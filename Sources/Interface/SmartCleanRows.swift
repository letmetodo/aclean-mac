import SwiftUI
import AppKit

struct SmartAppCacheGroupView: View {
    @EnvironmentObject var state: AppState
    let group: SmartAppCacheGroup
    let isManualStorage: Bool
    let isExpanded: Bool
    let onToggleExpand: () -> Void

    @State var hover = false
    @State private var asyncLoadedIcon: NSImage? = nil

    var groupCheckboxState: CheckboxState {
        if isManualStorage || group.selectableLeafIDs.isEmpty { return .locked }
        let selected = group.selectableLeafIDs.intersection(state.selection).count
        if selected == 0 { return .none }
        if selected == group.selectableLeafIDs.count { return .all }
        return .partial
    }

    func toggleGroupSelection() {
        guard !isManualStorage, !group.selectableLeafIDs.isEmpty else { return }
        let shouldSelectAll = (groupCheckboxState != .all)
        var next = state.selection
        if shouldSelectAll {
            next.formUnion(group.selectableLeafIDs)
        } else {
            next.subtract(group.selectableLeafIDs)
        }
        state.setManualSelection(next)
    }

    var body: some View {
        // Folder rows are siblings in the parent's lazy stack, not eager children here.
        HStack(spacing: 12) {
            FluidCheckbox(state: groupCheckboxState, tint: Theme.accent, a11yLabel: group.title, action: toggleGroupSelection)

            appIconView(size: 28)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(group.title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)

                if group.isRunning {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5.5, height: 5.5)
                        Text(L10n.localized(.statusRunning))
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(Color.green)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
                    .help(L10n.localized(.statusRunningAppHoverTip))
                }

                Text(group.subtitle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 10)

            Text(Fmt.size(group.totalSize))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.text)
                .monospacedDigit()
                .frame(minWidth: 74, alignment: .trailing)

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.sub)
                .frame(width: 18, height: 18)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(hover ? Theme.hover : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggleExpand()
        }
        .onHover { hover = $0 }
    }

    @ViewBuilder
    func appIconView(size: CGFloat) -> some View {
        let resolvedIcon = group.appIcon
            ?? asyncLoadedIcon
            ?? group.iconPath.flatMap { FileIconCache.shared.cachedIcon(for: $0) }
        Group {
            if let icon = resolvedIcon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: group.fallbackSymbol)
                    .font(.system(size: size * 0.68, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: size, height: size)
            }
        }
        .onAppear {
            guard resolvedIcon == nil, let iconPath = group.iconPath, !iconPath.isEmpty else { return }
            DispatchQueue.global(qos: .utility).async {
                let img = FileIconCache.shared.icon(for: iconPath)
                DispatchQueue.main.async {
                    self.asyncLoadedIcon = img
                }
            }
        }
    }
}

// ============================================================
//  MARK: - 展开后的单条缓存文件夹明细行 (`SmartCleanLeafRow`)
// ============================================================

struct SmartCleanLeafRow: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var config = AppConfigStore.shared
    let leaf: Node
    let isManualStorage: Bool
    var leadingIndent: CGFloat = 46

    @State var hover = false
    @State private var asyncLoadedIcon: NSImage? = nil
    @State var showsCapturedChildren = false

    static let cautionCoral = Color(red: 0.90, green: 0.44, blue: 0.30)

    var isCautionItem: Bool {
        !isManualStorage && (leaf.safety != .safe || !leaf.autoSelected || !leaf.selectionRestrictions.isEmpty)
    }

    var itemCheckboxState: CheckboxState {
        if isManualStorage || leaf.locked {
            return .locked
        }
        let selectable = leaf.leaves.filter { CleanupSelectionPolicy.isUserSelectable($0) }
        guard !selectable.isEmpty else { return .locked }
        let count = selectable.filter { state.selection.contains($0.id) }.count
        return count == 0 ? .none : (count == selectable.count ? .all : .partial)
    }

    var inlineLockExplanation: String? {
        guard itemCheckboxState == .locked else { return nil }
        if let reason = leaf.evaluationReason?.localizedExplanation, !reason.isEmpty {
            return reason
        }
        if !leaf.note.isEmpty {
            return leaf.note
        }
        return L10n.localized(.assetReadOnlyNotice)
    }

    var resolvedCliCommand: String? {
        let p = leaf.path.lowercased()
        let n = leaf.name.lowercased()
        if p.contains("/.ollama/models") || n.contains("ollama model") {
            let raw = leaf.note.isEmpty ? leaf.name : leaf.note
            let cleanTag = raw.components(separatedBy: " · ").last ?? raw
            let parts = cleanTag.split(separator: "/")
            if parts.count >= 2 {
                let model = parts[parts.count - 2]
                let tag = parts[parts.count - 1]
                return "ollama rm \(model):\(tag)"
            } else if !cleanTag.isEmpty {
                let name = cleanTag.trimmingCharacters(in: .whitespacesAndNewlines)
                return "ollama rm \(name)"
            }
        }
        if p.contains("/huggingface") || n.contains("hugging face") {
            return "huggingface-cli delete-cache"
        }
        return nil
    }

    var isIosBackup: Bool {
        leaf.path.lowercased().contains("/mobilesync/backup")
    }

    var isVirtualMachineOrDisk: Bool {
        let p = leaf.path.lowercased()
        return p.contains("docker.raw") || p.contains("data.img") || p.contains("parallels") || p.contains("vmware") || p.contains("utm/machines")
    }

    /// 规则友好名（如「用户缓存」）。该规则未配置标题键时返回 nil。
    var friendlyName: String? {
        JunkRuleTitle.friendlyName(forRuleID: leaf.ruleEvidence?.id)
    }

    /// 主标题：优先友好名，回退技术名。
    var displayName: String { friendlyName ?? leaf.name }

    /// 副标题原名：仅当友好名生效且与原名不同才显示，避免重复占位。
    var secondaryName: String? {
        guard let friendlyName, friendlyName != leaf.name else { return nil }
        return leaf.name
    }

    var effectiveCacheRecommendation: CacheRecommendationSnapshot? {
        leaf.cacheRecommendation ?? leaf.leaves.first?.cacheRecommendation
    }

    var inlineCacheEffectText: String? {
        guard !isManualStorage, itemCheckboxState != .locked, let rec = effectiveCacheRecommendation else { return nil }
        guard rec.state == .suggestedLarge || rec.profileID != nil || rec.reasons.contains(.configurationUnavailable) else { return nil }
        let effects = JunkCacheRecommendationPolicy.localizedEffects(for: rec)
        guard !effects.isEmpty else { return nil }
        return effects.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 10) {
            FluidCheckbox(state: itemCheckboxState, tint: Theme.accent, a11yLabel: leaf.name) {
                state.setSelection(leaf, itemCheckboxState != .all)
            }

            leafIconView
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(secondaryName ?? leaf.name)
                        .accessibilityLabel(secondaryName.map { "\(displayName)，\($0)" } ?? displayName)

                    if itemCheckboxState == .locked {
                        Text(L10n.localized(.assetProtectedBadge))
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(Color.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color.blue.opacity(0.12)))
                    } else if let largeBadge = JunkCacheRecommendationPolicy.localizedLargeBadge(for: effectiveCacheRecommendation) {
                        Text(largeBadge)
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(Self.cautionCoral)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Self.cautionCoral.opacity(0.14)))
                    }
                }

                if let secondaryName {
                    Text(secondaryName)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.tert)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if !leaf.path.isEmpty {
                    Text(abbreviateHomePath(leaf.path))
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.tert)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if let lockReason = inlineLockExplanation {
                    Text(lockReason)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.amber)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else if let effectText = inlineCacheEffectText {
                    Text(effectText)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer(minLength: 8)

            if leaf.isGroup {
                Button {
                    showsCapturedChildren = true
                } label: {
                    Image(systemName: "list.bullet")
                }
                .buttonStyle(.plain)
                .help(L10n.localized(.actionReviewDetails))
                .accessibilityLabel(L10n.localized(.actionReviewDetails))
                .popover(isPresented: $showsCapturedChildren) {
                    VStack(alignment: .leading) {
                        Text(leaf.name).font(.headline).padding()
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(leaf.leaves) { captured in
                                    AnyView(SmartCleanLeafRow(leaf: captured, isManualStorage: isManualStorage))
                                }
                            }
                        }
                    }
                    .frame(width: AppConfig.Remediation.snapshotDetailsWidth,
                           height: AppConfig.Remediation.snapshotDetailsHeight)
                }
            }

            HStack(spacing: 6) {
                if let cli = resolvedCliCommand {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(cli, forType: .string)
                        state.toast = L10n.localized(.assetCopiedToast)
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                            Text(L10n.format(.assetCopyCliCommandFormat, cli))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Theme.hover))
                    }
                    .buttonStyle(.plain)
                    .help(L10n.format(.assetCopyCliCommandFormat, cli))
                } else if isIosBackup {
                    Button {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.settings.Storage") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 10))
                            Text(L10n.localized(.assetOpenSystemStorage))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Theme.hover))
                    }
                    .buttonStyle(.plain)
                    .help(L10n.localized(.assetOpenSystemStorage))
                } else if isVirtualMachineOrDisk {
                    Button {
                        state.moduleKey = .spaceLens
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "rays")
                                .font(.system(size: 10))
                            Text(L10n.localized(.assetInspectInSpaceLens))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Theme.hover))
                    }
                    .buttonStyle(.plain)
                    .help(L10n.localized(.assetInspectInSpaceLens))
                }

                if let url = leaf.url {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    } label: {
                        Image(systemName: "folder")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.sub)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Theme.hover))
                    }
                    .buttonStyle(.plain)
                    .help(L10n.localized(.actionRevealInFinder))
                    .accessibilityLabel(L10n.localized(.actionRevealInFinder))

                    Button {
                        QuickLookHelper.shared.preview(url)
                    } label: {
                        Image(systemName: "eye")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.sub)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Theme.hover))
                    }
                    .buttonStyle(.plain)
                    .help(L10n.localized(.actionQuickLook))
                    .accessibilityLabel(L10n.localized(.actionQuickLook))
                }

                if !isManualStorage {
                    Button {
                        state.ignore(leaf)
                    } label: {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.sub)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Theme.hover))
                    }
                    .buttonStyle(.plain)
                    .help(L10n.localized(.actionAddToIgnoreWhitelist))
                    .accessibilityLabel(L10n.localized(.actionAddToIgnoreWhitelist))
                }
            }
            .opacity(hover ? 1.0 : 0.42)

            if isCautionItem {
                Text(L10n.format(.sizeCautionCleanFormat, Fmt.size(leaf.totalSize)))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Self.cautionCoral)
                    .monospacedDigit()
            } else {
                Text(Fmt.size(leaf.totalSize))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(state.selectedCount(in: leaf) > 0 ? Theme.text : Theme.sub)
                    .monospacedDigit()
                    .frame(minWidth: 68, alignment: .trailing)
            }
        }
        .padding(.leading, leadingIndent)
        .padding(.trailing, 18)
        .padding(.vertical, 5)
        .background(hover ? Theme.hover.opacity(0.5) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isManualStorage && !leaf.locked {
                state.setSelection(leaf, itemCheckboxState != .all)
            }
        }
        .onHover { hover = $0 }
        .contextMenu {
            if let url = leaf.url {
                Button(L10n.localized(.actionRevealInFinder)) {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                Button(L10n.localized(.actionQuickLook)) {
                    QuickLookHelper.shared.preview(url)
                }
                Button(L10n.localized(.actionCopyPath)) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(leaf.path, forType: .string)
                    state.toast = L10n.localized(.toastPathCopied)
                }
                if !isManualStorage && !leaf.locked {
                    Divider()
                    Button(L10n.localized(.actionAddToIgnoreWhitelist)) {
                        state.ignore(leaf)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var leafIconView: some View {
        if let img = leaf.image ?? asyncLoadedIcon {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if !leaf.path.isEmpty {
            // 占位图标 + 异步取图：body 内绝不同步查磁盘 / LaunchServices，
            // 否则展开一个几十项的分组就是几十次主线程图标查询，直接卡住窗口。
            Image(systemName: "folder.fill")
                .font(.system(size: 14))
                .foregroundStyle(Theme.accent)
                .onAppear { loadLeafIconIfNeeded() }
        } else {
            Image(systemName: "folder.fill")
                .font(.system(size: 14))
                .foregroundStyle(Theme.accent)
        }
    }

    func loadLeafIconIfNeeded() {
        guard leaf.image == nil, asyncLoadedIcon == nil else { return }
        let path = leaf.path
        guard !path.isEmpty else { return }
        if let cached = FileIconCache.shared.cachedIcon(for: path) {
            asyncLoadedIcon = cached
            return
        }
        FileIconCache.shared.loadIconAsync(for: path) { img in
            self.asyncLoadedIcon = img
        }
    }

    func abbreviateHomePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}

// ============================================================
//  MARK: - IdleJunkFeatureCard (垃圾清理首屏能力预览 Bento 微卡片)
// ============================================================

struct IdleJunkFeatureCard: View {
    let title: String
    let tag: String
    let subtitle: String
    let systemName: String
    let primaryColor: Color
    let secondaryColor: Color
    @State var hover = false
    @State private var asyncLoadedIcon: NSImage? = nil

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
                .minimumScaleFactor(0.75)

            Text(tag)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(hover ? Theme.accent : Theme.sub)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(width: 118, height: 96)
        .glassBentoCard(cornerRadius: 12, isHighlighted: false, isHovered: hover, padding: 6)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .help(subtitle)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: hover)
    }
}

