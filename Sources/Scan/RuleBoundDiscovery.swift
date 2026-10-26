import Foundation
import Darwin

enum RuleBoundDiscovery {
    private static func isStrictPhysicalChild(_ child: URL, of parent: URL) -> Bool {
        let childPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(child.resolvingSymlinksInPath().standardizedFileURL.path)
        let parentPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(parent.resolvingSymlinksInPath().standardizedFileURL.path)
        return childPath != parentPath && childPath.hasPrefix(parentPath == "/" ? "/" : parentPath + "/")
    }
    /// Expands only explicitly described directory components, with no symlink traversal.
    static func expand(_ template: String, stopped: () -> Bool) -> [URL] {
        let expanded = KBPaths.expand(template)
        guard expanded.hasPrefix("/"), !expanded.contains("{"), !expanded.contains("\0") else { return [] }
        let components = expanded.split(separator: "/").map(String.init)
        guard components.count <= AppConfig.RuleUpdates.maximumDiscoveryDepth, !components.contains("..") else { return [] }
        var current = [URL(fileURLWithPath: "/")]
        var count = 0
        for component in components {
            if stopped() { return [] }
            var next: [URL] = []
            for parent in current {
                let wildcard = component.contains("*") || component.contains("?") || component.contains("[")
                let candidates = wildcard ? FileUtil.children(of: parent).filter { fnmatch(component, $0.lastPathComponent, FNM_PATHNAME) == 0 }
                    : [parent.appendingPathComponent(component)]
                for file in candidates {
                    count += 1
                    guard count <= AppConfig.RuleUpdates.maximumRecords else { IOScanContext.recordTimeoutOrBudgetDegradation(); return [] }
                    // Ancestors such as /Users are traversal points, never deletion targets.
                    // Enforce physical containment here; apply target protection at the leaf.
                    guard !SymlinkGuard.isSymbolicLink(at: file), FileUtil.exists(file.path),
                          !SymlinkGuard.hasSymlinkEscape(url: file),
                          isStrictPhysicalChild(file, of: parent) else { continue }
                    next.append(file)
                }
            }
            current = next
        }
        return current
    }
}

extension JunkEngine {
    static func scanRuleBoundPaths(excluding: Set<String>, stopped: () -> Bool) -> ScanGroup? {
        let store = KnowledgeBaseManager.shared.authored
        var seen = excluding
        var items: [ScanItem] = []
        let generic = AppConfig.RuleUpdates.genericDiscoveryScanners
        for binding in store.catalog.bindings where binding.status == .active && generic.contains(binding.scannerID) {
            if stopped() { break }
            guard let rule = store.junk[binding.ruleID], rule.active, rule.tier.executable,
                  !AppConfig.JunkScan.versionCacheRuleIDs.contains(rule.id), !binding.pathTemplate.isEmpty else { continue }
            // These predicates need their existing dedicated identity-aware scanners.
            if AppConfig.RuleUpdates.dedicatedDiscoveryPredicates.contains(rule.predicate) { continue }
            var urls: [URL]
            if AppConfig.RuleIDs.cacheSubdirRules.contains(rule.id) || rule.id == AppConfig.RuleIDs.firefoxCache {
                urls = store.cacheDirectories(ruleID: rule.id)
            } else {
                let profiles = store.cacheProfiles.values.filter { $0.ruleID == rule.id }
                if !profiles.isEmpty { urls = profiles.flatMap { store.discoverUnits(for: $0) } }
                else {
                    urls = RuleBoundDiscovery.expand(binding.pathTemplate, stopped: stopped)
                    if binding.discoveryKind == .wildcardChild && !binding.pathTemplate.contains("*") {
                        urls = urls.flatMap { FileUtil.children(of: $0) }
                    }
                }
            }
            for url in urls {
                if stopped() { break }
                guard seen.insert(url.standardizedFileURL.path).inserted, !isIgnoredPath(url.path),
                      !SymlinkGuard.isSymbolicLink(at: url), SymlinkGuard.isSafePath(url: url),
                      let candidate = JunkRulePolicy.makeMeasuredCandidate(url: url, name: url.lastPathComponent,
                        note: L10n.localized(.ruleScanAdditionalPaths), safety: .caution, minBytes: rule.minBytes) else { continue }
                items.append(JunkRulePolicy.apply(candidate))
            }
        }
        guard !items.isEmpty else { return nil }
        return ScanGroup(title: L10n.localized(.ruleScanAdditionalPaths), icon: "folder", note: "", tileKey: "systemJunk", safety: .caution, items: items)
    }
}
