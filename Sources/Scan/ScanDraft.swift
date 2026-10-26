import AppKit
import Foundation

// MARK: - 扫描条目

struct ScanItem: Identifiable, Hashable, Sendable {
    var ruleIdentity: RuleIdentity? = RuleTaskGate.shared.identity
    let id = UUID()
    var url: URL
    var isRetainedOriginal: Bool = false
    var name: String
    var size: Int64
    var note: String = ""
    var safety: Safety = .caution
    var action: ItemAction = .trash
    var isSelected: Bool = false
    /// 角标文案,如 iOS 备份的「最新」(有角标的项默认不参与智能勾选)
    var badge: String = ""
    /// 自定义应用/工具图标
    var image: NSImage? = nil
    /// 子级明细项（支持工具 -> 多子缓存/文件明细的层级展开）
    var children: [ScanItem] = []
    /// 受保护锁定标记覆盖：
    ///   nil   = 自动（由 FileUtil.isProtected(url) 判定，默认行为）
    ///   true  = 强制锁定
    ///   false = 强制解锁——仅用于「由系统专用指令管理、路径位于只读系统卷」
    ///           的可移除资产（如 Cryptex 挂载的模拟器运行时，经 simctl 删除）。
    ///           注意：解锁后普通 trash 动作仍会被 RiskControlMatrix 的物理红线拦截，
    ///           因此该覆盖只会放行专用动作路径，属纵深防御。
    var locked: Bool? = nil
    /// 资产归属的应用 Bundle Identifier 列表（用于运行中应用防护 F2/R3）
    var ownerBundleIDs: [String] = []
    /// 扫描时捕获的物理文件身份（TOCTOU 防御 F4/R4）
    var fileIdentity: FileIdentity? = nil
    var duplicateEvidence: DuplicateEvidence? = nil
    var dockerEndpoint: DockerEndpoint? = nil
    var ruleEvidence: CleanupRuleEvidence? = nil
    var uninstallContext: UninstallContext? = nil
    var uninstallPurpose: UninstallerEngine.AppFolderPurpose? = nil
    /// 强类型清理授权上下文（默认按垃圾规则通道校验，非垃圾模块显式声明）
    var authorizationContext: CleanAuthorizationContext = .junkRule
    /// 结构化评估/降级原因
    var evaluationReason: CandidateEvaluationReason? = nil
    /// 标记是否已完成统一规则评估（保证跨层评估幂等，防止保壳展开子项被二次展开）
    var isRuleEvaluated: Bool = false
    /// 扫描时捕获的真实物理测量体积（与去重互斥显示体积 size 分离，防执行期 minBytes 复核失真）
    var measuredBytes: Int64? = nil
    /// T09：默认选择限制集合
    var selectionRestrictions: Set<SelectionRestriction> = []
    /// T12：大缓存与重建影响裁决快照
    var cacheRecommendation: CacheRecommendationSnapshot? = nil

    var resolvedAuthorizationContext: CleanAuthorizationContext {
        if authorizationContext != .junkRule {
            return authorizationContext
        }
        return CleanAuthorizationContext.infer(
            action: action,
            uninstallContext: uninstallContext,
            ruleEvidence: ruleEvidence,
            defaultFallback: .junkRule
        )
    }

    var path: String { url.path }

    static func == (l: ScanItem, r: ScanItem) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

// MARK: - 扫描分组

struct ScanGroup: Identifiable, Sendable {
    let id = UUID()
    var title: String
    var icon: String
    var note: String = ""
    var safety: Safety = .safe
    /// 所属分类（用于 DataManager 第一列），例如「系统垃圾」「废纸篓」
    var category: String = ""
    var items: [ScanItem]
    var isExpanded: Bool = false

    // —— 结果页磁贴文案（原版按类别分别写死，见 JunkCleanupModule 的 tiles_* 字符串）——
    /// 磁贴标题里的分类名，例："系统垃圾" / "额外二进制文件" / "已删除的用户账户"
    /// 留空则回退用 title。
    var tileName: String = ""
    /// 体积与分类名之间用 "的" 还是 "个"：原版"已发现 %@ 个废纸篓"用的是「个」
    var tileQuantifier: String = ""
    var tileVerb: String = ""
    /// 磁贴副标题，例："清理系统和应用程序生成的所有已不再有用的文件。"
    var tileNote: String = ""
    /// 磁贴图标（原版每一类都不一样）
    var tileIcon: String = ""
    /// 磁贴聚合键：多个 ScanGroup 共用同一个键时，结果页合并成一个磁贴。
    /// 原版「系统垃圾」磁贴下含缓存/日志/语言包/iOS 备份/二进制/登录项/偏好设置/
    /// 文稿版本/已删除用户等十几个子组，但结果页只显示一个磁贴。
    /// 留空表示自成一张磁贴。
    var tileKey: String = ""

    // —— 磁贴文案解析：显式字段优先，其次按 tileKey 查原版文案表 ——
    // 原版 JunkCleanupModule 的 Localizable.strings 里，tiles_* 键把每一类垃圾的
    // 「标题 / 副标题 / 已完成标题」都分别写死。系统垃圾背后有十几个扫描组共用同一
    // 套文案，因此按 tileKey 查表，引擎侧只需标一个键，不用把同一句话抄十几遍。
    var resolvedTileName: String {
        if !tileName.isEmpty { return tileName }
        if let c = TileCopyBook.shared[tileKey] { return c.name }
        return title
    }
    var resolvedTileNote: String {
        if !tileNote.isEmpty { return tileNote }
        if let c = TileCopyBook.shared[tileKey] { return c.note }
        return note
    }
    var resolvedTileIcon: String {
        if !tileIcon.isEmpty { return tileIcon }
        if let c = TileCopyBook.shared[tileKey] { return c.icon }
        return icon
    }
    var resolvedTileQuantifier: String {
        if !tileQuantifier.isEmpty && tileQuantifier != "" && tileQuantifier != L10n.localized(.tileQuantifierDe) { return tileQuantifier }
        if let c = TileCopyBook.shared[tileKey] { return c.quantifier }
        return L10n.localized(.tileQuantifierDe)
    }
    var resolvedTileVerb: String {
        if !tileVerb.isEmpty && tileVerb != "found" && tileVerb != L10n.localized(.tileVerbFound) { return tileVerb }
        if let c = TileCopyBook.shared[tileKey] { return c.verb }
        return L10n.localized(.tileVerbFound)
    }

    /// 构造器刻意采用引擎侧的书写顺序：tile* 文案在前，safety / items 在后。
    /// （各引擎都是「先写文案，再写安全等级和扫描项」，与结构体字段声明顺序无关。）
    init(title: String,
         icon: String,
         note: String = "",
         tileName: String = "",
         tileQuantifier: String = "",
         tileVerb: String = "",
         tileNote: String = "",
         tileIcon: String = "",
         tileKey: String = "",
         safety: Safety = .safe,
         category: String = "",
         items: [ScanItem],
         isExpanded: Bool = false) {
        self.title = title
        self.icon = icon
        self.note = note
        self.safety = safety
        self.category = category
        self.items = items
        self.isExpanded = isExpanded
        self.tileName = tileName
        self.tileQuantifier = tileQuantifier
        self.tileVerb = tileVerb
        self.tileNote = tileNote
        self.tileIcon = tileIcon
        self.tileKey = tileKey
    }

    var totalSize: Int64 { items.reduce(0) { $0 + $1.size } }
    var selectedSize: Int64 { items.filter { $0.isSelected }.reduce(0) { $0 + $1.size } }
    var selectedCount: Int { items.filter { $0.isSelected }.count }

    mutating func toggleAll() {
        let target = selectedCount != items.count
        for i in items.indices { items[i].isSelected = target }
    }
}

// MARK: - 原版磁贴文案表

/// 一份文案抄自原版 JunkCleanupModule/zh-Hans.lproj/Localizable.strings 的 tiles_* 键，
struct TileCopy {
    let nameKey: L10nKey
    let noteKey: L10nKey
    let icon: String
    let quantifierKey: L10nKey
    let verbKey: L10nKey

    var isRetainedOriginal: Bool = false
    var name: String { L10n.localized(nameKey) }
    var note: String { L10n.localized(noteKey) }
    var quantifier: String { L10n.localized(quantifierKey) }
    var verb: String { L10n.localized(verbKey) }
}

enum TileCopyBook {
    static let shared: [String: TileCopy] = [
        "systemJunk": TileCopy(
            nameKey: .systemJunk,
            noteKey: .tileNoteSystemJunk,
            icon: "cm_detail_system-junk_user-cache-files",
            quantifierKey: .tileQuantifierDe,
            verbKey: .tileVerbFound),
        "xcodeJunk": TileCopy(
            nameKey: .xcodeJunk,
            noteKey: .tileNoteXcodeJunk,
            icon: "cm_detail_system-junk_xcode-derived-data",
            quantifierKey: .tileQuantifierDe,
            verbKey: .tileVerbFound),
        "universalBinaries": TileCopy(
            nameKey: .extraBinaries,
            noteKey: .tileNoteUniversalBinaries,
            icon: "cm_detail_system-junk_universal-binaries",
            quantifierKey: .tileQuantifierDe,
            verbKey: .tileVerbFound),
        "iOSBackups": TileCopy(
            nameKey: .scannerIosDeviceBackups,
            noteKey: .tileNoteIosBackups,
            icon: "cm_detail_system-junk_xcode-ios-simulator",
            quantifierKey: .tileQuantifierDe,
            verbKey: .tileVerbFound),
        "trashBins": TileCopy(
            nameKey: .scannerTrashBins,
            noteKey: .tileNoteTrashBins,
            icon: "cm_detail_trash-bins_macintosh-hd",
            quantifierKey: .tileQuantifierGe,
            verbKey: .tileVerbFound),
        "aiClutter": TileCopy(
            nameKey: .scannerAiClutterFiles,
            noteKey: .tileNoteAiClutter,
            icon: "cm_cat_ai-clutter",
            quantifierKey: .tileQuantifierDe,
            verbKey: .tileVerbLocated),
        "documentVersions": TileCopy(
            nameKey: .scannerDocumentVersions,
            noteKey: .tileNoteDocumentVersions,
            icon: "cm_cat_similar-files",
            quantifierKey: .tileQuantifierGe,
            verbKey: .tileVerbFound),
        "deletedUsers": TileCopy(
            nameKey: .scannerDeletedUsers,
            noteKey: .tileNoteDeletedUsers,
            icon: "cm_cat_privacy",
            quantifierKey: .tileQuantifierGe,
            verbKey: .tileVerbFound),
    ]
}

// MARK: - 已安装应用

