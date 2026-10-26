import Foundation

// ============================================================
//  XcodeHelper —— Xcode 垃圾与 Simulator 运行时治理助手
//
//  核心职责：
//    1. 预检防扰民：前置检查 /usr/bin/xcode-select -p，未装工具链静默退出，
//       严禁直接调用 xcrun 触发系统“需安装命令行开发者工具”弹窗；
//    2. 镜像解析：执行 xcrun simctl runtime list -j 结构化解析，提取
//       iOS/watchOS/tvOS/visionOS 模拟器版本、构建号与占用体积；
//    3. 孤立项比对：对比 xcrun simctl list devices -j，若某运行时无任何模拟设备关联，
//       标记为「孤立运行时 (Orphaned)」；
//    4. 严格风控：运行时条目默认 isSelected = false，避免误清用户在用环境；
//    5. 专用删除路由：通过 xcrun simctl runtime delete <id> 原生指令释放磁盘。
// ============================================================

enum XcodeHelper {

    struct SimulatorRuntime: Identifiable, Hashable {
        let id: String              // runtime identifier, e.g. com.apple.CoreSimulator.SimRuntime.iOS-17-0
        let name: String            // e.g. iOS 17.0
        let version: String         // e.g. 17.0
        let buildVersion: String    // e.g. 21A328
        let bundlePath: String?
        let sizeBytes: Int64
        let isAvailable: Bool
        let isOrphaned: Bool
    }

    // MARK: - 1. 预检防扰民检查

    /// 校验系统是否已配置有效的 Xcode / 开发者命令行工具路径。
    /// 未安装时返回 false，防止调用 xcrun 弹出扰民的系统安装提示框。
    static func hasDeveloperTools() -> Bool {
        guard FileUtil.exists("/usr/bin/xcode-select") else { return false }
        let output = Shell.run("/usr/bin/xcode-select", ["-p"]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty, !output.contains("error:") else { return false }
        return FileUtil.exists(output)
    }

    // MARK: - 2. 扫描与解析模拟器运行时

    /// 扫描全量模拟器运行时，并标识孤立项（支持 simctl 与物理目录双重探测）
    static func scanSimulatorRuntimes() -> [ScanItem] {
        var items: [ScanItem] = []
        var processedPaths = Set<String>()
        var foundIDs = Set<String>()

        // 1. 若开发者工具可用，尝试通过 xcrun simctl 结构化解析
        if hasDeveloperTools() {
            let referencedRuntimes = fetchReferencedRuntimeIDs()
            let rawJSON = Shell.run("/usr/bin/xcrun", ["simctl", "runtime", "list", "-j"], timeout: 5.0)
            if let data = rawJSON.data(using: .utf8),
               let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let runtimesArray = root["runtimes"] as? [[String: Any]],
               !runtimesArray.isEmpty {
                for dict in runtimesArray {
                    guard let identifier = dict["identifier"] as? String else { continue }
                    foundIDs.insert(identifier)
                    let name = (dict["name"] as? String) ?? identifier
                    let version = (dict["version"] as? String) ?? ""
                    let buildVersion = (dict["buildversion"] as? String) ?? (dict["buildVersion"] as? String) ?? ""
                    let bundlePath = dict["bundlePath"] as? String
                    if let bp = bundlePath { processedPaths.insert(bp) }

                    let isOrphaned = referencedRuntimes.map { !$0.contains(identifier) } ?? false
                    var size: Int64 = 0
                    if let reportedSize = dict["sizeBytes"] as? Int64, reportedSize > 0 {
                        size = reportedSize
                    } else if let reportedSize = dict["sizeBytes"] as? Int, reportedSize > 0 {
                        size = Int64(reportedSize)
                    } else if let path = bundlePath, !path.isEmpty {
                        size = FileUtil.size(of: URL(fileURLWithPath: path))
                    }
                    // 体积未知即保持 0（扫到什么就是什么，严禁用常量冒充扫描结果）

                    let fileURL = URL(fileURLWithPath: bundlePath ?? "")
                    let title = "\(name) (\(buildVersion))\(isOrphaned ? " · Orphaned" : "")"
                    let note = isOrphaned
                        ? "Runtime not referenced by any current simulator device, safe to remove"
                        : "Simulator runtime (\(version)), can be re-downloaded via Xcode"

                    var item = ScanItem(
                        url: fileURL,
                        name: title,
                        size: size,
                        note: note,
                        safety: isOrphaned ? .safe : .caution,
                        action: .simctlRuntimeDelete(identifier)
                    )
                    // 由 simctl 管理的运行时（含 Cryptex 挂载，路径位于只读系统卷）：
                    // 解锁以便专用删除指令放行（普通 trash 仍会被物理红线拦截）
                    item.locked = false
                    item.isSelected = false
                    if isOrphaned { item.badge = "Orphaned" }
                    items.append(item)
                }
            }
        }

        // 2. 物理目录扫描（支持现代 Xcode 15/16 的 /Library/Developer/CoreSimulator/Volumes 挂载卷与 Runtimes）
        let physicalRoots = AppConfig.DeveloperPurge.simulatorPhysicalRoots

        for rootPath in physicalRoots where FileUtil.exists(rootPath) {
            let rootURL = URL(fileURLWithPath: rootPath)
            for child in FileUtil.children(of: rootURL) {
                let cp = child.standardizedFileURL.path
                guard !processedPaths.contains(cp) else { continue }

                // 检查是否包含 .simruntime
                let targetURL = child
                var runtimeName = child.deletingPathExtension().lastPathComponent
                var runtimeID = ""

                let deepRuntimeDir = child.appendingPathComponent("Library/Developer/CoreSimulator/Profiles/Runtimes")
                if FileUtil.exists(deepRuntimeDir.path) {
                    if let firstSim = FileUtil.children(of: deepRuntimeDir).first(where: { $0.pathExtension == "simruntime" }) {
                        runtimeName = firstSim.deletingPathExtension().lastPathComponent
                    }
                }

                let s = FileUtil.size(of: targetURL)
                guard s > 50 * 1024 * 1024 else { continue } // 至少大于 50MB 才是有效运行时
                processedPaths.insert(cp)

                // 尝试提取 Info.plist 元数据
                let possiblePlists = [
                    child.appendingPathComponent("Contents/Info.plist").path,
                    deepRuntimeDir.appendingPathComponent("\(runtimeName).simruntime/Contents/Info.plist").path
                ]
                for pl in possiblePlists where FileUtil.exists(pl) {
                    if let dict = NSDictionary(contentsOfFile: pl) {
                        if let cfName = dict["CFBundleName"] as? String { runtimeName = cfName }
                        if let cfID = dict["CFBundleIdentifier"] as? String { runtimeID = cfID }
                    }
                }

                if !runtimeID.isEmpty && foundIDs.contains(runtimeID) { continue }
                if !runtimeID.isEmpty { foundIDs.insert(runtimeID) }

                var item = ScanItem(
                    url: targetURL,
                    name: "Xcode Simulators Runtime",
                    size: s,
                    note: "iOS Simulator runtime (\(runtimeName)), can be re-downloaded via Xcode",
                    safety: .caution,
                    action: runtimeID.isEmpty ? .trash : .simctlRuntimeDelete(runtimeID)
                )
                item.isSelected = false
                if runtimeID.isEmpty { item.locked = true }
                items.append(JunkRulePolicy.apply(item))
            }
        }

        return items
    }

    // MARK: - 2b. Cryptex 挂载运行时 + 模拟器设备数据（P0-4 覆盖补齐）

    /// Cryptex 挂载的 iOS 模拟器运行时。
    ///
    /// Xcode 15+ 把模拟器运行时以 Cryptex（密封的预启动卷）形式挂载，
    /// 常规 `/Library/Developer/CoreSimulator/Volumes` 扫不到 —— 这正是「15GB+ 漏扫」的根因之一。
    /// 路径实证（`strings SystemJunkScanning`）：
    ///   `/System/Volumes/Preboot/Cryptexes/App/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime*`
    static func scanCryptexRuntimes(excluding processed: Set<String> = []) -> [ScanItem] {
        var items: [ScanItem] = []
        let root = "/System/Volumes/Preboot/Cryptexes/App/System/Library/AssetsV2"
        guard FileUtil.exists(root) else { return [] }
        for child in FileUtil.children(of: URL(fileURLWithPath: root))
        where child.lastPathComponent.hasPrefix("com_apple_MobileAsset_iOSSimulatorRuntime") {
            let cp = child.standardizedFileURL.path
            // 前缀去重：simctl 已报告过的（bundlePath 在该资产之下）不再重复计入
            guard !processed.contains(where: { $0.hasPrefix(cp) }) else { continue }
            let s = FileUtil.size(of: child)
            guard s > 50 * 1024 * 1024 else { continue } // 至少 50MB 才算有效运行时
            let item = ScanItem(
                url: child,
                name: "Simulator Runtime · \(child.lastPathComponent)",
                size: s,
                note: "Cryptex-mounted iOS Simulator runtime image (managed via Xcode or xcrun simctl)",
                safety: .caution,
                action: .trash,
                isSelected: false,
                locked: true,
                measuredBytes: s
            )
            items.append(JunkRulePolicy.apply(item))
        }
        return items
    }

    /// 模拟器设备数据。
    /// 逐台设备独立成项，便于用户按需清理。
    static func scanSimulatorDevices() -> [ScanItem] {
        var items: [ScanItem] = []
        let root = FileUtil.home.appendingPathComponent("Library/Developer/CoreSimulator/Devices")
        guard FileUtil.exists(root.path) else { return [] }
        for dev in FileUtil.children(of: root) {
            let s = FileUtil.size(of: dev)
            guard s > 50 * 1024 * 1024 else { continue }
            var label = dev.lastPathComponent
            let plist = dev.appendingPathComponent("device.plist")
            if let d = NSDictionary(contentsOf: plist), let n = d["name"] as? String {
                label = "\(n) [\(dev.lastPathComponent.prefix(8))]"
            }
            var item = ScanItem(
                url: dev,
                name: "Simulator Device · \(label)",
                size: s,
                note: "iOS simulator device data and installed apps; deleted device will disappear from Xcode",
                safety: .caution,
                action: .trash,
                isSelected: false,
                locked: true,
                measuredBytes: s
            )
            item.ruleEvidence = CleanupRuleEvidence(
                id: "JC.DEV.XCODE.SIMULATOR",
                tier: .readOnly,
                reason: .whitelistProtected,
                defaultSelected: false
            )
            items.append(JunkRulePolicy.apply(item))
        }
        return items
    }

    /// 解析当前所有活跃设备所绑定的 runtime identifiers
    private static func fetchReferencedRuntimeIDs() -> Set<String>? {
        let rawJSON = Shell.run("/usr/bin/xcrun", ["simctl", "list", "devices", "-j"])
        guard let data = rawJSON.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devicesDict = root["devices"] as? [String: [[String: Any]]] else {
            return nil
        }

        var referenced = Set<String>()
        for (runtimeKey, deviceList) in devicesDict {
            // 若设备列表中有非空的设备，说明该 runtime 正在被使用
            if !deviceList.isEmpty {
                referenced.insert(runtimeKey)
            }
        }
        return referenced
    }

    // MARK: - 3. 专用删除执行

    /// 调用 xcrun simctl runtime delete 删除指定模拟器运行时
    static func deleteRuntime(identifier: String) -> (success: Bool, error: String?) {
        guard hasDeveloperTools() else {
            return (false, "Xcode command line developer tools not found")
        }
        guard !identifier.isEmpty else {
            return (false, "Missing runtime identifier")
        }

        let result = Shell.execute("/usr/bin/xcrun", ["simctl", "runtime", "delete", identifier], timeout: 30.0)
        guard result.isSuccess else {
            let errMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            return (false, errMsg.isEmpty ? "xcrun simctl runtime delete failed with code \(result.exitCode)" : errMsg)
        }
        return (true, nil)
    }

    /// 调用 xcrun simctl delete unavailable 删除因旧版本 Xcode 遗留的不可用模拟器设备容器
    static func deleteUnavailableSimulators() -> (success: Bool, error: String?) {
        guard hasDeveloperTools() else {
            return (false, "Xcode command line developer tools not found")
        }

        let result = Shell.execute("/usr/bin/xcrun", ["simctl", "delete", "unavailable"], timeout: 30.0)
        guard result.isSuccess else {
            let errMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            return (false, errMsg.isEmpty ? "xcrun simctl delete unavailable failed with code \(result.exitCode)" : errMsg)
        }
        return (true, nil)
    }
}
