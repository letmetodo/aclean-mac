import SwiftUI
import AppKit

// ============================================================
//  Shell.swift —— CleanMate 简洁模式应用外壳 (CleanMate Concise Layout)
//
//  整体布局：
//    · 左侧：6 大核心模块导航栏（垃圾清理 / 性能优化 / 应用程序 / 空间透视 / 整理杂乱 / 系统监控）
//           底部集成预设主题色快速切换点、暗/浅色切换、10 国语言菜单与偏好设置入口
//    · 右侧：直接对应各模块的具体逻辑页面（去除复杂 8 屏中间态）
//    · 主题：全面支持暗色/浅色与 6 套预设主题色方案，零硬编码操作色
// ============================================================

struct AppChrome: View {
    typealias ContentView = AppChrome
    @ObservedObject private var permissionCoordinator = PermissionCoordinator.shared
    @EnvironmentObject var state: AppState
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var config = AppConfigStore.shared

    private var mainLayout: some View {
        HStack(spacing: 0) {
            Sidebar()
            Canvas()
                .background(Theme.contentBg)
        }
        .preferredColorScheme(Theme.isDark ? .dark : .light)
        .environment(\.colorScheme, Theme.isDark ? .dark : .light)
        .frame(minWidth: AppConfig.UI.defaultWindowMinWidth, minHeight: AppConfig.UI.defaultWindowMinHeight)
        .overlay(alignment: .bottom) {
            if let t = state.toast {
                ToastView(
                    text: t,
                    kind: state.toastKind,
                    actionTitle: state.toastAction?.title,
                    onAction: state.toastAction?.handler
                )
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: state.toast)
    }

    var body: some View {
        mainLayout
            .ignoresSafeArea(.all, edges: .top)
            .background(WindowConfigurator())
            .overlay {
                if state.showSettings {
                    PreferencesModalOverlay(isPresented: $state.showSettings)
                        .environmentObject(state)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .overlay {
                if state.showOnboarding {
                    OnboardingView()
                        .environmentObject(state)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .onChange(of: state.showSettings) { isOpen in
                for win in NSApp.windows {
                    win.isMovableByWindowBackground = !isOpen && !state.showOnboarding
                }
            }
            .onChange(of: state.showOnboarding) { isOpen in
                for win in NSApp.windows {
                    win.isMovableByWindowBackground = !isOpen && !state.showSettings
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: state.showSettings)
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: state.showOnboarding)
            .sheet(isPresented: $state.showInfo) {
                if let n = state.infoNode { InfoPanel(node: n) }
            }
            .sheet(isPresented: $state.showCommandPalette) {
                CommandPaletteView(isPresented: $state.showCommandPalette)
                    .environmentObject(state)
            }
            .sheet(isPresented: Binding(
                get: { permissionCoordinator.isRequesting },
                set: { if !$0 { PermissionCoordinator.shared.dismiss(callRetry: false) } }
            )) {
                PermissionSheet()
            }
            .alert(L10n.localized(.alertConfirmDeleteTitle),
                   isPresented: Binding(get: { state.dangerConfirm != nil },
                                        set: { if !$0 { state.dangerConfirm = nil } })) {
                Button(L10n.localized(.actionCancel), role: .cancel) { state.dangerConfirm = nil }
                Button(L10n.localized(.actionConfirmRemoval), role: .destructive) { state.confirmDangerClean() }
            } message: {
                Text(state.dangerConfirm?.message ?? "")
            }
            .task {
                config.applyWindowAppearance()
                state.disk = DiskInfo.current()
                state.checkFullDiskAccess()
                permissionCoordinator.refreshStatus()
            }
    }
}

// MARK: - 窗口顶栏与全屏内容透明穿透配置器

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        WindowConfiguratorView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class WindowConfiguratorView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configure()
    }

    private func configure() {
        guard let window = self.window else { return }
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: AppConfig.UI.defaultWindowMinWidth, height: AppConfig.UI.defaultWindowMinHeight)
    }
}

// MARK: - 左侧模块导航栏 (Sidebar)

struct Sidebar: View {
    @EnvironmentObject var state: AppState
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var config = AppConfigStore.shared

    var body: some View {
        Group {
            if state.isSidebarCollapsed {
                CollapsedRail()
            } else {
                FullSidebar()
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: state.isSidebarCollapsed)
    }
}

// MARK: - 紧凑图标轨 (60pt)

struct CollapsedRail: View {
    @EnvironmentObject var state: AppState
    @ObservedObject private var permissionCoordinator = PermissionCoordinator.shared
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var config = AppConfigStore.shared

    private var hasFda: Bool {
        permissionCoordinator.hasFullDiskAccess || state.hasFullDiskAccess
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部：红绿灯预留区 + 展开按钮
            VStack(spacing: 4) {
                Color.clear.frame(height: 24)

                Button {
                    state.toggleSidebar()
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.sub)
                        .frame(width: 34, height: 28)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Theme.hover))
                }
                .buttonStyle(.plain)
                .help(L10n.localized(.tooltipExpandSidebar))
            }
            .padding(.top, 6)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(ModuleRegistry.conciseModules, id: \.key) { m in
                        CollapsedRailItem(spec: m, selected: state.moduleKey == m.key) {
                            state.open(.restore(ModuleKey.parse(m.key) ?? .junk))
                        }
                    }
                }
                .padding(.horizontal, 6)
            }

            Spacer(minLength: 8)

            if !hasFda {
                Button {
                    permissionCoordinator.requestAccess(context: .general) {
                        state.checkFullDiskAccess(force: true)
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Theme.amber.opacity(0.16))
                            .frame(width: 36, height: 32)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.amber)
                            .frame(width: 36, height: 32)
                        Circle()
                            .fill(Theme.amber)
                            .frame(width: 6, height: 6)
                            .offset(x: -4, y: 4)
                    }
                }
                .buttonStyle(.plain)
                .padding(.bottom, 6)
                .help(L10n.localized(.sidebarQuickGrantFdaTitle))
            }

            Button {
                state.showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.sub)
                    .frame(width: 34, height: 28)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
            .help(L10n.localized(.preferencesEllipsis))
        }
        .frame(width: 62)
        .background {
            ZStack {
                VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                Theme.sidebarBg.opacity(Theme.isDark ? 0.28 : 0.22)
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle().fill(Theme.sep).frame(width: 1)
        }
    }
}

struct CollapsedRailItem: View {
    @EnvironmentObject var state: AppState
    var spec: ModuleSpec
    var selected: Bool
    var action: () -> Void
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var config = AppConfigStore.shared

    var body: some View {
        let isScanningBg = state.activeScanningModules.contains(spec.key)
        let isCleaningBg = state.isModuleCleaning(spec.key)
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(selected ? (Theme.isDark ? Color.white.opacity(0.11) : Color.black.opacity(0.075)) : Color.clear)
                        .frame(width: 42, height: 42)

                    CleanCategoryVisuals.navigationOpticalIcon(for: spec.key, size: 26)
                }

                if isScanningBg || isCleaningBg {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 6, height: 6)
                        .offset(x: -4, y: 4)
                }
            }
            .frame(width: 48, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(spec.title)
    }
}

// MARK: - 展开态左侧导航栏 (216pt)

struct FullSidebar: View {
    @EnvironmentObject var state: AppState
    @ObservedObject private var permissionCoordinator = PermissionCoordinator.shared
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var config = AppConfigStore.shared

    private var hasFda: Bool {
        permissionCoordinator.hasFullDiskAccess || state.hasFullDiskAccess
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部顶栏：左侧预留红绿灯区域，右侧与收起按钮严格水平对齐
            HStack(spacing: 8) {
                // 左侧预留窗口红绿灯空间 (~72pt)
                Color.clear
                    .frame(width: 72, height: 28)

                Spacer()

                Button {
                    state.toggleSidebar()
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.sub)
                        .padding(5)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Theme.hover))
                }
                .buttonStyle(.plain)
                .help(L10n.localized(.tooltipCollapseSidebar))
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(height: 42)

            // 6 大核心模块按钮列表
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(ModuleRegistry.conciseModules, id: \.key) { m in
                        SidebarRow(spec: m, selected: state.moduleKey == m.key) {
                            state.open(.restore(ModuleKey.parse(m.key) ?? .junk))
                        }
                    }
                }
                .padding(.horizontal, 10)
            }

            Spacer(minLength: 10)

            // 底部控制区：快捷授权胶囊、精简版启动磁盘容量卡片与偏好设置入口
            VStack(alignment: .leading, spacing: 10) {
                if !hasFda {
                    Button {
                        permissionCoordinator.requestAccess(context: .general) {
                            state.checkFullDiskAccess(force: true)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Theme.amber.opacity(0.22))
                                    .frame(width: 24, height: 24)
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.amber)
                            }

                            VStack(alignment: .leading, spacing: 1) {
                                Text(L10n.localized(.sidebarQuickGrantFdaTitle))
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundStyle(Theme.text)
                                    .lineLimit(1)
                                Text(L10n.localized(.sidebarQuickGrantFdaSubtitle))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.amber)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 2)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Theme.amber)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.amber.opacity(0.11))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Theme.amber.opacity(0.32), lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                }

                // 精简版启动磁盘容量卡片
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "internaldrive.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.accent)
                        Text(L10n.localized(.startupDisk))
                            .font(.system(size: 11.5, weight: .semibold))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        Spacer(minLength: 4)
                        Text("\(L10n.localized(.labelFreeAvailable)) \(Fmt.size(state.disk.free))")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(Theme.sub)
                            .monospacedDigit()
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    DiskBar(used: state.disk.used, total: state.disk.total, height: 5, tint: Theme.accent)
                    HStack {
                        Text("\(Fmt.size(state.disk.used)) / \(Fmt.size(state.disk.total))")
                            .font(.system(size: 9.5))
                            .foregroundStyle(Theme.tert)
                            .monospacedDigit()
                        Spacer(minLength: 0)
                    }
                }
                .glassBentoCard(cornerRadius: 10, padding: 10)

                // 偏好设置按钮
                Button {
                    state.showSettings = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12))
                        Text(L10n.localized(.preferencesEllipsis))
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Spacer(minLength: 2)
                        Text("⌘,")
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.tert)
                    }
                    .foregroundStyle(Theme.sub)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Theme.hover)
                    )
                    .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .frame(width: 218)
        .background {
            ZStack {
                VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                Theme.sidebarBg.opacity(Theme.isDark ? 0.28 : 0.22)
            }
        }
        .overlay(alignment: .trailing) {
            Rectangle().fill(Theme.sep).frame(width: 1)
        }
    }
}

func sidebarIcon(for key: String) -> String {
    switch key {
    case "healthCheck":  return "shield.checkerboard"
    case "smartCare":    return "wand.and.stars"
    case "junk":         return "trash.fill"
    case "performance":  return "bolt.fill"
    case "applications": return "square.grid.2x2.fill"
    case "spaceLens":    return "chart.pie.fill"
    case "organize":     return "folder.fill.badge.gearshape"
    case "liveMonitor":  return "gauge.with.dots.needle.67percent"
    case "toolbox":      return "square.grid.3x3.fill"
    case "assistant":    return "brain.head.profile"
    default:             return "sparkles"
    }
}

struct SidebarRow: View {
    @EnvironmentObject var state: AppState
    var spec: ModuleSpec
    var selected: Bool
    var action: () -> Void
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var config = AppConfigStore.shared

    @State private var hover = false

    var body: some View {
        let isScanningBg = state.activeScanningModules.contains(spec.key)
        let isCleaningBg = state.isModuleCleaning(spec.key)
        Button(action: action) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        selected
                            ? (Theme.isDark ? Color.white.opacity(0.11) : Color.black.opacity(0.075))
                            : (hover ? Theme.hover : Color.clear)
                    )

                HStack(spacing: 10) {
                    CleanCategoryVisuals.navigationOpticalIcon(for: spec.key, size: 24)

                    Text(spec.title)
                        .font(.system(size: 13, weight: selected ? .semibold : .regular))
                        .foregroundStyle(selected ? Theme.text : Theme.text.opacity(0.86))
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if isScanningBg || isCleaningBg {
                        ProgressView()
                            .controlSize(.mini)
                            .scaleEffect(0.85)
                    }
                }
                .padding(.horizontal, 9)
            }
            .frame(height: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.14), value: selected)
        .animation(.easeOut(duration: 0.12), value: hover)
        .onHover { hover = $0 }
    }
}

// MARK: - 右侧逻辑画布 (Canvas —— 支持中间态引导、扫描进度与结果展示)

struct Canvas: View {
    @EnvironmentObject var state: AppState
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var config = AppConfigStore.shared

    @ViewBuilder
    private var moduleView: some View {
        switch state.moduleKey {
        case .healthCheck:
            SystemHealthCheckView()
        case .junk:
            SmartCleanView()
        case .performance:
            PerformanceSingleColumnView()
        case .applications:
            ApplicationsManagerView()
        case .spaceLens:
            SpaceLensView()
        case .organize:
            SmartDeclutterView()
        case .liveMonitor:
            LiveMonitorView()
        case .smartCare:
            SmartCareDashboard()
        case .toolbox:
            ToolboxGrid()
        case .assistant:
            AssistantView()
        }
    }

    var body: some View {
        ZStack {
            AuroraBackgroundView(themeColor: Theme.accent)

            VStack(spacing: 0) {
                if let tip = moduleTipText {
                    moduleTipBanner(tip)
                }
                Group {
                    if state.screen == .log {
                        LogScreen()
                    } else {
                        moduleView
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    /// 分模块渐进式引导：只在该模块首次进入时给一条说明，看完即止。
    /// 文案复用 ModuleSpec.sidebarSubtitle，不为引导单独造一批翻译。
    private var moduleTipText: String? {
        guard state.screen != .intro, state.screen != .log else { return nil }
        let key = state.moduleKey.rawValue
        guard config.shouldShowModuleTip(key) else { return nil }
        let text = ModuleRegistry.spec(for: key).sidebarSubtitle
        return text.isEmpty ? nil : text
    }

    private func moduleTipBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.system(size: 11))
                .foregroundStyle(Theme.accent)
                .a11yDecorative()
            Text(text)
                .font(.system(size: 11.5))
                .foregroundStyle(Theme.sub)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button {
                config.markModuleTipSeen(state.moduleKey.rawValue)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(Theme.tert)
            }
            .buttonStyle(.plain)
            .a11yControl(label: L10n.localized(.moduleTipDismiss))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.accent.opacity(0.07))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.sep).frame(height: 0.5)
        }
    }
}

// MARK: - 显示简介面板

struct InfoPanel: View {
    var node: Node
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var config = AppConfigStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                if let img = node.image {
                    Image(nsImage: img).resizable().frame(width: 34, height: 34)
                } else {
                    IconTile(icon: node.icon, size: 34, colors: Theme.gradient(Theme.accent))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(node.name).font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.text).lineLimit(1)
                    Text(node.isGroup ? "\(node.leafCount) \(L10n.localized(.unitItems))" : L10n.localized(.unitItems))
                        .font(.system(size: 10)).foregroundStyle(Theme.tert)
                }
                Spacer()
            }
            .padding(16)

            Divider().background(Theme.sep)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    metaRow(L10n.localized(.sortOptionBySize), Fmt.size(node.totalSize))
                    if !node.path.isEmpty { metaRow("Path", node.path) }
                    ForEach(Array(node.meta.enumerated()), id: \.offset) { _, m in
                        metaRow(m.0, m.1)
                    }
                }
                .padding(16)
            }

            Divider().background(Theme.sep)

            HStack {
                Spacer()
                GhostButton(title: L10n.localized(.actionRevealInFinder), icon: "folder") {
                    if let u = node.url { NSWorkspace.shared.activateFileViewerSelecting([u]) }
                }
                PrimaryButton(title: L10n.localized(.actionDone)) { dismiss() }
            }
            .padding(12)
        }
        .frame(width: 420, height: 400)
        .background(Theme.card)
    }

    func metaRow(_ k: String, _ v: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(k).font(.system(size: 11)).foregroundStyle(Theme.tert)
                .frame(width: 72, alignment: .leading)
            Text(v).font(.system(size: 11)).foregroundStyle(Theme.text)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }
}

// ============================================================
// MARK: - 原生 AppKit 光标追踪适配器
// ============================================================

struct NativeCursorView: NSViewRepresentable {
    let cursor: NSCursor

    func makeNSView(context: Context) -> CursorTrackingNSView {
        let view = CursorTrackingNSView()
        view.cursor = cursor
        return view
    }

    func updateNSView(_ nsView: CursorTrackingNSView, context: Context) {
        nsView.cursor = cursor
        nsView.window?.invalidateCursorRects(for: nsView)
    }
}

final class CursorTrackingNSView: NSView {
    var cursor: NSCursor = .arrow

    override var mouseDownCanMoveWindow: Bool { false }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: cursor)
    }
}

// ============================================================
// MARK: - 阻止 AppKit 原生窗口拖拽扩散的 NSView
// ============================================================

final class NonWindowDraggableNSView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }
}

struct NonWindowDraggableBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NonWindowDraggableNSView {
        NonWindowDraggableNSView()
    }
    func updateNSView(_ nsView: NonWindowDraggableNSView, context: Context) {}
}

extension View {
    func preventWindowDrag() -> some View {
        self.background(NonWindowDraggableBackground())
    }
}

// ============================================================
// MARK: - 可拖动与可调整大小的偏好设置模态浮层
// ============================================================

struct PreferencesModalOverlay: View {
    @EnvironmentObject var state: AppState
    @Binding var isPresented: Bool

    // 缩放手势开始时的快照记录
    @State private var startSize: CGSize = .zero
    @State private var startOffset: CGSize = .zero
    @State private var isResizing: Bool = false

    private let minWidth: CGFloat = 720
    private let minHeight: CGFloat = 480

    var body: some View {
        GeometryReader { proxy in
            let windowW = proxy.size.width
            let windowH = proxy.size.height
            let maxAllowedW = max(minWidth, windowW - 40)
            let maxAllowedH = max(minHeight, windowH - 40)

            let boxW = min(maxAllowedW, max(minWidth, state.preferencesBoxSize.width))
            let boxH = min(maxAllowedH, max(minHeight, state.preferencesBoxSize.height))

            // 限制 offset，确保偏好设置窗口的顶栏始终处于窗口可见区内
            let maxOffsetX = max(0, (windowW - boxW) / 2 + boxW * 0.45)
            let maxOffsetY = max(0, (windowH - boxH) / 2 + boxH * 0.45)
            let clampedOffsetX = min(maxOffsetX, max(-maxOffsetX, state.preferencesBoxOffset.width))
            let clampedOffsetY = min(maxOffsetY, max(-maxOffsetY, state.preferencesBoxOffset.height))

            ZStack {
                // 1. 半透明遮罩背景 (点击半透明遮罩可关闭)
                Color.black.opacity(Theme.isDark ? 0.45 : 0.28)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.85)) {
                            isPresented = false
                        }
                    }

                // 2. 偏好设置主体显示框
                ZStack(alignment: .bottomTrailing) {
                    SettingsView()
                        .environmentObject(state)
                        .frame(width: boxW, height: boxH)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    // 8 个边框与边角可拖拽缩放手柄
                    resizeHandles(boxW: boxW, boxH: boxH, maxAllowedW: maxAllowedW, maxAllowedH: maxAllowedH)

                    // 右下角经典原生微缩拖动把手 (视觉提示)
                    resizeGripIndicator
                }
                .frame(width: boxW, height: boxH)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.windowBg)
                        .shadow(color: Color.black.opacity(Theme.isDark ? 0.55 : 0.25), radius: 25, x: 0, y: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.sep, lineWidth: 1)
                )
                .offset(x: clampedOffsetX, y: clampedOffsetY)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .preventWindowDrag()
            .onAppear {
                for win in NSApp.windows {
                    win.isMovableByWindowBackground = false
                }
            }
            .onDisappear {
                for win in NSApp.windows {
                    win.isMovableByWindowBackground = true
                }
            }
        }
    }

    // MARK: - 8 方向边缘与角落拖动缩放
    @ViewBuilder
    private func resizeHandles(boxW: CGFloat, boxH: CGFloat, maxAllowedW: CGFloat, maxAllowedH: CGFloat) -> some View {
        // 右边缘
        Rectangle()
            .fill(Color.clear)
            .frame(width: 12)
            .contentShape(Rectangle())
            .overlay(NativeCursorView(cursor: .resizeLeftRight))
            .gesture(makeResizeGesture(deltaWFactor: 1, deltaHFactor: 0, fromLeft: false, fromTop: false, maxW: maxAllowedW, maxH: maxAllowedH))
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity, alignment: .trailing)

        // 下边缘
        Rectangle()
            .fill(Color.clear)
            .frame(height: 12)
            .contentShape(Rectangle())
            .overlay(NativeCursorView(cursor: .resizeUpDown))
            .gesture(makeResizeGesture(deltaWFactor: 0, deltaHFactor: 1, fromLeft: false, fromTop: false, maxW: maxAllowedW, maxH: maxAllowedH))
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity, alignment: .bottom)

        // 左边缘
        Rectangle()
            .fill(Color.clear)
            .frame(width: 12)
            .contentShape(Rectangle())
            .overlay(NativeCursorView(cursor: .resizeLeftRight))
            .gesture(makeResizeGesture(deltaWFactor: -1, deltaHFactor: 0, fromLeft: true, fromTop: false, maxW: maxAllowedW, maxH: maxAllowedH))
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity, alignment: .leading)

        // 上边缘
        Rectangle()
            .fill(Color.clear)
            .frame(height: 12)
            .contentShape(Rectangle())
            .overlay(NativeCursorView(cursor: .resizeUpDown))
            .gesture(makeResizeGesture(deltaWFactor: 0, deltaHFactor: -1, fromLeft: false, fromTop: true, maxW: maxAllowedW, maxH: maxAllowedH))
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity, alignment: .top)

        // 右下角 (最常用拖动角)
        Rectangle()
            .fill(Color.clear)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .overlay(NativeCursorView(cursor: .crosshair))
            .gesture(makeResizeGesture(deltaWFactor: 1, deltaHFactor: 1, fromLeft: false, fromTop: false, maxW: maxAllowedW, maxH: maxAllowedH))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

        // 左下角
        Rectangle()
            .fill(Color.clear)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .overlay(NativeCursorView(cursor: .crosshair))
            .gesture(makeResizeGesture(deltaWFactor: -1, deltaHFactor: 1, fromLeft: true, fromTop: false, maxW: maxAllowedW, maxH: maxAllowedH))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

        // 右上角
        Rectangle()
            .fill(Color.clear)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .overlay(NativeCursorView(cursor: .crosshair))
            .gesture(makeResizeGesture(deltaWFactor: 1, deltaHFactor: -1, fromLeft: false, fromTop: true, maxW: maxAllowedW, maxH: maxAllowedH))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

        // 左上角
        Rectangle()
            .fill(Color.clear)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .overlay(NativeCursorView(cursor: .crosshair))
            .gesture(makeResizeGesture(deltaWFactor: -1, deltaHFactor: -1, fromLeft: true, fromTop: true, maxW: maxAllowedW, maxH: maxAllowedH))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func makeResizeGesture(deltaWFactor: CGFloat, deltaHFactor: CGFloat, fromLeft: Bool, fromTop: Bool, maxW: CGFloat, maxH: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if !isResizing {
                    isResizing = true
                    startSize = state.preferencesBoxSize
                    startOffset = state.preferencesBoxOffset
                }
                let rawW = startSize.width + value.translation.width * deltaWFactor
                let rawH = startSize.height + value.translation.height * deltaHFactor

                let clampedW = min(maxW, max(minWidth, rawW))
                let clampedH = min(maxH, max(minHeight, rawH))

                let dw = clampedW - startSize.width
                let dh = clampedH - startSize.height

                let newOffsetX: CGFloat = fromLeft ? (startOffset.width - dw / 2) : (startOffset.width + dw / 2)
                let newOffsetY: CGFloat = fromTop ? (startOffset.height - dh / 2) : (startOffset.height + dh / 2)

                state.preferencesBoxSize = CGSize(width: clampedW, height: clampedH)
                state.preferencesBoxOffset = CGSize(width: newOffsetX, height: newOffsetY)
            }
            .onEnded { _ in
                isResizing = false
            }
    }

    private var resizeGripIndicator: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<3) { i in
                let barHeight = CGFloat(4.0 + Double(i) * 3.2)
                Capsule()
                    .fill(Theme.sub.opacity(0.38))
                    .frame(width: 1.8, height: barHeight)
            }
        }
        .rotationEffect(.degrees(-45))
        .padding(6)
        .allowsHitTesting(false)
    }
}

typealias ContentView = AppChrome
