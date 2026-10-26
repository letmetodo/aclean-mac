import Foundation

@MainActor
struct P9ReviewFollowupTests {
    func runAll() async throws {
        var count = 0
        func check(_ value: Bool, _ message: String) { precondition(value, message); count += 1 }

        let suite = "org.cleanmate.scheduler-review." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let scheduler = SchedulerService(defaults: defaults)
        scheduler.config.isEnabled = true
        scheduler.config.nextRunDate = .distantPast
        var calls = 0
        scheduler.setTrigger {
            calls += 1
            try? await Task.sleep(nanoseconds: 20_000_000)
            return true
        }
        let agent = Task { await scheduler.triggerDueJob() }
        let timer = Task { await scheduler.triggerDueJob() }
        let first = await agent.value
        let second = await timer.value
        check(first != second && calls == 1, "LaunchAgent and timer must share an in-flight run")
        check(scheduler.config.lastRunDate != nil && scheduler.config.nextRunDate! > Date(), "successful agent run must advance the persisted schedule")
        let persisted = try JSONDecoder().decode(ScheduleConfig.self, from: defaults.data(forKey: AppConfig.Scheduling.storageKey)!)
        check(persisted == scheduler.config, "completion and next due time must be persisted together")
        let duplicate = await scheduler.triggerDueJob()
        check(!duplicate && calls == 1, "the next timer tick cannot repeat an acknowledged agent run")
        scheduler.config.nextRunDate = .distantPast
        let lastRun = scheduler.config.lastRunDate
        scheduler.setTrigger { false }
        let skipped = await scheduler.triggerDueJob()
        check(!skipped && scheduler.config.nextRunDate == .distantPast && scheduler.config.lastRunDate == lastRun,
              "busy jobs retain their due time and last actual run")
        scheduler.setTrigger { true }
        let retried = await scheduler.triggerDueJob()
        check(retried && scheduler.config.nextRunDate! > Date(), "busy jobs must remain retryable")
        scheduler.config.nextRunDate = .distantPast
        scheduler.setTrigger { scheduler.config.isEnabled = false; return true }
        let revoked = await scheduler.triggerDueJob()
        check(!revoked && scheduler.config.nextRunDate == .distantPast, "revoked jobs must not acknowledge the old authorization")
        scheduler.setTrigger { true }

        var fan = FanControlState()
        let cooling = fan.completeChange(to: "cooling", succeeded: true)!
        let failed = fan.completeChange(to: "max", succeeded: false)
        check(failed == nil && fan.mode == "cooling" && fan.generation == cooling,
              "failed hardware changes cannot publish a new mode or invalidate the valid lease")
        let maximum = fan.completeChange(to: "max", succeeded: true)!
        check(!fan.expireLease(generation: cooling) && fan.mode == "max",
              "an old renewal failure cannot cancel a newer fan mode")
        check(fan.expireLease(generation: maximum) && fan.mode == "auto", "a current expired lease must revert to auto")
        check(!fan.expireLease(generation: maximum), "duplicate callbacks cannot expire a later generation")
        _ = fan.completeChange(to: "auto", succeeded: true)
        check(!fan.expireLease(generation: maximum) && fan.mode == "auto", "an old renewal cannot revive or change automatic mode")

        // P1-2: 退出复位看门狗与租约到期安全性断言
        SMCBridge.shared.resetFanToAutoOnTermination()
        check(SMCBridge.shared.activeFanPreset == "auto", "resetFanToAutoOnTermination must restore or keep activeFanPreset as auto")

        let networkKey = AppConfig.StorageKeys.networkFeaturesEnabled
        let previousNetwork = UserDefaults.standard.object(forKey: networkKey)
        UserDefaults.standard.set(false, forKey: networkKey)
        defer {
            if let previousNetwork { UserDefaults.standard.set(previousNetwork, forKey: networkKey) }
            else { UserDefaults.standard.removeObject(forKey: networkKey) }
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ReviewNetworkStub.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let weather = WeatherService(session: session)
        let now = ISO8601DateFormatter().date(from: "2026-10-22T23:30:00Z")!
        let geo = GeoLocationInfo(city: "Test", region: "", country: "", latitude: 0, longitude: 0,
                                  publicIP: "", isp: "", isManualCity: true, updatedAt: now)
        var payload: [String: Any] = [
            "utc_offset_seconds": 19800,
            "current": ["temperature_2m": 42, "weather_code": 0, "is_day": 1],
            "hourly": ["time": ["2026-10-23T04:00", "2026-10-23T05:00", "2026-10-23T06:00"],
                       "temperature_2m": [41, 42, 43]],
            "daily": ["time": ["2026-10-23"], "temperature_2m_max": [44], "temperature_2m_min": [40]]
        ]
        let snapshot = try weather.parseOpenMeteo(data: JSONSerialization.data(withJSONObject: payload), geo: geo, now: now)!
        check(snapshot.hourly.first?.temp == 42 && snapshot.hourly.count == 2,
              "hourly forecasts must start at the city's hour, including fractional UTC offsets")
        check(snapshot.hourly.last?.hour == "06:00" && snapshot.updateTime == now,
              "forecast ordering and observation time must remain deterministic")
        let previousLanguage = L10n.shared.currentLanguage
        defer { L10n.shared.language = previousLanguage }
        L10n.shared.language = .en
        let cached = try JSONDecoder().decode(WeatherSnapshot.self, from: JSONEncoder().encode(snapshot))
        L10n.shared.language = .ja
        check(cached.hourly.first?.localizedHour == L10n.localized(.timeNow), "cached current-hour labels must follow language changes")
        let legacy = try JSONDecoder().decode(HourlyWeatherItem.self,
            from: Data(#"{"hour":"Now","temp":42,"iconName":"sun.max.fill","isSun":true,"precipProbability":0}"#.utf8))
        check(legacy.localizedHour == L10n.localized(.timeNow), "legacy localized caches must migrate their current-hour label")
        payload["current"] = [:] as [String: Any]
        let emptyCurrent = try weather.parseOpenMeteo(data: JSONSerialization.data(withJSONObject: payload), geo: geo, now: now)
        check(emptyCurrent == nil, "missing temperature cannot be published as real zero-degree weather")
        payload["current"] = ["temperature_2m": 42]
        payload["hourly"] = ["time": ["2026-10-23T05:00"], "temperature_2m": []]
        let incomplete = try weather.parseOpenMeteo(data: JSONSerialization.data(withJSONObject: payload), geo: geo, now: now)
        check(incomplete == nil, "incomplete hourly data cannot invent future readings from current temperature")
        let task = PerformanceEngine.maintenanceTasks().first { $0.taskId == "thinTimeMachine" }!
        let purgeTask = PerformanceEngine.maintenanceTasks().first { $0.taskId == "purgeableSpace" }!
        check(task.command == ([AppConfig.SystemReclaim.tmutilPath] + AppConfig.SystemReclaim.snapshotThinningArguments).joined(separator: " ")
              && purgeTask.command == task.command,
              "maintenance previews must disclose the same bounded snapshot thinning request as execution")
        let thinning = AppConfig.PrivilegedHelper.commands["thinTimeMachine"]!.first!
        check(thinning.0 == "/usr/bin/tmutil" && thinning.1 == ["thinlocalsnapshots", "/", "10737418240", "4"],
              "both execution routes must use the actual tmutil subcommand and the bounded 10 GiB request")
        let btmPath = "/private/tmp/AClean-BTM-Fixture-\(UUID().uuidString).app"
        let btmItem = StartupItem(name: "BTMHelper", path: btmPath, scope: "Background Services", program: btmPath, broken: false, enabled: true, stateKnown: false, isBackground: true, displayName: "BTMHelper", managedBySystemSettings: true)
        let btmNode = PerformanceModule.node(from: btmItem)
        check(btmNode.locked && !PerformanceEngine.setEnabled(btmItem, enabled: false) && PerformanceEngine.startupOverride(for: btmPath) == nil,
              "BTM items managed by System Settings must stay locked and never record fake disable overrides")

        // CM-01 & CM-07: AppConfigStore oldFileMonths sync & SchedulerService interval recalculation
        let prevMonths = AppConfigStore.shared.oldFileMonths
        defer { AppConfigStore.shared.oldFileMonths = prevMonths }
        AppConfigStore.shared.oldFileMonths = 12
        check(AppConfigStore.shared.currentOldFileMonths == 12, "CM-01: currentOldFileMonths must reflect configured oldFileMonths")
        scheduler.updateSchedule(interval: .monthly)
        check(scheduler.config.interval == .monthly && (scheduler.config.nextRunDate ?? .distantPast) > Date().addingTimeInterval(20 * 86400),
              "CM-07: updateSchedule(interval:) must recalculate nextRunDate")

        // CM-03: PerformanceEngine.executeTask distinguishes succeeded, targetNotRunning, and failed
        let finderTask = PerformanceEngine.quickGlitchFixes().first { $0.taskId == "fixFinderDock" }!
        let notRunningRes = PerformanceEngine.executeTask(finderTask) { _, _ in
            CommandResult(stdout: "", stderr: "No matching processes belonging to you were found", exitCode: 1)
        }
        let failedRes = PerformanceEngine.executeTask(finderTask) { _, _ in
            CommandResult(stdout: "", stderr: "Operation not permitted", exitCode: 1)
        }
        check(notRunningRes == .targetNotRunning, "CM-03: killall with no matching process must return .targetNotRunning")
        if case .failed = failedRes { check(true, "CM-03: real execution failure") } else { check(false, "CM-03: real failure must not be swallowed") }

        // CM-11: BK-tree transitive connected components in clusterSimilarHashes
        let chainHashes: [UInt64] = [0b0000, 0b0011, 0b1111]
        let clusters = OrganizeEngine.clusterSimilarHashes(chainHashes, maxDistance: 2)
        check(clusters.count == 1 && Set(clusters[0]) == Set([0, 1, 2]),
              "CM-11: transitive chain A~B~C must form a single connected component regardless of traversal order")

        // CM-15: Strict weak ordering for equal sizes in descending sort & full child date aggregation
        let state = AppState()
        state.sortKey = .size
        state.sortAscending = false
        let nodeA = Node(name: "Alpha", url: URL(fileURLWithPath: "/tmp/alpha"), size: 1024)
        let nodeB = Node(name: "Beta", url: URL(fileURLWithPath: "/tmp/beta"), size: 1024)
        let sortedAB = state.sorted([nodeA, nodeB])
        let sortedBA = state.sorted([nodeB, nodeA])
        check(sortedAB.map({ $0.path }) == ["/tmp/alpha", "/tmp/beta"] && sortedBA.map({ $0.path }) == ["/tmp/alpha", "/tmp/beta"],
              "CM-15: equal primary keys must produce deterministic order without violating strict weak ordering")

        // CM-18: CleanHistoryStore preserves lifetime cumulative totals beyond 50 recent entries
        let historyStore = CleanHistoryStore(defaults: defaults)
        for _ in 0..<55 {
            historyStore.record(moduleTitle: "Junk", itemCount: 1, bytes: 100, failedCount: 0)
        }
        let reloadedHistory = CleanHistoryStore(defaults: defaults)
        check(reloadedHistory.entries.count == 50 && reloadedHistory.totalRuns == 55 && reloadedHistory.totalBytes == 5500,
              "CM-18: lifetime cumulative runs and bytes must not shrink when recent entries ring buffer caps at 50")

        // CM-19, CM-23, CM-26, CM-27: Telemetry safety, PID identity guard, and IP sanitization
        var signalCalled = false
        let pidMismatch = SystemTelemetryEngine.shared.terminateProcess(
            pid: getpid(),
            expectedStartSec: -1,
            expectedStartUsec: -1,
            force: false,
            signalSender: { _, _ in signalCalled = true; return 0 }
        )
        check(!pidMismatch.success && !signalCalled, "CM-19: mismatched process start time must abort kill signal")
        check(IPGeoService.sanitizePublicIP("203.0.113.5") == "203.0.113.5" && IPGeoService.sanitizePublicIP("Detecting...") == "",
              "CM-23: sanitizePublicIP must accept valid IPs and reject localized status/error strings")
        let nlenOffset = MemoryLayout<sockaddr_dl>.offset(of: \.sdl_nlen) ?? 5
        let dataOffset = MemoryLayout<sockaddr_dl>.offset(of: \.sdl_data) ?? 8
        let nameBytes = Array("bridge100vlan".utf8)
        var validBuf = [UInt8](repeating: 0, count: 16 + dataOffset + nameBytes.count)
        validBuf[16 + nlenOffset] = UInt8(nameBytes.count)
        for (i, b) in nameBytes.enumerated() { validBuf[16 + dataOffset + i] = b }
        let validName = validBuf.withUnsafeBufferPointer { ptr in
            SystemTelemetryEngine.decodeSockaddrDLInterfaceName(from: ptr.baseAddress!, messageLength: validBuf.count, headerStride: 16)
        }
        var oobBuf = validBuf
        oobBuf[16 + nlenOffset] = UInt8(nameBytes.count + 10)
        let outOfBoundsName = oobBuf.withUnsafeBufferPointer { ptr in
            SystemTelemetryEngine.decodeSockaddrDLInterfaceName(from: ptr.baseAddress!, messageLength: oobBuf.count, headerStride: 16)
        }
        check(validName == "bridge100vlan" && outOfBoundsName == nil,
              "CM-26: decodeSockaddrDLInterfaceName must support >12 char interface names and reject out-of-bounds sdl_nlen")
        let selectedIface = SystemTelemetryEngine.selectActiveInterface(
            interfaceTotals: ["en0": 15_000_000, "en1": 3_000],
            previousTotals: ["en0": 15_000_000, "en1": 1_500],
            interfacesWithAddress: ["en0", "en1"],
            fallback: "en0"
        )
        check(selectedIface == "en1", "CM-27: selectActiveInterface must prefer interface with active interval traffic delta")

        let fallbackPurgeOk: Bool = await withCheckedContinuation { continuation in
            SystemTelemetryService.shared.purgeMemory(shellExecutor: { bin, args in
                if bin == "/usr/sbin/purge" {
                    return CommandResult(stdout: "", stderr: "Unable to purge disk buffers: Operation not permitted", exitCode: 1)
                }
                if bin == "/usr/bin/dscacheutil" && args == ["-flushcache"] {
                    return CommandResult(stdout: "", stderr: "", exitCode: 0)
                }
                return CommandResult(stdout: "", stderr: "Unexpected command", exitCode: 1)
            }) { ok in
                continuation.resume(returning: ok)
            }
        }
        check(fallbackPurgeOk && SystemTelemetryService.shared.latestSnapshot != nil,
              "purgeMemory must gracefully fall back to user-space cache flush when /usr/sbin/purge returns Operation not permitted")

        let realPurgeOk: Bool = await withCheckedContinuation { continuation in
            SystemTelemetryService.shared.purgeMemory { ok in
                continuation.resume(returning: ok)
            }
        }
        check(realPurgeOk, "purgeMemory end-to-end execution must succeed under current user privileges")

        print("P9 review followup: \(count) scheduling, lease and forecast assertions passed")
    }
}
