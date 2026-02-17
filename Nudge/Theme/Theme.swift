import SwiftUI

enum Theme {
    static let primary = Color.black
    static let secondary = Color.gray
    static let background = Color.white
    /// Teal accent for buttons, progress, selected state (matches mockups)
    static let accent = Color(red: 0.35, green: 0.72, blue: 0.68)
    static let urgency = Color.red

    // iPhone-appropriate font sizes (compact, not oversized)
    static let largeTitle = Font.system(size: 22, weight: .bold)
    static let title = Font.system(size: 18, weight: .semibold)
    static let headline = Font.system(size: 16, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let callout = Font.system(size: 14, weight: .regular)
    static let subheadline = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 11, weight: .regular)
    static let caption2 = Font.system(size: 10, weight: .regular)
}
