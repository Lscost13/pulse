//
//  PulseApp.swift
//  PULSE
//

import SwiftUI

@main
struct PulseApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(store.settings.accent.color)
                .preferredColorScheme(store.settings.appearance.colorScheme)
                .onAppear(perform: bootstrap)
        }
    }

    private func bootstrap() {
        guard store.settings.remindersEnabled else { return }
        NotificationManager.requestAuthorizationIfNeeded()
        NotificationManager.reschedule(tasks: store.tasks)
        NotificationManager.scheduleWeeklyReview(enabled: true)
    }
}
