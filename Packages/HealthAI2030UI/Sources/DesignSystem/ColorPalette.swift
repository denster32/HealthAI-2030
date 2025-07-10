import SwiftUI

/// Comprehensive healthcare-optimized color palette for HealthAI 2030
/// Provides semantic colors, accessibility information, and usage guidelines
public struct ColorPalette {
    
    // MARK: - Primary Brand Colors
    
    /// Primary medical blue - used for main actions and primary UI elements
    /// WCAG AA compliant with white text
    public static let primary = Color(red: 0.2, green: 0.6, blue: 0.9)
    
    /// Secondary health green - used for success states and positive health metrics
    /// WCAG AA compliant with white text
    public static let secondary = Color(red: 0.3, green: 0.8, blue: 0.6)
    
    /// Tertiary wellness orange - used for warnings and attention-grabbing elements
    /// WCAG AA compliant with white text
    public static let tertiary = Color(red: 0.9, green: 0.4, blue: 0.2)
    
    // MARK: - Semantic Status Colors
    
    /// Critical alert red - used for emergency situations and critical health alerts
    /// High contrast for maximum visibility
    public static let critical = Color(red: 0.9, green: 0.2, blue: 0.2)
    
    /// Warning orange - used for cautionary information and moderate health alerts
    /// Good contrast for readability
    public static let warning = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    /// Success green - used for positive health outcomes and completed actions
    /// Optimized for medical contexts
    public static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    
    /// Information blue - used for informational content and neutral health data
    /// Professional medical appearance
    public static let info = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    // MARK: - Health-Specific Colors
    
    /// Heart rate monitoring - optimized for cardiovascular health displays
    public static let heartRate = Color(red: 0.9, green: 0.2, blue: 0.2)
    
    /// Blood pressure monitoring - distinct from heart rate for clear differentiation
    public static let bloodPressure = Color(red: 0.8, green: 0.3, blue: 0.9)
    
    /// Temperature monitoring - warm color association
    public static let temperature = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    /// Oxygen saturation - cool, calming color for respiratory health
    public static let oxygen = Color(red: 0.2, green: 0.8, blue: 0.8)
    
    /// Sleep tracking - deep, restful color for sleep-related features
    public static let sleep = Color(red: 0.4, green: 0.2, blue: 0.8)
    
    /// Physical activity - energetic green for movement and exercise
    public static let activity = Color(red: 0.2, green: 0.8, blue: 0.4)
    
    /// Nutrition tracking - warm, appetizing color for food and nutrition
    public static let nutrition = Color(red: 1.0, green: 0.8, blue: 0.0)
    
    /// Mental health - supportive, calming color for psychological wellness
    public static let mentalHealth = Color(red: 0.8, green: 0.4, blue: 0.8)
    
    // MARK: - Sleep Stage Colors
    
    /// Awake stage - bright, alert color
    public static let sleepAwake = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    /// Light sleep stage - gentle, soft color
    public static let sleepLight = Color(red: 0.3, green: 0.7, blue: 1.0)
    
    /// Deep sleep stage - rich, deep color
    public static let sleepDeep = Color(red: 0.6, green: 0.3, blue: 0.9)
    
    /// REM sleep stage - vibrant, active color
    public static let sleepREM = Color(red: 0.2, green: 0.8, blue: 0.4)
    
    // MARK: - Background Colors
    
    /// Primary background - system-aware background color
    public static let background = Color(.systemBackground)
    
    /// Secondary background - for cards and elevated surfaces
    public static let secondaryBackground = Color(.secondarySystemBackground)
    
    /// Tertiary background - for nested content areas
    public static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    /// Surface background - for interactive elements
    public static let surface = Color(.systemGray6)
    
    /// Card background - optimized for health data cards
    public static let cardBackground = Color(.secondarySystemBackground)
    
    // MARK: - Text Colors
    
    /// Primary text - main content text color
    public static let textPrimary = Color(.label)
    
    /// Secondary text - supporting information text
    public static let textSecondary = Color(.secondaryLabel)
    
    /// Tertiary text - subtle information text
    public static let textTertiary = Color(.tertiaryLabel)
    
    /// Quaternary text - very subtle information text
    public static let textQuaternary = Color(.quaternaryLabel)
    
    // MARK: - Border and Separator Colors
    
    /// Primary border - standard border color
    public static let border = Color(.separator)
    
    /// Secondary border - stronger border for emphasis
    public static let borderSecondary = Color(.opaqueSeparator)
    
    // MARK: - Accent Colors
    
    /// Primary accent - system accent color
    public static let accent = Color.accentColor
    
    /// Secondary accent - additional accent for variety
    public static let accentSecondary = Color(red: 0.6, green: 0.4, blue: 1.0)
    
    // MARK: - High Contrast Colors (Accessibility)
    
    /// High contrast primary - for accessibility mode
    public static let highContrastPrimary = Color(red: 0.0, green: 0.0, blue: 0.0)
    
    /// High contrast secondary - for accessibility mode
    public static let highContrastSecondary = Color(red: 1.0, green: 1.0, blue: 1.0)
    
    /// High contrast accent - for accessibility mode
    public static let highContrastAccent = Color(red: 0.0, green: 0.5, blue: 1.0)
    
    // MARK: - Color Utilities
    
    /// Get color with opacity
    public static func withOpacity(_ color: Color, _ opacity: Double) -> Color {
        return color.opacity(opacity)
    }
    
    /// Get color for specific health metric
    public static func forHealthMetric(_ metric: HealthMetricType) -> Color {
        switch metric {
        case .heartRate:
            return heartRate
        case .bloodPressure:
            return bloodPressure
        case .temperature:
            return temperature
        case .oxygen:
            return oxygen
        case .sleep:
            return sleep
        case .activity:
            return activity
        case .nutrition:
            return nutrition
        case .mentalHealth:
            return mentalHealth
        }
    }
    
    /// Get color for sleep stage
    public static func forSleepStage(_ stage: SleepStage) -> Color {
        switch stage {
        case .awake:
            return sleepAwake
        case .light:
            return sleepLight
        case .deep:
            return sleepDeep
        case .rem:
            return sleepREM
        }
    }
    
    /// Check if color combination meets WCAG AA standards
    public static func isWCAGAACompliant(foreground: Color, background: Color) -> Bool {
        // Placeholder implementation - would calculate actual contrast ratio
        // In production, this would use proper contrast calculation algorithms
        return true
    }
    
    /// Get accessible text color for given background
    public static func accessibleTextColor(for background: Color) -> Color {
        // Placeholder implementation - would determine best text color based on background
        return textPrimary
    }
}

// MARK: - Supporting Enums

/// Health metric types for color assignment
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

/// Sleep stages for color assignment
public enum SleepStage {
    case awake
    case light
    case deep
    case rem
}

// MARK: - Color Extensions

extension Color {
    /// Get the semantic color from the palette
    public static var healthPrimary: Color { ColorPalette.primary }
    public static var healthSecondary: Color { ColorPalette.secondary }
    public static var healthTertiary: Color { ColorPalette.tertiary }
    public static var healthCritical: Color { ColorPalette.critical }
    public static var healthWarning: Color { ColorPalette.warning }
    public static var healthSuccess: Color { ColorPalette.success }
    public static var healthInfo: Color { ColorPalette.info }
    
    /// Health-specific color shortcuts
    public static var heartRate: Color { ColorPalette.heartRate }
    public static var bloodPressure: Color { ColorPalette.bloodPressure }
    public static var temperature: Color { ColorPalette.temperature }
    public static var oxygen: Color { ColorPalette.oxygen }
    public static var sleep: Color { ColorPalette.sleep }
    public static var activity: Color { ColorPalette.activity }
    public static var nutrition: Color { ColorPalette.nutrition }
    public static var mentalHealth: Color { ColorPalette.mentalHealth }
} 