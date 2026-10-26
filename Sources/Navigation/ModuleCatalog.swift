import SwiftUI

// ============================================================
//  ModuleSpec —— 模块描述符
//
//  对应原版每个 Module 的 Coordinator 配置。把「介绍页分类 /
//  扫描任务 / 磁贴映射 / DataManager 分类」全部数据化，
//  之后新增一个模块只需要填一张表。
// ============================================================

struct IntroCategory: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let note: String
    var icon: String
    var asset: String = ""

    init(title: String, icon: String, note: String = "", asset: String = "") {
        self.title = title
        self.note = note
        self.icon = icon
        self.asset = asset
    }
}

enum ModuleKind: Sendable {
    case standard       // 走完整 8 屏流程
    case dashboard      // 智能呵护（卡片网格，无 DataManager）
    case spaceLens      // 空间透镜（气泡 + 列表）
    case applications   // 应用管理（应用卡片列表）
    case performance    // 性能（启动项 + 维护任务）
    case toolbox        // 我的工具（工具卡片网格）
    case assistant      // 助手（健康分 + 建议）
    case liveMonitor    // 实时系统监控（AClean 级实时看板）
}

typealias ScanProgressCB = @Sendable (Double, String) -> Void
typealias ScanFoundCB = @Sendable ([Node]) -> Void
typealias ScanTreeBuilder = @Sendable (@escaping ScanProgressCB, @escaping ScanFoundCB, @escaping StopCheck) -> [Node]
typealias StopCheck = @Sendable () -> Bool

struct ModuleSpec {
    let key: String
    let title: String
    let icon: String
    let accent: Color
    let accent2: Color
    var kind: ModuleKind = .standard

    // 介绍页
    let sidebarSubtitle: String
    let introSubtitle: String
    let introCategories: [IntroCategory]

    // 扫描
    let scanSubtitle: String
    let scanDetail: String
    let primaryAction: String
    let emptyTitle: String
    let emptySubtitle: String

    // DataManager 第一列
    let filterOrder: [String]
    let filterIcons: [String: String]

    // 逻辑
    let buildTree: ScanTreeBuilder
    let tiles: ([Node]) -> [Tile]

    init(key: String, title: String, icon: String, accent: Color, accent2: Color,
         kind: ModuleKind = .standard, sidebarSubtitle: String, introSubtitle: String,
         introCategories: [IntroCategory], scanSubtitle: String, scanDetail: String = "",
         primaryAction: String, emptyTitle: String, emptySubtitle: String,
         filterOrder: [String], filterIcons: [String: String],
         buildTree: @escaping ScanTreeBuilder,
         tiles: @escaping ([Node]) -> [Tile]) {
        self.key = key
        self.title = title
        self.icon = icon
        self.accent = accent
        self.accent2 = accent2
        self.kind = kind
        self.sidebarSubtitle = sidebarSubtitle
        self.introSubtitle = introSubtitle
        self.introCategories = introCategories
        self.scanSubtitle = scanSubtitle
        self.scanDetail = scanDetail
        self.primaryAction = primaryAction
        self.emptyTitle = emptyTitle
        self.emptySubtitle = emptySubtitle
        self.filterOrder = filterOrder
        self.filterIcons = filterIcons
        self.buildTree = buildTree
        self.tiles = tiles
    }

    var gradient: [Color] { Theme.gradient(accent) }

    /// 极光渐变主色相（度），取自原版「模块 ↔ 素材」映射表
    var hue: Double { ModuleArtRegistry.art(key).hue }
}

// MARK: - 通用磁贴生成

enum Tiles {
    /// 按体积从大到小生成磁贴：第一个用横向大磁贴，其余用标准磁贴。
    ///
    /// 标题沿用原版按类别写死的文案（"已发现 %@ 的系统垃圾"、"已找到 %@ 的 AI 垃圾文件"…），
    /// 所以动词和量词都来自节点自身；没有单独设置时退回通用拼法。
    ///
    /// 聚合规则：`tileKey` 非空的节点会按键合并——原版「系统垃圾」一个磁贴背后是
    /// 十几个扫描组，结果页只呈现一张卡，进 DataManager 才展开。合并时取组内最大的
    /// 体积之和作为磁贴体积，并挑个体积最大的那个组代表文案与图标。
    static func from(_ roots: [Node], accent: Color, action: String,
                     verb: String? = nil) -> [Tile] {
        var buckets: [(key: String, size: Int64, rep: Node, count: Int)] = []
        var index: [String: Int] = [:]

        for g in roots where g.totalSize > 0 || g.tileKey == "trashBins" || g.tags.contains("Trash") || g.tags.contains(L10n.localized(.scannerTrashBins)) {
            let key = g.tileKey.isEmpty ? g.id.uuidString : g.tileKey
            if let i = index[key] {
                buckets[i].size += g.totalSize
                buckets[i].count += 1
                if g.totalSize > buckets[i].rep.totalSize { buckets[i].rep = g }
            } else {
                index[key] = buckets.count
                buckets.append((key, g.totalSize, g, 1))
            }
        }

        guard !buckets.isEmpty else {
            return [Tile(icon: "checkmark.circle", title: L10n.localized(.noCleanableItemsDiscovered),
                         detail: L10n.localized(.yourMacIsCrystalClean), accent: accent,
                         actionTitle: action, enabled: false)]
        }

        // 磁贴排列 标准布局：
        // 1. 若存在 "systemJunk"，始终将其置于第 0 位（左侧纵向大卡片 LargeVerticalTileCard，三卫星图环绕）
        // 2. 其余磁贴按体积从大到小排序，排在右侧 2x2 网格中（最多 4 张标准卡片，合计 5 张卡片）
        var sorted: [(key: String, size: Int64, rep: Node, count: Int)] = []
        if let sysIdx = buckets.firstIndex(where: { $0.key == "systemJunk" }) {
            sorted.append(buckets[sysIdx])
            var rest = buckets
            rest.remove(at: sysIdx)
            rest.sort { $0.size > $1.size }
            sorted.append(contentsOf: rest.prefix(4))
        } else {
            sorted = Array(buckets.sorted { $0.size > $1.size }.prefix(5))
        }

        let effectiveVerb = verb ?? L10n.localized(.verbFound)
        return sorted.enumerated().map { i, b in
            let g = b.rep
            let name = g.tileName.isEmpty ? g.name : g.tileName
            let q = g.tileQuantifier.isEmpty ? L10n.localized(.tileJunkQuantifier) : g.tileQuantifier
            let v = g.tileVerb.isEmpty ? effectiveVerb : g.tileVerb
            let note = g.tileNote.isEmpty ? g.note : g.tileNote
            let icon = g.tileIcon.isEmpty ? g.icon : g.tileIcon
            let satellites: [String] = i == 0 ? [
                "cm_detail_system-junk_language-files", "cm_detail_system-junk_user-cache-files", "cm_detail_system-junk_user-log-files"
            ] : []
            let titleText = b.size > 0 ? "\(v) \(Fmt.size(b.size)) \(q)\(name)" : L10n.localized(.clearedNameFormat, name)
            let detailText = b.size > 0 ? note : L10n.localized(.noCleanupNeededNow)
            return Tile(size: i == 0 ? .largeVertical : .standard,
                        icon: icon,
                        title: titleText,
                        detail: detailText,
                        accent: accent,
                        actionTitle: L10n.localized(.actionInspect),
                        primaryActionTitle: b.size > 0 ? (action.isEmpty ? L10n.localized(.actionCleanNow) : action) : nil,
                        enabled: true,
                        category: g.tags.first ?? name,
                        emptyTitle: L10n.localized(.emptyFoundNameFormat, name),
                        satelliteIcons: satellites,
                        sizeValue: b.size)
        }
    }
}

// MARK: - 注册表

enum ModuleRegistry {

    static var healthCheckSpec: ModuleSpec {
        ModuleSpec(
            key: "healthCheck",
            title: L10n.localized(.moduleHealthCheck),
            icon: "shield.checkerboard",
            accent: Color.teal,
            accent2: Color.blue,
            kind: .dashboard,
            sidebarSubtitle: L10n.localized(.moduleHealthCheckSubtitle),
            introSubtitle: L10n.localized(.moduleHealthCheckSubtitle),
            introCategories: [],
            scanSubtitle: "",
            primaryAction: "",
            emptyTitle: "",
            emptySubtitle: "",
            filterOrder: [],
            filterIcons: [:],
            buildTree: { _, _, _ in [] },
            tiles: { _ in [] }
        )
    }

    static var liveMonitorSpec: ModuleSpec {
        ModuleSpec(
            key: "liveMonitor",
            title: L10n.localized(.moduleLiveMonitor),
            icon: "gauge.with.dots.needle.67percent",
            accent: Color.blue,
            accent2: Color.cyan,
            kind: .liveMonitor,
            sidebarSubtitle: L10n.localized(.liveMonitorModuleSummary),
            introSubtitle: L10n.localized(.liveMonitorModuleDesc),
            introCategories: [],
            scanSubtitle: "",
            primaryAction: "",
            emptyTitle: "",
            emptySubtitle: "",
            filterOrder: [],
            filterIcons: [:],
            buildTree: { _, _, _ in [] },
            tiles: { _ in [] }
        )
    }

    /// 简洁模式左侧导航栏展示的 6 大核心模块（按 ModuleKey.sidebar 顺序）
    static var conciseModules: [ModuleSpec] {
        ModuleKey.sidebar.map { spec(for: $0.rawValue) }
    }

    static var all: [ModuleSpec] {
        [
            healthCheckSpec,
            JunkModule.spec,
            PerformanceModule.spec,
            ApplicationsModule.spec,
            SpaceLensModule.spec,
            OrganizeModule.spec,
            liveMonitorSpec,
            SmartCareModule.spec,
            ToolboxModule.spec,
            AssistantModule.spec,
        ]
    }

    static func spec(for key: String) -> ModuleSpec {
        if key == "healthCheck" { return healthCheckSpec }
        if key == "liveMonitor" { return liveMonitorSpec }
        return all.first { $0.key == key } ?? conciseModules[0]
    }
}
