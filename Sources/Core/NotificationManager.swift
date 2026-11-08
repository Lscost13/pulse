//
//  NotificationManager.swift
//  PULSE
//
//  Локальные напоминания. Своих серверов у приложения нет и не будет.
//

import Foundation
import UserNotifications

enum NotificationManager {
    static func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    static func schedule(task: TaskItem) {
        cancel(taskID: task.id)
        guard let fireDate = task.reminderDate, !task.isCompleted, fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body = task.notes.isEmpty ? "Пора заняться задачей" : task.notes
        content.sound = .default
        content.threadIdentifier = "pulse.tasks"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancel(taskID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [taskID.uuidString])
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func reschedule(tasks: [TaskItem]) {
        cancelAll()
        for task in tasks where !task.isCompleted && task.reminderDate != nil {
            schedule(task: task)
        }
    }

    /// Еженедельный итог — воскресенье, 20:00.
    static func scheduleWeeklyReview(enabled: Bool) {
        let identifier = "pulse.weekly.review"
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Итоги недели"
        content.body = "Посмотри, как прошла неделя, и спланируй следующую."
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1
        components.hour = 20
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
