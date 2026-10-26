import SwiftUI
import AppKit

// MARK: - 原生可聚焦城市搜索输入框 (解决无边框 NSPanel / NSPopover 内 SwiftUI TextField 无法聚焦与中文输入法断词问题)

final class AppKitCitySearchTextField: NSTextField {
    var didInitialFocus = false

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard window != nil, !didInitialFocus else { return }
        didInitialFocus = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let win = self.window else { return }
            MenuBarCompanion.shared.focusWindowForTextInput(win)
            win.makeFirstResponder(self)
        }
    }

    override func mouseDown(with event: NSEvent) {
        MenuBarCompanion.shared.focusWindowForTextInput(self.window)
        super.mouseDown(with: event)
        if currentEditor() == nil {
            window?.makeFirstResponder(self)
        }
    }
}

struct WeatherCitySearchInputField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var fontSize: CGFloat = 10
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> AppKitCitySearchTextField {
        let tf = AppKitCitySearchTextField(frame: .zero)
        tf.delegate = context.coordinator
        tf.isBordered = false
        tf.drawsBackground = false
        tf.focusRingType = .none
        tf.isEditable = true
        tf.isSelectable = true
        tf.usesSingleLineMode = true
        tf.lineBreakMode = .byTruncatingTail
        tf.cell?.isScrollable = true
        tf.cell?.wraps = false
        tf.font = NSFont.systemFont(ofSize: fontSize)
        tf.textColor = NSColor(Theme.text)
        tf.stringValue = text
        tf.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor(Theme.sub),
                .font: NSFont.systemFont(ofSize: fontSize)
            ]
        )
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tf
    }

    func updateNSView(_ nsView: AppKitCitySearchTextField, context: Context) {
        context.coordinator.parent = self
        nsView.font = NSFont.systemFont(ofSize: fontSize)
        nsView.textColor = NSColor(Theme.text)
        nsView.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor(Theme.sub),
                .font: NSFont.systemFont(ofSize: fontSize)
            ]
        )
        let isComposing = (nsView.currentEditor() as? NSTextView)?.hasMarkedText() == true
        if !isComposing && nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: WeatherCitySearchInputField

        init(_ parent: WeatherCitySearchInputField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            if parent.text != tf.stringValue {
                parent.text = tf.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if textView.hasMarkedText() {
                    return false
                }
                parent.text = control.stringValue
                parent.onSubmit()
                return true
            }
            return false
        }
    }
}

// MARK: - 8. Step 118 紧凑精炼天气悬浮窗 (CompactWeatherFlyoutView)

struct CompactWeatherFlyoutView: View {
    @ObservedObject var weatherService = WeatherService.shared
    @ObservedObject var geoService = IPGeoService.shared
    @ObservedObject var config = MenuBarConfigStore.shared
    @ObservedObject var appConfig = AppConfigStore.shared

    @State private var showCityPicker: Bool = false
    @State private var cityQuery: String = ""
    @State private var candidates: [CitySearchCandidate] = []
    @State private var isSearching: Bool = false

    private func formatTemp(_ celsius: Double) -> String {
        let val = config.weatherTempUnit == "F" ? (celsius * 9.0 / 5.0 + 32.0) : celsius
        return String(format: "%.0f°", val)
    }

    private func formatTempWithUnit(_ celsius: Double) -> String {
        let val = config.weatherTempUnit == "F" ? (celsius * 9.0 / 5.0 + 32.0) : celsius
        return String(format: config.weatherTempUnit == "F" ? "%.0f°F" : "%.0f°C", val)
    }

    private func uvLevelDescription(_ uv: Double) -> String {
        switch uv {
        case ..<3: return L10n.localized(.menuBarWeatherUvLow)
        case 3..<6: return L10n.localized(.menuBarWeatherUvModerate)
        case 6..<8: return L10n.localized(.menuBarWeatherUvHigh)
        default: return L10n.localized(.menuBarWeatherUvVeryHigh)
        }
    }

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        let snap = weatherService.current
        let tempVal = snap.currentTemp
        let feelsVal = snap.feelsLike
        let highVal = Double(snap.daily.first?.maxTemp ?? Int(tempVal.rounded()))
        let lowVal = Double(snap.daily.first?.minTemp ?? Int(tempVal.rounded()))
        let humVal = snap.humidity

        let hourlySlice = Array(snap.hourly.prefix(24))
        let hTemps = hourlySlice.map(\.temp)
        let hMin = hTemps.min() ?? 10.0
        let hMax = max(hMin + 1.0, hTemps.max() ?? 30.0)

        let dailySlice = Array(snap.daily.prefix(6))
        let dMin = Double(dailySlice.map(\.minTemp).min() ?? 10)
        let dMax = max(dMin + 1.0, Double(dailySlice.map(\.maxTemp).max() ?? 32))

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Button {
                    showCityPicker.toggle()
                    SubcategoryFlyoutState.shared.isInteractingWithTextInput = showCityPicker
                    syncFlyoutPanelLayout()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9.5))
                            .foregroundColor(Theme.accent)
                        Text("\(snap.city) · \(L10n.localized(.menuBarWeatherRealtimeHeader))")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(Theme.text)
                            .lineLimit(1)
                        Image(systemName: showCityPicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Theme.sub)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // 快捷 °C / °F 单位切换按钮
                Button {
                    config.weatherTempUnit = (config.weatherTempUnit == "F") ? "C" : "F"
                } label: {
                    Text(config.weatherTempUnit == "F" ? "°F" : "°C")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .padding(.horizontal, 5.5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(StatsTheme.boxBg))
                }
                .buttonStyle(.plain)

                Button {
                    weatherService.refreshWeather(forceAutoLocate: true)
                } label: {
                    HStack(spacing: 3) {
                        if weatherService.isRefreshing {
                            ProgressView().controlSize(.mini)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        Text(L10n.localized(.actionIpLocate))
                            .font(.system(size: 8.5, weight: .medium))
                    }
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(StatsTheme.boxBg))
                }
                .buttonStyle(.plain)
            }

            if showCityPicker {
                ModernBentoCard(cornerRadius: 8, padding: 8) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 5) {
                            WeatherCitySearchInputField(
                                placeholder: L10n.localized(.weatherSearchCityPlaceholder),
                                text: $cityQuery,
                                fontSize: 10,
                                onSubmit: { performCitySearch() }
                            )
                            .frame(maxWidth: .infinity, minHeight: 15)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(RoundedRectangle(cornerRadius: 5).fill(StatsTheme.boxBg))

                            Button(L10n.localized(.actionSearch)) {
                                performCitySearch()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                            .controlSize(.mini)
                        }

                        if isSearching {
                            HStack(spacing: 5) {
                                ProgressView().controlSize(.mini)
                                Text(L10n.localized(.weatherSearchingGlobalCoordsPrompt))
                                    .font(.system(size: 9))
                                    .foregroundColor(Theme.sub)
                            }
                        } else if !candidates.isEmpty {
                            ForEach(candidates.prefix(4)) { c in
                                Button {
                                    geoService.selectManualCity(c)
                                    candidates = []
                                    cityQuery = ""
                                    showCityPicker = false
                                    SubcategoryFlyoutState.shared.isInteractingWithTextInput = false
                                    syncFlyoutPanelLayout()
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(Theme.accent)
                                            .font(.system(size: 9.5))
                                        Text(c.displayTitle)
                                            .font(.system(size: 9.5, weight: .medium))
                                            .foregroundColor(Theme.text)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(StatsTheme.boxBg))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            ModernBentoCard(cornerRadius: 9, padding: 8) {
                HStack(alignment: .center, spacing: 10) {
                    WeatherAdaptiveIconView(
                        iconName: snap.isLoadedFromNetwork ? snap.conditionIcon : "sun.max.fill",
                        fontSize: 28
                    )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(snap.isLoadedFromNetwork ? formatTempWithUnit(tempVal) : "--°")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.text)
                        Text(
                            snap.isLoadedFromNetwork
                                ? "\(snap.localizedConditionText) · \(L10n.format(.menuBarWeatherFeelsLikeFormat, feelsVal))"
                                : snap.localizedConditionText
                        )
                        .font(.system(size: 9.5))
                        .foregroundColor(Theme.sub)
                        .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.format(.menuBarWeatherHighLowFormat, highVal, lowVal))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Theme.text)
                        if !snap.regionAndCountry.isEmpty {
                            Text(snap.regionAndCountry)
                                .font(.system(size: 8.5, weight: .semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Capsule().fill(Theme.accent.opacity(0.14)))
                                .foregroundColor(Theme.accent)
                                .lineLimit(1)
                        }
                    }
                }
            }

            HStack(spacing: 5) {
                compactWeatherMetric(label: L10n.localized(.menuBarWeatherHumidityLabel), val: snap.isLoadedFromNetwork ? "\(humVal)%" : "—")
                compactWeatherMetric(label: L10n.localized(.menuBarWeatherWindLabel), val: snap.isLoadedFromNetwork ? String(format: "%.0f km/h", snap.windSpeedKmh) : "—")
                compactWeatherMetric(
                    label: L10n.localized(.menuBarWeatherUvLabel),
                    val: snap.isLoadedFromNetwork ? "UV \(Int(snap.uvIndex.rounded())) · \(uvLevelDescription(snap.uvIndex))" : "—"
                )
            }

            if !hourlySlice.isEmpty {
                ModernBentoCard(cornerRadius: 8, padding: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.localized(.weatherHourlyForecastSection))
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(Theme.accent)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(hourlySlice.enumerated()), id: \.offset) { idx, item in
                                    let ratio = CGFloat((item.temp - hMin) / (hMax - hMin))
                                    let barH = max(6, min(26, 6 + ratio * 20))
                                    compactHourCol(
                                        time: idx == 0 ? L10n.localized(.menuBarWeatherNowLabel) : item.hour,
                                        icon: item.iconName,
                                        temp: formatTemp(item.temp),
                                        barH: barH,
                                        isNow: idx == 0
                                    )
                                }
                            }
                            .padding(.vertical, 1)
                        }
                    }
                }
            }

            if !dailySlice.isEmpty {
                ModernBentoCard(cornerRadius: 8, padding: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.localized(.weatherDailyForecastSection))
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(Theme.accent)
                        ForEach(Array(dailySlice.enumerated()), id: \.element.id) { idx, item in
                            let start = CGFloat((Double(item.minTemp) - dMin) / (dMax - dMin))
                            let end = CGFloat((Double(item.maxTemp) - dMin) / (dMax - dMin))
                            let curMarker: CGFloat? = (idx == 0)
                                ? min(1.0, max(0.0, CGFloat((tempVal - dMin) / (dMax - dMin))))
                                : nil
                            compactForecastRow(
                                day: item.localizedDayName,
                                icon: item.iconName,
                                low: formatTemp(Double(item.minTemp)),
                                high: formatTemp(Double(item.maxTemp)),
                                start: min(0.85, max(0.0, start)),
                                end: min(1.0, max(start + 0.1, end)),
                                currentMarker: curMarker
                            )
                        }
                    }
                }
            }
        }
    }

    private func syncFlyoutPanelLayout() {
        DispatchQueue.main.async {
            MenuBarCompanion.shared.syncSubcategoryFlyoutPanel()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            MenuBarCompanion.shared.syncSubcategoryFlyoutPanel()
        }
    }

    private func performCitySearch() {
        let q = cityQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        isSearching = true
        syncFlyoutPanelLayout()
        Task {
            let res = await geoService.searchCities(query: q)
            await MainActor.run {
                self.candidates = res
                self.isSearching = false
                self.syncFlyoutPanelLayout()
            }
        }
    }

    func compactWeatherMetric(label: String, val: String) -> some View {
        VStack(spacing: 1.5) {
            Text(label).font(.system(size: 8)).foregroundColor(Theme.sub).lineLimit(1)
            Text(val).font(.system(size: 9.5, weight: .bold, design: .monospaced)).foregroundColor(Theme.text).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4.5)
        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.sep, lineWidth: 0.6))
    }

    func compactHourCol(time: String, icon: String, temp: String, barH: CGFloat, isNow: Bool = false) -> some View {
        VStack(spacing: 3) {
            Text(time)
                .font(.system(size: 8.5, weight: isNow ? .bold : .regular))
                .foregroundColor(isNow ? Theme.accent : Theme.sub)
            WeatherAdaptiveIconView(iconName: icon, fontSize: 11)
            ZStack(alignment: .bottom) {
                Capsule().fill(StatsTheme.trackBg).frame(width: 5, height: 26)
                Capsule()
                    .fill(LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .bottom, endPoint: .top))
                    .frame(width: 5, height: barH)
            }
            Text(temp).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(Theme.text)
        }
        .frame(minWidth: 34)
    }

    func compactForecastRow(day: String, icon: String, low: String, high: String, start: CGFloat, end: CGFloat, currentMarker: CGFloat? = nil) -> some View {
        HStack {
            Text(day).font(.system(size: 9.5, weight: currentMarker != nil ? .bold : .medium)).foregroundColor(currentMarker != nil ? Theme.accent : Theme.text).frame(width: 36, alignment: .leading)
            WeatherAdaptiveIconView(iconName: icon, fontSize: 10.5).frame(width: 20)
            Text(low).font(.system(size: 9, design: .monospaced)).foregroundColor(Theme.sub).frame(width: 26, alignment: .trailing)
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(StatsTheme.trackBg).frame(height: 4.5)
                    Capsule()
                        .fill(LinearGradient(colors: [Theme.accent, Theme.accent2], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, w * (end - start)), height: 4.5)
                        .offset(x: w * start)
                    if let marker = currentMarker {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6.5, height: 6.5)
                            .overlay(Circle().strokeBorder(Theme.accent, lineWidth: 1.4))
                            .offset(x: max(0, min(w - 6.5, w * marker - 3.25)))
                    }
                }
            }
            .frame(height: 6.5)
            Text(high).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundColor(Theme.text).frame(width: 26, alignment: .trailing)
        }
    }
}
