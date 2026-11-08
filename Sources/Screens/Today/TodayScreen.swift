//
//  TodayScreen.swift
//  PULSE
//
//  Главный экран: состояние дня одним взглядом — прогресс, задачи,
//  ближайшее событие, свободное время, привычки и серия.
//

import SwiftUI

struct TodayScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var accent: Color { store.settings.accent.color }

    var body: some View {
        ZStack {
            PulseBackground(accent: store.settings.accent.color)

            ScrollView(showsIndicators: false) {
                if horizontalSizeClass == .regular {
                    wideLayout
                } else {
                    compactLayout
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Разметка

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: PulseMetrics.sectionSpacing) {
            header.pulseAppear(0)
            heroCard.pulseAppear(1)
            reviewCard.pulseAppear(2)
            agendaCard.pulseAppear(3)
            tasksCard.pulseAppear(3)
            freeTimeCard.pulseAppear(4)
            streakCard.pulseAppear(5)
            scheduleCard.pulseAppear(6)
        }
        .padding(.horizontal, PulseMetrics.screenPadding)
        .padding(.top, 6)
        .padding(.bottom, 110)
    }

    private var wideLayout: some View {
        VStack(alignment: .leading, spacing: PulseMetrics.sectionSpacing) {
            header.pulseAppear(0)
            HStack(alignment: .top, spacing: 20) {
                VStack(spacing: PulseMetrics.sectionSpacing) {
                    heroCard.pulseAppear(1)
                    reviewCard.pulseAppear(2)
                    tasksCard.pulseAppear(3)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: PulseMetrics.sectionSpacing) {
                    agendaCard.pulseAppear(2)
                    freeTimeCard.pulseAppear(4)
                    streakCard.pulseAppear(5)
                }
                .frame(maxWidth: .infinity)
            }
            scheduleCard.pulseAppear(6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 60)
    }

    // MARK: - Шапка

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(overlineText)
                    .font(PulseFont.micro)
                    .tracking(1.2)
                    .foregroundStyle(PulsePalette.inkTertiary)

                Text(PulseGreeting.text(name: store.settings.userName))
                    .font(PulseFont.displayM)
                    .foregroundStyle(PulsePalette.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                streakPill
                CircleIconButton(symbol: "gearshape.fill", size: 38) {
                    router.showSettings = true
                }
            }
        }
        .padding(.top, 8)
    }

    private var overlineText: String {
        let today = Date()
        return "\(today.weekdayFull.uppercased()) · \(today.dayNumber) \(today.monthNameGenitive.uppercased())"
    }

    private var streakPill: some View {
        Button {
            Haptics.tap()
            router.showStreak = true
        } label: {
            HStack(spacing: 5) {
                FlameView(size: 17, intensity: store.streak.current > 0 ? 1 : 0.3, isActive: store.streak.current > 0)
                Text("\(store.streak.current)")
                    .font(PulseFont.number(14, .bold))
                    .foregroundStyle(PulsePalette.ink)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(PulsePalette.card, in: Capsule())
            .overlay(Capsule().strokeBorder(PulsePalette.stroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Серия: \(store.streak.current) дней")
    }

    // MARK: - Прогресс дня

    private var heroCard: some View {
        let accent = store.settings.accent.color
        let progress = store.todayProgress
        let total = store.todayTasks.count
        let done = store.todayCompletedCount

        return PulseCard(padding: 20, tint: accent) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("ПРОГРЕСС ДНЯ")
                        .font(PulseFont.micro)
                        .tracking(1.1)
                        .foregroundStyle(PulsePalette.inkTertiary)
                    Spacer()
                    TagPill(
                        text: store.dayLoad(for: store.today).title,
                        tint: loadTint,
                        filled: false
                    )
                }

                HStack(alignment: .center, spacing: 18) {
                    ZStack {
                        PulseGradient.accentGlow(accent)
                            .frame(width: 190, height: 190)
                            .blur(radius: 18)
                        ProgressRing(progress: progress, lineWidth: 13, accent: accent)
                            .frame(width: 126, height: 126)
                        VStack(spacing: 1) {
                            Text("\(Int((progress * 100).rounded()))%")
                                .font(PulseFont.number(32, .bold))
                                .foregroundStyle(PulsePalette.ink)
                                .contentTransition(.numericText())
                            Text("готово")
                                .font(PulseFont.micro)
                                .foregroundStyle(PulsePalette.inkTertiary)
                        }
                    }
                    .frame(width: 136, height: 136)

                    VStack(spacing: 14) {
                        StatTile(
                            value: "\(done)/\(total)",
                            title: "задачи",
                            symbol: "checklist",
                            tint: PulsePalette.ink
                        )
                        StatTile(
                            value: PulseDate.durationShort(minutes: store.focusMinutesToday),
                            title: "фокус",
                            symbol: "timer",
                            tint: accent
                        )
                        StatTile(
                            value: PulseDate.durationShort(minutes: store.freeMinutesToday),
                            title: "свободно",
                            symbol: "wind",
                            tint: PulsePalette.mint
                        )
                    }
                }

                HStack(spacing: 10) {
                    Text("Цель дня")
                        .font(PulseFont.caption)
                        .foregroundStyle(PulsePalette.inkSecondary)
                    PulseProgressBar(
                        progress: store.settings.dailyGoalMinutes > 0
                            ? Double(store.focusMinutesToday) / Double(store.settings.dailyGoalMinutes)
                            : 0,
                        tint: accent,
                        height: 6
                    )
                    Text("\(store.focusMinutesToday)/\(store.settings.dailyGoalMinutes) мин")
                        .font(PulseFont.micro)
                        .foregroundStyle(PulsePalette.inkTertiary)
                }
            }
        }
    }

    private var loadTint: Color {
        switch store.dayLoad(for: store.today) {
        case .empty: return PulsePalette.inkTertiary
        case .light: return PulsePalette.mint
        case .medium: return PulsePalette.sky
        case .busy: return PulsePalette.amber
        case .overloaded: return PulsePalette.danger
        }
    }

    // MARK: - Итоги дня

    private var reviewCard: some View {
        let today = store.today
        let reflection = store.reflection(for: today)
        let hasText = !(reflection?.text.isEmpty ?? true)
        let scoreColor: Color = {
            guard let value = reflection?.score else { return accent }
            switch value {
            case 0..<35: return PulsePalette.danger
            case 35..<60: return PulsePalette.amber
            case 60..<80: return PulsePalette.sky
            default: return PulsePalette.mint
            }
        }()

        return Button {
            Haptics.tap()
            router.openReview(day: today)
        } label: {
            PulseCard(padding: 14, tint: reflection == nil ? accent : scoreColor) {
                HStack(spacing: 14) {
                    ScoreDial(
                        score: reflection?.score ?? 0,
                        size: 62,
                        lineWidth: 7,
                        accent: scoreColor,
                        showsNumber: true,
                        showsWord: false
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(reflection == nil ? "Как прошёл день?" : "Итоги дня")
                                .font(PulseFont.subheadline)
                                .foregroundStyle(PulsePalette.ink)
                            if let word = reflection?.word, !word.isEmpty {
                                TagPill(text: word, tint: scoreColor)
                            }
                        }
                        Text(hasText ? (reflection?.text ?? "") : (reflection == nil
                             ? "Оценка 0–100 и мысль дня"
                             : "Добавь мысль дня"))
                            .font(PulseFont.caption)
                            .foregroundStyle(PulsePalette.inkTertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(PulsePalette.inkTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ближайшее событие

    @ViewBuilder
    private var agendaCard: some View {
        if let current = store.currentEvent {
            eventCard(event: current, headline: "СЕЙЧАС ИДЁТ")
                .overlay(alignment: .topTrailing) {
                    LiveDot()
                        .padding(14)
                }
        } else if let next = store.nextEvent {
            eventCard(event: next, headline: "ДАЛЕЕ")
        } else {
            PulseCard {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(PulsePalette.cardSunken)
                            .frame(width: 40, height: 40)
                        Image(systemName: "moon.zzz")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("До конца дня событий нет")
                            .font(PulseFont.subheadline)
                            .foregroundStyle(PulsePalette.ink)
                        Text("Свободное время — тоже план")
                            .font(PulseFont.caption)
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }
                    Spacer()
                }
            }
        }
    }

    private func eventCard(event: CalendarEvent, headline: String) -> some View {
        let color = Color.category(store.category(with: event.categoryID)?.colorHex)
        let isOngoing = event.start <= Date()
        let total = max(1, event.durationMinutes)
        let elapsed = min(max(0, PulseDate.minutesBetween(event.start, Date())), total)

        return PulseCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(headline)
                        .font(PulseFont.micro)
                        .tracking(1.1)
                        .foregroundStyle(PulsePalette.inkTertiary)
                    Spacer()
                    if !isOngoing {
                        Text(countdownText(to: event.start))
                            .font(PulseFont.caption)
                            .foregroundStyle(color)
                    }
                }

                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(color)
                        .frame(width: 4, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(PulseFont.headline)
                            .foregroundStyle(PulsePalette.ink)
                            .lineLimit(1)
                        HStack(spacing: 10) {
                            MetaLabel(
                                symbol: "clock",
                                text: "\(event.start.timeString)–\(event.end.timeString)"
                            )
                            if !event.location.isEmpty {
                                MetaLabel(symbol: "mappin.and.ellipse", text: event.location)
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    Button {
                        Haptics.tap()
                        router.openEvent(event)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(PulsePalette.inkTertiary)
                            .frame(width: 30, height: 30)
                            .background(PulsePalette.cardSunken, in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                if isOngoing {
                    PulseProgressBar(
                        progress: Double(elapsed) / Double(total),
                        tint: color,
                        height: 4
                    )
                }
            }
        }
    }

    private func countdownText(to date: Date) -> String {
        let minutes = PulseDate.minutesBetween(Date(), date)
        if minutes <= 0 { return "сейчас" }
        if minutes < 60 { return "через \(minutes) мин" }
        let hours = minutes / 60
        let rest = minutes % 60
        if rest == 0 { return "через \(hours) ч" }
        return "через \(hours) ч \(rest) мин"
    }

    // MARK: - Задачи

    private var tasksCard: some View {
        let tasks = store.todayTasks
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Задачи на сегодня",
                subtitle: tasks.isEmpty ? nil : "\(store.todayCompletedCount) из \(tasks.count) готово",
                actionTitle: tasks.isEmpty ? nil : "Все",
                action: {
                    router.showTasks(.today)
                }
            )

            PulseCard(padding: 6) {
                if tasks.isEmpty {
                    EmptyState(
                        symbol: "checkmark.circle",
                        title: "День свободен",
                        subtitle: "Добавь первую задачу — начни с самого важного.",
                        actionTitle: "Добавить задачу",
                        action: {
                            router.openNewTask(day: store.today)
                        }
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(tasks.prefix(6).enumerated()), id: \.element.id) { index, task in
                            if index > 0 {
                                PulseDivider(inset: 40)
                            }
                            TaskRow(task: task)
                                .padding(.horizontal, 10)
                        }
                        if tasks.count > 6 {
                            PulseDivider(inset: 40)
                            Button {
                                router.showTasks(.today)
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Ещё \(tasks.count - 6)")
                                        .font(PulseFont.caption)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .foregroundStyle(PulsePalette.inkSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if !tasks.isEmpty {
                Button {
                    Haptics.tap()
                    router.openNewTask(day: store.today)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                        Text("Добавить задачу")
                            .font(PulseFont.caption)
                    }
                    .foregroundStyle(PulsePalette.inkSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(PulsePalette.cardSunken, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.leading, 2)
            }
        }
    }

    // MARK: - Свободное время

    @ViewBuilder
    private var freeTimeCard: some View {
        let free = store.freeMinutesToday
        if free >= 20 {
            PulseCard(padding: 16, tint: PulsePalette.mint) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(PulsePalette.mint.opacity(0.14))
                            .frame(width: 42, height: 42)
                        Image(systemName: "wind")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(PulsePalette.mint)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Свободного времени: \(PulseDate.durationShort(minutes: free))")
                            .font(PulseFont.subheadline)
                            .foregroundStyle(PulsePalette.ink)
                        Text("До \(PulseDate.timeText(hour: store.workdayEndHour)) — можно закрыть пару задач")
                            .font(PulseFont.caption)
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }

                    Spacer(minLength: 0)

                    Button {
                        Haptics.tap()
                        if let slot = store.suggestedSlot(for: 30, on: store.today) {
                            router.openNewTask(day: slot, start: slot)
                        } else {
                            router.openNewTask(day: store.today)
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 32, height: 32)
                            .background(PulseGradient.accent(PulsePalette.mint), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Серия и привычки

    private var streakCard: some View {
        let streak = store.streak
        let habits = store.activeHabits
        let accent = store.settings.accent.color

        return PulseCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    FlameView(
                        size: 40,
                        intensity: streak.current > 0 ? 1 : 0.35,
                        isActive: streak.current > 0
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(streak.current > 0 ? "\(streak.current) дней подряд" : "Начни серию сегодня")
                            .font(PulseFont.headline)
                            .foregroundStyle(PulsePalette.ink)
                        Text(streakSubtitle(streak))
                            .font(PulseFont.caption)
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }

                    Spacer(minLength: 0)

                    Button {
                        Haptics.tap()
                        router.showStreak = true
                    } label: {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(PulsePalette.inkSecondary)
                            .frame(width: 30, height: 30)
                            .background(PulsePalette.cardSunken, in: Circle())
                    }
                    .buttonStyle(.plain)
                }

                if !habits.isEmpty {
                    PulseDivider()
                    VStack(spacing: 2) {
                        ForEach(habits.prefix(3)) { habit in
                            HabitRow(habit: habit, day: store.today)
                        }
                    }
                } else {
                    Button {
                        router.openNewHabit()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                            Text("Добавить первую привычку")
                                .font(PulseFont.caption)
                        }
                        .foregroundStyle(accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func streakSubtitle(_ streak: StreakStats) -> String {
        if streak.isRestDay {
            return "День отдыха — серия сохранится"
        }
        if streak.isAtRisk {
            return "Ещё ничего не сделано сегодня"
        }
        let habitsDone = store.habitsDone(on: store.today)
        let total = store.activeHabits.count
        if total > 0 {
            return "Привычки: \(habitsDone) из \(total)"
        }
        return "Лучшая серия: \(streak.longest) дн."
    }

    // MARK: - Расписание

    private var scheduleCard: some View {
        let blocks = store.blocks(on: store.today)
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Расписание",
                subtitle: blocks.isEmpty ? nil : "\(blocks.count) блоков в дне",
                actionTitle: "Календарь",
                action: {
                    router.goToDay(store.today, tab: .calendar)
                }
            )

            PulseCard(padding: 14) {
                if blocks.isEmpty {
                    EmptyState(
                        symbol: "calendar",
                        title: "Пока пусто",
                        subtitle: "События и задачи с временем появятся здесь."
                    )
                } else {
                    VStack(spacing: 10) {
                        ForEach(blocks) { block in
                            scheduleRow(block)
                        }
                    }
                }
            }
        }
    }

    private func scheduleRow(_ block: TimeBlock) -> some View {
        let color = Color.category(block.colorHex)
        let isNow = block.start <= Date() && block.end > Date()

        return HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(block.start.timeString)
                    .font(PulseFont.number(12, .semibold))
                    .foregroundStyle(isNow ? color : PulsePalette.inkSecondary)
                Text(block.end.timeString)
                    .font(PulseFont.micro)
                    .foregroundStyle(PulsePalette.inkTertiary.opacity(0.7))
            }
            .frame(width: 44, alignment: .trailing)

            VStack(spacing: 2) {
                Capsule()
                    .fill(color)
                    .frame(width: 3, height: 16)
                Capsule()
                    .fill(color.opacity(0.18))
                    .frame(width: 3)
            }
            .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 2) {
                Text(block.title)
                    .font(PulseFont.bodyMedium)
                    .foregroundStyle(block.isDone ? PulsePalette.inkTertiary : PulsePalette.ink)
                    .strikethrough(block.isDone, color: PulsePalette.inkTertiary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(block.kind == .event ? "Событие" : "Задача")
                        .font(PulseFont.micro)
                        .foregroundStyle(PulsePalette.inkTertiary)
                    if isNow {
                        Text("· сейчас")
                            .font(PulseFont.micro)
                            .foregroundStyle(color)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            if block.kind == .task, let task = store.task(with: block.id) {
                router.openTask(task)
            } else if let event = store.events.first(where: { $0.id == block.id }) {
                router.openEvent(event)
            }
        }
    }
}

// MARK: - Пульсирующая точка «сейчас»

struct LiveDot: View {
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(PulsePalette.danger.opacity(0.25))
                .frame(width: 16, height: 16)
                .scaleEffect(pulsing ? 1.25 : 0.8)
                .opacity(pulsing ? 0.2 : 0.9)
            Circle()
                .fill(PulsePalette.danger)
                .frame(width: 6, height: 6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulsing = true
            }
        }
        .accessibilityHidden(true)
    }
}
