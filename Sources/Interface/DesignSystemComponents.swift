import SwiftUI
import AppKit

// MARK: - 6. 预设分类图标与色调字典 (Bento Badges)

@MainActor
enum CleanCategoryVisuals {
    // Apple HIG System Color Pairs (Top -> Bottom subtle vertical gradient)
    private static let appleBlue   = (Color(red: 0.04, green: 0.52, blue: 1.00), Color(red: 0.00, green: 0.40, blue: 0.88))
    private static let appleGreen  = (Color(red: 0.19, green: 0.82, blue: 0.35), Color(red: 0.14, green: 0.68, blue: 0.28))
    private static let appleIndigo = (Color(red: 0.37, green: 0.36, blue: 0.90), Color(red: 0.29, green: 0.28, blue: 0.78))
    private static let appleOrange = (Color(red: 1.00, green: 0.62, blue: 0.04), Color(red: 0.92, green: 0.49, blue: 0.00))
    private static let applePink   = (Color(red: 1.00, green: 0.22, blue: 0.37), Color(red: 0.88, green: 0.15, blue: 0.30))
    private static let appleTeal   = (Color(red: 0.20, green: 0.68, blue: 0.90), Color(red: 0.05, green: 0.54, blue: 0.78))
    private static let appleGray   = (Color(red: 0.56, green: 0.56, blue: 0.58), Color(red: 0.44, green: 0.44, blue: 0.46))

    static func badge(for kind: SmartCleanSectionKind, size: CGFloat = 28) -> GradientIconBadge {
        switch kind {
        case .app:
            return GradientIconBadge(icon: "app.badge.fill", size: size, colors: [appleBlue.0, appleBlue.1])
        case .communication:
            return GradientIconBadge(icon: "bubble.left.and.bubble.right.fill", size: size, colors: [appleGreen.0, appleGreen.1])
        case .developer:
            return GradientIconBadge(icon: "hammer.fill", size: size, colors: [appleIndigo.0, appleIndigo.1])
        case .ai:
            return GradientIconBadge(icon: "sparkles", size: size, colors: [appleTeal.0, appleTeal.1])
        case .design:
            return GradientIconBadge(icon: "paintbrush.fill", size: size, colors: [applePink.0, applePink.1])
        case .leftovers:
            return GradientIconBadge(icon: "trash.slash.fill", size: size, colors: [appleOrange.0, appleOrange.1])
        case .system:
            return GradientIconBadge(icon: "gearshape.2.fill", size: size, colors: [appleGray.0, appleGray.1])
        }
    }

    static func navigationBadge(for key: String, size: CGFloat = 24) -> GradientIconBadge {
        switch key {
        case "junk":
            return GradientIconBadge(icon: "trash.fill", size: size, colors: [appleBlue.0, appleBlue.1])
        case "performance":
            return GradientIconBadge(icon: "bolt.fill", size: size, colors: [appleOrange.0, appleOrange.1])
        case "applications":
            return GradientIconBadge(icon: "square.grid.2x2.fill", size: size, colors: [appleIndigo.0, appleIndigo.1])
        case "spaceLens":
            return GradientIconBadge(icon: "chart.pie.fill", size: size, colors: [appleTeal.0, appleTeal.1])
        case "organize":
            return GradientIconBadge(icon: "folder.fill.badge.gearshape", size: size, colors: [appleGreen.0, appleGreen.1])
        case "liveMonitor":
            return GradientIconBadge(icon: "gauge.with.dots.needle.67percent", size: size, colors: [applePink.0, applePink.1])
        default:
            return GradientIconBadge(icon: "sparkles", size: size, colors: [Theme.accent, Theme.accent2])
        }
    }

    static func declutterBadge(for kind: SmartDeclutterSectionKind, size: CGFloat = 28) -> GradientIconBadge {
        switch kind {
        case .installers:
            return GradientIconBadge(icon: "shippingbox.fill", size: size, colors: [appleOrange.0, appleOrange.1])
        case .duplicates:
            return GradientIconBadge(icon: "doc.on.doc.fill", size: size, colors: [appleBlue.0, appleBlue.1])
        case .similarPhotos:
            return GradientIconBadge(icon: "photo.stack.fill", size: size, colors: [applePink.0, applePink.1])
        case .downloads:
            return GradientIconBadge(icon: "arrow.down.circle.fill", size: size, colors: [appleTeal.0, appleTeal.1])
        case .largeOldFiles:
            return GradientIconBadge(icon: "clock.badge.exclamationmark.fill", size: size, colors: [appleIndigo.0, appleIndigo.1])
        }
    }

    static func glass3DIcon(for kind: SmartCleanSectionKind, size: CGFloat = 44) -> Glass3DIcon {
        switch kind {
        case .app:
            return Glass3DIcon(systemName: "square.stack.3d.up.fill", primaryColor: appleBlue.0, secondaryColor: appleBlue.1, size: size)
        case .communication:
            return Glass3DIcon(systemName: "bubble.left.and.bubble.right.fill", primaryColor: appleGreen.0, secondaryColor: appleGreen.1, size: size)
        case .developer:
            return Glass3DIcon(systemName: "hammer.fill", primaryColor: appleIndigo.0, secondaryColor: appleIndigo.1, size: size)
        case .ai:
            return Glass3DIcon(systemName: "sparkles", primaryColor: appleTeal.0, secondaryColor: appleTeal.1, size: size)
        case .design:
            return Glass3DIcon(systemName: "paintpalette.fill", primaryColor: applePink.0, secondaryColor: applePink.1, size: size)
        case .leftovers:
            return Glass3DIcon(systemName: "trash.slash.fill", primaryColor: appleOrange.0, secondaryColor: appleOrange.1, size: size)
        case .system:
            return Glass3DIcon(systemName: "gearshape.2.fill", primaryColor: appleGray.0, secondaryColor: appleGray.1, size: size)
        }
    }

    static func glass3DIcon(for kind: SmartDeclutterSectionKind, size: CGFloat = 42) -> OpticalSquircleIcon {
        switch kind {
        case .installers:
            return OpticalSquircleIcon(systemName: "shippingbox.fill", primaryColor: appleOrange.0, secondaryColor: appleOrange.1, size: size)
        case .duplicates:
            return OpticalSquircleIcon(systemName: "doc.on.doc.fill", primaryColor: appleBlue.0, secondaryColor: appleBlue.1, size: size)
        case .similarPhotos:
            return OpticalSquircleIcon(systemName: "photo.stack.fill", primaryColor: applePink.0, secondaryColor: applePink.1, size: size)
        case .downloads:
            return OpticalSquircleIcon(systemName: "arrow.down.circle.fill", primaryColor: appleTeal.0, secondaryColor: appleTeal.1, size: size)
        case .largeOldFiles:
            return OpticalSquircleIcon(systemName: "clock.badge.exclamationmark.fill", primaryColor: appleIndigo.0, secondaryColor: appleIndigo.1, size: size)
        }
    }

    static func opticalIcon(for kind: SmartCleanSectionKind, size: CGFloat = 42) -> OpticalSquircleIcon {
        glass3DIcon(for: kind, size: size)
    }

    static func opticalIcon(for kind: SmartDeclutterSectionKind, size: CGFloat = 42) -> OpticalSquircleIcon {
        glass3DIcon(for: kind, size: size)
    }

    static func navigationOpticalIcon(for key: String, size: CGFloat = 24) -> OpticalSquircleIcon {
        switch key {
        case "healthCheck":
            return OpticalSquircleIcon(systemName: "shield.checkerboard", primaryColor: appleTeal.0, secondaryColor: appleBlue.0, size: size)
        case "smartCare":
            return OpticalSquircleIcon(systemName: "wand.and.stars", primaryColor: Theme.accent, secondaryColor: Theme.accent2, size: size)
        case "junk":
            return OpticalSquircleIcon(systemName: "trash.fill", primaryColor: appleBlue.0, secondaryColor: appleBlue.1, size: size)
        case "performance":
            return OpticalSquircleIcon(systemName: "bolt.fill", primaryColor: appleOrange.0, secondaryColor: appleOrange.1, size: size)
        case "applications":
            return OpticalSquircleIcon(systemName: "square.grid.2x2.fill", primaryColor: appleIndigo.0, secondaryColor: appleIndigo.1, size: size)
        case "spaceLens":
            return OpticalSquircleIcon(systemName: "chart.pie.fill", primaryColor: appleTeal.0, secondaryColor: appleTeal.1, size: size)
        case "organize":
            return OpticalSquircleIcon(systemName: "folder.fill.badge.gearshape", primaryColor: appleGreen.0, secondaryColor: appleGreen.1, size: size)
        case "liveMonitor":
            return OpticalSquircleIcon(systemName: "gauge.with.dots.needle.67percent", primaryColor: applePink.0, secondaryColor: applePink.1, size: size)
        case "toolbox":
            return OpticalSquircleIcon(systemName: "square.grid.3x3.fill", primaryColor: appleGray.0, secondaryColor: appleGray.1, size: size)
        case "assistant":
            return OpticalSquircleIcon(systemName: "brain.head.profile", primaryColor: Theme.accent, secondaryColor: Theme.accent2, size: size)
        default:
            return OpticalSquircleIcon(systemName: "sparkles", primaryColor: Theme.accent, secondaryColor: Theme.accent2, size: size)
        }
    }
}

// ============================================================
//  MARK: - 7. 高定微组件库 (High-End Micro-Components)
// ============================================================

// 1. Apple 原生质感复选框 (FluidCheckbox)
struct FluidCheckbox: View {
    @ObservedObject var config = AppConfigStore.shared
    var state: CheckboxState
    var tint: Color = Theme.accent
    /// 读屏朗读用的项目名（如「Chrome 缓存」）。为空时回退到通用「选择」。
    var a11yLabel: String? = nil
    var action: () -> Void

    @State var hover: Bool = false

    var body: some View {
        let isDark = Theme.isDark
        Button(action: {
            if state != .locked {
                action()
            }
        }) {
            ZStack {
                switch state {
                case .all:
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tint)

                    Image(systemName: "checkmark")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(Color.white)

                case .partial:
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tint)

                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 8, height: 2)

                case .none:
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            isDark
                                ? Color.white.opacity(hover ? 0.08 : 0.04)
                                : Color.white
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .strokeBorder(
                                    isDark
                                        ? Color.white.opacity(hover ? 0.35 : 0.22)
                                        : Color.black.opacity(hover ? 0.32 : 0.20),
                                    lineWidth: 1
                                )
                        )

                case .locked:
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(isDark ? Color.white.opacity(0.03) : Color.black.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .strokeBorder(Theme.tert.opacity(0.28), lineWidth: 1)
                        )
                    Circle()
                        .fill(Theme.tert.opacity(0.55))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 18, height: 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(a11yLabel ?? L10n.localized(.labelSelectionPrefix))
        .accessibilityValue(state == .all ? L10n.localized(.selected) :
                            (state == .partial ? L10n.localized(.cleanupPartialResult) :
                             (state == .locked ? L10n.localized(.cleanSkippedProtected) : L10n.localized(.actionNone))))
        .accessibilityHint(state == .locked ? L10n.localized(.a11yLockedItemHint) : "")
        .accessibilityAddTraits(state == .all ? AccessibilityTraits.isSelected : AccessibilityTraits())
        .disabled(state == .locked)
        .onHover { hover = $0 }
    }
}

// 2. 轻量胶囊标签 (MetallicBadge)
struct MetallicBadge: View {
    @ObservedObject var config = AppConfigStore.shared
    var text: String
    var color: Color = Theme.accent
    var icon: String? = nil

    var body: some View {
        let isDark = Theme.isDark
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9.5, weight: .semibold))
            }
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(isDark ? color.opacity(0.95) : color)
        .padding(.horizontal, 7)
        .padding(.vertical, 2.5)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(color.opacity(isDark ? 0.14 : 0.10))
        )
        .fixedSize(horizontal: true, vertical: true)
    }
}

// 3. Apple 原生分段控制器 (SlidingSegmentedControl)
struct SlidingSegmentItem<T: Hashable>: Identifiable {
    let id: T
    let title: String
    var badge: String? = nil
}

struct SlidingSegmentedControl<T: Hashable>: View {
    let items: [SlidingSegmentItem<T>]
    @Binding var selection: T
    @Namespace var segmentNamespace
    @ObservedObject var config = AppConfigStore.shared

    var body: some View {
        let isDark = Theme.isDark

        HStack(spacing: 2) {
            ForEach(items) { item in
                let isSelected = (selection == item.id)
                Button {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        selection = item.id
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(item.title)
                            .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(isSelected ? Theme.text : Theme.sub)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        if let badge = item.badge, !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(isSelected ? Theme.text : Theme.tert)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(isDark ? Color.white.opacity(isSelected ? 0.14 : 0.06) : Color.black.opacity(isSelected ? 0.07 : 0.04))
                                )
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 5)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                                .fill(isDark ? Color(red: 0.24, green: 0.24, blue: 0.26) : Color.white)
                                .shadow(
                                    color: Color.black.opacity(isDark ? 0.22 : 0.08),
                                    radius: 2,
                                    y: 1
                                )
                                .matchedGeometryEffect(id: "sliding_active_segment", in: segmentNamespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2.5)
        .background(
            RoundedRectangle(cornerRadius: 8.5, style: .continuous)
                .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.055))
        )
    }
}

// 4. Apple 纯净进度条 (LiquidProgressBar)
struct LiquidProgressBar: View {
    @ObservedObject var config = AppConfigStore.shared
    var progress: Double // 0.0 ~ 1.0
    var tint: Color = Theme.accent
    var secondaryTint: Color = Theme.accent2
    var height: CGFloat = 5
    var showGlowTip: Bool = false

    var body: some View {
        let isDark = Theme.isDark
        let clamped = min(max(progress, 0.0), 1.0)

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.065))
                    .frame(height: height)

                if clamped > 0 {
                    let fillWidth = max(height, geo.size.width * CGFloat(clamped))
                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: fillWidth, height: height)
                }
            }
        }
        .frame(height: height)
    }
}

// 5. 丝滑胶囊开关 (SmoothCapsuleToggle)
struct SmoothCapsuleToggle: View {
    @Binding var isOn: Bool
    var tint: Color = Theme.accent
    @ObservedObject var config = AppConfigStore.shared

    var body: some View {
        let isDark = Theme.isDark
        Button {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule(style: .continuous)
                    .fill(isOn ? tint : (isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.12)))
                    .frame(width: 38, height: 22)

                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .padding(2)
                    .shadow(color: Color.black.opacity(0.18), radius: 1.5, y: 0.8)
            }
        }
        .buttonStyle(.plain)
    }
}
