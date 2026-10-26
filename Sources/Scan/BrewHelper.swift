import Foundation

// ============================================================
//  BrewHelper —— Homebrew 缓存安全探测与环境变量隔离助手
//
//  核心职责：
//    1. 环境变量安全隔离：派生子进程前全量剥离当前环境中所有 HOMEBREW_* 键，
//       防止外部通过恶意注入环境变量（如 HOMEBREW_CASK_OPTS）破坏系统；
//    2. 动态探测与白名单校验：动态执行 brew --cache，但必须严格校验返回路径
//       完全落入 knownBrewRoots 白名单范围内，防路径欺骗；
//    3. 规范清理执行：支持扫描 formula / cask 下载缓存并移入废纸篓，
//       或执行 brew cleanup --prune=30（安全注入 HOMEBREW_NO_AUTO_UPDATE=1
//       和 NONINTERACTIVE=1，杜绝自动更新网络卡死）。
// ============================================================

enum BrewHelper {

    /// 允许的已知 Homebrew 缓存根目录白名单（收敛至 AppConfig.Helpers）
    static var knownBrewRoots: [String] {
        let home = FileUtil.home.path
        return AppConfig.Helpers.brewKnownRoots.map { $0.replacingOccurrences(of: "~", with: home) }
    }

    /// 寻找本机可用的 brew 可执行文件路径（收敛至 AppConfig.Helpers）
    static func findBrewBinary() -> String? {
        for path in AppConfig.Helpers.brewBinaryCandidates {
            if FileUtil.exists(path) {
                return path
            }
        }
        return nil
    }

    /// 在剥离 HOMEBREW_* 环境变量的干净隔离沙盒中执行命令，带超时与退出码校验
    static func runIsolatedBrew(args: [String], extraEnv: [String: String] = [:], timeout: TimeInterval = 30.0) -> ShellResult {
        guard let brewBin = findBrewBinary() else {
            return ShellResult(stdout: "", stderr: "Homebrew binary not found", exitCode: -1)
        }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: brewBin)
        p.arguments = args

        // 环境变量过滤与隔离：移除所有带有 HOMEBREW_ 前缀的键
        var env = ProcessInfo.processInfo.environment.filter { key, _ in
            !key.hasPrefix("HOMEBREW_")
        }
        // 注入安全防御参数
        env["HOMEBREW_NO_AUTO_UPDATE"] = "1"
        env["HOMEBREW_NO_ANALYTICS"] = "1"
        env["NONINTERACTIVE"] = "1"
        for (k, v) in extraEnv {
            env[k] = v
        }
        p.environment = env

        let outPipe = Pipe()
        let errPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = errPipe

        do {
            try p.run()
        } catch {
            return ShellResult(stdout: "", stderr: error.localizedDescription, exitCode: -1)
        }

        let outHandle = outPipe.fileHandleForReading
        let errHandle = errPipe.fileHandleForReading
        let output = ScanResultSlots<Data>(repeating: Data(), count: 2)
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)

        group.enter()
        queue.async {
            output[0] = outHandle.readDataToEndOfFile()
            group.leave()
        }
        group.enter()
        queue.async {
            output[1] = errHandle.readDataToEndOfFile()
            group.leave()
        }

        let deadline = Date().addingTimeInterval(timeout)
        var timedOut = false
        while group.wait(timeout: .now() + AppConfig.Security.progressInterval) == .timedOut {
            if Date() >= deadline || IOScanContext.isCancelled { timedOut = true; break }
        }

        if !timedOut {
            while p.isRunning && Date() < deadline {
                usleep(10_000)
            }
            if p.isRunning { timedOut = true }
        }

        if timedOut {
            p.terminate()
            usleep(50_000)
            if p.isRunning { kill(p.processIdentifier, SIGKILL) }
            try? outHandle.close()
            try? errHandle.close()
            _ = group.wait(timeout: .now() + 0.5)
            return ShellResult(stdout: "", stderr: "Brew command timed out after \(timeout)s", exitCode: -2)
        }

        p.waitUntilExit()
        let outStr = String(data: output[0], encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errStr = String(data: output[1], encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return ShellResult(stdout: outStr, stderr: errStr, exitCode: p.terminationStatus)
    }

    /// 动态获取并通过白名单校验 Homebrew 缓存根路径
    static func verifiedCacheDirectory() -> URL? {
        // 先检查是否有 brew
        guard findBrewBinary() != nil else {
            // 没有安装 brew 时，检查家目录下是否存在默认遗留的 ~/Library/Caches/Homebrew
            let defaultCache = FileUtil.home.appendingPathComponent("Library/Caches/Homebrew")
            return FileUtil.exists(defaultCache.path) ? defaultCache : nil
        }

        let cacheResult = runIsolatedBrew(args: ["--cache"])
        let cacheOutput = cacheResult.stdout
        guard !cacheOutput.isEmpty, !cacheOutput.contains("\n") else {
            return nil
        }

        let candidatePath = (cacheOutput as NSString).standardizingPath

        // 白名单强制校验
        var isAllowed = false
        for root in knownBrewRoots {
            let stdRoot = (root as NSString).standardizingPath
            if candidatePath == stdRoot || candidatePath.hasPrefix(stdRoot + "/") {
                isAllowed = true
                break
            }
        }

        guard isAllowed, FileUtil.exists(candidatePath) else {
            return nil
        }

        return URL(fileURLWithPath: candidatePath)
    }

    /// 扫描 Homebrew 产生的旧版本下载包与 Cask 缓存文件
    static func scan() -> [ScanItem] {
        guard let cacheDir = verifiedCacheDirectory() else { return [] }

        var items: [ScanItem] = []
        let children = FileUtil.children(of: cacheDir)

        for child in children {
            // 符号链接逃逸与白名单防范
            guard SymlinkGuard.isSafePath(url: child, within: cacheDir) else { continue }
            guard !FileUtil.isProtected(child) else { continue }

            let name = child.lastPathComponent
            let note = name == "downloads"
                ? "Homebrew package temporary download cache"
                : "Homebrew package and source archive cache"

            guard let item = JunkRulePolicy.makeMeasuredCandidate(
                url: child,
                name: "Homebrew Cache · \(name)",
                note: note,
                safety: .safe,
                minBytes: 1024 * 1024
            ) else { continue }
            items.append(JunkRulePolicy.apply(item))
        }

        return items
    }

    /// 执行 brew cleanup
    static func runCleanup() -> (success: Bool, output: String) {
        guard findBrewBinary() != nil else {
            return (false, "Homebrew is not installed")
        }
        let result = runIsolatedBrew(args: ["cleanup", "--prune=30"], timeout: 60.0)
        let output = result.stdout.isEmpty ? result.stderr : result.stdout
        return (result.isSuccess, output)
    }
}
