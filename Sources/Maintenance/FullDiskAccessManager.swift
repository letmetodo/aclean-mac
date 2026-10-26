import AppKit
import Foundation

/// 完全磁盘访问权限 (Full Disk Access / FDA) 底层系统调用检测与注册管理器
///
/// 核心原则：
/// 1. 使用真实系统调用 (FileHandle.read / contentsOfDirectory) 探测，避免 metadata APIs
///    (如 fileExists / isReadableFile) 在 TCC 触发前短路返回，确保 CleanMate 被 macOS 登记在 FDA 列表中；
/// 2. 100% 遵从 DNA 宪章：绝对不触碰 Library/Mail 路径；
/// 3. 不越权触碰 Messages、Contacts、Calendars 或 Photos，杜绝触发无关隐私权限弹窗。
final class FullDiskAccessManager: Sendable {
    static let shared = FullDiskAccessManager()

    private init() {}

    /// 真实 FDA 专有只读探针列表 (仅受 SystemPolicyAllFiles 门控)
    /// 注意：严格避开 ~/Library/Mail (DNA禁令) 以及通讯录、照片、信息等独立 TCC 目录
    private var fdaProbes: [String] {
        AppConfig.Security.fdaProbePaths
    }

    /// 检查是否已获得完全磁盘访问权限 (FDA)
    enum AccessStatus: Equatable, Sendable { case unknown, limited, granted, error }
    var accessStatus: AccessStatus {
        var denied = false, failed = false
        for path in fdaProbes {
            var st = stat()
            if lstat(path, &st) != 0 {
                if errno == EACCES || errno == EPERM { denied = true }
                else if errno != ENOENT { failed = true }
                continue
            }
            do {
                try readProbe(path: path, isDirectory: st.st_mode & S_IFMT == S_IFDIR)
                return .granted
            } catch {
                switch CleanupFailure.classify(error) {
                case .permission: denied = true
                case .missing: break // A missing probe does not prove permission denial.
                default: failed = true
                }
            }
        }
        if denied { return .limited }
        if failed { return .error }
        return .unknown
    }
    var hasFullDiskAccess: Bool { accessStatus == .granted }

    /// 真实读取探测：执行内核 TCC 真正评估的 syscall。
    /// 目录执行 contentsOfDirectory，文件执行 FileHandle.read(upToCount: 1)。
    @discardableResult
    func canActuallyRead(path: String) -> Bool {
        var st = stat()
        guard lstat(path, &st) == 0 else { return false }
        do {
            try readProbe(path: path, isDirectory: st.st_mode & S_IFMT == S_IFDIR)
            return true
        } catch { return false }
    }

    private func readProbe(path: String, isDirectory: Bool) throws {
        if isDirectory {
            _ = try FileManager.default.contentsOfDirectory(atPath: path)
        } else {
            let handle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
            defer { try? handle.close() }
            _ = try handle.read(upToCount: 1)
        }
    }

    /// 唤醒系统 TCC 登记：在后台 utility 队列尝试读取 FDA 专有路径。
    /// 即使读取失败，macOS 也会将发出系统调用的 AClean 登记到系统设置的 FDA 列表中。
    func triggerRegistration() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            for path in self.fdaProbes {
                _ = self.canActuallyRead(path: path)
            }
        }
    }

    /// 打开系统设置的「完全磁盘访问权限」面板
    func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    func openSystemSettings() {
        openFullDiskAccessSettings()
    }

    /// 在访达 (Finder) 中高亮并定位 AClean.app 本体，方便用户拖拽至设置面板
    func revealAppInFinder() {
        let bundleURL = Bundle.main.bundleURL
        NSWorkspace.shared.activateFileViewerSelecting([bundleURL])
    }

    /// 重置 AClean 的 TCC 登记记录，便于重新触发
    @discardableResult
    func resetFullDiskAccess(bundleID: String? = nil) -> Bool {
        let bid = bundleID ?? Bundle.main.bundleIdentifier ?? "com.personal.aclean"
        let res = Shell.execute("/usr/bin/tccutil", ["reset", "SystemPolicyAllFiles", bid], timeout: 3.0)
        return res.exitCode == 0
    }
}
