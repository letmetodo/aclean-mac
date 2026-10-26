import SwiftUI
import AppKit

/// 命令面板（⌘K）。
///
/// 存在的理由：CleanMate 有 9 个模块、若干工具与设置页，逐层点击到达某个功能
/// 平均要 2～3 次点击加视线移动。命令面板把「找到某功能」压缩成「打三个字」。
///
/// 刻意不做的事：不做模糊打分排序（简单包含匹配已经够用）、不记录使用频次
/// （引入持久化状态会让行为不可预测）。保持它简单、可预测、响应快。
struct CommandPaletteView: View {
    @EnvironmentObject var state: AppState
    @Binding var isPresented: Bool

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private struct Entry: Identifiable {
        let id: String
        let title: String
        let group: String
        let icon: String
        let run: @MainActor () -> Void
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider().background(Theme.sep)
            resultsList
        }
        .frame(width: 560, height: 400)
        .background(Theme.contentBg)
        .onAppear { searchFocused = true }
    }

    // MARK: - 搜索栏

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.tert)
                .a11yDecorative()

            TextField(L10n.localized(.commandPalettePlaceholder), text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Theme.text)
                .focused($searchFocused)
                .accessibilityLabel(L10n.localized(.commandPalettePlaceholder))
                .onSubmit { runFirstMatch() }

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.tert)
                }
                .buttonStyle(.plain)
                .a11yControl(label: L10n.localized(.a11yClearSearchField))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: - 结果列表

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if filtered.isEmpty {
                    Text(L10n.localized(.commandPaletteNoResults))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.sub)
                        .padding(.vertical, 36)
                } else {
                    ForEach(filtered) { entry in
                        Button {
                            entry.run()
                            isPresented = false
                        } label: {
                            row(entry)
                        }
                        .buttonStyle(.plain)
                        .a11yRow(title: entry.title, value: entry.group)
                    }
                }
            }
        }
    }

    private func row(_ entry: Entry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: entry.icon)
                .font(.system(size: 13))
                .foregroundStyle(Theme.accent)
                .frame(width: 20)
                .a11yDecorative()
            Text(entry.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.text)
            Spacer(minLength: 8)
            Text(entry.group)
                .font(.system(size: 10.5))
                .foregroundStyle(Theme.tert)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }

    // MARK: - 数据

    private var entries: [Entry] {
        var out: [Entry] = []

        for spec in ModuleRegistry.all {
            guard let key = ModuleKey.parse(spec.key) else { continue }
            out.append(Entry(
                id: "module.\(spec.key)",
                title: spec.title,
                group: L10n.localized(.commandPaletteGroupModules),
                icon: spec.icon
            ) {
                state.open(.restore(key))
            })
        }

        out.append(Entry(
            id: "action.settings",
            title: L10n.localized(.preferencesEllipsis),
            group: L10n.localized(.commandPaletteGroupActions),
            icon: "gearshape"
        ) {
            state.showSettings = true
        })

        return out
    }

    private var filtered: [Entry] {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return entries }
        return entries.filter { $0.title.localizedCaseInsensitiveContains(keyword) }
    }

    private func runFirstMatch() {
        guard let first = filtered.first else { return }
        first.run()
        isPresented = false
    }
}
