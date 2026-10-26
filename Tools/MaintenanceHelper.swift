import Foundation
import Security
import Darwin

@_silgen_name("aclean_smc_execute")
private func smcExecute(_ argc: Int32, _ argv: UnsafePointer<UnsafePointer<CChar>?>) -> Int32


/// Hardware writes and lease expiry share one queue; a dead GUI cannot retain manual fan control.
private enum FanLease {
    static let queue = DispatchQueue(label: "com.personal.aclean.fan-lease")
    static let state = LockedValue<(pid: pid_t, deadline: TimeInterval)>((0, 0))
    static let timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: AppConfig.PrivilegedHelper.fanWatchdogInterval)
        timer.setEventHandler {
            let lease = state.withValue { $0 }
            if lease.pid != 0 && (kill(lease.pid, 0) != 0 || ProcessInfo.processInfo.systemUptime >= lease.deadline) {
                if write("auto") { state.withValue { $0 = (0, 0) } }
            }
        }
        timer.resume()
        return timer
    }()
    static func write(_ mode: String) -> Bool {
        let args = [strdup(AppConfig.PrivilegedHelper.executableName), strdup(mode)]
        defer { args.forEach { free($0) } }
        let immutable = args.map { $0.map { UnsafePointer($0) } } + [nil]
        return immutable.withUnsafeBufferPointer { smcExecute(2, $0.baseAddress!) == 0 }
    }
    static func perform(_ task: String, owner: pid_t) -> Bool {
        queue.sync {
            _ = timer
            if task == "fan.renew" {
                return state.withValue { lease in
                    guard lease.pid == owner, lease.deadline > ProcessInfo.processInfo.systemUptime else { return false }
                    lease.deadline = ProcessInfo.processInfo.systemUptime + AppConfig.PrivilegedHelper.fanLeaseSeconds
                    return true
                }
            }
            guard write(String(task.dropFirst(4))) else { _ = write("auto"); return false }
            state.withValue { $0 = task == "fan.auto" ? (0, 0) : (owner, ProcessInfo.processInfo.systemUptime + AppConfig.PrivilegedHelper.fanLeaseSeconds) }
            return true
        }
    }
}

/// One bounded serial queue across clients; invalidating a connection cancels its queued and running work.
private final class MaintenanceSession: NSObject, PrivilegedMaintenanceProtocol, @unchecked Sendable {
    private static let pending = LockedValue(0)
    static let queue: OperationQueue = {
        let queue = OperationQueue(); queue.maxConcurrentOperationCount = 1; return queue
    }()
    let owner: pid_t
    init(owner: pid_t) { self.owner = owner }
    let cancelled = LockedValue(false)
    func perform(taskID: String, reply: @escaping @Sendable (Bool) -> Void) {
        let admitted = Self.pending.withValue { count -> Bool in
            guard count < AppConfig.PrivilegedHelper.maxPendingRequests else { return false }
            count += 1; return true
        }
        guard admitted else { reply(false); return }
        let deadline = ProcessInfo.processInfo.systemUptime + AppConfig.PrivilegedHelper.timeout
        Self.queue.addOperation { [self] in
            defer { Self.pending.withValue { $0 -= 1 } }
            guard !cancelled.withValue({ $0 }), ProcessInfo.processInfo.systemUptime < deadline,
                  AppConfig.PrivilegedHelper.commands[taskID] != nil || AppConfig.PrivilegedHelper.fanTaskModes.contains(taskID) else { reply(false); return }
            if taskID.hasPrefix("fan.") {
                reply(FanLease.perform(taskID, owner: owner))
                return
            }
            guard let commands = AppConfig.PrivilegedHelper.commands[taskID] else { reply(false); return }
            for (path, arguments) in commands {
                guard execute(path, arguments, deadline: deadline) else { reply(false); return }
            }
            reply(true)
        }
    }
    private func execute(_ path: String, _ arguments: [String], deadline: TimeInterval) -> Bool {
        guard !cancelled.withValue({ $0 }) else { return false }
        var actions: posix_spawn_file_actions_t?, attributes: posix_spawnattr_t?
        guard posix_spawn_file_actions_init(&actions) == 0 else { return false }
        defer { posix_spawn_file_actions_destroy(&actions) }
        guard posix_spawnattr_init(&attributes) == 0 else { return false }
        defer { posix_spawnattr_destroy(&attributes) }
        for fd in [STDIN_FILENO, STDOUT_FILENO, STDERR_FILENO] {
            guard posix_spawn_file_actions_addopen(&actions, fd, "/dev/null", O_RDWR, 0) == 0 else { return false }
        }
        guard posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETPGROUP | POSIX_SPAWN_CLOEXEC_DEFAULT)) == 0,
              posix_spawnattr_setpgroup(&attributes, 0) == 0 else { return false }
        let argv = ([path] + arguments).map { strdup($0) } + [nil]
        let environment = [strdup("PATH=/usr/bin:/bin:/usr/sbin:/sbin"), strdup("LANG=C"), nil]
        defer { argv.forEach { free($0) }; environment.forEach { free($0) } }
        var pid: pid_t = 0
        let spawned = argv.withUnsafeBufferPointer { args in environment.withUnsafeBufferPointer { env in
            posix_spawn(&pid, path, &actions, &attributes, UnsafeMutablePointer(mutating: args.baseAddress!), UnsafeMutablePointer(mutating: env.baseAddress!))
        } }
        guard spawned == 0 else { return false }
        var status: Int32 = 0
        while true {
            let waited = waitpid(pid, &status, WNOHANG)
            if waited == pid { return status == 0 }
            if waited < 0 && errno != EINTR { return false }
            if cancelled.withValue({ $0 }) || ProcessInfo.processInfo.systemUptime >= deadline {
                _ = kill(-pid, SIGKILL)
                while waitpid(pid, &status, 0) < 0 && errno == EINTR {}
                return false
            }
            Thread.sleep(forTimeInterval: AppConfig.PrivilegedHelper.pollInterval)
        }
    }
}

private final class MaintenanceListener: NSObject, NSXPCListenerDelegate {
    let requirement: String
    init(requirement: String) { self.requirement = requirement }
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        guard connection.effectiveUserIdentifier != 0 else { return false }
        let session = MaintenanceSession(owner: connection.processIdentifier)
        connection.setCodeSigningRequirement(requirement)
        connection.exportedInterface = NSXPCInterface(with: PrivilegedMaintenanceProtocol.self)
        connection.exportedObject = session
        connection.invalidationHandler = { session.cancelled.withValue { $0 = true } }
        connection.interruptionHandler = { session.cancelled.withValue { $0 = true } }
        connection.resume()
        return true
    }
}

@main struct MaintenanceHelperMain {
    static func main() {
        guard geteuid() == 0 else { exit(EXIT_FAILURE) }

        // 降级机制 (CLI Direct Execution): 当未配置团队签名或通过 osascript/sudo 提权调用时执行单次任务
        if CommandLine.arguments.count > 1 {
            let task = CommandLine.arguments[1]
            let mode = task.hasPrefix("fan.") ? String(task.dropFirst(4)) : task
            if ["auto", "cool", "cooling", "max", "0", "50", "100"].contains(mode.lowercased()) {
                let ok = FanLease.write(mode)
                exit(ok ? EXIT_SUCCESS : EXIT_FAILURE)
            }
            exit(EXIT_FAILURE)
        }

        guard let team = MaintenanceSigning.currentTeam(identifier: AppConfig.PrivilegedHelper.service),
              let requirement = MaintenanceSigning.requirement(team: team, identifier: AppConfig.PrivilegedHelper.clientIdentifier) else { exit(EXIT_FAILURE) }
        _ = FanLease.perform("fan.auto", owner: 0)
        let delegate = MaintenanceListener(requirement: requirement)
        let listener = NSXPCListener(machServiceName: AppConfig.PrivilegedHelper.service)
        listener.delegate = delegate
        listener.resume()
        withExtendedLifetime((listener, delegate)) { RunLoop.current.run() }
    }
}
