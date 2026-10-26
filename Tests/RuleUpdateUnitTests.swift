import Foundation

@main
struct RuleUpdateUnitTests {
    static let limits = RuleUpdateLimits(metadataBytes: 262144, databaseBytes: 10485760, jsonDepth: 32,
        databaseName: "cleanmate_rules.db", maximumRecords: 100000, maximumStringBytes: 4096, queryInstructions: 1000000)
    static func check(_ value: @autoclosure () throws -> Bool) throws {
        if try !value() { throw RuleUpdateFailure.invalidManifest }
    }
    static func encoded(version: Int64 = 4, hash: String = String(repeating: "a", count: 64), size: Int = 512) throws -> Data {
        try JSONEncoder().encode(RuleManifest(formatVersion: 1, ruleVersion: version,
            databasePath: "cleanmate_rules.db", databaseBytes: size, databaseSHA256: hash,
            disabledRuleIDs: [], revokedDatabaseHashes: []))
    }
    static func store(_ folder: URL) throws -> RulePackageStore {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return try RulePackageStore(directory: folder,
            names: RuleStoreNames(database: "cleanmate_rules.db", state: "update-state.json", temporaryPrefix: ".rules-download-"),
            seedSQL: String(contentsOf: root.appendingPathComponent("Resources/cleanmate_authored_rules.sql"), encoding: .utf8),
            safety: Data(contentsOf: root.appendingPathComponent("Resources/rule_safety.json")), limits: limits)
    }
    static func main() async throws {
        switch CommandLine.arguments.dropFirst().first ?? "manifest" {
        case "manifest":
            let data = try encoded()
            try check(try RuleManifestReader.parse(bytes: data, limits: limits).manifest.ruleVersion == 4)
            let badPath = Data(String(decoding: data, as: UTF8.self).replacingOccurrences(of: "cleanmate_rules.db", with: "../other.db").utf8)
            do { _ = try RuleManifestReader.parse(bytes: badPath, limits: limits); throw CocoaError(.fileReadUnknown) }
            catch RuleUpdateFailure.invalidManifest {}
        case "duplicates":
            for value in [#"{"a":1,"a":2}"#, #"{"a":1,"\u0061":2}"#, #"{"x":{"b":0,"b":1}}"#] {
                do { try RuleManifestReader.strictJSON(Data(value.utf8), limits: limits); throw CocoaError(.fileReadUnknown) }
                catch RuleUpdateFailure.invalidJSON {}
            }
        case "invalid-manifest":
            let original = String(decoding: try encoded(), as: UTF8.self)
            for value in ["true", "1.5", "4.0", "4e0", "-1", "9223372036854775808"] {
                let bad = Data(original.replacingOccurrences(of: "\"ruleVersion\":4", with: "\"ruleVersion\":" + value).utf8)
                do { _ = try RuleManifestReader.parse(bytes: bad, limits: limits); throw CocoaError(.fileReadUnknown) }
                catch RuleUpdateFailure.invalidManifest {}
            }
        case "rollback":
            var state = RuleTrustState()
            let release = try RuleManifestReader.parse(bytes: encoded(), limits: limits)
            try state.accept(release); try state.accept(release)
            for data in [try encoded(version: 3), try encoded(hash: String(repeating: "b", count: 64))] {
                let invalid = try RuleManifestReader.parse(bytes: data, limits: limits)
                do { try state.accept(invalid); throw CocoaError(.fileReadUnknown) } catch RuleUpdateFailure.rollback {}
            }
        case "single-store":
            let folder = URL(fileURLWithPath: "/private/tmp/cleanmate-store-case-" + UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let local = try store(folder)
            let summary = try local.bootstrap()
            try check(summary.version == 1)
            try check(Set(try FileManager.default.contentsOfDirectory(atPath: folder.path)) == ["cleanmate_rules.db", "update-state.json"])
            try check(try local.bootstrap().sha256 == summary.sha256)
        case "install-recovery":
            let folder = URL(fileURLWithPath: "/private/tmp/cleanmate-store-case-" + UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let local = try store(folder)
            let baseline = try local.bootstrap()
            let baselineBytes = try Data(contentsOf: local.databaseURL)
            let sql = try String(contentsOfFile: "Resources/cleanmate_authored_rules.sql", encoding: .utf8)
            let candidate = try local.makeTemporary()
            try RuleDatabase.initialize(sql: sql + "\nUPDATE cm_rule_meta SET value='2' WHERE key='rule_version';", at: candidate)
            let summary = try local.validate(candidate)
            let replacement = try Data(contentsOf: candidate)
            let release = try RuleManifestReader.parse(bytes: encoded(version: 2, hash: summary.sha256, size: summary.bytes), limits: limits)
            try local.accept(release); _ = try local.install(candidate, release: release)
            try check(try store(folder).bootstrap().sha256 == summary.sha256)
            try Data("corruption".utf8).write(to: local.databaseURL)
            let recovered = try store(folder)
            try check(try recovered.bootstrap().sha256 == baseline.sha256)
            try check(recovered.trust.highestRuleVersion == 2)
            try recovered.accept(release)
            try replacement.write(to: recovered.databaseURL)
            var interrupted = recovered.trust
            interrupted.replacing = release; interrupted.current = nil
            interrupted.temporaryName = ".rules-download-crashed"
            let stateFile = folder.appendingPathComponent("update-state.json")
            try JSONEncoder().encode(interrupted).write(to: stateFile)
            try check(try store(folder).bootstrap().sha256 == summary.sha256)
            try baselineBytes.write(to: recovered.databaseURL)
            let pending = folder.appendingPathComponent(".rules-download-crashed")
            try replacement.write(to: pending)
            interrupted.current = nil
            try JSONEncoder().encode(interrupted).write(to: stateFile)
            try check(try store(folder).bootstrap().sha256 == baseline.sha256)
            try check(!FileManager.default.fileExists(atPath: pending.path))
            try check(Set(try FileManager.default.contentsOfDirectory(atPath: folder.path)) == ["cleanmate_rules.db", "update-state.json"])
        case "task-gate":
            let gate = RuleTaskGate()
            try gate.activate(version: 1, hash: "a") {}
            let old = gate.identity
            do {
                let lease = gate.begin(); defer { withExtendedLifetime(lease) {} }
                do { try gate.activate(version: 2, hash: "b") {}; throw RuleUpdateFailure.invalidManifest }
                catch RuleUpdateFailure.busy {}
                try check(gate.allows(old))
            }
            try gate.activate(version: 2, hash: "b") {}
            try check(!gate.allows(old))
            gate.updateRestrictions(disabled: ["JC.TEST"], revoked: [])
            try check(!gate.allows(gate.identity, ruleID: "JC.TEST"))
        case "download-limits":
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [RuleHTTPFixture.self]
            let http = RuleHTTPClient(origin: URL(string: "https://rules.invalid/")!, configuration: configuration)
            let bytes = try await http.fetch("latest.json", maximumBytes: 64)
            try check(bytes.count == 16)
            do { _ = try await http.fetch("latest.json", maximumBytes: 8); throw CocoaError(.fileReadUnknown) }
            catch RuleUpdateFailure.invalidManifest {}
            do { _ = try await http.fetch("../other", maximumBytes: 64); throw CocoaError(.fileReadUnknown) }
            catch RuleUpdateFailure.invalidManifest {}
        case "database-text":
            let file = URL(fileURLWithPath: "/private/tmp/cleanmate-text-case-" + UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: file) }
            try RuleDatabase.initialize(sql: "CREATE TABLE entries(id TEXT PRIMARY KEY);", at: file)
            for hex in ["610062", "ff"] {
                try RuleDatabase.initialize(sql: "DELETE FROM entries; INSERT INTO entries VALUES(CAST(X'\(hex)' AS TEXT));", at: file)
                do { _ = try RuleDatabase(url: file, limits: limits).table("entries"); throw CocoaError(.fileReadUnknown) }
                catch RuleUpdateFailure.invalidDatabase {}
            }
        case "live-github":
            let origin = URL(string: CommandLine.arguments[2])!
            let http = RuleHTTPClient(origin: origin, configuration: .ephemeral)
            let release = try RuleManifestReader.parse(bytes: await http.fetch("latest.json", maximumBytes: limits.metadataBytes), limits: limits)
            if CommandLine.arguments.count > 3 {
                try release.bytes.write(to: URL(fileURLWithPath: CommandLine.arguments[3]))
            }
            let bytes = try await http.fetch("cleanmate_rules.db", maximumBytes: limits.databaseBytes)
            try check(bytes.count == release.manifest.databaseBytes && RuleDigest.sha256(bytes) == release.manifest.databaseSHA256)
            let folder = URL(fileURLWithPath: "/private/tmp/cleanmate-live-rule-" + UUID().uuidString)
            defer { try? FileManager.default.removeItem(at: folder) }
            let local = try store(folder); _ = try local.bootstrap(); try local.accept(release)
            let candidate = try local.makeTemporary(); try bytes.write(to: candidate)
            try check(try local.install(candidate, release: release).version == release.manifest.ruleVersion)
            print("Public GitHub rules: version=\(release.manifest.ruleVersion), bytes=\(bytes.count), sha256=\(RuleDigest.sha256(bytes))")
        default: throw RuleUpdateFailure.invalidManifest
        }
        print("Rule update single case passed")
    }
}

private final class RuleHTTPFixture: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(repeating: 1, count: 16))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
