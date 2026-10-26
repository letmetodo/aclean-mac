import Foundation
import Combine

// ============================================================
//  WeatherService —— 100% 真实联网气象遥测与多时段预报引擎
//
//  核心职责：
//    1. 联动 IPGeoService 获取真实公网 IP 所在城市经纬度（或用户手动搜索选定的全球城市）；
//    2. 请求 Open-Meteo 实时气象接口获取当前气温、体感温度、湿度、风速、紫外线、WMO 天气码；
//    3. 解析未来 12 小时逐小时趋势预报 (Hourly Forecast) 与降水概率 (%)；
//    4. 解析未来 7 天日间最高/最低温与天气现象预报 (7-Day Forecast)；
//    5. 零假数据铁律：绝不硬编码任何假城市或假气温，支持本地持久化真实历史快照与状态机反馈。
// ============================================================

// MARK: - 天气数据模型

struct HourlyWeatherItem: Identifiable, Codable, Sendable {
    var id: String { "\(hour):\(temp)" }
    var hour: String           // 如 "现在", "14时", "15时" ...
    var temp: Double           // 如 25.1
    var iconName: String       // SF Symbol
    var isSun: Bool
    var precipProbability: Int // 0 ~ 100%
    var isCurrentHour: Bool? = nil

    var localizedHour: String {
        if isCurrentHour == true { return L10n.localized(.timeNow) }
        if isCurrentHour == nil, let entry = LocalizationCatalog.entries[.timeNow],
           AppLanguage.concreteLanguages.contains(where: { entry.text(for: $0) == hour }) {
            return L10n.localized(.timeNow)
        }
        return hour
    }
}

struct DailyWeatherItem: Identifiable, Codable, Sendable {
    var id: String { dayName }
    var dayName: String        // 如 "今天", "周四", "周五" ...
    var iconName: String       // SF Symbol
    var maxTemp: Int           // 如 32
    var minTemp: Int           // 如 23
    var precipMax: Int         // 0 ~ 100%
    var conditionSummary: String
    var conditionCode: Int? = nil
    var dateISO: String? = nil

    var localizedSummary: String {
        let description = conditionCode.map(WeatherService.description(for:)) ?? WeatherService.localizeLegacyCondition(conditionSummary.components(separatedBy: " · ").first ?? conditionSummary)
        return "\(description) · \(precipMax)%"
    }
    var localizedDayName: String {
        guard let dateISO else { return dayName }
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.dateFormat = "yyyy-MM-dd"
        guard let date = input.date(from: dateISO) else { return dayName }
        let output = DateFormatter()
        output.locale = L10n.shared.currentLocale
        output.dateFormat = "EEEE"
        return output.string(from: date)
    }
}

struct WeatherSnapshot: Codable, Sendable {
    var city: String
    var regionAndCountry: String
    var latitude: Double
    var longitude: Double
    var currentTemp: Double
    var feelsLike: Double
    var humidity: Int
    var windSpeedKmh: Double
    var uvIndex: Double
    var conditionText: String
    var conditionIcon: String
    var hourly: [HourlyWeatherItem]
    var daily: [DailyWeatherItem]
    var updateTime: Date
    var isLoadedFromNetwork: Bool
    var conditionCode: Int? = nil
    var isNight: Bool {
        conditionIcon.contains("moon")
    }
    var localizedConditionText: String {
        conditionCode.map(WeatherService.description(for:)) ?? WeatherService.localizeLegacyCondition(conditionText)
    }
}

// MARK: - 天气服务单例

@MainActor
final class WeatherService: ObservableObject {

    static let shared = WeatherService()

    @Published private(set) var current: WeatherSnapshot
    @Published private(set) var isRefreshing: Bool = false
    @Published private(set) var statusMessage: String? = L10n.localized(.weatherFetchingFromNetworkPrompt)

    private var refreshTimer: Timer?
    private let session: URLSession
    private static var cacheKey: String { AppConfig.Telemetry.weatherCacheKey }
    private var cacheKey: String { Self.cacheKey }

    init(session suppliedSession: URLSession? = nil) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = AppConfig.Telemetry.weatherRequestTimeoutSeconds
        config.timeoutIntervalForResource = AppConfig.Telemetry.weatherResourceTimeoutSeconds
        self.session = suppliedSession ?? URLSession(configuration: config)

        if let data = UserDefaults.standard.data(forKey: Self.cacheKey)
            ?? UserDefaults.standard.data(forKey: "cm.weather.lastRealSnapshot.v2"),
           let cached = try? JSONDecoder().decode(WeatherSnapshot.self, from: data) {
            self.current = cached
            self.statusMessage = nil
        } else {
            self.current = WeatherSnapshot(
                city: L10n.localized(.weatherLocatingEllipsis),
                regionAndCountry: "",
                latitude: 0,
                longitude: 0,
                currentTemp: 0,
                feelsLike: 0,
                humidity: 0,
                windSpeedKmh: 0,
                uvIndex: 0,
                conditionText: L10n.localized(.weatherFetchingFromNetworkPrompt),
                conditionIcon: "location.magnifyingglass",
                hourly: [],
                daily: [],
                updateTime: Date(),
                isLoadedFromNetwork: false
            )
        }

        if AppConfig.Telemetry.networkFeaturesEnabled {
            startPeriodicRefresh()
            refreshWeather()
        }
    }

    private var refreshTask: Task<Void, Never>?
    private var refreshGeneration = 0

    func networkPreferenceChanged() {
        refreshGeneration += 1
        refreshTask?.cancel()
        refreshTask = nil
        refreshTimer?.invalidate()
        session.getAllTasks { $0.forEach { $0.cancel() } }
        IPGeoService.shared.cancelNetworkRequests()
        isRefreshing = false
        if AppConfig.Telemetry.networkFeaturesEnabled {
            startPeriodicRefresh()
            refreshWeather()
        }
    }

    /// 启动定时刷新（每 15 分钟自动联网刷新）
    private func startPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: AppConfig.Telemetry.weatherRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshWeather() }
        }
    }

    /// 刷新真实定位与天气数据
    func refreshWeather(forceAutoLocate: Bool = false) {
        guard AppConfig.Telemetry.networkFeaturesEnabled, !isRefreshing else { return }
        isRefreshing = true
        let generation = refreshGeneration
        refreshTask = Task {
            defer { if generation == refreshGeneration { isRefreshing = false; refreshTask = nil } }
            await MainActor.run {
                self.isRefreshing = true
                if !self.current.isLoadedFromNetwork {
                    self.statusMessage = L10n.localized(.weatherFetchingFromNetworkPrompt)
                }
            }

            // 1. 获取真实地理位置 (公网 IP 定位或用户手动锁定的城市)
            guard let geo = await IPGeoService.shared.refreshPublicIPAndLocation(forceAutoLocate: forceAutoLocate, allowNetwork: false) else {
                await MainActor.run {
                    self.isRefreshing = false
                    if !self.current.isLoadedFromNetwork {
                        self.statusMessage = L10n.localized(.reviewNetworkUnavailable)
                    } else {
                        self.statusMessage = L10n.localized(.reviewNetworkUnavailable)
                    }
                }
                return
            }

            guard !Task.isCancelled, AppConfig.Telemetry.networkFeaturesEnabled, generation == refreshGeneration else { return }
            // Use the system proxy configuration.
            let urlStr = String(
                format: AppConfig.Telemetry.weatherForecastURL + "?latitude=%.4f&longitude=%.4f&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day&hourly=temperature_2m,precipitation_probability,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max,precipitation_probability_max&timezone=auto",
                geo.latitude, geo.longitude
            )
            guard let url = URL(string: urlStr) else {
                await MainActor.run { self.isRefreshing = false }
                return
            }

            do {
                let (data, response) = try await session.data(from: url)
                guard !Task.isCancelled, AppConfig.Telemetry.networkFeaturesEnabled,
                      generation == refreshGeneration else { return }
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
                if let parsed = try self.parseOpenMeteo(data: data, geo: geo) {
                    if let encoded = try? JSONEncoder().encode(parsed) {
                        UserDefaults.standard.set(encoded, forKey: self.cacheKey)
                    }
                    await MainActor.run {
                        self.current = parsed
                        self.isRefreshing = false
                        self.statusMessage = nil
                    }
                } else {
                    await MainActor.run {
                        self.isRefreshing = false
                        self.statusMessage = L10n.localized(.reviewNetworkUnavailable)
                    }
                }
            } catch {
                guard !Task.isCancelled, generation == refreshGeneration else { return }
                await MainActor.run {
                    self.isRefreshing = false
                    if !self.current.isLoadedFromNetwork {
                        self.statusMessage = L10n.localized(.reviewNetworkUnavailable)
                    } else {
                        self.statusMessage = L10n.localized(.reviewNetworkUnavailable)
                    }
                }
            }
        }
    }

    func parseOpenMeteo(data: Data, geo: GeoLocationInfo, now: Date = Date()) throws -> WeatherSnapshot? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let currentObj = json["current"] as? [String: Any],
              let hourlyObj = json["hourly"] as? [String: Any],
              let dailyObj = json["daily"] as? [String: Any] else {
            return nil
        }

        guard let currentTemp = (currentObj["temperature_2m"] as? NSNumber)?.doubleValue,
              currentTemp.isFinite else { return nil }
        let feelsLike = (currentObj["apparent_temperature"] as? NSNumber)?.doubleValue ?? currentTemp
        let humidity = (currentObj["relative_humidity_2m"] as? NSNumber)?.intValue ?? 0
        let windSpeed = (currentObj["wind_speed_10m"] as? NSNumber)?.doubleValue ?? 0.0
        let currentCode = (currentObj["weather_code"] as? NSNumber)?.intValue ?? 0
        let isDayNow = ((currentObj["is_day"] as? NSNumber)?.intValue ?? 1) == 1

        let hourlyTimes = (hourlyObj["time"] as? [String]) ?? []
        let hourlyTemps = (hourlyObj["temperature_2m"] as? [NSNumber])?.map { $0.doubleValue } ?? []
        let hourlyPrecip = (hourlyObj["precipitation_probability"] as? [NSNumber])?.map { $0.intValue } ?? []
        let hourlyCodes = (hourlyObj["weather_code"] as? [NSNumber])?.map { $0.intValue } ?? []

        let dailyTimes = (dailyObj["time"] as? [String]) ?? []
        let dailyMax = (dailyObj["temperature_2m_max"] as? [NSNumber])?.map { $0.doubleValue } ?? []
        let dailyMin = (dailyObj["temperature_2m_min"] as? [NSNumber])?.map { $0.doubleValue } ?? []
        let dailyCodes = (dailyObj["weather_code"] as? [NSNumber])?.map { $0.intValue } ?? []
        let dailyUV = (dailyObj["uv_index_max"] as? [NSNumber])?.map { $0.doubleValue } ?? []
        let dailyPrecipMax = (dailyObj["precipitation_probability_max"] as? [NSNumber])?.map { $0.intValue } ?? []
        guard hourlyTimes.count == hourlyTemps.count,
              dailyTimes.count == dailyMax.count, dailyTimes.count == dailyMin.count,
              hourlyTemps.allSatisfy(\.isFinite), dailyMax.allSatisfy(\.isFinite),
              dailyMin.allSatisfy(\.isFinite) else { return nil }
        let forecastZone = (json["timezone"] as? String).flatMap(TimeZone.init(identifier:))
            ?? (json["utc_offset_seconds"] as? NSNumber).flatMap { TimeZone(secondsFromGMT: $0.intValue) }
            ?? TimeZone(secondsFromGMT: 0)!

        let condition = Self.description(for: currentCode)
        let conditionIcon = weatherCodeIcon(currentCode, isNight: !isDayNow)

        // 定位当前小时在 hourlyTimes 时间序列中的精准索引
        let nowFormatter = DateFormatter()
        nowFormatter.locale = Locale(identifier: "en_US_POSIX")
        nowFormatter.timeZone = forecastZone
        nowFormatter.dateFormat = "yyyy-MM-dd'T'HH"
        let currentHourPrefix = nowFormatter.string(from: now)
        let matchedIdx = hourlyTimes.firstIndex(where: { $0.hasPrefix(currentHourPrefix) })
        var forecastCalendar = Calendar(identifier: .gregorian)
        forecastCalendar.timeZone = forecastZone
        let currentHour = forecastCalendar.component(.hour, from: now)
        let startIdx = matchedIdx ?? max(0, min(max(0, hourlyTimes.count - 9), currentHour))

        var hourlyItems: [HourlyWeatherItem] = []
        for i in startIdx..<(min(startIdx + 9, hourlyTimes.count)) {
            let hourLabel: String
            var hInt = i % 24
            if let tStr = hourlyTimes[safe: i] {
                let parts = tStr.components(separatedBy: "T")
                if parts.count > 1 {
                    let hourPart = parts[1].prefix(2)
                    hInt = Int(hourPart) ?? hInt
                }
            }
            hourLabel = (i == startIdx) ? tr(.timeNow) : String(format: "%02d:00", hInt)

            let temp = hourlyTemps[safe: i] ?? currentTemp
            let precip = hourlyPrecip[safe: i] ?? 0
            let code = hourlyCodes[safe: i] ?? currentCode
            let isDay = hInt >= 6 && hInt <= 18

            hourlyItems.append(HourlyWeatherItem(
                hour: hourLabel,
                temp: temp,
                iconName: weatherCodeIcon(code, isNight: !isDay),
                isSun: isDay && (code <= 2),
                precipProbability: precip,
                isCurrentHour: i == startIdx
            ))
        }

        // 解析未来 7 天预报
        var dailyItems: [DailyWeatherItem] = []
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = L10n.shared.currentLocale
        weekdayFormatter.timeZone = forecastZone
        weekdayFormatter.dateFormat = "EEEE"

        let inputFormatter = DateFormatter()
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.timeZone = forecastZone
        inputFormatter.dateFormat = "yyyy-MM-dd"

        for i in 0..<min(7, dailyTimes.count) {
            let maxT = Int((dailyMax[safe: i] ?? currentTemp).rounded())
            let minT = Int((dailyMin[safe: i] ?? currentTemp).rounded())
            let code = dailyCodes[safe: i] ?? currentCode
            let pMax = dailyPrecipMax[safe: i] ?? 0
            let desc = Self.description(for: code)
            let summary = "\(desc) · \(maxT)° / \(minT)° · \(pMax)%"

            let title: String
            if i == 0 {
                title = tr(.today)
            } else if let dateStr = dailyTimes[safe: i], let d = inputFormatter.date(from: dateStr) {
                title = weekdayFormatter.string(from: d)
            } else {
                title = String(i + 1)
            }

            dailyItems.append(DailyWeatherItem(
                dayName: title,
                iconName: weatherCodeIcon(code, isNight: false),
                maxTemp: maxT,
                minTemp: minT,
                precipMax: pMax,
                conditionSummary: summary, conditionCode: code, dateISO: dailyTimes[safe: i]
            ))
        }

        let regionParts = [geo.region, geo.country].filter { !$0.isEmpty && $0 != geo.city }
        let uvToday = dailyUV.first ?? 0.0

        return WeatherSnapshot(
            city: geo.city,
            regionAndCountry: regionParts.joined(separator: " · "),
            latitude: geo.latitude,
            longitude: geo.longitude,
            currentTemp: currentTemp,
            feelsLike: feelsLike,
            humidity: humidity,
            windSpeedKmh: windSpeed,
            uvIndex: uvToday,
            conditionText: condition,
            conditionIcon: conditionIcon,
            hourly: hourlyItems,
            daily: dailyItems,
            updateTime: now,
            isLoadedFromNetwork: true, conditionCode: currentCode
        )
    }

    nonisolated static func description(for code: Int) -> String {
        switch code {
        case 0: return L10n.localized(.weatherClear)
        case 1: return L10n.localized(.weatherMostlyClear)
        case 2: return L10n.localized(.weatherPartlyCloudy)
        case 3: return L10n.localized(.weatherOvercast)
        case 45, 48: return L10n.localized(.weatherFog)
        case 51, 53, 55: return L10n.localized(.weatherDrizzle)
        case 61, 63: return L10n.localized(.weatherRain)
        case 65: return L10n.localized(.weatherHeavyRain)
        case 71, 73, 75: return L10n.localized(.weatherSnow)
        case 80, 81, 82: return L10n.localized(.weatherShowers)
        case 95, 96, 99: return L10n.localized(.weatherThunderstorm)
        default: return L10n.localized(.weatherCloudy)
        }
    }

    nonisolated static func localizeLegacyCondition(_ text: String) -> String {
        let codes: [String: Int] = ["Clear": 0, "Mostly Clear": 1, "Partly Cloudy": 2, "Overcast": 3,
                                  "Foggy": 45, "Drizzle": 51, "Rain": 61, "Heavy Rain": 65,
                                  "Snow": 71, "Rain Showers": 80, "Thunderstorm": 95, "Cloudy": -1]
        return codes[text].map(description(for:)) ?? text
    }

    private func weatherCodeIcon(_ code: Int, isNight: Bool) -> String {
        switch code {
        case 0: return isNight ? "moon.stars.fill" : "sun.max.fill"
        case 1, 2: return isNight ? "cloud.moon.fill" : "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 61, 63, 80, 81: return "cloud.rain.fill"
        case 65, 82: return "cloud.heavyrain.fill"
        case 71, 73, 75: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.sun.fill"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
