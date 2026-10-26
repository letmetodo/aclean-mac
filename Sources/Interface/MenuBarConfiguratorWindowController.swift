import AppKit
import SwiftUI

// ============================================================
//  MenuBarConfiguratorWindowController
//
//  独立原生的 macOS 配置窗口控制器 (独立原生配置面板)
//  彻底解决在 NSPopover 内部弹 .sheet 产生的裁切、透视、被遮挡与失焦被关闭等严重体验问题。
// ============================================================

final class MenuBarConfiguratorWindowController: NSWindowController, NSWindowDelegate {

    static let shared = MenuBarConfiguratorWindowController()

    private var hostingController: NSHostingController<MenuBarConfiguratorContainerView>?

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 750),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.localized(.menuBarConfiguratorWindowTitle)
        window.minSize = NSSize(width: 680, height: 520)
        window.isReleasedWhenClosed = false
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.toolbarStyle = .unified

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showWindow(category: MonitorModuleCategory = .combined) {
        // 全面接入统一偏好设置面板，不再弹出独立配置框
        AppState.shared?.openSettings(tab: "menubar")
    }

    func windowWillClose(_ notification: Notification) {
        // 窗口关闭时无需额外操作，自动保持单例存活
    }
}

// ============================================================
//  MenuBarConfiguratorContainerView
//  包含顶部标题栏、关闭按钮、以及主配置区
// ============================================================

struct MenuBarConfiguratorContainerView: View {
    @State var selectedCategory: MonitorModuleCategory
    var onClose: () -> Void

    init(initialCategory: MonitorModuleCategory = .combined, onClose: @escaping () -> Void) {
        _selectedCategory = State(initialValue: initialCategory)
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            MenuBarConfiguratorView(selectedCategory: $selectedCategory)
        }
        .frame(minWidth: AppConfig.UI.configuratorMinWidth, minHeight: AppConfig.UI.configuratorMinHeight)
        .background(Theme.windowBg)
    }
}
