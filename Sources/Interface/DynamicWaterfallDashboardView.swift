import SwiftUI
import AppKit

// ============================================================
//  DynamicWaterfallDashboardView
//
//  【可动态组合配置和显示的瀑布流卡片面板】核心组件
//
//  场景：
//    macOS 顶部菜单栏点击后下拉弹出的状态面板（宽度固定，高度自适应，支持平滑滚动）
//    以及独立配置面板中的所见即所得动态拼装画布。
//
//  核心能力：
//    1. 原生 SwiftUI Layout 协议驱动的多跨度自适应瀑布流引擎 (WaterfallFlowLayout)：
//       - 1/2 双列并排小卡片 (如 CPU、GPU、内存、磁盘、网络、传感器，真实测量子视图不等高尺寸，按最矮列优先紧凑贴合，彻底消除高低差空白)
//       - 1/3 三列九宫格小卡片 (高密度监控矩阵，按三列最矮列优先瀑布排布)
//       - 1/1 通栏单列大卡片 (如系统健康横幅、电池外设、天气预报、网络IP诊断，横跨 100% 宽度)
//       - 1/1 底部数据列表与工具栏 (如 Top 进程占用排行、快捷工具坞，横跨 100% 宽度)
//    2. 单层扁平视图树 (Single Flat ForEach)：
//       - 所有卡片共享稳定的视图标识 (View Identity)，在跨列重排或切换 [1/1] [1/2] [1/3] 跨度时不会销毁重建视图，确保拖拽手势与动画丝滑连贯。
//    3. 自适应高度计算器 (WaterfallLayoutEngine)：
//       - 精确测算瀑布流理想总高度，驱动下拉弹窗自适应伸缩并受最大高度约束。
// ============================================================

/// 瀑布流卡片跨度 LayoutValueKey，使单层 ForEach 内的子视图携带自身 Span 参与原生瀑布流排版
struct WaterfallSpanLayoutKey: LayoutValueKey {
    static let defaultValue: DashboardGridSpan = .full
}

extension View {
    /// 为瀑布流子卡片标记跨度 (1/1 通栏、1/2 双列、1/3 三列)
    func waterfallSpan(_ span: DashboardGridSpan) -> some View {
        layoutValue(key: WaterfallSpanLayoutKey.self, value: span)
    }
}

/// 原生多跨度瀑布流布局引擎 (SwiftUI Layout Protocol)
/// 实时测量每个卡片子视图在对应列宽下的真实高度，并按「最矮列优先 (Shortest-Column First)」紧密贴合排布
struct WaterfallFlowLayout: Layout {
    var spacing: CGFloat = 8

    /// 安全解析容器可用宽度（防御 nil / .infinity / NaN 探测提案）
    private func resolvedWidth(from proposalWidth: CGFloat?, fallback: CGFloat = 680) -> CGFloat {
        guard let w = proposalWidth, w.isFinite, w > 0 else {
            return fallback
        }
        return max(120, min(w, 4000))
    }

    private func computeLayout(
        totalWidth: CGFloat,
        subviews: Subviews
    ) -> (frames: [CGRect], totalHeight: CGFloat) {
        guard !subviews.isEmpty else { return ([], 0) }
        let safeWidth = resolvedWidth(from: totalWidth)
        var frames = Array(repeating: CGRect.zero, count: subviews.count)

        var currentY: CGFloat = 0
        var hasPlacedGroup = false

        var i = 0
        while i < subviews.count {
            let span = subviews[i][WaterfallSpanLayoutKey.self]
            if hasPlacedGroup {
                currentY += spacing
            }
            hasPlacedGroup = true

            switch span {
            case .full:
                let size = subviews[i].sizeThatFits(ProposedViewSize(width: safeWidth, height: nil))
                let h = (size.height.isFinite && size.height > 0) ? size.height : 64
                frames[i] = CGRect(x: 0, y: currentY, width: safeWidth, height: h)
                currentY += h
                i += 1

            case .half:
                // 连续的 1/2 跨度小卡片组成双列瀑布流，自动按真实测量高度填入当前较矮的一列
                let colWidth = max(40, (safeWidth - spacing) / 2.0)
                var colHeights: [CGFloat] = [currentY, currentY]
                var colCounts: [Int] = [0, 0]

                while i < subviews.count && subviews[i][WaterfallSpanLayoutKey.self] == .half {
                    let colIdx = (colHeights[0] <= colHeights[1]) ? 0 : 1
                    if colCounts[colIdx] > 0 {
                        colHeights[colIdx] += spacing
                    }
                    let size = subviews[i].sizeThatFits(ProposedViewSize(width: colWidth, height: nil))
                    let h = (size.height.isFinite && size.height > 0) ? size.height : 84
                    let x = CGFloat(colIdx) * (colWidth + spacing)
                    let y = colHeights[colIdx]
                    frames[i] = CGRect(x: x, y: y, width: colWidth, height: h)
                    colHeights[colIdx] += h
                    colCounts[colIdx] += 1
                    i += 1
                }
                currentY = max(colHeights[0], colHeights[1])

            case .third:
                // 连续的 1/3 跨度小卡片组成三列九宫格瀑布流，自动按真实测量高度填入最矮列
                let colWidth = max(30, (safeWidth - spacing * 2.0) / 3.0)
                var colHeights: [CGFloat] = [currentY, currentY, currentY]
                var colCounts: [Int] = [0, 0, 0]

                while i < subviews.count && subviews[i][WaterfallSpanLayoutKey.self] == .third {
                    var minCol = 0
                    for c in 1..<3 {
                        if colHeights[c] < colHeights[minCol] {
                            minCol = c
                        }
                    }
                    if colCounts[minCol] > 0 {
                        colHeights[minCol] += spacing
                    }
                    let size = subviews[i].sizeThatFits(ProposedViewSize(width: colWidth, height: nil))
                    let h = (size.height.isFinite && size.height > 0) ? size.height : 84
                    let x = CGFloat(minCol) * (colWidth + spacing)
                    let y = colHeights[minCol]
                    frames[i] = CGRect(x: x, y: y, width: colWidth, height: h)
                    colHeights[minCol] += h
                    colCounts[minCol] += 1
                    i += 1
                }
                currentY = colHeights.max() ?? currentY
            }
        }

        return (frames, max(0, currentY))
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = resolvedWidth(from: proposal.width)
        let (_, totalHeight) = computeLayout(totalWidth: width, subviews: subviews)
        return CGSize(width: width, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let width = resolvedWidth(from: bounds.width, fallback: resolvedWidth(from: proposal.width))
        let (frames, _) = computeLayout(totalWidth: width, subviews: subviews)
        for (idx, subview) in subviews.enumerated() where idx < frames.count {
            let rect = frames[idx]
            subview.place(
                at: CGPoint(x: bounds.minX + rect.minX, y: bounds.minY + rect.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: rect.width, height: rect.height)
            )
        }
    }
}

/// 瀑布流排版分块模型（用于弹窗高度快速预估）
enum WaterfallLayoutBlock: Identifiable {
    case full(DropdownSectionKind)
    case halfPair([DropdownSectionKind])
    case thirdGrid([DropdownSectionKind])

    var id: String {
        switch self {
        case .full(let sec):
            return "full_\(sec.id)"
        case .halfPair(let list):
            return "half_" + list.map(\.id).joined(separator: "_")
        case .thirdGrid(let list):
            return "third_" + list.map(\.id).joined(separator: "_")
        }
    }
}

/// 瀑布流分块与弹窗自适应高度测算引擎
enum WaterfallLayoutEngine {

    /// 将有序卡片序列按照各自的 Span 切分为瀑布流布局块
    static func buildBlocks(
        from sections: [DropdownSectionKind],
        spanProvider: (DropdownSectionKind) -> DashboardGridSpan
    ) -> [WaterfallLayoutBlock] {
        var blocks: [WaterfallLayoutBlock] = []
        var pendingHalf: [DropdownSectionKind] = []
        var pendingThird: [DropdownSectionKind] = []

        func flushHalf() {
            if !pendingHalf.isEmpty {
                blocks.append(.halfPair(pendingHalf))
                pendingHalf.removeAll()
            }
        }

        func flushThird() {
            if !pendingThird.isEmpty {
                blocks.append(.thirdGrid(pendingThird))
                pendingThird.removeAll()
            }
        }

        for section in sections {
            let span = spanProvider(section)
            switch span {
            case .full:
                flushHalf()
                flushThird()
                blocks.append(.full(section))
            case .half:
                flushThird()
                pendingHalf.append(section)
            case .third:
                flushHalf()
                pendingThird.append(section)
            }
        }

        flushHalf()
        flushThird()
        return blocks
    }

    /// 估算单张卡片在给定跨度与高度档位下的基准渲染高度 (pt)
    static func estimatedCardHeight(
        for section: DropdownSectionKind,
        span: DashboardGridSpan,
        heightMode: DashboardCardHeightMode = .standard
    ) -> CGFloat {
        switch heightMode {
        case .compact:
            switch section {
            case .dateTimeCard: return 46
            case .healthBanner: return 48
            case .cpuCard, .gpuCard, .ramCard, .diskCard, .networkCard, .sensorCard:
                return 74
            case .batteryCard: return 68
            case .weatherQuickCard: return 46
            case .networkDetailCard: return 50
            case .topProcesses: return 130
            case .footerToolbar: return 40
            case .hardwareGrid: return 160
            }
        case .standard:
            switch section {
            case .dateTimeCard: return 48
            case .healthBanner: return 58
            case .cpuCard, .gpuCard, .ramCard, .diskCard, .networkCard, .sensorCard:
                return 96 // 标准档位统一高度！同行并排完美等高对齐！
            case .batteryCard: return 84
            case .weatherQuickCard: return 48
            case .networkDetailCard: return 54
            case .topProcesses: return 170
            case .footerToolbar: return 44
            case .hardwareGrid: return 210
            }
        case .expanded:
            switch section {
            case .dateTimeCard: return 56
            case .healthBanner: return 70
            case .cpuCard: return 132
            case .gpuCard: return 112
            case .ramCard: return 130
            case .diskCard: return 110
            case .networkCard: return 120
            case .sensorCard: return 110
            case .batteryCard: return 106
            case .weatherQuickCard: return 56
            case .networkDetailCard: return 62
            case .topProcesses: return 205
            case .footerToolbar: return 48
            case .hardwareGrid: return 260
            }
        }
    }

    /// 根据当前启用卡片、跨度与高度档位动态测算下拉面板理想总高度
    @MainActor static func estimateTotalHeight(
        sections: [DropdownSectionKind],
        spanProvider: (DropdownSectionKind) -> DashboardGridSpan,
        heightModeProvider: ((DropdownSectionKind) -> DashboardCardHeightMode)? = nil,
        spacing: CGFloat = 8,
        chromeHeight: CGFloat = 60,
        minHeight: CGFloat = 200,
        maxHeight: CGFloat = 960
    ) -> CGFloat {
        let getHeightMode = heightModeProvider ?? { MenuBarConfigStore.shared.heightMode(for: $0) }
        let blocks = buildBlocks(from: sections, spanProvider: spanProvider)
        var totalContentHeight: CGFloat = 0

        for block in blocks {
            switch block {
            case .full(let sec):
                totalContentHeight += estimatedCardHeight(for: sec, span: .full, heightMode: getHeightMode(sec))
            case .halfPair(let items):
                var col0: CGFloat = 0
                var col1: CGFloat = 0
                for item in items {
                    let h = estimatedCardHeight(for: item, span: .half, heightMode: getHeightMode(item))
                    if col0 <= col1 {
                        col0 += (col0 > 0 ? spacing : 0) + h
                    } else {
                        col1 += (col1 > 0 ? spacing : 0) + h
                    }
                }
                totalContentHeight += max(col0, col1)
            case .thirdGrid(let items):
                var cols: [CGFloat] = [0, 0, 0]
                for item in items {
                    let h = estimatedCardHeight(for: item, span: .third, heightMode: getHeightMode(item))
                    let minIdx = cols.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
                    cols[minIdx] += (cols[minIdx] > 0 ? spacing : 0) + h
                }
                totalContentHeight += (cols.max() ?? 0)
            }
        }

        if blocks.count > 1 {
            totalContentHeight += CGFloat(blocks.count - 1) * spacing
        }

        let ideal = chromeHeight + totalContentHeight
        return min(max(ideal, minHeight), maxHeight)
    }
}

// ============================================================
//  DynamicWaterfallFlowView —— 通用多跨度瀑布流渲染容器
//  同时服务于：
//    1. 下拉弹窗状态面板 (MenuBarPopoverView)
//    2. 配置面板实时瀑布流拼装画布 (MenuBarConfiguratorView)
// ============================================================

struct DynamicWaterfallFlowView<CardView: View>: View {
    let sections: [DropdownSectionKind]
    let spacing: CGFloat
    let spanProvider: (DropdownSectionKind) -> DashboardGridSpan
    @ViewBuilder let cardBuilder: (DropdownSectionKind, DashboardGridSpan) -> CardView

    init(
        sections: [DropdownSectionKind],
        spacing: CGFloat = 8,
        spanProvider: @escaping (DropdownSectionKind) -> DashboardGridSpan,
        @ViewBuilder cardBuilder: @escaping (DropdownSectionKind, DashboardGridSpan) -> CardView
    ) {
        self.sections = sections
        self.spacing = spacing
        self.spanProvider = spanProvider
        self.cardBuilder = cardBuilder
    }

    var body: some View {
        WaterfallFlowLayout(spacing: spacing) {
            ForEach(sections) { section in
                let span = spanProvider(section)
                cardBuilder(section, span)
                    .waterfallSpan(span)
            }
        }
    }
}
