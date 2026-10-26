import Foundation
import AppKit
import Darwin

// ============================================================
//  CleanCoordinator —— 清理执行与进度调度状态机
//
//  核心职责：
//    1. 单例互斥与会话生命周期管理：全局杜绝并发清理冲突 (F3)；
//    2. 优雅停机守护：对运行中的目标 App 发送标准 terminate 并设置安全超时 (P0-05)；
//    3. 拓扑排序与依赖门禁：严格执行 UninstallBatchPolicy 依赖顺序；
//    4. 高性能 UI 节流投射：遵循 AppConfig.Security.progressInterval (0.08s)
//       节流，坚决杜绝海量小文件高频刷新引发的 UI 卡顿与掉帧；
//    5. 真实物理容量审计：观测 DiskInfo 卷差，生成不可变 CleanReport。
// ============================================================

@MainActor
final class CleanCoordinator: ObservableObject {

    static let shared = CleanCoordinator()

    @Published private(set) var activeRun: ActiveCleanupRun? = nil
    @Published private(set) var cleanProgress: Double = 0
    @Published private(set) var cleanCurrent: String = ""
    @Published private(set) var cleanDone: Int = 0
    @Published private(set) var cleanTotal: Int = 0
    @Published private(set) var latestReport: CleanReport? = nil
    /// 当前清理是否处于暂停态（供界面显示「已暂停」与切换按钮文案）
    @Published private(set) var isPaused: Bool = false

    private init() {}

    /// 执行结果回执包
    struct ExecutionResult: Sendable {
        let runID: UUID
        let report: CleanReport
        let gonePaths: Set<String>
        let isOptimized: Bool
        let isInterrupted: Bool
    }

    /// 启动批量清理流水线
    /// - Parameters:
    ///   - targets: 待清理目标清单 (已通过前置业务裁决)
    ///   - moduleKey: 来源模块键
    ///   - moduleTitle: 模块显示标题
    ///   - onProgress: 节流进度回调 (运行在 @MainActor)
    ///   - onComplete: 完成回调 (运行在 @MainActor)
    /// - Returns: 是否成功启动 (若当前已有清理在运行则返回 false)
    @discardableResult
    func startCleanup(
        targets: [CleanTarget],
        moduleKey: String,
        moduleTitle: String,
        onProgress: (@MainActor (Int, Int, String, Double) -> Void)? = nil,
        onComplete: @escaping @MainActor (ExecutionResult) -> Void
    ) -> Bool {
        guard !targets.isEmpty else { return false }
        guard activeRun == nil else { return false }

        let ruleTaskLease = RuleTaskGate.shared.begin()
        let run = ActiveCleanupRun(moduleKey: moduleKey, moduleTitle: moduleTitle)
        self.activeRun = run
        self.cleanProgress = 0
        self.cleanTotal = targets.count
        self.cleanDone = 0
        self.cleanCurrent = ""
        self.isPaused = false

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = Self.executePipeline(targets: targets, run: run) { done, total, current, progress in
                Task { @MainActor [weak self] in
                    guard let self, self.activeRun?.runID == run.runID else { return }
                    self.cleanDone = done
                    self.cleanTotal = total
                    self.cleanCurrent = current
                    self.cleanProgress = progress
                    onProgress?(done, total, current, progress)
                }
            }

            Task { @MainActor [weak self] in
                defer { withExtendedLifetime(ruleTaskLease) {} }
                guard let self, self.activeRun?.runID == run.runID else { return }
                self.activeRun = nil
                self.isPaused = false
                self.cleanProgress = 1.0
                self.cleanDone = result.report.outcomes.count
                self.latestReport = result.report
                onComplete(result)
            }
        }

        return true
    }

    /// 取消当前正在执行的清理
    func cancelCleanup() {
        activeRun?.stopFlag.value = true
        // 停止优先于暂停：立刻解除暂停态，否则后台线程会一直停在闸门上
        activeRun?.resume()
        isPaused = false
    }

    /// 暂停清理。当前目标会处理完，停在下一个目标之前——
    /// 不在目标内部挂起，避免文件停在半完成状态。
    func pauseCleanup() {
        guard let run = activeRun, !run.stopFlag.value, !isPaused else { return }
        run.pause()
        isPaused = true
    }

    /// 继续清理
    func resumeCleanup() {
        guard let run = activeRun, isPaused else { return }
        run.resume()
        isPaused = false
    }

    // MARK: - 后台清理核心流水线 (Non-isolated，纯后台运行，杜绝主线程卡顿)

    private nonisolated static func executePipeline(
        targets: [CleanTarget],
        run: ActiveCleanupRun,
        progressThrottle: @escaping (Int, Int, String, Double) -> Void
    ) -> ExecutionResult {
        // 1. 运行态应用优雅停机检查 (P0-05)
        let appBundlePaths = Set(targets.compactMap { t -> String? in
            guard let u = t.url, u.pathExtension.lowercased() == "app" else { return nil }
            return u.standardizedFileURL.path
        })
        var unclosedAppPaths = Set<String>()
        var unclosedBundleIDs = Set<String>()
        if !appBundlePaths.isEmpty && !run.stopFlag.value {
            let runningMatches = NSWorkspace.shared.runningApplications.filter { r in
                guard let bu = r.bundleURL?.standardizedFileURL.path else { return false }
                return appBundlePaths.contains(bu)
            }
            if !runningMatches.isEmpty {
                for app in runningMatches { _ = app.terminate() }
                var waited = 0.0
                while !run.stopFlag.value && waited < AppConfig.Security.appTerminationTimeout && runningMatches.contains(where: { !$0.isTerminated }) {
                    Thread.sleep(forTimeInterval: AppConfig.Security.appTerminationPollInterval)
                    waited += AppConfig.Security.appTerminationPollInterval
                }
                for app in runningMatches where !app.isTerminated {
                    if let bu = app.bundleURL?.standardizedFileURL.path {
                        unclosedAppPaths.insert(bu)
                    }
                    if let bid = app.bundleIdentifier {
                        unclosedBundleIDs.insert(bid)
                    }
                }
            }
        }

        // 2. 卷差物理容量测算前置
        let hasHostReclaimTargets = !Cleaner.isDryRun && targets.contains { t in
            switch t.action {
            case .permanentlyDeleteTrashItem, .simctlRuntimeDelete, .simctlDeleteUnavailable, .apfsPurge, .thinBinary, .custom:
                return true
            case .trash, .emptyContainer, .dockerPrune:
                return false
            }
        }
        let rawFreeBefore: Int64? = hasHostReclaimTargets ? DiskInfo.current().rawFree : nil

        // 3. 执行核心循环
        let orderedTargets = UninstallBatchPolicy.ordered(targets)
        let context = IOScanContext(stopped: { run.stopFlag.value })
        let outcomes: [CleanOutcome] = context.perform {
            var outcomes: [CleanOutcome] = []
            var lastPublish: TimeInterval = 0
            let targetPaths = targets.compactMap { $0.url?.standardizedFileURL.path }
            let declaredOwners = UninstallBatchPolicy.bodyOwners(targets)
            var succeededBodies = Set<String>()
            let bodyCounts = Dictionary(grouping: targets.filter(UninstallBatchPolicy.isBody).flatMap { $0.ownerBundleIDs.map { $0.lowercased() } }, by: { $0 }).mapValues { $0.count }
            var successes: [String: Int] = [:]

            for (i, t) in orderedTargets.enumerated() {
                let now = ProcessInfo.processInfo.systemUptime
                if now - lastPublish >= AppConfig.Security.progressInterval {
                    lastPublish = now
                    let progress = Double(i) / Double(max(1, targets.count))
                    progressThrottle(i, targets.count, t.name, progress)
                }

                if let evidence = t.duplicateEvidence,
                   targetPaths.contains(where: { evidence.keeper.path == $0 || evidence.keeper.path.hasPrefix($0 + "/") }) {
                    outcomes.append(CleanOutcome(name: t.name, path: t.url?.path ?? "", size: t.size, ok: false,
                                                error: L10n.localized(.cleanupDuplicateUnavailable), actionCategory: .skipped))
                    continue
                }

                // 暂停闸门：只在两个目标之间等待，不打断当前目标的原子操作。
                // 放在停止检查之前——等待结束后若用户已点停止，下面的检查会立刻接管。
                run.waitWhilePausedIfNeeded()

                if run.stopFlag.value {
                    outcomes.append(CleanOutcome(name: t.name, path: t.url?.path ?? "",
                                                 size: t.size, ok: false,
                                                 error: L10n.localized(.cleanupCancelledResult),
                                                 actionCategory: .cancelled))
                    continue
                }

                if let u = t.url {
                    let std = u.standardizedFileURL.path
                    let matchesUnclosedPath = unclosedAppPaths.contains(where: { std == $0 || std.hasPrefix($0 + "/") })
                    let matchesOwnerBundleID = !unclosedBundleIDs.isEmpty && t.ownerBundleIDs.contains(where: { unclosedBundleIDs.contains($0) })
                    let runningCheck = ProcessGuard.shouldSkipDueToRunningProcess(path: std)

                    let ownerRunning = t.ownerBundleIDs.contains { ProcessGuard.isAppRunning(bundleID: $0) }
                    if matchesUnclosedPath || matchesOwnerBundleID || ownerRunning || runningCheck.skip {
                        let reason = runningCheck.reason ?? L10n.localized(.statusAppRunningSkipped)
                        outcomes.append(CleanOutcome(
                            name: t.name,
                            path: std,
                            size: t.size,
                            ok: false,
                            error: reason,
                            actionCategory: .skipped
                        ))
                        continue
                    }
                }

                if UninstallBatchPolicy.needsBodySuccess(t, declared: declaredOwners, succeeded: succeededBodies) {
                    outcomes.append(CleanOutcome(name: t.name, path: t.url?.path ?? "", size: t.size, ok: false,
                                                error: L10n.localized(.cleanupUninstallBlocked), actionCategory: .skipped))
                    continue
                }

                let outcome = Cleaner.clean(t)
                outcomes.append(outcome)
                if UninstallBatchPolicy.isBody(t), outcome.ok {
                    for bid in t.ownerBundleIDs.map({ $0.lowercased() }) {
                        successes[bid, default: 0] += 1
                        if successes[bid] == bodyCounts[bid] { succeededBodies.insert(bid) }
                    }
                }
            }

            return outcomes
        }

        // 4. 计算容量回收与审计报告
        let observedVolumeDelta: Int64? = {
            guard let before = rawFreeBefore, before > 0 else { return nil }
            let hadReclaimExecution = outcomes.contains { o in
                (o.ok || o.actionCategory == .partialFailure)
                    && (o.actionCategory == .permanentlyDeleted || o.actionCategory == .systemReclaimed)
            }
            guard hadReclaimExecution else { return nil }
            let after = DiskInfo.current().rawFree
            return max(0, after - before)
        }()

        var rep = CleanReport(module: run.moduleTitle, outcomes: outcomes, started: run.startTime)
        rep.observedVolumeDelta = observedVolumeDelta

        // 5. 若包含应用卸载批次，向 UninstallerUndoManager 登记撤销快照记录
        if !Cleaner.isDryRun {
            var grouped: [String: (appName: String, items: [UninstallUndoItem])] = [:]
            for (idx, target) in orderedTargets.enumerated() {
                guard idx < outcomes.count else { break }
                let outcome = outcomes[idx]
                guard outcome.ok,
                      outcome.actionCategory == CleanActionCategory.movedToTrash,
                      let destURL = outcome.destinationURL,
                      let ctx = target.uninstallContext else { continue }

                let item = UninstallUndoItem(
                    originalPath: outcome.path,
                    trashPath: destURL.path,
                    size: outcome.size,
                    isAppBody: ctx.isAppBody
                )
                let rawKey = ctx.bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
                let key = rawKey.isEmpty ? ctx.appURL.deletingPathExtension().lastPathComponent.lowercased() : rawKey.lowercased()
                let currentName = grouped[key]?.appName ?? (ctx.isAppBody ? target.name : ctx.appURL.deletingPathExtension().lastPathComponent)
                var currentItems = grouped[key]?.items ?? []
                currentItems.append(item)
                grouped[key] = (currentName, currentItems)
            }
            for (bundleID, info) in grouped {
                let persisted = UninstallerUndoManager.shared.recordBatch(
                    appName: info.appName,
                    bundleID: bundleID,
                    items: info.items
                )
                if !persisted {
                    // Keep the in-memory restore mapping in the report; surface durability failure.
                    rep.restorePersistenceFailed = true
                }
            }
        }

        let gone = Set(outcomes.flatMap { outcome in
            Array(outcome.removedSourcePaths) + ((outcome.ok || outcome.actionCategory == .absent) ? [outcome.path] : [])
        })
        let isOptimized = rep.okCount > 0 || outcomes.contains { !$0.removedSourcePaths.isEmpty }
        let isInterrupted = run.stopFlag.value

        return ExecutionResult(
            runID: run.runID,
            report: rep,
            gonePaths: gone,
            isOptimized: isOptimized,
            isInterrupted: isInterrupted
        )
    }
}
