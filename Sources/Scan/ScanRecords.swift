import Foundation
import SwiftUI

// ============================================================
//  Engine 层 DTO
//  这些类型是「扫描引擎」的原始输出，保持扁平、无 UI 依赖。
//  上层的 Node 树（Core/Node.swift）负责把它们组织成可交互的树。
// ============================================================

// MARK: - 清理动作

enum ItemAction: Equatable, Sendable {
    case trash                          // 移入废纸篓
    case emptyContainer                 // 受控清空保壳容器（1 次根级 lsof 复核 + 直接子项逐一移入废纸篓，保留外壳目录）
    case permanentlyDeleteTrashItem     // 物理清空废纸篓中经过严格核实的子项（专用永久删除，普通 .trash 严禁升级）
    case thinBinary(String)             // 【已封锁】用 lipo 移除多余架构
    case apfsPurge                      // APFS 可清除空间原生释放 (diskutil)
    case simctlRuntimeDelete(String)    // Xcode 模拟器运行时专用删除 (xcrun simctl)
    case simctlDeleteUnavailable        // Xcode 不可用模拟器设备容器清理 (xcrun simctl delete unavailable)
    case dockerPrune                    // Docker/OrbStack 虚拟容器释放 (docker system prune)
    case custom(String)                 // 由模块自行处理（例如 launchctl 启停）

    var label: String {
        switch self {
        case .trash, .emptyContainer:   return L10n.localized(.actionMoveToTrashAlt)
        case .permanentlyDeleteTrashItem: return L10n.localized(.actionRemoveNow)
        case .thinBinary:               return L10n.localized(.actionThinBinary)
        case .apfsPurge:                return L10n.localized(.actionReleasePurgeableSpace)
        case .simctlRuntimeDelete:       return L10n.localized(.actionDeleteSimulatorRuntime)
        case .simctlDeleteUnavailable:  return L10n.localized(.actionDeleteUnavailableSimulators)
        case .dockerPrune:              return L10n.localized(.actionCleanDockerCache)
        case .custom(let s):            return s
        }
    }

    static func == (l: ItemAction, r: ItemAction) -> Bool {
        switch (l, r) {
        case (.trash, .trash): return true
        case (.emptyContainer, .emptyContainer): return true
        case (.permanentlyDeleteTrashItem, .permanentlyDeleteTrashItem): return true
        case let (.thinBinary(a), .thinBinary(b)): return a == b
        case (.apfsPurge, .apfsPurge): return true
        case let (.simctlRuntimeDelete(a), .simctlRuntimeDelete(b)): return a == b
        case (.simctlDeleteUnavailable, .simctlDeleteUnavailable): return true
        case (.dockerPrune, .dockerPrune): return true
        case let (.custom(a), .custom(b)): return a == b
        default: return false
        }
    }
}

// MARK: - 清理授权上下文与扫描评估诊断

/// 清理目标的强类型业务授权来源（跨模块零退化契约）
enum CleanAuthorizationContext: String, Codable, Sendable, Equatable, Hashable {
    /// 垃圾清理 / AI 积压 / 孤儿残留：必须携带 ruleEvidence?.executable == true
    case junkRule
    /// 应用卸载本体与关联残留：必须携带有效的 uninstallContext
    case uninstall
    /// 废纸篓单项永久删除：action 必须为 .permanentlyDeleteTrashItem 且位于安全 Trash 根内
    case trashBin
    /// 空间整理（大文件/旧文件/重复文件/下载项/空间透镜）人工选择清理
    case organizeManual
    /// 系统维护原生动作（Docker / Simctl / APFS / 已知注册表 maint:<taskId>）
    case systemMaintenance

    static func infer(
        action: ItemAction,
        uninstallContext: UninstallContext? = nil,
        ruleEvidence: CleanupRuleEvidence? = nil,
        defaultFallback: CleanAuthorizationContext = .organizeManual
    ) -> CleanAuthorizationContext {
        if uninstallContext != nil {
            return .uninstall
        }
        if let evidence = ruleEvidence {
            return evidence.id.hasPrefix("UNINST_") ? .uninstall : .junkRule
        }
        switch action {
        case .permanentlyDeleteTrashItem:
            return .trashBin
        case .apfsPurge, .dockerPrune, .simctlRuntimeDelete, .simctlDeleteUnavailable, .custom:
            return .systemMaintenance
        case .thinBinary, .emptyContainer:
            return .junkRule
        case .trash:
            return defaultFallback
        }
    }
}

/// 清理执行模式：自动无人值守/未确认直通 vs 经用户显式确认的人工执行
enum CleanExecutionMode: String, Codable, Sendable, Equatable, Hashable {
    case automatic
    case manual
}

/// 扫描期系统级或容器级降级原因（防静默吞错）
enum ScanDegradationReason: String, Codable, Sendable, Equatable, Hashable {
    case ruleDatabaseUnavailable
    case containerEnumerationIncomplete
    case containerMutatedDuringScan
    case openFileInspectionFailed
}

/// 候选条目评估与锁定/降级原因（可审计结构化原因）
enum CandidateEvaluationReason: Sendable, Equatable, Hashable {
    case matchedExecutableRule
    case matchedReadOnlyOrForbiddenRule
    case ruleDatabaseUnavailable
    case noMatchingAuthoredRule
    case missingScanEntry(ruleId: String)
    case unimplementedPredicate(ruleId: String, predicate: String)
    case unknownOrNonTrashAction(ruleId: String, action: String)
    case descendantRuleConflict(path: String, descendantPath: String, ruleId: String)
    case containerSnapshotIncomplete(path: String, reason: String)
    case systemScopeHandleBlindSpot(path: String)
    case guardedByPolicy(guardName: String, detail: String)
    case protectedAssetBlocked
    case symlinkEscapeBlocked
    case runningProcessLocked
    case unsupportedDirectoryName(path: String)

    var localizedExplanation: String? {
        switch self {
        case .matchedExecutableRule:
            return nil
        case .matchedReadOnlyOrForbiddenRule:
            return ReasonCode.whitelistProtected.localizedExplanation
        case .ruleDatabaseUnavailable:
            return L10n.localized(.ruleDatabaseUnavailableTitle)
        case .noMatchingAuthoredRule:
            return L10n.localized(.cleanSkippedProtected)
        case .missingScanEntry(let ruleId):
            return "\(L10n.localized(.junkRuleCoverageUnavailable)) · \(ruleId)"
        case .unimplementedPredicate(let ruleId, let predicate):
            return "\(L10n.localized(.cleanSkippedProtected)) · \(ruleId) (\(predicate))"
        case .unknownOrNonTrashAction(let ruleId, let action):
            return "\(L10n.localized(.cleanSkippedProtected)) · \(ruleId) (\(action))"
        case .descendantRuleConflict(_, _, let ruleId):
            return "\(L10n.localized(.cleanSkippedProtected)) · \(ruleId)"
        case .containerSnapshotIncomplete(_, let reason):
            return "\(L10n.localized(.safetyInspectionIncomplete)) (\(reason))"
        case .systemScopeHandleBlindSpot:
            return L10n.localized(.safetyInspectionIncomplete)
        case .guardedByPolicy(_, let detail):
            return detail
        case .protectedAssetBlocked, .symlinkEscapeBlocked:
            return L10n.localized(.cleanSkippedProtected)
        case .runningProcessLocked:
            return L10n.localized(.statusAppRunningSkipped)
        case .unsupportedDirectoryName:
            return L10n.localized(.junkUnsupportedDirectoryName)
        }
    }

    var categoryKey: String {
        switch self {
        case .matchedExecutableRule: return "matchedExecutableRule"
        case .matchedReadOnlyOrForbiddenRule: return "matchedReadOnlyOrForbiddenRule"
        case .ruleDatabaseUnavailable: return "ruleDatabaseUnavailable"
        case .noMatchingAuthoredRule: return "noMatchingAuthoredRule"
        case .missingScanEntry: return "missingScanEntry"
        case .unimplementedPredicate: return "unimplementedPredicate"
        case .unknownOrNonTrashAction: return "unknownOrNonTrashAction"
        case .descendantRuleConflict: return "descendantRuleConflict"
        case .containerSnapshotIncomplete: return "containerSnapshotIncomplete"
        case .systemScopeHandleBlindSpot: return "systemScopeHandleBlindSpot"
        case .guardedByPolicy: return "guardedByPolicy"
        case .protectedAssetBlocked: return "protectedAssetBlocked"
        case .symlinkEscapeBlocked: return "symlinkEscapeBlocked"
        case .runningProcessLocked: return "runningProcessLocked"
        case .unsupportedDirectoryName: return "unsupportedDirectoryName"
        }
    }
}

/// 规则感知去重归并留痕记录（防候选静默消失）
struct DeduplicationRecord: Sendable, Equatable, Hashable {
    let droppedPath: String
    let droppedRuleId: String?
    let winnerPath: String
    let winnerRuleId: String?
    let reason: String
}

/// T09：默认选择限制集合（ScanItem / Node / CleanTarget 共享，转换与去重执行并集）
enum SelectionRestriction: String, Codable, Hashable, Sendable {
    case productPolicy, readOnlyAsset, largeCache, unknownImpact, scannerNotConnected
}

/// T12：缓存重建代价等级（严格四值）
enum RebuildCost: String, Codable, Hashable, Sendable, Comparable {
    case none, low, medium, high

    var rank: Int {
        switch self {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }

    static func < (lhs: RebuildCost, rhs: RebuildCost) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// T12：缓存分类（普通应用 vs 开发工具）
enum CacheClass: String, Codable, Hashable, Sendable {
    case app, developer
}

/// T12：清理后重建影响枚举
enum CacheRebuildEffect: String, Codable, Hashable, Sendable {
    case redownload
    case recompile
    case firstLaunch = "first_launch"

    var sortOrder: Int {
        switch self {
        case .redownload: return 0
        case .recompile: return 1
        case .firstLaunch: return 2
        }
    }
}

/// T12：缓存发现方式枚举
enum CacheDiscoveryKind: String, Codable, Hashable, Sendable {
    case exactRoot = "exact_root"
    case chromiumLeaves = "chromium_leaves"
    case electronLeaves = "electron_leaves"
    case firefoxLeaves = "firefox_leaves"
    case derivedChildren = "derived_children"
}

/// T12：缓存 Profile 运行锁类型枚举
enum CacheProfileLockKind: String, Codable, Hashable, Sendable {
    case bundleID = "bundle_id"
    case processName = "process_name"
    case processFamily = "process_family"
}

struct AuthoredCacheProfileLock: Codable, Hashable, Sendable {
    let profileID: String
    let lockKind: CacheProfileLockKind
    let lockValue: String
}

struct AuthoredCacheProfile: Codable, Hashable, Sendable {
    let id: String
    let ruleID: String
    let rootTemplate: String
    let discoveryKind: CacheDiscoveryKind
    let cacheClass: CacheClass
    let rebuildEffect: CacheRebuildEffect
    let costOverride: RebuildCost
}

struct CacheRecommendationConfig: Sendable, Equatable {
    let isAvailable: Bool
    let schemaVersion: String
    let policyVersion: String
    let appSuggestionBytes: Int64
    let developerSuggestionBytes: Int64
    let ageSuggestionEnabled: Bool
    let unavailableReason: String?

    static let unavailable = CacheRecommendationConfig(
        isAvailable: false,
        schemaVersion: "",
        policyVersion: "",
        appSuggestionBytes: 0,
        developerSuggestionBytes: 0,
        ageSuggestionEnabled: false,
        unavailableReason: "configuration_unavailable"
    )
}

enum CacheRecommendationState: String, Codable, Hashable, Sendable {
    case blocked, unknownReview, ordinary, suggestedLarge
}

enum CacheRecommendationReason: String, Codable, Hashable, Sendable {
    case thresholdReached, belowThreshold, profileMissing, profileRuleMismatch
    case unknownCost, configurationUnavailable, safetyGateFailed
}

struct CacheRecommendationSnapshot: Sendable, Equatable {
    let profileID: String?          // 没有 profile 时为 nil
    let ruleID: String?
    let ruleSQLHash: String
    let unitPath: String           // 实际缓存单元，不是伞目录/UI 分组
    let unitIdentity: FileIdentity? // 单元根身份；执行时重新捕获并核对
    let cacheClass: CacheClass?
    let allocatedBytes: Int64?
    let thresholdBytes: Int64?
    let effectiveCost: RebuildCost?
    let effects: Set<CacheRebuildEffect>
    let state: CacheRecommendationState
    let reasons: Set<CacheRecommendationReason>
    let automaticAllowed: Bool
    let policyVersion: String
}

struct InstalledApp: Identifiable, Hashable, Sendable {
    let id = UUID()
    var name: String
    var bundleID: String
    var url: URL
    var appSize: Int64 = 0
    var version: String = ""
    var lastOpened: Date? = nil
    var installDate: Date? = nil
    var source: String = "Other"          // App Store / Setapp / 其他
    /// 自动更新通道（本地检测）：App Store / Sparkle / ""（无）
    /// 说明：按 DNA「零网络」宪章，仅本地识别更新通道，不联网查询版本。
    var updateChannel: String = ""
    var is32Bit: Bool = false
    var isSuspicious: Bool = false
    var vendor: String = ""
    var leftovers: [ScanItem] = []
    var leftoversLoaded = false
    var icon: NSImage? = nil
    var isActiveNow: Bool = false

    var leftoverSize: Int64 { leftovers.reduce(0) { $0 + $1.size } }
    var totalSize: Int64 { appSize + leftoverSize }

    /// 超过 6 个月未打开（仅统计有真实 kMDItemLastUsedDate 的应用）
    ///
    /// 语义修正（P0-3）：
    ///   · 不再回落 contentAccessDate —— 该字段会被 Spotlight / 备份 / 同步任务刷新，
    ///     导致大量应用被误判为「已使用」；
    ///   · lastOpened == nil 表示「从未打开」，单独由 `neverOpened` 标记，
    ///     不计入「未使用」（与原版语义区分，杜绝凭空造数）。
    var isUnused: Bool {
        guard let d = lastOpened else { return false }
        return Date().timeIntervalSince(d) > 180 * 86400
    }

    /// 从未打开过（无 kMDItemLastUsedDate 记录）
    var neverOpened: Bool { lastOpened == nil }

    static func == (l: InstalledApp, r: InstalledApp) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

// MARK: - 大文件 / 目录占用

struct LargeFile: Identifiable {
    let id = UUID()
    var url: URL
    var size: Int64
    var lastAccess: Date? = nil
    var name: String { url.lastPathComponent }
    var isDirectory: Bool
}

// MARK: - 下载记录

struct DownloadEntry: Identifiable {
    let id = UUID()
    var app: String
    var icon: String
    var fileName: String
    var url: String
    var date: String
}

// MARK: - 启动项 / 后台项

struct StartupItem: Identifiable {
    var ruleIdentity = RuleTaskGate.shared.identity
    let id = UUID()
    var name: String
    var path: String
    var scope: String        // 用户 / 系统
    var program: String
    var broken: Bool
    var enabled: Bool
    /// 启用状态是否已被真实读取（P1-4）。
    /// false 表示 launchctl 不可读（沙箱 / 需 root），此时 enabled 为保守默认值，
    /// UI 应显示「状态未知」而非编造「已启用」。
    var stateKnown: Bool = true
    /// 登录项 or 后台项（LaunchAgent/LaunchDaemon）
    var isBackground: Bool = false
    var displayName: String = ""
    var appPath: String? = nil
    var iconImage: NSImage? = nil
    /// 是否由 macOS「系统设置 → 登录项与扩展」(BTM) 托管，不支持直接通过 launchctl / System Events 切换
    var managedBySystemSettings: Bool = false
}

// MARK: - 体积格式化

enum Fmt {
    private static let byteFormatter = LockedValue<ByteCountFormatter>({
        let bcf = ByteCountFormatter()
        bcf.countStyle = .file
        bcf.allowedUnits = .useAll
        return bcf
    }())

    static func size(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }
        return byteFormatter.withValue { $0.string(fromByteCount: bytes) }
    }

    /// 紧凑写法，用于列表（无空格）
    static func sizeCompact(_ bytes: Int64) -> String {
        size(bytes).replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\u{00A0}", with: "")
    }

    static func date(_ d: Date?) -> String {
        guard let d else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: d)
    }

    /// 应用程序最后使用时间格式化 
    static func appDate(_ d: Date?) -> String {
        guard let d else { return L10n.localized(.neverOpened) }
        let f = DateFormatter()
        f.locale = L10n.shared.currentLocale
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: d)
    }
}
