import Foundation
import AppKit

// ============================================================
//  OrphanFinderEngine —— 程序残留（已卸载应用程序遗留文件）发现器
//
//  对齐基线：
//    · 分类名    leftovers_category_name        = 程序残留
//    · 分类描述  leftovers_category_description = 如果您手动删除了一个应用程序文件，
//                  其所有残留的项目将保留在系统上。…即使主应用程序已被删除。
//    · 分组名    leftovers_group_name           = 残留文件
//    · 分组描述  leftovers_group_description    = 已卸载应用程序的偏好设置和配置文件是多余的，可以删除。
//
//  因此本引擎只产出「一个分组节点 + 文件级明细」，与 DataManager 三列
//  （分类「程序残留」→ 分组「残留文件」→ 明细）严格对应。
//
//  安全规范 (DNA 宪章与实施指南严格锁定)：
//    1. 严格安全阀门 (OrphanSafetyPolicy) 两层分级：
//       - 第一层（始终允许）挥发性缓存与日志目录：
//         ~/Library/Caches、~/Library/Logs、~/Library/Saved Application State、
//         ~/Library/HTTPStorages、~/Library/WebKit；
//         （注：~/Library/Application Support/CrashReporter 属「崩溃诊断报告」，
//          由 JunkEngine 的「用户日志文件」组负责，不属于应用残留语义。）
//       - 第二层（P1-3 条件允许）持久配置目录：~/Library/Preferences、
//         ~/Library/Application Support —— 仅当候选名呈「BundleID 形状」且经
//         反向拓扑确证「应用本体已卸载」、且不在保护集内时才放行，
//         并以 .caution 分级、默认不勾选（用户必须显式确认）。
//    2. 绝对黑名单阻断 (严禁越权)：
//       - 绝对严禁将 Containers (沙盒数据)、Group Containers、
//         LaunchAgents、Keychains、以及系统级 /Library 配置纳入孤儿残留。
//    3. 反向拓扑确证「应用本体已卸载」——必须同时排除三类主体：
//       a. 仍在安装的 GUI 应用：索引 CFBundleName / CFBundleDisplayName /
//          CFBundleExecutable / **各语言 InfoPlist.strings 本地化显示名**
//          （如 wechatwebdevtools.app 的 zh_CN 名「微信开发者工具」），
//          解决「应用目录名与缓存目录名语言不一致」造成的误报；
//       b. 开发者工具链与包管理器：Go / Playwright / hermit / TabNine / Goose 等
//          工具链缓存按 DNA §三.2 属「系统垃圾 → 开发者冗余」，不是
//          「已卸载应用程序残留」，严禁在本模块误报；
//       c. 活跃度守卫：目录/文件最近仍在被写入 ⇒ 归属主体仍在运行，
//          不可能是「已卸载应用程序」的遗留物（宁漏不误）。
//    4. 符号链接防穿透逃逸：严格执行 SymlinkGuard。
// ============================================================

enum OrphanSafetyPolicy {
    private static func canonicalPath(_ url: URL) -> String {
        SymlinkGuard.canonicalizeMacOSSystemPrefix(url.standardizedFileURL.path)
    }


    /// 第一层：始终允许的孤儿残留候选根目录（仅限挥发性缓存与日志）
    static var permittedRoots: [URL] {
        let homeLib = FileUtil.home.appendingPathComponent("Library")
        return [
            homeLib.appendingPathComponent("Caches"),
            homeLib.appendingPathComponent("Logs"),
            homeLib.appendingPathComponent("Saved Application State"),
            homeLib.appendingPathComponent("HTTPStorages"),
            homeLib.appendingPathComponent("WebKit")
        ]
    }

    /// 第二层（P1-3）：条件允许的持久配置根目录。
    /// 调用方 (OrphanFinderEngine) 必须额外完成「BundleID 形状 + 反向拓扑 + 保护集」三重校验。
    static var conditionalRoots: [URL] {
        let homeLib = FileUtil.home.appendingPathComponent("Library")
        return [
            homeLib.appendingPathComponent("Preferences"),
            homeLib.appendingPathComponent("Application Support")
        ]
    }

    /// 绝对禁止触碰的持久配置与沙盒数据根目录（绝对黑名单）
    /// 说明：Preferences / Application Support 已移交 conditionalRoots 条件管控，
    ///      此处不再重复列入，但其它沙盒/密钥/启动项位置仍绝对封锁。
    static var forbiddenRoots: [URL] {
        let homeLib = FileUtil.home.appendingPathComponent("Library")
        let rootLib = URL(fileURLWithPath: "/Library")
        return [
            homeLib.appendingPathComponent("Containers"),
            homeLib.appendingPathComponent("Group Containers"),
            homeLib.appendingPathComponent("LaunchAgents"),
            homeLib.appendingPathComponent("Keychains"),
            rootLib.appendingPathComponent("Preferences"),
            rootLib.appendingPathComponent("LaunchAgents"),
            rootLib.appendingPathComponent("LaunchDaemons"),
            rootLib.appendingPathComponent("Application Support")
        ]
    }

    /// 校验候选路径是否符合孤儿清理安全政策 (TC-ORPHAN-001)
    static func isPermitted(url: URL) -> Bool {
        let path = canonicalPath(url)

        // 1. 绝对黑名单拦截：若路径落在黑名单目录下，直接封锁拒绝
        for forbidden in forbiddenRoots {
            let fPath = canonicalPath(forbidden)
            if path == fPath || path.hasPrefix(fPath + "/") {
                // 特殊例外：CrashReporter 允许作为日志残留，其余 Application Support 坚决禁止
                if path.contains("Application Support/CrashReporter") {
                    continue
                }
                return false
            }
        }

        // 2. 检查是否在显式白名单允许的挥发性目录中
        for permitted in permittedRoots {
            let pPath = canonicalPath(permitted)
            if path.hasPrefix(pPath + "/") {
                return true
            }
        }

        // 默认禁止不在许可目录列表中的任何未知路径
        return false
    }

    /// 校验候选路径是否属于「条件允许」的持久配置残留（P1-3 第二层）。
    /// 本函数只做位置校验；调用方还必须完成 BundleID 形状 / 反向拓扑 / 保护集校验。
    static func isConditionallyPermitted(url: URL) -> Bool {
        let path = canonicalPath(url)
        for forbidden in forbiddenRoots {
            let fPath = canonicalPath(forbidden)
            if path == fPath || path.hasPrefix(fPath + "/") { return false }
        }
        for root in conditionalRoots {
            let rPath = canonicalPath(root)
            if path.hasPrefix(rPath + "/") { return true }
        }
        return false
    }

    /// 提取位于第一层挥发性残留根目录下的直接子项 URL（用于判断宿主应用归属与防根目录误删）
    static func volatileRootEntryURL(for url: URL) -> URL? {
        let std = url.standardizedFileURL
        let path = canonicalPath(std)
        let lower = path.lowercased()
        if lower.contains("/library/preferences/") { return nil }
        if lower.contains("/library/application support/") && !lower.contains("/application support/crashreporter/") {
            return nil
        }
        if isConditionallyPermitted(url: std) && !lower.contains("/application support/crashreporter/") {
            return nil
        }
        let homeCrashReporter = FileUtil.home.appendingPathComponent("Library/Application Support/CrashReporter").standardizedFileURL
        var roots: [URL] = permittedRoots.map { $0.standardizedFileURL } + [homeCrashReporter]
        if let orphanRule = KnowledgeBaseManager.shared.authored.junk[AppConfig.RuleIDs.leftoverOrphan] {
            for r in orphanRule.paths where !r.contains("*") && !r.contains("{") {
                roots.append(URL(fileURLWithPath: KBPaths.expand(r)).standardizedFileURL)
            }
        }
        for root in roots {
            let rootPath = canonicalPath(root)
            guard path.hasPrefix(rootPath + "/") else { continue }
            let remainder = path.dropFirst(rootPath.count + 1)
            guard let firstComp = remainder.split(separator: "/").first, !firstComp.isEmpty else { continue }
            return root.appendingPathComponent(String(firstComp))
        }
        return nil
    }

    /// Gate 4 (JC.LEFTOVER.ORPHAN): 仅允许第一层挥发性根目录下的直接子项、且对应宿主应用已确认卸载时进入垃圾清理审阅层（L2），
    /// 第二层持久配置目录（Preferences / Application Support）一律返回 false 保持 L3 只读。
    static func canScheduleForCleanup(_ url: URL) -> Bool {
        guard let entryURL = volatileRootEntryURL(for: url) else { return false }
        return !OrphanFinderEngine.isOwnedByInstalledApp(url: entryURL)
    }
}

enum OrphanFinderEngine {

    // MARK: - 原版文案常量（ApplicationsModule.framework/zh-Hans 实证）

    /// 分类标签（DataManager 第一列），对应原版 leftovers_category_name
    static let categoryTag = "App Leftovers"
    /// 分组名，对应原版 leftovers_group_name
    static let groupName = "Leftover Files"
    /// 分组描述，对应原版 leftovers_group_description（持久配置无主项显式标记为只读供人工核验）
    static let groupDescription = "Volatile caches and logs of uninstalled applications can be cleaned; persistent preferences and Application Support directories are listed as read-only for manual verification."

    /// 残留类别（对应原版 LeftoversFetcher 各 Fetcher 语义）
    private struct ResidueKind {
        var note: String
        var caution: Bool

        static let preference   = ResidueKind(note: "Preferences Residue (Read-only — verify manually)", caution: true)
        static let appSupport   = ResidueKind(note: "Application Support Residue (Read-only — verify manually)", caution: true)
        static let cache        = ResidueKind(note: "Cache Residue", caution: false)
        static let log          = ResidueKind(note: "Log Residue", caution: false)
        static let savedState   = ResidueKind(note: "Saved State Residue", caution: false)
        static let httpStorage  = ResidueKind(note: "HTTP Storage Residue", caution: false)
        static let webkit       = ResidueKind(note: "WebKit Data Residue", caution: false)
        static let crashReport  = ResidueKind(note: "Crash Report Residue", caution: false)
    }

    /// 单个残留条目（文件 / 目录级）
    private struct Residue {
        var item: ScanItem
        var kind: ResidueKind
    }

    // MARK: - 集中收敛至 AppConfig.Uninstaller 的安全排除与分类字典
    private static var systemExclusions: Set<String> { AppConfig.Uninstaller.systemExclusions }
    private static var conditionalGenericNames: Set<String> { AppConfig.Uninstaller.conditionalGenericNames }
    private static var developerToolchainTokens: Set<String> { AppConfig.Uninstaller.developerToolchainTokens }
    private static var sharedVendorNames: Set<String> { AppConfig.Uninstaller.sharedVendorNames }
    private static var sharedSystemNames: Set<String> { AppConfig.Uninstaller.sharedSystemNames }
    private static var systemOwnedFragments: Set<String> { AppConfig.Uninstaller.systemOwnedFragments }
    private static var genericBIDSegments: Set<String> { AppConfig.Uninstaller.genericBIDSegments }
    private static var genericEntityNames: Set<String> { AppConfig.Uninstaller.genericEntityNames }
    private static var genericAppNameTokens: Set<String> { AppConfig.Uninstaller.genericAppNameTokens }

    // MARK: - 归属判定索引（反向拓扑）

    /// 已安装实体索引：把「仍在安装的应用与开发者工具」压成可 O(1) 反查的集合。
    private struct OwnershipIndex {
        /// 全部实体名（应用名 / 显示名 / 可执行名 / 本地化名 / PATH 工具名）
        var names: Set<String> = []
        /// 归一化 bundle ID
        var bundleIDs: Set<String> = []
        /// bundle ID 的「家族指纹」段（≥5 字符且非通用词）
        var bidSegments: Set<String> = []
        /// 应用名（仅应用，用于「应用名 ± 短后缀」判定，≥4 字符且非通用名）
        var appNames: Set<String> = []
        /// 应用名「标识词」：从在装应用名切分出的 ≥5 字符、非通用的词。
        /// 用于识别「应用名与 bundle ID 主体完全不同」的家族
        /// （如 Qoder CN ↔ com.qoder.ide —— 应用名 token「qoder」）。
        /// 只收录**应用**派生名，不含 PATH 工具名，避免通用命令行工具名扩大误伤面。
        var appNameTokens: Set<String> = []

        /// 归一化：只保留字母与数字（含 CJK），忽略大小写、空格、连字符、点号。
        /// 使 `ms-playwright` / `msplaywright` / `MS Playwright` 等写法归一。
        static func normalize(_ s: String) -> String {
            var out = ""
            out.reserveCapacity(s.count)
            for ch in s.lowercased() where ch.isLetter || ch.isNumber { out.append(ch) }
            return out
        }

        mutating func insert(entity name: String) {
            let n = Self.normalize(name)
            guard n.count >= 2 else { return }
            names.insert(n)
            if n.count >= 4 && !genericEntityNames.contains(n) { appNames.insert(n) }
        }

        /// 收录「应用派生名」（应用名 / 包名 / CFBundleName / DisplayName /
        /// CFBundleExecutable / 各语言本地化名），并额外切分出「标识词」token。
        mutating func insertAppName(_ name: String) {
            insert(entity: name)
            for raw in name.split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
                let t = Self.normalize(String(raw))
                guard t.count >= 5,
                      !genericEntityNames.contains(t),
                      !genericBIDSegments.contains(t),
                      !genericAppNameTokens.contains(t) else { continue }
                appNameTokens.insert(t)
            }
        }

        /// 把候选名按非字母数字边界切段：`com.qoder.ide` → ["com","qoder","ide"]
        static func segments(_ s: String) -> [String] {
            s.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map { $0.lowercased() }
                .filter { $0.count >= 4 }
        }

        mutating func insert(bundleID: String) {
            let n = Self.normalize(bundleID)
            guard n.count >= 4 else { return }
            bundleIDs.insert(n)
            for seg in bundleID.split(separator: ".") {
                let s = Self.normalize(String(seg))
                // 段长阈值 4：品牌段常为 4 字符（trae / kywl / lark / solo / keka），
                // 若仍用 5 会漏掉「应用名与 bundle ID 主体不同」的家族
                // （如 cn.trae.app ↔ HTTPStorages/com.trae.app、
                //   com.larksuite.feishu.ka.kywl.lark ↔ Application Support/LarkShell-ka-kywl）。
                guard s.count >= 4, !genericBIDSegments.contains(s) else { continue }
                bidSegments.insert(s)
            }
        }

        /// 候选残留名是否归属于某个仍在安装 / 在用的主体
        func owns(_ candidate: String) -> Bool {
            let key = Self.normalize(candidate)
            guard key.count >= 3 else { return false }

            // 1. 精确命中应用名 / bundle ID
            if names.contains(key) || bundleIDs.contains(key) { return true }

            // 2. 开发者工具链 / 包管理器缓存（属「系统垃圾 → 开发者冗余」）
            if belongsToDeveloperToolchain(key) { return true }

            // 3. 多应用共享的厂商目录（JetBrains / Adobe / Sogou…）
            for v in sharedVendorNames where key.contains(v) { return true }

            // 4. 与具体应用无关的系统 / 共享目录
            if sharedSystemNames.contains(key) { return true }

            // 4b. 系统自身持有的域（CUPS / XQuartz / WindowServer / loginwindow…）
            //     如 org.cups.PrintingPrefs —— 呈 BundleID 形状但属系统守护进程。
            for f in systemOwnedFragments where key.contains(f) { return true }

            // 5. 应用家族指纹：在装应用 bundle ID 的段出现在候选名中
            //    （如 TDAppDesktop ↔ com.tencent.mac.tdappdesktop、
            //      LarkShell-ka-kywl ↔ com.larksuite.feishu.ka.kywl.lark）
            for seg in bidSegments where key.contains(seg) { return true }

            // 5b. 应用名标识词与候选「整段相等」——识别应用名与 bundle ID 主体
            //     完全不同的家族（Qoder CN ↔ com.qoder.ide：应用名 token「qoder」
            //     与候选段「qoder」整段相等）。
            //     刻意用「整段相等」而非「子串包含」：ClashX 与 Clash Verge 仅前缀
            //     相同、段并不相等，故未安装的 ClashX 残留仍能被正确判为孤儿。
            if !appNameTokens.isEmpty {
                for seg in Self.segments(candidate) where appNameTokens.contains(seg) { return true }
            }

            // 6. 「应用名 ± 短后缀/前缀」：数据目录常为应用名加 Shell/Helper/Data 等短后缀
            //    （如 LarkShell ↔ Lark）
            for n in appNames {
                if key == n { return true }
                if key.count <= n.count + 6, key.hasPrefix(n) || key.hasSuffix(n) { return true }
            }

            // 7. 兜底包含关系（要求双方均 ≥6 字符，杜绝短名误伤）
            for n in names where n.count >= 6 {
                if key.contains(n) { return true }
            }
            for b in bundleIDs where b.count >= 6 {
                if key.contains(b) || (key.count >= 6 && b.contains(key)) { return true }
            }
            return false
        }

        private func belongsToDeveloperToolchain(_ key: String) -> Bool {
            if developerToolchainTokens.contains(key) { return true }
            for t in developerToolchainTokens where t.count >= 5 {
                if key.hasPrefix(t) || key.contains(t) { return true }
            }
            return false
        }
    }

    /// 收集「仍在安装」的实体：GUI 应用（含各语言本地化名与可执行名）+ PATH 上的命令行工具
    private static func ownershipIndex(installed: [InstalledApp]) -> OwnershipIndex {
        let identities = installed.map { (name: $0.name, bundleID: $0.bundleID, url: $0.url) }
        return ownershipIndex(identities: identities)
    }

    private static func ownershipIndex(identities: [(name: String, bundleID: String, url: URL)]) -> OwnershipIndex {
        var idx = OwnershipIndex()

        for a in identities {
            idx.insertAppName(a.name)
            idx.insertAppName(a.url.deletingPathExtension().lastPathComponent)
            idx.insert(bundleID: a.bundleID)
            // Info.plist 主字段（CFBundleName / DisplayName / Executable）
            if let info = Bundle(url: a.url)?.infoDictionary {
                for key in ["CFBundleName", "CFBundleDisplayName", "CFBundleExecutable"] {
                    if let v = info[key] as? String { idx.insertAppName(v) }
                }
            }
            for n in localizedAppNames(of: a.url) { idx.insertAppName(n) }
        }

        // 命令行工具链（go / hermit / tabnine … 常驻于 PATH 目录）
        for dir in toolchainSearchPaths() {
            guard let entries = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for e in entries where !e.hasPrefix(".") { idx.insert(entity: e) }
        }

        // 系统级「组件型」安装物：打印机 / 扫描仪驱动（ICA / TWAIN）与内核扩展。
        // 动机（实测）：`/Library/Image Capture/Devices/EPSON ES016E.app` 的
        // CFBundleIdentifier 正是 `com.epson.ica.es016e`；`SamsungPortableSSDDriver.kext`
        // 为 `com.samsung.portablessd.driver`。若只扫 /Applications，就会把
        // 仍在安装的驱动之偏好设置误判为「已卸载应用程序残留」。
        for bid in systemComponentBundleIDs() { idx.insert(bundleID: bid) }

        return idx
    }

    /// 系统级「组件型」安装物（打印机 / 扫描仪驱动、内核扩展）的 bundle ID。
    ///
    /// 这些组件由厂商安装器写入 /Library，不出现在 /Applications，
    /// 但同样是「仍在安装的主体」，其用户级偏好设置不属孤儿残留。
    private static func systemComponentBundleIDs() -> [String] {
        let dirs = AppConfig.Uninstaller.systemComponentDirs
        var out: [String] = []
        for dir in dirs {
            guard let entries = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for e in entries where !e.hasPrefix(".") {
                let info = "\(dir)/\(e)/Contents/Info.plist"
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: info)),
                      let dict = try? PropertyListSerialization.propertyList(
                        from: data, options: [], format: nil) as? [String: Any],
                      let bid = dict["CFBundleIdentifier"] as? String, !bid.isEmpty
                else { continue }
                out.append(bid)
            }
        }
        return out
    }

    /// 读取应用包内关键语言 InfoPlist.strings 的 CFBundleName / CFBundleDisplayName。
    private static func localizedAppNames(of appURL: URL) -> [String] {
        let res = appURL.appendingPathComponent("Contents/Resources")
        guard let dirs = try? FileManager.default.contentsOfDirectory(
            at: res, includingPropertiesForKeys: nil) else { return [] }

        var out: [String] = []
        let targetLprojNames: Set<String> = [
            "zh-hans.lproj", "zh_cn.lproj", "zh-hant.lproj", "zh_tw.lproj",
            "en.lproj", "base.lproj"
        ]
        for d in dirs where targetLprojNames.contains(d.lastPathComponent.lowercased()) {
            let f = d.appendingPathComponent("InfoPlist.strings")
            guard let data = try? Data(contentsOf: f),
                  let dict = try? PropertyListSerialization.propertyList(
                    from: data, options: [], format: nil) as? [String: Any] else { continue }
            for key in ["CFBundleDisplayName", "CFBundleName"] {
                if let v = dict[key] as? String, !v.isEmpty { out.append(v) }
            }
        }
        return out
    }

    /// 开发者工具链常见的可执行文件目录
    private static func toolchainSearchPaths() -> [String] {
        let home = FileUtil.home.path
        var paths = [
            "/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/usr/sbin", "/usr/libexec",
            home + "/.local/bin", home + "/go/bin", home + "/.hermit/bin",
            home + "/.cargo/bin", home + "/bin"
        ]
        if let env = ProcessInfo.processInfo.environment["PATH"] {
            paths.append(contentsOf: env.split(separator: ":").map(String.init))
        }
        return Array(Set(paths))
    }

    /// 判定名称是否为「BundleID 形状」（至少含一个点，且字符集受限）
    private static func isBundleIDShaped(_ s: String) -> Bool {
        guard s.contains("."), s.count >= 5 else { return false }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_")
        return s.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// 活跃度守卫：最近仍在被写入 ⇒ 归属主体仍在运行，不可能是卸载残留（宁漏不误）。
    ///
    /// 目录自身的 mtime 只在增删条目时变化，缓存类目录的文件写入不会刷新父目录，
    /// 因此同时检查其直属子项的修改时间（浅层、限量，保证扫描开销可控）。
    private static func isActivelyUsed(_ url: URL, withinDays: Int = 14) -> Bool {
        let cutoff = Date().addingTimeInterval(-Double(withinDays) * 86_400)
        let fm = FileManager.default

        if let d = (try? fm.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date, d > cutoff {
            return true
        }

        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else { return false }
        guard let children = try? fm.contentsOfDirectory(
            at: url, includingPropertiesForKeys: [.contentModificationDateKey]) else { return false }

        for c in children.prefix(64) {
            if let d = (try? c.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate,
               d > cutoff {
                return true
            }
        }
        return false
    }

    /// 残留类别：按所在根目录映射（对应原版各 Fetcher 语义）
    private static func kind(for root: URL) -> ResidueKind {
        switch root.lastPathComponent {
        case "Caches":                  return .cache
        case "Logs":                    return .log
        case "Saved Application State": return .savedState
        case "HTTPStorages":            return .httpStorage
        case "WebKit":                  return .webkit
        case "CrashReporter":           return .crashReport
        case "Preferences":             return .preference
        default:                        return .appSupport
        }
    }

    // MARK: - 扫描

    private static let cachedIndexLock = NSLock()
    private static let cachedIndexEntryStorage = LockedValue<(time: TimeInterval, index: OwnershipIndex)?>(nil)
    private static var cachedIndexEntry: (time: TimeInterval, index: OwnershipIndex)? {
        get { cachedIndexEntryStorage.withValue { $0 } }
        set { cachedIndexEntryStorage.withValue { $0 = newValue } }
    }

    static func isOwnedByInstalledApp(url: URL) -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        let idx: OwnershipIndex = {
            cachedIndexLock.lock()
            if let cached = cachedIndexEntry, now - cached.time < AppConfig.Security.orphanOwnershipCacheTTL {
                cachedIndexLock.unlock()
                return cached.index
            }
            cachedIndexLock.unlock()
            let fastApps = UninstallerEngine.fastInstalledAppIdentities().map { ($0.name, $0.bundleID, $0.url) }
            let built = ownershipIndex(identities: fastApps)
            cachedIndexLock.lock()
            cachedIndexEntry = (now, built)
            cachedIndexLock.unlock()
            return built
        }()
        let rawName = url.lastPathComponent
        let stem = url.pathExtension.lowercased() == "savedstate"
            ? (rawName as NSString).deletingPathExtension
            : rawName
        if stem.lowercased().hasPrefix("com.apple.") || JunkEngine.isIgnoredBundleID(stem) {
            return true
        }
        return idx.owns(stem) || idx.owns(rawName)
    }

    /// 扫描全机已卸载应用程序留下的残留文件，产出 DataManager 的「程序残留」分组节点。
    ///
    /// 返回：单元素数组 —— 分组节点「残留文件」（tags 含「程序残留」），
    ///       children 为文件级明细。无残留时返回空数组。
    static func scanOrphanNodes(installed: [InstalledApp]? = nil, stopped: () -> Bool = { false }) -> [Node] {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        if stopped() || IOScanContext.isCancelled { return [] }
        let index: OwnershipIndex
        if let installed = installed {
            index = ownershipIndex(installed: installed)
        } else {
            let fastApps = UninstallerEngine.fastInstalledAppIdentities().map { ($0.name, $0.bundleID, $0.url) }
            index = ownershipIndex(identities: fastApps)
        }

        let kb = KnowledgeBaseManager.shared
        let _ = kb.isLoaded ? kb.protectedBundleIDs : []
        let kbProtectedNames: Set<String> = kb.isLoaded
            ? Set(kb.protectedPathLiterals.map { ($0 as NSString).lastPathComponent.lowercased() })
            : []
        let fullExclusions = systemExclusions.union(kbProtectedNames)

        var residues: [Residue] = []
        var seenPaths = Set<String>()

        /// 单个候选的公共校验（安全阀门 → 保护集 → 反向拓扑 → 活跃度）
        /// - Parameter ownershipName: 用于「反向拓扑」的名称。Preferences 的 .plist 必须传
        ///   去掉扩展名后的 bundle ID（如 `cn.trae.app`），否则带 `.plist` 后缀会导致
        ///   与在装应用 bundle ID 精确匹配失败，把在装应用的偏好设置误判为孤儿。
        func accept(_ child: URL, ownershipName: String, kind k: ResidueKind, minSize: Int64) -> Bool {
            let path = child.standardizedFileURL.path
            guard !seenPaths.contains(path) else { return false }
            // 符号链接防穿透
            guard SymlinkGuard.isSafePath(url: child) else { return false }
            // 双重保护集：规则库 + 物理红线
            if JunkEngine.isIgnoredPath(path) { return false }
            if ProtectedAssetPolicy.isMailPath(path) { return false }
            if kb.isLoaded, kb.isProtected(bundleID: ownershipName) { return false }

            let low = ownershipName.lowercased()
            if low.hasPrefix(".") || low.hasPrefix("com.apple.") || fullExclusions.contains(low) {
                return false
            }
            // 反向拓扑：仍有所属主体（在装应用 / 开发者工具链）→ 跳过
            if index.owns(ownershipName) { return false }
            // 活跃度守卫：最近仍在被写入 → 不是「已卸载应用」的遗留物
            if isActivelyUsed(child) { return false }

            guard let candidate = JunkRulePolicy.makeMeasuredCandidate(
                url: child,
                name: child.lastPathComponent,
                note: k.note,
                safety: k.caution ? .caution : .safe,
                minBytes: minSize,
                configure: {
                    $0.isSelected = false
                    if k.caution {
                        $0.locked = true
                    } else {
                        $0.ruleEvidence = CleanupRuleEvidence(
                            id: AppConfig.RuleIDs.leftoverOrphan,
                            tier: .review,
                            reason: .manualReview,
                            defaultSelected: false
                        )
                    }
                    $0.authorizationContext = .junkRule
                }
            ) else { return false }

            seenPaths.insert(path)
            residues.append(Residue(item: candidate, kind: k))
            return true
        }

        // ── 第一层：挥发性缓存 / 日志（始终允许）──
        for root in OrphanSafetyPolicy.permittedRoots {
            if stopped() || IOScanContext.isCancelled { return [] }
            guard FileUtil.exists(root.path) else { continue }
            for child in FileUtil.children(of: root) {
                if stopped() || IOScanContext.isCancelled { return [] }
                guard OrphanSafetyPolicy.isPermitted(url: child) else { continue }
                // 原版会列出 KB 级的偏好设置残留，故此处仅排除 0 字节空壳
                _ = accept(child, ownershipName: child.lastPathComponent,
                           kind: kind(for: root), minSize: 0)
            }
        }

        // ── 第二层：持久配置残留（Preferences / Application Support）──
        // 仅在「BundleID 形状 + 反向拓扑确证无主 + 非保护集」三重校验通过后放行，
        // 分级为 .caution 且默认锁定只读展示，绝不与第一层的「安全缓存」混同。
        for root in OrphanSafetyPolicy.conditionalRoots {
            if stopped() || IOScanContext.isCancelled { return [] }
            guard FileUtil.exists(root.path) else { continue }
            let isPrefs = root.lastPathComponent == "Preferences"

            for child in FileUtil.children(of: root) {
                if stopped() || IOScanContext.isCancelled { return [] }
                guard OrphanSafetyPolicy.isConditionallyPermitted(url: child) else { continue }

                let name = child.lastPathComponent

                // 形状校验：Preferences 只收 **BundleID 形状**的 .plist
                // （含点的 bundle ID 才能确认归属；loginwindow / replayd / siriknowledged
                //  这类系统守护进程的偏好设置不是「已卸载应用程序残留」）；
                // Application Support 只收目录。
                if isPrefs {
                    guard child.pathExtension.lowercased() == "plist" else { continue }
                } else {
                    var isDir: ObjCBool = false
                    guard FileManager.default.fileExists(atPath: child.path, isDirectory: &isDir),
                          isDir.boolValue else { continue }
                }

                let stem = isPrefs ? (name as NSString).deletingPathExtension : name
                let low = stem.lowercased()

                if isPrefs {
                    guard isBundleIDShaped(stem) else { continue }
                } else {
                    let shaped = isBundleIDShaped(stem)
                        || (low.count >= 5 && !low.contains(" ")
                            && low.rangeOfCharacter(from: CharacterSet(charactersIn: "/:")) == nil)
                    guard shaped else { continue }
                }
                if conditionalGenericNames.contains(low) { continue }

                _ = accept(child, ownershipName: stem, kind: kind(for: root), minSize: 0)
            }
        }

        guard !residues.isEmpty else { return [] }

        // ── 构造原版结构：单一分组「残留文件」+ 文件级明细 ──
        let items = residues
            .sorted { $0.item.size > $1.item.size }
            .map { r -> Node in
                let evaluated = JunkRulePolicy.apply(r.item)
                var node = Node.item(from: evaluated)
                node.icon = "cm_detail_app-leftovers_leftovers-item"
                node.tags = [categoryTag, r.kind.note]
                return node
            }

        let totalSize = items.reduce(Int64(0)) { $0 + $1.totalSize }
        let allSafe = items.allSatisfy { $0.safety == .safe && !$0.locked }
        let cautionCount = items.filter { $0.safety != .safe || $0.locked }.count

        let group = Node(name: groupName,
                         url: nil,
                         icon: "cm_detail_app-leftovers_leftovers",
                         note: groupDescription,
                         safety: allSafe ? .safe : .caution,
                         size: totalSize,
                         children: items,
                         isGroup: true,
                         tags: [categoryTag, "Leftovers"],
                         meta: [
                            ("Type", "App Leftovers"),
                            ("Size", Fmt.size(totalSize)),
                            ("Related Items", "\(items.count) items"),
                            ("Status", allSafe
                                ? "Application removed, only volatile caches/logs remaining"
                                : "Application removed, \(cautionCount) persistent configuration items shown read-only for manual verification")
                         ],
                         autoSelected: allSafe && items.allSatisfy { $0.autoSelected },
                         authorizationContext: .junkRule)

        return [group]
    }
}
