import SwiftUI
import AppKit

// ============================================================
//  Art — native vector artwork, using system-provided SF Symbols.
// ============================================================

enum Art {
    /// System vector symbols replace imported artwork. No third-party bitmap lookup.
    static func ns(_ name: String) -> NSImage? {
        let key = name.lowercased()
        let symbol: String
        if key.contains("check") { symbol = "checkmark" }
        else if key.contains("arrow") { symbol = "chevron.right" }
        else if key.contains("search") { symbol = "magnifyingglass" }
        else if key.contains("application") || key.contains("uninstall") { symbol = "app.badge" }
        else if key.contains("performance") || key.contains("maintenance") { symbol = "gauge.with.dots.needle.67percent" }
        else if key.contains("space") || key.contains("storage") { symbol = "internaldrive" }
        else if key.contains("organize") || key.contains("duplicate") { symbol = "folder.badge.gearshape" }
        else if key.contains("smart") { symbol = "sparkles" }
        else { symbol = "trash.circle.fill" }
        return NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
    }
    static func has(_ name: String) -> Bool { ns(name) != nil }
    static func view(_ name: String) -> Image? { ns(name).map { Image(nsImage: $0) } }
}

// ============================================================
//  FileIconCache —— 本地文件与应用图标高性能内存缓存
// ============================================================

/// NSCache synchronizes access; cached images are published read-only.
final class FileIconCache: @unchecked Sendable {
    static let shared = FileIconCache()
    private let cache = NSCache<NSString, NSImage>()
    /// LaunchServices 的图标查询串行化：主线程与预热的多个后台队列同时调用
    /// `NSWorkspace.icon(forFile:)` 时，内部图标服务会互相等待，表现为整窗卡死。
    private let loadQueue = DispatchQueue(label: "com.personal.aclean.fileicon", qos: .utility)

    init() {
        cache.countLimit = 800
    }

    func cachedIcon(for path: String) -> NSImage? {
        cache.object(forKey: path as NSString)
    }

    func icon(for path: String) -> NSImage {
        if let cached = cachedIcon(for: path) {
            return cached
        }
        return loadQueue.sync { loadIconOnQueue(path) }
    }

    /// 视图 body 里禁止同步查图标：命中就立刻回调，未命中则丢到串行后台队列，
    /// 主线程只负责拿结果刷新，绝不阻塞在磁盘 / LaunchServices 上。
    @MainActor
    func loadIconAsync(for path: String, completion: @escaping @MainActor @Sendable (NSImage) -> Void) {
        if let cached = cachedIcon(for: path) {
            completion(cached)
            return
        }
        loadQueue.async { [weak self] in
            guard let self else { return }
            let img = self.loadIconOnQueue(path)
            Task { @MainActor in
                completion(img)
            }
        }
    }

    private func loadIconOnQueue(_ path: String) -> NSImage {
        if let cached = cachedIcon(for: path) {
            return cached
        }
        let img = NSWorkspace.shared.icon(forFile: path)
        cache.setObject(img, forKey: path as NSString)
        return img
    }
}

/// 系统矢量模板图（单色遮罩）—— 用前景色染色，用于勾选、箭头、搜索等
struct ArtIcon: View {
    var name: String
    var size: CGFloat
    var tint: Color
    var weight: Font.Weight = .regular

    var body: some View {
        if let n = Art.ns(name) {
            Image(nsImage: n)
                .renderingMode(.template)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(tint)
        } else {
            Color.clear.frame(width: size, height: size)
        }
    }
}

// ============================================================
//  ModuleArt —— 模块 ↔ 原版素材映射
// ============================================================

struct ModuleArt {
    /// 侧栏选中 / 未选中图标
    var sidebar: String
    var sidebarOff: String
    /// 介绍页大图（原版是灰模，靠染色变成模块色）
    var hero: String?
    /// 扫描列表里的模块小图标
    var scan: String?
    /// 极光渐变主色相（度）
    var hue: Double
    /// 模块主题色（用于按钮、强调）
    var accent: Color { Aurora.accent(hue) }
    /// 无原版位图素材时的 SF Symbol 兜底(如助手)
    var symbol: String? = nil
}

enum ModuleArtRegistry {
    static let table: [String: ModuleArt] = [
        "smartCare":    ModuleArt(sidebar: "cm_sidebar_smartCare",    sidebarOff: "cm_sidebar_smartCare_off",
                                  hero: "cm_hero_smartCare",  scan: "cm_scan_smartCare",  hue: 318),
        "junk":         ModuleArt(sidebar: "cm_sidebar_junk",         sidebarOff: "cm_sidebar_junk_off",
                                  hero: "cm_hero_junk",       scan: "cm_scan_junk",       hue: 134),
        "applications": ModuleArt(sidebar: "cm_sidebar_applications", sidebarOff: "cm_sidebar_applications_off",
                                  hero: "cm_hero_applications", scan: "cm_scan_applications", hue: 209),
        "spaceLens":    ModuleArt(sidebar: "cm_sidebar_spaceLens",    sidebarOff: "cm_sidebar_spaceLens_off",
                                  hero: "cm_hero_spaceLens",  scan: "cm_scan_spaceLens",  hue: 262),
        "performance":  ModuleArt(sidebar: "cm_sidebar_performance",  sidebarOff: "cm_sidebar_performance_off",
                                  hero: "cm_hero_performance", scan: "cm_scan_performance", hue: 35),
        "organize":     ModuleArt(sidebar: "cm_sidebar_organize",     sidebarOff: "cm_sidebar_organize_off",
                                  hero: "cm_hero_organize",   scan: "cm_scan_organize",   hue: 184),
        "toolbox":      ModuleArt(sidebar: "cm_sidebar_toolbox",      sidebarOff: "cm_sidebar_toolbox_off",
                                  hero: nil,                  scan: nil,                 hue: 275),
        "assistant":    ModuleArt(sidebar: "",                       sidebarOff: "",
                                  hero: nil,                  scan: nil,                 hue: 255,
                                  symbol: "wand.and.stars"),
    ]

    static func art(_ key: String) -> ModuleArt {
        table[key] ?? table["junk"]!
    }
}

// ============================================================
//  Aurora —— 极光渐变
//
//  色值取自对原版「安全防护」介绍页的 2x 截图逐点采样
//  （窗口 1200×720，Retina），并按「模块主色相 ± 偏移」换算，
//  这样每个模块都能得到与原版同款的渐变关系：
//
//    亮部  H-20°, S .84, V .56   ← 顶部弧光（屏幕最亮处）
//    中段  H -4°, S .80, V .44
//    暗部  H+12°, S .84, V .28   ← 屏幕最暗处（左下）
//
//  扫描按钮外圈的辉光（原版实测 #ce31a7 → V .81）单独用
//  Aurora.ring() 表示。
// ============================================================

enum Aurora {

    static func hsv(_ h: Double, _ s: Double, _ v: Double, _ a: Double = 1) -> Color {
        let hh = (h.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return Color(hue: hh / 360, saturation: s, brightness: v, opacity: a)
    }

    /// 渐变三段色（亮 → 中 → 暗）
    static func stops(_ hue: Double) -> [Color] {
        [hsv(hue - 20, 0.84, 0.56),
         hsv(hue -  4, 0.80, 0.44),
         hsv(hue + 12, 0.84, 0.28)]
    }

    /// 顶部弧光的核心色（比 stops 再亮一档）
    static func bloom(_ hue: Double) -> Color { hsv(hue - 18, 0.80, 0.58) }

    /// 扫描按钮外的辉光环：实测 S .77 / V .80，是整页最鲜的一块
    static func ring(_ hue: Double) -> Color { hsv(hue - 9, 0.77, 0.80) }

    /// 按钮下方那一大片柔光（比 ring 暗一档，负责把辉光晕开）
    static func halo(_ hue: Double) -> Color { hsv(hue - 12, 0.78, 0.50) }

    /// 模块强调色（按钮、进度、高亮）
    static func accent(_ hue: Double) -> Color { hsv(hue - 8, 0.72, 0.86) }

    /// 正文用色
    static let onDark       = Color.white
    static let onDarkSub    = Color.white.opacity(0.78)
    static let onDarkTert   = Color.white.opacity(0.55)
    static let hairline     = Color.white.opacity(0.14)
    static let pillHover    = Color.white.opacity(0.10)
    static let pillSelected = Color.white.opacity(0.18)

    /// 完整极光背景（静态色板由 stops 决定，动效见 AuroraBackground）
    static func background(_ hue: Double) -> some View {
        AuroraBackground(hue: hue)
    }
}

// ============================================================
//  AuroraBackground —— 会呼吸的极光背景
//
//  原版每页背景是同一套「顶部弧光」：最亮处在屏幕上方略偏左，
//  向下方四周衰减。这里分四层还原，并把动效周期压到 3.5s–7s，
//  肉眼能直接看出在流动（原周期 18s/26s 基本看不出来）：
//    ① 径向渐变打底（亮 → 暗）
//    ② 顶部弧光：中心左右摆 + 亮度呼吸
//    ③ 底部柔光：贴着下缘的一整片模块色光雾，扫动 + 胀缩
//    ④ 暗角：左右轻微摆动
// ============================================================

struct AuroraBackground: View {
    var hue: Double

    @State private var drift   = false   // 弧光中心左右摆
    @State private var breathe = false   // 弧明明暗呼吸
    @State private var sweep   = false   // 底部柔光横向扫动
    @State private var swell   = false   // 底部柔光胀缩
    @State private var sway    = false   // 暗角摆动
    /// 实际渲染的色相。切换模块时由 onChange 平滑插值过去，
    /// 不能在父级用 `.animation(value:)` ——那种隐式过渡一旦套在含
    /// repeatForever 动画的子树上会卡在中间帧，旧色相永远不褪干净
    /// （症状：球体/按钮已是新模块色，背景还是上一个模块的色）。
    @State private var shown: Double = -1

    /// 真正喂给渐变色的色相
    private var active: Double { shown < 0 ? hue : shown }

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                // ① 打底：以顶部为圆心的径向渐变（最亮处在屏幕上方）
                RadialGradient(colors: Aurora.stops(active),
                               center: UnitPoint(x: 0.44, y: -0.10),
                               startRadius: 0,
                               endRadius: max(w, h) * 0.95)

                // ② 顶部弧光：一道横向铺开的亮带，缓慢左右摆 + 明暗呼吸
                Circle()
                    .fill(RadialGradient(
                        colors: [Aurora.bloom(active).opacity(breathe ? 0.95 : 0.60),
                                 Aurora.bloom(active).opacity(0)],
                        center: .center, startRadius: 0, endRadius: 260))
                    .frame(width: w * 1.05, height: h * 0.72)
                    .scaleEffect(x: 1, y: 1)
                    .position(x: w * (drift ? 0.55 : 0.42), y: -h * 0.10)
                    .blendMode(.screen)

                // ③ 底部柔光：原版下缘那一片持续的模块色光雾
                AuroraBand(hue: active)

                // ④ 暗角 + 顶部压暗
                LinearGradient(colors: [.clear, .black.opacity(sway ? 0.30 : 0.24)],
                               startPoint: .init(x: sway ? 0.30 : 0.24, y: sway ? 0.18 : 0.10),
                               endPoint: UnitPoint(x: 1.0, y: 1.0))
                LinearGradient(colors: [.black.opacity(0.16), .clear],
                               startPoint: UnitPoint(x: 0.5, y: 0),
                               endPoint: UnitPoint(x: 0.5, y: 0.09))
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true), value: drift)
        .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: breathe)
        .animation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true), value: sway)
        .onAppear {
            drift = true
            breathe = true
            sway = true
            if shown < 0 { shown = hue }
        }
        .onChange(of: hue) { new in
            // 色相是 Double，SwiftUI 会直接把数值插值出来，整片渐变跟着平滑过渡
            withAnimation(.easeInOut(duration: 0.6)) { shown = new }
        }
    }
}

// MARK: - 底部柔光带
//
// 三块大小不同、相位不同的柔光叠在一起，各自横向漂移，
// 叠出来的形状就会缓慢地「流动」——原版下缘那片光雾的形态就是这来的。

struct AuroraBand: View {
    var hue: Double

    @State private var sweep = false
    @State private var swell = false

    var body: some View {
        GeometryReader { g in
            ZStack {
                // 正中最亮，就在扫描按钮底下（原版那团辉光的中心）
                blob(g, fx: 0.50, amp: 0.15, scale: 1.16,
                     tint: Aurora.hsv(hue - 10, 0.78, 0.54), op: 0.95)
                blob(g, fx: 0.16, amp: 0.11, scale: 1.00,
                     tint: Aurora.hsv(hue + 10, 0.82, 0.38), op: 0.72)
                blob(g, fx: 0.86, amp: 0.10, scale: 1.04,
                     tint: Aurora.hsv(hue - 30, 0.74, 0.42), op: 0.62)
            }
            .blendMode(.screen)
        }
        .blur(radius: 26)
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 5.4).repeatForever(autoreverses: true), value: sweep)
        .animation(.easeInOut(duration: 3.9).repeatForever(autoreverses: true), value: swell)
        .onAppear {
            sweep = true
            swell = true
        }
    }

    @ViewBuilder
    private func blob(_ g: GeometryProxy, fx: CGFloat, amp: CGFloat, scale: CGFloat,
                      tint: Color, op: Double) -> some View {
        let w = g.size.width, h = g.size.height
        Circle()
            .fill(RadialGradient(
                colors: [tint.opacity(op * (swell ? 1.0 : 0.62)), .clear],
                center: .center, startRadius: 0,
                endRadius: min(300, w * 0.26)))
            .frame(width: w * 0.55, height: h * 0.40)
            .scaleEffect(scale * (swell ? 1.08 : 1.0))
            .position(x: w * (fx + (sweep ? amp : -amp)), y: h * 1.05)
    }
}


