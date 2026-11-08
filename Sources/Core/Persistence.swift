//
//  Persistence.swift
//  PULSE
//
//  Простое и надёжное локальное хранилище: один JSON-снапшот в
//  Application Support. Никаких сетевых зависимостей.
//

import Foundation

struct AppSnapshot: Codable {
    var schemaVersion: Int = 1
    var tasks: [TaskItem] = []
    var events: [CalendarEvent] = []
    var habits: [Habit] = []
    var sessions: [FocusSession] = []
    var categories: [TaskCategory] = []
    var achievements: [Achievement] = []
    var settings: PulseSettings = PulseSettings()
}

enum Persistence {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("PULSE", isDirectory: true)
    }

    static var fileURL: URL {
        directory.appendingPathComponent("store.json")
    }

    static func load() -> AppSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try? decoder.decode(AppSnapshot.self, from: data)
    }

    static func save(_ snapshot: AppSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            #if DEBUG
            print("PULSE: не удалось сохранить данные — \(error)")
            #endif
        }
    }

    static func wipe() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
