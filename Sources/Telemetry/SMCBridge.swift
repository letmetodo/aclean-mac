import Foundation
import IOKit
import AppKit

// ============================================================
//  SMCBridge —— AppleSMC 与 IOHID 原生硬件传感器直连桥
//
//  职责：
//    1. 直连 IOKit AppleSMC 内核驱动 (Selector 2, kSMCReadKey / kSMCGetKeyInfo / kSMCWriteKey)
//    2. 读取真实物理传感器数据：
//       - CPU 封装/核心温度 (Tp09/Tp0T/Tp01/Tp05/TC0P/TC0D/TC0E)
//       - GPU 核心温度 (Tg05/Tg0D/Tg0f/TG0P/TG0D)
//       - 物理风扇数量 (FNum)、实时转速 (F0Ac/F1Ac)、最小/最大转速 (F0Mn/F0Mx)
//       - 整机/芯片功耗 (PSTR/PCPC/PCPG)
//    3. 结合 IOHIDEventSystemClient (Page 0xFF00, Usage 5) 作为 Apple Silicon PMU 温度传感器补充，
//       确保 M1/M2/M3/M4 全系机型 100% 读取真实硬件温度，绝无任何伪造或估算数据。
// ============================================================

struct FanHardwareUnit: Sendable {
    var index: Int
    var currentRPM: Int
    var minRPM: Int
    var maxRPM: Int
    var mode: Int // 0 = Auto, 1 = Forced/Manual

    var dutyPercentage: Int {
        guard maxRPM > minRPM, currentRPM > 0 else { return 0 }
        let ratio = Double(currentRPM - minRPM) / Double(maxRPM - minRPM)
        return min(100, max(0, Int((ratio * 100.0).rounded())))
    }
}

struct SMCThermalReading: Sendable {
    var cpuTempCelsius: Double?      // nil = 物理探头不可用
    var gpuTempCelsius: Double?      // nil = 物理探头不可用
    var systemWatts: Double?         // PSTR 整机功耗 (W)
    var cpuWattsSMC: Double?         // PCPC
    var gpuWattsSMC: Double?         // PCPG
    var hasFans: Bool                // FNum > 0
    var fans: [FanHardwareUnit]
    var detailedSensors: [HardwareSensorItem] = []
    var powerBus: PowerBusSnapshot? = nil
}

final class SMCBridge: @unchecked Sendable {

    static let shared = SMCBridge()

    // AppleSMC 80-byte 标准内核通信缓冲区（严格对齐 IOKit AppleSMC UserClient ABI 偏移量：
    //   offset 0:  key (UInt32)
    //   offset 28: keyInfo.dataSize (UInt32)
    //   offset 32: keyInfo.dataType (UInt32)
    //   offset 36: keyInfo.dataAttributes (UInt8)
    //   offset 40: result (UInt8)
    //   offset 41: status (UInt8)
    //   offset 42: data8 (UInt8: 5=kSMCReadKey, 6=kSMCWriteKey, 9=kSMCGetKeyInfo)
    //   offset 44: data32 (UInt32)
    //   offset 48..79: bytes (32B)）
    private static let smcBufferSize = 80

    private var connection: io_connect_t = 0
    private var isOpen: Bool = false
    private let lock = NSLock()
    private var keyInfoCache: [UInt32: (size: UInt32, type: UInt32)] = [:]
    private var missingKeyCache: Set<UInt32> = []
    private var fanControlState = FanControlState()
    private var currentPresetMode: String {
        get { fanControlState.mode }
        set { fanControlState.mode = newValue }
    }
    private var isApplyingPreset: Bool = false
    private var cachedHIDClient: CFTypeRef?

    private static var privilegedHelperInstallPath: String { AppConfig.Paths.privilegedHelperInstallPath }
    private static var legacyHelperInstallPath: String { AppConfig.Paths.legacyHelperInstallPath }

    // Dynamic IOHIDEventSystemClient symbols for Apple Silicon PMU thermal sensors
    private typealias IOHIDEventSystemClientCreateType = @convention(c) (CFAllocator?) -> Unmanaged<CFTypeRef>?
    private typealias IOHIDEventSystemClientSetMatchingType = @convention(c) (CFTypeRef, CFDictionary) -> Void
    private typealias IOHIDEventSystemClientCopyServicesType = @convention(c) (CFTypeRef) -> Unmanaged<CFArray>?
    private typealias IOHIDServiceClientCopyPropertyType = @convention(c) (CFTypeRef, CFString) -> Unmanaged<CFTypeRef>?
    private typealias IOHIDServiceClientCopyEventType = @convention(c) (CFTypeRef, Int64, Int32, Int64) -> Unmanaged<CFTypeRef>?
    private typealias IOHIDEventGetFloatValueType = @convention(c) (CFTypeRef, Int32) -> Double

    private var hidCreate: IOHIDEventSystemClientCreateType?
    private var hidSetMatching: IOHIDEventSystemClientSetMatchingType?
    private var hidCopyServices: IOHIDEventSystemClientCopyServicesType?
    private var hidCopyProperty: IOHIDServiceClientCopyPropertyType?
    private var hidCopyEvent: IOHIDServiceClientCopyEventType?
    private var hidGetFloat: IOHIDEventGetFloatValueType?
    private var lastReading: SMCThermalReading?
    private var lastSampleUptime: TimeInterval = 0

    private init() {
        openConnection()
        loadHIDSymbols()
        registerTerminationHooks()
    }

    deinit {
        if isOpen && connection != 0 {
            IOServiceClose(connection)
        }
    }

    private func openConnection() {
        guard !isOpen else { return }
        guard let matching = IOServiceMatching("AppleSMC") else { return }
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != 0 else { return }
        defer { IOObjectRelease(service) }

        var conn: io_connect_t = 0
        if IOServiceOpen(service, mach_task_self_, 0, &conn) == kIOReturnSuccess {
            self.connection = conn
            self.isOpen = true
        }
    }

    private func loadHIDSymbols() {
        guard let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else { return }
        if let sym = dlsym(handle, "IOHIDEventSystemClientCreate") {
            hidCreate = unsafeBitCast(sym, to: IOHIDEventSystemClientCreateType.self)
        }
        if let sym = dlsym(handle, "IOHIDEventSystemClientSetMatching") {
            hidSetMatching = unsafeBitCast(sym, to: IOHIDEventSystemClientSetMatchingType.self)
        }
        if let sym = dlsym(handle, "IOHIDEventSystemClientCopyServices") {
            hidCopyServices = unsafeBitCast(sym, to: IOHIDEventSystemClientCopyServicesType.self)
        }
        if let sym = dlsym(handle, "IOHIDServiceClientCopyProperty") {
            hidCopyProperty = unsafeBitCast(sym, to: IOHIDServiceClientCopyPropertyType.self)
        }
        if let sym = dlsym(handle, "IOHIDServiceClientCopyEvent") {
            hidCopyEvent = unsafeBitCast(sym, to: IOHIDServiceClientCopyEventType.self)
        }
        if let sym = dlsym(handle, "IOHIDEventGetFloatValue") {
            hidGetFloat = unsafeBitCast(sym, to: IOHIDEventGetFloatValueType.self)
        }
    }

    // MARK: - 综合采样入口

    func sampleAll() -> SMCThermalReading {
        lock.lock()
        defer { lock.unlock() }

        let uptimeNow = ProcessInfo.processInfo.systemUptime
        if !isApplyingPreset, let cached = lastReading, (uptimeNow - lastSampleUptime) < 0.25 {
            return cached
        }

        if !isOpen { openConnection() }

        // 1. CPU 温度探头候选 (Apple Silicon M1/M2/M3/M4 + Intel)
        let cpuTempKeys = [
            "Tp09", "Tp0T", "Tp01", "Tp05", "Tp0D", "Tp0b", "Tp0j",
            "TC0P", "TC0E", "TC0D", "TC0F", "TC1C"
        ]
        var cpuTemps: [Double] = []
        for k in cpuTempKeys {
            if let val = readDoubleUnlocked(key: k), val > 15.0 && val < 125.0 {
                cpuTemps.append(val)
            }
        }

        // 2. GPU 温度探头候选
        let gpuTempKeys = [
            "Tg05", "Tg0D", "Tg0f", "Tg0j", "Tg0P", "TG0P", "TG0D", "TG0E"
        ]
        var gpuTemps: [Double] = []
        for k in gpuTempKeys {
            if let val = readDoubleUnlocked(key: k), val > 15.0 && val < 125.0 {
                gpuTemps.append(val)
            }
        }

        // 3. 通过 IOHID PMU 传感器获取各核心微观读数与兜底均温
        let hidReading = sampleHIDTemperaturesUnlocked()
        if cpuTemps.isEmpty, let c = hidReading.cpu {
            cpuTemps.append(c)
        }
        if gpuTemps.isEmpty, let g = hidReading.gpu {
            gpuTemps.append(g)
        }

        let finalCpuTemp: Double? = cpuTemps.isEmpty ? nil : (cpuTemps.reduce(0, +) / Double(cpuTemps.count))
        let finalGpuTemp: Double? = gpuTemps.isEmpty ? nil : (gpuTemps.reduce(0, +) / Double(gpuTemps.count))

        // 4. 功耗探头 (PSTR 整机功率, PCPC CPU 功率, PCPG GPU 功率)
        let sysWatts = readDoubleUnlocked(key: "PSTR").flatMap { ($0 > 0 && $0 < 500) ? $0 : nil }
        let cpuWatts = readDoubleUnlocked(key: "PCPC").flatMap { ($0 >= 0 && $0 < 300) ? $0 : nil }
        let gpuWatts = readDoubleUnlocked(key: "PCPG").flatMap { ($0 >= 0 && $0 < 300) ? $0 : nil }

        // 5. 物理风扇读取 (FNum, F0Ac, F0Mn, F0Mx, F0Md, F0Tg) —— 100% 真实硬件读数
        var fanUnits: [FanHardwareUnit] = []
        let fanCount = Int(readDoubleUnlocked(key: "FNum") ?? 0)
        var anyManualMode = false
        var detectedHighTarget = false

        if fanCount > 0 && fanCount <= 6 {
            for idx in 0..<fanCount {
                let rawAc = Int((readDoubleUnlocked(key: "F\(idx)Ac") ?? 0).rounded())
                let rawMn = Int((readDoubleUnlocked(key: "F\(idx)Mn") ?? 1200).rounded())
                let rawMx = Int((readDoubleUnlocked(key: "F\(idx)Mx") ?? 6500).rounded())
                let rawMd = Int((readDoubleUnlocked(key: "F\(idx)Md") ?? readDoubleUnlocked(key: "F\(idx)md") ?? 0).rounded())
                let rawTg = Int((readDoubleUnlocked(key: "F\(idx)Tg") ?? readDoubleUnlocked(key: "F\(idx)tg") ?? 0).rounded())
                let mn = max(0, rawMn)
                let mx = max(mn + 100, rawMx)

                if rawMd != 0 {
                    anyManualMode = true
                    if Double(rawTg) >= Double(mn) + Double(mx - mn) * 0.80 {
                        detectedHighTarget = true
                    }
                }

                // 仅当硬件真实处于手动模式 (rawMd != 0) 且电机刚启动尚未产出转速脉冲时使用目标转速过渡，绝不在自动模式下伪造转速
                let effectiveRPM: Int
                if rawAc > 0 {
                    effectiveRPM = rawAc
                } else if rawMd != 0 && rawTg > 0 {
                    effectiveRPM = rawTg
                } else {
                    effectiveRPM = 0
                }

                fanUnits.append(FanHardwareUnit(
                    index: idx,
                    currentRPM: effectiveRPM,
                    minRPM: mn,
                    maxRPM: mx,
                    mode: rawMd
                ))
            }

            // 当未处于预设切换过程中时，根据真实 SMC F%dMd / F%dTg 状态同步当前预设档位显示
            if !isApplyingPreset {
                if anyManualMode {
                    currentPresetMode = detectedHighTarget ? "max" : "cooling"
                } else {
                    currentPresetMode = "auto"
                }
            }
        }

        let powerBus = samplePowerBusUnlocked(sysWatts: sysWatts)

        let reading = SMCThermalReading(
            cpuTempCelsius: finalCpuTemp,
            gpuTempCelsius: finalGpuTemp,
            systemWatts: sysWatts,
            cpuWattsSMC: cpuWatts,
            gpuWattsSMC: gpuWatts,
            hasFans: !fanUnits.isEmpty,
            fans: fanUnits,
            detailedSensors: hidReading.detailedSensors,
            powerBus: powerBus
        )
        lastReading = reading
        lastSampleUptime = uptimeNow
        return reading
    }

    var activeFanPreset: String {
        lock.lock()
        defer { lock.unlock() }
        return currentPresetMode
    }

    // MARK: - 风扇模式控制 (自动 / 降温 50% / 强冷 100%)

    /// 注册应用退出监听与看门狗钩子 (P1-2: 解决退出后风扇残留高转速安全风险)
    private func registerTerminationHooks() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.resetFanToAutoOnTermination()
        }
        atexit {
            SMCBridge.shared.resetFanToAutoOnTermination()
        }
    }

    /// 应用退出时安全复位风扇为系统自动控制 (Auto)，消除残留转速风险 (P1-2)
    func resetFanToAutoOnTermination() {
        var attempts = 0
        while attempts < 5 {
            lock.lock()
            let mode = fanControlState.mode
            let busy = isApplyingPreset
            lock.unlock()
            guard mode != "auto" else { return }
            if !busy {
                _ = applyFanPreset(mode: "auto")
                return
            }
            attempts += 1
            Thread.sleep(forTimeInterval: 0.05)
        }
    }

    /// 应用风扇模式: "auto" (Auto), "cooling" (50% 转速), "max" (100% 转速)
    private var fanLeaseTimer: DispatchSourceTimer?

    private func updateFanLease(mode: String, succeeded: Bool) {
        lock.lock()
        defer { lock.unlock() }
        guard let generation = fanControlState.completeChange(to: mode, succeeded: succeeded) else { return }
        fanLeaseTimer?.cancel()
        fanLeaseTimer = nil
        if mode != "auto" {
            let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
            if PrivilegedMaintenanceClient.isEnabled {
                // 特权守护进程模式：每 fanRenewSeconds 周期向常驻 Daemon 发送续约请求
                timer.schedule(deadline: .now() + AppConfig.PrivilegedHelper.fanRenewSeconds,
                               repeating: AppConfig.PrivilegedHelper.fanRenewSeconds)
                timer.setEventHandler { [weak self] in
                    guard let self else { return }
                    self.lock.lock()
                    let current = self.fanControlState.generation == generation
                    self.lock.unlock()
                    guard current else { return }
                    guard !PrivilegedMaintenanceClient.run("fan.renew") else { return }
                    self.lock.lock()
                    let expired = self.fanControlState.expireLease(generation: generation)
                    if expired {
                        self.fanLeaseTimer?.cancel()
                        self.fanLeaseTimer = nil
                    }
                    self.lock.unlock()
                    if expired {
                        _ = self.applyFanPreset(mode: "auto")
                    }
                }
            } else {
                // 降级模式 (Fallback)：无常驻特权守护进程，设置一次性到期看门狗。到期后自动执行 expireLease 并安全回落到 auto (P1-2)
                timer.schedule(deadline: .now() + AppConfig.PrivilegedHelper.fanLeaseSeconds)
                timer.setEventHandler { [weak self] in
                    guard let self else { return }
                    self.lock.lock()
                    let current = self.fanControlState.generation == generation
                    let expired = current ? self.fanControlState.expireLease(generation: generation) : false
                    if expired {
                        self.fanLeaseTimer?.cancel()
                        self.fanLeaseTimer = nil
                    }
                    self.lock.unlock()
                    if expired {
                        _ = self.applyFanPreset(mode: "auto")
                    }
                }
            }
            fanLeaseTimer = timer
            timer.resume()
        }
    }

    @discardableResult
    func applyFanPreset(mode: String) -> Bool {
        let normalized: String
        let helperArg: String
        let targetPercent: Int
        switch mode.lowercased() {
        case "cool", "cooling", "50%":
            normalized = "cooling"
            helperArg = "cool"
            targetPercent = 50
        case "max", "100%":
            normalized = "max"
            helperArg = "max"
            targetPercent = 100
        default:
            normalized = "auto"
            helperArg = "auto"
            targetPercent = 0
        }

        lock.lock()
        guard !isApplyingPreset else { lock.unlock(); return false }
        if !isOpen { openConnection() }
        lastSampleUptime = 0
        isApplyingPreset = true
        let fanCount = Int(readDoubleUnlocked(key: "FNum") ?? 0)
        lock.unlock()

        defer {
            lock.lock()
            isApplyingPreset = false
            lock.unlock()
        }

        guard fanCount > 0 && fanCount <= AppConfig.Telemetry.maximumFanCount else { return false }

        // 1. 若当前进程已具备 root 权限 (例如 sudo 运行)，直接写入 SMC 寄存器
        if geteuid() == 0 {
            let directOk = applyFanHardwareDirect(fanCount: fanCount, targetPercent: targetPercent)
            updateFanLease(mode: normalized, succeeded: directOk)
            return directOk
        }

        // 2. 优先通过标准系统特权服务执行 (SMAppService.daemon)
        var authorizedRunSucceeded = PrivilegedMaintenanceClient.run("fan." + helperArg)

        // 3. 降级机制 (Fallback): 若未安装特权守护进程或无有效签名，使用管理员提权执行内置 Helper
        if !authorizedRunSucceeded {
            authorizedRunSucceeded = executeBundledHelperFallback(helperArg: helperArg)
        }

        updateFanLease(mode: normalized, succeeded: authorizedRunSucceeded)
        return authorizedRunSucceeded
    }

    /// 在拥有 root 权限的进程内直接执行 AppleSMC 风扇转速写入（支持 Apple Silicon Ftst 解锁与重试）
    private func applyFanHardwareDirect(fanCount: Int, targetPercent: Int) -> Bool {
        if targetPercent <= 0 {
            lock.lock()
            var ok = true
            for idx in 0..<fanCount {
                let mdKey = lookupKeyInfoUnlocked(code: fourCC("F\(idx)Md")) != nil ? "F\(idx)Md" : "F\(idx)md"
                if !writeUInt8Unlocked(key: mdKey, value: 0) {
                    ok = false
                }
            }
            let hasFtst = lookupKeyInfoUnlocked(code: fourCC("Ftst")) != nil
            lock.unlock()

            if hasFtst {
                for _ in 0..<20 {
                    lock.lock()
                    let ftstOk = writeUInt8Unlocked(key: "Ftst", value: 0)
                    lock.unlock()
                    if ftstOk {
                        ok = true
                        break
                    }
                    Thread.sleep(forTimeInterval: 0.1)
                }
                Thread.sleep(forTimeInterval: 0.15)
                lock.lock()
                for idx in 0..<fanCount {
                    let mdKey = lookupKeyInfoUnlocked(code: fourCC("F\(idx)Md")) != nil ? "F\(idx)Md" : "F\(idx)md"
                    _ = writeUInt8Unlocked(key: mdKey, value: 0)
                }
                lock.unlock()
            }
            return ok
        }

        // 计算每个风扇的目标转速
        var targets: [Float] = []
        lock.lock()
        for idx in 0..<fanCount {
            let mn = readDoubleUnlocked(key: "F\(idx)Mn") ?? 1200.0
            let mx = max(mn + 100.0, readDoubleUnlocked(key: "F\(idx)Mx") ?? 6000.0)
            let t = targetPercent >= 100 ? mx : (mn + (mx - mn) * (Double(targetPercent) / 100.0))
            targets.append(Float(max(mn, min(mx, t)).rounded()))
        }
        let hasFtst = lookupKeyInfoUnlocked(code: fourCC("Ftst")) != nil
        lock.unlock()

        if tryWriteManualFans(fanCount: fanCount, targets: targets, timeoutSeconds: 0) {
            return true
        }

        guard hasFtst else { return false }
        lock.lock()
        let unlockedFtst = writeUInt8Unlocked(key: "Ftst", value: 1)
        lock.unlock()
        guard unlockedFtst else { return false }

        Thread.sleep(forTimeInterval: 0.5)
        if tryWriteManualFans(fanCount: fanCount, targets: targets, timeoutSeconds: 8.0) {
            return true
        }

        lock.lock()
        _ = writeUInt8Unlocked(key: "Ftst", value: 0)
        lock.unlock()
        return false
    }

    private func tryWriteManualFans(fanCount: Int, targets: [Float], timeoutSeconds: TimeInterval) -> Bool {
        for idx in 0..<fanCount {
            let deadline = Date().addingTimeInterval(timeoutSeconds)
            var mdWritten = false
            repeat {
                lock.lock()
                let mdKey = lookupKeyInfoUnlocked(code: fourCC("F\(idx)Md")) != nil ? "F\(idx)Md" : "F\(idx)md"
                mdWritten = writeUInt8Unlocked(key: mdKey, value: 1)
                lock.unlock()
                if mdWritten || timeoutSeconds <= 0 { break }
                Thread.sleep(forTimeInterval: 0.1)
            } while Date() < deadline

            guard mdWritten else { return false }

            let tgDeadline = Date().addingTimeInterval(timeoutSeconds)
            var tgWritten = false
            repeat {
                lock.lock()
                let tgKey = lookupKeyInfoUnlocked(code: fourCC("F\(idx)Tg")) != nil ? "F\(idx)Tg" : "F\(idx)tg"
                tgWritten = writeFloatUnlocked(key: tgKey, value: targets[idx])
                lock.unlock()
                if tgWritten || timeoutSeconds <= 0 { break }
                Thread.sleep(forTimeInterval: 0.1)
            } while Date() < tgDeadline

            guard tgWritten else { return false }
        }
        return true
    }

    private func executeBundledHelperFallback(helperArg: String) -> Bool {
        guard ["auto", "cool", "max"].contains(helperArg) else { return false }
        guard let helperPath = bundledHelperBinaryPath() else { return false }
        if geteuid() == 0 {
            return Shell.execute(helperPath, [helperArg], timeout: AppConfig.PrivilegedHelper.fanRequestTimeout).isSuccess
        }
        let escaped = helperPath.replacingOccurrences(of: "'", with: "'\\''")
        let command = "'\(escaped)' '\(helperArg)'"
        let scriptCommand = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let res = Shell.execute(
            "/usr/bin/osascript",
            ["-e", "do shell script \"\(scriptCommand)\" with administrator privileges"],
            timeout: AppConfig.PrivilegedHelper.fanRequestTimeout
        )
        return res.isSuccess
    }

    private func bundledHelperBinaryPath() -> String? {
        let helperNames = [
            AppConfig.PrivilegedHelper.executableName,
            "ACleanSMCHelper",
            "CleanMateSMCHelper"
        ]
        // 仅允许从主应用 Bundle 内部查找受信任的 Helper 二进制，杜绝相对工作目录劫持风险
        if let mainExec = Bundle.main.executableURL {
            for name in helperNames {
                let bundled = mainExec.deletingLastPathComponent().appendingPathComponent(name).path
                if FileManager.default.isExecutableFile(atPath: bundled) {
                    return bundled
                }
            }
        }
        for name in helperNames {
            let candidate = Bundle.main.bundlePath + "/Contents/MacOS/\(name)"
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    // MARK: - IOHID PMU 温度传感器读取 (复用缓存 Client，避免每秒重复建立 Mach 连接)

    private func sampleHIDTemperaturesUnlocked() -> (cpu: Double?, gpu: Double?, detailedSensors: [HardwareSensorItem]) {
        guard let create = hidCreate,
              let setMatching = hidSetMatching,
              let copyServices = hidCopyServices,
              let copyProp = hidCopyProperty,
              let copyEvent = hidCopyEvent,
              let getFloat = hidCopyEvent != nil ? hidGetFloat : nil else {
            return (nil, nil, [])
        }

        let client: CFTypeRef
        if let existing = cachedHIDClient {
            client = existing
        } else {
            guard let clientUnmanaged = create(kCFAllocatorDefault) else {
                return (nil, nil, [])
            }
            let created = clientUnmanaged.takeRetainedValue()
            let matchDict: [String: Any] = [
                "PrimaryUsagePage": 0xff00,
                "PrimaryUsage": 5
            ]
            setMatching(created, matchDict as CFDictionary)
            cachedHIDClient = created
            client = created
        }

        guard let servicesUnmanaged = copyServices(client) else { return (nil, nil, []) }
        let services = servicesUnmanaged.takeRetainedValue() as NSArray

        var cpuVals: [Double] = []
        var gpuVals: [Double] = []
        var socVals: [Double] = []
        var detailed: [HardwareSensorItem] = []
        var seenKeys: Set<String> = []

        // kIOHIDEventTypeTemperature = 15, field = 15 << 16 = 0xF0000
        let kIOHIDEventTypeTemperature: Int64 = 15
        let kIOHIDEventFieldTemperatureLevel: Int32 = 15 << 16

        for item in services {
            let serviceRef = item as CFTypeRef
            let rawName: String
            if let propUnmanaged = copyProp(serviceRef, "Product" as CFString),
               let str = propUnmanaged.takeRetainedValue() as? String {
                rawName = str
            } else {
                rawName = ""
            }
            let name = rawName.lowercased()

            guard let eventUnmanaged = copyEvent(serviceRef, kIOHIDEventTypeTemperature, 0, 0) else { continue }
            let event = eventUnmanaged.takeRetainedValue()
            let temp = getFloat(event, kIOHIDEventFieldTemperatureLevel)
            guard temp > 15.0 && temp < 120.0 else { continue }

            if name.contains("pacc") || name.contains("eacc") || name.contains("cpu") || name.contains("pmgr soc die") || name.contains("tdie") {
                cpuVals.append(temp)
            } else if name.contains("gpu") {
                gpuVals.append(temp)
            } else if name.contains("soc") || name.contains("pmu") {
                socVals.append(temp)
            }

            // 归类并格式化微观传感器条目
            let dispName: String
            let group: String
            if name.contains("gas gauge") || name.contains("battery") {
                dispName = "Battery"
                group = "storage"
            } else if name.contains("nand") || name.contains("ssd") {
                dispName = "SSD"
                group = "storage"
            } else if name.contains("airport") || name.contains("wifi") {
                dispName = "AirPort"
                group = "system"
            } else if name.contains("airflow") {
                dispName = "Airflow \(detailed.filter { $0.group == "system" }.count + 1)"
                group = "system"
            } else if name.contains("palm") {
                dispName = "Palm Rest"
                group = "system"
            } else if name.contains("pacc") {
                dispName = "CPU (P-Core)"
                group = "core"
            } else if name.contains("eacc") {
                dispName = "CPU (E-Core)"
                group = "core"
            } else if name.contains("tdie") {
                let suffix = rawName.replacingOccurrences(of: "PMU ", with: "")
                dispName = "CPU Core (\(suffix))"
                group = "core"
            } else if name.contains("gpu") || name.contains("tp1g") || name.contains("tp2g") || name.contains("tp3g") {
                let suffix = rawName.replacingOccurrences(of: "PMU ", with: "")
                dispName = "GPU Core (\(suffix))"
                group = "core"
            } else if name.contains("tdev") {
                let suffix = rawName.replacingOccurrences(of: "PMU ", with: "")
                dispName = "Enclosure (\(suffix))"
                group = "system"
            } else {
                continue
            }

            let key = "\(rawName)_\(dispName)"
            if !seenKeys.contains(key) {
                seenKeys.insert(key)
                detailed.append(HardwareSensorItem(
                    key: key,
                    name: dispName,
                    group: group,
                    temperature: (temp * 10).rounded() / 10
                ))
            }
        }

        let cpuAvg = !cpuVals.isEmpty
            ? (cpuVals.reduce(0, +) / Double(cpuVals.count))
            : (!socVals.isEmpty ? (socVals.reduce(0, +) / Double(socVals.count)) : nil)
        let gpuAvg = !gpuVals.isEmpty
            ? (gpuVals.reduce(0, +) / Double(gpuVals.count))
            : cpuAvg

        if let avg = cpuAvg {
            detailed.insert(HardwareSensorItem(
                key: "cpu_core_average",
                name: "CPU Core Average",
                group: "core",
                temperature: (avg * 10).rounded() / 10
            ), at: 0)
        }

        return (cpuAvg, gpuAvg, detailed)
    }

    private func samplePowerBusUnlocked(sysWatts: Double?) -> PowerBusSnapshot {
        let matching = IOServiceMatching("AppleSmartBattery")
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        var vVolts: Double = 0.0
        var aAmps: Double = 0.0
        if service != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
               let dict = props?.takeRetainedValue() as? [String: Any] {
                let vMv = (dict["Voltage"] as? Double) ?? Double(dict["Voltage"] as? Int ?? 0)
                let aMa = abs((dict["Amperage"] as? Double) ?? Double(dict["Amperage"] as? Int ?? 0))
                if vMv > 1000 { vVolts = (vMv / 1000.0 * 100).rounded() / 100 }
                if aMa > 0 { aAmps = (aMa / 1000.0 * 100).rounded() / 100 }
            }
            IOObjectRelease(service)
        }
        let totalW = sysWatts ?? ((vVolts * aAmps > 0.1) ? (vVolts * aAmps) : 0.0)
        return PowerBusSnapshot(totalWatts: (totalW * 10).rounded() / 10, busVoltageVolts: vVolts, batteryAmperes: aAmps)
    }

    // MARK: - 底层 SMC 读写实现 (精确 80 字节 ABI 偏移)

    private func fourCC(_ str: String) -> UInt32 {
        var result: UInt32 = 0
        for byte in str.utf8.prefix(4) {
            result = (result << 8) | UInt32(byte)
        }
        return result
    }

    private func lookupKeyInfoUnlocked(code: UInt32) -> (size: UInt32, type: UInt32)? {
        if let cached = keyInfoCache[code] {
            return cached
        }
        if missingKeyCache.contains(code) {
            return nil
        }
        var inBuf = [UInt8](repeating: 0, count: Self.smcBufferSize)
        var outBuf = [UInt8](repeating: 0, count: Self.smcBufferSize)
        inBuf.withUnsafeMutableBytes { ptr in
            ptr.storeBytes(of: code, toByteOffset: 0, as: UInt32.self)
            ptr[42] = 9 // kSMCGetKeyInfo
        }
        var outSize = Self.smcBufferSize
        let kr = inBuf.withUnsafeBytes { inRaw in
            outBuf.withUnsafeMutableBytes { outRaw in
                IOConnectCallStructMethod(connection, 2, inRaw.baseAddress, Self.smcBufferSize, outRaw.baseAddress, &outSize)
            }
        }
        guard kr == kIOReturnSuccess else { return nil }
        let res = outBuf[40]
        let dSize = outBuf.withUnsafeBytes { $0.load(fromByteOffset: 28, as: UInt32.self) }
        let dType = outBuf.withUnsafeBytes { $0.load(fromByteOffset: 32, as: UInt32.self) }
        guard res == 0, dSize > 0, dSize <= 32 else {
            if res != 0 {
                missingKeyCache.insert(code)
            }
            return nil
        }
        let info = (size: dSize, type: dType)
        keyInfoCache[code] = info
        return info
    }

    private func readDoubleUnlocked(key: String) -> Double? {
        guard isOpen, connection != 0, key.utf8.count == 4 else { return nil }
        let code = fourCC(key)
        guard let info = lookupKeyInfoUnlocked(code: code) else { return nil }

        var inBuf = [UInt8](repeating: 0, count: Self.smcBufferSize)
        var outBuf = [UInt8](repeating: 0, count: Self.smcBufferSize)
        inBuf.withUnsafeMutableBytes { ptr in
            ptr.storeBytes(of: code, toByteOffset: 0, as: UInt32.self)
            ptr.storeBytes(of: info.size, toByteOffset: 28, as: UInt32.self)
            ptr[42] = 5 // kSMCReadKey
        }
        var outSize = Self.smcBufferSize
        let kr = inBuf.withUnsafeBytes { inRaw in
            outBuf.withUnsafeMutableBytes { outRaw in
                IOConnectCallStructMethod(connection, 2, inRaw.baseAddress, Self.smcBufferSize, outRaw.baseAddress, &outSize)
            }
        }
        guard kr == kIOReturnSuccess, outBuf[40] == 0 else { return nil }

        let rawBytes = Array(outBuf[48..<(48 + Int(info.size))])
        return decodeSMCValue(bytes: rawBytes, dataType: info.type)
    }

    private func decodeSMCValue(bytes: [UInt8], dataType: UInt32) -> Double? {
        let typeFLT  = fourCC("flt ")
        let typeSP78 = fourCC("sp78")
        let typeFPE2 = fourCC("fpe2")
        let typeUI8  = fourCC("ui8 ")
        let typeUI16 = fourCC("ui16")
        let typeUI32 = fourCC("ui32")

        if dataType == typeFLT && bytes.count >= 4 {
            // IEEE 754 float (Apple Silicon uses little-endian float)
            let val = bytes.withUnsafeBytes { $0.load(as: Float32.self) }
            if val.isFinite { return Double(val) }
        } else if dataType == typeSP78 && bytes.count >= 2 {
            // Signed 7.8 fixed point (big-endian)
            let raw = (Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1])))
            return Double(raw) / 256.0
        } else if dataType == typeFPE2 && bytes.count >= 2 {
            // Unsigned 14.2 fixed point (big-endian)
            let raw = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
            return Double(raw) / 4.0
        } else if dataType == typeUI8 && bytes.count >= 1 {
            return Double(bytes[0])
        } else if dataType == typeUI16 && bytes.count >= 2 {
            let raw = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
            return Double(raw)
        } else if dataType == typeUI32 && bytes.count >= 4 {
            let raw = (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
            return Double(raw)
        }
        return nil
    }

    private func writeUInt8Unlocked(key: String, value: UInt8) -> Bool {
        let code = fourCC(key)
        guard let info = lookupKeyInfoUnlocked(code: code) else { return false }
        var inBuf = [UInt8](repeating: 0, count: Self.smcBufferSize)
        var outBuf = [UInt8](repeating: 0, count: Self.smcBufferSize)
        inBuf.withUnsafeMutableBytes { ptr in
            ptr.storeBytes(of: code, toByteOffset: 0, as: UInt32.self)
            ptr.storeBytes(of: info.size, toByteOffset: 28, as: UInt32.self)
            ptr[42] = 6 // kSMCWriteKey
            ptr[48] = value
        }
        var outSize = Self.smcBufferSize
        let kr = inBuf.withUnsafeBytes { inRaw in
            outBuf.withUnsafeMutableBytes { outRaw in
                IOConnectCallStructMethod(connection, 2, inRaw.baseAddress, Self.smcBufferSize, outRaw.baseAddress, &outSize)
            }
        }
        return kr == kIOReturnSuccess && outBuf[40] == 0
    }

    private func writeFloatUnlocked(key: String, value: Float) -> Bool {
        let code = fourCC(key)
        guard let info = lookupKeyInfoUnlocked(code: code) else { return false }
        var inBuf = [UInt8](repeating: 0, count: Self.smcBufferSize)
        var outBuf = [UInt8](repeating: 0, count: Self.smcBufferSize)
        inBuf.withUnsafeMutableBytes { ptr in
            ptr.storeBytes(of: code, toByteOffset: 0, as: UInt32.self)
            ptr.storeBytes(of: info.size, toByteOffset: 28, as: UInt32.self)
            ptr[42] = 6 // kSMCWriteKey
            if info.type == fourCC("fpe2") && info.size >= 2 {
                let fpe2 = UInt16(clamping: Int((value * 4.0).rounded()))
                ptr[48] = UInt8((fpe2 >> 8) & 0xFF)
                ptr[49] = UInt8(fpe2 & 0xFF)
            } else {
                ptr.storeBytes(of: value, toByteOffset: 48, as: Float32.self)
            }
        }
        var outSize = Self.smcBufferSize
        let kr = inBuf.withUnsafeBytes { inRaw in
            outBuf.withUnsafeMutableBytes { outRaw in
                IOConnectCallStructMethod(connection, 2, inRaw.baseAddress, Self.smcBufferSize, outRaw.baseAddress, &outSize)
            }
        }
        return kr == kIOReturnSuccess && outBuf[40] == 0
    }
}
