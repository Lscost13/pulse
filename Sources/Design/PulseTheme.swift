//
//  PulseTheme.swift
//  PULSE
//
//  Визуальный язык приложения: палитра, типографика, метрики, движение.
//  Всё в одном месте — чтобы ни один экран не «изобретал» свои цвета.
//

import UIKit
import SwiftUI

// MARK: - HEX

extension Color {
    init(hex: String) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") {
            string.removeFirst()
        }
        var value: UInt64 = 0
        Scanner(string: string).scanHexInt64(&value)

        var red: Double = 0.5
        var green: Double = 0.5
        var blue: Double = 0.5
        var alpha: Double = 1.0

        if string.count == 8 {
            red = Double((value >> 24) & 0xFF) / 255.0
            green = Double((value >> 16) & 0xFF) / 255.0
            blue = Double((value >> 8) & 0xFF) / 255.0
            alpha = Double(value & 0xFF) / 255.0
        } else if string.count == 6 {
            red = Double((value >> 16) & 0xFF) / 255.0
            green = Double((value >> 8) & 0xFF) / 255.0
            blue = Double(value & 0xFF) / 255.0
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    /// Цвет, который сам подстраивается под светлую и тёмную тему.
    static func dynamic(light: String, dark: String) -> Color {
        let lightColor = Color(hex: light)
        let darkColor = Color(hex: dark)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(darkColor) : UIColor(lightColor)
        })
    }

    /// Цвет категории с запасным акцентом.
    static func category(_ hex: String?) -> Color {
        guard let hex = hex, !hex.isEmpty else { return PulsePalette.violetFallback }
        return Color(hex: hex)
    }
}

// MARK: - Палитра

enum PulsePalette {
    static let background = Color.dynamic(light: "#FAF9FC", dark: "#07070B")
    static let backgroundDeep = Color.dynamic(light: "#F4F2F8", dark: "#040407")
    static let surface = Color.dynamic(light: "#FFFFFF", dark: "#101016")
    static let card = Color.dynamic(light: "#FFFFFF", dark: "#15151D")
    static let cardElevated = Color.dynamic(light: "#FFFFFF", dark: "#1B1B25")
    static let cardSunken = Color.dynamic(light: "#F5F3F9", dark: "#0C0C12")

    static let stroke = Color.dynamic(light: "#EAE7F1", dark: "#26262F")
    static let strokeSoft = Color.dynamic(light: "#F2F0F7", dark: "#1E1E27")

    static let ink = Color.dynamic(light: "#14131A", dark: "#F6F5FA")
    static let inkSecondary = Color.dynamic(light: "#6B6876", dark: "#A5A1B3")
    static let inkTertiary = Color.dynamic(light: "#9D9AA8", dark: "#767284")
    static let inkInverse = Color.dynamic(light: "#FFFFFF", dark: "#0A0A0F")

    static let divider = Color.dynamic(light: "#EFEDF4", dark: "#232330")

    static let violetFallback = Color(hex: "#7C6EEB")
    static let mint = Color.dynamic(light: "#1FAE9B", dark: "#5EEAD4")
    static let blush = Color.dynamic(light: "#DD5A88", dark: "#FF8ABE")
    static let amber = Color.dynamic(light: "#D4863A", dark: "#F5B563")
    static let sky = Color.dynamic(light: "#3B7BEF", dark: "#8CC0FF")
    static let success = Color.dynamic(light: "#22A06B", dark: "#4ADE80")
    static let danger = Color.dynamic(light: "#DB4358", dark: "#FF6B81")

    static let cardShadow = Color.dynamic(light: "#1B1035", dark: "#000000")
}

// MARK: - Акценты

extension AccentTheme {
    var lightHex: String {
        switch self {
        case .violet: return "#7C6EEB"
        case .mint: return "#12A594"
        case .ember: return "#E0673A"
        case .ocean: return "#2F6FE4"
        }
    }

    var darkHex: String {
        switch self {
        case .violet: return "#A99BFF"
        case .mint: return "#5EEAD4"
        case .ember: return "#FFA179"
        case .ocean: return "#83B6FF"
        }
    }

    var softLightHex: String {
        switch self {
        case .violet: return "#EFECFF"
        case .mint: return "#E1F7F3"
        case .ember: return "#FCEDE5"
        case .ocean: return "#E7F0FE"
        }
    }

    var softDarkHex: String {
        switch self {
        case .violet: return "#201C33"
        case .mint: return "#122824"
        case .ember: return "#2B1E17"
        case .ocean: return "#141F31"
        }
    }

    var color: Color {
        Color.dynamic(light: lightHex, dark: darkHex)
    }

    var soft: Color {
        Color.dynamic(light: softLightHex, dark: softDarkHex)
    }

    /// Цвет для превью в настройках (не зависит от темы).
    var swatch: Color {
        Color(hex: lightHex)
    }
}

// MARK: - Типографика

enum PulseFont {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func number(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static let displayXL = rounded(46, .bold)
    static let displayL = rounded(36, .bold)
    static let displayM = rounded(28, .bold)
    static let title = rounded(22, .semibold)
    static let headline = rounded(17, .semibold)
    static let subheadline = rounded(15, .medium)
    static let body = Font.system(size: 15.5, weight: .regular)
    static let bodyMedium = Font.system(size: 15.5, weight: .medium)
    static let callout = Font.system(size: 14, weight: .medium)
    static let caption = Font.system(size: 12.5, weight: .medium)
    static let micro = Font.system(size: 11, weight: .semibold)
    static let overline = Font.system(size: 11.5, weight: .bold)
}

// MARK: - Метрики

enum PulseMetrics {
    static let screenPadding: CGFloat = 20
    static let cardRadius: CGFloat = 26
    static let innerRadius: CGFloat = 18
    static let chipRadius: CGFloat = 14
    static let sectionSpacing: CGFloat = 24
    static let rowSpacing: CGFloat = 12
    static let tabBarHeight: CGFloat = 64
    static let minTouch: CGFloat = 44
    static let ringLineWidth: CGFloat = 16
}

// MARK: - Движение

enum PulseMotion {
    static let smooth = Animation.spring(response: 0.45, dampingFraction: 0.86)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.72)
    static let soft = Animation.easeInOut(duration: 0.32)
    static let theme = Animation.easeInOut(duration: 0.5)
    static let progress = Animation.spring(response: 0.7, dampingFraction: 0.8)
}

// MARK: - Градиенты

enum PulseGradient {
    static func accent(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func accentGlow(_ color: Color) -> RadialGradient {
        RadialGradient(
            colors: [color.opacity(0.35), color.opacity(0.0)],
            center: .center,
            startRadius: 0,
            endRadius: 160
        )
    }

    static func cardSheen(_ color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.16), color.opacity(0.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let flame = LinearGradient(
        colors: [Color(hex: "#FFB86B"), Color(hex: "#FF7A59"), Color(hex: "#E0426B")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Тени

struct PulseShadow {
    let color: Color
    let radius: CGFloat
    let y: CGFloat

    static func card(_ scheme: ColorScheme) -> PulseShadow {
        scheme == .dark
            ? PulseShadow(color: Color.black.opacity(0.55), radius: 22, y: 12)
            : PulseShadow(color: PulsePalette.cardShadow.opacity(0.07), radius: 20, y: 10)
    }

    static func floating(_ scheme: ColorScheme) -> PulseShadow {
        scheme == .dark
            ? PulseShadow(color: Color.black.opacity(0.6), radius: 26, y: 14)
            : PulseShadow(color: PulsePalette.cardShadow.opacity(0.14), radius: 24, y: 12)
    }
}

extension View {
    func pulseShadow(_ shadow: PulseShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
    }
}
