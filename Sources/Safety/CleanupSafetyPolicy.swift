import Foundation
import AppKit
import Darwin

struct DuplicateEvidence: Sendable {
    let keeper: URL
    let identity: FileIdentity
    let digest: String

    func validates(target: URL) -> Bool {
        guard target.standardizedFileURL != keeper.standardizedFileURL,
              identity.matches(url: keeper),
              OrganizeEngine.fullHash(keeper) == digest,
              OrganizeEngine.fullHash(target) == digest else { return false }
        return identity.matches(url: keeper)
    }
}

enum CleanupSafetyPolicy {
    static let lowerProtectedPathMarkers: [String] = AppConfig.Security.protectedPathMarkers.map { $0.lowercased() }

    /// Includes paths excluded by scanning, without applying display-only protected roots
    /// (e.g. Documents may be scanned and individual user files manually reviewed).
    static func isProtectedAsset(
        _ url: URL,
        withinWholeApp: URL? = nil,
        assumeNoSymlinks: Bool = false,
        allowLproj: Bool = false,
        allowAppInterior: Bool = false,
        allowOrphanVolatile: Bool = false,
        authored: AuthoredRules? = nil
    ) -> Bool {
        let path = url.standardizedFileURL.path
        let lower = path.lowercased()
        let kb = KnowledgeBaseManager.shared
        let hitSessionMarker: Bool = {
            if allowOrphanVolatile {
                return lower.contains("/library/cookies/")
            }
            return AppConfig.Security.sessionPathMarkers.contains(where: { lower.contains($0) })
        }()
        let hitProtectedPathMarker: Bool = {
            if lower.contains("/developer/xcode/") || lower.contains("/symbols/system/library/") {
                return false
            }
            return lowerProtectedPathMarkers.contains { marker in
                if marker == "inputmethod" || marker == "input methods" {
                    return lower.hasSuffix("/" + marker) || lower.contains("/" + marker + "/")
                }
                return lower.contains(marker)
            }
        }()
        let isExplicitAppStoreContainer: Bool = {
            let expected = FileUtil.home.appendingPathComponent("Library/Caches/com.apple.appstore").standardizedFileURL.path.lowercased()
            let realExpected = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches/com.apple.appstore").standardizedFileURL.path.lowercased()
            return lower == expected || lower == realExpected
        }()
        return FileUtil.isProtected(url)
            || ProtectedAssetPolicy.isProtected(
                url,
                withinWholeApp: withinWholeApp,
                assumeNoSymlinks: assumeNoSymlinks,
                allowLproj: allowLproj,
                allowAppInterior: allowAppInterior,
                authored: authored
            )
            || FileUtil.isTCCOrApplePrivateBlocked(path)
            || JunkEngine.isCloudOrSyncProviderPath(path)
            || hitSessionMarker
            || hitProtectedPathMarker
            || DockerHelper.isProtectedVirtualDisk(path: path)
            || (kb.isLoaded && (kb.isProtectedPath(path, allowLproj: allowLproj, allowAppInterior: allowAppInterior) || (!isExplicitAppStoreContainer && kb.isProtected(bundleID: url.lastPathComponent))))
    }

    static func isValidXCArchive(_ url: URL) -> Bool {
        guard url.pathExtension.lowercased() == "xcarchive" else { return false }
        var isDir: ObjCBool = false
        let productsPath = url.appendingPathComponent("Products").path
        let infoPlistPath = url.appendingPathComponent("Info.plist").path
        return FileManager.default.fileExists(atPath: infoPlistPath)
            && FileManager.default.fileExists(atPath: productsPath, isDirectory: &isDir)
            && isDir.boolValue
    }

    static func isInsideValidXCArchive(_ child: URL, root: URL, rootIsXCArchive: Bool) -> Bool {
        if rootIsXCArchive { return true }
        let rootStd = root.standardizedFileURL.path
        var current = child.standardizedFileURL
        while current.path.count >= rootStd.count && current.path != "/" {
            if current.pathExtension.lowercased() == "xcarchive" && isValidXCArchive(current) {
                return true
            }
            if current.path == rootStd { break }
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path { break }
            current = parent
        }
        return false
    }

    struct DirectorySafetyInspection: Sendable {
        let isSafe: Bool
        let reason: String?
        let downgradeAutomaticToReview: Bool
        let evaluationReason: CandidateEvaluationReason?
    }

    /// Every traversed child belongs to the deletion scope. Errors/cancellation never mean clear.
    static func inspect(
        _ url: URL,
        parentRuleID: String? = nil,
        requireCurrentUserUID: Bool = true
    ) -> (isSafe: Bool, reason: String?) {
        let res = inspectDirectory(url, parentRuleID: parentRuleID, requireCurrentUserUID: requireCurrentUserUID)
        return (res.isSafe, res.reason)
    }

    static func inspectDirectory(
        _ url: URL,
        parentRuleID: String? = nil,
        parentTier: CleanupTier? = nil,
        requireCurrentUserUID: Bool = true
    ) -> DirectorySafetyInspection {
        return FastDirectoryInspector.inspect(
            url,
            parentRuleID: parentRuleID,
            parentTier: parentTier,
            requireCurrentUserUID: requireCurrentUserUID,
            measurePhysicalBytes: false,
            invokeMeasureHook: false
        ).safetyInspection
    }
}

/// P2 (Section 5.2): 单次 `fts_read` 物理遍历器（同时产出真实磁盘体积、当前用户 UID 归属证明、完整安全巡检结果与最新修改时间）
enum FastDirectoryInspector {
    struct InspectionResult: Sendable {
        let physicalBytes: Int64
        var allocatedBytes: Int64 { physicalBytes }
        let measurementComplete: Bool
        let allCurrentUserOwned: Bool
        let safetyInspection: CleanupSafetyPolicy.DirectorySafetyInspection
        let latestModificationTime: time_t
        var rootIdentityBefore: FileIdentity? = nil
        var rootIdentityAfter: FileIdentity? = nil
        var inspectedEntryCount: Int = 0
        var degradationReason: ScanDegradationReason? = nil
    }

    struct HardLinkKey: Hashable {
        let dev: dev_t
        let ino: ino_t
    }

    #if DEBUG
    static nonisolated(unsafe) var allocatedBytesOverrideForTesting: ((String) -> Int64?)? = nil
    #else
    static var allocatedBytesOverrideForTesting: ((String) -> Int64?)? { nil }
    #endif

    static func inspect(
        _ url: URL,
        identity: FileIdentity? = nil,
        parentRuleID: String? = nil,
        parentTier: CleanupTier? = nil,
        profileID: String? = nil,
        requireCurrentUserUID: Bool = true,
        measurePhysicalBytes: Bool = true,
        invokeMeasureHook: Bool = false,
        forExecution: Bool = false
    ) -> InspectionResult {
        let p = url.path
        guard !p.isEmpty, !IOScanContext.isCancelled else {
            return InspectionResult(
                physicalBytes: 0,
                measurementComplete: false,
                allCurrentUserOwned: false,
                safetyInspection: CleanupSafetyPolicy.DirectorySafetyInspection(
                    isSafe: false,
                    reason: L10n.localized(.safetyInspectionIncomplete),
                    downgradeAutomaticToReview: false,
                    evaluationReason: .protectedAssetBlocked
                ),
                latestModificationTime: 0
            )
        }
        guard let root = identity ?? FileIdentity.capture(from: url) else {
            IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: p)
            return InspectionResult(
                physicalBytes: 0,
                measurementComplete: false,
                allCurrentUserOwned: false,
                safetyInspection: CleanupSafetyPolicy.DirectorySafetyInspection(
                    isSafe: false,
                    reason: L10n.localized(.safetyInspectionIncomplete),
                    downgradeAutomaticToReview: false,
                    evaluationReason: .protectedAssetBlocked
                ),
                latestModificationTime: 0
            )
        }

        let store = KnowledgeBaseManager.shared.authored
        let isAppBundle = url.pathExtension.lowercased() == "app"
        let resolvedParentRule: AuthoredJunkRule? = {
            guard store.loaded, !isAppBundle else { return nil }
            if let parentRuleID, let r = store.junk[parentRuleID] { return r }
            if let ev = store.evidence(for: url, identity: root, knownSize: 1, knownFullScopeVerifiable: true),
               let r = store.junk[ev.id] { return r }
            return nil
        }()
        let effectiveRuleID = parentRuleID ?? resolvedParentRule?.id
        let effectiveParentTier = parentTier ?? resolvedParentRule?.tier
        let resolvedProfileID = profileID ?? store.matchingCacheProfiles(for: url, ruleID: effectiveRuleID).first?.id

        if let ctx = IOScanContext.current {
            let canonicalPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path)
            let registered = ctx.registeredCandidates[canonicalPath]
            let EffectiveTierForKey = registered?.strictestTier ?? effectiveParentTier
            let receiptKey = InspectionReceiptKey(
                scanUUID: ctx.scanUUID,
                canonicalPath: canonicalPath,
                device: root.device,
                inode: root.inode,
                uid: root.uid,
                mode: root.mode,
                ruleSQLHash: store.ruleSQLHash,
                ruleID: effectiveRuleID,
                parentRuleID: parentRuleID,
                parentTier: EffectiveTierForKey?.rawValue,
                protectionDigest: "\(store.protections.count):\(registered?.ownerBundleIDs.sorted().joined(separator: ",") ?? "")",
                ignorePolicyVersion: AppConfigStore.shared.ignorePolicyVersion,
                profileID: resolvedProfileID,
                requireCurrentUserUID: requireCurrentUserUID,
                boundaryPolicy: measurePhysicalBytes ? "FTS_PHYSICAL|FTS_XDEV|FULL" : "FTS_PHYSICAL|FTS_XDEV|SAFETY"
            )
            if forExecution {
                let result = performInspect(
                    url,
                    root: root,
                    store: store,
                    isAppBundle: isAppBundle,
                    resolvedParentRule: resolvedParentRule,
                    effectiveRuleID: effectiveRuleID,
                    effectiveParentTier: effectiveParentTier,
                    requireCurrentUserUID: requireCurrentUserUID,
                    measurePhysicalBytes: measurePhysicalBytes,
                    invokeMeasureHook: invokeMeasureHook
                )
                ctx.recordExecutionInspection(
                    canonicalPath: canonicalPath,
                    contextDigest: receiptKey.contextDigest,
                    result: result
                )
                return result
            } else if measurePhysicalBytes {
                return ctx.executeOrReuseScanInspection(key: receiptKey) {
                    performInspect(
                        url,
                        root: root,
                        store: store,
                        isAppBundle: isAppBundle,
                        resolvedParentRule: resolvedParentRule,
                        effectiveRuleID: effectiveRuleID,
                        effectiveParentTier: effectiveParentTier,
                        requireCurrentUserUID: requireCurrentUserUID,
                        measurePhysicalBytes: measurePhysicalBytes,
                        invokeMeasureHook: invokeMeasureHook
                    )
                }
            }
        }

        return performInspect(
            url,
            root: root,
            store: store,
            isAppBundle: isAppBundle,
            resolvedParentRule: resolvedParentRule,
            effectiveRuleID: effectiveRuleID,
            effectiveParentTier: effectiveParentTier,
            requireCurrentUserUID: requireCurrentUserUID,
            measurePhysicalBytes: measurePhysicalBytes,
            invokeMeasureHook: invokeMeasureHook
        )
    }


    static let dataScopeDirectoryNames: Set<String> = [
        "library", "containers", "group containers", "application support", "caches", "preferences", "logs"
    ]

    static let sessionDirectoryNames: Set<String> = [
        "httpstorages", "webkit", "cookies", "saved application state"
    ]

    static let markerAndDiskLastSegments: [String] = {
        var segs = Set<String>()
        let sources: [String] = CleanupSafetyPolicy.lowerProtectedPathMarkers
            + DockerHelper.protectedDiskMarkers.map { $0.lowercased() }
            + AppConfig.Security.protectedAISubtreeSuffixes.map { $0.lowercased() }
            + AppConfig.Security.protectedAIExactSuffixes.map { $0.lowercased() }
        for item in sources {
            let trimmed = item.hasSuffix("/") ? String(item.dropLast()) : item
            guard !trimmed.isEmpty else { continue }
            if let slash = trimmed.lastIndex(of: "/") {
                let s = String(trimmed[trimmed.index(after: slash)...])
                if !s.isEmpty { segs.insert(s) }
            } else {
                segs.insert(trimmed)
            }
        }
        return Array(segs)
    }()

    static func isProtectedDescendantFast(
        childPath: String,
        childLastComponent: String,
        childLastLower: String,
        isDirectory: Bool,
        ftsLevel: Int,
        isAppBundleRoot: Bool,
        childAllowLproj: Bool,
        childAllowAppInterior: Bool,
        allowOrphanVolatile: Bool,
        inXcodeOrSystemSymbols: Bool,
        inDataScope: Bool,
        insideAppBundleInterior: Bool,
        insideSessionDir: Bool,
        rootAlreadyPastFirstCachesComponent: Bool,
        canMatchSystemOrHomeProtectedRoots: Bool,
        canMatchDotRootsOrDockerConfig: Bool,
        canMatchDirectChildTCC: Bool,
        hasAppInteriorProtection: Bool,
        applicableProtections: [AuthoredPathProtection],
        applicableProtectionLastSegments: [String],
        store: AuthoredRules,
        kb: KnowledgeBaseManager,
        kbPlan: KBSubtreeProtectionPlan,
        getChildURL: () -> URL,
        getChildNormalizedPath: () -> String
    ) -> Bool {
        if insideSessionDir { return true }
        if childLastLower.hasSuffix(".photoslibrary")
            || childLastLower.contains(AppConfig.Remediation.quarantineMarker) {
            return true
        }
        if AppConfig.Security.credentialDirectories.contains(childLastLower)
            || AppConfig.Security.credentialNames.contains(childLastLower) {
            return true
        }
        if AppConfig.Security.edrTamperProtectedPrefixes.contains(where: childLastLower.contains) {
            return true
        }
        if childLastLower.hasSuffix(".app"),
           let info = autoreleasepool(invoking: { NSDictionary(contentsOf: getChildURL().appendingPathComponent(AppConfig.Remediation.infoPlistPath)) }),
           let bid = info[AppConfig.Remediation.bundleIDKey] as? String,
           AppConfig.Security.edrTamperProtectedPrefixes.contains(where: { bid.lowercased().hasPrefix($0) }) {
            return true
        }
        if inDataScope {
            if AppConfig.Security.passwordStoreNames.contains(where: childLastLower.contains)
                || AppConfig.Security.browserStateNames.contains(childLastLower)
                || childLastLower.hasSuffix(".binarycookies") {
                return true
            }
            if AppConfig.Security.fallbackMailNames.contains(childLastLower)
                || store.mailNames.contains(childLastLower)
                || AppConfig.Security.fallbackMailIDs.contains(where: childLastLower.contains)
                || store.mailIDs.contains(where: childLastLower.contains) {
                return true
            }
        }
        if !rootAlreadyPastFirstCachesComponent {
            if AppConfig.Security.keychainStormProtectedDaemons.contains(childLastLower)
                || AppConfig.Security.sensitiveIdentityFragments.contains(where: childLastLower.contains) {
                let comps = getChildNormalizedPath().split(separator: "/").map(String.init)
                if let idx = comps.firstIndex(of: "caches"), comps.count > idx + 1 {
                    let name = comps[idx + 1]
                    if AppConfig.Security.keychainStormProtectedDaemons.contains(name)
                        || AppConfig.Security.sensitiveIdentityFragments.contains(where: name.contains) {
                        return true
                    }
                }
            }
        }
        if !isDirectory {
            if childLastLower.contains("datavault") || (ftsLevel == 1 && canMatchDirectChildTCC) {
                if FileUtil.isTCCOrApplePrivateBlocked(childPath) { return true }
            }
            if !inXcodeOrSystemSymbols && AppConfig.Security.cloudPathMarkers.contains(where: childLastLower.contains) {
                if JunkEngine.isCloudOrSyncProviderPath(childPath) { return true }
            }
        }
        if canMatchSystemOrHomeProtectedRoots && FileUtil.isProtected(getChildURL()) {
            return true
        }
        if canMatchDotRootsOrDockerConfig {
            let norm = getChildNormalizedPath()
            if ProtectedAssetPolicy.protectedDotRootPaths.contains(norm)
                || norm == ProtectedAssetPolicy.dockerConfigPath {
                return true
            }
        }
        if !isAppBundleRoot && !childAllowAppInterior && hasAppInteriorProtection && insideAppBundleInterior {
            if getChildNormalizedPath().contains(".app/") {
                return true
            }
        }
        if applicableProtectionLastSegments.contains(where: childLastLower.contains) {
            let norm = getChildNormalizedPath()
            let skipBundleInterior = isAppBundleRoot || childAllowAppInterior
            for prot in applicableProtections {
                if skipBundleInterior && AppConfig.RuleIDs.bundleInteriorProtectionPaths.contains(prot.path) {
                    continue
                }
                if childAllowLproj && prot.path == ".lproj" {
                    continue
                }
                if prot.matchesNormalizedCandidate(norm) {
                    return true
                }
            }
        }
        if markerAndDiskLastSegments.contains(where: childLastLower.contains) {
            let norm = getChildNormalizedPath()
            if AppConfig.Security.protectedAISubtreeSuffixes.contains(where: { norm.hasSuffix($0) || norm.contains($0 + "/") })
                || AppConfig.Security.protectedAIExactSuffixes.contains(where: { norm.hasSuffix($0) }) {
                return true
            }
            if !inXcodeOrSystemSymbols {
                for marker in CleanupSafetyPolicy.lowerProtectedPathMarkers {
                    if marker == "inputmethod" || marker == "input methods" {
                        if norm.hasSuffix("/" + marker) || norm.contains("/" + marker + "/") {
                            return true
                        }
                    } else if norm.contains(marker) {
                        return true
                    }
                }
            }
            if DockerHelper.isProtectedVirtualDisk(path: childPath) {
                return true
            }
        }
        if kbPlan.isProtectedDescendant(
            path: childPath,
            lastComponent: childLastComponent,
            lastComponentLower: childLastLower,
            getLowerPath: getChildNormalizedPath
        ) {
            return true
        }
        return false
    }
}

enum CleanupFailure: String, Sendable {
    case permission, readOnlyVolume, busy, missing, io
    static func classify(_ error: Error) -> CleanupFailure {
        let ns = error as NSError
        if let nested = ns.userInfo[NSUnderlyingErrorKey] as? Error { return classify(nested) }
        if ns.domain == NSPOSIXErrorDomain {
            switch Int32(ns.code) {
            case EACCES, EPERM: return .permission
            case EROFS: return .readOnlyVolume
            case EBUSY: return .busy
            case ENOENT: return .missing
            default: return .io
            }
        }
        if ns.domain == NSOSStatusErrorDomain && (ns.code == -54 || ns.code == -5000) {
            return .permission
        }
        switch ns.code {
        case NSFileReadNoPermissionError, NSFileWriteNoPermissionError: return .permission
        case NSFileNoSuchFileError, NSFileReadNoSuchFileError: return .missing
        default: return .io
        }
    }
}
