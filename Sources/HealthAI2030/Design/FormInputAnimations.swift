import SwiftUI
import UIKit

/// Advanced form input animations for health app
/// Provides smooth transitions, validation feedback, and accessibility features
public class FormInputAnimations {
    
    // MARK: - Properties
    
    /// Animation durations for different input states
    private let animationDurations: FormAnimationDurations
    /// Validation feedback configurations
    private let validationFeedback: ValidationFeedbackConfig
    /// Accessibility configurations
    private let accessibilityConfig: AccessibilityConfig
    
    // MARK: - Initialization
    
    public init() {
        self.animationDurations = FormAnimationDurations()
        self.validationFeedback = ValidationFeedbackConfig()
        self.accessibilityConfig = AccessibilityConfig()
    }
    
    // MARK: - Text Field Animations
    
    /// Apply text field focus animation
    /// - Parameters:
    ///   - textField: Text field to animate
    ///   - completion: Completion handler
    public func applyTextFieldFocusAnimation(to textField: UITextField, completion: @escaping () -> Void = {}) {
        // Trigger haptic feedback
        triggerFocusHaptic()
        
        // Animate border and background
        UIView.animate(withDuration: animationDurations.focusDuration, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            textField.layer.borderWidth = 2.0
            textField.layer.borderColor = validationFeedback.focusColor.cgColor
            textField.backgroundColor = validationFeedback.focusBackgroundColor
            textField.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        } completion: { _ in
            completion()
        }
    }
    
    /// Apply text field blur animation
    /// - Parameters:
    ///   - textField: Text field to animate
    ///   - completion: Completion handler
    public func applyTextFieldBlurAnimation(to textField: UITextField, completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: animationDurations.blurDuration, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            textField.layer.borderWidth = 1.0
            textField.layer.borderColor = validationFeedback.defaultBorderColor.cgColor
            textField.backgroundColor = validationFeedback.defaultBackgroundColor
            textField.transform = .identity
        } completion: { _ in
            completion()
        }
    }
    
    /// Apply text field typing animation
    /// - Parameters:
    ///   - textField: Text field to animate
    ///   - completion: Completion handler
    public func applyTextFieldTypingAnimation(to textField: UITextField, completion: @escaping () -> Void = {}) {
        // Subtle scale animation
        UIView.animate(withDuration: animationDurations.typingDuration, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            textField.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
        } completion: { _ in
            UIView.animate(withDuration: animationDurations.typingDuration) {
                textField.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Validation Animations
    
    /// Apply validation success animation
    /// - Parameters:
    ///   - textField: Text field to animate
    ///   - completion: Completion handler
    public func applyValidationSuccessAnimation(to textField: UITextField, completion: @escaping () -> Void = {}) {
        // Trigger success haptic
        triggerSuccessHaptic()
        
        // Success animation sequence
        UIView.animate(withDuration: animationDurations.validationDuration, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            textField.layer.borderColor = validationFeedback.successColor.cgColor
            textField.backgroundColor = validationFeedback.successBackgroundColor
        } completion: { _ in
            // Add success checkmark
            self.addSuccessCheckmark(to: textField)
            
            UIView.animate(withDuration: animationDurations.validationDuration, 
                          delay: 0.5, 
                          options: [.allowUserInteraction, .curveEaseInOut]) {
                textField.layer.borderColor = validationFeedback.defaultBorderColor.cgColor
                textField.backgroundColor = validationFeedback.defaultBackgroundColor
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Apply validation error animation
    /// - Parameters:
    ///   - textField: Text field to animate
    ///   - errorMessage: Error message to display
    ///   - completion: Completion handler
    public func applyValidationErrorAnimation(to textField: UITextField, errorMessage: String, completion: @escaping () -> Void = {}) {
        // Trigger error haptic
        triggerErrorHaptic()
        
        // Shake animation
        let shakeAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shakeAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        shakeAnimation.duration = 0.6
        shakeAnimation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        
        textField.layer.add(shakeAnimation, forKey: "shake")
        
        // Color change and error message
        UIView.animate(withDuration: animationDurations.validationDuration) {
            textField.layer.borderColor = validationFeedback.errorColor.cgColor
            textField.backgroundColor = validationFeedback.errorBackgroundColor
        } completion: { _ in
            self.showErrorMessage(errorMessage, for: textField)
            
            UIView.animate(withDuration: animationDurations.validationDuration, 
                          delay: 2.0, 
                          options: [.allowUserInteraction, .curveEaseInOut]) {
                textField.layer.borderColor = validationFeedback.defaultBorderColor.cgColor
                textField.backgroundColor = validationFeedback.defaultBackgroundColor
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Add success checkmark to text field
    /// - Parameter textField: Text field to add checkmark to
    private func addSuccessCheckmark(to textField: UITextField) {
        let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmarkImageView.tintColor = validationFeedback.successColor
        checkmarkImageView.frame = CGRect(x: textField.bounds.width - 30, y: (textField.bounds.height - 20) / 2, width: 20, height: 20)
        checkmarkImageView.alpha = 0
        
        textField.addSubview(checkmarkImageView)
        
        UIView.animate(withDuration: 0.3) {
            checkmarkImageView.alpha = 1.0
        }
        
        // Remove after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            UIView.animate(withDuration: 0.3) {
                checkmarkImageView.alpha = 0
            } completion: { _ in
                checkmarkImageView.removeFromSuperview()
            }
        }
    }
    
    /// Show error message for text field
    /// - Parameters:
    ///   - message: Error message to display
    ///   - textField: Text field to show error for
    private func showErrorMessage(_ message: String, for textField: UITextField) {
        let errorLabel = UILabel()
        errorLabel.text = message
        errorLabel.textColor = validationFeedback.errorColor
        errorLabel.font = UIFont.systemFont(ofSize: 12)
        errorLabel.alpha = 0
        
        // Position below text field
        let textFieldFrame = textField.convert(textField.bounds, to: textField.superview)
        errorLabel.frame = CGRect(x: textFieldFrame.minX, 
                                 y: textFieldFrame.maxY + 5, 
                                 width: textFieldFrame.width, 
                                 height: 20)
        
        textField.superview?.addSubview(errorLabel)
        
        UIView.animate(withDuration: 0.3) {
            errorLabel.alpha = 1.0
        }
        
        // Remove after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIView.animate(withDuration: 0.3) {
                errorLabel.alpha = 0
            } completion: { _ in
                errorLabel.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Health-Specific Input Animations
    
    /// Apply vital signs input animation
    /// - Parameters:
    ///   - textField: Text field to animate
    ///   - vitalSign: Type of vital sign
    ///   - completion: Completion handler
    public func applyVitalSignsInputAnimation(to textField: UITextField, vitalSign: VitalSignType, completion: @escaping () -> Void = {}) {
        switch vitalSign {
        case .heartRate:
            applyHeartRateInputAnimation(to: textField, completion: completion)
        case .bloodPressure:
            applyBloodPressureInputAnimation(to: textField, completion: completion)
        case .temperature:
            applyTemperatureInputAnimation(to: textField, completion: completion)
        case .respiratoryRate:
            applyRespiratoryRateInputAnimation(to: textField, completion: completion)
        case .oxygenSaturation:
            applyOxygenSaturationInputAnimation(to: textField, completion: completion)
        }
    }
    
    /// Apply heart rate input animation
    /// - Parameters:
    ///   - textField: Text field to animate
    ///   - completion: Completion handler
    private func applyHeartRateInputAnimation(to textField: UITextField, completion: @escaping () -> Void = {}) {
        // Pulse animation for heart rate
        UIView.animate(withDuration: 0.3, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            textField.backgroundColor = validationFeedback.heartRateColor
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                textField.backgroundColor = validationFeedback.defaultBackgroundColor
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Apply blood pressure input animation
    /// - Parameters:
    ///   - textField: Text field to animate
    ///   - completion: Completion handler
    private func applyBloodPressureInputAnimation(to textField: UITextField, completion: @escaping () -> Void = {}) {
        // Pressure animation for blood pressure
        UIView.animate(withDuration: 0.4, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            textField.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
            textField.backgroundColor = validationFeedback.bloodPressureColor
        } completion: { _ in
            UIView.animate(withDuration: 0.4) {
                textField.transform = .identity
                textField.backgroundColor = validationFeedback.defaultBackgroundColor
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Apply temperature input animation
    /// - Parameters:
    ///   - textField: Text field to animate
    ///   - completion: Completion handler
    private func applyTemperatureInputAnimation(to textField: UITextField, completion: @escaping () -> Void = {}) {
        // Warm glow animation for temperature
        UIView.animate(withDuration: 0.5, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            textField.backgroundColor = validationFeedback.temperatureColor
            textField.layer.shadowColor = validationFeedback.temperatureColor.cgColor
            textField.layer.shadowOffset = CGSize(width: 0, height: 0)
            textField.layer.shadowOpacity = 0.3
            textField.layer.shadowRadius = 5
        } completion: { _ in
            UIView.animate(withDuration: 0.5) {
                textField.backgroundColor = validationFeedback.defaultBackgroundColor
                textField.layer.shadowOpacity = 0
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Apply respiratory rate input animation
    /// - Parameters:
    ///   - textField: Text field to animate
    ///   - completion: Completion handler
    private func applyRespiratoryRateInputAnimation(to textField: UITextField, completion: @escaping () -> Void = {}) {
        // Breathing animation for respiratory rate
        UIView.animate(withDuration: 0.6, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            textField.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
            textField.backgroundColor = validationFeedback.respiratoryColor
        } completion: { _ in
            UIView.animate(withDuration: 0.6) {
                textField.transform = .identity
                textField.backgroundColor = validationFeedback.defaultBackgroundColor
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Apply oxygen saturation input animation
    /// - Parameters:
    ///   - textField: Text field to animate
    ///   - completion: Completion handler
    private func applyOxygenSaturationInputAnimation(to textField: UITextField, completion: @escaping () -> Void = {}) {
        // Oxygen flow animation
        UIView.animate(withDuration: 0.4, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            textField.backgroundColor = validationFeedback.oxygenColor
        } completion: { _ in
            UIView.animate(withDuration: 0.4) {
                textField.backgroundColor = validationFeedback.defaultBackgroundColor
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Date Picker Animations
    
    /// Apply date picker focus animation
    /// - Parameters:
    ///   - datePicker: Date picker to animate
    ///   - completion: Completion handler
    public func applyDatePickerFocusAnimation(to datePicker: UIDatePicker, completion: @escaping () -> Void = {}) {
        triggerFocusHaptic()
        
        UIView.animate(withDuration: animationDurations.focusDuration, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            datePicker.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            datePicker.alpha = 1.0
        } completion: { _ in
            completion()
        }
    }
    
    /// Apply date picker selection animation
    /// - Parameters:
    ///   - datePicker: Date picker to animate
    ///   - completion: Completion handler
    public func applyDatePickerSelectionAnimation(to datePicker: UIDatePicker, completion: @escaping () -> Void = {}) {
        triggerSelectionHaptic()
        
        UIView.animate(withDuration: 0.2, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            datePicker.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                datePicker.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Slider Animations
    
    /// Apply slider value change animation
    /// - Parameters:
    ///   - slider: Slider to animate
    ///   - completion: Completion handler
    public func applySliderValueChangeAnimation(to slider: UISlider, completion: @escaping () -> Void = {}) {
        triggerSelectionHaptic()
        
        UIView.animate(withDuration: 0.1, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            slider.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                slider.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Switch Animations
    
    /// Apply switch toggle animation
    /// - Parameters:
    ///   - switchControl: Switch to animate
    ///   - completion: Completion handler
    public func applySwitchToggleAnimation(to switchControl: UISwitch, completion: @escaping () -> Void = {}) {
        triggerSelectionHaptic()
        
        UIView.animate(withDuration: 0.2, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            switchControl.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                switchControl.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Accessibility Animations
    
    /// Apply accessibility focus animation
    /// - Parameters:
    ///   - view: View to animate
    ///   - completion: Completion handler
    public func applyAccessibilityFocusAnimation(to view: UIView, completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: animationDurations.accessibilityDuration, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            view.layer.borderWidth = 3.0
            view.layer.borderColor = accessibilityConfig.focusColor.cgColor
            view.layer.shadowColor = accessibilityConfig.focusColor.cgColor
            view.layer.shadowOffset = CGSize(width: 0, height: 0)
            view.layer.shadowOpacity = 0.5
            view.layer.shadowRadius = 5
        } completion: { _ in
            completion()
        }
    }
    
    /// Remove accessibility focus animation
    /// - Parameters:
    ///   - view: View to animate
    ///   - completion: Completion handler
    public func removeAccessibilityFocusAnimation(from view: UIView, completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: animationDurations.accessibilityDuration, 
                      delay: 0, 
                      options: [.allowUserInteraction, .curveEaseInOut]) {
            view.layer.borderWidth = 0
            view.layer.shadowOpacity = 0
        } completion: { _ in
            completion()
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerFocusHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func triggerSuccessHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func triggerErrorHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    private func triggerSelectionHaptic() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}

// MARK: - Supporting Types

/// Animation durations for form interactions
public struct FormAnimationDurations {
    public let focusDuration: TimeInterval = 0.3
    public let blurDuration: TimeInterval = 0.2
    public let typingDuration: TimeInterval = 0.1
    public let validationDuration: TimeInterval = 0.4
    public let accessibilityDuration: TimeInterval = 0.2
}

/// Validation feedback configuration
public struct ValidationFeedbackConfig {
    public let focusColor = UIColor.systemBlue
    public let focusBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
    public let defaultBorderColor = UIColor.systemGray4
    public let defaultBackgroundColor = UIColor.systemBackground
    public let successColor = UIColor.systemGreen
    public let successBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
    public let errorColor = UIColor.systemRed
    public let errorBackgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
    public let heartRateColor = UIColor.systemRed.withAlphaComponent(0.2)
    public let bloodPressureColor = UIColor.systemOrange.withAlphaComponent(0.2)
    public let temperatureColor = UIColor.systemYellow.withAlphaComponent(0.2)
    public let respiratoryColor = UIColor.systemBlue.withAlphaComponent(0.2)
    public let oxygenColor = UIColor.systemCyan.withAlphaComponent(0.2)
}

/// Accessibility configuration
public struct AccessibilityConfig {
    public let focusColor = UIColor.systemBlue
    public let highContrastColor = UIColor.systemYellow
}

/// Vital sign types for specialized animations
public enum VitalSignType {
    case heartRate
    case bloodPressure
    case temperature
    case respiratoryRate
    case oxygenSaturation
} 