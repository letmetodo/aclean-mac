import SwiftUI
import AppKit
import UniformTypeIdentifiers

// ============================================================
//  SettingsView —— CleanMate 偏好设置与安全配置中心 (v3.2 五大独立配置模块)
//
//  分为五大核心配置选项卡：
//    1. 外观配置 (Appearance)：外观模式(系统/暗色/浅色)、6套预设主题色方案、10门语言热切换、音效与备份恢复
//    2. 菜单栏配置 (MenuBar)：状态栏实时监控主开关、顶部菜单栏常驻指标与顺序、下拉控制台卡片与排版
//    3. 扫描配置 (Scanning)：大文件体积阈值、旧文件闲置时间阈值、前缀感知排除白名单
//    4. 定时配置 (Schedule)：LaunchAgent 后台定时巡检、巡检周期、后台静默维护与守护进程状态
//    5. 权限配置 (Permissions)：高危清理前二次确认、风控矩阵说明、macOS 完全磁盘访问权限(FDA)与安全保护状态
// ============================================================

struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var ruleUpdates = RuleUpdateService.shared
    @AppStorage(AppConfig.RuleUpdates.automaticKey) var automaticRuleUpdates = true
    @ObservedObject var scheduler = SchedulerService.shared
    @State var helperMessage: L10nKey = .helperDescription
    @ObservedObject var permissionCoordinator = PermissionCoordinator.shared
    @ObservedObject var config = AppConfigStore.shared
    @ObservedObject var menuBarConfig = MenuBarConfigStore.shared
    @ObservedObject var l10n = L10n.shared

    @AppStorage(AppConfig.StorageKeys.networkFeaturesEnabled) var networkFeaturesEnabled = false
    @State var selectedTab: SettingsTab = .appearance
    @State var hoveredTab: SettingsTab? = nil
    @State var dragStartOffset: CGSize = .zero
    @State var isDraggingHeader: Bool = false

    enum SettingsTab: String, CaseIterable, Identifiable {
        case appearance  = "appearance"
        case menubar     = "menubar"
        case scanning    = "scanning"
        case schedule    = "schedule"
        case permissions = "permissions"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .appearance:  return L10n.localized(.appearanceConfig)
            case .menubar:     return L10n.localized(.menuBarConfig)
            case .scanning:    return L10n.localized(.scanConfig)
            case .schedule:    return L10n.localized(.scheduleConfig)
            case .permissions: return L10n.localized(.permissionConfig)
            }
        }

        var icon: String {
            switch self {
            case .appearance:  return "paintpalette.fill"
            case .menubar:     return "menubar.dock.rectangle"
            case .scanning:    return "slider.horizontal.3"
            case .schedule:    return "calendar.badge.clock"
            case .permissions: return "lock.shield.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider().background(Theme.sep)

            HStack(spacing: 0) {
                sidebarTabs
                Divider().background(Theme.sep)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch selectedTab {
                        case .appearance:
                            appearanceTabContent
                        case .menubar:
                            menubarTabContent
                        case .scanning:
                            scanningTabContent
                        case .schedule:
                            scheduleTabContent
                        case .permissions:
                            permissionsTabContent
                        }
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.contentBg)
            }
        }
        .frame(minWidth: AppConfig.UI.preferencesMinWidth, minHeight: AppConfig.UI.preferencesMinHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preventWindowDrag()
        .background(Theme.windowBg)
        .preferredColorScheme(Theme.isDark ? .dark : .light)
        .environment(\.colorScheme, Theme.isDark ? .dark : .light)
        .onAppear {
            if let tab = SettingsTab(rawValue: state.settingsSelectedTab) {
                selectedTab = tab
            }
            config.applyWindowAppearance()
            state.checkFullDiskAccess()
        }
        .onChange(of: state.settingsSelectedTab) { newTab in
            if let tab = SettingsTab(rawValue: newTab) {
                selectedTab = tab
            }
        }
        .onChange(of: selectedTab) { newTab in
            state.settingsSelectedTab = newTab.rawValue
        }
    }

    // MARK: - 顶部栏 (支持按住拖动窗口与双击居中)

    var headerBar: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                Text(L10n.localized(.preferencesTitle))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.text)
            }

            Spacer()

            Button {
                state.showSettings = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.sub.opacity(0.6))
                    .frame(width: 28, height: 28)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .help(L10n.localized(.actionDone))
            .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Theme.sidebarBg)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    if !isDraggingHeader {
                        isDraggingHeader = true
                        dragStartOffset = state.preferencesBoxOffset
                        NSCursor.closedHand.push()
                    }
                    state.preferencesBoxOffset = CGSize(
                        width: dragStartOffset.width + value.translation.width,
                        height: dragStartOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    if isDraggingHeader {
                        NSCursor.pop()
                    }
                    isDraggingHeader = false
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    state.preferencesBoxOffset = .zero
                }
            }
        )
    }

    // MARK: - 左侧导航栏 (支持整行任意位置点击选中与悬停高亮)

    var sidebarTabs: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(SettingsTab.allCases) { tab in
                let isSelected = (selectedTab == tab)
                let isHovered = (hoveredTab == tab)
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 20)
                            .foregroundStyle(isSelected ? Theme.accent : Theme.sub)
                        Text(tab.title)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Theme.text : Theme.sub)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? Theme.accent.opacity(0.14) : (isHovered ? Theme.hover.opacity(0.7) : Color.clear))
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .onHover { inside in
                    hoveredTab = inside ? tab : (hoveredTab == tab ? nil : hoveredTab)
                    if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }
            Spacer()
        }
        .padding(12)
        .frame(width: 190)
        .background(Theme.sidebarBg)
    }

    // MARK: - 1. 外观配置 (外观模式、预设主题色方案、10 国语言与音效)

    var appearanceTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // 外观模式与主题配色方案
            sectionTitle(L10n.localized(.appearanceModeAndTheme))

            settingsCard {
                VStack(alignment: .leading, spacing: 16) {
                    // 1. 暗色 / 浅色 / 跟随系统
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(L10n.localized(.appearanceMode))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.text)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 16)
                        HStack(spacing: 6) {
                            ForEach(AppAppearanceMode.allCases) { mode in
                                let active = config.appearanceMode == mode
                                Button {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        config.appearanceMode = mode
                                    }
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: mode.icon)
                                            .font(.system(size: 11, weight: .semibold))
                                        Text(mode.displayName)
                                            .font(.system(size: 11.5, weight: active ? .semibold : .medium))
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                    }
                                    .foregroundStyle(active ? Theme.onAccent : Theme.text)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .fill(active ? Theme.accent : Theme.hover)
                                    )
                                    .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                                .buttonStyle(.plain)
                                .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }

                    Divider().background(Theme.sep)

                    // 2. 6 套预设主题色配色方案
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.localized(.presetTheme))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.text)

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ], spacing: 10) {
                            ForEach(AppThemePreset.allCases) { preset in
                                themePresetCard(preset)
                            }
                        }
                    }

                    Divider().background(Theme.sep)

                    // 3. 10 门主流语言切换
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(L10n.localized(.interfaceLanguage))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.text)
                        }
                        Spacer(minLength: 12)
                        Menu {
                            ForEach(AppLanguage.allCases) { lang in
                                Button {
                                    config.language = lang
                                } label: {
                                    HStack {
                                        Text(lang.displayName)
                                        if config.language == lang {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "globe")
                                    .font(.system(size: 11.5, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                                Text(config.language.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.text)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                Spacer(minLength: 4)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundStyle(Theme.sub)
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .frame(minWidth: 120, maxWidth: 155)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Theme.hover)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(Theme.sep, lineWidth: 1)
                                    )
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                    }
                }
            }

            // 配置备份与恢复
            sectionTitle(L10n.localized(.configBackupAndRestoreTitle))

            settingsCard {
                HStack(spacing: 10) {
                    Button {
                        exportConfiguration()
                    } label: {
                        Label(L10n.localized(.actionExportConfig), systemImage: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.hover)
                            .foregroundStyle(Theme.text)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .contentShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                    .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }

                    Button {
                        importConfiguration()
                    } label: {
                        Label(L10n.localized(.actionImportConfig), systemImage: "square.and.arrow.down")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.hover)
                            .foregroundStyle(Theme.text)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .contentShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                    .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }

                    Spacer()

                    Button {
                        config.resetToDefaults(keepIgnoredPaths: true)
                        state.largeFileThresholdMB = config.largeFileThresholdMB
                        state.oldFileMonths = config.oldFileMonths
                        state.toast = L10n.localized(.toastResetDefaultSuccess)
                    } label: {
                        Label(L10n.localized(.actionRestoreDefaults), systemImage: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.amber.opacity(0.16))
                            .foregroundStyle(Theme.amber)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .contentShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .buttonStyle(.plain)
                    .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                }
            }
        }
    }

    func themePresetCard(_ preset: AppThemePreset) -> some View {
        let isSelected = config.themePreset == preset
        let swatch = Theme.presetColors(for: preset)

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                config.themePreset = preset
            }
        } label: {
            HStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [swatch.primary, swatch.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.displayName)
                        .font(.system(size: 11.5, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                    Text(preset.subtitle)
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.tert)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? swatch.primary.opacity(0.14) : Theme.hover)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(isSelected ? swatch.primary : Theme.sep, lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
    }

    // MARK: - 2. 菜单栏配置 (直接在偏好设置内完整展示与配置：顶部指标左右拖拽 + 瀑布流卡片面板)

    var menubarTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center) {
                sectionTitle(L10n.localized(.settingsMenuBarRealtimeMonitoringTitle))

                Spacer()

                if config.menuBarMonitor {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            menuBarConfig.resetToDefaults()
                        }
                    } label: {
                        Label(L10n.localized(.restoreMenuBarDefaultLayout), systemImage: "arrow.counterclockwise")
                            .font(.system(size: 11.5, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.card)
                            .foregroundStyle(Theme.sub)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Theme.sep, lineWidth: 1)
                            )
                            .contentShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                }
            }

            settingsCard {
                toggleRow(
                    title: L10n.localized(.enableMenuBarCompanion),
                    isOn: $config.menuBarMonitor
                )
                .onChange(of: config.menuBarMonitor) { val in
                    MenuBarCompanion.shared.setVisible(val)
                }
            }

            if config.menuBarMonitor {
                MenuBarConfiguratorView(isEmbedded: true)
            } else {
                settingsCard {
                    HStack(spacing: 14) {
                        Image(systemName: "menubar.dock.rectangle")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.sub)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(L10n.localized(.menuBarMonitorDisabledTitle))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.text)
                            Text(L10n.localized(.menuBarMonitorDisabledSubtitle))
                                .font(.system(size: 11.5))
                                .foregroundStyle(Theme.sub)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}
