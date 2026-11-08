//
//  SettingsView.swift
//  PULSE
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var showEraseConfirm: Bool = false
    @State private var showDemoConfirm: Bool = false
    @State private var showNewCategory: Bool = false
    @State private var newCategoryName: String = ""
    @State private var toast: String?

    private var accent: Color { store.settings.accent.color }

    var body: some View {
        @Bindable var store = store

        ZStack(alignment: .top) {
            PulseBackground(accent: accent)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    section("Профиль") {
                        profileCard(settings: $store.settings)
                    }

                    section("Оформление") {
                        appearanceCard(settings: $store.settings)
                    }

                    section("Цели") {
                        goalsCard(settings: $store.settings)
                    }

                    section("Фокус") {
                        focusCard(settings: $store.settings)
                    }

                    section("Поведение") {
                        behaviorCard(settings: $store.settings)
                    }

                    section("Категории") {
                        categoriesCard
                    }

                    section("Данные") {
                        dataCard
                    }

                    aboutBlock
                }
                .padding(.horizontal, PulseMetrics.screenPadding)
                .padding(.bottom, 60)
            }

            if let toast = toast {
                ToastView(text: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(PulseMotion.smooth, value: toast)
        .onChange(of: store.settings) { _, _ in
            store.persist()
        }
        .confirmationDialog("Удалить все данные?", isPresented: $showEraseConfirm, titleVisibility: .visible) {
            Button("Удалить всё", role: .destructive) {
                store.eraseEverything()
                showMessage("Данные удалены")
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Задачи, события, привычки и история будут стёрты безвозвратно.")
        }
        .confirmationDialog("Загрузить демо-данные?", isPresented: $showDemoConfirm, titleVisibility: .visible) {
            Button("Загрузить", role: .destructive) {
                store.loadDemoData()
                showMessage("Демо-данные загружены")
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Текущие данные будут заменены примером наполненного дня.")
        }
        .alert("Новая категория", isPresented: $showNewCategory) {
            TextField("Название", text: $newCategoryName)
            Button("Добавить") {
                addCategory()
            }
            Button("Отмена", role: .cancel) {
                newCategoryName = ""
            }
        } message: {
            Text("Категория появится в фильтрах и в редакторе задач.")
        }
    }

    // MARK: - Шапка

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("НАСТРОЙКИ")
                    .font(PulseFont.micro)
                    .tracking(1.2)
                    .foregroundStyle(PulsePalette.inkTertiary)
                Text("Под себя")
                    .font(PulseFont.displayM)
                    .foregroundStyle(PulsePalette.ink)
            }
            Spacer()
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
        .padding(.top, 18)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(PulseFont.micro)
                .tracking(1)
                .foregroundStyle(PulsePalette.inkTertiary)
                .padding(.leading, 4)
            content()
        }
    }

    // MARK: - Профиль

    private func profileCard(settings: Binding<PulseSettings>) -> some View {
        PulseCard(padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(PulseGradient.accent(accent))
                        .frame(width: 52, height: 52)
                    Text(initial)
                        .font(PulseFont.rounded(21, .bold))
                        .foregroundStyle(Color.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Как тебя зовут")
                        .font(PulseFont.micro)
                        .foregroundStyle(PulsePalette.inkTertiary)
                    TextField("Имя", text: settings.userName)
                        .font(PulseFont.subheadline)
                        .foregroundStyle(PulsePalette.ink)
                        .textInputAutocapitalization(.words)
                }
            }
        }
    }

    private var initial: String {
        let name = store.settings.userName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "P" : String(name.prefix(1)).uppercased()
    }

    // MARK: - Оформление

    private func appearanceCard(settings: Binding<PulseSettings>) -> some View {
        PulseCard(padding: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(AppearanceMode.allCases) { mode in
                        let isSelected = settings.appearance.wrappedValue == mode
                        Button {
                            Haptics.selection()
                            withAnimation(PulseMotion.theme) {
                                settings.appearance.wrappedValue = mode
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: mode.symbol)
                                    .font(.system(size: 15, weight: .semibold))
                                Text(mode.title)
                                    .font(.system(size: 9.5, weight: .medium))
                            }
                            .foregroundStyle(isSelected ? Color.white : PulsePalette.inkSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isSelected
                                          ? AnyShapeStyle(PulseGradient.accent(accent))
                                          : AnyShapeStyle(PulsePalette.cardSunken))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                PulseDivider()

                HStack {
                    Text("Акцент")
                        .font(PulseFont.subheadline)
                        .foregroundStyle(PulsePalette.ink)
                    Spacer()
                    HStack(spacing: 10) {
                        ForEach(AccentTheme.allCases) { theme in
                            let isSelected = settings.accent.wrappedValue == theme
                            Button {
                                Haptics.selection()
                                withAnimation(PulseMotion.smooth) {
                                    settings.accent.wrappedValue = theme
                                }
                            } label: {
                                Circle()
                                    .fill(theme.swatch)
                                    .frame(width: 26, height: 26)
                                    .overlay {
                                        Circle()
                                            .strokeBorder(
                                                isSelected ? PulsePalette.ink.opacity(0.85) : Color.clear,
                                                lineWidth: 2
                                            )
                                            .padding(-3)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Цели

    private func goalsCard(settings: Binding<PulseSettings>) -> some View {
        PulseCard(padding: 16) {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Фокус в день")
                            .font(PulseFont.subheadline)
                            .foregroundStyle(PulsePalette.ink)
                        Text("\(PulseDate.durationText(minutes: settings.dailyGoalMinutes.wrappedValue))")
                            .font(PulseFont.caption)
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }
                    Spacer()
                    Stepper("", value: settings.dailyGoalMinutes, in: 60...480, step: 30)
                        .labelsHidden()
                }

                Slider(
                    value: Binding(
                        get: { Double(settings.dailyGoalMinutes.wrappedValue) },
                        set: { settings.dailyGoalMinutes.wrappedValue = Int($0) }
                    ),
                    in: 60...480,
                    step: 30
                )
                .tint(accent)

                PulseDivider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Задач в неделю")
                            .font(PulseFont.subheadline)
                            .foregroundStyle(PulsePalette.ink)
                        Text("Гибкая цель, не жёсткий дедлайн")
                            .font(PulseFont.caption)
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }
                    Spacer()
                    Text("\(settings.weeklyGoalTasks.wrappedValue)")
                        .font(PulseFont.number(16, .bold))
                        .foregroundStyle(PulsePalette.ink)
                    Stepper("", value: settings.weeklyGoalTasks, in: 5...120, step: 5)
                        .labelsHidden()
                }
            }
        }
    }

    // MARK: - Фокус

    private func focusCard(settings: Binding<PulseSettings>) -> some View {
        PulseCard(padding: 16) {
            VStack(spacing: 12) {
                stepperRow(
                    title: "Длительность фокуса",
                    value: settings.focusLength.wrappedValue,
                    binding: settings.focusLength,
                    range: 10...90,
                    step: 5
                )
                PulseDivider()
                stepperRow(
                    title: "Короткий перерыв",
                    value: settings.shortBreak.wrappedValue,
                    binding: settings.shortBreak,
                    range: 3...20,
                    step: 1
                )
                PulseDivider()
                stepperRow(
                    title: "Длинный перерыв",
                    value: settings.longBreak.wrappedValue,
                    binding: settings.longBreak,
                    range: 10...45,
                    step: 5
                )
                PulseDivider()
                stepperRow(
                    title: "Сессий до отдыха",
                    value: settings.sessionsBeforeLongBreak.wrappedValue,
                    binding: settings.sessionsBeforeLongBreak,
                    range: 2...8,
                    step: 1
                )
            }
        }
    }

    private func stepperRow(
        title: String,
        value: Int,
        binding: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int
    ) -> some View {
        HStack {
            Text(title)
                .font(PulseFont.subheadline)
                .foregroundStyle(PulsePalette.ink)
            Spacer()
            Text(range.upperBound > 20 ? "\(value) мин" : "\(value)")
                .font(PulseFont.number(14, .semibold))
                .foregroundStyle(PulsePalette.inkSecondary)
            Stepper("", value: binding, in: range, step: step)
                .labelsHidden()
        }
    }

    // MARK: - Поведение

    private func behaviorCard(settings: Binding<PulseSettings>) -> some View {
        PulseCard(padding: 16) {
            VStack(spacing: 14) {
                Toggle(isOn: settings.weekStartsMonday) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Неделя с понедельника")
                            .font(PulseFont.subheadline)
                            .foregroundStyle(PulsePalette.ink)
                        Text("Влияет на календарь и отчёты")
                            .font(PulseFont.caption)
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }
                }
                .tint(accent)

                PulseDivider()

                Toggle(isOn: settings.remindersEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Напоминания")
                            .font(PulseFont.subheadline)
                            .foregroundStyle(PulsePalette.ink)
                        Text("Локальные уведомления о задачах")
                            .font(PulseFont.caption)
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }
                }
                .tint(accent)
                .onChange(of: store.settings.remindersEnabled) { _, newValue in
                    if newValue {
                        NotificationManager.requestAuthorizationIfNeeded()
                        NotificationManager.reschedule(tasks: store.tasks)
                    } else {
                        NotificationManager.cancelAll()
                    }
                }
            }
        }
    }

    // MARK: - Категории

    private var categoriesCard: some View {
        PulseCard(padding: 16) {
            VStack(spacing: 0) {
                ForEach(Array(store.categories.enumerated()), id: \.element.id) { index, category in
                    if index > 0 {
                        PulseDivider()
                    }
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: category.colorHex).opacity(0.16))
                                .frame(width: 26, height: 26)
                            Image(systemName: category.symbol)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color(hex: category.colorHex))
                        }
                        Text(category.name)
                            .font(PulseFont.subheadline)
                            .foregroundStyle(PulsePalette.ink)
                        Spacer()
                        Button {
                            Haptics.soft()
                            store.deleteCategory(category)
                            showMessage("Категория удалена")
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 15))
                                .foregroundStyle(PulsePalette.inkTertiary.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 9)
                }

                PulseDivider()

                Button {
                    newCategoryName = ""
                    showNewCategory = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Добавить категорию")
                            .font(PulseFont.caption)
                        Spacer()
                    }
                    .foregroundStyle(accent)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let palette = ["#7C6EEB", "#5EEAD4", "#F59E0B", "#F472B6", "#3B82F6", "#34D399", "#FB7185"]
        let hex = palette[store.categories.count % palette.count]
        store.addCategory(
            TaskCategory(
                id: UUID(),
                name: trimmed,
                colorHex: hex,
                symbol: "circle.fill",
                order: store.categories.count
            )
        )
        newCategoryName = ""
        showMessage("Категория добавлена")
    }

    // MARK: - Данные

    private var dataCard: some View {
        PulseCard(padding: 16) {
            VStack(spacing: 0) {
                Button {
                    showDemoConfirm = true
                } label: {
                    settingsRow(title: "Загрузить демо-данные", symbol: "sparkles", tint: PulsePalette.mint)
                }
                .buttonStyle(.plain)

                PulseDivider()

                Button {
                    showEraseConfirm = true
                } label: {
                    settingsRow(title: "Удалить все данные", symbol: "trash", tint: PulsePalette.danger)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func settingsRow(title: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22)
            Text(title)
                .font(PulseFont.subheadline)
                .foregroundStyle(PulsePalette.ink)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(PulsePalette.inkTertiary.opacity(0.6))
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }

    private var aboutBlock: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
                Text("PULSE")
                    .font(PulseFont.rounded(13, .bold))
                    .tracking(1.4)
                    .foregroundStyle(PulsePalette.inkSecondary)
            }
            Text("Версия \(appVersion) · время под контролем")
                .font(PulseFont.micro)
                .foregroundStyle(PulsePalette.inkTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func showMessage(_ text: String) {
        toast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if toast == text {
                toast = nil
            }
        }
    }
}
