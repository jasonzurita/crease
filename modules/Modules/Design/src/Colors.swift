import SwiftUI

public extension Color {
    static let crBackground = Color(hex: 0x1B2E4B)
    static let crSurface = Color(hex: 0x243757)
    static let crAccent = Color(hex: 0x3B9EFF)
    static let crSuccess = Color(hex: 0x2DD4A7)
    static let crWarning = Color(hex: 0xF5A623)
    static let crDanger = Color(hex: 0xFF4757)
    static let crTextPrimary = Color(hex: 0xF0F4F8)
    static let crTextSecondary = Color(hex: 0x8BA3BC)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
