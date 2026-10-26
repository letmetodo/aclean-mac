import Foundation

extension AppConfig {
    enum RuleIDs {
        static let bundleInteriorProtectionPaths: Set<String> = [".app/", ".lproj"]
        static let logRules: Set<String> = ["JC.LOG.USER", "JC.LOG.DIAG.USER", "JC.DEV.NPM.LOGS"]
        static let electronCache = "JC.ELECTRON.CACHE"
        static let aiIDECache = "JC.AI.IDE.CACHE"
        static let aiToolCache = "JC.AI.TOOL.CACHE"
        static let aiGeminiTmp = "JC.AI.GEMINI.TMP"
        static let chromiumCache = "JC.BRW.CHROMIUM.CACHE"
        static let safariCache = "JC.BRW.SAFARI.CACHE"
        static let firefoxCache = "JC.BRW.FIREFOX.CACHE"
        static let arcCache = "JC.BRW.ARC.CACHE"
        static let npmLogs = "JC.DEV.NPM.LOGS"
        static let npmCacache = "JC.DEV.NPM.CACACHE"
        static let derivedOrphan = "JC.DEV.XCODE.DERIVED.ORPHAN"
        static let derivedLive = "JC.DEV.XCODE.DERIVED.LIVE"
        static let xcodeCache = "JC.DEV.XCODE.CACHE"
        static let xcodeArchives = "JC.DEV.XCODE.ARCHIVES"
        static let deviceSupport = "JC.DEV.XCODE.DEVICESUPPORT"
        static let latestDeviceSupport = "JC.DEV.XCODE.DEVICESUPPORT.LATEST"
        static let userCache = "JC.CACHE.USER"
        static let containerCache = "JC.CACHE.CONTAINER"
        static let darwinTmp = "JC.SYS.TMP.DARWIN"
        static let darwinCache = "JC.SYS.CACHE.DARWIN"
        static let leftoverOrphan = "JC.LEFTOVER.ORPHAN"
        static let hfModel = "JC.AI.HF.MODEL"
        static let brokenPlist = "JC.SYS.PLIST.BROKEN"
        static let pubAsset = "JC.DEV.PUB.ASSET"
        static let jetBrainsCache = "JC.DEV.JETBRAINS.CACHE"
        static let spotifyCache = "JC.MEDIA.SPOTIFY.CACHE"
        static let spotifyStorage = "JC.MEDIA.SPOTIFY"
        static let appStoreCache = "JC.SYS.APPSTORE.CACHE"
        static let cacheSubdirRules: Set<String> = [
            "JC.ELECTRON.CACHE", "JC.ELECTRON.SW",
            "JC.BRW.CHROMIUM.CACHE", "JC.BRW.CHROMIUM.SW",
            "JC.BRW.ARC.CACHE",
            "JC.AI.IDE.CACHE"
        ]
        static let rootOnlyContainerRules: Set<String> = [
            "JC.CACHE.USER",
            "JC.CACHE.CONTAINER",
            "JC.SYS.TMP.DARWIN",
            "JC.SYS.CACHE.DARWIN"
        ]
        static let testCertificateExemptionRules: Set<String> = [
            "JC.DEV.PKG.SAFE",
            "JC.DEV.PKG.L2",
            "JC.DEV.NPM.CACACHE",
            "JC.DEV.BREW.CACHE",
            "JC.DEV.XCODE.DERIVED.ORPHAN",
            "JC.DEV.XCODE.DERIVED.LIVE"
        ]
        static let lprojExemptionRules: Set<String> = [
            "JC.BRW.CHROMIUM.CACHE",
            "JC.BRW.CHROMIUM.SW",
            "JC.BRW.SAFARI.CACHE",
            "JC.BRW.FIREFOX.CACHE",
            "JC.BRW.ARC.CACHE",
            "JC.ELECTRON.CACHE",
            "JC.ELECTRON.SW",
            "JC.AI.IDE.CACHE"
        ]
        static let xcarchiveAppExemptionRules: Set<String> = [
            "JC.DEV.XCODE.ARCHIVES",
            "JC.DEV.XCODE.DERIVED.ORPHAN",
            "JC.DEV.XCODE.DERIVED.LIVE"
        ]
        static var auditedAutoCleanUserCacheBundleIDs: Set<String> { KnowledgeBaseManager.shared.authored.catalog.values("cm_auto_clean_cache", "cache_key") }
        static var auditedAutoCleanUserCacheBundleIDsLower: Set<String> { Set(auditedAutoCleanUserCacheBundleIDs.map { $0.lowercased() }) }
        static let implementedPredicates: Set<String> = [
            "",
            "app_not_running",
            "browser_not_running AND profile_split",
            "browser_not_running",
            "workspace_path_missing AND xcode_not_running",
            "workspace_path_exists OR plist_missing",
            "xcode_not_running",
            "not_latest_per_platform",
            "latest_per_platform",
            "daemon_not_running",
            "not_downloads_subdir",
            "direct_child_of_user_caches AND NOT protected",
            "container_or_group_caches_child AND NOT apple_private",
            "one_row_per_model",
            "orphan_app_uninstalled_and_volatile_root",
            "plutil_lint_failed AND not_in_use",
            "manifest_and_git_and_sensitive_ok AND cwd_not_inside AND stale_by_git",
            "wechat_not_running",
            "premiere_or_ae_not_running",
            "confstr_user_temp AND regular_file AND no_open_handle",
            "confstr_user_cache AND regular_file AND no_open_handle",
            "normalized_name_matches_installed_app",
            "not_installed OR younger_than_7d",
            "not_open",
            "state_ready AND deletable AND no_booted_device"
        ]
        static var implementedAutomaticRules: Set<String> { KnowledgeBaseManager.shared.authored.catalog.selectedRules("daily_allowed") }
    }
    enum Remediation {
        static let snapshotDetailsWidth: CGFloat = 560
        static let snapshotDetailsHeight: CGFloat = 360
        static let chromiumProfileNames: Set<String> = ["Default", "Guest Profile"]
        static let chromiumProfilePrefix = "Profile "
        static let uninstallIdentityCharacters = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_")
        static let uninstallGlobCharacters = Set("*?[]\\")
        static let darwinCacheToken = "{DARWIN_USER_CACHE_DIR}"
        static let sqliteSidecarSuffixes = ["-wal", "-shm", "-journal"]
        static let lsofArguments = ["-n", "-P", "-Fn"]
        static let appGroupEntitlement = "com.apple.security.application-groups"
        static let derivedMetadataFile = "info.plist"
        static let unavailableWorkspacePrefixes = ["/Volumes/", "/Network/"]
        static let workspacePathKey = "WorkspacePath"
        static let virtualenvProofFiles = ["pyvenv.cfg", "bin/activate", "Scripts/activate"]
        static let virtualenvNames: Set<String> = ["env", "venv", ".venv"]
        static let protectedGameOutputs: Set<String> = ["build", "builds", "saved"]
        static let unityMarker = "ProjectSettings/ProjectVersion.txt"
        static let unrealExtension = "uproject"
        static let logExtensions: Set<String> = ["log", "old", "out", "err", "crash", "ips", "diag", "spin", "hang", "trace", "gz", "bz2", "jsonl"]
        static let xcodeBundleID = "com.apple.dt.Xcode"
        static let deviceSupportSuffix = " DeviceSupport"
        static let deviceVersionPattern = #"^(\d+(?:\.\d+)*)(?:\s|$)"#
        static let quarantineMarker = "com.apple.launchservices.quarantineevents"
        static let ollamaMarker = "/.ollama/models/"
        static let infoPlistPath = "Contents/Info.plist"
        static let bundleIDKey = "CFBundleIdentifier"
        static let appSupportTemplate = "~/Library/Application Support/{appName}"
        static let groupContainersMarker = "/library/group containers/"
        static let appSupportMarker = "/library/application support/"
        static var projectProofs: [String: Set<String>] { KnowledgeBaseManager.shared.authored.catalog.projectProofs }
        static let dotNetProjectExtensions: Set<String> = ["csproj", "fsproj", "vbproj"]
        static let gitStatusArguments = ["status", "--porcelain=v1", "-z", "--untracked-files=normal"]
        static let terraformStateFiles: Set<String> = ["terraform.tfstate", "terraform.tfstate.backup", ".terraform.tfstate.lock.info"]
        static let terraformStateDirs: Set<String> = ["terraform.tfstate.d"]
        static let terraformWorkspaceIndicator = "environment"
    }
}
