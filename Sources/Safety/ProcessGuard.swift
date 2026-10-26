import Foundation
import AppKit
import Darwin

// ============================================================
//  ProcessGuard —— 活跃进程安全锁与系统守护守卫
//
//  核心职责：
//    1. 检查目标应用与工具链进程活跃状态（Xcode/Simulator/Docker等），
//       若目标进程处于运行中，自动跳过清理，防止正在写入导致文件损坏或崩溃；
//    2. 原生内核内存直读（NSWorkspace + Darwin proc_listpids/proc_pidpath），
//       零外部 Shell 派生，零高负荷性能开销；
//    3. 提供系统核心进程保护白名单（CoreProcGuard 原语），
//       绝对禁止对系统关键守护进程发送终止信号。
// ============================================================

enum ProcessGuard {

    // MARK: - 系统核心守护进程保护白名单 (CoreProcGuard)

    /// 绝对禁止终止的核心系统进程集合（防止系统蓝屏、重启或窗口服务崩溃，收敛至 AppConfig.Security）
    static var criticalSystemProcesses: Set<String> {
        AppConfig.Security.criticalSystemProcesses
    }

    /// 判断给定 PID 或进程名称是否属于受保护的系统关键进程
    static func isProtectedSystemProcess(pid: pid_t, name: String? = nil) -> Bool {
        // PID 0 (kernel_task), PID 1 (launchd) 绝对受保护
        if pid <= 1 { return true }

        let procName = name ?? processName(for: pid) ?? ""
        let cleanName = (procName as NSString).lastPathComponent.lowercased()

        for protected in criticalSystemProcesses {
            if cleanName == protected.lowercased() {
                return true
            }
        }
        return false
    }

    // MARK: - 进程快照短周期缓存（消除高频扫描中成千上万次 NSRunningApplication / NSLock 分配与 libproc 系统调用）

    struct RunningAppRecord: Sendable {
        let localizedName: String?
        let localizedNameLower: String?
        let bundleID: String?
        let bundleIDLower: String?
        let bundlePath: String?
        let exeName: String?
        let exeNameLower: String?
    }

    struct ProcessSnapshot: Sendable {
        let timestamp: TimeInterval
        let apps: [RunningAppRecord]
        let bundleIDsLower: Set<String>
        let bundlePaths: Set<String>
        let cliExecNamesByLower: [String: String]
        var enumerationComplete: Bool = true
    }

    private static let snapshotLock = NSLock()
    private static nonisolated(unsafe) var _cachedSnapshot: ProcessSnapshot? = nil
    private static let snapshotTTL: TimeInterval = 0.5

    /// 测试专用注入钩子：模拟运行中进程名、BundleID 或进程枚举失败（fail-closed）
    #if DEBUG
    static nonisolated(unsafe) var runningProcessNamesOverrideForTesting: Set<String>? = nil {
        didSet { invalidateSnapshotCache() }
    }
    #else
    static var runningProcessNamesOverrideForTesting: Set<String>? { nil }
    #endif
    #if DEBUG
    static nonisolated(unsafe) var runningBundleIDsOverrideForTesting: Set<String>? = nil {
        didSet { invalidateSnapshotCache() }
    }
    #else
    static var runningBundleIDsOverrideForTesting: Set<String>? { nil }
    #endif
    #if DEBUG
    static nonisolated(unsafe) var simulateProcessEnumerationFailureForTesting: Bool = false {
        didSet { invalidateSnapshotCache() }
    }
    #else
    static var simulateProcessEnumerationFailureForTesting: Bool { false }
    #endif

    static func invalidateSnapshotCache() {
        snapshotLock.lock()
        _cachedSnapshot = nil
        snapshotLock.unlock()
    }

    static func currentSnapshot() -> ProcessSnapshot {
        let now = ProcessInfo.processInfo.systemUptime
        snapshotLock.lock()
        if let cached = _cachedSnapshot, (now - cached.timestamp) < snapshotTTL {
            snapshotLock.unlock()
            return cached
        }
        snapshotLock.unlock()

        let built: ProcessSnapshot = autoreleasepool {
            var apps: [RunningAppRecord] = []
            var bundleIDsLower = Set<String>()
            var bundlePaths = Set<String>()

            if let overrideBundles = runningBundleIDsOverrideForTesting {
                for bid in overrideBundles where !bid.isEmpty {
                    let bidLower = bid.lowercased()
                    bundleIDsLower.insert(bidLower)
                    apps.append(RunningAppRecord(
                        localizedName: bid,
                        localizedNameLower: bidLower,
                        bundleID: bid,
                        bundleIDLower: bidLower,
                        bundlePath: nil,
                        exeName: bid,
                        exeNameLower: bidLower
                    ))
                }
            } else {
                let running = NSWorkspace.shared.runningApplications
                apps.reserveCapacity(running.count)
                bundleIDsLower.reserveCapacity(running.count)
                bundlePaths.reserveCapacity(running.count)

                for r in running {
                    let locName = r.localizedName
                    let locLower = locName?.lowercased()
                    let bid = r.bundleIdentifier
                    let bidLower = bid?.lowercased()
                    let bPath = r.bundleURL?.standardizedFileURL.path
                    let exe = r.executableURL?.lastPathComponent
                    let exeLower = exe?.lowercased()
                    if let bidLower, !bidLower.isEmpty {
                        bundleIDsLower.insert(bidLower)
                    }
                    if let bPath, !bPath.isEmpty {
                        bundlePaths.insert(bPath)
                    }
                    apps.append(RunningAppRecord(
                        localizedName: locName,
                        localizedNameLower: locLower,
                        bundleID: bid,
                        bundleIDLower: bidLower,
                        bundlePath: bPath,
                        exeName: exe,
                        exeNameLower: exeLower
                    ))
                }
            }

            var enumerationComplete = true
            var cliExecNamesByLower: [String: String] = [:]
            if let overrideProcs = runningProcessNamesOverrideForTesting {
                for proc in overrideProcs where !proc.isEmpty {
                    cliExecNamesByLower[proc.lowercased()] = proc
                }
            } else {
                let enumerated = allRunningPIDs()
                enumerationComplete = enumerated != nil
                let pids = enumerated ?? []
                cliExecNamesByLower.reserveCapacity(pids.count)
                for pid in pids {
                    if let path = processPath(for: pid) {
                        let name = (path as NSString).lastPathComponent
                        let low = name.lowercased()
                        if cliExecNamesByLower[low] == nil {
                            cliExecNamesByLower[low] = name
                        }
                    }
                }
            }

            return ProcessSnapshot(
                timestamp: ProcessInfo.processInfo.systemUptime,
                apps: apps,
                bundleIDsLower: bundleIDsLower,
                bundlePaths: bundlePaths,
                cliExecNamesByLower: cliExecNamesByLower,
                enumerationComplete: enumerationComplete
            )
        }

        snapshotLock.lock()
        _cachedSnapshot = built
        snapshotLock.unlock()
        return built
    }

    static func runningApplicationBundlePaths() -> Set<String> {
        currentSnapshot().bundlePaths
    }

    // MARK: - 活跃应用检查 (GUI 进程)

    /// 检查指定 Bundle Identifier 的应用是否正在运行
    static func isAppRunning(bundleID: String) -> Bool {
        if simulateProcessEnumerationFailureForTesting || !currentSnapshot().enumerationComplete { return true }
        guard !bundleID.isEmpty else { return false }
        return currentSnapshot().bundleIDsLower.contains(bundleID.lowercased())
    }

    /// 检查指定显示名称的应用是否正在运行
    static func isAppRunning(named appName: String) -> Bool {
        if simulateProcessEnumerationFailureForTesting || !currentSnapshot().enumerationComplete { return true }
        let target = appName.lowercased()
        let targetApp = "\(target).app"
        let snap = currentSnapshot()
        for app in snap.apps {
            if let name = app.localizedNameLower, name == target {
                return true
            }
            if let exeName = app.exeNameLower,
               exeName == target || exeName == targetApp {
                return true
            }
        }
        return false
    }

    // MARK: - 底层/CLI 工具链活跃状态检查 (原生 libproc)

    /// 检查命令行/系统底层进程名称是否在系统中活跃运行
    static func isProcessRunning(executableName: String) -> Bool {
        if simulateProcessEnumerationFailureForTesting || !currentSnapshot().enumerationComplete { return true }
        let target = executableName.lowercased()
        return currentSnapshot().cliExecNamesByLower[target] != nil
    }

    /// 检查指定进程家族（如 python3Versioned -> \Apython3\.[0-9]+\z）是否在运行中
    static func isProcessFamilyRunning(_ family: String) -> (isRunning: Bool, activeName: String?) {
        if simulateProcessEnumerationFailureForTesting || !currentSnapshot().enumerationComplete {
            return (true, family)
        }
        guard family == "python3Versioned" else {
            return (true, family) // 未知 process_family 视为配置错误并 fail-closed 锁定
        }
        let pattern = AppConfig.JunkScan.CacheMatching.pythonVersionProcess
        let snap = currentSnapshot()
        for app in snap.apps {
            if let exe = app.exeName,
               AppConfig.JunkScan.CacheMatching.matchesWholeDirectoryName(exe.lowercased(), pattern: pattern) {
                return (true, exe)
            }
        }
        for (lowerName, rawName) in snap.cliExecNamesByLower {
            if AppConfig.JunkScan.CacheMatching.matchesWholeDirectoryName(lowerName, pattern: pattern) {
                return (true, rawName)
            }
        }
        return (false, nil)
    }

    /// 批量检查工具链集合中是否有任意一个处于运行态
    static func isAnyToolchainRunning(_ names: [String]) -> (isRunning: Bool, activeName: String?) {
        guard !names.isEmpty else { return (false, nil) }
        if simulateProcessEnumerationFailureForTesting || !currentSnapshot().enumerationComplete {
            return (true, names.first)
        }
        let targets = Set(names.map { $0.lowercased() })
        let snap = currentSnapshot()
        // 先快速查 GUI
        for app in snap.apps {
            if let name = app.localizedNameLower, targets.contains(name) {
                return (true, app.localizedName)
            }
            if let exe = app.exeNameLower, targets.contains(exe) {
                return (true, app.exeName)
            }
        }
        // 再查原生 PID 快照表
        for t in targets {
            if let matchedName = snap.cliExecNamesByLower[t] {
                return (true, matchedName)
            }
        }
        if targets.contains("python3versioned") {
            let familyCheck = isProcessFamilyRunning("python3Versioned")
            if familyCheck.isRunning {
                return familyCheck
            }
        }
        return (false, nil)
    }

    // MARK: - 针对待清理路径的活跃状态安全排查

    /// 检查指定路径是否归属于当前活跃运行的应用或开发工具链，运行中则指示应当跳过
    static func shouldSkipDueToRunningProcess(path: String) -> (skip: Bool, reason: String?) {
        guard !simulateProcessEnumerationFailureForTesting, currentSnapshot().enumerationComplete else {
            return (true, L10n.localized(.safetyInspectionIncomplete))
        }
        let stdPath = (path as NSString).standardizingPath

        // 1. Xcode 与开发工具链保护
        if stdPath.contains("/Developer/Xcode") || stdPath.contains("/DerivedData") {
            let xcodeCheck = isAnyToolchainRunning(AppConfig.Security.xcodeToolchainProcesses)
            if xcodeCheck.isRunning {
                return (true, "Xcode toolchain (\(xcodeCheck.activeName ?? "Xcode")) is currently running; skipped to prevent cache conflicts")
            }
        }

        // 2. 模拟器保护
        if stdPath.contains("CoreSimulator") {
            let simCheck = isAnyToolchainRunning(AppConfig.Security.simulatorProcesses)
            if simCheck.isRunning {
                return (true, "iOS Simulator is running; skipped to prevent runtime conflicts")
            }
        }

        // 3. Docker 与 OrbStack 保护
        if stdPath.contains("/.docker") || stdPath.contains("com.docker.docker") {
            let dockerCheck = isAnyToolchainRunning(AppConfig.Security.dockerProcesses)
            if dockerCheck.isRunning {
                return (true, "Docker is running; skipped to prevent container service errors")
            }
        }
        if stdPath.contains("/.orbstack") || stdPath.contains("dev.kdrag0n.MacVirt") {
            let orbCheck = isAnyToolchainRunning(AppConfig.Security.orbStackProcesses)
            if orbCheck.isRunning {
                return (true, "OrbStack is running; skipped to prevent VM service errors")
            }
        }

        let snap = currentSnapshot()

        // 3.5 应用程序包 (.app) 自身与运行中进程检测 (F2)
        if stdPath.hasSuffix(".app") || stdPath.contains(".app/") {
            var appPath = stdPath
            if let range = stdPath.range(of: ".app") {
                appPath = String(stdPath[..<range.upperBound])
            }
            if snap.bundlePaths.contains(appPath) {
                let matched = snap.apps.first { $0.bundlePath == appPath }
                let name = matched?.localizedName ?? (appPath as NSString).lastPathComponent
                return (true, "Target application [\(name)] is currently running; skipped to protect unsaved work")
            }
            // 尝试读取包内 Info.plist 提取 BundleID 核验
            let plistPath = (appPath as NSString).appendingPathComponent("Contents/Info.plist")
            if let dict = autoreleasepool(invoking: { NSDictionary(contentsOfFile: plistPath) }),
               let bid = dict["CFBundleIdentifier"] as? String,
               isAppRunning(bundleID: bid) {
                return (true, "Target application [\(bid)] is currently running; skipped to protect unsaved work")
            }
        }

        // 4. 沙盒容器、缓存、偏好设置与 Application Support (F2/R3)
        if let bundleID = extractBundleID(from: stdPath) {
            if isAppRunning(bundleID: bundleID) {
                return (true, "Target app (\(bundleID)) is currently running; skipped active application data")
            }
        }

        if stdPath.contains("/Application Support/") {
            let components = stdPath.split(separator: "/").map(String.init)
            if let idx = components.firstIndex(of: "Application Support"), idx + 1 < components.count {
                let candidate1 = components[idx + 1]
                let candidate2 = (idx + 2 < components.count) ? components[idx + 2] : nil
                let combined = (candidate2 != nil) ? "\(candidate1) \(candidate2!)" : candidate1

                if isAppRunning(bundleID: candidate1) || (candidate2 != nil && isAppRunning(bundleID: candidate2!)) {
                    return (true, "Target app is currently running; skipped active Application Support data")
                }

                let electronMap = KnowledgeBaseManager.shared.authored.electronDirectories
                if !electronMap.isEmpty {
                    let cand1Lower = candidate1.lowercased()
                    let cand2Lower = candidate2?.lowercased()
                    for (mappedBid, dirName) in electronMap {
                        let dLower = dirName.lowercased()
                        if dLower == cand1Lower || (cand2Lower != nil && dLower == "\(cand1Lower)/\(cand2Lower!)") {
                            if isAppRunning(bundleID: mappedBid) {
                                return (true, "Target application [\(mappedBid)] is currently running; skipped active Application Support data")
                            }
                        }
                    }
                }

                for r in snap.apps {
                    let rName = r.localizedName ?? ""
                    let rBid = r.bundleID ?? ""

                    // 1) 匹配应用名 (例如 candidate1 = "Slack", 或 combined = "Google Chrome", 或 candidate2 = "Chrome")
                    if (!rName.isEmpty && (
                        rName.localizedCaseInsensitiveCompare(candidate1) == .orderedSame ||
                        (candidate2 != nil && rName.localizedCaseInsensitiveCompare(candidate2!) == .orderedSame) ||
                        rName.localizedCaseInsensitiveCompare(combined) == .orderedSame
                    )) {
                        return (true, "Target application [\(rName)] is currently running; skipped active Application Support data")
                    }

                    // 2) 匹配厂商+应用路径在 Bundle ID 中的特征 (例如 Google/Chrome 对应 com.google.Chrome)
                    if let lowBid = r.bundleIDLower, !lowBid.isEmpty {
                        let low1 = candidate1.lowercased()
                        if let c2 = candidate2 {
                            let low2 = c2.lowercased()
                            if lowBid.contains(low1) && lowBid.contains(low2) {
                                return (true, "Target application [\(rName.isEmpty ? rBid : rName)] is currently running; skipped active Application Support data")
                            }
                        } else if lowBid.contains(low1) && (lowBid.hasSuffix("." + low1) || lowBid.hasPrefix(low1 + ".")) {
                            return (true, "Target application [\(rName.isEmpty ? rBid : rName)] is currently running; skipped active Application Support data")
                        }
                    }
                }
            }
        }

        return (false, nil)
    }

    /// 从标准缓存/容器路径中提取潜在的 Bundle Identifier
    static func extractBundleID(from path: String) -> String? {
        let components = path.split(separator: "/").map(String.init)
        for (i, comp) in components.enumerated() {
            if (comp == "Caches" || comp == "Containers" || comp == "Group Containers" || comp == "Preferences" || comp == "Saved Application State" || comp == "WebKit" || comp == "HTTPStorages") && i + 1 < components.count {
                var candidate = components[i + 1]
                if candidate.hasSuffix(".plist") {
                    candidate = String(candidate.dropLast(6))
                } else if candidate.hasSuffix(".savedState") {
                    candidate = String(candidate.dropLast(11))
                }
                // 常见 Bundle ID 格式包含点号，且不是内部特定保留目录
                if candidate.contains(".") && !candidate.hasPrefix(".") && candidate.count > 3 {
                    return candidate
                }
            }
        }
        return nil
    }

    // MARK: - Darwin libproc 原生支持（零外部 Shell 派生）

    /// 获取系统中所有正在运行的进程 PID 列表
    static func allRunningPIDs() -> [pid_t]? {
        let count = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard count > 0 else { return nil }

        let numPids = Int(count) / MemoryLayout<pid_t>.size + 256
        var pids = [pid_t](repeating: 0, count: numPids)
        let actual = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard actual > 0, actual < Int32(pids.count * MemoryLayout<pid_t>.size) else { return nil }

        let actualCount = Int(actual) / MemoryLayout<pid_t>.size
        return Array(pids.prefix(actualCount)).filter { $0 > 0 }
    }

    /// 读取指定 PID 的可执行文件绝对路径
    static func processPath(for pid: pid_t) -> String? {
        var buffer = [UInt8](repeating: 0, count: 4096)
        let len = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard len > 0 else { return nil }
        return String(decoding: buffer.prefix(while: { $0 != 0 }), as: UTF8.self)
    }

    /// 读取指定 PID 的进程名称
    static func processName(for pid: pid_t) -> String? {
        if let path = processPath(for: pid) {
            return (path as NSString).lastPathComponent
        }
        var info = proc_bsdinfo()
        let ret = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, Int32(MemoryLayout<proc_bsdinfo>.size))
        if ret == Int32(MemoryLayout<proc_bsdinfo>.size) {
            let name = withUnsafePointer(to: &info.pbi_name) { ptr in
                ptr.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: ptr.pointee)) {
                    String(cString: $0)
                }
            }
            return name.isEmpty ? nil : name
        }
        return nil
    }
}
