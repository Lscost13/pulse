//
//  AppStore.swift
//  PULSE
//
//  Единый источник истины. Все экраны читают данные отсюда и дергают
//  методы изменения; сохранение — сразу после изменения.
//

import Foundation
import Observation

@Observable
final class AppStore {

    // MARK: - Состояние

    var tasks: [TaskItem] = []
    var events: [CalendarEvent] = []
    var habits: [Habit] = []
    var sessions: [FocusSession] = []
    var categories: [TaskCategory] = []
    var achievements: [Achievement] = []
    var settings: PulseSettings = PulseSettings()

    // MARK: - Инициализация

    init() {
        let rescueKey = "pulse.seedRescue.v1"
        let loaded = Persistence.load()
        let hasContent = loaded.map {
            !$0.tasks.isEmpty || !$0.habits.isEmpty || !$0.events.isEmpty
        } ?? false

        if let snapshot = loaded, hasContent {
            apply(snapshot)
            return
        }

        // Данные пусты, но пользователь уже один раз «спасал» демо —
        // значит очистка была осознанной, не навязываем её снова.
        if let snapshot = loaded, UserDefaults.standard.bool(forKey: rescueKey) {
            apply(snapshot)
            return
        }

        var demo = SampleData.make()
        if let snapshot = loaded {
            // Настройки пользователя (имя, тема, акцент) сохраняем,
            // восстанавливаем только содержимое.
            var settings = snapshot.settings
            settings.hasSeededDemo = true
            demo.settings = settings
        }
        apply(demo)
        Persistence.save(demo)
        UserDefaults.standard.set(true, forKey: rescueKey)
    }

    private func apply(_ snapshot: AppSnapshot) {
        tasks = snapshot.tasks
        events = snapshot.events
        habits = snapshot.habits
        sessions = snapshot.sessions
        categories = snapshot.categories
        achievements = snapshot.achievements
        settings = snapshot.settings
    }

    func currentSnapshot() -> AppSnapshot {
        AppSnapshot(
            schemaVersion: 1,
            tasks: tasks,
            events: events,
            habits: habits,
            sessions: sessions,
            categories: categories,
            achievements: achievements,
            settings: settings
        )
    }

    func persist() {
        refreshAchievements()
        Persistence.save(currentSnapshot())
    }

    // MARK: - Календарь и «сейчас»

    var calendar: Calendar {
        PulseDate.calendar(firstWeekdayMonday: settings.weekStartsMonday)
    }

    var now: Date {
        Date()
    }

    var today: Date {
        calendar.startOfDay(for: Date())
    }

    func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    // MARK: - Категории

    func category(with id: UUID?) -> TaskCategory? {
        guard let id = id else { return nil }
        return categories.first { $0.id == id }
    }

    func colorHex(for id: UUID?) -> String {
        category(with: id)?.colorHex ?? settings.accent.mainHex
    }

    var defaultCategory: TaskCategory? {
        categories.sorted { $0.order < $1.order }.first
    }

    func addCategory(_ category: TaskCategory) {
        var copy = category
        copy.order = categories.count
        categories.append(copy)
        persist()
    }

    func updateCategory(_ category: TaskCategory) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[index] = category
        persist()
    }

    func deleteCategory(_ category: TaskCategory) {
        categories.removeAll { $0.id == category.id }
        for index in tasks.indices where tasks[index].categoryID == category.id {
            tasks[index].categoryID = nil
        }
        for index in events.indices where events[index].categoryID == category.id {
            events[index].categoryID = nil
        }
        persist()
    }

    // MARK: - Задачи: выборки

    func task(with id: UUID?) -> TaskItem? {
        guard let id = id else { return nil }
        return tasks.first { $0.id == id }
    }

    func tasks(on day: Date) -> [TaskItem] {
        tasks
            .filter { task in
                guard let due = task.dueDate else { return false }
                return calendar.isDate(due, inSameDayAs: day)
            }
            .sorted { lhs, rhs in
                let l = lhs.dueDate ?? .distantFuture
                let r = rhs.dueDate ?? .distantFuture
                if l != r { return l < r }
                return lhs.createdAt < rhs.createdAt
            }
    }

    func openTasks(on day: Date) -> [TaskItem] {
        tasks(on: day).filter { !$0.isCompleted }
    }

    func completedOn(_ day: Date) -> [TaskItem] {
        tasks.filter { task in
            guard task.isCompleted, let done = task.completedAt else { return false }
            return calendar.isDate(done, inSameDayAs: day)
        }
    }

    var overdueTasks: [TaskItem] {
        tasks
            .filter { $0.isOverdue }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    var unscheduledTasks: [TaskItem] {
        tasks.filter { !$0.isCompleted && $0.dueDate == nil }
    }

    var completedTasks: [TaskItem] {
        tasks
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    func tasks(in list: SmartList) -> [TaskItem] {
        let cal = calendar
        let todayStart = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart
        let weekEnd = cal.date(byAdding: .day, value: 7, to: todayStart) ?? todayStart

        switch list {
        case .today:
            return tasks
                .filter { task in
                    guard !task.isCompleted, let due = task.dueDate else { return false }
                    return cal.isDate(due, inSameDayAs: todayStart)
                }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .tomorrow:
            return tasks
                .filter { task in
                    guard !task.isCompleted, let due = task.dueDate else { return false }
                    return cal.isDate(due, inSameDayAs: tomorrow)
                }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .week:
            return tasks
                .filter { task in
                    guard !task.isCompleted, let due = task.dueDate else { return false }
                    return due >= tomorrow && due < weekEnd
                }
                .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
        case .overdue:
            return overdueTasks
        case .someday:
            return unscheduledTasks.sorted { $0.createdAt > $1.createdAt }
        case .completed:
            return Array(completedTasks.prefix(200))
        }
    }

    func taskCount(in list: SmartList) -> Int {
        tasks(in: list).count
    }

    // MARK: - Задачи: изменения

    func add(_ task: TaskItem) {
        var copy = task
        copy.sortIndex = tasks.count
        tasks.append(copy)
        if settings.remindersEnabled {
            NotificationManager.schedule(task: copy)
        }
        persist()
        Haptics.success()
    }

    func update(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        if settings.remindersEnabled {
            NotificationManager.schedule(task: task)
        }
        persist()
    }

    func delete(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        NotificationManager.cancel(taskID: task.id)
        persist()
    }

    func toggleCompletion(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        if tasks[index].isCompleted {
            tasks[index].completedAt = Date()
            NotificationManager.cancel(taskID: task.id)
            Haptics.success()
            spawnRecurringCopyIfNeeded(at: index)
        } else {
            tasks[index].completedAt = nil
            Haptics.soft()
        }
        persist()
    }

    private func spawnRecurringCopyIfNeeded(at index: Int) {
        let source = tasks[index]
        guard source.isCompleted,
              source.recurrence != .never,
              let due = source.dueDate,
              let next = source.recurrence.nextDate(after: due, calendar: calendar)
        else { return }
        var copy = source
        copy.id = UUID()
        copy.isCompleted = false
        copy.completedAt = nil
        copy.dueDate = next
        copy.createdAt = Date()
        copy.focusMinutes = 0
        copy.subtasks = source.subtasks.map { Subtask(id: UUID(), title: $0.title, isDone: false) }
        if let reminder = source.reminderDate {
            copy.reminderDate = next.addingTimeInterval(reminder.timeIntervalSince(due))
        }
        tasks.append(copy)
        if settings.remindersEnabled {
            NotificationManager.schedule(task: copy)
        }
    }

    func move(_ task: TaskItem, to day: Date?) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        guard let day = day else {
            tasks[index].dueDate = nil
            tasks[index].reminderDate = nil
            persist()
            return
        }
        let cal = calendar
        let targetDay = cal.startOfDay(for: day)
        let hour: Int
        let minute: Int
        if let existing = tasks[index].dueDate {
            hour = cal.component(.hour, from: existing)
            minute = cal.component(.minute, from: existing)
        } else {
            hour = 10
            minute = 0
        }
        var components = cal.dateComponents([.year, .month, .day], from: targetDay)
        components.hour = hour
        components.minute = minute
        tasks[index].dueDate = cal.date(from: components)
        persist()
    }

    func duplicate(_ task: TaskItem) {
        var copy = task
        copy.id = UUID()
        copy.title = task.title + " (копия)"
        copy.isCompleted = false
        copy.completedAt = nil
        copy.createdAt = Date()
        copy.subtasks = task.subtasks.map { Subtask(id: UUID(), title: $0.title, isDone: $0.isDone) }
        tasks.append(copy)
        persist()
    }

    func toggleSubtask(taskID: UUID, subtaskID: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }),
              let subIndex = tasks[index].subtasks.firstIndex(where: { $0.id == subtaskID })
        else { return }
        tasks[index].subtasks[subIndex].isDone.toggle()
        Haptics.selection()
        persist()
    }

    func completeAllToday() {
        for task in openTasks(on: today) {
            toggleCompletion(task)
        }
    }

    // MARK: - События

    func events(on day: Date) -> [CalendarEvent] {
        events
            .filter { event in
                if event.isAllDay {
                    return calendar.isDate(event.start, inSameDayAs: day)
                }
                return calendar.isDate(event.start, inSameDayAs: day)
            }
            .sorted { $0.start < $1.start }
    }

    func events(in range: DateInterval) -> [CalendarEvent] {
        events.filter { $0.start < range.end && $0.end > range.start }
    }

    func addEvent(_ event: CalendarEvent) {
        events.append(event)
        persist()
    }

    func updateEvent(_ event: CalendarEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index] = event
        persist()
    }

    func deleteEvent(_ event: CalendarEvent) {
        events.removeAll { $0.id == event.id }
        persist()
    }

    // MARK: - Привычки

    func addHabit(_ habit: Habit) {
        var copy = habit
        copy.order = habits.count
        habits.append(copy)
        persist()
    }

    func updateHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index] = habit
        persist()
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        persist()
    }

    func toggleHabit(_ habit: Habit, on day: Date) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let key = day.dayKey
        if habits[index].completions.contains(key) {
            habits[index].completions.removeAll { $0 == key }
            Haptics.soft()
        } else {
            habits[index].completions.append(key)
            Haptics.success()
        }
        persist()
    }

    var activeHabits: [Habit] {
        habits.filter { !$0.isArchived }.sorted { $0.order < $1.order }
    }

    func habitsDone(on day: Date) -> Int {
        activeHabits.filter { $0.isDone(on: day) }.count
    }

    func habitProgress(on day: Date) -> Double {
        let active = activeHabits
        guard !active.isEmpty else { return 0 }
        return Double(habitsDone(on: day)) / Double(active.count)
    }

    // MARK: - Фокус

    func addSession(_ session: FocusSession) {
        sessions.append(session)
        if session.isFocus && session.completed {
            if let taskID = session.taskID,
               let index = tasks.firstIndex(where: { $0.id == taskID }) {
                tasks[index].focusMinutes += session.minutes
            }
        }
        persist()
    }

    func focusMinutes(on day: Date) -> Int {
        sessions
            .filter { $0.isFocus && $0.completed && calendar.isDate($0.startedAt, inSameDayAs: day) }
            .reduce(0) { $0 + $1.minutes }
    }

    func focusSessions(on day: Date) -> [FocusSession] {
        sessions
            .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
            .sorted { $0.startedAt > $1.startedAt }
    }

    var recentSessions: [FocusSession] {
        sessions
            .filter { $0.completed }
            .sorted { $0.startedAt > $1.startedAt }
    }

    // MARK: - Прогресс дня

    var todayTasks: [TaskItem] {
        tasks(on: today)
    }

    var todayOpenTasks: [TaskItem] {
        todayTasks.filter { !$0.isCompleted }
    }

    var todayCompletedCount: Int {
        todayTasks.filter { $0.isCompleted }.count
    }

    var todayProgress: Double {
        let all = todayTasks
        guard !all.isEmpty else {
            let habitsProgress = habitProgress(on: today)
            return habitsProgress
        }
        let done = Double(all.filter { $0.isCompleted }.count)
        return done / Double(all.count)
    }

    var plannedMinutesToday: Int {
        todayTasks.reduce(0) { $0 + $1.plannedMinutes }
    }

    var focusMinutesToday: Int {
        focusMinutes(on: today)
    }

    var freeMinutesToday: Int {
        let cal = calendar
        let dayStart = cal.startOfDay(for: Date())
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let busy = busyIntervals(on: dayStart, from: dayStart, to: dayEnd)
        let window = workdayWindow(for: dayStart)
        let from = max(window.start, Date())
        let to = window.end
        guard to > from else { return 0 }
        let free = freeIntervals(from: from, to: to, busy: busy)
        return free.reduce(0) { $0 + PulseDate.minutesBetween($1.start, $1.end) }
    }

    var workdayStartHour: Int { 8 }
    var workdayEndHour: Int { 22 }

    func workdayWindow(for day: Date) -> (start: Date, end: Date) {
        let start = day.combiningTime(hour: workdayStartHour, minute: 0, calendar: calendar)
        let end = day.combiningTime(hour: workdayEndHour, minute: 0, calendar: calendar)
        return (start, end)
    }

    func busyIntervals(on day: Date, from: Date, to: Date) -> [DateInterval] {
        var intervals: [DateInterval] = []
        for event in events(on: day) where !event.isAllDay {
            intervals.append(DateInterval(start: event.start, end: event.end))
        }
        for task in tasks(on: day) {
            if let start = task.dueDate, let end = task.endDate {
                intervals.append(DateInterval(start: start, end: end))
            }
        }
        return merge(intervals.filter { $0.end > from && $0.start < to })
    }

    func merge(_ intervals: [DateInterval]) -> [DateInterval] {
        let sorted = intervals.sorted { $0.start < $1.start }
        var result: [DateInterval] = []
        for interval in sorted {
            if let last = result.last, interval.start <= last.end {
                let merged = DateInterval(start: last.start, end: max(last.end, interval.end))
                result[result.count - 1] = merged
            } else {
                result.append(interval)
            }
        }
        return result
    }

    func freeIntervals(from: Date, to: Date, busy: [DateInterval]) -> [DateInterval] {
        var result: [DateInterval] = []
        var cursor = from
        for interval in busy.sorted(by: { $0.start < $1.start }) {
            if interval.start > cursor {
                let end = min(interval.start, to)
                if end > cursor {
                    result.append(DateInterval(start: cursor, end: end))
                }
            }
            cursor = max(cursor, interval.end)
            if cursor >= to { break }
        }
        if cursor < to {
            result.append(DateInterval(start: cursor, end: to))
        }
        return result.filter { $0.duration >= 15 * 60 }
    }

    /// Свободные окна на день — для «умного» предложения времени.
    func freeSlots(on day: Date, minimumMinutes: Int = 30) -> [DateInterval] {
        let window = workdayWindow(for: day)
        let busy = busyIntervals(on: day, from: window.start, to: window.end)
        return freeIntervals(from: window.start, to: window.end, busy: busy)
            .filter { $0.duration >= Double(minimumMinutes) * 60 }
    }

    /// Ближайшее свободное окно под задачу нужной длительности.
    func suggestedSlot(for minutes: Int, on day: Date) -> Date? {
        freeSlots(on: day, minimumMinutes: minutes).first { interval in
            let start = max(interval.start, Date())
            return interval.end.timeIntervalSince(start) >= Double(minutes) * 60
        }.map { max($0.start, Date()) }
    }

    var nextEvent: CalendarEvent? {
        let current = Date()
        return events(on: today)
            .filter { !$0.isAllDay && $0.start > current }
            .min { $0.start < $1.start }
    }

    var currentEvent: CalendarEvent? {
        let current = Date()
        return events(on: today)
            .first { !$0.isAllDay && $0.start <= current && $0.end > current }
    }

    func nextEvent(after date: Date) -> CalendarEvent? {
        events
            .filter { $0.start > date }
            .min { $0.start < $1.start }
    }

    func dayLoad(for day: Date) -> DayLoad {
        let busy = busyIntervals(on: day, from: day, to: day.addingTimeInterval(86400))
        let minutes = busy.reduce(0) { $0 + PulseDate.minutesBetween($1.start, $1.end) }
        if minutes == 0 { return .empty }
        if minutes < 120 { return .light }
        if minutes < 300 { return .medium }
        if minutes < 540 { return .busy }
        return .overloaded
    }

    func loadRatio(for day: Date) -> Double {
        let busy = busyIntervals(on: day, from: day, to: day.addingTimeInterval(86400))
        let minutes = busy.reduce(0) { $0 + PulseDate.minutesBetween($1.start, $1.end) }
        return min(1, Double(minutes) / 720.0)
    }

    // MARK: - Таймлайн

    func blocks(on day: Date) -> [TimeBlock] {
        var blocks: [TimeBlock] = []
        for event in events(on: day) where !event.isAllDay {
            blocks.append(
                TimeBlock(
                    id: event.id,
                    kind: .event,
                    title: event.title,
                    start: event.start,
                    end: event.end,
                    colorHex: colorHex(for: event.categoryID)
                )
            )
        }
        for task in tasks(on: day) {
            guard let start = task.dueDate, let end = task.endDate else { continue }
            blocks.append(
                TimeBlock(
                    id: task.id,
                    kind: .task,
                    title: task.title,
                    start: start,
                    end: end,
                    colorHex: colorHex(for: task.categoryID),
                    isDone: task.isCompleted
                )
            )
        }
        return blocks.sorted { $0.start < $1.start }
    }

    // MARK: - Серия

    var streak: StreakStats {
        StreakEngine.compute(
            tasks: tasks,
            habits: habits,
            sessions: sessions,
            settings: settings,
            reference: Date(),
            calendar: calendar
        )
    }

    func repairStreak(day: Date) {
        let key = day.dayKey
        if !settings.repairedDays.contains(key) {
            settings.repairedDays.append(key)
            persist()
            Haptics.success()
        }
    }

    // MARK: - Достижения

    func refreshAchievements() {
        guard !achievements.isEmpty else { return }
        let stats = streak
        let reference = max(stats.current, stats.longest)
        for index in achievements.indices where achievements[index].unlockedAt == nil {
            if reference >= achievements[index].threshold {
                achievements[index].unlockedAt = Date()
            }
        }
        if reference > settings.bestFocusStreak {
            settings.bestFocusStreak = reference
        }
    }

    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    // MARK: - Статистика

    func stats(days: Int) -> StatsSnapshot {
        StatsEngine.snapshot(
            days: days,
            endingAt: Date(),
            tasks: tasks,
            sessions: sessions,
            categories: categories,
            calendar: calendar
        )
    }

    // MARK: - Настройки

    func updateSettings(_ block: (inout PulseSettings) -> Void) {
        block(&settings)
        persist()
    }

    func eraseEverything() {
        NotificationManager.cancelAll()
        Persistence.wipe()
        let empty = AppSnapshot(
            schemaVersion: 1,
            tasks: [],
            events: [],
            habits: [],
            sessions: [],
            categories: SampleData.defaultCategories(),
            achievements: SampleData.achievementCatalog(),
            settings: settings
        )
        apply(empty)
        persist()
    }

    func loadDemoData() {
        let demo = SampleData.make()
        apply(demo)
        persist()
    }
}
