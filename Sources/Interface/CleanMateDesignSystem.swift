import SwiftUI
import AppKit

// ============================================================
//  CleanMateDesignSystem.swift —— 高级设计底座 (CleanMate Design System)
//
//  三大核心视觉组件与材质基础：
//    1. GlassBentoCardModifier / .glassBentoCard(...) —— 受光玻璃卡片
//    2. GradientIconBadge —— 专属渐变图标底座
//    3. GlowingPillButton —— 弥散光胶囊主行动按钮
//    4. SidebarVisualEffectView —— macOS 原生毛玻璃侧栏材质
//    5. AmbientGlowBackground —— #0B0F19 底层与主题跟随环境光晕
// ============================================================

// MARK: - 1. 原生毛玻璃背景 (NSVisualEffectView Representable)

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    var state: NSVisualEffectView.State
    var cornerRadius: CGFloat

    init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .followsWindowActiveState,
        cornerRadius: CGFloat = 0
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
        self.cornerRadius = cornerRadius
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        if cornerRadius > 0 {
            view.wantsLayer = true
            view.layer?.cornerRadius = cornerRadius
            view.layer?.cornerCurve = .continuous
            view.layer?.masksToBounds = true
        }
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
        if cornerRadius > 0 {
            nsView.wantsLayer = true
            nsView.layer?.cornerRadius = cornerRadius
            nsView.layer?.cornerCurve = .continuous
            nsView.layer?.masksToBounds = true
        }
    }
}

// MARK: - 2. 受光玻璃 Bento 卡片 (Glass Bento Card)

struct GlassBentoCardModifier: ViewModifier {
    @ObservedObject var config = AppConfigStore.shared
    var cornerRadius: CGFloat
    var isHighlighted: Bool
    var isHovered: Bool
    var padding: CGFloat

    init(
        cornerRadius: CGFloat = 14,
        isHighlighted: Bool = false,
        isHovered: Bool = false,
        padding: CGFloat = 14
    ) {
        self.cornerRadius = cornerRadius
        self.isHighlighted = isHighlighted
        self.isHovered = isHovered
        self.padding = padding
    }

    func body(content: Content) -> some View {
        let isDark = Theme.isDark
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .padding(padding)
            .background {
                ZStack {
                    shape.fill(
                        isDark
                            ? (isHovered ? Theme.cardElevated : Theme.card)
                            : Color.white
                    )

                    if isHighlighted {
                        shape.fill(Theme.accent.opacity(isDark ? 0.12 : 0.06))
                    }
                }
            }
            .overlay {
                shape.strokeBorder(
                    isHighlighted
                        ? Theme.accent.opacity(isDark ? 0.55 : 0.45)
                        : (isDark
                            ? Color.white.opacity(isHovered ? 0.12 : 0.075)
                            : Color.black.opacity(isHovered ? 0.10 : 0.06)),
                    lineWidth: 1
                )
            }
            .shadow(
                color: Color.black.opacity(isDark
                    ? (isHovered ? 0.22 : 0.14)
                    : (isHovered ? 0.05 : 0.025)),
                radius: isHovered ? 6 : 3,
                x: 0,
                y: isHovered ? 2 : 1
            )
            .animation(.easeOut(duration: 0.16), value: isHovered)
            .animation(.easeOut(duration: 0.16), value: isHighlighted)
    }
}

extension View {
    func glassBentoCard(
        cornerRadius: CGFloat = 12,
        isHighlighted: Bool = false,
        isHovered: Bool = false,
        padding: CGFloat = 14
    ) -> some View {
        self.modifier(GlassBentoCardModifier(
            cornerRadius: cornerRadius,
            isHighlighted: isHighlighted,
            isHovered: isHovered,
            padding: padding
        ))
    }
}

// MARK: - 3. 专属渐变图标底座 (macOS System Settings 风格 Squircle)

struct GradientIconBadge: View {
    var icon: String
    var size: CGFloat
    var colors: [Color]
    var iconColor: Color
    var cornerRadius: CGFloat
    var glow: Bool

    init(
        icon: String,
        size: CGFloat = 24,
        colors: [Color] = [Theme.accent, Theme.accent2],
        iconColor: Color = .white,
        cornerRadius: CGFloat? = nil,
        glow: Bool = false
    ) {
        self.icon = icon
        self.size = size
        self.colors = colors
        self.iconColor = iconColor
        self.cornerRadius = cornerRadius ?? (size * 0.235)
        self.glow = glow
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            shape
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            shape
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)

            Image(systemName: icon)
                .font(.system(size: size * 0.50, weight: .semibold))
                .foregroundStyle(iconColor)
        }
        .frame(width: size, height: size)
        .shadow(
            color: Color.black.opacity(Theme.isDark ? 0.20 : 0.08),
            radius: 1.5,
            x: 0,
            y: 0.5
        )
    }
}

// MARK: - 4. Apple 风格主行动胶囊按钮 (Primary Pill Button)

struct GlowingPillButton: View {
    var title: String
    var subtitle: String?
    var icon: String?
    var tint: Color
    var isDangerous: Bool
    var isEnabled: Bool
    var width: CGFloat?
    var height: CGFloat?
    var action: () -> Void

    @State var isHovered = false
    @State var isPressed = false

    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        tint: Color = Theme.accent,
        isDangerous: Bool = false,
        isEnabled: Bool = true,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.isDangerous = isDangerous
        self.isEnabled = isEnabled
        self.width = width
        self.height = height
        self.action = action
    }

    var buttonBgGradient: LinearGradient {
        if isDangerous {
            return LinearGradient(
                colors: [Color(red: 1.00, green: 0.27, blue: 0.23), Color(red: 0.90, green: 0.20, blue: 0.16)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [tint.opacity(isHovered ? 0.94 : 1.0), tint.opacity(isHovered ? 0.86 : 0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            HStack(spacing: 7) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12.5, weight: .semibold))
                }

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.88)
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, height != nil ? 6 : 8)
            .frame(minWidth: width)
            .frame(height: height)
            .background(
                Capsule(style: .continuous)
                    .fill(buttonBgGradient)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
            )
            .shadow(
                color: Color.black.opacity(isEnabled ? (Theme.isDark ? 0.26 : 0.10) : 0),
                radius: isHovered ? 5 : 3,
                x: 0,
                y: isHovered ? 2 : 1
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.42)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .animation(.easeOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onHover { isHovered = $0 }
    }
}

// MARK: - 5. 纯净画布背景修饰器 (Clean Canvas Background)

struct AmbientGlowBackgroundModifier: ViewModifier {
    @ObservedObject var config = AppConfigStore.shared
    var accentColor: Color

    init(accentColor: Color = Theme.accent) {
        self.accentColor = accentColor
    }

    func body(content: Content) -> some View {
        ZStack {
            Theme.contentBg.ignoresSafeArea()
            content
        }
    }
}

extension View {
    func ambientGlowBackground(accent: Color = Theme.accent) -> some View {
        self.modifier(AmbientGlowBackgroundModifier(accentColor: accent))
    }
}
