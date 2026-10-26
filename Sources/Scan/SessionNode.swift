import Foundation
import SwiftUI

// ============================================================
//  Node —— 一切皆节点树
//
//  这是原版最核心的设计：扫描产出 Node 树 → 界面渲染树 →
//  勾选修改 selection → 清理按依赖顺序遍历树逐个移除。
//
//  树可以有任意深度；DataManager 的三列（分类 / 组 / 明细）
//  就是对这棵树不同层级的投影。
// ============================================================

struct Node: Identifiable, Sendable {
    private static let childrenRevisionCounter = LockedValue<UInt64>(0)
    private static func nextChildrenRevision() -> UInt64 {
        childrenRevisionCounter.withValue { value in value &+= 1; return value }
    }
    private(set) var childrenRevision = Node.nextChildrenRevision()
    var ruleIdentity: RuleIdentity? = RuleTaskGate.shared.identity
    let id: UUID
    var name: String
    var url: URL?
    var icon: String
    var note: String
    var safety: Safety
    var action: ItemAction
    var size: Int64 {
        didSet {
            if !isGroup || children.isEmpty {
                _cachedTotalSize = size
            } else {
                let childSum = children.reduce(Int64(0)) { $0 + $1.totalSize }
                _cachedTotalSize = max(size, childSum)
            }
        }
    }
    var directoryChildrenFromCache = false
    var children: [Node] {
        didSet {
            childrenRevision = Self.nextChildrenRevision()
            if isGroup {
                let childSum = children.reduce(Int64(0)) { $0 + $1.totalSize }
                _cachedTotalSize = max(size, childSum)
                _cachedLeafCount = children.isEmpty ? (url == nil ? 0 : 1) : children.reduce(0) { $0 + $1.leafCount }
            } else {
                _cachedTotalSize = size
                _cachedLeafCount = 1
            }
        }
    }
    var isGroup: Bool {
        didSet {
            if isGroup {
                let childSum = children.reduce(Int64(0)) { $0 + $1.totalSize }
                _cachedTotalSize = max(size, childSum)
                _cachedLeafCount = children.isEmpty ? (url == nil ? 0 : 1) : children.reduce(0) { $0 + $1.leafCount }
            } else {
                _cachedTotalSize = size
                _cachedLeafCount = 1
            }
        }
    }
    private var _cachedTotalSize: Int64 = 0
    private var _cachedLeafCount: Int = 1
    var ignorable: Bool
    /// 系统必需 / 受保护，不可移除
    var locked: Bool
    /// 角标，例如 iOS 备份的「最新」
    var isRetainedOriginal: Bool = false
    var badge: String?
    /// 应用图标（有则优先于 SF Symbol 显示）
    var image: NSImage?
    /// 所属分类标签（DataManager 第一列的筛选依据，一个节点可属于多个）
    var tags: [String]
    /// 「显示简介」的元数据字段
    var meta: [(String, String)]
    /// 智能勾选的默认状态(重复文件的「保留份」为 false,策略勾选时必须跳过)
    var autoSelected: Bool
    /// 日期属性（如应用程序上次打开时间、文件最后修改时间）
    var date: Date? = nil
    /// 安装日期属性（用于软件管理按安装时间排序）
    var installDate: Date? = nil

    // —— 结果页磁贴文案 ——
    // 原版每一类垃圾都单独写死磁贴标题/副标题（见 JunkCleanupModule 的 tiles_* 字符串），
    // 有的是「已发现 %@ 的系统垃圾」，有的是「已找到 %@ 的 AI 垃圾文件」，
    // 量词也不一样（个/的），所以这里逐个字段带下来，而不是统一拼组名。
    var tileName: String = ""
    var tileQuantifier: String = ""
    var tileVerb: String = "found"
    var tileNote: String = ""
    var tileIcon: String = ""
    /// 磁贴聚合键：原版「系统垃圾」磁贴下含 12 个子组（缓存/日志/语言包/登录项…），
    /// 结果页只显示 1 个磁贴，进 DataManager 才展开成 12 个组。
    /// 因此扫出多个组可共享同一个 tileKey，由 Tiles.from 合并成一个磁贴。
    var tileKey: String = ""
    /// 结构化启动项模型（消除对「状态 == 已停用」中文文本的脆弱依赖）
    var startupItem: StartupItem? = nil
    /// 结构化维护任务 ID（消除对中文任务名的脆弱依赖）
    var maintenanceTaskId: String? = nil
    /// 应用当前是否处于运行状态 
    var isActiveNow: Bool = false
    /// 资产归属的应用 Bundle Identifier 列表（用于运行中应用防护 F2/R3）
    var ownerBundleIDs: [String] = []
    /// 扫描时捕获的物理文件身份（TOCTOU 防御 F4/R4）
    var fileIdentity: FileIdentity? = nil
    var duplicateEvidence: DuplicateEvidence? = nil
    var dockerEndpoint: DockerEndpoint? = nil
    var ruleEvidence: CleanupRuleEvidence? = nil
    var uninstallContext: UninstallContext? = nil
    var uninstallPurpose: UninstallerEngine.AppFolderPurpose? = nil
    var authorizationContext: CleanAuthorizationContext = .organizeManual
    private var hasExplicitAuthorizationContext: Bool = false
    var evaluationReason: CandidateEvaluationReason? = nil
    var measuredBytes: Int64? = nil
    var selectionRestrictions: Set<SelectionRestriction> = []
    var cacheRecommendation: CacheRecommendationSnapshot? = nil

    var resolvedAuthorizationContext: CleanAuthorizationContext {
        if hasExplicitAuthorizationContext {
            return authorizationContext
        }
        return CleanAuthorizationContext.infer(
            action: action,
            uninstallContext: uninstallContext,
            ruleEvidence: ruleEvidence,
            defaultFallback: authorizationContext
        )
    }

    init(id: UUID = UUID(),
         name: String,
         url: URL? = nil,
         icon: String = "doc",
         note: String = "",
         safety: Safety = .safe,
         action: ItemAction = .trash,
         size: Int64 = 0,
         children: [Node] = [],
         isGroup: Bool = false,
         ignorable: Bool = true,
         locked: Bool = false,
         badge: String? = nil,
         image: NSImage? = nil,
         tags: [String] = [],
         meta: [(String, String)] = [],
         autoSelected: Bool = true,
         date: Date? = nil,
         installDate: Date? = nil,
         tileName: String = "",
         tileQuantifier: String = "",
         tileVerb: String = "found",
         tileNote: String = "",
         tileIcon: String = "",
         tileKey: String = "",
         startupItem: StartupItem? = nil,
         maintenanceTaskId: String? = nil,
         isActiveNow: Bool = false,
         ownerBundleIDs: [String] = [],
         fileIdentity: FileIdentity? = nil,
         captureIdentity: Bool = true,
         authorizationContext: CleanAuthorizationContext? = nil,
         evaluationReason: CandidateEvaluationReason? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.icon = icon
        self.note = note
        self.safety = safety
        self.action = action
        self.size = size
        self.children = children
        self.isGroup = isGroup
        if isGroup {
            let childSum = children.reduce(Int64(0)) { $0 + $1.totalSize }
            self._cachedTotalSize = max(size, childSum)
            self._cachedLeafCount = children.isEmpty ? (url == nil ? 0 : 1) : children.reduce(0) { $0 + $1.leafCount }
        } else {
            self._cachedTotalSize = size
            self._cachedLeafCount = 1
        }
        self.ignorable = ignorable
        self.locked = locked
        self.badge = badge
        self.image = image
        self.tags = tags
        self.meta = meta
        self.autoSelected = autoSelected
        self.date = date
        self.installDate = installDate
        self.tileName = tileName
        self.tileQuantifier = tileQuantifier
        self.tileVerb = tileVerb
        self.tileNote = tileNote
        self.tileIcon = tileIcon
        self.tileKey = tileKey
        self.startupItem = startupItem
        self.maintenanceTaskId = maintenanceTaskId
        self.isActiveNow = isActiveNow
        self.ownerBundleIDs = ownerBundleIDs
        self.fileIdentity = fileIdentity ?? ((captureIdentity && url != nil) ? FileIdentity.capture(from: url!) : nil)
        if let authorizationContext {
            self.authorizationContext = authorizationContext
            self.hasExplicitAuthorizationContext = true
        } else {
            self.authorizationContext = CleanAuthorizationContext.infer(
                action: action,
                defaultFallback: .organizeManual
            )
            self.hasExplicitAuthorizationContext = false
        }
        self.evaluationReason = evaluationReason
    }

    /// 基于文件路径生成稳定的确定性 UUID（供空间透视实时扫描期间保持同一文件夹节点身份不变）
    static func stableID(forPath path: String) -> UUID {
        var h1: UInt64 = 0xcbf29ce484222325
        var h2: UInt64 = 0x84222325cbf29ce4
        for b in path.utf8 {
            h1 ^= UInt64(b)
            h1 = h1 &* 0x100000001b3
            h2 ^= UInt64(b ^ 0x5c)
            h2 = h2 &* 0x100000001b3
        }
        let u: uuid_t = (
            UInt8(truncatingIfNeeded: h1 >> 56), UInt8(truncatingIfNeeded: h1 >> 48),
            UInt8(truncatingIfNeeded: h1 >> 40), UInt8(truncatingIfNeeded: h1 >> 32),
            UInt8(truncatingIfNeeded: h1 >> 24), UInt8(truncatingIfNeeded: h1 >> 16),
            UInt8((h1 >> 8) & 0x0f | 0x40),      UInt8(truncatingIfNeeded: h1),
            UInt8((h2 >> 56) & 0x3f | 0x80),     UInt8(truncatingIfNeeded: h2 >> 48),
            UInt8(truncatingIfNeeded: h2 >> 40), UInt8(truncatingIfNeeded: h2 >> 32),
            UInt8(truncatingIfNeeded: h2 >> 24), UInt8(truncatingIfNeeded: h2 >> 16),
            UInt8(truncatingIfNeeded: h2 >> 8),  UInt8(truncatingIfNeeded: h2)
        )
        return UUID(uuid: u)
    }

    // MARK: 派生属性

    var path: String { url?.path ?? "" }

    /// 读取应用节点的版本号元数据
    var appVersion: String {
        for (k, v) in meta where k == "Version" || k == L10n.localized(.labelVersion) {
            if !v.isEmpty && v != "—" { return v }
        }
        return ""
    }

    var isLeaf: Bool { !isGroup }

    /// 组：子树体积之和（O(1) 缓存读取）；叶子：自身体积
    var totalSize: Int64 {
        _cachedTotalSize
    }

    /// 展开成可勾选的最小单元
    var leaves: [Node] {
        isGroup ? children.flatMap { $0.leaves } : [self]
    }

    var leafCount: Int { _cachedLeafCount }

    /// 计算应用主程序包 (.app) 本身体积
    var appBundleSize: Int64 {
        let appBundleTag = L10n.localized(.appBundleBody)
        if let bundleNode = children.first(where: {
            $0.note == "Application Bundle" || $0.tags.contains("Application Bundle") || $0.tags.contains(appBundleTag) || ($0.url?.pathExtension == "app" && !$0.isGroup)
        }) {
            return bundleNode.totalSize
        }
        if let u = url, u.pathExtension == "app", !isGroup {
            return totalSize
        }
        return totalSize
    }

    /// 计算应用对应的数据文件大小（除本体 .app 以外的所有关联数据、容器、缓存、偏好设置等文件大小）
    var appDataSize: Int64 {
        max(0, totalSize - appBundleSize)
    }

    var metaSize: String { Fmt.size(totalSize) }
    var metaCount: String { L10n.format(.foundItemsCountFormat, leafCount) }

    // MARK: 构造

    /// 从引擎的 ScanGroup 转换
    static func group(from g: ScanGroup, icon: String? = nil, tags: [String] = []) -> Node {
        Node(name: g.title,
             url: nil,
             icon: icon ?? g.icon,
             note: g.note,
             safety: g.safety,
             action: .trash,
             size: g.totalSize,
             children: g.items.map { item(from: $0, tags: tags) },
             isGroup: true,
             ignorable: true,
             locked: false,
             tags: tags,
             tileName: g.resolvedTileName,
             tileQuantifier: g.resolvedTileQuantifier,
             tileVerb: g.resolvedTileVerb,
             tileNote: g.resolvedTileNote,
             tileIcon: g.resolvedTileIcon,
             tileKey: g.tileKey)
    }

    /// 从引擎的 ScanItem 转换
    static func item(from i: ScanItem, tags: [String] = []) -> Node {
        var meta: [(String, String)] = []
        if !i.url.path.isEmpty, let attrs = try? FileManager.default.attributesOfItem(atPath: i.url.path) {
            meta.append((tr(.fileType), (attrs[.type] as? FileAttributeType) == .typeDirectory ? tr(.fileTypeFolder) : (i.url.pathExtension.isEmpty ? tr(.fileTypeFile) : i.url.pathExtension.uppercased())))
            if let d = attrs[.modificationDate] as? Date { meta.append((tr(.modificationDate), Fmt.date(d))) }
            if let d = attrs[.creationDate] as? Date { meta.append((tr(.creationDate), Fmt.date(d))) }
        }
        let childNodes = i.children.map { item(from: $0, tags: tags) }
        let totalSize = childNodes.isEmpty ? i.size : max(i.size, childNodes.reduce(0) { $0 + $1.totalSize })
        let isSyntheticSubgroup = (i.url.path.isEmpty || !i.url.isFileURL) && !childNodes.isEmpty
        let resolvedURL: URL? = isSyntheticSubgroup ? nil : i.url
        return Node(name: i.name,
                    url: resolvedURL,
                    icon: isSyntheticSubgroup ? "folder" : icon(for: i.url),
                    note: i.note,
                    safety: i.safety,
                    action: i.action,
                    size: totalSize,
                    children: childNodes,
                    isGroup: !childNodes.isEmpty,
                    ignorable: true,
                    locked: i.locked ?? (resolvedURL.map { FileUtil.isProtected($0) } ?? false),
                    badge: i.badge.isEmpty ? nil : i.badge,
                    image: i.image,
                    tags: tags,
                    meta: meta,
                    autoSelected: i.isSelected,
                    date: resolvedURL.flatMap { (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate },
                    ownerBundleIDs: i.ownerBundleIDs,
                    fileIdentity: i.fileIdentity ?? resolvedURL.flatMap { FileIdentity.capture(from: $0) },
                    authorizationContext: i.resolvedAuthorizationContext,
                    evaluationReason: i.evaluationReason)
            .withEvidence(from: i)
    }

    private func withEvidence(from item: ScanItem) -> Node {
        var copy = self
        copy.isRetainedOriginal = item.isRetainedOriginal
        copy.duplicateEvidence = item.duplicateEvidence
        copy.dockerEndpoint = item.dockerEndpoint
        copy.ruleIdentity = item.ruleIdentity
        copy.ruleEvidence = item.ruleEvidence
        copy.uninstallContext = item.uninstallContext
        copy.uninstallPurpose = item.uninstallPurpose
        copy.authorizationContext = item.resolvedAuthorizationContext
        copy.hasExplicitAuthorizationContext = true
        copy.evaluationReason = item.evaluationReason
        copy.measuredBytes = item.measuredBytes ?? item.size
        copy.selectionRestrictions.formUnion(item.selectionRestrictions)
        copy.cacheRecommendation = item.cacheRecommendation ?? copy.cacheRecommendation
        if let reason = item.ruleEvidence?.reason {
            if let evalDesc = item.evaluationReason?.localizedExplanation,
               (copy.locked || item.ruleEvidence?.executable == false) {
                copy.note = evalDesc
            } else {
                copy.note = reason.localizedExplanation
            }
            copy.meta.append((L10n.localized(.cleanupRuleLabel), item.ruleEvidence!.id))
        } else if copy.locked, copy.note.isEmpty, let evalDesc = item.evaluationReason?.localizedExplanation {
            copy.note = evalDesc
        }
        if let rec = copy.cacheRecommendation, let allocBytes = rec.allocatedBytes, allocBytes > 0 {
            copy.meta.append((L10n.localized(.junkCacheAllocatedSize), Fmt.size(allocBytes)))
        }
        return copy
    }

    var cacheLargeSuggestionBadge: String? {
        JunkCacheRecommendationPolicy.localizedLargeBadge(for: cacheRecommendation)
    }

    var cacheEffectDescriptions: [String] {
        guard let cacheRecommendation else { return [] }
        return JunkCacheRecommendationPolicy.localizedEffects(for: cacheRecommendation)
    }

    var suggestedLargeUnitCount: Int {
        var unitPaths = Set<String>()
        for leaf in leaves {
            if let rec = leaf.cacheRecommendation,
               rec.state == .suggestedLarge,
               rec.profileID != nil,
               !rec.unitPath.isEmpty {
                unitPaths.insert(rec.unitPath)
            }
        }
        return unitPaths.count
    }

    static func icon(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "app":                    return "macwindow"
        case "plist":                  return "list.bullet.rectangle"
        case "log", "logarchive":      return "doc.text"
        case "dmg", "pkg", "zip", "tar", "gz": return "shippingbox"
        case "jpg", "jpeg", "png", "heic", "gif", "tiff", "webp": return "photo"
        case "mp4", "mov", "avi", "mkv": return "film"
        case "mp3", "m4a", "wav", "aac": return "music.note"
        case "pdf":                    return "doc.richtext"
        case "lproj":                  return "globe"
        case "framework", "dylib":     return "shippingbox.fill"
        case "xcarchive", "xcuserdata":return "hammer"
        default:
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                return "folder"
            }
            return "doc"
        }
    }
}

// MARK: - 树的查询与遍历

extension Array where Element == Node {
    /// 深度优先查找
    func firstNode(id: UUID) -> Node? {
        for n in self {
            if n.id == id { return n }
            if let f = n.children.firstNode(id: id) { return f }
        }
        return nil
    }

    /// 收集所有叶子
    var allLeaves: [Node] { flatMap { $0.leaves } }

    /// 原地修改某个节点
    mutating func mutate(id: UUID, _ f: (inout Node) -> Void) -> Bool {
        for i in indices {
            if self[i].id == id { f(&self[i]); return true }
            if self[i].children.mutate(id: id, f) { return true }
        }
        return false
    }

    /// 移除满足条件的叶子，返回被移除的数量，并递归剪除已变空的分组
    mutating func removeLeaves(where pred: (Node) -> Bool) -> Int {
        var removed = 0
        var keep: [Node] = []
        keep.reserveCapacity(count)
        for var n in self {
            if n.isGroup {
                let childRemoved = n.children.removeLeaves(where: pred)
                removed += childRemoved
                if !n.children.isEmpty {
                    n.size = n.children.reduce(0) { $0 + $1.totalSize }
                    keep.append(n)
                }
            } else if pred(n) {
                removed += 1
            } else {
                keep.append(n)
            }
        }
        self = keep
        return removed
    }

    /// 移除满足条件的节点（包括分组文件夹或叶子文件），并同步重算父节点体积与剪除空分组
    mutating func removeNodesOrLeaves(where pred: (Node) -> Bool) -> Int {
        var removed = 0
        var keep: [Node] = []
        keep.reserveCapacity(count)
        for var n in self {
            if pred(n) {
                removed += 1
                continue
            }
            if n.isGroup && !n.children.isEmpty {
                let childRemoved = n.children.removeNodesOrLeaves(where: pred)
                if childRemoved > 0 {
                    removed += childRemoved
                    n.size = n.children.reduce(0) { $0 + $1.totalSize }
                }
                if n.children.isEmpty && n.url == nil {
                    continue
                }
            }
            keep.append(n)
        }
        self = keep
        return removed
    }
}

// MARK: - 磁贴

enum TileSize {
    case standard          // 标准磁贴
    case largeHorizontal   // 横向大磁贴
    case largeVertical     // 纵向大磁贴
}

struct Tile: Identifiable {
    let id = UUID()
    var size: TileSize = .standard
    var icon: String
    var title: String
    var detail: String = ""
    var accent: Color = Theme.accent
    var actionTitle: String = "Review"
    var primaryActionTitle: String? = nil
    var enabled: Bool = true
    /// 点击「检查」时跳转到 DataManager 的哪个分类（空 = 全部）
    var category: String = ""
    /// 无数据时的替代文案（未发现时）
    var emptyTitle: String = ""
    var isPromo: Bool = false
    var satelliteIcons: [String] = []
    var sizeValue: Int64 = 0
    var appIcons: [String] = []
}

// MARK: - 分类

struct DataCategory: Identifiable, Hashable {
    var id: String { title }
    var title: String
    var icon: String

    init(_ title: String, _ icon: String = "square.grid.2x2") {
        self.title = title
        self.icon = icon
    }

    static let all = DataCategory(L10n.string(.filterAll), "square.grid.2x2")
}

// MARK: - 选择策略（对应原版「选择」下拉）

enum SelectStrategy: String, CaseIterable, Identifiable {
    case none        = "none"
    case smart       = "smart"
    case all         = "all"
    case largest     = "largest"
    case oldest      = "oldest"
    case newest      = "newest"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .none:    return tr(.actionNone)
        case .smart:   return tr(.actionSmartRecommended)
        case .all:     return tr(.actionSelectAll)
        case .largest: return tr(.strategyLargest)
        case .oldest:  return tr(.strategyOldest)
        case .newest:  return tr(.strategyNewest)
        }
    }

    var symbol: String {
        switch self {
        case .none:    return "circle.dashed"
        case .smart:   return "wand.and.stars"
        case .all:     return "checkmark.circle"
        case .largest: return "arrow.up.arrow.down"
        case .oldest:  return "clock.arrow.circlepath"
        case .newest:  return "clock"
        }
    }
}

// MARK: - 排序

enum SortKey: String, CaseIterable, Identifiable {
    case name        = "name"
    case size        = "size"
    case date        = "date"
    case installDate = "installDate"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .name:        return tr(.sortByName)
        case .size:        return tr(.sortBySize)
        case .date:        return tr(.sortByDate)
        case .installDate: return tr(.sortByInstallDate)
        }
    }
}

// MARK: - 清理结果与动作分类 (F5)

enum CleanActionCategory: String, Sendable {
    case movedToTrash           // 移至系统废纸篓 (可恢复，同卷未释放物理空间)
    case permanentlyDeleted     // 永久物理删除 (如废纸篓清空，空间立即释放)
    case systemReclaimed        // 系统级物理回收 (如 APFS 瘦身、Docker prune)
    case maintenanceExecuted    // 维护脚本执行
    case partialFailure         // 容器部分子项清理失败（已移入废纸篓部分保留真实字节数，失败子项如实上报）
    case skipped                // 安全跳过
    case failed                 // 执行失败
    case cancelled
    case absent
}


struct LogEntry: Identifiable {
    let id = UUID()
    var time: Date = Date()
    var title: String
    var detail: String
    var ok: Bool
}

/// 智能呵护每张卡片的独立扫描状态
struct SmartCardState {
    var scanning = false
    var done = false
    var progress: Double = 0
    var count: Int = 0
    var size: Int64 = 0
    var tree: [Node]? = nil
    var scanIssues: [String] = []
    var scanDegradations: [ScanDegradationReason] = []
    var evaluationReasonCounts: [CandidateEvaluationReason: Int] = [:]
    var deduplicationRecords: [DeduplicationRecord] = []
    /// 是否纳入「一键执行」(对应原版卡上的 SmartCareCheckbox)
    var included = true

    /// 卡片文案（对应原版 found / notFound）
    var isEmpty: Bool { done && count == 0 && scanIssues.isEmpty && scanDegradations.isEmpty }
}

/// A view projection only: keep captured containers as rows, without changing execution leaves.
enum CleanupPresentation {
    static func rows(_ node: Node) -> [Node] {
        if node.isGroup, let path = node.url?.standardizedFileURL.path,
           !node.children.isEmpty,
           node.children.allSatisfy({ $0.ruleEvidence?.containerPath == path }) { return [node] }
        return node.isGroup ? node.children.flatMap(rows) : [node]
    }
}

// MARK: - 扫描分类与接入适配

public enum ScanCategory: Hashable, Sendable {
    case systemJunk, trashBins, aiClutter, orphanLeftover

    public init(engineTitle: String) {
        switch engineTitle {
        case "Xcode Junk", "Universal Binaries", "Extra Binaries",
             L10n.localized(.xcodeJunk), L10n.localized(.scannerUniversalBinariesTitle), L10n.localized(.extraBinaries):
            self = .systemJunk
        case "Trash", "Local Trash",
             L10n.localized(.scannerTrashBins), L10n.localized(.scannerLocalTrashBins):
            self = .trashBins
        case "AI Clutter Files", "Local AI Models",
             L10n.localized(.scannerAiClutterFiles), L10n.localized(.scannerLocalAiModels):
            self = .aiClutter
        case "Orphan Leftovers", "Orphan Leftover",
             L10n.localized(.scannerAppLeftovers), L10n.localized(.scanOrphanLeftoversPrompt):
            self = .orphanLeftover
        default:
            self = .systemJunk
        }
    }

    public var titleKey: L10nKey {
        switch self {
        case .systemJunk: return .systemJunk
        case .trashBins: return .scannerTrashBins
        case .aiClutter: return .scannerAiClutterFiles
        case .orphanLeftover: return .scannerAppLeftovers
        }
    }

    public var localizedTitle: String {
        L10n.localized(titleKey)
    }
}

extension Node {
    /// 承重接纳方法：将引擎 ScanGroup 转换并打上类型安全的 ScanCategory 标签
    public static func adopt(_ group: ScanGroup) -> Node {
        let cat = ScanCategory(engineTitle: group.title)
        return Node.group(from: group, tags: [cat.localizedTitle])
    }
}
