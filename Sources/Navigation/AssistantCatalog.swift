import SwiftUI

// ============================================================
//  助手 Assistant —— 健康分 + 个性化建议
//
//  对应原版 AssistantModule(侧栏第 10 项):计算 Mac 健康分,
//  给出可一键前往对应模块的改进建议。
//  评分完全由本地指标推导,不发任何网络请求(排除项约定)。
// ============================================================

enum AssistantModule {

    struct Suggestion: Identifiable {
        let id = UUID()
        var title: String
        var detail: String
        var icon: String
        var asset: String = ""
        var moduleKey: String   // 点击前往的模块
        var penalty: Int        // 对健康分的扣分
    }

    struct Report {
        var score: Int
        var suggestions: [Suggestion]
    }

    // MARK: 健康分计算(100 起步,按问题扣分)

    static func health() -> Report {
        var suggestions: [Suggestion] = []
        let home = FileUtil.home
        let lib = home.appendingPathComponent("Library")
        let GB: Int64 = 1024 * 1024 * 1024

        // 1) 废纸篓
        let trash = home.appendingPathComponent(".Trash")
        if FileUtil.exists(trash.path) {
            let s = FileUtil.size(of: trash)
            if s > 500 * 1024 * 1024 {
                let p = max(3, min(15, Int(s / (5 * GB) * 15)))
                suggestions.append(Suggestion(
                    title: L10n.localized(.assistantTrashNotEmptyTitle),
                    detail: L10n.localized(.assistantTrashRemainingDescFormat, Fmt.size(s)),
                    icon: "trash", asset: "cm_intro_trash-bins", moduleKey: "junk", penalty: p))
            }
        }

        // 2) 用户缓存
        let caches = lib.appendingPathComponent("Caches")
        let cs = FileUtil.exists(caches.path) ? FileUtil.size(of: caches) : 0
        if cs > 3 * GB {
            let p = max(3, min(15, Int(cs / (10 * GB) * 15)))
            suggestions.append(Suggestion(
                title: L10n.localized(.assistantCachesHighTitle),
                detail: L10n.localized(.assistantCachesHighDescFormat, Fmt.size(cs)),
                icon: "internaldrive", asset: "cm_intro_system-junk", moduleKey: "junk", penalty: p))
        }

        // 3) 启动项过多
        let si = PerformanceEngine.startupItems()
        if si.count > 8 {
            suggestions.append(Suggestion(
                title: L10n.localized(.assistantTooManyStartupItemsTitle),
                detail: L10n.localized(.assistantLoginItemsCountDescFormat, si.count),
                icon: "bolt.fill", asset: "cm_intro_login-items", moduleKey: "performance", penalty: min(10, si.count / 2)))
        }

        // 4) 超大文件(Downloads / Desktop 顶层)
        var bigCount = 0
        var bigSize: Int64 = 0
        for dir in [home.appendingPathComponent("Downloads"),
                    home.appendingPathComponent("Desktop")] {
            for f in FileUtil.children(of: dir) {
                let s = FileUtil.size(of: f)
                if s > GB { bigCount += 1; bigSize += s }
            }
        }
        if bigCount > 0 {
            suggestions.append(Suggestion(
                title: L10n.localized(.assistantDiscoveredHugeFilesTitleFormat, bigCount),
                detail: L10n.localized(.assistantHugeFilesCountDescFormat, Fmt.size(bigSize)),
                icon: "externaldrive.badge.exclamationmark", asset: "cm_intro_large-old-files",
                moduleKey: "spaceLens", penalty: min(10, bigCount * 2)))
        }

        // 5) iOS 备份
        let backups = lib.appendingPathComponent("Application Support/MobileSync/Backup")
        if FileUtil.exists(backups.path) {
            let s = FileUtil.size(of: backups)
            if s > 10 * GB {
                suggestions.append(Suggestion(
                    title: L10n.localized(.assistantIosBackupLargeTitle),
                    detail: L10n.localized(.assistantIosBackupDescFormat, Fmt.size(s)),
                    icon: "iphone", asset: "cm_intro_system-junk", moduleKey: "junk", penalty: min(10, Int(s / (100 * GB) * 10))))
            }
        }

        // 6) 磁盘空间不足
        let disk = DiskInfo.current()
        if disk.total > 0 && disk.free < disk.total / 10 {
            suggestions.append(Suggestion(
                title: L10n.localized(.assistantDiskSpaceLowTitle),
                detail: L10n.localized(.assistantDiskFreeSpaceLowDescFormat, Fmt.size(disk.free)),
                icon: "externaldrive.badge.timemachine", asset: "cm_intro_explore-storage",
                moduleKey: "spaceLens", penalty: 15))
        }

        let score = max(5, 100 - suggestions.reduce(0) { $0 + $1.penalty })
        return Report(score: score, suggestions: suggestions.sorted { $0.penalty > $1.penalty })
    }

    // MARK: 模块描述符

    static var spec: ModuleSpec { ModuleSpec(
        key: "assistant",
        title: L10n.localized(.moduleAssistantTitle),
        icon: "wand.and.stars",
        accent: Aurora.accent(255),
        accent2: Aurora.accent(290),
        kind: .assistant,
        sidebarSubtitle: L10n.localized(.moduleAssistantSubtitle),
        introSubtitle: "",
        introCategories: [],
        scanSubtitle: "",
        primaryAction: L10n.localized(.actionInspect),
        emptyTitle: "",
        emptySubtitle: "",
        filterOrder: [],
        filterIcons: [:],
        buildTree: { _, _, _ in [] },
        tiles: { _ in [] }
    ) }
}
