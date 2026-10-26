import Foundation

// ============================================================
//  GitGuard —— Git 版本控制跟踪保护与敏感私钥资产避让守卫
//
//  核心职责：
//    1. 调用 git ls-files 保护 Git 仓库中已被版本控制跟踪的文件；
//    2. 严格检测并避让敏感资产与私钥（如 Solana/Anchor 的 *-keypair.json、
//       id_rsa、.pem、.key 以及 .git 仓库核心数据）；
//    3. 若构建产物目录中混入任何已跟踪源码或敏感私钥，立即全域封锁，
//       绝对禁止将其作为构建垃圾删除（对齐 TC-PROJ-001 & TC-PROJ-002）。
// ============================================================

enum GitGuard {

    // MARK: - 敏感资产与私钥模式匹配

    /// 敏感文件名特征或后缀（收敛至 AppConfig.Security）
    private static var sensitiveExtensions: Set<String> {
        AppConfig.Security.sensitiveExtensions
    }

    /// 敏感文件名精确匹配清单（收敛至 AppConfig.Security）
    private static var exactSensitiveNames: Set<String> {
        AppConfig.Security.exactSensitiveNames
    }

    private static var testCertExemptionExtensions: Set<String> {
        AppConfig.Security.testCertExemptionExtensions
    }

    /// 检查指定文件名是否为敏感私钥或凭据（如 *-keypair.json）
    /// - Parameter exemptTestCertExtensions: 仅当父规则属于明确开发包与构建缓存白名单时，豁免测试证书后缀 (.pem/.key/.p12/.pfx/.keystore/.jks)，但绝不豁免 .env / id_rsa / keypair.json 等精确凭证名
    static func isSensitiveFilename(_ name: String, exemptTestCertExtensions: Bool = false) -> Bool {
        let lower = name.lowercased()
        if lower.hasSuffix("-keypair.json") || lower.hasSuffix("_keypair.json") || lower == "keypair.json" {
            return true
        }
        if exactSensitiveNames.contains(lower) {
            if exemptTestCertExtensions && (lower.hasPrefix(".env") || lower == "credentials.json") {
                return false
            }
            return true
        }
        let ext = (name as NSString).pathExtension.lowercased()
        if exemptTestCertExtensions && testCertExemptionExtensions.contains(ext) {
            return false
        }
        if sensitiveExtensions.contains(ext) {
            return true
        }
        return false
    }

    /// 递归（深度限制）检查目录内是否含有任何私钥或敏感资产 (TC-PROJ-001)
    static func containsSensitiveAssets(in directory: URL, maxDepth: Int = AppConfig.Security.sensitiveAssetsMaxDepth) -> (hasSensitive: Bool, detail: String?) {
        guard FileUtil.exists(directory.path) else { return (true, L10n.localized(.safetyInspectionIncomplete)) }

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir), !isDir.boolValue {
            // 单文件直接检查
            if isSensitiveFilename(directory.lastPathComponent) {
                return (true, directory.lastPathComponent)
            }
            return (false, nil)
        }

        // 检查自身目录下是否包含 .git
        let gitDir = directory.appendingPathComponent(".git")
        if FileUtil.exists(gitDir.path) {
            return (true, ".git repository directory")
        }

        return autoreleasepool {
            let fm = FileManager.default
            let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey]
            var incomplete = false
            guard let enumerator = fm.enumerator(
                at: directory,
                includingPropertiesForKeys: keys,
                options: [],
                errorHandler: { _, _ in incomplete = true; return false }
            ) else { return (true, L10n.localized(.safetyInspectionIncomplete)) }

            for case let fileURL as URL in enumerator {
                // 控制深度
                if IOScanContext.isCancelled || enumerator.level > maxDepth {
                    return (true, L10n.localized(.safetyInspectionIncomplete))
                }
                let name = fileURL.lastPathComponent
                if name == ".git" {
                    return (true, ".git directory")
                }
                if isSensitiveFilename(name) {
                    return (true, name)
                }
            }
            return incomplete ? (true, L10n.localized(.safetyInspectionIncomplete)) : (false, nil)
        }
    }

    // MARK: - Git 仓库与已跟踪文件判定 (TC-PROJ-002)

    private static let cacheLock = NSLock()
    private static let repoTrackedCacheStorage = LockedValue<[String: (timestamp: TimeInterval, files: Set<String>?)]>([:])
    private static var repoTrackedCache: [String: (timestamp: TimeInterval, files: Set<String>?)] {
        get { repoTrackedCacheStorage.withValue { $0 } }
        set { repoTrackedCacheStorage.withValue { $0 = newValue } }
    }
    private static let cacheTTL: TimeInterval = AppConfig.Security.gitTrackedCacheTTL

    /// 获取并缓存指定 Git 仓库内所有受跟踪的相对路径集合（5 秒 TTL，避免同一仓库内多个子目录重复 fork git）
    /// 关键防线：若 git ls-files 失败或超时，返回 nil，外部严格 fail-safe 阻断删除
    private static func trackedFiles(inRepo repoPath: String) -> Set<String>? {
        let now = ProcessInfo.processInfo.systemUptime
        cacheLock.lock()
        if let hit = repoTrackedCache[repoPath], now - hit.timestamp < cacheTTL {
            cacheLock.unlock()
            return hit.files
        }
        cacheLock.unlock()

        let res = Shell.execute("/usr/bin/git", AppConfig.Security.safeGitArguments + ["-C", repoPath, "ls-files", "-z"], timeout: AppConfig.Security.gitLsFilesTimeout, environment: AppConfig.Security.safeGitEnvironment)
        guard res.isSuccess else {
            cacheLock.lock()
            repoTrackedCache[repoPath] = (now, nil)
            cacheLock.unlock()
            return nil
        }

        guard let bytes = res.stdoutData, let listing = String(data: bytes, encoding: .utf8) else { return nil }
        let tracked = Set(listing.split(separator: "\0").map(String.init))

        cacheLock.lock()
        repoTrackedCache[repoPath] = (now, tracked)
        cacheLock.unlock()
        return tracked
    }

    /// 向上查找所在 Git 仓库根目录
    static func findGitRepositoryRoot(for url: URL) -> URL? {
        var current = url.standardizedFileURL
        while current.path != "/" && current.pathComponents.count > 1 {
            let dotGit = current.appendingPathComponent(".git")
            if FileUtil.exists(dotGit.path) {
                return current
            }
            current = current.deletingLastPathComponent()
        }
        return nil
    }

    /// 检查指定文件或目录中是否存在被 Git 跟踪管理的文件 (git ls-files)
    static func hasGitTrackedFiles(url: URL) -> Bool {
        guard let repoRoot = findGitRepositoryRoot(for: url) else {
            // 不在 Git 仓库内，不属于 Git 跟踪
            return false
        }

        let repoPath = repoRoot.path
        let targetPath = url.standardizedFileURL.path

        // 计算相对于 repo 根的相对路径
        let relativePath: String
        if targetPath == repoPath {
            relativePath = "."
        } else if targetPath.hasPrefix(repoPath + "/") {
            relativePath = String(targetPath.dropFirst(repoPath.count + 1))
        } else {
            return false
        }

        guard let tracked = trackedFiles(inRepo: repoPath) else {
            // fail-safe 关键防线：若 git ls-files 异常或超时，无法确认跟踪状态，严格采取保守策略阻断清理
            return true
        }

        if relativePath == "." {
            return true
        }
        guard !tracked.isEmpty else { return false }

        // 判断目标是单文件命中还是目录前缀命中
        if tracked.contains(relativePath) {
            return true
        }
        let dirPrefix = relativePath.hasSuffix("/") ? relativePath : (relativePath + "/")
        return tracked.contains { $0.hasPrefix(dirPrefix) }
    }

    /// Any uncommitted/untracked work or unreadable status keeps project artifacts intact.
    static func hasDirtyWorkingTree(containing url: URL) -> Bool {
        guard let root = findGitRepositoryRoot(for: url) else { return false }
        let result = Shell.execute("/usr/bin/git", AppConfig.Security.safeGitArguments + ["-C", root.path] + AppConfig.Remediation.gitStatusArguments,
                                   timeout: AppConfig.Security.gitLsFilesTimeout, environment: AppConfig.Security.safeGitEnvironment)
        guard result.isSuccess, let data = result.stdoutData else { return true }
        return !data.isEmpty
    }

    static func invalidateTrackedCache() {
        cacheLock.lock(); defer { cacheLock.unlock() }
        repoTrackedCache.removeAll()
    }

    // MARK: - 综合可清理性判定安全阀

    /// 综合校验目标路径是否允许被清理（无私钥、无 Git 跟踪）
    static func isSafeToPurge(url: URL) -> (isSafe: Bool, reason: String?) {
        // 1. 敏感资产与私钥避让
        let sensitiveCheck = containsSensitiveAssets(in: url)
        if sensitiveCheck.hasSensitive {
            return (false, "Detected sensitive private key or credentials [\(sensitiveCheck.detail ?? "keypair")], deletion blocked")
        }

        // 2. Git 跟踪文件保护
        if hasGitTrackedFiles(url: url) {
            return (false, "Detected files tracked by Git version control under this directory, deletion blocked")
        }

        return (true, nil)
    }
}
