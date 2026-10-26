import Foundation

struct RuleIdentity: Codable, Hashable, Sendable {
    let version: Int64
    let hash: String
    let generation: UInt64
}

final class RuleTaskLease: @unchecked Sendable {
    let identity: RuleIdentity?
    private let gate: RuleTaskGate
    fileprivate init(gate: RuleTaskGate, identity: RuleIdentity?) { self.gate = gate; self.identity = identity }
    deinit { gate.finish() }
}

/// Task registration and the final activation check share the same lock.
final class RuleTaskGate: @unchecked Sendable {
    static let shared = RuleTaskGate()
    private let lock = NSRecursiveLock()
    private var active = 0
    private var current: RuleIdentity?
    private var disabled = Set<String>()
    private var revoked = Set<String>()
    var onIdle: (@Sendable () -> Void)? {
        get { lock.lock(); defer { lock.unlock() }; return idleCallback }
        set { lock.lock(); defer { lock.unlock() }; idleCallback = newValue }
    }
    private var idleCallback: (@Sendable () -> Void)?
    var identity: RuleIdentity? { lock.lock(); defer { lock.unlock() }; return current }
    var disabledIDs: Set<String> { lock.lock(); defer { lock.unlock() }; return disabled }
    var isIdle: Bool { lock.lock(); defer { lock.unlock() }; return active == 0 }
    func begin() -> RuleTaskLease {
        lock.lock(); defer { lock.unlock() }; active += 1
        return RuleTaskLease(gate: self, identity: current)
    }
    fileprivate func finish() {
        lock.lock(); active -= 1; precondition(active >= 0)
        let callback = active == 0 ? idleCallback : nil
        lock.unlock(); callback?()
    }
    func withTask<T>(_ body: () throws -> T) rethrows -> T {
        let lease = begin(); defer { withExtendedLifetime(lease) {} }
        return try body()
    }
    func updateRestrictions(disabled: Set<String>, revoked: Set<String>) {
        lock.lock(); defer { lock.unlock() }
        self.disabled.formUnion(disabled); self.revoked.formUnion(revoked)
    }
    func allows(_ expected: RuleIdentity?, ruleID: String? = nil) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard let current, let expected, current == expected, !revoked.contains(current.hash) else { return false }
        return ruleID.map { !disabled.contains($0) } ?? true
    }
    /// Recovery also owns the idle check until the database and snapshot agree.
    func recover(_ operation: () throws -> (version: Int64, hash: String)) throws {
        lock.lock(); defer { lock.unlock() }
        guard active == 0 else { throw RuleUpdateFailure.busy }
        let recovered = try operation()
        guard !revoked.contains(recovered.hash) else { throw RuleUpdateFailure.revoked }
        setIdentity(version: recovered.version, hash: recovered.hash)
    }
    private func setIdentity(version: Int64, hash: String) {
        if current?.version != version || current?.hash != hash {
            current = RuleIdentity(version: version, hash: hash, generation: (current?.generation ?? 0) &+ 1)
        }
    }
    func activate(version: Int64, hash: String, _ operation: () throws -> Void) throws {
        lock.lock(); defer { lock.unlock() }
        guard active == 0, !revoked.contains(hash) else { throw RuleUpdateFailure.busy }
        try operation()
        setIdentity(version: version, hash: hash)
    }
}
