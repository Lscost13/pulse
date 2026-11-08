//
//  Rows.swift
//  PULSE
//
//  Строки списков: задача, событие, привычка, фокус-сессия.
//

import SwiftUI

extension TaskPriority {
    var color: Color {
        switch self {
        case .low: return PulsePalette.inkTertiary
        case .normal: return PulsePalette.sky
        case .high: return PulsePalette.amber
        case .critical: return PulsePalette.danger
        }
    }
}

struct CategoryDot: View {
    var hex: String?
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(Color.category(hex))
            .frame(width: size, height: size)
    }
}

// MARK: - Задача

struct TaskRow: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router

    let task: TaskItem
    var showsDay: Bool = false
    var onOpen: (() -> Void)?

    private var accent: Color { store.settings.accent.color }
    private var category: TaskCategory? { store.category(with: task.categoryID) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PulseCheckbox(isOn: task.isCompleted, accent: accent, size: 23) {
                withAnimation(PulseMotion.smooth) {
                    store.toggleCompletion(task)
                }
            }
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(PulseFont.bodyMedium)
                    .foregroundStyle(task.isCompleted ? PulsePalette.inkTertiary : PulsePalette.ink)
                    .strikethrough(task.isCompleted, color: PulsePalette.inkTertiary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                metaRow

                if !task.subtasks.isEmpty {
                    subtaskProgress
                }
            }

            Spacer(minLength: 4)

            trailing
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            if let onOpen = onOpen {
                onOpen()
            } else {
                router.openTask(task)
            }
        }
        .contextMenu {
            Button {
                router.openTask(task)
            } label: {
                Label("Открыть", systemImage: "square.and.pencil")
            }
            Button {
                store.toggleCompletion(task)
            } label: {
                Label(task.isCompleted ? "Вернуть в работу" : "Завершить",
                      systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark.circle")
            }
            Button {
                store.move(task, to: Date().startOfDay().adding(days: 1))
            } label: {
                Label("Перенести на завтра", systemImage: "calendar.badge.clock")
            }
            Button {
                store.duplicate(task)
            } label: {
                Label("Дублировать", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive) {
                store.delete(task)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            if let due = task.dueDate {
                HStack(spacing: 3) {
                    Image(systemName: "clock")
                        .font(.system(size: 9.5, weight: .semibold))
                    Text(showsDay ? "\(due.dayNumber) \(due.monthShortName), \(due.timeString)" : due.timeString)
                        .font(PulseFont.caption)
                }
                .foregroundStyle(task.isOverdue ? PulsePalette.danger : PulsePalette.inkTertiary)
            }

            if task.duration > 0 {
                Text(PulseDate.durationShort(minutes: task.duration))
                    .font(PulseFont.caption)
                    .foregroundStyle(PulsePalette.inkTertiary)
            }

            if let category = category {
                HStack(spacing: 4) {
                    CategoryDot(hex: category.colorHex, size: 6)
                    Text(category.name)
                        .font(PulseFont.caption)
                        .foregroundStyle(PulsePalette.inkTertiary)
                }
            }

            if task.recurrence != .never {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(PulsePalette.inkTertiary)
            }
        }
    }

    private var subtaskProgress: some View {
        HStack(spacing: 6) {
            PulseProgressBar(
                progress: task.subtaskProgress,
                tint: category.map { Color(hex: $0.colorHex) } ?? accent,
                height: 3
            )
            .frame(maxWidth: 90)
            Text("\(task.doneSubtasks)/\(task.subtasks.count)")
                .font(PulseFont.micro)
                .foregroundStyle(PulsePalette.inkTertiary)
        }
        .padding(.top, 1)
    }

    @ViewBuilder
    private var trailing: some View {
        if !task.isCompleted && task.priority.weight >= 2 {
            Image(systemName: task.priority == .critical ? "exclamationmark.2" : "arrow.up")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(task.priority.color)
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(task.priority.color.opacity(0.12), in: Capsule())
        } else if task.isCompleted {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(PulsePalette.success)
        }
    }
}

// MARK: - Событие

struct EventRow: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router

    let event: CalendarEvent
    var compact: Bool = false

    private var color: Color {
        Color.category(store.category(with: event.categoryID)?.colorHex)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.isAllDay ? "Весь день" : event.start.timeString)
                    .font(PulseFont.number(compact ? 12 : 13, .semibold))
                    .foregroundStyle(PulsePalette.ink)
                if !event.isAllDay {
                    Text(PulseDate.durationShort(minutes: event.durationMinutes))
                        .font(PulseFont.micro)
                        .foregroundStyle(PulsePalette.inkTertiary)
                }
            }
            .frame(width: 52, alignment: .leading)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 3)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(PulseFont.bodyMedium)
                    .foregroundStyle(PulsePalette.ink)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if !event.location.isEmpty {
                        MetaLabel(symbol: "mappin.and.ellipse", text: event.location)
                    }
                    if let category = store.category(with: event.categoryID) {
                        MetaLabel(symbol: "circle.fill", text: category.name)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, compact ? 8 : 10)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.tap()
            router.openEvent(event)
        }
        .contextMenu {
            Button {
                router.openEvent(event)
            } label: {
                Label("Изменить", systemImage: "square.and.pencil")
            }
            Button(role: .destructive) {
                store.deleteEvent(event)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }
}

// MARK: - Привычка

struct HabitRow: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router

    let habit: Habit
    var day: Date = Date()

    private var color: Color { Color(hex: habit.colorHex) }
    private var isDone: Bool { habit.isDone(on: day) }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(PulseMotion.bouncy) {
                    store.toggleHabit(habit, on: day)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(isDone ? AnyShapeStyle(color.opacity(0.18)) : AnyShapeStyle(PulsePalette.cardSunken))
                        .frame(width: 38, height: 38)
                    Circle()
                        .strokeBorder(isDone ? color : PulsePalette.stroke, lineWidth: 1.2)
                        .frame(width: 38, height: 38)
                    Image(systemName: isDone ? "checkmark" : habit.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDone ? color : PulsePalette.inkSecondary)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(PulseFont.bodyMedium)
                    .foregroundStyle(PulsePalette.ink)
                HStack(spacing: 8) {
                    Text(habit.kind == .daily ? "Каждый день" : "\(habit.completions(inWeekOf: day, calendar: store.calendar))/\(habit.targetPerWeek) в неделю")
                        .font(PulseFont.caption)
                        .foregroundStyle(PulsePalette.inkTertiary)
                    Text(streakText)
                        .font(PulseFont.micro)
                        .foregroundStyle(color)
                }
            }

            Spacer(minLength: 0)

            weekDots
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                router.openHabit(habit)
            } label: {
                Label("Изменить", systemImage: "square.and.pencil")
            }
            Button(role: .destructive) {
                store.deleteHabit(habit)
            } label: {
                Label("Удалить", systemImage: "trash")
            }
        }
    }

    private var weekDots: some View {
        let days = PulseDate.week(of: day, calendar: store.calendar)
        return HStack(spacing: 3) {
            ForEach(days, id: \.self) { item in
                let done = habit.isDone(on: item)
                Circle()
                    .fill(done ? color : PulsePalette.cardSunken)
                    .frame(width: 6, height: 6)
                    .overlay {
                        if item.isToday {
                            Circle().strokeBorder(PulsePalette.ink.opacity(0.3), lineWidth: 0.8)
                        }
                    }
            }
        }
    }

    private var streakText: String {
        var count = 0
        var cursor = day
        var guardLimit = 0
        while guardLimit < 400 {
            guardLimit += 1
            if habit.isDone(on: cursor) {
                count += 1
            } else if cursor.isToday {
                // сегодня ещё можно успеть — не обрываем
            } else {
                break
            }
            cursor = cursor.adding(days: -1)
        }
        return count > 0 ? "\(count) дн." : ""
    }
}

// MARK: - Фокус-сессия

struct SessionRow: View {
    let session: FocusSession
    var taskTitle: String?

    private var color: Color {
        session.isFocus ? PulsePalette.violetFallback : PulsePalette.sky
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: session.phase.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(taskTitle ?? session.phase.shortTitle)
                    .font(PulseFont.bodyMedium)
                    .foregroundStyle(PulsePalette.ink)
                    .lineLimit(1)
                Text("\(session.startedAt.dayMonthTitle) · \(session.startedAt.timeString)")
                    .font(PulseFont.caption)
                    .foregroundStyle(PulsePalette.inkTertiary)
            }

            Spacer(minLength: 0)

            Text(PulseDate.durationShort(minutes: session.minutes))
                .font(PulseFont.number(15, .semibold))
                .foregroundStyle(PulsePalette.inkSecondary)
        }
        .padding(.vertical, 8)
    }
}
