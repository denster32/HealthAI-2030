import SwiftUI
import UIKit

/// Advanced feedback animations for health app
/// Provides smooth, engaging responses for user actions and system feedback
public class FeedbackAnimations {
    
    // MARK: - Properties
    
    /// Animation durations for different feedback types
    private let animationDurations: FeedbackAnimationDurations
    /// Feedback configurations
    private let feedbackConfig: FeedbackConfig
    /// Health-specific feedback configurations
    private let healthFeedbackConfig: HealthFeedbackConfig
    
    // MARK: - Initialization
    
    public init() {
        self.animationDurations = FeedbackAnimationDurations()
        self.feedbackConfig = FeedbackConfig()
        self.healthFeedbackConfig = HealthFeedbackConfig()
    }
    
    // MARK: - Success Feedback Animations
    
    /// Apply success feedback animation
    /// - Parameters:
    ///   - view: View to animate
    ///   - message: Success message
    ///   - completion: Completion handler
    public func applySuccessFeedbackAnimation(to view: UIView, message: String, completion: @escaping () -> Void = {}) {
        // Trigger success haptic
        triggerSuccessHaptic()
        
        // Create success overlay
        let successOverlay = createSuccessOverlay(message: message)
        view.addSubview(successOverlay)
        
        // Initial state
        successOverlay.alpha = 0
        successOverlay.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        // Animate in
        UIView.animate(withDuration: animationDurations.successInDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            successOverlay.alpha = 1.0
            successOverlay.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            // Bounce back
            UIView.animate(withDuration: 0.1) {
                successOverlay.transform = .identity
            } completion: { _ in
                // Add checkmark animation
                self.addCheckmarkAnimation(to: successOverlay)
                
                // Hold for display duration
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDurations.successDisplayDuration) {
                    // Animate out
                    UIView.animate(withDuration: animationDurations.successOutDuration) {
                        successOverlay.alpha = 0
                        successOverlay.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    } completion: { _ in
                        successOverlay.removeFromSuperview()
                        completion()
                    }
                }
            }
        }
    }
    
    /// Create success overlay
    /// - Parameter message: Success message
    /// - Returns: Success overlay view
    private func createSuccessOverlay(message: String) -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = feedbackConfig.successBackgroundColor
        overlay.layer.cornerRadius = 12
        overlay.layer.shadowColor = feedbackConfig.successColor.cgColor
        overlay.layer.shadowOffset = CGSize(width: 0, height: 4)
        overlay.layer.shadowOpacity = 0.3
        overlay.layer.shadowRadius = 8
        
        // Add success icon
        let iconView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iconView.tintColor = feedbackConfig.successColor
        iconView.frame = CGRect(x: 20, y: 15, width: 30, height: 30)
        overlay.addSubview(iconView)
        
        // Add message label
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = feedbackConfig.successTextColor
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.numberOfLines = 0
        messageLabel.frame = CGRect(x: 60, y: 15, width: 200, height: 30)
        overlay.addSubview(messageLabel)
        
        // Size overlay based on content
        let contentWidth = max(280, messageLabel.intrinsicContentSize.width + 80)
        overlay.frame = CGRect(x: (UIScreen.main.bounds.width - contentWidth) / 2,
                              y: 100,
                              width: contentWidth,
                              height: 60)
        
        return overlay
    }
    
    /// Add checkmark animation to overlay
    /// - Parameter overlay: Overlay to add animation to
    private func addCheckmarkAnimation(to overlay: UIView) {
        guard let iconView = overlay.subviews.first(where: { $0 is UIImageView }) as? UIImageView else { return }
        
        // Scale animation
        UIView.animate(withDuration: 0.2, 
                      delay: 0, 
                      options: [.curveEaseInOut]) {
            iconView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                iconView.transform = .identity
            }
        }
    }
    
    // MARK: - Error Feedback Animations
    
    /// Apply error feedback animation
    /// - Parameters:
    ///   - view: View to animate
    ///   - message: Error message
    ///   - completion: Completion handler
    public func applyErrorFeedbackAnimation(to view: UIView, message: String, completion: @escaping () -> Void = {}) {
        // Trigger error haptic
        triggerErrorHaptic()
        
        // Create error overlay
        let errorOverlay = createErrorOverlay(message: message)
        view.addSubview(errorOverlay)
        
        // Initial state
        errorOverlay.alpha = 0
        errorOverlay.transform = CGAffineTransform(translationX: 0, y: -50)
        
        // Animate in
        UIView.animate(withDuration: animationDurations.errorInDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            errorOverlay.alpha = 1.0
            errorOverlay.transform = .identity
        } completion: { _ in
            // Add shake animation
            self.addShakeAnimation(to: errorOverlay)
            
            // Hold for display duration
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDurations.errorDisplayDuration) {
                // Animate out
                UIView.animate(withDuration: animationDurations.errorOutDuration) {
                    errorOverlay.alpha = 0
                    errorOverlay.transform = CGAffineTransform(translationX: 0, y: -50)
                } completion: { _ in
                    errorOverlay.removeFromSuperview()
                    completion()
                }
            }
        }
    }
    
    /// Create error overlay
    /// - Parameter message: Error message
    /// - Returns: Error overlay view
    private func createErrorOverlay(message: String) -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = feedbackConfig.errorBackgroundColor
        overlay.layer.cornerRadius = 12
        overlay.layer.borderWidth = 1
        overlay.layer.borderColor = feedbackConfig.errorColor.cgColor
        
        // Add error icon
        let iconView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        iconView.tintColor = feedbackConfig.errorColor
        iconView.frame = CGRect(x: 20, y: 15, width: 30, height: 30)
        overlay.addSubview(iconView)
        
        // Add message label
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = feedbackConfig.errorTextColor
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.numberOfLines = 0
        messageLabel.frame = CGRect(x: 60, y: 15, width: 200, height: 30)
        overlay.addSubview(messageLabel)
        
        // Size overlay based on content
        let contentWidth = max(280, messageLabel.intrinsicContentSize.width + 80)
        overlay.frame = CGRect(x: (UIScreen.main.bounds.width - contentWidth) / 2,
                              y: 100,
                              width: contentWidth,
                              height: 60)
        
        return overlay
    }
    
    /// Add shake animation to view
    /// - Parameter view: View to shake
    private func addShakeAnimation(to view: UIView) {
        let shakeAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shakeAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        shakeAnimation.duration = 0.6
        shakeAnimation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, 0.0]
        
        view.layer.add(shakeAnimation, forKey: "shake")
    }
    
    // MARK: - Warning Feedback Animations
    
    /// Apply warning feedback animation
    /// - Parameters:
    ///   - view: View to animate
    ///   - message: Warning message
    ///   - completion: Completion handler
    public func applyWarningFeedbackAnimation(to view: UIView, message: String, completion: @escaping () -> Void = {}) {
        // Trigger warning haptic
        triggerWarningHaptic()
        
        // Create warning overlay
        let warningOverlay = createWarningOverlay(message: message)
        view.addSubview(warningOverlay)
        
        // Initial state
        warningOverlay.alpha = 0
        warningOverlay.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Animate in
        UIView.animate(withDuration: animationDurations.warningInDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            warningOverlay.alpha = 1.0
            warningOverlay.transform = .identity
        } completion: { _ in
            // Add pulse animation
            self.addPulseAnimation(to: warningOverlay)
            
            // Hold for display duration
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDurations.warningDisplayDuration) {
                // Animate out
                UIView.animate(withDuration: animationDurations.warningOutDuration) {
                    warningOverlay.alpha = 0
                    warningOverlay.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                } completion: { _ in
                    warningOverlay.removeFromSuperview()
                    completion()
                }
            }
        }
    }
    
    /// Create warning overlay
    /// - Parameter message: Warning message
    /// - Returns: Warning overlay view
    private func createWarningOverlay(message: String) -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = feedbackConfig.warningBackgroundColor
        overlay.layer.cornerRadius = 12
        overlay.layer.borderWidth = 1
        overlay.layer.borderColor = feedbackConfig.warningColor.cgColor
        
        // Add warning icon
        let iconView = UIImageView(image: UIImage(systemName: "exclamationmark.circle.fill"))
        iconView.tintColor = feedbackConfig.warningColor
        iconView.frame = CGRect(x: 20, y: 15, width: 30, height: 30)
        overlay.addSubview(iconView)
        
        // Add message label
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = feedbackConfig.warningTextColor
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.numberOfLines = 0
        messageLabel.frame = CGRect(x: 60, y: 15, width: 200, height: 30)
        overlay.addSubview(messageLabel)
        
        // Size overlay based on content
        let contentWidth = max(280, messageLabel.intrinsicContentSize.width + 80)
        overlay.frame = CGRect(x: (UIScreen.main.bounds.width - contentWidth) / 2,
                              y: 100,
                              width: contentWidth,
                              height: 60)
        
        return overlay
    }
    
    /// Add pulse animation to view
    /// - Parameter view: View to pulse
    private func addPulseAnimation(to view: UIView) {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.02
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = 3
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(pulseAnimation, forKey: "pulse")
    }
    
    // MARK: - Health-Specific Feedback Animations
    
    /// Apply health data saved feedback
    /// - Parameters:
    ///   - view: View to animate
    ///   - dataType: Type of health data
    ///   - completion: Completion handler
    public func applyHealthDataSavedFeedback(to view: UIView, dataType: HealthDataType, completion: @escaping () -> Void = {}) {
        let message = "\(dataType.displayName) data saved successfully"
        
        // Apply success feedback with health-specific styling
        let successOverlay = createHealthSuccessOverlay(message: message, dataType: dataType)
        view.addSubview(successOverlay)
        
        // Initial state
        successOverlay.alpha = 0
        successOverlay.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        // Animate in
        UIView.animate(withDuration: animationDurations.healthFeedbackDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            successOverlay.alpha = 1.0
            successOverlay.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                successOverlay.transform = .identity
            } completion: { _ in
                // Add health-specific icon animation
                self.addHealthIconAnimation(to: successOverlay, dataType: dataType)
                
                // Hold for display duration
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDurations.healthFeedbackDisplayDuration) {
                    UIView.animate(withDuration: animationDurations.healthFeedbackOutDuration) {
                        successOverlay.alpha = 0
                        successOverlay.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    } completion: { _ in
                        successOverlay.removeFromSuperview()
                        completion()
                    }
                }
            }
        }
    }
    
    /// Create health success overlay
    /// - Parameters:
    ///   - message: Success message
    ///   - dataType: Health data type
    /// - Returns: Health success overlay
    private func createHealthSuccessOverlay(message: String, dataType: HealthDataType) -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = getHealthDataColor(for: dataType).withAlphaComponent(0.9)
        overlay.layer.cornerRadius = 12
        overlay.layer.shadowColor = getHealthDataColor(for: dataType).cgColor
        overlay.layer.shadowOffset = CGSize(width: 0, height: 4)
        overlay.layer.shadowOpacity = 0.3
        overlay.layer.shadowRadius = 8
        
        // Add health icon
        let iconView = UIImageView(image: UIImage(systemName: getHealthDataIcon(for: dataType)))
        iconView.tintColor = .white
        iconView.frame = CGRect(x: 20, y: 15, width: 30, height: 30)
        overlay.addSubview(iconView)
        
        // Add message label
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.numberOfLines = 0
        messageLabel.frame = CGRect(x: 60, y: 15, width: 200, height: 30)
        overlay.addSubview(messageLabel)
        
        // Size overlay based on content
        let contentWidth = max(280, messageLabel.intrinsicContentSize.width + 80)
        overlay.frame = CGRect(x: (UIScreen.main.bounds.width - contentWidth) / 2,
                              y: 100,
                              width: contentWidth,
                              height: 60)
        
        return overlay
    }
    
    /// Add health icon animation
    /// - Parameters:
    ///   - overlay: Overlay to add animation to
    ///   - dataType: Health data type
    private func addHealthIconAnimation(to overlay: UIView, dataType: HealthDataType) {
        guard let iconView = overlay.subviews.first(where: { $0 is UIImageView }) as? UIImageView else { return }
        
        // Bounce animation
        UIView.animate(withDuration: 0.3, 
                      delay: 0, 
                      options: [.curveEaseInOut]) {
            iconView.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                iconView.transform = .identity
            }
        }
    }
    
    // MARK: - Form Submission Feedback
    
    /// Apply form submission feedback
    /// - Parameters:
    ///   - view: View to animate
    ///   - isSuccess: Whether submission was successful
    ///   - message: Feedback message
    ///   - completion: Completion handler
    public func applyFormSubmissionFeedback(to view: UIView, isSuccess: Bool, message: String, completion: @escaping () -> Void = {}) {
        if isSuccess {
            applySuccessFeedbackAnimation(to: view, message: message, completion: completion)
        } else {
            applyErrorFeedbackAnimation(to: view, message: message, completion: completion)
        }
    }
    
    // MARK: - Loading Feedback Animations
    
    /// Apply loading feedback animation
    /// - Parameters:
    ///   - view: View to animate
    ///   - message: Loading message
    ///   - completion: Completion handler
    public func applyLoadingFeedbackAnimation(to view: UIView, message: String, completion: @escaping () -> Void = {}) {
        // Create loading overlay
        let loadingOverlay = createLoadingOverlay(message: message)
        view.addSubview(loadingOverlay)
        
        // Initial state
        loadingOverlay.alpha = 0
        
        // Animate in
        UIView.animate(withDuration: animationDurations.loadingInDuration) {
            loadingOverlay.alpha = 1.0
        } completion: { _ in
            // Add loading spinner animation
            self.addLoadingSpinnerAnimation(to: loadingOverlay)
            
            completion()
        }
    }
    
    /// Create loading overlay
    /// - Parameter message: Loading message
    /// - Returns: Loading overlay view
    private func createLoadingOverlay(message: String) -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = feedbackConfig.loadingBackgroundColor
        overlay.layer.cornerRadius = 12
        
        // Add loading spinner
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = feedbackConfig.loadingColor
        spinner.frame = CGRect(x: 20, y: 15, width: 30, height: 30)
        overlay.addSubview(spinner)
        
        // Add message label
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = feedbackConfig.loadingTextColor
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.numberOfLines = 0
        messageLabel.frame = CGRect(x: 60, y: 15, width: 200, height: 30)
        overlay.addSubview(messageLabel)
        
        // Size overlay based on content
        let contentWidth = max(280, messageLabel.intrinsicContentSize.width + 80)
        overlay.frame = CGRect(x: (UIScreen.main.bounds.width - contentWidth) / 2,
                              y: 100,
                              width: contentWidth,
                              height: 60)
        
        return overlay
    }
    
    /// Add loading spinner animation
    /// - Parameter overlay: Overlay to add spinner to
    private func addLoadingSpinnerAnimation(to overlay: UIView) {
        guard let spinner = overlay.subviews.first(where: { $0 is UIActivityIndicatorView }) as? UIActivityIndicatorView else { return }
        spinner.startAnimating()
    }
    
    // MARK: - Accessibility Feedback
    
    /// Apply accessibility feedback animation
    /// - Parameters:
    ///   - view: View to animate
    ///   - message: Accessibility message
    ///   - completion: Completion handler
    public func applyAccessibilityFeedbackAnimation(to view: UIView, message: String, completion: @escaping () -> Void = {}) {
        // Create accessibility overlay with high contrast
        let accessibilityOverlay = createAccessibilityOverlay(message: message)
        view.addSubview(accessibilityOverlay)
        
        // Initial state
        accessibilityOverlay.alpha = 0
        accessibilityOverlay.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        // Animate in
        UIView.animate(withDuration: animationDurations.accessibilityDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            accessibilityOverlay.alpha = 1.0
            accessibilityOverlay.transform = .identity
        } completion: { _ in
            // Add high contrast border animation
            self.addHighContrastBorderAnimation(to: accessibilityOverlay)
            
            // Hold for display duration
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDurations.accessibilityDisplayDuration) {
                UIView.animate(withDuration: animationDurations.accessibilityOutDuration) {
                    accessibilityOverlay.alpha = 0
                    accessibilityOverlay.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                } completion: { _ in
                    accessibilityOverlay.removeFromSuperview()
                    completion()
                }
            }
        }
    }
    
    /// Create accessibility overlay
    /// - Parameter message: Accessibility message
    /// - Returns: Accessibility overlay view
    private func createAccessibilityOverlay(message: String) -> UIView {
        let overlay = UIView()
        overlay.backgroundColor = feedbackConfig.accessibilityBackgroundColor
        overlay.layer.cornerRadius = 12
        overlay.layer.borderWidth = 3
        overlay.layer.borderColor = feedbackConfig.accessibilityBorderColor.cgColor
        
        // Add accessibility icon
        let iconView = UIImageView(image: UIImage(systemName: "accessibility"))
        iconView.tintColor = feedbackConfig.accessibilityTextColor
        iconView.frame = CGRect(x: 20, y: 15, width: 30, height: 30)
        overlay.addSubview(iconView)
        
        // Add message label
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.textColor = feedbackConfig.accessibilityTextColor
        messageLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        messageLabel.numberOfLines = 0
        messageLabel.frame = CGRect(x: 60, y: 15, width: 200, height: 30)
        overlay.addSubview(messageLabel)
        
        // Size overlay based on content
        let contentWidth = max(300, messageLabel.intrinsicContentSize.width + 80)
        overlay.frame = CGRect(x: (UIScreen.main.bounds.width - contentWidth) / 2,
                              y: 100,
                              width: contentWidth,
                              height: 60)
        
        return overlay
    }
    
    /// Add high contrast border animation
    /// - Parameter view: View to add border animation to
    private func addHighContrastBorderAnimation(to view: UIView) {
        let borderAnimation = CABasicAnimation(keyPath: "borderWidth")
        borderAnimation.duration = 1.0
        borderAnimation.fromValue = 3
        borderAnimation.toValue = 5
        borderAnimation.autoreverses = true
        borderAnimation.repeatCount = 3
        borderAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(borderAnimation, forKey: "borderAnimation")
    }
    
    // MARK: - Utility Methods
    
    /// Get health data color
    /// - Parameter dataType: Health data type
    /// - Returns: Color for the data type
    private func getHealthDataColor(for dataType: HealthDataType) -> UIColor {
        switch dataType {
        case .heartRate:
            return healthFeedbackConfig.heartRateColor
        case .bloodPressure:
            return healthFeedbackConfig.bloodPressureColor
        case .temperature:
            return healthFeedbackConfig.temperatureColor
        case .respiratoryRate:
            return healthFeedbackConfig.respiratoryColor
        case .oxygenSaturation:
            return healthFeedbackConfig.oxygenColor
        case .steps:
            return healthFeedbackConfig.stepsColor
        case .calories:
            return healthFeedbackConfig.caloriesColor
        case .sleep:
            return healthFeedbackConfig.sleepColor
        case .medication:
            return healthFeedbackConfig.medicationColor
        case .appointment:
            return healthFeedbackConfig.appointmentColor
        }
    }
    
    /// Get health data icon
    /// - Parameter dataType: Health data type
    /// - Returns: Icon name for the data type
    private func getHealthDataIcon(for dataType: HealthDataType) -> String {
        switch dataType {
        case .heartRate:
            return "heart.fill"
        case .bloodPressure:
            return "drop.fill"
        case .temperature:
            return "thermometer"
        case .respiratoryRate:
            return "lungs.fill"
        case .oxygenSaturation:
            return "o.circle.fill"
        case .steps:
            return "figure.walk"
        case .calories:
            return "flame.fill"
        case .sleep:
            return "bed.double.fill"
        case .medication:
            return "pill.fill"
        case .appointment:
            return "calendar"
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerSuccessHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func triggerErrorHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    private func triggerWarningHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Supporting Types

/// Animation durations for feedback
public struct FeedbackAnimationDurations {
    public let successInDuration: TimeInterval = 0.4
    public let successDisplayDuration: TimeInterval = 2.0
    public let successOutDuration: TimeInterval = 0.3
    public let errorInDuration: TimeInterval = 0.3
    public let errorDisplayDuration: TimeInterval = 3.0
    public let errorOutDuration: TimeInterval = 0.3
    public let warningInDuration: TimeInterval = 0.3
    public let warningDisplayDuration: TimeInterval = 2.5
    public let warningOutDuration: TimeInterval = 0.3
    public let healthFeedbackDuration: TimeInterval = 0.4
    public let healthFeedbackDisplayDuration: TimeInterval = 2.0
    public let healthFeedbackOutDuration: TimeInterval = 0.3
    public let loadingInDuration: TimeInterval = 0.2
    public let accessibilityDuration: TimeInterval = 0.3
    public let accessibilityDisplayDuration: TimeInterval = 3.0
    public let accessibilityOutDuration: TimeInterval = 0.3
}

/// Feedback configuration
public struct FeedbackConfig {
    public let successColor = UIColor.systemGreen
    public let successBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
    public let successTextColor = UIColor.systemGreen
    public let errorColor = UIColor.systemRed
    public let errorBackgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
    public let errorTextColor = UIColor.systemRed
    public let warningColor = UIColor.systemOrange
    public let warningBackgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
    public let warningTextColor = UIColor.systemOrange
    public let loadingColor = UIColor.systemBlue
    public let loadingBackgroundColor = UIColor.systemBackground
    public let loadingTextColor = UIColor.systemBlue
    public let accessibilityBackgroundColor = UIColor.systemBackground
    public let accessibilityBorderColor = UIColor.systemYellow
    public let accessibilityTextColor = UIColor.systemYellow
}

/// Health feedback configuration
public struct HealthFeedbackConfig {
    public let heartRateColor = UIColor.systemRed
    public let bloodPressureColor = UIColor.systemOrange
    public let temperatureColor = UIColor.systemYellow
    public let respiratoryColor = UIColor.systemBlue
    public let oxygenColor = UIColor.systemCyan
    public let stepsColor = UIColor.systemGreen
    public let caloriesColor = UIColor.systemOrange
    public let sleepColor = UIColor.systemIndigo
    public let medicationColor = UIColor.systemPurple
    public let appointmentColor = UIColor.systemTeal
}

/// Health data types
public enum HealthDataType {
    case heartRate
    case bloodPressure
    case temperature
    case respiratoryRate
    case oxygenSaturation
    case steps
    case calories
    case sleep
    case medication
    case appointment
    
    public var displayName: String {
        switch self {
        case .heartRate:
            return "Heart Rate"
        case .bloodPressure:
            return "Blood Pressure"
        case .temperature:
            return "Temperature"
        case .respiratoryRate:
            return "Respiratory Rate"
        case .oxygenSaturation:
            return "Oxygen Saturation"
        case .steps:
            return "Steps"
        case .calories:
            return "Calories"
        case .sleep:
            return "Sleep"
        case .medication:
            return "Medication"
        case .appointment:
            return "Appointment"
        }
    }
} 