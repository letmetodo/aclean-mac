import Foundation
import AppKit
import SQLite3

extension P9CrossReviewFixTests {
    func uninstall() throws {
        let bid = "org.cleanmate.P9." + UUID().uuidString
        let appURL = base.appendingPathComponent("Example.app")
        _ = try file("Example.app/Contents/Info.plist", data: PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": bid], format: .xml, options: 0))
        let app = InstalledApp(name: "Example", bundleID: bid, url: appURL)
        _ = try file("home/Library/Caches/\(bid)/data.bin")
        _ = try file("home/Library/Logs/\(bid)/old.log")
        _ = try file("home/Library/LaunchAgents/\(bid).helper.plist")
        _ = try file("home/Library/LaunchAgents/\(bid)Beta.plist")
        _ = try file("home/Library/Preferences/ByHost/\(bid).123.plist")
        _ = try file("home/Library/Logs/DiagnosticReports/Example-123.ips")
        _ = try file("home/Library/Application Support/Vendor/Example/data.bin")
        _ = try file("home/Library/HTTPStorages/\(bid)/keep.bin")
        _ = try file("system/LaunchDaemons/\(bid).daemon.plist")
        let items = UninstallerEngine.leftovers(for: app)
        let ids = Set(items.compactMap { $0.ruleEvidence?.id })
        for id in ["UNINST_05", "UNINST_LOG", "UNINST_12", "UNINST_13", "UNINST_20", "UNINST_24", "UNINST_15"] {
            check(ids.contains(id), "bounded template discovery: " + id)
        }
        check(!ids.contains("UNINST_08"), "session data remains excluded")
        check(!items.contains { $0.url.lastPathComponent == bid + "Beta.plist" }, "bundle ID prefix collision rejected")
        check(items.allSatisfy { !$0.isSelected && $0.ruleEvidence?.defaultSelected == false }, "no associated data auto-selected")
        check(items.filter { ["UNINST_12", "UNINST_13", "UNINST_20", "UNINST_24", "UNINST_15"].contains($0.ruleEvidence!.id) }.allSatisfy { $0.locked == true }, "inferred/system paths display only")
        let root = ApplicationsModule.makeAppNode(app, allApps: [app])
        let categories = root.children.filter(\.isGroup)
        check(categories.contains { $0.name == L10n.localized(.categoryCache) } && categories.contains { $0.name == L10n.localized(.categoryLogs) }, "uninstall caches and logs have distinct purpose groups")
        let template = KnowledgeBaseManager.shared.authored.templates.first { $0.id == "UNINST_13" }!
        let sibling = UninstallerEngine.AppIdentity(name: "Beta", bundleID: bid + ".Beta", url: base.appendingPathComponent("Beta.app"))
        check(!UninstallDiscovery.matches(bid + ".Beta.agent.plist", template: template, app: app, identities: [sibling]), "known sibling product discovery excluded")
    }
    func performance() throws {
        let target = try file("performance/idle.dat")
        func measure(_ operation: () -> Bool) -> [String: Any] {
            var seconds: [Double] = []; var idle: [Bool] = []
            for _ in 0..<10 {
                let start = ProcessInfo.processInfo.systemUptime
                idle.append(operation()); seconds.append(ProcessInfo.processInfo.systemUptime - start)
            }
            return ["seconds": seconds, "sum": seconds.reduce(0,+), "median": seconds.sorted()[5], "idle_results": idle]
        }
        let oldFresh = measure { BaselineOpenFileGuard.isIdle(target) }
        _ = BaselineOpenFileGuard.isIdle(target, fresh: false)
        let oldCached = measure { BaselineOpenFileGuard.isIdle(target, fresh: false) }
        let newFresh = measure { OpenFileGuard.isIdle(target) }
        _ = OpenFileGuard.isIdle(target, fresh: false)
        let newCached = measure { OpenFileGuard.isIdle(target, fresh: false) }
        let result: [String: Any] = ["before_fresh":oldFresh,"before_cached":oldCached,
                                    "after_fresh":newFresh,"after_cached":newCached]
        print("P9_PERFORMANCE " + String(data: try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]), encoding: .utf8)!)
    }
    func handles() throws {
        let path = try file("handles/db")
        check(OpenFileGuard.isIdle(path), "closed target idle")
        _ = OpenFileGuard.isIdle(path, fresh: false)
        let opened = try FileHandle(forReadingFrom: path)
        check(!OpenFileGuard.isIdle(path), "newly opened target cannot use stale UI snapshot")
        check(!OpenFileGuard.isIdle(path.deletingLastPathComponent()), "open descendant blocks directory")
        try opened.close()
        check(OpenFileGuard.isIdle(path), "closed handle releases target")
        let wal = try file("handles/db-wal")
        let sidecar = try FileHandle(forReadingFrom: wal)
        check(!OpenFileGuard.isIdle(path), "open SQLite WAL blocks database")
        let shm = try file("handles/db-shm")
        check(!OpenFileGuard.isIdle(shm), "open WAL also protects sibling SHM")
        try sidecar.close()
        let alias = base.appendingPathComponent("handles/hardlink")
        try fm.linkItem(at: path, to: alias)
        let aliasHandle = try FileHandle(forReadingFrom: alias)
        check(!OpenFileGuard.isIdle(path), "vnode alias handle protects original target")
        try aliasHandle.close()
        let fd = open(path.path, O_RDONLY)
        check(fd >= 0, "mmap fixture descriptor opened")
        let mapped = mmap(nil, 3, PROT_READ, MAP_PRIVATE, fd, 0)
        close(fd)
        check(mapped != MAP_FAILED, "mmap fixture created")
        defer { munmap(mapped, 3) }
        check(!OpenFileGuard.isIdle(path), "memory mapping blocks target after descriptor closes")
        let warning = ShellResult(stdout: "p123\nn/other\n", stderr: "synthetic warning", exitCode: 0)
        check(OpenFileGuard.snapshot(warning, targeted: true) == nil, "warning never proves complete target inspection")
        check(OpenFileGuard.snapshot(ShellResult(stdout: "", stderr: "", exitCode: -2), targeted: true) == nil, "timeout fails closed")
        check(OpenFileGuard.snapshot(ShellResult(stdout: "", stderr: "", exitCode: 1), targeted: false) == nil, "global empty result not accepted as idle")
        let index = OpenFileGuard.Snapshot(paths: [path.path, path.path, path.path + "-wal"])
        check(index.paths.count == 2 && index.contains(path.deletingLastPathComponent()), "deduplicated prefix index retains directory protection")
    }

    /// 同一夹具下迁移前后“推荐集合（Recommended Set）”与“可执行集合（Executable Set）”对比验证
    func migrationEquivalenceComparison() throws {
        // 准备统一夹具：覆盖 L1 自动推荐、L2 手动审阅、4 类符合规范的有意收紧，以及卸载/废纸篓/空间整理/系统维护模块
        let l1LogFile = try file("home/Library/Logs/P9EquivLogs/clean.log", data: Data(repeating: 1, count: 64))
        try? fm.removeItem(at: base.appendingPathComponent("home/Library/Application Support/P9Cursor/CachedData"))
        let l1CursorCacheFile = try file("home/Library/Application Support/P9Cursor/CachedData/chunk.bin", data: Data(repeating: 2, count: 64))
        let l1CursorCacheDir = l1CursorCacheFile.deletingLastPathComponent()
        try? fm.removeItem(at: base.appendingPathComponent("home/Library/Caches/com.cleanmate.equivcache"))
        let l2UserCacheFile = try file("home/Library/Caches/com.cleanmate.equivcache/pkg.tgz", data: Data(repeating: 3, count: 64))
        let l2UserCacheDir = l2UserCacheFile.deletingLastPathComponent()

        // 4 类有意收紧夹具：
        // (A) 无匹配规则的垃圾候选（旧模型按 Safety.safe 放行；新模型 .noMatchingAuthoredRule 锁定）
        let unmatchedJunkFile = try file("home/Library/Application Support/UnmatchedRandomVendor/temp.cache", data: Data(repeating: 4, count: 64))
        // (B) 混有非日志文件的日志子目录（旧模型整子目录作为安全日志子项放行；新模型日志内容谓词拦截）
        let mixedLogSubdir = base.appendingPathComponent("home/Library/Logs/P9EquivLogs/MixedSubdir")
        _ = try file("home/Library/Logs/P9EquivLogs/MixedSubdir/trace.log", data: Data(repeating: 5, count: 32))
        _ = try file("home/Library/Logs/P9EquivLogs/MixedSubdir/report.pdf", data: Data(repeating: 6, count: 32))
        // (C) 含跨 UID 后代文件的日志候选（旧模型仅凭 Safety.safe 放行；新模型 .systemScopeHandleBlindSpot 锁定）
        let foreignChildFile = try file("home/Library/Logs/P9EquivLogs/foreign_owned.log", data: Data(repeating: 7, count: 32))
        // (D) 谓词未实现的规则路径（JC.AI.OLLAMA.ORPHAN：旧模型若作为候选传入会按 safety 放行；新模型 .unimplementedPredicate 锁定）
        let brokenPlistCandidateURL = try file("home/.ollama/models/blobs/sha256-equiv", data: Data(repeating: 8, count: 32))

        let foreignStandardized = foreignChildFile.standardizedFileURL.path
        FileIdentity.uidOverrideForTesting = { url in
            url.standardizedFileURL.path == foreignStandardized ? (getuid() &+ 1) : nil
        }
        defer { FileIdentity.uidOverrideForTesting = nil }

        // 1. 垃圾清理模块：在同一夹具上评估新流水线与旧基线模型
        let rawJunkFixture: [ScanItem] = [
            ScanItem(url: l1LogFile.deletingLastPathComponent(), name: "P9EquivLogs", size: 160, safety: .safe, isSelected: true),
            ScanItem(url: l1CursorCacheDir, name: "Cursor CachedData", size: 64, safety: .safe, isSelected: true),
            ScanItem(url: l2UserCacheDir, name: "Equiv User Cache", size: 64, safety: .caution, isSelected: false),
            ScanItem(url: unmatchedJunkFile, name: "Unmatched Cache", size: 64, safety: .safe, isSelected: true),
            ScanItem(url: brokenPlistCandidateURL, name: "Broken Plist Candidate", size: 32, safety: .caution, isSelected: false)
        ]

        let evaluatedNewItems = RuleAwareDeduplicator.deduplicate(rawJunkFixture.map(JunkRulePolicy.apply)).items
        let newJunkNodes: [Node] = evaluatedNewItems.map { Node.item(from: $0) }
        let newJunkLeaves: [Node] = newJunkNodes.flatMap { $0.leaves }

        let newRecommendedJunk = Set(newJunkLeaves.filter { CleanupSelectionPolicy.isRecommended($0) }.compactMap { $0.url?.standardizedFileURL.path })
        let newExecutableJunk = Set(newJunkLeaves.filter { !$0.locked && $0.ruleEvidence?.executable == true }.compactMap { $0.url?.standardizedFileURL.path })

        // 旧基线模型（迁移前：依赖 Safety == .safe 与 !locked，无规则证据闭环、无日志混合内容谓词、无 UID 盲区拦截）
        struct LegacyLeaf {
            let path: String
            let safety: Safety
            let locked: Bool
        }
        let legacyLeaves: [LegacyLeaf] = [
            LegacyLeaf(path: l1LogFile.standardizedFileURL.path, safety: .safe, locked: false),
            LegacyLeaf(path: mixedLogSubdir.standardizedFileURL.path, safety: .safe, locked: false),
            LegacyLeaf(path: foreignChildFile.standardizedFileURL.path, safety: .safe, locked: false),
            LegacyLeaf(path: l1CursorCacheFile.standardizedFileURL.path, safety: .safe, locked: false),
            LegacyLeaf(path: l2UserCacheFile.standardizedFileURL.path, safety: .caution, locked: false),
            LegacyLeaf(path: unmatchedJunkFile.standardizedFileURL.path, safety: .safe, locked: false),
            LegacyLeaf(path: brokenPlistCandidateURL.standardizedFileURL.path, safety: .caution, locked: false)
        ]
        let legacyRecommendedJunk = Set(legacyLeaves.filter { !$0.locked && $0.safety == .safe }.map { $0.path })
        let legacyExecutableJunk = Set(legacyLeaves.filter { !$0.locked }.map { $0.path })

        // 验证新推荐集与新可执行集均为旧模型的严格安全子集，且差集 100% 由规范要求的有意收紧解释
        check(newRecommendedJunk.isSubset(of: legacyRecommendedJunk),
              "Post-migration recommended junk set is a strict safe subset of pre-migration recommended set")
        check(newExecutableJunk.isSubset(of: legacyExecutableJunk),
              "Post-migration executable junk set is a strict safe subset of pre-migration executable set")

        let expectedRecommendedTightened: Set<String> = [
            unmatchedJunkFile.standardizedFileURL.path,
            mixedLogSubdir.standardizedFileURL.path,
            foreignChildFile.standardizedFileURL.path
        ]
        // 混有非日志文件的日志子目录从 L1 降级为 L2 review（退出推荐集，但保留手动复核可执行），而无匹配规则、外源 UID 与未实现谓词项降级为 L3 锁定（退出可执行集）
        let expectedExecutableTightened: Set<String> = [
            unmatchedJunkFile.standardizedFileURL.path,
            foreignChildFile.standardizedFileURL.path,
            brokenPlistCandidateURL.standardizedFileURL.path
        ]
        check(legacyRecommendedJunk.subtracting(newRecommendedJunk) == expectedRecommendedTightened,
              "Recommended set difference matches exact intentional tightenings (unmatched rule, mixed non-log subdir downgraded to L2, foreign UID)")
        check(legacyExecutableJunk.subtracting(newExecutableJunk) == expectedExecutableTightened,
              "Executable set difference matches exact intentional L3 lock tightenings (unmatched rule, foreign UID, unimplemented predicate rule)")

        if let mixedNode = newJunkLeaves.first(where: { $0.url?.standardizedFileURL.path == mixedLogSubdir.standardizedFileURL.path }) {
            check(!mixedNode.autoSelected && !CleanupSelectionPolicy.isRecommended(mixedNode) && !mixedNode.locked && mixedNode.ruleEvidence?.tier == .review && mixedNode.ruleEvidence?.executable == true,
                  "Mixed non-log subdir is downgraded from L1 recommended to L2 review executable")
        } else {
            check(false, "Expected mixedLogSubdir leaf in evaluated junk leaves")
        }

        // 除去有意收紧项后，L1 与 L2 合规垃圾项在新旧模型中的推荐集合与可执行集合完全等价
        let expectedValidRecommended: Set<String> = [
            l1LogFile.standardizedFileURL.path,
            l1CursorCacheFile.standardizedFileURL.path
        ]
        let expectedValidExecutable: Set<String> = expectedValidRecommended.union([
            l2UserCacheFile.standardizedFileURL.path,
            mixedLogSubdir.standardizedFileURL.path
        ])
        check(newRecommendedJunk == expectedValidRecommended,
              "Post-migration recommended set preserves 100% of compliant L1 items")
        check(newExecutableJunk == expectedValidExecutable,
              "Post-migration executable set preserves 100% of compliant L1 + L2 items")

        FileIdentity.uidOverrideForTesting = nil

        // 2. 非垃圾清理模块（卸载关联项、废纸篓、空间整理、系统维护）在同一夹具下的新旧推荐集与可执行集 100% 等价验证
        let trashItemURL = try file("home/.Trash/equiv_trashed.txt", data: Data([1, 2, 3]))
        let organizeItemURL = try file("home/Downloads/equiv_installer.dmg", data: Data([4, 5, 6]))
        let uninstCacheURL = try file("home/Library/Caches/org.cleanmate.equiv/cache.db", data: Data([7, 8, 9]))

        let trashNode = Node(
            name: "equiv_trashed.txt",
            url: trashItemURL,
            safety: .caution,
            action: .permanentlyDeleteTrashItem,
            size: 3,
            autoSelected: false,
            authorizationContext: .trashBin
        )
        let organizeNode = Node(
            name: "equiv_installer.dmg",
            url: organizeItemURL,
            safety: .caution,
            action: .trash,
            size: 3,
            autoSelected: false,
            authorizationContext: .organizeManual
        )
        let uninstEvidence = CleanupRuleEvidence(id: "UNINST_05", tier: .review, reason: .generalCache, defaultSelected: false)
        var uninstNode = Node(
            name: "org.cleanmate.equiv",
            url: uninstCacheURL,
            safety: .caution,
            action: .trash,
            size: 3,
            autoSelected: false,
            authorizationContext: .uninstall
        )
        uninstNode.ruleEvidence = uninstEvidence
        let maintenanceNode = Node(
            name: "Release Purgeable Space",
            url: nil,
            safety: .safe,
            action: .apfsPurge,
            size: 0,
            autoSelected: false,
            authorizationContext: .systemMaintenance
        )

        let nonJunkNodes = [trashNode, organizeNode, uninstNode, maintenanceNode]
        for node in nonJunkNodes {
            let newRecommended = CleanupSelectionPolicy.isRecommended(node)
            let legacyRecommended = !node.locked && node.autoSelected && node.safety == Safety.safe
            check(newRecommended == legacyRecommended && newRecommended == false,
                  "Non-junk module item (\(node.authorizationContext.rawValue)) recommendation is identical before and after migration (never auto-recommended)")

            let target = CleanTarget(node)
            let newAuthorizesExecution: Bool = {
                switch target.authorizationContext {
                case .trashBin, .organizeManual:
                    return !target.locked && target.url != nil && target.expectedIdentity != nil
                case .uninstall:
                    return !target.locked && target.ruleEvidence?.executable == true && target.expectedIdentity != nil
                case .systemMaintenance:
                    return !target.locked && target.action == .apfsPurge
                case .junkRule:
                    return false
                }
            }()
            let legacyAuthorizesExecution = !node.locked
            check(newAuthorizesExecution == legacyAuthorizesExecution && newAuthorizesExecution == true,
                  "Non-junk module item (\(node.authorizationContext.rawValue)) executable status is 100% equivalent before and after migration")
        }
    }

    func step5PostReviewOptimizations(db: URL) throws {
        let kb = KnowledgeBaseManager.shared
        defer { try? kb.load(from: db) }

        // 1. P1-1: Execution Mode Contract (.automatic vs .manual)
        let l2CacheFile = try file("home/Library/Caches/com.cleanmate.p9.mode/cache.bin", data: Data(repeating: 0x11, count: 128))
        let l2CacheDir = l2CacheFile.deletingLastPathComponent()
        let l2Eval = JunkRulePolicy.apply(ScanItem(url: l2CacheDir, name: "mode_cache", size: 128, safety: .caution, isSelected: false))
        let l2Node = Node.item(from: l2Eval)
        check(l2Node.ruleEvidence?.tier == .review && l2Node.ruleEvidence?.executable == true, "L2 user cache evaluated as review executable")

        var autoTargetForL2 = CleanTarget(l2Node)
        autoTargetForL2.executionMode = .automatic
        let autoL2Outcome = Cleaner.clean(autoTargetForL2)
        check(!autoL2Outcome.ok && autoL2Outcome.actionCategory == .skipped,
              "Cleaner blocks L2 review item when executionMode == .automatic")

        var manualTargetForL2 = CleanTarget(l2Node)
        manualTargetForL2.executionMode = .manual
        let manualL2Outcome = Cleaner.clean(manualTargetForL2)
        check(manualL2Outcome.ok, "Cleaner permits L2 review item when executionMode == .manual")

        let organizeTargetFile = try file("organize_mode/doc.dat", data: Data([1, 2, 3]))
        let autoOrganizeTarget = CleanTarget(
            name: "doc.dat",
            url: organizeTargetFile,
            size: 3,
            action: .trash,
            authorizationContext: .organizeManual,
            executionMode: .automatic
        )
        check(!Cleaner.clean(autoOrganizeTarget).ok, "Cleaner blocks .organizeManual target in .automatic executionMode")

        // 2. P1-2 (F01): Dynamic Electron ownerBundleIDs resolution & post-scan running app interception
        let codeCacheFile = try file("home/Library/Application Support/P9Code/Cache/chunk.bin", data: Data(repeating: 0x22, count: 64))
        let codeCacheDir = codeCacheFile.deletingLastPathComponent()
        let codeEval = JunkRulePolicy.apply(ScanItem(url: codeCacheDir, name: "Cache", size: 64, safety: .safe, isSelected: true))
        check(codeEval.ownerBundleIDs.contains("org.cleanmate.p9.code"),
              "JunkRulePolicy populates ownerBundleIDs from cm_electron_data_dir for container")
        check(codeEval.children.allSatisfy { $0.ownerBundleIDs.contains("org.cleanmate.p9.code") },
              "Expanded container children inherit resolved Electron ownerBundleIDs")

        if let runningBundleID = NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier).first(where: { !$0.isEmpty }) {
            let liveElecDB = base.appendingPathComponent("live_elec.db")
            try? fm.removeItem(at: liveElecDB)
            try fm.copyItem(at: db, to: liveElecDB)
            let escapedBID = runningBundleID.replacingOccurrences(of: "'", with: "''")
            try sql("INSERT OR REPLACE INTO cm_electron_data_dir(bundle_id, dir_name) VALUES ('\(escapedBID)', 'P9LiveElectronApp');", db: liveElecDB)
            try kb.load(from: liveElecDB)

            let liveAppCacheFile = try file("home/Library/Application Support/P9LiveElectronApp/Cache/live.bin", data: Data(repeating: 0x33, count: 64))
            let liveSkip = ProcessGuard.shouldSkipDueToRunningProcess(path: liveAppCacheFile.path)
            check(liveSkip.skip, "ProcessGuard.shouldSkipDueToRunningProcess detects running Electron app via cm_electron_data_dir")

            var forgedPostScanTarget = CleanTarget(
                name: "live.bin",
                url: liveAppCacheFile,
                size: 64,
                action: .trash,
                authorizationContext: .junkRule,
                executionMode: .manual
            )
            forgedPostScanTarget.ruleEvidence = CleanupRuleEvidence(
                id: AppConfig.RuleIDs.electronCache,
                tier: .automatic,
                reason: .generalCache,
                defaultSelected: true,
                containerPath: liveAppCacheFile.deletingLastPathComponent().standardizedFileURL.path,
                containerIdentity: FileIdentity.capture(from: liveAppCacheFile.deletingLastPathComponent())
            )
            forgedPostScanTarget.expectedIdentity = FileIdentity.capture(from: liveAppCacheFile)
            let postScanOutcome = Cleaner.clean(forgedPostScanTarget)
            check(!postScanOutcome.ok && postScanOutcome.actionCategory == .skipped,
                  "Cleaner blocks post-scan launched Electron app target at execution time")
            try kb.load(from: db)
        }

        // 3. P1-3 (F05): Separate measuredBytes from display-deducted size in RuleAwareDeduplicator
        let parentDir = base.appendingPathComponent("dedup_measured/parent")
        let childDir = parentDir.appendingPathComponent("child")
        _ = try file("dedup_measured/parent/root.bin", data: Data(repeating: 0x44, count: 1000))
        _ = try file("dedup_measured/parent/child/sub.bin", data: Data(repeating: 0x55, count: 400))

        var parentScan = ScanItem(
            url: parentDir,
            name: "parent",
            size: 1400,
            note: "original",
            safety: .caution,
            action: .trash,
            isSelected: false,
            locked: true,
            ruleEvidence: CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .readOnly, reason: .whitelistProtected, defaultSelected: false),
            authorizationContext: .junkRule,
            evaluationReason: .runningProcessLocked,
            isRuleEvaluated: true,
            measuredBytes: 1400
        )
        parentScan.fileIdentity = FileIdentity.capture(from: parentDir)
        var childScan = ScanItem(
            url: childDir,
            name: "child",
            size: 400,
            note: "child",
            safety: .caution,
            action: .trash,
            isSelected: false,
            locked: true,
            ruleEvidence: CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .readOnly, reason: .whitelistProtected, defaultSelected: false),
            authorizationContext: .junkRule,
            evaluationReason: .protectedAssetBlocked,
            isRuleEvaluated: true,
            measuredBytes: 400
        )
        childScan.fileIdentity = FileIdentity.capture(from: childDir)

        let dedupOut = RuleAwareDeduplicator.deduplicate([parentScan, childScan]).items
        if let dedupParent = dedupOut.first(where: { $0.name == "parent" }) {
            check(dedupParent.size == 1000 && dedupParent.measuredBytes == 1400,
                  "RuleAwareDeduplicator deducts child size for display (1000) while preserving physical measuredBytes (1400)")
            check(dedupParent.evaluationReason == .runningProcessLocked,
                  "Already-locked parent preserves its original specific evaluationReason (.runningProcessLocked)")
            let dedupParentNode = Node.item(from: dedupParent)
            check(dedupParentNode.size == 1000 && dedupParentNode.measuredBytes == 1400,
                  "Node preserves both display size and physical measuredBytes")
            check(dedupParentNode.note == CandidateEvaluationReason.runningProcessLocked.localizedExplanation,
                  "Locked Node displays specific evaluationReason explanation instead of generic whitelistProtected")
            let dedupTarget = CleanTarget(dedupParentNode)
            check(dedupTarget.size == 1000 && dedupTarget.measuredBytes == 1400,
                  "CleanTarget preserves both display size and physical measuredBytes")
        } else {
            check(false, "Expected dedupParent in deduplicated output")
        }

        // 4. P2-2 (F07): Bounded deduplication records in IOScanContext
        let boundedCtx = IOScanContext(stopped: { false })
        boundedCtx.perform {
            for i in 0..<2500 {
                IOScanContext.recordDeduplication(DeduplicationRecord(
                    droppedPath: "/tmp/drop/\(i)",
                    droppedRuleId: "R1",
                    winnerPath: "/tmp/win/\(i)",
                    winnerRuleId: "R2",
                    reason: "test"
                ))
            }
        }
        check(boundedCtx.deduplicationRecords.count == 2048, "IOScanContext bounds deduplicationRecords to 2048 entries")

        // 5. P2-3 (F10): Independent DB capability states (loaded vs templatesLoaded vs protectionsLoaded)
        let noTemplatesDB = base.appendingPathComponent("no_templates.db")
        try? fm.removeItem(at: noTemplatesDB)
        try fm.copyItem(at: db, to: noTemplatesDB)
        try sql("DROP TABLE cm_uninstall_template;", db: noTemplatesDB)
        try kb.load(from: noTemplatesDB)
        check(kb.authored.loaded && kb.authored.protectionsLoaded && !kb.authored.templatesLoaded,
              "Dropping cm_uninstall_template disables templatesLoaded without wiping out junk rules or protections")

        let noJunkDB = base.appendingPathComponent("no_junk.db")
        try? fm.removeItem(at: noJunkDB)
        try fm.copyItem(at: db, to: noJunkDB)
        try sql("DROP TABLE cm_junk_rule;", db: noJunkDB)
        try kb.load(from: noJunkDB)
        check(!kb.authored.loaded && kb.authored.protectionsLoaded && kb.authored.templatesLoaded && !kb.authored.templates.isEmpty,
              "Dropping cm_junk_rule disables junk loaded state without wiping out uninstall templates or protections")
        try kb.load(from: db)
    }

    func p1AndP2FinalSpecVerification(db: URL) async throws {
        let kb = KnowledgeBaseManager.shared
        try kb.load(from: db)
        let store = kb.authored

        // 1. P1 单一真源校验：SQL L1 集合与 AppConfig.RuleIDs.implementedAutomaticRules 完全相等（T08 后 12 条）
        let sqlL1Rules = Set(store.junk.values.filter { $0.tier == .automatic && $0.selected }.map { $0.id })
        check(sqlL1Rules.count == 12 && sqlL1Rules == AppConfig.RuleIDs.implementedAutomaticRules,
              "P1: SQL L1 rule set exactly equals AppConfig.RuleIDs.implementedAutomaticRules (12 rules)")

        // 2. Gate 1 & Gate 2: JC.CACHE.USER 含 .pem 或 .lproj 必须锁定 L3；白名单未运行 App 为 L1，未知 App 为 L2
        let cacheWithPem = try file("home/Library/Caches/com.spotify.client.pemtest/cert.pem").deletingLastPathComponent()
        let evalCachePem = JunkRulePolicy.apply(ScanItem(url: cacheWithPem, name: "com.spotify.client.pemtest", size: 12, safety: .safe, isSelected: true))
        check(evalCachePem.locked == true && !evalCachePem.isSelected,
              "P1 Gate 1: JC.CACHE.USER containing .pem is locked and never auto-selected")

        let cacheWithLproj = try file("home/Library/Caches/com.spotify.client.lprojtest/en.lproj/Localizable.strings").deletingLastPathComponent().deletingLastPathComponent()
        let evalCacheLproj = JunkRulePolicy.apply(ScanItem(url: cacheWithLproj, name: "com.spotify.client.lprojtest", size: 12, safety: .safe, isSelected: true))
        check(evalCacheLproj.locked == true && !evalCacheLproj.isSelected,
              "P1 Gate 1: JC.CACHE.USER containing .lproj is locked and never auto-selected")

        let cleanSpotifyCache = try file("home/Library/Caches/com.spotify.client/cache_chunk.bin").deletingLastPathComponent()
        let evalSpotify = JunkRulePolicy.apply(ScanItem(url: cleanSpotifyCache, name: "com.spotify.client", size: 16, safety: .safe, isSelected: true))
        check(evalSpotify.locked == true && evalSpotify.isSelected == false && evalSpotify.ruleEvidence?.tier == .readOnly,
              "CM-JUNK-T04: com.spotify.client cache is L3 read-only protected and never auto-selected")

        let cleanIinaCache = try file("home/Library/Caches/com.colliderli.iina/cache_chunk.bin").deletingLastPathComponent()
        if !ProcessGuard.isAppRunning(bundleID: "com.colliderli.iina") {
            let evalIina = JunkRulePolicy.apply(ScanItem(url: cleanIinaCache, name: "com.colliderli.iina", size: 16, safety: .safe, isSelected: true))
            check(evalIina.locked == false && evalIina.isSelected == true && evalIina.action == .emptyContainer,
                  "P1 Gate 2: Allowlisted non-running com.colliderli.iina cache is L1 auto-selected with .emptyContainer action")
        }

        let unknownUserCache = try file("home/Library/Caches/com.unknown.vendor.client/cache_chunk.bin").deletingLastPathComponent()
        let evalUnknownCache = JunkRulePolicy.apply(ScanItem(url: unknownUserCache, name: "com.unknown.vendor.client", size: 16, safety: .safe, isSelected: true))
        check(evalUnknownCache.locked == false && evalUnknownCache.isSelected == false && evalUnknownCache.children.allSatisfy { $0.ruleEvidence?.tier == .review },
              "P1 Gate 2: Unknown bundle ID under ~/Library/Caches is downgraded to L2 review and unselected by default")

        // 3. Gate 1 & Gate 3: JC.DEV.PKG.SAFE 含测试 .pem 解锁为 L2；~/.cursor/extensions 严格保护
        let npmCacheWithPem = try file("home/.npm/_cacache/content-v2/test_fixture.pem").deletingLastPathComponent().deletingLastPathComponent()
        let evalNpmPem = JunkRulePolicy.apply(ScanItem(url: npmCacheWithPem, name: "_cacache", size: 32, safety: .caution, isSelected: false))
        if let npmRule = store.junk["JC.DEV.NPM.CACACHE"],
           !store.hasRunningAppLock(for: npmCacheWithPem, rule: npmRule, isRunning: ProcessGuard.isAppRunning(bundleID:)) {
            check(evalNpmPem.locked == false && evalNpmPem.isSelected == false && evalNpmPem.children.allSatisfy { $0.ruleEvidence?.tier == .review && $0.locked == false },
                  "P1 Gate 1: JC.DEV.PKG.SAFE / JC.DEV.NPM.CACACHE containing test .pem is unlocked as L2 review when toolchain is idle")
        }

        let cursorExtURL = try file("home/.cursor/extensions/ms-python.python-2026.1/package.json").deletingLastPathComponent()
        let evalCursorExt = JunkRulePolicy.apply(ScanItem(url: cursorExtURL, name: "ms-python.python-2026.1", size: 64, safety: .safe, isSelected: true))
        check(evalCursorExt.locked == true && !evalCursorExt.isSelected && CleanupSafetyPolicy.isProtectedAsset(cursorExtURL),
              "P1 Gate 3: ~/.cursor/extensions is strictly protected and never cleanable")

        // 4. Gate 4: JC.LEFTOVER.ORPHAN 规则存在且为 L2；第一层 Saved Application State 为 L2 可手选，第二层 Application Support 保持 L3 只读锁定
        check(store.junk[AppConfig.RuleIDs.leftoverOrphan]?.tier == .review && store.junk[AppConfig.RuleIDs.leftoverOrphan]?.selected == false,
              "P1 Gate 4: JC.LEFTOVER.ORPHAN is registered as L2 review with defaultSelected == false")
        let orphanLayer1 = try file("home/Library/Saved Application State/com.zqxwvut.kjmnhbgvf.savedState/data.data").deletingLastPathComponent()
        let evalOrphanL1 = JunkRulePolicy.apply(ScanItem(
            url: orphanLayer1,
            name: "com.zqxwvut.kjmnhbgvf.savedState",
            size: 24,
            safety: .caution,
            isSelected: false,
            ruleEvidence: CleanupRuleEvidence(id: AppConfig.RuleIDs.leftoverOrphan, tier: .review, reason: .generalCache, defaultSelected: false)
        ))
        check(evalOrphanL1.locked == false && evalOrphanL1.isSelected == false && evalOrphanL1.ruleEvidence?.id == AppConfig.RuleIDs.leftoverOrphan && evalOrphanL1.ruleEvidence?.tier == .review,
              "P1 Gate 4: Layer 1 Saved Application State orphan is L2 review and unlocked")
        let orphanLayer2 = try file("home/Library/Application Support/com.zqxwvut.kjmnhbgvf/config.dat").deletingLastPathComponent()
        let evalOrphanL2 = JunkRulePolicy.apply(ScanItem(url: orphanLayer2, name: "com.zqxwvut.kjmnhbgvf", size: 24, safety: .caution, isSelected: false))
        check(evalOrphanL2.locked == true && !evalOrphanL2.isSelected,
              "P1 Gate 4: Layer 2 Application Support orphan remains L3 read-only locked")

        // 5. Gate 5.2 & Gate 5.3: DARWIN_USER_TEMP_DIR / DARWIN_USER_CACHE_DIR / Caches / Logs 根路径硬拒绝；混合日志目录单文件下钻
        for rootURL in [
            URL(fileURLWithPath: KBPaths.darwinUserTempDir),
            URL(fileURLWithPath: KBPaths.darwinUserCacheDir),
            base.appendingPathComponent("home/Library/Caches"),
            base.appendingPathComponent("home/Library/Logs")
        ] {
            var rootTarget = CleanTarget(
                name: rootURL.lastPathComponent,
                url: rootURL,
                size: 64,
                action: .emptyContainer,
                locked: false,
                identity: FileIdentity.capture(from: rootURL),
                authorizationContext: .junkRule
            )
            rootTarget.ruleEvidence = CleanupRuleEvidence(id: "JC.SYS.TMP", tier: .automatic, reason: .generalCache, defaultSelected: true)
            check(AuthoredRules.isProtectedSystemOrCacheRoot(rootURL) && !Cleaner.clean(rootTarget).ok,
                  "P1 Gate 5.2: Protected root \(rootURL.lastPathComponent) is hard-rejected by Cleaner.clean")
        }

        let mixedLogAppDir = base.appendingPathComponent("home/Library/Logs/P9DrillDownMix")
        try? fm.removeItem(at: mixedLogAppDir)
        let oldLogFile = try file("home/Library/Logs/P9DrillDownMix/sub/expired.log", data: Data(repeating: 0x41, count: 2048))
        let stateJsonFile = try file("home/Library/Logs/P9DrillDownMix/sub/session_state.json", data: Data(repeating: 0x42, count: 2048))
        let tenDaysAgo = Date().addingTimeInterval(-10 * 86400)
        try fm.setAttributes([.modificationDate: tenDaysAgo], ofItemAtPath: oldLogFile.path)
        try fm.setAttributes([.modificationDate: tenDaysAgo], ofItemAtPath: stateJsonFile.path)
        let evaluatedMixRoot = JunkRulePolicy.apply(ScanItem(url: mixedLogAppDir, name: "P9DrillDownMix", size: 4096, safety: .safe, isSelected: true))
        let drilledItems = JunkEngine.drillDownMixedUserLogDirectories([evaluatedMixRoot])
        let drilledChildPaths = Set(drilledItems.flatMap { $0.children }.map { $0.url.standardizedFileURL.path })
        check(drilledChildPaths.contains(oldLogFile.standardizedFileURL.path)
              && !drilledChildPaths.contains(stateJsonFile.standardizedFileURL.path),
              "P1 Gate 5.3: Mixed user log directory drills down to expired .log file while skipping .json state file")

        // 6. P2 (5.1 + 5.2 + 5.4): 会话级 lsof 快照、FastDirectoryInspector 硬链接去重、2000+ 子项 emptyContainer 仅 1 次 lsof 复核 + 废纸篓可恢复
        let hardlinkDir = base.appendingPathComponent("home/Library/Caches/P9HardlinkInspect")
        try? fm.removeItem(at: hardlinkDir)
        let hlFileA = try file("home/Library/Caches/P9HardlinkInspect/fileA.bin", data: Data(repeating: 0x5A, count: 16384))
        let hlFileB = hardlinkDir.appendingPathComponent("fileB.bin")
        _ = link(hlFileA.path, hlFileB.path)
        let singleInspect = FastDirectoryInspector.inspect(hlFileA, parentRuleID: nil, parentTier: nil)
        let dirInspect = FastDirectoryInspector.inspect(hardlinkDir, parentRuleID: nil, parentTier: nil)
        check(dirInspect.measurementComplete && dirInspect.physicalBytes == singleInspect.physicalBytes,
              "P2.2: FastDirectoryInspector deduplicates hard-linked inodes (st_nlink > 1) in single fts_read pass")

        let bigContainer = base.appendingPathComponent("home/Library/Application Support/P9Cursor/CachedData")
        try? fm.removeItem(at: bigContainer)
        try fm.createDirectory(at: bigContainer, withIntermediateDirectories: true)
        for idx in 0..<2005 {
            let childPath = bigContainer.appendingPathComponent("chunk_\(idx).bin")
            try Data([1, 2, 3, 4]).write(to: childPath)
        }
        let p2ScanCtx = IOScanContext(stopped: { false })
        let evaluatedBigContainer = p2ScanCtx.perform {
            JunkRulePolicy.apply(ScanItem(url: bigContainer, name: "CachedData", size: 0, safety: .safe, isSelected: true))
        }
        check(evaluatedBigContainer.action == .emptyContainer && evaluatedBigContainer.children.count == 2005,
              "P2.4: 2,005-child trash_children_only container evaluates with .emptyContainer action")
        check(p2ScanCtx.telemetrySnapshot.lsofInvocationCount <= 2,
              "P2.1: Session-level OpenFileGuard snapshot keeps scan lsof invocations <= 2 across 2,005 children")

        let p2CleanCtx = IOScanContext(stopped: { false })
        let bigNode = Node.item(from: evaluatedBigContainer)
        let bigTarget = CleanTarget.emptyContainer(from: bigNode)
        let bigOutcome = p2CleanCtx.perform {
            Cleaner.clean(bigTarget)
        }
        check(bigOutcome.ok && bigOutcome.actionCategory == .movedToTrash,
              "P2.4: Cleaner.clean(.emptyContainer) succeeds on 2,005-child container")
        check(p2CleanCtx.telemetrySnapshot.lsofInvocationCount == 1,
              "P2.4: Cleaner.clean(.emptyContainer) invokes lsof exactly 1 time for 2,005-child container")

        // Real Trash move & recovery verification on isolated 2-child container + permission failure classification & retry
        let realTrashContainer = base.appendingPathComponent("home/Library/Application Support/P9Cursor/Code Cache")
        try? fm.removeItem(at: realTrashContainer)
        let realChild1 = try file("home/Library/Application Support/P9Cursor/Code Cache/wasm_0.bin", data: Data([10, 20, 30]))
        let realChild2 = try file("home/Library/Application Support/P9Cursor/Code Cache/wasm_1.bin", data: Data([40, 50, 60]))
        let evalRealContainer = JunkRulePolicy.apply(ScanItem(url: realTrashContainer, name: "Code Cache", size: 0, safety: .safe, isSelected: true))
        let prevDryRun = Cleaner.isDryRun
        Cleaner.isDryRun = false
        defer {
            Cleaner.isDryRun = prevDryRun
            Cleaner.onTrashHook = nil
        }

        // 6a. Partial permission failure in emptyContainer preserves failureKind == .permission and scopes retry to failed child only
        let trashSink = base.appendingPathComponent("trash_sink")
        try? fm.removeItem(at: trashSink)
        try fm.createDirectory(at: trashSink, withIntermediateDirectories: true)
        Cleaner.onTrashHook = { itemURL in
            if itemURL.lastPathComponent == "wasm_1.bin" {
                throw CocoaError(.fileWriteNoPermission)
            }
            let dest = trashSink.appendingPathComponent(itemURL.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: itemURL, to: dest)
            return dest
        }
        let initialContainerTarget = CleanTarget.emptyContainer(from: Node.item(from: evalRealContainer))
        let partialPermOutcome = Cleaner.clean(initialContainerTarget)
        check(!partialPermOutcome.ok
              && partialPermOutcome.actionCategory == .partialFailure
              && partialPermOutcome.failureKind == .permission
              && partialPermOutcome.trashedURLs.count == 1
              && partialPermOutcome.failedChildDetails.count == 1
              && partialPermOutcome.failedChildDetails.first?.failureKind == .permission,
              "P2.4: emptyContainer partial permission failure preserves failureKind == .permission and structured child failure details")
        let retryTargets = AppState.permissionRetryTargets(from: [initialContainerTarget], outcomes: [partialPermOutcome])
        check(retryTargets.count == 1
              && retryTargets[0].retryChildPaths == [realChild2.standardizedFileURL.path]
              && retryTargets[0].containerChildren.map { $0.url?.standardizedFileURL.path } == [realChild2.standardizedFileURL.path],
              "P2.4: AppState.permissionRetryTargets scopes emptyContainer retry strictly to the failed child")

        // Retry execution after permission is granted moves only the remaining failed child
        Cleaner.onTrashHook = { itemURL in
            let dest = trashSink.appendingPathComponent(itemURL.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: itemURL, to: dest)
            return dest
        }
        let retryOutcome = Cleaner.clean(retryTargets[0])
        check(retryOutcome.ok && retryOutcome.actionCategory == .movedToTrash && retryOutcome.trashedURLs.count == 1,
              "P2.4: Scoped emptyContainer retry succeeds and moves the remaining child to Trash")
        check(fm.fileExists(atPath: realTrashContainer.path) && !fm.fileExists(atPath: realChild1.path) && !fm.fileExists(atPath: realChild2.path),
              "P2.4: Real emptyContainer preserves container shell directory while removing direct children")
        check(fm.fileExists(atPath: trashSink.appendingPathComponent("wasm_0.bin").path)
              && fm.fileExists(atPath: trashSink.appendingPathComponent("wasm_1.bin").path),
              "P2.4: All children moved by emptyContainer exist in Trash destination and are recoverable")

        // 6b. Unhooked system FileManager.trashItem verification (succeeds when host grants Trash access; reports .permission without data loss when sandbox denies)
        Cleaner.onTrashHook = nil
        let sysChild1 = try file("home/Library/Application Support/P9Cursor/Code Cache/wasm_0.bin", data: Data([10, 20, 30]))
        let sysChild2 = try file("home/Library/Application Support/P9Cursor/Code Cache/wasm_1.bin", data: Data([40, 50, 60]))
        let evalSysContainer = JunkRulePolicy.apply(ScanItem(url: realTrashContainer, name: "Code Cache", size: 0, safety: .safe, isSelected: true))
        let realOutcome = Cleaner.clean(CleanTarget.emptyContainer(from: Node.item(from: evalSysContainer)))
        if realOutcome.ok {
            check(realOutcome.actionCategory == .movedToTrash && realOutcome.trashedURLs.count == 2,
                  "P2.4: System Trash emptyContainer moves all direct children to system Trash")
            check(fm.fileExists(atPath: realTrashContainer.path) && !fm.fileExists(atPath: sysChild1.path) && !fm.fileExists(atPath: sysChild2.path),
                  "P2.4: System Trash emptyContainer preserves container shell directory")
            for trashedURL in realOutcome.trashedURLs {
                try? fm.removeItem(at: trashedURL)
            }
        } else {
            check(realOutcome.actionCategory == .failed
                  && realOutcome.failureKind == .permission
                  && realOutcome.failedChildDetails.count == 2
                  && realOutcome.failedChildDetails.allSatisfy({ $0.failureKind == .permission })
                  && fm.fileExists(atPath: realTrashContainer.path)
                  && fm.fileExists(atPath: sysChild1.path)
                  && fm.fileExists(atPath: sysChild2.path),
                  "P2.4: Restricted host Trash environment preserves original files and reports failureKind == .permission")
        }

        // 7. E4: TrashDeletion partial completion receipt & rollback conflict recoveryURL
        let trashAuthRoot = base.appendingPathComponent("authorized_trash")
        try? fm.removeItem(at: trashAuthRoot)
        let tdGood = try file("authorized_trash/folder/a_good.bin", data: Data(repeating: 0xAA, count: 4096))
        _ = try file("authorized_trash/folder/b_bad.bin", data: Data(repeating: 0xBB, count: 4096))
        let tdFolder = tdGood.deletingLastPathComponent()
        Cleaner.onAfterClaimHook = { claimedOriginalURL in
            // Simulate concurrent creation of a new item at the original path during staging
            try? Data([0xFF]).write(to: claimedOriginalURL)
        }
        Cleaner.onBeforeUnlinkHook = { targetURL in
            if targetURL.lastPathComponent == "b_bad.bin" {
                throw CocoaError(.fileWriteNoPermission)
            }
        }
        Cleaner.authorizedTrashRootsOverride = [trashAuthRoot]
        defer {
            Cleaner.onAfterClaimHook = nil
            Cleaner.onBeforeUnlinkHook = nil
            Cleaner.authorizedTrashRootsOverride = nil
        }
        let target = CleanTarget(name: tdFolder.lastPathComponent, url: tdFolder, size: 8192, action: .permanentlyDeleteTrashItem)
        let remErr = Cleaner.clean(target)
        check(!remErr.ok && remErr.actionCategory == CleanActionCategory.partialFailure, "E4: Cleaner.clean must report partial failure when a child fails during unlinkTree")
        check(remErr.permanentlyDeletedBytes >= 4096,
              "E4: Cleaner.clean records partially deleted child count and bytes")
        check(remErr.recoveryURL != nil && remErr.recoveryURL != tdFolder,
              "E4: TrashDeletion resolves rollback conflict via sibling recoveryURL without overwriting newly created file")
        if let recURL = remErr.recoveryURL {
            check(fm.fileExists(atPath: recURL.appendingPathComponent("b_bad.bin").path)
                  && !fm.fileExists(atPath: recURL.appendingPathComponent("a_good.bin").path),
                  "E4: Surviving child is preserved inside recoveryURL while unlinked child is gone")
        }
        check((try? Data(contentsOf: tdFolder)) == Data([0xFF]),
              "E4: Newly created file at original path is never overwritten by rollback")

        Cleaner.onAfterClaimHook = nil
        let sparseURL = try file("authorized_trash/sparse/a_sparse.bin", data: Data())
        let sparseHandle = try FileHandle(forWritingTo: sparseURL)
        try sparseHandle.truncate(atOffset: 128 * 1024 * 1024)
        try sparseHandle.close()
        _ = try file("authorized_trash/sparse/b_bad.bin", data: Data([1]))
        var sparseInfo = stat()
        check(lstat(sparseURL.path, &sparseInfo) == 0, "E4: Sparse fixture metadata is readable")
        let sparseAllocated = Int64(sparseInfo.st_blocks) * 512
        let sparseFolder = sparseURL.deletingLastPathComponent()
        let sparseTarget = CleanTarget(name: sparseFolder.lastPathComponent, url: sparseFolder, size: sparseAllocated, action: .permanentlyDeleteTrashItem)
        let sparseOutcome = Cleaner.clean(sparseTarget)
        check(!sparseOutcome.ok && sparseOutcome.actionCategory == CleanActionCategory.partialFailure, "E4: Sparse partial deletion must report the injected child failure")
        check(sparseOutcome.permanentlyDeletedBytes == sparseAllocated,
              "E4: Partial receipts use allocated blocks for sparse files, never logical length")
        Cleaner.onBeforeUnlinkHook = nil
        Cleaner.authorizedTrashRootsOverride = nil

        // 8. E3: Shell.execute timeout terminates background grandchildren ignoring HUP/TERM
        let shellMarker = base.appendingPathComponent("grandchild_marker")
        try? fm.removeItem(at: shellMarker)
        let shellCmd = "/bin/sh -c 'trap \"\" HUP TERM; /bin/sleep 0.4; /usr/bin/touch \"$1\"' child \"$1\" & wait"
        let shellRes = Shell.execute("/bin/sh", ["-c", shellCmd, "parent", shellMarker.path], timeout: 0.1)
        check(shellRes.exitCode == -2 && !fm.fileExists(atPath: shellMarker.path),
              "E3: Shell.execute returns -2 on timeout before grandchild touches marker")
        usleep(550_000)
        check(!fm.fileExists(atPath: shellMarker.path),
              "E3: Grandchild process is killed on timeout and never writes marker after return")

        // 9. E2: Batched @Published selection mutation emits once
        let batchState = AppState()
        let batchChildren = (0..<500).map { idx in
            Node(name: "leaf-\(idx)", url: base.appendingPathComponent("leaf-\(idx)"), size: 1, autoSelected: true)
        }
        batchState.roots = [Node(name: "root", children: batchChildren, isGroup: true)]
        var selectionPublishes = 0
        let cancellable = batchState.$selection.dropFirst().sink { _ in selectionPublishes += 1 }
        batchState.applyStrategy(.all, scopedToCategory: false)
        withExtendedLifetime(cancellable) {}
        check(selectionPublishes == 1 && batchState.selection.count == 500,
              "E2: AppState.applyStrategy(.all) publishes selection exactly once for 500 leaves")

        // 10. E5: DirectoryChildrenRepository distinguishes failed directory read from empty directory
        let missingDir = base.appendingPathComponent("nonexistent_dir_e5")
        let emptyDir = base.appendingPathComponent("empty_dir_e5")
        try? fm.removeItem(at: missingDir)
        try? fm.removeItem(at: emptyDir)
        try fm.createDirectory(at: emptyDir, withIntermediateDirectories: true)
        let repo = DirectoryChildrenRepository.shared
        repo.clear()
        _ = repo.children(for: missingDir)
        _ = repo.children(for: emptyDir)
        for _ in 0..<50 {
            if repo.failure(forPath: missingDir.path) != nil && repo.cached(forPath: emptyDir.path) != nil {
                break
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        check(repo.cached(forPath: missingDir.path) == nil && repo.failure(forPath: missingDir.path) != nil,
              "E5: Missing directory is recorded as failed state and never cached as Optional([])")
        check(repo.cached(forPath: emptyDir.path)?.count == 0 && repo.failure(forPath: emptyDir.path) == nil,
              "E5: Genuinely empty directory is cached as Optional([]) with 0 children")

        let metadataFailure = StopFlag(); metadataFailure.value = true
        let partialDir = base.appendingPathComponent("partial_metadata")
        _ = try file("partial_metadata/readable.bin", data: Data([1]))
        _ = try file("partial_metadata/denied.bin", data: Data([2]))
        let partialRepo = DirectoryChildrenRepository(fileSystem: MetadataFailureFileSystem(failing: metadataFailure))
        _ = partialRepo.children(for: partialDir)
        for _ in 0..<200 where partialRepo.isLoading(forPath: partialDir.path) { try await Task.sleep(nanoseconds: 20_000_000) }
        check(partialRepo.cached(forPath: partialDir.path)?.count == 1 && partialRepo.failure(forPath: partialDir.path) != nil,
              "E5: Child metadata errors preserve readable results and publish incomplete coverage")
        var dynamicTree = [Node(name: "partial", url: partialDir, isGroup: true)]
        partialRepo.reconcile(&dynamicTree)
        check(dynamicTree[0].children.count == 1, "E5: Partial dynamic results are selectable through the tree")
        metadataFailure.value = false
        partialRepo.retry(partialDir)
        for _ in 0..<200 where partialRepo.isLoading(forPath: partialDir.path) { try await Task.sleep(nanoseconds: 20_000_000) }
        check(partialRepo.cached(forPath: partialDir.path)?.count == 2 && partialRepo.failure(forPath: partialDir.path) == nil,
              "E5: Retrying an incomplete listing replaces it with a complete result")
        partialRepo.reconcile(&dynamicTree)
        check(dynamicTree[0].children.count == 2, "E5: Retry refreshes previously merged dynamic tree children")
        for index in 0..<(AppConfig.UI.directoryCacheEntryLimit + 1) {
            let directory = base.appendingPathComponent("cache_\(index)")
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            _ = partialRepo.children(for: directory)
            for _ in 0..<200 where partialRepo.isLoading(forPath: directory.path) { try await Task.sleep(nanoseconds: 1_000_000) }
        }
        check(partialRepo.cached(forPath: partialDir.path) == nil,
              "E5: LRU evicts old directory listings when the entry budget is exceeded")
        partialRepo.reconcile(&dynamicTree)
        check(dynamicTree[0].children.isEmpty, "E5: Evicted listings are also released from the selectable tree")
        partialRepo.clear()

        // 11. E6: Cross-target hard-link deduplication across sibling directories
        FileUtil.resetHardLinkLedger()
        let hlFirst = base.appendingPathComponent("cross_links/a")
        let hlSecond = base.appendingPathComponent("cross_links/b")
        try? fm.removeItem(at: base.appendingPathComponent("cross_links"))
        try fm.createDirectory(at: hlFirst, withIntermediateDirectories: true)
        try fm.createDirectory(at: hlSecond, withIntermediateDirectories: true)
        let hlPayload = hlFirst.appendingPathComponent("payload.bin")
        try Data(repeating: 0x6A, count: 65536).write(to: hlPayload)
        try fm.linkItem(at: hlPayload, to: hlSecond.appendingPathComponent("payload.bin"))
        let contextA = IOScanContext(stopped: { false })
        let firstBytes = contextA.perform { FileUtil.size(of: hlFirst) }
        let contextB = IOScanContext(stopped: { false })
        let secondBytes = contextA.perform { FileUtil.size(of: hlSecond) }
        let unionBytes = contextA.perform { FileUtil.size(of: hlFirst.deletingLastPathComponent()) }
        let independentBytes = contextB.perform { FileUtil.size(of: hlSecond) }
        check(independentBytes == firstBytes, "E6: Independent scan contexts have independent attribution")
        check(FileUtil.size(of: hlSecond) == firstBytes, "E6: Standalone size measurements do not inherit another scan ledger")
        let reverseContext = IOScanContext(stopped: { false })
        _ = reverseContext.perform { FileUtil.size(of: hlSecond) }
        check(reverseContext.perform { FileUtil.size(of: hlFirst.deletingLastPathComponent()) } == firstBytes,
              "E6: Union totals are correct even when a non-attributed alias is visited first")
        let fileContext = IOScanContext(stopped: { false })
        let regularFirst = fileContext.perform { FileUtil.size(of: hlPayload) }
        let regularSecond = fileContext.perform { FileUtil.size(of: hlSecond.appendingPathComponent("payload.bin")) }
        check(regularFirst == firstBytes && regularSecond == 0, "E6: Direct regular-file targets share hard-link attribution within a scan")
        check(firstBytes > 0 && secondBytes == 0 && (firstBytes + secondBytes) == unionBytes,
              "E6: Cross-target hard-linked files are not double-counted across sibling directories")

        // 12. E1: RuleAwareDeduplicator respects IOScanContext.isCancelled
        let cancelledCtx = IOScanContext(stopped: { true })
        let cancelledDedup = cancelledCtx.perform {
            RuleAwareDeduplicator.deduplicate([
                ScanItem(url: hlFirst, name: "a", size: 1024, safety: .safe),
                ScanItem(url: hlSecond, name: "b", size: 1024, safety: .safe)
            ])
        }
        check(cancelledDedup.items.isEmpty,
              "E1: RuleAwareDeduplicator.deduplicate aborts immediately when IOScanContext is cancelled")
    }
}
