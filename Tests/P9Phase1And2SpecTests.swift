import Foundation
import AppKit
import SQLite3

extension P9CrossReviewFixTests {
    // MARK: - Phase 1 (CM-JUNK-T01 ~ T04): A01 ~ A06, A15, A16 授权与安全夹具回归
    func phase1JunkSpecVerification(published: URL) async throws {
        let kb = KnowledgeBaseManager.shared
        let previousHome = FileUtil.homeOverrideForTesting
        let phase1DB = base.appendingPathComponent("phase1_rules.db")
        try? fm.removeItem(at: phase1DB)
        try fm.copyItem(at: published, to: phase1DB)
        let p1Home = base.appendingPathComponent("p1home")
        try? fm.removeItem(at: p1Home)
        try fm.createDirectory(at: p1Home, withIntermediateDirectories: true)
        let escapedHome = p1Home.path.replacingOccurrences(of: "'", with: "''")
        try sql("""
            UPDATE cm_discovery_binding SET path_template=replace(path_template,'~/','\(escapedHome)/');
            UPDATE cm_protected_path SET path_template=replace(path_template,'~/','\(escapedHome)/');
            INSERT OR REPLACE INTO cm_electron_data_dir(bundle_id,dir_name) VALUES ('org.cleanmate.p9.code','P9Code');
        """, db: phase1DB)
        FileUtil.homeOverrideForTesting = p1Home
        try kb.load(from: phase1DB)
        defer {
            FileUtil.homeOverrideForTesting = previousHome
            ProcessGuard.runningProcessNamesOverrideForTesting = nil
            ProcessGuard.runningBundleIDsOverrideForTesting = nil
            ProcessGuard.simulateProcessEnumerationFailureForTesting = false
            OpenFileGuard.openPathsOverrideForTesting = nil
            OpenFileGuard.simulateInspectionFailureForTesting = false
            DeveloperArtifactPolicy.currentWorkingDirectoryOverrideForTesting = nil
            FileIdentity.uidOverrideForTesting = nil
            Cleaner.isDryRun = true
            try? kb.load(from: published)
        }
        Cleaner.isDryRun = true

        func p1File(_ rel: String, data: Data = Data([0xCA, 0xFE, 0xBA, 0xBE])) throws -> URL {
            let url = p1Home.appendingPathComponent(rel)
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
            return url
        }

        let store = kb.authored

        // =========================================================================
        // A01 — CM-JUNK-T01: ~/.pub-cache 全子树只读保护
        // =========================================================================
        check(!AppConfig.JunkScan.packageManagerSpecs.contains(where: { $0.rawPath.contains(".pub-cache") }),
              "A01: ~/.pub-cache removed from AppConfig.JunkScan.packageManagerSpecs")
        check(store.junk["JC.DEV.PKG.L2"]?.paths.contains(where: { $0.contains(".pub-cache") }) == false,
              "A01: ~/.pub-cache removed from JC.DEV.PKG.L2 paths")
        check(store.junk[AppConfig.RuleIDs.pubAsset]?.tier == .readOnly
              && store.junk[AppConfig.RuleIDs.pubAsset]?.action == "read_only"
              && store.junk[AppConfig.RuleIDs.pubAsset]?.selected == false,
              "A01: JC.DEV.PUB.ASSET is L3 / read_only / default_selected=0")

        let pubHosted = try p1File(".pub-cache/hosted/pub.dev/http-1.2.0/lib/http.dart")
        let pubBin = try p1File(".pub-cache/bin/fvm")
        let pubGit = try p1File(".pub-cache/git/my_pkg-9f8e7d/.git/HEAD")
        let pubGlobal = try p1File(".pub-cache/global_packages/melos/pubspec.lock")
        let pubRoot = p1Home.appendingPathComponent(".pub-cache")

        for targetURL in [pubRoot, pubHosted, pubBin, pubGit, pubGlobal] {
            check(CleanupSafetyPolicy.isProtectedAsset(targetURL),
                  "A01: CleanupSafetyPolicy.isProtectedAsset blocks \(targetURL.lastPathComponent)")
            let evaluated = JunkRulePolicy.apply(ScanItem(url: targetURL, name: targetURL.lastPathComponent, size: 64, safety: .safe, isSelected: true))
            check(evaluated.locked == true
                  && evaluated.isSelected == false
                  && evaluated.ruleEvidence?.id == AppConfig.RuleIDs.pubAsset
                  && evaluated.ruleEvidence?.tier == .readOnly
                  && evaluated.evaluationReason == .protectedAssetBlocked,
                  "A01: JunkRulePolicy locks \(targetURL.lastPathComponent) as L3 read_only with protectedAssetBlocked")
            let cleanOut = Cleaner.clean(CleanTarget(Node.item(from: evaluated)))
            check(!cleanOut.ok && cleanOut.actionCategory == .skipped && fm.fileExists(atPath: targetURL.path),
                  "A01: Cleaner.clean rejects \(targetURL.lastPathComponent) and preserves file on disk")
        }

        // =========================================================================
        // A02 — CM-JUNK-T02: JetBrains 6 叶缓存、非法版本名与进程锁
        // =========================================================================
        check(store.junk[AppConfig.RuleIDs.jetBrainsCache]?.tier == .review
              && store.junk[AppConfig.RuleIDs.jetBrainsCache]?.action == "trash_children_only"
              && store.junk[AppConfig.RuleIDs.jetBrainsCache]?.selected == false
              && store.junk[AppConfig.RuleIDs.jetBrainsCache]?.paths.count == 6,
              "A02: JC.DEV.JETBRAINS.CACHE is L2 / trash_children_only / default_selected=0 with 6 glob leaves")
        check(store.junk[AppConfig.RuleIDs.userCache]?.excludedNames.contains(where: { $0.caseInsensitiveCompare("JetBrains") == .orderedSame }) == true,
              "A02: JC.CACHE.USER excludes JetBrains")
        check(AppConfig.JunkScan.userCacheUmbrellaSkipDirs.contains("jetbrains"),
              "A02: userCacheUmbrellaSkipDirs contains jetbrains")

        // 受限版本名正则正反例校验
        for validVer in ["IntelliJIdea2024.3", "IdeaIC2024.1", "PyCharm2024.2", "PyCharmCE2024.2.1", "WebStorm2024.1.4", "RustRover2024.2"] {
            check(AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(validVer, pattern: AppConfig.JunkScan.PathMatching.jetBrainsVersionName),
                  "A02: Valid JetBrains version name accepted: \(validVer)")
        }
        for invalidVer in ["", ".", "..", ".DS_Store", "123Bad", "foo bar", "CLion2024.3-EAP", "IntelliJIdea2024.3\n", "Idea\n2024", "Idea\r2024", "Idea/2024", "Idea\02024", "A"] {
            check(!AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(invalidVer, pattern: AppConfig.JunkScan.PathMatching.jetBrainsVersionName),
                  "A02: Invalid JetBrains version name rejected: \(invalidVer.debugDescription)")
        }

        // 创建 6 个允许叶与禁止兄弟目录
        let ideaVerRel = "Library/Caches/JetBrains/IntelliJIdea2024.3"
        var allowedLeafURLs: [URL] = []
        for leaf in AppConfig.JunkScan.jetBrainsAllowedLeaves {
            let childFile = try p1File("\(ideaVerRel)/\(leaf)/payload_\(leaf).bin", data: Data(repeating: 0x42, count: 1024))
            allowedLeafURLs.append(childFile.deletingLastPathComponent())
        }
        let jbForbiddenFiles: [URL] = [
            try p1File("\(ideaVerRel)/LocalHistory/changes.storage"),
            try p1File("\(ideaVerRel)/LocalHistory/changes.storageRecordIndex"),
            try p1File("\(ideaVerRel)/port"),
            try p1File("\(ideaVerRel)/port.lock"),
            try p1File("\(ideaVerRel)/.lock"),
            try p1File("\(ideaVerRel)/plugins/custom_plugin.jar"),
            try p1File("\(ideaVerRel)/full-line/model.bin"),
            try p1File("\(ideaVerRel)/groovyHotSwap/agent.jar"),
            try p1File("\(ideaVerRel)/httpFileSystem/remote.bin")
        ]

        // 进程全部未运行（通过 override 置空真机可能运行的 java/idea 进程以确保夹具确定性）
        ProcessGuard.runningProcessNamesOverrideForTesting = []
        ProcessGuard.runningBundleIDsOverrideForTesting = []
        OpenFileGuard.openPathsOverrideForTesting = []
        // 同时测试无进程运行时的评估：先确保 currentSnapshot 中不含 11 个进程锁
        let realActiveJB = ProcessGuard.isAnyToolchainRunning(AppConfig.JunkScan.jetBrainsProcessLocks).isRunning
        if !realActiveJB {
            for leafURL in allowedLeafURLs {
                check(AuthoredRules.isValidJetBrainsLeafOrDescendant(leafURL),
                      "A02: Allowed leaf passes isValidJetBrainsLeafOrDescendant: \(leafURL.lastPathComponent)")
                let evalLeaf = JunkRulePolicy.apply(ScanItem(url: leafURL, name: leafURL.lastPathComponent, size: 1024, safety: .caution, isSelected: false))
                check(evalLeaf.locked == false
                      && evalLeaf.isSelected == false
                      && evalLeaf.action == .emptyContainer
                      && evalLeaf.ruleEvidence?.id == AppConfig.RuleIDs.jetBrainsCache
                      && evalLeaf.ruleEvidence?.tier == .review,
                      "A02: Allowed leaf \(leafURL.lastPathComponent) evaluates as unlocked L2 .emptyContainer")
            }
        }

        // 禁止兄弟目录全部被锁定且不可勾选
        for forbiddenURL in jbForbiddenFiles {
            let target = (forbiddenURL.lastPathComponent == "changes.storage"
                          || forbiddenURL.lastPathComponent == "custom_plugin.jar"
                          || forbiddenURL.lastPathComponent == "model.bin"
                          || forbiddenURL.lastPathComponent == "agent.jar"
                          || forbiddenURL.lastPathComponent == "remote.bin")
                ? forbiddenURL.deletingLastPathComponent()
                : forbiddenURL
            check(!AuthoredRules.isValidJetBrainsLeafOrDescendant(target),
                  "A02: Forbidden sibling rejected by isValidJetBrainsLeafOrDescendant: \(target.lastPathComponent)")
            let evalForbidden = JunkRulePolicy.apply(ScanItem(url: target, name: target.lastPathComponent, size: 64, safety: .safe, isSelected: true))
            check(evalForbidden.locked == true && evalForbidden.isSelected == false && evalForbidden.ruleEvidence?.tier != .automatic && evalForbidden.ruleEvidence?.tier != .review,
                  "A02: Forbidden JetBrains sibling \(target.lastPathComponent) is locked and non-executable")
        }

        // 叶名大小写错误：Caches、INDEX、Log、Tmp、Compile-Server
        for (verDirName, wrongCaseLeaf) in [
            ("PyCharm2024.1", "Caches"),
            ("PyCharm2024.2", "INDEX"),
            ("PyCharm2024.3", "Log"),
            ("PyCharmCE2024.1", "Tmp"),
            ("PyCharmCE2024.2", "Compile-Server")
        ] {
            let wrongDir = try p1File("Library/Caches/JetBrains/\(verDirName)/\(wrongCaseLeaf)/data.bin").deletingLastPathComponent()
            check(!AuthoredRules.isValidJetBrainsLeafOrDescendant(wrongDir),
                  "A02: Wrong-case leaf \(wrongCaseLeaf) rejected by isValidJetBrainsLeafOrDescendant")
            let evalWrong = JunkRulePolicy.apply(ScanItem(url: wrongDir, name: wrongCaseLeaf, size: 64, safety: .safe, isSelected: true))
            check(evalWrong.locked == true && evalWrong.isSelected == false,
                  "A02: Wrong-case leaf \(wrongCaseLeaf) is locked and never selectable")
        }

        // 11 个进程锁逐一注入验证
        let firstAllowedLeaf = allowedLeafURLs[0]
        for procName in AppConfig.JunkScan.jetBrainsProcessLocks {
            ProcessGuard.runningProcessNamesOverrideForTesting = [procName]
            let evalLocked = JunkRulePolicy.apply(ScanItem(url: firstAllowedLeaf, name: firstAllowedLeaf.lastPathComponent, size: 1024, safety: .caution, isSelected: false))
            check(evalLocked.locked == true && evalLocked.isSelected == false,
                  "A02: Running process lock [\(procName)] locks JetBrains leaf")
        }
        ProcessGuard.runningProcessNamesOverrideForTesting = nil

        // 进程枚举失败 fail-closed 验证
        ProcessGuard.simulateProcessEnumerationFailureForTesting = true
        let evalEnumFail = JunkRulePolicy.apply(ScanItem(url: firstAllowedLeaf, name: firstAllowedLeaf.lastPathComponent, size: 1024, safety: .caution, isSelected: false))
        check(evalEnumFail.locked == true && evalEnumFail.isSelected == false,
              "A02: Process enumeration failure fails closed (locks JetBrains leaf)")
        ProcessGuard.simulateProcessEnumerationFailureForTesting = false

        // =========================================================================
        // A03 — CM-JUNK-T02: JetBrains LocalHistory suffix 保护
        // =========================================================================
        let appSupportLH = try p1File("Library/Application Support/JetBrains/IntelliJIdea2024.3/LocalHistory/changes.storage")
        let cachesLH = try p1File("Library/Caches/JetBrains/IntelliJIdea2024.3/LocalHistory/changes.storage")
        for lhURL in [appSupportLH, appSupportLH.deletingLastPathComponent(), cachesLH, cachesLH.deletingLastPathComponent()] {
            check(CleanupSafetyPolicy.isProtectedAsset(lhURL),
                  "A03: LocalHistory path \(lhURL.path) is protected by suffix rule")
            let evalLH = JunkRulePolicy.apply(ScanItem(url: lhURL, name: lhURL.lastPathComponent, size: 128, safety: .safe, isSelected: true))
            check(evalLH.locked == true && evalLH.isSelected == false && evalLH.evaluationReason == .protectedAssetBlocked,
                  "A03: LocalHistory path locked with protectedAssetBlocked")
            let outLH = Cleaner.clean(CleanTarget(Node.item(from: evalLH)))
            check(!outLH.ok && outLH.actionCategory == .skipped && fm.fileExists(atPath: lhURL.path),
                  "A03: Cleaner.clean refuses to delete LocalHistory")
        }
        let nonGlobSuffixProt = AuthoredPathProtection(path: "**/LocalHistory", kind: "suffix")
        check(!nonGlobSuffixProt.matches(appSupportLH.path),
              "A03: suffix protection with '**/LocalHistory' is not treated as a wildcard glob")
        let exactSuffixProt = AuthoredPathProtection(path: "/LocalHistory", kind: "suffix")
        let lhCopyPath = p1Home.appendingPathComponent("Library/Caches/JetBrains/IntelliJIdea2024.3/LocalHistory-copy").path
        check(!exactSuffixProt.matches(lhCopyPath) && !exactSuffixProt.matches(lhCopyPath + "/file.bin"),
              "A03: suffix '/LocalHistory' does not false-match sibling 'LocalHistory-copy'")

        // =========================================================================
        // A04 — 容器子项安全失败时整容器锁定，禁止部分勾选删除
        // =========================================================================
        if !realActiveJB {
            // 1) 允许叶下混入 LocalHistory
            let leafWithLH = p1Home.appendingPathComponent("Library/Caches/JetBrains/WebStorm2024.1/caches")
            _ = try p1File("Library/Caches/JetBrains/WebStorm2024.1/caches/normal_a.bin")
            _ = try p1File("Library/Caches/JetBrains/WebStorm2024.1/caches/LocalHistory/changes.storage")
            let evalLeafWithLH = JunkRulePolicy.apply(ScanItem(url: leafWithLH, name: "caches", size: 512, safety: .caution, isSelected: false))
            check(evalLeafWithLH.locked == true
                  && evalLeafWithLH.isSelected == false
                  && evalLeafWithLH.children.allSatisfy({ $0.locked == true && !$0.isSelected }),
                  "A04.1: Allowed leaf containing LocalHistory locks the ENTIRE container and all children")

            // 2) 允许叶下混入异主子项 (uid != getuid())
            let leafWithRootChild = p1Home.appendingPathComponent("Library/Caches/JetBrains/GoLand2024.1/caches")
            let normalB = try p1File("Library/Caches/JetBrains/GoLand2024.1/caches/normal_b.bin")
            let rootOwned = try p1File("Library/Caches/JetBrains/GoLand2024.1/caches/root_owned.bin")
            let rootOwnedStd = rootOwned.standardizedFileURL.path
            FileIdentity.uidOverrideForTesting = { $0.standardizedFileURL.path == rootOwnedStd ? 0 : nil }
            let evalLeafRoot = JunkRulePolicy.apply(ScanItem(url: leafWithRootChild, name: "caches", size: 512, safety: .caution, isSelected: false))
            check(evalLeafRoot.locked == true
                  && evalLeafRoot.isSelected == false
                  && evalLeafRoot.children.allSatisfy({ $0.locked == true && !$0.isSelected }),
                  "A04.2: Allowed leaf containing foreign UID child locks the ENTIRE container")
            FileIdentity.uidOverrideForTesting = nil
            check(fm.fileExists(atPath: normalB.path) && fm.fileExists(atPath: rootOwned.path),
                  "A04.2: Both normal and foreign-UID children remain untouched")

            // 3) 允许叶下混入越界软链子项 (link -> ~/.ssh)
            let leafWithSymlink = p1Home.appendingPathComponent("Library/Caches/JetBrains/CLion2024.1/caches")
            _ = try p1File("Library/Caches/JetBrains/CLion2024.1/caches/normal_c.bin")
            let sshDir = try p1File(".ssh/id_ed25519").deletingLastPathComponent()
            let escapeLink = leafWithSymlink.appendingPathComponent("escape_ssh_link")
            try? fm.removeItem(at: escapeLink)
            try fm.createSymbolicLink(at: escapeLink, withDestinationURL: sshDir)
            let evalLeafSymlink = JunkRulePolicy.apply(ScanItem(url: leafWithSymlink, name: "caches", size: 512, safety: .caution, isSelected: false))
            check(evalLeafSymlink.locked == true
                  && evalLeafSymlink.isSelected == false
                  && evalLeafSymlink.children.allSatisfy({ $0.locked == true && !$0.isSelected }),
                  "A04.3: Allowed leaf containing symlink escape child locks the ENTIRE container")

            // 4) 全部正常子项的允许叶可人工勾选并以 .emptyContainer 执行
            let cleanJBLeaf = p1Home.appendingPathComponent("Library/Caches/JetBrains/Rider2024.2/caches")
            let cleanC1 = try p1File("Library/Caches/JetBrains/Rider2024.2/caches/c1.bin", data: Data(repeating: 0x11, count: 256))
            let cleanC2 = try p1File("Library/Caches/JetBrains/Rider2024.2/caches/c2.bin", data: Data(repeating: 0x22, count: 256))
            let evalCleanJB = JunkRulePolicy.apply(ScanItem(url: cleanJBLeaf, name: "caches", size: 512, safety: .caution, isSelected: false))
            check(evalCleanJB.locked == false
                  && evalCleanJB.action == .emptyContainer
                  && evalCleanJB.children.count == 2
                  && evalCleanJB.children.allSatisfy({ $0.locked == false }),
                  "A04.5: Clean JetBrains leaf with all normal children is unlocked with .emptyContainer")
            let dryCleanTarget = CleanTarget.emptyContainer(from: Node.item(from: evalCleanJB), executionMode: .manual)
            let dryCleanOutcome = Cleaner.clean(dryCleanTarget)
            check(dryCleanOutcome.ok && dryCleanOutcome.actionCategory == .movedToTrash,
                  "A04.5: Dry-run Cleaner.clean(.emptyContainer) succeeds on clean JetBrains leaf")

            // =====================================================================
            // A16 — 扫描后到执行前的状态变化重验 (TOCTOU)
            // =====================================================================
            // 16.1 扫描后启动 idea 进程 -> 执行期拒绝
            ProcessGuard.runningProcessNamesOverrideForTesting = ["idea"]
            let procStartOutcome = Cleaner.clean(dryCleanTarget)
            check(!procStartOutcome.ok && procStartOutcome.actionCategory == .skipped,
                  "A16.1: Cleaner.clean rejects container when JetBrains process starts after scan")
            ProcessGuard.runningProcessNamesOverrideForTesting = nil

            // 16.2 扫描后打开子文件句柄 -> 执行期拒绝
            OpenFileGuard.openPathsOverrideForTesting = [cleanC1.path]
            let openFDOutcome = Cleaner.clean(dryCleanTarget)
            check(!openFDOutcome.ok && openFDOutcome.actionCategory == .skipped,
                  "A16.2: Cleaner.clean rejects container when a child file is opened after scan")
            OpenFileGuard.openPathsOverrideForTesting = nil

            // 16.3 扫描后容器内新增未验证子项 -> 整容器中止，不删旧子项
            let postScanNew = try p1File("Library/Caches/JetBrains/Rider2024.2/caches/post_scan_new.bin")
            let newChildOutcome = Cleaner.clean(dryCleanTarget)
            check(!newChildOutcome.ok
                  && (newChildOutcome.actionCategory == .skipped || newChildOutcome.actionCategory == .failed)
                  && fm.fileExists(atPath: cleanC1.path)
                  && fm.fileExists(atPath: cleanC2.path),
                  "A16.3: Cleaner.clean aborts whole container when new unverified child appears after scan")
            try? fm.removeItem(at: postScanNew)

            // 16.4 扫描后路径被替换为软链 -> 执行期身份/软链重验拒绝
            let swappedLeaf = p1Home.appendingPathComponent("Library/Caches/JetBrains/DataGrip2024.2/caches")
            _ = try p1File("Library/Caches/JetBrains/DataGrip2024.2/caches/d1.bin")
            let evalSwapped = JunkRulePolicy.apply(ScanItem(url: swappedLeaf, name: "caches", size: 128, safety: .caution, isSelected: false))
            let swappedTarget = CleanTarget.emptyContainer(from: Node.item(from: evalSwapped), executionMode: .manual)
            try fm.removeItem(at: swappedLeaf)
            try fm.createSymbolicLink(at: swappedLeaf, withDestinationURL: sshDir)
            let swappedOutcome = Cleaner.clean(swappedTarget)
            check(!swappedOutcome.ok && fm.fileExists(atPath: sshDir.appendingPathComponent("id_ed25519").path),
                  "A16.4: Cleaner.clean rejects container replaced with symlink after scan")

            // 16.5 扫描后目标已不存在 -> 记为 absent (.missing)
            try? fm.removeItem(at: swappedLeaf)
            let absentOutcome = Cleaner.clean(swappedTarget)
            check(!absentOutcome.ok && absentOutcome.actionCategory == .absent && absentOutcome.failureKind == .missing,
                  "A16.5: Cleaner.clean reports .absent / .missing when target was deleted before execution")
        }

        // =========================================================================
        // A05 — CM-JUNK-T03: IM 账号/媒体与 Service Worker 只读保护
        // =========================================================================
        let t03ReadOnlyRuleIDs = [
            "JC.IM.WECHAT.MEDIA",
            "JC.IM.QQ",
            "JC.IM.WECOM",
            "JC.IM.TELEGRAM.MEDIA",
            "JC.ELECTRON.SW",
            "JC.BRW.CHROMIUM.SW"
        ]
        for rid in t03ReadOnlyRuleIDs {
            check(store.junk[rid]?.tier == .readOnly
                  && store.junk[rid]?.action == "read_only"
                  && store.junk[rid]?.selected == false,
                  "A05: \(rid) is L3 / read_only / default_selected=0 in DB")
        }
        check(!AppConfig.JunkScan.electronCacheSubdirs.contains("Service Worker/CacheStorage"),
              "A05: Service Worker/CacheStorage removed from AppConfig.JunkScan.electronCacheSubdirs")

        let imFixtures: [(url: URL, expectedRuleID: String)] = [
            (try p1File("Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat/2.0b4.0.9/abcd1234/Message/MessageTemp/msg.pic").deletingLastPathComponent(), "JC.IM.WECHAT.MEDIA"),
            (try p1File("Library/Containers/com.tencent.xinWeChat/Data/Documents/xwechat_files/wxid_test/msg/attach/a.dat").deletingLastPathComponent(), "JC.IM.WECHAT.MEDIA"),
            (try p1File("Library/Containers/com.tencent.qq/Data/Library/Application Support/QQ/nt_qq_123/nt_data/Pic/p.jpg").deletingLastPathComponent(), "JC.IM.QQ"),
            (try p1File("Library/Containers/com.tencent.WeWorkMac/Data/Documents/Profiles/prof1/Caches/Images/i.png").deletingLastPathComponent(), "JC.IM.WECOM"),
            (try p1File("Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram/account-123/postbox/media/m.mp4").deletingLastPathComponent(), "JC.IM.TELEGRAM.MEDIA")
        ]
        for (fixtureURL, expectedRuleID) in imFixtures {
            let evalIM = JunkRulePolicy.apply(ScanItem(url: fixtureURL, name: fixtureURL.lastPathComponent, size: 256, safety: .safe, isSelected: true))
            check(evalIM.locked == true
                  && evalIM.isSelected == false
                  && evalIM.ruleEvidence?.id == expectedRuleID
                  && evalIM.ruleEvidence?.tier == .readOnly,
                  "A05: \(expectedRuleID) fixture at \(fixtureURL.lastPathComponent) is locked L3 read_only")
            let outIM = Cleaner.clean(CleanTarget(Node.item(from: evalIM)))
            check(!outIM.ok && outIM.actionCategory == .skipped && fm.fileExists(atPath: fixtureURL.path),
                  "A05: Cleaner.clean refuses \(expectedRuleID) target")
        }

        let swFixtures: [URL] = [
            try p1File("Library/Application Support/Code/Service Worker/CacheStorage/sw.bin").deletingLastPathComponent(),
            try p1File("Library/Application Support/Google/Chrome/Default/Service Worker/CacheStorage/sw.bin").deletingLastPathComponent()
        ]
        for swURL in swFixtures {
            let evalSW = JunkRulePolicy.apply(ScanItem(url: swURL, name: swURL.lastPathComponent, size: 256, safety: .safe, isSelected: true))
            check(evalSW.locked == true
                  && evalSW.isSelected == false
                  && (evalSW.ruleEvidence == nil || evalSW.ruleEvidence?.tier == .readOnly),
                  "A05: Service Worker fixture at \(swURL.path) is locked and non-executable")
            let outSW = Cleaner.clean(CleanTarget(Node.item(from: evalSW)))
            check(!outSW.ok && outSW.actionCategory == .skipped && fm.fileExists(atPath: swURL.path),
                  "A05: Cleaner.clean refuses Service Worker target")
        }

        // =========================================================================
        // A06 — CM-JUNK-T04: Spotify 双路径只读保护
        // =========================================================================
        check(!AppConfig.RuleIDs.auditedAutoCleanUserCacheBundleIDs.contains("com.spotify.client"),
              "A06: com.spotify.client removed from auditedAutoCleanUserCacheBundleIDs")
        check(!AppConfig.JunkScan.targetedAppCacheSpecs.contains(where: { $0.rawPath.lowercased().contains("spotify") }),
              "A06: Spotify removed from AppConfig.JunkScan.targetedAppCacheSpecs")
        check(store.junk[AppConfig.RuleIDs.spotifyCache]?.tier == .readOnly
              && store.junk[AppConfig.RuleIDs.spotifyCache]?.action == "read_only"
              && store.junk[AppConfig.RuleIDs.spotifyStorage]?.tier == .readOnly
              && store.junk[AppConfig.RuleIDs.spotifyStorage]?.action == "read_only",
              "A06: Both JC.MEDIA.SPOTIFY.CACHE and JC.MEDIA.SPOTIFY are L3 / read_only")

        let spotifyCacheFile = try p1File("Library/Caches/com.spotify.client/Browser/Cache/f_0001")
        let spotifyCacheRoot = p1Home.appendingPathComponent("Library/Caches/com.spotify.client")
        let spotifyStorageFile = try p1File("Library/Application Support/Spotify/PersistentCache/Storage/offline.bnk")
        let spotifyStorageRoot = p1Home.appendingPathComponent("Library/Application Support/Spotify/PersistentCache/Storage")

        for (spURL, expectedID) in [
            (spotifyCacheRoot, AppConfig.RuleIDs.spotifyCache),
            (spotifyCacheFile, AppConfig.RuleIDs.spotifyCache),
            (spotifyStorageRoot, AppConfig.RuleIDs.spotifyStorage),
            (spotifyStorageFile, AppConfig.RuleIDs.spotifyStorage)
        ] {
            check(CleanupSafetyPolicy.isProtectedAsset(spURL),
                  "A06: CleanupSafetyPolicy.isProtectedAsset blocks Spotify path \(spURL.lastPathComponent)")
            let evalSP = JunkRulePolicy.apply(ScanItem(url: spURL, name: spURL.lastPathComponent, size: 512, safety: .safe, isSelected: true))
            check(evalSP.locked == true
                  && evalSP.isSelected == false
                  && evalSP.ruleEvidence?.id == expectedID
                  && evalSP.ruleEvidence?.tier == .readOnly
                  && evalSP.evaluationReason == .protectedAssetBlocked,
                  "A06: Spotify path \(spURL.lastPathComponent) locked as \(expectedID) L3 read_only")
            let outSP = Cleaner.clean(CleanTarget(Node.item(from: evalSP)))
            check(!outSP.ok && outSP.actionCategory == .skipped && fm.fileExists(atPath: spURL.path),
                  "A06: Cleaner.clean refuses Spotify path \(spURL.lastPathComponent)")
        }

        // =========================================================================
        // A15 — 路径归一化、软链逃逸与大小写边界
        // =========================================================================
        // 15.1 根自身是软链: .../tmp -> /private/tmp
        let symRootVer = p1Home.appendingPathComponent("Library/Caches/JetBrains/RustRover2024.2")
        try fm.createDirectory(at: symRootVer, withIntermediateDirectories: true)
        let symLeafRoot = symRootVer.appendingPathComponent("tmp")
        try? fm.removeItem(at: symLeafRoot)
        try fm.createSymbolicLink(at: symLeafRoot, withDestinationURL: URL(fileURLWithPath: "/private/tmp"))
        check(SymlinkGuard.hasSymlinkEscape(url: symLeafRoot),
              "A15.1: Symlink leaf root detected by SymlinkGuard.hasSymlinkEscape")
        let evalSymRoot = JunkRulePolicy.apply(ScanItem(url: symLeafRoot, name: "tmp", size: 64, safety: .caution, isSelected: false))
        check(evalSymRoot.locked == true && evalSymRoot.isSelected == false && evalSymRoot.evaluationReason == .symlinkEscapeBlocked,
              "A15.1: Symlink leaf root locked with symlinkEscapeBlocked")

        // 15.2 悬空软链 (broken symlink) 与自指软链 (self-loop symlink)
        let brokenLink = symRootVer.appendingPathComponent("index")
        try? fm.removeItem(at: brokenLink)
        try fm.createSymbolicLink(at: brokenLink, withDestinationURL: p1Home.appendingPathComponent("nonexistent_target_xyz"))
        check(SymlinkGuard.hasSymlinkEscape(url: brokenLink),
              "A15.2: Broken symlink detected by SymlinkGuard.hasSymlinkEscape")
        let evalBroken = JunkRulePolicy.apply(ScanItem(url: brokenLink, name: "index", size: 64, safety: .caution, isSelected: false))
        check(evalBroken.locked == true && evalBroken.evaluationReason == .symlinkEscapeBlocked,
              "A15.2: Broken symlink locked with symlinkEscapeBlocked")

        let selfLoop = symRootVer.appendingPathComponent("log")
        try? fm.removeItem(at: selfLoop)
        try fm.createSymbolicLink(atPath: selfLoop.path, withDestinationPath: selfLoop.path)
        check(SymlinkGuard.hasSymlinkEscape(url: selfLoop),
              "A15.2b: Self-referencing symlink loop detected by SymlinkGuard.hasSymlinkEscape")

        // 15.3 相对段与 .. 穿越: .../caches/../../LocalHistory
        let dotDotURL = URL(fileURLWithPath: p1Home.path + "/Library/Caches/JetBrains/IntelliJIdea2024.3/caches/../LocalHistory")
        let evalDotDot = JunkRulePolicy.apply(ScanItem(url: dotDotURL, name: "LocalHistory", size: 64, safety: .safe, isSelected: true))
        check(evalDotDot.locked == true && evalDotDot.isSelected == false && evalDotDot.evaluationReason == .protectedAssetBlocked,
              "A15.3: Relative '..' traversal to LocalHistory is normalized and blocked as protectedAssetBlocked")

        // 15.4 大小写不同根: ~/Library/Caches/jetbrains/IntelliJIdea2024.3/caches
        let lowerJBURL = URL(fileURLWithPath: p1Home.path + "/Library/Caches/jetbrains/IntelliJIdea2024.3/caches")
        check(!AuthoredRules.isValidJetBrainsLeafOrDescendant(lowerJBURL),
              "A15.4: Lowercase 'jetbrains' root rejected by isValidJetBrainsLeafOrDescendant")
        let evalLowerJB = JunkRulePolicy.apply(ScanItem(url: lowerJBURL, name: "caches", size: 64, safety: .safe, isSelected: true))
        check(evalLowerJB.locked == true && evalLowerJB.isSelected == false,
              "A15.4: Lowercase 'jetbrains' root is locked and non-selectable")

        // =========================================================================
        // Phase 2 (CM-JUNK-T05 ~ T07): A07 ~ A10, A12, A13, C09, C10, C13, C16
        // =========================================================================

        // A07: 扫描入口授权绕过修复（App Store、Xcode、Simulator、Docker、Broken Preferences/StartupItems、MobileBackups）
        let appStoreCacheDir = p1Home.appendingPathComponent("Library/Caches/com.apple.appstore")
        let appStorePayload = appStoreCacheDir.appendingPathComponent("pkg_cache.bin")
        try fm.createDirectory(at: appStoreCacheDir, withIntermediateDirectories: true)
        try Data(repeating: 0x41, count: 4096).write(to: appStorePayload)
        check(store.junk["JC.SYS.APPSTORE.CACHE"]?.tier == .review
              && store.junk["JC.SYS.APPSTORE.CACHE"]?.action == "trash_children_only"
              && store.junk["JC.SYS.APPSTORE.CACHE"]?.selected == false,
              "A07.1: JC.SYS.APPSTORE.CACHE is L2 / trash_children_only / default_selected=0")
        ProcessGuard.runningProcessNamesOverrideForTesting = ["storedownloadd"]
        if let appStoreGroupLocked = JunkEngine.scanAppStoreCache(),
           let appStoreItemLocked = appStoreGroupLocked.items.first {
            check(appStoreItemLocked.locked == true && appStoreItemLocked.isSelected == false,
                  "A07.2: scanAppStoreCache locks item when storedownloadd is running")
        } else {
            check(false, "A07.2: scanAppStoreCache should return locked group when storedownloadd is running")
        }
        ProcessGuard.runningProcessNamesOverrideForTesting = []
        ProcessGuard.runningBundleIDsOverrideForTesting = []
        if let appStoreGroupIdle = JunkEngine.scanAppStoreCache(),
           let appStoreItemIdle = appStoreGroupIdle.items.first {
            check(appStoreItemIdle.locked == false && appStoreItemIdle.isSelected == false && appStoreItemIdle.action == .emptyContainer,
                  "A07.3: scanAppStoreCache returns L2 unselected emptyContainer when idle")
        } else {
            check(false, "A07.3: scanAppStoreCache should return L2 group when idle")
        }
        ProcessGuard.runningProcessNamesOverrideForTesting = nil
        ProcessGuard.runningBundleIDsOverrideForTesting = nil

        // Xcode 合成父组 url == nil 且 Archives / Simulator 只读
        let synthSubgroup = JunkEngine.makeXcodeSubgroup(
            name: "DerivedData Subgroup",
            icon: "hammer",
            note: "test",
            items: [ScanItem(url: appStorePayload, name: "pkg_cache.bin", size: 4096, safety: .caution, isSelected: false)]
        )
        let synthNode = Node.item(from: synthSubgroup)
        check(synthNode.isGroup == true && synthNode.url == nil,
              "A07.4: makeXcodeSubgroup synthetic parent node has url == nil and isGroup == true")
        check(store.junk["JC.DEV.XCODE.ARCHIVES"]?.tier == .readOnly
              && store.junk["JC.DEV.XCODE.SIMULATOR"]?.tier == .readOnly
              && store.junk["JC.SYS.IOS.BACKUP"]?.tier == .readOnly,
              "A07.5: Archives, Simulator, and iOS Backup rules are L3 / read_only")

        // Docker host physical items go through JunkRulePolicy.apply and respect running lock
        let dockerCacheDir = p1Home.appendingPathComponent("Library/Caches/dev.kdrag0n.MacVirt")
        let dockerCacheFile = dockerCacheDir.appendingPathComponent("orb_cache.bin")
        try fm.createDirectory(at: dockerCacheDir, withIntermediateDirectories: true)
        try Data(repeating: 0x42, count: 250 * 1024).write(to: dockerCacheFile)
        ProcessGuard.runningBundleIDsOverrideForTesting = ["dev.kdrag0n.MacVirt"]
        let dockerLockedItems = DockerHelper.scanHostPhysicalItems()
        check(!dockerLockedItems.isEmpty && dockerLockedItems.allSatisfy({ $0.locked == true && $0.isSelected == false }),
              "A07.6: DockerHelper.scanHostPhysicalItems locks items via JunkRulePolicy.apply when host app is running")
        ProcessGuard.runningBundleIDsOverrideForTesting = nil

        // Broken Preferences goes through JunkRulePolicy.apply and locks when owner bundle is running
        let prefsDir = p1Home.appendingPathComponent("Library/Preferences")
        try fm.createDirectory(at: prefsDir, withIntermediateDirectories: true)
        let brokenPlistFile = prefsDir.appendingPathComponent("com.acme.brokenapp.plist")
        try Data("<<<corrupted plist>>>".utf8).write(to: brokenPlistFile)
        ProcessGuard.runningBundleIDsOverrideForTesting = ["com.acme.brokenapp"]
        if let brokenGroup = JunkEngine.scanBrokenPreferences(),
           let brokenItem = brokenGroup.items.first(where: { $0.url.lastPathComponent == "com.acme.brokenapp.plist" }) {
            check(brokenItem.locked == true && brokenItem.isSelected == false && brokenItem.isRuleEvaluated,
                  "A07.7: scanBrokenPreferences locks plist via JunkRulePolicy.apply when owner app is running")
        } else {
            check(false, "A07.7: scanBrokenPreferences should return locked broken plist")
        }
        ProcessGuard.runningBundleIDsOverrideForTesting = nil

        // A08 & C09: 扫描后启动进程或打开句柄，执行期 fresh 复核拒绝删除
        let freshRecheckDir = p1Home.appendingPathComponent("Library/Caches/JetBrains/PyCharm2024.2/caches")
        let freshRecheckFile = freshRecheckDir.appendingPathComponent("index_table.dat")
        try fm.createDirectory(at: freshRecheckDir, withIntermediateDirectories: true)
        try Data("pycharm_cache_data".utf8).write(to: freshRecheckFile)
        ProcessGuard.runningProcessNamesOverrideForTesting = []
        ProcessGuard.runningBundleIDsOverrideForTesting = []
        let scannedIdleJB = JunkRulePolicy.apply(ScanItem(url: freshRecheckDir, name: "caches", size: 18, safety: .caution, isSelected: false))
        ProcessGuard.runningProcessNamesOverrideForTesting = nil
        ProcessGuard.runningBundleIDsOverrideForTesting = nil
        check(scannedIdleJB.locked == false && !scannedIdleJB.children.isEmpty,
              "A08.1: Target is unlocked at scan time when app and handles are idle")
        if let childToClean = scannedIdleJB.children.first {
            // Simulate app starting AFTER scan before Cleaner executes
            ProcessGuard.runningProcessNamesOverrideForTesting = ["pycharm"]
            let cleanTarget = CleanTarget(Node.item(from: childToClean))
            let wasDryRun = Cleaner.isDryRun
            Cleaner.isDryRun = true
            let resProc = Cleaner.clean(cleanTarget)
            Cleaner.isDryRun = wasDryRun
            ProcessGuard.runningProcessNamesOverrideForTesting = nil
            check(!resProc.ok && fm.fileExists(atPath: freshRecheckFile.path),
                  "A08.2 / C09: Cleaner fresh process recheck blocks deletion when app starts after scan")

            // Simulate file handle opened AFTER scan before Cleaner executes
            OpenFileGuard.openPathsOverrideForTesting = [freshRecheckFile.path]
            Cleaner.isDryRun = true
            let resHandle = Cleaner.clean(cleanTarget)
            Cleaner.isDryRun = wasDryRun
            OpenFileGuard.openPathsOverrideForTesting = nil
            check(!resHandle.ok && fm.fileExists(atPath: freshRecheckFile.path),
                  "A08.3 / C09: Cleaner fresh handle recheck blocks deletion when file is opened after scan")

            // C10: 句柄检查失败必锁 (simulateInspectionFailureForTesting)
            OpenFileGuard.simulateInspectionFailureForTesting = true
            let failedHandleEval = JunkRulePolicy.apply(ScanItem(url: freshRecheckFile, name: "index_table.dat", size: 18, safety: .caution, isSelected: true))
            check(failedHandleEval.locked == true
                  && failedHandleEval.isSelected == false
                  && failedHandleEval.evaluationReason == .runningProcessLocked,
                  "C10.1: Handle inspection failure locks item with runningProcessLocked at scan time")
            Cleaner.isDryRun = true
            let resC10 = Cleaner.clean(cleanTarget)
            Cleaner.isDryRun = wasDryRun
            OpenFileGuard.simulateInspectionFailureForTesting = false
            check(!resC10.ok && fm.fileExists(atPath: freshRecheckFile.path),
                  "C10.2: Handle inspection failure blocks deletion at execution time")
        }

        // A09 & C16: trash_children_only 容器快照不一致时丢弃全部部分子项并锁定父容器
        let mutatingContainer = p1Home.appendingPathComponent("Library/Caches/JetBrains/CLion2024.3/tmp")
        try fm.createDirectory(at: mutatingContainer, withIntermediateDirectories: true)
        try Data("c1".utf8).write(to: mutatingContainer.appendingPathComponent("a.tmp"))
        JunkRulePolicy.onContainerEnumerationHook = { dirURL in
            if dirURL.standardizedFileURL == mutatingContainer.standardizedFileURL {
                try? Data("concurrent_mutation".utf8).write(to: dirURL.appendingPathComponent("concurrent.tmp"))
            }
        }
        let mutatedEval = JunkRulePolicy.apply(ScanItem(url: mutatingContainer, name: "tmp", size: 0, safety: .caution, isSelected: false))
        JunkRulePolicy.onContainerEnumerationHook = nil
        var isSnapshotIncompleteReason = false
        if case .containerSnapshotIncomplete = mutatedEval.evaluationReason {
            isSnapshotIncompleteReason = true
        }
        check(mutatedEval.locked == true
              && mutatedEval.isSelected == false
              && mutatedEval.children.isEmpty
              && isSnapshotIncompleteReason,
              "A09 / C16: Container mutation during enumeration discards partial children and locks parent with containerSnapshotIncomplete")

        // A10 & C13: JunkDiscoveryBinding 路径级全量覆盖审计与运行态区分
        let coverageIssues = JunkDiscoveryRegistry.shared.auditCoverage(rules: store.junk)
        check(coverageIssues.isEmpty,
              "A10.1: Every cm_junk_rule and every (rule_id, path_template) in cm_discovery_binding has a valid JunkDiscoveryBinding (\(coverageIssues.joined(separator: "; ")))")
        let absentState = JunkDiscoveryRegistry.shared.evaluateAndRecordDirectoryState(
            at: p1Home.appendingPathComponent("Library/Caches/nonexistent_dir_xyz"),
            ruleID: "JC.CACHE.USER",
            pathTemplate: "~/Library/Caches",
            scannerID: "testScanner"
        )
        check(absentState == .absent, "A10.2 / C13: Nonexistent directory records DiscoveryRunState.absent")
        ProcessGuard.runningProcessNamesOverrideForTesting = ["storedownloadd"]
        let lockedRunState = JunkDiscoveryRegistry.shared.evaluateAndRecordDirectoryState(
            at: appStoreCacheDir,
            ruleID: "JC.SYS.APPSTORE.CACHE",
            pathTemplate: "~/Library/Caches/com.apple.appstore",
            scannerID: "scanAppStoreCache"
        )
        check(lockedRunState == .runningLocked, "A10.3 / C13: Running process lock records DiscoveryRunState.runningLocked")
        ProcessGuard.runningProcessNamesOverrideForTesting = []
        ProcessGuard.runningBundleIDsOverrideForTesting = []
        let foundRunState = JunkDiscoveryRegistry.shared.evaluateAndRecordDirectoryState(
            at: appStoreCacheDir,
            ruleID: "JC.SYS.APPSTORE.CACHE",
            pathTemplate: "~/Library/Caches/com.apple.appstore",
            scannerID: "scanAppStoreCache"
        )
        ProcessGuard.runningProcessNamesOverrideForTesting = nil
        ProcessGuard.runningBundleIDsOverrideForTesting = nil
        check(foundRunState == .found, "A10.4 / C13: Readable idle directory records DiscoveryRunState.found")

        // A12: JC.DEV.PROJECT 五重证明链（缺 manifest、缺 cacheProof、dirty git tree、cwd 命中时扫描与执行均拒绝）
        let projBase = p1Home.appendingPathComponent("Projects")
        // 12.1 缺 manifest 的普通 dist 目录
        let noManifestDist = projBase.appendingPathComponent("PlainDocs/dist")
        try fm.createDirectory(at: noManifestDist, withIntermediateDirectories: true)
        try Data(repeating: 0x31, count: 120 * 1024).write(to: noManifestDist.appendingPathComponent("doc.pdf"))
        check(!DeveloperArtifactPolicy.isEligibleProjectArtifact(noManifestDist) && !DeveloperArtifactPolicy.mayExecute(noManifestDist),
              "A12.1: Directory without project manifest is rejected by DeveloperArtifactPolicy")
        let evalNoManifest = JunkRulePolicy.apply(
            ScanItem(url: noManifestDist, name: "dist", size: 120 * 1024, safety: .caution, isSelected: true,
                     ruleEvidence: CleanupRuleEvidence(id: "JC.DEV.PROJECT", tier: .review, reason: .devDerivedData, defaultSelected: false))
        )
        check(evalNoManifest.locked == true && evalNoManifest.isSelected == false,
              "A12.1b: Scan evaluation locks JC.DEV.PROJECT candidate missing project manifest")

        // 12.2 缺 cacheProof 的 venv 目录（有 pyproject.toml 但无 pyvenv.cfg）
        let fakeVenvProj = projBase.appendingPathComponent("FakePyProj")
        let fakeVenvDir = fakeVenvProj.appendingPathComponent("venv")
        try fm.createDirectory(at: fakeVenvDir, withIntermediateDirectories: true)
        try Data("[project]\nname='demo'\n".utf8).write(to: fakeVenvProj.appendingPathComponent("pyproject.toml"))
        try Data(repeating: 0x32, count: 120 * 1024).write(to: fakeVenvDir.appendingPathComponent("user_notes.txt"))
        check(!DeveloperArtifactPolicy.isEligibleProjectArtifact(fakeVenvDir) && !DeveloperArtifactPolicy.mayExecute(fakeVenvDir),
              "A12.2: venv without pyvenv.cfg cacheProof is rejected by DeveloperArtifactPolicy")

        // 12.3 cwd 命中项目根或产物目录时扫描与执行均拒绝
        let validNodeProj = projBase.appendingPathComponent("ValidNodeApp")
        let validNodeModules = validNodeProj.appendingPathComponent("node_modules")
        try fm.createDirectory(at: validNodeModules, withIntermediateDirectories: true)
        try Data("{\"name\":\"demo\"}".utf8).write(to: validNodeProj.appendingPathComponent("package.json"))
        try Data(repeating: 0x33, count: 120 * 1024).write(to: validNodeModules.appendingPathComponent("bundle.js"))
        DeveloperArtifactPolicy.currentWorkingDirectoryOverrideForTesting = validNodeProj
        check(!DeveloperArtifactPolicy.isEligibleProjectArtifact(validNodeModules) && !DeveloperArtifactPolicy.mayExecute(validNodeModules),
              "A12.3: cwd inside project root blocks JC.DEV.PROJECT eligibility and execution")
        let evalCwdConflict = JunkRulePolicy.apply(
            ScanItem(url: validNodeModules, name: "node_modules", size: 120 * 1024, safety: .caution, isSelected: false,
                     ruleEvidence: CleanupRuleEvidence(id: "JC.DEV.PROJECT", tier: .review, reason: .devDerivedData, defaultSelected: false))
        )
        check(evalCwdConflict.locked == true && evalCwdConflict.isSelected == false,
              "A12.3b: cwd conflict locks JC.DEV.PROJECT item at scan time")
        DeveloperArtifactPolicy.currentWorkingDirectoryOverrideForTesting = nil
        check(DeveloperArtifactPolicy.isEligibleProjectArtifact(validNodeModules) && DeveloperArtifactPolicy.mayExecute(validNodeModules),
              "A12.4: Proven clean project artifact with non-conflicting cwd is eligible as L2 review")

        // 12.5 Terraform 状态与工作区熔断保护
        let terraformProj = projBase.appendingPathComponent("TerraformProject")
        let terraformDir = terraformProj.appendingPathComponent(".terraform")
        try fm.createDirectory(at: terraformDir, withIntermediateDirectories: true)
        try Data("terraform {\n  required_version = \">= 1.0\"\n}\n".utf8).write(to: terraformProj.appendingPathComponent("main.tf"))
        try Data("provider binary cache".utf8).write(to: terraformDir.appendingPathComponent("providers.json"))
        check(DeveloperArtifactPolicy.isEligibleProjectArtifact(terraformDir),
              "A12.5a: Clean .terraform directory without state is eligible")

        let tfStateFile = terraformProj.appendingPathComponent("terraform.tfstate")
        try Data("{\"version\": 4}".utf8).write(to: tfStateFile)
        check(!DeveloperArtifactPolicy.isEligibleProjectArtifact(terraformDir) && !DeveloperArtifactPolicy.mayExecute(terraformDir),
              "A12.5b: .terraform with local terraform.tfstate is rejected by DeveloperArtifactPolicy")
        try fm.removeItem(at: tfStateFile)

        let tfWorkspaceDir = terraformProj.appendingPathComponent("terraform.tfstate.d")
        try fm.createDirectory(at: tfWorkspaceDir, withIntermediateDirectories: true)
        check(!DeveloperArtifactPolicy.isEligibleProjectArtifact(terraformDir) && !DeveloperArtifactPolicy.mayExecute(terraformDir),
              "A12.5c: .terraform with workspace dir terraform.tfstate.d is rejected by DeveloperArtifactPolicy")
        try fm.removeItem(at: tfWorkspaceDir)

        let tfEnvFile = terraformDir.appendingPathComponent("environment")
        try Data("prod".utf8).write(to: tfEnvFile)
        check(!DeveloperArtifactPolicy.isEligibleProjectArtifact(terraformDir) && !DeveloperArtifactPolicy.mayExecute(terraformDir),
              "A12.5d: .terraform with environment workspace file is rejected by DeveloperArtifactPolicy")
        try fm.removeItem(at: tfEnvFile)

        // A13: Orphan DerivedData 路径证明（外置卷、云同步路径拒绝 L1 孤儿判定）
        let derivedRoot = p1Home.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        let extVolDerived = derivedRoot.appendingPathComponent("ExtVolApp-aaaa")
        try fm.createDirectory(at: extVolDerived, withIntermediateDirectories: true)
        let extInfoPlist: NSDictionary = ["WorkspacePath": "/Volumes/ExternalSSD/ExtVolApp/ExtVolApp.xcodeproj"]
        extInfoPlist.write(to: extVolDerived.appendingPathComponent("info.plist"), atomically: true)
        check(!DeveloperArtifactPolicy.isOrphanDerivedData(extVolDerived),
              "A13.1: DerivedData referencing /Volumes/* external volume is never treated as orphan")

        let cloudDerived = derivedRoot.appendingPathComponent("CloudApp-bbbb")
        try fm.createDirectory(at: cloudDerived, withIntermediateDirectories: true)
        let cloudInfoPlist: NSDictionary = ["WorkspacePath": p1Home.path + "/Library/Mobile Documents/com~apple~CloudDocs/CloudApp/CloudApp.xcodeproj"]
        cloudInfoPlist.write(to: cloudDerived.appendingPathComponent("info.plist"), atomically: true)
        check(!DeveloperArtifactPolicy.isOrphanDerivedData(cloudDerived),
              "A13.2: DerivedData referencing iCloud Mobile Documents path is never treated as orphan")

        try await phase3JunkSpecVerification(
            published: published,
            phase1DB: phase1DB,
            p1Home: p1Home,
            pubRoot: pubRoot,
            derivedRoot: derivedRoot
        )
    }
}
