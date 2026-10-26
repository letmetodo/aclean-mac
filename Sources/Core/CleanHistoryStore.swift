import Foundation

/// 单次清理的聚合记录。
/// 刻意只存数字与模块名，**不存任何文件路径**——历史记录不该变成隐私负担。
struct CleanHistoryEntry: Codable, Sendable, Identifiable {
    var id: UUID = UUID()
    var date: Date
    var moduleTitle: String
    var itemCount: Int
    var bytes: Int64
    var failedCount: Int
}

/// 跨会话的清理历史。
///
/// 解决的问题：清理工具最怕「用了半年，说不清到底有没有用」。
/// 有了累计量，用户每次打开都能看到「这台 Mac 一共腾出过多少」，
/// 也给了产品一个不靠弹窗就能自证价值的地方。
@MainActor
final class CleanHistoryStore {
    static let shared = CleanHistoryStore()

    private let defaults: UserDefaults
    private let storageKey = AppConfig.StorageKeys.cleanHistory
    private let totalBytesKey = AppConfig.StorageKeys.cleanHistory + ".totalBytes"
    private let totalRunsKey = AppConfig.StorageKeys.cleanHistory + ".totalRuns"
    private let limit = 50

    private(set) var entries: [CleanHistoryEntry] = []
    private var cumulativeBytes: Int64 = 0
    private var cumulativeRuns: Int = 0

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    /// 累计释放字节数（跨会话全历史累计，不受最近 50 条明细上限截断）
    var totalBytes: Int64 { max(cumulativeBytes, entries.reduce(0) { $0 + $1.bytes }) }

    /// 累计清理次数（跨会话全历史累计，不受最近 50 条明细上限截断）
    var totalRuns: Int { max(cumulativeRuns, entries.count) }

    /// 最近若干次清理（最多保留最近 50 条明细）
    func recent(_ count: Int = 5) -> [CleanHistoryEntry] {
        Array(entries.prefix(count))
    }

    /// 记录一次清理。没有任何实际动作时不记账，避免历史里塞满空记录。
    func record(moduleTitle: String, itemCount: Int, bytes: Int64, failedCount: Int) {
        guard bytes > 0 || itemCount > 0 else { return }
        cumulativeBytes = totalBytes + max(0, bytes)
        cumulativeRuns = totalRuns + 1
        entries.insert(
            CleanHistoryEntry(
                date: Date(),
                moduleTitle: moduleTitle,
                itemCount: itemCount,
                bytes: bytes,
                failedCount: failedCount
            ),
            at: 0
        )
        if entries.count > limit {
            entries.removeLast(entries.count - limit)
        }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([CleanHistoryEntry].self, from: data) else {
            entries = []
            cumulativeBytes = Int64(defaults.integer(forKey: totalBytesKey))
            cumulativeRuns = defaults.integer(forKey: totalRunsKey)
            return
        }
        entries = decoded
        let entriesSum = decoded.reduce(Int64(0)) { $0 + $1.bytes }
        let storedBytes = (defaults.object(forKey: totalBytesKey) as? NSNumber)?.int64Value ?? 0
        let storedRuns = defaults.integer(forKey: totalRunsKey)
        cumulativeBytes = max(storedBytes, entriesSum)
        cumulativeRuns = max(storedRuns, decoded.count)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: storageKey)
        defaults.set(NSNumber(value: cumulativeBytes), forKey: totalBytesKey)
        defaults.set(cumulativeRuns, forKey: totalRunsKey)
    }
}
