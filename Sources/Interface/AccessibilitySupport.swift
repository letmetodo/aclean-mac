import SwiftUI

// MARK: - 无障碍（VoiceOver）统一语义层
//
// CleanMate 大量控件是自绘图形（勾选框、环形图、水波图、图标按钮），
// 系统无法从绘制内容推断语义，读屏用户只会听到「按钮」。本文件提供统一修饰符，
// 把语义补齐，避免 59 个界面文件各写一遍。
//
// 纯展示层增强：不参与业务逻辑，不改变布局、不改变交互路径。

extension View {

    /// 列表行：把行内静态文本合并为一个可访问元素，读屏一次读完整条信息。
    /// 仅用于「不含独立交互控件」的行；含按钮/勾选框的行请用 `a11yGroup`。
    func a11yRow(title: String, value: String? = nil, selected: Bool? = nil, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
            .a11yOptionalValue(value)
            .a11yOptionalHint(hint)
            .accessibilityAddTraits(selected == true ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }

    /// 行 / 分组容器：保留子元素可独立导航（读屏用户仍能操作行内按钮与勾选框），
    /// 同时给容器一个整体标签。比 `.combine` 更安全——不会吞掉交互元素。
    func a11yGroup(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
            .a11yOptionalHint(hint)
    }

    /// 纯图形控件（自绘勾选框、图标按钮）：忽略内部绘制，只暴露一个按钮语义。
    func a11yControl(label: String, value: String? = nil, hint: String? = nil,
                     selected: Bool? = nil, enabled: Bool = true) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .a11yOptionalValue(value)
            .a11yOptionalHint(hint)
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(selected == true ? AccessibilityTraits.isSelected : AccessibilityTraits())
            .accessibilityRespondsToUserInteraction(enabled)
    }

    /// 纯图形可视化（环形图、柱状图、水波图）：给出文字等价物。
    /// 这类视图对读屏原本完全不可理解，必须提供 label + 数值描述。
    func a11yChart(label: String, description: String) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(description)
    }

    /// 进度指示：播报百分比。`fraction` 会自动夹取到 0...1。
    func a11yProgress(label: String, fraction: Double) -> some View {
        let clamped = min(max(fraction, 0), 1)
        let percent = Int((clamped * 100).rounded())
        return self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(L10n.format(.a11yProgressPercentFormat, percent))
    }

    /// 纯装饰元素（背景、光晕、分隔线）：从无障碍树中移除，避免读屏噪声。
    func a11yDecorative() -> some View {
        self.accessibilityHidden(true)
    }

    @ViewBuilder
    fileprivate func a11yOptionalValue(_ value: String?) -> some View {
        if let value, !value.isEmpty {
            self.accessibilityValue(value)
        } else {
            self
        }
    }

    @ViewBuilder
    fileprivate func a11yOptionalHint(_ hint: String?) -> some View {
        if let hint, !hint.isEmpty {
            self.accessibilityHint(hint)
        } else {
            self
        }
    }
}
