import SwiftUI
import AppKit
import UniformTypeIdentifiers

// ============================================================
//  SpaceLensView —— 空间透视模块
//
//  核心特性：
//    1. 顶部标题栏：去除冗余的副标题行（仅在待命态展示引导语），
//       右侧提供「可用 X GB / 共 Y GB」容量摘要、可视化模式开关与重新扫描按钮；
//    2. 面包屑导航栏：支持前进/后退箭头与层级折叠菜单；
//    3. 可视化模式（Visual Mode）：
//       - 左侧目录列表：原生 macOS 图标、名称、文件夹项数/文件类型、体积、右侧箭头；
//       - 交互对齐用户诉求：点击左侧/主体不跳入下一层，只刷新右侧展示该文件夹下的内容与体积；
//         点击右侧「>」箭头则跳转深入下一层；
//       - 右侧头部展示被点击文件夹名及「X 文件夹 Y 文件 | 共 Z GB」（琥珀色高亮）；
//       - 支持动态按需加载深层目录（有效解决 WeChat、Chrome 等深层应用容器提示为空无法查看的问题）；
//       - 比例矩形树图（Treemap）中，尾部零散小项聚合磁贴标题清晰展示为「其他 X 项」；
//    4. 非可视化模式（Non-Visual Mode，3 列分栏视图）：
//       - 精确只展示 3 列 Miller Columns，层级平滑推进与回溯；
//       - 单击当前三栏最后一列的文件夹立即推进展示下一层，无需繁琐双击；
//       - 深入目录支持动态探测真实文件，防止大文件夹出现为空阻断；
//       - 每一列均采用标准目录行渲染，选中项高亮，各列之间以细分割线对齐。
// ============================================================

// MARK: - 缓存与辅助类型

@MainActor
final class SpaceFileIconCache {
    static let shared = SpaceFileIconCache()
    var cache = NSCache<NSString, NSImage>()

    func icon(forPath path: String) -> NSImage {
        guard !path.isEmpty else {
            return NSWorkspace.shared.icon(for: .folder)
        }
        let key = path as NSString
        if let img = cache.object(forKey: key) {
            return img
        }
        let img = NSWorkspace.shared.icon(forFile: path)
        img.size = NSSize(width: 30, height: 30)
        cache.setObject(img, forKey: key)
        return img
    }
}

@MainActor
final class SpaceDirectoryCountCache {
    static let shared = SpaceDirectoryCountCache()
    var cache = NSCache<NSString, NSNumber>()

    func count(forPath path: String, fallback: Int = 0) -> Int {
        guard !path.isEmpty else { return fallback }
        let key = path as NSString
        if let num = cache.object(forKey: key) {
            return num.intValue
        }
        if let items = DirectoryChildrenRepository.shared.cached(forPath: path) {
            return items.count
        }
        return fallback
    }
}

/// 空间透视动态深层子节点缓存（当扫描树受限于初筛深度时，按需极速加载下一级真实目录）
final class SpaceDynamicChildrenCache: @unchecked Sendable {
    static let shared = SpaceDynamicChildrenCache()
    let lock = NSLock()
    var dict: [String: [Node]] = [:]

    func children(forPath path: String) -> [Node]? {
        lock.lock()
        defer { lock.unlock() }
        return dict[path]
    }

    func setChildren(_ children: [Node], forPath path: String) {
        lock.lock()
        defer { lock.unlock() }
        dict[path] = children
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        dict.removeAll()
    }
}

@MainActor
enum SpaceFileTypeHelper {
    static func subtitle(for item: Node) -> String {
        if item.isGroup || item.url?.hasDirectoryPath == true {
            let cnt = SpaceDirectoryCountCache.shared.count(forPath: item.path, fallback: item.children.count)
            return "\(cnt) \(L10n.localized(.unitItems))"
        }
        if let url = item.url {
            let ext = url.pathExtension
            if !ext.isEmpty, let uti = UTType(filenameExtension: ext) {
                if let desc = uti.localizedDescription, !desc.isEmpty {
                    return desc
                }
            }
            if !ext.isEmpty {
                return "\(ext.uppercased()) \(L10n.localized(.fileTypeFile))"
            }
        }
        return item.tags.first ?? L10n.localized(.fileTypeFile)
    }
}

// MARK: - 主视图

struct SpaceLensView: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var directoryChildren = DirectoryChildrenRepository.shared
    @ObservedObject var config = AppConfigStore.shared
    @ObservedObject var l10n = L10n.shared

    typealias VisualChartMode = SpaceChartMode
    typealias LeftPaneTab = SpacePane

    @State var isVisualMode: Bool = true
    @State var chartMode: VisualChartMode = .treemap
    @State var leftTab: LeftPaneTab = .directory
    @State var navPaths: [String] = []
    @State var forwardPaths: [[String]] = []
    @State var focusedItemId: UUID? = nil
    @State var col3SelectedId: UUID? = nil
    @State var keyMonitor: Any? = nil

    // MARK: - 动态路径解析与按需下钻（支持实时流式刷新与深层加载）

    /// 判断节点是否可以继续下钻进入（不仅看内存中的 children，更探测磁盘上的真实内容）
    func canDrillDown(_ node: Node) -> Bool {
        if !node.children.isEmpty { return true }
        if node.isGroup || node.url?.hasDirectoryPath == true {
            if let path = node.url?.path, !path.isEmpty {
                let cnt = SpaceDirectoryCountCache.shared.count(forPath: path, fallback: 0)
                if cnt > 0 { return true }
                if let cached = SpaceDynamicChildrenCache.shared.children(forPath: path), !cached.isEmpty {
                    return true
                }
            }
            if node.url?.pathExtension.isEmpty == true { return true }
        }
        return false
    }

    /// 动态获取节点的有效子项列表：优先使用扫描器树，若树叶受限则直接读取本地目录
    func effectiveChildren(of node: Node) -> [Node] {
        if !node.children.isEmpty {
            return node.children
        }
        guard node.isGroup || node.url?.hasDirectoryPath == true, let url = node.url else { return [] }
        let path = url.path
        guard !path.isEmpty else { return [] }

        if let cached = SpaceDynamicChildrenCache.shared.children(forPath: path) {
            return cached
        }

        return directoryChildren.children(for: url)
    }

    var resolvedNavNodes: [Node] {
        guard !navPaths.isEmpty, !state.roots.isEmpty else { return [] }
        var chain: [Node] = []
        var currentLevel = state.roots
        for path in navPaths {
            if let match = currentLevel.first(where: { $0.path == path })
                ?? findNode(byPath: path, in: currentLevel) {
                chain.append(match)
                currentLevel = effectiveChildren(of: match)
            } else {
                break
            }
        }
        return chain
    }

    func findNode(byPath targetPath: String, in nodes: [Node]) -> Node? {
        for n in nodes {
            if n.path == targetPath { return n }
            if (n.isGroup || n.url?.hasDirectoryPath == true), targetPath.hasPrefix(n.path + "/") {
                let kids = effectiveChildren(of: n)
                if let found = findNode(byPath: targetPath, in: kids) {
                    return found
                }
            }
        }
        return nil
    }

    var currentFolder: Node? {
        resolvedNavNodes.last
    }

    var directChildren: [Node] {
        let list: [Node]
        if let folder = currentFolder {
            list = effectiveChildren(of: folder)
        } else {
            list = state.roots
        }
        let filtered = state.search.isEmpty
            ? list
            : list.filter { $0.name.localizedCaseInsensitiveContains(state.search) }
        return filtered.sorted { $0.totalSize > $1.totalSize }
    }

    var topLargestLeaves: [Node] {
        let baseNodes = currentFolder.map { [$0] } ?? state.roots
        let all = baseNodes.allLeaves.filter { node in
            guard let url = node.url, !node.isGroup else { return false }
            return !url.hasDirectoryPath && !node.tags.contains("Folder") && !node.tags.contains(L10n.localized(.fileTypeFolder))
        }
        let filtered = state.search.isEmpty
            ? all
            : all.filter { $0.name.localizedCaseInsensitiveContains(state.search) }
        return Array(filtered.sorted { $0.totalSize > $1.totalSize }.prefix(50))
    }

    var currentFocusNode: Node? {
        if let id = focusedItemId, let found = directChildren.first(where: { $0.id == id }) {
            return found
        }
        return directChildren.first
    }

    var currentDirectoryTotalSize: Int64 {
        if let folder = currentFolder {
            return max(0, folder.totalSize)
        }
        return max(0, state.roots.reduce(0) { $0 + $1.totalSize })
    }

    var body: some View {
        ZStack {
            if state.scanning && state.roots.isEmpty {
                spaceScanningStageView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else if state.roots.isEmpty {
                spaceIdleStageView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                spaceResultStageView
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: state.scanning)
        .onReceive(directoryChildren.$revision) { _ in
            guard state.moduleKey == "spaceLens", !state.scanning else { return }
            directoryChildren.reconcile(&state.roots)
        }
        .onAppear {
            let sess = state.session(for: "spaceLens")
            navPaths = sess.spaceNavPaths
            focusedItemId = sess.spaceFocusedId
            isVisualMode = sess.spaceIsVisualMode
            chartMode = sess.spaceChartMode
            leftTab = sess.spaceLeftTab

            if focusedItemId == nil {
                focusedItemId = directChildren.first?.id
            }

            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 49 { // Spacebar
                    if let window = NSApp.keyWindow, let firstResponder = window.firstResponder,
                       firstResponder is NSTextView || firstResponder is NSTextField {
                        return event
                    }
                    if let focus = currentFocusNode {
                        state.quickLook(focus)
                        return nil
                    }
                }
                return event
            }
        }
        .onDisappear {
            if let m = keyMonitor {
                NSEvent.removeMonitor(m)
                keyMonitor = nil
            }
        }
        .onChange(of: isVisualMode) { newVisual in
            state.updateCurrentSession { $0.spaceIsVisualMode = newVisual }
        }
        .onChange(of: navPaths) { newPaths in
            state.updateCurrentSession { $0.spaceNavPaths = newPaths }
        }
        .onChange(of: focusedItemId) { newId in
            state.updateCurrentSession { $0.spaceFocusedId = newId }
        }
        .onChange(of: chartMode) { newMode in
            state.updateCurrentSession { $0.spaceChartMode = newMode }
        }
        .onChange(of: leftTab) { newTab in
            state.updateCurrentSession { $0.spaceLeftTab = newTab }
        }
    }

    // ============================================================
    // MARK: - 0. 顶部统一标题栏（去除扫描后冗余副标题行，支持容量与模式切换）
    // ============================================================

    var topHeaderStrip: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.localized(.moduleSpaceLens))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.text)

                if state.roots.isEmpty {
                    Text(L10n.localized(.spaceLensHeroSubtitle))
                        .font(.system(size: 12.5))
                        .foregroundStyle(Theme.sub)
                }
            }

            Spacer(minLength: 12)

            if !state.roots.isEmpty {
                diskAndFileStatusHeaderView
            }
        }
    }

    var diskAndFileStatusHeaderView: some View {
        HStack(spacing: 14) {
            // 容量信息：可用 X GB / 共 Y GB
            Text(freeAndTotalDiskText)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Theme.sub)
                .monospacedDigit()
                .lineLimit(1)

            // 重新扫描按钮
            Button {
                navPaths.removeAll()
                forwardPaths.removeAll()
                directoryChildren.clear()
                SpaceDynamicChildrenCache.shared.clear()
                state.startScan(for: "spaceLens", forceRestart: true)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .rotationEffect(.degrees(state.scanning ? 360 : 0))
                        .animation(state.scanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: state.scanning)
                    Text(L10n.localized(.actionRescan))
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Theme.sub)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Theme.cardElevated.opacity(0.85))
                )
            }
            .buttonStyle(.plain)

            // 可视化模式 Switch Toggle 开关
            HStack(spacing: 7) {
                Text(L10n.localized(.visualMode))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Theme.text)

                Toggle("", isOn: $isVisualMode)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
        }
    }

    var freeAndTotalDiskText: String {
        let free = Fmt.size(max(0, state.disk.total - state.disk.used))
        let total = Fmt.size(state.disk.total)
        return "\(L10n.localized(.labelFreeAvailable)) \(free) / \(L10n.localized(.labelTotal)) \(total)"
    }

    // ============================================================
    // ============================================================
    // MARK: - 面包屑导航栏（带前进/后退箭头、层级折叠与右侧详情统计/图表切换）
    // ============================================================

    var breadcrumbStrip: some View {
        HStack(alignment: .center, spacing: 10) {
            // 前进/后退按钮
            HStack(spacing: 4) {
                Button {
                    goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(navPaths.isEmpty ? Theme.tert : Theme.text)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Theme.card.opacity(navPaths.isEmpty ? 0.3 : 0.8))
                        )
                }
                .buttonStyle(.plain)
                .disabled(navPaths.isEmpty)

                Button {
                    goForward()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(forwardPaths.isEmpty ? Theme.tert : Theme.text)
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Theme.card.opacity(forwardPaths.isEmpty ? 0.3 : 0.8))
                        )
                }
                .buttonStyle(.plain)
                .disabled(forwardPaths.isEmpty)
            }

            breadcrumbNavigationView

            Spacer(minLength: 12)

            // 右侧信息区：当前聚焦目录/文件详情统计与图表模式切换（对齐红框与 Arrow 2）
            if isVisualMode {
                HStack(spacing: 12) {
                    let kids = (leftTab == .directory) ? directChildren : topLargestLeaves
                    let folders = kids.filter { $0.isGroup }.count
                    let files = kids.filter { !$0.isGroup }.count
                    let summaryText: String = {
                        if !kids.isEmpty {
                            return String(format: L10n.localized(.folderAndFileSummaryFormat), folders, files, Fmt.size(currentDirectoryTotalSize))
                        } else {
                            return "\(L10n.localized(.labelTotal)) \(Fmt.size(currentDirectoryTotalSize))"
                        }
                    }()

                    Text(summaryText)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.96, green: 0.58, blue: 0.12)) // 琥珀暖色
                        .monospacedDigit()

                    // 树图 / 行星切换
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            chartMode = (chartMode == .treemap) ? .orbit : .treemap
                        }
                    } label: {
                        Image(systemName: chartMode == .treemap ? "square.grid.3x2.fill" : "circle.hexagongrid.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.sub)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Theme.card))
                    }
                    .buttonStyle(.plain)
                    .help(chartMode == .treemap ? L10n.localized(.switchToOrbitLens) : L10n.localized(.switchToTreemap))
                }
            }
        }
    }

    var breadcrumbNavigationView: some View {
        let chain = resolvedNavNodes

        return HStack(spacing: 6) {
            Button {
                guard !navPaths.isEmpty else { return }
                forwardPaths.append(navPaths)
                withAnimation(.easeInOut(duration: 0.18)) {
                    navPaths.removeAll()
                    focusedItemId = directChildren.first?.id
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.accent)
                    Text(L10n.localized(.scopeWholeDisk))
                        .font(.system(size: 13, weight: chain.isEmpty ? .bold : .medium))
                        .foregroundStyle(chain.isEmpty ? Theme.text : Theme.sub)
                }
            }
            .buttonStyle(.plain)

            if chain.count > 3 {
                Text("›")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.tert)

                let hiddenCount = chain.count - 3
                Menu {
                    ForEach(0..<hiddenCount, id: \.self) { idx in
                        let node = chain[idx]
                        Button(node.name) {
                            forwardPaths.append(navPaths)
                            withAnimation(.easeInOut(duration: 0.18)) {
                                navPaths = Array(navPaths.prefix(idx + 1))
                                focusedItemId = effectiveChildren(of: node).first?.id
                            }
                        }
                    }
                } label: {
                    Text("···")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Theme.hover.opacity(0.6)))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                ForEach((chain.count - 3)..<chain.count, id: \.self) { index in
                    breadcrumbSegmentButton(chain: chain, index: index, isLastInPath: (index == chain.count - 1))
                }
            } else {
                ForEach(0..<chain.count, id: \.self) { index in
                    breadcrumbSegmentButton(chain: chain, index: index, isLastInPath: (index == chain.count - 1))
                }
            }
        }
    }

    @ViewBuilder
    func breadcrumbSegmentButton(chain: [Node], index: Int, isLastInPath: Bool) -> some View {
        let node = chain[index]
        Text("›")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.tert)

        Button {
            forwardPaths.append(navPaths)
            withAnimation(.easeInOut(duration: 0.18)) {
                navPaths = Array(navPaths.prefix(index + 1))
                focusedItemId = effectiveChildren(of: node).first?.id
            }
        } label: {
            Text(node.name)
                .font(.system(size: 13, weight: isLastInPath ? .bold : .medium))
                .foregroundStyle(isLastInPath ? Theme.text : Theme.sub)
                .lineLimit(1)
        }
        .buttonStyle(.plain)
    }

    // ============================================================
    // MARK: - 第一幕：待命态 (Act 1: Idle Stage)
    // ============================================================

    var spaceIdleStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 6)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Spacer(minLength: 6)

                    PulseOrbStageView(
                        isScanning: false,
                        sizeText: "",
                        unitText: "",
                        subtitle: L10n.localized(.statusReady),
                        themeColor: Theme.accent,
                        diameter: 140,
                        symbol: "chart.pie.fill"
                    )

                    VStack(spacing: 6) {
                        Text(L10n.localized(.spaceLensHeroMainTitle))
                            .font(.system(size: 23, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.text)

                        Text(L10n.localized(.spaceLensHeroMainDesc))
                            .font(.system(size: 12.5))
                            .foregroundStyle(Theme.sub)
                    }

                    HStack(spacing: 10) {
                        IdleSpaceFeatureCard(
                            title: L10n.localized(.chartTreemap),
                            tag: L10n.localized(.spaceLensFeatureTreemapTitle),
                            subtitle: L10n.localized(.spaceLensFeatureTreemapDesc),
                            systemName: "square.grid.3x2.fill",
                            primaryColor: Color(red: 0.38, green: 0.65, blue: 0.98),
                            secondaryColor: Color(red: 0.18, green: 0.42, blue: 0.88)
                        )

                        IdleSpaceFeatureCard(
                            title: L10n.localized(.chartOrbitLens),
                            tag: L10n.localized(.spaceLensFeatureOrbitTitle),
                            subtitle: L10n.localized(.spaceLensFeatureOrbitDesc),
                            systemName: "circle.hexagongrid.fill",
                            primaryColor: Color(red: 0.66, green: 0.36, blue: 0.96),
                            secondaryColor: Color(red: 0.46, green: 0.20, blue: 0.86)
                        )

                        IdleSpaceFeatureCard(
                            title: L10n.localized(.spaceLensFeatureDrillDownTitle),
                            tag: L10n.localized(.spaceLensFeatureDrillDownSubtitle),
                            subtitle: L10n.localized(.spaceLensFeatureDrillDownDesc),
                            systemName: "arrow.down.forward.and.arrow.up.backward",
                            primaryColor: Color(red: 0.98, green: 0.58, blue: 0.18),
                            secondaryColor: Color(red: 0.88, green: 0.40, blue: 0.08)
                        )

                        IdleSpaceFeatureCard(
                            title: L10n.localized(.spaceLensFeatureQuickLocateTitle),
                            tag: L10n.localized(.spaceLensFeatureQuickLocateSubtitle),
                            subtitle: L10n.localized(.spaceLensFeatureQuickLocateDesc),
                            systemName: "magnifyingglass.circle.fill",
                            primaryColor: Color(red: 0.24, green: 0.82, blue: 0.48),
                            secondaryColor: Color(red: 0.10, green: 0.62, blue: 0.35)
                        )
                    }
                    .padding(.horizontal, 16)

                    GlowingPillButton(
                        title: L10n.localized(.actionBuildSpaceLensMap),
                        icon: "sparkles",
                        tint: Theme.accent,
                        width: 184,
                        height: 42
                    ) {
                        navPaths.removeAll()
                        forwardPaths.removeAll()
                        directoryChildren.clear()
                SpaceDynamicChildrenCache.shared.clear()
                        state.startScan(for: "spaceLens", forceRestart: true)
                    }
                    .padding(.top, 4)

                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.accent.opacity(0.85))
                        Text(L10n.localized(.spaceLensSecurityGuaranteeNote))
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.tert)
                    }

                    Spacer(minLength: 6)
                }
                .frame(maxWidth: .infinity, minHeight: 460)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ============================================================
    // MARK: - 第二幕：分析中 (Act 2: Scanning Stage)
    // ============================================================

    var spaceScanningStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 34)
                .padding(.top, 24)
                .padding(.bottom, 6)

            VStack(spacing: 26) {
                Spacer()

                PulseOrbStageView(
                    isScanning: true,
                    sizeText: "\(Int(state.scanProgress * 100))",
                    unitText: "%",
                    subtitle: L10n.localized(.statusSpaceAnalyzingTitle),
                    themeColor: Theme.accent,
                    diameter: 220
                )

                VStack(spacing: 10) {
                    Text(L10n.localized(.statusBuildingSpaceMapPrompt))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.text)

                    Text(state.scanStatus.isEmpty ? L10n.localized(.statusScanningAllDirsAndLargeFilesPrompt) : state.scanStatus)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 520)
                }

                Button {
                    state.stopScan()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 12))
                        Text(L10n.localized(.actionStopAnalysis))
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .foregroundStyle(Theme.sub)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Theme.card.opacity(0.8))
                            .overlay(Capsule().strokeBorder(Theme.sep, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ============================================================
    // MARK: - 第三幕：结果态 (Act 3: Result Stage)
    // ============================================================

    var spaceResultStageView: some View {
        VStack(spacing: 0) {
            topHeaderStrip
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .padding(.bottom, 8)

            breadcrumbStrip
                .padding(.horizontal, 32)
                .padding(.bottom, 8)

            Divider().background(Theme.sep)

            if isVisualMode {
                visualModeContentView
            } else {
                nonVisualColumnsView
            }

            if state.selectedCount > 0 {
                bottomActionBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
