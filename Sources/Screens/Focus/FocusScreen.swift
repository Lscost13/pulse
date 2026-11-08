//
//  FocusScreen.swift
//  PULSE
//
//  Концентрация: большие сессии, паузы, привязка к задаче и история.
//  Во время работы интерфейс «затихает» и оставляет только таймер.
//

import SwiftUI
import Combine

struct FocusScreen: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var phase: FocusPhase = .focus
    @State private var remaining: Int
    @State private var isRunning: Bool = false
    @State private var endDate: Date?
    @State private var plannedMinutes: Int = 25
    @State private var boundTaskID: UUID?
    @State private var showHistory: Bool = true
    @State private var completedInCycle: Int = 0

    @State private var timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    init() {
        _remaining = State(initialValue: 25 * 60)
    }

    private var accent: Color { store.settings.accent.color }

    private var progress: Double {
        let total = Double(max(1, plannedMinutes * 60))
        return min(1, max(0, 1 - Double(remaining) / total))
    }

    var body: some View {
        ZStack {
            PulseBackground(accent: accent)

            if isRunning {
                focusModeView
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                regularView
                    .transition(.opacity)
            }
        }
        .animation(PulseMotion.smooth, value: isRunning)
        .onReceive(timer) { _ in
            tick()
        }
        .onAppear {
            syncPhaseDuration()
        }
    }

    // MARK: - Обычный режим

    private var regularView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                timerCard
                phaseSwitcher
                taskBinding
                statsRow
                historySection
            }
            .padding(.horizontal, PulseMetrics.screenPadding)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("ФОКУС")
                    .font(PulseFont.micro)
                    .tracking(1.2)
                    .foregroundStyle(PulsePalette.inkTertiary)
                Text("Глубокая работа")
                    .font(PulseFont.displayM)
                    .foregroundStyle(PulsePalette.ink)
            }
            Spacer(minLength: 8)
            Button {
                Haptics.tap()
                router.showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PulsePalette.inkSecondary)
                    .frame(width: 38, height: 38)
                    .background(PulsePalette.cardSunken, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 6)
    }

    private var timerCard: some View {
        PulseCard(padding: 22, tint: accent) {
            VStack(spacing: 20) {
                HStack {
                    Text(phase.title.uppercased())
                        .font(PulseFont.micro)
                        .tracking(1.2)
                        .foregroundStyle(accent)
                    Spacer()
                    Text("\(completedInCycle)/\(store.settings.sessionsBeforeLongBreak) до отдыха")
                        .font(PulseFont.micro)
                        .foregroundStyle(PulsePalette.inkTertiary)
                }

                ZStack {
                    PulseGradient.accentGlow(accent)
                        .frame(width: 300, height: 300)
                        .blur(radius: 26)
                        .opacity(isRunning ? 1 : 0.55)

                    ProgressRing(progress: progress, lineWidth: 18, accent: accent)
                        .frame(width: 240, height: 240)
                        .scaleEffect(isRunning ? 1.01 : 1)

                    VStack(spacing: 6) {
                        Text(timeText)
                            .font(PulseFont.number(52, .bold))
                            .foregroundStyle(PulsePalette.ink)
                            .monospacedDigit()
                        Text(phase == .focus ? "минут концентрации" : "минут отдыха")
                            .font(PulseFont.micro)
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }
                }
                .frame(height: 250)

                HStack(spacing: 12) {
                    Button {
                        Haptics.rigid()
                        withAnimation(PulseMotion.smooth) {
                            reset()
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(PulsePalette.inkSecondary)
                            .frame(width: 52, height: 52)
                            .background(PulsePalette.cardSunken, in: Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.tap()
                        withAnimation(PulseMotion.smooth) {
                            startOrPause()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text(isRunning ? "Пауза" : "Начать")
                                .font(PulseFont.headline)
                        }
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(PulseGradient.accent(accent), in: Capsule())
                        .shadow(color: accent.opacity(0.35), radius: 16, y: 8)
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.soft()
                        withAnimation(PulseMotion.smooth) {
                            finishCurrentPhase()
                        }
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(PulsePalette.inkSecondary)
                            .frame(width: 52, height: 52)
                            .background(PulsePalette.cardSunken, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var phaseSwitcher: some View {
        HStack(spacing: 8) {
            ForEach(FocusPhase.allCases) { item in
                let isSelected = phase == item
                Button {
                    Haptics.selection()
                    withAnimation(PulseMotion.snappy) {
                        phase = item
                        isRunning = false
                        endDate = nil
                        syncPhaseDuration()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 13, weight: .semibold))
                        Text(item.shortTitle)
                            .font(PulseFont.micro)
                        Text("\(duration(for: item)) мин")
                            .font(PulseFont.micro)
                            .opacity(0.7)
                    }
                    .foregroundStyle(isSelected ? Color.white : PulsePalette.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(isSelected
                                  ? AnyShapeStyle(PulseGradient.accent(accent))
                                  : AnyShapeStyle(PulsePalette.cardSunken))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var taskBinding: some View {
        Menu {
            Button {
                boundTaskID = nil
            } label: {
                Label("Без задачи", systemImage: "minus.circle")
            }
            Divider()
            ForEach(store.todayOpenTasks) { task in
                Button {
                    boundTaskID = task.id
                } label: {
                    Label(task.title, systemImage: "checklist")
                }
            }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(accent.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: "target")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(accent)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Привязать к задаче")
                        .font(PulseFont.micro)
                        .foregroundStyle(PulsePalette.inkTertiary)
                    Text(boundTaskTitle)
                        .font(PulseFont.subheadline)
                        .foregroundStyle(PulsePalette.ink)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(PulsePalette.inkTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(PulsePalette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(PulsePalette.stroke, lineWidth: 1)
            )
        }
    }

    private var boundTaskTitle: String {
        guard let id = boundTaskID, let task = store.task(with: id) else {
            return "Без задачи"
        }
        return task.title
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statBox(
                value: PulseDate.durationShort(minutes: store.focusMinutes(on: store.today)),
                title: "сегодня",
                symbol: "bolt.fill",
                tint: accent
            )
            statBox(
                value: "\(store.sessions.filter { $0.isFocus && $0.completed && $0.startedAt.isToday }.count)",
                title: "сессий",
                symbol: "square.stack.3d.up",
                tint: PulsePalette.mint
            )
            statBox(
                value: PulseDate.durationShort(minutes: store.focusMinutes(on: store.today.adding(days: -1))),
                title: "вчера",
                symbol: "clock.arrow.circlepath",
                tint: PulsePalette.sky
            )
        }
    }

    private func statBox(value: String, title: String, symbol: String, tint: Color) -> some View {
        PulseCard(padding: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(PulseFont.number(19, .bold))
                    .foregroundStyle(PulsePalette.ink)
                Text(title)
                    .font(PulseFont.micro)
                    .foregroundStyle(PulsePalette.inkTertiary)
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "История",
                subtitle: "\(store.sessions.filter { $0.isFocus }.count) сессий всего",
                actionTitle: showHistory ? "Свернуть" : "Показать",
                action: {
                    withAnimation(PulseMotion.smooth) { showHistory.toggle() }
                }
            )

            if showHistory {
                PulseCard(padding: 6) {
                    let items = Array(store.recentSessions.prefix(8))
                    if items.isEmpty {
                        EmptyState(
                            symbol: "timer",
                            title: "Пока нет сессий",
                            subtitle: "Первая сессия появится здесь после завершения."
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, session in
                                if index > 0 { PulseDivider(inset: 50) }
                                SessionRow(
                                    session: session,
                                    taskTitle: store.task(with: session.taskID)?.title
                                )
                                .padding(.horizontal, 10)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Режим концентрации

    private var focusModeView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(boundTaskTitle.uppercased())
                    .font(PulseFont.micro)
                    .tracking(1.4)
                    .foregroundStyle(PulsePalette.inkTertiary)
                    .lineLimit(1)
                Spacer()
                Button {
                    Haptics.tap()
                    withAnimation(PulseMotion.smooth) {
                        pauseSession()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(PulsePalette.inkTertiary)
                        .frame(width: 34, height: 34)
                        .background(PulsePalette.cardSunken, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            Spacer()

            ZStack {
                PulseGradient.accentGlow(accent)
                    .frame(width: 340, height: 340)
                    .blur(radius: 30)

                ProgressRing(progress: progress, lineWidth: 14, accent: accent, trackOpacity: 0.5)
                    .frame(width: 260, height: 260)

                VStack(spacing: 10) {
                    Text(timeText)
                        .font(PulseFont.number(64, .bold))
                        .foregroundStyle(PulsePalette.ink)
                        .monospacedDigit()
                    Text(phase == .focus ? "ФОКУС" : phase.shortTitle.uppercased())
                        .font(PulseFont.micro)
                        .tracking(2)
                        .foregroundStyle(accent)
                }
            }

            Spacer()

            VStack(spacing: 14) {
                Button {
                    Haptics.tap()
                    withAnimation(PulseMotion.smooth) {
                        pauseSession()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Пауза")
                            .font(PulseFont.headline)
                    }
                    .foregroundStyle(PulsePalette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(PulsePalette.card, in: Capsule())
                    .overlay(Capsule().strokeBorder(PulsePalette.stroke, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Text("Не отвлекайся — осталось \(max(1, remaining / 60)) мин")
                    .font(PulseFont.micro)
                    .foregroundStyle(PulsePalette.inkTertiary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 44)
        }
    }

    // MARK: - Логика таймера

    private var timeText: String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func duration(for item: FocusPhase) -> Int {
        switch item {
        case .focus: return store.settings.focusLength
        case .shortBreak: return store.settings.shortBreak
        case .longBreak: return store.settings.longBreak
        }
    }

    private func syncPhaseDuration() {
        plannedMinutes = duration(for: phase)
        remaining = plannedMinutes * 60
    }

    private func startOrPause() {
        if isRunning {
            pauseSession()
        } else {
            isRunning = true
            endDate = Date().addingTimeInterval(Double(remaining))
            Haptics.soft()
        }
    }

    private func pauseSession() {
        isRunning = false
        endDate = nil
    }

    private func reset() {
        isRunning = false
        endDate = nil
        syncPhaseDuration()
    }

    private func tick() {
        guard isRunning, let end = endDate else { return }
        let left = Int(end.timeIntervalSinceNow.rounded())
        if left <= 0 {
            remaining = 0
            finishCurrentPhase()
        } else {
            remaining = left
        }
    }

    private func finishCurrentPhase() {
        let spentMinutes = max(1, plannedMinutes - remaining / 60)
        isRunning = false
        endDate = nil

        if phase == .focus {
            store.addSession(
                FocusSession(
                    id: UUID(),
                    taskID: boundTaskID,
                    startedAt: Date().addingTimeInterval(-Double(spentMinutes) * 60),
                    minutes: plannedMinutes,
                    phase: .focus,
                    completed: true
                )
            )
            completedInCycle += 1
            Haptics.success()
        } else {
            Haptics.soft()
        }

        let nextPhase: FocusPhase
        if phase != .focus {
            nextPhase = .focus
        } else if completedInCycle > 0 && completedInCycle % max(1, store.settings.sessionsBeforeLongBreak) == 0 {
            nextPhase = .longBreak
        } else {
            nextPhase = .shortBreak
        }

        phase = nextPhase
        plannedMinutes = duration(for: nextPhase)
        remaining = plannedMinutes * 60
    }
}
