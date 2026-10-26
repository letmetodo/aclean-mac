import Foundation
import Combine

protocol DirectoryFileSystemProviding: Sendable {
    func children(of url: URL, keys: Set<URLResourceKey>) throws -> [URL]
    func metadata(of url: URL, keys: Set<URLResourceKey>) throws -> URLResourceValues
    func measure(_ url: URL) -> FileSizeMeasurement
}

struct LocalDirectoryFileSystem: DirectoryFileSystemProviding {
    func children(of url: URL, keys: Set<URLResourceKey>) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: Array(keys))
    }
    func metadata(of url: URL, keys: Set<URLResourceKey>) throws -> URLResourceValues {
        try url.resourceValues(forKeys: keys)
    }
    func measure(_ url: URL) -> FileSizeMeasurement { FileUtil.measureSize(of: url) }
}

private struct DirectoryEntrySnapshot: Sendable {
    let url: URL
    let isDirectory: Bool
    let measurement: FileSizeMeasurement
    let protected: Bool
    let date: Date?
    let identity: FileIdentity?
}

private enum DirectoryListingSnapshot: Sendable {
    case entries([DirectoryEntrySnapshot], issues: [String])
    case failed(String, CleanupFailure?)
}

/// All filesystem work returns Sendable values; Node/AppKit projection stays on MainActor.
@MainActor
final class DirectoryChildrenRepository: ObservableObject {
    enum LoadState {
        case loading
        case loaded([Node])
        case incomplete(children: [Node], message: String)
        case failed(message: String, failureKind: CleanupFailure?)
    }

    static let shared = DirectoryChildrenRepository()
    private static let ioQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = AppConfig.Security.ioConcurrency
        return queue
    }()
    @Published private(set) var revision = 0
    private var states: [String: LoadState] = [:]
    private var pending: [String: StopFlag] = [:]
    private var accesses: [String: UInt64] = [:]
    private var accessCounter: UInt64 = 0
    private var generation = 0
    private let fileSystem: any DirectoryFileSystemProviding

    init(fileSystem: any DirectoryFileSystemProviding = LocalDirectoryFileSystem()) {
        self.fileSystem = fileSystem
    }

    func children(for url: URL) -> [Node] {
        touch(url.path)
        if let children = cached(forPath: url.path) { return children }
        if states[url.path] == nil { request(url) }
        return []
    }

    func cached(forPath path: String) -> [Node]? {
        touch(path)
        switch states[path] {
        case .loaded(let children), .incomplete(let children, _): return children
        default: return nil
        }
    }
    func state(forPath path: String) -> LoadState? { states[path] }
    func isLoading(forPath path: String) -> Bool { pending[path] != nil }
    func failure(forPath path: String) -> (message: String, failureKind: CleanupFailure?)? {
        switch states[path] {
        case .failed(let message, let kind): return (message, kind)
        case .incomplete(_, let message): return (message, nil)
        default: return nil
        }
    }
    func hasCompletedAttempt(forPath path: String) -> Bool {
        states[path] != nil && pending[path] == nil
    }
    func retry(_ url: URL) {
        pending.removeValue(forKey: url.path)?.value = true
        states.removeValue(forKey: url.path)
        request(url)
        revision += 1
    }
    func clear() {
        generation += 1
        pending.values.forEach { $0.value = true }
        pending.removeAll(); states.removeAll(); accesses.removeAll()
        revision += 1
    }
    /// Keep the selectable tree synchronized without retaining evicted dynamic subtrees forever.
    func reconcile(_ nodes: inout [Node]) {
        for index in nodes.indices {
            let path = nodes[index].path
            let cached: [Node]?
            switch states[path] {
            case .loaded(let children), .incomplete(let children, _): cached = children
            default: cached = nil
            }
            if nodes[index].directoryChildrenFromCache || nodes[index].children.isEmpty {
                if let cached {
                    nodes[index].children = cached
                    nodes[index].directoryChildrenFromCache = true
                } else if nodes[index].directoryChildrenFromCache {
                    nodes[index].children = []
                }
            }
            reconcile(&nodes[index].children)
        }
    }

    private func touch(_ path: String) {
        guard states[path] != nil || pending[path] != nil else { return }
        accessCounter &+= 1
        accesses[path] = accessCounter
    }
    private func trimCache(keeping path: String) {
        var retainedNodes = states.values.reduce(0) { total, state in
            switch state {
            case .loaded(let nodes), .incomplete(let nodes, _): return total + nodes.count
            default: return total
            }
        }
        for candidate in states.keys.sorted(by: { (accesses[$0] ?? 0) < (accesses[$1] ?? 0) }) {
            guard states.count > AppConfig.UI.directoryCacheEntryLimit || retainedNodes > AppConfig.UI.directoryCacheNodeLimit else { break }
            guard candidate != path, pending[candidate] == nil else { continue }
            if let nodes = cached(forPath: candidate) { retainedNodes -= nodes.count }
            states.removeValue(forKey: candidate); accesses.removeValue(forKey: candidate)
        }
        // The currently displayed listing may exceed the budget; never truncate user-visible entries.
    }
    private func request(_ url: URL) {
        guard pending[url.path] == nil else { return }
        let ruleTaskLease = RuleTaskGate.shared.begin()
        let flag = StopFlag(), run = generation, fs = fileSystem
        pending[url.path] = flag
        states[url.path] = .loading
        touch(url.path)
        Self.ioQueue.addOperation { [weak self] in
            guard !flag.value else { return }
            let context = IOScanContext(stopped: { flag.value })
            let result: DirectoryListingSnapshot = context.perform {
                if FileUtil.isTCCOrApplePrivateBlocked(url.path) {
                    return .failed(L10n.localized(.scanCoverageIncomplete) + ": " + url.path, .permission)
                }
                if JunkEngine.isCloudOrSyncProviderPath(url.path) || SymlinkGuard.hasSymlinkEscape(url: url) {
                    return .failed(L10n.localized(.cleanSkippedProtected) + ": " + url.path, nil)
                }
                let keys: Set<URLResourceKey> = [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey, .contentModificationDateKey]
                do {
                    let entries = try fs.children(of: url, keys: keys)
                    var snapshots: [DirectoryEntrySnapshot] = [], issues: [String] = []
                    snapshots.reserveCapacity(entries.count)
                    for child in entries {
                        guard !flag.value else { break }
                        do {
                            let values = try fs.metadata(of: child, keys: keys)
                            let measurement = fs.measure(child)
                            if !measurement.isComplete && issues.count < AppConfig.Security.scopeIssueLimit { issues.append(child.path + ": " + L10n.localized(.safetyInspectionIncomplete)) }
                            snapshots.append(DirectoryEntrySnapshot(url: child,
                                isDirectory: values.isDirectory == true && values.isPackage != true && values.isSymbolicLink != true,
                                measurement: measurement, protected: CleanupSafetyPolicy.isProtectedAsset(child),
                                date: values.contentModificationDate, identity: FileIdentity.capture(from: child)))
                        } catch {
                            IOScanContext.record(error, path: child.path)
                            if issues.count < AppConfig.Security.scopeIssueLimit { issues.append(child.path + ": " + error.localizedDescription) }
                        }
                    }
                    return .entries(snapshots.sorted { $0.measurement.bytes > $1.measurement.bytes }, issues: issues)
                } catch { return .failed(error.localizedDescription, CleanupFailure.classify(error)) }
            }
            DispatchQueue.main.async { [weak self] in
                defer { withExtendedLifetime(ruleTaskLease) {} }
                guard let self, self.generation == run, !flag.value, self.pending[url.path] === flag else { return }
                self.pending.removeValue(forKey: url.path)
                switch result {
                case .failed(let message, let kind): self.states[url.path] = .failed(message: message, failureKind: kind)
                case .entries(let entries, let issues):
                    let nodes = entries.map { entry in
                        var node = Node(id: Node.stableID(forPath: entry.url.path), name: entry.url.lastPathComponent,
                            url: entry.url, icon: entry.isDirectory ? "folder.fill" : Node.icon(for: entry.url),
                            safety: .caution, size: entry.measurement.bytes, isGroup: entry.isDirectory,
                            locked: entry.protected || !entry.measurement.isComplete, autoSelected: false,
                            date: entry.date, fileIdentity: entry.identity, captureIdentity: false)
                        node.measuredBytes = entry.measurement.bytes
                        return node
                    }
                    self.states[url.path] = issues.isEmpty ? .loaded(nodes) : .incomplete(children: nodes, message: issues.joined(separator: "\n"))
                }
                self.touch(url.path); self.trimCache(keeping: url.path)
                self.revision += 1
            }
        }
    }
}
