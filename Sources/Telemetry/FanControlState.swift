/// Mutated under SMCBridge's lock. Only successful hardware changes create a lease.
struct FanControlState: Sendable {
    var mode = "auto"
    private(set) var generation = 0

    @discardableResult
    mutating func completeChange(to mode: String, succeeded: Bool) -> Int? {
        guard succeeded else { return nil }
        generation += 1
        self.mode = mode
        return generation
    }

    mutating func expireLease(generation expected: Int) -> Bool {
        guard expected == generation, mode != "auto" else { return false }
        mode = "auto"
        generation += 1
        return true
    }
}
