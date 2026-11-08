//
//  EventEditorView.swift
//  PULSE
//

import SwiftUI

struct EventEditorView: View {
    let request: EventEditorRequest

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var location: String
    @State private var notes: String
    @State private var date: Date
    @State private var startTime: Date
    @State private var durationMinutes: Int
    @State private var isAllDay: Bool
    @State private var categoryID: UUID?
    @State private var showDeleteConfirm: Bool = false

    @FocusState private var titleFocused: Bool

    init(request: EventEditorRequest) {
        self.request = request
        let existing = request.event
        let base = existing?.start ?? request.day.combiningTime(hour: 12, minute: 0)
        _title = State(initialValue: existing?.title ?? "")
        _location = State(initialValue: existing?.location ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
        _date = State(initialValue: base)
        _startTime = State(initialValue: base)
        _durationMinutes = State(initialValue: existing?.durationMinutes ?? 60)
        _isAllDay = State(initialValue: existing?.isAllDay ?? false)
        _categoryID = State(initialValue: existing?.categoryID)
    }

    private var accent: Color { store.settings.accent.color }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var start: Date {
        let day = date.startOfDay(calendar: store.calendar)
        if isAllDay {
            return day.combiningTime(hour: 0, minute: 0, calendar: store.calendar)
        }
        let hour = store.calendar.component(.hour, from: startTime)
        let minute = store.calendar.component(.minute, from: startTime)
        return day.combiningTime(hour: hour, minute: minute, calendar: store.calendar)
    }

    private var end: Date {
        isAllDay
            ? start.addingTimeInterval(86400)
            : start.addingTimeInterval(Double(durationMinutes) * 60)
    }

    var body: some View {
        ZStack {
            PulseBackground(accent: accent)

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        TextField("Название события", text: $title, axis: .vertical)
                            .font(PulseFont.rounded(26, .semibold))
                            .foregroundStyle(PulsePalette.ink)
                            .lineLimit(1...3)
                            .focused($titleFocused)
                            .padding(.vertical, 6)

                        EditorCard(title: "Когда", symbol: "clock") {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $isAllDay) {
                                    Text("Весь день")
                                        .font(PulseFont.subheadline)
                                        .foregroundStyle(PulsePalette.ink)
                                }
                                .tint(accent)

                                DatePicker("Дата", selection: $date, displayedComponents: [.date])
                                    .font(PulseFont.caption)
                                    .tint(accent)
                                    .labelsHidden()
                                    .datePickerStyle(.compact)

                                if !isAllDay {
                                    DatePicker("Начало", selection: $startTime, displayedComponents: [.hourAndMinute])
                                        .font(PulseFont.caption)
                                        .tint(accent)
                                        .datePickerStyle(.compact)

                                    HStack {
                                        Text("Длительность")
                                            .font(PulseFont.subheadline)
                                            .foregroundStyle(PulsePalette.ink)
                                        Spacer()
                                        Text(PulseDate.durationText(minutes: durationMinutes))
                                            .font(PulseFont.caption)
                                            .foregroundStyle(PulsePalette.inkSecondary)
                                    }

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 7) {
                                            ForEach([15, 30, 45, 60, 90, 120, 180], id: \.self) { value in
                                                Button {
                                                    Haptics.selection()
                                                    withAnimation(PulseMotion.snappy) {
                                                        durationMinutes = value
                                                    }
                                                } label: {
                                                    Text(PulseDate.durationShort(minutes: value))
                                                        .font(PulseFont.caption)
                                                        .foregroundStyle(durationMinutes == value ? Color.white : PulsePalette.inkSecondary)
                                                        .padding(.horizontal, 11)
                                                        .padding(.vertical, 7)
                                                        .background(
                                                            Capsule().fill(durationMinutes == value
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

                                HStack {
                                    Text("Итого")
                                        .font(PulseFont.micro)
                                        .foregroundStyle(PulsePalette.inkTertiary)
                                    Spacer()
                                    Text("\(start.timeString) – \(end.timeString)")
                                        .font(PulseFont.number(13, .semibold))
                                        .foregroundStyle(PulsePalette.inkSecondary)
                                }
                            }
                        }

                        EditorCard(title: "Место", symbol: "mappin.and.ellipse") {
                            TextField("Адрес или ссылка", text: $location)
                                .font(PulseFont.callout)
                                .foregroundStyle(PulsePalette.ink)
                        }

                        EditorCard(title: "Категория", symbol: "square.grid.2x2") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 7) {
                                    ForEach(store.categories) { category in
                                        let isSelected = categoryID == category.id
                                        Button {
                                            Haptics.selection()
                                            withAnimation(PulseMotion.snappy) {
                                                categoryID = isSelected ? nil : category.id
                                            }
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
                                                Capsule().fill(isSelected
                                                               ? Color(category.colorHex).opacity(0.14)
                                                               : PulsePalette.cardSunken)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                        }

                        EditorCard(title: "Заметка", symbol: "text.alignleft") {
                            TextField("Детали события", text: $notes, axis: .vertical)
                                .font(PulseFont.callout)
                                .foregroundStyle(PulsePalette.ink)
                                .lineLimit(2...6)
                        }

                        if request.event != nil {
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Удалить событие")
                                        .font(PulseFont.subheadline)
                                }
                                .foregroundStyle(PulsePalette.danger)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(PulsePalette.danger.opacity(0.08), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, PulseMetrics.screenPadding)
                    .padding(.vertical, 14)
                    .padding(.bottom, 80)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .onAppear {
            if request.event == nil {
                titleFocused = true
            }
        }
        .confirmationDialog("Удалить событие?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                if let event = request.event {
                    store.deleteEvent(event)
                }
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Отмена")
                        .font(PulseFont.subheadline)
                        .foregroundStyle(PulsePalette.inkSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(request.event == nil ? "Новое событие" : "Событие")
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
            }
            .padding(.horizontal, PulseMetrics.screenPadding)
            .padding(.top, 18)
            .padding(.bottom, 12)

            PulseDivider()
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var event = request.event ?? CalendarEvent()
        event.title = trimmed
        event.notes = notes
        event.location = location
        event.start = start
        event.end = end
        event.isAllDay = isAllDay
        event.categoryID = categoryID

        if request.event == nil {
            store.addEvent(event)
        } else {
            store.updateEvent(event)
        }
        Haptics.success()
        dismiss()
    }
}
