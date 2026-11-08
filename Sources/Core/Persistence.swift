//
//  Persistence.swift
//  PULSE
//
//  Простое и надёжное локальное хранилище: один JSON-снапшот в
//  Application Support. Никаких сетевых зависимостей.
//
//  Декодер написан вручную: новое поле не должно ломать уже
//  сохранённые данные — отсутствующие ключи берут значения по умолчанию.
//

import Foundation

struct AppSnapshot: Codable {
    var schemaVersion: Int
    var tasks: [TaskItem]
    var events: [CalendarEvent]
    var habits: [Habit]
    var sessions: [FocusSession]
    var categories: [TaskCategory]
    var achievements: [Achievement]
    var reflections: [DailyReflection]
    var settings: PulseSettings

    init(
        schemaVersion: Int = 2,
        tasks: [TaskItem] = [],
        events: [CalendarEvent] = [],
        habits: [Habit] = [],
        sessions: [FocusSession] = [],
        categories: [TaskCategory] = [],
        achievements: [Achievement] = [],
        reflections: [DailyReflection] = [],
        settings: PulseSettings = PulseSettings()
    ) {
        self.schemaVersion = schemaVersion
        self.tasks = tasks
        self.events = events
        self.habits = habits
        self.sessions = sessions
        self.categories = categories
        self.achievements = achievements
        self.reflections = reflections
        self.settings = settings
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case tasks
        case events
        case habits
        case sessions
        case categories
        case achievements
        case reflections
        case settings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = (try? container.decode(Int.self, forKey: .schemaVersion)) ?? 1
        tasks = (try? container.decode([TaskItem].self, forKey: .tasks)) ?? []
        events = (try? container.decode([CalendarEvent].self, forKey: .events)) ?? []
        habits = (try? container.decode([Habit].self, forKey: .habits)) ?? []
        sessions = (try? container.decode([FocusSession].self, forKey: .sessions)) ?? []
        categories = (try? container.decode([TaskCategory].self, forKey: .categories)) ?? []
        achievements = (try? container.decode([Achievement].self, forKey: .achievements)) ?? []
        reflections = (try? container.decode([DailyReflection].self, forKey: .reflections)) ?? []
        settings = (try? container.decode(PulseSettings.self, forKey: .settings)) ?? PulseSettings()
    }
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
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        if let snapshot = try? decoder.decode(AppSnapshot.self, from: data) {
            return snapshot
        }

        // Прочитать не удалось — не затираем файл молча, отодвигаем в сторону.
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = directory.appendingPathComponent("store-recovery-\(stamp).json")
        try? fileManager.moveItem(at: fileURL, to: backup)
        return nil
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
