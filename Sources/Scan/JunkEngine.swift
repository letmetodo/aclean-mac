import Foundation
import AppKit

// MARK: - 系统垃圾引擎
//
// 系统垃圾扫描涵盖以下核心子任务:
//   用户/系统/开发缓存、日志、损坏的偏好设置、损坏的启动项、
//   已删除用户残留、文档版本历史、应用多语言资源、
//   设备备份、App Store 下载缓存、符号缓存、快速查看缓存、
//   Electron 应用缓存、Gradle/工具链缓存等。
//
// 规则来源(重构后):
//   · 缓存/日志/Xcode 的靶向路径规则 —— 全部来自 cleanmate_rules.db
//     (KnowledgeBaseManager 动态加载,替代原 CachesKB/LogsKB 硬编码数组);
//   · 目录遍历策略(枚举 Caches/Logs 子项、扫描 .app 内 lproj/lipo)属于
//     「扫描方式」而非「路径规则」,保留实现,但每个候选均经规则库白名单
//     (protectedBundleIDs / protectedPaths)与 RiskControlMatrix 双重过滤;
//   · 默认勾选与规则分级由 JunkRulePolicy.apply 统一裁决。

enum JunkEngine {

    // MARK: - 白名单(规则库降级时的兜底)

    /// 规则库不可用时的最小保护集(收敛至 AppConfig.Security)
    static var fallbackIgnoreBundleIDs: Set<String> {
        AppConfig.Security.fallbackIgnoreBundleIDs
    }

    private static let fallbackIgnoreBundleIDsLower: Set<String> = Set(
        AppConfig.Security.fallbackIgnoreBundleIDs.map { $0.lowercased() }
    )
    private static let protectedBundleIDsLower: Set<String> = Set(
        RiskControlMatrix.protectedBundleIDs.map { $0.lowercased() }
    )
    private static let lowerProtectedPathMarkers: [String] = AppConfig.Security.protectedPathMarkers.map { $0.lowercased() }

    static var kb: KnowledgeBaseManager { KnowledgeBaseManager.shared }

    /// 统一白名单查询:兜底受保护 BundleID + 规则库 + RiskControlMatrix 深度裁决 (O(1) 极速查询)
    static func isIgnoredBundleID(_ bid: String) -> Bool {
        if ProtectedAssetPolicy.isProtectedIdentity(bid) { return true }
        let low = bid.lowercased()
        if fallbackIgnoreBundleIDsLower.contains(low) { return true }
        if protectedBundleIDsLower.contains(low) { return true }
        if kb.isLoaded && kb.isProtected(bundleID: bid) { return true }
        return false
    }

    /// 统一路径白名单:用户自定义前缀白名单 + 规则库 + 物理红线(FileUtil.isProtected) + 云盘与 TCC 避让
    static func isIgnoredPath(_ path: String) -> Bool {
        if ProtectedAssetPolicy.isProtected(URL(fileURLWithPath: path)) { return true }
        if FileUtil.isTCCOrApplePrivateBlocked(path) { return true }
        if AppConfigStore.shared.isPathIgnoredForDisplay(path) { return true }
        let url = URL(fileURLWithPath: path)
        if FileUtil.isProtected(url) { return true }
        if isCloudOrSyncProviderPath(path) { return true }
        let lower = path.lowercased()
        if lowerProtectedPathMarkers.contains(where: { lower.contains($0) }) { return true }
        if kb.isLoaded {
            if kb.isProtectedPath(path) { return true }
            if kb.isProtectedRoot(path) { return true }
        }
        return false
    }

    /// 避让云盘提供者与同步工作区（严格遵循 DNA 宪章，严防数据冲突与重新全量下载）
    static func isCloudOrSyncProviderPath(_ path: String) -> Bool {
        let p = path.lowercased()
        if p.contains("/developer/xcode/")
            || p.contains("/symbols/system/library/")
            || p.contains(".framework")
            || p.contains(".appex")
            || p.contains(".axbundle")
            || p.contains("/library/logs/com.apple.cloudtelemetry") {
            return false
        }
        let forbiddenMarkers = AppConfig.Security.cloudPathMarkers
        for marker in forbiddenMarkers {
            if marker == "fileprovider" {
                if p.contains("/fileprovider/") || p.hasSuffix("/fileprovider") || p.contains("com.apple.fileprovider") {
                    return true
                }
                continue
            }
            if p.contains(marker) { return true }
        }
        return false
    }

    /// 检查候选路径是否具备读取（及目录遍历）权限，静默跳过受 TCC 或 root 权限锁定的目录/文件
    static func isAccessibleCandidate(_ path: String) -> Bool {
        if FileUtil.isTCCOrApplePrivateBlocked(path) { return false }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir) else { return false }
        if isDir.boolValue {
            guard access(path, R_OK | X_OK) == 0, let dirp = opendir(path) else { return false }
            closedir(dirp)
            return true
        }
        return access(path, R_OK) == 0
    }

    /// 苹果官方应用与系统级受保护应用白名单（绝不能修改其内部资源或二进制，防止破坏 Gatekeeper 签名）
    static func isAppleOrProtectedApp(_ url: URL) -> Bool {
        let p = url.standardizedFileURL.path
        if p.hasPrefix("/System/") || p.hasPrefix("/Library/Apple/") { return true }

        // 向上查找所属 .app 的根路径
        var cur = url
        var appURL: URL? = nil
        while cur.path != "/" && cur.pathComponents.count > 1 {
            if cur.pathExtension == "app" {
                appURL = cur
                break
            }
            cur = cur.deletingLastPathComponent()
        }

        guard let app = appURL else {
            return p.contains("com.apple.")
        }

        let appName = app.deletingPathExtension().lastPathComponent.lowercased()
        let protectedNames: Set<String> = [
            "pages", "keynote", "numbers", "logic pro", "logic pro x",
            "final cut pro", "motion", "compressor", "mainstage", "mainstage 3",
            "garageband", "imovie", "xcode", "safari", "books", "music",
            "podcasts", "tv", "news", "shortcuts", "freeform", "system settings",
            "system preferences", "app store", "testflight"
        ]
        if protectedNames.contains(appName) { return true }

        // 读取应用包内 Info.plist 校验 Bundle Identifier
        let plistURL = app.appendingPathComponent("Contents/Info.plist")
        if let d = autoreleasepool(invoking: { NSDictionary(contentsOf: plistURL) }),
           let bid = (d["CFBundleIdentifier"] as? String)?.lowercased() {
            if bid.hasPrefix("com.apple.") { return true }
        }

        return false
    }

    // MARK: 入口

    typealias ScanTaskRunner = @Sendable (_ progress: ((Double, String) -> Void)?, _ isStopped: (@Sendable () -> Bool)?) -> ScanGroup?

    /// 系统垃圾引擎所有任务定义清单（对齐安全红线：不默认挂载在位修改二进制或语言包的红线任务）
    /// 任务编排原则：将轻量秒级扫描（日志、登录项、包管理器缓存）排在前面，使得 UI 能在 50~100ms 内即时流式呈现首批数据
    static let taskDefinitions: [(name: String, run: ScanTaskRunner)] = [
        ("System Log Files",           { _, _ in scanSystemLogs() }),
        ("User Log Files",             { _, _ in scanUserLogs() }),
        ("Broken Login Items",         { _, _ in scanBrokenStartupItems() }),
        ("Homebrew Cache",             { _, _ in scanHomebrewCache() }),
        ("Docker & Container Cache",   { _, _ in scanDockerCache() }),
        ("Package Manager Caches",     { _, _ in scanPackageManagerCaches() }),
        ("System Cache Files",         { _, _ in scanSystemCaches() }),
        ("Broken Preference Files",    { _, _ in scanBrokenPreferences() }),
        ("Deleted Users",              { _, _ in scanDeletedUsers() }),
        ("Document Versions",          { _, _ in scanDocumentVersions() }),
        ("32-bit Applications",        { _, _ in scan32BitApps() }),
        ("App Store Download Cache",   { _, _ in scanAppStoreCache() }),
        ("Unused Disk Images",         { _, _ in scanUnusedDiskImages() }),
        ("iOS Device Backups",         { _, _ in scanMobileBackups() }),
        ("Targeted Application Cache", { _, _ in scanHardcodedPathCache() }),
        ("User Cache Files",           { p, s in scanUserCaches(progress: p, isStopped: s) }),
        ("Electron App Cache",         { _, _ in scanElectronCaches() }),
        ("Xcode Junk",                 { _, _ in scanXcodeJunk() }),
        ("Gradle Cache",               { _, _ in scanGradleCache() }),
        ("Developer Project Artifacts", { p, s in scanProjectArtifacts(progress: p, isStopped: s) }),
        ("Trash",                      { _, _ in scanTrash() }),
    ]

    /// 对外公开的扫描任务标题清单（用于合规自检与界面展示）
    static var taskNames: [String] {
        taskDefinitions.map { $0.name }
    }

    private static let telemetryLock = NSLock()
    private static let _lastTelemetrySnapshotStorage = LockedValue<ScanTelemetrySnapshot?>(nil)
    private static var _lastTelemetrySnapshot: ScanTelemetrySnapshot? {
        get { _lastTelemetrySnapshotStorage.withValue { $0 } }
        set { _lastTelemetrySnapshotStorage.withValue { $0 = newValue } }
    }

    /// 最近一次扫描的结构化诊断快照
    static var lastTelemetrySnapshot: ScanTelemetrySnapshot? {
        get {
            telemetryLock.lock()
            defer { telemetryLock.unlock() }
            return _lastTelemetrySnapshot
        }
        set {
            telemetryLock.lock()
            _lastTelemetrySnapshot = newValue
            telemetryLock.unlock()
        }
    }

    private static func countLeafItems(_ items: [ScanItem]) -> Int {
        var total = 0
        for item in items {
            if item.children.isEmpty {
                total += 1
            } else {
                total += countLeafItems(item.children)
            }
        }
        return total
    }

    /// 组标题全部沿用原版 zh-Hans 字符串（system_junk_*_group_title 等），
    /// 并通过 RuleAwareDeduplicator 在规则评估后执行同路径与父子重叠去重及留痕。
    static func scan(
        progress: @escaping (Double, String) -> Void,
        isStopped: (@Sendable () -> Bool)? = nil,
        deduplicateGroups: Bool = true,
        onGroupFound: ((ScanGroup) -> Void)? = nil
    ) -> [ScanGroup] {
        let context = IOScanContext.current ?? IOScanContext(stopped: { isStopped?() == true })
        return context.perform {
            let scanStart = CFAbsoluteTimeGetCurrent()
            _ = KnowledgeBaseManager.shared.authored.auditRuleScanEntries()
            var groups: [ScanGroup] = []
            var deduplicator = RuleAwareDeduplicator()

            let total = max(1, taskDefinitions.count)
            for (i, t) in taskDefinitions.enumerated() {
                if isStopped?() == true { break }
                let baseP = Double(i) / Double(total)
                let spanP = 1.0 / Double(total)
                progress(max(0.03, baseP), t.name)

                let taskProgress: (Double, String) -> Void = { subP, subName in
                    let currentP = baseP + spanP * max(0.0, min(1.0, subP))
                    progress(max(0.03, currentP), subName)
                }
                let runStart = CFAbsoluteTimeGetCurrent()
                let rawGroup = autoreleasepool { t.run(taskProgress, isStopped) }
                let runMs = (CFAbsoluteTimeGetCurrent() - runStart) * 1000.0
                let rawCount = rawGroup.map { countLeafItems($0.items) } ?? 0
                var acceptMs: Double = 0
                var dedupCount = 0

                if let rawGroup, !rawGroup.items.isEmpty {
                    let acceptStart = CFAbsoluteTimeGetCurrent()
                    if deduplicateGroups {
                        if let g = deduplicator.acceptGroup(rawGroup, into: &groups) {
                            acceptMs = (CFAbsoluteTimeGetCurrent() - acceptStart) * 1000.0
                            dedupCount = countLeafItems(g.items)
                            onGroupFound?(g)
                        } else {
                            acceptMs = (CFAbsoluteTimeGetCurrent() - acceptStart) * 1000.0
                        }
                    } else {
                        var evaluatedGroup = rawGroup
                        evaluatedGroup.items = rawGroup.items
                            .map(JunkRulePolicy.apply)
                            .filter { !JunkRulePolicy.isEmptyVerifiedContainer($0) }
                        acceptMs = (CFAbsoluteTimeGetCurrent() - acceptStart) * 1000.0
                        dedupCount = countLeafItems(evaluatedGroup.items)
                        if !evaluatedGroup.items.isEmpty {
                            groups.append(evaluatedGroup)
                            onGroupFound?(evaluatedGroup)
                        }
                    }
                }
                IOScanContext.recordTaskTelemetry(
                    ScanTaskTelemetry(
                        taskName: t.name,
                        runMs: runMs,
                        acceptMs: acceptMs,
                        rawCandidateCount: rawCount,
                        deduplicatedLeafCount: dedupCount
                    )
                )
            }
            func collectedPaths(_ items: [ScanItem]) -> Set<String> {
                Set(items.flatMap { [$0.url.standardizedFileURL.path] + Array(collectedPaths($0.children)) })
            }
            let discovered = groups.reduce(into: Set<String>()) { $0.formUnion(collectedPaths($1.items)) }
            if let extra = scanRuleBoundPaths(excluding: discovered, stopped: { isStopped?() == true }) {
                if let accepted = deduplicator.acceptGroup(extra, into: &groups) { onGroupFound?(accepted) }
            }
            let totalWallMs = (CFAbsoluteTimeGetCurrent() - scanStart) * 1000.0
            IOScanContext.markTotalWallTimeMs(totalWallMs)
            lastTelemetrySnapshot = IOScanContext.currentTelemetrySnapshot()
            progress(1, L10n.localized(.statusCompleted))
            return groups
        }
    }

    // MARK: 0) APFS 可清除空间 (URLResourceValues 差值算法 + 原生 diskutil 触发)

    static func scanAPFSPurgeable() -> ScanGroup? {
        let rootURL = URL(fileURLWithPath: "/")
        guard let v = try? rootURL.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]) else { return nil }

        let important = Int64(v.volumeAvailableCapacityForImportantUsage ?? 0)
        let regular = Int64(v.volumeAvailableCapacity ?? 0)
        let purgeable = max(0, important - regular)

        // 仅当可回收空间大于 50MB 时提示
        guard purgeable > 50 * 1024 * 1024 else { return nil }

        let item = ScanItem(
            url: URL(string: "apfs-purgeable://")!, // 虚拟协议标记为 apfs-purgeable，路径为空字符串，严禁设为 "/"
            name: "APFS Purgeable Space",
            size: purgeable,
            note: "macOS-managed snapshots and temporary caches, reclaimable via APFS native calls",
            safety: .safe,
            action: .apfsPurge,
            isSelected: true
        )

        return ScanGroup(
            title: "APFS Purgeable Space",
            icon: "internaldrive",
            note: "Snapshots and temporary blocks marked reclaimable on APFS volume",
            tileKey: "systemJunk",
            safety: .safe,
            items: [item]
        )
    }

    // MARK: 0.5) Homebrew 缓存 (BrewHelper)

    static func scanHomebrewCache() -> ScanGroup? {
        let items = BrewHelper.scan()
        guard !items.isEmpty else { return nil }
        return ScanGroup(
            title: "Homebrew Cache",
            icon: "shippingbox",
            note: "Downloaded software archives and installer packages from Homebrew",
            tileKey: "systemJunk",
            safety: .safe,
            items: items.sorted { $0.size > $1.size }
        )
    }

    // MARK: 0.6) Docker 与容器缓存 (DockerHelper 虚实解耦)

    static func scanDockerCache() -> ScanGroup? {
        var items: [ScanItem] = []
        items.append(contentsOf: DockerHelper.scanHostPhysicalItems())
        if let virtualItem = DockerHelper.scanVirtualPruneItem() {
            items.append(virtualItem)
        }
        guard !items.isEmpty else { return nil }
        return ScanGroup(
            title: "Docker & Container Cache",
            icon: "shippingbox.circle",
            note: "Docker & OrbStack host service logs, build cache, and unused containers",
            tileKey: "systemJunk",
            safety: .safe,
            items: items.sorted { $0.size > $1.size }
        )
    }

    // MARK: 1) 缓存

    /// 用户缓存:常规 ~/Library/Caches 目录遍历
    /// + 沙盒应用容器动态枚举 (Containers/*/Data/Library/Caches & Group Containers/*/Library/Caches)
    /// + HTTPStorages 会话状态保留
    /// + 符号链接防穿透逃逸校验与规则库安全白名单过滤。
    static func scanUserCaches(progress: ((Double, String) -> Void)? = nil, isStopped: (@Sendable () -> Bool)? = nil) -> ScanGroup? {
        var byGroup: [String: [ScanItem]] = [:]
        var order: [String] = []

        progress?(0.10, "User App Cache")
        if isStopped?() == true { return nil }

        // 1) 常规 ~/Library/Caches 目录遍历（受规则库排除白名单与 RiskControlMatrix 双重保护，所有候选进入统一规则评估与去重）
        let caches = RuleRoot.homeLibrary.base.appendingPathComponent("Caches")
        let cacheChildren = FileUtil.children(of: caches)
        let browserUmbrellaCacheDirs: Set<String> = AppConfig.JunkScan.userCacheUmbrellaSkipDirs
        var cacheCandidates: [(url: URL, name: String)] = []
        for child in cacheChildren {
            let name = child.lastPathComponent
            let lowName = name.lowercased()
            // 排除所有 Apple 系统与第一方核心组件缓存，以及由专项 Profile 规则 (JC.BRW.*) 接管的浏览器顶层伞目录
            if lowName.hasPrefix("com.apple.") || browserUmbrellaCacheDirs.contains(lowName) { continue }
            let p = child.standardizedFileURL.path
            guard isAccessibleCandidate(p) else { continue }
            if isIgnoredBundleID(name) { continue }
            if isIgnoredPath(p) { continue }
            guard SymlinkGuard.isSafePath(url: child) else { continue }
            cacheCandidates.append((child, name))
        }

        let store = KnowledgeBaseManager.shared.authored
        progress?(0.25, "User App Cache")
        if !cacheCandidates.isEmpty {
            let cacheSizes = ScanResultSlots<Int64>(repeating: 0, count: cacheCandidates.count)
            IOScanContext.concurrentPerform(iterations: cacheCandidates.count) { [cacheCandidates] i in
                if isStopped?() == true { return }
                let url = cacheCandidates[i].url
                if !store.isTrashChildrenOnlyContainer(url) {
                    cacheSizes[i] = FileUtil.size(of: url)
                }
            }
            var others: [ScanItem] = []
            for (i, cand) in cacheCandidates.enumerated() {
                if store.isTrashChildrenOnlyContainer(cand.url) {
                    if let containerItem = JunkRulePolicy.makeMeasuredCandidate(
                        url: cand.url,
                        name: cand.name,
                        note: "App Cache",
                        safety: .safe,
                        minBytes: 1024 * 200
                    ) {
                        others.append(containerItem)
                    }
                    continue
                }
                let s = cacheSizes[i]
                guard s > 1024 * 200 else { continue }
                let item = ScanItem(url: cand.url, name: cand.name, size: s,
                                    note: "App Cache", safety: .safe)
                others.append(item)
            }
            if !others.isEmpty {
                order.append("App Cache")
                byGroup["App Cache", default: []].append(contentsOf: others)
            }
        }

        // 2) 沙盒应用容器动态穿透遍历 (~/Library/Containers/*/Data/Library/Caches)
        let containersRoot = RuleRoot.homeLibrary.base.appendingPathComponent("Containers")
        if isAccessibleCandidate(containersRoot.path) {
            let containerChildren = FileUtil.children(of: containersRoot)
            var containerCandidates: [(url: URL, bid: String, childName: String)] = []

            for container in containerChildren {
                if isStopped?() == true { return nil }
                let bid = container.lastPathComponent
                let lowBid = bid.lowercased()
                if (lowBid.hasPrefix("com.apple.") && !lowBid.hasPrefix("com.apple.dt.")) || isIgnoredBundleID(bid) { continue }
                let cachesDir = container.appendingPathComponent("Data/Library/Caches")
                guard isAccessibleCandidate(cachesDir.path) else { continue }

                for child in FileUtil.children(of: cachesDir) {
                    let p = child.standardizedFileURL.path
                    guard isAccessibleCandidate(p) else { continue }
                    if isIgnoredPath(p) { continue }
                    guard SymlinkGuard.isSafePath(url: child, within: cachesDir) else { continue }
                    containerCandidates.append((child, bid, child.lastPathComponent))
                }
            }

            progress?(0.55, "Sandbox Container Cache")
            if !containerCandidates.isEmpty {
                let containerSizes = ScanResultSlots<Int64>(repeating: 0, count: containerCandidates.count)
                IOScanContext.concurrentPerform(iterations: containerCandidates.count) { [containerCandidates] i in
                    if isStopped?() == true { return }
                    let url = containerCandidates[i].url
                    if !store.isTrashChildrenOnlyContainer(url) {
                        containerSizes[i] = FileUtil.size(of: url)
                    }
                }
                var containerItems: [ScanItem] = []
                for (i, cand) in containerCandidates.enumerated() {
                    let itemName = "\(cand.bid) · \(cand.childName)"
                    if store.isTrashChildrenOnlyContainer(cand.url) {
                        if let containerItem = JunkRulePolicy.makeMeasuredCandidate(
                            url: cand.url,
                            name: itemName,
                            note: "Sandbox Application Container Cache",
                            safety: .safe,
                            minBytes: 1024 * 200
                        ) {
                            containerItems.append(containerItem)
                        }
                        continue
                    }
                    let s = containerSizes[i]
                    guard s > 1024 * 200 else { continue }
                    let item = ScanItem(url: cand.url, name: itemName,
                                        size: s, note: "Sandbox Application Container Cache", safety: .safe)
                    containerItems.append(item)
                }
                if !containerItems.isEmpty {
                    order.append("Sandbox Container Cache")
                    byGroup["Sandbox Container Cache", default: []].append(contentsOf: containerItems)
                }
            }
        }

        // 3) Group Containers 穿透 (~/Library/Group Containers/*/Library/Caches)
        let groupContainersRoot = RuleRoot.homeLibrary.base.appendingPathComponent("Group Containers")
        if isAccessibleCandidate(groupContainersRoot.path) {
            let groupChildren = FileUtil.children(of: groupContainersRoot)
            var groupCandidates: [(url: URL, groupName: String, childName: String)] = []

            for groupDir in groupChildren {
                if isStopped?() == true { return nil }
                let groupName = groupDir.lastPathComponent
                let lowGroupName = groupName.lowercased()
                if lowGroupName.hasPrefix("group.com.apple.")
                    || lowGroupName.hasPrefix("com.apple.")
                    || lowGroupName.contains(".com.apple.")
                    || isIgnoredBundleID(groupName)
                    || isCloudOrSyncProviderPath(groupName) { continue }
                let cachesDir = groupDir.appendingPathComponent("Library/Caches")
                guard isAccessibleCandidate(cachesDir.path) else { continue }

                for child in FileUtil.children(of: cachesDir) {
                    let p = child.standardizedFileURL.path
                    guard isAccessibleCandidate(p) else { continue }
                    if isIgnoredPath(p) { continue }
                    guard SymlinkGuard.isSafePath(url: child, within: cachesDir) else { continue }
                    groupCandidates.append((child, groupName, child.lastPathComponent))
                }
            }

            progress?(0.80, "Group Container Cache")
            if !groupCandidates.isEmpty {
                let groupSizes = ScanResultSlots<Int64>(repeating: 0, count: groupCandidates.count)
                IOScanContext.concurrentPerform(iterations: groupCandidates.count) { [groupCandidates] i in
                    if isStopped?() == true { return }
                    let url = groupCandidates[i].url
                    if !store.isTrashChildrenOnlyContainer(url) {
                        groupSizes[i] = FileUtil.size(of: url)
                    }
                }
                var groupItems: [ScanItem] = []
                for (i, cand) in groupCandidates.enumerated() {
                    let itemName = "\(cand.groupName) · \(cand.childName)"
                    if store.isTrashChildrenOnlyContainer(cand.url) {
                        if let containerItem = JunkRulePolicy.makeMeasuredCandidate(
                            url: cand.url,
                            name: itemName,
                            note: "Shared Group Container Cache",
                            safety: .safe,
                            minBytes: 1024 * 200
                        ) {
                            groupItems.append(containerItem)
                        }
                        continue
                    }
                    let s = groupSizes[i]
                    guard s > 1024 * 200 else { continue }
                    let item = ScanItem(url: cand.url, name: itemName,
                                        size: s, note: "Shared Group Container Cache", safety: .safe)
                    groupItems.append(item)
                }
                if !groupItems.isEmpty {
                    order.append("Group Container Cache")
                    byGroup["Group Container Cache", default: []].append(contentsOf: groupItems)
                }
            }
        }

        // 4) 浏览器 Profile 级缓存发现 (Chromium Default/Profile * & Firefox Profiles/*/cache2 + startupCache)
        let browserProfileItems = scanBrowserCacheItems(minBytes: 1024 * 200)
        if !browserProfileItems.isEmpty {
            order.append("Browser Profile Cache")
            byGroup["Browser Profile Cache", default: []].append(contentsOf: browserProfileItems)
        }

        let evaluated = order.compactMap { byGroup[$0] }.flatMap { $0 }.map(JunkRulePolicy.apply)
        let items = RuleAwareDeduplicator.deduplicate(evaluated).items
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "User Cache Files", icon: "internaldrive",
                         note: "Application runtime caches, safe to clean",
                         tileKey: "systemJunk",
                         safety: .safe, items: items.sorted { $0.size > $1.size })
    }

    static func scanSystemCaches() -> ScanGroup? {
        var items: [ScanItem] = []
        // /Library/Caches 为目录遍历策略根(非规则库条目),子项逐个过白名单
        for root in [RuleRoot.rootLibrary.base.appendingPathComponent("Caches")] {
            guard FileUtil.exists(root.path) else { continue }
            for child in FileUtil.children(of: root) {
                let name = child.lastPathComponent
                let lowName = name.lowercased()
                if lowName.hasPrefix("com.apple.") && !lowName.hasPrefix("com.apple.dt.") { continue }
                let p = child.standardizedFileURL.path
                if isIgnoredPath(p) || isIgnoredBundleID(name) { continue }
                guard SymlinkGuard.isSafePath(url: child, within: root) else { continue }
                let s = FileUtil.size(of: child)
                guard s > 1024 * 200 else { continue }
                let item = ScanItem(url: child, name: "System Cache · \(name)",
                                    size: s, note: "/Library/Caches", safety: .caution, isSelected: false, measuredBytes: s)
                items.append(JunkRulePolicy.apply(item))
            }
        }
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "System Cache Files", icon: "gearshape.2",
                         note: "System-level caches, some require administrator privileges",
                         tileKey: "systemJunk",
                         safety: .caution, items: items.sorted { $0.size > $1.size })
    }

    // MARK: 2) 用户 / 系统日志（原版把崩溃报告归并到日志里，不单列）

    /// 按层级精准扫描日志与崩溃/卡死诊断报告（避免单次调用同时扫描用户与系统两套目录并丢弃一半）。
    private static func collectLogs(isUser: Bool) -> [ScanItem] {
        let crashDirs: Set<String> = ["DiagnosticReports", "CrashReporter", "HangReporter", "Retired"]
        var items: [ScanItem] = []

        let root: RuleRoot = isUser ? .homeLibrary : .rootLibrary
        let label = isUser ? "User Logs" : "System Logs"

        // 1. 常规日志目录遍历：用户 ~/Library/Logs 或系统 /Library/Logs
        let base = root.base.appendingPathComponent("Logs")
        if isAccessibleCandidate(base.path) {
            for child in FileUtil.children(of: base) {
                let childName = child.lastPathComponent
                if crashDirs.contains(childName) { continue }
                if childName.lowercased().hasPrefix("com.apple.cloudtelemetry") { continue }
                let p = child.standardizedFileURL.path
                guard isAccessibleCandidate(p) else { continue }
                if isIgnoredPath(p) { continue }
                guard SymlinkGuard.isSafePath(url: child, within: base) else { continue }
                guard let candidate = JunkRulePolicy.makeMeasuredCandidate(
                    url: child,
                    name: "\(label) · \(childName)",
                    note: "Logs",
                    safety: isUser ? .safe : .caution,
                    minBytes: 1024 * 20
                ) else { continue }
                items.append(candidate)
            }
        }

        // 2. 崩溃 / 卡死诊断报告
        let crashSpecs: [(String, String)] = isUser ? [
            ("Logs/DiagnosticReports", "User Diagnostic Reports"),
            ("Logs/CrashReporter",     "User Crash Reports (Legacy)"),
            ("Logs/HangReporter",      "User Hang Reports"),
            ("Application Support/CrashReporter", "User Crash Reports"),
        ] : [
            ("Logs/DiagnosticReports", "System Diagnostic Reports"),
            ("Logs/CrashReporter",     "System Crash Reports"),
        ]

        for (sub, crashLabel) in crashSpecs {
            let b = root.base.appendingPathComponent(sub)
            guard isAccessibleCandidate(b.path) else { continue }
            for child in FileUtil.children(of: b) {
                let childName = child.lastPathComponent
                if childName.lowercased().hasPrefix("com.apple.cloudtelemetry") { continue }
                let p = child.standardizedFileURL.path
                guard isAccessibleCandidate(p) else { continue }
                if isIgnoredPath(p) { continue }
                guard SymlinkGuard.isSafePath(url: child, within: b) else { continue }
                guard let candidate = JunkRulePolicy.makeMeasuredCandidate(
                    url: child,
                    name: "\(crashLabel) · \(childName)",
                    note: sub,
                    safety: isUser ? .safe : .caution,
                    minBytes: 0
                ) else { continue }
                items.append(candidate)
            }
        }
        var evaluated = items.map(JunkRulePolicy.apply)
        if isUser {
            evaluated = drillDownMixedUserLogDirectories(evaluated)
        }
        return RuleAwareDeduplicator.deduplicate(evaluated).items
    }

    /// Gate 5.3: 当 ~/Library/Logs/<App> 内存在混入 .json/.txt/.db-wal 的混合子目录导致整子目录降级为 L2 时，
    /// 下钻枚举其中符合日志后缀、年龄与空闲条件的单文件作为 L1 候选，跳过非日志状态文件。
    static func drillDownMixedUserLogDirectories(_ items: [ScanItem]) -> [ScanItem] {
        var result: [ScanItem] = []
        let logExts = AppConfig.Remediation.logExtensions
        for var item in items {
            guard !item.children.isEmpty else {
                result.append(item)
                continue
            }
            var newChildren: [ScanItem] = []
            for child in item.children {
                if child.locked != true,
                   child.ruleEvidence?.tier == .review,
                   child.ruleEvidence?.id == "JC.LOG.USER",
                   child.fileIdentity?.isDirectory == true {
                    var extractedLogs: [ScanItem] = []
                    if let enumerator = FileManager.default.enumerator(
                        at: child.url,
                        includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
                        options: [.skipsHiddenFiles]
                    ) {
                        for case let fileURL as URL in enumerator {
                            if IOScanContext.isCancelled { break }
                            let p = fileURL.standardizedFileURL.path
                            if isIgnoredPath(p) { continue }
                            guard SymlinkGuard.isSafePath(url: fileURL, within: child.url) else { continue }
                            let ext = fileURL.pathExtension.lowercased()
                            guard logExts.contains(ext) else { continue }
                            guard let identity = FileIdentity.capture(from: fileURL),
                                  (identity.mode & S_IFMT) == S_IFREG else { continue }
                            if let leafCand = JunkRulePolicy.makeMeasuredCandidate(
                                url: fileURL,
                                name: "\(item.name) · \(fileURL.lastPathComponent)",
                                note: "Logs",
                                safety: .safe,
                                minBytes: 1024
                            ) {
                                let evalLeaf = JunkRulePolicy.apply(leafCand)
                                if evalLeaf.locked != true {
                                    extractedLogs.append(evalLeaf)
                                }
                            }
                        }
                    }
                    if !extractedLogs.isEmpty {
                        newChildren.append(contentsOf: extractedLogs)
                        continue
                    }
                }
                newChildren.append(child)
            }
            item.children = newChildren
            let sum = newChildren.reduce(Int64(0)) { $0 + $1.size }
            item.size = sum
            item.measuredBytes = sum
            item.isSelected = newChildren.contains(where: \.isSelected)
            result.append(item)
        }
        return result
    }

    static func scanUserLogs() -> ScanGroup? {
        let items = collectLogs(isUser: true)
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "User Log Files", icon: "doc.text",
                         note: "Application logs and crash diagnostic reports",
                         tileKey: "systemJunk",
                         safety: .safe, items: items.sorted { $0.size > $1.size })
    }

    static func scanSystemLogs() -> ScanGroup? {
        let items = collectLogs(isUser: false)
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "System Log Files", icon: "doc.text",
                         note: "System logs, some require administrator privileges",
                         tileKey: "systemJunk",
                         safety: .caution, items: items.sorted { $0.size > $1.size })
    }

    // MARK: 3) 损坏的偏好设置

    static func scanBrokenPreferences() -> ScanGroup? {
        let dir = RuleRoot.homeLibrary.base.appendingPathComponent("Preferences")
        var items: [ScanItem] = []
        for f in FileUtil.children(of: dir) where f.pathExtension == "plist" {
            let name = f.lastPathComponent
            if name.hasPrefix("com.apple.") || name.hasPrefix(".") { continue }
            if isIgnoredBundleID((name as NSString).deletingPathExtension) { continue }
            if isIgnoredPath(f.standardizedFileURL.path) { continue }
            guard !isValidPlist(f) else { continue }
            let s = max(FileUtil.size(of: f), 4096)
            var item = ScanItem(url: f, name: f.lastPathComponent, size: s,
                                note: "Unparseable preference file", safety: .caution, isSelected: false, measuredBytes: s)
            item.ruleEvidence = CleanupRuleEvidence(
                id: AppConfig.RuleIDs.brokenPlist,
                tier: .review,
                reason: .generalCache,
                defaultSelected: false
            )
            items.append(JunkRulePolicy.apply(item))
        }
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "Broken Preference Files", icon: "doc.badge.gearshape",
                         note: "Corrupted preferences unreadable by apps",
                         tileKey: "systemJunk",
                         safety: .caution,
                         items: items.sorted { $0.size > $1.size })
    }

    static func isValidPlist(_ url: URL) -> Bool {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attrs[.size] as? Int64, fileSize > 0 else { return true }
        // 超过 10MB 的配置文件保守视为有效，避免大文件占用过多内存
        if fileSize > 10 * 1024 * 1024 { return true }
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return true }
        if data.isEmpty { return false }
        return (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) != nil
    }

    // MARK: 4) 损坏的启动项

    static func scanBrokenStartupItems() -> ScanGroup? {
        let dirs: [(RuleRoot, String, String)] = [
            (.homeLibrary, "LaunchAgents", "User Login Item"),
            (.rootLibrary, "LaunchAgents", "Global Login Item"),
            (.rootLibrary, "LaunchDaemons", "System Daemon"),
        ]
        var items: [ScanItem] = []
        for (root, sub, label) in dirs {
            let dir = root.base.appendingPathComponent(sub)
            guard FileUtil.exists(dir.path) else { continue }
            for f in FileUtil.children(of: dir) where f.pathExtension == "plist" {
                if isIgnoredPath(f.standardizedFileURL.path) { continue }
                guard let program = programPath(of: f), !program.isEmpty else { continue }
                if resolveExecutablePath(program) == nil {
                    let s = max(FileUtil.size(of: f), 4096)
                    let item = ScanItem(
                        url: f,
                        name: f.lastPathComponent,
                        size: s,
                        note: "\(label) · Target binary no longer exists: \(program) (Read-only — verify manually in Finder)",
                        safety: .caution,
                        isSelected: false,
                        locked: true,
                        measuredBytes: s
                    )
                    items.append(JunkRulePolicy.apply(item))
                }
            }
        }

        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "Broken Login Items", icon: "bolt.slash",
                         note: "Target program has been removed; orphaned leftovers (Read-only — verify manually in Finder)",
                         tileKey: "systemJunk",
                         safety: .caution,
                         items: items.sorted { $0.size > $1.size })
    }

    /// 解析可执行程序路径（支持绝对路径与针对标准 PATH 的相对命令名解析，防止误判 sh/bash 等系统命令）
    static func resolveExecutablePath(_ program: String) -> String? {
        if program.hasPrefix("/") {
            return FileUtil.exists(program) ? program : nil
        }
        let standardPaths = ["/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/opt/homebrew/bin"]
        for dir in standardPaths {
            let full = "\(dir)/\(program)"
            if FileUtil.exists(full) {
                return full
            }
        }
        return nil
    }

    /// 读取 launchd plist 的可执行路径（严格遵循 launchd.plist 规范：优先读取 Program，缺省时再读取 ProgramArguments 首项）
    static func programPath(of plist: URL) -> String? {
        guard let data = try? Data(contentsOf: plist),
              let obj = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        else { return nil }
        if let p = obj["Program"] as? String, !p.isEmpty { return p }
        if let args = obj["ProgramArguments"] as? [String], let first = args.first, !first.isEmpty { return first }
        return nil
    }
}
