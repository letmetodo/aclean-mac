import Foundation
import Darwin

struct RuleStoreNames: Sendable {
    let database: String
    let state: String
    let temporaryPrefix: String
}

private struct RuleStoredFileIdentity: Equatable {
    let device: dev_t
    let inode: ino_t
    let bytes: off_t
    let modifiedSeconds: Int64
    let modifiedNanoseconds: Int64
    init(_ info: stat) {
        device = info.st_dev; inode = info.st_ino; bytes = info.st_size
        modifiedSeconds = Int64(info.st_mtimespec.tv_sec)
        modifiedNanoseconds = Int64(info.st_mtimespec.tv_nsec)
    }
}

/// Owns one persistent database. All other files created here are short-lived replacements.
final class RulePackageStore: @unchecked Sendable {
    let directory: URL
    let databaseURL: URL
    private let stateURL: URL
    private let names: RuleStoreNames
    private let seedSQL: String
    private let safety: Data
    private let limits: RuleUpdateLimits
    private let lock = NSRecursiveLock()
    private var state = RuleTrustState()
    private var ownedTemporary: URL?
    private var validatedIdentities: [String: RuleStoredFileIdentity] = [:]

    init(directory: URL, names: RuleStoreNames, seedSQL: String, safety: Data,
         limits: RuleUpdateLimits) throws {
        guard [names.database, names.state, names.temporaryPrefix].allSatisfy({
            !$0.isEmpty && !$0.contains("/") && $0 != "." && $0 != ".."
        }) else { throw RuleUpdateFailure.unsafeFile }
        self.directory = directory; self.names = names; self.seedSQL = seedSQL
        self.safety = safety; self.limits = limits
        databaseURL = directory.appendingPathComponent(names.database)
        stateURL = directory.appendingPathComponent(names.state)
        guard directory.standardizedFileURL.path == directory.resolvingSymlinksInPath().standardizedFileURL.path else {
            throw RuleUpdateFailure.unsafeFile
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        var info = stat()
        guard lstat(directory.path, &info) == 0, (info.st_mode & S_IFMT) == S_IFDIR,
              info.st_uid == getuid(), info.st_mode & 0o022 == 0 else { throw RuleUpdateFailure.unsafeFile }
        if exists(stateURL) {
            try checkFile(stateURL)
            let data = try Data(contentsOf: stateURL)
            guard data.count <= limits.metadataBytes * 8 else { throw RuleUpdateFailure.unsafeFile }
            do { state = try JSONDecoder().decode(RuleTrustState.self, from: data) }
            catch { throw RuleUpdateFailure.unsafeFile }
            for cached in [state.highestManifest, state.current, state.replacing].compactMap({ $0 }) {
                let verified = try RuleManifestReader.parse(bytes: cached.bytes, limits: limits)
                guard verified.manifest == cached.manifest else { throw RuleUpdateFailure.invalidManifest }
            }
        }
        if let name = state.temporaryName {
            guard name.hasPrefix(names.temporaryPrefix), !name.contains("/"), name != names.database else { throw RuleUpdateFailure.unsafeFile }
            let file = directory.appendingPathComponent(name)
            if exists(file) { try checkFile(file); try FileManager.default.removeItem(at: file) }
            state.temporaryName = nil; try save()
        }
    }
    var trust: RuleTrustState { lock.lock(); defer { lock.unlock() }; return state }
    private func exists(_ file: URL) -> Bool {
        var info = stat()
        return lstat(file.path, &info) == 0
    }
    private func checkFile(_ file: URL) throws {
        var info = stat()
        guard file.deletingLastPathComponent().standardizedFileURL.path == directory.standardizedFileURL.path,
              lstat(file.path, &info) == 0, (info.st_mode & S_IFMT) == S_IFREG,
              info.st_uid == getuid(), info.st_nlink == 1, info.st_mode & 0o022 == 0 else { throw RuleUpdateFailure.unsafeFile }
    }
    private func identity(_ file: URL) throws -> RuleStoredFileIdentity {
        try checkFile(file)
        var info = stat()
        guard lstat(file.path, &info) == 0 else { throw RuleUpdateFailure.unsafeFile }
        return RuleStoredFileIdentity(info)
    }
    private func save() throws {
        if exists(stateURL) { try checkFile(stateURL) }
        try JSONEncoder().encode(state).write(to: stateURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: stateURL.path)
    }
    func makeTemporary() throws -> URL {
        lock.lock(); defer { lock.unlock() }
        guard ownedTemporary == nil else { throw RuleUpdateFailure.busy }
        let file = directory.appendingPathComponent(names.temporaryPrefix + UUID().uuidString)
        let fd = open(file.path, O_CREAT | O_EXCL | O_RDWR | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { throw RuleUpdateFailure.unsafeFile }
        close(fd); ownedTemporary = file; state.temporaryName = file.lastPathComponent
        do { try save() } catch { try? FileManager.default.removeItem(at: file); ownedTemporary = nil; state.temporaryName = nil; throw error }
        return file
    }
    func discardTemporary() throws {
        lock.lock(); defer { lock.unlock() }
        guard let file = ownedTemporary else { return }
        if exists(file) {
            try checkFile(file); try FileManager.default.removeItem(at: file)
        }
        ownedTemporary = nil
        validatedIdentities.removeValue(forKey: file.path)
        state.temporaryName = nil; try save()
    }
    func validate(_ file: URL) throws -> RuleDatabaseSummary {
        lock.lock(); defer { lock.unlock() }
        let before = try identity(file)
        let summary = try RuleDatabaseValidator.validate(at: file, policyData: safety, limits: limits)
        guard try identity(file) == before else { throw RuleUpdateFailure.unsafeFile }
        validatedIdentities[file.path] = before
        return summary
    }
    func bootstrap() throws -> RuleDatabaseSummary {
        lock.lock(); defer { lock.unlock() }
        let seed = try makeTemporary()
        defer { try? discardTemporary() }
        try RuleDatabase.initialize(sql: seedSQL, at: seed)
        let baseline = try validate(seed)
        if exists(databaseURL) {
            try checkFile(databaseURL)
            if let summary = try? validate(databaseURL), !state.revokedDatabaseHashes.contains(summary.sha256) {
                if let recorded = [state.replacing, state.current].compactMap({ $0 }).first(where: { $0.manifest.databaseSHA256 == summary.sha256 }) {
                    state.current = recorded; state.replacing = nil; try save(); return summary
                }
                if summary.sha256 == baseline.sha256 {
                    state.current = nil; state.replacing = nil; state.initializedHash = baseline.sha256; try save(); return summary
                }
            }
        }
        guard !state.revokedDatabaseHashes.contains(baseline.sha256) else { throw RuleUpdateFailure.revoked }
        try replaceFile(seed)
        state.current = nil; state.replacing = nil; state.initializedHash = baseline.sha256
        try save(); return baseline
    }
    func accept(_ release: RuleReleaseManifest) throws {
        lock.lock(); defer { lock.unlock() }
        let verified = try RuleManifestReader.parse(bytes: release.bytes, limits: limits)
        guard verified.manifest == release.manifest else { throw RuleUpdateFailure.invalidManifest }
        var next = state
        try next.accept(release)
        let previous = state; state = next
        do { try save() } catch { state = previous; throw error }
    }
    func install(_ candidate: URL, release: RuleReleaseManifest) throws -> RuleDatabaseSummary {
        lock.lock(); defer { lock.unlock() }
        guard candidate == ownedTemporary else { throw RuleUpdateFailure.unsafeFile }
        let summary = try validate(candidate)
        guard summary.sha256 == release.manifest.databaseSHA256, summary.bytes == release.manifest.databaseBytes,
              summary.version == release.manifest.ruleVersion,
              !state.revokedDatabaseHashes.contains(summary.sha256) else { throw RuleUpdateFailure.invalidDatabase }
        guard state.highestManifest == release else { throw RuleUpdateFailure.rollback }
        if exists(databaseURL), let installed = try? validate(databaseURL), installed.version > summary.version {
            throw RuleUpdateFailure.rollback
        }
        state.replacing = release; try save()
        try replaceFile(candidate)
        state.current = release; state.replacing = nil
        // If this write fails, the replacement identity already persists for restart recovery.
        try? save()
        return summary
    }
    private func replaceFile(_ source: URL) throws {
        guard let validated = validatedIdentities[source.path], try identity(source) == validated else { throw RuleUpdateFailure.unsafeFile }
        if exists(databaseURL) { try checkFile(databaseURL) }
        let fd = open(source.path, O_RDONLY | O_NOFOLLOW)
        guard fd >= 0 else { throw RuleUpdateFailure.unsafeFile }
        let syncResult = fsync(fd); close(fd)
        guard syncResult == 0, rename(source.path, databaseURL.path) == 0 else { throw RuleUpdateFailure.unsafeFile }
        validatedIdentities.removeAll()
        ownedTemporary = nil
        state.temporaryName = nil
        let directoryFD = open(directory.path, O_RDONLY | O_NOFOLLOW)
        if directoryFD >= 0 { _ = fsync(directoryFD); close(directoryFD) }
    }
}
