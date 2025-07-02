import UIKit
import SwiftUI

/// Haptic feedback manager for providing tactile responses
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Light impact feedback
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Light impact feedback
    func light() {
        impact(.light)
    }
    
    /// Medium impact feedback
    func medium() {
        impact(.medium)
    }
    
    /// Heavy impact feedback
    func heavy() {
        impact(.heavy)
    }
    
    /// Soft impact feedback
    func soft() {
        impact(.soft)
    }
    
    /// Rigid impact feedback
    func rigid() {
        impact(.rigid)
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification feedback
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification feedback
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification feedback
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection feedback
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Custom Patterns
    
    /// Health alert pattern
    func healthAlert() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        
        // Pattern: medium-medium-light
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let lightGenerator = UIImpactFeedbackGenerator(style: .light)
            lightGenerator.impactOccurred()
        }
    }
    
    /// Success pattern
    func successPattern() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        
        // Pattern: light-light-medium
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
            mediumGenerator.impactOccurred()
        }
    }
    
    /// Warning pattern
    func warningPattern() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        
        // Pattern: medium-pause-medium
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            generator.impactOccurred()
        }
    }
    
    /// Emergency pattern
    func emergencyPattern() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        
        // Pattern: heavy-heavy-heavy (urgent)
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            generator.impactOccurred()
        }
    }
    
    // MARK: - Health-Specific Feedback
    
    /// Heart rate alert
    func heartRateAlert() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        
        // Simulate heartbeat pattern
        generator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            generator.impactOccurred()
        }
    }
    
    /// Breathing exercise feedback
    func breathingInhale() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func breathingExhale() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Sleep optimization feedback
    func sleepOptimizationStart() {
        successPattern()
    }
    
    func sleepOptimizationStop() {
        warningPattern()
    }
    
    /// Mental health feedback
    func moodLogged() {
        success()
    }
    
    func stressAlert() {
        warningPattern()
    }
    
    // MARK: - Widget Feedback
    
    /// Widget interaction feedback
    func widgetTap() {
        light()
    }
    
    func widgetLongPress() {
        medium()
    }
    
    // MARK: - System Intelligence Feedback
    
    /// Siri suggestion feedback
    func siriSuggestion() {
        selection()
    }
    
    /// Automation trigger feedback
    func automationTriggered() {
        medium()
    }
    
    /// Predictive insight feedback
    func insightGenerated() {
        light()
    }
    
    // MARK: - Accessibility Support
    
    /// Check if haptics are enabled
    var isHapticsEnabled: Bool {
        return UIDevice.current.hasHapticFeedback
    }
    
    /// Safe haptic feedback (checks if enabled)
    func safeImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isHapticsEnabled else { return }
        impact(style)
    }
    
    func safeSuccess() {
        guard isHapticsEnabled else { return }
        success()
    }
    
    func safeWarning() {
        guard isHapticsEnabled else { return }
        warning()
    }
    
    func safeError() {
        guard isHapticsEnabled else { return }
        error()
    }
}

// MARK: - Extensions

extension UIDevice {
    var hasHapticFeedback: Bool {
        return UIDevice.current.hasHapticFeedback
    }
}

// MARK: - SwiftUI Integration

struct HapticButton: View {
    let title: String
    let action: () -> Void
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    
    init(_ title: String, hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light, action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.hapticStyle = hapticStyle
    }
    
    var body: some View {
        Button(title) {
            HapticManager.shared.impact(hapticStyle)
            action()
        }
    }
}

struct HapticToggle: View {
    @Binding var isOn: Bool
    let title: String
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .onChange(of: isOn) { _ in
                HapticManager.shared.selection()
            }
    }
} 