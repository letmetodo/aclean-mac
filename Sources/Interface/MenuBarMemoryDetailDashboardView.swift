import SwiftUI
import AppKit

// MARK: - Memory dashboard with pressure, history, and process details

struct MemoryDetailDashboardView: View {
    @ObservedObject var service = SystemTelemetryService.shared
    @ObservedObject var config = MenuBarConfigStore.shared
    @ObservedObject var appConfig = AppConfigStore.shared

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        let snap = service.latestSnapshot
        let mem = snap?.memory
        let total = max(1, mem?.totalBytes ?? Int64(ProcessInfo.processInfo.physicalMemory))
        let used = mem?.usedBytes ?? 0
        let pct = Int(((mem?.usedRatio ?? 0.0) * 100.0).rounded())
        let pressureVal: Double = {
            if let pPct = mem?.pressurePercent, pPct > 0 {
                return min(1.0, max(0.05, Double(pPct) / 100.0))
            }
            return mem?.usedRatio ?? 0.25
        }()

        let memStats = service.memoryRangeStats(for: config.selectedTimeRange)
        let wiredRatio = Double(mem?.wiredBytes ?? 0) / Double(total)
        let appRatio = Double(mem?.appBytes ?? 0) / Double(total)
        let usedRatioNow = max(0.05, mem?.usedRatio ?? 0.4)
        let appShare = min(0.85, max(0.20, appRatio / usedRatioNow))
        let wiredShare = min(0.92, max(appShare + 0.08, (appRatio + wiredRatio) / usedRatioNow))

        let compPts = memStats.points.map { min(0.96, max(0.05, $0 / 100.0)) }
        let wiredPts = compPts.map { $0 * wiredShare }
        let activePts = compPts.map { $0 * appShare }
        let pressureColor: Color = {
            switch mem?.pressureLevel ?? .normal {
            case .normal: return Theme.green
            case .warning: return StatsTheme.thirdColor
            case .critical: return Theme.red
            }
        }()

        return VStack(alignment: .leading, spacing: 6) {
            MenuBarTimeSpanHeader(title: L10n.localized(.memory), selectedRange: $config.selectedTimeRange)

            // 1. PRESSURE 压力环（动态绿/橙/红）+ 分项指标 + Swap/PageI/O
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.localized(.pressurePrefix))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.accent)

                    HStack(spacing: 10) {
                        ZStack {
                            Circle().stroke(StatsTheme.trackBg, lineWidth: 5)
                            Circle().trim(from: 0, to: CGFloat(pressureVal))
                                .stroke(pressureColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            VStack(spacing: 0) {
                                Text("\(Int((pressureVal * 100).rounded()))%")
                                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.text)
                                Text(mem?.pressureLevel.localizedTitle ?? L10n.localized(.statusNormal))
                                    .font(.system(size: 7.5, weight: .semibold))
                                    .foregroundColor(pressureColor)
                            }
                        }
                        .frame(width: 48, height: 48)

                        VStack(spacing: 3) {
                            StatsColorRow(color: Theme.accent, title: L10n.localized(.telemetryMemoryActiveLabel), value: Fmt.size(mem?.appBytes ?? 0), compact: true)
                            StatsColorRow(color: Theme.accent2, title: L10n.localized(.telemetryMemoryWiredLabel), value: Fmt.size(mem?.wiredBytes ?? 0), compact: true)
                            StatsColorRow(color: StatsTheme.thirdColor, title: L10n.localized(.telemetryMemoryCompressedLabel), value: Fmt.size(mem?.compressedBytes ?? 0), compact: true)
                            StatsColorRow(color: Theme.green, title: L10n.localized(.telemetryMemoryCachedLabel), value: Fmt.size(mem?.cacheBytes ?? 0), compact: true)
                        }
                    }

                    Divider().background(Theme.sep)
                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Text(L10n.localized(.menuBarSwapPartitionLabel))
                                .font(.system(size: 8.5))
                                .foregroundColor(Theme.sub)
                            Text(Fmt.size(mem?.swapUsedBytes ?? 0))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor((mem?.swapUsedBytes ?? 0) > 1024 * 1024 * 1024 ? StatsTheme.thirdColor : Theme.text)
                        }
                        Spacer()
                        Text(String(format: "\(L10n.localized(.menuBarPageInsLabel)) %.0f KB/s · \(L10n.localized(.menuBarPageOutsLabel)) %.0f KB/s", mem?.pageInsKBPerSec ?? 0, mem?.pageOutsKBPerSec ?? 0))
                            .font(.system(size: 8.5, design: .monospaced))
                            .foregroundColor(Theme.sub)
                            .lineLimit(1)
                    }
                }
            }

            // 2. 中间 MEMORY 历史堆叠波动图 (含悬停十字准星)
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(L10n.localized(.menuBarMemoryHistoryHeader))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.accent)
                        Spacer()
                        Text("\(Fmt.size(used)) / \(Fmt.size(total)) (\(pct)%)")
                            .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.sub)
                    }

                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 5).fill(StatsTheme.boxBg)
                        MenuBarAreaWaveShape(points: compPts, scale: 1.0)
                            .fill(StatsTheme.thirdColor.opacity(0.30))
                        MenuBarAreaWaveShape(points: wiredPts, scale: 1.0)
                            .fill(Theme.accent2.opacity(0.36))
                        MenuBarAreaWaveShape(points: activePts, scale: 1.0)
                            .fill(Theme.accent.opacity(0.45))
                        MenuBarAreaWaveStrokeShape(points: activePts, scale: 1.0)
                            .stroke(Theme.accent, lineWidth: 1.3)
                        MenuBarWaveHoverOverlay(rawPoints: memStats.points, valueFormat: "%.1f", unitSuffix: "%")
                    }
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                    HStack {
                        memLegendDot(label: L10n.localized(.menuBarLegendActive), color: Theme.accent)
                        Spacer()
                        memLegendDot(label: L10n.localized(.menuBarLegendWired), color: Theme.accent2)
                        Spacer()
                        memLegendDot(label: L10n.localized(.menuBarLegendCompressed), color: StatsTheme.thirdColor)
                        Spacer()
                        memLegendDot(label: L10n.localized(.menuBarLegendFree), color: Theme.green)
                    }
                }
            }

            // 3. PROCESSES
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.localized(.statsSectionTopProcesses))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.accent)

                    let snap = service.latestSnapshot
                    let list = (snap?.topMemoryProcesses.isEmpty == false)
                        ? (snap?.topMemoryProcesses ?? []).prefix(5)
                        : (snap?.topProcesses ?? []).prefix(5)

                    ForEach(list) { proc in
                        HStack(spacing: 8) {
                            if let icon = ProcessIconCache.shared.icon(forAppPath: proc.appPath) {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 14, height: 14)
                            } else {
                                Image(systemName: "app.dashed")
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(Theme.sub)
                            }
                            Text(proc.name)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(Theme.text)
                                .lineLimit(1)
                            Spacer()
                            Text(Fmt.size(proc.residentMemory))
                                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(Theme.accent)
                        }
                        .padding(.vertical, 1)
                    }
                }
            }
        }
    }

    func memLegendDot(label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 5.5, height: 5.5)
            Text(label).font(.system(size: 8.5)).foregroundColor(Theme.sub)
        }
    }
}
