import SwiftUI
import AppKit

extension SmartCleanView {
    /// 扫描状态行：在基础状态文字后追加预计剩余时间。
    /// ETA 不可信（样本不足 / 停止中）时不追加，避免给出误导性倒计时。
    var scanStatusLine: String {
        let base = state.scanStatus.isEmpty ? L10n.localized(.scanningSystemAppCaches) : state.scanStatus
        guard let eta = state.scanETA, !state.isStoppingScan else { return base }
        return "\(base) · \(EtaText.describe(eta))"
    }
    // MARK: - 0. 顶部统一标题栏（与系统监控完全对齐的左上角标题与规格副标题）

    var topHeaderStrip: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.localized(.moduleJunkAlt))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.text)

                if state.roots.isEmpty {
                    Text(L10n.localized(.smartCleanHeroSubtitle))
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                }
            }

            Spacer(minLength: 12)

            if !state.roots.isEmpty {
                HeaderIconButton(
                    icon: "arrow.clockwise",
                    spinning: state.scanning,
                    helpText: L10n.localized(.actionRescan)
                ) {
                    inspectingSectionKind = nil
                    state.didApplyDefaultsCurrentModule = false
                    state.startScan(for: "junk", forceRestart: true)
                }
            }
        }
    }

    // MARK: - 第一幕：待命态 (Act 1: Idle Stage)

    var cleanIdleStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Spacer(minLength: 6)

                    // 1. 核心悬浮脉冲球体（带垃圾桶图标与微光呼吸动效）
                    PulseOrbStageView(
                        isScanning: false,
                        sizeText: "",
                        unitText: "",
                        subtitle: L10n.localized(.statusReady),
                        themeColor: Theme.accent,
                        diameter: 140,
                        symbol: "trash.fill"
                    )

                    // 2. 标题与说明副标题
                    VStack(spacing: 6) {
                        Text(L10n.localized(.keepYourMacRunningLikeNew))
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.text)

                        Text(L10n.localized(.smartScanAllJunkSubtitle))
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.sub)
                    }

                    // 3. 4 大清理能力 Bento 预览微卡片（统一布局与微卡片设计）
                    HStack(spacing: 12) {
                        IdleJunkFeatureCard(
                            title: L10n.localized(.junkAppCachesAndLogs),
                            tag: L10n.localized(.categoryDailyAppsAndSystem),
                            subtitle: L10n.localized(.categoryDailyAppsAndSystemDesc),
                            systemName: "app.badge.checkmark",
                            primaryColor: Color(red: 0.25, green: 0.65, blue: 0.98),
                            secondaryColor: Color(red: 0.12, green: 0.45, blue: 0.88)
                        )

                        IdleJunkFeatureCard(
                            title: L10n.localized(.categoryDevAndBuildCaches),
                            tag: L10n.localized(.categoryXcodeAndPackageManagers),
                            subtitle: L10n.localized(.categoryXcodeAndPackageManagersDesc),
                            systemName: "hammer.fill",
                            primaryColor: Color(red: 0.98, green: 0.62, blue: 0.18),
                            secondaryColor: Color(red: 0.88, green: 0.42, blue: 0.08)
                        )

                        IdleJunkFeatureCard(
                            title: L10n.localized(.categoryMessagingAndSocialMedia),
                            tag: L10n.localized(.categoryExpiredChatFiles),
                            subtitle: L10n.localized(.categoryMessagingDeepScanDesc),
                            systemName: "bubble.left.and.bubble.right.fill",
                            primaryColor: Color(red: 0.20, green: 0.78, blue: 0.50),
                            secondaryColor: Color(red: 0.10, green: 0.58, blue: 0.35)
                        )

                        IdleJunkFeatureCard(
                            title: L10n.localized(.categoryAiAndDesignCaches),
                            tag: L10n.localized(.categoryModelsAndDesignAssets),
                            subtitle: L10n.localized(.categoryAiAndDesignCachesDesc),
                            systemName: "wand.and.stars",
                            primaryColor: Color(red: 0.66, green: 0.36, blue: 0.96),
                            secondaryColor: Color(red: 0.46, green: 0.20, blue: 0.86)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 2)

                    // 4. 底部主操作按钮（统一风格与位置）
                    HStack(spacing: 14) {
                        GlowingPillButton(
                            title: L10n.localized(.actionStartSmartScan),
                            icon: "sparkles",
                            tint: Theme.accent,
                            width: 184,
                            height: 42
                        ) {
                            state.didApplyDefaultsCurrentModule = false
                            state.startScan(for: "junk", forceRestart: true)
                        }
                    }
                    .padding(.top, 4)

                    // 5. 安全保障标语（统一安全说明）
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.accent.opacity(0.85))
                        Text(L10n.localized(.securitySandboxProtectionNote))
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.tert)
                    }
                    .padding(.top, 2)

                    if !state.hasFullDiskAccess {
                        fdaCompactBanner
                            .frame(maxWidth: AppConfig.UI.cleaningStageContentMaxWidth)
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 8)
                }
                .frame(maxWidth: .infinity, minHeight: AppConfig.UI.cleaningIdleMinHeight)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 第二幕：扫描中 (Act 2: Scanning Stage)

    var cleanScanningStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 6)

            VStack(spacing: 20) {
                Spacer()

                PulseOrbStageView(
                    isScanning: true,
                    sizeText: "\(Int(state.scanProgress * 100))",
                    unitText: "%",
                    subtitle: L10n.localized(.statusDeepScanning),
                    themeColor: Theme.accent,
                    diameter: 170
                )

                VStack(spacing: 8) {
                    Text(state.isStoppingScan ? L10n.localized(.statusStopping) : L10n.localized(.scanningEntireDiskEllipsis))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)

                    Text(scanStatusLine)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: AppConfig.UI.cleaningStageContentMaxWidth)
                }

                Button {
                    state.stopScan()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 12))
                        Text(state.isStoppingScan ? L10n.localized(.statusStopping) : L10n.localized(.actionStopScanning))
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .foregroundStyle(Theme.sub)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Theme.card.opacity(0.8))
                            .overlay(Capsule().strokeBorder(Theme.sep, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .disabled(state.isStoppingScan)
                .padding(.top, 2)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
        }
    }

    // MARK: - 清理中 (Cleaning Stage)

    var cleanCleaningStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 6)

            VStack(spacing: 20) {
                Spacer()

                PulseOrbStageView(
                    isScanning: !state.cleanupPaused,
                    sizeText: "\(Int(state.cleanProgress * 100))",
                    unitText: "%",
                    subtitle: "\(state.cleanDone) / \(state.cleanTotal)",
                    themeColor: Theme.accent,
                    diameter: 170
                )

                VStack(spacing: 10) {
                    Text(state.cleanupPaused
                         ? L10n.localized(.statusCleaningPaused)
                         : L10n.localized(.statusCleaning))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)

                    Text(state.cleanCurrent.isEmpty ? L10n.localized(.statusCleaning) : state.cleanCurrent)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: AppConfig.UI.cleaningStageContentMaxWidth)
                }

                HStack(spacing: 10) {
                    Button {
                        if state.cleanupPaused {
                            state.cleanCoordinator.resumeCleanup()
                            state.cleanupPaused = false
                        } else {
                            state.cleanCoordinator.pauseCleanup()
                            state.cleanupPaused = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: state.cleanupPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 12))
                            Text(state.cleanupPaused
                                 ? L10n.localized(.actionResumeCleaning)
                                 : L10n.localized(.actionPauseCleaning))
                                .font(.system(size: 12.5, weight: .semibold))
                        }
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Theme.card.opacity(0.8))
                                .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                    .help(L10n.localized(.statusPauseTakesEffectAfterCurrentItem))
                    .accessibilityHint(L10n.localized(.statusPauseTakesEffectAfterCurrentItem))

                    Button {
                        state.stopClean()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 12))
                            Text(L10n.localized(.actionStopCleaning))
                                .font(.system(size: 12.5, weight: .semibold))
                        }
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Theme.card.opacity(0.8))
                                .overlay(Capsule().strokeBorder(Theme.sep, lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
    }
}
