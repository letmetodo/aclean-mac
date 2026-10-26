import Foundation
import SQLite3
import Darwin

enum CleanupTier: String, Sendable {
    case automatic = "L1", review = "L2", readOnly = "L3", forbidden = "L4"
    var executable: Bool { self == .automatic || self == .review }
    var conservatismRank: Int {
        switch self {
        case .forbidden: return 4
        case .readOnly:  return 3
        case .review:    return 2
        case .automatic: return 1
        }
    }
}

struct CleanupRuleEvidence: Sendable, Equatable {
    var ruleIdentity: RuleIdentity? = RuleTaskGate.shared.identity
    let id: String
    let tier: CleanupTier
    let reason: ReasonCode
    let defaultSelected: Bool
    var containerPath: String? = nil
    var containerIdentity: FileIdentity? = nil
    var executable: Bool { tier.executable }
}

struct CompiledRulePattern: Sendable {
    let root: String
    let isGlob: Bool
    let wildcardCount: Int
    let slashCount: Int
    let staticSpecificity: Int
    let staticPrefixBeforeWildcard: String
    let literalSuffixAfterLastWildcard: String
}

struct AuthoredJunkRule: Sendable {
    let id: String
    let tier: CleanupTier
    let action: String
    let active: Bool
    let selected: Bool
    let minAgeHours: Double
    let minBytes: Int64
    let predicate: String
    let reason: ReasonCode
    let rebuildCost: RebuildCost
    /// 规则的本地化标题键（如 `junk.cache.user`）。用于在界面上显示「用户缓存」
    /// 而不是 `com.google.Chrome` 这类技术名。空串表示该规则没有配置友好名，回退到路径名。
    let titleKey: String
    var paths: [String] = []
    var excludedNames: [String] = []
    var bundleLocks: [String] = []
    var processLocks: [String] = []
    var compiledPatterns: [CompiledRulePattern] = []
    var compiledExcluded: [(expanded: String, rawLower: String)] = []

    init(
        id: String,
        tier: CleanupTier,
        action: String,
        active: Bool,
        selected: Bool,
        minAgeHours: Double,
        minBytes: Int64,
        predicate: String,
        reason: ReasonCode,
        rebuildCost: RebuildCost = .low,
        titleKey: String = "",
        paths: [String] = [],
        excludedNames: [String] = [],
        bundleLocks: [String] = [],
        processLocks: [String] = []
    ) {
        self.id = id
        self.tier = tier
        self.action = action
        self.active = active
        self.selected = selected
        self.minAgeHours = minAgeHours
        self.minBytes = minBytes
        self.predicate = predicate
        self.reason = reason
        self.rebuildCost = rebuildCost
        self.titleKey = titleKey
        self.paths = paths
        self.excludedNames = excludedNames
        self.bundleLocks = bundleLocks
        self.processLocks = processLocks
    }

    mutating func compilePatterns(electronDirectories: [String: String]) {
        var patterns: [CompiledRulePattern] = []
        for raw in paths {
            let isPlaceholder = raw.contains("{electronDataDir}") && !raw.contains("{bundleID}")
            let expanded: [String]
            if isPlaceholder {
                expanded = electronDirectories.values.map { raw.replacingOccurrences(of: "{electronDataDir}", with: $0) }
            } else {
                expanded = [raw]
            }
            for cand in expanded where !cand.contains("{") {
                let root = SymlinkGuard.canonicalizeMacOSSystemPrefix(
                    URL(fileURLWithPath: KBPaths.expand(cand)).standardizedFileURL.path
                ).lowercased()
                let isGlob = cand.contains("*")
                let wcCount = isGlob ? cand.filter({ $0 == "*" }).count : 0
                let slashCount = root.utf8.filter({ $0 == UInt8(ascii: "/") }).count
                let baseSpec = isGlob ? root.replacingOccurrences(of: "*", with: "").count : root.count
                let spec = isPlaceholder ? max(1, baseSpec - 1) : baseSpec
                let prefixBeforeWC = isGlob ? String(root.prefix(while: { $0 != "*" })) : root
                let suffixAfterWC: String = {
                    guard isGlob, let lastStar = root.lastIndex(of: "*") else { return "" }
                    let s = String(root[root.index(after: lastStar)...])
                    return (s.contains("?") || s.contains("[")) ? "" : s
                }()
                patterns.append(CompiledRulePattern(
                    root: root,
                    isGlob: isGlob,
                    wildcardCount: wcCount,
                    slashCount: slashCount,
                    staticSpecificity: spec,
                    staticPrefixBeforeWildcard: prefixBeforeWC,
                    literalSuffixAfterLastWildcard: suffixAfterWC
                ))
            }
        }
        self.compiledPatterns = patterns
        self.compiledExcluded = excludedNames.map { name in
            (expanded: KBPaths.expand(name).lowercased(), rawLower: name.lowercased())
        }
    }
}

struct AuthoredUninstallTemplate: Sendable {
    let id: String
    let path: String
    let tier: CleanupTier
    let domain: String
    let execute: Bool
    let selected: Bool
}

struct AuthoredPathProtection: Sendable {
    let path: String
    let kind: String
    let normalizedTarget: String
    let lastSegment: String

    init(path: String, kind: String) {
        self.path = path
        self.kind = kind
        let target: String
        if kind == "marker" && path.hasPrefix("**/") {
            target = String(path.dropFirst(2)).lowercased()
        } else if kind == "exact" || kind == "prefix" {
            target = SymlinkGuard.canonicalizeMacOSSystemPrefix(
                URL(fileURLWithPath: KBPaths.expand(path)).standardizedFileURL.path
            ).lowercased()
        } else {
            target = KBPaths.expand(path).lowercased()
        }
        self.normalizedTarget = target
        if target.hasSuffix("/") {
            self.lastSegment = ""
        } else if let slash = target.lastIndex(of: "/") {
            self.lastSegment = String(target[target.index(after: slash)...])
        } else {
            self.lastSegment = target
        }
    }

    func canMatchWithinSubtree(dirNormalizedPath: String, dirPrefix: String) -> Bool {
        if kind == "marker" && path.hasPrefix("**/") { return true }
        switch kind {
        case "exact":
            return normalizedTarget == dirNormalizedPath || normalizedTarget.hasPrefix(dirPrefix)
        case "prefix":
            return normalizedTarget.hasPrefix(dirPrefix)
                || dirNormalizedPath == normalizedTarget
                || dirNormalizedPath.hasPrefix(normalizedTarget + "/")
        default:
            return true
        }
    }

    func matches(_ raw: String) -> Bool {
        let candidate = SymlinkGuard.canonicalizeMacOSSystemPrefix(
            URL(fileURLWithPath: raw).standardizedFileURL.path
        ).lowercased()
        return matchesNormalizedCandidate(candidate)
    }

    static let sessionAndIMEBoundaryMarkers: Set<String> = [
        "cookies", "login data", "web data", "history", "bookmarks",
        "local storage", "indexeddb", "inputmethod", "input methods", "mail downloads"
    ]

    func matchesNormalizedCandidate(_ candidate: String) -> Bool {
        if kind == "marker" && path.hasPrefix("**/") {
            return candidate.hasSuffix(normalizedTarget) || candidate.contains(normalizedTarget + "/")
        }
        switch kind {
        case "exact": return candidate == normalizedTarget
        case "prefix": return candidate == normalizedTarget || candidate.hasPrefix(normalizedTarget + "/")
        case "suffix": return candidate.hasSuffix(normalizedTarget) || candidate.contains(normalizedTarget + "/")
        case "marker":
            if Self.sessionAndIMEBoundaryMarkers.contains(normalizedTarget) {
                return candidate.hasSuffix("/" + normalizedTarget)
                    || candidate.contains("/" + normalizedTarget + "/")
            }
            return candidate.contains(normalizedTarget)
        default: return true // An unknown protection must never widen deletion scope.
        }
    }
}

/// Immutable after loading. SQL is data: predicates are implemented explicitly, never evaluated as code.
struct AuthoredRules: Sendable {
    var loaded = false
    var catalog = RuleCatalog()
    var protectionsLoaded = false
    var templatesLoaded = false
    var junk: [String: AuthoredJunkRule] = [:]
    var protections: [AuthoredPathProtection] = []
    var mailIDs: [String] = []
    var mailNames: [String] = []
    var sharedVendorNames: Set<String> = []
    var collisionNames: Set<String> = []
    var templates: [AuthoredUninstallTemplate] = []
    var chromiumSubdirs: [String: CleanupTier] = [:]
    var electronDirectories: [String: String] = [:]
    var cacheSubdirs: [String: [String: CleanupTier]] = [:]
    var disabledDiscoveryRules: [AuthoredJunkRule] = []
    var ruleSQLHash: String = ""
    var cacheProfiles: [String: AuthoredCacheProfile] = [:]
    var cacheProfileLocks: [String: [AuthoredCacheProfileLock]] = [:]
    var disabledCacheProfileIDs: Set<String> = []
    var cacheRecommendationConfig: CacheRecommendationConfig = .unavailable

    static func load(_ db: OpaquePointer?) throws -> AuthoredRules {
        func rows(_ sql: String) throws -> [[String]] {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let statement = stmt else {
                throw CocoaError(.fileReadCorruptFile)
            }
            defer { sqlite3_finalize(statement) }
            var result: [[String]] = []
            var step = sqlite3_step(statement)
            while step == SQLITE_ROW {
                result.append((0..<sqlite3_column_count(statement)).map {
                    sqlite3_column_text(statement, $0).map { String(cString: $0) } ?? ""
                })
                step = sqlite3_step(statement)
            }
            guard step == SQLITE_DONE else { throw CocoaError(.fileReadCorruptFile) }
            return result
        }
        func hasTable(_ name: String) throws -> Bool {
            !(try rows("SELECT name FROM sqlite_master WHERE type='table' AND name='\(name)'")).isEmpty
        }

        var snapshot = AuthoredRules()
        snapshot.catalog = try RuleCatalog(database: db)

        // 1. Protected paths are mandatory safety redlines; missing or corrupt table must fail reload.
        for row in try rows("SELECT path_template,match_kind FROM cm_protected_path") {
            guard AppConfig.Security.authoredProtectionKinds.contains(row[1]) else { throw CocoaError(.fileReadCorruptFile) }
            snapshot.protections.append(AuthoredPathProtection(path: row[0], kind: row[1]))
        }
        guard !snapshot.protections.isEmpty else {
            throw CocoaError(.fileReadCorruptFile)
        }
        snapshot.protectionsLoaded = true

        // 2. Shared metadata tables (loaded whenever present).
        if try hasTable("cm_mail_client") {
            for row in try rows("SELECT bundle_id,name FROM cm_mail_client") {
                snapshot.mailIDs.append(row[0].lowercased()); snapshot.mailNames.append(row[1].lowercased())
            }
        }
        if try hasTable("cm_shared_vendor_root") {
            snapshot.sharedVendorNames = Set(try rows("SELECT name FROM cm_shared_vendor_root").map { $0[0].lowercased() })
        }
        if try hasTable("cm_name_collision") {
            snapshot.collisionNames = Set(try rows("SELECT name FROM cm_name_collision").map { $0[0].lowercased() })
        }
        if try hasTable("cm_chromium_profile_subdir") {
            for row in try rows("SELECT name,tier FROM cm_chromium_profile_subdir") {
                guard let tier = CleanupTier(rawValue: row[1]) else { throw CocoaError(.fileReadCorruptFile) }
                snapshot.chromiumSubdirs[row[0]] = tier
            }
        }
        if try hasTable("cm_electron_data_dir") {
            for row in try rows("SELECT bundle_id,dir_name FROM cm_electron_data_dir") {
                snapshot.electronDirectories[row[0]] = row[1]
            }
        }

        // 3. Uninstall templates capability (independent of cm_junk_rule).
        if try hasTable("cm_uninstall_template") {
            for row in try rows("SELECT id,path_template,tier,domain,execute,default_selected FROM cm_uninstall_template WHERE status='active'") {
                guard let tier = CleanupTier(rawValue: row[2]),
                      (row[3] != "system" || row[4] == "0"),
                      (row[0] == "UNINST_01" || row[5] == "0") else { throw CocoaError(.fileReadCorruptFile) }
                snapshot.templates.append(AuthoredUninstallTemplate(id: row[0], path: row[1], tier: tier,
                    domain: row[3], execute: row[4] == "1", selected: row[5] == "1"))
            }
            guard !snapshot.templates.isEmpty else {
                throw CocoaError(.fileReadCorruptFile)
            }
            snapshot.templatesLoaded = true
        }

        var ruleMeta: [String: String] = [:]
        if try hasTable("cm_rule_meta") {
            for row in try rows("SELECT key,value FROM cm_rule_meta") {
                ruleMeta[row[0]] = row[1]
            }
        }
        // Existing cache/evidence keys now bind to the complete database, not a SQL text hash.
        if let filename = sqlite3_db_filename(db, "main") {
            let path = String(cString: filename)
            if !path.isEmpty, let bytes = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                snapshot.ruleSQLHash = RuleDigest.sha256(bytes)
            }
        }
        // 4. Junk rules capability (independent of cm_uninstall_template).
        if try hasTable("cm_junk_rule") {
            for row in try rows("SELECT id,tier,action,status,default_selected,COALESCE(min_age_hours,0),fixture_required,COALESCE(min_bytes,0),COALESCE(predicate,''),reason_code,rebuild_cost,COALESCE(title_key,'') FROM cm_junk_rule") {
                guard let rebuildCost = RebuildCost(rawValue: row[10]) else {
                    throw NSError(
                        domain: NSCocoaErrorDomain,
                        code: NSFileReadCorruptFileError,
                        userInfo: [NSLocalizedDescriptionKey: "invalid_junk_rule_rebuild_cost:\(row[0]):\(row[10])"]
                    )
                }
                guard let tier = CleanupTier(rawValue: row[1]),
                      AppConfig.Security.authoredActions.contains(row[2]),
                      let reason = ReasonCode(rawValue: row[9]),
                      !(row[4] == "1" && (tier != .automatic || row[3] != "active" || row[6] != "0")) else {
                    throw NSError(
                        domain: NSCocoaErrorDomain,
                        code: NSFileReadCorruptFileError,
                        userInfo: [NSLocalizedDescriptionKey: "invalid_junk_rule_definition:\(row[0])"]
                    )
                }
                snapshot.junk[row[0]] = AuthoredJunkRule(id: row[0], tier: tier, action: row[2],
                    active: row[3] == "active" && row[6] == "0", selected: row[4] == "1",
                    minAgeHours: Double(row[5]) ?? 0, minBytes: Int64(row[7]) ?? 0, predicate: row[8], reason: reason, rebuildCost: rebuildCost,
                    titleKey: row.count > 11 ? row[11] : "")
            }
            for row in try rows("SELECT rule_id,path_template FROM cm_discovery_binding WHERE path_template != ''") {
                guard snapshot.junk[row[0]] != nil else { throw CocoaError(.fileReadCorruptFile) }
                snapshot.junk[row[0]]?.paths.append(row[1])
            }
            for row in try rows("SELECT rule_id,name FROM cm_junk_rule_exclude") { snapshot.junk[row[0]]?.excludedNames.append(row[1]) }
            for row in try rows("SELECT rule_id,lock_kind,lock_value FROM cm_junk_rule_lock") {
                if row[1] == "bundle_id" { snapshot.junk[row[0]]?.bundleLocks.append(row[2]) }
                else if row[1] == "process_name" { snapshot.junk[row[0]]?.processLocks.append(row[2]) }
                else { throw CocoaError(.fileReadCorruptFile) }
            }
            for row in try rows("SELECT rule_id,name,tier FROM cm_cache_subdir") {
                guard snapshot.junk[row[0]] != nil, let tier = CleanupTier(rawValue: row[2]),
                      tier == .automatic || tier == .review,
                      !row[1].isEmpty, !row[1].hasPrefix("/"), !row[1].split(separator: "/").contains("..") else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                snapshot.cacheSubdirs[row[0], default: [:]][row[1]] = tier
            }
            guard !snapshot.junk.isEmpty else {
                throw CocoaError(.fileReadCorruptFile)
            }
            let electronMap = snapshot.electronDirectories
            for key in Array(snapshot.junk.keys) {
                snapshot.junk[key]?.compilePatterns(electronDirectories: electronMap)
            }
            for key in snapshot.junk.keys.sorted() {
                guard var disabled = snapshot.junk[key], disabled.tier.executable else { continue }
                disabled.paths = snapshot.catalog.bindings.filter { $0.ruleID == key && $0.status != .active && !$0.pathTemplate.isEmpty }.map(\.pathTemplate)
                guard !disabled.paths.isEmpty else { continue }
                disabled.compilePatterns(electronDirectories: electronMap)
                snapshot.disabledDiscoveryRules.append(disabled)
            }
            snapshot.loaded = true

            // 5. T12-A: Load & validate cm_cache_profile, cm_cache_profile_lock, and recommendation metadata.
            // Missing tables, unsupported version, invalid thresholds, or corrupt profile rows disable cache recommendation without breaking base rule safety gates.
            snapshot.loadCacheProfiles(rows: rows, hasTable: hasTable, ruleMeta: ruleMeta)
        }
        return snapshot
    }

    mutating func loadCacheProfiles(
        rows: (String) throws -> [[String]],
        hasTable: (String) throws -> Bool,
        ruleMeta: [String: String]
    ) {
        func disableWithReason(_ reason: String) {
            self.cacheProfiles = [:]
            self.cacheProfileLocks = [:]
            self.disabledCacheProfileIDs = []
            self.cacheRecommendationConfig = CacheRecommendationConfig(
                isAvailable: false,
                schemaVersion: ruleMeta["schema_version"] ?? "",
                policyVersion: ruleMeta["schema_version"] ?? "",
                appSuggestionBytes: 0,
                developerSuggestionBytes: 0,
                ageSuggestionEnabled: false,
                unavailableReason: reason
            )
        }

        do {
            guard try hasTable("cm_cache_profile"), try hasTable("cm_cache_profile_lock") else {
                disableWithReason("missing_cache_profile_tables")
                return
            }
            guard let schemaVer = ruleMeta["schema_version"], schemaVer == "1",
                  let policyVer = ruleMeta["schema_version"], policyVer == "1",
                  let ageFlag = ruleMeta["cache_age_suggestion_enabled"], ageFlag == "0",
                  let appBytesRaw = ruleMeta["cache_app_suggestion_bytes"],
                  let appBytes = Int64(appBytesRaw), appBytes > 0,
                  let devBytesRaw = ruleMeta["cache_developer_suggestion_bytes"],
                  let devBytes = Int64(devBytesRaw), devBytes > 0 else {
                disableWithReason("invalid_cache_recommendation_meta")
                return
            }

            let profileRows = try rows("SELECT id,rule_id,root_template,discovery_kind,cache_class,rebuild_effect,cost_override FROM cm_cache_profile")
            guard !profileRows.isEmpty else {
                disableWithReason("empty_cache_profiles")
                return
            }

            var loadedProfiles: [String: AuthoredCacheProfile] = [:]
            var uniqueTriplets = Set<String>()
            for row in profileRows {
                guard row.count == 7 else {
                    disableWithReason("malformed_cache_profile_row")
                    return
                }
                let id = row[0]
                let ruleID = row[1]
                let rootTemplate = row[2]
                guard !id.isEmpty,
                      loadedProfiles[id] == nil,
                      let matchedRule = self.junk[ruleID],
                      matchedRule.active,
                      matchedRule.tier.executable,
                      !rootTemplate.isEmpty,
                      !rootTemplate.contains("\0"),
                      !rootTemplate.split(separator: "/").contains(".."),
                      (rootTemplate.hasPrefix("~/") || rootTemplate.hasPrefix("/")),
                      let discoveryKind = CacheDiscoveryKind(rawValue: row[3]),
                      let cacheClass = CacheClass(rawValue: row[4]),
                      let rebuildEffect = CacheRebuildEffect(rawValue: row[5]),
                      let costOverride = RebuildCost(rawValue: row[6]) else {
                    disableWithReason("invalid_cache_profile_definition:\(row[0])")
                    return
                }
                let tripletKey = "\(ruleID)|\(rootTemplate)|\(discoveryKind.rawValue)"
                guard !uniqueTriplets.contains(tripletKey) else {
                    disableWithReason("duplicate_cache_profile_triplet:\(tripletKey)")
                    return
                }
                uniqueTriplets.insert(tripletKey)
                loadedProfiles[id] = AuthoredCacheProfile(
                    id: id,
                    ruleID: ruleID,
                    rootTemplate: rootTemplate,
                    discoveryKind: discoveryKind,
                    cacheClass: cacheClass,
                    rebuildEffect: rebuildEffect,
                    costOverride: costOverride
                )
            }

            let lockRows = try rows("SELECT profile_id,lock_kind,lock_value FROM cm_cache_profile_lock")
            var loadedLocks: [String: [AuthoredCacheProfileLock]] = [:]
            var seenLockKeys = Set<String>()
            for row in lockRows {
                guard row.count == 3 else {
                    disableWithReason("malformed_cache_profile_lock_row")
                    return
                }
                let profileID = row[0]
                let lockValue = row[2]
                guard loadedProfiles[profileID] != nil,
                      let lockKind = CacheProfileLockKind(rawValue: row[1]),
                      !lockValue.isEmpty else {
                    disableWithReason("invalid_cache_profile_lock:\(row[0])")
                    return
                }
                if lockKind == .processFamily && lockValue != "python3Versioned" {
                    disableWithReason("unsupported_process_family:\(lockValue)")
                    return
                }
                let lockKey = "\(profileID)|\(lockKind.rawValue)|\(lockValue)"
                guard !seenLockKeys.contains(lockKey) else {
                    disableWithReason("duplicate_cache_profile_lock:\(lockKey)")
                    return
                }
                seenLockKeys.insert(lockKey)
                loadedLocks[profileID, default: []].append(
                    AuthoredCacheProfileLock(profileID: profileID, lockKind: lockKind, lockValue: lockValue)
                )
            }

            // Cross-check electron_leaves profiles against cm_electron_data_dir:
            // Conflicting profiles are deactivated without guessing similar names.
            var disabledIDs = Set<String>()
            for profile in loadedProfiles.values {
                let pLocks = loadedLocks[profile.id] ?? []
                if pLocks.isEmpty && !self.catalog.values("cm_version_cache", "rule_id").contains(profile.ruleID) {
                    disabledIDs.insert(profile.id)
                    continue
                }
                if profile.discoveryKind == .electronLeaves {
                    let dirName = (profile.rootTemplate as NSString).lastPathComponent
                    guard profile.id == "electron-" + dirName else {
                        disabledIDs.insert(profile.id)
                        continue
                    }
                    let bundleLocks = pLocks.filter { $0.lockKind == .bundleID }.map(\.lockValue)
                    let hasMatchingElectronMapping = bundleLocks.contains { bid in
                        self.electronDirectories[bid] == dirName
                    }
                    let hasConflictingElectronMapping = bundleLocks.contains { bid in
                        if let mappedDir = self.electronDirectories[bid], mappedDir != dirName {
                            return true
                        }
                        return false
                    }
                    if !hasMatchingElectronMapping || hasConflictingElectronMapping {
                        disabledIDs.insert(profile.id)
                    }
                }
            }

            self.cacheProfiles = loadedProfiles
            self.cacheProfileLocks = loadedLocks
            self.disabledCacheProfileIDs = disabledIDs
            self.cacheRecommendationConfig = CacheRecommendationConfig(
                isAvailable: true,
                schemaVersion: schemaVer,
                policyVersion: policyVer,
                appSuggestionBytes: appBytes,
                developerSuggestionBytes: devBytes,
                ageSuggestionEnabled: false,
                unavailableReason: nil
            )
        } catch {
            disableWithReason("cache_profile_query_failed")
        }
    }

    func effectiveRebuildCost(for profile: AuthoredCacheProfile) -> RebuildCost? {
        guard let rule = junk[profile.ruleID] else { return nil }
        return max(rule.rebuildCost, profile.costOverride)
    }

}
