import AppKit
import SwiftUI

// First-run permission guide and setup flow. The views are implemented with
// SwiftUI and system-provided imagery.

/// 可直接拖拽至「系统设置 → 完全磁盘访问权限」列表的应用图标组件
struct AppBundleDragHandle: View {
    var compact: Bool = false
    @State private var hovering = false
    @ObservedObject private var l10n = L10n.shared

    private var bundleURL: URL {
        Bundle.main.bundleURL
    }

    var body: some View {
        let boxSize: CGFloat = compact ? 74 : 84
        let iconSize: CGFloat = compact ? 50 : 56
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(hovering ? 0.10 : 0.05))
                    .frame(width: boxSize, height: boxSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                hovering ? Theme.accent.opacity(0.65) : Color.primary.opacity(0.12),
                                style: StrokeStyle(
                                    lineWidth: hovering ? 1.5 : 1.0,
                                    dash: hovering ? [] : [4, 3]
                                )
                            )
                    )

                appIcon
                    .frame(width: iconSize, height: iconSize)
                    .scaleEffect(hovering ? 1.05 : 1.0)
                    .shadow(
                        color: .black.opacity(hovering ? 0.18 : 0.08),
                        radius: hovering ? 8 : 4,
                        y: hovering ? 3 : 1
                    )
            }
            .animation(.easeOut(duration: 0.18), value: hovering)

            VStack(spacing: 1) {
                Text(L10n.localized(.appBrandName))
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Text(L10n.localized(.onboardingDragAppToListHint))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
            }
        }
        .padding(compact ? 6 : 10)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onHover { hovering = $0 }
        .help(L10n.localized(.onboardingDragIconTooltip))
        .onDrag {
            let provider = NSItemProvider(object: bundleURL as NSURL)
            provider.suggestedName = bundleURL.lastPathComponent
            return provider
        }
    }

    @ViewBuilder
    private var appIcon: some View {
        if let icon = NSApp.applicationIconImage {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        } else {
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(Theme.accent)
        }
    }
}

/// 纯 SwiftUI 模拟「系统设置 → 完全磁盘访问权限」开关拨动动效卡片
struct FDADemoView: View {
    enum Frame: Int, CaseIterable {
        case idle
        case highlight
        case toggleOn
        case granted
        case hold
    }

    var compact: Bool = false
    @State private var frame: Frame = .idle
    @State private var isActive = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var l10n = L10n.shared

    private var isToggleOn: Bool {
        frame == .toggleOn || frame == .granted || frame == .hold
    }

    private var isSucceeded: Bool {
        frame == .granted || frame == .hold
    }

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            VStack(spacing: 0) {
                // 模拟系统设置顶栏
                HStack(spacing: 6) {
                    Circle().fill(Color(red: 1.0, green: 0.36, blue: 0.34)).frame(width: 8, height: 8)
                    Circle().fill(Color(red: 1.0, green: 0.78, blue: 0.27)).frame(width: 8, height: 8)
                    Circle().fill(Color(red: 0.31, green: 0.78, blue: 0.36)).frame(width: 8, height: 8)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 10))
                        Text(L10n.localized(.onboardingDemoPathHint))
                            .font(.system(size: 10.5, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.04))

                Divider().opacity(0.4)

                // CleanMate 授权开关演示行
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Theme.accent.opacity(0.16))
                            .frame(width: 28, height: 28)
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }

                    Text(L10n.localized(.appBrandName))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary)

                    Spacer()

                    if isSucceeded {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.green)
                            .transition(.scale.combined(with: .opacity))
                    }

                    fauxSwitch(isOn: isToggleOn, emphasized: frame == .highlight)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, compact ? 8 : 10)
                .background(frame == .highlight ? Theme.accent.opacity(0.08) : Color.clear)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.8)
            )
        }
        .onAppear {
            if reduceMotion {
                frame = .hold
                return
            }
            isActive = true
            cycle()
        }
        .onDisappear {
            isActive = false
        }
    }

    private func fauxSwitch(isOn: Bool, emphasized: Bool) -> some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Theme.accent : Color.primary.opacity(0.18))
                .frame(width: 34, height: 20)
                .overlay(
                    Capsule()
                        .strokeBorder(Theme.accent.opacity(emphasized ? 0.85 : 0), lineWidth: 2)
                        .scaleEffect(emphasized ? 1.14 : 1.0)
                )
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                .shadow(color: .black.opacity(0.18), radius: 1, y: 1)
                .padding(.horizontal, 2)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.78), value: isOn)
        .animation(.easeInOut(duration: 0.25), value: emphasized)
    }

    private func cycle() {
        let schedule: [(Frame, Double)] = [
            (.idle, 0.7),
            (.highlight, 0.8),
            (.toggleOn, 0.6),
            (.granted, 1.3),
            (.hold, 1.0)
        ]

        var cumulative: Double = 0
        for (target, duration) in schedule {
            DispatchQueue.main.asyncAfter(deadline: .now() + cumulative) {
                guard isActive else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    frame = target
                }
            }
            cumulative += duration
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + cumulative) {
            guard isActive else { return }
            cycle()
        }
    }
}

/// 首次安装 3 步引导主视图
struct OnboardingView: View {
    @EnvironmentObject var state: AppState
    @ObservedObject private var coordinator = PermissionCoordinator.shared
    @ObservedObject private var config = AppConfigStore.shared
    @ObservedObject private var l10n = L10n.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum Step: Int, CaseIterable {
        case welcome = 0
        case permission = 1
        case ready = 2
    }

    @State private var step: Step
    @State private var direction: Int = 1
    @State private var hasOpenedSettings = false
    @State private var autoAdvanceScheduled = false

    private let pollTimer = Timer.publish(
        every: AppConfig.UI.permissionPollIntervalSeconds,
        on: .main,
        in: .common
    ).autoconnect()

    init() {
        let awaitingRelaunch = UserDefaults.standard.bool(forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch)
        let fdaGranted = FullDiskAccessManager.shared.hasFullDiskAccess
        if awaitingRelaunch {
            _step = State(initialValue: fdaGranted ? .ready : .permission)
        } else {
            _step = State(initialValue: .welcome)
        }
    }

    private var hasFda: Bool {
        coordinator.hasFullDiskAccess || state.hasFullDiskAccess
    }

    var body: some View {
        ZStack {
            // 全屏半透明毛玻璃遮罩背景
            Color.black.opacity(Theme.isDark ? 0.55 : 0.32)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 34)
                    .padding(.vertical, 12)
                    .id(step)
                    .transition(pageTransition)

                Divider().opacity(0.35)

                bottomBar
                    .padding(.horizontal, 28)
                    .padding(.vertical, 16)
            }
            .frame(
                width: AppConfig.UI.onboardingWidth,
                height: AppConfig.UI.onboardingHeight
            )
            .background(
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                    RadialGradient(
                        colors: [stepTint.opacity(0.16), .clear],
                        center: .topTrailing,
                        startRadius: 40,
                        endRadius: 460
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 28, y: 12)
        }
        .onAppear {
            FullDiskAccessManager.shared.triggerRegistration()
            coordinator.refreshStatus()
            state.checkFullDiskAccess(force: true)
        }
        .onReceive(pollTimer) { _ in
            if step == .permission {
                coordinator.refreshStatus()
                checkAutoAdvanceIfGranted()
            }
        }
        .onChange(of: coordinator.hasFullDiskAccess) { granted in
            if granted {
                checkAutoAdvanceIfGranted()
            }
        }
    }

    private var stepTint: Color {
        switch step {
        case .welcome: return Theme.accent
        case .permission: return hasFda ? Theme.green : Theme.amber
        case .ready: return Theme.green
        }
    }

    private var pageTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        return .asymmetric(
            insertion: .offset(x: direction >= 0 ? 40 : -40).combined(with: .opacity),
            removal: .offset(x: direction >= 0 ? -40 : 40).combined(with: .opacity)
        )
    }

    // MARK: - 顶栏（步骤指示与跳过按钮）

    private var topBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text(L10n.localized(.onboardingSafetyContractBadge))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.primary.opacity(0.05)))

            Spacer()

            Button {
                state.completeOnboarding(startFirstScan: false)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.secondary.opacity(0.75))
            }
            .buttonStyle(.plain)
            .help(L10n.localized(.actionSkipForNow))
        }
    }

    // MARK: - 3 步主体内容

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            welcomeScene
        case .permission:
            permissionScene
        case .ready:
            readyScene
        }
    }

    // Step 1: 欢迎与核心能力概览
    private var welcomeScene: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            VStack(spacing: 10) {
                if let icon = NSApp.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 76, height: 76)
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 5)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }

                Text(L10n.localized(.onboardingWelcomeTitle))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)

                Text(L10n.localized(.onboardingWelcomeSubtitle))
                    .font(.system(size: 13.5))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }

            VStack(spacing: 10) {
                featureRow(
                    icon: "sparkles",
                    tint: Color(red: 0.20, green: 0.60, blue: 0.98),
                    title: L10n.localized(.onboardingFeatureSmartCleanTitle),
                    desc: L10n.localized(.onboardingFeatureSmartCleanDesc)
                )
                featureRow(
                    icon: "trash.slash.fill",
                    tint: Color(red: 0.62, green: 0.36, blue: 0.96),
                    title: L10n.localized(.onboardingFeatureUninstallerTitle),
                    desc: L10n.localized(.onboardingFeatureUninstallerDesc)
                )
                featureRow(
                    icon: "chart.pie.fill",
                    tint: Color(red: 0.18, green: 0.76, blue: 0.52),
                    title: L10n.localized(.onboardingFeatureSpaceLensTitle),
                    desc: L10n.localized(.onboardingFeatureSpaceLensDesc)
                )
            }
            .frame(maxWidth: 520)

            Spacer(minLength: 0)
        }
    }

    private func featureRow(icon: String, tint: Color, title: String, desc: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        )
    }

    // Step 2: 核心权限一键引导（拖拽图标 + 双窗口并排 + 模拟开关演示）
    private var permissionScene: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            VStack(spacing: 6) {
                Text(L10n.localized(hasFda ? .onboardingPermissionGrantedTitle : .onboardingPermissionStepTitle))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.center)

                Text(L10n.localized(hasFda ? .onboardingPermissionGrantedSubtitle : .onboardingPermissionStepSubtitle))
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }

            FDADemoView()
                .frame(maxWidth: 480)

            if hasFda {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.green)
                    Text(L10n.localized(.onboardingAutoAdvancingPrompt))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.green)
                }
                .padding(.vertical, 12)
                .transition(.scale.combined(with: .opacity))
            } else {
                HStack(alignment: .center, spacing: 18) {
                    // 左侧：可拖拽 App 图标
                    AppBundleDragHandle()

                    Divider().frame(height: 92)

                    // 右侧：快捷操作按钮组
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            openSettingsFromOnboarding()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 12.5))
                                Text(L10n.localized(hasOpenedSettings ? .onboardingReopenSettingsAction : .actionOpenSystemSettingsToApp))
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        HStack(spacing: 12) {
                            Button {
                                FullDiskAccessManager.shared.revealAppInFinder()
                            } label: {
                                Label(L10n.localized(.actionLocateAppInFinderButton), systemImage: "folder")
                                    .font(.system(size: 11.5))
                            }
                            .buttonStyle(.link)

                            Button {
                                coordinator.resetAndReprime()
                            } label: {
                                Label(L10n.localized(.actionResetAndReregisterTcc), systemImage: "arrow.clockwise")
                                    .font(.system(size: 11.5))
                            }
                            .buttonStyle(.link)
                        }

                        Text(L10n.localized(.permissionOpenSideBySideHint))
                            .font(.system(size: 11))
                            .foregroundStyle(Color.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 310)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.035))
                )
            }

            Spacer(minLength: 0)
        }
    }

    // Step 3: 准备就绪与菜单栏快捷开关
    private var readyScene: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill((hasFda ? Theme.green : Theme.amber).opacity(0.14))
                    .frame(width: 88, height: 88)
                Image(systemName: hasFda ? "checkmark.shield.fill" : "hand.wave.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(hasFda ? Theme.green : Theme.amber)
            }

            VStack(spacing: 8) {
                Text(L10n.localized(hasFda ? .onboardingReadyTitleGranted : .onboardingReadyTitleLimited))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)

                Text(L10n.localized(hasFda ? .onboardingReadyDescGranted : .onboardingReadyDescLimited))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }

            // 菜单栏常驻实时监控快捷开关卡片
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Theme.accent.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: "menubar.rectangle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.localized(.onboardingMenuBarQuickToggleTitle))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    Text(L10n.localized(.onboardingMenuBarQuickToggleDesc))
                        .font(.system(size: 11.5))
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                Toggle("", isOn: $config.menuBarMonitor)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
            .padding(14)
            .frame(maxWidth: 480)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )

            if !hasFda {
                Button {
                    advance(to: .permission)
                } label: {
                    Label(L10n.localized(.permissionGrantFullDiskAccessTitle), systemImage: "lock.open.fill")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.link)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - 底栏导航

    private var bottomBar: some View {
        HStack {
            if step == .welcome {
                Button(L10n.localized(.actionSkipForNow)) {
                    state.completeOnboarding(startFirstScan: false)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12.5))
                .foregroundStyle(Color.secondary)
            } else {
                Button(L10n.localized(.onboardingActionBack)) {
                    if let prev = Step(rawValue: step.rawValue - 1) {
                        advance(to: prev)
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12.5))
                .foregroundStyle(Color.secondary)
            }

            Spacer()

            // 步骤胶囊指示器
            HStack(spacing: 6) {
                ForEach(Step.allCases, id: \.rawValue) { s in
                    Capsule()
                        .fill(s == step ? Theme.accent : Color.primary.opacity(0.16))
                        .frame(width: s == step ? 20 : 7, height: 7)
                        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: step)
                }
            }

            Spacer()

            switch step {
            case .welcome:
                Button {
                    advance(to: hasFda ? .ready : .permission)
                } label: {
                    Text(L10n.localized(.onboardingActionNext))
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            case .permission:
                HStack(spacing: 10) {
                    if !hasFda {
                        Button(L10n.localized(.actionSkipForNow)) {
                            advance(to: .ready)
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12.5))
                        .foregroundStyle(Color.secondary)
                    }

                    Button {
                        coordinator.refreshStatus()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            advance(to: .ready)
                        }
                    } label: {
                        Text(L10n.localized(hasFda ? .onboardingActionNext : .actionAuthorizedAndContinue))
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

            case .ready:
                Button {
                    state.completeOnboarding(startFirstScan: true)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text(L10n.localized(.onboardingActionStartFirstScan))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }

    // MARK: - 动作辅助

    private func advance(to target: Step) {
        guard target != step else { return }
        direction = target.rawValue >= step.rawValue ? 1 : -1
        if target == .permission {
            UserDefaults.standard.set(true, forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch)
        } else if target == .ready {
            UserDefaults.standard.set(false, forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch)
        }
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85)) {
            step = target
        }
    }

    private func openSettingsFromOnboarding() {
        UserDefaults.standard.set(true, forKey: AppConfig.StorageKeys.onboardingAwaitingFdaRelaunch)
        coordinator.openSettingsAndReveal()
        withAnimation(.easeInOut(duration: 0.25)) {
            hasOpenedSettings = true
        }
    }

    private func checkAutoAdvanceIfGranted() {
        guard hasFda, step == .permission, !autoAdvanceScheduled else { return }
        autoAdvanceScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.UI.permissionAutoAdvanceDelaySeconds) {
            guard step == .permission else {
                autoAdvanceScheduled = false
                return
            }
            advance(to: .ready)
            autoAdvanceScheduled = false
        }
    }
}
