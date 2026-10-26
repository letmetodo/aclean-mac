import Foundation
import AppKit
import Darwin

// MARK: - 文件系统工具

/// 带遍历完整性证明的文件/目录体积测量结果
struct FileSizeMeasurement: Sendable, Equatable {
    let bytes: Int64
    /// 仅当目标及全部递归子项均成功完成 lstat/fts_read，无任何权限错误、I/O 报错、TCC/云盘跳过或取消中断时为 true
    let isComplete: Bool
}

enum FileUtil {

    static var fm: FileManager { FileManager.default }
    private static let homePathPrefix: String = fm.homeDirectoryForCurrentUser.standardizedFileURL.path

    /// 判断路径是否属于 macOS TCC 强拦截或 Apple 私有守护进程目录（直接调用 open/enumerator 会在无 FDA 时触发 tccd 内核级阻塞）
    static func isTCCOrApplePrivateBlocked(_ rawPath: String) -> Bool {
        guard !rawPath.isEmpty else { return false }
        let p = rawPath
        let low = p.lowercased()

        // 1. ~/Library/Caches 下受 TCC 严格保护的私有守护进程缓存（绝不可枚举或清理，收敛至 AppConfig.Paths）
        let tccCachesExact = AppConfig.Paths.tccCachesExact
        let currentHomePrefix = home.standardizedFileURL.path
        let cachesPrefixes = Set([
            (homePathPrefix + "/Library/Caches/").lowercased(),
            (currentHomePrefix + "/Library/Caches/").lowercased()
        ])
        for cachesPrefix in cachesPrefixes where low.hasPrefix(cachesPrefix) {
            let rel = String(low.dropFirst(cachesPrefix.count))
            let firstComp = rel.split(separator: "/").first.map(String.init) ?? rel
            if tccCachesExact.contains(firstComp) { return true }
            if firstComp.hasPrefix("com.apple.")
                && !firstComp.hasPrefix("com.apple.dt.")
                && !firstComp.hasPrefix("com.apple.playgrounds")
                && firstComp != "com.apple.appstore" {
                return true
            }
        }

        // 1.2 /Library/Caches 系统根缓存中的 Apple 系统守护进程目录与 datavault
        let rootCachesPrefix = "/library/caches/"
        if low.hasPrefix(rootCachesPrefix) {
            let rel = String(low.dropFirst(rootCachesPrefix.count))
            let firstComp = rel.split(separator: "/").first.map(String.init) ?? rel
            if firstComp.contains("datavault") { return true }
            if firstComp.hasPrefix("com.apple.") && !firstComp.hasPrefix("com.apple.dt.") {
                return true
            }
        }
        if low.contains("datavault") || low.contains("classicdatavault") { return true }

        // 2. ~/Library/Containers 与 Group Containers 下的 Apple 系统级沙盒容器
        let containersPrefix = (homePathPrefix + "/Library/Containers/").lowercased()
        if low.hasPrefix(containersPrefix) {
            let rel = String(low.dropFirst(containersPrefix.count))
            let firstComp = rel.split(separator: "/").first.map(String.init) ?? rel
            if firstComp.hasPrefix("com.apple.") && !firstComp.hasPrefix("com.apple.dt.") {
                return true
            }
        }
        let groupContainersPrefix = (homePathPrefix + "/Library/Group Containers/").lowercased()
        if low.hasPrefix(groupContainersPrefix) {
            let rel = String(low.dropFirst(groupContainersPrefix.count))
            let firstComp = rel.split(separator: "/").first.map(String.init) ?? rel
            if firstComp.hasPrefix("group.com.apple.") {
                return true
            }
        }

        // 3. ~/Library 下 TCC 隐私敏感子目录（邮件/信息/Safari/HomeKit/通讯录/日历/生物特征/TCC 数据库等）
        let libPrefix = (homePathPrefix + "/Library/").lowercased()
        if low.hasPrefix(libPrefix) {
            let rel = String(low.dropFirst(libPrefix.count))
            let blockedLibPrefixes = AppConfig.Paths.blockedLibPrefixes
            for b in blockedLibPrefixes {
                if rel == b || rel.hasPrefix(b + "/") {
                    return true
                }
            }
        }

        return false
    }

    /// 获取路径对应的挂载卷已用空间（若是独立挂载卷，直接取 statfs，快且准）
    static func mountedVolumeUsedSize(_ path: String) -> Int64? {
        var stat = statfs()
        guard statfs(path, &stat) == 0 else { return nil }
        let bsize = Int64(stat.f_bsize)
        let used = (Int64(stat.f_blocks) - Int64(stat.f_bfree)) * bsize
        let mntName = withUnsafeBytes(of: &stat.f_mntonname) {
            String(cString: $0.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        let standardPath = URL(fileURLWithPath: path).standardized.path
        let standardMnt = URL(fileURLWithPath: mntName).standardized.path
        if standardMnt == standardPath {
            if standardMnt != "/" && standardMnt != "/System/Volumes/Data" {
                return max(used, 0)
            }
        }
        return nil
    }

    /// 递归测量目录体积并返回遍历完整性状态
    static func measureDirectorySize(_ url: URL) -> FileSizeMeasurement {
        let p = url.path
        guard !p.isEmpty,
              !IOScanContext.isCancelled,
              !isTCCOrApplePrivateBlocked(p),
              !JunkEngine.isCloudOrSyncProviderPath(p) else {
            return FileSizeMeasurement(bytes: 0, isComplete: false)
        }
        var rootStat = stat()
        guard lstat(p, &rootStat) == 0, (rootStat.st_mode & S_IFMT) == S_IFDIR else {
            IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: p)
            return FileSizeMeasurement(bytes: 0, isComplete: false)
        }
        guard access(p, R_OK | X_OK) == 0 else {
            IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: p)
            return FileSizeMeasurement(bytes: 0, isComplete: false)
        }
        let cPath = strdup(p)
        defer { free(cPath) }
        var argv: [UnsafeMutablePointer<CChar>?] = [cPath, nil]
        guard let fts = fts_open(&argv, FTS_PHYSICAL | FTS_NOCHDIR | FTS_XDEV, nil) else {
            IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: p)
            return FileSizeMeasurement(bytes: 0, isComplete: false)
        }
        defer { fts_close(fts) }
        struct HardLinkID: Hashable {
            let dev: dev_t
            let ino: ino_t
        }
        var total: Int64 = 0
        var seen = Set<HardLinkID>()
        var isComplete = true
        var visitedEntries = 0
        defer { IOScanContext.addInspectedEntries(visitedEntries) }
        errno = 0
        while let ent = fts_read(fts) {
            if IOScanContext.isCancelled {
                isComplete = false
                break
            }
            let info = Int32(ent.pointee.fts_info)
            if info != FTS_DP {
                visitedEntries += 1
            }
            if info == FTS_ERR || info == FTS_DNR || info == FTS_NS {
                IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(ent.pointee.fts_errno)), path: p)
                isComplete = false
                errno = 0
                continue
            }
            if info == FTS_D, let raw = ent.pointee.fts_path {
                let path = String(cString: raw)
                if let stat = ent.pointee.fts_statp, stat.pointee.st_dev != rootStat.st_dev {
                    fts_set(fts, ent, FTS_SKIP)
                    isComplete = false
                } else if isTCCOrApplePrivateBlocked(path) || JunkEngine.isCloudOrSyncProviderPath(path) {
                    fts_set(fts, ent, FTS_SKIP)
                    IOScanContext.current?.record(L10n.localized(.safetyInspectionIncomplete) + ": " + path)
                    isComplete = false
                }
            } else if info == FTS_F, let stat = ent.pointee.fts_statp {
                if stat.pointee.st_nlink > 1 {
                    let identity = HardLinkID(dev: stat.pointee.st_dev, ino: stat.pointee.st_ino)
                    guard !seen.contains(identity) else { continue }
                    if let raw = ent.pointee.fts_path {
                        let entryPath = String(cString: raw)
                        guard shouldCountHardLink(dev: stat.pointee.st_dev, ino: stat.pointee.st_ino, filePath: entryPath) else {
                            continue
                        }
                    }
                    seen.insert(identity)
                }
                total += max(0, Int64(stat.pointee.st_blocks) * 512)
            } else if info == FTS_DEFAULT, let stat = ent.pointee.fts_statp {
                let m = stat.pointee.st_mode & S_IFMT
                if m != S_IFREG && m != S_IFDIR && m != S_IFLNK && m != S_IFSOCK && m != S_IFIFO {
                    isComplete = false
                }
            }
            errno = 0
        }
        if !IOScanContext.isCancelled && errno != 0 {
            IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: p)
            isComplete = false
        }
        if IOScanContext.isCancelled {
            isComplete = false
        }
        return FileSizeMeasurement(bytes: total, isComplete: isComplete)
    }

    /// Explicit reset affects only the current scan, never another scan or directory request.
    static func resetHardLinkLedger() {
        IOScanContext.current?.resetHardLinkAttribution()
    }

    /// Outside a scan, a measurement always describes the target itself.
    static func shouldCountHardLink(dev: dev_t, ino: ino_t, filePath: String) -> Bool {
        IOScanContext.current?.claimHardLink(device: dev, inode: ino, path: filePath) ?? true
    }

    /// 测试钩子：用于审计单次体积测量与保壳目录不重复遍历
    #if DEBUG
    static nonisolated(unsafe) var onMeasureSizeHook: ((URL) -> Void)? = nil
    #else
    static var onMeasureSizeHook: ((URL) -> Void)? { nil }
    #endif

    /// 测量单个文件或目录体积并返回遍历完整性状态
    static func measureSize(of url: URL) -> FileSizeMeasurement {
        onMeasureSizeHook?(url)
        let p = url.path
        guard !p.isEmpty,
              !IOScanContext.isCancelled,
              !isTCCOrApplePrivateBlocked(p),
              !JunkEngine.isCloudOrSyncProviderPath(p) else {
            return FileSizeMeasurement(bytes: 0, isComplete: false)
        }
        var st = stat()
        guard lstat(p, &st) == 0 else {
            IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: p)
            return FileSizeMeasurement(bytes: 0, isComplete: false)
        }
        let mode = st.st_mode & S_IFMT
        if mode == S_IFDIR {
            return measureDirectorySize(url)
        } else if mode == S_IFREG {
            if st.st_nlink > 1 && !shouldCountHardLink(dev: st.st_dev, ino: st.st_ino, filePath: p) {
                return FileSizeMeasurement(bytes: 0, isComplete: true)
            }
            let blocks = Int64(st.st_blocks) * 512
            return FileSizeMeasurement(bytes: max(0, blocks), isComplete: true)
        } else if mode == S_IFLNK || mode == S_IFSOCK || mode == S_IFIFO {
            return FileSizeMeasurement(bytes: 0, isComplete: true)
        }
        return FileSizeMeasurement(bytes: 0, isComplete: false)
    }

    /// 目录体积(基于 C 级 fts_read 极速递归,跳过无权限与 TCC 阻塞项；若测量不完整则向当前扫描会话记录覆盖诊断)
    static func directorySize(_ url: URL) -> Int64 {
        let m = measureDirectorySize(url)
        if !m.isComplete && !IOScanContext.isCancelled {
            IOScanContext.current?.record(L10n.localized(.scanCoverageIncomplete) + ": " + url.path)
        }
        return m.bytes
    }

    /// 单个文件/目录体积（若测量不完整则向当前扫描会话记录覆盖诊断）
    static func size(of url: URL) -> Int64 {
        let m = measureSize(of: url)
        if !m.isComplete && !IOScanContext.isCancelled {
            IOScanContext.current?.record(L10n.localized(.scanCoverageIncomplete) + ": " + url.path)
        }
        return m.bytes
    }

    /// 列出一级子项（包含隐藏项）；TCC 拦截及读取错误保留覆盖诊断。
    static func children(of url: URL, keys: [URLResourceKey] = [.isDirectoryKey]) -> [URL] {
        let p = url.path
        guard !isTCCOrApplePrivateBlocked(p) else {
            IOScanContext.current?.record(L10n.localized(.scanCoverageIncomplete) + ": " + p)
            return []
        }
        guard access(p, R_OK | X_OK) == 0 else {
            IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: p)
            return []
        }
        do {
            return try fm.contentsOfDirectory(at: url,
                includingPropertiesForKeys: keys, options: [])
        } catch {
            IOScanContext.record(error, path: p)
            return []
        }
    }

    static func exists(_ path: String) -> Bool {
        guard !isTCCOrApplePrivateBlocked(path) else { return false }
        var st = stat()
        if lstat(path, &st) == 0 { return true }
        if errno != ENOENT && errno != ENOTDIR {
            IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: path)
        }
        return false
    }

    /// 同步执行一个外部命令并返回 stdout（失败返回 nil）。
    /// 只用于读取系统信息（如 dscl 列用户），不做任何写操作。
    static func shell(_ launch: String, args: [String]) -> String? {
        let output = Shell.run(launch, args)
        return output.isEmpty ? nil : output
    }

    /// 受保护路径:任何情况下都拒绝删除,防止灾难性误删
    static func isProtected(_ url: URL) -> Bool {
        let p = url.standardizedFileURL.path.lowercased()
        let home = home.standardizedFileURL.path.lowercased()

        // 根目录本身 (收敛至 AppConfig.Paths)
        let exactRoots = AppConfig.Paths.exactProtectedRoots
        if exactRoots.contains(where: { $0.lowercased() == p }) { return true }
        if p == home { return true }
        if AppConfig.Paths.topLevelContainers.contains(p.lowercased()) { return true }

        // 只读系统卷与系统敏感目录的子树:一个字节都不能碰 (收敛至 AppConfig.Paths)
        let subtreeRoots = AppConfig.Paths.protectedSubtreeRoots
        for r in subtreeRoots.map({ $0.lowercased() }) where p.hasPrefix(r + "/") || p == r { return true }

        let critical = AppConfig.Paths.criticalHomeDirectories
        for c in critical where p == "\(home)/\(c.lowercased())" { return true }

        // 保护钥匙串目录子树
        if p.hasPrefix("\(home)/library/keychains/") { return true }

        // 照片图库包(.photoslibrary)整体受保护：
        // 其内部文件由 Photos 数据库严格索引，外部删除会破坏图库一致性，
        // 因此任何情况下都拒绝由本工具移除其中文件（对齐 DNA「安全至上」）。
        if p.contains(".photoslibrary/") || p.hasSuffix(".photoslibrary") { return true }

        return false
    }

    #if DEBUG
    static nonisolated(unsafe) var homeOverrideForTesting: URL? = nil
    #else
    static var homeOverrideForTesting: URL? { nil }
    #endif
    private static let currentUserHome = fm.homeDirectoryForCurrentUser
    static var home: URL { homeOverrideForTesting ?? currentUserHome }
    static func lib(_ sub: String) -> URL { home.appendingPathComponent("Library/\(sub)") }

    /// 判断 child 是否为 parent 的严格子项（避免 parent 自身或同名同前缀目录命中，如 ~/.TrashBackup）
    static func isStrictDescendant(_ childURL: URL, of parentURL: URL) -> Bool {
        let child = childURL.standardizedFileURL.pathComponents
        let parent = parentURL.standardizedFileURL.pathComponents
        return child.count > parent.count && child.starts(with: parent)
    }

    /// 获取当前用户合法的废纸篓根目录列表（本机 ~/.Trash 及各已挂载卷下属当前 UID 的 .Trashes/<uid>）
    static func authorizedTrashRoots() -> [URL] {
        var roots: [URL] = [home.appendingPathComponent(".Trash")]
        let uid = getuid()
        let volumes = children(of: URL(fileURLWithPath: "/Volumes"))
        for v in volumes {
            let userVolTrash = v.appendingPathComponent(".Trashes/\(uid)")
            if exists(userVolTrash.path) {
                roots.append(userVolTrash)
            }
        }
        return roots
    }
}


// MARK: - 线程安全计数器（并行扫描时上报进度用）

final class ProgressCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var n = 0
    func increment() -> Int {
        lock.lock(); defer { lock.unlock() }
        n += 1
        return n
    }
    /// 批量累加，返回累加后的总数（并行扫描里按批次上报，减少锁竞争）
    @discardableResult
    func add(_ k: Int) -> Int {
        lock.lock(); defer { lock.unlock() }
        n += k
        return n
    }
    var value: Int {
        lock.lock(); defer { lock.unlock() }
        return n
    }
}

// MARK: - 磁盘信息

struct DiskInfo {
    var total: Int64 = 0
    /// 用户真实可用容量（优先使用 volumeAvailableCapacityForImportantUsage，与 macOS「系统设置 -> 储存空间」一致）
    var free: Int64 = 0
    /// 底层未分配物理块可用容量（volumeAvailableCapacity）
    var rawFree: Int64 = 0
    /// 含「可清除(purgeable)」空间的可用容量（volumeAvailableCapacityForImportantUsage）
    var freeForImportantUsage: Int64 = 0
    var used: Int64 { max(0, total - free) }
    var usedRatio: Double { total > 0 ? Double(used) / Double(total) : 0 }
    /// APFS 可清除空间估算 = 重要用途可用容量 - 底层未分配块可用容量
    var purgeable: Int64 { max(0, freeForImportantUsage - rawFree) }

    static func current() -> DiskInfo {
        var d = DiskInfo()
        let url = URL(fileURLWithPath: "/")
        if let v = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey,
                                                     .volumeAvailableCapacityKey,
                                                     .volumeAvailableCapacityForImportantUsageKey]) {
            let totalVal = Int64(v.volumeTotalCapacity ?? 0)
            let rawVal = Int64(v.volumeAvailableCapacity ?? 0)
            let impVal = Int64(v.volumeAvailableCapacityForImportantUsage ?? 0)
            d.total = totalVal
            d.rawFree = rawVal
            d.freeForImportantUsage = impVal
            // 与 macOS「系统设置 -> 储存空间」及 Finder 保持一致，展示含可自动回收缓存的真实可用空间
            d.free = impVal > 0 ? impVal : rawVal
        }
        return d
    }
}
