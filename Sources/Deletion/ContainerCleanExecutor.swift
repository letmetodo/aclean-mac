import Foundation
import Darwin

// ============================================================
//  ContainerCleanExecutor —— 受控容器清空执行器 (trash_children_only)
//
//  安全契约：
//    1. 根级门禁前置：绝不接收未经根级安全与身份核验的目标，仅消费 ContainerCleanCommand；
//    2. 子项严格复核：对容器下每一个直接子项独立执行 TOCTOU 物理校验、GitGuard、
//       FastDirectoryInspector 权限与安全评估；
//    3. 安全可逆与审计透明：逐项安全移入废纸篓（TrashMover），严禁 rm -rf，
//       聚合产出精确到子项的 CleanOutcome（成功、部分失败或全部失败）。
// ============================================================

enum ContainerCleanExecutor {

    /// 执行受控容器清空（仅移入直接子项至废纸篓，保留容器外壳目录本身）
    static func execute(
        _ command: ContainerCleanCommand,
        isDryRun: Bool = false
    ) -> CleanOutcome {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        let url = command.url
        let tName = command.targetName
        let tSize = command.targetSize
        let evidence = command.evidence
        let rule = command.rule
        let expected = command.expectedIdentity
        let requireCurrentUserUID = command.requireCurrentUserUID
        let executionMode = command.executionMode
        let store = KnowledgeBaseManager.shared.authored
        guard RuleTaskGate.shared.allows(evidence.ruleIdentity, ruleID: evidence.id) else {
            return CleanOutcome(name: tName, path: url.path, size: 0, ok: false,
                error: L10n.localized(.ruleUpdateRescanRequired), actionCategory: .skipped)
        }

        // 步骤 2（直接子项逐一移入废纸篓，保留外壳目录本身）：
        let directChildren: [URL]
        do {
            directChildren = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: []
            ).sorted { $0.standardizedFileURL.path < $1.standardizedFileURL.path }
        } catch {
            return CleanOutcome(
                name: tName,
                path: url.path,
                size: tSize,
                ok: false,
                error: error.localizedDescription,
                actionCategory: .failed,
                failureKind: CleanupFailure.classify(error)
            )
        }

        let verifiedChildByPath: [String: CleanTarget] = Dictionary(
            command.containerChildren.compactMap { child in
                guard let childURL = child.url else { return nil }
                return (childURL.standardizedFileURL.path, child)
            },
            uniquingKeysWith: { first, _ in first }
        )

        var movedBytes: Int64 = 0
        var movedCount: Int = 0
        var trashedURLs: [URL] = []
        var restoreItems: [CleanupRestoreItem] = []
        var removedSourcePaths = Set<String>()
        var failedChildren: [String] = []
        var failedChildDetails: [CleanChildFailure] = []
        let exemptTestCerts = AppConfig.RuleIDs.testCertificateExemptionRules.contains(evidence.id)

        func recordChildFailure(name: String, path: String, message: String, kind: CleanupFailure? = nil) {
            failedChildren.append("\(name): \(message)")
            failedChildDetails.append(CleanChildFailure(name: name, path: path, message: message, failureKind: kind))
        }

        let isLogContainer = AppConfig.RuleIDs.logRules.contains(evidence.id)
        var validatedChildrenToMove: [(url: URL, name: String, stdPath: String, bytes: Int64, identity: FileIdentity)] = []
        validatedChildrenToMove.reserveCapacity(directChildren.count)

        for childURL in directChildren {
            if !RuleTaskGate.shared.allows(evidence.ruleIdentity, ruleID: evidence.id) {
                recordChildFailure(name: tName, path: url.path, message: L10n.localized(.ruleUpdateRescanRequired))
                break
            }
            if IOScanContext.isCancelled {
                return CleanOutcome(
                    name: tName,
                    path: url.path,
                    size: movedBytes,
                    ok: false,
                    error: L10n.localized(.cleanupCancelledResult),
                    actionCategory: .cancelled,
                    destinationURL: trashedURLs.first,
                    trashedURLs: trashedURLs,
                    failedChildren: failedChildren,
                    failedChildDetails: failedChildDetails,
                    movedToTrashBytes: movedBytes,
                    removedSourcePaths: removedSourcePaths,
                    restoreItems: restoreItems
                )
            }
            let childName = childURL.lastPathComponent
            if childName == ".DS_Store"
                || rule.excludedNames.contains(childName.lowercased())
                || store.isExcluded(childURL, by: rule) {
                continue
            }
            let childStdPath = childURL.standardizedFileURL.path
            if let retryPaths = command.retryChildPaths, !retryPaths.contains(childStdPath) {
                continue
            }
            let verifiedChild = verifiedChildByPath[childStdPath]
            if verifiedChild == nil {
                if !isLogContainer && command.retryChildPaths == nil {
                    return CleanOutcome(
                        name: tName,
                        path: url.path,
                        size: tSize,
                        ok: false,
                        error: L10n.localized(.cleanupFileChanged),
                        actionCategory: .skipped
                    )
                }
                continue
            }
            if let verifiedChild, verifiedChild.locked {
                if !isLogContainer {
                    return CleanOutcome(
                        name: tName,
                        path: url.path,
                        size: tSize,
                        ok: false,
                        error: L10n.localized(.cleanSkippedProtected),
                        actionCategory: .skipped
                    )
                }
                recordChildFailure(name: childName, path: childStdPath, message: L10n.localized(.cleanSkippedProtected))
                continue
            }
            if executionMode == .automatic,
               let verifiedChild,
               (verifiedChild.ruleEvidence?.tier != .automatic || verifiedChild.ruleEvidence?.defaultSelected != true) {
                if !isLogContainer {
                    return CleanOutcome(
                        name: tName,
                        path: url.path,
                        size: tSize,
                        ok: false,
                        error: L10n.localized(.cleanSkippedProtected),
                        actionCategory: .skipped
                    )
                }
                recordChildFailure(name: childName, path: childStdPath, message: L10n.localized(.cleanSkippedProtected))
                continue
            }

            var childStat = stat()
            guard lstat(childURL.path, &childStat) == 0 else {
                let err = NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
                let kind = CleanupFailure.classify(err)
                if kind != .missing {
                    if !isLogContainer {
                        return CleanOutcome(
                            name: tName,
                            path: url.path,
                            size: tSize,
                            ok: false,
                            error: err.localizedDescription,
                            actionCategory: .failed,
                            failureKind: kind
                        )
                    }
                    recordChildFailure(name: childName, path: childStdPath, message: err.localizedDescription, kind: kind)
                }
                continue
            }
            guard let childIdentity = FileIdentity.capture(from: childURL),
                  !SymlinkGuard.hasSymlinkEscape(url: childURL) else {
                if !isLogContainer {
                    return CleanOutcome(
                        name: tName,
                        path: url.path,
                        size: tSize,
                        ok: false,
                        error: L10n.localized(.cleanupFileChanged),
                        actionCategory: .skipped
                    )
                }
                recordChildFailure(name: childName, path: childStdPath, message: L10n.localized(.cleanupFileChanged))
                continue
            }
            if let expectedChildIdentity = verifiedChild?.expectedIdentity,
               expectedChildIdentity != childIdentity {
                if !isLogContainer {
                    return CleanOutcome(
                        name: tName,
                        path: url.path,
                        size: tSize,
                        ok: false,
                        error: L10n.localized(.cleanupFileChanged),
                        actionCategory: .skipped
                    )
                }
                recordChildFailure(name: childName, path: childStdPath, message: L10n.localized(.cleanupFileChanged))
                continue
            }
            if AppConfigStore.shared.isPathIgnoredForDeletion(childStdPath)
                || CleanupSafetyPolicy.isProtectedAsset(childURL)
                || GitGuard.isSensitiveFilename(childName, exemptTestCertExtensions: exemptTestCerts)
                || childName == ".git"
                || GitGuard.hasGitTrackedFiles(url: childURL) {
                if !isLogContainer {
                    return CleanOutcome(
                        name: tName,
                        path: url.path,
                        size: tSize,
                        ok: false,
                        error: L10n.localized(.cleanSkippedProtected),
                        actionCategory: .skipped
                    )
                }
                recordChildFailure(name: childName, path: childStdPath, message: L10n.localized(.cleanSkippedProtected))
                continue
            }

            let fastChildInspection = FastDirectoryInspector.inspect(
                childURL,
                identity: childIdentity,
                parentRuleID: evidence.id,
                parentTier: evidence.tier,
                requireCurrentUserUID: requireCurrentUserUID,
                measurePhysicalBytes: true,
                forExecution: true
            )
            guard fastChildInspection.measurementComplete,
                  fastChildInspection.safetyInspection.isSafe,
                  (!requireCurrentUserUID || fastChildInspection.allCurrentUserOwned),
                  (executionMode != .automatic || !fastChildInspection.safetyInspection.downgradeAutomaticToReview) else {
                let failureKind: CleanupFailure? = (!fastChildInspection.measurementComplete && access(childURL.path, R_OK | X_OK) != 0 && (errno == EACCES || errno == EPERM))
                    ? .permission
                    : nil
                if !isLogContainer {
                    return CleanOutcome(
                        name: tName,
                        path: url.path,
                        size: tSize,
                        ok: false,
                        error: L10n.localized(.cleanSkippedProtected),
                        actionCategory: .skipped,
                        failureKind: failureKind
                    )
                }
                recordChildFailure(name: childName, path: childStdPath, message: L10n.localized(.cleanSkippedProtected), kind: failureKind)
                continue
            }

            let childBytes = max(verifiedChild?.size ?? 0, fastChildInspection.physicalBytes)
            validatedChildrenToMove.append((childURL, childName, childStdPath, childBytes, childIdentity))
        }

        if executionMode == .automatic && command.authorizationContext == .junkRule {
            let unitTotalBytes = FastDirectoryInspector.allocatedBytesOverrideForTesting?(url.path)
                ?? FastDirectoryInspector.allocatedBytesOverrideForTesting?(SymlinkGuard.canonicalizeMacOSSystemPrefix(url.path))
                ?? validatedChildrenToMove.reduce(Int64(0)) { $0 + $1.bytes }
            let freshContainerRec = JunkCacheRecommendationPolicy.evaluate(
                url: url,
                unitURL: url,
                unitIdentity: expected,
                ruleEvidence: command.runtimeStoreEvidence ?? evidence,
                allocatedBytes: unitTotalBytes,
                safetyGatePassed: true,
                store: store
            )
            if !freshContainerRec.automaticAllowed
                || freshContainerRec.state == .suggestedLarge
                || freshContainerRec.state == .blocked {
                return CleanOutcome(
                    name: tName,
                    path: url.path,
                    size: tSize,
                    ok: false,
                    error: L10n.localized(.cleanSkippedProtected),
                    actionCategory: .skipped
                )
            }
        }

        for validChild in validatedChildrenToMove {
            if !RuleTaskGate.shared.allows(evidence.ruleIdentity, ruleID: evidence.id) {
                recordChildFailure(name: tName, path: url.path, message: L10n.localized(.ruleUpdateRescanRequired))
                break
            }
            if IOScanContext.isCancelled {
                return CleanOutcome(
                    name: tName,
                    path: url.path,
                    size: movedBytes,
                    ok: false,
                    error: L10n.localized(.cleanupCancelledResult),
                    actionCategory: .cancelled,
                    destinationURL: trashedURLs.first,
                    trashedURLs: trashedURLs,
                    failedChildren: failedChildren,
                    failedChildDetails: failedChildDetails,
                    movedToTrashBytes: movedBytes,
                    removedSourcePaths: removedSourcePaths,
                    restoreItems: restoreItems
                )
            }
            guard validChild.identity.matches(url: validChild.url),
                  !SymlinkGuard.hasSymlinkEscape(url: validChild.url) else {
                recordChildFailure(name: validChild.name, path: validChild.stdPath, message: L10n.localized(.cleanupFileChanged))
                continue
            }
            if isDryRun {
                movedBytes += validChild.bytes
                movedCount += 1
                removedSourcePaths.insert(validChild.url.path)
                continue
            }

            do {
                let destination = try TrashMover.trash(validChild.url)
                movedBytes += validChild.bytes
                movedCount += 1
                removedSourcePaths.insert(validChild.url.path)
                if let destination {
                    trashedURLs.append(destination)
                    restoreItems.append(CleanupRestoreItem(originalURL: validChild.url, trashURL: destination, bytes: validChild.bytes))
                }
            } catch {
                recordChildFailure(
                    name: validChild.name,
                    path: validChild.stdPath,
                    message: error.localizedDescription,
                    kind: CleanupFailure.classify(error)
                )
            }
        }

        let aggregatedFailureKind: CleanupFailure? = {
            if failedChildDetails.contains(where: { $0.failureKind == .permission }) {
                return .permission
            }
            return failedChildDetails.compactMap(\.failureKind).first
        }()

        // 步骤 3（部分失败回执）：如实汇总成功移入废纸篓字节数与失败子项明细，绝不静默吞错、绝不回退 rm -rf
        if failedChildren.isEmpty {
            return CleanOutcome(
                name: tName,
                path: url.path,
                size: movedBytes,
                ok: true,
                actionCategory: .movedToTrash,
                destinationURL: trashedURLs.first,
                trashedURLs: trashedURLs,
                movedToTrashBytes: movedBytes,
                removedSourcePaths: removedSourcePaths,
                    restoreItems: restoreItems
            )
        } else if movedCount > 0 {
            return CleanOutcome(
                name: tName,
                path: url.path,
                size: movedBytes,
                ok: false,
                error: failedChildren.joined(separator: "; "),
                actionCategory: .partialFailure,
                destinationURL: trashedURLs.first,
                trashedURLs: trashedURLs,
                failedChildren: failedChildren,
                failedChildDetails: failedChildDetails,
                failureKind: aggregatedFailureKind,
                movedToTrashBytes: movedBytes,
                removedSourcePaths: removedSourcePaths,
                    restoreItems: restoreItems
            )
        } else {
            return CleanOutcome(
                name: tName,
                path: url.path,
                size: 0,
                ok: false,
                error: failedChildren.joined(separator: "; "),
                actionCategory: .failed,
                failedChildren: failedChildren,
                failedChildDetails: failedChildDetails,
                failureKind: aggregatedFailureKind
            )
        }
    }
}
