import Foundation

// ============================================================
//  VerifiedCleanCommand —— 强类型安全审核指令
//
//  核心不可变量 (Invariants):
//    1. 门禁与执行绝对分离：所有清理指令必须首先经过 Cleaner 统一门禁
//       (取消标志、授权上下文、锁定检查、红线动作过滤、TOCTOU身份复核、
//        运行时规则二次审计、进程锁与风控矩阵校验)；
//    2. 只有通过全部门禁的指令才能被实例化为 VerifiedCleanCommand；
//    3. 执行器严格只接收 VerifiedCleanCommand，杜绝接收松散的原始 CleanTarget。
// ============================================================

enum VerifiedCleanCommand: Sendable {
    /// 系统级资源与虚拟空间回收指令
    case systemReclaim(SystemReclaimCommand)

    /// 受控容器仅清空子项指令
    case emptyContainer(ContainerCleanCommand)
}

/// 系统级空间/资源回收指令 (已完成前置参数规格化与互斥检查)
enum SystemReclaimCommand: Sendable, Equatable {
    /// APFS 本地快照与可清除空间释放
    case apfsPurge(name: String, estimatedBytes: Int64)

    /// Docker 构建缓存释放
    case dockerPrune(name: String, endpoint: DockerEndpoint?, estimatedBytes: Int64)

    /// Xcode 模拟器运行时专用删除 (已通过非空及运行态互斥校验)
    case simctlRuntimeDelete(name: String, identifier: String, size: Int64)

    /// Xcode 不可用模拟器设备容器清理 (xcrun simctl delete unavailable)
    case simctlDeleteUnavailable(name: String, size: Int64)
}

/// 受控容器仅清空子项强类型指令（已完成根级门禁、运行时证据与风控矩阵审计）
struct ContainerCleanCommand: Sendable {
    let targetName: String
    let url: URL
    let targetSize: Int64
    let measuredBytes: Int64
    let expectedIdentity: FileIdentity
    let rule: AuthoredJunkRule
    let evidence: CleanupRuleEvidence
    let runtimeStoreEvidence: CleanupRuleEvidence?
    let requireCurrentUserUID: Bool
    let executionMode: CleanExecutionMode
    let authorizationContext: CleanAuthorizationContext
    let containerChildren: [CleanTarget]
    let retryChildPaths: Set<String>?
}
