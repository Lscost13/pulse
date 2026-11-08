//
//  InsightsScreen.swift
//  PULSE
//
//  Аналитика: динамика выполнения, распределение по категориям,
//  план против факта, тепловая карта и личные рекорды.
//

import SwiftUI

struct InsightsScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var range: StatsRange = .week

    private var accent: Color { store.settings.accent.color }

    var body: some View {
        ZStack {
            PulseBackground(accent: accent)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    rangeSwitch
                    heroCard
                    if horizontalSizeClass == .regular {
                        HStack(alignment: .top, spacing: 20) {
                            VStack(spacing: 18) {
                                dynamicCard
                                categoriesCard
                                heatmapCard
                            }
                            .frame(maxWidth: .infinity)
                            VStack(spacing: 18) {
                                planVsFactCard
                                weekdayCard
                                recordsCard
                            }
                            .frame(width: 340)
                        }
                    } else {
                        dynamicCard
                        categoriesCard
                        planVsFactCard
                        weekdayCard
                        heatmapCard
                        recordsCard
                    }
                }
                .padding(.horizontal, PulseMetrics.screenPadding)
                .padding(.top, 10)
                .padding(.bottom, 120)
            }
        }
    }

    // MARK: - Данные

    private var snapshot: StatsSnapshot {
        store.stats(days: range.days)
    }

    // MARK: - Шапка

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("АНАЛИТИКА")
                .font(PulseFont.micro)
                .tracking(1.2)
                .foregroundStyle(PulsePalette.inkTertiary)
            Text("Твой ритм")
                .font(PulseFont.displayM)
                .foregroundStyle(PulsePalette.ink)
        }
        .padding(.top, 6)
    }

    private var rangeSwitch: some View {
        SegmentedPill(
            selection: Binding(
                get: { range },
                set: { newValue in
                    withAnimation(PulseMotion.smooth) { range = newValue }
                }
            ),
            items: StatsRange.allCases,
            label: { $0.title },
            accent: accent
        )
    }

    // MARK: - Главная карточка

    private var heroCard: some View {
        let stats = snapshot
        return PulseCard(padding: 20, tint: accent) {
            VStack(spacing: 18) {
                HStack(alignment: .center, spacing: 18) {
                    ZStack {
                        ProgressRing(progress: stats.completionRate, lineWidth: 12, accent: accent)
                            .frame(width: 104, height: 104)
                        VStack(spacing: 0) {
                            Text("\(Int((stats.completionRate * 100).rounded()))%")
                                .font(PulseFont.number(26, .bold))
                                .foregroundStyle(PulsePalette.ink)
                                .contentTransition(.numericText())
                            Text("выполнено")
                                .font(PulseFont.micro)
                                .foregroundStyle(PulsePalette.inkTertiary)
                        }
                    }

                    VStack(spacing: 12) {
                        StatTile(
                            value: "\(stats.completed)",
                            title: "задач закрыто",
                            symbol: "checkmark.circle",
                            tint: PulsePalette.ink
                        )
                        StatTile(
                            value: PulseDate.durationShort(minutes: stats.focusMinutes),
                            title: "в фокусе",
                            symbol: "timer",
                            tint: accent
                        )
                    }
                }

                PulseDivider()

                HStack {
                    StatTile(value: "\(stats.overdue)", title: "просрочено", tint: PulsePalette.danger)
                    StatTile(value: String(format: "%.1f", stats.averagePerDay), title: "в день", tint: PulsePalette.inkSecondary)
                    StatTile(value: PulseDate.durationShort(minutes: stats.plannedMinutes), title: "в плане", tint: PulsePalette.sky)
                }
            }
        }
    }

    // MARK: - Динамика

    private var dynamicCard: some View {
        let points = barPoints
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Динамика",
                subtitle: range == .year ? "По месяцам" : "Выполненные задачи"
            )

            PulseCard(padding: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    InsightBarChart(points: points, accent: accent, height: 150)

                    HStack(spacing: 14) {
                        legendDot(color: accent, text: "выполнено")
                        legendDot(color: PulsePalette.sky.opacity(0.55), text: "в плане")
                        Spacer()
                        Text("\(snapshot.completed) / \(snapshot.created)")
                            .font(PulseFont.micro)
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }
                }
            }
        }
    }

    private func legendDot(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(PulseFont.micro)
                .foregroundStyle(PulsePalette.inkTertiary)
        }
    }

    private var barPoints: [BarPoint] {
        let days = snapshot.days
        switch range {
        case .week:
            return days.map { day in
                BarPoint(
                    label: day.day.weekdayShort,
                    value: Double(day.completed),
                    secondary: Double(day.planned)
                )
            }
        case .month:
            return days.map { day in
                BarPoint(
                    label: day.day.dayNumber % 5 == 0 ? "\(day.day.dayNumber)" : "",
                    value: Double(day.completed),
                    secondary: Double(day.planned)
                )
            }
        case .year:
            var buckets: [Int: (done: Int, planned: Int)] = [:]
            for day in days {
                let month = day.day.monthIndex
                var entry = buckets[month] ?? (0, 0)
                entry.done += day.completed
                entry.planned += day.planned
                buckets[month] = entry
            }
            return (0..<12).map { month in
                let entry = buckets[month] ?? (0, 0)
                return BarPoint(
                    label: String(RuCal.monthsShort[month].prefix(1)).uppercased(),
                    value: Double(entry.done),
                    secondary: Double(entry.planned)
                )
            }
        }
    }

    // MARK: - Категории

    private var categoriesCard: some View {
        let stats = snapshot
        let segments = stats.categories.map {
            DonutSegment(
                id: $0.id,
                label: $0.name,
                value: Double(max(1, $0.minutes)),
                color: Color(hex: $0.colorHex),
                detail: "\($0.tasks) задач"
            )
        }
        let total = stats.categories.reduce(0) { $0 + $1.minutes }

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Категории", subtitle: total > 0 ? "\(PulseDate.durationShort(minutes: total)) в работе" : nil)

            PulseCard(padding: 16) {
                if segments.isEmpty {
                    EmptyState(
                        symbol: "chart.pie",
                        title: "Нет данных",
                        subtitle: "Заверши несколько задач, чтобы увидеть распределение."
                    )
                } else {
                    HStack(spacing: 18) {
                        DonutChart(segments: segments, lineWidth: 16)
                            .frame(width: 116, height: 116)

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(segments.prefix(5)) { segment in
                                HStack(spacing: 7) {
                                    Circle()
                                        .fill(segment.color)
                                        .frame(width: 7, height: 7)
                                    Text(segment.label)
                                        .font(PulseFont.caption)
                                        .foregroundStyle(PulsePalette.ink)
                                        .lineLimit(1)
                                    Spacer(minLength: 4)
                                    Text(segment.detail)
                                        .font(PulseFont.micro)
                                        .foregroundStyle(PulsePalette.inkTertiary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - План и факт

    private var planVsFactCard: some View {
        let days = Array(snapshot.days.suffix(range == .week ? 7 : 14))
        let maxValue = max(
            1,
            days.map { max($0.plannedMinutes, $0.actualMinutes) }.max() ?? 1
        )
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "План и факт", subtitle: "Минуты по дням")

            PulseCard(padding: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(days) { day in
                            VStack(spacing: 3) {
                                HStack(alignment: .bottom, spacing: 2) {
                                    Capsule()
                                        .fill(PulsePalette.sky.opacity(0.4))
                                        .frame(width: 5, height: barHeight(day.plannedMinutes, max: maxValue))
                                    Capsule()
                                        .fill(accent)
                                        .frame(width: 5, height: barHeight(day.actualMinutes, max: maxValue))
                                }
                                Text(day.day.weekdayShort)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(PulsePalette.inkTertiary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 96, alignment: .bottom)

                    HStack(spacing: 12) {
                        legendDot(color: PulsePalette.sky.opacity(0.5), text: "план")
                        legendDot(color: accent, text: "факт")
                        Spacer()
                    }
                }
            }
        }
    }

    private func barHeight(_ value: Int, max maxValue: Int) -> CGFloat {
        let ratio = Double(value) / Double(maxValue)
        let height = max(value > 0 ? 3.0 : 0.0, 78.0 * ratio)
        return CGFloat(height)
    }

    // MARK: - Продуктивные дни

    private var weekdayCard: some View {
        var sums = Array(repeating: 0, count: 7)
        for day in snapshot.days {
            let index = day.day.ruWeekdayIndex
            if index >= 0 && index < 7 {
                sums[index] += day.completed
            }
        }
        let maxValue = max(1, sums.max() ?? 1)
        let best = sums.firstIndex(of: sums.max() ?? 0) ?? 0

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Лучшие дни", subtitle: best < 7 ? RuCal.weekdaysFull[best] : nil)

            PulseCard(padding: 16) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        VStack(spacing: 6) {
                            Text("\(sums[index])")
                                .font(PulseFont.micro)
                                .foregroundStyle(index == best ? accent : PulsePalette.inkTertiary)
                            Capsule()
                                .fill(index == best ? AnyShapeStyle(PulseGradient.accent(accent)) : AnyShapeStyle(PulsePalette.cardSunken))
                                .frame(height: max(6, CGFloat(60.0 * Double(sums[index]) / Double(maxValue))))
                            Text(RuCal.weekdaysShort[index])
                                .font(.system(size: 8.5, weight: .medium))
                                .foregroundStyle(PulsePalette.inkTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 96, alignment: .bottom)
            }
        }
    }

    // MARK: - Тепловая карта

    private var heatmapCard: some View {
        let cells = StatsEngine.heatmap(
            weeks: 16,
            tasks: store.tasks,
            sessions: store.sessions,
            calendar: store.calendar
        )
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Активность", subtitle: "Последние 16 недель")

            PulseCard(padding: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    HeatmapView(cells: cells, accent: accent, cellSize: 12, spacing: 4)

                    HStack(spacing: 5) {
                        Text("меньше")
                            .font(PulseFont.micro)
                            .foregroundStyle(PulsePalette.inkTertiary)
                        ForEach(0..<5, id: \.self) { level in
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(level == 0 ? PulsePalette.cardSunken : accent.opacity(0.2 + Double(level) * 0.2))
                                .frame(width: 9, height: 9)
                        }
                        Text("больше")
                            .font(PulseFont.micro)
                            .foregroundStyle(PulsePalette.inkTertiary)
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Рекорды

    private var recordsCard: some View {
        let stats = snapshot
        let streak = store.streak
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Рекорды")

            VStack(spacing: 10) {
                recordRow(
                    symbol: "flame.fill",
                    tint: PulsePalette.blush,
                    title: "Лучшая серия",
                    value: "\(streak.longest) дн."
                )
                recordRow(
                    symbol: "calendar.badge.clock",
                    tint: accent,
                    title: "Лучший день",
                    value: bestDayText(stats)
                )
                recordRow(
                    symbol: "hourglass",
                    tint: PulsePalette.mint,
                    title: "Часы концентрации",
                    value: PulseDate.durationShort(minutes: totalFocusMinutes)
                )
                recordRow(
                    symbol: "target",
                    tint: PulsePalette.sky,
                    title: "Средний процент",
                    value: "\(Int((stats.completionRate * 100).rounded()))%"
                )
            }
        }
    }

    private var totalFocusMinutes: Int {
        store.sessions.filter { $0.isFocus && $0.completed }.reduce(0) { $0 + $1.minutes }
    }

    private func bestDayText(_ stats: StatsSnapshot) -> String {
        guard let day = stats.bestDay, day.completed > 0 else { return "—" }
        return "\(day.day.dayMonthTitle) · \(day.completed)"
    }

    private func recordRow(symbol: String, tint: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(PulseFont.caption)
                .foregroundStyle(PulsePalette.inkSecondary)
            Spacer()
            Text(value)
                .font(PulseFont.number(14, .bold))
                .foregroundStyle(PulsePalette.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(PulsePalette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(PulsePalette.stroke, lineWidth: 1)
        )
    }
}

// MARK: - Точка графика

struct BarPoint: Identifiable, Hashable {
    var id: UUID = UUID()
    var label: String
    var value: Double
    var secondary: Double = 0
}

// MARK: - Столбчатый график

struct InsightBarChart: View {
    let points: [BarPoint]
    var accent: Color
    var height: CGFloat = 140

    private var maxValue: Double {
        max(1, points.map { max($0.value, $0.secondary) }.max() ?? 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(points) { point in
                VStack(spacing: 5) {
                    ZStack(alignment: .bottom) {
                        Capsule()
                            .fill(PulsePalette.sky.opacity(0.18))
                            .frame(width: 4)
                        Capsule()
                            .fill(PulseGradient.accent(accent))
                            .frame(width: 8, height: barHeight(point.value))
                    }
                    .frame(height: height - 16, alignment: .bottom)

                    Text(point.label)
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(PulsePalette.inkTertiary)
                        .lineLimit(1)
                        .frame(height: 10)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height)
    }

    private func barHeight(_ value: Double) -> CGFloat {
        let available = height - 22
        let ratio = value / maxValue
        return max(value > 0 ? 4 : 2, available * CGFloat(ratio))
    }
}

// MARK: - Донат

struct DonutSegment: Identifiable, Hashable {
    var id: UUID
    var label: String
    var value: Double
    var color: Color
    var detail: String
}

struct DonutChart: View {
    let segments: [DonutSegment]
    var lineWidth: CGFloat = 16

    private var total: Double {
        max(1, segments.reduce(0) { $0 + $1.value })
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(PulsePalette.cardSunken, lineWidth: lineWidth)

            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                let start = segments.prefix(index).reduce(0.0) { $0 + $1.value } / total
                let end = start + segment.value / total

                Circle()
                    .trim(from: start, to: max(start + 0.004, end - 0.006))
                    .stroke(
                        segment.color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(lineWidth / 2)
    }
}
