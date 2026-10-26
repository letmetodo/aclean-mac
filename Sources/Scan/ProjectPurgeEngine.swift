import Foundation

// ============================================================
//  ProjectPurgeEngine —— 开发者项目级构建深度清理引擎
//
//  开发项目构建产物清理引擎
//
//  核心设计与安全规范：
//    1. 34 种规范构建目标目录匹配：涵盖主流前端、后端、移动端、系统级工具链；
//    2. 敏感资产与私钥物理避让：严格结合 GitGuard，若目录下包含 *-keypair.json、
//       id_rsa、.git，立即对该目录全域封锁并跳过；
//    3. Git 跟踪保护：调用 git ls-files，若目录下存在被版本控制跟踪的文件，绝对禁止删除；
//    4. 嵌套路径折叠剪枝 (filter_nested_artifacts)：父目录与子目录不重复记录；
//    5. 陈旧度判定：默认仅清理修改时间超过 7 天 (MIN_AGE_DAYS=7) 的项目产物；
//    6. 符号链接穿透逃逸防御：严格执行 SymlinkGuard。
// ============================================================

enum ProjectPurgeEngine {

    /// 31 种规范构建目录目标（收敛至 AppConfig.DeveloperPurge）
    static var targetArtifactNames: Set<String> {
        AppConfig.DeveloperPurge.targetArtifactNames
    }

    /// 默认扫描根目录列表（收敛至 AppConfig.DeveloperPurge）
    static var defaultSearchDirectories: [URL] {
        AppConfig.DeveloperPurge.defaultSearchDirectories
    }

    /// 常见通用文件夹名：必须在附近层级检验到工程配置文件才可被视作项目构建产物 (P0-03)
    private static var genericDirectoryNames: Set<String> {
        AppConfig.DeveloperPurge.genericDirectoryNames
    }

    /// 典型开发者项目清单与版本控制文件标记
    private static var projectManifestNames: Set<String> {
        AppConfig.DeveloperPurge.projectManifestNames
    }

    /// 检查指定候选构建目录的上级或祖先目录是否包含有效的项目工程清单或版本控制标记
    static func hasProjectManifest(near dirURL: URL) -> Bool {
        var current = dirURL.deletingLastPathComponent().standardizedFileURL
        var depth = 0
        while current.path != "/" && current.pathComponents.count > 1 && depth < AppConfig.DeveloperPurge.manifestSearchMaxDepth {
            for manifest in projectManifestNames {
                if FileUtil.exists(current.appendingPathComponent(manifest).path) {
                    return true
                }
            }
            current = current.deletingLastPathComponent()
            depth += 1
        }
        return false
    }

    /// Confirm that a candidate directory has the expected virtual-environment or cache markers.
    static func hasCacheProof(for dirURL: URL) -> Bool {
        let name = dirURL.lastPathComponent
        if AppConfig.Remediation.virtualenvNames.contains(name) {
            return AppConfig.Remediation.virtualenvProofFiles.contains {
                FileUtil.exists(dirURL.appendingPathComponent($0).path)
            }
        }
        return true
    }

    // MARK: - 嵌套路径折叠剪枝算法 (filter_nested_artifacts)

    /// 对所有候选路径进行父子目录折叠，避免父目录已被删除时重复添加其内部的子构建目录
    static func filterNestedArtifacts(urls: [URL]) -> [URL] {
        guard !urls.isEmpty else { return [] }
        // 按路径字符串长度升序排序（父目录一定比子目录短）
        let sorted = urls.map { $0.standardizedFileURL }
            .sorted { $0.path.count < $1.path.count }

        var result: [URL] = []
        var prefixPaths: [String] = []

        for candidate in sorted {
            let path = candidate.path
            let isNested = prefixPaths.contains { prefix in
                path == prefix || path.hasPrefix(prefix + "/")
            }
            if !isNested {
                result.append(candidate)
                prefixPaths.append(path)
            }
        }
        return result
    }

    // MARK: - 项目产物扫描主流程

    /// 扫描指定根目录下符合规范的开发者项目构建产物
    /// - Parameters:
    ///   - roots: 扫描根目录数组（默认使用 defaultSearchDirectories）
    ///   - minAgeDays: 最小修改天数（默认 7 天，0 表示不限制天数）
    ///   - maxDepth: 目录搜索最大深度（默认 5 层）
    ///   - progress: 进度回调 (比例, 当前路径)
    ///   - stopped: 停止检查器
    static func scan(
        roots: [URL] = defaultSearchDirectories,
        minAgeDays: Int = AppConfig.DeveloperPurge.defaultMinAgeDays,
        maxDepth: Int = AppConfig.DeveloperPurge.defaultMaxDepth,
        progress: ((Double, String) -> Void)? = nil,
        stopped: (() -> Bool)? = nil
    ) -> [ScanItem] {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        var rawArtifactURLs: [URL] = []
        let fm = FileManager.default
        let now = Date()
        let minAgeSeconds = Double(minAgeDays * 86400)

        for (idx, root) in roots.enumerated() {
            if stopped?() == true { break }
            progress?(Double(idx) / Double(max(1, roots.count)), root.lastPathComponent)

            guard FileUtil.exists(root.path), !JunkEngine.isCloudOrSyncProviderPath(root.path) else { continue }

            let keys: [URLResourceKey] = [
                .isDirectoryKey,
                .contentModificationDateKey,
                .isSymbolicLinkKey
            ]

            guard let enumerator = fm.enumerator(
                at: root,
                includingPropertiesForKeys: keys,
                options: [.skipsPackageDescendants],
                errorHandler: { url, error in IOScanContext.record(error, path: url.path); return !IOScanContext.isCancelled }
            ) else { continue }

            for case let fileURL as URL in enumerator {
                if stopped?() == true { break }

                // 深度控制
                if enumerator.level > maxDepth {
                    enumerator.skipDescendants()
                    continue
                }

                // 检查是否为目标构建目录名
                let dirName = fileURL.lastPathComponent
                guard targetArtifactNames.contains(dirName) else { continue }

                // 确保自身是目录而非普通文件
                guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                      values.isDirectory == true else { continue }

                // 1. 符号链接防穿透逃逸校验
                guard SymlinkGuard.isSafePath(url: fileURL) else {
                    enumerator.skipDescendants()
                    continue
                }

                // 1.5 ~ 3. 统一项目产物五重证明链：manifest + cacheProof + Git 安全无跟踪文件 + 非 dirty 工作树 + cwd 非冲突
                guard DeveloperArtifactPolicy.isEligibleProjectArtifact(fileURL) else {
                    enumerator.skipDescendants()
                    continue
                }

                // 2. 陈旧度判定（修改时间距离当前必须 >= minAgeDays）
                if minAgeDays > 0, let modDate = values.contentModificationDate {
                    let age = now.timeIntervalSince(modDate)
                    if age < minAgeSeconds {
                        // 正在活跃修改的项目，跳过
                        enumerator.skipDescendants()
                        continue
                    }
                }

                // 收集候选构建目录并剪枝其内部子项（避免在 node_modules 内部继续扫描）
                rawArtifactURLs.append(fileURL)
                enumerator.skipDescendants()
            }
        }

        // 4. 执行嵌套路径折叠剪枝
        let prunedURLs = filterNestedArtifacts(urls: rawArtifactURLs)

        // 5. 构造标准化 ScanItem 并统一通过 JunkRulePolicy.apply 裁决
        var items: [ScanItem] = []
        for url in prunedURLs {
            let size = FileUtil.directorySize(url)
            guard size > AppConfig.ScanThresholds.projectArtifactMinimumBytes else { continue }

            let category = toolchainCategory(for: url.lastPathComponent)
            let projectName = extractProjectName(for: url)

            var item = ScanItem(
                url: url,
                name: "\(projectName) (\(url.lastPathComponent))",
                size: size,
                note: L10n.format(.projectBuildArtifactNoteFormat, category, url.path),
                safety: .caution,
                action: .trash,
                isSelected: false,
                measuredBytes: size
            )
            // 开发者构建物一律默认不勾选，防误删未提交的本地临时编译产物
            item.ruleEvidence = CleanupRuleEvidence(
                id: "JC.DEV.PROJECT",
                tier: .review,
                reason: .devDerivedData,
                defaultSelected: false
            )
            item.badge = category
            items.append(JunkRulePolicy.apply(item))
        }

        progress?(1.0, L10n.localized(.statusCompleted))
        return items.sorted { $0.size > $1.size }
    }

    // MARK: - 辅助分类与工程名称识别

    /// 获取构建目标所属工具链分类标签
    static func toolchainCategory(for name: String) -> String {
        switch name {
        case "node_modules", "dist", ".next", ".nuxt", ".output", ".turbo", ".cache", ".parcel-cache", "out", "coverage", ".docusaurus", ".svelte-kit", ".astro":
            return L10n.localized(.projectToolchainFrontend)
        case "target":
            return L10n.localized(.projectToolchainRust)
        case "build", "bin", "obj", "cmake-build-debug", "cmake-build-release":
            return L10n.localized(.projectToolchainNative)
        case ".gradle", ".idea":
            return L10n.localized(.projectToolchainJava)
        case "venv", ".venv", "__pycache__", ".pytest_cache", ".mypy_cache", ".tox", "env":
            return L10n.localized(.projectToolchainPython)
        case "Pods", ".build", "DerivedData":
            return L10n.localized(.projectToolchainApple)
        case ".dart_tool":
            return L10n.localized(.projectToolchainDart)
        default:
            return L10n.localized(.projectToolchainGeneric)
        }
    }

    /// 提取所属父项目名称
    static func extractProjectName(for url: URL) -> String {
        let parent = url.deletingLastPathComponent()
        return parent.lastPathComponent.isEmpty ? url.lastPathComponent : parent.lastPathComponent
    }
}
