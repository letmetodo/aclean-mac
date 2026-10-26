import SwiftUI
import AppKit

extension MenuBarConfiguratorView {
    // ============================================================
    // MARK: - 2. 下拉弹窗模块：【可动态组合配置和显示的瀑布流卡片面板】
    // ============================================================

    var waterfallDashboardConfigSection: some View {
        let validCases = Set(DropdownSectionKind.configurableCases)
        let displayedSections: [DropdownSectionKind] = (showOnlyEnabledInWaterfall
            ? config.activeDropdownSections
            : config.allDropdownSectionsOrder).filter { validCases.contains($0) }

        return VStack(alignment: .leading, spacing: 14) {
            waterfallHeader

            Divider().background(Theme.sep)

            VStack(spacing: 8) {
                ForEach(displayedSections) { section in
                    waterfallConfigurableCard(section: section, span: .full)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.sep, lineWidth: 1))
    }

    var waterfallHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "rectangle.grid.1x2.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.accent)
                Text(L10n.localized(.configuratorWaterfallSectionTitle))
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(Theme.text)
            }

            Spacer()

            waterfallFilterButton
        }
    }

    var waterfallHeightPicker: some View {
        let currentMode = config.allDropdownSectionsOrder.first.map { config.heightMode(for: $0) } ?? .standard

        return Menu {
            ForEach(DashboardCardHeightMode.allCases) { hMode in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        config.setAllHeightModes(to: hMode)
                    }
                } label: {
                    HStack {
                        Label(hMode.label, systemImage: hMode.icon)
                        if currentMode == hMode {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(L10n.localized(.cardHeightAlignAll) + ":")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.sub)

                Image(systemName: currentMode.icon)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.accent)

                Text(currentMode.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.text)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Theme.sub)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 6).fill(Theme.hover))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.sep, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .menuStyle(.borderlessButton)
        .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
    }

    var waterfallFilterButton: some View {
        let validCases = Set(DropdownSectionKind.configurableCases)
        let allCount = config.allDropdownSectionsOrder.filter { validCases.contains($0) }.count
        let activeCount = config.activeDropdownSections.filter { validCases.contains($0) }.count
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                showOnlyEnabledInWaterfall.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: showOnlyEnabledInWaterfall ? "eye.fill" : "square.grid.2x2")
                    .font(.system(size: 10.5))
                Text(showOnlyEnabledInWaterfall ? L10n.localized(.configuratorFilterOnlyActiveFormat, activeCount) : L10n.localized(.configuratorFilterShowAllFormat, allCount))
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(showOnlyEnabledInWaterfall ? Theme.accent : Theme.text)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(showOnlyEnabledInWaterfall ? Theme.accent.opacity(0.15) : Theme.hover)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(showOnlyEnabledInWaterfall ? Theme.accent.opacity(0.4) : Theme.sep, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
    }

    /// 下拉面板卡片配置项：仅支持上下顺序调整（拖拽/按钮）与隐藏/显示开关
    func waterfallConfigurableCard(section: DropdownSectionKind, span: DashboardGridSpan) -> some View {
        let isEnabled = config.isSectionEnabled(section)
        let isDraggingThis = activeSectionDrag?.sectionId == section.id
        let currentSectionOffset = isDraggingThis ? (activeSectionDrag?.offset ?? .zero) : .zero
        let validCases = Set(DropdownSectionKind.configurableCases)
        let allOrder = config.allDropdownSectionsOrder.filter { validCases.contains($0) }
        let globalIndex = allOrder.firstIndex(of: section) ?? 0
        let isTargetDrop = activeSectionDrag != nil && !isDraggingThis && activeSectionDrag?.targetIndex == globalIndex
        let activeOrderBadge = config.activeDropdownSections.filter { validCases.contains($0) }.firstIndex(of: section).map { "#\($0 + 1)" } ?? "-"

        return VStack(alignment: .leading, spacing: 8) {
            // 1. 卡片顶部交互控制栏 (宽大手柄拖动 + 大触点勾选显示/隐藏 + 标题 + 上下移动顺序按钮)
            HStack(spacing: 8) {
                // 1:1 独立拖动手柄胶囊
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(isDraggingThis ? Theme.accent : Theme.sub.opacity(0.85))
                    Text(activeOrderBadge)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(isEnabled ? section.accentColor : Theme.sub.opacity(0.5))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4.5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isDraggingThis ? Theme.accent.opacity(0.24) : Theme.hover)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(isDraggingThis ? Theme.accent : Theme.sep.opacity(0.7), lineWidth: 1)
                )
                .contentShape(Rectangle())
                .onHover { inside in
                    if inside { NSCursor.openHand.push() } else { NSCursor.pop() }
                }
                .highPriorityGesture(cardDragGesture(section: section, span: .full, globalIndex: globalIndex))
                .help(L10n.localized(.configuratorDragToReorderPrompt))

                // 复选框 Checkbox (显示/隐藏)
                Button {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        config.toggleSection(section)
                    }
                } label: {
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isEnabled ? section.accentColor : Theme.sub.opacity(0.45))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                .help(isEnabled ? L10n.localized(.configuratorClickToDisableCard) : L10n.localized(.configuratorClickToEnableCard))

                // 图标与卡片标题 (支持直接上下拖拽手势)
                HStack(spacing: 5) {
                    Image(systemName: section.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isEnabled ? section.accentColor : Theme.sub)

                    Text(cardDisplayTitle(for: section, span: .full))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isEnabled ? Theme.text : Theme.sub)
                        .lineLimit(1)
                }
                .contentShape(Rectangle())
                .highPriorityGesture(cardDragGesture(section: section, span: .full, globalIndex: globalIndex))
                .onHover { inside in
                    if inside { NSCursor.openHand.push() } else { NSCursor.pop() }
                }

                Spacer(minLength: 6)

                // 上下顺序调整按钮
                HStack(spacing: 4) {
                    Button {
                        guard globalIndex > 0 else { return }
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                            config.moveSectionInAllDirection(from: globalIndex, direction: -1)
                        }
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(globalIndex > 0 ? Theme.text.opacity(0.85) : Theme.sub.opacity(0.25))
                            .frame(width: 24, height: 22)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Theme.hover.opacity(globalIndex > 0 ? 0.95 : 0.35)))
                            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.sep.opacity(0.8), lineWidth: 0.8))
                            .contentShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .disabled(globalIndex <= 0)
                    .help(L10n.localized(.configuratorMoveUp))
                    .accessibilityLabel(L10n.localized(.configuratorMoveUp))
                    .onHover { if $0 && globalIndex > 0 { NSCursor.pointingHand.push() } else if !$0 { NSCursor.pop() } }

                    Button {
                        guard globalIndex < allOrder.count - 1 else { return }
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                            config.moveSectionInAllDirection(from: globalIndex, direction: 1)
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundStyle(globalIndex < allOrder.count - 1 ? Theme.text.opacity(0.85) : Theme.sub.opacity(0.25))
                            .frame(width: 24, height: 22)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Theme.hover.opacity(globalIndex < allOrder.count - 1 ? 0.95 : 0.35)))
                            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.sep.opacity(0.8), lineWidth: 0.8))
                            .contentShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    .disabled(globalIndex >= allOrder.count - 1)
                    .help(L10n.localized(.configuratorMoveDown))
                    .accessibilityLabel(L10n.localized(.configuratorMoveDown))
                    .onHover { if $0 && globalIndex < allOrder.count - 1 { NSCursor.pointingHand.push() } else if !$0 { NSCursor.pop() } }
                }
            }

            // 2. 与当前菜单栏下拉面板完全一致的紧凑卡片预览展示
            simulatedWaterfallCardBody(for: section, span: .full, heightMode: .compact)
                .opacity(isEnabled ? 1.0 : 0.42)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isEnabled ? Theme.card : Theme.card.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isDraggingThis ? Theme.accent : (isTargetDrop ? Theme.accent : (isEnabled ? section.accentColor.opacity(0.32) : Theme.sep)),
                    lineWidth: (isDraggingThis || isTargetDrop) ? 2 : 1
                )
        )
        .overlay(alignment: .top) {
            if isTargetDrop {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text(L10n.localized(.configuratorDropTargetPrompt))
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.accent))
                .shadow(color: Theme.accent.opacity(0.5), radius: 6, y: 2)
                .offset(y: -12)
                .zIndex(200)
            }
        }
        .offset(y: currentSectionOffset.height)
        .zIndex(isDraggingThis ? 100 : (isTargetDrop ? 10 : 1))
        .scaleEffect(isDraggingThis ? 1.02 : (isTargetDrop ? 0.99 : 1.0))
        .shadow(
            color: isDraggingThis ? Theme.accent.opacity(0.38) : (isTargetDrop ? Theme.accent.opacity(0.25) : Color.clear),
            radius: isDraggingThis ? 14 : (isTargetDrop ? 6 : 0),
            y: isDraggingThis ? 6 : 0
        )
        .contextMenu {
            Button {
                if globalIndex > 0 {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        config.moveSectionInAllDirection(from: globalIndex, direction: -1)
                    }
                }
            } label: {
                Label(L10n.localized(.configuratorMoveUp), systemImage: "arrow.up")
            }
            .disabled(globalIndex == 0)

            Button {
                if globalIndex < allOrder.count - 1 {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        config.moveSectionInAllDirection(from: globalIndex, direction: 1)
                    }
                }
            } label: {
                Label(L10n.localized(.configuratorMoveDown), systemImage: "arrow.down")
            }
            .disabled(globalIndex >= allOrder.count - 1)

            Divider()

            Button {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                    config.moveSectionInAll(from: globalIndex, to: 0)
                }
            } label: {
                Label(L10n.localized(.configuratorMoveToTop), systemImage: "arrow.up.to.line")
            }
            .disabled(globalIndex == 0)

            Button {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                    config.moveSectionInAll(from: globalIndex, to: allOrder.count - 1)
                }
            } label: {
                Label(L10n.localized(.configuratorMoveToBottom), systemImage: "arrow.down.to.line")
            }
            .disabled(globalIndex >= allOrder.count - 1)

            Divider()

            Button(isEnabled ? L10n.localized(.configuratorDisableSection) : L10n.localized(.configuratorEnableSection)) {
                config.toggleSection(section)
            }
        }
        .preventWindowDrag()
    }

    /// 卡片高优先级垂直拖动手势（仅上下调序，与外层 ScrollView 零冲突）
    func cardDragGesture(section: DropdownSectionKind, span: DashboardGridSpan, globalIndex: Int) -> some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .global)
            .updating($activeSectionDrag) { value, state, _ in
                let validCases = Set(DropdownSectionKind.configurableCases)
                let count = config.allDropdownSectionsOrder.filter { validCases.contains($0) }.count
                let initialIdx = dragInitialSectionIndex ?? (config.allDropdownSectionsOrder.firstIndex(of: section) ?? globalIndex)
                let dy = value.translation.height
                let step = Int(round(dy / AppConfig.UI.menuBarCardDragRowHeight))
                let targetIdx = max(0, min(count - 1, initialIdx + step))
                state = ActiveSectionDrag(
                    sectionId: section.id,
                    offset: CGSize(width: 0, height: dy),
                    targetIndex: targetIdx
                )
            }
            .onChanged { _ in
                if dragInitialSectionIndex == nil {
                    dragInitialSectionIndex = config.allDropdownSectionsOrder.firstIndex(of: section)
                    NSCursor.closedHand.push()
                }
            }
            .onEnded { value in
                NSCursor.pop()
                if let initialIdx = dragInitialSectionIndex {
                    let validCases = Set(DropdownSectionKind.configurableCases)
                    let count = config.allDropdownSectionsOrder.filter { validCases.contains($0) }.count
                    let dy = value.translation.height
                    let step = Int(round(dy / AppConfig.UI.menuBarCardDragRowHeight))
                    let targetIdx = max(0, min(count - 1, initialIdx + step))
                    if targetIdx != initialIdx {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            config.moveSectionInAll(from: initialIdx, to: targetIdx)
                        }
                    }
                }
                dragInitialSectionIndex = nil
            }
    }

    /// 单一简洁的跨度下拉切换菜单 (56x22pt 舒适触控区，彻底告别微缩按钮堆砌)
    func spanDropdownMenu(for section: DropdownSectionKind, currentSpan: DashboardGridSpan) -> some View {
        Menu {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    config.setGridSpan(for: section, span: .half)
                }
            } label: {
                Label(L10n.localized(.spanOptionHalf), systemImage: "rectangle.split.2x1")
            }

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    config.setGridSpan(for: section, span: .full)
                }
            } label: {
                Label(L10n.localized(.spanOptionFull), systemImage: "rectangle")
            }

            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    config.setGridSpan(for: section, span: .third)
                }
            } label: {
                Label(L10n.localized(.spanOptionThird), systemImage: "rectangle.split.3x1")
            }
        } label: {
            HStack(spacing: 3.5) {
                Image(systemName: currentSpan.icon)
                    .font(.system(size: 9.5))
                Text(currentSpan.shortLabel)
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 7.5))
                    .foregroundStyle(Theme.sub)
            }
            .foregroundStyle(Theme.text)
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(RoundedRectangle(cornerRadius: 5).fill(Theme.hover))
            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.sep, lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 5))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help(L10n.localized(.configuratorSwitchSpanTooltipFormat, currentSpan.label))
        .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
    }

    /// 根据卡片排版跨度 (1/1, 1/2, 1/3) 自动精简标题长度，避免在多列排版下文字溢出与截断
    func cardDisplayTitle(for section: DropdownSectionKind, span: DashboardGridSpan) -> String {
        switch span {
        case .third:
            return section.shortTitle
        case .half:
            switch section {
            case .cpuCard: return L10n.localized(.cardTitleCpuLoadShort)
            case .gpuCard: return L10n.localized(.cardTitleGpuUsageShort)
            case .ramCard: return L10n.localized(.cardTitleRamUsageShort)
            case .diskCard: return L10n.localized(.cardTitleDiskStorageShort)
            case .networkCard: return L10n.localized(.cardTitleNetworkThroughputShort)
            case .sensorCard: return L10n.localized(.cardTitleSensorsShort)
            case .batteryCard: return L10n.localized(.cardTitleBatteryShort)
            case .weatherQuickCard: return L10n.localized(.cardTitleWeatherShort)
            case .networkDetailCard: return L10n.localized(.cardTitleNetworkDetailShort)
            case .topProcesses: return L10n.localized(.cardTitleTopProcessesShort)
            case .healthBanner: return L10n.localized(.cardTitleHealthBannerShort)
            case .footerToolbar: return L10n.localized(.cardTitleFooterToolbarShort)
            default: return section.shortTitle
            }
        case .full:
            switch section {
            case .healthBanner:      return L10n.localized(.cardTitleHealthBannerFull)
            case .cpuCard:           return L10n.localized(.cardTitleCpuLoadFull)
            case .gpuCard:           return L10n.localized(.cardTitleGpuUsageFull)
            case .ramCard:           return L10n.localized(.cardTitleRamUsageFull)
            case .diskCard:          return L10n.localized(.cardTitleDiskStorageFull)
            case .networkCard:       return L10n.localized(.cardTitleNetworkThroughputFull)
            case .sensorCard:        return L10n.localized(.cardTitleSensorsFull)
            case .batteryCard:       return L10n.localized(.cardTitleBatteryFull)
            case .weatherQuickCard:  return L10n.localized(.cardTitleWeatherFull)
            case .dateTimeCard:      return L10n.localized(.menuBarCalendarAndAgendaHeader)
            case .networkDetailCard: return L10n.localized(.cardTitleNetworkDetailFull)
            case .topProcesses:      return L10n.localized(.cardTitleTopProcessesFull)
            case .footerToolbar:     return L10n.localized(.cardTitleFooterToolbarFull)
            default:                 return section.title
            }
        }
    }

    // ============================================================
}

// MARK: - 辅助扩展与滚动反弹禁用器

extension MenuBarTokenKind {
    var shortBarTitle: String {
        switch self {
        case .weatherIconTemp:   return L10n.localized(.menuBarCatWeather)
        case .cpuStacked:        return "CPU"
        case .gpuStacked:        return "GPU"
        case .memoryStacked:     return L10n.localized(.menuBarCatMemory)
        case .diskFreeStacked:   return L10n.localized(.menuBarCatDisks)
        case .networkStacked:    return L10n.localized(.menuBarCatNetwork)
        case .sensorTempStacked: return L10n.localized(.menuBarCatSensors)
        case .batteryStacked:    return L10n.localized(.menuBarCatBattery)
        case .clockStacked:      return L10n.localized(.menuBarCatTime)
        }
    }
}

/// 禁用外层 NSScrollView 垂直弹性橡皮筋效果，彻底杜绝上下拖拽卡片时整页被拉动晃动
struct ScrollViewBouncesDisabler: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let scrollView = view.enclosingScrollView {
                scrollView.verticalScrollElasticity = .none
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let scrollView = nsView.enclosingScrollView {
                scrollView.verticalScrollElasticity = .none
            }
        }
    }
}
