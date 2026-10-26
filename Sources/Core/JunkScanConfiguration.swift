import Foundation

#if !CLEANMATE_HELPER
extension AppConfig {
    // ========================================================
    // MARK: - 3. 系统垃圾与专项扫描器配置 (System Junk & Scanner Specs)
    // ========================================================
    public enum JunkScan {
        /// 开发者包管理器缓存配置：(路径模板, 显示名称, 详细说明)
        public static var packageManagerSpecs: [(rawPath: String, label: String, note: String)] { KnowledgeBaseManager.shared.authored.catalog.bindings.filter { $0.status == .active && $0.scannerID == "scanDeveloperCaches" && !$0.pathTemplate.contains("*") && !$0.pathTemplate.contains("{") && !$0.pathTemplate.isEmpty }.map { ($0.pathTemplate, (KBPaths.expand($0.pathTemplate) as NSString).lastPathComponent, L10n.localized(.junkCacheEffectRedownload)) } }

        /// 靶向硬编码应用缓存配置：(路径模板, 标题, 安全等级)
        public static var targetedAppCacheSpecs: [(rawPath: String, label: String, safety: Safety)] { KnowledgeBaseManager.shared.authored.catalog.bindings.filter { $0.status == .active && $0.scannerID == "scanProfileCache" && !$0.pathTemplate.contains("*") && !$0.pathTemplate.contains("{") }.map { ($0.pathTemplate, (KBPaths.expand($0.pathTemplate) as NSString).lastPathComponent, Safety.caution) } }

        public static var reviewedProfileRuleIDs: Set<String> { Set(KnowledgeBaseManager.shared.authored.catalog.bindings.filter { $0.scannerID == "scanProfileCache" }.map(\.ruleID)).subtracting(versionCacheRuleIDs) }
        public static let systemSimulatorCache = "/Library/Developer/CoreSimulator/Caches"
        public static var versionCacheRuleIDs: Set<String> { KnowledgeBaseManager.shared.authored.catalog.values("cm_version_cache", "rule_id") }
        public static var browserDownloadRoots: [String] { KnowledgeBaseManager.shared.authored.catalog.rows("cm_version_cache").filter { $0["family"] == "browser" }.compactMap { $0["root_template"] } }
        public static var browserDownloadVersionPattern: String { KnowledgeBaseManager.shared.authored.catalog.rows("cm_version_cache").first { $0["family"] == "browser" }?["name_pattern"] ?? "" }
        public static var agentVersionPattern: String { KnowledgeBaseManager.shared.authored.catalog.rows("cm_version_cache").first { $0["family"] == "agent" }?["name_pattern"] ?? "" }
        public static var agentVersionRoots: [(root: String, current: String, label: String)] { KnowledgeBaseManager.shared.authored.catalog.rows("cm_version_cache").filter { $0["family"] == "agent" }.compactMap { row in guard let root = row["root_template"], let current = row["current_template"] else { return nil }; return (root, current, (root as NSString).deletingLastPathComponent.components(separatedBy: "/").last ?? root) } }
        public static let versionInstallMarkers = ["install.lock.d", ".install.lock"]
        public static let versionInstallLock = "install.lock"
        public static let versionUpdateMarker = "auto-update-version"
        public static let versionMarkerMaximumBytes = 256

        /// Telegram macOS Group Container 相对路径
        public static let telegramGroupRelativePath = "Library/Group Containers/6N38VWS5BX.ru.keepcoder.Telegram"

        /// 微信 macOS 客户端数据根目录相对路径
        public static let wechatRelativePath = "Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat"

        /// Xcode 冗余子目录专项定义：(子目录组名, SF 图标, 匹配子相对路径, 说明, 安全等级)
        public static var xcodeSubdirSpecs: [(name: String, icon: String, rels: [String], note: String, safe: Safety)] {
            let prefix = "~/Library/Developer/Xcode/"
            let bindings = KnowledgeBaseManager.shared.authored.catalog.bindings
            let deviceRels = bindings.filter { $0.ruleID == AppConfig.RuleIDs.deviceSupport && $0.status == .active && $0.pathTemplate.hasPrefix(prefix) }.map { String($0.pathTemplate.dropFirst(prefix.count)) }
            let derivedRels = Array(Set(bindings.filter { ($0.ruleID == AppConfig.RuleIDs.derivedOrphan || $0.ruleID == AppConfig.RuleIDs.derivedLive) && $0.status == .active && $0.pathTemplate.hasPrefix(prefix) }.map { String($0.pathTemplate.dropFirst(prefix.count)) })).sorted()
            return [
                ("Device Support", "cpu",
                 deviceRels.isEmpty ? ["iOS DeviceSupport", "watchOS DeviceSupport", "tvOS DeviceSupport", "macOS DeviceSupport", "visionOS DeviceSupport"] : deviceRels,
                 "Legacy device symbolication and debug support files", .caution),
                ("DerivedData", "hammer", derivedRels.isEmpty ? ["DerivedData"] : derivedRels,
                 "Xcode build derived data and intermediate index cache", .caution),
                ("Archives", "archivebox", ["Archives"],
                 "Xcode build archives history", .caution),
                ("Module Cache", "shippingbox", ["ModuleCache.noindex", "ModuleCache"],
                 "Clang/LLVM module cache", .caution),
                ("Device Logs", "doc.text", ["iOS Device Logs", "DeviceLogs"],
                 "iOS device run logs", .caution),
                ("Documentation Cache", "book", ["DocumentationCache", "DocumentationIndex"],
                 "Xcode documentation and API reference index cache", .caution)
            ]
        }

        /// Gradle 缓存扫描根目录相对家目录
        public static var gradleRoots: [String] {
            let roots = KnowledgeBaseManager.shared.authored.catalog.bindings
                .filter { $0.status == .active && $0.pathTemplate.hasPrefix("~/.gradle/") }
                .map { String($0.pathTemplate.dropFirst(2)) }
            return roots.isEmpty ? [".gradle/caches", ".gradle/daemon"] : roots
        }

        /// Electron 应用通用缓存子目录名（移除 Service Worker/CacheStorage 可执行枚举，T03 归入只读）
        public static var electronCacheSubdirs: [String] {
            let rows = KnowledgeBaseManager.shared.authored.catalog.rows("cm_cache_subdir")
                .filter { $0["rule_id"] == AppConfig.RuleIDs.electronCache && $0["tier"] == "L1" }
                .compactMap { $0["name"] }
            return rows.isEmpty ? ["Cache", "Code Cache", "GPUCache", "DawnCache", "ShaderCache", "GrShaderCache", "GraphiteDawnCache"] : rows
        }

        /// 文档版本历史根路径
        public static let documentVersionsRoots = ["/.DocumentRevisions-V100"]

        /// CoreSymbolicationd 符号缓存备选路径
        public static let coreSymbolicationdPaths = [
            "/System/Library/Caches/com.apple.coresymbolicationd",
            "/Library/Caches/com.apple.coresymbolicationd"
        ]

        /// App Store 下载缓存相对路径
        public static var appStoreCachePath: String {
            KnowledgeBaseManager.shared.authored.catalog.bindings
                .first { $0.ruleID == AppConfig.RuleIDs.appStoreCache && !$0.pathTemplate.isEmpty }?.pathTemplate
                ?? "~/Library/Caches/com.apple.appstore"
        }

        /// JetBrains Caches 根路径与允许清理的六个叶目录（大小写敏感精确匹配）
        public static var jetBrainsCachesRoot: String {
            if let path = KnowledgeBaseManager.shared.authored.catalog.bindings.first(where: { $0.ruleID == AppConfig.RuleIDs.jetBrainsCache })?.pathTemplate,
               let range = path.range(of: "/*/") {
                return String(path[..<range.lowerBound])
            }
            return "~/Library/Caches/JetBrains"
        }
        public static var jetBrainsAllowedLeaves: [String] {
            let leaves = KnowledgeBaseManager.shared.authored.catalog.bindings
                .filter { $0.ruleID == AppConfig.RuleIDs.jetBrainsCache && $0.status == .active }
                .map { ($0.pathTemplate as NSString).lastPathComponent }
                .filter { !$0.isEmpty && $0 != "*" }
            return leaves.isEmpty ? ["caches", "index", "log", "jcef_cache", "tmp", "compile-server"] : leaves
        }
        public static var jetBrainsAllowedLeavesSet: Set<String> { Set(jetBrainsAllowedLeaves) }

        /// JetBrains 进程锁集合（与 SQL cm_junk_rule_lock 保持单一事实源一致）
        public static var jetBrainsProcessLocks: [String] {
            let locks = KnowledgeBaseManager.shared.authored.catalog.rows("cm_junk_rule_lock")
                .filter { $0["rule_id"] == AppConfig.RuleIDs.jetBrainsCache && $0["lock_kind"] == "process_name" }
                .compactMap { $0["lock_value"] }
            return locks.isEmpty ? ["idea", "pycharm", "webstorm", "goland", "clion", "rider", "datagrip", "phpstorm", "rubymine", "rustrover", "java"] : locks
        }

        /// scanUserCaches 顶层伞目录跳过集合（由专项扫描器处理或只读保护，全部小写）
        public static var userCacheUmbrellaSkipDirs: Set<String> {
            let catalog = KnowledgeBaseManager.shared.authored.catalog
            let dedicated: Set<String> = ["scanBrowserCaches", "scanDeveloperCaches", "scanJetBrainsCaches", "scanXcodeJunk", "BrewHelper.scanCacheItems"]
            var dirs = Set<String>()
            let cachesPrefix = "~/Library/Caches/"
            let supportPrefix = "~/Library/Application Support/"
            for binding in catalog.bindings {
                if dedicated.contains(binding.scannerID), binding.pathTemplate.hasPrefix(cachesPrefix) {
                    let comp = binding.pathTemplate.dropFirst(cachesPrefix.count).split(separator: "/").first.map { String($0).lowercased() } ?? ""
                    if !comp.isEmpty && !comp.contains("*") { dirs.insert(comp) }
                } else if binding.scannerID == "scanBrowserCaches", binding.pathTemplate.hasPrefix(supportPrefix) {
                    let comp = binding.pathTemplate.dropFirst(supportPrefix.count).split(separator: "/").first.map { String($0).lowercased() } ?? ""
                    if !comp.isEmpty && !comp.contains("*") { dirs.insert(comp) }
                }
            }
            for row in catalog.rows("cm_junk_rule_exclude") where row["rule_id"] == AppConfig.RuleIDs.userCache {
                if let name = row["name"]?.lowercased(), !name.isEmpty { dirs.insert(name) }
            }
            return dirs.isEmpty ? [
                "google", "com.apple.safari", "firefox", "arc", "company.thebrowser.browser",
                "bravesoftware", "microsoft edge", "vivaldi", "chromium", "com.operasoftware.opera",
                "com.apple.dt.xcode", "org.swift.swiftpm", "cocoapods", "go-build", "pip",
                "pnpm", "yarn", "ms-playwright", "node-gyp", "helm", "composer", "uv",
                "homebrew", "jetbrains"
            ] : dirs
        }

        /// 受限通配名整段正则常量（收敛于 AppConfig，供发现器与路径归一化共享）
        public enum PathMatching {
            public static let chromiumProfileName = #"\A(?:Default|Guest Profile|Profile [0-9]+)\z"#
            public static let firefoxProfileName = #"\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z"#
            public static let jetBrainsVersionName =
                #"\A(?:IntelliJIdea|IdeaIC|PyCharm|PyCharmCE|WebStorm|GoLand|CLion|Rider|DataGrip|PhpStorm|RubyMine|RustRover|Aqua|Gateway|Writerside)[0-9]{4}\.[0-9]+(?:\.[0-9]+)?\z"#
            public static let pythonVersionProcess = #"\Apython3\.[0-9]+\z"#
            public static let bundleOrContainerName = #"\A[A-Za-z0-9][A-Za-z0-9._-]{1,159}\z"#

            public static var chromiumAllowedLeaves: [String] {
                var leaves = KnowledgeBaseManager.shared.authored.catalog.rows("cm_cache_subdir")
                    .filter { $0["rule_id"] == AppConfig.RuleIDs.chromiumCache && $0["tier"] == "L1" }
                    .compactMap { $0["name"] }
                if leaves.contains("Cache/Cache_Data") && !leaves.contains("Cache") {
                    if let idx = leaves.firstIndex(of: "Cache/Cache_Data") {
                        leaves.insert("Cache", at: leaves.index(after: idx))
                    } else {
                        leaves.append("Cache")
                    }
                }
                return leaves.isEmpty ? [
                    "Cache/Cache_Data", "Cache", "Code Cache", "GPUCache",
                    "ShaderCache", "GrShaderCache", "DawnCache",
                    "GraphiteDawnCache", "DawnGraphiteCache", "DawnWebGPUCache"
                ] : leaves
            }

            public static var electronAllowedLeaves: [String] {
                var leaves = KnowledgeBaseManager.shared.authored.catalog.rows("cm_cache_subdir")
                    .filter { $0["rule_id"] == AppConfig.RuleIDs.electronCache && $0["tier"] == "L1" }
                    .compactMap { $0["name"] }
                if leaves.contains("Cache/Cache_Data"), let cacheIdx = leaves.firstIndex(of: "Cache"), let dataIdx = leaves.firstIndex(of: "Cache/Cache_Data"), cacheIdx < dataIdx {
                    leaves.remove(at: cacheIdx)
                    leaves.insert("Cache", at: dataIdx)
                }
                return leaves.isEmpty ? [
                    "Cache/Cache_Data", "Cache", "Code Cache", "GPUCache",
                    "ShaderCache", "GrShaderCache", "DawnCache",
                    "GraphiteDawnCache", "DawnGraphiteCache", "DawnWebGPUCache",
                    "CachedData"
                ] : leaves
            }

            public static var firefoxAllowedLeaves: [String] {
                let leaves = KnowledgeBaseManager.shared.authored.catalog.bindings
                    .filter { $0.ruleID == AppConfig.RuleIDs.firefoxCache && $0.status == .active }
                    .map { ($0.pathTemplate as NSString).lastPathComponent }
                    .filter { !$0.isEmpty && $0 != "*" }
                return leaves.isEmpty ? ["cache2", "startupCache"] : leaves
            }

            public static let protectedAppContextComponents: [String] = [
                "User/workspaceStorage", "User/globalStorage", "Backups",
                "LocalHistory", "Local Storage", "Session Storage",
                "IndexedDB", "History", "Login Data", "Cookies",
                "Network/Cookies", "Extensions", "Local Extension Settings",
                "Sync Extension Settings"
            ]

            public static func matchesWholeDirectoryName(_ name: String, pattern: String) -> Bool {
                guard !name.isEmpty,
                      name != ".",
                      name != "..",
                      !name.contains("/"),
                      !name.contains("\n"),
                      !name.contains("\r"),
                      !name.contains("\0") else {
                    return false
                }
                guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
                let range = NSRange(name.startIndex..<name.endIndex, in: name)
                guard let match = regex.firstMatch(in: name, options: [], range: range) else { return false }
                return match.range == range
            }
        }

        public typealias CacheMatching = PathMatching

        /// 大缓存建议配置类型入口（唯一真源为 SQL cm_rule_meta，禁止在 Swift 中复制 500 MiB / 1 GiB 常量）
        public enum CacheRecommendation {
            public static let expectedSchemaVersion = "1"
            public static let expectedPolicyVersion = "1"
            static var current: CacheRecommendationConfig {
                KnowledgeBaseManager.shared.authored.cacheRecommendationConfig
            }
        }

        /// 只读保护资产路径常量（T01/T02/T03/T04）
        public enum ProtectedAssets {
            public static let pubCachePath = "~/.pub-cache"
            public static let jetBrainsLocalHistorySuffix = "/LocalHistory"
            public static let spotifyUserCachePath = "~/Library/Caches/com.spotify.client"
            public static let spotifyPersistentStoragePath = "~/Library/Application Support/Spotify/PersistentCache/Storage"
        }
    }

    // ========================================================
    // MARK: - 4. 开发者项目构建产物深度清理配置 (Developer Project Purge)
    // ========================================================
    public enum DeveloperPurge {
        /// 规范构建目录目标名称（排除 .idea / bin / env 等含用户配置或源码脚本的目录）
        public static var targetArtifactNames: Set<String> { Set(KnowledgeBaseManager.shared.authored.catalog.rows("cm_project_artifact").filter { $0["candidate"] == "1" }.compactMap { $0["artifact_name"] }) }

        /// 默认项目扫描根目录名称列表（相对家目录）
        public static var defaultSearchDirectoryNames: [String] { KnowledgeBaseManager.shared.authored.catalog.rows("cm_project_scan_root").compactMap { $0["root_template"].flatMap { $0.hasPrefix("~/") ? String($0.dropFirst(2)) : nil } } }

        /// 解析为绝对 URL
        public static var defaultSearchDirectories: [URL] {
            let home = FileUtil.home
            return defaultSearchDirectoryNames.compactMap { rel in
                let url = home.appendingPathComponent(rel)
                return FileUtil.exists(url.path) ? url : nil
            }
        }

        /// 判定陈旧构建产物的最小未修改天数
        public static var defaultMinAgeDays: Int { max(AppConfig.RuleUpdates.minimumProjectAgeDays, Int(KnowledgeBaseManager.shared.authored.catalog.parameter("project_min_age_days") ?? "") ?? AppConfig.RuleUpdates.minimumProjectAgeDays) }

        /// 扫描项目目录树的最大递归深度
        public static var defaultMaxDepth: Int { min(AppConfig.RuleUpdates.maximumProjectDepth, Int(KnowledgeBaseManager.shared.authored.catalog.parameter("project_max_depth") ?? "") ?? AppConfig.RuleUpdates.maximumProjectDepth) }

        /// 常见通用文件夹名：必须在附近层级检验到工程配置文件才可被视作项目构建产物 (P0-03)
        public static var genericDirectoryNames: Set<String> { Set(KnowledgeBaseManager.shared.authored.catalog.rows("cm_project_artifact").filter { $0["generic_name"] == "1" }.compactMap { $0["artifact_name"] }) }

        /// 典型开发者项目清单与版本控制文件标记
        public static var projectManifestNames: Set<String> { KnowledgeBaseManager.shared.authored.catalog.values("cm_project_manifest", "name") }

        /// 检查项目清单向上追溯的最大层级深度
        public static var manifestSearchMaxDepth: Int { min(AppConfig.RuleUpdates.maximumManifestSearchDepth, Int(KnowledgeBaseManager.shared.authored.catalog.parameter("project_manifest_search_depth") ?? "") ?? AppConfig.RuleUpdates.maximumManifestSearchDepth) }

        /// Xcode 模拟器物理运行时扫描路径
        public static var simulatorPhysicalRoots: [String] {
            [
                "/Library/Developer/CoreSimulator/Volumes",
                "/Library/Developer/CoreSimulator/Profiles/Runtimes",
                FileUtil.home.appendingPathComponent("Library/Developer/CoreSimulator/Profiles/Runtimes").path
            ]
        }
    }

    // ========================================================
    // MARK: - 6. 容器与包管理器助手配置 (Docker & Homebrew Helpers)
    // ========================================================
    public enum Helpers {
        /// 严禁触碰的虚拟机磁盘镜像关键路径特征
        public static let dockerProtectedDiskMarkers: [String] = [
            ".orbstack/data",
            "Docker.raw",
            "Docker.qcow2",
            "com.docker.docker/Data/vms",
            "OrbStack/data"
        ]

        /// docker CLI 二进制查找候选路径
        public static let dockerBinaryCandidates: [String] = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "~/.docker/bin/docker",
            "~/.orbstack/bin/docker",
            "/usr/bin/docker"
        ]

        /// 宿主机物理 Docker 日志与缓存相对路径
        public static let dockerHostCandidatePaths: [(relPath: String, label: String)] = [
            ("Library/Containers/com.docker.docker/Data/cache", "Docker Host Cache"),
            ("Library/Containers/com.docker.docker/Data/log", "Docker Host Logs"),
            ("Library/Application Support/Docker Desktop/cache", "Docker Desktop Support Cache"),
            ("Library/Application Support/Docker Desktop/log", "Docker Desktop Logs"),
            ("Library/Logs/Docker Desktop", "Docker Desktop Diagnostic Logs"),
            ("Library/Caches/dev.kdrag0n.MacVirt", "OrbStack Host Cache"),
            ("Library/Logs/OrbStack", "OrbStack Logs")
        ]

        /// 允许的已知 Homebrew 缓存根目录白名单
        public static var brewKnownRoots: [String] {
            var roots = [
                "~/Library/Caches/Homebrew",
                "/Library/Caches/Homebrew",
                "/opt/homebrew/var/cache",
                "/usr/local/var/cache"
            ]
            for binding in KnowledgeBaseManager.shared.authored.catalog.bindings where binding.scannerID == "BrewHelper.scanCacheItems" && binding.status == .active && !binding.pathTemplate.isEmpty {
                if !roots.contains(binding.pathTemplate) {
                    roots.append(binding.pathTemplate)
                }
            }
            return roots
        }

        /// brew 二进制查找候选路径
        public static let brewBinaryCandidates: [String] = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew",
            "/usr/bin/brew"
        ]
    }

    // ========================================================
    // MARK: - 8. AI 垃圾与本地大模型扫描配置 (AI Clutter & Local Models)
    // ========================================================
    public enum AIClutter {
        /// 本地大模型按目录列出的存储路径
        public static var localModelSearchPaths: [(rawPath: String, label: String)] {
            var paths: [(rawPath: String, label: String)] = [
                ("~/.cache/lm-studio/models",                      "LM Studio Models"),
                ("~/Library/Application Support/LM Studio/models", "LM Studio Models"),
                ("~/.lmstudio/models",                             "LM Studio Models")
            ]
            let hfBindings = KnowledgeBaseManager.shared.authored.catalog.bindings
                .filter { $0.ruleID == AppConfig.RuleIDs.hfModel && $0.status == .active && !$0.pathTemplate.isEmpty }
                .map { ($0.pathTemplate, "Hugging Face Model Hub") }
            if hfBindings.isEmpty {
                paths.append(("~/.cache/huggingface/hub", "Hugging Face Model Hub"))
            } else {
                for item in hfBindings where !paths.contains(where: { $0.rawPath == item.0 }) {
                    paths.append(item)
                }
            }
            return paths
        }

        public struct SubLocation: Sendable {
            public let label: String
            public let path: String
            public let note: String
            public let safety: Safety
            public let isSelected: Bool

            public init(_ label: String, _ path: String, note: String = "", safety: Safety = .safe, isSelected: Bool = true) {
                self.label = label
                self.path = path
                self.note = note
                self.safety = safety
                self.isSelected = isSelected
            }
        }

        public struct ToolDefinition: Sendable {
            public let name: String
            public let note: String
            public let subs: [SubLocation]
            public let appPaths: [String]
            public let safety: Safety
            public let isSelected: Bool

            public init(name: String, note: String, subs: [SubLocation], appPaths: [String], safety: Safety = .safe, isSelected: Bool = true) {
                self.name = name
                self.note = note
                self.subs = subs
                self.appPaths = appPaths
                self.safety = safety
                self.isSelected = isSelected
            }
        }

        /// 靶向 AI 工具清单及子位置定义
        public static let toolDefinitions: [ToolDefinition] = [
            ToolDefinition(
                name: "Chrome DevTools MCP",
                note: "Chrome DevTools MCP browser kernel rendering and extensions cache",
                subs: [
                    SubLocation("Web & Page Cache (Cache)", "~/.cache/chrome-devtools-mcp/chrome-profile/Default/Cache", note: "Web static resources and response cache"),
                    SubLocation("Code Compile Cache (Code Cache)", "~/.cache/chrome-devtools-mcp/chrome-profile/Default/Code Cache", note: "V8 JavaScript bytecode compile cache"),
                    SubLocation("GPU Render Cache (GPUCache)", "~/.cache/chrome-devtools-mcp/chrome-profile/Default/GPUCache", note: "GPU shader and pipeline texture cache"),
                    SubLocation("Dawn Graphics Cache", "~/.cache/chrome-devtools-mcp/chrome-profile/Default/DawnCache", note: "WebGPU driver-layer cache"),
                    SubLocation("Shader Cache (GrShaderCache)", "~/.cache/chrome-devtools-mcp/chrome-profile/Default/GrShaderCache", note: "GPU shader precompilation cache"),
                    SubLocation("Graphite/Dawn Cache", "~/.cache/chrome-devtools-mcp/chrome-profile/Default/GraphiteDawnCache", note: "WebGPU Graphite rendering cache"),
                    SubLocation("Service Worker Cache", "~/.cache/chrome-devtools-mcp/chrome-profile/Default/Service Worker/CacheStorage", note: "Service Worker offline resource cache"),
                    SubLocation("Component Extension Cache", "~/.cache/chrome-devtools-mcp/chrome-profile/component_crx_cache", note: "Chrome component CRX cache"),
                    SubLocation("Extensions Cache", "~/.cache/chrome-devtools-mcp/chrome-profile/extensions_crx_cache", note: "Extension CRX cache")
                ],
                appPaths: ["/Applications/Google Chrome.app"]
            ),
            ToolDefinition(
                name: "Gemini / Antigravity",
                note: "Antigravity browser and GPU rendering cache (protects Brain memory and conversation context)",
                subs: [
                    SubLocation("Auto-Update Package Cache", "~/Library/Caches/antigravity-updater", note: "Downloaded client upgrade installer images"),
                    SubLocation("Application Client Cache", "~/Library/Caches/com.google.antigravity", note: "Desktop app runtime state cache"),
                    SubLocation("Internal Browser Cache", "~/.gemini/antigravity-browser-profile/Default/Cache", note: "Browser engine network cache"),
                    SubLocation("Code Compile Cache", "~/.gemini/antigravity-browser-profile/Default/Code Cache", note: "V8 bytecode cache"),
                    SubLocation("Shader Cache (GrShaderCache)", "~/.gemini/antigravity-browser-profile/Default/GrShaderCache", note: "GPU shader precompilation cache"),
                    SubLocation("Graphite/Dawn Cache", "~/.gemini/antigravity-browser-profile/Default/GraphiteDawnCache", note: "WebGPU Graphite rendering cache"),
                    SubLocation("Service Worker Cache", "~/.gemini/antigravity-browser-profile/Default/Service Worker/CacheStorage", note: "Service Worker offline resource cache"),
                    SubLocation("Component Extension Cache", "~/.gemini/antigravity-browser-profile/component_crx_cache", note: "Chrome component CRX cache"),
                    SubLocation("Extensions Cache", "~/.gemini/antigravity-browser-profile/extensions_crx_cache", note: "Extension CRX cache"),
                    SubLocation("Debug Temporary Files", "~/.gemini/tmp", note: "Temporary debugging and session data")
                ],
                appPaths: ["/Applications/Antigravity.app", "/Applications/Google Chrome.app"]
            ),
            ToolDefinition(
                name: "Codex",
                note: "Codex application tools and runtime temporary caches",
                subs: [
                    SubLocation("Runtime Environment Cache (codex-runtimes)", "~/.cache/codex-runtimes", note: "Codex offline container and toolchain cache"),
                    SubLocation("Application Server Info (codex_apps_server_info)", "~/.codex/cache/codex_apps_server_info", note: "Codex application server metadata cache"),
                    SubLocation("Application Tools Cache (codex_apps_tools)", "~/.codex/cache/codex_apps_tools", note: "Codex application toolchain cache"),
                    SubLocation("Client Session Cache", "~/Library/Caches/com.openai.codex", note: "Desktop client session cache")
                ],
                appPaths: ["/Applications/ChatGPT.app"]
            ),
            ToolDefinition(
                name: "Cursor",
                note: "Cursor cache and diagnostic logs (protects workspace configurations and agents)",
                subs: [
                    SubLocation("Cursor Agent Cache", "~/.cache/cursor-agent", note: "Intelligent agent temporary cache"),
                    SubLocation("Compilation Acceleration Cache", "~/Library/Caches/cursor-compile-cache", note: "TypeScript/V8 compilation cache"),
                    SubLocation("Runtime Diagnostic Logs", "~/Library/Logs/Cursor", note: "Runtime and diagnostic logs"),
                    SubLocation("Workspace Cache", "~/Library/Application Support/Cursor/Cache", note: "Project view and network cache"),
                    SubLocation("GPU Render Cache", "~/Library/Application Support/Cursor/GPUCache", note: "Graphics rendering pipeline cache"),
                    SubLocation("Code Compile Cache", "~/Library/Application Support/Cursor/Code Cache", note: "V8 bytecode compilation cache"),
                    SubLocation("Crash Dumps", "~/Library/Application Support/Cursor/Crashpad/completed", note: "Completed crash dump reports")
                ],
                appPaths: ["/Applications/Cursor.app"]
            ),
            ToolDefinition(
                name: "OpenCode",
                note: "OpenCode runtime logs and temporary caches (snapshots and databases strictly protected)",
                subs: [
                    SubLocation("Application Parsing Cache", "~/.cache/opencode", note: "Syntax parsing and dependency tree cache"),
                    SubLocation("Console Runtime Logs", "~/.local/share/opencode/log", note: "Execution and output logs")
                ],
                appPaths: []
            ),
            ToolDefinition(
                name: "Claude Code",
                note: "Claude CLI telemetry, downloads, and temporary caches (protects CLI versions, state JSON files, and session projects)",
                subs: [
                    SubLocation("Download Temp Files", "~/.claude/downloads", note: "Temporarily downloaded update packages and attachments"),
                    SubLocation("Telemetry Data Records", "~/.claude/telemetry", note: "CLI telemetry and diagnostic records"),
                    SubLocation("Shell Snapshots", "~/.claude/shell-snapshots", note: "Shell environment snapshot cache"),
                    SubLocation("Node.js Runtime Cache", "~/Library/Caches/claude-cli-nodejs", note: "Node.js engine runtime cache")
                ],
                appPaths: ["/Applications/Claude.app"],
                safety: .caution,
                isSelected: false
            ),
            ToolDefinition(
                name: "HuggingFace",
                note: "HuggingFace pretrained model hub temporary download cache",
                subs: [
                    SubLocation("Model Hub Download Cache", "~/.cache/huggingface", note: "Pretrained model hub chunk cache", safety: .caution, isSelected: false)
                ],
                appPaths: [],
                safety: .caution,
                isSelected: false
            )
        ]
    }
}
#endif
