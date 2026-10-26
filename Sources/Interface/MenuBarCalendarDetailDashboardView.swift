import SwiftUI
import AppKit

// MARK: - 7. 日历 + 节气休息日 + 月相天文弹窗 (Calendar & Moon Phase Flyout - 原生系统监控规范)

struct CalendarDetailDashboardView: View {
    @ObservedObject var appConfig = AppConfigStore.shared
    @State private var monthOffset: Int = 0
    @State private var selectedDate: Date = Date()

    private var orderedWeekdaySymbols: [(symbol: String, isWeekend: Bool)] {
        let cal = Calendar.current
        let raw = cal.veryShortStandaloneWeekdaySymbols
        guard raw.count == 7 else {
            return raw.map { ($0, false) }
        }
        let firstIdx = max(0, min(6, cal.firstWeekday - 1))
        var result: [(String, Bool)] = []
        for i in 0..<7 {
            let weekdayIndex = (firstIdx + i) % 7 // 0 = Sunday, 6 = Saturday
            let isWknd = (weekdayIndex == 0 || weekdayIndex == 6)
            result.append((raw[weekdayIndex], isWknd))
        }
        return result
    }

    private struct CalendarDayCell: Identifiable {
        let id: String
        let date: Date
        let dayNumber: Int
        let isOtherMonth: Bool
        let isToday: Bool
        let isSelected: Bool
        let isWeekend: Bool
        let hasMarkerDot: Bool
        let lunarShortText: String
    }

    private var displayedMonthDate: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    private func lunarSummary(for date: Date) -> (short: String, full: String, isFestivalOrFirst: Bool) {
        let chineseCal = Calendar(identifier: .chinese)
        let comps = chineseCal.dateComponents([.month, .day], from: date)
        let d = comps.day ?? 1

        let f = DateFormatter()
        f.calendar = chineseCal
        f.dateStyle = .medium
        f.timeStyle = .none
        let formatted = f.string(from: date)

        let hasDot = (d == 1) || (d == 15)
        return ("\(d)", formatted, hasDot)
    }

    private func buildMonthGrid(for monthRef: Date) -> [[CalendarDayCell]] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: monthRef)
        guard let firstOfMonth = cal.date(from: comps),
              let daysRange = cal.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }

        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let leadingCount = (firstWeekday - cal.firstWeekday + 7) % 7
        let prevMonthDate = cal.date(byAdding: .month, value: -1, to: firstOfMonth) ?? firstOfMonth
        let prevMonthDays = cal.range(of: .day, in: .month, for: prevMonthDate)?.count ?? 30

        var cells: [CalendarDayCell] = []

        if leadingCount > 0 {
            for i in (prevMonthDays - leadingCount + 1)...prevMonthDays {
                let offset = i - prevMonthDays - 1
                let dDate = cal.date(byAdding: .day, value: offset, to: firstOfMonth) ?? firstOfMonth
                let lunar = lunarSummary(for: dDate)
                let isWknd = cal.isDateInWeekend(dDate)
                cells.append(
                    CalendarDayCell(
                        id: "prev_\(i)",
                        date: dDate,
                        dayNumber: i,
                        isOtherMonth: true,
                        isToday: cal.isDateInToday(dDate),
                        isSelected: cal.isDate(dDate, inSameDayAs: selectedDate),
                        isWeekend: isWknd,
                        hasMarkerDot: lunar.isFestivalOrFirst || isWknd,
                        lunarShortText: lunar.short
                    )
                )
            }
        }

        for d in daysRange {
            let dDate = cal.date(byAdding: .day, value: d - 1, to: firstOfMonth) ?? firstOfMonth
            let lunar = lunarSummary(for: dDate)
            let isWknd = cal.isDateInWeekend(dDate)
            cells.append(
                CalendarDayCell(
                    id: "cur_\(d)",
                    date: dDate,
                    dayNumber: d,
                    isOtherMonth: false,
                    isToday: cal.isDateInToday(dDate),
                    isSelected: cal.isDate(dDate, inSameDayAs: selectedDate),
                    isWeekend: isWknd,
                    hasMarkerDot: lunar.isFestivalOrFirst || isWknd,
                    lunarShortText: lunar.short
                )
            )
        }

        var nextDay = 1
        let curCount = daysRange.count
        while cells.count % 7 != 0 || cells.count < 42 {
            let dDate = cal.date(byAdding: .day, value: curCount + nextDay - 1, to: firstOfMonth) ?? firstOfMonth
            let lunar = lunarSummary(for: dDate)
            let isWknd = cal.isDateInWeekend(dDate)
            cells.append(
                CalendarDayCell(
                    id: "next_\(nextDay)",
                    date: dDate,
                    dayNumber: nextDay,
                    isOtherMonth: true,
                    isToday: cal.isDateInToday(dDate),
                    isSelected: cal.isDate(dDate, inSameDayAs: selectedDate),
                    isWeekend: isWknd,
                    hasMarkerDot: lunar.isFestivalOrFirst || isWknd,
                    lunarShortText: lunar.short
                )
            )
            nextDay += 1
        }

        var rows: [[CalendarDayCell]] = []
        for idx in stride(from: 0, to: cells.count, by: 7) {
            rows.append(Array(cells[idx..<min(idx + 7, cells.count)]))
        }
        return rows
    }

    private func moonPhaseInfo(for date: Date) -> (name: String, icon: String, illumination: Int) {
        // 基准朔月时间：2000-01-06 18:14:00 UTC (947182440)
        let refNewMoon: TimeInterval = 947_182_440
        let synodicMonth: TimeInterval = 29.530588853 * 86400.0
        let elapsed = date.timeIntervalSince1970 - refNewMoon
        var phase = (elapsed.truncatingRemainder(dividingBy: synodicMonth)) / synodicMonth
        if phase < 0 { phase += 1.0 }

        let illum = Int(((1.0 - cos(phase * 2.0 * .pi)) / 2.0 * 100.0).rounded())
        switch phase {
        case 0.0..<0.0625, 0.9375...1.0:
            return (L10n.localized(.menuBarMoonPhaseNew), "moonphase.new.moon", illum)
        case 0.0625..<0.1875:
            return (L10n.localized(.menuBarMoonPhaseWaxingCrescent), "moonphase.waxing.crescent", illum)
        case 0.1875..<0.3125:
            return (L10n.localized(.menuBarMoonPhaseFirstQuarter), "moonphase.first.quarter", illum)
        case 0.3125..<0.4375:
            return (L10n.localized(.menuBarMoonPhaseWaxingGibbous), "moonphase.waxing.gibbous", illum)
        case 0.4375..<0.5625:
            return (L10n.localized(.menuBarMoonPhaseFull), "moonphase.full.moon", illum)
        case 0.5625..<0.6875:
            return (L10n.localized(.menuBarMoonPhaseWaningGibbous), "moonphase.waning.gibbous", illum)
        case 0.6875..<0.8125:
            return (L10n.localized(.menuBarMoonPhaseLastQuarter), "moonphase.last.quarter", illum)
        default:
            return (L10n.localized(.menuBarMoonPhaseWaningCrescent), "moonphase.waning.crescent", illum)
        }
    }

    var body: some View {
        let _ = appConfig.appearanceMode
        let _ = appConfig.themePreset
        let refMonth = displayedMonthDate
        let headerFmt: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "LLLL yyyy"
            return f
        }()
        let selFmt: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd EEEE"
            return f
        }()
        let cal = Calendar.current
        let weekOfYear = cal.component(.weekOfYear, from: selectedDate)
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: selectedDate) ?? 1
        let weeks = buildMonthGrid(for: refMonth)
        let lunar = lunarSummary(for: selectedDate)
        let moon = moonPhaseInfo(for: selectedDate)
        let isSelectedWeekend = cal.isDateInWeekend(selectedDate)

        return VStack(alignment: .leading, spacing: 6) {
            // 1. Calendar card with a colored header, weekday row, and adjacent-month dates
            VStack(spacing: 0) {
                // 顶部主题色通栏：月份标题 + 翻月/今天按钮 + 星期表头
                VStack(spacing: 6) {
                    HStack(alignment: .center) {
                        Text(headerFmt.string(from: refMonth))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Theme.onAccent)

                        Spacer()

                        HStack(spacing: 10) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.16)) {
                                    monthOffset -= 1
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.onAccent.opacity(0.92))
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help(L10n.localized(.menuBarCalendarPrevMonthHelp))

                            Button {
                                withAnimation(.easeInOut(duration: 0.16)) {
                                    monthOffset = 0
                                    selectedDate = Date()
                                }
                            } label: {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Theme.onAccent.opacity(0.92))
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help(L10n.localized(.menuBarCalendarTodayHelp))

                            Button {
                                withAnimation(.easeInOut(duration: 0.16)) {
                                    monthOffset += 1
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.onAccent.opacity(0.92))
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help(L10n.localized(.menuBarCalendarNextMonthHelp))
                        }
                    }

                    HStack(spacing: 0) {
                        ForEach(Array(orderedWeekdaySymbols.enumerated()), id: \.offset) { _, item in
                            Text(item.symbol)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(item.isWeekend ? Theme.onAccent.opacity(0.78) : Theme.onAccent)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 9)
                .padding(.bottom, 6)
                .background(
                    LinearGradient(
                        colors: [Theme.accent, Theme.accent2],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                // 日期矩阵：旧月份/新月份分区浅灰底色 + 休息日标识 + 底部圆点 + 点击选中
                VStack(spacing: 2) {
                    ForEach(0..<weeks.count, id: \.self) { rIdx in
                        let row = weeks[rIdx]
                        HStack(spacing: 2) {
                            ForEach(row) { cell in
                                let otherMonthBg = Theme.isDark
                                    ? Color.white.opacity(0.055)
                                    : Color.black.opacity(0.06)
                                Button {
                                    withAnimation(.easeInOut(duration: 0.14)) {
                                        selectedDate = cell.date
                                        if cell.isOtherMonth {
                                            let mDiff = cal.dateComponents([.month], from: refMonth, to: cell.date).month ?? 0
                                            if mDiff != 0 {
                                                monthOffset += mDiff
                                            }
                                        }
                                    }
                                } label: {
                                    VStack(spacing: 1.5) {
                                        Text("\(cell.dayNumber)")
                                            .font(.system(size: 11, weight: (cell.isToday || cell.isSelected) ? .bold : .medium, design: .rounded))
                                            .foregroundColor(
                                                cell.isToday
                                                    ? Theme.onAccent
                                                    : (cell.isOtherMonth
                                                        ? Theme.sub.opacity(0.58)
                                                        : (cell.isWeekend ? Theme.accent : Theme.text))
                                            )

                                        Circle()
                                            .fill(
                                                cell.hasMarkerDot
                                                    ? (cell.isToday ? Theme.onAccent : (cell.isWeekend ? Theme.accent.opacity(0.85) : Theme.accent2))
                                                    : Color.clear
                                            )
                                            .frame(width: 3.8, height: 3.8)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 29)
                                    .background(
                                        ZStack {
                                            if cell.isToday {
                                                Capsule()
                                                    .fill(Theme.accent)
                                                    .padding(.horizontal, 3)
                                                    .padding(.vertical, 1)
                                            } else if cell.isOtherMonth {
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .fill(otherMonthBg)
                                            }
                                            if cell.isSelected && !cell.isToday {
                                                Capsule()
                                                    .strokeBorder(Theme.accent, lineWidth: 1.3)
                                                    .padding(.horizontal, 3)
                                                    .padding(.vertical, 1)
                                            }
                                        }
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background(Theme.card)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Theme.sep, lineWidth: 0.8)
            )

            // 2. 选中日期详情：公历 + 农历/节日 + 工作日/休息日胶囊 + 周次
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(selFmt.string(from: selectedDate))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.text)
                            .lineLimit(1)
                        Spacer()
                        Text(isSelectedWeekend ? L10n.localized(.menuBarCalendarWeekendBadge) : L10n.localized(.menuBarCalendarWorkdayBadge))
                            .font(.system(size: 8.5, weight: .bold))
                            .padding(.horizontal, 5.5)
                            .padding(.vertical, 1.5)
                            .background(
                                Capsule().fill(isSelectedWeekend ? Theme.accent.opacity(0.18) : StatsTheme.boxBg)
                            )
                            .foregroundColor(isSelectedWeekend ? Theme.accent : Theme.sub)
                    }

                    HStack {
                        Text(lunar.full)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Theme.sub)
                        Spacer()
                        Text("\(L10n.format(.menuBarWeekNumberFormat, weekOfYear)) · D\(dayOfYear)")
                            .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Theme.accent)
                    }
                }
            }

            // 3. Moon phase and time-zone card
            ModernBentoCard(cornerRadius: 8, padding: 8) {
                HStack(spacing: 8) {
                    Image(systemName: moon.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.accent)
                        .frame(width: 22, height: 22)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(moon.name)
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Theme.text)
                        Text(L10n.format(.menuBarMoonIlluminationFormat, moon.illumination))
                            .font(.system(size: 8.5, design: .monospaced))
                            .foregroundColor(Theme.sub)
                    }

                    Spacer()

                    Label(TimeZone.current.identifier, systemImage: "globe")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(Theme.sub)
                        .lineLimit(1)
                }
            }
        }
    }
}
