import SwiftUI
import AppKit
import ServiceManagement

// ============================================================
//  MARK: - 性能任务专属视觉映射 (`PerformanceVisuals`)
// ============================================================

enum PerformanceVisuals {
    static func visual(for task: PerformanceEngine.MaintenanceTask) -> (icon: String, gradient: [Color]) {
        switch task.taskId {
        case "freeRAM":
            return ("memorychip", [Color(red: 0.35, green: 0.78, blue: 0.98), Color(red: 0.12, green: 0.53, blue: 0.90)])
        case "purgeableSpace":
            return ("internaldrive", [Color(red: 0.40, green: 0.85, blue: 0.55), Color(red: 0.15, green: 0.68, blue: 0.38)])
        case "flushDNS":
            return ("network", [Color(red: 0.65, green: 0.45, blue: 0.98), Color(red: 0.45, green: 0.25, blue: 0.85)])
        case "quickLookCache":
            return ("eye.fill", [Color(red: 0.98, green: 0.65, blue: 0.25), Color(red: 0.88, green: 0.45, blue: 0.15)])
        case "disableDSStore":
            return ("folder.badge.minus", [Color(red: 0.50, green: 0.75, blue: 0.95), Color(red: 0.30, green: 0.55, blue: 0.80)])
        case "vacuumDatabases":
            return ("cylinder.split.1x2", [Color(red: 0.95, green: 0.45, blue: 0.65), Color(red: 0.80, green: 0.25, blue: 0.50)])
        case "reindexSpotlight":
            return ("magnifyingglass", [Color(red: 0.98, green: 0.75, blue: 0.20), Color(red: 0.90, green: 0.55, blue: 0.10)])
        case "thinTimeMachine":
            return ("clock.arrow.circlepath", [Color(red: 0.30, green: 0.80, blue: 0.75), Color(red: 0.15, green: 0.60, blue: 0.55)])
        case "fixInputMethod":
            return ("keyboard", [Color(red: 0.40, green: 0.70, blue: 0.98), Color(red: 0.20, green: 0.50, blue: 0.85)])
        case "fixNotificationCenter":
            return ("bell.badge.fill", [Color(red: 0.98, green: 0.55, blue: 0.35), Color(red: 0.88, green: 0.35, blue: 0.20)])
        case "fixClipboardHandoff":
            return ("doc.on.clipboard.fill", [Color(red: 0.55, green: 0.80, blue: 0.45), Color(red: 0.35, green: 0.65, blue: 0.25)])
        case "fixFinderDock":
            return ("menubar.dock.rectangle", [Color(red: 0.70, green: 0.50, blue: 0.95), Color(red: 0.50, green: 0.30, blue: 0.80)])
        default:
            return ("wrench.and.screwdriver", [Theme.accent, Theme.accent2])
        }
    }
}

// ============================================================
//  MARK: - 「修复小毛病」单行 (`PerformanceQuickRow`)
// ============================================================

struct PerformanceQuickRow: View {
    @EnvironmentObject var state: AppState
    let task: PerformanceEngine.MaintenanceTask

    @State var hover = false
    @State var hoverAction = false

    var runStatus: String? {
        state.maintenanceRuns[task.name]
    }

    var body: some View {
        HStack(spacing: 12) {
            let vis = PerformanceVisuals.visual(for: task)
            GradientIconBadge(
                icon: vis.icon,
                size: 26,
                colors: vis.gradient,
                iconColor: .white,
                cornerRadius: 7,
                glow: false
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.text)
                Text(task.detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.tert)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            if runStatus == "Running…" || runStatus == tr(.running) || runStatus == tr(.statusRunningEllipsis) {
                ProgressView()
                    .controlSize(.small)
            } else if runStatus == "Completed" || runStatus == tr(.completed) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(L10n.localized(.refreshed))
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Theme.green)
            } else {
                Button {
                    state.runMaintenance(task)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9.5, weight: .bold))
                        Text(L10n.localized(.repair))
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    .foregroundStyle(hoverAction ? Color.white : Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4.5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(hoverAction ? Theme.accent : Theme.accent.opacity(0.14))
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .onHover { hoverAction = $0 }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 8)
        .background(hover ? Theme.hover.opacity(0.6) : Color.clear)
        .onHover { hover = $0 }
    }
}

// ============================================================
//  MARK: - 系统维护子项行 (`PerformanceTaskRow`)
// ============================================================

struct PerformanceTaskRow: View {
    @EnvironmentObject var state: AppState
    let task: PerformanceEngine.MaintenanceTask
    let isSelected: Bool
    let onToggle: () -> Void

    @State var hover = false
    @State var hoverAction = false

    var runStatus: String? {
        state.maintenanceRuns[task.name]
    }

    var body: some View {
        HStack(spacing: 12) {
            FluidCheckbox(state: isSelected ? .all : .none, a11yLabel: task.name, action: onToggle)

            let vis = PerformanceVisuals.visual(for: task)
            GradientIconBadge(
                icon: vis.icon,
                size: 26,
                colors: vis.gradient,
                iconColor: .white,
                cornerRadius: 7,
                glow: false
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(task.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.text)

                    if task.needsAdmin {
                        Text(L10n.localized(.labelRequiresAdminPrivileges))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.amber)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Theme.amber.opacity(0.14)))
                    }
                }

                Text(task.detail)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.tert)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            if runStatus == "Running…" || runStatus == tr(.running) || runStatus == tr(.statusRunningEllipsis) {
                ProgressView()
                    .controlSize(.small)
            } else if runStatus == "Completed" || runStatus == tr(.completed) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(L10n.localized(.completed))
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Theme.green)
            } else {
                Button {
                    state.runMaintenance(task)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text(L10n.localized(.run))
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    .foregroundStyle(hoverAction ? Color.white : Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4.5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(hoverAction ? Theme.accent : Theme.accent.opacity(0.14))
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .onHover { hoverAction = $0 }
            }
        }
        .padding(.leading, 36)
        .padding(.trailing, 22)
        .padding(.vertical, 8)
        .background(hover ? Theme.hover.opacity(0.6) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .onHover { hover = $0 }
    }
}

// ============================================================
//  MARK: - 启动项与后台服务行 (`StartupItemRow`)
// ============================================================

struct StartupItemRow: View {
    @EnvironmentObject var state: AppState
    let node: Node

    @State var hover = false
    @State var isToggling = false

    var primaryTitle: String {
        let rawName = node.startupItem?.displayName ?? node.name
        let disp = rawName.replacingOccurrences(of: ".plist", with: "")
        return disp.isEmpty ? (node.startupItem?.name ?? node.name) : disp
    }

    var secondaryTitle: String? {
        let orig = node.startupItem?.name ?? node.name
        if orig != primaryTitle && orig != "\(primaryTitle).plist" {
            return orig
        }
        return nil
    }

    var isBroken: Bool {
        node.startupItem?.broken == true || node.safety == .caution || node.icon == "bolt.slash" || node.note.contains("Invalid") || node.note.contains("Missing")
    }

    var isSystemManaged: Bool {
        node.locked || node.startupItem?.managedBySystemSettings == true
    }

    func toggleItem() {
        guard !isBroken, !isSystemManaged, !isToggling else { return }
        isToggling = true
        state.toggleStartupNode(node)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isToggling = false
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            startupIconView
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(primaryTitle)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)

                    if let sec = secondaryTitle {
                        Text(sec)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.tert)
                            .lineLimit(1)
                    }

                    if let scope = node.startupItem?.scope, !scope.isEmpty {
                        MetallicBadge(text: scope, color: Theme.sub)
                    }

                    if isBroken {
                        MetallicBadge(text: L10n.localized(.labelBrokenOrInvalid), color: Theme.red)
                    }
                }

                if !node.path.isEmpty {
                    Text(node.path)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Theme.tert)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: 12)

            if hover, let url = node.url {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.sub)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Theme.hover))
                }
                .buttonStyle(.plain)
                .help(L10n.localized(.actionRevealInFinder))
            }

            if !isBroken && !isSystemManaged {
                let enabled = state.startupEnabled(node)
                Button {
                    toggleItem()
                } label: {
                    HStack(spacing: 5) {
                        if isToggling {
                            ProgressView()
                                .controlSize(.mini)
                                .scaleEffect(0.75)
                        } else {
                            Circle()
                                .fill(enabled ? Theme.green : Theme.tert)
                                .frame(width: 6, height: 6)
                        }
                        Text(enabled ? L10n.localized(.statusEnabled) : L10n.localized(.statusDisabled))
                            .font(.system(size: 11.5, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .foregroundStyle(enabled ? Theme.green : Theme.sub)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(Capsule().fill(enabled ? Theme.green.opacity(0.14) : Theme.field))
                }
                .buttonStyle(.plain)
                .help(enabled ? L10n.localized(.actionClickToDisableThisItem) : L10n.localized(.actionClickToEnableThisItem))
            } else if !isBroken && isSystemManaged {
                Button {
                    SMAppService.openSystemSettingsLoginItems()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 10.5, weight: .semibold))
                        Text(L10n.localized(.actionDirectOpenFdaSettings))
                            .font(.system(size: 11.5, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .foregroundStyle(Theme.sub)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(Capsule().fill(Theme.field))
                }
                .buttonStyle(.plain)
                .help(L10n.localized(.actionOpenSystemSettings))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .glassBentoCard(
            cornerRadius: 12,
            isHighlighted: false,
            isHovered: hover,
            padding: 0
        )
        .contextMenu {
            if !isBroken && !isSystemManaged {
                let enabled = state.startupEnabled(node)
                Button(enabled ? L10n.localized(.statusDisable) : L10n.localized(.statusEnable)) {
                    toggleItem()
                }
                Divider()
            } else if !isBroken && isSystemManaged {
                Button(L10n.localized(.actionOpenSystemSettings)) {
                    SMAppService.openSystemSettingsLoginItems()
                }
                Divider()
            }
            if let url = node.url {
                Button(L10n.localized(.actionRevealInFinder)) {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
            if let appPath = node.startupItem?.appPath, !appPath.isEmpty {
                Button(L10n.localized(.actionRevealAppInFinder)) {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: appPath)])
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleItem()
        }
        .onHover { hover = $0 }
    }

    @ViewBuilder
    var startupIconView: some View {
        if let img = node.image ?? node.startupItem?.iconImage {
            Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if let appPath = node.startupItem?.appPath, !appPath.isEmpty {
            Image(nsImage: FileIconCache.shared.icon(for: appPath))
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if let url = node.url {
            Image(nsImage: FileIconCache.shared.icon(for: url.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16))
                .foregroundStyle(Theme.accent)
        }
    }
}

// ============================================================
//  MARK: - IdlePerfFeatureCard (首屏能力预览 Bento 微卡片)
// ============================================================

struct IdlePerfFeatureCard: View {
    let group: PerformanceGroupKind
    let tag: String
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

            Text(group.title)
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
        .help(group.subtitle)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: hover)
    }
}
