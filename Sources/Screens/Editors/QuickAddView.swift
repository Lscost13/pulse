//
//  QuickAddView.swift
//  PULSE
//
//  Быстрое добавление: одно поле, пара решений — и задача в плане.
//

import SwiftUI

struct QuickAddView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var day: Date?
    @State private var time: Date?
    @State private var priority: TaskPriority = .normal

    @FocusState private var focused: Bool

    private var accent: Color { store.settings.accent.color }

    private var canAdd: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Новая задача")
                    .font(PulseFont.headline)
                    .foregroundStyle(PulsePalette.ink)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(PulsePalette.inkTertiary)
                        .frame(width: 28, height: 28)
                        .background(PulsePalette.cardSunken, in: Circle())
                }
                .buttonStyle(.plain)
            }

            TextField("Что нужно сделать?", text: $title, axis: .vertical)
                .font(PulseFont.rounded(24, .semibold))
                .foregroundStyle(PulsePalette.ink)
                .lineLimit(1...3)
                .focused($focused)
                .submitLabel(.done)

            PulseDivider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    dayChip("Сегодня", value: store.today)
                    dayChip("Завтра", value: store.today.adding(days: 1))
                    dayChip("Послезавтра", value: store.today.adding(days: 2))
                    dayChip("Без даты", value: nil)
                }
            }
            .scrollIndicators(.hidden)

            if day != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(hourOptions, id: \.self) { hour in
                            let isSelected = time?.hour == hour
                            Button {
                                Haptics.selection()
                                withAnimation(PulseMotion.snappy) {
                                    time = (day ?? store.today).combiningTime(hour: hour, minute: 0)
                                }
                            } label: {
                                Text(PulseDate.timeText(hour: hour))
                                    .font(PulseFont.caption)
                                    .foregroundStyle(isSelected ? Color.white : PulsePalette.inkSecondary)
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule().fill(isSelected
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

            HStack(spacing: 6) {
                ForEach(TaskPriority.allCases) { item in
                    let isSelected = priority == item
                    Button {
                        Haptics.selection()
                        withAnimation(PulseMotion.snappy) { priority = item }
                    } label: {
                        HStack(spacing: 4) {
                            Text(item.glyph)
                                .font(PulseFont.number(11, .bold))
                            Text(item.title)
                                .font(.system(size: 10.5, weight: .medium))
                        }
                        .foregroundStyle(isSelected ? Color.white : item.color)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(isSelected ? item.color : item.color.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            Spacer(minLength: 4)

            HStack(spacing: 10) {
                Button {
                    Haptics.tap()
                    openFullEditor()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PulsePalette.inkSecondary)
                        .frame(width: 50, height: 50)
                        .background(PulsePalette.cardSunken, in: Circle())
                }
                .buttonStyle(.plain)

                Button {
                    add()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                        Text("Добавить")
                            .font(PulseFont.headline)
                    }
                }
                .buttonStyle(PulsePrimaryButtonStyle(accent: accent))
                .disabled(!canAdd)
                .opacity(canAdd ? 1 : 0.5)
            }
        }
        .padding(.horizontal, PulseMetrics.screenPadding)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .onAppear {
            focused = true
        }
    }

    private var hourOptions: [Int] {
        [8, 10, 12, 14, 16, 18, 20, 21]
    }

    private func dayChip(_ label: String, value: Date?) -> some View {
        let isSelected: Bool = {
            if let value = value, let day = day {
                return day.isSameDay(as: value)
            }
            return value == nil && day == nil
        }()

        return Button {
            Haptics.selection()
            withAnimation(PulseMotion.snappy) {
                day = value
                if value == nil {
                    time = nil
                } else if time == nil {
                    time = value?.combiningTime(hour: 10, minute: 0)
                }
            }
        } label: {
            Text(label)
                .font(PulseFont.caption)
                .foregroundStyle(isSelected ? Color.white : PulsePalette.inkSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(isSelected
                                   ? AnyShapeStyle(PulseGradient.accent(accent))
                                   : AnyShapeStyle(PulsePalette.cardSunken))
                )
        }
        .buttonStyle(.plain)
    }

    private func add() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var task = TaskItem()
        task.title = trimmed
        task.priority = priority
        task.duration = 30
        if let day = day {
            task.dueDate = time ?? day.combiningTime(hour: 10, minute: 0)
        } else {
            task.dueDate = nil
        }
        store.add(task)
        Haptics.success()
        dismiss()
    }

    private func openFullEditor() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        var draft = TaskItem()
        draft.title = trimmed
        draft.dueDate = day.map { time ?? $0.combiningTime(hour: 10, minute: 0) }
        draft.priority = priority
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            router.taskEditor = TaskEditorRequest(
                task: nil,
                day: day,
                suggestedStart: draft.dueDate
            )
        }
    }
}
