import SwiftUI

/// Unified Design System for HealthAI 2030
/// Provides consistent design tokens across all platforms
public struct HealthAIDesignSystem {
    
    // MARK: - Color System
    public struct Colors {
        // Primary Brand Colors
        public static let primary = Color("Primary")
        public static let secondary = Color("Secondary")
        public static let accent = Color("Accent")
        
        // Semantic Colors
        public static let success = Color("Success")
        public static let warning = Color("Warning")
        public static let error = Color("Error")
        public static let info = Color("Info")
        
        // Health-Specific Colors
        public static let heartRate = Color("HeartRate")
        public static let sleep = Color("Sleep")
        public static let activity = Color("Activity")
        public static let nutrition = Color("Nutrition")
        public static let mentalHealth = Color("MentalHealth")
        public static let respiratory = Color("Respiratory")
        public static let bloodPressure = Color("BloodPressure")
        public static let glucose = Color("Glucose")
        public static let weight = Color("Weight")
        public static let temperature = Color("Temperature")
        
        // Background Colors
        public static let background = Color("Background")
        public static let surface = Color("Surface")
        public static let card = Color("Card")
        public static let overlay = Color("Overlay")
        
        // Text Colors
        public static let textPrimary = Color("TextPrimary")
        public static let textSecondary = Color("TextSecondary")
        public static let textTertiary = Color("TextTertiary")
        public static let textInverse = Color("TextInverse")
        
        // Border Colors
        public static let border = Color("Border")
        public static let borderLight = Color("BorderLight")
        
        // Status Colors
        public static let healthy = Color("Healthy")
        public static let elevated = Color("Elevated")
        public static let critical = Color("Critical")
        public static let unknown = Color("Unknown")
    }
    
    // MARK: - Typography System
    public struct Typography {
        public static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
        public static let title1 = Font.system(.title, design: .rounded, weight: .bold)
        public static let title2 = Font.system(.title2, design: .rounded, weight: .semibold)
        public static let title3 = Font.system(.title3, design: .rounded, weight: .semibold)
        public static let headline = Font.system(.headline, design: .rounded, weight: .medium)
        public static let body = Font.system(.body, design: .rounded, weight: .regular)
        public static let callout = Font.system(.callout, design: .rounded, weight: .regular)
        public static let subheadline = Font.system(.subheadline, design: .rounded, weight: .medium)
        public static let footnote = Font.system(.footnote, design: .rounded, weight: .regular)
        public static let caption1 = Font.system(.caption, design: .rounded, weight: .regular)
        public static let caption2 = Font.system(.caption2, design: .rounded, weight: .regular)
        
        // Health-specific typography
        public static let metricValue = Font.system(.largeTitle, design: .rounded, weight: .bold)
        public static let metricUnit = Font.system(.body, design: .rounded, weight: .medium)
        public static let metricLabel = Font.system(.headline, design: .rounded, weight: .semibold)
        public static let alertTitle = Font.system(.title2, design: .rounded, weight: .bold)
        public static let alertMessage = Font.system(.body, design: .rounded, weight: .regular)
    }
    
    // MARK: - Spacing System
    public struct Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
        public static let xxxl: CGFloat = 64
        
        // Component-specific spacing
        public static let cardPadding: CGFloat = 20
        public static let buttonPadding: CGFloat = 16
        public static let listItemSpacing: CGFloat = 12
        public static let sectionSpacing: CGFloat = 32
    }
    
    // MARK: - Layout System
    public struct Layout {
        public static let cornerRadius: CGFloat = 12
        public static let cornerRadiusSmall: CGFloat = 8
        public static let cornerRadiusLarge: CGFloat = 16
        public static let cornerRadiusExtraLarge: CGFloat = 24
        
        public static let shadowRadius: CGFloat = 8
        public static let shadowRadiusSmall: CGFloat = 4
        public static let shadowRadiusLarge: CGFloat = 16
        public static let shadowOpacity: Float = 0.1
        public static let shadowOpacityLight: Float = 0.05
        public static let shadowOpacityHeavy: Float = 0.2
        
        public static let animationDuration: Double = 0.3
        public static let animationDurationFast: Double = 0.15
        public static let animationDurationSlow: Double = 0.6
        public static let animationSpring: Animation = .spring(response: 0.3, dampingFraction: 0.8)
        public static let animationSpringBouncy: Animation = .spring(response: 0.4, dampingFraction: 0.6)
        public static let animationEaseInOut: Animation = .easeInOut(duration: 0.3)
        
        // Component dimensions
        public static let buttonHeight: CGFloat = 48
        public static let buttonHeightSmall: CGFloat = 36
        public static let buttonHeightLarge: CGFloat = 56
        public static let cardMinHeight: CGFloat = 120
        public static let iconSize: CGFloat = 24
        public static let iconSizeSmall: CGFloat = 16
        public static let iconSizeLarge: CGFloat = 32
    }
    
    // MARK: - Platform-Specific Adjustments
    public struct Platform {
        #if os(iOS)
        public static let isIOS = true
        public static let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        public static let isIPhone = UIDevice.current.userInterfaceIdiom == .phone
        #else
        public static let isIOS = false
        public static let isIPad = false
        public static let isIPhone = false
        #endif
        
        #if os(macOS)
        public static let isMacOS = true
        #else
        public static let isMacOS = false
        #endif
        
        #if os(watchOS)
        public static let isWatchOS = true
        #else
        public static let isWatchOS = false
        #endif
        
        #if os(tvOS)
        public static let isTVOS = true
        #else
        public static let isTVOS = false
        #endif
    }
}

// MARK: - Design System Extensions
extension Color {
    /// Semantic color for health metrics
    public static func healthMetric(_ type: HealthMetricType) -> Color {
        switch type {
        case .heartRate:
            return HealthAIDesignSystem.Colors.heartRate
        case .sleep:
            return HealthAIDesignSystem.Colors.sleep
        case .activity:
            return HealthAIDesignSystem.Colors.activity
        case .nutrition:
            return HealthAIDesignSystem.Colors.nutrition
        case .mentalHealth:
            return HealthAIDesignSystem.Colors.mentalHealth
        case .respiratory:
            return HealthAIDesignSystem.Colors.respiratory
        case .bloodPressure:
            return HealthAIDesignSystem.Colors.bloodPressure
        case .glucose:
            return HealthAIDesignSystem.Colors.glucose
        case .weight:
            return HealthAIDesignSystem.Colors.weight
        case .temperature:
            return HealthAIDesignSystem.Colors.temperature
        }
    }
    
    /// Status color based on health value
    public static func healthStatus(_ status: HealthStatus) -> Color {
        switch status {
        case .healthy:
            return HealthAIDesignSystem.Colors.healthy
        case .elevated:
            return HealthAIDesignSystem.Colors.elevated
        case .critical:
            return HealthAIDesignSystem.Colors.critical
        case .unknown:
            return HealthAIDesignSystem.Colors.unknown
        }
    }
}

// MARK: - Supporting Types
public enum HealthMetricType {
    case heartRate, sleep, activity, nutrition, mentalHealth, respiratory, bloodPressure, glucose, weight, temperature
}

public enum HealthStatus {
    case healthy, elevated, critical, unknown
}
