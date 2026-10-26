import SwiftUI

// ============================================================
//  智能呵护 & 我的工具
//  对应原版 SmartCareModule 的卡片网格与 ToolboxModule 的工具集合
// ============================================================

// MARK: - 智能呵护

struct SmartCareDashboard: View {
    @EnvironmentObject var state: AppState

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(SmartCareModule.cards, id: \.self) { key in
                            SmartCard(key: key)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 130)
            }

            // 悬浮 1:1 核心操作按钮 (UbiquitousButton)
            let total = state.smartCards.values
                .filter { $0.included }
                .reduce(Int64(0)) { $0 + $1.size }
            UbiquitousButton(
                mode: .idle(title: L10n.localized(.run), subtitle: total > 0 ? Fmt.size(total) : nil),
                hue: state.spec.hue,
                size: 94
            ) {
                state.runSmartCleanup()
            }
            .padding(.bottom, -12)
        }
    }

    var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.localized(.dashboardReadyToRunPrompt))
                    .font(.system(size: 19, weight: .semibold)).foregroundStyle(.white)
                Text(L10n.localized(.dashboardOneScanAllBenefitsDesc))
                    .font(.system(size: 12)).foregroundStyle(Aurora.onDarkSub)
                HStack(spacing: 16) {
                    infoChip(L10n.localized(.labelUsed), Fmt.size(state.disk.used))
                    infoChip(L10n.localized(.labelFreeAvailable), Fmt.size(state.disk.free))
                }
                .padding(.top, 4)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                let total = state.smartCards.values
                    .filter { $0.included }
                    .reduce(Int64(0)) { $0 + $1.size }
                if total > 0 {
                    Text(L10n.format(.checkedItemsFoundActionableFormat, Fmt.size(total)))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                Button {
                    state.scanAllSmartCards()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .bold))
                        Text(L10n.localized(.actionRescan))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Color.white.opacity(0.9))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.black.opacity(0.28)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8))
    }

    func infoChip(_ k: String, _ v: String) -> some View {
        HStack(spacing: 5) {
            Text(k).font(.system(size: 10)).foregroundStyle(Aurora.onDarkTert)
            Text(v).font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Aurora.onDarkSub).monospacedDigit()
        }
    }
}

struct SmartCard: View {
    @EnvironmentObject var state: AppState
    var key: String

    var spec: ModuleSpec { ModuleRegistry.spec(for: key) }
    var card: SmartCardState? { state.smartCards[key] }

    @State private var hover = false

    /// 对应原版 3D 拟真大图素材
    private var cardBigAsset: String {
        switch key {
        case "junk": return "cm_catbig_system-junk"
        case "performance": return "cm_catbig_maintenance-tasks"
        case "organize": return "cm_catbig_duplicates"
        case "applications": return "cm_catbig_uninstaller"
        default: return "cm_catbig_system-junk"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 左半部：文案信息与操作
            VStack(alignment: .leading, spacing: 0) {
                // 1. 模块小标题
                HStack(spacing: 6) {
                    let art = ModuleArtRegistry.art(key)
                    if let img = Art.ns(art.sidebar) {
                        Image(nsImage: img)
                            .resizable().interpolation(.high).scaledToFit()
                            .frame(width: 18, height: 18)
                    } else {
                        Image(systemName: spec.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(spec.accent)
                    }

                    Text(spec.title)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                }

                Spacer(minLength: 12)

                // 2. 状态主干文案 (1:1 原版 CardCommonView)
                statusLine

                Spacer(minLength: 12)

                // 3. 底部胶囊操作按钮
                bottomAction
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 右半部：复选框 + 3D 拟真大图标
            VStack(alignment: .trailing, spacing: 8) {
                if card?.done == true {
                    CheckBox(state: (card?.included ?? true) ? .on : .off) {
                        state.toggleCardInclusion(key)
                    }
                } else {
                    Color.clear.frame(width: 18, height: 18)
                }

                Spacer(minLength: 4)

                // 3D 拟真大图标（带光晕与阴影）
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [spec.accent.opacity(0.30), Color.clear],
                            center: .center, startRadius: 0, endRadius: 44
                        ))
                        .frame(width: 88, height: 88)

                    if Art.has(cardBigAsset), let img = Art.ns(cardBigAsset) {
                        Image(nsImage: img)
                            .resizable().interpolation(.high).scaledToFit()
                            .frame(width: 74, height: 74)
                    } else {
                        IconTile(icon: spec.icon, size: 68, colors: spec.gradient, radius: 20)
                    }
                }
                .shadow(color: Color.black.opacity(0.35), radius: 8, y: 3)
            }
            .frame(width: 88)
        }
        .padding(18)
        .frame(height: 180, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(hover ? 0.36 : 0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(hover ? spec.accent.opacity(0.50) : Color.white.opacity(0.12), lineWidth: 0.8)
        )
        .onHover { hover = $0 }
    }

    @ViewBuilder
    private var statusLine: some View {
        if let c = card, c.done {
            if c.count > 0 {
                VStack(alignment: .leading, spacing: 3) {
                    Text(titleText(for: key, count: c.count, size: c.size))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .monospacedDigit()
                    Text(subtitleText(for: key))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Aurora.onDarkSub)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(red: 0.35, green: 0.90, blue: 0.55))
                        Text(emptyTitleText(for: key))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text(emptySubtitleText(for: key))
                        .font(.system(size: 11))
                        .foregroundStyle(Aurora.onDarkTert)
                }
            }
        } else if card?.scanning == true {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.localized(.statusScanningEllipsis))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                ProgressView(value: card?.progress ?? 0)
                    .progressViewStyle(.linear)
                    .frame(width: 120)
            }
        } else if let c = card, !c.scanDegradations.isEmpty || !c.scanIssues.isEmpty {
            let isRuleDBDown = c.scanDegradations.contains(.ruleDatabaseUnavailable)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.orange)
                    Text(isRuleDBDown ? L10n.localized(.ruleDatabaseUnavailableTitle) : L10n.localized(.scanCoverageIncomplete))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Text(c.scanIssues.first ?? (isRuleDBDown ? L10n.localized(.ruleDatabaseUnavailableBanner) : subtitleText(for: key)))
                    .font(.system(size: 11))
                    .foregroundStyle(Aurora.onDarkTert)
                    .lineLimit(2)
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.localized(.statusNotYetScanned))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Aurora.onDarkSub)
                Text(L10n.localized(.promptClickScanToInspect))
                    .font(.system(size: 11))
                    .foregroundStyle(Aurora.onDarkTert)
            }
        }
    }

    @ViewBuilder
    private var bottomAction: some View {
        if card?.scanning == true {
            Text("\(Int((card?.progress ?? 0) * 100))%")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Aurora.onDarkSub)
        } else if let c = card, (c.done || !c.scanDegradations.isEmpty || !c.scanIssues.isEmpty), c.count > 0 {
            Button {
                state.open(.smartResult(ModuleKey.parse(key) ?? .junk, tree: card?.tree ?? []))
            } label: {
                HStack(spacing: 4) {
                    Text(L10n.localized(.actionView)).font(.system(size: 11, weight: .semibold))
                    Image(systemName: "chevron.right").font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.18)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.24), lineWidth: 0.6))
            }
            .buttonStyle(.plain)
        } else {
            let hasAttemptedScan = (card?.done == true) || !(card?.scanDegradations.isEmpty ?? true) || !(card?.scanIssues.isEmpty ?? true)
            Button {
                state.scanSmartCard(key)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").font(.system(size: 9, weight: .bold))
                    Text(hasAttemptedScan ? L10n.localized(.actionRescan) : L10n.localized(.actionScan))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(Color.white.opacity(0.9))
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.12)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
    }

    private func titleText(for key: String, count: Int, size: Int64) -> String {
        switch key {
        case "junk": return L10n.format(.dashboardJunkSizeFormat, Fmt.size(size))
        case "performance": return L10n.format(.dashboardTasksToRunCountFormat, count)
        case "organize": return L10n.format(.dashboardOrganizeSizeFormat, Fmt.size(size))
        case "applications": return L10n.format(.dashboardPendingItemsCountFormat, count)
        default: return L10n.format(.dashboardSizeAndItemsCountFormat, Fmt.size(size), count)
        }
    }

    private func subtitleText(for key: String) -> String {
        switch key {
        case "junk": return L10n.localized(.cleanableTag)
        case "performance": return L10n.localized(.dashboardToRunTag)
        case "organize": return L10n.localized(.dashboardRemovableTag)
        case "applications": return L10n.localized(.dashboardToProcessTag)
        default: return L10n.localized(.dashboardOptimizableTag)
        }
    }

    private func emptyTitleText(for key: String) -> String {
        switch key {
        case "junk": return L10n.localized(.dashboardMacIsCleanSubtitle)
        case "performance": return L10n.localized(.dashboardPerformanceNormalSubtitle)
        case "organize": return L10n.localized(.dashboardNothingToOrganizeSubtitle)
        case "applications": return L10n.localized(.dashboardAppsUpToDateSubtitle)
        default: return L10n.localized(.dashboardAllIsWellSubtitle)
        }
    }

    private func emptySubtitleText(for key: String) -> String {
        switch key {
        case "junk": return L10n.localized(.dashboardNoJunkFoundDetail)
        case "performance": return L10n.localized(.dashboardNoTasksToRunDetail)
        case "organize": return L10n.localized(.dashboardNoDuplicatesFoundDetail)
        case "applications": return L10n.localized(.dashboardNoUpdatesToInstallDetail)
        default: return L10n.localized(.dashboardNoLeftoversDetail)
        }
    }
}

// MARK: - 我的工具

struct ToolboxGrid: View {
    @EnvironmentObject var state: AppState
    @State private var search = ""
    @AppStorage("toolbox.favorites") private var favoritesRaw = ""

    var favorites: Set<String> {
        Set(favoritesRaw.split(separator: "\n").map(String.init))
    }

    var filtered: [ToolItem] {
        guard !search.isEmpty else { return ToolboxModule.tools }
        let q = search.lowercased()
        return ToolboxModule.tools.filter {
            $0.title.lowercased().contains(q) || $0.keywords.lowercased().contains(q)
        }
    }

    var favoriteTools: [ToolItem] { filtered.filter { favorites.contains($0.id) } }
    var otherTools: [ToolItem] { filtered.filter { !favorites.contains($0.id) } }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                SearchField(text: $search, placeholder: L10n.localized(.actionSearchEllipsis)).frame(width: 240)
                if !search.isEmpty {
                    Text(L10n.format(.foundItemsCountFormat, filtered.count))
                        .font(.system(size: 11)).foregroundStyle(Theme.sub)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .frame(height: 52)

            Divider().opacity(0.5)

            if filtered.isEmpty {
                EmptyState(icon: "magnifyingglass",
                           title: L10n.localized(.toolboxNoMatchingToolsPrompt),
                           subtitle: L10n.localized(.searchNoResultsRetryPrompt),
                           colors: Theme.gradient(Theme.tool))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !favoriteTools.isEmpty {
                            SectionLabel(text: L10n.localized(.toolboxTabFavorites)).padding(.horizontal, 2)
                            grid(favoriteTools)
                        }
                        SectionLabel(text: favoriteTools.isEmpty ? L10n.localized(.toolboxTabAllTools) : L10n.localized(.toolboxCategoryOtherTools))
                            .padding(.horizontal, 2)
                            .padding(.top, favoriteTools.isEmpty ? 0 : 4)
                        grid(otherTools)
                    }
                    .padding(24)
                }
            }
        }
    }

    func grid(_ tools: [ToolItem]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 12)], spacing: 12) {
            ForEach(tools) { t in
                ToolCard(tool: t, favorited: favorites.contains(t.id)) {
                    toggleFavorite(t)
                } onOpen: {
                    state.openTool(t)
                }
            }
        }
    }

    func toggleFavorite(_ t: ToolItem) {
        var f = favorites
        if f.contains(t.id) { f.remove(t.id) } else { f.insert(t.id) }
        favoritesRaw = f.sorted().joined(separator: "\n")
    }
}

struct ToolCard: View {
    var tool: ToolItem
    var favorited: Bool
    var onFavorite: () -> Void
    var onOpen: () -> Void

    @State private var hover = false

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                // 3D 拟真图标或原生图标
                if !tool.asset.isEmpty, Art.has(tool.asset), let img = Art.ns(tool.asset) {
                    Image(nsImage: img)
                        .resizable().interpolation(.high).scaledToFit()
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.28), radius: 5, y: 2)
                } else {
                    IconTile(icon: tool.icon, size: 36, colors: Theme.gradient(tool.accent))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(tool.title)
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.text)
                        .lineLimit(1)
                    Text(tool.subtitle)
                        .font(.system(size: 10.5)).foregroundStyle(Theme.sub)
                        .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button(action: onFavorite) {
                    Image(systemName: favorited ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundStyle(favorited ? Theme.amber : Theme.tert)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(favorited ? L10n.localized(.favoriteAdded) : L10n.localized(.favoriteAdd))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(hover ? tool.accent.opacity(0.12) : Theme.card))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(hover ? tool.accent.opacity(0.38) : Theme.sep, lineWidth: 0.6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}
