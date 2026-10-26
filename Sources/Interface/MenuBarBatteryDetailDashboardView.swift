import SwiftUI
import AppKit

// MARK: - 6. 电池与蓝牙外设深度仪表盘

struct BatteryDetailDashboardView: View {
    @ObservedObject var service = SystemTelemetryService.shared
    @ObservedObject var appConfig = AppConfigStore.shared

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        let snap = service.latestSnapshot
        let bat = snap?.battery
        let pct = bat?.percentage ?? 100
        let health = bat?.healthPercentage ?? 100
        let cycles = bat?.cycleCount ?? 0

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(L10n.localized(.batteryHealthPowerDraw))
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(Theme.accent)
                Spacer()
                Text("\(pct)% ⚡️ \(bat?.isCharging == true ? L10n.localized(.batteryChargingStateCharging) : L10n.localized(.statusNormal))")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(Theme.green)
            }
            .padding(.horizontal, 2)

            ModernBentoCard(cornerRadius: 8, padding: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.localized(.menuBarBatteryPowerSourceLabel))
                            .font(.system(size: 8.5))
                            .foregroundColor(Theme.sub)
                        Text(
                            (bat?.adapterWatts ?? 0) > 0
                                ? "Power Adapter (\(bat!.adapterWatts)W)"
                                : (bat?.isPluggedIn == true ? L10n.localized(.menuBarAcPowerDirectLabel) : L10n.localized(.battery))
                        )
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(Theme.text)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.localized(.labelBatteryRemainingEstimate))
                            .font(.system(size: 8.5))
                            .foregroundColor(Theme.sub)
                        Text(bat?.chargeEstimateText ?? "—")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Theme.text)
                            .lineLimit(1)
                    }
                }
            }

            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.localized(.menuBarBluetoothPeripheralsHeader))
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(Theme.accent)

                    let bt = snap?.bluetoothPeripherals ?? []
                    if !bt.isEmpty {
                        ForEach(bt, id: \.id) { p in
                            accessoryCapsuleRow(icon: p.categorySymbol, name: p.name, pct: p.batteryPercent)
                        }
                    } else {
                        Text(L10n.localized(.notInUse))
                            .font(.system(size: 9.5))
                            .foregroundColor(Theme.sub)
                            .padding(.vertical, 2)
                    }
                }
            }

            HStack {
                miniBatMetric(label: L10n.localized(.menuBarBatteryHealthTitle), val: "\(health)%")
                Spacer()
                miniBatMetric(label: L10n.localized(.labelBatteryCycleCount), val: L10n.format(.batteryCycleCountFormat, cycles))
                Spacer()
                miniBatMetric(
                    label: L10n.localized(.menuBarTotalSystemWattsLabel),
                    val: String(format: "%.1f W", bat?.systemWatts ?? snap?.powerBus?.totalWatts ?? 0.0)
                )
                Spacer()
                miniBatMetric(label: L10n.localized(.labelBatteryTemperature), val: bat?.temperatureCelsius.map { String(format: "%.1f℃", $0) } ?? "—")
            }
            .padding(.horizontal, 4)
        }
    }

    func accessoryCapsuleRow(icon: String, name: String, pct: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10.5))
                .frame(width: 14)
                .foregroundColor(Theme.accent)
            Text(verbatim: name)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundColor(Theme.text)
                .lineLimit(1)
            Spacer()
            ZStack(alignment: .leading) {
                Capsule().fill(StatsTheme.trackBg).frame(width: 36, height: 4.5)
                Capsule()
                    .fill(LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(3, 36 * CGFloat(Double(pct) / 100.0)), height: 4.5)
            }
            Text("\(pct)%")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.text)
                .frame(width: 30, alignment: .trailing)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 5).fill(StatsTheme.boxBg))
    }

    func miniBatMetric(label: String, val: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.system(size: 8)).foregroundColor(Theme.sub)
            Text(val).font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundColor(Theme.text)
        }
    }
}
