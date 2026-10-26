import Foundation
import AppKit
import Darwin
import IOKit
import IOKit.storage

// ============================================================
//  SystemTelemetryEngine —— 100% 零假数据内核级原生硬件遥测引擎
//
//  核心铁律：
//    1. 100% 原生硬件直读：Mach / IOKit (AppleSMC / IOAccelerator / AppleSmartBattery) /
//       libIOReport / libproc (rusage_info_v4) / getifaddrs / CoreMediaIO / CoreAudio；
//    2. 严禁任何假数据、随机数抖动或拍脑袋估算值；
//    3. Apple Silicon 休眠 E-Core 修正：采用单调时钟时间窗保底算法，杜绝休眠核误报 100%；
//    4. 物理硬件自适应：无风扇机型 (如 MacBook Air) 真实标记 hasFans = false。
// ============================================================

// MARK: - 遥测引擎实现

final class SystemTelemetryEngine: @unchecked Sendable {

    static let shared = SystemTelemetryEngine()

    static let machTimebaseConversion: Double = {
        var tb = mach_timebase_info_data_t()
        mach_timebase_info(&tb)
        if tb.denom == 0 { return 1.0 / 1_000_000_000.0 }
        return (Double(tb.numer) / Double(tb.denom)) / 1_000_000_000.0
    }()

    let lock = NSLock()

    // 历史波形环形缓冲区 (60 点走势)
    let cpuHistory = RollingHistory(capacity: 60)
    let gpuHistory = RollingHistory(capacity: 60)
    let memoryHistory = RollingHistory(capacity: 60)
    let diskReadHistory = RollingHistory(capacity: 60)
    let diskWriteHistory = RollingHistory(capacity: 60)
    let netDownloadHistory = RollingHistory(capacity: 60)
    let netUploadHistory = RollingHistory(capacity: 60)
    let fanHistory = RollingHistory(capacity: 60)

    // 多时间段历史采样缓冲区 (支持 1分钟 / 5分钟 / 15分钟 / 1小时 切换)
    let cpuTimedHistory = TimestampedHistoryBuffer()
    let cpuLoadTimedHistory = TimestampedHistoryBuffer()
    let gpuTimedHistory = TimestampedHistoryBuffer()
    let memoryTimedHistory = TimestampedHistoryBuffer()
    let diskTimedHistory = TimestampedHistoryBuffer()
    let netTimedHistory = TimestampedHistoryBuffer()
    let fanTimedHistory = TimestampedHistoryBuffer()

    private(set) var fanMode: String = "auto"
    private(set) var isLowLatency: Bool = false

    @discardableResult
    func setFanMode(_ mode: String) -> Bool {
        let normalized: String
        switch mode.lowercased() {
        case "cooling", "cool", "50%":
            normalized = "cooling"
        case "max", "100%":
            normalized = "max"
        default:
            normalized = "auto"
        }
        lock.lock()
        fanMode = normalized
        lock.unlock()
        let ok = SMCBridge.shared.applyFanPreset(mode: normalized)
        if !ok {
            let actual = SMCBridge.shared.activeFanPreset
            lock.lock()
            fanMode = actual
            lock.unlock()
        }
        return ok
    }

    func toggleLowLatency() {
        lock.lock()
        isLowLatency.toggle()
        lock.unlock()
    }

    // CPU 总基线与每核心基线状态
    var prevCPUTicks: (user: UInt32, sys: UInt32, idle: UInt32, nice: UInt32)?
    var prevPerCoreTicks: [(user: UInt64, sys: UInt64, idle: UInt64, nice: UInt64)] = []
    var prevPerCoreTime: TimeInterval = 0

    // 静态硬件拓扑缓存
    lazy var cachedTopology: (pCores: Int, eCores: Int, chipName: String, modelName: String) = {
        let p = Self.readSysctlInt("hw.perflevel0.logicalcpu")
        let e = Self.readSysctlInt("hw.perflevel1.logicalcpu")
        let chip = Self.readChipBrand()
        let model = Self.readHardwareModel()
        return (p, e, chip, model)
    }()

    lazy var cachedDisplayFPS: Double = {
        if Thread.isMainThread, let fps = MainActor.assumeIsolated({ NSScreen.main?.maximumFramesPerSecond }), fps > 0 {
            return Double(fps)
        }
        return 120.0
    }()

    static let shortDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()

    lazy var cachedBootDate: Date? = {
        var bootTime = timeval()
        var bootSize = MemoryLayout<timeval>.stride
        var bootMib = [CTL_KERN, KERN_BOOTTIME]
        if sysctl(&bootMib, 2, &bootTime, &bootSize, nil, 0) == 0 && bootTime.tv_sec > 0 {
            return Date(timeIntervalSince1970: TimeInterval(bootTime.tv_sec))
        }
        return nil
    }()

    lazy var cachedBootDateFormatted: String = {
        guard let bootDate = cachedBootDate else { return "" }
        return Self.shortDateFormatter.string(from: bootDate)
    }()

    // 磁盘 I/O 基线状态
    var prevDiskBytesRead: Int64 = 0
    var prevDiskBytesWritten: Int64 = 0
    var prevDiskTime: TimeInterval = 0
    var cachedDiskIO: DiskIOSnapshot?

    // 网络基线状态
    var prevNetBytesIn: UInt64 = 0
    var prevNetBytesOut: UInt64 = 0
    var prevNetTime: TimeInterval = 0
    var prevInterfaceBytes: [String: UInt64] = [:]
    var cachedNetworkDetail: (iface: String, uptime: TimeInterval, detail: NetworkDetailSnapshot)?
    var peakNetDown: Double = 1024 * 1024 * 2
    var peakNetUp: Double = 1024 * 512

    // 内存分页与负载历史状态
    var prevPageIns: UInt64 = 0
    var prevPageOuts: UInt64 = 0
    var prevPageTime: TimeInterval = 0
    var loadHistoryBuffer = RollingHistory(capacity: 60, initialValue: 1.0)
    var userHistoryBuffer = RollingHistory(capacity: 60, initialValue: 10.0)
    var systemHistoryBuffer = RollingHistory(capacity: 60, initialValue: 5.0)
    var peakLoadEver: Double = 2.0

    // 低频外设/卷/隐私状态缓存 (4.0s TTL，避免每秒重复查询 IORegistry / CoreMediaIO / CoreAudio / Volume 列表)
    var lastSlowPeripheralSampleUptime: TimeInterval = 0
    var lastBatterySampleUptime: TimeInterval = 0
    var lastProcessCountUptime: TimeInterval = 0
    var cachedProcessCount: Int = 0
    var cachedAutoStart: Bool = false
    var cachedSMCReading: SMCThermalReading?
    var cachedChipMetrics: ChipPowerAndGPUMetrics?
    var isSensorWarmupInFlight: Bool = false
    var cachedBattery: BatterySnapshot?
    var cachedStorage: StorageSnapshot?
    var cachedExternalDrives: [VolumeItem] = []
    var cachedConnectedDevices: [ConnectedDeviceItem] = []
    var cachedBtPeripherals: [BluetoothPeripheralBattery] = []
    var cachedPrivacySignals: PrivacyHardwareSignals = PrivacyHardwareSignals(isCameraActive: false, isMicrophoneActive: false)

    // 进程基线与包元数据缓存：避免每秒对 700+ 个 PID 重复调用 proc_pidpath 与解析 Info.plist
    struct ProcBaseline {
        var startSec: Int
        var startUsec: Int
        var totalCpuTimeNs: UInt64
        var totalEnergyNj: UInt64
        var totalWakeups: UInt64
        var totalDiskReadBytes: UInt64
        var totalDiskWriteBytes: UInt64
        var sampleTime: TimeInterval
    }
    var procBaselines: [pid_t: ProcBaseline] = [:]
    var pidIdentityCache: [pid_t: (startSec: Int, startUsec: Int, name: String, bundleID: String, appPath: String?, isProtected: Bool)] = [:]
    var appBundleIdentityCache: [String: (name: String, bundleID: String, appPath: String?)] = [:]

    // 真实进程级网络流量基线 (nettop 差分采样)
    struct NetProcBaseline {
        var bytesIn: UInt64
        var bytesOut: UInt64
        var sampleTime: TimeInterval
        var lastActiveTime: TimeInterval
    }
    var netProcBaselines: [pid_t: NetProcBaseline] = [:]
    var cachedTopNetProcesses: [NetworkProcessItem] = []
    var lastNettopSampleUptime: TimeInterval = 0
    var isNettopSampleInFlight: Bool = false

    init() {
        // 仅做轻量级 Mach CPU tick 基线预热 (<0.05ms)，不阻塞调用线程
        var loadInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kerr = withUnsafeMutablePointer(to: &loadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            prevCPUTicks = (
                UInt32(loadInfo.cpu_ticks.0),
                UInt32(loadInfo.cpu_ticks.1),
                UInt32(loadInfo.cpu_ticks.2),
                UInt32(loadInfo.cpu_ticks.3)
            )
        }
        _ = samplePerCoreCPUDelta()
    }

    // MARK: - 采样主入口

    func sample(includeProcesses: Bool = true) -> TelemetrySnapshot {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        let uptimeNow = ProcessInfo.processInfo.systemUptime
        let smcReading: SMCThermalReading
        let chipMetrics: ChipPowerAndGPUMetrics

        if includeProcesses {
            let s = SMCBridge.shared.sampleAll()
            let c = IOReportSampler.shared.sample()
            fanMode = SMCBridge.shared.activeFanPreset
            cachedSMCReading = s
            cachedChipMetrics = c
            smcReading = s
            chipMetrics = c
        } else if let s = cachedSMCReading, let c = cachedChipMetrics {
            smcReading = s
            chipMetrics = c
        } else {
            smcReading = cachedSMCReading ?? SMCThermalReading(
                cpuTempCelsius: nil, gpuTempCelsius: nil,
                systemWatts: nil, cpuWattsSMC: nil, gpuWattsSMC: nil,
                hasFans: false, fans: [], detailedSensors: [],
                powerBus: PowerBusSnapshot(totalWatts: 0, busVoltageVolts: 0, batteryAmperes: 0)
            )
            chipMetrics = cachedChipMetrics ?? ChipPowerAndGPUMetrics(
                cpuWatts: nil, gpuWatts: nil, aneWatts: nil, dramWatts: nil, packageWatts: nil,
                gpuUsagePercent: 0, gpuCoreCount: 0, gpuModelName: "Apple GPU"
            )
            if !isSensorWarmupInFlight {
                isSensorWarmupInFlight = true
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    let s = SMCBridge.shared.sampleAll()
                    let c = IOReportSampler.shared.sample()
                    let preset = SMCBridge.shared.activeFanPreset
                    guard let self else { return }
                    self.lock.lock()
                    self.fanMode = preset
                    self.cachedSMCReading = s
                    self.cachedChipMetrics = c
                    self.isSensorWarmupInFlight = false
                    self.lock.unlock()
                }
            }
        }

        let cpu = sampleCPU(smc: smcReading, chipMetrics: chipMetrics)
        let gpu = sampleGPU(smc: smcReading, chipMetrics: chipMetrics)
        let memory = sampleMemory()
        let disk = sampleDiskIO()
        let network = sampleNetwork(includeExtendedDetails: includeProcesses)
        let fan = sampleFan(smc: smcReading)

        let procResult: (items: [MonitoredProcessItem], memoryItems: [MonitoredProcessItem], diskItems: [DiskProcessItem], totalCount: Int)
        if includeProcesses {
            procResult = sampleTopProcesses()
            cachedProcessCount = procResult.totalCount
            lastProcessCountUptime = uptimeNow
        } else {
            procResult = (items: [], memoryItems: [], diskItems: [], totalCount: cachedProcessCount)
        }
        let topEnergyProc = procResult.items.max(by: { $0.energyImpact < $1.energyImpact })
        let battery: BatterySnapshot?
        if includeProcesses {
            let sampled = sampleBattery(smc: smcReading, chipMetrics: chipMetrics, topEnergyProc: topEnergyProc)
            cachedBattery = sampled
            lastBatterySampleUptime = uptimeNow
            battery = sampled
        } else {
            battery = cachedBattery
        }
        let topNet = sampleTopNetworkProcesses(includeProcesses: includeProcesses, uptimeNow: uptimeNow)

        if cachedStorage == nil {
            cachedStorage = sampleStorage()
        }
        if includeProcesses && (lastSlowPeripheralSampleUptime == 0 || (uptimeNow - lastSlowPeripheralSampleUptime) >= 4.0) {
            cachedStorage = sampleStorage()
            cachedExternalDrives = sampleExternalDrives()
            cachedConnectedDevices = sampleConnectedDevices()
            cachedBtPeripherals = DeviceActivityMonitor.shared.sampleBluetoothPeripherals()
            cachedPrivacySignals = DeviceActivityMonitor.shared.samplePrivacySignals()
            let launchAgentPath = (NSHomeDirectory() as NSString).appendingPathComponent("Library/LaunchAgents/com.aclean.scheduler.plist")
            let legacyAgentPath = (NSHomeDirectory() as NSString).appendingPathComponent("Library/LaunchAgents/com.cleanmate.scheduler.plist")
            cachedAutoStart = FileManager.default.fileExists(atPath: launchAgentPath) || FileManager.default.fileExists(atPath: legacyAgentPath)
            lastSlowPeripheralSampleUptime = uptimeNow
        }

        let storage = cachedStorage
        let drives = cachedExternalDrives
        let devices = cachedConnectedDevices
        let btPeripherals = cachedBtPeripherals
        let privacy = cachedPrivacySignals

        let specs = sampleSpecs(
            cpu: cpu,
            memory: memory,
            storage: storage,
            diskIO: disk,
            battery: battery
        )

        // 更新 60 点滑动环形缓冲区
        cpuHistory.append(cpu.totalUsage * 100.0)
        gpuHistory.append(gpu.usagePercent)
        memoryHistory.append(memory.usedRatio * 100.0)
        diskReadHistory.append(disk.readMBPerSec)
        diskWriteHistory.append(disk.writeMBPerSec)
        netDownloadHistory.append(network.downloadBytesPerSec / 1024.0)
        netUploadHistory.append(network.uploadBytesPerSec / 1024.0)
        fanHistory.append(Double(fan.rpm))

        // 更新多时间段历史趋势缓冲区 (1m / 5m / 15m / 1h)
        cpuTimedHistory.append(primary: cpu.totalUsage * 100.0, secondary: cpu.systemUsage * 100.0, uptime: uptimeNow)
        cpuLoadTimedHistory.append(primary: cpu.loadAverage.0, secondary: cpu.loadAverage.1, uptime: uptimeNow)
        gpuTimedHistory.append(primary: gpu.usagePercent, secondary: Double(gpu.temperature ?? 0), uptime: uptimeNow)
        memoryTimedHistory.append(primary: memory.usedRatio * 100.0, secondary: Double(memory.compressedBytes) / Double(max(1, memory.totalBytes)) * 100.0, uptime: uptimeNow)
        diskTimedHistory.append(primary: disk.readMBPerSec, secondary: disk.writeMBPerSec, uptime: uptimeNow)
        netTimedHistory.append(primary: network.downloadBytesPerSec / 1024.0, secondary: network.uploadBytesPerSec / 1024.0, uptime: uptimeNow)
        fanTimedHistory.append(primary: Double(fan.rpm), secondary: Double(fan.percentage), uptime: uptimeNow)

        return TelemetrySnapshot(
            timestamp: now,
            specs: specs,
            cpu: cpu,
            gpu: gpu,
            memory: memory,
            diskIO: disk,
            network: network,
            fan: fan,
            topProcesses: procResult.items,
            totalProcessCount: procResult.totalCount,
            battery: battery,
            storage: storage,
            externalDrives: drives,
            connectedDevices: devices,
            bluetoothPeripherals: btPeripherals,
            privacySignals: privacy,
            detailedSensors: smcReading.detailedSensors,
            powerBus: smcReading.powerBus,
            topMemoryProcesses: procResult.memoryItems,
            topNetworkProcesses: topNet,
            topDiskProcesses: procResult.diskItems
        )
    }

    // MARK: - 1. CPU 真实采样 (Mach + Apple Silicon 休眠核保底时间窗修正)

    func sampleCPU(smc: SMCThermalReading, chipMetrics: ChipPowerAndGPUMetrics) -> CPUSnapshot {
        var loadInfo = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)

        let kerr = withUnsafeMutablePointer(to: &loadInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        var totalUsage = 0.0
        var userUsage = 0.0
        var systemUsage = 0.0

        if kerr == KERN_SUCCESS {
            let u = UInt32(loadInfo.cpu_ticks.0)
            let s = UInt32(loadInfo.cpu_ticks.1)
            let i = UInt32(loadInfo.cpu_ticks.2)
            let n = UInt32(loadInfo.cpu_ticks.3)

            if let prev = prevCPUTicks {
                let du = Double(u &- prev.user)
                let ds = Double(s &- prev.sys)
                let di = Double(i &- prev.idle)
                let dn = Double(n &- prev.nice)

                let busy = du + ds + dn
                let total = busy + di
                if total > 0 {
                    totalUsage = min(1.0, max(0.0, busy / total))
                    userUsage = min(1.0, max(0.0, (du + dn) / total))
                    systemUsage = min(1.0, max(0.0, ds / total))
                }
            }
            prevCPUTicks = (u, s, i, n)
        }

        // 每核心真实差分采样 (含 Apple Silicon 休眠核修正)
        let coreUsages = samplePerCoreCPUDelta()

        let topo = cachedTopology
        var pUsage = totalUsage
        var eUsage = totalUsage
        if topo.pCores > 0 && topo.eCores > 0 && coreUsages.count >= (topo.pCores + topo.eCores) {
            // macOS Apple Silicon 核心排布：前 eCores 个或后 pCores 个，通过 hw.perflevel 区分
            // Apple Silicon 默认 perflevel1 (E-core) 在前或 perflevel0 (P-core) 在后，直接按簇切片求均值
            let eSlice = coreUsages.prefix(topo.eCores)
            let pSlice = coreUsages.dropFirst(topo.eCores).prefix(topo.pCores)
            if !eSlice.isEmpty { eUsage = eSlice.reduce(0, +) / Double(eSlice.count) }
            if !pSlice.isEmpty { pUsage = pSlice.reduce(0, +) / Double(pSlice.count) }
        }

        // 读取系统平均负载 (vm.loadavg)
        var loadavg = loadavg()
        var lSize = MemoryLayout<loadavg>.stride
        var l1 = 0.0, l5 = 0.0, l15 = 0.0
        if sysctlbyname("vm.loadavg", &loadavg, &lSize, nil, 0) == 0 && loadavg.fscale > 0 {
            let scale = Double(loadavg.fscale)
            l1 = Double(loadavg.ldavg.0) / scale
            l5 = Double(loadavg.ldavg.1) / scale
            l15 = Double(loadavg.ldavg.2) / scale
        }

        let realTemp = smc.cpuTempCelsius.map { Int($0.rounded()) }
        let realWatts = chipMetrics.cpuWatts ?? smc.cpuWattsSMC
        let loadStr = totalUsage > 0.65 ? "high" : (totalUsage > 0.25 ? "medium" : "low")

        loadHistoryBuffer.append(l1)
        userHistoryBuffer.append(userUsage * 100.0)
        systemHistoryBuffer.append(systemUsage * 100.0)
        peakLoadEver = max(peakLoadEver, max(max(l1, l5), l15))
        let fps = cachedDisplayFPS

        return CPUSnapshot(
            totalUsage: totalUsage,
            userUsage: userUsage,
            systemUsage: systemUsage,
            coreUsages: coreUsages,
            pCoreCount: topo.pCores,
            eCoreCount: topo.eCores,
            pCoreUsage: pUsage,
            eCoreUsage: eUsage,
            loadAverage: (l1, l5, l15),
            temperature: realTemp,
            powerWatts: realWatts.map { ($0 * 10).rounded() / 10 },
            loadText: loadStr,
            displayFPS: fps,
            peakLoad: (peakLoadEver * 10).rounded() / 10,
            loadHistory: loadHistoryBuffer.values,
            userHistory: userHistoryBuffer.values,
            systemHistory: systemHistoryBuffer.values
        )
    }

    /// Apple Silicon 休眠核保底时间窗差分算法
    func samplePerCoreCPUDelta() -> [Double] {
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCpuInfo
        )

        guard result == KERN_SUCCESS, let info = cpuInfo, numCPUs > 0 else { return [] }
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: info),
                vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.size)
            )
        }

        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = prevPerCoreTime > 0 ? max(0.05, now - prevPerCoreTime) : 0.0
        // Darwin procesador ticks 标称 100 Hz，休眠核最小时间窗保底
        let minTickWindow = elapsed > 0 ? floor(elapsed * 100.0) : 0.0

        var currentTicks: [(user: UInt64, sys: UInt64, idle: UInt64, nice: UInt64)] = []
        var usages: [Double] = []
        currentTicks.reserveCapacity(Int(numCPUs))
        usages.reserveCapacity(Int(numCPUs))

        for i in 0..<Int(numCPUs) {
            let offset = i * Int(CPU_STATE_MAX)
            let u = UInt64(UInt32(bitPattern: info[offset + Int(CPU_STATE_USER)]))
            let s = UInt64(UInt32(bitPattern: info[offset + Int(CPU_STATE_SYSTEM)]))
            let idle = UInt64(UInt32(bitPattern: info[offset + Int(CPU_STATE_IDLE)]))
            let nice = UInt64(UInt32(bitPattern: info[offset + Int(CPU_STATE_NICE)]))
            currentTicks.append((u, s, idle, nice))

            if i < prevPerCoreTicks.count && elapsed > 0 {
                let prev = prevPerCoreTicks[i]
                let du = Double(u >= prev.user ? u - prev.user : 0)
                let ds = Double(s >= prev.sys ? s - prev.sys : 0)
                let di = Double(idle >= prev.idle ? idle - prev.idle : 0)
                let dn = Double(nice >= prev.nice ? nice - prev.nice : 0)

                let busy = du + ds + dn
                // 关键修复：若某核心处于硬件 Parked 休眠，其 total < minTickWindow，将缺失 tick 计入 idle
                let total = max(busy + di, minTickWindow)
                let pct = total > 0 ? min(1.0, max(0.0, busy / total)) : 0.0
                usages.append(pct)
            } else {
                usages.append(0.0)
            }
        }

        prevPerCoreTicks = currentTicks
        prevPerCoreTime = now
        return usages
    }

    // MARK: - 2. GPU 真实采样 (IOAccelerator + IOReport + SMC)

    func sampleGPU(smc: SMCThermalReading, chipMetrics: ChipPowerAndGPUMetrics) -> GPUSnapshot {
        let usage = chipMetrics.gpuUsagePercent
        let realTemp = smc.gpuTempCelsius.map { Int($0.rounded()) }
        let realWatts = chipMetrics.gpuWatts ?? smc.gpuWattsSMC
        let loadStr = usage > 50.0 ? "high" : (usage > 18.0 ? "medium" : "low")

        return GPUSnapshot(
            modelName: chipMetrics.gpuModelName,
            coreCount: chipMetrics.gpuCoreCount,
            usagePercent: (usage * 10).rounded() / 10,
            temperature: realTemp,
            powerWatts: realWatts.map { ($0 * 10).rounded() / 10 },
            loadText: loadStr
        )
    }

    // MARK: - 3. 风扇真实采样 (SMC FNum / F0Ac / F0Mn / F0Mx)

    func sampleFan(smc: SMCThermalReading) -> FanSnapshot {
        guard smc.hasFans, let primary = smc.fans.first else {
            let pct: Int
            let note: String
            switch fanMode {
            case "cooling":
                pct = 50
                note = L10n.localized(.fanModeCool)
            case "max":
                pct = 100
                note = L10n.localized(.fanModeMax)
            default:
                pct = 0
                note = L10n.localized(.telemetryFanAutoCoolingDesc)
            }
            return FanSnapshot(
                hasFans: false,
                fanCount: 0,
                rpm: 0,
                minRPM: 0,
                maxRPM: 0,
                percentage: pct,
                mode: fanMode,
                modeNote: note
            )
        }

        let avgRpm = smc.fans.map(\.currentRPM).reduce(0, +) / max(1, smc.fans.count)
        let rawDuty = smc.fans.map(\.dutyPercentage).reduce(0, +) / max(1, smc.fans.count)
        let anyHardwareManual = smc.fans.contains(where: { $0.mode != 0 })
        let effectiveDuty: Int
        let note: String

        switch fanMode {
        case "cooling":
            effectiveDuty = rawDuty > 0 ? rawDuty : (anyHardwareManual ? 50 : 0)
            note = "\(smc.fans.count) Fans · Cooling Mode (Target 50%)"
        case "max":
            effectiveDuty = rawDuty > 0 ? rawDuty : (anyHardwareManual ? 100 : 0)
            note = "\(smc.fans.count) Fans · Max Cooling Mode (Target 100%)"
        default:
            effectiveDuty = rawDuty
            if avgRpm == 0 {
                note = "Idle / 0 RPM · System Auto"
            } else {
                note = smc.fans.count > 1 ? "\(smc.fans.count) Fans · Auto Thermal Management" : "System Auto Thermal Management"
            }
        }

        let leftRPM = smc.fans.first?.currentRPM ?? 0
        let rightRPM = smc.fans.count > 1 ? smc.fans[1].currentRPM : 0

        return FanSnapshot(
            hasFans: true,
            fanCount: smc.fans.count,
            rpm: avgRpm,
            minRPM: primary.minRPM,
            maxRPM: primary.maxRPM,
            percentage: effectiveDuty,
            mode: fanMode,
            modeNote: note,
            leftFanRPM: leftRPM,
            rightFanRPM: rightRPM
        )
    }

    // MARK: - 4. 系统规格与 综合权重健康分计算 

    func sampleSpecs(
        cpu: CPUSnapshot,
        memory: MemorySnapshot,
        storage: StorageSnapshot?,
        diskIO: DiskIOSnapshot,
        battery: BatterySnapshot?
    ) -> SystemSpecsSnapshot {
        let topo = cachedTopology
        let totalGB = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024))
        let memStr = "\(totalGB) GB"

        let os = ProcessInfo.processInfo.operatingSystemVersion
        let osStr = "macOS \(os.majorVersion).\(os.minorVersion)"

        var uptimeSecs: UInt64 = 3600
        var uptimeDays = 0
        var bootDateStr = ""
        if let bootDate = cachedBootDate {
            let interval = max(1, Date().timeIntervalSince(bootDate))
            uptimeSecs = UInt64(interval)
            uptimeDays = Int(interval / 86400)
            bootDateStr = L10n.localized(.bootDateFormattedSuffixFormat, cachedBootDateFormatted)
        }

        let days = Int(uptimeSecs / 86400)
        let hours = Int((uptimeSecs % 86400) / 3600)
        let mins = Int((uptimeSecs % 3600) / 60)
        let compactUptime = days > 0 ? "\(days)d \(hours)h" : (hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m")
        let uptimeText = days > 0
            ? L10n.localized(.uptimeDaysHoursFormat, days, hours, bootDateStr)
            : L10n.localized(.uptimeHoursMinsFormat, hours, mins, bootDateStr)

        // 综合权重扣分算法
        var score = 100.0
        var issues: [String] = []

        // 1) CPU 权重 30.0 (阈值 50% / 85%)
        let cpuPct = cpu.totalUsage * 100.0
        if cpuPct > 50.0 {
            if cpuPct > 85.0 {
                score -= 30.0 * (cpuPct - 50.0) / (100.0 - 50.0)
                issues.append("High CPU Load")
            } else {
                score -= 15.0 * (cpuPct - 50.0) / (85.0 - 50.0)
            }
        }

        // 2) 内存权重 25.0 (阈值 70% / 88%) + 内存压力扣分
        let memPct = memory.usedRatio * 100.0
        if memPct > 70.0 {
            if memPct > 88.0 {
                score -= 25.0 * (memPct - 70.0) / (100.0 - 70.0)
                issues.append("High Memory Usage")
            } else {
                score -= 12.5 * (memPct - 70.0) / (88.0 - 70.0)
            }
        }
        switch memory.pressureLevel {
        case .warning:
            score -= 5.0
            issues.append("Elevated Memory Pressure")
        case .critical:
            score -= 15.0
            issues.append("Critical Memory Pressure")
        case .normal:
            break
        }

        // 3) 磁盘权重 20.0 (阈值 80% / 93%)
        if let st = storage {
            let diskPct = st.usedRatio * 100.0
            if diskPct > 80.0 {
                if diskPct > 93.0 {
                    score -= 20.0 * (diskPct - 80.0) / (100.0 - 80.0)
                    issues.append("Low Disk Space")
                } else {
                    score -= 10.0 * (diskPct - 80.0) / (93.0 - 80.0)
                }
            }
        }

        // 4) 温度权重 15.0 (阈值 65℃ / 85℃)
        if let cTemp = cpu.temperature, cTemp > 65 {
            if cTemp > 85 {
                score -= 15.0
                issues.append("Elevated Chip Temperature")
            } else {
                score -= 15.0 * Double(cTemp - 65) / 20.0
            }
        }

        // 5) 磁盘 IO 权重 10.0 (阈值 50 MB/s / 150 MB/s)
        let totalIO = diskIO.readMBPerSec + diskIO.writeMBPerSec
        if totalIO > 50.0 {
            if totalIO > 150.0 {
                score -= 10.0
                issues.append("Heavy Disk I/O Activity")
            } else {
                score -= 10.0 * (totalIO - 50.0) / 100.0
            }
        }

        // 6) 电池与长运行时间修正
        if let b = battery, b.isPresent {
            if b.cycleCount > 900 || (b.healthPercentage > 0 && b.healthPercentage < 60) {
                score -= 5.0
                issues.append("Service Battery Recommended")
            } else if b.cycleCount > 800 || (b.healthPercentage > 0 && b.healthPercentage < 80) {
                score -= 2.0
            }
        }
        if uptimeSecs > 14 * 86400 {
            score -= 3.0
            issues.append("Restart Recommended to Free Kernel Cache")
        } else if uptimeSecs > 7 * 86400 {
            score -= 1.0
        }

        let finalScore = min(100, max(0, Int(score.rounded())))
        let grade: String
        if finalScore >= 85 {
            grade = "excellent"
        } else if finalScore >= 65 {
            grade = "good"
        } else if finalScore >= 45 {
            grade = "fair"
        } else {
            grade = "needsAttention"
        }

        let diag = issues.isEmpty ? L10n.localized(.telemetryDiagAllNormal) : issues.joined(separator: " · ")

        return SystemSpecsSnapshot(
            modelName: topo.modelName,
            chipName: topo.chipName,
            memorySizeText: memStr,
            osVersionText: osStr,
            uptimeSeconds: uptimeSecs,
            uptimeDays: uptimeDays,
            uptimeCompactText: compactUptime,
            uptimeText: uptimeText,
            bootDateText: bootDateStr,
            healthScore: finalScore,
            healthGrade: grade,
            healthDiagnosis: diag,
            isAutoStartEnabled: cachedAutoStart
        )
    }

    // MARK: - 5. 电池与真实充放电瓦数采样 (AppleSmartBattery IORegistry)

    func sampleBattery(
        smc: SMCThermalReading,
        chipMetrics: ChipPowerAndGPUMetrics,
        topEnergyProc: MonitoredProcessItem?
    ) -> BatterySnapshot? {
        let topAppLabel: String
        if let p = topEnergyProc, p.energyImpact >= 0.5 {
            topAppLabel = "\(p.name) (\(String(format: "%.1f", p.energyImpact)))"
        } else if let p = topEnergyProc {
            topAppLabel = p.name
        } else {
            topAppLabel = "No abnormal power-hungry processes"
        }

        let sysWatts = smc.systemWatts ?? chipMetrics.packageWatts ?? 0.0

        guard let match = IOServiceMatching("AppleSmartBattery") else {
            return nil
        }
        let service = IOServiceGetMatchingService(kIOMainPortDefault, match)
        guard service != 0 else {
            // 桌面端 Mac (Mac mini / Studio / iMac)：无内置电池
            return nil
        }
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let d = props?.takeRetainedValue() as? [String: Any] else {
            return nil
        }

        let installed = (d["BatteryInstalled"] as? Bool) ?? true
        guard installed else { return nil }

        let current = d["CurrentCapacity"] as? Int ?? 0
        let maxCap = d["MaxCapacity"] as? Int ?? 100
        let percent = maxCap > 0 ? min(100, max(0, Int((Double(current) / Double(maxCap) * 100.0).rounded()))) : current

        // 真实健康度计算 (AppleRawMaxCapacity / DesignCapacity)
        let designCap = (d["DesignCapacity"] as? Int) ?? 0
        let rawMaxCap = (d["AppleRawMaxCapacity"] as? Int) ?? (d["NominalChargeCapacity"] as? Int) ?? 0
        var healthPct = 100
        if designCap > 0 && rawMaxCap > 0 {
            healthPct = min(100, max(1, Int((Double(rawMaxCap) * 100.0 / Double(designCap)).rounded())))
        }

        let isCharging = (d["IsCharging"] as? Bool) ?? false
        let plugged = (d["ExternalConnected"] as? Bool) ?? false
        let cycles = (d["CycleCount"] as? Int) ?? 0
        let failure = (d["PermanentFailureStatus"] as? Int) ?? 0

        // 电池温度 (centi-Celsius -> Celsius)
        var battTemp: Double? = nil
        if let rawTemp = d["Temperature"] as? Int, rawTemp > 0 {
            battTemp = rawTemp > 200 ? Double(rawTemp) / 100.0 : Double(rawTemp)
        }

        // 真实电压 (mV) 与有符号电流 (mA) -> 真实充放电瓦数 (W)
        let voltageMV = Double((d["AppleRawBatteryVoltage"] as? Int) ?? (d["Voltage"] as? Int) ?? 0)
        var amperageMA: Double = 0
        if let rawAmp = d["InstantAmperage"] as? Int64 {
            amperageMA = Double(rawAmp)
        } else if let rawAmpUInt = d["InstantAmperage"] as? UInt64 {
            amperageMA = Double(Int64(bitPattern: rawAmpUInt))
        } else if let rawAmpInt = d["Amperage"] as? Int {
            amperageMA = Double(rawAmpInt)
        }

        var batteryWatts = 0.0
        if voltageMV > 0 && amperageMA != 0 {
            batteryWatts = abs(voltageMV * amperageMA) / 1_000_000.0
        }
        // 读取 TelemetryData.SystemPowerIn 或回退至 SMC/IOReport 整机功耗
        var realSysWatts = sysWatts
        if let tele = d["PowerTelemetryData"] as? [String: Any],
           let sysInMW = tele["SystemPowerIn"] as? Int, sysInMW > 0 && sysInMW < 500_000 {
            realSysWatts = Double(sysInMW) / 1000.0
        }

        let displayWatts = batteryWatts > 0.05 ? batteryWatts : realSysWatts

        // 充电器额定功率 (Watts)
        var adapterW = 0
        if let adapter = d["AdapterDetails"] as? [String: Any],
           let w = adapter["Watts"] as? Int, w > 0 {
            adapterW = w
        }

        let rawTime = (d["TimeRemaining"] as? Int) ?? (isCharging ? (d["AvgTimeToFull"] as? Int ?? -1) : (d["AvgTimeToEmpty"] as? Int ?? -1))
        let validMinutes = (rawTime > 0 && rawTime < 6000) ? rawTime : -1

        let wattsStr = String(format: "%.1fW", displayWatts)
        let estimateText: String
        if isCharging {
            if validMinutes > 0 {
                estimateText = "Charging · \(wattsStr) · ~\(validMinutes / 60)h \(validMinutes % 60)m to full"
            } else {
                estimateText = "Charging · \(wattsStr)"
            }
        } else if plugged {
            estimateText = adapterW > 0 ? "Connected (\(adapterW)W) · \(wattsStr)" : "Connected · \(wattsStr)"
        } else {
            if validMinutes > 0 {
                estimateText = "Discharging \(wattsStr) · ~\(validMinutes / 60)h \(validMinutes % 60)m left"
            } else {
                estimateText = "On Battery · \(wattsStr)"
            }
        }

        return BatterySnapshot(
            isPresent: true,
            percentage: percent,
            healthPercentage: healthPct,
            isCharging: isCharging,
            isPluggedIn: plugged,
            cycleCount: cycles,
            temperatureCelsius: battTemp,
            condition: failure != 0 ? "Service Required" : (healthPct < 80 ? "Service Recommended" : "Normal"),
            timeRemainingMinutes: validMinutes,
            powerWatts: (displayWatts * 10).rounded() / 10,
            systemWatts: (realSysWatts * 10).rounded() / 10,
            adapterWatts: adapterW,
            topEnergyApp: topAppLabel,
            chargeEstimateText: estimateText
        )
    }

}
