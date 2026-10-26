import SwiftUI
import AppKit

// ============================================================
//  MenuBarDetailDashboards.swift —— 菜单栏二级看板、天气和日历 Agenda
//
//  全面兼容：
//    1. 暗色 (Dark) / 明亮 (Light) 双主题自适应 (Theme.isDark / Theme.text / Theme.sub / Theme.card / StatsTheme.boxBg)；
//    2. CleanMate 6 套主题色预设 (AppThemePreset: warmAmber, oceanBlue, emeraldForest, violetNebula, roseQuartz, graphiteMono)；
//    3. 纯 Shape 矢量波形绘制，零编译类型推导开销。
// ============================================================

// MARK: - 0. 零开销矢量波形 Shape 与顶部时间跨度选择器 (3h, 5h, 24h, 3d, 7d)

struct MenuBarAreaWaveShape: Shape {
    let points: [Double]
    var scale: CGFloat = 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        let w = rect.width
        let h = rect.height
        let step = w / CGFloat(points.count - 1)
        path.move(to: CGPoint(x: 0, y: h))
        for (i, val) in points.enumerated() {
            let x = CGFloat(i) * step
            let clamped = min(1.0, max(0.0, val * Double(scale)))
            let y = h - CGFloat(clamped) * (h - 2)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        return path
    }
}

struct MenuBarAreaWaveStrokeShape: Shape {
    let points: [Double]
    var scale: CGFloat = 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        let w = rect.width
        let h = rect.height
        let step = w / CGFloat(points.count - 1)
        for (i, val) in points.enumerated() {
            let x = CGFloat(i) * step
            let clamped = min(1.0, max(0.0, val * Double(scale)))
            let y = h - CGFloat(clamped) * (h - 2)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

struct MenuBarBiDirectionalWaveShape: Shape {
    let points: [Double]
    let isUp: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        let w = rect.width
        let h = rect.height
        let mid = h / 2.0
        let step = w / CGFloat(points.count - 1)
        path.move(to: CGPoint(x: 0, y: mid))
        for (i, val) in points.enumerated() {
            let x = CGFloat(i) * step
            let offset = CGFloat(min(1.0, max(0.05, val))) * (mid - 2)
            let y = isUp ? (mid - offset) : (mid + offset)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: w, y: mid))
        path.closeSubpath()
        return path
    }
}

struct MenuBarWaveHoverOverlay: View {
    let rawPoints: [Double]
    var valueFormat: String = "%.0f"
    var unitSuffix: String = "%"
    var accentColor: Color = Theme.accent
    @State private var hoverX: CGFloat? = nil

    var body: some View {
        GeometryReader { geo in
            let w = max(1, geo.size.width)
            let h = max(1, geo.size.height)
            ZStack(alignment: .topLeading) {
                Color.clear
                if let hx = hoverX, rawPoints.count > 1 {
                    let ratio = max(0, min(1, hx / w))
                    let idx = min(rawPoints.count - 1, max(0, Int((ratio * CGFloat(rawPoints.count - 1)).rounded())))
                    let cx = w * CGFloat(idx) / CGFloat(max(1, rawPoints.count - 1))
                    let val = rawPoints[idx]
                    let timeStr = ChartHoverHelper.timestampString(index: idx, totalCount: rawPoints.count)

                    Path { p in
                        p.move(to: CGPoint(x: cx, y: 0))
                        p.addLine(to: CGPoint(x: cx, y: h))
                    }
                    .stroke(Theme.text.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))

                    HStack(spacing: 3) {
                        Text(timeStr)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.sub)
                        Text(String(format: valueFormat, val) + unitSuffix)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(accentColor)
                    }
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Theme.card.opacity(0.95))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(Theme.sep, lineWidth: 0.6)
                    )
                    .frame(maxWidth: .infinity, alignment: cx > w * 0.55 ? .leading : .trailing)
                    .padding(2)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let loc): hoverX = loc.x
                case .ended: hoverX = nil
                }
            }
        }
    }
}

struct MenuBarTimeSpanHeader: View {
    let title: String
    @Binding var selectedRange: TelemetryTimeRange

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(Theme.accent)
            Spacer()
            HStack(spacing: 2) {
                ForEach(TelemetryTimeRange.allCases) { range in
                    let active = selectedRange == range
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedRange = range
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 8.5, weight: active ? .bold : .medium, design: .monospaced))
                            .padding(.horizontal, 5.5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(active ? Theme.accent : StatsTheme.boxBg))
                            .foregroundColor(active ? Theme.onAccent : Theme.sub)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 2)
    }
}
