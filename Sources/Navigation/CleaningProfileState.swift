import Foundation

/// One immutable value keeps the dropdown and its primary label consistent.
/// AppState owns the active projection; ModuleSession stores it while inactive.
struct CleaningProfileState: Equatable, Sendable {
    let profiles: Set<CleaningProfile>

    init(profile: CleaningProfile = .safeDaily, profiles: Set<CleaningProfile>? = nil) {
        self.profiles = (profiles ?? (profile == .custom ? [] : [profile]))
            .subtracting([.custom])
    }

    var primary: CleaningProfile {
        if profiles.contains(.maxSpace) { return .maxSpace }
        if profiles.contains(.devPro) { return .devPro }
        return profiles.contains(.safeDaily) ? .safeDaily : .custom
    }
}
