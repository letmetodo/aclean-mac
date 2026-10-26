import Foundation

/// The value never escapes by reference. All reads, mutations and compound operations hold the lock.
final class LockedValue<Value>: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var value: Value
    init(_ value: Value) { self.value = value }
    func withValue<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
        lock.lock(); defer { lock.unlock() }
        return try body(&value)
    }
    func synchronized<Result>(_ body: () throws -> Result) rethrows -> Result {
        lock.lock(); defer { lock.unlock() }
        return try body()
    }
}
