import Foundation
import AppKit
import UniformTypeIdentifiers
import Darwin

// ============================================================
//  PerformanceEngine —— 系统性能维护任务与启动项/守护进程管理引擎
//
//  工业化改进：
//    1. MaintenanceTask 引入稳定 taskId，支持跨语言精确匹配与向后兼容名称匹配；
//    2. StartupItem 切换引入会话级状态覆盖表 (runtimeStateOverrides)，彻底解决
//       launchctl print 不可读时状态切换后无法逆转的缺陷；
//    3. AppleScript 登录项配置修改严格转义反斜杠与双引号，杜绝命令注入或语法中断。
// ============================================================

enum PerformanceEngine {

    private static let stateLock = NSLock()
    private static let runtimeStateOverridesStorage = LockedValue<[String: Bool]>([:])
    private static var runtimeStateOverrides: [String: Bool] {
        get { runtimeStateOverridesStorage.withValue { $0 } }
        set { runtimeStateOverridesStorage.withValue { $0 = newValue } }
    }
    private static var kStartupOverridesDefaultsKey: String { AppConfig.StorageKeys.startupOverrides }
    private static var kLegacyStartupOverridesDefaultsKey: String { AppConfig.StorageKeys.legacyStartupOverrides }

    /// 记录或查询运行时手动切换过的启动项状态（内存快取 + UserDefaults 跨重启持久化）
    static func recordStartupOverride(path: String, enabled: Bool) {
        let key = AppConfigStore.canonicalPath(path)
        guard !key.isEmpty else { return }
        stateLock.lock()
        runtimeStateOverrides[key] = enabled
        var saved = (UserDefaults.standard.dictionary(forKey: kStartupOverridesDefaultsKey) as? [String: Bool])
            ?? (UserDefaults.standard.dictionary(forKey: kLegacyStartupOverridesDefaultsKey) as? [String: Bool])
            ?? [:]
        saved[key] = enabled
        UserDefaults.standard.set(saved, forKey: kStartupOverridesDefaultsKey)
        stateLock.unlock()
    }

    static func startupOverride(for path: String) -> Bool? {
        let key = AppConfigStore.canonicalPath(path)
        guard !key.isEmpty else { return nil }
        stateLock.lock()
        defer { stateLock.unlock() }
        if let mem = runtimeStateOverrides[key] {
            return mem
        }
        let saved = (UserDefaults.standard.dictionary(forKey: kStartupOverridesDefaultsKey) as? [String: Bool])
            ?? (UserDefaults.standard.dictionary(forKey: kLegacyStartupOverridesDefaultsKey) as? [String: Bool])
        if let val = saved?[key] {
            runtimeStateOverrides[key] = val
            return val
        }
        return nil
    }

    static func memoryInfo() -> (total: Int64, used: Int64, pressure: MemoryPressureLevel) {
        memoryInfo(
            vmStatOutput: Shell.run(AppConfig.Maintenance.memoryStatisticsExecutable, []),
            total: Int64(ProcessInfo.processInfo.physicalMemory),
            pageSize: Int64(getpagesize())
        )
    }

    static func memoryInfo(vmStatOutput: String, total: Int64, pageSize: Int64)
        -> (total: Int64, used: Int64, pressure: MemoryPressureLevel) {
        func pages(_ label: String) -> Int64 {
            for line in vmStatOutput.split(separator: "\n") where line.hasPrefix(label) {
                guard let colon = line.firstIndex(of: ":") else { continue }
                let digits = String(line[line.index(after: colon)...].filter { $0.isNumber })
                return Int64(digits) ?? 0
            }
            return 0
        }
        let used = (pages("Pages wired down") + pages("Pages active") + pages("Pages occupied by compressor")) * pageSize
        let ratio = total > 0 ? Double(used) / Double(total) : 0
        let pressure: MemoryPressureLevel = ratio > AppConfig.Maintenance.memoryCriticalUsageRatio
            ? .critical : (ratio > AppConfig.Maintenance.memoryWarningUsageRatio ? .warning : .normal)
        return (total, min(total, max(0, used)), pressure)
    }

    static func cpuLoad() -> Double {
        let la = Shell.run("/usr/sbin/sysctl", ["-n", "vm.loadavg"])
        let cleaned = la.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")
        let parts = cleaned.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        if let first = parts.first, let v = Double(first) { return v }
        return 0
    }

    // MARK: - 启动项管理

    struct LaunchdSnapshot {
        var loaded: Set<String> = []
        var disabled: Set<String> = []
        var guiReadable = false
        var systemReadable = false
    }

    private static func parseLaunchdDomain(_ out: String) -> (loaded: Set<String>, disabled: Set<String>, readable: Bool) {
        guard !out.isEmpty else { return ([], [], false) }
        var loaded = Set<String>()
        var disabled = Set<String>()
        var section = ""
        for raw in out.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = String(raw).trimmingCharacters(in: .whitespaces)
            if trimmed == "services = {" { section = "services"; continue }
            if trimmed == "disabled services = {" { section = "disabled"; continue }
            if trimmed == "attractive services = {" { section = "attractive"; continue }
            if trimmed == "}" { section = ""; continue }
            if section == "services" {
                let cols = trimmed.split(whereSeparator: { $0 == "\t" || $0 == " " }).map(String.init)
                if let label = cols.last, !label.isEmpty, label != "-" { loaded.insert(label) }
            } else if section == "disabled" {
                guard let arrow = trimmed.range(of: "=>") else { continue }
                let label = trimmed[..<arrow.lowerBound]
                    .trimmingCharacters(in: CharacterSet(charactersIn: " \"\t"))
                let val = trimmed[arrow.upperBound...].trimmingCharacters(in: .whitespaces)
                if val == "disabled" && !label.isEmpty { disabled.insert(label) }
            }
        }
        return (loaded, disabled, true)
    }

    static func launchdSnapshot() -> LaunchdSnapshot {
        var snap = LaunchdSnapshot()
        let uid = getuid()
        let gui = parseLaunchdDomain(Shell.run("/bin/launchctl", ["print", "gui/\(uid)"], timeout: 8))
        snap.loaded.formUnion(gui.loaded)
        snap.disabled.formUnion(gui.disabled)
        snap.guiReadable = gui.readable

        let guiDis = parseLaunchdDomain(Shell.run("/bin/launchctl", ["print-disabled", "gui/\(uid)"], timeout: 4))
        snap.disabled.formUnion(guiDis.disabled)

        let sys = parseLaunchdDomain(Shell.run("/bin/launchctl", ["print", "system"], timeout: 8))
        snap.loaded.formUnion(sys.loaded)
        snap.disabled.formUnion(sys.disabled)
        snap.systemReadable = sys.readable

        let sysDis = parseLaunchdDomain(Shell.run("/bin/launchctl", ["print-disabled", "system"], timeout: 4))
        snap.disabled.formUnion(sysDis.disabled)

        return snap
    }

    private static func isPlistDisabledByKey(_ plist: URL) -> Bool {
        guard let d = FileManager.default.contents(atPath: plist.path),
              let pd = try? PropertyListSerialization.propertyList(from: d, format: nil) as? [String: Any] else {
            return false
        }
        if let dis = pd["Disabled"] as? Bool {
            return dis
        }
        return false
    }

    private static func launchdLabel(of plist: URL) -> String {
        if let d = FileManager.default.contents(atPath: plist.path),
           let pd = try? PropertyListSerialization.propertyList(from: d, format: nil) as? [String: Any],
           let l = pd["Label"] as? String, !l.isEmpty {
            return l
        }
        return plist.deletingPathExtension().lastPathComponent
    }

    static func fetchSystemLoginItems() -> [StartupItem] {
        let script = """
        tell application "System Events"
            set outList to {}
            repeat with i in login items
                set itemName to ""
                set itemPath to ""
                try
                    set itemName to name of i as text
                end try
                try
                    set itemPath to POSIX path of (path of i as alias)
                on error
                    try
                        set itemPath to path of i as text
                    end try
                end try
                set end of outList to itemName & "|||" & itemPath
            end repeat
            set AppleScript's text item delimiters to "\\n"
            return outList as text
        end tell
        """
        var error: NSDictionary?
        var items: [StartupItem] = []
        if let appleScript = NSAppleScript(source: script) {
            let res = appleScript.executeAndReturnError(&error)
            if let output = res.stringValue, !output.isEmpty {
                let lines = output.components(separatedBy: "\n")
                for line in lines {
                    let parts = line.components(separatedBy: "|||")
                    guard parts.count >= 2 else { continue }
                    let name = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let p = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { continue }
                    let exists = !p.isEmpty && FileUtil.exists(p)
                    let iconImg: NSImage? = exists ? NSWorkspace.shared.icon(forFile: p) : NSWorkspace.shared.icon(for: .application)
                    let effectiveEnabled = startupOverride(for: p) ?? true
                    items.append(StartupItem(
                        name: name,
                        path: p,
                        scope: tr(.loginItem),
                        program: p,
                        broken: !exists,
                        enabled: effectiveEnabled,
                        stateKnown: true,
                        isBackground: false,
                        displayName: name,
                        appPath: p.hasSuffix(".app") ? p : nil,
                        iconImage: iconImg
                    ))
                }
            }
        }
        return items
    }

    static func startupItems() -> [StartupItem] {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        var out: [StartupItem] = []

        // 1. 真实的开机登录项 (Open at Login)
        let loginItems = fetchSystemLoginItems()
        out.append(contentsOf: loginItems)
        let loginPaths = Set(loginItems.map { $0.path }.filter { !$0.isEmpty })

        // 2. LaunchAgents & LaunchDaemons (后台项目)
        let snap = launchdSnapshot()
        let dirs: [(RuleRoot, String, String)] = [
            (.homeLibrary, "LaunchAgents", tr(.userAgent)),
            (.rootLibrary, "LaunchAgents", tr(.globalAgent)),
            (.rootLibrary, "LaunchDaemons", tr(.systemDaemon)),
        ]
        for (root, sub, scope) in dirs {
            let dir = root.base.appendingPathComponent(sub)
            guard FileUtil.exists(dir.path) else { continue }
            let isDaemon = (sub == "LaunchDaemons")
            for f in FileUtil.children(of: dir) where f.pathExtension == "plist" {
                let prog = JunkEngine.programPath(of: f) ?? ""
                let broken = !prog.isEmpty && JunkEngine.resolveExecutablePath(prog) == nil

                var appPath: String? = nil
                var displayName = f.lastPathComponent
                var iconImg: NSImage? = nil

                if !prog.isEmpty {
                    let parts = prog.split(separator: "/")
                    if let appIdx = parts.firstIndex(where: { $0.hasSuffix(".app") }) {
                        let potentialApp = "/" + parts[0...appIdx].joined(separator: "/")
                        if FileManager.default.fileExists(atPath: potentialApp) {
                            appPath = potentialApp
                            let bundleName = (potentialApp as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
                            displayName = bundleName
                            iconImg = NSWorkspace.shared.icon(forFile: potentialApp)
                        }
                    }
                }

                if iconImg == nil {
                    iconImg = NSWorkspace.shared.icon(forFile: f.path)
                }

                let label = launchdLabel(of: f)
                let readable = isDaemon ? snap.systemReadable : snap.guiReadable
                let overrideState = startupOverride(for: f.path)
                let isExplicitlyDisabled = snap.disabled.contains(label) || isPlistDisabledByKey(f)
                let enabledNow: Bool
                let stateKnownNow: Bool
                if let overrideState {
                    enabledNow = overrideState
                    stateKnownNow = true
                } else if readable {
                    enabledNow = !isExplicitlyDisabled
                    stateKnownNow = true
                } else {
                    enabledNow = !isExplicitlyDisabled
                    stateKnownNow = false
                }

                // 区分「开机启动项」(isBackground == false) 与「后台服务」(isBackground == true)：
                // - LaunchDaemons、Homebrew 服务 (homebrew.mxcl.*) 以及带 daemon / service / xpc / helper 特征的守护代理归入「后台服务」
                // - 其余随用户登录自启的 LaunchAgents 归入「启动项」
                let fileLow = f.lastPathComponent.lowercased()
                let progLow = prog.lowercased()
                let isBrewService = fileLow.hasPrefix("homebrew.mxcl.") || progLow.contains("/cellar/") || progLow.contains("/opt/homebrew/")
                let isDaemonLikeAgent = fileLow.contains("daemon")
                    || fileLow.contains("service")
                    || fileLow.contains("helper")
                    || progLow.contains(".xpc")
                    || progLow.contains("daemon")
                    || progLow.contains("/privilegedhelpertools/")
                let isBgService = isDaemon || isBrewService || isDaemonLikeAgent
                let resolvedScope = isBrewService ? tr(.brewService) : scope

                out.append(StartupItem(name: f.deletingPathExtension().lastPathComponent,
                                       path: f.path, scope: resolvedScope, program: prog,
                                       broken: broken, enabled: enabledNow, stateKnown: stateKnownNow,
                                       isBackground: isBgService,
                                       displayName: displayName, appPath: appPath, iconImage: iconImg))
            }
        }

        // 3. 现代 macOS 13+ BackgroundTaskManagement (BTM) 伴随服务与 Helper
        let btmURL = RuleRoot.homeLibrary.base
            .appendingPathComponent("Application Support/com.apple.backgroundtaskmanagementagent/backgrounditems.btm")
        if FileUtil.exists(btmURL.path),
           let data = try? Data(contentsOf: btmURL),
           let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
           let objects = plist["$objects"] as? [Any] {
            var seen = Set<String>()
            for obj in objects {
                guard let d = obj as? Data, d.count > 100 else { continue }
                var resolvedPath: String? = nil
                var isStale = false
                if let u = try? URL(resolvingBookmarkData: d, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale) {
                    resolvedPath = u.path
                } else if let vals = URL.resourceValues(forKeys: [.pathKey], fromBookmarkData: d), let p = vals.path {
                    resolvedPath = p
                }
                guard let p = resolvedPath, !seen.contains(p) else { continue }
                seen.insert(p)
                guard !loginPaths.contains(p) else { continue }

                let exists = FileUtil.exists(p)
                let itemURL = URL(fileURLWithPath: p)
                let name = itemURL.deletingPathExtension().lastPathComponent
                let iconImg: NSImage? = exists ? NSWorkspace.shared.icon(forFile: p) : NSWorkspace.shared.icon(for: .application)

                var mainAppPath: String? = p.hasSuffix(".app") ? p : nil
                if p.contains(".app/Contents/") {
                    let parts = p.split(separator: "/")
                    if let idx = parts.firstIndex(where: { $0.hasSuffix(".app") }) {
                        mainAppPath = "/" + parts[0...idx].joined(separator: "/")
                    }
                }

                // 顶层 .app 或 LoginItems 目录下的 Helper 归入「启动项」，其余底层 XPC/Daemon 归入「后台服务」
                let isLoginAppOrHelper = (p.hasSuffix(".app") && !p.contains(".app/Contents/"))
                    || p.contains(".app/Contents/Library/LoginItems/")
                let itemScope = isLoginAppOrHelper
                    ? tr(.loginHelperItem)
                    : tr(.categoryBackgroundServices)

                out.append(StartupItem(name: name,
                                       path: p,
                                       scope: itemScope,
                                       program: p,
                                       broken: !exists,
                                       enabled: exists,
                                       stateKnown: false,
                                       isBackground: !isLoginAppOrHelper,
                                       displayName: name,
                                       appPath: mainAppPath,
                                       iconImage: iconImg,
                                       managedBySystemSettings: true))
            }
        }

        // 4. 向后兼容旧版 loginitems.plist
        if loginItems.isEmpty {
            let legacy = RuleRoot.homeLibrary.base
                .appendingPathComponent("Preferences/com.apple.loginitems.plist")
            if let d = FileManager.default.contents(atPath: legacy.path),
               let plist = try? PropertyListSerialization.propertyList(from: d, format: nil) as? [String: Any],
               let items = plist["SessionItems"] as? [String: Any],
               let customs = items["CustomListItems"] as? [[String: Any]] {
                for c in customs {
                    guard let name = c["Name"] as? String else { continue }
                    out.append(StartupItem(name: name, path: legacy.path, scope: tr(.loginItem),
                                           program: "", broken: false, enabled: true,
                                           stateKnown: false,
                                           isBackground: false, displayName: name,
                                           appPath: nil, iconImage: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app"),
                                           managedBySystemSettings: true))
                }
            }
        }

        return out.sorted {
            let n0 = $0.displayName.isEmpty ? $0.name : $0.displayName
            let n1 = $1.displayName.isEmpty ? $1.name : $1.displayName
            return n0.localizedCaseInsensitiveCompare(n1) == .orderedAscending
        }
    }

    private static func escapeAppleScriptString(_ raw: String) -> String {
        raw.replacingOccurrences(of: "\\", with: "\\\\")
           .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func escapeShellSingleQuoted(_ raw: String) -> String {
        raw.replacingOccurrences(of: "'", with: "'\\''")
    }

    /// 启用 / 停用启动项与后台服务 (.plist 走 launchctl enable/bootstrap 与 disable/bootout；系统登录项走 System Events)
    static func setEnabled(_ item: StartupItem, enabled: Bool) -> Bool {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        guard !item.managedBySystemSettings else { return false }
        let blocked = KnowledgeBaseManager.shared.authored.catalog.values("cm_launchd_protected_prefix", "prefix")
        let protectedLabel = item.path.hasSuffix(".plist") ? launchdLabel(of: URL(fileURLWithPath: item.path)) : item.program
        guard RuleTaskGate.shared.allows(item.ruleIdentity), !blocked.contains(where: { protectedLabel.hasPrefix($0) }) else { return false }
        if !item.path.hasSuffix(".plist") {
            let escapedPath = escapeAppleScriptString(item.path)
            let escapedName = escapeAppleScriptString(item.name)
            let script: String
            if enabled {
                script = """
                tell application "System Events"
                    if not (exists (login item "\(escapedName)")) then
                        make login item at end with properties {path:"\(escapedPath)", hidden:false}
                    end if
                    return 1
                end tell
                """
            } else {
                script = """
                tell application "System Events"
                    set removedCount to 0
                    try
                        set matchItems to (every login item whose name is "\(escapedName)")
                        repeat with anItem in matchItems
                            delete anItem
                            set removedCount to removedCount + 1
                        end repeat
                    end try
                    try
                        set matchPathItems to (every login item whose path is "\(escapedPath)")
                        repeat with anItem in matchPathItems
                            delete anItem
                            set removedCount to removedCount + 1
                        end repeat
                    end try
                    return removedCount
                end tell
                """
            }
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                let res = appleScript.executeAndReturnError(&error)
                let ok = (error == nil) && (enabled || res.int32Value > 0)
                if ok {
                    recordStartupOverride(path: item.path, enabled: enabled)
                    if !enabled {
                        let binName = (item.path as NSString).lastPathComponent
                        if !binName.isEmpty && binName != "Finder.app" && !item.path.hasPrefix("/System/") {
                            _ = Shell.execute("/usr/bin/pkill", ["-f", item.path])
                        }
                    }
                }
                return ok
            }
            return false
        }

        let fileURL = URL(fileURLWithPath: item.path)
        let label = launchdLabel(of: fileURL)
        let uid = getuid()
        let isDaemon = item.path.contains("/Library/LaunchDaemons")
        // Global daemon mutation accepts arbitrary third-party paths; never escalate it through a generic command API.
        guard !isDaemon else { return false }
        let domain = "gui/\(uid)"
        let target = "\(domain)/\(label)"

        if enabled {
            // MARK: 启用服务 (Enable -> Bootstrap / Kickstart)
            var success = false
            if !isDaemon {
                let enableRes = Shell.execute("/bin/launchctl", ["enable", target])
                let bootRes = Shell.execute("/bin/launchctl", ["bootstrap", domain, item.path])
                if enableRes.isSuccess || bootRes.isSuccess {
                    success = true
                } else {
                    let kickRes = Shell.execute("/bin/launchctl", ["kickstart", "-k", target])
                    if kickRes.isSuccess {
                        success = true
                    }
                }
            }


            if success {
                recordStartupOverride(path: item.path, enabled: true)
                return true
            }
            return false
        } else {
            // MARK: 停用服务 (Disable -> Bootout)
            var success = false
            if !isDaemon {
                // 1. 在 gui/<uid> 域持久化禁用服务（即使下次开机或重新登录也不会启动）
                let disRes = Shell.execute("/bin/launchctl", ["disable", target])
                // 2. 尝试停止并卸载当前活跃实例（无论进程是否正在运行，忽略未运行报错）
                _ = Shell.execute("/bin/launchctl", ["bootout", target])
                _ = Shell.execute("/bin/launchctl", ["bootout", domain, item.path])

                if disRes.isSuccess {
                    success = true
                }
            }


            if success {
                recordStartupOverride(path: item.path, enabled: false)
                return true
            }
            return false
        }
    }

    // MARK: - 维护任务

    struct MaintenanceTask: Identifiable {
        var ruleIdentity: RuleIdentity? = RuleTaskGate.shared.identity
        var taskId: String
        var id: String { taskId }
        var name: String
        var detail: String
        var command: String
        var needsAdmin: Bool
        var asset: String

        init(taskId: String = "", name: String, detail: String, command: String, needsAdmin: Bool, asset: String) {
            self.taskId = taskId.isEmpty ? command : taskId
            self.name = name
            self.detail = detail
            self.command = command
            self.needsAdmin = needsAdmin
            self.asset = asset
        }
    }

    static func hasLocalSnapshots() -> Bool {
        let r = Shell.run("/usr/bin/tmutil", ["listlocalsnapshots", "/"])
        return r.contains("com.apple.TimeMachine")
    }

    static func maintenanceTasks() -> [MaintenanceTask] {
        [
            .init(taskId: "freeRAM",
                  name: tr(.freeRAM),
                  detail: tr(.freeUpInactiveMemoryDesc),
                  command: "freeRAM", needsAdmin: false,
                  asset: "cm_detail_maintenance-tasks_free-up-ram"),
            .init(taskId: "purgeableSpace",
                  name: tr(.freePurgeableSpace),
                  detail: tr(.macosMarksSpaceAsPurgeableWhenItCanBeSafelyReclaimedIfMoreStorageIsNeededThisIncludesTemporaryCachesAndFilesThatCanBeRedownloadedOrRecreatedWithoutAffectingCriticalData),
                  command: ([AppConfig.SystemReclaim.tmutilPath] + AppConfig.SystemReclaim.snapshotThinningArguments).joined(separator: " "), needsAdmin: true,
                  asset: "cm_detail_maintenance-tasks_purgeable-spaсe"),
            .init(taskId: "flushDNS",
                  name: tr(.flushDNSCache),
                  detail: tr(.macosKeepsALocalCacheOfResolvedDnsQueriesForAWhileButSometimesYouNeedToResetItImmediatelySuchAsAfterServerChangesOrNewDomainRecords),
                  command: "dscacheutil -flushcache && killall -HUP mDNSResponder", needsAdmin: true,
                  asset: "cm_detail_maintenance-tasks_flush-DNS-cache"),
            .init(taskId: "quickLookCache",
                  name: tr(.resetQuickLookIconCache),
                  detail: tr(.restartQuickLookAndIconCachesDesc),
                  command: "qlmanage -r && qlmanage -r cache", needsAdmin: false,
                  asset: "cm_detail_maintenance-tasks_flush-DNS-cache"),
            .init(taskId: "disableDSStore",
                  name: tr(.disableNetworkUsbDSStore),
                  detail: tr(.preventNetworkDsStoreFilesDesc),
                  command: "defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true && defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true", needsAdmin: false,
                  asset: "cm_detail_maintenance-tasks_repair-disk-permission"),
            .init(taskId: "vacuumDatabases",
                  name: tr(.compactLocalAppDatabases),
                  detail: tr(.sqliteVacuumCompactDatabasesDesc),
                  command: "vacuumDatabases", needsAdmin: false,
                  asset: "cm_detail_maintenance-tasks_speed-up-mail"),
            .init(taskId: "reindexSpotlight",
                  name: tr(.reindexSpotlight),
                  detail: tr(.rebuildSpotlightSearchIndexDesc),
                  command: "reindexSpotlight", needsAdmin: true,
                  asset: "cm_detail_maintenance-tasks_reindex-spotligt"),
            .init(taskId: "thinTimeMachine",
                  name: tr(.thinTimeMachineSnapshots),
                  detail: tr(.timeMachineIsIndispensableForDataRecoveryItsOnlyDownsideIsTheLargeAmountOfSpaceBackupsConsumeThinningTimeMachineLocalSnapshotsReclaimsSpaceWithoutLosingBackups),
                  command: ([AppConfig.SystemReclaim.tmutilPath] + AppConfig.SystemReclaim.snapshotThinningArguments).joined(separator: " "), needsAdmin: true,
                  asset: "cm_detail_maintenance-tasks_time-machine"),
        ].filter { $0.taskId != "freeRAM" && $0.command != "vacuumDatabases" }.filter(ruleAllowsTask)
    }

    /// 「修复小毛病」快速系统修复项（全部用户态安全重启，无需管理员权限）
    static func quickGlitchFixes() -> [MaintenanceTask] {
        [
            .init(taskId: "fixInputMethod",
                  name: L10n.localized(.inputMethodLagFix),
                  detail: tr(.restartInputMethodServiceDesc),
                  command: "killall SCIM SCIM_Extension TextInputMenuAgent TextInputSwitcher",
                  needsAdmin: false,
                  asset: "keyboard.badge.ellipsis"),
            .init(taskId: "fixNotificationCenter",
                  name: L10n.localized(.notificationCenterLagFix),
                  detail: tr(.restartNotificationCenterServiceDesc),
                  command: "killall NotificationCenter usernoted",
                  needsAdmin: false,
                  asset: "bell.badge.fill"),
            .init(taskId: "fixClipboardHandoff",
                  name: L10n.localized(.clipboardHandoffFix),
                  detail: tr(.restartClipboardAndAirDropServiceDesc),
                  command: "killall pboard sharingd",
                  needsAdmin: false,
                  asset: "doc.on.clipboard.fill"),
            .init(taskId: "fixFinderDock",
                  name: L10n.localized(.finderDockRefresh),
                  detail: tr(.safelyRestartFinderAndDockDesc),
                  command: "killall Finder Dock",
                  needsAdmin: false,
                  asset: "menubar.dock.rectangle"),
        ].filter(ruleAllowsTask)
    }

    private static func ruleAllowsTask(_ task: MaintenanceTask) -> Bool {
        guard let row = KnowledgeBaseManager.shared.authored.catalog.rows("cm_performance_task").first(where: { $0["task_id"] == task.taskId }),
              row["status"] == "allowed", row["needs_admin"] == (task.needsAdmin ? "1" : "0") else { return false }
        return RuleTaskGate.shared.allows(task.ruleIdentity, ruleID: "maint:" + task.taskId)
    }

    /// 严格按稳定注册表 taskId 查找系统维护任务（执行期零模糊匹配契约）
    static func findRegisteredTask(byTaskID taskID: String) -> MaintenanceTask? {
        guard !taskID.isEmpty else { return nil }
        return (maintenanceTasks() + quickGlitchFixes()).first { $0.taskId == taskID }
    }

    /// 严格禁止触碰的核心敏感数据库路径（DNA 宪章红线）
    private static var forbiddenDbMarkers: [String] { AppConfig.Paths.forbiddenDbMarkers + Array(KnowledgeBaseManager.shared.authored.catalog.values("cm_vacuum_forbidden", "marker")) }

    /// 真实触发内存压力释放 Inactive 内存
    static func freeRAM() -> Bool {
        // macOS manages pressure and compression. Allocating gigabytes is not an optimization.
        return false
    }

    /// 兼容旧测试名：对本地非邮件敏感应用 SQLite 数据库执行 VACUUM
    static func vacuumNonMailDatabases() -> Bool {
        vacuumDatabases()
    }

    /// 对本地非敏感应用 SQLite 数据库执行 VACUUM 碎片整理
    static func vacuumDatabases() -> Bool {
        // No schema/ownership-specific VACUUM rules exist. Never mutate arbitrary third-party DBs.
        return false
    }

    /// 系统定期脚本（执行 macOS 标准 periodic 维护脚本）
    static func runMaintenanceScripts() -> Bool {
        if FileManager.default.fileExists(atPath: "/usr/sbin/periodic") {
            return PrivilegedMaintenanceClient.run("runMaintenanceScripts")
        }
        // 若系统未提供 /usr/sbin/periodic，安全返回 false，绝不越权执行 log erase --all 或全局 find -delete
        return false
    }

    /// 智能重建 Spotlight 索引
    static func smartReindexSpotlight() -> Bool {
        return PrivilegedMaintenanceClient.run("reindexSpotlight")
    }

    enum TaskExecutionResult: Equatable, Sendable {
        case succeeded
        case targetNotRunning
        case failed(String)

        var isSuccess: Bool {
            if case .succeeded = self { return true }
            return false
        }
    }

    static func executeTask(
        _ t: MaintenanceTask,
        shellExecutor: ((String, [String]) -> ShellResult)? = nil
    ) -> TaskExecutionResult {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        guard RuleTaskGate.shared.allows(t.ruleIdentity, ruleID: "maint:" + t.taskId),
              let registered = findRegisteredTask(byTaskID: t.taskId),
              registered.command == t.command,
              registered.needsAdmin == t.needsAdmin else {
            return .failed(L10n.localized(.failedOrCancelled))
        }
        let exec = shellExecutor ?? { bin, args in Shell.execute(bin, args) }
        switch registered.command {
        case "freeRAM":
            return freeRAM() ? .succeeded : .failed(L10n.localized(.failedOrCancelled))
        case "vacuumDatabases":
            return vacuumDatabases() ? .succeeded : .failed(L10n.localized(.failedOrCancelled))
        case "runMaintenanceScripts":
            return runMaintenanceScripts() ? .succeeded : .failed(L10n.localized(.failedOrCancelled))
        case "reindexSpotlight":
            return smartReindexSpotlight() ? .succeeded : .failed(L10n.localized(.failedOrCancelled))
        default:
            if registered.needsAdmin {
                let helperTaskID = (registered.taskId == "purgeableSpace") ? "thinTimeMachine" : registered.taskId
                return PrivilegedMaintenanceClient.run(helperTaskID)
                    ? .succeeded
                    : .failed(L10n.localized(.failedOrCancelled))
            }
            if registered.command.hasPrefix("killall ") {
                let targets = registered.command
                    .dropFirst("killall ".count)
                    .split(separator: " ")
                    .map(String.init)
                    .filter { !$0.isEmpty }
                guard !targets.isEmpty else {
                    return .failed(L10n.localized(.failedOrCancelled))
                }
                var restartedCount = 0
                var notRunningCount = 0
                for target in targets {
                    let res = exec("/usr/bin/killall", [target])
                    if res.isSuccess {
                        restartedCount += 1
                    } else {
                        let combined = (res.stderr + "\n" + res.stdout).lowercased()
                        if combined.contains("no matching processes") && !combined.contains("not permitted") {
                            notRunningCount += 1
                        } else {
                            let detail = res.stderr.isEmpty ? res.stdout : res.stderr
                            return .failed(detail.isEmpty ? L10n.localized(.failedOrCancelled) : detail)
                        }
                    }
                }
                if restartedCount > 0 {
                    return .succeeded
                }
                if notRunningCount == targets.count {
                    return .targetNotRunning
                }
                return .failed(L10n.localized(.failedOrCancelled))
            }
            let res = exec("/bin/zsh", ["-c", registered.command])
            if res.isSuccess {
                return .succeeded
            }
            let detail = res.stderr.isEmpty ? res.stdout : res.stderr
            return .failed(detail.isEmpty ? L10n.localized(.failedOrCancelled) : detail)
        }
    }

    @discardableResult
    static func runTask(_ t: MaintenanceTask) -> Bool {
        executeTask(t).isSuccess
    }

}
