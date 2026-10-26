import Foundation
import AppKit
import SQLite3
import Darwin

extension P9CrossReviewFixTests {
    func phase3JunkSpecVerification(
        published: URL,
        phase1DB: URL,
        p1Home: URL,
        pubRoot: URL,
        derivedRoot: URL
    ) async throws {
        let kb = KnowledgeBaseManager.shared
        let store = kb.authored
        // ============================================================
        // Phase 3 (T08 / T09 / T12-A): L2 策略、SelectionRestriction 与已发布缓存规则校验
        // ============================================================
        ProcessGuard.runningProcessNamesOverrideForTesting = []
        ProcessGuard.runningBundleIDsOverrideForTesting = []
        OpenFileGuard.openPathsOverrideForTesting = []

        // A14 (T08): NPM CACACHE、Brew 两条规则、普通 Xcode 缓存固定为 L2 且默认不勾选；宽泛 DerivedData 从 JC.DEV.XCODE.CACHE 移除
        for l2RuleID in ["JC.DEV.NPM.CACACHE", "JC.DEV.BREW.DOWNLOADS", "JC.DEV.BREW.CACHE", "JC.DEV.XCODE.CACHE"] {
            let r = store.junk[l2RuleID]
            check(r?.tier == .review && r?.selected == false && !AppConfig.RuleIDs.implementedAutomaticRules.contains(l2RuleID),
                  "A14.1: \(l2RuleID) is fixed to L2 review with default_selected=0 and excluded from implementedAutomaticRules")
        }
        check(store.junk["JC.DEV.XCODE.CACHE"]?.paths.contains(where: { $0.hasSuffix("/Library/Developer/Xcode/DerivedData") }) == false
              && store.junk["JC.DEV.XCODE.CACHE"]?.paths.contains(where: { $0.hasSuffix("/Library/Developer/Xcode/DerivedData/ModuleCache.noindex") }) == true,
              "A14.2: JC.DEV.XCODE.CACHE removes broad DerivedData root and keeps explicit ModuleCache paths")
        check(store.evidence(for: derivedRoot) == nil,
              "A14.2b: ~/Library/Developer/Xcode/DerivedData root itself has no direct rule match")

        let npmCacacheDir = p1Home.appendingPathComponent(".npm/_cacache")
        let brewDownloadsDir = p1Home.appendingPathComponent("Library/Caches/Homebrew/downloads")
        let brewCacheDir = p1Home.appendingPathComponent("Library/Caches/Homebrew")
        let xcodeModCacheDir = p1Home.appendingPathComponent("Library/Developer/Xcode/DerivedData/ModuleCache.noindex")
        for d in [npmCacacheDir, brewDownloadsDir, brewCacheDir, xcodeModCacheDir] {
            try fm.createDirectory(at: d, withIntermediateDirectories: true)
            try Data(repeating: 0x41, count: 4096).write(to: d.appendingPathComponent("payload.bin"))
            let evalD = JunkRulePolicy.apply(ScanItem(url: d, name: d.lastPathComponent, size: 4096, safety: .safe, isSelected: true))
            check(evalD.ruleEvidence?.tier == .review
                  && evalD.isSelected == false
                  && evalD.selectionRestrictions.contains(.productPolicy),
                  "A14.3: \(d.lastPathComponent) evaluates to L2 review, isSelected=false, with .productPolicy restriction")
        }

        // A14 例外：Gradle daemon 残留与已证明孤儿 DerivedData 在满足全部门禁时保持 L1，进程运行时锁定；活跃 DerivedData 为 L2
        let liveProjExisting = p1Home.appendingPathComponent("Projects/LiveApp/LiveApp.xcodeproj")
        try fm.createDirectory(at: liveProjExisting, withIntermediateDirectories: true)
        let liveDerived = derivedRoot.appendingPathComponent("LiveApp-dddd")
        try fm.createDirectory(at: liveDerived, withIntermediateDirectories: true)
        let livePlist: NSDictionary = ["WorkspacePath": liveProjExisting.path]
        livePlist.write(to: liveDerived.appendingPathComponent("info.plist"), atomically: true)
        try Data(repeating: 0x45, count: 4096).write(to: liveDerived.appendingPathComponent("build.db"))
        let evalLiveDerived = JunkRulePolicy.apply(ScanItem(url: liveDerived, name: "LiveApp-dddd", size: 4096, safety: .safe, isSelected: true))
        check(evalLiveDerived.ruleEvidence?.id == "JC.DEV.XCODE.DERIVED.LIVE"
              && evalLiveDerived.ruleEvidence?.tier == .review
              && evalLiveDerived.isSelected == false,
              "A14.3b: Live project DerivedData matches JC.DEV.XCODE.DERIVED.LIVE as L2 review and default-unselected")

        let orphanProjMissing = p1Home.appendingPathComponent("Projects/DeletedApp/DeletedApp.xcodeproj")
        try fm.createDirectory(at: orphanProjMissing.deletingLastPathComponent(), withIntermediateDirectories: true)
        let provenOrphanDerived = derivedRoot.appendingPathComponent("DeletedApp-cccc")
        try fm.createDirectory(at: provenOrphanDerived, withIntermediateDirectories: true)
        let orphanPlist: NSDictionary = ["WorkspacePath": orphanProjMissing.path]
        orphanPlist.write(to: provenOrphanDerived.appendingPathComponent("info.plist"), atomically: true)
        try Data(repeating: 0x42, count: 4096).write(to: provenOrphanDerived.appendingPathComponent("build.db"))
        let twentyDaysAgo = Date(timeIntervalSinceNow: -20 * 86400)
        try fm.setAttributes([.modificationDate: twentyDaysAgo], ofItemAtPath: provenOrphanDerived.path)
        let evalOrphanIdle = JunkRulePolicy.apply(ScanItem(url: provenOrphanDerived, name: "DeletedApp-cccc", size: 4096, safety: .caution, isSelected: false))
        check(evalOrphanIdle.ruleEvidence?.id == "JC.DEV.XCODE.DERIVED.ORPHAN"
              && evalOrphanIdle.ruleEvidence?.tier == .automatic
              && evalOrphanIdle.locked == false
              && evalOrphanIdle.isSelected == true,
              "A14.4: Proven orphan DerivedData is L1 automatic and default-selected when idle")
        ProcessGuard.runningProcessNamesOverrideForTesting = ["swift-frontend"]
        let evalOrphanBusy = JunkRulePolicy.apply(ScanItem(url: provenOrphanDerived, name: "DeletedApp-cccc", size: 4096, safety: .safe, isSelected: true))
        check(evalOrphanBusy.locked == true && evalOrphanBusy.isSelected == false,
              "A14.5: Proven orphan DerivedData locks when swift-frontend toolchain is running")
        ProcessGuard.runningProcessNamesOverrideForTesting = []

        // A11 (T09): 同一 URL/身份/规则哈希/巡检上下文/限制集合下，初始 safe/caution 与 isSelected true/false 产出完全相同的授权、锁定与默认建议
        let chromeGPU = p1Home.appendingPathComponent("Library/Application Support/Google/Chrome/Default/GPUCache")
        try fm.createDirectory(at: chromeGPU, withIntermediateDirectories: true)
        try Data(repeating: 0x43, count: 4096).write(to: chromeGPU.appendingPathComponent("shader.bin"))
        for targetURL in [chromeGPU, npmCacacheDir, pubRoot.appendingPathComponent("hosted")] {
            let idCap = FileIdentity.capture(from: targetURL)
            let itemSafeTrue = ScanItem(url: targetURL, name: targetURL.lastPathComponent, size: 4096, safety: .safe, isSelected: true, fileIdentity: idCap)
            let itemCautionFalse = ScanItem(url: targetURL, name: targetURL.lastPathComponent, size: 4096, safety: .caution, isSelected: false, fileIdentity: idCap)
            let evalA = JunkRulePolicy.apply(itemSafeTrue)
            let evalB = JunkRulePolicy.apply(itemCautionFalse)
            check(evalA.ruleEvidence == evalB.ruleEvidence
                  && evalA.locked == evalB.locked
                  && evalA.safety == evalB.safety
                  && evalA.isSelected == evalB.isSelected
                  && evalA.selectionRestrictions == evalB.selectionRestrictions,
                  "A11.1: Initial safe/true vs caution/false invariance holds for \(targetURL.lastPathComponent)")
        }

        // T09 / C16: 用户手动勾选 L2 与取消勾选 L1 后，排序/折叠/过滤/reconcile 保留手选状态；锁定时强制撤销
        let l1Node = Node.item(from: JunkRulePolicy.apply(ScanItem(url: chromeGPU, name: "GPUCache", size: 4096, safety: .safe, isSelected: true)))
        let l2Node = Node.item(from: JunkRulePolicy.apply(ScanItem(url: npmCacacheDir, name: "_cacache", size: 4096, safety: .caution, isSelected: false)))
        let groupNode = Node(name: "CacheGroup", icon: "folder", size: l1Node.totalSize + l2Node.totalSize, children: [l1Node, l2Node], isGroup: true, tags: ["System Junk"])
        let state = AppState()
        state.moduleKey = "junk"
        state.roots = [groupNode]
        // 初始推荐仅勾选 L1
        state.applyStrategy(.smart, scopedToCategory: false)
        let l1LeafIDs = Set(l1Node.leaves.map(\.id))
        let l2LeafIDs = Set(l2Node.leaves.map(\.id))
        check(l1LeafIDs.isSubset(of: state.selection) && state.selection.isDisjoint(with: l2LeafIDs),
              "A11.2: Smart default selects L1 leaves and excludes L2 leaves")
        // 用户手选 L2 并取消 L1
        state.setSelection(l2Node, true)
        state.setSelection(l1Node, false)
        check(l2LeafIDs.isSubset(of: state.selection) && state.selection.isDisjoint(with: l1LeafIDs),
              "A11.3: User manual selection overrides defaults")
        state.sortKey = .name
        state.sortAscending = true
        state.expanded.insert(groupNode.id)
        let prevIdentities = Dictionary(uniqueKeysWithValues: state.roots.allLeaves.compactMap { l in l.fileIdentity.map { (l.id, $0) } })
        state.reconcileSelectionAfterRefresh(previousIdentities: prevIdentities)
        check(l2LeafIDs.isSubset(of: state.selection) && state.selection.isDisjoint(with: l1LeafIDs),
              "A11.4 / C16: Sorting, expanding, and reconcile with unchanged identity preserve user manual selection")
        // 当 L2 节点变为 locked 时，reconcileSelectionAfterRefresh 必须撤销其选中状态
        var lockedL2Node = l2Node
        lockedL2Node.locked = true
        lockedL2Node.selectionRestrictions.insert(.readOnlyAsset)
        state.roots = [Node(id: groupNode.id, name: "CacheGroup", icon: "folder", size: groupNode.size, children: [l1Node, lockedL2Node], isGroup: true, tags: ["System Junk"])]
        state.reconcileSelectionAfterRefresh(previousIdentities: prevIdentities)
        check(state.selection.isDisjoint(with: l2LeafIDs),
              "A11.5 / C16: Locking a node revokes its user selection upon reconcile")

        // C20 & C21: original profiles plus reviewed precise paths and version retention.
        check(store.cacheProfiles.count == 61, "C20.1: Loaded cm_cache_profile count is exactly 61")
        let totalProfileLocks = store.cacheProfileLocks.values.reduce(0) { $0 + $1.count }
        check(totalProfileLocks == 113, "C20.2: Loaded cm_cache_profile_lock count is exactly 113")
        check(store.cacheRecommendationConfig.isAvailable
              && store.cacheRecommendationConfig.appSuggestionBytes == 524_288_000
              && store.cacheRecommendationConfig.developerSuggestionBytes == 1_073_741_824
              && store.cacheRecommendationConfig.ageSuggestionEnabled == false,
              "C20.3: CacheRecommendationConfig matches 500 MiB (524288000) / 1 GiB (1073741824) and age_suggestion=0")
        check(!store.ruleSQLHash.isEmpty && store.ruleSQLHash.count == 64,
              "C20.4: AuthoredRules exposes 64-char database SHA-256")

        let expectedProfileIDs: Set<String> = [
            "chrome", "chromium", "brave", "edge", "vivaldi", "opera", "arc",
            "chrome-cache", "arc-cache", "arc-bundle-cache", "firefox",
            "electron-Code", "electron-Cursor", "electron-Windsurf", "electron-Antigravity", "electron-Claude",
            "electron-LarkShell", "electron-Notion", "electron-Slack", "electron-discord", "electron-Figma",
            "electron-Insomnia", "electron-Linear", "electron-Postman", "electron-CherryStudio", "electron-obsidian",
            "npm-download", "brew-download", "pip-macos", "pip-xdg", "bun-download", "cargo-archive",
            "go-build-macos", "go-build-xdg", "xcode-modules", "xcode-derived-live", "xcode-derived-orphan",
            "jianying-audioWave", "jianying-recognize", "jianying-frameThumbnail",
            "devtools-http", "playwright-mcp-http", "netease-online",
            "lark-aha-profile_all-Cache", "lark-aha-profile_all-Code-Cache",
            "lark-aha-PartitionsV2-all-Cache", "lark-aha-PartitionsV2-all-Code-Cache",
            "lark-iron-profile_all-Cache", "lark-iron-profile_all-Code-Cache",
            "lark-iron-PartitionsV2-all-Cache", "lark-iron-PartitionsV2-all-Code-Cache",
            "cursor-vsix", "code-vsix", "gradle-build-cache-1",
            "adobe-Media-Cache", "adobe-Media-Cache-Files",
            "puppeteer-chrome", "puppeteer-headless", "cursor-agent-versions",
            "cursor-embedded-versions", "codex-daemon-versions"
        ]
        check(Set(store.cacheProfiles.keys) == expectedProfileIDs && store.disabledCacheProfileIDs.isEmpty,
              "C21.1: All 61 profile IDs match the reviewed set with 0 disabled profiles")

        let allLoadedLocks: [AuthoredCacheProfileLock] = store.cacheProfileLocks.values.flatMap { $0 }
        let processFamilyLocks = allLoadedLocks.filter { $0.lockKind == .processFamily }
        check(processFamilyLocks.count == 2
              && Set(processFamilyLocks.map { $0.profileID }) == ["pip-macos", "pip-xdg"]
              && processFamilyLocks.allSatisfy { $0.lockValue == "python3Versioned" },
              "C21.2: Exactly 2 process_family locks exist (pip-macos and pip-xdg -> python3Versioned)")

        ProcessGuard.runningProcessNamesOverrideForTesting = ["python3.12"]
        check(ProcessGuard.isProcessFamilyRunning("python3Versioned").isRunning,
              "C21.3: python3.12 matches python3Versioned process family")
        let pipMacosDir = p1Home.appendingPathComponent("Library/Caches/pip")
        try fm.createDirectory(at: pipMacosDir, withIntermediateDirectories: true)
        try Data(repeating: 0x44, count: 4096).write(to: pipMacosDir.appendingPathComponent("wheel.whl"))
        let evalPipBusy = JunkRulePolicy.apply(ScanItem(url: pipMacosDir, name: "pip", size: 4096, safety: .caution, isSelected: false))
        check(evalPipBusy.locked == true && evalPipBusy.isSelected == false,
              "C21.4: pip-macos cache locks when python3.12 is running via process_family lock")
        ProcessGuard.runningProcessNamesOverrideForTesting = ["python3.12-config"]
        check(!ProcessGuard.isProcessFamilyRunning("python3Versioned").isRunning,
              "C21.5: python3.12-config does not falsely match python3Versioned regex")
        ProcessGuard.runningProcessNamesOverrideForTesting = []
        let evalPipIdle = JunkRulePolicy.apply(ScanItem(url: pipMacosDir, name: "pip", size: 4096, safety: .caution, isSelected: false))
        check(evalPipIdle.locked == false && evalPipIdle.ruleEvidence?.tier == .review,
              "C21.6: pip-macos cache is unlocked L2 review when python/pip processes are idle")

        if let goProfile = store.cacheProfiles["go-build-macos"],
           let npmProfile = store.cacheProfiles["npm-download"] {
            check(store.effectiveRebuildCost(for: goProfile) == .medium
                  && store.effectiveRebuildCost(for: npmProfile) == .low,
                  "C20.5: effectiveRebuildCost computes max(rule.rebuildCost, profile.costOverride)")
        }

        let pipNode = Node.item(from: evalPipIdle)
        let pipTargets = pipNode.leaves.map { CleanTarget($0) }
        check(!pipTargets.isEmpty && pipTargets.allSatisfy { $0.selectionRestrictions.contains(.productPolicy) },
              "A11.6: CleanTarget preserves selectionRestrictions from ScanItem and Node")

        // C20.6: 异常/冲突的 cm_cache_profile 配置不会崩溃，而是关闭大缓存建议配置或停用冲突 profile
        let badProfileDB = base.appendingPathComponent("bad_profile.db")
        try? fm.removeItem(at: badProfileDB)
        try fm.copyItem(at: phase1DB, to: badProfileDB)
        try sql("UPDATE cm_electron_data_dir SET dir_name='ConflictingSlackDir' WHERE bundle_id='com.tinyspeck.slackmacgap';", db: badProfileDB)
        try kb.load(from: badProfileDB)
        check(kb.authored.loaded
              && kb.authored.cacheRecommendationConfig.isAvailable
              && kb.authored.disabledCacheProfileIDs.contains("electron-Slack"),
              "C20.6: Conflicting electron_leaves mapping disables only the conflicting profile without crashing")

        try sql("UPDATE cm_rule_meta SET value='99' WHERE key='schema_version';", db: badProfileDB)
        try kb.load(from: badProfileDB)
        check(kb.authored.loaded && !kb.authored.cacheRecommendationConfig.isAvailable,
              "C20.7: Invalid schema_version disables cacheRecommendationConfig while keeping rules loaded")
        try kb.load(from: phase1DB)

        // ============================================================
        // Phase 4: CM-JUNK-T10 (37 Closed Cache Profiles, Regex, Case, Precedence, Conflict)
        // Covers: C06, C07, C08, C09, C14, C23
        // ============================================================
        ProcessGuard.runningProcessNamesOverrideForTesting = []
        ProcessGuard.runningBundleIDsOverrideForTesting = []

        // C06: .pub-cache/hosted、Spotify、workspaceStorage、Service Worker 均不进入 T12 建议，且不匹配任何 cm_cache_profile
        let c06PubHosted = p1Home.appendingPathComponent(".pub-cache/hosted")
        let c06Spotify = p1Home.appendingPathComponent("Library/Application Support/Spotify/PersistentCache")
        let c06WorkspaceStorage = p1Home.appendingPathComponent("Library/Application Support/Code/User/workspaceStorage")
        let c06ServiceWorker = p1Home.appendingPathComponent("Library/Application Support/Google/Chrome/Default/Service Worker/CacheStorage")
        for u in [c06PubHosted, c06Spotify, c06WorkspaceStorage, c06ServiceWorker] {
            try fm.createDirectory(at: u, withIntermediateDirectories: true)
            try Data(repeating: 0x55, count: 4096).write(to: u.appendingPathComponent("asset.dat"))
        }
        check(kb.authored.matchingCacheProfileUnits(for: c06PubHosted).isEmpty
              && kb.authored.matchingCacheProfileUnits(for: c06Spotify).isEmpty
              && kb.authored.matchingCacheProfileUnits(for: c06WorkspaceStorage).isEmpty
              && kb.authored.matchingCacheProfileUnits(for: c06ServiceWorker).isEmpty,
              "C06.1: .pub-cache/hosted, Spotify, workspaceStorage, Service Worker never match any cm_cache_profile")
        let evalC06Workspace = JunkRulePolicy.apply(ScanItem(url: c06WorkspaceStorage, name: "workspaceStorage", size: 4096, safety: .safe, isSelected: true))
        let evalC06SW = JunkRulePolicy.apply(ScanItem(url: c06ServiceWorker, name: "CacheStorage", size: 4096, safety: .safe, isSelected: true))
        check(evalC06Workspace.locked == true && !evalC06Workspace.isSelected && evalC06Workspace.evaluationReason == .protectedAssetBlocked,
              "C06.2: Electron User/workspaceStorage remains strictly protected")
        check(evalC06SW.locked == true && !evalC06SW.isSelected && (evalC06SW.ruleEvidence == nil || evalC06SW.ruleEvidence?.tier == .readOnly),
              "C06.3: Chromium Service Worker/CacheStorage remains strictly protected")

        // C07: Profile 1 / Profile -1 / Profile 1 尾换行 / root-other -> 只接受精确合法项
        let chromeRoot = p1Home.appendingPathComponent("Library/Application Support/Google/Chrome")
        let validProfile1GPU = chromeRoot.appendingPathComponent("Profile 1/GPUCache")
        let invalidNegProfileGPU = chromeRoot.appendingPathComponent("Profile -1/GPUCache")
        let invalidNewlineProfileGPU = chromeRoot.appendingPathComponent("Profile 1\n/GPUCache")
        let invalidRootOtherGPU = chromeRoot.appendingPathComponent("root-other/GPUCache")
        for u in [validProfile1GPU, invalidNegProfileGPU, invalidNewlineProfileGPU, invalidRootOtherGPU] {
            try fm.createDirectory(at: u, withIntermediateDirectories: true)
            try Data(repeating: 0x31, count: 1024).write(to: u.appendingPathComponent("data_0"))
        }
        check(kb.authored.matchingCacheProfileUnits(for: validProfile1GPU).first?.profile.id == "chrome",
              "C07.1: 'Profile 1/GPUCache' matches chrome profile")
        check(kb.authored.matchingCacheProfileUnits(for: invalidNegProfileGPU).isEmpty
              && kb.authored.evidence(for: invalidNegProfileGPU, preferredID: "JC.BRW.CHROMIUM.CACHE") == nil,
              "C07.2: 'Profile -1/GPUCache' is rejected by chromiumProfileName regex and authored rule matching")
        check(kb.authored.matchingCacheProfileUnits(for: invalidNewlineProfileGPU).isEmpty
              && kb.authored.evidence(for: invalidNewlineProfileGPU, preferredID: "JC.BRW.CHROMIUM.CACHE") == nil,
              "C07.3: 'Profile 1\\n/GPUCache' with trailing newline is rejected by \\A...\\z anchors")
        check(kb.authored.matchingCacheProfileUnits(for: invalidRootOtherGPU).isEmpty
              && kb.authored.evidence(for: invalidRootOtherGPU, preferredID: "JC.BRW.CHROMIUM.CACHE") == nil,
              "C07.4: 'root-other/GPUCache' is rejected")

        // Firefox profile regex validation (\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z + cache2/startupCache)
        let ffRoot = p1Home.appendingPathComponent("Library/Caches/Firefox/Profiles")
        let validFFCache2 = ffRoot.appendingPathComponent("abcd1234.default-release/cache2")
        let invalidDotFFCache2 = ffRoot.appendingPathComponent(".hidden-profile/cache2")
        let invalidFFSubdir = ffRoot.appendingPathComponent("abcd1234.default-release/storage")
        for u in [validFFCache2, invalidDotFFCache2, invalidFFSubdir] {
            try fm.createDirectory(at: u, withIntermediateDirectories: true)
        }
        check(kb.authored.matchingCacheProfileUnits(for: validFFCache2).first?.profile.id == "firefox"
              && kb.authored.evidence(for: validFFCache2, preferredID: "JC.BRW.FIREFOX.CACHE")?.tier == .automatic,
              "C07.5: Valid Firefox profile cache2 matches firefox profile and JC.BRW.FIREFOX.CACHE L1")
        check(kb.authored.matchingCacheProfileUnits(for: invalidDotFFCache2).isEmpty
              && kb.authored.evidence(for: invalidDotFFCache2, preferredID: "JC.BRW.FIREFOX.CACHE") == nil,
              "C07.6: Firefox profile starting with '.' is rejected")
        check(kb.authored.matchingCacheProfileUnits(for: invalidFFSubdir).isEmpty
              && kb.authored.evidence(for: invalidFFSubdir, preferredID: "JC.BRW.FIREFOX.CACHE") == nil,
              "C07.7: Firefox non-whitelisted subdir 'storage' is rejected")

        // C08: Case-sensitive 区分 Code 与 code，不合并成同一目标，仅清单中合法根参与
        let appSupportRoot = p1Home.appendingPathComponent("Library/Application Support")
        let existingCodeDir = appSupportRoot.appendingPathComponent("Code")
        try? fm.removeItem(at: existingCodeDir)
        let lowercaseCodeCache = appSupportRoot.appendingPathComponent("code/Cache/Cache_Data")
        try fm.createDirectory(at: lowercaseCodeCache, withIntermediateDirectories: true)
        try Data(repeating: 0x32, count: 1024).write(to: lowercaseCodeCache.appendingPathComponent("f_0001"))
        let discoveredLowercaseCode = kb.authored.discoverCacheProfileUnits(ruleID: "JC.ELECTRON.CACHE")
            .filter { $0.profile.id == "electron-Code" }
        check(discoveredLowercaseCode.isEmpty && kb.authored.matchingCacheProfileUnits(for: lowercaseCodeCache).isEmpty,
              "C08.1: Lowercase 'code' directory on disk is not matched as 'electron-Code' ('Code')")
        try? fm.removeItem(at: appSupportRoot.appendingPathComponent("code"))
        let exactCodeCache = appSupportRoot.appendingPathComponent("Code/Cache/Cache_Data")
        try fm.createDirectory(at: exactCodeCache, withIntermediateDirectories: true)
        try Data(repeating: 0x33, count: 1024).write(to: exactCodeCache.appendingPathComponent("f_0001"))
        let discoveredExactCode = kb.authored.discoverCacheProfileUnits(ruleID: "JC.ELECTRON.CACHE")
            .filter { $0.profile.id == "electron-Code" }
        check(discoveredExactCode.count == 1 && discoveredExactCode.first?.unitURL.path == exactCodeCache.path,
              "C08.2: Exact-case 'Code/Cache/Cache_Data' is discovered for 'electron-Code'")

        // C14: 同时存在 Cache 与 Cache/Cache_Data -> 只产生后者单元，无双重计量/祖孙重复删除
        let slackRoot = appSupportRoot.appendingPathComponent("Slack")
        let slackCache = slackRoot.appendingPathComponent("Cache")
        let slackCacheData = slackRoot.appendingPathComponent("Cache/Cache_Data")
        let slackGPUCache = slackRoot.appendingPathComponent("GPUCache")
        try fm.createDirectory(at: slackCacheData, withIntermediateDirectories: true)
        try fm.createDirectory(at: slackGPUCache, withIntermediateDirectories: true)
        try Data(repeating: 0x41, count: 2048).write(to: slackCache.appendingPathComponent("outer.bin"))
        try Data(repeating: 0x42, count: 4096).write(to: slackCacheData.appendingPathComponent("inner.bin"))
        try Data(repeating: 0x43, count: 1024).write(to: slackGPUCache.appendingPathComponent("gpu.bin"))

        let slackUnits = kb.authored.discoverCacheProfileUnits(ruleID: "JC.ELECTRON.CACHE")
            .filter { $0.profile.id == "electron-Slack" }
        let slackUnitPaths = Set(slackUnits.map { $0.unitURL.path })
        check(slackUnitPaths.contains(slackCacheData.path)
              && !slackUnitPaths.contains(slackCache.path)
              && slackUnitPaths.contains(slackGPUCache.path),
              "C14.1: When both Cache and Cache/Cache_Data exist, discoverUnits yields Cache/Cache_Data and suppresses parent Cache")
        check(kb.authored.cacheSubdirTier(slackCache, ruleID: "JC.ELECTRON.CACHE") == nil
              && kb.authored.cacheSubdirTier(slackCacheData, ruleID: "JC.ELECTRON.CACHE") == .automatic,
              "C14.2: cacheSubdirTier rejects parent Cache when child Cache/Cache_Data exists, preventing ancestor-descendant double counting")

        // C09: 目录包含 LocalHistory/凭据/云盘逃逸链接，或子项读取失败 -> 整删范围锁定
        let c09DirWithLocalHistory = p1Home.appendingPathComponent("Library/Caches/com.example.c09lh")
        try fm.createDirectory(at: c09DirWithLocalHistory.appendingPathComponent("nested/LocalHistory"), withIntermediateDirectories: true)
        try Data(repeating: 0x61, count: 1024).write(to: c09DirWithLocalHistory.appendingPathComponent("nested/LocalHistory/changes.dat"))
        let evalC09LH = JunkRulePolicy.apply(ScanItem(url: c09DirWithLocalHistory, name: "com.example.c09lh", size: 1024, safety: .safe, isSelected: true))
        check(evalC09LH.locked == true && !evalC09LH.isSelected && evalC09LH.evaluationReason == .protectedAssetBlocked,
              "C09.1: Directory containing nested LocalHistory is locked with protectedAssetBlocked")

        let c09DirWithEscapeLink = p1Home.appendingPathComponent("Library/Caches/com.example.c09link")
        let outsideTarget = base.appendingPathComponent("outside_cloud_dir")
        try fm.createDirectory(at: c09DirWithEscapeLink, withIntermediateDirectories: true)
        try fm.createDirectory(at: outsideTarget, withIntermediateDirectories: true)
        let escapeSymlink = c09DirWithEscapeLink.appendingPathComponent("escape_link")
        try? fm.removeItem(at: escapeSymlink)
        try fm.createSymbolicLink(at: escapeSymlink, withDestinationURL: outsideTarget)
        let evalC09Link = JunkRulePolicy.apply(ScanItem(url: c09DirWithEscapeLink, name: "com.example.c09link", size: 1024, safety: .safe, isSelected: true))
        check(evalC09Link.locked == true && !evalC09Link.isSelected && evalC09Link.evaluationReason == .symlinkEscapeBlocked,
              "C09.2: Directory containing a descendant symlink escaping the directory boundary is locked with symlinkEscapeBlocked")

        // C23: 相同叶存在同级 Electron/AI 规则时，结果稳定且按 profile.rule_id (JC.AI.IDE.CACHE) 确定性裁决，不能覆盖更严格规则
        let cursorCacheData = appSupportRoot.appendingPathComponent("Cursor/Cache/Cache_Data")
        try fm.createDirectory(at: cursorCacheData, withIntermediateDirectories: true)
        try Data(repeating: 0x71, count: 2048).write(to: cursorCacheData.appendingPathComponent("f_0001"))
        let evNoHint = kb.authored.evidence(for: cursorCacheData, preferredID: nil)
        var candElectron = ScanItem(url: cursorCacheData, name: "Cache_Data", size: 2048, safety: .safe, isSelected: true)
        candElectron.ruleEvidence = CleanupRuleEvidence(id: "JC.ELECTRON.CACHE", tier: .automatic, reason: .generalCache, defaultSelected: true)
        var candAI = ScanItem(url: cursorCacheData, name: "Cache_Data", size: 2048, safety: .safe, isSelected: true)
        candAI.ruleEvidence = CleanupRuleEvidence(id: "JC.AI.IDE.CACHE", tier: .automatic, reason: .generalCache, defaultSelected: true)
        let evalElectron = JunkRulePolicy.apply(candElectron)
        let evalAI = JunkRulePolicy.apply(candAI)
        let dedupOrder1 = RuleAwareDeduplicator.deduplicate([evalElectron, evalAI])
        let dedupOrder2 = RuleAwareDeduplicator.deduplicate([evalAI, evalElectron])
        check(evNoHint?.id == "JC.AI.IDE.CACHE"
              && dedupOrder1.items.first?.ruleEvidence?.id == "JC.AI.IDE.CACHE"
              && dedupOrder2.items.first?.ruleEvidence?.id == "JC.AI.IDE.CACHE",
              "C23.1: Cursor/Cache/Cache_Data deterministically resolves to JC.AI.IDE.CACHE regardless of candidate order or dictionary iteration")
        let cursorWorkspace = appSupportRoot.appendingPathComponent("Cursor/User/workspaceStorage")
        try fm.createDirectory(at: cursorWorkspace, withIntermediateDirectories: true)
        var candCursorWorkspace = ScanItem(url: cursorWorkspace, name: "workspaceStorage", size: 2048, safety: .safe, isSelected: true)
        candCursorWorkspace.ruleEvidence = CleanupRuleEvidence(id: "JC.AI.IDE.CACHE", tier: .automatic, reason: .generalCache, defaultSelected: true)
        let evalCursorProtected = JunkRulePolicy.apply(candCursorWorkspace)
        check(evalCursorProtected.locked == true
              && !evalCursorProtected.isSelected
              && evalCursorProtected.evaluationReason == .protectedAssetBlocked,
              "C23.2: Profile rule tie-breaker never overrides stricter protected rules on Cursor/User/workspaceStorage")

        // ============================================================
        // Phase 5 (T11 + T12-B/C/D): A17 + C01/C02/C03/C04/C05/C10/C11/C12/C13/C15/C16/C17/C18/C19/C22
        // ============================================================

        // A17: cm_junk_rule.rebuild_cost / cm_cache_profile.cost_override 未知枚举值校验
        let a17RuleDB = base.appendingPathComponent("a17_rule_cost.db")
        try? fm.removeItem(at: a17RuleDB)
        try fm.copyItem(at: phase1DB, to: a17RuleDB)
        let sqlCheckRejectedRule = (try? sql("UPDATE cm_junk_rule SET rebuild_cost = 'unknown' WHERE id = 'JC.DEV.NPM.CACACHE';", db: a17RuleDB)) == nil
        try sql("PRAGMA ignore_check_constraints = ON; UPDATE cm_junk_rule SET rebuild_cost = 'unknown' WHERE id = 'JC.DEV.NPM.CACACHE';", db: a17RuleDB)
        var a17RuleLoadError: String? = nil
        do {
            try kb.load(from: a17RuleDB)
        } catch {
            a17RuleLoadError = error.localizedDescription
        }
        check(sqlCheckRejectedRule && a17RuleLoadError?.contains("JC.DEV.NPM.CACACHE") == true,
              "A17.1: Invalid cm_junk_rule.rebuild_cost ('unknown') is rejected by SQL CHECK and throws Swift load error containing rule ID without falling back to .none")

        let a17ProfDB = base.appendingPathComponent("a17_prof_cost.db")
        try? fm.removeItem(at: a17ProfDB)
        try fm.copyItem(at: phase1DB, to: a17ProfDB)
        let sqlCheckRejectedProf = (try? sql("UPDATE cm_cache_profile SET cost_override = 'unknown' WHERE id = 'xcode-derived-live';", db: a17ProfDB)) == nil
        try sql("PRAGMA ignore_check_constraints = ON; UPDATE cm_cache_profile SET cost_override = 'unknown' WHERE id = 'xcode-derived-live';", db: a17ProfDB)
        try kb.load(from: a17ProfDB)
        check(sqlCheckRejectedProf
              && !kb.authored.cacheRecommendationConfig.isAvailable
              && (kb.authored.cacheRecommendationConfig.unavailableReason?.contains("xcode-derived-live") == true),
              "A17.2: Invalid cm_cache_profile.cost_override ('unknown') is rejected by SQL CHECK and disables cache recommendation config with profile ID")
        try kb.load(from: phase1DB)

        // C01: 应用/封闭缓存 < 524,288,000 -> ordinary (automaticAllowed=true)；== 524,288,000 -> suggestedLarge + 建议 badge + 自动清理排除
        let slackCacheDataIdentity = FileIdentity.capture(from: slackCacheData)
        let c01Ev = CleanupRuleEvidence(id: "JC.ELECTRON.CACHE", tier: .automatic, reason: .generalCache, defaultSelected: true)
        let c01Below = JunkCacheRecommendationPolicy.evaluate(
            url: slackCacheData,
            unitURL: slackCacheData,
            unitIdentity: slackCacheDataIdentity,
            ruleEvidence: c01Ev,
            allocatedBytes: 524_287_999,
            safetyGatePassed: true,
            store: kb.authored
        )
        let c01AtThreshold = JunkCacheRecommendationPolicy.evaluate(
            url: slackCacheData,
            unitURL: slackCacheData,
            unitIdentity: slackCacheDataIdentity,
            ruleEvidence: c01Ev,
            allocatedBytes: 524_288_000,
            safetyGatePassed: true,
            store: kb.authored
        )
        let c01AboveThreshold = JunkCacheRecommendationPolicy.evaluate(
            url: slackCacheData,
            unitURL: slackCacheData,
            unitIdentity: slackCacheDataIdentity,
            ruleEvidence: c01Ev,
            allocatedBytes: 524_288_001,
            safetyGatePassed: true,
            store: kb.authored
        )
        check(c01Below.state == .ordinary
              && c01Below.automaticAllowed == true
              && c01Below.thresholdBytes == 524_288_000
              && JunkCacheRecommendationPolicy.localizedLargeBadge(for: c01Below) == nil,
              "C01.1: App/closed cache with allocatedBytes = 524,287,999 evaluates to ordinary with automaticAllowed = true")
        check(c01AtThreshold.state == .suggestedLarge
              && c01AtThreshold.automaticAllowed == false
              && c01AtThreshold.reasons.contains(.thresholdReached)
              && c01AboveThreshold.state == .suggestedLarge
              && c01AboveThreshold.automaticAllowed == false
              && JunkCacheRecommendationPolicy.localizedLargeBadge(for: c01AtThreshold) == L10n.localized(.junkCacheLargeSuggestion),
              "C01.2: App/closed cache with allocatedBytes == 524,288,000 and 524,288,001 evaluates to suggestedLarge, shows badge, and excludes automatic cleanup")

        // C02: 开发/工具链缓存 < 1,073,741,824 与 == 1,073,741,824（L1 与 L2 分支）
        let xcodeOrphan = p1Home.appendingPathComponent("Library/Developer/Xcode/DerivedData/OrphanProj-abcd")
        try fm.createDirectory(at: xcodeOrphan, withIntermediateDirectories: true)
        let orphanPlistData = try PropertyListSerialization.data(
            fromPropertyList: ["WorkspacePath": base.appendingPathComponent("MissingOrphan.xcodeproj").path],
            format: .xml,
            options: 0
        )
        try orphanPlistData.write(to: xcodeOrphan.appendingPathComponent("Info.plist"))
        try fm.setAttributes([.modificationDate: Date().addingTimeInterval(-30 * 3600)], ofItemAtPath: xcodeOrphan.path)
        let xcodeOrphanIdentity = FileIdentity.capture(from: xcodeOrphan)
        let c02L1Ev = CleanupRuleEvidence(id: "JC.DEV.XCODE.DERIVED.ORPHAN", tier: .automatic, reason: .generalCache, defaultSelected: true)
        let c02L1Below = JunkCacheRecommendationPolicy.evaluate(
            url: xcodeOrphan,
            unitURL: xcodeOrphan,
            unitIdentity: xcodeOrphanIdentity,
            ruleEvidence: c02L1Ev,
            allocatedBytes: 1_073_741_823,
            safetyGatePassed: true,
            store: kb.authored
        )
        let c02L1At = JunkCacheRecommendationPolicy.evaluate(
            url: xcodeOrphan,
            unitURL: xcodeOrphan,
            unitIdentity: xcodeOrphanIdentity,
            ruleEvidence: c02L1Ev,
            allocatedBytes: 1_073_741_824,
            safetyGatePassed: true,
            store: kb.authored
        )
        let xcodeDerived = p1Home.appendingPathComponent("Library/Developer/Xcode/DerivedData/MyProject-abcd")
        try fm.createDirectory(at: xcodeDerived, withIntermediateDirectories: true)
        try Data(repeating: 0x51, count: 1024).write(to: xcodeDerived.appendingPathComponent("info.plist"))
        let xcodeDerivedIdentity = FileIdentity.capture(from: xcodeDerived)
        let c02L2Ev = CleanupRuleEvidence(id: "JC.DEV.XCODE.DERIVED.LIVE", tier: .review, reason: .generalCache, defaultSelected: false)
        let c02L2Below = JunkCacheRecommendationPolicy.evaluate(
            url: xcodeDerived,
            unitURL: xcodeDerived,
            unitIdentity: xcodeDerivedIdentity,
            ruleEvidence: c02L2Ev,
            allocatedBytes: 1_073_741_823,
            safetyGatePassed: true,
            store: kb.authored
        )
        let c02L2At = JunkCacheRecommendationPolicy.evaluate(
            url: xcodeDerived,
            unitURL: xcodeDerived,
            unitIdentity: xcodeDerivedIdentity,
            ruleEvidence: c02L2Ev,
            allocatedBytes: 1_073_741_824,
            safetyGatePassed: true,
            store: kb.authored
        )
        let c02L2Above = JunkCacheRecommendationPolicy.evaluate(
            url: xcodeDerived,
            unitURL: xcodeDerived,
            unitIdentity: xcodeDerivedIdentity,
            ruleEvidence: c02L2Ev,
            allocatedBytes: 1_073_741_825,
            safetyGatePassed: true,
            store: kb.authored
        )
        check(c02L1Below.state == .ordinary
              && c02L1Below.automaticAllowed == true
              && c02L1Below.thresholdBytes == 1_073_741_824
              && c02L1At.state == .suggestedLarge
              && c02L1At.automaticAllowed == false,
              "C02.1: L1 dev cache < 1 GiB is ordinary (automaticAllowed=true) and == 1 GiB (1,073,741,824) is suggestedLarge")
        check(c02L2Below.state == .ordinary
              && c02L2Below.automaticAllowed == false
              && c02L2At.state == .suggestedLarge
              && c02L2At.automaticAllowed == false
              && c02L2Above.state == .suggestedLarge
              && c02L2Above.automaticAllowed == false
              && c02L2At.reasons.contains(.thresholdReached),
              "C02.2: L2 dev cache < 1 GiB is ordinary with automaticAllowed=false (defaultSelected=false) and == 1 GiB / 1,073,741,825 is suggestedLarge")

        // C03: 1000 个 600 KiB 子项合计 614,400,000 bytes -> 挂父级建议，自动模式整单元拦截，手动确认可执行
        let npmCacacheRoot = p1Home.appendingPathComponent(".npm/_cacache")
        try? fm.removeItem(at: npmCacacheRoot.appendingPathComponent("payload.bin"))
        let npmContentV2 = npmCacacheRoot.appendingPathComponent("content-v2")
        let npmIndexV5 = npmCacacheRoot.appendingPathComponent("index-v5")
        try fm.createDirectory(at: npmContentV2, withIntermediateDirectories: true)
        try fm.createDirectory(at: npmIndexV5, withIntermediateDirectories: true)
        try Data(repeating: 0x45, count: 1024).write(to: npmContentV2.appendingPathComponent("shard1"))
        try Data(repeating: 0x46, count: 1024).write(to: npmIndexV5.appendingPathComponent("shard2"))
        FastDirectoryInspector.allocatedBytesOverrideForTesting = { p in
            if p == npmContentV2.path || p == npmIndexV5.path {
                return 600_000_000
            }
            return nil
        }
        var c03ContainerItem = ScanItem(url: npmCacacheRoot, name: "_cacache", size: 0, safety: .safe, isSelected: true)
        c03ContainerItem.ruleEvidence = CleanupRuleEvidence(id: "JC.DEV.NPM.CACACHE", tier: .review, reason: .generalCache, defaultSelected: false)
        let evalC03 = JunkRulePolicy.apply(c03ContainerItem)
        FastDirectoryInspector.allocatedBytesOverrideForTesting = nil
        check(evalC03.cacheRecommendation?.state == .suggestedLarge
              && evalC03.cacheRecommendation?.allocatedBytes == 1_200_000_000
              && evalC03.cacheRecommendation?.automaticAllowed == false
              && evalC03.isSelected == false
              && !evalC03.children.isEmpty
              && evalC03.children.allSatisfy {
                  $0.cacheRecommendation?.state == .suggestedLarge
                  && $0.cacheRecommendation?.automaticAllowed == false
                  && $0.selectionRestrictions.contains(.largeCache)
                  && $0.isSelected == false
              },
              "C03: Multi-child cache unit exceeding threshold attaches suggestedLarge to parent and propagates largeCache restriction to children")

        // C04: 无 cm_cache_profile 未知目录 700 MiB -> unknownReview，不显示可重建，不进自动执行
        let c04UnknownDir = p1Home.appendingPathComponent("Library/Caches/com.unknown.c04vendor")
        try fm.createDirectory(at: c04UnknownDir, withIntermediateDirectories: true)
        try Data(repeating: 0x52, count: 1024).write(to: c04UnknownDir.appendingPathComponent("blob.bin"))
        let c04Identity = FileIdentity.capture(from: c04UnknownDir)
        let c04Snap = JunkCacheRecommendationPolicy.evaluate(
            url: c04UnknownDir,
            unitURL: c04UnknownDir,
            unitIdentity: c04Identity,
            ruleEvidence: CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic, reason: .generalCache, defaultSelected: true),
            allocatedBytes: 700 * 1024 * 1024,
            safetyGatePassed: true,
            store: kb.authored
        )
        check(c04Snap.state == .unknownReview
              && c04Snap.reasons.contains(.profileMissing)
              && c04Snap.automaticAllowed == false
              && JunkCacheRecommendationPolicy.localizedLargeBadge(for: c04Snap) == nil
              && JunkCacheRecommendationPolicy.localizedEffects(for: c04Snap) == [L10n.localized(.junkCacheEffectUnknown)],
              "C04: Unregistered 700 MiB directory evaluates to unknownReview without rebuildable badge and is excluded from automatic execution")

        // C05: 成本未知或影响为空 -> unknownReview，自动排除，不默认勾选
        let c05NoCost = JunkCacheRecommendationPolicy.evaluate(
            url: slackCacheData,
            unitURL: slackCacheData,
            unitIdentity: slackCacheDataIdentity,
            ruleEvidence: c01Ev,
            allocatedBytes: 4096,
            safetyGatePassed: true,
            store: kb.authored,
            overrideRuleCost: RebuildCost.none,
            overrideProfileCost: RebuildCost.none
        )
        let c05NoEffects = JunkCacheRecommendationPolicy.evaluate(
            url: slackCacheData,
            unitURL: slackCacheData,
            unitIdentity: slackCacheDataIdentity,
            ruleEvidence: c01Ev,
            allocatedBytes: 4096,
            safetyGatePassed: true,
            store: kb.authored,
            overrideEffects: []
        )
        check(c05NoCost.state == .unknownReview
              && c05NoCost.automaticAllowed == false
              && c05NoCost.reasons.contains(.unknownCost)
              && c05NoEffects.state == .unknownReview
              && c05NoEffects.automaticAllowed == false,
              "C05: Unknown rebuild cost (.none) or empty rebuild effects evaluates to unknownReview and blocks automatic mode")

        // C10: 多采样源命中同一真实路径（软硬链接/父子重叠） -> scanFullInspectionCount == 1，复用 >= 1
        let c10RealDir = p1Home.appendingPathComponent("Library/Caches/com.example.c10real")
        try fm.createDirectory(at: c10RealDir, withIntermediateDirectories: true)
        try Data(repeating: 0x61, count: 4096).write(to: c10RealDir.appendingPathComponent("a.bin"))
        let c10Ctx = IOScanContext(stopped: { false })
        c10Ctx.perform {
            IOScanContext.registerCandidate(url: c10RealDir, scannerID: "scannerA", ruleID: "JC.CACHE.USER", tier: .automatic)
            IOScanContext.registerCandidate(url: c10RealDir, scannerID: "scannerB", ruleID: "JC.CACHE.USER", tier: .automatic)
            _ = FastDirectoryInspector.inspect(c10RealDir, parentRuleID: "JC.CACHE.USER")
            _ = FastDirectoryInspector.inspect(c10RealDir, parentRuleID: "JC.CACHE.USER")
        }
        let c10Tel = c10Ctx.telemetrySnapshot
        check(c10Tel.scanFullInspectionCount == 1
              && c10Tel.inspectionReuseCount >= 1
              && c10Tel.mergedDiscoveryCount >= 1,
              "C10: Multiple discovery registrations and inspections on the same realpath + FileIdentity execute 1 full scan inspection and reuse >= 1")

        // C11: 忽略列表变更或目录 mtime/FileIdentity 变化 -> 旧结果失效，inspectionRetryCount == 1
        let c11Dir = p1Home.appendingPathComponent("Library/Caches/com.example.c11dir")
        let c11DummyIgnore = base.appendingPathComponent("c11_dummy_ignore").path
        try fm.createDirectory(at: c11Dir, withIntermediateDirectories: true)
        try Data(repeating: 0x62, count: 2048).write(to: c11Dir.appendingPathComponent("b.bin"))
        let c11Ctx = IOScanContext(stopped: { false })
        c11Ctx.perform {
            _ = FastDirectoryInspector.inspect(c11Dir, parentRuleID: "JC.CACHE.USER")
            AppConfigStore.shared.addIgnoredPath(c11DummyIgnore)
            _ = FastDirectoryInspector.inspect(c11Dir, parentRuleID: "JC.CACHE.USER")
            AppConfigStore.shared.removeIgnoredPath(c11DummyIgnore)
        }
        let c11Tel = c11Ctx.telemetrySnapshot
        check(c11Tel.scanFullInspectionCount == 2 && c11Tel.inspectionRetryCount == 1,
              "C11: Changing ignorePolicyVersion invalidates cached receipt and increments inspectionRetryCount == 1")

        // C12: 同一 IOScanContext 先以宽松规则注册，后以更严规则/Protected owner 注册 -> 合并记录更新为严格证据，触发复检
        let c12Dir = pipMacosDir
        try fm.createDirectory(at: c12Dir, withIntermediateDirectories: true)
        try Data(repeating: 0x63, count: 2048).write(to: c12Dir.appendingPathComponent("c.bin"))
        let c12Ctx = IOScanContext(stopped: { false })
        var c12WinnerRuleID: String? = nil
        c12Ctx.perform {
            IOScanContext.registerCandidate(url: c12Dir, scannerID: "scanLoose", ruleID: "JC.CACHE.USER", tier: .automatic)
            _ = FastDirectoryInspector.inspect(c12Dir, parentRuleID: "JC.CACHE.USER")
            var c12Loose = ScanItem(url: c12Dir, name: "pip", size: 2048, safety: .safe, isSelected: true)
            c12Loose.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic, reason: .generalCache, defaultSelected: true)
            var c12Strict = ScanItem(url: c12Dir, name: "pip", size: 2048, safety: .caution, isSelected: false)
            c12Strict.ruleEvidence = CleanupRuleEvidence(id: "JC.DEV.PKG.SAFE", tier: .review, reason: .generalCache, defaultSelected: false)
            let c12Dedup = RuleAwareDeduplicator.deduplicate([c12Loose, c12Strict])
            c12WinnerRuleID = c12Dedup.items.first?.ruleEvidence?.id
            _ = FastDirectoryInspector.inspect(c12Dir, parentRuleID: c12WinnerRuleID)
        }
        let c12Tel = c12Ctx.telemetrySnapshot
        check(c12WinnerRuleID == "JC.DEV.PKG.SAFE"
              && c12Tel.inspectionRetryCount >= 1
              && c12Tel.scanFullInspectionCount == 2,
              "C12: Registering stricter rule after permissive rule updates winner to stricter evidence and triggers inspection retry")

        // C13: 非 children-only 普通目录 -> JunkRulePolicy.makeMeasuredCandidate + JunkRulePolicy.apply -> scanFullInspectionCount == 1
        let c13Ctx = IOScanContext(stopped: { false })
        var c13Applied: ScanItem? = nil
        c13Ctx.perform {
            if let cand = JunkRulePolicy.makeMeasuredCandidate(
                url: xcodeDerived,
                name: "MyProject-abcd",
                note: "C13 Single Pass",
                safety: .safe,
                minBytes: 0
            ) {
                c13Applied = JunkRulePolicy.apply(cand)
            }
        }
        let c13Tel = c13Ctx.telemetrySnapshot
        check(c13Applied != nil
              && c13Tel.scanFullInspectionCount == 1
              && c13Tel.inspectionReuseCount >= 1,
              "C13: makeMeasuredCandidate + JunkRulePolicy.apply performs single-pass directory inspection on non-children-only directory (scanFullInspectionCount == 1)")

        // C15: 扫描后缓存增长跨过 500 MiB 阈值，或新写入受保护文件 -> 执行前复检拦截，executionFullInspectionCount == 1
        let c15Ctx = IOScanContext(stopped: { false })
        var c15Outcome: CleanOutcome? = nil
        c15Ctx.perform {
            var c15Item = ScanItem(url: slackGPUCache, name: "GPUCache", size: 1024, safety: .safe, isSelected: true)
            c15Item.ruleEvidence = c01Ev
            c15Item = JunkRulePolicy.apply(c15Item)
            let c15Target = CleanTarget(Node.item(from: c15Item), executionMode: .automatic)
            FastDirectoryInspector.allocatedBytesOverrideForTesting = { p in
                p == slackGPUCache.path ? 600_000_000 : nil
            }
            c15Outcome = Cleaner.clean(c15Target)
            FastDirectoryInspector.allocatedBytesOverrideForTesting = nil
        }
        let c15Tel = c15Ctx.telemetrySnapshot
        check(c15Tel.executionFullInspectionCount == 1
              && c15Outcome?.ok == false,
              "C15: Cache unit growing past 500 MiB after scan is re-inspected before execution (executionFullInspectionCount == 1) and blocked in automatic mode")

        // C16: 扫描产生 suggestedLarge 的 L1 缓存项，未手动勾选 -> isSelected == false；automatic 被拒绝；manual 允许进入受控删除
        FastDirectoryInspector.allocatedBytesOverrideForTesting = { p in
            p == slackGPUCache.path ? 600_000_000 : nil
        }
        var c16ScanCand = ScanItem(url: slackGPUCache, name: "GPUCache", size: 600_000_000, safety: .safe, isSelected: true)
        c16ScanCand.ruleEvidence = c01Ev
        let c16Evaluated = JunkRulePolicy.apply(c16ScanCand)
        let c16AutoTarget = CleanTarget(Node.item(from: c16Evaluated), executionMode: .automatic)
        let c16AutoOutcome = Cleaner.clean(c16AutoTarget)
        var c16ManualItem = c16Evaluated
        c16ManualItem.isSelected = true
        let c16ManualTarget = CleanTarget(Node.item(from: c16ManualItem), executionMode: .manual)
        let c16ManualOutcome = Cleaner.clean(c16ManualTarget)
        FastDirectoryInspector.allocatedBytesOverrideForTesting = nil
        check(c16Evaluated.cacheRecommendation?.state == .suggestedLarge
              && c16Evaluated.isSelected == false
              && c16AutoOutcome.ok == false
              && c16ManualOutcome.ok == true,
              "C16.1: L1 suggestedLarge defaults to isSelected == false, is blocked in automatic mode, and succeeds in manual mode when explicitly confirmed")
        let c16State = AppState()
        c16State.moduleKey = "junk"
        let c16Node = Node.item(from: c16Evaluated)
        c16State.roots = [c16Node]
        c16State.setSelection(c16Node, true)
        let c16SelectedBeforeRefresh = c16State.selection
        let c16PrevIdentities = Dictionary(uniqueKeysWithValues: c16State.roots.allLeaves.compactMap { l in l.fileIdentity.map { (l.id, $0) } })
        var c16LockedNode = c16Node
        c16LockedNode.locked = true
        for i in c16LockedNode.children.indices { c16LockedNode.children[i].locked = true }
        c16State.roots = [c16LockedNode]
        c16State.reconcileSelectionAfterRefresh(previousIdentities: c16PrevIdentities)
        check(!c16SelectedBeforeRefresh.isEmpty && c16State.selection.isEmpty,
              "C16.2: User manual selection is preserved across UI refresh and forcibly cleared only when target becomes safety-locked")

        // C17: 单条规则对应多个 cm_cache_profile -> 按真实路径最长匹配选择唯一直属 Profile；且 ruleCost=.low + profileCost=.medium 展示 medium 及实际 effect
        let goBuildDir = p1Home.appendingPathComponent("Library/Caches/go-build")
        try fm.createDirectory(at: pipMacosDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: goBuildDir, withIntermediateDirectories: true)
        try Data(repeating: 0x64, count: 1024).write(to: pipMacosDir.appendingPathComponent("sym.bin"))
        try Data(repeating: 0x65, count: 1024).write(to: goBuildDir.appendingPathComponent("go.bin"))
        let c17PkgSafeEv = CleanupRuleEvidence(id: "JC.DEV.PKG.SAFE", tier: .review, reason: .generalCache, defaultSelected: false)
        let c17PipSnap = JunkCacheRecommendationPolicy.evaluate(
            url: pipMacosDir,
            unitURL: pipMacosDir,
            unitIdentity: FileIdentity.capture(from: pipMacosDir),
            ruleEvidence: c17PkgSafeEv,
            allocatedBytes: 4096,
            safetyGatePassed: true,
            store: kb.authored
        )
        let c17GoBuildSnap = JunkCacheRecommendationPolicy.evaluate(
            url: goBuildDir,
            unitURL: goBuildDir,
            unitIdentity: FileIdentity.capture(from: goBuildDir),
            ruleEvidence: c17PkgSafeEv,
            allocatedBytes: 4096,
            safetyGatePassed: true,
            store: kb.authored
        )
        let c17LowMedSnap = JunkCacheRecommendationPolicy.evaluate(
            url: slackCacheData,
            unitURL: slackCacheData,
            unitIdentity: slackCacheDataIdentity,
            ruleEvidence: c01Ev,
            allocatedBytes: 4096,
            safetyGatePassed: true,
            store: kb.authored,
            overrideRuleCost: .low,
            overrideProfileCost: .medium
        )
        check(c17PipSnap.profileID == "pip-macos"
              && c17PipSnap.effects == [.redownload]
              && c17GoBuildSnap.profileID == "go-build-macos"
              && c17GoBuildSnap.effects == [.recompile]
              && c17LowMedSnap.effectiveCost == .medium
              && !c17LowMedSnap.effects.isEmpty,
              "C17: Multiple profiles under JC.DEV.PKG.SAFE resolve uniquely by longest canonical path, and ruleCost=.low + profileCost=.medium resolves to medium with concrete effect")

        // C18: cm_junk_rule.rebuild_cost 与 cm_cache_profile.cost_override 同时存在 -> 取 max(ruleCost, overrideCost)；且 ScanItem->Node->reconcile->CleanTarget 字段不丢失
        let c18Snap1 = JunkCacheRecommendationPolicy.evaluate(
            url: slackCacheData,
            unitURL: slackCacheData,
            unitIdentity: slackCacheDataIdentity,
            ruleEvidence: c01Ev,
            allocatedBytes: 4096,
            safetyGatePassed: true,
            store: kb.authored,
            overrideRuleCost: .high,
            overrideProfileCost: .low
        )
        let c18Snap2 = JunkCacheRecommendationPolicy.evaluate(
            url: slackCacheData,
            unitURL: slackCacheData,
            unitIdentity: slackCacheDataIdentity,
            ruleEvidence: c01Ev,
            allocatedBytes: 4096,
            safetyGatePassed: true,
            store: kb.authored,
            overrideRuleCost: .low,
            overrideProfileCost: .high
        )
        var c18Item = ScanItem(url: xcodeDerived, name: "MyProject-abcd", size: 4096, safety: .caution, isSelected: false)
        c18Item.ruleEvidence = c02L2Ev
        c18Item = JunkRulePolicy.apply(c18Item)
        var c18Items = [c18Item]
        let c18Dedup = RuleAwareDeduplicator()
        c18Dedup.reconcile(items: &c18Items)
        let c18Node = Node.item(from: c18Items[0])
        let c18Target = CleanTarget(c18Node, executionMode: .manual)
        check(c18Snap1.effectiveCost == .high
              && c18Snap2.effectiveCost == .high
              && c18Target.cacheRecommendation?.profileID == c18Item.cacheRecommendation?.profileID
              && c18Target.cacheRecommendation?.unitPath == c18Item.cacheRecommendation?.unitPath
              && c18Target.cacheRecommendation?.allocatedBytes == c18Item.cacheRecommendation?.allocatedBytes
              && c18Target.cacheRecommendation?.effects == c18Item.cacheRecommendation?.effects
              && c18Target.cacheRecommendation?.state == c18Item.cacheRecommendation?.state
              && c18Target.cacheRecommendation?.automaticAllowed == c18Item.cacheRecommendation?.automaticAllowed,
              "C18: Effective rebuild cost takes max(ruleCost, overrideCost) and ScanItem->reconcile->Node->CleanTarget preserves all cacheRecommendation fields")

        // C19: 稀疏文件逻辑大小 2 GiB 与硬链接重复文件 -> 按实际分配块且同一 (dev, ino) 只计一次，不误报大缓存
        let c19Dir = p1Home.appendingPathComponent("Library/Caches/com.example.c19sparse")
        try fm.createDirectory(at: c19Dir, withIntermediateDirectories: true)
        let c19File1 = c19Dir.appendingPathComponent("hardlink_a.bin")
        let c19File2 = c19Dir.appendingPathComponent("hardlink_b.bin")
        try Data(repeating: 0x77, count: 65536).write(to: c19File1)
        try? fm.removeItem(at: c19File2)
        _ = Darwin.link(c19File1.path, c19File2.path)
        let c19SingleInspect = FastDirectoryInspector.inspect(c19File1)
        let c19DirInspect = FastDirectoryInspector.inspect(c19Dir)
        let c19SparseFile = c19Dir.appendingPathComponent("sparse_2gib.bin")
        let sparseFD = Darwin.open(c19SparseFile.path, O_CREAT | O_TRUNC | O_RDWR, S_IRUSR | S_IWUSR)
        if sparseFD >= 0 {
            _ = Darwin.ftruncate(sparseFD, off_t(2 * 1024 * 1024 * 1024))
            Darwin.close(sparseFD)
        }
        let c19AfterSparse = FastDirectoryInspector.inspect(c19Dir)
        check(c19DirInspect.physicalBytes == c19SingleInspect.physicalBytes
              && c19AfterSparse.physicalBytes < 524_288_000,
              "C19: Hard-linked files with identical (dev, ino) are counted once and a 2 GiB sparse file uses physical st_blocks*512 (< 500 MiB)")

        // C22: 父级单元已产生 suggestedLarge，执行器收到手动构造的子文件 CleanTarget -> 执行前向上解析所属缓存单元重算，自动模式拒绝删除该子文件
        let c22ChildURL = slackCacheData.appendingPathComponent("inner.bin")
        FastDirectoryInspector.allocatedBytesOverrideForTesting = { p in
            p == slackCacheData.path ? 600_000_000 : nil
        }
        var c22ChildItem = ScanItem(url: c22ChildURL, name: "inner.bin", size: 4096, safety: .safe, isSelected: true)
        c22ChildItem.ruleEvidence = c01Ev
        let c22ChildTarget = CleanTarget(Node.item(from: c22ChildItem), executionMode: .automatic)
        let c22AutoOutcome = Cleaner.clean(c22ChildTarget)
        FastDirectoryInspector.allocatedBytesOverrideForTesting = nil
        check(c22AutoOutcome.ok == false,
              "C22: Manually constructed child CleanTarget inside a >= 500 MiB cache unit resolves parent unit before execution and is blocked in automatic mode")

        // C23: UninstallerUndoManager 卸载批次快照记录与原路撤销还原验证
        let undoTestStorage = p1Home.appendingPathComponent("undo_test_records.json")
        let undoManager = UninstallerUndoManager(storageURL: undoTestStorage)

        let origAppDir = p1Home.appendingPathComponent("Applications/DemoUndo.app")
        let origCacheDir = p1Home.appendingPathComponent("Library/Caches/com.demo.undo")
        let trashAppDir = p1Home.appendingPathComponent(".Trash/DemoUndo.app")
        let trashCacheDir = p1Home.appendingPathComponent(".Trash/com.demo.undo")

        try fm.createDirectory(at: trashAppDir, withIntermediateDirectories: true)
        try Data("binary".utf8).write(to: trashAppDir.appendingPathComponent("DemoUndo"))
        try fm.createDirectory(at: trashCacheDir, withIntermediateDirectories: true)
        try Data("cache".utf8).write(to: trashCacheDir.appendingPathComponent("cache.db"))

        let undoItems = [
            UninstallUndoItem(originalPath: origAppDir.path, trashPath: trashAppDir.path, size: 4096, isAppBody: true),
            UninstallUndoItem(originalPath: origCacheDir.path, trashPath: trashCacheDir.path, size: 2048, isAppBody: false)
        ]
        undoManager.recordBatch(appName: "DemoUndo", bundleID: "com.demo.undo", items: undoItems)

        let loadedBatches = undoManager.loadBatches()
        check(loadedBatches.count == 1 && loadedBatches[0].appName == "DemoUndo" && loadedBatches[0].canRestore,
              "C23.1: UninstallerUndoManager successfully records batch and verifies canRestore condition")

        let batchToRestore = loadedBatches[0]
        try undoManager.restoreBatch(id: batchToRestore.id)

        check(fm.fileExists(atPath: origAppDir.path) && fm.fileExists(atPath: origCacheDir.path)
              && !fm.fileExists(atPath: trashAppDir.path) && !fm.fileExists(atPath: trashCacheDir.path)
              && undoManager.loadBatches().isEmpty,
              "C23.2: restoreBatch restores all files to exact original paths and clears batch from undo log")

        // C24: xcrun simctl delete unavailable 动作与系统回收契约验证
        let unavailableAction = ItemAction.simctlDeleteUnavailable
        check(unavailableAction.label == L10n.localized(.actionDeleteUnavailableSimulators),
              "C24.1: simctlDeleteUnavailable action label localized correctly")
        let unavailableTarget = CleanTarget(name: "Unavailable Simulators", url: nil, size: 1024 * 1024, action: .simctlDeleteUnavailable, executionMode: .manual)
        let origDryRun = Cleaner.isDryRun
        Cleaner.isDryRun = true
        let dryRunOutcome = Cleaner.clean(unavailableTarget)
        Cleaner.isDryRun = origDryRun
        check(dryRunOutcome.ok && dryRunOutcome.actionCategory == CleanActionCategory.permanentlyDeleted,
              "C24.2: Cleaner dry-run for simctlDeleteUnavailable returns permanentlyDeleted outcome")
    }
}

// Captured pre-fix implementation, benchmark only; never used by production execution.
import Foundation
import Darwin

/// Bounded read-only snapshot. Incomplete process inspection is never treated as idle.
enum BaselineOpenFileGuard {
    static func overlaps(_ target: URL, openPath: String) -> Bool {
        let root = SymlinkGuard.canonicalizeMacOSSystemPrefix(target.resolvingSymlinksInPath().standardizedFileURL.path)
        let path = SymlinkGuard.canonicalizeMacOSSystemPrefix(URL(fileURLWithPath: openPath).resolvingSymlinksInPath().standardizedFileURL.path)
        return path == root || path.hasPrefix(root + "/")
            || path == root + "-wal" || path == root + "-shm" || path == root + "-journal"
            || root == path + "-wal" || root == path + "-shm" || root == path + "-journal"
    }

    static let lock = NSLock()
    static var selectionSnapshot: (time: TimeInterval, paths: [String]?)?
    static func openPaths(fresh: Bool) -> [String]? {
        let now = ProcessInfo.processInfo.systemUptime
        if !fresh {
            lock.lock()
            let cached = selectionSnapshot
            lock.unlock()
            if let cached, now - cached.time < AppConfig.Security.openFileSelectionCacheTTL { return cached.paths }
        }
        let result = Shell.execute(AppConfig.Security.lsofPath,
            AppConfig.Remediation.lsofArguments + ["-u", String(getuid())], timeout: AppConfig.Security.fileHandleCheckTimeout)
        guard result.isSuccess, result.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              result.stdout.contains("\np") || result.stdout.hasPrefix("p") else { return nil }
        let paths = result.stdout.split(separator: "\n").filter { $0.hasPrefix("n/") }.map { String($0.dropFirst()) }
        if !fresh {
            lock.lock(); selectionSnapshot = (now, paths); lock.unlock()
        }
        return paths
    }
    static func isIdle(_ target: URL, fresh: Bool = true) -> Bool {
        guard let paths = openPaths(fresh: fresh) else { return false }
        return !paths.contains { overlaps(target, openPath: $0) }
    }
}

struct MetadataFailureFileSystem: DirectoryFileSystemProviding {
    let failing: StopFlag
    func children(of url: URL, keys: Set<URLResourceKey>) throws -> [URL] {
        try LocalDirectoryFileSystem().children(of: url, keys: keys)
    }
    func metadata(of url: URL, keys: Set<URLResourceKey>) throws -> URLResourceValues {
        if failing.value && url.lastPathComponent == "denied.bin" { throw CocoaError(.fileReadNoPermission) }
        return try LocalDirectoryFileSystem().metadata(of: url, keys: keys)
    }
    func measure(_ url: URL) -> FileSizeMeasurement { FileUtil.measureSize(of: url) }
}
