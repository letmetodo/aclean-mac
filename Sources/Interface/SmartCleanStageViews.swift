import SwiftUI
import AppKit

extension SmartCleanView {
    // MARK: - 清理完成结果态 (Complete Stage)

    func cleanCompleteStageView(report: CleanReport) -> some View {
        let isSuccess = report.state == .success
        let displayBytes = report.actualFreedBytes > 0 ? report.actualFreedBytes : (report.permanentlyDeletedBytes > 0 ? report.permanentlyDeletedBytes : report.movedToTrashBytes)
        let sizeParts = Fmt.sizeParts(displayBytes > 0 ? displayBytes : report.processedBytes)

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

                    // 累计值：让用户看到"长期有用"，而不只是这一次清了多少
                    if CleanHistoryStore.shared.totalBytes > 0 {
                        Text(L10n.format(.receiptLifetimeTotalFormat,
                                         Fmt.size(CleanHistoryStore.shared.totalBytes)))
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.tert)
                    }
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
                                        if let recoveryURL = outcome.recoveryURL {
                                            Button(recoveryURL.path) {
                                                NSWorkspace.shared.activateFileViewerSelecting([recoveryURL])
                                            }
                                            .buttonStyle(.plain)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(Theme.accent)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                    }
                }

                // MARK: 双重视角审计卡片 (Dual Perspective Audit Cards: 回收 vs 守护)
                HStack(spacing: 16) {
                    // 1. 已安全移入废纸篓 (Green)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.green)
                            Text(report.movedToTrashBytes > 0 ? L10n.localized(.actionOpenTrashInFinder) : L10n.localized(.statusCleanCompleted))
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(Theme.text)
                            Spacer()
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            let recParts = Fmt.sizeParts(displayBytes > 0 ? displayBytes : report.processedBytes)
                            Text(recParts.value)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.green)
                            Text(recParts.unit)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.sub)
                        }
                        Text(L10n.localized(.receiptApfsTrashNotice))
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.sub)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(Theme.card.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Theme.green.opacity(0.2), lineWidth: 1)
                    )

                    // 2. 已严格守护的核心资产 (Accent / Blue)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Theme.accent)
                            Text(L10n.localized(.receiptProtectedSummaryTitle))
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(Theme.text)
                            Spacer()
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            let protParts = Fmt.sizeParts(totalProtectedSize)
                            Text(protParts.value)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.accent)
                            Text(protParts.unit)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.sub)
                        }
                        Text(L10n.localized(.cleanProfileSafeDailyDesc))
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.sub)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(Theme.card.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Theme.accent.opacity(0.2), lineWidth: 1)
                    )
                }
                .frame(maxWidth: 580)

                HStack(spacing: 12) {
                    GlowingPillButton(
                        title: L10n.localized(.actionRescan),
                        icon: "arrow.clockwise",
                        tint: Theme.accent,
                        width: 150,
                        height: 42
                    ) {
                        undoSucceeded = false
                        undoInProgress = false
                        state.report = nil
                        state.screen = .dataManager
                        state.didApplyDefaultsCurrentModule = false
                        state.startScan(for: "junk", forceRestart: true)
                    }

                    if report.movedToTrashBytes > 0 {
                        Button {
                            undoCleanup(report: report)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: undoSucceeded ? "checkmark.circle.fill" : "arrow.uturn.backward")
                                    .font(.system(size: 12))
                                    .foregroundStyle(undoSucceeded ? Theme.green : Theme.text)
                                Text(undoSucceeded ? L10n.localized(.receiptUndoDone) : L10n.localized(.receiptUndoCleanupButton))
                                    .font(.system(size: 12.5, weight: .medium))
                            }
                            .foregroundStyle(Theme.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Theme.card.opacity(0.85))
                                    .overlay(Capsule().strokeBorder(undoSucceeded ? Theme.green.opacity(0.4) : Theme.sep, lineWidth: 1))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(undoSucceeded || undoInProgress)
                        .keyboardShortcut("z", modifiers: .command)
                        .help(L10n.localized(.receiptUndoWindowHint))
                        .accessibilityHint(L10n.localized(.receiptUndoWindowHint))
                    }

                    Button {
                        var locatedURLs: [URL] = []
                        for outcome in report.outcomes {
                            for u in outcome.trashedURLs where FileManager.default.fileExists(atPath: u.path) && !locatedURLs.contains(u) {
                                locatedURLs.append(u)
                            }
                            if let dest = outcome.destinationURL, FileManager.default.fileExists(atPath: dest.path), !locatedURLs.contains(dest) {
                                locatedURLs.append(dest)
                            }
                            if let rec = outcome.recoveryURL, FileManager.default.fileExists(atPath: rec.path), !locatedURLs.contains(rec) {
                                locatedURLs.append(rec)
                            }
                        }
                        if !locatedURLs.isEmpty {
                            NSWorkspace.shared.activateFileViewerSelecting(locatedURLs)
                        } else {
                            let trashURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
                            NSWorkspace.shared.open(trashURL)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                            Text(L10n.localized(.actionOpenTrashInFinder))
                                .font(.system(size: 12.5, weight: .medium))
                        }
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 14)
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

    // MARK: - 极简 0 垃圾状态 / 降级空状态 (Empty Stage)

    var cleanEmptyStageView: some View {
        let isRuleDegraded = state.hasRuleDatabaseDegradation
        let isSpotless = state.canPresentSpotlessEmptyState
        let stageTitle: String = {
            if isRuleDegraded {
                return L10n.localized(.ruleDatabaseUnavailableTitle)
            } else if !isSpotless {
                return L10n.localized(.safetyInspectionIncomplete)
            } else {
                return L10n.localized(.systemSpotlessTitle)
            }
        }()
        let stageSubtitle: String = {
            if isRuleDegraded {
                return L10n.localized(.ruleDatabaseUnavailableBanner)
            } else if !isSpotless {
                return L10n.localized(.scanCoverageIncomplete)
            } else {
                return L10n.localized(.systemSpotlessSubtitle)
            }
        }()
        let stageSymbol: String = {
            if isRuleDegraded {
                return "exclamationmark.shield.fill"
            } else if !isSpotless {
                return "exclamationmark.triangle.fill"
            } else {
                return "checkmark.seal.fill"
            }
        }()

        return VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 34)
                .padding(.top, 24)
                .padding(.bottom, 6)

            VStack(spacing: 24) {
                Spacer()

                PulseOrbStageView(
                    isScanning: false,
                    sizeText: isSpotless ? "0" : "!",
                    unitText: isSpotless ? "B" : "",
                    subtitle: stageTitle,
                    themeColor: isSpotless ? Color.green : Color.orange,
                    diameter: 200,
                    symbol: stageSymbol
                )

                VStack(spacing: 8) {
                    Text(stageTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)

                    Text(stageSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.sub)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 520)
                }

                GlowingPillButton(
                    title: L10n.localized(.actionRescan),
                    icon: "arrow.clockwise",
                    tint: Theme.accent,
                    width: 170,
                    height: 44
                ) {
                    state.report = nil
                    state.screen = .dataManager
                    state.didApplyDefaultsCurrentModule = false
                    state.startScan(for: "junk", forceRestart: true)
                }
                .padding(.top, 8)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
        }
    }

    // MARK: - 第三幕：结果态 (Act 3: Results Stage —— 1列全览 / 2列明细)

    var cleanResultStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 34)
                .padding(.top, 16)
                .padding(.bottom, 10)

            Divider().background(Theme.sep.opacity(0.5))

            GeometryReader { geo in
                let compactWidth = min(300, max(250, geo.size.width * 0.30))
                HStack(spacing: 0) {
                    // 分类列表：1列模式下占满100%全宽；2列模式下平滑收缩到左侧紧凑宽度
                    cleanCategoriesListView(isCompact: inspectingSectionKind != nil)
                        .frame(width: inspectingSectionKind == nil ? geo.size.width : compactWidth)
                        .frame(maxHeight: .infinity)

                    if let currentSection = currentInspectingSection {
                        Divider()
                            .background(Theme.sep.opacity(0.45))
                            .transition(.opacity)

                        // 详情列表：2列模式下占大部分页面展示要清理的文件夹明细
                        cleanCategoryDetailView(section: currentSection)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
            }

            cleanBottomBar
        }
    }

    var mainButtonTitle: String {
        guard !state.selection.isEmpty else { return L10n.localized(.actionCleanNow) }
        let actionMap = currentSnapshot.leafActionByID
        var hasPermanent = false
        var hasTrash = false
        for id in state.selection {
            guard let action = actionMap[id] else { continue }
            if action == .permanentlyDeleteTrashItem {
                hasPermanent = true
            } else if action == .trash {
                hasTrash = true
            }
            if hasPermanent && hasTrash { break }
        }
        if hasPermanent && !hasTrash {
            return L10n.localized(.actionEmptyTrash)
        } else if hasTrash && !hasPermanent {
            return L10n.localized(.actionMoveToTrash)
        } else {
            return L10n.localized(.actionCleanNow)
        }
    }

    // MARK: - 分类列表 (支持 1列宽卡片态 与 2列左侧紧凑态)

    func cleanCategoriesListView(isCompact: Bool) -> some View {
        let totalCleanable = totalCleanableCount
        let selCount = selectedCleanableCount
        let isAllSelected = totalCleanable > 0 && selCount == totalCleanable
        let isNoneSelected = selCount == 0

        return VStack(alignment: .leading, spacing: 0) {
            // 顶部快捷控制条
            if isCompact {
                HStack(alignment: .center, spacing: 8) {
                    Text(L10n.localized(.labelScanResults))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.text)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            showsProfileDropdown = false
                            inspectingSectionKind = nil
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "rectangle.compress.vertical")
                                .font(.system(size: 10.5))
                            Text(L10n.localized(.actionBack))
                                .font(.system(size: 11.5, weight: .medium))
                        }
                        .foregroundStyle(Theme.sub)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.localized(.actionBack))
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 10)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    Text(L10n.localized(.labelScanResults))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.text)

                    Spacer()

                    Text("\(L10n.localized(.labelSelected)) \(selCount) \(L10n.localized(.unitItems))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.sub)
                        .monospacedDigit()

                    HStack(spacing: 5) {
                        ActionLink(title: tr(.actionSelectAll), enabled: !isAllSelected && totalCleanable > 0) {
                            selectAllCleanable()
                        }
                        Text("·").foregroundStyle(Theme.tert)
                        ActionLink(title: tr(.actionDeselectAll), enabled: !isNoneSelected) {
                            deselectAllCleanable()
                        }
                        Text("·").foregroundStyle(Theme.tert)
                        cleaningProfileDropdownButton(enabled: totalCleanable > 0)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }

            if !state.hasFullDiskAccess {
                fdaCompactBanner
                    .padding(.horizontal, isCompact ? 14 : 24)
                    .padding(.bottom, 8)
            }

            if state.showIgnoredBanner {
                ignoredUndoBanner
                    .padding(.horizontal, isCompact ? 14 : 24)
                    .padding(.bottom, 8)
            }

            // 玻璃胶囊分类列表
            ScrollView {
                LazyVStack(spacing: isCompact ? 7 : 10) {
                    if sections.isEmpty {
                        cleanListEmptyState
                    } else {
                        ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                            SmartNextGenCleanRow(
                                section: section,
                                checkboxState: checkboxState(for: section),
                                selectedCount: selectedCount(in: section),
                                selectedSize: selectedSize(in: section),
                                isCompact: isCompact,
                                isSelected: inspectingSectionKind == section.kind,
                                onToggleSection: { toggleSectionSelection(section) },
                                onSelectSection: {
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                        showsProfileDropdown = false
                                        if inspectingSectionKind == section.kind {
                                            inspectingSectionKind = nil
                                        } else {
                                            inspectingSectionKind = section.kind
                                        }
                                    }
                                }
                            )
                            .staggeredAppear(index: index)
                        }
                    }
                }
                .padding(.horizontal, isCompact ? 12 : 24)
                .padding(.vertical, 8)
                .padding(.bottom, 12)
            }
            .id("\(config.appearanceMode.rawValue)-\(config.themePreset.rawValue)")
        }
    }

    // MARK: - 2列模式：右侧按应用聚合的三级可展开文件夹明细 

    func ensureDetailGroupsLoaded(for section: SmartCleanSectionData) {
        let key = section.cacheIdentityKey
        if let hit = SmartAppGroupBuilder.cachedGroups(for: section) {
            if detailGroupsBySectionKey[key] == nil {
                detailGroupsBySectionKey[key] = hit
            }
            if !didInitExpandedGroupsForSection.contains(section.kind), let first = hit.first {
                didInitExpandedGroupsForSection.insert(section.kind)
                expandedAppGroupIDs.insert(first.id)
            }
            return
        }
        let sectionKind = section.kind
        SmartAppGroupBuilder.loadGroupsAsync(for: section) { built in
            self.detailGroupsBySectionKey[key] = built
            if !self.didInitExpandedGroupsForSection.contains(sectionKind), let first = built.first {
                self.didInitExpandedGroupsForSection.insert(sectionKind)
                self.expandedAppGroupIDs.insert(first.id)
            }
        }
    }

    func cleanCategoryDetailView(section: SmartCleanSectionData) -> some View {
        let isDark = Theme.isDark
        let selCount = selectedCount(in: section)
        let selSize = selectedSize(in: section)
        let totalCount = section.totalCount
        let isManual = section.kind.isManualStorage
        let appGroups = SmartAppGroupBuilder.cachedGroups(for: section)
            ?? detailGroupsBySectionKey[section.cacheIdentityKey]
            ?? []
        let detailRows = SmartCleanDetailRow.rows(groups: appGroups, expanded: expandedAppGroupIDs)

        return VStack(alignment: .leading, spacing: 0) {
            // 详情头部
            HStack(spacing: 12) {
                CleanCategoryVisuals.opticalIcon(for: section.kind, size: 30)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(section.kind.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.text)

                        Text("\(totalCount) \(L10n.localized(.unitItems)) · \(selCount > 0 && !isManual ? "\(Fmt.size(selSize)) / \(Fmt.size(section.totalSize))" : Fmt.size(section.totalSize))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.sub)
                            .monospacedDigit()
                    }

                    Text(section.kind.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.tert)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                // 该分类快捷全选 / 取消全选 与 清理策略下拉
                HStack(spacing: 6) {
                    if !isManual {
                        let isAllSectionSelected = !section.selectableLeafIDs.isEmpty && section.selectableLeafIDs.isSubset(of: state.selection)
                        let isNoneSectionSelected = section.selectableLeafIDs.intersection(state.selection).isEmpty

                        ActionLink(title: tr(.actionSelectAll), enabled: !isAllSectionSelected && !section.selectableLeafIDs.isEmpty) {
                            var next = state.selection
                            next.formUnion(section.selectableLeafIDs)
                            state.setManualSelection(next)
                        }

                        Text("·").foregroundStyle(Theme.tert)

                        ActionLink(title: tr(.actionNone), enabled: !isNoneSectionSelected) {
                            var next = state.selection
                            for item in section.items.flatMap(\.leaves) {
                                next.remove(item.id)
                            }
                            state.setManualSelection(next)
                        }

                        Text("·").foregroundStyle(Theme.tert)
                    }

                    cleaningProfileDropdownButton(enabled: totalCleanableCount > 0)
                }

                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        showsProfileDropdown = false
                        inspectingSectionKind = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(Theme.sub.opacity(0.65))
                }
                .buttonStyle(.plain)
                .help(L10n.localized(.actionBack))
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider().background(Theme.sep.opacity(0.5))

            // 快捷提示条
            HStack {
                Text("\(L10n.localized(.labelSelected)): \(selCount)/\(totalCount) \(L10n.localized(.unitItems)) · \(Fmt.size(selSize)) / \(Fmt.size(section.totalSize))")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(Theme.sub)
                    .monospacedDigit()

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .background(isDark ? Color.white.opacity(0.02) : Color.black.opacity(0.02))

            Divider().background(Theme.sep.opacity(0.3))

            // 按应用聚合的二级可展开文件夹列表（一级应用行 -> 二级需要清空的具体文件夹行）
            if section.items.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: state.hasRuleDatabaseDegradation ? "exclamationmark.shield" : "checkmark.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(state.hasRuleDatabaseDegradation ? Theme.amber : Theme.tert)
                    Text(state.hasRuleDatabaseDegradation ? L10n.localized(.ruleDatabaseUnavailableBanner) : L10n.localized(.systemSpotlessSubtitle))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.tert)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 440)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(detailRows) { row in
                            VStack(spacing: 0) {
                                switch row.content {
                                case .group(let groupIndex):
                                    let group = appGroups[groupIndex]
                                    SmartAppCacheGroupView(
                                        group: group,
                                        isManualStorage: isManual,
                                        isExpanded: expandedAppGroupIDs.contains(group.id),
                                        onToggleExpand: {
                                            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                                                if expandedAppGroupIDs.contains(group.id) {
                                                    expandedAppGroupIDs.remove(group.id)
                                                } else {
                                                    expandedAppGroupIDs.insert(group.id)
                                                }
                                            }
                                        }
                                    )
                                case .item(let groupIndex, let itemIndex):
                                    SmartCleanLeafRow(
                                        leaf: appGroups[groupIndex].items[itemIndex],
                                        isManualStorage: isManual,
                                        leadingIndent: AppConfig.JunkPresentation.detailLeafIndent
                                    )
                                    .padding(.bottom, row.endsGroup ? AppConfig.JunkPresentation.detailGroupBottomPadding : 0)
                                }
                                if row.endsGroup {
                                    Divider().background(Theme.sep.opacity(0.28))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.bottom, 12)
                }
                .id(section.cacheIdentityKey)
                .onAppear {
                    ensureDetailGroupsLoaded(for: section)
                }
                .onChange(of: section.cacheIdentityKey) { _ in
                    ensureDetailGroupsLoaded(for: section)
                }
            }
        }
        .background(
            isDark ? Color.white.opacity(0.015) : Color.black.opacity(0.01)
        )
    }

    // MARK: - 方案下拉复选器 (Cleaning Profile Multi-Select Dropdown)

    static let selectableProfiles: [CleaningProfile] = [.safeDaily, .devPro, .maxSpace]

    func profileDeltaSize(for profile: CleaningProfile) -> Int64 {
        cachedProfileDeltas[profile] ?? 0
    }

    var profileDropdownSummaryTitle: String {
        let active = Self.selectableProfiles.filter { selectedProfiles.contains($0) }
        guard !active.isEmpty else {
            return tr(.cleanProfileCustom)
        }
        if active.count == 1, let first = active.first {
            return profileTitle(first)
        }
        return active.map { profileTitle($0) }.joined(separator: " / ")
    }

    func cleaningProfileDropdownButton(enabled: Bool) -> some View {
        Button {
            guard enabled else { return }
            showsProfileDropdown.toggle()
        } label: {
            HStack(spacing: 4) {
                if let primary = Self.selectableProfiles.first(where: { selectedProfiles.contains($0) }) {
                    Circle()
                        .fill(profileColor(primary))
                        .frame(width: 6, height: 6)
                }
                Text(profileDropdownSummaryTitle)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(enabled ? Theme.accent : Theme.tert)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(enabled ? Theme.accent.opacity(Theme.isDark ? 0.16 : 0.10) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(enabled ? Theme.accent.opacity(0.28) : Color.clear, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .popover(isPresented: $showsProfileDropdown, arrowEdge: .bottom) {
            cleaningProfileDropdownPopover
        }
    }

    var cleaningProfileDropdownPopover: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Self.selectableProfiles, id: \.self) { profile in
                let isChecked = selectedProfiles.contains(profile)
                Button {
                    toggleCleaningProfileOption(profile)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isChecked ? Theme.accent : Theme.sub)
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(profileColor(profile))
                                    .frame(width: 7, height: 7)

                                Text(profileTitle(profile))
                                    .font(.system(size: 12.5, weight: isChecked ? .semibold : .medium))
                                    .foregroundStyle(Theme.text)

                                let delta = profileDeltaSize(for: profile)
                                if delta > 0 {
                                    Text(L10n.format(.profileDeltaFormat, Fmt.size(delta)))
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .foregroundStyle(profileColor(profile))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(
                                            Capsule().fill(profileColor(profile).opacity(0.14))
                                        )
                                }
                            }

                            Text(profileHelp(profile))
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.sub)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isChecked ? Theme.accent.opacity(Theme.isDark ? 0.16 : 0.08) : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(profileTitle(profile))
                .accessibilityHint(profileHelp(profile))
                .accessibilityAddTraits(isChecked ? .isSelected : [])
            }
        }
        .padding(10)
        .frame(width: AppConfig.UI.profileDropdownWidth)
    }

    func profileColor(_ profile: CleaningProfile) -> Color {
        switch profile {
        case .safeDaily: return Color(red: 0.20, green: 0.78, blue: 0.45)
        case .devPro:    return Color(red: 0.95, green: 0.70, blue: 0.20)
        case .maxSpace:  return Color(red: 0.95, green: 0.45, blue: 0.25)
        case .custom:    return Theme.sub
        }
    }

    func profileTitle(_ profile: CleaningProfile) -> String {
        switch profile {
        case .safeDaily: return L10n.localized(.cleanProfileSafeDaily)
        case .devPro:    return L10n.localized(.cleanProfileDevPro)
        case .maxSpace:  return L10n.localized(.cleanProfileMaxSpace)
        case .custom:    return L10n.localized(.cleanProfileCustom)
        }
    }

    func profileHelp(_ profile: CleaningProfile) -> String {
        switch profile {
        case .safeDaily: return L10n.localized(.cleanProfileSafeDailyDesc)
        case .devPro:    return L10n.localized(.cleanProfileDevProDesc)
        case .maxSpace:  return L10n.localized(.cleanProfileMaxSpaceDesc)
        case .custom:    return L10n.localized(.cleanProfileCustom)
        }
    }

    // MARK: - 底部操作栏 (右下角放扫描结果与立即清理按钮，并展示已选择多少大小)

    var cleanBottomBar: some View {
        HStack(alignment: .center, spacing: 16) {
            // 左侧：关联应用退出提示与实时影响透视条 (Pre-Clean Impact Bar)
            HStack(spacing: 14) {
                if !runningAppsOccupyingCache.isEmpty {
                    Button {
                        quitOccupyingApps()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "app.dashed")
                                .font(.system(size: 11, weight: .semibold))
                            Text("\(runningAppsOccupyingCache.count) \(L10n.localized(.runningAssociatedAppsClickToQuitSuffix))")
                                .font(.system(size: 11.5, weight: .medium))
                        }
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(Theme.hover)
                        )
                        .overlay(
                            Capsule().strokeBorder(Theme.sep, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // 实时影响透视条 (Pre-Clean Impact Bar)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.accent)
                        Text(L10n.localized(.impactTrashReversibleNotice))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.sub)
                    }

                    HStack(spacing: 5) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 10.5))
                            .foregroundStyle(Color.blue)
                        Text(L10n.localized(.impactProtectedNoticeFormat))
                            .font(.system(size: 10.5))
                            .foregroundStyle(Theme.tert)
                    }
                }
            }

            Spacer()

            // 右下角：扫描结果统计 + 已选大小 + 立即清理主按钮
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(L10n.localized(.selected))
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Theme.sub)

                        Text(Fmt.size(selectedCleanableSize))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(selectedCleanableSize > 0 ? Theme.accent : Theme.tert)
                            .monospacedDigit()

                        Text("(\(selectedCleanableCount) \(L10n.localized(.unitItems)))")
                            .font(.system(size: 11.5))
                            .foregroundStyle(Theme.sub)
                            .monospacedDigit()
                    }

                    HStack(spacing: 4) {
                        Text("\(L10n.localized(.labelScanResults)):")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.tert)

                        Text("\(L10n.localized(.cleanableTag)) \(Fmt.size(totalCleanableSize)) · \(totalCleanableCount) \(L10n.localized(.unitItems)) · \(activeSectionCount) \(L10n.localized(.unitCategories))")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.tert)
                            .monospacedDigit()
                    }
                }

                GlowingPillButton(
                    title: mainButtonTitle,
                    subtitle: selectedCleanableSize > 0 ? Fmt.size(selectedCleanableSize) : nil,
                    icon: "trash.fill",
                    tint: Theme.accent,
                    isEnabled: selectedCleanableCount > 0 && !state.scanning && state.screen != .cleaning,
                    width: 170,
                    height: 40
                ) {
                    if !activeOccupyingRunningApps.isEmpty {
                        showsRunningAppsSheet = true
                    } else {
                        state.commitClean(category: nil)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            ZStack {
                VisualEffectView(material: .headerView, blendingMode: .withinWindow)
                Theme.card.opacity(Theme.isDark ? 0.75 : 0.88)
            }
        )
        .overlay(alignment: .top) {
            Divider().background(Theme.sep.opacity(0.6))
        }
    }

    // MARK: - 权限与忽略撤销条

    var fdaCompactBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 13))
                .foregroundStyle(Theme.amber)
            Text(L10n.localized(.fdaWarningProtectedDirsIncomplete))
                .font(.system(size: 12))
                .foregroundStyle(Theme.sub)
                .lineLimit(1)
            Spacer()

            HStack(spacing: 8) {
                Button {
                    PermissionCoordinator.shared.requestAccess(context: .general) {
                        state.checkFullDiskAccess(force: true)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10.5))
                        Text(L10n.localized(.actionGoToAuthorize))
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.accent.opacity(0.15)))
                    .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)

                Button {
                    FullDiskAccessManager.shared.openSystemSettings()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 10.5))
                        Text(L10n.localized(.actionDirectOpenFdaSettings))
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Theme.sub)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.card)
        )
    }

    /// 空状态。
    /// 清理模块本身没有搜索框（`state.search` 是跨模块共享的，拿它判断「筛完为空」会误报），
    /// 所以这里只处理一种情况：确实没有可清理项，给正向反馈而不是一句「暂无数据」。
    @ViewBuilder
    var cleanListEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Theme.green)
                .a11yDecorative()
            Text(L10n.localized(.emptyStateCleanTitle))
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.sub)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    var ignoredUndoBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.accent)
            Text(L10n.localized(.bannerAddedToWhitelist))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.text)
            Spacer()
            Button {
                state.undoIgnore()
            } label: {
                Text(L10n.localized(.actionUndo))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.card)
        )
    }

    // MARK: - 勾选状态计算与 智能推荐策略

    func selectedCount(in section: SmartCleanSectionData) -> Int {
        guard !section.kind.isManualStorage else { return 0 }
        return section.cleanableItemLeafIDs.filter { !$0.isDisjoint(with: state.selection) }.count
    }

    func selectedSize(in section: SmartCleanSectionData) -> Int64 {
        guard !section.kind.isManualStorage else { return 0 }
        var sum: Int64 = 0
        for (id, sz) in section.leafSizeByID where state.selection.contains(id) {
            sum += sz
        }
        return sum
    }

    func checkboxState(for section: SmartCleanSectionData) -> CheckboxState {
        if section.kind.isManualStorage || section.selectableLeafIDs.isEmpty {
            return section.kind.isManualStorage ? .locked : .none
        }
        let sel = section.selectableLeafIDs.intersection(state.selection).count
        if sel == 0 { return .none }
        if sel == section.selectableLeafIDs.count { return .all }
        return .partial
    }

    func toggleSectionSelection(_ section: SmartCleanSectionData) {
        guard !section.kind.isManualStorage, !section.selectableLeafIDs.isEmpty else { return }
        let currentState = checkboxState(for: section)
        let shouldSelectAll = (currentState != .all)
        var next = state.selection
        if shouldSelectAll {
            next.formUnion(section.selectableLeafIDs)
        } else {
            next.subtract(section.selectableLeafIDs)
        }
        state.setManualSelection(next)
    }

    func selectAllCleanable() {
        state.setCleaningProfile(.maxSpace, selectedProfiles: [.safeDaily, .devPro, .maxSpace])
        if let maxSet = cachedProfileSelections[.maxSpace], !maxSet.isEmpty {
            state.selection = maxSet
        } else {
            var next = Set<UUID>()
            for section in sections {
                next.formUnion(section.selectableLeafIDs)
            }
            state.selection = next
        }
    }

    func deselectAllCleanable() {
        state.setManualSelection([])
    }

    func applyRecommendedSelection() {
        applyCleaningProfileSelection(.safeDaily)
    }

    func toggleCleaningProfileOption(_ profile: CleaningProfile) {
        var nextProfiles = state.selectedProfiles
        if nextProfiles.contains(profile) {
            nextProfiles.remove(profile)
        } else {
            nextProfiles.insert(profile)
        }
        applySelectedCleaningProfiles(nextProfiles)
    }

    func applySelectedCleaningProfiles(_ profiles: Set<CleaningProfile>? = nil) {
        let targetProfiles = profiles ?? state.selectedProfiles
        if targetProfiles.isEmpty {
            state.markCustomSelection()
            state.selection.removeAll()
            return
        }
        let primaryProfile: CleaningProfile
        if targetProfiles.contains(.maxSpace) {
            primaryProfile = .maxSpace
        } else if targetProfiles.contains(.devPro) {
            primaryProfile = .devPro
        } else {
            primaryProfile = .safeDaily
        }
        state.setCleaningProfile(primaryProfile, selectedProfiles: targetProfiles)

        let buckets = currentSnapshot.profileBucketSelections
        var next = Set<UUID>()
        var usedBuckets = false
        for p in targetProfiles {
            if let set = buckets[p] {
                next.formUnion(set)
                usedBuckets = true
            }
        }
        if usedBuckets && !currentSnapshot.cleanableLeaves.isEmpty {
            state.selection = next
            return
        }
        for section in sections {
            for item in section.selectableLeaves {
                if CleanupSelectionPolicy.isSelected(node: item, in: targetProfiles) {
                    next.insert(item.id)
                }
            }
        }
        state.selection = next
    }

    func applyCleaningProfileSelection(_ profile: CleaningProfile) {
        if profile == .custom {
            state.markCustomSelection()
            return
        }
        applySelectedCleaningProfiles([profile])
    }

    func undoCleanup(report: CleanReport) {
        guard !undoInProgress, !undoSucceeded else { return }
        undoInProgress = true
        let reportID = report.id
        let items = report.outcomes.flatMap(\.restoreItems)
        let completed = restoredItemIDs
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                CleanupRestoreService.restore(items, excluding: completed)
            }.value
            guard state.report?.id == reportID else { return }
            undoInProgress = false
            restoredItemIDs.formUnion(result.restoredIDs)
            undoSucceeded = !items.isEmpty && result.failedPaths.isEmpty
            state.toast = undoSucceeded
                ? L10n.format(.receiptUndoSuccessNotice, result.restoredIDs.count, Fmt.size(result.restoredBytes))
                : L10n.localized(.reviewUndoIncomplete)
        }
    }
}
