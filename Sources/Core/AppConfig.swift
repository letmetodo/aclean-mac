import Foundation

// ============================================================
//  AppConfig —— CleanMate 全局统一配置与常量中心
//
//  设计目标：
//    1. 将散落在全项目数十个引擎文件中的硬编码目录、阈值、扫描特征、
//       白名单及风控规则全量收敛至此单一配置文件；
//    2. 集中化维护：后续若需新增扫描路径、调整安全阈值、增删排除名单，
//       只需修改本文件，无需深入各引擎实现细节；
//    3. 结构化模块命名空间：按业务领域划分（Paths, Security, JunkScan,
//       DeveloperPurge, Uninstaller, Helpers, Organize, AIClutter,
//       Telemetry, StorageKeys, Defaults）。
// ============================================================

public enum AppConfig {
    public enum RuleUpdates {
        public static let databaseName = "cleanmate_rules.db"
        public static let stateName = "update-state.json"
        public static let temporaryPrefix = ".rules-download-"
        public static let directory = "com.personal.aclean/Rules"
        public static let sqlResource = "cleanmate_authored_rules"
        public static let safetyResource = "rule_safety"
        public static let manifestName = "latest.json"
        public static let automaticKey = "aclean.rules.autoUpdate"
        public static let baseURLKey = "CleanMateRulesBaseURL"
        public static let interval: TimeInterval = 24 * 60 * 60
        public static let requestTimeout: TimeInterval = 15
        public static let resourceTimeout: TimeInterval = 60
        public static let metadataBytes = 256 * 1024
        public static let databaseBytes = 10 * 1024 * 1024
        public static let jsonDepth = 32
        public static let maximumRecords = 100_000
        public static let maximumStringBytes = 4096
        public static let queryInstructions: Int32 = 1_000_000
        public static let minimumVersionAgeHours = 168
        public static let minimumRetainedVersions = 2
        public static let minimumProjectAgeDays = 7
        public static let maximumProjectDepth = 4
        public static let maximumManifestSearchDepth = 3
        public static let maximumDiscoveryDepth = 16
        public static let lastCheckKey = "aclean.rules.lastCheck"
        public static let changedNotification = "CleanMateRulesDidChange"
        public static let genericDiscoveryScanners: Set<String> = [
            "scanUserCaches", "scanDeveloperCaches", "scanProfileCache", "scanBrowserCaches", "scanSystemLogs",
            "scanJetBrainsCaches", "scanXcodeJunk", "scanAppStoreCache", "BrewHelper.scanCacheItems"
        ]
        public static let dedicatedDiscoveryPredicates: Set<String> = [
            "one_row_per_model", "manifest_and_git_and_sensitive_ok AND cwd_not_inside AND stale_by_git"
        ]
        public static let offlineWorkerPathMarkers = ["/service worker/", "/serviceworker/"]
        public static let businessTables = [
            "cm_application_identity", "cm_auto_clean_cache", "cm_cache_profile", "cm_cache_profile_lock",
            "cm_cache_subdir", "cm_chromium_profile_subdir", "cm_discovery_binding", "cm_electron_data_dir",
            "cm_file_type", "cm_global_guard", "cm_junk_rule", "cm_junk_rule_exclude", "cm_junk_rule_lock",
            "cm_launchd_protected_prefix", "cm_mail_client", "cm_name_collision", "cm_organize_path",
            "cm_package_extension", "cm_performance_task", "cm_project_artifact", "cm_project_artifact_proof",
            "cm_project_manifest", "cm_project_scan_root", "cm_protected_path", "cm_rule_meta",
            "cm_rule_selection", "cm_service_worker_domain", "cm_shared_vendor_root", "cm_uninstall_template",
            "cm_vacuum_forbidden", "cm_version_cache"
        ]
        public static var automaticEnabled: Bool {
            UserDefaults.standard.object(forKey: automaticKey) as? Bool ?? true
        }
        public static var baseURL: URL? {
            guard let text = Bundle.main.object(forInfoDictionaryKey: baseURLKey) as? String,
                  let url = URL(string: text), url.scheme == "https", url.host != nil, url.user == nil, url.password == nil, url.query == nil, url.fragment == nil else { return nil }
            return url
        }

    }
    public enum Scheduling {
        public static let pollInterval: TimeInterval = 60
        public static let storageKey = "AClean.ScheduleConfig"
        public static let legacyStorageKey = "CleanMate.ScheduleConfig"
    }
    public enum ScanThresholds {
        public static let spaceLensLargeFileBytes: Int64 = 50 * 1024 * 1024
        public static let projectArtifactMinimumBytes: Int64 = 100 * 1024
    }

    public enum SystemReclaim {
        public static let tmutilPath = "/usr/bin/tmutil"
        public static let snapshotThinningArguments = ["thinlocalsnapshots", "/", "10737418240", "4"]
        public static let snapshotThinningTimeout: TimeInterval = 60
    }

    #if !CLEANMATE_HELPER
    public enum CleanupProfiles {
        /// Reviewed rebuildable caches only. Session data and uninstall leftovers stay manual.
        public static var developerCacheRuleIDs: Set<String> { KnowledgeBaseManager.shared.authored.catalog.selectedRules("developer_allowed") }

        public static var maximumCacheRuleIDs: Set<String> { KnowledgeBaseManager.shared.authored.catalog.selectedRules("maximum_allowed") }

        /// 即使在「极限清理 (maxSpace)」方案下也严禁自动勾选的规则 ID（聊天历史媒体、本地大模型资产、iOS 备份/固件、发版归档与模拟器数据等，仅允许用户手动确认勾选）
        public static var manualOnlyRuleIDs: Set<String> { KnowledgeBaseManager.shared.authored.catalog.selectedRules("manual_only") }
    }

    #endif
    public enum PrivilegedHelper {
        public static let service = "com.personal.aclean.maintenance-helper"
        public static let clientIdentifier = "com.personal.aclean"
        public static let plistName = service + ".plist"
        public static let executableName = "ACleanMaintenanceHelper"
        public static let executableRelativePath = "Contents/MacOS/" + executableName
        public static let fanLeaseSeconds: TimeInterval = 60
        public static let fanRenewSeconds: TimeInterval = 20
        public static let fanRequestTimeout: TimeInterval = 15
        public static let fanWatchdogInterval: TimeInterval = 2
        public static let fanTaskModes = ["fan.auto", "fan.cool", "fan.max", "fan.renew"]
        public static let maxPendingRequests = 8
        public static let timeout: TimeInterval = 120
        public static let pollInterval: TimeInterval = 0.05
        public static let commands: [String: [(String, [String])]] = [
            "flushDNS": [("/usr/bin/dscacheutil", ["-flushcache"]), ("/usr/bin/killall", ["-HUP", "mDNSResponder"])],
            "reindexSpotlight": [("/usr/bin/mdutil", ["-E", "/"])],
            "thinTimeMachine": [(SystemReclaim.tmutilPath, SystemReclaim.snapshotThinningArguments)],
            "runMaintenanceScripts": [("/usr/sbin/periodic", ["daily", "weekly", "monthly"])]
        ]
    }

    #if !CLEANMATE_HELPER
    // ========================================================
    // MARK: - 5. 软件卸载与孤儿残留规则配置 (Uninstaller & Orphan Finder)
    // ========================================================
    public enum Uninstaller {
        /// 正则匹配单层终端候选截断上限
        public static let regexMatchLevelCap: Int = 1000

        /// 应用程序深搜最大递归层级 (深度 5 确保命中藏于三层嵌套内的 32 位老应用)
        public static let appScanMaxDepth: Int = 5

        /// 启发式 Token 防短名误伤最小字符长度阈值
        public static let minMatchTokenLength: Int = 5

        /// 卸载器安全深搜根目录模板（严格限定在标准用户应用数据目录，绝不触碰 Mail/Messages/Safari 等禁区）
        public static let deepSearchRootTemplates: [String] = [
            "~/Library/Application Support",
            "~/Library/Caches",
            "~/Library/Logs",
            "~/Library/Preferences",
            "~/Library/Containers",
            "~/Library/Group Containers",
            "~/Library/Saved Application State",
            "~/Library/WebKit",
            "~/Library/HTTPStorages"
        ]

        /// 展开为当前用户下的绝对深搜根目录列表
        public static var deepSearchRoots: [String] {
            let home = FileUtil.home.path
            return deepSearchRootTemplates.map { path in
                path.hasPrefix("~") ? home + path.dropFirst() : path
            }
        }

        /// 系统级「组件型」安装物目录（打印机/扫描仪驱动、内核扩展，非孤儿残留主体）
        public static let systemComponentDirs: [String] = [
            "/Library/Image Capture/Devices",
            "/System/Library/Image Capture/Devices",
            "/Library/Image Capture/TWAIN Data Sources",
            "/Library/Extensions"
        ]

        /// 安装应用常规扫描目录（支持 ~/Applications 及特定厂商驱动辅助工具目录）
        public static let appSearchDirectoryTemplates: [String] = [
            "/Applications",
            "~/Applications",
            "~/Library/Application Support/PortableSSD",
            "~/Library/Application Support/WebEx Folder/Add-ons"
        ]

        public static var appSearchDirectories: [String] {
            let home = FileUtil.home.path
            return appSearchDirectoryTemplates.map { path in
                path.hasPrefix("~") ? home + path.dropFirst() : path
            }
        }

        /// 全量应用扫描目录（含 ~/Downloads 镜像与驱动辅助工具目录）
        public static let allAppScanDirectoryTemplates: [String] = [
            "/Applications",
            "~/Applications",
            "~/Downloads",
            "~/Library/Application Support/PortableSSD",
            "~/Library/Application Support/WebEx Folder/Add-ons"
        ]

        public static var allAppScanDirectories: [String] {
            let home = FileUtil.home.path
            return allAppScanDirectoryTemplates.map { path in
                path.hasPrefix("~") ? home + path.dropFirst() : path
            }
        }

        /// 补充扫描目录之外的特定辅助应用定义 (名称, bundleID, 路径模板)
        public static let assistantAppCandidates: [(name: String, bundleID: String, pathTemplate: String)] = [
            ("Samsung Portable SSD", "com.samsung.portablessd", "~/Library/Application Support/PortableSSD/Samsung Portable SSD.app"),
            ("T3 Log In Activator for Mac", "com.samsung.t3loginactivator", "~/Library/Application Support/PortableSSD/T3 Log In Activator for Mac.app"),
            ("Cisco WebEx Start", "com.cisco.webex.Cisco-WebEx-Start", "~/Library/Application Support/WebEx Folder/Add-ons/Cisco WebEx Start.app")
        ]

        /// 应用最后使用时间探测数据目录模板
        public static let lastUsedProbeTemplates: [String] = [
            "~/Library/Application Support/{appName}",
            "~/Library/Containers/{bundleID}",
            "~/Library/Saved Application State/{bundleID}.savedState",
            "~/Library/Caches/{bundleID}"
        ]

        public static func lastUsedProbePaths(appName: String, bundleID: String) -> [String] {
            let home = FileUtil.home.path
            return lastUsedProbeTemplates.map { tmpl in
                let resolved = tmpl
                    .replacingOccurrences(of: "{appName}", with: appName)
                    .replacingOccurrences(of: "{bundleID}", with: bundleID)
                return resolved.hasPrefix("~") ? home + resolved.dropFirst() : resolved
            }
        }

        /// 共享厂商中枢目录名（小写）：在 Uninstaller 中只计入一次归属，不归属单一应用
        public static var sharedVendorDirectoryNames: Set<String> {
            Set([
                "google", "jetbrains", "adobe", "microsoft", "mozilla", "tencent", "alibaba",
                "bytedance", "baidu", "netease", "oracle", "apple", "com.apple", "jetpack",
                "sogou", "samsung", "canon", "epson", "logitech", "nvidia", "intel", "vmware",
                "parallels", "dropbox", "zoom", "slack", "unity", "autodesk", "steam",
                "bravesoftware", "chromium", "google chrome", "firefox",
                "group containers", "application support", "preferences", "caches"
            ]).union(KnowledgeBaseManager.shared.authored.sharedVendorNames)
        }

        /// 系统关键内置组件保护集（OrphanFinder 绝不判定为孤儿）
        public static var systemExclusions: Set<String> {
            Set([
                "apple", "mobilesync", "addressbook", "dock", "finder", "syncservices",
                "cloudkit", "accounts", "crashreporter", "coreparsec", "clouddocs",
                "fileprovider", "knowledge", "differentialprivacy", "quick look",
                "controlcenter", "animoji", "trustedpeershelper", "diskimages",
                "identityservicesd", "transparencyd", "syncdefaultsd", "locationaccessstored",
                "accountsd", "networkserviceproxy", "videosubscriptionsd", "callhistorytransactions",
                "callhistorydb", "appplaceholdersyncd", "familycircled", "users", "instruments",
                "safari", "mail", "messages", "photos", "system preferences", "system settings",
                "icloud", "feedbackassistant", "shortcuts", "pip", "npm", "yarn", "pnpm", "cargo",
                "go", "git", "homebrew", "bun", "rustup", "gnupg", "nvm", "caches", "defaultcompany"
            ]).union(KnowledgeBaseManager.shared.authored.collisionNames)
        }

        /// 孤儿扫描额外排除的厂商/通用名
        public static var conditionalGenericNames: Set<String> {
            Set([
                "adobe", "google", "microsoft", "mozilla", "apple", "oracle", "jetbrains",
                "steam", "tencent", "alibaba", "baidu", "bytecode", "bytedance", "netease",
                "app store", "mobile devices", "mobilesync", "addressbook", "crashreporter",
                "clouddocs", "fileprovider", "knowledge", "com.apple", "group containers",
                "application support", "preferences", "containers", "keychains", "launchagents"
            ]).union(KnowledgeBaseManager.shared.authored.sharedVendorNames)
        }

        /// 开发者工具链 / 包管理器归属词（归开发者缓存，不作应用孤儿残留误报）
        public static var developerToolchainTokens: Set<String> {
            Set([
                "gobuild", "gopls", "goimports", "golangci", "golangextension", "gomodcache",
                "gocache", "gotip", "dlv", "playwright", "puppeteer", "cypress", "selenium",
                "chromium", "hermit", "tabnine", "goose", "aider", "continue", "copilot",
                "codex", "claude", "codebuddy", "dotslash", "fanal", "mcp", "npm", "yarn",
                "pnpm", "corepack", "nodegyp", "electron", "typescript", "eslint", "prettier",
                "esbuild", "vite", "webpack", "turbopack", "turborepo", "turbo", "deno", "bun",
                "cargo", "rustup", "swiftpm", "clangd", "ccache", "swiftlint", "swiftformat",
                "gradle", "maven", "cocoapods", "carthage", "mint", "kotlin", "jetbrains",
                "pip", "pipx", "poetry", "conda", "anaconda", "virtualenv", "uv",
                "composer", "rubygems", "bundler", "opam", "homebrew", "docker", "colima",
                "lima", "orbstack", "podman", "wechatwebdevtools", "wechat-devtools"
            ]).union(KnowledgeBaseManager.shared.authored.collisionNames)
        }

        /// 多应用共享厂商名
        public static var sharedVendorNames: Set<String> {
            Set([
                "jetbrains", "adobe", "google", "microsoft", "mozilla", "tencent", "alibaba",
                "bytedance", "baidu", "netease", "oracle", "steam", "blizzard", "samsung",
                "logitech", "razer", "sony", "nvidia", "intel", "dropbox", "slack", "zoom",
                "autodesk", "unity", "epicgames", "ubisoft", "vmware", "parallels", "sogou",
                "epson", "canon", "brother", "hewlettpackard", "lexmark", "ricoh", "kyocera"
            ]).union(KnowledgeBaseManager.shared.authored.sharedVendorNames)
        }

        /// 与具体应用无关的共享系统目录名
        public static let sharedSystemNames: Set<String> = [
            "localstorage", "webpush", "websitedata", "shared", "caches", "temp", "tmp",
            "default", "askpermissiond", "libcachedimagedata", "statsigcache",
            "comapple", "cloudkit", "safebrowsing"
        ]

        /// 系统自身持有的域片段（子串匹配，出现即判定为系统组件）
        public static let systemOwnedFragments: Set<String> = [
            "cups", "printingprefs", "xquartz", "screensharing", "windowserver",
            "loginwindow", "systemconfiguration", "coreservices", "bluetooth",
            "securityagent", "networkserviceproxy"
        ]

        /// bundle ID 分段时忽略的通用词
        public static let genericBIDSegments: Set<String> = [
            "desktop", "manager", "client", "helper", "service", "services", "update",
            "updater", "extension", "extensions", "plugin", "plugins", "beta", "lite",
            "apps", "application", "applications", "framework", "macos", "shared",
            "common", "tools", "utility", "utilities", "support", "preview", "insider",
            "nightly", "release", "official", "product", "studio", "editor",
            "home", "work", "mail", "maps", "news", "ical", "siri", "data", "test",
            "main", "core", "live", "sync", "code", "note", "chat", "docs", "demo",
            "temp", "user", "team", "file", "link", "page", "site", "open", "save",
            "tool", "util", "read", "book", "shop", "game", "auto", "free", "view",
            "edit", "play", "host", "port", "node", "java", "ruby", "rust", "desk",
            "plus", "soft", "tech", "sand", "text", "word", "time", "date", "info",
            "help", "menu", "icon", "lock", "keys", "auth", "calc", "paint",
            "video", "audio", "image", "photo", "movie", "music", "sound", "camera"
        ]

        /// 通用组件/可执行名（不参与应用名 ± 短后缀判定）
        public static let genericEntityNames: Set<String> = [
            "electron", "code", "main", "app", "helper", "updater", "crashpad",
            "launcher", "service", "agent", "daemon", "client", "renderer",
            "webcontent", "plugin", "macos", "windows", "universal", "beta", "lite"
        ]

        /// 过于通用的应用名标识词（不参与段交集判定）
        public static let genericAppNameTokens: Set<String> = [
            "desktop", "manager", "player", "editor", "viewer", "studio", "center",
            "client", "server", "remote", "terminal", "console", "preview", "utility",
            "tools", "store", "cloud", "music", "photos", "notes", "image", "screen",
            "script", "setup", "system", "control", "digital", "edition", "machine",
            "color", "meter", "games", "books", "pages", "print", "exchange",
            "migration", "transfer", "capture", "handler", "assistant", "monitor",
            "navigator", "information", "logic", "sharing", "switch", "mission",
            "activity", "calculator", "calendar", "contacts", "messages", "reminders",
            "weather", "stocks", "clock", "dictionary", "journal", "freeform",
            "shortcuts", "passwords", "facetime", "podcasts", "stickies", "textedit",
            "automator", "grapher", "mirroring", "screenshot", "bluetooth", "airport",
            "colorsync", "magnifier", "playground", "migrator", "compressor"
        ]
    }

    // ========================================================
    // MARK: - 7. 空间透镜与文件整理配置 (Space Lens & File Organize)
    // ========================================================
    public enum Organize {
        /// 文件后缀与归类大类映射字典
        public static var fileKindMap: [String: String] { Dictionary(uniqueKeysWithValues: KnowledgeBaseManager.shared.authored.catalog.rows("cm_file_type").compactMap { row in guard let key = row["extension"], let value = row["category"] else { return nil }; return (key, value) }) }

        /// 剪枝排除目录集合（避免深搜开发仓库与构建生成物子树）
        public static var pruneDirectories: Set<String> { Set(KnowledgeBaseManager.shared.authored.catalog.rows("cm_organize_path").filter { $0["role"] == "exclude_component" }.compactMap { $0["path_template"] }) }

        /// 废弃安装包探测根目录（相对家目录）
        public static var installerSearchRoots: [String] { KnowledgeBaseManager.shared.authored.catalog.rows("cm_organize_path").filter { $0["role"] == "installer_root" }.compactMap { $0["path_template"] } }

        /// 视作单体包对待的目录后缀（不向内展开为普通散列目录）
        public static var packageExtensions: Set<String> { KnowledgeBaseManager.shared.authored.catalog.values("cm_package_extension", "extension") }

        /// 空间透镜最大递归深度与单目录子项上限（提升至 18 层以彻底覆盖 WeChat、Chrome、Xcode、Docker 等深层应用容器目录）
        public static let similarImageCandidateLimit = 20_000
        public static let spaceLensMaxDepth = 18
        public static let spaceLensMaxChildrenPerDir = 64
        public static let spaceLensMinDirectFileBytes: Int64 = 2 * 1024 * 1024 // 2MB
    }

    // ========================================================
    // MARK: - 9. 网络诊断与气象服务配置 (Network & Weather Telemetry)
    // ========================================================
    public enum Telemetry {
        public static let maximumFanCount = 6
        public static var networkFeaturesEnabled: Bool {
            if let explicit = UserDefaults.standard.object(forKey: AppConfig.StorageKeys.networkFeaturesEnabled) as? Bool {
                return explicit
            }
            return false
        }
        public static let foregroundSampleInterval: TimeInterval = 1
        public static let backgroundSampleInterval: TimeInterval = 5
        public static let networkProcessSampleInterval: TimeInterval = 5
        public static let networkProcessForegroundSampleInterval: TimeInterval = 2
        public static let networkProcessTimeout: TimeInterval = 3
        public static let weatherForecastURL = "https://api.open-meteo.com/v1/forecast"
        public static let citySearchURL = "https://geocoding-api.open-meteo.com/v1/search"
        public static let ipProviderURLs = ["https://ipwho.is/", "https://ipinfo.io/json", "https://ipapi.co/json/"]
        public static let shellReadBufferSize = 16384
        public static let shellReadBatchLimit = 16
        public static let locationCacheTTL: TimeInterval = 6 * 60 * 60
        public static let networkRetryInterval: TimeInterval = 60
        public static let weatherRefreshInterval: TimeInterval = 900
        public static let ipGeoCacheKey = "cm.geo.lastResolvedLocation.v2"
        public static let weatherCacheKey = "cm.weather.lastRealSnapshot.v3"
        public static let ipGeoTimeoutSeconds: TimeInterval = 6.0
        public static let ipGeoResourceTimeoutSeconds: TimeInterval = 10.0
        public static let weatherRequestTimeoutSeconds: TimeInterval = 8.0
        public static let weatherResourceTimeoutSeconds: TimeInterval = 12.0
    }

    // ========================================================
    // MARK: - 10. 持久化存储 Key 与默认参数配置 (Storage Keys & Defaults)
    // ========================================================
    public enum StorageKeys {
        public static let networkFeaturesEnabled = "aclean.optionalNetworkFeatures"

        public static let language             = "aclean.language"
        public static let appearanceMode       = "aclean.appearanceMode"
        public static let themePreset          = "aclean.themePreset"
        public static let largeFileThresholdMB = "aclean.largeFileThresholdMB"
        public static let oldFileMonths        = "aclean.oldFileMonths"
        public static let ignoredPaths         = "aclean.ignoredPaths"
        public static let menuBarMonitor       = "aclean.menuBarMonitor"
        public static let confirmBeforeDelete  = "aclean.confirmBeforeDelete"
        public static let soundEffects         = "aclean.soundEffects"
        /// 长任务完成通知开关。刻意不进 ExportableAppConfig：
        /// 通知授权是系统级/设备级设置，不应跟随配置导入导出到别的机器。
        public static let notifyOnCompletion  = "aclean.notifyOnCompletion"
        /// 跨会话清理历史（仅聚合数字，不含路径）
        public static let cleanHistory        = "aclean.cleanHistory.v1"
        /// 已看过分模块引导提示的模块键
        public static let seenModuleTips      = "aclean.seenModuleTips.v1"
        public static let menuBarConfig        = "aclean.menubar.config.v1"
        public static let startupOverrides     = "AClean_StartupOverrides"
        public static let legacyStartupOverrides = "CleanMate_StartupOverrides"
        public static let onboardingCompleted  = "cleanmate.onboarding.completed.v1"
        public static let onboardingAwaitingFdaRelaunch = "cleanmate.onboarding.awaitingFdaRelaunch.v1"
    }

    public enum Defaults {
        public static let largeFileThresholdMB: Int = 100
        public static let minLargeFileThresholdMB: Int = 10
        public static let maxLargeFileThresholdMB: Int = 10240

        public static let oldFileMonths: Int = 6
        public static let minOldFileMonths: Int = 1
        public static let maxOldFileMonths: Int = 60

        public static let confirmBeforeDelete: Bool = true
        public static let soundEffects: Bool = true
        public static let notifyOnCompletion: Bool = true
        public static let menuBarMonitor: Bool = true
        public static let menuBarColorMode: String = "themeAccent"

        public static let schedulerMinimumCleanSize: Int64 = 500 * 1024 * 1024 // 500 MB

        /// SmartCare 智能呵护概览轮播卡片关联模块列表
        public static let smartCareCardModuleKeys: [String] = ["junk", "performance", "organize", "applications"]
    }

    // ========================================================
    // MARK: - 12. 界面窗口尺寸与布局规范配置 (UI Dimensions & Layout)
    // ========================================================
    public enum Maintenance {
        public static let irreversibleTaskIDs: Set<String> = ["purgeableSpace", "thinTimeMachine"]
        public static let memoryStatisticsExecutable = "/usr/bin/vm_stat"
        public static let memoryWarningUsageRatio = 0.75
        public static let memoryCriticalUsageRatio = 0.9
    }

    // ========================================================
    // MARK: - 13. 应用卸载撤销与批次记录配置 (Uninstaller Undo)
    // ========================================================
    public enum UninstallerUndo {
        public static let maxBatches: Int = 10
        public static let maxBatchAgeDays: Int = 30
        public static let recordFileName: String = "uninstall_undo_records.json"
        public static let appSupportSubdirectory: String = "CleanMate"
    }

    /// Presentation matching only; none of these markers grants cleanup permission.
    public enum JunkPresentation {
        /// 二级明细行（展开组内的具体文件夹）左侧缩进：与应用图标列对齐。
        public static let detailLeafIndent: CGFloat = 46
        /// 一个应用分组结束后留给分隔线的呼吸间距。
        public static let detailGroupBottomPadding: CGFloat = 6
        public static let commMarkers: [String] = [
            "xinwechat", "wechat", "tencent.qq", "/qq/", "telegram",
            "slack", "discord", "lark", "feishu", "dingtalk",
            "whatsapp", "microsoft.teams", "us.zoom.xos", "zoom", "weworkmac"
        ]
        public static let aiMarkers: [String] = [
            "antigravity", "cursor", "230313mzl4w4u92", "claude", "chatgpt", "openai",
            "windsurf", "trae", "ollama", "lmstudio", "cherry-studio", "cherrystudio",
            "codeium", "copilot", "continue", "deepseek", "gemini", "opencode", "huggingface"
        ]
        public static let designMarkers: [String] = [
            "figma", "sketch", "bohemiancoding", "adobe", "photoshop",
            "illustrator", "aftereffects", "premiere", "lightroom",
            "blender", "cinema4d", "pixelmator", "affinity", "canva",
            "principle", "framer", "axure", "jianying"
        ]
        public static let designExactPathComponents: Set<String> = ["eagle", "eagle.app"]
        public static let devMarkers: [String] = [
            "xcode", "deriveddata", "swiftpm", "org.swift", "cocoapods",
            "homebrew", "docker", "gradle", "maven", "/.m2", "nuget", "/.npm", "pnpm",
            "yarn", "cargo", "rustup", "/pip", "/.cache/uv", "/caches/uv", "go-build", "goimports",
            "hermit", "/.bun", "conda", "pub-cache", "playwright",
            "jetbrains", "coresymbolicationd", "dt.xcode", "simulator"
        ]
        public static let modelPathMarkers = ["/.ollama/models", "/lm-studio/models", "/huggingface"]
        public static let systemPathMarkers = ["/mobilesync/backup", "parallels", "vmware", "utm/machines", "/.trash", "diagnosticreports"]
        public static let systemPathPrefixes = ["/library/", "/system/"]
    }

    public enum UI {
        /// 普通轻提示停留时长（秒）
        public static let toastDefaultDuration: TimeInterval = 3.2
        /// 带动作（如撤销）的轻提示停留时长（秒）——留足反应窗口，避免用户还没读完就消失
        public static let toastActionDuration: TimeInterval = 8.0
        /// ETA 估算：进度低于该值时不显示（样本太少，估出来全是错的）
        public static let etaMinProgress: Double = 0.08
        /// ETA 估算：已耗时低于该值（秒）时不显示
        public static let etaMinElapsed: TimeInterval = 1.5
        /// ETA 估算：超过该值（秒）视为不可信，不显示
        public static let etaMaxSeconds: TimeInterval = 3600
        public static let directoryCacheEntryLimit = 64
        public static let directoryCacheNodeLimit = 100_000
        public static let defaultWindowWidth: Double = 1100
        public static let defaultWindowHeight: Double = 720
        public static let defaultWindowMinWidth: Double = 960
        public static let defaultWindowMinHeight: Double = 640
        public static let preferencesMinWidth: Double = 700
        public static let preferencesMinHeight: Double = 480
        public static let configuratorMinWidth: Double = 680
        public static let configuratorMinHeight: Double = 520
        public static let onboardingWidth: Double = 680
        public static let onboardingHeight: Double = 560
        public static let permissionSheetWidth: Double = 540
        public static let permissionPollIntervalSeconds: Double = 1.0
        public static let permissionAutoAdvanceDelaySeconds: Double = 0.8
        public static let revealInFinderDelaySeconds: Double = 0.55
        public static let menuBarCardDragRowHeight: Double = 68.0
        public static let menuBarPopoverCardSpacing: Double = 6.0
        public static let menuBarPopoverPadding: Double = 9.0
        public static let runningAppsSheetWidth: Double = 500.0
        public static let runningAppsListMaxHeight: Double = 180.0
        public static let profileDropdownWidth: Double = 310.0
        public static let cleaningStageContentMaxWidth: Double = 520
        public static let cleaningIdleMinHeight: Double = 460
        public static let detailedSensorRowLimit = 16
        public static let healthRadarCardSize: Double = 180.0
        public static let memoryReleaseToastDelay: Double = 2.0
    }
    #endif
}

#if !CLEANMATE_HELPER
extension AppConfig.Security {
    static let safeGitArguments = ["-c", "core.fsmonitor=false", "-c", "core.hooksPath=/dev/null", "-c", "core.untrackedCache=false", "-c", "core.attributesFile=/dev/null"]
    static let safeGitEnvironment = ["PATH": "/usr/bin:/bin", "HOME": "/var/empty", "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null", "GIT_OPTIONAL_LOCKS": "0", "GIT_TERMINAL_PROMPT": "0", "LANG": "C"]
}
#endif
