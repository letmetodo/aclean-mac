import AppKit
import QuartzCore
import SwiftUI

// ============================================================
//  CleanMyLiveBackground —— 1:1 逆向还原原版动态极光网格引擎
//
//  基于 CleanMyLiveBackground.framework 符号与汇编逆向：
//  1. 采用 CALayer + 3 个 CAGradientLayer(type: .radial)
//  2. 16 级指数衰减 Alpha 梯阶（彻底杜绝颜色断层与条带）:
//     [1.0, 0.99, 0.96, 0.92, 0.85, 0.77, 0.67, 0.56, 0.44, 0.33, 0.23, 0.15, 0.08, 0.04, 0.01, 0.0]
//  3. 精确 AnchorPoint / GradientCenter / Scale 几何定位：
//     Layer 0: anchor(1.0324, 0.5), center(-0.1389, 0.5), scale(1.2, 2.1)
//     Layer 1: anchor(0.9933, 0.5), center(0.00664, 0.5), scale(1.0, 1.7)
//     Layer 2: anchor(0.8125, 0.5), center(0.0, 0.5), scale(1.6, 1.6)
//  4. 20.0 秒无限连续旋转 CoreAnimation: "transform.rotation.z"
//  5. 各模块专属的 sRGB 原版四元色彩向量（3 组渐变色 + 1 组底色）
// ============================================================

struct LiveBackgroundPalette {
    let colors: [NSColor]
    let backgroundColor: NSColor

    init(colors: [NSColor], backgroundColor: NSColor) {
        self.colors = colors
        self.backgroundColor = backgroundColor
    }

    /// 智能呵护: 宝石粉紫
    static let smartCare = LiveBackgroundPalette(
        colors: [
            NSColor(srgbRed: 0.31, green: 0.00, blue: 0.22, alpha: 0.50),
            NSColor(srgbRed: 0.83, green: 0.00, blue: 0.91, alpha: 0.50),
            NSColor(srgbRed: 1.00, green: 0.33, blue: 0.97, alpha: 0.50)
        ],
        backgroundColor: NSColor(srgbRed: 0.36, green: 0.00, blue: 0.15, alpha: 1.0)
    )

    /// 垃圾清理: 经典深海蓝
    static let junk = LiveBackgroundPalette(
        colors: [
            NSColor(srgbRed: 0.00, green: 0.04, blue: 0.24, alpha: 0.50),
            NSColor(srgbRed: 0.50, green: 0.03, blue: 0.87, alpha: 0.50),
            NSColor(srgbRed: 0.14, green: 0.43, blue: 1.00, alpha: 0.50)
        ],
        backgroundColor: NSColor(srgbRed: 0.00, green: 0.153, blue: 0.380, alpha: 1.0)
    )

    /// 应用管理: 湖蓝紫罗兰
    static let applications = LiveBackgroundPalette(
        colors: [
            NSColor(srgbRed: 0.31, green: 0.00, blue: 0.22, alpha: 0.50),
            NSColor(srgbRed: 0.73, green: 0.00, blue: 0.99, alpha: 0.50),
            NSColor(srgbRed: 0.93, green: 0.00, blue: 1.00, alpha: 0.50)
        ],
        backgroundColor: NSColor(srgbRed: 0.035, green: 0.00, blue: 0.282, alpha: 1.0)
    )

    /// 空间透镜: 暗夜荧光紫
    static let spaceLens = LiveBackgroundPalette(
        colors: [
            NSColor(srgbRed: 0.0706, green: 0.00, blue: 0.1843, alpha: 0.50),
            NSColor(srgbRed: 0.3804, green: 0.00, blue: 0.7608, alpha: 0.50),
            NSColor(srgbRed: 0.4941, green: 0.0431, blue: 1.00, alpha: 0.50)
        ],
        backgroundColor: NSColor(srgbRed: 0.07, green: 0.04, blue: 0.00, alpha: 1.0)
    )

    /// 性能优化: 极光翠绿
    static let performance = LiveBackgroundPalette(
        colors: [
            NSColor(srgbRed: 0.00, green: 0.11, blue: 0.07, alpha: 0.50),
            NSColor(srgbRed: 0.00, green: 0.60, blue: 0.07, alpha: 0.50),
            NSColor(srgbRed: 0.52, green: 0.76, blue: 0.00, alpha: 0.50)
        ],
        backgroundColor: NSColor(srgbRed: 0.00, green: 0.18, blue: 0.04, alpha: 1.0)
    )

    /// 整理杂乱: 青碧游离
    static let clutter = LiveBackgroundPalette(
        colors: [
            NSColor(srgbRed: 0.00, green: 0.18, blue: 0.17, alpha: 0.50),
            NSColor(srgbRed: 0.00, green: 0.62, blue: 0.76, alpha: 0.50),
            NSColor(srgbRed: 0.00, green: 0.79, blue: 0.75, alpha: 0.50)
        ],
        backgroundColor: NSColor(srgbRed: 0.00, green: 0.29, blue: 0.28, alpha: 1.0)
    )

    /// 智能助手: 靛蓝星云
    static let assistant = LiveBackgroundPalette(
        colors: [
            NSColor(srgbRed: 0.16, green: 0.14, blue: 0.41, alpha: 0.50),
            NSColor(srgbRed: 0.35, green: 0.34, blue: 0.64, alpha: 0.50),
            NSColor(srgbRed: 0.28, green: 0.28, blue: 0.49, alpha: 0.50)
        ],
        backgroundColor: NSColor(srgbRed: 0.09, green: 0.06, blue: 0.18, alpha: 1.0)
    )

    /// 我的工具: 幻境紫罗兰
    static let toolbox = LiveBackgroundPalette(
        colors: [
            NSColor(srgbRed: 0.28, green: 0.05, blue: 0.38, alpha: 0.50),
            NSColor(srgbRed: 0.58, green: 0.12, blue: 0.88, alpha: 0.50),
            NSColor(srgbRed: 0.78, green: 0.35, blue: 1.00, alpha: 0.50)
        ],
        backgroundColor: NSColor(srgbRed: 0.12, green: 0.02, blue: 0.22, alpha: 1.0)
    )

    /// 设置面板: 沉静冷灰
    static let settings = LiveBackgroundPalette(
        colors: [
            NSColor(srgbRed: 0.309, green: 0.00, blue: 0.223, alpha: 0.19),
            NSColor(srgbRed: 0.176, green: 0.921, blue: 0.698, alpha: 0.25),
            NSColor(srgbRed: 1.00, green: 0.529, blue: 0.329, alpha: 0.32)
        ],
        backgroundColor: NSColor(srgbRed: 0.365, green: 0.408, blue: 0.431, alpha: 1.0)
    )

    static func palette(for moduleKey: String) -> LiveBackgroundPalette {
        switch moduleKey {
        case "healthCheck":  return .smartCare
        case "smartCare":    return .smartCare
        case "junk":         return .junk
        case "applications": return .applications
        case "spaceLens":    return .spaceLens
        case "performance":  return .performance
        case "organize":     return .clutter
        case "toolbox":      return .toolbox
        case "assistant":    return .assistant
        case "settings":     return .settings
        default:             return .junk
        }
    }
}

// MARK: - 原生 NSView: LiveBackgroundNSView

final class LiveBackgroundNSView: NSView {
    private let containerLayer = CALayer()
    private let backgroundColorLayer = CALayer()
    private var gradientLayers: [CAGradientLayer] = []

    // 16 级衰减阶梯
    private let alphaSteps: [CGFloat] = [
        1.0, 0.99, 0.96, 0.92, 0.85, 0.77, 0.67, 0.56,
        0.44, 0.33, 0.23, 0.15, 0.08, 0.04, 0.01, 0.0
    ]

    // 逆向自原版 3 层几何常数
    private let anchorPoints: [CGPoint] = [
        CGPoint(x: 1.0324, y: 0.5),
        CGPoint(x: 0.9933, y: 0.5),
        CGPoint(x: 0.8125, y: 0.5)
    ]

    private let gradientCenters: [CGPoint] = [
        CGPoint(x: -0.1389, y: 0.5),
        CGPoint(x: 0.00664, y: 0.5),
        CGPoint(x: 0.0, y: 0.5)
    ]

    private let gradientScales: [CGSize] = [
        CGSize(width: 1.2, height: 2.1),
        CGSize(width: 1.0, height: 1.7),
        CGSize(width: 1.6, height: 1.6)
    ]

    private let initialAngles: [CGFloat] = [
        0.0,
        CGFloat.pi * 0.45,
        CGFloat.pi * 1.15
    ]

    var palette: LiveBackgroundPalette = .junk {
        didSet { updateColors(animated: true) }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonSetup()
    }

    private func commonSetup() {
        wantsLayer = true
        guard let layer = self.layer else { return }

        // 禁用隐式 CATransaction 动画避免缩放残影
        var actions = [String: CAAction]()
        actions[kCAOnOrderIn] = NSNull()
        actions[kCAOnOrderOut] = NSNull()
        actions["sublayers"] = NSNull()
        actions["contents"] = NSNull()
        actions["bounds"] = NSNull()
        actions["position"] = NSNull()
        actions["frame"] = NSNull()
        containerLayer.actions = actions
        backgroundColorLayer.actions = actions

        layer.addSublayer(containerLayer)
        containerLayer.addSublayer(backgroundColorLayer)

        // 创建 3 层 CAGradientLayer
        for i in 0..<3 {
            let gl = CAGradientLayer()
            gl.type = .radial
            gl.startPoint = CGPoint(x: 0.5, y: 0.5)
            gl.endPoint = CGPoint(x: 1.0, y: 1.0)
            gl.anchorPoint = anchorPoints[i]
            gl.actions = actions
            gradientLayers.append(gl)
            containerLayer.addSublayer(gl)
        }

        updateColors(animated: false)
        startContinuousRotations()
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let b = bounds
        containerLayer.frame = b
        backgroundColorLayer.frame = b

        let maxDim = max(b.width, b.height)
        for (i, gl) in gradientLayers.enumerated() {
            let scale = gradientScales[i]
            let w = maxDim * scale.width
            let h = maxDim * scale.height
            gl.bounds = CGRect(x: 0, y: 0, width: w, height: h)

            let center = gradientCenters[i]
            gl.position = CGPoint(x: b.width * center.x + b.width * 0.5,
                                  y: b.height * center.y + b.height * 0.5)
        }

        CATransaction.commit()
    }

    private func makeGradientColors(from baseColor: NSColor) -> [CGColor] {
        guard let srgb = baseColor.usingColorSpace(.sRGB) else {
            return [baseColor.cgColor]
        }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        srgb.getRed(&r, green: &g, blue: &b, alpha: &a)

        return alphaSteps.map { step in
            NSColor(srgbRed: r, green: g, blue: b, alpha: a * step).cgColor
        }
    }

    private func updateColors(animated: Bool) {
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.6
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.backgroundColorLayer.backgroundColor = self.palette.backgroundColor.cgColor
                for (i, gl) in self.gradientLayers.enumerated() {
                    let base = i < self.palette.colors.count ? self.palette.colors[i] : self.palette.colors[0]
                    gl.colors = self.makeGradientColors(from: base)
                }
            }
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.backgroundColorLayer.backgroundColor = self.palette.backgroundColor.cgColor
            for (i, gl) in self.gradientLayers.enumerated() {
                let base = i < self.palette.colors.count ? self.palette.colors[i] : self.palette.colors[0]
                gl.colors = self.makeGradientColors(from: base)
            }
            CATransaction.commit()
        }
    }

    private func startContinuousRotations() {
        for (i, gl) in gradientLayers.enumerated() {
            gl.removeAnimation(forKey: "rotationAnimation")

            let anim = CABasicAnimation(keyPath: "transform.rotation.z")
            let start = initialAngles[i]
            anim.fromValue = start
            anim.toValue = start + (i % 2 == 0 ? 2 * CGFloat.pi : -2 * CGFloat.pi)
            // 20s 周期，层间微差产生复杂复合流动
            anim.duration = 20.0 + Double(i) * 3.5
            anim.repeatCount = .infinity
            anim.isRemovedOnCompletion = false
            anim.timingFunction = CAMediaTimingFunction(name: .linear)
            gl.add(anim, forKey: "rotationAnimation")
        }
    }
}

// MARK: - SwiftUI 桥接: LiveBackgroundView

struct LiveBackgroundView: NSViewRepresentable {
    var moduleKey: String

    init(moduleKey: String) {
        self.moduleKey = moduleKey
    }

    func makeNSView(context: Context) -> LiveBackgroundNSView {
        let v = LiveBackgroundNSView()
        v.palette = LiveBackgroundPalette.palette(for: moduleKey)
        return v
    }

    func updateNSView(_ nsView: LiveBackgroundNSView, context: Context) {
        let target = LiveBackgroundPalette.palette(for: moduleKey)
        nsView.palette = target
    }
}
