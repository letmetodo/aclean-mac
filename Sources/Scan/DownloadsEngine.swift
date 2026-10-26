import Foundation
import AppKit

// ============================================================
//  DownloadsEngine —— 下载历史记录与下载目录分类整理引擎
// ============================================================

enum DownloadsEngine {

    static func scan(progress: (Double, String) -> Void) -> ([DownloadEntry], [ScanGroup]) {
        var entries: [DownloadEntry] = []
        var groups: [ScanGroup] = []

        progress(0.1, tr(.readingSafariDownloadHistory))
        let safari = safariDownloads()
        entries += safari

        progress(0.4, tr(.readingChromeDownloadHistory))
        let chrome = chromeDownloads()
        entries += chrome

        progress(0.7, tr(.categorizingDownloadedFiles))
        groups = leftoverFiles()

        progress(1, tr(.actionDone))
        return (entries.sorted { $0.date > $1.date }, groups)
    }

    /// Safari: ~/Library/Safari/Downloads.plist
    static func safariDownloads() -> [DownloadEntry] {
        let url = RuleRoot.homeLibrary.base.appendingPathComponent("Safari/Downloads.plist")
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let list = plist["DownloadsListByID"] as? [String: Any] else { return [] }
        var out: [DownloadEntry] = []
        for (_, v) in list {
            guard let d = v as? [String: Any] else { continue }
            let path = d["Path"] as? String ?? ""
            let name = (path as NSString).lastPathComponent
            guard !name.isEmpty else { continue }
            let src = d["URL"] as? String ?? ""
            let date = d["DownloadEntryDateAddedKey"] as? Date
            out.append(DownloadEntry(app: "Safari", icon: "safari", fileName: name, url: src,
                                     date: date.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .short) } ?? ""))
        }
        return out
    }

    /// Chrome: 复制 History 库到临时目录后用 sqlite3 查询 (避免占用锁)
    static func chromeDownloads() -> [DownloadEntry] {
        let root = RuleRoot.homeLibrary.base.appendingPathComponent("Application Support/Google/Chrome")
        guard FileUtil.exists(root.path) else { return [] }
        var out: [DownloadEntry] = []
        for profile in FileUtil.children(of: root) {
            let n = profile.lastPathComponent
            guard n == "Default" || n.hasPrefix("Profile ") else { continue }
            let db = profile.appendingPathComponent("History")
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("cm_chrome_history_\(UUID().uuidString).db")
            try? FileManager.default.copyItem(at: db, to: tmp)
            let sql = "SELECT target_path, tab_url, datetime(start_time/1000000-11644473600,'unixepoch','localtime') FROM downloads ORDER BY start_time DESC LIMIT 200;"
            let res = Shell.run("/usr/bin/sqlite3", ["-separator", "\u{1}", tmp.path, sql])
            try? FileManager.default.removeItem(at: tmp)
            for line in res.split(separator: "\n") {
                let parts = line.split(separator: "\u{1}", omittingEmptySubsequences: false).map(String.init)
                guard parts.count >= 3 else { continue }
                let path = parts[0]
                let name = (path as NSString).lastPathComponent
                guard !name.isEmpty else { continue }
                out.append(DownloadEntry(app: "Chrome", icon: "globe", fileName: name,
                                         url: parts[1], date: parts[2]))
            }
        }
        return out
    }

    static func categoryTitle(for kind: String) -> String {
        let key: L10nKey
        switch kind {
        case "Documents": key = .downloadKindDocuments
        case "Images": key = .downloadKindImages
        case "Videos": key = .downloadKindVideos
        case "Audio": key = .downloadKindAudio
        case "Archives": key = .downloadKindArchives
        case "Installers": key = .downloadKindInstallers
        case "Applications": key = .downloadKindApplications
        default: key = .other
        }
        return L10n.localized(key)
    }

    /// 下载目录里按类型归类（尊重用户白名单）
    static func leftoverFiles() -> [ScanGroup] {
        let dl = RuleRoot.home.base.appendingPathComponent("Downloads")
        guard FileUtil.exists(dl.path), !AppConfigStore.shared.isPathIgnoredForDisplay(dl.path) else { return [] }
        var buckets: [String: [ScanItem]] = [:]
        let map = AppConfig.Organize.fileKindMap
        for f in FileUtil.children(of: dl) {
            if AppConfigStore.shared.isPathIgnoredForDisplay(f.path) { continue }
            let ext = f.pathExtension.lowercased()
            let bucket = map[ext] ?? "Other"
            let s = FileUtil.size(of: f)
            guard s > 0 else { continue }
            buckets[bucket, default: []].append(ScanItem(url: f, name: f.lastPathComponent, size: s,
                                                         note: categoryTitle(for: bucket), safety: .caution,
                                                         authorizationContext: .organizeManual))
        }
        return buckets.keys.sorted().map { k in
            let category = categoryTitle(for: k)
            return ScanGroup(title: L10n.format(.downloadsCategoryPrefixFormat, category), icon: "arrow.down.circle",
                      note: L10n.format(.downloadFilesCategoryNoteFormat, category), safety: .caution,
                      items: buckets[k]!.sorted { $0.size > $1.size })
        }
    }
}
