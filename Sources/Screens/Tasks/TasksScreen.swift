//
//  TasksScreen.swift
//  PULSE
//
//  Все задачи: умные списки, поиск, фильтры по категориям,
//  распределение по свободному времени.
//

import Foundation
import SwiftUI

struct TasksScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var searchText: String = ""
    @State private var selectedCategory: UUID?
    @State private var toast: String?

    var body: some View {
        ZStack(alignment: .top) {
            PulseBackground(accent: store.settings.accent.color)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    listChips
                    searchField
                    if !searchText.isEmpty {
                        searchResults
                    } else if horizontalSizeClass == .regular {
                        HStack(alignment: .top, spacing: 20) {
                            taskContent
                                .frame(maxWidth: .infinity)
                            summaryPanel
                                .frame(width: 300)
                        }
                    } else {
                        taskContent
                    }
                }
                .padding(.horizontal, PulseMetrics.screenPadding)
                .padding(.top, 10)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)

            if let toast = toast {
                ToastView(text: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(PulseMotion.smooth, value: toast)
    }

    // MARK: - Шапка

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ЗАДАЧИ")
                    .font(PulseFont.micro)
                    .tracking(1.2)
                    .foregroundStyle(PulsePalette.inkTertiary)
                Text("Всё под контролем")
                    .font(PulseFont.displayM)
                    .foregroundStyle(PulsePalette.ink)
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Menu {
                    Button {
                        autoSchedule()
                    } label: {
                        Label("Распределить по свободному времени", systemImage: "wand.and.stars")
                    }
                    Button {
                        completeOverdueToTomorrow()
                    } label: {
                        Label("Просроченное — на завтра", systemImage: "calendar.badge.clock")
                    }
                    Divider()
                    Button {
                        router.openNewTask(day: store.today)
                    } label: {
                        Label("Новая задача", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(PulsePalette.inkSecondary)
                        .frame(width: 38, height: 38)
                        .background(PulsePalette.cardSunken, in: Circle())
                }

                CircleIconButton(symbol: "plus", size: 38, tint: Color.white, background: store.settings.accent.color) {
                    router.openNewTask(day: router.selectedDay)
                }
            }
        }
    }

    // MARK: - Умные списки

    private var listChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SmartList.allCases) { list in
                    let count = store.taskCount(in: list)
                    Button {
                        Haptics.selection()
                        withAnimation(PulseMotion.smooth) {
                            router.smartList = list
                            selectedCategory = nil
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: list.symbol)
                                .font(.system(size: 10, weight: .semibold))
                            Text(list.title)
                                .font(PulseFont.caption)
                            if count > 0 {
                                Text("\(count)")
                                    .font(PulseFont.micro)
                                    .opacity(0.65)
                            }
                        }
                        .foregroundStyle(router.smartList == list ? Color.white : PulsePalette.inkSecondary)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background {
                            Capsule()
                                .fill(router.smartList == list
                                      ? AnyShapeStyle(PulseGradient.accent(store.settings.accent.color))
                                      : AnyShapeStyle(PulsePalette.cardSunken))
                        }
                        .overlay(Capsule().strokeBorder(
                            router.smartList == list ? Color.clear : PulsePalette.strokeSoft,
                            lineWidth: 1
                        ))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PulsePalette.inkTertiary)
            TextField("Найти задачу", text: $searchText)
                .font(PulseFont.body)
                .foregroundStyle(PulsePalette.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(PulsePalette.inkTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(PulsePalette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(PulsePalette.stroke, lineWidth: 1)
        )
    }

    // MARK: - Контент

    private var filteredTasks: [TaskItem] {
        var items = store.tasks(in: router.smartList)
        if let category = selectedCategory {
            items = items.filter { $0.categoryID == category }
        }
        return items
    }

    @ViewBuilder
    private var taskContent: some View {
        let items = filteredTasks
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Text(router.smartList.title.uppercased())
                    .font(PulseFont.micro)
                    .tracking(1)
                    .foregroundStyle(PulsePalette.inkTertiary)
                Text("\(items.count)")
                    .font(PulseFont.micro)
                    .foregroundStyle(PulsePalette.inkTertiary.opacity(0.7))
                Spacer()
            }

            categoryFilter

            if items.isEmpty {
                PulseCard {
                    EmptyState(
                        symbol: router.smartList.symbol,
                        title: emptyTitle,
                        subtitle: emptySubtitle,
                        actionTitle: "Добавить задачу",
                        action: { router.openNewTask(day: defaultDayForNewTask) }
                    )
                }
            } else {
                groupedList(items)
            }
        }
    }

    @ViewBuilder
    private var categoryFilter: some View {
        if !store.categories.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    Button {
                        Haptics.selection()
                        withAnimation(PulseMotion.snappy) { selectedCategory = nil }
                    } label: {
                        Text("Все")
                            .font(PulseFont.caption)
                            .foregroundStyle(selectedCategory == nil ? PulsePalette.ink : PulsePalette.inkTertiary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(selectedCategory == nil ? PulsePalette.card : Color.clear)
                            )
                            .overlay(Capsule().strokeBorder(PulsePalette.strokeSoft, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    ForEach(store.categories) { category in
                        let isSelected = selectedCategory == category.id
                        Button {
                            Haptics.selection()
                            withAnimation(PulseMotion.snappy) {
                                selectedCategory = isSelected ? nil : category.id
                            }
                        } label: {
                            HStack(spacing: 5) {
                                CategoryDot(hex: category.colorHex, size: 6)
                                Text(category.name)
                                    .font(PulseFont.caption)
                                    .foregroundStyle(isSelected ? PulsePalette.ink : PulsePalette.inkSecondary)
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(isSelected ? PulsePalette.card : Color.clear))
                            .overlay(Capsule().strokeBorder(
                                isSelected ? Color(category.colorHex).opacity(0.4) : PulsePalette.strokeSoft,
                                lineWidth: 1
                            ))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 1)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func groupedList(_ items: [TaskItem]) -> some View {
        let groups = group(items)
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(groups, id: \.key) { group in
                VStack(alignment: .leading, spacing: 8) {
                    if let title = group.title {
                        HStack(spacing: 6) {
                            Text(title.uppercased())
                                .font(PulseFont.micro)
                                .tracking(0.8)
                                .foregroundStyle(PulsePalette.inkTertiary)
                            if group.isOverdue {
                                TagPill(text: "просрочено", tint: PulsePalette.danger)
                            }
                            Spacer()
                        }
                        .padding(.leading, 4)
                    }

                    PulseCard(padding: 6) {
                        VStack(spacing: 0) {
                            ForEach(Array(group.tasks.enumerated()), id: \.element.id) { index, task in
                                if index > 0 {
                                    PulseDivider(inset: 40)
                                }
                                TaskRow(task: task, showsDay: group.title != nil)
                                    .padding(.horizontal, 10)
                            }
                        }
                    }
                }
            }
        }
    }

    private struct TaskGroup {
        var key: String
        var title: String?
        var isOverdue: Bool
        var tasks: [TaskItem]
    }

    private func group(_ items: [TaskItem]) -> [TaskGroup] {
        guard router.smartList != .someday else {
            return [TaskGroup(key: "none", title: nil, isOverdue: false, tasks: items)]
        }

        var buckets: [String: [TaskItem]] = [:]
        var order: [String] = []
        for task in items {
            let date: Date? = router.smartList == .completed
                ? task.completedAt
                : task.dueDate
            let key = date?.dayKey ?? "none"
            if buckets[key] == nil {
                buckets[key] = []
                order.append(key)
            }
            buckets[key]?.append(task)
        }

        return order.map { key in
            let tasks = buckets[key] ?? []
            let date = Date.from(dayKey: key)
            let title: String?
            if let date = date {
                if date.isToday {
                    title = "Сегодня, \(date.dayMonthTitle)"
                } else if date.isSameDay(as: store.today.adding(days: 1)) {
                    title = "Завтра, \(date.dayMonthTitle)"
                } else {
                    title = "\(date.weekdayFull), \(date.dayMonthTitle)"
                }
            } else {
                title = "Без даты"
            }
            let overdue = router.smartList == .overdue
            return TaskGroup(key: key, title: title, isOverdue: overdue, tasks: tasks)
        }
    }

    // MARK: - Поиск

    private var searchResults: some View {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let items = store.tasks.filter { task in
            query.isEmpty
                ? false
                : task.title.lowercased().contains(query)
                    || task.notes.lowercased().contains(query)
        }
        return VStack(alignment: .leading, spacing: 12) {
            Text("РЕЗУЛЬТАТЫ · \(items.count)")
                .font(PulseFont.micro)
                .tracking(1)
                .foregroundStyle(PulsePalette.inkTertiary)

            if items.isEmpty {
                PulseCard {
                    EmptyState(
                        symbol: "magnifyingglass",
                        title: "Ничего не найдено",
                        subtitle: "Попробуй другой запрос — или создай задачу."
                    )
                }
            } else {
                PulseCard(padding: 6) {
                    VStack(spacing: 0) {
                        ForEach(Array(TaskItem.sorted(items).enumerated()), id: \.element.id) { index, task in
                            if index > 0 {
                                PulseDivider(inset: 40)
                            }
                            TaskRow(task: task, showsDay: true)
                                .padding(.horizontal, 10)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Панель сводки (iPad)

    private var summaryPanel: some View {
        VStack(spacing: 16) {
            PulseCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("СЕГОДНЯ")
                        .font(PulseFont.micro)
                        .tracking(1)
                        .foregroundStyle(PulsePalette.inkTertiary)

                    ZStack {
                        ProgressRing(
                            progress: store.todayProgress,
                            lineWidth: 10,
                            accent: store.settings.accent.color
                        )
                        .frame(width: 110, height: 110)
                        VStack(spacing: 0) {
                            Text("\(Int((store.todayProgress * 100).rounded()))%")
                                .font(PulseFont.number(26, .bold))
                                .foregroundStyle(PulsePalette.ink)
                            Text("\(store.todayCompletedCount)/\(store.todayTasks.count)")
                                .font(PulseFont.micro)
                                .foregroundStyle(PulsePalette.inkTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    HStack {
                        StatTile(value: "\(store.overdueTasks.count)", title: "просрочено", tint: PulsePalette.danger)
                        StatTile(value: "\(store.unscheduledTasks.count)", title: "без даты", tint: PulsePalette.inkSecondary)
                    }
                }
            }

            PulseCard(tint: PulsePalette.mint) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(PulsePalette.mint)
                        Text("Умное распределение")
                            .font(PulseFont.subheadline)
                            .foregroundStyle(PulsePalette.ink)
                    }
                    Text("Расставлю задачи без даты в свободные окна ближайших дней.")
                        .font(PulseFont.caption)
                        .foregroundStyle(PulsePalette.inkTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        autoSchedule()
                    } label: {
                        Text("Распределить")
                    }
                    .buttonStyle(PulseSecondaryButtonStyle())
                }
            }
        }
    }

    // MARK: - Действия

    private func autoSchedule() {
        let pending = store.unscheduledTasks.prefix(4)
        guard !pending.isEmpty else {
            showToast("Нет задач без даты")
            return
        }
        var scheduled = 0
        for task in pending {
            var placed = false
            for offset in 0..<4 where !placed {
                let day = store.today.adding(days: offset)
                if let slot = store.suggestedSlot(for: task.duration, on: day) {
                    store.move(task, to: slot)
                    scheduled += 1
                    placed = true
                }
            }
        }
        showToast(scheduled > 0 ? "Задач расставлено: \(scheduled)" : "Свободных окон не нашлось")
    }

    private func completeOverdueToTomorrow() {
        let overdue = store.overdueTasks
        guard !overdue.isEmpty else {
            showToast("Просроченных задач нет")
            return
        }
        let tomorrow = store.today.adding(days: 1)
        for task in overdue {
            store.move(task, to: tomorrow)
        }
        showToast("Перенесено на завтра: \(overdue.count)")
    }

    private func showToast(_ text: String) {
        Haptics.success()
        toast = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if toast == text {
                toast = nil
            }
        }
    }

    private var defaultDayForNewTask: Date? {
        switch router.smartList {
        case .today: return store.today
        case .tomorrow: return store.today.adding(days: 1)
        case .week, .overdue, .someday, .completed: return store.today
        }
    }

    private var emptyTitle: String {
        switch router.smartList {
        case .today: return "На сегодня пусто"
        case .tomorrow: return "Завтра свободно"
        case .week: return "Неделя открыта"
        case .overdue: return "Просроченного нет"
        case .someday: return "Нет задач без даты"
        case .completed: return "Пока ничего не завершено"
        }
    }

    private var emptySubtitle: String {
        switch router.smartList {
        case .today: return "Хороший момент, чтобы запланировать главное."
        case .tomorrow: return "Задачи на завтра появятся здесь."
        case .week: return "Добавь задачи на ближайшие дни."
        case .overdue: return "Ты держишь всё в срок."
        case .someday: return "Идеи и задачи без срока живут здесь."
        case .completed: return "Завершённые задачи собираются в этом списке."
        }
    }
}

// MARK: - Тост

struct ToastView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PulsePalette.success)
            Text(text)
                .font(PulseFont.caption)
                .foregroundStyle(PulsePalette.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(PulsePalette.stroke, lineWidth: 1))
        .pulseShadow(PulseShadow(color: Color.black.opacity(0.18), radius: 18, y: 8))
    }
}
