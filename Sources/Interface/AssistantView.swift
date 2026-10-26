import SwiftUI

// ============================================================
//  助手页 —— 健康分圆环 + 建议卡片
//  对应原版 AssistantModule 的 Health Score 视图。
// ============================================================

struct AssistantView: View {
    @EnvironmentObject var state: AppState
    @State private var report: AssistantModule.Report?
    @State private var loading = false

    var body: some View {
        Group {
            if let r = report {
                content(r)
            } else {
                intro
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }

    // MARK: 介绍页

    var intro: some View {
        VStack(spacing: 20) {
            Spacer()

            if Art.has("cm_hero_smartCare"), let img = Art.ns("cm_hero_smartCare") {
                Image(nsImage: img)
                    .resizable().interpolation(.high).scaledToFit()
                    .frame(width: 96, height: 96)
                    .shadow(color: Color.black.opacity(0.35), radius: 12, y: 4)
            } else {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 54))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Text(L10n.localized(.moduleAssistantTitle))
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
            Text(L10n.localized(.assistantHeroSubtitle))
                .font(.system(size: 13))
                .foregroundStyle(Aurora.onDarkSub)

            Button {
                evaluate()
            } label: {
                HStack(spacing: 8) {
                    if loading { ProgressView().controlSize(.small).tint(.white) }
                    Image(systemName: "stethoscope")
                    Text(loading ? L10n.localized(.statusAssessingEllipsis) : L10n.localized(.actionAssessMyMac))
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 26).padding(.vertical, 12)
                .background(Capsule().fill(Color.white.opacity(0.18)))
                .overlay(Capsule().strokeBorder(Aurora.hairline, lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .disabled(loading)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: 结果页

    func content(_ r: AssistantModule.Report) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                scoreRing(r.score)
                    .padding(.vertical, 10)

                VStack(spacing: 10) {
                    ForEach(r.suggestions) { s in
                        card(s)
                    }
                }

                if r.suggestions.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.green)
                        Text(L10n.localized(.assistantAllGoodNoSuggestionsPrompt))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.black.opacity(0.25)))
                }

                Button(L10n.localized(.actionReAssess)) { report = nil }
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.75))
                    .buttonStyle(.plain)
                    .padding(.top, 6)
            }
            .padding(28)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
    }

    func scoreRing(_ score: Int) -> some View {
        let tint = score >= 85 ? Color(red: 0.35, green: 0.90, blue: 0.55) :
                  (score >= 70 ? Color(red: 0.40, green: 0.85, blue: 0.95) :
                  (score >= 50 ? Theme.amber : Theme.red))

        let statusText = score >= 85 ? L10n.localized(.healthExcellent) :
                        (score >= 70 ? L10n.localized(.healthGood) :
                        (score >= 50 ? L10n.localized(.statusNormal) : L10n.localized(.healthNeedsAttention)))
        let descText = score >= 85 ? L10n.localized(.assistantEvaluationScoreExcellentDesc) :
                      (score >= 70 ? L10n.localized(.assistantEvaluationScoreGoodDesc) :
                      (score >= 50 ? L10n.localized(.assistantEvaluationScoreFairDesc) :
                                     L10n.localized(.assistantEvaluationScorePoorDesc)))

        return VStack(spacing: 12) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.12), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(tint, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: score)
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(statusText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(tint)
                }
            }
            .frame(width: 140, height: 140)

            Text(descText)
                .font(.system(size: 12))
                .foregroundStyle(Aurora.onDarkSub)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
    }

    func card(_ s: AssistantModule.Suggestion) -> some View {
        Button {
            state.open(.restore(ModuleKey.parse(s.moduleKey) ?? .junk))
        } label: {
            HStack(spacing: 14) {
                if !s.asset.isEmpty, Art.has(s.asset), let img = Art.ns(s.asset) {
                    Image(nsImage: img)
                        .resizable().interpolation(.high).scaledToFit()
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.25), radius: 4, y: 2)
                } else {
                    Image(systemName: s.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.12)))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(s.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(s.detail)
                        .font(.system(size: 11))
                        .foregroundStyle(Aurora.onDarkSub)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(L10n.localized(.actionGoToSection))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.75))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.black.opacity(0.25)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.10), lineWidth: 0.6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func evaluate() {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let r = AssistantModule.health()
            DispatchQueue.main.async {
                report = r
                loading = false
                state.log.append(LogEntry(title: L10n.localized(.assistantHealthAssessmentTitle),
                                          detail: L10n.format(.assistantEvaluationScoreSummaryFormat, r.score, r.suggestions.count),
                                          ok: true))
            }
        }
    }
}
