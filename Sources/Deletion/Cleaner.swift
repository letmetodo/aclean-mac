import Foundation
import Darwin

// ============================================================
//  Cleaner —— 清理内核 (P1 多元分流重构版)
//
//  对应原版 CleaningCore：按节点逐个移除，产出分类型的结果。
//
//  最高铁律 (100% 遵从 DNA.md 宪章与实施指南 v3.1):
//    1. 系统必需 / 受保护路径 → 直接跳过 (规则库白名单 + 物理红线双重校验);
//    2. 严格执行 RiskControlMatrix 前置安全裁决 (Sequoia设置、ANE神经引擎、
//       SymlinkGuard 软链防逃逸、ProcessGuard 活跃态防冲突、GitGuard 版本控制避让);
//    3. 严禁在位修改第三方应用二进制签名与剥离语言包 (thinBinary 动作直接封锁);
//    4. 多元专用分流处理：
//       - APFS 可清除空间：原生路由至 tmutil thinLocalSnapshots；
//       - Xcode 模拟器运行时：原生路由至 xcrun simctl runtime delete <id>；
//       - Docker / OrbStack 虚拟释放：原生路由至 docker builder prune -f；
//       - 普通文件：100% 优先移入系统废纸篓 (FileManager.default.trashItem),
//         普通移入操作不使用永久删除；恢复取决于废纸篓内容仍然存在。
// ============================================================

enum Cleaner {

    // MARK: - 测试与模拟执行配置

    /// 模拟运行模式：当设为 true 时，完整执行全部路径解析、白名单、文件存在性与风控校验，
    /// 但阻断任何系统物理写入/删除调用（不会调用 tmutil、docker builder prune、xcrun simctl、removeItem 或 trashItem），
    /// 保证单元测试与端到端回归在宿主机执行时绝对 0 破坏、0 残留、0 污染。
    #if DEBUG
    private static let isDryRunStorage = LockedValue<Bool>(false)
    static var isDryRun: Bool {
        get { isDryRunStorage.withValue { $0 } }
        set { isDryRunStorage.withValue { $0 = newValue } }
    }

    /// 测试钩子：拦截/模拟 trashItem 行为
    public static nonisolated(unsafe) var onTrashHook: ((URL) throws -> URL?)? = nil
    /// 测试钩子：在目标被移至 staging 目录后、执行递归删除前触发
    public static nonisolated(unsafe) var onAfterClaimHook: ((URL) -> Void)? = nil
    /// 测试钩子：在每个节点执行 unlinkat 前触发
    public static nonisolated(unsafe) var onBeforeUnlinkHook: ((URL) throws -> Void)? = nil
    /// 测试钩子：临时授权废纸篓测试根目录
    public static nonisolated(unsafe) var authorizedTrashRootsOverride: [URL]? = nil

    #else
    static var isDryRun: Bool { false }
    static var onTrashHook: ((URL) throws -> URL?)? { nil }
    static var onAfterClaimHook: ((URL) -> Void)? { nil }
    static var onBeforeUnlinkHook: ((URL) throws -> Void)? { nil }
    static var authorizedTrashRootsOverride: [URL]? { nil }
    #endif

    // MARK: - 清理执行主入口

    static func clean(_ t: CleanTarget) -> CleanOutcome {
        let ruleLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleLease) {} }
        guard RuleTaskGate.shared.allows(t.ruleIdentity, ruleID: t.ruleEvidence?.id),
              t.ruleEvidence == nil || t.ruleEvidence?.ruleIdentity == t.ruleIdentity else {
            return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: 0, ok: false,
                                error: L10n.localized(.ruleUpdateRescanRequired), actionCategory: .skipped)
        }

        guard KnowledgeBaseManager.shared.isLoaded, KnowledgeBaseManager.shared.authored.loaded else {
            return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: 0, ok: false,
                                error: L10n.localized(.ruleDatabaseUnavailableTitle), actionCategory: .skipped)
        }
        if IOScanContext.isCancelled {
            return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: 0,
                                ok: false, error: L10n.localized(.cleanupCancelledResult), actionCategory: .cancelled)
        }
        // 0) 锁定项目直接跳过
        if t.locked {
            return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: t.size,
                                ok: false, error: tr(.cleanSkippedProtected),
                                actionCategory: .skipped)
        }

        // 1) 动作合法性封锁：彻底封锁二进制精简
        if case .thinBinary = t.action {
            return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: t.size,
                                ok: false, error: tr(.errorRedlineBinaryModification),
                                actionCategory: .failed)
        }

        // 1.5) 强类型清理授权上下文门禁（跨模块零退化 + 垃圾规则无证据零放行）
        switch t.authorizationContext {
        case .systemMaintenance:
            switch t.action {
            case .custom, .apfsPurge, .dockerPrune, .simctlRuntimeDelete, .simctlDeleteUnavailable:
                break
            default:
                return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: t.size, ok: false,
                                    error: L10n.localized(.cleanSkippedProtected), actionCategory: .skipped)
            }
        case .trashBin:
            guard case .permanentlyDeleteTrashItem = t.action,
                  t.executionMode == .manual else {
                return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: t.size, ok: false,
                                    error: L10n.localized(.cleanSkippedProtected), actionCategory: .skipped)
            }
        case .junkRule:
            guard (t.action == .trash || t.action == .emptyContainer),
                  KnowledgeBaseManager.shared.authored.loaded,
                  let evidence = t.ruleEvidence,
                  evidence.executable,
                  !evidence.id.hasPrefix("UNINST_"),
                  (t.executionMode != .automatic || (evidence.tier == .automatic && evidence.defaultSelected)) else {
                return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: t.size, ok: false,
                                    error: L10n.localized(.cleanSkippedProtected), actionCategory: .skipped)
            }
        case .uninstall:
            guard case .trash = t.action,
                  t.executionMode == .manual,
                  let context = t.uninstallContext,
                  !context.bundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: t.size, ok: false,
                                    error: L10n.localized(.cleanupUninstallBlocked), actionCategory: .skipped)
            }
        case .organizeManual:
            guard case .trash = t.action,
                  t.executionMode == .manual,
                  t.ruleEvidence == nil else {
                return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: t.size, ok: false,
                                    error: L10n.localized(.cleanSkippedProtected), actionCategory: .skipped)
            }
        }

        // 2) 非文件型维护任务动作分流（仅允许显式 maint:<taskId> 稳定注册表路由，移除 t.name 模糊兜底）
        if case .custom(let customPayload) = t.action {
            guard t.authorizationContext == .systemMaintenance,
                  customPayload.hasPrefix("maint:") else {
                return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: t.size, ok: false,
                                    error: tr(.maintenanceTaskNotFound),
                                    actionCategory: .failed)
            }
            let taskID = String(customPayload.dropFirst("maint:".count))
            if let task = PerformanceEngine.findRegisteredTask(byTaskID: taskID) {
                if isDryRun {
                    return CleanOutcome(name: t.name, path: "", size: t.size, ok: true, actionCategory: .maintenanceExecuted)
                }
                let ok = PerformanceEngine.runTask(task)
                return CleanOutcome(name: t.name, path: "", size: t.size, ok: ok,
                                    error: ok ? nil : tr(.executionFailedOrUserCancelledAuth),
                                    actionCategory: .maintenanceExecuted)
            }
            return CleanOutcome(name: t.name, path: t.url?.path ?? "", size: t.size, ok: false,
                                error: tr(.maintenanceTaskNotFound),
                                actionCategory: .failed)
        }

        // 3) 专用系统级回收分流 (经过强类型门禁与运行态校验，生成 VerifiedCleanCommand 并交由 SystemReclaimExecutor)
        switch t.action {
        case .apfsPurge:
            let cmd = SystemReclaimCommand.apfsPurge(name: t.name, estimatedBytes: t.size)
            return SystemReclaimExecutor.execute(cmd, isDryRun: isDryRun)

        case .dockerPrune:
            let cmd = SystemReclaimCommand.dockerPrune(name: t.name, endpoint: t.dockerEndpoint, estimatedBytes: t.size)
            return SystemReclaimExecutor.execute(cmd, isDryRun: isDryRun)

        case .simctlRuntimeDelete(let identifier):
            guard !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return CleanOutcome(name: t.name, path: identifier, size: t.size, ok: false,
                                    error: L10n.localized(.cleanErrorInvalidSimRuntime), actionCategory: .failed)
            }
            let running = ProcessGuard.isAnyToolchainRunning(AppConfig.Security.simulatorProcesses)
            guard !running.isRunning else {
                return CleanOutcome(name: t.name, path: identifier, size: t.size, ok: false,
                                    error: L10n.localized(.statusAppRunningSkipped), actionCategory: .skipped)
            }
            let cmd = SystemReclaimCommand.simctlRuntimeDelete(name: t.name, identifier: identifier, size: t.size)
            return SystemReclaimExecutor.execute(cmd, isDryRun: isDryRun)

        case .simctlDeleteUnavailable:
            let running = ProcessGuard.isAnyToolchainRunning(AppConfig.Security.simulatorProcesses)
            guard !running.isRunning else {
                return CleanOutcome(name: t.name, path: "xcrun simctl delete unavailable", size: t.size, ok: false,
                                    error: L10n.localized(.statusAppRunningSkipped), actionCategory: .skipped)
            }
            let cmd = SystemReclaimCommand.simctlDeleteUnavailable(name: t.name, size: t.size)
            return SystemReclaimExecutor.execute(cmd, isDryRun: isDryRun)

        default:
            break
        }

        // 4) 普通文件物理校验与风控前置
        guard let url = t.url else {
            return CleanOutcome(name: t.name, path: "", size: t.size,
                                ok: false, error: L10n.localized(.cleanErrorMissingFilePath), actionCategory: .failed)
        }

        // Gate 5.2: 严禁将 DARWIN_USER_TEMP_DIR、DARWIN_USER_CACHE_DIR、~/Library/Caches、~/Library/Logs、/tmp、/var/tmp 根路径自身作为清理目标
        if AuthoredRules.isProtectedSystemOrCacheRoot(url) {
            return CleanOutcome(name: t.name, path: url.path, size: t.size,
                                ok: false, error: L10n.localized(.cleanSkippedProtected), actionCategory: .skipped)
        }

        var existence = stat()
        if lstat(url.path, &existence) != 0 {
            let error = NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            let failure = CleanupFailure.classify(error)
            return CleanOutcome(name: t.name, path: url.path, size: t.size,
                                ok: false, error: error.localizedDescription,
                                actionCategory: failure == .missing ? .absent : .failed,
                                failureKind: failure)
        }

        if t.ownerBundleIDs.contains(where: { ProcessGuard.isAppRunning(bundleID: $0) }) {
            return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                error: L10n.localized(.statusAppRunningSkipped), actionCategory: .skipped)
        }
        if let evidence = t.ruleEvidence,
           let rule = KnowledgeBaseManager.shared.authored.junk[evidence.id] {
            let store = KnowledgeBaseManager.shared.authored
            if store.hasRunningAppLock(for: url, rule: rule, isRunning: ProcessGuard.isAppRunning(bundleID:))
                || ProcessGuard.isAnyToolchainRunning(store.effectiveProcessLocks(for: url, rule: rule)).isRunning {
                return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                    error: L10n.localized(.statusAppRunningSkipped), actionCategory: .skipped)
            }
        }

        // 4.5) TOCTOU 物理身份校验 (防止扫描至执行期间符号链接替换劫持)
        guard let expected = t.expectedIdentity, expected.matches(url: url) else {
            return CleanOutcome(name: t.name, path: url.path, size: t.size,
                                ok: false, error: L10n.localized(.cleanupFileChanged),
                                actionCategory: .failed)
        }

        if let context = t.uninstallContext, context.isAppBody {
            let info = NSDictionary(contentsOf: url.appendingPathComponent(AppConfig.Remediation.infoPlistPath))
            guard (info?[AppConfig.Remediation.bundleIDKey] as? String)?.lowercased() == context.bundleID.lowercased() else {
                return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                    error: L10n.localized(.cleanupFileChanged), actionCategory: .skipped)
            }
        }
        if let context = t.uninstallContext, !UninstallSafety.canDeleteAssociatedData(context, url: url) {
            return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                error: L10n.localized(.cleanupUninstallBlocked), actionCategory: .skipped)
        }
        if !DeveloperArtifactPolicy.mayExecute(url) {
            return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                error: L10n.localized(.cleanSkippedProtected), actionCategory: .skipped)
        }
        let requireCurrentUserUID = (t.authorizationContext == .junkRule)

        // 4.6) P2 (Section 5.4): 受控容器级清空动作 emptyContainer（统一门禁审计与验证指令生成，交由 ContainerCleanExecutor 执行）
        if case .emptyContainer = t.action {
            let store = KnowledgeBaseManager.shared.authored
            guard expected.isDirectory,
                  !SymlinkGuard.hasSymlinkEscape(url: url),
                  let evidence = t.ruleEvidence,
                  evidence.executable,
                  !evidence.id.hasPrefix("UNINST_"),
                  let rule = store.junk[evidence.id],
                  rule.action == "trash_children_only" else {
                return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                    error: L10n.localized(.cleanSkippedProtected), actionCategory: .skipped)
            }

            // 根级统一复核：
            // 1) 运行时 store.evidence() 与进程锁复核
            let current = store.evidence(
                for: url,
                preferredID: evidence.id,
                isContainerRoot: true,
                identity: expected,
                knownSize: t.measuredBytes,
                requireCurrentUserUID: requireCurrentUserUID
            )
            let validRootEvidence = current?.executable == true
                && current.map { evidence.tier.conservatismRank >= $0.tier.conservatismRank } == true
                && (t.executionMode != .automatic || (current?.tier == .automatic && current?.defaultSelected == true))
            guard validRootEvidence else {
                return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                    error: L10n.localized(.cleanupFileChanged), actionCategory: .skipped)
            }

            // 2) 全链路安全风控矩阵裁决
            GitGuard.invalidateTrackedCache()
            let safetyCheck = RiskControlMatrix.validateCleanTarget(
                url: url,
                action: .emptyContainer,
                parentRuleID: evidence.id,
                requireCurrentUserUID: requireCurrentUserUID
            )
            guard safetyCheck.isSafe else {
                return CleanOutcome(name: t.name, path: url.path, size: t.size,
                                    ok: false, error: safetyCheck.reason ?? L10n.localized(.cleanSkippedProtected),
                                    actionCategory: .skipped)
            }

            // 3) 仅执行 1 次容器根级 OpenFileGuard.isIdle(containerURL, fresh: true)
            guard OpenFileGuard.isIdle(url, fresh: true, requireCurrentUserUID: requireCurrentUserUID) else {
                return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                    error: L10n.localized(.safetyInspectionIncomplete), actionCategory: .skipped)
            }
            if IOScanContext.isCancelled {
                return CleanOutcome(name: t.name, path: url.path, size: 0, ok: false,
                                    error: L10n.localized(.cleanupCancelledResult), actionCategory: .cancelled)
            }
            guard expected.matches(url: url), !SymlinkGuard.hasSymlinkEscape(url: url) else {
                return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                    error: L10n.localized(.cleanupFileChanged), actionCategory: .skipped)
            }

            let command = ContainerCleanCommand(
                targetName: t.name,
                url: url,
                targetSize: t.size,
                measuredBytes: t.measuredBytes,
                expectedIdentity: expected,
                rule: rule,
                evidence: evidence,
                runtimeStoreEvidence: current,
                requireCurrentUserUID: requireCurrentUserUID,
                executionMode: t.executionMode,
                authorizationContext: t.authorizationContext,
                containerChildren: t.containerChildren,
                retryChildPaths: t.retryChildPaths
            )
            return ContainerCleanExecutor.execute(command, isDryRun: isDryRun)
        }

        // A manually constructed target cannot bypass a read-only runtime rule.
        let runtimeEvidence = KnowledgeBaseManager.shared.authored.evidence(
            for: url,
            preferredID: t.ruleEvidence?.id == AppConfig.RuleIDs.leftoverOrphan ? AppConfig.RuleIDs.leftoverOrphan : nil,
            identity: expected,
            knownSize: t.measuredBytes,
            requireCurrentUserUID: requireCurrentUserUID
        )
        if runtimeEvidence?.executable == false {
            return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                error: L10n.localized(.cleanSkippedProtected), actionCategory: .skipped)
        }
        if let runtime = runtimeEvidence,
           KnowledgeBaseManager.shared.authored.junk[runtime.id]?.action == "trash_children_only",
           expected.isDirectory, t.ruleEvidence?.containerPath == nil {
            return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                error: L10n.localized(.cleanSkippedProtected), actionCategory: .skipped)
        }
        if let evidence = t.ruleEvidence {
            var valid = evidence.executable
            if evidence.id.hasPrefix("UNINST_") {
                valid = valid
                    && t.uninstallContext != nil
                    && KnowledgeBaseManager.shared.authored.templatesLoaded
                    && KnowledgeBaseManager.shared.authored.templates.contains {
                        $0.id == evidence.id && $0.execute && $0.domain == "user" && $0.tier.executable
                    }
            } else {
                let store = KnowledgeBaseManager.shared.authored
                let isContainerChild = evidence.containerPath != nil
                let lookup = evidence.containerPath.map { URL(fileURLWithPath: $0) } ?? url
                let parentRuleID: String? = {
                    guard isContainerChild else { return evidence.id }
                    if store.junk[evidence.id]?.action == "trash_children_only" {
                        return evidence.id
                    }
                    return store.evidence(for: lookup, isContainerRoot: true)?.id
                }()
                let current = store.evidence(
                    for: lookup,
                    preferredID: parentRuleID,
                    isContainerRoot: isContainerChild,
                    identity: isContainerChild ? nil : expected,
                    knownSize: isContainerChild ? nil : t.measuredBytes,
                    requireCurrentUserUID: requireCurrentUserUID
                )
                valid = valid
                    && current?.executable == true
                    && current.map { evidence.tier.conservatismRank >= $0.tier.conservatismRank } == true
                    && (t.executionMode != .automatic || (current?.tier == .automatic && current?.defaultSelected == true))
                if isContainerChild {
                    let childCurrent = store.evidence(
                        for: url,
                        preferredID: evidence.id,
                        isContainerRoot: false,
                        identity: expected,
                        knownSize: t.measuredBytes,
                        requireCurrentUserUID: requireCurrentUserUID
                    )
                    let childUnconstrained = store.evidence(
                        for: url,
                        preferredID: nil,
                        isContainerRoot: false,
                        identity: expected,
                        knownSize: t.measuredBytes,
                        requireCurrentUserUID: requireCurrentUserUID
                    )
                    let requiresDirectChildMatch = (evidence.id != parentRuleID)
                    valid = valid
                        && (requiresDirectChildMatch ? childCurrent?.executable == true : childCurrent?.executable != false)
                        && (childCurrent.map { evidence.tier.conservatismRank >= $0.tier.conservatismRank } ?? !requiresDirectChildMatch)
                        && childUnconstrained?.executable != false
                        && (childUnconstrained.map { evidence.tier.conservatismRank >= $0.tier.conservatismRank } ?? true)
                        && (t.executionMode != .automatic || (
                            (requiresDirectChildMatch ? (childCurrent?.tier == .automatic && childCurrent?.defaultSelected == true) : childCurrent?.tier != .review)
                            && childUnconstrained?.tier != .review
                        ))
                }
                if let container = evidence.containerPath, let identity = evidence.containerIdentity,
                   let actual = FileIdentity.capture(from: lookup) {
                    valid = valid && actual.device == identity.device && actual.inode == identity.inode
                        && actual.mode == identity.mode && url.deletingLastPathComponent().standardizedFileURL.path == container
                } else if evidence.containerPath != nil { valid = false }
                if store.junk[evidence.id]?.action == "trash_children_only", evidence.containerPath == nil, expected.isDirectory { valid = false }

                if valid && t.authorizationContext == .junkRule {
                    let execInspection = FastDirectoryInspector.inspect(
                        url,
                        identity: expected,
                        parentRuleID: evidence.id,
                        parentTier: current?.tier ?? evidence.tier,
                        requireCurrentUserUID: requireCurrentUserUID,
                        measurePhysicalBytes: true,
                        forExecution: true
                    )
                    if !execInspection.measurementComplete
                        || !execInspection.safetyInspection.isSafe
                        || (requireCurrentUserUID && !execInspection.allCurrentUserOwned)
                        || (t.executionMode == .automatic && execInspection.safetyInspection.downgradeAutomaticToReview) {
                        valid = false
                    } else if t.executionMode == .automatic {
                        let unitURL: URL = {
                            if let unitPath = t.cacheRecommendation?.unitPath, !unitPath.isEmpty {
                                return URL(fileURLWithPath: unitPath)
                            }
                            if let containerPath = evidence.containerPath, !containerPath.isEmpty {
                                return URL(fileURLWithPath: containerPath)
                            }
                            if let matchedUnit = store.matchingCacheProfileUnits(for: url, ruleID: evidence.id).first?.unitURL {
                                return matchedUnit
                            }
                            return url
                        }()
                        let freshUnitIdentity = FileIdentity.capture(from: unitURL)
                        if let expectedUnitId = t.cacheRecommendation?.unitIdentity ?? evidence.containerIdentity {
                            if freshUnitIdentity?.device != expectedUnitId.device
                                || freshUnitIdentity?.inode != expectedUnitId.inode
                                || freshUnitIdentity?.mode != expectedUnitId.mode {
                                valid = false
                            }
                        }
                        if valid {
                            let unitInspection: FastDirectoryInspector.InspectionResult = (unitURL.standardizedFileURL == url.standardizedFileURL)
                                ? execInspection
                                : FastDirectoryInspector.inspect(
                                    unitURL,
                                    identity: freshUnitIdentity,
                                    parentRuleID: parentRuleID ?? evidence.id,
                                    parentTier: current?.tier ?? evidence.tier,
                                    requireCurrentUserUID: requireCurrentUserUID,
                                    measurePhysicalBytes: true,
                                    forExecution: true
                                )
                            if !unitInspection.measurementComplete
                                || !unitInspection.safetyInspection.isSafe
                                || (requireCurrentUserUID && !unitInspection.allCurrentUserOwned)
                                || unitInspection.safetyInspection.downgradeAutomaticToReview {
                                valid = false
                            } else {
                                let freshRec = JunkCacheRecommendationPolicy.evaluate(
                                    url: unitURL,
                                    unitURL: unitURL,
                                    unitIdentity: freshUnitIdentity,
                                    ruleEvidence: current ?? evidence,
                                    allocatedBytes: unitInspection.physicalBytes,
                                    safetyGatePassed: true,
                                    store: store
                                )
                                if !freshRec.automaticAllowed
                                    || freshRec.state == .suggestedLarge
                                    || freshRec.state == .blocked {
                                    valid = false
                                }
                            }
                        }
                    }
                }
            }
            guard valid else {
                return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                    error: L10n.localized(.cleanupFileChanged), actionCategory: .skipped)
            }
        }

        // 全链路安全风控矩阵裁决 (Sequoia / ANE / 虚拟机磁盘 / Symlink / Process / Git)
        GitGuard.invalidateTrackedCache()
        let safetyCheck = RiskControlMatrix.validateCleanTarget(
            url: url,
            action: t.action,
            parentRuleID: t.ruleEvidence?.id,
            requireCurrentUserUID: requireCurrentUserUID
        )
        if !safetyCheck.isSafe {
            return CleanOutcome(name: t.name, path: url.path, size: t.size,
                                ok: false, error: safetyCheck.reason ?? L10n.localized(.cleanSkippedProtected),
                                actionCategory: .skipped)
        }

        if let evidence = t.duplicateEvidence, !evidence.validates(target: url) {
            return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                error: L10n.localized(.cleanupDuplicateUnavailable), actionCategory: .skipped)
        }
        let isTargetIdle: Bool = {
            if let containerPath = t.ruleEvidence?.containerPath,
               let context = IOScanContext.current {
                let containerURL = URL(fileURLWithPath: containerPath)
                return context.containerIdleStatus(for: containerPath) {
                    OpenFileGuard.isIdle(containerURL, fresh: true, requireCurrentUserUID: requireCurrentUserUID)
                }
            }
            return OpenFileGuard.isIdle(url, fresh: true, requireCurrentUserUID: requireCurrentUserUID)
        }()
        guard isTargetIdle else {
            return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                error: L10n.localized(.safetyInspectionIncomplete), actionCategory: .skipped)
        }
        // Recheck after potentially expensive inspection/hash, immediately before mutation.
        if IOScanContext.isCancelled {
            return CleanOutcome(name: t.name, path: url.path, size: 0, ok: false,
                                error: L10n.localized(.cleanupCancelledResult), actionCategory: .cancelled)
        }
        guard expected.matches(url: url), !SymlinkGuard.hasSymlinkEscape(url: url) else {
            return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                error: L10n.localized(.cleanupFileChanged), actionCategory: .skipped)
        }

        // 5) 专用永久删除分支：必须为显式 .permanentlyDeleteTrashItem 动作，且为授权废纸篓根目录的严格子项
        if case .permanentlyDeleteTrashItem = t.action {
            let authorizedRoots = Cleaner.authorizedTrashRootsOverride ?? FileUtil.authorizedTrashRoots()
            guard authorizedRoots.contains(where: { FileUtil.isStrictDescendant(url, of: $0) }) else {
                return CleanOutcome(name: t.name, path: url.path, size: t.size,
                                    ok: false, error: L10n.localized(.cleanErrorTrashRootViolation),
                                    actionCategory: .failed)
            }

            guard !SymlinkGuard.hasSymlinkEscape(url: url) else {
                return CleanOutcome(name: t.name, path: url.path, size: t.size,
                                    ok: false, error: L10n.localized(.cleanErrorSymlinkEscape),
                                    actionCategory: .failed)
            }

            if isDryRun {
                return CleanOutcome(name: t.name, path: url.path, size: !expected.isDirectory && expected.linkCount > 1 ? 0 : t.size,
                                    ok: true, actionCategory: .permanentlyDeleted)
            }

            do {
                let removal = try TrashDeletion.remove(url, expected: expected, authorizedRoots: authorizedRoots)
                return CleanOutcome(name: t.name, path: url.path, size: removal.deletedBytes,
                                    ok: true, actionCategory: .permanentlyDeleted,
                                    permanentlyDeletedBytes: removal.deletedBytes)
            } catch let removalError as TrashDeletion.RemovalError {
                let isCancel = removalError.underlyingError is CancellationError
                let category: CleanActionCategory = removalError.deletedCount > 0
                    ? .partialFailure
                    : (isCancel ? .cancelled : .failed)
                return CleanOutcome(
                    name: t.name,
                    path: url.path,
                    size: removalError.deletedBytes,
                    ok: false,
                    error: removalError.errorDescription,
                    actionCategory: category,
                    failedChildren: removalError.failedChildren,
                    failureKind: isCancel ? nil : CleanupFailure.classify(removalError.underlyingError),
                    recoveryURL: removalError.recoveryURL,
                    permanentlyDeletedBytes: removalError.deletedBytes
                )
            } catch {
                return CleanOutcome(name: t.name, path: url.path, size: t.size,
                                    ok: false, error: error.localizedDescription,
                                    actionCategory: error is CancellationError ? .cancelled : .failed,
                                    failureKind: error is CancellationError ? nil : CleanupFailure.classify(error))
            }
        }

        guard RuleTaskGate.shared.allows(t.ruleIdentity, ruleID: t.ruleEvidence?.id) else {
            return CleanOutcome(name: t.name, path: url.path, size: 0, ok: false,
                                error: L10n.localized(.ruleUpdateRescanRequired), actionCategory: .skipped)
        }
        // 6) 普通文件 100% 移入系统废纸篓 (trashItem 提供完全可恢复支持，普通 .trash 动作绝不执行永久删除)
        switch t.action {
        case .trash:
            if isDryRun {
                return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: true, actionCategory: .movedToTrash)
            }
            do {
                let destination = try TrashMover.trash(url)
                return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: true,
                                    actionCategory: .movedToTrash, destinationURL: destination,
                                    trashedURLs: destination.map { [$0] } ?? [],
                                    restoreItems: destination.map { [CleanupRestoreItem(originalURL: url, trashURL: $0, bytes: t.size)] } ?? [])
            } catch {
                return CleanOutcome(name: t.name, path: url.path, size: t.size, ok: false,
                                    error: error.localizedDescription, actionCategory: .failed,
                                    failureKind: CleanupFailure.classify(error))
            }

        default:
            return CleanOutcome(name: t.name, path: url.path, size: t.size,
                                ok: false, error: L10n.localized(.cleanErrorUnknownAction), actionCategory: .failed)
        }
    }

    // ============================================================
    // MARK: - 私有废纸篓底层不可逆清理 (所有权收敛至 Cleaner)
    // ============================================================

    private enum TrashDeletion {
        struct RemovalOutcome: Sendable, Equatable {
            var deletedBytes: Int64
            var deletedCount: Int
        }

        struct RemovalError: LocalizedError, CustomNSError, Sendable {
            let underlyingError: Error
            let deletedBytes: Int64
            let deletedCount: Int
            let recoveryURL: URL?
            let restoredToOriginalPath: Bool
            let failedChildren: [String]

            var errorDescription: String? {
                let base = (underlyingError as? LocalizedError)?.errorDescription ?? underlyingError.localizedDescription
                if !failedChildren.isEmpty {
                    return failedChildren.joined(separator: "; ")
                }
                return base
            }

            static var errorDomain: String { "CleanMate.TrashDeletionError" }

            var errorCode: Int { (underlyingError as NSError).code }

            var errorUserInfo: [String: Any] {
                var info = (underlyingError as NSError).userInfo
                info[NSUnderlyingErrorKey] = underlyingError
                if let recoveryURL {
                    info[NSURLErrorKey] = recoveryURL
                }
                return info
            }
        }

        @discardableResult
        static func remove(
            _ url: URL,
            expected: FileIdentity,
            authorizedRoots: [URL]
        ) throws -> RemovalOutcome {
            guard authorizedRoots.contains(where: { FileUtil.isStrictDescendant(url, of: $0) }) else {
                throw CocoaError(.fileWriteNoPermission)
            }
            let canonical = SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path)
            let canonicalURL = URL(fileURLWithPath: canonical)
            let parts = canonicalURL.pathComponents.filter { $0 != "/" }
            guard let name = parts.last else { throw CocoaError(.fileWriteNoPermission) }
            var parent = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard parent >= 0 else { throw posixError() }
            defer { close(parent) }
            for component in parts.dropLast() {
                let next = openat(parent, component, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
                guard next >= 0 else { throw posixError() }
                close(parent); parent = next
            }
            var original = stat()
            guard fstatat(parent, name, &original, AT_SYMLINK_NOFOLLOW) == 0,
                  original.st_dev == expected.device, original.st_ino == expected.inode,
                  expected.matches(url: url) else { throw CocoaError(.fileWriteUnknown) }
            // Atomically claim one name into a mode-0700 directory on the same filesystem.
            let staging = ".aclean-delete-" + UUID().uuidString
            guard mkdirat(parent, staging, S_IRWXU) == 0 else { throw posixError() }
            let stage = openat(parent, staging, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard stage >= 0 else {
                _ = unlinkat(parent, staging, AT_REMOVEDIR)
                throw posixError()
            }
            var shouldRemoveStagingDir = true
            defer {
                close(stage)
                if shouldRemoveStagingDir {
                    _ = unlinkat(parent, staging, AT_REMOVEDIR)
                }
            }
            guard renameatx_np(parent, name, stage, name, UInt32(RENAME_EXCL)) == 0 else { throw posixError() }
            Cleaner.onAfterClaimHook?(canonicalURL)
            var claimed = stat()
            guard fstatat(stage, name, &claimed, AT_SYMLINK_NOFOLLOW) == 0,
                  claimed.st_dev == original.st_dev, claimed.st_ino == original.st_ino,
                  claimed.st_size == original.st_size,
                  claimed.st_mtimespec.tv_sec == original.st_mtimespec.tv_sec,
                  claimed.st_mtimespec.tv_nsec == original.st_mtimespec.tv_nsec else {
                let recovery = restoreClaimedItem(
                    stage: stage,
                    parent: parent,
                    name: name,
                    stagingName: staging,
                    originalURL: canonicalURL
                )
                shouldRemoveStagingDir = recovery.stageEmpty
                throw RemovalError(
                    underlyingError: CocoaError(.fileWriteUnknown),
                    deletedBytes: 0,
                    deletedCount: 0,
                    recoveryURL: recovery.recoveryURL,
                    restoredToOriginalPath: recovery.restoredToOriginal,
                    failedChildren: []
                )
            }
            var deletedBytes: Int64 = 0
            var deletedCount: Int = 0
            var failedChildren: [String] = []
            do {
                try unlinkTree(
                    parent: stage,
                    name: name,
                    device: original.st_dev,
                    logicalURL: canonicalURL,
                    deletedBytes: &deletedBytes,
                    deletedCount: &deletedCount,
                    failedChildren: &failedChildren
                )
                return RemovalOutcome(deletedBytes: deletedBytes, deletedCount: deletedCount)
            } catch {
                let recovery = restoreClaimedItem(
                    stage: stage,
                    parent: parent,
                    name: name,
                    stagingName: staging,
                    originalURL: canonicalURL
                )
                shouldRemoveStagingDir = recovery.stageEmpty
                throw RemovalError(
                    underlyingError: error,
                    deletedBytes: deletedBytes,
                    deletedCount: deletedCount,
                    recoveryURL: recovery.recoveryURL,
                    restoredToOriginalPath: recovery.restoredToOriginal,
                    failedChildren: failedChildren
                )
            }
        }

        private static func restoreClaimedItem(
            stage: Int32,
            parent: Int32,
            name: String,
            stagingName: String,
            originalURL: URL
        ) -> (recoveryURL: URL, restoredToOriginal: Bool, stageEmpty: Bool) {
            let parentDirURL = originalURL.deletingLastPathComponent()
            if renameatx_np(stage, name, parent, name, UInt32(RENAME_EXCL)) == 0 {
                return (originalURL, true, true)
            }
            for attempt in 0..<16 {
                let suffix = attempt == 0 ? String(UUID().uuidString.prefix(8)) : UUID().uuidString
                let fallbackName = "\(name).recovered-\(suffix)"
                if renameatx_np(stage, name, parent, fallbackName, UInt32(RENAME_EXCL)) == 0 {
                    return (parentDirURL.appendingPathComponent(fallbackName), false, true)
                }
            }
            let stagedLocation = parentDirURL.appendingPathComponent(stagingName).appendingPathComponent(name)
            return (stagedLocation, false, false)
        }

        private static func unlinkTree(
            parent: Int32,
            name: String,
            device: dev_t,
            logicalURL: URL,
            deletedBytes: inout Int64,
            deletedCount: inout Int,
            failedChildren: inout [String]
        ) throws {
            if IOScanContext.isCancelled { throw CancellationError() }
            var st = stat()
            guard fstatat(parent, name, &st, AT_SYMLINK_NOFOLLOW) == 0 else {
                let err = posixError()
                failedChildren.append("\(name): \(err.localizedDescription)")
                throw err
            }
            guard st.st_dev == device else {
                let err = CocoaError(.fileWriteNoPermission)
                failedChildren.append("\(name): \(err.localizedDescription)")
                throw err
            }
            if st.st_mode & S_IFMT != S_IFLNK {
                guard !CleanupSafetyPolicy.isProtectedAsset(logicalURL),
                      !AppConfigStore.shared.isPathIgnoredForDeletion(logicalURL.path),
                      !GitGuard.isSensitiveFilename(name), name != ".git" else {
                    let err = CocoaError(.fileWriteNoPermission)
                    failedChildren.append("\(name): \(err.localizedDescription)")
                    throw err
                }
            }
            if st.st_mode & S_IFMT == S_IFDIR {
                let fd = openat(parent, name, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
                guard fd >= 0 else {
                    let err = posixError()
                    failedChildren.append("\(name): \(err.localizedDescription)")
                    throw err
                }
                defer { close(fd) }
                var opened = stat()
                guard fstat(fd, &opened) == 0, opened.st_ino == st.st_ino, opened.st_dev == st.st_dev else {
                    let err = CocoaError(.fileWriteUnknown)
                    failedChildren.append("\(name): \(err.localizedDescription)")
                    throw err
                }
                guard let directory = fdopendir(dup(fd)) else {
                    let err = posixError()
                    failedChildren.append("\(name): \(err.localizedDescription)")
                    throw err
                }
                defer { closedir(directory) }
                var childNames: [String] = []
                errno = 0
                while let entry = readdir(directory) {
                    let child = withUnsafePointer(to: &entry.pointee.d_name) {
                        $0.withMemoryRebound(to: CChar.self, capacity: Int(entry.pointee.d_namlen) + 1) { String(cString: $0) }
                    }
                    if child != "." && child != ".." {
                        childNames.append(child)
                    }
                    errno = 0
                }
                if errno != 0 {
                    let err = posixError()
                    failedChildren.append("\(name): \(err.localizedDescription)")
                    throw err
                }
                childNames.sort()
                var firstError: Error? = nil
                for child in childNames {
                    do {
                        try unlinkTree(
                            parent: fd,
                            name: child,
                            device: device,
                            logicalURL: logicalURL.appendingPathComponent(child),
                            deletedBytes: &deletedBytes,
                            deletedCount: &deletedCount,
                            failedChildren: &failedChildren
                        )
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        if firstError == nil {
                            firstError = error
                        }
                    }
                }
                if let firstError {
                    throw firstError
                }
                try Cleaner.onBeforeUnlinkHook?(logicalURL)
                guard unlinkat(parent, name, AT_REMOVEDIR) == 0 else {
                    let err = posixError()
                    failedChildren.append("\(name): \(err.localizedDescription)")
                    throw err
                }
            } else {
                do {
                    try Cleaner.onBeforeUnlinkHook?(logicalURL)
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    failedChildren.append("\(name): \(error.localizedDescription)")
                    throw error
                }
                guard unlinkat(parent, name, 0) == 0 else {
                    let err = posixError()
                    failedChildren.append("\(name): \(err.localizedDescription)")
                    throw err
                }
                if (st.st_mode & S_IFMT) == S_IFREG && st.st_nlink <= 1 {
                    let blockBytes = Int64(st.st_blocks) * 512
                    deletedBytes += max(0, blockBytes)
                }
                deletedCount += 1
            }
        }

        private static func posixError() -> NSError { NSError(domain: NSPOSIXErrorDomain, code: Int(errno)) }
    }
}
