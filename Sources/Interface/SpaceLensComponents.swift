import SwiftUI
import AppKit

// ============================================================
//  MARK: - DirectoryItemRow —— 空间透镜目录行
// ============================================================

struct DirectoryItemRow: View {
    @EnvironmentObject var state: AppState
    let item: Node
    let isSelected: Bool
    let canDrillDown: Bool
    let onSelect: () -> Void
    let onDrillDown: () -> Void
    let onMoveToTrash: () -> Void

    @State var isHovered = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // 1. 原生 macOS 拟真图标（极速内存缓存，零卡顿）
            Group {
                if !item.path.isEmpty && item.url != nil {
                    Image(nsImage: SpaceFileIconCache.shared.icon(forPath: item.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: canDrillDown ? "folder.fill" : "doc.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(canDrillDown ? Theme.accent : Theme.sub)
                        .frame(width: 28, height: 28)
                }
            }

            // 2. 中间：文件/目录名 + 项数/文件类型
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(subtitleText)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            // 3. 右侧：文件大小 + 仅文件夹显示的「>」跳转箭头按钮
            HStack(spacing: 4) {
                Text(Fmt.size(item.totalSize))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.sub)
                    .monospacedDigit()
                    .lineLimit(1)

                if canDrillDown {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isSelected ? Theme.text : Theme.tert)
                        .frame(width: 18, height: 26)
                } else {
                    Spacer().frame(width: 18)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isSelected ? Theme.cardElevated.opacity(Theme.isDark ? 0.92 : 0.88) : (isHovered ? Theme.hover.opacity(0.45) : Color.clear))
                .overlay(
                    isSelected ? RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(Theme.accent.opacity(0.35), lineWidth: 1) : nil
                )
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            if canDrillDown {
                onDrillDown()
            } else {
                onSelect()
            }
        }
        .contextMenu {
            if canDrillDown {
                Button {
                    onDrillDown()
                } label: {
                    Label(L10n.localized(.actionOpenFolder), systemImage: "folder")
                }
            }
            Button {
                state.revealInFinder(item)
            } label: {
                Label(L10n.localized(.actionRevealInFinder), systemImage: "arrow.up.forward.app")
            }
            Button {
                state.quickLook(item)
            } label: {
                Label(L10n.localized(.actionQuickLook), systemImage: "eye")
            }
            Divider()
            Button(role: .destructive) {
                onMoveToTrash()
            } label: {
                Label(L10n.localized(.actionMoveToTrashAlt), systemImage: "trash")
            }
            .disabled(item.locked)
        }
    }

    var subtitleText: String {
        if item.badge == L10n.localized(.badgeCalculating) || item.badge == "Calculating" {
            return L10n.localized(.statusCalculating)
        }
        return SpaceFileTypeHelper.subtitle(for: item)
    }
}

// ============================================================
//  MARK: - TreemapCanvas —— 比例矩形树图 (尾部「其他 X 项」磁贴)
// ============================================================

struct TreemapCanvas: View {
    @EnvironmentObject var state: AppState
    var allItems: [Node]
    var totalSize: Int64
    var focusedId: UUID?
    var onSelect: (Node) -> Void
    var onDrillDown: (Node) -> Void
    var onMoveToTrash: (Node) -> Void

    struct DisplayTile: Identifiable {
        var id: UUID
        var node: Node?
        var title: String
        var size: Int64
        var isFolder: Bool
        var isAggregatedTail: Bool
        var rank: Int
    }

    struct TreemapRect: Identifiable {
        var id: UUID { tile.id }
        var tile: DisplayTile
        var rect: CGRect
    }

    var displayTiles: [DisplayTile] {
        let maxPrimary = 10
        if allItems.count <= maxPrimary + 1 {
            return allItems.enumerated().map { idx, n in
                DisplayTile(
                    id: n.id,
                    node: n,
                    title: n.name,
                    size: max(1, n.totalSize),
                    isFolder: n.isGroup || n.url?.hasDirectoryPath == true || !n.children.isEmpty,
                    isAggregatedTail: false,
                    rank: idx
                )
            }
        }

        var result: [DisplayTile] = allItems.prefix(maxPrimary).enumerated().map { idx, n in
            DisplayTile(
                id: n.id,
                node: n,
                title: n.name,
                size: max(1, n.totalSize),
                isFolder: n.isGroup || n.url?.hasDirectoryPath == true || !n.children.isEmpty,
                isAggregatedTail: false,
                rank: idx
            )
        }

        let tailSlice = allItems.dropFirst(maxPrimary)
        let tailSize = tailSlice.reduce(Int64(0)) { $0 + $1.totalSize }
        if tailSize > 0 {
            result.append(
                DisplayTile(
                    id: Node.stableID(forPath: "__treemap_tail_\(tailSlice.count)"),
                    node: tailSlice.first,
                    title: String(format: L10n.localized(.otherItemsCountFormat), tailSlice.count),
                    size: max(1, tailSize),
                    isFolder: false,
                    isAggregatedTail: true,
                    rank: maxPrimary
                )
            )
        }
        return result
    }

    var body: some View {
        GeometryReader { geo in
            let rects = computeTreemap(
                tiles: displayTiles,
                in: CGRect(origin: .zero, size: geo.size)
            )
            ZStack(alignment: .topLeading) {
                ForEach(rects) { item in
                    TreemapTileView(
                        item: item,
                        isFocused: focusedId != nil && item.tile.id == focusedId,
                        totalSize: totalSize,
                        onSelect: {
                            if let node = item.tile.node {
                                onSelect(node)
                            }
                        },
                        onDrillDown: {
                            if let node = item.tile.node, !item.tile.isAggregatedTail {
                                onDrillDown(node)
                            }
                        },
                        onRevealInFinder: {
                            if let node = item.tile.node {
                                state.revealInFinder(node)
                            }
                        },
                        onQuickLook: {
                            if let node = item.tile.node {
                                state.quickLook(node)
                            }
                        },
                        onMoveToTrash: {
                            if let node = item.tile.node, !item.tile.isAggregatedTail {
                                onMoveToTrash(node)
                            }
                        }
                    )
                    .frame(width: max(0, item.rect.width - 5), height: max(0, item.rect.height - 5))
                    .position(x: item.rect.midX, y: item.rect.midY)
                }
            }
        }
    }

    func computeTreemap(tiles: [DisplayTile], in rect: CGRect) -> [TreemapRect] {
        guard !tiles.isEmpty, rect.width > 4, rect.height > 4 else { return [] }
        return sliceTiles(tiles, in: rect)
    }

    func sliceTiles(_ tiles: [DisplayTile], in rect: CGRect) -> [TreemapRect] {
        guard !tiles.isEmpty else { return [] }
        if tiles.count == 1 {
            return [TreemapRect(tile: tiles[0], rect: rect)]
        }

        let total = tiles.reduce(Double(0)) { $0 + max(1.0, Double($1.size)) }
        var acc: Double = 0
        var splitIndex = 1
        let half = total / 2.0

        for i in 0..<tiles.count {
            acc += max(1.0, Double(tiles[i].size))
            if acc >= half {
                splitIndex = max(1, min(tiles.count - 1, i + 1))
                break
            }
        }

        let leftGroup = Array(tiles[0..<splitIndex])
        let rightGroup = Array(tiles[splitIndex..<tiles.count])
        let leftWeight = leftGroup.reduce(Double(0)) { $0 + max(1.0, Double($1.size)) }
        let ratio = CGFloat(max(0.14, min(0.86, leftWeight / max(1.0, total))))

        if rect.width >= rect.height {
            let w1 = rect.width * ratio
            let r1 = CGRect(x: rect.minX, y: rect.minY, width: w1, height: rect.height)
            let r2 = CGRect(x: rect.minX + w1, y: rect.minY, width: rect.width - w1, height: rect.height)
            return sliceTiles(leftGroup, in: r1) + sliceTiles(rightGroup, in: r2)
        } else {
            let h1 = rect.height * ratio
            let r1 = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: h1)
            let r2 = CGRect(x: rect.minX, y: rect.minY + h1, width: rect.width, height: rect.height - h1)
            return sliceTiles(leftGroup, in: r1) + sliceTiles(rightGroup, in: r2)
        }
    }
}

struct TreemapTileView: View {
    let item: TreemapCanvas.TreemapRect
    let isFocused: Bool
    let totalSize: Int64
    let onSelect: () -> Void
    let onDrillDown: () -> Void
    let onRevealInFinder: () -> Void
    let onQuickLook: () -> Void
    let onMoveToTrash: () -> Void

    @State var isHovered = false

    var body: some View {
        let w = item.rect.width
        let h = item.rect.height
        let pct = totalSize > 0 ? Double(item.tile.size) / Double(totalSize) * 100.0 : 0

        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tileGradient)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: isFocused ? Theme.accent.opacity(0.9) : Color.white.opacity(isHovered ? 0.36 : 0.20), location: 0),
                            .init(color: isFocused ? Theme.accent.opacity(0.4) : Color.white.opacity(isHovered ? 0.08 : 0.04), location: 0.35),
                            .init(color: Color.clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: isFocused ? 1.6 : 1.0
                )
                .shadow(
                    color: Color.black.opacity(Theme.isDark ? (isHovered ? 0.30 : 0.12) : 0.05),
                    radius: isHovered ? 8 : 3,
                    y: isHovered ? 4 : 1
                )

            if w > 40 && h > 28 {
                VStack(spacing: 3) {
                    HStack(spacing: 4) {
                        if !item.tile.isAggregatedTail && w > 76 {
                            Image(systemName: item.tile.isFolder ? "folder" : "doc")
                                .font(.system(size: min(13, max(10, min(w, h) * 0.09)), weight: .semibold))
                                .foregroundStyle(Theme.sub)
                        }

                        Text(item.tile.title)
                            .font(.system(size: min(14, max(10, min(w, h) * 0.095)), weight: .bold))
                            .foregroundStyle(item.tile.isAggregatedTail ? Theme.sub : Theme.text)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .padding(.horizontal, 6)

                    if h > 44 {
                        Text(tileSubtitleText)
                            .font(.system(size: min(12, max(9, min(w, h) * 0.08)), weight: .medium, design: .rounded))
                            .foregroundStyle(Theme.sub)
                            .monospacedDigit()
                    }
                }
            }

            if isHovered && !item.tile.isAggregatedTail && w >= 115 && h >= 64 {
                VStack {
                    Spacer()
                    HStack(spacing: 4) {
                        if item.tile.isFolder {
                            Button {
                                onDrillDown()
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 8))
                                    if w >= 170 {
                                        Text(L10n.localized(.actionEnterDirectory))
                                            .font(.system(size: 9.5, weight: .medium))
                                    }
                                }
                                .foregroundStyle(Theme.text)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.cardElevated.opacity(0.92)))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.6))
                            }
                            .buttonStyle(.plain)
                            .help(L10n.localized(.actionEnterDirectory))
                        }

                        Button {
                            onRevealInFinder()
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.system(size: 8))
                                if w >= 210 {
                                    Text(L10n.localized(.actionShowInFinder))
                                        .font(.system(size: 9.5, weight: .medium))
                                }
                            }
                            .foregroundStyle(Theme.text)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Theme.cardElevated.opacity(0.92)))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)
                        .help(L10n.localized(.actionRevealInFinder))

                        if let node = item.tile.node, !node.locked {
                            Button {
                                onMoveToTrash()
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 8))
                                        .foregroundStyle(Theme.red)
                                    if w >= 250 {
                                        Text(L10n.localized(.actionMoveToTrash))
                                            .font(.system(size: 9.5, weight: .medium))
                                            .foregroundStyle(Theme.red)
                                    }
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.cardElevated.opacity(0.92)))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.6))
                            }
                            .buttonStyle(.plain)
                            .help(L10n.localized(.actionMoveToTrashAlt))
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.16), value: isHovered)
        .animation(.easeInOut(duration: 0.16), value: isFocused)
        .onTapGesture {
            if item.tile.isFolder && !item.tile.isAggregatedTail {
                onDrillDown()
            } else {
                onSelect()
            }
        }
        .contextMenu {
            if !item.tile.isAggregatedTail {
                if item.tile.isFolder {
                    Button {
                        onDrillDown()
                    } label: {
                        Label(L10n.localized(.actionOpenFolder), systemImage: "folder")
                    }
                }
                Button {
                    onRevealInFinder()
                } label: {
                    Label(L10n.localized(.actionRevealInFinder), systemImage: "arrow.up.forward.app")
                }
                Button {
                    onQuickLook()
                } label: {
                    Label(L10n.localized(.actionQuickLook), systemImage: "eye")
                }
                Divider()
                Button(role: .destructive) {
                    onMoveToTrash()
                } label: {
                    Label(L10n.localized(.actionMoveToTrashAlt), systemImage: "trash")
                }
            }
        }
        .help("\(item.tile.title) — \(Fmt.size(item.tile.size)) (\(String(format: "%.1f%%", pct)))")
    }

    var tileSubtitleText: String {
        if item.tile.node?.badge == L10n.localized(.badgeCalculating) || item.tile.node?.badge == "Calculating" {
            return "\(L10n.localized(.statusCalculating)) · \(Fmt.size(item.tile.size))"
        }
        if let note = item.tile.node?.note, note.hasPrefix("≥") {
            return note
        }
        return Fmt.size(item.tile.size)
    }

    var tileGradient: LinearGradient {
        if item.tile.isAggregatedTail {
            return LinearGradient(
                colors: [
                    Theme.cardElevated.opacity(isHovered ? 0.95 : 0.72),
                    Theme.card.opacity(isHovered ? 0.85 : 0.58)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        let rank = item.tile.rank
        let baseColor: Color = {
            if isFocused {
                return Theme.accent
            }
            if rank < 3 {
                return Theme.accent
            } else if rank < 6 {
                return Theme.accent2
            } else {
                return Theme.cardElevated
            }
        }()

        let topAlpha: Double = {
            if isFocused { return Theme.isDark ? 0.38 : 0.28 }
            if isHovered { return Theme.isDark ? 0.30 : 0.22 }
            let boost = max(0.06, 0.26 - Double(rank) * 0.022)
            return Theme.isDark ? boost : boost * 0.85
        }()

        let bottomAlpha: Double = {
            if isFocused { return Theme.isDark ? 0.20 : 0.14 }
            if isHovered { return Theme.isDark ? 0.16 : 0.10 }
            let boost = max(0.03, 0.13 - Double(rank) * 0.015)
            return Theme.isDark ? boost : boost * 0.70
        }()

        return LinearGradient(
            colors: [
                baseColor.opacity(topAlpha),
                baseColor.opacity(bottomAlpha)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// ============================================================
//  MARK: - FocusPlanetBubbleView & SatelliteBubbleView
// ============================================================

struct FocusPlanetBubbleView: View {
    var node: Node
    var diameter: CGFloat
    var sharePercent: Double = 0
    @State var isHovered = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.accent.opacity(0.35), Color.clear],
                        center: .center, startRadius: diameter * 0.38, endRadius: diameter * 0.62
                    )
                )
                .frame(width: diameter * 1.28, height: diameter * 1.28)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.accent.opacity(0.92),
                            Theme.accent2.opacity(0.85),
                            Theme.accent.opacity(0.65)
                        ],
                        center: UnitPoint(x: 0.42, y: 0.38),
                        startRadius: diameter * 0.08,
                        endRadius: diameter * 0.55
                    )
                )
                .frame(width: diameter, height: diameter)
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.45), lineWidth: 1.2)
                )
                .shadow(color: Color.black.opacity(0.28), radius: 14, y: 6)

            VStack(spacing: max(3, diameter * 0.026)) {
                Image(systemName: node.children.isEmpty ? "doc.fill" : "folder.fill")
                    .font(.system(size: min(44, max(22, diameter * 0.20))))
                    .foregroundStyle(Theme.onAccent)

                Text(node.name)
                    .font(.system(size: min(17, max(11.5, diameter * 0.075)), weight: .bold))
                    .foregroundStyle(Theme.onAccent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: diameter * 0.82)

                Text(Fmt.size(node.totalSize))
                    .font(.system(size: min(15, max(10.5, diameter * 0.066)), weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.onAccent.opacity(0.92))
                    .monospacedDigit()

                if sharePercent > 0.05 && diameter >= 136 {
                    Text(String(format: "%.1f%%", min(100, sharePercent)))
                        .font(.system(size: min(11.5, max(9.5, diameter * 0.050)), weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.onAccent.opacity(0.75))
                        .monospacedDigit()
                }
            }
        }
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.spring(response: 0.30, dampingFraction: 0.75), value: isHovered)
        .onHover { isHovered = $0 }
        .help("\(node.name) — \(Fmt.size(node.totalSize))\(sharePercent > 0 ? String(format: " (%.1f%%)", min(100, sharePercent)) : "")")
    }
}

struct SatelliteBubbleView: View {
    var node: Node
    var diameter: CGFloat
    var sharePercent: Double = 0
    @State var isHovered = false

    var body: some View {
        let norm = max(0.0, min(1.0, (diameter - 36.0) / 110.0))
        ZStack {
            Circle()
                .fill(Theme.cardElevated)
                .frame(width: diameter, height: diameter)
                .overlay(
                    Circle().fill(
                        Theme.accent.opacity(isHovered ? 0.30 : (0.10 + norm * 0.14))
                    )
                )
                .overlay(
                    Circle().strokeBorder(
                        isHovered ? Theme.accent : Theme.accent.opacity(0.38 + norm * 0.25),
                        lineWidth: isHovered ? 1.6 : max(0.9, 0.9 + norm * 0.5)
                    )
                )
                .shadow(color: Color.black.opacity(0.18 + norm * 0.10), radius: 4 + norm * 5, y: 2)

            VStack(spacing: diameter >= 72 ? 3 : 1) {
                if diameter >= 62 {
                    Image(systemName: node.children.isEmpty ? "doc.fill" : "folder.fill")
                        .font(.system(size: min(28, max(12, diameter * 0.20))))
                        .foregroundStyle(Theme.accent)
                }

                Text(node.name)
                    .font(.system(size: min(14, max(8.5, diameter * 0.125)), weight: .bold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: max(26, diameter - 10))

                if diameter >= 44 {
                    Text(Fmt.size(node.totalSize))
                        .font(.system(size: min(12, max(7.5, diameter * 0.105)), weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .monospacedDigit()
                }
            }
        }
        .scaleEffect(isHovered ? 1.08 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.70), value: isHovered)
        .contentShape(Circle())
        .onHover { isHovered = $0 }
        .help("\(node.name) — \(Fmt.size(node.totalSize))\(sharePercent > 0 ? String(format: " (%.1f%%)", min(100, sharePercent)) : "")")
    }
}

// ============================================================
//  MARK: - IdleSpaceFeatureCard
// ============================================================

struct IdleSpaceFeatureCard: View {
    let title: String
    let tag: String
    let subtitle: String
    let systemName: String
    let primaryColor: Color
    let secondaryColor: Color
    @State var hover = false

    var body: some View {
        VStack(spacing: 6) {
            OpticalSquircleIcon(
                systemName: systemName,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                size: 32
            )
            .scaleEffect(hover ? 1.08 : 1.0)

            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(tag)
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundStyle(hover ? Theme.accent : Theme.sub)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(width: 118, height: 96)
        .glassBentoCard(cornerRadius: 13, isHighlighted: false, isHovered: hover, padding: 6)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
        .help(subtitle)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: hover)
    }
}
