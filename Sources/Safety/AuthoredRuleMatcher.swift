import Foundation

extension AuthoredRules {
    static func normalizeRuleMatchPath(_ url: URL) -> String {
        SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path).lowercased()
    }

    func isProtected(
        _ path: String,
        allowWholeBundle: Bool = false,
        allowLproj: Bool = false,
        allowAppInterior: Bool = false
    ) -> Bool {
        let candidate = SymlinkGuard.canonicalizeMacOSSystemPrefix(
            URL(fileURLWithPath: path).standardizedFileURL.path
        ).lowercased()
        return isProtectedNormalized(
            candidate,
            allowWholeBundle: allowWholeBundle,
            allowLproj: allowLproj,
            allowAppInterior: allowAppInterior
        )
    }

    func isProtectedNormalized(
        _ candidate: String,
        allowWholeBundle: Bool = false,
        allowLproj: Bool = false,
        allowAppInterior: Bool = false
    ) -> Bool {
        return protections.contains { prot in
            if (allowWholeBundle || allowAppInterior) && AppConfig.RuleIDs.bundleInteriorProtectionPaths.contains(prot.path) {
                return false
            }
            if allowLproj && prot.path == ".lproj" {
                return false
            }
            return prot.matchesNormalizedCandidate(candidate)
        }
    }

    func disabledDiscoveryRule(normalizedPath: String) -> AuthoredJunkRule? {
        if let blocked = disabledDiscoveryRules.first(where: { matchesNormalizedPath(normalizedPath, rule: $0) }) { return blocked }
        for id in RuleTaskGate.shared.disabledIDs.sorted() {
            if let rule = junk[id], matchesNormalizedPath(normalizedPath, rule: rule) { return rule }
        }
        return nil
    }

    func matches(_ url: URL, rule: AuthoredJunkRule) -> Bool {
        let path = Self.normalizeRuleMatchPath(url)
        return matchesNormalizedPath(path, rule: rule)
    }

    func matchesNormalizedPath(_ path: String, rule: AuthoredJunkRule) -> Bool {
        if rule.id == "JC.DEV.PROJECT" {
            let comps = path.split(separator: "/").map(String.init)
            guard !comps.contains("library") else { return false }
            let lowerArtifacts = Set(ProjectPurgeEngine.targetArtifactNames.map { $0.lowercased() })
            return comps.contains(where: { lowerArtifacts.contains($0) })
        }
        if !rule.compiledPatterns.isEmpty || rule.paths.isEmpty {
            for pattern in rule.compiledPatterns {
                if pattern.isGlob {
                    guard path.hasPrefix(pattern.staticPrefixBeforeWildcard) else { continue }
                    let suffix = pattern.literalSuffixAfterLastWildcard
                    if !suffix.isEmpty {
                        guard path.hasSuffix(suffix) || path.contains(suffix + "/") else { continue }
                    }
                    var candidate = path
                    let minLen = pattern.root.count - pattern.wildcardCount
                    while candidate.count >= minLen {
                        if fnmatch(pattern.root, candidate, FNM_PATHNAME) == 0 { return true }
                        guard let slash = candidate.lastIndex(of: "/"), slash > candidate.startIndex else { break }
                        candidate = String(candidate[..<slash])
                    }
                } else if path == pattern.root || path.hasPrefix(pattern.root + "/") {
                    return true
                }
            }
            return false
        }
        return rule.paths.contains { raw in
            let expanded: [String]
            if raw.contains("{electronDataDir}") && !raw.contains("{bundleID}") {
                expanded = electronDirectories.values.map { raw.replacingOccurrences(of: "{electronDataDir}", with: $0) }
            } else { expanded = [raw] }
            return expanded.contains { raw in
                guard !raw.contains("{") else { return false }
                let root = SymlinkGuard.canonicalizeMacOSSystemPrefix(URL(fileURLWithPath: KBPaths.expand(raw)).standardizedFileURL.path).lowercased()
                if raw.contains("*") {
                    var candidate = path
                    while candidate.count >= root.count - raw.filter({ $0 == "*" }).count {
                        if fnmatch(root, candidate, FNM_PATHNAME) == 0 { return true }
                        let parent = (candidate as NSString).deletingLastPathComponent
                        if parent == candidate || parent == "/" { break }
                        candidate = parent
                    }
                    return false
                }
                return path == root || path.hasPrefix(root + "/")
            }
        }
    }

    func isExcluded(_ url: URL, by rule: AuthoredJunkRule) -> Bool {
        let path = Self.normalizeRuleMatchPath(url)
        return isExcludedNormalizedPath(path, lastComponentLower: url.lastPathComponent.lowercased(), by: rule)
    }

    func isExcludedNormalizedPath(_ path: String, lastComponentLower: String, by rule: AuthoredJunkRule) -> Bool {
        if !rule.compiledExcluded.isEmpty || rule.excludedNames.isEmpty {
            return rule.compiledExcluded.contains { item in
                let excluded = item.expanded
                return path == excluded
                    || path.contains("/" + excluded + "/")
                    || path.hasSuffix("/" + excluded)
                    || lastComponentLower.hasPrefix(item.rawLower)
            }
        }
        return rule.excludedNames.contains { name in
            let excluded = KBPaths.expand(name).lowercased()
            return path == excluded || path.contains("/" + excluded + "/") || path.hasSuffix("/" + excluded)
                || lastComponentLower.hasPrefix(name.lowercased())
        }
    }

    /// 校验 JetBrains 路径是否严格满足 ~/Library/Caches/JetBrains/<受限版本名>/{caches,index,log,jcef_cache,tmp,compile-server}（大小写敏感）
    static func isValidJetBrainsLeafOrDescendant(_ url: URL) -> Bool {
        let components = url.standardizedFileURL.pathComponents
        guard components.count >= 5 else { return false }
        for i in 0..<(components.count - 4) {
            if components[i] == "Library"
                && components[i + 1] == "Caches"
                && components[i + 2] == "JetBrains" {
                let versionName = components[i + 3]
                let leafName = components[i + 4]
                guard AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(
                    versionName,
                    pattern: AppConfig.JunkScan.PathMatching.jetBrainsVersionName
                ), AppConfig.JunkScan.jetBrainsAllowedLeavesSet.contains(leafName) else {
                    return false
                }
                let prefixComponents = Array(components[0...(i + 1)])
                let cachesPath = NSString.path(withComponents: prefixComponents)
                if let entries = try? FileManager.default.contentsOfDirectory(atPath: cachesPath),
                   !entries.contains("JetBrains") {
                    return false
                }
                let jbPath = (cachesPath as NSString).appendingPathComponent("JetBrains")
                if let verEntries = try? FileManager.default.contentsOfDirectory(atPath: jbPath),
                   !verEntries.contains(versionName) {
                    return false
                }
                let verPath = (jbPath as NSString).appendingPathComponent(versionName)
                if let leafEntries = try? FileManager.default.contentsOfDirectory(atPath: verPath),
                   !leafEntries.contains(leafName) {
                    return false
                }
                return true
            }
        }
        return false
    }

    static func hasExactOnDiskCase(_ url: URL, relativeTo baseURL: URL? = nil) -> Bool {
        let stdURL = url.standardizedFileURL
        let fd = open(stdURL.path, O_RDONLY | O_SYMLINK)
        guard fd >= 0 else { return false }
        defer { close(fd) }
        var buf = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        guard fcntl(fd, F_GETPATH, &buf) != -1 else { return false }
        let rawPath = String(decoding: buf.prefix(while: { $0 != 0 }).map(UInt8.init(bitPattern:)), as: UTF8.self)
        let actualPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(rawPath)
        let expectedPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(stdURL.path)
        if let baseURL {
            let baseStd = SymlinkGuard.canonicalizeMacOSSystemPrefix(baseURL.standardizedFileURL.path)
            if actualPath.lowercased().hasPrefix(baseStd.lowercased() + "/"),
               expectedPath.lowercased().hasPrefix(baseStd.lowercased() + "/") {
                let actualRel = String(actualPath.dropFirst(baseStd.count + 1))
                let expectedRel = String(expectedPath.dropFirst(baseStd.count + 1))
                return actualRel == expectedRel
            }
        }
        return (actualPath as NSString).lastPathComponent == (expectedPath as NSString).lastPathComponent
    }

    /// 校验 Firefox 路径是否严格满足 ~/Library/Caches/Firefox/Profiles/<受限Profile名>/{cache2,startupCache}
    static func isValidFirefoxLeafOrDescendant(_ url: URL) -> Bool {
        let components = url.standardizedFileURL.pathComponents
        guard components.count >= 6 else { return false }
        for i in 0..<(components.count - 5) {
            if components[i] == "Library"
                && components[i + 1] == "Caches"
                && components[i + 2] == "Firefox"
                && components[i + 3] == "Profiles" {
                let profileName = components[i + 4]
                let leafName = components[i + 5]
                guard AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(
                    profileName,
                    pattern: AppConfig.JunkScan.PathMatching.firefoxProfileName
                ), AppConfig.JunkScan.PathMatching.firefoxAllowedLeaves.contains(leafName) else {
                    return false
                }
                let prefixComponents = Array(components[0...(i + 5)])
                let leafURL = NSURL.fileURL(withPathComponents: prefixComponents) ?? url
                if FileUtil.exists(leafURL.path) {
                    let firefoxRoot = leafURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                    if !hasExactOnDiskCase(leafURL, relativeTo: firefoxRoot.deletingLastPathComponent()) {
                        return false
                    }
                }
                return true
            }
        }
        return false
    }

    static func isValidJetBrainsLeafOrDescendantNormalizedPath(_ path: String) -> Bool {
        guard let markerRange = path.range(of: "/library/caches/jetbrains/") else { return false }
        let remainder = path[markerRange.upperBound...]
        let parts = remainder.split(separator: "/", maxSplits: 2, omittingEmptySubsequences: true)
        guard parts.count >= 2 else { return false }
        let versionName = String(parts[0])
        let leafName = String(parts[1])
        guard !versionName.isEmpty,
              let regex = try? NSRegularExpression(
                  pattern: AppConfig.JunkScan.PathMatching.jetBrainsVersionName,
                  options: [.caseInsensitive]
              ) else {
            return false
        }
        let range = NSRange(versionName.startIndex..<versionName.endIndex, in: versionName)
        guard let match = regex.firstMatch(in: versionName, options: [], range: range),
              match.range == range else {
            return false
        }
        return AppConfig.JunkScan.jetBrainsAllowedLeavesSet.contains(leafName)
    }

    func isRuleExcluded(_ url: URL) -> Bool {
        if Self.isValidJetBrainsLeafOrDescendant(url) {
            let path = Self.normalizeRuleMatchPath(url)
            let lastLower = url.lastPathComponent.lowercased()
            if let jbRule = junk[AppConfig.RuleIDs.jetBrainsCache],
               jbRule.active,
               !isExcludedNormalizedPath(path, lastComponentLower: lastLower, by: jbRule) {
                return false
            }
        }
        let path = Self.normalizeRuleMatchPath(url)
        let lastLower = url.lastPathComponent.lowercased()
        return isRuleExcludedNormalized(path, lastComponentLower: lastLower, originalURL: url)
    }

    func isRuleExcludedNormalized(_ path: String, lastComponentLower: String, originalURL: URL? = nil) -> Bool {
        return junk.values.contains { rule in
            guard !rule.excludedNames.isEmpty,
                  isExcludedNormalizedPath(path, lastComponentLower: lastComponentLower, by: rule),
                  matchesNormalizedPath(path, rule: rule) else {
                return false
            }
            let ruleSpec = matchingPathLengthNormalizedPath(path, rule: rule)
            let overriddenByMoreSpecificRule = junk.values.contains { specific in
                guard specific.active, specific.id != rule.id else { return false }
                guard matchesNormalizedPath(path, rule: specific),
                      !isExcludedNormalizedPath(path, lastComponentLower: lastComponentLower, by: specific) else {
                    return false
                }
                if specific.id == AppConfig.RuleIDs.jetBrainsCache {
                    let isValidJB = originalURL.map(Self.isValidJetBrainsLeafOrDescendant)
                        ?? Self.isValidJetBrainsLeafOrDescendantNormalizedPath(path)
                    if !isValidJB { return false }
                }
                return matchingPathLengthNormalizedPath(path, rule: specific) > ruleSpec
            }
            return !overriddenByMoreSpecificRule
        }
    }

    func matchingPathLength(_ url: URL, rule: AuthoredJunkRule) -> Int {
        let path = Self.normalizeRuleMatchPath(url)
        return matchingPathLengthNormalizedPath(path, rule: rule)
    }

    func matchingPathLengthNormalizedPath(_ path: String, rule: AuthoredJunkRule) -> Int {
        if rule.id == "JC.DEV.PROJECT" {
            return matchesNormalizedPath(path, rule: rule) ? 1 : 0
        }
        var best = 0
        if !rule.compiledPatterns.isEmpty || rule.paths.isEmpty {
            for pattern in rule.compiledPatterns {
                if pattern.isGlob {
                    guard pattern.staticSpecificity > best else { continue }
                    guard path.hasPrefix(pattern.staticPrefixBeforeWildcard) else { continue }
                    let suffix = pattern.literalSuffixAfterLastWildcard
                    if !suffix.isEmpty {
                        guard path.hasSuffix(suffix) || path.contains(suffix + "/") else { continue }
                    }
                    var current = path
                    let minLen = max(1, pattern.root.count - pattern.wildcardCount)
                    while current.count >= minLen {
                        if fnmatch(pattern.root, current, FNM_PATHNAME) == 0 {
                            if pattern.staticSpecificity > best { best = pattern.staticSpecificity }
                            break
                        }
                        guard let slash = current.lastIndex(of: "/"), slash > current.startIndex else { break }
                        current = String(current[..<slash])
                    }
                } else if path == pattern.root || path.hasPrefix(pattern.root + "/") {
                    if pattern.staticSpecificity > best { best = pattern.staticSpecificity }
                }
            }
            return best
        }
        for raw in rule.paths {
            let isPlaceholder = raw.contains("{electronDataDir}") && !raw.contains("{bundleID}")
            let expanded: [String]
            if isPlaceholder {
                expanded = electronDirectories.values.map { raw.replacingOccurrences(of: "{electronDataDir}", with: $0) }
            } else { expanded = [raw] }
            for cand in expanded where !cand.contains("{") {
                let root = SymlinkGuard.canonicalizeMacOSSystemPrefix(URL(fileURLWithPath: KBPaths.expand(cand)).standardizedFileURL.path).lowercased()
                if cand.contains("*") {
                    var current = path
                    let minLen = max(1, root.count - cand.filter({ $0 == "*" }).count)
                    while current.count >= minLen {
                        if fnmatch(root, current, FNM_PATHNAME) == 0 {
                            let baseSpec = root.replacingOccurrences(of: "*", with: "").count
                            let specificity = isPlaceholder ? max(1, baseSpec - 1) : baseSpec
                            if specificity > best { best = specificity }
                            break
                        }
                        let parent = (current as NSString).deletingLastPathComponent
                        if parent == current || parent == "/" { break }
                        current = parent
                    }
                } else if path == root || path.hasPrefix(root + "/") {
                    let specificity = isPlaceholder ? max(1, root.count - 1) : root.count
                    if specificity > best { best = specificity }
                }
            }
        }
        return best
    }

    func directoryContainsOnlyEligibleLogFiles(_ directoryURL: URL) -> Bool {
        autoreleasepool {
            guard !IOScanContext.isCancelled,
                  !SymlinkGuard.hasSymlinkEscape(url: directoryURL),
                  !SymlinkGuard.isSymbolicLink(at: directoryURL) else {
                return false
            }
            var complete = true
            let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey]
            guard let enumerator = FileManager.default.enumerator(
                at: directoryURL,
                includingPropertiesForKeys: keys,
                options: [],
                errorHandler: { url, error in
                    IOScanContext.record(error, path: url.path)
                    complete = false
                    return !IOScanContext.isCancelled
                }
            ) else {
                return false
            }
            let deadline = ProcessInfo.processInfo.systemUptime + AppConfig.Security.cleanupInspectionTimeout
            let maxEntries = AppConfig.Security.cleanupInspectionMaxItems
            var inspectedEntries = 0
            var foundLogLeaf = false
            for case let entryURL as URL in enumerator {
                inspectedEntries += 1
                if IOScanContext.isCancelled
                    || inspectedEntries > maxEntries
                    || (inspectedEntries & 0x3F == 0 && ProcessInfo.processInfo.systemUptime > deadline) {
                    return false
                }
                if SymlinkGuard.isSymbolicLink(at: entryURL) || SymlinkGuard.hasSymlinkEscape(url: entryURL) {
                    return false
                }
                guard let identity = FileIdentity.capture(from: entryURL) else {
                    return false
                }
                if identity.isDirectory {
                    continue
                }
                let isRegularFile = (identity.mode & S_IFMT) == S_IFREG
                guard isRegularFile else {
                    return false
                }
                let ext = entryURL.pathExtension.lowercased()
                guard AppConfig.Remediation.logExtensions.contains(ext) else {
                    return false
                }
                foundLogLeaf = true
            }
            return complete && foundLogLeaf
        }
    }

    func isLogRuleEligible(_ url: URL, ruleID: String) -> Bool {
        guard AppConfig.RuleIDs.logRules.contains(ruleID) else { return true }
        guard let identity = FileIdentity.capture(from: url) else { return false }
        if identity.isDirectory {
            return directoryContainsOnlyEligibleLogFiles(url)
        }
        let isRegularFile = (identity.mode & S_IFMT) == S_IFREG
        guard isRegularFile else { return false }
        return AppConfig.Remediation.logExtensions.contains(url.pathExtension.lowercased())
    }

    /// 规则角色声明（F06：明确区分清理目标、上下文保护与原生专用动作）
    enum RuleRole: String, Equatable {
        case cleanupTarget = "cleanup_target"
        case contextualProtection = "contextual_protection"
        case nativeAction = "native_action"
    }

    static func ruleRole(for rule: AuthoredJunkRule) -> RuleRole {
        if rule.action == "native" {
            return .nativeAction
        }
        if rule.action == "read_only" || rule.tier == .readOnly || rule.tier == .forbidden {
            return .contextualProtection
        }
        return .cleanupTarget
    }

    /// 规则生命周期五态审计结构（Section 5 P2-01 / P2-02 & F06：明确区分角色、已定义、已发现、已实现判断、可执行、可自动推荐）
    struct RuleStatusAudit: Equatable {
        let ruleID: String
        let role: RuleRole
        let isDefined: Bool
        let hasScanEntry: Bool
        let isPredicateImplemented: Bool
        let isExecutable: Bool
        let isAutoRecommendable: Bool

        init(
            ruleID: String,
            role: RuleRole = .cleanupTarget,
            isDefined: Bool,
            hasScanEntry: Bool,
            isPredicateImplemented: Bool,
            isExecutable: Bool,
            isAutoRecommendable: Bool
        ) {
            self.ruleID = ruleID
            self.role = role
            self.isDefined = isDefined
            self.hasScanEntry = hasScanEntry
            self.isPredicateImplemented = isPredicateImplemented
            self.isExecutable = isExecutable
            self.isAutoRecommendable = isAutoRecommendable
        }
    }

    static let scannedCacheSubdirRuleIDs: Set<String> = [
        AppConfig.RuleIDs.electronCache,
        AppConfig.RuleIDs.aiIDECache,
        AppConfig.RuleIDs.chromiumCache,
        AppConfig.RuleIDs.arcCache
    ]

    static func canonicalRulePathTemplate(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let home = FileUtil.home.path
        if trimmed.hasPrefix(home + "/") {
            return "~/" + trimmed.dropFirst(home.count + 1)
        }
        if let range = trimmed.range(of: "/home/") {
            let suffix = String(trimmed[range.upperBound...])
            if suffix.hasPrefix("Library/")
                || suffix.hasPrefix("Desktop")
                || suffix.hasPrefix("Downloads")
                || suffix.hasPrefix("Movies/")
                || suffix.hasPrefix(".") {
                return "~/" + suffix
            }
        }
        return trimmed
    }

    static func isProtectedSystemOrCacheRoot(_ url: URL) -> Bool {
        let std = url.standardizedFileURL.path
        let trimmed = (std.count > 1 && std.hasSuffix("/")) ? String(std.dropLast()) : std
        let lower = trimmed.lowercased()
        let canonicalLower = SymlinkGuard.canonicalizeMacOSSystemPrefix(trimmed).lowercased()

        let darwinTmp = KBPaths.darwinUserTempDir.lowercased()
        let darwinTmpCanon = SymlinkGuard.canonicalizeMacOSSystemPrefix(KBPaths.darwinUserTempDir).lowercased()
        let darwinCache = KBPaths.darwinUserCacheDir.lowercased()
        let darwinCacheCanon = SymlinkGuard.canonicalizeMacOSSystemPrefix(KBPaths.darwinUserCacheDir).lowercased()
        let homeCaches = FileUtil.home.appendingPathComponent("Library/Caches").standardizedFileURL.path.lowercased()
        let homeLogs = FileUtil.home.appendingPathComponent("Library/Logs").standardizedFileURL.path.lowercased()

        let exactForbiddenRoots: Set<String> = [
            darwinTmp, darwinTmpCanon,
            darwinCache, darwinCacheCanon,
            homeCaches, homeLogs,
            "/tmp", "/private/tmp",
            "/var/tmp", "/private/var/tmp",
            "/library/caches", "/library/logs"
        ]
        if exactForbiddenRoots.contains(lower) || exactForbiddenRoots.contains(canonicalLower) {
            return true
        }
        // Also protect remapped fixture ~/Library/Caches or ~/Library/Logs roots in tests
        if lower.hasSuffix("/library/caches") || lower.hasSuffix("/library/logs") {
            let parent = (lower as NSString).deletingLastPathComponent
            if !parent.contains("/containers/") && !parent.contains("/group containers/") {
                return true
            }
        }
        let store = KnowledgeBaseManager.shared.authored
        if store.loaded {
            let norm = Self.normalizeRuleMatchPath(url)
            for rid in AppConfig.RuleIDs.rootOnlyContainerRules {
                if let r = store.junk[rid], store.isExactRuleRoot(normalizedPath: norm, rule: r) {
                    return true
                }
            }
        }
        return false
    }

    /// 判定 normalizedPath 是否精确等于某条规则的根路径（而非其严格子项）
    func isExactRuleRoot(normalizedPath: String, rule: AuthoredJunkRule) -> Bool {
        if !rule.compiledPatterns.isEmpty || rule.paths.isEmpty {
            for pattern in rule.compiledPatterns {
                if pattern.isGlob {
                    if fnmatch(pattern.root, normalizedPath, FNM_PATHNAME) == 0 {
                        return true
                    }
                } else if normalizedPath == pattern.root {
                    return true
                }
            }
            return false
        }
        for raw in rule.paths where !raw.contains("{") {
            let root = SymlinkGuard.canonicalizeMacOSSystemPrefix(
                URL(fileURLWithPath: KBPaths.expand(raw)).standardizedFileURL.path
            ).lowercased()
            if raw.contains("*") {
                if fnmatch(root, normalizedPath, FNM_PATHNAME) == 0 { return true }
            } else if normalizedPath == root {
                return true
            }
        }
        return false
    }

    /// 判定目标目录是否为需要展开子项的保壳容器根（对 rootOnlyContainerRules 仅根路径本身为容器壳，其直接子项作为独立单元清理）
    func isContainerRootTarget(_ url: URL, ruleID: String) -> Bool {
        guard let rule = junk[ruleID], rule.action == "trash_children_only" else { return false }
        if AppConfig.RuleIDs.rootOnlyContainerRules.contains(rule.id) {
            let normalizedPath = Self.normalizeRuleMatchPath(url)
            return isExactRuleRoot(normalizedPath: normalizedPath, rule: rule)
        }
        return true
    }

    /// Gate 2: 从 ~/Library/Caches/<childName>/... 中提取直接子项名称
    static func extractUserCacheChildName(for url: URL) -> String? {
        let components = url.standardizedFileURL.pathComponents
        for i in 0..<components.count {
            if components[i].lowercased() == "caches",
               i > 0,
               components[i - 1].lowercased() == "library",
               (i < 2 || components[i - 2].lowercased() != "data") {
                if i + 1 < components.count {
                    return components[i + 1]
                }
                return nil
            }
        }
        return nil
    }

    /// Gate 2: 检查 ~/Library/Caches/<childName> 对应的宿主应用或进程是否正在运行
    static func isUserCacheChildAppRunning(_ childName: String, url: URL) -> Bool {
        if ProcessGuard.isAppRunning(bundleID: childName) { return true }
        if ProcessGuard.isAppRunning(named: childName) { return true }
        if ProcessGuard.isProcessRunning(executableName: childName) { return true }
        if ProcessGuard.shouldSkipDueToRunningProcess(path: url.path).skip { return true }
        return false
    }

    /// Gate 2: 从 ~/Library/Containers/<bundleID>/Data/Library/Caches 或 ~/Library/Group Containers/<groupID>/Library/Caches 提取宿主标识
    static func extractContainerBundleID(for url: URL) -> String? {
        let components = url.standardizedFileURL.pathComponents
        for i in 0..<components.count {
            let low = components[i].lowercased()
            if (low == "containers" || low == "group containers"), i + 1 < components.count {
                return components[i + 1]
            }
        }
        return nil
    }

    static func isContainerCacheHostRunning(for url: URL) -> Bool {
        if let bid = extractContainerBundleID(for: url) {
            if ProcessGuard.isAppRunning(bundleID: bid) { return true }
            let parts = bid.split(separator: ".", maxSplits: 1)
            if parts.count == 2 && parts[0].count == 10 {
                let stripped = String(parts[1])
                if ProcessGuard.isAppRunning(bundleID: stripped) { return true }
            }
        }
        return ProcessGuard.shouldSkipDueToRunningProcess(path: url.path).skip
    }

    /// Gate 5: 校验 .plist 文件是否真正损坏且对应应用未运行
    static func isBrokenPlistEligible(_ url: URL) -> (eligible: Bool, runningLocked: Bool) {
        guard url.pathExtension.lowercased() == "plist" else { return (false, false) }
        let fileName = url.lastPathComponent
        if fileName.lowercased().hasPrefix("com.apple.") { return (false, false) }
        let rawStem = url.deletingPathExtension().lastPathComponent
        // Strip ByHost UUID suffix if present (e.g. com.foo.bar.<UUID>.plist)
        let bundleID: String = {
            let parts = rawStem.split(separator: ".")
            if parts.count >= 3, let last = parts.last, last.count >= 12 && last.contains("-") {
                return parts.dropLast().joined(separator: ".")
            }
            return rawStem
        }()
        if ProcessGuard.isAppRunning(bundleID: bundleID)
            || ProcessGuard.isAppRunning(named: bundleID)
            || ProcessGuard.shouldSkipDueToRunningProcess(path: url.path).skip {
            return (false, true)
        }
        guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]) else {
            return (false, false)
        }
        if data.isEmpty {
            return (true, false)
        }
        do {
            _ = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            return (false, false)
        } catch {
            return (true, false)
        }
    }

    /// 核验扫描器流水线是否具备发现该规则目标深度候选的真实扫描入口 (Section 5 P2-01 & F06 & T07 路径级全量校验)
    func hasScannerEntryCoverage(for rule: AuthoredJunkRule) -> Bool {
        if AppConfig.JunkScan.versionCacheRuleIDs.contains(rule.id) {
            let roots = rule.id == "JC.DEV.BROWSER.DOWNLOAD"
                ? AppConfig.JunkScan.browserDownloadRoots
                : AppConfig.JunkScan.agentVersionRoots.map(\.root)
            let executedPaths = Set(roots.map { Self.canonicalRulePathTemplate($0 + "/*") })
            return !rule.paths.isEmpty && rule.paths.allSatisfy { executedPaths.contains(Self.canonicalRulePathTemplate($0)) }
        }
        if AppConfig.JunkScan.reviewedProfileRuleIDs.contains(rule.id) {
            let profiles = cacheProfiles.values.filter { $0.ruleID == rule.id }
            return !profiles.isEmpty && rule.paths.allSatisfy { path in
                profiles.contains { profile in
                    let canonical = Self.canonicalRulePathTemplate(path)
                    let root = Self.canonicalRulePathTemplate(profile.rootTemplate)
                    return root == canonical || (profile.discoveryKind == .chromiumLeaves
                        && AppConfig.JunkScan.PathMatching.chromiumAllowedLeaves.contains { canonical == root + "/*/" + $0 })
                }
            }
        }
        if rule.id == "JC.DEV.PROJECT" {
            return catalog.binding(ruleID: rule.id, path: "")?.status == .active
        }
        let validTemplates = rule.paths
            .map(Self.canonicalRulePathTemplate)
            .filter { !$0.isEmpty }
        guard !validTemplates.isEmpty else { return false }

        if AppConfig.RuleIDs.cacheSubdirRules.contains(rule.id) {
            guard Self.scannedCacheSubdirRuleIDs.contains(rule.id),
                  !(cacheSubdirs[rule.id] ?? [:]).isEmpty else {
                return false
            }
            return true
        }

        let exactTemplates = Set(catalog.bindings.filter { $0.status == .active }.map { Self.canonicalRulePathTemplate($0.pathTemplate) })
        func isSingleTemplateCovered(_ template: String) -> Bool {
            if let binding = catalog.binding(ruleID: rule.id, path: template),
               binding.status == .inventoryOnly || binding.status == .deferred || binding.status == .rejected {
                return false
            }
            if exactTemplates.contains(template) {
                return true
            }
            // JunkEngine.scanUserCaches 枚举 ~/Library/Caches 的直接子项（深度 1，不含深层子路径或通配符）
            if template.hasPrefix("~/Library/Caches/") {
                let rel = String(template.dropFirst("~/Library/Caches/".count))
                if !rel.isEmpty && !rel.contains("/") && !rel.contains("*") && !rel.contains("{") {
                    return true
                }
            }
            // JunkEngine.scanUserCaches 枚举 ~/Library/Containers/<bundleID>/Data/Library/Caches 的直接子项
            if template.hasPrefix("~/Library/Containers/") && template.hasSuffix("/Data/Library/Caches") {
                let middle = String(
                    template
                        .dropFirst("~/Library/Containers/".count)
                        .dropLast("/Data/Library/Caches".count)
                )
                if !middle.isEmpty && !middle.contains("/") {
                    return true
                }
            }
            // JunkEngine.scanUserLogs 枚举 ~/Library/Logs 的直接子项（深度 1）
            if template.hasPrefix("~/Library/Logs/") {
                let rel = String(template.dropFirst("~/Library/Logs/".count))
                if !rel.isEmpty && !rel.contains("/") && !rel.contains("*") && !rel.contains("{") {
                    return true
                }
            }
            return false
        }
        return validTemplates.allSatisfy(isSingleTemplateCovered)
    }

    /// 导出全部垃圾规则的五态生命周期审计结果（角色、已定义、已发现、已实现判断、可执行、可自动推荐）
    func auditRuleStatuses() -> [String: RuleStatusAudit] {
        guard loaded else { return [:] }
        var out: [String: RuleStatusAudit] = [:]
        for rule in junk.values {
            let role = Self.ruleRole(for: rule)
            let isDefined = rule.active
            let hasScanEntry = isDefined && hasScannerEntryCoverage(for: rule)
            let isPredicateImplemented = AppConfig.RuleIDs.implementedPredicates.contains(rule.predicate)
            let isExecutable = isDefined
                && hasScanEntry
                && role == .cleanupTarget
                && isPredicateImplemented
                && (rule.action == "trash" || rule.action == "trash_children_only")
                && (rule.tier == .automatic || rule.tier == .review)
            let isAutoRecommendable = isExecutable
                && hasScanEntry
                && rule.tier == .automatic
                && rule.selected
                && AppConfig.RuleIDs.implementedAutomaticRules.contains(rule.id)
            out[rule.id] = RuleStatusAudit(
                ruleID: rule.id,
                role: role,
                isDefined: isDefined,
                hasScanEntry: hasScanEntry,
                isPredicateImplemented: isPredicateImplemented,
                isExecutable: isExecutable,
                isAutoRecommendable: isAutoRecommendable
            )
        }
        return out
    }

    /// 规则覆盖审计：核查 active 状态且角色为 .cleanupTarget 的垃圾规则是否绑定了非空路径模板且具备对应深度的扫描发现入口；
    /// 上下文保护规则（.contextualProtection）不视为漏扫；若清理目标规则存在无扫描路径或扫描器未覆盖该深度，产出 .missingScanEntry(ruleId:)。
    @discardableResult
    func auditRuleScanEntries() -> [CandidateEvaluationReason] {
        guard loaded else { return [] }
        var missing: [CandidateEvaluationReason] = []
        for rule in junk.values.sorted(by: { $0.id < $1.id }) where rule.active {
            guard Self.ruleRole(for: rule) == .cleanupTarget else { continue }
            if !hasScannerEntryCoverage(for: rule) {
                let reason = CandidateEvaluationReason.missingScanEntry(ruleId: rule.id)
                missing.append(reason)
                IOScanContext.recordEvaluation(reason)
            }
        }
        return missing
    }

    /// 快速判定目录是否命中 action == "trash_children_only" 的保壳规则，避免扫描器在容器展开前预先递归测量父目录体积。
    func isTrashChildrenOnlyContainer(_ url: URL, identity: FileIdentity? = nil) -> Bool {
        guard loaded else { return false }
        let resolvedIdentity = identity ?? FileIdentity.capture(from: url)
        guard resolvedIdentity?.isDirectory == true else { return false }
        let normalizedPath = Self.normalizeRuleMatchPath(url)
        var candidates = junk.values.filter { $0.active && matchesNormalizedPath(normalizedPath, rule: $0) }
        guard !candidates.isEmpty else { return false }
        candidates.sort {
            let a = matchingPathLengthNormalizedPath(normalizedPath, rule: $0)
            let b = matchingPathLengthNormalizedPath(normalizedPath, rule: $1)
            return a == b ? $0.tier.rawValue > $1.tier.rawValue : a > b
        }
        for rule in candidates {
            if rule.id == AppConfig.RuleIDs.leftoverOrphan { continue }
            if rule.id == AppConfig.RuleIDs.derivedOrphan && url.deletingLastPathComponent().lastPathComponent != "DerivedData" { continue }
            if rule.id == AppConfig.RuleIDs.derivedLive && url.deletingLastPathComponent().lastPathComponent != "DerivedData" { continue }
            if AppConfig.RuleIDs.cacheSubdirRules.contains(rule.id) {
                guard cacheSubdirTier(url, ruleID: rule.id) != nil else { continue }
            }
            if AppConfig.RuleIDs.rootOnlyContainerRules.contains(rule.id) {
                return isExactRuleRoot(normalizedPath: normalizedPath, rule: rule)
            }
            return rule.action == "trash_children_only"
        }
        return false
    }

    func diagnoseNonExecutableReason(for url: URL, ruleID: String, identity: FileIdentity? = nil) -> CandidateEvaluationReason {
        guard loaded else { return .ruleDatabaseUnavailable }
        let resolvedIdentity = identity ?? FileIdentity.capture(from: url)
        if !OpenFileGuard.isCurrentUserVerifiableScope(url, identity: resolvedIdentity) {
            return .systemScopeHandleBlindSpot(path: OpenFileGuard.canonicalScopeURL(url).path)
        }
        guard let rule = junk[ruleID] else { return .noMatchingAuthoredRule }
        if !AppConfig.RuleIDs.implementedPredicates.contains(rule.predicate) {
            return .unimplementedPredicate(ruleId: rule.id, predicate: rule.predicate)
        }
        if rule.action != "trash" && rule.action != "trash_children_only" {
            return .unknownOrNonTrashAction(ruleId: rule.id, action: rule.action)
        }
        if rule.id == AppConfig.RuleIDs.userCache,
           let childName = Self.extractUserCacheChildName(for: url),
           Self.isUserCacheChildAppRunning(childName, url: url) {
            return .runningProcessLocked
        }
        if rule.id == AppConfig.RuleIDs.containerCache && Self.isContainerCacheHostRunning(for: url) {
            return .runningProcessLocked
        }
        if rule.id == AppConfig.RuleIDs.brokenPlist && Self.isBrokenPlistEligible(url).runningLocked {
            return .runningProcessLocked
        }
        if rule.predicate == "wechat_not_running"
            && (ProcessGuard.isAppRunning(bundleID: "com.tencent.xinWeChat") || ProcessGuard.isAppRunning(named: "WeChat")) {
            return .runningProcessLocked
        }
        if hasRunningAppLock(for: url, rule: rule, isRunning: ProcessGuard.isAppRunning(bundleID:))
            || (AppConfig.RuleIDs.cacheSubdirRules.contains(rule.id)
                && ProcessGuard.shouldSkipDueToRunningProcess(path: url.path).skip)
            || ProcessGuard.isAnyToolchainRunning(effectiveProcessLocks(for: url, rule: rule)).isRunning
            || ((rule.id == AppConfig.RuleIDs.derivedOrphan || rule.id == AppConfig.RuleIDs.derivedLive)
                && ProcessGuard.shouldSkipDueToRunningProcess(path: url.path).skip) {
            return .runningProcessLocked
        }
        if !OpenFileGuard.isIdle(url, fresh: false) {
            return .runningProcessLocked
        }
        return .matchedReadOnlyOrForbiddenRule
    }

    func isRuleLockedByRunningApp(_ ruleID: String, url: URL? = nil) -> Bool {
        guard let rule = junk[ruleID] else { return false }
        let targetURL = url ?? FileUtil.home
        if hasRunningAppLock(for: targetURL, rule: rule, isRunning: ProcessGuard.isAppRunning(bundleID:)) {
            return true
        }
        if ProcessGuard.isAnyToolchainRunning(effectiveProcessLocks(for: targetURL, rule: rule)).isRunning {
            return true
        }
        return false
    }
}
