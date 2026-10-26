import Foundation

// ============================================================
//  UninstallerUndoManager —— 应用卸载撤销与批次恢复管理器
//
//  安全契约：
//    1. 仅对 actionCategory == .movedToTrash 且带有 uninstallContext 的项目建立撤销快照；
//    2. 还原前实行双向存在性校验（废纸篓文件必须存在，原目标路径不得已被占用）；
//    3. 原路移回时先确保父目录存在，发生失败自动回滚；
//    4. 本地快照保留最大批次与超时清理。
// ============================================================

public struct UninstallUndoItem: Codable, Sendable, Equatable {
    public let originalPath: String
    public let trashPath: String
    public let size: Int64
    public let isAppBody: Bool
    let trashIdentity: FileIdentity?

    public init(originalPath: String, trashPath: String, size: Int64, isAppBody: Bool) {
        self.originalPath = originalPath
        self.trashPath = trashPath
        self.size = size
        self.isAppBody = isAppBody
        self.trashIdentity = FileIdentity.capture(from: URL(fileURLWithPath: trashPath))
    }
}

public struct UninstallUndoBatch: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let appName: String
    public let bundleID: String
    public let timestamp: Date
    public let items: [UninstallUndoItem]
    public let totalSize: Int64

    public init(
        id: UUID = UUID(),
        appName: String,
        bundleID: String,
        timestamp: Date = Date(),
        items: [UninstallUndoItem]
    ) {
        self.id = id
        self.appName = appName
        self.bundleID = bundleID
        self.timestamp = timestamp
        self.items = items
        self.totalSize = items.reduce(0) { $0 + $1.size }
    }

    /// 校验当前批次是否具备撤销还原条件（所有废纸篓文件必须仍存在，且原始路径未被占用）
    public var canRestore: Bool {
        guard !items.isEmpty else { return false }
        for item in items {
            guard item.trashIdentity?.matches(url: URL(fileURLWithPath: item.trashPath)) == true,
                  FileUtil.authorizedTrashRoots().contains(where: { FileUtil.isStrictDescendant(URL(fileURLWithPath: item.trashPath), of: $0) }) else {
                return false
            }
            guard !FileManager.default.fileExists(atPath: item.originalPath) else {
                return false
            }
        }
        return true
    }
}

public enum UndoRestoreFailure: Error, Sendable, Equatable {
    case persistenceFailed
    case partialRestore(paths: [String])
    case batchNotFound
    case invalidPath(path: String)
    case itemNotFoundInTrash(trashPath: String)
    case destinationAlreadyExists(originalPath: String)
    case moveFailed(originalPath: String, errorDescription: String)
}

public final class UninstallerUndoManager: @unchecked Sendable {
    public static let shared = UninstallerUndoManager()
    private let lock = NSLock()
    private let storageURL: URL
    private var storageReadable = true

    public init(storageURL: URL? = nil) {
        if let storageURL {
            self.storageURL = storageURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            let folder = appSupport.appendingPathComponent(AppConfig.UninstallerUndo.appSupportSubdirectory, isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            self.storageURL = folder.appendingPathComponent(AppConfig.UninstallerUndo.recordFileName)
        }
    }

    /// 记录一次应用卸载产生的撤销快照批次
    @discardableResult
    public func recordBatch(appName: String, bundleID: String, items: [UninstallUndoItem]) -> Bool {
        guard !items.isEmpty else { return true }
        lock.lock()
        defer { lock.unlock() }

        var batches = loadBatchesUnlocked()
        let newBatch = UninstallUndoBatch(
            appName: appName,
            bundleID: bundleID,
            timestamp: Date(),
            items: items
        )
        batches.insert(newBatch, at: 0)
        if batches.count > AppConfig.UninstallerUndo.maxBatches {
            batches = Array(batches.prefix(AppConfig.UninstallerUndo.maxBatches))
        }
        return saveBatchesUnlocked(batches)
    }

    /// 获取所有可用的卸载撤销记录
    public func loadBatches() -> [UninstallUndoBatch] {
        lock.lock()
        defer { lock.unlock() }
        return loadBatchesUnlocked()
    }

    /// 执行一键撤销还原（将废纸篓中的文件原路移回）
    public func restoreBatch(id: UUID) throws {
        lock.lock()
        defer { lock.unlock() }

        var batches = loadBatchesUnlocked()
        guard storageReadable else { throw UndoRestoreFailure.persistenceFailed }
        guard let index = batches.firstIndex(where: { $0.id == id }) else {
            throw UndoRestoreFailure.batchNotFound
        }

        guard storageReadable else { throw UndoRestoreFailure.persistenceFailed }
        let batch = batches[index]
        let items = batch.items.map {
            CleanupRestoreItem(originalURL: URL(fileURLWithPath: $0.originalPath),
                               trashURL: URL(fileURLWithPath: $0.trashPath),
                               identity: $0.trashIdentity, bytes: $0.size)
        }
        let result = CleanupRestoreService.restore(items)
        let pending = zip(batch.items, items).filter { !result.restoredIDs.contains($0.1.id) }.map { $0.0 }
        if pending.isEmpty { batches.remove(at: index) }
        else {
            batches[index] = UninstallUndoBatch(id: batch.id, appName: batch.appName, bundleID: batch.bundleID,
                                                timestamp: batch.timestamp, items: pending)
        }
        guard saveBatchesUnlocked(batches) else { throw UndoRestoreFailure.persistenceFailed }
        if !result.failedPaths.isEmpty { throw UndoRestoreFailure.partialRestore(paths: result.failedPaths) }
    }

    /// 清除指定撤销批次记录
    public func removeBatch(id: UUID) {
        lock.lock()
        defer { lock.unlock() }

        var batches = loadBatchesUnlocked()
        batches.removeAll { $0.id == id }
        saveBatchesUnlocked(batches)
    }

    /// 清理已过期的记录（废纸篓已清空或超过天数）
    public func purgeStaleBatches() {
        lock.lock()
        defer { lock.unlock() }

        var batches = loadBatchesUnlocked()
        purgeStaleBatchesUnlocked(&batches)
        saveBatchesUnlocked(batches)
    }

    private func purgeStaleBatchesUnlocked(_ batches: inout [UninstallUndoBatch]) {
        let cutoff = Date().addingTimeInterval(-Double(AppConfig.UninstallerUndo.maxBatchAgeDays * 86400))
        batches.removeAll { batch in
            if batch.timestamp < cutoff { return true }
            let hasAnyTrash = batch.items.contains { FileManager.default.fileExists(atPath: $0.trashPath) }
            return !hasAnyTrash
        }
    }

    private func loadBatchesUnlocked() -> [UninstallUndoBatch] {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { storageReadable = true; return [] }
        do {
            let data = try Data(contentsOf: storageURL)
            let batches = try JSONDecoder().decode([UninstallUndoBatch].self, from: data)
            storageReadable = true
            return batches
        } catch {
            storageReadable = false
            return [] // Preserve corrupt/unreadable bytes; saving is disabled.
        }
    }

    @discardableResult
    private func saveBatchesUnlocked(_ batches: [UninstallUndoBatch]) -> Bool {
        guard storageReadable else { return false }
        do {
            let data = try JSONEncoder().encode(batches)
            try data.write(to: storageURL, options: .atomic)
            return true
        } catch { return false }
    }
}
