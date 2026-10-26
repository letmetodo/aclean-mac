import SwiftUI
import AppKit

// ============================================================
//  设计系统 (Theme & DesignSystem)
//
//  支持：
//    1. 浅色模式 (Light) / 暗色模式 (Dark) / 跟随系统 (System) 动态自适应；
//    2. 6 套预设主题色配色方案 (琥珀暖金 / 深海湛蓝 / 森系翠绿 / 星云流紫 / 石英暖粉 / 石墨极简)；
//    3. 所有影响用户阅读与操作的语义色严禁写死，统一由 Theme 动态计算。
// ============================================================

enum Theme {
    /// 当前是否处于暗色模式
    static var isDark: Bool {
        AppConfigStore.shared.isEffectiveDark
    }

    /// 当前激活的主题色预设
    static var preset: AppThemePreset {
        AppConfigStore.shared.currentThemePreset
    }

    /// 构造自适应 AppKit/SwiftUI 动态色彩，由绘制时的真实有效外观动态求值，彻底杜绝暗色背景文字对比度异常与旧色残存
    static func dynamicColor(
        dark: @escaping () -> Color,
        light: @escaping () -> Color
    ) -> Color {
        let darkNSColor = NSColor(dark())
        let lightNSColor = NSColor(light())
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            AppConfigStore.shared.isEffectiveDark(for: appearance) ? darkNSColor : lightNSColor
        }))
    }

    // MARK: - 预设主题调色盘缓存（避免每次视图刷新重复分配 NSColor 动态闭包，保障 SwiftUI AttributeGraph 相等性剪枝）
    private struct PresetPalette {
        let accent: Color
        let accent2: Color
        let onAccent: Color
        let windowBg: Color
        let sidebarBg: Color
        let contentBg: Color
        let card: Color
        let cardElevated: Color
        let sel: Color

        init(preset: AppThemePreset) {
            self.accent = Theme.dynamicColor(
                dark: {
                    let rgb = preset.primaryRGB(isDark: true)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                },
                light: {
                    let rgb = preset.primaryRGB(isDark: false)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                }
            )
            self.accent2 = Theme.dynamicColor(
                dark: {
                    let rgb = preset.secondaryRGB(isDark: true)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                },
                light: {
                    let rgb = preset.secondaryRGB(isDark: false)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                }
            )
            self.onAccent = Theme.dynamicColor(
                dark: { .white },
                light: { .white }
            )
            let canvasColor = Theme.dynamicColor(
                dark: {
                    let rgb = preset.canvasRGB(isDark: true)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                },
                light: {
                    let rgb = preset.canvasRGB(isDark: false)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                }
            )
            self.windowBg = canvasColor
            self.contentBg = canvasColor
            self.sidebarBg = Theme.dynamicColor(
                dark: {
                    let rgb = preset.sidebarRGB(isDark: true)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                },
                light: {
                    let rgb = preset.sidebarRGB(isDark: false)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                }
            )
            self.card = Theme.dynamicColor(
                dark: {
                    let rgb = preset.cardRGB(isDark: true)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                },
                light: {
                    let rgb = preset.cardRGB(isDark: false)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
                }
            )
            self.cardElevated = Theme.dynamicColor(
                dark: {
                    Color(red: 0.200, green: 0.200, blue: 0.212) // #333336
                },
                light: { .white }
            )
            self.sel = Theme.dynamicColor(
                dark: {
                    let rgb = preset.primaryRGB(isDark: true)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b).opacity(0.16)
                },
                light: {
                    let rgb = preset.primaryRGB(isDark: false)
                    return Color(red: rgb.r, green: rgb.g, blue: rgb.b).opacity(0.11)
                }
            )
        }
    }

    private static let defaultPalette = PresetPalette(preset: .oceanBlue)
    private static let palettes: [AppThemePreset: PresetPalette] = Dictionary(
        uniqueKeysWithValues: AppThemePreset.allCases.map { ($0, PresetPalette(preset: $0)) }
    )
    private static var activePalette: PresetPalette {
        palettes[preset] ?? defaultPalette
    }

    // MARK: - 预设主题强调色（随主题色方案与深浅色自适应）
    static var accent: Color { activePalette.accent }
    static var accent2: Color { activePalette.accent2 }

    static func presetColors(for preset: AppThemePreset) -> (primary: Color, secondary: Color) {
        let pal = palettes[preset] ?? PresetPalette(preset: preset)
        return (pal.accent, pal.accent2)
    }

    /// 强调色按钮上的前景文字色（自动保证高对比度可读性）
    static var onAccent: Color { activePalette.onAccent }

    // 模块色（对齐 Apple HIG System Colors）
    static let junk: Color     = dynamicColor(dark: { Color(red: 0.19, green: 0.82, blue: 0.35) }, light: { Color(red: 0.16, green: 0.71, blue: 0.28) })
    static let space: Color    = dynamicColor(dark: { Color(red: 0.37, green: 0.36, blue: 0.90) }, light: { Color(red: 0.35, green: 0.34, blue: 0.84) })
    static let apps: Color     = dynamicColor(dark: { Color(red: 0.04, green: 0.52, blue: 1.00) }, light: { Color(red: 0.00, green: 0.48, blue: 1.00) })
    static let protect: Color  = dynamicColor(dark: { Color(red: 1.00, green: 0.22, blue: 0.37) }, light: { Color(red: 1.00, green: 0.18, blue: 0.33) })
    static let perform: Color  = dynamicColor(dark: { Color(red: 1.00, green: 0.62, blue: 0.04) }, light: { Color(red: 0.94, green: 0.52, blue: 0.00) })
    static let organize: Color = dynamicColor(dark: { Color(red: 0.25, green: 0.78, blue: 0.88) }, light: { Color(red: 0.00, green: 0.64, blue: 0.76) })
    static let cloud: Color    = dynamicColor(dark: { Color(red: 0.04, green: 0.52, blue: 1.00) }, light: { Color(red: 0.00, green: 0.48, blue: 1.00) })
    static let tool: Color     = dynamicColor(dark: { Color(red: 0.69, green: 0.32, blue: 0.87) }, light: { Color(red: 0.64, green: 0.28, blue: 0.82) })
    static let smart: Color    = dynamicColor(dark: { Color(red: 1.00, green: 0.22, blue: 0.37) }, light: { Color(red: 1.00, green: 0.18, blue: 0.33) })

    // MARK: - 窗口、侧栏与画布背景色（Apple 纯净中性底色，深浅色自适应）
    static var windowBg: Color  { activePalette.windowBg }
    static var sidebarBg: Color { activePalette.sidebarBg }
    static var contentBg: Color { activePalette.contentBg }

    // MARK: - 文本层级色（对齐 Apple HIG Label Hierarchy: #1D1D1F / #6E6E73 / #86868B）
    static let text: Color = dynamicColor(
        dark: { Color.white.opacity(0.92) },
        light: { Color(red: 0.114, green: 0.114, blue: 0.122) }
    )

    static let sub: Color = dynamicColor(
        dark: { Color.white.opacity(0.56) },
        light: { Color(red: 0.431, green: 0.431, blue: 0.451) }
    )

    static let tert: Color = dynamicColor(
        dark: { Color.white.opacity(0.36) },
        light: { Color(red: 0.549, green: 0.549, blue: 0.576) }
    )

    // MARK: - 表面、卡片、边框与交互态
    static let sep: Color = dynamicColor(
        dark: { Color.white.opacity(0.075) },
        light: { Color.black.opacity(0.065) }
    )

    static let border: Color = dynamicColor(
        dark: { Color.white.opacity(0.075) },
        light: { Color.black.opacity(0.065) }
    )

    static let canvas: Color = Color.clear
    static let sidebar: Color = Color.clear

    /// 标准卡片表面色
    static var card: Color { activePalette.card }

    /// 悬浮/展开二级卡片表面色
    static var cardElevated: Color { activePalette.cardElevated }

    /// 输入框/胶囊底色
    static let field: Color = dynamicColor(
        dark: { Color.white.opacity(0.055) },
        light: { Color.black.opacity(0.04) }
    )

    /// 鼠标悬停态
    static let hover: Color = dynamicColor(
        dark: { Color.white.opacity(0.055) },
        light: { Color.black.opacity(0.04) }
    )

    /// 选中行/选中胶囊态（融合当前预设主题色）
    static var sel: Color { activePalette.sel }

    /// 底部主行动胶囊按钮底色（对齐当前 Apple 强调色）
    static var primaryPillBg: Color { activePalette.accent }

    /// 底部主行动胶囊按钮文字色
    static let primaryPillFg: Color = .white

    // MARK: - 状态语义色（对齐 Apple HIG System Green / Red / Orange）
    static let green: Color = dynamicColor(
        dark: { Color(red: 0.188, green: 0.820, blue: 0.345) },
        light: { Color(red: 0.157, green: 0.706, blue: 0.275) }
    )

    static let red: Color = dynamicColor(
        dark: { Color(red: 1.000, green: 0.271, blue: 0.227) },
        light: { Color(red: 1.000, green: 0.231, blue: 0.188) }
    )

    static let amber: Color = dynamicColor(
        dark: { Color(red: 1.000, green: 0.624, blue: 0.039) },
        light: { Color(red: 0.940, green: 0.520, blue: 0.000) }
    )

    /// 模块主题色 → 渐变双色
    static func gradient(_ c: Color) -> [Color] { [c, c.opacity(0.88)] }

    static let mono = Font.system(size: 11, design: .monospaced)
}

// MARK: - SF Symbol 兜底

enum Sym {
    private static let cacheStorage = LockedValue<[String: String]>([:])
    private static var cache: [String: String] {
        get { cacheStorage.withValue { $0 } }
        set { cacheStorage.withValue { $0 = newValue } }
    }
    static func ok(_ name: String) -> String {
        if let c = cache[name] { return c }
        let valid = NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        let result = valid ? name : "doc"
        cache[name] = result
        return result
    }
}

// MARK: - 卡片

struct Card<Content: View>: View {
    var padding: CGFloat = 18
    var radius: CGFloat = 14
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Theme.card))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.sep, lineWidth: 0.8))
    }
}

// MARK: - 渐变图标块

struct IconTile: View {
    var icon: String
    var size: CGFloat = 44
    var colors: [Color] = Theme.gradient(Theme.accent)
    var radius: CGFloat? = nil

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius ?? size * 0.28, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Image(systemName: Sym.ok(icon))
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 勾选框（三态，深浅色自适应）

enum CheckState { case off, on, mixed }

struct CheckBox: View {
    var state: CheckState
    var disabled: Bool = false
    var tint: Color = Theme.accent
    /// 读屏朗读用的项目名（如「Chrome 缓存」）。为空时回退到通用「选择」。
    var a11yLabel: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if state == .off {
                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                        .strokeBorder(disabled ? Theme.tert.opacity(0.35) : Theme.sub.opacity(0.65), lineWidth: 1.4)
                        .background(
                            RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                                .fill(Theme.field.opacity(0.5))
                        )
                        .frame(width: 16, height: 16)
                } else {
                    RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                        .fill(tint)
                        .frame(width: 16, height: 16)
                    if state == .mixed {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Theme.onAccent)
                            .frame(width: 8, height: 2)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.onAccent)
                    }
                }
            }
            .frame(width: 18, height: 18)
            .opacity(disabled ? 0.4 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .a11yControl(
            label: a11yLabel ?? L10n.localized(.labelSelectionPrefix),
            value: state == .on
                ? L10n.localized(.selected)
                : (state == .mixed ? L10n.localized(.cleanupPartialResult) : L10n.localized(.actionNone)),
            hint: disabled ? L10n.localized(.a11yLockedItemHint) : nil,
            selected: state == .on,
            enabled: !disabled
        )
    }
}

// MARK: - 安全等级角标

struct SafetyBadge: View {
    var safety: Safety
    var body: some View {
        let (t, c): (String, Color) = {
            switch safety {
            case .safe:    return (L10n.localized(.safetySafe), Theme.green)
            case .caution: return (L10n.localized(.safetyCaution), Theme.amber)
            case .risky:   return (L10n.localized(.safetyRisky), Theme.red)
            }
        }()
        Text(t)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(c)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(c.opacity(0.14)))
    }
}

// MARK: - 尺寸角标

struct SizeBadge: View {
    var text: String
    var strong: Bool = false
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: strong ? .semibold : .regular, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(strong ? Theme.text : Theme.sub)
    }
}

// MARK: - 按钮

struct PrimaryButton: View {
    var title: String
    var icon: String? = nil
    var colors: [Color]? = nil
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        let activeColors = colors ?? Theme.gradient(Theme.accent)
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.system(size: 12, weight: .semibold)) }
                Text(title).font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(enabled ? (colors == nil ? Theme.onAccent : .white) : Theme.sub)
            .padding(.horizontal, 18).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: enabled ? activeColors : [Theme.field, Theme.field],
                                         startPoint: .top, endPoint: .bottom)))
            .opacity(enabled ? 1 : 0.55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct GhostButton: View {
    var title: String
    var icon: String? = nil
    var tint: Color = Theme.text
    var action: () -> Void

    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.system(size: 11, weight: .medium)) }
                Text(title).font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(hover ? Theme.hover : Theme.field.opacity(0.6)))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Theme.sep, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

// MARK: - 环形进度

struct RingProgress: View {
    var progress: Double
    var size: CGFloat = 132
    var colors: [Color] = Theme.gradient(Theme.accent)
    var lineWidth: CGFloat = 9
    var label: String? = nil
    var sublabel: String? = nil
    /// 读屏专用：说明这个环代表什么（如「存储占用」）。为空时回退到 label。
    var a11yLabel: String? = nil
    /// 读屏专用：具体数值描述（如「已用 68%，共 512 GB」）。为空时回退到百分比。
    var a11yValue: String? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.sep.opacity(0.6), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(AngularGradient(colors: colors + [colors[0]], center: .center),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: progress)
            VStack(spacing: 2) {
                if let label {
                    Text(label)
                        .font(.system(size: size * 0.20, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.text)
                }
                if let sublabel {
                    Text(sublabel)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.sub)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a11yLabel ?? label ?? "")
        .accessibilityValue(a11yValue ?? L10n.format(.a11yProgressPercentFormat,
                                                    Int((min(max(progress, 0), 1) * 100).rounded())))
    }
}

// MARK: - 磁盘条

struct DiskBar: View {
    var used: Int64
    var total: Int64
    var height: CGFloat = 6
    var tint: Color = Theme.accent

    var body: some View {
        let progress = total > 0 ? min(1.0, max(0.0, Double(used) / Double(total))) : 0.0
        LiquidProgressBar(
            progress: progress,
            tint: tint,
            secondaryTint: Theme.accent2,
            height: height,
            showGlowTip: true
        )
        // 纯视觉条：用量信息由相邻文字（已用 / 总计）表达，读屏无需重复朗读。
        .a11yDecorative()
    }
}

// MARK: - 搜索框

struct SearchField: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Theme.tert)
                .a11yDecorative()
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Theme.text)
                .accessibilityLabel(placeholder)
                .accessibilityHint(L10n.localized(.a11ySearchFieldHint))
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.tert)
                }
                .buttonStyle(.plain)
                .a11yControl(label: L10n.localized(.a11yClearSearchField))
            }
        }
        .padding(.horizontal, 9).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.field))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(Theme.sep, lineWidth: 0.6))
    }
}

// MARK: - 分段控件

struct Segmented<T: Hashable>: View {
    var items: [(T, String)]
    @Binding var value: T

    var body: some View {
        HStack(spacing: 2) {
            ForEach(items, id: \.0) { item in
                let on = item.0 == value
                Button { value = item.0 } label: {
                    Text(item.1)
                        .font(.system(size: 11, weight: on ? .semibold : .regular))
                        .foregroundStyle(on ? Theme.text : Theme.sub)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(on ? Theme.cardElevated : Color.clear))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Theme.field))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Theme.sep, lineWidth: 0.5))
    }
}

// MARK: - 空态

struct EmptyState: View {
    var icon: String
    var title: String
    var subtitle: String = ""
    var colors: [Color] = Theme.gradient(Theme.accent)

    var body: some View {
        VStack(spacing: 12) {
            IconTile(icon: icon, size: 56, colors: colors)
            Text(title).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.text)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 12)).foregroundStyle(Theme.sub)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

// MARK: - 提示条

struct ToastView: View {
    var text: String
    var kind: ToastKind = .info
    var actionTitle: String? = nil
    var onAction: (@MainActor () -> Void)? = nil

    private var accent: Color {
        switch kind {
        case .info: return Theme.accent
        case .success: return Theme.green
        case .warning: return Theme.amber
        case .error: return Theme.red
        }
    }

    private var iconName: String? {
        switch kind {
        case .info: return nil
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
                    .a11yDecorative()
            } else {
                Circle()
                    .fill(accent)
                    .frame(width: 6, height: 6)
                    .a11yDecorative()
            }
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.text)
                .lineLimit(2)
            if let actionTitle, let onAction {
                Button(actionTitle) { onAction() }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent)
                    .padding(.leading, 2)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Theme.isDark ? Color(red: 0.16, green: 0.17, blue: 0.20).opacity(0.96)
                                   : Color.white.opacity(0.96))
        )
        .overlay(Capsule().strokeBorder(Theme.sep, lineWidth: 0.8))
        .shadow(color: .black.opacity(Theme.isDark ? 0.35 : 0.12), radius: 10, y: 4)
        // 提示内容会被自动朗读，用户不必主动寻找
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - 分区标题

struct SectionLabel: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Theme.tert)
            .textCase(.uppercase)
    }
}

// ============================================================
//  MARK: - CleanMate 原生简洁交互组件 (CleanMate Native Primitives)
// ============================================================

/// 四态复选框状态：
/// - `.all`: 全部勾选 (`✓`)
/// - `.partial`: 部分勾选 (`—`)
/// - `.none`: 未勾选 (`☐`)
/// - `.locked`: 仅展示占用、不参与清理 (`•`，对应「手动管理」)
enum CheckboxState {
    case all
    case partial
    case none
    case locked
}

/// 右上角极简图标按钮（如 `↻` 刷新、`⊗` 重置关闭、`🔍` 搜索）
struct HeaderIconButton: View {
    var icon: String
    var spinning: Bool = false
    var helpText: String = ""
    var action: () -> Void

    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(hover ? Theme.text : Theme.sub)
                .rotationEffect(.degrees(spinning ? 360 : 0))
                .animation(
                    spinning ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default,
                    value: spinning
                )
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(hover ? Theme.hover : Color.clear)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .help(helpText)
        .accessibilityLabel(helpText.isEmpty ? L10n.localized(icon == "xmark" ? .actionClose : .actionRefresh) : helpText)
    }
}

/// 底部内联动作链接（如 `全选 · 全不选 · 推荐` 或 `一并移除用户数据 · 取消选择`）
struct ActionLink: View {
    var title: String
    var enabled: Bool = true
    var action: () -> Void

    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(
                    !enabled
                        ? Theme.tert.opacity(0.65)
                        : (hover ? Theme.accent.opacity(0.85) : Theme.accent)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .onHover { hover = $0 }
    }
}

/// 右下角高对比度胶囊主行动按钮（暗色模式下为白底深字，浅色模式下为深底白字）
struct PrimaryPillButton: View {
    var title: String
    var enabled: Bool = true
    var busy: Bool = false
    var action: () -> Void

    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if busy {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(enabled ? Theme.primaryPillFg : Theme.tert)
            .padding(.horizontal, 28)
            .frame(height: 44)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        enabled
                            ? Theme.primaryPillBg.opacity(hover ? 0.92 : 1.0)
                            : Theme.cardElevated
                    )
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled || busy)
        .onHover { hover = $0 }
    }
}

