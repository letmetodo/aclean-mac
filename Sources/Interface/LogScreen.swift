import SwiftUI

// ============================================================
//  LogScreen —— 清理完成与会话追踪日志查看页
// ============================================================

struct LogScreen: View {
    @EnvironmentObject var state: AppState
    @ObservedObject private var l10n = L10n.shared
    @ObservedObject private var config = AppConfigStore.shared

    init() {}

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(state.spec.title) · \(L10n.localized(.actionViewLogs))")
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.text)
                Spacer()
                GhostButton(title: L10n.localized(.actionBackAlt), icon: "chevron.left") { state.back() }
            }
            .padding(.horizontal, 24).frame(height: 52)

            Divider().background(Theme.sep)

            if let rep = state.report {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        SectionLabel(text: "\(L10n.localized(.actionViewLogs)) (\(rep.outcomes.count) \(L10n.localized(.unitItems)))")
                            .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 8)

                        ForEach(rep.outcomes) { o in
                            HStack(spacing: 10) {
                                Image(systemName: o.ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(o.ok ? Theme.green : Theme.amber)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(o.name).font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.text)
                                        .lineLimit(1)
                                    if let e = o.error {
                                        Text(e).font(.system(size: 10)).foregroundStyle(Theme.amber)
                                    } else if !o.path.isEmpty {
                                        Text(o.path).font(Theme.mono).foregroundStyle(Theme.tert)
                                            .lineLimit(1).truncationMode(.middle)
                                    }
                                }
                                Spacer(minLength: 8)
                                SizeBadge(text: Fmt.size(o.size))
                            }
                            .padding(.horizontal, 24).padding(.vertical, 6)
                        }

                        if !state.log.isEmpty {
                            SectionLabel(text: L10n.localized(.systemSessionTracing))
                                .padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 8)
                            ForEach(state.log) { e in
                                HStack(spacing: 10) {
                                    Text(Fmt.date(e.time)).font(Theme.mono).foregroundStyle(Theme.tert)
                                    Text(e.title).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text)
                                    Text(e.detail).font(.system(size: 10)).foregroundStyle(Theme.sub)
                                    Spacer()
                                }
                                .padding(.horizontal, 24).padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            } else {
                EmptyState(icon: "list.bullet.rectangle", title: L10n.localized(.actionViewLogs))
            }
        }
        .background(Theme.contentBg)
    }
}
