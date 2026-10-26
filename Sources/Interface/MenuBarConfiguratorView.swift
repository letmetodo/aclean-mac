import SwiftUI
import AppKit
import UniformTypeIdentifiers

// ============================================================
//  MenuBarConfiguratorView
//
//  核心设计与交互：
//    1. 顶部菜单栏模块 —— 直接在仿真菜单栏上左右拖动排序：
//       - 仿真 macOS 菜单栏上的每个指标胶囊支持直接按住左右平滑拖拽 (Drag & Drop) 调序；
//       - 点击菜单栏上的任意指标胶囊，弹出轻量级预设数据格式选择器（一键切换双行标准/仅百分比/微图等）；
//       - 配备紧凑的「指标快捷启闭池」，彻底去除冗余笨重的大卡片列表。
//    2. 下拉弹窗模块 —— 【可动态组合配置和显示的瀑布流卡片面板】组件：
//       - 基于 DynamicWaterfallFlowView 实现多跨度高低不等卡片的流式瀑布拼装；
//       - 支持 1/2 双列并排小卡片 (CPU、GPU、内存、磁盘、网络、温度风扇，高低不等自动紧凑贴合)；
//       - 支持 1/3 三列九宫格小卡片；
//       - 支持 1/1 通栏大卡片 (系统健康横幅、电池外设、天气预报、网络IP诊断)；
//       - 支持 1/1 底部数据列表与工具栏 (Top 进程占用排行、快捷工具坞)；
//       - 每张卡片均可在瀑布流画布中直接拖拽重排、切换 [1/1] [1/2] [1/3] 跨度、勾选启闭，实时所见即所得。
// ============================================================

struct MenuBarConfiguratorView: View {
    @ObservedObject var config = MenuBarConfigStore.shared

    @Binding var selectedCategory: MonitorModuleCategory
    @State var showResetConfirmation: Bool = false

    struct ActiveTokenDrag: Equatable {
        let tokenId: String
        let offset: CGSize
        let targetIndex: Int?
    }

    struct ActiveSectionDrag: Equatable {
        let sectionId: String
        let offset: CGSize
        let targetIndex: Int?
    }

    // 顶部菜单栏指标网格：拖拽调序与预设数据格式弹窗状态
    @GestureState var activeTokenDrag: ActiveTokenDrag? = nil
    @State var dragInitialTokenIndex: Int? = nil
    @State var activeFormatPopoverToken: MenuBarTokenKind? = nil

    // 下拉弹窗瀑布流卡片：1:1丝滑跟随拖拽与释放插位状态
    @GestureState var activeSectionDrag: ActiveSectionDrag? = nil
    @State var dragInitialSectionIndex: Int? = nil

    // 预览筛选：是否仅预览已启用卡片（模拟真实下拉弹窗）或显示全部卡片
    @State var showOnlyEnabledInWaterfall: Bool = false

    // 瀑布流卡片垂直拖拽基准步长
    let waterfallDragPitchY: CGFloat = 95.0
    let isEmbedded: Bool

    init(selectedCategory: Binding<MonitorModuleCategory>? = nil, isEmbedded: Bool = false) {
        if let binding = selectedCategory {
            self._selectedCategory = binding
        } else {
            self._selectedCategory = Binding.constant(.combined)
        }
        self.isEmbedded = isEmbedded
    }

    var body: some View {
        if isEmbedded {
            VStack(alignment: .leading, spacing: 18) {
                // 第一核心区：顶部菜单栏常驻指标（支持前后调整顺序、拖拽调序、快捷开关与切换格式）
                directDraggableMenuBarSection

                // 第二核心区：可动态组合配置与显示的瀑布流卡片面板
                waterfallDashboardConfigSection
            }
            .preventWindowDrag()
        } else {
            VStack(spacing: 0) {
                // 1. 顶部固定横幅（绝对置顶固定，不随滚动晃动）
                headerBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                    .background(Theme.contentBg)

                Divider().background(Theme.sep)

                // 2. 完整视图主展示区（禁用橡皮筋弹性拖拽）
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        directDraggableMenuBarSection
                        waterfallDashboardConfigSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(ScrollViewBouncesDisabler())
                }
            }
            .preventWindowDrag()
            .background(Theme.contentBg)
            .preferredColorScheme(Theme.isDark ? .dark : .light)
            .environment(\.colorScheme, Theme.isDark ? .dark : .light)
            .alert(isPresented: $showResetConfirmation) {
                Alert(
                    title: Text(L10n.localized(.dialogRestoreDefaultsTitle)),
                    message: Text(L10n.localized(.dialogRestoreDefaultsDesc)),
                    primaryButton: .destructive(Text(L10n.localized(.actionRestoreDefaultsButton))) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            config.resetToDefaults()
                        }
                    },
                    secondaryButton: .cancel(Text(L10n.localized(.actionCancel)))
                )
            }
        }
    }

    // MARK: - 顶部横幅
    var headerBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.95, green: 0.45, blue: 0.55).opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.45, blue: 0.55))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(L10n.localized(.configuratorTitleCombined))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.text)
                    Text(L10n.localized(.statusRunning))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                }
                Text(L10n.localized(.configuratorCombinedSubtitle))
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.sub)
            }

            Spacer()

            Button {
                showResetConfirmation = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text(L10n.localized(.actionRestoreDefaults))
                        .font(.system(size: 11.5, weight: .medium))
                }
                .foregroundStyle(Theme.sub)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Theme.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(Theme.sep, lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
        }
    }

    // ============================================================
    // MARK: - 1. 顶部菜单栏常驻指标 (支持前后顺序移动、拖拽调序、快捷开关与格式选择)
    // ============================================================

    var directDraggableMenuBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题与状态统计
            HStack(alignment: .center) {
                HStack(spacing: 7) {
                    Image(systemName: "menubar.rectangle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    Text(L10n.localized(.configuratorMenuBarTokensSectionTitle))
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundStyle(Theme.text)
                }

                Spacer()

                HStack(spacing: 5) {
                    Text(L10n.localized(.configuratorEnabledBadge))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.sub)
                    Text("\(config.activeMenuBarTokens.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    Text(L10n.localized(.menuBarTokensCountSuffixFormat, MenuBarTokenKind.configurableCases.count))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.sub)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(Theme.hover))
            }

            Divider().background(Theme.sep)

            // Stats 风格可视化预设选择面板 (预设方案: 默认 / 基础 / 推荐 / 扩展)
            statsPresetSelectorCard

            Divider().background(Theme.sep)

            // 全量指标 3 列紧凑网格（支持直接移动前后顺序、拖拽排序、快捷开关与切换展示格式）
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(config.allMenuBarTokensOrder.filter { $0 != .weatherIconTemp }.enumerated()), id: \.element.id) { idx, token in
                    metricCatalogCard(token: token, index: idx)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.sep, lineWidth: 1))
    }

    // MARK: - Stats 可视化预设选择器 (紧凑下拉菜单 + 实时微缩预览条)
    var statsPresetSelectorCard: some View {
        let selectedPreset = config.currentStatsPreset
        let displayTitle = selectedPreset?.title ?? L10n.localized(.statsPresetCustom)

        return HStack(spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "slider.horizontal.below.square.filled.and.square")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text(L10n.localized(.statsSelectPresetTitle))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.text)
            }

            Menu {
                ForEach(StatsMenuBarPreset.allCases) { preset in
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            config.applyStatsPreset(preset)
                        }
                    } label: {
                        HStack {
                            Text(preset.title)
                            if selectedPreset == preset {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(displayTitle)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(Theme.sub)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.accent.opacity(Theme.isDark ? 0.16 : 0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Theme.accent.opacity(0.45), lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }

            statsPresetVisualPreviewStrip(for: selectedPreset ?? .defaultPreset, isSelected: selectedPreset != nil)
        }
    }

    @ViewBuilder
    func statsPresetVisualPreviewStrip(for preset: StatsMenuBarPreset, isSelected: Bool) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 4)
            HStack(spacing: 7) {
                switch preset {
                case .defaultPreset:
                    previewLineChartBox()
                    previewDivider()
                    previewMiniText(top: "RAM", bottom: "78%")
                    previewDivider()
                    previewMiniText(top: "Disk", bottom: "36%")
                    previewDivider()
                    previewSpeedWidget()
                    previewDivider()
                    previewVerticalLabel("SEN")
                    previewDivider()
                    previewBatteryIcon()

                case .basic:
                    previewMiniText(top: "CPU", bottom: "34%")
                    previewDivider()
                    previewMiniText(top: "RAM", bottom: "78%")
                    previewDivider()
                    previewMiniText(top: "Disk", bottom: "36%")
                    previewDivider()
                    previewBatteryIcon()

                case .recommended:
                    HStack(spacing: 2.5) {
                        previewLineChartBox()
                        previewSingleBarBox(ratio: 0.34)
                    }
                    previewDivider()
                    previewSingleBarBox(ratio: 0.78)
                    previewDivider()
                    previewSingleBarBox(ratio: 0.36)
                    previewDivider()
                    previewSpeedWidget()
                    previewDivider()
                    previewSensorStack()
                    previewDivider()
                    previewBatteryIcon()

                case .extended:
                    HStack(spacing: 2.5) {
                        previewMiniText(top: "CPU", bottom: "34%")
                        previewLineChartBox()
                        previewSingleBarBox(ratio: 0.34)
                    }
                    previewDivider()
                    HStack(spacing: 2.5) {
                        previewMiniText(top: "RAM", bottom: "78%")
                        previewLineChartBox()
                        previewSingleBarBox(ratio: 0.78)
                    }
                    previewDivider()
                    HStack(spacing: 2.5) {
                        previewMiniText(top: "Disk", bottom: "36%")
                        previewSingleBarBox(ratio: 0.36)
                    }
                    previewDivider()
                    previewSpeedWidget()
                    previewDivider()
                    previewSensorStack()
                    previewDivider()
                    previewBatteryIcon()
                }
            }
            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Theme.hover.opacity(Theme.isDark ? 0.85 : 0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(isSelected ? Theme.accent : Theme.sep.opacity(0.85), lineWidth: isSelected ? 1.6 : 1.0)
        )
    }

    func previewDivider() -> some View {
        Rectangle()
            .fill(Theme.sub.opacity(0.25))
            .frame(width: 0.8, height: 14)
    }

    func previewMiniText(top: String, bottom: String) -> some View {
        VStack(alignment: .leading, spacing: -1) {
            Text(top)
                .font(.system(size: 6.5, weight: .semibold))
                .foregroundStyle(Theme.sub)
            Text(bottom)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.text)
        }
    }

    func previewLineChartBox() -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(red: 0.14, green: 0.15, blue: 0.17))
            Path { p in
                let pts: [CGFloat] = [0.22, 0.35, 0.28, 0.55, 0.42, 0.68, 0.48]
                let w: CGFloat = 24
                let h: CGFloat = 13
                p.move(to: CGPoint(x: 1, y: h))
                for (i, v) in pts.enumerated() {
                    let x = 1 + w * CGFloat(i) / CGFloat(pts.count - 1)
                    let y = 1 + h * (1.0 - v)
                    p.addLine(to: CGPoint(x: x, y: y))
                }
                p.addLine(to: CGPoint(x: 1 + w, y: h))
                p.closeSubpath()
            }
            .fill(Theme.accent.opacity(0.32))

            Path { p in
                let pts: [CGFloat] = [0.22, 0.35, 0.28, 0.55, 0.42, 0.68, 0.48]
                let w: CGFloat = 24
                let h: CGFloat = 13
                for (i, v) in pts.enumerated() {
                    let x = 1 + w * CGFloat(i) / CGFloat(pts.count - 1)
                    let y = 1 + h * (1.0 - v)
                    if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                    else { p.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Theme.accent, lineWidth: 1.1)
        }
        .frame(width: 26, height: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 2.5)
                .strokeBorder(Theme.text.opacity(0.25), lineWidth: 0.6)
        )
    }

    func previewSingleBarBox(ratio: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 2.2)
                .fill(Color(red: 0.14, green: 0.15, blue: 0.17))
            RoundedRectangle(cornerRadius: 1.3)
                .fill(Theme.accent)
                .frame(width: 5.5, height: max(2, 13 * ratio))
                .padding(.bottom, 1.5)
        }
        .frame(width: 8.5, height: 16)
        .overlay(
            RoundedRectangle(cornerRadius: 2.2)
                .strokeBorder(Theme.text.opacity(0.25), lineWidth: 0.6)
        )
    }

    func previewSpeedWidget() -> some View {
        HStack(spacing: 3) {
            VStack(spacing: 3.5) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 4, height: 4)
                Circle()
                    .fill(Color.red)
                    .frame(width: 4, height: 4)
            }
            VStack(alignment: .trailing, spacing: 0) {
                Text("123.3 KB/s")
                    .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.text)
                Text("890.1 KB/s")
                    .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.text)
            }
        }
    }

    func previewSensorStack() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 3) {
                Text("TMP")
                    .font(.system(size: 6.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.sub)
                Text("45.6°C")
                    .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.text)
            }
            HStack(spacing: 3) {
                Text("FAN")
                    .font(.system(size: 6.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.sub)
                Text("3421R")
                    .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.text)
            }
        }
    }

    func previewVerticalLabel(_ text: String) -> some View {
        VStack(spacing: -1) {
            ForEach(Array(text.prefix(3).enumerated()), id: \.offset) { _, ch in
                Text(String(ch))
                    .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.text)
            }
        }
    }

    func previewBatteryIcon() -> some View {
        HStack(spacing: 1) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2.2)
                    .strokeBorder(Theme.text.opacity(0.82), lineWidth: 1.0)
                    .frame(width: 19, height: 10.5)
                RoundedRectangle(cornerRadius: 1.2)
                    .fill(Theme.text.opacity(0.88))
                    .frame(width: 12.5, height: 6.8)
                    .padding(.leading, 1.8)
            }
            RoundedRectangle(cornerRadius: 0.8)
                .fill(Theme.text.opacity(0.75))
                .frame(width: 1.5, height: 4.5)
        }
    }

    /// 3列全量指标卡片：支持前后顺序移动、拖拽重排、启闭开关与预设格式切换
    func metricCatalogCard(token: MenuBarTokenKind, index: Int) -> some View {
        let enabled = config.isTokenEnabled(token)
        let preset = config.formatPreset(for: token)
        let allOrder = config.allMenuBarTokensOrder
        let activeIndex = config.activeMenuBarTokens.firstIndex(of: token)
        let isDraggingThis = activeTokenDrag?.tokenId == token.id
        let currentOffset = isDraggingThis ? (activeTokenDrag?.offset ?? .zero) : .zero
        let isTargetDrop = activeTokenDrag != nil && !isDraggingThis && activeTokenDrag?.targetIndex == index
        let isPopoverOpen = Binding<Bool>(
            get: { activeFormatPopoverToken == token },
            set: { if !$0 { activeFormatPopoverToken = nil } }
        )

        return HStack(spacing: 6) {
            Image(systemName: token.category.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(token.category.tintColor)
                .frame(width: 15)

            VStack(alignment: .leading, spacing: 1.5) {
                HStack(spacing: 4) {
                    if let activeIdx = activeIndex {
                        Text("#\(activeIdx + 1)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 3.5)
                            .padding(.vertical, 0.5)
                            .background(
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Theme.accent.opacity(0.15))
                            )
                    }

                    Text(token.shortBarTitle)
                        .font(.system(size: 11, weight: enabled ? .semibold : .medium))
                        .foregroundStyle(enabled ? Theme.text : Theme.sub)
                        .lineLimit(1)
                }

                if enabled {
                    Button {
                        activeFormatPopoverToken = (activeFormatPopoverToken == token) ? nil : token
                    } label: {
                        HStack(spacing: 2) {
                            Text(preset.localizedName)
                                .font(.system(size: 9.5, weight: .medium))
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 7, weight: .bold))
                        }
                        .foregroundStyle(Theme.accent)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: isPopoverOpen, arrowEdge: .bottom) {
                        tokenFormatPickerPopover(for: token)
                    }
                } else {
                    Text(token.previewBottomLine.isEmpty ? token.previewTopLine : "\(token.previewTopLine) / \(token.previewBottomLine)")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundStyle(Theme.sub.opacity(0.6))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 2)

            // 启闭开关（已移除左右方向键，支持直接拖拽卡片调整顺序）
            Button {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                    config.toggleToken(token)
                }
            } label: {
                Image(systemName: enabled ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 13.5, weight: enabled ? .bold : .medium))
                    .foregroundStyle(enabled ? Theme.accent : Theme.sub.opacity(0.7))
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(enabled ? L10n.localized(.configuratorTooltipHideFormat, token.title) : L10n.localized(.configuratorTooltipAddFormat))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(enabled ? Theme.accent.opacity(Theme.isDark ? 0.12 : 0.08) : Theme.hover.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .strokeBorder(
                    isDraggingThis ? Theme.accent : (isTargetDrop ? Theme.accent : (enabled ? Theme.accent.opacity(0.4) : Theme.sep)),
                    lineWidth: (isDraggingThis || isTargetDrop) ? 2 : 1
                )
        )
        .offset(currentOffset)
        .zIndex(isDraggingThis ? 50 : (isTargetDrop ? 10 : 1))
        .scaleEffect(isDraggingThis ? 1.03 : (isTargetDrop ? 0.98 : 1.0))
        .shadow(
            color: isDraggingThis ? Theme.accent.opacity(0.35) : Color.clear,
            radius: isDraggingThis ? 8 : 0,
            y: isDraggingThis ? 4 : 0
        )
        .contentShape(RoundedRectangle(cornerRadius: 7))
        .onTapGesture {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                config.toggleToken(token)
            }
        }
        .gesture(tokenGridDragGesture(token: token, globalIndex: index))
        .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
        .contextMenu {
            Button {
                if index > 0 {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        config.moveTokenInAllDirection(from: index, direction: -1)
                    }
                }
            } label: {
                Label(L10n.localized(.configuratorMoveUp), systemImage: "arrow.left")
            }
            .disabled(index <= 0)

            Button {
                if index < allOrder.count - 1 {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        config.moveTokenInAllDirection(from: index, direction: 1)
                    }
                }
            } label: {
                Label(L10n.localized(.configuratorMoveDown), systemImage: "arrow.right")
            }
            .disabled(index >= allOrder.count - 1)

            Divider()

            Menu(L10n.localized(.configuratorSelectFormatHeader)) {
                ForEach(token.availablePresets) { p in
                    Button {
                        config.setFormatPreset(for: token, presetId: p.id)
                    } label: {
                        HStack {
                            Text(p.localizedName)
                            if preset.id == p.id { Text("✓") }
                        }
                    }
                }
            }

            Divider()

            Button {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                    config.toggleToken(token)
                }
            } label: {
                Label(
                    enabled ? L10n.localized(.configuratorRemoveTokenBtn) : L10n.localized(.configuratorAddTokenBtn),
                    systemImage: enabled ? "eye.slash" : "plus.circle"
                )
            }
        }
        .preventWindowDrag()
    }

    /// 3列网格指标卡片拖拽手势（支持左右与上下跨行拖拽调序）
    func tokenGridDragGesture(token: MenuBarTokenKind, globalIndex: Int) -> some Gesture {
        DragGesture(minimumDistance: 3, coordinateSpace: .global)
            .updating($activeTokenDrag) { value, state, _ in
                let count = config.allMenuBarTokensOrder.count
                let initialIdx = dragInitialTokenIndex ?? (config.allMenuBarTokensOrder.firstIndex(of: token) ?? globalIndex)
                let colStep = Int(round(value.translation.width / 185.0))
                let rowStep = Int(round(value.translation.height / 46.0))
                let step = rowStep * 3 + colStep
                let targetIdx = max(0, min(count - 1, initialIdx + step))
                state = ActiveTokenDrag(
                    tokenId: token.id,
                    offset: value.translation,
                    targetIndex: targetIdx
                )
            }
            .onChanged { _ in
                if dragInitialTokenIndex == nil {
                    dragInitialTokenIndex = config.allMenuBarTokensOrder.firstIndex(of: token)
                    NSCursor.closedHand.push()
                }
            }
            .onEnded { value in
                NSCursor.pop()
                if let initialIdx = dragInitialTokenIndex {
                    let count = config.allMenuBarTokensOrder.count
                    let colStep = Int(round(value.translation.width / 185.0))
                    let rowStep = Int(round(value.translation.height / 46.0))
                    let step = rowStep * 3 + colStep
                    let targetIdx = max(0, min(count - 1, initialIdx + step))
                    if targetIdx != initialIdx {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                            config.moveTokenInAll(from: initialIdx, to: targetIdx)
                        }
                    }
                }
                dragInitialTokenIndex = nil
            }
    }

    /// 点击指标展示格式弹出的双列紧凑可视化网格选择器（大幅缩短纵向高度，直观预览样式）
    func tokenFormatPickerPopover(for token: MenuBarTokenKind) -> some View {
        let currentPreset = config.formatPreset(for: token)
        let columns = [
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6)
        ]

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: token.category.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(token.category.tintColor)
                Text(token.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text(L10n.localized(.configuratorSelectFormatHeader))
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.sub)
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(token.availablePresets) { preset in
                    let isSelected = currentPreset.id == preset.id
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            config.setFormatPreset(for: token, presetId: preset.id)
                        }
                        activeFormatPopoverToken = nil
                    } label: {
                        HStack(spacing: 6) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 3.5) {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(isSelected ? Theme.accent : Theme.sub.opacity(0.45))
                                    Text(preset.localizedName)
                                        .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                                        .foregroundStyle(isSelected ? Theme.accent : Theme.text)
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 2)
                            widgetStylePreviewBadge(for: preset, isSelected: isSelected)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isSelected ? Theme.accent.opacity(Theme.isDark ? 0.18 : 0.12) : Theme.hover.opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(isSelected ? Theme.accent : Theme.sep.opacity(0.7), lineWidth: isSelected ? 1.2 : 0.8)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
                }
            }

            if config.activeMenuBarTokens.count > 1 {
                Divider().background(Theme.sep)
                Button {
                    withAnimation {
                        config.removeToken(token)
                        activeFormatPopoverToken = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 10))
                        Text(L10n.localized(.configuratorRemoveTokenBtn))
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .foregroundStyle(Color.red.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 3)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .onHover { if $0 { NSCursor.pointingHand.push() } else { NSCursor.pop() } }
            }
        }
        .padding(10)
        .frame(width: 316)
        .background(Theme.card)
        .preferredColorScheme(Theme.isDark ? .dark : .light)
    }

    @ViewBuilder
    func widgetStylePreviewBadge(for preset: TokenDisplayFormatPreset, isSelected: Bool) -> some View {
        HStack(spacing: 3) {
            switch preset.id {
            case "cpu_line_chart", "gpu_line_chart", "mem_line_chart":
                previewLineChartBox()
            case "cpu_bar_chart", "gpu_bar_chart", "mem_bar_chart", "disk_bar_chart":
                previewSingleBarBox(ratio: 0.52)
            case "cpu_pie_chart", "mem_pie_chart":
                ZStack {
                    Circle()
                        .stroke(Theme.sub.opacity(0.25), lineWidth: 2.2)
                        .frame(width: 13, height: 13)
                    Circle()
                        .trim(from: 0, to: 0.58)
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 13, height: 13)
                }
            case "cpu_with_temp":
                previewMiniText(top: preset.topLine, bottom: preset.bottomLine)
                previewSingleBarBox(ratio: 0.38)
            case "cpu_sparkline":
                previewMiniText(top: "CPU", bottom: "18%")
                previewLineChartBox()
            case "sensor_label_vertical":
                previewVerticalLabel("SEN")
            case "bat_icon_only":
                previewBatteryIcon()
            case "net_dual", "net_up_down":
                previewSpeedWidget()
            default:
                if preset.bottomLine.isEmpty {
                    Text(preset.topLine)
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(isSelected ? Theme.accent : Theme.text)
                } else {
                    previewMiniText(top: preset.topLine, bottom: preset.bottomLine)
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2.5)
        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.hover))
    }
}
