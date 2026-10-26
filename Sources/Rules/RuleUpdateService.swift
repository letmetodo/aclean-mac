import Foundation
import Combine

@MainActor
final class RuleUpdateService: ObservableObject {
    enum Status { case notConfigured, ready, checking, waiting, updated, failed, unavailable }
    static let shared = RuleUpdateService()
    @Published private(set) var status: Status = .notConfigured
    @Published private(set) var version = ""
    @Published private(set) var lastCheck = UserDefaults.standard.object(forKey: AppConfig.RuleUpdates.lastCheckKey) as? Date
    private var store: RulePackageStore?
    private var task: Task<Void, Never>?
    private var schedule: Task<Void, Never>?
    private var waiting = false
    private var waitingManual = false

    func bootstrap() {
        guard store == nil else { return }
        do {
            let store = try RuleUpdateConfiguration.store()
            self.store = store
            let summary = try store.bootstrap()
            RuleTaskGate.shared.updateRestrictions(disabled: store.trust.disabledRuleIDs, revoked: store.trust.revokedDatabaseHashes)
            let snapshot = try KnowledgeBaseManager.shared.prepare(from: store.databaseURL)
            try RuleTaskGate.shared.activate(version: summary.version, hash: summary.sha256) { KnowledgeBaseManager.shared.publish(snapshot) }
            version = snapshot.version
            status = AppConfig.RuleUpdates.baseURL == nil ? .notConfigured : .ready
        } catch { status = .unavailable }
        RuleTaskGate.shared.onIdle = { Task { @MainActor in RuleUpdateService.shared.checkWaiting() } }
    }
    func start() {
        guard schedule == nil else { return }
        check(manual: false)
        schedule = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(AppConfig.RuleUpdates.interval)) } catch { break }
                self?.check(manual: false)
            }
        }
    }
    func preferenceChanged() {
        if AppConfig.RuleUpdates.automaticEnabled { check(manual: false) }
        else { waiting = false; waitingManual = false; task?.cancel() }
    }
    private func checkWaiting() {
        guard waiting, task == nil, RuleTaskGate.shared.isIdle else { return }
        let manual = waitingManual; waiting = false; waitingManual = false
        check(manual: manual)
    }
    func check(manual: Bool) {
        guard task == nil, manual || AppConfig.RuleUpdates.automaticEnabled else { return }
        guard let base = AppConfig.RuleUpdates.baseURL, let store else {
            if status != .unavailable { status = .notConfigured }; return
        }
        status = .checking
        task = Task { [weak self] in
            guard let self else { return }
            do { try await update(base: base, store: store, manual: manual) }
            catch RuleUpdateFailure.busy { waiting = true; waitingManual = manual; status = .waiting }
            catch is CancellationError { status = RuleTaskGate.shared.allows(RuleTaskGate.shared.identity) ? .ready : .unavailable }
            catch { status = RuleTaskGate.shared.allows(RuleTaskGate.shared.identity) ? .failed : .unavailable }
            task = nil
            checkWaiting()
        }
    }
    private func update(base: URL, store: RulePackageStore, manual: Bool, retry: Int = 0) async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = AppConfig.RuleUpdates.requestTimeout
        configuration.timeoutIntervalForResource = AppConfig.RuleUpdates.resourceTimeout
        let http = RuleHTTPClient(origin: base, configuration: configuration)
        try Task.checkCancellation()
        let raw = try await http.fetch(AppConfig.RuleUpdates.manifestName, maximumBytes: AppConfig.RuleUpdates.metadataBytes)
        let release = try RuleManifestReader.parse(bytes: raw, limits: RuleUpdateConfiguration.limits)
        if let current = RuleTaskGate.shared.identity, release.manifest.ruleVersion < current.version {
            lastCheck = Date(); UserDefaults.standard.set(lastCheck, forKey: AppConfig.RuleUpdates.lastCheckKey)
            status = .ready; return
        }
        let previousTrust = store.trust
        try store.accept(release)
        RuleTaskGate.shared.updateRestrictions(disabled: store.trust.disabledRuleIDs, revoked: store.trust.revokedDatabaseHashes)
        if previousTrust.disabledRuleIDs != store.trust.disabledRuleIDs || previousTrust.revokedDatabaseHashes != store.trust.revokedDatabaseHashes {
            NotificationCenter.default.post(name: Notification.Name(AppConfig.RuleUpdates.changedNotification), object: nil)
        }
        lastCheck = Date(); UserDefaults.standard.set(lastCheck, forKey: AppConfig.RuleUpdates.lastCheckKey)
        let manifest = release.manifest
        if let hash = RuleTaskGate.shared.identity?.hash, store.trust.revokedDatabaseHashes.contains(hash) {
            guard RuleTaskGate.shared.isIdle else { waiting = true; waitingManual = manual; status = .waiting; return }
            try await RuleBackground.run {
                try RuleTaskGate.shared.recover {
                    let summary = try store.bootstrap()
                    let snapshot = try KnowledgeBaseManager.shared.prepare(from: store.databaseURL)
                    KnowledgeBaseManager.shared.publish(snapshot)
                    return (summary.version, summary.sha256)
                }
            }
            version = KnowledgeBaseManager.shared.version
            NotificationCenter.default.post(name: Notification.Name(AppConfig.RuleUpdates.changedNotification), object: nil)
        }
        guard !store.trust.revokedDatabaseHashes.contains(manifest.databaseSHA256) else { throw RuleUpdateFailure.revoked }
        if let current = RuleTaskGate.shared.identity, current.version >= manifest.ruleVersion { status = .ready; return }
        guard RuleTaskGate.shared.isIdle else { waiting = true; waitingManual = manual; status = .waiting; return }
        let bytes = try await http.fetch(AppConfig.RuleUpdates.databaseName, maximumBytes: AppConfig.RuleUpdates.databaseBytes)
        guard bytes.count == manifest.databaseBytes, RuleDigest.sha256(bytes) == manifest.databaseSHA256 else {
            if retry == 0 { return try await update(base: base, store: store, manual: manual, retry: 1) }
            throw RuleUpdateFailure.invalidDatabase
        }
        try Task.checkCancellation()
        guard RuleTaskGate.shared.isIdle else { waiting = true; waitingManual = manual; status = .waiting; return }
        let updated = try await RuleBackground.run { () -> Bool in
            try Task.checkCancellation()
            let candidate = try store.makeTemporary()
            defer { try? store.discardTemporary() }
            try bytes.write(to: candidate)
            _ = try store.validate(candidate)
            let snapshot = try KnowledgeBaseManager.shared.prepare(from: candidate)
            guard snapshot.authored.loaded, snapshot.authored.cacheRecommendationConfig.isAvailable,
                  snapshot.authored.disabledCacheProfileIDs.isEmpty else { throw RuleUpdateFailure.invalidDatabase }
            do {
                try RuleTaskGate.shared.activate(version: manifest.ruleVersion, hash: manifest.databaseSHA256) {
                    try Task.checkCancellation()
                    _ = try store.install(candidate, release: release)
                    KnowledgeBaseManager.shared.publish(snapshot)
                }
            } catch RuleUpdateFailure.busy { return false }
            return true
        }
        if updated {
            version = String(manifest.ruleVersion); status = .updated
            NotificationCenter.default.post(name: Notification.Name(AppConfig.RuleUpdates.changedNotification), object: nil)
        } else { waiting = true; waitingManual = manual; status = .waiting }
    }
    var statusText: String {
        switch status {
        case .notConfigured: return L10n.localized(.ruleUpdateNotConfigured)
        case .ready: return L10n.localized(.ruleUpdateReady)
        case .checking: return L10n.localized(.ruleUpdateChecking)
        case .waiting: return L10n.localized(.ruleUpdateWaiting)
        case .updated: return L10n.localized(.ruleUpdateUpdated)
        case .failed: return L10n.localized(.ruleUpdateFailed)
        case .unavailable: return L10n.localized(.ruleDatabaseUnavailableTitle)
        }
    }
}
