import Foundation
import AppKit
import CoreServices

// MARK: - 卸载器引擎
//
// 依据 rea 证据,UninstallerScanning 由 20+ 个 Fetcher 组成:
//   ApplicationContainer / ApplicationHelp / ApplicationSavedState / ApplicationSupportDirectory /
//   Caches / Cookies / CrashLogs / DockIcon / DownloadFiles / ExtraFilesForSandboxedApplication /
//   LaunchDemons / LibraryPaths / LoginItems / Logs / PDFServices / PackageManager /
//   PluginResources / Plugins / PreferencesFiles / Receipt / Resource
//
// 当前规则来源：cm_uninstall_template，经 UninstallSafety 精确归属。
// ApplicationFiles 旧 Owner 错配已隔离；模糊名称和正则不产生可执行目标。
// 同款副本、共享 App Group、邮件、会话和系统组件按保守策略保留。

enum UninstallerEngine {

    private static var kb: KnowledgeBaseManager { KnowledgeBaseManager.shared }

    // MARK: 应用列表 

    /// 目录递归深度上限。
    ///
    /// 关键实测案例：`/Applications/Epson Software/Easy Photo Print/QuickPrint/QuickPrintA.app`
    /// —— Epson 打印机的 QuickPrint 小工具是**纯 32 位**（ppc + i386）应用，
    /// 正是原版「已发现 N 个不支持的应用程序」卡片列出的条目。
    /// 它藏在 /Applications 下第 3 层目录里，且**未被 LaunchServices 注册**
    /// （`_LSCopyAllApplicationURLs` 只返回 `/Library/Printers/EPSON/...` 下的
    ///   Epson Printer Utility Lite / 4.app，不含它），因此只有文件系统递归才能找到。
    /// 旧实现只往下看 1 层，导致 QuickPrintA/B 从未进入候选集。
    private static var kAppScanMaxDepth: Int { AppConfig.Uninstaller.appScanMaxDepth }

    /// 递归收集目录下的 `.app`。
    ///
    /// 铁律：**只递归「非 .app 目录」，绝不进入 .app 包内部**。
    /// 否则 Electron 的 `Contents/Frameworks/… Helper.app`、Sparkle 的
    /// `Updater.app`、`node_modules/@byted-solo/…` 内嵌 app 都会被当成独立应用，
    /// 实测会把应用数从 75 个暴涨到 200+ 个（原版量级为 75 ~ 82）。
    ///
    /// 同时跳过隐藏目录与 `node_modules` / `.git`，避免无谓遍历大目录。
    static func collectApplications(in dir: String, depth: Int = 0, into out: inout [URL]) {
        guard depth < kAppScanMaxDepth,
              let items = try? FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: dir), includingPropertiesForKeys: nil) else { return }

        for item in items {
            if item.pathExtension == "app" {
                out.append(item)
                continue
            }
            let name = item.lastPathComponent
            if name.hasPrefix(".") || name == "node_modules" { continue }
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir),
                  isDir.boolValue else { continue }
            collectApplications(in: item.path, depth: depth + 1, into: &out)
        }
    }

    struct AppIdentity {
        let name: String
        let bundleID: String
        let url: URL
    }

    /// 极速读取本机已安装应用身份信息（仅读 Info.plist，不递归测量体积、不抓取图标、不深搜 Downloads）
    static func fastInstalledAppIdentities() -> [AppIdentity] {
        let fm = FileManager.default
        var candidateURLs: [URL] = []
        let searchDirs = AppConfig.Uninstaller.allAppScanDirectories
        for d in searchDirs {
            collectApplications(in: d, into: &candidateURLs)
        }

        var results: [AppIdentity] = []
        var seen = Set<String>()

        for item in candidateURLs {
            let p = item.standardizedFileURL.path
            if p.hasPrefix("/System") || p.contains(".app/Contents/") || p.contains("node_modules") || item.standardizedFileURL == Bundle.main.bundleURL.standardizedFileURL { continue }
            guard !seen.contains(p) else { continue }
            seen.insert(p)

            var infoPlist = item.appendingPathComponent("Contents/Info.plist")
            let rawName = item.deletingPathExtension().lastPathComponent
            if !fm.fileExists(atPath: infoPlist.path) {
                let wrapper = item.appendingPathComponent("Wrapper")
                if let subs = try? fm.contentsOfDirectory(at: wrapper, includingPropertiesForKeys: nil) {
                    for s in subs where s.pathExtension == "app" {
                        infoPlist = s.appendingPathComponent("Info.plist")
                        break
                    }
                }
            }

            var bid = ""
            var name = rawName
            if let data = try? Data(contentsOf: infoPlist),
               let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                bid = (dict["CFBundleIdentifier"] as? String) ?? ""
                if let disp = dict["CFBundleDisplayName"] as? String, !disp.isEmpty, !disp.hasPrefix("com.") {
                    name = disp
                } else if let cfn = dict["CFBundleName"] as? String, !cfn.isEmpty, !cfn.hasPrefix("com.") {
                    name = cfn
                }
            }
            results.append(AppIdentity(name: name, bundleID: bid, url: item))
        }
        return results
    }

    /// 记录全量已安装应用实例（包含跨目录同款/同 BundleID 副本，不进行展示去重，供幸存者守卫与安全索引调用）(F7)
    private static let allInstalledAppInstancesStorage = LockedValue<[InstalledApp]>([])
    static var allInstalledAppInstances: [InstalledApp] {
        get { allInstalledAppInstancesStorage.withValue { $0 } }
        set { allInstalledAppInstancesStorage.withValue { $0 = newValue } }
    }

    static func installedApps() -> [InstalledApp] {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        let fm = FileManager.default
        var candidateURLs: [URL] = []

        // 1. 标准扫描目录 (/Applications, ~/Applications, ~/Downloads, PortableSSD, WebEx)
        candidateURLs = fastInstalledAppIdentities().map(\.url)

        var apps: [InstalledApp] = []
        var allInstances: [InstalledApp] = []
        var seen = Set<String>()
        var seenPaths = Set<String>()

        // 预取系统运行中应用集合
        let runningApps = NSWorkspace.shared.runningApplications
        var runningBIDs = Set<String>()
        var runningPaths = Set<String>()
        for r in runningApps {
            if let b = r.bundleIdentifier?.lowercased() {
                runningBIDs.insert(b)
            }
            if let u = r.bundleURL?.standardizedFileURL.path {
                runningPaths.insert(u)
            }
        }

        for item in candidateURLs {
            let p = item.standardizedFileURL.path
            if p.hasPrefix("/System") || p.contains(".app/Contents/") || p.contains("node_modules") || item.standardizedFileURL == Bundle.main.bundleURL.standardizedFileURL { continue }

            var infoPlist = item.appendingPathComponent("Contents/Info.plist")
            var isMAS = fm.fileExists(atPath: item.appendingPathComponent("Contents/_MASReceipt/receipt").path)
            let rawName = item.deletingPathExtension().lastPathComponent

            // 支持 iOS 移植应用包装器 (Wrapper/*.app)
            if !fm.fileExists(atPath: infoPlist.path) {
                let wrapper = item.appendingPathComponent("Wrapper")
                if let subs = try? fm.contentsOfDirectory(at: wrapper, includingPropertiesForKeys: nil) {
                    for s in subs where s.pathExtension == "app" {
                        infoPlist = s.appendingPathComponent("Info.plist")
                        isMAS = true
                        break
                    }
                }
            }

            var bid = ""
            var version = ""
            var name = rawName
            var plistDict: [String: Any] = [:]
            if let data = try? Data(contentsOf: infoPlist),
               let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] {
                plistDict = dict
                bid = (dict["CFBundleIdentifier"] as? String) ?? ""
                version = (dict["CFBundleShortVersionString"] as? String) ?? (dict["CFBundleVersion"] as? String) ?? ""
                if let disp = dict["CFBundleDisplayName"] as? String, !disp.isEmpty, !disp.hasPrefix("com.") {
                    name = disp
                }
            }

            // P0-2：GUI 主程序判定，收窄扫描面（对齐原版 ApplicationFilterType 体系）
            guard isGUIApplicationBundle(path: p, dict: plistDict) else { continue }

            // Safari 为受保护系统浏览器，排除
            if bid == "com.apple.Safari" { continue }

            let key = bid.isEmpty ? p : bid
            let isDuplicateForDisplay = seen.contains(key) || seenPaths.contains(p)
            seen.insert(key)
            seenPaths.insert(p)

            // App Store 来源识别 (含 MAS Receipt、SC_Info FairPlay DRM)
            if !isMAS && fm.fileExists(atPath: item.appendingPathComponent("SC_Info").path) {
                isMAS = true
            }
            let source = isMAS ? "App Store" : "Other"

            // 自动更新通道（本地检测，不联网）
            var updateChannel = ""
            if isMAS {
                updateChannel = "App Store"
            } else if plistDict["SUFeedURL"] != nil
                        || fm.fileExists(atPath: item.appendingPathComponent("Contents/Frameworks/Sparkle.framework").path) {
                updateChannel = "Sparkle"
            }

            // 运行态与最后活动时间检测
            let isRunningNow = (!bid.isEmpty && runningBIDs.contains(bid.lowercased()))
                || runningPaths.contains(p)

            var lastOpened: Date? = nil
            if isRunningNow {
                lastOpened = Date()
            } else {
                var candidateDates: [Date] = []
                if let mdItem = MDItemCreateWithURL(kCFAllocatorDefault, item as CFURL),
                   let d = MDItemCopyAttribute(mdItem, kMDItemLastUsedDate as CFString) as? Date,
                   d.timeIntervalSince1970 > 946684800 { // > 2000年
                    candidateDates.append(d)
                }
                if let attrs = try? fm.attributesOfItem(atPath: item.path),
                   let mod = attrs[.modificationDate] as? Date,
                   mod.timeIntervalSince1970 > 946684800 {
                    candidateDates.append(mod)
                }
                // 检查应用专属数据目录修改时间（解决如 Cursor/QQ 等应用 Spotlight 索引滞后或为 1979 年的问题）
                let appDataCandidates = AppConfig.Uninstaller.lastUsedProbePaths(appName: name, bundleID: bid)
                for candPath in appDataCandidates {
                    if let attrs = try? fm.attributesOfItem(atPath: candPath),
                       let mod = attrs[.modificationDate] as? Date,
                       mod.timeIntervalSince1970 > 946684800 {
                        candidateDates.append(mod)
                    }
                }
                lastOpened = candidateDates.max()
            }

            let isSuspicious = false

            // 经销商 / 供应商识别 
            var vendor = ""
            let lowBid = bid.lowercased()
            let lowName = name.lowercased()
            if lowBid.hasPrefix("com.apple.") {
                vendor = "Apple"
            } else if lowName == "google chrome" || lowName == "android file transfer" || lowName == "antigravity" {
                vendor = "Google"
            } else if lowBid.hasPrefix("com.macpaw.") {
                vendor = "MacPaw"
            } else if lowBid.hasPrefix("com.microsoft.") {
                vendor = "Microsoft"
            } else if lowBid.hasPrefix("com.jetbrains.") {
                vendor = "JetBrains"
            } else if lowBid.hasPrefix("com.adobe.") {
                vendor = "Adobe"
            }

            let icon = NSWorkspace.shared.icon(forFile: item.path)
            icon.size = NSSize(width: 64, height: 64)

            // 32 位判断
            let exe = Bundle(url: item)?.executableURL
            let is32 = exe.map { is32BitOnly($0) } ?? false

            var installDate: Date? = nil
            if let vals = try? item.resourceValues(forKeys: [.addedToDirectoryDateKey, .creationDateKey, .contentModificationDateKey]) {
                installDate = vals.addedToDirectoryDate ?? vals.creationDate ?? vals.contentModificationDate
            }

            var app = InstalledApp(name: name, bundleID: bid, url: item,
                                   appSize: FileUtil.size(of: item), icon: icon)
            app.version = version
            app.source = source
            app.updateChannel = updateChannel
            app.lastOpened = lastOpened
            app.installDate = installDate
            app.is32Bit = is32
            app.isSuspicious = isSuspicious
            app.vendor = vendor
            app.isActiveNow = isRunningNow
            allInstances.append(app)
            if !isDuplicateForDisplay {
                apps.append(app)
            }
        }

        // 补充扫描目录之外的特定用户助理工具（收敛至 AppConfig.Uninstaller）
        let home = fm.homeDirectoryForCurrentUser.path
        let extras: [(String, String, String)] = AppConfig.Uninstaller.assistantAppCandidates.map {
            ($0.name, $0.bundleID, $0.pathTemplate.replacingOccurrences(of: "~", with: home))
        }
        for (extraName, extraBid, extraPath) in extras {
            let u = URL(fileURLWithPath: extraPath)
            if fm.fileExists(atPath: extraPath) && !seenPaths.contains(u.standardizedFileURL.path) {
                var a = InstalledApp(name: extraName, bundleID: extraBid, url: u,
                                     appSize: FileUtil.size(of: u), icon: NSWorkspace.shared.icon(forFile: extraPath))
                a.source = "Other"
                apps.append(a)
                allInstances.append(a)
                seenPaths.insert(u.standardizedFileURL.path)
            }
        }

        Self.allInstalledAppInstances = allInstances
        apps.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return apps
    }

    /// GUI 主程序判定（P0-2，对齐原版 ApplicationFilterType 体系）
    ///
    /// 原版 UninstallerScanning 以 ApplicationNameFilter / BundleIdentifierFilter /
    /// CompoundApplicationFilter / EmptyApplicationFilter 体系 + `systemApplications`
    /// 显式排除 Frameworks / dylib / helper。新版仅按「目录里 .app 后缀」收集，
    /// 把 Helper、Framework 内部工具、安装包内的 .app 都算成了独立应用（134 → 应为原版量级）。
    ///
    /// 收窄规则（必须全部满足才收为独立应用）：
    ///   a. CFBundlePackageType == "APPL"（缺失时要求存在 CFBundleExecutable）；
    ///   b. LSUIElement != true（排除无 Dock 图标的辅助程序）；
    ///   c. 路径不在 Contents/{Frameworks,PlugIns,XPCServices,Helpers,Library}/ 之下；
    ///   d. 排除包内 Helper 工具（Contents/MacOS/*Helper* 且 PackageType != APPL）。
    static func isGUIApplicationBundle(path: String, dict: [String: Any]) -> Bool {
        // c. 内部嵌套组件路径排除（含 dylib/framework 内部 .app）
        for marker in ["/Contents/Frameworks/", "/Contents/PlugIns/", "/Contents/XPCServices/",
                       "/Contents/Helpers/", "/Contents/Library/"] {
            if path.contains(marker) { return false }
        }

        let pkgType = (dict["CFBundlePackageType"] as? String) ?? ""
        let exec = (dict["CFBundleExecutable"] as? String) ?? ""
        let hasExec = !exec.isEmpty

        // a. 必须为 APPL；若 PackageType 缺失则要求存在主可执行文件
        if !pkgType.isEmpty {
            guard pkgType.caseInsensitiveCompare("APPL") == .orderedSame else { return false }
        } else if !hasExec {
            return false
        }

        // b. LSUIElement == true → 无 Dock 图标的辅助程序（menu bar extra / background agent）
        //    **仅对「嵌套在其它 .app 内部」的候选生效**：
        //    - Electron 的 `Contents/Frameworks/… Helper.app`、各类 LoginItem 辅助程序
        //      都位于 /Contents/ 之下，必须排除（否则应用数从 75 暴涨到 200+）；
        //    - 但**独立**的菜单栏/后台小工具是「应用本体」，仍应计入。
        //      实测反例：Epson QuickPrintA 的 LSUIElement = "1"，而它恰是原版
        //      「已发现 N 个不支持的应用程序」要列出的纯 32 位应用。
        //      早期实现无差别套用本规则，QuickPrintA/B 被直接丢弃，
        //      于是「不支持的应用」永远显示 0 个。
        if path.contains("/Contents/") {
            if let ui = dict["LSUIElement"] as? Bool, ui { return false }
            if let ui = dict["LSUIElement"] as? String,
               ui == "1" || ui.lowercased() == "true" { return false }
            if let ui = dict["LSUIElement"] as? Int, ui != 0 { return false }
        }

        // d. 包内 Helper 工具（PackageType 非 APPL 且主可执行文件带 Helper）
        if exec.contains("Helper") && pkgType.caseInsensitiveCompare("APPL") != .orderedSame {
            return false
        }

        return true
    }

    /// 读 Mach-O 头部判断是否只有 32 位架构
    ///
    /// 字节序说明（本类曾因此彻底失效，务必保留此注释）：
    ///   · Mach-O thin header 的 MH_MAGIC(0xfeedface) / MH_MAGIC_64(0xfeedfacf) 按**主机序**
    ///     存储，在 arm64（小端）上原生读出来仍等于这两个常量，故直接比较即可。
    ///   · FAT（通用二进制）头则按**大端**存储。因此本机原生读出的是字节交换后的
    ///     **FAT_CIGAM (0xbebafeca)**，而不是 FAT_MAGIC (0xcafebabe)。
    ///     早期实现只判 `== 0xcafebabe`，在 Apple Silicon 上永远为假 —— 导致
    ///     QuickPrintA（ppc + i386 纯 32 位）这类「不支持的应用程序」一个都检不出来。
    ///     实测：`/usr/bin/python3` 与 `QuickPrintA` 的 magic 在磁盘上均为 CA FE BA BE，
    ///     小端原生读出即 0xbebafeca。
    ///   · 同理，FAT 头的 nfat / fat_arch 的 cputype / cpusubtype / offset / size / align
    ///     全部按大端读取。
    static func is32BitOnly(_ executable: URL) -> Bool {
        guard let h = try? FileHandle(forReadingFrom: executable) else { return false }
        defer { try? h.close() }
        guard let head = try? h.read(upToCount: 8192), head.count >= 8 else { return false }
        let magic: UInt32 = head.withUnsafeBytes { $0.load(as: UInt32.self) }
        // 32 位 thin Mach-O
        if magic == 0xfeedface { return true }
        // 64 位 thin Mach-O
        if magic == 0xfeedfacf { return false }
        let magicBE: UInt32 = head.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }

        // FAT / 通用二进制：magic 以 FAT_CIGAM（小端主机读出）或 FAT_MAGIC 出现
        guard magicBE == 0xcafebabe || magic == 0xcafebabe else { return false }
        let nfat: UInt32 = head.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self).bigEndian }
        var has64 = false
        for i in 0..<Int(nfat) {
            let off = 8 + i * 20
            guard off + 4 <= head.count else { break }
            let cputype: UInt32 = head.withUnsafeBytes { $0.load(fromByteOffset: off, as: UInt32.self).bigEndian }
            if cputype & 0x01000000 != 0 { has64 = true }
        }
        return !has64
    }

    // MARK: 残留扫描(规则库驱动 + 10 级启发式与 UUID 容器穿透)

    /// 防短名炸弹安全阈值 (TC-UNINST-001，收敛至 AppConfig.Uninstaller)
    static var minMatchTokenLength: Int { AppConfig.Uninstaller.minMatchTokenLength }

    /// 共享厂商目录名（小写，收敛至 AppConfig.Uninstaller）
    static var sharedVendorDirectoryNames: Set<String> { AppConfig.Uninstaller.sharedVendorDirectoryNames }

    /// 校验 Token 是否达到安全匹配阈值（杜绝因 ssh、git、go、app 等短名误伤 ~/.ssh 或 ~/.git）
    static func isSafeMatchToken(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minMatchTokenLength
    }

    /// 提取应用的 10 级关联启发式匹配特征 Token 集合
    static func matchesBundleID(_ candidate: String, bundleID: String) -> Bool {
        guard !bundleID.isEmpty else { return false }
        let name = candidate.lowercased(), bid = bundleID.lowercased()
        return name == bid || name.hasPrefix(bid + ".")
    }

    static func heuristicTokens(for app: InstalledApp) -> Set<String> {
        var tokens = Set<String>()

        // 1. Bundle ID 全等
        if isSafeMatchToken(app.bundleID) {
            tokens.insert(app.bundleID)
        }

        // 2. Bundle ID 子前缀
        let bidParts = app.bundleID.split(separator: ".")
        if bidParts.count >= 3 {
            let prefix = bidParts.dropLast().joined(separator: ".")
            _ = prefix // vendor prefix alone is not ownership evidence
        }

        // 3. 应用显示名称
        if isSafeMatchToken(app.name) {
            tokens.insert(app.name)
        }

        // 4. 去除版本号与修饰后缀后的规范化名称 (如 Visual Studio Code - Insiders -> Visual Studio Code)
        let normalized = app.name
            .replacingOccurrences(of: " Beta", with: "")
            .replacingOccurrences(of: " Preview", with: "")
            .replacingOccurrences(of: " - Insiders", with: "")
            .replacingOccurrences(of: " Community Edition", with: "")
            .replacingOccurrences(of: " Professional", with: "")
        if isSafeMatchToken(normalized) && normalized != app.name {
            tokens.insert(normalized)
        }

        // 5. 公司/开发者供应商名称
        if !app.vendor.isEmpty && isSafeMatchToken(app.vendor) {
            // Vendor identity does not establish ownership of shared data.
        }

        return tokens
    }

    /// 匹配正则残留规则（支持多层子目录及绝对路径正则）
    static func findRegexMatches(basePrefix: String, pattern: String) -> [URL] {
        var cleanPattern = pattern
        if cleanPattern.hasPrefix("^") { cleanPattern = String(cleanPattern.dropFirst()) }
        if cleanPattern.hasSuffix("$") { cleanPattern = String(cleanPattern.dropLast()) }

        let regexMetaChars: Set<Character> = ["*", "+", "?", "[", "]", "(", ")", "^", "{", "}", "|", "\\", "$"]

        let isAbsolute = pattern.hasPrefix("/") || pattern.hasPrefix("^/")
        var currentDirs: [URL]
        var components: [String]

        if isAbsolute {
            currentDirs = [URL(fileURLWithPath: "/")]
            components = cleanPattern.split(separator: "/").filter { !$0.isEmpty }.map(String.init)
        } else {
            guard !basePrefix.isEmpty else { return [] }
            let baseDir = URL(fileURLWithPath: basePrefix)
            guard FileUtil.exists(baseDir.path) else { return [] }
            currentDirs = [baseDir]
            components = cleanPattern.split(separator: "/").filter { !$0.isEmpty }.map(String.init)
        }

        guard !components.isEmpty else { return [] }

        for (idx, comp) in components.enumerated() {
            var nextLevel: [URL] = []
            let isLast = (idx == components.count - 1)
            let isRegexComp = comp.contains(where: { regexMetaChars.contains($0) })

            for dir in currentDirs {
                guard FileUtil.exists(dir.path) else { continue }
                if !isRegexComp {
                    let child = dir.appendingPathComponent(comp)
                    if FileUtil.exists(child.path) {
                        nextLevel.append(child)
                    }
                } else {
                    let children = FileUtil.children(of: dir)
                    for child in children {
                        let name = child.lastPathComponent
                        if RegexEngine.shared.matches("^" + comp + "$", name)
                            || RegexEngine.shared.matches(comp, name) {
                            nextLevel.append(child)
                        }
                    }
                }
            }
            if nextLevel.isEmpty { return [] }
            // 严防返回中间目录扩大清理范围 (R1)：
            // 若在中间分量超出上限，绝对不可返回中间父目录，直接中止并返回空；
            // 若在最终终端分量超出上限，安全截断至 1000 项
            if !isLast {
                guard nextLevel.count <= AppConfig.Uninstaller.regexMatchLevelCap else { return [] }
            } else {
                guard nextLevel.count <= AppConfig.Uninstaller.regexMatchLevelCap else { return [] }
            }
            currentDirs = nextLevel
        }

        return currentDirs
    }

    // MARK: - 应用关联文件夹用途识别引擎 (应用关联文件夹用途识别)

    struct AppFolderPurpose: Sendable, Equatable {
        /// 简短类别标签（如：App / 缓存 / 临时缓存 / HTTP 存储 / 容器 / 群组容器 / 应用支持 / 偏好设置 / 日志）
        let shortTag: String
        /// 文件夹具体用途说明（告知用户该目录具体存放什么、删除有什么影响）
        let purposeDescription: String
        /// 是否属于用户配置或私有数据（需确认项，区别于可随时重建的缓存/日志）
        let isUserData: Bool
        /// 展示排序权重（App 本体置顶，随后缓存/日志，最后容器/配置）
        let sortOrder: Int
    }

    /// 将完整路径缩写为以 ~ 开头的紧凑路径（如 ~/Library/Caches/...）
    static func abbreviateHomePath(_ rawPath: String) -> String {
        guard !rawPath.isEmpty else { return "" }
        let home = FileUtil.home.path
        if rawPath == home { return "~" }
        if rawPath.hasPrefix(home + "/") {
            return "~" + String(rawPath.dropFirst(home.count))
        }
        return rawPath
    }

    /// 根据路径与备注精准识别应用关联文件夹的具体用途
    static func classifyFolderPurpose(path: String, fallbackNote: String = "") -> AppFolderPurpose {
        let p = path
        let low = p.lowercased()

        // 1. 应用程序本体 (.app)
        if low.hasSuffix(".app") || fallbackNote == "Application Bundle" {
            return AppFolderPurpose(
                shortTag: tr(.categoryAppBundle),
                purposeDescription: tr(.appCategoryMainBundleExecutable),
                isUserData: false,
                sortOrder: 0
            )
        }

        // 2. 系统级临时缓存 (/private/var/folders/.../{C,0}/...)
        if (low.contains("/var/folders/") && !low.contains("/t/")) || fallbackNote == "Temporary Cache" {
            return AppFolderPurpose(
                shortTag: tr(.categoryTempCache),
                purposeDescription: tr(.appCategoryRuntimeShaderCache),
                isUserData: false,
                sortOrder: 2
            )
        }

        // 3. 临时交换目录 (/private/var/folders/.../T/ 或 /tmp/)
        if ((low.contains("/var/folders/") && low.contains("/t/")) || low.hasPrefix("/tmp/") || low.hasPrefix("/private/tmp/"))
            && !low.contains("/library/") {
            return AppFolderPurpose(
                shortTag: tr(.categoryTempFiles),
                purposeDescription: tr(.appCategorySessionTemporaryFiles),
                isUserData: false,
                sortOrder: 3
            )
        }

        // 4. 用户/系统级缓存 (~/Library/Caches/...)
        if low.contains("/library/caches/") {
            return AppFolderPurpose(
                shortTag: tr(.categoryCache),
                purposeDescription: tr(.appCategoryDiskCacheThumbnails),
                isUserData: false,
                sortOrder: 1
            )
        }

        // 5. HTTP 网络存储 (~/Library/HTTPStorages/...)
        if low.contains("/library/httpstorages/") {
            return AppFolderPurpose(
                shortTag: tr(.categoryHttpStorage),
                purposeDescription: tr(.appCategoryHttpNetworkCache),
                isUserData: true,
                sortOrder: 4
            )
        }

        // 6. 运行与崩溃日志 (~/Library/Logs/... 或 DiagnosticReports)
        if low.contains("/library/logs/") || low.contains("/diagnosticreports/") || low.contains("/crashreporter/") {
            return AppFolderPurpose(
                shortTag: tr(.categoryLogs),
                purposeDescription: tr(.applicationRuntimeDebugLogsAndHistoricalCrashReports),
                isUserData: false,
                sortOrder: 5
            )
        }

        // 7. 窗口保存状态 (~/Library/Saved Application State/...)
        if low.contains("/saved application state/") || low.hasSuffix(".savedstate") {
            return AppFolderPurpose(
                shortTag: tr(.categorySavedState),
                purposeDescription: tr(.appCategoryWindowLayoutState),
                isUserData: true,
                sortOrder: 6
            )
        }

        // 8. WebKit 内置浏览器数据 (~/Library/WebKit/...)
        if low.contains("/library/webkit/") {
            return AppFolderPurpose(
                shortTag: tr(.categoryWebKit),
                purposeDescription: tr(.appCategoryEmbeddedWebKitCache),
                isUserData: true,
                sortOrder: 7
            )
        }

        // 9. 安装包收据 (/private/var/db/receipts/...)
        if low.contains("/var/db/receipts/") || fallbackNote.contains("Receipt") {
            return AppFolderPurpose(
                shortTag: tr(.categoryReceipt),
                purposeDescription: tr(.appCategoryPkgReceiptsAndBom),
                isUserData: false,
                sortOrder: 8
            )
        }

        // 10. 沙盒容器 (~/Library/Containers/...)
        if low.contains("/library/containers/") {
            let isWidget = low.contains("widget") || low.contains("extension")
            return AppFolderPurpose(
                shortTag: tr(.categoryContainer),
                purposeDescription: isWidget
                    ? tr(.appCategoryWidgetSandboxContainer)
                    : tr(.macosSandboxContainerIncludesSettingsCachesAndPrivateData),
                isUserData: true,
                sortOrder: 10
            )
        }

        // 11. 共享群组容器 (~/Library/Group Containers/...)
        if low.contains("/library/group containers/") {
            return AppFolderPurpose(
                shortTag: tr(.categoryGroupContainerAlt),
                purposeDescription: tr(.appCategorySharedDeveloperAppGroup),
                isUserData: true,
                sortOrder: 11
            )
        }

        // 12. 应用支持目录 (~/Library/Application Support/...)
        if low.contains("/application support/") {
            return AppFolderPurpose(
                shortTag: tr(.categoryAppSupport),
                purposeDescription: tr(.appCategoryCoreConfigAndDatabase),
                isUserData: true,
                sortOrder: 12
            )
        }

        // 13. 启动代理與守护进程 (LaunchAgents / LaunchDaemons)
        if low.contains("/launchagents/") {
            return AppFolderPurpose(
                shortTag: tr(.categoryLaunchAgent),
                purposeDescription: tr(.appCategoryLaunchAgentPlist),
                isUserData: true,
                sortOrder: 14
            )
        }
        if low.contains("/launchdaemons/") {
            return AppFolderPurpose(
                shortTag: tr(.systemDaemon),
                purposeDescription: tr(.appCategoryLaunchDaemonPlist),
                isUserData: true,
                sortOrder: 15
            )
        }

        // 14. 偏好设置 (~/Library/Preferences/...)
        if low.contains("/library/preferences/") || low.hasSuffix(".plist") {
            return AppFolderPurpose(
                shortTag: tr(.categoryPreferences),
                purposeDescription: tr(.appCategoryPreferencesPlist),
                isUserData: true,
                sortOrder: 13
            )
        }

        // 15. Cookies (~/Library/Cookies/...)
        if low.contains("/library/cookies/") || low.hasSuffix(".binarycookies") {
            return AppFolderPurpose(
                shortTag: tr(.categoryCookies),
                purposeDescription: tr(.appCategoryLoginCookiesData),
                isUserData: true,
                sortOrder: 16
            )
        }

        // 16. 应用脚本 (~/Library/Application Scripts/...)
        if low.contains("/application scripts/") {
            return AppFolderPurpose(
                shortTag: tr(.appCategoryApplicationScripts),
                purposeDescription: tr(.appCategorySandboxedScriptsDesc),
                isUserData: true,
                sortOrder: 17
            )
        }

        // 17. 插件与扩展
        if low.contains("/internet plug-ins/") || low.contains("/plugins/") {
            return AppFolderPurpose(
                shortTag: tr(.appCategoryPlugins),
                purposeDescription: tr(.appCategoryPluginModulesDesc),
                isUserData: true,
                sortOrder: 18
            )
        }

        return AppFolderPurpose(
            shortTag: fallbackNote.isEmpty ? tr(.categoryAssociatedData) : fallbackNote,
            purposeDescription: tr(.appCategoryApplicationSupportDesc),
            isUserData: true,
            sortOrder: 20
        )
    }

    // MARK: 卸载与幸存安装守卫 (Surviving Installation Guard)

    /// 检查系统中是否存在同一 Bundle ID 的同款应用存活实例（例如外接盘备份、同目录多副本、Beta 版本等）
    static func hasSurvivingInstallation(for app: InstalledApp, allApps: [InstalledApp]? = nil) -> Bool {
        guard !app.bundleID.isEmpty else { return false }
        let targetStdPath = app.url.standardizedFileURL.path
        // 1. 从全量应用实例索引中查找（严防展示去重数组覆盖全量单例 R5）
        var candidatePool = allInstalledAppInstances
        if let passed = allApps {
            for p in passed {
                if !candidatePool.contains(where: { $0.url.standardizedFileURL.path == p.url.standardizedFileURL.path }) {
                    candidatePool.append(p)
                }
            }
        }
        if candidatePool.isEmpty { candidatePool = installedApps() }

        for other in candidatePool {
            if other.url.standardizedFileURL.path != targetStdPath,
               other.bundleID.localizedCaseInsensitiveCompare(app.bundleID) == .orderedSame,
               FileUtil.exists(other.url.path) {
                return true
            }
        }

        // 2. 实时向系统 LaunchServices / NSWorkspace 查询是否存在同 Bundle ID 存活应用
        if let otherURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleID) {
            if otherURL.standardizedFileURL.path != targetStdPath && FileUtil.exists(otherURL.path) {
                return true
            }
        }

        // 3. 扫描常见应用根目录（/Applications, /System/Applications, ~/Applications）
        let standardRoots = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            FileUtil.home.appendingPathComponent("Applications")
        ]
        let fm = FileManager.default
        for root in standardRoots {
            guard let contents = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [URLResourceKey](), options: [.skipsHiddenFiles]) else { continue }
            for item in contents where item.pathExtension.lowercased() == "app" {
                guard item.standardizedFileURL.path != targetStdPath else { continue }
                let plist = item.appendingPathComponent("Contents/Info.plist")
                if let data = try? Data(contentsOf: plist),
                   let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                   let bid = dict["CFBundleIdentifier"] as? String,
                   bid.localizedCaseInsensitiveCompare(app.bundleID) == .orderedSame {
                    return true
                }
            }
        }

        // 同时扫描当前 .app 所在父目录中的同级应用包（覆盖外接盘/自定义目录或无 Info.plist 变体副本）
        let parentDir = app.url.deletingLastPathComponent()
        if let siblings = try? fm.contentsOfDirectory(at: parentDir, includingPropertiesForKeys: [URLResourceKey](), options: [.skipsHiddenFiles]) {
            let baseLower = app.name.lowercased()
            for sib in siblings where sib.pathExtension.lowercased() == "app" {
                guard sib.standardizedFileURL.path != targetStdPath else { continue }
                let infoPlist = sib.appendingPathComponent("Contents/Info.plist")
                var sibBundleID = ""
                if let data = try? Data(contentsOf: infoPlist),
                   let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                   let bid = dict["CFBundleIdentifier"] as? String {
                    sibBundleID = bid
                }
                if !sibBundleID.isEmpty {
                    if sibBundleID.localizedCaseInsensitiveCompare(app.bundleID) == .orderedSame {
                        return true
                    }
                } else if !baseLower.isEmpty {
                    let sibNameLower = sib.deletingPathExtension().lastPathComponent.lowercased()
                    if sibNameLower == baseLower ||
                       sibNameLower.hasPrefix(baseLower + " ") ||
                       baseLower.hasPrefix(sibNameLower + " ") {
                        return true
                    }
                }
            }
        }
        return false
    }

    /// 返回需要删除的 URL 集合(应用本体 + 残留)
    /// 严格遵循 幸存安装守卫：若检测到同款应用依然存活，仅删除选中的 .app 本体，保留共享配置
    static func removalTargets(for app: InstalledApp, allApps: [InstalledApp]? = nil) -> [URL] {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        if hasSurvivingInstallation(for: app, allApps: allApps) {
            return [app.url]
        }
        return [app.url] + app.leftovers.filter { $0.locked != true && $0.ruleEvidence?.executable == true }.map { $0.url }
    }
}
