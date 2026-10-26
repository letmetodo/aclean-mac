import Foundation
import Combine

// ============================================================
//  IPGeoService —— 真实公网 IP 诊断与智能地理定位服务
//
//  职责：
//    1. 通过多源高可用 HTTPS 接口 (ipwho.is -> ipapi.co -> ipinfo.io) 获取真实公网 IP、
//       运营商 (ISP/ASN)、国家/省份/城市名称及真实经纬度坐标；
//    2. 支持 Open-Meteo Geocoding 全球城市搜索 API，允许用户手动搜索并锁定城市；
//    3. 100% 零假数据：未联网且无历史缓存时明确标记为 .locating / .offline，绝不硬编码假城市。
// ============================================================

struct GeoLocationInfo: Codable, Sendable, Equatable {
    var city: String
    var region: String
    var country: String
    var latitude: Double
    var longitude: Double
    var publicIP: String
    var isp: String
    var isManualCity: Bool
    var updatedAt: Date
}

struct CitySearchCandidate: Identifiable, Sendable {
    var id: String { "\(name)-\(latitude)-\(longitude)" }
    var name: String
    var admin1: String
    var country: String
    var latitude: Double
    var longitude: Double

    var displayTitle: String {
        let parts = [name, admin1, country].filter { !$0.isEmpty }
        return parts.joined(separator: " · ")
    }
}

@MainActor
final class IPGeoService: ObservableObject {

    nonisolated static let snapshot = LockedValue<GeoLocationInfo?>(nil)
    static let shared = IPGeoService()

    enum LocationState: Sendable {
        case locating
        case resolved(GeoLocationInfo)
        case failed(String)
    }

    @Published private(set) var state: LocationState = .locating
    @Published private(set) var latestInfo: GeoLocationInfo? {
        didSet { Self.snapshot.withValue { $0 = latestInfo } }
    }
    @Published private(set) var publicIP: String = L10n.localized(.statusDetecting)
    @Published private(set) var ispName: String = "—"

    private let session: URLSession
    private static var cacheKey: String { AppConfig.Telemetry.ipGeoCacheKey }
    private var cacheKey: String { Self.cacheKey }

    init(session suppliedSession: URLSession? = nil) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = AppConfig.Telemetry.ipGeoTimeoutSeconds
        config.timeoutIntervalForResource = AppConfig.Telemetry.ipGeoResourceTimeoutSeconds
        self.session = suppliedSession ?? URLSession(configuration: config)

        if let data = UserDefaults.standard.data(forKey: Self.cacheKey)
            ?? UserDefaults.standard.data(forKey: "cm.geo.lastResolvedLocation.v1"),
           let cached = try? JSONDecoder().decode(GeoLocationInfo.self, from: data) {
            self.latestInfo = cached
            Self.snapshot.withValue { $0 = cached }
            self.state = .resolved(cached)
            if !cached.publicIP.isEmpty {
                self.publicIP = cached.publicIP
            }
            if !cached.isp.isEmpty {
                self.ispName = cached.isp
            }
        }
    }

    private var requestGeneration = 0
    private var refreshing = false
    private var lastAttempt: Date = .distantPast

    func cancelNetworkRequests() {
        requestGeneration += 1
        session.getAllTasks { $0.forEach { $0.cancel() } }
    }

    /// 刷新公网 IP 与自动地理位置
    func refreshPublicIPAndLocation(forceAutoLocate: Bool = false, allowNetwork: Bool = false) async -> GeoLocationInfo? {
        guard AppConfig.Telemetry.networkFeaturesEnabled else { return latestInfo }
        if let manual = latestInfo, manual.isManualCity, !forceAutoLocate { return manual }
        guard !refreshing else { return latestInfo }
        if !forceAutoLocate, let cached = latestInfo,
           Date().timeIntervalSince(cached.updatedAt) < AppConfig.Telemetry.locationCacheTTL { return cached }
        guard Date().timeIntervalSince(lastAttempt) >= AppConfig.Telemetry.networkRetryInterval else { return latestInfo }
        let generation = requestGeneration
        refreshing = true
        lastAttempt = Date()
        defer { refreshing = false }

        if forceAutoLocate {
            if var current = latestInfo {
                current.isManualCity = false
                saveCache(current)
            }
        }

        // 总是探测一次真实公网 IP 与自动位置
        if let autoInfo = await fetchFromProviders(allowNetwork: AppConfig.Telemetry.networkFeaturesEnabled) {
            guard generation == requestGeneration, AppConfig.Telemetry.networkFeaturesEnabled, !Task.isCancelled else { return latestInfo }
            await MainActor.run {
                self.publicIP = autoInfo.publicIP
                self.ispName = autoInfo.isp
            }

            // 如果用户之前手动锁定了某个城市，则保留手动城市的经纬度，仅更新公网 IP 和 ISP
            if let existing = latestInfo, existing.isManualCity && !forceAutoLocate {
                var merged = existing
                merged.publicIP = autoInfo.publicIP
                merged.isp = autoInfo.isp
                merged.updatedAt = Date()
                let finalMerged = merged
                saveCache(finalMerged)
                await MainActor.run {
                    self.latestInfo = finalMerged
                    self.state = .resolved(finalMerged)
                }
                return finalMerged
            } else {
                saveCache(autoInfo)
                await MainActor.run {
                    self.latestInfo = autoInfo
                    self.state = .resolved(autoInfo)
                }
                return autoInfo
            }
        } else {
            await MainActor.run {
                if self.latestInfo == nil {
                    self.state = .failed(L10n.localized(.reviewNetworkUnavailable))
                    self.publicIP = ""
                }
            }
            return latestInfo
        }
    }

    static func sanitizePublicIP(_ candidate: String) -> String {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed != "—",
              trimmed != L10n.localized(.statusDetecting),
              trimmed != L10n.localized(.reviewNetworkUnavailable) else {
            return ""
        }
        // 仅接受合法 IPv4 或 IPv6 字符集，绝不将状态或错误文本持久化为 IP
        let allowed = CharacterSet(charactersIn: "0123456789abcdefABCDEF.:")
        guard trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }),
              (trimmed.contains(".") || trimmed.contains(":")) else {
            return ""
        }
        return trimmed
    }

    /// 用户手动选择城市
    func selectManualCity(_ candidate: CitySearchCandidate) {
        let info = GeoLocationInfo(
            city: candidate.name,
            region: candidate.admin1,
            country: candidate.country,
            latitude: candidate.latitude,
            longitude: candidate.longitude,
            publicIP: Self.sanitizePublicIP(self.publicIP),
            isp: self.ispName == "—" ? "" : self.ispName,
            isManualCity: true,
            updatedAt: Date()
        )
        saveCache(info)
        DispatchQueue.main.async {
            self.latestInfo = info
            self.state = .resolved(info)
            WeatherService.shared.refreshWeather()
        }
    }

    private static let majorChineseCityCoords: [String: (lat: Double, lon: Double)] = [
        "北京": (39.9042, 116.4074), "上海": (31.2304, 121.4737), "广州": (23.1291, 113.2644),
        "深圳": (22.5431, 114.0579), "杭州": (30.2741, 120.1551), "成都": (30.5728, 104.0668),
        "重庆": (29.5630, 106.5516), "武汉": (30.5928, 114.3055), "西安": (34.3416, 108.9398),
        "南京": (32.0603, 118.7969), "苏州": (31.2989, 120.5853), "天津": (39.3434, 117.3616),
        "长沙": (28.2282, 112.9388), "郑州": (34.7466, 113.6253), "东莞": (23.0207, 113.7518),
        "佛山": (23.0215, 113.1214), "青岛": (36.0671, 120.3826), "沈阳": (41.8057, 123.4315),
        "宁波": (29.8683, 121.5440), "昆明": (24.8801, 102.8329), "合肥": (31.8206, 117.2272),
        "福州": (26.0745, 119.2965), "厦门": (24.4798, 118.0894), "济南": (36.6512, 117.1201),
        "珠海": (22.2710, 113.5767), "中山": (22.5176, 113.3928), "惠州": (23.1115, 114.4162),
        "香港": (22.3193, 114.1694), "台北": (25.0330, 121.5654), "澳门": (22.1987, 113.5439),
        "广东": (23.1291, 113.2644), "浙江": (30.2741, 120.1551), "江苏": (32.0603, 118.7969),
        "山东": (36.6512, 117.1201), "河南": (34.7466, 113.6253), "河北": (38.0428, 114.5149),
        "石家庄": (38.0428, 114.5149), "湖南": (28.2282, 112.9388), "湖北": (30.5928, 114.3055),
        "四川": (30.5728, 104.0668), "福建": (26.0745, 119.2965), "安徽": (31.8206, 117.2272),
        "辽宁": (41.8057, 123.4315), "陕西": (34.3416, 108.9398), "江西": (28.6820, 115.8579),
        "南昌": (28.6820, 115.8579), "广西": (22.8170, 108.3665), "南宁": (22.8170, 108.3665),
        "云南": (24.8801, 102.8329), "贵州": (26.6470, 106.6302), "贵阳": (26.6470, 106.6302),
        "山西": (37.8706, 112.5489), "太原": (37.8706, 112.5489), "吉林": (43.8171, 125.3235),
        "长春": (43.8171, 125.3235), "黑龙江": (45.8038, 126.5349), "哈尔滨": (45.8038, 126.5349),
        "内蒙古": (40.8426, 111.7492), "新疆": (43.8256, 87.6168), "甘肃": (36.0611, 103.8343),
        "海南": (20.0440, 110.1999), "海口": (20.0440, 110.1999), "三亚": (18.2528, 109.5119),
        "宁夏": (38.4872, 106.2309), "青海": (36.6171, 101.7782), "西藏": (29.6525, 91.1721),
        "台湾": (25.0330, 121.5654)
    ]

    /// 搜索全球城市 (Open-Meteo Geocoding API)
    func searchCities(query: String, allowNetwork: Bool = false) async -> [CitySearchCandidate] {
        guard AppConfig.Telemetry.networkFeaturesEnabled else { return [] }
        let generation = requestGeneration
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              var components = URLComponents(string: AppConfig.Telemetry.citySearchURL) else { return [] }
        components.queryItems = [URLQueryItem(name: "name", value: trimmed), URLQueryItem(name: "count", value: "8"),
                                 URLQueryItem(name: "language", value: String(L10n.shared.effectiveLanguage.rawValue.prefix(2))),
                                 URLQueryItem(name: "format", value: "json")]
        guard let url = components.url else { return [] }

        do {
            let (data, response) = try await session.data(from: url)
            guard generation == requestGeneration, AppConfig.Telemetry.networkFeaturesEnabled, !Task.isCancelled,
                  (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let results = json["results"] as? [[String: Any]],
                  !results.isEmpty else {
                return Self.fallbackChineseCandidates(for: trimmed)
            }

            let mapped = results.compactMap { item -> CitySearchCandidate? in
                guard let name = item["name"] as? String,
                      let lat = item["latitude"] as? Double,
                      let lon = item["longitude"] as? Double else {
                    return nil
                }
                let admin1 = (item["admin1"] as? String) ?? ""
                let country = (item["country"] as? String) ?? ""
                return CitySearchCandidate(
                    name: name,
                    admin1: admin1,
                    country: country,
                    latitude: lat,
                    longitude: lon
                )
            }
            return mapped.isEmpty ? Self.fallbackChineseCandidates(for: trimmed) : mapped
        } catch {
            return Self.fallbackChineseCandidates(for: trimmed)
        }
    }

    private static func fallbackChineseCandidates(for query: String) -> [CitySearchCandidate] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return majorChineseCityCoords.keys
            .sorted()
            .filter { $0.contains(q) || q.contains($0) }
            .compactMap { key in
                guard let coord = majorChineseCityCoords[key] else { return nil }
                return CitySearchCandidate(
                    name: key,
                    admin1: "",
                    country: "China",
                    latitude: coord.lat,
                    longitude: coord.lon
                )
            }
    }

    private func resolveCityCoordinates(city: String, region: String = "", allowNetwork: Bool) async -> (lat: Double, lon: Double)? {
        if let preset = Self.majorChineseCityCoords[city] {
            return preset
        }
        for (k, v) in Self.majorChineseCityCoords.sorted(by: { $0.key.count > $1.key.count || ($0.key.count == $1.key.count && $0.key < $1.key) }) where city == k || city == k + "市" {
            return v
        }
        let candidates = await searchCities(query: city, allowNetwork: allowNetwork)
        if let matched = candidates.first(where: { $0.name.contains(city) || city.contains($0.name) }) ?? candidates.first {
            return (matched.latitude, matched.longitude)
        }
        if !region.isEmpty {
            if let regionPreset = Self.majorChineseCityCoords[region] {
                return regionPreset
            }
            for (k, v) in Self.majorChineseCityCoords.sorted(by: { $0.key < $1.key }) where region == k || region == k + "省" {
                return v
            }
        }
        return nil
    }

    // MARK: - 多源公网 IP 与地理定位链

    private func fetchFromProviders(allowNetwork: Bool = false) async -> GeoLocationInfo? {
        guard AppConfig.Telemetry.networkFeaturesEnabled else { return nil }
        // All requests use the system network configuration.
        if let info = await fetchFromIPWhoIs(allowNetwork: allowNetwork) {
            return info
        }
        if let info = await fetchFromIPInfo(allowNetwork: allowNetwork) {
            return info
        }
        if let info = await fetchFromIPApiCo(allowNetwork: allowNetwork) {
            return info
        }
        return nil
    }

    private func fetchFromIPWhoIs(allowNetwork: Bool = false) async -> GeoLocationInfo? {
        guard AppConfig.Telemetry.networkFeaturesEnabled, !Task.isCancelled, let url = URL(string: AppConfig.Telemetry.ipProviderURLs[0]) else { return nil }
        do {
            let (data, resp) = try await session.data(from: url)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            if let success = json["success"] as? Bool, !success {
                return nil
            }
            guard let ip = json["ip"] as? String,
                  let city = json["city"] as? String, !city.isEmpty,
                  let lat = json["latitude"] as? Double,
                  let lon = json["longitude"] as? Double else {
                return nil
            }
            let region = (json["region"] as? String) ?? ""
            let country = (json["country"] as? String) ?? ""
            var isp = ""
            if let conn = json["connection"] as? [String: Any] {
                isp = (conn["isp"] as? String) ?? (conn["org"] as? String) ?? ""
            }
            return GeoLocationInfo(
                city: city,
                region: region,
                country: country,
                latitude: lat,
                longitude: lon,
                publicIP: ip,
                isp: isp,
                isManualCity: false,
                updatedAt: Date()
            )
        } catch {
            return nil
        }
    }

    private func fetchFromIPInfo(allowNetwork: Bool = false) async -> GeoLocationInfo? {
        guard AppConfig.Telemetry.networkFeaturesEnabled, !Task.isCancelled, let url = URL(string: AppConfig.Telemetry.ipProviderURLs[1]) else { return nil }
        do {
            let (data, resp) = try await session.data(from: url)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ip = json["ip"] as? String,
                  let city = json["city"] as? String,
                  let loc = json["loc"] as? String else {
                return nil
            }
            let parts = loc.split(separator: ",")
            guard parts.count == 2,
                  let lat = Double(parts[0]),
                  let lon = Double(parts[1]) else {
                return nil
            }
            let region = (json["region"] as? String) ?? ""
            let country = (json["country"] as? String) ?? ""
            let org = (json["org"] as? String) ?? ""
            return GeoLocationInfo(
                city: city,
                region: region,
                country: country,
                latitude: lat,
                longitude: lon,
                publicIP: ip,
                isp: org,
                isManualCity: false,
                updatedAt: Date()
            )
        } catch {
            return nil
        }
    }

    private func fetchFromIPApiCo(allowNetwork: Bool = false) async -> GeoLocationInfo? {
        guard AppConfig.Telemetry.networkFeaturesEnabled, !Task.isCancelled, let url = URL(string: AppConfig.Telemetry.ipProviderURLs[2]) else { return nil }
        do {
            let (data, resp) = try await session.data(from: url)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ip = json["ip"] as? String,
                  let city = json["city"] as? String,
                  let lat = json["latitude"] as? Double,
                  let lon = json["longitude"] as? Double else {
                return nil
            }
            let region = (json["region"] as? String) ?? ""
            let country = (json["country_name"] as? String) ?? ""
            let org = (json["org"] as? String) ?? ""
            return GeoLocationInfo(
                city: city,
                region: region,
                country: country,
                latitude: lat,
                longitude: lon,
                publicIP: ip,
                isp: org,
                isManualCity: false,
                updatedAt: Date()
            )
        } catch {
            return nil
        }
    }

    private func saveCache(_ info: GeoLocationInfo) {
        if let data = try? JSONEncoder().encode(info) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}
