import Foundation
import AppKit
import UserNotifications

/// 长任务完成通知。
///
/// 场景：扫描 / 清理动辄几十秒，用户切到别的应用后，窗口里的进度与结果都看不见了。
/// 这里在任务结束时补一个系统级回音，用户不必反复切回来确认。
///
/// 两条刻意的克制：
/// 1. 窗口在前台时不发——用户正看着结果，弹通知是打扰。
/// 2. 未授权或用户关掉开关时静默失败，绝不弹二次索取授权的对话框。
@MainActor
enum CompletionNotifier {

    /// 扫描结束。只在扫描真正跑完（非中断）时调用。
    static func scanFinished(moduleTitle: String, itemCount: Int, bytes: Int64) {
        deliver(
            title: L10n.localized(.notifyScanFinishedTitle),
            body: L10n.format(.notifyScanFinishedBodyFormat, moduleTitle, itemCount, Fmt.size(bytes))
        )
    }

    /// 清理结束。`failedCount > 0` 时如实告知有多少项没清掉，不做粉饰。
    static func cleanFinished(moduleTitle: String, bytes: Int64, failedCount: Int) {
        let body: String = failedCount > 0
            ? L10n.format(.notifyCleanPartialBodyFormat, moduleTitle, Fmt.size(bytes), failedCount)
            : L10n.format(.notifyCleanFinishedBodyFormat, moduleTitle, Fmt.size(bytes))
        deliver(title: L10n.localized(.notifyCleanFinishedTitle), body: body)
    }

    private static func deliver(title: String, body: String) {
        guard AppConfigStore.shared.notifyOnCompletion else { return }
        // 前台时用户正看着窗口，无需系统通知；未初始化 NSApp（如单元测试）时直接跳过
        guard let app = NSApp, !app.isActive else { return }

        Task {
            let center = UNUserNotificationCenter.current()
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            try? await center.add(request)
        }
    }
}
