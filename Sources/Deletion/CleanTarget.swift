import Foundation

/// 文件物理身份凭证 (TOCTOU 与软链接劫持防御)
struct FileIdentity: Codable, Sendable, Equatable {
    var device: dev_t
    var inode: ino_t
    var isDirectory: Bool
    var modificationTime: time_t
    var modificationTimeNsec: Int
    var fileSize: off_t
    var mode: mode_t = 0
    var changeTime: time_t = 0
    var changeTimeNsec: Int = 0
    var linkCount: nlink_t = 0
    var uid: uid_t = 0

    /// 测试钩子：允许在非 root 测试环境下模拟后代文件或目录具有非当前用户 UID
    #if DEBUG
    static nonisolated(unsafe) var uidOverrideForTesting: ((URL) -> uid_t?)? = nil
    #else
    static var uidOverrideForTesting: ((URL) -> uid_t?)? { nil }
    #endif

    static func capture(from url: URL) -> FileIdentity? {
        var statBuf = stat()
        if lstat(url.path, &statBuf) == 0 {
            let isDir = (statBuf.st_mode & S_IFMT) == S_IFDIR
            let effectiveUID = uidOverrideForTesting?(url) ?? statBuf.st_uid
            return FileIdentity(
                device: statBuf.st_dev,
                inode: statBuf.st_ino,
                isDirectory: isDir,
                modificationTime: statBuf.st_mtimespec.tv_sec,
                modificationTimeNsec: statBuf.st_mtimespec.tv_nsec,
                fileSize: statBuf.st_size,
                mode: statBuf.st_mode,
                changeTime: statBuf.st_ctimespec.tv_sec,
                changeTimeNsec: statBuf.st_ctimespec.tv_nsec,
                linkCount: statBuf.st_nlink,
                uid: effectiveUID
            )
        }
        return nil
    }

    func matches(url: URL) -> Bool {
        guard let current = Self.capture(from: url) else { return false }
        return current == self
    }
}

struct CleanChildFailure: Sendable, Equatable {
    var name: String
    var path: String
    var message: String
    var failureKind: CleanupFailure? = nil
}

struct CleanOutcome: Identifiable, Sendable {
    let id = UUID()
    var name: String
    var path: String
    var size: Int64
    var ok: Bool
    var error: String?
    var actionCategory: CleanActionCategory = .movedToTrash
    var destinationURL: URL? = nil
    var trashedURLs: [URL] = []
    var failedChildren: [String] = []
    var failedChildDetails: [CleanChildFailure] = []
    var failureKind: CleanupFailure? = nil
    var recoveryURL: URL? = nil
    var permanentlyDeletedBytes: Int64 = 0
    /// Explicit side effects for containers, including cancellation after some children moved.
    var movedToTrashBytes: Int64? = nil
    var removedSourcePaths: Set<String> = []
    var restoreItems: [CleanupRestoreItem] = []
}

/// 清理任务的可跨线程传递形式（Node 含 NSImage，不是 Sendable）
struct CleanTarget: Sendable {
    var ruleIdentity: RuleIdentity? = RuleTaskGate.shared.identity
    var name: String
    var url: URL?
    var size: Int64
    var measuredBytes: Int64
    var action: ItemAction
    var locked: Bool
    var expectedIdentity: FileIdentity?
    var duplicateEvidence: DuplicateEvidence? = nil
    var dockerEndpoint: DockerEndpoint? = nil
    var ruleEvidence: CleanupRuleEvidence? = nil {
        didSet {
            if !hasExplicitAuthorizationContext {
                authorizationContext = CleanAuthorizationContext.infer(
                    action: action,
                    uninstallContext: uninstallContext,
                    ruleEvidence: ruleEvidence,
                    defaultFallback: .organizeManual
                )
            }
        }
    }
    var uninstallContext: UninstallContext? = nil {
        didSet {
            if !hasExplicitAuthorizationContext {
                authorizationContext = CleanAuthorizationContext.infer(
                    action: action,
                    uninstallContext: uninstallContext,
                    ruleEvidence: ruleEvidence,
                    defaultFallback: .organizeManual
                )
            }
        }
    }
    var uninstallPurpose: UninstallerEngine.AppFolderPurpose? = nil
    var ownerBundleIDs: [String] = []
    var safety: Safety = .caution
    var authorizationContext: CleanAuthorizationContext
    var executionMode: CleanExecutionMode = .manual
    var containerChildren: [CleanTarget] = []
    var retryChildPaths: Set<String>? = nil
    var selectionRestrictions: Set<SelectionRestriction> = []
    var cacheRecommendation: CacheRecommendationSnapshot? = nil
    private var hasExplicitAuthorizationContext: Bool = false

    init(
        name: String,
        url: URL?,
        size: Int64,
        action: ItemAction,
        locked: Bool = false,
        identity: FileIdentity? = nil,
        ownerBundleIDs: [String] = [],
        authorizationContext: CleanAuthorizationContext? = nil,
        measuredBytes: Int64? = nil,
        executionMode: CleanExecutionMode = .manual,
        containerChildren: [CleanTarget] = [],
        retryChildPaths: Set<String>? = nil,
        selectionRestrictions: Set<SelectionRestriction> = [],
        cacheRecommendation: CacheRecommendationSnapshot? = nil
    ) {
        self.name = name
        self.url = url
        self.size = size
        self.measuredBytes = measuredBytes ?? size
        self.action = action
        self.locked = locked
        self.expectedIdentity = identity ?? (url != nil ? FileIdentity.capture(from: url!) : nil)
        self.ownerBundleIDs = ownerBundleIDs
        self.executionMode = executionMode
        self.containerChildren = containerChildren
        self.retryChildPaths = retryChildPaths
        self.selectionRestrictions = selectionRestrictions
        self.cacheRecommendation = cacheRecommendation
        if let authorizationContext {
            self.authorizationContext = authorizationContext
            self.hasExplicitAuthorizationContext = true
        } else {
            self.authorizationContext = CleanAuthorizationContext.infer(
                action: action,
                defaultFallback: .organizeManual
            )
            self.hasExplicitAuthorizationContext = false
        }
    }

    init(_ n: Node, executionMode: CleanExecutionMode = .manual) {
        ruleIdentity = n.ruleIdentity
        name = n.name
        url = n.url
        size = n.totalSize
        measuredBytes = n.measuredBytes ?? n.totalSize
        action = n.action
        locked = n.locked
        ownerBundleIDs = n.ownerBundleIDs
        duplicateEvidence = n.duplicateEvidence
        dockerEndpoint = n.dockerEndpoint
        ruleEvidence = n.ruleEvidence
        uninstallContext = n.uninstallContext
        uninstallPurpose = n.uninstallPurpose
        expectedIdentity = n.fileIdentity
        safety = n.safety
        authorizationContext = n.resolvedAuthorizationContext
        self.executionMode = executionMode
        selectionRestrictions = n.selectionRestrictions
        cacheRecommendation = n.cacheRecommendation
        if n.action == .emptyContainer && !n.children.isEmpty {
            containerChildren = n.children.filter { !$0.locked }.map { CleanTarget($0, executionMode: executionMode) }
        }
        hasExplicitAuthorizationContext = true
    }

    static func emptyContainer(from n: Node, executionMode: CleanExecutionMode = .manual) -> CleanTarget {
        var target = CleanTarget(n, executionMode: executionMode)
        target.action = .emptyContainer
        if !n.children.isEmpty {
            target.containerChildren = n.children.filter { !$0.locked }.map { CleanTarget($0, executionMode: executionMode) }
        }
        return target
    }
}

/// 扫描/清理的中断标记（可跨线程读写）
final class StopFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = false
    var value: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _value }
        set { lock.lock(); _value = newValue; lock.unlock() }
    }
}

struct CleanReport: Identifiable {
    var restorePersistenceFailed = false
    let id = UUID()
    var module: String
    var outcomes: [CleanOutcome]
    var started: Date = Date()

    /// 移入废纸篓的总字节数（需清空废纸篓后才释放物理卷空间）
    var movedToTrashBytes: Int64 {
        outcomes.reduce(0) { total, outcome in
            if let moved = outcome.movedToTrashBytes { return total + max(0, moved) }
            let trashed = (outcome.ok && outcome.actionCategory == .movedToTrash)
                || (outcome.actionCategory == .partialFailure && outcome.permanentlyDeletedBytes == 0)
            return total + (trashed ? outcome.size : 0)
        }
    }

    /// 物理永久删除的估算字节数（直接从磁盘删除未入废纸篓，含部分永久删除已实际解除链接的字节）
    var permanentlyDeletedBytes: Int64 {
        outcomes.reduce(0) { acc, o in
            if o.ok && o.actionCategory == .permanentlyDeleted {
                return acc + o.size
            } else if o.permanentlyDeletedBytes > 0 {
                return acc + o.permanentlyDeletedBytes
            }
            return acc
        }
    }

    /// 工具报告的回收量；Docker daemon 的值不代表宿主卷可用空间净增量。
    var reportedReclaimedBytes: Int64 {
        outcomes.filter { $0.ok && $0.actionCategory == .systemReclaimed }.reduce(0) { $0 + $1.size }
    }

    /// 预计可释放空间总量（永久删除估算 + 工具报告回收）
    var estimatedReclaimableBytes: Int64 {
        permanentlyDeletedBytes + reportedReclaimedBytes
    }

    /// 经由系统容量观测证实的真实释放空间（无容量观测证据时为 0，不虚标精确回收）
    var actualFreedBytes: Int64 { observedVolumeDelta ?? 0 }
    var observedVolumeDelta: Int64? = nil

    /// 已成功处理的总数据量（包含废纸篓、永久删除与系统回收）
    var processedBytes: Int64 {
        outcomes.reduce(0) { total, outcome in
            if let moved = outcome.movedToTrashBytes {
                return total + max(0, moved) + outcome.permanentlyDeletedBytes
            }
            return total + ((outcome.ok || outcome.actionCategory == .partialFailure) ? outcome.size : 0)
        }
    }

    /// 兼容旧属性：被处理的有效总量
    var freed: Int64 {
        processedBytes
    }

    var okCount: Int { outcomes.filter(\.ok).count }
    var failCount: Int { outcomes.filter { !$0.ok }.count }
    var skippedCount: Int { outcomes.filter { $0.actionCategory == .skipped || $0.actionCategory == .absent }.count }
    var cancelledCount: Int { outcomes.filter { $0.actionCategory == .cancelled }.count }
    var errorCount: Int { outcomes.filter { !$0.ok && $0.actionCategory != .skipped && $0.actionCategory != .absent && $0.actionCategory != .cancelled }.count }
    var state: State {
        if outcomes.contains(where: { $0.actionCategory == .cancelled }) { return .cancelled }
        if outcomes.isEmpty { return .failed }
        if outcomes.contains(where: { $0.actionCategory == .partialFailure }) { return .partial }
        if failCount == 0 { return .success }
        if okCount == 0 { return .failed }
        return .partial
    }
    enum State { case success, partial, failed, cancelled }
}
