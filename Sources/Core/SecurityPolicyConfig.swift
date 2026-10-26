import Foundation

#if !CLEANMATE_HELPER
extension AppConfig {
    // ========================================================
    // MARK: - 1. 系统与物理核心路径配置 (System & Physical Paths)
    // ========================================================
    public enum Paths {
        /// 系统物理红线根目录：任何情况下严禁执行整体删除 (FileUtil.isProtected)
        public static let exactProtectedRoots: Set<String> = [
            "/", "/Applications", "/Library", "/Users",
            "/System", "/usr", "/bin", "/sbin", "/etc", "/var",
            "/private", "/private/var"
        ]

        /// 只读系统卷与系统敏感目录的子树前缀（命中则直接拒绝任何删除）
        public static let protectedSubtreeRoots: [String] = [
            "/System", "/usr", "/bin", "/sbin", "/etc",
            "/private/etc", "/private/var/root", "/private/var/db",
            "/var/root", "/var/db"
        ]

        /// 用户家目录下绝对受保护的核心资产与配置目录（严禁直接作为整体删除）
        public static let criticalHomeDirectories: [String] = [
            "Documents", "Desktop", "Downloads", "Pictures", "Movies", "Music",
            "Library", "Library/Application Support", "Library/Containers",
            "Library/Group Containers", "Library/Preferences", "Library/Keychains",
            "Library/Mail", "Library/Messages", "Library/Safari",
            "Library/Mobile Documents", "Library/Accounts", "Library/Calendars"
        ]

        /// ~/Library/Caches 下受 TCC 严格保护的私有守护进程缓存（不可枚举或清理，防 tccd 卡死）
        public static let tccCachesExact: Set<String> = [
            "cloudkit", "familycircle", "passkit", "gamekit", "geoservices",
            "animoji", "temporaryitems", "askpermissiond", "familycircled"
        ]

        /// ~/Library 下 TCC 隐私敏感子目录前缀（邮件、通讯录、信息、Safari、生物特征等）
        public static let blockedLibPrefixes: [String] = [
            "mail", "messages", "safari", "homekit", "identityservices",
            "personalizationportrait", "biome", "intelligenceplatform", "trial",
            "accounts", "suggestions", "sharing", "calendars", "contacts",
            "metadata/corespotlight", "autosave information", "statuskit", "donotdisturb",
            "application support/addressbook", "application support/callhistorydb",
            "application support/callhistorytransactions", "application support/com.apple.tcc",
            "application support/knowledge", "application support/clouddocs",
            "application support/fileprovider"
        ]

        /// 严格禁止触碰的核心敏感数据库路径（DNA 宪章红线）
        public static let forbiddenDbMarkers: [String] = [
            "/Library/Mail",
            "/Library/Safari",
            "/Library/Keychains",
            "/Library/Accounts",
            "/Library/Photos",
            "/Library/Messages"
        ]

        /// 硬件风扇控制助手安装路径 (SMC Helper)
        public static let privilegedHelperInstallPath = "/Library/PrivilegedHelperTools/com.aclean.smchelper"
        public static let legacyHelperInstallPath     = "/Library/PrivilegedHelperTools/com.cleanmate.smchelper"

        /// 后台常驻调度器 LaunchAgent 标识
        public static let launchAgentLabel = "com.aclean.scheduler"

        /// 顶层系统与用户根容器集合（相对或绝对路径，绝不允许将其作为子树前缀阻断其下内容的扫描）
        public static let topLevelContainerPaths: [String] = [
            "/",
            "/Applications",
            "/Library",
            "/Users",
            "/System",
            "/usr",
            "/bin",
            "/sbin",
            "/etc",
            "/var",
            "/private",
            "/private/var",
            "/private/var/folders",
            "~",
            "~/Applications",
            "~/Documents", "~/Desktop", "~/Downloads", "~/Pictures", "~/Music", "~/Movies",
            "/Volumes", "/opt", "/cores",
            "~/Library",
            "~/Library/Caches",
            "/Library/Caches",
            "~/Library/Logs",
            "/Library/Logs",
            "~/Library/Containers",
            "~/Library/Group Containers",
            "~/Library/Developer",
            "~/Library/Application Support",
            "/Library/Application Support"
        ]

        /// 解析为标准化的小写绝对路径集合（供安全检查快速 O(1) 判定）
        public static var topLevelContainers: Set<String> {
            let home = FileUtil.home.path.lowercased()
            return Set(topLevelContainerPaths.map { path in
                let expanded = path.hasPrefix("~")
                    ? home + path.dropFirst()
                    : path
                return expanded.lowercased()
            })
        }
    }

    // ========================================================
    // MARK: - 2. 安全与红线风控矩阵配置 (Security & Risk Control)
    // ========================================================
    public enum Security {
        public static let secondsPerHour: Double = 3600
        public static let authoredActions: Set<String> = ["trash", "trash_children_only", "read_only", "native"]
        public static let authoredProtectionKinds: Set<String> = ["prefix", "suffix", "exact", "marker"]
        public static let openFileSelectionCacheTTL: TimeInterval = 2
        public static let fileHandleCheckTimeout: TimeInterval = 3
        public static let lsofPath = "/usr/sbin/lsof"
        public static let credentialDirectories: Set<String> = [".ssh", ".gnupg", ".gpg", ".aws", ".kube", ".aliyun", ".tccli", ".password-store"]
        public static let protectedDotRoots = [".config", ".local", ".cache", ".cargo", ".docker", ".npm", ".nvm", ".rustup", ".vscode"]
        public static let credentialNames: Set<String> = [".npmrc", ".pypirc", ".netrc", ".gitconfig", ".git-credentials", ".zshrc", ".bashrc", ".profile", ".zsh_history", ".bash_history", "credentials", "credentials.json", "token", "tokens.json"]
        public static let browserStateNames: Set<String> = ["cookies", "cookies-journal", "login data", "login data-journal", "web data", "history", "history-journal", "bookmarks", "bookmarks.bak", "local storage", "session storage", "indexeddb", "webstorage", "local state", "preferences", "secure preferences", "extension state", "extensions", "key4.db", "places.sqlite", "logins.json"]
        public static let passwordStoreNames = ["1password", "agilebits", "bitwarden", "keepassxc", "lastpass", "dashlane"]
        public static let fallbackMailIDs = ["com.apple.mail", "com.microsoft.outlook", "org.mozilla.thunderbird", "com.readdle.smartemail-mac", "com.readdle.sparkdesktop", "it.bloop.airmail", "com.tencent.foxmail"]
        public static let fallbackMailNames: Set<String> = ["outlook", "thunderbird", "spark", "airmail", "foxmail", "mail downloads"]
        public static let dataScopeMarkers = ["/library/application support/", "/library/caches/", "/library/containers/", "/library/group containers/", "/.mozilla/", "/chrome-profile/", "/antigravity-browser-profile/"]
        public static let cleanupInspectionMaxItems = 100_000
        public static let cleanupInspectionTimeout: TimeInterval = 15
        public static let largeContainerInspectionMaxItemsMultiplier = 5
        public static let largeContainerInspectionTimeoutMultiplier: TimeInterval = 3
        public static let deduplicationRecordLimit = 2048
        public static let orphanOwnershipCacheTTL: TimeInterval = 10.0
        public static let testCertExemptionExtensions: Set<String> = [
            "pem", "key", "p12", "pfx", "keystore", "jks"
        ]
        public static let authoredManagedLegacyExclusions: Set<String> = [
            "ms-playwright",
            "com.spotify.client",
            "adobe",
            "^arc(?:/.*)?$",
            "^company\\.thebrowser\\.browser(?:/.*)?$",
            "^sentrycrash/arc(?:/.*)?$",
            "^(?:adobe\\s+.+|.+\\s+adobe)$",
            "^.+/java$",
            "^.+/fontconfig$"
        ]
        public static let authoredManagedNameExclusions: Set<String> = [
            "^com.apple.safari$",
            "^google$",
            "^metadata$",
            "com.spotify.client"
        ]
        public static let protectedAISubtreeSuffixes: [String] = [
            "/.cursor/extensions",
            "/.vscode/extensions",
            "/.windsurf/extensions",
            "/.claude/versions",
            "/.local/share/claude/versions"
        ]
        public static let protectedAIExactSuffixes: [String] = [
            "/.claude/stats-cache.json",
            "/.claude/mcp-needs-auth-cache.json",
            "/.claude/plugins/install-counts-cache.json"
        ]
        public static let ioConcurrency = 4
        public static let helperCommandTimeout: TimeInterval = 60
        public static let scopeIssueLimit = 100
        public static let hashChunkBytes = 1_048_576
        public static let hashHeadBytes = 4 * hashChunkBytes
        public static let progressInterval: TimeInterval = 0.08
        public static let shellPollMicroseconds: useconds_t = 10_000
        public static let sessionPathMarkers = ["/library/httpstorages/", "/library/webkit/", "/library/cookies/", "/saved application state/"]
        public static let cloudPathMarkers = ["fileprovider", "clouddocs", "mobile documents", "onedrive", "dropbox", "google drive", "cloudstorage", "nutstore", "baidunetdisk", "com.apple.bird", "com.apple.cloudd"]

        /// 固化受保护的系统 Bundle Identifier 白名单（含 macOS 15 Sequoia 设置与控制中心）
        public static let protectedBundleIDs: Set<String> = [
            "com.apple.Settings",
            "com.apple.SystemSettings",
            "com.apple.controlcenter",
            "com.apple.systempreferences",
            "com.apple.Safari.SafeBrowsing",
            "com.apple.security",
            "com.apple.keychain",
            "com.apple.Passwords",
            "com.apple.MobileBackup",
            "com.apple.bird",
            "com.apple.cloudd",
            "com.apple.icloud",
            "com.apple.Music",
            "com.apple.HomeKit",
            "com.apple.finder",
            "com.apple.dock",
            "com.apple.loginwindow",
            "com.apple.Spotlight",
            "com.apple.notificationcenterui",
            "com.apple.FontRegistry",
            "com.apple.IconServices"
        ]

        /// 规则知识库不可用时的最小保护 Bundle ID 集合
        public static let fallbackIgnoreBundleIDs: Set<String> = [
            "com.apple.Safari.SafeBrowsing",
            "com.apple.security",
            "com.apple.keychain",
            "com.apple.Passwords",
            "com.apple.MobileBackup",
            "com.apple.bird",
            "com.apple.cloudd",
            "com.apple.icloud",
            "com.apple.Music",
            "com.apple.HomeKit"
        ]

        /// 固化受保护路径标记（含 Apple 神经引擎 ANE 缓存、虚拟机磁盘、凭据库、密码扩展等）
        public static let protectedPathMarkers: [String] = [
            "com.apple.Settings",
            "com.apple.controlcenter",
            "com.apple.e5rt.e5bundlecache",          // Apple 神经引擎缓存，清除会导致 CoreML 重编卡死
            "Library/Keychains",
            "Library/Accounts",
            "Library/Mobile Documents",
            "CrashReporter/Retired",                  // 归档系统崩溃根
            ".orbstack/data",                        // OrbStack 虚拟机磁盘，绝对严禁删除
            "Docker.raw",                            // Docker 虚拟机数据磁盘，绝对严禁删除
            "Docker.qcow2",
            "com.apple.passwordmanager.json",        // 密码扩展组件，防破坏浏览器密码填充
            "Steam/steamapps/common",                // Steam 游戏安装库
            ".android/avd",                          // Android AVD 虚拟机磁盘
            "debug.keystore",                        // Android 调试秘钥
            "adbkey",                                // Android ADB 授权私钥
            "InputMethod",                           // 输入法词库与自定义词典目录
            "Input Methods",                         // macOS 输入法安装与用户词库目录
            ".cocoapods/repos"                       // CocoaPods 全局 Spec 镜像库
        ]

        /// System daemons that can trigger repeated authentication prompts.
        public static let keychainStormProtectedDaemons: Set<String> = [
            "cloudkit", "familycircle", "passkit", "gamekit", "geoservices",
            "animoji", "temporaryitems", "askpermissiond", "familycircled",
            "com.apple.accountsd", "akd", "identityservicesd", "containermanagerd",
            "passwords", "securityd", "secd"
        ]

        /// 敏感身份/账号关键词：出现即拦截（防触发认证弹窗与登出）
        public static let sensitiveIdentityFragments: [String] = [
            "account", "icloud", "appleid", "authkit", "keychain",
            "password", "token", "credential", "donotdisturb", "statuskit"
        ]

        /// EDR 端点安全防护软件前缀白名单（绝对不可清理或篡改）
        public static let edrTamperProtectedPrefixes: [String] = [
            "com.crowdstrike.", "com.sentinelone.", "com.sentinel-labs.",
            "com.jamf.", "com.jamfsoftware.", "com.carbonblack.",
            "com.sophos.", "com.microsoft.wdav.", "com.eset.",
            "com.paloaltonetworks.", "com.cisco.anyconnect", "com.cisco.secureclient"
        ]

        /// 开发编译缓存特征（命中即视为 devCache，默认不勾选）
        public static let devCacheMarkers: [String] = [
            "Developer/Xcode/DerivedData",
            "DerivedData",
            "ModuleCache.noindex",
            "Xcode/Archives",
            "iOS DeviceSupport",
            "macOS DeviceSupport",
            "watchOS DeviceSupport",
            "tvOS DeviceSupport",
            "iOS Device Logs",
            "DeviceLogs",
            "IB Support",
            "DocumentationCache",
            "CoreSimulator/Caches",
            "CoreSimulator/Devices",
            "CoreSimulator/Profiles",
            "CoreSimulator/Images",
            "XCPGDevices",
            "Caches/com.apple.dt.Xcode",
            "Caches/go-build",
            "Caches/org.gradle",
            ".gradle",
            "Caches/CocoaPods",
            "Caches/node-gyp",
            "Caches/pip",
            "Caches/Yarn",
            "Caches/Homebrew",
            "Caches/com.apple.dt.Xcode.InstallCheckCache"
        ]

        /// iOS 备份相对路径标记 (MobileSync/Backup)
        public static let iOSBackupRootMarker = "Application Support/MobileSync/Backup"

        /// 全局系统防护与通用缓存/垃圾扫描器的白名单 ScannerID 集合
        public static let cacheAndSystemScannerIDs: Set<Int> = [
            Int.max,             // 系统全局关键路径与服务 (9223372036854775807)
            39,                  // 深搜禁入目录（~/Library/Mail 等）
            9,                   // 系统垃圾扫描器受保护项
            10,                  // 用户缓存扫描器受保护项
            80                   // 系统数据卷挂载点
        ]

        /// 真实 FDA 专有只读探针相对路径列表（受 SystemPolicyAllFiles 门控，严格避开独立 TCC 目录）
        public static let fdaProbeRelativePaths: [String] = [
            "/Library/Application Support/com.apple.TCC/TCC.db",
            "~/Library/Application Support/com.apple.TCC/TCC.db"
        ]

        /// 解析为当前用户环境下的探针物理绝对路径
        public static var fdaProbePaths: [String] {
            let home = FileUtil.home.path
            return fdaProbeRelativePaths.map { path in
                path.hasPrefix("~") ? home + path.dropFirst() : path
            }
        }

        /// 敏感文件名后缀与私钥特征 (GitGuard 物理避让)
        public static let sensitiveExtensions: Set<String> = [
            "key", "pem", "p12", "pfx", "keystore", "jks"
        ]

        /// 敏感文件名精确匹配清单
        public static let exactSensitiveNames: Set<String> = [
            "id_rsa", "id_ed25519", "id_ecdsa", "id_dsa",
            ".env", ".env.local", ".env.production", "credentials.json"
        ]

        /// 绝对禁止终止的核心系统进程集合 (ProcessGuard 防止系统崩溃)
        public static let criticalSystemProcesses: Set<String> = [
            "kernel_task", "launchd", "WindowServer", "loginwindow", "Finder", "Dock",
            "syspolicyd", "opendirectoryd", "trustd", "securityd", "coreauthd", "tccd",
            "containermanagerd", "diskarbitrationd", "fseventsd", "kextd", "powerd",
            "systemsoundserverd", "ControlCenter", "SystemSettings", "NotificationCenter",
            "AClean", "CleanMate", "ACleaner"
        ]

        /// 开发工具链运行态进程名称（运行中则跳过对应缓存清理，防写入冲突）
        public static let xcodeToolchainProcesses = ["Xcode", "xcodebuild", "ibtool", "swift-frontend"]
        public static let simulatorProcesses      = ["Simulator", "com.apple.CoreSimulator.CoreSimulatorService"]
        public static let dockerProcesses         = ["Docker", "com.docker.backend", "dockerd"]
        public static let orbStackProcesses       = ["OrbStack", "orbstack"]

        /// GitGuard 敏感资产检查最大递归深度
        public static let sensitiveAssetsMaxDepth: Int = 10

        /// Git 仓库已跟踪文件检查命令执行超时时间 (秒)
        public static let gitLsFilesTimeout: TimeInterval = 5.0

        /// Git 仓库跟踪文件缓存 TTL (秒)
        public static let gitTrackedCacheTTL: TimeInterval = 5.0

        /// Docker 目录枚举安全预算上限（项数）
        public static let dockerSubtreeMaxItems: Int = 2000

        /// 应用退出等待超时时间 (秒)
        public static let appTerminationTimeout: TimeInterval = 1.0

        /// 应用退出等待轮询间隔 (秒)
        public static let appTerminationPollInterval: TimeInterval = 0.1
    }
}
#endif
