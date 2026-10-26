import Foundation
import CryptoKit
import CoreGraphics
import ImageIO

// ============================================================
//  整理杂乱引擎
//
//  对应原版 OrganizeModule 的四个自定义流程：
//    · largeAndOld   —— 大型和旧文件（体积 + 最后访问时间）
//    · duplicates    —— 重复文件查找器（按体积分桶 + 内容哈希）
//    · downloads     —— 下载项（已由 DownloadsEngine 实现）
//    · similarImages —— 相似图片（dHash 感知哈希聚类）
// ============================================================

enum OrganizeEngine {

    // MARK: - 大型和旧文件

    static var kindMap: [String: String] { AppConfig.Organize.fileKindMap }

    /// 剪枝排除目录集合（收敛至 AppConfig.Organize）
    static var pruneDirectories: Set<String> { AppConfig.Organize.pruneDirectories }

    // MARK: - 扫描范围（P1-5）

    /// 外接卷根目录（排除系统卷 / 只读卷 / 系统隐藏卷）
    /// 用于把「大型和旧文件 / 重复文件 / 相似图片」的扫描范围扩展到外接硬盘。
    static func externalVolumeRoots() -> [URL] {
        let keys: [URLResourceKey] = [.volumeIsRootFileSystemKey, .volumeIsReadOnlyKey,
                                      .volumeIsBrowsableKey, .volumeIsRemovableKey]
        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]) ?? []
        var out: [URL] = []
        for u in urls {
            guard let v = try? u.resourceValues(forKeys: Set(keys)) else { continue }
            if v.volumeIsRootFileSystem == true { continue }        // 排除启动卷
            if v.volumeIsReadOnly == true { continue }              // 只读卷无需清理
            if v.volumeIsBrowsable == false { continue }            // 排除不可浏览的系统卷
            if u.path.hasPrefix("/System/Volumes/") { continue }    // 排除系统卷宗
            out.append(u)
        }
        return out
    }

    /// 媒体库根目录：音乐资料库 + 照片图库(.photoslibrary 的 originals 子目录)
    /// 说明：照片图库内部文件已被 FileUtil.isProtected 整体保护，只做只读呈现，绝不删除。
    static func mediaLibraryRoots(includePhotos: Bool) -> [URL] {
        var out: [URL] = []
        let home = FileUtil.home

        let musicMedia = home.appendingPathComponent("Music/Music/Media")
        if FileUtil.exists(musicMedia.path) { out.append(musicMedia) }

        if includePhotos {
            let pictures = home.appendingPathComponent("Pictures")
            if let items = try? FileManager.default.contentsOfDirectory(
                at: pictures, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for it in items where it.pathExtension.lowercased() == "photoslibrary" {
                    out.append(it)
                }
            }
        }
        return out
    }

    /// 判断路径是否位于照片图库包内（只读呈现，禁止删除）
    static func isInsidePhotosLibrary(_ url: URL) -> Bool {
        url.path.contains(".photoslibrary/")
    }

    /// 废弃安装包智能探测器 (Installer Finder)
    /// 覆盖 .dmg, .pkg, .iso；针对 .zip 压缩包嗅探前 50 项判定是否包含 .app/.pkg；自动剥离 Homebrew Cask 哈希前缀
    static func scanInstallers(progress: ScanProgressCB, stopped: @escaping StopCheck) -> ScanGroup? {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        let home = FileUtil.home
        let roots: [URL] = AppConfig.Organize.installerSearchRoots
            .map { home.appendingPathComponent($0) }
            .filter { FileUtil.exists($0.path) }

        var items: [ScanItem] = []
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]

        for (ri, root) in roots.enumerated() {
            if stopped() { break }
            progress(Double(ri) / Double(max(1, roots.count)), root.lastPathComponent)

            guard let en = FileManager.default.enumerator(
                at: root, includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { url, error in IOScanContext.record(error, path: url.path); return !IOScanContext.isCancelled }
            ) else { continue }

            for case let f as URL in en {
                if stopped() { break }
                autoreleasepool {
                    if AppConfigStore.shared.isPathIgnoredForDisplay(f.path) { return }
                    guard let v = try? f.resourceValues(forKeys: Set(keys)),
                          v.isRegularFile == true else { return }

                    let ext = f.pathExtension.lowercased()
                    let size = Int64(v.fileSize ?? 0)
                    guard size > 1024 * 1024 else { return } // 忽略小于 1MB 的琐碎文件

                    var isInstaller = false
                    var installerType = "Installer"

                    if ext == "dmg" {
                        isInstaller = true
                        installerType = "DMG Disk Image"
                    } else if ext == "pkg" || ext == "mpkg" {
                        isInstaller = true
                        installerType = "macOS Package"
                    } else if ext == "iso" {
                        isInstaller = true
                        installerType = "ISO Disk Image"
                    } else if ext == "zip" {
                        // 读取 ZIP 压缩包元数据（前 50 项）嗅探是否包含 .app 或 .pkg
                        isInstaller = isZipInstallerPackage(f)
                        if isInstaller { installerType = "ZIP App Archive" }
                    }

                    guard isInstaller else { return }

                    // Homebrew Cask 缓存哈希前缀剥离 (e.g. 1a2b3c...--App-1.0.dmg -> App-1.0.dmg)
                    let rawName = f.lastPathComponent
                    let displayName: String
                    if rawName.contains("--") {
                        displayName = rawName.components(separatedBy: "--").dropFirst().joined(separator: "--")
                    } else {
                        displayName = rawName
                    }

                    let note = "\(installerType) · \(f.path)"
                    var item = ScanItem(url: f, name: displayName, size: size,
                                        note: note, safety: .safe,
                                        authorizationContext: .organizeManual)
                    item.action = .trash
                    item.isSelected = false // 安装包默认不勾选，交由用户决策
                    item.badge = installerType
                    items.append(item)
                }
            }
        }

        guard !items.isEmpty else { return nil }
        progress(1.0, L10n.localized(.completed))
        return ScanGroup(title: L10n.localized(.declutterInstallers),
                         icon: "shippingbox",
                         note: L10n.localized(.organizeInstallersGroupNote),
                         safety: .safe,
                         items: items.sorted { $0.size > $1.size })
    }

    /// 嗅探 ZIP 归档内部前 50 项文件路径，判断是否包含 macOS 应用或安装器
    static func isZipInstallerPackage(_ url: URL) -> Bool {
        // 使用 zipinfo -1 快速流式读取前 50 行，超时 2 秒防挂起
        let output = Shell.run("/usr/bin/zipinfo", ["-1", url.path], timeout: 2.0)
        guard !output.isEmpty else { return false }
        let lines = output.split(separator: "\n").prefix(50)
        for line in lines {
            let lower = line.lowercased()
            if lower.contains(".app/") || lower.hasSuffix(".app") || lower.hasSuffix(".pkg") || lower.hasSuffix(".mpkg") {
                return true
            }
        }
        return false
    }

    /// 大型和旧文件：>= 阈值（默认 100MB 或用户配置），或 >= 10MB 且超过设定月数未修改/未打开
    /// 包含 pruneDirectories 子树剪枝 (skipDescendants) 优化
    static func largeAndOld(
        thresholdBytes: Int64 = AppConfigStore.shared.currentLargeFileThresholdBytes,
        oldMonths: Int = AppConfigStore.shared.currentOldFileMonths,
        rootsOverride: [URL]? = nil,
        progress: ScanProgressCB,
        stopped: @escaping StopCheck
    ) -> ScanGroup? {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        let home = FileUtil.home
        var roots: [URL]
        if let rootsOverride {
            roots = rootsOverride
        } else {
            roots = ["Downloads", "Documents", "Desktop", "Movies", "Music", "Pictures"]
                .map { home.appendingPathComponent($0) }
            // P1-5：扩展扫描范围 —— 音乐资料库 + 外接卷
            roots += mediaLibraryRoots(includePhotos: false)
            roots += externalVolumeRoots()
        }
        roots = roots.filter { FileUtil.exists($0.path) && !AppConfigStore.shared.isPathIgnoredForDisplay($0.path) }

        var items: [ScanItem] = []
        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .fileSizeKey,
                                      .totalFileAllocatedSizeKey, .contentAccessDateKey,
                                      .contentModificationDateKey]
        let now = Date()
        let oldSeconds = Double(oldMonths) * 30.0 * 86400.0

        for (ri, root) in roots.enumerated() {
            if stopped() { break }
            progress(Double(ri) / Double(roots.count), root.lastPathComponent)
            guard let en = FileManager.default.enumerator(
                at: root, includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { url, error in IOScanContext.record(error, path: url.path); return !IOScanContext.isCancelled }) else { continue }

            for case let f as URL in en {
                if stopped() { break }
                autoreleasepool {
                    if AppConfigStore.shared.isPathIgnoredForDisplay(f.path) {
                        en.skipDescendants()
                        return
                    }

                    guard let v = try? f.resourceValues(forKeys: Set(keys)) else { return }

                    // 子树剪枝优化：如果当前是特定大型中间产物目录，直接跳过其内部所有子孙
                    if v.isDirectory == true && pruneDirectories.contains(f.lastPathComponent) {
                        en.skipDescendants()
                        return
                    }

                    guard v.isRegularFile == true else { return }
                    let size = Int64(v.totalFileAllocatedSize ?? v.fileSize ?? 0)
                    guard size >= 10 * 1024 * 1024 else { return }

                    let accessed = v.contentAccessDate ?? v.contentModificationDate ?? now
                    let age = now.timeIntervalSince(accessed)
                    let isOld = age > oldSeconds
                    // 大文件（≥ thresholdBytes）或「不大但很久没打开」
                    guard size >= thresholdBytes || isOld else { return }

                    var note = L10n.format(.organizeLastOpenedFormat, Fmt.date(accessed))
                    if isOld { note += " · " + L10n.format(.organizeNotUsedForMonthsFormat, oldMonths) }
                    items.append(ScanItem(url: f, name: f.lastPathComponent, size: size,
                                          note: note, safety: isOld ? .safe : .caution,
                                          authorizationContext: .organizeManual))
                }
            }
        }

        guard !items.isEmpty else { return nil }
        progress(1, L10n.localized(.completed))
        let sortedItems = items.sorted { $0.size > $1.size }
        let displayLimit = 300
        let isTruncated = sortedItems.count > displayLimit
        let groupNote = isTruncated
            ? L10n.format(.organizeCandidateLimitTruncatedFormat, displayLimit, sortedItems.count)
            : L10n.localized(.largeAndOldFilesDesc)
        return ScanGroup(title: L10n.localized(.declutterLargeAndOldFiles),
                         icon: "externaldrive.badge.exclamationmark",
                         note: groupNote,
                         safety: .caution,
                         items: sortedItems.prefix(displayLimit).map { $0 })
    }

    /// 按类型拆分成多个组（对应原版 DataManager 的「按类型」分组）
    static func largeAndOldByKind(_ group: ScanGroup) -> [ScanGroup] {
        var buckets: [String: [ScanItem]] = [:]
        for i in group.items {
            let ext = i.url.pathExtension.lowercased()
            let k = kindMap[ext] ?? "Other"
            buckets[k, default: []].append(i)
        }
        return buckets.map { k, v in
            ScanGroup(title: k, icon: "folder", note: "", safety: .caution,
                       items: v.sorted { $0.size > $1.size })
        }.sorted { $0.totalSize > $1.totalSize }
    }

    // MARK: - 重复文件

    static func duplicates(progress: ScanProgressCB, stopped: @escaping StopCheck,
                           minSize: Int64 = 1024 * 1024) -> [ScanGroup] {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        let home = FileUtil.home
        var roots = ["Downloads", "Documents", "Desktop", "Pictures", "Movies"]
            .map { home.appendingPathComponent($0) }
        // P1-5：扩展扫描范围 —— 音乐资料库 + 外接卷
        roots += mediaLibraryRoots(includePhotos: false)
        roots += externalVolumeRoots()
        roots = roots.filter { FileUtil.exists($0.path) && !AppConfigStore.shared.isPathIgnoredForDisplay($0.path) }

        // 1) 收集候选并按逻辑体积分桶（排除白名单、开发中间目录与同 inode 硬链接）
        var bySize: [Int64: [URL]] = [:]
        var seenPaths = Set<String>()
        var seenResourceIDs = Set<AnyHashable>()
        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .fileSizeKey, .fileResourceIdentifierKey]
        for (ri, root) in roots.enumerated() {
            if stopped() { break }
            progress(Double(ri) / Double(max(1, roots.count)) * 0.45, root.lastPathComponent)
            guard let en = FileManager.default.enumerator(
                at: root, includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { url, error in IOScanContext.record(error, path: url.path); return !IOScanContext.isCancelled }) else { continue }
            for case let f as URL in en {
                if stopped() { break }
                autoreleasepool {
                    if AppConfigStore.shared.isPathIgnoredForDisplay(f.path) {
                        en.skipDescendants()
                        return
                    }
                    guard let v = try? f.resourceValues(forKeys: Set(keys)) else { return }
                    if v.isDirectory == true && pruneDirectories.contains(f.lastPathComponent) {
                        en.skipDescendants()
                        return
                    }
                    guard v.isRegularFile == true else { return }
                    let canon = f.resolvingSymlinksInPath().path
                    guard !seenPaths.contains(canon) else { return }
                    if let resID = v.fileResourceIdentifier as? AnyHashable {
                        guard !seenResourceIDs.contains(resID) else { return }
                        seenResourceIDs.insert(resID)
                    }
                    let size = Int64(v.fileSize ?? 0)
                    guard size >= minSize else { return }
                    seenPaths.insert(canon)
                    bySize[size, default: []].append(f)
                }
            }
        }

        // 2) 只对「同体积且不止一个」的候选做内容哈希
        let candidates = bySize.filter { $0.value.count > 1 }
        var buckets: [String: [URL]] = [:]
        var verifiedFullDigests: [String: (digest: String, identity: FileIdentity)] = [:]
        var done = 0
        for (size, urls) in candidates {
            if stopped() { break }
            done += 1
            progress(0.45 + 0.5 * Double(done) / Double(max(1, candidates.count)),
                     L10n.format(.organizeComparingFilesOfSizeFormat, urls.count, Fmt.size(size)))
            // 两级指纹:先比头部 4MB;头部相同的组再做全文件分块哈希,
            // 避免两个「开头一样但内容不同」的文件被误判为重复(否则会删掉不一样的文件)。
            var byHead: [String: [URL]] = [:]
            for u in urls {
                if stopped() { break }
                autoreleasepool {
                    guard let h = headHash(u) else { return }
                    byHead[h, default: []].append(u)
                }
            }
            for (_, group) in byHead where group.count > 1 {
                var byFull: [String: [URL]] = [:]
                for u in group {
                    if stopped() { break }
                    autoreleasepool {
                        let preIdentity = FileIdentity.capture(from: u)
                        guard let h = fullHash(u) else { return }
                        if let preIdentity, preIdentity.matches(url: u) {
                            verifiedFullDigests[u.resolvingSymlinksInPath().path] = (h, preIdentity)
                        }
                        byFull[h, default: []].append(u)
                    }
                }
                for (fh, same) in byFull {
                    // 全文件哈希相同才进重复桶(单文件组在下一步被过滤)
                    buckets["\(size)-\(fh)", default: []].append(contentsOf: same)
                }
            }
        }

        // 3) 生成组：每组保留一份「最旧」的，其余建议删除
        var groups: [ScanGroup] = []
        for (bucketKey, urls) in buckets {
            // 按规范化路径去重，确保同路径不会自我碰撞
            var uniqueMap: [String: URL] = [:]
            for u in urls {
                let p = u.resolvingSymlinksInPath().path
                if uniqueMap[p] == nil { uniqueMap[p] = u }
            }
            let uniqueUrls = Array(uniqueMap.values)
            guard uniqueUrls.count > 1 else { continue }

            let sorted = uniqueUrls.sorted { a, b in
                let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return da < db
            }
            guard let keeper = sorted.first, let keeperIdentity = FileIdentity.capture(from: keeper) else { continue }
            let keeperCanonPath = keeper.resolvingSymlinksInPath().path
            let keeperHash: String? = {
                if let cached = verifiedFullDigests[keeperCanonPath],
                   cached.identity == keeperIdentity,
                   keeperIdentity.matches(url: keeper) {
                    return cached.digest
                }
                return autoreleasepool { fullHash(keeper) }
            }()
            guard let keeperHash, bucketKey.hasSuffix("-" + keeperHash),
                  keeperIdentity.matches(url: keeper) else { continue }
            let evidence = DuplicateEvidence(keeper: keeper, identity: keeperIdentity, digest: keeperHash)
            let items = sorted.enumerated().compactMap { i, u -> ScanItem? in
                let size = FileUtil.size(of: u)
                let note = i == 0 ? L10n.localized(.noteKeepOriginal) : L10n.localized(.noteDuplicateCopy)
                var item = ScanItem(url: u, name: u.lastPathComponent, size: size,
                                    note: note, safety: .caution, action: .trash,
                                    isSelected: false,
                                    badge: i == 0 ? L10n.localized(.badgeWillKeep) : "",
                                    authorizationContext: .organizeManual)
                item.isRetainedOriginal = i == 0
                item.duplicateEvidence = evidence
                item.fileIdentity = FileIdentity.capture(from: u)
                return item
            }
            let name = sorted.first?.lastPathComponent ?? L10n.localized(.declutterDuplicates)
            groups.append(ScanGroup(title: L10n.format(.organizeDuplicateCopiesGroupFormat, name, sorted.count),
                                    icon: "doc.on.doc",
                                    note: sorted.first?.deletingLastPathComponent().path ?? "",
                                    safety: .safe, items: items))
        }
        progress(1, L10n.localized(.completed))
        return groups.sorted { $0.totalSize > $1.totalSize }
    }

    static func headHash(_ url: URL) -> String? {
        verifiedHash(url, limit: Int64(AppConfig.Security.hashHeadBytes))
    }

    static func fullHash(_ url: URL) -> String? {
        verifiedHash(url, limit: nil)
    }

    /// Throwing reader keeps I/O failures distinct from EOF. Short reads are allowed.
    static func hashContents(limit: Int64?, expectedSize: Int64,
                             stopped: () -> Bool,
                             read: (Int) throws -> Data?) throws -> String {
        var hash = SHA256()
        var total: Int64 = 0
        let required = min(limit ?? expectedSize, expectedSize)
        while total < required {
            if stopped() { throw CancellationError() }
            let want = Int(min(Int64(AppConfig.Security.hashChunkBytes), required - total))
            let chunkCount: Int = try autoreleasepool {
                let data = try read(want) ?? Data()
                guard !data.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
                hash.update(data: data)
                return data.count
            }
            total += Int64(chunkCount)
        }
        if limit == nil {
            let hasExtra: Bool = try autoreleasepool {
                !(try read(1) ?? Data()).isEmpty
            }
            if hasExtra { throw CocoaError(.fileReadCorruptFile) }
        }
        if stopped() { throw CancellationError() }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func verifiedHash(_ url: URL, limit: Int64?) -> String? {
        autoreleasepool {
            guard !SymlinkGuard.hasSymlinkEscape(url: url),
                  let before = FileIdentity.capture(from: url), !before.isDirectory,
                  before.mode & S_IFMT == S_IFREG,
                  let handle = try? FileHandle(forReadingFrom: url) else { return nil }
            defer { try? handle.close() }
            // Bind the opened descriptor to the path identity, before and after reading.
            var opened = stat()
            guard fstat(handle.fileDescriptor, &opened) == 0,
                  opened.st_dev == before.device, opened.st_ino == before.inode else { return nil }
            do {
                let digest = try hashContents(limit: limit, expectedSize: Int64(before.fileSize),
                                              stopped: { IOScanContext.isCancelled }) {
                    try handle.read(upToCount: $0)
                }
                var after = stat()
                guard fstat(handle.fileDescriptor, &after) == 0,
                      after.st_size == opened.st_size,
                      after.st_mtimespec.tv_sec == opened.st_mtimespec.tv_sec,
                      after.st_mtimespec.tv_nsec == opened.st_mtimespec.tv_nsec,
                      after.st_ctimespec.tv_sec == opened.st_ctimespec.tv_sec,
                      after.st_ctimespec.tv_nsec == opened.st_ctimespec.tv_nsec,
                      before.matches(url: url) else { return nil }
                return digest
            } catch {
                IOScanContext.record(error, path: url.path)
                return nil
            }
        }
    }

    // MARK: - 相似图片（感知哈希聚类）

    /// dHash(9×8 灰度梯度哈希)+ 汉明距离 ≤ 8 聚类。
    /// 每个相似组保留「最新」一张( isSelected=false 不参与勾选 ),其余列为可删副本。
    static func similarImages(progress: ScanProgressCB, stopped: @escaping StopCheck) -> [ScanGroup] {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        let home = FileUtil.home
        let exts: Set<String> = ["jpg", "jpeg", "png", "heic", "heif", "tif", "tiff", "bmp", "webp"]
        var roots = ["Pictures", "Desktop", "Downloads"].map { home.appendingPathComponent($0) }
        // P1-5：扩展扫描范围 —— 外接卷 + 照片图库（图库内部只读呈现，不参与删除）
        roots += externalVolumeRoots()
        roots += mediaLibraryRoots(includePhotos: true)
        roots = roots.filter { FileUtil.exists($0.path) && !AppConfigStore.shared.isPathIgnoredForDisplay($0.path) }

        // 1) 收集候选(上限 20000 张,防止极端图库拖死扫描)
        var files: [URL] = []
        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        for (ri, root) in roots.enumerated() {
            if stopped() { break }
            progress(Double(ri) / Double(max(1, roots.count)) * 0.35, root.lastPathComponent)
            guard let en = FileManager.default.enumerator(
                at: root, includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { url, error in IOScanContext.record(error, path: url.path); return !IOScanContext.isCancelled }) else { continue }
            for case let f as URL in en {
                if stopped() || files.count >= AppConfig.Organize.similarImageCandidateLimit { break }
                autoreleasepool {
                    if AppConfigStore.shared.isPathIgnoredForDisplay(f.path) {
                        en.skipDescendants()
                        return
                    }
                    if let v = try? f.resourceValues(forKeys: [.isDirectoryKey]),
                       v.isDirectory == true && pruneDirectories.contains(f.lastPathComponent) {
                        en.skipDescendants()
                        return
                    }
                    guard exts.contains(f.pathExtension.lowercased()) else { return }
                    files.append(f)
                }
            }
        }
        guard !files.isEmpty, !stopped() else { return [] }

        // 2) 逐张算指纹
        struct Shot { let url: URL; let hash: UInt64; let date: Date; let size: Int64 }
        var prints: [Shot] = []
        for (i, f) in files.enumerated() {
            if stopped() { break }
            autoreleasepool {
                if i % 25 == 0 {
                    progress(0.35 + 0.55 * Double(i) / Double(files.count),
                             L10n.format(.organizeAnalyzingImagesProgressFormat, i + 1, files.count))
                }
                guard let h = dHash(f) else { return }
                let v = try? f.resourceValues(forKeys: Set(keys))
                prints.append(Shot(url: f, hash: h,
                                   date: v?.contentModificationDate ?? .distantPast,
                                   size: Int64(v?.fileSize ?? 0)))
            }
        }

        let isCandidateTruncated = files.count >= AppConfig.Organize.similarImageCandidateLimit
        let clusters = clusterSimilarHashes(prints.map(\.hash), maxDistance: 8, stopped: stopped)

        // 4) 生成组:组内最新一张保留,其余为相似副本
        progress(1, L10n.localized(.completed))
        return clusters.enumerated().compactMap { ci, cl in
            let sorted = cl.map { prints[$0] }.sorted { $0.date > $1.date }
            let items = sorted.enumerated().map { i, s -> ScanItem in
                let inPhotos = isInsidePhotosLibrary(s.url)
                var item = ScanItem(url: s.url, name: s.url.lastPathComponent, size: s.size,
                                    note: inPhotos
                                        ? L10n.localized(.organizePhotosLibraryProtectedNote)
                                        : (i == 0 ? L10n.localized(.organizeNewestInGroupKeepNote) : L10n.format(.organizeSimilarToTargetFormat, sorted[0].url.lastPathComponent)),
                                    safety: .caution, action: .trash,
                                    isSelected: false,
                                    badge: (!inPhotos && i == 0) ? L10n.localized(.badgeWillKeep) : "",
                                    authorizationContext: .organizeManual)
                item.isRetainedOriginal = i == 0
                if inPhotos { item.locked = true }   // 图库内文件强制锁定，杜绝破坏图库索引
                return item
            }
            let baseNote = sorted[0].url.deletingLastPathComponent().path
            let groupNote = isCandidateTruncated
                ? "\(baseNote) · \(L10n.format(.organizeCandidateLimitTruncatedFormat, AppConfig.Organize.similarImageCandidateLimit, files.count))"
                : baseNote
            return ScanGroup(title: L10n.format(.organizeSimilarImagesGroupTitleFormat, ci + 1, cl.count),
                             icon: "photo.on.rectangle.angled",
                             note: groupNote,
                             safety: .caution, items: items)
        }
        .sorted { $0.totalSize > $1.totalSize }
    }

    /// 3) 聚类: BK-Tree 加速汉明距离 ≤ maxDistance 搜索 + BFS 连通分量分簇（确保 A≈B、B≈C 归入同一连通簇）
    static func clusterSimilarHashes(_ hashes: [UInt64], maxDistance: Int = 8, stopped: () -> Bool = { false }) -> [[Int]] {
        guard hashes.count > 1 else { return [] }
        final class BKTreeNode {
            let index: Int
            let hash: UInt64
            var children: [Int: BKTreeNode] = [:]
            init(index: Int, hash: UInt64) {
                self.index = index
                self.hash = hash
            }
        }

        var root: BKTreeNode?
        for (idx, h) in hashes.enumerated() {
            if stopped() { break }
            guard let r = root else {
                root = BKTreeNode(index: idx, hash: h)
                continue
            }
            var curr = r
            while true {
                let dist = Int((curr.hash ^ h).nonzeroBitCount)
                if let child = curr.children[dist] {
                    curr = child
                } else {
                    curr.children[dist] = BKTreeNode(index: idx, hash: h)
                    break
                }
            }
        }

        func queryBKTree(from node: BKTreeNode?, hash: UInt64, maxDist: Int, result: inout [Int]) {
            guard let node = node else { return }
            var stack = [node]
            while let n = stack.popLast() {
                let dist = Int((n.hash ^ hash).nonzeroBitCount)
                if dist <= maxDist {
                    result.append(n.index)
                }
                let low = max(0, dist - maxDist)
                let high = dist + maxDist
                for (d, child) in n.children {
                    if d >= low && d <= high {
                        stack.append(child)
                    }
                }
            }
        }

        var visited = Array(repeating: false, count: hashes.count)
        var clusters: [[Int]] = []
        for i in 0..<hashes.count {
            if stopped() { break }
            guard !visited[i] else { continue }
            var component: [Int] = [i]
            visited[i] = true
            var queueIndex = 0
            while queueIndex < component.count {
                if stopped() { break }
                let cur = component[queueIndex]
                queueIndex += 1
                var neighbors: [Int] = []
                queryBKTree(from: root, hash: hashes[cur], maxDist: maxDistance, result: &neighbors)
                neighbors.sort()
                for nb in neighbors where !visited[nb] {
                    visited[nb] = true
                    component.append(nb)
                }
            }
            component.sort()
            if component.count > 1 {
                clusters.append(component)
            }
        }
        return clusters
    }

    /// dHash:将图片强制绘制到固定 9×8 灰度网格中，比较每行相邻像素亮度 → 64 bit 指纹
    private static func dHash(_ url: URL) -> UInt64? {
        autoreleasepool {
            guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
            let opts: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 32,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCache: false,
            ]
            guard let img = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
            let w = 9, h = 8
            var pix = [UInt8](repeating: 0, count: w * h)
            let ok = pix.withUnsafeMutableBytes { buf -> Bool in
                guard let ctx = CGContext(data: buf.baseAddress, width: w, height: h,
                                          bitsPerComponent: 8, bytesPerRow: w,
                                          space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
                ctx.interpolationQuality = .medium
                ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
                return true
            }
            guard ok else { return nil }
            var hash: UInt64 = 0
            var bit: UInt64 = 0
            for y in 0..<h {
                for x in 0..<(w - 1) {
                    if pix[y * w + x] > pix[y * w + x + 1] { hash |= (1 << bit) }
                    bit += 1
                }
            }
            return hash
        }
    }
}
