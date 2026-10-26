import Foundation
import ServiceManagement

/// Ordinary scans never register or start a privileged service.
enum PrivilegedMaintenanceClient {
    @MainActor static func register() throws {
        guard MaintenanceSigning.currentTeam(identifier: AppConfig.PrivilegedHelper.clientIdentifier) != nil else {
            throw CocoaError(.executableNotLoadable)
        }
        try SMAppService.daemon(plistName: AppConfig.PrivilegedHelper.plistName).register()
        SMAppService.openSystemSettingsLoginItems()
    }
    static var isEnabled: Bool {
        MaintenanceSigning.currentTeam(identifier: AppConfig.PrivilegedHelper.clientIdentifier) != nil
            && SMAppService.daemon(plistName: AppConfig.PrivilegedHelper.plistName).status == .enabled
    }
    static func run(_ taskID: String) -> Bool {
        guard !Thread.isMainThread,
              AppConfig.PrivilegedHelper.commands[taskID] != nil || AppConfig.PrivilegedHelper.fanTaskModes.contains(taskID),
              let team = MaintenanceSigning.currentTeam(identifier: AppConfig.PrivilegedHelper.clientIdentifier),
              let requirement = MaintenanceSigning.requirement(team: team, identifier: AppConfig.PrivilegedHelper.service),
              SMAppService.daemon(plistName: AppConfig.PrivilegedHelper.plistName).status == .enabled else { return false }
        let connection = NSXPCConnection(machServiceName: AppConfig.PrivilegedHelper.service, options: .privileged)
        connection.setCodeSigningRequirement(requirement)
        connection.remoteObjectInterface = NSXPCInterface(with: PrivilegedMaintenanceProtocol.self)
        let finished = DispatchSemaphore(value: 0), result = LockedValue(false)
        connection.invalidationHandler = { finished.signal() }
        connection.interruptionHandler = { finished.signal() }
        connection.resume()
        defer { connection.invalidate() }
        guard let proxy = connection.remoteObjectProxyWithErrorHandler({ _ in finished.signal() }) as? PrivilegedMaintenanceProtocol else { return false }
        proxy.perform(taskID: taskID) { ok in result.withValue { $0 = ok }; finished.signal() }
        let deadline = ProcessInfo.processInfo.systemUptime + (taskID.hasPrefix("fan.") ? AppConfig.PrivilegedHelper.fanRequestTimeout : AppConfig.PrivilegedHelper.timeout)
        repeat {
            if finished.wait(timeout: .now() + AppConfig.PrivilegedHelper.pollInterval) == .success { return result.withValue { $0 } }
        } while !IOScanContext.isCancelled && ProcessInfo.processInfo.systemUptime < deadline
        return false
    }
}
