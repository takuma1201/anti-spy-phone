import SwiftUI

// MARK: - Nothing Design System — Typography
//
// FONT SETUP (one-time Xcode task):
//   1. Download from Google Fonts:
//      • Doto (variable) — https://fonts.google.com/specimen/Doto
//      • Space Grotesk (300, 400, 500, 700) — https://fonts.google.com/specimen/Space+Grotesk
//      • Space Mono (400, 700) — https://fonts.google.com/specimen/Space+Mono
//   2. Add all .ttf files to AntiSpyPhone/Resources/ (create folder if needed)
//   3. In Info.plist add key "Fonts provided by application" (UIAppFonts / ATSApplicationFontsPath)
//      with each filename as an array entry
//   After that the .custom() calls below resolve; until then they fall back to system mono/sans.

// MARK: - Font helpers

struct NFont {
    // Display — Doto dot-matrix. Hero moments only. 36px+.
    static func doto(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Doto", fixedSize: size).weight(weight)
    }

    // Body / UI — Space Grotesk
    static func grotesk(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("SpaceGrotesk-Regular", fixedSize: size).weight(weight)
    }

    // Data / Labels — Space Mono. Use ALL CAPS externally.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("SpaceMono-Regular", fixedSize: size).weight(weight)
    }

    // Type scale tokens (Nothing design system)
    static let displayXL  = doto(72)           // hero numbers, time displays
    static let displayLG  = doto(48)           // section heroes
    static let displayMD  = doto(36)           // page-level Doto moments
    static let heading    = grotesk(24, weight: .medium)
    static let subheading = grotesk(18, weight: .regular)
    static let body       = grotesk(16, weight: .regular)
    static let bodySM     = grotesk(14, weight: .regular)
    static let caption    = grotesk(12, weight: .regular)
    static let label      = mono(11)           // ALL CAPS, letter-spacing 0.08em
    static let monoData   = mono(14)           // numeric data, values
    static let monoBody   = mono(16)           // raw JSON, code
}

// MARK: - Cursor helper

extension View {
    func pointingHandCursor() -> some View {
        self.onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }
}

// MARK: - Dot-grid background

struct DotGridBackground: View {
    var spacing: CGFloat = 16
    var dotSize: CGFloat = 1
    var opacity: Double  = 0.12

    var body: some View {
        Canvas { ctx, size in
            let cols = Int(size.width  / spacing) + 1
            let rows = Int(size.height / spacing) + 1
            for col in 0..<cols {
                for row in 0..<rows {
                    let x = CGFloat(col) * spacing
                    let y = CGFloat(row) * spacing
                    let rect = CGRect(x: x - dotSize/2, y: y - dotSize/2,
                                      width: dotSize, height: dotSize)
                    ctx.fill(Path(ellipseIn: rect),
                             with: .color(.ndBorderVisible.opacity(opacity)))
                }
            }
        }
    }
}

// MARK: - Nothing label modifier

extension Text {
    func ndLabel() -> some View {
        self
            .font(NFont.label)
            .foregroundStyle(Color.ndTextSecondary)
            .tracking(1.5)
            .textCase(.uppercase)
    }
}
