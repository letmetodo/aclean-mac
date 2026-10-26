import SwiftUI
import AppKit

// MARK: - 5. 磁盘存储深度仪表盘 (Stats Popup Style)

struct DiskDetailDashboardView: View {
    @ObservedObject var service = SystemTelemetryService.shared
    @ObservedObject var config = MenuBarConfigStore.shared
    @ObservedObject var appConfig = AppConfigStore.shared

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        let snap = service.latestSnapshot
        let st = snap?.storage
        let io = snap?.diskIO
        let total = max(1, st?.total ?? 1)
        let free = st?.free ?? 0
        let purgeable = st?.purgeable ?? 0
        let used = max(0, total - free)
        let usedPct = Int(((st?.usedRatio ?? 0) * 100).rounded())
        let stats = service.diskRangeStats(for: config.selectedTimeRange)

        return VStack(alignment: .leading, spacing: 6) {
            MenuBarTimeSpanHeader(title: L10n.localized(.cardTitleDiskStorageShort), selectedRange: $config.selectedTimeRange)

            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 12) {
                        StatsPieChartView(
                            segments: [
                                .init(value: max(0, Double(used - purgeable) / Double(total)), color: StatsTheme.secondColor),
                                .init(value: Double(purgeable) / Double(total), color: StatsTheme.thirdColor)
                            ],
                            nonUsageColor: StatsTheme.idleTrackColor,
                            centerTitle: "\(usedPct)%",
                            centerSubtitle: L10n.localized(.menuBarMacintoshHdLocalTitle),
                            lineWidth: 7.5
                        )
                        .frame(width: 68, height: 68)

                        VStack(alignment: .leading, spacing: 3.5) {
                            StatsColorRow(color: StatsTheme.secondColor, title: L10n.localized(.usedLabel), value: Fmt.size(used))
                            StatsColorRow(color: StatsTheme.thirdColor, title: L10n.localized(.scannerApfsPurgeableSpace), value: Fmt.size(purgeable))
                            StatsColorRow(color: StatsTheme.idleTrackColor, title: L10n.localized(.labelFreeAvailable), value: Fmt.size(free))
                        }
                    }

                    SegmentedStackedBarView(
                        segments: [
                            .init(title: L10n.localized(.usedLabel), bytes: max(0, used - purgeable), color: StatsTheme.secondColor),
                            .init(title: L10n.localized(.scannerApfsPurgeableSpace), bytes: purgeable, color: StatsTheme.thirdColor),
                            .init(title: L10n.localized(.labelFreeAvailable), bytes: free, color: StatsTheme.idleTrackColor)
                        ],
                        totalBytes: total
                    )
                    .frame(height: 5.5)
                }
            }

            // 2. 磁盘读写双曲线波形图 (读和写两条线 + 悬浮准星与双路速率)
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(L10n.localized(.statsSectionDiskIO))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.accent)
                        Spacer()
                        HStack(spacing: 8) {
                            HStack(spacing: 3.5) {
                                Circle().fill(Theme.accent).frame(width: 5.5, height: 5.5)
                                Text(L10n.localized(.menuBarReadSpeedPrefixFormat, String(format: "%.2f MB/s", io?.readMBPerSec ?? 0)))
                                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Theme.text)
                            }
                            HStack(spacing: 3.5) {
                                Circle().fill(Color.orange).frame(width: 5.5, height: 5.5)
                                Text(L10n.localized(.menuBarWriteSpeedPrefixFormat, String(format: "%.2f MB/s", io?.writeMBPerSec ?? 0)))
                                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Theme.text)
                            }
                        }
                    }

                    DualStreamWaveView(
                        primaryData: stats.points,
                        secondaryData: stats.secondaryPoints,
                        primaryColor: Theme.accent,
                        secondaryColor: Color.orange,
                        isSpeedMB: true
                    )
                    .frame(height: 48)
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 5).fill(StatsTheme.boxBg))
                }
            }

            // 3. 高负载应用展示 (对标 CPU 与内存模块)
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(L10n.localized(.statsSectionTopProcesses))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.accent)
                        Spacer()
                        Button {
                            _ = Shell.run("/usr/bin/open", ["-a", "Activity Monitor"])
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(Theme.sub)
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .help(L10n.localized(.actionOpenActivityMonitorHelp))
                    }

                    let diskActive = (snap?.topDiskProcesses ?? []).filter { $0.readBytesPerSec > 0 || $0.writeBytesPerSec > 0 }
                    if !diskActive.isEmpty {
                        ForEach(diskActive.prefix(5)) { p in
                            HStack(spacing: 6) {
                                if let icon = ProcessIconCache.shared.icon(forAppPath: p.appPath) {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 14, height: 14)
                                } else {
                                    Image(systemName: "internaldrive")
                                        .frame(width: 14, height: 14)
                                        .foregroundColor(Theme.sub)
                                }
                                Text(p.name)
                                    .font(.system(size: 9.5, weight: .medium))
                                    .foregroundColor(Theme.text)
                                    .lineLimit(1)
                                Spacer()
                                Text("R: \(formatRate(p.readBytesPerSec))")
                                    .font(.system(size: 8.5, design: .monospaced))
                                    .foregroundColor(Theme.accent)
                                Text("W: \(formatRate(p.writeBytesPerSec))")
                                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color.orange)
                            }
                            .padding(.vertical, 1)
                        }
                    } else {
                        let topList = (snap?.topProcesses ?? []).prefix(5)
                        ForEach(topList) { proc in
                            ProcessRowView(proc: proc)
                        }
                    }
                }
            }
        }
    }

    private func formatRate(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1024 * 1024 {
            return String(format: "%.1f MB/s", bytesPerSec / (1024 * 1024))
        } else if bytesPerSec >= 1024 {
            return String(format: "%.0f KB/s", bytesPerSec / 1024)
        } else {
            return String(format: "%.0f B/s", max(0, bytesPerSec))
        }
    }
}
