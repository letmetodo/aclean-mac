import SwiftUI
import AppKit

/// 完全磁盘访问权限 (FDA) 优雅引导与无感自动重试面板
struct PermissionSheet: View {
    @ObservedObject private var coordinator = PermissionCoordinator.shared
    @State private var appeared = false
    @State private var pulse = false
    @State private var showAdvanced = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)
            contentBody
            Divider().opacity(0.3)
            footer
        }
        .frame(width: AppConfig.UI.permissionSheetWidth)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: coordinator.hasFullDiskAccess)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    // MARK: - 顶部标头
    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                let tint = coordinator.hasFullDiskAccess ? Color.green : Color.blue
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 42, height: 42)

                Image(systemName: coordinator.hasFullDiskAccess ? "checkmark.shield.fill" : "lock.shield.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(coordinator.context.headline)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.primary)

                Text(coordinator.hasFullDiskAccess ? L10n.localized(.permissionGrantedRetryingPrompt) : L10n.localized(.permissionSheetOneStepSubtitle))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    // MARK: - 主体内容
    @ViewBuilder
    private var contentBody: some View {
        if coordinator.hasFullDiskAccess {
            grantedBody
        } else {
            requestBody
        }
    }

    private var requestBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(coordinator.context.message)
                .font(.system(size: 12))
                .foregroundStyle(Color.secondary)
                .fixedSize(horizontal: false, vertical: true)

            FDADemoView(compact: true)

            // 双窗口协同引导区域（支持直接拖拽图标或一键并排打开）
            HStack(spacing: 16) {
                // 左侧：真实可拖拽 App 图标交互区
                AppBundleDragHandle(compact: true)

                Divider().frame(height: 82)

                // 右侧：一键打开并排窗口与快捷直达按钮
                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        coordinator.openSettingsAndReveal()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 12))
                            Text(L10n.localized(.actionOpenSystemSettingsToApp))
                                .font(.system(size: 12.5, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)

                    Text(L10n.localized(.permissionOpenSideBySideHint))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )

            // 3 步流水线引导
            HStack(spacing: 0) {
                stepCell(number: 1, title: L10n.localized(.permissionStepCheckApp), caption: L10n.localized(.permissionStepEnableFdaDesc))
                stepDivider
                stepCell(number: 2, title: L10n.localized(.labelBiometricAuth), caption: L10n.localized(.permissionStepTouchIdOrPassword))
                stepDivider
                stepCell(number: 3, title: L10n.localized(.labelSeamlessContinue), caption: L10n.localized(.permissionStepAutoRetryDesc))
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.03))
            )

            // 实时轮询监听提示
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 10, height: 10)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                        .scaleEffect(pulse ? 1.4 : 0.8)
                        .opacity(pulse ? 0.4 : 1)
                }

                Text(L10n.localized(.permissionListeningForAuthChangesPrompt))
                    .font(.system(size: 11.5))
                    .foregroundStyle(Color.secondary)

                Spacer()

                Button(showAdvanced ? L10n.localized(.actionCollapseHint) : L10n.localized(.permissionAppNotInListPrompt)) {
                    withAnimation(.easeInOut(duration: 0.25)) { showAdvanced.toggle() }
                }
                .buttonStyle(.link)
                .font(.system(size: 11.5))
            }

            if showAdvanced {
                advancedPanel
            }

            if !coordinator.failedItemPaths.isEmpty {
                blockedList
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    private var grantedBody: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.green)
            }

            Text(L10n.localized(.permissionAuthorizationSuccessTitle))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.primary)

            Text(L10n.localized(.permissionReplayingActionPrompt))
                .font(.system(size: 12))
                .foregroundStyle(Color.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - 高级解决措施
    private var advancedPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.localized(.permissionNotInListTroubleshootingHeader))
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Color.secondary)

            HStack(spacing: 8) {
                Button {
                    FullDiskAccessManager.shared.revealAppInFinder()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text(L10n.localized(.actionLocateAppInFinderButton))
                    }
                    .font(.system(size: 11))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)

                Button {
                    coordinator.resetAndReprime()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text(L10n.localized(.actionResetAndReregisterTcc))
                    }
                    .font(.system(size: 11))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: - 受阻路径列表
    private var blockedList: some View {
        DisclosureGroup(L10n.format(.permissionRestrictedFilePathsFormat, coordinator.failedItemPaths.count)) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(coordinator.failedItemPaths.prefix(5), id: \.self) { path in
                    Text(path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if coordinator.failedItemPaths.count > 5 {
                    Text(L10n.format(.permissionAndMoreFailedPathsFormat, coordinator.failedItemPaths.count - 5))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.secondary.opacity(0.7))
                }
            }
            .padding(.top, 4)
        }
        .font(.system(size: 11.5, weight: .medium))
        .foregroundStyle(Color.secondary)
    }

    private func stepCell(number: Int, title: String, caption: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("\(number)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color.blue))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.primary)
                Text(caption)
                    .font(.system(size: 9.5))
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(width: 0.5, height: 26)
    }

    // MARK: - 底部操作栏
    private var footer: some View {
        HStack {
            Button(L10n.localized(.actionSkipForNow)) {
                coordinator.dismiss(callRetry: false)
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(Color.secondary)

            Spacer()

            if !coordinator.hasFullDiskAccess {
                Button(L10n.localized(.actionAuthorizedAndContinue)) {
                    coordinator.refreshStatus()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if coordinator.hasFullDiskAccess {
                            coordinator.dismiss(callRetry: true)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
    }
}
