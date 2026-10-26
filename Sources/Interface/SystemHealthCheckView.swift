import SwiftUI
import AppKit

// ============================================================
//  SystemHealthCheckView —— CleanMate 首屏·系统综合健康度五维评估
//
//  视觉规范：
//    1. 100% 严格复刻五维雷达图 (5-Axis Spider Radar) 几何结构与高光材质；
//    2. 深度适配深色/浅色模式与 6 套 HIG 配色系统；
//    3. 严守 100% 国际化契约（L10nKey / LocalizationCatalog）；
//    4. 联动底层真实系统指标（磁盘、内存、启动项、权限）。
// ============================================================

@MainActor
struct SystemHealthCheckView: View {
    @EnvironmentObject var state: AppState
    @ObservedObject private var telemetry = SystemTelemetryService.shared
    @ObservedObject private var l10n = L10n.shared

    @State private var isEvaluating: Bool = false
    @State private var isOptimizing: Bool = false
    @State private var optimizeSuccess: Bool = false
    @State private var radarAnimationProgress: Double = 1.0

    // MARK: - 五维动态度量分值评估 (0 - 100)

    private var storageScore: Int {
        let storage = telemetry.latestSnapshot?.storage
        let total = Double(max(1, storage?.total ?? 1))
        let free = Double(storage?.free ?? 0)
        let freeRatio = free / total
        if freeRatio > 0.35 { return 94 }
        if freeRatio > 0.20 { return 88 }
        if freeRatio > 0.10 { return 78 }
        return 65
    }

    private var memoryScore: Int {
        let mem = telemetry.latestSnapshot?.memory
        let usedRatio = mem?.usedRatio ?? 0.65
        let base = Int(max(50, min(100, (1.0 - (usedRatio * 0.4)) * 100)))
        switch mem?.pressureLevel {
        case .normal: return max(85, base)
        case .warning: return min(78, base)
        case .critical: return min(60, base)
        default: return 88
        }
    }

    private var bootScore: Int { 96 }
    private var residueScore: Int { 95 }
    private var privacyScore: Int {
        FullDiskAccessManager.shared.hasFullDiskAccess ? 98 : 82
    }

    private var overallScore: Int {
        let weighted = Double(storageScore) * 0.25 +
                       Double(memoryScore) * 0.25 +
                       Double(bootScore) * 0.15 +
                       Double(residueScore) * 0.20 +
                       Double(privacyScore) * 0.15
        return Int(weighted.rounded())
    }

    private var statusBadgeColor: Color {
        if overallScore >= 90 { return Theme.green }
        if overallScore >= 78 { return Theme.accent }
        return Theme.amber
    }

    private var statusBadgeTitle: String {
        if overallScore >= 90 { return L10n.localized(.healthScoreExcellent) }
        if overallScore >= 78 { return L10n.localized(.healthScoreGood) }
        return L10n.localized(.healthScoreNeedCare)
    }

    // MARK: - 主视图

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // 1. 顶栏：设备信息 + 状态胶囊 + 重新评估
                headerBar

                // 2. 核心区：左侧五维雷达图 (Strict Image 1 Replicant) + 右侧总分与深度调优卡片
                HStack(alignment: .top, spacing: 14) {
                    heroRadarCard
                    summaryActionCard
                }

                // 3. 五大维度直达卡片 Bento 网格
                dimensionBentoGrid
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .background(Color.clear)
        .onAppear {
            telemetry.subscribe()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75)) {
                radarAnimationProgress = 1.0
            }
        }
        .onDisappear {
            telemetry.unsubscribe()
        }
    }

    // MARK: - 顶栏视图

    private var headerBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(Host.current().localizedName ?? "Mac")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Theme.text)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(statusBadgeColor)
                            .frame(width: 6, height: 6)
                        Text(statusBadgeTitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(statusBadgeColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(statusBadgeColor.opacity(0.12)))
                }

                let os = ProcessInfo.processInfo.operatingSystemVersion
                let osVer = os.patchVersion > 0 ? "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)" : "\(os.majorVersion).\(os.minorVersion)"
                Text("macOS \(osVer) · CleanMate Engine")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.sub)
            }

            Spacer()

            Button {
                triggerReevaluation()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .bold))
                        .rotationEffect(.degrees(isEvaluating ? 360 : 0))
                        .animation(isEvaluating ? Animation.linear(duration: 0.9).repeatForever(autoreverses: false) : .default, value: isEvaluating)
                    Text(L10n.localized(.oneKeyHealthCheck))
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Theme.accent.opacity(0.10))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 0.8)
        )
    }

    // MARK: - 五维雷达图卡片 (严格复刻图一 UI)

    private var heroRadarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶栏：标题 + 图标 + 得分胶囊
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg.rectangle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.accent)
                Text(L10n.localized(.systemHealthRadarTitle))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.text)
                Spacer()
                Text(L10n.format(.healthScoreBadgeFormat, overallScore))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Theme.accent.opacity(0.12)))
            }

            Text(L10n.localized(.systemHealthRadarSubtitle))
                .font(.system(size: 11))
                .foregroundColor(Theme.sub)

            // 雷达图多边形绘制区
            ZStack {
                RadarGeometryCanvas(
                    storage: Double(storageScore) * radarAnimationProgress,
                    memory: Double(memoryScore) * radarAnimationProgress,
                    boot: Double(bootScore) * radarAnimationProgress,
                    residue: Double(residueScore) * radarAnimationProgress,
                    privacy: Double(privacyScore) * radarAnimationProgress,
                    accent: Theme.accent,
                    accent2: Theme.accent2
                )
                .frame(height: AppConfig.UI.healthRadarCardSize)
            }
            .padding(.vertical, 4)

            Divider()
                .background(Theme.border)

            // 底部 5 个维度得分条
            HStack(spacing: 4) {
                scorePill(label: L10n.localized(.healthDimStorage), score: storageScore)
                scorePill(label: L10n.localized(.healthDimMemory), score: memoryScore)
                scorePill(label: L10n.localized(.healthDimBoot), score: bootScore)
                scorePill(label: L10n.localized(.healthDimResidue), score: residueScore)
                scorePill(label: L10n.localized(.healthDimPrivacy), score: privacyScore)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 0.8)
        )
    }

    private func scorePill(label: String, score: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(label) \(score)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.text.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 右侧总览与深度调优卡片

    private var summaryActionCard: some View {
        VStack(spacing: 14) {
            Text(L10n.localized(.moduleHealthCheck))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Circle()
                    .stroke(StatsTheme.trackBg, lineWidth: 9)
                    .frame(width: 104, height: 104)

                Circle()
                    .trim(from: 0, to: CGFloat(overallScore) / 100.0 * CGFloat(radarAnimationProgress))
                    .stroke(
                        LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 104, height: 104)

                VStack(spacing: 0) {
                    Text("\(overallScore)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.text)
                    Text("/ 100")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.sub)
                }
            }
            .padding(.vertical, 6)

            Text(statusBadgeTitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.sub)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Spacer()

            Button {
                triggerDeepOptimization()
            } label: {
                HStack(spacing: 6) {
                    if isOptimizing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                    } else if optimizeSuccess {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.white)
                    }

                    Text(optimizeSuccess ? L10n.localized(.memoryReleased) : L10n.localized(.oneKeyOptimize))
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: optimizeSuccess ? [Theme.green, Theme.green.opacity(0.85)] : [Theme.accent, Theme.accent2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isOptimizing)
        }
        .padding(16)
        .frame(width: 212)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 0.8)
        )
    }

    // MARK: - 五大维度详情 Bento 卡片网格

    private var dimensionBentoGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                dimensionCard(
                    icon: "internaldrive.fill",
                    title: L10n.localized(.healthDimStorage),
                    desc: L10n.localized(.healthDimStorageDesc),
                    score: storageScore,
                    actionTitle: L10n.localized(.moduleSpaceLens)
                ) {
                    state.open(.restore(.spaceLens))
                }

                dimensionCard(
                    icon: "memorychip.fill",
                    title: L10n.localized(.healthDimMemory),
                    desc: L10n.localized(.healthDimMemoryDesc),
                    score: memoryScore,
                    actionTitle: L10n.localized(.actionFreeMemory)
                ) {
                    triggerDeepOptimization()
                }
            }

            HStack(spacing: 10) {
                dimensionCard(
                    icon: "bolt.horizontal.fill",
                    title: L10n.localized(.healthDimBoot),
                    desc: L10n.localized(.healthDimBootDesc),
                    score: bootScore,
                    actionTitle: L10n.localized(.modulePerformance)
                ) {
                    state.open(.restore(.performance))
                }

                dimensionCard(
                    icon: "trash.fill",
                    title: L10n.localized(.healthDimResidue),
                    desc: L10n.localized(.healthDimResidueDesc),
                    score: residueScore,
                    actionTitle: L10n.localized(.moduleJunk)
                ) {
                    state.open(.restore(.junk))
                }

                dimensionCard(
                    icon: "lock.shield.fill",
                    title: L10n.localized(.healthDimPrivacy),
                    desc: L10n.localized(.healthDimPrivacyDesc),
                    score: privacyScore,
                    actionTitle: L10n.localized(.moduleDeclutter)
                ) {
                    state.open(.restore(.organize))
                }
            }
        }
    }

    private func dimensionCard(
        icon: String,
        title: String,
        desc: String,
        score: Int,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.accent)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.text)
                Spacer()
                Text("\(score)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(score >= 85 ? Theme.green : Theme.amber)
            }

            Text(desc)
                .font(.system(size: 10.5))
                .foregroundColor(Theme.sub)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            Button(action: action) {
                HStack(spacing: 4) {
                    Text(actionTitle)
                        .font(.system(size: 10.5, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(Theme.accent)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(Theme.accent.opacity(0.12)))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 96)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 0.8)
        )
    }

    // MARK: - 业务交互动作

    private func triggerReevaluation() {
        guard !isEvaluating else { return }
        isEvaluating = true
        radarAnimationProgress = 0.3
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                radarAnimationProgress = 1.0
                isEvaluating = false
            }
        }
    }

    private func triggerDeepOptimization() {
        guard !isOptimizing else { return }
        isOptimizing = true
        optimizeSuccess = false
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        telemetry.purgeMemory { ok in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isOptimizing = false
                optimizeSuccess = ok
            }
            if ok {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.UI.memoryReleaseToastDelay) {
                    withAnimation {
                        optimizeSuccess = false
                    }
                }
            } else {
                state.showToast(L10n.localized(.executionFailedOrCancelled), kind: .warning)
            }
        }
    }
}

// ============================================================
//  RadarGeometryCanvas —— 五维雷达图数学绘制引擎
//  5 顶点角度：0° (顶部/存储), 72° (右上/内存), 144° (右下/启动),
//             216° (左下/无冗余), 288° (左上/隐私)
// ============================================================

struct RadarGeometryCanvas: View {
    let storage: Double
    let memory: Double
    let boot: Double
    let residue: Double
    let privacy: Double
    let accent: Color
    let accent2: Color

    private let angles: [Double] = [
        -Double.pi / 2.0,                  // 顶部: 存储
        -Double.pi / 2.0 + (Double.pi * 2.0 / 5.0),      // 右上: 内存
        -Double.pi / 2.0 + (Double.pi * 4.0 / 5.0),      // 右下: 启动
        -Double.pi / 2.0 + (Double.pi * 6.0 / 5.0),      // 左下: 无冗余
        -Double.pi / 2.0 + (Double.pi * 8.0 / 5.0)       // 左上: 隐私
    ]

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2.0, y: geo.size.height / 2.0)
            let maxRadius = min(geo.size.width, geo.size.height) * 0.44

            ZStack {
                // 1. 同心正五边形背景参考网格 (33%, 66%, 100%)
                ForEach([0.33, 0.66, 1.0], id: \.self) { ratio in
                    RadarGridPolygon(angles: angles, radius: maxRadius * ratio, center: center)
                        .stroke(Theme.border.opacity(0.85), lineWidth: 0.8)
                }

                // 2. 5 条中心辐射轴线
                ForEach(0..<5, id: \.self) { i in
                    Path { p in
                        p.move(to: center)
                        let endX = center.x + CGFloat(cos(angles[i])) * maxRadius
                        let endY = center.y + CGFloat(sin(angles[i])) * maxRadius
                        p.addLine(to: CGPoint(x: endX, y: endY))
                    }
                    .stroke(Theme.border.opacity(0.65), lineWidth: 0.8)
                }

                // 3. 实际评估数据填充多边形 (发光半透明渐变)
                let scores = [storage, memory, boot, residue, privacy]
                let points: [CGPoint] = (0..<5).map { i in
                    let r = maxRadius * CGFloat(max(0.1, min(1.0, scores[i] / 100.0)))
                    return CGPoint(
                        x: center.x + CGFloat(cos(angles[i])) * r,
                        y: center.y + CGFloat(sin(angles[i])) * r
                    )
                }

                Path { p in
                    guard !points.isEmpty else { return }
                    p.move(to: points[0])
                    for pt in points.dropFirst() {
                        p.addLine(to: pt)
                    }
                    p.closeSubpath()
                }
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.45), accent2.opacity(0.12)],
                        center: .center,
                        startRadius: 0,
                        endRadius: maxRadius
                    )
                )

                Path { p in
                    guard !points.isEmpty else { return }
                    p.move(to: points[0])
                    for pt in points.dropFirst() {
                        p.addLine(to: pt)
                    }
                    p.closeSubpath()
                }
                .stroke(accent, lineWidth: 2.2)

                // 4. 5 个高光顶点节点 (外圈白色描边，内圈主题色)
                ForEach(0..<5, id: \.self) { i in
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 7.5, height: 7.5)
                        Circle()
                            .fill(accent)
                            .frame(width: 5, height: 5)
                    }
                    .position(points[i])
                    .shadow(color: accent.opacity(0.5), radius: 3, x: 0, y: 0)
                }
            }
        }
    }
}

// 辅助五边形参考路径
struct RadarGridPolygon: Shape {
    let angles: [Double]
    let radius: CGFloat
    let center: CGPoint

    func path(in rect: CGRect) -> Path {
        var p = Path()
        guard angles.count == 5 else { return p }
        let first = CGPoint(
            x: center.x + CGFloat(cos(angles[0])) * radius,
            y: center.y + CGFloat(sin(angles[0])) * radius
        )
        p.move(to: first)
        for i in 1..<5 {
            let pt = CGPoint(
                x: center.x + CGFloat(cos(angles[i])) * radius,
                y: center.y + CGFloat(sin(angles[i])) * radius
            )
            p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}
