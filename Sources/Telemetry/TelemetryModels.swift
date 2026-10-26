import Foundation
import AppKit
import Darwin

// ============================================================
//  TelemetryModels —— 硬件遥测引擎不可变快照模型与环形缓冲区
// ============================================================

// MARK: - 基础快照模型

struct SystemSpecsSnapshot: Sendable {
    var modelName: String         // 如 "MacBook Air" 或 "MacBook Pro"
    var chipName: String          // 如 "Apple M4"
    var memorySizeText: String    // 如 "16 GB"
    var osVersionText: String     // 如 "macOS 15.4"
    var uptimeSeconds: UInt64
    var uptimeDays: Int
    var uptimeCompactText: String // 如 "5d 20h"
    var uptimeText: String        // 如 "已运行 5天 20小时 · 10月8日开机"
    var bootDateText: String      // 如 "10月8日开机"
    var healthScore: Int          // 0 ~ 100 (综合权重算法)
    var healthGrade: String       // "excellent" / "good" / "fair" / "needsAttention"
    var healthDiagnosis: String   // 真实诊断原因
    var isAutoStartEnabled: Bool

    var localizedHealthGrade: String {
        switch healthGrade {
        case "excellent": return L10n.localized(.healthExcellent)
        case "good": return L10n.localized(.healthGood)
        case "fair": return L10n.localized(.healthFair)
        default: return L10n.localized(.healthNeedsAttention)
        }
    }
}

enum SensorCategory: String, CaseIterable, Identifiable, Sendable {
    case all = "all"
    case core = "core"
    case system = "system"
    case storage = "storage"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .all: return L10n.localized(.filterAll)
        case .core: return L10n.localized(.menuBarCoreTemperatureTab)
        case .system: return L10n.localized(.menuBarSystemPeripheralTab)
        case .storage: return L10n.localized(.menuBarStoragePowerTab)
        }
    }
}

struct HardwareSensorItem: Identifiable, Sendable {
    var id: String { key }
    var key: String
    var name: String
    var group: String // "core", "system", "storage"
    var temperature: Double
}

struct PowerBusSnapshot: Sendable {
    var totalWatts: Double?
    var busVoltageVolts: Double?
    var batteryAmperes: Double?
}

struct NetworkProcessItem: Identifiable, Sendable {
    var id: String { name }
    var name: String
    var bundleID: String
    var appPath: String?
    var uploadBytesPerSec: Double
    var downloadBytesPerSec: Double
    var isTunnel: Bool = false
}

struct DiskProcessItem: Identifiable, Sendable {
    var id: String { name }
    var name: String
    var bundleID: String
    var appPath: String?
    var readBytesPerSec: Double
    var writeBytesPerSec: Double
}

struct CPUSnapshot: Sendable {
    var totalUsage: Double              // 0.0 ~ 1.0
    var userUsage: Double               // 0.0 ~ 1.0
    var systemUsage: Double             // 0.0 ~ 1.0
    var coreUsages: [Double]            // 各核心真实利用率 (经休眠核修正)
    var pCoreCount: Int                 // 性能核数 (hw.perflevel0.logicalcpu)
    var eCoreCount: Int                 // 能效核数 (hw.perflevel1.logicalcpu)
    var pCoreUsage: Double              // 性能核平均占用 (0.0 ~ 1.0)
    var eCoreUsage: Double              // 能效核平均占用 (0.0 ~ 1.0)
    var loadAverage: (Double, Double, Double) // 1m, 5m, 15m
    var temperature: Int?               // 真实 SMC/HID 温度 (℃)，nil 表示传感器不可读
    var powerWatts: Double?             // 真实 IOReport/SMC CPU 瓦数 (W)
    var loadText: String
    var displayFPS: Double = 120.0
    var peakLoad: Double = 0.0
    var loadHistory: [Double] = []
    var userHistory: [Double] = []
    var systemHistory: [Double] = []

    var localizedLoadText: String {
        switch loadText {
        case "high": return L10n.localized(.statusHighLoad)
        case "medium": return L10n.localized(.statusMediumLoad)
        default: return L10n.localized(.statusLowLoad)
        }
    }
}

struct GPUSnapshot: Sendable {
    var modelName: String               // 如 "Apple M4 GPU"
    var coreCount: Int                  // 如 10
    var usagePercent: Double            // IOAccelerator 真实利用率 0.0 ~ 100.0
    var temperature: Int?               // 真实 SMC/HID GPU 温度 (℃)
    var powerWatts: Double?             // 真实 IOReport/SMC GPU 瓦数 (W)
    var loadText: String

    var localizedLoadText: String {
        switch loadText {
        case "high": return L10n.localized(.statusHighLoad)
        case "medium": return L10n.localized(.statusMediumLoad)
        default: return L10n.localized(.statusLowLoad)
        }
    }
}

struct FanSnapshot: Sendable {
    var hasFans: Bool                   // FNum > 0
    var fanCount: Int
    var rpm: Int                        // 真实 F0Ac RPM (无风扇或停转时为 0)
    var minRPM: Int
    var maxRPM: Int
    var percentage: Int                 // 真实占空比 0 ~ 100%
    var mode: String                    // "auto" / "cooling" / "max"
    var modeNote: String                // 真实状态说明
    var leftFanRPM: Int = 0
    var rightFanRPM: Int = 0

    var localizedMode: String {
        switch mode {
        case "cooling": return L10n.localized(.fanModeCooling50)
        case "max": return L10n.localized(.fanModeMaxCooling100)
        default: return L10n.localized(.menuBarFanModeSystemAuto)
        }
    }
}

enum MemoryPressureLevel: String, Sendable {
    case normal = "normal"
    case warning = "warning"
    case critical = "critical"

    var localizedTitle: String {
        switch self {
        case .normal: return L10n.localized(.statusNormal)
        case .warning: return L10n.localized(.statusWarning)
        case .critical: return L10n.localized(.statusCritical)
        }
    }
}

struct MemorySnapshot: Sendable {
    var totalBytes: Int64
    var usedBytes: Int64
    var appBytes: Int64
    var wiredBytes: Int64
    var compressedBytes: Int64
    var freeBytes: Int64
    var activeBytes: Int64 = 0
    var inactiveBytes: Int64 = 0
    var cacheBytes: Int64 = 0
    var pressurePercent: Int = 0
    var pageInsKBPerSec: Double = 0.0
    var pageOutsKBPerSec: Double = 0.0
    var pressureLevel: MemoryPressureLevel
    var swapUsedBytes: Int64            // 真实 vm.swapusage (绝不造假)
    var swapTotalBytes: Int64
    var isSampleValid: Bool = true
    var usedRatio: Double { (isSampleValid && totalBytes > 0) ? Double(usedBytes) / Double(totalBytes) : 0 }
}

struct DiskIOSnapshot: Sendable {
    var readBytesPerSec: Double
    var writeBytesPerSec: Double
    var readMBPerSec: Double { max(0, readBytesPerSec / (1024 * 1024)) }
    var writeMBPerSec: Double { max(0, writeBytesPerSec / (1024 * 1024)) }
}

struct NetworkTrafficSnapshot: Sendable {
    var downloadBytesPerSec: Double
    var uploadBytesPerSec: Double
    var activeInterfaceName: String
    var downloadSpeedText: String
    var uploadSpeedText: String
    var interfaceType: String
    var isLowLatencyEnabled: Bool
    var detail: NetworkDetailSnapshot
    var peakDownloadBytesPerSec: Double = 0
    var peakUploadBytesPerSec: Double = 0
}

struct BatterySnapshot: Sendable {
    var isPresent: Bool
    var percentage: Int
    var healthPercentage: Int
    var isCharging: Bool
    var isPluggedIn: Bool
    var cycleCount: Int
    var temperatureCelsius: Double?
    var condition: String
    var timeRemainingMinutes: Int       // -1 = 未知/正在计算
    var powerWatts: Double              // 真实充放电或系统功率 (W)
    var systemWatts: Double             // 真实整机功耗 (W)
    var adapterWatts: Int               // 充电器额定功率 (W)
    var topEnergyApp: String
    var chargeEstimateText: String
}

enum DiskPressureLevel: String, Sendable {
    case normal = "normal"
    case warning = "warning"
    case critical = "critical"

    var localizedTitle: String {
        switch self {
        case .normal: return L10n.localized(.statusNormal)
        case .warning: return L10n.localized(.statusHigh)
        case .critical: return L10n.localized(.statusTight)
        }
    }
}

struct StorageSnapshot: Sendable {
    var total: Int64
    var free: Int64
    var purgeable: Int64 = 0
    var used: Int64 { max(0, total - free) }
    var usedRatio: Double { total > 0 ? Double(used) / Double(total) : 0 }
    var pressure: DiskPressureLevel
}

struct VolumeItem: Identifiable, Sendable {
    var id: String { path }
    var name: String
    var path: String
    var total: Int64
    var free: Int64
    var isInternal: Bool
    var isRemovable: Bool
    var isEjectable: Bool
}

struct ConnectedDeviceItem: Identifiable, Sendable {
    var id: String
    var name: String
    var kind: String
    var detail: String
}

struct MonitoredProcessItem: Identifiable, Sendable {
    var id: String
    var pid: pid_t
    var ppid: pid_t
    var name: String
    var bundleID: String
    var cpuPercent: Double
    var residentMemory: Int64           // ri_phys_footprint 真实物理内存足迹
    var energyImpact: Double            // 基于 ri_energy_nj + wakeups + CPU 的真实能耗分
    var processCount: Int
    var isSystemProtected: Bool
    var appPath: String?
    var startSec: Int = 0
    var startUsec: Int = 0
    var memberPIDs: [pid_t] = []
}

struct TelemetrySnapshot: Sendable {
    var timestamp: Date
    var specs: SystemSpecsSnapshot
    var cpu: CPUSnapshot
    var gpu: GPUSnapshot
    var memory: MemorySnapshot
    var diskIO: DiskIOSnapshot
    var network: NetworkTrafficSnapshot
    var fan: FanSnapshot
    var topProcesses: [MonitoredProcessItem]
    var totalProcessCount: Int
    var battery: BatterySnapshot?
    var storage: StorageSnapshot?
    var externalDrives: [VolumeItem]
    var connectedDevices: [ConnectedDeviceItem]
    var bluetoothPeripherals: [BluetoothPeripheralBattery]
    var privacySignals: PrivacyHardwareSignals
    var detailedSensors: [HardwareSensorItem] = []
    var powerBus: PowerBusSnapshot? = nil
    var topMemoryProcesses: [MonitoredProcessItem] = []
    var topNetworkProcesses: [NetworkProcessItem] = []
    var topDiskProcesses: [DiskProcessItem] = []
}

// MARK: - 60 点滑动环形缓冲区 (Ring Buffer)

final class RollingHistory: @unchecked Sendable {
    private var data: [Double] = []
    let capacity: Int
    private let lock = NSLock()
    private var isPrimed = false

    init(capacity: Int = 60, initialValue: Double? = nil) {
        self.capacity = capacity
        if let initial = initialValue {
            self.data = Array(repeating: initial, count: capacity)
            self.isPrimed = true
        } else {
            self.data = []
            self.isPrimed = false
        }
    }

    func append(_ value: Double) {
        lock.lock(); defer { lock.unlock() }
        if !isPrimed {
            // 首次收到真实硬件采样值时，以该真实基线平铺填满历史缓冲区，
            // 彻底杜绝冷启动首 30-60 秒因默认 0.0 假数据造成的“从零暴涨”阶梯视觉 Bug。
            data = Array(repeating: value, count: capacity)
            isPrimed = true
            return
        }
        data.append(value)
        if data.count > capacity {
            data.removeFirst(data.count - capacity)
        }
    }

    var values: [Double] {
        lock.lock(); defer { lock.unlock() }
        if data.isEmpty {
            return Array(repeating: 0.0, count: capacity)
        }
        return data
    }

    func reset() {
        lock.lock(); defer { lock.unlock() }
        data.removeAll()
        isPrimed = false
    }
}

// MARK: - 多时间段历史趋势采样与重采样缓冲区 (1分钟 / 5分钟 / 15分钟 / 1小时)

enum TelemetryTimeRange: String, CaseIterable, Identifiable, Sendable {
    case oneMinute      = "1m"
    case fiveMinutes    = "5m"
    case fifteenMinutes = "15m"
    case oneHour        = "1h"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneMinute:      return L10n.localized(.timeOneMinute)
        case .fiveMinutes:    return L10n.localized(.timeFiveMinutes)
        case .fifteenMinutes: return L10n.localized(.timeFifteenMinutes)
        case .oneHour:        return L10n.localized(.timeOneHour)
        }
    }

    var windowSeconds: TimeInterval {
        switch self {
        case .oneMinute:      return 60
        case .fiveMinutes:    return 300
        case .fifteenMinutes: return 900
        case .oneHour:        return 3600
        }
    }
}

struct TelemetryRangeStats: Sendable {
    var points: [Double]
    var secondaryPoints: [Double]
    var average: Double
    var peak: Double
    var minimum: Double
    var sampleCount: Int
}

final class TimestampedHistoryBuffer: @unchecked Sendable {
    struct Entry {
        var uptime: TimeInterval
        var primary: Double
        var secondary: Double
    }

    private var entries: [Entry] = []
    private let maxAgeSeconds: TimeInterval = 3660
    private let lock = NSLock()

    func append(primary: Double, secondary: Double = 0, uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        lock.lock()
        defer { lock.unlock() }
        entries.append(Entry(uptime: uptime, primary: primary, secondary: secondary))
        let cutoff = uptime - maxAgeSeconds
        if let firstValid = entries.firstIndex(where: { $0.uptime >= cutoff }), firstValid > 0 {
            entries.removeFirst(firstValid)
        }
    }

    func query(range: TelemetryTimeRange, bucketCount: Int = 60) -> TelemetryRangeStats {
        lock.lock()
        let snapshot = entries
        lock.unlock()

        guard let latest = snapshot.last else {
            return TelemetryRangeStats(
                points: Array(repeating: 0, count: bucketCount),
                secondaryPoints: Array(repeating: 0, count: bucketCount),
                average: 0,
                peak: 0,
                minimum: 0,
                sampleCount: 0
            )
        }

        let cutoff = latest.uptime - range.windowSeconds
        let windowEntries = snapshot.filter { $0.uptime >= cutoff }
        guard !windowEntries.isEmpty else {
            return TelemetryRangeStats(
                points: Array(repeating: 0, count: bucketCount),
                secondaryPoints: Array(repeating: 0, count: bucketCount),
                average: 0,
                peak: 0,
                minimum: 0,
                sampleCount: 0
            )
        }

        let primVals = windowEntries.map(\.primary)
        let avg = primVals.reduce(0, +) / Double(primVals.count)
        let peak = primVals.max() ?? 0
        let minVal = primVals.min() ?? 0

        // 按真实物理时间窗口 [cutoff, latest.uptime] 映射到 bucketCount 个时间槽，使不同时间跨度 (1m/5m/15m/1h) 呈现明显的视口缩放差异
        var outPrimary: [Double] = []
        var outSecondary: [Double] = []
        outPrimary.reserveCapacity(bucketCount)
        outSecondary.reserveCapacity(bucketCount)

        let totalWindow = max(1.0, range.windowSeconds)
        let bucketDuration = totalWindow / Double(bucketCount)
        let firstEntry = windowEntries.first!

        var cursor = 0
        for b in 0..<bucketCount {
            let bucketStart = cutoff + Double(b) * bucketDuration
            let bucketEnd = bucketStart + bucketDuration

            if bucketEnd <= firstEntry.uptime {
                // 采样尚未覆盖的早期时间区间，平滑延续最早一条真实基线
                outPrimary.append(firstEntry.primary)
                outSecondary.append(firstEntry.secondary)
                continue
            }

            while cursor < windowEntries.count && windowEntries[cursor].uptime < bucketStart {
                cursor += 1
            }

            var sumP = 0.0
            var sumS = 0.0
            var count = 0
            var idx = cursor
            while idx < windowEntries.count && windowEntries[idx].uptime <= bucketEnd {
                sumP += windowEntries[idx].primary
                sumS += windowEntries[idx].secondary
                count += 1
                idx += 1
            }

            if count > 0 {
                outPrimary.append(sumP / Double(count))
                outSecondary.append(sumS / Double(count))
            } else {
                let fallbackIdx = min(windowEntries.count - 1, max(0, cursor - 1))
                outPrimary.append(windowEntries[fallbackIdx].primary)
                outSecondary.append(windowEntries[fallbackIdx].secondary)
            }
        }

        return TelemetryRangeStats(
            points: outPrimary,
            secondaryPoints: outSecondary,
            average: avg,
            peak: peak,
            minimum: minVal,
            sampleCount: windowEntries.count
        )
    }
}
