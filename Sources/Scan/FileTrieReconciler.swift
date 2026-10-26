import Foundation

extension RuleAwareDeduplicator {
    struct PathTrie {
        final class Node {
            var children: [Substring: Node] = [:]
            var terminalPath: String? = nil

            init(children: [Substring: Node] = [:], terminalPath: String? = nil) {
                self.children = children
                self.terminalPath = terminalPath
            }

            func deepCopy() -> Node {
                let copy = Node(terminalPath: terminalPath)
                copy.children.reserveCapacity(children.count)
                for (k, v) in children {
                    copy.children[k] = v.deepCopy()
                }
                return copy
            }
        }

        private var root = Node()

        private mutating func ensureUnique() {
            if !isKnownUniquelyReferenced(&root) {
                root = root.deepCopy()
            }
        }

        static func components(of path: String) -> [Substring] {
            path.split(separator: "/", omittingEmptySubsequences: true)
        }

        mutating func insert(path: String) {
            guard !path.isEmpty else { return }
            ensureUnique()
            var current = root
            for comp in Self.components(of: path) {
                if let next = current.children[comp] {
                    current = next
                } else {
                    let next = Node()
                    current.children[comp] = next
                    current = next
                }
            }
            current.terminalPath = path
        }

        mutating func remove(path: String) {
            guard !path.isEmpty else { return }
            ensureUnique()
            let comps = Self.components(of: path)
            _ = Self.removeRecursive(node: root, comps: comps, index: 0)
        }

        private static func removeRecursive(node: Node, comps: [Substring], index: Int) -> Bool {
            if index == comps.count {
                node.terminalPath = nil
                return node.children.isEmpty
            }
            let comp = comps[index]
            guard let child = node.children[comp] else { return false }
            let shouldPruneChild = removeRecursive(node: child, comps: comps, index: index + 1)
            if shouldPruneChild {
                node.children.removeValue(forKey: comp)
            }
            return node.terminalPath == nil && node.children.isEmpty
        }

        /// O(k) 查找 path 的所有严格祖先路径（按路径长度降序排列）
        func ancestorPaths(of path: String) -> [String] {
            let comps = Self.components(of: path)
            guard comps.count > 1 else { return [] }
            var found: [String] = []
            var current = root
            for i in 0..<(comps.count - 1) {
                guard let next = current.children[comps[i]] else { break }
                current = next
                if let term = current.terminalPath {
                    found.append(term)
                }
            }
            if found.count > 1 {
                found.sort { $0.count > $1.count }
            }
            return found
        }

        /// 查找 path 的所有严格后代路径（若无子孙则 O(k) 立即返回空数组；否则按路径长度降序返回）
        func descendantPaths(of path: String) -> [String] {
            let comps = Self.components(of: path)
            var current = root
            for comp in comps {
                guard let next = current.children[comp] else { return [] }
                current = next
            }
            guard !current.children.isEmpty else { return [] }
            var found: [String] = []
            Self.collectDescendants(from: current, into: &found)
            if found.count > 1 {
                found.sort { $0.count > $1.count }
            }
            return found
        }

        private static func collectDescendants(from node: Node, into out: inout [String]) {
            if IOScanContext.isCancelled { return }
            for child in node.children.values {
                if IOScanContext.isCancelled { return }
                if let term = child.terminalPath {
                    out.append(term)
                }
                if !child.children.isEmpty {
                    collectDescendants(from: child, into: &out)
                }
            }
        }

        /// 查找 path 下没有中间已接受节点的“直接后代”路径（遇到首个 terminalPath 即停止向该分支更深层下钻）
        func directDescendantPaths(of path: String) -> [String] {
            if IOScanContext.isCancelled { return [] }
            let comps = Self.components(of: path)
            var current = root
            for comp in comps {
                guard let next = current.children[comp] else { return [] }
                current = next
            }
            guard !current.children.isEmpty else { return [] }
            var direct: [String] = []
            Self.collectDirectDescendants(from: current, into: &direct)
            return direct
        }

        private static func collectDirectDescendants(from node: Node, into out: inout [String]) {
            if IOScanContext.isCancelled { return }
            for child in node.children.values {
                if IOScanContext.isCancelled { return }
                if let term = child.terminalPath {
                    out.append(term)
                } else if !child.children.isEmpty {
                    collectDirectDescendants(from: child, into: &out)
                }
            }
        }
    }

    static func applyReconciledLeafState(from latest: ScanItem, to item: ScanItem) -> ScanItem {
        var copy = item
        copy.size = latest.size
        copy.measuredBytes = latest.measuredBytes ?? item.measuredBytes ?? latest.size
        copy.locked = latest.locked
        copy.isSelected = latest.isSelected
        copy.safety = latest.safety
        copy.action = latest.action
        copy.ruleEvidence = latest.ruleEvidence
        copy.evaluationReason = latest.evaluationReason
        copy.authorizationContext = latest.resolvedAuthorizationContext
        copy.fileIdentity = latest.fileIdentity ?? item.fileIdentity
        return copy
    }

    /// 用最新跨组裁决状态原地更新先前已产出的 ScanItem 列表（移除被归并子项，同步被锁定/降级/扣减体积的同路径或父项）
    func reconcile(items: inout [ScanItem]) {
        var updatedItems: [ScanItem] = []
        updatedItems.reserveCapacity(items.count)
        for item in items {
            if item.children.isEmpty {
                let path = Self.canonicalPath(for: item.url)
                if !path.isEmpty {
                    if droppedLeafPaths.contains(path) {
                        continue
                    }
                    if let latest = acceptedLeafByPath[path] {
                        updatedItems.append(Self.applyReconciledLeafState(from: latest, to: item))
                        continue
                    }
                }
                updatedItems.append(item)
            } else {
                var children = item.children
                reconcile(items: &children)
                guard !children.isEmpty else { continue }
                var copy = item
                copy.children = children
                copy.size = children.reduce(0) { $0 + $1.size }
                copy.measuredBytes = children.reduce(0) { $0 + ($1.measuredBytes ?? $1.size) }
                copy.isSelected = children.contains { $0.isSelected }
                if children.allSatisfy({ $0.locked == true }) {
                    copy.locked = true
                    copy.isSelected = false
                    copy.safety = .caution
                } else {
                    copy.locked = false
                    copy.safety = copy.isSelected ? .safe : .caution
                }
                updatedItems.append(copy)
            }
        }
        items = updatedItems
    }

    /// 用最新跨组裁决状态原地更新先前已产出的 ScanGroup 列表
    func reconcile(groups: inout [ScanGroup]) {
        var updatedGroups: [ScanGroup] = []
        updatedGroups.reserveCapacity(groups.count)
        for var g in groups {
            reconcile(items: &g.items)
            guard !g.items.isEmpty else { continue }
            updatedGroups.append(g)
        }
        groups = updatedGroups
    }

    mutating func acceptGroup(_ group: ScanGroup) -> ScanGroup? {
        var g = group
        let evaluated = g.items.map(JunkRulePolicy.apply)
        let accepted = accept(evaluated)
        guard !accepted.isEmpty else { return nil }
        g.items = accepted
        return g
    }

    mutating func acceptGroup(_ group: ScanGroup, into groups: inout [ScanGroup]) -> ScanGroup? {
        let accepted = acceptGroup(group)
        reconcile(groups: &groups)
        if let accepted {
            groups.append(accepted)
        }
        return accepted
    }

    func reconcileSingleNode(_ node: Node) -> (node: Node?, changed: Bool) {
        if !node.isGroup || node.children.isEmpty {
            guard let url = node.url else { return (node, false) }
            let path = Self.canonicalPath(for: url)
            guard !path.isEmpty else { return (node, false) }
            if droppedLeafPaths.contains(path) {
                return (nil, true)
            }
            guard let latest = acceptedLeafByPath[path] else { return (node, false) }
            let newLocked = latest.locked ?? node.locked
            let newAutoSelected = latest.isSelected
            let newSafety = latest.safety
            let newAction = latest.action
            let newSize = latest.size
            let newMeasuredBytes = latest.measuredBytes ?? node.measuredBytes
            let newRuleEvidence = latest.ruleEvidence
            let newEvalReason = latest.evaluationReason
            let newAuthCtx = latest.resolvedAuthorizationContext
            let newSelectionRestrictions = node.selectionRestrictions.union(latest.selectionRestrictions)
            let newCacheRecommendation = latest.cacheRecommendation ?? node.cacheRecommendation
            let didChange = node.locked != newLocked
                || node.autoSelected != newAutoSelected
                || node.safety != newSafety
                || node.action != newAction
                || node.size != newSize
                || node.measuredBytes != newMeasuredBytes
                || node.ruleEvidence != newRuleEvidence
                || node.evaluationReason != newEvalReason
                || node.resolvedAuthorizationContext != newAuthCtx
                || node.selectionRestrictions != newSelectionRestrictions
                || node.cacheRecommendation != newCacheRecommendation
            guard didChange else { return (node, false) }
            var copy = node
            copy.locked = newLocked
            copy.autoSelected = newAutoSelected
            copy.safety = newSafety
            copy.action = newAction
            copy.size = newSize
            copy.measuredBytes = newMeasuredBytes
            copy.ruleEvidence = newRuleEvidence
            copy.evaluationReason = newEvalReason
            copy.authorizationContext = newAuthCtx
            copy.selectionRestrictions = newSelectionRestrictions
            copy.cacheRecommendation = newCacheRecommendation
            copy.fileIdentity = latest.fileIdentity ?? node.fileIdentity
            if (newLocked || newRuleEvidence?.executable == false),
               let evalReason = newEvalReason,
               let evalExplanation = evalReason.localizedExplanation {
                copy.note = evalExplanation
            } else if let reason = newRuleEvidence?.reason {
                copy.note = reason.localizedExplanation
            }
            return (copy, true)
        }

        var updatedChildren: [Node] = []
        updatedChildren.reserveCapacity(node.children.count)
        var anyChildChanged = false
        for child in node.children {
            let (reconciledChild, childChanged) = reconcileSingleNode(child)
            if childChanged {
                anyChildChanged = true
            }
            if let reconciledChild {
                updatedChildren.append(reconciledChild)
            }
        }
        guard anyChildChanged else { return (node, false) }
        guard !updatedChildren.isEmpty else { return (nil, true) }
        var copy = node
        copy.children = updatedChildren
        copy.size = updatedChildren.reduce(0) { $0 + $1.totalSize }
        copy.measuredBytes = updatedChildren.reduce(0) { $0 + ($1.measuredBytes ?? $1.totalSize) }
        if copy.url != nil {
            copy.autoSelected = updatedChildren.contains { $0.autoSelected }
            if updatedChildren.allSatisfy({ $0.locked }) {
                copy.locked = true
                copy.autoSelected = false
                copy.safety = .caution
            } else {
                copy.locked = false
                copy.safety = copy.autoSelected ? .safe : .caution
            }
        } else if updatedChildren.allSatisfy({ $0.locked }) {
            copy.locked = true
            copy.autoSelected = false
            copy.safety = .caution
        }
        return (copy, true)
    }

    /// 用最新跨组裁决状态原地更新先前已加入结果树的 Node，并返回发生变更的根 Node 列表供流式 UI 同步
    @discardableResult
    func reconcile(nodes: inout [Node]) -> [Node] {
        var survivingRoots: [Node] = []
        survivingRoots.reserveCapacity(nodes.count)
        var modifiedForStream: [Node] = []
        for root in nodes {
            let (reconciled, changed) = reconcileSingleNode(root)
            if let reconciled {
                survivingRoots.append(reconciled)
                if changed {
                    modifiedForStream.append(reconciled)
                }
            } else if changed {
                var emptied = root
                emptied.children = []
                emptied.size = 0
                emptied.locked = true
                modifiedForStream.append(emptied)
            }
        }
        nodes = survivingRoots
        return modifiedForStream
    }

    mutating func acceptGroup(_ group: ScanGroup, tags: [String], into nodes: inout [Node]) -> [Node] {
        let accepted = acceptGroup(group)
        var changed = reconcile(nodes: &nodes)
        if let accepted {
            let node = Node.group(from: accepted, tags: tags)
            nodes.append(node)
            changed.append(node)
        }
        return changed
    }

    mutating func acceptNode(_ node: Node) -> Node? {
        if !node.isGroup || node.children.isEmpty {
            guard let url = node.url else { return node }
            let synth = ScanItem(
                url: url,
                name: node.name,
                size: node.totalSize,
                note: node.note,
                safety: node.safety,
                action: node.action,
                isSelected: node.autoSelected,
                locked: node.locked,
                ownerBundleIDs: node.ownerBundleIDs,
                fileIdentity: node.fileIdentity,
                ruleEvidence: node.ruleEvidence,
                uninstallContext: node.uninstallContext,
                authorizationContext: node.resolvedAuthorizationContext,
                evaluationReason: node.evaluationReason,
                isRuleEvaluated: true,
                measuredBytes: node.measuredBytes ?? node.totalSize,
                selectionRestrictions: node.selectionRestrictions,
                cacheRecommendation: node.cacheRecommendation
            )
            guard let surviving = accept([synth]).first else { return nil }
            var copy = node
            copy.locked = surviving.locked ?? copy.locked
            copy.autoSelected = surviving.isSelected
            copy.safety = surviving.safety
            copy.size = surviving.size
            copy.measuredBytes = surviving.measuredBytes ?? copy.measuredBytes
            copy.ruleEvidence = surviving.ruleEvidence
            copy.evaluationReason = surviving.evaluationReason
            copy.selectionRestrictions = copy.selectionRestrictions.union(surviving.selectionRestrictions)
            copy.cacheRecommendation = surviving.cacheRecommendation ?? copy.cacheRecommendation
            return copy
        }
        let filteredChildren = node.children.compactMap { acceptNode($0) }
        guard !filteredChildren.isEmpty else { return nil }
        var copy = node
        copy.children = filteredChildren
        copy.size = filteredChildren.reduce(0) { $0 + $1.totalSize }
        copy.measuredBytes = filteredChildren.reduce(0) { $0 + ($1.measuredBytes ?? $1.totalSize) }
        if filteredChildren.allSatisfy({ $0.locked }) {
            copy.locked = true
            copy.autoSelected = false
            copy.safety = .caution
        }
        return copy
    }

    mutating func acceptNode(
        _ node: Node,
        into nodes: inout [Node],
        postProcess: ((inout Node) -> Void)? = nil
    ) -> [Node] {
        let accepted = acceptNode(node)
        var changed = reconcile(nodes: &nodes)
        if var accepted {
            postProcess?(&accepted)
            nodes.append(accepted)
            changed.append(accepted)
        }
        return changed
    }
}
