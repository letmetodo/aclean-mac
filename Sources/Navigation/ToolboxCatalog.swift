import SwiftUI

// ============================================================
//  我的工具 Toolbox
//
//  原版：工具卡片集合 + 搜索 + 收藏。每张卡点击后进入
//  该工具对应的子流程。本质上是「把已有模块的子流程以
//  卡片形式暴露出来」，复用度极高。
// ============================================================

struct ToolboxEntry: Identifiable, Hashable {
    var id: String { "\(moduleKey)/\(category)/\(titleKey.rawValue)" }
    var titleKey: L10nKey
    var subtitleKey: L10nKey
    var title: String { L10n.string(titleKey) }
    var subtitle: String { L10n.string(subtitleKey) }
    var icon: String
    var asset: String = ""
    var accent: Color
    var moduleKey: String
    var category: String = ""
    /// 搜索关键词
    var keywords: String = ""
}

typealias ToolItem = ToolboxEntry

enum ToolboxModule {

    static let tools: [ToolItem] = [
        ToolItem(titleKey: .toolboxLiveMonitorCardTitle, subtitleKey: .toolboxLiveMonitorCardDesc,
                 icon: "gauge.badge.bolt", asset: "cm_intro_maintenance-tasks", accent: Color.blue,
                 moduleKey: "liveMonitor", category: L10n.localized(.moduleLiveMonitor),
                 keywords: "live monitor cpu memory disk network"),
        ToolItem(titleKey: .toolboxAppUninstallerCardTitle, subtitleKey: .toolboxAppUninstallerCardDesc,
                 icon: "trash.slash", asset: "cm_intro_uninstaller", accent: Theme.apps,
                 moduleKey: "applications", category: L10n.localized(.filterAllApplications),
                 keywords: "uninstall apps leftovers"),
        ToolItem(titleKey: .toolboxLargeFilesCardTitle, subtitleKey: .toolboxLargeFilesCardDesc,
                 icon: "externaldrive.badge.exclamationmark", asset: "cm_intro_large-old-files", accent: Theme.organize,
                 moduleKey: "organize", category: L10n.localized(.declutterLargeAndOldFiles),
                 keywords: "large old files"),
        ToolItem(titleKey: .toolboxDuplicatesCardTitle, subtitleKey: .toolboxDuplicatesCardDesc,
                 icon: "doc.on.doc", asset: "cm_intro_duplicates", accent: Theme.organize,
                 moduleKey: "organize", category: L10n.localized(.declutterDuplicates),
                 keywords: "duplicate files"),
        ToolItem(titleKey: .toolboxDownloadsCardTitle, subtitleKey: .toolboxDownloadsCardDesc,
                 icon: "arrow.down.circle", asset: "cm_intro_downloads", accent: Theme.organize,
                 moduleKey: "organize", category: L10n.localized(.declutterDownloads),
                 keywords: "downloads"),
        ToolItem(titleKey: .toolboxMaintenanceScriptsCardTitle, subtitleKey: .toolboxMaintenanceScriptsCardDesc,
                 icon: "wrench.and.screwdriver", asset: "cm_intro_maintenance-tasks", accent: Theme.perform,
                 moduleKey: "performance", category: L10n.localized(.maintenanceTasks),
                 keywords: "maintenance scripts"),
        ToolItem(titleKey: .toolboxStartupItemsCardTitle, subtitleKey: .toolboxStartupItemsCardDesc,
                 icon: "power", asset: "cm_intro_login-items", accent: Theme.perform,
                 moduleKey: "performance", category: L10n.localized(.loginItems),
                 keywords: "login startup items"),
        ToolItem(titleKey: .backgroundItems, subtitleKey: .toolboxDaemonsCardDesc,
                 icon: "gearshape.2", asset: "cm_intro_launch-agents", accent: Theme.perform,
                 moduleKey: "performance", category: L10n.localized(.backgroundItems),
                 keywords: "background daemons agents"),
        ToolItem(titleKey: .moduleSpaceLensTitle, subtitleKey: .toolboxSpaceLensCardDesc,
                 icon: "chart.pie", asset: "cm_intro_explore-storage", accent: Theme.space,
                 moduleKey: "spaceLens", category: L10n.localized(.fileTypeFolder),
                 keywords: "space lens storage"),
        ToolItem(titleKey: .toolboxSystemJunkCardTitle, subtitleKey: .toolboxSystemJunkCardDesc,
                 icon: "trash", asset: "cm_intro_system-junk", accent: Theme.junk,
                 moduleKey: "junk", category: L10n.localized(.systemJunk),
                 keywords: "system junk caches logs"),
        ToolItem(titleKey: .scannerAiClutterFiles, subtitleKey: .toolboxAiClutterCardDesc,
                 icon: "sparkles", asset: "cm_intro_ai-clutter", accent: Theme.smart,
                 moduleKey: "junk", category: L10n.localized(.scannerAiClutterFiles),
                 keywords: "ai clutter models"),
    ]

    static var spec: ModuleSpec { ModuleSpec(
        key: "toolbox",
        title: L10n.localized(.moduleToolboxTitle),
        icon: "square.grid.3x3",
        accent: Theme.tool,
        accent2: Color(red: 0.55, green: 0.62, blue: 0.72),
        kind: .toolbox,
        sidebarSubtitle: L10n.localized(.moduleToolboxSubtitle),
        introSubtitle: L10n.localized(.moduleToolboxDesc),
        introCategories: [
            IntroCategory(title: L10n.localized(.toolboxCategoryCleaningTitle), icon: "trash",
                          note: L10n.localized(.toolboxCategoryCleaningSubtitle),
                          asset: "cm_intro_system-junk"),
            IntroCategory(title: L10n.localized(.toolboxCategoryPerformanceTitle), icon: "speedometer",
                          note: L10n.localized(.toolboxCategoryPerformanceSubtitle),
                          asset: "cm_intro_maintenance-tasks"),
        ],
        scanSubtitle: L10n.localized(.statusPreparingToolsPrompt),
        primaryAction: L10n.localized(.actionScan),
        emptyTitle: L10n.localized(.noRelevantToolsFound),
        emptySubtitle: L10n.localized(.tryDifferentKeywordsPrompt),
        filterOrder: [],
        filterIcons: [:],
        buildTree: { _, _, _ in [] },
        tiles: { _ in [] }
    ) }
}
