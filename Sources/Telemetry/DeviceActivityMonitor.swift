import Foundation
import CoreAudio
import CoreMediaIO
import IOKit

// ============================================================
//  DeviceActivityMonitor —— 摄像头、麦克风隐私占用监测与蓝牙外设真实电量采集
//
//  职责：
//    1. 通过 CoreMediaIO (kCMIODevicePropertyDeviceIsRunningSomewhere) 实时检测物理摄像头占用；
//    2. 通过 CoreAudio (kAudioDevicePropertyDeviceIsRunningSomewhere) 实时检测麦克风输入流占用；
//    3. 通过 IOKit (AppleDeviceManagementHIDEventService / IOHIDDevice) 采集蓝牙键鼠、触控板、耳机真实电量。
// ============================================================

struct PrivacyHardwareSignals: Sendable {
    var isCameraActive: Bool
    var isMicrophoneActive: Bool

    var summaryText: String {
        switch (isCameraActive, isMicrophoneActive) {
        case (true, true):   return L10n.localized(.cameraAndMicInUse)
        case (true, false):  return L10n.localized(.cameraInUse)
        case (false, true):  return L10n.localized(.microphoneInUse)
        case (false, false): return L10n.localized(.notInUse)
        }
    }
}

struct BluetoothPeripheralBattery: Identifiable, Sendable {
    var id: String
    var name: String
    var batteryPercent: Int
    var categorySymbol: String
}

final class DeviceActivityMonitor: @unchecked Sendable {

    static let shared = DeviceActivityMonitor()

    private init() {}

    // MARK: - 1. 摄像头与麦克风实时占用状态

    func samplePrivacySignals() -> PrivacyHardwareSignals {
        let camActive = isAnyCameraRunning()
        let micActive = isAnyMicrophoneRunning()
        return PrivacyHardwareSignals(isCameraActive: camActive, isMicrophoneActive: micActive)
    }

    private func isAnyCameraRunning() -> Bool {
        var prop = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )

        var dataSize: UInt32 = 0
        guard CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, &dataSize) == OSStatus(kCMIOHardwareNoError),
              dataSize > 0 else {
            return false
        }

        let count = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
        var devices = [CMIODeviceID](repeating: 0, count: count)
        var dataUsed: UInt32 = 0
        guard CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, dataSize, &dataUsed, &devices) == OSStatus(kCMIOHardwareNoError) else {
            return false
        }

        var runProp = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )

        for dev in devices {
            var isRunning: UInt32 = 0
            let runSize = UInt32(MemoryLayout<UInt32>.size)
            var used: UInt32 = 0
            if CMIOObjectGetPropertyData(dev, &runProp, 0, nil, runSize, &used, &isRunning) == OSStatus(kCMIOHardwareNoError) {
                if isRunning != 0 {
                    return true
                }
            }
        }
        return false
    }

    private func isAnyMicrophoneRunning() -> Bool {
        var runProp = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let runSize = UInt32(MemoryLayout<UInt32>.size)

        // 1. 先检查默认音频输入设备
        var defaultInputID = AudioDeviceID(0)
        var defaultProp = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        if AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &defaultProp, 0, nil, &size, &defaultInputID) == noErr,
           defaultInputID != kAudioObjectUnknown {
            var isRunning: UInt32 = 0
            var rSize = runSize
            if AudioObjectGetPropertyData(defaultInputID, &runProp, 0, nil, &rSize, &isRunning) == noErr, isRunning != 0 {
                return true
            }
        }

        // 2. 枚举全部音频设备，检查任何具备输入通道 (Input Scope) 的麦克风/外置音频接口是否正在采集
        var devicesProp = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &devicesProp, 0, nil, &dataSize) == noErr,
              dataSize > 0 else {
            return false
        }
        let count = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &devicesProp, 0, nil, &dataSize, &devices) == noErr else {
            return false
        }

        var streamConfigProp = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        for dev in devices where dev != kAudioObjectUnknown {
            var cfgSize: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(dev, &streamConfigProp, 0, nil, &cfgSize) == noErr,
                  cfgSize >= UInt32(MemoryLayout<AudioBufferList>.size) else { continue }
            let rawPtr = UnsafeMutableRawPointer.allocate(byteCount: Int(cfgSize), alignment: MemoryLayout<AudioBufferList>.alignment)
            defer { rawPtr.deallocate() }
            guard AudioObjectGetPropertyData(dev, &streamConfigProp, 0, nil, &cfgSize, rawPtr) == noErr else { continue }
            let bufferList = UnsafeMutableAudioBufferListPointer(rawPtr.assumingMemoryBound(to: AudioBufferList.self))
            let inputChannels = bufferList.reduce(0) { $0 + Int($1.mNumberChannels) }
            guard inputChannels > 0 else { continue }

            var isRunning: UInt32 = 0
            var rSize = runSize
            if AudioObjectGetPropertyData(dev, &runProp, 0, nil, &rSize, &isRunning) == noErr, isRunning != 0 {
                return true
            }
        }
        return false
    }

    // MARK: - 2. 蓝牙与无线 HID 外设真实电量采集

    func sampleBluetoothPeripherals() -> [BluetoothPeripheralBattery] {
        var result: [BluetoothPeripheralBattery] = []
        var seen = Set<String>()

        for serviceName in ["AppleDeviceManagementHIDEventService", "IOBluetoothHIDDriver"] {
            guard let matching = IOServiceMatching(serviceName) else { continue }
            var iter: io_iterator_t = 0
            guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iter) == kIOReturnSuccess else { continue }
            defer { IOObjectRelease(iter) }

            var service = IOIteratorNext(iter)
            while service != 0 {
                var props: Unmanaged<CFMutableDictionary>?
                if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                   let dict = props?.takeRetainedValue() as? [String: Any] {
                    if let pct = dict["BatteryPercent"] as? Int, pct > 0 && pct <= 100 {
                        let name = (dict["Product"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Bluetooth Peripheral"
                        if !seen.contains(name) {
                            seen.insert(name)
                            result.append(BluetoothPeripheralBattery(
                                id: name,
                                name: name,
                                batteryPercent: pct,
                                categorySymbol: symbolForPeripheral(name: name)
                            ))
                        }
                    }
                }
                IOObjectRelease(service)
                service = IOIteratorNext(iter)
            }
        }
        return result
    }

    private func symbolForPeripheral(name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("mouse") { return "magicmouse" }
        if lower.contains("trackpad") { return "rectangle.and.hand.point.up.left" }
        if lower.contains("keyboard") { return "keyboard" }
        if lower.contains("airpods") || lower.contains("beats") || lower.contains("headphone") { return "airpodspro" }
        return "wave.3.right.circle"
    }
}
