import Foundation
import Darwin

// Final rule-database identity, path expansion and safe matching helpers.

// MARK: - 规则模型

struct KBApplication {
    let recordID: Int
    let name: String
    let bundleID: String
    let type: Int
    /// 偏好面板 / 偏好设置插件(type 2 / 5)
    var isPreferencePane: Bool { type == 2 || type == 5 }
}

// MARK: - 路径展开(~/ → 家目录)

enum KBPaths {
    static var home: String {
        FileUtil.home.path
    }
    static let darwinUserTempDir: String = {
        var buf = [CChar](repeating: 0, count: Int(PATH_MAX))
        if confstr(_CS_DARWIN_USER_TEMP_DIR, &buf, buf.count) > 0 {
            let raw = String(decoding: buf.prefix(while: { $0 != 0 }).map(UInt8.init(bitPattern:)), as: UTF8.self)
            let trimmed = raw.hasSuffix("/") && raw.count > 1 ? String(raw.dropLast()) : raw
            return URL(fileURLWithPath: trimmed).standardizedFileURL.path
        }
        let fallback = NSTemporaryDirectory()
        let trimmed = fallback.hasSuffix("/") && fallback.count > 1 ? String(fallback.dropLast()) : fallback
        return URL(fileURLWithPath: trimmed).standardizedFileURL.path
    }()
    static let darwinUserCacheDir: String = {
        var buf = [CChar](repeating: 0, count: Int(PATH_MAX))
        if confstr(_CS_DARWIN_USER_CACHE_DIR, &buf, buf.count) > 0 {
            let raw = String(decoding: buf.prefix(while: { $0 != 0 }).map(UInt8.init(bitPattern:)), as: UTF8.self)
            let trimmed = raw.hasSuffix("/") && raw.count > 1 ? String(raw.dropLast()) : raw
            return URL(fileURLWithPath: trimmed).standardizedFileURL.path
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches").path
    }()
    static func expand(_ p: String) -> String {
        var s = p
        if s.contains("{DARWIN_USER_TEMP_DIR}") {
            s = s.replacingOccurrences(of: "{DARWIN_USER_TEMP_DIR}", with: darwinUserTempDir)
        }
        if s.contains("{DARWIN_USER_CACHE_DIR}") {
            s = s.replacingOccurrences(of: "{DARWIN_USER_CACHE_DIR}", with: darwinUserCacheDir)
        }
        if s.contains("{HOME}") {
            s = s.replacingOccurrences(of: "{HOME}", with: home)
        }
        if s.hasPrefix("~/") { return home + String(s.dropFirst(1)) }
        if s == "~" { return home }
        return s
    }
    /// 以前缀拼装相对路径(前缀保证以 / 结尾,相对值去掉开头 /)
    static func join(_ prefix: String, _ relative: String) -> String {
        let rel = relative.hasPrefix("/") ? String(relative.dropFirst()) : relative
        return prefix + rel
    }
}

// MARK: - 高性能正则求值器
//
//  规则库里近 200 条 IsRegex 规则(.*Safari.*、^TemporaryItems$、
//  ^/System/Library(?!/Caches/...) 等)会在扫描中被反复求值。
//  NSRegularExpression 编译成本高,这里做全局编译缓存 + 失败记忆,
//  同一 pattern 只编译一次;大小写不敏感(macOS 文件系统语义)。

final class RegexEngine: @unchecked Sendable {
    static let shared = RegexEngine()
    private var cache: [String: NSRegularExpression] = [:]
    private var failed: Set<String> = []
    private let lock = NSLock()

    private init() {}

    func compiled(_ pattern: String) -> NSRegularExpression? {
        lock.lock()
        defer { lock.unlock() }
        if let re = cache[pattern] { return re }
        if failed.contains(pattern) { return nil }
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            failed.insert(pattern)
            return nil
        }
        cache[pattern] = re
        return re
    }

    /// 整串匹配(规则语义:Value 是完整匹配模式,如 ^TemporaryItems$ / .*Safari.*)
    func matches(_ pattern: String, _ string: String) -> Bool {
        guard let re = compiled("\\A(?:\(pattern))\\z") else { return false }
        let range = NSRange(string.startIndex..., in: string)
        guard let m = re.firstMatch(in: string, options: [], range: range) else { return false }
        return m.range == range
    }

    /// 包含匹配(宽松语义:模式出现在任意位置即命中)
    func contains(_ pattern: String, _ string: String) -> Bool {
        guard let re = compiled(pattern) else { return false }
        let range = NSRange(string.startIndex..., in: string)
        return re.firstMatch(in: string, options: [], range: range) != nil
    }
}

// MARK: - 动态占位符解析
//
//  规则模板支持 {bundleID} / {appName} / {vendor} 三类占位符,
//  统一卸载规则路径展开语义。

enum RuleTemplate {
    static func resolve(_ template: String, bundleID: String, appName: String) -> String {
        guard template.contains("{") else { return template }
        var s = template
        if s.contains("{bundleID}") {
            s = s.replacingOccurrences(of: "{bundleID}", with: bundleID)
        }
        if s.contains("{appName}") {
            s = s.replacingOccurrences(of: "{appName}", with: appName)
        }
        if s.contains("{vendor}") {
            // vendor = BundleID 前两段(com.google.Chrome → com.google)
            let parts = bundleID.split(separator: ".").prefix(2).joined(separator: ".")
            s = s.replacingOccurrences(of: "{vendor}", with: parts)
        }
        return s
    }
}

// MARK: - 预编译正则与子树可省略性证明

struct CompiledKBRegex: @unchecked Sendable {
    let pattern: String
    let regex: NSRegularExpression
    let isWholeMatch: Bool
    let requiredLowerPrefix: String?
    let requiredLowerSubstrings: [String]

    init?(pattern: String, isWholeMatch: Bool) {
        let actualPattern = isWholeMatch ? "^(?:\(pattern))$" : pattern
        guard let re = try? NSRegularExpression(pattern: actualPattern, options: [.caseInsensitive]) else {
            return nil
        }
        self.pattern = pattern
        self.regex = re
        self.isWholeMatch = isWholeMatch
        self.requiredLowerPrefix = nil
        self.requiredLowerSubstrings = []
    }

    func matches(_ candidate: String, lowerCandidate: String) -> Bool {
        if let reqPrefix = requiredLowerPrefix, !lowerCandidate.hasPrefix(reqPrefix) {
            return false
        }
        for sub in requiredLowerSubstrings {
            if !lowerCandidate.contains(sub) {
                return false
            }
        }
        let range = NSRange(candidate.startIndex..<candidate.endIndex, in: candidate)
        return regex.firstMatch(in: candidate, options: [], range: range) != nil
    }

    /// 从正则表达式语法树中确定性提取必须出现的字面量前缀与子串（仅当无顶层分支且字面量无 0 次量词时提取）
    static func extractRequiredLiterals(from rawPattern: String) -> (prefix: String?, substrings: [String]) {
        var pattern = rawPattern
        if pattern.hasPrefix("^(") && pattern.hasSuffix(")$") && !pattern.contains("|") {
            let inner = String(pattern.dropFirst(2).dropLast(2))
            if !inner.contains("(") && !inner.contains(")") {
                pattern = "^" + inner + "$"
            }
        }
        let chars = Array(pattern)
        var depth = 0
        var inCharClass = false
        var i = 0
        while i < chars.count {
            let c = chars[i]
            if c == "\\" {
                i += 2
                continue
            }
            if inCharClass {
                if c == "]" { inCharClass = false }
                i += 1
                continue
            }
            if c == "[" {
                inCharClass = true
            } else if c == "(" {
                depth += 1
            } else if c == ")" {
                depth = max(0, depth - 1)
            } else if c == "|" && depth == 0 {
                return (nil, [])
            }
            i += 1
        }

        var atStart = false
        var prefix: String? = nil
        var substrings: [String] = []
        var current = ""

        func flush() {
            if !current.isEmpty {
                let low = current.lowercased()
                if atStart && prefix == nil {
                    prefix = low
                }
                if low.count >= 2 && !substrings.contains(low) {
                    substrings.append(low)
                }
                current = ""
            }
            atStart = false
        }

        func skipQuantifier(_ idx: inout Int) {
            guard idx < chars.count else { return }
            let q = chars[idx]
            if q == "*" || q == "?" || q == "+" {
                idx += 1
                if idx < chars.count && chars[idx] == "?" { idx += 1 }
            } else if q == "{" {
                while idx < chars.count && chars[idx] != "}" { idx += 1 }
                if idx < chars.count && chars[idx] == "}" { idx += 1 }
                if idx < chars.count && chars[idx] == "?" { idx += 1 }
            }
        }

        i = 0
        if !chars.isEmpty && chars[0] == "^" {
            atStart = true
            i = 1
        }
        while i < chars.count {
            let c = chars[i]
            if c == "\\" {
                guard i + 1 < chars.count else { break }
                let next = chars[i + 1]
                if next == "." || next == "/" || next == "-" || next == "_" || next == " " {
                    let qIdx = i + 2
                    if qIdx < chars.count && (chars[qIdx] == "*" || chars[qIdx] == "?" || chars[qIdx] == "{") {
                        flush()
                        i = qIdx
                        skipQuantifier(&i)
                        continue
                    } else if qIdx < chars.count && chars[qIdx] == "+" {
                        current.append(next)
                        flush()
                        i = qIdx
                        skipQuantifier(&i)
                        continue
                    } else {
                        current.append(next)
                        i += 2
                        continue
                    }
                } else {
                    flush()
                    i += 2
                    skipQuantifier(&i)
                    continue
                }
            } else if c == "(" {
                flush()
                var d = 1
                i += 1
                while i < chars.count && d > 0 {
                    if chars[i] == "\\" {
                        i += 2
                        continue
                    }
                    if chars[i] == "(" { d += 1 }
                    else if chars[i] == ")" { d -= 1 }
                    i += 1
                }
                skipQuantifier(&i)
                continue
            } else if c == "[" {
                flush()
                i += 1
                while i < chars.count && chars[i] != "]" {
                    if chars[i] == "\\" { i += 2 } else { i += 1 }
                }
                if i < chars.count && chars[i] == "]" { i += 1 }
                skipQuantifier(&i)
                continue
            } else if c == "." || c == "^" || c == "$" || c == "*" || c == "+" || c == "?" || c == "{" || c == "|" {
                flush()
                i += 1
                continue
            } else {
                let qIdx = i + 1
                if qIdx < chars.count && (chars[qIdx] == "*" || chars[qIdx] == "?" || chars[qIdx] == "{") {
                    flush()
                    i = qIdx
                    skipQuantifier(&i)
                    continue
                } else if qIdx < chars.count && chars[qIdx] == "+" {
                    current.append(c)
                    flush()
                    i = qIdx
                    skipQuantifier(&i)
                    continue
                } else {
                    current.append(c)
                    i += 1
                }
            }
        }
        flush()
        return (prefix, substrings)
    }
}

struct KBSubtreeProtectionPlan: Sendable {
    let isLoaded: Bool
    let applicablePathLiterals: Set<String>
    let protectedBundleIDs: Set<String>
    let bundleRegexes: [CompiledKBRegex]
    let nameRegexes: [CompiledKBRegex]
    let pathRegexes: [CompiledKBRegex]

    func isProtectedDescendant(
        path: String,
        lastComponent: String,
        lastComponentLower: String,
        getLowerPath: () -> String
    ) -> Bool {
        guard isLoaded else { return false }
        if protectedBundleIDs.contains(lastComponentLower) {
            return true
        }
        for re in bundleRegexes {
            if re.matches(lastComponentLower, lowerCandidate: lastComponentLower) {
                return true
            }
        }
        for re in nameRegexes {
            if re.matches(lastComponent, lowerCandidate: lastComponentLower) {
                return true
            }
        }
        if !applicablePathLiterals.isEmpty || !pathRegexes.isEmpty {
            let lowerPath = getLowerPath()
            if !applicablePathLiterals.isEmpty {
                if applicablePathLiterals.contains(lowerPath) { return true }
                for lit in applicablePathLiterals where lowerPath.hasPrefix(lit + "/") {
                    return true
                }
            }
            for re in pathRegexes {
                if re.matches(path, lowerCandidate: lowerPath) {
                    return true
                }
            }
        }
        return false
    }
}

