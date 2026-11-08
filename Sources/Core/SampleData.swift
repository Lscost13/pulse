//
//  SampleData.swift
//  PULSE
//
//  Демо-набор: приложение должно встречать пользователя живым
//  интерфейсом, а не пустыми списками.
//

import Foundation

enum SampleData {

    static let cal = PulseDate.calendar(firstWeekdayMonday: true)

    // MARK: - Стабильные идентификаторы

    private static func uid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012ld", value)) ?? UUID()
    }

    static func day(_ offset: Int) -> Date {
        let today = cal.startOfDay(for: Date())
        return cal.date(byAdding: .day, value: offset, to: today) ?? today
    }

    static func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        day(dayOffset).combiningTime(hour: hour, minute: minute, calendar: cal)
    }

    // MARK: - Категории

    static func defaultCategories() -> [TaskCategory] {
        [
            TaskCategory(id: uid(1), name: "Работа", colorHex: "#7C6EEB", symbol: "briefcase.fill", order: 0),
            TaskCategory(id: uid(2), name: "Личное", colorHex: "#5EEAD4", symbol: "sparkles", order: 1),
            TaskCategory(id: uid(3), name: "Здоровье", colorHex: "#34D399", symbol: "heart.fill", order: 2),
            TaskCategory(id: uid(4), name: "Учёба", colorHex: "#F59E0B", symbol: "book.fill", order: 3),
            TaskCategory(id: uid(5), name: "Дом", colorHex: "#F472B6", symbol: "house.fill", order: 4)
        ]
    }

    static func achievementCatalog() -> [Achievement] {
        [
            Achievement(id: "streak.3", title: "Первый импульс", detail: "3 дня подряд", symbol: "bolt.fill", threshold: 3),
            Achievement(id: "streak.7", title: "Неделя силы", detail: "7 дней подряд", symbol: "flame.fill", threshold: 7),
            Achievement(id: "streak.14", title: "Ритм", detail: "14 дней подряд", symbol: "waveform.path.ecg", threshold: 14),
            Achievement(id: "streak.30", title: "Месяц дисциплины", detail: "30 дней подряд", symbol: "crown.fill", threshold: 30),
            Achievement(id: "streak.60", title: "Стальной курс", detail: "60 дней подряд", symbol: "shield.lefthalf.filled", threshold: 60),
            Achievement(id: "streak.100", title: "Сотня", detail: "100 дней подряд", symbol: "trophy.fill", threshold: 100),
            Achievement(id: "streak.365", title: "Год с PULSE", detail: "365 дней подряд", symbol: "star.circle.fill", threshold: 365)
        ]
    }

    // MARK: - Снапшот

    static func make() -> AppSnapshot {
        let categories = defaultCategories()
        let work = categories[0].id
        let personal = categories[1].id
        let health = categories[2].id
        let study = categories[3].id
        let home = categories[4].id

        var tasks: [TaskItem] = []
        var seed = 100

        func task(
            _ title: String,
            dayOffset: Int?,
            hour: Int = 10,
            minute: Int = 0,
            duration: Int = 30,
            priority: TaskPriority = .normal,
            category: UUID?,
            notes: String = "",
            completed: Bool = false,
            completedDaysAgo: Int? = nil,
            subtasks: [String] = [],
            recurrence: Recurrence = .never
        ) -> TaskItem {
            seed += 1
            var due: Date?
            if let offset = dayOffset {
                due = at(offset, hour, minute)
            }
            let completionDate: Date? = completed
                ? (completedDaysAgo.map { at(-$0, max(9, hour + 1), 15) } ?? (due?.addingTimeInterval(3600) ?? Date()))
                : nil
            return TaskItem(
                id: uid(seed),
                title: title,
                notes: notes,
                dueDate: due,
                duration: duration,
                priority: priority,
                categoryID: category,
                subtasks: subtasks.map { Subtask(id: uid(seed * 10 + (subtasks.firstIndex(of: $0) ?? 0)), title: $0) },
                reminderDate: nil,
                recurrence: recurrence,
                isCompleted: completed,
                completedAt: completionDate,
                createdAt: at((dayOffset ?? 0) - 2, 9, 0),
                focusMinutes: completed ? duration : 0,
                sortIndex: seed
            )
        }

        // Сегодня
        tasks.append(task("Собрать финальный макет Today", dayOffset: 0, hour: 9, minute: 0, duration: 90,
                          priority: .critical, category: work,
                          notes: "Довести до состояния, в котором не стыдно показать команде.",
                          completed: true, completedDaysAgo: 0,
                          subtasks: ["Сетка и отступы", "Прогресс-кольцо", "Таймлайн дня"]))
        tasks.append(task("Ревью пул-реквеста", dayOffset: 0, hour: 11, minute: 0, duration: 45,
                          priority: .high, category: work, completed: true, completedDaysAgo: 0))
        tasks.append(task("Созвон с командой дизайна", dayOffset: 0, hour: 16, minute: 0, duration: 60,
                          priority: .high, category: work,
                          notes: "Обсудить визуальную иерархию карточек и анимации переходов.",
                          subtasks: ["Показать прототип", "Собрать правки"]))
        tasks.append(task("Ответить на письма", dayOffset: 0, hour: 14, minute: 0, duration: 30,
                          priority: .low, category: work))
        tasks.append(task("Прогулка 30 минут", dayOffset: 0, hour: 19, minute: 0, duration: 30,
                          priority: .normal, category: health))
        tasks.append(task("Прочитать главу «Дизайн привычек»", dayOffset: 0, hour: 21, minute: 0, duration: 40,
                          priority: .normal, category: study))
        tasks.append(task("Полить растения", dayOffset: 0, hour: 20, minute: 30, duration: 15,
                          priority: .low, category: home, completed: true, completedDaysAgo: 0))

        // Завтра
        tasks.append(task("Планёрка недели", dayOffset: 1, hour: 10, minute: 0, duration: 30,
                          priority: .high, category: work))
        tasks.append(task("Черновик дизайн-системы", dayOffset: 1, hour: 12, minute: 0, duration: 120,
                          priority: .critical, category: work,
                          notes: "Цвета, типографика, радиусы, тени.",
                          subtasks: ["Токены цвета", "Типографическая шкала", "Тени и свечения"]))
        tasks.append(task("Тренировка", dayOffset: 1, hour: 19, minute: 30, duration: 60,
                          priority: .normal, category: health))

        // На неделе
        tasks.append(task("Подготовить презентацию", dayOffset: 2, hour: 15, minute: 0, duration: 90,
                          priority: .high, category: work,
                          subtasks: ["Структура", "Слайды", "Репетиция"]))
        tasks.append(task("Купить продукты", dayOffset: 3, hour: 18, minute: 0, duration: 45,
                          priority: .low, category: home))
        tasks.append(task("Английский: эссе", dayOffset: 4, hour: 20, minute: 0, duration: 45,
                          priority: .normal, category: study))
        tasks.append(task("Встреча с ментором", dayOffset: 5, hour: 11, minute: 0, duration: 60,
                          priority: .high, category: personal))

        // Просроченные
        tasks.append(task("Отправить счёт", dayOffset: -2, hour: 12, minute: 0, duration: 20,
                          priority: .critical, category: work))
        tasks.append(task("Записаться к стоматологу", dayOffset: -1, hour: 10, minute: 0, duration: 15,
                          priority: .normal, category: health))

        // Без даты
        tasks.append(task("Разобрать архив заметок", dayOffset: nil, duration: 60,
                          priority: .low, category: personal))
        tasks.append(task("Идеи для отпуска", dayOffset: nil, duration: 30,
                          priority: .low, category: personal))
        tasks.append(task("Обновить портфолио", dayOffset: nil, duration: 90,
                          priority: .normal, category: work))

        // Прошлые дни — для графиков и серии
        tasks.append(task("Итерация главного экрана", dayOffset: -1, hour: 10, minute: 0, duration: 90,
                          priority: .high, category: work, completed: true, completedDaysAgo: 1))
        tasks.append(task("Йога", dayOffset: -1, hour: 8, minute: 0, duration: 30,
                          priority: .normal, category: health, completed: true, completedDaysAgo: 1))
        tasks.append(task("Разбор бэклога", dayOffset: -2, hour: 11, minute: 0, duration: 60,
                          priority: .normal, category: work, completed: true, completedDaysAgo: 2))
        tasks.append(task("Чтение", dayOffset: -2, hour: 21, minute: 0, duration: 30,
                          priority: .low, category: study, completed: true, completedDaysAgo: 2))
        tasks.append(task("Спринт-ревью", dayOffset: -3, hour: 15, minute: 0, duration: 60,
                          priority: .high, category: work, completed: true, completedDaysAgo: 3))
        tasks.append(task("Уборка", dayOffset: -3, hour: 19, minute: 0, duration: 45,
                          priority: .low, category: home, completed: true, completedDaysAgo: 3))
        tasks.append(task("Прототип Focus", dayOffset: -4, hour: 10, minute: 0, duration: 120,
                          priority: .critical, category: work, completed: true, completedDaysAgo: 4))
        tasks.append(task("Пробежка", dayOffset: -4, hour: 7, minute: 30, duration: 40,
                          priority: .normal, category: health, completed: true, completedDaysAgo: 4))
        tasks.append(task("Тексты для онбординга", dayOffset: -5, hour: 13, minute: 0, duration: 60,
                          priority: .normal, category: work, completed: true, completedDaysAgo: 5))
        tasks.append(task("Позвонить родителям", dayOffset: -6, hour: 20, minute: 0, duration: 30,
                          priority: .high, category: personal, completed: true, completedDaysAgo: 6))
        tasks.append(task("Настроить аналитику", dayOffset: -7, hour: 12, minute: 0, duration: 90,
                          priority: .normal, category: work, completed: true, completedDaysAgo: 7))
        tasks.append(task("Медитация", dayOffset: -7, hour: 8, minute: 0, duration: 15,
                          priority: .low, category: health, completed: true, completedDaysAgo: 7))

        // События
        var events: [CalendarEvent] = []
        let eventSeeds: [(String, Int, Int, Int, Int, UUID, String)] = [
            ("Утренний стендап", 0, 10, 0, 15, work, "Zoom"),
            ("Обед с командой", 0, 13, 0, 60, personal, "Кафе на углу"),
            ("Дизайн-ревью", 0, 17, 30, 45, work, "Переговорная Б"),
            ("Планёрка недели", 1, 10, 0, 30, work, "Zoom"),
            ("Созвон с клиентом", 1, 15, 0, 60, work, ""),
            ("Йога", 1, 20, 0, 60, health, "Студия"),
            ("Презентация концепта", 2, 11, 0, 90, work, "Офис"),
            ("Стоматолог", 3, 9, 30, 60, health, "Клиника"),
            ("Ужин с друзьями", 4, 19, 0, 120, personal, "Город"),
            ("Субботняя прогулка", 5, 12, 0, 90, personal, "Парк"),
            ("Планирование воскресенья", 6, 18, 0, 30, personal, ""),
            ("Ретроспектива", -1, 16, 0, 60, work, "Zoom"),
            ("Митинг по продукту", -2, 14, 0, 45, work, "")
        ]
        var eventSeed = 500
        for (title, offset, hour, minute, duration, category, location) in eventSeeds {
            eventSeed += 1
            let start = at(offset, hour, minute)
            events.append(
                CalendarEvent(
                    id: uid(eventSeed),
                    title: title,
                    notes: "",
                    start: start,
                    end: start.addingTimeInterval(Double(duration) * 60),
                    categoryID: category,
                    isAllDay: false,
                    location: location
                )
            )
        }

        // Привычки
        var habits: [Habit] = []
        let habitSeeds: [(String, String, String, HabitKind, Int, [Int])] = [
            ("Зарядка", "figure.run", "#5EEAD4", .daily, 7, Array(0...13)),
            ("Чтение 20 минут", "book", "#F59E0B", .daily, 7, Array(0...9) + Array(11...16)),
            ("Медитация", "leaf.fill", "#34D399", .daily, 7, Array(0...5) + [7, 8] + [10, 12]),
            ("Английский", "character.book.closed.fill", "#7C6EEB", .weekly, 3, [0, 2, 4, 6, 8, 9, 12]),
            ("Вода 8 стаканов", "drop.fill", "#3B82F6", .daily, 7, Array(0...13))
        ]
        for (index, seedHabit) in habitSeeds.enumerated() {
            let (name, symbol, color, kind, target, offsets) = seedHabit
            habits.append(
                Habit(
                    id: uid(700 + index),
                    name: name,
                    symbol: symbol,
                    colorHex: color,
                    kind: kind,
                    targetPerWeek: target,
                    createdAt: at(-60, 8, 0),
                    completions: offsets.map { day(-$0).dayKey },
                    isArchived: false,
                    order: index
                )
            )
        }

        // Фокус-сессии за последние 3 недели
        var sessions: [FocusSession] = []
        var sessionSeed = 900
        let focusPlan: [(Int, [Int])] = [
            (0, [50, 25]),
            (-1, [25, 25, 50]),
            (-2, [25, 50]),
            (-3, [25]),
            (-4, [50, 25]),
            (-5, [25, 25]),
            (-6, [25]),
            (-7, [50]),
            (-8, [25, 25]),
            (-9, [25]),
            (-10, [50, 25]),
            (-11, [25]),
            (-12, [25, 25, 25]),
            (-13, [50]),
            (-14, [25]),
            (-16, [25, 25]),
            (-18, [50]),
            (-20, [25])
        ]
        for (offset, minutesList) in focusPlan {
            var hour = 10
            for minutes in minutesList {
                sessionSeed += 1
                sessions.append(
                    FocusSession(
                        id: uid(sessionSeed),
                        taskID: nil,
                        startedAt: at(offset, hour, 5),
                        minutes: minutes,
                        phase: .focus,
                        completed: true
                    )
                )
                hour += 2
            }
        }

        var settings = PulseSettings()
        settings.userName = ""
        settings.appearance = .system
        settings.accent = .violet
        settings.hasOnboarded = false
        settings.hasSeededDemo = true
        settings.dailyGoalMinutes = 240
        settings.weeklyGoalTasks = 25
        settings.restWeekdays = [1]

        // Впечатления о прошлых днях — чтобы графики оценок были живыми
        var reflections: [DailyReflection] = []
        let reflectionSeeds: [(Int, Int, String, String)] = [
            (-1, 84, "макет", "День получился плотным, но ровным. Главное — закрыл макет."),
            (-2, 72, "спешка", "Много переключений между задачами, вечером уже не было сил."),
            (-3, 91, "глубина", "Лучший день недели: две глубокие сессии без телефона."),
            (-4, 65, "шум", "Скомкано. Стоило начать с самого сложного, а не с почты."),
            (-5, 78, "прогулка", "Спокойно и по делу. Прогулка вернула голову на место."),
            (-6, 88, "ритм", "Успел всё, что планировал, и даже немного больше."),
            (-7, 54, "сон", "Слабо. Проспал, весь день догонял."),
            (-8, 80, "фокус", "Хороший ритм: фокус с утра, встречи после обеда."),
            (-9, 76, "привычка", "Средний день, но привычки не пропустил."),
            (-10, 92, "контроль", "Ощущение контроля. Редкое и приятное."),
            (-11, 68, "суета", "Много шума, мало глубины."),
            (-12, 74, "стабильность", "Стабильно: задачи, чтение, прогулка.")
        ]
        for (offset, score, word, text) in reflectionSeeds {
            reflections.append(
                DailyReflection(
                    dayKey: day(offset).dayKey,
                    score: score,
                    word: word,
                    text: text,
                    updatedAt: at(offset, 22, 30)
                )
            )
        }

        return AppSnapshot(
            schemaVersion: 2,
            tasks: tasks,
            events: events,
            habits: habits,
            sessions: sessions,
            categories: categories,
            achievements: achievementCatalog(),
            reflections: reflections,
            settings: settings
        )
    }
}
