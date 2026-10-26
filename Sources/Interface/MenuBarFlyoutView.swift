import SwiftUI
import AppKit

// MARK: - 7. 悬停二级子面板根容器 (SubcategoryFlyoutRootView - Stats Popup Architecture)

struct SubcategoryFlyoutRootView: View {
    @ObservedObject var flyoutState = SubcategoryFlyoutState.shared
    @ObservedObject var appConfig = AppConfigStore.shared

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        VStack(spacing: 0) {
            if let sub = flyoutState.activeSubcategory {
                VStack(alignment: .leading, spacing: 8) {
                    switch sub {
                    case .calendar:
                        CalendarDetailDashboardView()
                    case .weather:
                        CompactWeatherFlyoutView()
                    case .cpu, .gpu:
                        CpuDetailDashboardView()
                    case .memory:
                        MemoryDetailDashboardView()
                    case .network:
                        NetworkDetailDashboardView()
                    case .fan:
                        SensorsDetailDashboardView()
                    case .disk:
                        DiskDetailDashboardView()
                    case .battery:
                        BatteryDetailDashboardView()
                    }
                }
                .padding(9)
            }
        }
        .frame(width: 330)
        .background(
            ZStack {
                VisualEffectView(material: .popover, blendingMode: .behindWindow, state: .active, cornerRadius: 12)
                StatsTheme.popupTint
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.sep, lineWidth: 0.9)
        )
        .preferredColorScheme(appConfig.appearanceMode == .dark ? .dark : (appConfig.appearanceMode == .light ? .light : nil))
        .onHover { hovering in
            flyoutState.setHoveringFlyout(hovering)
        }
    }

    func flyoutHeader(for sub: CompanionSubcategoryKind) -> some View {
        HStack(spacing: 6) {
            Image(systemName: sub.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.accent)
            Text(sub.title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.text)
            Spacer()

            // 快捷入口：一键打开活动监视器 + 菜单栏模块配置
            Button {
                _ = Shell.run("/usr/bin/open", ["-a", "Activity Monitor"])
            } label: {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Theme.sub)
                    .frame(width: 22, height: 22)
                    .background(StatsTheme.boxBg)
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help(L10n.localized(.actionOpenActivityMonitorHelp))

            Button {
                MenuBarCompanion.shared.closeSystemPopover()
                AppState.shared?.openSettings(tab: "menubar")
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Theme.sub)
                    .frame(width: 22, height: 22)
                    .background(StatsTheme.boxBg)
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help(L10n.localized(.menuBarConfigCustomizationHelp))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(StatsTheme.boxBg)
    }
}

// MARK: - 8. 统一底部实用工具快捷坞 (QuickUtilityDockView)

struct QuickUtilityDockView: View {
    @Binding var isCaffeinateOn: Bool
    @ObservedObject var appConfig = AppConfigStore.shared

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        HStack(spacing: 6) {
            // 活动监视器
            dockIconButton("chart.bar.xaxis", help: L10n.localized(.actionOpenActivityMonitorHelp)) {
                _ = Shell.run("/usr/bin/open", ["-a", "Activity Monitor"])
            }

            // 终端
            dockIconButton("terminal", help: L10n.localized(.actionOpenTerminalHelp)) {
                _ = Shell.run("/usr/bin/open", ["-a", "Terminal"])
            }

            // 控制台
            dockIconButton("newspaper", help: L10n.localized(.actionOpenConsoleHelp)) {
                _ = Shell.run("/usr/bin/open", ["-a", "Console"])
            }

            // 系统设置
            dockIconButton("gearshape.fill", help: L10n.localized(.actionOpenSystemSettings)) {
                _ = Shell.run("/usr/bin/open", ["-a", "System Settings"])
            }

            // AClean 主应用
            dockIconButton("sparkles", help: L10n.localized(.actionOpenACleanConsole)) {
                NSApp.activate(ignoringOtherApps: true)
                for w in NSApp.windows where w.canBecomeMain {
                    w.makeKeyAndOrderFront(nil)
                }
            }

            // AClean 模块管理
            dockIconButton("square.grid.2x2", help: L10n.localized(.actionOpenModuleManagement)) {
                MenuBarCompanion.shared.closeSystemPopover()
                AppState.shared?.openSettings(tab: "menubar")
            }

            Spacer()

            // 防休眠常亮开关 (Caffeinate)
            Button {
                isCaffeinateOn = MenuBarCompanion.shared.toggleCaffeinate()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isCaffeinateOn ? "cup.and.saucer.fill" : "cup.and.saucer")
                        .foregroundColor(isCaffeinateOn ? Color.orange : Theme.sub)
                    Text(isCaffeinateOn ? L10n.localized(.actionCaffeinateAlwaysOn) : L10n.localized(.actionCaffeinateShort))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isCaffeinateOn ? Color.orange : Theme.sub)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isCaffeinateOn ? Color.orange.opacity(0.18) : StatsTheme.boxBg)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help(L10n.localized(.actionCaffeinateTooltip))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.sep, lineWidth: 0.8))
        .cornerRadius(8)
    }

    func dockIconButton(_ icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(StatsTheme.boxBg)
                    .frame(width: 25, height: 25)
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.text)
            }
        }
        .buttonStyle(.plain)
        .focusable(false)
        .help(help)
    }
}
