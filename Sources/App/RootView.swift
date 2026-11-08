//
//  RootView.swift
//  PULSE
//
//  Оболочка: онбординг, телефонная и планшетная навигация, все модальные
//  окна приложения в одном месте.
//

import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var router = Router()
    @State private var themeVeil: Double = 0

    var body: some View {
        @Bindable var router = router

        ZStack {
            if store.settings.hasOnboarded {
                if horizontalSizeClass == .compact {
                    phoneShell(router: router)
                } else {
                    padShell(router: router)
                }
            } else {
                OnboardingView()
                    .transition(.opacity)
            }

            if themeVeil > 0 {
                PulsePalette.background
                    .ignoresSafeArea()
                    .opacity(themeVeil)
                    .allowsHitTesting(false)
            }
        }
        .environment(router)
        .animation(PulseMotion.theme, value: store.settings.hasOnboarded)
        .sheet(item: $router.taskEditor) { request in
            TaskEditorView(request: request)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $router.eventEditor) { request in
            EventEditorView(request: request)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $router.habitEditor) { request in
            HabitEditorView(request: request)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $router.showQuickAdd) {
            QuickAddView()
                .presentationDetents([.height(360), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.thinMaterial)
        }
        .sheet(isPresented: $router.showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $router.showStreak) {
            StreakScreen(isModal: true)
                .presentationDragIndicator(.visible)
        }
        .onChange(of: store.settings.appearance) { _, _ in
            flashThemeVeil()
        }
    }

    private func flashThemeVeil() {
        themeVeil = 0.85
        withAnimation(.easeOut(duration: 0.5)) {
            themeVeil = 0
        }
    }

    // MARK: - iPhone

    private func phoneShell(router: Router) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                switch router.tab {
                case .today: TodayScreen()
                case .calendar: CalendarScreen()
                case .tasks: TasksScreen()
                case .focus: FocusScreen()
                case .insights: InsightsScreen()
                case .streak: StreakScreen(isModal: false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                PulseTabBar(selection: tabBinding(router: router), accent: store.settings.accent.color)
            }
            .transition(.opacity)

            addButton
                .padding(.trailing, 20)
                .padding(.bottom, 96)
        }
    }

    private var addButton: some View {
        Button {
            Haptics.tap()
            router.showQuickAdd = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: 58, height: 58)
                .background(
                    PulseGradient.accent(store.settings.accent.color),
                    in: Circle()
                )
                .shadow(
                    color: store.settings.accent.color.opacity(0.4),
                    radius: 18,
                    x: 0,
                    y: 10
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Быстрое создание задачи")
    }

    private func tabBinding(router: Router) -> Binding<PulseTab> {
        Binding(
            get: { router.tab },
            set: { newValue in
                if newValue == router.tab && newValue == .today {
                    router.selectedDay = Date().startOfDay()
                }
                router.tab = newValue
            }
        )
    }

    // MARK: - iPad

    private func padShell(router: Router) -> some View {
        NavigationSplitView {
            PadSidebar(selection: tabBinding(router: router))
                .navigationSplitViewColumnWidth(min: 230, ideal: 260, max: 300)
        } detail: {
            ZStack {
                PulseBackground(accent: store.settings.accent.color)
                Group {
                    switch router.tab {
                    case .today: TodayScreen()
                    case .calendar: CalendarScreen()
                    case .tasks: TasksScreen()
                    case .focus: FocusScreen()
                    case .insights: InsightsScreen()
                    case .streak: StreakScreen(isModal: false)
                    }
                }
                .frame(maxWidth: 1180)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - Нижняя панель iPhone

struct PulseTabBar: View {
    @Binding var selection: PulseTab
    var accent: Color = PulsePalette.violetFallback

    @Namespace private var namespace
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 2) {
            ForEach(PulseTab.phoneTabs) { tab in
                let isSelected = selection == tab
                Button {
                    Haptics.selection()
                    withAnimation(PulseMotion.smooth) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: isSelected ? tab.filledSymbol : tab.symbol)
                            .font(.system(size: 17, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                        Text(tab.title)
                            .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                    }
                    .foregroundStyle(isSelected ? accent : PulsePalette.inkTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(accent.opacity(scheme == .dark ? 0.16 : 0.10))
                                .matchedGeometryEffect(id: "tab", in: namespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(PulsePalette.surface.opacity(0.55))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(PulsePalette.stroke.opacity(0.8), lineWidth: 1)
                }
                .pulseShadow(PulseShadow.floating(scheme))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .padding(.top, 6)
    }
}

// MARK: - Боковая панель iPad

struct PadSidebar: View {
    @Binding var selection: PulseTab
    @Environment(AppStore.self) private var store

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(PulseGradient.accent(store.settings.accent.color))
                            .frame(width: 34, height: 34)
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("PULSE")
                            .font(PulseFont.rounded(17, .bold))
                            .foregroundStyle(PulsePalette.ink)
                        Text(greeting)
                            .font(PulseFont.micro)
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Разделы") {
                ForEach(PulseTab.allCases) { tab in
                    Button {
                        Haptics.selection()
                        withAnimation(PulseMotion.smooth) {
                            selection = tab
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: selection == tab ? tab.filledSymbol : tab.symbol)
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 22)
                            Text(tab.title)
                                .font(PulseFont.subheadline)
                            Spacer()
                            if tab == .tasks {
                                let count = store.tasks(in: .today).count
                                if count > 0 {
                                    CounterPill(value: count)
                                }
                            }
                        }
                        .foregroundStyle(selection == tab ? store.settings.accent.color : PulsePalette.inkSecondary)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Section {
                Button {
                    routerOpenSettings()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 22)
                        Text("Настройки")
                            .font(PulseFont.subheadline)
                    }
                    .foregroundStyle(PulsePalette.inkSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(PulsePalette.background)
        .navigationTitle("PULSE")
    }

    @Environment(Router.self) private var router

    private func routerOpenSettings() {
        router.showSettings = true
    }

    private var greeting: String {
        let name = store.settings.userName
        let hour = Calendar.current.component(.hour, from: Date())
        let base: String
        switch hour {
        case 5..<12: base = "Доброе утро"
        case 12..<18: base = "Добрый день"
        case 18..<23: base = "Добрый вечер"
        default: base = "Доброй ночи"
        }
        return name.isEmpty ? base : "\(base), \(name)"
    }
}
