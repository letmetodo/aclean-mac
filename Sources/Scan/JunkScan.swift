import SwiftUI

// ============================================================
//  垃圾清理 JunkCleanup
//
//  介绍页分类：系统垃圾 / 废纸篓 / AI 垃圾文件 (100% 遵守 DNA 宪章，严禁邮件清理)
//  子流程：SystemJunk · TrashBin · AIClutter
// ============================================================

enum JunkModule {

    static var spec: ModuleSpec { makeSpec() }
    private static func makeSpec() -> ModuleSpec { ModuleSpec(
        key: "junk",
        title: L10n.localized(.moduleJunkAlt),
        icon: "trash",
        accent: Theme.junk,
        accent2: Color(red: 0.99, green: 0.70, blue: 0.26),
        sidebarSubtitle: L10n.localized(.cleanRedundantSystemFiles),
        introSubtitle: L10n.localized(.cleanRedundantSystemFilesForPeakPerformanceAndFreeUpDiskSpace),
        introCategories: [
            IntroCategory(title: L10n.localized(.systemJunk), icon: "gearshape.2",
                          note: L10n.localized(.removeRedundantFilesThatWasteSpaceAndSlowDownYourMac),
                          asset: "cm_intro_system-junk"),
            IntroCategory(title: L10n.localized(.scannerAiClutterFiles), icon: "sparkles",
                          note: L10n.localized(.cleanAiToolCachesLogsAndIdleLocalModelsToReclaimStorage),
                          asset: "cm_intro_ai-clutter"),
            IntroCategory(title: L10n.localized(.scannerTrashBins), icon: "trash",
                          note: L10n.localized(.emptyAllActiveTrashBinsAcrossYourMac),
                          asset: "cm_intro_trash-bins"),
        ],
        // 原版 scan_progress_title / _subtitle 拆成两行显示
        scanSubtitle: L10n.localized(.lookingForJunkFiles),
        scanDetail: L10n.localized(.scanningForSpaceWastingFilesOnYourStorage),
        primaryAction: L10n.localized(.actionCleanNow),
        emptyTitle: L10n.localized(.yourMacIsCrystalClean),
        emptySubtitle: L10n.localized(.noItemsRequiringCleanupWereFoundOnYourSystem),
        filterOrder: [L10n.localized(.filterAllJunk), L10n.localized(.systemJunk), L10n.localized(.scannerAiClutterFiles), L10n.localized(.scannerTrashBins)],
        filterIcons: [
            L10n.localized(.filterAllJunk): "square.grid.2x2",
            L10n.localized(.systemJunk): "gearshape.2",
            L10n.localized(.scannerAiClutterFiles): "sparkles",
            L10n.localized(.scannerTrashBins): "trash",
        ],
        buildTree: { progress, onFound, stopped in
            JunkDiscoveryRegistry.shared.resetRunRecords()
            if !KnowledgeBaseManager.shared.authored.loaded {
                IOScanContext.recordDegradation(
                    .ruleDatabaseUnavailable,
                    issue: L10n.localized(.ruleDatabaseUnavailableBanner)
                )
            } else {
                _ = KnowledgeBaseManager.shared.authored.auditRuleScanEntries()
            }
            var out: [Node] = []
            var deduplicator = RuleAwareDeduplicator()

            // 1. 先执行 AI 专有扫描器，使 AI 工具的特定缓存优先归入 AI 分类，避免被通用 Caches 吞并或重复计算
            if !stopped() {
                _ = AIClutterEngine.scan(
                    progress: { p, s in progress(p * 0.16, s) },
                    onGroupFound: { g in
                        if stopped() { return }
                        let changed = deduplicator.acceptGroup(
                            g,
                            tags: [L10n.localized(.scannerAiClutterFiles), "AI Clutter Files"],
                            into: &out
                        )
                        if !changed.isEmpty {
                            onFound(changed)
                        }
                    }
                )
            }
            // 2. 执行系统与开发者垃圾引擎扫描，通过规则感知去重器完成跨分类去重与父子规则裁决
            if !stopped() {
                _ = JunkEngine.scan(
                    progress: { p, s in progress(0.16 + p * 0.74, s) },
                    isStopped: stopped,
                    deduplicateGroups: false,
                    onGroupFound: { g in
                        if stopped() { return }
                        let cat = ScanCategory(engineTitle: g.title)
                        let changed = deduplicator.acceptGroup(
                            g,
                            tags: [cat.localizedTitle],
                            into: &out
                        )
                        if !changed.isEmpty {
                            onFound(changed)
                        }
                    }
                )
            }
            if !stopped() {
                progress(0.92, L10n.localized(.scanOrphanLeftoversPrompt))
                let orphanGroups = OrphanFinderEngine.scanOrphanNodes(stopped: stopped)
                for og in orphanGroups {
                    if stopped() { break }
                    let changed = deduplicator.acceptNode(og, into: &out) { deduplicatedNode in
                        deduplicatedNode.children = deduplicatedNode.children.map { child in
                            var c = child
                            c.autoSelected = false
                            c.selectionRestrictions.insert(.productPolicy)
                            return c
                        }
                        deduplicatedNode.size = deduplicatedNode.children.reduce(0) { $0 + $1.totalSize }
                        deduplicatedNode.autoSelected = false
                        deduplicatedNode.selectionRestrictions.insert(.productPolicy)
                    }
                    if !changed.isEmpty {
                        onFound(changed)
                    }
                }
            }
            return out
        },
        tiles: { Tiles.from($0, accent: Theme.junk, action: L10n.localized(.actionCleanNow)) }
    ) }
}
