import Foundation

/// A narrow rule predicate, reused at scan and execution through AuthoredRules.
/// Unknown current versions, partial listings and installer markers retain data.
enum VersionedCachePolicy {
    private static func path(_ url: URL) -> String {
        SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path)
    }
    static func candidates(root: URL, current: URL?, browserDownloads: Bool) -> [URL] {
        let configuration = KnowledgeBaseManager.shared.authored.catalog.rows("cm_version_cache").first {
            guard let raw = $0["root_template"] else { return false }
            return path(URL(fileURLWithPath: KBPaths.expand(raw))) == path(root)
        }
        guard let configuration, let pattern = configuration["name_pattern"] else { return [] }
        let keep = max(AppConfig.RuleUpdates.minimumRetainedVersions, Int(configuration["keep_latest"] ?? "") ?? 0)
        let age = max(AppConfig.RuleUpdates.minimumVersionAgeHours, Int(configuration["min_age_hours"] ?? "") ?? 0)
        guard !SymlinkGuard.hasSymlinkEscape(url: root),
              let before = FileIdentity.capture(from: root), before.isDirectory,
              let children = try? FileManager.default.contentsOfDirectory(at: root,
                includingPropertiesForKeys: nil) else { return [] }
        let parent = root.deletingLastPathComponent()
        if AppConfig.JunkScan.versionInstallMarkers.contains(where: {
            FileUtil.exists(parent.appendingPathComponent($0).path)
        }) { return [] }
        let installLock = parent.appendingPathComponent(AppConfig.JunkScan.versionInstallLock)
        if FileUtil.exists(installLock.path),
           (SymlinkGuard.isSymbolicLink(at: installLock) || !OpenFileGuard.isIdle(installLock, fresh: true)) { return [] }
        var retained = Set<String>()
        let updateMarker = parent.appendingPathComponent(AppConfig.JunkScan.versionUpdateMarker)
        let updateIdentity = FileIdentity.capture(from: updateMarker)
        let currentPath = current.map { path($0.resolvingSymlinksInPath()) }
        if FileUtil.exists(updateMarker.path) {
            guard !SymlinkGuard.isSymbolicLink(at: updateMarker),
                  let attrs = try? FileManager.default.attributesOfItem(atPath: updateMarker.path),
                  ((attrs[.size] as? NSNumber)?.intValue ?? Int.max) <= AppConfig.JunkScan.versionMarkerMaximumBytes,
                  let text = try? String(contentsOf: updateMarker, encoding: .utf8) else { return [] }
            let version = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard children.contains(where: { $0.lastPathComponent == version }) else { return [] }
            retained.insert(path(root.appendingPathComponent(version)))
        }
        if let current {
            // The entry point must resolve to a concrete installed child version.
            guard FileUtil.exists(current.path) else { return [] }
            let active = path(current.resolvingSymlinksInPath())
            guard let version = children.first(where: { active == path($0) || active.hasPrefix(path($0) + "/") }) else { return [] }
            retained.insert(path(version))
        } else if !browserDownloads { return [] }
        var families: [String: [URL]] = [:]
        for child in children {
            guard AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName(child.lastPathComponent, pattern: pattern),
                  !SymlinkGuard.isSymbolicLink(at: child),
                  let identity = FileIdentity.capture(from: child), identity.isDirectory,
                  SymlinkGuard.isSafePath(url: child, within: root) else { continue }
            let family = browserDownloads ? String(child.lastPathComponent.split(separator: "-")[0]) : ""
            families[family, default: []].append(child)
        }
        var result: [URL] = []
        for versions in families.values {
            let ordered = versions.sorted { $0.lastPathComponent.compare($1.lastPathComponent, options: .numeric) == .orderedDescending }
            retained.formUnion(ordered.prefix(keep).map { path($0) })
            for version in ordered where !retained.contains(path(version)) {
                guard let identity = FileIdentity.capture(from: version),
                      Date().timeIntervalSince1970 - Double(identity.modificationTime) >= Double(age) * AppConfig.Security.secondsPerHour else { continue }
                result.append(version)
            }
        }
        guard FileIdentity.capture(from: root) == before,
              FileIdentity.capture(from: updateMarker) == updateIdentity,
              current.map({ path($0.resolvingSymlinksInPath()) }) == currentPath else { return [] }
        return result.sorted { $0.path < $1.path }
    }

    static func inventory(root: URL, browserDownloads: Bool) -> [URL] {
        guard !SymlinkGuard.hasSymlinkEscape(url: root),
              let children = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return [] }
        let pattern = browserDownloads ? AppConfig.JunkScan.browserDownloadVersionPattern : AppConfig.JunkScan.agentVersionPattern
        return children.filter {
            AppConfig.JunkScan.PathMatching.matchesWholeDirectoryName($0.lastPathComponent, pattern: pattern)
                && !SymlinkGuard.isSymbolicLink(at: $0)
                && FileIdentity.capture(from: $0)?.isDirectory == true
        }.sorted { $0.lastPathComponent.compare($1.lastPathComponent, options: .numeric) == .orderedDescending }
    }

    static func isEligible(_ url: URL, ruleID: String) -> Bool {
        let browser = ruleID == "JC.DEV.BROWSER.DOWNLOAD"
        let specs: [(String, String?)] = browser
            ? AppConfig.JunkScan.browserDownloadRoots.map { ($0, nil) }
            : AppConfig.JunkScan.agentVersionRoots.map { ($0.root, Optional($0.current)) }
        return specs.contains { root, current in
            let base = URL(fileURLWithPath: KBPaths.expand(root))
            guard path(url.deletingLastPathComponent()) == path(base) else { return false }
            return candidates(root: base, current: current.map { URL(fileURLWithPath: KBPaths.expand($0)) },
                browserDownloads: browser).contains { path($0) == path(url) }
        }
    }
}
