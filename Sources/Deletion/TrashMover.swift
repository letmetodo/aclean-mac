import Foundation

// ============================================================
//  TrashMover —— 安全废纸篓搬运执行器
//
//  安全契约：
//    1. 默认优先调用系统 NSFileManager trashItem(at:resultingItemURL:)；
//    2. 支持 Cleaner.onTrashHook 测试模拟钩子。
// ============================================================

enum TrashMover {
    @discardableResult
    static func trash(_ url: URL) throws -> URL? {
        if let hook = Cleaner.onTrashHook {
            return try hook(url)
        }
        var result: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &result)
        return result as URL?
    }
}
