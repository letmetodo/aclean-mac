import Foundation

// ============================================================
//  P3AdvancedTests —— 阶段四开发者清理、深度卸载与系统维护测试套件
//
//  覆盖测试用例：
//    1. TC-PROJ-001: 敏感资产与私钥全域避让 (*-keypair.json 导致构建目录跳过)
//    2. TC-PROJ-002: Git 跟踪保护 (已 commit 跟踪构建文件导致构建目录跳过)
//    3. TC-ORPHAN-001: OrphanSafetyPolicy 安全阀门 (严格封锁 Preferences/Containers)
//    4. TC-UNINST-001: 防短名炸弹防御 (minMatchTokenLength >= 5 杜绝匹配 ~/.ssh)
//    5. TC-UNINST-002: 幸存安装守卫 (同款 Bundle ID 多副本仅删 .app 本体保留配置)
//    6. TC-PERF-001: 维护套件合规性 (100% 杜绝邮件，支持非邮件 VACUUM / QuickLook)
//    7. TC-ORG-001: 安装包智能嗅探与大文件子树剪枝
// ============================================================

final class P3AdvancedTests {

    private let fm = FileManager.default
    private var tempDir: URL!

    init() {
        tempDir = fm.temporaryDirectory.appendingPathComponent("CleanMate_P3Tests_\(UUID().uuidString)")
        try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    deinit {
        try? fm.removeItem(at: tempDir)
    }

    func runAll() {
        print("==================================================")
        print(" 启动 CleanMate 阶段四 (P3: 深度卸载与开发者清理) 自动化测试")
        print("==================================================")

        test_TC_PROJ_001_KeypairAvoidance()
        test_TC_PROJ_002_GitTrackedProtection()
        test_TC_ORPHAN_001_OrphanSafetyPolicy()
        test_TC_UNINST_001_AntiShortNameBomb()
        test_TC_UNINST_002_SurvivingInstallationGuard()
        test_TC_PERF_001_MaintenanceCompliance()
        test_TC_ORG_001_InstallerSniffingAndPruning()

        print("\n==================================================")
        print(" 🎉 恭喜！阶段四 (P3) 全部 7 大核心高级测试用例 100% 通过！")
        print("==================================================")
    }

    // MARK: - TC-PROJ-001: 私钥全域避让
    func test_TC_PROJ_001_KeypairAvoidance() {
        print("\n[RUNNING] TC-PROJ-001: 构造含 deploy/id-keypair.json 的 Rust target 目录避让测试...")

        let projectDir = tempDir.appendingPathComponent("SolanaProject")
        let targetDir = projectDir.appendingPathComponent("target")
        let deployDir = targetDir.appendingPathComponent("deploy")
        try? fm.createDirectory(at: deployDir, withIntermediateDirectories: true)

        let keypairFile = deployDir.appendingPathComponent("id-keypair.json")
        try? "{\"dummy\":\"private_key\"}".write(to: keypairFile, atomically: true, encoding: .utf8)

        // 验证 GitGuard 识别私钥
        let check = GitGuard.containsSensitiveAssets(in: targetDir)
        assert(check.hasSensitive, "target 目录内包含 id-keypair.json 必须被识别为敏感资产")

        // 验证 ProjectPurgeEngine 扫描结果不包含该 target
        let scanned = ProjectPurgeEngine.scan(roots: [projectDir], minAgeDays: 0)
        let foundTarget = scanned.contains { $0.url.path == targetDir.path }
        assert(!foundTarget, "ProjectPurgeEngine 必须全域跳过包含私钥的 target 构建目录！")

        print("  ✓ TC-PROJ-001 通过: 成功识别私钥文件并对整棵构建目录全域封锁")
    }

    // MARK: - TC-PROJ-002: Git 跟踪保护
    func test_TC_PROJ_002_GitTrackedProtection() {
        print("\n[RUNNING] TC-PROJ-002: 构造 Git 仓库中已跟踪的 build 目录保护测试...")

        let gitRepo = tempDir.appendingPathComponent("WebProject")
        let buildDir = gitRepo.appendingPathComponent("build")
        try? fm.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // 初始化 Git 仓库并提交跟踪文件
        _ = Shell.run("/usr/bin/git", ["-C", gitRepo.path, "init"])
        _ = Shell.run("/usr/bin/git", ["-C", gitRepo.path, "config", "user.email", "test@test.com"])
        _ = Shell.run("/usr/bin/git", ["-C", gitRepo.path, "config", "user.name", "tester"])

        let trackedFile = buildDir.appendingPathComponent("bundle.js")
        try? "console.log('tracked');".write(to: trackedFile, atomically: true, encoding: .utf8)

        _ = Shell.run("/usr/bin/git", ["-C", gitRepo.path, "add", "build/bundle.js"])
        _ = Shell.run("/usr/bin/git", ["-C", gitRepo.path, "commit", "-m", "commit bundle.js"])

        // 验证 GitGuard 检测到被跟踪文件
        assert(GitGuard.hasGitTrackedFiles(url: buildDir), "build 目录内已 commit 的文件必须判定为被 Git 跟踪")

        // 验证 ProjectPurgeEngine 扫描跳过该 build 目录
        let scanned = ProjectPurgeEngine.scan(roots: [gitRepo], minAgeDays: 0)
        let foundBuild = scanned.contains { $0.url.path == buildDir.path }
        assert(!foundBuild, "ProjectPurgeEngine 必须绝对禁止清理已被 Git 跟踪的构建目录！")

        print("  ✓ TC-PROJ-002 通过: Git 版本控制跟踪保护生效，未清理任何受管文件")
    }

    // MARK: - TC-ORPHAN-001: OrphanSafetyPolicy 安全阀门
    func test_TC_ORPHAN_001_OrphanSafetyPolicy() {
        print("\n[RUNNING] TC-ORPHAN-001: OrphanSafetyPolicy 偏好设置与沙盒容器黑名单阻断测试...")

        let home = FileUtil.home
        let prefFile = home.appendingPathComponent("Library/Preferences/com.foo.bar.plist")
        let containerDir = home.appendingPathComponent("Library/Containers/com.foo.bar")
        let groupContainerDir = home.appendingPathComponent("Library/Group Containers/group.foo.bar")
        let launchAgentFile = home.appendingPathComponent("Library/LaunchAgents/com.foo.bar.plist")

        // 严格断言黑名单目录下的任何路径均被拒绝
        assert(!OrphanSafetyPolicy.isPermitted(url: prefFile), "Preferences 路径必须被 OrphanSafetyPolicy 绝对拒绝！")
        assert(!OrphanSafetyPolicy.isPermitted(url: containerDir), "Containers 路径必须被 OrphanSafetyPolicy 绝对拒绝！")
        assert(!OrphanSafetyPolicy.isPermitted(url: groupContainerDir), "Group Containers 路径必须被 OrphanSafetyPolicy 绝对拒绝！")
        assert(!OrphanSafetyPolicy.isPermitted(url: launchAgentFile), "LaunchAgents 路径必须被 OrphanSafetyPolicy 绝对拒绝！")

        // 验证挥发性缓存目录允许纳入
        let cacheDir = home.appendingPathComponent("Library/Caches/com.foo.bar")
        let logDir = home.appendingPathComponent("Library/Logs/com.foo.bar")
        assert(OrphanSafetyPolicy.isPermitted(url: cacheDir), "Caches 路径属于许可的挥发性目录: \(cacheDir.standardizedFileURL.path) roots=\(OrphanSafetyPolicy.permittedRoots.map { $0.standardizedFileURL.path }) forbidden=\(OrphanSafetyPolicy.forbiddenRoots.map { $0.standardizedFileURL.path })")
        assert(OrphanSafetyPolicy.isPermitted(url: logDir), "Logs 路径属于许可的挥发性目录")

        print("  ✓ TC-ORPHAN-001 通过: 孤儿安全阀门 100% 锁死，严禁触碰偏好设置与沙盒容器")
    }

    // MARK: - TC-UNINST-001: 防短名炸弹防御
    func test_TC_UNINST_001_AntiShortNameBomb() {
        print("\n[RUNNING] TC-UNINST-001: 卸载器防短名炸弹防御测试 (minMatchTokenLength >= 5)...")

        // 1. 阈值常量校验
        assert(UninstallerEngine.minMatchTokenLength >= 5, "minMatchTokenLength 必须 >= 5")

        // 2. 短名校验阻断测试 (ssh, git, go, app, code)
        assert(!UninstallerEngine.isSafeMatchToken("ssh"), "短名 [ssh] 必须被判定为不安全 Token")
        assert(!UninstallerEngine.isSafeMatchToken("git"), "短名 [git] 必须被判定为不安全 Token")
        assert(!UninstallerEngine.isSafeMatchToken("go"), "短名 [go] 必须被判定为不安全 Token")
        assert(!UninstallerEngine.isSafeMatchToken("app"), "短名 [app] 必须被判定为不安全 Token")

        // 3. 安全 Token 校验
        assert(UninstallerEngine.isSafeMatchToken("Visual Studio Code"), "长 Token 允许通过")
        assert(UninstallerEngine.isSafeMatchToken("com.google.Chrome"), "标准 BundleID 允许通过")

        // 4. 模拟名为 ssh 的应用提取 heuristicTokens
        let fakeAppURL = tempDir.appendingPathComponent("ssh.app")
        let fakeApp = InstalledApp(name: "ssh", bundleID: "com.test.ssh", url: fakeAppURL, appSize: 1024)
        let tokens = UninstallerEngine.heuristicTokens(for: fakeApp)
        assert(!tokens.contains("ssh"), "启发式匹配 Token 集合严禁包含小于 5 字符的短名 [ssh]！")

        print("  ✓ TC-UNINST-001 通过: 防短名炸弹规则完全生效，彻底规避误删 ~/.ssh 或 ~/.git")
    }

    // MARK: - TC-UNINST-002: 幸存安装守卫
    func test_TC_UNINST_002_SurvivingInstallationGuard() {
        print("\n[RUNNING] TC-UNINST-002: AClean 多副本应用保护测试...")

        let appA_URL = tempDir.appendingPathComponent("Applications/MyApp.app")
        let appB_URL = tempDir.appendingPathComponent("Applications/MyApp Beta.app")
        try? fm.createDirectory(at: appA_URL, withIntermediateDirectories: true)
        try? fm.createDirectory(at: appB_URL, withIntermediateDirectories: true)

        let appA = InstalledApp(name: "MyApp", bundleID: "com.example.myapp", url: appA_URL, appSize: 1024)
        let appB = InstalledApp(name: "MyApp Beta", bundleID: "com.example.myapp", url: appB_URL, appSize: 1024)

        // 构造假定关联残留文件
        var appAWithLeftovers = appA
        let leftoverURL = tempDir.appendingPathComponent("Library/Application Support/MyApp")
        try? fm.createDirectory(at: leftoverURL, withIntermediateDirectories: true)
        let item = ScanItem(url: leftoverURL, name: "MyApp", size: 4096, note: "应用配置", safety: .caution)
        appAWithLeftovers.leftovers = [item]

        // 判定是否存在同款存活应用
        let allApps = [appA, appB]
        assert(UninstallerEngine.hasSurvivingInstallation(for: appA, allApps: allApps), "检测到存活的 appB，必须返回 true")

        // 执行卸载目标裁决
        let targets = UninstallerEngine.removalTargets(for: appAWithLeftovers)
        assert(targets.count == 1, "在有同款应用存活时，仅允许返回 1 个删除目标")
        assert(targets.first == appA_URL, "删除目标必须且仅为选中的 .app 本体")
        assert(!targets.contains(leftoverURL), "必须严格保留 Application Support 残留配置，防止影响存活实例！")

        print("  ✓ TC-UNINST-002 通过: 幸存安装守卫精确生效，同款多副本仅删本体包并保留数据")
    }

    // MARK: - TC-PERF-001: 维护套件合规性
    func test_TC_PERF_001_MaintenanceCompliance() {
        print("\n[RUNNING] TC-PERF-001: 系统维护套件 DNA 宪章合规性与高阶任务测试...")

        let tasks = PerformanceEngine.maintenanceTasks()
        assert(!tasks.isEmpty, "维护任务清单不可为空")

        for t in tasks {
            // 严格红线断言：禁止任何邮件任务
            assert(!t.name.contains("邮件") && !t.detail.contains("信封数据库"), "维护任务 [\(t.name)] 绝对不能包含邮件清理！")
        }

        // 验证 QuickLook 任务可用，未经规则授权的通用 VACUUM 不可用。
        let hasQuickLook = tasks.contains { $0.command.contains("qlmanage") }
        let hasVacuum = tasks.contains { $0.command == "vacuumDatabases" }
        let hasDSStore = tasks.contains { $0.command.contains("DSDontWriteNetworkStores") }

        assert(hasQuickLook, "维护套件必须包含 QuickLook 快速查看与图标刷新任务")
        assert(!hasVacuum, "维护套件不得包含未经正向规则授权的通用数据库紧缩任务")
        assert(hasDSStore, "维护套件必须包含禁用网络与外接盘 .DS_Store 优化任务")

        // 兼容入口必须拒绝执行，而非假报成功。
        let vacuumOK = PerformanceEngine.vacuumNonMailDatabases()
        assert(!vacuumOK, "通用数据库 VACUUM 必须拒绝执行")

        print("  ✓ TC-PERF-001 通过: 维护任务注册正确，通用数据库紧缩已禁用（未执行真实维护）")
    }

    // MARK: - TC-ORG-001: 安装包嗅探与大文件剪枝
    func test_TC_ORG_001_InstallerSniffingAndPruning() {
        print("\n[RUNNING] TC-ORG-001: 废弃安装包智能探测与大文件剪枝测试...")

        // 1. 测试 ZIP 嗅探逻辑 (非应用 zip vs 应用 zip)
        let dummyZip = tempDir.appendingPathComponent("normal.zip")
        try? "fake zip content".write(to: dummyZip, atomically: true, encoding: .utf8)
        let isAppZip = OrganizeEngine.isZipInstallerPackage(dummyZip)
        assert(!isAppZip, "普通非 zip 文件嗅探必须安全返回 false")

        // 2. 剪枝集合校验
        assert(OrganizeEngine.pruneDirectories.contains(".git"), "剪枝集合必须包含 .git")
        assert(OrganizeEngine.pruneDirectories.contains("node_modules"), "剪枝集合必须包含 node_modules")
        assert(OrganizeEngine.pruneDirectories.contains("DerivedData"), "剪枝集合必须包含 DerivedData")

        print("  ✓ TC-ORG-001 通过: 安装包嗅探器与大文件剪枝策略完全就绪")
    }
}
