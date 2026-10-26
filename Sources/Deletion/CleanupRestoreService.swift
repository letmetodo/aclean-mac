import Foundation

/// Captured at the mutation boundary; paths are never reconstructed from Trash names.
struct CleanupRestoreItem: Codable, Sendable, Equatable, Identifiable {
    var id: String { originalURL.path + "\n" + trashURL.path }
    let originalURL: URL
    let trashURL: URL
    let identity: FileIdentity?
    let bytes: Int64

    init(originalURL: URL, trashURL: URL, identity: FileIdentity?, bytes: Int64) {
        self.originalURL = originalURL.standardizedFileURL
        self.trashURL = trashURL.standardizedFileURL
        self.identity = identity
        self.bytes = bytes
    }

    init(originalURL: URL, trashURL: URL, bytes: Int64) {
        self.originalURL = originalURL.standardizedFileURL
        self.trashURL = trashURL.standardizedFileURL
        self.identity = FileIdentity.capture(from: trashURL)
        self.bytes = bytes
    }
}

struct CleanupRestoreResult: Sendable {
    var restoredIDs: Set<String> = []
    var restoredBytes: Int64 = 0
    var failedPaths: [String] = []
}

enum CleanupRestoreService {
    private static let lock = NSLock()

    static func restore(_ items: [CleanupRestoreItem], excluding restored: Set<String> = []) -> CleanupRestoreResult {
        lock.lock()
        defer { lock.unlock() }
        var result = CleanupRestoreResult()
        let fm = FileManager.default
        let roots = Cleaner.authorizedTrashRootsOverride ?? FileUtil.authorizedTrashRoots()
        for item in items where !restored.contains(item.id) {
            guard let identity = item.identity,
                  roots.contains(where: { FileUtil.isStrictDescendant(item.trashURL, of: $0) }),
                  identity.matches(url: item.trashURL),
                  !SymlinkGuard.hasSymlinkEscape(url: item.trashURL),
                  item.originalURL.path != "/",
                  FileIdentity.capture(from: item.originalURL) == nil,
                  !SymlinkGuard.hasSymlinkEscape(url: item.originalURL) else {
                result.failedPaths.append(item.originalURL.path)
                continue
            }
            do {
                try fm.createDirectory(at: item.originalURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                guard identity.matches(url: item.trashURL),
                      !SymlinkGuard.hasSymlinkEscape(url: item.originalURL),
                      FileIdentity.capture(from: item.originalURL) == nil else {
                    result.failedPaths.append(item.originalURL.path)
                    continue
                }
                try fm.moveItem(at: item.trashURL, to: item.originalURL)
                result.restoredIDs.insert(item.id)
                result.restoredBytes += item.bytes
            } catch {
                result.failedPaths.append(item.originalURL.path)
            }
        }
        return result
    }
}
