import Foundation
import Combine

/// 调度周期枚举
enum ScheduleInterval: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw.lowercased() {
        case "daily": self = .daily
        case "weekly": self = .weekly
        case "biweekly": self = .biweekly
        case "monthly": self = .monthly
        default:
            if raw == L10n.localized(.daily) { self = .daily }
            else if raw == L10n.localized(.weekly) { self = .weekly }
            else if raw == L10n.localized(.biweekly) { self = .biweekly }
            else if raw == L10n.localized(.monthly) { self = .monthly }
            else { self = .weekly }
        }
    }

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:    return L10n.localized(.daily)
        case .weekly:   return L10n.localized(.weekly)
        case .biweekly: return L10n.localized(.biweekly)
        case .monthly:  return L10n.localized(.monthly)
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .daily:    return 86400
        case .weekly:   return 604800
        case .biweekly: return 1209600
        case .monthly:  return 2592000
        }
    }
}

/// 定时扫描与清理配置
struct ScheduleConfig: Codable, Equatable {
    var isEnabled: Bool = false
    var interval: ScheduleInterval = .weekly
    var autoClean: Bool = false
    var notifyOnCompletion: Bool = true
    var minimumCleanSize: Int64 = AppConfig.Defaults.schedulerMinimumCleanSize
    var lastRunDate: Date? = nil
    var nextRunDate: Date? = nil

    var formattedLastRun: String {
        guard let date = lastRunDate else { return L10n.localized(.neverRun) }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var formattedNextRun: String {
        guard let date = nextRunDate else { return L10n.localized(.notConfigured) }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

/// 定时调度服务 (SchedulerService)
///
/// 具备双层调度能力：
/// 1. 前台常驻 60s 轮询 Timer，到期触发任务；
/// 2. 后台可选注册 LaunchAgent (com.cleanmate.scheduler.plist 带 --scheduled-scan)，
///    利用 macOS 系统 launchd 机制在系统后台维持定期自启扫描；
/// 3. 到期任务保留重试，两个触发入口共享互斥与持久化完成记录。
@MainActor
final class SchedulerService: ObservableObject {
    static let shared = SchedulerService()

    private(set) var authorizationGeneration = 0
    @Published var config: ScheduleConfig {
        didSet {
            if config.isEnabled != oldValue.isEnabled || config.autoClean != oldValue.autoClean { authorizationGeneration += 1 }
            saveConfig()
        }
    }

    private var triggerInFlight = false
    private var timer: Timer?
    private let defaults: UserDefaults
    private var configKey: String { AppConfig.Scheduling.storageKey }
    private var onTrigger: (() async -> Bool)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let rawData = defaults.data(forKey: AppConfig.Scheduling.storageKey)
            ?? defaults.data(forKey: AppConfig.Scheduling.legacyStorageKey)

        if let data = rawData,
           let saved = try? JSONDecoder().decode(ScheduleConfig.self, from: data) {
            // Retain overdue schedules; retry on the next eligible tick.
            self.config = saved
        } else {
            self.config = ScheduleConfig()
        }
    }

    /// 设置触发回调
    func setTrigger(_ handler: @escaping () async -> Bool) {
        self.onTrigger = handler
    }

    /// 启动前台轮询 Timer
    func start() {
        stop()
        guard config.isEnabled else { return }

        if config.nextRunDate == nil {
            updateNextRunDate()
        }

        timer = Timer.scheduledTimer(withTimeInterval: AppConfig.Scheduling.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAndRun()
            }
        }
    }

    /// 停止前台轮询
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// 更新调度周期
    func updateSchedule(interval: ScheduleInterval) {
        config.interval = interval
        updateNextRunDate()
        if config.isEnabled {
            start()
            if isLaunchAgentInstalled {
                _ = installLaunchAgent()
            }
        }
    }

    /// 开关定时调度
    func toggleEnabled(_ enabled: Bool) {
        config.isEnabled = enabled
        if enabled {
            updateNextRunDate()
            start()
        } else {
            stop()
        }
    }

    // MARK: - 内部执行逻辑

    private func checkAndRun() {
        Task { await triggerDueJob() }
    }

    /// LaunchAgent and foreground timer must acknowledge the same scheduled run.
    @discardableResult
    func triggerDueJob() async -> Bool {
        guard config.isEnabled,
              let nextRun = config.nextRunDate,
              Date() >= nextRun,
              !Task.isCancelled,
              !triggerInFlight else { return false }

        triggerInFlight = true
        let generation = authorizationGeneration
        defer { triggerInFlight = false }
        guard await onTrigger?() == true,
              !Task.isCancelled,
              config.isEnabled, generation == authorizationGeneration else { return false }
        var completed = config
        completed.lastRunDate = Date()
        completed.nextRunDate = completed.lastRunDate!.addingTimeInterval(completed.interval.seconds)
        config = completed
        return true
    }

    func updateNextRunDate() {
        let base = config.lastRunDate ?? Date()
        config.nextRunDate = base.addingTimeInterval(config.interval.seconds)
    }

    private func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: configKey)
        }
    }

    // MARK: - LaunchAgent 守护进程管理

    nonisolated static var launchAgentLabel: String { AppConfig.Paths.launchAgentLabel }

    nonisolated static var launchAgentFileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(launchAgentLabel).plist")
    }

    nonisolated static var isLaunchAgentInstalledNonisolated: Bool {
        FileManager.default.fileExists(atPath: launchAgentFileURL.path)
    }

    var launchAgentURL: URL {
        Self.launchAgentFileURL
    }

    var isLaunchAgentInstalled: Bool {
        Self.isLaunchAgentInstalledNonisolated
    }

    /// 生成 LaunchAgent plist 内容
    func generateLaunchAgentPlist(executablePath: String) -> String {
        let plist: [String: Any] = ["Label": Self.launchAgentLabel,
                                   "ProgramArguments": [executablePath, "--scheduled-scan"],
                                   "StartInterval": Int(config.interval.seconds), "RunAtLoad": false]
        guard let data = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0),
              let text = String(data: data, encoding: .utf8) else { return "" }
        return text
    }

    /// 注册 LaunchAgent
    @discardableResult
    func installLaunchAgent(customExecutable: String? = nil) -> Bool {
        start()
        let plistURL = launchAgentURL
        let dir = plistURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let appPath = customExecutable ?? Bundle.main.executablePath ?? "/Applications/AClean.app/Contents/MacOS/AClean"
        let plistContent = generateLaunchAgentPlist(executablePath: appPath)

        do {
            try plistContent.write(to: plistURL, atomically: true, encoding: .utf8)

            let uid = getuid()
            _ = Shell.execute("/bin/launchctl", ["bootout", "gui/\(uid)/\(Self.launchAgentLabel)"])
            let bootRes = Shell.execute("/bin/launchctl", ["bootstrap", "gui/\(uid)", plistURL.path])
            if bootRes.exitCode == 0 { return true }
            let loadRes = Shell.execute("/bin/launchctl", ["load", plistURL.path])
            return loadRes.exitCode == 0
        } catch {
            return false
        }
    }

    /// 卸载 LaunchAgent
    @discardableResult
    func uninstallLaunchAgent(
        shellExecutor: ((String, [String]) -> ShellResult)? = nil,
        fileRemover: ((URL) throws -> Void)? = nil
    ) -> Bool {
        stop()
        let plistURL = launchAgentURL
        let exec = shellExecutor ?? { bin, args in Shell.execute(bin, args) }
        let removeFile = fileRemover ?? { url in try FileManager.default.removeItem(at: url) }
        guard FileManager.default.fileExists(atPath: plistURL.path) else { return true }

        let uid = getuid()
        let label = Self.launchAgentLabel
        let bootoutRes = exec("/bin/launchctl", ["bootout", "gui/\(uid)", plistURL.path])
        let unloadRes = exec("/bin/launchctl", ["unload", plistURL.path])

        do {
            try removeFile(plistURL)
        } catch {
            return false
        }

        if FileManager.default.fileExists(atPath: plistURL.path) {
            return false
        }
        if !bootoutRes.isSuccess && !unloadRes.isSuccess {
            let printRes = exec("/bin/launchctl", ["print", "gui/\(uid)/\(label)"])
            if printRes.isSuccess {
                return false
            }
        }
        return true
    }
}
