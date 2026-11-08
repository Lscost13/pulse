//
//  HabitEditorView.swift
//  PULSE
//

import SwiftUI

struct HabitEditorView: View {
    let request: HabitEditorRequest

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var symbol: String
    @State private var colorHex: String
    @State private var kind: HabitKind
    @State private var targetPerWeek: Int
    @State private var showDeleteConfirm: Bool = false

    @FocusState private var nameFocused: Bool

    private let symbols = [
        "leaf.fill", "figure.run", "book", "drop.fill", "brain.head.profile",
        "dumbbell.fill", "bed.double.fill", "fork.knife", "pencil", "pianokeys",
        "sun.max.fill", "moon.stars.fill", "heart.fill", "music.note"
    ]

    private let palette = [
        "#7C6EEB", "#5EEAD4", "#34D399", "#F59E0B",
        "#F472B6", "#3B82F6", "#FB7185", "#A3E635"
    ]

    init(request: HabitEditorRequest) {
        self.request = request
        let existing = request.habit
        _name = State(initialValue: existing?.name ?? "")
        _symbol = State(initialValue: existing?.symbol ?? "leaf.fill")
        _colorHex = State(initialValue: existing?.colorHex ?? "#5EEAD4")
        _kind = State(initialValue: existing?.kind ?? .daily)
        _targetPerWeek = State(initialValue: existing?.targetPerWeek ?? 7)
    }

    private var accent: Color { store.settings.accent.color }
    private var habitColor: Color { Color(hex: colorHex) }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            PulseBackground(accent: accent)

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        preview

                        TextField("Название привычки", text: $name)
                            .font(PulseFont.rounded(24, .semibold))
                            .foregroundStyle(PulsePalette.ink)
                            .focused($nameFocused)

                        EditorCard(title: "Иконка", symbol: "square.grid.2x2") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                                ForEach(symbols, id: \.self) { item in
                                    Button {
                                        Haptics.selection()
                                        withAnimation(PulseMotion.snappy) { symbol = item }
                                    } label: {
                                        Image(systemName: item)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(symbol == item ? Color.white : PulsePalette.inkSecondary)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 38)
                                            .background(
                                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                                    .fill(symbol == item
                                                          ? AnyShapeStyle(habitColor)
                                                          : AnyShapeStyle(PulsePalette.cardSunken))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        EditorCard(title: "Цвет", symbol: "paintpalette") {
                            HStack(spacing: 9) {
                                ForEach(palette, id: \.self) { hex in
                                    Button {
                                        Haptics.selection()
                                        withAnimation(PulseMotion.snappy) { colorHex = hex }
                                    } label: {
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 28, height: 28)
                                            .overlay {
                                                Circle()
                                                    .strokeBorder(Color.white.opacity(colorHex == hex ? 0.9 : 0), lineWidth: 2)
                                                    .padding(2)
                                            }
                                            .overlay {
                                                Circle()
                                                    .strokeBorder(Color(hex: hex).opacity(0.5), lineWidth: colorHex == hex ? 2 : 0)
                                                    .padding(-2)
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        EditorCard(title: "Ритм", symbol: "repeat") {
                            VStack(alignment: .leading, spacing: 12) {
                                SegmentedPill(
                                    selection: Binding(
                                        get: { kind },
                                        set: { newValue in
                                            withAnimation(PulseMotion.snappy) {
                                                kind = newValue
                                                targetPerWeek = newValue == .daily ? 7 : min(targetPerWeek, 6)
                                            }
                                        }
                                    ),
                                    items: HabitKind.allCases,
                                    label: { $0.title },
                                    accent: habitColor
                                )

                                if kind == .weekly {
                                    HStack {
                                        Text("Цель в неделю")
                                            .font(PulseFont.subheadline)
                                            .foregroundStyle(PulsePalette.ink)
                                        Spacer()
                                        Stepper(
                                            value: $targetPerWeek,
                                            in: 1...7
                                        ) {
                                            Text("\(targetPerWeek)")
                                                .font(PulseFont.number(15, .bold))
                                                .foregroundStyle(PulsePalette.ink)
                                        }
                                        .labelsHidden()
                                    }
                                }
                            }
                        }

                        if request.habit != nil {
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Удалить привычку")
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
            if request.habit == nil {
                nameFocused = true
            }
        }
        .confirmationDialog("Удалить привычку?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                if let habit = request.habit {
                    store.deleteHabit(habit)
                }
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    private var preview: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(habitColor.opacity(0.16))
                    .frame(width: 58, height: 58)
                Circle()
                    .strokeBorder(habitColor.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 58, height: 58)
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(habitColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(name.isEmpty ? "Новая привычка" : name)
                    .font(PulseFont.headline)
                    .foregroundStyle(PulsePalette.ink)
                Text(kind == .daily ? "Каждый день" : "\(targetPerWeek) раз в неделю")
                    .font(PulseFont.caption)
                    .foregroundStyle(PulsePalette.inkTertiary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(PulsePalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(habitColor.opacity(0.2), lineWidth: 1)
        )
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

                Text(request.habit == nil ? "Новая привычка" : "Привычка")
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
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var habit = request.habit ?? Habit()
        habit.name = trimmed
        habit.symbol = symbol
        habit.colorHex = colorHex
        habit.kind = kind
        habit.targetPerWeek = kind == .daily ? 7 : targetPerWeek

        if request.habit == nil {
            store.addHabit(habit)
        } else {
            store.updateHabit(habit)
        }
        Haptics.success()
        dismiss()
    }
}
