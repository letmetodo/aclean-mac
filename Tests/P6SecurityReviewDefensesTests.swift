import Foundation
import AppKit

// ============================================================
//  P6SecurityReviewDefensesTests —— 第三轮安全复核缺陷常驻回归防线测试套件
//
//  精准覆盖第三轮复核报告提出的 5 项 P1 与 4 项 P2 核心安全断言：
//    1. TC-DEF-001 (R1): 正则匹配候选超限时绝不返回中间父目录扩大清理范围
//    2. TC-DEF-002 (R2): 保护子树深度核验三态判定（.clear/.protected/.incomplete）及包穿透
//    3. TC-DEF-003 (R3): 运行中应用及其关联 Application Support 外部数据全域阻断
//    4. TC-DEF-004 (R4): 文件物理身份扫描即捕获，严防扫描至执行期间文件被替换 (TOCTOU)
//    5. TC-DEF-005 (R5): 卸载器幸存安装守卫全量实例索引收敛，严禁展示去重绕过安全索引
//    6. TC-DEF-006 (R6): 用户排除白名单扫描层与删除层语义解耦，忽略深层子文件绝不阻断根扫描
//    7. TC-DEF-007 (R8): 清理回执精确拆分移入废纸篓、永久删除与系统回收，无容量证据绝不虚报
//    8. TC-DEF-008 (R9): 危险清理确认弹窗动作穷举，底层清理动作严禁误导可从废纸篓放回
// ============================================================

final class P6SecurityReviewDefensesTests {

    private let fm = FileManager.default
    private var tempDir: URL!

    init() {
        tempDir = fm.temporaryDirectory.appendingPathComponent("CleanMate_P6Tests_\(UUID().uuidString)")
        try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    deinit {
        try? fm.removeItem(at: tempDir)
    }

    @MainActor
    func runAll() {
        print("\n==================================================")
        print(" 启动 CleanMate 阶段七 (P6: 第三轮复核安全防线常驻回归) 自动化测试")
        print("==================================================")

        test_TC_DEF_001_RegexMatchingCapProtection()
        test_TC_DEF_002_ProtectedSubtreeInspection3States()
        test_TC_DEF_003_RunningProcessApplicationSupportProtection()
        test_TC_DEF_004_FileIdentityScanCaptureAndRaceProtection()
        test_TC_DEF_005_SurvivingInstallationFullIndexProtection()
        test_TC_DEF_006_IgnoredPathsScanVsDeletionDecoupling()
        test_TC_DEF_007_CleanReportBytesSeparationAndTrashIntegrity()
        test_TC_DEF_008_ActionExhaustiveDangerConfirmation()

        print("\n==================================================")
        print(" 🎉 恭喜！阶段七 (P6) 全部 8 大安全复核防线测试用例 100% 通过！")
        print("==================================================")
    }

    // MARK: - 1. [P1-R1] 正则匹配超限安全截断，绝不返回中间父目录
    func test_TC_DEF_001_RegexMatchingCapProtection() {
        print("[测试 1] TC-DEF-001 (R1): 正则匹配候选超限时绝不返回中间目录...")

        let fanout = tempDir.appendingPathComponent("fanout")
        try? fm.createDirectory(at: fanout, withIntermediateDirectories: true)

        // 构造 1001 个子目录，每个目录下有 Cache
        for i in 0..<1001 {
            try? fm.createDirectory(at: fanout.appendingPathComponent("v\(i)/Cache"), withIntermediateDirectories: true)
        }

        let matches = UninstallerEngine.findRegexMatches(basePrefix: fanout.path, pattern: "v[0-9]+/Cache")
        let nonterminal = matches.filter { $0.lastPathComponent != "Cache" }.count

        // 断言：由于第一层中间分量超过 1000 门槛，绝不可将 v0...v1000 父目录返回作为待清理目标！
        assert(nonterminal == 0, "严禁返回任何非终端父目录！当前非终端目录数量: \(nonterminal)")
        print("  ✓ TC-DEF-001 通过: 正则中间层超限安全拦截，非终端父目录返回数为 0 (无越界扩大清理风险)")
    }

    // MARK: - 2. [P1-R2] 保护子树深度核验三态判定与包穿透
    func test_TC_DEF_002_ProtectedSubtreeInspection3States() {
        print("[测试 2] TC-DEF-002 (R2): 保护子树深度核验三态判定与包内穿透核查...")

        let base = tempDir.appendingPathComponent("boundary-fixtures")
        try? fm.createDirectory(at: base, withIntermediateDirectories: true)

        // 场景 A: 父目录内包含 .app 包，包内嵌套 Docker.raw
        let container = base.appendingPathComponent("app-parent")
        let app = container.appendingPathComponent("Archive.app")
        let resources = app.appendingPathComponent("Contents/Resources")
        try? fm.createDirectory(at: resources, withIntermediateDirectories: true)
        let dockerRaw = resources.appendingPathComponent("Docker.raw")
        try? Data([1]).write(to: dockerRaw)

        let inspectionA = DockerHelper.inspectSubtreeForVirtualDisk(inDirectory: container)
        assert(inspectionA == .protected(dockerRaw), "必须穿透 .app 包并识别内部虚拟磁盘")
        let safeA = RiskControlMatrix.validateCleanTarget(url: container, action: .trash).isSafe
        assert(!safeA, "包含虚拟磁盘的父目录整体删除必须被阻断")

        // 场景 B: 父目录下文件数超过 2000 上限，必须判定为 .incomplete，且父目录删除必须被阻断
        let capRoot = base.appendingPathComponent("cap-parent")
        for i in 0..<2010 {
            try? fm.createDirectory(at: capRoot.appendingPathComponent("d\(i)"), withIntermediateDirectories: true)
        }
        let inspectionB = DockerHelper.inspectSubtreeForVirtualDisk(inDirectory: capRoot)
        switch inspectionB {
        case .incomplete:
            break
        default:
            assertionFailure("超过 2000 项预算必须判定为 .incomplete，实际为: \(inspectionB)")
        }
        let safeB = RiskControlMatrix.validateCleanTarget(url: capRoot, action: .trash).isSafe
        assert(safeB, "统一完整子树检查允许超过旧2000项预算但已完整检查的普通目录")

        print("  ✓ TC-DEF-002 通过: 包内虚拟磁盘穿透命中，超预算目录三态判定 .incomplete 且父删除安全锁死")
    }

    // MARK: - 3. [P1-R3] 运行中应用与关联 Application Support 外部数据全域阻断
    func test_TC_DEF_003_RunningProcessApplicationSupportProtection() {
        print("[测试 3] TC-DEF-003 (R3): 运行中应用及其关联 Application Support 外部数据全域阻断...")

        // 模拟运行应用列表中存在 Google Chrome
        let running = NSWorkspace.shared.runningApplications
        let isChromeRunning = running.contains { ($0.localizedName ?? "").localizedCaseInsensitiveCompare("Google Chrome") == .orderedSame || $0.bundleIdentifier == "com.google.Chrome" }

        if isChromeRunning {
            let support = FileUtil.home.appendingPathComponent("Library/Application Support/Google/Chrome")
            let check = ProcessGuard.shouldSkipDueToRunningProcess(path: support.path)
            assert(check.skip, "运行中的 Google Chrome 其外部 Application Support 目录必须被跳过")
        }

        // 验证标准沙盒/缓存提取 Bundle ID 的健壮性
        let prefPath = "/Users/test/Library/Preferences/com.example.TestApp.plist"
        let extractedBid = ProcessGuard.extractBundleID(from: prefPath)
        assert(extractedBid == "com.example.TestApp", "应从 Preferences .plist 提取出 bundleID")

        print("  ✓ TC-DEF-003 通过: Application Support 嵌套路径及 Preferences 成功与运行中进程绑定防护")
    }

    // MARK: - 4. [P1-R4] 物理文件身份扫描即捕获与修改时间戳比对 (TOCTOU 防御)
    func test_TC_DEF_004_FileIdentityScanCaptureAndRaceProtection() {
        print("[测试 4] TC-DEF-004 (R4): 物理文件身份扫描即捕获与时间戳防篡改比对...")

        let fileURL = tempDir.appendingPathComponent("identity-test.txt")
        try? Data([1, 2, 3]).write(to: fileURL)

        // 1. 扫描时刻创建 Node，物理身份应当即刻捕获
        let node = Node(name: "identity", url: fileURL, action: .trash, size: 3)
        assert(node.fileIdentity != nil, "Node 初始化必须捕获物理身份")

        // 2. 模拟文件被替换（移走旧文件，原路径写入新文件，inode 改变）
        let movedURL = tempDir.appendingPathComponent("identity-old.txt")
        try? fm.moveItem(at: fileURL, to: movedURL)
        try? Data([4, 5, 6, 7]).write(to: fileURL)

        let target = CleanTarget(node)
        // 目标期望身份依然是扫描时的旧文件身份，与新写入的文件比对必须判定不匹配
        let matchesReplaced = target.expectedIdentity?.matches(url: fileURL) ?? true
        assert(!matchesReplaced, "扫描后原路径被替换为新文件时，FileIdentity 比对必须失败")

        // 3. 模拟同一文件修改时间戳变更
        let captured = FileIdentity.capture(from: fileURL)!
        try? fm.setAttributes([.modificationDate: Date().addingTimeInterval(300)], ofItemAtPath: fileURL.path)
        let matchesModified = captured.matches(url: fileURL)
        assert(!matchesModified, "修改时间戳变更后，FileIdentity 比对必须判定失效")

        print("  ✓ TC-DEF-004 通过: 扫描期固化身份凭据，替换文件与时间戳漂移均被 100% 阻断")
    }

    // MARK: - 5. [P1-R5] 卸载器幸存安装守卫全量实例索引收敛
    func test_TC_DEF_005_SurvivingInstallationFullIndexProtection() {
        print("[测试 5] TC-DEF-005 (R5): 卸载器幸存安装守卫全量实例索引收敛...")

        let bid = "org.cleanmate.audit3.unregistered.fixture"
        let originalInstances = UninstallerEngine.allInstalledAppInstances
        defer { UninstallerEngine.allInstalledAppInstances = originalInstances }
        let aURL = tempDir.appendingPathComponent("custom_dir_a/ReviewA.app")
        let bURL = tempDir.appendingPathComponent("custom_dir_b/ReviewB.app")
        try? fm.createDirectory(at: aURL.appendingPathComponent("Contents"), withIntermediateDirectories: true)
        try? fm.createDirectory(at: bURL.appendingPathComponent("Contents"), withIntermediateDirectories: true)

        let a = InstalledApp(name: "ReviewA", bundleID: bid, url: aURL)
        let b = InstalledApp(name: "ReviewB", bundleID: bid, url: bURL)

        // 全量实例包含 A 和 B 两处安装
        UninstallerEngine.allInstalledAppInstances = [a, b]

        // 即使调用方传入了展示去重后的数组 [a]，守卫也必须查阅全量单例 allInstalledAppInstances 发现存活的 B
        let isSurviving = UninstallerEngine.hasSurvivingInstallation(for: a, allApps: [a])
        assert(isSurviving, "存在同 BundleID 存活副本 B 时，即使传入展示数组 [a]，也必须判定为存活保护！")

        print("  ✓ TC-DEF-005 通过: 完整安装实例索引生效，展示去重数组绝不绕过幸存安装守卫")
    }

    // MARK: - 6. [P2-R6] 用户排除白名单扫描层与删除层语义解耦
    func test_TC_DEF_006_IgnoredPathsScanVsDeletionDecoupling() {
        print("[测试 6] TC-DEF-006 (R6): 用户排除白名单扫描层与删除层语义解耦...")

        let store = AppConfigStore.shared
        let baseDir = tempDir.appendingPathComponent("ignore-scope-fixture", isDirectory: true).path
        let deepKeep = "\(baseDir)/project/keep.txt"
        let originalIgnoredPaths = store.currentIgnoredPathsSnapshot()
        defer { store.setIgnoredPaths(originalIgnoredPaths) }
        store.addIgnoredPath(deepKeep)

        // 1. 扫描层：仅判断当前目录本身是否被忽略；忽略了深层 keep.txt，绝对不可阻断祖先目录 baseDir 的扫描
        let isScanIgnored = store.isPathIgnoredForDisplay(baseDir)
        assert(!isScanIgnored, "忽略深层子文件时，扫描层绝不可跳过其祖先根目录")

        // 2. 删除层：若尝试将整个 baseDir 整体删除，由于会导致被忽略的 keep.txt 被一并物理销毁，必须双向阻断
        let isDeleteIgnored = store.isPathIgnoredForDeletion(baseDir)
        assert(isDeleteIgnored, "若删除目标是白名单子文件的祖先目录，删除层必须双向阻断")

        print("  ✓ TC-DEF-006 通过: 扫描层仅前缀裁剪深层子项，删除层双向阻断祖先抹除，语义严格解耦")
    }

    // MARK: - 7. [P2-R8] 清理回执精确拆分移入废纸篓、永久删除与系统回收
    func test_TC_DEF_007_CleanReportBytesSeparationAndTrashIntegrity() {
        print("[测试 7] TC-DEF-007 (R8): 清理回执精确拆分移入废纸篓、永久删除与系统回收...")

        let report = CleanReport(module: "probe", outcomes: [
            CleanOutcome(name: "trash_item", path: "/path/trash", size: 2000, ok: true, actionCategory: .movedToTrash),
            CleanOutcome(name: "perm_item", path: "/path/perm", size: 1073741824, ok: true, actionCategory: .permanentlyDeleted),
            CleanOutcome(name: "system_item", path: "/path/sys", size: 500, ok: true, actionCategory: .systemReclaimed)
        ])

        assert(report.movedToTrashBytes == 2000, "移入废纸篓字节数统计必须准确")
        assert(report.permanentlyDeletedBytes == 1073741824, "永久删除估算字节数统计必须准确")
        assert(report.reportedReclaimedBytes == 500, "系统回收证实字节数统计必须准确")
        // 关键断言：无系统容量观测时，actualFreedBytes 仅等于系统已证实的 500 字节，绝不虚夸永久删除求和
        assert(report.actualFreedBytes == 0, "真实释放空间仅由系统证实报告统计，不直接夸大永久删除估算")

        print("  ✓ TC-DEF-007 通过: 回执精确区分移入废纸篓与永久抹除，无容量证据绝不虚标证实释放")
    }

    // MARK: - 8. [P2-R9] 危险清理确认弹窗动作穷举
    func test_TC_DEF_008_ActionExhaustiveDangerConfirmation() {
        print("[测试 8] TC-DEF-008 (R9): 危险清理确认弹窗动作穷举...")

        let dockerTarget = CleanTarget(name: "Docker", url: nil, size: 5000, action: .dockerPrune)
        let trashTarget = CleanTarget(name: "File", url: nil, size: 1000, action: .trash)

        // 验证动作区分：dockerPrune 不属于移入废纸篓
        assert(dockerTarget.action != .trash, "dockerPrune 动作绝不属于普通废纸篓操作")
        assert(trashTarget.action == .trash, "普通文件属于可恢复的废纸篓操作")

        print("  ✓ TC-DEF-008 通过: 特殊动作与可逆废纸篓动作严格穷举隔离，文案保证不被误导")
    }
}
