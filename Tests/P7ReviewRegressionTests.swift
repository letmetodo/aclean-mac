import Foundation
import AppKit
import CryptoKit
import Darwin

@MainActor
final class P7ReviewRegressionTests {
    private let fm = FileManager.default
    private let base = URL(fileURLWithPath: "/private/tmp").appendingPathComponent("AClean-P7-" + UUID().uuidString)
    private var passed = 0
    init() { try! fm.createDirectory(at: base, withIntermediateDirectories: true) }
    deinit { try? fm.removeItem(at: base) }
    private func check(_ value: @autoclosure () -> Bool, _ message: String) {
        precondition(value(), message)
        passed += 1
    }
    private func file(_ path: String, data: Data = Data([1, 2, 3])) throws -> URL {
        let url = base.appendingPathComponent(path)
        try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
        return url
    }
    private func eventually(_ predicate: () -> Bool) async {
        let deadline = Date().addingTimeInterval(5)
        while !predicate(), Date() < deadline { try? await Task.sleep(nanoseconds: 10_000_000) }
        check(predicate(), "Timed out waiting for lifecycle")
    }

    func runAll() async throws {
        try testIdentityAndDuplicateEvidence()
        try testHashFailureAndShortReads()
        try testProtectedScope()
        try testAccountingAndGitPaths()
        try testDescriptorDeletion()
        try testMissingAndUnreadableTargets()
        testSelectionAndReceipts()
        testBoundedWorkersAndCancellation()
        await testOldScanCannotSettleNewScan()
        await testScheduledScanDoesNotUsePageSelection()
        await testSmartScanSettlesAfterPageSwitch()
        print("P7: \(passed) deterministic regression assertions passed")
    }

    private func testIdentityAndDuplicateEvidence() throws {
        let target = try file("identity.txt")
        var t = [timespec(tv_sec: 1_700_000_000, tv_nsec: 1), timespec(tv_sec: 1_700_000_000, tv_nsec: 1)]
        check(utimensat(AT_FDCWD, target.path, &t, 0) == 0, "set initial identity time")
        let identity = FileIdentity.capture(from: target)!
        let h = try FileHandle(forWritingTo: target)
        try h.seekToEnd(); try h.write(contentsOf: Data([4])); try h.close()
        t[1].tv_nsec = 900
        check(utimensat(AT_FDCWD, target.path, &t, 0) == 0, "set changed identity time")
        check(!identity.matches(url: target), "Same-second content/size changes must invalidate identity")
        let keeper = try file("duplicate-keeper.txt")
        let copy = try file("duplicate-copy.txt")
        let evidence = DuplicateEvidence(keeper: keeper, identity: FileIdentity.capture(from: keeper)!, digest: OrganizeEngine.fullHash(keeper)!)
        check(evidence.validates(target: copy), "Equal stable copies are valid")
        try fm.removeItem(at: keeper)
        check(!evidence.validates(target: copy), "Missing retained copy must prevent deletion")
        var node = Node(name: "copy", url: copy, size: 3)
        node.duplicateEvidence = evidence
        check(!Cleaner.clean(CleanTarget(node)).ok, "Real Cleaner must reject a missing keeper")
    }

    private func testHashFailureAndShortReads() throws {
        var calls = 0
        do {
            _ = try OrganizeEngine.hashContents(limit: nil, expectedSize: 2, stopped: { false }) { _ in
                calls += 1
                if calls == 1 { return Data([1]) }
                throw CocoaError(.fileReadUnknown)
            }
            preconditionFailure("I/O failure cannot produce a hash")
        } catch { passed += 1 }
        var shortReads = [Data([1]), Data([2]), Data([3]), Data()]
        let digest = try OrganizeEngine.hashContents(limit: nil, expectedSize: 3, stopped: { false }) { _ in shortReads.removeFirst() }
        let expected = SHA256.hash(data: Data([1, 2, 3])).map { String(format: "%02x", $0) }.joined()
        check(digest == expected, "Short read is not EOF")
        do {
            _ = try OrganizeEngine.hashContents(limit: nil, expectedSize: 3, stopped: { false }) { _ in Data() }
            preconditionFailure("Premature EOF cannot produce a hash")
        } catch { passed += 1 }
    }

    private func testProtectedScope() throws {
        let photos = try file("archive/Family.photoslibrary/database")
        check(!CleanupSafetyPolicy.inspect(photos.deletingLastPathComponent().deletingLastPathComponent()).isSafe,
              "A parent cannot remove a protected library")
        let cloud = try file("CloudStorage/Provider/cache.bin")
        check(!RiskControlMatrix.validateCleanTarget(url: cloud.deletingLastPathComponent(), action: .trash).isSafe,
              "Cloud policy applies in executor")
        let deep = try file("deep/" + (0..<12).map { "d\($0)" }.joined(separator: "/") + "/wallet-keypair.json")
        check(!CleanupSafetyPolicy.inspect(base.appendingPathComponent("deep")).isSafe, "Deep credentials must be found")
        check(GitGuard.containsSensitiveAssets(in: base.appendingPathComponent("deep")).hasSensitive,
              "Depth cap must fail closed")
        let cancelled = IOScanContext(stopped: { true })
        check(!cancelled.perform { CleanupSafetyPolicy.inspect(base.appendingPathComponent("deep")) }.isSafe,
              "Cancellation cannot become a clear subtree")
        check(fm.fileExists(atPath: deep.path), "Safety checks must be read-only")
        let ordinary = try file("ordinary/a.txt")
        check(CleanupSafetyPolicy.inspect(ordinary.deletingLastPathComponent()).isSafe, "Ordinary reviewed folder remains cleanable")
    }

    private func testAccountingAndGitPaths() throws {
        let directory = base.appendingPathComponent("accounting")
        let sparse = try file("accounting/sparse", data: Data())
        let h = try FileHandle(forWritingTo: sparse); try h.truncate(atOffset: 64 * 1024 * 1024); try h.close()
        var st = stat(); check(lstat(sparse.path, &st) == 0, "sparse stat")
        check(FileUtil.size(of: sparse) == Int64(st.st_blocks) * 512, "Zero allocated blocks cannot fall back to logical size")
        let hidden = try file("accounting/.hidden", data: Data(repeating: 1, count: 8192))
        let originalBytes = FileUtil.size(of: hidden)
        try fm.linkItem(at: hidden, to: directory.appendingPathComponent("hardlink"))
        check(FileUtil.directorySize(directory) == originalBytes + Int64(st.st_blocks) * 512,
              "Include hidden files and count a hardlink inode once")
        let repo = base.appendingPathComponent("repo")
        try fm.createDirectory(at: repo, withIntermediateDirectories: true)
        check(Shell.execute("/usr/bin/git", ["-C", repo.path, "init", "-q"]).isSuccess, "git fixture init")
        check(Shell.execute("/usr/bin/git", ["-C", repo.path, "config", "core.quotePath", "true"]).isSuccess, "git fixture quote setting")
        for name in ["中文.txt", "tab\t.txt", "line\n.txt", " spaced .txt"] {
            let url = try file("repo/" + name)
            check(Shell.execute("/usr/bin/git", ["-C", repo.path, "add", "--", name]).isSuccess, "track special path")
            GitGuard.invalidateTrackedCache()
            check(GitGuard.hasGitTrackedFiles(url: url), "NUL parsing must protect \(name.debugDescription)")
        }
    }

    private func testDescriptorDeletion() throws {
        let prevDryRun = Cleaner.isDryRun
        Cleaner.isDryRun = false
        defer { Cleaner.isDryRun = prevDryRun }
        let root = base.appendingPathComponent("trash-fixture")
        let target = try file("trash-fixture/item/inside.txt")
        let external = try file("external.txt", data: Data([9]))
        try fm.createSymbolicLink(at: target.deletingLastPathComponent().appendingPathComponent("link"), withDestinationURL: external)
        let item = target.deletingLastPathComponent()
        Cleaner.authorizedTrashRootsOverride = [root]
        defer { Cleaner.authorizedTrashRootsOverride = nil }
        let validOutcome = Cleaner.clean(CleanTarget(name: item.lastPathComponent, url: item, size: 100, action: .permanentlyDeleteTrashItem))
        check(validOutcome.ok, "Descriptor deletion removes claimed folder via Cleaner.clean")
        check(!fm.fileExists(atPath: item.path), "Descriptor deletion removes claimed folder")
        check(fm.fileExists(atPath: external.path), "Contained symlink cannot remove external target")
        let externalOutcome = Cleaner.clean(CleanTarget(name: external.lastPathComponent, url: external, size: 9, action: .permanentlyDeleteTrashItem))
        check(!externalOutcome.ok, "Outside trash cannot be permanently removed")
        check(fm.fileExists(atPath: external.path), "Outside-trash rejection preserves file")
        passed += 1
    }

    private func testSelectionAndReceipts() {
        let similar = Node(name: "Similar", url: base.appendingPathComponent("photo.jpg"), safety: .caution, autoSelected: true)
        check(!CleanupSelectionPolicy.isRecommended(similar), "Caution never recommended")
        let installer = Node(name: "Installer", url: FileUtil.home.appendingPathComponent("Downloads/keep.dmg"), safety: .safe, autoSelected: true)
        check(!CleanupSelectionPolicy.isRecommended(installer), "User installer never recommended")
        check(UninstallerEngine.matchesBundleID("com.example.Editor.helper", bundleID: "com.example.Editor"), "Separated helper matches")
        check(!UninstallerEngine.matchesBundleID("com.example.EditorBeta", bundleID: "com.example.Editor"), "Prefix-only sibling cannot match")
        check(UninstallerEngine.classifyFolderPurpose(path: "/Users/test/Library/HTTPStorages/example").isUserData, "HTTP sessions are user data")
        check(DockerHelper.parseByteSizeString("1.5GB") == 1_500_000_000, "Docker decimal units")
        check(DockerHelper.parseByteSizeString("1GiB") == 1_073_741_824, "Explicit IEC units")
        check(DockerHelper.parseReclaimableBytes(from: "Local Volumes  3 0 2GB 2GB (100%)\nBuild Cache 2 0 500MB 500MB (100%)") == 500_000_000, "Do not count volumes in cache prune")
        let report = CleanReport(module: "fixture", outcomes: [
            CleanOutcome(name: "ok", path: "a", size: 10, ok: true, actionCategory: .systemReclaimed),
            CleanOutcome(name: "bad", path: "b", size: 0, ok: false, actionCategory: .failed)
        ])
        check(report.state == .partial, "One success cannot turn partial failure into success")
        check(report.actualFreedBytes == 0 && report.reportedReclaimedBytes == 10, "Daemon output is not host volume observation")
        let mixed = CleanReport(module: "fixture", outcomes: [
            CleanOutcome(name: "failed maintenance", path: "", size: 0, ok: false, actionCategory: .maintenanceExecuted),
            CleanOutcome(name: "skipped", path: "", size: 0, ok: false, actionCategory: .skipped),
            CleanOutcome(name: "cancelled", path: "", size: 0, ok: false, actionCategory: .cancelled)
        ])
        check(mixed.errorCount == 1 && mixed.skippedCount == 1 && mixed.cancelledCount == 1, "Receipt counts distinguish failures, skips and cancellation")
        check(!PerformanceEngine.freeRAM() && !PerformanceEngine.vacuumDatabases(), "Unsafe generic maintenance does not fabricate success")
    }

    private func testMissingAndUnreadableTargets() throws {
        let missing = try file("missing/file")
        let target = CleanTarget(Node(name: "missing", url: missing, size: 3))
        try fm.removeItem(at: missing)
        check(Cleaner.clean(target).actionCategory == .absent, "Only missing paths are absent")
        let unreadable = try file("unreadable/file")
        let deniedTarget = CleanTarget(Node(name: "denied", url: unreadable, size: 3))
        let parent = unreadable.deletingLastPathComponent()
        check(chmod(parent.path, 0) == 0, "Create unreadable fixture")
        defer { _ = chmod(parent.path, S_IRWXU) }
        if geteuid() != 0 {
            let outcome = Cleaner.clean(deniedTarget)
            check(outcome.actionCategory == .failed && outcome.failureKind == .permission,
                  "Permission denial must not remove a target as absent")
        }
    }

    private func testBoundedWorkersAndCancellation() {
        let slots = ScanResultSlots<Int>(repeating: -1, count: 128)
        IOScanContext.concurrentPerform(iterations: 128) { index in slots[index] = index }
        check(slots.values == Array(0..<128), "Concurrent result slots cannot lose writes")
        let flag = StopFlag()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { flag.value = true }
        let start = Date()
        let result = IOScanContext(stopped: { flag.value }).perform { Shell.execute("/bin/sleep", ["10"], timeout: 15) }
        check(!result.isSuccess && Date().timeIntervalSince(start) < 2, "Subprocess cancellation must interrupt wait")
    }

    private func testOldScanCannotSettleNewScan() async {
        let old = DispatchSemaphore(value: 0), next = DispatchSemaphore(value: 0)
        let count = LockedValue(0)
        let state = AppState(scanBuilder: { _ in { _, _, _ in
            let run = count.withValue { $0 += 1; return $0 }
            if run == 1 { old.wait() } else { next.wait() }
            return []
        } })
        state.startScan(for: "junk")
        await eventually { count.withValue { $0 == 1 } }
        state.startScan(for: "junk", forceRestart: true)
        await eventually { count.withValue { $0 == 2 } }
        old.signal()
        try? await Task.sleep(nanoseconds: 100_000_000)
        check(state.activeScanningModules.contains("junk") && state.isScanning(module: "junk"), "Old completion must not remove new active scan")
        next.signal()
        await eventually { !state.isScanning(module: "junk") }
    }

    private func testScheduledScanDoesNotUsePageSelection() async {
        let release = DispatchSemaphore(value: 0)
        let entered = StopFlag()
        let state = AppState(scanBuilder: { _ in { _, _, _ in entered.value = true; release.wait(); return [] } })
        let original = SchedulerService.shared.config
        defer { SchedulerService.shared.config = original }
        SchedulerService.shared.config.isEnabled = true
        SchedulerService.shared.config.autoClean = true
        SchedulerService.shared.config.minimumCleanSize = 1
        let job = Task { await state.runScheduledCleanup() }
        await eventually { entered.value }
        state.open(.restore(.organize))
        let node = Node(name: "must stay", url: base.appendingPathComponent("keep.txt"), size: 100)
        state.roots = [node]; state.selection = [node.id]
        release.signal(); _ = await job.value
        check(state.activeCleanupRun == nil && state.report == nil, "Scheduled junk job must not execute organize selection")
        check(state.selection.contains(node.id), "Scheduled job must preserve current page selection")
    }

    private func testSmartScanSettlesAfterPageSwitch() async {
        let release = DispatchSemaphore(value: 0), entered = StopFlag()
        let state = AppState(scanBuilder: { _ in { _, _, _ in entered.value = true; release.wait(); return [] } })
        state.open(.restore(.smartCare))
        state.scanSmartCard(SmartCareModule.cards[0])
        await eventually { entered.value }
        state.open(.restore(.organize))
        let node = Node(name: "stay", url: base.appendingPathComponent("stay.txt"), size: 3)
        state.roots = [node]
        release.signal()
        await eventually { state.smartScanFlags.isEmpty }
        check(state.roots.first?.id == node.id && state.moduleKey == "organize", "Smart completion cannot replace another page")
        check(!state.session(for: "smartCare").scanning, "Smart session must settle offscreen")
        state.open(.restore(.smartCare))
        check(!state.scanning && state.screen == .results, "Returning to SmartCare must show settled results")
    }
}
