import SwiftUI
import AppKit

// ============================================================
//  LiveMonitorView —— 实时系统状态总览与进程管理看板 (100% 真实硬件数据)
//
//  核心特性：
//    1. 顶部硬件规格状态条 + 联网实况天气胶囊；
//    2. 8 宫格 Bento HUD 硬件遥测矩阵 (2行 x 4列)：
//       - 健康度 (综合权重评分 + 动态自转 3D 太阳恒星球体)
//       - CPU (SMC/HID 真实温度 + P/E 核分色柱状图 + IOReport 真实功耗 W)
//       - GPU (IOAccelerator 真实利用率 + 真实温度 + IOReport 真实功耗 W)
//       - 内存 (Mach 真实物理内存 + 压力等级 + 真实 vm.swapusage 交换空间)
//       - 电池与电源 (AppleSmartBattery 真实健康度/循环/充放电瓦数/充满预估/最高能耗应用)
//       - 可用空间与磁盘 I/O (真实剩余容量 + IOBlockStorageDriver 实时读写 MB/s)
//       - 网络与公网 IP (上下行双波形图 + 可点击的 Wi-Fi ⓘ 网络详情浮窗 + TCP 延迟 ms)
//       - 风扇与温控 (SMC 真实 F0Ac RPM + 自动/降温/强冷档位控制 + 无风扇机型自适应)
//    3. 底部进程实时监控面板：支持搜索过滤、按 CPU/内存/能耗/PID 排序、进程用途解释与安全终止进程；
//    4. 100% 适配浅色/暗色模式与预设主题色方案，支持 10 门主流语言。
// ============================================================

struct LiveMonitorView: View {
    @ObservedObject var service = SystemTelemetryService.shared
    @ObservedObject var weatherService = WeatherService.shared
    @ObservedObject var geoService = IPGeoService.shared
    @ObservedObject var config = AppConfigStore.shared
    @ObservedObject var l10n = L10n.shared

    @State var terminatingProcess: MonitoredProcessItem?
    @State var showConfirmAlert: Bool = false
    @State var showNetworkDetailPopover: Bool = false
    @State var showWeatherDetailPopover: Bool = false
    @State var processSearchText: String = ""
    @State var processSortOrder: ProcessSortKey = .cpu
    @State var inspectedProcess: MonitoredProcessItem?

    enum ProcessSortKey: String, CaseIterable, Identifiable {
        case cpu = "% CPU"
        case memory = "memory"
        case energy = "energy"
        case pid = "PID"
        var id: String { rawValue }

        var localizedTitle: String {
            switch self {
            case .cpu:    return "% CPU"
            case .memory: return tr(.memory)
            case .energy: return tr(.energyImpact)
            case .pid:    return "PID"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Divider().background(Theme.sep)

            ScrollView(showsIndicators: true) {
                VStack(alignment: .leading, spacing: 14) {
                    metricsGrid
                    processTableSection
                }
                .padding(.horizontal, 30)
                .padding(.top, 14)
                .padding(.bottom, 22)
            }
        }
        .background(Color.clear)
        .onAppear {
            service.subscribe()
        }
        .onDisappear {
            service.unsubscribe()
        }
        .alert(isPresented: $showConfirmAlert) {
            Alert(
                title: Text(L10n.localized(.terminateProcessConfirmationTitle)),
                message: Text(tr(
                    .terminateProcessConfirmMessageFormat,
                    terminatingProcess?.name ?? "",
                    terminatingProcess?.pid ?? 0
                )),
                primaryButton: .destructive(Text(L10n.localized(.terminateProcess))) {
                    if let proc = terminatingProcess {
                        let res = service.terminate(process: proc, force: false)
                        AppState.shared?.showToast(res.message, kind: res.success ? .success : .error)
                    }
                },
                secondaryButton: .cancel(Text(L10n.localized(.actionCancel)))
            )
        }
    }

    // MARK: - 0. 顶部标题与硬件规格副标题栏

    var topHeaderStrip: some View {
        let specs = service.latestSnapshot?.specs
        let w = weatherService.current

        return HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.localized(.moduleLiveMonitor))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.text)

                if let specs {
                    Text("\(specs.modelName) · \(specs.chipName) · \(specs.memorySizeText) · \(specs.osVersionText) · \(L10n.localized(.systemUptimeLabel)) \(specs.uptimeText)")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                        .monospacedDigit()
                } else {
                    Text(L10n.localized(.liveMonitorHeroSubtitle))
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                }
            }

            Spacer(minLength: 12)

            // 联网实时天气快捷胶囊
            Button {
                showWeatherDetailPopover.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: w.conditionIcon)
                        .renderingMode(.original)
                        .font(.system(size: 12))
                    if w.isLoadedFromNetwork {
                        Text("\(w.city) · \(String(format: "%.1f°C", w.currentTemp)) · \(w.conditionText)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.text)
                    } else {
                        Text(L10n.localized(.weatherLocatingEllipsis))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.sub)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule(style: .continuous).fill(Theme.card))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showWeatherDetailPopover, arrowEdge: .bottom) {
                WeatherPopoverView()
            }
        }
    }

    // MARK: - 1. 顶部 8 大指标网格 (2 行 x 4 列)

    var metricsGrid: some View {
        let snap = service.latestSnapshot
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return LazyVGrid(columns: columns, spacing: 12) {
            healthCard(snap)
            cpuCard(snap?.cpu)
            gpuCard(snap?.gpu)
            memoryCard(snap?.memory)

            batteryCard(snap?.battery, snap: snap)
            storageCard(snap?.storage, diskIO: snap?.diskIO)
            networkCard(snap?.network)
            fanCard(snap?.fan, cpuTemp: snap?.cpu.temperature)
        }
    }

    // MARK: 卡片 1: 健康度
    func healthCard(_ snap: TelemetrySnapshot?) -> some View {
        let specs = snap?.specs
        let score = specs?.healthScore ?? 95
        let grade = specs?.localizedHealthGrade ?? L10n.localized(.healthExcellent)
        let diag = (specs?.healthDiagnosis.isEmpty ?? true) ? L10n.localized(.samplingHardwareStatusPrompt) : specs!.healthDiagnosis
        let uptime = specs?.uptimeText ?? "—"

        return BaseCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.amber)
                    Text(L10n.localized(.healthScore))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.text)
                    Spacer()
                }

                HStack(spacing: 4) {
                    let chip = (specs?.chipName ?? "Apple Silicon").replacingOccurrences(of: "Apple ", with: "")
                    SpecTag(chip)
                    SpecTag(specs?.memorySizeText ?? "—")
                    SpecTag(specs?.osVersionText ?? "macOS")
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(score)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                    Text(grade)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(score >= 85 ? Theme.green : Theme.amber)
                }
                .padding(.top, 2)

                Text(diag)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)

                let uptimeDisplay = uptime.components(separatedBy: " · ").first ?? uptime
                Text(uptimeDisplay)
                    .font(.system(size: 10.5))
                    .foregroundStyle(Theme.tert)
                    .lineLimit(1)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: 卡片 2: CPU
    func cpuCard(_ cpu: CPUSnapshot?) -> some View {
        let usage = cpu?.totalUsage ?? 0.0
        let cores = cpu?.coreUsages ?? []
        let pCount = cpu?.pCoreCount ?? 0
        let eCount = cpu?.eCoreCount ?? 0
        let tempBadge = cpu?.temperature.map { "\($0)℃" } ?? (pCount > 0 ? "\(pCount)P+\(eCount)E" : "SoC")
        let wattsText = cpu?.powerWatts.map { String(format: " · %.1fW", $0) } ?? ""
        let coreDesc = (pCount > 0 && eCount > 0) ? "\(pCount)P+\(eCount)E · " : (cores.isEmpty ? "" : "\(cores.count) Cores · ")
        let load = cpu?.localizedLoadText ?? L10n.localized(.statusLowLoad)

        return BaseCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.green)
                        Text("CPU")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.text)
                    }
                    Spacer()
                    PillTag(tempBadge)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int((usage * 100).rounded()))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                    Text("%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.sub)
                }

                CoreBarsView(coreUsages: cores, eCoreCount: eCount)
                    .frame(height: 24)

                Text("\(coreDesc)\(load)\(wattsText)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)
            }
        }
    }

    // MARK: 卡片 3: GPU
    func gpuCard(_ gpu: GPUSnapshot?) -> some View {
        let usage = gpu?.usagePercent ?? 0.0
        let cores = gpu?.coreCount ?? 0
        let tempBadge = gpu?.temperature.map { "\($0)℃" } ?? (cores > 0 ? "\(cores) Cores" : "Metal")
        let wattsText = gpu?.powerWatts.map { String(format: " · %.1fW", $0) } ?? ""
        let corePrefix = cores > 0 ? "\(cores) GPU · " : ""
        let load = gpu?.localizedLoadText ?? L10n.localized(.statusLowLoad)

        return BaseCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "cpu.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.amber)
                        Text("GPU")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.text)
                    }
                    Spacer()
                    PillTag(tempBadge)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(usage.rounded()))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                    Text("%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.sub)
                }

                SparklineWaveView(data: service.gpuHistory, color: Theme.amber)
                    .frame(height: 24)

                Text("\(corePrefix)\(load)\(wattsText)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)
            }
        }
    }

    // MARK: 卡片 4: 内存
    func memoryCard(_ mem: MemorySnapshot?) -> some View {
        let isValid = mem?.isSampleValid ?? false
        let usedRatio = mem?.usedRatio ?? 0.0
        let pressure = isValid ? (mem?.pressureLevel.localizedTitle ?? L10n.localized(.statusNormal)) : "—"
        let usedBytes = mem?.usedBytes ?? 0
        let swapBytes = mem?.swapUsedBytes ?? 0

        return BaseCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "memorychip")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.accent)
                        Text(L10n.localized(.memory))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.text)
                    }
                    Spacer()
                    PillTag("\(L10n.localized(.labelPressure)) \(pressure)")
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(isValid ? "\(Int((usedRatio * 100).rounded()))" : "—")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                    if isValid {
                        Text("%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.sub)
                    }
                }

                AreaWaveView(data: service.memoryHistory, color: Theme.accent)
                    .frame(height: 24)

                Text(isValid ? "\(Fmt.size(usedBytes)) · \(L10n.localized(.swapSpace)) \(Fmt.size(swapBytes))" : "—")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)
            }
        }
    }

    // MARK: 卡片 5: 电池与电源
    func batteryCard(_ bat: BatterySnapshot?, snap: TelemetrySnapshot?) -> some View {
        return BaseCard {
            if let bat, bat.isPresent {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: bat.isCharging ? "battery.100.bolt" : "battery.100")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.green)
                                Text(L10n.localized(.battery))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.text)
                            }
                            Spacer()
                            PillTag("\(bat.healthPercentage)%")
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(bat.percentage)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.text)
                            Text("%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.sub)
                        }

                        Text((bat.percentage >= 100 && bat.isPluggedIn) ? L10n.localized(.batteryFullyCharged) : bat.chargeEstimateText)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.sub)
                            .lineLimit(1)

                        Text("\(L10n.localized(.labelTopEnergyUsage)) \(bat.topEnergyApp)")
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.tert)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    BatteryRingView(percent: Double(bat.percentage) / 100.0, isCharging: bat.isCharging)
                        .frame(width: 38, height: 38)
                        .padding(.top, 22)
                }
            } else {
                let totalW = (snap?.cpu.powerWatts ?? 0) + (snap?.gpu.powerWatts ?? 0)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.green)
                            Text(L10n.localized(.systemPowerWatts))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.text)
                        }
                        Spacer()
                        PillTag(L10n.localized(.acPower))
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", totalW))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.text)
                        Text("W")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.sub)
                    }

                    Text(L10n.localized(.desktopAcPowerSupplying))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.sub)

                    Text("\(L10n.localized(.labelTopEnergyUsage)) \(snap?.topProcesses.first?.name ?? "—")")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.tert)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: 卡片 6: 可用空间与磁盘读写 I/O
    func storageCard(_ st: StorageSnapshot?, diskIO: DiskIOSnapshot?) -> some View {
        let total = st?.total ?? 0
        let free = st?.free ?? 0
        let used = max(0, total - free)
        let usedPct = total > 0 ? Int((Double(used) / Double(total) * 100).rounded()) : 0
        let rMB = diskIO?.readMBPerSec ?? 0
        let wMB = diskIO?.writeMBPerSec ?? 0

        return BaseCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "internaldrive")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.accent)
                        Text(L10n.localized(.freeSpace))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.text)
                    }
                    Spacer()
                    PillTag(Fmt.size(total))
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", Double(free) / 1_000_000_000.0))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                        .monospacedDigit()
                    Text("GB")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.sub)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.sep)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Theme.accent, Theme.accent2],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: max(8, proxy.size.width * CGFloat(usedPct) / 100.0))
                    }
                }
                .frame(height: 7)
                .padding(.vertical, 4)

                HStack {
                    Text("\(L10n.localized(.labelUsed)) \(Fmt.size(used)) · \(usedPct)%")
                    Spacer()
                    if rMB > 0.5 || wMB > 0.5 {
                        Text(String(format: "%.1f MB/s", rMB + wMB))
                            .monospacedDigit()
                    }
                }
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.sub)
                .lineLimit(1)
            }
        }
    }

    // MARK: 卡片 7: 网络与公网 IP 诊断浮窗
    func networkCard(_ net: NetworkTrafficSnapshot?) -> some View {
        let down = net?.downloadSpeedText ?? "0 KB/s"
        let up = net?.uploadSpeedText ?? "0 KB/s"
        let ifType = net?.interfaceType ?? "Wi-Fi"
        let isLowLatency = net?.isLowLatencyEnabled ?? false
        let rttText = net?.detail.latencyMs.map { " · \($0)ms" } ?? ""

        return BaseCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "network")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.accent)
                        Text(L10n.localized(.network))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.text)
                    }
                    Spacer()
                    Button {
                        showNetworkDetailPopover.toggle()
                    } label: {
                        PillTag("\(ifType)\(rttText) ⓘ")
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showNetworkDetailPopover, arrowEdge: .bottom) {
                        NetworkDetailPopoverCard(detail: net?.detail)
                    }
                }

                Text(down)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)

                SparklineWaveView(data: service.netDownloadHistory, color: Theme.green)
                    .frame(height: 24)

                HStack {
                    Text("\(L10n.localized(.upload)) \(up)")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    Button(action: {
                        service.toggleLowLatency()
                    }) {
                        Text(isLowLatency ? L10n.localized(.lowLatencyOn) : L10n.localized(.enableLowLatency))
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(isLowLatency ? Theme.green : Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: 卡片 8: 风扇转速监控与 SoC 温度
    func fanCard(_ fan: FanSnapshot?, cpuTemp: Int?) -> some View {
        let hasFans = fan?.hasFans ?? false
        let rpm = fan?.rpm ?? 0
        let pct = fan?.percentage ?? 0
        let mode = fan?.mode ?? "auto"
        let note = fan?.localizedMode ?? L10n.localized(.menuBarFanModeSystemAuto)

        return BaseCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "fanblades.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.amber)
                        Text(L10n.localized(.fanSpeedMonitor))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.text)
                    }
                    Spacer()
                    PillTag("\(L10n.localized(.fanSpeedShort)) \(pct)%")
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(NumberFormatter.localizedString(from: NSNumber(value: rpm), number: .decimal))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)
                        .monospacedDigit()
                        .fixedSize(horizontal: true, vertical: false)
                    Text("RPM")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    if let t = cpuTemp {
                        Text("SoC \(t)℃")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.tert)
                    }
                }

                HStack(spacing: 5) {
                    FanModeButton(title: L10n.localized(.fanModeAuto), isSelected: mode == "auto") {
                        service.setFanMode("auto")
                    }
                    FanModeButton(title: "\(L10n.localized(.fanModeCool)) 50%", isSelected: mode == "cool" || mode == "cooling") {
                        service.setFanMode("cooling")
                    }
                    FanModeButton(title: "\(L10n.localized(.fanModeMax)) 100%", isSelected: mode == "max") {
                        service.setFanMode("max")
                    }
                }
                .disabled(!hasFans)
                .opacity(hasFans ? 1.0 : 0.6)
                .padding(.vertical, 2)

                HStack(spacing: 6) {
                    Text(hasFans ? note : L10n.localized(.fanModeDisabledPassive))
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if hasFans, let f = fan, f.maxRPM > 0 {
                        Text("\(f.minRPM)~\(f.maxRPM)")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundStyle(Theme.tert)
                    }
                }
            }
        }
    }

    // MARK: - 2. 底部进程实时监控表格 (支持搜索、排序与进程作用解释)

    var filteredAndSortedProcesses: [MonitoredProcessItem] {
        let raw = service.latestSnapshot?.topProcesses ?? []
        let filtered: [MonitoredProcessItem]
        let q = processSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            filtered = raw
        } else {
            filtered = raw.filter {
                $0.name.lowercased().contains(q) || "\($0.pid)".contains(q) || $0.bundleID.lowercased().contains(q)
            }
        }

        switch processSortOrder {
        case .cpu:
            return filtered.sorted { $0.cpuPercent > $1.cpuPercent }
        case .memory:
            return filtered.sorted { $0.residentMemory > $1.residentMemory }
        case .energy:
            return filtered.sorted { $0.energyImpact > $1.energyImpact }
        case .pid:
            return filtered.sorted { $0.pid < $1.pid }
        }
    }

    var processTableSection: some View {
        let totalCount = service.latestSnapshot?.totalProcessCount ?? 0
        let list = filteredAndSortedProcesses

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text("\(L10n.localized(.activeProcesses)) (\(totalCount))")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(Theme.text)

                SearchField(text: $processSearchText, placeholder: tr(.searchProcessPlaceholder))
                    .frame(width: 195)

                Spacer()

                sortHeaderButton(L10n.localized(.memory), key: .memory, width: 90)
                sortHeaderButton("% CPU", key: .cpu, width: 140)
                sortHeaderButton(L10n.localized(.energyImpact), key: .energy, width: 80)
                sortHeaderButton("PID", key: .pid, width: 70)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.sidebarBg.opacity(0.6))

            Divider().background(Theme.sep)

            if list.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.tert)
                    Text(L10n.localized(.searchProcessPlaceholder))
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView(showsIndicators: true) {
                    LazyVStack(spacing: 0) {
                        ForEach(list) { proc in
                            processRow(proc)
                            Divider().background(Theme.sep.opacity(0.5))
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .frame(maxHeight: 340)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.card))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.sep, lineWidth: 0.8)
        )
    }

    func sortHeaderButton(_ label: String, key: ProcessSortKey, width: CGFloat) -> some View {
        let isSelected = processSortOrder == key
        return Button {
            processSortOrder = key
        } label: {
            HStack(spacing: 3) {
                Spacer()
                Text(label)
                if isSelected {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 7))
                }
            }
            .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
            .foregroundStyle(isSelected ? Theme.accent : Theme.sub)
            .frame(width: width, alignment: .trailing)
        }
        .buttonStyle(.plain)
    }

    func processRow(_ proc: MonitoredProcessItem) -> some View {
        let isHighCpu = proc.cpuPercent > 50.0
        let isHighEnergy = proc.energyImpact > 35.0
        let explanation = explainProcess(proc)

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 1)
                .fill(isHighCpu ? Theme.red : (isHighEnergy ? Theme.amber : Color.clear))
                .frame(width: 2.5, height: 18)

            HStack(spacing: 8) {
                if let iconImage = ProcessIconCache.shared.icon(forAppPath: proc.appPath) {
                    Image(nsImage: iconImage)
                        .resizable()
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "gearshape.2.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 15, height: 15)
                        .foregroundStyle(Theme.sub)
                }
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(proc.name)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                        if proc.processCount > 1 {
                            Text("×\(proc.processCount)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Theme.tert)
                        }
                    }
                    if !explanation.isEmpty {
                        Text(explanation)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.tert)
                            .lineLimit(1)
                    }
                }
            }
            .frame(minWidth: 230, alignment: .leading)

            Spacer()

            Text(Fmt.size(proc.residentMemory))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.text)
                .frame(width: 90, alignment: .trailing)

            HStack(spacing: 8) {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.sep)
                        Capsule()
                            .fill(isHighCpu ? Theme.red : (proc.cpuPercent > 20 ? Theme.amber : Theme.green))
                            .frame(width: max(2, g.size.width * CGFloat(min(1.0, proc.cpuPercent / 100.0))))
                    }
                }
                .frame(width: 44, height: 4)

                Text(String(format: "%.1f", proc.cpuPercent))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isHighCpu ? Theme.red : (proc.cpuPercent > 20 ? Theme.amber : Theme.text))
                    .frame(width: 48, alignment: .trailing)
            }
            .frame(width: 140, alignment: .trailing)

            Text(String(format: "%.1f", proc.energyImpact))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(isHighEnergy ? Theme.amber : Theme.sub)
                .frame(width: 80, alignment: .trailing)

            Text(String(proc.pid))
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(Theme.tert)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .contextMenu {
            if !proc.isSystemProtected {
                let sigtermTitle = proc.processCount > 1
                    ? L10n.format(.actionTerminateRepresentativeProcessFormat, proc.pid, proc.processCount)
                    : L10n.localized(.actionTerminateProcessSigterm)
                Button(sigtermTitle) {
                    terminatingProcess = proc
                    showConfirmAlert = true
                }
                Button(L10n.localized(.actionKillProcessSigkill)) {
                    let res = service.terminate(process: proc, force: true)
                    AppState.shared?.showToast(res.message, kind: res.success ? .success : .error)
                }
            } else {
                Text(L10n.localized(.protectedSystemCoreDaemon))
            }
            if let p = proc.appPath, FileUtil.exists(p) {
                Divider()
                Button(L10n.localized(.actionRevealInFinder)) {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: p)])
                }
            }
        }
    }

    /// 进程通俗解释器 (ProcessExplanationView)
    func explainProcess(_ proc: MonitoredProcessItem) -> String {
        let lower = proc.name.lowercased()
        if lower == "windowserver" {
            return tr(.macosWindowserverCompositorCoreDisplayProcess)
        } else if lower == "kernel_task" {
            return tr(.macosKernelAndThermalManagementTasks)
        } else if lower.contains("mds") || lower.contains("spotlight") {
            return tr(.spotlightSearchIndexingService)
        } else if lower.contains("cloudd") || lower.contains("bird") {
            return tr(.icloudDriveBackgroundSyncDaemon)
        } else if lower.contains("coreaudiod") {
            return tr(.macosCoreAudioDriverServiceCoreaudiod)
        } else if lower.contains("helper") || lower.contains("renderer") {
            return tr(.applicationHelperRendererProcess)
        } else if proc.isSystemProtected {
            return tr(.macosSystemLevelBackgroundDaemonService)
        } else if let appPath = proc.appPath, !appPath.isEmpty {
            return UninstallerEngine.abbreviateHomePath(appPath)
        }
        return ""
    }
}
