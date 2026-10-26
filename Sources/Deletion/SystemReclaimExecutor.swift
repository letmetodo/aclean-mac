import Foundation

// ============================================================
//  SystemReclaimExecutor —— 系统专用资源与虚拟空间回收执行器
//
//  安全契约：
//    1. 绝不接收未经验证的原始 CleanTarget，仅消费通过门禁的 SystemReclaimCommand；
//    2. 真实如实汇报底层系统执行结果与释放容量，严禁用预估值粉饰结果；
//    3. 隔离外部命令行与 Helper 调用，支持 dry-run 模拟模式。
// ============================================================

enum SystemReclaimExecutor {
    /// Injectable system boundaries; tests still execute the production result handling.
    struct APFSOperations {
        let capacity: () -> (rawFree: Int64, free: Int64)
        let run: () -> ShellResult

        static var live: APFSOperations {
            APFSOperations(capacity: {
                let disk = DiskInfo.current()
                return (disk.rawFree, disk.free)
            }, run: {
                Shell.execute(AppConfig.SystemReclaim.tmutilPath,
                              AppConfig.SystemReclaim.snapshotThinningArguments,
                              timeout: AppConfig.SystemReclaim.snapshotThinningTimeout)
            })
        }
    }

    /// 执行系统级空间回收指令
    static func execute(
        _ command: SystemReclaimCommand,
        isDryRun: Bool = false,
        apfsOperations: APFSOperations = .live
    ) -> CleanOutcome {
        switch command {
        case let .apfsPurge(name, estimatedBytes):
            return executeAPFSPurge(name: name, estimatedBytes: estimatedBytes, isDryRun: isDryRun, operations: apfsOperations)

        case let .dockerPrune(name, endpoint, estimatedBytes):
            return executeDockerPrune(name: name, endpoint: endpoint, estimatedBytes: estimatedBytes, isDryRun: isDryRun)

        case let .simctlRuntimeDelete(name, identifier, size):
            return executeSimulatorRuntime(name: name, identifier: identifier, size: size, isDryRun: isDryRun, operations: apfsOperations)

        case let .simctlDeleteUnavailable(name, size):
            return executeSimulatorUnavailable(name: name, size: size, isDryRun: isDryRun, operations: apfsOperations)
        }
    }

    // MARK: - 私有执行细节

    /// 触发 APFS 本地快照与可清除空间回收
    private static func executeAPFSPurge(
        name: String,
        estimatedBytes: Int64,
        isDryRun: Bool,
        operations: APFSOperations
    ) -> CleanOutcome {
        if isDryRun {
            return CleanOutcome(
                name: name,
                path: "APFS Purgeable",
                size: estimatedBytes,
                ok: true,
                actionCategory: .systemReclaimed
            )
        }

        let beforeInfo = operations.capacity()
        let result = operations.run()
        let afterInfo = operations.capacity()

        let reclaimed = max(0, max(afterInfo.rawFree - beforeInfo.rawFree, afterInfo.free - beforeInfo.free))

        if result.exitCode != 0 {
            let errMsg = result.stderr.isEmpty ? result.stdout : result.stderr
            return CleanOutcome(
                name: name,
                path: "APFS Purgeable",
                size: 0,
                ok: false,
                error: errMsg.isEmpty ? L10n.localized(.failedToReclaimApfsPurgeableSpace) : errMsg,
                actionCategory: .failed
            )
        }

        // tmutil 成功：如实返回真实观测到的回收容量，无增量则报告 0，绝不用扫描预估值粉饰
        return CleanOutcome(
            name: name,
            path: "APFS Purgeable",
            size: reclaimed,
            ok: true,
            actionCategory: .systemReclaimed
        )
    }

    /// 触发 docker builder prune -f 容器空间回收
    private static func executeDockerPrune(
        name: String,
        endpoint: DockerEndpoint?,
        estimatedBytes: Int64,
        isDryRun: Bool
    ) -> CleanOutcome {
        if isDryRun {
            return CleanOutcome(
                name: name,
                path: "Docker Build Cache",
                size: estimatedBytes,
                ok: true,
                actionCategory: .systemReclaimed
            )
        }

        let res = DockerHelper.executeDockerPrune(endpoint: endpoint)
        if res.success {
            // 如实返回 prune 解析出的真实字节数（可能为0），绝不回退至扫描预估值
            return CleanOutcome(
                name: name,
                path: "Docker Build Cache",
                size: res.reclaimedBytes,
                ok: true,
                actionCategory: .systemReclaimed
            )
        } else {
            return CleanOutcome(
                name: name,
                path: "Docker",
                size: 0,
                ok: false,
                error: res.error ?? L10n.localized(.cleanErrorDockerPruneFailed),
                actionCategory: .failed
            )
        }
    }

    /// 触发 Xcode xcrun simctl runtime delete 模拟器专用删除
    private static func executeSimulatorRuntime(
        name: String,
        identifier: String,
        size: Int64,
        isDryRun: Bool,
        operations: APFSOperations = .live
    ) -> CleanOutcome {
        if isDryRun {
            return CleanOutcome(
                name: name,
                path: identifier,
                size: size,
                ok: true,
                actionCategory: .permanentlyDeleted
            )
        }

        let beforeInfo = operations.capacity()
        let res = XcodeHelper.deleteRuntime(identifier: identifier)
        let afterInfo = operations.capacity()
        let reclaimed = max(0, max(afterInfo.rawFree - beforeInfo.rawFree, afterInfo.free - beforeInfo.free))
        if res.success {
            return CleanOutcome(
                name: name,
                path: identifier,
                size: reclaimed,
                ok: true,
                actionCategory: .systemReclaimed
            )
        } else {
            return CleanOutcome(
                name: name,
                path: identifier,
                size: 0,
                ok: false,
                error: res.error ?? L10n.localized(.cleanErrorSimRuntimeDeleteFailed),
                actionCategory: .failed
            )
        }
    }

    /// 触发 xcrun simctl delete unavailable 清理不可用模拟器设备容器
    private static func executeSimulatorUnavailable(
        name: String,
        size: Int64,
        isDryRun: Bool,
        operations: APFSOperations = .live
    ) -> CleanOutcome {
        if isDryRun {
            return CleanOutcome(
                name: name,
                path: "xcrun simctl delete unavailable",
                size: size,
                ok: true,
                actionCategory: .permanentlyDeleted
            )
        }

        let beforeInfo = operations.capacity()
        let res = XcodeHelper.deleteUnavailableSimulators()
        let afterInfo = operations.capacity()
        let reclaimed = max(0, max(afterInfo.rawFree - beforeInfo.rawFree, afterInfo.free - beforeInfo.free))
        if res.success {
            return CleanOutcome(
                name: name,
                path: "xcrun simctl delete unavailable",
                size: reclaimed,
                ok: true,
                actionCategory: .systemReclaimed
            )
        } else {
            return CleanOutcome(
                name: name,
                path: "xcrun simctl delete unavailable",
                size: 0,
                ok: false,
                error: res.error ?? L10n.localized(.cleanErrorSimUnavailableDeleteFailed),
                actionCategory: .failed
            )
        }
    }
}
