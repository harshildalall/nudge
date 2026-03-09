import SwiftUI

// MARK: - Albert Sans font helper
extension Font {
    static func albertSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:     return .custom("AlbertSans-Bold", size: size)
        case .semibold: return .custom("AlbertSans-SemiBold", size: size)
        case .medium:   return .custom("AlbertSans-Medium", size: size)
        case .light:    return .custom("AlbertSans-Light", size: size)
        case .ultraLight, .thin:
                        return .custom("AlbertSans-ExtraLight", size: size)
        default:        return .custom("AlbertSans-Regular", size: size)
        }
    }

    static func albertSansItalic(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:     return .custom("AlbertSans-BoldItalic", size: size)
        case .semibold: return .custom("AlbertSans-SemiBoldItalic", size: size)
        default:        return .custom("AlbertSans-Italic", size: size)
        }
    }
}

// MARK: - Hex color initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    static let nudgeButton = Color(hex: "7A92A5")
    /// Light blue card surface used throughout the app
    static let cardSurface = Color(hex: "E2EDF5")
}

// MARK: - Shared background components
struct NudgeBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: "EDF1F5"), Color(hex: "D5E0EA")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Light blue-to-white gradient used across the main app tabs and sheets.
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: "D5E4EF"), Color(hex: "EEF3F8"), Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// Gradient fill used for progress bars (light → dark blue, left → right).
struct NudgeProgressGradient: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: "B5CCE0"), Color(hex: "3D6178")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct NudgePrimaryButton: View {
    let title: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.albertSans(17, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.nudgeButton)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 32)
    }
}

struct NudgeBackButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.albertSans(13, weight: .medium))
                Text("Back")
                    .font(.albertSans(14, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.nudgeButton)
            .clipShape(Capsule())
        }
    }
}

// MARK: - App theme constants
enum Theme {
    static let primary = Color.black
    static let secondary = Color.gray
    static let background = Color.white
    /// Teal accent for buttons, progress, selected state (matches mockups)
    static let accent = Color(red: 0.35, green: 0.72, blue: 0.68)
    static let urgency = Color.red

    static let largeTitle  = Font.albertSans(22, weight: .bold)
    static let title       = Font.albertSans(18, weight: .semibold)
    static let headline    = Font.albertSans(16, weight: .semibold)
    static let body        = Font.albertSans(15)
    static let callout     = Font.albertSans(14)
    static let subheadline = Font.albertSans(13)
    static let caption     = Font.albertSans(11)
    static let caption2    = Font.albertSans(10)
}
