import Foundation
import CryptoKit
import CoreFoundation

enum RuleUpdateFailure: Error, Equatable, Sendable {
    case notConfigured, invalidJSON, invalidManifest
    case rollback, invalidDatabase, unsafeFile, revoked, busy, cancelled
}

struct RuleUpdateLimits: Sendable {
    let metadataBytes: Int
    let databaseBytes: Int
    let jsonDepth: Int
    let databaseName: String
    let maximumRecords: Int
    let maximumStringBytes: Int
    let queryInstructions: Int32
}

struct RuleManifest: Codable, Equatable, Sendable {
    let formatVersion: Int64
    let ruleVersion: Int64
    let databasePath: String
    let databaseBytes: Int
    let databaseSHA256: String
    let disabledRuleIDs: [String]
    let revokedDatabaseHashes: [String]
}

struct RuleReleaseManifest: Codable, Equatable, Sendable {
    let manifest: RuleManifest
    let bytes: Data
}

enum RuleDigest {
    static func sha256(_ bytes: Data) -> String {
        SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }
    static func isSHA256(_ value: String) -> Bool {
        value.utf8.count == SHA256.byteCount * 2
            && value.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) }
    }
}

/// Rejects duplicate keys (including escaped equivalents) before Foundation decoding.
private final class RuleJSONReader {
    private let bytes: [UInt8]
    private let maximumDepth: Int
    private var position = 0
    init(_ data: Data, depth: Int) { bytes = Array(data); maximumDepth = depth }
    func validate() throws {
        try value(depth: 0); whitespace()
        guard position == bytes.count else { throw RuleUpdateFailure.invalidJSON }
    }
    private func whitespace() {
        while position < bytes.count && [9, 10, 13, 32].contains(bytes[position]) { position += 1 }
    }
    private func consume(_ byte: UInt8) -> Bool {
        whitespace()
        guard position < bytes.count && bytes[position] == byte else { return false }
        position += 1; return true
    }
    private func string() throws -> String {
        whitespace(); let start = position
        guard position < bytes.count && bytes[position] == 34 else { throw RuleUpdateFailure.invalidJSON }
        position += 1
        while position < bytes.count {
            let byte = bytes[position]; position += 1
            if byte == 92 {
                guard position < bytes.count else { throw RuleUpdateFailure.invalidJSON }
                position += 1
            } else if byte == 34 {
                do { return try JSONDecoder().decode(String.self, from: Data(bytes[start..<position])) }
                catch { throw RuleUpdateFailure.invalidJSON }
            }
        }
        throw RuleUpdateFailure.invalidJSON
    }
    private func value(depth: Int) throws {
        guard depth <= maximumDepth else { throw RuleUpdateFailure.invalidJSON }
        whitespace()
        guard position < bytes.count else { throw RuleUpdateFailure.invalidJSON }
        switch bytes[position] {
        case 123:
            position += 1; var keys = Set<String>()
            if consume(125) { return }
            repeat {
                let key = try string()
                guard keys.insert(key).inserted, consume(58) else { throw RuleUpdateFailure.invalidJSON }
                try value(depth: depth + 1)
                if consume(125) { return }
                guard consume(44) else { throw RuleUpdateFailure.invalidJSON }
            } while true
        case 91:
            position += 1
            if consume(93) { return }
            repeat {
                try value(depth: depth + 1)
                if consume(93) { return }
                guard consume(44) else { throw RuleUpdateFailure.invalidJSON }
            } while true
        case 34: _ = try string()
        default:
            let start = position
            while position < bytes.count && ![9, 10, 13, 32, 44, 93, 125].contains(bytes[position]) { position += 1 }
            guard position > start else { throw RuleUpdateFailure.invalidJSON }
            do { _ = try JSONSerialization.jsonObject(with: Data(bytes[start..<position]), options: .fragmentsAllowed) }
            catch { throw RuleUpdateFailure.invalidJSON }
        }
    }
}

enum RuleManifestReader {
    static func strictJSON(_ bytes: Data, limits: RuleUpdateLimits) throws {
        guard bytes.count <= limits.metadataBytes else { throw RuleUpdateFailure.invalidJSON }
        try RuleJSONReader(bytes, depth: limits.jsonDepth).validate()
    }
    static func parse(bytes: Data, limits: RuleUpdateLimits) throws -> RuleReleaseManifest {
        try strictJSON(bytes, limits: limits)
        guard let object = try JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              Set(object.keys) == Set(["formatVersion", "ruleVersion", "databasePath", "databaseBytes", "databaseSHA256", "disabledRuleIDs", "revokedDatabaseHashes"]) else { throw RuleUpdateFailure.invalidManifest }
        for name in ["formatVersion", "ruleVersion", "databaseBytes"] {
            guard let number = object[name] as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID(),
                  !["d", "f"].contains(String(cString: number.objCType)),
                  Int64(number.stringValue) != nil else { throw RuleUpdateFailure.invalidManifest }
        }
        let manifest: RuleManifest
        do { manifest = try JSONDecoder().decode(RuleManifest.self, from: bytes) }
        catch { throw RuleUpdateFailure.invalidManifest }
        guard manifest.formatVersion == 1, manifest.ruleVersion > 0,
              manifest.databasePath == limits.databaseName,
              manifest.databaseBytes > 0, manifest.databaseBytes <= limits.databaseBytes,
              RuleDigest.isSHA256(manifest.databaseSHA256),
              manifest.disabledRuleIDs.count <= limits.maximumRecords,
              manifest.revokedDatabaseHashes.count <= limits.maximumRecords,
              manifest.disabledRuleIDs.allSatisfy({ !$0.isEmpty && $0.utf8.count <= limits.maximumStringBytes }),
              manifest.revokedDatabaseHashes.allSatisfy(RuleDigest.isSHA256) else { throw RuleUpdateFailure.invalidManifest }
        return RuleReleaseManifest(manifest: manifest, bytes: bytes)
    }
}

struct RuleTrustState: Codable, Sendable {
    var highestManifest: RuleReleaseManifest?
    var highestRuleVersion: Int64 { highestManifest?.manifest.ruleVersion ?? 0 }
    var disabledRuleIDs = Set<String>()
    var revokedDatabaseHashes = Set<String>()
    var current: RuleReleaseManifest?
    var replacing: RuleReleaseManifest?
    var initializedHash: String?
    var temporaryName: String?

    mutating func accept(_ release: RuleReleaseManifest) throws {
        let incoming = release.manifest
        if let highest = highestManifest {
            guard incoming.ruleVersion >= highest.manifest.ruleVersion else { throw RuleUpdateFailure.rollback }
            if incoming.ruleVersion == highest.manifest.ruleVersion && incoming != highest.manifest {
                throw RuleUpdateFailure.rollback
            }
        }
        highestManifest = release
        disabledRuleIDs.formUnion(incoming.disabledRuleIDs)
        revokedDatabaseHashes.formUnion(incoming.revokedDatabaseHashes)
    }
}
