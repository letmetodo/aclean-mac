import Foundation
import SwiftUI

enum Screen: Equatable {
    case intro          // ① 介绍页
    case scanning       // ② 扫描进度
    case results        // ③ 磁贴结果页
    case dataManager    // ④ 数据管理器
    case review         // ⑤ 清理前确认
    case cleaning       // ⑥ 清理进度
    case complete       // ⑦ 清理结果
    case log            // ⑧ 清理日志
}

/// 承重模块键：整份会话状态的唯一身份
enum ModuleKey: String, Hashable, Codable, Sendable, CaseIterable, ExpressibleByStringLiteral {
    case healthCheck, junk, performance, applications, spaceLens, organize, liveMonitor
    case smartCare, toolbox, assistant

    static let sidebar: [ModuleKey] = [
        .healthCheck, .junk, .performance, .applications, .spaceLens, .organize, .liveMonitor
    ]

    init(stringLiteral value: String) {
        self = ModuleKey.parse(value) ?? .junk
    }

    /// 调试参数、旧存档。未知字符串变成 nil，调用方显示 junk，不往字典里写垃圾键。
    static func parse(_ raw: String) -> ModuleKey? {
        ModuleKey(rawValue: raw)
    }
}

func == (lhs: ModuleKey, rhs: String) -> Bool {
    lhs.rawValue == rhs
}
func == (lhs: String, rhs: ModuleKey) -> Bool {
    lhs == rhs.rawValue
}
func != (lhs: ModuleKey, rhs: String) -> Bool {
    lhs.rawValue != rhs
}
func != (lhs: String, rhs: ModuleKey) -> Bool {
    lhs != rhs.rawValue
}

enum OpenRequest: Sendable {
    case restore(ModuleKey)
    /// tree 为空时，open 内部改走 restore。
    case smartResult(ModuleKey, tree: [Node])
}

public enum ApplicationsTab: String, Codable, Sendable, CaseIterable, Identifiable {
    case uninstall = "uninstall"
    case leftovers = "leftovers"

    public var id: String { rawValue }

    public var titleKey: L10nKey {
        switch self {
        case .uninstall: return .tabUninstall
        case .leftovers: return .tabLeftovers
        }
    }

    public var title: String {
        L10n.localized(titleKey)
    }

    public static func parse(_ saved: String) -> ApplicationsTab {
        let lower = saved.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower == "leftovers" || lower == "残留" || lower == "leftover" {
            return .leftovers
        }
        return .uninstall
    }
}

public enum SpaceChartMode: String, Codable, Sendable, CaseIterable {
    case treemap = "treemap"
    case orbit   = "orbit"

    public var titleKey: L10nKey {
        switch self {
        case .treemap: return .chartTreemap
        case .orbit:   return .chartOrbitLens
        }
    }

    public var localizedTitle: String {
        L10n.localized(titleKey)
    }
}

public enum SpacePane: String, Codable, Sendable, CaseIterable {
    case directory    = "directory"
    case largestFiles = "largestFiles"

    public var titleKey: L10nKey {
        switch self {
        case .directory:    return .scopeCurrentFolder
        case .largestFiles: return .scopeLargestFiles
        }
    }

    public var localizedTitle: String {
        L10n.localized(titleKey)
    }
}
