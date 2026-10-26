import SwiftUI

// ============================================================
//  性能优化 Performance
//
//  介绍页分类：开机启动项 / 后台运行项 / 系统维护任务
//  子流程：LoginItems · BackgroundItems · MaintenanceTasks
// ============================================================

enum PerformanceModule {

    static var spec: ModuleSpec { makeSpec() }

    static func memoryCleanupTile(pressure: MemoryPressureLevel) -> Tile? {
        guard pressure != .normal else { return nil }
        return Tile(icon: "cm_detail_maintenance-tasks_free-up-ram",
                    title: L10n.localized(.actionFreeUpRamMemory),
                    detail: L10n.localized(.performanceFreeRamDesc),
                    accent: Theme.perform,
                    actionTitle: L10n.localized(.actionInspect),
                    primaryActionTitle: L10n.localized(.actionFree),
                    category: L10n.localized(.maintenanceTasks))
    }

    private static func makeSpec() -> ModuleSpec { ModuleSpec(
        key: "performance",
        title: L10n.localized(.modulePerformance),
        icon: "speedometer",
        accent: Theme.perform,
        accent2: Color(red: 0.30, green: 0.84, blue: 0.72),
        kind: .performance,
        sidebarSubtitle: L10n.localized(.modulePerformanceTitle),
        introSubtitle: L10n.localized(.modulePerformanceDesc),
        introCategories: [
            IntroCategory(title: L10n.localized(.categoryBackgroundServices), icon: "gearshape.2",
                          note: L10n.localized(.manageBackgroundServicesDesc),
                          asset: "cm_intro_launch-agents"),
            IntroCategory(title: L10n.localized(.loginItems), icon: "power",
                          note: L10n.localized(.manageLoginAndLaunchAgentsDesc),
                          asset: "cm_intro_login-items"),
            IntroCategory(title: L10n.localized(.maintenanceTasks), icon: "wrench.and.screwdriver",
                          note: L10n.localized(.performanceRecommendedTasksSubtitle),
                          asset: "cm_intro_maintenance-tasks"),
        ],
        scanSubtitle: L10n.localized(.checkingYourSystemPrompt),
        primaryAction: L10n.localized(.actionRunTasks),
        emptyTitle: L10n.localized(.noRecommendedOptimizationTasks),
        emptySubtitle: L10n.localized(.macInGoodConditionPrompt),
        filterOrder: [
            L10n.localized(.maintenanceTasks),
            L10n.localized(.loginItems),
            L10n.localized(.categoryBackgroundServices),
            L10n.localized(.backgroundItems)
        ],
        filterIcons: Dictionary([
            (L10n.localized(.categoryBackgroundServices), "gearshape.2"),
            (L10n.localized(.backgroundItems), "gearshape.2"),
            (L10n.localized(.loginItems), "power"),
            (L10n.localized(.maintenanceTasks), "wrench.and.screwdriver"),
        ], uniquingKeysWith: { first, _ in first }),
        buildTree: { progress, onFound, stopped in
            var out: [Node] = []
            progress(0.15, L10n.localized(.statusCheckingBackgroundAppsAndProcessesPrompt))
            let all = PerformanceEngine.startupItems()
            let login = all.filter { !$0.isBackground }
            let bg = all.filter { $0.isBackground }

            let bgTag = L10n.localized(.categoryBackgroundServices)
            let bgItemsTag = L10n.localized(.backgroundItems)
            let loginTag = L10n.localized(.loginItems)
            let maintTag = L10n.localized(.maintenanceTasks)

            // 后台项目/后台服务全量单列表平铺（对齐原版后台项目）
            if !bg.isEmpty {
                let sortedBg = bg.sorted {
                    let n0 = $0.displayName.isEmpty ? $0.name : $0.displayName
                    let n1 = $1.displayName.isEmpty ? $1.name : $1.displayName
                    return n0.localizedCaseInsensitiveCompare(n1) == .orderedAscending
                }
                let bgNode = Node(name: bgTag, icon: "gearshape.2",
                                  note: L10n.localized(.startupDisableUnusedProcessesDesc),
                                  size: 0, children: sortedBg.map { node(from: $0) },
                                  isGroup: true, tags: [bgTag, bgItemsTag, "Background Services", "Background Items"])
                out.append(bgNode)
                onFound([bgNode])
            }
            if stopped() { return out }

            progress(0.45, L10n.localized(.statusCheckingLoginAppsPrompt))
            if !login.isEmpty {
                let loginNode = Node(name: loginTag, icon: "power",
                                     note: L10n.localized(.startupManageLoginItemsDesc),
                                     size: 0, children: login.map { node(from: $0) },
                                     isGroup: true, tags: [loginTag, "Login Items"])
                out.append(loginNode)
                onFound([loginNode])
            }
            if stopped() { return out }

            progress(0.75, L10n.localized(.generatingMaintenanceTasksPrompt))
            let tasks = PerformanceEngine.maintenanceTasks()
            let nodes = tasks.map { t -> Node in
                Node(name: t.name, url: nil, icon: "wrench.and.screwdriver",
                     note: t.detail, safety: .safe,
                     action: .custom("maint:\(t.taskId)"),
                     size: 0, image: Art.ns(t.asset), tags: [maintTag, "Maintenance Tasks"],
                     meta: [(L10n.localized(.labelDescription), t.detail),
                            (L10n.localized(.labelPermission), t.needsAdmin ? L10n.localized(.needsAdminPermission) : L10n.localized(.noPermissionNeeded))],
                     maintenanceTaskId: t.taskId,
                     authorizationContext: .systemMaintenance)
            }
            if !nodes.isEmpty {
                let taskNode = Node(name: maintTag, icon: "wrench.and.screwdriver",
                                    note: L10n.localized(.performanceMaintenanceDetailedIntro),
                                    size: 0, children: nodes, isGroup: true,
                                    tags: [maintTag, "Maintenance Tasks"],
                                    authorizationContext: .systemMaintenance)
                out.append(taskNode)
                onFound([taskNode])
            }

            // APFS 可清除空间：按宪章归入「系统维护任务」，严禁计入系统垃圾
            if let apfs = JunkEngine.scanAPFSPurgeable() {
                let nodes = apfs.items.map { item -> Node in
                    Node(name: item.name, url: item.url, icon: "internaldrive",
                         note: item.note, safety: .safe,
                         action: item.action,
                         size: item.size, tags: [maintTag, "Maintenance Tasks"],
                         meta: [(L10n.localized(.labelDescription), item.note), (L10n.localized(.labelSize), Fmt.size(item.size))],
                         authorizationContext: .systemMaintenance)
                }
                if !nodes.isEmpty {
                    let purgeNode = Node(name: L10n.localized(.scannerApfsPurgeableSpace), icon: "internaldrive",
                                         note: L10n.localized(.purgeableSpaceDetailedIntro),
                                         size: nodes.reduce(0) { $0 + $1.totalSize },
                                         children: nodes, isGroup: true, tags: [maintTag, "Maintenance Tasks"])
                    out.append(purgeNode)
                    onFound([purgeNode])
                }
            }

            progress(0.95, L10n.localized(.statusCheckingLocalSnapshotsAndMemoryPrompt))
            progress(1.0, L10n.localized(.completed))
            return out
        },
        tiles: { roots in
            var tiles: [Tile] = []
            let bgTag = L10n.localized(.categoryBackgroundServices)
            let bgItemsTag = L10n.localized(.backgroundItems)
            let loginTag = L10n.localized(.loginItems)
            let maintTag = L10n.localized(.maintenanceTasks)
            let bg = roots.filter { $0.tags.contains(bgItemsTag) || $0.tags.contains("Background Items") || $0.tags.contains("Background Services") || $0.tags.contains(bgTag) }
            let login = roots.filter { $0.tags.contains(loginTag) || $0.tags.contains("Login Items") }
            let broken = bg.reduce(0) { $0 + $1.children.filter { $0.note.contains("Invalid") || $0.note.contains("Missing") || $0.startupItem?.broken == true }.count }

            // 1. 主大卡片（纵向大卡片 .largeVertical，置于首位对齐原版规范）
            tiles.append(Tile(size: .largeVertical,
                              icon: "cm_catbig_maintenance-tasks",
                              title: L10n.localized(.actionRunRecommendedMaintenanceTasks),
                              detail: L10n.localized(.weeklyRecommendedMaintenanceTasksReadyDesc),
                              accent: Theme.perform,
                              actionTitle: L10n.localized(.actionInspect),
                              primaryActionTitle: L10n.localized(.actionRunTasks),
                              category: maintTag,
                              satelliteIcons: ["cm_detail_maintenance-tasks_free-up-ram",
                                               "cm_catbig_maintenance-tasks",
                                               "cm_detail_maintenance-tasks_speed-up-mail"]))

            // 2. 次级卡片：后台项目
            let bgCount = bg.reduce(0) { $0 + $1.leafCount }
            if bgCount > 0 {
                tiles.append(Tile(icon: "cm_cat_launch-agents",
                                  title: L10n.localized(.discoveredBackgroundItemsCountFormat, bgCount),
                                  detail: broken > 0 ? L10n.localized(.brokenBackgroundItemsCountFormat, broken) :
                                                       L10n.localized(.viewAllowedBackgroundProcessesDesc),
                                  accent: Theme.perform,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: bgItemsTag))
            }

            // 3. 次级卡片：开机启动项
            let loginCount = login.reduce(0) { $0 + $1.leafCount }
            if loginCount > 0 {
                tiles.append(Tile(icon: "cm_cat_login-items",
                                  title: L10n.localized(.discoveredLoginItemsCountFormat, loginCount),
                                  detail: L10n.localized(.viewStartupAppsDesc),
                                  accent: Theme.perform,
                                  actionTitle: L10n.localized(.actionInspect),
                                  category: loginTag))
            }

            // 4. 动态卡片：精简时间机器快照（若系统存在本地快照）
            if PerformanceEngine.hasLocalSnapshots() {
                tiles.append(Tile(icon: "cm_detail_maintenance-tasks_time-machine",
                                  title: L10n.localized(.thinTimeMachineSnapshots),
                                  detail: L10n.localized(.performanceThinTimeMachineDesc),
                                  accent: Theme.perform,
                                  actionTitle: L10n.localized(.actionInspect),
                                  primaryActionTitle: L10n.localized(.actionThin),
                                  category: maintTag))
            }

            // 5. 动态卡片：释放 RAM 内存（仅在维护任务启用 freeRAM 且内存压力偏高时展示）
            let mem = PerformanceEngine.memoryInfo()
            if PerformanceEngine.maintenanceTasks().contains(where: { $0.taskId == "freeRAM" }),
               let memoryTile = memoryCleanupTile(pressure: mem.pressure) {
                tiles.append(memoryTile)
            }

            return tiles
        }
    ) }

    static func node(from item: StartupItem) -> Node {
        let displayName = item.displayName.isEmpty ? item.name : item.displayName
        let bgTag = L10n.localized(.categoryBackgroundServices)
        let bgItemsTag = L10n.localized(.backgroundItems)
        let loginTag = L10n.localized(.loginItems)
        var meta: [(String, String)] = [
            (L10n.localized(.labelName), displayName),
            (L10n.localized(.labelScope), item.scope),
            (L10n.localized(.labelConfigFile), item.path),
        ]
        if !item.program.isEmpty { meta.append((L10n.localized(.labelProgram), item.program)) }
        if item.broken {
            meta.append((L10n.localized(.labelStatus), L10n.localized(.statusPointedProgramMissing)))
        } else if !item.stateKnown {
            meta.append((L10n.localized(.labelStatus), L10n.localized(.statusUnknownUnreadable)))
        } else {
            meta.append((L10n.localized(.labelStatus), item.enabled ? L10n.localized(.statusEnabled) : L10n.localized(.statusDisabled)))
        }
        let isLocked = item.path.contains("/Library/LaunchDaemons/") || item.managedBySystemSettings
        return Node(name: displayName,
                    url: URL(fileURLWithPath: item.path),
                    icon: item.broken ? "bolt.slash" : "bolt",
                    note: isLocked ? L10n.localized(.showsDiskUsageOnlyAndIsNeverAutoCleanedManageInTheRespectiveAppOrSystemSettings) : item.broken ? L10n.localized(.statusInvalidProgramMissing) : item.program.isEmpty ? item.scope : item.program,
                    safety: item.broken ? .caution : .safe,
                    size: FileUtil.size(of: URL(fileURLWithPath: item.path)),
                    ignorable: !item.broken,
                    locked: isLocked,
                    image: item.iconImage,
                    tags: item.isBackground ? [bgTag, bgItemsTag, "Background Services", "Background Items"] : [loginTag, "Login Items"],
                    meta: meta,
                    startupItem: item)
    }

    static func icon(forScope s: String) -> String {
        switch s {
        case "User Agent", L10n.localized(.userAgent): return "person.crop.circle"
        case "Global Agent", L10n.localized(.globalAgent): return "globe"
        case "System Daemon", L10n.localized(.systemDaemon): return "gearshape.2"
        default:        return "bolt"
        }
    }

    static func scopeNote(_ s: String) -> String {
        switch s {
        case "User Agent", L10n.localized(.userAgent): return L10n.localized(.scopeUserAgentDesc)
        case "Global Agent", L10n.localized(.globalAgent): return L10n.localized(.scopeGlobalAgentDesc)
        case "System Daemon", L10n.localized(.systemDaemon): return L10n.localized(.scopeSystemDaemonDesc)
        default:        return ""
        }
    }
}
