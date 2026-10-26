import SwiftUI
import AppKit

// ============================================================
//  SmartDeclutterView —— 整理杂乱模块（极简卡片式设计）
//
//  视觉与交互特征（统一极简卡片设计语言）：
//    1. 顶部区域：
//       - 左侧大标题「整理杂乱」，副标题「可清理 X GB · N 项 · 5 类 · 大文件 ≥100MB / 3个月」
//       - 右上角仅保留阈值菜单图标、`↻`（重新扫描）与 `⊗`（重置选择）极简图标按钮
//    2. 5 大人类语义卡片（无花哨彩块，左侧四态复选框 + 标题 + `已选 X/Y` + 后果说明 + 右侧 `Selected / Total` 体积 + `⌄`）：
//       - 大型和旧文件（默认 0 勾选 `☐`，供用户确认后清理）
//       - 重复文件（默认勾选除每组原件外的重复副本 `—`）
//       - 相似图片（默认勾选除每组最佳原图外的相似副本 `—`）
//       - 下载项（默认勾选安全过期项 `—`）
//       - 安装包（默认全选 `.dmg` / `.pkg` 安装镜像 `✓`）
//    3. 底部操作栏：
//       - 左侧：`已选 N 项   全选 · 全不选 · 推荐`
//       - 右侧：高对比度白色胶囊大按钮 `移到废纸篓 · X GB`
// ============================================================

enum SmartDeclutterSectionKind: String, CaseIterable, Identifiable {
    case installers     = "installers"
    case duplicates     = "duplicates"
    case similarPhotos  = "similarPhotos"
    case downloads      = "downloads"
    case largeOldFiles  = "largeOldFiles"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .installers:    return tr(.declutterInstallers)
        case .duplicates:    return tr(.declutterDuplicates)
        case .similarPhotos: return tr(.declutterSimilarPhotos)
        case .downloads:     return tr(.declutterDownloads)
        case .largeOldFiles: return tr(.declutterLargeAndOldFiles)
        }
    }

    var subtitle: String {
        switch self {
        case .installers:
            return L10n.localized(.leftoverDmgAndPkgInstallersAfterSetupCleaningDoesNotAffectInstalledApps)
        case .duplicates:
            return L10n.localized(.exactDuplicatesVerifiedBySha256OldestOriginalKeptByDefault)
        case .similarPhotos:
            return L10n.localized(.burstShotsOrVisuallySimilarPhotosHighestQualityKeptByDefault)
        case .downloads:
            return L10n.localized(.oldArchivesDocumentsAndTemporaryDownloadsInDownloadsFolder)
        case .largeOldFiles:
            return L10n.localized(.largeOrLongUnopenedFilesConfirmTheyAreNoLongerNeededBeforeCleaning)
        }
    }
}

struct SmartDeclutterSectionData: Identifiable {
    let kind: SmartDeclutterSectionKind
    var items: [Node]
    var id: String { kind.rawValue }
    let totalSize: Int64
    var totalCount: Int { items.count }

    init(kind: SmartDeclutterSectionKind, items: [Node]) {
        self.kind = kind
        self.items = items
        self.totalSize = items.reduce(0) { $0 + $1.totalSize }
    }
}

struct SmartDeclutterSelectionSummary {
    var selectableCount = 0
    var selectedCount = 0
    var selectedSize: Int64 = 0
}

struct SmartDeclutterView: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var config = AppConfigStore.shared
    @ObservedObject var l10n = L10n.shared

    @State var expandedSections: Set<SmartDeclutterSectionKind> = []
    @State var didApplyInitialDefaults = false
    @State var inspectingSectionKind: SmartDeclutterSectionKind? = nil
    @State var pulseHero = false

    var currentInspectingSection: SmartDeclutterSectionData? {
        guard let kind = inspectingSectionKind else { return nil }
        return sections.first { $0.kind == kind }
    }

    @State var cachedSections: [SmartDeclutterSectionData] = []
    @State var hasCachedSections = false
    @State var cachedSelectableLeaves: [Node] = []
    @State var cachedSelectedLeaves: [Node] = []
    @State var cachedSelectedSize: Int64 = 0
    @State var cachedSelectionBySection: [SmartDeclutterSectionKind: SmartDeclutterSelectionSummary] = [:]

    var sections: [SmartDeclutterSectionData] {
        hasCachedSections ? cachedSections : buildSections()
    }

    func recomputeSections() {
        cachedSections = buildSections()
        hasCachedSections = true
        recomputeSelectionSummaries()
    }

    func recomputeSelectionSummaries() {
        let currentSections = sections
        let selectedIDs = state.selection
        var selectable: [Node] = []
        var selected: [Node] = []
        var selectedSize: Int64 = 0
        var summaries: [SmartDeclutterSectionKind: SmartDeclutterSelectionSummary] = [:]

        for section in currentSections {
            var summary = SmartDeclutterSelectionSummary()
            for item in section.items where isDeclutterSelectable(item) {
                selectable.append(item)
                summary.selectableCount += 1
                if selectedIDs.contains(item.id) {
                    selected.append(item)
                    selectedSize += item.totalSize
                    summary.selectedCount += 1
                    summary.selectedSize += item.totalSize
                }
            }
            summaries[section.kind] = summary
        }

        cachedSelectableLeaves = selectable
        cachedSelectedLeaves = selected
        cachedSelectedSize = selectedSize
        cachedSelectionBySection = summaries
    }

    func buildSections() -> [SmartDeclutterSectionData] {
        var buckets: [SmartDeclutterSectionKind: [Node]] = [:]
        for kind in SmartDeclutterSectionKind.allCases {
            buckets[kind] = []
        }

        for root in state.roots {
            let kind = classifyRoot(root)
            buckets[kind, default: []].append(contentsOf: root.leaves)
        }

        return SmartDeclutterSectionKind.allCases.map { kind in
            let rawItems = buckets[kind] ?? []
            let items: [Node]
            switch kind {
            case .duplicates, .similarPhotos:
                // 保持每个重复/相似簇的原始分组顺序（首项为「将保留」原件，后续为同簇副本）
                items = rawItems
            default:
                items = rawItems.sorted { $0.totalSize > $1.totalSize }
            }
            return SmartDeclutterSectionData(kind: kind, items: items)
        }
    }

    func classifyRoot(_ root: Node) -> SmartDeclutterSectionKind {
        let tagSet = Set(root.tags)
        let name = root.name
        if tagSet.contains(L10n.localized(.declutterInstallers)) || tagSet.contains("Installers") || name.contains(L10n.localized(.declutterInstallers)) || name.contains("Installers") {
            return .installers
        }
        if tagSet.contains(L10n.localized(.declutterDuplicates)) || tagSet.contains("Duplicates") || name.contains(L10n.localized(.declutterDuplicates)) || name.contains("Duplicates") {
            return .duplicates
        }
        if tagSet.contains(L10n.localized(.similarImages)) || tagSet.contains("Similar Images") || name.contains(L10n.localized(.similarImages)) || name.contains("Similar") {
            return .similarPhotos
        }
        if tagSet.contains(L10n.localized(.declutterDownloads)) || tagSet.contains("Downloads") || name.contains(L10n.localized(.declutterDownloads)) || name.contains("Downloads") {
            return .downloads
        }
        return .largeOldFiles
    }

    /// 判断节点是否为重复文件或相似图片簇中需要保留的原件（禁止被批量「全选」误勾选）
    static func isKeptOriginal(_ item: Node) -> Bool {
        item.isRetainedOriginal
    }

    func isDeclutterSelectable(_ item: Node) -> Bool {
        state.isSelectableForClean(item) && !Self.isKeptOriginal(item)
    }

    var allSelectableLeaves: [Node] {
        hasCachedSections ? cachedSelectableLeaves : sections.flatMap(\.items).filter { isDeclutterSelectable($0) }
    }

    var selectedLeaves: [Node] {
        hasCachedSections ? cachedSelectedLeaves : sections.flatMap(\.items).filter { isDeclutterSelectable($0) && state.selection.contains($0.id) }
    }

    var selectedSize: Int64 {
        hasCachedSections ? cachedSelectedSize : selectedLeaves.reduce(0) { $0 + $1.totalSize }
    }

    var activeSectionCount: Int {
        sections.filter { !$0.items.isEmpty }.count
    }

    // MARK: - 视图主体 (三幕剧舞台架构: 待命态 -> 扫描中 -> 结果态)

    var body: some View {
        ZStack(alignment: .trailing) {
            if state.screen == .cleaning {
                declutterCleaningStageView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if state.screen == .complete, let rep = state.report {
                declutterCompleteStageView(report: rep)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if state.scanning {
                declutterScanningStageView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if state.roots.isEmpty {
                if state.hasOptimizedCurrentModule || state.hasScannedCurrentModule {
                    declutterEmptyStageView
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    declutterIdleStageView
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            } else {
                declutterResultStageView
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if state.hasIncompleteScanCoverage && !state.scanning && state.report == nil {
                Label(L10n.localized(.scanCoverageIncomplete), systemImage: "exclamationmark.triangle")
                    .font(.system(size: 12)).foregroundStyle(Theme.amber)
                    .padding(8).frame(maxWidth: .infinity)
                    .background(Theme.card)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: state.scanning)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: inspectingSectionKind)
        .onAppear {
            recomputeSections()
            if !state.scanning && !state.roots.isEmpty && !state.didApplyDefaultsCurrentModule {
                applyRecommendedSelection()
                state.didApplyDefaultsCurrentModule = true
            }
        }
        .onReceive(state.$roots.dropFirst()) { _ in
            guard state.moduleKey == "organize" else { return }
            recomputeSections()
        }
        .onChange(of: state.scanning) { isScanning in
            recomputeSections()
            if !isScanning && !state.roots.isEmpty && !state.didApplyDefaultsCurrentModule {
                applyRecommendedSelection()
                state.didApplyDefaultsCurrentModule = true
            }
        }
        .onChange(of: state.selection) { _ in
            recomputeSelectionSummaries()
        }
    }

    // MARK: - 0. 顶部统一标题栏（与系统监控完全对齐的左上角标题与规格副标题）

    var topHeaderStrip: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.localized(.moduleDeclutter))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.text)

                if state.roots.isEmpty {
                    Text(L10n.localized(.declutterHeroScanSubtitle))
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                } else {
                    let appliedMB = state.appliedLargeFileThresholdMB
                    let appliedMonths = state.appliedOldFileMonths
                    Text("\(L10n.localized(.cleanableTag)) \(Fmt.size(selectedSize)) · \(selectedLeaves.count) \(L10n.localized(.unitItems)) · \(activeSectionCount) \(L10n.localized(.unitCategories)) · \(L10n.localized(.labelThreshold)): ≥\(appliedMB >= 1024 ? "1GB" : "\(appliedMB)MB") / \(appliedMonths)\(L10n.localized(.unitMonths))")
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                        .monospacedDigit()
                }
            }

            Spacer(minLength: 12)

            if state.roots.isEmpty {
                idleThresholdMenu
            } else {
                HStack(spacing: 10) {
                    thresholdInlineMenu

                    HeaderIconButton(
                        icon: "arrow.clockwise",
                        spinning: state.scanning,
                        helpText: L10n.localized(.actionRescan)
                    ) {
                        inspectingSectionKind = nil
                        expandedSections.removeAll()
                        state.didApplyDefaultsCurrentModule = false
                        state.startScan(for: "organize", forceRestart: true)
                    }
                }
            }
        }
    }

    // MARK: - 第一幕：待命态 (Act 1: Idle Stage)

    var declutterIdleStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Spacer(minLength: 6)

                    // 1. 核心悬浮脉冲球体（带整理图标与微光呼吸动效）
                    PulseOrbStageView(
                        isScanning: false,
                        sizeText: "",
                        unitText: "",
                        subtitle: L10n.localized(.statusReady),
                        themeColor: Theme.accent,
                        diameter: 140,
                        symbol: "folder.fill.badge.gearshape"
                    )

                    // 2. 标题与说明副标题
                    VStack(spacing: 6) {
                        Text(L10n.localized(.declutterHeroTitle))
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.text)

                        Text(L10n.localized(.declutterHeroSubtitle))
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.sub)
                    }

                    // 3. 5 大清理能力 Bento 预览卡片
                    HStack(spacing: 10) {
                        ForEach(SmartDeclutterSectionKind.allCases) { kind in
                            IdleDeclutterFeatureCard(kind: kind, tag: idleTag(for: kind))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 2)

                    // 4. 底部统一主操作扫描按钮 (GlowingPillButton 184x42)
                    GlowingPillButton(
                        title: L10n.localized(.declutterStartAction),
                        icon: "sparkles",
                        tint: Theme.accent,
                        width: 184,
                        height: 42
                    ) {
                        expandedSections.removeAll()
                        state.didApplyDefaultsCurrentModule = false
                        state.startScan(for: "organize", forceRestart: true)
                    }
                    .padding(.top, 4)

                    // 5. 安全保障标语
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.accent.opacity(0.85))
                        Text(L10n.localized(.declutterSafetyNote))
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.tert)
                    }
                    .padding(.top, 2)

                    Spacer(minLength: 8)
                }
                .frame(maxWidth: .infinity, minHeight: 460)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func idleTag(for kind: SmartDeclutterSectionKind) -> String {
        switch kind {
        case .installers:
            return L10n.localized(.tagDmgPkgImages)
        case .duplicates:
            return L10n.localized(.tagSha256Match)
        case .similarPhotos:
            return L10n.localized(.tagPerceptualHashMatch)
        case .downloads:
            return L10n.localized(.tagHistoricalArchives)
        case .largeOldFiles:
            return "≥\(state.largeFileThresholdMB >= 1024 ? "1GB" : "\(state.largeFileThresholdMB)MB")"
        }
    }

    var idleThresholdMenu: some View {
        Menu {
            Section(L10n.localized(.thresholdLargeFileMinSize)) {
                ForEach([50, 100, 250, 500, 1024], id: \.self) { mb in
                    Button {
                        state.largeFileThresholdMB = mb
                    } label: {
                        HStack {
                            Text(mb >= 1024 ? "≥ 1 GB" : "≥ \(mb) MB")
                            if state.largeFileThresholdMB == mb {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            Section(L10n.localized(.thresholdOldFileMonths)) {
                ForEach([1, 3, 6, 12], id: \.self) { m in
                    Button {
                        state.oldFileMonths = m
                    } label: {
                        HStack {
                            Text("≥ \(m) \(L10n.localized(.unitMonths))")
                            if state.oldFileMonths == m {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.accent)
                Text("\(L10n.localized(.labelThreshold)): ≥\(state.largeFileThresholdMB >= 1024 ? "1GB" : "\(state.largeFileThresholdMB)MB") / \(state.oldFileMonths)\(L10n.localized(.unitMonths))")
                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.text)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.sub.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Theme.card)
                    .overlay(
                        Capsule().strokeBorder(Theme.sep, lineWidth: 1)
                    )
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: - 第二幕：扫描中 (Act 2: Scanning Stage)

    var declutterScanningStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 34)
                .padding(.top, 24)
                .padding(.bottom, 6)

            VStack(spacing: 26) {
                Spacer()

                PulseOrbStageView(
                    isScanning: true,
                    sizeText: "\(Int(state.scanProgress * 100))",
                    unitText: "%",
                    subtitle: L10n.localized(.statusDeepDiagnosing),
                    themeColor: Theme.accent,
                    diameter: 220
                )

                VStack(spacing: 10) {
                    Text(L10n.localized(.declutterScanningTitle))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)

                    Text(state.scanStatus.isEmpty ? L10n.localized(.declutterScanningSubtitle) : state.scanStatus)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 520)
                }

                Button {
                    state.stopScan()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 12))
                        Text(L10n.localized(.actionStopScanning))
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .foregroundStyle(Theme.sub)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Theme.card.opacity(0.8))
                            .overlay(Capsule().strokeBorder(Theme.sep, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 清理中 (Cleaning Stage)

    var declutterCleaningStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 34)
                .padding(.top, 24)
                .padding(.bottom, 6)

            VStack(spacing: 26) {
                Spacer()

                PulseOrbStageView(
                    isScanning: true,
                    sizeText: "\(Int(state.cleanProgress * 100))",
                    unitText: "%",
                    subtitle: "\(state.cleanDone) / \(state.cleanTotal)",
                    themeColor: Theme.accent,
                    diameter: 220
                )

                VStack(spacing: 10) {
                    Text(L10n.localized(.statusCleaning))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)

                    Text(state.cleanCurrent.isEmpty ? L10n.localized(.statusCleaning) : state.cleanCurrent)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 520)
                }

                Button {
                    state.stopClean()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 12))
                        Text(L10n.localized(.actionStopCleaning))
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .foregroundStyle(Theme.sub)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Theme.card.opacity(0.8))
                            .overlay(Capsule().strokeBorder(Theme.sep, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
    }

    // MARK: - 清理完成结果态 (Complete Stage)

    func declutterCompleteStageView(report: CleanReport) -> some View {
        let isSuccess = report.state == .success
        let displayBytes = report.actualFreedBytes > 0
            ? report.actualFreedBytes
            : (report.permanentlyDeletedBytes > 0
                ? report.permanentlyDeletedBytes
                : (report.movedToTrashBytes > 0 ? report.movedToTrashBytes : report.reportedReclaimedBytes))
        let sizeParts = Fmt.sizeParts(displayBytes)

        let subtitleText: String
        if report.state == .cancelled {
            subtitleText = L10n.localized(.cleanupCancelledResult)
        } else if report.state == .partial {
            subtitleText = L10n.localized(.cleanupPartialResult)
        } else if !isSuccess {
            subtitleText = L10n.localized(.statusOperationCancelledOrFailed)
        } else if report.actualFreedBytes > 0 && report.movedToTrashBytes > 0 {
            subtitleText = L10n.format(.receiptReclaimedAndTrashedFormat, Fmt.size(report.actualFreedBytes), Fmt.size(report.movedToTrashBytes))
        } else if report.actualFreedBytes > 0 {
            subtitleText = L10n.format(.receiptDiskSpaceFreedFormat, Fmt.size(report.actualFreedBytes))
        } else if report.permanentlyDeletedBytes > 0 && report.movedToTrashBytes > 0 {
            subtitleText = L10n.format(.receiptPermanentlyDeletedAndTrashedFormat, Fmt.size(report.permanentlyDeletedBytes), Fmt.size(report.movedToTrashBytes))
        } else if report.permanentlyDeletedBytes > 0 {
            subtitleText = L10n.format(.receiptPermanentlyDeletedFormat, Fmt.size(report.permanentlyDeletedBytes))
        } else if report.movedToTrashBytes > 0 {
            subtitleText = L10n.format(.receiptMovedToTrashFormat, Fmt.size(report.movedToTrashBytes))
        } else {
            subtitleText = L10n.localized(.statusCleanCompleted)
        }

        var receiptParts = [L10n.format(.cleanupOutcomeCountsFormat, report.okCount, report.errorCount, report.skippedCount, report.cancelledCount)]
        if report.movedToTrashBytes > 0 {
            receiptParts.append(L10n.format(.receiptMovedToTrashTagFormat, Fmt.size(report.movedToTrashBytes)))
        }
        if report.permanentlyDeletedBytes > 0 {
            receiptParts.append(L10n.format(.receiptPermanentlyDeletedTagFormat, Fmt.size(report.permanentlyDeletedBytes)))
        }
        if report.reportedReclaimedBytes > 0 {
            receiptParts.append(L10n.format(.receiptToolReportedFormat, Fmt.size(report.reportedReclaimedBytes)))
        }
        if report.actualFreedBytes > 0 {
            receiptParts.append(L10n.format(.receiptReclaimedTagFormat, Fmt.size(report.actualFreedBytes)))
        }
        let detailText = receiptParts.joined(separator: " · ")

        return VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 34)
                .padding(.top, 24)
                .padding(.bottom, 6)

            VStack(spacing: 24) {
                Spacer()

                PulseOrbStageView(
                    isScanning: false,
                    sizeText: sizeParts.value,
                    unitText: sizeParts.unit,
                    subtitle: subtitleText,
                    themeColor: isSuccess ? Color.green : Color.orange,
                    diameter: 200,
                    symbol: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )

                VStack(spacing: 8) {
                    Text(isSuccess ? L10n.localized(.statusCleanCompleted) : L10n.localized(.statusOperationCancelledOrFailed))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)

                    Text(detailText)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.sub)
                    if report.outcomes.contains(where: { $0.failureKind == .permission }) {
                        Button(L10n.localized(.permissionGrantFullDiskAccessTitle)) {
                            state.requestCleanupPermissionRetry()
                        }
                    }
                    if report.restorePersistenceFailed {
                        Text(L10n.localized(.reviewRestoreNotSaved)).foregroundStyle(Theme.sub)
                    }
                    if report.failCount > 0 {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(report.outcomes.filter { !$0.ok }) { outcome in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(outcome.path.isEmpty ? outcome.name : outcome.path)
                                            .textSelection(.enabled)
                                        Text(outcome.error ?? L10n.localized(.statusOperationCancelledOrFailed))
                                            .foregroundStyle(Theme.sub)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    }
                }

                HStack(spacing: 14) {
                    if report.movedToTrashBytes > 0 { CleanupUndoButton(report: report).id(report.id) }
                    GlowingPillButton(
                        title: L10n.localized(.actionRescan),
                        icon: "arrow.clockwise",
                        tint: Theme.accent,
                        width: 170,
                        height: 44
                    ) {
                        inspectingSectionKind = nil
                        expandedSections.removeAll()
                        state.report = nil
                        state.screen = .dataManager
                        state.didApplyDefaultsCurrentModule = false
                        state.startScan(for: "organize", forceRestart: true)
                    }

                    Button {
                        let trashURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
                        NSWorkspace.shared.open(trashURL)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                            Text(L10n.localized(.actionOpenTrashInFinder))
                                .font(.system(size: 12.5, weight: .medium))
                        }
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Theme.card.opacity(0.85))
                                .overlay(Capsule().strokeBorder(Theme.sep, lineWidth: 1))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
    }

    // MARK: - 极简 0 杂乱状态 (Empty Stage)

    var declutterEmptyStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 34)
                .padding(.top, 24)
                .padding(.bottom, 6)

            VStack(spacing: 24) {
                Spacer()

                PulseOrbStageView(
                    isScanning: false,
                    sizeText: "0",
                    unitText: "B",
                    subtitle: L10n.localized(.systemSpotlessTitle),
                    themeColor: Color.green,
                    diameter: 200,
                    symbol: "checkmark.seal.fill"
                )

                VStack(spacing: 8) {
                    Text(L10n.localized(.systemSpotlessTitle))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)

                    Text(L10n.localized(.systemSpotlessSubtitle))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.sub)
                }

                GlowingPillButton(
                    title: L10n.localized(.actionRescan),
                    icon: "arrow.clockwise",
                    tint: Theme.accent,
                    width: 170,
                    height: 44
                ) {
                    inspectingSectionKind = nil
                    expandedSections.removeAll()
                    state.report = nil
                    state.screen = .dataManager
                    state.didApplyDefaultsCurrentModule = false
                    state.startScan(for: "organize", forceRestart: true)
                }
                .padding(.top, 8)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
    }
}

typealias OrganizeView = SmartDeclutterView
typealias OrganizeSectionKind = SmartDeclutterSectionKind
typealias OrganizeSection = SmartDeclutterSectionData
typealias OrganizeSelectionSummary = SmartDeclutterSelectionSummary
typealias OrganizeRow = SmartNextGenDeclutterRow
typealias OrganizeLeafRow = SmartDeclutterLeafRow
