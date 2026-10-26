import Foundation

/// T12：大缓存与重建影响唯一纯裁决策略（UI、SmartCare、定时扫描与 Cleaner 共享）
enum JunkCacheRecommendationPolicy {
    static let profileGovernedRuleIDs: Set<String> = [
        AppConfig.RuleIDs.chromiumCache,
        AppConfig.RuleIDs.arcCache,
        AppConfig.RuleIDs.firefoxCache,
        AppConfig.RuleIDs.electronCache,
        AppConfig.RuleIDs.aiIDECache,
        AppConfig.RuleIDs.npmCacache,
        "JC.DEV.BREW.DOWNLOADS",
        "JC.DEV.PKG.SAFE",
        "JC.DEV.XCODE.CACHE",
        AppConfig.RuleIDs.derivedLive,
        AppConfig.RuleIDs.derivedOrphan,
        "JC.BRW.AUTOMATION.CACHE", "JC.APP.LARK.CACHE", "JC.MEDIA.NETEASE.CACHE",
        "JC.DSG.JIANYING.CACHE", "JC.DSG.ADOBE.MEDIACACHE"
    ]

    static let nonCacheRulePrefixes: [String] = [
        "JC.LOG.",
        "JC.TMP.",
        "JC.PREF.",
        "JC.LEFTOVER."
    ]

    static let nonCacheRuleIDs: Set<String> = [
        AppConfig.RuleIDs.darwinTmp,
        "JC.SYS.SAVEDSTATE",
        "JC.DEV.GRADLE.DAEMON",
        "JC.DEV.NPM.LOGS"
    ]

    static func isNonCacheRule(_ ruleID: String?) -> Bool {
        guard let ruleID, !ruleID.isEmpty else { return false }
        if nonCacheRuleIDs.contains(ruleID) { return true }
        return nonCacheRulePrefixes.contains { ruleID.hasPrefix($0) }
    }

    static func costRank(_ cost: RebuildCost) -> Int {
        switch cost {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }

    static func effectiveRebuildCost(ruleCost: RebuildCost, overrideCost: RebuildCost) -> RebuildCost {
        costRank(overrideCost) >= costRank(ruleCost) ? overrideCost : ruleCost
    }

    static func orderedEffects(_ effects: Set<CacheRebuildEffect>) -> [CacheRebuildEffect] {
        let fixedOrder: [CacheRebuildEffect] = [.redownload, .recompile, .firstLaunch]
        return fixedOrder.filter { effects.contains($0) }
    }

    static func localizedEffects(for snapshot: CacheRecommendationSnapshot) -> [String] {
        switch snapshot.state {
        case .blocked:
            return []
        case .unknownReview:
            return [L10n.localized(.junkCacheEffectUnknown)]
        case .ordinary, .suggestedLarge:
            guard snapshot.profileID != nil,
                  let cost = snapshot.effectiveCost,
                  cost != .none,
                  !snapshot.effects.isEmpty else {
                return [L10n.localized(.junkCacheEffectUnknown)]
            }
            return orderedEffects(snapshot.effects).map { effect in
                switch effect {
                case .redownload:
                    return L10n.localized(.junkCacheEffectRedownload)
                case .recompile:
                    return L10n.localized(.junkCacheEffectRecompile)
                case .firstLaunch:
                    return L10n.localized(.junkCacheEffectFirstLaunch)
                }
            }
        }
    }

    static func localizedLargeBadge(for snapshot: CacheRecommendationSnapshot?) -> String? {
        guard let snapshot,
              snapshot.state == .suggestedLarge,
              snapshot.profileID != nil,
              let cost = snapshot.effectiveCost,
              cost != .none,
              !snapshot.effects.isEmpty else {
            return nil
        }
        return L10n.localized(.junkCacheLargeSuggestion)
    }

    static func isUnderAnyConfiguredProfileRoot(_ url: URL, store: AuthoredRules) -> Bool {
        let candidatePath = SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path)
        for profile in store.cacheProfiles.values {
            let expanded = KBPaths.expand(profile.rootTemplate)
            guard !expanded.isEmpty else { continue }
            let rootPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(URL(fileURLWithPath: expanded).standardizedFileURL.path)
            if candidatePath == rootPath || candidatePath.hasPrefix(rootPath + "/") {
                return true
            }
        }
        return false
    }

    /// 固定 7 步裁决函数（Section 5.2）
    static func evaluate(
        url: URL,
        unitURL: URL? = nil,
        unitIdentity: FileIdentity?,
        ruleEvidence: CleanupRuleEvidence?,
        allocatedBytes: Int64?,
        safetyGatePassed: Bool,
        store: AuthoredRules = KnowledgeBaseManager.shared.authored,
        overrideRuleCost: RebuildCost? = nil,
        overrideProfileCost: RebuildCost? = nil,
        overrideEffects: Set<CacheRebuildEffect>? = nil
    ) -> CacheRecommendationSnapshot {
        let resolvedUnitURL = unitURL ?? url
        let canonicalUnitPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(resolvedUnitURL.standardizedFileURL.path)
        let config = store.cacheRecommendationConfig
        let policyVer = config.policyVersion.isEmpty
            ? AppConfig.JunkScan.CacheRecommendation.expectedPolicyVersion
            : config.policyVersion

        // Step 1: 原安全门禁先行（规则库可用、规则可执行、完整巡检通过、身份可证、未锁定）
        let storeReady = store.loaded && !store.ruleSQLHash.isEmpty
        let ruleExecutable = (ruleEvidence?.executable == true)
        guard storeReady,
              safetyGatePassed,
              ruleExecutable,
              let verifiedIdentity = unitIdentity,
              let verifiedBytes = allocatedBytes,
              verifiedBytes >= 0 else {
            var reasons: Set<CacheRecommendationReason> = [.safetyGateFailed]
            if !storeReady || !config.isAvailable {
                reasons.insert(.configurationUnavailable)
            }
            return CacheRecommendationSnapshot(
                profileID: nil,
                ruleID: ruleEvidence?.id,
                ruleSQLHash: store.ruleSQLHash,
                unitPath: canonicalUnitPath,
                unitIdentity: unitIdentity,
                cacheClass: nil,
                allocatedBytes: allocatedBytes,
                thresholdBytes: nil,
                effectiveCost: nil,
                effects: [],
                state: .blocked,
                reasons: reasons,
                automaticAllowed: false,
                policyVersion: policyVer
            )
        }

        // Step 2: 检查缓存配置元数据可用性
        let configValid = config.isAvailable
            && config.schemaVersion == AppConfig.JunkScan.CacheRecommendation.expectedSchemaVersion
            && config.policyVersion == AppConfig.JunkScan.CacheRecommendation.expectedPolicyVersion
            && !config.ageSuggestionEnabled
            && config.appSuggestionBytes > 0
            && config.developerSuggestionBytes > 0
        guard configValid else {
            return CacheRecommendationSnapshot(
                profileID: nil,
                ruleID: ruleEvidence?.id,
                ruleSQLHash: store.ruleSQLHash,
                unitPath: canonicalUnitPath,
                unitIdentity: verifiedIdentity,
                cacheClass: nil,
                allocatedBytes: verifiedBytes,
                thresholdBytes: nil,
                effectiveCost: nil,
                effects: [],
                state: .unknownReview,
                reasons: [.configurationUnavailable],
                automaticAllowed: false,
                policyVersion: policyVer
            )
        }

        // Step 3: 用完整匹配 ruleID 与实际缓存单元查 profile
        let matchedRuleID = ruleEvidence?.id
        let allMatches = store.matchingCacheProfileUnits(
            for: resolvedUnitURL,
            ruleID: nil,
            enforceCacheDataPrecedence: true
        )
        let exactMatches = allMatches.filter { $0.profile.ruleID == matchedRuleID }

        if !allMatches.isEmpty && exactMatches.isEmpty {
            return CacheRecommendationSnapshot(
                profileID: nil,
                ruleID: matchedRuleID,
                ruleSQLHash: store.ruleSQLHash,
                unitPath: canonicalUnitPath,
                unitIdentity: verifiedIdentity,
                cacheClass: nil,
                allocatedBytes: verifiedBytes,
                thresholdBytes: nil,
                effectiveCost: nil,
                effects: [],
                state: .unknownReview,
                reasons: [.profileRuleMismatch],
                automaticAllowed: false,
                policyVersion: policyVer
            )
        }

        guard let matched = exactMatches.first else {
            // 无 profile 匹配：输出 unknownReview，不显示可重建标签
            // 仅对非缓存类规则（如日志/临时文件）或低于阈值的兼容白名单项在各自策略下处理；此快照本身不授予可重建建议
            let isNonCache = isNonCacheRule(matchedRuleID)
            #if DEBUG
            // Only an explicitly injected test Home may use the remapped fixture allowance.
            let allowRemappedFixture = FileUtil.homeOverrideForTesting != nil && !store.cacheProfiles.isEmpty && (
                store.disabledCacheProfileIDs.count == store.cacheProfiles.count
                || store.junk[AppConfig.RuleIDs.chromiumCache]?.paths.contains(where: { $0.hasPrefix("~/Library/Application Support/Google/Chrome") }) != true
                || store.junk[AppConfig.RuleIDs.aiIDECache]?.paths.contains(where: { $0.hasPrefix("~/Library/Application Support/Cursor") }) != true
            )
            #else
            let allowRemappedFixture = false
            #endif
            let isAllowlistedSmallGenericCache: Bool = {
                guard let rid = matchedRuleID else { return false }
                guard rid == AppConfig.RuleIDs.userCache
                    || rid == AppConfig.RuleIDs.containerCache
                    || rid == AppConfig.RuleIDs.darwinCache else {
                    return false
                }
                guard !isUnderAnyConfiguredProfileRoot(resolvedUnitURL, store: store) else {
                    return false
                }
                return ruleEvidence?.tier == .automatic
                    && ruleEvidence?.defaultSelected == true
                    && verifiedBytes < config.appSuggestionBytes
            }()
            let allowAuto = (isNonCache || isAllowlistedSmallGenericCache || (allowRemappedFixture && verifiedBytes < config.appSuggestionBytes))
                && ruleEvidence?.tier == .automatic
                && ruleEvidence?.defaultSelected == true
            return CacheRecommendationSnapshot(
                profileID: nil,
                ruleID: matchedRuleID,
                ruleSQLHash: store.ruleSQLHash,
                unitPath: canonicalUnitPath,
                unitIdentity: verifiedIdentity,
                cacheClass: nil,
                allocatedBytes: verifiedBytes,
                thresholdBytes: nil,
                effectiveCost: nil,
                effects: [],
                state: .unknownReview,
                reasons: [.profileMissing],
                automaticAllowed: allowAuto,
                policyVersion: policyVer
            )
        }

        let profile = matched.profile
        let resolvedUnitCanonical = SymlinkGuard.canonicalizeMacOSSystemPrefix(matched.unitURL.standardizedFileURL.path)
        let ruleCost = overrideRuleCost ?? (matchedRuleID.flatMap { store.junk[$0]?.rebuildCost } ?? .none)
        let profCost = overrideProfileCost ?? profile.costOverride
        let effectiveCost = effectiveRebuildCost(ruleCost: ruleCost, overrideCost: profCost)
        let effects = overrideEffects ?? [profile.rebuildEffect]

        // 成本未知或影响为空：unknownReview
        guard effectiveCost != .none, !effects.isEmpty else {
            return CacheRecommendationSnapshot(
                profileID: profile.id,
                ruleID: matchedRuleID,
                ruleSQLHash: store.ruleSQLHash,
                unitPath: resolvedUnitCanonical,
                unitIdentity: verifiedIdentity,
                cacheClass: profile.cacheClass,
                allocatedBytes: verifiedBytes,
                thresholdBytes: nil,
                effectiveCost: effectiveCost == .none ? nil : effectiveCost,
                effects: [],
                state: .unknownReview,
                reasons: [.unknownCost],
                automaticAllowed: false,
                policyVersion: policyVer
            )
        }

        // Step 4 & Step 5: 按该单元类别阈值比较（app = 524288000, developer = 1073741824）
        let thresholdBytes: Int64 = (profile.cacheClass == .app)
            ? config.appSuggestionBytes
            : config.developerSuggestionBytes

        if verifiedBytes >= thresholdBytes {
            return CacheRecommendationSnapshot(
                profileID: profile.id,
                ruleID: matchedRuleID,
                ruleSQLHash: store.ruleSQLHash,
                unitPath: resolvedUnitCanonical,
                unitIdentity: verifiedIdentity,
                cacheClass: profile.cacheClass,
                allocatedBytes: verifiedBytes,
                thresholdBytes: thresholdBytes,
                effectiveCost: effectiveCost,
                effects: effects,
                state: .suggestedLarge,
                reasons: [.thresholdReached],
                automaticAllowed: false,
                policyVersion: policyVer
            )
        } else {
            let allowAuto = (ruleEvidence?.tier == .automatic)
                && (ruleEvidence?.defaultSelected == true)
                && (matchedRuleID.map { AppConfig.RuleIDs.implementedAutomaticRules.contains($0) } ?? false)
            return CacheRecommendationSnapshot(
                profileID: profile.id,
                ruleID: matchedRuleID,
                ruleSQLHash: store.ruleSQLHash,
                unitPath: resolvedUnitCanonical,
                unitIdentity: verifiedIdentity,
                cacheClass: profile.cacheClass,
                allocatedBytes: verifiedBytes,
                thresholdBytes: thresholdBytes,
                effectiveCost: effectiveCost,
                effects: effects,
                state: .ordinary,
                reasons: [.belowThreshold],
                automaticAllowed: allowAuto,
                policyVersion: policyVer
            )
        }
    }
}
