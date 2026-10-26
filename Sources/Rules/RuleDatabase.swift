import Foundation
import SQLite3

/// A bounded, short-lived connection. Rule consumers retain values, never SQLite handles.
final class RuleDatabase {
    private(set) var handle: OpaquePointer?
    private let limits: RuleUpdateLimits
    init(url: URL, limits: RuleUpdateLimits) throws {
        self.limits = limits
        guard sqlite3_open_v2(url.path, &handle, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK else {
            sqlite3_close(handle); handle = nil; throw RuleUpdateFailure.invalidDatabase
        }
        // Apple's SQLite omits the extension-loading API; never register extensions and
        // additionally deny the SQL entry point even on a runtime which exposes it.
        sqlite3_set_authorizer(handle, { _, action, _, function, _, _ in
            if action == SQLITE_FUNCTION, let function, String(cString: function).lowercased() == "load_extension" { return SQLITE_DENY }
            return SQLITE_OK
        }, nil)
        sqlite3_limit(handle, SQLITE_LIMIT_LENGTH, Int32(clamping: limits.databaseBytes))
        sqlite3_limit(handle, SQLITE_LIMIT_SQL_LENGTH, Int32(clamping: limits.databaseBytes))
        sqlite3_progress_handler(handle, limits.queryInstructions, { _ in 1 }, nil)
        guard sqlite3_exec(handle, "PRAGMA trusted_schema=OFF; PRAGMA query_only=ON; PRAGMA mmap_size=0;", nil, nil, nil) == SQLITE_OK else {
            sqlite3_close(handle); handle = nil; throw RuleUpdateFailure.invalidDatabase
        }
    }
    deinit { sqlite3_close(handle) }
    func rows(_ sql: String) throws -> [[String: Any]] {
        var raw: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &raw, nil) == SQLITE_OK, let statement = raw else {
            throw RuleUpdateFailure.invalidDatabase
        }
        defer { sqlite3_finalize(statement) }
        var result: [[String: Any]] = []
        var step = sqlite3_step(statement)
        while step == SQLITE_ROW {
            guard result.count < limits.maximumRecords else { throw RuleUpdateFailure.invalidDatabase }
            var row: [String: Any] = [:]
            for column in 0..<sqlite3_column_count(statement) {
                let name = String(cString: sqlite3_column_name(statement, column))
                switch sqlite3_column_type(statement, column) {
                case SQLITE_NULL: row[name] = NSNull()
                case SQLITE_INTEGER: row[name] = NSNumber(value: sqlite3_column_int64(statement, column))
                case SQLITE_FLOAT:
                    let value = sqlite3_column_double(statement, column)
                    guard value.isFinite else { throw RuleUpdateFailure.invalidDatabase }
                    row[name] = NSNumber(value: value)
                case SQLITE_TEXT:
                    let count = Int(sqlite3_column_bytes(statement, column))
                    guard count <= limits.maximumStringBytes, let bytes = sqlite3_column_text(statement, column),
                          let value = String(bytes: UnsafeBufferPointer(start: bytes, count: count), encoding: .utf8),
                          !value.contains("\0") else { throw RuleUpdateFailure.invalidDatabase }
                    row[name] = value
                default: throw RuleUpdateFailure.invalidDatabase
                }
            }
            result.append(row); step = sqlite3_step(statement)
        }
        guard step == SQLITE_DONE else { throw RuleUpdateFailure.invalidDatabase }
        return result
    }
    func table(_ name: String) throws -> [[String: Any]] {
        guard !name.isEmpty, name.utf8.allSatisfy({ (97...122).contains($0) || (48...57).contains($0) || $0 == 95 }) else {
            throw RuleUpdateFailure.invalidDatabase
        }
        return try rows("SELECT * FROM \(name)")
    }
    static func initialize(sql: String, at url: URL) throws {
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nil) == SQLITE_OK else {
            sqlite3_close(db); throw RuleUpdateFailure.invalidDatabase
        }
        defer { sqlite3_close(db) }
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw RuleUpdateFailure.invalidDatabase }
    }
}

struct RuleDatabaseSummary: Sendable {
    let version: Int64
    let sha256: String
    let bytes: Int
}

enum RuleDatabaseValidator {
    static func validate(at url: URL, policyData: Data, limits: RuleUpdateLimits) throws -> RuleDatabaseSummary {
        guard let policy = try JSONSerialization.jsonObject(with: policyData) as? [String: Any],
              let schema = policy["schema"] as? [String: String] else { throw RuleUpdateFailure.invalidDatabase }
        let database = try RuleDatabase(url: url, limits: limits)
        guard try database.rows("PRAGMA quick_check").first?["quick_check"] as? String == "ok",
              try database.rows("PRAGMA foreign_key_check").isEmpty else { throw RuleUpdateFailure.invalidDatabase }
        let objects = try database.rows("SELECT type,name,sql FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'")
        var found: [String: String] = [:]
        for object in objects {
            guard object["type"] as? String == "table", let name = object["name"] as? String,
                  let sql = object["sql"] as? String else { throw RuleUpdateFailure.invalidDatabase }
            found[name] = sql
        }
        guard found == schema else { throw RuleUpdateFailure.invalidDatabase }
        var tables: [String: [[String: Any]]] = [:]
        for name in schema.keys { tables[name] = try database.table(name) }
        func required(_ table: String, _ key: String) throws {
            guard let expected = policy[key] as? [[String: Any]], let actual = tables[table] else { throw RuleUpdateFailure.invalidDatabase }
            for row in expected {
                guard actual.contains(where: { NSDictionary(dictionary: $0).isEqual(to: row) }) else { throw RuleUpdateFailure.invalidDatabase }
            }
        }
        try required("cm_global_guard", "requiredGlobalGuards")
        try required("cm_protected_path", "requiredProtectedPaths")
        try required("cm_junk_rule_lock", "requiredRuleLocks")
        try required("cm_cache_profile_lock", "requiredProfileLocks")
        try required("cm_junk_rule_exclude", "requiredExclusions")
        let ranks = ["L1": 1, "L2": 2, "L3": 3, "L4": 4]
        let rules = Dictionary(uniqueKeysWithValues: (tables["cm_junk_rule"] ?? []).compactMap { row in
            (row["id"] as? String).map { ($0, row) }
        })
        guard !rules.isEmpty, let floors = policy["ruleLimits"] as? [[String: Any]],
              let predicates = policy["predicates"] as? [String], let scanners = policy["scanners"] as? [String],
              let conditions = policy["requiredConditions"] as? [String: String] else { throw RuleUpdateFailure.invalidDatabase }
        for floor in floors {
            guard let id = floor["ruleID"] as? String else { throw RuleUpdateFailure.invalidDatabase }
            guard let rule = rules[id] else { continue }
            guard let tier = rule["tier"] as? String, let minimum = floor["minimumTier"] as? String,
                  let rank = ranks[tier], let minimumRank = ranks[minimum], rank >= minimumRank,
                  let actions = floor["allowedActions"] as? [String], let action = rule["action"] as? String,
                  actions.contains(action), (floor["activationAllowed"] as? Bool == true || rule["status"] as? String != "active"),
                  (rule["predicate"] as? String ?? "") == conditions[id] else { throw RuleUpdateFailure.invalidDatabase }
        }
        var bound = Set<String>()
        var canonicalBindings = Set<String>()
        let capabilities = policy["bindingCapabilities"] as? [String: [String]] ?? [:]
        let pathScopes = policy["pathScopes"] as? [String: [String]] ?? [:]
        let newScanners = policy["newRuleScanners"] as? [String] ?? []
        for binding in tables["cm_discovery_binding"] ?? [] {
            guard let id = binding["rule_id"] as? String, let rule = rules[id],
                  let scanner = binding["scanner_id"] as? String, scanners.contains(scanner),
                  let path = binding["path_template"] as? String, path.utf8.count <= limits.maximumStringBytes,
                  !path.contains("\0"), !path.split(separator: "/", omittingEmptySubsequences: false).contains("..") else {
                throw RuleUpdateFailure.invalidDatabase
            }
            let canonical = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard canonicalBindings.insert(id + ":" + canonical).inserted else { throw RuleUpdateFailure.invalidDatabase }
            bound.insert(id)
            if binding["status"] as? String == "active" {
                let capability = scanner + ":" + (binding["discovery_kind"] as? String ?? "")
                guard capabilities[id].map({ $0.contains(capability) }) ?? newScanners.contains(scanner),
                      path.isEmpty || (pathScopes[scanner] ?? []).contains(where: {
                          path == $0 || path.hasPrefix($0 + "/")
                      }) else { throw RuleUpdateFailure.invalidDatabase }
                guard rule["status"] as? String == "active", ["L1", "L2"].contains(rule["tier"] as? String ?? ""),
                      rule["action"] as? String != "read_only", !["inventoryOnly", "rejected", "deferred"].contains(scanner),
                      predicates.contains(rule["predicate"] as? String ?? "") else { throw RuleUpdateFailure.invalidDatabase }
            }
        }
        guard bound == Set(rules.keys) else { throw RuleUpdateFailure.invalidDatabase }
        let patterns = policy["versionPatterns"] as? [String: String] ?? [:]
        for row in tables["cm_version_cache"] ?? [] {
            guard (row["keep_latest"] as? NSNumber)?.intValue ?? 0 >= 2,
                  (row["min_age_hours"] as? NSNumber)?.intValue ?? 0 >= 168,
                  let family = row["family"] as? String, let pattern = row["name_pattern"] as? String,
                  patterns[family] == pattern else { throw RuleUpdateFailure.invalidDatabase }
        }
        for (table, key, idKey) in [("cm_performance_task", "maintenanceLimits", "task_id"), ("cm_uninstall_template", "uninstallLimits", "id")] {
            let actual = tables[table] ?? []
            for floor in policy[key] as? [[String: Any]] ?? [] {
                guard let id = floor[idKey] as? String else { throw RuleUpdateFailure.invalidDatabase }
                guard let row = actual.first(where: { $0[idKey] as? String == id }) else { continue }
                guard (row["default_selected"] as? NSNumber)?.intValue ?? 1 <= (floor["default_selected"] as? NSNumber)?.intValue ?? 0 else {
                    throw RuleUpdateFailure.invalidDatabase
                }
                if table == "cm_performance_task" {
                    let risks = ["safe": 0, "caution": 1, "disruptive": 2, "forbidden": 3]
                    guard (row["needs_admin"] as? NSNumber) == (floor["needs_admin"] as? NSNumber),
                          (risks[row["risk"] as? String ?? ""] ?? -1) >= (risks[floor["risk"] as? String ?? ""] ?? 4),
                          (row["reversible"] as? NSNumber)?.intValue ?? 1 <= (floor["reversible"] as? NSNumber)?.intValue ?? 0,
                          floor["status"] as? String == "allowed" || row["status"] as? String != "allowed" else { throw RuleUpdateFailure.invalidDatabase }
                } else {
                    guard (row["execute"] as? NSNumber)?.intValue ?? 1 <= (floor["execute"] as? NSNumber)?.intValue ?? 0,
                          row["domain"] as? String == floor["domain"] as? String,
                          (ranks[row["tier"] as? String ?? ""] ?? 0) >= (ranks[floor["tier"] as? String ?? ""] ?? 5) else {
                        throw RuleUpdateFailure.invalidDatabase
                    }
                }
            }
        }
        let meta = Dictionary(uniqueKeysWithValues: (tables["cm_rule_meta"] ?? []).compactMap { row -> (String, String)? in
            guard let key = row["key"] as? String, let value = row["value"] as? String else { return nil }; return (key, value)
        })
        guard meta["schema_version"] == "1", let rawVersion = meta["rule_version"], let version = Int64(rawVersion), version > 0 else {
            throw RuleUpdateFailure.invalidDatabase
        }
        guard let bounds = policy["projectBounds"] as? [String: Any],
              let minimumAge = bounds["minimumAgeDays"] as? Int,
              let maximumDepth = bounds["maximumScanDepth"] as? Int,
              let maximumManifest = bounds["maximumManifestSearchDepth"] as? Int,
              let age = Int(meta["project_min_age_days"] ?? ""), age >= minimumAge,
              let depth = Int(meta["project_max_depth"] ?? ""), depth > 0, depth <= maximumDepth,
              let manifestDepth = Int(meta["project_manifest_search_depth"] ?? ""), manifestDepth > 0, manifestDepth <= maximumManifest else {
            throw RuleUpdateFailure.invalidDatabase
        }
        for floor in policy["projectArtifactFloors"] as? [[String: Any]] ?? [] {
            guard let row = (tables["cm_project_artifact"] ?? []).first(where: { $0["artifact_name"] as? String == floor["artifact_name"] as? String }) else { continue }
            guard row["proof_kind"] as? String == floor["proof_kind"] as? String,
                  (row["candidate"] as? NSNumber)?.intValue ?? 1 <= (floor["candidate"] as? NSNumber)?.intValue ?? 0,
                  (row["generic_name"] as? NSNumber)?.intValue ?? 0 >= (floor["generic_name"] as? NSNumber)?.intValue ?? 1 else {
                throw RuleUpdateFailure.invalidDatabase
            }
        }
        let bytes = try Data(contentsOf: url)
        guard bytes.count <= limits.databaseBytes else { throw RuleUpdateFailure.invalidDatabase }
        return RuleDatabaseSummary(version: version, sha256: RuleDigest.sha256(bytes), bytes: bytes.count)
    }
}
