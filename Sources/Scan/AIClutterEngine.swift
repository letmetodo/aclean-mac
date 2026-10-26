import Foundation
import AppKit

// ============================================================
//  AI 垃圾文件引擎 (AIClutterEngine) —— AI 缓存与模型冗余扫描
//
//  对应原版 JunkCleanupModule 的 AIClutter 自定义流程：
//    · AI 垃圾文件 (AIToolScanning.framework 靶向工具聚合)
//        1. Chrome DevTools MCP
//        2. Gemini / Antigravity
//        3. Codex
//        4. Cursor
//        5. OpenCode
//        6. Claude Code
//        7. HuggingFace / PyTorch / ChatGPT 等现代开源模型与工具缓存
//    · 本地模型 (LocalModelScanning.framework 大模型文件隔离)
//        Ollama / LM Studio 下载的本地模型权重 (默认必须 isSelected = false)
// ============================================================

enum AIClutterEngine {

    static func scan(progress: (Double, String) -> Void, onGroupFound: ((ScanGroup) -> Void)? = nil) -> [ScanGroup] {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        var out: [ScanGroup] = []
        progress(0.1, "Scanning AI tool caches")
        if IOScanContext.isCancelled { return [] }
        if let g = scanAgentsJunk() {
            out.append(g)
            onGroupFound?(g)
        }
        progress(0.6, "Scanning local models")
        if IOScanContext.isCancelled { return out }
        if let m = scanLocalModels() {
            out.append(m)
            onGroupFound?(m)
        }
        progress(1, "Complete")
        return out
    }

    // MARK: - 1) AI 工具的缓存与日志 (收敛至 AppConfig.AIClutter)

    typealias AISubLocation = AppConfig.AIClutter.SubLocation
    typealias AIToolDefinition = AppConfig.AIClutter.ToolDefinition

    private static var toolDefinitions: [AIToolDefinition] {
        var definitions = AppConfig.AIClutter.toolDefinitions
        let store = KnowledgeBaseManager.shared.authored
        let directories = store.cacheDirectories(ruleID: AppConfig.RuleIDs.aiIDECache)
        for path in store.junk[AppConfig.RuleIDs.aiIDECache]?.paths ?? [] where !path.contains("{") && !path.contains("*") {
            let root = URL(fileURLWithPath: KBPaths.expand(path))
            guard !definitions.contains(where: { $0.name == root.lastPathComponent }) else { continue }
            let locations = directories.filter { $0.path.hasPrefix(root.path + "/") }
                .map { AISubLocation($0.lastPathComponent, $0.path) }
            if !locations.isEmpty {
                definitions.append(AIToolDefinition(name: root.lastPathComponent, note: "", subs: locations, appPaths: []))
            }
        }
        var existingSubPaths = Set(definitions.flatMap(\.subs).map { KBPaths.expand($0.path) })
        let dynamicRuleIDs: Set<String> = [AppConfig.RuleIDs.aiToolCache, AppConfig.RuleIDs.aiGeminiTmp]
        for binding in store.catalog.bindings where binding.status == .active && dynamicRuleIDs.contains(binding.ruleID) {
            let pattern = binding.pathTemplate
            guard !pattern.isEmpty, !pattern.contains("{"), !pattern.contains("*") else { continue }
            let expanded = KBPaths.expand(pattern)
            guard !existingSubPaths.contains(expanded) else { continue }
            existingSubPaths.insert(expanded)
            let url = URL(fileURLWithPath: expanded)
            let parentName = url.deletingLastPathComponent().lastPathComponent
            let label = url.lastPathComponent
            if let idx = definitions.firstIndex(where: { $0.name.caseInsensitiveCompare(parentName) == .orderedSame }) {
                var updated = definitions[idx].subs
                updated.append(AISubLocation(label, pattern))
                definitions[idx] = AIToolDefinition(
                    name: definitions[idx].name,
                    note: definitions[idx].note,
                    subs: updated,
                    appPaths: definitions[idx].appPaths,
                    safety: definitions[idx].safety,
                    isSelected: definitions[idx].isSelected
                )
            } else {
                definitions.append(AIToolDefinition(
                    name: parentName.isEmpty ? label : parentName,
                    note: "",
                    subs: [AISubLocation(label, pattern)],
                    appPaths: []
                ))
            }
        }
        return definitions
    }

    static func scanAgentsJunk() -> ScanGroup? {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        var items: [ScanItem] = []
        let home = FileUtil.home.path
        let definitions = toolDefinitions
        let authoredCacheDirectories = KnowledgeBaseManager.shared.authored.cacheDirectories(ruleID: AppConfig.RuleIDs.aiIDECache)

        // 解析当前正在使用的 Claude CLI 二进制真实路径（~/.local/bin/claude 符号链接目标），绝不删除当前版本
        let activeClaudeBinaryPath: String? = {
            let linkURL = URL(fileURLWithPath: home).appendingPathComponent(".local/bin/claude")
            guard FileUtil.exists(linkURL.path) else { return nil }
            return linkURL.resolvingSymlinksInPath().standardizedFileURL.path
        }()

        struct AICandidate {
            let defIndex: Int
            let sub: AISubLocation
            let url: URL
            let path: String
            let customLabel: String?
        }

        var candidates: [AICandidate] = []
        for (defIdx, def) in definitions.enumerated() {
            var seenPaths = Set<String>()
            var locations = def.subs
            // Keep authored discoveries in the actual scan, not only the rule-classification API.
            for url in authoredCacheDirectories
                where url.pathComponents.contains(def.name) {
                locations.append(AISubLocation(url.lastPathComponent, url.path))
            }
            for sub in locations {
                let path = sub.path.replacingOccurrences(of: "~", with: home)
                let url = URL(fileURLWithPath: path)
                guard FileUtil.exists(path), !FileUtil.isProtected(url), !JunkEngine.isIgnoredPath(path) else { continue }
                guard SymlinkGuard.isSafePath(url: url) else { continue }

                // 特殊处理 ~/.local/share/claude/versions：逐个枚举旧版本并排除当前生效的符号链接目标
                if sub.path == "~/.local/share/claude/versions" {
                    let children = FileUtil.children(of: url).sorted { $0.lastPathComponent < $1.lastPathComponent }
                    for (idx, verURL) in children.enumerated() {
                        let verStd = verURL.standardizedFileURL.path
                        // 排除当前软链指向的活跃版本，若无软链则保守排除字典序最新的最后一个版本
                        if let active = activeClaudeBinaryPath, (verStd == active || active.hasPrefix(verStd + "/")) {
                            continue
                        } else if activeClaudeBinaryPath == nil && idx == children.count - 1 {
                            continue
                        }
                        if seenPaths.contains(verStd) { continue }
                        seenPaths.insert(verStd)
                        candidates.append(AICandidate(
                            defIndex: defIdx,
                            sub: sub,
                            url: verURL,
                            path: verURL.path,
                            customLabel: "\(def.name) · Older Version (\(verURL.lastPathComponent))"
                        ))
                    }
                    continue
                }

                let std = url.standardizedFileURL.path
                if seenPaths.contains(std) { continue }
                if seenPaths.contains(where: { std.hasPrefix($0 + "/") || $0.hasPrefix(std + "/") }) { continue }
                seenPaths.insert(std)
                candidates.append(AICandidate(
                    defIndex: defIdx,
                    sub: sub,
                    url: url,
                    path: path,
                    customLabel: "\(def.name) · \(sub.label)"
                ))
            }
        }

        guard !candidates.isEmpty else { return nil }

        let store = KnowledgeBaseManager.shared.authored
        let sizes = ScanResultSlots<Int64>(repeating: 0, count: candidates.count)
        IOScanContext.concurrentPerform(iterations: candidates.count) { [candidates] i in
            let url = candidates[i].url
            if !store.isTrashChildrenOnlyContainer(url) {
                sizes[i] = FileUtil.size(of: url)
            }
        }

        var subsByDef: [Int: [ScanItem]] = [:]
        for (i, cand) in candidates.enumerated() {
            let def = definitions[cand.defIndex]
            let itemName = cand.customLabel ?? "\(def.name) · \(cand.sub.label)"
            let itemNote = cand.sub.note.isEmpty ? cand.path : cand.sub.note
            if store.isTrashChildrenOnlyContainer(cand.url) {
                if let subItem = JunkRulePolicy.makeMeasuredCandidate(
                    url: cand.url,
                    name: itemName,
                    note: itemNote,
                    safety: cand.sub.safety,
                    minBytes: 512,
                    configure: {
                        $0.action = .trash
                        $0.isSelected = cand.sub.isSelected
                    }
                ) {
                    subsByDef[cand.defIndex, default: []].append(subItem)
                }
                continue
            }
            let s = sizes[i]
            guard s > 512 else { continue }
            let subItem = ScanItem(
                url: cand.url,
                name: itemName,
                size: s,
                note: itemNote,
                safety: cand.sub.safety,
                action: .trash,
                isSelected: cand.sub.isSelected
            )
            subsByDef[cand.defIndex, default: []].append(subItem)
        }

        for (defIdx, def) in definitions.enumerated() {
            guard let subItems = subsByDef[defIdx], !subItems.isEmpty else { continue }
            let totalToolSize = subItems.reduce(0) { $0 + $1.size }
            guard totalToolSize > 1024 else { continue }
            let primaryURL = subItems.first!.url

            // 尝试提取应用真实高分辨率图标
            var appIcon: NSImage? = nil
            for ap in def.appPaths where FileUtil.exists(ap) {
                appIcon = NSWorkspace.shared.icon(forFile: ap)
                break
            }

            var toolItem = ScanItem(
                url: primaryURL,
                name: def.name,
                size: totalToolSize,
                note: def.note,
                safety: def.safety,
                action: .trash,
                isSelected: def.isSelected
            )
            toolItem.image = appIcon
            toolItem.children = subItems
            items.append(toolItem)
        }

        guard !items.isEmpty else { return nil }
        return ScanGroup(
            title: "AI Clutter Files",
            icon: "sparkles",
            note: "Caches, logs, and temporary files generated by AI tools such as Claude, Codex, Gemini, Cursor, etc.",
            tileName: "AI Clutter Files", tileQuantifier: "", tileVerb: "found",
            tileNote: "Clean caches, logs, residue files from AI tools, and unused local models.",
            tileIcon: "cm_detail_ai-clutter_ai-junk-files",
            tileKey: "aiClutter",
            safety: .safe,
            items: items.sorted { $0.size > $1.size }
        )
    }

    // MARK: - 2) 本地模型 (独立分组隔离，默认安全不勾选)

    /// LM Studio 等「按目录列出」的模型存储（收敛至 AppConfig.AIClutter）
    private static var modelPaths: [(String, String)] {
        AppConfig.AIClutter.localModelSearchPaths
    }

    static func scanLocalModels() -> ScanGroup? {
        let ruleTaskLease = RuleTaskGate.shared.begin()
        defer { withExtendedLifetime(ruleTaskLease) {} }
        var items: [ScanItem] = []
        // 1) Ollama：结构化解析 ~/.ollama/models/{manifests,blobs} + GGUF 识别
        items.append(contentsOf: scanOllamaModels())

        // 2) LM Studio 等：按目录逐个模型列项
        let home = FileUtil.home.path
        var seenModelPaths = Set<String>()
        for (raw, label) in modelPaths {
            let path = raw.replacingOccurrences(of: "~", with: home)
            guard FileUtil.exists(path), !JunkEngine.isIgnoredPath(path) else { continue }
            let base = URL(fileURLWithPath: path)
            let stdBase = base.standardizedFileURL.path
            guard !seenModelPaths.contains(stdBase) else { continue }
            seenModelPaths.insert(stdBase)
            // 逐个模型目录列出，便于用户按需选择
            let kids = FileUtil.children(of: base)
            if kids.isEmpty {
                let size = FileUtil.directorySize(base)
                guard size > 1024 * 1024 else { continue }
                var item = ScanItem(url: base, name: label, size: size, note: raw, safety: .caution)
                item.isSelected = false
                items.append(item)
            } else {
                for k in kids {
                    let size = FileUtil.directorySize(k)
                    guard size > 1024 * 1024 else { continue }
                    var item = ScanItem(
                        url: k,
                        name: "\(label) · \(k.lastPathComponent)",
                        size: size,
                        note: k.path,
                        safety: .caution
                    )
                    item.isSelected = false
                    items.append(item)
                }
            }
        }
        guard !items.isEmpty else { return nil }
        return ScanGroup(
            title: "Local Models",
            icon: "brain",
            note: "Models downloaded by Ollama and LM Studio can each reach several gigabytes. Deleting them requires re-downloading to restore.",
            tileName: "AI Clutter Files", tileQuantifier: "", tileVerb: "found",
            tileNote: "Clean caches, logs, residue files from AI tools, and unused local models.",
            tileIcon: "cm_detail_ai-clutter_local-models",
            tileKey: "aiClutter",
            safety: .caution,
            items: items.sorted { $0.size > $1.size }
        )
    }

    /// Ollama 模型存储解析（对应原版 OllamaStoreScanner）：
    ///   `manifests/<registry>/<ns>/<model>/<tag>` 为 JSON 清单，同时解析 `config.digest` 与 `layers[].digest` 引用的 `blobs/sha256-*` 数据块。
    ///   逐模型列项并将独享的权重 Blob 作为子节点关联；未被任何清单引用的真正孤立 Blob 单独列出并做 GGUF 魔数识别。
    private static func scanOllamaModels() -> [ScanItem] {
        let base = FileUtil.home.appendingPathComponent(".ollama/models")
        let manifests = base.appendingPathComponent("manifests")
        let blobs = base.appendingPathComponent("blobs")
        var items: [ScanItem] = []
        var referencedBlobs = Set<String>()
        var blobRefCount: [String: Int] = [:]

        struct ParsedManifest {
            let url: URL
            let rel: String
            let blobURLs: [URL]
        }
        var parsedManifests: [ParsedManifest] = []

        if FileUtil.exists(manifests.path),
           let en = FileManager.default.enumerator(
               at: manifests,
               includingPropertiesForKeys: [.isRegularFileKey],
               options: [.skipsHiddenFiles],
               errorHandler: { _, _ in true }) {
            while let f = en.nextObject() as? URL {
                guard let data = try? Data(contentsOf: f),
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
                var modelBlobs: [URL] = []
                if let config = obj["config"] as? [String: Any],
                   let cfgDigest = config["digest"] as? String {
                    let cfgBlob = blobs.appendingPathComponent(cfgDigest.replacingOccurrences(of: ":", with: "-"))
                    if FileUtil.exists(cfgBlob.path) {
                        modelBlobs.append(cfgBlob)
                        referencedBlobs.insert(cfgBlob.path)
                        blobRefCount[cfgBlob.path, default: 0] += 1
                    }
                }
                if let layers = obj["layers"] as? [[String: Any]] {
                    for layer in layers {
                        guard let digest = layer["digest"] as? String else { continue }
                        let blob = blobs.appendingPathComponent(digest.replacingOccurrences(of: ":", with: "-"))
                        if FileUtil.exists(blob.path) {
                            modelBlobs.append(blob)
                            referencedBlobs.insert(blob.path)
                            blobRefCount[blob.path, default: 0] += 1
                        }
                    }
                }
                guard !modelBlobs.isEmpty else { continue }
                let rel = f.path.replacingOccurrences(of: manifests.path + "/", with: "")
                parsedManifests.append(ParsedManifest(url: f, rel: rel, blobURLs: modelBlobs))
            }
        }

        for pm in parsedManifests {
            let manifestBytes: Int64 = max(FileUtil.size(of: pm.url), 512)
            var logicalSize: Int64 = manifestBytes
            var exclusiveSize: Int64 = manifestBytes
            var children: [ScanItem] = [
                ScanItem(url: pm.url, name: "Ollama Manifest · \(pm.rel)", size: manifestBytes,
                         note: pm.url.path, safety: .caution, isSelected: false)
            ]
            for b in pm.blobURLs {
                let s = FileUtil.size(of: b)
                logicalSize += s
                // 仅将引用计数为 1 的独享 Blob 纳入该模型的删除子节点，防止误删多标签共享层
                if blobRefCount[b.path] == 1 {
                    exclusiveSize += s
                    children.append(
                        ScanItem(url: b, name: "Ollama Weight Blob · \(pm.rel) (\(b.lastPathComponent.prefix(16)))",
                                 size: s, note: b.path, safety: .caution, isSelected: false)
                    )
                }
            }
            guard logicalSize > 1024 * 1024 else { continue }
            let modelNote = exclusiveSize < logicalSize
                ? L10n.format(.ollamaSharedBlobsNoteFormat, Fmt.size(logicalSize), Fmt.size(exclusiveSize))
                : L10n.localized(.cleanupProtectedReason)
            var item = ScanItem(url: pm.url, name: "Ollama Model · \(pm.rel)", size: logicalSize,
                                note: modelNote, safety: .caution, isSelected: false, children: children)
            item.isSelected = false
            items.append(item)
        }

        // 未被任何模型清单（含 config 与 layers）引用的孤立 Blob（默认只读保护展示）
        if FileUtil.exists(blobs.path) {
            for b in FileUtil.children(of: blobs) where !referencedBlobs.contains(b.path) {
                let s = FileUtil.size(of: b)
                guard s > 1024 * 1024 else { continue }
                let gguf = isGGUFBlob(b)
                var item = ScanItem(
                    url: b,
                    name: "Ollama Orphan Blob\(gguf ? " (GGUF)" : "") · \(b.lastPathComponent.prefix(18))",
                    size: s, note: L10n.localized(.ollamaOrphanBlobNote), safety: .caution)
                item.isSelected = false
                items.append(item)
            }
        }
        return items.map { original in
            var item = original
            item.locked = true
            if item.note.isEmpty || item.note == item.url.path {
                item.note = L10n.localized(.cleanupProtectedReason)
            }
            item.children = item.children.map { child in
                var copy = child; copy.locked = true; copy.isSelected = false
                copy.note = L10n.localized(.cleanupProtectedReason)
                return copy
            }
            return item
        }
    }

    /// GGUF 格式魔数识别（原版 GGUFCandidate）：文件头 4 字节为 ASCII "GGUF"
    private static func isGGUFBlob(_ url: URL) -> Bool {
        guard let h = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? h.close() }
        guard let head = try? h.read(upToCount: 4), head.count == 4 else { return false }
        return head == Data([0x47, 0x47, 0x55, 0x46])
    }
}
