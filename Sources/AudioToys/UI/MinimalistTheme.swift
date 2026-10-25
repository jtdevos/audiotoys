import SwiftUI

public struct AudioToyStyle {
    public static let bgDark = Color(red: 0.05, green: 0.06, blue: 0.09)
    public static let surfaceDark = Color(red: 0.10, green: 0.12, blue: 0.16)
    public static let surfaceGlass = Color(red: 0.14, green: 0.16, blue: 0.22).opacity(0.8)
    public static let borderGlass = Color.white.opacity(0.12)
    public static let textPrimary = Color.white
    public static let textSecondary = Color.white.opacity(0.65)
    public static let textMuted = Color.white.opacity(0.4)
    public static let accentCyan = Color(red: 0.0, green: 0.94, blue: 1.0)
    public static let accentEmerald = Color(red: 0.0, green: 1.0, blue: 0.55)
}

extension Color {
    public init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch clean.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 240, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
