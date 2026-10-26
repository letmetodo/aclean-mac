import Foundation
import SQLite3

@MainActor
struct P9RuleUpdateIntegrationTests {
    func runAll() throws {
        let fm = FileManager.default
        let base = URL(fileURLWithPath: "/private/tmp/cleanmate-ota-integration-" + UUID().uuidString)
        let published = URL(fileURLWithPath: ProcessInfo.processInfo.environment["ACLEAN_RULES_DB"]!)
        let database = base.appendingPathComponent("rules.db")
        let home = base.appendingPathComponent("home")
        try fm.createDirectory(at: home, withIntermediateDirectories: true)
        try fm.copyItem(at: published, to: database)
        let oldHome = FileUtil.homeOverrideForTesting
        defer {
            FileUtil.homeOverrideForTesting = oldHome
            try? KnowledgeBaseManager.shared.load(from: published)
            try? fm.removeItem(at: base)
        }
        FileUtil.homeOverrideForTesting = home
        func sql(_ statement: String) throws {
            var handle: OpaquePointer?
            guard sqlite3_open(database.path, &handle) == SQLITE_OK else { throw RuleUpdateFailure.invalidDatabase }
            defer { sqlite3_close(handle) }
            guard sqlite3_exec(handle, statement, nil, nil, nil) == SQLITE_OK else { throw RuleUpdateFailure.invalidDatabase }
        }
        try sql("""
        INSERT INTO cm_junk_rule(id,section,tier,action,status,default_selected,min_bytes,rebuild_cost,predicate,reason_code,title_key,fixture_required)
        VALUES('JC.OTA.TEST','developer','L2','trash','active',0,0,'low','','REASON_CODE_MANUAL_REVIEW','ota_test',0);
        INSERT INTO cm_discovery_binding(rule_id,path_template,path_kind,scanner_id,discovery_kind,status)
        VALUES('JC.OTA.TEST','~/Library/Caches/OTAExampleCache','root','scanDeveloperCaches','fixed_path','active');
        UPDATE cm_rule_meta SET value='2' WHERE key='rule_version';
        """)
        let safety = try Data(contentsOf: published.deletingLastPathComponent().appendingPathComponent("rule_safety.json"))
        _ = try RuleDatabaseValidator.validate(at: database, policyData: safety, limits: RuleUpdateConfiguration.limits)
        let root = home.appendingPathComponent("Library/Caches/OTAExampleCache")
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 4096).write(to: root.appendingPathComponent("cache.bin"))
        // Keep raw keys distinct even when two rows share the same canonical alias.
        let rawTemplate = "~/Library/Caches/OTAExampleCache"
        let absoluteTemplate = root.path
        let quotedAbsolute = absoluteTemplate.replacingOccurrences(of: "'", with: "''")
        try sql("INSERT INTO cm_discovery_binding VALUES('JC.OTA.TEST','\(quotedAbsolute)','root','scanDeveloperCaches','fixed_path','deferred');")
        do {
            let connection = try RuleDatabase(url: database, limits: RuleUpdateConfiguration.limits)
            let catalog = try RuleCatalog(database: connection.handle)
            precondition(catalog.binding(ruleID: "JC.OTA.TEST", path: rawTemplate)?.pathTemplate == rawTemplate,
                         "OTA: canonical aliases cannot overwrite a raw template")
            let otherHome = base.appendingPathComponent("second-home")
            FileUtil.homeOverrideForTesting = otherHome
            defer { FileUtil.homeOverrideForTesting = home }
            precondition(catalog.binding(ruleID: "JC.OTA.TEST", path: absoluteTemplate)?.pathTemplate == absoluteTemplate,
                         "OTA: raw lookup survives a Home change after index construction")
            let newRoot = otherHome.path.lowercased() + "/library/caches"
            precondition(AppConfig.Paths.topLevelContainers.contains(newRoot)
                         && KnowledgeBaseManager.topLevelContainers.contains(newRoot),
                         "OTA: both top-container accessors follow the current Home")
        }
        try sql("DELETE FROM cm_discovery_binding WHERE rule_id='JC.OTA.TEST' AND path_template='\(quotedAbsolute)';")
        try KnowledgeBaseManager.shared.load(from: database)
        let items = JunkEngine.scanRuleBoundPaths(excluding: [], stopped: { false })?.items ?? []
        func canonical(_ url: URL) -> String { SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path) }
        guard let found = items.first(where: { canonical($0.url) == canonical(root) }) else {
            print("OTA diagnostic home", FileUtil.home.path, "expanded", KBPaths.expand("~/Library/Caches/OTAExampleCache"))
            print("OTA diagnostic walker", RuleBoundDiscovery.expand("~/Library/Caches/OTAExampleCache", stopped: { false }).map(\.path))
            print("OTA diagnostic gates", JunkEngine.isIgnoredPath(root.path), SymlinkGuard.isSafePath(url: root), FileUtil.isProtected(root), KnowledgeBaseManager.shared.isProtectedPath(root.path), CleanupSafetyPolicy.isProtectedAsset(root))
            print("OTA diagnostic items", items.map { $0.url.path })
            preconditionFailure("OTA: A new database path must reach the real scanner")
        }
        precondition(found.ruleEvidence?.id == "JC.OTA.TEST", "OTA: new path has current rule evidence")
        try sql("UPDATE cm_discovery_binding SET status='deferred' WHERE rule_id='JC.OTA.TEST';")
        try KnowledgeBaseManager.shared.load(from: database)
        precondition(KnowledgeBaseManager.shared.authored.evidence(for: root, preferredID: "JC.OTA.TEST")?.tier == .readOnly, "OTA: a disabled path cannot be authorized by an old scanner")
        precondition(CleanupSafetyPolicy.isProtectedAsset(root), "OTA: disabled paths also block parent traversal")
        try sql("UPDATE cm_discovery_binding SET status='active' WHERE rule_id='JC.OTA.TEST';")
        try KnowledgeBaseManager.shared.load(from: database)
        RuleTaskGate.shared.updateRestrictions(disabled: ["JC.OTA.TEST"], revoked: [])
        precondition(CleanupSafetyPolicy.isProtectedAsset(root), "OTA: emergency disabled IDs also protect paths found by a broader rule")
        let stale = CleanTarget(Node.item(from: found))
        try KnowledgeBaseManager.shared.load(from: published)
        precondition(!Cleaner.clean(stale).ok, "OTA: old result cannot execute after a rule replacement")
        precondition(fm.fileExists(atPath: root.path), "OTA: stale result preserves the fixture")
        let tasks = PerformanceEngine.maintenanceTasks() + PerformanceEngine.quickGlitchFixes()
        precondition(Set(["fixInputMethod", "fixNotificationCenter", "fixClipboardHandoff", "fixFinderDock"]).isSubset(of: Set(tasks.map(\.taskId))), "OTA: existing quick fixes stay registered")
        precondition(!tasks.contains(where: { $0.taskId == "freeRAM" || $0.command == "vacuumDatabases" }), "OTA: forbidden maintenance remains unavailable")
        try sql("UPDATE cm_discovery_binding SET scanner_id='executeShell' WHERE rule_id='JC.OTA.TEST';")
        do {
            _ = try RuleDatabaseValidator.validate(at: database, policyData: safety, limits: RuleUpdateConfiguration.limits)
            preconditionFailure("OTA: unknown scanner must reject the complete package")
        } catch RuleUpdateFailure.invalidDatabase {}
        print("Rule OTA: real discovery, stale result, maintenance registry and invalid package checks passed")
    }
}
