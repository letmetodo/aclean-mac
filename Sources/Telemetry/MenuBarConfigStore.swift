import Foundation
import Combine

// MARK: - 5. 配置持久化中心 (MenuBarConfigStore)

@MainActor
final class MenuBarConfigStore: ObservableObject {

    static let shared = MenuBarConfigStore()

    /// 启用的主监控模块集合 (主监控模块集合)
    @Published var enabledCategories: Set<MonitorModuleCategory> {
        didSet { save() }
    }

    /// 是否开启双行紧凑堆叠菜单栏渲染 (紧凑双行样式)
    @Published var useDualLineMenuBar: Bool {
        didSet { save() }
    }

    /// 是否常驻固定展开左栏 (默认 false：单栏展示，鼠标悬停有子类目项时才弹出二级面板)
    @Published var useDualColumnDropdown: Bool {
        didSet { save() }
    }

    /// 左栏默认激活的子面板
    @Published var activeLeftPane: CompanionLeftPaneTab {
        didSet { save() }
    }

    /// 当前在二级详情面板中选择的时间段 (1分钟 / 5分钟 / 15分钟 / 1小时)
    @Published var selectedTimeRange: TelemetryTimeRange = .oneMinute

    /// 在顶部菜单栏显示的令牌数组 (有序，支持自由增删与左右移动排序)
    @Published var activeMenuBarTokens: [MenuBarTokenKind] {
        didSet { save() }
    }

    /// 在下拉弹窗右栏显示的区块数组 (有序，支持自由增删与上下移动排序)
    @Published var activeDropdownSections: [DropdownSectionKind] {
        didSet { save() }
    }

    /// 全量菜单栏模块全局排序 (包含已启用与已隐藏项，供复选与拖拽自定义)
    @Published var allMenuBarTokensOrder: [MenuBarTokenKind] {
        didSet { save() }
    }

    /// 全量下拉弹窗模块全局排序 (包含已启用与已隐藏项，供复选与拖拽自定义)
    @Published var allDropdownSectionsOrder: [DropdownSectionKind] {
        didSet { save() }
    }

    // MARK: - 各模块高级个性化配置 (各模块高级独立设置)
    
    // 天气 (Weather)
    @Published var weatherTempUnit: String { didSet { save() } }           // "C" 或 "F"
    @Published var weatherShow24hHourly: Bool { didSet { save() } }
    @Published var weatherShow7Day: Bool { didSet { save() } }
    @Published var weatherShowExtraMetrics: Bool { didSet { save() } }    // 紫外线、湿度、风速
    
    // CPU & GPU
    @Published var cpuShowSparkline: Bool { didSet { save() } }           // 是否在菜单栏画微型历史图
    @Published var cpuShowPerCore: Bool { didSet { save() } }             // P核/E核明细
    @Published var cpuTopProcessesCount: Int { didSet { save() } }        // 5, 10, 15
    @Published var cpuRefreshInterval: Double { didSet { save() } }       // 1.0, 2.0, 5.0 秒

    // 内存 (Memory)
    @Published var memoryShowPressure: Bool { didSet { save() } }         // 内存压力指示条
    @Published var memoryShowBreakdown: Bool { didSet { save() } }        // 联动/压缩/缓存构成

    // 磁盘 (Disks)
    @Published var disksShowExternalDrives: Bool { didSet { save() } }    // 挂载的外置驱动器
    @Published var disksShowIoRate: Bool { didSet { save() } }            // 读写 IO 速率

    // 网络 (Network)
    @Published var networkShowPublicIP: Bool { didSet { save() } }        // 公网 IP
    @Published var networkSpeedUnit: String { didSet { save() } }         // "bytes" (KB/s) 或 "bits" (Kbps)
    @Published var networkPingDiagnosis: Bool { didSet { save() } }       // 延迟诊断

    // 传感器与风扇 (Sensors & Fans)
    @Published var sensorFanMode: String { didSet { save() } }            // "auto", "cooling", "max"
    @Published var sensorTempUnit: String { didSet { save() } }           // "C" 或 "F"

    // 电池与电源 (Battery & Power)
    @Published var batteryShowWattage: Bool { didSet { save() } }         // 实时功率 W
    @Published var batteryShowHealth: Bool { didSet { save() } }          // 健康度与循环
    @Published var batteryShowBluetooth: Bool { didSet { save() } }       // 蓝牙键鼠耳机电量

    // 时间与日历 (Time & Date)
    @Published var clockUse24Hour: Bool { didSet { save() } }
    @Published var clockShowDayOfWeek: Bool { didSet { save() } }
    @Published var clockShowSeconds: Bool { didSet { save() } }

    /// 顶部状态栏小组件着色模式 (支持主题色联动)
    @Published var menuBarColorMode: MenuBarColorMode { didSet { save() } }

    /// 指标预设数据展示格式: token.id -> preset.id
    @Published var tokenFormatSelections: [String: String] { didSet { save() } }

    /// 下拉弹窗九宫格卡片宽度跨度: section.id -> DashboardGridSpan.rawValue
    @Published var sectionGridSpans: [String: String] { didSet { save() } }

    /// 下拉弹窗卡片垂直高度档位: section.id -> DashboardCardHeightMode.rawValue
    @Published var sectionHeightModes: [String: String] { didSet { save() } }

    private static var storageKey: String { AppConfig.StorageKeys.menuBarConfig }
    private var storageKey: String { Self.storageKey }

    private struct PersistedPayload: Codable {
        var enabledCategories: [MonitorModuleCategory]?
        var useDualLineMenuBar: Bool
        var useDualColumnDropdown: Bool
        var activeLeftPane: CompanionLeftPaneTab
        var activeMenuBarTokens: [MenuBarTokenKind]
        var activeDropdownSections: [DropdownSectionKind]
        var allMenuBarTokensOrder: [MenuBarTokenKind]?
        var allDropdownSectionsOrder: [DropdownSectionKind]?
        var tokenFormatSelections: [String: String]?
        var sectionGridSpans: [String: String]?
        var sectionHeightModes: [String: String]?
        var menuBarColorMode: MenuBarColorMode?
        
        var weatherTempUnit: String?
        var weatherShow24hHourly: Bool?
        var weatherShow7Day: Bool?
        var weatherShowExtraMetrics: Bool?
        var cpuShowSparkline: Bool?
        var cpuShowPerCore: Bool?
        var cpuTopProcessesCount: Int?
        var cpuRefreshInterval: Double?
        var memoryShowPressure: Bool?
        var memoryShowBreakdown: Bool?
        var disksShowExternalDrives: Bool?
        var disksShowIoRate: Bool?
        var networkShowPublicIP: Bool?
        var networkSpeedUnit: String?
        var networkPingDiagnosis: Bool?
        var sensorFanMode: String?
        var sensorTempUnit: String?
        var batteryShowWattage: Bool?
        var batteryShowHealth: Bool?
        var batteryShowBluetooth: Bool?
        var clockUse24Hour: Bool?
        var clockShowDayOfWeek: Bool?
        var clockShowSeconds: Bool?
    }

    private static func migrateSections(_ sections: [DropdownSectionKind]) -> [DropdownSectionKind] {
        let validSet = Set(DropdownSectionKind.configurableCases)
        var migrated: [DropdownSectionKind] = []
        for s in sections {
            if s == .hardwareGrid {
                let hardware: [DropdownSectionKind] = [.cpuCard, .ramCard, .diskCard, .networkCard, .sensorCard]
                for h in hardware where !migrated.contains(h) {
                    migrated.append(h)
                }
            } else if validSet.contains(s) && !migrated.contains(s) {
                migrated.append(s)
            }
        }
        return migrated
    }

    private init() {
        let rawData = UserDefaults.standard.data(forKey: Self.storageKey)
            ?? UserDefaults.standard.data(forKey: "cm.menubar.config.v4")

        if let data = rawData,
           let decoded = try? JSONDecoder().decode(PersistedPayload.self, from: data) {
            self.enabledCategories = Set(decoded.enabledCategories ?? MonitorModuleCategory.allCases)
            self.useDualLineMenuBar = decoded.useDualLineMenuBar
            self.useDualColumnDropdown = decoded.useDualColumnDropdown
            self.activeLeftPane = decoded.activeLeftPane
            let cleanedDecodedActive = decoded.activeMenuBarTokens.filter { $0 != .weatherIconTemp }
            self.activeMenuBarTokens = cleanedDecodedActive
            var migratedActive = Self.migrateSections(decoded.activeDropdownSections)
            let rawAll = decoded.allDropdownSectionsOrder ?? decoded.activeDropdownSections
            if !decoded.activeDropdownSections.isEmpty && !rawAll.contains(.dateTimeCard) && !migratedActive.contains(.dateTimeCard) {
                migratedActive.insert(.dateTimeCard, at: 0)
            }
            self.activeDropdownSections = migratedActive

            var initialAllTokens = (decoded.allMenuBarTokensOrder ?? cleanedDecodedActive).filter { $0 != .weatherIconTemp }
            for token in MenuBarTokenKind.configurableCases {
                if !initialAllTokens.contains(token) { initialAllTokens.append(token) }
            }
            self.allMenuBarTokensOrder = initialAllTokens
            let syncedActive = initialAllTokens.filter { cleanedDecodedActive.contains($0) }
            self.activeMenuBarTokens = syncedActive

            var initialAllSections = Self.migrateSections(rawAll)
            if !rawAll.contains(.dateTimeCard) && !initialAllSections.contains(.dateTimeCard) {
                initialAllSections.insert(.dateTimeCard, at: 0)
            }
            for sec in DropdownSectionKind.configurableCases {
                if !initialAllSections.contains(sec) { initialAllSections.append(sec) }
            }
            self.allDropdownSectionsOrder = initialAllSections
            self.activeDropdownSections = initialAllSections.filter { migratedActive.contains($0) }
            self.tokenFormatSelections = decoded.tokenFormatSelections ?? [:]
            self.sectionGridSpans = decoded.sectionGridSpans ?? [:]
            self.sectionHeightModes = decoded.sectionHeightModes ?? [:]

            self.weatherTempUnit = decoded.weatherTempUnit ?? "C"
            self.weatherShow24hHourly = decoded.weatherShow24hHourly ?? true
            self.weatherShow7Day = decoded.weatherShow7Day ?? true
            self.weatherShowExtraMetrics = decoded.weatherShowExtraMetrics ?? true
            self.cpuShowSparkline = decoded.cpuShowSparkline ?? true
            self.cpuShowPerCore = decoded.cpuShowPerCore ?? true
            self.cpuTopProcessesCount = decoded.cpuTopProcessesCount ?? 5
            self.cpuRefreshInterval = decoded.cpuRefreshInterval ?? 2.0
            self.memoryShowPressure = decoded.memoryShowPressure ?? true
            self.memoryShowBreakdown = decoded.memoryShowBreakdown ?? true
            self.disksShowExternalDrives = decoded.disksShowExternalDrives ?? true
            self.disksShowIoRate = decoded.disksShowIoRate ?? true
            self.networkShowPublicIP = decoded.networkShowPublicIP ?? true
            self.networkSpeedUnit = decoded.networkSpeedUnit ?? "bytes"
            self.networkPingDiagnosis = decoded.networkPingDiagnosis ?? true
            self.sensorFanMode = decoded.sensorFanMode ?? "auto"
            self.sensorTempUnit = decoded.sensorTempUnit ?? "C"
            self.batteryShowWattage = decoded.batteryShowWattage ?? true
            self.batteryShowHealth = decoded.batteryShowHealth ?? true
            self.batteryShowBluetooth = decoded.batteryShowBluetooth ?? true
            self.clockUse24Hour = decoded.clockUse24Hour ?? true
            self.clockShowDayOfWeek = decoded.clockShowDayOfWeek ?? true
            self.clockShowSeconds = decoded.clockShowSeconds ?? false
            self.menuBarColorMode = decoded.menuBarColorMode ?? .themeAccent
        } else {
            // 兼容迁移老版本 cm.menubar.config.v3
            let oldKey = "cm.menubar.config.v3"
            let loadedOldTokens: [MenuBarTokenKind]? = nil
            let loadedOldSections: [DropdownSectionKind]? = nil
            var loadedDualLine = true
            var loadedDualColumn = false
            let loadedLeftPane: CompanionLeftPaneTab = .weather

            if let oldData = UserDefaults.standard.data(forKey: oldKey),
               let oldJson = try? JSONSerialization.jsonObject(with: oldData) as? [String: Any] {
                if let dl = oldJson["useDualLineMenuBar"] as? Bool { loadedDualLine = dl }
                if let dc = oldJson["useDualColumnDropdown"] as? Bool { loadedDualColumn = dc }
            }

            self.enabledCategories = Set(MonitorModuleCategory.allCases)
            self.useDualLineMenuBar = loadedDualLine
            self.useDualColumnDropdown = loadedDualColumn
            self.activeLeftPane = loadedLeftPane
            let initActiveTokens = loadedOldTokens ?? [
                .cpuStacked,
                .memoryStacked,
                .networkStacked,
                .sensorTempStacked
            ]
            self.activeMenuBarTokens = initActiveTokens

            let initActiveSections = loadedOldSections.map(Self.migrateSections) ?? DropdownSectionKind.configurableCases
            self.activeDropdownSections = initActiveSections

            var defaultAllTokens: [MenuBarTokenKind] = initActiveTokens.filter { $0 != .weatherIconTemp }
            for token in MenuBarTokenKind.configurableCases {
                if !defaultAllTokens.contains(token) { defaultAllTokens.append(token) }
            }
            self.allMenuBarTokensOrder = defaultAllTokens

            var defaultAllSections: [DropdownSectionKind] = initActiveSections
            for sec in DropdownSectionKind.configurableCases {
                if !defaultAllSections.contains(sec) { defaultAllSections.append(sec) }
            }
            self.allDropdownSectionsOrder = defaultAllSections
            self.tokenFormatSelections = [:]
            self.sectionGridSpans = [:]
            self.sectionHeightModes = [:]

            self.weatherTempUnit = "C"
            self.weatherShow24hHourly = true
            self.weatherShow7Day = true
            self.weatherShowExtraMetrics = true
            self.cpuShowSparkline = true
            self.cpuShowPerCore = true
            self.cpuTopProcessesCount = 5
            self.cpuRefreshInterval = 2.0
            self.memoryShowPressure = true
            self.memoryShowBreakdown = true
            self.disksShowExternalDrives = true
            self.disksShowIoRate = true
            self.networkShowPublicIP = true
            self.networkSpeedUnit = "bytes"
            self.networkPingDiagnosis = true
            self.sensorFanMode = "auto"
            self.sensorTempUnit = "C"
            self.batteryShowWattage = true
            self.batteryShowHealth = true
            self.batteryShowBluetooth = true
            self.clockUse24Hour = true
            self.clockShowDayOfWeek = true
            self.clockShowSeconds = false
            self.menuBarColorMode = .themeAccent
        }
    }

    private func save() {
        let payload = PersistedPayload(
            enabledCategories: Array(enabledCategories),
            useDualLineMenuBar: useDualLineMenuBar,
            useDualColumnDropdown: useDualColumnDropdown,
            activeLeftPane: activeLeftPane,
            activeMenuBarTokens: activeMenuBarTokens,
            activeDropdownSections: activeDropdownSections,
            allMenuBarTokensOrder: allMenuBarTokensOrder,
            allDropdownSectionsOrder: allDropdownSectionsOrder,
            tokenFormatSelections: tokenFormatSelections,
            sectionGridSpans: sectionGridSpans,
            sectionHeightModes: sectionHeightModes,
            menuBarColorMode: menuBarColorMode,
            weatherTempUnit: weatherTempUnit,
            weatherShow24hHourly: weatherShow24hHourly,
            weatherShow7Day: weatherShow7Day,
            weatherShowExtraMetrics: weatherShowExtraMetrics,
            cpuShowSparkline: cpuShowSparkline,
            cpuShowPerCore: cpuShowPerCore,
            cpuTopProcessesCount: cpuTopProcessesCount,
            cpuRefreshInterval: cpuRefreshInterval,
            memoryShowPressure: memoryShowPressure,
            memoryShowBreakdown: memoryShowBreakdown,
            disksShowExternalDrives: disksShowExternalDrives,
            disksShowIoRate: disksShowIoRate,
            networkShowPublicIP: networkShowPublicIP,
            networkSpeedUnit: networkSpeedUnit,
            networkPingDiagnosis: networkPingDiagnosis,
            sensorFanMode: sensorFanMode,
            sensorTempUnit: sensorTempUnit,
            batteryShowWattage: batteryShowWattage,
            batteryShowHealth: batteryShowHealth,
            batteryShowBluetooth: batteryShowBluetooth,
            clockUse24Hour: clockUse24Hour,
            clockShowDayOfWeek: clockShowDayOfWeek,
            clockShowSeconds: clockShowSeconds
        )
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - 指标数据展示格式 (Preset Data Format)

    func formatPreset(for token: MenuBarTokenKind) -> TokenDisplayFormatPreset {
        let chosenId = tokenFormatSelections[token.id]
        if let id = chosenId, let found = token.availablePresets.first(where: { $0.id == id }) {
            return found
        }
        return token.availablePresets.first ?? TokenDisplayFormatPreset(id: "default", name: "Standard", topLine: "100%", bottomLine: "DATA", description: "Default display")
    }

    func setFormatPreset(for token: MenuBarTokenKind, presetId: String) {
        tokenFormatSelections[token.id] = presetId
    }

    // MARK: - Stats 预设一键应用 (Stats Preset Selector)

    var currentStatsPreset: StatsMenuBarPreset? {
        for preset in StatsMenuBarPreset.allCases {
            if activeMenuBarTokens == preset.tokens {
                var allMatched = true
                for token in preset.tokens {
                    if let expectedFormat = preset.formatOverrides[token],
                       formatPreset(for: token).id != expectedFormat {
                        allMatched = false
                        break
                    }
                }
                if allMatched { return preset }
            }
        }
        return nil
    }

    func applyStatsPreset(_ preset: StatsMenuBarPreset) {
        useDualLineMenuBar = true
        for (token, formatId) in preset.formatOverrides {
            tokenFormatSelections[token.id] = formatId
        }
        var newAllOrder = preset.tokens
        for token in allMenuBarTokensOrder where !newAllOrder.contains(token) && token != .weatherIconTemp {
            newAllOrder.append(token)
        }
        for token in MenuBarTokenKind.configurableCases where !newAllOrder.contains(token) {
            newAllOrder.append(token)
        }
        allMenuBarTokensOrder = newAllOrder
        activeMenuBarTokens = preset.tokens
    }

    // MARK: - 仪表盘卡片九宫格排版布局 (Dashboard Grid Assembly)

    func gridSpan(for section: DropdownSectionKind) -> DashboardGridSpan {
        if let raw = sectionGridSpans[section.id], let span = DashboardGridSpan(rawValue: raw) {
            return span
        }
        return defaultGridSpan(for: section)
    }

    func setGridSpan(for section: DropdownSectionKind, span: DashboardGridSpan) {
        sectionGridSpans[section.id] = span.rawValue
    }

    func defaultGridSpan(for section: DropdownSectionKind) -> DashboardGridSpan {
        return .full
    }

    // MARK: - 仪表盘卡片高度/密度控制 (Dashboard Card Height Mode)

    func heightMode(for section: DropdownSectionKind) -> DashboardCardHeightMode {
        if let raw = sectionHeightModes[section.id], let mode = DashboardCardHeightMode(rawValue: raw) {
            return mode
        }
        return .standard
    }

    func setHeightMode(for section: DropdownSectionKind, mode: DashboardCardHeightMode) {
        sectionHeightModes[section.id] = mode.rawValue
    }

    func setAllHeightModes(to mode: DashboardCardHeightMode) {
        for sec in DropdownSectionKind.configurableCases {
            sectionHeightModes[sec.id] = mode.rawValue
        }
    }

    // MARK: - 模块启用/禁用操作 (模块启用/禁用导航)

    func isCategoryEnabled(_ cat: MonitorModuleCategory) -> Bool {
        enabledCategories.contains(cat)
    }

    func toggleCategory(_ cat: MonitorModuleCategory) {
        if enabledCategories.contains(cat) {
            // 至少保留一个模块启用
            if enabledCategories.count > 1 {
                enabledCategories.remove(cat)
            }
        } else {
            enabledCategories.insert(cat)
        }
    }

    func setCategoryEnabled(_ cat: MonitorModuleCategory, enabled: Bool) {
        if enabled {
            enabledCategories.insert(cat)
        } else {
            if enabledCategories.count > 1 {
                enabledCategories.remove(cat)
            }
        }
    }

    // MARK: - 顶部菜单栏令牌增删、复选与拖动排序 (ITEMS TO SHOW IN MENUBAR)

    func isTokenEnabled(_ token: MenuBarTokenKind) -> Bool {
        activeMenuBarTokens.contains(token)
    }

    func setTokenEnabled(_ token: MenuBarTokenKind, isEnabled: Bool) {
        if isEnabled {
            if !activeMenuBarTokens.contains(token) {
                var updated = activeMenuBarTokens
                updated.append(token)
                activeMenuBarTokens = allMenuBarTokensOrder.filter { updated.contains($0) }
            }
        } else {
            if activeMenuBarTokens.count > 1, let idx = activeMenuBarTokens.firstIndex(of: token) {
                activeMenuBarTokens.remove(at: idx)
            }
        }
    }

    func toggleToken(_ token: MenuBarTokenKind) {
        setTokenEnabled(token, isEnabled: !isTokenEnabled(token))
    }

    /// 在顶部菜单栏仿真条上直接拖拽排序已启用的指标
    func moveActiveToken(from sourceIndex: Int, to destinationIndex: Int) {
        guard activeMenuBarTokens.indices.contains(sourceIndex),
              destinationIndex >= 0, destinationIndex < activeMenuBarTokens.count,
              sourceIndex != destinationIndex else { return }

        var updatedActive = activeMenuBarTokens
        let removed = updatedActive.remove(at: sourceIndex)
        updatedActive.insert(removed, at: destinationIndex)
        activeMenuBarTokens = updatedActive

        // 同步更新全量顺序，使已启用指标保持用户的直接拖拽顺序
        var newAllOrder = updatedActive
        for token in allMenuBarTokensOrder where !newAllOrder.contains(token) {
            newAllOrder.append(token)
        }
        allMenuBarTokensOrder = newAllOrder
    }

    func moveTokenInAll(from sourceIndex: Int, to destinationIndex: Int) {
        guard allMenuBarTokensOrder.indices.contains(sourceIndex),
              destinationIndex >= 0, destinationIndex <= allMenuBarTokensOrder.count else { return }
        let item = allMenuBarTokensOrder.remove(at: sourceIndex)
        let insertIndex = min(destinationIndex, allMenuBarTokensOrder.count)
        allMenuBarTokensOrder.insert(item, at: insertIndex)
        activeMenuBarTokens = allMenuBarTokensOrder.filter { activeMenuBarTokens.contains($0) }
    }

    func moveTokenInAll(from item: MenuBarTokenKind, to target: MenuBarTokenKind) {
        guard let srcIdx = allMenuBarTokensOrder.firstIndex(of: item),
              let tgtIdx = allMenuBarTokensOrder.firstIndex(of: target),
              srcIdx != tgtIdx else { return }
        let removed = allMenuBarTokensOrder.remove(at: srcIdx)
        allMenuBarTokensOrder.insert(removed, at: tgtIdx)
        activeMenuBarTokens = allMenuBarTokensOrder.filter { activeMenuBarTokens.contains($0) }
    }

    func moveTokenInAllDirection(from index: Int, direction: Int) {
        let target = index + direction
        guard allMenuBarTokensOrder.indices.contains(index),
              allMenuBarTokensOrder.indices.contains(target) else { return }
        allMenuBarTokensOrder.swapAt(index, target)
        activeMenuBarTokens = allMenuBarTokensOrder.filter { activeMenuBarTokens.contains($0) }
    }

    func addToken(_ token: MenuBarTokenKind) {
        setTokenEnabled(token, isEnabled: true)
    }

    func removeToken(_ token: MenuBarTokenKind) {
        setTokenEnabled(token, isEnabled: false)
    }

    func moveToken(from index: Int, direction: Int) {
        let target = index + direction
        guard activeMenuBarTokens.indices.contains(index),
              activeMenuBarTokens.indices.contains(target) else { return }
        moveActiveToken(from: index, to: target)
    }

    // MARK: - 下拉弹窗区块增删、复选与拖动排序 (ITEMS TO SHOW IN DROPDOWN)

    func isSectionEnabled(_ section: DropdownSectionKind) -> Bool {
        activeDropdownSections.contains(section)
    }

    func setSectionEnabled(_ section: DropdownSectionKind, isEnabled: Bool) {
        if isEnabled {
            if !activeDropdownSections.contains(section) {
                var updated = activeDropdownSections
                updated.append(section)
                activeDropdownSections = allDropdownSectionsOrder.filter { updated.contains($0) }
            }
        } else {
            if activeDropdownSections.count > 1, let idx = activeDropdownSections.firstIndex(of: section) {
                activeDropdownSections.remove(at: idx)
            }
        }
    }

    func toggleSection(_ section: DropdownSectionKind) {
        setSectionEnabled(section, isEnabled: !isSectionEnabled(section))
    }

    func moveSectionInAll(from sourceIndex: Int, to destinationIndex: Int) {
        guard allDropdownSectionsOrder.indices.contains(sourceIndex),
              destinationIndex >= 0, destinationIndex <= allDropdownSectionsOrder.count else { return }
        let item = allDropdownSectionsOrder.remove(at: sourceIndex)
        let insertIndex = min(destinationIndex, allDropdownSectionsOrder.count)
        allDropdownSectionsOrder.insert(item, at: insertIndex)
        activeDropdownSections = allDropdownSectionsOrder.filter { activeDropdownSections.contains($0) }
    }

    func moveSectionInAll(from item: DropdownSectionKind, to target: DropdownSectionKind) {
        guard let srcIdx = allDropdownSectionsOrder.firstIndex(of: item),
              let tgtIdx = allDropdownSectionsOrder.firstIndex(of: target),
              srcIdx != tgtIdx else { return }
        let removed = allDropdownSectionsOrder.remove(at: srcIdx)
        allDropdownSectionsOrder.insert(removed, at: tgtIdx)
        activeDropdownSections = allDropdownSectionsOrder.filter { activeDropdownSections.contains($0) }
    }

    func moveSectionInAllDirection(from index: Int, direction: Int) {
        let target = index + direction
        guard allDropdownSectionsOrder.indices.contains(index),
              allDropdownSectionsOrder.indices.contains(target) else { return }
        allDropdownSectionsOrder.swapAt(index, target)
        activeDropdownSections = allDropdownSectionsOrder.filter { activeDropdownSections.contains($0) }
    }

    func addSection(_ section: DropdownSectionKind) {
        setSectionEnabled(section, isEnabled: true)
    }

    func removeSection(_ section: DropdownSectionKind) {
        setSectionEnabled(section, isEnabled: false)
    }

    func moveSection(from index: Int, direction: Int) {
        let target = index + direction
        guard activeDropdownSections.indices.contains(index),
              activeDropdownSections.indices.contains(target) else { return }
        let sourceSection = activeDropdownSections[index]
        let targetSection = activeDropdownSections[target]
        moveSectionInAll(from: sourceSection, to: targetSection)
    }

    func resetToDefaults() {
        enabledCategories = Set(MonitorModuleCategory.allCases)
        useDualLineMenuBar = true
        useDualColumnDropdown = false
        activeLeftPane = .weather

        var defTokens: [MenuBarTokenKind] = [.cpuStacked, .memoryStacked, .networkStacked, .sensorTempStacked]
        for t in MenuBarTokenKind.configurableCases {
            if !defTokens.contains(t) { defTokens.append(t) }
        }
        allMenuBarTokensOrder = defTokens
        activeMenuBarTokens = [.cpuStacked, .memoryStacked, .networkStacked, .sensorTempStacked]

        allDropdownSectionsOrder = DropdownSectionKind.configurableCases
        activeDropdownSections = DropdownSectionKind.configurableCases

        tokenFormatSelections = [:]
        sectionGridSpans = [:]
        sectionHeightModes = [:]

        weatherTempUnit = "C"
        weatherShow24hHourly = true
        weatherShow7Day = true
        weatherShowExtraMetrics = true
        cpuShowSparkline = true
        cpuShowPerCore = true
        cpuTopProcessesCount = 5
        cpuRefreshInterval = 2.0
        memoryShowPressure = true
        memoryShowBreakdown = true
        disksShowExternalDrives = true
        disksShowIoRate = true
        networkShowPublicIP = true
        networkSpeedUnit = "bytes"
        networkPingDiagnosis = true
        sensorFanMode = "auto"
        sensorTempUnit = "C"
        batteryShowWattage = true
        batteryShowHealth = true
        batteryShowBluetooth = true
        clockUse24Hour = true
        clockShowDayOfWeek = true
        clockShowSeconds = false
        menuBarColorMode = .themeAccent
    }
}
