//
//  OnboardingView.swift
//  PULSE
//
//  Первое знакомство: имя, тема и обещание продукта. Без экранов-заглушек.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    @State private var step: Int = 0
    @State private var name: String = ""
    @State private var appearance: AppearanceMode = .system
    @State private var accent: AccentTheme = .violet
    @State private var appeared: Bool = false

    @FocusState private var nameFocused: Bool

    private let totalSteps = 3

    var body: some View {
        ZStack {
            PulseBackground(accent: accent.color)

            VStack(spacing: 0) {
                Spacer(minLength: 20)

                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: nameStep
                    default: readyStep
                    }
                }
                .pulseAppear()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .frame(maxWidth: 520)

                Spacer(minLength: 16)

                footer
                    .frame(maxWidth: 520)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
        .onAppear {
            name = store.settings.userName
            appearance = store.settings.appearance
            accent = store.settings.accent
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - Шаг 1: бренд

    private var welcomeStep: some View {
        VStack(spacing: 26) {
            ZStack {
                PulseGradient.accentGlow(accent.color)
                    .frame(width: 320, height: 320)
                    .blur(radius: 30)

                Circle()
                    .strokeBorder(accent.color.opacity(0.18), lineWidth: 1)
                    .frame(width: 210, height: 210)
                    .scaleEffect(appeared ? 1 : 0.8)

                Circle()
                    .strokeBorder(accent.color.opacity(0.3), lineWidth: 1)
                    .frame(width: 160, height: 160)
                    .scaleEffect(appeared ? 1 : 0.85)

                ZStack {
                    Circle()
                        .fill(PulseGradient.accent(accent.color))
                        .frame(width: 104, height: 104)
                        .shadow(color: accent.color.opacity(0.45), radius: 24, y: 12)
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .scaleEffect(appeared ? 1 : 0.7)
            }
            .frame(height: 250)

            VStack(spacing: 10) {
                Text("PULSE")
                    .font(PulseFont.rounded(44, .bold))
                    .tracking(6)
                    .foregroundStyle(PulsePalette.ink)

                Text("Время, задачи и ритм — в одном месте")
                    .font(PulseFont.subheadline)
                    .foregroundStyle(PulsePalette.inkSecondary)
                    .multilineTextAlignment(.center)

                Text("Планируй день, держи фокус и расти в серии. Спокойно, красиво и без перегруза.")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulsePalette.inkTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Шаг 2: имя

    private var nameStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Как тебя зовут?")
                    .font(PulseFont.displayM)
                    .foregroundStyle(PulsePalette.ink)
                Text("Имя нужно только для приветствия. Никаких аккаунтов и серверов.")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulsePalette.inkTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(PulseGradient.accent(accent.color))
                        .frame(width: 46, height: 46)
                    Text(initial)
                        .font(PulseFont.rounded(19, .bold))
                        .foregroundStyle(Color.white)
                }

                TextField("Твоё имя", text: $name)
                    .font(PulseFont.rounded(20, .semibold))
                    .foregroundStyle(PulsePalette.ink)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(PulsePalette.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(accent.color.opacity(nameFocused ? 0.45 : 0), lineWidth: 1.5)
                    )
            }

            VStack(spacing: 10) {
                Text("Тема")
                    .font(PulseFont.micro)
                    .tracking(1)
                    .foregroundStyle(PulsePalette.inkTertiary)

                HStack(spacing: 8) {
                    ForEach(AppearanceMode.allCases) { mode in
                        let isSelected = appearance == mode
                        Button {
                            Haptics.selection()
                            withAnimation(PulseMotion.snappy) { appearance = mode }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: mode.symbol)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(mode.title)
                                    .font(.system(size: 9.5, weight: .medium))
                            }
                            .foregroundStyle(isSelected ? Color.white : PulsePalette.inkSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .fill(isSelected
                                          ? AnyShapeStyle(PulseGradient.accent(accent.color))
                                          : AnyShapeStyle(PulsePalette.card))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .strokeBorder(isSelected ? Color.clear : PulsePalette.stroke, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 10) {
                    ForEach(AccentTheme.allCases) { theme in
                        Button {
                            Haptics.selection()
                            withAnimation(PulseMotion.smooth) { accent = theme }
                        } label: {
                            Circle()
                                .fill(theme.swatch)
                                .frame(width: 26, height: 26)
                                .overlay {
                                    Circle()
                                        .strokeBorder(
                                            accent == theme ? PulsePalette.ink.opacity(0.85) : Color.clear,
                                            lineWidth: 2
                                        )
                                        .padding(-3)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 20)
    }

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "P" : String(trimmed.prefix(1)).uppercased()
    }

    // MARK: - Шаг 3: готово

    private var readyStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 44, weight: .regular))
                    .foregroundStyle(accent.color)
                    .padding(.bottom, 4)
                Text("Всё готово\(name.isEmpty ? "" : ", \(name)")")
                    .font(PulseFont.displayM)
                    .foregroundStyle(PulsePalette.ink)
                    .multilineTextAlignment(.center)
                Text("В приложении уже есть пример наполненного дня — смотри, трогай и меняй под себя.")
                    .font(PulseFont.callout)
                    .foregroundStyle(PulsePalette.inkTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                featureRow(symbol: "sun.max.fill", title: "День", text: "Задачи, события и свободное время")
                featureRow(symbol: "timer", title: "Фокус", text: "Сессии концентрации с привязкой к задаче")
                featureRow(symbol: "flame.fill", title: "Серия", text: "Привычки и ритм без наказаний")
            }
        }
        .padding(.top, 10)
    }

    private func featureRow(symbol: String, title: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(accent.color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(PulseFont.subheadline)
                    .foregroundStyle(PulsePalette.ink)
                Text(text)
                    .font(PulseFont.caption)
                    .foregroundStyle(PulsePalette.inkTertiary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(PulsePalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(PulsePalette.stroke, lineWidth: 1)
        )
    }

    // MARK: - Подвал

    private var footer: some View {
        VStack(spacing: 16) {
            HStack(spacing: 7) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? accent.color : PulsePalette.stroke)
                        .frame(width: index == step ? 22 : 7, height: 7)
                        .animation(PulseMotion.smooth, value: step)
                }
            }

            Button {
                advance()
            } label: {
                Text(buttonTitle)
            }
            .buttonStyle(PulsePrimaryButtonStyle(accent: accent.color))

            if step > 0 {
                Button {
                    Haptics.tap()
                    withAnimation(PulseMotion.smooth) { step -= 1 }
                } label: {
                    Text("Назад")
                        .font(PulseFont.caption)
                        .foregroundStyle(PulsePalette.inkTertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var buttonTitle: String {
        switch step {
        case 0: return "Продолжить"
        case 1: return "Дальше"
        default: return "Начать"
        }
    }

    private func advance() {
        Haptics.tap()
        if step < totalSteps - 1 {
            withAnimation(PulseMotion.smooth) { step += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        store.updateSettings { settings in
            settings.userName = trimmed
            settings.appearance = appearance
            settings.accent = accent
            settings.hasOnboarded = true
        }
        Haptics.success()
    }
}
