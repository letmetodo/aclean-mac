import SwiftUI
import AppKit

enum SmartCleanSectionKind: String, CaseIterable, Identifiable {
    case app           = "app"
    case communication = "communication"
    case developer     = "developer"
    case ai            = "ai"
    case design        = "design"
    case leftovers     = "leftovers"
    case system        = "system"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .app:           return L10n.localized(.junkAppCachesAndLogs)
        case .communication: return L10n.localized(.junkCommTools)
        case .developer:     return L10n.localized(.junkDevTools)
        case .ai:            return L10n.localized(.junkAiTools)
        case .design:        return L10n.localized(.junkDesignCaches)
        case .leftovers:     return L10n.localized(.junkUninstallerLeftovers)
        case .system:        return L10n.localized(.junkSystemData)
        }
    }

    var subtitle: String {
        switch self {
        case .app:
            return L10n.localized(.appBrowserAndCloudCachesPlusOldLogsKeepsSignInsAndBrowsingHistory)
        case .communication:
            return L10n.localized(.chatAppCachesOlderImagesorvideosMustBeReDownloadedAndExpiredMediaCannotBeRecovered)
        case .developer:
            return L10n.localized(.xcodeSwiftpmNodeJsAndBuildCachesFirstBuildAfterCleaningMayBeSlightlySlower)
        case .ai:
            return L10n.localized(.aiAppCachesAndOldToolchainsPreservesChatsProjectsAndLocalModels)
        case .design:
            return L10n.localized(.designToolCachesYourDesignFilesAndArtworksRemainUntouched)
        case .leftovers:
            return L10n.localized(.orphanedDataLeftOnDiskByAlreadyUninstalledApplications)
        case .system:
            return L10n.localized(.systemCachesDiagnosticReportsAndLocalSnapshots)
        }
    }

    var isManualStorage: Bool {
        false
    }
}

enum SmartCleanTreeFingerprint {
    @inline(__always)
    static func mix(_ value: UInt64, into hash: inout UInt64) {
        hash ^= value
        hash &*= 1099511628211
    }

    @inline(__always)
    static func mixString(_ s: String, into hash: inout UInt64) {
        for b in s.utf8 {
            hash ^= UInt64(b)
            hash &*= 1099511628211
        }
        mix(0xFF, into: &hash)
    }

    static func digest(node: Node, into hash: inout UInt64, nodeCount: inout UInt64, totalBytes: inout Int64, includeChildren: Bool = true) {
        nodeCount &+= 1
        totalBytes &+= node.totalSize
        let uuid = node.id.uuid
        let u1 = UInt64(uuid.0) << 56 | UInt64(uuid.1) << 48 | UInt64(uuid.2) << 40 | UInt64(uuid.3) << 32
               | UInt64(uuid.4) << 24 | UInt64(uuid.5) << 16 | UInt64(uuid.6) << 8 | UInt64(uuid.7)
        let u2 = UInt64(uuid.8) << 56 | UInt64(uuid.9) << 48 | UInt64(uuid.10) << 40 | UInt64(uuid.11) << 32
               | UInt64(uuid.12) << 24 | UInt64(uuid.13) << 16 | UInt64(uuid.14) << 8 | UInt64(uuid.15)
        mix(u1, into: &hash)
        mix(u2, into: &hash)
        mix(UInt64(bitPattern: node.size), into: &hash)
        mix(UInt64(bitPattern: node.measuredBytes ?? -1), into: &hash)
        mix(UInt64(bitPattern: node.totalSize), into: &hash)

        var flags: UInt64 = 0
        if node.locked { flags |= 1 << 0 }
        if node.autoSelected { flags |= 1 << 1 }
        if node.ruleEvidence != nil { flags |= 1 << 2 }
        if node.duplicateEvidence != nil { flags |= 1 << 3 }
        if node.selectionRestrictions.contains(.productPolicy) { flags |= 1 << 4 }
        if node.selectionRestrictions.contains(.readOnlyAsset) { flags |= 1 << 5 }
        if node.selectionRestrictions.contains(.largeCache) { flags |= 1 << 6 }
        if node.selectionRestrictions.contains(.unknownImpact) { flags |= 1 << 7 }
        if node.selectionRestrictions.contains(.scannerNotConnected) { flags |= 1 << 8 }
        switch node.safety {
        case .safe: flags |= 1 << 9
        case .caution: flags |= 2 << 9
        case .risky: flags |= 3 << 9
        }
        switch node.action {
        case .trash: flags |= 1 << 11
        case .permanentlyDeleteTrashItem: flags |= 2 << 11
        case .custom: flags |= 3 << 11
        default: flags |= 4 << 11
        }
        mix(flags, into: &hash)

        if let badge = node.badge {
            mixString(badge, into: &hash)
        }
        if let ev = node.ruleEvidence {
            mixString(ev.id, into: &hash)
            mixString(ev.tier.rawValue, into: &hash)
            mixString(ev.reason.rawValue, into: &hash)
            mix(ev.defaultSelected ? 1 : 0, into: &hash)
            mix(ev.executable ? 1 : 0, into: &hash)
        } else {
            mix(0, into: &hash)
        }
        if let rec = node.cacheRecommendation {
            mixString(rec.state.rawValue, into: &hash)
            mixString(rec.cacheClass?.rawValue ?? "", into: &hash)
            mix(rec.automaticAllowed ? 1 : 0, into: &hash)
        } else {
            mix(0, into: &hash)
        }
        if let fid = node.fileIdentity {
            mix(UInt64(bitPattern: Int64(fid.device)), into: &hash)
            mix(fid.inode, into: &hash)
            mix(UInt64(fid.uid), into: &hash)
            mix(fid.isDirectory ? 1 : 0, into: &hash)
        }
        mix(UInt64(node.children.count), into: &hash)
        mix(node.ruleIdentity?.generation ?? 0, into: &hash)
        guard includeChildren else { return }
        for child in node.children {
            digest(node: child, into: &hash, nodeCount: &nodeCount, totalBytes: &totalBytes)
        }
    }

    static func digest(nodes: [Node]) -> (hash: UInt64, nodeCount: UInt64, totalBytes: Int64) {
        var hash: UInt64 = 14695981039346656037
        var nodeCount: UInt64 = 0
        var totalBytes: Int64 = 0
        mix(UInt64(nodes.count), into: &hash)
        for n in nodes {
            digest(node: n, into: &hash, nodeCount: &nodeCount, totalBytes: &totalBytes)
        }
        return (hash, nodeCount, totalBytes)
    }
}

struct SmartCleanSectionData: Identifiable, @unchecked Sendable {
    let kind: SmartCleanSectionKind
    var items: [Node]
    let totalSize: Int64
    let selectableLeaves: [Node]
    let selectableLeafIDs: Set<UUID>
    let leafSizeByID: [UUID: Int64]
    let cleanableItems: [Node]
    let cleanableItemLeafIDs: [Set<UUID>]
    let lockedSize: Int64
    let contentSignature: UInt64
    var id: String { kind.rawValue }

    var cacheIdentityKey: String {
        "\(kind.rawValue)|\(String(contentSignature, radix: 16))|v\(CleanupSelectionPolicy.policyVersion)"
    }

    var totalCount: Int { items.count }

    init(kind: SmartCleanSectionKind, items: [Node]) {
        self.kind = kind
        self.items = items
        self.totalSize = items.reduce(0) { $0 + $1.totalSize }
        self.contentSignature = SmartCleanTreeFingerprint.digest(nodes: items).hash
        let allLeaves = items.flatMap(\.leaves)
        var selectable: [Node] = []
        selectable.reserveCapacity(allLeaves.count)
        var selectableIDs = Set<UUID>(minimumCapacity: allLeaves.count)
        var sizeMap: [UUID: Int64] = [:]
        sizeMap.reserveCapacity(allLeaves.count)
        var lockedBytes: Int64 = 0
        for leaf in allLeaves {
            if !CleanupSelectionPolicy.isUserSelectable(leaf) {
                lockedBytes += leaf.totalSize
            } else {
                selectable.append(leaf)
                selectableIDs.insert(leaf.id)
                sizeMap[leaf.id] = leaf.totalSize
            }
        }
        self.selectableLeaves = selectable
        self.selectableLeafIDs = selectableIDs
        self.leafSizeByID = sizeMap
        var cleanables: [Node] = []
        var cleanableIDs: [Set<UUID>] = []
        for item in items {
            let itemSelectableIDs = Set(item.leaves.lazy.filter { CleanupSelectionPolicy.isUserSelectable($0) }.map(\.id))
            if !itemSelectableIDs.isEmpty {
                cleanables.append(item)
                cleanableIDs.append(itemSelectableIDs)
            }
        }
        self.cleanableItems = cleanables
        self.cleanableItemLeafIDs = cleanableIDs
        self.lockedSize = lockedBytes
    }
}
