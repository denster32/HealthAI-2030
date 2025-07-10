import SwiftUI

// MARK: - Accessibility Guidelines
/// Comprehensive accessibility guidelines for HealthAI 2030
/// Ensures WCAG 2.1 AA compliance and healthcare-specific accessibility requirements
public struct AccessibilityGuidelines {
    
    // MARK: - WCAG Compliance Levels
    public enum WCAGLevel {
        case A
        case AA
        case AAA
        
        var description: String {
            switch self {
            case .A:
                return "Basic accessibility requirements"
            case .AA:
                return "Enhanced accessibility for most users"
            case .AAA:
                return "Maximum accessibility for all users"
            }
        }
    }
    
    // MARK: - Color Contrast Requirements
    public struct ColorContrast {
        /// Minimum contrast ratio for normal text (WCAG AA)
        public static let normalText: CGFloat = 4.5
        
        /// Minimum contrast ratio for large text (WCAG AA)
        public static let largeText: CGFloat = 3.0
        
        /// Minimum contrast ratio for UI components (WCAG AA)
        public static let uiComponents: CGFloat = 3.0
        
        /// Enhanced contrast ratio for healthcare applications
        public static let healthcareText: CGFloat = 7.0
        
        /// Critical information contrast ratio
        public static let criticalInfo: CGFloat = 8.0
    }
    
    // MARK: - Touch Target Sizes
    public struct TouchTargets {
        /// Minimum touch target size for iOS (44pt)
        public static let minimumSize: CGFloat = 44
        
        /// Recommended touch target size for healthcare apps
        public static let recommendedSize: CGFloat = 48
        
        /// Touch target size for critical medical actions
        public static let criticalSize: CGFloat = 56
        
        /// Touch target spacing between elements
        public static let minimumSpacing: CGFloat = 8
    }
    
    // MARK: - Typography Accessibility
    public struct TypographyAccessibility {
        /// Minimum font size for body text
        public static let minimumBodySize: CGFloat = 16
        
        /// Minimum font size for captions
        public static let minimumCaptionSize: CGFloat = 12
        
        /// Recommended line height ratio
        public static let lineHeightRatio: CGFloat = 1.5
        
        /// Letter spacing for improved readability
        public static let letterSpacing: CGFloat = 0.5
        
        /// Word spacing for medical terms
        public static let wordSpacing: CGFloat = 1.0
    }
    
    // MARK: - Focus Management
    public struct FocusManagement {
        /// Focus indicator color
        public static let focusColor = ColorPalette.primary
        
        /// Focus indicator thickness
        public static let focusThickness: CGFloat = 2
        
        /// Focus indicator corner radius
        public static let focusCornerRadius: CGFloat = 4
        
        /// Focus animation duration
        public static let focusAnimationDuration: Double = 0.2
    }
    
    // MARK: - VoiceOver Guidelines
    public struct VoiceOverGuidelines {
        /// Maximum label length for VoiceOver
        public static let maxLabelLength = 100
        
        /// Recommended hint length
        public static let maxHintLength = 150
        
        /// Trait combinations for complex elements
        public static let recommendedTraits: [AccessibilityTraits] = [
            .isButton,
            .isHeader,
            .isLink,
            .isImage,
            .isStaticText
        ]
    }
    
    // MARK: - Healthcare-Specific Accessibility
    public struct HealthcareAccessibility {
        /// Medical terminology pronunciation guides
        public static let medicalPronunciationGuides = [
            "ECG": "E-C-G",
            "BP": "Blood Pressure",
            "HR": "Heart Rate",
            "SpO2": "S-P-O-2",
            "BMI": "B-M-I",
            "CBC": "C-B-C",
            "CT": "C-T",
            "MRI": "M-R-I",
            "X-ray": "X-ray"
        ]
        
        /// Critical medical information indicators
        public static let criticalInfoIndicators = [
            "ALERT",
            "EMERGENCY",
            "CRITICAL",
            "URGENT",
            "WARNING"
        ]
        
        /// Medical measurement units
        public static let medicalUnits = [
            "mmHg": "millimeters of mercury",
            "bpm": "beats per minute",
            "°F": "degrees Fahrenheit",
            "°C": "degrees Celsius",
            "mg/dL": "milligrams per deciliter",
            "mEq/L": "milliequivalents per liter"
        ]
    }
    
    // MARK: - Animation and Motion
    public struct MotionAccessibility {
        /// Respect reduced motion preference
        public static let respectReducedMotion = true
        
        /// Maximum animation duration
        public static let maxAnimationDuration: Double = 0.5
        
        /// Flashing content threshold (3 times per second)
        public static let flashingThreshold: Double = 3.0
        
        /// Auto-playing content timeout
        public static let autoPlayTimeout: Double = 5.0
    }
    
    // MARK: - Error Handling
    public struct ErrorAccessibility {
        /// Error message format
        public static let errorFormat = "Error: {description}. {solution}"
        
        /// Warning message format
        public static let warningFormat = "Warning: {description}. {action}"
        
        /// Success message format
        public static let successFormat = "Success: {description}"
        
        /// Critical error format
        public static let criticalFormat = "Critical: {description}. Immediate action required."
    }
}

// MARK: - Accessibility Helper Functions
public extension AccessibilityGuidelines {
    
    /// Check if color contrast meets WCAG AA requirements
    static func meetsContrastRequirements(
        foreground: Color,
        background: Color,
        level: WCAGLevel = .AA
    ) -> Bool {
        let contrast = calculateContrastRatio(foreground: foreground, background: background)
        
        switch level {
        case .A:
            return contrast >= 3.0
        case .AA:
            return contrast >= 4.5
        case .AAA:
            return contrast >= 7.0
        }
    }
    
    /// Calculate contrast ratio between two colors
    static func calculateContrastRatio(foreground: Color, background: Color) -> CGFloat {
        // Simplified contrast calculation
        // In a real implementation, this would use proper luminance calculations
        let foregroundLuminance = getLuminance(color: foreground)
        let backgroundLuminance = getLuminance(color: background)
        
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Get luminance value for a color
    static func getLuminance(color: Color) -> CGFloat {
        // Simplified luminance calculation
        // In a real implementation, this would use proper color space conversions
        return 0.5 // Placeholder value
    }
    
    /// Format medical terminology for accessibility
    static func formatMedicalTerm(_ term: String) -> String {
        if let pronunciation = HealthcareAccessibility.medicalPronunciationGuides[term] {
            return "\(term) (\(pronunciation))"
        }
        return term
    }
    
    /// Format medical units for accessibility
    static func formatMedicalUnit(_ unit: String) -> String {
        if let description = HealthcareAccessibility.medicalUnits[unit] {
            return "\(unit) (\(description))"
        }
        return unit
    }
    
    /// Check if content contains critical medical information
    static func containsCriticalInfo(_ text: String) -> Bool {
        let upperText = text.uppercased()
        return HealthcareAccessibility.criticalInfoIndicators.contains { indicator in
            upperText.contains(indicator)
        }
    }
    
    /// Generate appropriate accessibility label for medical data
    static func generateMedicalAccessibilityLabel(
        title: String,
        value: String,
        unit: String? = nil,
        isCritical: Bool = false
    ) -> String {
        var label = title
        
        if isCritical {
            label = "Critical: \(label)"
        }
        
        label += ": \(value)"
        
        if let unit = unit {
            label += " \(formatMedicalUnit(unit))"
        }
        
        return label
    }
    
    /// Generate appropriate accessibility hint for medical actions
    static func generateMedicalAccessibilityHint(
        action: String,
        isCritical: Bool = false
    ) -> String {
        var hint = "Double tap to \(action)"
        
        if isCritical {
            hint += ". This is a critical medical action."
        }
        
        return hint
    }
}

// MARK: - Accessibility Compliance Checker
public struct AccessibilityComplianceChecker {
    
    /// Check if a view meets accessibility requirements
    public static func checkViewCompliance(_ view: some View) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        // This would implement actual compliance checking logic
        // For now, return empty array as placeholder
        
        return issues
    }
    
    /// Accessibility issue structure
    public struct AccessibilityIssue {
        let severity: IssueSeverity
        let description: String
        let recommendation: String
        let wcagCriteria: String
        
        public init(
            severity: IssueSeverity,
            description: String,
            recommendation: String,
            wcagCriteria: String
        ) {
            self.severity = severity
            self.description = description
            self.recommendation = recommendation
            self.wcagCriteria = wcagCriteria
        }
    }
    
    /// Issue severity levels
    public enum IssueSeverity {
        case critical
        case high
        case medium
        case low
        
        var description: String {
            switch self {
            case .critical:
                return "Critical - Must be fixed"
            case .high:
                return "High - Should be fixed"
            case .medium:
                return "Medium - Consider fixing"
            case .low:
                return "Low - Optional improvement"
            }
        }
    }
}

// MARK: - Accessibility Testing Utilities
public extension AccessibilityGuidelines {
    
    /// Test color contrast compliance
    static func testColorContrast(
        foreground: Color,
        background: Color,
        level: WCAGLevel = .AA
    ) -> (compliant: Bool, ratio: CGFloat) {
        let ratio = calculateContrastRatio(foreground: foreground, background: background)
        let compliant = meetsContrastRequirements(foreground: foreground, background: background, level: level)
        return (compliant, ratio)
    }
    
    /// Test touch target size compliance
    static func testTouchTargetSize(width: CGFloat, height: CGFloat) -> (compliant: Bool, recommended: CGFloat) {
        let minDimension = min(width, height)
        let compliant = minDimension >= TouchTargets.minimumSize
        return (compliant, TouchTargets.recommendedSize)
    }
    
    /// Test typography accessibility
    static func testTypographyAccessibility(fontSize: CGFloat) -> (compliant: Bool, recommended: CGFloat) {
        let compliant = fontSize >= TypographyAccessibility.minimumBodySize
        return (compliant, TypographyAccessibility.minimumBodySize)
    }
}

// MARK: - Accessibility Documentation
public extension AccessibilityGuidelines {
    
    /// Generate accessibility documentation
    static func generateDocumentation() -> String {
        return """
        # HealthAI 2030 Accessibility Guidelines
        
        ## WCAG Compliance
        - Target Level: AA
        - Color Contrast: 4.5:1 for normal text, 3:1 for large text
        - Touch Targets: Minimum 44pt, recommended 48pt
        
        ## Healthcare-Specific Requirements
        - Medical terminology pronunciation guides
        - Critical information indicators
        - Enhanced contrast for medical data
        - Emergency action accessibility
        
        ## Implementation Checklist
        - [ ] Color contrast meets WCAG AA
        - [ ] Touch targets are appropriately sized
        - [ ] VoiceOver labels are descriptive
        - [ ] Focus indicators are visible
        - [ ] Medical terms are properly formatted
        - [ ] Critical information is highlighted
        - [ ] Error messages are accessible
        - [ ] Animations respect reduced motion
        
        ## Testing Requirements
        - VoiceOver testing on all components
        - Color contrast validation
        - Touch target size verification
        - Focus management testing
        - Medical terminology pronunciation testing
        """
    }
} 