import Foundation
import Foundation
import Combine

// ============================================================
//  MenuBarConfigStore —— AClean 级菜单栏与下拉弹窗自定义配置中心
//
//  职责：
//    1. 管理左侧 9 大监控模块的启用/禁用状态；
//    2. 管理 ITEMS TO SHOW IN MENUBAR (顶部菜单栏显示令牌及顺序，支持双行堆叠渲染)；
//    3. 管理 ITEMS TO SHOW IN DROPDOWN (下拉弹窗显示区块及顺序)；
//    4. 管理双栏并排模式 (Dual-Column：左栏天气/网络/进程二级看板 + 右栏主状态看板)。
// ============================================================

// MARK: - 1. 左侧模块分类 (对齐图四左侧列表)

enum MonitorModuleCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case weather  = "weather"
    case cpuGpu   = "cpuGpu"
    case memory   = "memory"
    case disks    = "disks"
    case network  = "network"
    case sensors  = "sensors"
    case battery  = "battery"
    case time     = "time"
    case combined = "combined"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weather:  return L10n.localized(.menuBarCatWeather)
        case .cpuGpu:   return L10n.localized(.menuBarCatCpuGpu)
        case .memory:   return L10n.localized(.menuBarCatMemory)
        case .disks:    return L10n.localized(.menuBarCatDisks)
        case .network:  return L10n.localized(.menuBarCatNetwork)
        case .sensors:  return L10n.localized(.menuBarCatSensors)
        case .battery:  return L10n.localized(.menuBarCatBattery)
        case .time:     return L10n.localized(.menuBarCatTime)
        case .combined: return L10n.localized(.menuBarCatCombined)
        }
    }

    var icon: String {
        switch self {
        case .weather:  return "cloud.sun.fill"
        case .cpuGpu:   return "cpu"
        case .memory:   return "memorychip"
        case .disks:    return "internaldrive.fill"
        case .network:  return "network"
        case .sensors:  return "thermometer.medium"
        case .battery:  return "battery.100"
        case .time:     return "clock.fill"
        case .combined: return "rectangle.grid.2x2.fill"
        }
    }


}

// MARK: - 2. ITEMS TO SHOW IN MENUBAR (顶部菜单栏展示项与预设数据格式)

enum MenuBarColorMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case themeAccent  = "themeAccent"
    case utilization  = "utilization"
    case monochrome   = "monochrome"
    case classicMulti = "classicMulti"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .themeAccent:  return L10n.localized(.menuBarColorModeThemeAccent)
        case .utilization:  return L10n.localized(.menuBarColorModeUtilization)
        case .monochrome:   return L10n.localized(.menuBarColorModeMonochrome)
        case .classicMulti: return L10n.localized(.menuBarColorModeClassicMulti)
        }
    }

    var iconName: String {
        switch self {
        case .themeAccent:  return "paintpalette.fill"
        case .utilization:  return "gauge.with.dots.needle.67percent"
        case .monochrome:   return "circle.lefthalf.filled"
        case .classicMulti: return "chart.pie.fill"
        }
    }

    var title: String { localizedTitle }
    var icon: String { iconName }
}

struct TokenDisplayFormatPreset: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let topLine: String
    let bottomLine: String
    let description: String

    var localizedName: String {
        if let key = L10nKey.presetName(id: id) {
            return L10n.localized(key)
        }
        return name
    }

    var localizedDescription: String {
        if let key = L10nKey.presetDescription(id: id) {
            return L10n.localized(key)
        }
        return description
    }
}

/// 预设 4 组顶部状态栏初始预设方案 (默认 / 基础 / 推荐 / 扩展)
enum StatsMenuBarPreset: String, CaseIterable, Identifiable, Codable, Sendable {
    case defaultPreset = "default"
    case basic         = "basic"
    case recommended   = "recommended"
    case extended      = "extended"

    var id: String { rawValue }

    var title: String { localizedTitle }

    var localizedTitle: String {
        switch self {
        case .defaultPreset: return L10n.localized(.statsPresetDefault)
        case .basic:         return L10n.localized(.statsPresetBasic)
        case .recommended:   return L10n.localized(.statsPresetRecommended)
        case .extended:      return L10n.localized(.statsPresetExtended)
        }
    }

    var tokens: [MenuBarTokenKind] {
        switch self {
        case .defaultPreset:
            return [.cpuStacked, .memoryStacked, .diskFreeStacked, .networkStacked, .batteryStacked]
        case .basic:
            return [.cpuStacked, .memoryStacked]
        case .recommended:
            return [.cpuStacked, .memoryStacked, .diskFreeStacked, .networkStacked]
        case .extended:
            return [.cpuStacked, .gpuStacked, .memoryStacked, .diskFreeStacked, .sensorTempStacked, .networkStacked, .batteryStacked]
        }
    }

    var formatOverrides: [MenuBarTokenKind: String] {
        switch self {
        case .defaultPreset:
            return [
                .cpuStacked: "cpu_mini",
                .memoryStacked: "mem_used_total",
                .diskFreeStacked: "disk_mini_pct",
                .networkStacked: "net_dual",
                .batteryStacked: "bat_icon_only"
            ]
        case .basic:
            return [
                .cpuStacked: "cpu_mini",
                .memoryStacked: "mem_used_total"
            ]
        case .recommended:
            return [
                .cpuStacked: "cpu_mini",
                .memoryStacked: "mem_bar_chart",
                .diskFreeStacked: "disk_bar_chart",
                .networkStacked: "net_dual"
            ]
        case .extended:
            return [
                .cpuStacked: "cpu_line_chart",
                .gpuStacked: "gpu_with_power",
                .memoryStacked: "mem_bar_chart",
                .diskFreeStacked: "disk_bar_chart",
                .sensorTempStacked: "sensor_label_vertical",
                .networkStacked: "net_dual",
                .batteryStacked: "bat_icon_only"
            ]
        }
    }
}

enum MenuBarTokenKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case weatherIconTemp    = "weatherIconTemp"    // 已从顶部状态栏移除（仅保留枚举值以兼容旧配置反序列化）
    case cpuStacked         = "cpuStacked"         // CPU (Mini / LineChart / BarChart / PieChart)
    case gpuStacked         = "gpuStacked"         // GPU (Mini / LineChart / BarChart)
    case memoryStacked      = "memoryStacked"      // RAM (Mini / BarChart / PieChart / LineChart)
    case diskFreeStacked    = "diskFreeStacked"    // SSD (Mini / BarChart / I/O Speed)
    case networkStacked     = "networkStacked"     // Net (SpeedDots ● 上下行 / 单行)
    case sensorTempStacked  = "sensorTempStacked"  // Sensors (Mini TMP / 竖排 SEN)
    case batteryStacked     = "batteryStacked"     // Battery (BatteryIcon 图标 / Mini BAT)
    case clockStacked       = "clockStacked"       // Clock (双行星期+时间 / 单行)

    /// 顶部菜单栏可配置的硬件监控指标（彻底移除天气图标项，天气仅在下拉弹窗内展示）
    static var configurableCases: [MenuBarTokenKind] {
        allCases.filter { $0 != .weatherIconTemp }
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weatherIconTemp:   return L10n.localized(.menuBarTokenWeatherIconTemp)
        case .cpuStacked:        return L10n.localized(.menuBarTokenCpuStacked)
        case .gpuStacked:        return L10n.localized(.menuBarTokenGpuStacked)
        case .memoryStacked:     return L10n.localized(.menuBarTokenMemoryStacked)
        case .diskFreeStacked:   return L10n.localized(.menuBarTokenDiskFreeStacked)
        case .networkStacked:    return L10n.localized(.menuBarTokenNetworkStacked)
        case .sensorTempStacked: return L10n.localized(.menuBarTokenSensorTempStacked)
        case .batteryStacked:    return L10n.localized(.menuBarTokenBatteryStacked)
        case .clockStacked:      return L10n.localized(.menuBarTokenClockStacked)
        }
    }

    var availablePresets: [TokenDisplayFormatPreset] {
        switch self {
        case .cpuStacked:
            return [
                TokenDisplayFormatPreset(id: "cpu_mini", name: "Stats Mini (CPU 12%)", topLine: "CPU", bottomLine: "12%", description: "Stats compact top label + bottom percentage"),
                TokenDisplayFormatPreset(id: "cpu_line_chart", name: "Stats Line Chart", topLine: "╭─╮", bottomLine: "CPU", description: "Stats dark box with live filled area waveform"),
                TokenDisplayFormatPreset(id: "cpu_bar_chart", name: "Stats Bar Chart", topLine: "▊", bottomLine: "CPU", description: "Stats vertical dark capsule slot with fill bar"),
                TokenDisplayFormatPreset(id: "cpu_with_temp", name: "Stats Mini + Bar", topLine: "CPU", bottomLine: "18%", description: "Stats Mini label, percentage and core column bars"),
                TokenDisplayFormatPreset(id: "cpu_pie_chart", name: "Stats Pie Ring", topLine: "18%", bottomLine: "CPU", description: "Stats segmented ring chart with percentage"),
                TokenDisplayFormatPreset(id: "cpu_percent_only", name: "Percentage Only", topLine: "18%", bottomLine: "", description: "Minimal numeric usage, saves space"),
                TokenDisplayFormatPreset(id: "cpu_user_sys", name: "User + System", topLine: "U: 12%", bottomLine: "S: 6%", description: "User space and kernel system load breakdown"),
                TokenDisplayFormatPreset(id: "cpu_sparkline", name: "Trend Sparkline", topLine: "18%", bottomLine: "", description: "Load percentage with dynamic historical mini-bars")
            ]
        case .gpuStacked:
            return [
                TokenDisplayFormatPreset(id: "gpu_with_power", name: "Stats Mini (GPU 32%)", topLine: "GPU", bottomLine: "32%", description: "Stats Mini uppercase label and GPU utilization"),
                TokenDisplayFormatPreset(id: "gpu_line_chart", name: "Stats Line Chart", topLine: "╭─╮", bottomLine: "GPU", description: "Stats dark box with live GPU area waveform"),
                TokenDisplayFormatPreset(id: "gpu_bar_chart", name: "Stats Bar Chart", topLine: "▊", bottomLine: "GPU", description: "Stats vertical dark capsule slot with GPU fill bar"),
                TokenDisplayFormatPreset(id: "gpu_with_temp", name: "Load + Temp", topLine: "32%", bottomLine: "45°C", description: "GPU core compute load and graphics thermal temperature"),
                TokenDisplayFormatPreset(id: "gpu_percent_only", name: "Percentage Only", topLine: "32%", bottomLine: "", description: "Minimal numeric GPU load, saves space")
            ]
        case .memoryStacked:
            return [
                TokenDisplayFormatPreset(id: "mem_used_total", name: "Stats Mini (RAM 57%)", topLine: "RAM", bottomLine: "57%", description: "Stats Mini RAM label and usage ratio"),
                TokenDisplayFormatPreset(id: "mem_bar_chart", name: "Stats Bar Chart", topLine: "▊", bottomLine: "RAM", description: "Stats vertical dark capsule slot with RAM fill bar"),
                TokenDisplayFormatPreset(id: "mem_pie_chart", name: "Stats Pie Ring", topLine: "57%", bottomLine: "RAM", description: "Stats segmented memory ring chart"),
                TokenDisplayFormatPreset(id: "mem_line_chart", name: "Stats Line Chart", topLine: "╭─╮", bottomLine: "RAM", description: "Stats dark box with memory history waveform"),
                TokenDisplayFormatPreset(id: "mem_percent_pressure", name: "Usage + Pressure", topLine: "57%", bottomLine: "OK", description: "Memory usage ratio and kernel memory pressure"),
                TokenDisplayFormatPreset(id: "mem_percent_only", name: "Percentage Only", topLine: "57%", bottomLine: "", description: "Minimal memory percentage, saves space"),
                TokenDisplayFormatPreset(id: "mem_free_only", name: "Free Space", topLine: "6.2G", bottomLine: "", description: "Available free physical memory, single line")
            ]
        case .networkStacked:
            return [
                TokenDisplayFormatPreset(id: "net_dual", name: "Stats Speed Dots", topLine: "● 479 KB/s", bottomLine: "● 8.9 MB/s", description: "Stats dual-row speed with red/blue activity indicator dots"),
                TokenDisplayFormatPreset(id: "net_down_only", name: "Download Only", topLine: "↓ 8.9M/s", bottomLine: "", description: "Incoming download bandwidth, single line centered"),
                TokenDisplayFormatPreset(id: "net_up_only", name: "Upload Only", topLine: "↑ 479K/s", bottomLine: "", description: "Outgoing upload bandwidth, single line centered"),
                TokenDisplayFormatPreset(id: "net_total", name: "Combined Rate", topLine: "9.4M/s", bottomLine: "", description: "Total combined network bandwidth, single line centered")
            ]
        case .sensorTempStacked:
            return [
                TokenDisplayFormatPreset(id: "sensor_with_fan", name: "Stats Mini (TMP 42°C)", topLine: "TMP", bottomLine: "42°C", description: "Stats Mini temperature label and SoC reading"),
                TokenDisplayFormatPreset(id: "sensor_label_vertical", name: "Stats Vertical (SEN)", topLine: "SEN", bottomLine: "42°C", description: "Stats vertical stacked S/E/N module label"),
                TokenDisplayFormatPreset(id: "sensor_with_power", name: "Temp + Power", topLine: "42°C", bottomLine: "15W", description: "SoC core temperature and package thermal power"),
                TokenDisplayFormatPreset(id: "sensor_temp_only", name: "Temperature Only", topLine: "42°C", bottomLine: "", description: "Minimal digital temperature, single line centered")
            ]
        case .batteryStacked:
            return [
                TokenDisplayFormatPreset(id: "bat_icon_only", name: "Stats Battery Icon", topLine: "[🔋]", bottomLine: "100%", description: "Stats horizontal battery graphic with proportional fill"),
                TokenDisplayFormatPreset(id: "bat_time_estimate", name: "Stats Mini (BAT 96%)", topLine: "BAT", bottomLine: "96%", description: "Stats Mini battery label and percentage"),
                TokenDisplayFormatPreset(id: "bat_standard", name: "Battery + Power", topLine: "96%", bottomLine: "6.8W", description: "Battery percentage and live charging wattage"),
                TokenDisplayFormatPreset(id: "bat_percent_only", name: "Percentage Only", topLine: "96%", bottomLine: "", description: "Remaining battery percentage, single line centered")
            ]
        case .diskFreeStacked:
            return [
                TokenDisplayFormatPreset(id: "disk_mini_pct", name: "Stats Mini (SSD 36%)", topLine: "SSD", bottomLine: "36%", description: "Stats Mini SSD label and used percentage"),
                TokenDisplayFormatPreset(id: "disk_bar_chart", name: "Stats Bar Chart", topLine: "▊", bottomLine: "SSD", description: "Stats vertical dark capsule slot with SSD fill bar"),
                TokenDisplayFormatPreset(id: "disk_free_ratio", name: "Stats Mini (SSD 175G)", topLine: "SSD", bottomLine: "175G", description: "Stats Mini disk label and free storage"),
                TokenDisplayFormatPreset(id: "disk_io_speed", name: "Disk I/O Speed", topLine: "R: 12M", bottomLine: "W: 5M", description: "Real-time physical disk read and write speed"),
                TokenDisplayFormatPreset(id: "disk_free_size", name: "Free Storage", topLine: "175G", bottomLine: "", description: "Remaining space on primary disk, single line centered"),
                TokenDisplayFormatPreset(id: "disk_percent", name: "Usage Ratio", topLine: "36%", bottomLine: "", description: "Percentage of disk space used, single line centered")
            ]
        case .weatherIconTemp:
            return [
                TokenDisplayFormatPreset(id: "weather_temp_only", name: "Temperature Only", topLine: "24°C", bottomLine: "", description: "Minimal live digital temperature, single line centered")
            ]
        case .clockStacked:
            return [
                TokenDisplayFormatPreset(id: "clock_weekday_time", name: "Weekday + Time", topLine: "Tue", bottomLine: "14:28", description: "Classic two-line day of week and time"),
                TokenDisplayFormatPreset(id: "clock_with_seconds", name: "Time with Seconds", topLine: "14:28", bottomLine: ":35", description: "High-precision live ticking seconds"),
                TokenDisplayFormatPreset(id: "clock_time_only", name: "Compact Time", topLine: "14:28", bottomLine: "", description: "Minimal 24-hour digital clock, single line centered")
            ]
        }
    }

    @MainActor var previewTopLine: String {
        MenuBarConfigStore.shared.formatPreset(for: self).topLine
    }

    @MainActor var previewBottomLine: String {
        MenuBarConfigStore.shared.formatPreset(for: self).bottomLine
    }

    var category: MonitorModuleCategory {
        switch self {
        case .weatherIconTemp:   return .weather
        case .cpuStacked, .gpuStacked: return .cpuGpu
        case .memoryStacked:     return .memory
        case .diskFreeStacked:   return .disks
        case .networkStacked:    return .network
        case .sensorTempStacked: return .sensors
        case .batteryStacked:    return .battery
        case .clockStacked:      return .time
        }
    }
}

// MARK: - 3. ITEMS TO SHOW IN DROPDOWN (下拉面板展示区块与九宫格排版)

enum DashboardGridSpan: String, CaseIterable, Identifiable, Codable, Sendable {
    case full  = "full"   // 1/1 通栏全宽 (独占一行)
    case half  = "half"   // 1/2 双列并排 (两两成对)
    case third = "third"  // 1/3 三列九宫 (三等分紧凑)

    var id: String { rawValue }

    var label: String {
        switch self {
        case .full:  return L10n.localized(.spanOptionFull)
        case .half:  return L10n.localized(.spanOptionHalf)
        case .third: return L10n.localized(.spanOptionThird)
        }
    }

    var shortLabel: String {
        switch self {
        case .full:  return "1/1"
        case .half:  return "1/2"
        case .third: return "1/3"
        }
    }

    var icon: String {
        switch self {
        case .full:  return "rectangle.fill"
        case .half:  return "rectangle.split.2x1.fill"
        case .third: return "rectangle.split.3x1.fill"
        }
    }
}

/// 下拉弹窗卡片垂直高度/内容密度尺寸档位
enum DashboardCardHeightMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case compact  = "compact"   // 紧凑 (S: 核心数值优先，高度约 72pt，极度规整)
    case standard = "standard"  // 标准 (M: 标准微图表，高度约 94pt，左右完美对齐等高)
    case expanded = "expanded"  // 展开 (L: 极客全量详情，高度约 130pt，展现最完整多维数据)

    var id: String { rawValue }

    var label: String {
        switch self {
        case .compact:  return L10n.localized(.cardHeightCompact)
        case .standard: return L10n.localized(.cardHeightStandard)
        case .expanded: return L10n.localized(.cardHeightExpanded)
        }
    }

    var shortLabel: String {
        switch self {
        case .compact:  return "S"
        case .standard: return "M"
        case .expanded: return "L"
        }
    }

    var icon: String {
        switch self {
        case .compact:  return "rectangle.compress.vertical"
        case .standard: return "rectangle"
        case .expanded: return "rectangle.expand.vertical"
        }
    }
}

enum DropdownSectionKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case dateTimeCard       = "dateTimeCard"       // 日期 + 时间 + 今日日历日程卡片
    case weatherQuickCard   = "weatherQuickCard"   // 实时天气摘要与预报快捷卡片
    case cpuCard            = "cpuCard"            // CPU 核心负载与微图
    case ramCard            = "ramCard"            // 内存使用率与压力
    case networkCard        = "networkCard"        // 实时网络吞吐与公网 IP
    case diskCard           = "diskCard"           // 磁盘可用空间与 I/O
    case batteryCard        = "batteryCard"        // 电池健康、充放电功率与蓝牙外设电量
    case sensorCard         = "sensorCard"         // 芯片温度与风扇转速
    case healthBanner       = "healthBanner"       // 旧版兼容
    case gpuCard            = "gpuCard"            // 旧版兼容
    case networkDetailCard  = "networkDetailCard"  // 旧版兼容
    case topProcesses       = "topProcesses"       // 旧版兼容
    case footerToolbar      = "footerToolbar"      // 旧版兼容
    case hardwareGrid           = "hardwareGrid"           // 旧版兼容

    static var configurableCases: [DropdownSectionKind] {
        [
            .dateTimeCard,
            .weatherQuickCard,
            .cpuCard,
            .ramCard,
            .networkCard,
            .diskCard,
            .batteryCard,
            .sensorCard
        ]
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dateTimeCard:      return L10n.localized(.menuBarCalendarAndAgendaHeader)
        case .healthBanner:      return L10n.localized(.dropdownHealthBannerTitle)
        case .cpuCard:           return L10n.localized(.menuBarTokenCpuStacked)
        case .gpuCard:           return L10n.localized(.menuBarTokenGpuStacked)
        case .ramCard:           return L10n.localized(.menuBarTokenMemoryStacked)
        case .diskCard:          return L10n.localized(.menuBarTokenDiskFreeStacked)
        case .networkCard:       return L10n.localized(.menuBarTokenNetworkStacked)
        case .sensorCard:        return L10n.localized(.menuBarTokenSensorTempStacked)
        case .batteryCard:       return L10n.localized(.dropdownBatteryCardTitle)
        case .weatherQuickCard:  return L10n.localized(.dropdownWeatherQuickCardTitle)
        case .networkDetailCard: return L10n.localized(.dropdownNetworkDetailCardTitle)
        case .topProcesses:      return L10n.localized(.dropdownTopProcessesTitle)
        case .footerToolbar:     return L10n.localized(.dropdownFooterToolbarTitle)
        case .hardwareGrid:          return L10n.localized(.dropdownHardwareGridTitle)
        }
    }

    var shortTitle: String {
        switch self {
        case .dateTimeCard:      return L10n.localized(.menuBarCatTime)
        case .healthBanner:      return L10n.localized(.dropdownHealthBannerTitle)
        case .cpuCard:           return "CPU"
        case .gpuCard:           return "GPU"
        case .ramCard:           return L10n.localized(.menuBarCatMemory)
        case .diskCard:          return L10n.localized(.menuBarCatDisks)
        case .networkCard:       return L10n.localized(.menuBarCatNetwork)
        case .sensorCard:        return L10n.localized(.menuBarCatSensors)
        case .batteryCard:       return L10n.localized(.menuBarCatBattery)
        case .weatherQuickCard:  return L10n.localized(.menuBarCatWeather)
        case .networkDetailCard: return L10n.localized(.menuBarCatNetwork)
        case .topProcesses:      return "Top"
        case .footerToolbar:     return L10n.localized(.dropdownFooterToolbarTitle)
        case .hardwareGrid:          return L10n.localized(.menuBarCatCombined)
        }
    }

    var subtitle: String {
        switch self {
        case .dateTimeCard:      return L10n.localized(.menuBarCalendarAndAgendaHeader)
        case .healthBanner:      return L10n.localized(.dropdownHealthBannerDesc)
        case .cpuCard:           return L10n.localized(.menuBarPerCoreEqualizerHeader)
        case .gpuCard:           return L10n.localized(.menuBarGpuEngineHeader)
        case .ramCard:           return L10n.localized(.menuBarMemoryCompositionHeader)
        case .diskCard:          return L10n.localized(.menuBarDiskIoHeader)
        case .networkCard:       return L10n.localized(.menuBarTopBandwidthAppsHeader)
        case .sensorCard:        return L10n.localized(.menuBarTemperatureSensorsMatrixHeader)
        case .batteryCard:       return L10n.localized(.dropdownBatteryCardDesc)
        case .weatherQuickCard:  return L10n.localized(.dropdownWeatherQuickCardDesc)
        case .networkDetailCard: return L10n.localized(.dropdownNetworkDetailCardDesc)
        case .topProcesses:      return L10n.localized(.dropdownTopProcessesDesc)
        case .footerToolbar:     return L10n.localized(.dropdownFooterToolbarDesc)
        case .hardwareGrid:          return L10n.localized(.dropdownHardwareGridDesc)
        }
    }

    var icon: String {
        switch self {
        case .dateTimeCard:      return "calendar"
        case .healthBanner:      return "sun.max.fill"
        case .cpuCard:           return "cpu"
        case .gpuCard:           return "display"
        case .ramCard:           return "memorychip"
        case .diskCard:          return "internaldrive"
        case .networkCard:       return "network"
        case .sensorCard:        return "fanblades.fill"
        case .batteryCard:       return "battery.100.bolt"
        case .weatherQuickCard:  return "cloud.sun.rain.fill"
        case .networkDetailCard: return "globe.asia.australia.fill"
        case .topProcesses:      return "list.number"
        case .footerToolbar:     return "slider.horizontal.below.square.filled.and.square"
        case .hardwareGrid:          return "square.grid.2x2.fill"
        }
    }


}

// MARK: - 4. 左栏伴侣面板视图模式与悬停二级子面板分类

enum CompanionLeftPaneTab: String, CaseIterable, Identifiable, Codable, Sendable {
    case weather   = "weather"
    case network   = "network"
    case processes = "processes"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weather:   return L10n.localized(.subPanelWeatherTitle)
        case .network:   return L10n.localized(.subPanelNetworkTitle)
        case .processes: return L10n.localized(.subPanelProcessesTitle)
        }
    }

    var icon: String {
        switch self {
        case .weather:   return "cloud.sun.fill"
        case .network:   return "network"
        case .processes: return "Waveform.path.ecg"
        }
    }
}

/// 顶部菜单栏主列鼠标滑过时触发的二级详情分类（若滑过无子类目的区块则为 nil，自动收起二级面板）
enum CompanionSubcategoryKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case calendar = "calendar"
    case weather  = "weather"
    case cpu      = "cpu"
    case gpu      = "gpu"
    case memory   = "memory"
    case disk     = "disk"
    case network  = "network"
    case fan      = "fan"
    case battery  = "battery"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calendar: return L10n.localized(.menuBarCalendarAndAgendaHeader)
        case .weather:  return L10n.localized(.weatherWeeklyForecast)
        case .cpu:      return L10n.localized(.cpuLoadDetails)
        case .gpu:      return L10n.localized(.gpuRenderDetails)
        case .memory:   return L10n.localized(.memoryPressureDistribution)
        case .disk:     return L10n.localized(.diskCapacityIoTrends)
        case .network:  return L10n.localized(.networkThroughputDiagnostics)
        case .fan:      return L10n.localized(.fanSpeedThermalControl)
        case .battery:  return L10n.localized(.batteryHealthPowerDraw)
        }
    }

    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .weather:  return "cloud.sun.fill"
        case .cpu:      return "cpu"
        case .gpu:      return "display"
        case .memory:   return "memorychip"
        case .disk:     return "internaldrive.fill"
        case .network:  return "network"
        case .fan:      return "fanblades.fill"
        case .battery:  return "battery.100.bolt"
        }
    }
}

