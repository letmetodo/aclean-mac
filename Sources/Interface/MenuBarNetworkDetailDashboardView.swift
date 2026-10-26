import SwiftUI
import AppKit

// MARK: - Network dashboard with traffic history, connection details, and processes

struct NetworkDetailDashboardView: View {
    @ObservedObject var service = SystemTelemetryService.shared
    @ObservedObject var geo = IPGeoService.shared
    @ObservedObject var config = MenuBarConfigStore.shared
    @ObservedObject var appConfig = AppConfigStore.shared

    @State private var isPublicIPMasked: Bool = false
    @State private var copiedField: String? = nil

    private func maskIP(_ ip: String) -> String {
        guard isPublicIPMasked else { return ip }
        let parts = ip.split(separator: ".")
        if parts.count == 4 {
            return "\(parts[0]).*.*.\(parts[3])"
        }
        return "•••.•••.•••.•••"
    }

    private func copyToPasteboard(_ text: String, tag: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "—" else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(trimmed, forType: .string)
        withAnimation(.easeInOut(duration: 0.15)) {
            copiedField = tag
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            if copiedField == tag {
                withAnimation(.easeInOut(duration: 0.15)) {
                    copiedField = nil
                }
            }
        }
    }

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        let snap = service.latestSnapshot
        let net = snap?.network
        let detail = net?.detail
        let flag = detail?.countryFlag.isEmpty == false ? detail!.countryFlag : "🌐"

        let netStats = service.netRangeStats(for: config.selectedTimeRange)
        let maxDownKB = max(64.0, netStats.points.max() ?? 64.0)
        let maxUpKB = max(32.0, netStats.secondaryPoints.max() ?? 32.0)
        let downPts = netStats.points.map { min(0.95, max(0.03, $0 / maxDownKB)) }
        let upPts = netStats.secondaryPoints.map { min(0.95, max(0.03, $0 / maxUpKB)) }
        let peakDownBytes = max(net?.peakDownloadBytesPerSec ?? 0, (netStats.points.max() ?? 0) * 1024.0)
        let peakUpBytes = max(net?.peakUploadBytesPerSec ?? 0, (netStats.secondaryPoints.max() ?? 0) * 1024.0)

        return VStack(alignment: .leading, spacing: 6) {
            MenuBarTimeSpanHeader(title: L10n.localized(.network), selectedRange: $config.selectedTimeRange)

            // 1. PUBLIC IP & WI-FI 状态（支持点击复制 IP + 隐私打码 + 延迟）
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Text(L10n.localized(.statsSectionPublicIP))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.accent)
                        if let rtt = detail?.latencyMs {
                            Text("\(rtt) ms")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 4.5)
                                .padding(.vertical, 1)
                                .background(Capsule().fill((rtt < 80 ? Theme.green : StatsTheme.thirdColor).opacity(0.16)))
                                .foregroundColor(rtt < 80 ? Theme.green : StatsTheme.thirdColor)
                        }
                        Spacer()
                        Button {
                            copyToPasteboard(geo.publicIP, tag: "pub")
                        } label: {
                            HStack(spacing: 4) {
                                Circle().fill(Theme.green).frame(width: 6, height: 6)
                                if copiedField == "pub" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 9))
                                        .foregroundColor(Theme.green)
                                    Text(L10n.localized(.assetCopiedToast))
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Theme.green)
                                } else {
                                    Text("\(flag) \(maskIP(geo.publicIP))")
                                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Theme.text)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help(L10n.localized(.menuBarNetworkCopyIpHelp))

                        Button {
                            isPublicIPMasked.toggle()
                        } label: {
                            Image(systemName: isPublicIPMasked ? "eye.slash" : "eye")
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundColor(Theme.sub)
                        }
                        .buttonStyle(.plain)
                        .help(L10n.localized(.menuBarNetworkToggleMaskHelp))
                    }
                    Divider().background(Theme.sep)
                    HStack {
                        Text(detail?.interfaceDisplayName ?? "Wi-Fi (en0)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Theme.sub)
                        Spacer()
                        Button {
                            copyToPasteboard(detail?.localIPv4 ?? "", tag: "lan")
                        } label: {
                            HStack(spacing: 3) {
                                if copiedField == "lan" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 8.5))
                                        .foregroundColor(Theme.green)
                                    Text(L10n.localized(.assetCopiedToast))
                                        .font(.system(size: 8.5, weight: .bold))
                                        .foregroundColor(Theme.green)
                                } else {
                                    Text(detail?.localIPv4 ?? "—")
                                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Theme.text)
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 7.5))
                                        .foregroundColor(Theme.sub)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help(L10n.localized(.menuBarNetworkCopyIpHelp))
                    }
                }
            }

            // 2. 双向流动波形 (红上蓝下) + 上下行双 Peak + 实时速率 + 悬停准星
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(L10n.localized(.statsSectionUsageHistory))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.accent)
                        Spacer()
                        Text("\(L10n.localized(.peakPrefix)) ↑ \(formatSpeed(peakUpBytes)) · ↓ \(formatSpeed(peakDownBytes))")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(Theme.sub)
                            .lineLimit(1)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 5).fill(StatsTheme.boxBg)
                        Rectangle().fill(Theme.sep).frame(height: 0.6)
                        MenuBarBiDirectionalWaveShape(points: upPts, isUp: true)
                            .fill(Theme.red.opacity(0.42))
                        MenuBarBiDirectionalWaveShape(points: downPts, isUp: false)
                            .fill(Theme.accent.opacity(0.42))
                        MenuBarWaveHoverOverlay(rawPoints: netStats.points, valueFormat: "%.1f", unitSuffix: " KB/s")
                    }
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                    HStack {
                        HStack(spacing: 4) {
                            Circle().fill(Theme.red).frame(width: 6, height: 6)
                            Text(L10n.localized(.menuBarUploadTxLabel)).font(.system(size: 8.5, weight: .semibold)).foregroundColor(Theme.sub)
                            Text("\(net?.uploadSpeedText ?? "0 KB/s") ↑")
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.red)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Circle().fill(Theme.accent).frame(width: 6, height: 6)
                            Text(L10n.localized(.menuBarDownloadRxLabel)).font(.system(size: 8.5, weight: .semibold)).foregroundColor(Theme.sub)
                            Text("\(net?.downloadSpeedText ?? "0 KB/s") ↓")
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
            }

            // 3. PROCESSES
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.localized(.statsSectionTopProcesses))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.accent)

                    let procs = snap?.topNetworkProcesses ?? []
                    if procs.isEmpty {
                        Text(L10n.localized(.menuBarNoHighBandwidthAppsPrompt))
                            .font(.system(size: 9.5))
                            .foregroundColor(Theme.sub)
                    } else {
                        ForEach(procs.prefix(5)) { p in
                            HStack(spacing: 6) {
                                if let icon = ProcessIconCache.shared.icon(forAppPath: p.appPath) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                } else {
                                    Image(systemName: "network")
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(Theme.accent)
                                }
                                Text(p.name)
                                    .font(.system(size: 9.5, weight: .medium))
                                    .foregroundColor(Theme.text)
                                    .lineLimit(1)
                                if p.isTunnel {
                                    Text(L10n.localized(.networkTunnelBadge))
                                        .font(.system(size: 7.5, weight: .bold))
                                        .padding(.horizontal, 3.5)
                                        .padding(.vertical, 0.5)
                                        .background(Capsule().fill(Theme.accent.opacity(0.15)))
                                        .foregroundColor(Theme.accent)
                                }
                                Spacer()
                                Text("↑ \(formatSpeed(p.uploadBytesPerSec))")
                                    .font(.system(size: 8.5, design: .monospaced))
                                    .foregroundColor(Theme.red)
                                Text("↓ \(formatSpeed(p.downloadBytesPerSec))")
                                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Theme.accent)
                            }
                            .padding(.vertical, 1)
                        }
                    }
                }
            }
        }
    }

    func formatSpeed(_ bytes: Double) -> String {
        if bytes >= 1024 * 1024 {
            return String(format: "%.1f MB/s", bytes / (1024 * 1024))
        } else if bytes >= 1024 {
            return String(format: "%.1f KB/s", bytes / 1024)
        } else {
            return String(format: "%.0f B/s", max(0, bytes))
        }
    }
}
