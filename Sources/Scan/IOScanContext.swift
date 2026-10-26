import Foundation
import AppKit

/// T11：目录巡检阶段
enum InspectionStage: String, Codable, Equatable, Sendable {
    case scan
    case execution
}

/// T11：目录巡检重查原因
enum InspectionRetryReason: String, Codable, Equatable, Sendable {
    case identityChanged
    case ruleContextChanged
    case ignorePolicyChanged
    case overlapContext
}

/// T11：目录巡检观测明细
struct InspectionTelemetryRecord: Codable, Equatable, Sendable {
    var targetPath: String
    var contextDigest: String
    var stage: InspectionStage
    var reused: Bool
    var retryReason: InspectionRetryReason?
    var inspectedEntryCount: Int
    var degradationReason: ScanDegradationReason?
}

/// T11：本轮目录巡检回执键（绑定 scanUUID、物理身份与规则/忽略上下文）
struct InspectionReceiptKey: Hashable, Sendable {
    let scanUUID: UUID
    let canonicalPath: String
    let device: dev_t
    let inode: ino_t
    let uid: uid_t
    let mode: mode_t
    let ruleSQLHash: String
    let ruleID: String?
    let parentRuleID: String?
    let parentTier: String?
    let protectionDigest: String
    let ignorePolicyVersion: Int
    let profileID: String?
    let requireCurrentUserUID: Bool
    let boundaryPolicy: String

    var contextDigest: String {
        "\(ruleSQLHash)|\(ruleID ?? "-")|\(parentRuleID ?? "-")|\(parentTier ?? "-")|\(protectionDigest)|\(ignorePolicyVersion)|\(profileID ?? "-")|\(requireCurrentUserUID)|\(boundaryPolicy)"
    }
}

/// T11：候选注册表记录（仅登记发现根、scannerID、owner 线索与规则上下文，不递归测量）
struct RegisteredCandidate: Sendable, Equatable {
    var canonicalPath: String
    var url: URL
    var scannerIDs: Set<String>
    var ownerBundleIDs: Set<String>
    var ruleIDs: Set<String>
    var strictestTier: CleanupTier?
    var physicalDevice: dev_t?
    var physicalInode: ino_t?
}

/// 单项扫描任务的结构化耗时与候选统计 (P0 Telemetry + T11)
struct ScanTaskTelemetry: Codable, Equatable, Sendable {
    var taskName: String
    var runMs: Double
    var acceptMs: Double
    var rawCandidateCount: Int
    var deduplicatedLeafCount: Int
    var discoveredTargetCount: Int = 0
    var mergedDiscoveryCount: Int = 0
    var scanFullInspectionCount: Int = 0
    var inspectionReuseCount: Int = 0
    var inspectionRetryCount: Int = 0
    var executionFullInspectionCount: Int = 0
    var inspectedEntryCount: Int = 0
}

/// 按分级或评估原因聚合的项数与字节数统计桶
struct ScanBucketAggregation: Codable, Equatable, Sendable {
    var itemCount: Int = 0
    var totalBytes: Int64 = 0

    mutating func add(bytes: Int64) {
        itemCount += 1
        totalBytes += max(0, bytes)
    }
}

/// 扫描会话完整结构化诊断快照 (P0 ScanTelemetrySnapshot + T11)
struct ScanTelemetrySnapshot: Codable, Equatable, Sendable {
    var totalWallTimeMs: Double
    var tasks: [ScanTaskTelemetry]
    var inspectedDirectoryEntryCount: Int
    var timeoutOrBudgetDegradationCount: Int
    var deduplicationComparisonCount: Int
    var lsofInvocationCount: Int
    var lsofCumulativeMs: Double
    var runningBundleIDs: [String]
    var tierAggregations: [String: ScanBucketAggregation]
    var reasonAggregations: [String: ScanBucketAggregation]
    var discoveredTargetCount: Int = 0
    var mergedDiscoveryCount: Int = 0
    var scanFullInspectionCount: Int = 0
    var inspectionReuseCount: Int = 0
    var inspectionRetryCount: Int = 0
    var executionFullInspectionCount: Int = 0
    var inspectedEntryCount: Int = 0
    var inspectionRecords: [InspectionTelemetryRecord] = []

    enum CodingKeys: String, CodingKey {
        case totalWallTimeMs
        case tasks
        case inspectedDirectoryEntryCount
        case timeoutOrBudgetDegradationCount
        case deduplicationComparisonCount
        case lsofInvocationCount
        case lsofCumulativeMs
        case runningBundleIDs
        case tierAggregations
        case reasonAggregations
        case discoveredTargetCount
        case mergedDiscoveryCount
        case scanFullInspectionCount
        case inspectionReuseCount
        case inspectionRetryCount
        case executionFullInspectionCount
        case inspectedEntryCount
        case inspectionRecords
    }
}

/// Synchronous scanners share cancellation and coverage on their dedicated I/O threads.
/// This is deliberately not a cooperative-executor task running blocking FTS calls.
final class IOScanContext: @unchecked Sendable {
    private static let key = "AClean.IOScanContext"
    let scanUUID: UUID = UUID()
    private let lock = NSLock()
    private let _startTime: TimeInterval = ProcessInfo.processInfo.systemUptime
    private var _totalWallTimeMs: Double?
    private var _issues: [String] = []
    private var _degradations: [ScanDegradationReason] = []
    private var _evaluationReasonCounts: [CandidateEvaluationReason: Int] = [:]
    private var _deduplicationRecords: [DeduplicationRecord] = []
    private var _taskTelemetries: [ScanTaskTelemetry] = []
    private var _inspectedDirectoryEntryCount: Int = 0
    private var _timeoutOrBudgetDegradationCount: Int = 0
    private var _deduplicationComparisonCount: Int = 0
    private var _lsofInvocationCount: Int = 0
    private var _lsofCumulativeMs: Double = 0
    private var _runningBundleIDs: [String]
    private var _discoveredTargetCount: Int = 0
    private var _mergedDiscoveryCount: Int = 0
    private var _scanFullInspectionCount: Int = 0
    private var _inspectionReuseCount: Int = 0
    private var _inspectionRetryCount: Int = 0
    private var _executionFullInspectionCount: Int = 0
    private var _inspectionRecords: [InspectionTelemetryRecord] = []
    private var _candidateRegistry: [String: RegisteredCandidate] = [:]
    private struct StoredReceipt {
        var key: InspectionReceiptKey
        var result: FastDirectoryInspector.InspectionResult
    }
    private var _inspectionReceipts: [String: StoredReceipt] = [:]
    private var _pendingRetryReasons: [String: InspectionRetryReason] = [:]
    private var _inFlightConditions: [InspectionReceiptKey: NSCondition] = [:]
    private var _tierAggregations: [String: ScanBucketAggregation] = [
        CleanupTier.automatic.rawValue: ScanBucketAggregation(),
        CleanupTier.review.rawValue: ScanBucketAggregation(),
        CleanupTier.readOnly.rawValue: ScanBucketAggregation(),
        CleanupTier.forbidden.rawValue: ScanBucketAggregation()
    ]
    private var _reasonAggregations: [String: ScanBucketAggregation] = [:]
    private let _openFileSnapshotLock = NSLock()
    private var _openFileSnapshotLoaded: Bool = false
    private var _openFileSnapshot: OpenFileGuard.Snapshot?
    private let _containerIdleStatusLock = NSLock()
    private var _containerIdleStatus: [String: Bool] = [:]
    private struct HardLinkKey: Hashable { let device: dev_t; let inode: ino_t }
    private let hardLinkLock = NSLock()
    private var hardLinkPaths: [HardLinkKey: String] = [:]

    /// Attribution belongs to this scan only; constructing another context cannot reset it.
    func claimHardLink(device: dev_t, inode: ino_t, path: String) -> Bool {
        let canonical = URL(fileURLWithPath: path).standardizedFileURL.path
        let key = HardLinkKey(device: device, inode: inode)
        hardLinkLock.lock(); defer { hardLinkLock.unlock() }
        if let previous = hardLinkPaths[key], previous != canonical {
            var info = stat()
            if lstat(previous, &info) == 0 && info.st_dev == device && info.st_ino == inode && info.st_nlink > 1 {
                return false
            }
        }
        hardLinkPaths[key] = canonical
        return true
    }

    func resetHardLinkAttribution() {
        hardLinkLock.lock(); defer { hardLinkLock.unlock() }
        hardLinkPaths.removeAll()
    }

    let stopped: () -> Bool

    init(stopped: @escaping () -> Bool) {
        self.stopped = stopped
        let running = NSWorkspace.shared.runningApplications.compactMap { app -> String? in
            guard !app.isTerminated, let bid = app.bundleIdentifier, !bid.isEmpty else { return nil }
            return bid
        }
        self._runningBundleIDs = Array(Set(running)).sorted()
    }

    var issues: [String] { lock.lock(); defer { lock.unlock() }; return _issues }
    var degradations: [ScanDegradationReason] { lock.lock(); defer { lock.unlock() }; return _degradations }
    var evaluationReasonCounts: [CandidateEvaluationReason: Int] { lock.lock(); defer { lock.unlock() }; return _evaluationReasonCounts }
    var deduplicationRecords: [DeduplicationRecord] { lock.lock(); defer { lock.unlock() }; return _deduplicationRecords }
    var taskTelemetries: [ScanTaskTelemetry] { lock.lock(); defer { lock.unlock() }; return _taskTelemetries }
    var inspectedDirectoryEntryCount: Int { lock.lock(); defer { lock.unlock() }; return _inspectedDirectoryEntryCount }
    var timeoutOrBudgetDegradationCount: Int { lock.lock(); defer { lock.unlock() }; return _timeoutOrBudgetDegradationCount }
    var deduplicationComparisonCount: Int { lock.lock(); defer { lock.unlock() }; return _deduplicationComparisonCount }
    var lsofInvocationCount: Int { lock.lock(); defer { lock.unlock() }; return _lsofInvocationCount }
    var lsofCumulativeMs: Double { lock.lock(); defer { lock.unlock() }; return _lsofCumulativeMs }
    var runningBundleIDs: [String] { lock.lock(); defer { lock.unlock() }; return _runningBundleIDs }
    var discoveredTargetCount: Int { lock.lock(); defer { lock.unlock() }; return _discoveredTargetCount }
    var mergedDiscoveryCount: Int { lock.lock(); defer { lock.unlock() }; return _mergedDiscoveryCount }
    var scanFullInspectionCount: Int { lock.lock(); defer { lock.unlock() }; return _scanFullInspectionCount }
    var inspectionReuseCount: Int { lock.lock(); defer { lock.unlock() }; return _inspectionReuseCount }
    var inspectionRetryCount: Int { lock.lock(); defer { lock.unlock() }; return _inspectionRetryCount }
    var executionFullInspectionCount: Int { lock.lock(); defer { lock.unlock() }; return _executionFullInspectionCount }
    var inspectionRecords: [InspectionTelemetryRecord] { lock.lock(); defer { lock.unlock() }; return _inspectionRecords }
    var registeredCandidates: [String: RegisteredCandidate] { lock.lock(); defer { lock.unlock() }; return _candidateRegistry }

    var telemetrySnapshot: ScanTelemetrySnapshot {
        lock.lock(); defer { lock.unlock() }
        let wallMs = _totalWallTimeMs ?? ((ProcessInfo.processInfo.systemUptime - _startTime) * 1000.0)
        return ScanTelemetrySnapshot(
            totalWallTimeMs: wallMs,
            tasks: _taskTelemetries,
            inspectedDirectoryEntryCount: _inspectedDirectoryEntryCount,
            timeoutOrBudgetDegradationCount: _timeoutOrBudgetDegradationCount,
            deduplicationComparisonCount: _deduplicationComparisonCount,
            lsofInvocationCount: _lsofInvocationCount,
            lsofCumulativeMs: _lsofCumulativeMs,
            runningBundleIDs: _runningBundleIDs,
            tierAggregations: _tierAggregations,
            reasonAggregations: _reasonAggregations,
            discoveredTargetCount: _discoveredTargetCount,
            mergedDiscoveryCount: _mergedDiscoveryCount,
            scanFullInspectionCount: _scanFullInspectionCount,
            inspectionReuseCount: _inspectionReuseCount,
            inspectionRetryCount: _inspectionRetryCount,
            executionFullInspectionCount: _executionFullInspectionCount,
            inspectedEntryCount: _inspectedDirectoryEntryCount,
            inspectionRecords: _inspectionRecords
        )
    }

    static var current: IOScanContext? { Thread.current.threadDictionary[key] as? IOScanContext }
    static var isCancelled: Bool { current?.stopped() == true }
    static func record(_ error: Error, path: String) {
        current?.record(path + ": " + error.localizedDescription)
    }
    static func recordDegradation(_ reason: ScanDegradationReason, issue: String? = nil) {
        current?.recordDegradation(reason, issue: issue)
    }
    static func recordEvaluation(_ reason: CandidateEvaluationReason, tier: CleanupTier? = nil, bytes: Int64 = 0) {
        current?.recordEvaluation(reason, tier: tier, bytes: bytes)
    }
    static func recordDeduplication(_ record: DeduplicationRecord) {
        current?.recordDeduplication(record)
    }
    static func recordTaskTelemetry(_ task: ScanTaskTelemetry) {
        current?.recordTaskTelemetry(task)
    }
    static func addInspectedEntries(_ count: Int) {
        guard count > 0 else { return }
        current?.addInspectedEntries(count)
    }
    static func recordTimeoutOrBudgetDegradation() {
        current?.recordTimeoutOrBudgetDegradation()
    }
    static func addDeduplicationComparisons(_ count: Int) {
        guard count > 0 else { return }
        current?.addDeduplicationComparisons(count)
    }
    static func recordLsofInvocation(durationMs: Double) {
        current?.recordLsofInvocation(durationMs: durationMs)
    }
    static func markTotalWallTimeMs(_ wallMs: Double) {
        current?.markTotalWallTimeMs(wallMs)
    }
    static func currentTelemetrySnapshot() -> ScanTelemetrySnapshot? {
        current?.telemetrySnapshot
    }
    @discardableResult
    static func registerCandidate(
        url: URL,
        scannerID: String,
        ownerBundleIDs: [String] = [],
        ruleID: String? = nil,
        tier: CleanupTier? = nil
    ) -> RegisteredCandidate? {
        current?.registerCandidate(
            url: url,
            scannerID: scannerID,
            ownerBundleIDs: ownerBundleIDs,
            ruleID: ruleID,
            tier: tier
        )
    }
    static func recordContextRetry(canonicalPath: String, reason: InspectionRetryReason) {
        current?.recordContextRetry(canonicalPath: canonicalPath, reason: reason)
    }

    private static func tierStrictnessRank(_ tier: CleanupTier) -> Int {
        switch tier {
        case .forbidden: return 4
        case .readOnly: return 3
        case .review: return 2
        case .automatic: return 1
        }
    }

    @discardableResult
    func registerCandidate(
        url: URL,
        scannerID: String,
        ownerBundleIDs: [String] = [],
        ruleID: String? = nil,
        tier: CleanupTier? = nil
    ) -> RegisteredCandidate {
        let canonical = SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path)
        let identity = FileIdentity.capture(from: url)
        lock.lock()
        defer { lock.unlock() }
        _discoveredTargetCount += 1
        if var existing = _candidateRegistry[canonical] {
            let previousOwners = existing.ownerBundleIDs
            let previousRules = existing.ruleIDs
            let previousTier = existing.strictestTier
            existing.scannerIDs.insert(scannerID)
            existing.ownerBundleIDs.formUnion(ownerBundleIDs)
            if let ruleID, !ruleID.isEmpty {
                existing.ruleIDs.insert(ruleID)
            }
            if let tier {
                if let prev = existing.strictestTier {
                    if Self.tierStrictnessRank(tier) > Self.tierStrictnessRank(prev) {
                        existing.strictestTier = tier
                    }
                } else {
                    existing.strictestTier = tier
                }
            }
            if existing.physicalDevice == nil { existing.physicalDevice = identity?.device }
            if existing.physicalInode == nil { existing.physicalInode = identity?.inode }
            _candidateRegistry[canonical] = existing

            let stricterTierArrived: Bool = {
                guard let newT = existing.strictestTier else { return false }
                guard let oldT = previousTier else { return true }
                return Self.tierStrictnessRank(newT) > Self.tierStrictnessRank(oldT)
            }()
            let ownersExpanded = existing.ownerBundleIDs != previousOwners
            let rulesExpanded = existing.ruleIDs != previousRules
            if (stricterTierArrived || ownersExpanded || rulesExpanded),
               _inspectionReceipts[canonical] != nil {
                _pendingRetryReasons[canonical] = .ruleContextChanged
            }
            return existing
        } else {
            _mergedDiscoveryCount += 1
            var rules: Set<String> = []
            if let ruleID, !ruleID.isEmpty { rules.insert(ruleID) }
            let created = RegisteredCandidate(
                canonicalPath: canonical,
                url: url,
                scannerIDs: [scannerID],
                ownerBundleIDs: Set(ownerBundleIDs),
                ruleIDs: rules,
                strictestTier: tier,
                physicalDevice: identity?.device,
                physicalInode: identity?.inode
            )
            _candidateRegistry[canonical] = created
            return created
        }
    }

    func recordContextRetry(canonicalPath: String, reason: InspectionRetryReason) {
        let canonical = SymlinkGuard.canonicalizeMacOSSystemPrefix(
            URL(fileURLWithPath: canonicalPath).standardizedFileURL.path
        )
        lock.lock()
        defer { lock.unlock() }
        _pendingRetryReasons[canonical] = reason
        _inspectionReceipts.removeValue(forKey: canonical)
        _inspectionRetryCount += 1
        if _inspectionRecords.count < AppConfig.Security.deduplicationRecordLimit {
            _inspectionRecords.append(
                InspectionTelemetryRecord(
                    targetPath: canonical,
                    contextDigest: "reconcile",
                    stage: .scan,
                    reused: false,
                    retryReason: reason,
                    inspectedEntryCount: 0,
                    degradationReason: nil
                )
            )
        }
    }

    func executeOrReuseScanInspection(
        key: InspectionReceiptKey,
        compute: () -> FastDirectoryInspector.InspectionResult
    ) -> FastDirectoryInspector.InspectionResult {
        var waitCondition: NSCondition? = nil
        var createdCondition: NSCondition? = nil
        var retryReason: InspectionRetryReason? = nil

        lock.lock()
        if let pending = _pendingRetryReasons.removeValue(forKey: key.canonicalPath) {
            retryReason = pending
            _inspectionReceipts.removeValue(forKey: key.canonicalPath)
        } else if let stored = _inspectionReceipts[key.canonicalPath] {
            if stored.key == key {
                _inspectionReuseCount += 1
                if _inspectionRecords.count < AppConfig.Security.deduplicationRecordLimit {
                    _inspectionRecords.append(
                        InspectionTelemetryRecord(
                            targetPath: key.canonicalPath,
                            contextDigest: key.contextDigest,
                            stage: .scan,
                            reused: true,
                            retryReason: nil,
                            inspectedEntryCount: stored.result.inspectedEntryCount,
                            degradationReason: stored.result.degradationReason
                        )
                    )
                }
                lock.unlock()
                return stored.result
            } else {
                if stored.key.device != key.device
                    || stored.key.inode != key.inode
                    || stored.key.uid != key.uid
                    || stored.key.mode != key.mode {
                    retryReason = .identityChanged
                } else if stored.key.ignorePolicyVersion != key.ignorePolicyVersion {
                    retryReason = .ignorePolicyChanged
                } else if stored.key.ruleSQLHash != key.ruleSQLHash
                    || stored.key.ruleID != key.ruleID
                    || stored.key.parentRuleID != key.parentRuleID
                    || stored.key.parentTier != key.parentTier
                    || stored.key.protectionDigest != key.protectionDigest
                    || stored.key.profileID != key.profileID
                    || stored.key.requireCurrentUserUID != key.requireCurrentUserUID {
                    retryReason = .ruleContextChanged
                } else {
                    retryReason = .overlapContext
                }
                _inspectionReceipts.removeValue(forKey: key.canonicalPath)
            }
        }

        if let existingCond = _inFlightConditions[key] {
            waitCondition = existingCond
            lock.unlock()
        } else {
            let cond = NSCondition()
            _inFlightConditions[key] = cond
            createdCondition = cond
            lock.unlock()
        }

        if let waitCondition {
            waitCondition.lock()
            while !stopped() {
                lock.lock()
                let finished = (_inFlightConditions[key] == nil)
                let cached = _inspectionReceipts[key.canonicalPath]
                if finished {
                    if let cached, cached.key == key {
                        _inspectionReuseCount += 1
                        if _inspectionRecords.count < AppConfig.Security.deduplicationRecordLimit {
                            _inspectionRecords.append(
                                InspectionTelemetryRecord(
                                    targetPath: key.canonicalPath,
                                    contextDigest: key.contextDigest,
                                    stage: .scan,
                                    reused: true,
                                    retryReason: nil,
                                    inspectedEntryCount: cached.result.inspectedEntryCount,
                                    degradationReason: cached.result.degradationReason
                                )
                            )
                        }
                        lock.unlock()
                        waitCondition.unlock()
                        return cached.result
                    }
                    lock.unlock()
                    break
                }
                lock.unlock()
                _ = waitCondition.wait(until: Date().addingTimeInterval(0.02))
            }
            waitCondition.unlock()
        }

        let result = compute()

        lock.lock()
        _scanFullInspectionCount += 1
        if retryReason != nil {
            _inspectionRetryCount += 1
        }
        _inspectionReceipts[key.canonicalPath] = StoredReceipt(key: key, result: result)
        if _inspectionRecords.count < AppConfig.Security.deduplicationRecordLimit {
            _inspectionRecords.append(
                InspectionTelemetryRecord(
                    targetPath: key.canonicalPath,
                    contextDigest: key.contextDigest,
                    stage: .scan,
                    reused: false,
                    retryReason: retryReason,
                    inspectedEntryCount: result.inspectedEntryCount,
                    degradationReason: result.degradationReason
                )
            )
        }
        if let createdCondition {
            _inFlightConditions.removeValue(forKey: key)
            lock.unlock()
            createdCondition.lock()
            createdCondition.broadcast()
            createdCondition.unlock()
        } else {
            lock.unlock()
        }
        return result
    }

    func recordExecutionInspection(
        canonicalPath: String,
        contextDigest: String,
        result: FastDirectoryInspector.InspectionResult
    ) {
        lock.lock()
        defer { lock.unlock() }
        _executionFullInspectionCount += 1
        if _inspectionRecords.count < AppConfig.Security.deduplicationRecordLimit {
            _inspectionRecords.append(
                InspectionTelemetryRecord(
                    targetPath: canonicalPath,
                    contextDigest: contextDigest,
                    stage: .execution,
                    reused: false,
                    retryReason: nil,
                    inspectedEntryCount: result.inspectedEntryCount,
                    degradationReason: result.degradationReason
                )
            )
        }
    }

    func record(_ issue: String) {
        lock.lock(); defer { lock.unlock() }
        if _issues.count < AppConfig.Security.scopeIssueLimit && !_issues.contains(issue) {
            _issues.append(issue)
        }
    }
    func recordDegradation(_ reason: ScanDegradationReason, issue: String? = nil) {
        lock.lock(); defer { lock.unlock() }
        if !_degradations.contains(reason) {
            _degradations.append(reason)
        }
        if let issue, !issue.isEmpty, _issues.count < AppConfig.Security.scopeIssueLimit, !_issues.contains(issue) {
            _issues.append(issue)
        }
    }
    func recordEvaluation(_ reason: CandidateEvaluationReason, tier: CleanupTier? = nil, bytes: Int64 = 0) {
        lock.lock(); defer { lock.unlock() }
        _evaluationReasonCounts[reason, default: 0] += 1
        _reasonAggregations[reason.categoryKey, default: ScanBucketAggregation()].add(bytes: bytes)
        if let tier {
            _tierAggregations[tier.rawValue, default: ScanBucketAggregation()].add(bytes: bytes)
        } else if case .missingScanEntry = reason {
            // missingScanEntry is a rule-level audit entry, not a file candidate
        } else {
            let inferredTier: CleanupTier = (reason == .matchedExecutableRule) ? .review : .readOnly
            _tierAggregations[inferredTier.rawValue, default: ScanBucketAggregation()].add(bytes: bytes)
        }
    }
    func recordDeduplication(_ record: DeduplicationRecord) {
        lock.lock(); defer { lock.unlock() }
        if _deduplicationRecords.count < AppConfig.Security.deduplicationRecordLimit {
            _deduplicationRecords.append(record)
        }
    }
    func recordTaskTelemetry(_ task: ScanTaskTelemetry) {
        lock.lock(); defer { lock.unlock() }
        if let idx = _taskTelemetries.firstIndex(where: { $0.taskName == task.taskName }) {
            _taskTelemetries[idx] = task
        } else {
            _taskTelemetries.append(task)
        }
    }
    func addInspectedEntries(_ count: Int) {
        lock.lock(); defer { lock.unlock() }
        _inspectedDirectoryEntryCount += count
    }
    func recordTimeoutOrBudgetDegradation() {
        lock.lock(); defer { lock.unlock() }
        _timeoutOrBudgetDegradationCount += 1
    }
    func addDeduplicationComparisons(_ count: Int) {
        lock.lock(); defer { lock.unlock() }
        _deduplicationComparisonCount += count
    }
    func recordLsofInvocation(durationMs: Double) {
        lock.lock(); defer { lock.unlock() }
        _lsofInvocationCount += 1
        _lsofCumulativeMs += max(0, durationMs)
    }
    func markTotalWallTimeMs(_ wallMs: Double) {
        lock.lock(); defer { lock.unlock() }
        _totalWallTimeMs = max(0, wallMs)
    }
    func openFileSnapshot(loader: () -> OpenFileGuard.Snapshot?) -> OpenFileGuard.Snapshot? {
        _openFileSnapshotLock.lock()
        defer { _openFileSnapshotLock.unlock() }
        if !_openFileSnapshotLoaded {
            _openFileSnapshot = loader()
            _openFileSnapshotLoaded = true
        }
        return _openFileSnapshot
    }
    func invalidateOpenFileSnapshot() {
        _openFileSnapshotLock.lock()
        _openFileSnapshotLoaded = false
        _openFileSnapshot = nil
        _openFileSnapshotLock.unlock()
    }
    func containerIdleStatus(for containerPath: String, loader: () -> Bool) -> Bool {
        _containerIdleStatusLock.lock()
        defer { _containerIdleStatusLock.unlock() }
        if let cached = _containerIdleStatus[containerPath] {
            return cached
        }
        let idle = loader()
        _containerIdleStatus[containerPath] = idle
        return idle
    }
    func perform<T>(_ body: () throws -> T) rethrows -> T {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        let old = Thread.current.threadDictionary[Self.key]
        Thread.current.threadDictionary[Self.key] = self
        defer { Thread.current.threadDictionary[Self.key] = old }
        return try body()
    }

    /// Bounded workers inherit the scan context; callers synchronize result storage.
    static func concurrentPerform(iterations: Int, execute: @escaping @Sendable (Int) -> Void) {
        guard iterations > 0 else { return }
        let context = current
        let workers = min(iterations, AppConfig.Security.ioConcurrency)
        DispatchQueue.concurrentPerform(iterations: workers) { worker in
            let work = {
                var index = worker
                while index < iterations && !Self.isCancelled {
                    execute(index)
                    index += workers
                }
            }
            if let context { context.perform(work) } else { work() }
        }
    }
}

/// Protects result slots and progress callbacks used by synchronous parallel scanners.
final class ScanResultSlots<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Value]
    init(repeating value: Value, count: Int) { storage = Array(repeating: value, count: count) }
    subscript(index: Int) -> Value {
        get { lock.lock(); defer { lock.unlock() }; return storage[index] }
        set { lock.lock(); defer { lock.unlock() }; storage[index] = newValue }
    }
    var values: [Value] { lock.lock(); defer { lock.unlock() }; return storage }
}
