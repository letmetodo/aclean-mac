import SwiftUI
import AppKit

extension MenuBarConfiguratorView {
    // MARK: - 瀑布流卡片拟真内容渲染（体现不同高度与不同跨度的真实视觉）
    // ============================================================

    @ViewBuilder
    func simulatedWaterfallCardBody(for section: DropdownSectionKind, span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        Group {
            switch section {
            case .healthBanner:
                simulatedHealthBanner(span: span, heightMode: heightMode)
            case .cpuCard:
                simulatedCPUCard(span: span, heightMode: heightMode)
            case .gpuCard:
                simulatedGPUCard(span: span, heightMode: heightMode)
            case .ramCard:
                simulatedRAMCard(span: span, heightMode: heightMode)
            case .diskCard:
                simulatedDiskCard(span: span, heightMode: heightMode)
            case .networkCard:
                simulatedNetworkThroughputCard(span: span, heightMode: heightMode)
            case .sensorCard:
                simulatedSensorCard(span: span, heightMode: heightMode)
            case .batteryCard:
                simulatedBatteryCard(span: span, heightMode: heightMode)
            case .weatherQuickCard:
                simulatedWeatherCard(span: span, heightMode: heightMode)
            case .dateTimeCard:
                simulatedDateTimeCard(span: span, heightMode: heightMode)
            case .networkDetailCard:
                simulatedNetworkDetailCard(span: span, heightMode: heightMode)
            case .topProcesses:
                simulatedTopProcesses(span: span, heightMode: heightMode)
            case .footerToolbar:
                simulatedFooterToolbar(span: span, heightMode: heightMode)
            case .hardwareGrid:
                simulatedCPUCard(span: span, heightMode: heightMode)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(Theme.isDark ? 0.24 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Theme.sep.opacity(0.5), lineWidth: 0.8)
        )
    }

    // 1. 系统健康横幅 (通栏卡片)
    func simulatedHealthBanner(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .strokeBorder(Color.green.opacity(0.35), lineWidth: 3)
                    .frame(width: heightMode == .compact ? 28 : 34, height: heightMode == .compact ? 28 : 34)
                Text("98")
                    .font(.system(size: heightMode == .compact ? 11.5 : 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(L10n.localized(.previewHealthScoreExcellent))
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(Theme.text)
                    Text(L10n.localized(.previewRunningNormally))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                }
                if heightMode != .compact {
                    Text(L10n.localized(.simulatedHardwareSpecsFormat))
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                }
            }

            Spacer()

            if span == .full {
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                    Text(L10n.localized(.previewQuickPurge))
                        .font(.system(size: 9.5, weight: .semibold))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Theme.accent.opacity(0.14)))
            }
        }
    }

    // 2. CPU 小卡片 (支持 S: 紧凑 / M: 标准等高 / L: 展开全量明细)
    func simulatedCPUCard(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        VStack(alignment: .leading, spacing: heightMode == .compact ? 4 : 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("18%")
                    .font(.system(size: heightMode == .compact ? 16 : 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text("46°C · 8P+4E")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.55))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color(red: 0.35, green: 0.85, blue: 0.55).opacity(0.14)))
            }

            switch heightMode {
            case .compact:
                // 紧凑 S: 单行微型进度条 + 频率
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hover)
                        Capsule().fill(Color(red: 0.35, green: 0.85, blue: 0.55)).frame(width: geo.size.width * 0.18)
                    }
                }
                .frame(height: 5)

                HStack {
                    Text(L10n.localized(.statusLowLoad))
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    Text("3.5 GHz")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                }

            case .standard:
                // 标准等高 M: 12 核紧凑柱状图 + 规整 P/E 核心比，与 GPU 等高完全对齐
                HStack(alignment: .bottom, spacing: 2.5) {
                    ForEach([0.35, 0.65, 0.40, 0.55, 0.25, 0.75, 0.30, 0.20, 0.15, 0.25, 0.10, 0.22], id: \.self) { ratio in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 0.35, green: 0.85, blue: 0.55).opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: max(3, CGFloat(ratio) * 14))
                    }
                }
                .frame(height: 14)

                HStack {
                    Text("P: 24% · E: 8%")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.55))
                    Spacer()
                    Text("Load 1.62")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                }

            case .expanded:
                // 展开 L: 24pt 高柱状图 + 频率 + 详细负载明细
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach([0.45, 0.72, 0.38, 0.60, 0.25, 0.82, 0.30, 0.18, 0.15, 0.22, 0.12, 0.28], id: \.self) { ratio in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color(red: 0.35, green: 0.85, blue: 0.55).opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: max(4, CGFloat(ratio) * 22))
                    }
                }
                .frame(height: 22)

                HStack {
                    Text(L10n.localized(.simulatedCpuBreakdownFormat))
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    Text("3.5 GHz")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                }

                HStack(spacing: 6) {
                    Text("P-Core: 24%")
                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(red: 0.35, green: 0.85, blue: 0.55))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.hover))
                    Text("E-Core: 8%")
                        .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.hover))
                    Spacer()
                    Text("Load 1.62")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                }
            }
        }
        .frame(minHeight: span == .half ? (heightMode == .compact ? 52 : (heightMode == .standard ? 76 : 110)) : nil)
    }

    // 3. GPU 小卡片 (支持 S: 紧凑 / M: 标准等高 / L: 展开详情)
    func simulatedGPUCard(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        VStack(alignment: .leading, spacing: heightMode == .compact ? 4 : 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("14%")
                    .font(.system(size: heightMode == .compact ? 16 : 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text(L10n.localized(.simulatedGpuCoreRenderFormat))
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.orange.opacity(0.14)))
            }

            switch heightMode {
            case .compact:
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hover)
                        Capsule().fill(Color.orange).frame(width: geo.size.width * 0.24)
                    }
                }
                .frame(height: 5)

                Text(L10n.localized(.statusLowLoad))
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.sub)

            case .standard:
                // 标准等高 M: 进度条 + 显存与核心频率，与 CPU 等高完全对齐
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hover)
                        Capsule().fill(Color.orange).frame(width: geo.size.width * 0.24)
                    }
                }
                .frame(height: 5)

                HStack {
                    Text(L10n.localized(.simulatedGpuMemoryLoadFormat))
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                    Spacer()
                    Text("980 MHz")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                }

            case .expanded:
                HStack(alignment: .bottom, spacing: 2.5) {
                    ForEach([0.2, 0.35, 0.25, 0.5, 0.45, 0.7, 0.3, 0.2, 0.15, 0.25, 0.4, 0.28], id: \.self) { r in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.orange.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: max(3, CGFloat(r) * 16))
                    }
                }
                .frame(height: 16)

                Text(L10n.localized(.simulatedGpuMemoryLoadFormat))
                    .font(.system(size: 9.5))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text("Metal 3D")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.hover))
                    Spacer()
                    Text("1.2 GHz · 16 Cores")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                }
            }
        }
        .frame(minHeight: span == .half ? (heightMode == .compact ? 52 : (heightMode == .standard ? 76 : 110)) : nil)
    }

    // 4. 内存小卡片 (支持 S: 紧凑 / M: 标准等高 / L: 展开详情)
    func simulatedRAMCard(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        VStack(alignment: .leading, spacing: heightMode == .compact ? 4 : 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("62%")
                    .font(.system(size: heightMode == .compact ? 16 : 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text(L10n.localized(.simulatedRamPressureNormal))
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(Color(red: 0.95, green: 0.80, blue: 0.35))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color(red: 0.95, green: 0.80, blue: 0.35).opacity(0.15)))
            }

            switch heightMode {
            case .compact:
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.95, green: 0.80, blue: 0.35)).frame(width: geo.size.width * 0.42)
                        RoundedRectangle(cornerRadius: 2).fill(Color.orange.opacity(0.7)).frame(width: geo.size.width * 0.20)
                        RoundedRectangle(cornerRadius: 2).fill(Theme.hover)
                    }
                }
                .frame(height: 5)

                Text(L10n.localized(.simulatedRamUsedTotalFormat))
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)

            case .standard:
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.95, green: 0.80, blue: 0.35)).frame(width: geo.size.width * 0.42)
                        RoundedRectangle(cornerRadius: 2).fill(Color.orange.opacity(0.7)).frame(width: geo.size.width * 0.20)
                        RoundedRectangle(cornerRadius: 2).fill(Theme.hover)
                    }
                }
                .frame(height: 5)

                HStack {
                    Text(L10n.localized(.simulatedRamUsedTotalFormat))
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    Text("Swap 0 MB")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                }
                .lineLimit(1)

            case .expanded:
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.95, green: 0.80, blue: 0.35)).frame(width: geo.size.width * 0.42)
                        RoundedRectangle(cornerRadius: 2).fill(Color.orange.opacity(0.7)).frame(width: geo.size.width * 0.20)
                        RoundedRectangle(cornerRadius: 2).fill(Theme.hover)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text(L10n.localized(.simulatedRamUsedTotalFormat))
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    Text(L10n.localized(.simulatedRamAppCompressedFormat))
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.sub.opacity(0.8))
                }
                .lineLimit(1)

                HStack(spacing: 5) {
                    Text("Wired 3.6G")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.hover))
                    Text("Swap 0 MB")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.hover))
                    Spacer()
                }
            }
        }
        .frame(minHeight: span == .half ? (heightMode == .compact ? 52 : (heightMode == .standard ? 76 : 110)) : nil)
    }

    // 5. 磁盘小卡片 (支持 S: 紧凑 / M: 标准等高 / L: 展开详情)
    func simulatedDiskCard(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        VStack(alignment: .leading, spacing: heightMode == .compact ? 4 : 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("175.4 GB")
                    .font(.system(size: heightMode == .compact ? 16 : 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text("Macintosh HD")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.cyan)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.14)))
            }

            switch heightMode {
            case .compact:
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hover)
                        Capsule().fill(Color.cyan).frame(width: geo.size.width * 0.65)
                    }
                }
                .frame(height: 5)

                Text(L10n.localized(.simulatedDiskIoFormat))
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)

            case .standard:
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hover)
                        Capsule().fill(Color.cyan).frame(width: geo.size.width * 0.65)
                    }
                }
                .frame(height: 5)

                HStack {
                    Text(L10n.localized(.simulatedDiskIoFormat))
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    Text("APFS 1TB")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                }
                .lineLimit(1)

            case .expanded:
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.hover)
                        Capsule().fill(Color.cyan).frame(width: geo.size.width * 0.65)
                    }
                }
                .frame(height: 6)

                Text(L10n.localized(.simulatedDiskIoFormat))
                    .font(.system(size: 9.5))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text("Read 12 MB/s")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.hover))
                    Text("Write 8 MB/s")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.hover))
                    Spacer()
                }
            }
        }
        .frame(minHeight: span == .half ? (heightMode == .compact ? 52 : (heightMode == .standard ? 76 : 110)) : nil)
    }

    // 6. 网络吞吐小卡片 (支持 S: 紧凑 / M: 标准等高 / L: 展开详情)
    func simulatedNetworkThroughputCard(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        VStack(alignment: .leading, spacing: heightMode == .compact ? 4 : 6) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("↓ 4.8 MB/s")
                        .font(.system(size: heightMode == .compact ? 13 : 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.teal)
                    if heightMode != .compact {
                        Text("↑ 320 KB/s")
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.sub)
                    }
                }
                Spacer()
                Text("Wi-Fi 6E")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.teal)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.teal.opacity(0.14)))
            }

            switch heightMode {
            case .compact:
                HStack {
                    Text("↑ 320 KB/s")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    Text("192.168.1.5")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                }

            case .standard:
                HStack(alignment: .bottom, spacing: 2.5) {
                    ForEach([0.2, 0.45, 0.7, 0.4, 0.85, 0.65, 0.5, 0.75], id: \.self) { v in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.teal.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .frame(height: max(3, CGFloat(v) * 12))
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("Total: 5.1 MB/s")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    Text("en0")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                }

            case .expanded:
                HStack(alignment: .bottom, spacing: 2.5) {
                    ForEach([0.2, 0.35, 0.6, 0.45, 0.85, 0.7, 0.4, 0.9, 0.65, 0.5, 0.75, 0.55], id: \.self) { v in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.teal.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .frame(height: max(3, CGFloat(v) * 16))
                    }
                }
                .frame(height: 16)

                HStack(spacing: 6) {
                    Text("Packets 4.2k/s")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.hover))
                    Spacer()
                    Text("Ping 12ms")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Color.teal)
                }
            }
        }
        .frame(minHeight: span == .half ? (heightMode == .compact ? 52 : (heightMode == .standard ? 76 : 110)) : nil)
    }

    // 7. 传感器与风扇小卡片 (支持 S: 紧凑 / M: 标准等高 / L: 展开详情)
    func simulatedSensorCard(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        VStack(alignment: .leading, spacing: heightMode == .compact ? 4 : 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("42°C")
                    .font(.system(size: heightMode == .compact ? 16 : 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)
                Spacer()
                Text("1320 RPM")
                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.orange)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.orange.opacity(0.14)))
            }

            switch heightMode {
            case .compact:
                Text(L10n.localized(.simulatedFanStatsFormat))
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)

            case .standard:
                Text(L10n.localized(.simulatedFanStatsFormat))
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)

                HStack {
                    Text("SoC: 44°C")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    Text("Ambient: 28°C")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                }

            case .expanded:
                Text(L10n.localized(.simulatedFanStatsFormat))
                    .font(.system(size: 9.5))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Text("CPU 42°C")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.hover))
                    Text("GPU 39°C")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.hover))
                    Spacer()
                    Text("Fan 35%")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Color.orange)
                }
            }
        }
        .frame(minHeight: span == .half ? (heightMode == .compact ? 52 : (heightMode == .standard ? 76 : 110)) : nil)
    }

    // 8. 电池与蓝牙外设通栏卡片
    func simulatedBatteryCard(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text("96%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.green)
                    Text(L10n.localized(.simulatedPowerAdapterFormat))
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(Theme.sub)
                }
                if heightMode != .compact {
                    Text(L10n.localized(.simulatedBatteryHealthCycleFormat))
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.sub)
                }
            }

            Spacer()

            if span == .full {
                HStack(spacing: 8) {
                    Label("AirPods 92%", systemImage: "airpodspro")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Theme.hover))

                    if heightMode != .compact {
                        Label("Magic Mouse 78%", systemImage: "computermouse.fill")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(Theme.text)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Theme.hover))
                    }
                }
            }
        }
    }

    // 9. 天气通栏卡片
    func simulatedWeatherCard(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "cloud.sun.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: heightMode == .compact ? 18 : 22))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(L10n.localized(.simulatedWeatherConditionFormat))
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(Theme.text)
                    Text(L10n.localized(.simulatedWeatherAqiFormat))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.green.opacity(0.14)))
                }
                if heightMode != .compact {
                    Text(L10n.localized(.simulatedWeatherForecastFormat))
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
    }

    // 10. 网络 IP 与延迟诊断通栏卡片
    func simulatedNetworkDetailCard(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.localized(.simulatedLanIpFormat))
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.text)
                if heightMode != .compact {
                    Text(L10n.localized(.simulatedPublicIpFormat))
                        .font(.system(size: 9.5))
                        .foregroundStyle(Theme.sub)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text(L10n.localized(.simulatedGatewayLatencyFormat))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.green)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.green.opacity(0.12)))
        }
    }

    // 11. 底部 Top 进程占用列表 (100% 宽度数据列表)
    func simulatedTopProcesses(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        let processCount: Int = {
            switch heightMode {
            case .compact:  return 2
            case .standard: return 3
            case .expanded: return 4
            }
        }()

        let allProcesses = [
            ("Xcode", "24.6%", "3.8 GB", Color.blue),
            ("Google Chrome Helper", "11.2%", "2.1 GB", Color.orange),
            ("WindowServer", "6.8%", "780 MB", Color.purple),
            ("AClean", "2.1%", "240 MB", Color.teal)
        ]

        return VStack(spacing: 5) {
            HStack {
                Text(L10n.localized(.simulatedColProcessName))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.sub)
                Spacer()
                Text(L10n.localized(.cpuAndMemoryUsageHeader))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.sub)
            }

            ForEach(Array(allProcesses.prefix(processCount)), id: \.0) { item in
                HStack(spacing: 8) {
                    Circle().fill(item.3).frame(width: 6, height: 6)
                    Text(item.0)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                    Spacer()
                    Text(item.1)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Theme.text)
                    Text(item.2)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundStyle(Theme.sub)
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
    }

    // 12. 底部快捷工具栏
    func simulatedFooterToolbar(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        HStack(spacing: 8) {
            Label(L10n.localized(.simulatedPrivacyNotInUse), systemImage: "checkmark.shield.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.green)
            Spacer()
            Label(L10n.localized(.simulatedKeepAwakeActive), systemImage: "cup.and.saucer.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.orange)
            Spacer()
            Label(L10n.localized(.simulatedPurgeMemory), systemImage: "sparkles")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Theme.accent)
        }
    }

    // 13. 日期时间与日历卡片 (对齐下拉面板顶部时间日历横幅)
    func simulatedDateTimeCard(span: DashboardGridSpan, heightMode: DashboardCardHeightMode) -> some View {
        let now = Date()
        let timeFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = L10n.shared.currentLocale
            f.dateFormat = "HH:mm"
            return f
        }()
        let dateFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = L10n.shared.currentLocale
            f.dateStyle = .medium
            f.timeStyle = .none
            return f
        }()
        let weekdayFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = L10n.shared.currentLocale
            f.dateFormat = "EEEE"
            return f
        }()

        return HStack(spacing: 10) {
            Image(systemName: "calendar")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.indigo)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(dateFormatter.string(from: now))
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text(weekdayFormatter.string(from: now))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.sub)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Text(timeFormatter.string(from: now))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.text)
                .monospacedDigit()
        }
    }
}
