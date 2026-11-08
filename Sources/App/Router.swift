//
//  Router.swift
//  PULSE
//
//  Навигационное состояние приложения: активная вкладка, выбранный день,
//  редактируемые сущности. Держим отдельно от данных.
//

import Foundation
import Observation
import SwiftUI

enum CalendarMode: String, CaseIterable, Identifiable, Hashable {
    case month
    case week
    case day

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: return "Месяц"
        case .week: return "Неделя"
        case .day: return "День"
        }
    }
}

enum StatsRange: String, CaseIterable, Identifiable, Hashable {
    case week
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .year: return "Год"
        }
    }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }

    var compactDays: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 91
        }
    }
}

struct TaskEditorRequest: Identifiable, Hashable {
    var id: UUID = UUID()
    var task: TaskItem?
    var day: Date?
    var suggestedStart: Date?

    var isNew: Bool { task == nil }
}

struct EventEditorRequest: Identifiable, Hashable {
    var id: UUID = UUID()
    var event: CalendarEvent?
    var day: Date = Date().startOfDay()
}

struct HabitEditorRequest: Identifiable, Hashable {
    var id: UUID = UUID()
    var habit: Habit?
}

/// Один шит на всё приложение. Несколько `.sheet` на одном экране конфликтуют
/// (SwiftUI показывает только один и может вести себя непредсказуемо),
/// поэтому все сценарии идут через единый маршрут.
enum SheetRoute: Identifiable, Hashable {
    case quickAdd
    case settings
    case streak
    case review(Date)
    case task(TaskEditorRequest)
    case event(EventEditorRequest)
    case habit(HabitEditorRequest)

    var id: String {
        switch self {
        case .quickAdd: return "quickAdd"
        case .settings: return "settings"
        case .streak: return "streak"
        case .review(let day): return "review-\(day.dayKey)"
        case .task(let request): return "task-\(request.id.uuidString)"
        case .event(let request): return "event-\(request.id.uuidString)"
        case .habit(let request): return "habit-\(request.id.uuidString)"
        }
    }
}

@Observable
final class Router {
    var tab: PulseTab = .today
    var calendarMode: CalendarMode = .month
    var selectedDay: Date = Date().startOfDay()
    var sheet: SheetRoute?
    var smartList: SmartList = .today
    var searchText: String = ""
    var focusTaskID: UUID?

    // MARK: - Совместимые аксессоры

    var taskEditor: TaskEditorRequest? {
        get {
            if case .task(let request)? = sheet { return request }
            return nil
        }
        set {
            sheet = newValue.map { SheetRoute.task($0) }
        }
    }

    var eventEditor: EventEditorRequest? {
        get {
            if case .event(let request)? = sheet { return request }
            return nil
        }
        set {
            sheet = newValue.map { SheetRoute.event($0) }
        }
    }

    var habitEditor: HabitEditorRequest? {
        get {
            if case .habit(let request)? = sheet { return request }
            return nil
        }
        set {
            sheet = newValue.map { SheetRoute.habit($0) }
        }
    }

    var showQuickAdd: Bool {
        get {
            if case .quickAdd? = sheet { return true }
            return false
        }
        set {
            if newValue {
                sheet = .quickAdd
            } else if case .quickAdd? = sheet {
                sheet = nil
            }
        }
    }

    var showSettings: Bool {
        get {
            if case .settings? = sheet { return true }
            return false
        }
        set {
            if newValue {
                sheet = .settings
            } else if case .settings? = sheet {
                sheet = nil
            }
        }
    }

    var showStreak: Bool {
        get {
            if case .streak? = sheet { return true }
            return false
        }
        set {
            if newValue {
                sheet = .streak
            } else if case .streak? = sheet {
                sheet = nil
            }
        }
    }

    func openNewTask(day: Date? = nil, start: Date? = nil) {
        taskEditor = TaskEditorRequest(task: nil, day: day, suggestedStart: start)
    }

    func openTask(_ task: TaskItem) {
        taskEditor = TaskEditorRequest(task: task, day: task.dueDate, suggestedStart: task.dueDate)
    }

    func openNewEvent(day: Date) {
        eventEditor = EventEditorRequest(event: nil, day: day)
    }

    func openEvent(_ event: CalendarEvent) {
        eventEditor = EventEditorRequest(event: event, day: event.start)
    }

    func openReview(day: Date) {
        sheet = .review(day.startOfDay())
    }

    func openNewHabit() {
        habitEditor = HabitEditorRequest(habit: nil)
    }

    func openHabit(_ habit: Habit) {
        habitEditor = HabitEditorRequest(habit: habit)
    }

    func goToDay(_ day: Date, tab: PulseTab = .today) {
        selectedDay = day.startOfDay()
        self.tab = tab
    }

    func showTasks(_ list: SmartList) {
        smartList = list
        tab = .tasks
    }
}

extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
