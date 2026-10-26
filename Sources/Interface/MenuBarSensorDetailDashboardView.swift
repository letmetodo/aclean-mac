import SwiftUI
import AppKit

// MARK: - Sensors, fans, and power bus dashboard

struct SensorsDetailDashboardView: View {
    @ObservedObject var service = SystemTelemetryService.shared
    @ObservedObject var appConfig = AppConfigStore.shared

    struct SensorItemRow: Identifiable {
        let id: String
        let name: String
        let valueText: String
        let ratio: Double
        let isPrimaryBar: Bool
    }

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        let snap = service.latestSnapshot
        let fan = snap?.fan
        let power = snap?.powerBus
        let leftRpm = fan?.leftFanRPM ?? 0
        let rightRpm = fan?.rightFanRPM ?? 0
        let totalW = power?.totalWatts ?? snap?.cpu.powerWatts ?? 0.0
        let railV = power?.busVoltageVolts ?? 0.0
        let busA = power?.batteryAmperes ?? 0.0

        let realSensors = snap?.detailedSensors ?? []
        let tempRows: [SensorItemRow] = {
            if !realSensors.isEmpty {
                return Array(realSensors.prefix(AppConfig.UI.detailedSensorRowLimit)).map { item in
                    SensorItemRow(
                        id: item.key,
                        name: item.name,
                        valueText: String(format: "%.0f°", item.temperature),
                        ratio: min(1.0, max(0.05, item.temperature / 100.0)),
                        isPrimaryBar: true
                    )
                }
            }
            var fallback: [SensorItemRow] = []
            if let cTemp = snap?.cpu.temperature {
                fallback.append(SensorItemRow(id: "cpu_avg", name: "CPU Core Average", valueText: "\(cTemp)°", ratio: Double(cTemp) / 100.0, isPrimaryBar: true))
            }
            if let gTemp = snap?.gpu.temperature {
                fallback.append(SensorItemRow(id: "gpu_avg", name: "GPU Average", valueText: "\(gTemp)°", ratio: Double(gTemp) / 100.0, isPrimaryBar: true))
            }
            if let bTemp = snap?.battery?.temperatureCelsius {
                fallback.append(SensorItemRow(id: "bat_temp", name: "Battery", valueText: String(format: "%.0f°", bTemp), ratio: bTemp / 100.0, isPrimaryBar: true))
            }
            return fallback
        }()

        return VStack(spacing: 4) {
            Text(L10n.localized(.menuBarSensorsHeader))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.accent)
                .padding(.top, 2)

            HStack {
                Text(L10n.localized(.menuBarFansLabel))
                    .font(.system(size: 10))
                    .foregroundColor(Theme.sub)
                Spacer()
                if fan?.hasFans == true {
                    let curMode = fan?.mode ?? "auto"
                    HStack(spacing: 3) {
                        fanModePill(title: L10n.localized(.menuBarFanModeSystemAuto), mode: "auto", current: curMode)
                        fanModePill(title: "50%", mode: "cooling", current: curMode)
                        fanModePill(title: "100%", mode: "max", current: curMode)
                    }
                } else {
                    Text(fan?.localizedMode ?? L10n.localized(.menuBarSystemControlledLabel))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.text)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 2)

            if let feedback = service.fanControlFeedback {
                Text(feedback)
                    .font(.system(size: 8.5))
                    .foregroundColor(Theme.sub)
                    .lineLimit(2)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)
            }

            Divider().background(Theme.sep)

            VStack(spacing: 1.5) {
                ForEach(tempRows) { item in
                    sensorCapsuleRow(name: item.name, value: item.valueText, ratio: item.ratio, isPrimary: item.isPrimaryBar)
                }

                if fan?.hasFans == true {
                    Divider().background(Theme.sep).padding(.vertical, 2)

                    sensorCapsuleRow(name: L10n.localized(.labelLeftFan), value: "\(leftRpm) rpm", ratio: Double(leftRpm) / Double(max(1, fan?.maxRPM ?? 6000)), isPrimary: false)
                    if (fan?.fanCount ?? 0) > 1 {
                        sensorCapsuleRow(name: L10n.localized(.labelRightFan), value: "\(rightRpm) rpm", ratio: Double(rightRpm) / Double(max(1, fan?.maxRPM ?? 6000)), isPrimary: false)
                    }
                }

                Divider().background(Theme.sep).padding(.vertical, 2)

                sensorCapsuleRow(name: L10n.localized(.menuBarTotalSystemWattsLabel), value: String(format: "%.2f W", totalW), ratio: min(1.0, totalW / 100.0), isPrimary: true)
                if railV > 0 {
                    sensorCapsuleRow(name: L10n.localized(.menuBarPowerBusVoltageLabel), value: String(format: "%.2f V", railV), ratio: min(1.0, railV / 15.0), isPrimary: true)
                }
                if busA > 0 {
                    sensorCapsuleRow(name: L10n.localized(.menuBarBatteryBusAmperesLabel), value: String(format: "%.2f A", busA), ratio: min(1.0, max(0.04, busA / 2.0)), isPrimary: true)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    func fanModePill(title: String, mode: String, current: String) -> some View {
        let active = current == mode
        return Button {
            service.setFanMode(mode)
        } label: {
            Text(title)
                .font(.system(size: 8.5, weight: active ? .bold : .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(active ? Theme.accent : StatsTheme.boxBg))
                .foregroundColor(active ? Theme.onAccent : Theme.sub)
        }
        .buttonStyle(.plain)
        .disabled(service.isSettingFanMode)
        .overlay { if service.isSettingFanMode && active { ProgressView().controlSize(.mini) } }
    }

    func sensorCapsuleRow(name: String, value: String, ratio: Double, isPrimary: Bool) -> some View {
        let barColor: Color = {
            if !isPrimary { return Theme.tert.opacity(0.55) }
            if ratio >= 0.80 { return Theme.red }
            if ratio >= 0.65 { return StatsTheme.thirdColor }
            return Theme.accent
        }()
        return HStack(spacing: 8) {
            Text(name)
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(Theme.sub)
                .lineLimit(1)
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(isPrimary && ratio >= 0.80 ? Theme.red : Theme.text)
                .frame(minWidth: 54, alignment: .trailing)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(StatsTheme.trackBg)
                    .frame(width: 44, height: 8)
                if ratio > 0 {
                    Capsule()
                        .fill(barColor)
                        .frame(width: max(3, 44 * CGFloat(min(1.0, ratio))), height: 8)
                }
            }
        }
        .padding(.vertical, 1.2)
    }
}
