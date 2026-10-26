import Foundation
import SwiftUI

// ============================================================
//  8 屏流程与全局响应式主状态 (AppState)
//
//  ① 介绍 → ② 扫描进度 → ③ 磁贴结果 → ④ 数据管理器
//  → ⑤ 清理前确认 → ⑥ 清理进度 → ⑦ 清理结果 → ⑧ 清理日志
// ============================================================

/// 轻提示的语义类型：决定图标与强调色，让用户不用读文字也能判断结果好坏。
enum ToastKind: Sendable {
    case info
    case success
    case warning
    case error
}

/// 轻提示上可挂载的一个动作（典型用法：「撤销」）。
/// 仅在主线程使用，与 AppState 同隔离域。
@MainActor
struct ToastAction {
    let title: String
    let handler: @MainActor () -> Void
}

@MainActor
final class AppState: ObservableObject {

    public static weak var shared: AppState?

    // MARK: 导航（支持未扫描中间态与扫描完成结果态）
    @Published var moduleKey: ModuleKey = .junk
    @Published var screen: Screen = .intro
    @Published var disk = DiskInfo.current()
    @Published var sidebarCollapsedOverride: Bool? = nil

    /// 各模块独立状态表（所有权私有，来回拷贝仅限 open 与 write）
    var ruleUpdateObserver: NSObjectProtocol?
    let moduleSessions = ModuleSessionStore()
    @Published var activeScanningModules: Set<String> = []
    var isSwitchingModule: Bool = false
    var smartScanGeneration = 0
    var smartScanFlags: [String: StopFlag] = [:]
    var pendingCleanupModuleKey: String?
    var scheduledRunActive = false
    var lastCleanupTargets: [String: [CleanTarget]] = [:]
    let scanBuilder: ((String) -> ScanTreeBuilder?)?

    // MARK: 全局清理运行互斥追踪 (F3)
    @Published var activeCleanupRun: ActiveCleanupRun? = nil

    var isAnyModuleCleaning: Bool {
        activeCleanupRun != nil
    }

    func isModuleCleaning(_ key: String) -> Bool {
        activeCleanupRun?.moduleKey == key
    }

    // MARK: 偏好设置与系统协同
    @Published var showSettings: Bool = false
    /// 命令面板（⌘K）是否展开
    @Published var showCommandPalette: Bool = false
    @Published var showOnboarding: Bool = false
    @Published var settingsSelectedTab: String = "appearance"
    @Published var preferencesBoxSize: CGSize = CGSize(width: 890, height: 660)
    @Published var preferencesBoxOffset: CGSize = .zero
    @Published var scheduler: SchedulerService = SchedulerService.shared
    @Published var configStore: AppConfigStore = AppConfigStore.shared
    @Published var l10n: L10n = L10n.shared
    @Published var cleanCoordinator: CleanCoordinator = CleanCoordinator.shared
    /// 清理是否已暂停。
    /// 刻意在 AppState 做镜像而不是直接读 `cleanCoordinator.isPaused`：
    /// AppState 对 coordinator 只是普通引用，coordinator 内部的 @Published 不会转发，
    /// 暂停时进度又恰好不更新，界面就收不到刷新信号。
    @Published var cleanupPaused: Bool = false

    init(scanBuilder: ((String) -> ScanTreeBuilder?)? = nil) {
        self.scanBuilder = scanBuilder
        let completed = UserDefaults.standard.bool(forKey: AppConfig.StorageKeys.onboardingCompleted)
        let awaitingRelaunch = UserDefaults.standard.bool(forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch)
        let isAutomatedRun = CommandLine.arguments.contains("--scheduled-scan")
            || CommandLine.arguments.contains("--debug-module")
            || !(ProcessInfo.processInfo.environment["DEBUG_MODULE"] ?? "").isEmpty
        if !isAutomatedRun && (!completed || awaitingRelaunch) {
            self.showOnboarding = true
        }
        AppState.shared = self
    }

    /// 重新唤起首次安装与权限引导向导
    func presentOnboarding(resetRelaunchFlag: Bool = true) {
        if resetRelaunchFlag {
            UserDefaults.standard.set(false, forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch)
        }
        showSettings = false
        showOnboarding = true
    }

    /// 完成首次安装向导（可选立即触发首次智能垃圾扫描）
    func completeOnboarding(startFirstScan: Bool = false) {
        UserDefaults.standard.set(true, forKey: AppConfig.StorageKeys.onboardingCompleted)
        UserDefaults.standard.set(false, forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch)
        showOnboarding = false
        checkFullDiskAccess(force: true)
        PermissionCoordinator.shared.refreshStatus()
        if startFirstScan {
            open(.restore(.junk))
            didApplyDefaultsCurrentModule = false
            startScan(for: "junk", forceRestart: true)
        }
    }

    /// 打开偏好设置并直达指定选项卡（支持 appearance / menubar / scanning / schedule / permissions）
    func openSettings(tab: String = "appearance") {
        settingsSelectedTab = tab
        showSettings = true
        DispatchQueue.main.async {
            if let w = NSApp.windows.first(where: { $0.canBecomeMain && !($0 is NSPanel) }) {
                w.deminiaturize(nil)
                w.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @Published var largeFileThresholdMB: Int = AppConfigStore.shared.largeFileThresholdMB {
        didSet {
            guard largeFileThresholdMB != oldValue else { return }
            AppConfigStore.shared.largeFileThresholdMB = largeFileThresholdMB
            if isScanning(module: "organize") {
                startScan(for: "organize", forceRestart: true)
            }
        }
    }
    @Published var oldFileMonths: Int = AppConfigStore.shared.oldFileMonths {
        didSet {
            guard oldFileMonths != oldValue else { return }
            AppConfigStore.shared.oldFileMonths = oldFileMonths
            if isScanning(module: "organize") {
                startScan(for: "organize", forceRestart: true)
            }
        }
    }

    var appliedLargeFileThresholdMB: Int {
        moduleSessions[.organize]?.scannedLargeFileThresholdMB ?? largeFileThresholdMB
    }

    var appliedOldFileMonths: Int {
        moduleSessions[.organize]?.scannedOldFileMonths ?? oldFileMonths
    }
    @Published var hasFullDiskAccess: Bool = false
    private var lastFDACheckUptime: TimeInterval = 0

    func checkFullDiskAccess(force: Bool = false) {
        let now = ProcessInfo.processInfo.systemUptime
        if !force && lastFDACheckUptime > 0 && (now - lastFDACheckUptime) < 10.0 {
            return
        }
        lastFDACheckUptime = now
        DispatchQueue.global(qos: .userInitiated).async {
            let access = FullDiskAccessManager.shared.hasFullDiskAccess
            DispatchQueue.main.async { [self] in
                if self.hasFullDiskAccess != access {
                    self.hasFullDiskAccess = access
                }
            }
        }
    }

    var isSidebarCollapsed: Bool {
        get {
            sidebarCollapsedOverride ?? false
        }
        set {
            sidebarCollapsedOverride = newValue
        }
    }

    func toggleSidebar() {
        sidebarCollapsedOverride = !isSidebarCollapsed
    }

    // MARK: 树与选择
    @Published var roots: [Node] = []
    @Published var selection: Set<UUID> = []
    @Published private(set) var cleaningProfileState = CleaningProfileState()
    var cleaningProfile: CleaningProfile { cleaningProfileState.primary }
    var selectedProfiles: Set<CleaningProfile> { cleaningProfileState.profiles }
    @Published var expanded: Set<UUID> = []
    @Published var ignored: Set<UUID> = []
    @Published var ignoredNames: [String] = []
    /// 被忽略项的原始子树快照（「放回原处」时直接插回树，不重扫）
    var ignoredSubtrees: [Node] = []
    /// 忽略路径，按规范化路径持久化并与 AppConfigStore 同步
    @Published var ignoredPaths: Set<String> = AppConfigStore.shared.currentIgnoredPathsSnapshot()

    /// 待二次确认的清理弹窗模型
    struct DangerClean {
        var message: String
        var targets: [CleanTarget]
        var module: String
    }
    @Published var dangerConfirm: DangerClean?

    // MARK: DataManager 状态
    @Published var category: String = ""
    @Published var search: String = ""
    @Published var sortKey: SortKey = .size
    @Published var sortAscending: Bool = false
    @Published var strategy: SelectStrategy = .smart
    @Published var focusGroup: UUID?
    @Published var showInfo = false
    @Published var infoNode: Node?
    @Published var showIgnoredBanner = false

    // MARK: 流程状态
    @Published var scanning = false
    @Published var isStoppingScan = false
    @Published var scanProgress: Double = 0
    @Published var scanStatus: String = ""
    /// 预计剩余秒数；nil 表示样本不足，界面不展示倒计时
    @Published var scanETA: TimeInterval? = nil
    @Published var scanPaths: [String] = []
    @Published var cleanProgress: Double = 0
    @Published var cleanCurrent: String = ""
    @Published var cleanDone = 0
    @Published var cleanTotal = 0
    @Published var report: CleanReport?
    @Published var log: [LogEntry] = []
    @Published private var _toast: String?
    /// 当前轻提示的语义类型，决定图标与强调色
    @Published private(set) var toastKind: ToastKind = .info
    /// 当前轻提示上挂载的动作（如「撤销」），无则为 nil
    @Published private(set) var toastAction: ToastAction?
    var toastToken = UUID()

    /// 兼容旧调用：直接赋值即弹出一条普通提示，停留时长取 `AppConfig.UI.toastDefaultDuration`。
    var toast: String? {
        get { _toast }
        set { showToast(newValue) }
    }

    /// 统一提示出口。所有模块都应优先走这里，避免各处自建提示导致位置/时长/样式不一致。
    /// - Parameters:
    ///   - text: 提示正文；传 nil 或空串即关闭当前提示
    ///   - kind: 语义类型，影响图标与强调色
    ///   - action: 可选的附加动作（如撤销）。挂载动作时自动延长停留时间。
    func showToast(_ text: String?, kind: ToastKind = .info, action: ToastAction? = nil) {
        _toast = text
        guard let text, !text.isEmpty else {
            toastAction = nil
            return
        }
        toastKind = kind
        toastAction = action
        let duration = action == nil
            ? AppConfig.UI.toastDefaultDuration
            : AppConfig.UI.toastActionDuration
        let token = UUID()
        toastToken = token
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self, self.toastToken == token else { return }
            self._toast = nil
            self.toastAction = nil
        }
    }

    /// 扫描/清理的中断标记（可跨线程）
    let stopFlag = StopFlag()
    /// 扫描完成后要自动应用的分类（从「我的工具」进入时使用）
    @Published var pendingCategory: String = ""
    /// 调试用：扫描完成后要跳到的屏幕（截图验证用）
    var debugStage: String = ""

    // MARK: 空间透镜专用
    enum SpaceLensMode: String {
        case bubble
        case list
    }
    @Published var spaceLensMode: SpaceLensMode = .bubble
    @Published var folderBreakdown: [LargeFile] = []
    @Published var spaceFiles: [LargeFile] = []

    // MARK: 性能专用
    @Published var memory: (total: Int64, used: Int64, pressure: String) = (0, 0, "—")
    @Published var cpuLoad: Double = 0
    @Published var startupItems: [StartupItem] = []
    @Published var maintenanceRuns: [String: String] = [:]

    // MARK: 整理杂乱专用
    @Published var downloads: [DownloadEntry] = []

    // MARK: 智能呵护专用
    @Published var smartCards: [String: SmartCardState] = [:]
    var smartQueue: [String] = []

    var spec: ModuleSpec { ModuleRegistry.spec(for: moduleKey.rawValue) }

    // ============================================================
    // MARK: 派生
    // ============================================================

    static func isAllCategory(_ cat: String) -> Bool {
        cat.isEmpty || cat == "All" || cat == "All Junk" || cat == L10n.localized(.filterAll) || cat == L10n.localized(.filterAllJunk) || cat == L10n.localized(.allJunk)
    }

    static func isSelectedCategory(_ cat: String) -> Bool {
        cat == "Selected" || cat == L10n.localized(.filterSelected) || cat == L10n.localized(.selected)
    }

    /// 当前分类 + 搜索过滤后的根节点
    var visibleRoots: [Node] {
        var r = roots
        if !Self.isAllCategory(category) {
            if Self.isSelectedCategory(category) {
                r = r.filter { isSelected($0) || (moduleKey == "applications" && partial($0)) }
            } else {
                r = r.filter { $0.tags.contains(category) }
            }
        }
        if !search.isEmpty {
            let q = search.lowercased()
            r = r.compactMap { filterNode($0, q) }
        }
        return sorted(r)
    }

    func filterNode(_ n: Node, _ q: String) -> Node? {
        if n.name.lowercased().contains(q) || n.path.lowercased().contains(q) { return n }
        var copy = n
        copy.children = n.children.compactMap { filterNode($0, q) }
        return copy.children.isEmpty ? nil : copy
    }

    func sorted(_ list: [Node]) -> [Node] {
        var dates: [UUID: Date] = [:]
        if sortKey == .date {
            for n in list { dates[n.id] = nodeDate(n) }
        } else if sortKey == .installDate {
            for n in list { dates[n.id] = nodeInstallDate(n) }
        }
        return list.sorted { a, b in
            let cmp: ComparisonResult
            switch sortKey {
            case .name:
                cmp = a.name.localizedStandardCompare(b.name)
            case .size:
                cmp = a.totalSize == b.totalSize ? .orderedSame : (a.totalSize < b.totalSize ? .orderedAscending : .orderedDescending)
            case .date, .installDate:
                let da = dates[a.id] ?? .distantPast
                let db = dates[b.id] ?? .distantPast
                cmp = da == db ? .orderedSame : (da < db ? .orderedAscending : .orderedDescending)
            }
            if cmp != .orderedSame {
                return sortAscending ? (cmp == .orderedAscending) : (cmp == .orderedDescending)
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

    func nodeDate(_ n: Node) -> Date {
        if let d = n.date { return d }
        var latest = fileDate(n) ?? .distantPast
        for c in n.children {
            let d = c.isGroup ? nodeDate(c) : (fileDate(c) ?? .distantPast)
            if d > latest { latest = d }
        }
        return latest
    }

    func nodeInstallDate(_ n: Node) -> Date {
        n.installDate ?? n.date ?? .distantPast
    }

    func fileDate(_ n: Node) -> Date? { n.date }

    var detailNodes: [Node] {
        if let f = focusGroup, let g = visibleRoots.firstNode(id: f) { return g.children }
        if let first = visibleRoots.first { return first.children }
        return []
    }

    var detailGroup: Node? {
        if let f = focusGroup, let g = visibleRoots.firstNode(id: f) { return g }
        return visibleRoots.first
    }

    var allLeaves: [Node] { roots.allLeaves }

    /// 支持叶子节点勾选及文件夹节点直接勾选（例如空间透视中直接勾选整个目录）
    var selectedLeaves: [Node] {
        guard !selection.isEmpty else { return [] }
        var out: [Node] = []
        func collect(_ nodes: [Node]) {
            for n in nodes {
                if selection.contains(n.id) && (n.url != nil || !n.isGroup) {
                    out.append(n)
                } else if !n.children.isEmpty {
                    collect(n.children)
                }
            }
        }
        collect(roots)
        return out
    }

    var selectedRoots: [Node] {
        guard !selection.isEmpty else { return [] }
        return roots.filter { isSelected($0) || (moduleKey == "applications" && partial($0)) }
    }

    var selectedSize: Int64 {
        guard !selection.isEmpty else { return 0 }
        return selectedLeaves.reduce(0) { $0 + $1.totalSize }
    }
    var selectedCount: Int {
        guard !selection.isEmpty else { return 0 }
        return selectedLeaves.count
    }
    var totalSize: Int64 { roots.reduce(0) { $0 + $1.totalSize } }
    var totalCount: Int { roots.reduce(0) { $0 + $1.leafCount } }

    var hasIncompleteScanCoverage: Bool {
        guard let session = moduleSessions[moduleKey], session.hasScanned, !session.scanning else { return false }
        return !session.completedSuccessfully
    }

    var scanDegradations: [ScanDegradationReason] {
        moduleSessions[moduleKey]?.scanDegradations ?? []
    }

    var hasRuleDatabaseDegradation: Bool {
        scanDegradations.contains(.ruleDatabaseUnavailable)
    }

    /// 仅当已完成扫描、无任何规则库降级或覆盖不完整、且结果为空时才允许展示绿色“干净/无垃圾”空态
    var canPresentSpotlessEmptyState: Bool {
        guard hasScannedCurrentModule || hasOptimizedCurrentModule else { return false }
        return roots.isEmpty && !hasRuleDatabaseDegradation && !hasIncompleteScanCoverage
    }

    var activeScanDegradationBanner: String? {
        guard !scanning && report == nil else { return nil }
        if hasRuleDatabaseDegradation {
            return L10n.localized(.ruleDatabaseUnavailableBanner)
        }
        if hasIncompleteScanCoverage {
            return L10n.localized(.scanCoverageIncomplete)
        }
        return nil
    }

    var hasResults: Bool { !roots.isEmpty && totalCount > 0 }

    var categories: [DataCategory] {
        var list: [DataCategory] = []
        var seen = Set<String>()
        for t in spec.filterOrder where !seen.contains(t) {
            seen.insert(t)
            list.append(DataCategory(t, spec.filterIcons[t] ?? "square.grid.2x2"))
        }
        for r in roots {
            for t in r.tags where !seen.contains(t) {
                seen.insert(t)
                list.append(DataCategory(t, r.icon))
            }
        }
        return list
    }

    // ============================================================
    // MARK: 选择与方案联动
    // ============================================================

    /// Profile metadata belongs to this module session, never the presentation cache.
    func markCustomSelection() {
        let custom = CleaningProfileState(profile: .custom)
        if cleaningProfileState != custom { cleaningProfileState = custom }
    }

    func setCleaningProfile(_ profile: CleaningProfile, selectedProfiles: Set<CleaningProfile>? = nil) {
        let next = CleaningProfileState(profile: profile, profiles: selectedProfiles)
        if cleaningProfileState != next { cleaningProfileState = next }
    }

    /// Callers provide IDs from the captured selectable scope; execution still revalidates.
    func setManualSelection(_ ids: Set<UUID>) {
        selection = ids
        didApplyDefaultsCurrentModule = true
        markCustomSelection()
    }


}
