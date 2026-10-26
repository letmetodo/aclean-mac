import Foundation
import Combine

// ============================================================
//  Localization (L10n) —— 10 国语言工业级国际化引擎
//
//  核心规范：
//    1. 原生支持 10 门主流语言 (zh-Hans, zh-Hant, en, ja, ko, fr, de, es, it, pt-BR) + 跟随系统 (system)；
//    2. 全量采用强类型英文常量枚举 (L10nKey)，彻底消除中文字符串作为键名；
//    3. 运行时零重启热切换：SwiftUI 视图通过 @ObservedObject 自动重绘；
//    4. 线程安全 (Sendable)：后台引擎与主线程 UI 均可安全调用；
//    5. 展示文本与业务逻辑彻底解耦。
// ============================================================

enum AppLanguage: String, CaseIterable, Codable, Identifiable, Sendable {
    case zhHans = "zh-Hans"
    case zhHant = "zh-Hant"
    case en     = "en"
    case ja     = "ja"
    case ko     = "ko"
    case fr     = "fr"
    case de     = "de"
    case es     = "es"
    case it     = "it"
    case ptBR   = "pt-BR"
    case system = "system"

    var id: String { rawValue }

    /// 供用户界面展示的 10 门具体语言列表（不含 .system）
    static var concreteLanguages: [AppLanguage] {
        [.zhHans, .zhHant, .en, .ja, .ko, .fr, .de, .es, .it, .ptBR]
    }

    var displayName: String {
        switch self {
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .en:     return "English"
        case .ja:     return "日本語"
        case .ko:     return "한국어"
        case .fr:     return "Français"
        case .de:     return "Deutsch"
        case .es:     return "Español"
        case .it:     return "Italiano"
        case .ptBR:   return "Português (Brasil)"
        case .system: return L10n.localized(.followSystem)
        }
    }

    var shortBadge: String {
        switch resolved {
        case .zhHans: return "简"
        case .zhHant: return "繁"
        case .en:     return "EN"
        case .ja:     return "日"
        case .ko:     return "韓"
        case .fr:     return "FR"
        case .de:     return "DE"
        case .es:     return "ES"
        case .it:     return "IT"
        case .ptBR:   return "PT"
        case .system: return "简"
        }
    }

    /// 解析后的实际生效语言（始终返回 10 门具体语言之一）
    var resolved: AppLanguage {
        switch self {
        case .system:
            let preferred = Locale.preferredLanguages.first?.lowercased() ?? "zh-hans"
            if preferred.hasPrefix("zh-hant") || preferred.hasPrefix("zh-tw") || preferred.hasPrefix("zh-hk") {
                return .zhHant
            }
            if preferred.hasPrefix("zh") { return .zhHans }
            if preferred.hasPrefix("ja") { return .ja }
            if preferred.hasPrefix("ko") { return .ko }
            if preferred.hasPrefix("fr") { return .fr }
            if preferred.hasPrefix("de") { return .de }
            if preferred.hasPrefix("es") { return .es }
            if preferred.hasPrefix("it") { return .it }
            if preferred.hasPrefix("pt") { return .ptBR }
            return .en
        default:
            return self
        }
    }
}


/// 全局响应式多语言中心
final class L10n: ObservableObject, @unchecked Sendable {
    static let shared = L10n()
    static let storageKey = "cm.language"

    private let lock = NSLock()
    private var cachedLanguage: AppLanguage

    @Published var language: AppLanguage {
        didSet {
            lock.lock()
            cachedLanguage = language
            lock.unlock()
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppLanguage.system.rawValue
        let initial = AppLanguage(rawValue: saved) ?? .system
        self.cachedLanguage = initial
        self.language = initial
    }

    /// 线程安全读取当前设置语言
    var currentLanguage: AppLanguage {
        lock.lock()
        defer { lock.unlock() }
        return cachedLanguage
    }

    /// 当前实际生效语言（解析 .system 后）
    var effectiveLanguage: AppLanguage {
        currentLanguage.resolved
    }

    /// 当前实际生效语言对应的 Locale
    var currentLocale: Locale {
        Locale(identifier: effectiveLanguage.rawValue)
    }

    /// 线程安全判定当前是否处于英文环境
    static var isEnglish: Bool {
        shared.currentLanguage.resolved == .en
    }

    /// 线程安全判定当前是否为中文环境（简/繁）
    static var isChinese: Bool {
        let r = shared.currentLanguage.resolved
        return r == .zhHans || r == .zhHant
    }

    /// 线程安全设置语言（供设置页与测试调用）
    func setLanguage(_ lang: AppLanguage) {
        if Thread.isMainThread {
            self.language = lang
        } else {
            lock.lock()
            self.cachedLanguage = lang
            lock.unlock()
            UserDefaults.standard.set(lang.rawValue, forKey: Self.storageKey)
            DispatchQueue.main.async {
                self.language = lang
            }
        }
    }

    /// 按英文常量获取本地化文案（核心推荐标准调用）
    @inline(__always)
    static func localized(_ key: L10nKey) -> String {
        string(key)
    }

    @inline(__always)
    static func tr(_ key: L10nKey) -> String {
        string(key)
    }

    @inline(__always)
    static func string(_ key: L10nKey) -> String {
        LocalizationCatalog.text(for: key, lang: shared.effectiveLanguage)
    }

    /// 带参数格式化的本地化文案
    static func format(_ key: L10nKey, _ args: CVarArg...) -> String {
        let template = string(key)
        return String(format: template, arguments: args)
    }

    static func localized(_ key: L10nKey, _ args: CVarArg...) -> String {
        let template = string(key)
        return String(format: template, arguments: args)
    }


    // MARK: - 常用核心常量快捷属性
    static var followSystem: String { localized(.followSystem) }
    static var scan: String { localized(.actionScan) }
    static var rescan: String { localized(.actionRescan) }
    static var stop: String { localized(.actionStop) }
    static var clean: String { localized(.actionCleanNow) }
    static var cancel: String { localized(.actionCancel) }
    static var confirm: String { localized(.actionConfirm) }
    static var done: String { localized(.actionDone) }
    static var back: String { localized(.actionBack) }
}

@inline(__always)
func tr(_ key: L10nKey) -> String {
    L10n.string(key)
}

@inline(__always)
func tr(_ key: L10nKey, _ args: CVarArg...) -> String {
    let template = L10n.string(key)
    return String(format: template, arguments: args)
}


// MARK: - 清理原因代码 (Reason Code) 国际化与用户透明交互

public enum ReasonCode: String, CaseIterable, Sendable {
    case manualReview = "REASON_CODE_MANUAL_REVIEW"
    case browserCache              = "REASON_CODE_BROWSER_CACHE"
    case browserGpuCache           = "REASON_CODE_BROWSER_GPU_CACHE"
    case browserCodeCache          = "REASON_CODE_BROWSER_CODE_CACHE"
    case wechatV3Temp              = "REASON_CODE_WECHAT_V3_TEMP"
    case wechatV4Media             = "REASON_CODE_WECHAT_V4_MEDIA"
    case commAppCache              = "REASON_CODE_COMM_APP_CACHE"
    case telegramMediaCache        = "REASON_CODE_TELEGRAM_MEDIA_CACHE"
    case mailDownloads             = "REASON_CODE_MAIL_DOWNLOADS"
    case devDerivedData            = "REASON_CODE_DEV_DERIVED_DATA"
    case devDeviceSupport          = "REASON_CODE_DEV_DEVICE_SUPPORT"
    case devArchives               = "REASON_CODE_DEV_ARCHIVES"
    case devBuildCache             = "REASON_CODE_DEV_BUILD_CACHE"
    case pkgManagerCache           = "REASON_CODE_PKG_MANAGER_CACHE"
    case pkgManagerDownloadCache   = "REASON_CODE_PKG_MANAGER_DOWNLOAD_CACHE"
    case aiModelWeights            = "REASON_CODE_AI_MODEL_WEIGHTS"
    case aiToolCache               = "REASON_CODE_AI_TOOL_CACHE"
    case officeAppCache            = "REASON_CODE_OFFICE_APP_CACHE"
    case mediaRenderCache          = "REASON_CODE_MEDIA_RENDER_CACHE"
    case gameMediaCache            = "REASON_CODE_GAME_MEDIA_CACHE"
    case utilityCache              = "REASON_CODE_UTILITY_CACHE"
    case userTrashBin              = "REASON_CODE_USER_TRASH_BIN"
    case systemLogsAsl             = "REASON_CODE_SYSTEM_LOGS_ASL"
    case systemCrashReports        = "REASON_CODE_SYSTEM_CRASH_REPORTS"
    case systemTempFiles           = "REASON_CODE_SYSTEM_TEMP_FILES"
    case systemCache               = "REASON_CODE_SYSTEM_CACHE"
    case whitelistProtected        = "REASON_CODE_WHITELIST_PROTECTED"
    case generalCache              = "REASON_CODE_GENERAL_CACHE"

    public var localizedExplanation: String {
        switch self {
        case .whitelistProtected, .mailDownloads: return L10n.localized(.cleanupProtectedReason)
        case .pkgManagerCache, .pkgManagerDownloadCache: return L10n.localized(.cleanupPackageReason)
        case .devDerivedData: return L10n.localized(.cleanupDerivedReason)
        case .systemLogsAsl, .systemCrashReports: return L10n.localized(.cleanupLogReason)
        case .browserCache, .browserGpuCache, .browserCodeCache, .generalCache: return L10n.localized(.cleanupCacheReason)
        default: return L10n.localized(.cleanupManualReview)
        }
    }
}
