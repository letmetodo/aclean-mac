import Foundation
import Combine
import AppKit
import Darwin

// ============================================================
//  SystemTelemetryService —— 系统实时遥测调度与多订阅者节流服务
//
//  核心职责：
//    1. 多订阅者生命周期管理：当实时监控页或菜单栏打开时无缝调度，
//       关闭时自动挂起或低频节流，全链路保障自身常驻 CPU < 0.3%；
//    2. 动态频控策略：前台活跃监控时 1.0s 平滑采样，后台/仅图标时 5.0s 节能采样；
//    3. 线程安全分发：在独立后台串行队列上执行内核采样，并在主线程派发更新 UI。
// ============================================================

@MainActor
final class SystemTelemetryService: ObservableObject {

    static let shared = SystemTelemetryService()

    @Published private(set) var latestSnapshot: TelemetrySnapshot?
    @Published var activeSubscribers: Int = 0
    @Published var isHighFrequency: Bool = false

    private let engine = SystemTelemetryEngine.shared
    private let sampleQueue = DispatchQueue(label: "com.aclean.telemetry.queue", qos: .utility)
    private var timer: DispatchSourceTimer?
    private let subscribed = StopFlag()
    private var menuBarVisible = false

    private init() {
        menuBarVisible = AppConfigStore.shared.menuBarMonitor
        if menuBarVisible {
            triggerImmediateSample(includeProcesses: false)
            startTimer(interval: AppConfig.Telemetry.backgroundSampleInterval)
        }
    }

    // MARK: - 多订阅者注册与解绑 (节流调度)

    /// 注册一个前台高频消费者 (如打开了实时监控主视图或菜单栏 Popover)
    func subscribe() {
        activeSubscribers += 1
        subscribed.value = true
        let shouldAccelerate = activeSubscribers == 1

        if shouldAccelerate {
            updateHighFrequency(true)
            startTimer(interval: AppConfig.Telemetry.foregroundSampleInterval)
            // 立即触发一次全量采样
            triggerImmediateSample(includeProcesses: true)
        }
    }

    /// 注销一个前台高频消费者
    func unsubscribe() {
        activeSubscribers = max(0, activeSubscribers - 1)
        subscribed.value = activeSubscribers > 0
        let shouldThrottle = activeSubscribers == 0

        if shouldThrottle {
            updateHighFrequency(false)
            if menuBarVisible { startTimer(interval: AppConfig.Telemetry.backgroundSampleInterval) }
            else { timer?.cancel(); timer = nil }
        }
    }

    func setMenuBarVisible(_ visible: Bool) {
        guard menuBarVisible != visible else { return }
        menuBarVisible = visible
        guard activeSubscribers == 0 else { return }
        if visible { startTimer(interval: AppConfig.Telemetry.backgroundSampleInterval) }
        else { timer?.cancel(); timer = nil }
    }

    private func updateHighFrequency(_ value: Bool) { isHighFrequency = value }

    private func startTimer(interval: TimeInterval) {
        timer?.cancel()
        timer = Self.makeSampleTimer(
            queue: sampleQueue,
            interval: interval,
            engine: engine,
            subscribed: subscribed,
            service: self
        )
    }

    nonisolated private static func makeSampleTimer(
        queue: DispatchQueue,
        interval: TimeInterval,
        engine: SystemTelemetryEngine,
        subscribed: StopFlag,
        service: SystemTelemetryService
    ) -> DispatchSourceTimer {
        let newTimer = DispatchSource.makeTimerSource(queue: queue)
        newTimer.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(100))
        newTimer.setEventHandler { [weak service] in
            let snap = engine.sample(includeProcesses: subscribed.value)
            DispatchQueue.main.async { [weak service] in
                service?.latestSnapshot = snap
            }
        }
        newTimer.resume()
        return newTimer
    }

    private func currentSubscriberCount() -> Int { activeSubscribers }

    private func triggerImmediateSample(includeProcesses: Bool) {
        let engine = engine
        sampleQueue.async { [weak self] in
            let snap = engine.sample(includeProcesses: includeProcesses)
            DispatchQueue.main.async { [weak self] in self?.latestSnapshot = snap }
        }
    }

    // MARK: - 快捷数据通道 (用于 SwiftUI 图表与仪表卡片)

    var cpuHistory: [Double] { engine.cpuHistory.values }
    var gpuHistory: [Double] { engine.gpuHistory.values }
    var memoryHistory: [Double] { engine.memoryHistory.values }
    var diskReadHistory: [Double] { engine.diskReadHistory.values }
    var diskWriteHistory: [Double] { engine.diskWriteHistory.values }
    var netDownloadHistory: [Double] { engine.netDownloadHistory.values }
    var netUploadHistory: [Double] { engine.netUploadHistory.values }
    var fanHistory: [Double] { engine.fanHistory.values }

    func cpuRangeStats(for range: TelemetryTimeRange) -> TelemetryRangeStats {
        engine.cpuTimedHistory.query(range: range)
    }

    func cpuLoadRangeStats(for range: TelemetryTimeRange) -> TelemetryRangeStats {
        engine.cpuLoadTimedHistory.query(range: range)
    }

    func gpuRangeStats(for range: TelemetryTimeRange) -> TelemetryRangeStats {
        engine.gpuTimedHistory.query(range: range)
    }

    func memoryRangeStats(for range: TelemetryTimeRange) -> TelemetryRangeStats {
        engine.memoryTimedHistory.query(range: range)
    }

    func diskRangeStats(for range: TelemetryTimeRange) -> TelemetryRangeStats {
        engine.diskTimedHistory.query(range: range)
    }

    func netRangeStats(for range: TelemetryTimeRange) -> TelemetryRangeStats {
        engine.netTimedHistory.query(range: range)
    }

    func fanRangeStats(for range: TelemetryTimeRange) -> TelemetryRangeStats {
        engine.fanTimedHistory.query(range: range)
    }

    private let controlQueue = DispatchQueue(label: "com.aclean.telemetry.control", qos: .userInitiated)

    @Published private(set) var isSettingFanMode = false
    @Published var fanControlFeedback: String? = nil

    func setFanMode(_ mode: String, completion: (@Sendable (Bool) -> Void)? = nil) {
        guard !isSettingFanMode else { return }
        isSettingFanMode = true
        let normalized: String
        switch mode.lowercased() {
        case "cooling", "cool", "50%":
            normalized = "cooling"
        case "max", "100%":
            normalized = "max"
        default:
            normalized = "auto"
        }

        // 1. 立即乐观更新 UI 档位高亮，避免主线程等待权限弹窗或 SMC 解锁
        if var snap = latestSnapshot {
            let updatedFan = FanSnapshot(
                hasFans: snap.fan.hasFans,
                fanCount: snap.fan.fanCount,
                rpm: snap.fan.rpm,
                minRPM: snap.fan.minRPM,
                maxRPM: snap.fan.maxRPM,
                percentage: normalized == "max" ? max(snap.fan.percentage, 100) : (normalized == "cooling" ? max(snap.fan.percentage, 50) : snap.fan.percentage),
                mode: normalized,
                modeNote: snap.fan.modeNote,
                leftFanRPM: snap.fan.leftFanRPM,
                rightFanRPM: snap.fan.rightFanRPM
            )
            snap = TelemetrySnapshot(
                timestamp: snap.timestamp,
                specs: snap.specs,
                cpu: snap.cpu,
                gpu: snap.gpu,
                memory: snap.memory,
                diskIO: snap.diskIO,
                network: snap.network,
                fan: updatedFan,
                topProcesses: snap.topProcesses,
                totalProcessCount: snap.totalProcessCount,
                battery: snap.battery,
                storage: snap.storage,
                externalDrives: snap.externalDrives,
                connectedDevices: snap.connectedDevices,
                bluetoothPeripherals: snap.bluetoothPeripherals,
                privacySignals: snap.privacySignals
            )
            latestSnapshot = snap
        }

        let engine = engine, queue = sampleQueue, subscribed = subscribed
        controlQueue.async { [weak self] in
            let success = engine.setFanMode(normalized)
            DispatchQueue.main.async { [weak self] in
                self?.isSettingFanMode = false
                if success {
                    if normalized != "auto" {
                        self?.fanControlFeedback = L10n.localized(.fanControlAppliedToast)
                        AppState.shared?.toast = L10n.localized(.fanControlAppliedToast)
                    } else {
                        self?.fanControlFeedback = nil
                    }
                } else {
                    if normalized != "auto" {
                        self?.fanControlFeedback = L10n.localized(.fanControlAuthFailedOrCancelled)
                        AppState.shared?.toast = L10n.localized(.fanControlAuthFailedOrCancelled)
                    }
                }
                completion?(success)
            }
            for delay in [0.0, 0.9, 2.0, 3.5] {
                queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                    let snap = engine.sample(includeProcesses: subscribed.value)
                    DispatchQueue.main.async { [weak self] in self?.latestSnapshot = snap }
                }
            }
        }
    }

    func toggleLowLatency() {
        engine.toggleLowLatency()
        triggerImmediateSample(includeProcesses: currentSubscriberCount() > 0)
    }

    // MARK: - 进程控制与管理操作

    func terminate(process: MonitoredProcessItem, force: Bool = false) -> (success: Bool, message: String) {
        let result = engine.terminateProcess(
            pid: process.pid,
            expectedStartSec: process.startSec,
            expectedStartUsec: process.startUsec,
            force: force
        )
        if result.success {
            let engine = engine
            sampleQueue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                let snap = engine.sample(includeProcesses: true)
                DispatchQueue.main.async { [weak self] in self?.latestSnapshot = snap }
            }
        }
        return result
    }

    /// 一键优化内存与缓存（优先尝试系统 purge，非特权态自动降级执行用户态缓存回收与堆页释放，并刷新实时快照）
    func purgeMemory(completion: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        purgeMemory(shellExecutor: nil, completion: completion)
    }

    func purgeMemory(
        shellExecutor: (@Sendable (String, [String]) -> ShellResult)?,
        completion: (@MainActor @Sendable (Bool) -> Void)? = nil
    ) {
        let engine = engine
        let includeProcesses = currentSubscriberCount() > 0
        sampleQueue.async { [weak self] in
            URLCache.shared.removeAllCachedResponses()
            ProcessIconCache.shared.removeAll()
            _ = malloc_zone_pressure_relief(nil, 0)

            let exec: @Sendable (String, [String]) -> ShellResult = shellExecutor ?? { bin, args in
                Shell.execute(bin, args, timeout: 10.0)
            }
            let purgeRes = exec("/usr/sbin/purge", [])
            let ok: Bool
            if purgeRes.isSuccess {
                ok = true
            } else {
                let combined = (purgeRes.stderr + "\n" + purgeRes.stdout).lowercased()
                if combined.contains("not permitted") || combined.contains("permission denied") {
                    let dnsRes = exec("/usr/bin/dscacheutil", ["-flushcache"])
                    ok = dnsRes.isSuccess
                } else {
                    ok = false
                }
            }

            let snap = engine.sample(includeProcesses: includeProcesses)
            DispatchQueue.main.async { [weak self] in
                self?.latestSnapshot = snap
                completion?(ok)
            }
        }
    }
}

// MARK: - 进程应用图标内存缓存 (消除 View.body 内同步磁盘 I/O 与 NSWorkspace.icon 重绘卡顿)

final class ProcessIconCache: @unchecked Sendable {
    static let shared = ProcessIconCache()
    private let cache = NSCache<NSString, NSImage>()
    private let missingLock = NSLock()
    private var missingPaths = Set<String>()

    private init() {
        cache.countLimit = 256
    }

    func removeAll() {
        cache.removeAllObjects()
        missingLock.lock()
        missingPaths.removeAll()
        missingLock.unlock()
    }

    func icon(forAppPath path: String?) -> NSImage? {
        guard let path, !path.isEmpty else { return nil }
        let key = path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        missingLock.lock()
        let isKnownMissing = missingPaths.contains(path)
        missingLock.unlock()
        if isKnownMissing {
            return nil
        }
        guard FileUtil.exists(path) else {
            missingLock.lock()
            missingPaths.insert(path)
            missingLock.unlock()
            return nil
        }
        let img = NSWorkspace.shared.icon(forFile: path)
        img.size = NSSize(width: 32, height: 32)
        cache.setObject(img, forKey: key)
        return img
    }
}
