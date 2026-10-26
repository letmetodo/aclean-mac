import SwiftUI
import AppKit

// MARK: - 网络与公网 IP 详情浮窗卡片 

struct NetworkDetailPopoverCard: View {
    let detail: NetworkDetailSnapshot?
    @ObservedObject var geo = IPGeoService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "globe.asia.australia.fill")
                    .foregroundStyle(Theme.accent)
                Text(L10n.localized(.networkInterfacesAndPublicIpDiagnostics))
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Button {
                    Task { _ = await geo.refreshPublicIPAndLocation(forceAutoLocate: false) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.localized(.actionRefresh))
            }

            Divider().background(Theme.sep)

            detailRow(label: tr(.activeInterface), value: detail?.interfaceDisplayName ?? "en0")
            detailRow(label: tr(.localIPv4), value: detail?.localIPv4 ?? "—")
            detailRow(label: tr(.publicIp), value: geo.publicIP)
            detailRow(label: tr(.ispAndRegion), value: detail?.ispLocation ?? geo.ispName)
            detailRow(label: tr(.systemProxyOrTun), value: "\(detail?.proxyType ?? "Direct") · \(detail?.proxyHost ?? "")")
            detailRow(label: tr(.publicGatewayLatency), value: detail?.latencyMs.map { "\($0) ms" } ?? "—")
        }
        .padding(14)
        .frame(width: 290)
        .background(Theme.windowBg)
    }

    func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Theme.sub)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
        }
    }
}

// MARK: - 基础卡片与视觉组件（深浅色自适应）

struct BaseCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(14)
        .frame(height: 154)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.card))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.sep, lineWidth: 0.8)
        )
    }
}

struct PillTag: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(Theme.sub)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 4).fill(Theme.field))
    }
}

struct SpecTag: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 9.5, weight: .medium))
            .foregroundStyle(Theme.sub)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 3.5).fill(Theme.field))
            .lineLimit(1)
    }
}

struct FanModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Theme.onAccent : Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.accent : Theme.hover)
                        .overlay(
                            Capsule()
                                .strokeBorder(isSelected ? Theme.accent : Theme.sep, lineWidth: 0.8)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 3D 发光太阳星球球体 (支持健康度色温联动)

struct GlowingSunSphere: View {
    let size: CGFloat
    var score: Int = 95

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Theme.accent.opacity(0.45), Color.clear],
                    center: .center, startRadius: size * 0.3, endRadius: size * 0.65
                ))
                .frame(width: size * 1.25, height: size * 1.25)

            Circle()
                .fill(RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.95, blue: 0.65),
                        Theme.accent,
                        Theme.accent2,
                        Theme.accent.opacity(0.75)
                    ],
                    center: UnitPoint(x: 0.35, y: 0.35),
                    startRadius: 0,
                    endRadius: size * 0.55
                ))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Theme.accent.opacity(0.45), radius: 8, x: 0, y: 0)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - P/E 核分色多核心条形柱状图 (CoreBarsView)

struct CoreBarsView: View {
    let coreUsages: [Double]
    var eCoreCount: Int = 0

    var body: some View {
        let count = max(1, coreUsages.count)
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<count, id: \.self) { idx in
                let u = idx < coreUsages.count ? coreUsages[idx] : 0.05
                let isECore = idx < eCoreCount
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(isECore ? Theme.accent.opacity(0.65) : Theme.green)
                    .frame(height: max(3, CGFloat(u) * 24))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

struct BatteryRingView: View {
    let percent: Double
    var isCharging: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.sep, lineWidth: 3)
            Circle()
                .trim(from: 0, to: CGFloat(min(1.0, max(0.0, percent))))
                .stroke(Theme.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: isCharging ? "bolt.fill" : "laptopcomputer")
                .font(.system(size: 12))
                .foregroundStyle(isCharging ? Theme.green : Theme.text)
        }
    }
}

struct SparklineWaveView: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let points = data.suffix(30)
            let maxVal = max(points.max() ?? 1.0, 1.0)
            let w = proxy.size.width
            let h = proxy.size.height

            if points.count >= 2 {
                Path { path in
                    for (i, val) in points.enumerated() {
                        let x = w * CGFloat(i) / CGFloat(points.count - 1)
                        let norm = CGFloat(max(0, min(1.0, val / maxVal)))
                        let y = h * (1.0 - norm * 0.8) - 2
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

struct AreaWaveView: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let points = data.suffix(30)
            let w = proxy.size.width
            let h = proxy.size.height

            if points.count >= 2 {
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h))
                        for (i, val) in points.enumerated() {
                            let x = w * CGFloat(i) / CGFloat(points.count - 1)
                            let norm = CGFloat(max(0, min(1.0, val / 100.0)))
                            let y = h * (1.0 - norm * 0.85)
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(LinearGradient(
                        colors: [color.opacity(0.35), color.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    ))

                    Path { path in
                        for (i, val) in points.enumerated() {
                            let x = w * CGFloat(i) / CGFloat(points.count - 1)
                            let norm = CGFloat(max(0, min(1.0, val / 100.0)))
                            let y = h * (1.0 - norm * 0.85)
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, lineWidth: 1.5)
                }
            }
        }
    }
}
