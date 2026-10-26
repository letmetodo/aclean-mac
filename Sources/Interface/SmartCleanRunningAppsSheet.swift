import SwiftUI
import AppKit

// MARK: - 运行中 App 前置决策弹窗 (Sheet)

struct SmartCleanRunningAppsSheet: View {
    let apps: [NSRunningApplication]
    let onCancel: () -> Void
    let onSkipAndClean: () -> Void
    let onQuitAndClean: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            runningAppsHeader
            runningAppsList
            runningAppsFooter
        }
        .padding(24)
        .frame(width: AppConfig.UI.runningAppsSheetWidth)
    }

    private var runningAppsHeader: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Theme.amber)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.localized(.runningAppsDetectedTitle))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.text)

                Text(L10n.localized(.runningAppsDetectedSubtitle))
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.sub)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 4)
    }

    private var runningAppsList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(apps, id: \.processIdentifier) { app in
                    runningAppRow(app)
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(maxHeight: AppConfig.UI.runningAppsListMaxHeight)
    }

    @ViewBuilder
    private func runningAppRow(_ app: NSRunningApplication) -> some View {
        HStack(spacing: 12) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.sub)
                    .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.localizedName ?? L10n.localized(.runningAppFallbackName))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.text)
                if let bid = app.bundleIdentifier {
                    Text(bid)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.sub.opacity(0.8))
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(Theme.green)
                    .frame(width: 6, height: 6)
                Text(L10n.localized(.statusRunning))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.green)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Theme.green.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.card.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.sep.opacity(0.6), lineWidth: 0.5)
        )
    }

    private var runningAppsFooter: some View {
        HStack(spacing: 12) {
            Button(L10n.localized(.actionCancel)) {
                onCancel()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button {
                onSkipAndClean()
            } label: {
                Text(L10n.localized(.runningAppSkipAndCleanRest))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(Theme.sep, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button {
                onQuitAndClean()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                    Text(L10n.localized(.runningAppQuitAndClean))
                        .font(.system(size: 12.5, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 6)
    }
}
