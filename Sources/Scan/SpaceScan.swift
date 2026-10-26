import SwiftUI

// ============================================================
//  空间透镜 SpaceLens
//
//  原版：气泡图 + 列表双视图，点击气泡下钻，底部指示器
//  显示「已用 / 可用 / 已勾选 / 可清理」，移除前有独立确认屏。
// ============================================================

enum SpaceLensModule {

    static var spec: ModuleSpec { makeSpec() }
    private static func makeSpec() -> ModuleSpec { ModuleSpec(
        key: "spaceLens",
        title: L10n.localized(.moduleSpaceLensTitle),
        icon: "chart.pie",
        accent: Theme.space,
        accent2: Color(red: 0.20, green: 0.84, blue: 0.86),
        kind: .spaceLens,
        sidebarSubtitle: L10n.localized(.moduleSpaceLensSubtitle),
        introSubtitle: L10n.localized(.moduleSpaceLensDesc),
        introCategories: [
            IntroCategory(title: L10n.localized(.sectionStorageDistributionMap), icon: "chart.pie",
                          note: L10n.localized(.checkFolderByFolderWhereSpaceWent),
                          asset: "cm_intro_explore-storage"),
            IntroCategory(title: L10n.localized(.toggleShowHiddenFiles), icon: "eye.slash",
                          note: L10n.localized(.findHiddenLargeFilesAndLeftovers),
                          asset: "cm_intro_reveal-hidden-files"),
            IntroCategory(title: L10n.localized(.sectionLargeFoldersOverview), icon: "folder",
                          note: L10n.localized(.seeFoldersConsumingMostDiskSpace),
                          asset: "cm_intro_review-large-folders"),
        ],
        scanSubtitle: L10n.localized(.visualizingStorageSpacePrompt),
        primaryAction: L10n.localized(.actionRemoveNow),
        emptyTitle: L10n.localized(.notEnoughContentToVisualize),
        emptySubtitle: L10n.localized(.noItemsNeedingAttentionInAreaPrompt),
        filterOrder: [L10n.localized(.fileTypeFolder), L10n.localized(.sectionLargeFiles)],
        filterIcons: [L10n.localized(.fileTypeFolder): "folder", L10n.localized(.sectionLargeFiles): "doc"],
        buildTree: { progress, onFound, stopped in
            // 极速单趟 FTS 扫描 + 实时体积流式推送
            progress(0.02, L10n.localized(.statusBuildingSpaceMapPrompt))

            func fastIcon(for url: URL, isDir: Bool) -> String {
                if isDir { return "folder.fill" }
                let ext = url.pathExtension.lowercased()
                switch ext {
                case "app": return "macwindow"
                case "dmg", "pkg", "zip", "tar", "gz": return "shippingbox"
                case "jpg", "jpeg", "png", "heic", "gif", "webp": return "photo"
                case "mp4", "mov", "avi", "mkv": return "film"
                case "mp3", "m4a", "wav", "aac": return "music.note"
                case "pdf": return "doc.richtext"
                default: return url.hasDirectoryPath ? "folder.fill" : "doc"
                }
            }

            func toNode(_ e: SpaceEngine.Entry, isLive: Bool) -> Node {
                let p = e.url.path
                let displayName = e.customName ?? e.url.lastPathComponent
                let nodeID = Node.stableID(forPath: p)
                let isDir = !e.children.isEmpty || e.url.hasDirectoryPath
                var note = Fmt.size(e.size)
                if !e.notePrefix.isEmpty {
                    note = "\(e.notePrefix)\(note)"
                }
                let badge = e.isCalculating ? L10n.localized(.badgeCalculating) : nil
                let isRootFolder = (AppConfig.Paths.topLevelContainers.contains(p.lowercased()) || p == FileUtil.home.path)
                let folderTag = L10n.localized(.fileTypeFolder)
                if e.children.isEmpty {
                    return Node(id: nodeID,
                                name: displayName,
                                url: e.url,
                                icon: fastIcon(for: e.url, isDir: isDir),
                                note: note,
                                safety: .caution,
                                size: e.size,
                                isGroup: isDir,
                                locked: isRootFolder,
                                badge: badge,
                                tags: isDir ? [folderTag, "Folder"] : [],
                                meta: isLive ? [] : [(L10n.localized(.labelSize), Fmt.size(e.size)), (L10n.localized(.metaPath), p)],
                                captureIdentity: !isLive)
                }
                var kids = e.children.map { toNode($0, isLive: isLive) }
                if e.otherBytes > 1024 * 1024 || e.omittedCount > 0 {
                    let baseOtherNote = L10n.localized(.unexpandedDirectSmallItemsFormat, Fmt.size(e.otherBytes))
                    let otherNote = e.omittedCount > 0
                        ? "\(baseOtherNote) · \(L10n.format(.organizeCandidateLimitTruncatedFormat, e.children.count, e.children.count + e.omittedCount))"
                        : baseOtherNote
                    kids.append(Node(id: Node.stableID(forPath: p + "/__other__"),
                                     name: L10n.localized(.otherFilesDirect),
                                     url: nil,
                                     icon: "doc",
                                     note: otherNote,
                                     safety: .safe,
                                     size: e.otherBytes,
                                     isGroup: false,
                                     ignorable: false,
                                     locked: true,
                                     captureIdentity: false))
                }
                return Node(id: nodeID,
                            name: displayName,
                            url: e.url,
                            icon: "folder.fill",
                            note: note,
                            safety: .caution,
                            size: e.size,
                            children: kids,
                            isGroup: true,
                            locked: isRootFolder,
                            badge: badge,
                            tags: [folderTag, "Folder"],
                            meta: isLive ? [] : [(L10n.localized(.labelSize), Fmt.size(e.size)), (L10n.localized(.metaPath), p)],
                            captureIdentity: !isLive)
            }

            let result = SpaceEngine.analyzeHome(
                minLargeFile: AppConfig.ScanThresholds.spaceLensLargeFileBytes,
                progress: { p, s in progress(0.02 + p * 0.94, s) },
                onPartialUpdate: { liveFolders in
                    guard !stopped() else { return }
                    let liveNodes = autoreleasepool {
                        liveFolders.map { toNode($0, isLive: true) }
                    }
                    if !liveNodes.isEmpty {
                        onFound(liveNodes)
                    }
                },
                stopped: stopped
            )

            let roots: [Node] = autoreleasepool {
                result.folders.map { toNode($0, isLive: false) }
            }
            if stopped() { return roots }
            onFound(roots)
            progress(1, L10n.localized(.completed))
            return roots
        },
        // 空间透镜专属 3D 拟真磁贴（彻底消除垃圾清理语言包错配）
        tiles: { roots in
            var tiles: [Tile] = []
            let totalScanned = roots.reduce(0) { $0 + $1.totalSize }
            let folderTag = L10n.localized(.fileTypeFolder)
            let largeFilesTag = L10n.localized(.sectionLargeFiles)
            let folders = roots.filter { $0.tags.contains(folderTag) || $0.tags.contains("Folder") }
            let bigFiles = roots.first { $0.tags.contains(largeFilesTag) || $0.tags.contains("Large Files") }

            // 1. 主大卡片（.largeVertical，绑定 3D 大图 cm_hero_spaceLens 与透镜三图簇）
            tiles.append(Tile(size: .largeVertical,
                              icon: "cm_hero_spaceLens",
                              title: L10n.localized(.analyzedDiskSpaceUsageFormat, Fmt.size(totalScanned)),
                              detail: L10n.localized(.moduleSpaceLensDesc),
                              accent: Theme.space,
                              actionTitle: L10n.localized(.actionReviewAndRemove),
                              category: folderTag,
                              satelliteIcons: ["cm_intro_review-large-folders",
                                               "cm_hero_spaceLens",
                                               "cm_intro_reveal-hidden-files"]))

            // 2. 次级卡片 1：大文件夹概览
            if let topFolder = folders.max(by: { $0.totalSize < $1.totalSize }) {
                tiles.append(Tile(icon: "cm_intro_review-large-folders",
                                  title: L10n.localized(.sectionLargeFoldersOverview),
                                  detail: L10n.localized(.topFolderConsumesSpaceFormat, topFolder.name, Fmt.size(topFolder.totalSize)),
                                  accent: Theme.space,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: folderTag))
            }

            // 3. 次级卡片 2：独立大文件
            if let big = bigFiles, big.totalSize > 0 {
                tiles.append(Tile(icon: "cm_intro_explore-storage",
                                  title: L10n.localized(.sectionStandaloneLargeFiles),
                                  detail: L10n.localized(.bigFilesCountAndSizeFormat, big.children.count, Fmt.size(big.totalSize)),
                                  accent: Theme.space,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: largeFilesTag))
            }

            // 4. 次级卡片 3：显示被隐藏的文件
            let hiddenCount = roots.reduce(0) { acc, r in
                acc + r.children.filter { $0.name.hasPrefix(".") }.count
            }
            tiles.append(Tile(icon: "cm_intro_reveal-hidden-files",
                              title: L10n.localized(.toggleShowHiddenFiles),
                              detail: hiddenCount > 0 ? L10n.localized(.discoveredHiddenResourcesFormat, hiddenCount) : L10n.localized(.hiddenFilesAutomaticallyIncluded),
                              accent: Theme.space,
                              actionTitle: L10n.localized(.actionInspect),
                              category: folderTag))

            return tiles
        }
    ) }
}
