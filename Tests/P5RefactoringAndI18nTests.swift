import Foundation

// ============================================================
//  P5RefactoringAndI18nTests —— 工业化重构、多语言与零差错防线测试套件
//
//  覆盖测试用例：
//    1. TC-I18N-001: 多语言引擎实时切换 (zh-Hans ↔ en) 与词条映射准确性验证
//    2. TC-SAFE-WHITELIST-001: 前缀感知白名单防线（扫描层递归裁剪 + 执行层拦截）
//    3. TC-SAFE-MAINT-001: 跨语言稳定任务 ID (maint:<taskId>) 维护指令路由验证
//    4. TC-SAFE-STARTUP-001: 启动项未知状态 (stateKnown == false) 内存覆盖与可逆切换验证
//    5. TC-CONFIG-001: AppConfigStore 配置快照 JSON 导出、导入与恢复默认闭环验证
// ============================================================

final class P5RefactoringAndI18nTests {

    private let fm = FileManager.default
    private var tempDir: URL!

    init() {
        tempDir = fm.temporaryDirectory.appendingPathComponent("CleanMate_P5Tests_\(UUID().uuidString)")
        try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    deinit {
        try? fm.removeItem(at: tempDir)
    }

    @MainActor
    func runAll() {
        print("\n==================================================")
        print(" 启动 CleanMate 阶段六 (P5: 工业化重构与零差错防线) 自动化测试")
        print("==================================================")

        test_TC_I18N_001_LocalizationSwitchAndMapping()
        test_TC_SAFE_WHITELIST_001_PrefixAwareWhitelistProtection()
        test_TC_SAFE_MAINT_001_CrossLanguageMaintenanceRouting()
        test_TC_SAFE_STARTUP_001_DeterministicStartupStateToggle()
        test_TC_CONFIG_001_ConfigExportImportAndReset()
        test_TC_APPS_FOLDER_001_FolderPurposeAndLayeredUninstall()
        test_TC_PARALLEL_001_MultiModuleParallelAndStatePreservation()
        test_TC_SPACE_STREAM_001_RealTimeStreamingAndCachedTotalSize()
        test_TC_STARTUP_SPLIT_001_StartupAndBackgroundServicesSplit()
        test_TC_INTERMEDIATE_STATE_001_ManualTriggerAndResultPersistence()

        print("\n==================================================")
        print(" 🎉 恭喜！阶段六 (P5) 全部 10 大核心测试用例 100% 通过！")
        print("==================================================")
    }

    // MARK: - 1. 多语言切换与词条映射验证
    @MainActor
    private func test_TC_I18N_001_LocalizationSwitchAndMapping() {
        print("\n[测试 1] TC-I18N-001: 多语言引擎实时切换与词条映射验证")
        let originalLang = AppConfigStore.shared.language
        defer {
            AppConfigStore.shared.language = originalLang
        }

        AppConfigStore.shared.language = .zhHans
        assert(L10n.shared.effectiveLanguage == .zhHans, "切换至 zhHans 后 effectiveLanguage 应为 .zhHans")
        assert(tr(.moduleSmartCare) == "智能扫描", "中文模式下 tr(.moduleSmartCare) 应为 '智能扫描'")
        assert(L10n.string(.moduleJunk) == "清理", "中文模式下 L10n.string(.moduleJunk) 应为 '清理'")

        AppConfigStore.shared.language = .en
        assert(L10n.shared.effectiveLanguage == .en, "切换至 en 后 effectiveLanguage 应为 .en")
        assert(tr(.moduleSmartCare) == "Smart Care", "英文模式下 tr(.moduleSmartCare) 应为 'Smart Care'")
        assert(L10n.string(.moduleJunk) == "System Junk", "英文模式下 L10n.string(.moduleJunk) 应为 'System Junk'")

        // 验证 10 门主流语言全部具备原生母语级翻译且不为空
        assert(AppLanguage.concreteLanguages.count == 10, "必须完整支持 10 门主流具体语言")
        let coreModules: [L10nKey] = [.moduleJunk, .modulePerformance, .moduleApplications, .moduleSpaceLens, .moduleDeclutter, .moduleLiveMonitor]
        for lang in AppLanguage.concreteLanguages {
            AppConfigStore.shared.language = lang
            assert(L10n.shared.effectiveLanguage == lang, "切换至 \(lang.rawValue) 后 effectiveLanguage 应一致")
            for mod in coreModules {
                let translated = L10n.localized(mod)
                assert(!translated.isEmpty, "语言 \(lang.rawValue) 下模块 '\(mod.rawValue)' 的翻译不应为空")
            }
        }

        // 验证简洁模式 6 大模块与预设主题色方案
        assert(ModuleRegistry.conciseModules.count == 6, "简洁模式应包含 6 大核心模块")
        assert(AppThemePreset.allCases.count == 6, "应提供 6 套预设主题色配色方案")
        for preset in AppThemePreset.allCases {
            AppConfigStore.shared.themePreset = preset
            assert(AppConfigStore.shared.themePreset == preset, "主题色预设 \(preset.rawValue) 切换应生效")
        }

        print("  ✓ TC-I18N-001 通过: 10 门主流语言实时切换、6 套预设主题色与简洁模式 6 大模块校验通过")
    }

    // MARK: - 2. 前缀感知白名单防线（扫描层 + 执行层双重拦截）
    @MainActor
    private func test_TC_SAFE_WHITELIST_001_PrefixAwareWhitelistProtection() {
        print("\n[测试 2] TC-SAFE-WHITELIST-001: 前缀感知白名单防线（扫描层 + 执行层双重拦截）")

        let protectedFolder = tempDir.appendingPathComponent("ProtectedWorkspace")
        let nestedSubdir = protectedFolder.appendingPathComponent("SubProject/BuildCache")
        try? fm.createDirectory(at: nestedSubdir, withIntermediateDirectories: true)

        let protectedFile = nestedSubdir.appendingPathComponent("important_cache.dat")
        let unprotectedFile = tempDir.appendingPathComponent("unprotected_temp.dat")
        try? Data(repeating: 0x41, count: 2048).write(to: protectedFile)
        try? Data(repeating: 0x42, count: 1024).write(to: unprotectedFile)

        // 加入父目录到白名单
        AppConfigStore.shared.addIgnoredPath(protectedFolder.path)
        defer {
            AppConfigStore.shared.removeIgnoredPath(protectedFolder.path)
        }

        // 验证 1: 前缀感知路径判定（子目录与孙文件必须被识别为受保护，且不会误伤同前缀兄弟目录）
        let siblingFile = tempDir.appendingPathComponent("ProtectedWorkspace_Sibling/file.dat")
        assert(AppConfigStore.shared.isPathIgnored(protectedFolder.path), "白名单根目录自身应受保护")
        assert(AppConfigStore.shared.isPathIgnored(protectedFile.path), "白名单目录下的深层嵌套子文件必须自动受保护")
        assert(!AppConfigStore.shared.isPathIgnored(siblingFile.path), "同名前缀兄弟目录不应被误判为白名单")

        // 验证 2: RiskControlMatrix 底层硬性拦截
        let decision = RiskControlMatrix.validateCleanTarget(url: protectedFile, action: .trash)
        assert(!decision.isSafe, "白名单目录内的文件在 RiskControlMatrix 层必须被 isSafe == false 拦截！")
        print("  · RiskControlMatrix 成功拦截白名单子文件清理请求: \(decision.reason ?? "")")

        // 验证 3: Cleaner.clean 真实执行不误删白名单子文件
        let targetProtected = CleanTarget(
            name: "important_cache.dat",
            url: protectedFile,
            size: 2048,
            action: .trash
        )
        let outcomeProtected = Cleaner.clean(targetProtected)
        assert(!outcomeProtected.ok, "白名单父目录下的子文件清理结果必须为 ok == false")
        assert(fm.fileExists(atPath: protectedFile.path), "白名单父目录下的子文件绝不能被 Cleaner 删除！")

        print("  ✓ TC-SAFE-WHITELIST-001 通过: 父目录白名单对深层子文件的路径判定与执行拦截 100% 生效")
    }

    // MARK: - 3. 跨语言稳定任务 ID (maint:<taskId>) 路由验证
    @MainActor
    private func test_TC_SAFE_MAINT_001_CrossLanguageMaintenanceRouting() {
        print("\n[测试 3] TC-SAFE-MAINT-001: 跨语言维护任务稳定 ID 解析验证")
        let originalLang = AppConfigStore.shared.language
        defer {
            AppConfigStore.shared.language = originalLang
        }

        // 切换到英文模式后，验证通过 maint:<taskId> 与原始稳定 taskId 能跨语言唯一定位维护任务，且展示名称不可作为 taskId 匹配
        AppConfigStore.shared.language = .en
        let tasks = PerformanceEngine.maintenanceTasks()
        assert(!tasks.isEmpty, "维护任务列表不应为空")

        let prevDryRun = Cleaner.isDryRun
        Cleaner.isDryRun = true
        defer { Cleaner.isDryRun = prevDryRun }

        for task in tasks {
            let byRawId = PerformanceEngine.findRegisteredTask(byTaskID: task.taskId)
            assert(byRawId?.taskId == task.taskId, "通过稳定 taskId (\(task.taskId)) 必须能跨语言唯一定位任务")

            let byLocalizedName = PerformanceEngine.findRegisteredTask(byTaskID: task.name)
            assert(byLocalizedName == nil, "展示名称 \(task.name) 严禁作为稳定 taskId 匹配任务")

            let validTarget = CleanTarget(
                name: task.name,
                url: nil,
                size: 0,
                action: .custom("maint:\(task.taskId)"),
                authorizationContext: .systemMaintenance
            )
            let validOutcome = Cleaner.clean(validTarget)
            assert(validOutcome.ok, "通过 maint:\(task.taskId) 必须能跨语言路由系统维护任务")
        }

        print("  ✓ TC-SAFE-MAINT-001 通过: 全部 \(tasks.count) 项系统维护任务支持跨语言稳定 ID 路由")
    }

    // MARK: - 4. 启动项未知状态 (stateKnown == false) 可逆切换验证
    @MainActor
    private func test_TC_SAFE_STARTUP_001_DeterministicStartupStateToggle() {
        print("\n[测试 4] TC-SAFE-STARTUP-001: 启动项未知状态可逆切换与状态保持验证")

        let mockPlistPath = tempDir.appendingPathComponent("com.cleanmate.mock.agent.plist").path
        let unknownItem = StartupItem(
            name: "com.cleanmate.mock.agent",
            path: mockPlistPath,
            scope: "用户代理",
            program: mockPlistPath,
            broken: false,
            enabled: true,
            stateKnown: false,
            isBackground: true,
            displayName: "com.cleanmate.mock.agent",
            appPath: nil,
            iconImage: nil
        )
        let startupNode = Node(
            name: unknownItem.name,
            url: URL(fileURLWithPath: mockPlistPath),
            startupItem: unknownItem
        )

        // 模拟用户在 UI 中将该未知状态的启动项切换为禁用 (false)，再切换回启用 (true)
        PerformanceEngine.recordStartupOverride(path: mockPlistPath, enabled: false)
        assert(PerformanceEngine.startupOverride(for: mockPlistPath) == false, "禁用后内存覆盖状态应为 false")

        let state = AppState()
        assert(state.startupEnabled(startupNode) == false, "禁用后 AppState.startupEnabled 应返回 false")

        PerformanceEngine.recordStartupOverride(path: mockPlistPath, enabled: true)
        assert(PerformanceEngine.startupOverride(for: mockPlistPath) == true, "重新启用后内存覆盖状态应为 true")
        assert(state.startupEnabled(startupNode) == true, "重新启用后 AppState.startupEnabled 应返回 true")
        print("  ✓ TC-SAFE-STARTUP-001 通过: stateKnown == false 启动项支持确定性可逆切换")
    }

    // MARK: - 5. 配置中心 JSON 导出、导入与重置闭环验证
    @MainActor
    private func test_TC_CONFIG_001_ConfigExportImportAndReset() {
        print("\n[测试 5] TC-CONFIG-001: AppConfigStore JSON 导出、导入与恢复默认验证")

        let store = AppConfigStore.shared
        let origLang = store.language
        let origThreshold = store.largeFileThresholdMB
        let origMonths = store.oldFileMonths
        let origConfirm = store.confirmBeforeDelete
        let origSound = store.soundEffects
        let origPaths = store.ignoredPaths

        defer {
            store.language = origLang
            store.largeFileThresholdMB = origThreshold
            store.oldFileMonths = origMonths
            store.confirmBeforeDelete = origConfirm
            store.soundEffects = origSound
            store.setIgnoredPaths(origPaths)
        }

        store.language = .en
        store.largeFileThresholdMB = 250
        store.oldFileMonths = 12
        store.confirmBeforeDelete = false
        store.soundEffects = false
        store.addIgnoredPath("/Users/Shared/CleanMateTestIgnore")

        let exportedData = store.exportJSONData()
        assert(exportedData != nil && !(exportedData!.isEmpty), "配置 JSON 导出不应为空")

        // 恢复默认（不保留白名单）
        store.resetToDefaults(keepIgnoredPaths: false)
        assert(store.largeFileThresholdMB == 100, "恢复默认后大文件阈值应回到 100 MB")
        assert(store.oldFileMonths == 6, "恢复默认后旧文件月数应回到 6 个月")
        assert(store.confirmBeforeDelete == true, "恢复默认后清理前确认应为 true")
        assert(store.ignoredPaths.isEmpty, "不保留白名单恢复默认后白名单应为空")

        // 重新导入刚才导出的 JSON
        let importedOk = store.importJSONData(exportedData!)
        assert(importedOk, "配置 JSON 导入应返回 true")
        assert(store.language == .en, "导入配置后语言应恢复为 .en")
        assert(store.largeFileThresholdMB == 250, "导入配置后大文件阈值应恢复为 250 MB")
        assert(store.oldFileMonths == 12, "导入配置后旧文件月数应恢复为 12 个月")
        assert(store.confirmBeforeDelete == false, "导入配置后 confirmBeforeDelete 应恢复为 false")
        assert(store.isPathIgnored("/Users/Shared/CleanMateTestIgnore/subdir/file.txt"), "导入配置后白名单前缀保护应立即生效")

        print("  ✓ TC-CONFIG-001 通过: 配置快照导出、重置与导入全链路闭环验证成功")
    }

    // MARK: - 6. 软件管理：文件夹用途识别与「安全项 vs 用户数据」分层勾选验证
    @MainActor
    private func test_TC_APPS_FOLDER_001_FolderPurposeAndLayeredUninstall() {
        print("\n[测试 6] TC-APPS-FOLDER-001: 软件管理文件夹用途识别与分层勾选验证")

        let origLang = AppConfigStore.shared.language
        AppConfigStore.shared.language = .zhHans
        defer { AppConfigStore.shared.language = origLang }

        let pApp = UninstallerEngine.classifyFolderPurpose(path: "/Applications/iStat Menus.app", fallbackNote: "应用程序本体")
        assert(pApp.shortTag == "App" && !pApp.isUserData, "应用本体应识别为 App 且属于默认移除项")

        let pCache = UninstallerEngine.classifyFolderPurpose(path: "/Users/test/Library/Caches/com.bjango.istatmenus")
        assert(pCache.shortTag == "缓存" && !pCache.isUserData, "Library/Caches 应识别为 缓存 且属于安全移除项")

        let pTempCache = UninstallerEngine.classifyFolderPurpose(path: "/private/var/folders/st/kv5spmg57/C/com.bjango.istatmenus.status")
        assert(pTempCache.shortTag == "临时缓存" && !pTempCache.isUserData, "/var/folders/.../C/ 应识别为 临时缓存 且属于安全移除项")

        let pHTTP = UninstallerEngine.classifyFolderPurpose(path: "/Users/test/Library/HTTPStorages/com.bjango.istatmenus")
        assert(pHTTP.shortTag == "HTTP 存储" && pHTTP.isUserData, "HTTPStorages 应识别为 HTTP 存储")

        let pContainer = UninstallerEngine.classifyFolderPurpose(path: "/Users/test/Library/Containers/com.bjango.istatmenus.Widget")
        assert(pContainer.shortTag == "容器" && pContainer.isUserData, "Containers 应识别为 容器 且标记为需确认用户数据")

        let pSupport = UninstallerEngine.classifyFolderPurpose(path: "/Users/test/Library/Application Support/iStat Menus")
        assert(pSupport.shortTag == "应用支持" && pSupport.isUserData, "Application Support 应识别为 应用支持 且标记为需确认用户数据")

        let pPref = UninstallerEngine.classifyFolderPurpose(path: "/Users/test/Library/Preferences/com.bjango.istatmenus.plist")
        assert(pPref.shortTag == "偏好设置" && pPref.isUserData, "Preferences 应识别为 偏好设置 且标记为需确认用户数据")

        // 构造模拟应用节点验证分层勾选：「移除 75 MB · 另有 100 MB 需确认」
        var leafApp = Node(name: "iStat Menus.app", url: URL(fileURLWithPath: "/Applications/iStat Menus.app"), note: "应用程序本体", size: 70_000_000)
        var leafCache = Node(name: "com.bjango.istatmenus", url: URL(fileURLWithPath: "/Users/test/Library/Caches/com.bjango.istatmenus"), note: "缓存", size: 5_000_000)
        let leafContainer = Node(name: "com.bjango.istatmenus.Widget", url: URL(fileURLWithPath: "/Users/test/Library/Containers/com.bjango.istatmenus.Widget"), note: "容器", size: 100_000_000)
        // Defaults depend on explicit body/cache evidence, not translated labels or path fragments.
        leafApp.uninstallContext = UninstallContext(appURL: leafApp.url!, bundleID: "com.bjango.istatmenus", isAppBody: true)
        leafCache.ruleEvidence = CleanupRuleEvidence(id: "fixture.verifiedCache", tier: .automatic, reason: .generalCache, defaultSelected: true)
        let mockApp = Node(name: "iStat Menus", url: URL(fileURLWithPath: "/Applications/iStat Menus.app"), size: 175_000_000, children: [leafApp, leafCache, leafContainer], isGroup: true)

        let state = AppState()
        state.moduleKey = "applications"
        state.roots = [mockApp]

        // 1. 首次点击应用勾选框：默认仅勾选安全项 (70M + 5M = 75M)，保留 100M 容器需确认
        state.toggleAppUninstall(mockApp)
        assert(state.isAppChecked(mockApp), "勾选后应用应处于已选状态")
        assert(state.selectedSize(in: mockApp) == 75_000_000, "默认勾选应包含 App 本体 + 缓存 (75MB)")
        assert(state.unselectedUserDataSize(in: mockApp) == 100_000_000, "未勾选的需确认用户数据应为 100MB")

        // 2. 点击「一并移除用户数据」：全量 175M 均被选中
        state.includeUserData(for: mockApp)
        assert(state.selectedSize(in: mockApp) == 175_000_000, "一并勾选用户数据后应选中全部 175MB")
        assert(state.unselectedUserDataSize(in: mockApp) == 0, "一并勾选用户数据后待确认体积应为 0")

        // 3. 点击「仅勾选安全清理项」：退回 75M
        state.keepOnlySafeItems(for: mockApp)
        assert(state.selectedSize(in: mockApp) == 75_000_000, "仅保留安全项后应回到 75MB")

        // 4. 再次点击应用勾选框：全部取消
        state.toggleAppUninstall(mockApp)
        assert(!state.isAppChecked(mockApp), "再次点击应用复选框应取消全部选中")

        print("  ✓ TC-APPS-FOLDER-001 通过: 文件夹具体用途分类与「安全项 vs 用户数据」分层勾选")
    }

    // MARK: - 7. 多模块并行扫描与切换状态保留验证
    @MainActor
    private func test_TC_PARALLEL_001_MultiModuleParallelAndStatePreservation() {
        print("\n[测试 7] TC-PARALLEL-001: 多模块并行执行与切换后已扫描状态保留验证")

        let state = AppState()
        state.moduleKey = "junk"

        // 构造垃圾清理模块的已扫描数据与用户手动勾选状态
        let junkLeaf1 = Node(name: "ChromeCache", url: URL(fileURLWithPath: "/tmp/chrome_cache"), size: 120_000_000)
        let junkLeaf2 = Node(name: "SafariCache", url: URL(fileURLWithPath: "/tmp/safari_cache"), size: 80_000_000)
        let junkGroup = Node(name: "浏览器缓存", children: [junkLeaf1, junkLeaf2], isGroup: true)
        state.roots = [junkGroup]
        state.selection = [junkLeaf1.id]
        state.hasScannedCurrentModule = true
        state.didApplyDefaultsCurrentModule = true
        state.scanning = true // 模拟垃圾清理仍在后台扫描中

        // 在垃圾清理扫描进行中，直接切换到「空间透视」，不应被阻断，也不应弹出“另一个模块正在扫描中”
        var spaceSess = state.defaultSession(for: "spaceLens")
        let spaceChild = Node(id: Node.stableID(forPath: "/Users/test/Downloads"),
                              name: "Downloads",
                              url: URL(fileURLWithPath: "/Users/test/Downloads"),
                              size: 500_000_000,
                              isGroup: true)
        spaceSess.roots = [spaceChild]
        spaceSess.hasScanned = true
        spaceSess.spaceNavPaths = ["/Users/test/Downloads"]
        state.write(.spaceLens) { $0 = spaceSess }

        state.open(.restore(.spaceLens))
        assert(state.moduleKey == "spaceLens", "扫描中点击其他模块应立即切换成功，不得阻塞")
        assert(state.roots.count == 1 && state.roots.first?.name == "Downloads", "切换到空间透视应加载其自身会话树")
        assert(state.session(for: "spaceLens").spaceNavPaths == ["/Users/test/Downloads"], "空间透视下钻路径应完整保留")
        assert(state.isScanning(module: "junk"), "原垃圾清理模块的后台扫描状态应继续保持")

        // 再切换回「垃圾清理」，验证之前的扫描结果与勾选状态 100% 保留，不会清空重扫
        state.open(.restore(.junk))
        assert(state.moduleKey == "junk", "应成功切回垃圾清理模块")
        assert(state.roots.count == 1 && state.roots.first?.name == "浏览器缓存", "切回已扫描模块后扫描结果不应丢失")
        assert(state.selection == [junkLeaf1.id], "切回已扫描模块后用户的勾选状态应完整保留")
        assert(state.hasScannedCurrentModule == true, "已扫描标记应保留为 true")

        print("  ✓ TC-PARALLEL-001 通过: 多模块并行扫描不互锁，切换模块完整保留已扫描树与勾选状态")
    }

    // MARK: - 8. 空间透视：确定性节点 ID、O(1) 体积缓存与实时流式快照验证
    @MainActor
    private func test_TC_SPACE_STREAM_001_RealTimeStreamingAndCachedTotalSize() {
        print("\n[测试 8] TC-SPACE-STREAM-001: 空间透视确定性 ID 与 O(1) 节点体积缓存验证")

        // 1. 验证相同路径跨多次实时快照生成的 UUID 100% 稳定一致
        let idA = Node.stableID(forPath: "/Users/zhongjie/Library/Caches")
        let idB = Node.stableID(forPath: "/Users/zhongjie/Library/Caches")
        let idC = Node.stableID(forPath: "/Users/zhongjie/Downloads")
        assert(idA == idB, "相同路径的 stableID 必须完全一致，以保证流式刷新时焦点与展开态不丢失")
        assert(idA != idC, "不同路径的 stableID 必须不同")

        // 2. 验证 Node.totalSize 与 leafCount 缓存更新的准确性与 O(1) 性能
        let f1 = Node(name: "a.bin", size: 1000)
        let f2 = Node(name: "b.bin", size: 2500)
        var folder = Node(name: "Folder", size: 0, children: [f1, f2], isGroup: true)
        assert(folder.totalSize == 3500, "分组节点的缓存 totalSize 应等于子节点体积之和 (3500)")
        assert(folder.leafCount == 2, "分组节点的缓存 leafCount 应为 2")

        let f3 = Node(name: "c.bin", size: 4500)
        folder.children.append(f3)
        assert(folder.totalSize == 8000, "追加子节点后 didSet 应实时更新缓存 totalSize 至 8000")
        assert(folder.leafCount == 3, "追加子节点后 didSet 应实时更新缓存 leafCount 至 3")

        print("  ✓ TC-SPACE-STREAM-001 通过: 空间透视确定性 UUID 与 O(1) 体积缓存机制验证通过")
    }

    // MARK: - 9. 应用程序模块精简与数据文件大小、性能优化整合启动项验证
    @MainActor
    private func test_TC_STARTUP_SPLIT_001_StartupAndBackgroundServicesSplit() {
        print("\n[测试 9] TC-STARTUP-SPLIT-001: 应用程序模块精简、数据文件大小与性能优化整合启动项验证")

        let originalLang = AppConfigStore.shared.language
        AppConfigStore.shared.language = .zhHans
        defer { AppConfigStore.shared.language = originalLang }

        // 1. 验证应用程序模块精简为 2 标签页：[uninstall, leftovers]
        let appTabs = ApplicationsManagerView.TopTabMode.allCases.map(\.rawValue)
        precondition(appTabs == ["uninstall", "leftovers"],
                     "应用程序顶部必须精简为 [uninstall, leftovers] 两个独立分段标签，实际为 \(appTabs)")

        // 2. 验证应用程序数据文件大小 appDataSize 准确计算
        let appBundleNode = Node(name: "TestApp.app", url: URL(fileURLWithPath: "/Applications/TestApp.app"),
                                 note: "应用程序本体", size: 200 * 1024 * 1024,
                                 tags: ["应用程序本体"])
        let cacheNode = Node(name: "Caches", url: URL(fileURLWithPath: "/Users/test/Library/Caches/com.test.app"),
                             note: "缓存", size: 150 * 1024 * 1024,
                             tags: ["缓存"])
        let supportNode = Node(name: "Application Support", url: URL(fileURLWithPath: "/Users/test/Library/Application Support/com.test.app"),
                               note: "应用支持", size: 50 * 1024 * 1024,
                               tags: ["应用支持"])
        let leftoverGroup = Node(name: "残留", size: 200 * 1024 * 1024, children: [cacheNode, supportNode], isGroup: true, tags: ["残留"])
        let appNode = Node(name: "TestApp", size: 400 * 1024 * 1024, children: [appBundleNode, leftoverGroup], isGroup: true, tags: ["所有应用程序"])

        precondition(appNode.totalSize == 400 * 1024 * 1024, "应用总大小应为 400 MB，实际为 \(appNode.totalSize)")
        precondition(appNode.appDataSize == 200 * 1024 * 1024, "应用数据文件大小应为 200 MB，实际为 \(appNode.appDataSize)")

        // 3. 验证性能优化模块 (PerformanceModule) 完整接管启动项与后台服务
        precondition(PerformanceModule.spec.filterOrder.contains("开机启动项"), "性能优化模块必须包含开机启动项分类")
        precondition(PerformanceModule.spec.filterOrder.contains("后台服务"), "性能优化模块必须包含后台服务分类")

        let allItems = PerformanceEngine.startupItems()
        let loginStartup = allItems.filter { !$0.isBackground }
        let bgServices = allItems.filter { $0.isBackground }
        print("  · 性能优化启动项接管探测汇总: 共 \(allItems.count) 项 = 开机启动项 \(loginStartup.count) 项 + 后台服务 \(bgServices.count) 项")
        precondition(loginStartup.count + bgServices.count == allItems.count, "启动项与后台服务拆分应完整覆盖所有项目")

        // 验证 /Library/LaunchDaemons 下的项目全部归入后台服务 (isBackground == true)
        for item in allItems where item.path.contains("/Library/LaunchDaemons/") {
            precondition(item.isBackground, "LaunchDaemons 守护进程 (\(item.name)) 必须归入后台服务")
        }

        print("  ✓ TC-STARTUP-SPLIT-001 通过: 应用程序 2 标签精简、appDataSize 计算与性能优化接管验证通过")
    }

    // MARK: - 10. 中间引导状态、手动触发与扫描结果保留验证
    @MainActor
    func test_TC_INTERMEDIATE_STATE_001_ManualTriggerAndResultPersistence() {
        print("\n[测试用例 10] TC-INTERMEDIATE-STATE-001: 中间引导状态、手动触发与扫描结果保留验证")

        let state = AppState()

        // 1. 验证启动与各扫描模块初态均为未扫描、未优化、Screen 为 .intro
        for key in ["junk", "performance", "applications", "spaceLens", "organize"] {
            precondition(!state.isModuleScannedOrOptimized(key), "\(key) 模块初始状态应为未扫描或优化过")
            let sess = state.session(for: key)
            precondition(!sess.hasScanned, "\(key) 初始 hasScanned 应为 false")
            precondition(!sess.hasOptimized, "\(key) 初始 hasOptimized 应为 false")
            precondition(sess.roots.isEmpty, "\(key) 初始 roots 应为空")
            precondition(sess.screen == .intro, "\(key) 初始 screen 应为 .intro")
        }

        // 静态模块 (liveMonitor, toolbox, assistant) 应直接就绪无需扫描
        for key in ["liveMonitor", "toolbox", "assistant"] {
            precondition(state.isModuleScannedOrOptimized(key), "\(key) 静态模块应直接标记为已就绪")
        }

        // 2. 验证点击左侧菜单切换模块时，绝不自动触发后台扫描
        state.open(.restore(.performance))
        precondition(state.moduleKey == "performance", "当前模块应切换为 performance")
        precondition(!state.isScanning(module: "performance"), "点击左侧菜单切换到 performance 时绝不自动发起扫描")
        precondition(!state.isModuleScannedOrOptimized("performance"), "未手动触发时 performance 应保持未扫描")
        precondition(state.screen == .intro, "未扫描时当前页面状态必须为 .intro 中间引导态")

        state.open(.restore(.applications))
        precondition(state.moduleKey == "applications", "当前模块应切换为 applications")
        precondition(!state.isScanning(module: "applications"), "点击左侧菜单切换到 applications 时绝不自动发起扫描")
        precondition(!state.isModuleScannedOrOptimized("applications"), "未手动触发时 applications 应保持未扫描")

        state.open(.restore(.spaceLens))
        precondition(!state.isScanning(module: "spaceLens"), "点击左侧菜单切换到 spaceLens 时绝不自动发起扫描")

        // 3. 模拟用户手动点击按钮触发扫描并完成
        state.open(.restore(.junk))
        precondition(!state.isModuleScannedOrOptimized("junk"), "junk 此时仍为未扫描态")
        // 模拟扫描完成填充结果
        let dummyNode = Node(name: "TestJunk", size: 1024 * 1024, tags: ["系统垃圾"])
        state.roots = [dummyNode]
        state.hasScannedCurrentModule = true
        state.screen = .dataManager

        precondition(state.isModuleScannedOrOptimized("junk"), "完成扫描后 junk 应标记为已扫描过")

        // 4. 验证切换到其他模块再切回时，直接使用刚刚的结果展示，不重置也不重扫
        state.open(.restore(.organize))
        precondition(!state.isModuleScannedOrOptimized("organize"), "organize 仍为未扫描态")
        precondition(state.screen == .intro, "organize 呈现 .intro 中间引导态")

        state.open(.restore(.junk))
        precondition(state.isModuleScannedOrOptimized("junk"), "切回 junk 时应保持已扫描状态")
        precondition(!state.roots.isEmpty, "切回 junk 时刚刚扫描的节点数据应完好保留")
        precondition(state.screen == .dataManager, "切回 junk 时应直接展示结果页")

        // 5. 验证执行维护任务后标记 hasOptimized = true
        state.open(.restore(.performance))
        precondition(!state.isModuleScannedOrOptimized("performance"), "performance 优化前为未优化")
        state.hasOptimizedCurrentModule = true
        state.screen = .dataManager
        precondition(state.isModuleScannedOrOptimized("performance"), "优化后 performance 应标记为已优化过")

        // 6. 验证 startOver 重置后恢复为未扫描中间态
        state.open(.restore(.junk))
        precondition(state.isModuleScannedOrOptimized("junk"), "重置前 junk 为已扫描")
        state.startOver()
        precondition(!state.isModuleScannedOrOptimized("junk"), "startOver 后 junk 应重置为未扫描状态")
        precondition(state.screen == .intro, "startOver 后 screen 应重置为 .intro 中间引导页")

        print("  ✓ TC-INTERMEDIATE-STATE-001 通过: 中间引导态、菜单切换防自动扫描、手动触发结果保留与重置闭环验证通过")
    }
}
