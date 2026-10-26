import Foundation

/// Display grouping only. This classifier never grants selection or deletion authorization.
enum SmartCleanSectionClassifier {
    /// 将原 CleanMate 扫描引擎产出的叶子节点精准归入 8 大语义分类卡片
    nonisolated static func classify(leaf: Node, groupTitle: String, groupTags: [String]) -> SmartCleanSectionKind {
        let p = leaf.path.lowercased()
        let n = leaf.name.lowercased()
        let combined = "\(n) \(p) \(groupTitle.lowercased())"
        let ruleID = leaf.ruleEvidence?.id ?? leaf.leaves.first?.ruleEvidence?.id ?? ""
        if ruleID == "JC.LEFTOVER.ORPHAN" || ruleID == "JC.SYS.PLIST.BROKEN" { return .leftovers }

        // 1. AI 工具（Ollama、Hugging Face、LM Studio、Antigravity、Cursor、Claude、ChatGPT、Trae、Windsurf 等）
        if ruleID == "JC.AI.OLLAMA.MODEL"
            || ruleID == "JC.AI.OLDVERSION"
            || ruleID == "JC.AI.OLLAMA.ORPHAN"
            || ruleID == "JC.AI.LMSTUDIO"
            || groupTitle == "Local Models"
            || groupTitle == L10n.localized(.scannerLocalAiModels)
            || groupTags.contains("AI Clutter Files")
            || groupTags.contains(L10n.localized(.scannerAiClutterFiles))
            || groupTitle == "AI Clutter Files"
            || groupTitle == L10n.localized(.scannerAiClutterFiles)
            || AppConfig.JunkPresentation.modelPathMarkers.contains(where: { p.contains($0) })
            || AppConfig.JunkPresentation.aiMarkers.contains(where: { combined.contains($0) }) {
            return .ai
        }

        // 2. 通讯工具（微信、QQ、Telegram、飞书、钉钉、Slack、Discord、Zoom、Teams、WhatsApp）
        if AppConfig.JunkPresentation.commMarkers.contains(where: { combined.contains($0) }) {
            return .communication
        }

        // 3. 卸载残留（已卸载 App 遗留物、损坏偏好设置优先归类，避免被 design/dev 关键字误伤）
        if ruleID == "JC.LEFTOVER.ORPHAN"
            || ruleID == "JC.SYS.PLIST.BROKEN"
            || groupTags.contains("App Leftovers")
            || groupTags.contains(L10n.localized(.scannerAppLeftovers))
            || groupTitle == "Leftover Files"
            || groupTitle == L10n.localized(.scannerAppLeftovers)
            || groupTitle == "Broken Preference Files"
            || groupTitle == L10n.localized(.scannerBrokenPreferences) {
            return .leftovers
        }

        // 4. 设计缓存（Figma、Sketch、Adobe、Photoshop、Illustrator、Blender、Canva、Affinity、Pixelmator、剪映）
        if ruleID.hasPrefix("JC.DSG.")
            || !AppConfig.JunkPresentation.designExactPathComponents.isDisjoint(with: p.split(separator: "/").map(String.init))
            || AppConfig.JunkPresentation.designMarkers.contains(where: { combined.contains($0) }) {
            return .design
        }

        // 5. 开发工具（Xcode、SwiftPM、Homebrew、Docker、Gradle、npm/pnpm/yarn、Cargo、Pip、Maven、NuGet、JetBrains）
        let devGroups: Set<String> = [
            "Xcode Junk", L10n.localized(.xcodeJunk),
            "Homebrew Cache", L10n.localized(.scannerHomebrewCache),
            "Docker & Container Caches", L10n.localized(.dockerAndContainers), L10n.localized(.scannerDockerCache),
            "Gradle Cache", L10n.localized(.scannerGradleCache),
            "Symbolication Cache", L10n.localized(.scannerSymbolicationCache),
            "Package Manager Caches", "Project Build Caches", L10n.localized(.declutterCleanProjects)
        ]
        if ruleID == "JC.DEV.DOCKER.VM"
            || devGroups.contains(groupTitle)
            || AppConfig.JunkPresentation.devMarkers.contains(where: { combined.contains($0) }) {
            return .developer
        }

        // 6. 系统数据（iOS 备份、系统缓存、系统日志、文稿版本、废纸篓、磁盘映像、虚拟机）
        let sysGroups: Set<String> = [
            "System Cache Files", L10n.localized(.scannerSystemCacheFiles),
            "System Log Files", L10n.localized(.scannerSystemLogFiles),
            "Document Versions", L10n.localized(.scannerDocumentVersions),
            "Trash", "Local Trash", L10n.localized(.scannerTrashBins),
            "Unused Disk Images", L10n.localized(.scannerUnusedDiskImages),
            "32-bit Applications", L10n.localized(.scanner32BitApps),
            "Broken Login Items", L10n.localized(.scannerBrokenLoginItems),
            "Deleted Users", L10n.localized(.scannerDeletedUsers),
            "iOS Device Backups", L10n.localized(.scannerIosDeviceBackups)
        ]
        if sysGroups.contains(groupTitle)
            || ruleID == "JC.SYS.IOS.BACKUP"
            || ruleID == "JC.SYS.APFS.PURGEABLE"
            || ruleID == "JC.SYS.TM.SNAPSHOTS"
            || ruleID == "JC.IMG.UNUSED_DMG"
            || AppConfig.JunkPresentation.systemPathMarkers.contains(where: { p.contains($0) })
            || AppConfig.JunkPresentation.systemPathPrefixes.contains(where: { p.hasPrefix($0) }) {
            return .system
        }

        // 7. 默认归入 App 缓存与日志
        return .app
    }
}
