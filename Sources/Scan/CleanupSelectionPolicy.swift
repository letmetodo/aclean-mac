import Foundation

/// 清理方案枚举（三级场景化方案 + 自定义微调）
public enum CleaningProfile: String, CaseIterable, Identifiable, Sendable {
    case safeDaily = "safeDaily"
    case devPro    = "devPro"
    case maxSpace  = "maxSpace"
    case custom    = "custom"

    public var id: String { rawValue }
}

/// One recommendation policy for UI, SmartCare and scheduled scans.
enum CleanupSelectionPolicy {
    static func isUserSelectable(_ node: Node) -> Bool {
        guard RuleTaskGate.shared.allows(node.ruleIdentity, ruleID: node.ruleEvidence?.id) else { return false }
        guard !node.locked, !node.isRetainedOriginal, node.safety != .risky,
              !node.selectionRestrictions.contains(.readOnlyAsset),
              !node.selectionRestrictions.contains(.scannerNotConnected),
              node.ruleEvidence?.tier != .forbidden,
              node.ruleEvidence?.tier != .readOnly else { return false }
        if let url = node.url {
            // Selection consumes the scan snapshot; execution revalidates physical paths.
            guard !CleanupSafetyPolicy.isProtectedAsset(url, assumeNoSymlinks: true) else { return false }
            let path = url.standardizedFileURL.path.lowercased()
            if AppConfig.Paths.topLevelContainers.contains(path) { return false }
        }
        return true
    }

    /// 策略版本号：当方案选择边界或扩展规则更新时递增，用于驱动快照缓存失效
    static let policyVersion: Int = 7

    /// 方案扩展仅允许放宽的受控限制项（仅限策略降级与大体积缓存提示；严禁放宽 readOnlyAsset / unknownImpact / scannerNotConnected）
    static let allowedProfileExpansionRestrictions: Set<SelectionRestriction> = [
        .productPolicy,
        .largeCache
    ]


    static func isRecommended(_ node: Node) -> Bool {
        guard isUserSelectable(node),
              node.selectionRestrictions.isEmpty,
              node.cacheRecommendation?.automaticAllowed != false,
              node.autoSelected,
              node.safety == .safe,
              node.ruleEvidence?.tier == .automatic,
              node.ruleEvidence?.defaultSelected == true,
              node.badge == nil,
              node.duplicateEvidence == nil else { return false }
        if case .custom = node.action { return false } // maintenance always explicit
        guard node.action == .trash, let url = node.url, let identity = node.fileIdentity else { return false }
        guard OpenFileGuard.isCurrentUserVerifiableScope(url, identity: identity, checkDescendants: false, assumeNoSymlinks: true) else { return false }
        // Structured, implemented L1 evidence grants recommendation. Display category/path text does not.
        return node.ruleEvidence.map { AppConfig.RuleIDs.implementedAutomaticRules.contains($0.id) } == true
    }

    /// 判断节点是否属于「开发和设计缓存」范畴（已通过基础安全与规则可执行门禁）
    static func isDevOrDesignCache(node: Node) -> Bool {
        guard isUserSelectable(node),
              node.selectionRestrictions.isSubset(of: allowedProfileExpansionRestrictions),
              node.cacheRecommendation?.state != .blocked,
              node.safety != .risky,
              let evidence = node.ruleEvidence,
              !evidence.id.isEmpty,
              !AppConfig.CleanupProfiles.manualOnlyRuleIDs.contains(evidence.id),
              evidence.executable,
              evidence.tier != .forbidden,
              evidence.tier != .readOnly,
              node.badge == nil,
              node.duplicateEvidence == nil,
              node.action == .trash else { return false }

        return AppConfig.CleanupProfiles.developerCacheRuleIDs.contains(evidence.id)
            && node.cacheRecommendation?.state != .unknownReview
    }

    /// 方案化选择匹配判定（零磁盘 I/O：明确允许扩展的限制项，严格要求存在可执行规则证据；后续清理执行门禁保持不变）
    static func isSelected(node: Node, in profile: CleaningProfile) -> Bool {
        guard profile != .custom else { return false }
        guard isUserSelectable(node),
              node.selectionRestrictions.isSubset(of: allowedProfileExpansionRestrictions),
              node.cacheRecommendation?.state != .blocked,
              node.safety != .risky,
              let evidence = node.ruleEvidence,
              !evidence.id.isEmpty,
              !AppConfig.CleanupProfiles.manualOnlyRuleIDs.contains(evidence.id),
              evidence.executable,
              evidence.tier != .forbidden,
              evidence.tier != .readOnly,
              node.badge == nil,
              node.duplicateEvidence == nil,
              node.action == .trash else { return false }

        switch profile {
        case .safeDaily:
            return node.selectionRestrictions.isEmpty
                && node.cacheRecommendation?.automaticAllowed != false
                && node.autoSelected
                && node.safety == .safe
                && evidence.tier == .automatic
                && evidence.defaultSelected
                && AppConfig.RuleIDs.implementedAutomaticRules.contains(evidence.id)

        case .devPro:
            if isSelected(node: node, in: .safeDaily) { return true }
            return isDevOrDesignCache(node: node)

        case .maxSpace:
            if isSelected(node: node, in: .devPro) { return true }
            return (AppConfig.CleanupProfiles.maximumCacheRuleIDs.contains(evidence.id)
                || AppConfig.RuleIDs.implementedAutomaticRules.contains(evidence.id))
                && node.cacheRecommendation?.state != .unknownReview

        case .custom:
            return false
        }
    }

    /// Each selectable candidate belongs to exactly one checkbox bucket.
    /// Safe daily wins over developer/design classification, as confirmed for the UI.
    static func selectionBucket(for node: Node) -> CleaningProfile? {
        if isSelected(node: node, in: .safeDaily) { return .safeDaily }
        if isDevOrDesignCache(node: node) { return .devPro }
        if isSelected(node: node, in: .maxSpace) { return .maxSpace }
        return nil
    }

    static func isSelected(node: Node, in profiles: Set<CleaningProfile>) -> Bool {
        guard let bucket = selectionBucket(for: node) else { return false }
        return profiles.contains(bucket)
    }

    /// T09 / C16：在排序、折叠、过滤、徽章或建议刷新后保护用户显式选择状态；
    /// 仅当节点变为 locked、不再具备可执行授权或物理身份发生变更时撤销失效选择，绝不将未勾选条目重新自动勾上。
    static func reconcileUserSelection(
        _ currentSelection: Set<UUID>,
        roots: [Node],
        previousIdentities: [UUID: FileIdentity] = [:]
    ) -> Set<UUID> {
        guard !currentSelection.isEmpty else { return [] }
        var validIDs = Set<UUID>()
        func visit(_ node: Node, ancestorLocked: Bool) {
            let effectivelyLocked = ancestorLocked
                || node.locked
                || node.selectionRestrictions.contains(.readOnlyAsset)
                || node.cacheRecommendation?.state == .blocked
            if node.isLeaf {
                guard currentSelection.contains(node.id), !effectivelyLocked else { return }
                if node.resolvedAuthorizationContext == .junkRule,
                   node.ruleEvidence?.executable != true {
                    return
                }
                if let prevIdentity = previousIdentities[node.id],
                   let curIdentity = node.fileIdentity,
                   prevIdentity != curIdentity {
                    return
                }
                validIDs.insert(node.id)
            } else {
                for child in node.children {
                    visit(child, ancestorLocked: effectivelyLocked)
                }
            }
        }
        for root in roots {
            visit(root, ancestorLocked: false)
        }
        return validIDs
    }
}
