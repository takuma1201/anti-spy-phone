import SwiftUI

// MARK: - Nothing Design System — Dark Mode Palette

extension Color {
    // Base surfaces (OLED black)
    static let ndBlack          = Color(hex: "000000")   // primary bg
    static let ndSurface        = Color(hex: "111111")   // cards, panels
    static let ndSurfaceRaised  = Color(hex: "1A1A1A")   // sidebar, modals
    static let ndBorder         = Color(hex: "222222")   // subtle dividers
    static let ndBorderVisible  = Color(hex: "333333")   // intentional borders

    // Text hierarchy
    static let ndTextDisabled   = Color(hex: "666666")   // 40% — decorative, inactive
    static let ndTextSecondary  = Color(hex: "999999")   // 60% — labels, captions
    static let ndTextPrimary    = Color(hex: "E8E8E8")   // 90% — body
    static let ndTextDisplay    = Color(hex: "FFFFFF")   // 100% — hero numbers

    // Accent & status
    static let ndAccent         = Color(hex: "D71921")   // signal red — one per screen
    static let ndAccentSubtle   = Color(hex: "D71921").opacity(0.15)
    static let ndSuccess        = Color(hex: "4A9E5C")   // connected, active, granted
    static let ndWarning        = Color(hex: "D4A843")   // caution, pending
    static let ndInteractive    = Color(hex: "5B9BF6")   // tappable text, links

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
