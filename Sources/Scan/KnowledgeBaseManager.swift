import Foundation
import SQLite3

final class KnowledgeBaseManager: @unchecked Sendable {
    static let shared = KnowledgeBaseManager()
    struct Snapshot {
        var isLoaded = false
        var version = ""
        var authored = AuthoredRules()
        var applicationsByBundleID: [String: KBApplication] = [:]
        var protectedBundleIDs = Set<String>()
        var protectedPathLiterals = Set<String>()
        var protectedRoots = Set<String>()
        var compiledBundleRegexes: [CompiledKBRegex] = []
        var compiledNameRegexes: [CompiledKBRegex] = []
        var compiledPathRegexes: [CompiledKBRegex] = []
    }
    private let storage = LockedValue(Snapshot())
    private init() {}
    var isLoaded: Bool { storage.withValue { $0.isLoaded } }
    var version: String { storage.withValue { $0.version } }
    var authored: AuthoredRules { storage.withValue { $0.authored } }
    var applicationsByBundleID: [String: KBApplication] { storage.withValue { $0.applicationsByBundleID } }
    var protectedBundleIDs: Set<String> { storage.withValue { $0.protectedBundleIDs } }
    var protectedPathLiterals: Set<String> { storage.withValue { $0.protectedPathLiterals } }
    var protectedRoots: Set<String> { storage.withValue { $0.protectedRoots } }
    var applicationCount: Int { applicationsByBundleID.count }
    func application(bundleID: String) -> KBApplication? { applicationsByBundleID[bundleID.lowercased()] }

    func prepare(from url: URL) throws -> Snapshot {
        let database = try RuleDatabase(url: url, limits: RuleUpdateConfiguration.limits)
        guard try database.rows("PRAGMA quick_check").first?["quick_check"] as? String == "ok" else { throw RuleUpdateFailure.invalidDatabase }
        let authored = try AuthoredRules.load(database.handle)
        let catalog = authored.catalog
        guard let version = catalog.parameter("rule_version"), Int64(version) != nil else { throw RuleUpdateFailure.invalidDatabase }
        var snapshot = Snapshot()
        snapshot.authored = authored; snapshot.version = version
        for (index, row) in catalog.rows("cm_application_identity").enumerated() {
            guard let id = row["bundle_id"], let name = row["name"] else { throw RuleUpdateFailure.invalidDatabase }
            snapshot.applicationsByBundleID[id.lowercased()] = KBApplication(recordID: index, name: name, bundleID: id, type: 0)
        }
        for row in catalog.rows("cm_global_guard") {
            guard let value = row["value"], let kind = row["kind"] else { throw RuleUpdateFailure.invalidDatabase }
            let path = KBPaths.expand(value).lowercased()
            let normalized = path.hasSuffix("/") && path.count > 1 ? String(path.dropLast()) : path
            switch kind {
            case "protected_bundle": snapshot.protectedBundleIDs.insert(value.lowercased())
            case "protected_path": snapshot.protectedPathLiterals.insert(normalized)
            case "protected_root": snapshot.protectedRoots.insert(normalized)
            default: throw RuleUpdateFailure.invalidDatabase
            }
        }
        guard authored.protectionsLoaded, !snapshot.protectedRoots.isEmpty else { throw RuleUpdateFailure.invalidDatabase }
        snapshot.isLoaded = true
        return snapshot
    }
    func publish(_ snapshot: Snapshot) { storage.withValue { $0 = snapshot } }
    #if DEBUG
    func load(from url: URL) throws {
        let snapshot = try prepare(from: url)
        let hash = RuleDigest.sha256(try Data(contentsOf: url))
        try RuleTaskGate.shared.activate(version: Int64(snapshot.version) ?? 0, hash: hash) { publish(snapshot) }
    }
    #endif

    // MARK: 查询:安全白名单

    /// BundleID 是否受保护(系统关键服务,绝不清理)
    func isProtected(bundleID: String) -> Bool {
        let low = bundleID.lowercased()
        return storage.withValue { state in
            guard state.isLoaded else { return true }
            if state.protectedBundleIDs.contains(low) { return true }
            for re in state.compiledBundleRegexes {
                if re.matches(low, lowerCandidate: low) { return true }
            }
            return false
        }
    }

    // MARK: - 顶层存储根容器集合 (绝不允许将其作为子树前缀阻断其下内容的扫描，收敛至 AppConfig.Paths)
    static var topLevelContainers: Set<String> { AppConfig.Paths.topLevelContainers }

    /// 为指定根目录预计算子树适用的 KB 保护集合（逐条证明不可能命中该子树时才省略）
    func subtreeProtectionPlan(forRootPath rootPath: String) -> KBSubtreeProtectionPlan {
        let rawLow = rootPath.lowercased()
        let rootLow = rawLow.hasSuffix("/") ? String(rawLow.dropLast()) : rawLow
        let rootPrefix = rootLow.isEmpty ? "/" : (rootLow + "/")
        let canonicalRootLow = SymlinkGuard.canonicalizeMacOSSystemPrefix(rootLow).lowercased()
        let canonicalPrefix = canonicalRootLow == "/" ? "/" : (canonicalRootLow + "/")
        let topContainers = Self.topLevelContainers

        return storage.withValue { state in
            guard state.isLoaded else {
                return KBSubtreeProtectionPlan(
                    isLoaded: false,
                    applicablePathLiterals: [],
                    protectedBundleIDs: [],
                    bundleRegexes: [],
                    nameRegexes: [],
                    pathRegexes: []
                )
            }
            let literals = state.protectedPathLiterals.filter { lit in
                guard !topContainers.contains(lit) else { return false }
                return lit.hasPrefix(rootPrefix) || lit.hasPrefix(canonicalPrefix)
            }
            let applicablePathREs = state.compiledPathRegexes.filter { re in
                guard let reqPrefix = re.requiredLowerPrefix else { return true }
                if reqPrefix.count <= rootPrefix.count {
                    return rootPrefix.hasPrefix(reqPrefix) || canonicalPrefix.hasPrefix(reqPrefix)
                } else {
                    return reqPrefix.hasPrefix(rootPrefix) || reqPrefix.hasPrefix(canonicalPrefix)
                }
            }
            return KBSubtreeProtectionPlan(
                isLoaded: true,
                applicablePathLiterals: literals,
                protectedBundleIDs: state.protectedBundleIDs,
                bundleRegexes: state.compiledBundleRegexes,
                nameRegexes: state.compiledNameRegexes,
                pathRegexes: applicablePathREs
            )
        }
    }

    /// 路径是否命中受保护路径(ItemType 3/5/6:字面量 + 目录前缀 + 正则)
    func isProtectedPath(_ path: String, allowLproj: Bool = false, allowAppInterior: Bool = false) -> Bool {
        let rawLow = path.lowercased()
        let low = rawLow.hasSuffix("/") ? String(rawLow.dropLast()) : rawLow
        return storage.withValue { state in
            guard state.isLoaded else { return true }
            // 1. 精确匹配受保护路径自身(防止将 ~/Library, ~/Library/Caches, /Library 等根容器作为待删目标整体删除)
            if state.protectedPathLiterals.contains(low) { return true }
            // 2. 检查子目录链：仅对非顶层根容器的受保护子树（如 ~/Library/Mail、~/Library/Caches/Adobe 等）生效，
            //    绝对严禁将 ~/Library、~/Library/Caches、~/Library/Containers 等顶级存储容器的子项阻断！
            let topContainers = Self.topLevelContainers
            var searchIndex = low.startIndex
            while searchIndex < low.endIndex,
                  let slashIndex = low[searchIndex...].firstIndex(of: "/") {
                if slashIndex > low.startIndex {
                    let prefix = String(low[..<slashIndex])
                    if !topContainers.contains(prefix) && state.protectedPathLiterals.contains(prefix) {
                        return true
                    }
                }
                searchIndex = low.index(after: slashIndex)
            }
            let lastComponent: String = {
                if let slash = path.lastIndex(of: "/") {
                    return String(path[path.index(after: slash)...])
                }
                return path
            }()
            let lastLower = lastComponent.lowercased()
            for re in state.compiledNameRegexes {
                if re.matches(lastComponent, lowerCandidate: lastLower) {
                    return true
                }
            }
            for re in state.compiledPathRegexes {
                if re.matches(path, lowerCandidate: low) {
                    return true
                }
            }
            return false
        }
    }

    /// 是否为受保护根目录(ItemType 9:~/Desktop 等用户内容区,整点命中)
    func isProtectedRoot(_ path: String) -> Bool {
        let rawLow = path.lowercased()
        let low = rawLow.hasSuffix("/") ? String(rawLow.dropLast()) : rawLow
        return protectedRoots.contains(low)
    }

}
