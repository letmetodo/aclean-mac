import Foundation
import SwiftUI
import AppKit

// ============================================================
//  AppState+SmartCareAndActions —— 白名单过滤、启动项原子控制、
//  系统维护任务调度、SmartCare 编排与模块路由扩展
// ============================================================

extension AppState {

    // MARK: - 忽略与前缀感知白名单过滤

    func ignore(_ n: Node) {
        ignoredSubtrees.append(n)
        var nextIgnored = ignored
        var nextSelection = selection
        for l in n.leaves {
            nextIgnored.insert(l.id)
            nextSelection.remove(l.id)
            if let p = l.url?.path, !p.isEmpty {
                let canon = AppConfigStore.canonicalPath(p)
                ignoredPaths.insert(canon.isEmpty ? p : canon)
            }
        }
        ignored = nextIgnored
        selection = nextSelection
        if let rootPath = n.url?.path, !rootPath.isEmpty {
            let canon = AppConfigStore.canonicalPath(rootPath)
            ignoredPaths.insert(canon.isEmpty ? rootPath : canon)
        }
        ignoredNames.append(n.name)
        persistIgnoredPaths()
        roots = applyIgnoredPaths(to: roots)
        showIgnoredBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.showIgnoredBanner = false
        }
    }

    /// 撤销忽略：从快照恢复而不必重新全盘扫描
    func undoIgnore() {
        ignored.removeAll()
        ignoredNames.removeAll()
        var removed: Set<String> = []
        for sub in ignoredSubtrees {
            if let rp = sub.url?.path {
                removed.insert(rp)
                removed.insert(AppConfigStore.canonicalPath(rp))
            }
            for l in sub.leaves {
                guard let lp = l.url?.path else { continue }
                removed.insert(lp)
                removed.insert(AppConfigStore.canonicalPath(lp))
            }
            if !roots.contains(where: { $0.id == sub.id }) { roots.append(sub) }
        }
        ignoredPaths.subtract(removed)
        persistIgnoredPaths()
        ignoredSubtrees.removeAll()
        showIgnoredBanner = false
    }

    func persistIgnoredPaths() {
        AppConfigStore.shared.setIgnoredPaths(ignoredPaths)
    }

    func addIgnoredPath(_ path: String) {
        let canon = AppConfigStore.canonicalPath(path)
        guard !canon.isEmpty else { return }
        ignoredPaths.insert(canon)
        AppConfigStore.shared.addIgnoredPath(canon)
        roots = applyIgnoredPaths(to: roots)
    }

    func removeIgnoredPath(_ path: String) {
        let canon = AppConfigStore.canonicalPath(path)
        ignoredPaths.remove(path)
        ignoredPaths.remove(canon)
        AppConfigStore.shared.removeIgnoredPath(path)
        if !canon.isEmpty && canon != path {
            AppConfigStore.shared.removeIgnoredPath(canon)
        }
    }

    /// 判定节点是否命中用户白名单（仅自身与子项，用于扫描与 UI 展示过滤，保留祖先节点）(F6)
    func isNodeIgnoredForDisplay(_ node: Node) -> Bool {
        let rawPath = node.path
        guard !rawPath.isEmpty else { return false }
        if AppConfigStore.shared.isPathIgnoredForDisplay(rawPath) { return true }
        let target = AppConfigStore.canonicalPath(rawPath)
        guard !target.isEmpty else { return false }
        if ignoredPaths.contains(rawPath) || ignoredPaths.contains(target) { return true }
        for ignoredDir in ignoredPaths {
            let canonIgnored = AppConfigStore.canonicalPath(ignoredDir)
            guard !canonIgnored.isEmpty, canonIgnored != "/" else { continue }
            if target == canonIgnored || target.hasPrefix(canonIgnored + "/") {
                return true
            }
        }
        return false
    }

    /// 判定节点是否覆盖或命中用户白名单（双向重叠校验，用于删除安全阻断）
    func isNodeIgnoredForDeletion(_ node: Node) -> Bool {
        let rawPath = node.path
        guard !rawPath.isEmpty else { return false }
        if AppConfigStore.shared.isPathIgnoredForDeletion(rawPath) { return true }
        let target = AppConfigStore.canonicalPath(rawPath)
        guard !target.isEmpty else { return false }
        if ignoredPaths.contains(rawPath) || ignoredPaths.contains(target) { return true }
        for ignoredDir in ignoredPaths {
            let canonIgnored = AppConfigStore.canonicalPath(ignoredDir)
            guard !canonIgnored.isEmpty, canonIgnored != "/" else { continue }
            if target == canonIgnored || target.hasPrefix(canonIgnored + "/") || canonIgnored.hasPrefix(target + "/") {
                return true
            }
        }
        return false
    }

    /// 判定节点是否命中用户白名单（默认遵循删除安全级双向阻断）
    func isNodeIgnored(_ node: Node) -> Bool {
        isNodeIgnoredForDeletion(node)
    }

    /// 扫描后按持久化的忽略路径过滤（支持目录级前缀递归剥离，仅排除被忽略项自身及后代，完整保留祖先展示树）
    func applyIgnoredPaths(to tree: [Node]) -> [Node] {
        guard !ignoredPaths.isEmpty || !AppConfigStore.shared.currentIgnoredPathsSnapshot().isEmpty else {
            return tree
        }
        func filterSubtree(_ node: Node) -> Node? {
            if isNodeIgnoredForDisplay(node) { return nil }
            if node.children.isEmpty {
                // A real directory may not have been expanded yet; it is not an empty display group.
                return node.isGroup && node.url == nil ? nil : node
            }
            let remainingChildren = node.children.compactMap { filterSubtree($0) }
            if node.isGroup && remainingChildren.isEmpty {
                return nil
            }
            var copy = node
            copy.children = remainingChildren
            if !remainingChildren.isEmpty {
                copy.size = remainingChildren.reduce(0) { $0 + $1.totalSize }
            }
            return copy
        }
        return tree.compactMap { filterSubtree($0) }
    }

    // MARK: - 单项操作

    func revealInFinder(_ n: Node) {
        guard let u = n.url else { return }
        NSWorkspace.shared.activateFileViewerSelecting([u])
    }

    func open(_ n: Node) {
        guard let u = n.url else { return }
        NSWorkspace.shared.open(u)
    }

    func quickLook(_ n: Node) {
        guard let u = n.url else { return }
        QuickLookHelper.shared.preview(u)
    }

    func showInfoPanel(_ n: Node) {
        infoNode = n
        showInfo = true
    }

    // MARK: - 维护任务执行

    private func confirmMaintenance(_ tasks: [PerformanceEngine.MaintenanceTask]) -> Bool {
        let irreversible = tasks.filter { AppConfig.Maintenance.irreversibleTaskIDs.contains($0.taskId) }
        guard !irreversible.isEmpty else { return true }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = tr(.actionRunSystemMaintenance)
        alert.informativeText = irreversible.map(\.name).joined(separator: "\n") + "\n\n" + tr(.maintenanceIrreversibleNotice)
        alert.addButton(withTitle: tr(.actionConfirm))
        alert.addButton(withTitle: tr(.actionCancel))
        return alert.runModal() == .alertFirstButtonReturn
    }

    func runMaintenance(_ t: PerformanceEngine.MaintenanceTask) {
        guard maintenanceRuns[t.name] != tr(.running) else { return }
        guard !t.needsAdmin || PrivilegedMaintenanceClient.isEnabled else { toast = tr(.helperFailed); openSettings(tab: "permissions"); return }
        guard confirmMaintenance([t]) else { return }
        maintenanceRuns[t.name] = tr(.running)
        let ruleTaskLease = RuleTaskGate.shared.begin()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let outcome = PerformanceEngine.executeTask(t)
            let ok = outcome.isSuccess
            DispatchQueue.main.async { [self] in
                defer { withExtendedLifetime(ruleTaskLease) {} }
                let doneText: String
                switch outcome {
                case .succeeded:
                    doneText = tr(.completed)
                    self?.toast = "\(tr(.statusExecuted)): \(t.name)"
                case .targetNotRunning:
                    doneText = tr(.statusTargetNotRunningNoActionNeeded)
                    self?.toast = "\(t.name): \(tr(.statusTargetNotRunningNoActionNeeded))"
                case .failed:
                    doneText = tr(.failedOrCancelled)
                    self?.toast = "\(tr(.executionFailedOrCancelled)): \(t.name)"
                }
                self?.maintenanceRuns[t.name] = doneText
                self?.log.append(LogEntry(title: t.name, detail: doneText, ok: ok))
                if ok {
                    self?.hasOptimizedCurrentModule = true
                    self?.updateCurrentSession {
                        $0.hasOptimized = true
                        $0.hasScanned = true
                    }
                    AppConfigStore.shared.playCompletionSoundIfEnabled()
                }
            }
        }
    }

    /// 批量顺序运行指定的维护任务列表（合并或顺序执行，避免并发弹出多个管理员授权框）
    func runMaintenanceTasks(_ runList: [PerformanceEngine.MaintenanceTask]) {
        guard !runList.isEmpty, !runList.contains(where: { maintenanceRuns[$0.name] == tr(.running) }) else { return }
        guard !runList.contains(where: \.needsAdmin) || PrivilegedMaintenanceClient.isEnabled else { toast = tr(.helperFailed); openSettings(tab: "permissions"); return }
        guard confirmMaintenance(runList) else { return }
        toast = tr(.startingMaintenanceTasksCountFormat, runList.count)
        for t in runList {
            maintenanceRuns[t.name] = tr(.running)
        }
        let ruleTaskLease = RuleTaskGate.shared.begin()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var okCount = 0
            // 1. 先执行无需管理员权限的任务
            let nonAdminTasks = runList.filter { !$0.needsAdmin }
            let adminTasks = runList.filter { $0.needsAdmin }

            for t in nonAdminTasks {
                let outcome = PerformanceEngine.executeTask(t)
                let ok = outcome.isSuccess
                DispatchQueue.main.async { [self] in
                    let statusText: String
                    switch outcome {
                    case .succeeded: statusText = tr(.completed)
                    case .targetNotRunning: statusText = tr(.statusTargetNotRunningNoActionNeeded)
                    case .failed: statusText = tr(.failedOrCancelled)
                    }
                    self?.maintenanceRuns[t.name] = statusText
                    self?.log.append(LogEntry(title: t.name, detail: statusText, ok: ok))
                }
                if ok { okCount += 1 }
            }

            // Dispatch each typed task; deduplicate identical underlying helper actions (e.g. purgeableSpace & thinTimeMachine).
            var executedAdminCommands: [String: Bool] = [:]
            for task in adminTasks {
                let dedupKey = (task.taskId == "purgeableSpace" || task.taskId == "thinTimeMachine") ? "thinTimeMachine" : task.taskId
                let ok: Bool
                if let cachedOk = executedAdminCommands[dedupKey] {
                    ok = cachedOk
                } else {
                    ok = PerformanceEngine.executeTask(task).isSuccess
                    executedAdminCommands[dedupKey] = ok
                }
                if ok { okCount += 1 }
                DispatchQueue.main.async { [self] in
                    self?.maintenanceRuns[task.name] = ok ? tr(.completed) : tr(.failedOrCancelled)
                    self?.log.append(LogEntry(title: task.name, detail: ok ? tr(.completed) : tr(.failedOrCancelled), ok: ok))
                }
            }

            DispatchQueue.main.async { [self, okCount] in
                defer { withExtendedLifetime(ruleTaskLease) {} }
                self?.toast = tr(.maintenanceCompletedRatioFormat, okCount, runList.count)
                self?.selection.removeAll()
                if okCount > 0 {
                    self?.hasOptimizedCurrentModule = true
                    self?.updateCurrentSession {
                        $0.hasOptimized = true
                        $0.hasScanned = true
                    }
                    AppConfigStore.shared.playCompletionSoundIfEnabled()
                }
            }
        }
    }

    /// 批量运行选中的维护任务（支持稳定 maintenanceTaskId 与跨语言匹配）
    func runSelectedMaintenanceTasks() {
        let targets = selectedLeaves.filter { $0.tags.contains("Maintenance Tasks") || $0.tags.contains(tr(.maintenanceTasks)) || $0.maintenanceTaskId != nil }
        let tasks = PerformanceEngine.maintenanceTasks()
        let toRun = tasks.filter { t in
            targets.contains { node in
                node.maintenanceTaskId == t.taskId || node.name == t.name
            }
        }
        let runList = toRun.isEmpty ? tasks : toRun
        runMaintenanceTasks(runList)
    }

    // MARK: - 启动项原子切换

    func toggleStartup(_ item: StartupItem) {
        let current = PerformanceEngine.startupOverride(for: item.path) ?? item.enabled
        let target = !current
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let ok = PerformanceEngine.setEnabled(item, enabled: target)
            DispatchQueue.main.async { [self] in
                if ok, let i = self?.startupItems.firstIndex(where: { $0.id == item.id }) {
                    self?.startupItems[i].enabled = target
                    self?.startupItems[i].stateKnown = true
                    self?.toast = target
                        ? tr(.enabledItemNameFormat, item.name)
                        : tr(.disabledItemNameFormat, item.name)
                } else if ok {
                    self?.toast = target
                        ? tr(.enabledItemNameFormat, item.name)
                        : tr(.disabledItemNameFormat, item.name)
                } else {
                    self?.toast = tr(.statusOperationCancelledOrFailed)
                }
            }
        }
    }

    func isStartupItem(_ n: Node) -> Bool {
        n.startupItem != nil || n.tags.contains("Login Items") || n.tags.contains("Background Items") || n.tags.contains("Background Services")
    }

    /// 跨语言、零脆弱性的启动项启用状态判定
    func startupEnabled(_ n: Node) -> Bool {
        if let item = n.startupItem, item.managedBySystemSettings {
            return item.enabled
        }
        if !n.path.isEmpty, let override = PerformanceEngine.startupOverride(for: n.path) {
            return override
        }
        if let item = n.startupItem {
            return item.enabled
        }
        if let statusTuple = n.meta.first(where: { $0.0 == "Status" || $0.0 == tr(.labelStatus) }) {
            return statusTuple.1 != "Disabled" && statusTuple.1 != tr(.statusDisabled)
        }
        return true
    }

    private func applyNodeStartupState(_ node: inout Node, enabled: Bool) {
        node.startupItem?.enabled = enabled
        node.startupItem?.stateKnown = true
        let statusVal = enabled ? tr(.statusEnabled) : tr(.statusDisabled)
        if let i = node.meta.firstIndex(where: { $0.0 == "Status" || $0.0 == tr(.labelStatus) }) {
            node.meta[i].1 = statusVal
        } else {
            node.meta.append(("Status", statusVal))
        }
    }

    /// 批量禁用选中的启动项/后台项目
    func disableSelectedStartupNodes() {
        let targets = selectedLeaves.filter { isStartupItem($0) }
        guard !targets.isEmpty else { return }
        let targetPairs = targets.compactMap { n -> (UUID, String, StartupItem?)? in
            guard let p = n.url?.path else { return nil }
            return (n.id, p, n.startupItem)
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let items = PerformanceEngine.startupItems()
            var succeeded = Set<UUID>()
            var count = 0
            for (id, path, cachedItem) in targetPairs {
                if let item = cachedItem ?? items.first(where: { $0.path == path }) {
                    let ok = PerformanceEngine.setEnabled(item, enabled: false)
                    if ok { count += 1; succeeded.insert(id) }
                }
            }
            DispatchQueue.main.async { [self, succeeded, count] in
                guard let self else { return }
                for (id, _, _) in targetPairs where succeeded.contains(id) {
                    _ = self.roots.mutate(id: id) { n in
                        self.applyNodeStartupState(&n, enabled: false)
                    }
                }
                self.selection.subtract(succeeded)
                self.toast = tr(.disabledStartupItemsCountFormat, count)
            }
        }
    }

    /// 批量启用选中的启动项/后台项目
    func enableSelectedStartupNodes() {
        let targets = selectedLeaves.filter { isStartupItem($0) }
        guard !targets.isEmpty else { return }
        let targetPairs = targets.compactMap { n -> (UUID, String, StartupItem?)? in
            guard let p = n.url?.path else { return nil }
            return (n.id, p, n.startupItem)
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let items = PerformanceEngine.startupItems()
            var succeeded = Set<UUID>()
            var count = 0
            for (id, path, cachedItem) in targetPairs {
                if let item = cachedItem ?? items.first(where: { $0.path == path }) {
                    let ok = PerformanceEngine.setEnabled(item, enabled: true)
                    if ok { count += 1; succeeded.insert(id) }
                }
            }
            DispatchQueue.main.async { [self, succeeded, count] in
                guard let self else { return }
                for (id, _, _) in targetPairs where succeeded.contains(id) {
                    _ = self.roots.mutate(id: id) { n in
                        self.applyNodeStartupState(&n, enabled: true)
                    }
                }
                self.selection.subtract(succeeded)
                self.toast = tr(.enabledStartupItemsCountFormat, count)
            }
        }
    }

    /// 对 DataManager 里的启动项节点执行禁用/启用 (支持未知态切换后逆转)
    func toggleStartupNode(_ n: Node) {
        guard !n.locked else { toast = tr(.showsDiskUsageOnlyAndIsNeverAutoCleanedManageInTheRespectiveAppOrSystemSettings); return }
        guard let path = n.url?.path else { return }
        let nodeID = n.id
        let currentEnabled = startupEnabled(n)
        let target = !currentEnabled
        let resolvedItem = n.startupItem ?? PerformanceEngine.startupItems().first(where: { $0.path == path })
        guard let item = resolvedItem else {
            toast = tr(.startupItemConfigNotFound)
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let ok = PerformanceEngine.setEnabled(item, enabled: target)
            DispatchQueue.main.async { [self] in
                guard let self else { return }
                if ok {
                    _ = self.roots.mutate(id: nodeID) { node in
                        self.applyNodeStartupState(&node, enabled: target)
                    }
                    self.toast = target
                        ? tr(.enabledItemNameFormat, item.name)
                        : tr(.disabledItemNameFormat, item.name)
                    self.log.append(LogEntry(title: item.name,
                                             detail: target ? tr(.statusEnabled) : tr(.disabledViaLaunchctl),
                                             ok: true))
                } else {
                    self.toast = tr(.statusOperationCancelledOrFailed)
                }
            }
        }
    }

    // MARK: - 智能呵护：逐卡扫描与一键执行

    private func syncSmartScanSession() {
        let cards = SmartCareModule.cards.compactMap { smartCards[$0] }.filter(\.included)
        let inProgress = !smartScanFlags.isEmpty || !smartQueue.isEmpty
        var session = session(for: "smartCare")
        let initializeSelection = session.scanGeneration != smartScanGeneration || session.scanning
        session.scanGeneration = smartScanGeneration
        session.hasScanned = true
        session.scanning = inProgress
        session.completedSuccessfully = !inProgress && !cards.isEmpty && cards.allSatisfy(\.done)
        session.scanIssues = cards.flatMap(\.scanIssues)
        session.scanDegradations = cards.flatMap(\.scanDegradations)
        session.scanProgress = cards.isEmpty ? 0 : cards.reduce(0) { $0 + $1.progress } / Double(cards.count)
        if !inProgress {
            if session.scanDegradations.contains(.ruleDatabaseUnavailable) {
                session.scanStatus = L10n.localized(.ruleDatabaseUnavailableTitle)
            } else {
                session.scanStatus = L10n.localized(session.completedSuccessfully ? .statusCompleted : .scanCoverageIncomplete)
            }
        }
        session.roots = cards.compactMap(\.tree).flatMap { $0 }
        session.screen = inProgress ? .scanning : .results
        if !inProgress && initializeSelection {
            session.selection = Set(session.roots.allLeaves.filter(CleanupSelectionPolicy.isRecommended).map(\.id))
        } else if !inProgress {
            session.selection = CleanupSelectionPolicy.reconcileUserSelection(session.selection, roots: session.roots)
        }
        write(.smartCare) { s in
            s = session
        }
    }

    func scanSmartCard(_ key: String) {
        guard !isModuleCleaning("smartCare") else { return }
        var st = smartCards[key] ?? SmartCardState()
        guard !st.scanning else { return }
        if moduleKey == "smartCare" { stopFlag.value = false }
        st = SmartCardState()
        st.included = smartCards[key]?.included ?? true
        st.scanning = true
        smartCards[key] = st

        let ruleTaskLease = RuleTaskGate.shared.begin()
        let generation = smartScanGeneration
        let flag = StopFlag()
        smartScanFlags[key] = flag
        let sp = ModuleRegistry.spec(for: key)
        let moduleTitle = sp.title
        let builder = scanBuilder?(key) ?? sp.buildTree
        syncSmartScanSession()
        if moduleKey == "smartCare" { scanStatus = tr(.scanningModuleTitleFormat, sp.title) }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let context = IOScanContext(stopped: { flag.value })
            let progressState = LockedValue<TimeInterval>(0)
            let tree = context.perform { builder({ [self] p, s in
                let accepted = progressState.withValue { previous -> Bool in
                    let now = ProcessInfo.processInfo.systemUptime
                    guard now - previous >= AppConfig.Security.progressInterval || p >= 1 else { return false }
                    previous = now; return true
                }
                guard accepted else { return }
                DispatchQueue.main.async { [self] in
                defer { withExtendedLifetime(ruleTaskLease) {} }
                    guard let self, self.smartScanGeneration == generation,
                          var cur = self.smartCards[key], cur.scanning, !flag.value else { return }
                    cur.progress = p
                    self.smartCards[key] = cur
                    self.write(.smartCare) { session in
                        session.scanStatus = s
                    }
                    self.syncSmartScanSession()
                    if self.moduleKey == "smartCare", !s.isEmpty {
                        self.scanStatus = s
                        self.scanPaths.append(s)
                        if self.scanPaths.count > 4 { self.scanPaths.removeFirst() }
                    }
                }
            }, { [self] incrementalNodes in
                DispatchQueue.main.async { [self] in
                    guard let self, self.smartScanGeneration == generation,
                          var cur = self.smartCards[key], cur.scanning, !flag.value else { return }
                    let incomingIDs = Set(incrementalNodes.map(\.id))
                    let filtered = self.applyIgnoredPaths(to: incrementalNodes.filter { $0.totalSize > 0 || $0.leafCount > 0 })
                    let survivingIDs = Set(filtered.map(\.id))
                    let removedIDs = incomingIDs.subtracting(survivingIDs)
                    guard !filtered.isEmpty || !removedIDs.isEmpty else { return }
                    var partialTree = cur.tree ?? []
                    if !removedIDs.isEmpty {
                        partialTree.removeAll { removedIDs.contains($0.id) }
                    }
                    for node in filtered {
                        if let index = partialTree.firstIndex(where: { $0.id == node.id }) { partialTree[index] = node }
                        else { partialTree.append(node) }
                    }
                    cur.tree = partialTree
                    let actionableLeaves = partialTree.allLeaves.filter {
                        CleanupSelectionPolicy.isRecommended($0) && !self.isStartupItem($0)
                    }
                    cur.size = actionableLeaves.reduce(0) { $0 + $1.totalSize }
                    cur.count = actionableLeaves.count
                    self.smartCards[key] = cur
                    self.syncSmartScanSession()
                }
            }, { flag.value }) }

            DispatchQueue.main.async { [self] in
                guard let self else { return }
                guard self.smartScanGeneration == generation else { return }
                self.smartScanFlags.removeValue(forKey: key)
                var cur = self.smartCards[key] ?? SmartCardState()
                cur.scanning = false
                if flag.value {
                    cur.done = false
                    self.smartCards[key] = cur
                    if self.moduleKey == "smartCare" { self.scanning = false }
                    self.smartQueue.removeAll()
                    self.syncSmartScanSession()
                    return
                }
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
                cur.done = issues.isEmpty && degradations.isEmpty
                cur.scanIssues = issues
                cur.scanDegradations = degradations
                cur.evaluationReasonCounts = context.evaluationReasonCounts
                cur.deduplicationRecords = context.deduplicationRecords
                cur.progress = 1
                let filtered = self.applyIgnoredPaths(to: tree)
                let actionableLeaves = filtered.allLeaves.filter {
                    CleanupSelectionPolicy.isRecommended($0) && !self.isStartupItem($0)
                }
                cur.count = actionableLeaves.isEmpty ? filtered.allLeaves.count : actionableLeaves.count
                cur.size = actionableLeaves.reduce(0) { $0 + $1.totalSize }
                cur.tree = filtered
                self.smartCards[key] = cur
                let statusSuffix = cur.scanDegradations.contains(.ruleDatabaseUnavailable)
                    ? L10n.localized(.ruleDatabaseUnavailableTitle)
                    : (cur.done ? tr(.completed) : tr(.scanCoverageIncomplete))
                self.log.append(LogEntry(title: "\(moduleTitle) \(statusSuffix)",
                                         detail: "\(cur.count) \(tr(.tileJunkQuantifier)) · \(Fmt.size(cur.size))",
                                         ok: cur.done))
                if !self.smartQueue.isEmpty {
                    let next = self.smartQueue.removeFirst()
                    let doneCount = SmartCareModule.cards.count - self.smartQueue.count
                    if self.moduleKey == "smartCare" { self.scanProgress = Double(doneCount) / Double(SmartCareModule.cards.count) }
                    self.scanSmartCard(next)
                } else {
                    self.syncSmartScanSession()
                    if self.moduleKey == "smartCare" { self.disk = DiskInfo.current() }
                    AppConfigStore.shared.playCompletionSoundIfEnabled()
                }
            }
        }
    }

    func scanAllSmartCards() {
        guard !isModuleCleaning("smartCare") else { return }
        smartScanGeneration += 1
        for flag in smartScanFlags.values { flag.value = true }
        smartScanFlags.removeAll()
        for key in smartCards.keys { smartCards[key]?.scanning = false }
        smartQueue.removeAll()
        if moduleKey == "smartCare" { stopFlag.value = false }
        let keys = SmartCareModule.cards.filter {
            (smartCards[$0]?.included ?? true) && !(smartCards[$0]?.scanning ?? false)
        }
        guard !keys.isEmpty else {
            toast = tr(.noScanCardsSelected)
            return
        }
        for key in keys {
            let included = smartCards[key]?.included ?? true
            smartCards[key] = SmartCardState()
            smartCards[key]?.included = included
        }
        smartQueue = Array(keys.dropFirst())
        scanSmartCard(keys[0])
    }

    func toggleCardInclusion(_ key: String) {
        var st = smartCards[key] ?? SmartCardState()
        st.included.toggle()
        smartCards[key] = st
    }

    func runSmartCleanup() {
        var targets: [CleanTarget] = []
        let chosen = moduleKey == .smartCare ? selection : session(for: .smartCare).selection
        for k in SmartCareModule.cards {
            guard let st = smartCards[k], st.done, st.included, let tree = st.tree else { continue }
            for l in tree.allLeaves where chosen.contains(l.id) && CleanupSelectionPolicy.isRecommended(l) && !isNodeIgnoredForDeletion(l) && !isStartupItem(l) && !isManualStorageNode(l) {
                if l.badge == "Latest" || l.badge == "Will Keep" || l.badge == tr(.badgeWillKeep) { continue }
                targets.append(CleanTarget(l, executionMode: .automatic))
            }
        }

        guard !targets.isEmpty else {
            toast = tr(.nothingToCleanPleaseScanFirst)
            return
        }

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
        let userRequiresConfirm = AppConfigStore.shared.confirmBeforeDelete

        // F1/R9 智能维护对齐全域统一安全风控契约：凡不可恢复或用户设置删除确认，统一弹窗
        if hasIrreversible || targets.contains(where: { RiskControlMatrix.requiresConfirmation($0) }) || userRequiresConfirm {
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
            pendingCleanupModuleKey = "smartCare"
            let manualTargets = targets.map { t -> CleanTarget in
                var copy = t
                copy.executionMode = .manual
                return copy
            }
            dangerConfirm = DangerClean(
                message: messages.joined(separator: "\n\n"),
                targets: manualTargets,
                module: tr(.moduleSmartCareAlt))
            return
        }

        cleanTargets(targets, module: tr(.moduleSmartCareAlt))
    }

    func syncSmartCardsAfterClean(gone: Set<String>) {
        guard !gone.isEmpty else { return }
        for k in SmartCareModule.cards {
            guard var st = smartCards[k], st.done, var tree = st.tree else { continue }
            _ = tree.removeLeaves { node in
                if gone.contains(node.path) { return true }
                if let containerPath = node.ruleEvidence?.containerPath, gone.contains(containerPath) { return true }
                return false
            }
            st.tree = tree
            st.count = tree.allLeaves.count
            st.size = tree.reduce(0) { $0 + $1.totalSize }
            smartCards[k] = st
        }
    }

    // MARK: - 导航与软件管理（所有权收敛至 open，支持多模块并行与状态保留）

    func openTool(_ tool: ToolItem) {
        open(.restore(ModuleKey.parse(tool.moduleKey) ?? .junk))
        pendingCategory = tool.category
    }

    func back() {
        let isConcise = ModuleKey.sidebar.contains(moduleKey)
        switch screen {
        case .intro:       break
        case .scanning:    stopScan(for: moduleKey.rawValue)
        case .results:     screen = isConcise ? .dataManager : .intro
        case .dataManager:
            if !isConcise { screen = .results }
        case .review:      screen = .dataManager
        case .cleaning:    break
        case .complete:
            screen = isConcise ? .dataManager : .results
        case .log:
            screen = isConcise ? .dataManager : .complete
        }
    }

    func startOver() {
        guard screen != .cleaning else { return }
        stopScan(for: moduleKey.rawValue)
        roots = []
        selection = []
        expanded = []
        focusGroup = nil
        category = ""
        search = ""
        report = nil
        hasScannedCurrentModule = false
        hasOptimizedCurrentModule = false
        didApplyDefaultsCurrentModule = false
        screen = .intro
        updateCurrentSession {
            $0.hasScanned = false
            $0.hasOptimized = false
            $0.screen = .intro
            $0.roots = []
            $0.report = nil
            $0.selection = []
            $0.expanded = []
        }
    }

    // MARK: - 软件管理：应用本体+安全缓存 vs 需确认用户数据 分层选择

    /// 判断某个应用节点是否已被勾选（全选或部分勾选安全项）
    func isAppChecked(_ app: Node) -> Bool {
        isSelected(app) || partial(app)
    }

    /// 切换应用卸载勾选状态：
    /// 未勾选时默认勾选「App 本体 + 安全缓存/日志」，保留「容器/应用支持/偏好设置」供用户按需确认；
    /// 已勾选时一键取消该应用下所有目录。
    func toggleAppUninstall(_ app: Node) {
        let allLeaves = app.leaves.filter { !$0.locked }
        guard !allLeaves.isEmpty else { return }

        var next = selection
        if isAppChecked(app) {
            for l in allLeaves { next.remove(l.id) }
        } else {
            let safeLeaves = allLeaves.filter {
                UninstallSafety.isDefaultItem($0)
            }
            for l in safeLeaves { next.insert(l.id) }
        }
        selection = next
    }

    /// 一并勾选指定应用的全部用户数据（容器、应用支持、偏好设置等）
    func includeUserData(for app: Node) {
        var next = selection
        for l in app.leaves where !l.locked {
            next.insert(l.id)
        }
        selection = next
    }

    /// 仅保留指定应用的安全清理项（取消容器、应用支持、偏好设置等用户数据）
    func keepOnlySafeItems(for app: Node) {
        let allLeaves = app.leaves.filter { !$0.locked }
        var next = selection
        for l in allLeaves {
            let isUser = !UninstallSafety.isDefaultItem(l)
            if isUser {
                next.remove(l.id)
            } else {
                next.insert(l.id)
            }
        }
        selection = next
    }

    /// 一并勾选所有当前已选应用的全部用户数据（对应底部栏「一并移除用户数据」）
    func includeUserDataForSelectedApps() {
        let checkedApps = selectedRoots.filter { !$0.tags.contains(OrphanFinderEngine.categoryTag) }
        var next = selection
        for app in checkedApps {
            for l in app.leaves where !l.locked {
                next.insert(l.id)
            }
        }
        selection = next
    }

    /// 计算应用下尚未勾选的「需确认用户数据」体积
    func unselectedUserDataSize(in app: Node) -> Int64 {
        app.leaves.filter {
            !$0.locked &&
            !selection.contains($0.id) &&
            !UninstallSafety.isDefaultItem($0)
        }.reduce(0) { $0 + $1.totalSize }
    }

    /// 计算应用下全部「安全移除项（App 本体 + 缓存/日志等）」体积
    func safeRemovalSize(in app: Node) -> Int64 {
        app.leaves.filter {
            !$0.locked &&
            UninstallSafety.isDefaultItem($0)
        }.reduce(0) { $0 + $1.totalSize }
    }
}
