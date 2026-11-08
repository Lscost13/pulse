//
//  StatsEngine.swift
//  PULSE
//
//  Считаем срезы статистики. Никаких графиков — только числа.
//

import Foundation

enum StatsEngine {

    static func snapshot(
        days: Int,
        endingAt reference: Date,
        tasks: [TaskItem],
        sessions: [FocusSession],
        categories: [TaskCategory],
        calendar: Calendar
    ) -> StatsSnapshot {
        var snapshot = StatsSnapshot()
        let end = calendar.startOfDay(for: reference)
        let safeDays = max(1, min(days, 366))
        guard let start = calendar.date(byAdding: .day, value: -(safeDays - 1), to: end) else {
            return snapshot
        }

        var dayStats: [DayStat] = []
        dayStats.reserveCapacity(safeDays)

        var day = start
        while day <= end {
            let dayTasks = tasks.filter { task in
                guard let due = task.dueDate else { return false }
                return calendar.isDate(due, inSameDayAs: day)
            }
            let completed = tasks.filter { task in
                guard task.isCompleted, let done = task.completedAt else { return false }
                return calendar.isDate(done, inSameDayAs: day)
            }
            let focus = sessions
                .filter { $0.isFocus && $0.completed && calendar.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.minutes }

            let stat = DayStat(
                day: day,
                completed: completed.count,
                planned: dayTasks.count,
                plannedMinutes: dayTasks.reduce(0) { $0 + $1.plannedMinutes },
                actualMinutes: completed.reduce(0) { $0 + $1.plannedMinutes },
                focusMinutes: focus
            )
            dayStats.append(stat)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        snapshot.days = dayStats
        snapshot.completed = dayStats.reduce(0) { $0 + $1.completed }
        snapshot.plannedMinutes = dayStats.reduce(0) { $0 + $1.plannedMinutes }
        snapshot.actualMinutes = dayStats.reduce(0) { $0 + $1.actualMinutes }
        snapshot.focusMinutes = dayStats.reduce(0) { $0 + $1.focusMinutes }

        let createdInRange = tasks.filter { $0.createdAt >= start && $0.createdAt <= reference.addingTimeInterval(86400) }
        snapshot.created = createdInRange.count
        snapshot.overdue = tasks.filter { task in
            guard !task.isCompleted, let due = task.dueDate else { return false }
            return due < reference
        }.count

        // Распределение по категориям — по выполненным задачам.
        let completedInRange = tasks.filter { task in
            guard task.isCompleted, let done = task.completedAt else { return false }
            return done >= start
        }
        var categoryStats: [CategoryStat] = []
        for category in categories {
            let items = completedInRange.filter { $0.categoryID == category.id }
            guard !items.isEmpty else { continue }
            categoryStats.append(
                CategoryStat(
                    id: category.id,
                    name: category.name,
                    colorHex: category.colorHex,
                    minutes: items.reduce(0) { $0 + $1.plannedMinutes },
                    tasks: items.count
                )
            )
        }
        let uncategorized = completedInRange.filter { $0.categoryID == nil }
        if !uncategorized.isEmpty {
            categoryStats.append(
                CategoryStat(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID(),
                    name: "Без категории",
                    colorHex: "#8E8E93",
                    minutes: uncategorized.reduce(0) { $0 + $1.plannedMinutes },
                    tasks: uncategorized.count
                )
            )
        }
        snapshot.categories = categoryStats.sorted { $0.minutes > $1.minutes }
        return snapshot
    }

    /// Данные для тепловой карты за N недель.
    static func heatmap(
        weeks: Int,
        tasks: [TaskItem],
        sessions: [FocusSession],
        calendar: Calendar
    ) -> [HeatmapCell] {
        let today = calendar.startOfDay(for: Date())
        let weekStart = PulseDate.weekStart(of: today, calendar: calendar)
        let totalDays = max(1, weeks) * 7
        guard let firstDay = calendar.date(byAdding: .day, value: -(totalDays - 1), to: weekStart) else {
            return []
        }
        var cells: [HeatmapCell] = []
        var day = firstDay
        while day <= today {
            let score = StreakEngine.activityScore(for: day, tasks: tasks, sessions: sessions, calendar: calendar)
            cells.append(HeatmapCell(day: day, score: score))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return cells
    }
}

struct HeatmapCell: Identifiable, Hashable {
    var day: Date
    var score: Int
    var id: Date { day }

    var level: Int {
        if score <= 0 { return 0 }
        if score <= 2 { return 1 }
        if score <= 4 { return 2 }
        if score <= 6 { return 3 }
        return 4
    }
}
