import SwiftUI
import AppKit

// MARK: - 主菜单栏下拉控制台 (MenuBarPopoverView)

struct MenuBarPopoverView: View {
    @ObservedObject var service = SystemTelemetryService.shared
    @ObservedObject var weather = WeatherService.shared
    @ObservedObject var geo = IPGeoService.shared
    @ObservedObject var config = MenuBarConfigStore.shared
    @ObservedObject var appConfig = AppConfigStore.shared
    @ObservedObject var flyoutState = SubcategoryFlyoutState.shared

    @State var isCaffeinateOn: Bool = MenuBarCompanion.shared.isCaffeinateActive

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        HStack(spacing: 0) {
            if config.useDualColumnDropdown {
                SubcategoryFlyoutRootView()
                    .frame(width: 330)
                    .background(
                        ZStack {
                            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                            StatsTheme.popupTint
                        }
                    )

                Rectangle()
                    .fill(Theme.sep)
                    .frame(width: 1)
            }

            mainColumn
                .frame(width: 340)
        }
        .coordinateSpace(name: "MenuBarPopoverSpace")
        .frame(width: config.useDualColumnDropdown ? 675 : 340)
        .background(
            ZStack {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                StatsTheme.popupTint
            }
        )
        .preferredColorScheme(Theme.isDark ? .dark : .light)
    }

    var mainColumn: some View {
        let activeSections = config.activeDropdownSections.filter { DropdownSectionKind.configurableCases.contains($0) }
        return VStack(spacing: AppConfig.UI.menuBarPopoverCardSpacing) {
            ForEach(activeSections) { sec in
                switch sec {
                case .dateTimeCard:
                    v158DateTimeCard
                case .weatherQuickCard:
                    v158WeatherCard
                case .cpuCard:
                    v158CpuCard
                case .ramCard:
                    v158MemoryCard
                case .networkCard:
                    v158NetworkCard
                case .diskCard:
                    v158DiskCard
                case .batteryCard:
                    v158BatteryCard
                case .sensorCard:
                    v158SensorsCard
                default:
                    EmptyView()
                }
            }

            // ⑧ 统一底部实用工具快捷坞 (严格保持 5 个快捷 Icon + 防休眠按钮不动)
            QuickUtilityDockView(isCaffeinateOn: $isCaffeinateOn)
        }
        .padding(AppConfig.UI.menuBarPopoverPadding)
        .contentShape(Rectangle())
        .onTapGesture {
            SubcategoryFlyoutState.shared.clearActiveSubcategory()
        }
        .onAppear {
            if !weather.current.isLoadedFromNetwork && !weather.isRefreshing {
                weather.refreshWeather()
            }
        }
    }

    // MARK: - Step 158 紧凑卡片容器 (兼容暗色/明亮 2 主题与 6 套配色)
    func v158GlassCard<Content: View>(
        subKind: CompanionSubcategoryKind,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let isHovered = flyoutState.activeSubcategory == subKind
        return content()
            .padding(.horizontal, 9)
            .padding(.vertical, 6.5)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Theme.sel : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isHovered ? Theme.accent.opacity(0.65) : Theme.sep, lineWidth: isHovered ? 1.0 : 0.8)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                    SubcategoryFlyoutState.shared.toggleSubcategory(subKind)
                }
            }
            .modifier(SubcategoryHoverModifier(kind: subKind))
    }

    // ① 日期 + 时间 + 今日日程入口卡片
    var v158DateTimeCard: some View {
        let now = Date()
        let timeFmt: DateFormatter = {
            let f = DateFormatter()
            f.locale = L10n.shared.currentLocale
            f.dateFormat = "HH:mm:ss"
            return f
        }()
        let dateFmt: DateFormatter = {
            let f = DateFormatter()
            f.locale = L10n.shared.currentLocale
            f.dateFormat = "MM-dd EEEE"
            return f
        }()
        let tzMinutes = TimeZone.current.secondsFromGMT() / 60
        let tzString = String(format: "UTC%@%02d:%02d", tzMinutes >= 0 ? "+" : "−", abs(tzMinutes) / 60, abs(tzMinutes) % 60)
        let weekOfYear = Calendar.current.component(.weekOfYear, from: now)

        return v158GlassCard(subKind: .calendar) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().stroke(StatsTheme.trackBg, lineWidth: 2.2)
                    Circle().trim(from: 0, to: 0.72)
                        .stroke(
                            LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "calendar")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }
                .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(timeFmt.string(from: now))
                            .font(.system(size: 13.5, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.text)
                        Text(tzString)
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Theme.accent.opacity(0.16)))
                            .foregroundColor(Theme.accent)
                    }
                    Text("\(dateFmt.string(from: now)) · \(L10n.format(.menuBarWeekNumberFormat, weekOfYear))")
                        .font(.system(size: 9.5))
                        .foregroundColor(Theme.sub)
                        .lineLimit(1)
                }
                Spacer()

                // 内存压力展示与极速释放微组件 (极速释放动效)
                MenuBarMemoryQuickReleaseWidget()
            }
        }
        .contextMenu {
            Button {
                MenuBarCompanion.shared.triggerOneClickClean()
            } label: {
                Label(L10n.localized(.oneClickCleanMenuTitle), systemImage: "sparkles")
            }
            Button {
                MenuBarCompanion.shared.openModuleManagementFromMenu()
            } label: {
                Label(L10n.localized(.actionOpenModuleManagement), systemImage: "square.grid.2x2")
            }
            Divider()
            Button {
                MenuBarCompanion.shared.openPreferencesFromMenu()
            } label: {
                Label(L10n.localized(.openPreferencesMenuTitle), systemImage: "gearshape")
            }
        }
    }

    // ② 天气速览卡片 (Step 118 紧凑展示，高对比度自适应天气图标)
    var v158WeatherCard: some View {
        let snap = weather.current
        let tempVal = snap.currentTemp
        let highVal = Double(snap.daily.first?.maxTemp ?? Int(tempVal.rounded()))
        let lowVal = Double(snap.daily.first?.minTemp ?? Int(tempVal.rounded()))
        let humVal = snap.humidity

        return v158GlassCard(subKind: .weather) {
            HStack(spacing: 8) {
                WeatherSymbolBadgeView(
                    iconName: snap.isLoadedFromNetwork ? snap.conditionIcon : "sun.max.fill"
                )
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(
                            snap.isLoadedFromNetwork
                                ? "\(snap.city) · \(snap.localizedConditionText) \(Int(tempVal.rounded()))℃"
                                : "\(snap.city) · \(snap.localizedConditionText)"
                        )
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)
                        if snap.isLoadedFromNetwork && !snap.regionAndCountry.isEmpty {
                            Text(snap.regionAndCountry)
                                .font(.system(size: 8, weight: .bold))
                                .padding(.horizontal, 4.5)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Theme.accent.opacity(0.16)))
                                .foregroundColor(Theme.accent)
                                .lineLimit(1)
                        }
                    }
                    Text(
                        snap.isLoadedFromNetwork
                            ? "H:\(Int(highVal.rounded()))° L:\(Int(lowVal.rounded()))° · \(L10n.localized(.menuBarWeatherHumidityLabel)) \(humVal)% · UV \(Int(snap.uvIndex.rounded()))"
                            : (weather.statusMessage ?? snap.localizedConditionText)
                    )
                    .font(.system(size: 9))
                    .foregroundColor(Theme.sub)
                    .lineLimit(1)
                }
                Spacer()
            }
        }
    }

    // ③ CPU 性能矩阵卡片
    var v158CpuCard: some View {
        let snap = service.latestSnapshot
        let cpu = snap?.cpu
        let total = cpu?.totalUsage ?? 0.0
        let usr = cpu?.userUsage ?? 0.0
        let sys = cpu?.systemUsage ?? 0.0
        let pct = Int((total * 100).rounded())
        let usrPct = Int((usr * 100).rounded())
        let sysPct = Int((sys * 100).rounded())
        let idlePct = max(0, 100 - usrPct - sysPct)
        let coreUsages = (cpu?.coreUsages.isEmpty == false)
            ? Array(cpu!.coreUsages.prefix(12))
            : Array(repeating: total, count: 8)
        let pCount = cpu?.pCoreCount ?? 4

        return v158GlassCard(subKind: .cpu) {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "cpu")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.accent)
                    Text(snap?.specs.chipName ?? "Apple Silicon")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)
                    Spacer()
                    Text("\(pct)%")
                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.accent)
                }
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<coreUsages.count, id: \.self) { idx in
                        ZStack(alignment: .bottom) {
                            Capsule().fill(StatsTheme.trackBg).frame(height: 13)
                            Capsule()
                                .fill(idx < pCount ? Theme.accent : Theme.green)
                                .frame(height: max(2.5, 13 * CGFloat(min(1.0, max(0.05, coreUsages[idx])))))
                        }
                    }
                }
                .frame(height: 13)
                HStack {
                    Text("\(L10n.localized(.userPrefix)) \(usrPct)%")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundColor(Theme.sub)
                    Spacer()
                    Text("\(L10n.localized(.systemPrefix)) \(sysPct)%")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundColor(Theme.sub)
                    Spacer()
                    Text("\(L10n.localized(.idlePrefix)) \(idlePct)%")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundColor(Theme.sub)
                }
            }
        }
    }

    // ④ 内存物理分段卡片
    var v158MemoryCard: some View {
        let mem = service.latestSnapshot?.memory
        let total = Double(max(1, mem?.totalBytes ?? Int64(ProcessInfo.processInfo.physicalMemory)))
        let used = mem?.usedBytes ?? 0
        let pct = Int(((mem?.usedRatio ?? 0.0) * 100).rounded())
        let appR = CGFloat(Double(mem?.appBytes ?? 0) / total)
        let wiredR = CGFloat(Double(mem?.wiredBytes ?? 0) / total)
        let compR = CGFloat(Double(mem?.compressedBytes ?? 0) / total)

        return v158GlassCard(subKind: .memory) {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "memorychip")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.accent)
                    Text(L10n.localized(.memory))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Text("\(L10n.localized(.pressurePrefix)) \(mem?.pressureLevel.localizedTitle ?? L10n.localized(.statusNormal))")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4.5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Theme.green.opacity(0.16)))
                        .foregroundColor(Theme.green)
                    Spacer()
                    Text("\(Fmt.size(used)) / \(Fmt.size(Int64(total)))")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.text)
                }
                HStack(spacing: 6) {
                    GeometryReader { geo in
                        let w = geo.size.width
                        ZStack(alignment: .leading) {
                            Capsule().fill(StatsTheme.trackBg)
                            HStack(spacing: 1) {
                                Rectangle().fill(Theme.accent).frame(width: max(4, w * appR))
                                Rectangle().fill(Theme.accent2).frame(width: max(4, w * wiredR))
                                Rectangle().fill(StatsTheme.thirdColor).frame(width: max(2, w * compR))
                            }
                            .clipShape(Capsule())
                        }
                    }
                    .frame(height: 5)
                    Text("\(pct)%")
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }

    // ⑤ 网络双向对流卡片
    var v158NetworkCard: some View {
        let net = service.latestSnapshot?.network
        let detail = net?.detail
        let flag = detail?.countryFlag.isEmpty == false ? detail!.countryFlag : "🌐"

        return v158GlassCard(subKind: .network) {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "wifi")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.accent)
                    Text(detail?.interfaceDisplayName ?? "Wi-Fi")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)
                    Spacer()
                    Text("\(flag) \(geo.publicIP)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Theme.sub)
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Text("↑").font(.system(size: 9.5, weight: .bold)).foregroundColor(Theme.red)
                        Text(net?.uploadSpeedText ?? "0 KB/s")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.text)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(StatsTheme.boxBg))

                    HStack(spacing: 4) {
                        Text("↓").font(.system(size: 9.5, weight: .bold)).foregroundColor(Theme.accent)
                        Text(net?.downloadSpeedText ?? "0 KB/s")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.text)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(StatsTheme.boxBg))
                }
            }
        }
    }

    // ⑤-B 磁盘存储与 I/O 速览卡片
    var v158DiskCard: some View {
        let snap = service.latestSnapshot
        let st = snap?.storage
        let io = snap?.diskIO
        let usedPct = Int(((st?.usedRatio ?? 0.0) * 100.0).rounded())
        let freeText = Fmt.size(st?.free ?? 0)
        let totalText = Fmt.size(st?.total ?? 0)

        return v158GlassCard(subKind: .disk) {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.accent)
                    Text(L10n.localized(.disks))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Spacer()
                    Text("\(L10n.localized(.labelFreeAvailable)) \(freeText) / \(totalText)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.sub)
                    Text("\(usedPct)%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(usedPct >= 90 ? Theme.red : Theme.accent)
                }
                HStack(spacing: 6) {
                    GeometryReader { geo in
                        let w = geo.size.width
                        let ratio = CGFloat(min(1.0, max(0.04, st?.usedRatio ?? 0.0)))
                        ZStack(alignment: .leading) {
                            Capsule().fill(StatsTheme.trackBg).frame(height: 5)
                            Capsule()
                                .fill(LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .leading, endPoint: .trailing))
                                .frame(width: w * ratio, height: 5)
                        }
                    }
                    .frame(height: 5)

                    Text(String(format: "R %.1f · W %.1f MB/s", io?.readMBPerSec ?? 0.0, io?.writeMBPerSec ?? 0.0))
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundColor(Theme.sub)
                        .lineLimit(1)
                }
            }
        }
    }

    // ⑥ 电池与蓝牙外设卡片
    var v158BatteryCard: some View {
        let snap = service.latestSnapshot
        let bat = snap?.battery
        let pct = bat?.percentage ?? 100
        let health = bat?.healthPercentage ?? 100
        let btList = snap?.bluetoothPeripherals ?? []
        let btSummary: String = {
            if !btList.isEmpty {
                let items = btList.prefix(3).map { "\($0.name) \($0.batteryPercent)%" }.joined(separator: " · ")
                return "\(L10n.localized(.menuBarBluetoothPeripheralsHeader)): \(items)"
            }
            return bat?.chargeEstimateText ?? L10n.localized(.statusNormal)
        }()

        return v158GlassCard(subKind: .battery) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(Theme.green.opacity(0.18)).frame(width: 24, height: 24)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(Theme.green)
                }
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text("\(L10n.localized(.battery)) · \(tr(.healthPrefix)) \(health)%")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(Theme.text)
                        Text(bat?.isCharging == true ? L10n.localized(.batteryChargingStateCharging) : L10n.localized(.statusNormal))
                            .font(.system(size: 8.5))
                            .foregroundColor(Theme.sub)
                    }
                    Text(btSummary)
                        .font(.system(size: 8.5))
                        .foregroundColor(Theme.sub)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(pct)%")
                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.green)
            }
        }
    }

    // ⑦ 硬件传感器与温控卡片 (悬停展示 SENSORS 悬浮窗)
    var v158SensorsCard: some View {
        let snap = service.latestSnapshot
        let cpuTemp = snap?.cpu.temperature
        let gpuTemp = snap?.gpu.temperature
        let fan = snap?.fan
        let totalW = snap?.powerBus?.totalWatts ?? snap?.cpu.powerWatts ?? 0.0
        let fanText: String = {
            guard let f = fan, f.hasFans else { return "Passive" }
            if f.fanCount > 1 {
                return "\(f.leftFanRPM)/\(f.rightFanRPM)"
            }
            return "\(f.rpm) rpm"
        }()

        return v158GlassCard(subKind: .fan) {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.accent)
                    Text(L10n.localized(.menuBarSensorsAndFansTitle))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Spacer()
                    Text(String(format: "%.1fW", totalW))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.accent)
                }
                HStack(spacing: 4) {
                    v158SensorChip(title: L10n.localized(.menuBarSensorCpuCoreShort), value: cpuTemp.map { "\($0)℃" } ?? "—", color: StatsTheme.thirdColor)
                    v158SensorChip(title: "GPU", value: gpuTemp.map { "\($0)℃" } ?? "—", color: Theme.green)
                    v158SensorChip(
                        title: L10n.localized(.menuBarSensorLrFansShort),
                        value: fanText,
                        color: Theme.accent
                    )
                }
            }
        }
    }

    func v158SensorChip(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(title)
                .font(.system(size: 8.5))
                .foregroundColor(Theme.sub)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2.5)
        .background(RoundedRectangle(cornerRadius: 5).fill(StatsTheme.boxBg))
        .frame(maxWidth: .infinity)
    }

    // MARK: - 顶部横幅
    var topHeaderSection: some View {
        let specs = service.latestSnapshot?.specs
        let score = specs?.healthScore ?? 100
        let grade = specs?.localizedHealthGrade ?? L10n.localized(.healthExcellent)

        return HStack(spacing: 9) {
            StatsPieChartView(
                segments: [(Double(score) / 100.0, Theme.accent)],
                centerText: "\(score)",
                lineWidth: 2.8,
                size: 28
            )

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(L10n.localized(.appBrandName))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.text)
                    Text("· \(grade)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.accent)
                }
                Text("\(specs?.chipName ?? "Apple Silicon") · \(specs?.uptimeCompactText ?? L10n.localized(.labelUptimePrefix))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.sub)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                MenuBarCompanion.shared.closeSystemPopover()
                AppState.shared?.openSettings(tab: "menubar")
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 10))
                    Text(L10n.localized(.config))
                        .font(.system(size: 10.5, weight: .medium))
                }
                .foregroundColor(Theme.sub)
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(StatsTheme.boxBg)
                .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help(L10n.localized(.menuBarConfigCustomizationHelp))
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }

    // MARK: - 综合总览内容 (基于可动态组合配置与显示的瀑布流卡片面板组件渲染)
    var overviewContent: some View {
        DynamicWaterfallFlowView(
            sections: config.activeDropdownSections.filter { $0 != .healthBanner },
            spacing: 8,
            spanProvider: { config.gridSpan(for: $0) }
        ) { section, span in
            sectionCardView(for: section, span: span)
        }
    }

    @ViewBuilder
    func sectionCardView(for section: DropdownSectionKind, span: DashboardGridSpan) -> some View {
        let heightMode = config.heightMode(for: section)
        switch section {
        case .dateTimeCard:
            v158DateTimeCard
        case .healthBanner:
            EmptyView()
        case .cpuCard:
            cpuBentoCard(heightMode: heightMode)
        case .gpuCard:
            gpuBentoCard(heightMode: heightMode)
        case .ramCard:
            ramBentoCard(heightMode: heightMode)
        case .diskCard:
            diskBentoCard(heightMode: heightMode)
        case .networkCard:
            networkBentoCard(heightMode: heightMode)
        case .sensorCard:
            sensorBentoCard(heightMode: heightMode)
        case .hardwareGrid:
            overviewBentoGrid
        case .batteryCard:
            overviewBatteryCard
        case .weatherQuickCard:
            overviewWeatherCard
        case .networkDetailCard:
            overviewNetworkCard
        case .topProcesses:
            overviewTopProcesses
        case .footerToolbar:
            QuickUtilityDockView(isCaffeinateOn: $isCaffeinateOn)
        }
    }

    // MARK: - Stats Portal 风格硬件总览卡片 (复刻 Modules/*/portal.swift)

    func cpuBentoCard(heightMode: DashboardCardHeightMode = .standard) -> some View {
        let snap = service.latestSnapshot
        let total = snap?.cpu.totalUsage ?? 0
        let sys = snap?.cpu.systemUsage ?? (total * 0.35)
        let usr = snap?.cpu.userUsage ?? (total * 0.65)
        let pct = Int((total * 100).rounded())

        return statsPortalCard(
            title: "CPU",
            pill: snap?.cpu.temperature.map { "\($0)℃" } ?? "\(snap?.cpu.pCoreCount ?? 0)P+\(snap?.cpu.eCoreCount ?? 0)E",
            icon: "cpu",
            iconColor: StatsTheme.primaryColor,
            subKind: .cpu,
            heightMode: heightMode
        ) {
            HStack(spacing: 8) {
                StatsPieChartView(
                    segments: [
                        (sys, StatsTheme.secondaryColor),
                        (usr, StatsTheme.primaryColor)
                    ],
                    centerText: "\(pct)%",
                    lineWidth: 4.5,
                    size: heightMode == .compact ? 38 : 44
                )

                VStack(alignment: .leading, spacing: 2) {
                    StatsColorRow(color: StatsTheme.primaryColor, title: L10n.localized(.userPrefix), value: "\(Int((usr * 100).rounded()))%", compact: true)
                    StatsColorRow(color: StatsTheme.secondaryColor, title: L10n.localized(.systemPrefix), value: "\(Int((sys * 100).rounded()))%", compact: true)
                    if heightMode != .compact {
                        StatsColorRow(color: StatsTheme.tertiaryColor, title: "E/P", value: "\(Int(((snap?.cpu.eCoreUsage ?? 0) * 100).rounded()))%/\(Int(((snap?.cpu.pCoreUsage ?? 0) * 100).rounded()))%", compact: true)
                    }
                }
            }

            StatsColumnChartView(
                coreUsages: snap?.cpu.coreUsages ?? [],
                pCount: snap?.cpu.pCoreCount ?? 4
            )
            .frame(height: heightMode == .compact ? 12 : 16)

            if heightMode == .expanded {
                Text(String(format: "Load: %.2f / %.2f / %.2f", snap?.cpu.loadAverage.0 ?? 0, snap?.cpu.loadAverage.1 ?? 0, snap?.cpu.loadAverage.2 ?? 0))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Theme.sub)
                    .lineLimit(1)
            }
        }
    }

    func gpuBentoCard(heightMode: DashboardCardHeightMode = .standard) -> some View {
        let snap = service.latestSnapshot
        let pct = Int((snap?.gpu.usagePercent ?? 0).rounded())
        let ratio = Double(pct) / 100.0

        return statsPortalCard(
            title: "GPU",
            pill: snap?.gpu.temperature.map { "\($0)℃" } ?? tr(.gpuCoresCountFormat, snap?.gpu.coreCount ?? 0),
            icon: "display",
            iconColor: StatsTheme.secondaryColor,
            subKind: .gpu,
            heightMode: heightMode
        ) {
            HStack(spacing: 8) {
                StatsPieChartView(
                    segments: [(ratio, StatsTheme.secondaryColor)],
                    centerText: "\(pct)%",
                    lineWidth: 4.5,
                    size: heightMode == .compact ? 38 : 44
                )

                VStack(alignment: .leading, spacing: 2) {
                    StatsColorRow(color: StatsTheme.secondaryColor, title: L10n.localized(.renderCores), value: "\(snap?.gpu.coreCount ?? 0)", compact: true)
                    StatsColorRow(color: StatsTheme.primaryColor, title: "Hz", value: "\(Int((snap?.cpu.displayFPS ?? 120).rounded())) Hz", compact: true)
                }
            }

            MiniWaveView(data: service.gpuHistory, color: StatsTheme.secondaryColor, fixedMax: 100.0)
                .padding(.horizontal, 3)
                .padding(.vertical, 2)
                .frame(height: heightMode == .compact ? 12 : 16)
                .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(StatsTheme.boxBg))
        }
    }

    func ramBentoCard(heightMode: DashboardCardHeightMode = .standard) -> some View {
        let snap = service.latestSnapshot
        let mem = snap?.memory
        let total = Double(max(1, mem?.totalBytes ?? 1))
        let appR = Double(mem?.appBytes ?? 0) / total
        let wiredR = Double(mem?.wiredBytes ?? 0) / total
        let compR = Double(mem?.compressedBytes ?? 0) / total
        let pct = Int(((mem?.usedRatio ?? 0) * 100).rounded())

        return statsPortalCard(
            title: L10n.localized(.memory),
            pill: mem?.pressureLevel.localizedTitle ?? tr(.statusNormal),
            icon: "memorychip",
            iconColor: StatsTheme.primaryColor,
            subKind: .memory,
            heightMode: heightMode
        ) {
            HStack(spacing: 8) {
                StatsPieChartView(
                    segments: [
                        (appR, StatsTheme.primaryColor),
                        (wiredR, StatsTheme.secondaryColor),
                        (compR, StatsTheme.quaternaryColor)
                    ],
                    centerText: "\(pct)%",
                    lineWidth: 4.5,
                    size: heightMode == .compact ? 38 : 44
                )

                VStack(alignment: .leading, spacing: 2) {
                    StatsColorRow(color: StatsTheme.primaryColor, title: tr(.usedLabel), value: Fmt.size(mem?.usedBytes ?? 0), compact: true)
                    StatsColorRow(color: StatsTheme.tertiaryColor, title: L10n.localized(.freeSpace), value: Fmt.size(mem?.freeBytes ?? 0), compact: true)
                    if heightMode != .compact {
                        StatsColorRow(color: StatsTheme.secondaryColor, title: "Swap", value: Fmt.size(mem?.swapUsedBytes ?? 0), compact: true)
                    }
                }
            }

            MiniAreaView(data: service.memoryHistory, color: StatsTheme.primaryColor, fixedMax: 100.0)
                .padding(.horizontal, 3)
                .frame(height: heightMode == .compact ? 12 : 16)
                .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(StatsTheme.boxBg))
        }
    }

    func diskBentoCard(heightMode: DashboardCardHeightMode = .standard) -> some View {
        let snap = service.latestSnapshot
        let ratio = snap?.storage?.usedRatio ?? 0
        let pct = Int((ratio * 100).rounded())

        return statsPortalCard(
            title: L10n.localized(.disks),
            pill: Fmt.size(snap?.storage?.total ?? 0),
            icon: "internaldrive",
            iconColor: StatsTheme.tertiaryColor,
            subKind: .disk,
            heightMode: heightMode
        ) {
            HStack(spacing: 8) {
                StatsPieChartView(
                    segments: [(ratio, StatsTheme.tertiaryColor)],
                    centerText: "\(pct)%",
                    lineWidth: 4.5,
                    size: heightMode == .compact ? 38 : 44
                )

                VStack(alignment: .leading, spacing: 2) {
                    StatsColorRow(color: StatsTheme.tertiaryColor, title: tr(.usedLabel), value: Fmt.size(snap?.storage?.used ?? 0), compact: true)
                    StatsColorRow(color: StatsTheme.primaryColor, title: L10n.localized(.freeSpace), value: String(format: "%.0fG", Double(snap?.storage?.free ?? 0) / 1_000_000_000.0), compact: true)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2.5).fill(StatsTheme.trackColor)
                    RoundedRectangle(cornerRadius: 2.5).fill(StatsTheme.tertiaryColor)
                        .frame(width: max(4, proxy.size.width * CGFloat(ratio)))
                }
            }
            .frame(height: 6)
            .padding(.top, 2)
        }
    }

    func networkBentoCard(heightMode: DashboardCardHeightMode = .standard) -> some View {
        let snap = service.latestSnapshot
        return statsPortalCard(
            title: L10n.localized(.network),
            pill: snap?.network.interfaceType ?? "Wi-Fi",
            icon: "network",
            iconColor: StatsTheme.primaryColor,
            subKind: .network,
            heightMode: heightMode
        ) {
            VStack(alignment: .leading, spacing: 3) {
                StatsColorRow(
                    color: StatsTheme.primaryColor,
                    title: "↓ IN",
                    value: snap?.network.downloadSpeedText ?? "0 KB/s",
                    compact: true
                )
                StatsColorRow(
                    color: StatsTheme.secondaryColor,
                    title: "↑ OUT",
                    value: snap?.network.uploadSpeedText ?? "0 KB/s",
                    compact: true
                )
            }

            DualStreamWaveView(
                primaryData: service.netDownloadHistory,
                secondaryData: service.netUploadHistory,
                primaryColor: StatsTheme.primaryColor,
                secondaryColor: StatsTheme.secondaryColor,
                isSpeedKB: true
            )
            .padding(.horizontal, 3)
            .frame(height: heightMode == .compact ? 14 : 20)
            .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(StatsTheme.boxBg))
        }
    }

    func sensorBentoCard(heightMode: DashboardCardHeightMode = .standard) -> some View {
        let snap = service.latestSnapshot
        let tempC = Double(snap?.cpu.temperature ?? 42)
        let normTemp = min(1.0, max(0.05, (tempC - 25.0) / 75.0))

        return statsPortalCard(
            title: L10n.localized(.sensors),
            pill: snap?.cpu.temperature.map { "\($0)℃" } ?? "SMC",
            icon: "fanblades.fill",
            iconColor: StatsTheme.secondaryColor,
            subKind: .fan,
            heightMode: heightMode
        ) {
            HStack(spacing: 8) {
                StatsGaugeChartView(
                    value: normTemp,
                    title: snap?.cpu.temperature.map { "\($0)°C" } ?? "42°C",
                    size: CGSize(width: 44, height: 36)
                )

                VStack(alignment: .leading, spacing: 2) {
                    StatsColorRow(color: StatsTheme.secondaryColor, title: "RPM", value: "\(snap?.fan.rpm ?? 0)", compact: true)
                    StatsColorRow(color: StatsTheme.primaryColor, title: "Pwr", value: String(format: "%.1fW", snap?.powerBus?.totalWatts ?? snap?.cpu.powerWatts ?? 0), compact: true)
                }
            }

            MiniAreaView(data: service.fanHistory, color: StatsTheme.secondaryColor, unitSuffix: " RPM", valueFormat: "%.0f")
                .padding(.horizontal, 3)
                .frame(height: heightMode == .compact ? 12 : 16)
                .background(RoundedRectangle(cornerRadius: 4, style: .continuous).fill(StatsTheme.boxBg))
        }
    }

    var overviewBentoGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        return LazyVGrid(columns: cols, spacing: 8) {
            cpuBentoCard()
            gpuBentoCard()
            ramBentoCard()
            diskBentoCard()
            networkBentoCard()
            sensorBentoCard()
        }
    }

    func statsPortalCard<Content: View>(
        title: String,
        pill: String,
        icon: String,
        iconColor: Color,
        subKind: CompanionSubcategoryKind,
        heightMode: DashboardCardHeightMode = .standard,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        let isHovered = flyoutState.activeSubcategory == subKind

        return ModernBentoCard(isHighlighted: isHovered, cornerRadius: 8, padding: 8) {
            VStack(alignment: .leading, spacing: heightMode == .compact ? 4 : 6) {
                // Stats PortalHeader 风格顶栏
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(iconColor)
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Spacer()
                    MiniPillTag(pill)
                }

                content()
            }
            .frame(minHeight: heightMode == .compact ? 52 : (heightMode == .standard ? 76 : 110))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                SubcategoryFlyoutState.shared.toggleSubcategory(subKind)
            }
        }
        .modifier(SubcategoryHoverModifier(kind: subKind))
    }

    // 电池横向 Portal 卡片 (复刻 Modules/Battery/portal.swift)
    var overviewBatteryCard: some View {
        let bat = service.latestSnapshot?.battery
        let isHovered = flyoutState.activeSubcategory == .battery

        return ModernBentoCard(isHighlighted: isHovered, cornerRadius: 8, padding: 8) {
            if let bat, bat.isPresent {
                HStack(spacing: 10) {
                    StatsPieChartView(
                        segments: [(Double(bat.percentage) / 100.0, bat.percentage < 20 ? Theme.red : Theme.green)],
                        centerText: "\(bat.percentage)%",
                        lineWidth: 4.5,
                        size: 42
                    )

                    VStack(alignment: .leading, spacing: 2.5) {
                        HStack {
                            Text(L10n.localized(.battery))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Theme.text)
                            Spacer()
                            StatsStatusBadge(
                                text: bat.isCharging ? L10n.localized(.batteryChargingStateCharging) : L10n.localized(.statusNormal),
                                isPositive: true
                            )
                        }
                        StatsColorRow(color: Theme.green, title: tr(.healthPrefix), value: "\(bat.healthPercentage)% · \(bat.cycleCount) cyc", compact: true)
                        StatsColorRow(color: StatsTheme.primaryColor, title: L10n.localized(.labelBatteryRemainingEstimate), value: bat.chargeEstimateText, compact: true)
                    }
                }
            } else {
                let sysW = (service.latestSnapshot?.cpu.powerWatts ?? 0) + (service.latestSnapshot?.gpu.powerWatts ?? 0)
                HStack {
                    Label(L10n.localized(.menuBarAcPowerDirectLabel), systemImage: "bolt.circle.fill")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Theme.text)
                    Spacer()
                    Text(String(format: tr(.chipPowerFormat), sysW))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Theme.green)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                SubcategoryFlyoutState.shared.toggleSubcategory(.battery)
            }
        }
        .modifier(SubcategoryHoverModifier(kind: .battery))
    }

    // 天气快捷卡 (Stats Portal Style)
    var overviewWeatherCard: some View {
        let snap = weather.current
        let isHovered = flyoutState.activeSubcategory == .weather
        let tempText = snap.isLoadedFromNetwork
            ? String(format: config.weatherTempUnit == "F" ? "%.0f°F" : "%.0f°C", config.weatherTempUnit == "F" ? (snap.currentTemp * 9.0 / 5.0 + 32.0) : snap.currentTemp)
            : "--°"

        return ModernBentoCard(isHighlighted: isHovered, cornerRadius: 8, padding: 8) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(StatsTheme.boxBg)
                        .frame(width: 28, height: 28)
                    WeatherAdaptiveIconView(iconName: snap.conditionIcon, fontSize: 14)
                }
                VStack(alignment: .leading, spacing: 1.5) {
                    HStack(spacing: 5) {
                        Text(snap.city)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.text)
                        Text("· \(snap.localizedConditionText)")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(Theme.sub)
                            .lineLimit(1)
                    }
                    HStack(spacing: 8) {
                        Text(String(format: tr(.weatherLiveTempFormat), snap.currentTemp))
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(Theme.sub)
                        if snap.isLoadedFromNetwork {
                            Text("💧\(snap.humidity)%")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(Theme.sub)
                        }
                    }
                }
                Spacer()
                MiniPillTag(tempText)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                SubcategoryFlyoutState.shared.toggleSubcategory(.weather)
            }
        }
        .modifier(SubcategoryHoverModifier(kind: .weather))
    }

    // 网络快速卡
    var overviewNetworkCard: some View {
        let detail = service.latestSnapshot?.network.detail
        let flag = detail?.countryFlag.isEmpty == false ? detail!.countryFlag : "🌐"

        return ModernBentoCard(cornerRadius: 8, padding: 8) {
            HStack(spacing: 8) {
                Text(flag)
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(tr(.publicIpPrefix)): \(geo.publicIP)")
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.text)
                    Text("\(tr(.lanPrefix)): \(detail?.localIPv4 ?? "—") · \(tr(.latencyPrefix)): \(detail?.latencyMs.map { "\($0)ms" } ?? "—")")
                        .font(.system(size: 9.5))
                        .foregroundColor(Theme.sub)
                }
                Spacer()
                StatsStatusBadge(text: "UP", isPositive: true)
                Button {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        SubcategoryFlyoutState.shared.toggleSubcategory(.network)
                    }
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.sub)
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
        }
    }

    // 高占用进程 (对齐 Stats Top Processes)
    var overviewTopProcesses: some View {
        let list = (service.latestSnapshot?.topProcesses ?? []).prefix(5)

        return ModernBentoCard(cornerRadius: 8, padding: 8) {
            VStack(alignment: .leading, spacing: 4) {
                StatsSeparatorHeader(title: L10n.localized(.menuBarTopActiveAppsTitle))

                ForEach(list) { proc in
                    ProcessRowView(proc: proc)
                }
            }
        }
    }
}

// MARK: - 内存压力与一键释放微组件

struct MenuBarMemoryQuickReleaseWidget: View {
    @ObservedObject private var telemetry = SystemTelemetryService.shared
    @State private var isReleasing: Bool = false
    @State private var releaseSuccess: Bool = false
    @State private var rotationAngle: Double = 0.0
    @State private var isHovering: Bool = false

    private var usedRatio: Double {
        telemetry.latestSnapshot?.memory.usedRatio ?? 0.68
    }

    private var percent: Int {
        Int((usedRatio * 100.0).rounded())
    }

    private var pressureColor: Color {
        let level = telemetry.latestSnapshot?.memory.pressureLevel ?? .normal
        switch level {
        case .normal: return Theme.green
        case .warning: return Theme.amber
        case .critical: return Theme.red
        }
    }

    var body: some View {
        Button {
            triggerMemoryPurge()
        } label: {
            HStack(spacing: 5) {
                // 微型环形压力进度表 / 旋转清理球
                ZStack {
                    Circle()
                        .stroke(StatsTheme.trackBg, lineWidth: 2.2)
                        .frame(width: 24, height: 24)

                    Circle()
                        .trim(from: 0, to: isReleasing ? 0.75 : CGFloat(max(0.05, min(1.0, usedRatio))))
                        .stroke(
                            LinearGradient(
                                colors: releaseSuccess ? [Theme.green, Theme.green.opacity(0.8)] : [Theme.accent, pressureColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
                        )
                        .rotationEffect(.degrees(isReleasing ? rotationAngle : -90))
                        .frame(width: 24, height: 24)

                    if isReleasing {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.accent)
                            .rotationEffect(.degrees(rotationAngle))
                    } else if releaseSuccess {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.green)
                    } else {
                        Image(systemName: "memorychip")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Theme.accent)
                    }
                }

                VStack(alignment: .leading, spacing: 0.5) {
                    if isReleasing {
                        Text(L10n.localized(.memoryReleasing))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.accent)
                    } else if releaseSuccess {
                        Text(L10n.localized(.memoryReleased))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.green)
                    } else {
                        Text("\(percent)%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.text)
                        Text(isHovering ? L10n.localized(.actionFreeMemory) : L10n.localized(.healthDimMemory))
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(isHovering ? Theme.accent : Theme.sub)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3.5)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isHovering || isReleasing ? Theme.accent.opacity(0.12) : StatsTheme.boxBg.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isHovering ? Theme.accent.opacity(0.4) : Color.clear, lineWidth: 0.8)
            )
            .scaleEffect(releaseSuccess ? 1.05 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: releaseSuccess)
        }
        .buttonStyle(.plain)
        .onHover { h in
            isHovering = h
        }
        .help(L10n.localized(.memoryQuickReleasePrompt))
        .disabled(isReleasing)
    }

    private func triggerMemoryPurge() {
        guard !isReleasing else { return }
        isReleasing = true
        releaseSuccess = false
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)

        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        telemetry.purgeMemory { ok in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isReleasing = false
                releaseSuccess = ok
                rotationAngle = 0
            }
            if ok {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
                DispatchQueue.main.asyncAfter(deadline: .now() + AppConfig.UI.memoryReleaseToastDelay) {
                    withAnimation {
                        releaseSuccess = false
                    }
                }
            }
        }
    }
}
