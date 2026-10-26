import SwiftUI

// ============================================================
//  智能呵护 SmartCare
//
//  原版：卡片网格，每张卡对应一个子模块，显示四种状态
//  （found / notFound / runEmpty / runStopped），
//  一键执行时按顺序跑所有已勾选的卡片，最后给出总结果。
// ============================================================

enum SmartCareModule {

    static var spec: ModuleSpec { ModuleSpec(
        key: "smartCare",
        title: L10n.localized(.moduleSmartCare),
        icon: "wand.and.stars",
        accent: Theme.smart,
        accent2: Color(red: 0.60, green: 0.38, blue: 0.96),
        kind: .dashboard,
        sidebarSubtitle: L10n.localized(.moduleSmartCareSubtitle),
        introSubtitle: L10n.localized(.moduleSmartCareDesc),
        introCategories: [
            IntroCategory(title: L10n.localized(.categoryQuickScanTitle), icon: "bolt.fill",
                          note: L10n.localized(.categoryQuickScanDesc),
                          asset: "cm_intro_quick-scan"),
            IntroCategory(title: L10n.localized(.categorySystemTuneupTitle), icon: "speedometer",
                          note: L10n.localized(.categorySystemTuneupDesc),
                          asset: "cm_intro_system-tuneup"),
            IntroCategory(title: L10n.localized(.categorySecurityCheckTitle), icon: "shield.lefthalf.filled",
                          note: L10n.localized(.categorySecurityCheckDesc),
                          asset: "cm_intro_security-check"),
        ],
        scanSubtitle: L10n.localized(.statusScanningMacPrompt),
        primaryAction: L10n.localized(.actionRun),
        emptyTitle: L10n.localized(.yourMacIsCrystalClean),
        emptySubtitle: L10n.localized(.noItemsRequiringCleanupWereFoundOnYourSystem),
        filterOrder: [
            L10n.localized(.moduleJunkAlt),
            L10n.localized(.modulePerformance),
            L10n.localized(.moduleDeclutter),
            L10n.localized(.moduleApplications)
        ],
        filterIcons: [
            L10n.localized(.moduleJunkAlt): "trash",
            L10n.localized(.modulePerformance): "speedometer",
            L10n.localized(.moduleDeclutter): "tray.full",
            L10n.localized(.moduleApplications): "app.badge"
        ],
        buildTree: { _, _, _ in [] },
        tiles: { _ in [] }
    ) }

    /// 智能呵护覆盖的子模块（卡片顺序，收敛至 AppConfig.Defaults）
    static var cards: [String] { AppConfig.Defaults.smartCareCardModuleKeys }
}
