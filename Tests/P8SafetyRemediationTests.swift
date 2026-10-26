import Foundation
import SQLite3
import AppKit

@MainActor
final class P8SafetyRemediationTests {
    private let fm = FileManager.default
    private let base = URL(fileURLWithPath: "/private/tmp/AClean-P8-" + UUID().uuidString)
    private var passed = 0
    private var fixtureDB: URL { base.appendingPathComponent("rules.db") }
    private var home: URL { base.appendingPathComponent("home") }
    private func check(_ result: @autoclosure () -> Bool, _ message: String) {
        precondition(result(), "P8: " + message); passed += 1
    }
    private func file(_ path: String, _ contents: Data = Data([1, 2, 3])) throws -> URL {
        let url = base.appendingPathComponent(path)
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url)
        return url
    }
    private func sql(_ statements: String, db: URL? = nil) throws {
        var handle: OpaquePointer?
        guard sqlite3_open((db ?? fixtureDB).path, &handle) == SQLITE_OK else { throw CocoaError(.fileReadCorruptFile) }
        defer { sqlite3_close(handle) }
        guard sqlite3_exec(handle, statements, nil, nil, nil) == SQLITE_OK else {
            throw NSError(domain: "P8SQL", code: 1, userInfo: [NSLocalizedDescriptionKey: String(cString: sqlite3_errmsg(handle))])
        }
    }
    func runAll() async throws {
        try fm.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: base) }
        Cleaner.isDryRun = true
        let published = URL(fileURLWithPath: ProcessInfo.processInfo.environment["ACLEAN_RULES_DB"]!)
        let kb = KnowledgeBaseManager.shared
        try kb.load(from: published)
        defer { try? kb.load(from: published) }
        check(kb.authored.loaded, "published final-format rules load")
        for bid in AppConfig.Security.fallbackMailIDs {
            check(JunkEngine.isIgnoredBundleID(bid), "mail identity excluded: " + bid)
        }
        check(kb.authored.junk["JC.CACHE.USER"]?.selected == true && !AppConfig.RuleIDs.auditedAutoCleanUserCacheBundleIDsLower.contains("unknownapp"), "unknown user cache defaults off via Gate 2 allowlist")
        check(kb.authored.junk["JC.CACHE.CONTAINER"]?.selected == false, "unknown container cache defaults off")
        check(!AppConfig.AIClutter.localModelSearchPaths.contains { $0.rawPath.contains(".ollama/models/blobs") }, "no flat Ollama blobs entry")
        try fm.copyItem(at: published, to: fixtureDB)
        // Same published DB, remap paths only; clear host GUI locks for deterministic positive fixtures.
        let fakeHome = home.path.replacingOccurrences(of: "'", with: "''") + "/"
        try sql("UPDATE cm_discovery_binding SET path_template=replace(path_template,'~/','\(fakeHome)'); UPDATE cm_uninstall_template SET path_template=replace(path_template,'~/','\(fakeHome)'); DELETE FROM cm_junk_rule_lock; UPDATE cm_discovery_binding SET path_template=replace(path_template,'Google/Chrome','P8Browser');")
        try kb.load(from: fixtureDB)
        try testProtection()
        try testSelectionAndContainers()
        try testDeveloperProofs()
        try testRuleReload()
        try testUninstallOwnership()
        try await testBodyFailureIsolation()
        try testOpenFiles()
        testLanguages()
        print("P8: \(passed) real-DB and safety remediation assertions passed")
    }

    private func testProtection() throws {
        for path in ["Library/Caches/com.microsoft.Outlook/cache.dat", "Library/Caches/com.readdle.SparkDesktop/cache.dat",
                     "Library/Application Support/Chrome/Default/Cookies", "Library/Application Support/Chrome/Default/Local Storage/data",
                     "Library/Application Support/1Password/vault.db", ".aws/credentials", ".ssh/id_rsa",
                     "Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2"] {
            let url = try file("home/" + path)
            check(CleanupSafetyPolicy.isProtectedAsset(url), "sensitive direct path blocked: " + path)
            check(!Cleaner.clean(CleanTarget(name: "sensitive", url: url, size: 3, action: .trash)).ok, "execution cannot bypass direct protection")
        }
        let parent = home.appendingPathComponent("Library/Application Support/Chrome")
        check(!CleanupSafetyPolicy.inspect(parent).isSafe, "parent deletion cannot bypass browser-state protection")
        let bundle = base.appendingPathComponent("Renamed Security.app")
        let info = ["CFBundleIdentifier": AppConfig.Security.edrTamperProtectedPrefixes[0] + ".fixture"]
        _ = try file("Renamed Security.app/Contents/Info.plist", PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0))
        check(CleanupSafetyPolicy.isProtectedAsset(bundle), "EDR uses real Info.plist rather than display name")
        check(!CleanupSafetyPolicy.inspect(base).isSafe, "ancestor containing EDR/mail/credentials blocked")
        let excluded = try file("home/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat/account/MM.sqlite")
        check(CleanupSafetyPolicy.isProtectedAsset(excluded), "rule excludes protect nested chat databases")
        check(!CleanupSafetyPolicy.inspect(excluded.deletingLastPathComponent()).isSafe,
              "deleting a parent cannot bypass rule exclusions")
        check(!Cleaner.clean(CleanTarget(name: "chat parent", url: excluded.deletingLastPathComponent(), size: 3, action: .trash)).ok,
              "execution reuses recursive rule exclusions even without UI metadata")
        let ordinary = try file("ordinary/user-document.txt")
        check(!CleanupSafetyPolicy.isProtectedAsset(ordinary), "ordinary manual file remains eligible for review")
    }

    private func testSelectionAndContainers() throws {
        for name in ["pnpm", "uv", "org.swift.swiftpm", "UnknownApp"] {
            let child = try file("home/Library/Caches/" + name + "/data.bin", Data(repeating: 1, count: 250_000))
            let item = JunkRulePolicy.apply(ScanItem(url: child.deletingLastPathComponent(), name: name, size: 250_000, safety: .safe, isSelected: true))
            let node = Node.item(from: item)
            check(!node.autoSelected && node.leaves.allSatisfy { !CleanupSelectionPolicy.isRecommended($0) }, "unproven cache defaults off: " + name)
        }
        for repo in [".m2/repository", ".nuget/packages"] {
            let child = try file("home/" + repo + "/pkg/data.bin", Data(repeating: 1, count: 250_000))
            let item = JunkRulePolicy.apply(ScanItem(url: child.deletingLastPathComponent().deletingLastPathComponent(), name: repo, size: 250_000, safety: .safe, isSelected: true))
            let node = Node.item(from: item)
            check(!node.autoSelected && !CleanupSelectionPolicy.isRecommended(node), "L2 package repository defaults off: " + repo)
            check(RiskControlMatrix.requiresConfirmation(node), "L2 cannot disable confirmation")
        }
        let cacheFile = try file("home/Library/Application Support/P8Browser/Default/GPUCache/data.bin")
        let cache = cacheFile.deletingLastPathComponent()
        let item = JunkRulePolicy.apply(ScanItem(url: cache, name: "GPUCache", size: 3, safety: .safe, isSelected: true))
        print("P8 cache fixture: rule=\(String(describing: item.ruleEvidence)), children=\(item.children.count)")
        check(item.ruleEvidence?.tier == .automatic && item.children.count == 1, "verified Chromium leaf split into captured children")
        let rootIdentity = FileIdentity.capture(from: cache)!
        _ = try file("home/Library/Application Support/P8Browser/Default/GPUCache/added-later.bin")
        let node = Node.item(from: item)
        check(node.leaves.count == 1 && node.leaves[0].url == cacheFile, "new child is never silently added to confirmed target list")
        check(CleanupSelectionPolicy.isRecommended(node.leaves[0]), "verified L1 child has structured default evidence")
        let target = CleanTarget(node.leaves[0])
        let capturedOutcome = Cleaner.clean(target)
        print("P8 captured outcome: \(capturedOutcome)")
        check(capturedOutcome.ok, "unchanged captured child reaches ordinary Trash route in dry-run")
        check(!Cleaner.clean(CleanTarget(name: "cache root", url: cache, size: 3, action: .trash)).ok,
              "manual target cannot replace children-only action with whole-container deletion")
        check(FileIdentity.capture(from: cache)?.inode == rootIdentity.inode, "cache container shell retained")
        try Data([9, 8, 7, 6]).write(to: cacheFile)
        check(!Cleaner.clean(target).ok, "replaced/modified child rejected")
        let logURL = try file("home/Library/Logs/P8/old.log")
        let logItem = JunkRulePolicy.apply(ScanItem(url: logURL, name: "old.log", size: 3, safety: .safe))
        check(CleanupSelectionPolicy.isRecommended(Node.item(from: logItem)), "recognized idle log retains structured L1 default")
        check(Cleaner.clean(CleanTarget(Node.item(from: logItem))).ok, "direct log file remains executable without deleting its parent")
        let notes = try file("home/Library/Logs/P8/my-notes.txt")
        check(!JunkRulePolicy.apply(ScanItem(url: notes, name: "notes", size: 3, safety: .safe)).isSelected,
              "log directory name cannot default-select a personal document")
        let manual = Node(name: "unknown", url: cacheFile, safety: .safe, autoSelected: true)
        check(!CleanupSelectionPolicy.isRecommended(manual), "safe label alone is not automatic permission")
        let state = AppState()
        state.moduleKey = "junk"
        let review = Node(name: "persistent", url: try file("persistent.dat"), safety: .caution, size: 3)
        state.roots = [review]; state.selection = [review.id]
        let previous = AppConfigStore.shared.confirmBeforeDelete
        AppConfigStore.shared.confirmBeforeDelete = false
        defer { AppConfigStore.shared.confirmBeforeDelete = previous }
        state.commitClean()
        check(state.dangerConfirm != nil && state.activeCleanupRun == nil, "confirmation setting off still requires L2 confirmation")
    }

    private func testDeveloperProofs() throws {
        let fake = try file("project/.venv/personal.txt").deletingLastPathComponent()
        check(!ProjectPurgeEngine.hasCacheProof(for: fake), ".venv name alone is no proof")
        _ = try file("project/.venv/pyvenv.cfg")
        check(ProjectPurgeEngine.hasCacheProof(for: fake), ".venv proof recognized")
        _ = try file("project/package.json")
        check(!DeveloperArtifactPolicy.isProvenProjectArtifact(fake), "wrong ecosystem cannot justify a virtual environment")
        _ = try file("project/pyproject.toml")
        check(DeveloperArtifactPolicy.isProvenProjectArtifact(fake), "matching Python manifest permits review")
        let game = try file("unity/build/exported-game.bin").deletingLastPathComponent()
        _ = try file("unity/CMakeLists.txt")
        _ = try file("unity/ProjectSettings/ProjectVersion.txt")
        check(!DeveloperArtifactPolicy.isProvenProjectArtifact(game), "Unity exported build retained")
        let repo = base.appendingPathComponent("project")
        check(Shell.execute("/usr/bin/git", ["-C", repo.path, "init", "-q"]).isSuccess, "git fixture initialized")
        check(GitGuard.hasDirtyWorkingTree(containing: fake), "untracked/dirty project remains protected")
        for platform in ["iOS", "watchOS", "tvOS", "visionOS", "macOS"] {
            let root = "home/Library/Developer/Xcode/" + platform + " DeviceSupport/"
            let old = try file(root + "17.9 (old)/Symbols/test.bin").deletingLastPathComponent().deletingLastPathComponent()
            let newest = try file(root + "18.1 (new)/Symbols/test.bin").deletingLastPathComponent().deletingLastPathComponent()
            let unknown = try file(root + "unknown/Symbols/test.bin").deletingLastPathComponent().deletingLastPathComponent()
            check(!DeveloperArtifactPolicy.mustKeepDeviceSupport(old), "numeric old version reviewable: " + platform)
            check(DeveloperArtifactPolicy.mustKeepDeviceSupport(newest), "latest symbols retained: " + platform)
            check(DeveloperArtifactPolicy.mustKeepDeviceSupport(unknown), "unparseable symbols retained: " + platform)
            check(!Cleaner.clean(CleanTarget(name: "latest", url: newest, size: 3, action: .trash)).ok, "direct target cannot bypass latest-symbol protection")
        }
        let unknown = try file("home/Library/Developer/Xcode/DerivedData/unknown/cache.bin").deletingLastPathComponent()
        check(!DeveloperArtifactPolicy.isOrphanDerivedData(unknown), "missing metadata is not proof of orphanhood")
        let info = [AppConfig.Remediation.workspacePathKey: base.appendingPathComponent("missing.xcodeproj").path]
        _ = try file("home/Library/Developer/Xcode/DerivedData/orphan/info.plist", PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0))
        let orphan = home.appendingPathComponent("Library/Developer/Xcode/DerivedData/orphan")
        check(DeveloperArtifactPolicy.isOrphanDerivedData(orphan), "readable parent proves missing workspace")
        let evidence = KnowledgeBaseManager.shared.authored.evidence(for: orphan, preferredID: AppConfig.RuleIDs.derivedOrphan)
        if ProcessGuard.shouldSkipDueToRunningProcess(path: orphan.path).skip {
            check(evidence?.tier == .readOnly && evidence?.defaultSelected == false,
                  "active compiler/Xcode toolchain keeps even verified orphan read-only")
        } else {
            check(evidence?.defaultSelected == true, "verified idle orphan qualifies for L1 default")
        }
        _ = try file("missing.xcodeproj/project.pbxproj")
        check(KnowledgeBaseManager.shared.authored.evidence(for: orphan, preferredID: AppConfig.RuleIDs.derivedOrphan)?.defaultSelected == false, "workspace reappearance revokes L1 selection")
    }

    private func testRuleReload() throws {
        let kb = KnowledgeBaseManager.shared
        let count = kb.authored.junk.count
        let broken = base.appendingPathComponent("broken.db")
        try fm.copyItem(at: fixtureDB, to: broken)
        try sql("DROP TABLE cm_protected_path", db: broken)
        do { try kb.load(from: broken); preconditionFailure("incomplete protection schema must fail") }
        catch { passed += 1 }
        check(kb.authored.loaded && kb.authored.junk.count == count, "failed reload preserves complete prior snapshot")
        try sql("CREATE TABLE cm_protected_path(path_template TEXT,match_kind TEXT); INSERT INTO cm_protected_path VALUES ('/','unknown');", db: broken)
        do { try kb.load(from: broken); preconditionFailure("unknown protection semantics must fail") }
        catch { passed += 1 }
    }

    private func testUninstallOwnership() throws {
        let bid = "org.cleanmate.P8." + UUID().uuidString
        let appURL = base.appendingPathComponent("Example.app")
        _ = try file("Example.app/Contents/Info.plist", PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": bid], format: .xml, options: 0))
        let a = InstalledApp(name: "Example", bundleID: bid, url: appURL)
        let cache = try file("home/Library/Caches/" + bid + "/data.dat").deletingLastPathComponent()
        let sibling = try file("home/Library/Caches/" + bid + ".Beta/keep.dat").deletingLastPathComponent()
        let leftovers = UninstallerEngine.leftovers(for: a)
        check(leftovers.contains { $0.url == cache }, "exact BID associated cache discovered")
        check(!leftovers.contains { $0.url == sibling }, "dot-prefixed sibling not inferred as same owner")
        check(leftovers.allSatisfy { !$0.isSelected }, "unverified app data never default-selected")
        check(UninstallSafety.appGroups(appURL) == nil, "unsigned app cannot establish shared-group ownership")
        let groupContext = UninstallContext(appURL: appURL, bundleID: bid, isAppBody: false, appGroupID: "group.test")
        check(!UninstallSafety.canDeleteAssociatedData(groupContext, url: cache), "shared group remains read-only without complete owner inventory")
        let copy = base.appendingPathComponent("Example Copy.app")
        _ = try file("Example Copy.app/Contents/Info.plist", PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": bid], format: .xml, options: 0))
        let saved = UninstallerEngine.allInstalledAppInstances
        UninstallerEngine.allInstalledAppInstances = [a, InstalledApp(name: "Example Copy", bundleID: bid, url: copy)]
        defer { UninstallerEngine.allInstalledAppInstances = saved }
        let context = UninstallContext(appURL: appURL, bundleID: bid, isAppBody: false)
        check(!UninstallSafety.canDeleteAssociatedData(context, url: cache), "execution rechecks surviving installation")
        check(UninstallerEngine.leftovers(for: a).allSatisfy { $0.locked == true }, "surviving installation locks associated candidates")
        let unknown = Node(name: "unknown.app", url: appURL, safety: .caution)
        check(!AppFolderClassifier.isDefaultClearItem(unknown), "extension alone cannot infer app-body role")
    }

    private func testBodyFailureIsolation() async throws {
        let bid = "org.cleanmate.P8.batch." + UUID().uuidString
        let bodyFile = try file("Batch.app/Contents/data.bin")
        let appURL = bodyFile.deletingLastPathComponent().deletingLastPathComponent()
        let stale = FileIdentity.capture(from: appURL)!
        _ = try file("Batch.app/changed.txt")
        let body = CleanTarget(name: "app", url: appURL, size: 3, action: .trash, identity: stale, ownerBundleIDs: [bid])
        let dataURL = try file("batch-data/config.dat")
        let data = CleanTarget(name: "data", url: dataURL, size: 3, action: .trash, ownerBundleIDs: [bid])
        for targets in [[body, data], [data, body]] {
            let state = AppState(); state.moduleKey = "applications"
            state.cleanTargets(targets, module: "P8 fixture")
            let deadline = Date().addingTimeInterval(8)
            while state.activeCleanupRun != nil, Date() < deadline { try await Task.sleep(nanoseconds: 10_000_000) }
            check(state.activeCleanupRun == nil, "batch completes")
            check(state.report?.outcomes.first?.path == appURL.path, "body executes before data regardless selection order")
            check(state.report?.outcomes.contains { $0.path == dataURL.path && !$0.ok && $0.actionCategory == .skipped } == true,
                  "failed body keeps associated data")
            check(fm.fileExists(atPath: dataURL.path), "associated file still exists")
        }
        let otherBID = "org.cleanmate.P8.other." + UUID().uuidString
        let otherURL = base.appendingPathComponent("Other.app")
        _ = try file("Other.app/Contents/Info.plist", PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": otherBID], format: .xml, options: 0))
        _ = try file("Other.app/Contents/Resources/en.lproj/Localizable.strings")
        let interior = otherURL.appendingPathComponent("Contents/Resources/en.lproj")
        check(!Cleaner.clean(CleanTarget(name: "language stripping", url: interior, size: 3, action: .trash)).ok,
              "bundle interior remains protected as a direct deletion target")
        var otherBody = CleanTarget(name: "other body", url: otherURL, size: 3, action: .trash, ownerBundleIDs: [otherBID])
        otherBody.uninstallContext = UninstallContext(appURL: otherURL, bundleID: otherBID, isAppBody: true)
        check(Cleaner.clean(otherBody).ok, "whole-app uninstall is allowed without stripping bundle components in place")
        let otherDataURL = try file("batch-other/config.dat")
        let otherData = CleanTarget(name: "other data", url: otherDataURL, size: 3, action: .trash, ownerBundleIDs: [otherBID])
        let mixedState = AppState(); mixedState.moduleKey = "applications"
        mixedState.cleanTargets([data, otherData, body, otherBody], module: "mixed P8 fixture")
        let mixedDeadline = Date().addingTimeInterval(8)
        while mixedState.activeCleanupRun != nil, Date() < mixedDeadline { try await Task.sleep(nanoseconds: 10_000_000) }
        check(mixedState.report?.outcomes.contains { $0.path == dataURL.path && !$0.ok } == true,
              "failed owner's data remains skipped in mixed batch")
        check(mixedState.report?.outcomes.contains { $0.path == otherDataURL.path && $0.ok } == true,
              "one app failure does not prevent another successful app's data phase")
        let declared = UninstallBatchPolicy.bodyOwners([body])
        check(!UninstallBatchPolicy.needsBodySuccess(data, declared: declared, succeeded: [bid.lowercased()]), "successful owner body permits data phase")
        check(!UninstallBatchPolicy.needsBodySuccess(data, declared: [], succeeded: []), "pure leftover review retains independent flow")
        var roots = [Node(name: "app group", url: appURL, children: [
            Node(name: "body", url: appURL), Node(name: "failed data", url: dataURL)
        ], isGroup: true)]
        let gone = Set([appURL.path])
        _ = roots.removeNodesOrLeaves { gone.contains($0.path) && (!$0.isGroup || $0.children.isEmpty) }
        check(roots.count == 1 && roots[0].children.count == 1 && roots[0].children[0].url == dataURL,
              "partial uninstall keeps failed data visible after successful body")
        var contextual = data
        contextual.uninstallContext = UninstallContext(appURL: appURL, bundleID: bid, isAppBody: false)
        check(UninstallBatchPolicy.needsBodySuccess(contextual, declared: [], succeeded: []), "uninstall data alone cannot bypass body phase")
    }

    private func testOpenFiles() throws {
        let url = try file("activity/db.sqlite")
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        check(!OpenFileGuard.isIdle(url), "real open handle blocks target")
        check(!Cleaner.clean(CleanTarget(name: "busy", url: url, size: 3, action: .trash)).ok, "Cleaner checks active file handles even in dry-run")
        check(OpenFileGuard.overlaps(url, openPath: url.path + "-wal"), "SQLite WAL belongs to same activity family")
        check(!OpenFileGuard.overlaps(url, openPath: url.path + ".backup"), "unrelated prefix is not an active family")
    }

    private func testLanguages() {
        let keys: [L10nKey] = [.cleanupLogReason, .cleanupRuleLabel, .cleanupManualReview, .cleanupCacheReason, .cleanupPackageReason,
                              .cleanupDerivedReason, .cleanupProtectedReason, .cleanupUninstallBlocked]
        for key in keys {
            check(LocalizationCatalog.entries[key] != nil, "new reason key registered")
            for language in AppLanguage.concreteLanguages {
                check(LocalizationCatalog.entries[key]?.text(for: language).isEmpty == false, "all ten languages have reason text")
            }
        }
    }
}
