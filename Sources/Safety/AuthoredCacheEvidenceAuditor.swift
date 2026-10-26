import Foundation
import Darwin

extension AuthoredRules {

    struct MatchedCacheProfileUnit: Sendable, Equatable {
        let profile: AuthoredCacheProfile
        let unitURL: URL
        let unitPath: String
    }

    func matchCacheProfileUnit(
        for url: URL,
        profile: AuthoredCacheProfile,
        enforceCacheDataPrecedence: Bool = true
    ) -> MatchedCacheProfileUnit? {
        // Match wildcard roots one path component at a time, including the concrete
        // ancestor unit when checking a child during execution.
        if profile.rootTemplate.contains("*") {
            let pattern = SymlinkGuard.canonicalizeMacOSSystemPrefix(KBPaths.expand(profile.rootTemplate))
            let candidatePath = SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path)
            guard candidatePath.hasPrefix(String(pattern.prefix { $0 != "*" })) else { return nil }
            var ancestor = url.standardizedFileURL
            while ancestor.path != "/" {
                if fnmatch(pattern, SymlinkGuard.canonicalizeMacOSSystemPrefix(ancestor.path), FNM_PATHNAME) == 0 {
                    let concrete = AuthoredCacheProfile(id: profile.id, ruleID: profile.ruleID,
                        rootTemplate: ancestor.path, discoveryKind: profile.discoveryKind,
                        cacheClass: profile.cacheClass, rebuildEffect: profile.rebuildEffect,
                        costOverride: profile.costOverride)
                    return matchCacheProfileUnit(for: url, profile: concrete,
                        enforceCacheDataPrecedence: enforceCacheDataPrecedence)
                }
                ancestor.deleteLastPathComponent()
            }
            return nil
        }
        guard !disabledCacheProfileIDs.contains(profile.id),
              !profile.rootTemplate.contains(".."),
              !profile.rootTemplate.contains("\0") else {
            return nil
        }
        let rootURL = URL(fileURLWithPath: KBPaths.expand(profile.rootTemplate)).standardizedFileURL
        let rootPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(rootURL.path)
        let candidateURL = url.standardizedFileURL
        let candidatePath = SymlinkGuard.canonicalizeMacOSSystemPrefix(candidateURL.path)
        guard candidatePath == rootPath || candidatePath.hasPrefix(rootPath + "/") else {
            return nil
        }
        let relComponents: [String]
        if candidatePath == rootPath {
            relComponents = []
        } else {
            let rel = String(candidatePath.dropFirst(rootPath.count + 1))
            relComponents = rel.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        }

        switch profile.discoveryKind {
        case .exactRoot:
            return MatchedCacheProfileUnit(profile: profile, unitURL: rootURL, unitPath: rootPath)

        case .chromiumLeaves:
            guard !relComponents.isEmpty else { return nil }
            let baseURL: URL
            let leafSlice: ArraySlice<String>
            if AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(
                relComponents[0],
                pattern: AppConfig.JunkScan.PathMatching.chromiumProfileName
            ) {
                baseURL = rootURL.appendingPathComponent(relComponents[0])
                leafSlice = relComponents.dropFirst(1)
            } else {
                baseURL = rootURL
                leafSlice = relComponents[...]
            }
            guard !leafSlice.isEmpty else { return nil }
            let firstLeaf = leafSlice[leafSlice.startIndex]
            if leafSlice.count >= 2
                && firstLeaf == "Cache"
                && leafSlice[leafSlice.index(after: leafSlice.startIndex)] == "Cache_Data" {
                let unitURL = baseURL.appendingPathComponent("Cache").appendingPathComponent("Cache_Data")
                let unitPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(unitURL.standardizedFileURL.path)
                return MatchedCacheProfileUnit(profile: profile, unitURL: unitURL, unitPath: unitPath)
            }
            guard AppConfig.JunkScan.PathMatching.chromiumAllowedLeaves.contains(firstLeaf),
                  firstLeaf != "Cache/Cache_Data" else {
                return nil
            }
            if enforceCacheDataPrecedence && firstLeaf == "Cache" {
                let cacheDataURL = baseURL.appendingPathComponent("Cache").appendingPathComponent("Cache_Data")
                if FileUtil.exists(cacheDataURL.path) {
                    return nil
                }
            }
            let unitURL = baseURL.appendingPathComponent(firstLeaf)
            let unitPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(unitURL.standardizedFileURL.path)
            return MatchedCacheProfileUnit(profile: profile, unitURL: unitURL, unitPath: unitPath)

        case .electronLeaves:
            guard !relComponents.isEmpty else { return nil }
            let firstLeaf = relComponents[0]
            if relComponents.count >= 2 && firstLeaf == "Cache" && relComponents[1] == "Cache_Data" {
                let unitURL = rootURL.appendingPathComponent("Cache").appendingPathComponent("Cache_Data")
                let unitPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(unitURL.standardizedFileURL.path)
                return MatchedCacheProfileUnit(profile: profile, unitURL: unitURL, unitPath: unitPath)
            }
            guard AppConfig.JunkScan.PathMatching.electronAllowedLeaves.contains(firstLeaf),
                  firstLeaf != "Cache/Cache_Data" else {
                return nil
            }
            if enforceCacheDataPrecedence && firstLeaf == "Cache" {
                let cacheDataURL = rootURL.appendingPathComponent("Cache").appendingPathComponent("Cache_Data")
                if FileUtil.exists(cacheDataURL.path) {
                    return nil
                }
            }
            let unitURL = rootURL.appendingPathComponent(firstLeaf)
            let unitPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(unitURL.standardizedFileURL.path)
            return MatchedCacheProfileUnit(profile: profile, unitURL: unitURL, unitPath: unitPath)

        case .firefoxLeaves:
            guard relComponents.count >= 2 else { return nil }
            let profileDir = relComponents[0]
            let leaf = relComponents[1]
            guard AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(
                profileDir,
                pattern: AppConfig.JunkScan.PathMatching.firefoxProfileName
            ), AppConfig.JunkScan.PathMatching.firefoxAllowedLeaves.contains(leaf) else {
                return nil
            }
            let unitURL = rootURL.appendingPathComponent(profileDir).appendingPathComponent(leaf)
            let unitPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(unitURL.standardizedFileURL.path)
            return MatchedCacheProfileUnit(profile: profile, unitURL: unitURL, unitPath: unitPath)

        case .derivedChildren:
            guard !relComponents.isEmpty else { return nil }
            let childName = relComponents[0]
            guard childName != "ModuleCache.noindex" && childName != "ModuleCache" else {
                return nil
            }
            let unitURL = rootURL.appendingPathComponent(childName)
            if enforceCacheDataPrecedence {
                if profile.ruleID == AppConfig.RuleIDs.derivedOrphan && !DeveloperArtifactPolicy.isOrphanDerivedData(unitURL) {
                    return nil
                }
                if profile.ruleID == AppConfig.RuleIDs.derivedLive && DeveloperArtifactPolicy.isOrphanDerivedData(unitURL) {
                    return nil
                }
            }
            let unitPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(unitURL.standardizedFileURL.path)
            return MatchedCacheProfileUnit(profile: profile, unitURL: unitURL, unitPath: unitPath)
        }
    }

    func discoverUnits(for profile: AuthoredCacheProfile) -> [URL] {
        if profile.rootTemplate.contains("*") {
            return expandedCacheRoots(profile.rootTemplate).flatMap { root in
                discoverUnits(for: AuthoredCacheProfile(id: profile.id, ruleID: profile.ruleID,
                    rootTemplate: root.path, discoveryKind: profile.discoveryKind,
                    cacheClass: profile.cacheClass, rebuildEffect: profile.rebuildEffect,
                    costOverride: profile.costOverride))
            }
        }
        guard !disabledCacheProfileIDs.contains(profile.id),
              let rule = junk[profile.ruleID],
              rule.active,
              !profile.rootTemplate.contains(".."),
              !profile.rootTemplate.contains("\0") else {
            return []
        }
        let rootURL = URL(fileURLWithPath: KBPaths.expand(profile.rootTemplate))
        guard FileUtil.exists(rootURL.path),
              Self.hasExactOnDiskCase(rootURL, relativeTo: rootURL.deletingLastPathComponent()),
              !SymlinkGuard.isSymbolicLink(at: rootURL),
              SymlinkGuard.isSafePath(url: rootURL) else {
            return []
        }

        func isAuthorizedUnit(_ candidate: URL, within base: URL?) -> Bool {
            guard FileUtil.exists(candidate.path),
                  Self.hasExactOnDiskCase(candidate, relativeTo: base ?? candidate.deletingLastPathComponent()),
                  !SymlinkGuard.isSymbolicLink(at: candidate),
                  SymlinkGuard.isSafePath(url: candidate, within: base),
                  !CleanupSafetyPolicy.isProtectedAsset(candidate),
                  matches(candidate, rule: rule),
                  !isExcluded(candidate, by: rule) else {
                return false
            }
            if AppConfig.RuleIDs.cacheSubdirRules.contains(rule.id) {
                return cacheSubdirTier(candidate, ruleID: rule.id) != nil
            }
            return true
        }

        var found: [URL] = []
        switch profile.discoveryKind {
        case .exactRoot:
            if isAuthorizedUnit(rootURL, within: nil) {
                found.append(rootURL)
            }

        case .chromiumLeaves:
            var baseRoots: [URL] = [rootURL]
            for child in FileUtil.children(of: rootURL) {
                let profileName = child.lastPathComponent
                if AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(
                    profileName,
                    pattern: AppConfig.JunkScan.PathMatching.chromiumProfileName
                ),
                Self.hasExactOnDiskCase(child, relativeTo: rootURL),
                !SymlinkGuard.isSymbolicLink(at: child),
                SymlinkGuard.isSafePath(url: child, within: rootURL) {
                    baseRoots.append(child)
                }
            }
            for base in baseRoots {
                let cacheDataURL = base.appendingPathComponent("Cache/Cache_Data")
                let hasCacheData = isAuthorizedUnit(cacheDataURL, within: base)
                for leaf in AppConfig.JunkScan.PathMatching.chromiumAllowedLeaves {
                    if leaf == "Cache" && hasCacheData { continue }
                    let leafURL = base.appendingPathComponent(leaf)
                    if isAuthorizedUnit(leafURL, within: base) {
                        found.append(leafURL)
                    }
                }
            }

        case .electronLeaves:
            let cacheDataURL = rootURL.appendingPathComponent("Cache/Cache_Data")
            let hasCacheData = isAuthorizedUnit(cacheDataURL, within: rootURL)
            for leaf in AppConfig.JunkScan.PathMatching.electronAllowedLeaves {
                if leaf == "Cache" && hasCacheData { continue }
                let leafURL = rootURL.appendingPathComponent(leaf)
                if isAuthorizedUnit(leafURL, within: rootURL) {
                    found.append(leafURL)
                }
            }

        case .firefoxLeaves:
            for profileDir in FileUtil.children(of: rootURL) {
                let profileName = profileDir.lastPathComponent
                guard AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(
                    profileName,
                    pattern: AppConfig.JunkScan.PathMatching.firefoxProfileName
                ),
                Self.hasExactOnDiskCase(profileDir, relativeTo: rootURL),
                !SymlinkGuard.isSymbolicLink(at: profileDir),
                SymlinkGuard.isSafePath(url: profileDir, within: rootURL) else {
                    continue
                }
                for leaf in AppConfig.JunkScan.PathMatching.firefoxAllowedLeaves {
                    let leafURL = profileDir.appendingPathComponent(leaf)
                    if isAuthorizedUnit(leafURL, within: profileDir) {
                        found.append(leafURL)
                    }
                }
            }

        case .derivedChildren:
            for child in FileUtil.children(of: rootURL) {
                let name = child.lastPathComponent
                guard name != "ModuleCache.noindex" && name != "ModuleCache" else { continue }
                guard isAuthorizedUnit(child, within: rootURL) else { continue }
                if profile.ruleID == AppConfig.RuleIDs.derivedOrphan {
                    guard DeveloperArtifactPolicy.isOrphanDerivedData(child) else { continue }
                } else if profile.ruleID == AppConfig.RuleIDs.derivedLive {
                    guard !DeveloperArtifactPolicy.isOrphanDerivedData(child) else { continue }
                }
                found.append(child)
            }
        }
        return found.sorted { $0.path < $1.path }
    }

    func discoverCacheProfileUnits(ruleID: String? = nil) -> [(profile: AuthoredCacheProfile, unitURL: URL)] {
        let profiles = cacheProfiles.values
            .filter { !disabledCacheProfileIDs.contains($0.id) && (ruleID == nil || $0.ruleID == ruleID) }
            .sorted { $0.id < $1.id }
        var out: [(profile: AuthoredCacheProfile, unitURL: URL)] = []
        for profile in profiles {
            for unitURL in discoverUnits(for: profile) {
                out.append((profile: profile, unitURL: unitURL))
            }
        }
        return out
    }

    /// Bounded-depth expansion of authored patterns; never follows symlink roots.
    func expandedCacheRoots(_ template: String) -> [URL] {
        let parts = SymlinkGuard.canonicalizeMacOSSystemPrefix(KBPaths.expand(template)).split(separator: "/").map(String.init)
        guard !parts.contains("..") else { return [] }
        var roots = [URL(fileURLWithPath: "/")]
        for part in parts {
            roots = roots.flatMap { parent -> [URL] in
                let children: [URL]
                if part.contains("*") {
                    do {
                        children = try FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil)
                    } catch {
                        IOScanContext.recordDegradation(.containerEnumerationIncomplete,
                            issue: L10n.localized(.scanCoverageIncomplete))
                        return []
                    }
                } else { children = [parent.appendingPathComponent(part)] }
                return children.filter {
                    fnmatch(part, $0.lastPathComponent, FNM_PATHNAME) == 0
                        && FileUtil.exists($0.path)
                        && !SymlinkGuard.isSymbolicLink(at: $0)
                        && !SymlinkGuard.hasSymlinkEscape(url: $0)
                }
            }
            if roots.isEmpty { break }
        }
        return roots
    }

    func matchingCacheProfileUnits(
        for url: URL,
        ruleID: String? = nil,
        enforceCacheDataPrecedence: Bool = true
    ) -> [MatchedCacheProfileUnit] {
        guard !cacheProfiles.isEmpty else { return [] }
        return cacheProfiles.values
            .filter { ruleID == nil || $0.ruleID == ruleID }
            .sorted { $0.id < $1.id }
            .compactMap { matchCacheProfileUnit(for: url, profile: $0, enforceCacheDataPrecedence: enforceCacheDataPrecedence) }
    }

    func matchingCacheProfiles(for url: URL, ruleID: String? = nil) -> [AuthoredCacheProfile] {
        matchingCacheProfileUnits(for: url, ruleID: ruleID).map(\.profile)
    }

    func effectiveProcessLocks(for url: URL, rule: AuthoredJunkRule) -> [String] {
        let baseRuleLocks: [String] = {
            guard !rule.processLocks.isEmpty else { return [] }
            let low = url.standardizedFileURL.path.lowercased()
            if rule.id == AppConfig.RuleIDs.npmCacache || low.contains("/.npm/") {
                return ["npm", "pnpm", "yarn"]
            }
            if rule.id == "JC.DEV.PKG.SAFE" || rule.id == "JC.DEV.PKG.L2" {
                if low.contains("pnpm") { return ["pnpm"] }
                if low.contains("yarn") { return ["yarn"] }
                if low.contains("/.bun/") || low.contains("/bun/") { return ["bun"] }
                if low.contains("/pip") { return ["pip", "pip3"] }
                if low.contains("/uv") { return ["uv"] }
                if low.contains("/.cargo/") || low.contains("/cargo/") { return ["cargo", "rustc", "rustup"] }
                if low.contains("go-build") || low.contains("goimports") { return ["go"] }
                if low.contains("cocoapods") { return ["pod"] }
                if low.contains("swiftpm") { return ["swift", "xcodebuild"] }
                if low.contains("gradle") || low.contains(".ivy2") || low.contains(".sbt") { return ["GradleDaemon", "gradle", "kotlin"] }
                if low.contains("/.m2/") { return ["mvn", "gradle", "GradleDaemon"] }
                if low.contains("/.nuget/") { return ["dotnet"] }
                if low.contains("conda") { return ["conda"] }
                if low.contains("node-gyp") { return ["npm", "pnpm", "yarn"] }
                if low.contains("playwright") || low.contains("torch") || low.contains("helm") || low.contains("composer") || low.contains("terraform") || low.contains(".gem/") || low.contains(".android/") || low.contains(".docker/buildx") {
                    return []
                }
            }
            return rule.processLocks
        }()
        var locks = Set(baseRuleLocks)
        for matched in matchingCacheProfileUnits(for: url, ruleID: nil, enforceCacheDataPrecedence: false) {
            for lock in cacheProfileLocks[matched.profile.id] ?? []
                where lock.lockKind == .processName || lock.lockKind == .processFamily {
                locks.insert(lock.lockValue)
            }
        }
        return locks.sorted()
    }

    func evidence(
        for url: URL,
        preferredID: String? = nil,
        isContainerRoot: Bool = false,
        identity: FileIdentity? = nil,
        knownSize: Int64? = nil,
        requireCurrentUserUID: Bool = true,
        knownFullScopeVerifiable: Bool? = nil
    ) -> CleanupRuleEvidence? {
        guard loaded else { return nil }
        let normalizedPath = Self.normalizeRuleMatchPath(url)
        if let disabled = disabledDiscoveryRule(normalizedPath: normalizedPath) {
            return CleanupRuleEvidence(id: disabled.id, tier: .readOnly, reason: .whitelistProtected, defaultSelected: false)
        }
        let lastComponentLower = url.lastPathComponent.lowercased()
        var candidates = junk.values.filter { $0.active && matchesNormalizedPath(normalizedPath, rule: $0) }
        if let preferredID { candidates = candidates.filter { $0.id == preferredID } }
        let profileRuleIDs = Set(matchingCacheProfileUnits(for: url, ruleID: nil, enforceCacheDataPrecedence: false).map { $0.profile.ruleID })
        // Most specific matching path wins. Ties prefer manual review over automatic classification, then matching profile rule_id, then deterministic rule ID.
        candidates.sort {
            let a = matchingPathLengthNormalizedPath(normalizedPath, rule: $0)
            let b = matchingPathLengthNormalizedPath(normalizedPath, rule: $1)
            if a != b { return a > b }
            if $0.tier.conservatismRank != $1.tier.conservatismRank {
                return $0.tier.conservatismRank > $1.tier.conservatismRank
            }
            let aMatchesProfile = profileRuleIDs.contains($0.id)
            let bMatchesProfile = profileRuleIDs.contains($1.id)
            if aMatchesProfile != bMatchesProfile {
                return aMatchesProfile
            }
            return $0.id < $1.id
        }
        let targetIdentity = identity ?? FileIdentity.capture(from: url)
        let isProtectedRootSelf = Self.isProtectedSystemOrCacheRoot(url)
        let ownScopeVerifiable: Bool = {
            if let known = knownFullScopeVerifiable, !isContainerRoot {
                return known
            }
            return OpenFileGuard.isCurrentUserVerifiableScope(
                url,
                identity: targetIdentity,
                checkDescendants: false,
                requireCurrentUserUID: requireCurrentUserUID
            )
        }()
        var fullScopeVerifiableCache: Bool? = knownFullScopeVerifiable
        func isFullScopeVerifiable() -> Bool {
            if let cached = fullScopeVerifiableCache { return cached }
            let result = ownScopeVerifiable && OpenFileGuard.isCurrentUserVerifiableScope(
                url,
                identity: targetIdentity,
                checkDescendants: true,
                requireCurrentUserUID: requireCurrentUserUID
            )
            fullScopeVerifiableCache = result
            return result
        }
        for rule in candidates {
            if (rule.id == "JC.AI.OLDVERSION" || rule.id == "JC.DEV.BROWSER.DOWNLOAD"),
               !VersionedCachePolicy.isEligible(url, ruleID: rule.id) {
                return CleanupRuleEvidence(id: rule.id, tier: .readOnly, reason: .whitelistProtected, defaultSelected: false)
            }
            if rule.id == AppConfig.RuleIDs.leftoverOrphan
                && preferredID != AppConfig.RuleIDs.leftoverOrphan {
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
            if rule.id == AppConfig.RuleIDs.jetBrainsCache && !Self.isValidJetBrainsLeafOrDescendant(url) { continue }
            if rule.id == AppConfig.RuleIDs.firefoxCache && !Self.isValidFirefoxLeafOrDescendant(url) { continue }
            if rule.id == "JC.DEV.PROJECT" && preferredID != "JC.DEV.PROJECT" && !DeveloperArtifactPolicy.isProvenProjectArtifact(url) { continue }
            let isContainerHeader = isContainerRoot && isContainerRootTarget(url, ruleID: rule.id)
            let inCurrentUserScope = isContainerHeader ? ownScopeVerifiable : isFullScopeVerifiable()
            var tier = rule.tier
            if !inCurrentUserScope { tier = .readOnly }
            if isProtectedRootSelf { tier = .readOnly }
            if AppConfig.RuleIDs.rootOnlyContainerRules.contains(rule.id)
                && isExactRuleRoot(normalizedPath: normalizedPath, rule: rule) {
                tier = .readOnly
            }
            if isExcludedNormalizedPath(normalizedPath, lastComponentLower: lastComponentLower, by: rule) { tier = .readOnly }
            if rule.minAgeHours > 0 {
                if let targetIdentity {
                    if Date().timeIntervalSince1970 - Double(targetIdentity.modificationTime) < rule.minAgeHours * AppConfig.Security.secondsPerHour { tier = .readOnly }
                } else { tier = .readOnly }
            }
            if !AppConfig.RuleIDs.implementedPredicates.contains(rule.predicate) { tier = .readOnly }
            if rule.predicate == "wechat_not_running"
                && (ProcessGuard.isAppRunning(bundleID: "com.tencent.xinWeChat") || ProcessGuard.isAppRunning(named: "WeChat")) {
                tier = .readOnly
            }
            if hasRunningAppLock(for: url, rule: rule, isRunning: ProcessGuard.isAppRunning(bundleID:))
                || (AppConfig.RuleIDs.cacheSubdirRules.contains(rule.id)
                    && ProcessGuard.shouldSkipDueToRunningProcess(path: url.path).skip) {
                tier = .readOnly
            }
            if ProcessGuard.isAnyToolchainRunning(effectiveProcessLocks(for: url, rule: rule)).isRunning { tier = .readOnly }
            if (rule.id == AppConfig.RuleIDs.derivedOrphan || rule.id == AppConfig.RuleIDs.derivedLive)
                && ProcessGuard.shouldSkipDueToRunningProcess(path: url.path).skip {
                tier = .readOnly
            }
            // Gate 2: JC.CACHE.USER Per-App allowlist + running app lock
            if rule.id == AppConfig.RuleIDs.userCache {
                guard let childName = Self.extractUserCacheChildName(for: url) else {
                    tier = .readOnly
                    let reason: ReasonCode = .whitelistProtected
                    return CleanupRuleEvidence(id: rule.id, tier: tier, reason: reason, defaultSelected: false)
                }
                let isKnownUserCache = AppConfig.RuleIDs.auditedAutoCleanUserCacheBundleIDsLower.contains(childName.lowercased())
                    || self.electronDirectories[childName] != nil
                    || self.electronDirectories.keys.contains(where: { $0.caseInsensitiveCompare(childName) == .orderedSame })
                    || self.electronDirectories.values.contains(where: { $0.caseInsensitiveCompare(childName) == .orderedSame })
                if Self.isUserCacheChildAppRunning(childName, url: url) {
                    tier = .readOnly
                } else if tier == .automatic && !isKnownUserCache {
                    tier = .review
                }
            }
            // Gate 2: JC.CACHE.CONTAINER sandbox bundleID extraction + running app lock
            if rule.id == AppConfig.RuleIDs.containerCache {
                if Self.isContainerCacheHostRunning(for: url) {
                    tier = .readOnly
                } else if tier == .automatic {
                    tier = .review
                }
            }
            // Gate 3: JC.AI.HF.MODEL one_row_per_model (models--* directory granularity)
            if rule.id == AppConfig.RuleIDs.hfModel {
                let isModelDir = (targetIdentity?.isDirectory == true)
                    && lastComponentLower.hasPrefix("models--")
                    && url.deletingLastPathComponent().lastPathComponent.lowercased() == "hub"
                if !isModelDir {
                    tier = .readOnly
                }
            }
            // Gate 4: JC.LEFTOVER.ORPHAN restricted to OrphanFinderEngine Layer 1 volatile roots
            if rule.id == AppConfig.RuleIDs.leftoverOrphan {
                let canSchedule = OrphanSafetyPolicy.canScheduleForCleanup(url)
                let running = ProcessGuard.shouldSkipDueToRunningProcess(path: url.path).skip
                    || ProcessGuard.isAppRunning(bundleID: url.deletingPathExtension().lastPathComponent)
                if !canSchedule || running {
                    tier = .readOnly
                } else if tier == .automatic {
                    tier = .review
                }
            }
            // Gate 5: JC.SYS.PLIST.BROKEN plutil lint check + bundleID not running
            if rule.id == AppConfig.RuleIDs.brokenPlist {
                let plistCheck = Self.isBrokenPlistEligible(url)
                if !plistCheck.eligible || plistCheck.runningLocked {
                    tier = .readOnly
                } else if tier == .automatic {
                    tier = .review
                }
            }
            if tier == .automatic && !AppConfig.RuleIDs.implementedAutomaticRules.contains(rule.id) { tier = .review }
            if rule.id == AppConfig.RuleIDs.deviceSupport && DeveloperArtifactPolicy.mustKeepDeviceSupport(url) { tier = .readOnly }
            if rule.id == "JC.DEV.PROJECT" && tier.executable {
                if !DeveloperArtifactPolicy.isEligibleProjectArtifact(url) {
                    tier = .readOnly
                }
            }
            if (rule.id == AppConfig.RuleIDs.darwinTmp || rule.id == AppConfig.RuleIDs.darwinCache) && !isContainerHeader {
                let isRegOrDir = targetIdentity.map { ($0.mode & S_IFMT) == S_IFREG || $0.isDirectory } ?? false
                if !isRegOrDir || !OpenFileGuard.isIdle(url, fresh: false) {
                    tier = .readOnly
                }
            }
            if !isContainerHeader && !OpenFileGuard.isIdle(url, fresh: false) {
                tier = .readOnly
            }
            if rule.action == "native" || rule.action == "read_only" { tier = .readOnly }
            if rule.id == AppConfig.RuleIDs.derivedOrphan && tier == .automatic && !DeveloperArtifactPolicy.isOrphanDerivedData(url) { tier = .review }
            // L1 application data roots never confer permission to delete the whole root.
            if AppConfig.RuleIDs.cacheSubdirRules.contains(rule.id) {
                guard let cacheTier = cacheSubdirTier(url, ruleID: rule.id) else { continue }
                if cacheTier != .automatic && tier.executable { tier = cacheTier }
            }
            let logEligible = isContainerHeader ? true : isLogRuleEligible(url, ruleID: rule.id)
            let meetsMinBytes: Bool = {
                if rule.minBytes <= 0 || isContainerHeader { return true }
                if let knownSize {
                    return knownSize >= rule.minBytes
                }
                let m = FileUtil.measureSize(of: url)
                return m.isComplete && m.bytes >= rule.minBytes
            }()
            let selected = inCurrentUserScope && rule.selected && logEligible && meetsMinBytes && tier == .automatic && AppConfig.RuleIDs.implementedAutomaticRules.contains(rule.id) && (isContainerHeader || OpenFileGuard.isIdle(url, fresh: false))
            let reason: ReasonCode = tier == .readOnly || tier == .forbidden ? .whitelistProtected : rule.reason
            return CleanupRuleEvidence(id: rule.id, tier: tier, reason: reason, defaultSelected: selected)
        }
        return nil
    }

    func resolvedOwnerBundleIDs(for url: URL, rule: AuthoredJunkRule) -> [String] {
        var ids = Set(rule.bundleLocks.filter { !$0.contains("{") && !$0.isEmpty })
        if AppConfig.RuleIDs.cacheSubdirRules.contains(rule.id) {
            // SQL maps data directory names to identities (e.g. Code != Visual Studio Code).
            let components = Set(url.pathComponents)
            ids.formUnion(electronDirectories.filter { components.contains($0.value) }.keys)
        }
        if rule.id == AppConfig.RuleIDs.containerCache,
           let bid = Self.extractContainerBundleID(for: url) {
            ids.insert(bid)
        }
        for matched in matchingCacheProfileUnits(for: url, ruleID: nil, enforceCacheDataPrecedence: false) {
            for lock in cacheProfileLocks[matched.profile.id] ?? [] where lock.lockKind == .bundleID {
                ids.insert(lock.lockValue)
            }
        }
        return ids.sorted()
    }

    func hasRunningAppLock(for url: URL, rule: AuthoredJunkRule, isRunning: (String) -> Bool) -> Bool {
        return resolvedOwnerBundleIDs(for: url, rule: rule).contains(where: isRunning)
    }

    /// Discovery uses the same closed list as authorization, never arbitrary support-directory names.
    func cacheDirectories(ruleID: String) -> [URL] {
        guard let rule = junk[ruleID], rule.active else { return [] }
        var found = Set<URL>()
        if ruleID == AppConfig.RuleIDs.firefoxCache {
            for raw in rule.paths {
                let expanded = KBPaths.expand(raw)
                let parts = expanded.components(separatedBy: "/*/")
                guard parts.count == 2 else { continue }
                let profilesRoot = URL(fileURLWithPath: parts[0])
                let leafRel = parts[1]
                guard AppConfig.JunkScan.PathMatching.firefoxAllowedLeaves.contains(leafRel),
                      FileUtil.exists(profilesRoot.path),
                      Self.hasExactOnDiskCase(profilesRoot, relativeTo: profilesRoot.deletingLastPathComponent()),
                      !SymlinkGuard.isSymbolicLink(at: profilesRoot),
                      SymlinkGuard.isSafePath(url: profilesRoot) else { continue }
                for profileDir in FileUtil.children(of: profilesRoot) {
                    let profileName = profileDir.lastPathComponent
                    guard AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(
                        profileName,
                        pattern: AppConfig.JunkScan.PathMatching.firefoxProfileName
                    ),
                    Self.hasExactOnDiskCase(profileDir, relativeTo: profilesRoot),
                    !SymlinkGuard.isSymbolicLink(at: profileDir),
                    SymlinkGuard.isSafePath(url: profileDir, within: profilesRoot) else { continue }
                    let url = profileDir.appendingPathComponent(leafRel)
                    if FileUtil.exists(url.path),
                       Self.hasExactOnDiskCase(url, relativeTo: profileDir),
                       !SymlinkGuard.isSymbolicLink(at: url),
                       !CleanupSafetyPolicy.isProtectedAsset(url),
                       SymlinkGuard.isSafePath(url: url, within: profileDir),
                       matches(url, rule: rule) {
                        found.insert(url)
                    }
                }
            }
            return found.sorted { $0.path < $1.path }
        }
        guard let names = cacheSubdirs[ruleID] else { return [] }
        let allowProfiles = rule.id.hasPrefix("JC.BRW.CHROMIUM.") || rule.id == AppConfig.RuleIDs.arcCache || rule.predicate.contains("profile_split")
        for raw in rule.paths {
            let roots = raw.contains("{electronDataDir}") && !raw.contains("{bundleID}")
                ? electronDirectories.values.map { raw.replacingOccurrences(of: "{electronDataDir}", with: $0) } : [raw]
            for path in roots where !path.contains("{") && !path.contains("*") {
                let root = URL(fileURLWithPath: KBPaths.expand(path))
                guard FileUtil.exists(root.path),
                      Self.hasExactOnDiskCase(root, relativeTo: root.deletingLastPathComponent()),
                      !SymlinkGuard.isSymbolicLink(at: root),
                      SymlinkGuard.isSafePath(url: root) else { continue }
                var candidateRoots: [URL] = [root]
                if allowProfiles {
                    for child in FileUtil.children(of: root) {
                        let profile = child.lastPathComponent
                        let knownProfile = AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(
                            profile,
                            pattern: AppConfig.JunkScan.PathMatching.chromiumProfileName
                        )
                        if knownProfile,
                           Self.hasExactOnDiskCase(child, relativeTo: root),
                           !SymlinkGuard.isSymbolicLink(at: child),
                           SymlinkGuard.isSafePath(url: child, within: root) {
                            candidateRoots.append(child)
                        }
                    }
                }
                for baseRoot in candidateRoots {
                    let cacheDataURL = baseRoot.appendingPathComponent("Cache/Cache_Data")
                    let hasValidCacheData = names["Cache/Cache_Data"] != nil
                        && FileUtil.exists(cacheDataURL.path)
                        && Self.hasExactOnDiskCase(cacheDataURL, relativeTo: baseRoot)
                        && !SymlinkGuard.isSymbolicLink(at: cacheDataURL)
                        && !CleanupSafetyPolicy.isProtectedAsset(cacheDataURL)
                        && SymlinkGuard.isSafePath(url: cacheDataURL, within: baseRoot)
                        && cacheSubdirTier(cacheDataURL, ruleID: ruleID) != nil
                    for name in names.keys {
                        if name == "Cache" && hasValidCacheData {
                            continue
                        }
                        let url = baseRoot.appendingPathComponent(name)
                        if FileUtil.exists(url.path),
                           Self.hasExactOnDiskCase(url, relativeTo: baseRoot),
                           !SymlinkGuard.isSymbolicLink(at: url),
                           !CleanupSafetyPolicy.isProtectedAsset(url),
                           SymlinkGuard.isSafePath(url: url, within: baseRoot),
                           cacheSubdirTier(url, ruleID: ruleID) != nil {
                            found.insert(url)
                        }
                    }
                }
            }
        }
        return found.sorted { $0.path < $1.path }
    }

    func cacheSubdirTier(_ url: URL, ruleID: String? = nil) -> CleanupTier? {
        guard let ruleID else {
            // Compatibility for browser discovery; runtime evidence always supplies its rule ID.
            let path = url.standardizedFileURL.path
            return chromiumSubdirs.first { path.hasSuffix("/" + $0.key) }?.value
        }
        guard let rule = junk[ruleID], let allowed = cacheSubdirs[ruleID] else { return nil }
        let sortedAllowed = allowed.sorted {
            let aCount = $0.key.split(separator: "/").count
            let bCount = $1.key.split(separator: "/").count
            return aCount == bCount ? $0.key < $1.key : aCount > bCount
        }
        for (name, tier) in sortedAllowed {
            let root = (0..<name.split(separator: "/").count).reduce(url) { value, _ in value.deletingLastPathComponent() }
            guard url.standardizedFileURL.path == root.appendingPathComponent(name).standardizedFileURL.path else { continue }
            if FileUtil.exists(url.path) && !Self.hasExactOnDiskCase(url, relativeTo: root) {
                continue
            }
            if name == "Cache" && allowed["Cache/Cache_Data"] != nil {
                let cacheDataURL = root.appendingPathComponent("Cache/Cache_Data")
                if FileUtil.exists(cacheDataURL.path) && Self.hasExactOnDiskCase(cacheDataURL, relativeTo: root) {
                    return nil
                }
            }
            // Exact relative subdirectory, with profile wildcards resolved by the path matcher.
            if matches(root, rule: rule) && ruleRootMatches(root, rule: rule) { return tier }
        }
        return nil
    }

    func ruleRootMatches(_ url: URL, rule: AuthoredJunkRule) -> Bool {
        if FileUtil.exists(url.path) && !Self.hasExactOnDiskCase(url, relativeTo: url.deletingLastPathComponent()) {
            return false
        }
        let path = SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path)
        return rule.paths.contains { raw in
            var roots = [KBPaths.expand(raw)]
            if raw.contains("{electronDataDir}") {
                roots = electronDirectories.values.map { KBPaths.expand(raw.replacingOccurrences(of: "{electronDataDir}", with: $0)) }
            } else if raw.hasSuffix("/*/*") {
                roots.append(KBPaths.expand(String(raw.dropLast(2))))
            }
            return roots.contains { root in
                guard !root.contains("{") else { return false }
                let normalizedRoot = SymlinkGuard.canonicalizeMacOSSystemPrefix(URL(fileURLWithPath: root).standardizedFileURL.path)
                if fnmatch(normalizedRoot, path, FNM_PATHNAME) == 0 { return true }
                guard rule.id.hasPrefix("JC.BRW.CHROMIUM.") || rule.id == AppConfig.RuleIDs.arcCache else { return false }
                let profile = url.lastPathComponent
                let knownProfile = AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(
                    profile,
                    pattern: AppConfig.JunkScan.PathMatching.chromiumProfileName
                )
                let parentURL = url.deletingLastPathComponent()
                if FileUtil.exists(parentURL.path) && !Self.hasExactOnDiskCase(parentURL, relativeTo: parentURL.deletingLastPathComponent()) {
                    return false
                }
                return knownProfile && fnmatch(normalizedRoot, SymlinkGuard.canonicalizeMacOSSystemPrefix(parentURL.standardizedFileURL.path), FNM_PATHNAME) == 0
            }
        }
    }
}
