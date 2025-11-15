import SwiftUI

extension Color {
    // MARK: - Light Theme
    static let lightBackground = Color(hex: "#FFFAF1")
    static let lightText = Color(hex: "#11181C")
    static let lightTint = Color(hex: "#0a7ea4")
    static let lightIcon = Color(hex: "#687076")

    // MARK: - Dark Theme
    static let darkBackground = Color(hex: "#151718")
    static let darkText = Color(hex: "#ECEDEE")
    static let darkTint = Color.white
    static let darkIcon = Color(hex: "#9BA1A6")

    // MARK: - Custom Colors
    static let blob = Color(hex: "#F8D18A")
    static let lightGridLine = Color(hex: "#E6E6E6")
    static let darkGridLine = Color(hex: "#2A2A2A")
    static let inputBackground = Color(hex: "#EFEFEF")
    static let buttonBlack = Color(hex: "#1C1C1C")
    static let buttonGray = Color(hex: "#D9D9D9")

    // MARK: - Theme-aware colors
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkBackground : lightBackground
    }

    static func text(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkText : lightText
    }

    static func tint(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkTint : lightTint
    }

    static func icon(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkIcon : lightIcon
    }

    static func gridLine(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? darkGridLine : lightGridLine
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}
