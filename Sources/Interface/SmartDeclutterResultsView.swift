import SwiftUI
import AppKit

extension SmartDeclutterView {
    // MARK: - 第三幕：结果态 (Act 3: Results Stage —— 1列全览 / 2列明细)

    var declutterResultStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 34)
                .padding(.top, 16)
                .padding(.bottom, 10)

            Divider().background(Theme.sep.opacity(0.5))

            GeometryReader { geo in
                let compactWidth = min(300, max(250, geo.size.width * 0.30))
                HStack(spacing: 0) {
                    // 分类列表：1列模式下占满100%全宽；2列模式下平滑收缩到左侧紧凑宽度
                    declutterCategoriesListView(isCompact: inspectingSectionKind != nil)
                        .frame(width: inspectingSectionKind == nil ? geo.size.width : compactWidth)
                        .frame(maxHeight: .infinity)

                    if let currentSection = currentInspectingSection {
                        Divider()
                            .background(Theme.sep.opacity(0.45))
                            .transition(.opacity)

                        // 详情列表：2列模式下占大部分页面展示要整理的文件明细
                        declutterCategoryDetailView(section: currentSection)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
            }

            declutterBottomBar
        }
    }

    // MARK: - 分类列表 (全宽 1 列 / 紧凑导航)

    func declutterCategoriesListView(isCompact: Bool) -> some View {
        let total = allSelectableLeaves.count
        let sel = selectedLeaves.count
        let isAllSelected = total > 0 && sel == total
        let isNoneSelected = sel == 0

        return VStack(alignment: .leading, spacing: 0) {
            // 顶部快捷控制条
            if isCompact {
                HStack(alignment: .center, spacing: 8) {
                    Text(L10n.localized(.labelScanResults))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.text)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            inspectingSectionKind = nil
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "rectangle.compress.vertical")
                                .font(.system(size: 10.5))
                            Text(L10n.localized(.actionBack))
                                .font(.system(size: 11.5, weight: .medium))
                        }
                        .foregroundStyle(Theme.sub)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.localized(.actionBack))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    Text(L10n.localized(.declutterCleanProjects))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.text)

                    Spacer()

                    Text("\(L10n.localized(.labelSelected)) \(sel) \(L10n.localized(.unitItems))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.sub)
                        .monospacedDigit()

                    HStack(spacing: 5) {
                        ActionLink(title: tr(.actionSelectAll), enabled: !isAllSelected && total > 0) {
                            var next = state.selection
                            for l in allSelectableLeaves {
                                next.insert(l.id)
                            }
                            state.setManualSelection(next)
                        }
                        Text("·").foregroundStyle(Theme.tert)
                        ActionLink(title: tr(.actionDeselectAll), enabled: !isNoneSelected) {
                            state.setManualSelection([])
                        }
                        Text("·").foregroundStyle(Theme.tert)
                        ActionLink(title: tr(.actionSmartRecommended), enabled: total > 0) {
                            applyRecommendedSelection()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }

            if state.showIgnoredBanner {
                ignoredBanner
                    .padding(.horizontal, isCompact ? 14 : 24)
                    .padding(.bottom, 8)
            }

            // 玻璃胶囊分类列表 (交错弹簧入场)
            ScrollView {
                LazyVStack(spacing: isCompact ? 7 : 10) {
                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        SmartNextGenDeclutterRow(
                            section: section,
                            checkboxState: checkboxState(for: section),
                            selectedCount: selectedCount(in: section),
                            selectedSize: selectedSize(in: section),
                            isCompact: isCompact,
                            isSelected: inspectingSectionKind == section.kind,
                            onToggleSection: { toggleSectionSelection(section) },
                            onSelectSection: {
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                    if inspectingSectionKind == section.kind {
                                        inspectingSectionKind = nil
                                    } else {
                                        inspectingSectionKind = section.kind
                                    }
                                }
                            }
                        )
                        .staggeredAppear(index: index)
                    }
                }
                .padding(.horizontal, isCompact ? 12 : 24)
                .padding(.vertical, 8)
                .padding(.bottom, 12)
            }
            .id("\(config.appearanceMode.rawValue)-\(config.themePreset.rawValue)")
        }
    }

    // MARK: - 2列模式：右侧要清理的项目明细 (占大部分页面)

    func declutterCategoryDetailView(section: SmartDeclutterSectionData) -> some View {
        let isDark = Theme.isDark
        let selCount = selectedCount(in: section)
        let selSize = selectedSize(in: section)
        let totalCount = section.totalCount
        let selectable = section.items.filter { isDeclutterSelectable($0) }

        return VStack(alignment: .leading, spacing: 0) {
            // 详情头部
            HStack(spacing: 12) {
                CleanCategoryVisuals.opticalIcon(for: section.kind, size: 34)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(section.kind.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.text)

                        Text("\(totalCount) \(L10n.localized(.unitItems)) · \(Fmt.size(section.totalSize))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.sub)
                            .monospacedDigit()
                    }

                    Text(section.kind.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.tert)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                // 该分类快捷全选 / 取消全选
                HStack(spacing: 6) {
                    Button(L10n.localized(.actionSelectAll)) {
                        var next = state.selection
                        for item in selectable {
                            next.insert(item.id)
                        }
                        state.setManualSelection(next)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.accent)

                    Text("·").foregroundStyle(Theme.tert)

                    Button(L10n.localized(.actionNone)) {
                        var next = state.selection
                        for item in section.items {
                            next.remove(item.id)
                        }
                        state.setManualSelection(next)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.sub)
                }

                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        inspectingSectionKind = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.sub.opacity(0.65))
                }
                .buttonStyle(.plain)
                .help(L10n.localized(.actionBack))
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider().background(Theme.sep.opacity(0.5))

            // 快捷提示条
            HStack {
                Text("\(L10n.localized(.labelSelected)): \(selCount)/\(totalCount) \(L10n.localized(.unitItems)) · \(Fmt.size(selSize))")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(Theme.sub)
                    .monospacedDigit()

                Spacer()

                if section.kind == .largeOldFiles {
                    thresholdInlineMenu
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 8)
            .background(isDark ? Color.white.opacity(0.02) : Color.black.opacity(0.02))

            Divider().background(Theme.sep.opacity(0.3))

            // 列表
            if section.items.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.tert)
                    Text(L10n.localized(.systemSpotlessSubtitle))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.tert)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(section.items) { leaf in
                            SmartDeclutterLeafRow(leaf: leaf)
                            Divider().background(Theme.sep.opacity(0.35))
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.bottom, 12)
                }
                .id(section.id)
            }
        }
        .background(
            isDark ? Color.white.opacity(0.015) : Color.black.opacity(0.01)
        )
    }

    // MARK: - 底部操作栏

    var declutterBottomBar: some View {
        HStack(alignment: .center, spacing: 16) {
            // 左侧：在2列模式下展示全局快捷推荐/全选/全不选
            if inspectingSectionKind != nil {
                HStack(spacing: 5) {
                    ActionLink(title: tr(.actionSelectAll), enabled: selectedLeaves.count < allSelectableLeaves.count && !allSelectableLeaves.isEmpty) {
                        var next = state.selection
                        for l in allSelectableLeaves {
                            next.insert(l.id)
                        }
                        state.setManualSelection(next)
                    }
                    Text("·").foregroundStyle(Theme.tert)
                    ActionLink(title: tr(.actionDeselectAll), enabled: !selectedLeaves.isEmpty) {
                        state.setManualSelection([])
                    }
                    Text("·").foregroundStyle(Theme.tert)
                    ActionLink(title: tr(.actionSmartRecommended), enabled: !allSelectableLeaves.isEmpty) {
                        applyRecommendedSelection()
                    }
                }
                .font(.system(size: 11.5))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.accent.opacity(0.85))
                    Text(L10n.localized(.declutterSafetyNote))
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.tert)
                }
            }

            Spacer()

            // 右侧：已选大小 + 项数统计 + 立即清理/移到废纸篓主按钮
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(L10n.localized(.selected))
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.sub)

                        Text(Fmt.size(selectedSize))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(selectedSize > 0 ? Theme.accent : Theme.tert)
                            .monospacedDigit()

                        Text("(\(selectedLeaves.count) \(L10n.localized(.unitItems)))")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.sub)
                            .monospacedDigit()
                    }

                    HStack(spacing: 4) {
                        Text("\(L10n.localized(.labelScanResults)):")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.tert)

                        let totalSize = allSelectableLeaves.reduce(Int64(0)) { $0 + $1.totalSize }
                        Text("\(L10n.localized(.cleanableTag)) \(Fmt.size(totalSize)) · \(allSelectableLeaves.count) \(L10n.localized(.unitItems)) · \(activeSectionCount) \(L10n.localized(.unitCategories))")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.tert)
                            .monospacedDigit()
                    }
                }

                GlowingPillButton(
                    title: selectedLeaves.isEmpty ? L10n.localized(.actionMoveToTrashAlt) : "\(L10n.localized(.actionMoveToTrash)) (\(selectedLeaves.count))",
                    subtitle: selectedSize > 0 ? Fmt.size(selectedSize) : nil,
                    icon: "trash.fill",
                    tint: Theme.accent,
                    isEnabled: selectedLeaves.count > 0 && !state.scanning && state.screen != .cleaning,
                    width: 170,
                    height: 40
                ) {
                    state.commitClean(category: nil)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            ZStack {
                VisualEffectView(material: .headerView, blendingMode: .withinWindow)
                Theme.card.opacity(Theme.isDark ? 0.75 : 0.88)
            }
        )
        .overlay(alignment: .top) {
            Divider().background(Theme.sep.opacity(0.6))
        }
    }

    var thresholdInlineMenu: some View {
        let appliedMB = state.appliedLargeFileThresholdMB
        let appliedMonths = state.appliedOldFileMonths
        return Menu {
            Section(L10n.localized(.thresholdLargeFileMinSize)) {
                ForEach([50, 100, 250, 500, 1024], id: \.self) { mb in
                    Button {
                        state.largeFileThresholdMB = mb
                        state.startScan(for: "organize", forceRestart: true)
                    } label: {
                        HStack {
                            Text(mb >= 1024 ? "≥ 1 GB" : "≥ \(mb) MB")
                            if appliedMB == mb {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Section(L10n.localized(.thresholdOldFileMonths)) {
                ForEach([1, 3, 6, 12], id: \.self) { m in
                    Button {
                        state.oldFileMonths = m
                        state.startScan(for: "organize", forceRestart: true)
                    } label: {
                        HStack {
                            Text("≥ \(m) \(L10n.localized(.unitMonths))")
                            if appliedMonths == m {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 10.5))
                Text("≥\(appliedMB)MB / \(appliedMonths)\(L10n.localized(.unitMonths))")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Theme.sub)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(Capsule().fill(Theme.hover))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .disabled(state.scanning)
    }

    var ignoredBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.accent)
            Text(L10n.localized(.bannerAddedToWhitelist))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.text)
            Spacer()
            Button {
                state.undoIgnore()
            } label: {
                Text(L10n.localized(.actionUndo))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.card))
    }

    // MARK: - 勾选与推荐策略

    func selectedCount(in section: SmartDeclutterSectionData) -> Int {
        if hasCachedSections { return cachedSelectionBySection[section.kind]?.selectedCount ?? 0 }
        return section.items.filter { isDeclutterSelectable($0) && state.selection.contains($0.id) }.count
    }

    func selectedSize(in section: SmartDeclutterSectionData) -> Int64 {
        if hasCachedSections { return cachedSelectionBySection[section.kind]?.selectedSize ?? 0 }
        return section.items.filter { isDeclutterSelectable($0) && state.selection.contains($0.id) }.reduce(0) { $0 + $1.totalSize }
    }

    func checkboxState(for section: SmartDeclutterSectionData) -> CheckboxState {
        if hasCachedSections {
            guard let summary = cachedSelectionBySection[section.kind], summary.selectableCount > 0 else { return .none }
            if summary.selectedCount == 0 { return .none }
            if summary.selectedCount == summary.selectableCount { return .all }
            return .partial
        }
        let selectable = section.items.filter { isDeclutterSelectable($0) }
        guard !selectable.isEmpty else { return .none }
        let sel = selectable.filter { state.selection.contains($0.id) }.count
        if sel == 0 { return .none }
        if sel == selectable.count { return .all }
        return .partial
    }

    func toggleSectionSelection(_ section: SmartDeclutterSectionData) {
        let selectable = section.items.filter { isDeclutterSelectable($0) }
        let shouldSelectAll = (checkboxState(for: section) != .all)
        var next = state.selection
        for item in selectable {
            if shouldSelectAll {
                next.insert(item.id)
            } else {
                next.remove(item.id)
            }
        }
        state.setManualSelection(next)
    }

    /// 推荐策略：
    /// - 安装包：默认全选
    /// - 重复文件 & 相似图片：仅勾选非原件副本 (`autoSelected && !isKeptOriginal`)
    /// - 下载项：仅勾选安全可删副本 (`autoSelected && safety == .safe`)
    /// - 大型和旧文件：默认 0 勾选（防误删个人大文件）
    func applyRecommendedSelection() {
        state.strategy = .smart
        state.selection.removeAll()
        // User files, installers and perceptual matches require explicit review.
        recomputeSelectionSummaries()
    }
}

// ============================================================
//  MARK: - IdleDeclutterFeatureCard (首屏能力预览 Bento 微卡片)
// ============================================================

struct IdleDeclutterFeatureCard: View {
    let kind: SmartDeclutterSectionKind
    let tag: String
    @State var hover = false

    var body: some View {
        VStack(spacing: 6) {
            CleanCategoryVisuals.glass3DIcon(for: kind, size: 32)
                .scaleEffect(hover ? 1.08 : 1.0)

            Text(kind.title)
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
        .frame(width: 112, height: 96)
        .glassBentoCard(cornerRadius: 12, isHighlighted: false, isHovered: hover, padding: 6)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .help(kind.subtitle)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: hover)
    }
}

// ============================================================
//  MARK: - SmartNextGenDeclutterRow (高定微组件 64pt 静音级整理行 / 52pt 紧凑行)
// ============================================================

struct SmartNextGenDeclutterRow: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var config = AppConfigStore.shared
    let section: SmartDeclutterSectionData
    let checkboxState: CheckboxState
    let selectedCount: Int
    let selectedSize: Int64
    let isCompact: Bool
    let isSelected: Bool
    let onToggleSection: () -> Void
    let onSelectSection: () -> Void

    @State var hover = false

    var shadowColor: Color {
        let opacity: Double = Theme.isDark ? 0.18 : (hover ? 0.07 : 0.03)
        return Color.black.opacity(opacity)
    }

    var badgeText: String {
        if selectedCount == 0 || selectedCount == section.totalCount {
            return "\(section.totalCount) \(L10n.localized(.unitItems))"
        }
        return "\(selectedCount)/\(section.totalCount) \(L10n.localized(.unitItems))"
    }

    var sizeParts: (value: String, unit: String) {
        Fmt.sizeParts(selectedSize > 0 ? selectedSize : section.totalSize)
    }

    @ViewBuilder
    var mainContent: some View {
        if isCompact {
            compactContent
        } else {
            wideContent
        }
    }

    var body: some View {
        mainContent
            .background(rowBackground(isDark: Theme.isDark))
            .overlay(rowOverlay(isDark: Theme.isDark))
            .shadow(
                color: shadowColor,
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

                        MetallicBadge(
                            text: badgeText,
                            color: selectedCount > 0 ? Theme.accent : Theme.tert
                        )
                    }
                }
            }

            Spacer(minLength: 12)

            // 锚点 2: 右锚点 (双字阶纯净体积排版)
            let parts = sizeParts
            let hasSize = (selectedSize > 0 || section.totalSize > 0)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(parts.value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(hasSize ? Theme.text : Theme.tert)
                    .monospacedDigit()

                Text(parts.unit)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(hasSize ? Theme.sub : Theme.tert)
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
                    Text("\(selectedCount)/\(section.totalCount)")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(selectedCount > 0 ? Theme.accent : Theme.tert)
                        .monospacedDigit()

                    Text("·")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.tert)

                    let displaySize = selectedSize > 0 ? selectedSize : section.totalSize
                    Text(Fmt.size(displaySize))
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(displaySize > 0 ? Theme.sub : Theme.tert)
                        .monospacedDigit()
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
//  MARK: - 整理杂乱子项行 (`SmartDeclutterLeafRow`)
// ============================================================

struct SmartDeclutterLeafRow: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var config = AppConfigStore.shared
    let leaf: Node

    @State var hover = false

    var isSelected: Bool {
        state.selection.contains(leaf.id)
    }

    var body: some View {
        let isOriginal = SmartDeclutterView.isKeptOriginal(leaf)
        let isSelectable = state.isSelectableForClean(leaf) && !isOriginal
        return HStack(spacing: 10) {
            FluidCheckbox(state: !isSelectable ? .locked : (isSelected ? .all : .none), tint: Theme.accent, a11yLabel: leaf.name) {
                if isSelectable {
                    state.toggle(leaf)
                }
            }

            if let img = leaf.image {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            } else if !leaf.path.isEmpty {
                Image(nsImage: FileIconCache.shared.icon(for: leaf.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            } else {
                Image(systemName: "doc.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 18, height: 18)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(leaf.name)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if SmartDeclutterView.isKeptOriginal(leaf) {
                        MetallicBadge(text: L10n.localized(.labelKeepOriginalRecommended), color: Theme.green)
                            .layoutPriority(1)
                    }
                }

                if !leaf.path.isEmpty {
                    Text(abbreviateHomePath(leaf.path))
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.tert)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 8)

            if hover, let url = leaf.url {
                HStack(spacing: 6) {
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
                }
            }

            Text(Fmt.size(leaf.totalSize))
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(isSelected ? Theme.text : Theme.sub)
                .monospacedDigit()
                .frame(minWidth: 68, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(hover ? Theme.hover : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if !leaf.locked {
                state.toggle(leaf)
            }
        }
        .onHover { hover = $0 }
    }

    func abbreviateHomePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
