import SwiftUI

/// Comprehensive typography system for HealthAI 2030
/// Provides accessible typography scales, health-specific fonts, and dynamic type support
public struct TypographySystem {
    
    // MARK: - Display Typography
    
    /// Large display text for main headlines
    /// Supports Dynamic Type up to XXXL
    public static let largeDisplay = Font.largeTitle.weight(.bold)
    
    /// Large display text (iOS 16+)
    /// Supports Dynamic Type up to XXXL
    public static let largeDisplay2 = Font.largeTitle2.weight(.bold)
    
    // MARK: - Title Typography
    
    /// Primary title - used for main section headers
    /// Supports Dynamic Type up to XXXL
    public static let title = Font.title.weight(.semibold)
    
    /// Secondary title - used for subsection headers
    /// Supports Dynamic Type up to XXXL
    public static let title2 = Font.title2.weight(.semibold)
    
    /// Tertiary title - used for card headers and important labels
    /// Supports Dynamic Type up to XXXL
    public static let title3 = Font.title3.weight(.semibold)
    
    // MARK: - Headline Typography
    
    /// Primary headline - used for content section headers
    /// Supports Dynamic Type up to XXXL
    public static let headline = Font.headline.weight(.medium)
    
    /// Secondary headline - used for supporting headers
    /// Supports Dynamic Type up to XXXL
    public static let subheadline = Font.subheadline.weight(.medium)
    
    // MARK: - Body Typography
    
    /// Primary body text - used for main content
    /// Supports Dynamic Type up to XXXL
    public static let body = Font.body
    
    /// Bold body text - used for emphasized content
    /// Supports Dynamic Type up to XXXL
    public static let bodyBold = Font.body.weight(.semibold)
    
    /// Callout text - used for highlighted information
    /// Supports Dynamic Type up to XXXL
    public static let callout = Font.callout
    
    // MARK: - Caption Typography
    
    /// Primary caption - used for supporting information
    /// Supports Dynamic Type up to XXXL
    public static let caption = Font.caption
    
    /// Secondary caption - used for subtle information
    /// Supports Dynamic Type up to XXXL
    public static let caption2 = Font.caption2
    
    /// Footnote text - used for references and small print
    /// Supports Dynamic Type up to XXXL
    public static let footnote = Font.footnote
    
    // MARK: - Health-Specific Typography
    
    /// Large health metric display - for prominent health numbers
    /// Rounded design for medical equipment aesthetic
    public static let healthMetricLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    
    /// Medium health metric display - for standard health numbers
    /// Rounded design for medical equipment aesthetic
    public static let healthMetricMedium = Font.system(size: 32, weight: .bold, design: .rounded)
    
    /// Small health metric display - for compact health numbers
    /// Rounded design for medical equipment aesthetic
    public static let healthMetricSmall = Font.system(size: 24, weight: .semibold, design: .rounded)
    
    /// Health metric label - for health metric descriptions
    /// Clear, readable design for medical contexts
    public static let healthMetricLabel = Font.system(size: 14, weight: .medium, design: .default)
    
    /// Health metric unit - for measurement units
    /// Smaller, subtle design for units
    public static let healthMetricUnit = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Medical Typography
    
    /// Medical reading - optimized for medical text readability
    /// Slightly larger for medical professionals
    public static let medicalReading = Font.system(size: 16, weight: .regular, design: .serif)
    
    /// Medical label - for medical terminology
    /// Clear, professional appearance
    public static let medicalLabel = Font.system(size: 14, weight: .medium, design: .default)
    
    /// Medical caption - for medical notes and references
    /// Smaller, professional appearance
    public static let medicalCaption = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Accessibility Typography
    
    /// Get dynamic type font with custom weight
    /// - Parameters:
    ///   - style: The text style for dynamic scaling
    ///   - weight: The font weight
    /// - Returns: A font that scales with accessibility settings
    public static func dynamicType(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        return Font.system(style, design: .default).weight(weight)
    }
    
    /// Get dynamic type font with rounded design
    /// - Parameters:
    ///   - style: The text style for dynamic scaling
    ///   - weight: The font weight
    /// - Returns: A rounded font that scales with accessibility settings
    public static func dynamicTypeRounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        return Font.system(style, design: .rounded).weight(weight)
    }
    
    /// Get dynamic type font with serif design
    /// - Parameters:
    ///   - style: The text style for dynamic scaling
    ///   - weight: The font weight
    /// - Returns: A serif font that scales with accessibility settings
    public static func dynamicTypeSerif(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        return Font.system(style, design: .serif).weight(weight)
    }
    
    /// Get dynamic type font with monospaced design
    /// - Parameters:
    ///   - style: The text style for dynamic scaling
    ///   - weight: The font weight
    /// - Returns: A monospaced font that scales with accessibility settings
    public static func dynamicTypeMonospaced(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        return Font.system(style, design: .monospaced).weight(weight)
    }
    
    // MARK: - Typography Utilities
    
    /// Get typography for specific content type
    /// - Parameter type: The content type
    /// - Returns: Appropriate font for the content type
    public static func forContentType(_ type: ContentType) -> Font {
        switch type {
        case .mainHeading:
            return largeDisplay
        case .sectionHeading:
            return title
        case .subsectionHeading:
            return title2
        case .bodyText:
            return body
        case .caption:
            return caption
        case .healthMetric:
            return healthMetricMedium
        case .medicalText:
            return medicalReading
        }
    }
    
    /// Get typography for specific health metric
    /// - Parameter metric: The health metric type
    /// - Returns: Appropriate font for the health metric
    public static func forHealthMetric(_ metric: HealthMetricType) -> Font {
        switch metric {
        case .heartRate, .bloodPressure, .temperature, .oxygen:
            return healthMetricMedium
        case .sleep, .activity, .nutrition, .mentalHealth:
            return healthMetricSmall
        }
    }
    
    /// Check if font size is accessible
    /// - Parameter fontSize: The font size to check
    /// - Returns: True if the font size meets accessibility standards
    public static func isAccessibleSize(_ fontSize: CGFloat) -> Bool {
        return fontSize >= 8.0 // Minimum accessible font size
    }
    
    /// Get line height for optimal readability
    /// - Parameter font: The font to calculate line height for
    /// - Returns: Recommended line height multiplier
    public static func lineHeight(for font: Font) -> CGFloat {
        // Placeholder implementation - would calculate optimal line height
        return 1.4 // Standard line height for body text
    }
}

// MARK: - Supporting Enums

/// Content types for typography selection
public enum ContentType {
    case mainHeading
    case sectionHeading
    case subsectionHeading
    case bodyText
    case caption
    case healthMetric
    case medicalText
}

/// Health metric types for typography selection
public enum HealthMetricType {
    case heartRate
    case bloodPressure
    case temperature
    case oxygen
    case sleep
    case activity
    case nutrition
    case mentalHealth
}

// MARK: - Typography Extensions

extension Font {
    /// Typography system shortcuts
    public static var healthLargeDisplay: Font { TypographySystem.largeDisplay }
    public static var healthTitle: Font { TypographySystem.title }
    public static var healthTitle2: Font { TypographySystem.title2 }
    public static var healthTitle3: Font { TypographySystem.title3 }
    public static var healthHeadline: Font { TypographySystem.headline }
    public static var healthSubheadline: Font { TypographySystem.subheadline }
    public static var healthBody: Font { TypographySystem.body }
    public static var healthBodyBold: Font { TypographySystem.bodyBold }
    public static var healthCallout: Font { TypographySystem.callout }
    public static var healthCaption: Font { TypographySystem.caption }
    public static var healthCaption2: Font { TypographySystem.caption2 }
    public static var healthFootnote: Font { TypographySystem.footnote }
    
    /// Health-specific typography shortcuts
    public static var healthMetricLarge: Font { TypographySystem.healthMetricLarge }
    public static var healthMetricMedium: Font { TypographySystem.healthMetricMedium }
    public static var healthMetricSmall: Font { TypographySystem.healthMetricSmall }
    public static var healthMetricLabel: Font { TypographySystem.healthMetricLabel }
    public static var healthMetricUnit: Font { TypographySystem.healthMetricUnit }
    public static var medicalReading: Font { TypographySystem.medicalReading }
    public static var medicalLabel: Font { TypographySystem.medicalLabel }
    public static var medicalCaption: Font { TypographySystem.medicalCaption }
}

// MARK: - Typography Modifiers

extension View {
    /// Apply health typography with accessibility support
    /// - Parameter typography: The typography to apply
    /// - Returns: View with applied typography
    public func healthTypography(_ typography: Font) -> some View {
        self.font(typography)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
    
    /// Apply health typography with custom line height
    /// - Parameters:
    ///   - typography: The typography to apply
    ///   - lineHeight: The line height multiplier
    /// - Returns: View with applied typography and line height
    public func healthTypography(_ typography: Font, lineHeight: CGFloat) -> some View {
        self.font(typography)
            .lineSpacing(lineHeight - 1.0)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
} 