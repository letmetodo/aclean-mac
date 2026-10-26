import Foundation
import AppKit
import Darwin

// ============================================================
//  SpaceEngine —— 空间透镜 (Space Lens) C 级 fts_read 实时流式目录树分析引擎
// ============================================================

enum SpaceEngine {

    /// 目录占用条目。`children` 为真实子目录 + 大文件叶子（多叉树）。
    struct Entry {
        var url: URL
        var size: Int64
        var children: [Entry] = []
        /// 直属小文件（未达大文件阈值）或超出单目录展示上限的合计字节数
        var otherBytes: Int64 = 0
        /// 因单目录展示上限被折叠进「其他」的子项数量
        var omittedCount: Int = 0
        var isCalculating: Bool = false
        var notePrefix: String = ""
        var customName: String? = nil
    }

    private static let estimateKey = "spaceLens.entryEstimate"

    static let scanLogEnabled = ProcessInfo.processInfo.environment["CLEANMATE_SCAN_LOG"] != nil
    static func scanLog(_ s: String) {
        guard scanLogEnabled else { return }
        FileHandle.standardError.write(("[scan] " + s + "\n").data(using: .utf8)!)
    }

    /// 实时可变目录树节点（支持扫描过程中任意时刻生成一致性树快照）
    private final class LiveDir: @unchecked Sendable {
        let path: String
        private var _cachedURL: URL?
        var url: URL {
            if let u = _cachedURL { return u }
            let u = URL(fileURLWithPath: path, isDirectory: true)
            _cachedURL = u
            return u
        }
        let depth: Int
        let isPackage: Bool
        weak var parent: LiveDir?
        var customName: String?
        var isCalculating: Bool = false
        var isScanning: Bool = false
        var notePrefix: String = ""

        var totalBytes: Int64 = 0
        var ownBytes: Int64 = 0
        var otherBytes: Int64 = 0
        var subdirs: [LiveDir] = []
        var directFiles: [Entry] = []

        init(path: String, url: URL? = nil, depth: Int, isPackage: Bool, parent: LiveDir?, customName: String? = nil, isCalculating: Bool = false, isScanning: Bool = false, notePrefix: String = "") {
            self.path = path
            self._cachedURL = url
            self.depth = depth
            self.isPackage = isPackage
            self.parent = parent
            self.customName = customName
            self.isCalculating = isCalculating
            self.isScanning = isScanning
            self.notePrefix = notePrefix
        }
    }

    private static var packageExtensions: Set<String> {
        AppConfig.Organize.packageExtensions
    }

    private static func isPackagePath(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        guard !ext.isEmpty else { return false }
        return packageExtensions.contains(ext)
    }

    // MARK: - 并行流式扫描上下文

    private final class ScanCtx: @unchecked Sendable {
        private struct HardLinkID: Hashable {
            let dev: dev_t
            let ino: ino_t
        }
        let lock = NSLock()
        let counter = ProgressCounter()
        private var seenHardLinks = Set<HardLinkID>()
        func claim(_ stat: stat) -> Bool {
            guard stat.st_nlink > 1 else { return true }
            lock.lock(); defer { lock.unlock() }
            return seenHardLinks.insert(HardLinkID(dev: stat.st_dev, ino: stat.st_ino)).inserted
        }
        let minLargeFile: Int64
        let estimate: Int
        let stopped: () -> Bool
        let progress: (Double, String) -> Void
        let onPartialUpdate: (([Entry]) -> Void)?
        let ignoredPrefixes: [String]
        let ignoredExact: Set<String>

        let maxTreeDepth = AppConfig.Organize.spaceLensMaxDepth
        let maxChildrenPerDir = AppConfig.Organize.spaceLensMaxChildrenPerDir
        let minDirectFileNodeBytes: Int64 = AppConfig.Organize.spaceLensMinDirectFileBytes

        var rootDirs: [LiveDir] = []
        var rootFiles: [Entry] = []
        var rootOtherBytes: Int64 = 0
        var largeFiles: [Entry] = []
        var lastSnapshotTime: TimeInterval = 0
        var lastProgressTime: TimeInterval = 0

        init(minLargeFile: Int64,
             estimate: Int,
             ignored: Set<String>,
             stopped: @escaping () -> Bool,
             progress: @escaping (Double, String) -> Void,
             onPartialUpdate: (([Entry]) -> Void)?) {
            self.minLargeFile = minLargeFile
            self.estimate = max(100_000, estimate)
            self.stopped = stopped
            self.progress = progress
            self.onPartialUpdate = onPartialUpdate
            let validIgnored = ignored.filter { !$0.isEmpty && $0 != "/" }
            self.ignoredExact = Set(validIgnored)
            self.ignoredPrefixes = validIgnored.map { $0 + "/" }
        }

        func isStopped() -> Bool { stopped() }

        func isIgnored(_ path: String) -> Bool {
            guard !ignoredExact.isEmpty else { return false }
            if ignoredExact.contains(path) { return true }
            for prefix in ignoredPrefixes {
                if path.hasPrefix(prefix) { return true }
            }
            return false
        }

        func attachChild(_ child: LiveDir, to parent: LiveDir) {
            lock.lock()
            parent.subdirs.append(child)
            lock.unlock()
        }

        func completeDir(_ dir: LiveDir) {
            lock.lock()
            defer { lock.unlock() }
            dir.isScanning = false
            if !dir.isCalculating && dir.depth >= 3 && dir.totalBytes < 512 * 1024 {
                dir.subdirs.removeAll()
                dir.directFiles.removeAll()
            }
            guard let parent = dir.parent else { return }
            if dir.totalBytes == 0 && !dir.isCalculating {
                if let idx = parent.subdirs.lastIndex(where: { $0 === dir }) {
                    parent.subdirs.remove(at: idx)
                }
                return
            }
            if parent.subdirs.count > maxChildrenPerDir * 2 {
                var activeSubs: [LiveDir] = []
                var finishedSubs: [LiveDir] = []
                activeSubs.reserveCapacity(8)
                finishedSubs.reserveCapacity(parent.subdirs.count)
                for sub in parent.subdirs {
                    if sub.isScanning || sub.isCalculating {
                        activeSubs.append(sub)
                    } else if sub.totalBytes > 0 {
                        finishedSubs.append(sub)
                    }
                }
                if finishedSubs.count > maxChildrenPerDir {
                    finishedSubs.sort { $0.totalBytes > $1.totalBytes }
                    let overflow = finishedSubs.suffix(from: maxChildrenPerDir)
                    for dropped in overflow {
                        parent.otherBytes += dropped.totalBytes
                        dropped.subdirs.removeAll()
                        dropped.directFiles.removeAll()
                    }
                    finishedSubs.removeSubrange(maxChildrenPerDir..<finishedSubs.count)
                }
                parent.subdirs = activeSubs + finishedSubs
            }
        }

        func addLargeFile(_ entry: Entry) {
            lock.lock()
            largeFiles.append(entry)
            lock.unlock()
        }

        func flushDelta(to dir: LiveDir,
                        totalDelta: Int64,
                        ownDelta: Int64,
                        otherDelta: Int64,
                        newDirectFiles: [Entry],
                        newLargeFiles: [Entry],
                        scannedCount: Int,
                        currentName: String) {
            let totalScanned = counter.add(scannedCount)
            let now = ProcessInfo.processInfo.systemUptime
            var shouldEmitSnapshot = false
            var shouldEmitProgress = false

            lock.lock()
            if totalDelta > 0 {
                var cur: LiveDir? = dir
                while let node = cur {
                    node.totalBytes += totalDelta
                    cur = node.parent
                }
            }
            dir.ownBytes += ownDelta
            dir.otherBytes += otherDelta
            if !newDirectFiles.isEmpty {
                dir.directFiles.append(contentsOf: newDirectFiles)
                if dir.directFiles.count > maxChildrenPerDir * 2 {
                    dir.directFiles.sort { $0.size > $1.size }
                    let overflow = dir.directFiles.suffix(from: maxChildrenPerDir)
                    dir.otherBytes += overflow.reduce(Int64(0)) { $0 + $1.size }
                    dir.directFiles.removeSubrange(maxChildrenPerDir..<dir.directFiles.count)
                }
            }
            if !newLargeFiles.isEmpty {
                largeFiles.append(contentsOf: newLargeFiles)
            }
            if now - lastProgressTime >= 0.08 {
                lastProgressTime = now
                shouldEmitProgress = true
            }
            if onPartialUpdate != nil && (now - lastSnapshotTime >= 0.35) {
                lastSnapshotTime = now
                shouldEmitSnapshot = true
            }
            let snapshotEntries: [Entry]? = shouldEmitSnapshot ? buildSnapshotLocked(maxDepth: 4) : nil
            lock.unlock()

            if shouldEmitProgress {
                let p = 0.02 + 0.93 * min(0.985, Double(totalScanned) / Double(estimate))
                progress(p, currentName)
            }
            if let snapshotEntries, !isStopped() {
                onPartialUpdate?(snapshotEntries)
            }
        }

        func buildSnapshot(maxDepth: Int) -> [Entry] {
            lock.lock()
            defer { lock.unlock() }
            return buildSnapshotLocked(maxDepth: maxDepth)
        }

        private func buildSnapshotLocked(maxDepth: Int) -> [Entry] {
            let cap = maxDepth < maxTreeDepth ? 28 : maxChildrenPerDir

            func toEntry(_ d: LiveDir) -> Entry {
                guard d.totalBytes > 0 || d.isCalculating else {
                    return Entry(url: d.url, size: 0, isCalculating: d.isCalculating, notePrefix: d.notePrefix, customName: d.customName)
                }
                if (d.isPackage || d.depth >= maxDepth || (d.depth >= 3 && d.totalBytes < 512 * 1024)) && !d.isCalculating {
                    return Entry(url: d.url, size: d.totalBytes, isCalculating: false, notePrefix: d.notePrefix, customName: d.customName)
                }

                var extraOther = d.otherBytes
                var omitted = 0
                let nonZeroSubs = d.subdirs.filter { $0.totalBytes > 0 || $0.isCalculating }.sorted { $0.totalBytes > $1.totalBytes }
                let keptSubs: ArraySlice<LiveDir>
                if nonZeroSubs.count > cap {
                    keptSubs = nonZeroSubs.prefix(cap)
                    omitted += (nonZeroSubs.count - cap)
                    for dropped in nonZeroSubs.suffix(from: cap) {
                        extraOther += dropped.totalBytes
                    }
                } else {
                    keptSubs = nonZeroSubs[...]
                }

                var kids: [Entry] = []
                kids.reserveCapacity(min(cap, keptSubs.count + d.directFiles.count))
                for sub in keptSubs {
                    kids.append(toEntry(sub))
                }
                kids.append(contentsOf: d.directFiles)
                kids.sort { $0.size > $1.size }

                if kids.count > cap {
                    let overflow = kids.suffix(from: cap)
                    omitted += overflow.count
                    extraOther += overflow.reduce(Int64(0)) { $0 + $1.size }
                    kids.removeSubrange(cap..<kids.count)
                }
                return Entry(url: d.url, size: d.totalBytes, children: kids, otherBytes: extraOther, omittedCount: omitted, isCalculating: d.isCalculating, notePrefix: d.notePrefix, customName: d.customName)
            }

            let sortedRoots = rootDirs.filter { $0.totalBytes > 0 || $0.isCalculating }.sorted { a, b in
                if a.isCalculating && a.customName?.hasPrefix("Users") == true { return true }
                if b.isCalculating && b.customName?.hasPrefix("Users") == true { return false }
                return a.totalBytes > b.totalBytes
            }
            var out: [Entry] = []
            out.reserveCapacity(sortedRoots.count + rootFiles.count)
            for d in sortedRoots {
                out.append(toEntry(d))
            }
            out.append(contentsOf: rootFiles)
            return out
        }
    }

    static func analyzeHome(minLargeFile: Int64,
                            progress: @escaping (Double, String) -> Void,
                            onPartialUpdate: (([Entry]) -> Void)? = nil,
                            stopped: @escaping () -> Bool) -> (folders: [Entry], files: [Entry]) {
        let home = FileUtil.home.standardizedFileURL
        let homeName = home.lastPathComponent
        let stored = UserDefaults.standard.integer(forKey: estimateKey)
        let estimate = stored > 200_000 ? stored : 1_200_000
        let ignoredSnapshot = AppConfigStore.shared.currentIgnoredPathsSnapshot()
        let ctx = ScanCtx(minLargeFile: minLargeFile,
                          estimate: estimate,
                          ignored: ignoredSnapshot,
                          stopped: stopped,
                          progress: progress,
                          onPartialUpdate: onPartialUpdate)
        let t0 = Date()
        let vkeys: Set<URLResourceKey> = [
            .isDirectoryKey, .isPackageKey, .isRegularFileKey,
            .fileSizeKey, .totalFileAllocatedSizeKey
        ]

        // 1. 构建 4 个核心磁盘顶层入口 (1:1 对齐原版 整个磁盘 根目录)
        let usersDir = LiveDir(path: home.path,
                               url: home,
                               depth: 1,
                               isPackage: false,
                               parent: nil,
                               customName: "Users/\(homeName)",
                               isCalculating: true)

        let appsURL = URL(fileURLWithPath: "/Applications")
        let appsDir = LiveDir(path: appsURL.path,
                              url: appsURL,
                              depth: 1,
                              isPackage: false,
                              parent: nil,
                              customName: "Applications",
                              isCalculating: true)

        let libURL = URL(fileURLWithPath: "/Library")
        let libDir = LiveDir(path: libURL.path,
                             url: libURL,
                             depth: 1,
                             isPackage: false,
                             parent: nil,
                             customName: "Library",
                             isCalculating: true,
                             notePrefix: "≥ ")

        var initialRootDirs = [usersDir, appsDir, libDir]

        var optDir: LiveDir? = nil
        let optURL = URL(fileURLWithPath: "/opt")
        if FileUtil.fm.fileExists(atPath: optURL.path) {
            let opt = LiveDir(path: optURL.path,
                              url: optURL,
                              depth: 1,
                              isPackage: false,
                              parent: nil,
                              customName: "opt",
                              isCalculating: true)
            optDir = opt
            initialRootDirs.append(opt)
        }

        ctx.rootDirs = initialRootDirs

        // 2. 将用户家目录下的子目录挂载到 usersDir.subdirs (下钻 Users/username 时展开)
        let kids = FileUtil.children(of: home, keys: Array(vkeys))

        var workItems: [LiveDir] = []

        for k in kids {
            let stdURL = k.standardizedFileURL
            let p = stdURL.path
            if ctx.isIgnored(p) { continue }
            let v = try? stdURL.resourceValues(forKeys: vkeys)
            if v?.isDirectory == true {
                let isPkg = (v?.isPackage == true) || isPackagePath(p)
                let topDir = LiveDir(path: p, url: stdURL, depth: 2, isPackage: isPkg, parent: usersDir)
                usersDir.subdirs.append(topDir)

                // 对 ~/Library 做二级并发切分，避免单线程卡在超大 Library 目录
                if !isPkg && stdURL.lastPathComponent == "Library" {
                    let libKids = FileUtil.children(of: stdURL, keys: Array(vkeys))
                    var libOwnBytes: Int64 = 0
                    var libOtherBytes: Int64 = 0
                    var libDirectFiles: [Entry] = []
                    for lk in libKids {
                        let lStd = lk.standardizedFileURL
                        let lp = lStd.path
                        if ctx.isIgnored(lp) { continue }
                        let lv = try? lStd.resourceValues(forKeys: vkeys)
                        if lv?.isDirectory == true {
                            let subPkg = (lv?.isPackage == true) || isPackagePath(lp)
                            let subDir = LiveDir(path: lp, url: lStd, depth: 3, isPackage: subPkg, parent: topDir)
                            topDir.subdirs.append(subDir)
                            workItems.append(subDir)
                        } else if lv?.isRegularFile == true {
                            let s = Int64(lv?.totalFileAllocatedSize ?? lv?.fileSize ?? 0)
                            libOwnBytes += s
                            if s >= ctx.minDirectFileNodeBytes {
                                libDirectFiles.append(Entry(url: lStd, size: s))
                            } else {
                                libOtherBytes += s
                            }
                            if s >= minLargeFile {
                                ctx.addLargeFile(Entry(url: lStd, size: s))
                            }
                        }
                    }
                    topDir.ownBytes += libOwnBytes
                    topDir.otherBytes += libOtherBytes
                    topDir.totalBytes += libOwnBytes
                    topDir.directFiles.append(contentsOf: libDirectFiles)
                    usersDir.totalBytes += libOwnBytes
                } else {
                    workItems.append(topDir)
                }
            } else if v?.isRegularFile == true {
                let s = Int64(v?.totalFileAllocatedSize ?? v?.fileSize ?? 0)
                if s > 0 {
                    usersDir.directFiles.append(Entry(url: stdURL, size: s))
                    usersDir.ownBytes += s
                    usersDir.totalBytes += s
                    if s >= minLargeFile {
                        ctx.addLargeFile(Entry(url: stdURL, size: s))
                    }
                }
            }
        }

        ctx.counter.add(kids.count)
        progress(0.02, tr(.analyzingDirectoryUsageInRealTime))

        // 立即发送首帧快照（展示 Users/Applications/Library/opt），零黑屏等待直接进入实时树图
        if let onPartialUpdate, !ctx.rootDirs.isEmpty {
            let initialEntries = ctx.buildSnapshot(maxDepth: 4)
            onPartialUpdate(initialEntries)
        }

        let queue = OperationQueue()
        queue.name = "com.aclean.spacelens.fts"
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = AppConfig.Security.ioConcurrency
        let ioContext = IOScanContext.current
        func enqueue(_ work: @escaping @Sendable () -> Void) {
            queue.addOperation {
                autoreleasepool {
                    if let ioContext { ioContext.perform(work) } else { work() }
                }
            }
        }

        // 并发扫描 /Applications
        enqueue {
            guard !ctx.isStopped() else { return }
            scanApplicationsDir(appsDir: appsDir, ctx: ctx)
        }

        // 并发扫描 /Library
        enqueue {
            guard !ctx.isStopped() else { return }
            scanLibraryDir(libDir: libDir, ctx: ctx)
        }

        // 并发扫描 /opt（若存在）
        if let optDir {
            enqueue {
                guard !ctx.isStopped() else { return }
                scanOptDir(optDir: optDir, ctx: ctx)
            }
        }

        // 并发扫描 ~/ 下各子目录
        for item in workItems {
            enqueue {
                guard !ctx.isStopped() else { return }
                scanSubtreeFTS(rootDir: item, ctx: ctx)
            }
        }

        queue.waitUntilAllOperationsAreFinished()

        ctx.lock.lock()
        usersDir.isCalculating = false
        appsDir.isCalculating = false
        libDir.isCalculating = false
        optDir?.isCalculating = false
        ctx.lock.unlock()

        let finalFolders = ctx.buildSnapshot(maxDepth: ctx.maxTreeDepth)
        ctx.lock.lock()
        let finalFiles = ctx.largeFiles.sorted { $0.size > $1.size }
        ctx.lock.unlock()

        let scanned = ctx.counter.value
        if scanned > 200_000 {
            UserDefaults.standard.set(scanned, forKey: estimateKey)
        }
        scanLog(String(format: "done: scanned=%d folders=%d files=%d total=%.2fs",
                       scanned, finalFolders.count, finalFiles.count, Date().timeIntervalSince(t0)))

        progress(1.0, tr(.actionDone))
        return (finalFolders, finalFiles)
    }

    private static func scanApplicationsDir(appsDir: LiveDir, ctx: ScanCtx) {
        let vkeys: Set<URLResourceKey> = [.isDirectoryKey, .fileSizeKey, .totalFileAllocatedSizeKey]
        let items = FileUtil.children(of: appsDir.url, keys: Array(vkeys))
        var entries: [(URL, Int64)] = []
        var total: Int64 = 0
        for item in items {
            if ctx.isStopped() { break }
            let p = item.path
            if ctx.isIgnored(p) { continue }
            let s = FileUtil.directorySize(item)
            if s > 0 {
                total += s
                entries.append((item, s))
            }
        }
        entries.sort { $0.1 > $1.1 }
        let overflowBytes = entries.dropFirst(48).reduce(Int64(0)) { $0 + $1.1 }
        ctx.lock.lock()
        appsDir.totalBytes = total
        appsDir.otherBytes = overflowBytes
        appsDir.subdirs = entries.prefix(48).map { (u, s) in
            let d = LiveDir(path: u.path, url: u, depth: 2, isPackage: true, parent: appsDir)
            d.totalBytes = s
            return d
        }
        appsDir.isCalculating = false
        ctx.counter.add(items.count)
        ctx.lock.unlock()
    }

    private static func scanLibraryDir(libDir: LiveDir, ctx: ScanCtx) {
        let items = FileUtil.children(of: libDir.url)
        var entries: [(URL, Int64)] = []
        var total: Int64 = 0
        for item in items {
            if ctx.isStopped() { break }
            let p = item.path
            if ctx.isIgnored(p) || FileUtil.isTCCOrApplePrivateBlocked(p) { continue }
            let s = FileUtil.directorySize(item)
            if s > 0 {
                total += s
                entries.append((item, s))
            }
        }
        entries.sort { $0.1 > $1.1 }
        ctx.lock.lock()
        libDir.totalBytes = total
        libDir.subdirs = entries.prefix(32).map { (u, s) in
            let d = LiveDir(path: u.path, url: u, depth: 2, isPackage: isPackagePath(u.path), parent: libDir)
            d.totalBytes = s
            return d
        }
        libDir.isCalculating = false
        ctx.counter.add(items.count)
        ctx.lock.unlock()
    }

    private static func scanOptDir(optDir: LiveDir, ctx: ScanCtx) {
        let items = FileUtil.children(of: optDir.url)
        var entries: [(URL, Int64)] = []
        var total: Int64 = 0
        for item in items {
            if ctx.isStopped() { break }
            let p = item.path
            if ctx.isIgnored(p) { continue }
            let s = FileUtil.directorySize(item)
            if s > 0 {
                total += s
                entries.append((item, s))
            }
        }
        entries.sort { $0.1 > $1.1 }
        ctx.lock.lock()
        optDir.totalBytes = total
        optDir.subdirs = entries.prefix(32).map { (u, s) in
            let d = LiveDir(path: u.path, url: u, depth: 2, isPackage: isPackagePath(u.path), parent: optDir)
            d.totalBytes = s
            return d
        }
        optDir.isCalculating = false
        ctx.counter.add(items.count)
        ctx.lock.unlock()
    }

    /// 使用 Darwin C `fts_open` / `fts_read` 高速扫描子树并实时向父链传播体积增量
    private static func scanSubtreeFTS(rootDir: LiveDir, ctx: ScanCtx) {
        if ctx.isStopped() || ctx.isIgnored(rootDir.path) { return }

        let cPath = strdup(rootDir.path)
        defer { free(cPath) }
        var argv: [UnsafeMutablePointer<CChar>?] = [cPath, nil]

        guard let fts = fts_open(&argv, FTS_PHYSICAL | FTS_NOCHDIR | FTS_XDEV, nil) else {
            IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(errno)), path: rootDir.path)
            return
        }
        defer { fts_close(fts) }

        rootDir.isScanning = true
        var stack: [LiveDir] = [rootDir]
        var packageBaseLevel: Int = -1

        var pendingTotal: Int64 = 0
        var pendingOwn: Int64 = 0
        var pendingOther: Int64 = 0
        var pendingDirectFiles: [Entry] = []
        var pendingLargeFiles: [Entry] = []
        var pendingCount: Int = 0
        var lastName: String = (rootDir.path as NSString).lastPathComponent

        func flush(to target: LiveDir) {
            guard pendingCount > 0 || pendingTotal > 0 || !pendingDirectFiles.isEmpty || !pendingLargeFiles.isEmpty else {
                return
            }
            ctx.flushDelta(
                to: target,
                totalDelta: pendingTotal,
                ownDelta: pendingOwn,
                otherDelta: pendingOther,
                newDirectFiles: pendingDirectFiles,
                newLargeFiles: pendingLargeFiles,
                scannedCount: pendingCount,
                currentName: lastName
            )
            pendingTotal = 0
            pendingOwn = 0
            pendingOther = 0
            pendingDirectFiles.removeAll(keepingCapacity: true)
            pendingLargeFiles.removeAll(keepingCapacity: true)
            pendingCount = 0
        }

        while let ent = fts_read(fts) {
            if ctx.isStopped() { break }
            if pendingCount >= 1024 {
                if ctx.isStopped() { break }
                if let active = stack.last {
                    flush(to: active)
                }
            }

            let info = Int32(ent.pointee.fts_info)
            let level = Int(ent.pointee.fts_level)
            if info == FTS_ERR || info == FTS_DNR || info == FTS_NS {
                let path = ent.pointee.fts_path.map { String(cString: $0) } ?? rootDir.path
                IOScanContext.record(NSError(domain: NSPOSIXErrorDomain, code: Int(ent.pointee.fts_errno)), path: path)
            }

            switch info {
            case FTS_D:
                if level == 0 {
                    if rootDir.isPackage {
                        packageBaseLevel = 0
                    }
                    continue
                }
                guard let pathPtr = ent.pointee.fts_path else { continue }
                let dPath = String(cString: pathPtr)
                if ctx.isIgnored(dPath) || FileUtil.isTCCOrApplePrivateBlocked(dPath) {
                    fts_set(fts, ent, FTS_SKIP)
                    continue
                }
                if packageBaseLevel >= 0 {
                    continue
                }
                let globalDepth = rootDir.depth + level
                if globalDepth <= ctx.maxTreeDepth {
                    if let active = stack.last {
                        flush(to: active)
                    }
                    while stack.count > level {
                        stack.removeLast()
                    }
                    let parentDir = stack.last ?? rootDir
                    let isPkg = isPackagePath(dPath)
                    let childDir = LiveDir(path: dPath, url: nil, depth: globalDepth, isPackage: isPkg, parent: parentDir, isScanning: true)
                    ctx.attachChild(childDir, to: parentDir)
                    stack.append(childDir)
                    lastName = (dPath as NSString).lastPathComponent
                    if isPkg {
                        packageBaseLevel = level
                    }
                }

            case FTS_DP:
                if let active = stack.last {
                    let activeRelLevel = active.depth - rootDir.depth
                    if level == activeRelLevel {
                        flush(to: active)
                        ctx.completeDir(active)
                        if stack.count > 1 {
                            stack.removeLast()
                        }
                    }
                }
                if packageBaseLevel == level {
                    packageBaseLevel = -1
                }

            case FTS_F:
                pendingCount += 1
                guard let st = ent.pointee.fts_statp else { continue }
                let blocks = Int64(st.pointee.st_blocks) * 512
                guard ctx.claim(st.pointee) else { continue }
                let sz = max(0, blocks)
                guard sz > 0 else { continue }

                pendingTotal += sz
                pendingOwn += sz

                guard let active = stack.last else { continue }
                let isDirectFileOfActive = (packageBaseLevel < 0) && (rootDir.depth + level == active.depth + 1)

                if isDirectFileOfActive {
                    if sz >= ctx.minDirectFileNodeBytes, let pathPtr = ent.pointee.fts_path {
                        let fPath = String(cString: pathPtr)
                        if !ctx.isIgnored(fPath) {
                            let fURL = URL(fileURLWithPath: fPath, isDirectory: false)
                            let entry = Entry(url: fURL, size: sz)
                            pendingDirectFiles.append(entry)
                            if sz >= ctx.minLargeFile {
                                pendingLargeFiles.append(entry)
                            }
                        }
                    } else {
                        pendingOther += sz
                    }
                } else {
                    if packageBaseLevel < 0 {
                        pendingOther += sz
                        if sz >= ctx.minLargeFile, let pathPtr = ent.pointee.fts_path {
                            let fPath = String(cString: pathPtr)
                            if !ctx.isIgnored(fPath) {
                                pendingLargeFiles.append(Entry(url: URL(fileURLWithPath: fPath, isDirectory: false), size: sz))
                            }
                        }
                    }
                }

            default:
                pendingCount += 1
            }
        }

        if let active = stack.last {
            flush(to: active)
        }
    }

    static func largeFiles(in root: URL, minSize: Int64, limit: Int,
                           progress: (Double, String) -> Void) -> [LargeFile] {
        var result: [LargeFile] = []
        let keys: [URLResourceKey] = [.isDirectoryKey, .totalFileAllocatedSizeKey, .fileSizeKey]
        guard let en = FileUtil.fm.enumerator(at: root, includingPropertiesForKeys: keys,
                                              options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                              errorHandler: { url, error in IOScanContext.record(error, path: url.path); return !IOScanContext.isCancelled }) else { return [] }
        var scanned = 0
        for case let f as URL in en {
            scanned += 1
            if scanned % 800 == 0 { progress(min(0.99, Double(scanned) / 300000.0), f.lastPathComponent) }
            if AppConfigStore.shared.isPathIgnoredForDisplay(f.path) { continue }
            let v = try? f.resourceValues(forKeys: Set(keys))
            guard v?.isDirectory == false else { continue }
            let s = Int64(v?.totalFileAllocatedSize ?? v?.fileSize ?? 0)
            if s >= minSize { result.append(LargeFile(url: f, size: s, isDirectory: false)) }
        }
        progress(1.0, tr(.actionDone))
        return Array(result.sorted { $0.size > $1.size }.prefix(limit))
    }

    static func folderBreakdown(of root: URL, progress: (Double, String) -> Void) -> [LargeFile] {
        let kids = FileUtil.children(of: root)
        var out: [LargeFile] = []
        for (i, k) in kids.enumerated() {
            progress(Double(i) / Double(max(1, kids.count)), k.lastPathComponent)
            if AppConfigStore.shared.isPathIgnoredForDisplay(k.path) { continue }
            let s = FileUtil.size(of: k)
            if s > 0 { out.append(LargeFile(url: k, size: s, isDirectory: true)) }
        }
        progress(1.0, tr(.actionDone))
        return out.sorted { $0.size > $1.size }
    }
}
