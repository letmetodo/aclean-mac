import SwiftUI
import AppKit

// ============================================================
//  WeatherPopoverView —— Stats / Apple Weather 风格自适应主题气象看板
//
//  设计特性：
//    1. 彻底移除硬编码黑色背景与写死白色文字，100% 接入 Theme / StatsTheme 与 6 套主题预设；
//    2. 顶部实况 Bento 卡片：城市定位胶囊（支持全球城市搜索与 IP 自动重定位）、大字号实时温度、
//       体感温度、天气现象图标光晕、湿度 / 风速 / UV 指数微指标宫格；
//    3. 逐小时趋势卡片：支持鼠标连续悬浮 (onContinuousHover) 查看任意时间点的精确温度与降水概率；
//    4. 7 天预报卡片：自适应深浅色底槽与温度跨度渐变胶囊条。
// ============================================================

struct WeatherPopoverView: View {
    @ObservedObject private var weatherService = WeatherService.shared
    @ObservedObject private var geoService = IPGeoService.shared
    @ObservedObject private var config = MenuBarConfigStore.shared
    @ObservedObject private var appConfig = AppConfigStore.shared

    @State private var showCityPicker: Bool = false
    @State private var cityQuery: String = ""
    @State private var candidates: [CitySearchCandidate] = []
    @State private var isSearching: Bool = false
    @State private var hoveredHourIndex: Int? = nil

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        let snap = weatherService.current

        VStack(alignment: .leading, spacing: 10) {
            // 1. 顶部实时天气 Hero Bento 卡片
            ModernBentoCard(padding: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    topHeaderSection(snap)

                    if showCityPicker {
                        Divider().background(Theme.sep)
                        citySearchDrawer
                    }

                    if let msg = weatherService.statusMessage {
                        HStack(spacing: 6) {
                            if weatherService.isRefreshing {
                                ProgressView().controlSize(.mini)
                            } else {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                            }
                            Text(msg)
                                .font(.system(size: 10))
                                .foregroundColor(Theme.sub)
                                .lineLimit(1)
                            Spacer()
                            Button(L10n.localized(.actionRefresh)) {
                                weatherService.refreshWeather(forceAutoLocate: true)
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.accent)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(StatsTheme.boxBg))
                    }
                }
            }

            if snap.isLoadedFromNetwork && !snap.hourly.isEmpty {
                // 2. 24 小时逐时趋势预报卡片 (支持鼠标悬浮显示对应时间与数据)
                if config.weatherShow24hHourly {
                    ModernBentoCard(padding: 10) {
                        VStack(alignment: .leading, spacing: 8) {
                            StatsSeparatorHeader(title: L10n.localized(.weatherHourlyForecastSection))
                            hourlyForecastSection(snap.hourly)
                        }
                    }
                }

                // 3. 7 日天气趋势卡片
                if config.weatherShow7Day && !snap.daily.isEmpty {
                    ModernBentoCard(padding: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            StatsSeparatorHeader(title: L10n.localized(.weatherDailyForecastSection))
                            dailyForecastSection(snap.daily)
                        }
                    }
                }
            } else {
                // 离线或加载中状态卡片
                ModernBentoCard(padding: 18) {
                    VStack(spacing: 10) {
                        if weatherService.isRefreshing {
                            ProgressView()
                                .scaleEffect(0.9)
                            Text(L10n.localized(.weatherFetchingFromNetworkPrompt))
                                .font(.system(size: 11))
                                .foregroundColor(Theme.sub)
                                .multilineTextAlignment(.center)
                        } else {
                            Image(systemName: "icloud.slash")
                                .font(.system(size: 28))
                                .foregroundColor(Theme.sub.opacity(0.6))
                            Text(L10n.localized(.weatherNoRealtimeDataPrompt))
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundColor(Theme.text)
                            Text(L10n.localized(.weatherCheckNetworkOrManualPrompt))
                                .font(.system(size: 10.5))
                                .foregroundColor(Theme.sub)
                                .multilineTextAlignment(.center)
                            Button {
                                weatherService.refreshWeather(forceAutoLocate: true)
                            } label: {
                                Text(L10n.localized(.weatherRetryFetchPrompt))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Theme.onAccent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(Theme.accent))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 温度单位格式化
    private func formatTemp(_ celsius: Double, decimals: Int = 1) -> String {
        let val = config.weatherTempUnit == "F" ? (celsius * 9.0 / 5.0 + 32.0) : celsius
        return String(format: "%.\(decimals)f°", val)
    }

    private func formatTempInt(_ celsius: Int) -> String {
        let val = config.weatherTempUnit == "F"
            ? Int((Double(celsius) * 9.0 / 5.0 + 32.0).rounded())
            : celsius
        return "\(val)°"
    }

    // MARK: - 1. 顶部大温度与城市现状
    private func topHeaderSection(_ snap: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 顶部定位栏与刷新按钮
            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showCityPicker.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(Theme.accent)
                        Text(snap.city)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.text)
                        if !snap.regionAndCountry.isEmpty {
                            Text(snap.regionAndCountry)
                                .font(.system(size: 10))
                                .foregroundColor(Theme.sub)
                                .lineLimit(1)
                        }
                        Image(systemName: showCityPicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(Theme.sub)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(StatsTheme.boxBg))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    weatherService.refreshWeather(forceAutoLocate: false)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Theme.sub)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(StatsTheme.boxBg))
                }
                .buttonStyle(.plain)
                .help(L10n.localized(.weatherRefreshNowTooltip))
            }

            // 温度主视觉与天气图标
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(snap.isLoadedFromNetwork ? formatTemp(snap.currentTemp, decimals: 1) : "--°")
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.text)
                        .lineLimit(1)

                    Text(
                        snap.isLoadedFromNetwork
                            ? "\(snap.localizedConditionText) · \(L10n.format(.menuBarWeatherFeelsLikeFormat, config.weatherTempUnit == "F" ? snap.feelsLike * 1.8 + 32 : snap.feelsLike))"
                            : snap.localizedConditionText
                    )
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.sub)
                    .lineLimit(1)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.accent.opacity(0.22), Color.clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 32
                            )
                        )
                        .frame(width: 60, height: 60)

                    WeatherAdaptiveIconView(iconName: snap.conditionIcon, fontSize: 32)
                        .frame(width: 40, height: 40)
                        .shadow(color: Theme.accent.opacity(0.25), radius: 5, x: 0, y: 2)
                }
            }

            // 实况微指标三宫格：湿度 / 风速 / 紫外线
            if snap.isLoadedFromNetwork && config.weatherShowExtraMetrics {
                HStack(spacing: 6) {
                    weatherMetricPill(icon: "humidity.fill", label: "\(snap.humidity)%")
                    weatherMetricPill(icon: "wind", label: String(format: "%.0f km/h", snap.windSpeedKmh))
                    weatherMetricPill(icon: "sun.max.fill", label: String(format: "UV %.0f", snap.uvIndex))
                    Spacer(minLength: 0)
                    if !geoService.publicIP.isEmpty && !geoService.publicIP.contains("...") && !geoService.publicIP.contains("…") {
                        Text(geoService.publicIP)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(Theme.sub.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private func weatherMetricPill(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9.5))
                .foregroundColor(Theme.accent)
            Text(label)
                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                .foregroundColor(Theme.text)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3.5)
        .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(StatsTheme.boxBg))
    }

    // MARK: - 城市快速搜索抽屉
    private var citySearchDrawer: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                WeatherCitySearchInputField(
                    placeholder: L10n.localized(.weatherSearchCityPlaceholder),
                    text: $cityQuery,
                    fontSize: 11,
                    onSubmit: { performCitySearch() }
                )
                .frame(maxWidth: .infinity, minHeight: 16)
                .padding(.horizontal, 8)
                .padding(.vertical, 4.5)
                .background(RoundedRectangle(cornerRadius: 5).fill(StatsTheme.boxBg))

                Button(L10n.localized(.actionSearch)) {
                    performCitySearch()
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .controlSize(.mini)

                Button(L10n.localized(.actionIpLocate)) {
                    showCityPicker = false
                    weatherService.refreshWeather(forceAutoLocate: true)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            if isSearching {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.mini)
                    Text(L10n.localized(.weatherSearchingGlobalCoordsPrompt))
                        .font(.system(size: 10))
                        .foregroundColor(Theme.sub)
                }
            } else if !candidates.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(candidates.prefix(5)) { c in
                        Button {
                            geoService.selectManualCity(c)
                            candidates = []
                            cityQuery = ""
                            showCityPicker = false
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(Theme.accent)
                                    .font(.system(size: 10.5))
                                Text(c.displayTitle)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(Theme.text)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 5).fill(StatsTheme.boxBg))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func performCitySearch() {
        let q = cityQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        isSearching = true
        Task {
            let res = await geoService.searchCities(query: q)
            await MainActor.run {
                self.candidates = res
                self.isSearching = false
            }
        }
    }

    // MARK: - 2. 逐小时趋势预报带 (支持鼠标悬浮查看对应时间与温度/降水率)
    private func hourlyForecastSection(_ hourly: [HourlyWeatherItem]) -> some View {
        let temps = hourly.map { $0.temp }
        let minT = temps.min() ?? 15.0
        let maxT = temps.max() ?? 28.0
        let tSpan = max(1.0, maxT - minT)

        return VStack(spacing: 6) {
            // 交互式温度面积曲线区
            GeometryReader { proxy in
                let w = max(1, proxy.size.width)
                let h = max(1, proxy.size.height)
                let stepX = w / CGFloat(max(1, hourly.count - 1))
                let topPad: CGFloat = 6
                let botPad: CGFloat = 6
                let plotH = max(10, h - topPad - botPad)

                ZStack(alignment: .topLeading) {
                    // 面积填充
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h))
                        for (idx, item) in hourly.enumerated() {
                            let x = CGFloat(idx) * stepX
                            let norm = CGFloat((item.temp - minT) / tSpan)
                            let y = topPad + (1.0 - norm) * plotH
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.28), Theme.accent.opacity(0.03)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // 温度平滑折线
                    Path { path in
                        for (idx, item) in hourly.enumerated() {
                            let x = CGFloat(idx) * stepX
                            let norm = CGFloat((item.temp - minT) / tSpan)
                            let y = topPad + (1.0 - norm) * plotH
                            if idx == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [Theme.accent, StatsTheme.secondColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                    )

                    // 悬浮指示线与时间+温度+降水率气泡
                    if let idx = hoveredHourIndex, hourly.indices.contains(idx) {
                        let item = hourly[idx]
                        let cx = CGFloat(idx) * stepX
                        let norm = CGFloat((item.temp - minT) / tSpan)
                        let cy = topPad + (1.0 - norm) * plotH

                        Path { p in
                            p.move(to: CGPoint(x: cx, y: 0))
                            p.addLine(to: CGPoint(x: cx, y: h))
                        }
                        .stroke(Theme.text.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))

                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 6, height: 6)
                            .position(x: cx, y: cy)

                        HStack(spacing: 4) {
                            Text(item.localizedHour)
                                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Theme.sub)
                            Text(formatTemp(item.temp, decimals: 1))
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.text)
                            if item.precipProbability > 0 {
                                Text("💧\(item.precipProbability)%")
                                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Theme.accent)
                            }
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Theme.card.opacity(0.96))
                                .shadow(color: Color.black.opacity(0.16), radius: 2, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(Theme.sep, lineWidth: 0.6)
                        )
                        .frame(maxWidth: .infinity, alignment: cx > w * 0.55 ? .leading : .trailing)
                        .padding(.horizontal, 2)
                    }
                }
                .contentShape(Rectangle())
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let loc):
                        let ratio = min(1.0, max(0.0, loc.x / w))
                        hoveredHourIndex = min(hourly.count - 1, max(0, Int(round(ratio * CGFloat(hourly.count - 1)))))
                    case .ended:
                        hoveredHourIndex = nil
                    }
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(StatsTheme.boxBg))

            // 逐时标签与天气图标列
            HStack(spacing: 0) {
                ForEach(Array(hourly.enumerated()), id: \.element.id) { idx, item in
                    let isHovered = hoveredHourIndex == idx
                    VStack(spacing: 2.5) {
                        Text(item.localizedHour)
                            .font(.system(size: 9, weight: isHovered ? .bold : .medium, design: .monospaced))
                            .foregroundColor(isHovered ? Theme.accent : Theme.sub)

                        WeatherAdaptiveIconView(iconName: item.iconName, fontSize: 11)
                            .frame(height: 14)

                        Text(formatTemp(item.temp, decimals: 0))
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.text)

                        Text("\(item.precipProbability)%")
                            .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                            .foregroundColor(item.precipProbability > 0 ? Theme.accent : Theme.sub.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isHovered ? Theme.accent.opacity(0.12) : Color.clear)
                    )
                }
            }
        }
    }

    // MARK: - 3. 7 天天气预报列表
    private func dailyForecastSection(_ daily: [DailyWeatherItem]) -> some View {
        let globalMin = daily.map(\.minTemp).min() ?? 10
        let globalMax = daily.map(\.maxTemp).max() ?? 35
        let span = max(1, globalMax - globalMin)

        return VStack(spacing: 5) {
            ForEach(daily) { item in
                HStack(alignment: .center, spacing: 8) {
                    Text(item.localizedDayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.text)
                        .frame(width: 48, alignment: .leading)
                        .lineLimit(1)

                    WeatherAdaptiveIconView(iconName: item.iconName, fontSize: 12)
                        .frame(width: 18, alignment: .center)

                    Text(item.localizedSummary)
                        .font(.system(size: 9.5))
                        .foregroundColor(Theme.sub)
                        .frame(width: 44, alignment: .leading)
                        .lineLimit(1)

                    Text(formatTempInt(item.minTemp))
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(Theme.sub)
                        .frame(width: 28, alignment: .trailing)

                    GeometryReader { geo in
                        let w = geo.size.width
                        let startFrac = CGFloat(item.minTemp - globalMin) / CGFloat(span)
                        let endFrac = CGFloat(item.maxTemp - globalMin) / CGFloat(span)
                        let barW = max(8, w * (endFrac - startFrac))
                        ZStack(alignment: .leading) {
                            Capsule().fill(StatsTheme.trackColor)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.accent, Color.orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: barW)
                                .offset(x: w * startFrac)
                        }
                    }
                    .frame(height: 5)

                    Text(formatTempInt(item.maxTemp))
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .frame(width: 28, alignment: .trailing)
                }
                .padding(.vertical, 2)
            }
        }
    }
}
