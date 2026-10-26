import SwiftUI
import AppKit

// ============================================================
//  MARK: - 单个已安装应用行与内联文件夹用途展开 (`InstalledAppRow`)
// ============================================================

struct InstalledAppRow: View {
    @EnvironmentObject var state: AppState
    let app: Node
    let maxAppSize: Int64
    let isExpanded: Bool
    let runningBIDs: Set<String>
    let runningPaths: Set<String>
    let onToggleExpand: () -> Void
    let onToggleAppCheck: () -> Void

    @State var hoverHeader = false

    var allLeaves: [Node] {
        app.leaves
    }

    /// 「清除」分组：已证实的应用本体和 L1 项。
    var clearLeaves: [Node] {
        allLeaves.filter { AppFolderClassifier.isDefaultClearItem($0) }
    }

    /// 「需要确认」分组：应用支持、容器、共享容器、偏好设置、启动代理等用户配置
    var confirmLeaves: [Node] {
        allLeaves.filter { !AppFolderClassifier.isDefaultClearItem($0) }
    }

    var selectedSizeInApp: Int64 {
        allLeaves.filter { state.selection.contains($0.id) }.reduce(0) { $0 + $1.totalSize }
    }

    var unselectedConfirmSize: Int64 {
        allLeaves.filter { !state.selection.contains($0.id) }.reduce(0) { $0 + $1.totalSize }
    }

    var appCheckboxState: CheckboxState {
        let selectable = allLeaves.filter { !$0.locked }
        guard !selectable.isEmpty else { return .locked }
        let selCount = selectable.filter { state.selection.contains($0.id) }.count
        if selCount == 0 { return .none }
        if selCount == selectable.count { return .all }
        return .all // 只要勾选了该 App 的默认卸载集，右侧复选框即显示为勾选态
    }

    var isAnySelected: Bool {
        allLeaves.contains { state.selection.contains($0.id) }
    }

    var appVersionText: String {
        if let v = app.meta.first(where: { $0.0 == "Version" || $0.0 == L10n.localized(.labelVersion) })?.1, !v.isEmpty {
            return v
        }
        return ""
    }

    var isAppActiveNow: Bool {
        if app.isActiveNow { return true }
        if let bid = app.meta.first(where: { $0.0 == "Bundle Identifier" || $0.0 == L10n.localized(.labelBundleIdentifier) })?.1, !bid.isEmpty {
            if runningBIDs.contains(bid.lowercased()) {
                return true
            }
        }
        if let u = app.url {
            if runningPaths.contains(u.path) {
                return true
            }
        }
        return false
    }

    var activityInfo: (text: String, isOld: Bool, isActive: Bool) {
        if isAppActiveNow {
            return (L10n.localized(.statusActive), false, true)
        }
        guard let d = app.date else {
            return (L10n.localized(.statusNotOpenedRecently), true, false)
        }
        let now = Date()
        let diff = max(0, now.timeIntervalSince(d))
        let minutes = Int(diff / 60)
        let hours = Int(diff / 3600)
        let days = Int(diff / 86400)

        if minutes < 60 {
            let m = max(1, minutes)
            return ("\(m)\(L10n.localized(.activityMinutesAgoSuffix))", false, false)
        } else if hours < 24 {
            return ("\(hours)\(L10n.localized(.activityHoursAgoSuffix))", false, false)
        } else if days < 30 {
            return ("\(days)\(L10n.localized(.activityDaysAgoSuffix))", false, false)
        } else {
            let months = max(1, days / 30)
            return ("\(months)\(L10n.localized(.activityMonthsAgoSuffix))", months >= 3, false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. 头部行（对齐视觉：高清阴影图标 + 琥珀色活动胶囊 + 体积可视化列）
            HStack(alignment: .center, spacing: 14) {
                appIconView
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(app.name)
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)

                        // 独立的圆角半透明胶囊标签 (Badge)
                        // 独立的圆角半透明胶囊标签 (MetallicBadge)
                        let act = activityInfo
                        MetallicBadge(
                            text: act.text,
                            color: act.isActive ? Theme.green : (act.isOld ? Theme.amber : Theme.sub),
                            icon: act.isActive ? "circle.fill" : nil
                        )
                    }

                    HStack(spacing: 4) {
                        if !appVersionText.isEmpty {
                            Text(appVersionText)
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.sub)
                            Text("·").foregroundStyle(Theme.tert)
                        }
                        // 展示 App 主程序体积
                        Text(Fmt.size(app.appBundleSize))
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.sub)
                            .monospacedDigit()

                        // 若存在数据文件，展示「数据 XX GB」
                        if app.appDataSize > 0 {
                            Text("·").foregroundStyle(Theme.tert)
                            Text("\(L10n.localized(.labelData)) \(Fmt.size(app.appDataSize))")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.sub)
                                .monospacedDigit()
                        }
                    }
                }

                Spacer(minLength: 16)

                // 右侧：选中或展开时状态提示 + 体积可视化列 + 复选框
                HStack(spacing: 14) {
                    if isAnySelected || isExpanded {
                        HStack(spacing: 6) {
                            if selectedSizeInApp > 0 {
                                Text("\(L10n.localized(.remove)) \(Fmt.size(selectedSizeInApp))")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Theme.sub)
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            if unselectedConfirmSize > 0 {
                                if selectedSizeInApp > 0 {
                                    Text("·").foregroundStyle(Theme.tert)
                                }
                                Text("\(L10n.localized(.labelAndMore)) \(Fmt.size(unselectedConfirmSize)) \(L10n.localized(.safetyReview))")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.sub)
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.sub)
                        }
                    } else if hoverHeader {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.tert)
                    }

                    // 体积可视化列：15pt 等宽粗体 + LiquidProgressBar
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(Fmt.size(app.totalSize))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.text)
                            .monospacedDigit()

                        LiquidProgressBar(
                            progress: maxAppSize > 0 ? Double(app.totalSize) / Double(maxAppSize) : 0.05,
                            tint: Theme.accent,
                            secondaryTint: Theme.accent2,
                            height: 4
                        )
                        .frame(width: 80)
                    }
                    .frame(width: 84, alignment: .trailing)

                    FluidCheckbox(state: appCheckboxState, tint: Theme.accent, a11yLabel: app.name) {
                        onToggleAppCheck()
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture {
                onToggleExpand()
            }
            .onHover { hoverHeader = $0 }

            // 2. 内联展开区：展示「清除」与「需要确认」两组文件夹及其具体用途
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if !clearLeaves.isEmpty {
                        folderGroupSection(
                            title: L10n.localized(.remove),
                            leaves: clearLeaves
                        )
                    }

                    if !confirmLeaves.isEmpty {
                        folderGroupSection(
                            title: L10n.localized(.needsConfirmationTag),
                            leaves: confirmLeaves
                        )
                    }
                }
                .padding(.leading, 18)
                .padding(.trailing, 18)
                .padding(.bottom, 16)
                .padding(.top, 4)
            }
        }
        .glassBentoCard(
            cornerRadius: 13,
            isHighlighted: isAnySelected,
            isHovered: hoverHeader,
            padding: 0
        )
    }

    func folderGroupSection(title: String, leaves: [Node]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(Theme.tert)
                .padding(.leading, 6)
                .padding(.bottom, 2)

            ForEach(leaves) { leaf in
                AppFolderDetailRow(leaf: leaf)
            }
        }
    }

    @ViewBuilder
    var appIconView: some View {
        let icon: NSImage = {
            if let img = app.image {
                return img
            }
            if let p = app.url?.path, !p.isEmpty {
                return FileIconCache.shared.icon(for: p)
            }
            if !app.path.isEmpty {
                return FileIconCache.shared.icon(for: app.path)
            }
            if #available(macOS 12.0, *) {
                return NSWorkspace.shared.icon(for: .application)
            } else {
                return NSWorkspace.shared.icon(forFileType: "app")
            }
        }()

        Image(nsImage: icon)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .shadow(color: Color.black.opacity(Theme.isDark ? 0.35 : 0.16), radius: 4, x: 0, y: 2)
    }
}

// ============================================================
//  MARK: - 应用关联文件夹单行（1:1 对齐图4：`[☑] [用途标签] [路径] [大小/空]`）
// ============================================================

struct AppFolderDetailRow: View {
    @EnvironmentObject var state: AppState
    let leaf: Node

    @State var hover = false

    var isChecked: Bool {
        state.selection.contains(leaf.id)
    }

    var folderMeta: (shortLabel: String, detailUsage: String) {
        AppFolderClassifier.describe(leaf)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            FluidCheckbox(state: leaf.locked ? .locked : (isChecked ? .all : .none), tint: Theme.accent,
                          a11yLabel: folderMeta.shortLabel) {
                state.toggle(leaf)
            }

            // 固定宽度文件夹类别短标签（如 `App`、`缓存`、`临时缓存`、`HTTP 存储`、`容器`、`日志`）
            Text(folderMeta.shortLabel)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Theme.sub)
                .frame(width: 72, alignment: .leading)
                .lineLimit(1)

            // 路径单独清晰展示，悬停 tooltip 显示具体用途说明（不在行内拼接长句导致严重截断）
            Text(formatDisplayPath(leaf.path.isEmpty ? leaf.name : leaf.path))
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundStyle(isChecked ? Theme.text : Theme.sub)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(folderMeta.detailUsage)

            Spacer(minLength: 12)

            if hover, let url = leaf.url {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.sub)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Theme.hover))
                }
                .buttonStyle(.plain)
                .help(L10n.localized(.actionRevealInFinder))
            }

            // 大小为 0 时显示「空」，非 0 显示格式化尺寸
            if leaf.totalSize == 0 {
                Text(L10n.localized(.labelEmpty))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Theme.tert)
                    .frame(minWidth: 64, alignment: .trailing)
            } else {
                Text(Fmt.size(leaf.totalSize))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(isChecked ? Theme.text : Theme.sub)
                    .monospacedDigit()
                    .frame(minWidth: 64, alignment: .trailing)
            }
        }
        .padding(.vertical, 3.5)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(hover ? Theme.hover.opacity(0.6) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !leaf.locked {
                state.toggle(leaf)
            }
        }
        .onHover { hover = $0 }
    }

    func formatDisplayPath(_ rawPath: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if rawPath.hasPrefix(home) {
            return "~" + rawPath.dropFirst(home.count)
        }
        if rawPath.hasPrefix("/var/folders/") {
            return "/private" + rawPath
        }
        return rawPath
    }
}

// ============================================================
//  MARK: - 文件夹用途分类器 (`AppFolderClassifier`)
// ============================================================

enum AppFolderClassifier {
    /// 判断该目录是否归入「清除」分组（默认安全勾选）：
    /// 已证实的 App 本体角色与结构化 L1；路径名不授予默认删除权限。
    static func isDefaultClearItem(_ leaf: Node) -> Bool {
        UninstallSafety.isDefaultItem(leaf)
    }

    /// 返回每个文件夹的「短类别标签」与「具体用途说明」
    static func describe(_ leaf: Node) -> (shortLabel: String, detailUsage: String) {
        let p = leaf.path.lowercased()
        let appBodyTag = L10n.localized(.appBundleBody)
        if leaf.tags.contains("Application Bundle") || leaf.tags.contains(appBodyTag) || p.hasSuffix(".app") {
            return (
                L10n.localized(.categoryAppBundle),
                L10n.localized(.appMainBundleAndExecutableDesc)
            )
        }
        if p.contains("/var/folders/") {
            return (
                L10n.localized(.categoryTempCache),
                L10n.localized(.macosSystemRuntimeTemporaryCachesAndShaderBuffers)
            )
        }
        if p.contains("/library/caches/") {
            return (
                L10n.localized(.categoryCache),
                L10n.localized(.appRuntimeDownloadAndRenderCachesRebuiltAutomaticallyWhenLaunched)
            )
        }
        if p.contains("/library/httpstorages/") {
            return (
                L10n.localized(.categoryHttpStorage),
                L10n.localized(.networkRequestSessionCachesAndLocalCookieDatabases)
            )
        }
        if p.contains("/library/webkit/") {
            return (
                L10n.localized(.categoryWebKitCache),
                L10n.localized(.embeddedWebkitWebviewOfflineStorageAndScriptCaches)
            )
        }
        if p.contains("/library/logs/") || p.contains("crashreporter") {
            return (
                L10n.localized(.categoryLogs),
                L10n.localized(.applicationRuntimeDebugLogsAndHistoricalCrashReports)
            )
        }
        if p.contains("/saved application state/") {
            return (
                L10n.localized(.categoryWindowState),
                L10n.localized(.savedWindowDimensionsAndScrollPositionsFromLastExit)
            )
        }
        if p.contains("/library/group containers/") {
            return (
                L10n.localized(.categoryGroupContainer),
                L10n.localized(.sharedDatabasesAndAccountSettingsAcrossAppsFromTheSameDeveloper)
            )
        }
        if p.contains("/library/containers/") {
            return (
                L10n.localized(.categoryContainer),
                L10n.localized(.sandboxedAppContainerIncludesSandboxedDocumentsAndUserData)
            )
        }
        if p.contains("/library/preferences/") {
            return (
                L10n.localized(.categoryPreferences),
                L10n.localized(.applicationPreferencesShortcutsAndUiSettingsPlist)
            )
        }
        if p.contains("/launchagents/") || p.contains("/launchdaemons/") {
            return (
                L10n.localized(.categoryBackgroundServices),
                L10n.localized(.launchDaemonsAndBackgroundAutoUpdateConfigurations)
            )
        }
        if p.contains("/library/application support/") {
            return (
                L10n.localized(.categoryAppSupport),
                L10n.localized(.corePluginsLocalBusinessDatabasesAndUserExtensions)
            )
        }
        return (
            L10n.localized(.categoryAssociatedData),
            L10n.localized(.associatedSupportFilesOrConfigurationDirectoriesForTheApplication)
        )
    }
}

// ============================================================
//  MARK: - 卸载残留单行 (`OrphanLeftoverRow`)
// ============================================================

struct OrphanLeftoverRow: View {
    @EnvironmentObject var state: AppState
    let leaf: Node

    @State var hover = false

    var isChecked: Bool {
        state.selection.contains(leaf.id)
    }

    var body: some View {
        let meta = AppFolderClassifier.describe(leaf)
        HStack(spacing: 14) {
            FluidCheckbox(state: isChecked ? .all : .none, tint: Theme.amber, a11yLabel: meta.shortLabel) {
                state.toggle(leaf)
            }

            if let url = leaf.url {
                Image(nsImage: FileIconCache.shared.icon(for: url.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(leaf.name)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    MetallicBadge(text: meta.shortLabel, color: Theme.amber)
                        .layoutPriority(1)
                }

                Text("\(leaf.path) · \(meta.detailUsage)")
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.tert)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer(minLength: 12)

            if hover, let url = leaf.url {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.sub)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Theme.hover))
                }
                .buttonStyle(.plain)
                .help(L10n.localized(.actionRevealInFinder))
            }

            Text(Fmt.size(leaf.totalSize))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isChecked ? Theme.accent : Theme.sub)
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .glassBentoCard(
            cornerRadius: 12,
            isHighlighted: isChecked,
            isHovered: hover,
            padding: 0
        )
        .contentShape(Rectangle())
        .onTapGesture {
            state.toggle(leaf)
        }
        .onHover { hover = $0 }
    }
}

// ============================================================
//  MARK: - IdleAppFeatureCard (首屏能力预览 Bento 微卡片)
// ============================================================

struct IdleAppFeatureCard: View {
    let title: String
    let tag: String
    let subtitle: String
    let systemName: String
    let primaryColor: Color
    let secondaryColor: Color
    @State var hover = false

    var body: some View {
        VStack(spacing: 6) {
            OpticalSquircleIcon(
                systemName: systemName,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                size: 32
            )
            .scaleEffect(hover ? 1.08 : 1.0)

            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)

            Text(tag)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(hover ? Theme.accent : Theme.sub)
                .lineLimit(1)
        }
        .frame(width: 118, height: 96)
        .glassBentoCard(cornerRadius: 13, isHighlighted: false, isHovered: hover, padding: 6)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .help(subtitle)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: hover)
    }
}
