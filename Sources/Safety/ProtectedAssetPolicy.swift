import Foundation

/// Identical safety boundary for scanners and every recursively inspected deletion target.
enum ProtectedAssetPolicy {
    static let homeLower: String = FileUtil.home.path.lowercased()
    static let protectedDotRootPaths: Set<String> = Set(AppConfig.Security.protectedDotRoots.map {
        FileUtil.home.path.lowercased() + "/" + $0
    })
    static let dockerConfigPath: String = FileUtil.home.path.lowercased() + "/.docker/config.json"

    static func isProtected(
        _ url: URL,
        withinWholeApp: URL? = nil,
        assumeNoSymlinks: Bool = false,
        allowLproj: Bool = false,
        allowAppInterior: Bool = false,
        authored: AuthoredRules? = nil
    ) -> Bool {
        let literal = url.standardizedFileURL
        if assumeNoSymlinks {
            let wholeApp = withinWholeApp.map { root in
                root.pathExtension.lowercased() == "app" && FileUtil.isStrictDescendant(literal, of: root)
            } ?? false
            return protectedPath(
                literal,
                allowWholeBundle: wholeApp,
                allowLproj: allowLproj,
                allowAppInterior: allowAppInterior,
                authored: authored
            )
        }
        let physical = url.resolvingSymlinksInPath().standardizedFileURL
        let wholeApp = withinWholeApp.map { root in
            root.pathExtension.lowercased() == "app" && FileUtil.isStrictDescendant(literal, of: root)
                && FileUtil.isStrictDescendant(physical, of: root.resolvingSymlinksInPath())
        } ?? false
        return protectedPath(
            literal,
            allowWholeBundle: wholeApp,
            allowLproj: allowLproj,
            allowAppInterior: allowAppInterior,
            authored: authored
        ) || (
            physical.path != literal.path
                && protectedPath(
                    physical,
                    allowWholeBundle: wholeApp,
                    allowLproj: allowLproj,
                    allowAppInterior: allowAppInterior,
                    authored: authored
                )
        )
    }

    static func protectedPath(
        _ url: URL,
        allowWholeBundle: Bool = false,
        allowLproj: Bool = false,
        allowAppInterior: Bool = false,
        authored: AuthoredRules? = nil
    ) -> Bool {
        let path = url.path.lowercased()
        if path.contains(AppConfig.Remediation.quarantineMarker) { return true }
        let config = authored ?? KnowledgeBaseManager.shared.authored
        let normalizedPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(url.path).lowercased()
        if config.disabledDiscoveryRule(normalizedPath: normalizedPath) != nil { return true }
        let lastLower = url.lastPathComponent.lowercased()
        if config.isProtectedNormalized(
            normalizedPath,
            allowWholeBundle: allowWholeBundle,
            allowLproj: allowLproj,
            allowAppInterior: allowAppInterior
        ) || config.isRuleExcludedNormalized(normalizedPath, lastComponentLower: lastLower, originalURL: url) { return true }
        let components = path.split(separator: "/").map(String.init)
        if !AppConfig.Security.credentialDirectories.isDisjoint(with: components) { return true }
        if components.contains(where: { AppConfig.Security.credentialNames.contains($0) }) {
            return true
        }
        if protectedDotRootPaths.contains(path) { return true }
        if path == dockerConfigPath { return true }
        if AppConfig.Security.protectedAISubtreeSuffixes.contains(where: { path.hasSuffix($0) || path.contains($0 + "/") })
            || AppConfig.Security.protectedAIExactSuffixes.contains(where: { path.hasSuffix($0) }) {
            return true
        }
        if AppConfig.Security.edrTamperProtectedPrefixes.contains(where: path.contains) { return true }
        if url.pathExtension.lowercased() == "app",
           let info = autoreleasepool(invoking: { NSDictionary(contentsOf: url.appendingPathComponent(AppConfig.Remediation.infoPlistPath)) }),
           let bid = info[AppConfig.Remediation.bundleIDKey] as? String,
           AppConfig.Security.edrTamperProtectedPrefixes.contains(where: { bid.lowercased().hasPrefix($0) }) { return true }
        if AppConfig.RuleUpdates.offlineWorkerPathMarkers.contains(where: path.contains) {
            let offlineDomains = config.catalog.values("cm_service_worker_domain", "domain")
            if offlineDomains.contains(where: path.contains) { return true }
        }
        let inDataScope = AppConfig.Security.dataScopeMarkers.contains(where: path.contains)
        if inDataScope {
            if components.contains(where: { name in
                AppConfig.Security.passwordStoreNames.contains(where: name.contains)
                    || AppConfig.Security.browserStateNames.contains(name)
                    || name.hasSuffix(".binarycookies")
            }) { return true }
            if isMailPath(path, components: components, authored: config) { return true }
        }
        if let index = components.firstIndex(of: "caches"), components.count > index + 1 {
            let name = components[index + 1]
            if AppConfig.Security.keychainStormProtectedDaemons.contains(name)
                || AppConfig.Security.sensitiveIdentityFragments.contains(where: name.contains) { return true }
        }
        return false
    }

    static func isMailPath(_ raw: String, components: [String]? = nil, authored: AuthoredRules? = nil) -> Bool {
        let path = raw.lowercased()
        let config = authored ?? KnowledgeBaseManager.shared.authored
        if AppConfig.Security.fallbackMailIDs.contains(where: path.contains)
            || config.mailIDs.contains(where: path.contains) {
            return true
        }
        let authoredNames = config.mailNames
        if let components {
            return components.contains { AppConfig.Security.fallbackMailNames.contains($0) || authoredNames.contains($0) }
        }
        return path.split(separator: "/").contains {
            let s = String($0)
            return AppConfig.Security.fallbackMailNames.contains(s) || authoredNames.contains(s)
        }
    }

    static func isProtectedIdentity(_ bid: String) -> Bool {
        let low = bid.lowercased()
        return AppConfig.Security.edrTamperProtectedPrefixes.contains { low.hasPrefix($0) }
            || AppConfig.Security.fallbackMailIDs.contains(low)
            || KnowledgeBaseManager.shared.authored.mailIDs.contains(low)
            || AppConfig.Security.keychainStormProtectedDaemons.contains(low)
    }
}
