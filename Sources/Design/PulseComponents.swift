//
//  PulseComponents.swift
//  PULSE
//
//  Базовые строительные блоки интерфейса: карточки, заголовки,
//  сегменты, кнопки, чипы, пустые состояния.
//

import SwiftUI

// MARK: - Фон экрана

struct PulseBackground: View {
    var accent: Color = PulsePalette.violetFallback
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            PulsePalette.background
            Circle()
                .fill(accent.opacity(scheme == .dark ? 0.16 : 0.10))
                .frame(width: 460, height: 460)
                .blur(radius: 130)
                .offset(x: -150, y: -320)
            Circle()
                .fill(PulsePalette.mint.opacity(scheme == .dark ? 0.10 : 0.07))
                .frame(width: 380, height: 380)
                .blur(radius: 150)
                .offset(x: 170, y: 280)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Карточка

struct PulseCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme

    var padding: CGFloat
    var radius: CGFloat
    var tint: Color?
    var content: Content

    init(
        padding: CGFloat = 18,
        radius: CGFloat = PulseMetrics.cardRadius,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.radius = radius
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(PulsePalette.card)
                    .overlay {
                        if let tint = tint {
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .fill(PulseGradient.cardSheen(tint))
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(PulsePalette.stroke, lineWidth: 1)
                    }
                    .pulseShadow(PulseShadow.card(scheme))
            }
    }
}

// MARK: - Заголовок секции

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(PulseFont.headline)
                    .foregroundStyle(PulsePalette.ink)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(PulseFont.caption)
                        .foregroundStyle(PulsePalette.inkTertiary)
                }
            }
            Spacer(minLength: 8)
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(PulseFont.caption)
                        .foregroundStyle(PulsePalette.inkSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(PulsePalette.cardSunken, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Сегментированный переключатель

struct SegmentedPill<Item: Hashable>: View {
    @Binding var selection: Item
    let items: [Item]
    let label: (Item) -> String
    var accent: Color = PulsePalette.violetFallback

    @Namespace private var namespace
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let isSelected = selection == item
                Button {
                    Haptics.selection()
                    withAnimation(PulseMotion.snappy) {
                        selection = item
                    }
                } label: {
                    Text(label(item))
                        .font(PulseFont.caption)
                        .foregroundStyle(isSelected ? PulsePalette.ink : PulsePalette.inkTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(PulsePalette.card)
                                    .matchedGeometryEffect(id: "segment", in: namespace)
                                    .pulseShadow(PulseShadow(
                                        color: scheme == .dark ? Color.black.opacity(0.45) : Color.black.opacity(0.06),
                                        radius: 8,
                                        y: 3
                                    ))
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(PulsePalette.cardSunken))
        .overlay(Capsule().strokeBorder(PulsePalette.strokeSoft, lineWidth: 1))
    }
}

// MARK: - Чип

struct PulseChip: View {
    let title: String
    var symbol: String?
    var isSelected: Bool = false
    var tint: Color = PulsePalette.violetFallback
    var showsChevron: Bool = false
    var action: (() -> Void)?

    var body: some View {
        let content = HStack(spacing: 6) {
            if let symbol = symbol {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
            }
            Text(title)
                .font(PulseFont.caption)
            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .opacity(0.6)
            }
        }
        .foregroundStyle(isSelected ? Color.white : PulsePalette.inkSecondary)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background {
            Capsule()
                .fill(isSelected ? AnyShapeStyle(PulseGradient.accent(tint)) : AnyShapeStyle(PulsePalette.cardSunken))
        }
        .overlay(
            Capsule().strokeBorder(
                isSelected ? Color.clear : PulsePalette.strokeSoft,
                lineWidth: 1
            )
        )

        if let action = action {
            Button {
                Haptics.selection()
                withAnimation(PulseMotion.snappy) { action() }
            } label: {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: - Кнопки

struct PulsePrimaryButtonStyle: ButtonStyle {
    var accent: Color = PulsePalette.violetFallback
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PulseFont.headline)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 15)
            .frame(maxWidth: fullWidth ? CGFloat.infinity : nil)
            .background(PulseGradient.accent(accent), in: Capsule())
            .shadow(color: accent.opacity(configuration.isPressed ? 0.15 : 0.3), radius: 16, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(PulseMotion.snappy, value: configuration.isPressed)
    }
}

struct PulseSecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PulseFont.subheadline)
            .foregroundStyle(PulsePalette.ink)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? CGFloat.infinity : nil)
            .background(PulsePalette.cardSunken, in: Capsule())
            .overlay(Capsule().strokeBorder(PulsePalette.stroke, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(PulseMotion.snappy, value: configuration.isPressed)
    }
}

struct CircleIconButton: View {
    let symbol: String
    var size: CGFloat = 40
    var tint: Color = PulsePalette.ink
    var background: Color = PulsePalette.cardSunken
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(background, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Плитка статистики

struct StatTile: View {
    let value: String
    let title: String
    var symbol: String?
    var tint: Color = PulsePalette.ink
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 6) {
            HStack(spacing: 5) {
                if let symbol = symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 10, weight: .bold))
                }
                Text(title.uppercased())
                    .font(PulseFont.micro)
                    .tracking(0.6)
            }
            .foregroundStyle(PulsePalette.inkTertiary)

            Text(value)
                .font(PulseFont.number(22, .bold))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }
}

// MARK: - Разделитель

struct PulseDivider: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(PulsePalette.divider)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

// MARK: - Пустое состояние

struct EmptyState: View {
    let symbol: String
    let title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(PulsePalette.cardSunken)
                    .frame(width: 64, height: 64)
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(PulsePalette.inkTertiary)
            }
            Text(title)
                .font(PulseFont.headline)
                .foregroundStyle(PulsePalette.ink)
                .multilineTextAlignment(.center)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(PulseFont.caption)
                    .foregroundStyle(PulsePalette.inkTertiary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                }
                .buttonStyle(PulseSecondaryButtonStyle(fullWidth: false))
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 16)
    }
}

// MARK: - Прогресс-бар

struct PulseProgressBar: View {
    var progress: Double
    var tint: Color = PulsePalette.violetFallback
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(PulsePalette.cardSunken)
                Capsule()
                    .fill(PulseGradient.accent(tint))
                    .frame(width: max(0, proxy.size.width * CGFloat(min(1, max(0, progress)))))
                    .animation(PulseMotion.progress, value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Пилюля-метка

struct TagPill: View {
    let text: String
    var tint: Color = PulsePalette.inkSecondary
    var filled: Bool = false

    var body: some View {
        Text(text)
            .font(PulseFont.micro)
            .foregroundStyle(filled ? Color.white : tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .fill(filled ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.12)))
            }
    }
}

// MARK: - Строка «иконка + значение»

struct MetaLabel: View {
    let symbol: String
    let text: String
    var tint: Color = PulsePalette.inkTertiary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(PulseFont.caption)
        }
        .foregroundStyle(tint)
    }
}

// MARK: - Заголовок экрана

struct ScreenHeader: View {
    let overline: String?
    let title: String
    var subtitle: String?
    var trailing: AnyView?

    init(
        overline: String? = nil,
        title: String,
        subtitle: String? = nil,
        trailing: AnyView? = nil
    ) {
        self.overline = overline
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let overline = overline {
                    Text(overline.uppercased())
                        .font(PulseFont.micro)
                        .tracking(1.1)
                        .foregroundStyle(PulsePalette.inkTertiary)
                }
                Text(title)
                    .font(PulseFont.displayM)
                    .foregroundStyle(PulsePalette.ink)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(PulseFont.caption)
                        .foregroundStyle(PulsePalette.inkTertiary)
                }
            }
            Spacer(minLength: 0)
            if let trailing = trailing {
                trailing
            }
        }
    }
}

// MARK: - Мягкая «капсула-счётчик»

struct CounterPill: View {
    let value: Int
    var title: String?
    var tint: Color = PulsePalette.inkSecondary

    var body: some View {
        HStack(spacing: 5) {
            Text("\(value)")
                .font(PulseFont.number(13, .bold))
                .contentTransition(.numericText())
            if let title = title {
                Text(title)
                    .font(PulseFont.micro)
            }
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.10), in: Capsule())
    }
}
