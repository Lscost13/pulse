//
//  PulseEffects.swift
//  PULSE
//
//  Визуальные эффекты: кольцо прогресса, огонёк серии, чекбокс,
//  тепловая карта. Здесь живёт «дорогая» анимация.
//

import SwiftUI

// MARK: - Кольцо прогресса

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = PulseMetrics.ringLineWidth
    var accent: Color = PulsePalette.violetFallback
    var trackOpacity: Double = 1

    @State private var animated: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(PulsePalette.cardSunken.opacity(trackOpacity), lineWidth: lineWidth)
            if animated > 0.001 {
                Circle()
                    .trim(from: 0, to: min(1, animated))
                    .stroke(
                        PulseGradient.accent(accent),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: accent.opacity(0.35), radius: 12)
            }
        }
        .onAppear {
            withAnimation(PulseMotion.progress.delay(0.15)) {
                animated = min(1, max(0, progress))
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(PulseMotion.progress) {
                animated = min(1, max(0, newValue))
            }
        }
    }
}

// MARK: - Огонёк серии

struct FlameView: View {
    var size: CGFloat = 44
    var intensity: Double = 1.0
    var isActive: Bool = true

    @State private var breathing = false

    var body: some View {
        ZStack {
            Image(systemName: "flame.fill")
                .font(.system(size: size))
                .foregroundStyle(PulseGradient.flame)
                .blur(radius: size * 0.24)
                .opacity((isActive ? 0.55 : 0.12) * intensity + 0.1)
                .scaleEffect(breathing ? 1.08 : 0.94)

            Image(systemName: "flame.fill")
                .font(.system(size: size))
                .foregroundStyle(
                    isActive ? AnyShapeStyle(PulseGradient.flame) : AnyShapeStyle(PulsePalette.inkTertiary.opacity(0.4))
                )
                .scaleEffect(breathing ? 1.03 : 0.985)

            Image(systemName: "flame.fill")
                .font(.system(size: size * 0.5))
                .foregroundStyle(Color.white.opacity(isActive ? 0.5 : 0.15))
                .blur(radius: size * 0.05)
                .offset(y: size * 0.14)
                .scaleEffect(breathing ? 1.05 : 0.9)
        }
        .frame(width: size * 1.2, height: size * 1.2)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Чекбокс задачи

struct PulseCheckbox: View {
    var isOn: Bool
    var accent: Color = PulsePalette.violetFallback
    var size: CGFloat = 24
    var action: () -> Void

    @State private var pop: CGFloat = 1

    var body: some View {
        Button {
            Haptics.selection()
            withAnimation(PulseMotion.bouncy) {
                pop = 0.82
            }
            withAnimation(PulseMotion.bouncy.delay(0.1)) {
                pop = 1
            }
            action()
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(
                        isOn ? Color.clear : PulsePalette.stroke,
                        lineWidth: 1.6
                    )
                    .background {
                        Circle()
                            .fill(isOn ? AnyShapeStyle(PulseGradient.accent(accent)) : AnyShapeStyle(Color.clear))
                    }
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.44, weight: .bold))
                        .foregroundStyle(Color.white)
                        .symbolEffect(.bounce, value: isOn)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: size, height: size)
            .scaleEffect(pop)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOn ? "Отметить как невыполненную" : "Отметить как выполненную")
    }
}

// MARK: - Тепловая карта

struct HeatmapView: View {
    let cells: [HeatmapCell]
    var accent: Color = PulsePalette.violetFallback
    var cellSize: CGFloat = 13
    var spacing: CGFloat = 4

    private let levelOpacity: [Double] = [0.0, 0.22, 0.42, 0.68, 1.0]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: spacing) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: spacing) {
                        ForEach(week) { cell in
                            RoundedRectangle(cornerRadius: cellSize * 0.28, style: .continuous)
                                .fill(color(for: cell))
                                .frame(width: cellSize, height: cellSize)
                                .overlay {
                                    if cell.day.isToday {
                                        RoundedRectangle(cornerRadius: cellSize * 0.28, style: .continuous)
                                            .strokeBorder(PulsePalette.ink.opacity(0.55), lineWidth: 1.2)
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    private var weeks: [[HeatmapCell]] {
        guard !cells.isEmpty else { return [] }
        var result: [[HeatmapCell]] = []
        var current: [HeatmapCell] = []
        var lastWeekStart: Date?
        for cell in cells {
            let weekStart = PulseDate.weekStart(of: cell.day, calendar: PulseDate.defaultCalendar)
            if let last = lastWeekStart, !calendar.isDate(last, inSameDayAs: weekStart) {
                result.append(current)
                current = []
            }
            current.append(cell)
            lastWeekStart = weekStart
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result.map { week in
            // Выравниваем недели по первому дню недели.
            week
        }
    }

    private var calendar: Calendar {
        PulseDate.defaultCalendar
    }

    private func color(for cell: HeatmapCell) -> Color {
        let level = min(4, max(0, cell.level))
        if level == 0 {
            return PulsePalette.cardSunken
        }
        return accent.opacity(levelOpacity[level])
    }
}

// MARK: - Мини-календарь серии

struct StreakCalendar: View {
    let activeDays: Set<String>
    let repairedDays: Set<String>
    let restWeekdays: [Int]
    var accent: Color = PulsePalette.violetFallback
    var month: Date

    private var calendar: Calendar { PulseDate.defaultCalendar }

    var body: some View {
        let days = PulseDate.monthGrid(for: month, calendar: calendar)
        let currentMonth = calendar.component(.month, from: month)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
            ForEach(RuCal.weekdaysShort, id: \.self) { name in
                Text(name)
                    .font(PulseFont.micro)
                    .foregroundStyle(PulsePalette.inkTertiary)
                    .frame(maxWidth: .infinity)
            }
            ForEach(days, id: \.self) { day in
                let inMonth = calendar.component(.month, from: day) == currentMonth
                let key = day.dayKey
                let isActive = activeDays.contains(key)
                let isRepaired = repairedDays.contains(key)
                let isRest = restWeekdays.contains(day.weekdayNumber)
                let isFuture = day > Date()

                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(fill(isActive: isActive, isRepaired: isRepaired, isRest: isRest, isFuture: isFuture))
                        .frame(height: 30)
                        .overlay {
                            if day.isToday {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .strokeBorder(PulsePalette.ink.opacity(0.45), lineWidth: 1.2)
                            }
                        }
                    Text("\(day.dayNumber)")
                        .font(PulseFont.micro)
                        .foregroundStyle(dayNumberColor(isActive: isActive, inMonth: inMonth))
                        .opacity(inMonth ? 1 : 0.3)
                }
            }
        }
    }

    private func fill(isActive: Bool, isRepaired: Bool, isRest: Bool, isFuture: Bool) -> Color {
        if isActive { return accent }
        if isRepaired { return accent.opacity(0.28) }
        if isRest { return PulsePalette.cardSunken.opacity(0.7) }
        return PulsePalette.cardSunken.opacity(isFuture ? 0.35 : 1)
    }

    private func dayNumberColor(isActive: Bool, inMonth: Bool) -> Color {
        if isActive { return Color.white }
        return PulsePalette.inkSecondary.opacity(inMonth ? 1 : 0.5)
    }
}

// MARK: - Анимированный счётчик

struct AnimatedNumberText: View {
    let value: Double
    var format: (Double) -> String = { String(Int($0)) }
    var font: Font = PulseFont.number(28, .bold)
    var tint: Color = PulsePalette.ink

    var body: some View {
        Text(format(value))
            .font(font)
            .foregroundStyle(tint)
            .contentTransition(.numericText())
            .animation(PulseMotion.smooth, value: value)
    }
}

// MARK: - Появление блока

/// Мягкое появление секции: чуть вверх и из прозрачности.
/// Небольшая задержка по индексу даёт «дорогой» каскад при открытии экрана.
struct PulseAppearModifier: ViewModifier {
    var index: Int
    var enabled: Bool
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown || !enabled ? 1 : 0)
            .offset(y: shown || !enabled ? 0 : 16)
            .onAppear {
                guard enabled, !shown else { return }
                withAnimation(PulseMotion.smooth.delay(Double(min(index, 8)) * 0.045)) {
                    shown = true
                }
            }
    }
}

extension View {
    func pulseAppear(_ index: Int = 0, enabled: Bool = true) -> some View {
        modifier(PulseAppearModifier(index: index, enabled: enabled))
    }
}
