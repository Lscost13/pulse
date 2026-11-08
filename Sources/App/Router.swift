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

@Observable
final class Router {
    var tab: PulseTab = .today
    var calendarMode: CalendarMode = .month
    var selectedDay: Date = Date().startOfDay()
    var taskEditor: TaskEditorRequest?
    var eventEditor: EventEditorRequest?
    var habitEditor: HabitEditorRequest?
    var showQuickAdd: Bool = false
    var showSettings: Bool = false
    var showStreak: Bool = false
    var showCommandBar: Bool = false
    var smartList: SmartList = .today
    var searchText: String = ""
    var focusTaskID: UUID?
    var padDetailVisible: Bool = true

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
