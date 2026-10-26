import Foundation
import Darwin

// ============================================================
//  SymlinkGuard —— 符号链接防穿透逃逸守卫
//
//  核心职责：
//    1. 严格执行 resolvingSymlinksInPath() == path 防符号链接穿透逃逸；
//    2. 防御恶意程序或错误配置在可清理目录（如 ~/Library/Caches）内
//       放置软链接指向 ~/.ssh、~/.gnupg、/etc、Keychain 等敏感目录；
//    3. 确保任何扫描或清理动作均作用于真实物理路径，严禁穿透软链接
//       删除其背后的宿主重要数据。
// ============================================================

enum SymlinkGuard {

    enum GuardError: LocalizedError {
        case symlinkEscapeDetected(original: String, resolved: String)
        case pathEscapesBaseDirectory(target: String, base: String)
        case protectedTargetReached(target: String)

        var errorDescription: String? {
            switch self {
            case .symlinkEscapeDetected(let orig, let res):
                return "Detected symlink escape: original [\(orig)] points to physical [\(res)]; blocked for system protection"
            case .pathEscapesBaseDirectory(let target, let base):
                return "Physical path [\(target)] escapes permitted base directory [\(base)]"
            case .protectedTargetReached(let target):
                return "Symlink points to protected critical path [\(target)]; operation forbidden"
            }
        }
    }

    // MARK: - 基础符号链接探测

    /// 检测指定 URL 自身是否为符号链接（不跟随链接）
    static func isSymbolicLink(at url: URL) -> Bool {
        var statBuf = stat()
        if lstat(url.path, &statBuf) == 0 {
            return (statBuf.st_mode & S_IFMT) == S_IFLNK
        }
        let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey])
        return values?.isSymbolicLink == true
    }

    /// 检测指定路径自身或其父路径是否含有符号链接
    static func containsSymlinkComponent(url: URL) -> Bool {
        var current = url.standardizedFileURL
        while current.path != "/" && current.pathComponents.count > 1 {
            if isSymbolicLink(at: current) {
                return true
            }
            current = current.deletingLastPathComponent()
        }
        return false
    }

    // MARK: - 符号链接逃逸与一致性校验 (TC-SAFE-001)

    /// 规范化 macOS 系统路径差异（统一映射系统别名至物理路径：/var -> /private/var, /etc -> /private/etc, /tmp -> /private/tmp）
    static func canonicalizeMacOSSystemPrefix(_ path: String) -> String {
        if path == "/var" || path.hasPrefix("/var/") {
            return "/private" + path
        }
        if path == "/etc" || path.hasPrefix("/etc/") {
            return "/private" + path
        }
        if path == "/tmp" || path.hasPrefix("/tmp/") {
            return "/private" + path
        }
        return path
    }

    /// 严格验证路径是否存在符号链接逃逸。
    /// 若原路径与其真实物理路径在规范化后不一致，返回 true（存在逃逸或指向外部）
    static func hasSymlinkEscape(url: URL) -> Bool {
        if isSymbolicLink(at: url) {
            return true
        }
        let originalPath = url.standardizedFileURL.path
        let resolvedPath = url.resolvingSymlinksInPath().standardizedFileURL.path

        // 标准化对比
        let cOrig = canonicalizeMacOSSystemPrefix(originalPath)
        let cRes = canonicalizeMacOSSystemPrefix(resolvedPath)

        if cOrig == cRes {
            return false
        }

        // 真实路径与原路径不一致，存在逃逸行为
        return true
    }

    /// 验证待处理路径是否属于安全的物理路径，且严格限制在允许的 base 目录之内。
    /// - Parameters:
    ///   - url: 待检测文件或目录路径
    ///   - baseDirectory: 可选的所属基准目录（例如 ~/Library/Caches）
    /// - Returns: true 表示安全；false 表示存在逃逸风险或触碰受保护目标
    static func isSafePath(url: URL, within baseDirectory: URL? = nil) -> Bool {
        let originalPath = url.standardizedFileURL.path
        let resolvedURL = url.resolvingSymlinksInPath().standardizedFileURL
        let resolvedPath = resolvedURL.path

        // 0. 强校验：严禁任何自身或上级目录的符号链接逃逸 (P0-06 彻底封堵)
        if hasSymlinkEscape(url: url) {
            return false
        }

        // 1. 如果自身或真实物理目标指向了受保护目录，直接拒绝
        if FileUtil.isProtected(resolvedURL) || FileUtil.isProtected(url) {
            return false
        }

        // 2. 如果存在基准目录，真实物理路径必须完全处于该基准目录之内
        if let base = baseDirectory {
            let baseResolvedPath = base.resolvingSymlinksInPath().standardizedFileURL.path
            let cResolved = canonicalizeMacOSSystemPrefix(resolvedPath)
            let cBaseResolved = canonicalizeMacOSSystemPrefix(baseResolvedPath)

            let isWithinBase = cResolved == cBaseResolved || cResolved.hasPrefix(cBaseResolved + "/")
            if !isWithinBase {
                return false
            }
        }

        // 3. 严格比对：如果自身为符号链接，且原路径 != 真实物理路径，严禁穿透进入目标进行子集清理
        if isSymbolicLink(at: url) {
            let cOrig = canonicalizeMacOSSystemPrefix(originalPath)
            let cRes = canonicalizeMacOSSystemPrefix(resolvedPath)
            if cOrig != cRes {
                // 软链接自身指向外部真实路径，拒绝作为常规垃圾目录递归扫描/清理
                return false
            }
        }

        return true
    }

    /// 执行强校验，若不安全则抛出对应的 GuardError 异常
    static func validateSafePath(url: URL, within baseDirectory: URL? = nil) throws {
        let originalPath = url.standardizedFileURL.path
        let resolvedURL = url.resolvingSymlinksInPath().standardizedFileURL
        let resolvedPath = resolvedURL.path

        if hasSymlinkEscape(url: url) {
            throw GuardError.symlinkEscapeDetected(original: originalPath, resolved: resolvedPath)
        }

        if FileUtil.isProtected(resolvedURL) || FileUtil.isProtected(url) {
            throw GuardError.protectedTargetReached(target: resolvedPath)
        }

        if let base = baseDirectory {
            let baseResolvedPath = base.resolvingSymlinksInPath().standardizedFileURL.path
            let cResolved = canonicalizeMacOSSystemPrefix(resolvedPath)
            let cBaseResolved = canonicalizeMacOSSystemPrefix(baseResolvedPath)

            let isWithinBase = cResolved == cBaseResolved || cResolved.hasPrefix(cBaseResolved + "/")
            if !isWithinBase {
                throw GuardError.pathEscapesBaseDirectory(target: resolvedPath, base: baseResolvedPath)
            }
        }

        if isSymbolicLink(at: url) {
            let cOrig = canonicalizeMacOSSystemPrefix(originalPath)
            let cRes = canonicalizeMacOSSystemPrefix(resolvedPath)
            if cOrig != cRes {
                throw GuardError.symlinkEscapeDetected(original: originalPath, resolved: resolvedPath)
            }
        }
    }
}
