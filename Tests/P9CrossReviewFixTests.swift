import Foundation
import AppKit
import SQLite3
import Security
import Darwin

@MainActor
final class P9CrossReviewFixTests {
    var passed = 0
    let base = URL(fileURLWithPath: "/private/tmp/AClean-P9-" + UUID().uuidString)
    let fm = FileManager.default
    func check(_ value: @autoclosure () -> Bool, _ message: String) {
        precondition(value(), "P9: " + message); passed += 1
    }
    func file(_ path: String, data: Data = Data([1, 2, 3])) throws -> URL {
        let url = base.appendingPathComponent(path)
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url); return url
    }
    func sql(_ sql: String, db: URL) throws {
        var handle: OpaquePointer?
        guard sqlite3_open(db.path, &handle) == SQLITE_OK else { throw CocoaError(.fileReadCorruptFile) }
        defer { sqlite3_close(handle) }
        guard sqlite3_exec(handle, sql, nil, nil, nil) == SQLITE_OK else { throw CocoaError(.fileReadCorruptFile) }
    }
    func runAll() async throws {
        check(MaintenanceSigning.requirement(team: "ABCDEF1234", identifier: AppConfig.PrivilegedHelper.service) != nil,
              "Helper: Signed peer requirement accepts a well-formed team and identifier")
        check(MaintenanceSigning.requirement(team: "bad\" or true", identifier: AppConfig.PrivilegedHelper.clientIdentifier) == nil,
              "Helper: Team requirement injection is rejected")
        check(MaintenanceSigning.requirement(team: "ABCDEF1234", identifier: "bad\" or true") == nil,
              "Helper: Identifier requirement injection is rejected")
        var peerRequirement: SecRequirement?
        let peerRequirementText = MaintenanceSigning.requirement(team: "ABCDEF1234", identifier: AppConfig.PrivilegedHelper.service)!
        check(SecRequirementCreateWithString(peerRequirementText as CFString, [], &peerRequirement) == errSecSuccess,
              "Helper: Peer requirement parses with the Security framework")
        check(AppConfig.PrivilegedHelper.commands.keys.sorted() == ["flushDNS", "reindexSpotlight", "runMaintenanceScripts", "thinTimeMachine"],
              "Helper: Privileged command manifest contains only reviewed task IDs")
        check(AppConfig.PrivilegedHelper.commands.values.flatMap { $0 }.allSatisfy { path, _ in
            path.hasPrefix("/") && !["/bin/sh", "/bin/zsh", "/usr/bin/osascript"].contains(path)
        }, "Helper: Privileged commands use absolute executables without shell interpreters")
        check(!PrivilegedMaintenanceClient.run("untrusted task; touch /tmp/injected"),
              "Helper: Unknown privileged payload fails before any connection or execution")
        let kb = KnowledgeBaseManager.shared
        let published = URL(fileURLWithPath: ProcessInfo.processInfo.environment["ACLEAN_RULES_DB"]!)
        try fm.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: base) }
        try requestedReviewFixRegressions()
        try kb.load(from: published)
        defer { try? kb.load(from: published) }
        let original = kb.authored
        // P8 has finished already: its deleted fixture must not remain the singleton's source.
        check(original.junk["JC.AI.IDE.CACHE"]?.paths.contains("~/Library/Application Support/Cursor") == true,
              "P8 restores published snapshot before subsequent tests")
        check(original.templates.filter { $0.id != "UNINST_01" }.allSatisfy { !$0.selected }, "SQL associated data defaults match effective policy")
        check(original.junk["JC.DEV.BREW.DOWNLOADS"]?.tier == .review
              && original.junk["JC.DEV.BREW.CACHE"]?.tier == .review
              && original.junk["JC.DEV.NPM.CACACHE"]?.tier == .review
              && original.junk["JC.DEV.XCODE.CACHE"]?.tier == .review
              && original.junk["JC.DEV.PKG.SAFE"]?.tier == .review,
              "T08: Homebrew downloads/cache, npm cacache, and Xcode module cache are L2 review alongside package manager caches")
        let automatic = Set(original.junk.values.filter(\.selected).map(\.id))
        check(automatic == AppConfig.RuleIDs.implementedAutomaticRules, "published defaults exactly match proven runtime capabilities")
        check(!AppConfig.RuleIDs.implementedPredicates.contains("plutil_fail AND reread_fail"), "unimplemented validation cannot be enabled by naming its predicate")
        let db = base.appendingPathComponent("rules.db")
        try fm.copyItem(at: published, to: db)
        let home = base.appendingPathComponent("home").path.replacingOccurrences(of: "'", with: "''")
        let system = base.appendingPathComponent("system").path.replacingOccurrences(of: "'", with: "''")
        try sql("UPDATE cm_discovery_binding SET path_template=replace(replace(path_template,'~/','\(home)/'),'Cursor','P9Cursor'); UPDATE cm_protected_path SET path_template=replace(path_template,'~/','\(home)/'); UPDATE cm_electron_data_dir SET bundle_id='org.cleanmate.p9.cursor', dir_name='P9Cursor' WHERE dir_name='Cursor'; INSERT INTO cm_electron_data_dir(bundle_id,dir_name) VALUES ('org.cleanmate.p9.code','P9Code'); DELETE FROM cm_junk_rule_lock; DELETE FROM cm_cache_profile_lock; UPDATE cm_uninstall_template SET path_template=replace(replace(path_template,'~/','\(home)/'),'/Library/LaunchDaemons/','\(system)/LaunchDaemons/');", db: db)
        try kb.load(from: db)
        for (name, tier) in [("Cache", CleanupTier.automatic), ("GPUCache", .automatic), ("Code Cache", .automatic),
                             ("CachedData", .automatic), ("CachedExtensionVSIXs", .review), ("logs", .review), ("Crashpad/completed", .review)] {
            let url = try file("home/Library/Application Support/P9Cursor/" + name + "/data.bin").deletingLastPathComponent()
            let evidence = kb.authored.evidence(for: url, preferredID: "JC.AI.IDE.CACHE")
            check(evidence?.tier == tier, "IDE layout recognized: " + name)
            if tier == .review { check(evidence?.defaultSelected == false, "unproven contents require review: " + name) }
        }
        for relative in ["Crashpad", "User/workspaceStorage/GPUCache", "User/globalStorage/Cache", "IndexedDB", "Local Storage"] {
            let url = try file("home/Library/Application Support/P9Cursor/" + relative + "/keep.bin").deletingLastPathComponent()
            check(kb.authored.cacheSubdirTier(url, ruleID: "JC.AI.IDE.CACHE") == nil, "nested or active data not authorized: " + relative)
        }
        let browserCache = try file("home/Library/Application Support/Google/Chrome/Default/Cache/data.bin").deletingLastPathComponent()
        check(kb.authored.cacheSubdirTier(browserCache, ruleID: "JC.BRW.CHROMIUM.CACHE") == nil, "Electron Cache allowance cannot widen Chromium")
        let browserGPU = try file("home/Library/Application Support/Google/Chrome/Profile 1/GPUCache/data.bin").deletingLastPathComponent()
        check(kb.authored.cacheSubdirTier(browserGPU, ruleID: "JC.BRW.CHROMIUM.CACHE") == .automatic, "browser profile GPU allowance preserved")
        let electronCache = try file("home/Library/Application Support/P9Code/Cache/data.bin").deletingLastPathComponent()
        check(kb.authored.evidence(for: electronCache, preferredID: "JC.ELECTRON.CACHE")?.tier == .automatic, "mapped Electron Cache evidence restored")
        try discoveryAndLocks()
        try step1AuthorizationAndEvidence(db: db)
        try step2EvaluationAndDeduplication()
        try step3ContainerSnapshotAndMeasurement()
        try step4OpenFileScopeAndUID()
        try step5PostReviewOptimizations(db: db)
        try migrationEquivalenceComparison()
        try presentation()
        try uninstall()
        try handles()
        try performance()
        try await p1AndP2FinalSpecVerification(db: db)
        // Junk Spec v1.2 40-case acceptance matrix:
        // A01 A02 A03 A04 A05 A06 A07 A08 A09 A10 A11 A12 A13 A14 A15 A16 A17
        // C01 C02 C03 C04 C05 C06 C07 C08 C09 C10 C11 C12 C13 C14 C15 C16 C17 C18 C19 C20 C21 C22 C23
        try await phase1JunkSpecVerification(published: published)
        try await reviewStateAndMemoryRegressions()
        print("P9: \(passed) cross-review regression assertions passed")
    }
    func step1AuthorizationAndEvidence(db: URL) throws {
        // 1. 无证据垃圾候选强制锁定且执行期拒绝
        let unmatchedFile = try file("unmatched/mystery_cache.dat")
        let unmatchedScan = JunkRulePolicy.apply(ScanItem(url: unmatchedFile, name: "mystery_cache.dat", size: 3, safety: .safe, isSelected: true))
        check(unmatchedScan.ruleEvidence == nil, "unmatched path has nil ruleEvidence")
        check(unmatchedScan.locked == true && !unmatchedScan.isSelected, "unmatched junk candidate is locked and deselected")
        check(unmatchedScan.evaluationReason == .noMatchingAuthoredRule, "unmatched junk candidate records noMatchingAuthoredRule")
        let unmatchedNode = Node.item(from: unmatchedScan)
        check(unmatchedNode.locked && unmatchedNode.authorizationContext == .junkRule, "Node preserves locked state and .junkRule context")
        let manualForgedJunkTarget = CleanTarget(name: "forged junk", url: unmatchedFile, size: 3, action: .trash, locked: false, authorizationContext: .junkRule)
        let forgedOutcome = Cleaner.clean(manualForgedJunkTarget)
        check(!forgedOutcome.ok && forgedOutcome.actionCategory == .skipped, "Cleaner rejects unlocked .junkRule target lacking ruleEvidence")

        // 2. 跨模块零退化：空间整理手动目标（含 OrganizeEngine.largeAndOld 真实扫描产物）、系统维护注册表任务正常工作
        let organizeDir = base.appendingPathComponent("organize")
        let organizeFile = try file("organize/large_video.mp4", data: Data(repeating: 0xAB, count: 11 * 1024 * 1024))
        let laofGroup = OrganizeEngine.largeAndOld(
            thresholdBytes: 10 * 1024 * 1024,
            oldMonths: 6,
            rootsOverride: [organizeDir],
            progress: { _, _ in },
            stopped: { false }
        )
        check(laofGroup != nil && laofGroup?.items.count == 1, "OrganizeEngine.largeAndOld discovers large file candidate")
        if let laofItem = laofGroup?.items.first {
            check(laofItem.url.standardizedFileURL == organizeFile.standardizedFileURL && laofItem.authorizationContext == .organizeManual,
                  "OrganizeEngine.largeAndOld assigns .organizeManual authorizationContext")
            let laofNode = Node.item(from: laofItem)
            let laofTarget = CleanTarget(laofNode)
            check(laofTarget.authorizationContext == .organizeManual && laofTarget.ruleEvidence == nil,
                  "Node.item and CleanTarget preserve .organizeManual and nil ruleEvidence from OrganizeEngine.largeAndOld")
            var forgedOrganizeWithRuleEvidence = laofTarget
            forgedOrganizeWithRuleEvidence.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic, reason: .generalCache, defaultSelected: true)
            check(!Cleaner.clean(forgedOrganizeWithRuleEvidence).ok,
                  "Cleaner rejects .organizeManual target carrying non-nil ruleEvidence per §3.1 matrix")
            let laofOutcome = Cleaner.clean(laofTarget)
            check(laofOutcome.ok && laofOutcome.actionCategory == .movedToTrash,
                  "OrganizeEngine.largeAndOld candidate succeeds end-to-end in Cleaner.clean")
        }

        let validMaintTarget = CleanTarget(name: "Flush DNS", url: nil, size: 0, action: .custom("maint:flushDNS"), authorizationContext: .systemMaintenance)
        check(Cleaner.clean(validMaintTarget).ok, "Registered maint:flushDNS succeeds under .systemMaintenance")
        let legacyNameMaintTarget = CleanTarget(name: "Flush DNS Cache", url: nil, size: 0, action: .custom("Flush DNS Cache"), authorizationContext: .systemMaintenance)
        check(!Cleaner.clean(legacyNameMaintTarget).ok, "Non-prefixed custom payload rejected without fallback to display name")

        // 3. JC.LOG.USER 子目录分级与人工勾选执行闭环：
        //    - 纯日志子目录 (pureSubdir) -> L1 自动勾选且可执行
        //    - 混有非日志文件的子目录 (mixedSubdir) 与非日志直接子文件 (top_report.pdf) -> 降为 L2 (.review) 不默认勾选，但用户手动勾选后 Cleaner.clean 允许正常清理
        //    - 含受保护资产的子目录 (protectedSubdir/Cookies) -> 降为 L3 (.readOnly) 锁定且 Cleaner.clean 拒绝清理
        _ = try file("home/Library/Logs/P9LogDirTest/pureSubdir/a.log")
        _ = try file("home/Library/Logs/P9LogDirTest/pureSubdir/b.out")
        _ = try file("home/Library/Logs/P9LogDirTest/mixedSubdir/c.log")
        _ = try file("home/Library/Logs/P9LogDirTest/mixedSubdir/report.pdf")
        _ = try file("home/Library/Logs/P9LogDirTest/top_report.pdf")
        _ = try file("home/Library/Logs/P9LogDirTest/protectedSubdir/Cookies")
        let logRoot = base.appendingPathComponent("home/Library/Logs/P9LogDirTest")
        let evaluatedLogRoot = JunkRulePolicy.apply(ScanItem(url: logRoot, name: "P9LogDirTest", size: 18, safety: .safe, isSelected: true))
        let pureChild = evaluatedLogRoot.children.first { $0.name == "pureSubdir" }
        let mixedChild = evaluatedLogRoot.children.first { $0.name == "mixedSubdir" }
        let nonLogTopFile = evaluatedLogRoot.children.first { $0.name == "top_report.pdf" }
        let protectedChild = evaluatedLogRoot.children.first { $0.name == "protectedSubdir" }
        check(pureChild?.isSelected == true && pureChild?.ruleEvidence?.tier == .automatic && pureChild?.ruleEvidence?.defaultSelected == true,
              "Subdirectory containing only valid log files is eligible for L1 auto-selection")
        check(mixedChild?.isSelected == false && mixedChild?.locked == false && mixedChild?.ruleEvidence?.tier == .review && mixedChild?.ruleEvidence?.defaultSelected == false,
              "Subdirectory containing non-log file (report.pdf) is downgraded to L2 review and unselected by default")
        check(nonLogTopFile?.isSelected == false && nonLogTopFile?.locked == false && nonLogTopFile?.ruleEvidence?.tier == .review,
              "Direct non-log file under log container is downgraded to L2 review and unselected by default")
        check(protectedChild?.locked == true && protectedChild?.ruleEvidence?.tier == .readOnly,
              "Log container child containing protected asset (Cookies) is L3 read-only locked")
        if let mixedChild {
            let manualReviewTarget = CleanTarget(Node.item(from: mixedChild))
            let manualOutcome = Cleaner.clean(manualReviewTarget)
            check(manualOutcome.ok && manualOutcome.actionCategory == .movedToTrash,
                  "User manually selecting L2 review log subdirectory succeeds in Cleaner.clean")
        } else {
            check(false, "Expected mixedSubdir child in P9LogDirTest")
        }
        if let nonLogTopFile {
            let manualFileOutcome = Cleaner.clean(CleanTarget(Node.item(from: nonLogTopFile)))
            check(manualFileOutcome.ok && manualFileOutcome.actionCategory == .movedToTrash,
                  "User manually selecting L2 review non-log file succeeds in Cleaner.clean")
        }
        if let protectedChild {
            var forgedProtectedTarget = CleanTarget(Node.item(from: protectedChild))
            forgedProtectedTarget.locked = false
            check(!Cleaner.clean(forgedProtectedTarget).ok,
                  "Cleaner rejects forged execution of L3 protected child in log container")
        }

        // 3b. 结构化原因枚举完整产出验证 (unimplementedPredicate / unknownOrNonTrashAction / missingScanEntry) 与五态规则审计
        let brokenPrefFile = try file("home/Library/Preferences/com.p9.broken.plist", data: Data([0x00, 0xFF]))
        let evaluatedFreshBrokenPref = JunkRulePolicy.apply(ScanItem(url: brokenPrefFile, name: "com.p9.broken.plist", size: 2, safety: .safe, isSelected: true))
        check(evaluatedFreshBrokenPref.locked == true && !evaluatedFreshBrokenPref.isSelected,
              "Newly modified (<24h) corrupted plist is protected as L3 read-only per Gate 5.1")
        try fm.setAttributes([.modificationDate: Date().addingTimeInterval(-30 * 3600)], ofItemAtPath: brokenPrefFile.path)
        let evaluatedBrokenPref = JunkRulePolicy.apply(ScanItem(url: brokenPrefFile, name: "com.p9.broken.plist", size: 2, safety: .safe, isSelected: true))
        check(evaluatedBrokenPref.locked == false && !evaluatedBrokenPref.isSelected && evaluatedBrokenPref.ruleEvidence?.tier == .review,
              "Corrupted plist (>24h, plutil_lint_failed AND not_in_use) is evaluated as L2 review and unselected by default")

        let ollamaBlobFile = try file("home/.ollama/models/blobs/sha256-deadbeef", data: Data([0x01, 0x02]))
        let evaluatedOllamaBlob = JunkRulePolicy.apply(ScanItem(url: ollamaBlobFile, name: "sha256-deadbeef", size: 2, safety: .safe, isSelected: true))
        check(evaluatedOllamaBlob.locked == true && !evaluatedOllamaBlob.isSelected, "Rule with unimplemented predicate is locked read-only")
        if case .unimplementedPredicate(let rID, let pred) = evaluatedOllamaBlob.evaluationReason {
            check(rID == "JC.AI.OLLAMA.ORPHAN" && pred == "blob_refcount_zero", "unimplementedPredicate records ruleId and predicate")
        } else {
            check(false, "Expected unimplementedPredicate reason for JC.AI.OLLAMA.ORPHAN")
        }

        let simFile = try file("home/Library/Developer/CoreSimulator/Devices/sim1/data.bin")
        let simDir = simFile.deletingLastPathComponent().deletingLastPathComponent()
        let evaluatedSim = JunkRulePolicy.apply(ScanItem(url: simDir, name: "Devices", size: 3, safety: .caution, isSelected: false))
        check(evaluatedSim.locked == true, "read_only action rule is locked")
        if case .unknownOrNonTrashAction(let rID, let act) = evaluatedSim.evaluationReason {
            check(rID == "JC.DEV.XCODE.SIMULATOR" && act == "read_only", "unknownOrNonTrashAction records ruleId and non-trash action")
        } else {
            check(false, "Expected unknownOrNonTrashAction reason for JC.DEV.XCODE.SIMULATOR")
        }

        let missingEntryDB = base.appendingPathComponent("missing_entry_rules.db")
        try? fm.removeItem(at: missingEntryDB)
        try fm.copyItem(at: db, to: missingEntryDB)
        try sql("INSERT INTO cm_junk_rule (id, section, tier, action, status, default_selected, rebuild_cost, reason_code, title_key, fixture_required) VALUES ('JC.TEST.ORPHAN.RULE', 'system', 'L1', 'trash', 'active', 1, 'none', 'REASON_CODE_GENERAL_CACHE', 'test', 0); INSERT INTO cm_junk_rule (id, section, tier, action, status, default_selected, rebuild_cost, reason_code, title_key, fixture_required) VALUES ('JC.TEST.UNCOVERED.DEPTH', 'system', 'L2', 'trash_children_only', 'active', 0, 'none', 'REASON_CODE_GENERAL_CACHE', 'test_depth', 0); INSERT INTO cm_discovery_binding (rule_id, path_template, path_kind, scanner_id, discovery_kind, status) VALUES ('JC.TEST.UNCOVERED.DEPTH', '~/Library/Caches/SomeVendor/Profiles/*/deep_cache', 'glob', 'deferred', 'explicit_not_supported', 'deferred');", db: missingEntryDB)
        try KnowledgeBaseManager.shared.load(from: missingEntryDB)
        let auditCtx = IOScanContext(stopped: { false })
        let missingReasons = auditCtx.perform {
            KnowledgeBaseManager.shared.authored.auditRuleScanEntries()
        }
        check(missingReasons.contains(.missingScanEntry(ruleId: "JC.TEST.ORPHAN.RULE")),
              "auditRuleScanEntries detects and records missingScanEntry for rules without path template")
        check(missingReasons.contains(.missingScanEntry(ruleId: "JC.TEST.UNCOVERED.DEPTH")),
              "auditRuleScanEntries detects rules that have path templates but lack depth-matched scanner entry coverage")
        check(!missingReasons.contains(.missingScanEntry(ruleId: "JC.DEV.XCODE.DEVICESUPPORT.LATEST"))
              && !missingReasons.contains(.missingScanEntry(ruleId: "JC.SYS.SAVEDSTATE")),
              "Contextual protection rules (DEVICESUPPORT.LATEST, SAVEDSTATE) are not misclassified as missingScanEntry")
        let statuses = KnowledgeBaseManager.shared.authored.auditRuleStatuses()
        let autoRecommendableIDs = Set(statuses.values.filter(\.isAutoRecommendable).map(\.ruleID))
        check(autoRecommendableIDs == AppConfig.RuleIDs.implementedAutomaticRules,
              "5-state RuleStatusAudit confirms all 16 implementedAutomaticRules have depth-matched scanner entry coverage and are auto-recommendable")
        check(statuses["JC.DEV.XCODE.DEVICESUPPORT.LATEST"]?.role == .contextualProtection
              && statuses["JC.SYS.SAVEDSTATE"]?.role == .contextualProtection,
              "RuleStatusAudit classifies DEVICESUPPORT.LATEST and SAVEDSTATE as contextualProtection role")
        check(statuses["JC.TEST.UNCOVERED.DEPTH"]?.isExecutable == false
              && statuses["JC.TEST.UNCOVERED.DEPTH"]?.hasScanEntry == false
              && statuses["JC.TEST.UNCOVERED.DEPTH"]?.isAutoRecommendable == false,
              "Deferred discovery binding has no executable or automatic capability")
        check(statuses["JC.SYS.PLIST.BROKEN"]?.isDefined == true && statuses["JC.SYS.PLIST.BROKEN"]?.hasScanEntry == true && statuses["JC.SYS.PLIST.BROKEN"]?.isPredicateImplemented == true && statuses["JC.SYS.PLIST.BROKEN"]?.isExecutable == true,
              "Broken plist rule has implemented predicate and is executable as L2 review")

        // F02: 保壳容器直接子项存在更严格规则 (L2 / L3) 时，严禁被父容器 L1 证据覆盖，且 Cleaner.clean 阻断伪造 L1 越权
        let specificManualRoot = try file("home/Library/Logs/P9SpecificContainer/manual/session.log").deletingLastPathComponent()
        let specificReadonlyRoot = try file("home/Library/Logs/P9SpecificContainer/readonly/session.log").deletingLastPathComponent()
        for (ruleID, tier, targetURL) in [("JC.REVIEW.DIRECT.L2", "L2", specificManualRoot), ("JC.REVIEW.DIRECT.L3", "L3", specificReadonlyRoot)] {
            let escapedPath = targetURL.path.replacingOccurrences(of: "'", with: "''")
            let bindingStatus = tier == "L3" ? "inventory_only" : "active"
            try sql("INSERT INTO cm_junk_rule(id,section,tier,action,status,default_selected,rebuild_cost,reason_code,title_key,fixture_required) VALUES ('\(ruleID)','system','\(tier)','trash','active',0,'none','REASON_CODE_MANUAL_REVIEW','review',0); INSERT INTO cm_discovery_binding(rule_id,path_template,path_kind,scanner_id,discovery_kind,status) VALUES ('\(ruleID)','\(escapedPath)','root','scanSystemLogs','fixed_path','\(bindingStatus)');", db: missingEntryDB)
        }
        try KnowledgeBaseManager.shared.load(from: missingEntryDB)
        let evaluatedSpecificParent = JunkRulePolicy.apply(
            ScanItem(url: specificManualRoot.deletingLastPathComponent(), name: "P9SpecificContainer", size: 6, safety: .safe, isSelected: true)
        )
        let manualDirectChild = evaluatedSpecificParent.children.first { $0.name == "manual" }
        let readonlyDirectChild = evaluatedSpecificParent.children.first { $0.name == "readonly" }
        check(manualDirectChild?.ruleEvidence?.id == "JC.REVIEW.DIRECT.L2"
              && manualDirectChild?.ruleEvidence?.tier == .review
              && manualDirectChild?.isSelected == false
              && manualDirectChild?.locked == false,
              "F02: Direct child matching L2 rule retains JC.REVIEW.DIRECT.L2 and L2 review tier instead of inheriting parent L1")
        check(readonlyDirectChild?.ruleEvidence?.id == "JC.REVIEW.DIRECT.L3"
              && readonlyDirectChild?.ruleEvidence?.tier == .readOnly
              && readonlyDirectChild?.isSelected == false
              && readonlyDirectChild?.locked == true,
              "F02: Direct child matching L3 rule is locked read-only under JC.REVIEW.DIRECT.L3")
        if let manualDirectChild {
            var forgedL1ChildTarget = CleanTarget(Node.item(from: manualDirectChild))
            forgedL1ChildTarget.ruleEvidence = CleanupRuleEvidence(
                id: "JC.LOG.USER",
                tier: .automatic,
                reason: .generalCache,
                defaultSelected: true,
                containerPath: manualDirectChild.ruleEvidence?.containerPath,
                containerIdentity: manualDirectChild.ruleEvidence?.containerIdentity
            )
            check(!Cleaner.clean(forgedL1ChildTarget).ok,
                  "F02: Cleaner.clean rejects forged L1 container evidence when direct child matches stricter L2 rule")
            let legitimateManualChildTarget = CleanTarget(Node.item(from: manualDirectChild))
            check(Cleaner.clean(legitimateManualChildTarget).ok,
                  "F02: Cleaner.clean permits legitimate L2 review execution when user explicitly confirms direct child")
        }

        // F01: 即使规则未配置静态 cm_junk_rule_lock (bundleLocks.isEmpty)，只要命中 cm_electron_data_dir 的动态运行中应用映射，必须降级 L3 只读并在 Cleaner.clean 中拦截
        if let runningBid = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier != nil && !$0.isTerminated })?.bundleIdentifier {
            let mappedIDECache = try file("home/Library/Application Support/P9MappedRunningIDE/GPUCache/cache.bin").deletingLastPathComponent()
            let mappedIDERoot = mappedIDECache.deletingLastPathComponent().path.replacingOccurrences(of: "'", with: "''")
            let escapedBid = runningBid.replacingOccurrences(of: "'", with: "''")
            try sql("DELETE FROM cm_junk_rule_lock WHERE rule_id='JC.AI.IDE.CACHE'; INSERT INTO cm_discovery_binding(rule_id,path_template,path_kind,scanner_id,discovery_kind,status) VALUES ('JC.AI.IDE.CACHE','\(mappedIDERoot)','root','scanUserCaches','profile_leaves','active'); INSERT OR REPLACE INTO cm_electron_data_dir(bundle_id,dir_name) VALUES ('\(escapedBid)','P9MappedRunningIDE');", db: missingEntryDB)
            try KnowledgeBaseManager.shared.load(from: missingEntryDB)
            let evaluatedRunningIDE = JunkRulePolicy.apply(
                ScanItem(url: mappedIDECache, name: "GPUCache", size: 3, safety: .safe, isSelected: true)
            )
            let runningIDELeaf = evaluatedRunningIDE.children.first ?? evaluatedRunningIDE
            check(runningIDELeaf.locked == true && !runningIDELeaf.isSelected && runningIDELeaf.ruleEvidence?.tier == .readOnly,
                  "F01: Dynamic cm_electron_data_dir running app lock enforces L3 read-only even when explicit bundleLocks is empty")
            var forgedRunningTarget = CleanTarget(Node.item(from: runningIDELeaf))
            forgedRunningTarget.locked = false
            forgedRunningTarget.ruleEvidence = CleanupRuleEvidence(
                id: "JC.AI.IDE.CACHE",
                tier: .automatic,
                reason: .generalCache,
                defaultSelected: true,
                containerPath: runningIDELeaf.ruleEvidence?.containerPath,
                containerIdentity: runningIDELeaf.ruleEvidence?.containerIdentity
            )
            check(!Cleaner.clean(forgedRunningTarget).ok,
                  "F01: Cleaner.clean rejects execution for running mapped IDE cache")
        }

        // F11: PerformanceEngine.runTask 闭集校验拦截未注册 MaintenanceTask
        let unregisteredTask = PerformanceEngine.MaintenanceTask(
            taskId: "unregistered.arbitrary.task",
            name: "Unregistered Task",
            detail: "Should be rejected by closed-set check",
            command: "/usr/bin/true",
            needsAdmin: false,
            asset: "xmark"
        )
        check(!PerformanceEngine.runTask(unregisteredTask),
              "F11: PerformanceEngine.runTask rejects unregistered task ID at final execution entry")

        try KnowledgeBaseManager.shared.load(from: db)

        // 4. 规则库不可用时记录 ScanDegradationReason.ruleDatabaseUnavailable、阻止“干净”空状态并展示明确规则库告警
        let unloadedDB = base.appendingPathComponent("unloaded_rules.db")
        try? fm.removeItem(at: unloadedDB)
        try fm.copyItem(at: db, to: unloadedDB)
        try sql("DROP TABLE cm_junk_rule;", db: unloadedDB)
        try KnowledgeBaseManager.shared.load(from: unloadedDB)
        defer { try? KnowledgeBaseManager.shared.load(from: db) }
        check(!KnowledgeBaseManager.shared.authored.loaded, "Dropping cm_junk_rule results in authored.loaded == false")
        let scanCtx = IOScanContext(stopped: { false })
        let degradedLogFile = try file("home/Library/Logs/P9LogDirTest/degraded.log")
        let degradedItem = scanCtx.perform {
            JunkRulePolicy.apply(ScanItem(url: degradedLogFile, name: "degraded.log", size: 3, safety: .safe, isSelected: true))
        }
        check(degradedItem.locked == true && !degradedItem.isSelected, "Candidate is locked and deselected when rule DB is unavailable")
        check(degradedItem.evaluationReason == .ruleDatabaseUnavailable, "Candidate records ruleDatabaseUnavailable reason")
        check(scanCtx.degradations.contains(.ruleDatabaseUnavailable) && !scanCtx.issues.isEmpty, "IOScanContext records ruleDatabaseUnavailable degradation and issue")

        let degradedState = AppState()
        degradedState.moduleKey = "junk"
        var degradedSession = degradedState.session(for: "junk")
        degradedSession.hasScanned = true
        degradedSession.scanning = false
        degradedSession.roots = []
        degradedSession.scanDegradations = [.ruleDatabaseUnavailable]
        degradedSession.scanIssues = [L10n.localized(.ruleDatabaseUnavailableBanner)]
        degradedSession.completedSuccessfully = false
        degradedState.write(.junk) { $0 = degradedSession }
        check(degradedState.hasRuleDatabaseDegradation, "AppState reports hasRuleDatabaseDegradation when rule DB is unavailable")
        check(!degradedState.canPresentSpotlessEmptyState, "AppState forbids green Spotless empty state when rule DB is degraded")
        check(degradedState.activeScanDegradationBanner == L10n.localized(.ruleDatabaseUnavailableBanner),
              "AppState surfaces explicit ruleDatabaseUnavailableBanner instead of generic incomplete banner")
    }
    func step2EvaluationAndDeduplication() throws {
        let scanCtx = IOScanContext(stopped: { false })

        // 1. 同路径双候选：一条低风险/宽泛规则，一条更具体或 L3 只读规则 -> 必定保留更具体/更保守规则并留痕
        let sameURL = try file("home/Library/Caches/pnpm/store_index.bin")
        var looseCandidate = ScanItem(url: sameURL, name: "pnpm loose", size: 100, safety: .safe, isSelected: true, locked: false, isRuleEvaluated: true)
        looseCandidate.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic, reason: .generalCache, defaultSelected: true)
        var strictCandidate = ScanItem(url: sameURL, name: "pnpm strict", size: 100, safety: .caution, isSelected: false, locked: true, isRuleEvaluated: true)
        strictCandidate.ruleEvidence = CleanupRuleEvidence(id: "JC.DEV.PKG.SAFE", tier: .readOnly, reason: .whitelistProtected, defaultSelected: false)

        let samePathResult = scanCtx.perform {
            RuleAwareDeduplicator.deduplicate([looseCandidate, strictCandidate])
        }
        check(samePathResult.items.count == 1, "Exact path overlap deduplicates to 1 winner")
        check(samePathResult.items[0].locked == true && samePathResult.items[0].ruleEvidence?.id == "JC.DEV.PKG.SAFE",
              "Exact path overlap retains locked/more-specific L3 rule over loose L1 candidate")
        check(samePathResult.records.count == 1 && samePathResult.records[0].winnerRuleId == "JC.DEV.PKG.SAFE" && samePathResult.records[0].droppedRuleId == "JC.CACHE.USER",
              "Exact path deduplication emits DeduplicationRecord audit trail")

        // 1a-2. [P2-4] 无匹配规则而锁定（evaluationReason == .noMatchingAuthoredRule, ruleEvidence == nil）的候选与同路径有证据可清理候选重叠时，必须遵守“任一候选锁定即保留最严格限制”
        let noRuleLockedURL = try file("home/Library/Caches/P9OverlapNoRule/mystery.dat", data: Data(repeating: 6, count: 48))
        var noRuleLockedCand = ScanItem(url: noRuleLockedURL, name: "mystery.dat (unmatched)", size: 48, safety: .caution, isSelected: false, locked: true, isRuleEvaluated: true)
        noRuleLockedCand.evaluationReason = .noMatchingAuthoredRule
        var broadUnlockedCand = ScanItem(url: noRuleLockedURL, name: "mystery.dat (broad)", size: 48, safety: .safe, isSelected: true, locked: false, isRuleEvaluated: true)
        broadUnlockedCand.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic, reason: .generalCache, defaultSelected: true)
        let noRuleVsUnlocked1 = scanCtx.perform {
            RuleAwareDeduplicator.deduplicate([broadUnlockedCand, noRuleLockedCand])
        }
        let noRuleVsUnlocked2 = scanCtx.perform {
            RuleAwareDeduplicator.deduplicate([noRuleLockedCand, broadUnlockedCand])
        }
        check(noRuleVsUnlocked1.items.count == 1 && noRuleVsUnlocked1.items[0].locked == true && !noRuleVsUnlocked1.items[0].isSelected,
              "Locked candidate with .noMatchingAuthoredRule wins over unlocked rule-matched candidate (order: unlocked -> locked)")
        check(noRuleVsUnlocked2.items.count == 1 && noRuleVsUnlocked2.items[0].locked == true && !noRuleVsUnlocked2.items[0].isSelected,
              "Locked candidate with .noMatchingAuthoredRule cannot be overwritten by unlocked rule-matched candidate (order: locked -> unlocked)")
        check(noRuleVsUnlocked1.records.first?.reason == "locked_or_protected_priority" && noRuleVsUnlocked2.records.first?.reason == "locked_or_protected_priority",
              "Overlap between .noMatchingAuthoredRule locked candidate and unlocked candidate records locked_or_protected_priority")

        // 1a-3. [P2-5] 专项扫描不再在评估前通过 seen 集合静默丢弃同路径候选，全部进入 JunkRulePolicy.apply 与 RuleAwareDeduplicator 并产出 DeduplicationRecord
        let overlapLeafURL = try file("home/Library/Application Support/P9Cursor/Cache/overlap_entry.bin", data: Data(repeating: 4, count: 300_000))
        let electronScanCtx = IOScanContext(stopped: { false })
        let electronGroup = electronScanCtx.perform {
            JunkEngine.scanElectronCaches()
        }
        let cursorCacheURL = base.appendingPathComponent("home/Library/Application Support/P9Cursor/Cache").standardizedFileURL
        let cursorCacheWinners = (electronGroup?.items ?? []).filter { $0.url.standardizedFileURL == cursorCacheURL }
        check(cursorCacheWinners.count == 1 && cursorCacheWinners[0].ruleEvidence?.id == AppConfig.RuleIDs.aiIDECache,
              "scanElectronCaches evaluates both JC.ELECTRON.CACHE and JC.AI.IDE.CACHE and retains more specific JC.AI.IDE.CACHE via RuleAwareDeduplicator")
        let overlapLeafCanonical = RuleAwareDeduplicator.canonicalPath(for: overlapLeafURL)
        check(electronScanCtx.deduplicationRecords.contains {
            $0.winnerPath == overlapLeafCanonical && $0.winnerRuleId == AppConfig.RuleIDs.aiIDECache && $0.droppedRuleId == AppConfig.RuleIDs.electronCache && $0.reason == "rule_specificity_priority"
        }, "scanElectronCaches emits DeduplicationRecord instead of pre-evaluation Set skipping")

        // 1b. 跨组流式去重回写验证：先前扫描组已加入结果树的 Node，在后续扫描组发现同路径更严格候选或父子重叠时必须原地更新
        var crossDedup = RuleAwareDeduplicator()
        var emittedNodes: [Node] = []
        let group1 = ScanGroup(title: "Group1 Loose", icon: "folder", note: "", items: [looseCandidate])
        let changed1 = crossDedup.acceptGroup(group1, tags: ["System Junk"], into: &emittedNodes)
        check(emittedNodes.count == 1 && changed1.count == 1 && emittedNodes[0].leaves.first?.locked == false && emittedNodes[0].leaves.first?.autoSelected == true,
              "Group 1 initially emits loose L1 candidate")
        let group2 = ScanGroup(title: "Group2 Strict", icon: "lock", note: "", items: [strictCandidate])
        let changed2 = crossDedup.acceptGroup(group2, tags: ["System Junk"], into: &emittedNodes)
        check(emittedNodes.count == 1, "Group 2 same-path stricter candidate updates Group 1 in place without adding duplicate node")
        let updatedLeaf = emittedNodes[0].leaves.first
        check(updatedLeaf?.locked == true && updatedLeaf?.autoSelected == false && updatedLeaf?.ruleEvidence?.id == "JC.DEV.PKG.SAFE",
              "Previously emitted Node in result tree is updated in-place to locked L3 rule")
        check(changed2.count == 1 && changed2[0].id == emittedNodes[0].id && changed2[0].leaves.first?.locked == true,
              "acceptGroup returns reconciled earlier Node so streaming UI overwrites stale unlocked state")

        // 2. 已产出父子路径候选（含跨组场景）：父路径为 L1/L2 整目录 .trash，子路径为 L3 或 locked == true -> 严禁父吞并子，父原地降级只读且扣减子项体积
        let parentDir = base.appendingPathComponent("home/Library/Caches/ParentBundle")
        let protectedSubFile = try file("home/Library/Caches/ParentBundle/SubLocked/data.db", data: Data(repeating: 7, count: 40))
        _ = try file("home/Library/Caches/ParentBundle/other.bin", data: Data(repeating: 1, count: 60))
        var parentCand = ScanItem(url: parentDir, name: "ParentBundle", size: 100, safety: .safe, isSelected: true, locked: false, isRuleEvaluated: true)
        parentCand.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic, reason: .generalCache, defaultSelected: true)
        var childLockedCand = ScanItem(url: protectedSubFile, name: "data.db", size: 40, safety: .caution, isSelected: false, locked: true, isRuleEvaluated: true)
        childLockedCand.ruleEvidence = CleanupRuleEvidence(id: "JC.DEV.XCODE.SIMULATOR", tier: .readOnly, reason: .whitelistProtected, defaultSelected: false)

        let parentChildResult = scanCtx.perform {
            RuleAwareDeduplicator.deduplicate([parentCand, childLockedCand])
        }
        check(parentChildResult.items.count == 2, "Parent candidate cannot swallow stricter locked child candidate")
        let adjudicatedParent = parentChildResult.items.first { $0.url == parentDir }
        let adjudicatedChild = parentChildResult.items.first { $0.url == protectedSubFile }
        check(adjudicatedParent?.locked == true && adjudicatedParent?.isSelected == false,
              "Whole-directory .trash parent is downgraded to read-only locked when descendant is stricter")
        check(adjudicatedChild?.locked == true, "Stricter child candidate remains preserved")
        let combinedSize = parentChildResult.items.reduce(Int64(0)) { $0 + $1.size }
        check(combinedSize == 100, "Total size after parent-child conflict has zero duplicate accumulation")
        check(parentChildResult.records.contains { $0.reason == "parent_locked_due_to_stricter_descendant" },
              "Parent-child conflict records parent_locked_due_to_stricter_descendant")

        // 跨组父先子后：Group A 先产出父目录 (100B)，Group B 后产出更严格子项 (40B) -> Group A 中的父节点原地变为 locked=true 且 size=60B
        var crossParentChildDedup = RuleAwareDeduplicator()
        var pcNodes: [Node] = []
        _ = crossParentChildDedup.acceptGroup(ScanGroup(title: "ParentGroup", icon: "folder", note: "", items: [parentCand]), tags: ["System Junk"], into: &pcNodes)
        _ = crossParentChildDedup.acceptGroup(ScanGroup(title: "ChildGroup", icon: "doc", note: "", items: [childLockedCand]), tags: ["System Junk"], into: &pcNodes)
        check(pcNodes.count == 2, "Cross-group parent-child conflict keeps both groups")
        let reconciledParentLeaf = pcNodes[0].leaves.first
        check(reconciledParentLeaf?.locked == true && reconciledParentLeaf?.autoSelected == false && reconciledParentLeaf?.totalSize == 60,
              "Earlier parent Node is locked and has child size subtracted in-place when stricter child arrives in later group")
        check(pcNodes.reduce(Int64(0)) { $0 + $1.totalSize } == 100,
              "Cross-group parent-child total size is 100 without double counting")

        // 跨组子先父后（同为可清理 .trash）：Group A 先产出可清理子项 (40B)，Group B 后产出可清理父项 (100B) -> 子归并至父，Group A 空节点被移除
        let mergeParentDir = base.appendingPathComponent("home/Library/Caches/MergeParent")
        let mergeChildFile = try file("home/Library/Caches/MergeParent/sub/cache.dat", data: Data(repeating: 2, count: 40))
        var cleanChildCand = ScanItem(url: mergeChildFile, name: "cache.dat", size: 40, safety: .safe, isSelected: true, locked: false, isRuleEvaluated: true)
        cleanChildCand.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic, reason: .generalCache, defaultSelected: true)
        var cleanParentCand = ScanItem(url: mergeParentDir, name: "MergeParent", size: 100, safety: .caution, isSelected: false, locked: false, isRuleEvaluated: true)
        cleanParentCand.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .review, reason: .generalCache, defaultSelected: false)
        var mergeDedup = RuleAwareDeduplicator()
        var mergeNodes: [Node] = []
        _ = mergeDedup.acceptGroup(ScanGroup(title: "EarlyChildGroup", icon: "doc", note: "", items: [cleanChildCand]), tags: ["System Junk"], into: &mergeNodes)
        check(mergeNodes.count == 1, "Early cleanable child group emitted")
        let mergeStreamChanges = mergeDedup.acceptGroup(ScanGroup(title: "LateParentGroup", icon: "folder", note: "", items: [cleanParentCand]), tags: ["System Junk"], into: &mergeNodes)
        check(mergeNodes.count == 1 && mergeNodes[0].name == "LateParentGroup" && mergeNodes[0].totalSize == 100,
              "Earlier cleanable child is merged into later cleanable parent and empty child group is removed")
        let hasEmptiedEarlyGroup = mergeStreamChanges.contains { node in
            node.name == "EarlyChildGroup" && node.totalSize == 0 && node.leafCount == 0
        }
        check(hasEmptiedEarlyGroup,
              "Stream changes include emptied earlier group so AppState removes it from live UI roots")

        // 2e. 二级嵌套分组（toolItem -> trash_children_only subItem -> leaf）与后续扫描组发生同路径/父子重叠去重
        let nestedContainerURL = base.appendingPathComponent("home/Library/Caches/P9NestedTool/SubContainer")
        let nestedLeaf1URL = try file("home/Library/Caches/P9NestedTool/SubContainer/leaf1.dat", data: Data(repeating: 1, count: 32))
        let nestedLeaf2URL = try file("home/Library/Caches/P9NestedTool/SubContainer/leaf2.dat", data: Data(repeating: 2, count: 48))
        var leaf1Item = ScanItem(url: nestedLeaf1URL, name: "leaf1.dat", size: 32, safety: .safe, isSelected: true, isRuleEvaluated: true)
        leaf1Item.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic, reason: .generalCache, defaultSelected: true, containerPath: nestedContainerURL.standardizedFileURL.path)
        var leaf2Item = ScanItem(url: nestedLeaf2URL, name: "leaf2.dat", size: 48, safety: .safe, isSelected: true, isRuleEvaluated: true)
        leaf2Item.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic, reason: .generalCache, defaultSelected: true, containerPath: nestedContainerURL.standardizedFileURL.path)
        var subContainerItem = ScanItem(url: nestedContainerURL, name: "SubContainer", size: 80, safety: .safe, isSelected: true, isRuleEvaluated: true)
        subContainerItem.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic, reason: .generalCache, defaultSelected: true)
        subContainerItem.children = [leaf1Item, leaf2Item]
        var topWrapperItem = ScanItem(url: nestedContainerURL.deletingLastPathComponent(), name: "P9NestedTool", size: 80, safety: .safe, isSelected: true, isRuleEvaluated: true)
        topWrapperItem.children = [subContainerItem]

        var stricterLeaf1 = ScanItem(url: nestedLeaf1URL, name: "leaf1.dat", size: 32, safety: .caution, isSelected: false, isRuleEvaluated: true)
        stricterLeaf1.locked = true
        stricterLeaf1.ruleEvidence = CleanupRuleEvidence(id: "JC.AI.IDE.CACHE", tier: .readOnly, reason: .whitelistProtected, defaultSelected: false)

        var nestedDedup = RuleAwareDeduplicator()
        var nestedGroups: [ScanGroup] = []
        _ = nestedDedup.acceptGroup(ScanGroup(title: "NestedToolGroup", icon: "folder", note: "", items: [topWrapperItem]), into: &nestedGroups)
        check(nestedGroups.count == 1 && nestedGroups[0].items[0].children[0].children.count == 2,
              "2-level nested group preserves 2 real leaves on initial accept")
        _ = nestedDedup.acceptGroup(ScanGroup(title: "LaterStricterLeafGroup", icon: "doc", note: "", items: [stricterLeaf1]), into: &nestedGroups)
        check(nestedGroups.count == 1, "Same-path stricter leaf updates 2-level nested group in-place without emitting duplicate group")
        let reconciledGrandchildren = nestedGroups[0].items[0].children[0].children
        let reconciledLeaf1 = reconciledGrandchildren.first { $0.url.standardizedFileURL == nestedLeaf1URL.standardizedFileURL }
        check(reconciledLeaf1?.locked == true && reconciledLeaf1?.isSelected == false && reconciledLeaf1?.ruleEvidence?.tier == .readOnly,
              "Real leaf at depth 2 (item.children[0].children[0]) is updated in-place to L3 read-only")

        // 3. 未单独产出子候选的整目录 .trash 父目录：内部包含命中更具体非 .trash / L3 规则的后代 -> 递归检查拦截并锁定只读
        _ = try file("home/Library/Caches/Firefox/Profiles/test.default/cache2/entry.bin")
        let firefoxParentDir = base.appendingPathComponent("home/Library/Caches/Firefox")
        let evaluatedFirefoxParent = scanCtx.perform {
            JunkRulePolicy.apply(ScanItem(url: firefoxParentDir, name: "Firefox", size: 30, safety: .safe, isSelected: true))
        }
        check(evaluatedFirefoxParent.locked == true && !evaluatedFirefoxParent.isSelected,
              "Unemitted descendant matching more specific trash_children_only rule blocks whole-directory .trash of parent")
        if case .descendantRuleConflict(_, _, let conflictRuleID) = evaluatedFirefoxParent.evaluationReason {
            check(conflictRuleID == "JC.BRW.FIREFOX.CACHE", "Descendant rule conflict records the more specific descendant rule ID")
        } else {
            check(false, "Expected descendantRuleConflict evaluationReason on parent directory")
        }
        check(!scanCtx.deduplicationRecords.isEmpty, "IOScanContext captures DeduplicationRecord entries")

        // 4. [F05] 三层嵌套父/子/孙冲突体积核算：P=100, C=60 (locked), G=40 (locked) -> 独占体积 [40, 20, 40]，总和恒为 100（批量 + 不同到达顺序流式完全一致）
        let nestedRoot = base.appendingPathComponent("home/Library/Caches/P9Nested3Level")
        var itemP = ScanItem(url: nestedRoot, name: "nested", size: 100, safety: .safe, isSelected: true, locked: false, isRuleEvaluated: true)
        itemP.ruleEvidence = CleanupRuleEvidence(id: "JC.LOG.USER", tier: .automatic, reason: .generalCache, defaultSelected: true)
        var itemC = itemP
        itemC.url = nestedRoot.appendingPathComponent("child")
        itemC.name = "child"
        itemC.size = 60
        itemC.locked = true
        var itemG = itemP
        itemG.url = nestedRoot.appendingPathComponent("child/grandchild")
        itemG.name = "grandchild"
        itemG.size = 40
        itemG.locked = true

        for order in [[itemP, itemC, itemG], [itemG, itemC, itemP], [itemC, itemP, itemG]] {
            let batch3 = RuleAwareDeduplicator.deduplicate(order)
            let total3 = batch3.items.reduce(Int64(0)) { $0 + $1.size }
            let sizeP = batch3.items.first { $0.name == "nested" }?.size
            let sizeC = batch3.items.first { $0.name == "child" }?.size
            let sizeG = batch3.items.first { $0.name == "grandchild" }?.size
            check(total3 == 100 && sizeP == 40 && sizeC == 20 && sizeG == 40,
                  "F05: Batch 3-level nested conflict accounting preserves exact 100B union (40 + 20 + 40) across arrival orders")

            var streamDedup3 = RuleAwareDeduplicator()
            var streamNodes3: [Node] = []
            for (idx, item) in order.enumerated() {
                _ = streamDedup3.acceptGroup(ScanGroup(title: "G\(idx)", icon: "folder", note: "", items: [item]), tags: ["System Junk"], into: &streamNodes3)
            }
            let streamTotal3 = streamNodes3.reduce(Int64(0)) { $0 + $1.totalSize }
            check(streamTotal3 == 100,
                  "F05: Streaming 3-level nested conflict accounting preserves exact 100B union across arrival orders")
        }
    }
    func step3ContainerSnapshotAndMeasurement() throws {
        // 0. 保壳目录单次测量验证：扫描发现阶段通过 makeMeasuredCandidate 对 trash_children_only 容器不递归测父目录，展开与规则评估对每个直接子项只测量一次
        let singlePassDir = base.appendingPathComponent("home/Library/Logs/P9SinglePassContainer")
        try? fm.removeItem(at: singlePassDir)
        let spChild1 = try file("home/Library/Logs/P9SinglePassContainer/one.log", data: Data(repeating: 1, count: 24))
        let spChild2 = try file("home/Library/Logs/P9SinglePassContainer/two.log", data: Data(repeating: 2, count: 36))
        var measuredCounts: [String: Int] = [:]
        FileUtil.onMeasureSizeHook = { url in
            measuredCounts[url.standardizedFileURL.path, default: 0] += 1
        }
        defer { FileUtil.onMeasureSizeHook = nil }
        let candidateOpt = JunkRulePolicy.makeMeasuredCandidate(
            url: singlePassDir,
            name: "P9SinglePassContainer",
            note: "",
            safety: .safe,
            minBytes: 0
        )
        check(candidateOpt != nil, "makeMeasuredCandidate creates evaluated candidate for non-empty trash_children_only container")
        check(measuredCounts[singlePassDir.standardizedFileURL.path, default: 0] == 0,
              "makeMeasuredCandidate skips recursive FileUtil.measureSize on trash_children_only parent container")
        let evaluatedSinglePass = JunkRulePolicy.apply(candidateOpt!)
        FileUtil.onMeasureSizeHook = nil
        let expectedChildSum = evaluatedSinglePass.children.reduce(Int64(0)) { $0 + $1.size }
        check(evaluatedSinglePass.children.count == 2 && evaluatedSinglePass.size > 0 && evaluatedSinglePass.size == expectedChildSum,
              "Single-pass container expansion computes total size from direct children")
        check(measuredCounts[singlePassDir.standardizedFileURL.path, default: 0] == 0,
              "Parent container is never recursively measured across discovery and evaluation")
        check(measuredCounts[spChild1.standardizedFileURL.path] == 1 && measuredCounts[spChild2.standardizedFileURL.path] == 1,
              "Each direct child in trash_children_only container is measured exactly once")

        // 1. 空目录处理：preIdentity == postIdentity && children.isEmpty 时返回 0 个候选，不报错、不产生异常锁定项
        let emptyLogDir = base.appendingPathComponent("home/Library/Logs/P9EmptyContainer")
        try fm.createDirectory(at: emptyLogDir, withIntermediateDirectories: true)
        let emptyCtx = IOScanContext(stopped: { false })
        let evaluatedEmpty = emptyCtx.perform {
            JunkRulePolicy.apply(ScanItem(url: emptyLogDir, name: "P9EmptyContainer", size: 0, safety: .safe, isSelected: true))
        }
        check(JunkRulePolicy.isEmptyVerifiedContainer(evaluatedEmpty), "Empty trash_children_only container is recognized as verified empty")
        let dedupedEmpty = emptyCtx.perform {
            RuleAwareDeduplicator.deduplicate([evaluatedEmpty]).items
        }
        check(dedupedEmpty.isEmpty, "RuleAwareDeduplicator drops verified-empty container without creating locked entry")
        check(emptyCtx.issues.isEmpty && !emptyCtx.evaluationReasonCounts.keys.contains {
            if case .containerSnapshotIncomplete = $0 { return true }
            return false
        }, "Empty container records no error or containerSnapshotIncomplete")

        // 2. 枚举期间父目录发生并发变更（preIdentity != postIdentity） -> 丢弃部分结果并原子回退为锁定只读容器
        let mutatingDir = base.appendingPathComponent("home/Library/Logs/P9MutatingContainer")
        _ = try file("home/Library/Logs/P9MutatingContainer/a.log", data: Data(repeating: 1, count: 16))
        _ = try file("home/Library/Logs/P9MutatingContainer/b.log", data: Data(repeating: 2, count: 16))
        let mutCtx = IOScanContext(stopped: { false })
        JunkRulePolicy.onContainerEnumerationHook = { dirURL in
            if dirURL.standardizedFileURL == mutatingDir.standardizedFileURL {
                let injected = dirURL.appendingPathComponent("injected_during_scan.log")
                try? Data([9, 9, 9]).write(to: injected)
            }
        }
        defer { JunkRulePolicy.onContainerEnumerationHook = nil }
        let evaluatedMutating = mutCtx.perform {
            JunkRulePolicy.apply(ScanItem(url: mutatingDir, name: "P9MutatingContainer", size: 32, safety: .safe, isSelected: true))
        }
        JunkRulePolicy.onContainerEnumerationHook = nil
        check(evaluatedMutating.locked == true && !evaluatedMutating.isSelected && evaluatedMutating.children.isEmpty && evaluatedMutating.size == 0,
              "Container mutated during enumeration discards partial children and locks parent container with 0 size")
        check(mutCtx.degradations.contains(.containerMutatedDuringScan),
              "Mutation during enumeration records containerMutatedDuringScan degradation")
        if case .containerSnapshotIncomplete(_, let reason) = evaluatedMutating.evaluationReason {
            check(reason == "container_identity_mutated_during_enumeration", "Mutation during enumeration records container_identity_mutated_during_enumeration")
        } else {
            check(false, "Expected containerSnapshotIncomplete when container mutates during enumeration")
        }
        // [P2-2] 零体积锁定父项在结果树中的保留验证：leafCount == 1，不会被 AppState 会话过滤 ($0.totalSize > 0 || $0.leafCount > 0) 丢弃
        let lockedMutatedNode = Node.item(from: evaluatedMutating)
        let lockedMutatedGroup = Node.group(from: ScanGroup(title: "System Log Files", icon: "doc.text", note: "", items: [evaluatedMutating]))
        check(lockedMutatedNode.totalSize == 0 && lockedMutatedNode.leafCount == 1 && lockedMutatedGroup.leafCount == 1,
              "Zero-size locked container fallback item has leafCount == 1 so parent group leafCount == 1")
        let candidateRoots: [Node] = [lockedMutatedGroup]
        let filteredSessionRoots = candidateRoots.filter { (root: Node) -> Bool in root.totalSize > 0 || root.leafCount > 0 }
        check(filteredSessionRoots.count == 1 && filteredSessionRoots[0].leaves.first?.url == mutatingDir,
              "AppState session root filter retains zero-size locked container parent item for user visibility")

        // 3. 子项体积统计不完整（measureSize.isComplete == false，例如包含无权限子目录） -> 严禁半截子项进入可勾选列表，整容器回退只读锁定
        let unreadableContainer = base.appendingPathComponent("home/Library/Logs/P9UnreadableContainer")
        _ = try file("home/Library/Logs/P9UnreadableContainer/ok.log", data: Data(repeating: 4, count: 32))
        let secretSubdir = base.appendingPathComponent("home/Library/Logs/P9UnreadableContainer/unreadableSub/nested.log")
        _ = try file("home/Library/Logs/P9UnreadableContainer/unreadableSub/nested.log", data: Data(repeating: 5, count: 64))
        let lockedSubdirURL = secretSubdir.deletingLastPathComponent()
        try fm.setAttributes([.posixPermissions: 0o000], ofItemAtPath: lockedSubdirURL.path)
        defer { try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: lockedSubdirURL.path) }
        if getuid() != 0 {
            let subMeasure = FileUtil.measureSize(of: lockedSubdirURL)
            check(!subMeasure.isComplete, "FileUtil.measureSize marks unreadable subdirectory as isComplete == false")
            let unrdCtx = IOScanContext(stopped: { false })
            let evaluatedUnreadable = unrdCtx.perform {
                JunkRulePolicy.apply(ScanItem(url: unreadableContainer, name: "P9UnreadableContainer", size: 96, safety: .safe, isSelected: true))
            }
            check(evaluatedUnreadable.locked == true && !evaluatedUnreadable.isSelected && evaluatedUnreadable.children.isEmpty,
                  "Incomplete child size measurement aborts container expansion and locks container")
            check(unrdCtx.degradations.contains(.containerEnumerationIncomplete),
                  "Incomplete child measurement records containerEnumerationIncomplete degradation")
            if case .containerSnapshotIncomplete(_, let reason) = evaluatedUnreadable.evaluationReason {
                check(reason.hasPrefix("child_size_measurement_incomplete:"), "Incomplete child measurement records child_size_measurement_incomplete")
            } else {
                check(false, "Expected containerSnapshotIncomplete for unreadable child subdirectory")
            }
        }

        // 4. 与执行期 Cleaner.clean 的闭环验证：展开子项携带父容器身份与子项身份，仅删除子项保留父容器壳；整父容器直接清理被拒绝
        let execContainer = base.appendingPathComponent("home/Library/Logs/P9ExecClosure")
        let childLog = try file("home/Library/Logs/P9ExecClosure/session.log", data: Data(repeating: 8, count: 64))
        let evaluatedExec = JunkRulePolicy.apply(ScanItem(url: execContainer, name: "P9ExecClosure", size: 64, safety: .safe, isSelected: true))
        check(evaluatedExec.children.count == 1, "Exec closure container expands 1 child")
        let childItem = evaluatedExec.children[0]
        check(childItem.ruleEvidence?.containerPath == execContainer.standardizedFileURL.path && childItem.ruleEvidence?.containerIdentity != nil && childItem.fileIdentity != nil,
              "Expanded child carries parent containerPath, containerIdentity, and child fileIdentity")
        // 尝试把父容器本体直接交给 Cleaner.clean -> 必须被拦截
        var directContainerTarget = CleanTarget(
            name: "P9ExecClosure",
            url: execContainer,
            size: 64,
            action: .trash,
            locked: false,
            identity: FileIdentity.capture(from: execContainer),
            authorizationContext: .junkRule
        )
        directContainerTarget.ruleEvidence = evaluatedExec.ruleEvidence
        check(!Cleaner.clean(directContainerTarget).ok, "Cleaner rejects direct deletion of trash_children_only container directory")
        check(fm.fileExists(atPath: execContainer.path) && fm.fileExists(atPath: childLog.path), "Container and child remain intact after rejected container deletion")
        // 清理展开后的直接子项 -> 通过父容器身份与子项身份双重校验并进入 movedToTrash
        let childTarget = CleanTarget(Node.item(from: childItem))
        let childOutcome = Cleaner.clean(childTarget)
        check(childOutcome.ok && childOutcome.actionCategory == .movedToTrash && childOutcome.path == childLog.path,
              "Cleaner succeeds on expanded child with matching containerIdentity and fileIdentity")
        // 若父容器身份 (mode/inode/device) 在扫描后发生篡改 -> Cleaner.clean 必须拦截子项清理
        var tamperedContainerTarget = childTarget
        var tamperedEvidence = childItem.ruleEvidence!
        var fakeContainerIdentity = tamperedEvidence.containerIdentity!
        fakeContainerIdentity.inode &+= 999_999
        tamperedEvidence.containerIdentity = fakeContainerIdentity
        tamperedContainerTarget.ruleEvidence = tamperedEvidence
        check(!Cleaner.clean(tamperedContainerTarget).ok,
              "Cleaner rejects expanded child when parent containerIdentity no longer matches")
    }
    func step4OpenFileScopeAndUID() throws {
        // 1. FileIdentity.uid 捕获与变更拦截验证
        let uidFile = try file("home/Library/Logs/P9UID/app.log", data: Data([1, 2, 3, 4]))
        let capturedIdentity = FileIdentity.capture(from: uidFile)
        check(capturedIdentity?.uid == getuid(), "FileIdentity.capture captures current process uid")
        var tamperedUIDIdentity = capturedIdentity!
        tamperedUIDIdentity.uid = getuid() &+ 1
        check(!tamperedUIDIdentity.matches(url: uidFile), "FileIdentity.matches fails when uid changes")

        // 2. OpenFileGuard 范围边界显式声明与规范化路径组件校验
        check(OpenFileGuard.checkScope == .currentUserOnly, "OpenFileGuard explicitly declares .currentUserOnly scope")
        check(OpenFileGuard.isCurrentUserVerifiableScope(uidFile, identity: capturedIdentity),
              "Current user file outside system shared roots is verifiable by current-user lsof")
        check(!OpenFileGuard.isCurrentUserVerifiableScope(uidFile, identity: tamperedUIDIdentity),
              "File owned by non-current UID is never verifiable by current-user lsof")

        for sysPath in ["/Library/Caches/com.example.daemon",
                        "/Library/Logs/DiagnosticReports/crash.ips",
                        "/System/Library/Caches/com.apple.kernel",
                        "/private/var/log/system.log",
                        "/var/log/system.log",
                        "/Users/other_account_xyz/Library/Caches/app",
                        "/Users/Shared/shared_cache.bin"] {
            let sysURL = URL(fileURLWithPath: sysPath)
            check(OpenFileGuard.isSystemSharedScopePath(sysURL), "System or cross-user path recognized as system shared scope: " + sysPath)
            check(!OpenFileGuard.isCurrentUserVerifiableScope(sysURL, identity: capturedIdentity),
                  "System or cross-user path is barred from current-user lsof verification: " + sysPath)
        }
        let currentHomeCache = FileUtil.home.appendingPathComponent("Library/Caches/com.cleanmate.test")
        check(!OpenFileGuard.isSystemSharedScopePath(currentHomeCache), "Current user's ~/Library/Caches is not a system shared scope path")
        check(OpenFileGuard.isCurrentUserVerifiableScope(currentHomeCache, identity: capturedIdentity),
              "Current user's ~/Library/Caches with matching UID is in current-user verifiable scope")

        // 3. 软链指向系统域（如指向 /var/log 或 /Library/Logs）时，通过 resolvingSymlinksInPath + canonicalizeMacOSSystemPrefix 依然识别为系统域
        let symlinkToVar = base.appendingPathComponent("home/Library/Logs/P9UID/var_alias")
        try? fm.removeItem(at: symlinkToVar)
        try fm.createSymbolicLink(at: symlinkToVar, withDestinationURL: URL(fileURLWithPath: "/var/log"))
        defer { try? fm.removeItem(at: symlinkToVar) }
        check(!OpenFileGuard.isCurrentUserVerifiableScope(symlinkToVar, identity: capturedIdentity),
              "Symlink alias resolving to /var/log (/private/var/log) is rejected by canonical scope check")

        // 4. 非当前 UID 或系统范围候选进入 JunkRulePolicy.apply 时，禁止授予 L1 自动推荐，强制锁定只读并记录 systemScopeHandleBlindSpot
        var foreignUIDScan = ScanItem(url: uidFile, name: "app.log", size: 4, safety: .safe, isSelected: true, fileIdentity: tamperedUIDIdentity)
        foreignUIDScan = JunkRulePolicy.apply(foreignUIDScan)
        check(foreignUIDScan.locked == true && !foreignUIDScan.isSelected && foreignUIDScan.ruleEvidence?.tier == .readOnly,
              "Non-current UID log candidate is downgraded to L3 read-only and never auto-selected")
        check(!CleanupSelectionPolicy.isRecommended(Node.item(from: foreignUIDScan)),
              "CleanupSelectionPolicy refuses recommendation for non-current UID candidate")
        if case .systemScopeHandleBlindSpot(let recordedPath) = foreignUIDScan.evaluationReason {
            check(recordedPath == OpenFileGuard.canonicalScopeURL(uidFile).path, "Evaluation reason records systemScopeHandleBlindSpot with canonical path")
        } else {
            check(false, "Expected systemScopeHandleBlindSpot evaluation reason for foreign UID candidate")
        }

        // 执行期 Cleaner.clean 对 UID 篡改的拦截
        let validLogScan = JunkRulePolicy.apply(ScanItem(url: uidFile, name: "app.log", size: 4, safety: .safe, isSelected: true))
        var uidMismatchTarget = CleanTarget(Node.item(from: validLogScan))
        uidMismatchTarget.expectedIdentity = tamperedUIDIdentity
        check(!Cleaner.clean(uidMismatchTarget).ok, "Cleaner.clean rejects execution when FileIdentity.uid does not match current file uid")

        // 5. [P1] 目录删除的句柄证明范围：当前用户拥有的目录内若包含其他 UID 的后代文件，OpenFileGuard、CleanupSafetyPolicy、JunkRulePolicy 与 Cleaner.clean 必须全部拒绝
        let foreignDescDir = base.appendingPathComponent("home/Library/Caches/P9ForeignDescendantDir")
        _ = try file("home/Library/Caches/P9ForeignDescendantDir/owned.bin", data: Data([1, 2, 3]))
        let foreignDescFile = try file("home/Library/Caches/P9ForeignDescendantDir/nested/foreign.bin", data: Data([4, 5, 6]))
        let foreignDescStandardized = foreignDescFile.standardizedFileURL.path
        FileIdentity.uidOverrideForTesting = { url in
            url.standardizedFileURL.path == foreignDescStandardized ? (getuid() &+ 1) : nil
        }
        defer { FileIdentity.uidOverrideForTesting = nil }

        let dirIdentity = FileIdentity.capture(from: foreignDescDir)
        check(dirIdentity?.uid == getuid(), "Parent directory itself is owned by current UID")
        check(!OpenFileGuard.isCurrentUserVerifiableScope(foreignDescDir, identity: dirIdentity),
              "OpenFileGuard.isCurrentUserVerifiableScope rejects current-UID directory containing foreign-UID descendant")
        check(!OpenFileGuard.isIdle(foreignDescDir, fresh: true),
              "OpenFileGuard.isIdle refuses to prove idle for directory containing foreign-UID descendant")
        let dirDisposition = CleanupSafetyPolicy.inspectDirectory(foreignDescDir)
        check(!dirDisposition.isSafe && dirDisposition.evaluationReason == .systemScopeHandleBlindSpot(path: OpenFileGuard.canonicalScopeURL(foreignDescFile).path),
              "CleanupSafetyPolicy.inspectDirectory detects foreign-UID descendant and reports systemScopeHandleBlindSpot")
        let evaluatedForeignDescDir = JunkRulePolicy.apply(
            ScanItem(url: foreignDescDir, name: "P9ForeignDescendantDir", size: 6, safety: .safe, isSelected: true)
        )
        check(evaluatedForeignDescDir.locked == true && !evaluatedForeignDescDir.isSelected,
              "JunkRulePolicy.apply locks directory containing foreign-UID descendant")
        var forgedDirTarget = CleanTarget(
            name: "P9ForeignDescendantDir",
            url: foreignDescDir,
            size: 6,
            action: .trash,
            locked: false,
            identity: dirIdentity,
            authorizationContext: .junkRule
        )
        forgedDirTarget.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic, reason: .generalCache, defaultSelected: true)
        let forgedDirOutcome = Cleaner.clean(forgedDirTarget)
        check(!forgedDirOutcome.ok && forgedDirOutcome.actionCategory == .skipped,
              "Cleaner.clean refuses to delete directory containing foreign-UID descendant")
        check(fm.fileExists(atPath: foreignDescFile.path), "Directory with foreign-UID descendant remains untouched on disk")
        FileIdentity.uidOverrideForTesting = nil

        // 6. [F13] CleanupSelectionPolicy.isRecommended 在主线程消费扫描证据时触发 0 次后代递归 lstat
        let selectorDir = try file("home/Documents/P9SelectorDir/child.bin").deletingLastPathComponent()
        let selectorIdentity = FileIdentity.capture(from: selectorDir)
        var selectorNode = Node(name: "selector", url: selectorDir, safety: .safe, size: 4096, autoSelected: true, fileIdentity: selectorIdentity)
        selectorNode.ruleEvidence = CleanupRuleEvidence(id: "JC.LOG.USER", tier: .automatic, reason: .generalCache, defaultSelected: true)
        var descendantCaptures = 0
        FileIdentity.uidOverrideForTesting = { url in
            if FileUtil.isStrictDescendant(url, of: selectorDir) {
                descendantCaptures += 1
            }
            return nil
        }
        let isRec = CleanupSelectionPolicy.isRecommended(selectorNode)
        FileIdentity.uidOverrideForTesting = nil
        check(isRec && descendantCaptures == 0,
              "F13: CleanupSelectionPolicy.isRecommended performs 0 descendant FileIdentity captures on main thread")

        // 7. [F14] 非 .junkRule 模块 (.organizeManual / .uninstall) 显式授权目标支持跨 UID 清理（不混用垃圾 L1 当前用户假设）
        let foreignManualFile = try file("home/Documents/P9ForeignManual.bin", data: Data([1, 2, 3, 4]))
        let foreignAppRoot = base.appendingPathComponent("home/Applications/P9ForeignApp.app")
        let foreignAppPlist: [String: Any] = ["CFBundleIdentifier": "org.cleanmate.p9.foreignapp", "CFBundleName": "P9ForeignApp"]
        _ = try file("home/Applications/P9ForeignApp.app/Contents/Info.plist", data: PropertyListSerialization.data(fromPropertyList: foreignAppPlist, format: .xml, options: 0))

        FileIdentity.uidOverrideForTesting = { url in
            if url.standardizedFileURL == foreignManualFile.standardizedFileURL || url.standardizedFileURL == foreignAppRoot.standardizedFileURL {
                return getuid() &+ 1
            }
            return nil
        }
        let foreignManualNode = Node(name: "P9ForeignManual.bin", url: foreignManualFile, safety: .caution, action: .trash, size: 4, autoSelected: false, authorizationContext: .organizeManual)
        let foreignManualOutcome = Cleaner.clean(CleanTarget(foreignManualNode))
        check(foreignManualOutcome.ok && foreignManualOutcome.actionCategory == .movedToTrash,
              "F14: .organizeManual target with foreign UID succeeds in Cleaner.clean when identity matches")

        let foreignAppNode = Node(name: "P9ForeignApp.app", url: foreignAppRoot, safety: .caution, action: .trash, size: 64, autoSelected: false, authorizationContext: .uninstall)
        var foreignAppTarget = CleanTarget(foreignAppNode)
        foreignAppTarget.uninstallContext = UninstallContext(appURL: foreignAppRoot, bundleID: "org.cleanmate.p9.foreignapp", isAppBody: true)
        let foreignAppOutcome = Cleaner.clean(foreignAppTarget)
        check(foreignAppOutcome.ok && foreignAppOutcome.actionCategory == .movedToTrash,
              "F14: .uninstall app body target with foreign UID succeeds in Cleaner.clean when bundleID and identity match")
        FileIdentity.uidOverrideForTesting = nil
    }
    func discoveryAndLocks() throws {
        let store = KnowledgeBaseManager.shared.authored
        for name in ["CachedData", "CachedExtensionVSIXs", "logs", "Crashpad/completed"] {
            let url = try file("home/Library/Application Support/P9Cursor/" + name + "/scan.bin", data: Data(repeating: 3, count: 250_000)).deletingLastPathComponent()
            check(store.cacheDirectories(ruleID: AppConfig.RuleIDs.aiIDECache).contains(url), "authored discovery includes " + name)
            check(JunkEngine.scanElectronCaches()?.items.contains { $0.url == url } == true, "production scanner discovers " + name)
        }
        // F08 & F06: 验证 Firefox profile cache2/startupCache、Chromium profile GPUCache 与 ~/.npm/_logs 的真实扫描器深度发现
        let ffCache2Dir = try file("home/Library/Caches/Firefox/Profiles/p9.default-release/cache2/entries/chunk.bin", data: Data(repeating: 2, count: 250_000)).deletingLastPathComponent().deletingLastPathComponent()
        let ffStartupDir = try file("home/Library/Caches/Firefox/Profiles/p9.default-release/startupCache/startup.bin", data: Data(repeating: 2, count: 250_000)).deletingLastPathComponent()
        let chromeProfileGPU = try file("home/Library/Application Support/Google/Chrome/Profile 2/GPUCache/gpu.bin", data: Data(repeating: 2, count: 250_000)).deletingLastPathComponent()
        check(store.cacheDirectories(ruleID: AppConfig.RuleIDs.firefoxCache).contains(ffCache2Dir)
              && store.cacheDirectories(ruleID: AppConfig.RuleIDs.firefoxCache).contains(ffStartupDir),
              "F08: cacheDirectories(ruleID: JC.BRW.FIREFOX.CACHE) discovers Profiles/*/cache2 and startupCache")
        check(store.cacheDirectories(ruleID: AppConfig.RuleIDs.chromiumCache).contains(chromeProfileGPU),
              "F08: cacheDirectories(ruleID: JC.BRW.CHROMIUM.CACHE) discovers profile-scoped GPUCache")
        let browserScanGroup = JunkEngine.scanBrowserCaches(minBytes: 0)
        let browserDiscoveredURLs = Set((browserScanGroup?.items ?? []).map { $0.url.standardizedFileURL })
        check(browserDiscoveredURLs.contains(ffCache2Dir.standardizedFileURL)
              && browserDiscoveredURLs.contains(ffStartupDir.standardizedFileURL)
              && browserDiscoveredURLs.contains(chromeProfileGPU.standardizedFileURL),
              "F08: JunkEngine.scanBrowserCaches discovers Firefox profile cache2/startupCache and Chromium profile GPUCache end-to-end")

        let npmLogFile = try file("home/.npm/_logs/2026-10-18_debug-0.log", data: Data(repeating: 1, count: 1024))
        let npmLogsDir = npmLogFile.deletingLastPathComponent()
        let pkgScanGroup = JunkEngine.scanPackageManagerCaches()
        let discoveredNpmLogs = pkgScanGroup?.items.first { $0.url.standardizedFileURL == npmLogsDir.standardizedFileURL }
        check(discoveredNpmLogs != nil && discoveredNpmLogs?.children.contains(where: { $0.url.standardizedFileURL == npmLogFile.standardizedFileURL }) == true,
              "F08: JunkEngine.scanPackageManagerCaches discovers ~/.npm/_logs container and expands log child under JC.DEV.NPM.LOGS")

        // 16 个开源项目共识规则与四层白名单验证
        let nodeGypDir = try file("home/Library/Caches/node-gyp/20.0.0/include/node.h").deletingLastPathComponent().deletingLastPathComponent()
        check(store.evidence(for: nodeGypDir)?.id == "JC.DEV.PKG.SAFE" && store.evidence(for: nodeGypDir)?.tier == .review,
              "16-project alignment: node-gyp cache matches JC.DEV.PKG.SAFE as L2 review")
        let adbKeyURL = base.appendingPathComponent("home/.android/adbkey")
        check(CleanupSafetyPolicy.isProtectedAsset(adbKeyURL) && JunkEngine.isIgnoredPath(adbKeyURL.path),
              "16-project whitelist: ~/.android/adbkey is protected against cleanup")
        let imeURL = base.appendingPathComponent("home/Library/Input Methods/Squirrel.app")
        check(JunkEngine.isIgnoredPath(imeURL.path),
              "16-project whitelist: Input Methods directory is protected against cleanup")
        check(JunkEngine.isIgnoredBundleID("com.apple.SystemSettings") && JunkEngine.isIgnoredBundleID("com.apple.Spotlight"),
              "16-project whitelist: SystemSettings and Spotlight bundle IDs are protected")

        let unknown = try file("home/Library/Application Support/UnknownProduct/Cache/data.bin").deletingLastPathComponent()
        check(store.cacheSubdirTier(unknown, ruleID: AppConfig.RuleIDs.electronCache) == nil, "generic support glob cannot authorize unknown product")
        let code = base.appendingPathComponent("home/Library/Application Support/Code/Cache")
        let rule = store.junk[AppConfig.RuleIDs.electronCache]!
        check(store.hasRunningAppLock(for: code, rule: rule, isRunning: { $0 == "com.microsoft.VSCode" }), "Code directory resolves the VS Code identity lock")
        check(!store.hasRunningAppLock(for: code, rule: rule, isRunning: { _ in false }), "closed mapped app does not block discovery")
        let root = try file("home/Library/Logs/P9Scope/ordinary.log").deletingLastPathComponent()
        _ = try file("home/Library/Logs/P9Scope/nested/credentials")
        let item = JunkRulePolicy.apply(ScanItem(url: root, name: "logs", size: 6, safety: .safe))
        check(item.children.allSatisfy { !$0.isSelected || CleanupSafetyPolicy.inspect($0.url).isSafe }, "log snapshot cannot default select protected descendants")
    }
    func presentation() throws {
        let dir = base.appendingPathComponent("home/Library/Application Support/P9Cursor/GPUCache")
        try? fm.removeItem(at: dir)
        for index in 0..<300 { _ = try file("home/Library/Application Support/P9Cursor/GPUCache/f_\(index)") }
        let scanned = JunkRulePolicy.apply(ScanItem(url: dir, name: "Cursor GPU cache", size: 900, safety: .safe, isSelected: true))
        let node = Node.item(from: scanned)
        check(node.leaves.count == 300, "all captured children remain execution targets")
        check(CleanupPresentation.rows(node).count == 1 && CleanupPresentation.rows(node)[0].name == "Cursor GPU cache", "300 children project to one named directory row")
        check(Set(node.leaves.compactMap { $0.ruleEvidence?.containerIdentity?.inode }).count == 1, "per-child container identity preserved")
        _ = try file("home/Library/Application Support/P9Cursor/GPUCache/new-after-scan")
        check(node.leaves.count == 300, "projection never discovers new execution children")
        let state = AppState();state.moduleKey = "junk";state.roots = [node]
        state.setSelection(node, true)
        check(state.selection == Set(node.leaves.map(\.id)), "select row selects captured UUIDs only")
        state.selection.remove(node.leaves[0].id)
        check(state.partial(node) && state.selectedCount(in: node) == 299 && state.selectedSize(in: node) == 299 * node.leaves[0].totalSize, "mixed selection counts captured children")
        state.setSelection(node, false)
        check(state.selection.isEmpty, "directory deselection clears all children")
        var mixed = node; mixed.children[0].locked = true
        state.setSelection(mixed, true)
        check(state.selection.count == 299 && !state.selection.contains(mixed.children[0].id), "locked child excluded from group selection")

        // 验收项 1：子项锁定/限制/规则变化或版本变化时，快照签名与分组缓存必须立即失效（绝不命中旧缓存）
        let snapBeforeLock = MainActor.assumeIsolated {
            SmartCleanSnapshotCache.shared.snapshot(for: [node])
        }
        check(snapBeforeLock.cleanableLeaves.count == 300, "snapshot before child lock has 300 selectable leaves")
        let cacheMissOnLockedChild = MainActor.assumeIsolated {
            SmartCleanSnapshotCache.shared.cachedSnapshot(for: [mixed]) == nil
        }
        check(cacheMissOnLockedChild, "child lock invalidates cachedSnapshot even when root id/size/childCount are unchanged")
        let snapAfterLock = MainActor.assumeIsolated {
            SmartCleanSnapshotCache.shared.snapshot(for: [mixed])
        }
        check(snapAfterLock.cleanableLeaves.count == 299 && !snapAfterLock.profileSelections[.maxSpace, default: []].contains(mixed.children[0].id),
              "recomputed snapshot excludes newly locked child from cleanableLeaves and profileSelections")
        check(snapBeforeLock.sections.first?.cacheIdentityKey != snapAfterLock.sections.first?.cacheIdentityKey,
              "section cacheIdentityKey invalidates when descendant leaf lock state changes")

        // 验收项 3：模式选择边界（拒绝 unknownImpact、拒绝缺失或不可执行 ruleEvidence、保留安全门禁）
        var devReviewLeaf = node.leaves[1]
        devReviewLeaf.cacheRecommendation = nil // isolate authored profile expansion from cache-cost restrictions
        devReviewLeaf.autoSelected = false
        devReviewLeaf.safety = .caution
        devReviewLeaf.selectionRestrictions = [.productPolicy]
        devReviewLeaf.ruleEvidence = CleanupRuleEvidence(id: "JC.DEV.XCODE.DERIVED.LIVE", tier: .review, reason: .generalCache, defaultSelected: false)
        check(!CleanupSelectionPolicy.isSelected(node: devReviewLeaf, in: .safeDaily)
              && CleanupSelectionPolicy.isSelected(node: devReviewLeaf, in: .devPro)
              && CleanupSelectionPolicy.isSelected(node: devReviewLeaf, in: .maxSpace),
              "dev review item with productPolicy and executable evidence is selected in devPro and maxSpace only")

        var devUnknownImpactLeaf = devReviewLeaf
        devUnknownImpactLeaf.selectionRestrictions = [.unknownImpact]
        check(!CleanupSelectionPolicy.isSelected(node: devUnknownImpactLeaf, in: .safeDaily)
              && !CleanupSelectionPolicy.isSelected(node: devUnknownImpactLeaf, in: .devPro)
              && !CleanupSelectionPolicy.isSelected(node: devUnknownImpactLeaf, in: .maxSpace),
              "dev item with unknownImpact restriction is rejected in all profiles")

        var missingEvidenceLeaf = devReviewLeaf
        missingEvidenceLeaf.ruleEvidence = nil
        check(!CleanupSelectionPolicy.isSelected(node: missingEvidenceLeaf, in: .safeDaily)
              && !CleanupSelectionPolicy.isSelected(node: missingEvidenceLeaf, in: .devPro)
              && !CleanupSelectionPolicy.isSelected(node: missingEvidenceLeaf, in: .maxSpace),
              "node without ruleEvidence is rejected in all profiles including maxSpace")

        var largeAppCacheLeaf = node.leaves[2]
        largeAppCacheLeaf.url = base.appendingPathComponent("home/Library/Caches/org.cleanmate.p9.demoapp")
        largeAppCacheLeaf.name = "DemoApp Cache"
        largeAppCacheLeaf.autoSelected = false
        largeAppCacheLeaf.safety = .caution
        largeAppCacheLeaf.cacheRecommendation = nil
        largeAppCacheLeaf.selectionRestrictions = [.largeCache]
        largeAppCacheLeaf.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .review, reason: .generalCache, defaultSelected: false)
        check(!CleanupSelectionPolicy.isSelected(node: largeAppCacheLeaf, in: .safeDaily)
              && !CleanupSelectionPolicy.isSelected(node: largeAppCacheLeaf, in: .devPro)
              && CleanupSelectionPolicy.isSelected(node: largeAppCacheLeaf, in: .maxSpace),
              "large non-dev cache with executable evidence is selected in maxSpace only")

        // 验证多选方案独立桶逻辑 (Multi-select profile orthogonality)
        check(CleanupSelectionPolicy.isSelected(node: devReviewLeaf, in: [.devPro])
              && !CleanupSelectionPolicy.isSelected(node: devReviewLeaf, in: [.safeDaily])
              && !CleanupSelectionPolicy.isSelected(node: devReviewLeaf, in: [.maxSpace])
              && CleanupSelectionPolicy.isSelected(node: devReviewLeaf, in: [.safeDaily, .devPro]),
              "dev review leaf matches only profiles containing devPro")

        check(CleanupSelectionPolicy.isSelected(node: largeAppCacheLeaf, in: [.maxSpace])
              && !CleanupSelectionPolicy.isSelected(node: largeAppCacheLeaf, in: [.safeDaily])
              && !CleanupSelectionPolicy.isSelected(node: largeAppCacheLeaf, in: [.devPro])
              && CleanupSelectionPolicy.isSelected(node: largeAppCacheLeaf, in: [.safeDaily, .maxSpace]),
              "large app cache leaf matches only profiles containing maxSpace")

        // 验收项 2：测量冷缓存构建、热缓存切页命中与模式切换耗时
        let coldStart = ProcessInfo.processInfo.systemUptime
        let coldSnap = SmartCleanSnapshotCache.computeSnapshot(roots: [node], resultVersion: 99)
        let coldMs = (ProcessInfo.processInfo.systemUptime - coldStart) * 1000.0
        MainActor.assumeIsolated {
            SmartCleanSnapshotCache.shared.storePrecomputedSnapshot(coldSnap)
        }
        let warmStart = ProcessInfo.processInfo.systemUptime
        let warmHit = MainActor.assumeIsolated {
            SmartCleanSnapshotCache.shared.cachedSnapshot(for: [node], resultVersion: 99)
        }
        let warmMs = (ProcessInfo.processInfo.systemUptime - warmStart) * 1000.0
        check(warmHit != nil && warmMs < 15.0, "warm tab-switch snapshot lookup completes in under 15ms")
        print(String(format: "JUNK_SWITCH_BENCHMARK {\"cold_compute_ms\":%.3f,\"warm_tab_hit_ms\":%.3f}", coldMs, warmMs))

        // 首次安装引导 (Onboarding) 与快捷授权状态机测试
        let defaults = UserDefaults.standard
        let prevCompleted = defaults.object(forKey: AppConfig.StorageKeys.onboardingCompleted)
        let prevAwaiting = defaults.object(forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch)
        defer {
            if let v = prevCompleted { defaults.set(v, forKey: AppConfig.StorageKeys.onboardingCompleted) }
            else { defaults.removeObject(forKey: AppConfig.StorageKeys.onboardingCompleted) }
            if let v = prevAwaiting { defaults.set(v, forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch) }
            else { defaults.removeObject(forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch) }
        }

        defaults.set(false, forKey: AppConfig.StorageKeys.onboardingCompleted)
        defaults.set(false, forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch)
        let onboardingState = AppState { _ in nil }
        check(onboardingState.showOnboarding == true, "AppState shows onboarding on fresh install when onboardingCompleted is false")

        onboardingState.completeOnboarding(startFirstScan: false)
        check(onboardingState.showOnboarding == false
              && defaults.bool(forKey: AppConfig.StorageKeys.onboardingCompleted) == true
              && defaults.bool(forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch) == false,
              "completeOnboarding persists onboardingCompleted and clears awaitingFdaRelaunch flag")

        onboardingState.presentOnboarding()
        check(onboardingState.showOnboarding == true, "presentOnboarding reopens onboarding guide from Settings")
        onboardingState.completeOnboarding(startFirstScan: false)

        // 校验新增 10 国语言引导词条无缺失
        let onboardingKeys: [L10nKey] = [
            .onboardingWelcomeTitle, .onboardingWelcomeSubtitle, .onboardingSafetyContractBadge,
            .onboardingPermissionStepTitle, .onboardingPermissionGrantedTitle,
            .onboardingDragAppToListHint, .onboardingActionStartFirstScan,
            .sidebarQuickGrantFdaTitle, .sidebarQuickGrantFdaSubtitle, .actionDirectOpenFdaSettings
        ]
        for key in onboardingKeys {
            let text = L10n.localized(key)
            check(!text.isEmpty && text != key.rawValue, "L10n key \(key.rawValue) is localized")
        }

        // 验收项 4：方案与多选状态所有权（Single Source of Truth 在 AppState，手动勾选自动退回自定义微调）
        let profileState = AppState(); profileState.moduleKey = "junk"; profileState.roots = [node]
        profileState.setCleaningProfile(.safeDaily)
        check(profileState.cleaningProfile == .safeDaily && profileState.selectedProfiles == [.safeDaily],
              "AppState publishes one consistent profile state")

        profileState.setCleaningProfile(.maxSpace, selectedProfiles: [.safeDaily, .devPro, .maxSpace])
        check(profileState.cleaningProfile == .maxSpace && profileState.selectedProfiles == [.safeDaily, .devPro, .maxSpace],
              "multi-select profile updates the module state correctly")

        // 手动勾选叶子节点，必须驱动状态退回 custom 并清空多选集合
        profileState.toggle(node.leaves[0])
        check(profileState.cleaningProfile == .custom && profileState.selectedProfiles.isEmpty,
              "manual leaf toggle resets the module to custom with empty selectedProfiles")

        // 模块切页保持会话状态
        profileState.setCleaningProfile(.devPro, selectedProfiles: [.devPro])
        profileState.open(.restore(.spaceLens))
        check(profileState.moduleKey == .spaceLens, "switched to spaceLens")
        profileState.open(.restore(.junk))
        check(profileState.cleaningProfile == .devPro && profileState.selectedProfiles == [.devPro],
              "module session switch roundtrips cleaningProfile and selectedProfiles")
    }
}
