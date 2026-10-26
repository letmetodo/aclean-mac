import Foundation
import Security
import Darwin

struct UninstallContext: Sendable {
    let appURL: URL
    let bundleID: String
    let isAppBody: Bool
    var appGroupID: String? = nil
}

enum UninstallSafety {
    /// Signing metadata is evidence for display, never a license to delete a shared container.
    static func appGroups(_ url: URL) -> Set<String>? {
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess, let code else { return nil }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
              let dict = info as? [String: Any], let entitlements = dict[kSecCodeInfoEntitlementsDict as String] as? [String: Any] else { return nil }
        return Set(entitlements[AppConfig.Remediation.appGroupEntitlement] as? [String] ?? [])
    }

    static func canDeleteAssociatedData(_ context: UninstallContext, url: URL) -> Bool {
        guard !context.isAppBody else { return true }
        // No complete inventory of every user/external volume exists: shared groups remain view-only.
        if context.appGroupID != nil || url.path.lowercased().contains(AppConfig.Remediation.groupContainersMarker) { return false }
        let app = InstalledApp(name: context.appURL.deletingPathExtension().lastPathComponent,
                               bundleID: context.bundleID, url: context.appURL)
        return !UninstallerEngine.hasSurvivingInstallation(for: app)
    }

    static func isDefaultItem(_ node: Node) -> Bool {
        guard !node.locked else { return false }
        if node.uninstallContext?.isAppBody == true { return true }
        return node.ruleEvidence?.defaultSelected == true && node.ruleEvidence?.tier == .automatic
    }
}

extension UninstallerEngine {
    static func leftovers(for app: InstalledApp, inventory: [AppIdentity]? = nil) -> [ScanItem] {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        let kb = KnowledgeBaseManager.shared
        guard app.bundleID.count >= 3, app.bundleID != "...",
              app.bundleID.allSatisfy({ AppConfig.Remediation.uninstallIdentityCharacters.contains($0) }),
              !(kb.isLoaded && kb.isProtected(bundleID: app.bundleID)),
              !ProtectedAssetPolicy.isProtectedIdentity(app.bundleID), kb.authored.templatesLoaded else { return [] }
        let templates = kb.authored.templates
        let groups = UninstallSafety.appGroups(app.url) ?? []
        let identities = inventory ?? fastInstalledAppIdentities()
        let safeName = isSafeMatchToken(app.name) && !app.name.contains("/")
            && Set(app.name).isDisjoint(with: AppConfig.Remediation.uninstallGlobCharacters) && app.name != "." && app.name != ".."
            && !sharedVendorDirectoryNames.union(kb.authored.sharedVendorNames).contains(app.name.lowercased())
            && !kb.authored.collisionNames.contains(app.name.lowercased())
            && !identities.contains { $0.url != app.url && $0.name.lowercased() == app.name.lowercased() }
        var seen = Set<String>()
        var items: [ScanItem] = []
        func add(_ url: URL, template: AuthoredUninstallTemplate, group: String? = nil, displayOnly: Bool = false) {
            let path = url.standardizedFileURL.path
            guard !seen.contains(path), FileUtil.exists(path), !SymlinkGuard.hasSymlinkEscape(url: url) else { return }
            if CleanupSafetyPolicy.isProtectedAsset(url) {
                // Physical system redlines prohibit deletion, not a bounded read-only inventory.
                guard template.domain == "system", !ProtectedAssetPolicy.isProtected(url) else { return }
            }
            if sharedVendorDirectoryNames.union(kb.authored.sharedVendorNames).contains(url.lastPathComponent.lowercased()) { return }
            seen.insert(path)
            let measurement = FileUtil.measureSize(of: url)
            if !measurement.isComplete && !IOScanContext.isCancelled {
                IOScanContext.current?.record(L10n.localized(.scanCoverageIncomplete) + ": " + url.path)
            }
            let context = UninstallContext(appURL: app.url, bundleID: app.bundleID, isAppBody: false, appGroupID: group)
            let executable = !displayOnly && measurement.isComplete && template.execute && template.domain == "user" && template.tier.executable
                && UninstallSafety.canDeleteAssociatedData(context, url: url)
            // Exact ownership permits review; a directory name alone never proves reproducible cache contents.
            var item = ScanItem(url: url, name: url.lastPathComponent, size: measurement.bytes,
                                note: L10n.localized(.categoryAssociatedData), safety: .caution, isSelected: false,
                                authorizationContext: .uninstall)
            item.locked = !executable
            item.ownerBundleIDs = [app.bundleID]
            item.fileIdentity = FileIdentity.capture(from: url)
            item.uninstallContext = context
            item.uninstallPurpose = classifyFolderPurpose(path: template.path, fallbackNote: item.note)
            item.ruleEvidence = CleanupRuleEvidence(id: template.id, tier: executable ? .review : .readOnly,
                                                   reason: executable ? .manualReview : .whitelistProtected, defaultSelected: false)
            items.append(item)
        }
        for template in templates {
            if template.id == "UNINST_01" || template.domain == "session" { continue }
            if template.path.contains("{appGroupID}") {
                for group in groups where group.count >= 3 && group != "..."
                    && group.allSatisfy({ AppConfig.Remediation.uninstallIdentityCharacters.contains($0) }) {
                    add(URL(fileURLWithPath: KBPaths.expand(template.path.replacingOccurrences(of: "{appGroupID}", with: group))),
                        template: template, group: group)
                }
                continue
            }
            if template.id == "UNINST_NAME" { continue }
            if template.path.contains("{appName}") && !safeName { continue }
            var path = template.path.replacingOccurrences(of: "{bundleID}", with: app.bundleID)
                .replacingOccurrences(of: "{appName}", with: app.name)
            if path.contains(AppConfig.Remediation.darwinCacheToken) {
                guard let root = DarwinUserCache.path else { continue }
                path = path.replacingOccurrences(of: AppConfig.Remediation.darwinCacheToken, with: root)
            }
            if path.contains("{vendor}") {
                let parts = path.components(separatedBy: "{vendor}")
                guard parts.count == 2, safeName else { continue }
                let parent = URL(fileURLWithPath: KBPaths.expand(parts[0]))
                for vendor in FileUtil.children(of: parent) where FileIdentity.capture(from: vendor)?.isDirectory == true {
                    guard !SymlinkGuard.hasSymlinkEscape(url: vendor) else { continue }
                    let candidate = vendor.appendingPathComponent(String(parts[1].drop(while: { $0 == "/" })))
                    add(candidate, template: template, displayOnly: true)
                }
                continue
            }
            guard !path.contains("{") else { continue }
            let target = URL(fileURLWithPath: KBPaths.expand(path))
            if path.contains("*") {
                // Only one directory is listed. A glob is discovery evidence, never deletion ownership.
                let parent = target.deletingLastPathComponent()
                guard !parent.path.contains("*") else { continue }
                for candidate in FileUtil.children(of: parent)
                    where UninstallDiscovery.matches(candidate.lastPathComponent, template: template, app: app, identities: identities) {
                    add(candidate, template: template, displayOnly: true)
                }
            } else {
                add(target, template: template)
            }
        }
        if safeName, let template = templates.first(where: { $0.id == "UNINST_NAME" }) {
            add(URL(fileURLWithPath: KBPaths.expand(AppConfig.Remediation.appSupportTemplate.replacingOccurrences(of: "{appName}", with: app.name))), template: template)
        }
        return items.sorted { $0.size > $1.size }
    }
}

/// Stable body-first order and per-owner success gate shared by normal and retry execution.
enum UninstallBatchPolicy {
    static func ordered(_ targets: [CleanTarget]) -> [CleanTarget] {
        targets.enumerated().sorted {
            let a = isBody($0.element), b = isBody($1.element)
            return a != b ? a : $0.offset < $1.offset
        }.map(\.element)
    }
    static func isBody(_ target: CleanTarget) -> Bool {
        target.uninstallContext?.isAppBody == true || target.url?.pathExtension.lowercased() == "app"
    }
    static func bodyOwners(_ targets: [CleanTarget]) -> Set<String> {
        Set(targets.filter(isBody).flatMap { $0.ownerBundleIDs.map { $0.lowercased() } })
    }
    static func needsBodySuccess(_ target: CleanTarget, declared: Set<String>, succeeded: Set<String>) -> Bool {
        guard !isBody(target) else { return false }
        let owners = Set(target.ownerBundleIDs.map { $0.lowercased() })
        if target.uninstallContext != nil && owners.isDisjoint(with: declared) { return true }
        return !owners.intersection(declared).isSubset(of: succeeded)
    }
}

/// Closed, single-level filename discovery. Sibling app identities never become executable ownership.
enum UninstallDiscovery {
    static func matches(_ name: String, template: AuthoredUninstallTemplate, app: InstalledApp,
                        identities: [UninstallerEngine.AppIdentity]) -> Bool {
        let pattern = (template.path as NSString).lastPathComponent
            .replacingOccurrences(of: "{bundleID}", with: app.bundleID)
            .replacingOccurrences(of: "{appName}", with: app.name)
        guard fnmatch(pattern, name, FNM_PATHNAME) == 0 else { return false }
        if template.path.contains("{bundleID}") {
            guard name == app.bundleID || name.hasPrefix(app.bundleID + ".") || name.hasPrefix(app.bundleID + "-") else { return false }
            if identities.contains(where: {
                $0.bundleID != app.bundleID && !$0.bundleID.isEmpty &&
                    (name == $0.bundleID || name.hasPrefix($0.bundleID + ".") || name.hasPrefix($0.bundleID + "-"))
            }) { return false }
        }
        return true
    }
}

private enum DarwinUserCache {
    static var path: String? {
        let count = confstr(_CS_DARWIN_USER_CACHE_DIR, nil, 0)
        guard count > 1 else { return nil }
        var buffer = [CChar](repeating: 0, count: count)
        guard confstr(_CS_DARWIN_USER_CACHE_DIR, &buffer, count) == count else { return nil }
        return String(decoding: buffer.prefix(while: { $0 != 0 }).map(UInt8.init(bitPattern:)), as: UTF8.self)
    }
}
