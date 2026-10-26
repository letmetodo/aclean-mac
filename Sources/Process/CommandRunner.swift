import Foundation

public struct CommandResult {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32
    public var stdoutData: Data? = nil
    public var isSuccess: Bool { exitCode == 0 }
}

public typealias ShellResult = CommandResult

public enum CommandRunner {
    /// 基于 sysctl(KERN_PROC_ALL) 收集给定根进程集合的所有递归子孙进程 PID（及独立进程组内的成员）
    private static func collectProcessTreePIDs(roots: Set<pid_t>, isolatedPGID: pid_t?) -> Set<pid_t> {
        let selfPID = getpid()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size: Int = 0
        guard sysctl(&mib, 4, nil, &size, nil, 0) == 0, size > 0 else {
            return roots
        }
        let count = (size / MemoryLayout<kinfo_proc>.stride) + 32
        var procs = Array<kinfo_proc>(repeating: kinfo_proc(), count: count)
        var actualSize = count * MemoryLayout<kinfo_proc>.stride
        guard sysctl(&mib, 4, &procs, &actualSize, nil, 0) == 0 else {
            return roots
        }
        let actualCount = actualSize / MemoryLayout<kinfo_proc>.stride
        var childrenByParent: [pid_t: [pid_t]] = [:]
        var result = roots
        var queue = Array(roots)

        for i in 0..<actualCount {
            let pid = procs[i].kp_proc.p_pid
            let ppid = procs[i].kp_eproc.e_ppid
            let pgid = procs[i].kp_eproc.e_pgid
            guard pid > 1, pid != selfPID else { continue }
            childrenByParent[ppid, default: []].append(pid)
            if let isolatedPGID, pgid == isolatedPGID, !result.contains(pid) {
                result.insert(pid)
                queue.append(pid)
            }
        }

        var idx = 0
        while idx < queue.count {
            let current = queue[idx]
            idx += 1
            if let children = childrenByParent[current] {
                for child in children where !result.contains(child) {
                    result.insert(child)
                    queue.append(child)
                }
            }
        }
        return result
    }

    /// 终止并清理命令进程及其全部子孙进程树，防止超时/取消后孙进程孤儿化继续执行
    private static func terminateProcessTree(_ p: Process, isolatedPGID: pid_t?) {
        let rootPID = p.processIdentifier
        guard rootPID > 1 else { return }
        var knownTree = collectProcessTreePIDs(roots: [rootPID], isolatedPGID: isolatedPGID)
        // 先暂停进程树，防止在父进程退出瞬间子进程并发 fork 或重挂到 launchd 后漏检
        if let pgid = isolatedPGID {
            _ = kill(-pgid, SIGSTOP)
        }
        for pid in knownTree {
            _ = kill(pid, SIGSTOP)
        }
        knownTree = collectProcessTreePIDs(roots: knownTree, isolatedPGID: isolatedPGID)

        // 发送 SIGTERM 并恢复运行以允许优雅退出
        if let pgid = isolatedPGID {
            _ = kill(-pgid, SIGTERM)
            _ = kill(-pgid, SIGCONT)
        }
        for pid in knownTree where pid != rootPID {
            _ = kill(pid, SIGTERM)
            _ = kill(pid, SIGCONT)
        }
        _ = kill(rootPID, SIGTERM)
        _ = kill(rootPID, SIGCONT)

        usleep(50_000)

        // 复核存活状态并强制 SIGKILL 全部残留子孙进程
        knownTree = collectProcessTreePIDs(roots: knownTree, isolatedPGID: isolatedPGID)
        if let pgid = isolatedPGID {
            _ = kill(-pgid, SIGKILL)
        }
        for pid in knownTree {
            if kill(pid, 0) == 0 || errno != ESRCH {
                _ = kill(pid, SIGKILL)
            }
        }
        for _ in 0..<10 {
            let anyAlive = knownTree.contains { pid in
                kill(pid, 0) == 0
            }
            if !anyAlive { break }
            usleep(10_000)
        }
    }

    /// 两个输出管道都由独立线程排空，避免 stderr 写满 64KB 缓冲后子进程阻塞死锁。
    /// 内置超时机制（默认 10.0 秒），捕获真实 stdout、stderr 与 exitCode。
    @discardableResult
    static func execute(_ launch: String, _ args: [String], timeout: TimeInterval = 10.0,
                        environment: [String: String]? = nil) -> ShellResult {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: launch)
        p.arguments = args
        p.environment = environment
        let outPipe = Pipe()
        let errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe
        do { try p.run() } catch {
            return ShellResult(stdout: "", stderr: error.localizedDescription, exitCode: -1)
        }

        let rootPID = p.processIdentifier
        let selfPGID = getpgrp()
        _ = setpgid(rootPID, rootPID)
        let actualPGID = getpgid(rootPID)
        let isolatedPGID: pid_t? = (actualPGID > 1 && actualPGID != selfPGID) ? actualPGID : nil

        let outHandle = outPipe.fileHandleForReading
        let errHandle = errPipe.fileHandleForReading
        // A single owner reads and closes each descriptor. No FileHandle is closed
        // concurrently with a blocking Objective-C read.
        let handles = [outHandle, errHandle]
        defer { handles.forEach { try? $0.close() } }
        for handle in handles { _ = fcntl(handle.fileDescriptor, F_SETFL, O_NONBLOCK) }
        var output = [Data(), Data()]
        var ended = [false, false]
        let deadline = ProcessInfo.processInfo.systemUptime + timeout
        var buffer = [UInt8](repeating: 0, count: AppConfig.Telemetry.shellReadBufferSize)
        while true {
            for i in handles.indices where !ended[i] {
                // Bound each drain so a continuously writing process cannot starve timeout checks.
                for _ in 0..<AppConfig.Telemetry.shellReadBatchLimit {
                    let n = read(handles[i].fileDescriptor, &buffer, buffer.count)
                    if n > 0 { output[i].append(contentsOf: buffer.prefix(n)) }
                    else { if n == 0 { ended[i] = true }; break }
                }
            }
            if !p.isRunning {
                // Inherited descriptors in detached grandchildren do not keep the caller waiting.
                p.waitUntilExit()
                // Drain bytes written between the last read and process exit.
                for i in handles.indices where !ended[i] {
                    for _ in 0..<AppConfig.Telemetry.shellReadBatchLimit {
                        let n = read(handles[i].fileDescriptor, &buffer, buffer.count)
                        guard n > 0 else { break }
                        output[i].append(contentsOf: buffer.prefix(n))
                    }
                }
                return ShellResult(stdout: String(data: output[0], encoding: .utf8) ?? "",
                                   stderr: String(data: output[1], encoding: .utf8) ?? "",
                                   exitCode: p.terminationStatus, stdoutData: output[0])
            }
            if ProcessInfo.processInfo.systemUptime >= deadline || IOScanContext.isCancelled {
                terminateProcessTree(p, isolatedPGID: isolatedPGID)
                p.waitUntilExit()
                // Drain bytes written between the last read and process exit.
                for i in handles.indices where !ended[i] {
                    for _ in 0..<AppConfig.Telemetry.shellReadBatchLimit {
                        let n = read(handles[i].fileDescriptor, &buffer, buffer.count)
                        guard n > 0 else { break }
                        output[i].append(contentsOf: buffer.prefix(n))
                    }
                }
                return ShellResult(stdout: "", stderr: L10n.localized(.cleanupCancelledResult), exitCode: -2)
            }
            usleep(AppConfig.Security.shellPollMicroseconds)
        }
    }

    @discardableResult
    static func run(_ launch: String, _ args: [String], timeout: TimeInterval = 10.0) -> String {
        return execute(launch, args, timeout: timeout).stdout
    }
}

public typealias Shell = CommandRunner
