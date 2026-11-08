//
//  StreakEngine.swift
//  PULSE
//
//  Серия дней. Принцип: мотивировать, но не наказывать — дни отдыха
//  не рвут серию, пропуск можно «восстановить».
//

import Foundation

enum StreakEngine {

    static func dayIsRest(_ day: Date, settings: PulseSettings) -> Bool {
        settings.restWeekdays.contains(day.weekdayNumber)
    }

    static func activeKeys(
        tasks: [TaskItem],
        habits: [Habit],
        sessions: [FocusSession]
    ) -> Set<String> {
        var keys = Set<String>()
        for task in tasks where task.isCompleted {
            if let date = task.completedAt {
                keys.insert(date.dayKey)
            }
        }
        for habit in habits {
            for key in habit.completions {
                keys.insert(key)
            }
        }
        for session in sessions where session.isFocus && session.completed && session.minutes >= 10 {
            keys.insert(session.startedAt.dayKey)
        }
        return keys
    }

    static func compute(
        tasks: [TaskItem],
        habits: [Habit],
        sessions: [FocusSession],
        settings: PulseSettings,
        reference: Date,
        calendar: Calendar
    ) -> StreakStats {
        var stats = StreakStats()

        let active = activeKeys(tasks: tasks, habits: habits, sessions: sessions)
        let repaired = Set(settings.repairedDays)
        var effective = active
        effective.formUnion(repaired)
        stats.activeDays = active
        stats.repairedDays = repaired

        let today = calendar.startOfDay(for: reference)
        stats.todayActive = effective.contains(today.dayKey)
        stats.isRestDay = dayIsRest(today, settings: settings)

        if let lastKey = effective.compactMap({ Date.from(dayKey: $0) }).max() {
            stats.lastActiveDay = calendar.startOfDay(for: lastKey)
        }

        // Текущая серия: сегодня может быть ещё «в процессе», поэтому
        // начинаем отсчёт с сегодня, если он закрыт, иначе — со вчера.
        var cursor = today
        if !stats.todayActive && !stats.isRestDay {
            cursor = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }

        var current = 0
        var guardCounter = 0
        while guardCounter < 1500 {
            guardCounter += 1
            let key = cursor.dayKey
            if effective.contains(key) {
                current += 1
            } else if dayIsRest(cursor, settings: settings) {
                // отдых — просто пропускаем
            } else {
                break
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        stats.current = current

        // Самая длинная серия: идём от первого активного дня до сегодня.
        let allKeys = effective.compactMap { Date.from(dayKey: $0) }.map { calendar.startOfDay(for: $0) }
        if let first = allKeys.min() {
            var longest = 0
            var run = 0
            var day = first
            var limit = 0
            while day <= today && limit < 3000 {
                limit += 1
                if effective.contains(day.dayKey) {
                    run += 1
                    longest = max(longest, run)
                } else if !dayIsRest(day, settings: settings) {
                    run = 0
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            stats.longest = max(longest, stats.current)
        } else {
            stats.longest = 0
        }

        // День, который можно восстановить: ближайший пропуск перед серией.
        var probe = today
        if !stats.todayActive && !stats.isRestDay {
            probe = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }
        var steps = 0
        while steps < 60 {
            steps += 1
            let isActive = effective.contains(probe.dayKey)
            let isRest = dayIsRest(probe, settings: settings)
            if !isActive && !isRest {
                // если раньше были активные дни — этот пропуск «спасаемый»
                var back = calendar.date(byAdding: .day, value: -1, to: probe)
                var look = 0
                var hasHistory = false
                while let b = back, look < 10 {
                    look += 1
                    if effective.contains(b.dayKey) { hasHistory = true; break }
                    if dayIsRest(b, settings: settings) {
                        back = calendar.date(byAdding: .day, value: -1, to: b)
                        continue
                    }
                    break
                }
                if hasHistory {
                    stats.rescueableDay = probe
                }
                break
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: probe) else { break }
            probe = previous
        }

        return stats
    }

    /// Тепловая карта: сколько «очков» активности в день.
    static func activityScore(
        for day: Date,
        tasks: [TaskItem],
        sessions: [FocusSession],
        calendar: Calendar
    ) -> Int {
        let done = tasks.filter { task in
            guard task.isCompleted, let completed = task.completedAt else { return false }
            return calendar.isDate(completed, inSameDayAs: day)
        }.count
        let focus = sessions
            .filter { $0.isFocus && $0.completed && calendar.isDate($0.startedAt, inSameDayAs: day) }
            .reduce(0) { $0 + $1.minutes } / 25
        return done + focus
    }
}
