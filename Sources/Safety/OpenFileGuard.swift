import Foundation
import Darwin

/// OpenFileGuard 句柄占用检查的证明范围语义（Section 3.5.2）
enum OpenFileCheckScope: String, Sendable, Equatable {
    /// 仅证明当前登录 UID (`-u getuid()`) 下的进程未打开目标文件或其后代、SQLite `-wal/-shm/-journal` 附属文件；
    /// 不证明 root、系统守护进程（launchd daemons）或其他用户的句柄状态。
    case currentUserOnly = "current_user_only"
}

/// Read-only occupancy checks. Only UI recommendation may reuse a snapshot.
/// Execution always queries the current target; errors/warnings never mean idle.
enum OpenFileGuard {
    /// 显式声明当前句柄检查器的证明范围：仅覆盖当前登录 UID 进程
    static let checkScope: OpenFileCheckScope = .currentUserOnly

    struct Snapshot: @unchecked Sendable {
        final class PathComponentTrieNode {
            var children: [Substring: PathComponentTrieNode] = [:]
            var isTerminal: Bool = false
        }

        let paths: [String]
        let exact: Set<String>
        private let trieRoot = PathComponentTrieNode()

        init(paths: [String]) {
            // Deduplicate before filesystem work: lsof repeats mapped libraries for every process.
            let deduplicated = Set(Set(paths).map { OpenFileGuard.normalize(URL(fileURLWithPath: $0)) })
            exact = deduplicated
            self.paths = deduplicated.sorted()
            for p in deduplicated {
                var current = trieRoot
                for comp in p.split(separator: "/", omittingEmptySubsequences: true) {
                    if let next = current.children[comp] {
                        current = next
                    } else {
                        let next = PathComponentTrieNode()
                        current.children[comp] = next
                        current = next
                    }
                }
                current.isTerminal = true
            }
        }

        func contains(_ target: URL) -> Bool {
            let root = OpenFileGuard.normalize(target)
            if OpenFileGuard.sqliteFamily(root).contains(where: exact.contains) { return true }
            var current = trieRoot
            for comp in root.split(separator: "/", omittingEmptySubsequences: true) {
                guard let next = current.children[comp] else { return false }
                current = next
            }
            return !current.children.isEmpty
        }
    }

    static func canonicalScopeURL(_ url: URL) -> URL {
        let resolved = url.resolvingSymlinksInPath().standardizedFileURL.path
        let canonical = SymlinkGuard.canonicalizeMacOSSystemPrefix(resolved)
        return URL(fileURLWithPath: canonical).standardizedFileURL
    }

    /// 按规范化物理路径组件边界判定目标是否位于系统共享域或跨用户域（Section 3.5.3）：
    /// - `/Library`、`/System`、`/private/var` 的自身或严格子项；
    /// - `/Users` 自身，或位于 `/Users` 下但既非 `currentHome` 也非 `currentHome` 的严格子项。
    static func isSystemSharedScopePath(_ url: URL, currentHome: URL = FileUtil.home, assumeNoSymlinks: Bool = false) -> Bool {
        let targetURL = assumeNoSymlinks
            ? URL(fileURLWithPath: SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path))
            : canonicalScopeURL(url)
        let homeURL = assumeNoSymlinks
            ? URL(fileURLWithPath: SymlinkGuard.canonicalizeMacOSSystemPrefix(currentHome.standardizedFileURL.path))
            : canonicalScopeURL(currentHome)
        let systemSharedRoots = ["/Library", "/System", "/private/var"].map {
            URL(fileURLWithPath: $0).standardizedFileURL
        }
        for root in systemSharedRoots {
            if targetURL == root || FileUtil.isStrictDescendant(targetURL, of: root) {
                return true
            }
        }
        let usersRoot = URL(fileURLWithPath: "/Users").standardizedFileURL
        if targetURL == usersRoot {
            return true
        }
        if FileUtil.isStrictDescendant(targetURL, of: usersRoot) {
            if targetURL != homeURL && !FileUtil.isStrictDescendant(targetURL, of: homeURL) {
                return true
            }
        }
        return false
    }

    /// 核验目录内所有后代是否均属于当前登录 UID 且未跨卷（任一后代 UID 不属于当前用户或无法完整遍历均返回 false）
    static func directoryDescendantsMatchCurrentUID(
        _ url: URL,
        rootDevice: dev_t,
        currentUID: uid_t = getuid()
    ) -> Bool {
        let p = url.path
        var rootStat = stat()
        guard !p.isEmpty, lstat(p, &rootStat) == 0 else {
            return false
        }
        guard (rootStat.st_mode & S_IFMT) == S_IFDIR else {
            return true
        }
        guard access(p, R_OK | X_OK) == 0 else {
            return false
        }
        let cPath = strdup(p)
        defer { free(cPath) }
        var argv: [UnsafeMutablePointer<CChar>?] = [cPath, nil]
        guard let fts = fts_open(&argv, FTS_PHYSICAL | FTS_NOCHDIR, nil) else {
            return false
        }
        defer { fts_close(fts) }

        let deadline = ProcessInfo.processInfo.systemUptime + AppConfig.Security.cleanupInspectionTimeout
        let maxItems = AppConfig.Security.cleanupInspectionMaxItems
        let uidOverride = FileIdentity.uidOverrideForTesting
        var count = 0
        defer { IOScanContext.addInspectedEntries(count) }
        while let ent = fts_read(fts) {
            let info = Int32(ent.pointee.fts_info)
            if info == FTS_DP { continue }
            if info == FTS_ERR || info == FTS_DNR || info == FTS_NS {
                return false
            }
            if ent.pointee.fts_level == 0 { continue }
            count += 1
            let timedOut = count > maxItems || ((count & 0x3F) == 0 && ProcessInfo.processInfo.systemUptime > deadline)
            if timedOut {
                IOScanContext.recordTimeoutOrBudgetDegradation()
            }
            if IOScanContext.isCancelled || timedOut {
                return false
            }
            guard let st = ent.pointee.fts_statp,
                  st.pointee.st_dev == rootDevice else {
                return false
            }
            let itemUID: uid_t
            if let uidOverride, let ftsPath = ent.pointee.fts_path {
                let childURL = URL(fileURLWithPath: String(cString: ftsPath))
                itemUID = uidOverride(childURL) ?? st.pointee.st_uid
            } else {
                itemUID = st.pointee.st_uid
            }
            guard itemUID == currentUID else {
                return false
            }
        }
        return !IOScanContext.isCancelled
    }

    /// 判断目标是否处于当前用户 `lsof -u getuid()` 可独立证明未占用的范围（Section 3.5.3）：
    /// 1. 目标必须可获取 `FileIdentity` 且 `resolvedIdentity.uid == currentUID`；
    /// 2. 目标规范化物理路径不得位于系统共享域（`/Library`、`/System`、`/private/var`）或非当前用户 `/Users/*`；
    /// 3. 若目标为目录，其内部所有后代同样必须属于 `currentUID`。
    static func isCurrentUserVerifiableScope(
        _ url: URL,
        identity: FileIdentity? = nil,
        currentUID: uid_t = getuid(),
        currentHome: URL = FileUtil.home,
        checkDescendants: Bool = true,
        requireCurrentUserUID: Bool = true,
        assumeNoSymlinks: Bool = false
    ) -> Bool {
        guard let resolvedIdentity = identity ?? FileIdentity.capture(from: url) else {
            return false
        }
        if requireCurrentUserUID && resolvedIdentity.uid != currentUID {
            return false
        }
        if isSystemSharedScopePath(url, currentHome: currentHome, assumeNoSymlinks: assumeNoSymlinks) {
            return false
        }
        if requireCurrentUserUID && checkDescendants && resolvedIdentity.isDirectory {
            guard directoryDescendantsMatchCurrentUID(url, rootDevice: resolvedIdentity.device, currentUID: currentUID) else {
                return false
            }
        }
        return true
    }

    private static func normalize(_ url: URL) -> String {
        SymlinkGuard.canonicalizeMacOSSystemPrefix(url.resolvingSymlinksInPath().standardizedFileURL.path)
    }
    private static func sqliteFamily(_ path: String) -> [String] {
        let suffixes = AppConfig.Remediation.sqliteSidecarSuffixes
        let base = suffixes.first(where: path.hasSuffix).map { String(path.dropLast($0.count)) } ?? path
        return [base] + suffixes.map { base + $0 }
    }
    static func overlaps(_ target: URL, openPath: String) -> Bool {
        Snapshot(paths: [openPath]).contains(target)
    }

    private static let lock = NSLock()
    private static let refreshLock = NSLock()
    private static let selectionSnapshotStorage = LockedValue<(time: TimeInterval, value: Snapshot?)?>(nil)
    private static var selectionSnapshot: (time: TimeInterval, value: Snapshot?)? {
        get { selectionSnapshotStorage.withValue { $0 } }
        set { selectionSnapshotStorage.withValue { $0 = newValue } }
    }

    /// 测试专用注入钩子：模拟打开文件句柄集合
    #if DEBUG
    static nonisolated(unsafe) var openPathsOverrideForTesting: [String]? = nil {
        didSet { invalidateSelectionSnapshot() }
    }
    #else
    static var openPathsOverrideForTesting: [String]? { nil }
    #endif

    /// 测试专用注入钩子：模拟 lsof 句柄检查失败（超时、非零退出或 stderr 非空）
    #if DEBUG
    static nonisolated(unsafe) var simulateInspectionFailureForTesting: Bool = false {
        didSet { invalidateSelectionSnapshot() }
    }
    #else
    static var simulateInspectionFailureForTesting: Bool { false }
    #endif

    static func invalidateSelectionSnapshot() {
        lock.lock()
        selectionSnapshot = nil
        lock.unlock()
        IOScanContext.current?.invalidateOpenFileSnapshot()
    }

    private static func captureGlobalUserSnapshot() -> Snapshot? {
        if simulateInspectionFailureForTesting {
            IOScanContext.recordDegradation(.openFileInspectionFailed)
            return nil
        }
        if let override = openPathsOverrideForTesting {
            return Snapshot(paths: override)
        }
        let t0 = ProcessInfo.processInfo.systemUptime
        let result = Shell.execute(
            AppConfig.Security.lsofPath,
            AppConfig.Remediation.lsofArguments + ["-u", String(getuid())],
            timeout: AppConfig.Security.fileHandleCheckTimeout
        )
        IOScanContext.recordLsofInvocation(durationMs: (ProcessInfo.processInfo.systemUptime - t0) * 1000.0)
        return snapshot(result, targeted: false)
    }

    /// Exit 1 with empty output is lsof's documented no-match result, only for a target query.
    static func snapshot(_ result: ShellResult, targeted: Bool) -> Snapshot? {
        guard result.exitCode != -2 else {
            IOScanContext.recordTimeoutOrBudgetDegradation()
            IOScanContext.recordDegradation(.openFileInspectionFailed)
            return nil
        }
        guard result.stderr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            IOScanContext.recordDegradation(.openFileInspectionFailed)
            return nil
        }
        if targeted && result.exitCode == 1 && result.stdout.isEmpty { return Snapshot(paths: []) }
        guard result.isSuccess else {
            IOScanContext.recordDegradation(.openFileInspectionFailed)
            return nil
        }
        let fields = result.stdout.split(separator: "\n")
        guard fields.contains(where: { $0.hasPrefix("p") && Int32($0.dropFirst()) != nil }),
              fields.contains(where: { $0.hasPrefix("n/") }) else {
            IOScanContext.recordDegradation(.openFileInspectionFailed)
            return nil
        }
        return Snapshot(paths: fields.filter { $0.hasPrefix("n/") }.map { String($0.dropFirst()) })
    }

    static func isIdle(_ target: URL, fresh: Bool = true, requireCurrentUserUID: Bool = true) -> Bool {
        if simulateInspectionFailureForTesting {
            IOScanContext.recordDegradation(.openFileInspectionFailed)
            return false
        }
        if fresh {
            let currentUID = getuid()
            guard let identity = FileIdentity.capture(from: target) else { return false }
            if requireCurrentUserUID {
                guard identity.uid == currentUID else { return false }
                if identity.isDirectory {
                    guard directoryDescendantsMatchCurrentUID(target, rootDevice: identity.device, currentUID: currentUID) else {
                        return false
                    }
                }
            }
            if let override = openPathsOverrideForTesting {
                return !Snapshot(paths: override).contains(target)
            }
            // Limit lsof's output and directory traversal to this target. A global warning is
            // still a denial; no blanket stderr suppression or stale execution cache is used.
            var arguments = AppConfig.Remediation.lsofArguments + ["-a", "-u", String(currentUID)]
            if identity.isDirectory { arguments += ["+D", target.path] }
            let paths = sqliteFamily(target.path).filter { FileUtil.exists($0) }
            guard !paths.isEmpty else { return false }
            arguments += ["--"] + paths
            let t0 = ProcessInfo.processInfo.systemUptime
            let result = Shell.execute(AppConfig.Security.lsofPath, arguments,
                                       timeout: AppConfig.Security.fileHandleCheckTimeout)
            IOScanContext.recordLsofInvocation(durationMs: (ProcessInfo.processInfo.systemUptime - t0) * 1000.0)
            // lsof selects by vnode identity too; even an aliased path is an occupancy result.
            guard let current = snapshot(result, targeted: true) else { return false }
            return current.paths.isEmpty
        }
        // Section 5.1: Reuse the scan-session open-file snapshot across the entire IOScanContext.perform lifecycle
        if let ctx = IOScanContext.current {
            let sessionSnap = ctx.openFileSnapshot {
                lock.lock()
                let existing = selectionSnapshot
                lock.unlock()
                let now = ProcessInfo.processInfo.systemUptime
                if let existing, now - existing.time < AppConfig.Security.openFileSelectionCacheTTL {
                    return existing.value
                }
                let captured = captureGlobalUserSnapshot()
                lock.lock()
                selectionSnapshot = (ProcessInfo.processInfo.systemUptime, captured)
                lock.unlock()
                return captured
            }
            return sessionSnap.map { !$0.contains(target) } ?? false
        }
        lock.lock()
        let cached = selectionSnapshot
        lock.unlock()
        let now = ProcessInfo.processInfo.systemUptime
        if let cached, now - cached.time < AppConfig.Security.openFileSelectionCacheTTL {
            return cached.value.map { !$0.contains(target) } ?? false
        }
        refreshLock.lock()
        defer { refreshLock.unlock() }
        lock.lock()
        let secondCheck = selectionSnapshot
        lock.unlock()
        let recheckNow = ProcessInfo.processInfo.systemUptime
        if let secondCheck, recheckNow - secondCheck.time < AppConfig.Security.openFileSelectionCacheTTL {
            return secondCheck.value.map { !$0.contains(target) } ?? false
        }
        let current = captureGlobalUserSnapshot()
        lock.lock()
        selectionSnapshot = (ProcessInfo.processInfo.systemUptime, current)
        lock.unlock()
        return current.map { !$0.contains(target) } ?? false
    }
}
