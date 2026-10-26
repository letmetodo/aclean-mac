import SwiftUI

// ============================================================
//  应用管理 Applications
//
//  介绍页分类：应用程序卸载 / 应用程序更新 / 应用残留清理
//  DataManager 第一列是「筛选」，第二列是应用，第三列是残留文件。
// ============================================================

enum ApplicationsModule {

    static var spec: ModuleSpec { makeSpec() }
    private static func makeSpec() -> ModuleSpec { ModuleSpec(
        key: "applications",
        title: L10n.localized(.moduleApplications),
        icon: "square.grid.2x2",
        accent: Theme.apps,
        accent2: Color(red: 0.99, green: 0.45, blue: 0.40),
        kind: .applications,
        sidebarSubtitle: L10n.localized(.moduleApplicationsSubtitle),
        introSubtitle: L10n.localized(.moduleApplicationsDesc),
        introCategories: [
            IntroCategory(title: L10n.localized(.categoryAppUninstallTitle), icon: "trash.slash",
                          note: L10n.localized(.categoryAppUninstallDesc),
                          asset: "cm_intro_uninstaller"),
            IntroCategory(title: L10n.localized(.categoryAppLeftoversTitle), icon: "doc.on.doc",
                          note: L10n.localized(.categoryAppLeftoversDesc),
                          asset: "cm_intro_app-leftovers"),
        ],
        scanSubtitle: L10n.localized(.statusScanningAppsAndLeftoversPrompt),
        primaryAction: L10n.localized(.actionUninstallNow),
        emptyTitle: L10n.localized(.noAppsFoundOnMac),
        emptySubtitle: L10n.localized(.noAppsInstalledOnMac),
        filterOrder: [
            L10n.localized(.filterAllApplications),
            L10n.localized(.filterUnused),
            L10n.localized(.filterNeverOpened),
            L10n.localized(.filter32Bit),
            L10n.localized(.filterSuspicious),
            L10n.localized(.filterSelected),
            L10n.localized(.filterAppStore),
            L10n.localized(.filterAppUpdates),
            L10n.localized(.filterAppLeftovers),
            L10n.localized(.other),
            "Apple", "Google", "MacPaw", "Microsoft"
        ],
        filterIcons: [
            L10n.localized(.filterAllApplications): "square.grid.2x2",
            L10n.localized(.filterUnused): "clock.arrow.circlepath",
            L10n.localized(.filterNeverOpened): "questionmark.folder",
            L10n.localized(.filter32Bit): "nosign",
            L10n.localized(.filterSuspicious): "exclamationmark.shield",
            L10n.localized(.filterSelected): "checkmark.circle",
            L10n.localized(.filterAppStore): "arrow.down.app",
            L10n.localized(.filterAppUpdates): "arrow.triangle.2.circlepath",
            L10n.localized(.filterAppLeftovers): "cm_cat_app-leftovers",
            L10n.localized(.other): "macwindow",
            "Apple": "apple.logo",
            "Google": "g.circle",
            "MacPaw": "pawprint",
            "Microsoft": "window.vertical.closed",
        ],
        buildTree: { progress, onFound, stopped in
            progress(0.05, L10n.localized(.statusReadingInstalledApps))
            let apps = UninstallerEngine.installedApps()
            let allInstances = UninstallerEngine.allInstalledAppInstances
            let total = max(1, apps.count)

            // 每个应用的「残留枚举 + 体积统计」是独立工作，并行处理
            let slots = ScanResultSlots<Node?>(repeating: nil, count: apps.count)
            let counter = ProgressCounter()
            IOScanContext.concurrentPerform(iterations: apps.count) { i in
                if stopped() { return }
                let app = apps[i]
                let node = makeAppNode(app, allApps: allInstances)
                slots[i] = node
                onFound([node])
                let n = counter.increment()
                if n % 3 == 0 {
                    progress(0.05 + 0.75 * Double(n) / Double(total), app.name)
                }
            }

            var roots = slots.values.compactMap { $0 }
            if stopped() { return roots }

            // 扫描程序残留（本体已卸载的遗留文件）
            progress(0.85, L10n.localized(.statusScanningAppLeftovers))
            let orphanNodes = OrphanFinderEngine.scanOrphanNodes(installed: apps, stopped: stopped)
            guard !stopped() else { return roots }
            roots.append(contentsOf: orphanNodes)
            onFound(orphanNodes)

            progress(1, L10n.localized(.completed))
            return roots
        },
        tiles: { roots in
            var tiles: [Tile] = []
            let unusedTag = L10n.localized(.filterUnused)
            let bit32Tag = L10n.localized(.filter32Bit)
            let updatesTag = L10n.localized(.filterAppUpdates)

            let installedRoots = roots.filter { !$0.tags.contains(OrphanFinderEngine.categoryTag) }
            let unused = installedRoots.filter { $0.tags.contains(unusedTag) || $0.tags.contains("Unused") }
            let bit32 = installedRoots.filter { $0.tags.contains(bit32Tag) || $0.tags.contains("32-bit") }

            // 统计总残留体积（已卸载应用遗留的无主残留，与侧栏「程序残留」分类一致）
            let orphanNodes = roots.filter { $0.tags.contains(OrphanFinderEngine.categoryTag) }
            let orphanSize = orphanNodes.reduce(Int64(0)) { $0 + $1.totalSize }
            let appLeftoversSize = installedRoots.reduce(Int64(0)) { acc, app in
                acc + app.children.filter { $0.tags.contains("Leftovers") || $0.tags.contains(L10n.localized(.filterAppLeftovers)) }.reduce(0) { $0 + $1.totalSize }
            }
            // 卡片体积 = 真实扫描值（可为 0），严禁用常量兜底
            let totalLeftoversSize = orphanSize + appLeftoversSize

            // 1. 未使用的应用程序 
            let unusedCount = unused.count
            tiles.append(Tile(size: .standard,
                              icon: "clock.arrow.circlepath",
                              title: L10n.localized(.discoveredUnusedAppsCountFormat, unusedCount),
                              detail: L10n.localized(.unusedAppsDesc),
                              accent: Theme.apps,
                              actionTitle: L10n.localized(.actionInspect),
                              primaryActionTitle: nil, // 原版该卡片无第二操作按钮
                              enabled: true,
                              category: unusedTag,
                              emptyTitle: L10n.localized(.noUnusedAppsFound),
                              sizeValue: unused.reduce(0) { $0 + $1.totalSize }))

            // 2. 不支持的应用程序 
            let unsupportedCount = bit32.count
            tiles.append(Tile(size: .standard,
                              icon: "nosign",
                              title: L10n.localized(.discoveredUnsupportedAppsCountFormat, unsupportedCount),
                              detail: L10n.localized(.unsupported32BitAppsDesc),
                              accent: Theme.apps,
                              actionTitle: L10n.localized(.actionInspect),
                              primaryActionTitle: L10n.localized(.actionUninstallNow),
                              enabled: true,
                              category: bit32Tag,
                              emptyTitle: L10n.localized(.noUnsupportedAppsFound),
                              sizeValue: bit32.reduce(0) { $0 + $1.totalSize }))

            // 3. 应用程序残留文件 
            tiles.append(Tile(size: .standard,
                              icon: "cm_catbig_app-leftovers",
                              title: L10n.localized(.discoveredAppLeftoversSizeFormat, Fmt.size(totalLeftoversSize)),
                              detail: L10n.localized(.cleanLeftoverAppFilesDesc),
                              accent: Theme.apps,
                              actionTitle: L10n.localized(.actionInspect),
                              primaryActionTitle: L10n.localized(.actionRemoveNow),
                              enabled: true,
                              category: OrphanFinderEngine.categoryTag,
                              emptyTitle: L10n.localized(.noLeftoverFilesFound),
                              sizeValue: totalLeftoversSize))

            // 4. 应用程序更新 
            //    零网络宪章：仅本地识别更新通道（App Store / Sparkle），不联网查询版本。
            let updatable = installedRoots.filter { $0.tags.contains { $0.hasPrefix("UpdateChannel:") } }
            let updatableCount = updatable.count
            tiles.append(Tile(size: .standard,
                              icon: "arrow.down.app",
                              title: L10n.localized(.discoveredUpdatableAppsCountFormat, updatableCount),
                              detail: L10n.localized(.updatableAppsDesc),
                              accent: Theme.apps,
                              actionTitle: L10n.localized(.actionInspect),
                              primaryActionTitle: nil, // 更新由各通道自行完成，本卡不提供直接操作
                              enabled: updatableCount > 0,
                              category: updatesTag,
                              emptyTitle: L10n.localized(.noUpdatesNeeded),
                              sizeValue: 0,
                              appIcons: updatable.prefix(4).compactMap { $0.url?.path }))

            return tiles
        }
    ) }

    /// 构造单个应用节点（并行调用，无共享状态）
    static func makeAppNode(_ app: InstalledApp, allApps: [InstalledApp]? = nil) -> Node {
        let allAppsTag = L10n.localized(.filterAllApplications)
        let unusedTag = L10n.localized(.filterUnused)
        let neverOpenedTag = L10n.localized(.filterNeverOpened)
        let suspiciousTag = L10n.localized(.filterSuspicious)
        let bit32Tag = L10n.localized(.filter32Bit)
        let updatesTag = L10n.localized(.filterAppUpdates)
        let appBodyTag = L10n.localized(.appBundleBody)
        let leftoverTag = L10n.localized(.filterAppLeftovers)

        var tags = [allAppsTag, "All Applications", app.source]
        if app.isUnused { tags.append(contentsOf: [unusedTag, "Unused"]) }
        if app.neverOpened { tags.append(contentsOf: [neverOpenedTag, "Never Opened"]) }
        if app.isSuspicious { tags.append(contentsOf: [suspiciousTag, "Suspicious"]) }
        if !app.vendor.isEmpty { tags.append(app.vendor) }
        if app.is32Bit { tags.append(contentsOf: [bit32Tag, "32-bit"]) }
        // P1-1：自动更新通道（本地识别，零网络）——供「应用程序更新」分类聚合
        if !app.updateChannel.isEmpty {
            tags.append(contentsOf: [updatesTag, "Application Updates", "UpdateChannel:\(app.updateChannel)"])
        }

        let isSurviving = UninstallerEngine.hasSurvivingInstallation(for: app, allApps: allApps)
        let leftovers = UninstallerEngine.leftovers(for: app, inventory: allApps?.map { UninstallerEngine.AppIdentity(name: $0.name, bundleID: $0.bundleID, url: $0.url) })
        var children: [Node] = []
        children.append(Node(name: app.name, url: app.url, icon: "macwindow",
                             note: appBodyTag, safety: .caution,
                             size: app.appSize, image: app.icon, tags: [appBodyTag, "Application Bundle"],
                             autoSelected: false,
                             ownerBundleIDs: [app.bundleID],
                             authorizationContext: .uninstall))
        children[0].uninstallContext = UninstallContext(appURL: app.url, bundleID: app.bundleID, isAppBody: true)
        // 残留按类别归组，让「明细」列能按类型展示
        var byPurpose: [Int: (label: String, items: [Node])] = [:]
        for lo in leftovers {
            var node = Node.item(from: lo)
            node.ownerBundleIDs = [app.bundleID]
            node.autoSelected = false
            if isSurviving {
                node.locked = true
                node.badge = L10n.localized(.cleanupProtectedReason)
                node.note = L10n.localized(.cleanupUninstallBlocked)
            }
            let purpose = lo.uninstallPurpose ?? UninstallerEngine.classifyFolderPurpose(path: lo.url.path, fallbackNote: lo.note)
            node.meta.append((L10n.localized(.metaDirectoryPurpose), purpose.purposeDescription))
            node.meta.append((L10n.localized(.metaPurposeCategory), purpose.shortTag))
            byPurpose[purpose.sortOrder, default: (purpose.shortTag, [])].items.append(node)
        }
        for (_, category) in byPurpose.sorted(by: { $0.key < $1.key }) {
            let (label, items) = category
            let sz = items.reduce(Int64(0)) { $0 + $1.totalSize }
            var groupNode = Node(name: label, icon: iconForLeftover(label),
                                 note: isSurviving ? L10n.localized(.cleanupUninstallBlocked) : "\(items.count) \(L10n.localized(.tileJunkQuantifier)) · \(Fmt.size(sz))",
                                 size: sz, children: items, isGroup: true, tags: [leftoverTag, "Leftovers"],
                                 autoSelected: false)
            if isSurviving {
                groupNode.locked = true
                groupNode.badge = L10n.localized(.cleanupProtectedReason)
            }
            children.append(groupNode)
        }

        var meta: [(String, String)] = [
            (L10n.localized(.labelBundleIdentifier), app.bundleID),
            (L10n.localized(.labelVersion), app.version.isEmpty ? "—" : app.version),
            (L10n.localized(.labelSource), app.source),
            (L10n.localized(.labelLastOpened), Fmt.appDate(app.lastOpened)),
        ]
        if let inst = app.installDate {
            meta.append((L10n.localized(.labelInstallDate), Fmt.date(inst)))
        }
        if !app.vendor.isEmpty { meta.append((L10n.localized(.labelVendor), app.vendor)) }
        if app.is32Bit { meta.append((L10n.localized(.labelArchitecture), L10n.localized(.archOnly32Bit))) }
        if !app.updateChannel.isEmpty { meta.append((L10n.localized(.labelUpdateChannel), app.updateChannel)) }

        let totalSize = app.appSize + leftovers.reduce(Int64(0)) { $0 + $1.size }
        return Node(name: app.name, url: app.url, icon: "macwindow",
                    note: app.bundleID, safety: .caution,
                    size: totalSize, children: children,
                    isGroup: true, image: app.icon, tags: tags, meta: meta,
                    autoSelected: false,
                    date: app.isActiveNow ? Date() : app.lastOpened,
                    installDate: app.installDate,
                    isActiveNow: app.isActiveNow)
    }

    static func iconForLeftover(_ label: String) -> String {
        let l = label.lowercased()
        if l.contains("dmg") || l.contains("installer") || l.contains("package") {
            return "cm_detail_app-leftovers_installers-dmg-files"
        }
        if l.contains("cache") { return "internaldrive" }
        if l.contains("log") || l.contains("crash") { return "doc.text" }
        if l.contains("preference") { return "gearshape" }
        if l.contains("config") { return "gearshape" }
        if l.contains("container") { return "shippingbox" }
        if l.contains("launch") || l.contains("login") { return "bolt" }
        if l.contains("receipt") { return "doc.plaintext" }
        if l.contains("plugin") || l.contains("extension") { return "puzzlepiece.extension" }
        return "folder"
    }
}
