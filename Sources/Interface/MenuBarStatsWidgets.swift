import SwiftUI
import AppKit

// MARK: - 9. Stats 风格主题感知微组件体系 (CleanMate Theme Engine)

@MainActor
enum StatsTheme {
    /// 弹窗毛玻璃上的主题背景着色层
    static var popupTint: Color {
        Theme.windowBg.opacity(Theme.isDark ? 0.86 : 0.90)
    }

    /// 第一主色（System / Upload / Active P-Core）：响应 MenuBarColorMode 与当前主题
    static var firstColor: Color {
        switch MenuBarConfigStore.shared.menuBarColorMode {
        case .monochrome:
            return Theme.text
        case .themeAccent:
            return Theme.accent
        case .utilization, .classicMulti:
            return Color(red: 0.92, green: 0.32, blue: 0.28) // Stats System Red
        }
    }

    /// 第二主色（User / Download / Wired / E-Core）：响应 MenuBarColorMode 与当前主题
    static var secondColor: Color {
        switch MenuBarConfigStore.shared.menuBarColorMode {
        case .monochrome:
            return Theme.sub
        case .themeAccent:
            return Theme.accent2
        case .utilization, .classicMulti:
            return Color(red: 0.22, green: 0.56, blue: 0.96) // Stats User Blue
        }
    }

    /// 第三辅助色（Compressed / Purgeable / Warning）
    static var thirdColor: Color {
        switch MenuBarConfigStore.shared.menuBarColorMode {
        case .monochrome:
            return Theme.sub.opacity(0.75)
        case .themeAccent:
            return Color(red: 0.96, green: 0.60, blue: 0.22)
        case .utilization, .classicMulti:
            return Color(red: 0.96, green: 0.60, blue: 0.22)
        }
    }

    /// 第四辅助色（Healthy / Battery / Normal）
    static var fourthColor: Color {
        switch MenuBarConfigStore.shared.menuBarColorMode {
        case .monochrome:
            return Theme.text.opacity(0.85)
        default:
            return Color(red: 0.24, green: 0.78, blue: 0.48)
        }
    }

    /// 圆环与进度条底轨色（自适应深浅色模式）
    static var idleTrackColor: Color {
        Theme.isDark ? Color.white.opacity(0.11) : Color.black.opacity(0.08)
    }

    /// 胶囊/柱状槽底轨色
    static var trackBg: Color {
        Theme.isDark ? Color.white.opacity(0.09) : Color.black.opacity(0.07)
    }

    /// 内部微卡片/数据块容器底色（替代硬编码 Color.white.opacity）
    static var boxBg: Color {
        Theme.isDark ? Color.white.opacity(0.045) : Color.black.opacity(0.038)
    }

    // 兼容别名 (Primary / Secondary / Tertiary / Quaternary / Track)
    static var primaryColor: Color { firstColor }
    static var secondaryColor: Color { secondColor }
    static var tertiaryColor: Color { thirdColor }
    static var quaternaryColor: Color { fourthColor }
    static var trackColor: Color { idleTrackColor }

    /// 负载梯度着色（0.0 ~ 1.0）
    static func utilizationColor(_ ratio: Double) -> Color {
        let clamped = max(0.0, min(1.0, ratio))
        switch MenuBarConfigStore.shared.menuBarColorMode {
        case .monochrome:
            return Theme.text
        case .themeAccent:
            if clamped >= 0.85 { return Color(red: 0.95, green: 0.30, blue: 0.28) }
            if clamped >= 0.65 { return Color(red: 0.96, green: 0.60, blue: 0.20) }
            return Theme.accent
        case .utilization, .classicMulti:
            if clamped >= 0.85 { return Color(red: 0.95, green: 0.30, blue: 0.28) }
            if clamped >= 0.65 { return Color(red: 0.96, green: 0.60, blue: 0.20) }
            if clamped >= 0.45 { return Color(red: 0.95, green: 0.80, blue: 0.22) }
            return Color(red: 0.24, green: 0.78, blue: 0.48)
        }
    }
}

/// 多段环形图组件
struct StatsPieChartView: View {
    struct Segment {
        var value: Double
        var color: Color
    }

    struct TrimSlice: Identifiable {
        let id: Int
        let start: CGFloat
        let end: CGFloat
        let color: Color
    }

    var segments: [Segment]
    var nonUsageColor: Color? = nil
    var centerTitle: String
    var centerSubtitle: String? = nil
    var lineWidth: CGFloat = 7.0
    var fixedFrameSize: CGFloat? = nil

    init(
        segments: [Segment],
        nonUsageColor: Color? = nil,
        centerTitle: String,
        centerSubtitle: String? = nil,
        lineWidth: CGFloat = 7.0
    ) {
        self.segments = segments
        self.nonUsageColor = nonUsageColor
        self.centerTitle = centerTitle
        self.centerSubtitle = centerSubtitle
        self.lineWidth = lineWidth
        self.fixedFrameSize = nil
    }

    init(
        segments: [(Double, Color)],
        centerText: String,
        lineWidth: CGFloat = 6.0,
        size: CGFloat = 60
    ) {
        self.segments = segments.map { Segment(value: $0.0, color: $0.1) }
        self.nonUsageColor = nil
        self.centerTitle = centerText
        self.centerSubtitle = nil
        self.lineWidth = lineWidth
        self.fixedFrameSize = size
    }

    var slices: [TrimSlice] {
        var result: [TrimSlice] = []
        var cursor: CGFloat = 0.0
        for (idx, seg) in segments.enumerated() {
            let clamped = CGFloat(max(0.0, min(1.0, seg.value)))
            guard clamped > 0.002, cursor < 1.0 else { continue }
            let next = min(1.0, cursor + clamped)
            result.append(TrimSlice(id: idx, start: cursor, end: next, color: seg.color))
            cursor = next
        }
        return result
    }

    var body: some View {
        let ring = ZStack {
            Circle()
                .stroke(nonUsageColor ?? StatsTheme.idleTrackColor, lineWidth: lineWidth)

            ForEach(slices) { slice in
                Circle()
                    .trim(from: slice.start, to: slice.end)
                    .rotation(.degrees(-90))
                    .stroke(slice.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            }

            VStack(spacing: 0) {
                Text(centerTitle)
                    .font(.system(size: centerSubtitle == nil ? 10.5 : 13, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                if let sub = centerSubtitle {
                    Text(sub)
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(Theme.sub)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, lineWidth + 2)
        }

        if let s = fixedFrameSize {
            ring.frame(width: s, height: s)
        } else {
            ring
        }
    }
}

/// 半圆开口仪表盘组件
struct StatsGaugeChartView: View {
    var value: Double
    var color: Color
    var centerTitle: String
    var centerSubtitle: String? = nil
    var lineWidth: CGFloat = 7.0
    var fixedSize: CGSize? = nil

    init(
        value: Double,
        color: Color,
        centerTitle: String,
        centerSubtitle: String? = nil,
        lineWidth: CGFloat = 7.0
    ) {
        self.value = value
        self.color = color
        self.centerTitle = centerTitle
        self.centerSubtitle = centerSubtitle
        self.lineWidth = lineWidth
        self.fixedSize = nil
    }

    init(
        value: Double,
        title: String,
        size: CGSize
    ) {
        self.value = value
        self.color = StatsTheme.utilizationColor(value)
        self.centerTitle = title
        self.centerSubtitle = nil
        self.lineWidth = min(size.width, size.height) >= 56 ? 6.0 : 4.5
        self.fixedSize = size
    }

    var body: some View {
        let clamped = max(0.0, min(1.0, value))
        let gauge = ZStack {
            Circle()
                .trim(from: 0.0, to: 0.72)
                .rotation(.degrees(140))
                .stroke(StatsTheme.idleTrackColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            Circle()
                .trim(from: 0.0, to: 0.72 * CGFloat(clamped))
                .rotation(.degrees(140))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            VStack(spacing: 0) {
                Text(centerTitle)
                    .font(.system(size: centerSubtitle == nil ? 9.5 : 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                if let sub = centerSubtitle {
                    Text(sub)
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(Theme.sub)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, lineWidth + 2)
        }

        if let s = fixedSize {
            gauge.frame(width: s.width, height: s.height)
        } else {
            gauge
        }
    }
}

/// 带底槽每核负载柱状图
struct StatsColumnChartView: View {
    let values: [Double]
    let pCoreCount: Int
    var showLabels: Bool = false

    init(values: [Double], pCoreCount: Int, showLabels: Bool = false) {
        self.values = values
        self.pCoreCount = pCoreCount
        self.showLabels = showLabels
    }

    init(coreUsages: [Double], pCount: Int, showLabels: Bool = false) {
        self.values = coreUsages
        self.pCoreCount = pCount
        self.showLabels = showLabels
    }

    var body: some View {
        let count = max(1, values.count)
        HStack(alignment: .bottom, spacing: count > 12 ? 2 : 3) {
            ForEach(0..<count, id: \.self) { idx in
                let v = idx < values.count ? max(0.04, min(1.0, values[idx])) : 0.05
                let isPCore = idx < pCoreCount
                VStack(spacing: 2) {
                    GeometryReader { proxy in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                .fill(StatsTheme.trackBg)
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                .fill(isPCore ? StatsTheme.firstColor : StatsTheme.secondColor)
                                .frame(height: max(2.5, proxy.size.height * CGFloat(v)))
                        }
                    }
                    if showLabels {
                        Text(isPCore ? "P\(idx + 1)" : "E\(idx - pCoreCount + 1)")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.sub)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

/// 弹窗分隔标题：`── SECTION ──`
struct StatsSeparatorHeader: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Theme.sep)
                .frame(height: 1)
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.sub)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Rectangle()
                .fill(Theme.sep)
                .frame(height: 1)
        }
        .padding(.vertical, 1)
    }
}

/// 带色块键值对行
struct StatsColorRow: View {
    var color: Color?
    let title: String
    let value: String
    var compact: Bool = false

    init(color: Color?, title: String, value: String, compact: Bool = false) {
        self.color = color
        self.title = title
        self.value = value
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: compact ? 4 : 5) {
            if let color {
                RoundedRectangle(cornerRadius: 2.2, style: .continuous)
                    .fill(color)
                    .frame(width: compact ? 7.5 : 9, height: compact ? 7.5 : 9)
            }
            Text(title)
                .font(.system(size: compact ? 9.5 : 10))
                .foregroundColor(Theme.sub)
                .lineLimit(1)
            Spacer(minLength: 4)
            Text(value)
                .font(.system(size: compact ? 9.5 : 10, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.text)
                .lineLimit(1)
        }
    }
}

/// 标准键值对行
struct StatsPopupRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(Theme.sub)
                .lineLimit(1)
            Spacer(minLength: 6)
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.text)
                .lineLimit(1)
        }
    }
}

/// 状态胶囊徽章
struct StatsStatusBadge: View {
    let text: String
    let color: Color

    init(text: String, color: Color) {
        self.text = text
        self.color = color
    }

    init(text: String, isPositive: Bool) {
        self.text = text
        self.color = isPositive ? StatsTheme.fourthColor : Color.red
    }

    var body: some View {
        HStack(spacing: 3.5) {
            Circle()
                .fill(color)
                .frame(width: 5.5, height: 5.5)
            Text(text)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(color)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill(color.opacity(0.14)))
    }
}

struct ModernBentoCard<Content: View>: View {
    var isHighlighted: Bool = false
    var cornerRadius: CGFloat = 10
    var padding: CGFloat = 10
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(padding)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.card)
                if isHighlighted {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Theme.accent.opacity(0.10))
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    isHighlighted ? Theme.accent.opacity(0.75) : Theme.sep,
                    lineWidth: 1
                )
        }
        .shadow(color: Color.black.opacity(Theme.isDark ? 0.20 : 0.05), radius: 3, x: 0, y: 1.5)
    }
}

struct MiniPillTag: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .medium))
            .foregroundColor(Theme.sub)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(StatsTheme.boxBg)
            .cornerRadius(4)
            .lineLimit(1)
    }
}

struct MiniTag: View {
    let text: String
    var color: Color = Theme.sub
    init(_ text: String, color: Color = Theme.sub) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
            .lineLimit(1)
    }
}

struct MiniModeBtn: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    init(_ title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Theme.onAccent : Theme.sub)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3.5)
                .background(isSelected ? Theme.accent : StatsTheme.boxBg)
                .cornerRadius(5)
        }
        .buttonStyle(.plain)
    }
}

struct ProcessRowView: View {
    let proc: MonitoredProcessItem

    var body: some View {
        HStack(spacing: 8) {
            if let icon = ProcessIconCache.shared.icon(forAppPath: proc.appPath) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 15, height: 15)
            } else {
                Image(systemName: "gearshape.2.fill")
                    .frame(width: 14, height: 14)
                    .foregroundColor(Theme.sub)
            }

            Text(proc.name)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(Theme.text)
                .lineLimit(1)

            Spacer()

            Text(Fmt.size(proc.residentMemory))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(Theme.sub)
                .frame(width: 62, alignment: .trailing)

            Text(String(format: "%.1f%%", proc.cpuPercent))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(StatsTheme.utilizationColor(proc.cpuPercent / 100.0))
                .frame(width: 48, alignment: .trailing)
        }
        .padding(.vertical, 1.5)
    }
}

// 核心均衡器视图
struct CoreEqualizerView: View {
    let coreUsages: [Double]
    let pCount: Int

    var body: some View {
        StatsColumnChartView(values: coreUsages, pCoreCount: pCount, showLabels: true)
    }
}

// 内存精细化堆叠条
struct SegmentedStackedBarView: View {
    struct BarSegment {
        var title: String
        var bytes: Int64
        var color: Color
    }

    var segments: [BarSegment]
    var totalBytes: Int64

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let safeTotal = max(1, totalBytes)

            HStack(spacing: 1.5) {
                ForEach(segments.indices, id: \.self) { i in
                    let seg = segments[i]
                    let ratio = CGFloat(max(0, seg.bytes)) / CGFloat(safeTotal)
                    let segWidth = max(2, w * ratio)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(seg.color)
                        .frame(width: segWidth)
                }
            }
        }
        .cornerRadius(3)
    }
}

// MARK: - 时序图表悬浮时间与数值格式化辅助
enum ChartHoverHelper {
    static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df
    }()

    static func timestampString(index: Int, totalCount: Int) -> String {
        guard totalCount > 1 else { return timeFormatter.string(from: Date()) }
        let sampleInterval: Double = 2.0
        let secondsAgo = Double(max(0, totalCount - 1 - index)) * sampleInterval
        let date = Date().addingTimeInterval(-secondsAgo)
        return timeFormatter.string(from: date)
    }

    static func formatKBPerSec(_ kb: Double) -> String {
        if kb >= 1024.0 {
            return String(format: "%.1f MB/s", kb / 1024.0)
        } else if kb >= 1.0 {
            return String(format: "%.0f KB/s", kb)
        } else {
            return String(format: "%.0f B/s", max(0, kb * 1024.0))
        }
    }
}

// 双流面积波形图（支持鼠标悬浮查看对应时间与双路数据）
struct DualStreamWaveView: View {
    var primaryData: [Double]
    var secondaryData: [Double]
    var primaryColor: Color
    var secondaryColor: Color
    var isSpeedKB: Bool = false
    var isSpeedMB: Bool = false

    @State var hoverX: CGFloat? = nil

    var body: some View {
        GeometryReader { proxy in
            let w = max(1, proxy.size.width)
            let h = max(1, proxy.size.height)
            let count = max(2, primaryData.count)
            let maxVal: Double = {
                if isSpeedMB {
                    return max(primaryData.max() ?? 1.0, secondaryData.max() ?? 1.0, 1.0)
                } else if isSpeedKB {
                    return max(primaryData.max() ?? 10.0, secondaryData.max() ?? 10.0, 10.0)
                } else {
                    return 100.0
                }
            }()

            let hoveredIndex: Int? = {
                guard let hx = hoverX, primaryData.count >= 2 else { return nil }
                let ratio = min(1.0, max(0.0, hx / w))
                return min(primaryData.count - 1, max(0, Int(round(ratio * CGFloat(primaryData.count - 1)))))
            }()

            ZStack(alignment: .topLeading) {
                // Secondary wave (下层/系统/上行)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h))
                    for (i, v) in secondaryData.enumerated() {
                        let x = w * CGFloat(i) / CGFloat(count - 1)
                        let norm = CGFloat(min(1.0, max(0.0, v / maxVal)))
                        let y = h * (1.0 - norm * 0.85)
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.closeSubpath()
                }
                .fill(secondaryColor.opacity(0.22))

                // Primary wave (上层/用户/下载)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h))
                    for (i, v) in primaryData.enumerated() {
                        let x = w * CGFloat(i) / CGFloat(count - 1)
                        let norm = CGFloat(min(1.0, max(0.0, v / maxVal)))
                        let y = h * (1.0 - norm * 0.85)
                        p.addLine(to: CGPoint(x: x, y: y))
                    }
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.closeSubpath()
                }
                .fill(primaryColor.opacity(0.25))

                // Secondary stroke
                Path { p in
                    for (i, v) in secondaryData.enumerated() {
                        let x = w * CGFloat(i) / CGFloat(count - 1)
                        let norm = CGFloat(min(1.0, max(0.0, v / maxVal)))
                        let y = h * (1.0 - norm * 0.85)
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(secondaryColor.opacity(0.85), lineWidth: 1.0)

                // Primary stroke
                Path { p in
                    for (i, v) in primaryData.enumerated() {
                        let x = w * CGFloat(i) / CGFloat(count - 1)
                        let norm = CGFloat(min(1.0, max(0.0, v / maxVal)))
                        let y = h * (1.0 - norm * 0.85)
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(primaryColor, lineWidth: 1.3)

                // 鼠标悬浮指示线与时间+数据气泡
                if let idx = hoveredIndex, primaryData.indices.contains(idx) {
                    let cx = w * CGFloat(idx) / CGFloat(max(1, primaryData.count - 1))
                    let pVal = primaryData[idx]
                    let sVal = secondaryData.indices.contains(idx) ? secondaryData[idx] : 0.0
                    let py = h * (1.0 - CGFloat(min(1.0, max(0.0, pVal / maxVal))) * 0.85)
                    let sy = h * (1.0 - CGFloat(min(1.0, max(0.0, sVal / maxVal))) * 0.85)

                    Path { p in
                        p.move(to: CGPoint(x: cx, y: 0))
                        p.addLine(to: CGPoint(x: cx, y: h))
                    }
                    .stroke(Theme.text.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))

                    Circle()
                        .fill(secondaryColor)
                        .frame(width: 5, height: 5)
                        .position(x: cx, y: sy)

                    Circle()
                        .fill(primaryColor)
                        .frame(width: 5.5, height: 5.5)
                        .position(x: cx, y: py)

                    let timeStr = ChartHoverHelper.timestampString(index: idx, totalCount: primaryData.count)
                    let valText: String = {
                        if isSpeedMB {
                            return "R: \(String(format: "%.2f MB/s", pVal)) · W: \(String(format: "%.2f MB/s", sVal))"
                        } else if isSpeedKB {
                            return "↓\(ChartHoverHelper.formatKBPerSec(pVal)) ↑\(ChartHoverHelper.formatKBPerSec(sVal))"
                        } else {
                            return String(format: "%.0f%% / %.0f%%", pVal, sVal)
                        }
                    }()

                    HStack(spacing: 4) {
                        Text(timeStr)
                            .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.sub)
                        Text(valText)
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.text)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Theme.card.opacity(0.95))
                            .shadow(color: Color.black.opacity(0.18), radius: 2, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(Theme.sep, lineWidth: 0.6)
                    )
                    .frame(maxWidth: .infinity, alignment: cx > w * 0.55 ? .leading : .trailing)
                    .padding(.horizontal, 2)
                    .padding(.top, 1)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let loc):
                    hoverX = loc.x
                case .ended:
                    hoverX = nil
                }
            }
        }
    }
}

struct MiniCoreBarsView: View {
    let coreUsages: [Double]

    var body: some View {
        StatsColumnChartView(values: coreUsages, pCoreCount: max(1, coreUsages.count / 2), showLabels: false)
    }
}

struct MiniWaveView: View {
    let data: [Double]
    let color: Color
    var fixedMax: Double? = nil
    var unitSuffix: String = "%"
    var valueFormat: String = "%.0f"

    var body: some View {
        MiniAreaView(
            data: data,
            color: color,
            fixedMax: fixedMax,
            unitSuffix: unitSuffix,
            valueFormat: valueFormat
        )
    }
}

struct MiniAreaWaveView: View {
    let data: [Double]
    let color: Color
    var fixedMax: Double? = nil
    var unitSuffix: String = "%"
    var valueFormat: String = "%.0f"

    var body: some View {
        MiniAreaView(
            data: data,
            color: color,
            fixedMax: fixedMax,
            unitSuffix: unitSuffix,
            valueFormat: valueFormat
        )
    }
}

struct MiniAreaView: View {
    let data: [Double]
    let color: Color
    var fixedMax: Double? = nil
    var unitSuffix: String = "%"
    var valueFormat: String = "%.0f"

    @State var hoverX: CGFloat? = nil

    var body: some View {
        GeometryReader { proxy in
            let pts = Array(data.suffix(60))
            let maxV = fixedMax ?? max(pts.max() ?? 100.0, 1.0)
            let w = max(1, proxy.size.width)
            let h = max(1, proxy.size.height)

            let hoveredIndex: Int? = {
                guard let hx = hoverX, pts.count >= 2 else { return nil }
                let ratio = min(1.0, max(0.0, hx / w))
                return min(pts.count - 1, max(0, Int(round(ratio * CGFloat(pts.count - 1)))))
            }()

            if pts.count >= 2 {
                ZStack(alignment: .topLeading) {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h))
                        for (i, v) in pts.enumerated() {
                            let x = w * CGFloat(i) / CGFloat(pts.count - 1)
                            let y = h * (1.0 - CGFloat(max(0, min(1.0, v / maxV))) * 0.85)
                            p.addLine(to: CGPoint(x: x, y: y))
                        }
                        p.addLine(to: CGPoint(x: w, y: h))
                        p.closeSubpath()
                    }
                    .fill(color.opacity(0.22))

                    Path { p in
                        for (i, v) in pts.enumerated() {
                            let x = w * CGFloat(i) / CGFloat(pts.count - 1)
                            let y = h * (1.0 - CGFloat(max(0, min(1.0, v / maxV))) * 0.85)
                            if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                            else { p.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(color, lineWidth: 1.2)

                    if let idx = hoveredIndex, pts.indices.contains(idx) {
                        let cx = w * CGFloat(idx) / CGFloat(max(1, pts.count - 1))
                        let val = pts[idx]
                        let cy = h * (1.0 - CGFloat(max(0, min(1.0, val / maxV))) * 0.85)

                        Path { p in
                            p.move(to: CGPoint(x: cx, y: 0))
                            p.addLine(to: CGPoint(x: cx, y: h))
                        }
                        .stroke(Theme.text.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))

                        Circle()
                            .fill(color)
                            .frame(width: 5, height: 5)
                            .position(x: cx, y: cy)

                        let timeStr = ChartHoverHelper.timestampString(index: idx, totalCount: pts.count)
                        let valStr = String(format: valueFormat, val) + unitSuffix

                        HStack(spacing: 4) {
                            Text(timeStr)
                                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.sub)
                            Text(valStr)
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.text)
                        }
                        .padding(.horizontal, 4.5)
                        .padding(.vertical, 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Theme.card.opacity(0.95))
                                .shadow(color: Color.black.opacity(0.18), radius: 2, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(Theme.sep, lineWidth: 0.6)
                        )
                        .frame(maxWidth: .infinity, alignment: cx > w * 0.55 ? .leading : .trailing)
                        .padding(.horizontal, 2)
                        .padding(.top, 1)
                    }
                }
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let loc):
                        hoverX = loc.x
                    case .ended:
                        hoverX = nil
                    }
                }
            }
        }
    }
}

struct SubcategoryHoverModifier: ViewModifier {
    let kind: CompanionSubcategoryKind

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    let minY = geo.frame(in: .named("MenuBarPopoverSpace")).minY
                    Color.clear
                        .onAppear {
                            SubcategoryFlyoutState.shared.itemTopOffsets[kind] = minY
                        }
                        .onChange(of: minY) { newY in
                            SubcategoryFlyoutState.shared.itemTopOffsets[kind] = newY
                        }
                }
            )
            .onHover { hovering in
                if hovering {
                    SubcategoryFlyoutState.shared.enterMainItemWithSubcategory(kind)
                } else {
                    SubcategoryFlyoutState.shared.leaveMainItem(for: kind)
                }
            }
    }
}

// MARK: - Weather Adaptive Icon & Badge Components

struct WeatherAdaptiveIconView: View {
    let iconName: String
    var fontSize: CGFloat = 13
    var fontWeight: Font.Weight = .medium

    var isNight: Bool {
        iconName.contains("moon")
    }

    var body: some View {
        let isDark = Theme.isDark
        Group {
            if isDark {
                // 暗色模式：原色渲染对比度优秀
                Image(systemName: iconName)
                    .renderingMode(.original)
                    .font(.system(size: fontSize, weight: fontWeight))
            } else {
                // 亮色模式：彻底解决白色云朵在浅色卡片底色上完全看不清的体验问题
                lightModeWeatherIcon
            }
        }
    }

    @ViewBuilder
    private var lightModeWeatherIcon: some View {
        if iconName == "sun.max.fill" || iconName.contains("sun.max") {
            Image(systemName: iconName)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(.orange)
        } else if iconName == "moon.stars.fill" || iconName.contains("moon.fill") {
            Image(systemName: iconName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.yellow, Color.indigo)
                .font(.system(size: fontSize, weight: fontWeight))
        } else if iconName == "cloud.fill" {
            // 纯阴天：原版为纯白，浅色底隐形；亮模式采用有质感的蓝灰色云朵
            Image(systemName: iconName)
                .font(.system(size: fontSize, weight: fontWeight))
                .foregroundColor(Color(red: 0.40, green: 0.47, blue: 0.58))
        } else if iconName == "cloud.fog.fill" {
            // 雾霾/大雾
            Image(systemName: iconName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(red: 0.40, green: 0.47, blue: 0.58), Color(red: 0.55, green: 0.62, blue: 0.72))
                .font(.system(size: fontSize, weight: fontWeight))
        } else if iconName == "cloud.sun.fill" {
            // 多云伴晴：云朵着蓝灰，太阳着暖橙，层次分明
            Image(systemName: iconName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(red: 0.45, green: 0.52, blue: 0.62), Color.orange)
                .font(.system(size: fontSize, weight: fontWeight))
        } else if iconName == "cloud.moon.fill" {
            // 夜间多云：云朵着深灰蓝，月亮着淡金
            Image(systemName: iconName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(red: 0.45, green: 0.52, blue: 0.62), Color.yellow)
                .font(.system(size: fontSize, weight: fontWeight))
        } else if iconName == "cloud.rain.fill" || iconName == "cloud.heavyrain.fill" {
            // 下雨：云朵着深灰蓝，雨滴着明亮天蓝色
            Image(systemName: iconName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(red: 0.42, green: 0.49, blue: 0.60), Color(red: 0.15, green: 0.55, blue: 0.95))
                .font(.system(size: fontSize, weight: fontWeight))
        } else if iconName == "cloud.snow.fill" {
            // 下雪：云朵着深灰蓝，雪花着冰蓝
            Image(systemName: iconName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(red: 0.42, green: 0.49, blue: 0.60), Color(red: 0.35, green: 0.70, blue: 0.95))
                .font(.system(size: fontSize, weight: fontWeight))
        } else if iconName == "cloud.bolt.rain.fill" {
            // 雷阵雨：云朵深灰蓝、闪电亮金黄、雨滴天蓝
            Image(systemName: iconName)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(red: 0.42, green: 0.49, blue: 0.60), Color.yellow, Color(red: 0.15, green: 0.55, blue: 0.95))
                .font(.system(size: fontSize, weight: fontWeight))
        } else {
            // 兜底：若包含 cloud 则用高对比度蓝灰，否则原色
            if iconName.contains("cloud") {
                Image(systemName: iconName)
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundColor(Color(red: 0.42, green: 0.49, blue: 0.60))
            } else {
                Image(systemName: iconName)
                    .renderingMode(.original)
                    .font(.system(size: fontSize, weight: fontWeight))
            }
        }
    }
}

struct WeatherSymbolBadgeView: View {
    let iconName: String

    var isNight: Bool {
        iconName.contains("moon")
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(badgeBgColor)
                .frame(width: 24, height: 24)
            WeatherAdaptiveIconView(iconName: iconName, fontSize: 11.5, fontWeight: .semibold)
        }
    }

    private var badgeBgColor: Color {
        let isDark = Theme.isDark
        if iconName.contains("sun") {
            return Color.orange.opacity(isDark ? 0.20 : 0.14)
        } else if iconName.contains("moon") {
            return Color.indigo.opacity(isDark ? 0.22 : 0.14)
        } else if iconName.contains("rain") || iconName.contains("snow") || iconName.contains("bolt") {
            return Color.blue.opacity(isDark ? 0.20 : 0.14)
        } else {
            // 阴天/雾天
            return Color(red: 0.40, green: 0.47, blue: 0.58).opacity(isDark ? 0.20 : 0.15)
        }
    }
}
