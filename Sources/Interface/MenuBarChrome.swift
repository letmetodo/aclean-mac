import SwiftUI

extension MonitorModuleCategory {
    var tintColor: Color {
        switch self {
        case .weather:  return Color(red: 0.30, green: 0.75, blue: 0.98)
        case .cpuGpu:   return Color(red: 0.30, green: 0.85, blue: 0.55)
        case .memory:   return Color(red: 0.95, green: 0.75, blue: 0.30)
        case .disks:    return Color(red: 0.38, green: 0.62, blue: 0.96)
        case .network:  return Color(red: 0.25, green: 0.82, blue: 0.80)
        case .sensors:  return Color.orange
        case .battery:  return Color.green
        case .time:     return Color(red: 0.70, green: 0.52, blue: 0.96)
        case .combined: return Color(red: 0.95, green: 0.45, blue: 0.55)
        }
    }
}

extension DropdownSectionKind {
    var accentColor: Color {
        switch self {
        case .dateTimeCard:      return Color(red: 0.70, green: 0.52, blue: 0.96)
        case .healthBanner:      return Color.green
        case .cpuCard:           return Color(red: 0.35, green: 0.85, blue: 0.55)
        case .gpuCard:           return Color.orange
        case .ramCard:           return Color(red: 0.95, green: 0.80, blue: 0.35)
        case .diskCard:          return Color.cyan
        case .networkCard:       return Color(red: 0.30, green: 0.80, blue: 0.95)
        case .sensorCard:        return Color(red: 0.98, green: 0.52, blue: 0.32)
        case .batteryCard:       return Color(red: 0.45, green: 0.90, blue: 0.45)
        case .weatherQuickCard:  return Color(red: 0.38, green: 0.68, blue: 0.98)
        case .networkDetailCard: return Color.teal
        case .topProcesses:      return Color(red: 0.95, green: 0.45, blue: 0.55)
        case .footerToolbar:     return Color.purple
        case .hardwareGrid:          return Color.blue
        }
    }
}
