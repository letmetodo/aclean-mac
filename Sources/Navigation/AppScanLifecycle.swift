import Foundation
import SwiftUI
import AppKit

@MainActor
extension AppState {
    // ============================================================
    // MARK: 扫描（支持多模块后台并行扫描）
    // ============================================================

    func startScan(for targetKey: String? = nil, forceRestart: Bool = false) {
        let key = targetKey ?? moduleKey.rawValue
        guard !isModuleCleaning(key) else {
            toast = L10n.localized(.toastCleanupAlreadyRunning)
            return
        }
        if key == "smartCare" {
            scanAllSmartCards()
            return
        }

        // 仅阻止同一模块重复并发扫描；如请求 forceRestart 则先向旧任务发出取消信号再重新开始
        if isScanning(module: key) {
            if forceRestart {
                if let modKey = ModuleKey.parse(key) {
                    session(for: modKey).stopFlag.value = true
                }
                if key == moduleKey {
                    stopFlag.value = true
                }
            } else {
                return
            }
        }

        let sp = ModuleRegistry.spec(for: key)
        let moduleKind = sp.kind, moduleTitle = sp.title
        let builder = scanBuilder?(key) ?? sp.buildTree
        let modKey = ModuleKey.parse(key) ?? .junk
        let flag = StopFlag()
        var gen = 0
        write(modKey) { sess in
            sess.stopFlag = flag
            sess.scanGeneration += 1
            gen = sess.scanGeneration
            sess.scanning = true
            sess.isStoppingScan = false
            sess.scanIssues = []
            sess.scanDegradations = []
            sess.completedSuccessfully = false
            sess.hasScanned = true
            sess.didApplyDefaults = false
            sess.screen = .scanning
            sess.scanProgress = 0
            sess.scanStatus = sp.scanDetail.isEmpty ? sp.scanSubtitle : sp.scanDetail
            sess.scanETA = nil
            sess.scanPaths = []
            sess.roots = []
            sess.selection = []
            sess.expanded = []
            sess.focusGroup = nil
            sess.category = ""
            sess.search = ""
            sess.report = nil
            if modKey == .spaceLens {
                sess.spaceNavPaths = []
                sess.spaceFocusedId = nil
            }
            if modKey == .organize {
                sess.scannedLargeFileThresholdMB = AppConfigStore.shared.largeFileThresholdMB
                sess.scannedOldFileMonths = AppConfigStore.shared.oldFileMonths
            }
        }
        activeScanningModules.insert(key)

        if moduleKey == key {
            stopFlag.value = false
        }

        let ruleTaskLease = RuleTaskGate.shared.begin()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let context = IOScanContext(stopped: { flag.value })
            let progressState = LockedValue((time: CFAbsoluteTime(0), value: -1.0))
            let scanStart = CFAbsoluteTimeGetCurrent()
            let tree = autoreleasepool { context.perform { builder({ [weak self] (p: Double, s: String) in
                let accepted = progressState.withValue { previous -> Bool in
                    let now = CFAbsoluteTimeGetCurrent()
                    if p < 1 && now - previous.time < AppConfig.Security.progressInterval && abs(p - previous.value) < 0.02 { return false }
                    previous = (now, p); return true
                }
                guard accepted else { return }
                DispatchQueue.main.async { [weak self] in
                    guard let self, !flag.value else { return }
                    self.write(modKey) { cur in
                        guard cur.scanGeneration == gen else { return }
                        cur.scanProgress = p
                        cur.scanStatus = s
                        cur.scanETA = Self.estimateETA(progress: p,
                                                       elapsed: CFAbsoluteTimeGetCurrent() - scanStart)
                        if !s.isEmpty {
                            cur.scanPaths.append(s)
                            if cur.scanPaths.count > 4 { cur.scanPaths.removeFirst() }
                        }
                    }
                }
            }, { [weak self] (incrementalNodes: [Node]) in
                DispatchQueue.main.async { [weak self] in
                    guard let self, !flag.value else { return }
                    let incomingIDs = Set(incrementalNodes.map(\.id))
                    let filtered = self.applyIgnoredPaths(
                        to: incrementalNodes.filter { $0.totalSize > 0 || $0.leafCount > 0 })
                    let survivingIDs = Set(filtered.map(\.id))
                    let removedIDs = incomingIDs.subtracting(survivingIDs)
                    guard !filtered.isEmpty || !removedIDs.isEmpty else { return }

                    self.write(modKey) { cur in
                        guard cur.scanGeneration == gen else { return }
                        if modKey == .spaceLens {
                            // 空间透视：流式实时替换整棵目录树快照（确定性 UUID 保持焦点与勾选不丢失）
                            cur.roots = filtered
                        } else {
                            if !removedIDs.isEmpty {
                                cur.roots.removeAll { removedIDs.contains($0.id) }
                            }
                            for node in filtered {
                                if let idx = cur.roots.firstIndex(where: { $0.id == node.id }) {
                                    cur.roots[idx] = node
                                } else {
                                    cur.roots.append(node)
                                }
                            }
                        }
                    }
                }
            }, {
                flag.value
            }) } }

            let nonEmptyTree = tree.filter { $0.totalSize > 0 || $0.leafCount > 0 }
            let bgJunkSnapshot: SmartCleanSnapshotCache.Snapshot? = (modKey == .junk) ? {
                let snap = SmartCleanSnapshotCache.computeSnapshot(roots: nonEmptyTree)
                SmartAppGroupBuilder.prewarmSections(snap.sections)
                return snap
            }() : nil

            DispatchQueue.main.async { [self] in
                defer { withExtendedLifetime(ruleTaskLease) {} }
                guard let self else { return }
                guard self.session(for: modKey).scanGeneration == gen else { return }
                self.activeScanningModules.remove(key)
                let wasStopped = flag.value
                var issues = context.issues
                var degradations = context.degradations
                if key == "junk" && !KnowledgeBaseManager.shared.authored.loaded {
                    if !degradations.contains(.ruleDatabaseUnavailable) {
                        degradations.append(.ruleDatabaseUnavailable)
                    }
                    let msg = L10n.localized(.ruleDatabaseUnavailableBanner)
                    if !issues.contains(msg) {
                        issues.append(msg)
                    }
                }
                let finalRoots = self.applyIgnoredPaths(to: nonEmptyTree)
                if let bgSnap = bgJunkSnapshot,
                   bgSnap.signature == SmartCleanSnapshotCache.signature(for: finalRoots) {
                    SmartCleanSnapshotCache.shared.storePrecomputedSnapshot(bgSnap)
                }

                var scanCompleted = false
                var scanStatusText = ""
                var totalItemCount = 0
                var totalByteSize: Int64 = 0

                self.write(modKey) { cur in
                    guard cur.scanGeneration == gen else { return }
                    cur.scanIssues = issues
                    cur.scanDegradations = degradations
                    cur.evaluationReasonCounts = context.evaluationReasonCounts
                    cur.deduplicationRecords = context.deduplicationRecords
                    cur.completedSuccessfully = !wasStopped && cur.scanIssues.isEmpty && cur.scanDegradations.isEmpty
                    if !wasStopped || !finalRoots.isEmpty || cur.roots.isEmpty {
                        cur.roots = finalRoots
                    }
                    cur.scanning = false
                    cur.isStoppingScan = false
                    cur.scanProgress = wasStopped ? cur.scanProgress : 1
                    if wasStopped {
                        cur.scanStatus = L10n.localized(.statusScanStoppedPartialResults)
                    } else if cur.scanDegradations.contains(.ruleDatabaseUnavailable) {
                        cur.scanStatus = L10n.localized(.ruleDatabaseUnavailableTitle)
                    } else if cur.scanIssues.isEmpty && cur.scanDegradations.isEmpty {
                        cur.scanStatus = L10n.localized(.statusCompleted)
                    } else {
                        cur.scanStatus = L10n.localized(.safetyInspectionIncomplete)
                    }
                    cur.hasScanned = true

                    if moduleKind == .performance {
                        cur.sortKey = .name
                        cur.sortAscending = true
                        cur.strategy = .none
                        cur.selection = []
                    } else if moduleKind == .applications {
                        cur.sortKey = .size
                        cur.sortAscending = false
                        cur.strategy = .none
                        cur.selection = []
                    } else if moduleKind == .spaceLens {
                        cur.sortKey = .size
                        cur.sortAscending = false
                        cur.strategy = .none
                    } else {
                        cur.sortKey = .size
                        cur.sortAscending = false
                        cur.strategy = .smart
                        var sel = Set<UUID>()
                        for l in cur.roots.allLeaves where CleanupSelectionPolicy.isRecommended(l) {
                            if l.badge == "Latest" || l.badge == L10n.localized(.statusLatest) { continue }
                            sel.insert(l.id)
                        }
                        cur.selection = sel
                    }
                    cur.didApplyDefaults = true

                    if ModuleKey.sidebar.contains(modKey) || moduleKind == .applications || self.debugStage == "dataManager" {
                        cur.screen = .dataManager
                    } else {
                        cur.screen = .results
                    }

                    scanCompleted = cur.completedSuccessfully
                    scanStatusText = cur.scanStatus
                    totalItemCount = cur.roots.reduce(0) { $0 + $1.leafCount }
                    totalByteSize = cur.roots.reduce(Int64(0)) { $0 + $1.totalSize }
                }

                if self.moduleKey == key {
                    if !self.pendingCategory.isEmpty {
                        self.category = self.pendingCategory
                        self.pendingCategory = ""
                    } else if self.category.isEmpty || !self.categories.contains(where: { $0.title == self.category }) {
                        self.category = self.categories.first?.title ?? ""
                    }
                    self.focusGroup = self.visibleRoots.first?.id
                    if wasStopped {
                        self.toast = L10n.localized(.toastScanStopped)
                    }
                }

                self.log.append(LogEntry(title: "\(moduleTitle) \(scanCompleted ? L10n.localized(.statusScanCompleted) : scanStatusText)",
                                         detail: "\(totalItemCount) \(L10n.localized(.unitItems)) · \(Fmt.size(totalByteSize))",
                                         ok: scanCompleted))
                guard !wasStopped else { return }
                AppConfigStore.shared.playCompletionSoundIfEnabled()
                if scanCompleted {
                    CompletionNotifier.scanFinished(
                        moduleTitle: moduleTitle,
                        itemCount: totalItemCount,
                        bytes: totalByteSize
                    )
                }
            }
        }
    }

    func stopScan(for targetKey: String? = nil) {
        let key = targetKey ?? moduleKey.rawValue
        if key == "smartCare" {
            smartScanGeneration += 1
            for flag in smartScanFlags.values { flag.value = true }
            smartScanFlags.removeAll()
            smartQueue.removeAll()
            for card in smartCards.keys where smartCards[card]?.scanning == true {
                smartCards[card]?.scanning = false
                smartCards[card]?.done = false
            }
        }
        let hasActiveBackgroundTask = activeScanningModules.contains(key)
        if let modKey = ModuleKey.parse(key) {
            write(modKey) { sess in
                sess.stopFlag.value = true
                sess.completedSuccessfully = false
                if hasActiveBackgroundTask {
                    // 等待后台扫描闭包真正退出并在主线程收敛时再置 scanning = false
                    sess.isStoppingScan = true
                    sess.scanStatus = L10n.localized(.statusStopping)
                } else {
                    sess.scanning = false
                    sess.isStoppingScan = false
                    sess.scanStatus = L10n.localized(.statusScanStoppedPartialResults)
                    sess.screen = ModuleKey.sidebar.contains(modKey) ? .dataManager : .results
                }
            }
        }

        if key == moduleKey {
            stopFlag.value = true
            if key == ModuleKey.smartCare.rawValue { smartQueue.removeAll() }
            for k in smartCards.keys where key == ModuleKey.smartCare.rawValue {
                if var st = smartCards[k], st.scanning {
                    st.scanning = false
                    smartCards[k] = st
                }
            }
            if hasActiveBackgroundTask {
                isStoppingScan = true
                scanStatus = L10n.localized(.statusStopping)
            } else {
                scanning = false
                isStoppingScan = false
                if spec.kind == .performance {
                    sortKey = .name
                    sortAscending = true
                    applyStrategy(.none, scopedToCategory: false)
                } else if spec.kind == .applications {
                    sortKey = .size
                    sortAscending = false
                    applyStrategy(.none, scopedToCategory: false)
                } else if spec.kind == .spaceLens {
                    sortKey = .size
                    sortAscending = false
                } else {
                    sortKey = .size
                    sortAscending = false
                    applyStrategy(.smart, scopedToCategory: false)
                }
                if !categories.isEmpty {
                    category = categories.first?.title ?? ""
                }
                focusGroup = visibleRoots.first?.id
                scanStatus = L10n.localized(.statusScanStoppedPartialResults)
                screen = ModuleKey.sidebar.contains(moduleKey) ? .dataManager : .results
                toast = L10n.localized(.toastScanStopped)
            }
        }
    }

    // ============================================================
    // MARK: 清理
    // ============================================================

    func goReview() {
        guard selectedCount > 0 else {
            toast = L10n.localized(.toastNoItemsSelected)
            return
        }
        screen = .review
    }

    /// 判定节点是否属于手动管理只读专区（iOS 备份、本地大模型权重、虚拟机镜像、显式锁定项）
    func isManualStorageNode(_ n: Node) -> Bool {
        if n.locked { return true }
        let p = n.path.lowercased()
        let name = n.name.lowercased()
        let combined = "\(name) \(p)"
        return combined.contains("/mobilesync/backup")
            || combined.contains("/.ollama/models")
            || combined.contains("/lm-studio/models")
            || combined.contains("parallels")
            || combined.contains("vmware")
            || combined.contains("utm/machines")
    }

    func isSelectableForClean(_ n: Node) -> Bool {
        CleanupSelectionPolicy.isUserSelectable(n)
            && !isNodeIgnoredForDeletion(n)
            && !isStartupItem(n)
            && !isManualStorageNode(n)
    }

    func commitClean(category: String? = nil) {
        // 关键安全防线：
        // 1. 过滤已忽略节点 (白名单双向保护，防止删除包含忽略子项的父目录) (F6)
        // 2. 开机启动项和后台服务严禁被删除，只能启动和关闭
        // 3. 手动管理只读专区节点（iOS 备份、本地大模型权重、虚拟机镜像等）严禁进入自动清理链路 (P0-07)
        var leaves = selectedLeaves.filter { isSelectableForClean($0) }
        if let cat = category, !Self.isAllCategory(cat) {
            leaves = leaves.filter { $0.tags.contains(cat) }
        }
        guard !leaves.isEmpty else {
            toast = L10n.localized(.toastNoItemsSelected)
            return
        }

        let targets = leaves.map { CleanTarget($0) }
        var trashTargets: [CleanTarget] = []
        var permanentTargets: [CleanTarget] = []
        var systemReclaimTargets: [CleanTarget] = []
        var customTargets: [CleanTarget] = []

        for t in targets {
            switch t.action {
            case .trash, .emptyContainer:
                trashTargets.append(t)
            case .permanentlyDeleteTrashItem:
                permanentTargets.append(t)
            case .dockerPrune, .simctlRuntimeDelete, .simctlDeleteUnavailable, .apfsPurge:
                systemReclaimTargets.append(t)
            case .custom, .thinBinary:
                customTargets.append(t)
            }
        }

        let permanentCount = permanentTargets.count
        let permanentBytes = permanentTargets.reduce(Int64(0)) { $0 + $1.size }
        let systemReclaimCount = systemReclaimTargets.count
        let systemReclaimBytes = systemReclaimTargets.reduce(Int64(0)) { $0 + $1.size }
        let trashCount = trashTargets.count
        let trashBytes = trashTargets.reduce(Int64(0)) { $0 + $1.size }

        let hasIrreversible = permanentCount > 0 || systemReclaimCount > 0
        let hasRisky = leaves.contains(where: { RiskControlMatrix.requiresConfirmation($0) })
        let userRequiresConfirm = AppConfigStore.shared.confirmBeforeDelete

        // F1/R9 强制确认防线：
        // 1. 凡包含不可恢复动作（永久删除或系统底层清理），一律强制弹窗核对并明确标示
        // 2. 凡命中风控高危类目，强制确认
        // 3. 用户开启「删除前确认」偏好设置，无论何种动作均弹出操作清单确认
        if hasIrreversible || hasRisky || userRequiresConfirm {
            var messages: [String] = []
            if permanentCount > 0 {
                messages.append(L10n.format(.dangerCleanPermanentNoticeFormat, permanentCount, Fmt.size(permanentBytes)))
            }
            if systemReclaimCount > 0 {
                messages.append(L10n.format(.dangerCleanSystemReclaimNoticeFormat, systemReclaimCount, Fmt.size(systemReclaimBytes)))
            }
            if customTargets.count > 0 {
                messages.append(L10n.format(.dangerCleanCustomMaintenanceNoticeFormat, customTargets.count))
            }
            if trashCount > 0 {
                messages.append(L10n.format(.dangerCleanTrashNoticeFormat, trashCount, Fmt.size(trashBytes)))
            }
            if let risky = leaves.first(where: { RiskControlMatrix.requiresConfirmation($0) }) {
                let cat = RiskControlMatrix.category(of: risky)
                messages.append(L10n.format(.dangerCleanRiskWarningFormat, cat.localizedTitle))
            }
            pendingCleanupModuleKey = moduleKey.rawValue
            let manualTargets = targets.map { t -> CleanTarget in
                var copy = t
                copy.executionMode = .manual
                return copy
            }
            dangerConfirm = DangerClean(
                message: messages.joined(separator: "\n\n"),
                targets: manualTargets,
                module: spec.title)
            return
        }
        let autoTargets = targets.map { t -> CleanTarget in
            var copy = t
            copy.executionMode = .automatic
            return copy
        }
        cleanTargets(autoTargets, module: spec.title)
    }

    func confirmDangerClean() {
        guard let d = dangerConfirm else { return }
        dangerConfirm = nil
        let origin = pendingCleanupModuleKey ?? moduleKey.rawValue
        pendingCleanupModuleKey = nil
        let manualTargets = d.targets.map { t -> CleanTarget in
            var copy = t
            copy.executionMode = .manual
            return copy
        }
        cleanTargets(manualTargets, module: d.module, moduleKey: origin)
    }

    func cleanTargets(_ targets: [CleanTarget], module name: String, moduleKey originKey: String? = nil) {
        guard !targets.isEmpty else { return }
        // 全局互斥运行锁：跨模块全应用单例互斥，坚决杜绝并发清理 (F3)
        guard activeCleanupRun == nil else {
            toast = L10n.localized(.toastCleanupAlreadyRunning)
            return
        }
        let targetModuleKey = originKey ?? moduleKey.rawValue
        guard !isScanning(module: targetModuleKey) else { return }

        lastCleanupTargets[targetModuleKey] = targets

        if targetModuleKey == moduleKey.rawValue { screen = .cleaning }
        if let modKey = ModuleKey.parse(targetModuleKey) {
            write(modKey) { session in
                session.screen = .cleaning
            }
        }
        cleanProgress = 0
        cleanTotal = targets.count
        cleanDone = 0
        cleanCurrent = ""
        cleanupPaused = false
        stopFlag.value = false

        let started = cleanCoordinator.startCleanup(
            targets: targets,
            moduleKey: targetModuleKey,
            moduleTitle: name,
            onProgress: { [weak self] done, total, current, progress in
                guard let self else { return }
                self.cleanDone = done
                self.cleanTotal = total
                self.cleanCurrent = current
                self.cleanProgress = progress
                // 暂停被自动解除（超时）后让界面状态跟上，避免一直停在「已暂停」
                if self.cleanupPaused && !self.cleanCoordinator.isPaused {
                    self.cleanupPaused = false
                }
            },
            onComplete: { [weak self] result in
                guard let self else { return }
                self.handleCleanupCompletion(result: result, targetModuleKey: targetModuleKey, name: name)
            }
        )

        guard started else {
            if let key = ModuleKey.parse(targetModuleKey) {
                write(key) { $0.screen = .results }
            }
            if targetModuleKey == moduleKey.rawValue { screen = .results }
            toast = L10n.localized(.toastCleanupAlreadyRunning)
            return
        }
        self.activeCleanupRun = cleanCoordinator.activeRun
    }

    private func handleCleanupCompletion(
        result: CleanCoordinator.ExecutionResult,
        targetModuleKey: String,
        name: String
    ) {
        guard self.activeCleanupRun?.runID == result.runID else { return }
        self.activeCleanupRun = nil

        let rep = result.report
        self.cleanProgress = 1
        self.cleanDone = rep.outcomes.count
        self.disk = DiskInfo.current()

        var receiptParts = [L10n.format(.cleanupOutcomeCountsFormat, rep.okCount, rep.errorCount, rep.skippedCount, rep.cancelledCount)]
        if rep.movedToTrashBytes > 0 { receiptParts.append(L10n.format(.receiptMovedToTrashTagFormat, Fmt.size(rep.movedToTrashBytes))) }
        if rep.permanentlyDeletedBytes > 0 { receiptParts.append(L10n.format(.receiptPermanentlyDeletedTagFormat, Fmt.size(rep.permanentlyDeletedBytes))) }
        if rep.reportedReclaimedBytes > 0 { receiptParts.append(L10n.format(.receiptToolReportedFormat, Fmt.size(rep.reportedReclaimedBytes))) }
        let resultTitle: String
        switch rep.state {
        case .success: resultTitle = L10n.localized(.statusCleanCompleted)
        case .partial: resultTitle = L10n.localized(.cleanupPartialResult)
        case .cancelled: resultTitle = L10n.localized(.cleanupCancelledResult)
        case .failed: resultTitle = L10n.localized(.statusFailed)
        }
        self.log.append(LogEntry(title: "\(name) \(resultTitle)",
                                 detail: receiptParts.joined(separator: " · "),
                                 ok: rep.state == .success))

        // 长任务回音：清理在后台跑完时给一条系统通知（窗口在前台时 CompletionNotifier 会自动跳过）
        if rep.state == .success || rep.state == .partial {
            let movedBytes = rep.movedToTrashBytes + rep.permanentlyDeletedBytes
            let reclaimed = movedBytes > 0 ? movedBytes : rep.reportedReclaimedBytes
            CompletionNotifier.cleanFinished(
                moduleTitle: name,
                bytes: reclaimed,
                failedCount: rep.errorCount
            )
            // 跨会话记账：只记聚合数字，用于「累计腾出多少」的自证
            CleanHistoryStore.shared.record(
                moduleTitle: name,
                itemCount: rep.okCount,
                bytes: reclaimed,
                failedCount: rep.errorCount
            )
        }

        let gone = result.gonePaths

        let isOptimized = result.isOptimized
        let shouldRemoveAfterClean: (Node) -> Bool = { node in
            if gone.contains(node.path) && (!node.isGroup || node.children.isEmpty || node.action == .emptyContainer) {
                return true
            }
            if let containerPath = node.ruleEvidence?.containerPath, gone.contains(containerPath) {
                return true
            }
            return false
        }

        if let modKey = ModuleKey.parse(targetModuleKey) {
            self.write(modKey) { sess in
                _ = sess.roots.removeNodesOrLeaves(where: shouldRemoveAfterClean)
                sess.selection.removeAll()
                sess.report = rep
                sess.hasScanned = true
                sess.hasOptimized = isOptimized
                sess.screen = .complete
            }
        }

        self.syncSmartCardsAfterClean(gone: gone)
        if rep.state == .cancelled {
            self.toast = L10n.localized(.cleanupCancelledResult)
        } else if rep.state == .partial {
            self.toast = L10n.localized(.cleanupPartialResult)
        } else if isOptimized {
            let freedSummary: String
            if rep.actualFreedBytes > 0 && rep.movedToTrashBytes > 0 {
                freedSummary = L10n.format(.receiptReclaimedAndTrashedFormat, Fmt.size(rep.actualFreedBytes), Fmt.size(rep.movedToTrashBytes))
            } else if rep.actualFreedBytes > 0 {
                freedSummary = L10n.format(.receiptDiskSpaceFreedFormat, Fmt.size(rep.actualFreedBytes))
            } else if rep.permanentlyDeletedBytes > 0 && rep.movedToTrashBytes > 0 {
                freedSummary = L10n.format(.receiptPermanentlyDeletedAndTrashedFormat, Fmt.size(rep.permanentlyDeletedBytes), Fmt.size(rep.movedToTrashBytes))
            } else if rep.permanentlyDeletedBytes > 0 {
                freedSummary = L10n.format(.receiptPermanentlyDeletedFormat, Fmt.size(rep.permanentlyDeletedBytes))
            } else if rep.reportedReclaimedBytes > 0 {
                freedSummary = L10n.format(.receiptToolReportedFormat, Fmt.size(rep.reportedReclaimedBytes))
            } else if rep.movedToTrashBytes > 0 {
                freedSummary = L10n.format(.receiptMovedToTrashFormat, Fmt.size(rep.movedToTrashBytes))
            } else {
                freedSummary = L10n.format(.cleanupOutcomeCountsFormat, rep.okCount, rep.errorCount, rep.skippedCount, rep.cancelledCount)
            }
            self.toast = "\(L10n.localized(.statusCleanCompleted)) · \(freedSummary)"
            AppConfigStore.shared.playCompletionSoundIfEnabled()
        } else if result.isInterrupted {
            self.toast = L10n.localized(.toastScanStopped)
        } else {
            self.toast = L10n.localized(.statusOperationCancelledOrFailed)
        }
    }

    nonisolated static func permissionRetryTargets(from plan: [CleanTarget], outcomes: [CleanOutcome]) -> [CleanTarget] {
        var permissionOutcomesByPath: [String: CleanOutcome] = [:]
        for outcome in outcomes where outcome.failureKind == .permission && !outcome.path.isEmpty {
            let stdPath = URL(fileURLWithPath: outcome.path).standardizedFileURL.path
            permissionOutcomesByPath[stdPath] = outcome
            permissionOutcomesByPath[outcome.path] = outcome
        }
        guard !permissionOutcomesByPath.isEmpty else { return [] }

        return plan.compactMap { (target: CleanTarget) -> CleanTarget? in
            guard let targetURL = target.url else { return nil }
            let rawPath = targetURL.path
            let stdPath = targetURL.standardizedFileURL.path
            guard let outcome = permissionOutcomesByPath[stdPath] ?? permissionOutcomesByPath[rawPath] else {
                return nil
            }
            var copy = target
            if copy.action == .emptyContainer {
                if let origIdentity = copy.expectedIdentity ?? copy.ruleEvidence?.containerIdentity,
                   let currentIdentity = FileIdentity.capture(from: targetURL),
                   origIdentity.device == currentIdentity.device,
                   origIdentity.inode == currentIdentity.inode,
                   origIdentity.isDirectory == currentIdentity.isDirectory,
                   origIdentity.uid == currentIdentity.uid,
                   origIdentity.mode == currentIdentity.mode {
                    copy.expectedIdentity = currentIdentity
                    if var ev = copy.ruleEvidence {
                        ev.containerIdentity = currentIdentity
                        copy.ruleEvidence = ev
                    }
                }
                let permFailedPaths = Set(
                    outcome.failedChildDetails
                        .filter { $0.failureKind == .permission }
                        .map { URL(fileURLWithPath: $0.path).standardizedFileURL.path }
                )
                let allFailedPaths = Set(
                    outcome.failedChildDetails
                        .map { URL(fileURLWithPath: $0.path).standardizedFileURL.path }
                )
                let chosenRetryPaths = !permFailedPaths.isEmpty ? permFailedPaths : allFailedPaths
                if !chosenRetryPaths.isEmpty {
                    copy.retryChildPaths = chosenRetryPaths
                    if !copy.containerChildren.isEmpty {
                        copy.containerChildren = copy.containerChildren.filter { child in
                            guard let cURL = child.url else { return false }
                            return chosenRetryPaths.contains(cURL.standardizedFileURL.path)
                        }
                    }
                }
            }
            return copy
        }
    }

    func requestCleanupPermissionRetry() {
        let key = moduleKey
        guard let receipt = session(for: key).report ?? report,
              let plan = lastCleanupTargets[key.rawValue], activeCleanupRun == nil else { return }
        let retry = Self.permissionRetryTargets(from: plan, outcomes: receipt.outcomes)
        guard !retry.isEmpty else { return }
        let failedPaths = retry.flatMap { target -> [String] in
            if let retryChildPaths = target.retryChildPaths, !retryChildPaths.isEmpty {
                return retryChildPaths.sorted()
            }
            return target.url.map { [$0.path] } ?? []
        }
        PermissionCoordinator.shared.requestAccess(context: .cleanup(failedCount: retry.count), failedPaths: failedPaths) { [weak self] in
            guard let self, self.activeCleanupRun == nil,
                  self.session(for: key).report?.id == receipt.id else { return }
            // Explicit retry retains original identities and remains subject to execution safety.
            if retry.contains(where: { RiskControlMatrix.requiresConfirmation($0) }) {
                self.pendingCleanupModuleKey = key.rawValue
                self.dangerConfirm = DangerClean(message: L10n.localized(.alertConfirmDeleteTitle), targets: retry, module: receipt.module)
            } else {
                self.cleanTargets(retry, module: receipt.module, moduleKey: key.rawValue)
            }
        }
    }

    func runScheduledCleanup() async -> Bool {
        guard SchedulerService.shared.config.isEnabled, !scheduledRunActive, activeCleanupRun == nil, !isScanning(module: "junk") else { return false }
        scheduledRunActive = true
        defer { scheduledRunActive = false }
        let authorizationGeneration = SchedulerService.shared.authorizationGeneration
        startScan(for: "junk")
        let generation = session(for: .junk).scanGeneration
        while session(for: .junk).scanning {
            do { try await Task.sleep(nanoseconds: UInt64(AppConfig.Security.progressInterval * 1_000_000_000)) }
            catch { stopScan(for: "junk"); return false }
            guard session(for: .junk).scanGeneration == generation else { return false }
        }
        let session = session(for: .junk)
        guard authorizationGeneration == SchedulerService.shared.authorizationGeneration, !Task.isCancelled, SchedulerService.shared.config.isEnabled,
              session.scanGeneration == generation,
              session.completedSuccessfully, !session.stopFlag.value else { return false }
        guard SchedulerService.shared.config.autoClean else { return true }
        let candidates = session.roots.allLeaves.filter { CleanupSelectionPolicy.isRecommended($0) }
        guard candidates.reduce(Int64(0), { $0 + $1.totalSize }) >= SchedulerService.shared.config.minimumCleanSize else { return true }
        // No page selection or manual/irreversible actions enter an unattended plan.
        cleanTargets(candidates.map { CleanTarget($0, executionMode: .automatic) }, module: JunkModule.spec.title, moduleKey: "junk")
        guard let runID = activeCleanupRun?.runID else { return false }
        while activeCleanupRun?.runID == runID {
            do { try await Task.sleep(nanoseconds: UInt64(AppConfig.Security.progressInterval * 1_000_000_000)) }
            catch { stopClean(); return false }
            guard authorizationGeneration == SchedulerService.shared.authorizationGeneration,
                  SchedulerService.shared.config.isEnabled else {
                stopClean()
                return false
            }
        }
        guard authorizationGeneration == SchedulerService.shared.authorizationGeneration,
              !Task.isCancelled,
              SchedulerService.shared.config.isEnabled,
              let rep = self.session(for: .junk).report else { return false }
        return rep.state == .success
    }

    func stopClean() {
        stopFlag.value = true
        cleanCoordinator.cancelCleanup()
        activeCleanupRun?.stopFlag.value = true
        cleanupPaused = false
        cleanCurrent = L10n.localized(.statusStopping)
    }

    // MARK: - ETA 估算

    /// 用已耗时与当前进度线性外推剩余时间。
    /// 刻意保守：样本不足、数值异常或超出合理上限时返回 nil——
    /// 清理工具里跳动的假倒计时，比没有倒计时更伤体验。
    nonisolated static func estimateETA(progress p: Double, elapsed: TimeInterval) -> TimeInterval? {
        guard p >= AppConfig.UI.etaMinProgress, p < 0.999 else { return nil }
        guard elapsed >= AppConfig.UI.etaMinElapsed else { return nil }
        let remaining = elapsed / p * (1 - p)
        guard remaining.isFinite, remaining > 0, remaining <= AppConfig.UI.etaMaxSeconds else { return nil }
        return remaining
    }
}
