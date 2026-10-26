import AppKit
import Combine
import Foundation

/// 权限协调器 (PermissionCoordinator)
///
/// 负责完全磁盘访问权限 (FDA) 的引导、双窗口并排协同、1.0s 无感状态轮询以及自动重试重放：
/// 1. 触发双窗口协同：唤起系统设置「完全磁盘访问权限」面板，并在 Finder 中高亮显示 CleanMate.app 供直接拖拽；
/// 2. 1.0s 响应式无感轮询：用户在设置中开启权限后 1 秒内自动检测并触发完成动画；
/// 3. 操作自动重放：用户授权后自动执行由于权限受限而阻断的清理或卸载操作，无需重复点击。
@MainActor
final class PermissionCoordinator: ObservableObject {
    static let shared = PermissionCoordinator()

    @Published private(set) var isRequesting: Bool = false
    @Published private(set) var hasFullDiskAccess: Bool = false
    @Published private(set) var accessStatus: FullDiskAccessManager.AccessStatus = .unknown
    @Published private(set) var failedItemPaths: [String] = []
    @Published private(set) var context: PromptContext = .general

    enum PromptContext: Equatable {
        case general
        case cleanup(failedCount: Int)
        case uninstall(appName: String, failedCount: Int)

        var headline: String {
            switch self {
            case .general:
                return L10n.localized(.permissionGrantFullDiskAccessTitle)
            case .cleanup(let n):
                return L10n.format(.permissionCleanupItemsNeedFdaFormat, n)
            case .uninstall(let app, let n):
                return L10n.format(.permissionUninstallItemsNeedFdaFormat, app, n)
            }
        }

        var message: String {
            switch self {
            case .general:
                return L10n.localized(.permissionFdaGeneralExplanation)
            case .cleanup:
                return L10n.localized(.permissionFdaProtectedDirExplanation)
            case .uninstall(let app, _):
                return L10n.format(.permissionFdaSandboxContainerExplanationFormat, app)
            }
        }
    }

    private var pollTimer: Timer?
    private var onGrantCallback: (() -> Void)?
    private var pendingGrantWork: DispatchWorkItem?
    private var probeInFlight = false
    private var activationObserver: NSObjectProtocol?

    private init() {
        refreshStatus()
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshStatus()
                AppState.shared?.checkFullDiskAccess(force: true)
            }
        }
    }

    /// 发起权限请求与引导流程。
    /// 若已获得权限，立即同步调用 `onGranted()` 并退出；否则弹起引导面板并开启 1.0s 轮询。
    func requestAccess(
        context: PromptContext = .general,
        failedPaths: [String] = [],
        onGranted: @escaping () -> Void
    ) {
        onGrantCallback = nil
        pendingGrantWork?.cancel()
        pendingGrantWork = nil

        self.context = context
        self.failedItemPaths = failedPaths
        self.onGrantCallback = onGranted
        if hasFullDiskAccess {
            onGranted()
            onGrantCallback = nil
            return
        }

        isRequesting = true
        startPolling()
    }

    /// 双窗口并排引导：打开系统设置 FDA 面板，并在延迟后在访达中高亮展示 CleanMate.app
    func openSettingsAndReveal() {
        FullDiskAccessManager.shared.openFullDiskAccessSettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.UI.revealInFinderDelaySeconds) {
            FullDiskAccessManager.shared.revealAppInFinder()
        }
    }

    /// 重置 TCC 登记并重新唤醒
    func resetAndReprime() {
        Task.detached(priority: .userInitiated) {
            _ = FullDiskAccessManager.shared.resetFullDiskAccess()
            FullDiskAccessManager.shared.triggerRegistration()
            await MainActor.run {
                FullDiskAccessManager.shared.openFullDiskAccessSettings()
            }
        }
    }

    /// 关闭权限引导浮层
    func dismiss(callRetry: Bool = false) {
        stopPolling()
        pendingGrantWork?.cancel()
        pendingGrantWork = nil
        let callback = onGrantCallback
        onGrantCallback = nil
        isRequesting = false
        failedItemPaths = []
        context = .general
        if callRetry {
            callback?()
        }
    }

    /// 刷新权限状态（如应用重新激活时）
    func refreshStatus() {
        guard !probeInFlight else { return }
        probeInFlight = true
        Task.detached(priority: .userInitiated) {
            let status = FullDiskAccessManager.shared.accessStatus
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.probeInFlight = false
                self.accessStatus = status
                let granted = status == .granted
                let wasGranted = self.hasFullDiskAccess
                self.hasFullDiskAccess = granted
                if AppState.shared?.hasFullDiskAccess != granted {
                    AppState.shared?.hasFullDiskAccess = granted
                }
                if granted && !wasGranted && self.isRequesting {
                    self.handleGrant()
                }
            }
        }
    }

    // MARK: - 轮询与重放控制

    private func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.UI.permissionPollIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshStatus() }
        }

        // 立即检测一次
        refreshStatus()
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    /// 处理授权成功：停止轮询，展示 1.0s 成功动效后自动收起并执行重试回调
    private func handleGrant() {
        let callback = onGrantCallback
        onGrantCallback = nil
        stopPolling()

        pendingGrantWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.isRequesting = false
            self.failedItemPaths = []
            self.context = .general
            self.pendingGrantWork = nil
            callback?()
        }
        pendingGrantWork = work

        // 留出 1.0s 让用户看到「已授权」成功动效，然后无感自动重试
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
    }
}
