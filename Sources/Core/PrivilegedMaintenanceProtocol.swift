import Foundation
import Security

@objc(ACleanPrivilegedMaintenanceProtocol) protocol PrivilegedMaintenanceProtocol {
    /// No caller-supplied paths, arguments or shell commands cross the privilege boundary.
    func perform(taskID: String, reply: @escaping @Sendable (Bool) -> Void)
}

enum MaintenanceSigning {
    static func currentTeam(identifier: String) -> String? {
        var code: SecCode?, staticCode: SecStaticCode?, information: CFDictionary?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code,
              SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode,
              SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &information) == errSecSuccess,
              let team = (information as? [String: Any])?[kSecCodeInfoTeamIdentifier as String] as? String,
              team.range(of: "^[A-Z0-9]{10}$", options: .regularExpression) != nil,
              let requirement = requirement(team: team, identifier: identifier) else { return nil }
        var parsed: SecRequirement?
        guard SecRequirementCreateWithString(requirement as CFString, [], &parsed) == errSecSuccess,
              SecCodeCheckValidity(code, [], parsed) == errSecSuccess else { return nil }
        return team
    }
    static func requirement(team: String, identifier: String) -> String? {
        guard team.range(of: "^[A-Z0-9]{10}$", options: .regularExpression) != nil,
              identifier.range(of: "^[A-Za-z0-9.-]+$", options: .regularExpression) != nil else { return nil }
        return "anchor apple generic and certificate leaf[subject.OU] = \"\(team)\" and identifier \"\(identifier)\""
    }
}
