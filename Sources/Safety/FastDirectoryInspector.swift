import Foundation
import Darwin

extension FastDirectoryInspector {
    static func performInspect(
        _ url: URL,
        root: FileIdentity,
        store: AuthoredRules,
        isAppBundle: Bool,
        resolvedParentRule: AuthoredJunkRule?,
        effectiveRuleID: String?,
        effectiveParentTier: CleanupTier?,
        requireCurrentUserUID: Bool,
        measurePhysicalBytes: Bool,
        invokeMeasureHook: Bool
    ) -> InspectionResult {
        if invokeMeasureHook {
            FileUtil.onMeasureSizeHook?(url)
        }
        let p = url.path
        let currentUID = getuid()
        let blockedAtRoot = FileUtil.isTCCOrApplePrivateBlocked(p) || JunkEngine.isCloudOrSyncProviderPath(p)

        var rootStat = stat()
        let hasRootStat = (lstat(p, &rootStat) == 0)
        var latestMtime: time_t = hasRootStat ? rootStat.st_mtimespec.tv_sec : root.modificationTime
        let isUpdaterStagingCache: Bool = {
            let low = p.lowercased()
            let verifiedBrowserDownload = effectiveRuleID == "JC.DEV.BROWSER.DOWNLOAD"
                && VersionedCachePolicy.isEligible(url, ruleID: "JC.DEV.BROWSER.DOWNLOAD")
            return verifiedBrowserDownload || (low.contains("/caches/") && (
                low.contains(".shipit")
                    || low.contains("/shipit")
                    || low.contains("org.sparkle-project.sparkle")
                    || low.contains("-updater/")
                    || low.contains("bundlemigration")
                    || low.contains("/ms-playwright/")
                    || low.contains("/ms-playwright-mcp/")
                    || low.contains("/dotslash/")
            ))
        }()
        let exemptTestCerts = isUpdaterStagingCache
            || (effectiveRuleID.map { AppConfig.RuleIDs.testCertificateExemptionRules.contains($0) } ?? false)
        let exemptLproj = isUpdaterStagingCache || (effectiveRuleID.map {
            AppConfig.RuleIDs.lprojExemptionRules.contains($0)
                || $0.hasPrefix("JC.DEV.")
                || $0.hasPrefix("JC.BRW.")
        } ?? false)
        let canExemptXCArchiveApp = effectiveRuleID.map { AppConfig.RuleIDs.xcarchiveAppExemptionRules.contains($0) } ?? false
        let rootIsValidXCArchive = canExemptXCArchiveApp && CleanupSafetyPolicy.isValidXCArchive(url)
        let allowOrphanVolatile = (effectiveRuleID == AppConfig.RuleIDs.leftoverOrphan)
            && OrphanSafetyPolicy.canScheduleForCleanup(url)

        let rootSystemShared = OpenFileGuard.isSystemSharedScopePath(url)
        var allOwned = (!requireCurrentUserUID || root.uid == currentUID) && !rootSystemShared
        var rootDowngradeToReview = false

        var rootSafetyFailure: CleanupSafetyPolicy.DirectorySafetyInspection? = nil
        if CleanupSafetyPolicy.isProtectedAsset(
            url,
            allowLproj: isUpdaterStagingCache,
            allowAppInterior: isUpdaterStagingCache,
            allowOrphanVolatile: allowOrphanVolatile,
            authored: store
        )
            || AppConfigStore.shared.isPathIgnoredForDeletion(url.path) {
            rootSafetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                isSafe: false,
                reason: L10n.localized(.cleanSkippedProtected),
                downgradeAutomaticToReview: false,
                evaluationReason: .protectedAssetBlocked
            )
        } else if GitGuard.isSensitiveFilename(url.lastPathComponent, exemptTestCertExtensions: exemptTestCerts) || url.lastPathComponent == ".git" {
            rootSafetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                isSafe: false,
                reason: L10n.localized(.cleanSkippedProtected),
                downgradeAutomaticToReview: false,
                evaluationReason: .protectedAssetBlocked
            )
        } else if exemptTestCerts && GitGuard.isSensitiveFilename(url.lastPathComponent, exemptTestCertExtensions: false) {
            rootDowngradeToReview = true
        } else if requireCurrentUserUID && root.uid != currentUID {
            rootSafetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                isSafe: false,
                reason: L10n.localized(.safetyInspectionIncomplete),
                downgradeAutomaticToReview: false,
                evaluationReason: .systemScopeHandleBlindSpot(path: OpenFileGuard.canonicalScopeURL(url).path)
            )
        }

        // Non-directory fast path (regular file, symlink, or special node)
        if !root.isDirectory {
            let mode = root.mode & S_IFMT
            let bytes: Int64
            let complete: Bool
            if blockedAtRoot || !hasRootStat {
                bytes = 0
                complete = false
            } else if mode == S_IFREG {
                bytes = Self.allocatedBytesOverrideForTesting?(p) ?? max(0, Int64(rootStat.st_blocks) * 512)
                complete = true
            } else if mode == S_IFLNK || mode == S_IFSOCK || mode == S_IFIFO {
                bytes = 0
                complete = true
                if (mode == S_IFSOCK || mode == S_IFIFO)
                    && (effectiveRuleID == AppConfig.RuleIDs.darwinTmp || effectiveRuleID == AppConfig.RuleIDs.darwinCache)
                    && rootSafetyFailure == nil {
                    rootSafetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                        isSafe: false,
                        reason: L10n.localized(.cleanSkippedProtected),
                        downgradeAutomaticToReview: false,
                        evaluationReason: .protectedAssetBlocked
                    )
                }
            } else {
                bytes = 0
                complete = false
            }
            let safety = rootSafetyFailure ?? CleanupSafetyPolicy.DirectorySafetyInspection(
                isSafe: true,
                reason: nil,
                downgradeAutomaticToReview: rootDowngradeToReview,
                evaluationReason: nil
            )
            return InspectionResult(
                physicalBytes: bytes,
                measurementComplete: complete,
                allCurrentUserOwned: allOwned,
                safetyInspection: safety,
                latestModificationTime: latestMtime,
                rootIdentityBefore: root,
                rootIdentityAfter: FileIdentity.capture(from: url) ?? root,
                inspectedEntryCount: 1,
                degradationReason: nil
            )
        }

        if let rootSafetyFailure, !measurePhysicalBytes {
            return InspectionResult(
                physicalBytes: 0,
                measurementComplete: false,
                allCurrentUserOwned: allOwned,
                safetyInspection: rootSafetyFailure,
                latestModificationTime: latestMtime,
                rootIdentityBefore: root,
                rootIdentityAfter: root
            )
        }

        if blockedAtRoot {
            return InspectionResult(
                physicalBytes: 0,
                measurementComplete: false,
                allCurrentUserOwned: false,
                safetyInspection: rootSafetyFailure ?? CleanupSafetyPolicy.DirectorySafetyInspection(
                    isSafe: false,
                    reason: L10n.localized(.cleanSkippedProtected),
                    downgradeAutomaticToReview: false,
                    evaluationReason: .protectedAssetBlocked
                ),
                latestModificationTime: latestMtime,
                rootIdentityBefore: root,
                rootIdentityAfter: root
            )
        }

        guard access(p, R_OK | X_OK) == 0 else {
            IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: p)
            return InspectionResult(
                physicalBytes: 0,
                measurementComplete: false,
                allCurrentUserOwned: false,
                safetyInspection: rootSafetyFailure ?? CleanupSafetyPolicy.DirectorySafetyInspection(
                    isSafe: false,
                    reason: L10n.localized(.safetyInspectionIncomplete),
                    downgradeAutomaticToReview: false,
                    evaluationReason: .protectedAssetBlocked
                ),
                latestModificationTime: latestMtime,
                rootIdentityBefore: root,
                rootIdentityAfter: root
            )
        }

        // 1. 根目录阶段预计算：生成适用于这棵子树的规则、保护项和豁免集合，避免每个文件重复准备
        let appPaths = ProcessGuard.runningApplicationBundlePaths()
        let rootLiteralPath = url.standardizedFileURL.path
        let rootPhysicalPath = url.resolvingSymlinksInPath().standardizedFileURL.path
        let rootHasNoSymlinkPrefix = (SymlinkGuard.canonicalizeMacOSSystemPrefix(rootLiteralPath) == rootPhysicalPath)
            && ((root.mode & S_IFMT) != S_IFLNK)
        let dirNormalizedPath = AuthoredRules.normalizeRuleMatchPath(url)
        let dirPrefix = dirNormalizedPath == "/" ? "/" : (dirNormalizedPath + "/")
        let dirSlashCount = dirNormalizedPath.utf8.filter({ $0 == UInt8(ascii: "/") }).count
        let parentSpecificity = resolvedParentRule.map { store.matchingPathLengthNormalizedPath(dirNormalizedPath, rule: $0) } ?? 0
        let activeRules: [AuthoredJunkRule] = (store.loaded && !isAppBundle) ? store.junk.values.filter(\.active) : []
        var parentRuleSpec: [String: Int] = [:]
        var candidateDescendantRules: [AuthoredJunkRule] = []
        var candidateDescendantSlashCounts = Set<Int>()
        var hasUncompiledDescendantRule = false
        for rule in activeRules {
            if rule.id == AppConfig.RuleIDs.leftoverOrphan {
                continue
            }
            let pSpec = store.matchingPathLengthNormalizedPath(dirNormalizedPath, rule: rule)
            parentRuleSpec[rule.id] = pSpec
            var canMatchDeeper = false
            for pattern in rule.compiledPatterns {
                guard pattern.staticSpecificity > parentSpecificity && pattern.staticSpecificity > pSpec else {
                    continue
                }
                if pattern.isGlob {
                    guard pattern.slashCount > dirSlashCount else { continue }
                    if pattern.staticPrefixBeforeWildcard.hasPrefix(dirPrefix)
                        || dirPrefix.hasPrefix(pattern.staticPrefixBeforeWildcard) {
                        canMatchDeeper = true
                        candidateDescendantSlashCounts.insert(pattern.slashCount)
                    }
                } else if pattern.root.hasPrefix(dirPrefix) {
                    canMatchDeeper = true
                    candidateDescendantSlashCounts.insert(pattern.slashCount)
                }
            }
            if rule.compiledPatterns.isEmpty && !rule.paths.isEmpty {
                canMatchDeeper = true
                hasUncompiledDescendantRule = true
            }
            if canMatchDeeper {
                candidateDescendantRules.append(rule)
            }
        }
        let candidateExcludeRules: [AuthoredJunkRule] = (store.loaded && !isAppBundle)
            ? store.junk.values.filter { rule in
                guard !rule.excludedNames.isEmpty else { return false }
                if rule.compiledPatterns.isEmpty && !rule.paths.isEmpty { return true }
                return rule.compiledPatterns.contains { pattern in
                    pattern.staticPrefixBeforeWildcard.hasPrefix(dirPrefix)
                        || dirPrefix.hasPrefix(pattern.staticPrefixBeforeWildcard)
                        || dirNormalizedPath == pattern.root
                        || dirNormalizedPath.hasPrefix(pattern.root + "/")
                }
            }
            : []
        let excludeRawLowerPrefixes: [String] = candidateExcludeRules.flatMap { rule -> [String] in
            if !rule.compiledExcluded.isEmpty || rule.excludedNames.isEmpty {
                return rule.compiledExcluded.map(\.rawLower)
            }
            return rule.excludedNames.map { $0.lowercased() }
        }
        let excludeLastSegments: [String] = candidateExcludeRules.flatMap { rule -> [String] in
            let items: [String] = (!rule.compiledExcluded.isEmpty || rule.excludedNames.isEmpty)
                ? rule.compiledExcluded.map(\.expanded)
                : rule.excludedNames.map { KBPaths.expand($0).lowercased() }
            return items.map { expanded in
                if let slash = expanded.lastIndex(of: "/") {
                    return String(expanded[expanded.index(after: slash)...])
                }
                return expanded
            }
        }

        let kb = KnowledgeBaseManager.shared
        let kbPlan = kb.subtreeProtectionPlan(forRootPath: p)
        let rootExcludesBundleInterior = isAppBundle || isUpdaterStagingCache
        let rootExcludesLproj = exemptLproj || isUpdaterStagingCache
        let applicableProtections: [AuthoredPathProtection] = store.protections.filter { prot in
            if rootExcludesBundleInterior && AppConfig.RuleIDs.bundleInteriorProtectionPaths.contains(prot.path) {
                return false
            }
            if rootExcludesLproj && prot.path == ".lproj" {
                return false
            }
            return prot.canMatchWithinSubtree(dirNormalizedPath: dirNormalizedPath, dirPrefix: dirPrefix)
        }
        let applicableProtectionLastSegments: [String] = Array(Set(applicableProtections.compactMap {
            $0.lastSegment.isEmpty ? nil : $0.lastSegment
        }))
        let hasAppInteriorProtection = applicableProtections.contains { $0.path == ".app/" }
        let inXcodeOrSystemSymbols = dirNormalizedPath.contains("/developer/xcode/")
            || dirNormalizedPath.contains("/symbols/system/library/")
        let rootInDataScope = AppConfig.Security.dataScopeMarkers.contains(where: dirNormalizedPath.contains)
        let rootInsideAppBundle = dirNormalizedPath.contains(".app/") || dirNormalizedPath.hasSuffix(".app")
        let rootPrefixHitsSessionMarker: Bool = {
            if allowOrphanVolatile {
                return dirPrefix.contains("/library/cookies/")
            }
            return AppConfig.Security.sessionPathMarkers.contains(where: { dirPrefix.contains($0) })
        }()
        let rootComponents = dirNormalizedPath.split(separator: "/").map(String.init)
        let rootAlreadyPastFirstCachesComponent: Bool = {
            guard let idx = rootComponents.firstIndex(of: "caches") else { return false }
            return rootComponents.count > idx + 1
        }()
        let homeLower = ProtectedAssetPolicy.homeLower
        let canMatchSystemOrHomeProtectedRoots: Bool = dirNormalizedPath == "/"
            || dirNormalizedPath == homeLower
            || dirNormalizedPath == homeLower + "/library"
            || dirNormalizedPath == "/library"
            || dirNormalizedPath == "/volumes"
            || dirNormalizedPath.hasPrefix("/system")
        let canMatchDotRootsOrDockerConfig: Bool = dirNormalizedPath == homeLower
            || dirNormalizedPath == homeLower + "/.docker"
        let canMatchDirectChildTCC: Bool = dirNormalizedPath == homeLower + "/library/caches"
            || dirNormalizedPath == "/library/caches"
            || dirNormalizedPath == homeLower + "/library/containers"
            || dirNormalizedPath == homeLower + "/library/group containers"
            || dirNormalizedPath == homeLower + "/library"

        return autoreleasepool {
            let cPath = strdup(p)
            defer { free(cPath) }
            var argv: [UnsafeMutablePointer<CChar>?] = [cPath, nil]
            guard let fts = fts_open(&argv, FTS_PHYSICAL | FTS_NOCHDIR | FTS_XDEV, nil) else {
                IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: p)
                return InspectionResult(
                    physicalBytes: 0,
                    measurementComplete: false,
                    allCurrentUserOwned: false,
                    safetyInspection: rootSafetyFailure ?? CleanupSafetyPolicy.DirectorySafetyInspection(
                        isSafe: false,
                        reason: L10n.localized(.safetyInspectionIncomplete),
                        downgradeAutomaticToReview: false,
                        evaluationReason: .protectedAssetBlocked
                    ),
                    latestModificationTime: latestMtime
                )
            }
            defer { fts_close(fts) }

            let isLargeContainerRule = effectiveRuleID?.hasPrefix("JC.DEV.") == true
                || effectiveRuleID == AppConfig.RuleIDs.userCache
                || effectiveRuleID == AppConfig.RuleIDs.containerCache
            let inspectionTimeout = isLargeContainerRule
                ? (AppConfig.Security.cleanupInspectionTimeout * AppConfig.Security.largeContainerInspectionTimeoutMultiplier)
                : AppConfig.Security.cleanupInspectionTimeout
            let deadline = ProcessInfo.processInfo.systemUptime + inspectionTimeout
            let maxItems = isLargeContainerRule
                ? (AppConfig.Security.cleanupInspectionMaxItems * AppConfig.Security.largeContainerInspectionMaxItemsMultiplier)
                : AppConfig.Security.cleanupInspectionMaxItems
            let uidOverride = FileIdentity.uidOverrideForTesting
            var count = 0
            defer { IOScanContext.addInspectedEntries(count) }

            var totalBytes: Int64 = 0
            var seenHardLinks = Set<HardLinkKey>()
            var measurementComplete = true
            var downgradeToReview = rootDowngradeToReview
            var safetyFailure: CleanupSafetyPolicy.DirectorySafetyInspection? = rootSafetyFailure

            var appBundleEnterLevel: Int? = rootInsideAppBundle ? 0 : nil
            var dataScopeEnterLevel: Int? = rootInDataScope ? 0 : nil
            var xcarchiveEnterLevel: Int? = rootIsValidXCArchive ? 0 : nil
            var sessionDirEnterLevel: Int? = rootPrefixHitsSessionMarker ? 0 : nil
            var matchedDescendantRuleEnterLevel: Int? = nil

            errno = 0
            while let ent = fts_read(fts) {
                if IOScanContext.isCancelled {
                    measurementComplete = false
                    allOwned = false
                    if safetyFailure == nil {
                        safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                            isSafe: false,
                            reason: L10n.localized(.safetyInspectionIncomplete),
                            downgradeAutomaticToReview: false,
                            evaluationReason: .protectedAssetBlocked
                        )
                    }
                    break
                }
                let info = Int32(ent.pointee.fts_info)
                let ftsLevel = Int(ent.pointee.fts_level)
                if info == FTS_DP {
                    if let m = appBundleEnterLevel, m > 0, ftsLevel <= m { appBundleEnterLevel = nil }
                    if let m = dataScopeEnterLevel, m > 0, ftsLevel <= m { dataScopeEnterLevel = nil }
                    if let m = xcarchiveEnterLevel, m > 0, ftsLevel <= m { xcarchiveEnterLevel = nil }
                    if let m = sessionDirEnterLevel, m > 0, ftsLevel <= m { sessionDirEnterLevel = nil }
                    if let m = matchedDescendantRuleEnterLevel, ftsLevel <= m { matchedDescendantRuleEnterLevel = nil }
                    errno = 0
                    continue
                }
                if ftsLevel == 0 {
                    if info == FTS_ERR || info == FTS_DNR || info == FTS_NS {
                        IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(ent.pointee.fts_errno)), path: p)
                        measurementComplete = false
                        allOwned = false
                        if safetyFailure == nil {
                            safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                                isSafe: false,
                                reason: L10n.localized(.safetyInspectionIncomplete),
                                downgradeAutomaticToReview: false,
                                evaluationReason: .protectedAssetBlocked
                            )
                        }
                    }
                    errno = 0
                    continue
                }

                count += 1
                let overBudget = count > maxItems
                    || ((count & 0x3F) == 0 && ProcessInfo.processInfo.systemUptime > deadline)
                if overBudget {
                    IOScanContext.recordTimeoutOrBudgetDegradation()
                    allOwned = false
                    measurementComplete = false
                    if safetyFailure == nil {
                        safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                            isSafe: false,
                            reason: L10n.localized(.safetyInspectionIncomplete),
                            downgradeAutomaticToReview: false,
                            evaluationReason: .protectedAssetBlocked
                        )
                    }
                    break
                }

                if info == FTS_ERR || info == FTS_DNR || info == FTS_NS {
                    IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(ent.pointee.fts_errno)), path: p)
                    measurementComplete = false
                    allOwned = false
                    if safetyFailure == nil {
                        safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                            isSafe: false,
                            reason: L10n.localized(.safetyInspectionIncomplete),
                            downgradeAutomaticToReview: false,
                            evaluationReason: .protectedAssetBlocked
                        )
                    }
                    if !measurePhysicalBytes { break }
                    errno = 0
                    continue
                }

                guard let st = ent.pointee.fts_statp,
                      let rawPath = ent.pointee.fts_path else {
                    measurementComplete = false
                    allOwned = false
                    if safetyFailure == nil {
                        safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                            isSafe: false,
                            reason: L10n.localized(.safetyInspectionIncomplete),
                            downgradeAutomaticToReview: false,
                            evaluationReason: .protectedAssetBlocked
                        )
                    }
                    if !measurePhysicalBytes { break }
                    errno = 0
                    continue
                }

                if st.pointee.st_mtimespec.tv_sec > latestMtime {
                    latestMtime = st.pointee.st_mtimespec.tv_sec
                }

                if st.pointee.st_dev != root.device {
                    if info == FTS_D {
                        fts_set(fts, ent, FTS_SKIP)
                    }
                    measurementComplete = false
                    allOwned = false
                    if safetyFailure == nil {
                        safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                            isSafe: false,
                            reason: L10n.localized(.safetyInspectionIncomplete),
                            downgradeAutomaticToReview: false,
                            evaluationReason: .protectedAssetBlocked
                        )
                    }
                    if !measurePhysicalBytes { break }
                    errno = 0
                    continue
                }

                let childPath = String(cString: rawPath)

                // 3. 目录节点优先处理覆盖整棵子树的 TCC / 云盘同步规则
                if info == FTS_D && (FileUtil.isTCCOrApplePrivateBlocked(childPath) || JunkEngine.isCloudOrSyncProviderPath(childPath)) {
                    fts_set(fts, ent, FTS_SKIP)
                    IOScanContext.current?.record(L10n.localized(.safetyInspectionIncomplete) + ": " + childPath)
                    measurementComplete = false
                    allOwned = false
                    if safetyFailure == nil {
                        safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                            isSafe: false,
                            reason: L10n.localized(.cleanSkippedProtected),
                            downgradeAutomaticToReview: false,
                            evaluationReason: .protectedAssetBlocked
                        )
                    }
                    if !measurePhysicalBytes { break }
                    errno = 0
                    continue
                }

                let mode = st.pointee.st_mode & S_IFMT
                if info == FTS_F {
                    let fileBytes = Self.allocatedBytesOverrideForTesting?(childPath) ?? max(0, Int64(st.pointee.st_blocks) * 512)
                    if st.pointee.st_nlink > 1 {
                        let key = HardLinkKey(dev: st.pointee.st_dev, ino: st.pointee.st_ino)
                        if !seenHardLinks.contains(key) {
                            seenHardLinks.insert(key)
                            totalBytes += fileBytes
                        }
                    } else {
                        totalBytes += fileBytes
                    }
                } else if info == FTS_DEFAULT {
                    if mode != S_IFREG && mode != S_IFDIR && mode != S_IFLNK && mode != S_IFSOCK && mode != S_IFIFO {
                        measurementComplete = false
                    } else if (mode == S_IFSOCK || mode == S_IFIFO)
                        && (effectiveRuleID == AppConfig.RuleIDs.darwinTmp || effectiveRuleID == AppConfig.RuleIDs.darwinCache)
                        && safetyFailure == nil {
                        safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                            isSafe: false,
                            reason: L10n.localized(.cleanSkippedProtected),
                            downgradeAutomaticToReview: false,
                            evaluationReason: .protectedAssetBlocked
                        )
                    }
                }

                // 2. 延迟构造 URL 与标准化路径，避免普通文件无谓构造 URL
                var cachedChildURL: URL? = nil
                func getChildURL() -> URL {
                    if let u = cachedChildURL { return u }
                    let u = URL(fileURLWithPath: childPath)
                    cachedChildURL = u
                    return u
                }
                var cachedChildNormalizedPath: String? = nil
                func getChildNormalizedPath() -> String {
                    if let n = cachedChildNormalizedPath { return n }
                    let n = rootHasNoSymlinkPrefix
                        ? SymlinkGuard.canonicalizeMacOSSystemPrefix(childPath).lowercased()
                        : AuthoredRules.normalizeRuleMatchPath(getChildURL())
                    cachedChildNormalizedPath = n
                    return n
                }

                let itemUID: uid_t = uidOverride?(getChildURL()) ?? st.pointee.st_uid
                if requireCurrentUserUID && itemUID != currentUID {
                    allOwned = false
                    if safetyFailure == nil {
                        safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                            isSafe: false,
                            reason: L10n.localized(.safetyInspectionIncomplete),
                            downgradeAutomaticToReview: false,
                            evaluationReason: .systemScopeHandleBlindSpot(path: OpenFileGuard.canonicalScopeURL(getChildURL()).path)
                        )
                    }
                    if !measurePhysicalBytes { break }
                }

                // Check symlinks for escape outside root, cloud sync target, or protected target (Section 2.3 & C09)
                if info == FTS_SL || info == FTS_SLNONE || mode == S_IFLNK {
                    if safetyFailure == nil && !isAppBundle {
                        let childURL = getChildURL()
                        let cRoot = SymlinkGuard.canonicalizeMacOSSystemPrefix(rootPhysicalPath)
                        if let dest = try? FileManager.default.destinationOfSymbolicLink(atPath: childPath) {
                            let targetURL = URL(fileURLWithPath: dest, relativeTo: childURL.deletingLastPathComponent()).standardizedFileURL
                            let resolvedTarget = targetURL.resolvingSymlinksInPath().standardizedFileURL
                            let cTarget = SymlinkGuard.canonicalizeMacOSSystemPrefix(targetURL.path)
                            let cResolved = SymlinkGuard.canonicalizeMacOSSystemPrefix(resolvedTarget.path)
                            let staysInRoot = (cTarget == cRoot || cTarget.hasPrefix(cRoot + "/"))
                                && (cResolved == cRoot || cResolved.hasPrefix(cRoot + "/"))
                            let hitsCloudOrProtected = JunkEngine.isCloudOrSyncProviderPath(cTarget)
                                || JunkEngine.isCloudOrSyncProviderPath(cResolved)
                                || FileUtil.isProtected(targetURL)
                                || FileUtil.isProtected(resolvedTarget)
                            if !staysInRoot || hitsCloudOrProtected {
                                safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                                    isSafe: false,
                                    reason: L10n.localized(.cleanSkippedProtected),
                                    downgradeAutomaticToReview: false,
                                    evaluationReason: .symlinkEscapeBlocked
                                )
                            }
                        } else {
                            safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                                isSafe: false,
                                reason: L10n.localized(.cleanSkippedProtected),
                                downgradeAutomaticToReview: false,
                                evaluationReason: .symlinkEscapeBlocked
                            )
                        }
                    }
                    errno = 0
                    continue
                }

                if safetyFailure == nil {
                    let isDir = (mode == S_IFDIR)
                    let childLastComponent: String = {
                        guard let slash = childPath.lastIndex(of: "/") else { return childPath }
                        let after = childPath.index(after: slash)
                        if after < childPath.endIndex {
                            return String(childPath[after...])
                        }
                        let trimmed = childPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                        if let s = trimmed.lastIndex(of: "/") {
                            return String(trimmed[trimmed.index(after: s)...])
                        }
                        return trimmed
                    }()
                    let childLastLower = childLastComponent.lowercased()

                    // 进入前序目录节点 (FTS_D) 时维护子树级上下文状态
                    if info == FTS_D {
                        if canExemptXCArchiveApp && xcarchiveEnterLevel == nil && childLastLower.hasSuffix(".xcarchive") {
                            if CleanupSafetyPolicy.isValidXCArchive(getChildURL()) {
                                xcarchiveEnterLevel = ftsLevel
                            }
                        }
                        if dataScopeEnterLevel == nil && Self.dataScopeDirectoryNames.contains(childLastLower) {
                            dataScopeEnterLevel = ftsLevel
                        }
                        if sessionDirEnterLevel == nil && Self.sessionDirectoryNames.contains(childLastLower) {
                            let dirWithSlash = getChildNormalizedPath() + "/"
                            let hitsSession = allowOrphanVolatile
                                ? dirWithSlash.contains("/library/cookies/")
                                : AppConfig.Security.sessionPathMarkers.contains(where: { dirWithSlash.contains($0) })
                            if hitsSession {
                                sessionDirEnterLevel = ftsLevel
                            }
                        }
                    }

                    let checkAppContextProtected = !isAppBundle
                        && !(effectiveRuleID?.hasPrefix("JC.DEV.") == true && effectiveRuleID != AppConfig.RuleIDs.jetBrainsCache)
                    let hitsAppContextProtected = childLastComponent == "LocalHistory"
                        || (checkAppContextProtected && (
                            AppConfig.JunkScan.PathMatching.protectedAppContextComponents.contains(childLastComponent)
                            || childPath.hasSuffix("/User/workspaceStorage")
                            || childPath.hasSuffix("/User/globalStorage")
                            || childPath.hasSuffix("/Network/Cookies")
                        ))

                    if childLastComponent == ".git"
                        || hitsAppContextProtected
                        || GitGuard.isSensitiveFilename(childLastComponent, exemptTestCertExtensions: exemptTestCerts) {
                        safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                            isSafe: false,
                            reason: L10n.localized(.cleanSkippedProtected),
                            downgradeAutomaticToReview: false,
                            evaluationReason: .protectedAssetBlocked
                        )
                    } else if isDir && appPaths.contains(childPath) {
                        safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                            isSafe: false,
                            reason: L10n.localized(.statusAppRunningSkipped),
                            downgradeAutomaticToReview: false,
                            evaluationReason: .runningProcessLocked
                        )
                    } else {
                        if exemptTestCerts && GitGuard.isSensitiveFilename(childLastComponent, exemptTestCertExtensions: false) {
                            downgradeToReview = true
                        }

                        // 检查规则级排除项 (candidateExcludeRules)
                        if !candidateExcludeRules.isEmpty {
                            let couldMatchExclude = excludeRawLowerPrefixes.contains(where: { childLastLower.hasPrefix($0) })
                                || excludeLastSegments.contains(where: { childLastLower == $0 })
                            if couldMatchExclude {
                                let childNormalizedPath = getChildNormalizedPath()
                                let isExcludedByAnyRule = store.isRuleExcludedNormalized(
                                    childNormalizedPath,
                                    lastComponentLower: childLastLower,
                                    originalURL: getChildURL()
                                )
                                if isExcludedByAnyRule {
                                    safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                                        isSafe: false,
                                        reason: L10n.localized(.cleanSkippedProtected),
                                        downgradeAutomaticToReview: false,
                                        evaluationReason: .descendantRuleConflict(
                                            path: rootLiteralPath,
                                            descendantPath: getChildURL().standardizedFileURL.path,
                                            ruleId: resolvedParentRule?.id ?? "cm_junk_rule_exclude"
                                        )
                                    )
                                }
                            }
                        }

                        // 检查更具体的子项规则冲突 (candidateDescendantRules)
                        if safetyFailure == nil && !candidateDescendantRules.isEmpty {
                            let childSlashCount = dirSlashCount + ftsLevel
                            let shouldCheckDescendantRules = !rootHasNoSymlinkPrefix
                                || hasUncompiledDescendantRule
                                || matchedDescendantRuleEnterLevel != nil
                                || candidateDescendantSlashCounts.contains(childSlashCount)
                            if shouldCheckDescendantRules {
                                let childNormalizedPath = getChildNormalizedPath()
                                var moreSpecificMatches: [(rule: AuthoredJunkRule, spec: Int)] = []
                                for rule in candidateDescendantRules {
                                    if rule.id == AppConfig.RuleIDs.leftoverOrphan {
                                        continue
                                    }
                                    if (rule.id == AppConfig.RuleIDs.derivedOrphan || rule.id == AppConfig.RuleIDs.derivedLive)
                                        && getChildURL().deletingLastPathComponent().lastPathComponent != "DerivedData" {
                                        continue
                                    }
                                    guard store.matchesNormalizedPath(childNormalizedPath, rule: rule) else { continue }
                                    let dSpec = store.matchingPathLengthNormalizedPath(childNormalizedPath, rule: rule)
                                    let pSpec = parentRuleSpec[rule.id] ?? 0
                                    if dSpec > parentSpecificity && dSpec > pSpec {
                                        moreSpecificMatches.append((rule, dSpec))
                                    }
                                }
                                if !moreSpecificMatches.isEmpty {
                                    moreSpecificMatches.sort {
                                        if $0.spec != $1.spec { return $0.spec > $1.spec }
                                        return $0.rule.tier.conservatismRank > $1.rule.tier.conservatismRank
                                    }
                                    let bestRule = moreSpecificMatches[0].rule
                                    let childIdentity = FileIdentity(
                                        device: st.pointee.st_dev,
                                        inode: st.pointee.st_ino,
                                        isDirectory: isDir,
                                        modificationTime: st.pointee.st_mtimespec.tv_sec,
                                        modificationTimeNsec: st.pointee.st_mtimespec.tv_nsec,
                                        fileSize: st.pointee.st_size,
                                        mode: st.pointee.st_mode,
                                        changeTime: st.pointee.st_ctimespec.tv_sec,
                                        changeTimeNsec: st.pointee.st_ctimespec.tv_nsec,
                                        linkCount: st.pointee.st_nlink,
                                        uid: itemUID
                                    )
                                    let childEv = store.evidence(for: getChildURL(), preferredID: bestRule.id, identity: childIdentity)
                                    if !bestRule.tier.executable
                                        || bestRule.action != "trash"
                                        || childEv?.executable != true {
                                        safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                                            isSafe: false,
                                            reason: L10n.localized(.cleanSkippedProtected),
                                            downgradeAutomaticToReview: false,
                                            evaluationReason: .descendantRuleConflict(
                                                path: rootLiteralPath,
                                                descendantPath: getChildURL().standardizedFileURL.path,
                                                ruleId: bestRule.id
                                            )
                                        )
                                    } else {
                                        if info == FTS_D && matchedDescendantRuleEnterLevel == nil {
                                            matchedDescendantRuleEnterLevel = ftsLevel
                                        }
                                        if effectiveParentTier == .automatic
                                            && (childEv?.tier != .automatic || childEv?.defaultSelected == false) {
                                            downgradeToReview = true
                                        }
                                    }
                                }
                            }
                        }

                        // 检查子项保护策略（目录子树保护 + 普通文件轻量级保护 + 逐条证明可省略的 KB 计划）
                        if safetyFailure == nil {
                            let childAllowAppInterior: Bool = {
                                if isUpdaterStagingCache { return true }
                                guard canExemptXCArchiveApp else { return false }
                                if rootHasNoSymlinkPrefix {
                                    return xcarchiveEnterLevel != nil
                                }
                                return CleanupSafetyPolicy.isInsideValidXCArchive(getChildURL(), root: url, rootIsXCArchive: rootIsValidXCArchive)
                            }()
                            let childAllowLproj = exemptLproj || childAllowAppInterior

                            let isProtectedChild: Bool
                            if !rootHasNoSymlinkPrefix {
                                isProtectedChild = CleanupSafetyPolicy.isProtectedAsset(
                                    getChildURL(),
                                    withinWholeApp: isAppBundle ? url : nil,
                                    assumeNoSymlinks: false,
                                    allowLproj: childAllowLproj,
                                    allowAppInterior: childAllowAppInterior,
                                    allowOrphanVolatile: allowOrphanVolatile,
                                    authored: store
                                )
                            } else {
                                isProtectedChild = Self.isProtectedDescendantFast(
                                    childPath: childPath,
                                    childLastComponent: childLastComponent,
                                    childLastLower: childLastLower,
                                    isDirectory: isDir,
                                    ftsLevel: ftsLevel,
                                    isAppBundleRoot: isAppBundle,
                                    childAllowLproj: childAllowLproj,
                                    childAllowAppInterior: childAllowAppInterior,
                                    allowOrphanVolatile: allowOrphanVolatile,
                                    inXcodeOrSystemSymbols: inXcodeOrSystemSymbols,
                                    inDataScope: dataScopeEnterLevel != nil,
                                    insideAppBundleInterior: appBundleEnterLevel != nil,
                                    insideSessionDir: sessionDirEnterLevel != nil && ftsLevel > (sessionDirEnterLevel ?? 0),
                                    rootAlreadyPastFirstCachesComponent: rootAlreadyPastFirstCachesComponent,
                                    canMatchSystemOrHomeProtectedRoots: canMatchSystemOrHomeProtectedRoots,
                                    canMatchDotRootsOrDockerConfig: canMatchDotRootsOrDockerConfig,
                                    canMatchDirectChildTCC: canMatchDirectChildTCC,
                                    hasAppInteriorProtection: hasAppInteriorProtection,
                                    applicableProtections: applicableProtections,
                                    applicableProtectionLastSegments: applicableProtectionLastSegments,
                                    store: store,
                                    kb: kb,
                                    kbPlan: kbPlan,
                                    getChildURL: getChildURL,
                                    getChildNormalizedPath: getChildNormalizedPath
                                )
                            }

                            if isProtectedChild {
                                safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                                    isSafe: false,
                                    reason: L10n.localized(.cleanSkippedProtected),
                                    downgradeAutomaticToReview: false,
                                    evaluationReason: .protectedAssetBlocked
                                )
                            } else if info == FTS_D && appBundleEnterLevel == nil && childLastLower.hasSuffix(".app") {
                                appBundleEnterLevel = ftsLevel
                            }
                        }
                    }
                    if safetyFailure != nil && !measurePhysicalBytes {
                        break
                    }
                }
                errno = 0
            }

            if !IOScanContext.isCancelled && errno != 0 {
                IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: p)
                measurementComplete = false
                allOwned = false
                if safetyFailure == nil {
                    safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                        isSafe: false,
                        reason: L10n.localized(.safetyInspectionIncomplete),
                        downgradeAutomaticToReview: false,
                        evaluationReason: .protectedAssetBlocked
                    )
                }
            }

            let rootAfter = FileIdentity.capture(from: url)
            if rootAfter != root {
                measurementComplete = false
                allOwned = false
                if safetyFailure == nil {
                    safetyFailure = CleanupSafetyPolicy.DirectorySafetyInspection(
                        isSafe: false,
                        reason: L10n.localized(.safetyInspectionIncomplete),
                        downgradeAutomaticToReview: false,
                        evaluationReason: .protectedAssetBlocked
                    )
                }
            }

            let finalSafety = safetyFailure ?? CleanupSafetyPolicy.DirectorySafetyInspection(
                isSafe: true,
                reason: nil,
                downgradeAutomaticToReview: downgradeToReview,
                evaluationReason: nil
            )
            let degReason: ScanDegradationReason? = (!measurementComplete && !finalSafety.isSafe)
                ? .containerEnumerationIncomplete
                : nil
            let resolvedTotalBytes = Self.allocatedBytesOverrideForTesting?(p)
                ?? Self.allocatedBytesOverrideForTesting?(SymlinkGuard.canonicalizeMacOSSystemPrefix(p))
                ?? totalBytes
            return InspectionResult(
                physicalBytes: resolvedTotalBytes,
                measurementComplete: measurementComplete,
                allCurrentUserOwned: allOwned,
                safetyInspection: finalSafety,
                latestModificationTime: latestMtime,
                rootIdentityBefore: root,
                rootIdentityAfter: rootAfter,
                inspectedEntryCount: count,
                degradationReason: degReason
            )
        }
    }
}
