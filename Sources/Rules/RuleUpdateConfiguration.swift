import Foundation

enum RuleUpdateConfiguration {
    static var limits: RuleUpdateLimits {
        RuleUpdateLimits(metadataBytes: AppConfig.RuleUpdates.metadataBytes, databaseBytes: AppConfig.RuleUpdates.databaseBytes,
                         jsonDepth: AppConfig.RuleUpdates.jsonDepth, databaseName: AppConfig.RuleUpdates.databaseName,
                         maximumRecords: AppConfig.RuleUpdates.maximumRecords, maximumStringBytes: AppConfig.RuleUpdates.maximumStringBytes,
                         queryInstructions: AppConfig.RuleUpdates.queryInstructions)
    }
    static func store() throws -> RulePackageStore {
        guard let sql = Bundle.main.url(forResource: AppConfig.RuleUpdates.sqlResource, withExtension: "sql"),
              let safety = Bundle.main.url(forResource: AppConfig.RuleUpdates.safetyResource, withExtension: "json") else {
            throw RuleUpdateFailure.invalidDatabase
        }
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return try RulePackageStore(directory: support.appendingPathComponent(AppConfig.RuleUpdates.directory),
                                    names: RuleStoreNames(database: AppConfig.RuleUpdates.databaseName, state: AppConfig.RuleUpdates.stateName,
                                                          temporaryPrefix: AppConfig.RuleUpdates.temporaryPrefix),
                                    seedSQL: String(contentsOf: sql, encoding: .utf8), safety: Data(contentsOf: safety),
                                    limits: limits)
    }
}
