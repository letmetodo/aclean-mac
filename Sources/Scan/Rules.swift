import Foundation

// ============================================================
//  Rules —— 安全等级与路径根(唯一保留的静态定义)
//
//  业务规则来自 Resources/cleanmate_authored_rules.sql，首次运行生成唯一数据库，
//  后续可通过验签的完整规则包更新，由 KnowledgeBaseManager 加载。
//
//  此处仅保留与数据无关的两类基础设施:
//        · Safety   —— 安全等级(UI 展示语义)
//        · RuleRoot —— 路径根枚举(各引擎拼装绝对路径用)
// ============================================================

// MARK: - 安全等级

public enum Safety: String, Sendable {
    case safe      = "safe"
    case caution   = "caution"
    case risky     = "risky"

    public var displayName: String {
        switch self {
        case .safe:    return L10n.localized(.safetySafe)
        case .caution: return L10n.localized(.safetyCaution)
        case .risky:   return L10n.localized(.safetyRisky)
        }
    }

    public var desc: String {
        switch self {
        case .safe:    return L10n.localized(.ruleSafeToCleanDesc)
        case .caution: return L10n.localized(.ruleCautionReLoginOrRebuildDesc)
        case .risky:   return L10n.localized(.ruleRiskyContainsUserDataDesc)
        }
    }
}

// MARK: - 路径根

enum RuleRoot: String {
    case home          = "~"
    case homeLibrary   = "~/Library"
    case rootLibrary   = "/Library"
    case systemLibrary = "/System/Library"
    case applications  = "/Applications"
    case userApps      = "~/Applications"
    case absolute      = ""

    var base: URL {
        let home = FileUtil.home
        switch self {
        case .home:          return home
        case .homeLibrary:   return home.appendingPathComponent("Library")
        case .rootLibrary:   return URL(fileURLWithPath: "/Library")
        case .systemLibrary: return URL(fileURLWithPath: "/System/Library")
        case .applications:  return URL(fileURLWithPath: "/Applications")
        case .userApps:      return home.appendingPathComponent("Applications")
        case .absolute:      return URL(fileURLWithPath: "/")
        }
    }
}
