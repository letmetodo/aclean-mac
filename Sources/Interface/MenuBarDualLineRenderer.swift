import AppKit
import SwiftUI

// ============================================================
//  MenuBarDualLineRenderer —— 多态主题化状态栏矢量渲染器
//
//  职责：
//    1. 状态栏小组件视觉：
//       - Stats Mini 样式：上行 7pt 紧凑模块标签 (CPU / RAM / GPU / DSK / TMP) + 下行 11.5pt 高对比等宽数值；
//       - Stats BarChart 柱阵：带圆角底槽轨道与渐变填充的实时柱状图；
//       - Stats PieChart 微缩圆环：多段彩色圆环 (User/Sys、App/Wired/Compressed)；
//       - Stats SpeedWidget 双行网速：左侧上下行状态指示圆点 (● 流量激活点亮) + 右对齐速率；
//    2. 全链路接入 CleanMate 6 套主题预设 (AppThemePreset) 与 4 种状态栏着色模式 (MenuBarColorMode)。
// ============================================================

@MainActor
enum MenuBarDualLineRenderer {

    enum MiniGraphicKind {
        case none
        case barChart([Double])                                  // 文本右侧多柱迷你图 (0.0 ~ 100.0)
        case lineChartBox([Double], NSColor)                     // Stats LineChart 独立深色圆角盒曲线 (28x16pt)
        case barChartBox(Double, NSColor)                        // Stats BarChart 独立竖向胶囊柱 (9x16pt)
        case lineAndBarBox([Double], Double, NSColor)            // Stats LineChart + BarChart 组合 (推荐预设)
        case verticalLabel(String)                               // Stats 竖排三字母标签 (S/E/N)
        case batteryIcon(Double, Bool)                           // Stats 横向电池图标 (22x11pt)
        case pieRing([(ratio: Double, color: NSColor)])
        case speedDots(upActive: Bool, downActive: Bool, upColor: NSColor, downColor: NSColor)
    }

    struct TokenDrawSpec {
        var topText: String
        var bottomText: String
        var topColor: NSColor
        var bottomColor: NSColor
        var isMiniLabelTop: Bool = false      // true: Stats Mini 模式 (上行7pt浅标签 + 下行11.5pt粗体值)
        var graphic: MiniGraphicKind = .none
    }

    // MARK: - 主题色与 MenuBarColorMode 动态解析
    static func themeAccentNSColors() -> (primary: NSColor, secondary: NSColor) {
        let isDark = AppConfigStore.shared.isEffectiveDark
        let preset = AppConfigStore.shared.currentThemePreset
        let p = preset.primaryRGB(isDark: isDark)
        let s = preset.secondaryRGB(isDark: isDark)
        return (
            NSColor(calibratedRed: p.r, green: p.g, blue: p.b, alpha: 1.0),
            NSColor(calibratedRed: s.r, green: s.g, blue: s.b, alpha: 1.0)
        )
    }

    static func resolveWidgetAccent(
        mode: MenuBarColorMode,
        usageRatio: Double,
        classicColor: NSColor
    ) -> NSColor {
        switch mode {
        case .monochrome:
            return NSColor.labelColor
        case .utilization:
            if usageRatio >= 0.80 {
                return NSColor.systemRed
            } else if usageRatio >= 0.60 {
                return NSColor.systemOrange
            } else {
                return themeAccentNSColors().primary
            }
        case .classicMulti:
            if usageRatio >= 0.85 { return NSColor.systemRed }
            return classicColor
        case .themeAccent:
            if usageRatio >= 0.85 { return NSColor.systemRed }
            return themeAccentNSColors().primary
        }
    }

    /// 根据当前快照与用户配置的令牌列表，生成 Stats 风格状态栏矢量图
    private static var cachedFingerprint: String?
    private static var cachedImage: NSImage?

    static func renderStatusBarImage(
        tokens: [MenuBarTokenKind],
        snapshot: TelemetrySnapshot?,
        weather: WeatherSnapshot,
        cpuHistory: [Double]
    ) -> NSImage {
        let specs = tokens.map { makeSpec(for: $0, snapshot: snapshot, weather: weather, cpuHistory: cpuHistory) }
        let fingerprint = String(reflecting: specs) + (NSApp?.effectiveAppearance.name.rawValue ?? "")
            + String(describing: NSScreen.main?.backingScaleFactor ?? 2)
        if cachedFingerprint == fingerprint, let cachedImage { return cachedImage }

        // 状态栏微组件字号体系
        let miniLabelFont = NSFont.systemFont(ofSize: 7.0, weight: .semibold)
        let miniValueFont = NSFont.monospacedDigitSystemFont(ofSize: 11.0, weight: .semibold)
        let topFont = NSFont.monospacedDigitSystemFont(ofSize: 9.2, weight: .semibold)
        let bottomFont = NSFont.monospacedDigitSystemFont(ofSize: 8.2, weight: .medium)
        let singleFont = NSFont.monospacedDigitSystemFont(ofSize: 11.5, weight: .semibold)

        let itemSpacing: CGFloat = 8.0
        let barChartWidth: CGFloat = 16.0
        let lineBoxWidth: CGFloat = 28.0
        let singleBarWidth: CGFloat = 9.0
        let pieRingSize: CGFloat = 14.0
        let speedDotsWidth: CGFloat = 7.0
        let horizontalPad: CGFloat = 4.0
        let barHeight: CGFloat = 22.0

        var widths: [CGFloat] = []
        for s in specs {
            let hasText = !s.topText.isEmpty || !s.bottomText.isEmpty
            let isSingle = hasText && s.bottomText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            var w: CGFloat = 0
            if !hasText {
                w = 0
            } else if isSingle {
                let sSize = (s.topText as NSString).size(withAttributes: [.font: singleFont])
                let isNumeric = s.topText.contains("%") || s.topText.contains("°") || s.topText.contains("G")
                w = ceil(max(isNumeric ? 31.0 : 24.0, sSize.width))
            } else if s.isMiniLabelTop {
                let tSize = (s.topText as NSString).size(withAttributes: [.font: miniLabelFont])
                let bSize = (s.bottomText as NSString).size(withAttributes: [.font: miniValueFont])
                // 对齐 3 位百分比/数值标准槽位宽 (如 "100%")，杜绝 123 -> 1 位数跳变引起的整栏水平抖动
                let isNumeric = s.bottomText.contains("%") || s.bottomText.contains("°") || s.bottomText.contains("G") || s.bottomText.contains("M") || s.bottomText.contains("K")
                let stableBottomWidth = max(bSize.width, isNumeric ? 28.5 : 24.0)
                w = ceil(max(tSize.width, stableBottomWidth))
            } else {
                let tSize = (s.topText as NSString).size(withAttributes: [.font: topFont])
                let bSize = (s.bottomText as NSString).size(withAttributes: [.font: bottomFont])
                let isNumeric = s.topText.contains("%") || s.bottomText.contains("%") || s.topText.contains(":") || s.bottomText.contains(":")
                let stableWidth = max(max(tSize.width, bSize.width), isNumeric ? 33.0 : 24.0)
                w = ceil(stableWidth)
            }

            switch s.graphic {
            case .none:
                w = max(isSingle ? 24.0 : 28.0, w)
            case .barChart:
                w += (hasText ? 3.5 : 0) + barChartWidth
                w = max(28.0, w)
            case .lineChartBox:
                w += (hasText ? 3.5 : 0) + lineBoxWidth
            case .barChartBox:
                w += (hasText ? 3.5 : 0) + singleBarWidth
            case .lineAndBarBox:
                w += (hasText ? 3.5 : 0) + lineBoxWidth + 2.5 + singleBarWidth
            case .verticalLabel:
                w = max(10.0, w + 9.0)
            case .batteryIcon:
                w = max(24.0, w + 24.0)
            case .pieRing:
                w += (hasText ? 3.5 : 0) + pieRingSize
            case .speedDots:
                // 网速文本标准对齐槽位 (宽 36pt，可稳定容纳 0K/s ~ 99.9M/s)，彻底杜绝网速数值变化引起的菜单栏左右跳动
                let minSpeedTextWidth: CGFloat = 36.0
                let textW = max(w, minSpeedTextWidth)
                w = textW + speedDotsWidth
            }
            widths.append(w)
        }

        let totalWidth = horizontalPad * 2
            + widths.reduce(0, +)
            + CGFloat(max(0, specs.count - 1)) * itemSpacing

        let imgSize = NSSize(width: max(34, totalWidth), height: barHeight)
        let image = NSImage(size: imgSize, flipped: false) { _ in
            var curX = horizontalPad

            for (idx, s) in specs.enumerated() {
                let colWidth = widths[idx]
                let hasText = !s.topText.isEmpty || !s.bottomText.isEmpty
                var textStartX = curX
                var textAvailWidth = colWidth

                switch s.graphic {
                case .none:
                    break
                case .barChart:
                    textAvailWidth = colWidth - barChartWidth - (hasText ? 3.5 : 0)
                case .lineChartBox(let hist, let color):
                    let boxX = hasText ? (curX + colWidth - lineBoxWidth) : curX
                    drawStatsLineChartBox(
                        in: NSRect(x: boxX, y: 3.0, width: lineBoxWidth, height: 16.0),
                        values: hist,
                        accentColor: color
                    )
                    textAvailWidth = max(0, colWidth - lineBoxWidth - (hasText ? 3.5 : 0))
                case .barChartBox(let ratio, let color):
                    let boxX = hasText ? (curX + colWidth - singleBarWidth) : curX
                    drawStatsSingleBarBox(
                        in: NSRect(x: boxX, y: 3.0, width: singleBarWidth, height: 16.0),
                        ratio: ratio,
                        accentColor: color
                    )
                    textAvailWidth = max(0, colWidth - singleBarWidth - (hasText ? 3.5 : 0))
                case .lineAndBarBox(let hist, let ratio, let color):
                    let totalGWidth = lineBoxWidth + 2.5 + singleBarWidth
                    let boxX = hasText ? (curX + colWidth - totalGWidth) : curX
                    drawStatsLineChartBox(
                        in: NSRect(x: boxX, y: 3.0, width: lineBoxWidth, height: 16.0),
                        values: hist,
                        accentColor: color
                    )
                    drawStatsSingleBarBox(
                        in: NSRect(x: boxX + lineBoxWidth + 2.5, y: 3.0, width: singleBarWidth, height: 16.0),
                        ratio: ratio,
                        accentColor: color
                    )
                    textAvailWidth = max(0, colWidth - totalGWidth - (hasText ? 3.5 : 0))
                case .verticalLabel(let chars):
                    drawStatsVerticalLabel(
                        in: NSRect(x: curX, y: 2.0, width: 9.0, height: 18.0),
                        text: chars,
                        color: s.topColor
                    )
                    textStartX = curX + 9.0
                    textAvailWidth = max(0, colWidth - 9.0)
                case .batteryIcon(let ratio, let isCharging):
                    drawStatsBatteryIcon(
                        in: NSRect(x: curX, y: 5.5, width: 22.0, height: 11.0),
                        ratio: ratio,
                        isCharging: isCharging
                    )
                    textAvailWidth = 0
                case .pieRing(let segments):
                    // 左侧绘制 Stats PieChart 微缩圆环
                    let ringRect = NSRect(x: curX, y: (barHeight - pieRingSize) / 2.0, width: pieRingSize, height: pieRingSize)
                    drawMiniPieRing(in: ringRect, segments: segments)
                    textStartX = curX + pieRingSize + 3.5
                    textAvailWidth = colWidth - pieRingSize - 3.5
                case .speedDots(let upActive, let downActive, let upColor, let downColor):
                    // 左侧绘制 Stats SpeedWidget 上下行圆点指示器
                    let dotSize: CGFloat = 4.5
                    let dotX = curX + 0.5
                    let upDotRect = NSRect(x: dotX, y: 12.8, width: dotSize, height: dotSize)
                    let downDotRect = NSRect(x: dotX, y: 4.5, width: dotSize, height: dotSize)
                    let inactiveDot = NSColor.labelColor.withAlphaComponent(0.22)

                    (upActive ? upColor : inactiveDot).setFill()
                    NSBezierPath(ovalIn: upDotRect).fill()

                    (downActive ? downColor : inactiveDot).setFill()
                    NSBezierPath(ovalIn: downDotRect).fill()

                    textStartX = curX + speedDotsWidth
                    textAvailWidth = colWidth - speedDotsWidth
                }

                let isSingle = hasText && s.bottomText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

                if !hasText {
                    // 纯图形小组件 (LineChart / BarChart / BatteryIcon / VerticalLabel)，不绘制右侧文字
                } else if isSingle {
                    let singleAttrs: [NSAttributedString.Key: Any] = [
                        .font: singleFont,
                        .foregroundColor: s.topColor
                    ]
                    let tStr = s.topText as NSString
                    let tSize = tStr.size(withAttributes: singleAttrs)
                    let tX = textStartX + max(0, (textAvailWidth - tSize.width) / 2.0)
                    let tY = round((barHeight - tSize.height) / 2.0)
                    tStr.draw(at: NSPoint(x: tX, y: tY), withAttributes: singleAttrs)
                } else if s.isMiniLabelTop {
                    // Stats Mini.swift 布局：上行 7pt 标签 + 下行 11pt 数值
                    let topAttrs: [NSAttributedString.Key: Any] = [
                        .font: miniLabelFont,
                        .foregroundColor: s.topColor
                    ]
                    let bottomAttrs: [NSAttributedString.Key: Any] = [
                        .font: miniValueFont,
                        .foregroundColor: s.bottomColor
                    ]
                    let tStr = s.topText as NSString
                    let bStr = s.bottomText as NSString
                    let tSize = tStr.size(withAttributes: topAttrs)
                    let bSize = bStr.size(withAttributes: bottomAttrs)

                    let tX = textStartX + max(0, (textAvailWidth - tSize.width) / 2.0)
                    let bX = textStartX + max(0, (textAvailWidth - bSize.width) / 2.0)

                    tStr.draw(at: NSPoint(x: tX, y: 13.0), withAttributes: topAttrs)
                    bStr.draw(at: NSPoint(x: bX, y: 1.0), withAttributes: bottomAttrs)
                } else {
                    let topAttrs: [NSAttributedString.Key: Any] = [
                        .font: topFont,
                        .foregroundColor: s.topColor
                    ]
                    let bottomAttrs: [NSAttributedString.Key: Any] = [
                        .font: bottomFont,
                        .foregroundColor: s.bottomColor
                    ]

                    let tStr = s.topText as NSString
                    let bStr = s.bottomText as NSString
                    let tSize = tStr.size(withAttributes: topAttrs)
                    let bSize = bStr.size(withAttributes: bottomAttrs)

                    let isRightAligned: Bool = {
                        if case .speedDots = s.graphic { return true }
                        return false
                    }()

                    let tX = isRightAligned
                        ? (textStartX + max(0, textAvailWidth - tSize.width))
                        : (textStartX + max(0, (textAvailWidth - tSize.width) / 2.0))
                    let bX = isRightAligned
                        ? (textStartX + max(0, textAvailWidth - bSize.width))
                        : (textStartX + max(0, (textAvailWidth - bSize.width) / 2.0))

                    tStr.draw(at: NSPoint(x: tX, y: 10.6), withAttributes: topAttrs)
                    bStr.draw(at: NSPoint(x: bX, y: 1.4), withAttributes: bottomAttrs)
                }

                // 右侧绘制 Stats BarChart / ColumnChart 迷你柱阵
                if case .barChart(let hist) = s.graphic {
                    let sparkX = curX + textAvailWidth + 3.5
                    let sparkY: CGFloat = 3.0
                    let sparkH: CGFloat = 16.0
                    drawMiniBarChart(
                        in: NSRect(x: sparkX, y: sparkY, width: barChartWidth, height: sparkH),
                        values: hist
                    )
                }

                // Stats CombinedView.swift 风格模块分隔细竖线
                if idx < specs.count - 1 {
                    let sepX = curX + colWidth + itemSpacing / 2.0
                    NSColor.labelColor.withAlphaComponent(0.15).setFill()
                    NSBezierPath(rect: NSRect(x: sepX, y: 4.0, width: 0.8, height: 14.0)).fill()
                }

                curX += colWidth + itemSpacing
            }
            return true
        }
        image.isTemplate = false
        cachedFingerprint = fingerprint
        cachedImage = image
        return image
    }

    // MARK: - Stats 风格微缩柱状图 (复刻 Kit/Widgets/BarChart.swift + ColumnChartView)
    private static func drawMiniBarChart(in rect: NSRect, values: [Double]) {
        let mode = MenuBarConfigStore.shared.menuBarColorMode
        let (themePrimary, _) = themeAccentNSColors()

        // 外框微底盒
        let boxPath = NSBezierPath(roundedRect: rect, xRadius: 2.2, yRadius: 2.2)
        NSColor.labelColor.withAlphaComponent(0.08).setFill()
        boxPath.fill()

        let tail = Array(values.suffix(6))
        let count = max(1, tail.count)
        let innerX = rect.minX + 1.5
        let innerY = rect.minY + 1.5
        let innerW = rect.width - 3.0
        let innerH = rect.height - 3.0
        let spacing: CGFloat = 1.0
        let barW = max(1.2, (innerW - CGFloat(count - 1) * spacing) / CGFloat(count))

        for (i, rawVal) in tail.enumerated() {
            let bx = innerX + CGFloat(i) * (barW + spacing)
            // 柱底槽轨道 (Stats ColumnChartView track)
            let trackRect = NSRect(x: bx, y: innerY, width: barW, height: innerH)
            NSColor.labelColor.withAlphaComponent(0.12).setFill()
            NSBezierPath(roundedRect: trackRect, xRadius: 0.8, yRadius: 0.8).fill()

            let norm = CGFloat(min(1.0, max(0.08, rawVal / 100.0)))
            let fillH = innerH * norm
            let fillRect = NSRect(x: bx, y: innerY, width: barW, height: fillH)

            let barColor: NSColor
            switch mode {
            case .monochrome:
                barColor = NSColor.labelColor.withAlphaComponent(0.88)
            case .utilization:
                if rawVal > 80 { barColor = .systemRed }
                else if rawVal > 55 { barColor = .systemOrange }
                else { barColor = themePrimary }
            case .classicMulti:
                if rawVal > 80 { barColor = .systemRed }
                else if rawVal > 55 { barColor = .systemOrange }
                else { barColor = .systemBlue }
            case .themeAccent:
                barColor = rawVal > 82 ? .systemRed : themePrimary
            }

            barColor.setFill()
            NSBezierPath(roundedRect: fillRect, xRadius: 0.8, yRadius: 0.8).fill()
        }
    }

    // MARK: - Stats 风格微缩多段圆环 (复刻 Kit/Widgets/PieChart.swift)
    private static func drawMiniPieRing(in rect: NSRect, segments: [(ratio: Double, color: NSColor)]) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()
        ctx.setShouldAntialias(true)

        let lineWidth: CGFloat = 2.6
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = (min(rect.width, rect.height) - lineWidth) / 2.0

        // 底轨圆环
        ctx.setLineWidth(lineWidth)
        ctx.setStrokeColor(NSColor.labelColor.withAlphaComponent(0.18).cgColor)
        ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.strokePath()

        var curAngle: CGFloat = .pi / 2.0
        for seg in segments where seg.ratio > 0.005 {
            let sweep = CGFloat(min(1.0, seg.ratio)) * .pi * 2.0
            let nextAngle = curAngle - sweep
            ctx.setStrokeColor(seg.color.cgColor)
            ctx.setLineCap(.butt)
            ctx.addArc(center: center, radius: radius, startAngle: curAngle, endAngle: nextAngle, clockwise: true)
            ctx.strokePath()
            curAngle = nextAngle
        }
        ctx.restoreGState()
    }

    // MARK: - Stats 风格 LineChart 独立深色圆角盒曲线 (复刻 Kit/Widgets/LineChart.swift)
    private static func drawStatsLineChartBox(in rect: NSRect, values: [Double], accentColor: NSColor) {
        let boxBg = NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.17, alpha: 0.92)
        let boxPath = NSBezierPath(roundedRect: rect, xRadius: 3.0, yRadius: 3.0)
        boxBg.setFill()
        boxPath.fill()

        NSColor.labelColor.withAlphaComponent(0.18).setStroke()
        boxPath.lineWidth = 0.6
        boxPath.stroke()

        let tail = values.count >= 2 ? Array(values.suffix(18)) : [15, 22, 18, 34, 28, 42, 31, 36]
        guard tail.count >= 2 else { return }

        let innerX = rect.minX + 1.5
        let innerY = rect.minY + 1.5
        let innerW = rect.width - 3.0
        let innerH = rect.height - 3.0

        let linePath = NSBezierPath()
        let areaPath = NSBezierPath()
        areaPath.move(to: NSPoint(x: innerX, y: innerY))

        for (i, raw) in tail.enumerated() {
            let x = innerX + innerW * CGFloat(i) / CGFloat(max(1, tail.count - 1))
            let norm = CGFloat(min(1.0, max(0.06, raw / 100.0)))
            let y = innerY + innerH * norm
            let pt = NSPoint(x: x, y: y)
            if i == 0 {
                linePath.move(to: pt)
            } else {
                linePath.line(to: pt)
            }
            areaPath.line(to: pt)
        }
        areaPath.line(to: NSPoint(x: innerX + innerW, y: innerY))
        areaPath.close()

        accentColor.withAlphaComponent(0.28).setFill()
        areaPath.fill()

        accentColor.setStroke()
        linePath.lineWidth = 1.15
        linePath.lineJoinStyle = .round
        linePath.stroke()
    }

    // MARK: - Stats 风格 BarChart 独立竖向胶囊槽 (复刻 Kit/Widgets/BarChart.swift)
    private static func drawStatsSingleBarBox(in rect: NSRect, ratio: Double, accentColor: NSColor) {
        let boxBg = NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.17, alpha: 0.92)
        let boxPath = NSBezierPath(roundedRect: rect, xRadius: 2.5, yRadius: 2.5)
        boxBg.setFill()
        boxPath.fill()

        NSColor.labelColor.withAlphaComponent(0.20).setStroke()
        boxPath.lineWidth = 0.6
        boxPath.stroke()

        let pad: CGFloat = 1.4
        let innerW = max(2.0, rect.width - pad * 2)
        let innerH = max(2.0, rect.height - pad * 2)
        let norm = CGFloat(min(1.0, max(0.08, ratio)))
        let fillH = innerH * norm
        let fillRect = NSRect(x: rect.minX + pad, y: rect.minY + pad, width: innerW, height: fillH)

        let fillColor: NSColor
        if ratio > 0.85 {
            fillColor = .systemRed
        } else if ratio > 0.65 {
            fillColor = .systemOrange
        } else {
            fillColor = accentColor
        }
        fillColor.setFill()
        NSBezierPath(roundedRect: fillRect, xRadius: 1.4, yRadius: 1.4).fill()
    }

    // MARK: - Stats 风格 Label 竖排三字母 (S/E/N)
    private static func drawStatsVerticalLabel(in rect: NSRect, text: String, color: NSColor) {
        let chars = Array(text.uppercased().prefix(3))
        let font = NSFont.monospacedSystemFont(ofSize: 5.5, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let stepH = rect.height / CGFloat(max(1, chars.count))
        for (i, ch) in chars.enumerated() {
            let s = String(ch) as NSString
            let sz = s.size(withAttributes: attrs)
            let x = rect.minX + (rect.width - sz.width) / 2.0
            // flipped = false, top char is highest y
            let y = rect.maxY - CGFloat(i + 1) * stepH + (stepH - sz.height) / 2.0
            s.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
        }
    }

    // MARK: - Stats 风格 BatteryIcon 横向电池图标 (复刻 Kit/Widgets/BatteryWidget.swift)
    private static func drawStatsBatteryIcon(in rect: NSRect, ratio: Double, isCharging: Bool) {
        let bodyW = rect.width - 2.5
        let bodyRect = NSRect(x: rect.minX, y: rect.minY, width: bodyW, height: rect.height)
        let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 2.5, yRadius: 2.5)
        NSColor.labelColor.withAlphaComponent(0.85).setStroke()
        bodyPath.lineWidth = 1.0
        bodyPath.stroke()

        // 电池右侧正极凸起
        let nubH = max(3.5, rect.height * 0.42)
        let nubRect = NSRect(
            x: bodyRect.maxX + 0.8,
            y: rect.midY - nubH / 2.0,
            width: 1.6,
            height: nubH
        )
        NSColor.labelColor.withAlphaComponent(0.75).setFill()
        NSBezierPath(roundedRect: nubRect, xRadius: 0.8, yRadius: 0.8).fill()

        // 内部电量填充
        let pad: CGFloat = 1.8
        let maxFillW = max(1.0, bodyW - pad * 2)
        let norm = CGFloat(min(1.0, max(0.08, ratio)))
        let fillRect = NSRect(
            x: bodyRect.minX + pad,
            y: bodyRect.minY + pad,
            width: maxFillW * norm,
            height: max(2.0, bodyRect.height - pad * 2)
        )
        let fillColor: NSColor
        if isCharging {
            fillColor = .systemGreen
        } else if ratio < 0.20 {
            fillColor = .systemRed
        } else {
            fillColor = NSColor.labelColor.withAlphaComponent(0.90)
        }
        fillColor.setFill()
        NSBezierPath(roundedRect: fillRect, xRadius: 1.2, yRadius: 1.2).fill()
    }

    // MARK: - 构造每个令牌的绘制规格
    private static func makeSpec(
        for token: MenuBarTokenKind,
        snapshot: TelemetrySnapshot?,
        weather: WeatherSnapshot,
        cpuHistory: [Double]
    ) -> TokenDrawSpec {
        let config = MenuBarConfigStore.shared
        let colorMode = config.menuBarColorMode
        let (themePrimary, themeSecondary) = themeAccentNSColors()
        let labelDimColor = NSColor.labelColor.withAlphaComponent(0.66)
        let valuePrimaryColor = NSColor.labelColor
        let presetId = config.formatPreset(for: token).id

        switch token {
        case .weatherIconTemp:
            let tempVal = weather.currentTemp
            let tempStr: String
            if weather.isLoadedFromNetwork {
                if config.weatherTempUnit == "F" {
                    let f = (tempVal * 9.0 / 5.0) + 32.0
                    tempStr = String(format: "%.0f°F", f)
                } else {
                    tempStr = String(format: "%.0f°C", tempVal)
                }
            } else {
                tempStr = "--°"
            }
            let cityStr = String(weather.city.prefix(4))
            let bottom: String
            switch presetId {
            case "weather_temp_only":
                bottom = ""
            default:
                bottom = weather.localizedConditionText.isEmpty ? cityStr : String(weather.localizedConditionText.prefix(4))
            }
            let accent = resolveWidgetAccent(mode: colorMode, usageRatio: 0.2, classicColor: .systemCyan)
            return TokenDrawSpec(
                topText: tempStr,
                bottomText: bottom,
                topColor: valuePrimaryColor,
                bottomColor: colorMode == .monochrome ? labelDimColor : accent,
                isMiniLabelTop: false,
                graphic: .none
            )

        case .cpuStacked:
            let totalRatio = snapshot?.cpu.totalUsage ?? 0
            let pct = Int((totalRatio * 100.0).rounded())
            let userRatio = snapshot?.cpu.userUsage ?? (totalRatio * 0.65)
            let sysRatio = snapshot?.cpu.systemUsage ?? (totalRatio * 0.35)
            let valColor = resolveWidgetAccent(mode: colorMode, usageRatio: totalRatio, classicColor: valuePrimaryColor)
            let barData: [Double] = {
                if let cores = snapshot?.cpu.coreUsages, !cores.isEmpty {
                    return cores.map { $0 * 100.0 }
                }
                return cpuHistory
            }()

            switch presetId {
            case "cpu_mini":
                return TokenDrawSpec(
                    topText: "CPU",
                    bottomText: "\(pct)%",
                    topColor: labelDimColor,
                    bottomColor: colorMode == .utilization || totalRatio > 0.8 ? valColor : valuePrimaryColor,
                    isMiniLabelTop: true,
                    graphic: .none
                )
            case "cpu_line_chart":
                return TokenDrawSpec(
                    topText: "",
                    bottomText: "",
                    topColor: valuePrimaryColor,
                    bottomColor: labelDimColor,
                    graphic: .lineChartBox(cpuHistory, themePrimary)
                )
            case "cpu_bar_chart":
                return TokenDrawSpec(
                    topText: "",
                    bottomText: "",
                    topColor: valuePrimaryColor,
                    bottomColor: labelDimColor,
                    graphic: .barChartBox(totalRatio, themePrimary)
                )
            case "cpu_percent_only":
                return TokenDrawSpec(
                    topText: "\(pct)%",
                    bottomText: "",
                    topColor: colorMode == .utilization || totalRatio > 0.8 ? valColor : valuePrimaryColor,
                    bottomColor: labelDimColor
                )
            case "cpu_pie_chart":
                let seg1 = colorMode == .monochrome ? NSColor.labelColor : (colorMode == .classicMulti ? .systemRed : themeSecondary)
                let seg2 = colorMode == .monochrome ? NSColor.labelColor.withAlphaComponent(0.55) : (colorMode == .classicMulti ? .systemBlue : themePrimary)
                return TokenDrawSpec(
                    topText: "CPU",
                    bottomText: "\(pct)%",
                    topColor: labelDimColor,
                    bottomColor: colorMode == .utilization || totalRatio > 0.8 ? valColor : valuePrimaryColor,
                    isMiniLabelTop: true,
                    graphic: .pieRing([(sysRatio, seg1), (userRatio, seg2)])
                )
            case "cpu_user_sys":
                let u = Int((userRatio * 100.0).rounded())
                let s = Int((sysRatio * 100.0).rounded())
                return TokenDrawSpec(
                    topText: "U:\(u)%",
                    bottomText: "S:\(s)%",
                    topColor: colorMode == .monochrome ? valuePrimaryColor : themePrimary,
                    bottomColor: colorMode == .monochrome ? labelDimColor : themeSecondary
                )
            case "cpu_sparkline":
                return TokenDrawSpec(
                    topText: "CPU",
                    bottomText: "\(pct)%",
                    topColor: labelDimColor,
                    bottomColor: colorMode == .utilization || totalRatio > 0.8 ? valColor : valuePrimaryColor,
                    isMiniLabelTop: true,
                    graphic: .lineAndBarBox(cpuHistory, totalRatio, themePrimary)
                )
            default:
                // Stats Mini + BarChart 默认样式
                return TokenDrawSpec(
                    topText: "CPU",
                    bottomText: "\(pct)%",
                    topColor: labelDimColor,
                    bottomColor: colorMode == .utilization || totalRatio > 0.8 ? valColor : valuePrimaryColor,
                    isMiniLabelTop: true,
                    graphic: config.cpuShowSparkline ? .barChart(barData) : .none
                )
            }

        case .gpuStacked:
            let pct = Int((snapshot?.gpu.usagePercent ?? 0).rounded())
            let ratio = Double(pct) / 100.0
            let valColor = resolveWidgetAccent(mode: colorMode, usageRatio: ratio, classicColor: valuePrimaryColor)
            switch presetId {
            case "gpu_line_chart":
                return TokenDrawSpec(
                    topText: "",
                    bottomText: "",
                    topColor: valuePrimaryColor,
                    bottomColor: labelDimColor,
                    graphic: .lineChartBox([Double(pct)], themePrimary)
                )
            case "gpu_bar_chart":
                return TokenDrawSpec(
                    topText: "",
                    bottomText: "",
                    topColor: valuePrimaryColor,
                    bottomColor: labelDimColor,
                    graphic: .barChartBox(ratio, themePrimary)
                )
            case "gpu_percent_only":
                return TokenDrawSpec(topText: "\(pct)%", bottomText: "", topColor: valColor, bottomColor: labelDimColor)
            case "gpu_with_temp":
                let tempStr: String
                if let t = snapshot?.gpu.temperature, t > 0 {
                    tempStr = config.sensorTempUnit == "F" ? "\(Int((Double(t) * 9.0 / 5.0 + 32.0).rounded()))°F" : "\(t)°C"
                } else {
                    tempStr = "GPU"
                }
                return TokenDrawSpec(topText: "\(pct)%", bottomText: tempStr, topColor: valuePrimaryColor, bottomColor: labelDimColor)
            default:
                return TokenDrawSpec(
                    topText: "GPU",
                    bottomText: "\(pct)%",
                    topColor: labelDimColor,
                    bottomColor: colorMode == .utilization ? valColor : valuePrimaryColor,
                    isMiniLabelTop: true
                )
            }

        case .memoryStacked:
            let ratio = snapshot?.memory.usedRatio ?? 0
            let pct = Int((ratio * 100.0).rounded())
            let gib = 1_073_741_824.0
            let valColor = resolveWidgetAccent(mode: colorMode, usageRatio: ratio, classicColor: valuePrimaryColor)

            switch presetId {
            case "mem_bar_chart":
                return TokenDrawSpec(
                    topText: "",
                    bottomText: "",
                    topColor: valuePrimaryColor,
                    bottomColor: labelDimColor,
                    graphic: .barChartBox(ratio, themePrimary)
                )
            case "mem_line_chart":
                return TokenDrawSpec(
                    topText: "",
                    bottomText: "",
                    topColor: valuePrimaryColor,
                    bottomColor: labelDimColor,
                    graphic: .lineChartBox([Double(pct)], themePrimary)
                )
            case "mem_percent_only":
                return TokenDrawSpec(topText: "\(pct)%", bottomText: "", topColor: valuePrimaryColor, bottomColor: labelDimColor)
            case "mem_free_only":
                let freeG = Double(snapshot?.memory.freeBytes ?? 0) / gib
                return TokenDrawSpec(topText: String(format: "%.1fG", freeG), bottomText: "", topColor: valuePrimaryColor, bottomColor: labelDimColor)
            case "mem_pie_chart":
                let total = Double(max(1, snapshot?.memory.totalBytes ?? 1))
                let appR = Double(snapshot?.memory.appBytes ?? 0) / total
                let wiredR = Double(snapshot?.memory.wiredBytes ?? 0) / total
                let compR = Double(snapshot?.memory.compressedBytes ?? 0) / total
                let c1 = colorMode == .monochrome ? NSColor.labelColor : (colorMode == .classicMulti ? .systemBlue : themePrimary)
                let c2 = colorMode == .monochrome ? NSColor.labelColor.withAlphaComponent(0.65) : (colorMode == .classicMulti ? .systemOrange : themeSecondary)
                let c3 = colorMode == .monochrome ? NSColor.labelColor.withAlphaComponent(0.4) : .systemPink
                return TokenDrawSpec(
                    topText: "RAM",
                    bottomText: "\(pct)%",
                    topColor: labelDimColor,
                    bottomColor: snapshot?.memory.pressureLevel == .critical ? .systemRed : valuePrimaryColor,
                    isMiniLabelTop: true,
                    graphic: .pieRing([(appR, c1), (wiredR, c2), (compR, c3)])
                )
            case "mem_percent_pressure":
                return TokenDrawSpec(
                    topText: "RAM",
                    bottomText: "\(pct)%",
                    topColor: labelDimColor,
                    bottomColor: snapshot?.memory.pressureLevel == .critical ? .systemRed : (colorMode == .utilization ? valColor : valuePrimaryColor),
                    isMiniLabelTop: true
                )
            default:
                return TokenDrawSpec(
                    topText: "RAM",
                    bottomText: "\(pct)%",
                    topColor: labelDimColor,
                    bottomColor: snapshot?.memory.pressureLevel == .critical ? .systemRed : (colorMode == .utilization ? valColor : valuePrimaryColor),
                    isMiniLabelTop: true
                )
            }

        case .diskFreeStacked:
            let freeGB = Int((Double(snapshot?.storage?.free ?? 0) / 1_000_000_000.0).rounded())
            let usedRatio = snapshot?.storage?.usedRatio ?? 0
            let usedPct = Int((usedRatio * 100.0).rounded())
            switch presetId {
            case "disk_mini_pct":
                return TokenDrawSpec(
                    topText: "SSD",
                    bottomText: "\(usedPct)%",
                    topColor: labelDimColor,
                    bottomColor: valuePrimaryColor,
                    isMiniLabelTop: true
                )
            case "disk_bar_chart":
                return TokenDrawSpec(
                    topText: "",
                    bottomText: "",
                    topColor: valuePrimaryColor,
                    bottomColor: labelDimColor,
                    graphic: .barChartBox(usedRatio, themePrimary)
                )
            case "disk_free_size":
                return TokenDrawSpec(topText: "\(freeGB)G", bottomText: "", topColor: valuePrimaryColor, bottomColor: labelDimColor)
            case "disk_percent":
                return TokenDrawSpec(topText: "\(usedPct)%", bottomText: "", topColor: valuePrimaryColor, bottomColor: labelDimColor)
            case "disk_io_speed":
                return TokenDrawSpec(
                    topText: compactRate(snapshot?.diskIO.readBytesPerSec ?? 0, prefix: "R:"),
                    bottomText: compactRate(snapshot?.diskIO.writeBytesPerSec ?? 0, prefix: "W:"),
                    topColor: valuePrimaryColor,
                    bottomColor: labelDimColor
                )
            default:
                return TokenDrawSpec(
                    topText: "DSK",
                    bottomText: "\(freeGB)G",
                    topColor: labelDimColor,
                    bottomColor: valuePrimaryColor,
                    isMiniLabelTop: true
                )
            }

        case .networkStacked:
            let upBytes = snapshot?.network.uploadBytesPerSec ?? 0
            let downBytes = snapshot?.network.downloadBytesPerSec ?? 0
            let upColor: NSColor = {
                switch colorMode {
                case .monochrome: return NSColor.labelColor
                case .classicMulti: return NSColor.systemRed
                case .themeAccent, .utilization: return themeSecondary
                }
            }()
            let downColor: NSColor = {
                switch colorMode {
                case .monochrome: return NSColor.labelColor
                case .classicMulti: return NSColor.systemBlue
                case .themeAccent, .utilization: return themePrimary
                }
            }()

            switch presetId {
            case "net_down_only":
                return TokenDrawSpec(topText: compactRate(downBytes, prefix: "↓"), bottomText: "", topColor: valuePrimaryColor, bottomColor: labelDimColor)
            case "net_up_only":
                return TokenDrawSpec(topText: compactRate(upBytes, prefix: "↑"), bottomText: "", topColor: valuePrimaryColor, bottomColor: labelDimColor)
            case "net_total":
                return TokenDrawSpec(topText: compactRate(upBytes + downBytes, prefix: ""), bottomText: "", topColor: valuePrimaryColor, bottomColor: labelDimColor)
            default:
                // Stats SpeedWidget 风格：左侧圆点 + 右对齐速率
                return TokenDrawSpec(
                    topText: "\(compactRate(upBytes, prefix: ""))/s",
                    bottomText: "\(compactRate(downBytes, prefix: ""))/s",
                    topColor: valuePrimaryColor,
                    bottomColor: valuePrimaryColor,
                    isMiniLabelTop: false,
                    graphic: .speedDots(
                        upActive: upBytes >= 1024,
                        downActive: downBytes >= 1024,
                        upColor: upColor,
                        downColor: downColor
                    )
                )
            }

        case .sensorTempStacked:
            let rawC = snapshot?.cpu.temperature
            let tempText: String
            if let c = rawC {
                if config.sensorTempUnit == "F" {
                    let f = Int(((Double(c) * 9.0 / 5.0) + 32.0).rounded())
                    tempText = "\(f)°F"
                } else {
                    tempText = "\(c)°C"
                }
            } else {
                tempText = "--°"
            }

            switch presetId {
            case "sensor_label_vertical":
                return TokenDrawSpec(
                    topText: "",
                    bottomText: "",
                    topColor: valuePrimaryColor,
                    bottomColor: labelDimColor,
                    graphic: .verticalLabel("SEN")
                )
            case "sensor_temp_only":
                return TokenDrawSpec(topText: tempText, bottomText: "", topColor: valuePrimaryColor, bottomColor: labelDimColor)
            case "sensor_with_power":
                let w = snapshot?.powerBus?.totalWatts ?? snapshot?.cpu.powerWatts ?? 0.0
                let sub = w > 0.1 ? String(format: "%.0fW", w) : "PWR"
                return TokenDrawSpec(topText: tempText, bottomText: sub, topColor: valuePrimaryColor, bottomColor: labelDimColor)
            default:
                if let fan = snapshot?.fan, fan.hasFans, fan.rpm > 0 {
                    return TokenDrawSpec(topText: tempText, bottomText: "\(fan.rpm)R", topColor: valuePrimaryColor, bottomColor: labelDimColor)
                }
                return TokenDrawSpec(
                    topText: "TMP",
                    bottomText: tempText,
                    topColor: labelDimColor,
                    bottomColor: (rawC ?? 0) > 82 ? .systemOrange : valuePrimaryColor,
                    isMiniLabelTop: true
                )
            }

        case .batteryStacked:
            let pct = snapshot?.battery?.percentage ?? 100
            let watts = snapshot?.battery?.powerWatts ?? 0.0
            let isCharging = snapshot?.battery?.isCharging ?? false
            switch presetId {
            case "bat_icon_only":
                return TokenDrawSpec(
                    topText: "",
                    bottomText: "",
                    topColor: valuePrimaryColor,
                    bottomColor: labelDimColor,
                    graphic: .batteryIcon(Double(pct) / 100.0, isCharging)
                )
            case "bat_percent_only":
                return TokenDrawSpec(topText: "\(pct)%", bottomText: "", topColor: valuePrimaryColor, bottomColor: labelDimColor)
            case "bat_standard":
                let bottom = watts > 0.1 ? String(format: "%.1fW", watts) : "BAT"
                return TokenDrawSpec(topText: "\(pct)%", bottomText: bottom, topColor: valuePrimaryColor, bottomColor: labelDimColor)
            default:
                return TokenDrawSpec(
                    topText: "BAT",
                    bottomText: "\(pct)%",
                    topColor: labelDimColor,
                    bottomColor: pct < 20 ? .systemRed : valuePrimaryColor,
                    isMiniLabelTop: true
                )
            }

        case .clockStacked:
            let now = Date()
            let dfTop = DateFormatter()
            dfTop.locale = Locale.current
            dfTop.dateFormat = config.clockShowDayOfWeek ? "E" : "MM/dd"

            let dfBot = DateFormatter()
            let showSec = config.clockShowSeconds || presetId == "clock_with_seconds"
            if config.clockUse24Hour {
                dfBot.dateFormat = showSec ? "HH:mm:ss" : "HH:mm"
            } else {
                dfBot.dateFormat = showSec ? "h:mm:ss a" : "h:mm a"
            }
            if presetId == "clock_time_only" {
                return TokenDrawSpec(
                    topText: dfBot.string(from: now),
                    bottomText: "",
                    topColor: valuePrimaryColor,
                    bottomColor: labelDimColor
                )
            }
            return TokenDrawSpec(
                topText: dfTop.string(from: now),
                bottomText: dfBot.string(from: now),
                topColor: labelDimColor,
                bottomColor: valuePrimaryColor,
                isMiniLabelTop: true
            )
        }
    }

    private static func compactRate(_ bytesPerSec: Double, prefix: String) -> String {
        if bytesPerSec >= 1024 * 1024 {
            return String(format: "%@%.1fM", prefix, bytesPerSec / (1024 * 1024))
        } else if bytesPerSec >= 1024 {
            return String(format: "%@%.0fK", prefix, bytesPerSec / 1024)
        } else {
            return "\(prefix)0K"
        }
    }
}
