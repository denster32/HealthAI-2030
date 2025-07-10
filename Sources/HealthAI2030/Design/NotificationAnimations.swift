import SwiftUI
import UIKit

/// Advanced notification animations for health app
/// Provides smooth, engaging feedback for health alerts and system notifications
public class NotificationAnimations {
    
    // MARK: - Properties
    
    /// Animation durations for different notification types
    private let animationDurations: NotificationAnimationDurations
    /// Notification configurations
    private let notificationConfig: NotificationConfig
    /// Health alert configurations
    private let healthAlertConfig: HealthAlertConfig
    
    // MARK: - Initialization
    
    public init() {
        self.animationDurations = NotificationAnimationDurations()
        self.notificationConfig = NotificationConfig()
        self.healthAlertConfig = HealthAlertConfig()
    }
    
    // MARK: - Standard Notification Animations
    
    /// Apply notification slide-in animation
    /// - Parameters:
    ///   - notificationView: Notification view to animate
    ///   - fromDirection: Direction to slide from
    ///   - completion: Completion handler
    public func applyNotificationSlideInAnimation(to notificationView: UIView, fromDirection: SlideDirection, completion: @escaping () -> Void = {}) {
        // Set initial position
        let initialTransform = getInitialTransform(for: fromDirection, view: notificationView)
        notificationView.transform = initialTransform
        notificationView.alpha = 0
        
        // Trigger notification haptic
        triggerNotificationHaptic()
        
        // Animate in
        UIView.animate(withDuration: animationDurations.slideInDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            notificationView.transform = .identity
            notificationView.alpha = 1.0
        } completion: { _ in
            completion()
        }
    }
    
    /// Apply notification slide-out animation
    /// - Parameters:
    ///   - notificationView: Notification view to animate
    ///   - toDirection: Direction to slide to
    ///   - completion: Completion handler
    public func applyNotificationSlideOutAnimation(to notificationView: UIView, toDirection: SlideDirection, completion: @escaping () -> Void = {}) {
        let finalTransform = getFinalTransform(for: toDirection, view: notificationView)
        
        UIView.animate(withDuration: animationDurations.slideOutDuration, 
                      delay: 0, 
                      options: [.curveEaseIn]) {
            notificationView.transform = finalTransform
            notificationView.alpha = 0
        } completion: { _ in
            completion()
        }
    }
    
    /// Apply notification bounce animation
    /// - Parameters:
    ///   - notificationView: Notification view to animate
    ///   - completion: Completion handler
    public func applyNotificationBounceAnimation(to notificationView: UIView, completion: @escaping () -> Void = {}) {
        // Initial state
        notificationView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        notificationView.alpha = 0
        
        // Bounce in
        UIView.animate(withDuration: animationDurations.bounceInDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            notificationView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            notificationView.alpha = 1.0
        } completion: { _ in
            // Bounce back
            UIView.animate(withDuration: 0.1) {
                notificationView.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Health Alert Animations
    
    /// Apply health alert animation
    /// - Parameters:
    ///   - alertView: Alert view to animate
    ///   - alertType: Type of health alert
    ///   - completion: Completion handler
    public func applyHealthAlertAnimation(to alertView: UIView, alertType: HealthAlertType, completion: @escaping () -> Void = {}) {
        switch alertType {
        case .critical:
            applyCriticalHealthAlertAnimation(to: alertView, completion: completion)
        case .warning:
            applyWarningHealthAlertAnimation(to: alertView, completion: completion)
        case .info:
            applyInfoHealthAlertAnimation(to: alertView, completion: completion)
        case .reminder:
            applyReminderAlertAnimation(to: alertView, completion: completion)
        }
    }
    
    /// Apply critical health alert animation
    /// - Parameters:
    ///   - alertView: Alert view to animate
    ///   - completion: Completion handler
    private func applyCriticalHealthAlertAnimation(to alertView: UIView, completion: @escaping () -> Void = {}) {
        // Trigger critical haptic
        triggerCriticalHaptic()
        
        // Set critical styling
        alertView.backgroundColor = healthAlertConfig.criticalColor
        alertView.layer.borderColor = healthAlertConfig.criticalBorderColor.cgColor
        alertView.layer.borderWidth = 2.0
        
        // Initial state
        alertView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        alertView.alpha = 0
        
        // Animate in with urgency
        UIView.animate(withDuration: animationDurations.criticalAlertDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            alertView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            alertView.alpha = 1.0
        } completion: { _ in
            // Add pulsing effect
            self.addPulsingEffect(to: alertView, color: healthAlertConfig.criticalColor)
            
            UIView.animate(withDuration: 0.1) {
                alertView.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Apply warning health alert animation
    /// - Parameters:
    ///   - alertView: Alert view to animate
    ///   - completion: Completion handler
    private func applyWarningHealthAlertAnimation(to alertView: UIView, completion: @escaping () -> Void = {}) {
        // Trigger warning haptic
        triggerWarningHaptic()
        
        // Set warning styling
        alertView.backgroundColor = healthAlertConfig.warningColor
        alertView.layer.borderColor = healthAlertConfig.warningBorderColor.cgColor
        alertView.layer.borderWidth = 1.5
        
        // Initial state
        alertView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        alertView.alpha = 0
        
        // Animate in
        UIView.animate(withDuration: animationDurations.warningAlertDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            alertView.transform = .identity
            alertView.alpha = 1.0
        } completion: { _ in
            completion()
        }
    }
    
    /// Apply info health alert animation
    /// - Parameters:
    ///   - alertView: Alert view to animate
    ///   - completion: Completion handler
    private func applyInfoHealthAlertAnimation(to alertView: UIView, completion: @escaping () -> Void = {}) {
        // Trigger info haptic
        triggerInfoHaptic()
        
        // Set info styling
        alertView.backgroundColor = healthAlertConfig.infoColor
        alertView.layer.borderColor = healthAlertConfig.infoBorderColor.cgColor
        alertView.layer.borderWidth = 1.0
        
        // Initial state
        alertView.transform = CGAffineTransform(translationX: 0, y: -50)
        alertView.alpha = 0
        
        // Animate in
        UIView.animate(withDuration: animationDurations.infoAlertDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            alertView.transform = .identity
            alertView.alpha = 1.0
        } completion: { _ in
            completion()
        }
    }
    
    /// Apply reminder alert animation
    /// - Parameters:
    ///   - alertView: Alert view to animate
    ///   - completion: Completion handler
    private func applyReminderAlertAnimation(to alertView: UIView, completion: @escaping () -> Void = {}) {
        // Trigger reminder haptic
        triggerReminderHaptic()
        
        // Set reminder styling
        alertView.backgroundColor = healthAlertConfig.reminderColor
        alertView.layer.borderColor = healthAlertConfig.reminderBorderColor.cgColor
        alertView.layer.borderWidth = 1.0
        
        // Initial state
        alertView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        alertView.alpha = 0
        
        // Gentle animate in
        UIView.animate(withDuration: animationDurations.reminderAlertDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            alertView.transform = .identity
            alertView.alpha = 1.0
        } completion: { _ in
            completion()
        }
    }
    
    // MARK: - Medication Reminder Animations
    
    /// Apply medication reminder animation
    /// - Parameters:
    ///   - reminderView: Reminder view to animate
    ///   - medication: Medication details
    ///   - completion: Completion handler
    public func applyMedicationReminderAnimation(to reminderView: UIView, medication: MedicationReminder, completion: @escaping () -> Void = {}) {
        // Trigger medication haptic
        triggerMedicationHaptic()
        
        // Set medication styling
        reminderView.backgroundColor = healthAlertConfig.medicationColor
        reminderView.layer.borderColor = healthAlertConfig.medicationBorderColor.cgColor
        reminderView.layer.borderWidth = 2.0
        
        // Add medication icon
        let medicationIcon = UIImageView(image: UIImage(systemName: "pill.fill"))
        medicationIcon.tintColor = .white
        medicationIcon.frame = CGRect(x: 15, y: (reminderView.bounds.height - 20) / 2, width: 20, height: 20)
        reminderView.addSubview(medicationIcon)
        
        // Initial state
        reminderView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        reminderView.alpha = 0
        
        // Animate in with medication-specific timing
        UIView.animate(withDuration: animationDurations.medicationReminderDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            reminderView.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
            reminderView.alpha = 1.0
        } completion: { _ in
            // Add gentle pulse for medication reminders
            self.addGentlePulseEffect(to: reminderView)
            
            UIView.animate(withDuration: 0.1) {
                reminderView.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Appointment Reminder Animations
    
    /// Apply appointment reminder animation
    /// - Parameters:
    ///   - reminderView: Reminder view to animate
    ///   - appointment: Appointment details
    ///   - completion: Completion handler
    public func applyAppointmentReminderAnimation(to reminderView: UIView, appointment: AppointmentReminder, completion: @escaping () -> Void = {}) {
        // Trigger appointment haptic
        triggerAppointmentHaptic()
        
        // Set appointment styling
        reminderView.backgroundColor = healthAlertConfig.appointmentColor
        reminderView.layer.borderColor = healthAlertConfig.appointmentBorderColor.cgColor
        reminderView.layer.borderWidth = 2.0
        
        // Add calendar icon
        let calendarIcon = UIImageView(image: UIImage(systemName: "calendar"))
        calendarIcon.tintColor = .white
        calendarIcon.frame = CGRect(x: 15, y: (reminderView.bounds.height - 20) / 2, width: 20, height: 20)
        reminderView.addSubview(calendarIcon)
        
        // Initial state
        reminderView.transform = CGAffineTransform(translationX: 0, y: -30)
        reminderView.alpha = 0
        
        // Animate in
        UIView.animate(withDuration: animationDurations.appointmentReminderDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            reminderView.transform = .identity
            reminderView.alpha = 1.0
        } completion: { _ in
            completion()
        }
    }
    
    // MARK: - Achievement Notification Animations
    
    /// Apply achievement notification animation
    /// - Parameters:
    ///   - achievementView: Achievement view to animate
    ///   - achievement: Achievement details
    ///   - completion: Completion handler
    public func applyAchievementNotificationAnimation(to achievementView: UIView, achievement: Achievement, completion: @escaping () -> Void = {}) {
        // Trigger achievement haptic
        triggerAchievementHaptic()
        
        // Set achievement styling
        achievementView.backgroundColor = healthAlertConfig.achievementColor
        achievementView.layer.borderColor = healthAlertConfig.achievementBorderColor.cgColor
        achievementView.layer.borderWidth = 2.0
        
        // Add trophy icon
        let trophyIcon = UIImageView(image: UIImage(systemName: "trophy.fill"))
        trophyIcon.tintColor = .white
        trophyIcon.frame = CGRect(x: 15, y: (achievementView.bounds.height - 20) / 2, width: 20, height: 20)
        achievementView.addSubview(trophyIcon)
        
        // Initial state
        achievementView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        achievementView.alpha = 0
        
        // Animate in with celebration
        UIView.animate(withDuration: animationDurations.achievementNotificationDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            achievementView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            achievementView.alpha = 1.0
        } completion: { _ in
            // Add celebration effect
            self.addCelebrationEffect(to: achievementView)
            
            UIView.animate(withDuration: 0.1) {
                achievementView.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    // MARK: - Dismissal Animations
    
    /// Apply notification dismissal animation
    /// - Parameters:
    ///   - notificationView: Notification view to animate
    ///   - dismissalType: Type of dismissal
    ///   - completion: Completion handler
    public func applyNotificationDismissalAnimation(to notificationView: UIView, dismissalType: DismissalType, completion: @escaping () -> Void = {}) {
        switch dismissalType {
        case .swipe:
            applySwipeDismissalAnimation(to: notificationView, completion: completion)
        case .tap:
            applyTapDismissalAnimation(to: notificationView, completion: completion)
        case .auto:
            applyAutoDismissalAnimation(to: notificationView, completion: completion)
        case .fade:
            applyFadeDismissalAnimation(to: notificationView, completion: completion)
        }
    }
    
    /// Apply swipe dismissal animation
    /// - Parameters:
    ///   - notificationView: Notification view to animate
    ///   - completion: Completion handler
    private func applySwipeDismissalAnimation(to notificationView: UIView, completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: animationDurations.swipeDismissalDuration, 
                      delay: 0, 
                      options: [.curveEaseIn]) {
            notificationView.transform = CGAffineTransform(translationX: notificationView.bounds.width, y: 0)
            notificationView.alpha = 0
        } completion: { _ in
            completion()
        }
    }
    
    /// Apply tap dismissal animation
    /// - Parameters:
    ///   - notificationView: Notification view to animate
    ///   - completion: Completion handler
    private func applyTapDismissalAnimation(to notificationView: UIView, completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: animationDurations.tapDismissalDuration, 
                      delay: 0, 
                      options: [.curveEaseInOut]) {
            notificationView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            notificationView.alpha = 0
        } completion: { _ in
            completion()
        }
    }
    
    /// Apply auto dismissal animation
    /// - Parameters:
    ///   - notificationView: Notification view to animate
    ///   - completion: Completion handler
    private func applyAutoDismissalAnimation(to notificationView: UIView, completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: animationDurations.autoDismissalDuration, 
                      delay: 0, 
                      options: [.curveEaseInOut]) {
            notificationView.transform = CGAffineTransform(translationX: 0, y: -50)
            notificationView.alpha = 0
        } completion: { _ in
            completion()
        }
    }
    
    /// Apply fade dismissal animation
    /// - Parameters:
    ///   - notificationView: Notification view to animate
    ///   - completion: Completion handler
    private func applyFadeDismissalAnimation(to notificationView: UIView, completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: animationDurations.fadeDismissalDuration, 
                      delay: 0, 
                      options: [.curveEaseInOut]) {
            notificationView.alpha = 0
        } completion: { _ in
            completion()
        }
    }
    
    // MARK: - Visual Effects
    
    /// Add pulsing effect to view
    /// - Parameters:
    ///   - view: View to add pulse to
    ///   - color: Pulse color
    private func addPulsingEffect(to view: UIView, color: UIColor) {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.05
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(pulseAnimation, forKey: "pulse")
    }
    
    /// Add gentle pulse effect to view
    /// - Parameter view: View to add gentle pulse to
    private func addGentlePulseEffect(to view: UIView) {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 2.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.02
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(pulseAnimation, forKey: "gentlePulse")
    }
    
    /// Add celebration effect to view
    /// - Parameter view: View to add celebration to
    private func addCelebrationEffect(to view: UIView) {
        // Add confetti effect
        for _ in 0..<15 {
            let confetti = UIView()
            confetti.backgroundColor = [UIColor.systemYellow, UIColor.systemPink, UIColor.systemBlue, UIColor.systemGreen].randomElement()
            confetti.frame = CGRect(x: CGFloat.random(in: 0...view.bounds.width),
                                   y: -10,
                                   width: 4,
                                   height: 4)
            confetti.layer.cornerRadius = 2
            
            view.addSubview(confetti)
            
            UIView.animate(withDuration: 1.5, 
                          delay: Double.random(in: 0...0.3), 
                          options: [.curveEaseOut]) {
                confetti.frame.origin.y = view.bounds.height + 10
                confetti.alpha = 0
            } completion: { _ in
                confetti.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get initial transform for slide direction
    /// - Parameters:
    ///   - direction: Slide direction
    ///   - view: View to transform
    /// - Returns: Initial transform
    private func getInitialTransform(for direction: SlideDirection, view: UIView) -> CGAffineTransform {
        switch direction {
        case .top:
            return CGAffineTransform(translationX: 0, y: -view.bounds.height)
        case .bottom:
            return CGAffineTransform(translationX: 0, y: view.bounds.height)
        case .left:
            return CGAffineTransform(translationX: -view.bounds.width, y: 0)
        case .right:
            return CGAffineTransform(translationX: view.bounds.width, y: 0)
        }
    }
    
    /// Get final transform for slide direction
    /// - Parameters:
    ///   - direction: Slide direction
    ///   - view: View to transform
    /// - Returns: Final transform
    private func getFinalTransform(for direction: SlideDirection, view: UIView) -> CGAffineTransform {
        switch direction {
        case .top:
            return CGAffineTransform(translationX: 0, y: -view.bounds.height)
        case .bottom:
            return CGAffineTransform(translationX: 0, y: view.bounds.height)
        case .left:
            return CGAffineTransform(translationX: -view.bounds.width, y: 0)
        case .right:
            return CGAffineTransform(translationX: view.bounds.width, y: 0)
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerNotificationHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func triggerCriticalHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    private func triggerWarningHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func triggerInfoHaptic() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    private func triggerReminderHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func triggerMedicationHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func triggerAppointmentHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func triggerAchievementHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
}

// MARK: - Supporting Types

/// Animation durations for notifications
public struct NotificationAnimationDurations {
    public let slideInDuration: TimeInterval = 0.4
    public let slideOutDuration: TimeInterval = 0.3
    public let bounceInDuration: TimeInterval = 0.5
    public let criticalAlertDuration: TimeInterval = 0.6
    public let warningAlertDuration: TimeInterval = 0.4
    public let infoAlertDuration: TimeInterval = 0.3
    public let reminderAlertDuration: TimeInterval = 0.4
    public let medicationReminderDuration: TimeInterval = 0.5
    public let appointmentReminderDuration: TimeInterval = 0.4
    public let achievementNotificationDuration: TimeInterval = 0.6
    public let swipeDismissalDuration: TimeInterval = 0.3
    public let tapDismissalDuration: TimeInterval = 0.2
    public let autoDismissalDuration: TimeInterval = 0.4
    public let fadeDismissalDuration: TimeInterval = 0.3
}

/// Notification configuration
public struct NotificationConfig {
    public let primaryColor = UIColor.systemBlue
    public let secondaryColor = UIColor.systemGray
    public let successColor = UIColor.systemGreen
    public let errorColor = UIColor.systemRed
}

/// Health alert configuration
public struct HealthAlertConfig {
    public let criticalColor = UIColor.systemRed
    public let criticalBorderColor = UIColor.systemRed
    public let warningColor = UIColor.systemOrange
    public let warningBorderColor = UIColor.systemOrange
    public let infoColor = UIColor.systemBlue
    public let infoBorderColor = UIColor.systemBlue
    public let reminderColor = UIColor.systemGreen
    public let reminderBorderColor = UIColor.systemGreen
    public let medicationColor = UIColor.systemPurple
    public let medicationBorderColor = UIColor.systemPurple
    public let appointmentColor = UIColor.systemTeal
    public let appointmentBorderColor = UIColor.systemTeal
    public let achievementColor = UIColor.systemYellow
    public let achievementBorderColor = UIColor.systemYellow
}

/// Slide directions
public enum SlideDirection {
    case top
    case bottom
    case left
    case right
}

/// Health alert types
public enum HealthAlertType {
    case critical
    case warning
    case info
    case reminder
}

/// Dismissal types
public enum DismissalType {
    case swipe
    case tap
    case auto
    case fade
}

/// Medication reminder structure
public struct MedicationReminder {
    public let name: String
    public let dosage: String
    public let time: Date
    public let instructions: String
    
    public init(name: String, dosage: String, time: Date, instructions: String) {
        self.name = name
        self.dosage = dosage
        self.time = time
        self.instructions = instructions
    }
}

/// Appointment reminder structure
public struct AppointmentReminder {
    public let title: String
    public let date: Date
    public let location: String
    public let doctor: String
    
    public init(title: String, date: Date, location: String, doctor: String) {
        self.title = title
        self.date = date
        self.location = location
        self.doctor = doctor
    }
}

/// Achievement structure
public struct Achievement {
    public let title: String
    public let description: String
    public let icon: String
    public let type: AchievementType
    
    public init(title: String, description: String, icon: String, type: AchievementType) {
        self.title = title
        self.description = description
        self.icon = icon
        self.type = type
    }
}

/// Achievement types
public enum AchievementType {
    case daily
    case weekly
    case monthly
    case milestone
    case special
} 