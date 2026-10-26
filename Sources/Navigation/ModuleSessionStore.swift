import Foundation
import SwiftUI

/// 单个功能模块的独立会话状态（支持多模块后台并行扫描 + 切换模块时完整保留已扫描状态）
struct ModuleSession {
    var roots: [Node] = []
    var selection: Set<UUID> = []
    var expanded: Set<UUID> = []
    var category: String = ""
    var search: String = ""
    var sortKey: SortKey = .size
    var sortAscending: Bool = false
    var strategy: SelectStrategy = .smart
    var focusGroup: UUID? = nil
    var screen: Screen = .intro
    var scanning: Bool = false
    var isStoppingScan: Bool = false
    var scanProgress: Double = 0
    var scanStatus: String = ""
    /// 预计剩余秒数；nil 表示样本不足、不显示（宁可不显示，也不给跳动的假数字）
    var scanETA: TimeInterval? = nil
    var scanPaths: [String] = []
    var report: CleanReport? = nil
    var hasScanned: Bool = false
    var hasOptimized: Bool = false
    var didApplyDefaults: Bool = false
    var stopFlag: StopFlag = StopFlag()
    var scanGeneration: Int = 0
    var scanIssues: [String] = []
    var scanDegradations: [ScanDegradationReason] = []
    var evaluationReasonCounts: [CandidateEvaluationReason: Int] = [:]
    var deduplicationRecords: [DeduplicationRecord] = []
    var completedSuccessfully = false

    // 视图层专属导航/展开状态持久化（避免切换侧栏后丢失下钻路径或当前子标签）
    var spaceNavPaths: [String] = []
    var spaceFocusedId: UUID? = nil
    var spaceChartMode: SpaceChartMode = .treemap
    var spaceLeftTab: SpacePane = .directory
    var spaceIsVisualMode: Bool = true
    var appActiveTab: ApplicationsTab = .uninstall
    var appExpandedIDs: Set<UUID> = []
    var startupItemsCache: [StartupItem] = []
    var startupLoaded: Bool = false
    var cleaningProfileState = CleaningProfileState()
    var scannedLargeFileThresholdMB: Int? = nil
    var scannedOldFileMonths: Int? = nil
}

/// One store per AppState. Session transactions remain on MainActor.
@MainActor
final class ModuleSessionStore {
    private var sessions: [ModuleKey: ModuleSession] = [:]
    func clearForRuleUpdate() {
        for key in Array(sessions.keys) {
            guard let previous = sessions[key] else { continue }
            previous.stopFlag.value = true
            var cleared = ModuleSession()
            cleared.scanGeneration = previous.scanGeneration + 1
            sessions[key] = cleared
        }
    }

    subscript(key: ModuleKey) -> ModuleSession? {
        get { sessions[key] }
        set { sessions[key] = newValue }
    }
}
