import Foundation
import SystemConfiguration
import Darwin

// ============================================================
//  NetworkInspector —— 原生网络拓扑、代理检测与真实延迟 (RTT) 诊断器
//
//  职责 ：
//    1. 原生读取本机活跃网卡 IPv4 地址 (getifaddrs AF_INET)；
//    2. 通过 SystemConfiguration (SCDynamicStoreCopyProxies) 与环境变量
//       零开销识别 HTTP / HTTPS / SOCKS / PAC 代理与 TUN 隧道；
//    3. 异步测量真实公网/DNS 节点 TCP 握手延迟 (RTT ms)；
//    4. 提供 NetworkDetailSnapshot 供主界面与顶部双栏弹窗的 NetworkDetailCard 展示。
// ============================================================

struct NetworkDetailSnapshot: Sendable {
    var interfaceName: String        // 如 "en0"
    var interfaceDisplayName: String // 如 "Wi-Fi" 或 "Ethernet" 或 "VPN (utun)"
    var localIPv4: String            // 如 "192.168.1.102"
    var localIPv6: String            // 如 "fe80::21:942c:cdcf:2550"
    var publicIP: String             // 来自 IPGeoService 的真实公网 IP
    var ispLocation: String          // 如 "中国 · 广州 · China Telecom"
    var countryFlag: String          // 如 "🇸🇬" 或 "🇨🇳"
    var proxyType: String            // "None" / "HTTP" / "HTTPS" / "SOCKS" / "PAC" / "TUN"
    var proxyHost: String            // 如 "127.0.0.1:7890" 或 "Direct"
    var latencyMs: Int?              // 真实 TCP RTT (ms)，nil = 测量中或离线
    var inactiveInterfaces: [String] // 如 ["Ethernet Adapter (en4)", "Thunderbolt Bridge", ...]
}

final class NetworkInspector: @unchecked Sendable {

    static let shared = NetworkInspector()

    private let lock = NSLock()
    private var cachedLatencyMs: Int?
    private var lastLatencyProbeAt: TimeInterval = 0
    private var probeInFlight: Bool = false

    private init() {
        triggerLatencyProbeIfNeeded()
    }

    static func flagEmoji(for countryCode: String) -> String {
        let base: UInt32 = 127397
        var s = ""
        for v in countryCode.uppercased().unicodeScalars {
            if v.value >= 65 && v.value <= 90 {
                if let scalar = UnicodeScalar(base + v.value) {
                    s.unicodeScalars.append(scalar)
                }
            }
        }
        return s.isEmpty ? "🌐" : s
    }

    func inspect(activeInterface: String) -> NetworkDetailSnapshot {
        triggerLatencyProbeIfNeeded()

        let (ipMap, ip6Map) = collectInterfaceIPs()
        let localIP = ipMap[activeInterface] ?? ipMap["en0"] ?? ipMap.values.first ?? "Unassigned"
        let localIPv6 = ip6Map[activeInterface] ?? ip6Map["en0"] ?? ip6Map.values.first ?? "—"

        let proxy = detectProxy(ipMap: ipMap)
        let geo = IPGeoService.snapshot.withValue { $0 }
        let pubIP = geo?.publicIP ?? L10n.localized(.statusDetecting)
        let ispLoc: String
        let flag: String
        if let g = geo {
            let parts = [g.country, g.city, g.isp].filter { !$0.isEmpty }
            ispLoc = parts.isEmpty ? "—" : parts.joined(separator: " · ")
            let cLower = g.country.lowercased()
            if cLower.contains("singapore") || cLower.contains("新加坡") || cLower == "sg" {
                flag = "🇸🇬"
            } else if cLower.contains("china") || cLower.contains("中国") || cLower == "cn" {
                flag = "🇨🇳"
            } else if cLower.contains("united states") || cLower.contains("usa") || cLower.contains("美国") || cLower == "us" {
                flag = "🇺🇸"
            } else if cLower.contains("japan") || cLower.contains("日本") || cLower == "jp" {
                flag = "🇯🇵"
            } else if cLower.contains("hong kong") || cLower.contains("香港") || cLower == "hk" {
                flag = "🇭🇰"
            } else {
                flag = "🌐"
            }
        } else {
            ispLoc = "Locating..."
            flag = "🌐"
        }

        let displayName: String
        if activeInterface.hasPrefix("utun") || activeInterface.hasPrefix("tun") || activeInterface.hasPrefix("ppp") {
            displayName = "VPN / Tunnel (\(activeInterface))"
        } else if activeInterface == "en0" {
            displayName = "Wi-Fi (\(activeInterface))"
        } else {
            displayName = "Ethernet (\(activeInterface))"
        }

        let inactive = collectInactiveHardwareInterfaces(connectedName: activeInterface)

        lock.lock()
        let rtt = cachedLatencyMs
        lock.unlock()

        return NetworkDetailSnapshot(
            interfaceName: activeInterface,
            interfaceDisplayName: displayName,
            localIPv4: localIP,
            localIPv6: localIPv6,
            publicIP: pubIP,
            ispLocation: ispLoc,
            countryFlag: flag,
            proxyType: proxy.type,
            proxyHost: proxy.host,
            latencyMs: rtt,
            inactiveInterfaces: inactive
        )
    }

    // MARK: - 1. 本机各网卡 IPv4 与 IPv6 读取 (getifaddrs)

    func collectInterfaceIPv4() -> [String: String] {
        return collectInterfaceIPs().v4
    }

    func collectInterfaceIPs() -> (v4: [String: String], v6: [String: String]) {
        var v4: [String: String] = [:]
        var v6: [String: String] = [:]
        var ifaddrList: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrList) == 0, let first = ifaddrList else {
            return (v4, v6)
        }
        defer { freeifaddrs(ifaddrList) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let ptr = cursor {
            let ifa = ptr.pointee
            let name = String(cString: ifa.ifa_name)
            if let addr = ifa.ifa_addr {
                let family = addr.pointee.sa_family
                if family == UInt8(AF_INET) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        let ip = String(decoding: hostname.prefix(while: { $0 != 0 }).map(UInt8.init(bitPattern:)), as: UTF8.self)
                        if !ip.hasPrefix("127.") && !ip.hasPrefix("169.254.") {
                            v4[name] = ip
                        }
                    }
                } else if family == UInt8(AF_INET6) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        let ip = String(decoding: hostname.prefix(while: { $0 != 0 }).map(UInt8.init(bitPattern:)), as: UTF8.self)
                        if !ip.hasPrefix("::1") && !ip.hasPrefix("fe80::1%") {
                            // 优先保留非 fe80，或者记录链路本地
                            if v6[name] == nil || !ip.hasPrefix("fe80:") {
                                v6[name] = ip
                            }
                        }
                    }
                }
            }
            cursor = ifa.ifa_next
        }
        return (v4, v6)
    }

    /// Collect physical network interfaces that are currently disconnected.
    func collectInactiveHardwareInterfaces(connectedName: String) -> [String] {
        var list: [String] = []
        if let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] {
            for iface in interfaces {
                let bsd = SCNetworkInterfaceGetBSDName(iface) as String? ?? ""
                let disp = SCNetworkInterfaceGetLocalizedDisplayName(iface) as String? ?? bsd
                if bsd != connectedName && !disp.isEmpty {
                    list.append("\(disp) (\(bsd))")
                }
            }
        }
        return list.sorted()
    }

    // MARK: - 2. 系统代理与 TUN 隧道原生识别 (SCDynamicStoreCopyProxies)

    private func detectProxy(ipMap: [String: String]) -> (type: String, host: String) {
        // 1) 环境变量优先
        let env = ProcessInfo.processInfo.environment
        for key in ["https_proxy", "HTTPS_PROXY", "http_proxy", "HTTP_PROXY", "all_proxy", "ALL_PROXY"] {
            if let val = env[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !val.isEmpty {
                let isSocks = val.lowercased().hasPrefix("socks")
                return (isSocks ? "SOCKS" : "HTTP", val)
            }
        }

        // 2) SystemConfiguration 原生代理表
        if let proxiesCF = SCDynamicStoreCopyProxies(nil),
           let dict = proxiesCF as? [String: Any] {
            if let socksEn = dict[kCFNetworkProxiesSOCKSEnable as String] as? Int, socksEn == 1 {
                let h = (dict[kCFNetworkProxiesSOCKSProxy as String] as? String) ?? "127.0.0.1"
                let p = (dict[kCFNetworkProxiesSOCKSPort as String] as? Int) ?? 0
                return ("SOCKS", p > 0 ? "\(h):\(p)" : h)
            }
            if let httpsEn = dict[kCFNetworkProxiesHTTPSEnable as String] as? Int, httpsEn == 1 {
                let h = (dict[kCFNetworkProxiesHTTPSProxy as String] as? String) ?? "127.0.0.1"
                let p = (dict[kCFNetworkProxiesHTTPSPort as String] as? Int) ?? 0
                return ("HTTPS", p > 0 ? "\(h):\(p)" : h)
            }
            if let httpEn = dict[kCFNetworkProxiesHTTPEnable as String] as? Int, httpEn == 1 {
                let h = (dict[kCFNetworkProxiesHTTPProxy as String] as? String) ?? "127.0.0.1"
                let p = (dict[kCFNetworkProxiesHTTPPort as String] as? Int) ?? 0
                return ("HTTP", p > 0 ? "\(h):\(p)" : h)
            }
            if let pacEn = dict[kCFNetworkProxiesProxyAutoConfigEnable as String] as? Int, pacEn == 1 {
                let url = (dict[kCFNetworkProxiesProxyAutoConfigURLString as String] as? String) ?? "PAC"
                return ("PAC", url)
            }
        }

        // 3) 活跃 utun 隧道检测
        let activeTuns = ipMap.keys.filter { $0.hasPrefix("utun") || $0.hasPrefix("tun") }.sorted()
        if let firstTun = activeTuns.first {
            return ("TUN", activeTuns.count > 1 ? "\(firstTun)+" : firstTun)
        }

        return ("Direct", "No Proxy")
    }

    // MARK: - 3. 真实网络延迟 (TCP Handshake RTT) 探测

    private func triggerLatencyProbeIfNeeded() {
        guard AppConfig.Telemetry.networkFeaturesEnabled else { return }
        let now = Date().timeIntervalSince1970
        lock.lock()
        if probeInFlight || (now - lastLatencyProbeAt < 10.0) {
            lock.unlock()
            return
        }
        probeInFlight = true
        lastLatencyProbeAt = now
        lock.unlock()

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let rtt = Self.measureTCPLatency(host: "223.5.5.5", port: 53)
                ?? Self.measureTCPLatency(host: "1.1.1.1", port: 53)
            guard let self else { return }
            self.lock.lock()
            self.cachedLatencyMs = rtt
            self.probeInFlight = false
            self.lock.unlock()
        }
    }

    private static func measureTCPLatency(host: String, port: UInt16) -> Int? {
        guard AppConfig.Telemetry.networkFeaturesEnabled else { return nil }
        let sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
        guard sock >= 0 else { return nil }
        defer { close(sock) }

        // 非阻塞连接 + poll 计时 (超时 1.2s)
        let flags = fcntl(sock, F_GETFL, 0)
        _ = fcntl(sock, F_SETFL, flags | O_NONBLOCK)

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        inet_pton(AF_INET, host, &addr.sin_addr)

        let start = DispatchTime.now().uptimeNanoseconds
        let connectRes = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        if connectRes == 0 {
            let elapsedMs = Int((DispatchTime.now().uptimeNanoseconds - start) / 1_000_000)
            return max(1, elapsedMs)
        }

        guard errno == EINPROGRESS else { return nil }

        var pfd = pollfd(fd: sock, events: Int16(POLLOUT), revents: 0)
        let pollRes = poll(&pfd, 1, 1200)
        guard pollRes > 0, (pfd.revents & Int16(POLLOUT)) != 0 else { return nil }

        var soError: Int32 = 0
        var len = socklen_t(MemoryLayout<Int32>.size)
        guard getsockopt(sock, SOL_SOCKET, SO_ERROR, &soError, &len) == 0, soError == 0 else {
            return nil
        }

        let elapsedMs = Int((DispatchTime.now().uptimeNanoseconds - start) / 1_000_000)
        return max(1, elapsedMs)
    }
}
