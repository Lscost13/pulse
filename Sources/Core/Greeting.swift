//
//  Greeting.swift
//  PULSE
//

import Foundation

enum PulseGreeting {
    static func timeOfDay(date: Date = Date()) -> String {
        let hour = PulseDate.defaultCalendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Доброе утро"
        case 12..<18: return "Добрый день"
        case 18..<23: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }

    static func text(name: String, date: Date = Date()) -> String {
        let base = timeOfDay(date: date)
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return base }
        return "\(base), \(name)"
    }

    static func shortName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "друг" : trimmed
    }
}
