import SwiftUI
import AppKit

// ============================================================
//  NextGenVisualEngine.swift —— CleanMate 次世代流光舞台视觉引擎
//
//  核心视觉组件：
//    1. AuroraBackgroundView: 动态深海极光流体背景（告别死板纯色）
//    2. Glass3DIcon: 3D 拟态多层玻璃折射图标
//    3. PulseOrbStageView: 核心视觉舞台悬浮脉冲立体能量球
//    4. StaggeredAppearModifier: 瀑布流交错弹簧入场动效修饰器
//    5. NextGenCategoryVisuals: 7 大系统清理分类与透视分类的专属 3D 视觉映射
// ============================================================

// MARK: - 1. 纯净 Apple 画布背景 (消除杂色极光污染，呈现纯净深浅中性底色)

struct AuroraBackgroundView: View {
    @ObservedObject private var config = AppConfigStore.shared
    var themeColor: Color = Theme.accent

    var body: some View {
        Theme.contentBg
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}

// MARK: - 2. macOS 系统设置风格圆角图标 (OpticalSquircleIcon)

struct OpticalSquircleIcon: View {
    @ObservedObject private var config = AppConfigStore.shared
    let systemName: String
    let primaryColor: Color
    let secondaryColor: Color
    var size: CGFloat = 42

    var body: some View {
        let isDark = Theme.isDark
        let cornerRadius = size * 0.225
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        ZStack {
            shape
                .fill(
                    LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: systemName)
                .font(.system(size: size * 0.48, weight: .semibold))
                .foregroundStyle(Color.white)

            shape
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDark ? 0.36 : 0.48),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.65
                )
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .shadow(
            color: isDark ? primaryColor.opacity(0.28) : Color.black.opacity(0.12),
            radius: isDark ? 3.5 : 2.0,
            x: 0,
            y: isDark ? 1.5 : 1.0
        )
    }
}

/// 兼容别名 Glass3DIcon -> OpticalSquircleIcon
typealias Glass3DIcon = OpticalSquircleIcon

// MARK: - 3. 核心视觉舞台：Apple 极简精密圆环仪表 (Precision Ring Stage)

struct PulseOrbStageView: View {
    var isScanning: Bool
    var sizeText: String // 如 "29.23" 或 "0.00"
    var unitText: String // 如 "GB"
    var subtitle: String // 如 "让你的 Mac 焕然一新" 或 "深度扫描中"
    var themeColor: Color = Theme.accent
    var diameter: CGFloat = 200
    var symbol: String? = nil

    @ObservedObject private var config = AppConfigStore.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var spinAngle: Double = 0

    var body: some View {
        let isDark = Theme.isDark
        let orbScale = diameter / 200.0

        ZStack {
            // 1. 纯净圆形卡片底座
            Circle()
                .fill(isDark ? Theme.card : Color.white)
                .frame(width: 176 * orbScale, height: 176 * orbScale)
                .shadow(
                    color: Color.black.opacity(isDark ? 0.24 : 0.05),
                    radius: 14 * orbScale,
                    x: 0,
                    y: 4 * orbScale
                )

            // 2. 精密刻度底轨
            Circle()
                .strokeBorder(
                    isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.06),
                    lineWidth: max(2.5, 3.5 * orbScale)
                )
                .frame(width: 176 * orbScale, height: 176 * orbScale)

            // 3. 主题强调色圆环（扫描时平滑旋转，静止时呈现细腻静态环）
            if isScanning {
                Circle()
                    .trim(from: 0.08, to: 0.78)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                themeColor.opacity(0.05),
                                themeColor.opacity(0.45),
                                themeColor
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: max(2.5, 3.5 * orbScale), lineCap: .round)
                    )
                    .frame(width: 176 * orbScale, height: 176 * orbScale)
                    .rotationEffect(.degrees(spinAngle))
            } else {
                Circle()
                    .strokeBorder(
                        themeColor.opacity(isDark ? 0.32 : 0.24),
                        lineWidth: max(1.5, 2.0 * orbScale)
                    )
                    .frame(width: 176 * orbScale, height: 176 * orbScale)
            }

            // 4. 中心符号、体积数字与副标题
            VStack(spacing: 4 * orbScale) {
                if let sym = symbol, sizeText.isEmpty {
                    Image(systemName: sym)
                        .font(.system(size: 36 * orbScale, weight: .medium))
                        .foregroundStyle(themeColor)
                        .padding(.bottom, 2 * orbScale)
                }

                if !sizeText.isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: 3 * orbScale) {
                        Text(sizeText)
                            .font(.system(size: 38 * orbScale, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.text)
                            .monospacedDigit()
                            .contentTransition(.numericText())

                        Text(unitText)
                            .font(.system(size: 14 * orbScale, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.sub)
                    }
                }

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11.5 * orbScale, weight: .medium))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                        .padding(.horizontal, 16 * orbScale)
                }
            }
        }
        .frame(width: 196 * orbScale, height: 196 * orbScale)
        .onAppear {
            updateScanAnimations(scanning: isScanning)
        }
        .onChange(of: isScanning) { scanning in
            updateScanAnimations(scanning: scanning)
        }
    }

    private func updateScanAnimations(scanning: Bool) {
        guard !reduceMotion else { return }
        if scanning {
            spinAngle = 0
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                spinAngle = 360
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                spinAngle = 0
            }
        }
    }
}

// MARK: - 4. 瀑布流交错弹簧入场修饰器 (让列表像丝绸一样依次滑出来)

struct StaggeredAppearModifier: ViewModifier {
    let index: Int

    func body(content: Content) -> some View {
        // 直接渲染内容，避免菜单切换时全量卡片隐藏 + N 路延迟弹簧动画造成主线程切页停顿
        content
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        self.modifier(StaggeredAppearModifier(index: index))
    }
}

// MARK: - 5. 专属 3D 视觉分类映射表 (NextGenCategoryVisuals)

enum NextGenCategoryVisuals {
    struct VisualMeta {
        var symbol: String
        var primaryColor: Color
        var secondaryColor: Color
        var displayName: String
        var description: String
    }

    /// 垃圾清理 7 大分类的 3D 玻璃图标与双色辉光配置
    static func junkMeta(for tag: String) -> VisualMeta {
        switch tag {
        case "App Cache", L10n.localized(.categoryApplicationCacheTitle):
            return VisualMeta(
                symbol: "square.stack.3d.up.fill",
                primaryColor: Color(red: 0.20, green: 0.75, blue: 0.98),
                secondaryColor: Color(red: 0.10, green: 0.45, blue: 0.92),
                displayName: L10n.localized(.categoryApplicationCacheTitle),
                description: L10n.localized(.categoryApplicationCacheSubtitle)
            )
        case "Messaging", L10n.localized(.categoryCommunicationCacheTitle):
            return VisualMeta(
                symbol: "bubble.left.and.bubble.right.fill",
                primaryColor: Color(red: 0.35, green: 0.88, blue: 0.55),
                secondaryColor: Color(red: 0.12, green: 0.65, blue: 0.40),
                displayName: L10n.localized(.categoryCommunicationCacheTitle),
                description: L10n.localized(.categoryCommunicationCacheSubtitle)
            )
        case "Developer", L10n.localized(.categoryDeveloperEnvironmentCacheTitle):
            return VisualMeta(
                symbol: "hammer.fill",
                primaryColor: Color(red: 0.82, green: 0.40, blue: 0.98),
                secondaryColor: Color(red: 0.58, green: 0.22, blue: 0.85),
                displayName: L10n.localized(.categoryDeveloperEnvironmentCacheTitle),
                description: L10n.localized(.buildArtifactsAndCachesFromXcodeDeriveddataGradleNpmRustEtc)
            )
        case "AI & ML", L10n.localized(.aiModelsAndTools):
            return VisualMeta(
                symbol: "sparkles",
                primaryColor: Color(red: 0.98, green: 0.76, blue: 0.22),
                secondaryColor: Color(red: 0.95, green: 0.50, blue: 0.12),
                displayName: L10n.localized(.aiModelsAndTools),
                description: L10n.localized(.categoryLocalAiModelsSubtitle)
            )
        case "Browser", L10n.localized(.browserCaches):
            return VisualMeta(
                symbol: "safari.fill",
                primaryColor: Color(red: 0.28, green: 0.65, blue: 0.98),
                secondaryColor: Color(red: 0.15, green: 0.40, blue: 0.88),
                displayName: L10n.localized(.browserCaches),
                description: L10n.localized(.temporaryWebPagesFaviconsAndScriptsDownloadedBySafariChromeEtc)
            )
        case "System", L10n.localized(.categorySystemLogsAndDiagnosticsTitle):
            return VisualMeta(
                symbol: "gearshape.2.fill",
                primaryColor: Color(red: 0.55, green: 0.60, blue: 0.72),
                secondaryColor: Color(red: 0.35, green: 0.40, blue: 0.52),
                displayName: L10n.localized(.categorySystemLogsAndDiagnosticsTitle),
                description: L10n.localized(.macosSystemCrashReportsDiagnosticsAndTemporaryFiles)
            )
        case "Trash", L10n.localized(.scannerTrashBins):
            return VisualMeta(
                symbol: "trash.fill",
                primaryColor: Color(red: 0.98, green: 0.35, blue: 0.40),
                secondaryColor: Color(red: 0.85, green: 0.18, blue: 0.25),
                displayName: L10n.localized(.scannerTrashBins),
                description: L10n.localized(.categoryTrashFilesSubtitle)
            )
        default:
            return VisualMeta(
                symbol: "tray.full.fill",
                primaryColor: Theme.accent,
                secondaryColor: Theme.accent2,
                displayName: tag,
                description: L10n.localized(.categorySystemPurgeableCacheDataTitle)
            )
        }
    }

    /// 整理杂乱 5 大分类的 3D 玻璃图标与双色辉光配置
    static func declutterMeta(for tag: String) -> VisualMeta {
        switch tag {
        case "Large Files", L10n.localized(.categoryLargeFilesTitle), L10n.localized(.declutterLargeAndOldFiles):
            return VisualMeta(
                symbol: "doc.zipper",
                primaryColor: Color(red: 0.98, green: 0.65, blue: 0.22),
                secondaryColor: Color(red: 0.88, green: 0.40, blue: 0.12),
                displayName: L10n.localized(.categoryLargeFilesTitle),
                description: L10n.localized(.categoryLargeFilesSubtitle)
            )
        case "Duplicates", L10n.localized(.declutterDuplicates):
            return VisualMeta(
                symbol: "doc.on.doc.fill",
                primaryColor: Color(red: 0.25, green: 0.75, blue: 0.98),
                secondaryColor: Color(red: 0.15, green: 0.50, blue: 0.92),
                displayName: L10n.localized(.declutterDuplicates),
                description: L10n.localized(.identicalFileDuplicatesWithMatchingContentHashes)
            )
        case "Similar Photos", L10n.localized(.categorySimilarPhotosTitle), L10n.localized(.similarImages):
            return VisualMeta(
                symbol: "photo.stack.fill",
                primaryColor: Color(red: 0.85, green: 0.42, blue: 0.95),
                secondaryColor: Color(red: 0.65, green: 0.25, blue: 0.85),
                displayName: L10n.localized(.categorySimilarPhotosTitle),
                description: L10n.localized(.categorySimilarPhotosSubtitle)
            )
        case "DMG & Installers", L10n.localized(.categoryUsedInstallersTitle), L10n.localized(.declutterInstallers):
            return VisualMeta(
                symbol: "externaldrive.fill.badge.minus",
                primaryColor: Color(red: 0.98, green: 0.82, blue: 0.25),
                secondaryColor: Color(red: 0.90, green: 0.62, blue: 0.15),
                displayName: L10n.localized(.categoryUsedInstallersTitle),
                description: L10n.localized(.categoryUsedInstallersSubtitle)
            )
        case "Old Downloads", L10n.localized(.categoryOldDownloadsTitle), L10n.localized(.declutterDownloads):
            return VisualMeta(
                symbol: "arrow.down.circle.fill",
                primaryColor: Color(red: 0.40, green: 0.85, blue: 0.65),
                secondaryColor: Color(red: 0.20, green: 0.65, blue: 0.45),
                displayName: L10n.localized(.categoryOldDownloadsTitle),
                description: L10n.localized(.categoryOldDownloadsSubtitle)
            )
        default:
            return VisualMeta(
                symbol: "archivebox.fill",
                primaryColor: Theme.accent,
                secondaryColor: Theme.accent2,
                displayName: tag,
                description: L10n.localized(.categoryClutteredFilesSubtitle)
            )
        }
    }
}

// MARK: - 体积数字与单位分离格式化助手

extension Fmt {
    static func sizeParts(_ bytes: Int64) -> (value: String, unit: String) {
        guard bytes > 0 else { return ("0.00", "GB") }
        let raw = size(bytes)
        let normalized = raw.replacingOccurrences(of: "\u{00A0}", with: " ")
        let parts = normalized.split(separator: " ").map(String.init)
        if parts.count >= 2 {
            return (parts[0], parts[1])
        }
        return (raw, "")
    }
}

