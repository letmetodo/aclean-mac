import Foundation

@MainActor
struct P9CleanupCoverageTests {
    func runAll() throws {
        let fm = FileManager.default
        let base = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
            .appendingPathComponent("CleanMate-Coverage-" + UUID().uuidString)
        try fm.createDirectory(at: base, withIntermediateDirectories: true)
        let published = URL(fileURLWithPath: ProcessInfo.processInfo.environment["ACLEAN_RULES_DB"] ?? "Resources/cleanmate_rules.db")
        let dbURL = base.appendingPathComponent("rules.db")
        try fm.copyItem(at: published, to: dbURL)
        let oldHome = FileUtil.homeOverrideForTesting
        let oldProcesses = ProcessGuard.runningProcessNamesOverrideForTesting
        let oldBundles = ProcessGuard.runningBundleIDsOverrideForTesting
        let oldOpen = OpenFileGuard.openPathsOverrideForTesting
        defer {
            FileUtil.homeOverrideForTesting = oldHome
            ProcessGuard.runningProcessNamesOverrideForTesting = oldProcesses
            ProcessGuard.runningBundleIDsOverrideForTesting = oldBundles
            OpenFileGuard.openPathsOverrideForTesting = oldOpen
            try? KnowledgeBaseManager.shared.load(from: published)
            try? fm.removeItem(at: base)
        }
        FileUtil.homeOverrideForTesting = base
        ProcessGuard.runningProcessNamesOverrideForTesting = []
        ProcessGuard.runningBundleIDsOverrideForTesting = []
        OpenFileGuard.openPathsOverrideForTesting = []
        try KnowledgeBaseManager.shared.load(from: dbURL)
        let store = KnowledgeBaseManager.shared.authored
        var count = 0
        func check(_ value: Bool, _ message: String) { precondition(value, message); count += 1 }
        @discardableResult
        func file(_ path: String) throws -> URL {
            let url = base.appendingPathComponent(path)
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(repeating: 0x61, count: 96 * 1024).write(to: url)
            return url
        }
        func leaves(_ item: ScanItem) -> [ScanItem] { item.children.isEmpty ? [item] : item.children.flatMap(leaves) }
        func age(_ root: URL) throws {
            let entries = fm.enumerator(at: root, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
            for url in entries + [root] {
                try fm.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -14 * 86400)], ofItemAtPath: url.path)
            }
        }
        let jianying = "Movies/JianyingPro/User Data/Cache/"
        for leaf in ["audioWave", "recognize", "frameThumbnail"] { try file(jianying + leaf + "/data.bin") }
        let draft = try file(jianying + "Drafts/project.json")
        let browser = "Library/Caches/ms-playwright-mcp/mcp-chrome-test/Default/"
        let cache = try file(browser + "Cache/Cache_Data/data.bin")
        let cookies = try file(browser + "Cookies")
        let login = try file(browser + "Login Data")
        let offline = try file(browser + "Service Worker/CacheStorage/offline.bin")
        let lark = try file("Library/Caches/LarkShell-test/aha/users/u/profile_main/Cache/Cache_Data/data.bin")
        let music = try file("Library/Containers/com.netease.163music/Data/Library/Caches/online_play_cache/music.uc")
        let personal = try file("Library/Containers/com.netease.163music/Data/Documents/Music/personal.mp3")
        let items = JunkEngine.scanHardcodedPathCache()?.items.flatMap(leaves) ?? []
        func path(_ url: URL) -> String { SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path) }
        let paths = Set(items.map { path($0.url) })
        func covers(_ url: URL) -> Bool { paths.contains(path(url)) || paths.contains { path(url).hasPrefix($0 + "/") } }
        for leaf in ["audioWave", "recognize", "frameThumbnail"] {
            check(covers(base.appendingPathComponent(jianying + leaf)), "production scan discovers Jianying " + leaf)
        }
        for target in [cache, lark, music] { check(covers(target), "production scan discovers precise cache leaf: " + target.path) }
        for target in [draft, cookies, login, offline, personal] { check(!covers(target), "user state stays outside discovery: " + target.path) }
        check(store.disabledCacheProfileIDs.isDisjoint(with: ["netease-online", "cursor-agent-versions", "codex-daemon-versions"]), "new profiles retain executable evidence")
        guard let musicItem = items.first(where: { path($0.url) == path(music) }) else {
            preconditionFailure("online cache must expand to its concrete file: \(items.filter { $0.url.path.contains("online_play_cache") })")
        }
        let musicNode = Node.item(from: musicItem)
        check(!CleanupSelectionPolicy.isSelected(node: musicNode, in: .safeDaily), "online playback cache never enters daily selection")
        check(CleanupSelectionPolicy.isSelected(node: musicNode, in: .maxSpace), "reviewed online playback cache enters maximum mode")
        var unknown = musicNode
        unknown.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .review, reason: .generalCache, defaultSelected: false)
        let unprofiled = try file("Library/Caches/UnknownApp/cache.bin")
        unknown.url = unprofiled
        unknown.cacheRecommendation = JunkCacheRecommendationPolicy.evaluate(url: unprofiled,
            unitIdentity: FileIdentity.capture(from: unprofiled), ruleEvidence: unknown.ruleEvidence,
            allocatedBytes: 98304, safetyGatePassed: true, store: store)
        check(unknown.cacheRecommendation?.state == .unknownReview
            && !CleanupSelectionPolicy.isSelected(node: unknown, in: .maxSpace), "unknown caches cannot bypass review in maximum mode")
        for rule in ["JC.DEV.PKG.L2", "JC.DEV.PKG.UNVERIFIED", "JC.DEV.PROJECT"] {
            var asset = unknown
            asset.cacheRecommendation = nil
            asset.ruleEvidence = CleanupRuleEvidence(id: rule, tier: .review, reason: .generalCache, defaultSelected: false)
            check(!CleanupSelectionPolicy.isSelected(node: asset, in: .devPro)
                && !CleanupSelectionPolicy.isSelected(node: asset, in: .maxSpace), "dependency/project assets stay manual")
        }
        let eagle = Node(name: "EagleCloud", url: base.appendingPathComponent("Library/Caches/com.eagleyun.sase"))
        check(SmartCleanSectionClassifier.classify(leaf: eagle, groupTitle: "", groupTags: []) != .design, "EagleCloud is not Eagle design cache")
        var codex = Node(name: "Codex", url: base.appendingPathComponent(".codex/packages/app-server-daemon/releases/0.1.0"))
        codex.ruleEvidence = CleanupRuleEvidence(id: "JC.AI.OLDVERSION", tier: .review, reason: .generalCache, defaultSelected: false)
        check(SmartCleanSectionClassifier.classify(leaf: codex, groupTitle: "", groupTags: []) == .ai, "Codex versions appear under AI tools")
        let gradleFile = try file(".gradle/caches/build-cache-1/data.bin")
        try file(".gradle/caches/modules-2/dependency.jar")
        let gradle = JunkRulePolicy.apply(ScanItem(url: base.appendingPathComponent(".gradle/caches"), name: "Gradle", size: 0, note: "", safety: .safe))
        check(leaves(gradle).contains { path($0.url) == path(gradleFile.deletingLastPathComponent())
            && $0.cacheRecommendation?.profileID == "gradle-build-cache-1"
            && $0.cacheRecommendation?.state != .unknownReview }, "parent cache does not erase precise Gradle child evidence")
        let versions = base.appendingPathComponent(".cache/puppeteer/chrome")
        for version in ["mac-1.0.0", "mac-2.0.0", "mac-3.0.0"] {
            try file(".cache/puppeteer/chrome/" + version + "/Chrome.app/Contents/Resources/en.lproj/data.bin")
            try age(versions.appendingPathComponent(version))
        }
        let old = versions.appendingPathComponent("mac-1.0.0")
        check(VersionedCachePolicy.candidates(root: versions, current: nil, browserDownloads: true) == [old], "retain newest and rollback browser download versions")
        check(JunkEngine.scanHardcodedPathCache()?.items.flatMap(leaves).contains { path($0.url) == path(old) && $0.locked != true } == true, "scan includes safe old browser binaries")
        check(store.evidence(for: old)?.executable == true, "old version has executable evidence")
        try fm.setAttributes([.modificationDate: Date()], ofItemAtPath: old.path)
        check(store.evidence(for: old)?.executable == false, "execution checks fresh version state")
        let agentRoot = base.appendingPathComponent(".local/share/cursor-agent/versions")
        for version in ["2026.01.01-a", "2026.02.01-b", "2026.03.01-c"] {
            try file(".local/share/cursor-agent/versions/" + version + "/cursor-agent")
            try age(agentRoot.appendingPathComponent(version))
        }
        let current = base.appendingPathComponent(".local/bin/cursor-agent")
        try fm.createDirectory(at: current.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.createSymbolicLink(at: current, withDestinationURL: agentRoot.appendingPathComponent("2026.03.01-c/cursor-agent"))
        check(VersionedCachePolicy.candidates(root: agentRoot, current: current, browserDownloads: false).count == 1, "active agent entry retains current and rollback versions")
        let history = JunkEngine.scanHardcodedPathCache()?.items.flatMap(leaves).filter { $0.ruleEvidence?.id == "JC.AI.OLDVERSION" } ?? []
        check(history.count == 3 && history.filter { $0.locked != true }.count == 1, "AI history displays retained versions as well as removable ones")
        try file(".local/share/cursor-agent/install.lock")
        check(VersionedCachePolicy.candidates(root: agentRoot, current: current, browserDownloads: false).count == 1, "unopened persistent lock file is not an active installation")
        try fm.createDirectory(at: agentRoot.deletingLastPathComponent().appendingPathComponent("install.lock.d"), withIntermediateDirectories: true)
        check(VersionedCachePolicy.candidates(root: agentRoot, current: current, browserDownloads: false).isEmpty, "active installation marker retains all versions")
        check(JunkDiscoveryRegistry.shared.allRecordedStates().contains { $0.ruleID == "JC.APP.LARK.CACHE" }, "production discovery produces runtime records")
        check(JunkDiscoveryRegistry.shared.auditCoverage(rules: store.junk).isEmpty, "new authored paths have discovery contracts")
        print("P9 cleanup coverage: \(count) assertions passed")
    }
}
