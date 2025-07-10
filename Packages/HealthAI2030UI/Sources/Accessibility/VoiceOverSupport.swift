import SwiftUI

// MARK: - VoiceOver Support Manager
/// Comprehensive VoiceOver support for HealthAI 2030
/// Provides medical terminology pronunciation, health data announcements, and healthcare-specific accessibility
public class VoiceOverSupportManager: ObservableObject {
    
    @Published public var isVoiceOverEnabled: Bool = false
    @Published public var pronunciationEnabled: Bool = true
    @Published public var medicalAnnouncementsEnabled: Bool = true
    @Published public var criticalAlertsEnabled: Bool = true
    
    public static let shared = VoiceOverSupportManager()
    
    private init() {
        checkVoiceOverStatus()
    }
    
    /// Check if VoiceOver is currently enabled
    public func checkVoiceOverStatus() {
        // In a real implementation, this would check UIAccessibility.isVoiceOverRunning
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
    }
    
    /// Announce medical data with proper pronunciation
    public func announceMedicalData(
        title: String,
        value: String,
        unit: String? = nil,
        isCritical: Bool = false
    ) {
        guard isVoiceOverEnabled else { return }
        
        let announcement = generateMedicalAnnouncement(
            title: title,
            value: value,
            unit: unit,
            isCritical: isCritical
        )
        
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
    
    /// Announce critical medical information
    public func announceCriticalInfo(_ message: String) {
        guard isVoiceOverEnabled && criticalAlertsEnabled else { return }
        
        let criticalAnnouncement = "Critical alert: \(message)"
        UIAccessibility.post(notification: .announcement, argument: criticalAnnouncement)
    }
    
    /// Announce health trend changes
    public func announceHealthTrend(
        metric: String,
        trend: String,
        direction: TrendDirection
    ) {
        guard isVoiceOverEnabled && medicalAnnouncementsEnabled else { return }
        
        let trendAnnouncement = generateTrendAnnouncement(
            metric: metric,
            trend: trend,
            direction: direction
        )
        
        UIAccessibility.post(notification: .announcement, argument: trendAnnouncement)
    }
}

// MARK: - Trend Direction
public enum TrendDirection {
    case improving
    case declining
    case stable
    case critical
    
    var description: String {
        switch self {
        case .improving:
            return "improving"
        case .declining:
            return "declining"
        case .stable:
            return "stable"
        case .critical:
            return "critical"
        }
    }
}

// MARK: - VoiceOver Extensions
public extension VoiceOverSupportManager {
    
    /// Generate medical data announcement
    private func generateMedicalAnnouncement(
        title: String,
        value: String,
        unit: String? = nil,
        isCritical: Bool = false
    ) -> String {
        var announcement = ""
        
        if isCritical {
            announcement += "Critical: "
        }
        
        announcement += formatMedicalTerm(title)
        announcement += ": \(value)"
        
        if let unit = unit {
            announcement += " \(formatMedicalUnit(unit))"
        }
        
        return announcement
    }
    
    /// Generate trend announcement
    private func generateTrendAnnouncement(
        metric: String,
        trend: String,
        direction: TrendDirection
    ) -> String {
        let formattedMetric = formatMedicalTerm(metric)
        return "\(formattedMetric) is \(direction.description): \(trend)"
    }
    
    /// Format medical terminology for VoiceOver
    private func formatMedicalTerm(_ term: String) -> String {
        let medicalTerms: [String: String] = [
            "ECG": "E-C-G",
            "BP": "Blood Pressure",
            "HR": "Heart Rate",
            "SpO2": "S-P-O-2",
            "BMI": "B-M-I",
            "CBC": "C-B-C",
            "CT": "C-T",
            "MRI": "M-R-I",
            "X-ray": "X-ray",
            "EKG": "E-K-G",
            "IV": "I-V",
            "ICU": "I-C-U",
            "ER": "E-R",
            "OR": "O-R",
            "NPO": "N-P-O",
            "PRN": "P-R-N",
            "BID": "B-I-D",
            "TID": "T-I-D",
            "QID": "Q-I-D"
        ]
        
        if let pronunciation = medicalTerms[term.uppercased()] {
            return "\(term) (\(pronunciation))"
        }
        
        return term
    }
    
    /// Format medical units for VoiceOver
    private func formatMedicalUnit(_ unit: String) -> String {
        let medicalUnits: [String: String] = [
            "mmHg": "millimeters of mercury",
            "bpm": "beats per minute",
            "°F": "degrees Fahrenheit",
            "°C": "degrees Celsius",
            "mg/dL": "milligrams per deciliter",
            "mEq/L": "milliequivalents per liter",
            "kg": "kilograms",
            "lbs": "pounds",
            "cm": "centimeters",
            "in": "inches",
            "mL": "milliliters",
            "L": "liters",
            "mg": "milligrams",
            "g": "grams",
            "mcg": "micrograms"
        ]
        
        if let description = medicalUnits[unit] {
            return "\(unit) (\(description))"
        }
        
        return unit
    }
}

// MARK: - VoiceOver View Modifiers
public extension View {
    
    /// Add comprehensive VoiceOver support for medical data
    func medicalVoiceOverSupport(
        title: String,
        value: String,
        unit: String? = nil,
        isCritical: Bool = false,
        hint: String? = nil
    ) -> some View {
        self.accessibilityElement(children: .combine)
            .accessibilityLabel(Text(generateMedicalAccessibilityLabel(
                title: title,
                value: value,
                unit: unit,
                isCritical: isCritical
            )))
            .accessibilityHint(Text(hint ?? generateMedicalAccessibilityHint(
                action: "view details",
                isCritical: isCritical
            )))
            .accessibilityAddTraits(isCritical ? [.isButton, .isHeader] : [.isButton])
    }
    
    /// Add VoiceOver support for health metrics
    func healthMetricVoiceOverSupport(
        metric: String,
        value: String,
        unit: String? = nil,
        trend: String? = nil
    ) -> some View {
        self.accessibilityElement(children: .combine)
            .accessibilityLabel(Text(generateHealthMetricAccessibilityLabel(
                metric: metric,
                value: value,
                unit: unit,
                trend: trend
            )))
            .accessibilityHint(Text("Double tap to view \(metric.lowercased()) details"))
            .accessibilityAddTraits(.isButton)
    }
    
    /// Add VoiceOver support for medical actions
    func medicalActionVoiceOverSupport(
        action: String,
        isCritical: Bool = false,
        confirmation: String? = nil
    ) -> some View {
        self.accessibilityElement(children: .combine)
            .accessibilityLabel(Text(generateMedicalActionAccessibilityLabel(
                action: action,
                isCritical: isCritical
            )))
            .accessibilityHint(Text(generateMedicalActionAccessibilityHint(
                action: action,
                isCritical: isCritical
            )))
            .accessibilityAddTraits(.isButton)
    }
    
    /// Add VoiceOver support for navigation
    func navigationVoiceOverSupport(
        destination: String,
        currentLocation: String? = nil
    ) -> some View {
        self.accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Navigate to \(destination)"))
            .accessibilityHint(Text(generateNavigationAccessibilityHint(
                destination: destination,
                currentLocation: currentLocation
            )))
            .accessibilityAddTraits(.isButton)
    }
    
    /// Add VoiceOver support for form fields
    func formFieldVoiceOverSupport(
        fieldName: String,
        isRequired: Bool = false,
        validationMessage: String? = nil
    ) -> some View {
        self.accessibilityElement(children: .combine)
            .accessibilityLabel(Text(generateFormFieldAccessibilityLabel(
                fieldName: fieldName,
                isRequired: isRequired
            )))
            .accessibilityHint(Text(generateFormFieldAccessibilityHint(
                fieldName: fieldName,
                validationMessage: validationMessage
            )))
    }
}

// MARK: - Accessibility Label Generators
private extension View {
    
    func generateMedicalAccessibilityLabel(
        title: String,
        value: String,
        unit: String? = nil,
        isCritical: Bool = false
    ) -> String {
        var label = ""
        
        if isCritical {
            label += "Critical: "
        }
        
        label += formatMedicalTerm(title)
        label += ": \(value)"
        
        if let unit = unit {
            label += " \(formatMedicalUnit(unit))"
        }
        
        return label
    }
    
    func generateHealthMetricAccessibilityLabel(
        metric: String,
        value: String,
        unit: String? = nil,
        trend: String? = nil
    ) -> String {
        var label = "\(formatMedicalTerm(metric)): \(value)"
        
        if let unit = unit {
            label += " \(formatMedicalUnit(unit))"
        }
        
        if let trend = trend {
            label += ", \(trend)"
        }
        
        return label
    }
    
    func generateMedicalActionAccessibilityLabel(
        action: String,
        isCritical: Bool = false
    ) -> String {
        var label = action
        
        if isCritical {
            label = "Critical action: \(label)"
        }
        
        return label
    }
    
    func generateFormFieldAccessibilityLabel(
        fieldName: String,
        isRequired: Bool = false
    ) -> String {
        var label = fieldName
        
        if isRequired {
            label += ", required"
        }
        
        return label
    }
}

// MARK: - Accessibility Hint Generators
private extension View {
    
    func generateMedicalAccessibilityHint(
        action: String,
        isCritical: Bool = false
    ) -> String {
        var hint = "Double tap to \(action)"
        
        if isCritical {
            hint += ". This is a critical medical action."
        }
        
        return hint
    }
    
    func generateMedicalActionAccessibilityHint(
        action: String,
        isCritical: Bool = false
    ) -> String {
        var hint = "Double tap to \(action.lowercased())"
        
        if isCritical {
            hint += ". This is a critical medical action that requires immediate attention."
        }
        
        return hint
    }
    
    func generateNavigationAccessibilityHint(
        destination: String,
        currentLocation: String? = nil
    ) -> String {
        var hint = "Double tap to navigate to \(destination.lowercased())"
        
        if let currentLocation = currentLocation {
            hint += " from \(currentLocation.lowercased())"
        }
        
        return hint
    }
    
    func generateFormFieldAccessibilityHint(
        fieldName: String,
        validationMessage: String? = nil
    ) -> String {
        var hint = "Enter \(fieldName.lowercased())"
        
        if let validationMessage = validationMessage {
            hint += ". \(validationMessage)"
        }
        
        return hint
    }
}

// MARK: - Medical Terminology Formatters
private extension View {
    
    func formatMedicalTerm(_ term: String) -> String {
        let medicalTerms: [String: String] = [
            "ECG": "E-C-G",
            "BP": "Blood Pressure",
            "HR": "Heart Rate",
            "SpO2": "S-P-O-2",
            "BMI": "B-M-I",
            "CBC": "C-B-C",
            "CT": "C-T",
            "MRI": "M-R-I",
            "X-ray": "X-ray",
            "EKG": "E-K-G",
            "IV": "I-V",
            "ICU": "I-C-U",
            "ER": "E-R",
            "OR": "O-R",
            "NPO": "N-P-O",
            "PRN": "P-R-N",
            "BID": "B-I-D",
            "TID": "T-I-D",
            "QID": "Q-I-D"
        ]
        
        if let pronunciation = medicalTerms[term.uppercased()] {
            return "\(term) (\(pronunciation))"
        }
        
        return term
    }
    
    func formatMedicalUnit(_ unit: String) -> String {
        let medicalUnits: [String: String] = [
            "mmHg": "millimeters of mercury",
            "bpm": "beats per minute",
            "°F": "degrees Fahrenheit",
            "°C": "degrees Celsius",
            "mg/dL": "milligrams per deciliter",
            "mEq/L": "milliequivalents per liter",
            "kg": "kilograms",
            "lbs": "pounds",
            "cm": "centimeters",
            "in": "inches",
            "mL": "milliliters",
            "L": "liters",
            "mg": "milligrams",
            "g": "grams",
            "mcg": "micrograms"
        ]
        
        if let description = medicalUnits[unit] {
            return "\(unit) (\(description))"
        }
        
        return unit
    }
}

// MARK: - VoiceOver Testing Utilities
public extension VoiceOverSupportManager {
    
    /// Test VoiceOver announcement
    func testAnnouncement(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    /// Test medical data announcement
    func testMedicalDataAnnouncement(
        title: String,
        value: String,
        unit: String? = nil
    ) {
        announceMedicalData(title: title, value: value, unit: unit)
    }
    
    /// Test critical alert announcement
    func testCriticalAlert(_ message: String) {
        announceCriticalInfo(message)
    }
    
    /// Test health trend announcement
    func testHealthTrendAnnouncement(
        metric: String,
        trend: String,
        direction: TrendDirection
    ) {
        announceHealthTrend(metric: metric, trend: trend, direction: direction)
    }
}

// MARK: - VoiceOver Configuration
public extension VoiceOverSupportManager {
    
    /// Configure VoiceOver settings
    func configureVoiceOverSettings(
        pronunciationEnabled: Bool = true,
        medicalAnnouncementsEnabled: Bool = true,
        criticalAlertsEnabled: Bool = true
    ) {
        self.pronunciationEnabled = pronunciationEnabled
        self.medicalAnnouncementsEnabled = medicalAnnouncementsEnabled
        self.criticalAlertsEnabled = criticalAlertsEnabled
    }
    
    /// Reset VoiceOver settings to defaults
    func resetVoiceOverSettings() {
        configureVoiceOverSettings()
    }
} 