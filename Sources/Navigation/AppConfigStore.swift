import Foundation
import AppKit
import Combine

// ============================================================
//  AppConfigStore —— 工业化统一配置与前缀感知白名单中心
//
//  职责：
//    1. 统一收敛分散在各处的 UserDefaults 配置键，提供类型安全、范围校验的读写能力；
//    2. 提供线程安全的前缀感知白名单校验 (isPathIgnored)，支持父目录自动保护所有子目录与文件；
//    3. 支持配置 JSON 一键导出、导入与恢复出厂默认设置；
//    4. 驱动多语言、删除前二次确认、完成提示音效与状态栏常驻实时生效。
// ============================================================

// ============================================================
//  外观模式与预设主题色配色方案
// ============================================================

enum AppAppearanceMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case system = "system"
    case dark   = "dark"
    case light  = "light"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return L10n.localized(.followSystem)
        case .dark:   return L10n.localized(.darkMode)
        case .light:  return L10n.localized(.lightMode)
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .dark:   return "moon.stars.fill"
        case .light:  return "sun.max.fill"
        }
    }

    var icon: String { iconName }



    /// 解析当前实际生效的深浅色状态
    var isEffectiveDark: Bool {
        isEffectiveDark(for: nil)
    }

    /// 结合指定的 AppKit Appearance 解析当前实际生效的深浅色状态
    func isEffectiveDark(for appearance: NSAppearance?) -> Bool {
        switch self {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            let target = appearance ?? NSAppearance.currentDrawing()
            if let match = target.bestMatch(from: [NSAppearance.Name.darkAqua, NSAppearance.Name.aqua]) {
                return match == .darkAqua
            }
            let globalStyle = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? ""
            return globalStyle.lowercased().contains("dark")
        }
    }
}

enum AppThemePreset: String, CaseIterable, Identifiable, Codable, Sendable {
    case oceanBlue     = "oceanBlue"
    case violetNebula  = "violetNebula"
    case roseQuartz    = "roseQuartz"
    case warmAmber     = "warmAmber"
    case emeraldForest = "emeraldForest"
    case graphiteMono  = "graphiteMono"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .oceanBlue:     return L10n.localized(.themeOceanBlue)
        case .violetNebula:  return L10n.localized(.themeVioletNebula)
        case .roseQuartz:    return L10n.localized(.themeRoseQuartz)
        case .warmAmber:     return L10n.localized(.themeWarmAmber)
        case .emeraldForest: return L10n.localized(.themeEmeraldForest)
        case .graphiteMono:  return L10n.localized(.themeGraphiteMono)
        }
    }

    var subtitle: String {
        switch self {
        case .oceanBlue:     return "#007AFF · Blue"
        case .violetNebula:  return "#5856D6 · Indigo"
        case .roseQuartz:    return "#FF2D55 · Pink"
        case .warmAmber:     return "#FF9500 · Amber"
        case .emeraldForest: return "#34C759 · Green"
        case .graphiteMono:  return "#8E8E93 · Graphite"
        }
    }

    /// 主强调色 RGB（对齐 Apple HIG System Colors，深浅色自适应高对比度）
    func primaryRGB(isDark: Bool) -> (r: Double, g: Double, b: Double) {
        switch self {
        case .oceanBlue:
            // Apple System Blue (#0A84FF Dark / #007AFF Light)
            return isDark ? (0.039, 0.518, 1.000) : (0.000, 0.478, 1.000)
        case .violetNebula:
            // Apple System Indigo (#5E5CE6 Dark / #5856D6 Light)
            return isDark ? (0.369, 0.361, 0.902) : (0.345, 0.337, 0.839)
        case .roseQuartz:
            // Apple System Pink (#FF375F Dark / #FF2D55 Light)
            return isDark ? (1.000, 0.216, 0.373) : (1.000, 0.176, 0.333)
        case .warmAmber:
            // Apple System Orange (#FF9F0A Dark / #FF9500 Light)
            return isDark ? (1.000, 0.624, 0.039) : (0.940, 0.520, 0.000)
        case .emeraldForest:
            // Apple System Green (#30D158 Dark / #28B446 Light)
            return isDark ? (0.188, 0.820, 0.345) : (0.157, 0.706, 0.275)
        case .graphiteMono:
            // Apple System Graphite (#98989D Dark / #6E6E73 Light)
            return isDark ? (0.596, 0.596, 0.616) : (0.431, 0.431, 0.451)
        }
    }

    /// 辅助强调色 RGB
    func secondaryRGB(isDark: Bool) -> (r: Double, g: Double, b: Double) {
        switch self {
        case .oceanBlue:
            return isDark ? (0.180, 0.600, 1.000) : (0.000, 0.400, 0.900)
        case .violetNebula:
            return isDark ? (0.460, 0.440, 0.960) : (0.280, 0.270, 0.760)
        case .roseQuartz:
            return isDark ? (1.000, 0.340, 0.480) : (0.880, 0.140, 0.280)
        case .warmAmber:
            return isDark ? (1.000, 0.700, 0.180) : (0.860, 0.440, 0.000)
        case .emeraldForest:
            return isDark ? (0.240, 0.860, 0.420) : (0.120, 0.600, 0.220)
        case .graphiteMono:
            return isDark ? (0.680, 0.680, 0.700) : (0.350, 0.350, 0.370)
        }
    }

    /// 画布主背景 RGB（Apple macOS 纯净中性底色：深色 #1C1C1E，浅色 #F5F5F7，彻底去除杂色染色）
    func canvasRGB(isDark: Bool) -> (r: Double, g: Double, b: Double) {
        return isDark ? (0.110, 0.110, 0.118) : (0.961, 0.961, 0.969)
    }

    /// 侧栏背景 RGB（配合 NSVisualEffectView(.sidebar) 的纯净中性底衬）
    func sidebarRGB(isDark: Bool) -> (r: Double, g: Double, b: Double) {
        return isDark ? (0.141, 0.141, 0.153) : (0.929, 0.929, 0.941)
    }

    /// 卡片表面 RGB（Apple 分组卡片表面：深色 #28282B，浅色纯白 #FFFFFF）
    func cardRGB(isDark: Bool) -> (r: Double, g: Double, b: Double) {
        return isDark ? (0.157, 0.157, 0.169) : (1.0, 1.0, 1.0)
    }

    /// 极光/色相角度
    var hue: Double {
        switch self {
        case .oceanBlue:     return 211
        case .violetNebula:  return 241
        case .roseQuartz:    return 348
        case .warmAmber:     return 35
        case .emeraldForest: return 135
        case .graphiteMono:  return 220
        }
    }
}

struct ExportableAppConfig: Codable, Equatable, Sendable {
    var version: Int = 3
    var language: AppLanguage
    var appearanceMode: AppAppearanceMode = .system
    var themePreset: AppThemePreset = .oceanBlue
    var largeFileThresholdMB: Int
    var oldFileMonths: Int
    var confirmBeforeDelete: Bool
    var soundEffects: Bool
    var menuBarMonitor: Bool
    var ignoredPaths: [String]

    enum CodingKeys: String, CodingKey {
        case version, language, appearanceMode, themePreset
        case largeFileThresholdMB, oldFileMonths, confirmBeforeDelete
        case soundEffects, menuBarMonitor, ignoredPaths
    }

    init(
        version: Int = 3,
        language: AppLanguage,
        appearanceMode: AppAppearanceMode = .system,
        themePreset: AppThemePreset = .oceanBlue,
        largeFileThresholdMB: Int,
        oldFileMonths: Int,
        confirmBeforeDelete: Bool,
        soundEffects: Bool,
        menuBarMonitor: Bool,
        ignoredPaths: [String]
    ) {
        self.version = version
        self.language = language
        self.appearanceMode = appearanceMode
        self.themePreset = themePreset
        self.largeFileThresholdMB = largeFileThresholdMB
        self.oldFileMonths = oldFileMonths
        self.confirmBeforeDelete = confirmBeforeDelete
        self.soundEffects = soundEffects
        self.menuBarMonitor = menuBarMonitor
        self.ignoredPaths = ignoredPaths
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 2
        language = try c.decode(AppLanguage.self, forKey: .language)
        appearanceMode = try c.decodeIfPresent(AppAppearanceMode.self, forKey: .appearanceMode) ?? .system
        themePreset = try c.decodeIfPresent(AppThemePreset.self, forKey: .themePreset) ?? .oceanBlue
        largeFileThresholdMB = try c.decode(Int.self, forKey: .largeFileThresholdMB)
        oldFileMonths = try c.decode(Int.self, forKey: .oldFileMonths)
        confirmBeforeDelete = try c.decode(Bool.self, forKey: .confirmBeforeDelete)
        soundEffects = try c.decode(Bool.self, forKey: .soundEffects)
        menuBarMonitor = try c.decode(Bool.self, forKey: .menuBarMonitor)
        ignoredPaths = try c.decode([String].self, forKey: .ignoredPaths)
    }
}

final class AppConfigStore: ObservableObject, @unchecked Sendable {
    static let shared = AppConfigStore()

    // MARK: - 标准持久化 Key (统一采用 aclean.* 规范)
    enum Keys {
        static var language: String             { AppConfig.StorageKeys.language }
        static var appearanceMode: String       { AppConfig.StorageKeys.appearanceMode }
        static var themePreset: String          { AppConfig.StorageKeys.themePreset }
        static var largeFileThresholdMB: String { AppConfig.StorageKeys.largeFileThresholdMB }
        static var oldFileMonths: String        { AppConfig.StorageKeys.oldFileMonths }
        static var ignoredPaths: String         { AppConfig.StorageKeys.ignoredPaths }
        static var menuBarMonitor: String       { AppConfig.StorageKeys.menuBarMonitor }
        static var confirmBeforeDelete: String  { AppConfig.StorageKeys.confirmBeforeDelete }
        static var soundEffects: String         { AppConfig.StorageKeys.soundEffects }
        static var notifyOnCompletion: String   { AppConfig.StorageKeys.notifyOnCompletion }
    }

    private let lock = NSLock()
    private let defaults = UserDefaults.standard

    // MARK: - 内部线程安全镜像
    private var cachedAppearanceMode: AppAppearanceMode
    private var cachedThemePreset: AppThemePreset
    private var cachedLargeFileThresholdMB: Int
    private var cachedOldFileMonths: Int
    private var cachedConfirmBeforeDelete: Bool
    private var cachedSoundEffects: Bool
    private var cachedMenuBarMonitor: Bool
    private var cachedIgnoredPaths: Set<String>
    private var lastDefaultsSyncTime: TimeInterval = 0

    // MARK: - SwiftUI 响应式属性

    @Published var language: AppLanguage {
        didSet {
            L10n.shared.setLanguage(language)
        }
    }

    @Published var appearanceMode: AppAppearanceMode {
        willSet {
            lock.lock()
            cachedAppearanceMode = newValue
            lock.unlock()
        }
        didSet {
            lock.lock()
            cachedAppearanceMode = appearanceMode
            lock.unlock()
            defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
            applyWindowAppearance()
        }
    }

    @Published var themePreset: AppThemePreset {
        willSet {
            lock.lock()
            cachedThemePreset = newValue
            lock.unlock()
        }
        didSet {
            lock.lock()
            cachedThemePreset = themePreset
            lock.unlock()
            defaults.set(themePreset.rawValue, forKey: Keys.themePreset)
        }
    }

    @Published var largeFileThresholdMB: Int {
        didSet {
            let clamped = max(AppConfig.Defaults.minLargeFileThresholdMB, min(AppConfig.Defaults.maxLargeFileThresholdMB, largeFileThresholdMB))
            if clamped != largeFileThresholdMB {
                largeFileThresholdMB = clamped
            }
            lock.lock()
            cachedLargeFileThresholdMB = clamped
            lock.unlock()
            defaults.set(clamped, forKey: Keys.largeFileThresholdMB)
        }
    }

    @Published var oldFileMonths: Int {
        didSet {
            let clamped = max(AppConfig.Defaults.minOldFileMonths, min(AppConfig.Defaults.maxOldFileMonths, oldFileMonths))
            if clamped != oldFileMonths {
                oldFileMonths = clamped
            }
            lock.lock()
            cachedOldFileMonths = clamped
            lock.unlock()
            defaults.set(clamped, forKey: Keys.oldFileMonths)
        }
    }

    @Published var confirmBeforeDelete: Bool {
        didSet {
            lock.lock()
            cachedConfirmBeforeDelete = confirmBeforeDelete
            lock.unlock()
            defaults.set(confirmBeforeDelete, forKey: Keys.confirmBeforeDelete)
        }
    }

    @Published var soundEffects: Bool {
        didSet {
            lock.lock()
            cachedSoundEffects = soundEffects
            lock.unlock()
            defaults.set(soundEffects, forKey: Keys.soundEffects)
        }
    }

    /// 长任务（扫描 / 清理）完成时发系统通知。
    /// 刻意不纳入 ExportableAppConfig：通知授权属于设备级设置，不应随配置迁移到其他机器。
    @Published var notifyOnCompletion: Bool {
        didSet { defaults.set(notifyOnCompletion, forKey: Keys.notifyOnCompletion) }
    }

    /// 已经看过引导提示条的模块键。
    /// 用于「分模块渐进式引导」：Onboarding 只讲三件事，其余每个模块首次进入时
    /// 给一条可关闭的提示，看完不再打扰。
    @Published var seenModuleTips: [String] = [] {
        didSet { defaults.set(seenModuleTips, forKey: AppConfig.StorageKeys.seenModuleTips) }
    }

    func shouldShowModuleTip(_ moduleKey: String) -> Bool {
        !seenModuleTips.contains(moduleKey)
    }

    func markModuleTipSeen(_ moduleKey: String) {
        guard !seenModuleTips.contains(moduleKey) else { return }
        seenModuleTips.append(moduleKey)
    }

    @Published var menuBarMonitor: Bool {
        didSet {
            lock.lock()
            cachedMenuBarMonitor = menuBarMonitor
            lock.unlock()
            defaults.set(menuBarMonitor, forKey: Keys.menuBarMonitor)
        }
    }

    @Published private(set) var ignoredPaths: Set<String> {
        didSet {
            lock.lock()
            cachedIgnoredPaths = ignoredPaths
            lock.unlock()
            defaults.set(Array(ignoredPaths).sorted(), forKey: Keys.ignoredPaths)
        }
    }

    private init() {
        let savedLang = defaults.string(forKey: Keys.language)
            ?? defaults.string(forKey: "cm.language")
            ?? AppLanguage.system.rawValue
        let initLang = AppLanguage(rawValue: savedLang) ?? .system

        let savedAppearance = defaults.string(forKey: Keys.appearanceMode)
            ?? defaults.string(forKey: "cm.appearanceMode")
            ?? AppAppearanceMode.system.rawValue
        let initAppearance = AppAppearanceMode(rawValue: savedAppearance) ?? .system

        let savedPreset = defaults.string(forKey: Keys.themePreset)
            ?? defaults.string(forKey: "cm.themePreset")
            ?? AppThemePreset.oceanBlue.rawValue
        let initPreset = AppThemePreset(rawValue: savedPreset) ?? .oceanBlue

        let rawLarge = (defaults.object(forKey: Keys.largeFileThresholdMB) as? Int)
            ?? (defaults.object(forKey: "cm.largeFileThresholdMB") as? Int)
            ?? defaults.integer(forKey: Keys.largeFileThresholdMB)
        let initLarge = rawLarge > 0 ? max(AppConfig.Defaults.minLargeFileThresholdMB, min(AppConfig.Defaults.maxLargeFileThresholdMB, rawLarge)) : AppConfig.Defaults.largeFileThresholdMB

        let rawOld = (defaults.object(forKey: Keys.oldFileMonths) as? Int)
            ?? (defaults.object(forKey: "cm.oldFileMonths") as? Int)
            ?? defaults.integer(forKey: Keys.oldFileMonths)
        let initOld = rawOld > 0 ? max(AppConfig.Defaults.minOldFileMonths, min(AppConfig.Defaults.maxOldFileMonths, rawOld)) : AppConfig.Defaults.oldFileMonths

        let initConfirm = (defaults.object(forKey: Keys.confirmBeforeDelete) as? Bool)
            ?? (defaults.object(forKey: "cm.confirmBeforeDelete") as? Bool)
            ?? AppConfig.Defaults.confirmBeforeDelete
        let initSound = (defaults.object(forKey: Keys.soundEffects) as? Bool)
            ?? (defaults.object(forKey: "cm.soundEffects") as? Bool)
            ?? AppConfig.Defaults.soundEffects
        let initMenuBar = (defaults.object(forKey: Keys.menuBarMonitor) as? Bool)
            ?? (defaults.object(forKey: "cm.menuBarMonitor") as? Bool)
            ?? AppConfig.Defaults.menuBarMonitor

        let savedIgnored = defaults.stringArray(forKey: Keys.ignoredPaths)
            ?? defaults.stringArray(forKey: "cm.ignoredPaths")
            ?? []
        let canonicalSet = Set(savedIgnored.map { Self.canonicalPath($0) }.filter { !$0.isEmpty })

        self.cachedAppearanceMode = initAppearance
        self.cachedThemePreset = initPreset
        self.cachedLargeFileThresholdMB = initLarge
        self.cachedOldFileMonths = initOld
        self.cachedConfirmBeforeDelete = initConfirm
        self.cachedSoundEffects = initSound
        self.cachedMenuBarMonitor = initMenuBar
        self.cachedIgnoredPaths = canonicalSet

        self.language = initLang
        self.appearanceMode = initAppearance
        self.themePreset = initPreset
        self.largeFileThresholdMB = initLarge
        self.oldFileMonths = initOld
        self.confirmBeforeDelete = initConfirm
        self.soundEffects = initSound
        self.menuBarMonitor = initMenuBar
        self.ignoredPaths = canonicalSet
        self.notifyOnCompletion = (defaults.object(forKey: Keys.notifyOnCompletion) as? Bool)
            ?? AppConfig.Defaults.notifyOnCompletion
        self.seenModuleTips = defaults.stringArray(forKey: AppConfig.StorageKeys.seenModuleTips) ?? []
    }

    /// 线程安全读取当前外观模式与主题色预设
    var currentAppearanceMode: AppAppearanceMode {
        lock.lock()
        defer { lock.unlock() }
        return cachedAppearanceMode
    }

    var currentThemePreset: AppThemePreset {
        lock.lock()
        defer { lock.unlock() }
        return cachedThemePreset
    }

    var isEffectiveDark: Bool {
        currentAppearanceMode.isEffectiveDark
    }

    func isEffectiveDark(for appearance: NSAppearance?) -> Bool {
        currentAppearanceMode.isEffectiveDark(for: appearance)
    }

    func applyWindowAppearance() {
        let mode = currentAppearanceMode
        let applyBlock: @MainActor @Sendable () -> Void = {
            guard let app = NSApp else { return }
            let targetAppearance = NSAppearance(named: mode.isEffectiveDark ? .darkAqua : .aqua)
            app.appearance = targetAppearance
            let isSettingsOpen = AppState.shared?.showSettings ?? false
            for win in app.windows {
                win.appearance = targetAppearance
                win.titlebarAppearsTransparent = true
                win.titleVisibility = .hidden
                win.styleMask.insert(.fullSizeContentView)
                win.isMovableByWindowBackground = !isSettingsOpen
                win.sheets.forEach { $0.appearance = targetAppearance }
            }
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                applyBlock()
            }
        } else {
            DispatchQueue.main.async {
                applyBlock()
            }
        }
    }

    // MARK: - 路径规范化与前缀白名单引擎

    /// 规范化路径：展开 ~、标准化 .. 与冗余斜杠、去除末尾 /
    static func canonicalPath(_ rawPath: String) -> String {
        // Whitespace is a legal part of a filesystem name, including its final component.
        guard !rawPath.isEmpty else { return "" }
        let expanded = (rawPath as NSString).expandingTildeInPath
        var standardized = (expanded as NSString).standardizingPath
        while standardized.count > 1 && standardized.hasSuffix("/") {
            standardized.removeLast()
        }
        return standardized
    }

    private func currentSyncedIgnoredSet() -> Set<String> {
        let now = ProcessInfo.processInfo.systemUptime
        lock.lock()
        var currentSet = cachedIgnoredPaths
        let needSync = (now - lastDefaultsSyncTime) > 0.5
        if needSync { lastDefaultsSyncTime = now }
        lock.unlock()

        // 兼容直接写入 UserDefaults 的外部调用（节流同步，避免高频扫描循环内百万次读取 UserDefaults）
        if needSync, let diskList = defaults.stringArray(forKey: Keys.ignoredPaths), diskList.count != currentSet.count {
            let synced = Set(diskList.map { Self.canonicalPath($0) }.filter { !$0.isEmpty })
            lock.lock()
            cachedIgnoredPaths = synced
            currentSet = synced
            lock.unlock()
        }
        return currentSet
    }

    var ignorePolicyVersion: Int {
        let currentSet = currentSyncedIgnoredSet()
        guard !currentSet.isEmpty else { return 0 }
        var hasher = Hasher()
        for item in currentSet.sorted() {
            hasher.combine(item)
        }
        return hasher.finalize()
    }

    /// 判定目标是否被用户白名单忽略（仅自身与子项，用于扫描与 UI 展示过滤，防止祖先树被错误剥离）(F6)
    func isPathIgnoredForDisplay(_ rawPath: String) -> Bool {
        guard !rawPath.isEmpty else { return false }
        let currentSet = currentSyncedIgnoredSet()
        if currentSet.isEmpty { return false }

        let target = Self.canonicalPath(rawPath)
        guard !target.isEmpty else { return false }
        if currentSet.contains(target) { return true }

        for canonIgnored in currentSet {
            guard !canonIgnored.isEmpty, canonIgnored != "/" else { continue }
            // 目标等于忽略路径，或目标是被忽略路径的子目录
            if target == canonIgnored || target.hasPrefix(canonIgnored + "/") {
                return true
            }
        }
        return false
    }

    /// 判定目标是否覆盖或命中白名单（双向重叠校验，用于删除计划与安全阻断）
    func isPathIgnoredForDeletion(_ rawPath: String) -> Bool {
        guard !rawPath.isEmpty else { return false }
        let currentSet = currentSyncedIgnoredSet()
        if currentSet.isEmpty { return false }

        let target = Self.canonicalPath(rawPath)
        guard !target.isEmpty else { return false }
        if currentSet.contains(target) { return true }

        for canonIgnored in currentSet {
            guard !canonIgnored.isEmpty, canonIgnored != "/" else { continue }
            // 1. 目标等于忽略路径，或目标是忽略路径的子目录
            if target == canonIgnored || target.hasPrefix(canonIgnored + "/") {
                return true
            }
            // 2. 目标是忽略路径的祖先目录（整体删除目标会导致被忽略的子目录被一并销毁，双向重叠防护）
            if canonIgnored.hasPrefix(target + "/") {
                return true
            }
        }
        return false
    }

    /// 线程安全检测某个路径是否处于用户排除白名单中（默认遵循删除安全级双向阻断）
    func isPathIgnored(_ rawPath: String) -> Bool {
        isPathIgnoredForDeletion(rawPath)
    }

    /// 添加路径至白名单（自动规范化）
    @discardableResult
    func addIgnoredPath(_ path: String) -> Bool {
        let canon = Self.canonicalPath(path)
        guard !canon.isEmpty, canon != "/" else { return false }
        var updated = currentIgnoredPathsSnapshot()
        let (inserted, _) = updated.insert(canon)
        updateIgnoredPaths(updated)
        return inserted
    }

    /// 从白名单移除路径（同时支持原路径与规范化路径）
    func removeIgnoredPath(_ path: String) {
        let canon = Self.canonicalPath(path)
        var updated = currentIgnoredPathsSnapshot()
        updated.remove(path)
        updated.remove(canon)
        updateIgnoredPaths(updated)
    }

    /// 批量替换白名单
    func setIgnoredPaths(_ paths: Set<String>) {
        let canonical = Set(paths.map { Self.canonicalPath($0) }.filter { !$0.isEmpty && $0 != "/" })
        updateIgnoredPaths(canonical)
    }

    /// 清空白名单
    func clearIgnoredPaths() {
        updateIgnoredPaths([])
    }

    func currentIgnoredPathsSnapshot() -> Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return cachedIgnoredPaths
    }

    private func updateIgnoredPaths(_ newSet: Set<String>) {
        lock.lock()
        cachedIgnoredPaths = newSet
        lock.unlock()
        defaults.set(Array(newSet).sorted(), forKey: Keys.ignoredPaths)
        if Thread.isMainThread {
            self.ignoredPaths = newSet
        } else {
            DispatchQueue.main.async {
                self.ignoredPaths = newSet
            }
        }
    }

    // MARK: - 线程安全阈值读取（供后台扫描器使用）

    var currentLargeFileThresholdBytes: Int64 {
        lock.lock()
        let mb = cachedLargeFileThresholdMB
        lock.unlock()
        return Int64(max(AppConfig.Defaults.minLargeFileThresholdMB, mb)) * 1024 * 1024
    }

    var currentOldFileMonths: Int {
        lock.lock()
        let months = cachedOldFileMonths
        lock.unlock()
        return max(AppConfig.Defaults.minOldFileMonths, min(AppConfig.Defaults.maxOldFileMonths, months))
    }

    var currentOldFileSeconds: TimeInterval {
        return Double(currentOldFileMonths) * 30.0 * 86400.0
    }

    var isSoundEffectsEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cachedSoundEffects
    }

    var isConfirmBeforeDeleteEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cachedConfirmBeforeDelete
    }

    // MARK: - 音效反馈

    func playCompletionSoundIfEnabled() {
        guard isSoundEffectsEnabled else { return }
        DispatchQueue.main.async {
            NSSound(named: NSSound.Name("Glass"))?.play()
        }
    }

    // MARK: - 配置导入 / 导出 / 恢复默认

    func exportConfig() -> ExportableAppConfig {
        lock.lock()
        let snapshot = ExportableAppConfig(
            language: L10n.shared.currentLanguage,
            appearanceMode: cachedAppearanceMode,
            themePreset: cachedThemePreset,
            largeFileThresholdMB: cachedLargeFileThresholdMB,
            oldFileMonths: cachedOldFileMonths,
            confirmBeforeDelete: cachedConfirmBeforeDelete,
            soundEffects: cachedSoundEffects,
            menuBarMonitor: cachedMenuBarMonitor,
            ignoredPaths: Array(cachedIgnoredPaths).sorted()
        )
        lock.unlock()
        return snapshot
    }

    func exportJSONData() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(exportConfig())
    }

    @discardableResult
    func importJSONData(_ data: Data) -> Bool {
        guard let decoded = try? JSONDecoder().decode(ExportableAppConfig.self, from: data) else {
            return false
        }
        applyConfig(decoded)
        return true
    }

    func applyConfig(_ cfg: ExportableAppConfig) {
        let clampedLarge = max(AppConfig.Defaults.minLargeFileThresholdMB, min(AppConfig.Defaults.maxLargeFileThresholdMB, cfg.largeFileThresholdMB))
        let clampedOld = max(AppConfig.Defaults.minOldFileMonths, min(AppConfig.Defaults.maxOldFileMonths, cfg.oldFileMonths))
        let canonicalIgnored = Set(cfg.ignoredPaths.map { Self.canonicalPath($0) }.filter { !$0.isEmpty && $0 != "/" })

        L10n.shared.setLanguage(cfg.language)
        lock.lock()
        cachedAppearanceMode = cfg.appearanceMode
        cachedThemePreset = cfg.themePreset
        cachedLargeFileThresholdMB = clampedLarge
        cachedOldFileMonths = clampedOld
        cachedConfirmBeforeDelete = cfg.confirmBeforeDelete
        cachedSoundEffects = cfg.soundEffects
        cachedMenuBarMonitor = cfg.menuBarMonitor
        cachedIgnoredPaths = canonicalIgnored
        lock.unlock()

        defaults.set(cfg.appearanceMode.rawValue, forKey: Keys.appearanceMode)
        defaults.set(cfg.themePreset.rawValue, forKey: Keys.themePreset)
        defaults.set(clampedLarge, forKey: Keys.largeFileThresholdMB)
        defaults.set(clampedOld, forKey: Keys.oldFileMonths)
        defaults.set(cfg.confirmBeforeDelete, forKey: Keys.confirmBeforeDelete)
        defaults.set(cfg.soundEffects, forKey: Keys.soundEffects)
        defaults.set(cfg.menuBarMonitor, forKey: Keys.menuBarMonitor)
        defaults.set(Array(canonicalIgnored).sorted(), forKey: Keys.ignoredPaths)
        applyWindowAppearance()

        let applyMain: @MainActor @Sendable () -> Void = {
            self.language = cfg.language
            self.appearanceMode = cfg.appearanceMode
            self.themePreset = cfg.themePreset
            self.largeFileThresholdMB = clampedLarge
            self.oldFileMonths = clampedOld
            self.confirmBeforeDelete = cfg.confirmBeforeDelete
            self.soundEffects = cfg.soundEffects
            self.menuBarMonitor = cfg.menuBarMonitor
            self.ignoredPaths = canonicalIgnored
        }
        if Thread.isMainThread {
            MainActor.assumeIsolated { applyMain() }
        } else {
            DispatchQueue.main.async(execute: applyMain)
        }
    }

    /// 恢复出厂默认配置（可选是否保留用户排除白名单）
    func resetToDefaults(keepIgnoredPaths: Bool = false) {
        let defaultCfg = ExportableAppConfig(
            language: .zhHans,
            appearanceMode: .system,
            themePreset: .oceanBlue,
            largeFileThresholdMB: AppConfig.Defaults.largeFileThresholdMB,
            oldFileMonths: AppConfig.Defaults.oldFileMonths,
            confirmBeforeDelete: AppConfig.Defaults.confirmBeforeDelete,
            soundEffects: AppConfig.Defaults.soundEffects,
            menuBarMonitor: AppConfig.Defaults.menuBarMonitor,
            ignoredPaths: keepIgnoredPaths ? Array(currentIgnoredPathsSnapshot()) : []
        )
        applyConfig(defaultCfg)
    }
}
