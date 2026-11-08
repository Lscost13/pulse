//
//  DayReviewView.swift
//  PULSE
//
//  Итоги дня: оценка от 0 до 100, мысль дня и история оценок.
//  Кольцо-шкала, спарклайн и мягкие анимации — без лишнего шума.
//

import SwiftUI

struct DayReviewView: View {
    let day: Date

    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var score: Int = 70
    @State private var text: String = ""
    @State private var didLoad: Bool = false
    @State private var justSaved: Bool = false

    @FocusState private var textFocused: Bool

    private var accent: Color { store.settings.accent.color }
    private var scoreColor: Color {
        switch score {
        case 0..<35: return PulsePalette.danger
        case 35..<60: return PulsePalette.amber
        case 60..<80: return PulsePalette.sky
        default: return PulsePalette.mint
        }
    }

    var body: some View {
        ZStack {
            PulseBackground(accent: accent)

            NavigationStack {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        dialCard
                        quickScores
                        thoughtCard
                        saveButton
                        historyCard
                    }
                    .padding(.horizontal, PulseMetrics.screenPadding)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
                .navigationTitle(day.isToday ? "Итоги дня" : day.dayMonthTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Закрыть") { dismiss() }
                            .foregroundStyle(PulsePalette.inkSecondary)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Сохранить") { save() }
                            .font(PulseFont.headline)
                            .foregroundStyle(accent)
                    }
                }
            }
        }
        .onAppear(perform: load)
        .overlay(alignment: .top) {
            if justSaved {
                ToastView(text: "Сохранено")
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(PulseMotion.smooth, value: justSaved)
    }

    // MARK: - Загрузка и сохранение

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        guard let existing = store.reflection(for: day) else { return }
        if existing.score > 0 {
            score = existing.score
        }
        text = existing.text
    }

    private func save() {
        store.saveReflection(day: day, score: score, text: text)
        Haptics.success()
        withAnimation(PulseMotion.smooth) {
            justSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            if justSaved { justSaved = false }
        }
    }

    // MARK: - Кольцо оценки

    private var dialCard: some View {
        PulseCard(padding: 22, tint: scoreColor) {
            VStack(spacing: 16) {
                ScoreDial(score: score, size: 200, lineWidth: 15, accent: scoreColor, showsNumber: true)

                Slider(
                    value: Binding(
                        get: { Double(score) },
                        set: { newValue in
                            score = min(100, max(0, Int(newValue.rounded())))
                        }
                    ),
                    in: 0...100,
                    step: 1
                )
                .tint(scoreColor)
                .sensoryFeedback(.selection, trigger: score / 10)

                HStack {
                    Text("0 — тяжёлый день")
                        .font(PulseFont.micro)
                        .foregroundStyle(PulsePalette.inkTertiary)
                    Spacer()
                    Text("100 — идеальный")
                        .font(PulseFont.micro)
                        .foregroundStyle(PulsePalette.inkTertiary)
                }
            }
        }
    }

    // MARK: - Быстрые оценки

    private var quickScores: some View {
        HStack(spacing: 8) {
            quickChip("Плохо", 25, PulsePalette.danger)
            quickChip("Средне", 50, PulsePalette.amber)
            quickChip("Хорошо", 75, PulsePalette.sky)
            quickChip("Отлично", 95, PulsePalette.mint)
        }
    }

    private func quickChip(_ title: String, _ value: Int, _ tint: Color) -> some View {
        let isSelected = score == value
        return Button {
            Haptics.selection()
            withAnimation(PulseMotion.bouncy) {
                score = value
            }
        } label: {
            VStack(spacing: 3) {
                Text("\(value)")
                    .font(PulseFont.number(15, .bold))
                Text(title)
                    .font(.system(size: 9.5, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.white : tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.12)))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Мысль дня

    private var thoughtCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "text.quote")
                    .font(.system(size: 10, weight: .bold))
                Text("МЫСЛЬ ДНЯ")
                    .font(PulseFont.micro)
                    .tracking(0.9)
                Spacer()
                Text("\(text.count)")
                    .font(PulseFont.micro)
                    .foregroundStyle(PulsePalette.inkTertiary.opacity(0.6))
            }
            .foregroundStyle(PulsePalette.inkTertiary)

            VStack(alignment: .leading, spacing: 8) {
                TextField(
                    "Что запомнилось, что понял, что забрать в завтра?",
                    text: $text,
                    axis: .vertical
                )
                .font(PulseFont.body)
                .foregroundStyle(PulsePalette.ink)
                .lineLimit(3...8)
                .focused($textFocused)

                HStack(spacing: 6) {
                    imageChip("Понял", "lightbulb.max.fill")
                    imageChip("Гордость", "star.fill")
                    imageChip("Стоп", "hand.raised.fill")
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(PulsePalette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(PulsePalette.stroke, lineWidth: 1)
            )
        }
    }

    private func imageChip(_ title: String, _ symbol: String) -> some View {
        Button {
            Haptics.selection()
            let prefix: String
            switch symbol {
            case "lightbulb.max.fill": prefix = "Понял: "
            case "star.fill": prefix = "Горжусь: "
            default: prefix = "Стоп: "
            }
            if text.isEmpty {
                text = prefix
            } else if !text.hasSuffix("\n") {
                text += "\n" + prefix
            } else {
                text += prefix
            }
            textFocused = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
                Text(title)
                    .font(PulseFont.micro)
            }
            .foregroundStyle(PulsePalette.inkSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(PulsePalette.cardSunken, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Сохранение

    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text(store.reflection(for: day) == nil ? "Сохранить итоги" : "Обновить итоги")
                    .font(PulseFont.headline)
            }
        }
        .buttonStyle(PulsePrimaryButtonStyle(accent: scoreColor))
    }

    // MARK: - История

    @ViewBuilder
    private var historyCard: some View {
        let history = store.scoreHistory(days: 14)
        let values = history.map { $0.score }
        let average = store.averageScore(days: 14)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Оценки за 14 дней")
                    .font(PulseFont.headline)
                    .foregroundStyle(PulsePalette.ink)
                Spacer()
                if let average = average {
                    TagPill(text: String(format: "средняя %.0f", average), tint: accent)
                }
            }

            PulseCard(padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    ScoreSparkline(values: values, accent: accent)
                        .frame(height: 84)

                    HStack(spacing: 6) {
                        ForEach(Array(history.enumerated()), id: \.offset) { _, item in
                            Circle()
                                .fill(item.score == nil ? PulsePalette.cardSunken : accent.opacity(0.75))
                                .frame(width: 5, height: 5)
                        }
                        Spacer()
                        Text("14 дн.")
                            .font(PulseFont.micro)
                            .foregroundStyle(PulsePalette.inkTertiary)
                    }
                }
            }

            let recents = Array(store.filledReflections.prefix(4))
            if !recents.isEmpty {
                PulseCard(padding: 6) {
                    VStack(spacing: 0) {
                        ForEach(Array(recents.enumerated()), id: \.element.id) { index, reflection in
                            if index > 0 {
                                PulseDivider(inset: 12)
                            }
                            HStack(spacing: 10) {
                                Text("\(reflection.score)")
                                    .font(PulseFont.number(13, .bold))
                                    .foregroundStyle(scoreColor(for: reflection.score))
                                    .frame(width: 34, height: 26)
                                    .background(
                                        scoreColor(for: reflection.score).opacity(0.12),
                                        in: Capsule()
                                    )
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(reflection.day.dayMonthTitle)
                                        .font(PulseFont.caption)
                                        .foregroundStyle(PulsePalette.inkSecondary)
                                    if !reflection.text.isEmpty {
                                        Text(reflection.text)
                                            .font(PulseFont.micro)
                                            .foregroundStyle(PulsePalette.inkTertiary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }

    private func scoreColor(for value: Int) -> Color {
        switch value {
        case 0..<35: return PulsePalette.danger
        case 35..<60: return PulsePalette.amber
        case 60..<80: return PulsePalette.sky
        default: return PulsePalette.mint
        }
    }
}

// MARK: - Кольцо-шкала

struct ScoreDial: View {
    var score: Int
    var size: CGFloat = 200
    var lineWidth: CGFloat = 15
    var accent: Color = PulsePalette.violetFallback
    var showsNumber: Bool = true
    var showsWord: Bool = true

    private var progress: Double {
        Double(min(100, max(0, score))) / 100.0
    }

    private var word: String {
        switch score {
        case 0..<35: return "тяжёлый"
        case 35..<60: return "средний"
        case 60..<80: return "хороший"
        default: return "отличный"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    PulsePalette.cardSunken,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(135))

            if progress > 0.002 {
                Circle()
                    .trim(from: 0, to: 0.75 * progress)
                    .stroke(
                        PulseGradient.accent(accent),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .shadow(color: accent.opacity(0.35), radius: 12)
                    .animation(PulseMotion.progress, value: progress)
            }

            if showsNumber {
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(PulseFont.number(size * 0.26, .bold))
                        .foregroundStyle(PulsePalette.ink)
                        .contentTransition(.numericText())
                        .animation(PulseMotion.smooth, value: score)
                    if showsWord {
                        Text(word)
                            .font(PulseFont.micro)
                            .foregroundStyle(accent)
                    }
                }
                .offset(y: size * 0.02)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Спарклайн оценок

struct ScoreSparkline: View {
    var values: [Int?]
    var accent: Color

    @State private var shown: Bool = false

    var body: some View {
        GeometryReader { proxy in
            let points = computePoints(in: proxy.size)
            ZStack {
                if points.count > 1 {
                    areaPath(points: points, height: proxy.size.height)
                        .fill(
                            LinearGradient(
                                colors: [accent.opacity(0.28), accent.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    linePath(points: points)
                        .trim(from: 0, to: shown ? 1 : 0)
                        .stroke(
                            PulseGradient.accent(accent),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                }

                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(accent)
                        .frame(width: 4, height: 4)
                        .position(point)
                        .opacity(shown ? 1 : 0)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.9).delay(0.1)) {
                    shown = true
                }
            }
        }
    }

    private func computePoints(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let step = size.width / CGFloat(max(1, values.count - 1))
        var points: [CGPoint] = []
        for (index, value) in values.enumerated() {
            guard let value = value else { continue }
            let x = CGFloat(index) * step
            let ratio = CGFloat(min(100, max(0, value))) / 100
            let y = size.height - size.height * ratio
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }

    private func linePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }

    private func areaPath(points: [CGPoint], height: CGFloat) -> Path {
        var path = Path()
        guard let first = points.first, let last = points.last else { return path }
        path.move(to: CGPoint(x: first.x, y: height))
        path.addLine(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.addLine(to: CGPoint(x: last.x, y: height))
        path.closeSubpath()
        return path
    }
}
