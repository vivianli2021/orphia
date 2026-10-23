import SwiftUI

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

/// Palette ported 1:1 from the HTML prototype's `:root` CSS custom properties.
enum AppColors {
    static let bg = Color(hex: "#FBF4E8")
    static let pageBg = Color(hex: "#F1E6D3")
    static let ink = Color(hex: "#2B2015")
    static let muted = Color(hex: "#8B7A62")
    static let primary = Color(hex: "#C0392B")
    static let primaryDark = Color(hex: "#8E2A3C")
    static let rust = Color(hex: "#A8431F")
    static let carnation = Color(hex: "#AE2E26")
    static let carnationDark = Color(hex: "#7E1F1A")
    static let card = Color.white
    static let border = Color(hex: "#E8D9BC")
    static let gold = Color(hex: "#E0A940")
    static let selectedCardBg = Color(hex: "#FBE1DC")
    static let lyricHighlight = Color(hex: "#FDEEC9")
    static let stemGreen = Color(hex: "#6B7A4F")
}
