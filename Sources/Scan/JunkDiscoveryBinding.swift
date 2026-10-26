import Foundation
import Darwin

enum DiscoveryStatus: String, Sendable {
    case active
    case inventoryOnly = "inventory_only"
    case deferred
    case rejected
}

enum DiscoveryKind: String, Sendable {
    case fixedPath = "fixed_path"
    case wildcardChild = "wildcard_child"
    case profileLeaves = "profile_leaves"
    case bundlePredicate = "bundle_predicate"
    case systemTemp = "system_temp"
    case explicitNotSupported = "explicit_not_supported"
}

enum DiscoveryRunState: String, Sendable {
    case found
    case absent
    case permissionDenied = "permission_denied"
    case runningLocked = "running_locked"
    case incomplete
}

struct JunkDiscoveryBinding: Sendable, Equatable {
    let ruleID: String
    let pathTemplate: String
    let scannerID: String
    let discoveryKind: DiscoveryKind
    let status: DiscoveryStatus
    let reason: String?
}

struct DiscoveryRunRecord: Sendable, Equatable {
    let ruleID: String
    let pathTemplate: String
    let scannerID: String
    let state: DiscoveryRunState
    let detail: String?
}

final class JunkDiscoveryRegistry: @unchecked Sendable {
    static let shared = JunkDiscoveryRegistry()

    private let lock = NSLock()
    private var runRecords: [String: DiscoveryRunRecord] = [:]

    static func bindingKey(ruleID: String, pathTemplate: String) -> String {
        "\(ruleID)::\(pathTemplate)"
    }

    var allBindings: [JunkDiscoveryBinding] { KnowledgeBaseManager.shared.authored.catalog.bindings }
    var bindingsByKey: [String: JunkDiscoveryBinding] {
        Dictionary(uniqueKeysWithValues: allBindings.map { (Self.bindingKey(ruleID: $0.ruleID, pathTemplate: $0.pathTemplate), $0) })
    }
    private init() {}
    func binding(ruleID: String, pathTemplate: String) -> JunkDiscoveryBinding? {
        KnowledgeBaseManager.shared.authored.catalog.binding(ruleID: ruleID, path: pathTemplate)
    }

    func bindings(forRuleID ruleID: String) -> [JunkDiscoveryBinding] {
        allBindings.filter { $0.ruleID == ruleID }
    }

    /// 审计规则库全量 `cm_junk_rule` 与 `cm_junk_rule_path` 是否 100% 具备路径级显式发现绑定。
    /// 返回所有缺失或违反契约的审计错误描述；为空数组表示 100% 合规。
    func auditCoverage(rules: [String: AuthoredJunkRule] = KnowledgeBaseManager.shared.authored.junk) -> [String] {
        var issues: [String] = []
        for (ruleID, rule) in rules.sorted(by: { $0.key < $1.key }) {
            if rule.paths.isEmpty {
                guard let b = binding(ruleID: ruleID, pathTemplate: "") else {
                    issues.append("Missing rule-level discovery binding for \(ruleID) (no path_template)")
                    continue
                }
                validateBindingContract(b, rule: rule, issues: &issues)
            } else {
                for pathTemplate in rule.paths {
                    guard let b = binding(ruleID: ruleID, pathTemplate: pathTemplate) else {
                        issues.append("Missing path-level discovery binding for (\(ruleID), \(pathTemplate))")
                        continue
                    }
                    validateBindingContract(b, rule: rule, issues: &issues)
                }
            }
        }
        return issues
    }

    private func validateBindingContract(
        _ b: JunkDiscoveryBinding,
        rule: AuthoredJunkRule,
        issues: inout [String]
    ) {
        if rule.tier == .forbidden {
            if b.status != .rejected && b.status != .deferred {
                issues.append("Forbidden rule (\(b.ruleID), \(b.pathTemplate)) must be rejected or deferred, got \(b.status.rawValue)")
            }
            if (b.reason ?? "").isEmpty {
                issues.append("Non-active binding (\(b.ruleID), \(b.pathTemplate)) missing reason")
            }
        } else if rule.tier == .readOnly || rule.action == "read_only" {
            if b.status != .inventoryOnly && b.status != .deferred {
                issues.append("ReadOnly rule (\(b.ruleID), \(b.pathTemplate)) must be inventory_only or deferred, got \(b.status.rawValue)")
            }
            if (b.reason ?? "").isEmpty {
                issues.append("ReadOnly binding (\(b.ruleID), \(b.pathTemplate)) missing reason")
            }
        } else if !rule.active {
            if b.status == .active {
                issues.append("Inactive rule (\(b.ruleID), \(b.pathTemplate)) cannot have active discovery status")
            }
        } else {
            if b.status != .active && (b.reason ?? "").isEmpty {
                issues.append("Active rule (\(b.ruleID), \(b.pathTemplate)) downgraded to \(b.status.rawValue) without reason")
            }
        }
    }

    func resetRunRecords() {
        lock.lock()
        runRecords.removeAll()
        lock.unlock()
    }

    func recordRunState(
        ruleID: String,
        pathTemplate: String,
        scannerID: String,
        state: DiscoveryRunState,
        detail: String? = nil
    ) {
        let key = Self.bindingKey(ruleID: ruleID, pathTemplate: pathTemplate)
        let record = DiscoveryRunRecord(
            ruleID: ruleID,
            pathTemplate: pathTemplate,
            scannerID: scannerID,
            state: state,
            detail: detail
        )
        lock.lock()
        runRecords[key] = record
        lock.unlock()
    }

    func recordedState(ruleID: String, pathTemplate: String) -> DiscoveryRunRecord? {
        let key = Self.bindingKey(ruleID: ruleID, pathTemplate: pathTemplate)
        lock.lock()
        defer { lock.unlock() }
        return runRecords[key]
    }

    func allRecordedStates() -> [DiscoveryRunRecord] {
        lock.lock()
        defer { lock.unlock() }
        return Array(runRecords.values)
    }

    /// 评估目录发现运行态：区分 `found`、`absent`、`permissionDenied`、`runningLocked`、`incomplete`，严禁将权限拒绝或进程锁定静默吞为普通空目录。
    @discardableResult
    func evaluateAndRecordDirectoryState(
        at url: URL,
        ruleID: String,
        pathTemplate: String,
        scannerID: String,
        fm: FileManager = .default
    ) -> DiscoveryRunState {
        let path = url.path
        if KnowledgeBaseManager.shared.authored.isRuleLockedByRunningApp(ruleID, url: url) {
            recordRunState(ruleID: ruleID, pathTemplate: pathTemplate, scannerID: scannerID, state: .runningLocked, detail: "Rule locked by running application")
            return .runningLocked
        }
        var st = stat()
        if lstat(path, &st) != 0 {
            let err = errno
            if err == EACCES || err == EPERM {
                recordRunState(ruleID: ruleID, pathTemplate: pathTemplate, scannerID: scannerID, state: .permissionDenied, detail: "lstat failed with errno \(err)")
                return .permissionDenied
            }
            recordRunState(ruleID: ruleID, pathTemplate: pathTemplate, scannerID: scannerID, state: .absent)
            return .absent
        }
        if !OpenFileGuard.isIdle(url, fresh: false) {
            recordRunState(ruleID: ruleID, pathTemplate: pathTemplate, scannerID: scannerID, state: .runningLocked, detail: "Open file handle or handle inspection failure")
            return .runningLocked
        }
        let isDir = (st.st_mode & S_IFMT) == S_IFDIR
        if isDir {
            do {
                _ = try fm.contentsOfDirectory(atPath: path)
            } catch let nsError as NSError {
                if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileReadNoPermissionError
                    || nsError.domain == NSPOSIXErrorDomain && (nsError.code == Int(EACCES) || nsError.code == Int(EPERM)) {
                    recordRunState(ruleID: ruleID, pathTemplate: pathTemplate, scannerID: scannerID, state: .permissionDenied, detail: nsError.localizedDescription)
                    return .permissionDenied
                }
                recordRunState(ruleID: ruleID, pathTemplate: pathTemplate, scannerID: scannerID, state: .incomplete, detail: nsError.localizedDescription)
                return .incomplete
            }
        }
        recordRunState(ruleID: ruleID, pathTemplate: pathTemplate, scannerID: scannerID, state: .found)
        return .found
    }

}
