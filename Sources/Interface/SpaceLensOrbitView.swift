import SwiftUI
import AppKit

extension SpaceLensView {
    // ============================================================
    // MARK: - 可视化模式：左侧目录面板 + 右侧选中文件夹透视图/树图
    // ============================================================

    var visualModeContentView: some View {
        HStack(spacing: 0) {
            // 左侧：当前目录列表
            leftDirectoryPanel
                .frame(width: 290)
                .background(Theme.sidebarBg.opacity(0.38))

            Divider().background(Theme.sep)

            // 右侧：被点击文件夹下的文件展示
            rightVisualPreviewPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.contentBg)
        }
    }

    var leftDirectoryPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. 顶部当前目录汇总：`X 项 · Y GB`
            HStack(spacing: 6) {
                if state.scanning {
                    ProgressView()
                        .controlSize(.mini)
                        .scaleEffect(0.75)
                }
                Text("\(directChildren.count) \(L10n.localized(.unitItems)) · \(Fmt.size(currentDirectoryTotalSize))")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.text)
                    .monospacedDigit()
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // 2. 「当前目录 · 最大文件」切换及返回上一级
            HStack(alignment: .center, spacing: 8) {
                Button {
                    leftTab = .directory
                } label: {
                    Text(L10n.localized(.scopeCurrentFolder))
                        .font(.system(size: 12, weight: leftTab == .directory ? .bold : .medium))
                        .foregroundStyle(leftTab == .directory ? Theme.text : Theme.tert)
                }
                .buttonStyle(.plain)

                Text("·")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.tert)

                Button {
                    leftTab = .largestFiles
                } label: {
                    Text(L10n.localized(.scopeLargestFiles))
                        .font(.system(size: 12, weight: leftTab == .largestFiles ? .bold : .medium))
                        .foregroundStyle(leftTab == .largestFiles ? Theme.text : Theme.tert)
                }
                .buttonStyle(.plain)

                Spacer()

                if !navPaths.isEmpty {
                    Button {
                        goBack()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 9.5, weight: .bold))
                            Text(L10n.localized(.actionParentDirectory))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Theme.sub)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            // 3. 目录层级列表
            ScrollView(showsIndicators: true) {
                LazyVStack(spacing: 2) {
                    let listData = (leftTab == .directory) ? directChildren : topLargestLeaves
                    let focusId = currentFocusNode?.id
                    ForEach(listData) { item in
                        DirectoryItemRow(
                            item: item,
                            isSelected: item.id == focusId,
                            canDrillDown: canDrillDown(item),
                            onSelect: {
                                // 左侧：单击 不要点到下一层，展示被点击文件夹下文件大小
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                    focusedItemId = item.id
                                }
                            },
                            onDrillDown: {
                                // 右侧：单击跳转到下一层
                                drillDown(item)
                            },
                            onMoveToTrash: {
                                moveNodeToTrash(item)
                            }
                        )
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }

            // 4. 底部右键提示
            HStack {
                Text(L10n.localized(.rightClickToOpenOrMoveToTrash))
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.tert)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
    }

    var rightVisualPreviewPanel: some View {
        VStack(spacing: 0) {
            if let url = currentFocusNode?.url, let failure = directoryChildren.failure(forPath: url.path) {
                HStack {
                    Label(failure.message, systemImage: "exclamationmark.triangle")
                        .font(.caption).lineLimit(3).textSelection(.enabled)
                    Spacer()
                    Button(L10n.localized(.actionRescan)) { directoryChildren.retry(url) }
                }
                .foregroundStyle(Theme.amber).padding(12)
            }
            rightVisualPreviewContent
        }
    }

    var rightVisualPreviewContent: some View {
        ZStack {
            let itemsToShow: [Node] = (leftTab == .directory) ? directChildren : topLargestLeaves

            if itemsToShow.isEmpty {
                if let focus = currentFocusNode, !focus.isGroup {
                    singleFilePreviewView(for: focus)
                } else if !state.scanning,
                          let currentPath = currentFocusNode?.url?.path,
                          let failure = directoryChildren.failure(forPath: currentPath) {
                    EmptyState(
                        icon: "exclamationmark.triangle",
                        title: L10n.localized(.scanCoverageIncomplete),
                        subtitle: failure.message
                    )
                } else {
                    EmptyState(
                        icon: "folder",
                        title: (state.scanning || currentFocusNode?.url.map { directoryChildren.isLoading(forPath: $0.path) } == true) ? L10n.localized(.analyzingDirectorySizes) : L10n.localized(.directoryIsEmpty),
                        subtitle: state.scanning ? state.scanStatus : L10n.localized(.chooseFolderOrRescanPrompt)
                    )
                }
            } else if chartMode == .treemap {
                TreemapCanvas(
                    allItems: itemsToShow,
                    totalSize: max(1, currentDirectoryTotalSize),
                    focusedId: focusedItemId,
                    onSelect: { item in
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            focusedItemId = item.id
                        }
                    },
                    onDrillDown: { item in
                        drillDown(item)
                    },
                    onMoveToTrash: { item in
                        moveNodeToTrash(item)
                    }
                )
                .padding(14)
            } else {
                planetaryOrbitCanvas(items: itemsToShow)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func singleFilePreviewView(for node: Node) -> some View {
        VStack(spacing: 16) {
            Image(nsImage: SpaceFileIconCache.shared.icon(forPath: node.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)

            VStack(spacing: 6) {
                Text(node.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(Fmt.size(node.totalSize))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.sub)
                    .monospacedDigit()

                if !node.path.isEmpty {
                    Text(node.path)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Theme.tert)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 32)
                }
            }

            HStack(spacing: 12) {
                Button {
                    state.revealInFinder(node)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.up.forward.app")
                        Text(L10n.localized(.actionRevealInFinder))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.card))
                }
                .buttonStyle(.plain)

                Button {
                    state.quickLook(node)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "eye")
                        Text(L10n.localized(.actionQuickLook))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.card))
                }
                .buttonStyle(.plain)

                if !node.locked {
                    Button(role: .destructive) {
                        moveNodeToTrash(node)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "trash")
                            Text(L10n.localized(.actionMoveToTrashAlt))
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.red)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.card))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ============================================================
    // MARK: - 非可视化模式（3 列 Miller Columns 分栏视图）
    // ============================================================

    struct MillerColumnsState {
        let col1Items: [Node]
        let col1SelectedId: UUID?
        let col2Items: [Node]
        let col2SelectedId: UUID?
        let col3Items: [Node]
        let col3SelectedId: UUID?
    }

    func computeMillerColumns() -> MillerColumnsState {
        let chain = resolvedNavNodes
        let roots = state.roots.sorted { $0.totalSize > $1.totalSize }

        if chain.isEmpty {
            let col1Items = roots
            let col1Selected = col1Items.first
            let col2Items = (col1Selected != nil ? effectiveChildren(of: col1Selected!) : []).sorted { $0.totalSize > $1.totalSize }
            let col2Selected = col2Items.first
            let col3Items = (col2Selected != nil ? effectiveChildren(of: col2Selected!) : []).sorted { $0.totalSize > $1.totalSize }
            return MillerColumnsState(
                col1Items: col1Items,
                col1SelectedId: col1Selected?.id,
                col2Items: col2Items,
                col2SelectedId: col2Selected?.id,
                col3Items: col3Items,
                col3SelectedId: col3SelectedId
            )
        } else if chain.count == 1 {
            let col1Items = roots
            let col1Selected = chain[0]
            let col2Items = effectiveChildren(of: col1Selected).sorted { $0.totalSize > $1.totalSize }
            let col2Selected = col2Items.first(where: { $0.id == focusedItemId }) ?? col2Items.first
            let col3Items = (col2Selected != nil ? effectiveChildren(of: col2Selected!) : []).sorted { $0.totalSize > $1.totalSize }
            return MillerColumnsState(
                col1Items: col1Items,
                col1SelectedId: col1Selected.id,
                col2Items: col2Items,
                col2SelectedId: col2Selected?.id,
                col3Items: col3Items,
                col3SelectedId: col3SelectedId
            )
        } else if chain.count == 2 {
            let col1Items = roots
            let col1Selected = chain[0]
            let col2Items = effectiveChildren(of: col1Selected).sorted { $0.totalSize > $1.totalSize }
            let col2Selected = chain[1]
            let col3Items = effectiveChildren(of: col2Selected).sorted { $0.totalSize > $1.totalSize }
            return MillerColumnsState(
                col1Items: col1Items,
                col1SelectedId: col1Selected.id,
                col2Items: col2Items,
                col2SelectedId: col2Selected.id,
                col3Items: col3Items,
                col3SelectedId: col3SelectedId
            )
        } else {
            // chain.count >= 3：显示后 3 个层级，精确 3 列
            let n = chain.count
            let parentCol1 = chain[n - 3]
            let col1Items = effectiveChildren(of: parentCol1).sorted { $0.totalSize > $1.totalSize }
            let col1Selected = chain[n - 2]

            let parentCol2 = chain[n - 2]
            let col2Items = effectiveChildren(of: parentCol2).sorted { $0.totalSize > $1.totalSize }
            let col2Selected = chain[n - 1]

            let parentCol3 = chain[n - 1]
            let col3Items = effectiveChildren(of: parentCol3).sorted { $0.totalSize > $1.totalSize }

            return MillerColumnsState(
                col1Items: col1Items,
                col1SelectedId: col1Selected.id,
                col2Items: col2Items,
                col2SelectedId: col2Selected.id,
                col3Items: col3Items,
                col3SelectedId: col3SelectedId
            )
        }
    }

    var nonVisualColumnsView: some View {
        let cols = computeMillerColumns()
        return HStack(spacing: 0) {
            millerColumn(
                items: cols.col1Items,
                selectedId: cols.col1SelectedId,
                columnIndex: 1,
                onSelect: { node in
                    handleCol1Select(node)
                },
                onDrillDown: { node in
                    handleCol1Select(node)
                }
            )

            Divider().background(Theme.sep)

            millerColumn(
                items: cols.col2Items,
                selectedId: cols.col2SelectedId,
                columnIndex: 2,
                onSelect: { node in
                    handleCol2Select(node)
                },
                onDrillDown: { node in
                    handleCol2Select(node)
                }
            )

            Divider().background(Theme.sep)

            millerColumn(
                items: cols.col3Items,
                selectedId: cols.col3SelectedId,
                columnIndex: 3,
                onSelect: { node in
                    handleCol3Select(node)
                },
                onDrillDown: { node in
                    handleCol3DrillDown(node)
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.contentBg)
    }

    func millerColumn(
        items: [Node],
        selectedId: UUID?,
        columnIndex: Int,
        onSelect: @escaping (Node) -> Void,
        onDrillDown: @escaping (Node) -> Void
    ) -> some View {
        VStack(spacing: 0) {
            if items.isEmpty {
                VStack {
                    Spacer()
                    Text(L10n.localized(.directoryIsEmpty))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.tert)
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: true) {
                    LazyVStack(spacing: 2) {
                        ForEach(items) { item in
                            DirectoryItemRow(
                                item: item,
                                isSelected: item.id == selectedId,
                                canDrillDown: canDrillDown(item),
                                onSelect: {
                                    onSelect(item)
                                },
                                onDrillDown: {
                                    onDrillDown(item)
                                },
                                onMoveToTrash: {
                                    moveNodeToTrash(item)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func handleCol1Select(_ node: Node) {
        forwardPaths.append(navPaths)
        let chain = resolvedNavNodes
        if chain.count <= 2 {
            navPaths = [node.path]
        } else {
            navPaths = Array(navPaths.prefix(chain.count - 2)) + [node.path]
        }
        focusedItemId = effectiveChildren(of: node).first?.id
        col3SelectedId = nil
    }

    func handleCol2Select(_ node: Node) {
        forwardPaths.append(navPaths)
        let chain = resolvedNavNodes
        if chain.count <= 1 {
            if let firstRoot = state.roots.first {
                navPaths = [firstRoot.path, node.path]
            } else {
                navPaths = [node.path]
            }
        } else {
            navPaths = Array(navPaths.prefix(chain.count - 1)) + [node.path]
        }
        focusedItemId = node.id
        col3SelectedId = nil
    }

    func handleCol3Select(_ node: Node) {
        if canDrillDown(node) {
            // 单击最后一列（第三列）的文件夹：直接推进展现下一层！绝不需要双击！
            handleCol3DrillDown(node)
        } else {
            // 单击文件：选中高亮该文件
            col3SelectedId = node.id
            focusedItemId = node.id
        }
    }

    func handleCol3DrillDown(_ node: Node) {
        guard canDrillDown(node) else {
            col3SelectedId = node.id
            focusedItemId = node.id
            return
        }
        forwardPaths.append(navPaths)
        let chain = resolvedNavNodes
        if chain.isEmpty {
            if let firstRoot = state.roots.first {
                let rKids = effectiveChildren(of: firstRoot)
                if let firstChild = rKids.first {
                    navPaths = [firstRoot.path, firstChild.path, node.path]
                } else {
                    navPaths = [firstRoot.path, node.path]
                }
            } else {
                navPaths = [node.path]
            }
        } else {
            navPaths.append(node.path)
        }
        col3SelectedId = nil
        let children = effectiveChildren(of: node)
        focusedItemId = children.first?.id
    }

    // ============================================================
    // MARK: - 行星轨道透镜 (Planetary Orbit Space Lens)
    // ============================================================

    struct OrbitSatellitePlacement: Identifiable {
        let id: UUID
        let node: Node
        let diameter: CGFloat
        let position: CGPoint
        let sharePercent: Double
    }

    func planetaryOrbitCanvas(items: [Node]) -> some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let canvasSpan = max(320, min(w, h))
            let centerPoint = CGPoint(x: w * 0.50, y: h * 0.50)
            let centerNode = items.first
            let satellites = Array(items.dropFirst().prefix(14))
            let totalSize = max(1, items.reduce(Int64(0)) { $0 + $1.totalSize })
            let planetDiameter = focusPlanetDiameter(
                centerNode: centerNode,
                allItems: items,
                canvasSpan: canvasSpan
            )
            let placements = computeSatellitePlacements(
                satellites: satellites,
                allItems: items,
                totalDirSize: totalSize,
                centerPoint: centerPoint,
                planetDiameter: planetDiameter,
                canvasSize: proxy.size
            )
            let guideOrbitRadius = placements.isEmpty
                ? planetDiameter * 0.78
                : placements.reduce(CGFloat(0)) { $0 + hypot($1.position.x - centerPoint.x, $1.position.y - centerPoint.y) } / CGFloat(placements.count)

            ZStack {
                Circle()
                    .stroke(
                        Theme.sep,
                        style: StrokeStyle(lineWidth: 1, dash: [4, 6])
                    )
                    .frame(width: guideOrbitRadius * 2.0, height: guideOrbitRadius * 2.0)
                    .position(centerPoint)

                ForEach(placements) { item in
                    Path { path in
                        path.move(to: centerPoint)
                        path.addLine(to: item.position)
                    }
                    .stroke(
                        Theme.accent.opacity(0.08 + min(0.22, item.sharePercent * 0.004)),
                        style: StrokeStyle(lineWidth: max(0.8, min(2.2, item.diameter * 0.014)), dash: [3, 5])
                    )
                }

                ForEach(placements) { item in
                    SatelliteBubbleView(
                        node: item.node,
                        diameter: item.diameter,
                        sharePercent: item.sharePercent
                    )
                    .position(item.position)
                    .onTapGesture {
                        drillDown(item.node)
                    }
                    .contextMenu {
                        if canDrillDown(item.node) {
                            Button {
                                drillDown(item.node)
                            } label: {
                                Label(L10n.localized(.actionOpenFolder), systemImage: "folder")
                            }
                        }
                        Button {
                            state.revealInFinder(item.node)
                        } label: {
                            Label(L10n.localized(.actionRevealInFinder), systemImage: "arrow.up.forward.app")
                        }
                        Button {
                            state.quickLook(item.node)
                        } label: {
                            Label(L10n.localized(.actionQuickLook), systemImage: "eye")
                        }
                        Divider()
                        Button(role: .destructive) {
                            moveNodeToTrash(item.node)
                        } label: {
                            Label(L10n.localized(.actionMoveToTrashAlt), systemImage: "trash")
                        }
                        .disabled(item.node.locked)
                    }
                }

                if let centerNode {
                    let centerShare = totalSize > 0
                        ? Double(max(0, centerNode.totalSize)) / Double(totalSize) * 100.0
                        : 100.0
                    FocusPlanetBubbleView(
                        node: centerNode,
                        diameter: planetDiameter,
                        sharePercent: centerShare
                    )
                    .position(centerPoint)
                    .onTapGesture {
                        drillDown(centerNode)
                    }
                    .contextMenu {
                        if canDrillDown(centerNode) {
                            Button {
                                drillDown(centerNode)
                            } label: {
                                Label(L10n.localized(.actionOpenFolder), systemImage: "folder")
                            }
                        }
                        Button {
                            state.revealInFinder(centerNode)
                        } label: {
                            Label(L10n.localized(.actionRevealInFinder), systemImage: "arrow.up.forward.app")
                        }
                        Button {
                            state.quickLook(centerNode)
                        } label: {
                            Label(L10n.localized(.actionQuickLook), systemImage: "eye")
                        }
                        Divider()
                        Button(role: .destructive) {
                            moveNodeToTrash(centerNode)
                        } label: {
                            Label(L10n.localized(.actionMoveToTrashAlt), systemImage: "trash")
                        }
                        .disabled(centerNode.locked)
                    }
                }
            }
        }
    }

    func focusPlanetDiameter(centerNode: Node?, allItems: [Node], canvasSpan: CGFloat) -> CGFloat {
        let minPlanet = max(118, min(140, canvasSpan * 0.23))
        let maxPlanet = max(176, min(232, canvasSpan * 0.40))
        guard let centerNode else { return (minPlanet + maxPlanet) * 0.5 }

        let positiveSizes = allItems.map { Double(max(Int64(1), $0.totalSize)) }
        let globalMax = positiveSizes.max() ?? 1.0
        let globalMin = positiveSizes.min() ?? 1.0
        let nodeBytes = Double(max(Int64(1), centerNode.totalSize))

        let ratioToMax = max(0.0, min(1.0, nodeBytes / max(1.0, globalMax)))
        let areaRootScore = pow(ratioToMax, 0.38)
        let logScore: Double
        if globalMax > globalMin * 1.05 {
            logScore = max(0.0, min(1.0, (log10(nodeBytes) - log10(globalMin)) / max(0.4, log10(globalMax) - log10(globalMin))))
        } else {
            logScore = 1.0
        }
        let score = 0.62 * areaRootScore + 0.38 * logScore
        return minPlanet + CGFloat(score) * (maxPlanet - minPlanet)
    }

    func computeSatellitePlacements(
        satellites: [Node],
        allItems: [Node],
        totalDirSize: Int64,
        centerPoint: CGPoint,
        planetDiameter: CGFloat,
        canvasSize: CGSize
    ) -> [OrbitSatellitePlacement] {
        guard !satellites.isEmpty else { return [] }

        let canvasSpan = max(320, min(canvasSize.width, canvasSize.height))
        let minSatDiameter = max(34, min(44, canvasSpan * 0.068))
        let maxSatDiameter = max(106, min(148, canvasSpan * 0.255))

        let satBytesList = satellites.map { Double(max(Int64(1), $0.totalSize)) }
        let maxSatBytes = satBytesList.max() ?? 1.0
        let minSatBytes = satBytesList.min() ?? 1.0
        let globalMaxBytes = allItems.map { Double(max(Int64(1), $0.totalSize)) }.max() ?? maxSatBytes

        let diameters: [CGFloat] = satellites.map { sat in
            let bytes = Double(max(Int64(1), sat.totalSize))
            if satellites.count == 1 || maxSatBytes <= minSatBytes * 1.02 {
                let singleRatio = pow(max(0.0, min(1.0, bytes / max(1.0, globalMaxBytes))), 0.40)
                return minSatDiameter + CGFloat(singleRatio) * (maxSatDiameter - minSatDiameter)
            }
            let cohortRatio = max(0.0, min(1.0, bytes / max(1.0, maxSatBytes)))
            let sqrtNorm = pow(cohortRatio, 0.42)
            let logSpan = max(0.35, log10(maxSatBytes) - log10(minSatBytes))
            let logNorm = max(0.0, min(1.0, (log10(bytes) - log10(minSatBytes)) / logSpan))
            let cohortToGlobal = max(0.55, min(1.0, pow(maxSatBytes / max(1.0, globalMaxBytes), 0.18)))
            let effectiveMaxDiameter = minSatDiameter + (maxSatDiameter - minSatDiameter) * CGFloat(cohortToGlobal)
            let blended = max(0.0, min(1.0, 0.58 * sqrtNorm + 0.42 * logNorm))
            return minSatDiameter + CGFloat(blended) * (effectiveMaxDiameter - minSatDiameter)
        }

        let count = satellites.count
        var placements: [OrbitSatellitePlacement] = []
        placements.reserveCapacity(count)

        let safeMargin = planetDiameter * 0.50
        let maxAvailableRadius = max(safeMargin + 60, min(canvasSize.width * 0.46, canvasSize.height * 0.46))

        for i in 0..<count {
            let sat = satellites[i]
            let d = diameters[i]
            let fraction = Double(i) / Double(max(1, count))
            let angle = fraction * 2.0 * .pi - (.pi / 2.0)
            let ringWave = (i % 2 == 0) ? 0.0 : 0.45
            let radius = safeMargin + d * 0.55 + 24.0 + ringWave * max(18.0, (maxAvailableRadius - safeMargin) * 0.32)
            let clampedRadius = min(maxAvailableRadius - d * 0.52, radius)

            let px = centerPoint.x + CGFloat(cos(angle)) * clampedRadius
            let py = centerPoint.y + CGFloat(sin(angle)) * clampedRadius
            let share = totalDirSize > 0 ? Double(max(0, sat.totalSize)) / Double(totalDirSize) * 100.0 : 0

            placements.append(
                OrbitSatellitePlacement(
                    id: sat.id,
                    node: sat,
                    diameter: d,
                    position: CGPoint(x: px, y: py),
                    sharePercent: share
                )
            )
        }
        return placements
    }

    // ============================================================
    // MARK: - 底部操作栏（当有勾选项目时浮现）
    // ============================================================

    var bottomActionBar: some View {
        HStack(alignment: .center, spacing: 14) {
            Text("\(L10n.localized(.labelSelected)) \(state.selectedCount) \(L10n.localized(.unitItems))")
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(Theme.text)
                .monospacedDigit()

            HStack(spacing: 6) {
                ActionLink(title: L10n.localized(.actionSelectAll), enabled: !directChildren.isEmpty) {
                    var next = state.selection
                    for c in directChildren where !c.locked { next.insert(c.id) }
                    state.selection = next
                }
                Text("·").foregroundStyle(Theme.tert)
                ActionLink(title: L10n.localized(.actionNone), enabled: state.selectedCount > 0) {
                    state.selection.removeAll()
                }
            }

            Spacer(minLength: 16)

            PrimaryPillButton(
                title: state.selectedSize > 0
                    ? "\(L10n.localized(.actionMoveToTrashAlt)) · \(Fmt.size(state.selectedSize))"
                    : L10n.localized(.actionMoveToTrashAlt),
                enabled: state.selectedCount > 0 && !state.scanning,
                busy: state.screen == .cleaning
            ) {
                state.commitClean()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            ZStack {
                VisualEffectView(material: .headerView, blendingMode: .withinWindow)
                Theme.card.opacity(Theme.isDark ? 0.75 : 0.88)
            }
        )
        .overlay(alignment: .top) {
            Divider().background(Theme.sep.opacity(0.6))
        }
    }

    // ============================================================
    // MARK: - 辅助导航操作与下钻
    // ============================================================

    func goBack() {
        guard !navPaths.isEmpty else { return }
        forwardPaths.append(navPaths)
        withAnimation(.easeInOut(duration: 0.18)) {
            _ = navPaths.removeLast()
            focusedItemId = directChildren.first?.id
            col3SelectedId = nil
        }
    }

    func goForward() {
        guard let next = forwardPaths.popLast() else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            navPaths = next
            focusedItemId = directChildren.first?.id
            col3SelectedId = nil
        }
    }

    func drillDown(_ node: Node) {
        guard canDrillDown(node) else {
            state.revealInFinder(node)
            return
        }
        guard !node.path.isEmpty else { return }
        forwardPaths.removeAll()
        withAnimation(.easeInOut(duration: 0.18)) {
            navPaths.append(node.path)
            focusedItemId = effectiveChildren(of: node).first?.id
            col3SelectedId = nil
        }
    }

    func moveNodeToTrash(_ node: Node) {
        guard CleanupSelectionPolicy.isUserSelectable(node), node.url != nil else {
            state.toast = L10n.localized(.toastSystemProtectedCannotRemove)
            return
        }
        let previous = state.selection
        state.selection = [node.id]
        state.commitClean()
        state.selection = previous
    }
}
