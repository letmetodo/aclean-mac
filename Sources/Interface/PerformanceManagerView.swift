import SwiftUI
import AppKit

// ============================================================
//  PerformanceSingleColumnView (SmartOptimizeView) —— 性能优化模块（极简卡片式设计）
//
//  视觉与交互特征（交互与视觉规范）：
//    1. 顶部区域：
//       - 左侧大标题「优化 Mac」，副标题「修复小毛病 · 执行系统维护」
//       - 右上角提供 `[系统维护 | 开机启动项 | 后台项目]` 极简胶囊切换与 `↻` 重新扫描按钮
//    2. 「系统维护」视图：
//       - 第一分组卡片：「修复小毛病」（输入法切换 / 通知中心 / 通用剪贴板 / 访达与程序坞），右侧一键「刷新」
//       - 4 大系统维护分类卡片（与垃圾清理同款极简卡片：左侧 Checkbox + 标题 + `已选 X/Y` + 后果说明 + 右侧状态與展开箭头）：
//         · 启动加速
//         · 系统数据库
//         · 网络与搜索
//         · 系统维护
//    3. 「开机启动项 / 后台项目」视图：
//       - 极简列表行（应用图标 + 名称 + 路径/签名状态 + 右侧启用/停用开关胶囊，严禁删除操作）
//    4. 底部操作栏：
//       - 「系统维护任务」保留：`已选 N 项   全选 · 全不选 · 推荐` + 高对比度白色胶囊大按钮 `运行任务 · N 项`
//       - 「开机启动项 / 后台服务」专注状态启闭，无废纸篓与勾选框，确保系统服务绝不被误删
// ============================================================

typealias SmartOptimizeView = PerformanceSingleColumnView

enum PerformanceGroupKind: String, CaseIterable, Identifiable {
    case launchSpeed   = "launchSpeed"
    case databases     = "databases"
    case networkSearch = "networkSearch"
    case maintenance   = "maintenance"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .launchSpeed:   return L10n.localized(.perfLaunchSpeed)
        case .databases:     return L10n.localized(.perfStorageSnapshots)
        case .networkSearch: return L10n.localized(.perfNetworkAndSearch)
        case .maintenance:   return L10n.localized(.perfSystemMaintenance)
        }
    }

    var subtitle: String {
        switch self {
        case .launchSpeed:
            return L10n.localized(.taskRebuildLaunchServicesDesc)
        case .databases:
            return L10n.localized(.perfStorageSnapshotsDesc)
        case .networkSearch:
            return L10n.localized(.taskFlushDnsAndSpotlightDesc)
        case .maintenance:
            return L10n.localized(.taskFreePurgeableAndRunMaintenanceDesc)
        }
    }
}

struct PerformanceSingleColumnView: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var config = AppConfigStore.shared
    @ObservedObject var l10n = L10n.shared

    @State var selectedTaskIDs: Set<String> = []
    @State var expandedGroups: Set<PerformanceGroupKind> = [.launchSpeed, .databases, .networkSearch, .maintenance]
    @State var didInitRecommended = false
    @State var isSearchExpanded = false

    let tabMaintenanceId = "maintenanceTasks"
    let tabStartupId = "loginItems"
    let tabBackgroundId = "backgroundServices"

    var currentTab: String {
        if state.category.isEmpty || AppState.isAllCategory(state.category) {
            return tabMaintenanceId
        }
        return state.category
    }

    var isMaintenanceTab: Bool {
        currentTab == tabMaintenanceId || currentTab == "Maintenance Tasks" || currentTab == L10n.localized(.maintenanceTasks)
    }

    var isStartupTab: Bool {
        currentTab == tabStartupId || currentTab == "Login Items" || currentTab == L10n.localized(.loginItems)
    }

    var isBackgroundTab: Bool {
        currentTab == tabBackgroundId || currentTab == "Background Items" || currentTab == "Background Services" || currentTab == L10n.localized(.categoryBackgroundServices) || currentTab == L10n.localized(.backgroundItems)
    }

    var allTasks: [PerformanceEngine.MaintenanceTask] {
        let tasks = PerformanceEngine.maintenanceTasks()
        let hasThinSnapshot = tasks.contains { $0.taskId == "thinTimeMachine" }
        return hasThinSnapshot ? tasks.filter { $0.taskId != "purgeableSpace" } : tasks
    }

    func tasks(for group: PerformanceGroupKind) -> [PerformanceEngine.MaintenanceTask] {
        allTasks.filter { classifyTask($0) == group }
    }

    func classifyTask(_ task: PerformanceEngine.MaintenanceTask) -> PerformanceGroupKind {
        switch task.id {
        case "quickLookCache", "disableDSStore", "launchServices", "repairPermissions":
            return .launchSpeed
        case "vacuumDatabases", "thinTimeMachine", "sqliteVacuum", "timeMachineThin":
            return .databases
        case "flushDNS", "reindexSpotlight", "spotlightReindex":
            return .networkSearch
        default:
            return .maintenance
        }
    }

    var startupNodes: [Node] {
        let root = state.roots.first {
            if isStartupTab {
                return $0.tags.contains("Login Items") || $0.name == "Login Items" || $0.tags.contains(L10n.localized(.loginItems)) || $0.name == L10n.localized(.loginItems)
            } else if isBackgroundTab {
                return $0.tags.contains("Background Services") || $0.tags.contains("Background Items") || $0.name == "Background Services" || $0.name == "Background Items" || $0.tags.contains(L10n.localized(.categoryBackgroundServices)) || $0.name == L10n.localized(.categoryBackgroundServices)
            } else {
                return $0.tags.contains(currentTab) || $0.name == currentTab
            }
        }
        var list = root?.children ?? []
        if !state.search.isEmpty {
            let q = state.search.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(q)
                    || $0.path.lowercased().contains(q)
                    || $0.note.lowercased().contains(q)
                    || ($0.startupItem?.displayName.lowercased().contains(q) ?? false)
                    || ($0.startupItem?.program.lowercased().contains(q) ?? false)
            }
        }
        return list
    }

    var body: some View {
        ZStack {
            if state.scanning {
                perfScanningStageView
            } else if !state.hasScannedCurrentModule && !state.hasOptimizedCurrentModule && state.roots.isEmpty {
                perfIdleStageView
            } else {
                perfResultStageView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: state.scanning)
        .onAppear {
            if !didInitRecommended {
                applyRecommendedTasks()
                didInitRecommended = true
            }
        }
    }

    // MARK: - 0. 顶部统一标题栏（与系统监控完全对齐的左上角标题与规格副标题）

    var topHeaderStrip: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.localized(.modulePerformance))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.text)

                if !state.hasScannedCurrentModule && !state.hasOptimizedCurrentModule && state.roots.isEmpty {
                    Text(L10n.localized(.perfHeroSubtitle))
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                } else if isMaintenanceTab {
                    Text("\(L10n.localized(.quickGlitchFixes)) · \(L10n.localized(.actionRunSystemMaintenance)) · \(L10n.localized(.labelSelected)) \(selectedTaskIDs.count)/\(allTasks.count) \(L10n.localized(.unitItems))")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                        .monospacedDigit()
                } else if isStartupTab {
                    let enabledCount = startupNodes.filter { state.startupEnabled($0) }.count
                    Text("\(L10n.localized(.loginItems)) · \(startupNodes.count) \(L10n.localized(.unitItems)) · \(L10n.localized(.statusEnabled)) \(enabledCount) \(L10n.localized(.unitItems))")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                        .monospacedDigit()
                } else {
                    let enabledCount = startupNodes.filter { state.startupEnabled($0) }.count
                    Text("\(L10n.localized(.categoryBackgroundServices)) · \(startupNodes.count) \(L10n.localized(.unitItems)) · \(L10n.localized(.runningOrEnabled)) \(enabledCount) \(L10n.localized(.unitItems))")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 12)

            if state.hasScannedCurrentModule || state.hasOptimizedCurrentModule || !state.roots.isEmpty {
                HeaderIconButton(
                    icon: "arrow.clockwise",
                    spinning: state.scanning,
                    helpText: L10n.localized(.actionRescan)
                ) {
                    state.startScan(for: "performance", forceRestart: true)
                }
            }
        }
    }

    // MARK: - 第一幕：待命态 (Act 1: Idle Stage)

    var perfIdleStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Spacer(minLength: 6)

                    // 1. 核心悬浮脉冲球体（带闪电/加速图标与微光呼吸动效）
                    PulseOrbStageView(
                        isScanning: false,
                        sizeText: "",
                        unitText: "",
                        subtitle: L10n.localized(.statusReady),
                        themeColor: Theme.accent,
                        diameter: 140,
                        symbol: "bolt.fill"
                    )

                    // 2. 标题与说明副标题
                    VStack(spacing: 6) {
                        Text(L10n.localized(.perfHeroTitle))
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.text)

                        Text(L10n.localized(.perfHeroSubtitle))
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.sub)
                    }

                    // 3. 4 大性能优化 Bento 预览微卡片
                    HStack(spacing: 10) {
                        IdlePerfFeatureCard(
                            group: .launchSpeed,
                            tag: L10n.localized(.perfTagStartupPermissions),
                            systemName: "bolt.fill",
                            primaryColor: Color(red: 0.98, green: 0.68, blue: 0.22),
                            secondaryColor: Color(red: 0.90, green: 0.48, blue: 0.10)
                        )

                        IdlePerfFeatureCard(
                            group: .databases,
                            tag: L10n.localized(.perfTagLocalSnapshots),
                            systemName: "clock.arrow.circlepath",
                            primaryColor: Color(red: 0.24, green: 0.82, blue: 0.48),
                            secondaryColor: Color(red: 0.10, green: 0.62, blue: 0.35)
                        )

                        IdlePerfFeatureCard(
                            group: .networkSearch,
                            tag: L10n.localized(.perfTagDnsSpotlight),
                            systemName: "network",
                            primaryColor: Color(red: 0.20, green: 0.75, blue: 0.98),
                            secondaryColor: Color(red: 0.10, green: 0.45, blue: 0.92)
                        )

                        IdlePerfFeatureCard(
                            group: .maintenance,
                            tag: L10n.localized(.perfTagSpaceReclaimScripts),
                            systemName: "wrench.and.screwdriver.fill",
                            primaryColor: Color(red: 0.66, green: 0.36, blue: 0.96),
                            secondaryColor: Color(red: 0.46, green: 0.20, blue: 0.86)
                        )
                    }
                    .padding(.horizontal, 16)

                    // 4. 底部主操作按钮 + 辅助入口
                    VStack(spacing: 8) {
                        GlowingPillButton(
                            title: L10n.localized(.perfActionStartDiagnosis),
                            icon: "sparkles",
                            tint: Theme.accent,
                            width: 184,
                            height: 42
                        ) {
                            state.startScan(for: "performance", forceRestart: true)
                        }

                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                state.hasScannedCurrentModule = true
                            }
                        } label: {
                            Text(L10n.localized(.perfDirectManageLink))
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(Theme.sub)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)

                    // 5. 安全保障标语
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.accent.opacity(0.85))
                        Text(L10n.localized(.perfSafetyNote))
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.tert)
                    }

                    Spacer(minLength: 6)
                }
                .frame(maxWidth: .infinity, minHeight: 460)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 第二幕：体检中 (Act 2: Scanning Stage)

    var perfScanningStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 34)
                .padding(.top, 24)
                .padding(.bottom, 6)

            VStack(spacing: 26) {
                Spacer()

                PulseOrbStageView(
                    isScanning: true,
                    sizeText: "\(Int(state.scanProgress * 100))",
                    unitText: "%",
                    subtitle: L10n.localized(.perfDiagnosingSubtitle),
                    themeColor: Theme.accent,
                    diameter: 220
                )

                VStack(spacing: 10) {
                    Text(L10n.localized(.perfScanningMaintenanceTasks))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)

                    Text(state.scanStatus.isEmpty ? L10n.localized(.perfScanningStartupServices) : state.scanStatus)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 520)
                }

                Button {
                    state.stopScan()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 12))
                        Text(L10n.localized(.stopDiagnosis))
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .foregroundStyle(Theme.sub)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Theme.card.opacity(0.8))
                            .overlay(Capsule().strokeBorder(Theme.sep, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 第三幕：结果与管理态 (Act 3: Result Stage)

    var perfResultStageView: some View {
        VStack(alignment: .leading, spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 34)
                .padding(.top, 16)
                .padding(.bottom, 10)

            Divider().background(Theme.sep)

            moduleTopBar

            ScrollView(showsIndicators: true) {
                if isMaintenanceTab {
                    VStack(alignment: .leading, spacing: 12) {
                        quickGlitchCard
                            .staggeredAppear(index: 0)

                        ForEach(Array(PerformanceGroupKind.allCases.enumerated()), id: \.element.id) { idx, group in
                            let groupTasks = tasks(for: group)
                            if !groupTasks.isEmpty {
                                optimizeGroupCard(group: group, tasks: groupTasks)
                                    .staggeredAppear(index: idx + 1)
                            }
                        }
                    }
                    .padding(.horizontal, 34)
                    .padding(.vertical, 6)
                    .padding(.bottom, 12)
                } else {
                    startupListSection
                        .padding(.horizontal, 34)
                        .padding(.vertical, 6)
                        .padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isMaintenanceTab {
                maintenanceFooter
            }
        }
    }

    // MARK: - 1. 顶部控制栏（左侧 `[系统维护任务 | 开机启动项 | 后台服务]`，与应用程序 1:1 对齐展示方式和位置）

    var moduleTopBar: some View {
        HStack(alignment: .center, spacing: 14) {
            // 左侧高定滑动光块分段器（与应用程序完全对齐：靠左对齐，一致的样式与内边距）
            SlidingSegmentedControl(
                items: [
                    SlidingSegmentItem(id: tabMaintenanceId, title: L10n.localized(.maintenanceTasks)),
                    SlidingSegmentItem(id: tabStartupId, title: L10n.localized(.loginItems)),
                    SlidingSegmentItem(id: tabBackgroundId, title: L10n.localized(.categoryBackgroundServices))
                ],
                selection: Binding(
                    get: {
                        if isMaintenanceTab { return tabMaintenanceId }
                        if isStartupTab { return tabStartupId }
                        if isBackgroundTab { return tabBackgroundId }
                        return tabMaintenanceId
                    },
                    set: { newTab in
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                            state.category = newTab
                            state.selection.removeAll()
                            if newTab == tabMaintenanceId {
                                state.search = ""
                                isSearchExpanded = false
                            }
                        }
                    }
                )
            )

            Spacer(minLength: 16)

            // 右侧搜索框 / 放大镜按钮 `🔍`（开机启动项与后台服务支持实时搜索，与应用程序对齐在右侧）
            if !isMaintenanceTab {
                HStack(spacing: 8) {
                    if isSearchExpanded || !state.search.isEmpty {
                        SearchField(text: $state.search, placeholder: L10n.localized(.searchStartupItemsPlaceholder))
                            .frame(width: 180)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }

                    HeaderIconButton(
                        icon: (isSearchExpanded && !state.search.isEmpty) ? "xmark.circle.fill" : "magnifyingglass",
                        helpText: L10n.localized(.actionSearch)
                    ) {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            isSearchExpanded.toggle()
                            if !isSearchExpanded {
                                state.search = ""
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 34)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - 1. 「修复小毛病」卡片

    var quickGlitchCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.localized(.quickGlitchFixes))
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundStyle(Theme.text)
                    Text(L10n.localized(.performanceQuickFixesSubtitle))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.sub)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()
                .background(Theme.sep)
                .padding(.horizontal, 18)

            VStack(spacing: 0) {
                ForEach(PerformanceEngine.quickGlitchFixes()) { fix in
                    PerformanceQuickRow(task: fix)
                }
            }
            .padding(.vertical, 6)
        }
        .glassBentoCard(cornerRadius: 13, isHighlighted: false, isHovered: false, padding: 0)
    }

    // MARK: - 2. 4 大系统维护分组卡片

    func optimizeGroupCard(group: PerformanceGroupKind, tasks: [PerformanceEngine.MaintenanceTask]) -> some View {
        let isExpanded = expandedGroups.contains(group)
        let selCount = tasks.filter { selectedTaskIDs.contains($0.id) }.count
        let checkState: CheckboxState = {
            if selCount == 0 { return .none }
            if selCount == tasks.count { return .all }
            return .partial
        }()
        let completedCount = tasks.filter {
            let st = state.maintenanceRuns[$0.name]
            return st == "Completed" || st == tr(.completed)
        }.count

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                FluidCheckbox(state: checkState, tint: Theme.accent, a11yLabel: L10n.localized(.actionSelectAll)) {
                    let shouldSelectAll = (checkState != .all)
                    for t in tasks {
                        if shouldSelectAll {
                            selectedTaskIDs.insert(t.id)
                        } else {
                            selectedTaskIDs.remove(t.id)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(group.title)
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundStyle(Theme.text)

                        MetallicBadge(
                            text: "\(selCount)/\(tasks.count) \(L10n.localized(.unitItems))",
                            color: selCount > 0 ? Theme.accent : Theme.tert
                        )
                    }

                    Text(group.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                }

                Spacer(minLength: 16)

                HStack(spacing: 12) {
                    if completedCount > 0 {
                        Text("\(L10n.localized(.completed)) \(completedCount)/\(tasks.count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.green)
                            .monospacedDigit()
                    } else {
                        Text("\(selCount) \(L10n.localized(.tasksToRun))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selCount > 0 ? Theme.accent : Theme.sub)
                            .monospacedDigit()
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Theme.sub)
                        .frame(width: 16)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.16)) {
                    if expandedGroups.contains(group) {
                        expandedGroups.remove(group)
                    } else {
                        expandedGroups.insert(group)
                    }
                }
            }

            if isExpanded {
                Divider()
                    .background(Theme.sep)
                    .padding(.horizontal, 18)

                VStack(spacing: 0) {
                    ForEach(tasks) { task in
                        PerformanceTaskRow(
                            task: task,
                            isSelected: selectedTaskIDs.contains(task.id),
                            onToggle: {
                                if selectedTaskIDs.contains(task.id) {
                                    selectedTaskIDs.remove(task.id)
                                } else {
                                    selectedTaskIDs.insert(task.id)
                                }
                            }
                        )
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .glassBentoCard(cornerRadius: 13, isHighlighted: false, isHovered: false, padding: 0)
    }

    // MARK: - 3. 启动项与后台服务列表

    @ViewBuilder
    var startupListSection: some View {
        if state.scanning && state.roots.isEmpty {
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                Text(L10n.localized(.scanningStartupItemsAndBackgroundServices))
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.sub)
            }
            .frame(maxWidth: .infinity, minHeight: 320)
        } else if startupNodes.isEmpty {
            VStack(spacing: 10) {
                Text(isStartupTab ? L10n.localized(.noStartupItemsDetected) : L10n.localized(.noBackgroundServicesDetected))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text(isStartupTab
                     ? L10n.localized(.startupUserLoginItemsEmptyNote)
                     : L10n.localized(.startupBackgroundDaemonsEmptyNote))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.sub)
            }
            .frame(maxWidth: .infinity, minHeight: 320)
        } else {
            VStack(spacing: 8) {
                ForEach(Array(startupNodes.enumerated()), id: \.element.id) { index, node in
                    StartupItemRow(node: node)
                        .staggeredAppear(index: min(index, 16))
                }
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - 维护任务底部操作栏

    var maintenanceFooter: some View {
        HStack(alignment: .center, spacing: 14) {
            let total = allTasks.count
            let sel = selectedTaskIDs.count
            Text("\(L10n.localized(.labelSelected)) \(sel) \(L10n.localized(.unitItems))")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(Theme.text)
                .monospacedDigit()

            HStack(spacing: 6) {
                ActionLink(title: tr(.actionSelectAll), enabled: sel < total) {
                    selectedTaskIDs = Set(allTasks.map(\.id))
                }
                Text("·").foregroundStyle(Theme.tert)
                ActionLink(title: tr(.actionDeselectAll), enabled: sel > 0) {
                    selectedTaskIDs.removeAll()
                }
                Text("·").foregroundStyle(Theme.tert)
                ActionLink(title: tr(.actionSmartRecommended), enabled: true) {
                    applyRecommendedTasks()
                }
            }

            Spacer(minLength: 16)

            GlowingPillButton(
                title: sel > 0
                    ? "\(L10n.localized(.actionRunTasks)) · \(sel) \(L10n.localized(.unitItems))"
                    : L10n.localized(.actionRunTasks),
                icon: "play.fill",
                tint: Theme.accent,
                isEnabled: sel > 0,
                width: 170,
                height: 40
            ) {
                runSelectedTasks()
            }
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 10)
        .background(
            ZStack {
                VisualEffectView(material: .headerView, blendingMode: .withinWindow)
                Theme.card.opacity(Theme.isDark ? 0.75 : 0.88)
            }
        )
        .overlay(alignment: .top) {
            Divider().background(Theme.sep.opacity(0.6))
        }
    }

    func applyRecommendedTasks() {
        // 默认推荐勾选无需管理员权限的轻量日常维护项
        selectedTaskIDs = Set(allTasks.filter { !$0.needsAdmin }.map(\.id))
    }

    func runSelectedTasks() {
        let targets = allTasks.filter { selectedTaskIDs.contains($0.id) }
        guard !targets.isEmpty else { return }
        state.runMaintenanceTasks(targets)
    }
}
