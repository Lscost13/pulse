//
//  DateUtils.swift
//  PULSE
//
//  Русские даты без зависимости от системной локали: наборы названий
//  и форматтеры держим сами, чтобы вид был предсказуемым.
//

import Foundation

enum RuCal {
    static let locale = Locale(identifier: "ru_RU")

    static let weekdaysShort: [String] = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
    static let weekdaysFull: [String] = [
        "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"
    ]
    static let weekdaysGenitive: [String] = [
        "понедельника", "вторника", "среды", "четверга", "пятницы", "субботы", "воскресенья"
    ]
    static let monthsNominative: [String] = [
        "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
        "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"
    ]
    static let monthsGenitive: [String] = [
        "января", "февраля", "марта", "апреля", "мая", "июня",
        "июля", "августа", "сентября", "октября", "ноября", "декабря"
    ]
    static let monthsShort: [String] = [
        "янв", "фев", "мар", "апр", "май", "июн",
        "июл", "авг", "сен", "окт", "ноя", "дек"
    ]
}

enum PulseDate {
    static func calendar(firstWeekdayMonday: Bool) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = RuCal.locale
        cal.timeZone = TimeZone.current
        cal.firstWeekday = firstWeekdayMonday ? 2 : 1
        cal.minimumDaysInFirstWeek = 4
        return cal
    }

    static var defaultCalendar: Calendar {
        calendar(firstWeekdayMonday: true)
    }

    static func today(calendar: Calendar = PulseDate.defaultCalendar) -> Date {
        calendar.startOfDay(for: Date())
    }

    /// Все дни календарной сетки месяца (6 недель, начиная с первого дня недели).
    static func monthGrid(for month: Date, calendar: Calendar) -> [Date] {
        let start = monthStart(month, calendar: calendar)
        let weekdayOffset = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        let gridStart = calendar.date(byAdding: .day, value: -weekdayOffset, to: start) ?? start
        var days: [Date] = []
        days.reserveCapacity(42)
        for index in 0..<42 {
            if let day = calendar.date(byAdding: .day, value: index, to: gridStart) {
                days.append(calendar.startOfDay(for: day))
            }
        }
        return days
    }

    /// Дни одной недели, содержащей дату.
    static func week(of date: Date, calendar: Calendar) -> [Date] {
        let start = weekStart(of: date, calendar: calendar)
        var days: [Date] = []
        for index in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: index, to: start) {
                days.append(calendar.startOfDay(for: day))
            }
        }
        return days
    }

    static func monthStart(_ date: Date, calendar: Calendar) -> Date {
        let interval = calendar.dateInterval(of: .month, for: date)
        return calendar.startOfDay(for: interval?.start ?? date)
    }

    static func weekStart(of date: Date, calendar: Calendar) -> Date {
        let interval = calendar.dateInterval(of: .weekOfYear, for: date)
        return calendar.startOfDay(for: interval?.start ?? date)
    }

    static func hoursBetween(_ start: Date, _ end: Date) -> Double {
        end.timeIntervalSince(start) / 3600
    }

    static func minutesBetween(_ start: Date, _ end: Date) -> Int {
        max(0, Int(end.timeIntervalSince(start) / 60))
    }

    /// Человеческое «1 ч 20 мин».
    static func durationText(minutes: Int) -> String {
        let mins = max(0, minutes)
        let hours = mins / 60
        let rest = mins % 60
        if hours == 0 { return "\(rest) мин" }
        if rest == 0 { return "\(hours) ч" }
        return "\(hours) ч \(rest) мин"
    }

    static func durationShort(minutes: Int) -> String {
        let mins = max(0, minutes)
        if mins < 60 { return "\(mins)м" }
        let hours = mins / 60
        let rest = mins % 60
        return rest == 0 ? "\(hours)ч" : "\(hours)ч \(rest)м"
    }

    static func timeText(hour: Int, minute: Int = 0) -> String {
        String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - Форматтеры

enum PulseFormatters {
    static let dayKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = RuCal.locale
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

// MARK: - Расширения даты

extension Date {
    var dayKey: String {
        PulseFormatters.dayKey.string(from: self)
    }

    var timeString: String {
        PulseFormatters.time.string(from: self)
    }

    static func from(dayKey: String) -> Date? {
        PulseFormatters.dayKey.date(from: dayKey)
    }

    func startOfDay(calendar: Calendar = PulseDate.defaultCalendar) -> Date {
        calendar.startOfDay(for: self)
    }

    func adding(days: Int, calendar: Calendar = PulseDate.defaultCalendar) -> Date {
        calendar.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(minutes: Int, calendar: Calendar = PulseDate.defaultCalendar) -> Date {
        calendar.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    func isSameDay(as other: Date, calendar: Calendar = PulseDate.defaultCalendar) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }

    var isToday: Bool {
        isSameDay(as: Date())
    }

    /// 0 — понедельник, 6 — воскресенье.
    var ruWeekdayIndex: Int {
        let weekday = PulseDate.defaultCalendar.component(.weekday, from: self)
        return (weekday + 5) % 7
    }

    /// Номер дня недели по Calendar (1 — воскресенье).
    var weekdayNumber: Int {
        PulseDate.defaultCalendar.component(.weekday, from: self)
    }

    var weekdayShort: String {
        RuCal.weekdaysShort[ruWeekdayIndex]
    }

    var weekdayFull: String {
        RuCal.weekdaysFull[ruWeekdayIndex]
    }

    var monthIndex: Int {
        PulseDate.defaultCalendar.component(.month, from: self) - 1
    }

    var monthName: String {
        RuCal.monthsNominative[safe: monthIndex] ?? ""
    }

    var monthNameGenitive: String {
        RuCal.monthsGenitive[safe: monthIndex] ?? ""
    }

    var monthShortName: String {
        RuCal.monthsShort[safe: monthIndex] ?? ""
    }

    var dayNumber: Int {
        PulseDate.defaultCalendar.component(.day, from: self)
    }

    var yearNumber: Int {
        PulseDate.defaultCalendar.component(.year, from: self)
    }

    /// «8 ноября»
    var dayMonthTitle: String {
        "\(dayNumber) \(monthNameGenitive)"
    }

    /// «8 ноября, суббота»
    var longDateTitle: String {
        "\(dayNumber) \(monthNameGenitive), \(weekdayFull.lowercased())"
    }

    /// «Ноябрь 2026»
    var monthYearTitle: String {
        "\(monthName) \(yearNumber)"
    }

    /// «ноя 2026»
    var shortMonthYearTitle: String {
        "\(monthShortName) \(yearNumber)"
    }

    var isWeekend: Bool {
        weekdayNumber == 1 || weekdayNumber == 7
    }

    var hour: Int {
        PulseDate.defaultCalendar.component(.hour, from: self)
    }

    var minute: Int {
        PulseDate.defaultCalendar.component(.minute, from: self)
    }

    /// Округление до получаса — удобно для быстрого создания задач.
    func roundedToHalfHour(calendar: Calendar = PulseDate.defaultCalendar) -> Date {
        let minutes = calendar.component(.minute, from: self)
        let rounded = minutes < 30 ? 0 : 30
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: self)
        components.minute = rounded
        return calendar.date(from: components) ?? self
    }

    func combiningTime(hour: Int, minute: Int, calendar: Calendar = PulseDate.defaultCalendar) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: self)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? self
    }

    func dateAtStartOfDay(calendar: Calendar = PulseDate.defaultCalendar) -> Date {
        calendar.startOfDay(for: self)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
