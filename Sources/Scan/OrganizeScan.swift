import SwiftUI

// ============================================================
//  整理杂乱 Organize / MyClutter
//
//  介绍页分类：大型文件 / 重复文件 / 下载项
//  子流程：LAOF · DuplicateFinder · Downloads
// ============================================================

enum OrganizeModule {

    static var spec: ModuleSpec { makeSpec() }
    private static func makeSpec() -> ModuleSpec { ModuleSpec(
        key: "organize",
        title: L10n.localized(.moduleDeclutter),
        icon: "arrow.down.circle",
        accent: Theme.organize,
        accent2: Color(red: 0.98, green: 0.60, blue: 0.36),
        sidebarSubtitle: L10n.localized(.moduleOrganizeSubtitle),
        introSubtitle: L10n.localized(.moduleOrganizeDesc),
        introCategories: [
            IntroCategory(title: L10n.localized(.sectionLargeFiles), icon: "externaldrive",
                          note: L10n.localized(.findLargeOrLongUnusedFiles),
                          asset: "cm_intro_large-old-files"),
            IntroCategory(title: L10n.localized(.declutterDuplicates), icon: "doc.on.doc",
                          note: L10n.localized(.cleanExactDuplicateFilesDesc),
                          asset: "cm_intro_duplicates"),
            IntroCategory(title: L10n.localized(.similarImages), icon: "photo.on.rectangle.angled",
                          note: L10n.localized(.findSimilarPhotosKeepBestDesc),
                          asset: "cm_intro_similar-files"),
            IntroCategory(title: L10n.localized(.declutterDownloads), icon: "arrow.down.circle",
                          note: L10n.localized(.reviewAndDeleteDownloadsDesc),
                          asset: "cm_intro_downloads"),
        ],
        scanSubtitle: L10n.localized(.statusScanningDuplicatesAndUnneededFilesPrompt),
        primaryAction: L10n.localized(.actionRemoveNow),
        emptyTitle: L10n.localized(.howDoYouKeepItSoClean),
        emptySubtitle: L10n.localized(.noClutterDiscoveredPrompt),
        filterOrder: [
            L10n.localized(.declutterLargeAndOldFiles),
            L10n.localized(.declutterDuplicates),
            L10n.localized(.similarImages),
            L10n.localized(.declutterDownloads),
            L10n.localized(.declutterInstallers)
        ],
        filterIcons: [
            L10n.localized(.declutterLargeAndOldFiles): "externaldrive",
            L10n.localized(.declutterDuplicates): "doc.on.doc",
            L10n.localized(.similarImages): "photo.on.rectangle.angled",
            L10n.localized(.declutterDownloads): "arrow.down.circle",
            L10n.localized(.declutterInstallers): "shippingbox",
        ],
        buildTree: { progress, onFound, stopped in
            var out: [Node] = []
            var seenPaths = Set<String>()

            let laofTag = L10n.localized(.declutterLargeAndOldFiles)
            let dupTag = L10n.localized(.declutterDuplicates)
            let dlTag = L10n.localized(.declutterDownloads)
            let simTag = L10n.localized(.similarImages)
            let instTag = L10n.localized(.declutterInstallers)

            func recordPaths(in group: ScanGroup) {
                for item in group.items {
                    seenPaths.insert(item.url.resolvingSymlinksInPath().path)
                }
            }

            func filterUnseenItems(in group: ScanGroup) -> ScanGroup? {
                let filtered = group.items.filter { item in
                    let canon = item.url.resolvingSymlinksInPath().path
                    return !seenPaths.contains(canon)
                }
                guard !filtered.isEmpty else { return nil }
                var copy = group
                copy.items = filtered
                return copy
            }

            // 1) 安装包（优先归类明确的安装包，避免与下载项/大文件三处重复统计）
            progress(0.05, L10n.localized(.statusFindingAbandonedInstallersPrompt))
            if let inst = OrganizeEngine.scanInstallers(
                progress: { p, s in progress(0.05 + p * 0.10, s) }, stopped: stopped) {
                recordPaths(in: inst)
                let n = Node.group(from: inst, tags: [instTag, "Installers"])
                out.append(n)
                onFound([n])
            }
            if stopped() { return out }

            // 2) 重复文件（保持完整簇结构，并登记已归入重复簇的文件路径）
            progress(0.15, L10n.localized(.statusComparingDuplicateFilesPrompt))
            let dups = OrganizeEngine.duplicates(progress: { p, s in progress(0.15 + p * 0.30, s) },
                                                 stopped: stopped)
            var dupNodes: [Node] = []
            for g in dups {
                if stopped() { return out }
                recordPaths(in: g)
                let n = Node.group(from: g, tags: [dupTag, "Duplicates"])
                out.append(n)
                dupNodes.append(n)
            }
            if !dupNodes.isEmpty { onFound(dupNodes) }
            if stopped() { return out }

            // 3) 相似图片（保持完整相似簇结构）
            progress(0.45, L10n.localized(.statusScanningSimilarPhotosPrompt))
            let similar = OrganizeEngine.similarImages(
                progress: { p, s in progress(0.45 + p * 0.15, s) }, stopped: stopped)
            var simNodes: [Node] = []
            for g in similar {
                if stopped() { return out }
                recordPaths(in: g)
                let n = Node.group(from: g, tags: [simTag, "Similar Images"])
                out.append(n)
                simNodes.append(n)
            }
            if !simNodes.isEmpty { onFound(simNodes) }
            if stopped() { return out }

            // 4) 下载项（剔除已被安装包/重复文件/相似图片认领的文件）
            progress(0.60, L10n.localized(.statusCheckingDownloadsPrompt))
            let dlGroups = DownloadsEngine.leftoverFiles()
            var dlNodes: [Node] = []
            for rawGroup in dlGroups {
                if stopped() { return out }
                guard let g = filterUnseenItems(in: rawGroup) else { continue }
                recordPaths(in: g)
                let n = Node.group(from: g, tags: [dlTag, "Downloads"])
                out.append(n)
                dlNodes.append(n)
            }
            if !dlNodes.isEmpty { onFound(dlNodes) }
            if stopped() { return out }

            // 5) 大型和旧文件（剔除已在上述专项分类中出现过的文件）
            progress(0.75, L10n.localized(.statusFindingLargeAndOldFilesPrompt))
            if let rawLaof = OrganizeEngine.largeAndOld(
                thresholdBytes: AppConfigStore.shared.currentLargeFileThresholdBytes,
                oldMonths: AppConfigStore.shared.currentOldFileMonths,
                progress: { p, s in progress(0.75 + p * 0.25, s) },
                stopped: stopped
            ),
               let laof = filterUnseenItems(in: rawLaof) {
                var nodes: [Node] = []
                for g in OrganizeEngine.largeAndOldByKind(laof) {
                    if stopped() { return out }
                    recordPaths(in: g)
                    let n = Node.group(from: g, tags: [laofTag, "Large & Old Files"])
                    out.append(n)
                    nodes.append(n)
                }
                if !nodes.isEmpty { onFound(nodes) }
            }
            progress(1.0, L10n.localized(.completed))
            return out
        },
        tiles: { roots in
            var tiles: [Tile] = []
            let laofTag = L10n.localized(.declutterLargeAndOldFiles)
            let dupTag = L10n.localized(.declutterDuplicates)
            let simTag = L10n.localized(.similarImages)
            let dlTag = L10n.localized(.declutterDownloads)
            let instTag = L10n.localized(.declutterInstallers)

            let laof = roots.filter { $0.tags.contains(laofTag) || $0.tags.contains("Large & Old Files") }
            let dups = roots.filter { $0.tags.contains(dupTag) || $0.tags.contains("Duplicates") }
            let similar = roots.filter { $0.tags.contains(simTag) || $0.tags.contains("Similar Images") }
            let dls = roots.filter { $0.tags.contains(dlTag) || $0.tags.contains("Downloads") }
            let insts = roots.filter { $0.tags.contains(instTag) || $0.tags.contains("Installers") }

            let dupCount = dups.reduce(0) { $0 + $1.leafCount }
            let laofSize = laof.reduce(0) { $0 + $1.totalSize }
            let simCount = similar.reduce(0) { $0 + $1.leafCount }
            let dlCount = dls.reduce(0) { $0 + $1.leafCount }
            let instCount = insts.reduce(0) { $0 + $1.leafCount }

            var primaryKey: String = ""

            // 1. 动态推选主大卡片（首张纵向大卡片 .largeVertical，配置原版 3D 图与三图簇）
            if dupCount > 0 {
                primaryKey = "duplicates"
                tiles.append(Tile(size: .largeVertical,
                                  icon: "cm_catbig_duplicates",
                                  title: L10n.localized(.discoveredDuplicatesCountFormat, dupCount),
                                  detail: L10n.localized(.duplicatesRetentionRuleDesc),
                                  accent: Theme.organize,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: dupTag,
                                  satelliteIcons: ["cm_cat_large-old-files",
                                                   "cm_catbig_duplicates",
                                                   "cm_cat_similar-files"]))
            } else if laofSize > 0 {
                primaryKey = "largeAndOld"
                tiles.append(Tile(size: .largeVertical,
                                  icon: "cm_catbig_large-old-files",
                                  title: L10n.localized(.foundLargeAndOldFilesSizeFormat, Fmt.size(laofSize)),
                                  detail: L10n.localized(.considerRemovingForgottenLargeFilesDesc),
                                  accent: Theme.organize,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: laofTag,
                                  satelliteIcons: ["cm_cat_downloads",
                                                   "cm_catbig_large-old-files",
                                                   "cm_cat_similar-files"]))
            } else if simCount > 0 {
                primaryKey = "similar"
                tiles.append(Tile(size: .largeVertical,
                                  icon: "cm_catbig_similar-files",
                                  title: L10n.localized(.discoveredSimilarPhotosCountFormat, simCount),
                                  detail: L10n.localized(.reviewSimilarPhotosKeepBestDesc),
                                  accent: Theme.organize,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: simTag,
                                  satelliteIcons: ["cm_cat_downloads",
                                                   "cm_catbig_similar-files",
                                                   "cm_cat_large-old-files"]))
            } else if dlCount > 0 {
                primaryKey = "downloads"
                tiles.append(Tile(size: .largeVertical,
                                  icon: "cm_catbig_downloads",
                                  title: L10n.localized(.discoveredDownloadsCountFormat, dlCount),
                                  detail: L10n.localized(.reviewAndDeleteDownloadsSaveSpaceDesc),
                                  accent: Theme.organize,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: dlTag,
                                  satelliteIcons: ["cm_cat_large-old-files",
                                                   "cm_catbig_downloads",
                                                   "cm_cat_similar-files"]))
            }

            // 2. 次级标准卡片（除主卡片之外的各项，绑定原生 3D 图标）
            if primaryKey != "largeAndOld" && laofSize > 0 {
                tiles.append(Tile(icon: "cm_cat_large-old-files",
                                  title: L10n.localized(.foundLargeAndOldFilesSizeFormat, Fmt.size(laofSize)),
                                  detail: L10n.localized(.largeOrYearUnusedFilesDesc),
                                  accent: Theme.organize,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: laofTag))
            }

            if primaryKey != "duplicates" && dupCount > 0 {
                tiles.append(Tile(icon: "cm_cat_duplicates",
                                  title: L10n.localized(.discoveredDuplicatesCountFormat, dupCount),
                                  detail: L10n.localized(.duplicatesRetentionRuleDesc),
                                  accent: Theme.organize,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: dupTag))
            }

            if primaryKey != "similar" && simCount > 0 {
                tiles.append(Tile(icon: "cm_cat_similar-files",
                                  title: L10n.localized(.discoveredSimilarPhotosCountFormat, simCount),
                                  detail: L10n.localized(.keepNewestPhotoDeleteOthersDesc),
                                  accent: Theme.organize,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: simTag))
            }

            if primaryKey != "downloads" && dlCount > 0 {
                tiles.append(Tile(icon: "cm_cat_downloads",
                                  title: L10n.localized(.discoveredDownloadsCountFormat, dlCount),
                                  detail: L10n.localized(.downloadsFromBrowsersAndChatsDesc),
                                  accent: Theme.organize,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: dlTag))
            }

            if instCount > 0 {
                tiles.append(Tile(icon: "shippingbox",
                                  title: L10n.localized(.discoveredAbandonedInstallersCountFormat, instCount),
                                  detail: L10n.localized(.abandonedInstallersDesc),
                                  accent: Theme.organize,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: instTag))
            }

            return tiles
        }
    ) }
}
