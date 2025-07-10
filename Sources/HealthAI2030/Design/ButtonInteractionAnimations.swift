import SwiftUI
import UIKit

/// Advanced button interaction animations for health app
/// Provides rich tactile feedback and visual responses for all button interactions
public class ButtonInteractionAnimations {
    
    // MARK: - Properties
    
    /// Animation duration for different interaction types
    private let animationDurations: ButtonAnimationDurations
    /// Haptic feedback patterns
    private let hapticPatterns: HapticFeedbackPatterns
    /// Visual feedback configurations
    private let visualFeedback: VisualFeedbackConfig
    
    // MARK: - Initialization
    
    public init() {
        self.animationDurations = ButtonAnimationDurations()
        self.hapticPatterns = HapticFeedbackPatterns()
        self.visualFeedback = VisualFeedbackConfig()
    }
    
    // MARK: - Primary Button Animations
    
    /// Apply primary button press animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    public func applyPrimaryButtonPressAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        // Trigger haptic feedback
        hapticPatterns.triggerPrimaryButtonHaptic()
        
        // Scale down animation
        UIView.animate(withDuration: animationDurations.pressDuration, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            button.alpha = 0.8
        } completion: { _ in
            // Scale back up
            UIView.animate(withDuration: animationDurations.releaseDuration, 
                          delay: 0, 
                          options: [.allowUserInteraction, .curveEaseInOut]) {
                button.transform = .identity
                button.alpha = 1.0
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Apply primary button release animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    public func applyPrimaryButtonReleaseAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: animationDurations.releaseDuration, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            button.transform = .identity
            button.alpha = 1.0
        } completion: { _ in
            completion()
        }
    }
    
    // MARK: - Secondary Button Animations
    
    /// Apply secondary button press animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    public func applySecondaryButtonPressAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        // Trigger haptic feedback
        hapticPatterns.triggerSecondaryButtonHaptic()
        
        // Subtle scale and color change
        UIView.animate(withDuration: animationDurations.pressDuration, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            button.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
            button.backgroundColor = visualFeedback.secondaryButtonPressedColor
        } completion: { _ in
            UIView.animate(withDuration: animationDurations.releaseDuration, 
                          delay: 0, 
                          options: [.allowUserInteraction, .curveEaseInOut]) {
                button.transform = .identity
                button.backgroundColor = visualFeedback.secondaryButtonDefaultColor
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Success Button Animations
    
    /// Apply success button animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    public func applySuccessButtonAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        // Trigger success haptic
        hapticPatterns.triggerSuccessHaptic()
        
        // Success animation sequence
        UIView.animate(withDuration: animationDurations.pressDuration, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            button.backgroundColor = visualFeedback.successColor
        } completion: { _ in
            // Add checkmark icon
            self.addSuccessCheckmark(to: button)
            
            UIView.animate(withDuration: animationDurations.releaseDuration, 
                          delay: 0.1, 
                          options: [.allowUserInteraction, .curveEaseInOut]) {
                button.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Add success checkmark to button
    /// - Parameter button: Button to add checkmark to
    private func addSuccessCheckmark(to button: UIView) {
        let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmarkImageView.tintColor = .white
        checkmarkImageView.frame = CGRect(x: button.bounds.width - 30, y: 10, width: 20, height: 20)
        checkmarkImageView.alpha = 0
        
        button.addSubview(checkmarkImageView)
        
        UIView.animate(withDuration: 0.3) {
            checkmarkImageView.alpha = 1.0
        }
    }
    
    // MARK: - Error Button Animations
    
    /// Apply error button animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    public func applyErrorButtonAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        // Trigger error haptic
        hapticPatterns.triggerErrorHaptic()
        
        // Shake animation
        let shakeAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shakeAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        shakeAnimation.duration = 0.6
        shakeAnimation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        
        button.layer.add(shakeAnimation, forKey: "shake")
        
        // Color change
        UIView.animate(withDuration: 0.3) {
            button.backgroundColor = visualFeedback.errorColor
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                button.backgroundColor = visualFeedback.primaryButtonDefaultColor
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Loading Button Animations
    
    /// Apply loading button animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    public func applyLoadingButtonAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        // Store original title
        let originalTitle = (button as? UIButton)?.title(for: .normal)
        
        // Add loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .white
        activityIndicator.center = CGPoint(x: button.bounds.width / 2, y: button.bounds.height / 2)
        activityIndicator.startAnimating()
        
        button.addSubview(activityIndicator)
        
        // Disable button
        button.isUserInteractionEnabled = false
        
        // Animate button
        UIView.animate(withDuration: 0.3) {
            button.alpha = 0.7
            (button as? UIButton)?.setTitle("", for: .normal)
        } completion: { _ in
            completion()
        }
    }
    
    /// Remove loading animation from button
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - originalTitle: Original button title
    ///   - completion: Completion handler
    public func removeLoadingAnimation(from button: UIView, originalTitle: String?, completion: @escaping () -> Void = {}) {
        // Remove activity indicator
        button.subviews.forEach { subview in
            if subview is UIActivityIndicatorView {
                subview.removeFromSuperview()
            }
        }
        
        // Re-enable button
        button.isUserInteractionEnabled = true
        
        // Restore original state
        UIView.animate(withDuration: 0.3) {
            button.alpha = 1.0
            (button as? UIButton)?.setTitle(originalTitle, for: .normal)
        } completion: { _ in
            completion()
        }
    }
    
    // MARK: - Pulse Animation
    
    /// Apply pulse animation to button
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    public func applyPulseAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: 0.1, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.1, 
                          delay: 0, 
                          options: [.allowUserInteraction, .curveEaseInOut]) {
                button.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Ripple Effect
    
    /// Apply ripple effect to button
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - touchPoint: Point where user touched
    ///   - completion: Completion handler
    public func applyRippleEffect(to button: UIView, at touchPoint: CGPoint, completion: @escaping () -> Void = {}) {
        let rippleView = UIView()
        rippleView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        rippleView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        rippleView.center = touchPoint
        rippleView.layer.cornerRadius = 10
        
        button.addSubview(rippleView)
        
        UIView.animate(withDuration: 0.6, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            rippleView.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
            rippleView.alpha = 0
        } completion: { _ in
            rippleView.removeFromSuperview()
            completion()
        }
    }
    
    // MARK: - Accessibility Animations
    
    /// Apply accessibility-focused animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    public func applyAccessibilityAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        // High contrast animation for accessibility
        UIView.animate(withDuration: 0.2, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            button.layer.borderWidth = 3.0
            button.layer.borderColor = UIColor.systemBlue.cgColor
        } completion: { _ in
            UIView.animate(withDuration: 0.2, 
                          delay: 0.1, 
                          options: [.allowUserInteraction, .curveEaseInOut]) {
                button.layer.borderWidth = 0
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Health-Specific Animations
    
    /// Apply health action button animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - healthAction: Type of health action
    ///   - completion: Completion handler
    public func applyHealthActionAnimation(to button: UIView, healthAction: HealthActionType, completion: @escaping () -> Void = {}) {
        switch healthAction {
        case .medication:
            applyMedicationButtonAnimation(to: button, completion: completion)
        case .exercise:
            applyExerciseButtonAnimation(to: button, completion: completion)
        case .nutrition:
            applyNutritionButtonAnimation(to: button, completion: completion)
        case .sleep:
            applySleepButtonAnimation(to: button, completion: completion)
        case .vitalSigns:
            applyVitalSignsButtonAnimation(to: button, completion: completion)
        }
    }
    
    /// Apply medication button animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    private func applyMedicationButtonAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        hapticPatterns.triggerMedicationHaptic()
        
        UIView.animate(withDuration: 0.3, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            button.backgroundColor = visualFeedback.medicationColor
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                button.transform = .identity
                button.backgroundColor = visualFeedback.primaryButtonDefaultColor
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Apply exercise button animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    private func applyExerciseButtonAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        hapticPatterns.triggerExerciseHaptic()
        
        // Bounce animation for exercise
        UIView.animate(withDuration: 0.2, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                button.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Apply nutrition button animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    private func applyNutritionButtonAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        hapticPatterns.triggerNutritionHaptic()
        
        UIView.animate(withDuration: 0.3, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            button.backgroundColor = visualFeedback.nutritionColor
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                button.backgroundColor = visualFeedback.primaryButtonDefaultColor
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Apply sleep button animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    private func applySleepButtonAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        hapticPatterns.triggerSleepHaptic()
        
        // Gentle fade animation for sleep
        UIView.animate(withDuration: 0.5, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            button.alpha = 0.7
            button.backgroundColor = visualFeedback.sleepColor
        } completion: { _ in
            UIView.animate(withDuration: 0.5) {
                button.alpha = 1.0
                button.backgroundColor = visualFeedback.primaryButtonDefaultColor
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Apply vital signs button animation
    /// - Parameters:
    ///   - button: Button view to animate
    ///   - completion: Completion handler
    private func applyVitalSignsButtonAnimation(to button: UIView, completion: @escaping () -> Void = {}) {
        hapticPatterns.triggerVitalSignsHaptic()
        
        // Pulse animation for vital signs
        UIView.animate(withDuration: 0.3, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            button.backgroundColor = visualFeedback.vitalSignsColor
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                button.transform = .identity
                button.backgroundColor = visualFeedback.primaryButtonDefaultColor
            } completion: { _ in
                completion()
            }
        }
    }
}

// MARK: - Supporting Types

/// Animation durations for different button interactions
public struct ButtonAnimationDurations {
    public let pressDuration: TimeInterval = 0.1
    public let releaseDuration: TimeInterval = 0.2
    public let successDuration: TimeInterval = 0.5
    public let errorDuration: TimeInterval = 0.6
    public let loadingDuration: TimeInterval = 0.3
    public let pulseDuration: TimeInterval = 0.2
    public let rippleDuration: TimeInterval = 0.6
    public let accessibilityDuration: TimeInterval = 0.2
}

/// Haptic feedback patterns for different button types
public class HapticFeedbackPatterns {
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    public init() {
        impactFeedback.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()
    }
    
    public func triggerPrimaryButtonHaptic() {
        impactFeedback.impactOccurred()
    }
    
    public func triggerSecondaryButtonHaptic() {
        selectionFeedback.selectionChanged()
    }
    
    public func triggerSuccessHaptic() {
        notificationFeedback.notificationOccurred(.success)
    }
    
    public func triggerErrorHaptic() {
        notificationFeedback.notificationOccurred(.error)
    }
    
    public func triggerMedicationHaptic() {
        impactFeedback.impactOccurred(intensity: 0.8)
    }
    
    public func triggerExerciseHaptic() {
        impactFeedback.impactOccurred(intensity: 1.0)
    }
    
    public func triggerNutritionHaptic() {
        impactFeedback.impactOccurred(intensity: 0.6)
    }
    
    public func triggerSleepHaptic() {
        impactFeedback.impactOccurred(intensity: 0.3)
    }
    
    public func triggerVitalSignsHaptic() {
        impactFeedback.impactOccurred(intensity: 0.7)
    }
}

/// Visual feedback configuration
public struct VisualFeedbackConfig {
    public let primaryButtonDefaultColor = UIColor.systemBlue
    public let primaryButtonPressedColor = UIColor.systemBlue.withAlphaComponent(0.8)
    public let secondaryButtonDefaultColor = UIColor.systemGray5
    public let secondaryButtonPressedColor = UIColor.systemGray4
    public let successColor = UIColor.systemGreen
    public let errorColor = UIColor.systemRed
    public let medicationColor = UIColor.systemPurple
    public let nutritionColor = UIColor.systemOrange
    public let sleepColor = UIColor.systemIndigo
    public let vitalSignsColor = UIColor.systemTeal
}

/// Health action types for specialized animations
public enum HealthActionType {
    case medication
    case exercise
    case nutrition
    case sleep
    case vitalSigns
} 