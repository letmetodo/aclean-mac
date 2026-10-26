import Foundation
import IOKit

// ============================================================
//  IOReportSampler —— Apple Silicon 免 Root 芯片级能耗与 GPU 真实利用率采样器
//
//  职责：
//    1. 动态桥接系统私有库 /usr/lib/libIOReport.dylib ("Energy Model" 通道)：
//       实时采样 CPU Energy、GPU Energy、ANE Energy、DRAM Energy 硬件寄存器增量，
//       换算为精确的实时功耗瓦特数 (Watts = ΔJoules / ΔSeconds)；
//    2. 直连 IOKit IOAccelerator / AGXAccelerator 驱动：
//       读取 PerformanceStatistics 字典中的 "Device Utilization %"，
//       无需 root 权限即可实现毫秒级真实 GPU 占用率与 GPU 核心数采集。
// ============================================================

struct ChipPowerAndGPUMetrics: Sendable {
    var cpuWatts: Double?            // 真实 CPU 封装功耗 (W)
    var gpuWatts: Double?            // 真实 GPU 核心功耗 (W)
    var aneWatts: Double?            // 真实神经网络引擎功耗 (W)
    var dramWatts: Double?           // 真实内存控制器功耗 (W)
    var packageWatts: Double?        // 芯片总功耗 (W)
    var gpuUsagePercent: Double      // IOAccelerator 真实 GPU 占用率 (0.0 ~ 100.0)
    var gpuCoreCount: Int            // 真实 GPU 核心数 (如 10)
    var gpuModelName: String         // 如 "Apple M4 GPU"
}

final class IOReportSampler: @unchecked Sendable {

    static let shared = IOReportSampler()

    // libIOReport C 函数指针签名
    private typealias CopyChannelsInGroupFn = @convention(c) (CFString?, CFString?, UInt64, UInt64, UInt64) -> Unmanaged<CFMutableDictionary>?
    private typealias CreateSubscriptionFn = @convention(c) (UnsafeRawPointer?, CFMutableDictionary, UnsafeMutablePointer<Unmanaged<CFMutableDictionary>?>, UInt64, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> UnsafeRawPointer?
    private typealias CreateSamplesFn = @convention(c) (UnsafeRawPointer, CFMutableDictionary, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> Unmanaged<CFDictionary>?
    private typealias CreateSamplesDeltaFn = @convention(c) (CFDictionary, CFDictionary, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> Unmanaged<CFDictionary>?
    private typealias ChannelGetChannelNameFn = @convention(c) (CFDictionary) -> Unmanaged<CFString>?
    private typealias ChannelGetSubGroupFn = @convention(c) (CFDictionary) -> Unmanaged<CFString>?
    private typealias ChannelGetUnitLabelFn = @convention(c) (CFDictionary) -> Unmanaged<CFString>?
    private typealias SimpleGetIntegerValueFn = @convention(c) (CFDictionary, Int32) -> Int64

    private var copyChannelsInGroup: CopyChannelsInGroupFn?
    private var createSubscription: CreateSubscriptionFn?
    private var createSamples: CreateSamplesFn?
    private var createSamplesDelta: CreateSamplesDeltaFn?
    private var getChannelName: ChannelGetChannelNameFn?
    private var getSubGroup: ChannelGetSubGroupFn?
    private var getUnitLabel: ChannelGetUnitLabelFn?
    private var getIntegerValue: SimpleGetIntegerValueFn?

    private var subscription: UnsafeRawPointer?
    private var subscribedChannels: CFMutableDictionary?
    private var prevSample: CFDictionary?
    private var prevSampleTime: TimeInterval = 0
    private var lastSampleCallUptime: TimeInterval = 0
    private var lastMetrics: ChipPowerAndGPUMetrics?

    private var dylibHandle: UnsafeMutableRawPointer?
    private let lock = NSLock()

    private init() {
        setupIOReport()
    }

    deinit {
        if let h = dylibHandle {
            dlclose(h)
        }
    }

    private func setupIOReport() {
        guard let handle = dlopen("/usr/lib/libIOReport.dylib", RTLD_NOW) else { return }

        guard let s1 = dlsym(handle, "IOReportCopyChannelsInGroup"),
              let s2 = dlsym(handle, "IOReportCreateSubscription"),
              let s3 = dlsym(handle, "IOReportCreateSamples"),
              let s4 = dlsym(handle, "IOReportCreateSamplesDelta"),
              let s5 = dlsym(handle, "IOReportChannelGetChannelName"),
              let s6 = dlsym(handle, "IOReportChannelGetSubGroup"),
              let s7 = dlsym(handle, "IOReportChannelGetUnitLabel"),
              let s8 = dlsym(handle, "IOReportSimpleGetIntegerValue") else {
            dlclose(handle)
            return
        }
        self.dylibHandle = handle

        copyChannelsInGroup = unsafeBitCast(s1, to: CopyChannelsInGroupFn.self)
        createSubscription = unsafeBitCast(s2, to: CreateSubscriptionFn.self)
        createSamples = unsafeBitCast(s3, to: CreateSamplesFn.self)
        createSamplesDelta = unsafeBitCast(s4, to: CreateSamplesDeltaFn.self)
        getChannelName = unsafeBitCast(s5, to: ChannelGetChannelNameFn.self)
        getSubGroup = unsafeBitCast(s6, to: ChannelGetSubGroupFn.self)
        getUnitLabel = unsafeBitCast(s7, to: ChannelGetUnitLabelFn.self)
        getIntegerValue = unsafeBitCast(s8, to: SimpleGetIntegerValueFn.self)

        guard let channelsUnmanaged = copyChannelsInGroup?("Energy Model" as CFString, nil, 0, 0, 0) else { return }
        let channels = channelsUnmanaged.takeRetainedValue()

        var subbedUnmanaged: Unmanaged<CFMutableDictionary>?
        if let sub = createSubscription?(nil, channels, &subbedUnmanaged, 0, nil),
           let subbed = subbedUnmanaged?.takeRetainedValue() {
            self.subscription = sub
            self.subscribedChannels = subbed
            // 立即采集一次初始基线
            if let first = createSamples?(sub, subbed, nil)?.takeRetainedValue() {
                self.prevSample = first
                self.prevSampleTime = ProcessInfo.processInfo.systemUptime
            }
        }
    }

    // MARK: - 综合采样入口

    func sample() -> ChipPowerAndGPUMetrics {
        lock.lock()
        defer { lock.unlock() }

        let uptimeNow = ProcessInfo.processInfo.systemUptime
        if let cached = lastMetrics, (uptimeNow - lastSampleCallUptime) < 0.15 {
            return cached
        }
        lastSampleCallUptime = uptimeNow

        let gpuAcc = sampleIOAcceleratorGPU()
        let energy = sampleEnergyDeltaUnlocked()

        let result = ChipPowerAndGPUMetrics(
            cpuWatts: energy.cpuWatts,
            gpuWatts: energy.gpuWatts,
            aneWatts: energy.aneWatts,
            dramWatts: energy.dramWatts,
            packageWatts: energy.packageWatts,
            gpuUsagePercent: gpuAcc.usagePercent,
            gpuCoreCount: gpuAcc.coreCount,
            gpuModelName: gpuAcc.modelName
        )
        self.lastMetrics = result
        return result
    }

    // MARK: - 1. IOReport Energy Model 芯片功耗差分计算

    private func sampleEnergyDeltaUnlocked() -> (cpuWatts: Double?, gpuWatts: Double?, aneWatts: Double?, dramWatts: Double?, packageWatts: Double?) {
        guard let sub = subscription,
              let subbed = subscribedChannels,
              let createSamples = createSamples,
              let createDelta = createSamplesDelta,
              let getName = getChannelName,
              let getUnit = getUnitLabel,
              let getInt = getIntegerValue else {
            return (nil, nil, nil, nil, nil)
        }

        let now = ProcessInfo.processInfo.systemUptime
        let dt = now - prevSampleTime
        guard dt >= 0.15 else {
            if let last = lastMetrics {
                return (last.cpuWatts, last.gpuWatts, last.aneWatts, last.dramWatts, last.packageWatts)
            }
            return (nil, nil, nil, nil, nil)
        }

        guard let currentUnmanaged = createSamples(sub, subbed, nil) else {
            return (nil, nil, nil, nil, nil)
        }
        let currentSample = currentUnmanaged.takeRetainedValue()

        guard let prev = prevSample,
              let deltaUnmanaged = createDelta(prev, currentSample, nil) else {
            self.prevSample = currentSample
            self.prevSampleTime = now
            return (nil, nil, nil, nil, nil)
        }

        self.prevSample = currentSample
        self.prevSampleTime = now

        let deltaDict = deltaUnmanaged.takeRetainedValue() as NSDictionary
        guard let rawChannels = deltaDict["IOReportChannels"] as? [Any] else {
            return (nil, nil, nil, nil, nil)
        }

        var cpuJoules: Double = 0
        var gpuJoules: Double = 0
        var aneJoules: Double = 0
        var dramJoules: Double = 0
        var foundCPU = false
        var foundGPU = false

        for item in rawChannels {
            guard let ch = (item as? NSDictionary) as CFDictionary? else { continue }
            guard let nameCF = getName(ch)?.takeUnretainedValue() else { continue }
            let name = (nameCF as String).uppercased()
            let unit = (getUnit(ch)?.takeUnretainedValue() as String? ?? "mJ").trimmingCharacters(in: .whitespaces)
            let rawVal = getInt(ch, 0)
            guard rawVal >= 0 else { continue }

            let joules = convertToJoules(value: Double(rawVal), unit: unit)

            if name == "CPU ENERGY" || name == "DIE_0_CPU Energy".uppercased() {
                cpuJoules += joules
                foundCPU = true
            } else if name == "GPU ENERGY" || name.hasPrefix("GPU0_") || name == "GPU" {
                gpuJoules += joules
                foundGPU = true
            } else if name.contains("ANE") {
                aneJoules += joules
            } else if name.contains("DRAM") {
                dramJoules += joules
            }
        }

        // 若单通道未汇总 "CPU ENERGY"，则累加 ECPU + PCPU 簇能耗
        if !foundCPU {
            for item in rawChannels {
                guard let ch = (item as? NSDictionary) as CFDictionary? else { continue }
                guard let nameCF = getName(ch)?.takeUnretainedValue() else { continue }
                let name = (nameCF as String).uppercased()
                if (name.contains("ECPU") || name.contains("PCPU")) && !name.contains("SRAM") {
                    let unit = (getUnit(ch)?.takeUnretainedValue() as String? ?? "mJ").trimmingCharacters(in: .whitespaces)
                    let rawVal = getInt(ch, 0)
                    if rawVal > 0 {
                        cpuJoules += convertToJoules(value: Double(rawVal), unit: unit)
                        foundCPU = true
                    }
                }
            }
        }

        let cpuW = foundCPU ? (cpuJoules / dt) : nil
        let gpuW = foundGPU ? (gpuJoules / dt) : nil
        let aneW = aneJoules > 0 ? (aneJoules / dt) : 0.0
        let dramW = dramJoules > 0 ? (dramJoules / dt) : 0.0
        let pkgW: Double? = (foundCPU || foundGPU) ? ((cpuW ?? 0) + (gpuW ?? 0) + aneW + dramW) : nil

        return (cpuW, gpuW, aneW, dramW, pkgW)
    }

    private func convertToJoules(value: Double, unit: String) -> Double {
        switch unit {
        case "J":  return value
        case "mJ": return value / 1_000.0
        case "uJ", "µJ": return value / 1_000_000.0
        case "nJ": return value / 1_000_000_000.0
        default:   return value / 1_000.0
        }
    }

    // MARK: - 2. IOKit IOAccelerator 免 Root GPU 实时利用率与核心数采集

    private func sampleIOAcceleratorGPU() -> (usagePercent: Double, coreCount: Int, modelName: String) {
        guard let matching = IOServiceMatching("IOAccelerator") else {
            return (0.0, 0, "Apple GPU")
        }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == kIOReturnSuccess else {
            return (0.0, 0, "Apple GPU")
        }
        defer { IOObjectRelease(iterator) }

        var maxUtil: Double = 0.0
        var cores: Int = 0
        var model: String = "Apple GPU"

        var service = IOIteratorNext(iterator)
        while service != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
               let dict = props?.takeRetainedValue() as? [String: Any] {

                if let c = dict["gpu-core-count"] as? Int, c > 0 {
                    cores = c
                } else if let cNum = dict["gpu-core-count"] as? NSNumber, cNum.intValue > 0 {
                    cores = cNum.intValue
                }

                if let m = dict["model"] as? String, !m.isEmpty {
                    model = m
                } else if let mData = dict["model"] as? Data,
                          let str = String(data: mData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters),
                          !str.isEmpty {
                    model = str
                }

                if let perf = dict["PerformanceStatistics"] as? [String: Any] {
                    let candidates = [
                        "Device Utilization %",
                        "GPU Activity (%)",
                        "Renderer Utilization %",
                        "Tiler Utilization %"
                    ]
                    for key in candidates {
                        if let val = perf[key] as? Int {
                            maxUtil = max(maxUtil, Double(val))
                            break
                        } else if let num = perf[key] as? NSNumber {
                            maxUtil = max(maxUtil, num.doubleValue)
                            break
                        }
                    }
                }
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }

        return (min(100.0, max(0.0, maxUtil)), cores, model)
    }
}
