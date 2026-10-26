import Foundation
import Combine

@MainActor
struct P9SelectionStateRepairTests {
    func runAll() throws {
        var count = 0
        func check(_ value: Bool, _ message: String) {
            precondition(value, message)
            count += 1
        }
        let fm = FileManager.default
        let base = fm.temporaryDirectory.appendingPathComponent("CleanMate-SelectionState-" + UUID().uuidString)
        try fm.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: base) }
        let url = base.appendingPathComponent("cache.log")
        try Data([1, 2, 3]).write(to: url)
        var leaf = Node(name: "cache.log", url: url, safety: .safe, size: 4096, autoSelected: true)
        leaf.fileIdentity = FileIdentity.capture(from: url)
        leaf.ruleEvidence = CleanupRuleEvidence(id: "JC.DEV.NPM.LOGS", tier: .automatic, reason: .generalCache, defaultSelected: true)

        let state = AppState()
        state.roots = [leaf]
        var events: [CleaningProfileState] = []
        let subscription = state.$cleaningProfileState.dropFirst().sink { events.append($0) }
        defer { subscription.cancel() }
        state.setCleaningProfile(.maxSpace, selectedProfiles: [.safeDaily, .devPro, .maxSpace])
        check(events.count == 1 && events[0].primary == .maxSpace && events[0].profiles.count == 3,
              "profile label and options must publish as one consistent value")
        state.setManualSelection([leaf.id])
        check(state.selection == [leaf.id] && state.cleaningProfile == .custom && state.selectedProfiles.isEmpty,
              "category, group and drawer manual selection must clear the profile in the same owner")
        check(events.count == 2 && events.last?.profiles.isEmpty == true,
              "manual selection cannot publish a primary label with stale options")
        check(state.didApplyDefaultsCurrentModule, "manual selection cannot be overwritten by initial defaults")

        state.setCleaningProfile(.safeDaily)
        state.setSelection(leaf, false)
        check(state.selection.isEmpty && state.cleaningProfile == .custom && state.selectedProfiles.isEmpty,
              "manual leaf deselection clears every profile indicator")
        state.setCleaningProfile(.devPro)
        state.toggle(leaf)
        check(state.selection == [leaf.id] && state.cleaningProfile == .custom && state.selectedProfiles.isEmpty,
              "the alternate leaf toggle path shares the manual state transition")
        state.setCleaningProfile(.maxSpace, selectedProfiles: [])
        check(state.cleaningProfile == .custom && state.selectedProfiles.isEmpty,
              "an empty option set cannot retain a non-custom primary label")
        state.setCleaningProfile(.safeDaily, selectedProfiles: [.devPro, .custom])
        check(state.cleaningProfile == .devPro && state.selectedProfiles == [.devPro],
              "primary profile is derived from normalized options rather than a second mutable field")

        let other = AppState()
        other.setCleaningProfile(.safeDaily)
        check(state.cleaningProfile == .devPro && state.selectedProfiles == [.devPro],
              "another AppState cannot overwrite this instance through a singleton presentation cache")
        state.open(.restore(.spaceLens))
        check(state.cleaningProfile == .safeDaily, "a new module starts with its own profile state")
        state.setManualSelection([])
        state.open(.restore(.junk))
        check(state.cleaningProfile == .devPro && state.selectedProfiles == [.devPro] && state.selection == [leaf.id],
              "module switches restore actual selections and profile metadata together")
        state.open(.restore(.spaceLens))
        check(state.cleaningProfile == .custom && state.selectedProfiles.isEmpty,
              "inactive module changes do not leak into another module")
        state.write(.junk) { session in
            session.cleaningProfileState = CleaningProfileState(profile: .maxSpace)
        }
        check(state.cleaningProfile == .custom && state.selectedProfiles.isEmpty,
              "background module writes cannot overwrite the visible module profile")
        state.open(.restore(.junk))
        check(state.cleaningProfile == .maxSpace && state.selectedProfiles == [.maxSpace],
              "opening a background-updated module restores that module's profile")
        state.setManualSelection([])
        state.open(.smartResult(.junk, tree: [leaf]))
        check(state.cleaningProfile == .safeDaily && state.selectedProfiles == [.safeDaily],
              "new smart results reset stale custom metadata to their recommendation strategy")

        var restricted = Node(name: "read-only.log", url: url, safety: .safe, size: 4096, autoSelected: true)
        restricted.fileIdentity = leaf.fileIdentity
        restricted.ruleEvidence = leaf.ruleEvidence
        restricted.selectionRestrictions = [.readOnlyAsset]
        restricted.locked = false
        let section = SmartCleanSectionData(kind: .developer, items: [leaf, restricted])
        check(section.selectableLeafIDs == [leaf.id] && section.lockedSize == restricted.totalSize,
              "section-level shortcuts must honor the shared selection policy, not only a lock bit")
        let group = SmartAppCacheGroup(id: "test", title: "test", subtitle: "", appIcon: nil,
                                     fallbackSymbol: "app", items: [leaf, restricted])
        check(group.selectableLeafIDs == [leaf.id], "application-level shortcuts use the same eligibility boundary")
        state.roots = [leaf, restricted]
        state.setSelection(restricted, true)
        check(!state.selection.contains(restricted.id), "the direct leaf path cannot select a read-only asset")
        state.setCleaningProfile(.devPro)
        state.setManualSelection([])
        state.reconcileSelectionAfterRefresh()
        check(state.selection.isEmpty && state.cleaningProfile == .custom && state.selectedProfiles.isEmpty,
              "refresh does not restore explicitly cleared choices or profile indicators")
        var devOnly = Node(name: "dev-review", url: base.appendingPathComponent("dev-review"), safety: .caution,
                           size: 8192, autoSelected: false)
        devOnly.selectionRestrictions = [.productPolicy]
        devOnly.ruleEvidence = CleanupRuleEvidence(id: "JC.DEV.XCODE.DERIVED.LIVE", tier: .review,
                                                   reason: .generalCache, defaultSelected: false)
        var maxOnly = Node(name: "large-cache", url: base.appendingPathComponent("large-cache"), safety: .caution,
                           size: 16384, autoSelected: false)
        maxOnly.selectionRestrictions = [.largeCache]
        maxOnly.ruleEvidence = CleanupRuleEvidence(id: "JC.CACHE.USER", tier: .automatic,
                                                   reason: .generalCache, defaultSelected: false)
        check(CleanupSelectionPolicy.isDevOrDesignCache(node: leaf)
              && CleanupSelectionPolicy.selectionBucket(for: leaf) == .safeDaily,
              "a daily-safe developer cache belongs exclusively to the daily bucket")
        check(!CleanupSelectionPolicy.isSelected(node: leaf, in: Set([CleaningProfile.devPro]))
              && !CleanupSelectionPolicy.isSelected(node: leaf, in: Set([CleaningProfile.maxSpace])),
              "unchecking daily cannot reselect its developer cache through another option")
        let snapshot = SmartCleanSnapshotCache.computeSnapshot(roots: [leaf, devOnly, maxOnly, restricted])
        let safeIDs = snapshot.profileBucketSelections[.safeDaily, default: []]
        let devIDs = snapshot.profileBucketSelections[.devPro, default: []]
        let maxIDs = snapshot.profileBucketSelections[.maxSpace, default: []]
        check(safeIDs == [leaf.id] && devIDs == [devOnly.id] && maxIDs == [maxOnly.id],
              "cached buckets have the same exclusive ownership as the selection policy")
        check(safeIDs.isDisjoint(with: devIDs) && safeIDs.isDisjoint(with: maxIDs) && devIDs.isDisjoint(with: maxIDs),
              "no pair of checkbox buckets can overlap")
        check(safeIDs.union(devIDs).union(maxIDs) == snapshot.profileSelections[.maxSpace, default: []],
              "all checkbox buckets together retain every eligible legacy maximum-profile candidate")
        check(snapshot.profileDeltas[.devPro] == devOnly.totalSize && snapshot.profileDeltas[.maxSpace] == maxOnly.totalSize,
              "incremental size labels equal the corresponding exclusive bucket sizes")
        let orderedProfiles: [CleaningProfile] = [.safeDaily, .devPro, .maxSpace]
        let orderedLeaves = [leaf, devOnly, maxOnly]
        for mask in 0..<8 {
            let profiles = Set(orderedProfiles.enumerated().compactMap { index, profile in
                mask & (1 << index) == 0 ? nil : profile
            })
            let expected = Set(orderedLeaves.enumerated().compactMap { index, node in
                mask & (1 << index) == 0 ? nil : node.id
            })
            let selected = Set(orderedLeaves.filter { CleanupSelectionPolicy.isSelected(node: $0, in: profiles) }.map(\.id))
            let cached = profiles.reduce(into: Set<UUID>()) { ids, profile in
                ids.formUnion(snapshot.profileBucketSelections[profile, default: []])
            }
            check(selected == expected && cached == expected,
                  "every checkbox combination agrees with cached ownership and its expected IDs")
        }

        let categories: [(String, [String], SmartCleanSectionKind)] = [
            ("Local Models", [], .ai),
            ("Homebrew Cache", [], .developer),
            ("ordinary", ["App Leftovers"], .leftovers)
        ]
        for (title, tags, expected) in categories {
            check(SmartCleanSectionClassifier.classify(leaf: leaf, groupTitle: title, groupTags: tags) == expected,
                  "extracting display grouping must preserve existing category semantics")
        }
        let modelPath = Node(name: "model", url: base.appendingPathComponent(".ollama/models/model"))
        check(SmartCleanSectionClassifier.classify(leaf: modelPath, groupTitle: "", groupTags: []) == .ai,
              "centralized model path markers preserve display grouping")
        check([CleaningProfile.safeDaily, .devPro, .maxSpace].allSatisfy {
            !CleanupSelectionPolicy.isSelected(node: restricted, in: $0)
        }, "display classification cannot grant an otherwise forbidden profile selection")

        let moved = CleanOutcome(name: "cache.log", path: url.path, size: 4096, ok: true, error: nil,
                                 actionCategory: .movedToTrash)
        let movedReport = CleanReport(module: "test", outcomes: [moved])
        check(movedReport.movedToTrashBytes == 4096 && movedReport.actualFreedBytes == 0
              && movedReport.estimatedReclaimableBytes == 0,
              "allocated bytes moved to Trash cannot be reported as verified or estimated physical release")
        let tool = CleanOutcome(name: "tool", path: url.path, size: 4096, ok: true, error: nil,
                                actionCategory: .systemReclaimed)
        let toolReport = CleanReport(module: "test", outcomes: [tool])
        check(toolReport.reportedReclaimedBytes == 4096 && toolReport.actualFreedBytes == 0,
              "tool-reported bytes remain separate from observed host volume changes")
        print("P9 selection-state repair: \(count) ownership, manual selection and session assertions passed")
    }
}
