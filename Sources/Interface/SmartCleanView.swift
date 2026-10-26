import SwiftUI
import AppKit

// ============================================================
//  SmartCleanView —— 垃圾清理模块（极简卡片式清理视图）
//
//  视觉与交互特征（交互与视觉规范）：
//    1. 顶部区域：
//       - 左侧大标题「准备开始清理」
//       - 副标题「可清理 30.8 GB · 609 项 · 7 类 · 洁净大师、Antigravity、Google Chrome 占用缓存 · 退出」
//         自动检测正在运行且占用待清理缓存的 App，点击「退出」可优雅关闭对应应用
//       - 右上角仅保留 `↻`（重新扫描）与 `⊗`（重置状态）两个极简图标按钮
//    2. 8 大人类语义分组卡片（无左侧花哨彩块，仅保留四态复选框）：
//       - App 缓存与日志 (`✓` 默认勾选安全项)
//       - 通讯工具 (`—` 聊天图片视频默认不勾选，防误删过期媒体)
//       - 开发工具 (`—` 构建缓存按推荐勾选)
//       - AI 工具 (`✓` 保留对话、项目和本地模型)
//       - 设计缓存 (`✓` 作品本身不受影响)
//       - 卸载残留 (`☐` 默认 0 勾选，供用户确认)
//       - 系统数据 (`—` 系统缓存、诊断日志和本地快照)
//       - 手动管理 (`•` 锁定圆点，仅显示占用，不参与自动清理)
//    3. 卡片右侧大小格式：
//       - 全选时仅显示 `Total`（如 `2.35 GB`）
//       - 部分勾选或未勾选时显示 `Selected / Total`（如 `22.8 GB / 34.3 GB`、`0 KB / 643 MB`）
//    4. 底部操作栏：
//       - 左侧：`已选 N 项   全选 · 全不选 · 推荐`
//       - 右侧：高对比度白色胶囊大按钮 `移到废纸篓 · 30.8 GB`（底层 100% 走废纸篓安全防线）
// ============================================================

struct SmartCleanView: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var config = AppConfigStore.shared
    @ObservedObject var l10n = L10n.shared

    @State var expandedSections: Set<SmartCleanSectionKind> = []
    @State var expandedAppGroupIDs: Set<String> = []
    @State var expandedSubcategoryIDs: Set<String> = []
    @State var didInitExpandedGroupsForSection: Set<SmartCleanSectionKind> = []
    @State var didApplyInitialCleanDefaults = false
    @State var activeSnapshot: SmartCleanSnapshotCache.Snapshot = SmartCleanSnapshotCache.shared.currentSnapshot
    @State var detailGroupsBySectionKey: [String: [SmartAppCacheGroup]] = [:]
    @State var cachedOccupyingApps: [NSRunningApplication] = SmartCleanSnapshotCache.shared.cachedOccupyingApps
    @State var runningApplicationsByBundleID: [String: NSRunningApplication] = SmartCleanSnapshotCache.shared.runningApplicationsByBundleID
    @State var occupancyGeneration: UInt64 = 0
    @State var inspectingSectionKind: SmartCleanSectionKind? = nil
    @State var pulseHero = false
    var currentProfile: CleaningProfile { state.cleaningProfile }
    var selectedProfiles: Set<CleaningProfile> { state.selectedProfiles }
    @State var showsProfileDropdown = false
    @State var showsRunningAppsSheet = false
    @State var restoredItemIDs: Set<String> = []
    @State var undoSucceeded = false
    @State var undoInProgress = false

    var currentSnapshot: SmartCleanSnapshotCache.Snapshot {
        guard !state.roots.isEmpty else { return .empty }
        // 单次 body 求值会读十余次 currentSnapshot，绝不能让每一次都重跑全树递归哈希；
        // 这里直连记忆化指纹，同时作为「缓存文件被回滚」的编译期哨兵。
        let expectedSig = SmartCleanSignatureMemo.signature(
            for: state.roots,
            resultVersion: 0,
            policyVersion: CleanupSelectionPolicy.policyVersion
        )
        let cached = SmartCleanSnapshotCache.shared.currentSnapshot
        if cached.signature == expectedSig {
            return cached
        }
        if activeSnapshot.signature == expectedSig {
            return activeSnapshot
        }
        return .empty
    }

    var currentInspectingSection: SmartCleanSectionData? {
        guard let kind = inspectingSectionKind else { return nil }
        return sections.first { $0.kind == kind }
    }

    // MARK: - 8 大语义分区聚合

    var sections: [SmartCleanSectionData] {
        currentSnapshot.sections
    }

    var cachedProfileSelections: [CleaningProfile: Set<UUID>] {
        currentSnapshot.profileSelections
    }

    var cachedProfileDeltas: [CleaningProfile: Int64] {
        currentSnapshot.profileDeltas
    }

    func buildSections(roots: [Node]? = nil) -> [SmartCleanSectionData] {
        SmartCleanSnapshotCache.buildSections(from: roots ?? state.roots)
    }

    func recomputeSections(roots: [Node]? = nil, forceOccupancyRefresh: Bool = false) {
        let targetRoots = roots ?? state.roots
        let cache = SmartCleanSnapshotCache.shared
        if let hit = cache.cachedSnapshot(for: targetRoots) {
            if activeSnapshot.signature != hit.signature {
                activeSnapshot = hit
            }
            if !state.scanning && !targetRoots.isEmpty && !state.didApplyDefaultsCurrentModule {
                applyRecommendedSelection()
                state.didApplyDefaultsCurrentModule = true
            }
            let now = ProcessInfo.processInfo.systemUptime
            if forceOccupancyRefresh
                || hit.signature != cache.lastOccupancyRefreshSignature
                || (now - cache.lastOccupancyRefreshTime) > 15.0 {
                cache.lastOccupancyRefreshSignature = hit.signature
                cache.lastOccupancyRefreshTime = now
                refreshOccupyingApps(in: hit.sections)
            } else if cachedOccupyingApps != cache.cachedOccupyingApps {
                cachedOccupyingApps = cache.cachedOccupyingApps
            }
            return
        }

        guard !state.scanning else { return }

        cache.rebuildSnapshotAsync(roots: targetRoots) { built in
            self.activeSnapshot = built
            if !self.state.scanning && !targetRoots.isEmpty && !self.state.didApplyDefaultsCurrentModule {
                self.applyRecommendedSelection()
                self.state.didApplyDefaultsCurrentModule = true
            }
            let now = ProcessInfo.processInfo.systemUptime
            if forceOccupancyRefresh
                || built.signature != cache.lastOccupancyRefreshSignature
                || (now - cache.lastOccupancyRefreshTime) > 15.0 {
                cache.lastOccupancyRefreshSignature = built.signature
                cache.lastOccupancyRefreshTime = now
                self.refreshOccupyingApps(in: built.sections)
            }
        }
    }

    func refreshOccupyingApps(in sections: [SmartCleanSectionData]) {
        let leafBlob = sections
            .filter { !$0.kind.isManualStorage }
            .flatMap(\.selectableLeaves)
            .prefix(200)
            .map { "\($0.name.lowercased()) \($0.path.lowercased())" }
            .joined(separator: " ")

        occupancyGeneration &+= 1
        let generation = occupancyGeneration
        guard !leafBlob.isEmpty else {
            cachedOccupyingApps = []
            runningApplicationsByBundleID = [:]
            SmartCleanSnapshotCache.shared.cachedOccupyingApps = []
            SmartCleanSnapshotCache.shared.runningApplicationsByBundleID = [:]
            return
        }

        // NSWorkspace/AppKit objects stay on the main actor. Only immutable strings
        // cross to the worker queue for the potentially repeated matching work.
        let ownBundleID = Bundle.main.bundleIdentifier ?? "com.personal.aclean"
        var candidates: [SmartRunningAppCandidate] = []
        var applicationsByBundleID: [String: NSRunningApplication] = [:]
        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular,
                  let bundleID = app.bundleIdentifier,
                  bundleID != ownBundleID,
                  !bundleID.hasPrefix("com.apple.finder"),
                  let name = app.localizedName,
                  !name.isEmpty else { continue }
            candidates.append(SmartRunningAppCandidate(bundleID: bundleID, name: name))
            applicationsByBundleID[bundleID] = app
        }
        let candidatesSnapshot = candidates
        runningApplicationsByBundleID = applicationsByBundleID
        SmartCleanSnapshotCache.shared.runningApplicationsByBundleID = applicationsByBundleID

        DispatchQueue.global(qos: .userInitiated).async {
            let matchedBundleIDs = SmartRunningAppMatcher.matchingBundleIDs(
                leafBlob: leafBlob,
                candidates: candidatesSnapshot
            )
            DispatchQueue.main.async {
                guard self.occupancyGeneration == generation else { return }
                let matchedApps = matchedBundleIDs.compactMap { self.runningApplicationsByBundleID[$0] }
                self.cachedOccupyingApps = matchedApps
                SmartCleanSnapshotCache.shared.cachedOccupyingApps = matchedApps
            }
        }
    }

    // MARK: - 统计与运行中占用缓存 App 检测

    var cleanableItems: [Node] {
        currentSnapshot.cleanableItems
    }

    var cleanableLeaves: [Node] {
        currentSnapshot.cleanableLeaves
    }

    var selectedCleanableLeaves: [Node] {
        cleanableLeaves.filter { state.selection.contains($0.id) }
    }

    var selectedCleanableSize: Int64 {
        let sizeMap = currentSnapshot.leafSizeByID
        var sum: Int64 = 0
        for id in state.selection {
            if let sz = sizeMap[id] {
                sum += sz
            }
        }
        return sum
    }

    var selectedCleanableCount: Int {
        sections.reduce(0) { acc, sec in
            acc + sec.cleanableItemLeafIDs.filter { !$0.isDisjoint(with: state.selection) }.count
        }
    }

    var activeSectionCount: Int {
        currentSnapshot.activeSectionCount
    }

    var totalCleanableSize: Int64 {
        currentSnapshot.totalCleanableSize
    }

    var totalCleanableCount: Int {
        currentSnapshot.totalCleanableCount
    }

    var runningAppsOccupyingCache: [NSRunningApplication] {
        cachedOccupyingApps
    }

    var totalProtectedSize: Int64 {
        currentSnapshot.totalProtectedSize
    }

    var activeOccupyingRunningApps: [NSRunningApplication] {
        guard !cachedOccupyingApps.isEmpty else { return [] }
        let leaves = selectedCleanableLeaves
        guard !leaves.isEmpty else { return [] }
        let selectedBlob = leaves.prefix(200).map { "\($0.name.lowercased()) \($0.path.lowercased())" }.joined(separator: " ")
        return cachedOccupyingApps.filter { app in
            guard let name = app.localizedName?.lowercased(), !name.isEmpty else { return false }
            let bid = (app.bundleIdentifier ?? "").lowercased()
            return (!bid.isEmpty && selectedBlob.contains(bid)) || (name.count >= 3 && selectedBlob.contains(name))
        }
    }

    func quitOccupyingApps() {
        let apps = runningAppsOccupyingCache
        guard !apps.isEmpty else { return }
        for app in apps {
            app.terminate()
        }
        let names = apps.compactMap(\.localizedName).joined(separator: "、")
        state.toast = "\(L10n.localized(.statusQuitRequested)) \(names)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.recomputeSections(forceOccupancyRefresh: true)
        }
    }

    func quitOccupyingAppsAndClean() {
        let apps = activeOccupyingRunningApps
        showsRunningAppsSheet = false
        for app in apps {
            app.terminate()
        }
        let names = apps.compactMap(\.localizedName).joined(separator: "、")
        state.toast = "\(L10n.localized(.statusQuitRequested)) \(names)"
        Task { @MainActor in
            let deadline = Date().addingTimeInterval(AppConfig.Security.appTerminationTimeout)
            while apps.contains(where: { !$0.isTerminated }) && Date() < deadline {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled { return }
            }
            guard apps.allSatisfy(\.isTerminated) else {
                state.toast = L10n.localized(.safetyInspectionIncomplete)
                return
            }
            state.commitClean(category: nil)
        }
    }

    func skipOccupyingAppsAndClean() {
        let apps = activeOccupyingRunningApps
        showsRunningAppsSheet = false
        var matchBIDs: [String] = []
        var matchNames: [String] = []
        for app in apps {
            if let bid = app.bundleIdentifier?.lowercased(), !bid.isEmpty {
                matchBIDs.append(bid)
            }
            if let name = app.localizedName?.lowercased(), name.count >= 2 {
                matchNames.append(name)
            }
        }
        var nextSelection = state.selection
        for leaf in cleanableLeaves {
            let lowerName = leaf.name.lowercased()
            let lowerPath = leaf.path.lowercased()
            let pathSegments = lowerPath.split(separator: "/").map(String.init)
            let isMatched = matchBIDs.contains(where: { lowerName.contains($0) || lowerPath.contains($0) })
                || matchNames.contains(where: { name in
                    lowerName.contains(name) || pathSegments.contains(where: { $0 == name || $0.hasPrefix(name + ".") || $0.hasSuffix("." + name) })
                })
            if isMatched {
                nextSelection.remove(leaf.id)
            }
        }
        state.selection = nextSelection
        state.commitClean(category: nil)
    }

    // MARK: - 视图主体 (三幕剧舞台架构: 待命态 -> 扫描中 -> 结果态)

    var body: some View {
        ZStack(alignment: .trailing) {
            if state.screen == .cleaning {
                cleanCleaningStageView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if state.screen == .complete, let rep = state.report {
                cleanCompleteStageView(report: rep)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if state.scanning {
                cleanScanningStageView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if state.roots.isEmpty {
                if state.hasOptimizedCurrentModule || state.hasScannedCurrentModule {
                    cleanEmptyStageView
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    cleanIdleStageView
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            } else {
                cleanResultStageView
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let bannerText = state.activeScanDegradationBanner {
                Label(
                    bannerText,
                    systemImage: state.hasRuleDatabaseDegradation ? "exclamationmark.shield.fill" : "exclamationmark.triangle"
                )
                    .font(.system(size: 12)).foregroundStyle(Theme.amber)
                    .padding(8).frame(maxWidth: .infinity)
                    .background(Theme.card)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: state.scanning)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: inspectingSectionKind)
        .onAppear {
            state.checkFullDiskAccess()
            recomputeSections()
            if !state.scanning && !state.roots.isEmpty && !state.didApplyDefaultsCurrentModule {
                applyRecommendedSelection()
                state.didApplyDefaultsCurrentModule = true
            }
        }
        .onReceive(state.$roots.dropFirst()) { roots in
            guard !state.isSwitchingModule, state.moduleKey == .junk else { return }
            recomputeSections(roots: roots)
        }
        .onChange(of: state.report?.id) { _ in
            undoSucceeded = false
            undoInProgress = false
            restoredItemIDs = []
        }
        .onChange(of: state.scanning) { isScanning in
            guard !state.isSwitchingModule, state.moduleKey == .junk else { return }
            recomputeSections()
            if !isScanning && !state.roots.isEmpty && !state.didApplyDefaultsCurrentModule {
                applyRecommendedSelection()
                state.didApplyDefaultsCurrentModule = true
            }
        }
        .sheet(isPresented: $showsRunningAppsSheet) {
            runningAppsPromptSheet
        }
    }

    // MARK: - 运行中 App 前置决策弹窗 (Sheet)

    var runningAppsPromptSheet: some View {
        SmartCleanRunningAppsSheet(
            apps: activeOccupyingRunningApps,
            onCancel: { showsRunningAppsSheet = false },
            onSkipAndClean: { skipOccupyingAppsAndClean() },
            onQuitAndClean: { quitOccupyingAppsAndClean() }
        )
    }
}

typealias JunkCleanView = SmartCleanView
typealias JunkSectionKind = SmartCleanSectionKind
typealias JunkSection = SmartCleanSectionData
typealias RunningAppCandidate = SmartRunningAppCandidate
typealias RunningAppMatcher = SmartRunningAppMatcher
typealias JunkCleanRow = SmartNextGenCleanRow
typealias AppCacheGroup = SmartAppCacheGroup
typealias AppCacheGroupBuilder = SmartAppGroupBuilder
typealias AppCacheGroupView = SmartAppCacheGroupView
typealias JunkLeafRow = SmartCleanLeafRow
