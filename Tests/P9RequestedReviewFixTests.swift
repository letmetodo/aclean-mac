import Foundation
import Darwin

extension P9CrossReviewFixTests {
    func requestedReviewFixRegressions() throws {
        let published = URL(fileURLWithPath: ProcessInfo.processInfo.environment["ACLEAN_RULES_DB"]!)
        try KnowledgeBaseManager.shared.load(from: published)
        let config = AppConfigStore.shared
        let previousIgnored = config.currentIgnoredPathsSnapshot()
        let previousDryRun = Cleaner.isDryRun
        let previousRoots = Cleaner.authorizedTrashRootsOverride
        let previousOpenPaths = OpenFileGuard.openPathsOverrideForTesting
        let previousHome = FileUtil.homeOverrideForTesting
        let previousLanguage = L10n.shared.language
        defer {
            config.setIgnoredPaths(previousIgnored)
            Cleaner.isDryRun = previousDryRun
            Cleaner.authorizedTrashRootsOverride = previousRoots
            OpenFileGuard.openPathsOverrideForTesting = previousOpenPaths
            FileUtil.homeOverrideForTesting = previousHome
            L10n.shared.language = previousLanguage
        }
        OpenFileGuard.openPathsOverrideForTesting = []

        // Real names and production whitelist/deletion gates, including a trailing newline.
        for name in ["keep ", "keep\n", "keep\t"] {
            let child = try file("requested-review/\(name)/data.txt")
            let directory = child.deletingLastPathComponent()
            config.setIgnoredPaths([directory.path])
            check((AppConfigStore.canonicalPath(directory.path) as NSString).lastPathComponent == name,
                  "Requested review: normalization preserves legal filename whitespace")
            check(config.isPathIgnoredForDisplay(child.path)
                  && config.isPathIgnoredForDeletion(child.path)
                  && config.isPathIgnoredForDeletion(directory.deletingLastPathComponent().path),
                  "Requested review: whitelist protects descendants and covering ancestors")
            check(!config.isPathIgnoredForDeletion(directory.path + "-sibling/data.txt"),
                  "Requested review: whitelist respects component boundaries")
            Cleaner.isDryRun = false
            let blocked = Cleaner.clean(CleanTarget(name: child.lastPathComponent, url: child,
                                                    size: 4096, action: .trash))
            check(!blocked.ok && blocked.actionCategory == .skipped && fm.fileExists(atPath: child.path),
                  "Requested review: Cleaner preserves the actual whitelisted file")
        }
        config.setIgnoredPaths([])

        // Real descriptor deletion in an isolated authorized trash fixture, never system Trash.
        let regular = try file("requested-trash/folder/data.bin", data: Data(repeating: 1, count: 8192))
        let external = try file("requested-external/shared.bin", data: Data(repeating: 2, count: 8192))
        let folder = regular.deletingLastPathComponent()
        try fm.linkItem(at: external, to: folder.appendingPathComponent("shared.bin"))
        var regularStat = stat()
        check(lstat(regular.path, &regularStat) == 0, "Requested review: real file allocation is readable")
        let allocated = Int64(regularStat.st_blocks) * 512
        check(allocated > 0, "Requested review: accounting fixture occupies physical blocks")
        Cleaner.authorizedTrashRootsOverride = [folder.deletingLastPathComponent()]
        let target = CleanTarget(name: "folder", url: folder, size: 1, action: .permanentlyDeleteTrashItem)
        Cleaner.isDryRun = true
        check(Cleaner.clean(target).size == 1,
              "Requested review: directory link count does not zero the dry-run directory estimate")
        Cleaner.isDryRun = false
        let removed = Cleaner.clean(target)
        check(removed.ok && removed.size == allocated && removed.permanentlyDeletedBytes == allocated,
              "Requested review: successful deletion reports actual unique allocation, not stale target size")
        check(!fm.fileExists(atPath: folder.path) && fm.fileExists(atPath: external.path),
              "Requested review: directory is deleted while an external hard link survives")

        let linked = try file("requested-trash/linked.bin", data: Data(repeating: 3, count: 4096))
        let keeper = base.appendingPathComponent("requested-external/keeper.bin")
        try fm.linkItem(at: linked, to: keeper)
        let linkedOutcome = Cleaner.clean(CleanTarget(name: "linked", url: linked, size: 4096,
                                                    action: .permanentlyDeleteTrashItem))
        check(linkedOutcome.ok && linkedOutcome.permanentlyDeletedBytes == 0
              && !fm.fileExists(atPath: linked.path) && fm.fileExists(atPath: keeper.path),
              "Requested review: deleting one hard link does not report freed allocation")

        // Inject only OS boundaries; exercise the real executor's command-result decisions.
        for code: Int32 in [1, -2] {
            var reads = 0
            let operations = SystemReclaimExecutor.APFSOperations(capacity: {
                reads += 1
                return reads == 1 ? (100, 100) : (8192, 16384)
            }, run: { ShellResult(stdout: "", stderr: "fixture failure", exitCode: code) })
            let result = SystemReclaimExecutor.execute(.apfsPurge(name: "fixture", estimatedBytes: 999),
                                                       apfsOperations: operations)
            check(!result.ok && result.actionCategory == .failed && result.size == 0
                  && result.error == "fixture failure",
                  "Requested review: failed/cancelled APFS command stays failed despite free-space growth")
        }
        let noErrorText = SystemReclaimExecutor.APFSOperations(capacity: { (100, 100) }, run: {
            ShellResult(stdout: "", stderr: "", exitCode: 1)
        })
        check(SystemReclaimExecutor.execute(.apfsPurge(name: "fixture", estimatedBytes: 999),
                                            apfsOperations: noErrorText).error == L10n.localized(.failedToReclaimApfsPurgeableSpace),
              "Requested review: APFS failure without diagnostics uses localized fallback")
        var successReads = 0
        let success = SystemReclaimExecutor.APFSOperations(capacity: {
            successReads += 1
            return successReads == 1 ? (100, 100) : (200, 200)
        }, run: { ShellResult(stdout: "", stderr: "", exitCode: 0) })
        let successOutcome = SystemReclaimExecutor.execute(.apfsPurge(name: "fixture", estimatedBytes: 999),
                                                           apfsOperations: success)
        check(successOutcome.ok && successOutcome.size == 100,
              "Requested review: successful APFS command retains observed capacity accounting")

        // The actual Downloads scanner produces localized groups from real files in a fake home.
        let fakeHome = base.appendingPathComponent("requested-home")
        _ = try file("requested-home/Downloads/report.pdf")
        _ = try file("requested-home/Downloads/unknown.xyz")
        FileUtil.homeOverrideForTesting = fakeHome
        let categoryKeys: [L10nKey] = [.downloadKindDocuments, .downloadKindImages, .downloadKindVideos,
            .downloadKindAudio, .downloadKindArchives, .downloadKindInstallers, .downloadKindApplications,
            .downloadFilesCategoryNoteFormat, .projectBuildArtifactNoteFormat, .projectToolchainFrontend,
            .projectToolchainRust, .projectToolchainNative, .projectToolchainJava, .projectToolchainPython,
            .projectToolchainApple, .projectToolchainDart, .projectToolchainGeneric]
        for language in AppLanguage.concreteLanguages {
            L10n.shared.language = language
            for key in categoryKeys {
                check(LocalizationCatalog.entries[key] != nil
                      && !LocalizationCatalog.text(for: key, lang: language).isEmpty,
                      "Requested review: each new key has an explicit translation in every supported language")
            }
            let groups = DownloadsEngine.leftoverFiles()
            let title = L10n.localized(.downloadKindDocuments)
            check(groups.contains { $0.title == L10n.format(.downloadsCategoryPrefixFormat, title)
                && $0.note == L10n.format(.downloadFilesCategoryNoteFormat, title)
                && $0.items.first?.note == title },
                "Requested review: Downloads scanner localizes category, group title and note")
            check(groups.contains { $0.items.first?.name == "unknown.xyz"
                && $0.items.first?.note == L10n.localized(.other) },
                "Requested review: unknown download extensions use the localized fallback")
            check(ProjectPurgeEngine.toolchainCategory(for: "venv") == L10n.localized(.projectToolchainPython),
                  "Requested review: production toolchain labels follow the active language")
            let artifact = L10n.format(.projectBuildArtifactNoteFormat, "TOOL", "PATH")
            check(artifact.contains("TOOL") && artifact.contains("PATH") && !artifact.contains("%@"),
                  "Requested review: both artifact-note placeholders format correctly in all languages")
        }
    }
}
