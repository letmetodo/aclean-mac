import Foundation

/// Owns the ordered save/open/write projection contract.
/// Background work writes its originating module rather than the visible page.
extension AppState {
    // ============================================================
    // MARK: 模块会话同步与查询 (所有权契约)
    // ============================================================

    func rulesDidChange() {
        moduleSessions.clearForRuleUpdate()
        roots = []; selection = []; expanded = []; ignoredSubtrees = []
        activeScanningModules.removeAll(); scanning = false; isStoppingScan = false
        stopFlag.value = true
        screen = defaultSession(for: moduleKey).screen
        focusGroup = nil; infoNode = nil; showInfo = false
        startupItems = []; lastCleanupTargets.removeAll()
        smartScanGeneration += 1
        smartScanFlags.values.forEach { $0.value = true }
        smartScanFlags.removeAll(); smartQueue.removeAll(); smartCards.removeAll()
        dangerConfirm = nil
        DirectoryChildrenRepository.shared.clear()
        SmartCleanSnapshotCache.shared.invalidateRules()
        toast = L10n.localized(.ruleUpdateRescanRequired)
    }

    func defaultSession(for key: ModuleKey) -> ModuleSession {
        var s = ModuleSession()
        let isStatic = (key == .liveMonitor || key == .toolbox || key == .assistant)
        s.screen = isStatic ? .dataManager : .intro
        if key == .performance {
            s.sortKey = .name
            s.sortAscending = true
            s.strategy = .none
        } else if key == .applications {
            s.sortKey = .size
            s.sortAscending = false
            s.strategy = .none
        } else if key == .spaceLens {
            s.sortKey = .size
            s.sortAscending = false
            s.strategy = .none
        } else {
            s.sortKey = .size
            s.sortAscending = false
            s.strategy = .smart
        }
        return s
    }

    func defaultSession(for rawKey: String) -> ModuleSession {
        defaultSession(for: ModuleKey.parse(rawKey) ?? .junk)
    }

    func session(for key: ModuleKey) -> ModuleSession {
        if key == moduleKey {
            saveActiveToSession()
        }
        return moduleSessions[key] ?? defaultSession(for: key)
    }

    func session(for rawKey: String) -> ModuleSession {
        guard let key = ModuleKey.parse(rawKey) else { return defaultSession(for: .junk) }
        return session(for: key)
    }

    func updateCurrentSession(_ mutate: (inout ModuleSession) -> Void) {
        write(moduleKey, mutate)
    }

    func isScanning(module key: ModuleKey) -> Bool {
        if key == moduleKey { return scanning }
        return moduleSessions[key]?.scanning ?? false
    }

    func isScanning(module rawKey: String) -> Bool {
        guard let key = ModuleKey.parse(rawKey) else { return false }
        return isScanning(module: key)
    }

    var hasScannedCurrentModule: Bool {
        get { moduleSessions[moduleKey]?.hasScanned ?? false }
        set {
            write(moduleKey) { $0.hasScanned = newValue }
        }
    }

    var hasOptimizedCurrentModule: Bool {
        get { moduleSessions[moduleKey]?.hasOptimized ?? false }
        set {
            write(moduleKey) { $0.hasOptimized = newValue }
        }
    }

    var didApplyDefaultsCurrentModule: Bool {
        get { moduleSessions[moduleKey]?.didApplyDefaults ?? false }
        set {
            write(moduleKey) { $0.didApplyDefaults = newValue }
        }
    }

    /// 检查指定模块是否刚刚扫描或优化过（若已扫描或优化过，直接呈现结果；否则呈现中间引导页与触发按钮）
    func isModuleScannedOrOptimized(_ key: ModuleKey) -> Bool {
        if key == .liveMonitor || key == .toolbox || key == .assistant {
            return true
        }
        if let s = moduleSessions[key] {
            return s.hasScanned || s.hasOptimized || !s.roots.isEmpty || s.report != nil
        }
        if key == moduleKey {
            return hasScannedCurrentModule || hasOptimizedCurrentModule || !roots.isEmpty || report != nil
        }
        return false
    }

    func isModuleScannedOrOptimized(_ rawKey: String) -> Bool {
        guard let key = ModuleKey.parse(rawKey) else { return false }
        return isModuleScannedOrOptimized(key)
    }

    // MARK: - 所有权操作：open 与 write 为投影与字典同步的唯一入口

    private func saveActiveToSession() {
        var s = moduleSessions[moduleKey] ?? defaultSession(for: moduleKey)
        s.roots = roots
        s.selection = selection
        s.expanded = expanded
        s.category = category
        s.search = search
        s.sortKey = sortKey
        s.sortAscending = sortAscending
        s.strategy = strategy
        s.focusGroup = focusGroup
        s.screen = screen
        s.scanning = scanning
        s.isStoppingScan = isStoppingScan
        s.scanProgress = scanProgress
        s.scanStatus = scanStatus
        s.scanETA = scanETA
        s.scanPaths = scanPaths
        s.report = report
        s.cleaningProfileState = cleaningProfileState
        moduleSessions[moduleKey] = s
    }

    private func applySessionToProjection(_ s: ModuleSession) {
        isSwitchingModule = true
        if !Self.sharesRootSnapshot(roots, s.roots) {
            roots = s.roots
        }
        if selection != s.selection { selection = s.selection }
        setCleaningProfile(s.cleaningProfileState.primary, selectedProfiles: s.cleaningProfileState.profiles)
        if expanded != s.expanded { expanded = s.expanded }
        if category != s.category { category = s.category }
        if search != s.search { search = s.search }
        if sortKey != s.sortKey { sortKey = s.sortKey }
        if sortAscending != s.sortAscending { sortAscending = s.sortAscending }
        if strategy != s.strategy { strategy = s.strategy }
        if focusGroup != s.focusGroup { focusGroup = s.focusGroup }
        let targetScreen: Screen = (activeCleanupRun?.moduleKey == moduleKey.rawValue) ? .cleaning : s.screen
        if screen != targetScreen { screen = targetScreen }
        if scanning != s.scanning { scanning = s.scanning }
        if isStoppingScan != s.isStoppingScan { isStoppingScan = s.isStoppingScan }
        if scanProgress != s.scanProgress { scanProgress = s.scanProgress }
        if scanStatus != s.scanStatus { scanStatus = s.scanStatus }
        if scanETA != s.scanETA { scanETA = s.scanETA }
        if scanPaths != s.scanPaths { scanPaths = s.scanPaths }
        if report?.id != s.report?.id { report = s.report }
        isSwitchingModule = false
    }

    func open(_ request: OpenRequest) {
        switch request {
        case .restore(let targetKey):
            if moduleKey == targetKey {
                return
            }
            saveActiveToSession()
            let s = moduleSessions[targetKey] ?? defaultSession(for: targetKey)
            moduleSessions[targetKey] = s
            isSwitchingModule = true
            moduleKey = targetKey
            applySessionToProjection(s)

        case .smartResult(let targetKey, let tree):
            guard !tree.isEmpty else {
                open(.restore(targetKey))
                return
            }
            saveActiveToSession()
            var s = moduleSessions[targetKey] ?? defaultSession(for: targetKey)
            s.roots = tree
            s.selection = []
            s.expanded = []
            s.category = ""
            s.search = ""
            s.focusGroup = tree.first?.id
            s.screen = (targetKey == .applications) ? .dataManager : .results
            s.hasScanned = true
            s.didApplyDefaults = true
            s.strategy = (targetKey == .applications) ? .none : .smart
            s.cleaningProfileState = CleaningProfileState(profile: s.strategy == .smart ? .safeDaily : .custom)
            if s.strategy == .smart {
                var initialSelection = Set<UUID>()
                for l in tree.allLeaves where CleanupSelectionPolicy.isRecommended(l) {
                    if l.badge == "Latest" || l.badge == L10n.localized(.statusLatest) { continue }
                    initialSelection.insert(l.id)
                }
                s.selection = initialSelection
            } else {
                s.selection = []
            }
            moduleSessions[targetKey] = s
            isSwitchingModule = true
            moduleKey = targetKey
            applySessionToProjection(s)
        }
    }

    func write(_ key: ModuleKey, _ mutate: (inout ModuleSession) -> Void) {
        if key == moduleKey {
            saveActiveToSession()
        }
        var sess = moduleSessions[key] ?? defaultSession(for: key)
        mutate(&sess)
        moduleSessions[key] = sess
        if moduleKey == key {
            applySessionToProjection(sess)
        }
    }

    func write(_ rawKey: String, _ mutate: (inout ModuleSession) -> Void) {
        guard let key = ModuleKey.parse(rawKey) else { return }
        write(key, mutate)
    }

    static func sharesRootSnapshot(_ lhs: [Node], _ rhs: [Node]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        guard !lhs.isEmpty else { return true }
        return lhs.withUnsafeBufferPointer { lhsBuffer in
            rhs.withUnsafeBufferPointer { rhsBuffer in
                lhsBuffer.baseAddress == rhsBuffer.baseAddress
            }
        }
    }
}
