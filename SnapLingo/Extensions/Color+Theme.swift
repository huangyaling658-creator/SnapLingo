import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    // MARK: - Minimal Premium Theme
    static let bg = Color(hex: "FAFAFA")
    static let surface = Color.white
    static let textPrimary = Color(hex: "1A1A1A")
    static let accentSoft = Color(hex: "3A3A3A")
    static let subtle = Color(hex: "8E8E93")
    static let border = Color(hex: "E5E5EA")
    static let cardBg = Color.white
    static let highlight = Color(hex: "007AFF")
    static let highlightSoft = Color(hex: "007AFF").opacity(0.08)

    // MARK: - TypeBadge Colors
    static let nounBg = Color(hex: "E3F2FD")
    static let nounText = Color(hex: "1565C0")
    static let adjBg = Color(hex: "FFF3E0")
    static let adjText = Color(hex: "E65100")
    static let verbBg = Color(hex: "E8F5E9")
    static let verbText = Color(hex: "2E7D32")
}
