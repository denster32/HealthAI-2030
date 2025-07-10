import SwiftUI

/// Comprehensive spacing grid system for HealthAI 2030
/// Provides consistent spacing values, responsive layouts, and accessibility considerations
public struct SpacingGrid {
    
    // MARK: - Base Spacing Units
    
    /// Base spacing unit (4pt) - fundamental building block
    public static let baseUnit: CGFloat = 4
    
    /// Micro spacing (2pt) - for very tight spacing
    public static let micro: CGFloat = 2
    
    /// Extra small spacing (4pt) - for minimal spacing
    public static let extraSmall: CGFloat = 4
    
    /// Small spacing (8pt) - for compact spacing
    public static let small: CGFloat = 8
    
    /// Medium spacing (16pt) - for standard spacing
    public static let medium: CGFloat = 16
    
    /// Large spacing (24pt) - for generous spacing
    public static let large: CGFloat = 24
    
    /// Extra large spacing (32pt) - for very generous spacing
    public static let extraLarge: CGFloat = 32
    
    // MARK: - Section Spacing
    
    /// Section spacing (40pt) - for major content sections
    public static let section: CGFloat = 40
    
    /// Large section spacing (48pt) - for prominent sections
    public static let sectionLarge: CGFloat = 48
    
    /// Extra large section spacing (64pt) - for major page sections
    public static let sectionExtraLarge: CGFloat = 64
    
    // MARK: - Component-Specific Spacing
    
    /// Card padding (20pt) - for card components
    public static let cardPadding: CGFloat = 20
    
    /// Button padding (16pt) - for button components
    public static let buttonPadding: CGFloat = 16
    
    /// List row padding (12pt) - for list items
    public static let listRowPadding: CGFloat = 12
    
    /// Form field spacing (20pt) - for form elements
    public static let formFieldSpacing: CGFloat = 20
    
    /// Chart padding (16pt) - for chart components
    public static let chartPadding: CGFloat = 16
    
    /// Navigation padding (16pt) - for navigation elements
    public static let navigationPadding: CGFloat = 16
    
    /// Modal padding (24pt) - for modal dialogs
    public static let modalPadding: CGFloat = 24
    
    /// Sheet padding (20pt) - for sheet presentations
    public static let sheetPadding: CGFloat = 20
    
    // MARK: - Grid System
    
    /// Grid spacing (16pt) - for grid layouts
    public static let gridSpacing: CGFloat = 16
    
    /// Number of grid columns
    public static let gridColumns: Int = 12
    
    /// Maximum content width
    public static let maxContentWidth: CGFloat = 1200
    
    // MARK: - Responsive Spacing
    
    /// Get responsive spacing based on device type
    /// - Parameter deviceType: The device type
    /// - Returns: Appropriate spacing for the device
    public static func responsiveSpacing(for deviceType: DeviceType) -> ResponsiveSpacing {
        switch deviceType {
        case .iPhone:
            return ResponsiveSpacing(
                small: 8,
                medium: 12,
                large: 16,
                extraLarge: 24
            )
        case .iPad:
            return ResponsiveSpacing(
                small: 12,
                medium: 16,
                large: 24,
                extraLarge: 32
            )
        case .mac:
            return ResponsiveSpacing(
                small: 16,
                medium: 20,
                large: 28,
                extraLarge: 40
            )
        case .watch:
            return ResponsiveSpacing(
                small: 4,
                medium: 6,
                large: 8,
                extraLarge: 12
            )
        case .tv:
            return ResponsiveSpacing(
                small: 24,
                medium: 32,
                large: 48,
                extraLarge: 64
            )
        }
    }
    
    /// Get accessibility-aware spacing
    /// - Parameter baseSpacing: The base spacing value
    /// - Returns: Spacing adjusted for accessibility settings
    public static func accessibleSpacing(_ baseSpacing: CGFloat) -> CGFloat {
        // Increase spacing for larger text sizes
        let textSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        let scaleFactor = textSize / 17.0 // Base body text size
        
        return baseSpacing * max(1.0, scaleFactor * 0.1)
    }
    
    // MARK: - Layout Spacing
    
    /// Get spacing for specific layout type
    /// - Parameter layoutType: The layout type
    /// - Returns: Appropriate spacing for the layout
    public static func forLayoutType(_ layoutType: LayoutType) -> LayoutSpacing {
        switch layoutType {
        case .compact:
            return LayoutSpacing(
                horizontal: 8,
                vertical: 8,
                between: 12
            )
        case .standard:
            return LayoutSpacing(
                horizontal: 16,
                vertical: 16,
                between: 20
            )
        case .comfortable:
            return LayoutSpacing(
                horizontal: 24,
                vertical: 24,
                between: 32
            )
        case .spacious:
            return LayoutSpacing(
                horizontal: 32,
                vertical: 32,
                between: 48
            )
        }
    }
    
    // MARK: - Health-Specific Spacing
    
    /// Get spacing for health metric display
    /// - Parameter metricType: The health metric type
    /// - Returns: Appropriate spacing for the health metric
    public static func forHealthMetric(_ metricType: HealthMetricType) -> CGFloat {
        switch metricType {
        case .heartRate, .bloodPressure:
            return 20 // More spacing for critical metrics
        case .temperature, .oxygen:
            return 16 // Standard spacing for vital signs
        case .sleep, .activity, .nutrition, .mentalHealth:
            return 12 // Compact spacing for lifestyle metrics
        }
    }
    
    /// Get spacing for medical content
    /// - Parameter contentType: The medical content type
    /// - Returns: Appropriate spacing for the medical content
    public static func forMedicalContent(_ contentType: MedicalContentType) -> CGFloat {
        switch contentType {
        case .patientData:
            return 16 // Standard spacing for patient information
        case .labResults:
            return 20 // More spacing for detailed lab data
        case .medications:
            return 12 // Compact spacing for medication lists
        case .procedures:
            return 24 // Generous spacing for procedure information
        }
    }
    
    // MARK: - Utility Functions
    
    /// Get spacing multiplier for accessibility
    /// - Returns: Spacing multiplier based on accessibility settings
    public static func accessibilityMultiplier() -> CGFloat {
        let textSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        return max(1.0, textSize / 17.0)
    }
    
    /// Get minimum touch target spacing
    /// - Returns: Minimum spacing for touch targets
    public static func minimumTouchTargetSpacing() -> CGFloat {
        return 44 // Apple HIG minimum touch target
    }
    
    /// Get optimal reading spacing
    /// - Parameter fontSize: The font size
    /// - Returns: Optimal spacing for reading comfort
    public static func optimalReadingSpacing(for fontSize: CGFloat) -> CGFloat {
        return fontSize * 1.5 // 1.5x line height for optimal reading
    }
}

// MARK: - Supporting Structures

/// Responsive spacing configuration
public struct ResponsiveSpacing {
    public let small: CGFloat
    public let medium: CGFloat
    public let large: CGFloat
    public let extraLarge: CGFloat
    
    public init(small: CGFloat, medium: CGFloat, large: CGFloat, extraLarge: CGFloat) {
        self.small = small
        self.medium = medium
        self.large = large
        self.extraLarge = extraLarge
    }
}

/// Layout spacing configuration
public struct LayoutSpacing {
    public let horizontal: CGFloat
    public let vertical: CGFloat
    public let between: CGFloat
    
    public init(horizontal: CGFloat, vertical: CGFloat, between: CGFloat) {
        self.horizontal = horizontal
        self.vertical = vertical
        self.between = between
    }
}

// MARK: - Supporting Enums

/// Device types for responsive spacing
public enum DeviceType {
    case iPhone
    case iPad
    case mac
    case watch
    case tv
}

/// Layout types for spacing configuration
public enum LayoutType {
    case compact
    case standard
    case comfortable
    case spacious
}

/// Health metric types for spacing configuration
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

/// Medical content types for spacing configuration
public enum MedicalContentType {
    case patientData
    case labResults
    case medications
    case procedures
}

// MARK: - Spacing Extensions

extension View {
    /// Apply consistent spacing to a view
    /// - Parameter spacing: The spacing to apply
    /// - Returns: View with applied spacing
    public func healthSpacing(_ spacing: CGFloat) -> some View {
        self.padding(spacing)
    }
    
    /// Apply responsive spacing to a view
    /// - Parameter deviceType: The device type for responsive spacing
    /// - Returns: View with responsive spacing
    public func responsiveSpacing(_ deviceType: DeviceType) -> some View {
        let spacing = SpacingGrid.responsiveSpacing(for: deviceType)
        return self.padding(.horizontal, spacing.medium)
            .padding(.vertical, spacing.small)
    }
    
    /// Apply layout spacing to a view
    /// - Parameter layoutType: The layout type
    /// - Returns: View with layout-specific spacing
    public func layoutSpacing(_ layoutType: LayoutType) -> some View {
        let spacing = SpacingGrid.forLayoutType(layoutType)
        return self.padding(.horizontal, spacing.horizontal)
            .padding(.vertical, spacing.vertical)
    }
    
    /// Apply accessible spacing to a view
    /// - Parameter baseSpacing: The base spacing value
    /// - Returns: View with accessibility-adjusted spacing
    public func accessibleSpacing(_ baseSpacing: CGFloat) -> some View {
        let spacing = SpacingGrid.accessibleSpacing(baseSpacing)
        return self.padding(spacing)
    }
}

// MARK: - Spacing Modifiers

extension VStack {
    /// Apply consistent spacing to VStack
    /// - Parameter spacing: The spacing between elements
    /// - Returns: VStack with consistent spacing
    public init(spacing: CGFloat = SpacingGrid.medium, @ViewBuilder content: () -> Content) {
        self.init(spacing: spacing, content: content)
    }
}

extension HStack {
    /// Apply consistent spacing to HStack
    /// - Parameter spacing: The spacing between elements
    /// - Returns: HStack with consistent spacing
    public init(spacing: CGFloat = SpacingGrid.medium, @ViewBuilder content: () -> Content) {
        self.init(spacing: spacing, content: content)
    }
}

extension LazyVGrid {
    /// Apply consistent spacing to LazyVGrid
    /// - Parameters:
    ///   - columns: The grid columns
    ///   - spacing: The spacing between items
    ///   - content: The grid content
    /// - Returns: LazyVGrid with consistent spacing
    public init(columns: [GridItem], spacing: CGFloat = SpacingGrid.gridSpacing, @ViewBuilder content: () -> Content) {
        self.init(columns: columns, spacing: spacing, content: content)
    }
} 