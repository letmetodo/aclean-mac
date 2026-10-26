import Foundation
import AppKit
import Darwin

extension P9CrossReviewFixTests {
    func reviewStateAndMemoryRegressions() async throws {
        let previousState = AppState.shared
        defer { AppState.shared = previousState }
        reviewIgnoredDirectoryRegressions()
        reviewMemoryRegressions()
        try await reviewCleanupReceiptRegressions()
    }

    private func reviewIgnoredDirectoryRegressions() {
        let state = AppState()
        let hidden = base.appendingPathComponent("review-filter/hidden.dat")
        let collapsed = Node(name: "unexpanded", url: base.appendingPathComponent("review-filter/deep"),
                             size: 8192, isGroup: true, captureIdentity: false)
        let package = Node(name: "package", url: base.appendingPathComponent("review-filter/Example.app"),
                           size: 16384, isGroup: true, captureIdentity: false)
        let hiddenNode = Node(name: "hidden", url: hidden, size: 4096, captureIdentity: false)
        let parent = Node(name: "parent", children: [collapsed, package, hiddenNode], isGroup: true)
        state.ignoredPaths = [hidden.path]
        let result = state.applyIgnoredPaths(to: [parent])
        check(result.count == 1 && result[0].children.map(\.id) == [collapsed.id, package.id],
              "Review 3: ignoring a sibling preserves unexpanded real directories and packages")
        check(result[0].totalSize == collapsed.totalSize + package.totalSize,
              "Review 3: filtered ancestor retains the exact visible directory bytes")
        let emptyDisplay = Node(name: "display-only", children: [hiddenNode], isGroup: true)
        check(state.applyIgnoredPaths(to: [emptyDisplay]).isEmpty,
              "Review 3: a display group whose children are all ignored is removed")
        state.ignoredPaths.insert(collapsed.path)
        check(state.applyIgnoredPaths(to: [collapsed]).isEmpty,
              "Review 3: an explicitly ignored unexpanded directory is still removed")
    }

    private func reviewMemoryRegressions() {
        let output = """
        Pages active: 100.
        Pages wired down: 50.
        Pages occupied by compressor: 25.
        """
        let total: Int64 = 4 * 1024 * 1024
        let smallPages = PerformanceEngine.memoryInfo(vmStatOutput: output, total: total, pageSize: 4096)
        let largePages = PerformanceEngine.memoryInfo(vmStatOutput: output, total: total, pageSize: 16384)
        check(smallPages.used == 175 * 4096 && largePages.used == 175 * 16384,
              "Review 6: production memory parser respects both 4 KB and 16 KB page sizes")
        let warning = PerformanceEngine.memoryInfo(vmStatOutput: output, total: 3500000, pageSize: 16384)
        let critical = PerformanceEngine.memoryInfo(vmStatOutput: output, total: 2900000, pageSize: 16384)
        check(largePages.pressure == .normal && warning.pressure == .warning && critical.pressure == .critical,
              "Review 6: page conversion feeds the normal, warning and critical classifications")
        let zeroTotal = PerformanceEngine.memoryInfo(vmStatOutput: "", total: 0, pageSize: 16384)
        check(zeroTotal.used == 0 && zeroTotal.pressure == .normal,
              "Review 6: unavailable memory statistics do not divide by zero")
        let native = PerformanceEngine.memoryInfo()
        check(native.total == Int64(ProcessInfo.processInfo.physicalMemory) && native.used >= 0 && native.used <= native.total,
              "Review 6: native memory sampling returns bounded real-machine usage")

        let previousLanguage = L10n.shared.currentLanguage
        defer { L10n.shared.setLanguage(previousLanguage) }
        for language in AppLanguage.concreteLanguages {
            L10n.shared.setLanguage(language)
            check(PerformanceModule.memoryCleanupTile(pressure: largePages.pressure) == nil,
                  "Review 7: normal memory does not suggest cleanup in " + language.rawValue)
            let tile = PerformanceModule.memoryCleanupTile(pressure: warning.pressure)
            check(tile?.title == L10n.localized(.actionFreeUpRamMemory)
                  && tile?.category == L10n.localized(.maintenanceTasks)
                  && PerformanceModule.memoryCleanupTile(pressure: critical.pressure) != nil,
                  "Review 7: elevated memory produces a localized maintenance tile in " + language.rawValue)
        }
    }

    private func reviewCleanupReceiptRegressions() async throws {
        let published = URL(fileURLWithPath: ProcessInfo.processInfo.environment["ACLEAN_RULES_DB"]!)
        let db = base.appendingPathComponent("review-receipts.db")
        try fm.copyItem(at: published, to: db)
        let home = base.appendingPathComponent("review-home").path.replacingOccurrences(of: "'", with: "''")
        try sql("UPDATE cm_discovery_binding SET path_template=replace(path_template,'~/','\(home)/'); UPDATE cm_protected_path SET path_template=replace(path_template,'~/','\(home)/'); DELETE FROM cm_junk_rule_lock; DELETE FROM cm_cache_profile_lock;", db: db)
        let previousDryRun = Cleaner.isDryRun
        let previousHook = Cleaner.onTrashHook
        let previousOpenPaths = OpenFileGuard.openPathsOverrideForTesting
        let previousBundles = ProcessGuard.runningBundleIDsOverrideForTesting
        let previousProcesses = ProcessGuard.runningProcessNamesOverrideForTesting
        defer {
            Cleaner.isDryRun = previousDryRun
            Cleaner.onTrashHook = previousHook
            OpenFileGuard.openPathsOverrideForTesting = previousOpenPaths
            ProcessGuard.runningBundleIDsOverrideForTesting = previousBundles
            ProcessGuard.runningProcessNamesOverrideForTesting = previousProcesses
            try? KnowledgeBaseManager.shared.load(from: published)
        }
        try KnowledgeBaseManager.shared.load(from: db)
        Cleaner.isDryRun = false
        OpenFileGuard.openPathsOverrideForTesting = []
        ProcessGuard.runningBundleIDsOverrideForTesting = []
        ProcessGuard.runningProcessNamesOverrideForTesting = []
        let first = try file("review-home/Library/Caches/JetBrains/Rider2024.2/caches/a.dat", data: Data(repeating: 1, count: 4096))
        let second = try file("review-home/Library/Caches/JetBrains/Rider2024.2/caches/b.dat", data: Data(repeating: 2, count: 4096))
        let item = JunkRulePolicy.apply(ScanItem(url: first.deletingLastPathComponent(), name: "caches", size: 8192))
        check(item.locked != true && item.children.count == 2,
              "Review 4: fixture passes the real rule evaluator and captures two children")
        let node = Node.item(from: item)
        let target = CleanTarget.emptyContainer(from: node)
        let firstBytes = target.containerChildren.first { $0.url == first }!.size
        let sink = base.appendingPathComponent("review-sink")
        try fm.createDirectory(at: sink, withIntermediateDirectories: true)
        let entered = StopFlag(), release = DispatchSemaphore(value: 0)
        defer { release.signal() }
        Cleaner.onTrashHook = { source in
            let destination = sink.appendingPathComponent(source.lastPathComponent)
            try FileManager.default.moveItem(at: source, to: destination)
            entered.value = true
            _ = release.wait(timeout: .now() + 5)
            return destination
        }
        let state = AppState()
        state.open(.restore(.junk))
        state.roots = [node]
        state.cleanTargets([target], module: "review-cancel", moduleKey: "junk")
        try await waitForReviewState { entered.value }
        state.stopClean()
        release.signal()
        try await waitForReviewState { state.activeCleanupRun == nil }
        let report = state.report!
        check(report.state == .cancelled && report.movedToTrashBytes == firstBytes && report.processedBytes == firstBytes,
              "Review 4: cancellation preserves exactly the successfully moved bytes")
        check(report.outcomes[0].removedSourcePaths == [first.path]
              && report.outcomes[0].trashedURLs == [sink.appendingPathComponent(first.lastPathComponent)],
              "Review 4: cancellation records both original and recovery paths: sources=\(report.outcomes[0].removedSourcePaths), expected=\(first.path), destinations=\(report.outcomes[0].trashedURLs), expected destination=\(sink.appendingPathComponent(first.lastPathComponent))")
        check(!fm.fileExists(atPath: first.path) && fm.fileExists(atPath: second.path),
              "Review 4: only the completed child was physically moved into the isolated sink")
        check(state.roots.allLeaves.map(\.path) == [second.path] && state.roots[0].totalSize == target.size - firstBytes,
              "Review 4: completion removes the moved child and recalculates remaining UI bytes")
        let neverMoved = CleanOutcome(name: "not-started", path: second.path, size: 8192,
                                      ok: false, actionCategory: .cancelled)
        let neverMovedReport = CleanReport(module: "review", outcomes: [neverMoved])
        check(neverMovedReport.movedToTrashBytes == 0 && neverMovedReport.processedBytes == 0,
              "Review 4: cancellation before a side effect never counts the planned bytes")

        let uiFile = try file("review-ui.dat")
        let uiNode = Node(name: "review-ui", url: uiFile, size: FileUtil.size(of: uiFile))
        let ready = StopFlag(), finish = DispatchSemaphore(value: 0)
        defer { finish.signal() }
        Cleaner.onTrashHook = { source in
            let destination = sink.appendingPathComponent(source.lastPathComponent)
            try FileManager.default.moveItem(at: source, to: destination)
            ready.value = true
            _ = finish.wait(timeout: .now() + 5)
            return destination
        }
        let existingReport = CleanReport(module: "space-existing", outcomes: [])
        let spaceNode = Node(name: "space-kept", url: second, size: 4096)
        state.write(.spaceLens) { session in
            session.report = existingReport
            session.roots = [spaceNode]
            session.selection = [spaceNode.id]
            session.screen = .complete
        }
        state.roots = [uiNode]
        state.cleanTargets([CleanTarget(uiNode)], module: "junk-background", moduleKey: "junk")
        try await waitForReviewState { ready.value }
        state.open(.restore(.spaceLens))
        finish.signal()
        try await waitForReviewState { state.activeCleanupRun == nil }
        check(state.moduleKey == .spaceLens && state.report?.id == existingReport.id
              && state.roots.map(\.id) == [spaceNode.id] && state.selection == [spaceNode.id],
              "Review 5: background completion preserves the active page report, results and selection")
        check(state.session(for: .junk).report?.module == "junk-background" && state.session(for: .junk).roots.isEmpty,
              "Review 5: background receipt and removed files settle into the originating session")
        state.open(.restore(.applications))
        state.open(.restore(.spaceLens))
        check(state.report?.id == existingReport.id,
              "Review 5: switching pages again cannot persist a foreign cleanup receipt")
        state.open(.restore(.junk))
        check(state.report?.module == "junk-background" && state.screen == .complete,
              "Review 5: returning to the source page restores its own completed receipt")
    }

    private func waitForReviewState(_ condition: () -> Bool) async throws {
        for _ in 0..<500 {
            if condition() { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        check(condition(), "Review state transition finishes within five seconds")
    }
}
