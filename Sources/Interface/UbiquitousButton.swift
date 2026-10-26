import AppKit
import SwiftUI

// ============================================================
//  UbiquitousButton —— 1:1 逆向还原原版全局浮动操作按钮
//
//  基于 UbiquitousButtonUI.framework 逆向：
//  - windowSize: 256.0 pt（外围辉光与光子扩散区）
//  - buttonSize: 96.0 pt（核心可点击操作圆盘）
//  - bottomOffset: -112.0 pt（浮动悬停于窗口下边缘）
//  - Aurora.ring 脉冲光环（原版实测鲜艳度最强区）+ 呼吸柔光晕
//  - 扫描/清理状态：同轴动态 CoreGraphics 轨道波、进度百分比、粒子旋转
//  - 按下弹簧回弹物理手感与悬停提亮
// ============================================================

enum UbiquitousButtonMode: Equatable {
    case idle(title: String, subtitle: String? = nil)
    case scanning(progress: Double, count: Int? = nil)
    case cleaning(progress: Double, done: Int, total: Int)
    case stop(title: String)
    case disabled(title: String)
}

struct UbiquitousButton: View {
    var mode: UbiquitousButtonMode
    var hue: Double
    var size: CGFloat = 96
    var action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var pulseWave = false
    @State private var glowBreath = false
    @State private var orbitalRotation: Double = 0

    init(mode: UbiquitousButtonMode, hue: Double, size: CGFloat = 96, action: @escaping () -> Void) {
        self.mode = mode
        self.hue = hue
        self.size = size
        self.action = action
    }

    init(title: String, subtitle: String? = nil, hue: Double, size: CGFloat = 96, action: @escaping () -> Void) {
        self.mode = .idle(title: title, subtitle: subtitle)
        self.hue = hue
        self.size = size
        self.action = action
    }

    private var ringColor: Color {
        Aurora.ring(hue)
    }

    private var accentColor: Color {
        Aurora.accent(hue)
    }

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            action()
        }) {
            ZStack {
                // 1. 最外层 256pt 柔光扩散场（对应原版 UbiquitousButtonWindowBackground）
                Circle()
                    .fill(RadialGradient(
                        colors: [
                            ringColor.opacity(glowBreath ? 0.40 : 0.22),
                            ringColor.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.4,
                        endRadius: size * 1.35
                    ))
                    .frame(width: size * 2.66, height: size * 2.66)
                    .allowsHitTesting(false)

                // 2. 连续向外扩散的脉冲能量环 (Aurora Pulse Ring)
                if case .idle = mode {
                    Circle()
                        .stroke(ringColor.opacity(0.65), lineWidth: 1.5)
                        .scaleEffect(pulseWave ? 1.75 : 1.0)
                        .opacity(pulseWave ? 0.0 : 0.85)
                        .frame(width: size, height: size)
                        .allowsHitTesting(false)
                }

                // 3. 贴身呼吸辉光晕 (Tight Aurora Halo)
                Circle()
                    .fill(RadialGradient(
                        colors: [ringColor.opacity(glowBreath ? 0.85 : 0.50), Color.clear],
                        center: .center,
                        startRadius: size * 0.35,
                        endRadius: size * 0.72
                    ))
                    .frame(width: size * 1.45, height: size * 1.45)
                    .allowsHitTesting(false)

                // 4. 扫描/清理状态下的旋转轨道环 (Orbital Scan Ring)
                if case .scanning(let p, _) = mode {
                    progressRing(progress: p)
                } else if case .cleaning(let p, _, _) = mode {
                    progressRing(progress: p)
                }

                // 5. 核心操作圆盘 (96pt Core Button Disc)
                ZStack {
                    // 圆盘底色渐变
                    Circle()
                        .fill(LinearGradient(
                            colors: [
                                Aurora.hsv(hue - 16, 0.72, 0.95),
                                ringColor,
                                Aurora.hsv(hue + 10, 0.82, 0.70)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))

                    // 内部液态玻璃高光
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.white.opacity(0.45), Color.clear],
                            center: UnitPoint(x: 0.35, y: 0.25),
                            startRadius: 0,
                            endRadius: size * 0.5
                        ))

                    // 浅色双层描边 (Glass Border Rings)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.65), lineWidth: 1.5)
                    Circle()
                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 3.5)
                        .padding(3.5)

                    // 按钮文字排版
                    buttonContent
                }
                .frame(width: size, height: size)
                .shadow(color: ringColor.opacity(glowBreath ? 0.70 : 0.40),
                        radius: glowBreath ? 22 : 12, y: 4)
                .scaleEffect(isHovered ? 1.04 : 1.0)
                .animation(.easeOut(duration: 0.2), value: isHovered)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(SpringPressButtonStyle())
        .disabled(!isEnabled)
        .onHover { isHovered = $0 }
        .onAppear {
            startAnimations()
        }
    }

    private var isEnabled: Bool {
        if case .disabled = mode { return false }
        return true
    }

    @ViewBuilder
    private var buttonContent: some View {
        switch mode {
        case .idle(let title, let subtitle):
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: subtitle == nil ? 15 : 14, weight: .bold))
                    .foregroundStyle(Aurora.hsv(hue + 6, 0.65, 0.15))

                if let sub = subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Aurora.hsv(hue + 6, 0.65, 0.25))
                        .monospacedDigit()
                }
            }

        case .scanning(let p, _):
            VStack(spacing: 2) {
                Text(L10n.localized(.scanning))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Aurora.hsv(hue + 6, 0.65, 0.15))
                Text("\(Int(p * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Aurora.hsv(hue + 6, 0.65, 0.15))
                    .monospacedDigit()
            }

        case .cleaning(_, let done, let total):
            VStack(spacing: 2) {
                Text(L10n.localized(.cleaning))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Aurora.hsv(hue + 6, 0.65, 0.15))
                Text("\(done)/\(total)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Aurora.hsv(hue + 6, 0.65, 0.20))
                    .monospacedDigit()
            }

        case .stop(let title):
            VStack(spacing: 2) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }

        case .disabled(let title):
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.45))
        }
    }

    @ViewBuilder
    private func progressRing(progress: Double) -> some View {
        ZStack {
            // 背景轨道
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 4)
                .frame(width: size + 16, height: size + 16)

            // 进度条
            Circle()
                .trim(from: 0, to: max(0.01, min(1.0, progress)))
                .stroke(
                    AngularGradient(
                        colors: [Color.white, ringColor, Color.white],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: size + 16, height: size + 16)
                .animation(.linear(duration: 0.2), value: progress)

            // 旋转光子轨道
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [Color.clear, ringColor.opacity(0.8), Color.white],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [4, 8])
                )
                .frame(width: size + 28, height: size + 28)
                .rotationEffect(.degrees(orbitalRotation))
        }
    }

    private func startAnimations() {
        withAnimation(.easeOut(duration: 2.6).repeatForever(autoreverses: false)) {
            pulseWave = true
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowBreath = true
        }
        withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
            orbitalRotation = 360
        }
    }
}

struct SpringPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// 辅助视图：原生模糊效果
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
