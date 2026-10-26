import SwiftUI
import AppKit

// ============================================================
//  MARK: - SmartNextGenCleanRow (高定微组件 64pt宽版 / 52pt紧凑版 静音级卡片行)
// ============================================================

struct SmartNextGenCleanRow: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var config = AppConfigStore.shared
    let section: SmartCleanSectionData
    let checkboxState: CheckboxState
    let selectedCount: Int
    let selectedSize: Int64
    let isCompact: Bool
    let isSelected: Bool
    let onToggleSection: () -> Void
    let onSelectSection: () -> Void

    @State var hover = false

    var body: some View {
        let isDark = Theme.isDark

        Group {
            if isCompact {
                compactContent
            } else {
                wideContent
            }
        }
        .background(rowBackground(isDark: isDark))
        .overlay(rowOverlay(isDark: isDark))
        .shadow(
            color: Color.black.opacity(isDark ? 0.18 : (hover ? 0.07 : 0.03)),
            radius: hover ? 6 : 3,
            x: 0,
            y: hover ? 2 : 1
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelectSection()
        }
        .onHover { hover = $0 }
        .help(section.kind.subtitle)
    }

    func rowBackground(isDark: Bool) -> some View {
        let fillColor: Color
        if isSelected {
            fillColor = Theme.accent.opacity(isDark ? 0.14 : 0.08)
        } else if isDark {
            fillColor = hover ? Theme.cardElevated : Theme.card
        } else {
            fillColor = Color.white
        }
        return RoundedRectangle(cornerRadius: isCompact ? 10 : 12, style: .continuous)
            .fill(fillColor)
    }

    func rowOverlay(isDark: Bool) -> some View {
        let strokeColor: Color
        if isSelected {
            strokeColor = Theme.accent.opacity(isDark ? 0.50 : 0.40)
        } else if isDark {
            strokeColor = Color.white.opacity(hover ? 0.12 : 0.07)
        } else {
            strokeColor = Color.black.opacity(hover ? 0.10 : 0.06)
        }
        let lineWidth: CGFloat = isSelected ? 1.2 : 1.0
        return RoundedRectangle(cornerRadius: isCompact ? 10 : 12, style: .continuous)
            .strokeBorder(strokeColor, lineWidth: lineWidth)
    }

    var wideContent: some View {
        HStack(spacing: 14) {
            // 锚点 1: 左锚点 (36x36 五层光学Squircle图标 + 标题 + MetallicBadge)
            HStack(spacing: 11) {
                CleanCategoryVisuals.opticalIcon(for: section.kind, size: 36)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(section.kind.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)

                        if !section.kind.isManualStorage {
                            let badgeText = (selectedCount == 0)
                                ? "\(section.totalCount) \(L10n.localized(.unitItems))"
                                : "\(selectedCount)/\(section.totalCount) \(L10n.localized(.unitItems))"
                            MetallicBadge(
                                text: badgeText,
                                color: selectedCount > 0 ? Theme.accent : Theme.tert
                            )
                        } else {
                            MetallicBadge(
                                text: L10n.localized(.viewOnly),
                                color: Theme.amber
                            )
                        }
                    }
                }
            }

            Spacer(minLength: 12)

            // 锚点 2: 右锚点 (选中后展示 已选大小/总大小，未选中时展示该类目总大小)
            let displaySize = section.totalSize
            let parts = Fmt.sizeParts(displaySize)

            if !section.kind.isManualStorage && selectedCount > 0 {
                let selParts = Fmt.sizeParts(selectedSize)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(selParts.value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.accent)
                        .monospacedDigit()

                    Text(selParts.unit)
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.accent.opacity(0.85))

                    Text(" / ")
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.tert)

                    Text(parts.value)
                        .font(.system(size: 15.5, weight: .bold, design: .rounded))
                        .foregroundStyle(displaySize > 0 ? Theme.text : Theme.tert)
                        .monospacedDigit()

                    Text(parts.unit)
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(displaySize > 0 ? Theme.sub : Theme.tert)
                }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(parts.value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(displaySize > 0 ? Theme.text : Theme.tert)
                        .monospacedDigit()

                    Text(parts.unit)
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(displaySize > 0 ? Theme.sub : Theme.tert)
                }
            }

            // 锚点 3: 操作锚点 (Hover 时浮现微指引箭头 + FluidCheckbox)
            HStack(spacing: 10) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(hover ? Theme.sub : Color.clear)
                    .frame(width: 14)

                FluidCheckbox(state: checkboxState, tint: Theme.accent, action: onToggleSection)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
    }

    var compactContent: some View {
        HStack(spacing: 8) {
            if isSelected {
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: 3.5, height: 22)
            }

            CleanCategoryVisuals.opticalIcon(for: section.kind, size: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.kind.title)
                    .font(.system(size: 12.5, weight: isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? Theme.text : Theme.text.opacity(0.9))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if !section.kind.isManualStorage {
                        Text("\(selectedCount)/\(section.totalCount)")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(selectedCount > 0 ? Theme.accent : Theme.tert)
                            .monospacedDigit()
                    } else {
                        Text(L10n.localized(.viewOnly))
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.amber)
                    }

                    Text("·")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.tert)

                    if !section.kind.isManualStorage && selectedCount > 0 {
                        Text("\(Fmt.size(selectedSize)) / \(Fmt.size(section.totalSize))")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.sub)
                            .monospacedDigit()
                            .lineLimit(1)
                    } else {
                        Text(Fmt.size(section.totalSize))
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(section.totalSize > 0 ? Theme.sub : Theme.tert)
                            .monospacedDigit()
                    }
                }
            }

            Spacer(minLength: 4)

            FluidCheckbox(state: checkboxState, tint: Theme.accent, action: onToggleSection)
        }
        .padding(.leading, isSelected ? 8 : 12)
        .padding(.trailing, 12)
        .frame(height: 48)
    }
}

// ============================================================
//  MARK: - 按应用/工具聚合的二级可展开缓存目录模型与构建器 (一级应用 -> 二级需要清空的文件夹)
// ============================================================

struct SmartAppCacheGroup: Identifiable, @unchecked Sendable {
    let id: String
    let title: String
    let subtitle: String
    let appIcon: NSImage?
    let iconPath: String?
    let fallbackSymbol: String
    let items: [Node]
    var isRunning: Bool = false
    let totalSize: Int64
    let allLeaves: [Node]
    let selectableLeafIDs: Set<UUID>

    init(
        id: String,
        title: String,
        subtitle: String,
        appIcon: NSImage?,
        iconPath: String? = nil,
        fallbackSymbol: String,
        items: [Node],
        isRunning: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.appIcon = appIcon
        self.iconPath = iconPath
        self.fallbackSymbol = fallbackSymbol
        self.items = items
        self.isRunning = isRunning
        self.totalSize = items.reduce(0) { $0 + $1.totalSize }
        let leaves = items.flatMap(\.leaves)
        self.allLeaves = leaves
        self.selectableLeafIDs = Set(leaves.lazy.filter { CleanupSelectionPolicy.isUserSelectable($0) }.map(\.id))
    }
}

enum SmartAppGroupBuilder {
    struct ResolvedAppIdentity {
        let key: String
        let displayName: String
        let subtitle: String
        let appURL: URL?
        let isXcode: Bool
    }

    static let knownToolMap: [(token: String, name: String, bundleID: String?, exactTokenOnly: Bool)] = [
        ("com.todesktop.230313mzl4w4u92", "Cursor", "com.todesktop.230313mzl4w4u92", false),
        ("cursor", "Cursor", "com.todesktop.230313mzl4w4u92", false),
        ("com.microsoft.vscode", "Visual Studio Code", "com.microsoft.VSCode", false),
        ("vscode", "Visual Studio Code", "com.microsoft.VSCode", false),
        ("code", "Visual Studio Code", "com.microsoft.VSCode", true),
        ("com.workbuddy.workbuddy-ai", "WorkBuddy AI", "com.workbuddy.workbuddy-ai", false),
        ("workbuddy", "WorkBuddy AI", "com.workbuddy.workbuddy-ai", false),
        ("com.google.antigravity", "Antigravity", "com.google.antigravity", false),
        ("antigravity", "Antigravity", "com.google.antigravity", false),
        ("com.google.chrome", "Google Chrome", "com.google.Chrome", false),
        ("company.thebrowser.browser", "Arc", "company.thebrowser.Browser", false),
        ("com.brave.browser", "Brave Browser", "com.brave.Browser", false),
        ("com.microsoft.edgemac", "Microsoft Edge", "com.microsoft.edgemac", false),
        ("org.mozilla.firefox", "Firefox", "org.mozilla.firefox", false),
        ("com.operasoftware.opera", "Opera", "com.operasoftware.Opera", false),
        ("com.netease.163music", "网易云音乐", "com.netease.163music", false),
        ("neteasemusic", "网易云音乐", "com.netease.163music", false),
        ("com.tencent.qq", "QQ", "com.tencent.qq", false),
        ("com.tencent.xinwechat", "微信", "com.tencent.xinWeChat", false),
        ("xinwechat", "微信", "com.tencent.xinWeChat", false),
        ("xwechat_files", "微信", "com.tencent.xinWeChat", false),
        ("com.tencent.weworkmac", "企业微信", "com.tencent.WeWorkMac", false),
        ("ru.keepcoder.telegram", "Telegram", "ru.keepcoder.Telegram", false),
        ("telegram", "Telegram", "ru.keepcoder.Telegram", false),
        ("com.electron.lark", "飞书", "com.electron.lark", false),
        ("feishu", "飞书", "com.electron.lark", false),
        ("com.alibaba.dingtalkmac", "钉钉", "com.alibaba.DingTalkMac", false),
        ("dingtalk", "钉钉", "com.alibaba.DingTalkMac", false),
        ("com.tinyspeck.slackmacgap", "Slack", "com.tinyspeck.slackmacgap", false),
        ("com.hnc.discord", "Discord", "com.hnc.Discord", false),
        ("us.zoom.xos", "Zoom", "us.zoom.xos", false),
        ("com.spotify.client", "Spotify", "com.spotify.client", false),
        ("com.anthropic.claudefordesktop", "Claude", "com.anthropic.claudefordesktop", false),
        ("claude", "Claude", "com.anthropic.claudefordesktop", false),
        ("com.openai.chat", "ChatGPT", "com.openai.chat", false),
        ("chatgpt", "ChatGPT", "com.openai.chat", false),
        ("com.openai.codex", "OpenAI Codex", "com.openai.codex", false),
        ("codex", "OpenAI Codex", "com.openai.codex", false),
        ("windsurf", "Windsurf", "com.exafunction.windsurf", false),
        ("trae", "Trae", "com.bytedance.trae", false),
        ("ollama", "Ollama", "com.electron.ollama", false),
        ("lm-studio", "LM Studio", "ai.elementlabs.lmstudio", false),
        ("lmstudio", "LM Studio", "ai.elementlabs.lmstudio", false),
        ("cherrystudio", "Cherry Studio", "com.tencent.CherryStudio", false),
        ("cherry-studio", "Cherry Studio", "com.tencent.CherryStudio", false),
        ("opencode", "OpenCode", nil, false),
        ("huggingface", "Hugging Face", nil, false),
        ("gemini", "Google Gemini", nil, false),
        ("org.swift.swiftpm", "Swift Package Manager", nil, false),
        ("swiftpm", "Swift Package Manager", nil, false),
        ("cocoapods", "CocoaPods", nil, false),
        ("homebrew", "Homebrew", nil, false),
        ("pnpm", "pnpm", nil, false),
        ("/.npm", "npm", nil, false),
        ("yarn", "Yarn", nil, false),
        ("/.bun", "Bun", nil, false),
        ("/uv", "uv (Python)", nil, false),
        ("/pip", "pip (Python)", nil, false),
        ("conda", "Conda", nil, false),
        ("/.cargo", "Cargo (Rust)", nil, false),
        ("rustup", "Rustup", nil, false),
        ("gradle", "Gradle", nil, false),
        ("/.m2", "Maven", nil, false),
        ("nuget", "NuGet", nil, false),
        ("go-build", "Go Toolchain", nil, false),
        ("goimports", "Go Toolchain", nil, false),
        ("hermit", "Hermit", nil, false),
        ("pub-cache", "Flutter / Dart Pub", nil, false),
        ("ms-playwright", "Playwright", nil, false),
        ("playwright", "Playwright", nil, false),
        ("jetbrains", "JetBrains IDEs", nil, false),
        ("docker", "Docker", "com.docker.docker", false),
        ("adobe", "Adobe Creative Cloud", nil, false),
        ("jianying", "剪映专业版", "com.lemon.lvpro", false),
        ("figma", "Figma", "com.figma.Desktop", false),
        ("bohemiancoding.sketch", "Sketch", "com.bohemiancoding.sketch3", false),
        ("sketch", "Sketch", "com.bohemiancoding.sketch3", false)
    ]

    struct RunningAppsSnapshot: Sendable {
        let timestamp: TimeInterval
        let runningBIDs: Set<String>
        let runningNames: Set<String>
        let installedFallbackByBID: [String: (name: String, url: URL)]
    }

    static let cachedIdentities = LockedValue<(timestamp: TimeInterval, isRefreshing: Bool, items: [UninstallerEngine.AppIdentity])>((0, false, []))
    static let cachedRunningSnapshot = LockedValue<RunningAppsSnapshot>(RunningAppsSnapshot(timestamp: 0, runningBIDs: [], runningNames: [], installedFallbackByBID: [:]))
    static let cachedSectionGroups = LockedValue<[String: [SmartAppCacheGroup]]>([:])

    static func cachedFastInstalledAppIdentities(allowSyncFetch: Bool = !Thread.isMainThread) -> [UninstallerEngine.AppIdentity] {
        let now = ProcessInfo.processInfo.systemUptime
        let state = cachedIdentities.withValue { current -> (hit: [UninstallerEngine.AppIdentity]?, shouldSpawnAsync: Bool) in
            if !current.items.isEmpty && (now - current.timestamp < 30.0 || !allowSyncFetch) {
                let needsBackgroundRefresh = (now - current.timestamp >= 30.0) && !current.isRefreshing
                if needsBackgroundRefresh {
                    current.isRefreshing = true
                }
                return (current.items, needsBackgroundRefresh)
            }
            if !allowSyncFetch {
                let shouldSpawn = !current.isRefreshing
                if shouldSpawn {
                    current.isRefreshing = true
                }
                return ([], shouldSpawn)
            }
            return (nil, false)
        }
        if state.shouldSpawnAsync {
            DispatchQueue.global(qos: .userInitiated).async {
                let fresh = UninstallerEngine.fastInstalledAppIdentities()
                let t = ProcessInfo.processInfo.systemUptime
                cachedIdentities.withValue { $0 = (t, false, fresh) }
            }
        }
        if let hit = state.hit {
            return hit
        }
        let fresh = UninstallerEngine.fastInstalledAppIdentities()
        cachedIdentities.withValue { $0 = (now, false, fresh) }
        return fresh
    }

    static func currentRunningSnapshot(allowSyncRefresh: Bool = true) -> RunningAppsSnapshot {
        let now = ProcessInfo.processInfo.systemUptime
        if let hit = cachedRunningSnapshot.withValue({ $0.timestamp > 0 && (now - $0.timestamp < 5.0 || !allowSyncRefresh) ? $0 : nil }) {
            return hit
        }
        var runningBIDs = Set<String>()
        var runningNames = Set<String>()
        var fallbackByBID: [String: (name: String, url: URL)] = [:]
        for running in NSWorkspace.shared.runningApplications {
            if let bid = running.bundleIdentifier?.lowercased() {
                runningBIDs.insert(bid)
                if let name = running.localizedName, !name.isEmpty,
                   let url = running.bundleURL, fallbackByBID[bid] == nil {
                    fallbackByBID[bid] = (name, url)
                }
            }
            if let name = running.localizedName?.lowercased() {
                runningNames.insert(name)
            }
        }
        let snap = RunningAppsSnapshot(
            timestamp: now,
            runningBIDs: runningBIDs,
            runningNames: runningNames,
            installedFallbackByBID: fallbackByBID
        )
        cachedRunningSnapshot.withValue { $0 = snap }
        return snap
    }

    static func cachedGroups(for section: SmartCleanSectionData) -> [SmartAppCacheGroup]? {
        let cacheKey = section.cacheIdentityKey
        return cachedSectionGroups.withValue { $0[cacheKey] }
    }

    static func prewarmSections(_ sections: [SmartCleanSectionData]) {
        guard !sections.isEmpty else { return }
        _ = cachedFastInstalledAppIdentities(allowSyncFetch: true)
        _ = currentRunningSnapshot(allowSyncRefresh: true)
        for section in sections {
            let cacheKey = section.cacheIdentityKey
            if cachedSectionGroups.withValue({ $0[cacheKey] != nil }) {
                continue
            }
            let built = buildGroups(kind: section.kind, items: section.items, allowSyncDiskWork: true)
            cachedSectionGroups.withValue { store in
                if store.count > 64 {
                    store.removeAll(keepingCapacity: true)
                }
                store[cacheKey] = built
            }
        }
    }

    @MainActor
    static func loadGroupsAsync(
        for section: SmartCleanSectionData,
        completion: @escaping @MainActor ([SmartAppCacheGroup]) -> Void
    ) {
        if let hit = cachedGroups(for: section) {
            completion(hit)
            return
        }
        let kind = section.kind
        let items = section.items
        let cacheKey = section.cacheIdentityKey
        DispatchQueue.global(qos: .userInitiated).async {
            if let hit = cachedSectionGroups.withValue({ $0[cacheKey] }) {
                DispatchQueue.main.async {
                    completion(hit)
                }
                return
            }
            let built = buildGroups(kind: kind, items: items, allowSyncDiskWork: true)
            cachedSectionGroups.withValue { store in
                if store.count > 64 {
                    store.removeAll(keepingCapacity: true)
                }
                store[cacheKey] = built
            }
            DispatchQueue.main.async {
                completion(built)
            }
        }
    }

    static func buildGroups(for section: SmartCleanSectionData) -> [SmartAppCacheGroup] {
        let cacheKey = section.cacheIdentityKey
        if let hit = cachedSectionGroups.withValue({ $0[cacheKey] }) {
            return hit
        }
        let allowSync = !Thread.isMainThread
        let groups = buildGroups(kind: section.kind, items: section.items, allowSyncDiskWork: allowSync)
        cachedSectionGroups.withValue { store in
            if store.count > 64 {
                store.removeAll(keepingCapacity: true)
            }
            store[cacheKey] = groups
        }
        return groups
    }

    static func buildGroups(
        kind: SmartCleanSectionKind,
        items: [Node],
        allowSyncDiskWork: Bool = !Thread.isMainThread
    ) -> [SmartAppCacheGroup] {
        let installed = cachedFastInstalledAppIdentities(allowSyncFetch: allowSyncDiskWork)
        var installedByBID: [String: (name: String, url: URL)] = [:]
        var installedByName: [String: (name: String, url: URL)] = [:]
        for app in installed {
            installedByBID[app.bundleID.lowercased()] = (app.name, app.url)
            installedByName[app.name.lowercased()] = (app.name, app.url)
        }
        let runningSnap = currentRunningSnapshot(allowSyncRefresh: allowSyncDiskWork)
        let runningBIDs = runningSnap.runningBIDs
        let runningNames = runningSnap.runningNames
        for (bid, fallback) in runningSnap.installedFallbackByBID where installedByBID[bid] == nil {
            installedByBID[bid] = fallback
        }

        let kbApps = KnowledgeBaseManager.shared.applicationsByBundleID
        let electronDirs = KnowledgeBaseManager.shared.authored.electronDirectories
        var electronDirToBID: [String: String] = [:]
        for (bid, dir) in electronDirs {
            electronDirToBID[dir.lowercased()] = bid
        }

        var groupedNodes: [String: (identity: ResolvedAppIdentity, nodes: [Node])] = [:]
        for item in items {
            let identity = resolveIdentity(
                for: item,
                sectionKind: kind,
                installedByBID: installedByBID,
                installedByName: installedByName,
                kbApps: kbApps,
                electronDirToBID: electronDirToBID
            )
            if groupedNodes[identity.key] == nil {
                groupedNodes[identity.key] = (identity, [item])
            } else {
                groupedNodes[identity.key]?.nodes.append(item)
            }
        }

        var result: [SmartAppCacheGroup] = []
        for (_, entry) in groupedNodes {
            let identity = entry.identity
            let nodes = entry.nodes.sorted { $0.totalSize > $1.totalSize }
            let resolvedIcon = resolveAppIcon(
                for: identity,
                sampleNode: nodes.first,
                loadFromDisk: allowSyncDiskWork
            )

            let allLeaves = nodes.flatMap(\.leaves)
            let allLocked = !allLeaves.isEmpty && allLeaves.allSatisfy { $0.locked || $0.selectionRestrictions.contains(.readOnlyAsset) }
            let hasLocked = allLeaves.contains { $0.locked || $0.selectionRestrictions.contains(.readOnlyAsset) }

            let groupSubtitle: String
            if allLocked {
                groupSubtitle = L10n.format(.appProtectedGroupSubtitleFormat, identity.displayName)
            } else if hasLocked {
                groupSubtitle = L10n.format(.appMixedGroupSubtitleFormat, identity.displayName)
            } else {
                groupSubtitle = identity.subtitle
            }

            let lowerKey = identity.key.lowercased()
            let lowerName = identity.displayName.lowercased()
            let isRunning = runningBIDs.contains(lowerKey)
                || runningNames.contains(lowerName)
                || runningBIDs.contains(where: { lowerKey.contains($0) || $0.contains(lowerKey) })

            result.append(
                SmartAppCacheGroup(
                    id: "\(kind.rawValue):\(identity.key)",
                    title: identity.displayName,
                    subtitle: groupSubtitle,
                    appIcon: resolvedIcon.icon,
                    iconPath: resolvedIcon.iconPath,
                    fallbackSymbol: identity.isXcode ? "hammer.fill" : "app.badge.checkmark",
                    items: nodes,
                    isRunning: isRunning
                )
            )
        }

        return result.sorted { a, b in
            if a.id.hasSuffix(":xcode.dev.junk") != b.id.hasSuffix(":xcode.dev.junk") {
                return a.id.hasSuffix(":xcode.dev.junk")
            }
            return a.totalSize > b.totalSize
        }
    }

    static func resolveIdentity(
        for node: Node,
        sectionKind: SmartCleanSectionKind,
        installedByBID: [String: (name: String, url: URL)],
        installedByName: [String: (name: String, url: URL)],
        kbApps: [String: KBApplication],
        electronDirToBID: [String: String]
    ) -> ResolvedAppIdentity {
        let path = node.path
        let lowerPath = path.lowercased()
        let ruleID = node.ruleEvidence?.id ?? node.leaves.first?.ruleEvidence?.id ?? ""

        // 1. Xcode 专属开发垃圾组
        if sectionKind == .developer && (
            ruleID.hasPrefix("JC.DEV.XCODE.")
            || ruleID == "JC.DEV.SIMCTL.RUNTIME"
            || lowerPath.contains("/developer/xcode")
            || lowerPath.contains("/coresimulator")
            || lowerPath.contains("com.apple.dt.xcode")
        ) {
            let xcodeURL = installedByBID["com.apple.dt.xcode"]?.url
                ?? (FileManager.default.fileExists(atPath: "/Applications/Xcode.app") ? URL(fileURLWithPath: "/Applications/Xcode.app") : nil)
            return ResolvedAppIdentity(
                key: "xcode.dev.junk",
                displayName: L10n.localized(.xcodeDevJunkTitle),
                subtitle: L10n.localized(.xcodeCacheGroupSubtitle),
                appURL: xcodeURL,
                isXcode: true
            )
        }

        // 2. 项目构建依赖缓存（如 node_modules / target / .venv）按项目归组
        if ruleID == "JC.DEV.PROJECT", !path.isEmpty {
            let url = URL(fileURLWithPath: path)
            let projectName = url.deletingLastPathComponent().lastPathComponent
            let display = projectName.isEmpty ? node.name : projectName
            return ResolvedAppIdentity(
                key: "project.\(display.lowercased())",
                displayName: display,
                subtitle: L10n.format(.appCacheGroupSubtitleFormat, display),
                appURL: nil,
                isXcode: false
            )
        }

        // 3. 提取容器或目录 Token
        let token = extractContainerToken(from: path, fallbackName: node.name, ownerBundleID: node.ownerBundleIDs.first)
        let lowerToken = token.lowercased()

        // 3a. 检查 Electron 数据目录映射 (如 Code -> com.microsoft.VSCode, Cursor -> com.todesktop.230313mzl4w4u92)
        if let mappedBID = electronDirToBID[lowerToken] {
            let lowerBID = mappedBID.lowercased()
            if let inst = installedByBID[lowerBID] {
                return ResolvedAppIdentity(
                    key: lowerBID,
                    displayName: inst.name,
                    subtitle: L10n.format(.appCacheGroupSubtitleFormat, inst.name),
                    appURL: inst.url,
                    isXcode: false
                )
            }
            if let known = knownToolMap.first(where: { $0.bundleID?.lowercased() == lowerBID || $0.token == lowerBID }) {
                return ResolvedAppIdentity(
                    key: lowerBID,
                    displayName: known.name,
                    subtitle: L10n.format(.appCacheGroupSubtitleFormat, known.name),
                    appURL: nil,
                    isXcode: false
                )
            }
        }

        // 3b. 检查已知应用/工具表
        for entry in knownToolMap {
            let matched = entry.exactTokenOnly
                ? (lowerToken == entry.token)
                : (lowerToken == entry.token || lowerPath.contains(entry.token))
            if matched {
                let bidKey = entry.bundleID?.lowercased() ?? entry.token
                let appURL = entry.bundleID.flatMap { installedByBID[$0.lowercased()]?.url }
                    ?? installedByName[entry.name.lowercased()]?.url
                let displayName = entry.bundleID.flatMap { installedByBID[$0.lowercased()]?.name } ?? entry.name
                return ResolvedAppIdentity(
                    key: "known.\(bidKey)",
                    displayName: displayName,
                    subtitle: L10n.format(.appCacheGroupSubtitleFormat, displayName),
                    appURL: appURL,
                    isXcode: false
                )
            }
        }

        // 3c. 检查已安装应用 Bundle ID（含前缀回退，如 com.foo.app.ShipIt -> com.foo.app）
        for candidateBID in candidateBundleIDs(from: lowerToken) {
            if let inst = installedByBID[candidateBID] {
                return ResolvedAppIdentity(
                    key: candidateBID,
                    displayName: inst.name,
                    subtitle: L10n.format(.appCacheGroupSubtitleFormat, inst.name),
                    appURL: inst.url,
                    isXcode: false
                )
            }
            if let kbApp = kbApps[candidateBID] {
                let appURL = installedByName[kbApp.name.lowercased()]?.url
                return ResolvedAppIdentity(
                    key: candidateBID,
                    displayName: kbApp.name,
                    subtitle: L10n.format(.appCacheGroupSubtitleFormat, kbApp.name),
                    appURL: appURL,
                    isXcode: false
                )
            }
        }

        // 3d. 检查已安装应用名称直接匹配
        if let inst = installedByName[lowerToken] {
            return ResolvedAppIdentity(
                key: inst.name.lowercased(),
                displayName: inst.name,
                subtitle: L10n.format(.appCacheGroupSubtitleFormat, inst.name),
                appURL: inst.url,
                isXcode: false
            )
        }

        // 3e. 兜底：美化反向域名或文件夹名
        let prettyName = humanizeToken(token)
        let matchedURL = installedByName[prettyName.lowercased()]?.url
        return ResolvedAppIdentity(
            key: prettyName.lowercased(),
            displayName: prettyName,
            subtitle: L10n.format(.appCacheGroupSubtitleFormat, prettyName),
            appURL: matchedURL,
            isXcode: false
        )
    }

    static func extractContainerToken(from path: String, fallbackName: String, ownerBundleID: String?) -> String {
        if let bid = ownerBundleID, !bid.isEmpty {
            return stripHelperSuffix(bid)
        }
        let components = path.split(separator: "/").map(String.init)
        if let libIndex = components.firstIndex(of: "Library"), libIndex + 1 < components.count {
            let category = components[libIndex + 1]
            if (category == "Caches" || category == "Logs" || category == "Saved Application State") && libIndex + 2 < components.count {
                let first = components[libIndex + 2]
                if (first.lowercased() == "google" || first.lowercased() == "bravesoftware" || first.lowercased() == "microsoft") && libIndex + 3 < components.count {
                    return "\(first) \(components[libIndex + 3])"
                }
                return stripHelperSuffix(first)
            }
            if category == "Application Support" && libIndex + 2 < components.count {
                let first = components[libIndex + 2]
                if (first.lowercased() == "google" || first.lowercased() == "bravesoftware") && libIndex + 3 < components.count {
                    return "\(first) \(components[libIndex + 3])"
                }
                return stripHelperSuffix(first)
            }
            if category == "Containers" && libIndex + 2 < components.count {
                return stripHelperSuffix(components[libIndex + 2])
            }
            if category == "Group Containers" && libIndex + 2 < components.count {
                return stripTeamPrefix(stripHelperSuffix(components[libIndex + 2]))
            }
        }
        return stripHelperSuffix(fallbackName)
    }

    static func stripHelperSuffix(_ raw: String) -> String {
        var s = raw
        let suffixes = [
            ".BundleMigration", ".ShipIt", ".savedState", ".helper", ".Helper", ".Updater", ".updater",
            ".Renderer", ".GPU", ".Plugin", "-updater"
        ]
        for suffix in suffixes where s.hasSuffix(suffix) && s.count > suffix.count {
            s = String(s.dropLast(suffix.count))
        }
        return s
    }

    static func stripTeamPrefix(_ raw: String) -> String {
        let parts = raw.split(separator: ".")
        if let first = parts.first, first.count == 10,
           first.allSatisfy({ $0.isNumber || ($0 >= "A" && $0 <= "Z") }),
           parts.count >= 3 {
            return parts.dropFirst().joined(separator: ".")
        }
        return raw
    }

    static func candidateBundleIDs(from lowerToken: String) -> [String] {
        var result = [lowerToken]
        let parts = lowerToken.split(separator: ".")
        if parts.count >= 4 {
            result.append(parts.dropLast().joined(separator: "."))
        }
        return result
    }

    static func humanizeToken(_ token: String) -> String {
        let cleaned = stripTeamPrefix(stripHelperSuffix(token))
        let parts = cleaned.split(separator: ".").map(String.init)
        if parts.count >= 3,
           ["com", "org", "net", "io", "app", "me", "dev", "cn", "ru", "de", "jp", "co", "uk", "us", "company"].contains(parts[0].lowercased()) {
            let last = parts.last ?? cleaned
            let vendor = parts.count >= 3 ? parts[parts.count - 2] : ""
            if ["client", "desktop", "mac", "app", "macos", "browser"].contains(last.lowercased()), !vendor.isEmpty {
                return vendor.prefix(1).uppercased() + vendor.dropFirst()
            }
            return last.prefix(1).uppercased() + last.dropFirst()
        }
        return cleaned
    }

    static func resolveAppIcon(
        for identity: ResolvedAppIdentity,
        sampleNode: Node?,
        loadFromDisk: Bool = !Thread.isMainThread
    ) -> (icon: NSImage?, iconPath: String?) {
        if let img = sampleNode?.image {
            return (img, identity.appURL?.path ?? sampleNode?.path)
        }
        let targetPath: String? = {
            if let appPath = identity.appURL?.path, !appPath.isEmpty {
                return appPath
            }
            if let nodePath = sampleNode?.path, !nodePath.isEmpty {
                return nodePath
            }
            return nil
        }()
        guard let path = targetPath else {
            return (nil, nil)
        }
        if let cached = FileIconCache.shared.cachedIcon(for: path) {
            return (cached, path)
        }
        guard loadFromDisk else {
            return (nil, path)
        }
        if let appURL = identity.appURL, FileManager.default.fileExists(atPath: appURL.path) {
            return (FileIconCache.shared.icon(for: appURL.path), appURL.path)
        }
        if let nodePath = sampleNode?.path, !nodePath.isEmpty {
            return (FileIconCache.shared.icon(for: nodePath), nodePath)
        }
        return (nil, path)
    }
}

// ============================================================
//  MARK: - 一级应用行视图 (`SmartAppCacheGroupView` —— 展开直接显示需要清空的文件夹)
// ============================================================
