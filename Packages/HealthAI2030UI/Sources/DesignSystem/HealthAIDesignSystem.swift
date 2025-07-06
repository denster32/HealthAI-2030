import SwiftUI

public struct HealthAIDesignSystem {
    public struct Color {
        // Semantic Colors
        public static let healthPrimary = SwiftUI.Color("healthPrimary")
        public static let healthSecondary = SwiftUI.Color("healthSecondary")
        public static let healthTertiary = SwiftUI.Color("healthTertiary")
        public static let warningRed = SwiftUI.Color("warningRed")
        public static let successGreen = SwiftUI.Color("successGreen")
        public static let infoBlue = SwiftUI.Color("infoBlue")
        public static let background = SwiftUI.Color(uiColor: .systemBackground)
        public static let surface = SwiftUI.Color(uiColor: .secondarySystemBackground)
        public static let textPrimary = SwiftUI.Color(uiColor: .label)
        public static let textSecondary = SwiftUI.Color(uiColor: .secondaryLabel)
        public static let border = SwiftUI.Color(uiColor: .separator)
        public static let accent = SwiftUI.Color.accentColor
    }

    public struct Typography {
        public static let largeTitle = Font.largeTitle.weight(.bold)
        public static let title = Font.title.weight(.semibold)
        public static let title2 = Font.title2.weight(.semibold)
        public static let title3 = Font.title3.weight(.semibold)
        public static let headline = Font.headline
        public static let subheadline = Font.subheadline
        public static let body = Font.body
        public static let callout = Font.callout
        public static let footnote = Font.footnote
        public static let caption = Font.caption
        public static let caption2 = Font.caption2
    }

    public struct Spacing {
        public static let extraSmall: CGFloat = 4
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 24
        public static let extraLarge: CGFloat = 32
        public static let section: CGFloat = 40
    }

    public struct Layout {
        public static let cornerRadius: CGFloat = 12
        public static let cardCornerRadius: CGFloat = 20
        public static let borderWidth: CGFloat = 1
        public static let shadowRadius: CGFloat = 6
        public static let minButtonHeight: CGFloat = 48
        public static let minTapArea: CGFloat = 44 // Apple HIG minimum
    }

    public struct Animation {
        public static let defaultCurve = SwiftUI.Animation.easeInOut(duration: 0.3)
        public static let springCurve = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2)
        public static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        public static let slow = SwiftUI.Animation.easeInOut(duration: 0.6)
    }

    // MARK: - Accessibility Helpers
    public struct Accessibility {
        public static func highContrastEnabled() -> Bool {
            UIAccessibility.isDarkerSystemColorsEnabled
        }

        public static func reduceMotionEnabled() -> Bool {
            UIAccessibility.isReduceMotionEnabled
        }
    }
}
