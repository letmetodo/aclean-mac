import Foundation

extension JunkRulePolicy {
    static func apply(_ original: ScanItem) -> ScanItem {
        if original.isRuleEvaluated {
            return original
        }
        var item = original
        if !item.children.isEmpty {
            item.authorizationContext = item.resolvedAuthorizationContext
            item.children = item.children.map(apply).filter { !isEmptyVerifiedContainer($0) }
            item.size = item.children.reduce(0) { $0 + $1.size }
            item.measuredBytes = item.children.reduce(0) { $0 + ($1.measuredBytes ?? $1.size) }
            item.isSelected = item.children.contains { $0.isSelected }
            if !item.children.isEmpty && item.children.allSatisfy({ $0.locked == true }) {
                item.locked = true
                item.isSelected = false
                item.safety = .caution
                item.selectionRestrictions.insert(.readOnlyAsset)
            } else {
                item.locked = false
                item.safety = item.isSelected ? .safe : .caution
                if !item.isSelected {
                    item.selectionRestrictions.insert(.productPolicy)
                }
            }
            item.isRuleEvaluated = true
            return item
        }
        if item.measuredBytes == nil && item.size > 0 {
            item.measuredBytes = item.size
        }
        var physicalBytes = item.measuredBytes ?? item.size
        let preLocked = (item.locked == true)
        let preEvaluationReason = item.evaluationReason
        guard item.action == .trash || item.action == .emptyContainer else {
            item.authorizationContext = item.resolvedAuthorizationContext
            item.isSelected = false
            item.selectionRestrictions.insert(.productPolicy)
            item.isRuleEvaluated = true
            return item
        }
        item.authorizationContext = .junkRule
        let store = KnowledgeBaseManager.shared.authored
        let prelim = preliminaryRule(for: item.url, preferredID: item.ruleEvidence?.id, store: store)
        IOScanContext.registerCandidate(
            url: item.url,
            scannerID: "JunkRulePolicy.apply",
            ownerBundleIDs: item.ownerBundleIDs,
            ruleID: item.ruleEvidence?.id ?? prelim?.id,
            tier: item.ruleEvidence?.tier ?? prelim?.tier
        )
        func attachBlockedRecommendation(_ target: inout ScanItem, identity: FileIdentity? = nil) {
            target.cacheRecommendation = JunkCacheRecommendationPolicy.evaluate(
                url: target.url,
                unitIdentity: identity ?? target.fileIdentity,
                ruleEvidence: target.ruleEvidence,
                allocatedBytes: target.measuredBytes ?? target.size,
                safetyGatePassed: false,
                store: store
            )
        }
        guard store.loaded else {
            item.ruleEvidence = nil
            item.locked = true
            item.isSelected = false
            item.safety = .caution
            item.selectionRestrictions.insert(.readOnlyAsset)
            item.evaluationReason = .ruleDatabaseUnavailable
            attachBlockedRecommendation(&item)
            item.isRuleEvaluated = true
            IOScanContext.recordDegradation(
                .ruleDatabaseUnavailable,
                issue: L10n.localized(.safetyInspectionIncomplete)
            )
            IOScanContext.recordEvaluation(.ruleDatabaseUnavailable, tier: .readOnly, bytes: physicalBytes)
            return item
        }

        // 1. SymlinkGuard 逃逸检查
        if SymlinkGuard.hasSymlinkEscape(url: item.url) {
            item.locked = true
            item.isSelected = false
            item.safety = .caution
            item.selectionRestrictions.insert(.readOnlyAsset)
            item.evaluationReason = .symlinkEscapeBlocked
            attachBlockedRecommendation(&item)
            item.isRuleEvaluated = true
            IOScanContext.recordEvaluation(.symlinkEscapeBlocked, tier: .readOnly, bytes: physicalBytes)
            return item
        }

        // 2. AppConfigStore 用户自定义忽略列表双向保护
        if !item.url.path.isEmpty && AppConfigStore.shared.isPathIgnoredForDeletion(item.url.path) {
            item.locked = true
            item.isSelected = false
            item.safety = .caution
            item.selectionRestrictions.insert(.readOnlyAsset)
            let reason = CandidateEvaluationReason.guardedByPolicy(guardName: "AppConfigStore", detail: "user_ignored_path")
            item.evaluationReason = reason
            attachBlockedRecommendation(&item)
            item.isRuleEvaluated = true
            IOScanContext.recordEvaluation(reason, tier: .readOnly, bytes: physicalBytes)
            return item
        }

        // 3. ProtectedAssetPolicy / 静态物理保护红线
        let allowOrphanVolatile = (item.ruleEvidence?.id == AppConfig.RuleIDs.leftoverOrphan)
            && OrphanSafetyPolicy.canScheduleForCleanup(item.url)
        if CleanupSafetyPolicy.isProtectedAsset(item.url, allowOrphanVolatile: allowOrphanVolatile) {
            if item.ruleEvidence == nil, store.loaded {
                let targetIdentity = item.fileIdentity ?? FileIdentity.capture(from: item.url)
                if let ev = store.evidence(for: item.url, isContainerRoot: targetIdentity?.isDirectory == true, identity: targetIdentity) {
                    item.ruleEvidence = CleanupRuleEvidence(
                        id: ev.id,
                        tier: .readOnly,
                        reason: .whitelistProtected,
                        defaultSelected: false
                    )
                }
            } else if let existing = item.ruleEvidence, existing.tier != .readOnly && existing.tier != .forbidden {
                item.ruleEvidence = CleanupRuleEvidence(
                    id: existing.id,
                    tier: .readOnly,
                    reason: .whitelistProtected,
                    defaultSelected: false
                )
            }
            item.locked = true
            item.isSelected = false
            item.safety = .caution
            item.selectionRestrictions.insert(.readOnlyAsset)
            item.evaluationReason = .protectedAssetBlocked
            attachBlockedRecommendation(&item)
            item.isRuleEvaluated = true
            IOScanContext.recordEvaluation(.protectedAssetBlocked, tier: .forbidden, bytes: physicalBytes)
            return item
        }

        // 4. GitGuard 敏感文件名与已跟踪文件保护
        if GitGuard.isSensitiveFilename(item.url.lastPathComponent)
            || item.url.lastPathComponent == ".git"
            || GitGuard.hasGitTrackedFiles(url: item.url) {
            item.locked = true
            item.isSelected = false
            item.safety = .caution
            item.selectionRestrictions.insert(.readOnlyAsset)
            let reason = CandidateEvaluationReason.guardedByPolicy(guardName: "GitGuard", detail: "git_protected")
            item.evaluationReason = reason
            attachBlockedRecommendation(&item)
            item.isRuleEvaluated = true
            IOScanContext.recordEvaluation(reason, tier: .readOnly, bytes: physicalBytes)
            return item
        }

        // 5. ProcessGuard 显式关联运行中应用锁
        if item.ownerBundleIDs.contains(where: { ProcessGuard.isAppRunning(bundleID: $0) }) {
            item.locked = true
            item.isSelected = false
            item.safety = .caution
            item.selectionRestrictions.insert(.readOnlyAsset)
            item.evaluationReason = .runningProcessLocked
            attachBlockedRecommendation(&item)
            item.isRuleEvaluated = true
            IOScanContext.recordEvaluation(.runningProcessLocked, tier: .readOnly, bytes: physicalBytes)
            return item
        }

        // 6. 单遍巡检与 AuthoredRules 匹配/谓词/动作/进程锁/句柄范围评估
        let targetIdentity = item.fileIdentity ?? FileIdentity.capture(from: item.url)
        item.fileIdentity = targetIdentity
        let isDirectoryTarget = targetIdentity?.isDirectory == true
        let isPrelimChildrenOnly = (prelim?.action == "trash_children_only") && isDirectoryTarget

        var fullInspection: FastDirectoryInspector.InspectionResult? = nil
        if !isPrelimChildrenOnly {
            let inspected = FastDirectoryInspector.inspect(
                item.url,
                identity: targetIdentity,
                parentRuleID: prelim?.id,
                parentTier: prelim?.tier,
                requireCurrentUserUID: true,
                measurePhysicalBytes: true
            )
            fullInspection = inspected
            if inspected.measurementComplete {
                if inspected.physicalBytes > 0 || !isDirectoryTarget || inspected.inspectedEntryCount > 0 {
                    physicalBytes = inspected.physicalBytes
                    item.measuredBytes = physicalBytes
                    if item.size == 0 || !isDirectoryTarget || inspected.inspectedEntryCount > 0 {
                        item.size = physicalBytes
                    }
                }
            }
        }

        let evidence = store.evidence(
            for: item.url,
            preferredID: item.ruleEvidence?.id,
            isContainerRoot: isDirectoryTarget,
            identity: targetIdentity,
            knownSize: physicalBytes > 0 ? physicalBytes : nil,
            knownFullScopeVerifiable: fullInspection.map { $0.measurementComplete && $0.allCurrentUserOwned }
        )
        item.ruleEvidence = evidence
        if let evidence, let matchedRule = store.junk[evidence.id] {
            let resolvedOwners = store.resolvedOwnerBundleIDs(for: item.url, rule: matchedRule)
            if !resolvedOwners.isEmpty {
                item.ownerBundleIDs = Set(item.ownerBundleIDs).union(resolvedOwners).sorted()
            }
        }
        guard let evidence else {
            item.locked = true
            item.isSelected = false
            item.safety = .caution
            item.selectionRestrictions.insert(.readOnlyAsset)
            let reason: CandidateEvaluationReason = !OpenFileGuard.isCurrentUserVerifiableScope(item.url, identity: targetIdentity)
                ? .systemScopeHandleBlindSpot(path: OpenFileGuard.canonicalScopeURL(item.url).path)
                : .noMatchingAuthoredRule
            item.evaluationReason = reason
            attachBlockedRecommendation(&item, identity: targetIdentity)
            item.isRuleEvaluated = true
            IOScanContext.recordEvaluation(reason, tier: .readOnly, bytes: physicalBytes)
            return item
        }
        let isChildrenOnlyRule = store.junk[evidence.id]?.action == "trash_children_only"

        if preLocked {
            item.locked = true
            item.isSelected = false
            item.safety = .caution
            item.selectionRestrictions.insert(.readOnlyAsset)
            item.evaluationReason = preEvaluationReason ?? .protectedAssetBlocked
            item.ruleEvidence = CleanupRuleEvidence(
                id: evidence.id,
                tier: .readOnly,
                reason: .whitelistProtected,
                defaultSelected: false
            )
            attachBlockedRecommendation(&item, identity: targetIdentity)
            item.isRuleEvaluated = true
            IOScanContext.recordEvaluation(item.evaluationReason ?? .protectedAssetBlocked, tier: .readOnly, bytes: physicalBytes)
            return item
        }

        // 7. 整目录 .trash 后代规则与递归安全策略核查 (Section 3.3.3 & T11 单遍巡检复用)
        var downgradeFromDescendant = false
        if !(isChildrenOnlyRule && isDirectoryTarget) {
            let activeInspection: FastDirectoryInspector.InspectionResult = {
                if let fullInspection, prelim?.id == evidence.id {
                    return fullInspection
                }
                return FastDirectoryInspector.inspect(
                    item.url,
                    identity: targetIdentity,
                    parentRuleID: evidence.id,
                    parentTier: evidence.tier,
                    requireCurrentUserUID: true,
                    measurePhysicalBytes: true
                )
            }()
            if !activeInspection.measurementComplete || !activeInspection.allCurrentUserOwned || !activeInspection.safetyInspection.isSafe {
                item.locked = true
                item.isSelected = false
                item.safety = .caution
                item.selectionRestrictions.insert(.readOnlyAsset)
                let reason = activeInspection.safetyInspection.evaluationReason ?? .protectedAssetBlocked
                item.evaluationReason = reason
                item.ruleEvidence = CleanupRuleEvidence(
                    id: evidence.id,
                    tier: .readOnly,
                    reason: .whitelistProtected,
                    defaultSelected: false
                )
                attachBlockedRecommendation(&item, identity: targetIdentity)
                item.isRuleEvaluated = true
                IOScanContext.recordEvaluation(reason, tier: .readOnly, bytes: physicalBytes)
                return item
            }
            if activeInspection.safetyInspection.downgradeAutomaticToReview {
                downgradeFromDescendant = true
            }
        }

        guard evidence.executable else {
            item.locked = true
            item.isSelected = false
            item.safety = .caution
            item.selectionRestrictions.insert(.readOnlyAsset)
            let reason = store.diagnoseNonExecutableReason(for: item.url, ruleID: evidence.id, identity: targetIdentity)
            item.evaluationReason = reason
            attachBlockedRecommendation(&item, identity: targetIdentity)
            item.isRuleEvaluated = true
            IOScanContext.recordEvaluation(reason, tier: evidence.tier == .forbidden ? .forbidden : .readOnly, bytes: physicalBytes)
            return item
        }

        item.locked = false
        if !item.badge.isEmpty || item.duplicateEvidence != nil {
            item.selectionRestrictions.insert(.productPolicy)
        }
        if !(isChildrenOnlyRule && isDirectoryTarget) {
            let rec = JunkCacheRecommendationPolicy.evaluate(
                url: item.url,
                unitURL: item.url,
                unitIdentity: targetIdentity,
                ruleEvidence: evidence,
                allocatedBytes: physicalBytes,
                safetyGatePassed: true,
                store: store
            )
            item.cacheRecommendation = rec
            switch rec.state {
            case .blocked:
                item.selectionRestrictions.insert(.readOnlyAsset)
            case .unknownReview:
                if !rec.automaticAllowed {
                    if rec.reasons == [.profileMissing] {
                        if let bytes = rec.allocatedBytes,
                           store.cacheRecommendationConfig.appSuggestionBytes > 0,
                           bytes >= store.cacheRecommendationConfig.appSuggestionBytes {
                            item.selectionRestrictions.insert(.largeCache)
                        }
                        item.selectionRestrictions.insert(.productPolicy)
                    } else {
                        item.selectionRestrictions.insert(.unknownImpact)
                    }
                }
            case .suggestedLarge:
                item.selectionRestrictions.insert(.largeCache)
                downgradeFromDescendant = true
            case .ordinary:
                if !rec.automaticAllowed {
                    item.selectionRestrictions.insert(.productPolicy)
                }
            }
            if evidence.tier != .automatic
                || !evidence.defaultSelected
                || downgradeFromDescendant
                || !AppConfig.RuleIDs.implementedAutomaticRules.contains(evidence.id) {
                item.selectionRestrictions.insert(.productPolicy)
            }
        }
        let computedSafe = (evidence.tier == .automatic
            && !downgradeFromDescendant
            && AppConfig.RuleIDs.implementedAutomaticRules.contains(evidence.id)
            && (!AppConfig.RuleIDs.logRules.contains(evidence.id) || evidence.defaultSelected || (isChildrenOnlyRule && isDirectoryTarget)))
            && item.selectionRestrictions.isEmpty
            && (item.cacheRecommendation?.automaticAllowed != false)
        item.safety = computedSafe ? .safe : .caution
        item.isSelected = evidence.defaultSelected
            && !downgradeFromDescendant
            && AppConfig.RuleIDs.implementedAutomaticRules.contains(evidence.id)
            && item.selectionRestrictions.isEmpty
            && (item.cacheRecommendation?.automaticAllowed != false)
            && item.badge.isEmpty
            && item.duplicateEvidence == nil
        if downgradeFromDescendant {
            item.ruleEvidence = CleanupRuleEvidence(
                id: evidence.id,
                tier: .review,
                reason: evidence.reason,
                defaultSelected: false,
                containerPath: evidence.containerPath,
                containerIdentity: evidence.containerIdentity
            )
        }
        item.evaluationReason = .matchedExecutableRule

        if isChildrenOnlyRule && isDirectoryTarget {
            if !AppConfig.RuleIDs.logRules.contains(evidence.id) && !OpenFileGuard.isIdle(item.url, fresh: false) {
                item.locked = true
                item.isSelected = false
                item.safety = .caution
                item.selectionRestrictions.insert(.readOnlyAsset)
                item.evaluationReason = .runningProcessLocked
                item.ruleEvidence = CleanupRuleEvidence(
                    id: evidence.id,
                    tier: .readOnly,
                    reason: .whitelistProtected,
                    defaultSelected: false
                )
                attachBlockedRecommendation(&item, identity: targetIdentity)
                item.isRuleEvaluated = true
                IOScanContext.recordEvaluation(.runningProcessLocked, tier: .readOnly, bytes: physicalBytes)
                return item
            }
            switch expandContainerOutcome(for: item, evidence: evidence) {
            case .empty:
                item.children = []
                item.size = 0
                item.measuredBytes = 0
                item.isSelected = false
                item.locked = false
                item.safety = .caution
                item.cacheRecommendation = JunkCacheRecommendationPolicy.evaluate(
                    url: item.url,
                    unitURL: item.url,
                    unitIdentity: targetIdentity,
                    ruleEvidence: evidence,
                    allocatedBytes: 0,
                    safetyGatePassed: true,
                    store: store
                )
                item.isRuleEvaluated = true
                return item
            case .expanded(let rawChildren, let totalBytes):
                let isLogContainer = AppConfig.RuleIDs.logRules.contains(evidence.id)
                let shouldLockWholeContainer = isLogContainer
                    ? rawChildren.allSatisfy({ $0.locked == true })
                    : rawChildren.contains(where: { $0.locked == true })
                if shouldLockWholeContainer {
                    let blockedUnitRec = JunkCacheRecommendationPolicy.evaluate(
                        url: item.url,
                        unitURL: item.url,
                        unitIdentity: targetIdentity,
                        ruleEvidence: evidence,
                        allocatedBytes: totalBytes,
                        safetyGatePassed: false,
                        store: store
                    )
                    let lockedChildren = rawChildren.map { child -> ScanItem in
                        var c = child
                        c.locked = true
                        c.isSelected = false
                        c.safety = .caution
                        c.selectionRestrictions.insert(.readOnlyAsset)
                        c.cacheRecommendation = blockedUnitRec
                        if let ce = c.ruleEvidence {
                            c.ruleEvidence = CleanupRuleEvidence(
                                id: ce.id,
                                tier: .readOnly,
                                reason: .whitelistProtected,
                                defaultSelected: false,
                                containerPath: ce.containerPath,
                                containerIdentity: ce.containerIdentity
                            )
                        }
                        return c
                    }
                    item.children = lockedChildren
                    item.size = totalBytes
                    item.measuredBytes = totalBytes
                    item.locked = true
                    item.isSelected = false
                    item.safety = .caution
                    item.selectionRestrictions.insert(.readOnlyAsset)
                    item.cacheRecommendation = blockedUnitRec
                    item.ruleEvidence = CleanupRuleEvidence(
                        id: evidence.id,
                        tier: .readOnly,
                        reason: .whitelistProtected,
                        defaultSelected: false
                    )
                    if let firstReason = rawChildren.first(where: { $0.locked == true })?.evaluationReason
                        ?? rawChildren.compactMap(\.evaluationReason).first {
                        item.evaluationReason = firstReason
                    }
                } else {
                    let unitRec = JunkCacheRecommendationPolicy.evaluate(
                        url: item.url,
                        unitURL: item.url,
                        unitIdentity: targetIdentity,
                        ruleEvidence: evidence,
                        allocatedBytes: totalBytes,
                        safetyGatePassed: true,
                        store: store
                    )
                    let propagatedChildren = rawChildren.map { child -> ScanItem in
                        var c = child
                        if c.action == .emptyContainer,
                           let cRec = c.cacheRecommendation,
                           cRec.profileID != nil,
                           cRec.ruleID != evidence.id {
                            return c
                        }
                        // Check precise child units only when the parent has no profile.
                        // A known parent still governs its full size and rebuild impact.
                        let ownRec = c.cacheRecommendation ?? (unitRec.profileID == nil
                            ? JunkCacheRecommendationPolicy.evaluate(url: c.url, unitURL: c.url,
                                unitIdentity: c.fileIdentity, ruleEvidence: c.ruleEvidence,
                                allocatedBytes: c.measuredBytes ?? c.size,
                                safetyGatePassed: c.locked != true, store: store)
                            : nil)
                        let childRec = unitRec.profileID == nil && ownRec?.profileID != nil
                            && FileUtil.isStrictDescendant(c.url, of: item.url) ? ownRec! : unitRec
                        c.cacheRecommendation = childRec
                        switch childRec.state {
                        case .blocked:
                            c.selectionRestrictions.insert(.readOnlyAsset)
                            c.isSelected = false
                            c.safety = .caution
                        case .unknownReview:
                            if !childRec.automaticAllowed {
                                if childRec.reasons == [.profileMissing] {
                                    if let bytes = childRec.allocatedBytes,
                                       store.cacheRecommendationConfig.appSuggestionBytes > 0,
                                       bytes >= store.cacheRecommendationConfig.appSuggestionBytes {
                                        c.selectionRestrictions.insert(.largeCache)
                                    }
                                    c.selectionRestrictions.insert(.productPolicy)
                                } else {
                                    c.selectionRestrictions.insert(.unknownImpact)
                                }
                                c.isSelected = false
                                c.safety = .caution
                            }
                        case .suggestedLarge:
                            c.selectionRestrictions.insert(.largeCache)
                            c.isSelected = false
                            c.safety = .caution
                            if let ce = c.ruleEvidence, ce.tier == .automatic {
                                c.ruleEvidence = CleanupRuleEvidence(
                                    id: ce.id,
                                    tier: .review,
                                    reason: ce.reason,
                                    defaultSelected: false,
                                    containerPath: ce.containerPath,
                                    containerIdentity: ce.containerIdentity
                                )
                            }
                        case .ordinary:
                            if !childRec.automaticAllowed {
                                c.selectionRestrictions.insert(.productPolicy)
                                c.isSelected = false
                                c.safety = .caution
                            }
                        }
                        return c
                    }
                    item.children = propagatedChildren
                    item.size = totalBytes
                    item.measuredBytes = totalBytes
                    item.cacheRecommendation = unitRec
                    switch unitRec.state {
                    case .blocked:
                        item.selectionRestrictions.insert(.readOnlyAsset)
                    case .unknownReview:
                        if !unitRec.automaticAllowed {
                            if unitRec.reasons == [.profileMissing] {
                                if let bytes = unitRec.allocatedBytes,
                                   store.cacheRecommendationConfig.appSuggestionBytes > 0,
                                   bytes >= store.cacheRecommendationConfig.appSuggestionBytes {
                                    item.selectionRestrictions.insert(.largeCache)
                                }
                                item.selectionRestrictions.insert(.productPolicy)
                            } else {
                                item.selectionRestrictions.insert(.unknownImpact)
                            }
                        }
                    case .suggestedLarge:
                        item.selectionRestrictions.insert(.largeCache)
                        if let ie = item.ruleEvidence, ie.tier == .automatic {
                            item.ruleEvidence = CleanupRuleEvidence(
                                id: ie.id,
                                tier: .review,
                                reason: ie.reason,
                                defaultSelected: false,
                                containerPath: ie.containerPath,
                                containerIdentity: ie.containerIdentity
                            )
                        }
                    case .ordinary:
                        if !unitRec.automaticAllowed {
                            item.selectionRestrictions.insert(.productPolicy)
                        }
                    }
                    item.isSelected = propagatedChildren.contains { $0.isSelected }
                    item.safety = item.isSelected ? .safe : .caution
                    item.locked = false
                    if !item.isSelected {
                        item.selectionRestrictions.insert(.productPolicy)
                    }
                    item.action = .emptyContainer
                }
                item.isRuleEvaluated = true
                return item
            case .failed(var lockedContainer, _):
                attachBlockedRecommendation(&lockedContainer, identity: targetIdentity)
                return lockedContainer
            }
        }
        IOScanContext.recordEvaluation(
            .matchedExecutableRule,
            tier: item.ruleEvidence?.tier ?? evidence.tier,
            bytes: physicalBytes
        )
        item.isRuleEvaluated = true
        return item
    }
}
