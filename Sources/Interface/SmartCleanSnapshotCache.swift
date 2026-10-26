import SwiftUI
import AppKit

/// 全树指纹的单槽记忆化。
///
/// `SmartCleanSnapshotCache.signature(for:)` 每次调用都要递归遍历整棵树
/// （`SmartCleanTreeFingerprint.digest` 对每个节点做十余次混合 + 逐字节字符串哈希）。
/// 而 `SmartCleanView.currentSnapshot` 是计算属性，单次 body 求值会被访问十余次，
/// 于是每次点击 / 每帧动画都在主线程上跑十几遍全树哈希 —— 明细页「越点越卡、最终卡死」的主因。
///
/// 这里用 O(顶层分组数) 的廉价结构指纹做前置判断，命中即直接返回上次的签名，
/// 只有扫描结果真正变化时才重新做一次全树递归。
///
/// 注意：必须与 `SmartCleanSnapshotCache` 同文件。放到独立新文件里会被
/// `git clean -fd` 之类的清理动作连带删除，进而让调用方编译失败或被整体回滚。
/// 同时被 `SmartCleanView.currentSnapshot` 直接引用，这样一旦本文件被回滚，
/// 编译期就会报错而不是悄悄退化回「每次全树哈希」。
enum SmartCleanSignatureMemo {
    static let store = LockedValue<(key: UInt64, signature: String)>((0, ""))

    /// 只读取每个顶层节点的 O(1) 摘要字段（UUID / 体积 / children 数 / 叶子数），不做递归。
    static func structuralKey(
        for roots: [Node],
        resultVersion: UInt64,
        policyVersion: Int
    ) -> UInt64 {
        var key: UInt64 = 14695981039346656037
        key = (key ^ UInt64(roots.count)) &* 1099511628211
        key = (key ^ resultVersion) &* 1099511628211
        key = (key ^ UInt64(bitPattern: Int64(policyVersion))) &* 1099511628211
        for root in roots {
            var nodeCount: UInt64 = 0
            var totalBytes: Int64 = 0
            SmartCleanTreeFingerprint.digest(node: root, into: &key, nodeCount: &nodeCount,
                                            totalBytes: &totalBytes, includeChildren: false)
            SmartCleanTreeFingerprint.mix(root.childrenRevision, into: &key)
        }
        return key
    }

    static func signature(
        for roots: [Node],
        resultVersion: UInt64,
        policyVersion: Int
    ) -> String {
        guard !roots.isEmpty else { return "" }
        let key = structuralKey(for: roots, resultVersion: resultVersion, policyVersion: policyVersion)
        if let hit = store.withValue({ $0.key == key && !$0.signature.isEmpty ? $0.signature : nil }) {
            return hit
        }
        let digest = SmartCleanTreeFingerprint.digest(nodes: roots)
        let signature = "v\(policyVersion):r\(resultVersion):n\(digest.nodeCount):b\(digest.totalBytes):h\(String(digest.hash, radix: 16))"
        store.withValue { $0 = (key, signature) }
        return signature
    }
}

@MainActor
final class SmartCleanSnapshotCache {
    static let shared = SmartCleanSnapshotCache()

    struct Snapshot: @unchecked Sendable {
        let signature: String
        let resultVersion: UInt64
        let policyVersion: Int
        let sections: [SmartCleanSectionData]
        let cleanableItems: [Node]
        let cleanableLeaves: [Node]
        let leafSizeByID: [UUID: Int64]
        let leafActionByID: [UUID: ItemAction]
        let totalCleanableSize: Int64
        let totalCleanableCount: Int
        let totalProtectedSize: Int64
        let activeSectionCount: Int
        let profileSelections: [CleaningProfile: Set<UUID>]
        let profileBucketSelections: [CleaningProfile: Set<UUID>]
        let profileDeltas: [CleaningProfile: Int64]

        static let empty = Snapshot(
            signature: "",
            resultVersion: 0,
            policyVersion: CleanupSelectionPolicy.policyVersion,
            sections: [],
            cleanableItems: [],
            cleanableLeaves: [],
            leafSizeByID: [:],
            leafActionByID: [:],
            totalCleanableSize: 0,
            totalCleanableCount: 0,
            totalProtectedSize: 0,
            activeSectionCount: 0,
            profileSelections: [.safeDaily: [], .devPro: [], .maxSpace: []],
            profileBucketSelections: [.safeDaily: [], .devPro: [], .maxSpace: []],
            profileDeltas: [.safeDaily: 0, .devPro: 0, .maxSpace: 0]
        )
    }

    private(set) var currentSnapshot: Snapshot = .empty
    func invalidateRules() {
        currentSnapshot = .empty
        inFlightSignature = ""
        cachedOccupyingApps = []
        runningApplicationsByBundleID = [:]
        lastOccupancyRefreshSignature = ""
        lastOccupancyRefreshTime = 0
        SmartCleanSignatureMemo.store.withValue { $0 = (0, "") }
    }
    private var inFlightSignature: String = ""
    var cachedOccupyingApps: [NSRunningApplication] = []
    var runningApplicationsByBundleID: [String: NSRunningApplication] = [:]
    var lastOccupancyRefreshSignature: String = ""
    var lastOccupancyRefreshTime: TimeInterval = 0

    nonisolated static func signature(
        for roots: [Node],
        resultVersion: UInt64 = 0,
        policyVersion: Int = CleanupSelectionPolicy.policyVersion
    ) -> String {
        // 记忆化：避免每次读取 currentSnapshot 都重跑一遍全树递归哈希。
        SmartCleanSignatureMemo.signature(
            for: roots,
            resultVersion: resultVersion,
            policyVersion: policyVersion
        )
    }

    nonisolated static func buildSections(from roots: [Node]) -> [SmartCleanSectionData] {
        var buckets: [SmartCleanSectionKind: [Node]] = [:]
        for kind in SmartCleanSectionKind.allCases {
            buckets[kind] = []
        }

        for root in roots {
            let groupTitle = root.name
            let groupTags = root.tags
            for leaf in CleanupPresentation.rows(root) {
                let kind = SmartCleanSectionClassifier.classify(leaf: leaf, groupTitle: groupTitle, groupTags: groupTags)
                buckets[kind, default: []].append(leaf)
            }
        }

        return SmartCleanSectionKind.allCases.compactMap { kind in
            let sortedItems = (buckets[kind] ?? []).sorted { $0.totalSize > $1.totalSize }
            if !sortedItems.isEmpty {
                return SmartCleanSectionData(kind: kind, items: sortedItems)
            }
            return nil
        }
    }

    nonisolated static func computeSnapshot(
        roots: [Node],
        resultVersion: UInt64 = 0,
        policyVersion: Int = CleanupSelectionPolicy.policyVersion,
        existingSignature: String? = nil,
        builder: (([Node]) -> [SmartCleanSectionData])? = nil
    ) -> Snapshot {
        let sig = existingSignature ?? signature(for: roots, resultVersion: resultVersion, policyVersion: policyVersion)
        if sig.isEmpty {
            return .empty
        }
        let sections = builder?(roots) ?? buildSections(from: roots)
        let cleanableItems = sections.flatMap(\.cleanableItems)
        let cleanableLeaves = sections.flatMap(\.selectableLeaves)
        var sizeByID: [UUID: Int64] = [:]
        sizeByID.reserveCapacity(cleanableLeaves.count)
        var actionByID: [UUID: ItemAction] = [:]
        actionByID.reserveCapacity(cleanableLeaves.count)
        var totalCleanableBytes: Int64 = 0
        var safeSet = Set<UUID>()
        var devSet = Set<UUID>()
        var devBucketSet = Set<UUID>()
        var maxSet = Set<UUID>()
        var maxBucketSet = Set<UUID>()
        var safeSize: Int64 = 0
        var devSize: Int64 = 0
        var maxSize: Int64 = 0

        for leaf in cleanableLeaves {
            sizeByID[leaf.id] = leaf.totalSize
            actionByID[leaf.id] = leaf.action
            totalCleanableBytes += leaf.totalSize

            switch CleanupSelectionPolicy.selectionBucket(for: leaf) {
            case .safeDaily:
                safeSet.insert(leaf.id)
                devSet.insert(leaf.id)
                maxSet.insert(leaf.id)
                safeSize += leaf.totalSize
                devSize += leaf.totalSize
                maxSize += leaf.totalSize
            case .devPro:
                devBucketSet.insert(leaf.id)
                devSet.insert(leaf.id)
                maxSet.insert(leaf.id)
                devSize += leaf.totalSize
                maxSize += leaf.totalSize
            case .maxSpace:
                maxBucketSet.insert(leaf.id)
                maxSet.insert(leaf.id)
                maxSize += leaf.totalSize
            case .custom, nil:
                break
            }
        }

        let protectedBytes = sections.reduce(0) { $0 + $1.lockedSize }
        let activeCount = sections.filter { !$0.kind.isManualStorage && !$0.items.isEmpty }.count

        return Snapshot(
            signature: sig,
            resultVersion: resultVersion,
            policyVersion: policyVersion,
            sections: sections,
            cleanableItems: cleanableItems,
            cleanableLeaves: cleanableLeaves,
            leafSizeByID: sizeByID,
            leafActionByID: actionByID,
            totalCleanableSize: totalCleanableBytes,
            totalCleanableCount: cleanableItems.count,
            totalProtectedSize: protectedBytes,
            activeSectionCount: activeCount,
            profileSelections: [
                .safeDaily: safeSet,
                .devPro: devSet,
                .maxSpace: maxSet
            ],
            profileBucketSelections: [
                .safeDaily: safeSet,
                .devPro: devBucketSet,
                .maxSpace: maxBucketSet
            ],
            profileDeltas: [
                .safeDaily: 0,
                .devPro: max(0, devSize - safeSize),
                .maxSpace: max(0, maxSize - devSize)
            ]
        )
    }

    func cachedSnapshot(
        for roots: [Node],
        resultVersion: UInt64 = 0,
        policyVersion: Int = CleanupSelectionPolicy.policyVersion
    ) -> Snapshot? {
        if roots.isEmpty {
            currentSnapshot = .empty
            return .empty
        }
        let sig = Self.signature(for: roots, resultVersion: resultVersion, policyVersion: policyVersion)
        if currentSnapshot.signature == sig {
            return currentSnapshot
        }
        return nil
    }

    func storePrecomputedSnapshot(_ snapshot: Snapshot) {
        currentSnapshot = snapshot
    }

    func rebuildSnapshotAsync(
        roots: [Node],
        resultVersion: UInt64 = 0,
        policyVersion: Int = CleanupSelectionPolicy.policyVersion,
        completion: (@MainActor (Snapshot) -> Void)? = nil
    ) {
        if roots.isEmpty {
            currentSnapshot = .empty
            inFlightSignature = ""
            completion?(.empty)
            return
        }
        let sig = Self.signature(for: roots, resultVersion: resultVersion, policyVersion: policyVersion)
        if currentSnapshot.signature == sig {
            completion?(currentSnapshot)
            return
        }
        inFlightSignature = sig
        DispatchQueue.global(qos: .userInitiated).async {
            let built = Self.computeSnapshot(
                roots: roots,
                resultVersion: resultVersion,
                policyVersion: policyVersion,
                existingSignature: sig
            )
            SmartAppGroupBuilder.prewarmSections(built.sections)
            DispatchQueue.main.async {
                let cache = SmartCleanSnapshotCache.shared
                if cache.inFlightSignature == sig || cache.currentSnapshot.signature.isEmpty {
                    cache.currentSnapshot = built
                }
                completion?(built)
            }
        }
    }

    func snapshot(
        for roots: [Node],
        resultVersion: UInt64 = 0,
        policyVersion: Int = CleanupSelectionPolicy.policyVersion,
        builder: (([Node]) -> [SmartCleanSectionData])? = nil
    ) -> Snapshot {
        let sig = Self.signature(for: roots, resultVersion: resultVersion, policyVersion: policyVersion)
        if sig.isEmpty {
            currentSnapshot = .empty
            return .empty
        }
        if currentSnapshot.signature == sig {
            return currentSnapshot
        }
        let built = Self.computeSnapshot(
            roots: roots,
            resultVersion: resultVersion,
            policyVersion: policyVersion,
            existingSignature: sig,
            builder: builder
        )
        currentSnapshot = built
        return built
    }
}

struct SmartRunningAppCandidate: Sendable {
    let bundleID: String
    let name: String
}

enum SmartRunningAppMatcher {
    static func matchingBundleIDs(leafBlob: String, candidates: [SmartRunningAppCandidate]) -> [String] {
        guard !leafBlob.isEmpty else { return [] }
        var matched: [String] = []
        var seenNames = Set<String>()
        for candidate in candidates {
            let name = candidate.name
            guard !name.isEmpty, !seenNames.contains(name) else { continue }
            if leafBlob.contains(candidate.bundleID.lowercased())
                || (name.count >= 3 && leafBlob.contains(name.lowercased())) {
                seenNames.insert(name)
                matched.append(candidate.bundleID)
                if matched.count >= 3 { break }
            }
        }
        return matched
    }
}
