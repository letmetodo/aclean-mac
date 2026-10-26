import Foundation
import Darwin

enum JunkRulePolicy {
    enum ContainerExpansionOutcome {
        case empty
        case expanded(children: [ScanItem], totalBytes: Int64)
        case failed(lockedContainer: ScanItem, reason: CandidateEvaluationReason)
    }

    /// 测试钩子：允许在保壳容器读取直接子项列表后、捕获 postIdentity 前注入并发变更模拟
    #if DEBUG
    static nonisolated(unsafe) var onContainerEnumerationHook: ((URL) -> Void)? = nil
    #else
    static var onContainerEnumerationHook: ((URL) -> Void)? { nil }
    #endif

    static func isEmptyVerifiedContainer(_ item: ScanItem) -> Bool {
        guard item.children.isEmpty,
              item.locked != true,
              item.size == 0,
              let ruleID = item.ruleEvidence?.id,
              KnowledgeBaseManager.shared.authored.junk[ruleID]?.action == "trash_children_only" else {
            return false
        }
        return true
    }

    static func preliminaryRule(
        for url: URL,
        preferredID: String? = nil,
        store: AuthoredRules
    ) -> AuthoredJunkRule? {
        guard store.loaded else { return nil }
        let norm = AuthoredRules.normalizeRuleMatchPath(url)
        let lastComponentLower = url.lastPathComponent.lowercased()
        var candidates = store.junk.values.filter { $0.active && store.matchesNormalizedPath(norm, rule: $0) }
        if let preferredID { candidates = candidates.filter { $0.id == preferredID } }
        let profileRuleIDs = Set(
            store.matchingCacheProfileUnits(for: url, ruleID: nil, enforceCacheDataPrecedence: false)
                .map { $0.profile.ruleID }
        )
        candidates.sort {
            let a = store.matchingPathLengthNormalizedPath(norm, rule: $0)
            let b = store.matchingPathLengthNormalizedPath(norm, rule: $1)
            if a != b { return a > b }
            if $0.tier.conservatismRank != $1.tier.conservatismRank {
                return $0.tier.conservatismRank > $1.tier.conservatismRank
            }
            let aMatchesProfile = profileRuleIDs.contains($0.id)
            let bMatchesProfile = profileRuleIDs.contains($1.id)
            if aMatchesProfile != bMatchesProfile { return aMatchesProfile }
            return $0.id < $1.id
        }
        for rule in candidates {
            if rule.id == AppConfig.RuleIDs.leftoverOrphan && preferredID != AppConfig.RuleIDs.leftoverOrphan {
                continue
            }
            if rule.id == AppConfig.RuleIDs.derivedOrphan || rule.id == AppConfig.RuleIDs.derivedLive {
                if url.deletingLastPathComponent().lastPathComponent != "DerivedData"
                    || lastComponentLower == "modulecache.noindex"
                    || lastComponentLower == "modulecache" {
                    continue
                }
            }
            if rule.id == AppConfig.RuleIDs.derivedLive
                && preferredID != AppConfig.RuleIDs.derivedLive
                && DeveloperArtifactPolicy.isOrphanDerivedData(url) {
                continue
            }
            if rule.id == AppConfig.RuleIDs.jetBrainsCache && !AuthoredRules.isValidJetBrainsLeafOrDescendant(url) {
                continue
            }
            if rule.id == AppConfig.RuleIDs.firefoxCache && !AuthoredRules.isValidFirefoxLeafOrDescendant(url) {
                continue
            }
            if rule.id == "JC.DEV.PROJECT" && preferredID != "JC.DEV.PROJECT" && !DeveloperArtifactPolicy.isProvenProjectArtifact(url) {
                continue
            }
            return rule
        }
        return nil
    }

    /// 单次测量或保壳容器展开辅助函数：
    /// - 若 url 命中 action == "trash_children_only" 的目录容器，直接通过 JunkRulePolicy.apply 执行四步快照协议单次测量其直接子项，不预先递归调用 FileUtil.size(of: url)；
    /// - 否则通过 FastDirectoryInspector.inspect 单遍完成体积测量与安全巡检。
    static func makeMeasuredCandidate(
        url: URL,
        name: String,
        note: String,
        safety: Safety,
        minBytes: Int64,
        configure: ((inout ScanItem) -> Void)? = nil
    ) -> ScanItem? {
        let store = KnowledgeBaseManager.shared.authored
        let identity = FileIdentity.capture(from: url)
        let prelim = preliminaryRule(for: url, store: store)
        IOScanContext.registerCandidate(
            url: url,
            scannerID: "makeMeasuredCandidate",
            ruleID: prelim?.id,
            tier: prelim?.tier
        )
        if store.isTrashChildrenOnlyContainer(url, identity: identity) {
            var item = ScanItem(url: url, name: name, size: 0, note: note, safety: safety)
            item.fileIdentity = identity
            configure?(&item)
            let evaluated = apply(item)
            if isEmptyVerifiedContainer(evaluated) {
                return nil
            }
            if evaluated.locked != true && evaluated.size <= minBytes {
                return nil
            }
            return evaluated
        }
        let fastInspection = FastDirectoryInspector.inspect(
            url,
            identity: identity,
            parentRuleID: prelim?.id,
            parentTier: prelim?.tier,
            requireCurrentUserUID: true,
            measurePhysicalBytes: true,
            invokeMeasureHook: true
        )
        let s = fastInspection.physicalBytes
        guard !fastInspection.measurementComplete || s > minBytes else { return nil }
        var item = ScanItem(url: url, name: name, size: s, note: note, safety: safety, measuredBytes: s)
        item.fileIdentity = identity
        if !fastInspection.measurementComplete || !fastInspection.allCurrentUserOwned || !fastInspection.safetyInspection.isSafe {
            IOScanContext.current?.record(L10n.localized(.scanCoverageIncomplete) + ": " + url.path)
            item.locked = true
            item.isSelected = false
            item.safety = .caution
            item.selectionRestrictions.insert(.readOnlyAsset)
            item.evaluationReason = fastInspection.safetyInspection.evaluationReason ?? .protectedAssetBlocked
        }
        configure?(&item)
        return item
    }

    /// 针对命中 trash_children_only 的保壳容器执行四步快照完整性展开协议 (Section 3.4.2)：
    /// 1. 捕获枚举前父容器身份 preIdentity；
    /// 2. 读取直接子项列表；
    /// 3. 单次遍历每个直接子项捕获 FileIdentity 并调用 FileUtil.measureSize(of:) 校验 isComplete；
    /// 4. 捕获枚举后父容器身份 postIdentity 并核验 preIdentity == postIdentity。
    /// 任一环节失败立即丢弃全部部分子项并将父容器锁定为只读；若快照一致且子项为空则正常返回 0 个候选。
    static func expandContainerOutcome(
        for containerItem: ScanItem,
        evidence: CleanupRuleEvidence
    ) -> ContainerExpansionOutcome {
        let store = KnowledgeBaseManager.shared.authored
        let parentURL = containerItem.url
        let parentStdPath = parentURL.standardizedFileURL.path

        func fail(_ detail: String, degradation: ScanDegradationReason) -> ContainerExpansionOutcome {
            let reason = CandidateEvaluationReason.containerSnapshotIncomplete(
                path: parentStdPath,
                reason: detail
            )
            var lockedParent = containerItem
            lockedParent.children = []
            lockedParent.size = 0
            lockedParent.measuredBytes = 0
            lockedParent.locked = true
            lockedParent.isSelected = false
            lockedParent.safety = .caution
            lockedParent.selectionRestrictions.insert(.readOnlyAsset)
            lockedParent.evaluationReason = reason
            lockedParent.isRuleEvaluated = true
            lockedParent.ruleEvidence = CleanupRuleEvidence(
                id: evidence.id,
                tier: .readOnly,
                reason: .whitelistProtected,
                defaultSelected: false
            )
            IOScanContext.recordEvaluation(reason)
            IOScanContext.recordDegradation(
                degradation,
                issue: L10n.localized(.safetyInspectionIncomplete) + ": " + parentStdPath + " (\(detail))"
            )
            return .failed(lockedContainer: lockedParent, reason: reason)
        }

        // Step 1: 捕获枚举前父容器身份 preIdentity
        guard let preIdentity = FileIdentity.capture(from: parentURL),
              preIdentity.isDirectory,
              access(parentURL.path, R_OK | X_OK) == 0 else {
            return fail(
                "pre_identity_or_access_failed",
                degradation: .containerEnumerationIncomplete
            )
        }

        // Step 2: 读取直接子项列表
        let childURLs: [URL]
        do {
            childURLs = try FileManager.default.contentsOfDirectory(
                at: parentURL,
                includingPropertiesForKeys: nil
            )
        } catch {
            IOScanContext.record(error, path: parentURL.path)
            return fail(
                "contents_of_directory_error",
                degradation: .containerEnumerationIncomplete
            )
        }

        onContainerEnumerationHook?(parentURL)

        // Step 3: 遍历每个直接子项，捕获 childIdentity + 调用 FileUtil.measureSize(of:)
        var expandedChildren: [ScanItem] = []
        expandedChildren.reserveCapacity(childURLs.count)
        var totalBytes: Int64 = 0

        let parentSpecificity = store.junk[evidence.id].map { store.matchingPathLength(parentURL, rule: $0) } ?? 0

        for childURL in childURLs {
            let failureOutcome: ContainerExpansionOutcome? = autoreleasepool {
                guard let childIdentity = FileIdentity.capture(from: childURL) else {
                    return fail(
                        "child_identity_missing:\(childURL.lastPathComponent)",
                        degradation: .containerEnumerationIncomplete
                    )
                }
                let norm = AuthoredRules.normalizeRuleMatchPath(childURL)
                let childMatchedRule: AuthoredJunkRule? = {
                    var matches = store.junk.values.filter { $0.active && store.matchesNormalizedPath(norm, rule: $0) }
                    matches.sort {
                        let a = store.matchingPathLengthNormalizedPath(norm, rule: $0)
                        let b = store.matchingPathLengthNormalizedPath(norm, rule: $1)
                        return a == b ? $0.tier.rawValue > $1.tier.rawValue : a > b
                    }
                    return matches.first
                }()
                if childIdentity.isDirectory,
                   let mr = childMatchedRule,
                   mr.id != evidence.id,
                   mr.action == "trash_children_only",
                   store.matchingPathLengthNormalizedPath(norm, rule: mr) > parentSpecificity,
                   let subContainerEvidence = store.evidence(
                       for: childURL,
                       isContainerRoot: true,
                       identity: childIdentity
                   ),
                   subContainerEvidence.id != evidence.id,
                   let subRule = store.junk[subContainerEvidence.id],
                   subRule.action == "trash_children_only",
                   store.matchingPathLengthNormalizedPath(norm, rule: subRule) > parentSpecificity {
                    var subContainer = ScanItem(
                        url: childURL,
                        name: childURL.lastPathComponent,
                        size: 0,
                        note: containerItem.note,
                        safety: containerItem.safety
                    )
                    subContainer.fileIdentity = childIdentity
                    subContainer.ownerBundleIDs = containerItem.ownerBundleIDs
                    subContainer.selectionRestrictions = containerItem.selectionRestrictions
                    subContainer.cacheRecommendation = containerItem.cacheRecommendation
                    let evaluatedSub = apply(subContainer)
                    if isEmptyVerifiedContainer(evaluatedSub) {
                        return nil
                    }
                    expandedChildren.append(evaluatedSub)
                    totalBytes += evaluatedSub.size
                    return nil
                }
                let prelimRuleID: String = {
                    if let mr = childMatchedRule, mr.id != evidence.id {
                        let cSpec = store.matchingPathLengthNormalizedPath(norm, rule: mr)
                        if cSpec > parentSpecificity || mr.tier.conservatismRank > evidence.tier.conservatismRank || !mr.tier.executable {
                            return mr.id
                        }
                    }
                    return evidence.id
                }()
                let prelimTier: CleanupTier = {
                    if let mr = childMatchedRule, mr.id == prelimRuleID {
                        return mr.tier.conservatismRank >= evidence.tier.conservatismRank ? mr.tier : evidence.tier
                    }
                    return evidence.tier
                }()
                let fastInspection = FastDirectoryInspector.inspect(
                    childURL,
                    identity: childIdentity,
                    parentRuleID: prelimRuleID,
                    parentTier: prelimTier,
                    requireCurrentUserUID: true,
                    measurePhysicalBytes: true,
                    invokeMeasureHook: true
                )
                guard fastInspection.measurementComplete else {
                    return fail(
                        "child_size_measurement_incomplete:\(childURL.lastPathComponent)",
                        degradation: .containerEnumerationIncomplete
                    )
                }

                let childFullScopeVerifiable = fastInspection.allCurrentUserOwned
                let unconstrainedEvidence = store.evidence(
                    for: childURL,
                    preferredID: nil,
                    isContainerRoot: false,
                    identity: childIdentity,
                    knownSize: fastInspection.physicalBytes,
                    knownFullScopeVerifiable: childFullScopeVerifiable
                )
                let parentScopedEvidence: CleanupRuleEvidence? = {
                    if unconstrainedEvidence?.id == evidence.id {
                        return unconstrainedEvidence
                    }
                    return store.evidence(
                        for: childURL,
                        preferredID: evidence.id,
                        isContainerRoot: false,
                        identity: childIdentity,
                        knownSize: fastInspection.physicalBytes,
                        knownFullScopeVerifiable: childFullScopeVerifiable
                    )
                }()
                let hasMoreSpecificChildRule: Bool = {
                    guard let unc = unconstrainedEvidence,
                          unc.id != evidence.id,
                          let uncRule = store.junk[unc.id] else {
                        return false
                    }
                    let childSpec = store.matchingPathLength(childURL, rule: uncRule)
                    return childSpec > parentSpecificity
                        || unc.tier.conservatismRank > (parentScopedEvidence?.tier ?? evidence.tier).conservatismRank
                        || !unc.executable
                }()
                let childResolvedEvidence = hasMoreSpecificChildRule ? unconstrainedEvidence : parentScopedEvidence
                let effectiveChildRuleID = childResolvedEvidence?.id ?? evidence.id
                let effectiveBaseTier: CleanupTier = {
                    var best = evidence.tier
                    if let pTier = parentScopedEvidence?.tier, pTier.conservatismRank > best.conservatismRank {
                        best = pTier
                    }
                    if let cTier = childResolvedEvidence?.tier, cTier.conservatismRank > best.conservatismRank {
                        best = cTier
                    }
                    return best
                }()
                let childInspection = (effectiveChildRuleID == prelimRuleID)
                    ? fastInspection.safetyInspection
                    : CleanupSafetyPolicy.inspectDirectory(
                        childURL,
                        parentRuleID: effectiveChildRuleID,
                        parentTier: effectiveBaseTier
                    )
                let hasSymlinkEscape = SymlinkGuard.hasSymlinkEscape(url: childURL)
                let isUserIgnored = AppConfigStore.shared.isPathIgnoredForDeletion(childURL.path)
                let childSafe = childInspection.isSafe && !hasSymlinkEscape && !isUserIgnored
                let parentAllowsAuto = containerItem.selectionRestrictions.isEmpty
                    && containerItem.badge.isEmpty
                    && containerItem.duplicateEvidence == nil
                    && (containerItem.cacheRecommendation?.automaticAllowed != false)
                var selected: Bool
                if hasMoreSpecificChildRule {
                    selected = (childResolvedEvidence?.defaultSelected == true)
                        && (effectiveBaseTier == .automatic)
                        && AppConfig.RuleIDs.implementedAutomaticRules.contains(effectiveChildRuleID)
                        && parentAllowsAuto
                        && (AppConfig.RuleIDs.logRules.contains(effectiveChildRuleID) || evidence.defaultSelected)
                } else {
                    selected = AppConfig.RuleIDs.logRules.contains(evidence.id)
                        ? (childResolvedEvidence?.defaultSelected == true && parentAllowsAuto)
                        : (evidence.defaultSelected && parentAllowsAuto && effectiveBaseTier == .automatic && AppConfig.RuleIDs.implementedAutomaticRules.contains(effectiveChildRuleID))
                }
                if !childSafe || childInspection.downgradeAutomaticToReview {
                    selected = false
                }
                let childLocked = containerItem.locked == true
                    || !childSafe
                    || parentScopedEvidence?.executable == false
                    || childResolvedEvidence?.executable == false
                if childLocked {
                    selected = false
                }
                let childTier: CleanupTier = childLocked
                    ? .readOnly
                    : ((AppConfig.RuleIDs.logRules.contains(effectiveChildRuleID) && !selected && effectiveBaseTier == .automatic) || childInspection.downgradeAutomaticToReview
                        ? .review
                        : effectiveBaseTier)
                let childSafety: Safety = (!childLocked && selected && childTier == .automatic) ? .safe : .caution
                let childReason: CandidateEvaluationReason = !childSafe
                    ? (hasSymlinkEscape
                        ? .symlinkEscapeBlocked
                        : (isUserIgnored
                            ? .guardedByPolicy(guardName: "AppConfigStore", detail: "user_ignored_path")
                            : (childInspection.evaluationReason ?? .protectedAssetBlocked)))
                    : (childLocked ? store.diagnoseNonExecutableReason(for: childURL, ruleID: effectiveChildRuleID, identity: childIdentity) : .matchedExecutableRule)

                var child = ScanItem(
                    url: childURL,
                    name: childURL.lastPathComponent,
                    size: fastInspection.physicalBytes,
                    note: containerItem.note,
                    safety: childSafety,
                    isSelected: selected,
                    authorizationContext: .junkRule,
                    evaluationReason: childReason,
                    isRuleEvaluated: true,
                    measuredBytes: fastInspection.physicalBytes
                )
                var mergedOwners = Set(containerItem.ownerBundleIDs)
                if let childRule = store.junk[effectiveChildRuleID] {
                    mergedOwners.formUnion(store.resolvedOwnerBundleIDs(for: childURL, rule: childRule))
                }
                child.ownerBundleIDs = mergedOwners.sorted()
                child.fileIdentity = childIdentity
                var childEvidence = CleanupRuleEvidence(
                    id: effectiveChildRuleID,
                    tier: childTier,
                    reason: childLocked ? .whitelistProtected : (childResolvedEvidence?.reason ?? evidence.reason),
                    defaultSelected: selected
                )
                childEvidence.containerPath = parentStdPath
                childEvidence.containerIdentity = preIdentity
                child.ruleEvidence = childEvidence
                child.locked = childLocked
                child.selectionRestrictions = containerItem.selectionRestrictions
                if childLocked || !childEvidence.executable {
                    child.selectionRestrictions.insert(.readOnlyAsset)
                } else if childTier != .automatic || !selected {
                    child.selectionRestrictions.insert(.productPolicy)
                }
                if !child.selectionRestrictions.isEmpty {
                    child.isSelected = false
                }
                IOScanContext.recordEvaluation(childReason, tier: childTier, bytes: fastInspection.physicalBytes)
                expandedChildren.append(child)
                totalBytes += fastInspection.physicalBytes
                return nil
            }
            if let failureOutcome {
                return failureOutcome
            }
        }

        // Step 4: 捕获枚举后父容器身份 postIdentity 并核对一致性
        guard let postIdentity = FileIdentity.capture(from: parentURL),
              preIdentity == postIdentity else {
            return fail(
                "container_identity_mutated_during_enumeration",
                degradation: .containerMutatedDuringScan
            )
        }

        if expandedChildren.isEmpty {
            return .empty
        }
        if let overrideParentBytes = FastDirectoryInspector.allocatedBytesOverrideForTesting?(parentURL.path)
            ?? FastDirectoryInspector.allocatedBytesOverrideForTesting?(parentStdPath) {
            totalBytes = overrideParentBytes
        }
        return .expanded(children: expandedChildren, totalBytes: totalBytes)
    }

}
