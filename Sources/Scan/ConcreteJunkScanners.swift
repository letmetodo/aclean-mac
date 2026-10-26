import Foundation
import AppKit

// ============================================================
//  JunkEngine+Scanners —— 系统垃圾专项扫描器扩展
//  (Xcode、Gradle、Electron、磁盘映像、备份、文档版本、废纸篓等)
// ============================================================

extension JunkEngine {

    // MARK: 5) 开发者包管理器缓存 (npm / pnpm / Yarn / Bun / Cargo / pip / uv / CocoaPods)

    static func scanPackageManagerCaches() -> ScanGroup? {
        let home = FileUtil.home.path
        let specs = AppConfig.JunkScan.packageManagerSpecs
        let store = KnowledgeBaseManager.shared.authored

        var candidates: [(url: URL, label: String, note: String)] = []
        var seenStdPaths = Set<String>()
        for (raw, label, note) in specs {
            let path = raw.replacingOccurrences(of: "~", with: home)
            guard FileUtil.exists(path), !isIgnoredPath(path) else { continue }
            let url = URL(fileURLWithPath: path)
            guard SymlinkGuard.isSafePath(url: url) else { continue }
            let std = url.standardizedFileURL.path
            seenStdPaths.insert(std)
            candidates.append((url, label, note))
        }
        if let npmLogsRule = store.junk[AppConfig.RuleIDs.npmLogs], npmLogsRule.active {
            for raw in npmLogsRule.paths where !raw.contains("*") && !raw.contains("{") {
                let path = KBPaths.expand(raw)
                guard FileUtil.exists(path), !isIgnoredPath(path) else { continue }
                let url = URL(fileURLWithPath: path)
                guard SymlinkGuard.isSafePath(url: url) else { continue }
                let std = url.standardizedFileURL.path
                guard seenStdPaths.insert(std).inserted else { continue }
                candidates.append((url, "npm debug logs", "npm installation debug logs"))
            }
        }
        // T02: JetBrains 仅发现 ~/Library/Caches/JetBrains/<受限版本名>/{caches,index,log,jcef_cache,tmp,compile-server} 六个精确叶
        let cachesParent = FileUtil.home.appendingPathComponent("Library/Caches")
        if !SymlinkGuard.isSymbolicLink(at: cachesParent),
           let cachesEntries = try? FileManager.default.contentsOfDirectory(atPath: cachesParent.path),
           cachesEntries.contains("JetBrains") {
            let jbRoot = cachesParent.appendingPathComponent("JetBrains")
            if !isIgnoredPath(jbRoot.path),
               !SymlinkGuard.isSymbolicLink(at: jbRoot),
               SymlinkGuard.isSafePath(url: jbRoot, within: cachesParent),
               let versionNames = try? FileManager.default.contentsOfDirectory(atPath: jbRoot.path) {
                for verName in versionNames.sorted() {
                    guard AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(
                        verName,
                        pattern: AppConfig.JunkScan.PathMatching.jetBrainsVersionName
                    ) else { continue }
                    let verDir = jbRoot.appendingPathComponent(verName)
                    var isVerDir: ObjCBool = false
                    guard !SymlinkGuard.isSymbolicLink(at: verDir),
                          SymlinkGuard.isSafePath(url: verDir, within: jbRoot),
                          FileManager.default.fileExists(atPath: verDir.path, isDirectory: &isVerDir),
                          isVerDir.boolValue,
                          let leafEntries = try? FileManager.default.contentsOfDirectory(atPath: verDir.path) else {
                        continue
                    }
                    let exactLeafSet = Set(leafEntries)
                    for leaf in AppConfig.JunkScan.jetBrainsAllowedLeaves where exactLeafSet.contains(leaf) {
                        let leafURL = verDir.appendingPathComponent(leaf)
                        var isLeafDir: ObjCBool = false
                        guard !isIgnoredPath(leafURL.path),
                              !SymlinkGuard.isSymbolicLink(at: leafURL),
                              SymlinkGuard.isSafePath(url: leafURL, within: verDir),
                              FileManager.default.fileExists(atPath: leafURL.path, isDirectory: &isLeafDir),
                              isLeafDir.boolValue else {
                            continue
                        }
                        let std = leafURL.standardizedFileURL.path
                        guard seenStdPaths.insert(std).inserted else { continue }
                        candidates.append((
                            leafURL,
                            "\(L10n.localized(.junkJetBrainsCacheTitle)) (\(verName)/\(leaf))",
                            "\(AppConfig.JunkScan.jetBrainsCachesRoot)/\(verName)/\(leaf)"
                        ))
                    }
                }
            }
        }
        guard !candidates.isEmpty else { return nil }

        let sizes = ScanResultSlots<Int64>(repeating: 0, count: candidates.count)
        IOScanContext.concurrentPerform(iterations: candidates.count) { [candidates] i in
            let url = candidates[i].url
            if !store.isTrashChildrenOnlyContainer(url) {
                sizes[i] = FileUtil.size(of: url)
            }
        }

        var rawItems: [ScanItem] = []
        for (i, cand) in candidates.enumerated() {
            let isNpmLogs = cand.url.lastPathComponent == "_logs"
            let isJetBrainsLeaf = AuthoredRules.isValidJetBrainsLeafOrDescendant(cand.url)
            let threshold: Int64 = isNpmLogs
                ? max(0, store.junk[AppConfig.RuleIDs.npmLogs]?.minBytes ?? 0)
                : (isJetBrainsLeaf ? max(0, store.junk[AppConfig.RuleIDs.jetBrainsCache]?.minBytes ?? 0) : 1024 * 512)
            if store.isTrashChildrenOnlyContainer(cand.url) {
                if let containerItem = JunkRulePolicy.makeMeasuredCandidate(
                    url: cand.url,
                    name: cand.label,
                    note: cand.note,
                    safety: isJetBrainsLeaf ? .caution : .safe,
                    minBytes: threshold,
                    configure: isJetBrainsLeaf ? {
                        $0.action = .emptyContainer
                        $0.isSelected = false
                    } : nil
                ) {
                    rawItems.append(containerItem)
                }
                continue
            }
            let s = sizes[i]
            guard s > threshold else { continue }
            let item = ScanItem(url: cand.url, name: cand.label, size: s,
                                note: cand.note, safety: .safe)
            rawItems.append(item)
        }
        let evaluated = rawItems.map(JunkRulePolicy.apply)
        let items = RuleAwareDeduplicator.deduplicate(evaluated).items
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "Package Manager Caches", icon: "terminal",
                         note: "Download caches for npm, pnpm, Cargo, pip, uv, Go, CocoaPods and more",
                         tileKey: "systemJunk", safety: .safe,
                         items: items.sorted { $0.size > $1.size })
    }

    // MARK: 6) 开发者项目构建产物 (ProjectPurgeEngine: 超过 7 天未修改的 node_modules / target / .build 等)

    static func scanProjectArtifacts(progress: ((Double, String) -> Void)? = nil, isStopped: (@Sendable () -> Bool)? = nil) -> ScanGroup? {
        let items = ProjectPurgeEngine.scan(
            minAgeDays: AppConfig.DeveloperPurge.defaultMinAgeDays,
            maxDepth: AppConfig.DeveloperPurge.defaultMaxDepth,
            progress: progress,
            stopped: isStopped
        )
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "Developer Project Artifacts", icon: "hammer.fill",
                         note: "Local project build directories untouched for over 7 days (node_modules, target, .build, unselected by default)",
                         tileKey: "systemJunk", safety: .caution,
                         items: items)
    }

    // MARK: 7) iOS 设备备份

    static func scanMobileBackups() -> ScanGroup? {
        let base = RuleRoot.homeLibrary.base
            .appendingPathComponent("Application Support/MobileSync/Backup")
        guard isAccessibleCandidate(base.path),
              !isIgnoredPath(base.path) else { return nil }
        var items: [ScanItem] = []
        for child in FileUtil.children(of: base) {
            if isIgnoredPath(child.path) { continue }
            let s = FileUtil.size(of: child)
            guard s > 0 else { continue }
            let date = (try? child.resourceValues(forKeys: [.contentModificationDateKey]))?
                .contentModificationDate ?? .distantPast
            let dateText = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
            var item = ScanItem(url: child, name: String(child.lastPathComponent.prefix(12)) + "…",
                                size: s, note: "Backed up on \(dateText)", safety: .risky,
                                isSelected: false, locked: true, measuredBytes: s)
            item.ruleEvidence = CleanupRuleEvidence(
                id: "JC.SYS.IOS.BACKUP",
                tier: .readOnly,
                reason: .whitelistProtected,
                defaultSelected: false
            )
            items.append(item)
        }
        items = RiskControlMatrix.applyLatestBackupProtection(items).map(JunkRulePolicy.apply)
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "iOS Device Backups", icon: "iphone",
                         note: "Device backups generated by Finder/iTunes; will require re-backup if deleted",
                         tileKey: "iOSBackups",
                         safety: .risky,
                         items: items.sorted { $0.size > $1.size })
    }

    // MARK: 7.6) 32 位应用程序(CMApplicationCleanup 32-bit)

    static func scan32BitApps() -> ScanGroup? {
        var items: [ScanItem] = []
        for dir in [RuleRoot.applications.base, RuleRoot.userApps.base] {
            for app in FileUtil.children(of: dir) where app.pathExtension == "app" {
                if isIgnoredPath(app.path) { continue }
                let name = app.deletingPathExtension().lastPathComponent
                let macosDir = app.appendingPathComponent("Contents/MacOS")
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: macosDir.path, isDirectory: &isDir),
                      isDir.boolValue,
                      access(macosDir.path, R_OK | X_OK) == 0 else { continue }
                var main = macosDir.appendingPathComponent(name)
                if !FileUtil.exists(main.path) {
                    guard let first = FileUtil.children(of: macosDir).first
                    else { continue }
                    main = first
                }
                guard machoHas64Bit(main) == false else { continue }
                let s = FileUtil.size(of: app)
                let item = ScanItem(
                    url: app,
                    name: name,
                    size: s,
                    note: "32-bit application, incompatible with modern macOS (Read-only — uninstall via Applications or Finder)",
                    safety: .caution,
                    isSelected: false,
                    locked: true,
                    measuredBytes: s
                )
                items.append(JunkRulePolicy.apply(item))
            }
        }
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "32-bit Applications", icon: "app.badge",
                         note: "Applications no longer supported on modern macOS (Read-only — verify manually)",
                         tileName: "32-bit Applications", tileQuantifier: "", tileVerb: "found",
                         tileNote: "32-bit apps cannot run on macOS Catalina or later.",
                         tileIcon: "app.badge",
                         safety: .caution,
                         items: items.sorted { $0.size > $1.size })
    }

    private static func machoHas64Bit(_ url: URL) -> Bool? {
        guard let fh = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? fh.close() }
        guard let d = try? fh.read(upToCount: 1024), d.count >= 8 else { return nil }
        func le32(_ o: Int) -> UInt32 {
            UInt32(d[o]) | UInt32(d[o + 1]) << 8 | UInt32(d[o + 2]) << 16 | UInt32(d[o + 3]) << 24
        }
        switch le32(0) {
        case 0xfeedfacf: return true
        case 0xfeedface: return false
        case 0xbebafeca, 0xbfbafeca:
            let n = Int(le32(4).byteSwapped)
            let entrySize = le32(0) == 0xbebafeca ? 20 : 32
            guard n > 0, n <= 32, d.count >= 8 + n * entrySize else { return false }
            for i in 0..<n {
                let cpu = le32(8 + i * entrySize).byteSwapped
                if cpu == 0x01000007 || cpu == 0x0100000c { return true }
            }
            return false
        default: return nil
        }
    }

    // MARK: 7.7) 未使用的磁盘映像

    static func scanUnusedDiskImages() -> ScanGroup? {
        let home = FileUtil.home
        let exts: Set<String> = ["dmg", "iso", "cdr", "toast", "img", "sparseimage"]
        var items: [ScanItem] = []
        let bindingDirs = KnowledgeBaseManager.shared.authored.catalog.bindings
            .filter { $0.scannerID == "scanUnusedDiskImages" && $0.status == .active && !$0.pathTemplate.isEmpty }
            .map { URL(fileURLWithPath: KBPaths.expand($0.pathTemplate)) }
        let searchDirs = bindingDirs.isEmpty ? [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Desktop")
        ] : bindingDirs
        for dir in searchDirs {
            if isIgnoredPath(dir.path) { continue }
            let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey,
                                          .contentAccessDateKey, .contentModificationDateKey]
            guard let en = FileManager.default.enumerator(
                at: dir, includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { url, error in IOScanContext.record(error, path: url.path); return !IOScanContext.isCancelled }) else { continue }
            for case let f as URL in en {
                if isIgnoredPath(f.path) { continue }
                guard exts.contains(f.pathExtension.lowercased()) else { continue }
                guard let v = try? f.resourceValues(forKeys: Set(keys)),
                      v.isRegularFile == true else { continue }
                let volName = f.deletingPathExtension().lastPathComponent
                if FileUtil.exists("/Volumes/\(volName)") { continue }
                let size = Int64(v.fileSize ?? 0)
                guard size > 1024 * 1024 else { continue }
                let accessed = v.contentAccessDate ?? v.contentModificationDate ?? .distantPast
                let days = (Calendar.current.dateComponents([.day], from: accessed, to: Date()).day) ?? 0
                guard days > 30 else { continue }
                let ageLabel = days > 365 ? "Not used for over a year" : "Not used for over \(days) days"
                var item = ScanItem(
                    url: f,
                    name: f.lastPathComponent,
                    size: size,
                    note: "\(ageLabel) (Read-only — verify manually in Finder)",
                    safety: .caution,
                    isSelected: false,
                    locked: true,
                    measuredBytes: size
                )
                item = JunkRulePolicy.apply(item)
                item.locked = true
                item.isSelected = false
                items.append(item)
            }
        }
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "Unused Disk Images", icon: "opticaldiscdrive",
                         note: "DMG/ISO images unmounted for an extended period (Read-only — verify manually in Finder)",
                         tileName: "Unused Disk Images", tileQuantifier: "", tileVerb: "found",
                         tileNote: "These disk images have not been used for over 30 days. Review manually in Finder before deleting.",
                         tileIcon: "opticaldiscdrive",
                         safety: .caution,
                         items: items.sorted { $0.size > $1.size })
    }

    // MARK: 7.8) Gradle 缓存

    static func scanGradleCache() -> ScanGroup? {
        let home = FileUtil.home
        let roots = AppConfig.JunkScan.gradleRoots.map { home.appendingPathComponent($0) }
        var items: [ScanItem] = []
        for r in roots where FileUtil.exists(r.path) && !isIgnoredPath(r.path) {
            if let item = JunkRulePolicy.makeMeasuredCandidate(
                url: r,
                name: r.lastPathComponent,
                note: "Gradle dependency and build cache; re-downloaded on next build",
                safety: .caution,
                minBytes: 1024 * 1024
            ) {
                items.append(JunkRulePolicy.apply(item))
            }
        }
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "Gradle Cache", icon: "hammer.circle",
                         note: "Dependencies and build cache downloaded by Java/Gradle tools",
                         tileKey: "systemJunk", safety: .caution,
                         items: items.sorted { $0.size > $1.size })
    }

    // MARK: 7.9) Electron 应用缓存

    static func scanElectronCaches() -> ScanGroup? {
        var rawItems: [ScanItem] = []
        struct ElecCandidate {
            let ruleID: String
            let url: URL
            let name: String
            let note: String
        }
        var candidates: [ElecCandidate] = []
        let store = KnowledgeBaseManager.shared.authored
        for ruleID in [AppConfig.RuleIDs.electronCache, AppConfig.RuleIDs.aiIDECache] {
            for target in store.cacheDirectories(ruleID: ruleID) {
                let p = target.standardizedFileURL.path
                guard !isIgnoredPath(p) else { continue }
                candidates.append(ElecCandidate(ruleID: ruleID, url: target, name: target.lastPathComponent, note: target.path))
            }
        }
        guard !candidates.isEmpty else { return nil }
        let sizes = ScanResultSlots<Int64>(repeating: 0, count: candidates.count)
        IOScanContext.concurrentPerform(iterations: candidates.count) { [candidates] i in
            let url = candidates[i].url
            if !store.isTrashChildrenOnlyContainer(url) {
                sizes[i] = FileUtil.size(of: url)
            }
        }
        for (i, cand) in candidates.enumerated() {
            if store.isTrashChildrenOnlyContainer(cand.url) {
                if let item = JunkRulePolicy.makeMeasuredCandidate(
                    url: cand.url,
                    name: cand.name,
                    note: cand.note,
                    safety: .safe,
                    minBytes: 1024 * 200,
                    configure: {
                        $0.ruleEvidence = CleanupRuleEvidence(
                            id: cand.ruleID,
                            tier: .review,
                            reason: .manualReview,
                            defaultSelected: false
                        )
                    }
                ) {
                    rawItems.append(item)
                }
                continue
            }
            let s = sizes[i]
            guard s > 1024 * 200 else { continue }
            var item = ScanItem(url: cand.url, name: cand.name, size: s,
                                note: cand.note, safety: .safe)
            item.ruleEvidence = CleanupRuleEvidence(
                id: cand.ruleID,
                tier: .review,
                reason: .manualReview,
                defaultSelected: false
            )
            rawItems.append(item)
        }
        let evaluated = rawItems.map(JunkRulePolicy.apply)
        let items = RuleAwareDeduplicator.deduplicate(evaluated).items
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "Electron App Cache", icon: "app.badge",
                         note: "Caches produced by Electron-based apps (VS Code, Slack, Discord, etc.)",
                         tileKey: "systemJunk", safety: .safe,
                         items: items.sorted { $0.size > $1.size })
    }

    // MARK: 7.10) 浏览器 Profile 级缓存 (Chromium Default/Profile * & Firefox Profiles/*/cache2 + startupCache)

    static func scanBrowserCacheItems(minBytes: Int64 = 0) -> [ScanItem] {
        let store = KnowledgeBaseManager.shared.authored
        var rawItems: [ScanItem] = []
        let browserRuleIDs = [
            AppConfig.RuleIDs.chromiumCache,
            AppConfig.RuleIDs.firefoxCache,
            AppConfig.RuleIDs.arcCache,
            AppConfig.RuleIDs.safariCache,
        ]
        for ruleID in browserRuleIDs {
            for target in store.cacheDirectories(ruleID: ruleID) {
                let p = target.standardizedFileURL.path
                guard !isIgnoredPath(p), isAccessibleCandidate(p) else { continue }
                let threshold = max(minBytes, store.junk[ruleID]?.minBytes ?? 0)
                if let item = JunkRulePolicy.makeMeasuredCandidate(
                    url: target,
                    name: target.lastPathComponent,
                    note: target.path,
                    safety: .safe,
                    minBytes: threshold,
                    configure: {
                        $0.ruleEvidence = CleanupRuleEvidence(
                            id: ruleID,
                            tier: .review,
                            reason: .manualReview,
                            defaultSelected: false
                        )
                    }
                ) {
                    rawItems.append(item)
                }
            }
        }
        return rawItems.map(JunkRulePolicy.apply)
    }

    static func scanBrowserCaches(minBytes: Int64 = 0) -> ScanGroup? {
        let evaluated = scanBrowserCacheItems(minBytes: minBytes)
        let items = RuleAwareDeduplicator.deduplicate(evaluated).items
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "Browser Profile Cache", icon: "globe",
                         note: "Profile-scoped browser caches (Chromium Default/Profile * & Firefox cache2/startupCache)",
                         tileKey: "systemJunk", safety: .safe,
                         items: items.sorted { $0.size > $1.size })
    }

    // MARK: 7.11) 靶向硬编码路径缓存（严格保护聊天记录与离线下载内容）

    static func scanHardcodedPathCache() -> ScanGroup? {
        let home = FileUtil.home.path
        // 1) 安全的静态缓存子路径（收敛至 AppConfig.JunkScan.targetedAppCacheSpecs）
        let specs = AppConfig.JunkScan.targetedAppCacheSpecs
        var items: [ScanItem] = []
        for (raw, label, safety) in specs {
            let path = raw.replacingOccurrences(of: "~", with: home)
            guard FileUtil.exists(path), !isIgnoredPath(path) else { continue }
            let url = URL(fileURLWithPath: path)
            guard !FileUtil.isProtected(url), SymlinkGuard.isSafePath(url: url) else { continue }
            guard let item = JunkRulePolicy.makeMeasuredCandidate(
                url: url,
                name: label,
                note: raw,
                safety: safety,
                minBytes: 1024 * 50
            ) else { continue }
            items.append(JunkRulePolicy.apply(item))
        }

        // Discover the same precise units used by recommendation and execution.
        // Profiles are authored SQL, not permission to sweep their umbrella roots.
        let store = KnowledgeBaseManager.shared.authored
        let seen = Set(items.map { $0.url.standardizedFileURL.path })
        for profile in store.cacheProfiles.values.sorted(by: { $0.id < $1.id })
            where AppConfig.JunkScan.reviewedProfileRuleIDs.contains(profile.ruleID) {
            let units = store.discoverUnits(for: profile)
            var runState: DiscoveryRunState = units.isEmpty ? .absent : .found
            for url in units where !seen.contains(url.standardizedFileURL.path) {
                guard !isIgnoredPath(url.path),
                      let item = JunkRulePolicy.makeMeasuredCandidate(url: url,
                        name: url.lastPathComponent, note: L10n.localized(.junkCacheEffectRedownload),
                        safety: .safe, minBytes: 0) else { continue }
                let evaluated = JunkRulePolicy.apply(item)
                if evaluated.evaluationReason == .runningProcessLocked { runState = .runningLocked }
                items.append(evaluated)
            }
            JunkDiscoveryRegistry.shared.recordRunState(ruleID: profile.ruleID,
                pathTemplate: profile.rootTemplate, scannerID: "scanHardcodedPathCache", state: runState)
        }

        // Version plans retain active/recent versions; execution evaluates the plan again.
        for ruleID in AppConfig.JunkScan.versionCacheRuleIDs {
            let browser = ruleID == "JC.DEV.BROWSER.DOWNLOAD"
            let specs: [(String, String?)] = browser
                ? AppConfig.JunkScan.browserDownloadRoots.map { ($0, nil) }
                : AppConfig.JunkScan.agentVersionRoots.map { ($0.root, Optional($0.current)) }
            for (raw, current) in specs {
                let root = URL(fileURLWithPath: KBPaths.expand(raw))
                let versions = Set(VersionedCachePolicy.candidates(root: root,
                    current: current.map { URL(fileURLWithPath: KBPaths.expand($0)) }, browserDownloads: browser)
                )
                let product = browser ? "Puppeteer" : (AppConfig.JunkScan.agentVersionRoots.first { $0.root == raw }?.label ?? root.lastPathComponent)
                for url in VersionedCachePolicy.inventory(root: root, browserDownloads: browser) where !isIgnoredPath(url.path) {
                    let name = String(format: L10n.localized(.junkHistoricalVersionFormat), product, url.lastPathComponent)
                    if !versions.contains(url) {
                        let measured = FileUtil.measureSize(of: url)
                        var retained = ScanItem(url: url, name: name, size: measured.bytes,
                            note: L10n.localized(.junkVersionRetentionReason), safety: .caution,
                            isSelected: false, locked: true, measuredBytes: measured.bytes)
                        retained.ruleEvidence = CleanupRuleEvidence(id: ruleID, tier: .readOnly,
                            reason: .whitelistProtected, defaultSelected: false)
                        retained.selectionRestrictions = [.readOnlyAsset]
                        retained.isRuleEvaluated = true
                        items.append(retained)
                        continue
                    }
                    guard let item = JunkRulePolicy.makeMeasuredCandidate(url: url,
                        name: name, note: L10n.localized(.junkCacheEffectRedownload),
                        safety: .caution, minBytes: 0) else { continue }
                    items.append(JunkRulePolicy.apply(item))
                }
            }
        }

        // T03: Telegram postbox/media 与微信 Message/MessageTemp 已收敛至 L3/read_only，不再从专项扫描器产出可执行清理项。

        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "Targeted Application Cache", icon: "target",
                         note: "Targeted caches and temp data from major apps (strictly preserves chat databases and logins)",
                         tileKey: "systemJunk", safety: .safe,
                         items: items.sorted { $0.size > $1.size })
    }

    // MARK: 8) 文档版本历史

    static func scanDocumentVersions() -> ScanGroup? {
        var roots: [URL] = []
        let volumes = FileUtil.children(of: URL(fileURLWithPath: "/Volumes"))
        roots.append(URL(fileURLWithPath: "/.DocumentRevisions-V100"))
        for v in volumes { roots.append(v.appendingPathComponent(".DocumentRevisions-V100")) }

        var items: [ScanItem] = []
        for r in roots where FileUtil.exists(r.path) && !isIgnoredPath(r.path) {
            let s = FileUtil.size(of: r)
            guard s > 1024 * 1024 else { continue }
            let item = ScanItem(url: r, name: "Document Versions · \(r.deletingLastPathComponent().lastPathComponent)",
                                size: s, note: "Auto-saved revisions; older versions cannot be restored once deleted",
                                safety: .risky, isSelected: false, locked: true, measuredBytes: s)
            items.append(JunkRulePolicy.apply(item))
        }
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "Document Versions", icon: "clock.arrow.circlepath",
                         note: "Historical document revisions saved by macOS",
                         tileKey: "documentVersions",
                         safety: .risky,
                         items: items.sorted { $0.size > $1.size })
    }

    // MARK: 8.5) 已删除用户

    static func scanDeletedUsers() -> ScanGroup? {
        var items: [ScanItem] = []
        let usersDir = URL(fileURLWithPath: "/Users")
        let keep: Set<String> = ["Shared", "Guest"]
        guard let names = try? FileManager.default.contentsOfDirectory(
            atPath: usersDir.path) else { return nil }

        // 必须从 Directory Services (dscl) 成功输出中提取真实存活的用户账户
        // 若 dscl 执行失败，无法确证账号是否已注销，严格安全返回 nil，禁止瞎删
        guard let dsclOutput = FileUtil.shell("/usr/bin/dscl", args: [".", "-list", "/Users"]), !dsclOutput.isEmpty else {
            return nil
        }

        var alive = Set(dsclOutput.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) })
        // 同步读取 NFSHomeDirectory 映射：防止存活账号使用了自定义/重命名过的 /Users/<folder> 目录而被误判为已注销
        if let homeMapOutput = FileUtil.shell("/usr/bin/dscl", args: [".", "-list", "/Users", "NFSHomeDirectory"]) {
            for line in homeMapOutput.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if let range = trimmed.range(of: "/Users/") {
                    let suffix = trimmed[range.upperBound...]
                    if let folderName = suffix.split(separator: "/").first.map(String.init), !folderName.isEmpty {
                        alive.insert(folderName)
                    }
                }
            }
        }
        // 关键防御：当前用户家目录名以及系统常驻守护用户强制放入存活白名单
        if let currentShortName = FileUtil.fm.homeDirectoryForCurrentUser.path.split(separator: "/").last.map(String.init) {
            alive.insert(currentShortName)
        }
        alive.insert("root")
        alive.insert("daemon")
        alive.insert("nobody")

        for name in names where !keep.contains(name) && !alive.contains(name) {
            let u = usersDir.appendingPathComponent(name)
            if isIgnoredPath(u.path) { continue }
            let s = FileUtil.size(of: u)
            guard s > 1024 * 1024 else { continue }
            let item = ScanItem(
                url: u,
                name: "User Home Directory · \(name)",
                size: s,
                note: "Account has been removed from system, but home directory remains (Read-only — verify manually in Finder)",
                safety: .risky,
                isSelected: false,
                locked: true,
                measuredBytes: s
            )
            items.append(JunkRulePolicy.apply(item))
        }
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: "Deleted Users", icon: "person.crop.circle.badge.xmark",
                         note: "Data left behind by deleted user accounts (Read-only — verify manually in Finder)",
                         tileKey: "deletedUsers",
                         safety: .risky, items: items.sorted { $0.size > $1.size })
    }

    // MARK: 8.6) Xcode 垃圾

    static func scanXcodeJunk() -> ScanGroup? {
        var subgroups: [ScanItem] = []
        let systemCache = URL(fileURLWithPath: AppConfig.JunkScan.systemSimulatorCache)
        if FileUtil.exists(systemCache.path), !SymlinkGuard.hasSymlinkEscape(url: systemCache),
           !isIgnoredPath(systemCache.path) {
            let measurement = FileUtil.measureSize(of: systemCache)
            var item = ScanItem(url: systemCache, name: systemCache.lastPathComponent,
                size: measurement.bytes, note: L10n.localized(.needsAdminPermission), safety: .caution,
                isSelected: false, locked: true, measuredBytes: measurement.bytes)
            item.ruleEvidence = CleanupRuleEvidence(id: "JC.DEV.XCODE.SYSTEM.CACHE", tier: .readOnly,
                reason: .whitelistProtected, defaultSelected: false)
            item.selectionRestrictions = [.readOnlyAsset]
            item.isRuleEvaluated = true
            subgroups.append(item)
        }

        var devRoots: [URL] = []
        if devRoots.isEmpty {
            for rel in ["Developer/Xcode", "Developer/CoreSimulator", "Developer/XCPGDevices"] {
                let u = RuleRoot.homeLibrary.base.appendingPathComponent(rel)
                if FileUtil.exists(u.path) && !isIgnoredPath(u.path) { devRoots.append(u) }
            }
        }

        let simRuntimes = XcodeHelper.scanSimulatorRuntimes()
        let cryptexRuntimes = XcodeHelper.scanCryptexRuntimes(
            excluding: Set(simRuntimes.map { $0.url.standardizedFileURL.path }))
        let allRuntimes = simRuntimes + cryptexRuntimes
        if !allRuntimes.isEmpty {
            subgroups.append(makeXcodeSubgroup(
                name: "Simulator Runtimes", icon: "shippingbox",
                note: "Downloaded iOS/watchOS/tvOS simulator runtimes; can be re-downloaded via Xcode",
                items: allRuntimes))
        }

        let simDevices = XcodeHelper.scanSimulatorDevices()
        if !simDevices.isEmpty {
            subgroups.append(makeXcodeSubgroup(
                name: "Simulator Devices", icon: "iphone",
                note: "Simulator device data and installed apps; deleted device will disappear from Xcode",
                items: simDevices))
        }

        let xcodeSubdirs = AppConfig.JunkScan.xcodeSubdirSpecs
        for spec in xcodeSubdirs {
            var subItems: [ScanItem] = []
            for root in devRoots where root.lastPathComponent == "Xcode" {
                for rel in spec.rels {
                    let target = root.appendingPathComponent(rel)
                    guard FileUtil.exists(target.path), !isIgnoredPath(target.path) else { continue }
                    let rawKids = FileUtil.children(of: target).filter { !isIgnoredPath($0.path) }
                    var measuredKids: [(url: URL, size: Int64)] = []
                    var allPositiveKids: [(url: URL, size: Int64)] = []
                    var totalRawBytes: Int64 = 0
                    for child in rawKids {
                        let childSize = FileUtil.size(of: child)
                        if childSize > 0 {
                            totalRawBytes += childSize
                            allPositiveKids.append((child, childSize))
                        }
                        if childSize > 1024 * 1024 {
                            measuredKids.append((child, childSize))
                        }
                    }
                    let effectiveKids: [(url: URL, size: Int64)] = {
                        if !measuredKids.isEmpty {
                            return measuredKids
                        }
                        if totalRawBytes > 1024 * 1024 {
                            return allPositiveKids
                        }
                        return []
                    }()
                    for (k, kSize) in effectiveKids {
                        var item = ScanItem(
                            url: k,
                            name: k.lastPathComponent,
                            size: kSize,
                            note: spec.note,
                            safety: spec.safe,
                            isSelected: false,
                            measuredBytes: kSize
                        )
                        if rel == "DerivedData" {
                            let kNameLower = k.lastPathComponent.lowercased()
                            let id: String
                            if kNameLower == "modulecache.noindex" || kNameLower == "modulecache" {
                                id = AppConfig.RuleIDs.xcodeCache
                            } else {
                                id = DeveloperArtifactPolicy.isOrphanDerivedData(k) ? AppConfig.RuleIDs.derivedOrphan : AppConfig.RuleIDs.derivedLive
                            }
                            item.ruleEvidence = kb.authored.evidence(for: k, preferredID: id, knownSize: kSize)
                        } else if rel.hasSuffix(AppConfig.Remediation.deviceSupportSuffix) {
                            item.locked = DeveloperArtifactPolicy.mustKeepDeviceSupport(k)
                            item.ruleEvidence = kb.authored.evidence(for: k, preferredID: AppConfig.RuleIDs.deviceSupport, knownSize: kSize)
                        } else if rel == "Archives" || rel == "Products" {
                            item.locked = true
                            item.isSelected = false
                            item.ruleEvidence = kb.authored.evidence(for: k, preferredID: "JC.DEV.XCODE.ARCHIVES", knownSize: kSize)
                        }
                        subItems.append(JunkRulePolicy.apply(item))
                    }
                }
            }
            if !subItems.isEmpty {
                subgroups.append(makeXcodeSubgroup(name: spec.name, icon: spec.icon,
                                                   note: spec.note, items: subItems))
            }
        }

        var csItems: [ScanItem] = []
        for root in devRoots where root.lastPathComponent == "CoreSimulator" {
            let caches = root.appendingPathComponent("Caches")
            guard FileUtil.exists(caches.path), !isIgnoredPath(caches.path) else { continue }
            if let item = JunkRulePolicy.makeMeasuredCandidate(
                url: caches,
                name: "CoreSimulator Cache",
                note: "CoreSimulator runtime dynamic cache",
                safety: .caution,
                minBytes: 1024 * 1024
            ) {
                csItems.append(JunkRulePolicy.apply(item))
            }
        }
        if !csItems.isEmpty {
            subgroups.append(makeXcodeSubgroup(name: "CoreSimulator Caches", icon: "shippingbox.circle",
                                               note: "CoreSimulator runtime dynamic cache", items: csItems))
        }

        let xcodeCache = RuleRoot.homeLibrary.base.appendingPathComponent("Caches/com.apple.dt.Xcode")
        if FileUtil.exists(xcodeCache.path) && !isIgnoredPath(xcodeCache.path) {
            if let item = JunkRulePolicy.makeMeasuredCandidate(
                url: xcodeCache,
                name: "Xcode Cache",
                note: "Xcode build derived data and intermediate index cache",
                safety: .caution,
                minBytes: 1024 * 1024
            ) {
                subgroups.append(makeXcodeSubgroup(name: "Xcode Caches", icon: "internaldrive",
                                                   note: "Xcode Application-Level Cache", items: [JunkRulePolicy.apply(item)]))
            }
        }

        guard !subgroups.isEmpty else { return nil }
        return ScanGroup(title: "Xcode Junk", icon: "hammer",
                         note: "Derived data, device support, and archives produced by Xcode",
                         tileName: "Xcode Junk", tileQuantifier: "", tileVerb: "found",
                         tileNote: "Xcode has accumulated large amounts of derived data and caches. Clean them to reclaim space.",
                         tileIcon: "cm_detail_system-junk_xcode-derived-data",
                         tileKey: "xcodeJunk",
                         safety: .safe, items: subgroups.sorted { $0.size > $1.size })
    }

    static func makeXcodeSubgroup(name: String, icon: String, note: String, items: [ScanItem]) -> ScanItem {
        let evaluated = items.map(JunkRulePolicy.apply).filter { !JunkRulePolicy.isEmptyVerifiedContainer($0) }
        let total = evaluated.reduce(Int64(0)) { $0 + $1.size }
        var g = ScanItem(url: URL(string: "cleanmate-synthetic://")!,
                         name: name, size: total, note: note, safety: .safe,
                         action: .trash, isSelected: false)
        g.children = evaluated.sorted { $0.size > $1.size }
        return JunkRulePolicy.apply(g)
    }

    // MARK: 9) App Store 下载缓存 (JC.SYS.APPSTORE.CACHE)

    static func scanAppStoreCache() -> ScanGroup? {
        let c = URL(fileURLWithPath: KBPaths.expand(AppConfig.JunkScan.appStoreCachePath))
        guard FileUtil.exists(c.path), !isIgnoredPath(c.path) else { return nil }
        guard let item = JunkRulePolicy.makeMeasuredCandidate(
            url: c,
            name: L10n.localized(.junkAppStoreCacheTitle),
            note: "App Store downloads and update cache",
            safety: .caution,
            minBytes: 0,
            configure: {
                $0.isSelected = false
                $0.ownerBundleIDs = ["com.apple.AppStore"]
                $0.ruleEvidence = CleanupRuleEvidence(
                    id: "JC.SYS.APPSTORE.CACHE",
                    tier: .review,
                    reason: .generalCache,
                    defaultSelected: false
                )
            }
        ) else { return nil }
        let evaluated = JunkRulePolicy.apply(item)
        guard evaluated.size > 0 || evaluated.locked == true else { return nil }
        return ScanGroup(title: L10n.localized(.junkAppStoreCacheTitle), icon: "arrow.down.app",
                         note: "App Store downloads cache",
                         tileKey: "systemJunk",
                         safety: .caution, items: [evaluated])
    }

    // MARK: 10) 废纸篓

    static func scanTrash() -> ScanGroup? {
        var items: [ScanItem] = []
        let home = FileUtil.home.appendingPathComponent(".Trash")
        var isTCCBlocked = false

        if FileUtil.exists(home.path) && !isIgnoredPath(home.path) {
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: home, includingPropertiesForKeys: [.fileSizeKey, .totalFileAllocatedSizeKey],
                    options: [])
                for c in contents {
                    if isIgnoredPath(c.path) { continue }
                    let s = FileUtil.size(of: c)
                    let item = ScanItem(url: c, name: "Trash · \(c.lastPathComponent)", size: s,
                                        note: "Items in Trash", safety: .caution,
                                        action: .permanentlyDeleteTrashItem, isSelected: false)
                    items.append(item)
                }
            } catch {
                isTCCBlocked = true
            }

            if isTCCBlocked {
                let (finderItems, totalSize) = getTrashItemsViaFinder(home: home)
                if !finderItems.isEmpty {
                    items.append(contentsOf: finderItems)
                } else if totalSize > 0 {
                    var item = ScanItem(url: home, name: "Local Trash", size: totalSize,
                                        note: isTCCBlocked ? "Protected by macOS permissions, sized via Finder" : "Files in Trash",
                                        safety: .caution, action: .trash, isSelected: false)
                    item.locked = true
                    items.append(item)
                }
            }
        }

        let uid = getuid()
        let volumes = FileUtil.children(of: URL(fileURLWithPath: "/Volumes"))
        for v in volumes {
            let t = v.appendingPathComponent(".Trashes/\(uid)")
            guard FileUtil.exists(t.path), !isIgnoredPath(t.path) else { continue }
            for child in FileUtil.children(of: t) {
                if isIgnoredPath(child.path) { continue }
                let s = FileUtil.size(of: child)

                let item = ScanItem(url: child, name: "\(v.lastPathComponent) Trash · \(child.lastPathComponent)",
                                    size: s, note: "External Volume Trash", safety: .caution,
                                    action: .permanentlyDeleteTrashItem, isSelected: false)
                items.append(item)
            }
        }

        if items.isEmpty {
            let note = isTCCBlocked
                ? "Restricted by macOS permissions; grant Full Disk Access to AClean in System Settings"
                : "Trash is currently empty"
            var placeholder = ScanItem(url: home, name: "Local Trash", size: 0,
                                       note: note, safety: .caution, action: .trash, isSelected: false)
            placeholder.locked = true
            return ScanGroup(title: "Trash", icon: "trash", note: "Empty trash bins on all drives to reclaim disk space.",
                             tileName: "Trash", tileQuantifier: "", tileVerb: "found",
                             tileNote: "Free up storage by permanently deleting files in your trash bins.",
                             tileIcon: "cm_detail_trash-bins_macintosh-hd",
                             tileKey: "trashBins", safety: .caution,
                             items: [placeholder])
        }

        return ScanGroup(title: "Trash", icon: "trash", note: "Empty trash bins on all drives to reclaim disk space.",
                         tileName: "Trash", tileQuantifier: "", tileVerb: "found",
                         tileNote: "Free up storage by permanently deleting files in your trash bins.",
                         tileIcon: "cm_detail_trash-bins_macintosh-hd",
                         tileKey: "trashBins",
                         safety: .caution,
                         items: items.sorted { $0.size > $1.size })
    }

    private static func getTrashItemsViaFinder(home: URL) -> ([ScanItem], Int64) {
        let script = """
        tell application "Finder"
            set outList to {}
            repeat with anItem in (items of trash as list)
                try
                    set p to POSIX path of (anItem as alias)
                    set s to (size of anItem) as text
                    set end of outList to (p & "||" & s)
                end try
            end repeat
            set AppleScript's text item delimiters to linefeed
            return outList as text
        end tell
        """
        let out = Shell.run("/usr/bin/osascript", ["-e", script]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !out.isEmpty else { return ([], 0) }
        var result: [ScanItem] = []
        var total: Int64 = 0
        let authorizedRoots = FileUtil.authorizedTrashRoots()

        for line in out.split(separator: "\n") {
            let parts = line.split(separator: "||", maxSplits: 1).map(String.init)
            guard let rawPath = parts.first, !rawPath.isEmpty else { continue }
            let s = parts.count > 1 ? (Int64(parts[1]) ?? 0) : 0
            total += s

            let fileURL = URL(fileURLWithPath: rawPath).standardizedFileURL
            // 真实根严格核验：必须为授权废纸篓根目录的严格子项，严防越权或路径拼接冒充 (P0-01)
            guard authorizedRoots.contains(where: { FileUtil.isStrictDescendant(fileURL, of: $0) }) else { continue }
            guard !isIgnoredPath(fileURL.path) else { continue }

            let item = ScanItem(url: fileURL, name: "Trash · \(fileURL.lastPathComponent)", size: max(s, 1024),
                                note: "Items in Trash", safety: .caution,
                                action: .permanentlyDeleteTrashItem, isSelected: false)
            result.append(item)
        }
        return (result, total)
    }
}
