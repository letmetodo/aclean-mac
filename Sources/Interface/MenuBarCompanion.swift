import SwiftUI
import AppKit
import Combine

// ============================================================
//  MenuBarCompanion.swift —— 现代受光玻璃态菜单栏监控台与多维系统看板
//
//  设计理念与美学特征 (CleanMate Design System / CleanMate 美学)：
//    1. 核心硬件监控指标体系：
//       - CPU: 总占用、User/System/Idle、双流走势、P/E核矩阵、SoC温度、M2/M4芯片标牌、FPS刷新率、Load Average峰值与走势、Uptime系统运行时间、Top CPU进程、实用工具快捷坞；
//       - 内存: 内存压力等级与百分比、App/Wired/Compressed/Cache/Free精细化五色分层彩条、Top内存进程真实物理足迹、Swap交换分区、Page Ins/Outs分页速率；
//       - 网络: 公网出口IP与国旗图标(如🇸🇬)、Wi-Fi/以太网活跃连接、局域网IPv4与IPv6、上下行对称双向实时波形、峰值↑↓标记、未连接硬件适配器列表、高流量进程；
//       - 传感器与风扇: 物理双风扇RPM与占空比、系统自动/降温50%/强冷100%三档温控、整机功耗(W)/总线电压(V)/电池电流(A)、全量微观传感器(CPU/GPU/AirPort/Airflow/Battery/PalmRest/SSD)；
//       - 磁盘: Macintosh HD容量彩条、APFS可清除容量、磁盘读写I/O实时走势、外置磁盘一键推出；
//       - 电池与外设: 电池健康、循环、系统功耗、蓝牙外设电量；
//       - 综合总览: 天气实况与预报、核心硬件Bento网格、快捷清理与状态坞。
//    2. 样式重塑：告别老旧灰色Win98切面，采用CleanMate受光玻璃、环境光晕、柔和微质感与自适应深浅色主题；
//    3. 灵活交互：支持顶部胶囊分类一键切换查看专属看板，亦保留鼠标滑过卡片弹出二级详情子面板的双模式体验。
// ============================================================

// MARK: - 顶部导航分类枚举

enum PopoverCategoryTab: String, CaseIterable, Identifiable {
    case overview = "overview"
    case cpu      = "cpu"
    case memory   = "memory"
    case network  = "network"
    case sensors  = "sensors"
    case disk     = "disk"
    case battery  = "battery"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return L10n.localized(.categoryOverview)
        case .cpu:      return "CPU"
        case .memory:   return L10n.localized(.memory)
        case .network:  return L10n.localized(.network)
        case .sensors:  return L10n.localized(.sensors)
        case .disk:     return L10n.localized(.disks)
        case .battery:  return L10n.localized(.battery)
        }
        }

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .cpu:      return "cpu"
        case .memory:   return "memorychip"
        case .network:  return "network"
        case .sensors:  return "thermometer.medium"
        case .disk:     return "internaldrive.fill"
        case .battery:  return "battery.100.bolt"
        }
    }
}

// MARK: - 悬停二级子面板状态机

@MainActor
final class SubcategoryFlyoutState: ObservableObject {
    static let shared = SubcategoryFlyoutState()

    @Published var activeSubcategory: CompanionSubcategoryKind? = nil
    @Published var isHoveringMainItem: Bool = false
    @Published var isHoveringFlyoutPanel: Bool = false
    @Published var isInteractingWithTextInput: Bool = false
    var itemTopOffsets: [CompanionSubcategoryKind: CGFloat] = [:]

    var hideWorkItem: DispatchWorkItem?
    var pendingEnterWorkItem: DispatchWorkItem?

    func defaultTopOffset(for kind: CompanionSubcategoryKind) -> CGFloat {
        switch kind {
        case .calendar: return 9
        case .weather:  return 56
        case .cpu, .gpu: return 103
        case .memory:   return 173
        case .network:  return 243
        case .battery:  return 313
        case .fan:      return 360
        case .disk:     return 313
        }
    }

    func enterMainItemWithSubcategory(_ kind: CompanionSubcategoryKind) {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        isHoveringMainItem = true

        if isInteractingWithTextInput && activeSubcategory != nil {
            pendingEnterWorkItem?.cancel()
            pendingEnterWorkItem = nil
            return
        }

        if activeSubcategory == kind {
            pendingEnterWorkItem?.cancel()
            pendingEnterWorkItem = nil
            return
        }

        pendingEnterWorkItem?.cancel()
        let delay: TimeInterval = (activeSubcategory != nil) ? 0.08 : 0.11
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.isHoveringMainItem, !self.isInteractingWithTextInput else { return }
            self.activeSubcategory = kind
            MenuBarCompanion.shared.syncSubcategoryFlyoutPanel()
        }
        pendingEnterWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func setActiveSubcategory(_ kind: CompanionSubcategoryKind) {
        pendingEnterWorkItem?.cancel()
        pendingEnterWorkItem = nil
        hideWorkItem?.cancel()
        hideWorkItem = nil
        if activeSubcategory != kind {
            isInteractingWithTextInput = false
        }
        isHoveringMainItem = true
        activeSubcategory = kind
        MenuBarCompanion.shared.syncSubcategoryFlyoutPanel()
    }

    func toggleSubcategory(_ kind: CompanionSubcategoryKind) {
        pendingEnterWorkItem?.cancel()
        pendingEnterWorkItem = nil
        hideWorkItem?.cancel()
        hideWorkItem = nil
        isInteractingWithTextInput = false
        if activeSubcategory == kind {
            activeSubcategory = nil
            isHoveringMainItem = false
        } else {
            activeSubcategory = kind
            isHoveringMainItem = true
        }
        MenuBarCompanion.shared.syncSubcategoryFlyoutPanel()
    }

    func clearActiveSubcategory() {
        pendingEnterWorkItem?.cancel()
        pendingEnterWorkItem = nil
        hideWorkItem?.cancel()
        hideWorkItem = nil
        isInteractingWithTextInput = false
        isHoveringMainItem = false
        isHoveringFlyoutPanel = false
        if activeSubcategory != nil {
            activeSubcategory = nil
            MenuBarCompanion.shared.syncSubcategoryFlyoutPanel()
        }
    }

    func enterMainItemWithoutSubcategory() {
        if isInteractingWithTextInput && activeSubcategory != nil {
            return
        }
        pendingEnterWorkItem?.cancel()
        pendingEnterWorkItem = nil
        hideWorkItem?.cancel()
        hideWorkItem = nil
        isHoveringMainItem = false
        isHoveringFlyoutPanel = false
        if activeSubcategory != nil {
            activeSubcategory = nil
            MenuBarCompanion.shared.syncSubcategoryFlyoutPanel()
        }
    }

    func leaveMainItem(for kind: CompanionSubcategoryKind) {
        pendingEnterWorkItem?.cancel()
        pendingEnterWorkItem = nil
        isHoveringMainItem = false
        scheduleHideIfNeeded()
    }

    func setHoveringFlyout(_ hovering: Bool) {
        hideWorkItem?.cancel()
        hideWorkItem = nil
        isHoveringFlyoutPanel = hovering
        if !hovering && !isHoveringMainItem && !isInteractingWithTextInput {
            scheduleHideIfNeeded(delay: 0.20)
        }
    }

    func scheduleHideIfNeeded(delay: TimeInterval = 0.24) {
        hideWorkItem?.cancel()
        guard !isInteractingWithTextInput else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if !self.isHoveringMainItem && !self.isHoveringFlyoutPanel && !self.isInteractingWithTextInput {
                self.activeSubcategory = nil
                MenuBarCompanion.shared.syncSubcategoryFlyoutPanel()
            }
        }
        hideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    func reset() {
        pendingEnterWorkItem?.cancel()
        pendingEnterWorkItem = nil
        hideWorkItem?.cancel()
        hideWorkItem = nil
        isInteractingWithTextInput = false
        isHoveringMainItem = false
        isHoveringFlyoutPanel = false
        activeSubcategory = nil
    }
}

// MARK: - 支持键盘与输入法焦点的无边框悬浮子面板

final class SubcategoryFlyoutPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown {
            if !NSApp.isActive {
                NSApp.activate(ignoringOtherApps: true)
            }
            if !isKeyWindow {
                makeKey()
            }
        }
        super.sendEvent(event)
    }
}

// MARK: - 菜单栏状态控制器

@MainActor
final class MenuBarCompanion: NSObject, NSPopoverDelegate {

    static let shared = MenuBarCompanion()

    var systemStatusItem: NSStatusItem?
    var weatherStatusItem: NSStatusItem?

    var systemPopover: NSPopover?
    var weatherPopover: NSPopover?
    var flyoutPanel: NSPanel?
    var lastRenderedSubcategory: CompanionSubcategoryKind?

    let service = SystemTelemetryService.shared
    let weatherService = WeatherService.shared
    let configStore = MenuBarConfigStore.shared
    let flyoutState = SubcategoryFlyoutState.shared
    var cancellables = Set<AnyCancellable>()

    var caffeinateProcess: Process?

    override init() {
        super.init()
    }

    func setup() {
        guard AppConfigStore.shared.menuBarMonitor else { setVisible(false); return }
        service.setMenuBarVisible(true)
        setupSystemStatusItem()
        if let weatherItem = weatherStatusItem {
            NSStatusBar.system.removeStatusItem(weatherItem)
            weatherStatusItem = nil
        }
        bindUpdates()
        systemStatusItem?.isVisible = true
    }

    func setVisible(_ visible: Bool) {
        service.setMenuBarVisible(visible)
        if visible {
            setup()
        } else {
            hideSubcategoryFlyoutPanel()
            systemPopover?.performClose(nil)
            weatherPopover?.performClose(nil)
            systemStatusItem?.isVisible = false
            if let weatherItem = weatherStatusItem {
                NSStatusBar.system.removeStatusItem(weatherItem)
                weatherStatusItem = nil
            }
        }
    }

    func setupSystemStatusItem() {
        guard systemStatusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.imagePosition = .imageLeft
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
            button.target = self
            button.action = #selector(handleSystemStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.systemStatusItem = item

        let pop = NSPopover()
        pop.contentSize = preferredPopoverSize()
        pop.behavior = .applicationDefined
        pop.delegate = self
        self.systemPopover = pop

        refreshSystemStatusBarAppearance()
    }

    func setupWeatherStatusItem() {
        guard weatherStatusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "cloud.sun.fill", accessibilityDescription: L10n.localized(.weather))
            button.imagePosition = .imageLeft
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
            button.target = self
            button.action = #selector(handleWeatherStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        self.weatherStatusItem = item

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 330, height: 530)
        pop.behavior = .transient
        pop.delegate = self
        self.weatherPopover = pop

        refreshWeatherStatusBarAppearance()
    }

    func bindUpdates() {
        cancellables.removeAll()

        service.$latestSnapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshSystemStatusBarAppearance()
            }
            .store(in: &cancellables)

        weatherService.$current
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshSystemStatusBarAppearance()
                self?.refreshWeatherStatusBarAppearance()
            }
            .store(in: &cancellables)

        configStore.objectWillChange
            .debounce(for: .milliseconds(80), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshSystemStatusBarAppearance()
                self?.updatePopoverSize()
                self?.syncSubcategoryFlyoutPanel()
            }
            .store(in: &cancellables)

        AppConfigStore.shared.objectWillChange
            .debounce(for: .milliseconds(80), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshSystemStatusBarAppearance()
                self?.syncSubcategoryFlyoutPanel()
            }
            .store(in: &cancellables)
    }

    func refreshSystemStatusBarAppearance() {
        guard let button = systemStatusItem?.button else { return }
        let snap = service.latestSnapshot
        let weather = weatherService.current
        let tokens = configStore.activeMenuBarTokens

        if configStore.useDualLineMenuBar && !tokens.isEmpty {
            let img = MenuBarDualLineRenderer.renderStatusBarImage(
                tokens: tokens,
                snapshot: snap,
                weather: weather,
                cpuHistory: service.cpuHistory
            )
            button.image = img
            button.title = ""
            button.imagePosition = .imageOnly
        } else {
            let cpu = Int(((snap?.cpu.totalUsage ?? 0) * 100.0).rounded())
            let mem = Int(((snap?.memory.usedRatio ?? 0) * 100.0).rounded())
            button.image = NSImage(systemSymbolName: "gauge.with.dots.needle.67percent", accessibilityDescription: L10n.localized(.appBrandName))
            button.imagePosition = .imageLeft
            button.title = " \(cpu)% · \(mem)%"
        }
    }

    func refreshWeatherStatusBarAppearance() {
        guard let button = weatherStatusItem?.button else { return }
        let snap = weatherService.current
        if snap.isLoadedFromNetwork {
            button.title = String(format: " %.0f°", snap.currentTemp)
            button.image = NSImage(systemSymbolName: snap.conditionIcon, accessibilityDescription: snap.localizedConditionText)
        } else {
            button.title = " " + L10n.localized(.weather)
            button.image = NSImage(systemSymbolName: "cloud.sun.fill", accessibilityDescription: L10n.localized(.weather))
        }
    }

    func preferredPopoverSize() -> NSSize {
        let store = configStore
        let width: CGFloat = store.useDualColumnDropdown ? 675 : 340
        let screenMax = (NSScreen.main?.visibleFrame.height ?? 900) - 36
        let compactHeight: CGFloat = min(screenMax, 520)
        return NSSize(width: width, height: compactHeight)
    }

    func updatePopoverSize() {
        systemPopover?.contentSize = preferredPopoverSize()
    }

    func exactFlyoutContentHeight(for sub: CompanionSubcategoryKind) -> CGFloat {
        switch sub {
        case .calendar:  return 440
        case .weather:   return 430
        case .cpu, .gpu: return 485
        case .memory:    return 485
        case .network:   return 475
        case .battery:   return 330
        case .fan:       return 520
        case .disk:      return 485
        }
    }

    func syncSubcategoryFlyoutPanel() {
        guard systemPopover?.isShown == true,
              !configStore.useDualColumnDropdown,
              let activeSub = flyoutState.activeSubcategory,
              let contentView = systemPopover?.contentViewController?.view,
              let popWindow = contentView.window else {
            hideSubcategoryFlyoutPanel()
            return
        }

        let panelWidth: CGFloat = 330
        let screenFrame = popWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let maxAllowedFlyoutHeight: CGFloat = screenFrame.height - 40

        if flyoutPanel == nil {
            let panel = SubcategoryFlyoutPanel(
                contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: 360),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.becomesKeyOnlyIfNeeded = false
            panel.level = .popUpMenu
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            panel.acceptsMouseMovedEvents = true
            panel.contentViewController = NSHostingController(rootView: SubcategoryFlyoutRootView())
            self.flyoutPanel = panel
        }

        guard let panel = flyoutPanel else { return }
        let hostingVC: NSHostingController<SubcategoryFlyoutRootView>
        if let existingVC = panel.contentViewController as? NSHostingController<SubcategoryFlyoutRootView> {
            if lastRenderedSubcategory != activeSub {
                existingVC.rootView = SubcategoryFlyoutRootView()
            }
            hostingVC = existingVC
        } else {
            let newVC = NSHostingController(rootView: SubcategoryFlyoutRootView())
            panel.contentViewController = newVC
            hostingVC = newVC
        }
        lastRenderedSubcategory = activeSub

        hostingVC.view.wantsLayer = true
        hostingVC.view.layer?.cornerRadius = 12
        hostingVC.view.layer?.cornerCurve = .continuous
        hostingVC.view.layer?.masksToBounds = true
        hostingVC.view.invalidateIntrinsicContentSize()
        hostingVC.view.layoutSubtreeIfNeeded()

        let fittedHeight = hostingVC.view.fittingSize.height
        let rawHeight = fittedHeight > 80 ? fittedHeight : exactFlyoutContentHeight(for: activeSub)
        let panelHeight = min(maxAllowedFlyoutHeight, rawHeight)

        // 转换主弹窗内容视图的真实屏幕坐标（消除 NSPopover 外层阴影窗口带来的额外留白）
        let contentRectInWindow = contentView.convert(contentView.bounds, to: nil)
        let contentRectOnScreen = popWindow.convertToScreen(contentRectInWindow)

        // 紧贴右侧主面板（仅保留 2pt 呼吸微缝）
        var targetX = contentRectOnScreen.minX - panelWidth - 2
        if targetX < screenFrame.minX + 6 {
            targetX = contentRectOnScreen.maxX + 2
        }

        // 纵向跟随当前悬停/选中的模块卡片顶部位置对齐展示，底部不超出屏幕可见区
        let cardTopOffset = max(0, flyoutState.itemTopOffsets[activeSub] ?? flyoutState.defaultTopOffset(for: activeSub))
        let cardTopOnScreen = contentRectOnScreen.maxY - cardTopOffset
        let desiredY = cardTopOnScreen - panelHeight
        let targetY = max(screenFrame.minY + 8, min(desiredY, contentRectOnScreen.maxY - panelHeight))
        let targetFrame = NSRect(x: targetX, y: targetY, width: panelWidth, height: panelHeight)

        panel.acceptsMouseMovedEvents = true
        panel.setFrame(targetFrame, display: true)
        panel.invalidateShadow()
        if panel.parent != popWindow {
            popWindow.addChildWindow(panel, ordered: .above)
        }
        panel.orderFront(nil)
    }

    func hideSubcategoryFlyoutPanel() {
        lastRenderedSubcategory = nil
        guard let panel = flyoutPanel else { return }
        if let parent = panel.parent {
            parent.removeChildWindow(panel)
        }
        panel.orderOut(nil)
        panel.contentViewController = nil
    }

    func focusWindowForTextInput(_ window: NSWindow? = nil) {
        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
        }
        if let target = window {
            target.makeKeyAndOrderFront(nil)
        } else if let panel = flyoutPanel, panel.isVisible {
            panel.makeKeyAndOrderFront(nil)
        } else if let popWin = systemPopover?.contentViewController?.view.window, systemPopover?.isShown == true {
            popWin.makeKey()
        } else if let weatherWin = weatherPopover?.contentViewController?.view.window, weatherPopover?.isShown == true {
            weatherWin.makeKey()
        }
    }

    private var isComposingMarkedTextInPopoverOrFlyout: Bool {
        if let tv = flyoutPanel?.firstResponder as? NSTextView, tv.hasMarkedText() {
            return true
        }
        if let tv = systemPopover?.contentViewController?.view.window?.firstResponder as? NSTextView, tv.hasMarkedText() {
            return true
        }
        return false
    }

    func closeSystemPopover() {
        stopOutsideClickMonitor()
        hideSubcategoryFlyoutPanel()
        systemPopover?.performClose(nil)
    }

    private var outsideClickGlobalMonitor: Any?
    private var outsideClickLocalMonitor: Any?

    func startOutsideClickMonitor() {
        stopOutsideClickMonitor()

        // 1. 全局鼠标监听：当点击其他菜单栏卡片、其他软件窗口或桌面时自动收回（排除输入法候选框选词点击）
        outsideClickGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.systemPopover?.isShown == true else { return }
                guard !self.isComposingMarkedTextInPopoverOrFlyout else { return }
                self.closeSystemPopover()
            }
        }

        // 2. 局部鼠标监听：当点击本应用其他窗口或面板时自动收回
        outsideClickLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.systemPopover?.isShown == true else { return event }
            let clickLoc = NSEvent.mouseLocation
            let popWindow = self.systemPopover?.contentViewController?.view.window
            let popFrame = popWindow?.frame ?? .zero
            let flyoutFrame = self.flyoutPanel?.frame ?? .zero
            let statusItemFrame = self.systemStatusItem?.button?.window?.frame ?? .zero

            if !popFrame.contains(clickLoc) && !flyoutFrame.contains(clickLoc) && !statusItemFrame.contains(clickLoc) {
                DispatchQueue.main.async { [weak self] in
                    self?.closeSystemPopover()
                }
            }
            return event
        }
    }

    func stopOutsideClickMonitor() {
        if let monitor = outsideClickGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickGlobalMonitor = nil
        }
        if let monitor = outsideClickLocalMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickLocalMonitor = nil
        }
    }

    @objc func handleSystemStatusItemClick(_ sender: Any?) {
        let isRightClick: Bool
        if let event = NSApp.currentEvent {
            isRightClick = event.type == .rightMouseUp ||
                (event.type == .leftMouseUp && event.modifierFlags.contains(.control))
        } else {
            isRightClick = false
        }

        if isRightClick {
            showStatusItemContextMenu(for: systemStatusItem)
        } else {
            toggleSystemPopover()
        }
    }

    @objc func handleWeatherStatusItemClick(_ sender: Any?) {
        let isRightClick: Bool
        if let event = NSApp.currentEvent {
            isRightClick = event.type == .rightMouseUp ||
                (event.type == .leftMouseUp && event.modifierFlags.contains(.control))
        } else {
            isRightClick = false
        }

        if isRightClick {
            showStatusItemContextMenu(for: weatherStatusItem)
        } else {
            toggleWeatherPopover()
        }
    }

    func showStatusItemContextMenu(for item: NSStatusItem?) {
        closeSystemPopover()
        weatherPopover?.performClose(nil)

        let menu = NSMenu()

        // 1. 一键清理
        let cleanItem = NSMenuItem(
            title: L10n.localized(.oneClickCleanMenuTitle),
            action: #selector(triggerOneClickClean),
            keyEquivalent: ""
        )
        cleanItem.target = self
        cleanItem.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
        menu.addItem(cleanItem)

        // 2. AClean 模块管理
        let modulesItem = NSMenuItem(
            title: L10n.localized(.actionOpenModuleManagement),
            action: #selector(openModuleManagementFromMenu),
            keyEquivalent: ""
        )
        modulesItem.target = self
        modulesItem.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil)
        menu.addItem(modulesItem)

        menu.addItem(NSMenuItem.separator())

        // 3. 打开偏好设置
        let prefsItem = NSMenuItem(
            title: L10n.localized(.openPreferencesMenuTitle),
            action: #selector(openPreferencesFromMenu),
            keyEquivalent: ","
        )
        prefsItem.target = self
        prefsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // 4. 退出 CleanMate
        let quitItem = NSMenuItem(
            title: L10n.localized(.quitCleanMateMenuTitle),
            action: #selector(quitAppFromMenu),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        if let button = (item ?? systemStatusItem)?.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
        }
    }

    @objc func triggerOneClickClean() {
        closeSystemPopover()
        weatherPopover?.performClose(nil)
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            if let appState = AppState.shared {
                appState.open(.restore(.junk))
                appState.didApplyDefaultsCurrentModule = false
                appState.startScan(for: "junk", forceRestart: true)
            }
            if let w = NSApp.windows.first(where: { $0.canBecomeMain && !($0 is NSPanel) }) {
                w.deminiaturize(nil)
                w.makeKeyAndOrderFront(nil)
            }
        }
    }

    @objc func openModuleManagementFromMenu() {
        closeSystemPopover()
        weatherPopover?.performClose(nil)
        AppState.shared?.openSettings(tab: "menubar")
    }

    @objc func openPreferencesFromMenu() {
        closeSystemPopover()
        weatherPopover?.performClose(nil)
        AppState.shared?.openSettings(tab: "appearance")
    }

    @objc func quitAppFromMenu() {
        NSApp.terminate(nil)
    }

    @objc func toggleSystemPopover() {
        guard let button = systemStatusItem?.button, let pop = systemPopover else { return }
        if weatherPopover?.isShown == true { weatherPopover?.performClose(nil) }

        if pop.isShown {
            closeSystemPopover()
        } else {
            flyoutState.reset()
            if pop.contentViewController == nil {
                pop.contentViewController = NSHostingController(rootView: MenuBarPopoverView())
            }
            pop.contentSize = preferredPopoverSize()
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            startOutsideClickMonitor()
            if let popWindow = pop.contentViewController?.view.window {
                popWindow.acceptsMouseMovedEvents = true
                popWindow.makeKey()
                popWindow.makeFirstResponder(nil)
            }
        }
    }

    @objc func toggleWeatherPopover() {
        guard let button = weatherStatusItem?.button, let pop = weatherPopover else { return }
        if systemPopover?.isShown == true {
            hideSubcategoryFlyoutPanel()
            systemPopover?.performClose(nil)
        }

        if pop.isShown {
            pop.performClose(nil)
        } else {
            if pop.contentViewController == nil {
                pop.contentViewController = NSHostingController(rootView: WeatherPopoverView())
            }
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            pop.contentViewController?.view.window?.makeKey()
        }
    }

    func toggleCaffeinate() -> Bool {
        if let proc = caffeinateProcess, proc.isRunning {
            proc.terminate()
            caffeinateProcess = nil
            return false
        } else {
            let p = Process()
            p.launchPath = "/usr/bin/caffeinate"
            p.arguments = ["-dism", "-w", String(ProcessInfo.processInfo.processIdentifier)]
            try? p.run()
            caffeinateProcess = p
            return true
        }
    }

    var isCaffeinateActive: Bool {
        return caffeinateProcess?.isRunning == true
    }

    func ejectAllExternalVolumes() {
        let drives = service.latestSnapshot?.externalDrives ?? []
        for vol in drives where vol.isEjectable || vol.isRemovable {
            let url = URL(fileURLWithPath: vol.path)
            try? NSWorkspace.shared.unmountAndEjectDevice(at: url)
        }
    }

    func popoverWillShow(_ notification: Notification) {
        service.subscribe()
        startOutsideClickMonitor()
    }

    func popoverDidClose(_ notification: Notification) {
        stopOutsideClickMonitor()
        flyoutState.reset()
        hideSubcategoryFlyoutPanel()
        if let closedPop = notification.object as? NSPopover {
            closedPop.contentViewController = nil
        }
        service.unsubscribe()
    }
}
