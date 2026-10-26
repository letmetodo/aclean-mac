import Foundation
import Darwin

enum DeveloperArtifactPolicy {
    static func isProvenProjectArtifact(_ url: URL) -> Bool {
        let parent = url.deletingLastPathComponent()
        let names: [URL]
        do { names = try FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil) }
        catch { return false }
        let gameProject = FileUtil.exists(parent.appendingPathComponent(AppConfig.Remediation.unityMarker).path)
            || names.contains { $0.pathExtension.lowercased() == AppConfig.Remediation.unrealExtension }
        if gameProject { return false } // Exported builds/Saved can contain the only playable copy.
        let catalog = KnowledgeBaseManager.shared.authored.catalog
        guard let configuration = catalog.rows("cm_project_artifact").first(where: { $0["artifact_name"] == url.lastPathComponent }),
              configuration["proof_kind"] != "disabled",
              let proofs = catalog.projectProofs[url.lastPathComponent] else { return false }
        if AppConfig.Remediation.dotNetProjectExtensions.contains(where: { ext in names.contains { $0.pathExtension == ext } }) {
            return configuration["proof_kind"] == "dotnet_project" && (url.lastPathComponent == "bin" || url.lastPathComponent == "obj")
        }
        return configuration["proof_kind"] == "parent_any" && proofs.contains { FileUtil.exists(parent.appendingPathComponent($0).path) }
    }

    static func isOrphanDerivedData(_ url: URL) -> Bool {
        guard let info = NSDictionary(contentsOf: url.appendingPathComponent(AppConfig.Remediation.derivedMetadataFile)),
              let path = info[AppConfig.Remediation.workspacePathKey] as? String,
              path.hasPrefix("/"), !path.contains("\0"),
              !AppConfig.Remediation.unavailableWorkspacePrefixes.contains(where: path.hasPrefix),
              !JunkEngine.isCloudOrSyncProviderPath(path),
              !ProcessGuard.isAppRunning(bundleID: AppConfig.Remediation.xcodeBundleID) else { return false }
        let workspace = URL(fileURLWithPath: path).standardizedFileURL
        var status = stat()
        guard lstat(workspace.path, &status) != 0, errno == ENOENT else { return false }
        // Prove absence against the closest existing readable parent; permission failures are unknown.
        var parent = workspace.deletingLastPathComponent()
        while parent.path != "/" {
            if lstat(parent.path, &status) == 0 {
                return access(parent.path, R_OK | X_OK) == 0 && !SymlinkGuard.hasSymlinkEscape(url: parent)
            }
            guard errno == ENOENT else { return false }
            parent.deleteLastPathComponent()
        }
        return false
    }

    static func version(_ url: URL) -> [Int]? {
        guard let regex = try? NSRegularExpression(pattern: AppConfig.Remediation.deviceVersionPattern),
              let match = regex.firstMatch(in: url.lastPathComponent,
                  range: NSRange(url.lastPathComponent.startIndex..., in: url.lastPathComponent)),
              let range = Range(match.range(at: 1), in: url.lastPathComponent) else { return nil }
        return url.lastPathComponent[range].split(separator: ".").compactMap { Int($0) }
    }

    static func mustKeepDeviceSupport(_ url: URL) -> Bool {
        let parent = url.deletingLastPathComponent()
        guard parent.lastPathComponent.hasSuffix(AppConfig.Remediation.deviceSupportSuffix),
              let candidate = version(url),
              let siblings = try? FileManager.default.contentsOfDirectory(at: parent, includingPropertiesForKeys: nil) else { return true }
        let versions = siblings.compactMap(version)
        guard let latest = versions.max(by: { $0.lexicographicallyPrecedes($1) }) else { return true }
        return candidate == latest
    }

    /// 测试专用注入钩子：模拟当前工作目录 (cwd)
    #if DEBUG
    static nonisolated(unsafe) var currentWorkingDirectoryOverrideForTesting: URL? = nil
    #else
    static var currentWorkingDirectoryOverrideForTesting: URL? { nil }
    #endif

    static func isCurrentWorkingDirectoryConflict(_ url: URL) -> Bool {
        let rawCwd = (currentWorkingDirectoryOverrideForTesting
            ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
            .resolvingSymlinksInPath().standardizedFileURL.path
        let rawTarget = url.resolvingSymlinksInPath().standardizedFileURL.path
        let cwdPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(rawCwd)
        let targetPath = SymlinkGuard.canonicalizeMacOSSystemPrefix(rawTarget)
        let projectRootPath = (targetPath as NSString).deletingLastPathComponent
        if cwdPath == targetPath || cwdPath.hasPrefix(targetPath + "/") {
            return true
        }
        if !projectRootPath.isEmpty && projectRootPath != "/" {
            if cwdPath == projectRootPath || cwdPath.hasPrefix(projectRootPath + "/") {
                return true
            }
        }
        return false
    }

    /// 检查 Terraform 目标及其根目录是否包含活跃状态或工作区信息
    static func hasDangerousTerraformState(for url: URL) -> Bool {
        guard url.lastPathComponent == ".terraform" else { return false }
        let projectRoot = url.deletingLastPathComponent()

        // 1. 本地状态文件与备份 (terraform.tfstate, terraform.tfstate.backup)
        for file in AppConfig.Remediation.terraformStateFiles {
            if FileUtil.exists(projectRoot.appendingPathComponent(file).path) {
                return true
            }
        }
        // 2. 多工作区状态目录 (terraform.tfstate.d)
        for dir in AppConfig.Remediation.terraformStateDirs {
            if FileUtil.exists(projectRoot.appendingPathComponent(dir).path) {
                return true
            }
        }
        // 3. 当前激活工作区标记 (.terraform/environment)
        if FileUtil.exists(url.appendingPathComponent(AppConfig.Remediation.terraformWorkspaceIndicator).path) {
            return true
        }
        return false
    }

    static func isEligibleProjectArtifact(_ url: URL) -> Bool {
        guard isProvenProjectArtifact(url),
              ProjectPurgeEngine.hasCacheProof(for: url),
              !hasDangerousTerraformState(for: url),
              GitGuard.isSafeToPurge(url: url).isSafe,
              !GitGuard.hasDirtyWorkingTree(containing: url),
              !isCurrentWorkingDirectoryConflict(url) else {
            return false
        }
        return true
    }

    static func mayExecute(_ url: URL) -> Bool {
        if url.deletingLastPathComponent().lastPathComponent.hasSuffix(AppConfig.Remediation.deviceSupportSuffix) {
            return !mustKeepDeviceSupport(url)
        }
        if ProjectPurgeEngine.targetArtifactNames.contains(url.lastPathComponent) {
            return isEligibleProjectArtifact(url)
        }
        return true
    }
}
