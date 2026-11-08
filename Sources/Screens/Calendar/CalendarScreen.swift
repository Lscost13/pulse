//
//  CalendarScreen.swift
//  PULSE
//
//  Календарь: месяц, неделя, день. Нагрузка дней, цветные категории,
//  свободные окна и перенос задач перетаскиванием.
//

import SwiftUI

struct CalendarScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var monthAnchor: Date = Date().startOfDay()

    private var accent: Color { store.settings.accent.color }

    var body: some View {
        ZStack {
            PulseBackground(accent: accent)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    modeSwitch

                    if horizontalSizeClass == .regular {
                        HStack(alignment: .top, spacing: 20) {
                            VStack(spacing: 16) {
                                calendarPane
                            }
                            .frame(maxWidth: .infinity)
                            VStack(spacing: 16) {
                                dayHeader
                                agendaCard
                                freeSlotsCard
                            }
                            .frame(width: 340)
                        }
                    } else {
                        calendarPane
                        dayHeader
                        agendaCard
                        freeSlotsCard
                    }
                }
                .padding(.horizontal, PulseMetrics.screenPadding)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
        .onAppear {
            monthAnchor = router.selectedDay
        }
    }

    // MARK: - Шапка

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("КАЛЕНДАРЬ")
                        .font(PulseFont.micro)
                        .tracking(1.2)
                        .foregroundStyle(PulsePalette.inkTertiary)
                    Text(periodTitle)
                        .font(PulseFont.displayM)
                        .foregroundStyle(PulsePalette.ink)
                        .contentTransition(.numericText())
                        .animation(PulseMotion.smooth, value: periodTitle)
                }

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    CircleIconButton(symbol: "chevron.left", size: 34) { shift(-1) }
                    Button {
                        Haptics.tap()
                        withAnimation(PulseMotion.smooth) {
                            router.selectedDay = store.today
                            monthAnchor = store.today
                        }
                    } label: {
                        Text("Сегодня")
                            .font(PulseFont.caption)
                            .foregroundStyle(PulsePalette.ink)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(PulsePalette.cardSunken, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    CircleIconButton(symbol: "chevron.right", size: 34) { shift(1) }
                }
            }

            Menu {
                Button {
                    router.openNewTask(day: router.selectedDay)
                } label: {
                    Label("Новая задача", systemImage: "checklist")
                }
                Button {
                    router.openNewEvent(day: router.selectedDay)
                } label: {
                    Label("Новое событие", systemImage: "calendar.badge.plus")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("Добавить на \(router.selectedDay.dayNumber) \(router.selectedDay.monthNameGenitive)")
                        .font(PulseFont.caption)
                }
                .foregroundStyle(PulsePalette.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(PulseGradient.accent(accent).opacity(0.14), in: Capsule())
                .overlay(Capsule().strokeBorder(accent.opacity(0.25), lineWidth: 1))
            }
        }
    }

    private var modeSwitch: some View {
        SegmentedPill(
            selection: Binding(
                get: { router.calendarMode },
                set: { newValue in
                    withAnimation(PulseMotion.smooth) {
                        router.calendarMode = newValue
                    }
                }
            ),
            items: CalendarMode.allCases,
            label: { $0.title },
            accent: accent
        )
    }

    private var periodTitle: String {
        switch router.calendarMode {
        case .month:
            return monthAnchor.monthYearTitle
        case .week:
            let days = PulseDate.week(of: router.selectedDay, calendar: store.calendar)
            guard let first = days.first, let last = days.last else {
                return router.selectedDay.monthYearTitle
            }
            if first.monthIndex == last.monthIndex {
                return "\(first.dayNumber)–\(last.dayNumber) \(last.monthNameGenitive)"
            }
            return "\(first.dayNumber) \(first.monthShortName) – \(last.dayNumber) \(last.monthShortName)"
        case .day:
            return router.selectedDay.longDateTitle
        }
    }

    private func shift(_ direction: Int) {
        Haptics.selection()
        withAnimation(PulseMotion.smooth) {
            switch router.calendarMode {
            case .month:
                let cal = store.calendar
                monthAnchor = cal.date(byAdding: .month, value: direction, to: monthAnchor) ?? monthAnchor
            case .week:
                router.selectedDay = router.selectedDay.adding(days: 7 * direction)
                monthAnchor = router.selectedDay
            case .day:
                router.selectedDay = router.selectedDay.adding(days: direction)
                monthAnchor = router.selectedDay
            }
        }
    }

    // MARK: - Панели

    @ViewBuilder
    private var calendarPane: some View {
        switch router.calendarMode {
        case .month:
            monthCard
        case .week:
            VStack(spacing: 14) {
                weekStrip
                timelineCard
            }
        case .day:
            timelineCard
        }
    }

    // MARK: - Месяц

    private var monthCard: some View {
        PulseCard(padding: 12) {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach(RuCal.weekdaysShort, id: \.self) { name in
                        Text(name)
                            .font(PulseFont.micro)
                            .foregroundStyle(PulsePalette.inkTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 2)

                let days = PulseDate.monthGrid(for: monthAnchor, calendar: store.calendar)
                let currentMonth = store.calendar.component(.month, from: monthAnchor)

                VStack(spacing: 4) {
                    ForEach(0..<6, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { column in
                                let index = row * 7 + column
                                if let day = days[safe: index] {
                                    monthCell(
                                        day: day,
                                        inMonth: store.calendar.component(.month, from: day) == currentMonth
                                    )
                                } else {
                                    Color.clear.frame(height: 54)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func monthCell(day: Date, inMonth: Bool) -> some View {
        let isSelected = day.isSameDay(as: router.selectedDay)
        let isToday = day.isToday
        let tasks = store.tasks(on: day)
        let events = store.events(on: day)
        let itemCount = tasks.count + events.count
        let load = store.loadRatio(for: day)

        let categories: [String] = {
            var hexes: [String] = []
            for task in tasks {
                let hex = store.colorHex(for: task.categoryID)
                if !hexes.contains(hex) { hexes.append(hex) }
                if hexes.count >= 3 { break }
            }
            for event in events {
                let hex = store.colorHex(for: event.categoryID)
                if !hexes.contains(hex) { hexes.append(hex) }
                if hexes.count >= 3 { break }
            }
            return hexes
        }()

        return VStack(spacing: 3) {
            ZStack {
                if isToday {
                    Circle()
                        .fill(accent)
                        .frame(width: 24, height: 24)
                }
                Text("\(day.dayNumber)")
                    .font(PulseFont.number(13, isSelected ? .bold : .medium))
                    .foregroundStyle(
                        isToday ? Color.white
                            : (inMonth ? (isSelected ? accent : PulsePalette.ink) : PulsePalette.inkTertiary.opacity(0.5))
                    )
            }
            .frame(height: 24)

            HStack(spacing: 2.5) {
                ForEach(Array(categories.enumerated()), id: \.offset) { _, hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 4.5, height: 4.5)
                }
            }
            .frame(height: 6)

            Capsule()
                .fill(load > 0 ? loadColor(load: load) : Color.clear)
                .frame(height: 2.5)
                .padding(.horizontal, 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? accent.opacity(0.12) : Color.clear)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? accent.opacity(0.35) : Color.clear, lineWidth: 1)
        }
        .opacity(inMonth ? 1 : 0.55)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture {
            Haptics.selection()
            withAnimation(PulseMotion.snappy) {
                router.selectedDay = day
            }
        }
        .dropDestination(for: String.self) { values, _ in
            guard let raw = values.first, let id = UUID(uuidString: raw),
                  let task = store.task(with: id) else { return false }
            withAnimation(PulseMotion.smooth) {
                store.move(task, to: day)
            }
            Haptics.success()
            return true
        }
        .accessibilityLabel("\(day.dayMonthTitle), элементов: \(itemCount)")
    }

    private func loadColor(load: Double) -> Color {
        if load < 0.15 { return PulsePalette.mint.opacity(0.7) }
        if load < 0.35 { return PulsePalette.sky.opacity(0.7) }
        if load < 0.6 { return PulsePalette.amber.opacity(0.8) }
        return PulsePalette.danger.opacity(0.8)
    }

    // MARK: - Неделя

    private var weekStrip: some View {
        let days = PulseDate.week(of: router.selectedDay, calendar: store.calendar)
        return PulseCard(padding: 10) {
            HStack(spacing: 4) {
                ForEach(days, id: \.self) { day in
                    let isSelected = day.isSameDay(as: router.selectedDay)
                    let load = store.loadRatio(for: day)
                    Button {
                        Haptics.selection()
                        withAnimation(PulseMotion.snappy) {
                            router.selectedDay = day
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(day.weekdayShort)
                                .font(PulseFont.micro)
                                .foregroundStyle(isSelected ? accent : PulsePalette.inkTertiary)
                            Text("\(day.dayNumber)")
                                .font(PulseFont.number(17, .bold))
                                .foregroundStyle(day.isToday ? Color.white : (isSelected ? accent : PulsePalette.ink))
                                .frame(width: 32, height: 32)
                                .background {
                                    Circle()
                                        .fill(day.isToday ? accent : (isSelected ? accent.opacity(0.12) : Color.clear))
                                }
                            Capsule()
                                .fill(load > 0 ? loadColor(load: load) : Color.clear)
                                .frame(width: 14, height: 2.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .dropDestination(for: String.self) { values, _ in
                        guard let raw = values.first, let id = UUID(uuidString: raw),
                              let task = store.task(with: id) else { return false }
                        withAnimation(PulseMotion.smooth) {
                            store.move(task, to: day)
                        }
                        Haptics.success()
                        return true
                    }
                }
            }
        }
    }

    private var timelineCard: some View {
        let blocks = store.blocks(on: router.selectedDay)
        return PulseCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(router.selectedDay.weekdayFull), \(router.selectedDay.dayMonthTitle)")
                        .font(PulseFont.subheadline)
                        .foregroundStyle(PulsePalette.ink)
                    Spacer()
                    CounterPill(value: blocks.count, title: "блоков")
                }

                if blocks.isEmpty {
                    EmptyState(
                        symbol: "calendar",
                        title: "День свободен",
                        subtitle: "Перетащи задачу сюда или добавь событие.",
                        actionTitle: "Добавить задачу",
                        action: { router.openNewTask(day: router.selectedDay) }
                    )
                } else {
                    DayTimeline(
                        blocks: blocks,
                        day: router.selectedDay,
                        startHour: 7,
                        endHour: 23,
                        hourHeight: 54,
                        showsNow: true,
                        onTap: { block in
                            if block.kind == .task, let task = store.task(with: block.id) {
                                router.openTask(task)
                            } else if let event = store.events.first(where: { $0.id == block.id }) {
                                router.openEvent(event)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - День: заголовок

    private var dayHeader: some View {
        let day = router.selectedDay
        let tasks = store.tasks(on: day)
        let open = tasks.filter { !$0.isCompleted }
        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.isToday ? "СЕГОДНЯ" : day.weekdayFull.uppercased())
                    .font(PulseFont.micro)
                    .tracking(1)
                    .foregroundStyle(PulsePalette.inkTertiary)
                Text(day.dayMonthTitle)
                    .font(PulseFont.title)
                    .foregroundStyle(PulsePalette.ink)
            }
            Spacer()
            HStack(spacing: 6) {
                TagPill(text: "\(open.count) задач", tint: accent)
                TagPill(text: store.dayLoad(for: day).title, tint: PulsePalette.inkSecondary)
            }
        }
    }

    // MARK: - Агенда дня

    private var agendaCard: some View {
        let day = router.selectedDay
        let events = store.events(on: day)
        let timedTasks = store.tasks(on: day).filter { $0.dueDate != nil }
        let untimed = store.tasks(on: day).filter { $0.dueDate == nil }

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Агенда")
                    .font(PulseFont.headline)
                    .foregroundStyle(PulsePalette.ink)
                Spacer()
                Button {
                    router.openNewEvent(day: day)
                } label: {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PulsePalette.inkSecondary)
                        .frame(width: 30, height: 30)
                        .background(PulsePalette.cardSunken, in: Circle())
                }
                .buttonStyle(.plain)
            }

            PulseCard(padding: 6) {
                if events.isEmpty && timedTasks.isEmpty && untimed.isEmpty {
                    EmptyState(
                        symbol: "calendar.badge.plus",
                        title: "На этот день ничего нет",
                        subtitle: "Добавь событие или задачу — и день оживёт.",
                        actionTitle: "Добавить задачу",
                        action: { router.openNewTask(day: day) }
                    )
                } else {
                    VStack(spacing: 0) {
                        if !events.isEmpty {
                            groupLabel("СОБЫТИЯ")
                            ForEach(events) { event in
                                EventRow(event: event)
                                    .padding(.horizontal, 10)
                            }
                        }
                        if !timedTasks.isEmpty {
                            groupLabel("ЗАДАЧИ")
                            ForEach(Array(timedTasks.enumerated()), id: \.element.id) { index, task in
                                if index > 0 { PulseDivider(inset: 40) }
                                TaskRow(task: task)
                                    .padding(.horizontal, 10)
                                    .draggable(task.id.uuidString)
                            }
                        }
                        if !untimed.isEmpty {
                            groupLabel("БЕЗ ВРЕМЕНИ")
                            ForEach(Array(untimed.enumerated()), id: \.element.id) { index, task in
                                if index > 0 { PulseDivider(inset: 40) }
                                TaskRow(task: task)
                                    .padding(.horizontal, 10)
                                    .draggable(task.id.uuidString)
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
    }

    private func groupLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(PulseFont.micro)
                .tracking(0.8)
                .foregroundStyle(PulsePalette.inkTertiary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 2)
    }

    // MARK: - Свободные окна

    @ViewBuilder
    private var freeSlotsCard: some View {
        let slots = store.freeSlots(on: router.selectedDay, minimumMinutes: 30)
        if !slots.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Свободные окна")
                        .font(PulseFont.headline)
                        .foregroundStyle(PulsePalette.ink)
                    Spacer()
                    Text("\(slots.count)")
                        .font(PulseFont.micro)
                        .foregroundStyle(PulsePalette.inkTertiary)
                }

                PulseCard(padding: 6) {
                    VStack(spacing: 0) {
                        ForEach(Array(slots.prefix(4).enumerated()), id: \.offset) { index, slot in
                            if index > 0 { PulseDivider(inset: 12) }
                            HStack(spacing: 10) {
                                Image(systemName: "circle.dashed")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(PulsePalette.inkTertiary)
                                Text("\(slot.start.timeString) – \(slot.end.timeString)")
                                    .font(PulseFont.caption)
                                    .foregroundStyle(PulsePalette.ink)
                                Text(PulseDate.durationShort(minutes: PulseDate.minutesBetween(slot.start, slot.end)))
                                    .font(PulseFont.micro)
                                    .foregroundStyle(PulsePalette.inkTertiary)
                                Spacer()
                                Button {
                                    Haptics.tap()
                                    router.openNewTask(day: router.selectedDay, start: max(slot.start, Date()))
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(accent)
                                        .frame(width: 26, height: 26)
                                        .background(accent.opacity(0.12), in: Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                        }
                    }
                }
            }
        }
    }
}
