//
//  TaskEditorView.swift
//  PULSE
//
//  Полный редактор задачи: время, приоритет, категория, подзадачи,
//  напоминание и повторение.
//

import SwiftUI

struct TaskEditorView: View {
    let request: TaskEditorRequest

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var notes: String
    @State private var hasDate: Bool
    @State private var date: Date
    @State private var duration: Int
    @State private var priority: TaskPriority
    @State private var categoryID: UUID?
    @State private var subtasks: [Subtask]
    @State private var hasReminder: Bool
    @State private var reminderDate: Date
    @State private var recurrence: Recurrence
    @State private var newSubtaskTitle: String = ""
    @State private var showDeleteConfirm: Bool = false
    @State private var isCompleted: Bool

    @FocusState private var titleFocused: Bool

    init(request: TaskEditorRequest) {
        self.request = request
        let existing = request.task
        let start = existing?.dueDate ?? request.suggestedStart ?? request.day?.combiningTime(hour: 10, minute: 0) ?? Date().roundedToHalfHour()
        _title = State(initialValue: existing?.title ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
        _hasDate = State(initialValue: existing?.dueDate != nil || request.day != nil || request.suggestedStart != nil)
        _date = State(initialValue: start)
        _duration = State(initialValue: existing?.duration ?? 30)
        _priority = State(initialValue: existing?.priority ?? .normal)
        _categoryID = State(initialValue: existing?.categoryID)
        _subtasks = State(initialValue: existing?.subtasks ?? [])
        _hasReminder = State(initialValue: existing?.reminderDate != nil)
        _reminderDate = State(initialValue: existing?.reminderDate ?? start.addingTimeInterval(-900))
        _recurrence = State(initialValue: existing?.recurrence ?? .never)
        _isCompleted = State(initialValue: existing?.isCompleted ?? false)
    }

    private var accent: Color { store.settings.accent.color }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            PulseBackground(accent: accent)

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        titleBlock
                        timeBlock
                        priorityBlock
                        categoryBlock
                        subtasksBlock
                        reminderBlock
                        notesBlock
                        if request.task != nil {
                            dangerBlock
                        }
                    }
                    .padding(.horizontal, PulseMetrics.screenPadding)
                    .padding(.vertical, 16)
                    .padding(.bottom, 100)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear {
            if request.task == nil {
                titleFocused = true
            }
        }
        .confirmationDialog("Удалить задачу?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                if let task = request.task {
                    store.delete(task)
                }
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    // MARK: - Шапка

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Text("Отмена")
                        .font(PulseFont.subheadline)
                        .foregroundStyle(PulsePalette.inkSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(request.isNew ? "Новая задача" : "Задача")
                    .font(PulseFont.headline)
                    .foregroundStyle(PulsePalette.ink)

                Spacer()

                Button {
                    save()
                } label: {
                    Text("Готово")
                        .font(PulseFont.headline)
                        .foregroundStyle(canSave ? accent : PulsePalette.inkTertiary)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.6)
            }
            .padding(.horizontal, PulseMetrics.screenPadding)
            .padding(.top, 18)
            .padding(.bottom, 12)

            PulseDivider()
        }
    }

    // MARK: - Поля

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Что нужно сделать?", text: $title, axis: .vertical)
                .font(PulseFont.rounded(26, .semibold))
                .foregroundStyle(PulsePalette.ink)
                .lineLimit(1...4)
                .focused($titleFocused)
                .submitLabel(.done)

            HStack(spacing: 10) {
                Button {
                    withAnimation(PulseMotion.bouncy) {
                        isCompleted.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 13, weight: .semibold))
                        Text(isCompleted ? "Выполнено" : "Отметить выполненной")
                            .font(PulseFont.caption)
                    }
                    .foregroundStyle(isCompleted ? PulsePalette.success : PulsePalette.inkTertiary)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(.vertical, 6)
    }

    private var timeBlock: some View {
        EditorCard(title: "Когда", symbol: "calendar") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $hasDate) {
                    Text("Запланировать")
                        .font(PulseFont.subheadline)
                        .foregroundStyle(PulsePalette.ink)
                }
                .tint(accent)

                if hasDate {
                    HStack(spacing: 8) {
                        quickDayChip("Сегодня", day: store.today)
                        quickDayChip("Завтра", day: store.today.adding(days: 1))
                        quickDayChip("Пн", day: nextWeekday(2))
                        Spacer()
                    }

                    DatePicker(
                        "Дата и время",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .font(PulseFont.caption)
                    .tint(accent)
                    .labelsHidden()
                    .datePickerStyle(.compact)

                    if !hasDateSlot {
                        Button {
                            Haptics.tap()
                            if let slot = store.suggestedSlot(for: duration, on: date) {
                                date = slot
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Подобрать свободное окно")
                                    .font(PulseFont.caption)
                            }
                            .foregroundStyle(accent)
                        }
                        .buttonStyle(.plain)
                    }
                }

                PulseDivider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Длительность")
                        .font(PulseFont.caption)
                        .foregroundStyle(PulsePalette.inkTertiary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach([15, 25, 30, 45, 60, 90, 120], id: \.self) { value in
                                Button {
                                    Haptics.selection()
                                    withAnimation(PulseMotion.snappy) { duration = value }
                                } label: {
                                    Text(PulseDate.durationShort(minutes: value))
                                        .font(PulseFont.caption)
                                        .foregroundStyle(duration == value ? Color.white : PulsePalette.inkSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(
                                            Capsule().fill(duration == value
                                                           ? AnyShapeStyle(PulseGradient.accent(accent))
                                                           : AnyShapeStyle(PulsePalette.cardSunken))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }

                PulseDivider()

                Menu {
                    ForEach(Recurrence.allCases) { item in
                        Button {
                            recurrence = item
                        } label: {
                            if recurrence == item {
                                Label(item.title, systemImage: "checkmark")
                            } else {
                                Text(item.title)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Повторение")
                            .font(PulseFont.subheadline)
                            .foregroundStyle(PulsePalette.ink)
                        Spacer()
                        Text(recurrence.shortTitle)
                            .font(PulseFont.caption)
                            .foregroundStyle(PulsePalette.inkSecondary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }
                }
            }
        }
    }

    private var hasDateSlot: Bool {
        let start = date
        let end = date.addingTimeInterval(Double(duration) * 60)
        return !store.busyIntervals(on: start, from: start, to: end).isEmpty
    }

    private func nextWeekday(_ weekday: Int) -> Date {
        var candidate = store.today.adding(days: 1)
        var counter = 0
        while store.calendar.component(.weekday, from: candidate) != weekday && counter < 7 {
            candidate = candidate.adding(days: 1)
            counter += 1
        }
        return candidate
    }

    private func quickDayChip(_ title: String, day: Date) -> some View {
        let isSelected = date.isSameDay(as: day)
        return Button {
            Haptics.selection()
            withAnimation(PulseMotion.snappy) {
                date = day.combiningTime(hour: date.hour, minute: date.minute)
            }
        } label: {
            Text(title)
                .font(PulseFont.caption)
                .foregroundStyle(isSelected ? accent : PulsePalette.inkSecondary)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? accent.opacity(0.14) : PulsePalette.cardSunken)
                )
        }
        .buttonStyle(.plain)
    }

    private var priorityBlock: some View {
        EditorCard(title: "Приоритет", symbol: "flag") {
            HStack(spacing: 7) {
                ForEach(TaskPriority.allCases) { item in
                    let isSelected = priority == item
                    Button {
                        Haptics.selection()
                        withAnimation(PulseMotion.snappy) { priority = item }
                    } label: {
                        VStack(spacing: 3) {
                            Text(item.glyph)
                                .font(PulseFont.number(13, .bold))
                            Text(item.title)
                                .font(.system(size: 9.5, weight: .medium))
                        }
                        .foregroundStyle(isSelected ? Color.white : item.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(isSelected
                                      ? AnyShapeStyle(item.color)
                                      : AnyShapeStyle(item.color.opacity(0.10)))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var categoryBlock: some View {
        EditorCard(title: "Категория", symbol: "square.grid.2x2") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    Button {
                        Haptics.selection()
                        withAnimation(PulseMotion.snappy) { categoryID = nil }
                    } label: {
                        Text("Без категории")
                            .font(PulseFont.caption)
                            .foregroundStyle(categoryID == nil ? PulsePalette.ink : PulsePalette.inkTertiary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(categoryID == nil ? PulsePalette.card : Color.clear))
                            .overlay(Capsule().strokeBorder(PulsePalette.stroke, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    ForEach(store.categories) { category in
                        let isSelected = categoryID == category.id
                        Button {
                            Haptics.selection()
                            withAnimation(PulseMotion.snappy) { categoryID = category.id }
                        } label: {
                            HStack(spacing: 5) {
                                CategoryDot(hex: category.colorHex, size: 6)
                                Text(category.name)
                                    .font(PulseFont.caption)
                                    .foregroundStyle(isSelected ? PulsePalette.ink : PulsePalette.inkSecondary)
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(
                                Capsule().fill(isSelected ? Color(category.colorHex).opacity(0.14) : PulsePalette.cardSunken)
                            )
                            .overlay(Capsule().strokeBorder(
                                isSelected ? Color(category.colorHex).opacity(0.4) : Color.clear,
                                lineWidth: 1
                            ))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var subtasksBlock: some View {
        EditorCard(title: "Подзадачи", symbol: "list.bullet") {
            VStack(spacing: 8) {
                ForEach(subtasks) { subtask in
                    HStack(spacing: 9) {
                        Button {
                            Haptics.selection()
                            withAnimation(PulseMotion.snappy) {
                                if let position = subtasks.firstIndex(where: { $0.id == subtask.id }) {
                                    subtasks[position].isDone.toggle()
                                }
                            }
                        } label: {
                            Image(systemName: subtask.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(subtask.isDone ? accent : PulsePalette.inkTertiary)
                        }
                        .buttonStyle(.plain)

                        Text(subtask.title)
                            .font(PulseFont.callout)
                            .foregroundStyle(subtask.isDone ? PulsePalette.inkTertiary : PulsePalette.ink)
                            .strikethrough(subtask.isDone, color: PulsePalette.inkTertiary)

                        Spacer()

                        Button {
                            withAnimation(PulseMotion.snappy) {
                                subtasks.removeAll { $0.id == subtask.id }
                            }
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(PulsePalette.inkTertiary.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(PulsePalette.inkTertiary)
                    TextField("Добавить шаг", text: $newSubtaskTitle)
                        .font(PulseFont.callout)
                        .foregroundStyle(PulsePalette.ink)
                        .submitLabel(.done)
                        .onSubmit(addSubtask)
                    if !newSubtaskTitle.isEmpty {
                        Button {
                            addSubtask()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(PulseMotion.snappy) {
            subtasks.append(Subtask(title: trimmed, isDone: false))
        }
        newSubtaskTitle = ""
        Haptics.soft()
    }

    private var reminderBlock: some View {
        EditorCard(title: "Напоминание", symbol: "bell") {
            VStack(spacing: 10) {
                Toggle(isOn: $hasReminder) {
                    Text("Напомнить")
                        .font(PulseFont.subheadline)
                        .foregroundStyle(PulsePalette.ink)
                }
                .tint(accent)

                if hasReminder {
                    DatePicker(
                        "Время напоминания",
                        selection: $reminderDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .font(PulseFont.caption)
                    .tint(accent)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
            }
        }
    }

    private var notesBlock: some View {
        EditorCard(title: "Заметка", symbol: "text.alignleft") {
            TextField("Детали, ссылки, мысли…", text: $notes, axis: .vertical)
                .font(PulseFont.callout)
                .foregroundStyle(PulsePalette.ink)
                .lineLimit(3...8)
        }
    }

    private var dangerBlock: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                Text("Удалить задачу")
                    .font(PulseFont.subheadline)
            }
            .foregroundStyle(PulsePalette.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(PulsePalette.danger.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Сохранение

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var task = request.task ?? TaskItem()
        task.title = trimmed
        task.notes = notes
        task.dueDate = hasDate ? date : nil
        task.duration = duration
        task.priority = priority
        task.categoryID = categoryID
        task.subtasks = subtasks.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
        task.reminderDate = hasReminder ? reminderDate : nil
        task.recurrence = recurrence

        if isCompleted != (request.task?.isCompleted ?? false) {
            task.isCompleted = isCompleted
            task.completedAt = isCompleted ? Date() : nil
        }

        if request.task == nil {
            store.add(task)
        } else {
            store.update(task)
        }
        Haptics.success()
        dismiss()
    }
}

// MARK: - Карточка редактора

struct EditorCard<Content: View>: View {
    let title: String
    let symbol: String
    let content: Content

    init(title: String, symbol: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbol = symbol
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
                Text(title.uppercased())
                    .font(PulseFont.micro)
                    .tracking(0.9)
            }
            .foregroundStyle(PulsePalette.inkTertiary)

            content
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(PulsePalette.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(PulsePalette.stroke, lineWidth: 1)
                )
        }
    }
}
