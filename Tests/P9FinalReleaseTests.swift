import Foundation

final class ReviewNetworkStub: URLProtocol, @unchecked Sendable {
    static let requests = LockedValue(0)
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.requests.withValue { $0 += 1 }
        let data = Data(#"{"success":true,"ip":"192.0.2.1","city":"Test City","region":"Test","country":"Test","latitude":1,"longitude":2,"connection":{"isp":"Test ISP"}}"#.utf8)
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

@MainActor
struct P9FinalReleaseTests {
    func runAll() async throws {
        let fm = FileManager.default
        let base = fm.temporaryDirectory.appendingPathComponent("CleanMate-final-" + UUID().uuidString)
        let trash = base.appendingPathComponent(".Trash")
        try fm.createDirectory(at: trash, withIntermediateDirectories: true)
        let previousRoots = Cleaner.authorizedTrashRootsOverride
        Cleaner.authorizedTrashRootsOverride = [trash]
        defer { Cleaner.authorizedTrashRootsOverride = previousRoots; try? fm.removeItem(at: base) }
        var count = 0
        func check(_ value: Bool, _ message: String) { precondition(value, message); count += 1 }
        func file(_ path: String, _ value: String = "payload") throws -> URL {
            let url = base.appendingPathComponent(path)
            try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(value.utf8).write(to: url)
            return url
        }
        // Renamed Trash entries must recover their recorded names, including a single container child.
        let source = try file(".Trash/renamed 2.bin")
        let original = base.appendingPathComponent("missing-container/original.bin")
        let item = CleanupRestoreItem(originalURL: original, trashURL: source, bytes: 7)
        let recovered = CleanupRestoreService.restore([item])
        check(recovered.restoredIDs == [item.id] && recovered.restoredBytes == 7 && fm.fileExists(atPath: original.path), "restore must honor exact mapping")
        let conflictSource = try file(".Trash/conflict.bin")
        let conflict = CleanupRestoreItem(originalURL: original, trashURL: conflictSource, bytes: 7)
        let blocked = CleanupRestoreService.restore([conflict])
        check(blocked.restoredIDs.isEmpty && blocked.failedPaths == [original.path] && fm.fileExists(atPath: conflictSource.path), "conflicts must remain recoverable, with no false success")
        let swap = try file(".Trash/swapped.bin")
        let identity = CleanupRestoreItem(originalURL: base.appendingPathComponent("swapped-result"), trashURL: swap, bytes: 7)
        try fm.moveItem(at: swap, to: trash.appendingPathComponent("old-inode"))
        _ = try file(".Trash/swapped.bin", "unrelated")
        check(!CleanupRestoreService.restore([identity]).failedPaths.isEmpty, "replacement inode must be rejected")
        let similar = try file(".TrashBackup/unauthorized.bin")
        check(!CleanupRestoreService.restore([CleanupRestoreItem(originalURL: base.appendingPathComponent("escaped"), trashURL: similar, bytes: 7)]).failedPaths.isEmpty, "Trash substring cannot grant restore authority")
        let corrupt = try file("history.json", "invalid JSON")
        let manager = UninstallerUndoManager(storageURL: corrupt)
        check(!manager.recordBatch(appName: "Test", bundleID: "org.cleanmate.test", items: [UninstallUndoItem(originalPath: original.path, trashPath: conflictSource.path, size: 7, isAppBody: true)]), "corrupt history must report persistence failure")
        check(try String(contentsOf: corrupt, encoding: .utf8) == "invalid JSON", "corrupt history must not be overwritten")

        let alternation = RegexEngine.shared.matches("a|ab", "ab")
        check(alternation, "whole-string regex must backtrack across alternatives")
        let shell = Shell.execute("/bin/sh", ["-c", "printf hello; (sleep 1) &"], timeout: 0.2)
        check(shell.isSuccess && shell.stdout == "hello", "exited command cannot time out on a grandchild's descriptor")
        let timeout = Shell.execute("/bin/sh", ["-c", "while :; do printf x; done"], timeout: 0.1)
        check(timeout.exitCode == -2, "active writers must not starve timeout or race FileHandle.close")
        let large = Shell.execute("/usr/bin/printf", ["%s", String(repeating: "x", count: 60000)])
        check(large.isSuccess && large.stdout.utf8.count == 60000, "final stdout must be drained after process exit")

        let key = AppConfig.StorageKeys.networkFeaturesEnabled
        let defaults = UserDefaults.standard
        let old = defaults.object(forKey: key)
        defer { if let old { defaults.set(old, forKey: key) } else { defaults.removeObject(forKey: key) } }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ReviewNetworkStub.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        ReviewNetworkStub.requests.withValue { $0 = 0 }
        defaults.set(false, forKey: key)
        let location = IPGeoService(session: session)
        let weather = WeatherService(session: session)
        _ = await location.refreshPublicIPAndLocation(forceAutoLocate: true, allowNetwork: true)
        _ = await location.searchCities(query: "Test & admin=true", allowNetwork: true)
        weather.refreshWeather(forceAutoLocate: true)
        try await Task.sleep(nanoseconds: 20_000_000)
        check(ReviewNetworkStub.requests.withValue { $0 } == 0, "disabled preference must dominate every request flag, even without cache")
        defaults.set(true, forKey: key)
        let info = await location.refreshPublicIPAndLocation(forceAutoLocate: true)
        check(info?.publicIP == "192.0.2.1", "mock location response must be parsed")
        _ = await location.refreshPublicIPAndLocation()
        check(ReviewNetworkStub.requests.withValue { $0 } == 1, "location must be cached and rate-limited")
        defaults.set(false, forKey: key)
        weather.networkPreferenceChanged()
        let leaf = Node(name: "cursor canvas", url: nil, size: 1)
        var leftover = leaf
        leftover.ruleEvidence = CleanupRuleEvidence(id: "JC.LEFTOVER.HTTP", tier: .review, reason: .generalCache, defaultSelected: false)
        leftover.selectionRestrictions = [.productPolicy]
        check(!CleanupSelectionPolicy.isSelected(node: leftover, in: .devPro) && !CleanupSelectionPolicy.isSelected(node: leftover, in: .maxSpace), "names and residual sessions cannot enter expanded profiles")
        var retained = leaf
        retained.isRetainedOriginal = true
        check(!CleanupSelectionPolicy.isUserSelectable(retained), "retained originals must remain protected in every language")
        let oldSchedule = SchedulerService.shared.config
        defer { SchedulerService.shared.config = oldSchedule }
        let entered = StopFlag()
        let release = DispatchSemaphore(value: 0)
        let scheduled = AppState(scanBuilder: { _ in { _, _, _ in entered.value = true; release.wait(); return [] } })
        SchedulerService.shared.config.isEnabled = true
        SchedulerService.shared.config.autoClean = true
        let job = Task { await scheduled.runScheduledCleanup() }
        let waitUntil = Date().addingTimeInterval(3)
        while !entered.value && Date() < waitUntil { try await Task.sleep(nanoseconds: 10_000_000) }
        SchedulerService.shared.config.isEnabled = false
        release.signal()
        let accepted = await job.value
        check(entered.value && !accepted && scheduled.activeCleanupRun == nil, "turning off a scheduled scan must revoke its cleanup authorization")
        let smart = AppState()
        smart.moduleKey = .smartCare
        var card = SmartCardState()
        var selectable = Node(name: "safe log", url: try file("smart/log.txt"), safety: .safe, size: 7, autoSelected: true)
        selectable.fileIdentity = FileIdentity.capture(from: selectable.url!)
        selectable.ruleEvidence = CleanupRuleEvidence(id: "JC.LOG.USER", tier: .automatic, reason: .generalCache, defaultSelected: true)
        card.tree = [selectable]
        card.done = true
        smart.smartCards[SmartCareModule.cards[0]] = card
        smart.selection = []
        smart.runSmartCleanup()
        check(smart.activeCleanupRun == nil, "Smart Care must respect a user deselecting every item")
        for entry in LocalizationCatalog.entries.values {
            for language in AppLanguage.concreteLanguages {
                check(!entry.text(for: language).isEmpty, "every catalog entry must have ten non-empty translations")
            }
        }
        print("P9 final-release: \(count) restore, corruption, process, network, schedule, selection and localization assertions passed")
    }
}
