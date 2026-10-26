import Foundation

// ============================================================
//  P0SecurityTests —— 阶段一安全风控基石与底层加固测试套件
//
//  覆盖测试用例：
//    1. TC-SAFE-001: 符号链接穿透逃逸防御测试 (~/Library/Caches/FakeApp -> ~/.ssh)
//    2. TC-PROJ-001: 敏感资产与私钥避让测试 (*-keypair.json, id_rsa, .git)
//    3. TC-PROJ-002: Git 跟踪源码保护测试 (git ls-files)
//    4. TC-P0-RISK-001: Sequoia 系统设置保护与 ANE 神经引擎缓存保护测试
//    5. TC-P0-ACTION-001: 二进制架构精简与语言包在位修改动作封锁测试
//    6. TC-P0-PROC-001: 活跃应用检测与核心进程不可杀保护测试
//    7. TC-P0-MAIL-001: DNA 宪章邮件附件零残留合规测试
// ============================================================

final class P0SecurityTests {

    private let fm = FileManager.default
    private var tempDir: URL!

    init() {
        tempDir = fm.temporaryDirectory.appendingPathComponent("CleanMate_P0Tests_\(UUID().uuidString)")
        try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    deinit {
        try? fm.removeItem(at: tempDir)
    }

    func runAll() {
        print("==================================================")
        print(" 启动 CleanMate 阶段一 (P0: 安全风控基石) 自动化测试")
        print("==================================================")

        test_TC_SAFE_001_SymlinkEscape()
        test_TC_PROJ_001_SensitiveKeypairEscape()
        test_TC_PROJ_002_GitTrackedProtection()
        test_TC_P0_RISK_001_SequoiaAndANEProtection()
        test_TC_P0_ACTION_001_BlockThinBinaryAndLanguages()
        test_TC_P0_PROC_001_ProcessGuardAndCoreSystemProc()
        test_TC_P0_MAIL_001_ZeroMailAttachmentCompliance()

        print("\n==================================================")
        print(" 🎉 恭喜！阶段一 (P0) 全部 7 大安全测试用例 100% 通过！")
        print("==================================================")
    }

    // MARK: - TC-SAFE-001: 符号链接逃逸防御
    func test_TC_SAFE_001_SymlinkEscape() {
        print("\n[RUNNING] TC-SAFE-001: 构造符号链接防穿透逃逸测试...")

        let fakeCaches = tempDir.appendingPathComponent("Library/Caches")
        let sensitiveTarget = tempDir.appendingPathComponent("UserSensitive/.ssh")
        try? fm.createDirectory(at: fakeCaches, withIntermediateDirectories: true)
        try? fm.createDirectory(at: sensitiveTarget, withIntermediateDirectories: true)

        let symlinkApp = fakeCaches.appendingPathComponent("FakeApp")
        // 构造软链接: FakeApp -> sensitiveTarget
        try? fm.createSymbolicLink(at: symlinkApp, withDestinationURL: sensitiveTarget)

        assert(SymlinkGuard.isSymbolicLink(at: symlinkApp), "symlinkApp 必须被识别为符号链接")
        assert(SymlinkGuard.hasSymlinkEscape(url: symlinkApp), "symlinkApp 必须被判定为存在符号链接逃逸")
        assert(!SymlinkGuard.isSafePath(url: symlinkApp, within: fakeCaches), "symlinkApp 指向基准目录外，必须判定为不安全")

        // 验证 RiskControlMatrix 裁决
        let safety = RiskControlMatrix.validateCleanTarget(url: symlinkApp, action: .trash)
        assert(!safety.isSafe, "RiskControlMatrix 必须拦截逃逸的符号链接")
        print("  ✓ TC-SAFE-001 通过: 成功阻断软链接穿透 [\(symlinkApp.path)] -> [\(sensitiveTarget.path)]")
    }

    // MARK: - TC-PROJ-001: 敏感资产避让 (*-keypair.json)
    func test_TC_PROJ_001_SensitiveKeypairEscape() {
        print("\n[RUNNING] TC-PROJ-001: 敏感私钥资产避让测试 (*-keypair.json)...")

        let projectTarget = tempDir.appendingPathComponent("RustProject/target")
        let deploySubdir = projectTarget.appendingPathComponent("deploy")
        try? fm.createDirectory(at: deploySubdir, withIntermediateDirectories: true)

        // 构造 Solana/Anchor 部署私钥文件
        let keypairFile = deploySubdir.appendingPathComponent("id-keypair.json")
        try? "{\"secret\":\"dummy_key\"}".write(to: keypairFile, atomically: true, encoding: .utf8)

        let check = GitGuard.containsSensitiveAssets(in: projectTarget)
        assert(check.hasSensitive, "必须识别出 target 目录下包含 *-keypair.json 私钥")
        assert(check.detail?.contains("keypair") == true, "匹配详情必须指出包含 keypair")

        let safeCheck = GitGuard.isSafeToPurge(url: projectTarget)
        assert(!safeCheck.isSafe, "包含私钥的目录必须被封锁禁止清理")

        let rcmCheck = RiskControlMatrix.validateCleanTarget(url: projectTarget, action: .trash)
        assert(!rcmCheck.isSafe, "RiskControlMatrix 必须拒绝清理含私钥的项目目录")
        print("  ✓ TC-PROJ-001 通过: 成功识别私钥文件 [\(keypairFile.lastPathComponent)] 并全域封锁清理")
    }

    // MARK: - TC-PROJ-002: Git 跟踪保护
    func test_TC_PROJ_002_GitTrackedProtection() {
        print("\n[RUNNING] TC-PROJ-002: Git 跟踪源码保护测试 (git ls-files)...")

        let repoDir = tempDir.appendingPathComponent("MyGitRepo")
        let buildDir = repoDir.appendingPathComponent("build")
        try? fm.createDirectory(at: buildDir, withIntermediateDirectories: true)

        // 初始化真实临时 Git 仓库
        _ = Shell.run("/usr/bin/git", ["-C", repoDir.path, "init"])
        _ = Shell.run("/usr/bin/git", ["-C", repoDir.path, "config", "user.email", "test@cleanmate.internal"])
        _ = Shell.run("/usr/bin/git", ["-C", repoDir.path, "config", "user.name", "CleanMateTest"])

        // 构造被跟踪的构建文件
        let trackedFile = buildDir.appendingPathComponent("output.js")
        try? "console.log('committed');".write(to: trackedFile, atomically: true, encoding: .utf8)
        _ = Shell.run("/usr/bin/git", ["-C", repoDir.path, "add", "build/output.js"])
        _ = Shell.run("/usr/bin/git", ["-C", repoDir.path, "commit", "-m", "add tracked build file"])

        // 验证 GitGuard 判定
        let isTracked = GitGuard.hasGitTrackedFiles(url: buildDir)
        assert(isTracked, "已 commit 的 build/output.js 必须被判定为受 Git 跟踪")

        let safeCheck = GitGuard.isSafeToPurge(url: buildDir)
        assert(!safeCheck.isSafe, "包含 Git 跟踪文件的目录必须拒绝清理")

        let rcmCheck = RiskControlMatrix.validateCleanTarget(url: buildDir, action: .trash)
        assert(!rcmCheck.isSafe, "RiskControlMatrix 必须保护受 Git 跟踪的文件目录")
        print("  ✓ TC-PROJ-002 通过: 成功调用 git ls-files 拦截已跟踪代码目录 [\(buildDir.path)]")
    }

    // MARK: - TC-P0-RISK-001: Sequoia 设置保护与 ANE 保护
    func test_TC_P0_RISK_001_SequoiaAndANEProtection() {
        print("\n[RUNNING] TC-P0-RISK-001: Sequoia 设置保护与 ANE 缓存保护测试...")

        let sequoiaSettingsURL = URL(fileURLWithPath: "/Users/test/Library/Containers/com.apple.Settings")
        let aneCacheURL = URL(fileURLWithPath: "/Users/test/Library/Caches/com.apple.e5rt.e5bundlecache")
        let controlCenterURL = URL(fileURLWithPath: "/Users/test/Library/Caches/com.apple.controlcenter")

        let check1 = RiskControlMatrix.validateCleanTarget(url: sequoiaSettingsURL, action: .trash)
        assert(!check1.isSafe, "com.apple.Settings 必须被绝对保护")

        let check2 = RiskControlMatrix.validateCleanTarget(url: aneCacheURL, action: .trash)
        assert(!check2.isSafe, "com.apple.e5rt.e5bundlecache 神经引擎缓存必须被绝对保护")

        let check3 = RiskControlMatrix.validateCleanTarget(url: controlCenterURL, action: .trash)
        assert(!check3.isSafe, "com.apple.controlcenter 控制中心必须被绝对保护")

        print("  ✓ TC-P0-RISK-001 通过: 成功阻断 Sequoia 设置与 Apple 神经引擎缓存的清理")
    }

    // MARK: - TC-P0-ACTION-001: 封锁二进制精简与语言包在位删除
    func test_TC_P0_ACTION_001_BlockThinBinaryAndLanguages() {
        print("\n[RUNNING] TC-P0-ACTION-001: 二进制架构精简与语言包在位修改动作封锁测试...")

        let dummyAppBin = URL(fileURLWithPath: "/Applications/TestApp.app/Contents/MacOS/TestApp")
        let dummyLproj = URL(fileURLWithPath: "/Applications/TestApp.app/Contents/Resources/de.lproj")

        // 1. thinBinary 动作封锁
        let thinCheck = RiskControlMatrix.isActionPermitted(action: .thinBinary("x86_64"), url: dummyAppBin)
        assert(!thinCheck.permitted, "thinBinary 动作必须被全面封锁")

        // 2. 在位删除语言包封锁
        let langCheck = RiskControlMatrix.isActionPermitted(action: .trash, url: dummyLproj)
        assert(!langCheck.permitted, "在位删除 .lproj 必须被全面封锁")

        // 3. Cleaner 路由阻断
        let target1 = CleanTarget(name: "TestApp", url: dummyAppBin, size: 1024,
                                  action: .thinBinary("x86_64"), locked: false)
        let outcome1 = Cleaner.clean(target1)
        assert(!outcome1.ok, "Cleaner 必须拒绝执行 thinBinary")

        print("  ✓ TC-P0-ACTION-001 通过: 架构红线封锁生效，坚决杜绝在位修改应用签名与切片")
    }

    // MARK: - TC-P0-PROC-001: 活跃进程检测与核心守护进程保护
    func test_TC_P0_PROC_001_ProcessGuardAndCoreSystemProc() {
        print("\n[RUNNING] TC-P0-PROC-001: 活跃进程检测与核心守护进程保护测试...")

        // 1. 验证关键系统进程保护 (launchd, kernel_task, WindowServer, Finder)
        assert(ProcessGuard.isProtectedSystemProcess(pid: 1, name: "launchd"), "PID 1 launchd 必须受保护")
        assert(ProcessGuard.isProtectedSystemProcess(pid: 0, name: "kernel_task"), "PID 0 kernel_task 必须受保护")
        assert(ProcessGuard.isProtectedSystemProcess(pid: 9999, name: "WindowServer"), "WindowServer 必须受保护")
        assert(ProcessGuard.isProtectedSystemProcess(pid: 9999, name: "Finder"), "Finder 必须受保护")
        assert(ProcessGuard.isProtectedSystemProcess(pid: 9999, name: "CleanMate"), "CleanMate 自身必须受保护")
        assert(!ProcessGuard.isProtectedSystemProcess(pid: 9999, name: "MyTestApp"), "常规第三方应用不应误判为系统关键守护进程")

        // 2. 验证原生 PID 枚举
        guard let pids = ProcessGuard.allRunningPIDs() else {
            assertionFailure("原生 proc_listpids 必须成功获取系统进程列表")
            return
        }
        assert(!pids.isEmpty, "原生 proc_listpids 必须成功获取系统进程列表")
        assert(pids.contains(1), "系统运行中必须包含 PID 1")

        print("  ✓ TC-P0-PROC-001 通过: 原生内核进程直读与系统核心守护进程防护完全就绪")
    }

    // MARK: - TC-P0-MAIL-001: 邮件附件零残留合规
    func test_TC_P0_MAIL_001_ZeroMailAttachmentCompliance() {
        print("\n[RUNNING] TC-P0-MAIL-001: DNA 宪章邮件附件零残留合规测试...")

        // 1. 验证 JunkEngine 任务清单中 100% 杜绝邮件扫描项
        let taskNames = JunkEngine.taskNames
        assert(!taskNames.isEmpty, "JunkEngine 任务清单不可为空")
        for name in taskNames {
            assert(!name.contains("邮件") && !name.localizedCaseInsensitiveContains("Mail"),
                   "JunkEngine 任务 [\(name)] 违反 DNA 宪章，严禁包含任何邮件清理任务！")
        }

        // 2. 验证扫描管道入口在启动拦截下也不会上报邮件进度
        var reportedNames: [String] = []
        _ = JunkEngine.scan(progress: { _, task in
            reportedNames.append(task)
        }, isStopped: { true })
        for r in reportedNames {
            assert(!r.contains("邮件") && !r.localizedCaseInsensitiveContains("Mail"),
                   "JunkEngine 进度上报不得出现邮件相关关键字！")
        }

        print("  ✓ TC-P0-MAIL-001 通过: JunkEngine 100% 符合 DNA 宪章，彻底移除邮件清理")
    }
}
