//
//  Models.swift
//  PULSE
//
//  Доменные модели приложения. Никакого UI здесь нет — только данные,
//  чтобы их можно было спокойно сериализовать и считать статистику.
//

import Foundation

// MARK: - Приоритет

enum TaskPriority: String, Codable, CaseIterable, Identifiable, Hashable {
    case low
    case normal
    case high
    case critical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return "Низкий"
        case .normal: return "Обычный"
        case .high: return "Высокий"
        case .critical: return "Критичный"
        }
    }

    var glyph: String {
        switch self {
        case .low: return "↓"
        case .normal: return "·"
        case .high: return "↑"
        case .critical: return "!"
        }
    }

    var weight: Int {
        switch self {
        case .low: return 0
        case .normal: return 1
        case .high: return 2
        case .critical: return 3
        }
    }

    static func ordered() -> [TaskPriority] {
        [.critical, .high, .normal, .low]
    }
}

// MARK: - Повторение

enum Recurrence: String, Codable, CaseIterable, Identifiable, Hashable {
    case never
    case daily
    case weekdays
    case weekly
    case biweekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .never: return "Не повторять"
        case .daily: return "Каждый день"
        case .weekdays: return "По будням"
        case .weekly: return "Каждую неделю"
        case .biweekly: return "Раз в две недели"
        case .monthly: return "Каждый месяц"
        }
    }

    var shortTitle: String {
        switch self {
        case .never: return "Однократно"
        case .daily: return "Ежедневно"
        case .weekdays: return "Будни"
        case .weekly: return "Еженедельно"
        case .biweekly: return "2 недели"
        case .monthly: return "Ежемесячно"
        }
    }

    /// Следующая дата после указанной. nil — повторов нет.
    func nextDate(after date: Date, calendar: Calendar) -> Date? {
        switch self {
        case .never:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekdays:
            var candidate = calendar.date(byAdding: .day, value: 1, to: date)
            var guardCount = 0
            while let c = candidate, guardCount < 10 {
                let weekday = calendar.component(.weekday, from: c)
                if weekday != 1 && weekday != 7 { return c }
                candidate = calendar.date(byAdding: .day, value: 1, to: c)
                guardCount += 1
            }
            return candidate
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date)
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        }
    }
}

// MARK: - Подзадача

struct Subtask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String = ""
    var isDone: Bool = false
}

// MARK: - Задача

struct TaskItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var dueDate: Date?
    var duration: Int = 30
    var priority: TaskPriority = .normal
    var categoryID: UUID?
    var subtasks: [Subtask] = []
    var reminderDate: Date?
    var recurrence: Recurrence = .never
    var isCompleted: Bool = false
    var completedAt: Date?
    var createdAt: Date = Date()
    var focusMinutes: Int = 0
    var sortIndex: Int = 0

    var endDate: Date? {
        guard let dueDate = dueDate else { return nil }
        return dueDate.addingTimeInterval(Double(duration) * 60)
    }

    var subtaskProgress: Double {
        guard !subtasks.isEmpty else { return isCompleted ? 1 : 0 }
        let done = subtasks.filter { $0.isDone }.count
        return Double(done) / Double(subtasks.count)
    }

    var doneSubtasks: Int {
        subtasks.filter { $0.isDone }.count
    }

    var isOverdue: Bool {
        guard !isCompleted, let dueDate = dueDate else { return false }
        return (endDate ?? dueDate) < Date()
    }

    var plannedMinutes: Int {
        max(5, duration)
    }

    static func sorted(_ items: [TaskItem]) -> [TaskItem] {
        items.sorted { lhs, rhs in
            if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                if l != r { return l < r }
            case (nil, .some):
                return false
            case (.some, nil):
                return true
            case (nil, nil):
                break
            }
            if lhs.priority.weight != rhs.priority.weight {
                return lhs.priority.weight > rhs.priority.weight
            }
            return lhs.createdAt < rhs.createdAt
        }
    }
}

// MARK: - Категория

struct TaskCategory: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var colorHex: String = "#7C6EEB"
    var symbol: String = "circle"
    var order: Int = 0
}

// MARK: - Событие календаря

struct CalendarEvent: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var start: Date = Date()
    var end: Date = Date().addingTimeInterval(3600)
    var categoryID: UUID?
    var isAllDay: Bool = false
    var location: String = ""

    var durationMinutes: Int {
        max(5, Int(end.timeIntervalSince(start) / 60))
    }
}

// MARK: - Привычки

enum HabitKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case daily
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Ежедневно"
        case .weekly: return "По неделям"
        }
    }
}

struct Habit: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String = ""
    var symbol: String = "leaf"
    var colorHex: String = "#5EEAD4"
    var kind: HabitKind = .daily
    var targetPerWeek: Int = 7
    var createdAt: Date = Date()
    /// Ключи дней в формате yyyy-MM-dd.
    var completions: [String] = []
    var isArchived: Bool = false
    var order: Int = 0

    func isDone(on day: Date) -> Bool {
        completions.contains(day.dayKey)
    }

    func completions(inWeekOf day: Date, calendar: Calendar) -> Int {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: day) else { return 0 }
        return completions.filter { key in
            guard let parsed = Date.from(dayKey: key) else { return false }
            return parsed >= interval.start && parsed < interval.end
        }.count
    }
}

// MARK: - Фокус

enum FocusPhase: String, Codable, CaseIterable, Identifiable, Hashable {
    case focus
    case shortBreak
    case longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: return "Фокус"
        case .shortBreak: return "Короткий перерыв"
        case .longBreak: return "Длинный перерыв"
        }
    }

    var shortTitle: String {
        switch self {
        case .focus: return "Фокус"
        case .shortBreak: return "Пауза"
        case .longBreak: return "Отдых"
        }
    }

    var symbol: String {
        switch self {
        case .focus: return "bolt.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.stars.fill"
        }
    }
}

struct FocusSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var taskID: UUID?
    var startedAt: Date = Date()
    var minutes: Int = 25
    var phase: FocusPhase = .focus
    var completed: Bool = true

    var isFocus: Bool { phase == .focus }
}

// MARK: - Настройки

enum AppearanceMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Как в системе"
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

enum AccentTheme: String, Codable, CaseIterable, Identifiable, Hashable {
    case violet
    case mint
    case ember
    case ocean

    var id: String { rawValue }

    var title: String {
        switch self {
        case .violet: return "Violet"
        case .mint: return "Mint"
        case .ember: return "Ember"
        case .ocean: return "Ocean"
        }
    }

    var mainHex: String {
        switch self {
        case .violet: return "#7C6EEB"
        case .mint: return "#2FB9A6"
        case .ember: return "#E9733F"
        case .ocean: return "#3B82F6"
        }
    }

    var softHex: String {
        switch self {
        case .violet: return "#B9B0FF"
        case .mint: return "#7FE3D4"
        case .ember: return "#FFB08A"
        case .ocean: return "#8CC0FF"
        }
    }
}

struct PulseSettings: Codable, Hashable {
    var userName: String = ""
    var appearance: AppearanceMode = .system
    var accent: AccentTheme = .violet
    var focusLength: Int = 25
    var shortBreak: Int = 5
    var longBreak: Int = 15
    var sessionsBeforeLongBreak: Int = 4
    var weekStartsMonday: Bool = true
    /// Номера дней недели (1 — воскресенье), которые считаются днями отдыха.
    var restWeekdays: [Int] = [1]
    var dailyGoalMinutes: Int = 240
    var weeklyGoalTasks: Int = 25
    var remindersEnabled: Bool = true
    var hasOnboarded: Bool = false
    var hasSeededDemo: Bool = false
    /// Дни, отмеченные как «восстановленные» — не рвут серию.
    var repairedDays: [String] = []
    var bestFocusStreak: Int = 0
}

// MARK: - Достижения

struct Achievement: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var title: String = ""
    var detail: String = ""
    var symbol: String = "flame.fill"
    var threshold: Int = 7
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }
}

// MARK: - Впечатление о дне

struct DailyReflection: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var dayKey: String = ""
    var score: Int = 0
    var word: String = ""
    var text: String = ""
    var updatedAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id
        case dayKey
        case score
        case word
        case text
        case updatedAt
    }

    init() {}

    init(
        id: UUID = UUID(),
        dayKey: String = "",
        score: Int = 0,
        word: String = "",
        text: String = "",
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dayKey = dayKey
        self.score = score
        self.word = word
        self.text = text
        self.updatedAt = updatedAt
    }

    /// Новое поле не должно ломать уже сохранённые впечатления.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        dayKey = (try? container.decode(String.self, forKey: .dayKey)) ?? ""
        score = (try? container.decode(Int.self, forKey: .score)) ?? 0
        word = (try? container.decode(String.self, forKey: .word)) ?? ""
        text = (try? container.decode(String.self, forKey: .text)) ?? ""
        updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? Date()
    }

    var day: Date {
        Date.from(dayKey: dayKey) ?? Date()
    }

    var isFilled: Bool {
        score > 0
            || !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var scoreColorKey: String {
        switch score {
        case 0..<35: return "danger"
        case 35..<60: return "amber"
        case 60..<80: return "sky"
        default: return "mint"
        }
    }
}

// MARK: - Серия

struct StreakStats {
    var current: Int = 0
    var longest: Int = 0
    var todayActive: Bool = false
    var isRestDay: Bool = false
    var activeDays: Set<String> = []
    var repairedDays: Set<String> = []
    var lastActiveDay: Date?
    /// Ключ дня, который можно «спасти», если серия под угрозой.
    var rescueableDay: Date?

    var isAtRisk: Bool {
        !todayActive && !isRestDay && current > 0
    }
}

// MARK: - Статистика

struct DayStat: Identifiable, Hashable {
    var day: Date
    var completed: Int
    var planned: Int
    var plannedMinutes: Int
    var actualMinutes: Int
    var focusMinutes: Int

    var id: Date { day }
}

struct CategoryStat: Identifiable, Hashable {
    var id: UUID
    var name: String
    var colorHex: String
    var minutes: Int
    var tasks: Int
}

struct StatsSnapshot {
    var completed: Int = 0
    var created: Int = 0
    var focusMinutes: Int = 0
    var plannedMinutes: Int = 0
    var actualMinutes: Int = 0
    var overdue: Int = 0
    var days: [DayStat] = []
    var categories: [CategoryStat] = []

    var completionRate: Double {
        guard created > 0 else { return completed > 0 ? 1 : 0 }
        return min(1, Double(completed) / Double(created))
    }

    var averagePerDay: Double {
        guard !days.isEmpty else { return 0 }
        return Double(completed) / Double(days.count)
    }

    var bestDay: DayStat? {
        days.max { $0.completed < $1.completed }
    }
}

// MARK: - Временные блоки (таймлайн дня)

enum TimeBlockKind: String, Codable, Hashable {
    case event
    case task
    case free
}

struct TimeBlock: Identifiable, Hashable {
    var id: UUID
    var kind: TimeBlockKind
    var title: String
    var start: Date
    var end: Date
    var colorHex: String
    var isDone: Bool = false
}

// MARK: - Уровни продуктивности дня

enum DayLoad: String, Codable, Hashable {
    case empty
    case light
    case medium
    case busy
    case overloaded

    var title: String {
        switch self {
        case .empty: return "Свободно"
        case .light: return "Легкий день"
        case .medium: return "Средняя загрузка"
        case .busy: return "Плотный день"
        case .overloaded: return "Перегруз"
        }
    }
}

// MARK: - Вкладки

enum PulseTab: String, CaseIterable, Identifiable, Hashable {
    case today
    case calendar
    case tasks
    case focus
    case insights
    case streak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Сегодня"
        case .calendar: return "Календарь"
        case .tasks: return "Задачи"
        case .focus: return "Фокус"
        case .insights: return "Аналитика"
        case .streak: return "Серия"
        }
    }

    var symbol: String {
        switch self {
        case .today: return "sun.max"
        case .calendar: return "calendar"
        case .tasks: return "checklist"
        case .focus: return "timer"
        case .insights: return "chart.bar.xaxis"
        case .streak: return "flame"
        }
    }

    var filledSymbol: String {
        switch self {
        case .today: return "sun.max.fill"
        case .calendar: return "calendar"
        case .tasks: return "checklist"
        case .focus: return "timer"
        case .insights: return "chart.bar.xaxis"
        case .streak: return "flame.fill"
        }
    }

    static var phoneTabs: [PulseTab] {
        [.today, .calendar, .tasks, .focus, .insights]
    }
}

// MARK: - Быстрые списки задач

enum SmartList: String, CaseIterable, Identifiable, Hashable {
    case today
    case tomorrow
    case week
    case overdue
    case someday
    case completed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Сегодня"
        case .tomorrow: return "Завтра"
        case .week: return "На неделе"
        case .overdue: return "Просрочено"
        case .someday: return "Без даты"
        case .completed: return "Выполнено"
        }
    }

    var symbol: String {
        switch self {
        case .today: return "sun.max"
        case .tomorrow: return "sunrise"
        case .week: return "calendar.badge.clock"
        case .overdue: return "exclamationmark.triangle"
        case .someday: return "tray"
        case .completed: return "checkmark.circle"
        }
    }
}
