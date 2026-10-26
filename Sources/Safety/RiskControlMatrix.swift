import Foundation

// ============================================================
//  RiskControlMatrix —— 多维安全风控分级矩阵 (P0 核心风控版)
//
//  核心原则: 数据安全第一，宁漏不误。
//    1. 固化 Sequoia 系统设置保护（com.apple.Settings、com.apple.controlcenter）；
//    2. 固化 Apple 神经引擎缓存保护（com.apple.e5rt.e5bundlecache）；
//    3. 全面封锁应用在位二进制修改（thinBinary）与语言包（.lproj）剥离动作，
//       杜绝破坏 Gatekeeper 签名或触发 dyld SIGKILL；
//    4. 深度协同 ProcessGuard（运行态保护）、SymlinkGuard（防软链逃逸）
//       与 GitGuard（Git 跟踪与私钥避让）；
//    5. 细粒度默认勾选策略与多级确认机制。
// ============================================================

// MARK: - 清理类别

enum CleanCategory: String {
    case safeCache      = "safeCache"
    case diagnosticLog  = "diagnosticLog"
    case brokenItem     = "brokenItem"
    case devCache       = "devCache"
    case languagePack   = "languagePack"
    case archSlice      = "archSlice"
    case iOSBackup      = "iOSBackup"
    case duplicateCopy  = "duplicateCopy"
    case trashContent   = "trashContent"
    case userContent    = "userContent"
    case systemLevel    = "systemLevel"
    case unknown        = "unknown"

    var requiresManualConfirmation: Bool {
        switch self {
        case .iOSBackup, .systemLevel, .userContent:
            return true
        default:
            return false
        }
    }

    var localizedTitle: String {
        switch self {
        case .safeCache:     return L10n.localized(.cleanCatTitleSafeCache)
        case .diagnosticLog: return L10n.localized(.cleanCatTitleDiagnosticLog)
        case .brokenItem:    return L10n.localized(.cleanCatTitleBrokenItem)
        case .devCache:      return L10n.localized(.cleanCatTitleDevCache)
        case .languagePack:  return L10n.localized(.cleanCatTitleLanguagePack)
        case .archSlice:     return L10n.localized(.cleanCatTitleArchSlice)
        case .iOSBackup:     return L10n.localized(.cleanCatTitleIosBackup)
        case .duplicateCopy: return L10n.localized(.cleanCatTitleDuplicateCopy)
        case .trashContent:  return L10n.localized(.cleanCatTitleTrashContent)
        case .userContent:   return L10n.localized(.cleanCatTitleUserContent)
        case .systemLevel:   return L10n.localized(.cleanCatTitleSystemLevel)
        case .unknown:       return L10n.localized(.other)
        }
    }

    var desc: String {
        localizedDesc
    }

    var localizedDesc: String {
        switch self {
        case .safeCache:     return L10n.localized(.cleanCatDescSafeCache)
        case .diagnosticLog: return L10n.localized(.cleanCatDescDiagnosticLog)
        case .brokenItem:    return L10n.localized(.cleanCatDescBrokenItem)
        case .devCache:      return L10n.localized(.cleanCatDescDevCache)
        case .languagePack:  return L10n.localized(.cleanCatDescLanguagePack)
        case .archSlice:     return L10n.localized(.cleanCatDescArchSlice)
        case .iOSBackup:     return L10n.localized(.cleanCatDescIosBackup)
        case .duplicateCopy: return L10n.localized(.cleanCatDescDuplicateCopy)
        case .trashContent:  return L10n.localized(.cleanCatDescTrashContent)
        case .userContent:   return L10n.localized(.cleanCatDescUserContent)
        case .systemLevel:   return L10n.localized(.cleanCatDescSystemLevel)
        case .unknown:       return L10n.localized(.cleanCatDescUnknown)
        }
    }
}

// MARK: - 风控矩阵

enum RiskControlMatrix {

    // MARK: - 固化核心系统白名单（Sequoia 设置保护 & ANE 保护）

    // MARK: - 固化核心系统白名单（Sequoia 设置保护 & ANE 保护）

    /// 固化受保护的系统 Bundle Identifier 白名单（收敛至 AppConfig.Security）
    static var protectedBundleIDs: Set<String> {
        AppConfig.Security.protectedBundleIDs
    }

    /// 固化受保护路径标记（含 Apple 神经引擎缓存、虚拟机磁盘文件，收敛至 AppConfig.Security）
    static var protectedPathMarkers: [String] {
        AppConfig.Security.protectedPathMarkers
    }

    // MARK: 开发编译缓存特征 (命中即视为 devCache, 默认不勾选，收敛至 AppConfig.Security)
    private static var devCacheMarkers: [String] {
        AppConfig.Security.devCacheMarkers
    }

    /// iOS 备份根 (MobileSync/Backup 下按设备分子目录，收敛至 AppConfig.Security)
    static var iOSBackupRootMarker: String {
        AppConfig.Security.iOSBackupRootMarker
    }

    // MARK: - 动作合法性封锁（封锁二进制与语言包在位修改，封锁 .app 内部子组件删除）

    /// 检查路径是否严格位于某个 .app 应用程序包内部
    /// 注意：整包卸载时目标本身为 Foo.app，其 parent 遍历中不含 .app，返回 false；
    /// 若目标为 Foo.app/Contents/...，其 parent 包含 Foo.app，返回 true。
    static func isInsideApplicationBundle(_ url: URL) -> Bool {
        var parent = url.standardizedFileURL.deletingLastPathComponent()
        while parent.path != "/" && parent.pathComponents.count > 1 {
            if parent.pathExtension.lowercased() == "app" { return true }
            parent.deleteLastPathComponent()
        }
        return false
    }

    /// 校验清理动作合法性。严禁在位修改二进制与删除 .lproj，严禁删除 .app 应用程序包内部子组件
    static func isActionPermitted(action: ItemAction, url: URL?) -> (permitted: Bool, reason: String?) {
        // 1. 彻底封锁架构切片瘦身 (thinBinary)
        if case .thinBinary = action {
            return (false, tr(.errorRedlineBinaryModification))
        }

        if let targetURL = url {
            let path = targetURL.standardizedFileURL.path
            // 2. 彻底封锁在位删除应用程序内的 .lproj 语言包
            if path.hasSuffix(".lproj") && path.contains(".app/Contents/Resources") {
                return (false, "[Redline] In-place stripping of application language packs (.lproj) is strictly prohibited to preserve code signing integrity")
            }

            // 3. 彻底封锁对应用包内部任何子项的删除（必须保护代码签名封印 CodeResources）
            let resolved = targetURL.resolvingSymlinksInPath()
            if isInsideApplicationBundle(targetURL) || isInsideApplicationBundle(resolved) {
                return (false, "[Redline] Direct modification or deletion of components inside an application bundle is strictly prohibited to preserve code signing integrity")
            }
        }

        return (true, nil)
    }

    // MARK: - 全链路安全风控综合裁决

    /// 对待清理目标执行综合安全裁决（整合白名单、Sequoia、ANE、SymlinkGuard、ProcessGuard、GitGuard）
    static func validateCleanTarget(
        url: URL,
        action: ItemAction,
        parentRuleID: String? = nil,
        requireCurrentUserUID: Bool = true
    ) -> (isSafe: Bool, reason: String?) {
        // 1. 动作许可校验
        let actionCheck = isActionPermitted(action: action, url: url)
        guard actionCheck.permitted else {
            return (false, actionCheck.reason)
        }

        // 虚拟项特例：APFS purge 与 Docker prune 路径为空字符串，直接放行交由专用指令安全执行
        if (action == .apfsPurge || action == .dockerPrune) && url.path.isEmpty {
            return (true, nil)
        }

        let path = url.standardizedFileURL.path

        // 1.5 用户自定义排除白名单双向保护 (支持目录级双向递归保护)
        if !path.isEmpty && AppConfigStore.shared.isPathIgnoredForDeletion(path) {
            return (false, tr(.targetProtectedByWhitelistBlocked))
        }

        // 1.6 目录级清理深度风控（针对常规清理项执行子树深度资产风控；废纸篓永久删除项由 TrashDeletion 私有受控机制负责）
        if action != .permanentlyDeleteTrashItem {
            let scope = CleanupSafetyPolicy.inspect(
                url,
                parentRuleID: parentRuleID,
                requireCurrentUserUID: requireCurrentUserUID
            )
            guard scope.isSafe else { return scope }
        }

        // 2. 物理红线校验 (FileUtil.isProtected)
        if FileUtil.isProtected(url) {
            return (false, "Target hit system protected physical path redline, operation forbidden")
        }

        // 3. 固化路径标记校验（Sequoia 设置、ANE 神经引擎等）
        for marker in protectedPathMarkers {
            if path.contains(marker) {
                return (false, "Target hit protected core system marker [\(marker)] (Sequoia Settings / ANE Engine / Critical Credentials)")
            }
        }

        // 4. 固化 Bundle Identifier 校验（针对沙盒容器、包组件及应用真身）
        let bid = url.lastPathComponent
        if protectedBundleIDs.contains(bid) {
            return (false, "Target belongs to protected system component Bundle ID [\(bid)]")
        }
        if url.pathExtension == "app" {
            let plistURL = url.appendingPathComponent("Contents/Info.plist")
            if let dict = NSDictionary(contentsOf: plistURL),
               let appBid = dict["CFBundleIdentifier"] as? String,
               protectedBundleIDs.contains(appBid) {
                return (false, "Target application belongs to protected system component Bundle ID [\(appBid)]")
            }
        }

        // 4.5. 防 Keychain 弹窗风暴与 EDR 安全端点拦截
        let lowBid = bid.lowercased()
        if AppConfig.Security.keychainStormProtectedDaemons.contains(lowBid) {
            return (false, "Target is protected keychain/identity daemon [\(bid)] to prevent prompt storms")
        }
        for edr in AppConfig.Security.edrTamperProtectedPrefixes {
            if path.contains(edr) || bid.hasPrefix(edr) {
                return (false, "Target belongs to protected EDR security software [\(edr)]")
            }
        }

        // 5. 符号链接防穿透逃逸校验 (SymlinkGuard)
        if !SymlinkGuard.isSafePath(url: url) {
            return (false, "Symlink escape risk detected or pointing to protected target; traversal blocked")
        }

        // 6. 活跃进程校验 (ProcessGuard)
        let procCheck = ProcessGuard.shouldSkipDueToRunningProcess(path: path)
        if procCheck.skip {
            return (false, procCheck.reason ?? "Target application is currently running")
        }

        // 7. Git 跟踪与敏感私钥资产避让 (GitGuard)
        if GitGuard.hasGitTrackedFiles(url: url) {
            return (false, L10n.localized(.cleanSkippedProtected))
        }

        return (true, nil)
    }

    // MARK: - 类别判定

    static func category(of item: ScanItem) -> CleanCategory {
        let path = item.url.standardizedFileURL.path
        let note = item.note
        let lowerNote = note.lowercased()

        // 动作优先: 架构切片 (标记为不可选类别)
        if case .thinBinary = item.action { return .archSlice }

        // 重复副本
        if note.contains(L10n.localized(.noteDuplicateCopy)) || lowerNote.contains("duplicate copy") { return .duplicateCopy }

        // iOS 设备备份
        if path.contains(iOSBackupRootMarker) { return .iOSBackup }

        // 语言包
        if path.hasSuffix(".lproj") { return .languagePack }

        // 损坏项
        if lowerNote.contains("corrupted") || lowerNote.contains("broken") || lowerNote.contains("unresolved")
            || lowerNote.contains("missing") || lowerNote.contains("invalid residue") {
            return .brokenItem
        }

        // 开发编译缓存
        for marker in devCacheMarkers where path.contains(marker) { return .devCache }

        // 用户内容区(家目录下非 Library 区)
        let home = FileUtil.home.standardizedFileURL.path
        if path.hasPrefix(home + "/") && !path.hasPrefix(home + "/Library") {
            if path.contains("/.Trash") || path.contains("/.Trashes/") { return .trashContent }
            return .userContent
        }

        // 系统级(/Library、/System、/private 等家门外)
        if !path.hasPrefix(home) { return .systemLevel }

        // 常规缓存
        if path.contains("/Caches/") { return .safeCache }

        // 诊断日志(含崩溃报告目录)
        if path.contains("/Logs") || path.contains("CrashReporter") || path.contains("DiagnosticReports") {
            return .diagnosticLog
        }

        return .unknown
    }

    /// Node 版类别判定
    static func category(of node: Node) -> CleanCategory {
        guard let url = node.url else { return .unknown }
        let lowerNote = node.note.lowercased()
        if node.note.contains(L10n.localized(.noteDuplicateCopy)) || lowerNote.contains("duplicate copy") { return .duplicateCopy }
        let item = ScanItem(url: url, name: node.name, size: node.totalSize,
                            note: node.note, safety: node.safety, action: node.action)
        return category(of: item)
    }

    // MARK: 确认弹窗 (F1)

    static func requiresConfirmation(_ item: ScanItem) -> Bool {
        if item.safety != .safe || item.ruleEvidence?.tier != .automatic { return true }
        if item.action == .permanentlyDeleteTrashItem { return true }
        if !item.badge.isEmpty { return true }
        return category(of: item).requiresManualConfirmation
    }

    static func requiresConfirmation(_ node: Node) -> Bool {
        if node.safety != .safe || node.ruleEvidence?.tier != .automatic { return true }
        if node.action == .permanentlyDeleteTrashItem { return true }
        if let badge = node.badge, !badge.isEmpty { return true }
        return category(of: node).requiresManualConfirmation
    }

    static func requiresConfirmation(_ target: CleanTarget) -> Bool {
        if target.safety != .safe || target.ruleEvidence?.tier != .automatic { return true }
        switch target.action {
        case .permanentlyDeleteTrashItem, .dockerPrune, .simctlRuntimeDelete, .apfsPurge: return true
        default: return false
        }
    }

    // MARK: iOS 备份:最新一份保护

    static func applyLatestBackupProtection(_ backups: [ScanItem]) -> [ScanItem] {
        var items = backups
        guard !items.isEmpty else { return items }
        var newestIdx = 0
        var newestDate = Date.distantPast
        for i in items.indices {
            let d = modificationDate(of: items[i].url)
            if d > newestDate { newestDate = d; newestIdx = i }
        }
        items[newestIdx].badge = L10n.localized(.statusLatest)
        items[newestIdx].note += " · \(L10n.localized(.noteNewestBackupKeep))"
        items[newestIdx].isSelected = false
        return items
    }

    private static func modificationDate(of url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
    }
}
