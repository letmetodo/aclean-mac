import Foundation

// ============================================================
//  RuleAwareDeduplicator —— 规则感知去重与父子重叠裁决器 (Section 3.3.2)
// ============================================================

struct RuleAwareDeduplicator {
    /// P2 (Section 5.3): 增量路径组件字典树，支持 O(k) 祖先查询、O(subtree) 后代查询与直接存活子项体积扣减

    private(set) var records: [DeduplicationRecord] = []
    private(set) var acceptedLeafByPath: [String: ScanItem] = [:]
    private(set) var droppedLeafPaths: Set<String> = []
    var rawLeafSizeByPath: [String: Int64] = [:]
    var pathTrie = PathTrie()

    static func canonicalPath(for url: URL) -> String {
        let raw = url.path
        guard !raw.isEmpty else { return "" }
        let std = url.standardizedFileURL.path
        return SymlinkGuard.canonicalizeMacOSSystemPrefix(std)
    }

    static func isProtectionOrRuleLocked(_ item: ScanItem) -> Bool {
        return item.locked == true || item.ruleEvidence?.executable == false
    }

    static func specificity(of item: ScanItem, store: AuthoredRules) -> Int {
        guard let ev = item.ruleEvidence, let rule = store.junk[ev.id] else { return 0 }
        let lookup = ev.containerPath.map { URL(fileURLWithPath: $0) } ?? item.url
        return store.matchingPathLength(lookup, rule: rule)
    }

    static func tierRank(of item: ScanItem) -> Int {
        if let tier = item.ruleEvidence?.tier {
            return tier.conservatismRank
        }
        switch item.safety {
        case .risky:   return 3
        case .caution: return 2
        case .safe:    return 1
        }
    }

    static func actionRank(of item: ScanItem, store: AuthoredRules) -> Int {
        if let ruleID = item.ruleEvidence?.id, let rule = store.junk[ruleID] {
            switch rule.action {
            case "read_only", "native": return 3
            case "trash_children_only": return 2
            case "trash": return 1
            default: return 3
            }
        }
        if item.ruleEvidence?.containerPath != nil {
            return 2
        }
        return 1
    }

    /// 比较同一规范化物理路径上的两个候选，返回 (winner, loser, reason)
    static func adjudicateSamePath(
        _ first: ScanItem,
        _ second: ScanItem,
        store: AuthoredRules = KnowledgeBaseManager.shared.authored
    ) -> (winner: ScanItem, loser: ScanItem, reason: String) {
        let a = first
        let b = second

        let aProtLocked = isProtectionOrRuleLocked(a)
        let bProtLocked = isProtectionOrRuleLocked(b)
        var firstWins = true
        var reason = "exact_path_duplicate"

        // 优先级 1：锁定与保护优先
        if aProtLocked != bProtLocked {
            firstWins = aProtLocked
            reason = "locked_or_protected_priority"
        } else if (a.ruleEvidence != nil) != (b.ruleEvidence != nil) {
            // 优先级 2：有效规则证据优先
            firstWins = (a.ruleEvidence != nil)
            reason = "valid_rule_evidence_priority"
        } else if (a.locked == true) != (b.locked == true) {
            firstWins = (a.locked == true)
            reason = "locked_or_protected_priority"
        } else {
            // 优先级 3：规则匹配具体度 Specificity 优先
            let aSpec = specificity(of: a, store: store)
            let bSpec = specificity(of: b, store: store)
            if aSpec != bSpec {
                firstWins = aSpec > bSpec
                reason = "rule_specificity_priority"
            } else {
                // 优先级 4：保守风险等级优先 (L4 > L3 > L2 > L1)
                let aTier = tierRank(of: a)
                let bTier = tierRank(of: b)
                if aTier != bTier {
                    firstWins = aTier > bTier
                    reason = "conservative_tier_priority"
                } else {
                    // 优先级 5：保守清理动作优先 (read_only > trash_children_only > trash)
                    let aAct = actionRank(of: a, store: store)
                    let bAct = actionRank(of: b, store: store)
                    if aAct != bAct {
                        firstWins = aAct > bAct
                        reason = "conservative_action_priority"
                    } else if let aID = a.ruleEvidence?.id, let bID = b.ruleEvidence?.id, aID != bID {
                        let profileRuleIDs = Set(store.matchingCacheProfileUnits(for: a.url, ruleID: nil, enforceCacheDataPrecedence: false).map { $0.profile.ruleID })
                        let aMatchesProfile = profileRuleIDs.contains(aID)
                        let bMatchesProfile = profileRuleIDs.contains(bID)
                        if aMatchesProfile != bMatchesProfile {
                            firstWins = aMatchesProfile
                            reason = "cache_profile_rule_priority"
                        } else {
                            firstWins = aID < bID
                            reason = "deterministic_rule_id_priority"
                        }
                    }
                }
            }
        }

        var winner = firstWins ? a : b
        let loser = firstWins ? b : a
        let mergedPhysical = max(a.measuredBytes ?? a.size, b.measuredBytes ?? b.size)
        winner.measuredBytes = mergedPhysical
        winner.selectionRestrictions.formUnion(loser.selectionRestrictions)
        let mergedOwners = Set(winner.ownerBundleIDs).union(loser.ownerBundleIDs).sorted()
        let ownersChanged = mergedOwners != a.ownerBundleIDs
        winner.ownerBundleIDs = mergedOwners
        let mergedOwnerRunning = mergedOwners.contains(where: { ProcessGuard.isAppRunning(bundleID: $0) })
        if mergedOwnerRunning {
            winner.locked = true
            winner.isSelected = false
            winner.safety = .caution
            winner.selectionRestrictions.insert(.readOnlyAsset)
            winner.evaluationReason = .runningProcessLocked
            if let wEv = winner.ruleEvidence {
                winner.ruleEvidence = CleanupRuleEvidence(
                    id: wEv.id,
                    tier: .readOnly,
                    reason: .whitelistProtected,
                    defaultSelected: false,
                    containerPath: wEv.containerPath,
                    containerIdentity: wEv.containerIdentity
                )
            }
        }
        if !firstWins || ownersChanged || winner.locked != a.locked || winner.ruleEvidence?.id != a.ruleEvidence?.id || winner.ruleEvidence?.tier != a.ruleEvidence?.tier {
            IOScanContext.recordContextRetry(canonicalPath: winner.url.path, reason: .ruleContextChanged)
        }
        if winner.cacheRecommendation == nil {
            winner.cacheRecommendation = loser.cacheRecommendation
        }
        if aProtLocked || bProtLocked || mergedOwnerRunning || winner.selectionRestrictions.contains(.readOnlyAsset) {
            winner.locked = true
            winner.isSelected = false
            winner.safety = .caution
            winner.selectionRestrictions.insert(.readOnlyAsset)
            winner.cacheRecommendation = JunkCacheRecommendationPolicy.evaluate(
                url: winner.url,
                unitIdentity: winner.fileIdentity,
                ruleEvidence: winner.ruleEvidence,
                allocatedBytes: mergedPhysical,
                safetyGatePassed: false,
                store: store
            )
        } else if !winner.selectionRestrictions.isEmpty {
            winner.isSelected = false
            winner.safety = .caution
        }
        if winner.ruleEvidence?.containerPath == nil,
           let loserContainer = loser.ruleEvidence?.containerPath,
           let winEv = winner.ruleEvidence,
           store.junk[winEv.id]?.action == "trash_children_only" {
            var updatedEv = winEv
            updatedEv.containerPath = loserContainer
            updatedEv.containerIdentity = loser.ruleEvidence?.containerIdentity
            winner.ruleEvidence = updatedEv
        }
        return (winner, loser, reason)
    }

    static func lockParentItem(
        _ parent: ScanItem,
        parentPath: String,
        descendantPath: String,
        descendantRuleID: String?,
        subtractBytes: Int64
    ) -> ScanItem {
        let wasAlreadyNonExecutable = (parent.locked == true || parent.ruleEvidence?.executable == false)
        var lockedParent = parent
        if lockedParent.measuredBytes == nil {
            lockedParent.measuredBytes = parent.size
        }
        lockedParent.locked = true
        lockedParent.isSelected = false
        lockedParent.safety = .caution
        lockedParent.selectionRestrictions.insert(.readOnlyAsset)
        if !wasAlreadyNonExecutable
            || lockedParent.evaluationReason == nil
            || lockedParent.evaluationReason == .matchedExecutableRule {
            lockedParent.evaluationReason = .descendantRuleConflict(
                path: parentPath,
                descendantPath: descendantPath,
                ruleId: descendantRuleID ?? "locked_descendant"
            )
        }
        if let ev = lockedParent.ruleEvidence {
            lockedParent.ruleEvidence = CleanupRuleEvidence(
                id: ev.id,
                tier: .readOnly,
                reason: .whitelistProtected,
                defaultSelected: false,
                containerPath: ev.containerPath,
                containerIdentity: ev.containerIdentity
            )
        }
        lockedParent.size = max(0, lockedParent.size - subtractBytes)
        return lockedParent
    }

    static func mergeChildIntoCleanableAncestor(parent: ScanItem, child: ScanItem) -> ScanItem {
        var updatedParent = parent
        if !child.isSelected {
            updatedParent.isSelected = false
        }
        if child.safety != .safe && updatedParent.safety == .safe {
            updatedParent.safety = child.safety
        }
        if let pEv = updatedParent.ruleEvidence,
           let cEv = child.ruleEvidence,
           cEv.tier == .review && pEv.tier == .automatic {
            updatedParent.ruleEvidence = CleanupRuleEvidence(
                id: pEv.id,
                tier: .review,
                reason: pEv.reason,
                defaultSelected: false,
                containerPath: pEv.containerPath,
                containerIdentity: pEv.containerIdentity
            )
        }
        return updatedParent
    }

    struct LeafSlot {
        var indexPath: [Int]
        var item: ScanItem
        var rawSize: Int64
        var canonicalPath: String
        var dropped: Bool = false
    }

    /// 对一批已完成规则评估的 ScanItem 执行同路径 + 父子路径去重裁决并生成留痕（基于 PathTrie O(N*k) 增量查找）
    static func deduplicate(_ items: [ScanItem]) -> (items: [ScanItem], records: [DeduplicationRecord]) {
        if IOScanContext.isCancelled {
            return ([], [])
        }
        let store = KnowledgeBaseManager.shared.authored
        var slots: [LeafSlot] = []
        var comparisons = 0
        func collectLeaves(from list: [ScanItem], prefix: [Int]) {
            if IOScanContext.isCancelled { return }
            for (idx, item) in list.enumerated() {
                if IOScanContext.isCancelled { return }
                if JunkRulePolicy.isEmptyVerifiedContainer(item) {
                    continue
                }
                let path = prefix + [idx]
                if item.children.isEmpty {
                    let rawSize = item.measuredBytes ?? item.size
                    var leafItem = item
                    leafItem.measuredBytes = rawSize
                    slots.append(LeafSlot(
                        indexPath: path,
                        item: leafItem,
                        rawSize: rawSize,
                        canonicalPath: canonicalPath(for: item.url)
                    ))
                } else {
                    collectLeaves(from: item.children, prefix: path)
                }
            }
        }
        collectLeaves(from: items, prefix: [])
        if IOScanContext.isCancelled {
            return ([], [])
        }

        var records: [DeduplicationRecord] = []
        var batchTrie = PathTrie()

        // 1. 同路径重叠裁决
        var pathWinnerSlotIdx: [String: Int] = [:]
        for idx in slots.indices {
            if IOScanContext.isCancelled {
                IOScanContext.addDeduplicationComparisons(comparisons)
                return ([], records)
            }
            let path = slots[idx].canonicalPath
            guard !path.isEmpty else { continue }
            comparisons += 1
            if let prevIdx = pathWinnerSlotIdx[path] {
                let prevItem = slots[prevIdx].item
                let currItem = slots[idx].item
                let mergedRawSize = max(slots[prevIdx].rawSize, slots[idx].rawSize)
                let res = adjudicateSamePath(prevItem, currItem, store: store)
                var winnerItem = res.winner
                winnerItem.size = mergedRawSize
                winnerItem.measuredBytes = mergedRawSize
                if res.winner.id == prevItem.id {
                    slots[prevIdx].item = winnerItem
                    slots[prevIdx].rawSize = mergedRawSize
                    slots[idx].dropped = true
                } else {
                    slots[idx].item = winnerItem
                    slots[idx].rawSize = mergedRawSize
                    slots[prevIdx].dropped = true
                    pathWinnerSlotIdx[path] = idx
                }
                let rec = DeduplicationRecord(
                    droppedPath: path,
                    droppedRuleId: res.loser.ruleEvidence?.id,
                    winnerPath: path,
                    winnerRuleId: res.winner.ruleEvidence?.id,
                    reason: res.reason
                )
                records.append(rec)
                IOScanContext.recordDeduplication(rec)
            } else {
                pathWinnerSlotIdx[path] = idx
                batchTrie.insert(path: path)
            }
        }

        // 2. 父子路径重叠裁决（基于 PathTrie 仅访问存在真实子孙的父节点，按路径长度自底向上）
        let activeIndices = slots.indices
            .filter { !slots[$0].dropped && !slots[$0].canonicalPath.isEmpty }
            .sorted { slots[$0].canonicalPath.count > slots[$1].canonicalPath.count }
        for pIdx in activeIndices {
            if IOScanContext.isCancelled {
                IOScanContext.addDeduplicationComparisons(comparisons)
                return ([], records)
            }
            guard !slots[pIdx].dropped else { continue }
            let pPath = slots[pIdx].canonicalPath
            let descPaths = batchTrie.descendantPaths(of: pPath)
            guard !descPaths.isEmpty else { continue }
            for cPath in descPaths {
                if IOScanContext.isCancelled {
                    IOScanContext.addDeduplicationComparisons(comparisons)
                    return ([], records)
                }
                guard let cIdx = pathWinnerSlotIdx[cPath], cIdx != pIdx, !slots[cIdx].dropped else { continue }
                comparisons += 1
                let parentItem = slots[pIdx].item
                let childItem = slots[cIdx].item

                let cIsLocked = childItem.locked == true || childItem.ruleEvidence?.executable == false
                let pIsLocked = parentItem.locked == true || parentItem.ruleEvidence?.executable == false
                let cTier = tierRank(of: childItem)
                let pTier = tierRank(of: parentItem)
                let cAct = actionRank(of: childItem, store: store)
                let pAct = actionRank(of: parentItem, store: store)

                let childIsStricter = cIsLocked || cTier > pTier || cAct > pAct || parentItem.action != .trash || childItem.action != .trash
                if childIsStricter {
                    slots[pIdx].item = lockParentItem(
                        slots[pIdx].item,
                        parentPath: pPath,
                        descendantPath: cPath,
                        descendantRuleID: childItem.ruleEvidence?.id,
                        subtractBytes: 0
                    )
                    let rec = DeduplicationRecord(
                        droppedPath: pPath,
                        droppedRuleId: parentItem.ruleEvidence?.id,
                        winnerPath: cPath,
                        winnerRuleId: childItem.ruleEvidence?.id,
                        reason: "parent_locked_due_to_stricter_descendant"
                    )
                    records.append(rec)
                    IOScanContext.recordDeduplication(rec)
                } else if !pIsLocked {
                    slots[cIdx].dropped = true
                    batchTrie.remove(path: cPath)
                    pathWinnerSlotIdx.removeValue(forKey: cPath)
                    slots[pIdx].item = mergeChildIntoCleanableAncestor(parent: slots[pIdx].item, child: childItem)
                    let rec = DeduplicationRecord(
                        droppedPath: cPath,
                        droppedRuleId: childItem.ruleEvidence?.id,
                        winnerPath: pPath,
                        winnerRuleId: parentItem.ruleEvidence?.id,
                        reason: "merged_into_cleanable_ancestor"
                    )
                    records.append(rec)
                    IOScanContext.recordDeduplication(rec)
                }
            }
        }

        // 2b. 基于 PathTrie 直接后代原始体积扣减（仅对存在存活后代的父节点计算，O(1) 跳过普通叶子）
        let survivingIndices = slots.indices.filter { !slots[$0].dropped && !slots[$0].canonicalPath.isEmpty }
        if survivingIndices.count > 1 {
            for pIdx in survivingIndices {
                if IOScanContext.isCancelled {
                    IOScanContext.addDeduplicationComparisons(comparisons)
                    return ([], records)
                }
                let pPath = slots[pIdx].canonicalPath
                let directDescPaths = batchTrie.directDescendantPaths(of: pPath)
                var directChildrenBytes: Int64 = 0
                for dPath in directDescPaths {
                    if IOScanContext.isCancelled {
                        IOScanContext.addDeduplicationComparisons(comparisons)
                        return ([], records)
                    }
                    comparisons += 1
                    if let dIdx = pathWinnerSlotIdx[dPath], !slots[dIdx].dropped {
                        directChildrenBytes += slots[dIdx].rawSize
                    }
                }
                slots[pIdx].item.measuredBytes = slots[pIdx].rawSize
                slots[pIdx].item.size = max(0, slots[pIdx].rawSize - directChildrenBytes)
            }
        }
        IOScanContext.addDeduplicationComparisons(comparisons)
        if IOScanContext.isCancelled {
            return ([], records)
        }

        // 3. 自底向上重组结果
        let slotByPath = Dictionary(uniqueKeysWithValues: slots.map { ($0.indexPath, $0) })
        func rebuildList(_ list: [ScanItem], prefix: [Int]) -> [ScanItem] {
            if IOScanContext.isCancelled { return [] }
            var rebuilt: [ScanItem] = []
            rebuilt.reserveCapacity(list.count)
            for (idx, original) in list.enumerated() {
                if IOScanContext.isCancelled { return rebuilt }
                if JunkRulePolicy.isEmptyVerifiedContainer(original) {
                    continue
                }
                let currentPath = prefix + [idx]
                if original.children.isEmpty {
                    if let slot = slotByPath[currentPath], !slot.dropped {
                        rebuilt.append(slot.item)
                    }
                } else {
                    let surviving = rebuildList(original.children, prefix: currentPath)
                    guard !surviving.isEmpty else { continue }
                    var copy = original
                    copy.children = surviving
                    copy.size = surviving.reduce(0) { $0 + $1.size }
                    copy.measuredBytes = surviving.reduce(0) { $0 + ($1.measuredBytes ?? $1.size) }
                    copy.isSelected = surviving.contains { $0.isSelected }
                    if surviving.allSatisfy({ $0.locked == true }) {
                        copy.locked = true
                        copy.isSelected = false
                        copy.safety = .caution
                    } else {
                        copy.locked = false
                        copy.safety = copy.isSelected ? .safe : .caution
                    }
                    rebuilt.append(copy)
                }
            }
            return rebuilt
        }
        let out = rebuildList(items, prefix: [])
        return (out, records)
    }

    mutating func recomputeAcceptedLeafSizes(forAffectedAncestors ancestorPaths: [String]) {
        guard !ancestorPaths.isEmpty, !IOScanContext.isCancelled else { return }
        var comparisons = 0
        for pPath in ancestorPaths {
            if IOScanContext.isCancelled { break }
            guard var pItem = acceptedLeafByPath[pPath] else { continue }
            let pRaw = rawLeafSizeByPath[pPath] ?? pItem.measuredBytes ?? pItem.size
            let directDescPaths = pathTrie.directDescendantPaths(of: pPath)
            var directChildrenBytes: Int64 = 0
            for dPath in directDescPaths {
                if IOScanContext.isCancelled { break }
                comparisons += 1
                directChildrenBytes += (rawLeafSizeByPath[dPath] ?? acceptedLeafByPath[dPath]?.measuredBytes ?? acceptedLeafByPath[dPath]?.size ?? 0)
            }
            pItem.measuredBytes = pRaw
            pItem.size = max(0, pRaw - directChildrenBytes)
            acceptedLeafByPath[pPath] = pItem
        }
        IOScanContext.addDeduplicationComparisons(comparisons)
    }

    /// 跨组流式去重：对新进入的一批已评估 ScanItem 先做组内规则去重，再通过 PathTrie 与历史已接受候选做 O(k) 跨组规则裁决
    mutating func accept(_ items: [ScanItem]) -> [ScanItem] {
        if IOScanContext.isCancelled { return [] }
        let store = KnowledgeBaseManager.shared.authored
        var comparisons = 0
        func recordIncomingRawSizes(_ list: [ScanItem]) {
            if IOScanContext.isCancelled { return }
            for item in list {
                if IOScanContext.isCancelled { return }
                if JunkRulePolicy.isEmptyVerifiedContainer(item) { continue }
                if item.children.isEmpty {
                    let path = Self.canonicalPath(for: item.url)
                    if !path.isEmpty {
                        let raw = item.measuredBytes ?? item.size
                        rawLeafSizeByPath[path] = max(rawLeafSizeByPath[path] ?? 0, raw)
                    }
                } else {
                    recordIncomingRawSizes(item.children)
                }
            }
        }
        recordIncomingRawSizes(items)
        if IOScanContext.isCancelled { return [] }

        let batchResult = Self.deduplicate(items)
        records.append(contentsOf: batchResult.records)
        if IOScanContext.isCancelled { return [] }
        var affectedAncestors = Set<String>()

        func acceptLeaf(_ candidate: ScanItem) -> ScanItem? {
            if IOScanContext.isCancelled { return nil }
            let path = Self.canonicalPath(for: candidate.url)
            guard !path.isEmpty else { return candidate }
            comparisons += 1

            // 1. 同路径重叠
            if let existing = acceptedLeafByPath[path] {
                let res = Self.adjudicateSamePath(existing, candidate, store: store)
                acceptedLeafByPath[path] = res.winner
                pathTrie.insert(path: path)
                droppedLeafPaths.remove(path)
                affectedAncestors.insert(path)
                for anc in pathTrie.ancestorPaths(of: path) {
                    affectedAncestors.insert(anc)
                }
                let rec = DeduplicationRecord(
                    droppedPath: path,
                    droppedRuleId: res.loser.ruleEvidence?.id,
                    winnerPath: path,
                    winnerRuleId: res.winner.ruleEvidence?.id,
                    reason: res.reason
                )
                records.append(rec)
                IOScanContext.recordDeduplication(rec)
                return nil
            }

            var currentCandidate = candidate
            let raw = rawLeafSizeByPath[path] ?? currentCandidate.measuredBytes ?? currentCandidate.size
            currentCandidate.measuredBytes = raw
            currentCandidate.size = raw

            // 2a. 查找已接受的祖先节点 (O(k), k <= 路径深度)
            let ancestorPaths = pathTrie.ancestorPaths(of: path)
            for existingPath in ancestorPaths {
                if IOScanContext.isCancelled { return nil }
                comparisons += 1
                guard let existingItem = acceptedLeafByPath[existingPath] else { continue }
                let cIsLocked = currentCandidate.locked == true || currentCandidate.ruleEvidence?.executable == false
                let pIsLocked = existingItem.locked == true || existingItem.ruleEvidence?.executable == false
                let cTier = Self.tierRank(of: currentCandidate)
                let pTier = Self.tierRank(of: existingItem)
                let cAct = Self.actionRank(of: currentCandidate, store: store)
                let pAct = Self.actionRank(of: existingItem, store: store)
                let childIsStricter = cIsLocked || cTier > pTier || cAct > pAct || existingItem.action != .trash || currentCandidate.action != .trash
                if childIsStricter {
                    let lockedParent = Self.lockParentItem(
                        existingItem,
                        parentPath: existingPath,
                        descendantPath: path,
                        descendantRuleID: currentCandidate.ruleEvidence?.id,
                        subtractBytes: 0
                    )
                    acceptedLeafByPath[existingPath] = lockedParent
                    affectedAncestors.insert(existingPath)
                    let rec = DeduplicationRecord(
                        droppedPath: existingPath,
                        droppedRuleId: existingItem.ruleEvidence?.id,
                        winnerPath: path,
                        winnerRuleId: currentCandidate.ruleEvidence?.id,
                        reason: "parent_locked_due_to_stricter_descendant"
                    )
                    records.append(rec)
                    IOScanContext.recordDeduplication(rec)
                } else if !pIsLocked {
                    let updatedParent = Self.mergeChildIntoCleanableAncestor(parent: existingItem, child: currentCandidate)
                    acceptedLeafByPath[existingPath] = updatedParent
                    affectedAncestors.insert(existingPath)
                    let rec = DeduplicationRecord(
                        droppedPath: path,
                        droppedRuleId: currentCandidate.ruleEvidence?.id,
                        winnerPath: existingPath,
                        winnerRuleId: existingItem.ruleEvidence?.id,
                        reason: "merged_into_cleanable_ancestor"
                    )
                    records.append(rec)
                    IOScanContext.recordDeduplication(rec)
                    return nil
                }
            }

            // 2b. 查找已接受的后代节点 (若无后代则 O(k) 立即返回空)
            let descendantPaths = pathTrie.descendantPaths(of: path)
            for existingPath in descendantPaths {
                if IOScanContext.isCancelled { return nil }
                comparisons += 1
                guard let existingItem = acceptedLeafByPath[existingPath] else { continue }
                let cIsLocked = existingItem.locked == true || existingItem.ruleEvidence?.executable == false
                let pIsLocked = currentCandidate.locked == true || currentCandidate.ruleEvidence?.executable == false
                let cTier = Self.tierRank(of: existingItem)
                let pTier = Self.tierRank(of: currentCandidate)
                let cAct = Self.actionRank(of: existingItem, store: store)
                let pAct = Self.actionRank(of: currentCandidate, store: store)
                let childIsStricter = cIsLocked || cTier > pTier || cAct > pAct || currentCandidate.action != .trash || existingItem.action != .trash
                if childIsStricter {
                    currentCandidate = Self.lockParentItem(
                        currentCandidate,
                        parentPath: path,
                        descendantPath: existingPath,
                        descendantRuleID: existingItem.ruleEvidence?.id,
                        subtractBytes: 0
                    )
                    affectedAncestors.insert(path)
                    let rec = DeduplicationRecord(
                        droppedPath: path,
                        droppedRuleId: candidate.ruleEvidence?.id,
                        winnerPath: existingPath,
                        winnerRuleId: existingItem.ruleEvidence?.id,
                        reason: "parent_locked_due_to_stricter_descendant"
                    )
                    records.append(rec)
                    IOScanContext.recordDeduplication(rec)
                } else if !pIsLocked {
                    currentCandidate = Self.mergeChildIntoCleanableAncestor(parent: currentCandidate, child: existingItem)
                    acceptedLeafByPath.removeValue(forKey: existingPath)
                    pathTrie.remove(path: existingPath)
                    droppedLeafPaths.insert(existingPath)
                    affectedAncestors.insert(path)
                    let rec = DeduplicationRecord(
                        droppedPath: existingPath,
                        droppedRuleId: existingItem.ruleEvidence?.id,
                        winnerPath: path,
                        winnerRuleId: currentCandidate.ruleEvidence?.id,
                        reason: "merged_into_cleanable_ancestor"
                    )
                    records.append(rec)
                    IOScanContext.recordDeduplication(rec)
                }
            }

            acceptedLeafByPath[path] = currentCandidate
            pathTrie.insert(path: path)
            droppedLeafPaths.remove(path)
            if !ancestorPaths.isEmpty {
                for anc in ancestorPaths {
                    affectedAncestors.insert(anc)
                }
            }
            return currentCandidate
        }

        func acceptTree(_ list: [ScanItem]) -> [ScanItem] {
            if IOScanContext.isCancelled { return [] }
            var out: [ScanItem] = []
            out.reserveCapacity(list.count)
            for item in list {
                if IOScanContext.isCancelled { return out }
                if item.children.isEmpty {
                    if let accepted = acceptLeaf(item) {
                        out.append(accepted)
                    }
                } else {
                    let kids = acceptTree(item.children)
                    guard !kids.isEmpty else { continue }
                    var copy = item
                    copy.children = kids
                    copy.size = kids.reduce(0) { $0 + $1.size }
                    copy.measuredBytes = kids.reduce(0) { $0 + ($1.measuredBytes ?? $1.size) }
                    copy.isSelected = kids.contains { $0.isSelected }
                    if kids.allSatisfy({ $0.locked == true }) {
                        copy.locked = true
                        copy.isSelected = false
                        copy.safety = .caution
                    } else {
                        copy.locked = false
                        copy.safety = copy.isSelected ? .safe : .caution
                    }
                    out.append(copy)
                }
            }
            return out
        }

        var acceptedTree = acceptTree(batchResult.items)
        IOScanContext.addDeduplicationComparisons(comparisons)
        guard !IOScanContext.isCancelled else { return [] }
        recomputeAcceptedLeafSizes(forAffectedAncestors: Array(affectedAncestors))
        reconcile(items: &acceptedTree)
        return acceptedTree
    }

}
