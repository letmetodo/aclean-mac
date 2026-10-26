import SwiftUI
import AppKit
import Combine

@main
struct CleanMateApp: App {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var state = AppState()
    @State private var initialized = false
    @State private var debugEntryApplied = false

    var body: some Scene {
        WindowGroup {
            AppChrome()
                .environmentObject(state)
                .transaction { if reduceMotion { $0.disablesAnimations = true; $0.animation = nil } }
                .frame(minWidth: AppConfig.UI.defaultWindowMinWidth, minHeight: AppConfig.UI.defaultWindowMinHeight)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    SMCBridge.shared.resetFanToAutoOnTermination()
                }
                .onAppear {
                    guard !initialized else { return }
                    initialized = true
                    bootstrapKnowledgeBase()
                    applyDebugEntry()
                    MenuBarCompanion.shared.setup()
                    FullDiskAccessManager.shared.triggerRegistration()
                    setupScheduler()
                    guard !CommandLine.arguments.contains("--scheduled-scan") else { return }
                    DispatchQueue.main.async {
                        if let w = NSApp.windows.first(where: { $0.canBecomeMain }) {
                            let curW = w.frame.width
                            let curH = w.frame.height
                            let targetW = max(curW, AppConfig.UI.defaultWindowWidth)
                            let targetH = max(curH, AppConfig.UI.defaultWindowHeight)
                            if curW < AppConfig.UI.defaultWindowWidth || curH < AppConfig.UI.defaultWindowHeight {
                                w.setContentSize(CGSize(width: targetW, height: targetH))
                            }
                            if w.frame.origin.x < 0 || w.frame.origin.y < 0 {
                                w.center()
                            }
                            w.makeKeyAndOrderFront(nil)
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: AppConfig.UI.defaultWindowWidth, height: AppConfig.UI.defaultWindowHeight)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appSettings) {
                Button(L10n.localized(.preferencesEllipsis)) {
                    state.showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandMenu(L10n.localized(.commandPaletteTitle)) {
                Button(L10n.localized(.commandPaletteTitle)) {
                    state.showCommandPalette = true
                }
                .keyboardShortcut("k", modifiers: .command)
            }
            CommandMenu(L10n.localized(.groupSystemManage)) {
                ForEach(ModuleRegistry.conciseModules, id: \.key) { m in
                    Button(m.title) { state.open(.restore(ModuleKey.parse(m.key) ?? .junk)) }
                }
                Divider()
                Button(L10n.localized(.menuBarConfig)) {
                    state.openSettings(tab: "menubar")
                }
                .keyboardShortcut("m", modifiers: [.command, .option])
            }
        }
    }

    /// 初始化定时调度服务（支持前台定时触发与 LaunchAgent `--scheduled-scan` 启动触发）
    private func setupScheduler() {
        let runScheduledJob: () async -> Bool = {
            await state.runScheduledCleanup()
        }

        SchedulerService.shared.setTrigger {
            await runScheduledJob()
        }
        SchedulerService.shared.start()

        if CommandLine.arguments.contains("--scheduled-scan") {
            Task {
                await SchedulerService.shared.triggerDueJob()
            }
        }
    }

    @MainActor
    private func bootstrapKnowledgeBase() {
        if state.ruleUpdateObserver == nil {
            state.ruleUpdateObserver = NotificationCenter.default.addObserver(
                forName: Notification.Name(AppConfig.RuleUpdates.changedNotification), object: nil, queue: .main
            ) { [weak state] _ in Task { @MainActor in state?.rulesDidChange() } }
        }
        RuleUpdateService.shared.bootstrap()
        RuleUpdateService.shared.start()
    }

    /// 调试入口：仅在明确通过 `--debug-module <模块>` 参数或 `DEBUG_MODULE` 环境变量启动时生效。
    /// 彻底清除 UserDefaults 中可能残留的 DebugModule 键，杜绝正常启动时误开偏好设置。
    private func applyDebugEntry() {
        guard !debugEntryApplied else { return }
        debugEntryApplied = true

        // 清理 UserDefaults 中的历史遗留键，避免持久化开机自动弹窗
        if UserDefaults.standard.object(forKey: "DebugModule") != nil {
            UserDefaults.standard.removeObject(forKey: "DebugModule")
        }

        // 仅响应显式传入的命令行参数或环境变量
        var raw: String? = ProcessInfo.processInfo.environment["DEBUG_MODULE"]
        if raw == nil || raw?.isEmpty == true {
            if let idx = CommandLine.arguments.firstIndex(of: "--debug-module"),
               idx + 1 < CommandLine.arguments.count {
                raw = CommandLine.arguments[idx + 1]
            }
        }

        guard let debugVal = raw, !debugVal.isEmpty else {
            state.open(.restore(.healthCheck))
            return
        }
        if debugVal == "menubarConfig" {
            DispatchQueue.main.async {
                self.state.openSettings(tab: "menubar")
            }
            return
        }
        let parts = debugVal.split(separator: ":").map(String.init)
        let key = parts[0]
        let stage = parts.count > 1 ? parts[1] : "results"
        state.open(.restore(ModuleKey.parse(key) ?? .junk))
        guard stage != "intro" else { return }
        state.debugStage = stage
        state.startScan()
    }
}

typealias ACleanApp = CleanMateApp
