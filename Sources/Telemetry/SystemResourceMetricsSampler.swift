import Foundation
import AppKit
import Darwin
import IOKit
import IOKit.ps

extension SystemTelemetryEngine {
    // MARK: - 6. 内存与真实 Swap 采样 (绝不伪造交换空间)

    func sampleMemory() -> MemorySnapshot {
        var vmStats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)

        let kerr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        let totalPhys = Int64(ProcessInfo.processInfo.physicalMemory)
        guard kerr == KERN_SUCCESS else {
            return MemorySnapshot(
                totalBytes: totalPhys,
                usedBytes: 0, appBytes: 0, wiredBytes: 0, compressedBytes: 0, freeBytes: totalPhys,
                pressureLevel: .normal,
                swapUsedBytes: 0,
                swapTotalBytes: 0,
                isSampleValid: false
            )
        }

        let pageSize = Int64(getpagesize())
        let internalPages = Int64(vmStats.internal_page_count) * pageSize
        let purgeable = Int64(vmStats.purgeable_count) * pageSize
        let wired = Int64(vmStats.wire_count) * pageSize
        let compressed = Int64(vmStats.compressor_page_count) * pageSize

        let app = max(0, internalPages - purgeable)
        let used = min(totalPhys, app + wired + compressed)

        var pressureVal: Int32 = 0
        var size = MemoryLayout<Int32>.size
        let pErr = sysctlbyname("kern.memorystatus_vm_pressure_level", &pressureVal, &size, nil, 0)
        let pressure: MemoryPressureLevel
        if pErr == 0 {
            switch pressureVal {
            case 2: pressure = .warning
            case 4: pressure = .critical
            default: pressure = .normal
            }
        } else {
            let ratio = Double(used) / Double(totalPhys)
            pressure = ratio > 0.88 ? .critical : (ratio > 0.75 ? .warning : .normal)
        }

        // 真实读取 vm.swapusage，为 0 时保持 0 B
        var swap = xsw_usage()
        var sSize = MemoryLayout<xsw_usage>.stride
        var sMib = [CTL_VM, VM_SWAPUSAGE]
        var swapUsed: Int64 = 0
        var swapTotal: Int64 = 0
        if sysctl(&sMib, 2, &swap, &sSize, nil, 0) == 0 {
            swapUsed = Int64(swap.xsu_used)
            swapTotal = Int64(swap.xsu_total)
        }

        let active = Int64(vmStats.active_count) * pageSize
        let inactive = Int64(vmStats.inactive_count) * pageSize
        let cache = inactive + purgeable
        let pressurePct = Int(min(100, max(0, (Double(used) / Double(totalPhys) * 100).rounded())))

        var pageInsPerSec: Double = 0
        var pageOutsPerSec: Double = 0
        let nowUptime = ProcessInfo.processInfo.systemUptime
        if prevPageTime > 0 {
            let dt = max(0.1, nowUptime - prevPageTime)
            let curIns = UInt64(vmStats.pageins)
            let curOuts = UInt64(vmStats.pageouts)
            if curIns >= prevPageIns {
                pageInsPerSec = Double(curIns - prevPageIns) * Double(pageSize) / 1024.0 / dt
            }
            if curOuts >= prevPageOuts {
                pageOutsPerSec = Double(curOuts - prevPageOuts) * Double(pageSize) / 1024.0 / dt
            }
            prevPageIns = curIns
            prevPageOuts = curOuts
        } else {
            prevPageIns = UInt64(vmStats.pageins)
            prevPageOuts = UInt64(vmStats.pageouts)
        }
        prevPageTime = nowUptime

        return MemorySnapshot(
            totalBytes: totalPhys,
            usedBytes: used,
            appBytes: app,
            wiredBytes: wired,
            compressedBytes: compressed,
            freeBytes: max(0, totalPhys - used),
            activeBytes: active,
            inactiveBytes: inactive,
            cacheBytes: cache,
            pressurePercent: pressurePct,
            pageInsKBPerSec: (pageInsPerSec * 10).rounded() / 10,
            pageOutsKBPerSec: (pageOutsPerSec * 10).rounded() / 10,
            pressureLevel: pressure,
            swapUsedBytes: swapUsed,
            swapTotalBytes: swapTotal
        )
    }

    // MARK: - 7. 磁盘空间、外置卷与磁盘 I/O

    func pressureLevel(_ usedRatio: Double) -> DiskPressureLevel {
        if usedRatio >= 0.92 { return .critical }
        if usedRatio >= 0.82 { return .warning }
        return .normal
    }

    func sampleStorage() -> StorageSnapshot? {
        let url = URL(fileURLWithPath: "/")
        guard let v = try? url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ]) else { return nil }
        let total = Int64(v.volumeTotalCapacity ?? 0)
        guard total > 0 else { return nil }
        let imp = Int64(v.volumeAvailableCapacityForImportantUsage ?? 0)
        let raw = Int64(v.volumeAvailableCapacity ?? 0)
        let free = imp > 0 ? imp : raw
        let purgeable = max(0, imp - raw)
        let ratio = Double(max(0, total - free)) / Double(total)
        return StorageSnapshot(total: total, free: free, purgeable: purgeable, pressure: pressureLevel(ratio))
    }

    func sampleExternalDrives() -> [VolumeItem] {
        let keys: [URLResourceKey] = [
            .volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey,
            .volumeIsInternalKey, .volumeIsRemovableKey, .volumeIsEjectableKey,
            .volumeIsBrowsableKey, .volumeIsRootFileSystemKey
        ]
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        var out: [VolumeItem] = []
        for u in urls {
            guard let v = try? u.resourceValues(forKeys: Set(keys)) else { continue }
            if v.volumeIsBrowsable == false { continue }
            if v.volumeIsRootFileSystem == true { continue }
            if u.path.hasPrefix("/System/Volumes/") { continue }
            let name = v.volumeName ?? u.lastPathComponent
            out.append(VolumeItem(
                name: name,
                path: u.path,
                total: Int64(v.volumeTotalCapacity ?? 0),
                free: Int64(v.volumeAvailableCapacity ?? 0),
                isInternal: v.volumeIsInternal ?? false,
                isRemovable: v.volumeIsRemovable ?? false,
                isEjectable: v.volumeIsEjectable ?? false
            ))
        }
        return out.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func sampleConnectedDevices() -> [ConnectedDeviceItem] {
        var out: [ConnectedDeviceItem] = []
        var seen = Set<String>()
        for cls in ["IOUSBHostDevice", "IOUSBDevice"] {
            guard let match = IOServiceMatching(cls) else { continue }
            var iter: io_iterator_t = 0
            guard IOServiceGetMatchingServices(kIOMainPortDefault, match, &iter) == KERN_SUCCESS else { continue }
            var service = IOIteratorNext(iter)
            while service != 0 {
                var props: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                   let d = props?.takeRetainedValue() as? [String: Any] {
                    let name = (d["USB Product Name"] as? String) ?? (d["USB Vendor Name"] as? String) ?? "USB Device"
                    let serial = (d["USB Serial Number"] as? String) ?? ""
                    let key = "\(name)|\(serial)"
                    if !seen.contains(key) {
                        seen.insert(key)
                        out.append(ConnectedDeviceItem(id: key, name: name, kind: "USB", detail: serial))
                    }
                }
                IOObjectRelease(service)
                service = IOIteratorNext(iter)
            }
            IOObjectRelease(iter)
        }
        return out.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func sampleDiskIO() -> DiskIOSnapshot {
        let now = ProcessInfo.processInfo.systemUptime
        if prevDiskTime > 0, (now - prevDiskTime) < 0.04, let cached = cachedDiskIO {
            return cached
        }

        var totalBytesRead: Int64 = 0
        var totalBytesWritten: Int64 = 0

        guard let dict = IOServiceMatching("IOBlockStorageDriver") else {
            return DiskIOSnapshot(readBytesPerSec: 0, writeBytesPerSec: 0)
        }

        var iterator: io_iterator_t = 0
        if IOServiceGetMatchingServices(kIOMainPortDefault, dict, &iterator) == kIOReturnSuccess {
            var service: io_object_t = IOIteratorNext(iterator)
            while service != 0 {
                var props: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                   let propsDict = props?.takeRetainedValue() as? [String: Any],
                   let statistics = propsDict["Statistics"] as? [String: Any] {
                    if let r = statistics["Bytes (Read)"] as? NSNumber {
                        totalBytesRead += r.int64Value
                    }
                    if let w = statistics["Bytes (Write)"] as? NSNumber {
                        totalBytesWritten += w.int64Value
                    }
                }
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            IOObjectRelease(iterator)
        }

        var readRate: Double = 0
        var writeRate: Double = 0

        if prevDiskTime > 0 {
            let dt = max(0.04, now - prevDiskTime)
            if totalBytesRead >= prevDiskBytesRead {
                readRate = Double(totalBytesRead - prevDiskBytesRead) / dt
            }
            if totalBytesWritten >= prevDiskBytesWritten {
                writeRate = Double(totalBytesWritten - prevDiskBytesWritten) / dt
            }
        }

        prevDiskBytesRead = totalBytesRead
        prevDiskBytesWritten = totalBytesWritten
        prevDiskTime = now

        let snap = DiskIOSnapshot(readBytesPerSec: readRate, writeBytesPerSec: writeRate)
        cachedDiskIO = snap
        return snap
    }

    // MARK: - 8. 网络流量与详情采样 (sysctl NET_RT_IFLIST2 64-bit + NetworkInspector)

    /// 通过 Darwin 内核路由套接字 (NET_RT_IFLIST2) 查询 64 位原生无溢出网卡流量统计 
    /// 安全解码 RTM_IFINFO2 消息中的 sockaddr_dl 网卡名称，直接基于受边界校验的消息缓冲区读取，杜绝栈拷贝越界与 Array 值地址覆盖
    static func decodeSockaddrDLInterfaceName(
        from messagePtr: UnsafePointer<UInt8>,
        messageLength: Int,
        headerStride: Int = MemoryLayout<if_msghdr2>.stride
    ) -> String? {
        let dataOffsetInSDL = MemoryLayout<sockaddr_dl>.offset(of: \.sdl_data) ?? 8
        let nlenOffsetInSDL = MemoryLayout<sockaddr_dl>.offset(of: \.sdl_nlen) ?? 5
        guard messageLength >= headerStride + dataOffsetInSDL,
              headerStride + nlenOffsetInSDL < messageLength else {
            return nil
        }
        let nlen = Int(messagePtr[headerStride + nlenOffsetInSDL])
        let dataStart = headerStride + dataOffsetInSDL
        guard nlen > 0, dataStart + nlen <= messageLength else {
            return nil
        }
        var ifnameBytes = [UInt8](repeating: 0, count: nlen)
        let srcPtr = messagePtr.advanced(by: dataStart)
        ifnameBytes.withUnsafeMutableBufferPointer { dstBuf in
            if let dstBase = dstBuf.baseAddress {
                dstBase.update(from: srcPtr, count: nlen)
            }
        }
        return String(decoding: ifnameBytes, as: UTF8.self)
    }

    /// 依据采样周期增量与活动地址表选择当前真实活动主接口（而非单纯取开机累计总流量最大接口）
    static func selectActiveInterface(
        interfaceTotals: [String: UInt64],
        previousTotals: [String: UInt64],
        interfacesWithAddress: Set<String>,
        fallback: String = "en0"
    ) -> String {
        let enCandidates = interfaceTotals.keys.filter { $0.hasPrefix("en") }.sorted()
        guard !enCandidates.isEmpty else { return fallback }

        // 1. 优先选取本采样周期内有真实流量增量 (delta > 0) 的接口
        if !previousTotals.isEmpty {
            var bestDeltaName: String?
            var bestDelta: UInt64 = 0
            for name in enCandidates {
                guard let cur = interfaceTotals[name], let prev = previousTotals[name], cur > prev else { continue }
                let delta = cur - prev
                if delta > bestDelta || (delta == bestDelta && interfacesWithAddress.contains(name)) {
                    bestDelta = delta
                    bestDeltaName = name
                }
            }
            if let bestDeltaName {
                return bestDeltaName
            }
        }

        // 2. 若本周期处于静默期，优先选取当前分配了有效 IPv4/IPv6 地址且处于 RUNNING 状态的接口
        let addressed = enCandidates.filter { interfacesWithAddress.contains($0) }
        if let bestAddressed = addressed.max(by: { (interfaceTotals[$0] ?? 0) < (interfaceTotals[$1] ?? 0) }) {
            return bestAddressed
        }

        // 3. 兜底：选取流量最大的 en* 接口
        return enCandidates.max(by: { (interfaceTotals[$0] ?? 0) < (interfaceTotals[$1] ?? 0) }) ?? fallback
    }

    static func activeAddressedInterfaces() -> Set<String> {
        var ifaddrList: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrList) == 0, let firstAddr = ifaddrList else { return [] }
        defer { freeifaddrs(ifaddrList) }
        var out = Set<String>()
        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let ptr = cursor {
            let ifa = ptr.pointee
            let flags = ifa.ifa_flags
            let isUpAndRunning = (flags & UInt32(IFF_UP)) != 0 && (flags & UInt32(IFF_RUNNING)) != 0
            let isLoopback = (flags & UInt32(IFF_LOOPBACK)) != 0
            if isUpAndRunning && !isLoopback, let addr = ifa.ifa_addr {
                let fam = Int32(addr.pointee.sa_family)
                if fam == AF_INET || fam == AF_INET6 {
                    out.insert(String(cString: ifa.ifa_name))
                }
            }
            cursor = ifa.ifa_next
        }
        return out
    }

    static func query64BitInterfaceTraffic() -> (totalIn: UInt64, totalOut: UInt64, primaryInterface: String, perInterfaceBytes: [String: UInt64])? {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var len: Int = 0
        guard sysctl(&mib, 6, nil, &len, nil, 0) == 0, len > 0 else { return nil }

        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
        defer { buf.deallocate() }

        guard sysctl(&mib, 6, buf, &len, nil, 0) == 0 else { return nil }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var primaryInterface = "en0"
        var maxInterfaceBytes: UInt64 = 0
        var perInterfaceBytes: [String: UInt64] = [:]

        var offset = 0
        while offset < len {
            let remaining = len - offset
            guard remaining >= MemoryLayout<if_msghdr>.size else { break }
            let msgPtr = buf.advanced(by: offset)
            let ifm = msgPtr.withMemoryRebound(to: if_msghdr.self, capacity: 1) { $0.pointee }
            let msgLen = Int(ifm.ifm_msglen)
            guard msgLen > 0, msgLen <= remaining else { break }

            if ifm.ifm_type == RTM_IFINFO2,
               msgLen >= MemoryLayout<if_msghdr2>.size,
               let name = decodeSockaddrDLInterfaceName(from: UnsafePointer(msgPtr), messageLength: msgLen) {
                let if2m = msgPtr.withMemoryRebound(to: if_msghdr2.self, capacity: 1) { $0.pointee }

                let isLoopback = (if2m.ifm_flags & Int32(IFF_LOOPBACK)) != 0
                let isUp = (if2m.ifm_flags & Int32(IFF_UP)) != 0
                let isNoise = name.hasPrefix("awdl") || name.hasPrefix("llw") || name.hasPrefix("utun") ||
                              name.hasPrefix("bridge") || name.hasPrefix("gif") || name.hasPrefix("stf") ||
                              name.hasPrefix("anpi") || name.hasPrefix("ap")

                if isUp && !isLoopback && !isNoise {
                    let ib = if2m.ifm_data.ifi_ibytes
                    let ob = if2m.ifm_data.ifi_obytes
                    totalIn += ib
                    totalOut += ob
                    if name.hasPrefix("en") {
                        let sum = ib &+ ob
                        perInterfaceBytes[name] = sum
                        if sum >= maxInterfaceBytes {
                            maxInterfaceBytes = sum
                            primaryInterface = name
                        }
                    }
                }
            }
            offset += msgLen
        }

        return (totalIn, totalOut, primaryInterface, perInterfaceBytes)
    }

    /// 备用降级方案：getifaddrs
    static func queryLegacyIfAddrsTraffic() -> (totalIn: UInt64, totalOut: UInt64, primaryInterface: String, perInterfaceBytes: [String: UInt64]) {
        var ifaddrList: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrList) == 0, let firstAddr = ifaddrList else {
            return (0, 0, "en0", [:])
        }
        defer { freeifaddrs(ifaddrList) }

        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var primaryInterface = "en0"
        var maxInterfaceBytes: UInt64 = 0
        var perInterfaceBytes: [String: UInt64] = [:]

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let ptr = cursor {
            let ifa = ptr.pointee
            let name = String(cString: ifa.ifa_name)

            let isLoopback = (ifa.ifa_flags & UInt32(IFF_LOOPBACK)) != 0
            let isUp = (ifa.ifa_flags & UInt32(IFF_UP)) != 0
            let isNoise = name.hasPrefix("awdl") || name.hasPrefix("llw") || name.hasPrefix("utun") ||
                          name.hasPrefix("bridge") || name.hasPrefix("gif") || name.hasPrefix("stf") ||
                          name.hasPrefix("anpi") || name.hasPrefix("ap")

            if isUp && !isLoopback && !isNoise, let addr = ifa.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) {
                if let data = ifa.ifa_data {
                    let ifData = data.assumingMemoryBound(to: if_data.self).pointee
                    let ib = UInt64(ifData.ifi_ibytes)
                    let ob = UInt64(ifData.ifi_obytes)
                    totalIn += ib
                    totalOut += ob
                    if name.hasPrefix("en") {
                        let sum = ib &+ ob
                        perInterfaceBytes[name] = sum
                        if sum >= maxInterfaceBytes {
                            maxInterfaceBytes = sum
                            primaryInterface = name
                        }
                    }
                }
            }
            cursor = ifa.ifa_next
        }

        return (totalIn, totalOut, primaryInterface, perInterfaceBytes)
    }

    func sampleNetwork(includeExtendedDetails: Bool = true) -> NetworkTrafficSnapshot {
        let stats: (totalIn: UInt64, totalOut: UInt64, primaryInterface: String, perInterfaceBytes: [String: UInt64])
        if let queried = Self.query64BitInterfaceTraffic() {
            stats = queried
        } else {
            stats = Self.queryLegacyIfAddrsTraffic()
        }

        let totalIn = stats.totalIn
        let totalOut = stats.totalOut
        let addressedSet = Self.activeAddressedInterfaces()
        let primaryInterface = Self.selectActiveInterface(
            interfaceTotals: stats.perInterfaceBytes,
            previousTotals: prevInterfaceBytes,
            interfacesWithAddress: addressedSet,
            fallback: stats.primaryInterface
        )
        prevInterfaceBytes = stats.perInterfaceBytes

        let now = ProcessInfo.processInfo.systemUptime
        var downRate: Double = 0
        var upRate: Double = 0

        if prevNetTime > 0 {
            let dt = max(0.1, now - prevNetTime)
            if totalIn >= prevNetBytesIn {
                downRate = Double(totalIn - prevNetBytesIn) / dt
            }
            if totalOut >= prevNetBytesOut {
                upRate = Double(totalOut - prevNetBytesOut) / dt
            }
        }

        prevNetBytesIn = totalIn
        prevNetBytesOut = totalOut
        prevNetTime = now

        let downText = formatBandwidth(downRate)
        let upText = formatBandwidth(upRate)
        let ifType = primaryInterface == "en0" ? "Wi-Fi" : "Ethernet"

        let detail: NetworkDetailSnapshot
        if let cached = cachedNetworkDetail,
           cached.iface == primaryInterface,
           (!includeExtendedDetails || (now - cached.uptime) < 4.0) {
            detail = cached.detail
        } else if includeExtendedDetails {
            let inspected = NetworkInspector.shared.inspect(activeInterface: primaryInterface)
            cachedNetworkDetail = (primaryInterface, now, inspected)
            detail = inspected
        } else {
            detail = NetworkDetailSnapshot(
                interfaceName: primaryInterface,
                interfaceDisplayName: "\(ifType) (\(primaryInterface))",
                localIPv4: "—", localIPv6: "—", publicIP: "—", ispLocation: "—",
                countryFlag: "🌐", proxyType: "Direct", proxyHost: "—", latencyMs: nil, inactiveInterfaces: []
            )
        }

        peakNetDown = max(peakNetDown, downRate)
        peakNetUp = max(peakNetUp, upRate)

        return NetworkTrafficSnapshot(
            downloadBytesPerSec: downRate,
            uploadBytesPerSec: upRate,
            activeInterfaceName: primaryInterface,
            downloadSpeedText: downText,
            uploadSpeedText: upText,
            interfaceType: ifType,
            isLowLatencyEnabled: isLowLatency,
            detail: detail,
            peakDownloadBytesPerSec: peakNetDown,
            peakUploadBytesPerSec: peakNetUp
        )
    }

    func formatBandwidth(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1024 * 1024 {
            return String(format: "%.1f MB/s", bytesPerSec / (1024 * 1024))
        } else if bytesPerSec >= 1024 {
            return String(format: "%.0f KB/s", bytesPerSec / 1024)
        } else {
            return String(format: "%.1f KB/s", bytesPerSec / 1024)
        }
    }

    // MARK: - 9. 进程监控与 rusage_info_v4 真实 Energy Impact 采样 (带 PID 身份缓存)

    func sampleTopProcesses() -> (items: [MonitoredProcessItem], memoryItems: [MonitoredProcessItem], diskItems: [DiskProcessItem], totalCount: Int) {
        let pids = ProcessGuard.allRunningPIDs() ?? []
        let now = ProcessInfo.processInfo.systemUptime

        struct RawProc {
            var pid: pid_t
            var ppid: pid_t
            var startSec: Int
            var startUsec: Int
            var name: String
            var appPath: String?
            var bundleID: String
            var cpuPercent: Double
            var footprintBytes: Int64
            var energyImpact: Double
            var diskReadBytesPerSec: Double
            var diskWriteBytesPerSec: Double
            var diskTotalBytes: UInt64
            var isProtected: Bool
        }

        var rawList: [RawProc] = []
        rawList.reserveCapacity(pids.count)

        for pid in pids {
            var info = proc_taskallinfo()
            let size = proc_pidinfo(pid, PROC_PIDTASKALLINFO, 0, &info, Int32(MemoryLayout<proc_taskallinfo>.size))
            guard size == Int32(MemoryLayout<proc_taskallinfo>.size) else { continue }

            let startSec = Int(info.pbsd.pbi_start_tvsec)
            let startUsec = Int(info.pbsd.pbi_start_tvusec)
            let ppid = pid_t(info.pbsd.pbi_ppid)

            // 读取 rusage_info_v6 获取真实物理内存足迹 (ri_phys_footprint)、硬件纳焦耳能耗 (ri_energy_nj) 与磁盘读写字节 (ri_diskio_bytesread/written)
            var rusage = rusage_info_v6()
            let rRes = withUnsafeMutablePointer(to: &rusage) { ptr in
                ptr.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { reboundPtr in
                    proc_pid_rusage(pid, RUSAGE_INFO_V6, reboundPtr)
                }
            }

            let totalCpuNs: UInt64
            let footprint: Int64
            let energyNj: UInt64
            let wakeups: UInt64
            let diskReadBytes: UInt64
            let diskWriteBytes: UInt64

            if rRes == 0 {
                totalCpuNs = rusage.ri_user_time + rusage.ri_system_time
                footprint = Int64(rusage.ri_phys_footprint > 0 ? rusage.ri_phys_footprint : info.ptinfo.pti_resident_size)
                energyNj = rusage.ri_energy_nj
                wakeups = rusage.ri_pkg_idle_wkups
                diskReadBytes = rusage.ri_diskio_bytesread
                diskWriteBytes = rusage.ri_diskio_byteswritten
            } else {
                totalCpuNs = info.ptinfo.pti_total_user + info.ptinfo.pti_total_system
                footprint = Int64(info.ptinfo.pti_resident_size)
                energyNj = 0
                wakeups = 0
                diskReadBytes = 0
                diskWriteBytes = 0
            }

            var cpuPercent = 0.0
            var energyScore = 0.0
            var diskReadRate = 0.0
            var diskWriteRate = 0.0

            if let prev = procBaselines[pid], prev.startSec == startSec && prev.startUsec == startUsec {
                let dt = now - prev.sampleTime
                if dt > 0.05 {
                    if totalCpuNs >= prev.totalCpuTimeNs {
                        let dCpuTicks = Double(totalCpuNs - prev.totalCpuTimeNs)
                        let dCpuSec = dCpuTicks * Self.machTimebaseConversion
                        cpuPercent = (dCpuSec / dt) * 100.0
                    }
                    // 真实硬件能耗差分 (Apple Silicon ri_energy_nj) + 唤醒惩罚
                    let dEnergyW: Double
                    if energyNj > prev.totalEnergyNj {
                        dEnergyW = Double(energyNj - prev.totalEnergyNj) / (dt * 1_000_000_000.0)
                    } else {
                        dEnergyW = 0
                    }
                    let dWakeupsPerSec: Double
                    if wakeups >= prev.totalWakeups {
                        dWakeupsPerSec = Double(wakeups - prev.totalWakeups) / dt
                    } else {
                        dWakeupsPerSec = 0
                    }
                    // 对齐 Activity Monitor Energy Impact 量纲
                    energyScore = cpuPercent * 0.85 + dEnergyW * 12.0 + min(25.0, dWakeupsPerSec * 0.05)

                    if diskReadBytes >= prev.totalDiskReadBytes {
                        diskReadRate = Double(diskReadBytes - prev.totalDiskReadBytes) / dt
                    }
                    if diskWriteBytes >= prev.totalDiskWriteBytes {
                        diskWriteRate = Double(diskWriteBytes - prev.totalDiskWriteBytes) / dt
                    }
                }
            }

            procBaselines[pid] = ProcBaseline(
                startSec: startSec,
                startUsec: startUsec,
                totalCpuTimeNs: totalCpuNs,
                totalEnergyNj: energyNj,
                totalWakeups: wakeups,
                totalDiskReadBytes: diskReadBytes,
                totalDiskWriteBytes: diskWriteBytes,
                sampleTime: now
            )

            let appName: String
            let bundleID: String
            let appPath: String?
            let isProtected: Bool

            if let cachedId = pidIdentityCache[pid],
               cachedId.startSec == startSec && cachedId.startUsec == startUsec {
                appName = cachedId.name
                bundleID = cachedId.bundleID
                appPath = cachedId.appPath
                isProtected = cachedId.isProtected
            } else {
                let exePath = ProcessGuard.processPath(for: pid) ?? ""
                let resolved = resolveAppIdentity(pid: pid, executablePath: exePath, bsdInfo: info.pbsd)
                let prot = ProcessGuard.isProtectedSystemProcess(pid: pid, name: resolved.name)
                pidIdentityCache[pid] = (startSec, startUsec, resolved.name, resolved.bundleID, resolved.appPath, prot)
                appName = resolved.name
                bundleID = resolved.bundleID
                appPath = resolved.appPath
                isProtected = prot
            }

            rawList.append(RawProc(
                pid: pid,
                ppid: ppid,
                startSec: startSec,
                startUsec: startUsec,
                name: appName,
                appPath: appPath,
                bundleID: bundleID,
                cpuPercent: cpuPercent,
                footprintBytes: footprint,
                energyImpact: (energyScore * 10).rounded() / 10,
                diskReadBytesPerSec: diskReadRate,
                diskWriteBytesPerSec: diskWriteRate,
                diskTotalBytes: diskReadBytes &+ diskWriteBytes,
                isProtected: isProtected
            ))
        }

        if procBaselines.count > pids.count + 64 {
            let activePidSet = Set(pids)
            procBaselines = procBaselines.filter { activePidSet.contains($0.key) }
            pidIdentityCache = pidIdentityCache.filter { activePidSet.contains($0.key) }
        }

        // 按主应用容器聚合 Helper / XPC 子进程
        var aggregated: [String: MonitoredProcessItem] = [:]
        var aggregatedDisk: [String: (item: DiskProcessItem, totalBytes: UInt64)] = [:]
        for item in rawList {
            let key: String
            if !item.bundleID.isEmpty {
                key = item.bundleID
            } else if let path = item.appPath, !path.isEmpty {
                key = path
            } else {
                key = "\(item.name)#\(item.pid)"
            }

            if var existing = aggregated[key] {
                existing.cpuPercent += item.cpuPercent
                existing.residentMemory += item.footprintBytes
                existing.energyImpact += item.energyImpact
                existing.processCount += 1
                existing.memberPIDs.append(item.pid)
                // 若新进程是当前代表进程的父进程，提升为主代表进程并同步其启动时间身份
                if item.pid == existing.ppid {
                    existing.pid = item.pid
                    existing.ppid = item.ppid
                    existing.startSec = item.startSec
                    existing.startUsec = item.startUsec
                }
                if item.isProtected { existing.isSystemProtected = true }
                aggregated[key] = existing
            } else {
                aggregated[key] = MonitoredProcessItem(
                    id: key,
                    pid: item.pid,
                    ppid: item.ppid,
                    name: item.name,
                    bundleID: item.bundleID,
                    cpuPercent: item.cpuPercent,
                    residentMemory: item.footprintBytes,
                    energyImpact: item.energyImpact,
                    processCount: 1,
                    isSystemProtected: item.isProtected,
                    appPath: item.appPath,
                    startSec: item.startSec,
                    startUsec: item.startUsec,
                    memberPIDs: [item.pid]
                )
            }

            if var existingDisk = aggregatedDisk[key] {
                existingDisk.item.readBytesPerSec += item.diskReadBytesPerSec
                existingDisk.item.writeBytesPerSec += item.diskWriteBytesPerSec
                existingDisk.totalBytes &+= item.diskTotalBytes
                aggregatedDisk[key] = existingDisk
            } else if item.diskReadBytesPerSec > 0 || item.diskWriteBytesPerSec > 0 || item.diskTotalBytes > 1024 * 1024 {
                aggregatedDisk[key] = (
                    DiskProcessItem(
                        name: item.name,
                        bundleID: item.bundleID,
                        appPath: item.appPath,
                        readBytesPerSec: item.diskReadBytesPerSec,
                        writeBytesPerSec: item.diskWriteBytesPerSec
                    ),
                    item.diskTotalBytes
                )
            }
        }

        let sorted = Array(aggregated.values)
            .sorted {
                if abs($0.cpuPercent - $1.cpuPercent) > 0.1 {
                    return $0.cpuPercent > $1.cpuPercent
                }
                return $0.residentMemory > $1.residentMemory
            }
            .prefix(40)
            .map { $0 }

        let memSorted = Array(aggregated.values)
            .sorted { $0.residentMemory > $1.residentMemory }
            .prefix(30)
            .map { $0 }

        // 磁盘进程排序策略：优先按实时读写速率 max(read, write) 排序，若均为 0 则按累计磁盘读写字节降序
        let diskSorted = Array(aggregatedDisk.values)
            .sorted { a, b in
                let maxA = max(a.item.readBytesPerSec, a.item.writeBytesPerSec)
                let maxB = max(b.item.readBytesPerSec, b.item.writeBytesPerSec)
                if abs(maxA - maxB) > 1.0 {
                    return maxA > maxB
                }
                let minA = min(a.item.readBytesPerSec, a.item.writeBytesPerSec)
                let minB = min(b.item.readBytesPerSec, b.item.writeBytesPerSec)
                if abs(minA - minB) > 1.0 {
                    return minA > minB
                }
                return a.totalBytes > b.totalBytes
            }
            .prefix(8)
            .map { $0.item }

        return (sorted, memSorted, diskSorted, rawList.count)
    }

    /// 真实进程级网络带宽采样（调用 /usr/bin/nettop 差分统计每个 PID 的真实 bytes_in / bytes_out）
    func sampleTopNetworkProcesses(includeProcesses: Bool, uptimeNow: TimeInterval) -> [NetworkProcessItem] {
        guard includeProcesses else { return cachedTopNetProcesses }
        let sampleInterval = isLowLatency ? 1.0 : (includeProcesses ? AppConfig.Telemetry.networkProcessForegroundSampleInterval : AppConfig.Telemetry.networkProcessSampleInterval)
        if lastNettopSampleUptime > 0 && (uptimeNow - lastNettopSampleUptime) < sampleInterval && !cachedTopNetProcesses.isEmpty {
            return cachedTopNetProcesses
        }
        guard !isNettopSampleInFlight else { return cachedTopNetProcesses }
        isNettopSampleInFlight = true

        // 拷贝当前身份缓存快照用于后台解析名称与图标
        let identitySnapshot = pidIdentityCache
        let prevBaselines = netProcBaselines

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let sampled = Self.runNettopSample(prevBaselines: prevBaselines, identitySnapshot: identitySnapshot)
            guard let self else { return }
            self.lock.lock()
            self.netProcBaselines = sampled.baselines
            self.cachedTopNetProcesses = sampled.items
            self.lastNettopSampleUptime = ProcessInfo.processInfo.systemUptime
            self.isNettopSampleInFlight = false
            self.lock.unlock()
        }

        return cachedTopNetProcesses
    }

    static func runNettopSample(
        prevBaselines: [pid_t: NetProcBaseline],
        identitySnapshot: [pid_t: (startSec: Int, startUsec: Int, name: String, bundleID: String, appPath: String?, isProtected: Bool)]
    ) -> (items: [NetworkProcessItem], baselines: [pid_t: NetProcBaseline]) {
        let sampled = Shell.execute("/usr/bin/nettop", ["-P", "-L", "1", "-n", "-k",
            "time,interface,state,rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,arch"],
            timeout: AppConfig.Telemetry.networkProcessTimeout,
            environment: ["PATH": "/usr/bin:/bin", "LC_ALL": "en_US.UTF-8"])
        guard sampled.isSuccess, !sampled.stdout.isEmpty else { return ([], prevBaselines) }
        let output = sampled.stdout

        let now = ProcessInfo.processInfo.systemUptime
        var nextBaselines: [pid_t: NetProcBaseline] = [:]
        var aggregated: [String: (item: NetworkProcessItem, lastActive: TimeInterval, totalCumulative: UInt64)] = [:]

        var isFirstLine = true
        output.enumerateLines { line, _ in
            if isFirstLine {
                isFirstLine = false
                return
            }
            let cols = line.split(separator: ",", omittingEmptySubsequences: false)
            guard cols.count >= 3 else { return }

            let nameAndPid = cols[0]
            guard let dotIdx = nameAndPid.lastIndex(of: ".") else { return }
            let pidStr = nameAndPid[nameAndPid.index(after: dotIdx)...]
            guard let pid = pid_t(pidStr), pid > 0 else { return }
            let rawProcName = String(nameAndPid[..<dotIdx])

            let bytesIn = UInt64(cols[1]) ?? 0
            let bytesOut = UInt64(cols[2]) ?? 0

            var downRate = 0.0
            var upRate = 0.0
            var lastActive = prevBaselines[pid]?.lastActiveTime ?? 0

            if let prev = prevBaselines[pid] {
                let dt = max(0.2, now - prev.sampleTime)
                if bytesIn >= prev.bytesIn {
                    downRate = Double(bytesIn - prev.bytesIn) / dt
                }
                if bytesOut >= prev.bytesOut {
                    upRate = Double(bytesOut - prev.bytesOut) / dt
                }
                if downRate > 0 || upRate > 0 {
                    lastActive = now
                }
            }

            nextBaselines[pid] = NetProcBaseline(
                bytesIn: bytesIn,
                bytesOut: bytesOut,
                sampleTime: now,
                lastActiveTime: lastActive
            )

            // 过滤完全无历史收发记录的空套接字进程
            guard bytesIn > 0 || bytesOut > 0 else { return }

            let displayName: String
            let bundleID: String
            let appPath: String?

            if let cached = identitySnapshot[pid] {
                displayName = cached.name
                bundleID = cached.bundleID
                appPath = cached.appPath
            } else {
                displayName = rawProcName.isEmpty ? "PID \(pid)" : rawProcName
                bundleID = ""
                appPath = nil
            }

            let lowerName = displayName.lowercased()
            let lowerBundle = bundleID.lowercased()
            let isTunnel = lowerName.contains("vpn") ||
                           lowerName.contains("easyconnect") ||
                           lowerName.contains("wireguard") ||
                           lowerName.contains("openvpn") ||
                           lowerName.contains("tailscale") ||
                           lowerName.contains("clash") ||
                           lowerName.contains("sing-box") ||
                           lowerName.contains("surge") ||
                           lowerName.contains("shadowsocks") ||
                           lowerName.contains("v2ray") ||
                           lowerName.contains("xray") ||
                           lowerName.contains("anyconnect") ||
                           lowerName.contains("globalprotect") ||
                           lowerBundle.contains("vpn") ||
                           lowerBundle.contains("easyconnect") ||
                           lowerBundle.contains("wireguard")

            let key = !bundleID.isEmpty ? bundleID : (appPath ?? "\(displayName)#\(pid)")
            if var existing = aggregated[key] {
                existing.item.downloadBytesPerSec += downRate
                existing.item.uploadBytesPerSec += upRate
                existing.lastActive = max(existing.lastActive, lastActive)
                existing.totalCumulative &+= (bytesIn &+ bytesOut)
                existing.item.isTunnel = existing.item.isTunnel || isTunnel
                aggregated[key] = existing
            } else {
                aggregated[key] = (
                    NetworkProcessItem(
                        name: displayName,
                        bundleID: bundleID,
                        appPath: appPath,
                        uploadBytesPerSec: upRate,
                        downloadBytesPerSec: downRate,
                        isTunnel: isTunnel
                    ),
                    lastActive,
                    bytesIn &+ bytesOut
                )
            }
        }

        // 优先按实时 max(download, upload) 降序，相同则按最近活跃时间与累计总流量降序
        let sorted = Array(aggregated.values)
            .sorted { a, b in
                let maxA = max(a.item.downloadBytesPerSec, a.item.uploadBytesPerSec)
                let maxB = max(b.item.downloadBytesPerSec, b.item.uploadBytesPerSec)
                if abs(maxA - maxB) > 1.0 {
                    return maxA > maxB
                }
                let minA = min(a.item.downloadBytesPerSec, a.item.uploadBytesPerSec)
                let minB = min(b.item.downloadBytesPerSec, b.item.uploadBytesPerSec)
                if abs(minA - minB) > 1.0 {
                    return minA > minB
                }
                if abs(a.lastActive - b.lastActive) > 0.5 {
                    return a.lastActive > b.lastActive
                }
                return a.totalCumulative > b.totalCumulative
            }
            .prefix(6)
            .map { $0.item }

        return (sorted, nextBaselines)
    }

    func resolveAppIdentity(pid: pid_t, executablePath: String, bsdInfo: proc_bsdinfo) -> (name: String, bundleID: String, appPath: String?) {
        if executablePath.contains(".app/") {
            let components = executablePath.components(separatedBy: ".app/")
            if let first = components.first {
                let appPath = "\(first).app"
                if let cached = appBundleIdentityCache[appPath] {
                    return cached
                }
                let appURL = URL(fileURLWithPath: appPath)
                let name = appURL.deletingPathExtension().lastPathComponent
                var bid = ""
                if let bundle = Bundle(url: appURL), let bundleIdentifier = bundle.bundleIdentifier {
                    bid = bundleIdentifier
                }
                let result = (name: name, bundleID: bid, appPath: Optional(appPath))
                appBundleIdentityCache[appPath] = result
                return result
            }
        }
        if !executablePath.isEmpty {
            let lastComp = (executablePath as NSString).lastPathComponent
            if !lastComp.isEmpty {
                return (lastComp, "", nil)
            }
        }
        var bsd = bsdInfo
        let commName = withUnsafePointer(to: &bsd.pbi_name) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) { String(cString: $0) }
        }
        if !commName.isEmpty {
            return (commName, "", nil)
        }
        let fallbackName = ProcessGuard.processName(for: pid) ?? "PID \(pid)"
        return (fallbackName, "", nil)
    }

    // MARK: - 10. 进程终止接口

    func terminateProcess(
        pid: pid_t,
        expectedStartSec: Int? = nil,
        expectedStartUsec: Int? = nil,
        force: Bool = false,
        identityInspector: ((pid_t) -> (startSec: Int, startUsec: Int)?)? = nil,
        signalSender: ((pid_t, Int32) -> Int32)? = nil
    ) -> (success: Bool, message: String) {
        if ProcessGuard.isProtectedSystemProcess(pid: pid) {
            return (false, L10n.localized(.protectedSystemCoreDaemon))
        }

        if let expectedStartSec, let expectedStartUsec, (expectedStartSec != 0 || expectedStartUsec != 0) {
            let inspect = identityInspector ?? { targetPID in
                var info = proc_taskallinfo()
                let sz = proc_pidinfo(targetPID, PROC_PIDTASKALLINFO, 0, &info, Int32(MemoryLayout<proc_taskallinfo>.size))
                guard sz == Int32(MemoryLayout<proc_taskallinfo>.size) else { return nil }
                return (Int(info.pbsd.pbi_start_tvsec), Int(info.pbsd.pbi_start_tvusec))
            }
            guard let live = inspect(pid),
                  live.startSec == expectedStartSec && live.startUsec == expectedStartUsec else {
                return (false, L10n.localized(.processIdentityChangedOrExited))
            }
        }

        let signal = force ? SIGKILL : SIGTERM
        let send = signalSender ?? { targetPID, sig in kill(targetPID, sig) }
        let res = send(pid, signal)
        if res == 0 {
            return (true, force ? L10n.localized(.processTerminatedSigkillSuccess) : L10n.localized(.processTerminatedSigtermSuccess))
        } else {
            return (false, L10n.format(.processTerminateFailedErrnoFormat, Int(errno)))
        }
    }

    // MARK: - 静态辅助查询

    static func readSysctlInt(_ name: String) -> Int {
        var val: Int32 = 0
        var size = MemoryLayout<Int32>.size
        if sysctlbyname(name, &val, &size, nil, 0) == 0 {
            return Int(val)
        }
        return 0
    }

    static func readSysctlString(_ name: String) -> String {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return "" }
        var buf = [UInt8](repeating: 0, count: size)
        guard sysctlbyname(name, &buf, &size, nil, 0) == 0 else { return "" }
        return String(decoding: buf.prefix(while: { $0 != 0 }), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func readChipBrand() -> String {
        let b = readSysctlString("machdep.cpu.brand_string")
        guard !b.isEmpty else { return "Apple Silicon" }
        return b
    }

    static func readHardwareModel() -> String {
        let raw = readSysctlString("hw.model")
        let lower = raw.lowercased()
        if lower.contains("macbookair") { return "MacBook Air" }
        if lower.contains("macbookpro") { return "MacBook Pro" }
        if lower.contains("macmini") { return "Mac mini" }
        if lower.contains("macstudio") { return "Mac Studio" }
        if lower.contains("imac") { return "iMac" }
        if lower.contains("macpro") { return "Mac Pro" }
        // Mac15,x / Mac16,x 识别
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        if service != 0 {
            defer { IOObjectRelease(service) }
            if let prop = IORegistryEntryCreateCFProperty(service, "product-name" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() {
                if let data = prop as? Data,
                   let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters),
                   !str.isEmpty {
                    return str
                }
            }
        }
        return raw.isEmpty ? "Mac" : raw
    }
}
