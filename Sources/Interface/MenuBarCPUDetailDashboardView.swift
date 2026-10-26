import SwiftUI
import AppKit

// MARK: - CPU dashboard with selectable history intervals, per-core activity, processes, and load average

struct CpuDetailDashboardView: View {
    @ObservedObject var service = SystemTelemetryService.shared
    @ObservedObject var config = MenuBarConfigStore.shared
    @ObservedObject var appConfig = AppConfigStore.shared

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        let snap = service.latestSnapshot
        let cpu = snap?.cpu
        let totalRatio = cpu?.totalUsage ?? 0.0
        let userRatio = cpu?.userUsage ?? 0.0
        let sysRatio = cpu?.systemUsage ?? 0.0
        let userPct = Int((userRatio * 100.0).rounded())
        let sysPct = Int((sysRatio * 100.0).rounded())
        let idlePct = max(0, 100 - userPct - sysPct)

        let cpuStats = service.cpuRangeStats(for: config.selectedTimeRange)
        let loadStats = service.cpuLoadRangeStats(for: config.selectedTimeRange)

        let uPts = cpuStats.points.map { min(0.95, max(0.03, $0 / 100.0)) }
        let sPts = cpuStats.secondaryPoints.map { min(0.95, max(0.02, $0 / 100.0)) }
        let maxLoadRef = max(2.0, loadStats.peak, cpu?.peakLoad ?? 2.0)
        let loadPts = loadStats.points.map { min(0.95, max(0.03, $0 / maxLoadRef)) }

        let coreUsages = (cpu?.coreUsages.isEmpty == false)
            ? Array(cpu!.coreUsages.prefix(12))
            : Array(repeating: totalRatio, count: 8)
        let pCount = cpu?.pCoreCount ?? 4
        let eCount = cpu?.eCoreCount ?? max(0, coreUsages.count - pCount)
        let sysShare = totalRatio > 0.01 ? min(0.85, max(0.15, sysRatio / totalRatio)) : 0.30
        let gpuRatio = min(1.0, max(0.0, (snap?.gpu.usagePercent ?? 0.0) / 100.0))
        let gpuUsagePct = Int((snap?.gpu.usagePercent ?? 0.0).rounded())

        return VStack(alignment: .leading, spacing: 6) {
            MenuBarTimeSpanHeader(title: L10n.localized(.menuBarCpuShort), selectedRange: $config.selectedTimeRange)

            // 1. CPU 堆叠波形 + 核心柱阵 + User/System/Idle + GPU/温度
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(L10n.localized(.menuBarCpuShort))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.accent)
                        Text(L10n.format(.menuBarCoreCountsFormat, pCount, eCount))
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(StatsTheme.boxBg))
                            .foregroundColor(Theme.sub)
                        Spacer()
                        Text(L10n.format(.menuBarAvgPeakUsageFormat, cpuStats.average, cpuStats.peak))
                            .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.sub)
                    }

                    HStack(spacing: 6) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 5).fill(StatsTheme.boxBg)
                            MenuBarAreaWaveShape(points: uPts, scale: 1.0)
                                .fill(Theme.accent.opacity(0.32))
                            MenuBarAreaWaveStrokeShape(points: uPts, scale: 1.0)
                                .stroke(Theme.accent, lineWidth: 1.3)
                            MenuBarAreaWaveShape(points: sPts, scale: 1.0)
                                .fill(Theme.red.opacity(0.38))
                            MenuBarAreaWaveStrokeShape(points: sPts, scale: 1.0)
                                .stroke(Theme.red, lineWidth: 1.2)
                            MenuBarWaveHoverOverlay(rawPoints: cpuStats.points, valueFormat: "%.1f", unitSuffix: "%")
                        }
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(0..<coreUsages.count, id: \.self) { i in
                                let totalVal = min(1.0, max(0.04, coreUsages[i]))
                                let isPCore = i < pCount
                                let sVal = totalVal * sysShare
                                let uVal = totalVal * (1.0 - sysShare)
                                ZStack(alignment: .bottom) {
                                    Capsule().fill(StatsTheme.trackBg).frame(width: 5, height: 42)
                                    VStack(spacing: 0) {
                                        Capsule().fill(Theme.red).frame(width: 5, height: max(1.5, 42 * CGFloat(sVal)))
                                        Capsule().fill(isPCore ? Theme.accent : Theme.green).frame(width: 5, height: max(1.5, 42 * CGFloat(uVal)))
                                    }
                                }
                            }
                        }
                        .padding(4)
                        .frame(width: 86, height: 52)
                        .background(RoundedRectangle(cornerRadius: 5).fill(StatsTheme.boxBg))
                    }

                    HStack {
                        HStack(spacing: 4) {
                            Circle().fill(Theme.accent).frame(width: 6, height: 6)
                            Text(L10n.localized(.userPrefix)).font(.system(size: 8.5, weight: .semibold)).foregroundColor(Theme.sub)
                            Text("\(userPct)%").font(.system(size: 9.5, weight: .bold, design: .monospaced)).foregroundColor(Theme.text)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Circle().fill(Theme.red).frame(width: 6, height: 6)
                            Text(L10n.localized(.systemPrefix)).font(.system(size: 8.5, weight: .semibold)).foregroundColor(Theme.sub)
                            Text("\(sysPct)%").font(.system(size: 9.5, weight: .bold, design: .monospaced)).foregroundColor(Theme.text)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Circle().fill(StatsTheme.trackBg).frame(width: 6, height: 6)
                            Text(L10n.localized(.idlePrefix)).font(.system(size: 8.5, weight: .semibold)).foregroundColor(Theme.sub)
                            Text("\(idlePct)%").font(.system(size: 9.5, weight: .bold, design: .monospaced)).foregroundColor(Theme.text)
                        }
                    }

                    Divider().background(Theme.sep)
                    HStack(spacing: 8) {
                        if let cTemp = cpu?.temperature {
                            HStack(spacing: 4) {
                                Text(L10n.localized(.menuBarCoreTemperatureTab))
                                    .font(.system(size: 8.5, weight: .medium))
                                    .foregroundColor(Theme.sub)
                                Text("\(cTemp)°C")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(cTemp >= 80 ? Theme.red : (cTemp >= 65 ? StatsTheme.thirdColor : Theme.text))
                            }
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text(L10n.localized(.menuBarGpuShort))
                                .font(.system(size: 8.5, weight: .semibold))
                                .foregroundColor(Theme.sub)
                            ZStack(alignment: .leading) {
                                Capsule().fill(StatsTheme.trackBg).frame(width: 34, height: 4.5)
                                Capsule().fill(Theme.accent2).frame(width: max(3, 34 * CGFloat(gpuRatio)), height: 4.5)
                            }
                            Text("\(gpuUsagePct)%")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.accent2)
                        }
                    }
                }
            }

            // 2. PROCESSES (支持一键打开活动监视器)
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 3.5) {
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
                        .help(L10n.localized(.actionOpenActivityMonitorHelp))
                    }

                    let topList = (service.latestSnapshot?.topProcesses ?? []).prefix(5)
                    ForEach(topList) { proc in
                        ProcessRowView(proc: proc)
                    }
                }
            }

            // 3. LOAD AVERAGE
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(L10n.localized(.statsSectionAverageLoad))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.accent)
                        Spacer()
                        if let l = cpu?.loadAverage {
                            Text(L10n.localized(.peakPrefix) + " " + String(format: "%.2f", max(loadStats.peak, max(l.0, max(l.1, l.2)))))
                                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.sub)
                        }
                    }

                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 5).fill(StatsTheme.boxBg)
                        MenuBarAreaWaveShape(points: loadPts, scale: 1.0)
                            .fill(Theme.accent.opacity(0.28))
                        MenuBarAreaWaveStrokeShape(points: loadPts, scale: 1.0)
                            .stroke(Theme.accent, lineWidth: 1.2)
                        MenuBarWaveHoverOverlay(rawPoints: loadStats.points, valueFormat: "%.2f", unitSuffix: "")
                    }
                    .frame(height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                    if let l = cpu?.loadAverage {
                        HStack {
                            statBox(label: L10n.localized(.timeRangeOneMinute), value: String(format: "%.2f", l.0))
                            statBox(label: L10n.localized(.timeRangeFiveMinutes), value: String(format: "%.2f", l.1))
                            statBox(label: L10n.localized(.timeRangeFifteenMinutes), value: String(format: "%.2f", l.2))
                        }
                    }
                }
            }
        }
    }

    func statBox(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8.5))
                .foregroundColor(Theme.sub)
            Text(value)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.text)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3)
        .background(StatsTheme.boxBg)
        .cornerRadius(5)
    }
}
