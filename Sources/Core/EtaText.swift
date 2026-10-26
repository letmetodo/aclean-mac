import Foundation

/// 长任务剩余时间的口语化描述。
///
/// 只做两档（秒 / 分钟），刻意不做到「时:分:秒」的精确倒计时：
/// 清理扫描的吞吐波动很大，精确到秒的数字反而让人觉得不靠谱。
enum EtaText {
    /// - Parameter seconds: 预计剩余秒数，调用方需保证已通过可信度校验
    static func describe(_ seconds: TimeInterval) -> String {
        let total = max(1, Int(seconds.rounded()))
        if total < 60 {
            return L10n.format(.etaSecondsFormat, total)
        }
        let minutes = max(1, total / 60)
        return L10n.format(.etaMinutesFormat, minutes)
    }
}
