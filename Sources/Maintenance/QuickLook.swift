import AppKit
import Quartz

/// 快速查看（QuickLook）—— 对应原版 DataManager 右键菜单的「快速查看」
@MainActor
final class QuickLookHelper: NSObject, @preconcurrency QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    static let shared = QuickLookHelper()
    private var current: URL?

    func preview(_ url: URL) {
        current = url
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.delegate = self
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        current == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        current as NSURL?
    }
}
