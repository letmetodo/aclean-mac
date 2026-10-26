import Foundation
import SQLite3

/// Immutable, in-memory business data from the one current database.
struct RuleCatalog: Sendable {
    private var data: [String: [[String: String]]] = [:]
    private var sets: [String: [String: Set<String>]] = [:]
    private var selections: [String: Set<String>] = [:]
    private var parameters: [String: String] = [:]
    private var cachedBindings: [JunkDiscoveryBinding] = []
    private var bindingIndex: [String: JunkDiscoveryBinding] = [:]
    private var rawBindingIndex: [String: JunkDiscoveryBinding] = [:]
    private(set) var projectProofs: [String: Set<String>] = [:]
    init() {}
    init(database: OpaquePointer?) throws {
        for name in AppConfig.RuleUpdates.businessTables {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(database, "SELECT * FROM \(name)", -1, &statement, nil) == SQLITE_OK,
                  let statement else { continue }
            defer { sqlite3_finalize(statement) }
            var values: [[String: String]] = []
            var status = sqlite3_step(statement)
            while status == SQLITE_ROW {
                guard values.count < AppConfig.RuleUpdates.maximumRecords else { throw RuleUpdateFailure.invalidDatabase }
                var row: [String: String] = [:]
                for column in 0..<sqlite3_column_count(statement) {
                    let count = Int(sqlite3_column_bytes(statement, column))
                    guard count <= AppConfig.RuleUpdates.maximumStringBytes else { throw RuleUpdateFailure.invalidDatabase }
                    let key = String(cString: sqlite3_column_name(statement, column))
                    if let bytes = sqlite3_column_text(statement, column) {
                        guard let value = String(bytes: UnsafeBufferPointer(start: bytes, count: count), encoding: .utf8),
                              !value.contains("\0") else { throw RuleUpdateFailure.invalidDatabase }
                        row[key] = value
                    } else { row[key] = "" }
                }
                values.append(row); status = sqlite3_step(statement)
            }
            guard status == SQLITE_DONE else { throw RuleUpdateFailure.invalidDatabase }
            data[name] = values
        }
        for (table, rows) in data {
            for row in rows { for (column, value) in row { sets[table, default: [:]][column, default: []].insert(value) } }
        }
        for row in rows("cm_rule_selection") {
            guard let id = row["rule_id"] else { continue }
            for (column, value) in row where value == "1" { selections[column, default: []].insert(id) }
        }
        for row in rows("cm_rule_meta") { if let key = row["key"], let value = row["value"] { parameters[key] = value } }
        for row in rows("cm_project_artifact") { if let name = row["artifact_name"] { projectProofs[name] = [] } }
        for row in rows("cm_project_artifact_proof") {
            if let name = row["artifact_name"], let proof = row["proof_path"] { projectProofs[name, default: []].insert(proof) }
        }
        cachedBindings = makeBindings()
        var index: [String: JunkDiscoveryBinding] = [:]
        var rawIndex: [String: JunkDiscoveryBinding] = [:]
        var ambiguous = Set<String>()
        for b in cachedBindings {
            rawIndex[JunkDiscoveryRegistry.bindingKey(ruleID: b.ruleID, pathTemplate: b.pathTemplate)] = b
            let key = JunkDiscoveryRegistry.bindingKey(ruleID: b.ruleID, pathTemplate: AuthoredRules.canonicalRulePathTemplate(b.pathTemplate))
            if let existing = index[key], existing.pathTemplate != b.pathTemplate { ambiguous.insert(key) }
            else { index[key] = b }
        }
        for key in ambiguous { index.removeValue(forKey: key) }
        bindingIndex = index
        rawBindingIndex = rawIndex
    }
    func rows(_ table: String) -> [[String: String]] { data[table] ?? [] }
    func values(_ table: String, _ column: String) -> Set<String> {
        sets[table]?[column] ?? []
    }
    func parameter(_ key: String) -> String? { parameters[key] }
    func selectedRules(_ column: String) -> Set<String> {
        selections[column] ?? []
    }
    var bindings: [JunkDiscoveryBinding] { cachedBindings }
    private func makeBindings() -> [JunkDiscoveryBinding] {
        rows("cm_discovery_binding").compactMap { row in
            guard let id = row["rule_id"], let path = row["path_template"], let scanner = row["scanner_id"],
                  let rawKind = row["discovery_kind"], let kind = DiscoveryKind(rawValue: rawKind),
                  let rawStatus = row["status"], let status = DiscoveryStatus(rawValue: rawStatus) else { return nil }
            return JunkDiscoveryBinding(ruleID: id, pathTemplate: path, scannerID: scanner, discoveryKind: kind,
                                        status: status, reason: status == .active ? nil : L10n.localized(.ruleDatabaseUnavailableTitle))
        }
    }
    func binding(ruleID: String, path: String) -> JunkDiscoveryBinding? {
        if let direct = rawBindingIndex[JunkDiscoveryRegistry.bindingKey(ruleID: ruleID, pathTemplate: path)] {
            return direct
        }
        let canonical = AuthoredRules.canonicalRulePathTemplate(path)
        return bindingIndex[JunkDiscoveryRegistry.bindingKey(ruleID: ruleID, pathTemplate: canonical)]
    }
}
