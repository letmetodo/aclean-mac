import SwiftUI
import AppKit

// ============================================================
//  ApplicationsManagerView —— 应用程序模块（已安装应用与残留管理）
//
//  单页通栏交互设计：
//    1. 采用单页通栏布局；
//    2. 顶部控制栏：
//       - 左侧：`[卸载 | 残留 | 启动项]` 胶囊分段器 + `↻` 刷新按钮
//       - 右侧：`名称   占用体积   最近使用 ↑   安装日期` 内联文字排序 + `🔍` 搜索展开按钮
//    3. 统计副标题行：`已安装 App   74 个 · 53 GB`
//    4. 应用列表行与内联展开（内联文件夹展开视图）：
//       - 未展开时：36×36 图标 + 应用名 + `版本 · 总大小 · X个月前有活动` + 右侧复选框
//       - 选中/展开时：右侧展示 `移除 75 MB · 另有 100.4 MB 需确认 ⌄` + 复选框
//       - 展开详情分为「清除」（默认勾选：App 本体、缓存、临时缓存、HTTP 存储、日志）与
//         「需要确认」（默认不勾选：容器、应用支持、偏好设置、启动代理），每行清晰展示：
//         `[复选框] [文件夹用途标签 (App/缓存/临时缓存/HTTP 存储/容器/应用支持/偏好设置/日志)] [路径 + 具体用途说明] [体积]`
//    5. 底部操作栏：
//       - 左侧：`[App 图标] 示例应用 · 1 个 App · 75 MB   一并移除用户数据 · 取消选择`
//       - 右侧：高对比度白色胶囊大按钮 `移除 1 项`
// ============================================================

struct ApplicationsManagerView: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var config = AppConfigStore.shared
    @ObservedObject var l10n = L10n.shared

    typealias TopTabMode = ApplicationsTab

    @State var activeTab: TopTabMode = .uninstall
    @State var expandedAppIDs: Set<UUID> = []
    @State var isSearchExpanded: Bool = false

    // MARK: - 数据源派生

    var installedAppRoots: [Node] {
        var list = state.roots.filter { !$0.tags.contains(OrphanFinderEngine.categoryTag) }
        if !state.search.isEmpty {
            let q = state.search.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(q)
                    || $0.path.lowercased().contains(q)
                    || $0.children.contains(where: { $0.path.lowercased().contains(q) })
            }
        }
        return sortAppNodes(list)
    }

    var orphanLeaves: [Node] {
        let orphanGroups = state.roots.filter { $0.tags.contains(OrphanFinderEngine.categoryTag) }
        var leaves = orphanGroups.flatMap(\.leaves)
        if !state.search.isEmpty {
            let q = state.search.lowercased()
            leaves = leaves.filter {
                $0.name.lowercased().contains(q) || $0.path.lowercased().contains(q)
            }
        }
        return leaves.sorted { $0.totalSize > $1.totalSize }
    }

    var maxInstalledAppSize: Int64 {
        installedAppRoots.map(\.totalSize).max() ?? 1
    }

    var totalInstalledSize: Int64 {
        installedAppRoots.reduce(0) { $0 + $1.appBundleSize }
    }

    var selectedAppRoots: [Node] {
        installedAppRoots.filter { app in
            app.leaves.contains { state.selection.contains($0.id) }
        }
    }

    func sortAppNodes(_ list: [Node]) -> [Node] {
        list.sorted { a, b in
            let cmp: ComparisonResult
            switch state.sortKey {
            case .name:
                cmp = a.name.localizedStandardCompare(b.name)
            case .size:
                cmp = a.totalSize == b.totalSize ? .orderedSame : (a.totalSize < b.totalSize ? .orderedAscending : .orderedDescending)
            case .date:
                // 活跃中应用在「最近使用」排序中排在最前
                let da = a.isActiveNow ? Date.distantFuture : (a.date ?? .distantPast)
                let db = b.isActiveNow ? Date.distantFuture : (b.date ?? .distantPast)
                cmp = da == db ? .orderedSame : (da < db ? .orderedAscending : .orderedDescending)
            case .installDate:
                let ia = a.installDate ?? .distantPast
                let ib = b.installDate ?? .distantPast
                cmp = ia == ib ? .orderedSame : (ia < ib ? .orderedAscending : .orderedDescending)
            }
            if cmp != .orderedSame {
                return state.sortAscending ? (cmp == .orderedAscending) : (cmp == .orderedDescending)
            }
            let nameCmp = a.name.localizedStandardCompare(b.name)
            if nameCmp != .orderedSame {
                return nameCmp == .orderedAscending
            }
            if a.path != b.path {
                return a.path < b.path
            }
            return a.id.uuidString < b.id.uuidString
        }
    }

    // MARK: - 主体视图

    var body: some View {
        ZStack {
            if state.scanning {
                appScanningStageView
            } else if !state.hasScannedCurrentModule && installedAppRoots.isEmpty && orphanLeaves.isEmpty {
                appIdleStageView
            } else {
                appResultStageView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: state.scanning)
        .onAppear {
            let sess = state.session(for: "applications")
            activeTab = sess.appActiveTab
            expandedAppIDs = sess.appExpandedIDs

            // 应用程序默认用占用体积从大到小排序
            if (state.sortKey == .date && state.sortAscending) || (state.sortKey != .size && state.sortKey != .name && state.sortKey != .date && state.sortKey != .installDate) {
                state.sortKey = .size
                state.sortAscending = false
            }
        }
        .onChange(of: activeTab) { newTab in
            state.updateCurrentSession { $0.appActiveTab = newTab }
        }
        .onChange(of: expandedAppIDs) { newIDs in
            state.updateCurrentSession { $0.appExpandedIDs = newIDs }
        }
    }

    // MARK: - 0. 顶部统一标题栏（与系统监控完全对齐的左上角标题与规格副标题）

    var topHeaderStrip: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.localized(.moduleApplications))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.text)

                if !state.hasScannedCurrentModule && installedAppRoots.isEmpty && orphanLeaves.isEmpty {
                    Text(L10n.localized(.appManagerSubtitleCleanUninstall))
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                } else {
                    Text("\(L10n.localized(.installedAppsHeader)) \(installedAppRoots.count) \(L10n.localized(.unitCount)) · \(Fmt.size(totalInstalledSize)) · \(orphanLeaves.count) \(L10n.localized(.orphanedResidualItemsCountSuffix))")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 12)

            if state.hasScannedCurrentModule || !installedAppRoots.isEmpty || !orphanLeaves.isEmpty {
                HeaderIconButton(
                    icon: "arrow.clockwise",
                    spinning: state.scanning,
                    helpText: L10n.localized(.actionRescan)
                ) {
                    expandedAppIDs.removeAll()
                    state.startScan(for: "applications", forceRestart: true)
                }
            }
        }
    }

    // MARK: - 第一幕：待命态 (Act 1: Idle Stage)

    var appIdleStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Spacer(minLength: 6)

                    // 1. 核心悬浮脉冲球体（带应用网格图标与微光呼吸动效）
                    PulseOrbStageView(
                        isScanning: false,
                        sizeText: "",
                        unitText: "",
                        subtitle: L10n.localized(.statusReady),
                        themeColor: Theme.accent,
                        diameter: 140,
                        symbol: "square.grid.2x2.fill"
                    )

                    // 2. 标题与说明副标题
                    VStack(spacing: 6) {
                        Text(L10n.localized(.totalControlOverYourApplications))
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.text)

                        Text(L10n.localized(.smartDetectionOfInstalledAppsUnusedSoftwareLeftoverFilesAndStartupItems))
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.sub)
                    }

                    // 3. 4 大应用管理 Bento 预览微卡片
                    HStack(spacing: 10) {
                        IdleAppFeatureCard(
                            title: L10n.localized(.featureCleanUninstall),
                            tag: L10n.localized(.tagCleanUninstall),
                            subtitle: L10n.localized(.deepScanApplicationBundleContainersAppSupportAndPreferencesForACleanRemoval),
                            systemName: "trash.circle.fill",
                            primaryColor: Color(red: 0.98, green: 0.42, blue: 0.38),
                            secondaryColor: Color(red: 0.88, green: 0.22, blue: 0.20)
                        )

                        IdleAppFeatureCard(
                            title: L10n.localized(.junkUninstallerLeftovers),
                            tag: L10n.localized(.orphanedFileCleanup),
                            subtitle: L10n.localized(.smartSearchForLeftoverSupportFoldersAndOrphanedCachesFromAlreadyDeletedApps),
                            systemName: "sparkles.rectangle.stack.fill",
                            primaryColor: Color(red: 0.98, green: 0.58, blue: 0.18),
                            secondaryColor: Color(red: 0.88, green: 0.40, blue: 0.08)
                        )

                        IdleAppFeatureCard(
                            title: L10n.localized(.featureUnusedApps),
                            tag: L10n.localized(.tagUnusedApps),
                            subtitle: L10n.localized(.identifySoftwareUnopenedForMonthsBasedOnActivityTimeToReclaimStorage),
                            systemName: "clock.arrow.circlepath",
                            primaryColor: Color(red: 0.38, green: 0.65, blue: 0.98),
                            secondaryColor: Color(red: 0.18, green: 0.42, blue: 0.88)
                        )

                        IdleAppFeatureCard(
                            title: L10n.localized(.featureStartupComponents),
                            tag: L10n.localized(.tagStartupComponents),
                            subtitle: L10n.localized(.findBackgroundLaunchagentsAndHelperToolsBundledWithAppsToKeepMacosFast),
                            systemName: "bolt.horizontal.circle.fill",
                            primaryColor: Color(red: 0.66, green: 0.36, blue: 0.96),
                            secondaryColor: Color(red: 0.46, green: 0.20, blue: 0.86)
                        )
                    }
                    .padding(.horizontal, 16)

                    // 4. 底部统一主操作扫描按钮 (GlowingPillButton 184x42)
                    GlowingPillButton(
                        title: L10n.localized(.actionStartAnalyzeApps),
                        icon: "sparkles",
                        tint: Theme.accent,
                        width: 184,
                        height: 42
                    ) {
                        expandedAppIDs.removeAll()
                        state.startScan(for: "applications", forceRestart: true)
                    }
                    .padding(.top, 4)

                    // 5. 安全保障标语
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.accent.opacity(0.85))
                        Text(L10n.localized(.protectedSystemComponentsAreSafeDetailedFileListsAreShownBeforeAnyDeletion))
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

    // MARK: - 第二幕：扫描中 (Act 2: Scanning Stage)

    var appScanningStageView: some View {
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
                    subtitle: L10n.localized(.statusAppScanning),
                    themeColor: Theme.accent,
                    diameter: 220
                )

                VStack(spacing: 10) {
                    Text(L10n.localized(.analyzingInstalledApps))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)

                    Text(state.scanStatus.isEmpty ? L10n.localized(.scanningSystemAppCaches) : state.scanStatus)
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
                        Text(L10n.localized(.actionStopScanning))
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

    // MARK: - 第三幕：结果态 (Act 3: Result Stage)

    var appResultStageView: some View {
        VStack(alignment: .leading, spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 34)
                .padding(.top, 16)
                .padding(.bottom, 10)

            Divider().background(Theme.sep)

            moduleTopBar

            moduleSubheaderLine

            mainContentArea

            if activeTab == .uninstall || activeTab == .leftovers {
                moduleBottomFooter
            }
        }
    }

    // MARK: - 1. 顶部控制栏（左侧 `[卸载 | 残留]`，右侧排序 + `🔍`）

    var moduleTopBar: some View {
        HStack(alignment: .center, spacing: 14) {
            // 左侧高定滑动光块分段器
            SlidingSegmentedControl(
                items: TopTabMode.allCases.map { SlidingSegmentItem(id: $0, title: $0.title) },
                selection: Binding(
                    get: { activeTab },
                    set: { newTab in
                        activeTab = newTab
                        state.selection.removeAll()
                    }
                )
            )

            Spacer(minLength: 16)

            // 右侧内联文字排序栏（名称 / 占用体积 / 最近使用 ↑ / 安装日期）
            if activeTab == .uninstall {
                HStack(spacing: 18) {
                    inlineSortButton(title: L10n.localized(.sortByName), key: .name, defaultAsc: true)
                    inlineSortButton(title: L10n.localized(.sortBySizeAlt), key: .size, defaultAsc: false)
                    inlineSortButton(title: L10n.localized(.sortByLastUsed), key: .date, defaultAsc: false)
                    inlineSortButton(title: L10n.localized(.sortByInstallDate), key: .installDate, defaultAsc: false)
                }
            }

            // 搜索框 / 放大镜按钮 `🔍`
            HStack(spacing: 8) {
                if isSearchExpanded || !state.search.isEmpty {
                    SearchField(text: $state.search, placeholder: L10n.localized(.searchAppsOrPathPlaceholder))
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
        .padding(.horizontal, 34)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    func inlineSortButton(title: String, key: SortKey, defaultAsc: Bool) -> some View {
        let active = (state.sortKey == key)
        return Button {
            if state.sortKey == key {
                state.sortAscending.toggle()
            } else {
                state.sortKey = key
                state.sortAscending = defaultAsc
            }
        } label: {
            HStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 12.5, weight: active ? .bold : .regular))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                if active {
                    Text(state.sortAscending ? "↑" : "↓")
                        .font(.system(size: 11, weight: .bold))
                }
            }
            .foregroundStyle(active ? Theme.text : Theme.sub)
            .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 2. 统计副标题行（`已安装 App  74 个 · 53 GB（其中数据文件 28 GB）`）

    var moduleSubheaderLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            switch activeTab {
            case .uninstall:
                Text(L10n.localized(.installedAppsHeader))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.text)
                Text("\(installedAppRoots.count) \(L10n.localized(.unitCount)) · \(Fmt.size(totalInstalledSize))")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.sub)
                    .monospacedDigit()

            case .leftovers:
                let totalOrphanBytes = orphanLeaves.reduce(Int64(0)) { $0 + $1.totalSize }
                Text(L10n.localized(.junkUninstallerLeftovers))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.text)
                Text("\(orphanLeaves.count) \(L10n.localized(.unitItems)) · \(Fmt.size(totalOrphanBytes))")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.sub)
                    .monospacedDigit()
            }

            Spacer()
        }
        .padding(.horizontal, 34)
        .padding(.bottom, 8)
    }

    // MARK: - 3. 主列表内容区

    @ViewBuilder
    var mainContentArea: some View {
        if state.scanning && state.roots.isEmpty {
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                Text(L10n.localized(.scanningInstalledApplicationsAndAssociatedDirectories))
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.sub)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 6) {
                    switch activeTab {
                    case .uninstall:
                        let apps = installedAppRoots
                        let maxSize = apps.map(\.totalSize).max() ?? 1
                        let runningApps = NSWorkspace.shared.runningApplications
                        let runningBIDs = Set(runningApps.compactMap { $0.bundleIdentifier?.lowercased() })
                        let runningPaths = Set(runningApps.compactMap { $0.bundleURL?.path })
                        ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                            InstalledAppRow(
                                app: app,
                                maxAppSize: maxSize,
                                isExpanded: expandedAppIDs.contains(app.id),
                                runningBIDs: runningBIDs,
                                runningPaths: runningPaths,
                                onToggleExpand: {
                                    withAnimation(.easeInOut(duration: 0.16)) {
                                        if expandedAppIDs.contains(app.id) {
                                            expandedAppIDs.remove(app.id)
                                        } else {
                                            expandedAppIDs.insert(app.id)
                                        }
                                    }
                                },
                                onToggleAppCheck: {
                                    toggleAppDefaultSelection(app)
                                }
                            )
                            .staggeredAppear(index: min(index, 16))
                        }

                    case .leftovers:
                        if orphanLeaves.isEmpty {
                            VStack(spacing: 10) {
                                Text(L10n.localized(.noLeftoversDetectedTitle))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.text)
                                Text(L10n.localized(.noLeftoversDetectedSubtitle))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.sub)
                            }
                            .frame(maxWidth: .infinity, minHeight: 320)
                        } else {
                            ForEach(Array(orphanLeaves.enumerated()), id: \.element.id) { index, leaf in
                                OrphanLeftoverRow(leaf: leaf)
                                    .staggeredAppear(index: min(index, 16))
                            }
                        }
                    }
                }
                .padding(.horizontal, 34)
                .padding(.vertical, 6)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - 4. 底部操作栏（1:1 对齐图2 & 图3/4 底部栏）

    var moduleBottomFooter: some View {
        HStack(alignment: .center, spacing: 14) {
            if activeTab == .uninstall {
                let checkedApps = selectedAppRoots
                let selSize = state.selectedSize
                let hasUncheckedUserData = checkedApps.contains { app in
                    app.leaves.contains { !$0.locked && !state.selection.contains($0.id) }
                }

                if let firstApp = checkedApps.first {
                    if let img = firstApp.image {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    }

                    let summaryTitle: String = {
                        if checkedApps.count == 1 {
                            return "\(firstApp.name) · 1 \(L10n.localized(.unitCount)) App · \(Fmt.size(selSize))"
                        } else {
                            return "\(firstApp.name) \(L10n.localized(.particleEtc)) \(checkedApps.count) \(L10n.localized(.unitCount)) App · \(Fmt.size(selSize))"
                        }
                    }()

                    Text(summaryTitle)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .monospacedDigit()
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        ActionLink(
                            title: hasUncheckedUserData ? L10n.localized(.actionAlsoRemoveUserData) : L10n.localized(.actionOnlyRemoveSafeCacheAndApp),
                            enabled: true
                        ) {
                            toggleUserDataForSelectedApps(includeAll: hasUncheckedUserData)
                        }
                        Text("·").foregroundStyle(Theme.tert)
                        ActionLink(title: L10n.localized(.actionDeselect), enabled: true) {
                            state.selection.removeAll()
                        }
                    }
                } else {
                    Text(L10n.localized(.appUninstallHint))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.sub)
                }

                Spacer(minLength: 16)

                let count = checkedApps.count
                GlowingPillButton(
                    title: count > 0
                        ? "\(L10n.localized(.remove)) \(count) \(L10n.localized(.unitItems))"
                        : L10n.localized(.remove),
                    icon: "trash",
                    tint: Theme.red,
                    isDangerous: true,
                    isEnabled: count > 0 && !state.scanning && state.screen != .cleaning,
                    width: 170,
                    height: 40
                ) {
                    state.commitClean(category: nil)
                }
            } else {
                let selCount = state.selectedCount
                let selSize = state.selectedSize
                Text("\(L10n.localized(.labelSelected)) \(selCount) \(L10n.localized(.unitItems)) · \(Fmt.size(selSize))")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .monospacedDigit()

                HStack(spacing: 6) {
                    ActionLink(title: L10n.localized(.actionSelectAll), enabled: selCount < orphanLeaves.count && !orphanLeaves.isEmpty) {
                        var next = state.selection
                        for leaf in orphanLeaves where !leaf.locked {
                            next.insert(leaf.id)
                        }
                        state.selection = next
                    }
                    Text("·").foregroundStyle(Theme.tert)
                    ActionLink(title: L10n.localized(.actionNone), enabled: selCount > 0) {
                        state.selection.removeAll()
                    }
                }

                Spacer(minLength: 16)

                GlowingPillButton(
                    title: selCount > 0
                        ? "\(L10n.localized(.remove)) \(selCount) \(L10n.localized(.unitItems))"
                        : L10n.localized(.remove),
                    icon: "trash",
                    tint: Theme.red,
                    isDangerous: true,
                    isEnabled: selCount > 0 && !state.scanning && state.screen != .cleaning,
                    width: 170,
                    height: 40
                ) {
                    state.commitClean(category: OrphanFinderEngine.categoryTag)
                }
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

    // MARK: - 勾选辅助方法

    /// 勾选 App 时默认选中「清除」分组（App 本体 + 缓存/日志），保留「需要确认」分组（用户数据）待用户确认，并自动展开该 App
    func toggleAppDefaultSelection(_ app: Node) {
        let leaves = app.leaves.filter { !$0.locked }
        let anySelected = leaves.contains { state.selection.contains($0.id) }
        var next = state.selection
        if anySelected {
            for l in leaves {
                next.remove(l.id)
            }
            state.selection = next
        } else {
            let safeLeaves = leaves.filter { AppFolderClassifier.isDefaultClearItem($0) }
            let targetLeaves = safeLeaves
            for l in targetLeaves {
                next.insert(l.id)
            }
            state.selection = next
            withAnimation(.easeInOut(duration: 0.16)) {
                _ = expandedAppIDs.insert(app.id)
            }
        }
    }

    func toggleUserDataForSelectedApps(includeAll: Bool) {
        var next = state.selection
        for app in selectedAppRoots {
            for leaf in app.leaves where !leaf.locked {
                if includeAll {
                    next.insert(leaf.id)
                } else if AppFolderClassifier.isDefaultClearItem(leaf) {
                    next.insert(leaf.id)
                } else {
                    next.remove(leaf.id)
                }
            }
        }
        state.selection = next
    }
}
