import Foundation

/// Selection operations consume captured candidates; AppState owns the active module projection.
extension AppState {
    func isSelected(_ n: Node) -> Bool {
        if selection.contains(n.id) { return true }
        return n.isGroup ? (!n.children.isEmpty && n.leaves.allSatisfy { selection.contains($0.id) })
                         : false
    }

    func partial(_ n: Node) -> Bool {
        guard n.isGroup else { return false }
        let l = n.leaves
        let c = l.filter { selection.contains($0.id) }.count
        return c > 0 && c < l.count
    }

    func selectedSize(in n: Node) -> Int64 {
        guard !selection.isEmpty else { return 0 }
        return n.leaves.filter { selection.contains($0.id) }.reduce(0) { $0 + $1.totalSize }
    }

    func selectedCount(in n: Node) -> Int {
        guard !selection.isEmpty else { return 0 }
        return n.leaves.filter { selection.contains($0.id) }.count
    }

    func toggle(_ n: Node) {
        if spec.kind == .spaceLens && n.url != nil {
            guard CleanupSelectionPolicy.isUserSelectable(n) else { return }
            var next = selection
            if next.contains(n.id) {
                next.remove(n.id)
            } else {
                next.insert(n.id)
                for l in n.leaves { next.remove(l.id) }
            }
            setManualSelection(next)
            return
        }
        let leaves = n.leaves.filter { CleanupSelectionPolicy.isUserSelectable($0) }
        let on = !isSelected(n)
        var next = selection
        for l in leaves {
            if on { next.insert(l.id) } else { next.remove(l.id) }
        }
        setManualSelection(next)
    }

    func setSelection(_ n: Node, _ on: Bool) {
        var next = selection
        for l in n.leaves where CleanupSelectionPolicy.isUserSelectable(l) {
            if on { next.insert(l.id) } else { next.remove(l.id) }
        }
        setManualSelection(next)
    }

    func reconcileSelectionAfterRefresh(previousIdentities: [UUID: FileIdentity] = [:]) {
        selection = CleanupSelectionPolicy.reconcileUserSelection(
            selection,
            roots: roots,
            previousIdentities: previousIdentities
        )
    }

    func applyStrategy(_ s: SelectStrategy, scopedToCategory: Bool = true) {
        strategy = s
        let scope: [Node] = scopedToCategory ? visibleRoots.allLeaves : allLeaves
        var next = scopedToCategory ? selection : Set<UUID>()
        if scopedToCategory {
            for l in scope { next.remove(l.id) }
        }
        switch s {
        case .none:
            markCustomSelection()
        case .all:
            for l in scope where CleanupSelectionPolicy.isUserSelectable(l) { next.insert(l.id) }
            setCleaningProfile(.maxSpace, selectedProfiles: [.safeDaily, .devPro, .maxSpace])
        case .smart:
            for l in scope where CleanupSelectionPolicy.isRecommended(l) {
                if l.badge == "Latest" || l.badge == L10n.localized(.statusLatest) { continue }
                next.insert(l.id)
            }
            setCleaningProfile(.safeDaily, selectedProfiles: [.safeDaily])
        case .largest:
            let top = scope.filter { CleanupSelectionPolicy.isUserSelectable($0) }.sorted { $0.totalSize > $1.totalSize }
            for l in top.prefix(max(1, top.count / 4)) { next.insert(l.id) }
            markCustomSelection()
        case .oldest, .newest:
            let leaves = scope.filter { CleanupSelectionPolicy.isUserSelectable($0) }
            let sorted = leaves.sorted { a, b in
                let da = a.date ?? .distantPast, db = b.date ?? .distantPast
                return s == .oldest ? da < db : da > db
            }
            for l in sorted.prefix(max(1, sorted.count / 4)) { next.insert(l.id) }
            markCustomSelection()
        }
        selection = next
    }
}
