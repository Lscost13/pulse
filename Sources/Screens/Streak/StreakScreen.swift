//
//  StreakScreen.swift
//  PULSE
//
//  Серия дней и привычки. Принцип: поддерживать, а не наказывать —
//  дни отдыха и восстановление серии встроены в механику.
//

import SwiftUI

struct StreakScreen: View {
    var isModal: Bool = false

    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var calendarMonth: Date = Date().startOfDay()

    private var accent: Color { store.settings.accent.color }
    private var streak: StreakStats { store.streak }

    var body: some View {
        ZStack {
            PulseBackground(accent: accent)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    heroCard
                    if streak.isAtRisk || streak.rescueableDay != nil {
                        rescueCard
                    }
                    achievementsSection
                    calendarSection
                    habitsSection
                    restDaysSection
                }
                .padding(.horizontal, PulseMetrics.screenPadding)
                .padding(.top, isModal ? 18 : 10)
                .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Шапка

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("СЕРИЯ")
                    .font(PulseFont.micro)
                    .tracking(1.2)
                    .foregroundStyle(PulsePalette.inkTertiary)
                Text("Твой импульс")
                    .font(PulseFont.displayM)
                    .foregroundStyle(PulsePalette.ink)
            }
            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Button {
                    Haptics.tap()
                    router.openNewHabit()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PulsePalette.inkSecondary)
                        .frame(width: 38, height: 38)
                        .background(PulsePalette.cardSunken, in: Circle())
                }
                .buttonStyle(.plain)

                if isModal {
                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(PulsePalette.inkSecondary)
                            .frame(width: 38, height: 38)
                            .background(PulsePalette.cardSunken, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Герой

    private var heroCard: some View {
        PulseCard(padding: 24, tint: PulsePalette.blush) {
            VStack(spacing: 16) {
                ZStack {
                    PulseGradient.accentGlow(PulsePalette.blush)
                        .frame(width: 260, height: 260)
                        .blur(radius: 24)
                        .opacity(streak.current > 0 ? 1 : 0.3)

                    FlameView(
                        size: 96,
                        intensity: streak.current > 0 ? 1 : 0.3,
                        isActive: streak.current > 0
                    )
                }
                .frame(height: 130)

                VStack(spacing: 2) {
                    Text("\(streak.current)")
                        .font(PulseFont.number(64, .bold))
                        .foregroundStyle(PulsePalette.ink)
                        .contentTransition(.numericText())
                    Text(streak.current == 1 ? "день подряд" : "дней подряд")
                        .font(PulseFont.subheadline)
                        .foregroundStyle(PulsePalette.inkSecondary)
                }

                Text(heroSubtitle)
                    .font(PulseFont.caption)
                    .foregroundStyle(PulsePalette.inkTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 0) {
                    heroStat(value: "\(streak.longest)", title: "рекорд")
                    divider
                    heroStat(value: "\(streak.activeDays.count)", title: "дней в ритме")
                    divider
                    heroStat(value: "\(store.habitsDone(on: store.today))/\(store.activeHabits.count)", title: "привычки")
                }
                .padding(.top, 4)
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(PulsePalette.divider)
            .frame(width: 1, height: 26)
    }

    private func heroStat(value: String, title: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(PulseFont.number(17, .bold))
                .foregroundStyle(PulsePalette.ink)
            Text(title)
                .font(PulseFont.micro)
                .foregroundStyle(PulsePalette.inkTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var heroSubtitle: String {
        if streak.isRestDay {
            return "Сегодня день отдыха. Серия не прервётся — отдых тоже часть системы."
        }
        if streak.current == 0 {
            return "Серия начинается с одного дня. Закрой задачу или отметь привычку — и огонь загорится."
        }
        if streak.isAtRisk {
            return "Ещё ничего не сделано сегодня. Одна привычка — и день засчитан."
        }
        return "Лучшая серия: \(streak.longest) дн. Держи ритм, но помни про отдых."
    }

    // MARK: - Спасение серии

    @ViewBuilder
    private var rescueCard: some View {
        PulseCard(padding: 16, tint: PulsePalette.amber) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(PulsePalette.amber)
                    Text(streak.isAtRisk ? "Серия под угрозой" : "Серия прервалась")
                        .font(PulseFont.subheadline)
                        .foregroundStyle(PulsePalette.ink)
                    Spacer()
                }

                Text(streak.isAtRisk
                     ? "Отметь любую привычку или заверши задачу, чтобы день засчитался."
                     : "Можно восстановить один пропущенный день — без драмы.")
                    .font(PulseFont.caption)
                    .foregroundStyle(PulsePalette.inkTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    if streak.isAtRisk {
                        Button {
                            Haptics.tap()
                            router.showTasks(.today)
                            if isModal { dismiss() }
                        } label: {
                            Text("К задачам дня")
                        }
                        .buttonStyle(PulsePrimaryButtonStyle(accent: accent, fullWidth: false))
                    }
                    if let day = streak.rescueableDay {
                        Button {
                            store.repairStreak(day: day)
                        } label: {
                            Text("Восстановить \(day.dayMonthTitle)")
                        }
                        .buttonStyle(PulseSecondaryButtonStyle(fullWidth: false))
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Достижения

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Достижения",
                subtitle: "\(store.unlockedAchievements.count) из \(store.achievements.count) открыто"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.achievements) { achievement in
                        AchievementBadge(
                            achievement: achievement,
                            accent: accent,
                            progress: Double(max(streak.current, streak.longest)) / Double(max(1, achievement.threshold))
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Календарь серии

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Календарь серии")
                    .font(PulseFont.headline)
                    .foregroundStyle(PulsePalette.ink)
                Spacer()
                HStack(spacing: 4) {
                    CircleIconButton(symbol: "chevron.left", size: 30) {
                        withAnimation(PulseMotion.snappy) {
                            calendarMonth = store.calendar.date(byAdding: .month, value: -1, to: calendarMonth) ?? calendarMonth
                        }
                    }
                    Text(calendarMonth.monthName + " " + String(calendarMonth.yearNumber))
                        .font(PulseFont.caption)
                        .foregroundStyle(PulsePalette.inkSecondary)
                        .frame(width: 96)
                    CircleIconButton(symbol: "chevron.right", size: 30) {
                        withAnimation(PulseMotion.snappy) {
                            calendarMonth = store.calendar.date(byAdding: .month, value: 1, to: calendarMonth) ?? calendarMonth
                        }
                    }
                }
            }

            PulseCard(padding: 14) {
                StreakCalendar(
                    activeDays: streak.activeDays,
                    repairedDays: streak.repairedDays,
                    restWeekdays: store.settings.restWeekdays,
                    accent: accent,
                    month: calendarMonth
                )
            }
        }
    }

    // MARK: - Привычки

    private var habitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Привычки",
                subtitle: "\(store.habitsDone(on: store.today)) из \(store.activeHabits.count) сегодня",
                actionTitle: "Добавить",
                action: { router.openNewHabit() }
            )

            PulseCard(padding: 6) {
                if store.activeHabits.isEmpty {
                    EmptyState(
                        symbol: "leaf",
                        title: "Пока нет привычек",
                        subtitle: "Начни с одной: зарядка, чтение или стакан воды.",
                        actionTitle: "Добавить привычку",
                        action: { router.openNewHabit() }
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(store.activeHabits.enumerated()), id: \.element.id) { index, habit in
                            if index > 0 { PulseDivider(inset: 50) }
                            HabitRow(habit: habit, day: store.today)
                                .padding(.horizontal, 10)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - Дни отдыха

    private var restDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Дни отдыха", subtitle: "Серия не прервётся")

            PulseCard(padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { index in
                            let weekdayNumber = index == 6 ? 1 : index + 2
                            let isOn = store.settings.restWeekdays.contains(weekdayNumber)
                            Button {
                                Haptics.selection()
                                withAnimation(PulseMotion.snappy) {
                                    store.updateSettings { settings in
                                        if settings.restWeekdays.contains(weekdayNumber) {
                                            settings.restWeekdays.removeAll { $0 == weekdayNumber }
                                        } else {
                                            settings.restWeekdays.append(weekdayNumber)
                                        }
                                    }
                                }
                            } label: {
                                Text(RuCal.weekdaysShort[index])
                                    .font(PulseFont.caption)
                                    .foregroundStyle(isOn ? Color.white : PulsePalette.inkSecondary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background {
                                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                                            .fill(isOn
                                                  ? AnyShapeStyle(PulseGradient.accent(accent))
                                                  : AnyShapeStyle(PulsePalette.cardSunken))
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("В выбранные дни серия сохраняется, даже если ты ничего не сделал.")
                        .font(PulseFont.caption)
                        .foregroundStyle(PulsePalette.inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Бейдж достижения

struct AchievementBadge: View {
    let achievement: Achievement
    var accent: Color
    var progress: Double

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? AnyShapeStyle(PulseGradient.accent(accent))
                          : AnyShapeStyle(PulsePalette.cardSunken))
                    .frame(width: 58, height: 58)
                    .overlay {
                        Circle()
                            .strokeBorder(
                                achievement.isUnlocked ? accent.opacity(0) : PulsePalette.stroke,
                                lineWidth: 1
                            )
                    }

                Image(systemName: achievement.isUnlocked ? achievement.symbol : "lock.fill")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(achievement.isUnlocked ? Color.white : PulsePalette.inkTertiary)

                if achievement.isUnlocked {
                    Circle()
                        .fill(PulsePalette.success)
                        .frame(width: 14, height: 14)
                        .overlay {
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(Color.white)
                        }
                        .offset(x: 21, y: 21)
                }
            }

            Text("\(achievement.threshold)")
                .font(PulseFont.number(13, .bold))
                .foregroundStyle(achievement.isUnlocked ? accent : PulsePalette.inkTertiary)
            Text(achievement.title)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(PulsePalette.inkTertiary)
                .lineLimit(1)
                .frame(width: 72)
        }
        .frame(width: 78)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(PulsePalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    achievement.isUnlocked ? accent.opacity(0.25) : PulsePalette.stroke,
                    lineWidth: 1
                )
        )
        .opacity(achievement.isUnlocked ? 1 : 0.75)
    }
}
