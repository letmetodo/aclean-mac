import Foundation
import SwiftUI

/// 全局唯一的清理执行运行时会话 (F3)
final class ActiveCleanupRun: @unchecked Sendable {
    let runID = UUID()
    let moduleKey: String
    let moduleTitle: String
    let stopFlag = StopFlag()
    let startTime = Date()

    // MARK: - 暂停 / 续传
    //
    // 暂停的语义刻意定得很窄：**只在两个目标之间生效**，绝不打断单个目标的处理。
    // 单个目标内部包含「校验 → 移动 → 记账」多个步骤，中途挂起会让文件停在
    // 半完成状态；而在目标之间暂停，已完成项与待处理队列天然一致，恢复后无需补偿。
    //
    // 停止优先于暂停：暂停期间点停止会立即退出等待，不会卡住。

    private let pauseCondition = NSCondition()
    private var paused = false

    /// 最长等待时间，防止用户离开后后台线程永久挂起。
    private static let maxPauseDuration: TimeInterval = 30 * 60

    var isPaused: Bool {
        pauseCondition.lock()
        defer { pauseCondition.unlock() }
        return paused
    }

    func pause() {
        pauseCondition.lock()
        paused = true
        pauseCondition.unlock()
    }

    func resume() {
        pauseCondition.lock()
        paused = false
        pauseCondition.broadcast()
        pauseCondition.unlock()
    }

    /// 在目标之间调用：若已暂停则阻塞等待，直到恢复、停止或超时。
    /// - Returns: true 表示因暂停实际等待过
    @discardableResult
    func waitWhilePausedIfNeeded() -> Bool {
        pauseCondition.lock()
        defer { pauseCondition.unlock() }
        guard paused else { return false }

        let deadline = Date().addingTimeInterval(Self.maxPauseDuration)
        var didWait = false
        while paused && !stopFlag.value && Date() < deadline {
            didWait = true
            pauseCondition.wait(until: Date().addingTimeInterval(0.2))
        }
        // 超时或停止后自动解除暂停态，避免 UI 停留在「已暂停」而实际已继续
        paused = false
        return didWait
    }

    init(moduleKey: String, moduleTitle: String) {
        self.moduleKey = moduleKey
        self.moduleTitle = moduleTitle
    }
}
