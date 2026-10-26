import Foundation

// ============================================================
//  DockerHelper —— Docker / OrbStack 虚实解耦清理助手
//
//  核心职责：
//    1. 宿主机物理日志/缓存解耦：安全识别 Docker/OrbStack 宿主机上
//       的日志与构建缓存（log/cache/tmp），这些项 100% 移入废纸篓；
//    2. 虚拟机磁盘硬核保护：绝对严禁物理删除 ~/.orbstack/data、
//       Docker.raw、Docker.qcow2 等虚拟机镜像文件；
//    3. 虚拟项目驱动：检测 Docker Daemon 活跃状态，生成虚拟清理条目，
//       调用 docker builder prune -f 并在输出中精确解析释放字节数。
// ============================================================

struct DockerEndpoint: Sendable, Equatable {
    let context: String
    let host: String
    let binary: String
    let identity: FileIdentity
}

enum DockerHelper {
    private static var isolatedEnvironment: [String: String] {
        ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("DOCKER_") && !$0.key.hasPrefix("BUILDX_") }
    }
    static func localEndpoint() -> DockerEndpoint? {
        guard let candidate = findDockerBinary() else { return nil }
        let binary = URL(fileURLWithPath: candidate).resolvingSymlinksInPath().path
        guard let identity = FileIdentity.capture(from: URL(fileURLWithPath: binary)), identity.mode & S_IFMT == S_IFREG else { return nil }
        let context = Shell.execute(binary, ["context", "show"]).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !context.isEmpty else { return nil }
        let host = Shell.execute(binary, ["context", "inspect", context, "--format", "{{.Endpoints.docker.Host}}"],
                                 environment: isolatedEnvironment).stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard host.hasPrefix("unix://") else { return nil }
        return DockerEndpoint(context: context, host: host, binary: binary, identity: identity)
    }
    private static func endpointStillMatches(_ endpoint: DockerEndpoint) -> Bool {
        guard endpoint.identity.matches(url: URL(fileURLWithPath: endpoint.binary)) else { return false }
        let res = Shell.execute(endpoint.binary, ["context", "inspect", endpoint.context, "--format", "{{.Endpoints.docker.Host}}"], environment: isolatedEnvironment)
        return res.isSuccess && res.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == endpoint.host
    }


    /// 严禁触碰的虚拟机磁盘镜像关键路径特征（收敛至 AppConfig.Helpers）
    static var protectedDiskMarkers: [String] {
        AppConfig.Helpers.dockerProtectedDiskMarkers
    }

    /// 校验是否属于受保护的 Docker/OrbStack 虚拟机磁盘镜像
    static func isProtectedVirtualDisk(path: String) -> Bool {
        for marker in protectedDiskMarkers {
            if path.contains(marker) {
                return true
            }
        }
        return false
    }

    public enum SubtreeInspection: Equatable {
        case clear
        case protected(URL)
        case incomplete(String)

        public static func == (lhs: SubtreeInspection, rhs: SubtreeInspection) -> Bool {
            switch (lhs, rhs) {
            case (.clear, .clear):
                return true
            case (.incomplete(let s1), .incomplete(let s2)):
                return s1 == s2
            case (.protected(let u1), .protected(let u2)):
                return u1.resolvingSymlinksInPath().path == u2.resolvingSymlinksInPath().path
            default:
                return false
            }
        }
    }

    /// 深度核验目录内部子树是否安全（三态判定：.clear、.protected(URL)、.incomplete(String)）(F4/R2)
    static func inspectSubtreeForVirtualDisk(inDirectory url: URL) -> SubtreeInspection {
        let stdPath = url.standardizedFileURL.path
        guard !stdPath.isEmpty, stdPath != "/" else { return .clear }

        // 1. 若目录路径本身直接命中标记
        for marker in protectedDiskMarkers {
            if stdPath.contains(marker) {
                return .protected(url)
            }
        }

        // 2. 检查目录是否包含虚拟磁盘特征文件
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: stdPath, isDirectory: &isDir), isDir.boolValue else {
            return .clear
        }

        let fm = FileManager.default
        // 关键安全防线 R2：绝不使用 skipsPackageDescendants，防止包内嵌套 Docker.raw 逃逸风控
        var enumerationError: Error?
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [],
                                            errorHandler: { _, error in enumerationError = error; return false }) else {
            return .incomplete("Unable to create directory enumerator for \(stdPath)")
        }

        var inspected = 0
        let maxItems = AppConfig.Security.dockerSubtreeMaxItems
        while let item = enumerator.nextObject() as? URL {
            if IOScanContext.isCancelled { return .incomplete(L10n.localized(.safetyInspectionIncomplete)) }
            inspected += 1
            if inspected > maxItems {
                // 超过检查预算上限，绝不可判定为安全清白 (R2)
                return .incomplete("Enumeration budget cap exceeded (\(maxItems) items) for \(stdPath)")
            }
            let p = item.standardizedFileURL.path
            for marker in protectedDiskMarkers {
                if p.hasSuffix("/" + marker) || p.contains("/" + marker + "/") || p.hasSuffix(marker) {
                    return .protected(item)
                }
            }
        }
        if let error = enumerationError { return .incomplete(error.localizedDescription) }
        return .clear
    }

    /// 检查指定目录是否覆盖或内部包含任何受保护的 Docker/OrbStack 虚拟机磁盘镜像文件 (F4)
    static func containsProtectedVirtualDisk(inDirectory url: URL) -> (contains: Bool, foundPath: String?) {
        switch inspectSubtreeForVirtualDisk(inDirectory: url) {
        case .protected(let foundURL):
            return (true, foundURL.path)
        case .incomplete, .clear:
            return (false, nil)
        }
    }

    /// 查找系统中可用的 docker CLI 二进制路径（收敛至 AppConfig.Helpers）
    static func findDockerBinary() -> String? {
        let home = FileUtil.home.path
        for c in AppConfig.Helpers.dockerBinaryCandidates {
            let path = c.replacingOccurrences(of: "~", with: home)
            if FileUtil.exists(path) {
                return path
            }
        }
        return nil
    }

    /// 检查 Docker 守护进程是否处于活跃通信状态（超时 2 秒防挂起）
    static func isDockerDaemonActive() -> Bool {
        guard let dockerBin = findDockerBinary() else { return false }
        let output = Shell.run(dockerBin, ["info", "--format", "{{.ServerVersion}}"], timeout: 2.0)
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !trimmed.contains("Cannot connect") && !trimmed.contains("error")
    }

    // MARK: - 扫描物理宿主机日志与缓存

    /// 扫描宿主机上的物理 Docker/OrbStack 缓存与日志
    static func scanHostPhysicalItems() -> [ScanItem] {
        var items: [ScanItem] = []
        let home = FileUtil.home

        let candidatePaths: [(URL, String)] = AppConfig.Helpers.dockerHostCandidatePaths.map {
            (home.appendingPathComponent($0.relPath), $0.label)
        }

        for (dir, label) in candidatePaths {
            guard FileUtil.exists(dir.path) else { continue }
            // 严禁包含虚拟磁盘
            guard !isProtectedVirtualDisk(path: dir.path) else { continue }
            guard SymlinkGuard.isSafePath(url: dir) else { continue }

            let isOrbStack = dir.path.lowercased().contains("orbstack") || dir.path.contains("MacVirt")
            let ownerBundles = isOrbStack
                ? ["dev.kdrag0n.MacVirt", "dev.orbstack.OrbStack"]
                : ["com.docker.docker", "com.electron.dockerdesktop"]

            guard let candidate = JunkRulePolicy.makeMeasuredCandidate(
                url: dir,
                name: label,
                note: "Host service logs and caches, safe to remove",
                safety: .caution,
                minBytes: 1024 * 100,
                configure: {
                    $0.isSelected = false
                    $0.ownerBundleIDs = ownerBundles
                }
            ) else { continue }
            items.append(JunkRulePolicy.apply(candidate))
        }

        return items
    }

    // MARK: - 扫描虚拟项目（容器/镜像释放）

    /// 扫描 Docker 虚拟空间（若守护进程活跃，生成虚拟项）
    static func scanVirtualPruneItem() -> ScanItem? {
        guard let endpoint = localEndpoint(), endpointStillMatches(endpoint) else { return nil }

        // 查询估计可释放的空间 (docker system df)
        var estimatedReclaimable: Int64 = 0
        if endpointStillMatches(endpoint) {
            let dfOutput = Shell.execute(endpoint.binary, ["--host", endpoint.host, "system", "df"], timeout: 4.0,
                                             environment: isolatedEnvironment).stdout
            estimatedReclaimable = parseReclaimableBytes(from: dfOutput)
        }

        // 若无法解析出预估，使用真实解析值（若解析不出或为0，则展示0，绝不用保底常量虚构空间）
        let displaySize = max(0, estimatedReclaimable)

        var item = ScanItem(
            url: URL(string: "docker-virtual://")!, // 虚拟协议标记，路径为空字符串，绝不设为 "/"
            name: L10n.localized(.actionCleanDockerCache),
            size: displaySize,
            note: L10n.localized(.dockerBuildCacheScope) + "\n" + endpoint.context + " · " + endpoint.host,
            safety: .caution,
            action: .dockerPrune
        )
        // 虚拟项默认不勾选，避免影响用户正在开发的容器
        item.isSelected = false
        item.dockerEndpoint = endpoint
        item.badge = "Virtual"
        return item
    }

    // MARK: - 清理执行与释放容量解析

    /// 执行 docker builder prune -f 并解析释放的字节数（核查进程真实退出码与 stderr）
    static func executeDockerPrune(endpoint: DockerEndpoint? = nil) -> (success: Bool, reclaimedBytes: Int64, error: String?) {
        guard let endpoint, endpointStillMatches(endpoint) else {
            return (false, 0, L10n.localized(.cleanupFileChanged))
        }
        // Execute against the captured socket even if the named context changes after inspection.
        let result = Shell.execute(endpoint.binary, ["--host", endpoint.host, "builder", "prune", "-f"],
                                   timeout: AppConfig.Security.helperCommandTimeout, environment: isolatedEnvironment)
        guard result.isSuccess else {
            let errMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            return (false, 0, errMsg.isEmpty ? "docker builder prune exited with code \(result.exitCode)" : errMsg)
        }
        let reclaimed = parseReclaimedBytesFromPruneOutput(result.stdout)
        return (true, reclaimed, nil)
    }

    /// 从 `docker builder prune` 输出中提取 Total reclaimed space: xxx
    /// 例如: "Total reclaimed space: 1.458GB" -> 换算字节数
    static func parseReclaimedBytesFromPruneOutput(_ output: String) -> Int64 {
        for line in output.split(separator: "\n") {
            let l = line.trimmingCharacters(in: .whitespaces)
            if l.contains("Total reclaimed space:") || l.hasPrefix("Total:") {
                let parts = l.components(separatedBy: l.hasPrefix("Total:") ? "Total:" : "Total reclaimed space:")
                if let sizeStr = parts.last?.trimmingCharacters(in: .whitespaces) {
                    return parseByteSizeString(sizeStr)
                }
            }
        }
        return 0
    }

    /// 从 `docker system df` 表格输出中解析 Build Cache 行的 Reclaimable
    static func parseReclaimableBytes(from dfOutput: String) -> Int64 {
        var total: Int64 = 0
        for line in dfOutput.split(separator: "\n") {
            // 每行可能包含形如 "1.2GB (100%)" 的 Reclaimable 列
            if line.hasPrefix("Build Cache"), line.contains("(") && line.contains("%)") {
                let tokens = line.split(separator: " ").map(String.init)
                for (i, t) in tokens.enumerated() {
                    if t.hasPrefix("(") && t.hasSuffix("%)") && i > 0 {
                        total += parseByteSizeString(tokens[i - 1])
                    }
                }
            }
        }
        return total
    }

    /// 将常见容量单位字符串（如 "1.5GB", "500MB", "10KB", "2048B"）转换为字节数
    static func parseByteSizeString(_ str: String) -> Int64 {
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return 0 }

        var numStr = ""
        var unitStr = ""

        for char in trimmed {
            if char.isNumber || char == "." {
                numStr.append(char)
            } else {
                unitStr.append(char)
            }
        }

        guard let value = Double(numStr), value.isFinite, value >= 0 else { return 0 }
        let units: [String: Double] = ["B": 1, "KB": 1e3, "MB": 1e6, "GB": 1e9, "TB": 1e12,
                                       "KIB": 1024, "MIB": 1048576, "GIB": 1073741824, "TIB": 1099511627776]
        guard let multiplier = units[unitStr], value * multiplier < Double(Int64.max) else { return 0 }
        return Int64(value * multiplier)

    }
}
