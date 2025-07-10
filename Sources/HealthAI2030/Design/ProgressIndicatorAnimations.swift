import SwiftUI
import UIKit

/// Advanced progress indicator animations for health app
/// Provides smooth, engaging feedback for data processing and achievement tracking
public class ProgressIndicatorAnimations {
    
    // MARK: - Properties
    
    /// Animation durations for different progress states
    private let animationDurations: ProgressAnimationDurations
    /// Progress indicator configurations
    private let progressConfig: ProgressIndicatorConfig
    /// Achievement animation configurations
    private let achievementConfig: AchievementAnimationConfig
    
    // MARK: - Initialization
    
    public init() {
        self.animationDurations = ProgressAnimationDurations()
        self.progressConfig = ProgressIndicatorConfig()
        self.achievementConfig = AchievementAnimationConfig()
    }
    
    // MARK: - Linear Progress Bar Animations
    
    /// Apply linear progress bar animation
    /// - Parameters:
    ///   - progressBar: Progress bar view to animate
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - completion: Completion handler
    public func applyLinearProgressAnimation(to progressBar: UIView, progress: Float, completion: @escaping () -> Void = {}) {
        // Create progress fill view
        let progressFill = UIView()
        progressFill.backgroundColor = progressConfig.primaryColor
        progressFill.frame = CGRect(x: 0, y: 0, width: 0, height: progressBar.bounds.height)
        progressFill.layer.cornerRadius = progressBar.layer.cornerRadius
        
        progressBar.addSubview(progressFill)
        
        // Animate progress fill
        UIView.animate(withDuration: animationDurations.progressDuration, 
                      delay: 0, 
                      options: [.curveEaseInOut]) {
            progressFill.frame = CGRect(x: 0, 
                                       y: 0, 
                                       width: progressBar.bounds.width * CGFloat(progress), 
                                       height: progressBar.bounds.height)
        } completion: { _ in
            completion()
        }
    }
    
    /// Apply health goal progress animation
    /// - Parameters:
    ///   - progressBar: Progress bar view to animate
    ///   - currentValue: Current health value
    ///   - targetValue: Target health value
    ///   - completion: Completion handler
    public func applyHealthGoalProgressAnimation(to progressBar: UIView, currentValue: Double, targetValue: Double, completion: @escaping () -> Void = {}) {
        let progress = min(currentValue / targetValue, 1.0)
        
        // Apply gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = progressBar.bounds
        gradientLayer.colors = [progressConfig.healthGoalStartColor.cgColor, progressConfig.healthGoalEndColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        progressBar.layer.insertSublayer(gradientLayer, at: 0)
        
        // Create progress fill
        let progressFill = UIView()
        progressFill.backgroundColor = progressConfig.primaryColor
        progressFill.frame = CGRect(x: 0, y: 0, width: 0, height: progressBar.bounds.height)
        progressFill.layer.cornerRadius = progressBar.layer.cornerRadius
        
        progressBar.addSubview(progressFill)
        
        // Animate with bounce effect
        UIView.animate(withDuration: animationDurations.healthGoalDuration, 
                      delay: 0, 
                      options: [.curveEaseInOut]) {
            progressFill.frame = CGRect(x: 0, 
                                       y: 0, 
                                       width: progressBar.bounds.width * CGFloat(progress), 
                                       height: progressBar.bounds.height)
        } completion: { _ in
            if progress >= 1.0 {
                self.triggerGoalAchievementAnimation(for: progressBar)
            }
            completion()
        }
    }
    
    // MARK: - Circular Progress Animations
    
    /// Apply circular progress animation
    /// - Parameters:
    ///   - progressView: Circular progress view to animate
    ///   - progress: Progress value (0.0 to 1.0)
    ///   - completion: Completion handler
    public func applyCircularProgressAnimation(to progressView: UIView, progress: Float, completion: @escaping () -> Void = {}) {
        // Create circular progress layer
        let progressLayer = CAShapeLayer()
        let center = CGPoint(x: progressView.bounds.width / 2, y: progressView.bounds.height / 2)
        let radius = min(progressView.bounds.width, progressView.bounds.height) / 2 - 10
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + (2 * CGFloat.pi * CGFloat(progress))
        
        let path = UIBezierPath(arcCenter: center, 
                               radius: radius, 
                               startAngle: startAngle, 
                               endAngle: endAngle, 
                               clockwise: true)
        
        progressLayer.path = path.cgPath
        progressLayer.strokeColor = progressConfig.primaryColor.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 8
        progressLayer.lineCap = .round
        
        progressView.layer.addSublayer(progressLayer)
        
        // Animate stroke
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.fromValue = 0
        strokeAnimation.toValue = 1
        strokeAnimation.duration = animationDurations.circularProgressDuration
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        progressLayer.add(strokeAnimation, forKey: "strokeAnimation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDurations.circularProgressDuration) {
            completion()
        }
    }
    
    /// Apply health metric circular progress
    /// - Parameters:
    ///   - progressView: Circular progress view to animate
    ///   - metric: Health metric type
    ///   - value: Current value
    ///   - target: Target value
    ///   - completion: Completion handler
    public func applyHealthMetricCircularProgress(to progressView: UIView, metric: HealthMetricType, value: Double, target: Double, completion: @escaping () -> Void = {}) {
        let progress = min(value / target, 1.0)
        let metricColor = getMetricColor(for: metric)
        
        // Create circular progress layer
        let progressLayer = CAShapeLayer()
        let center = CGPoint(x: progressView.bounds.width / 2, y: progressView.bounds.height / 2)
        let radius = min(progressView.bounds.width, progressView.bounds.height) / 2 - 10
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + (2 * CGFloat.pi * CGFloat(progress))
        
        let path = UIBezierPath(arcCenter: center, 
                               radius: radius, 
                               startAngle: startAngle, 
                               endAngle: endAngle, 
                               clockwise: true)
        
        progressLayer.path = path.cgPath
        progressLayer.strokeColor = metricColor.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 10
        progressLayer.lineCap = .round
        
        progressView.layer.addSublayer(progressLayer)
        
        // Add glow effect
        progressLayer.shadowColor = metricColor.cgColor
        progressLayer.shadowOffset = CGSize(width: 0, height: 0)
        progressLayer.shadowOpacity = 0.5
        progressLayer.shadowRadius = 5
        
        // Animate stroke
        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")
        strokeAnimation.fromValue = 0
        strokeAnimation.toValue = 1
        strokeAnimation.duration = animationDurations.healthMetricDuration
        strokeAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        progressLayer.add(strokeAnimation, forKey: "strokeAnimation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDurations.healthMetricDuration) {
            completion()
        }
    }
    
    // MARK: - Loading Animations
    
    /// Apply data loading animation
    /// - Parameters:
    ///   - loadingView: Loading view to animate
    ///   - completion: Completion handler
    public func applyDataLoadingAnimation(to loadingView: UIView, completion: @escaping () -> Void = {}) {
        // Create pulsing dots
        let dotCount = 3
        let dotSize: CGFloat = 8
        let spacing: CGFloat = 12
        
        for i in 0..<dotCount {
            let dot = UIView()
            dot.backgroundColor = progressConfig.loadingColor
            dot.frame = CGRect(x: loadingView.bounds.width / 2 - (CGFloat(dotCount) * spacing) / 2 + CGFloat(i) * spacing,
                              y: loadingView.bounds.height / 2 - dotSize / 2,
                              width: dotSize,
                              height: dotSize)
            dot.layer.cornerRadius = dotSize / 2
            dot.alpha = 0.3
            
            loadingView.addSubview(dot)
            
            // Animate each dot with delay
            UIView.animate(withDuration: 0.6, 
                          delay: Double(i) * 0.2, 
                          options: [.repeat, .autoreverse, .curveEaseInOut]) {
                dot.alpha = 1.0
                dot.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }
        }
        
        // Complete after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDurations.loadingDuration) {
            completion()
        }
    }
    
    /// Apply health data processing animation
    /// - Parameters:
    ///   - processingView: Processing view to animate
    ///   - completion: Completion handler
    public func applyHealthDataProcessingAnimation(to processingView: UIView, completion: @escaping () -> Void = {}) {
        // Create rotating health icon
        let healthIcon = UIImageView(image: UIImage(systemName: "heart.fill"))
        healthIcon.tintColor = progressConfig.healthProcessingColor
        healthIcon.frame = CGRect(x: processingView.bounds.width / 2 - 15,
                                 y: processingView.bounds.height / 2 - 15,
                                 width: 30,
                                 height: 30)
        
        processingView.addSubview(healthIcon)
        
        // Rotate animation
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = 2 * CGFloat.pi
        rotationAnimation.duration = 2.0
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        healthIcon.layer.add(rotationAnimation, forKey: "rotation")
        
        // Pulse animation
        UIView.animate(withDuration: 1.0, 
                      delay: 0, 
                      options: [.repeat, .autoreverse, .curveEaseInOut]) {
            healthIcon.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        
        // Complete after processing duration
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDurations.processingDuration) {
            completion()
        }
    }
    
    // MARK: - Achievement Animations
    
    /// Apply achievement unlock animation
    /// - Parameters:
    ///   - achievementView: Achievement view to animate
    ///   - achievement: Achievement details
    ///   - completion: Completion handler
    public func applyAchievementUnlockAnimation(to achievementView: UIView, achievement: Achievement, completion: @escaping () -> Void = {}) {
        // Trigger achievement haptic
        triggerAchievementHaptic()
        
        // Initial state
        achievementView.alpha = 0
        achievementView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        // Animate in
        UIView.animate(withDuration: animationDurations.achievementInDuration, 
                      delay: 0, 
                      options: [.curveEaseOut]) {
            achievementView.alpha = 1.0
            achievementView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            // Bounce back
            UIView.animate(withDuration: 0.1) {
                achievementView.transform = .identity
            } completion: { _ in
                // Add sparkle effect
                self.addSparkleEffect(to: achievementView)
                
                // Hold for display duration
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDurations.achievementDisplayDuration) {
                    // Animate out
                    UIView.animate(withDuration: animationDurations.achievementOutDuration) {
                        achievementView.alpha = 0
                        achievementView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                    } completion: { _ in
                        completion()
                    }
                }
            }
        }
    }
    
    /// Add sparkle effect to achievement view
    /// - Parameter view: View to add sparkle effect to
    private func addSparkleEffect(to view: UIView) {
        let sparkleCount = 8
        
        for i in 0..<sparkleCount {
            let sparkle = UIImageView(image: UIImage(systemName: "sparkle"))
            sparkle.tintColor = achievementConfig.sparkleColor
            sparkle.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            sparkle.alpha = 0
            
            // Position around the view
            let angle = (2 * CGFloat.pi * CGFloat(i)) / CGFloat(sparkleCount)
            let radius: CGFloat = 50
            sparkle.center = CGPoint(x: view.bounds.width / 2 + cos(angle) * radius,
                                   y: view.bounds.height / 2 + sin(angle) * radius)
            
            view.addSubview(sparkle)
            
            // Animate sparkle
            UIView.animate(withDuration: 0.5, 
                          delay: Double(i) * 0.1, 
                          options: [.curveEaseOut]) {
                sparkle.alpha = 1.0
                sparkle.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            } completion: { _ in
                UIView.animate(withDuration: 0.3) {
                    sparkle.alpha = 0
                    sparkle.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                } completion: { _ in
                    sparkle.removeFromSuperview()
                }
            }
        }
    }
    
    // MARK: - Progress Completion Animations
    
    /// Apply progress completion animation
    /// - Parameters:
    ///   - progressView: Progress view to animate
    ///   - completion: Completion handler
    public func applyProgressCompletionAnimation(to progressView: UIView, completion: @escaping () -> Void = {}) {
        // Trigger completion haptic
        triggerCompletionHaptic()
        
        // Completion animation
        UIView.animate(withDuration: 0.3, 
                      delay: 0, 
                      options: [.curveEaseInOut]) {
            progressView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            progressView.backgroundColor = progressConfig.completionColor
        } completion: { _ in
            // Add completion checkmark
            self.addCompletionCheckmark(to: progressView)
            
            UIView.animate(withDuration: 0.3, 
                          delay: 0.5, 
                          options: [.curveEaseInOut]) {
                progressView.transform = .identity
            } completion: { _ in
                completion()
            }
        }
    }
    
    /// Add completion checkmark to progress view
    /// - Parameter view: View to add checkmark to
    private func addCompletionCheckmark(to view: UIView) {
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .white
        checkmark.frame = CGRect(x: view.bounds.width - 30, y: 5, width: 20, height: 20)
        checkmark.alpha = 0
        
        view.addSubview(checkmark)
        
        UIView.animate(withDuration: 0.3) {
            checkmark.alpha = 1.0
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get color for health metric type
    /// - Parameter metric: Health metric type
    /// - Returns: Color for the metric
    private func getMetricColor(for metric: HealthMetricType) -> UIColor {
        switch metric {
        case .heartRate:
            return progressConfig.heartRateColor
        case .bloodPressure:
            return progressConfig.bloodPressureColor
        case .temperature:
            return progressConfig.temperatureColor
        case .respiratoryRate:
            return progressConfig.respiratoryColor
        case .oxygenSaturation:
            return progressConfig.oxygenColor
        case .steps:
            return progressConfig.stepsColor
        case .calories:
            return progressConfig.caloriesColor
        case .sleep:
            return progressConfig.sleepColor
        }
    }
    
    /// Trigger goal achievement animation
    /// - Parameter view: View to animate
    private func triggerGoalAchievementAnimation(for view: UIView) {
        // Add celebration effect
        let celebrationView = UIView(frame: view.bounds)
        celebrationView.backgroundColor = UIColor.clear
        
        view.addSubview(celebrationView)
        
        // Add confetti effect
        for _ in 0..<20 {
            let confetti = UIView()
            confetti.backgroundColor = [progressConfig.primaryColor, progressConfig.secondaryColor, progressConfig.accentColor].randomElement()
            confetti.frame = CGRect(x: CGFloat.random(in: 0...view.bounds.width),
                                   y: -10,
                                   width: 5,
                                   height: 5)
            confetti.layer.cornerRadius = 2.5
            
            celebrationView.addSubview(confetti)
            
            UIView.animate(withDuration: 2.0, 
                          delay: Double.random(in: 0...0.5), 
                          options: [.curveEaseOut]) {
                confetti.frame.origin.y = view.bounds.height + 10
                confetti.alpha = 0
            } completion: { _ in
                confetti.removeFromSuperview()
            }
        }
        
        // Remove celebration view after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            celebrationView.removeFromSuperview()
        }
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerAchievementHaptic() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func triggerCompletionHaptic() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Supporting Types

/// Animation durations for progress indicators
public struct ProgressAnimationDurations {
    public let progressDuration: TimeInterval = 1.0
    public let healthGoalDuration: TimeInterval = 1.5
    public let circularProgressDuration: TimeInterval = 1.2
    public let healthMetricDuration: TimeInterval = 1.0
    public let loadingDuration: TimeInterval = 2.0
    public let processingDuration: TimeInterval = 3.0
    public let achievementInDuration: TimeInterval = 0.5
    public let achievementDisplayDuration: TimeInterval = 3.0
    public let achievementOutDuration: TimeInterval = 0.3
}

/// Progress indicator configuration
public struct ProgressIndicatorConfig {
    public let primaryColor = UIColor.systemBlue
    public let secondaryColor = UIColor.systemGreen
    public let accentColor = UIColor.systemOrange
    public let healthGoalStartColor = UIColor.systemGreen
    public let healthGoalEndColor = UIColor.systemBlue
    public let loadingColor = UIColor.systemGray
    public let healthProcessingColor = UIColor.systemRed
    public let completionColor = UIColor.systemGreen
    public let heartRateColor = UIColor.systemRed
    public let bloodPressureColor = UIColor.systemOrange
    public let temperatureColor = UIColor.systemYellow
    public let respiratoryColor = UIColor.systemBlue
    public let oxygenColor = UIColor.systemCyan
    public let stepsColor = UIColor.systemGreen
    public let caloriesColor = UIColor.systemOrange
    public let sleepColor = UIColor.systemIndigo
}

/// Achievement animation configuration
public struct AchievementAnimationConfig {
    public let sparkleColor = UIColor.systemYellow
    public let celebrationColor = UIColor.systemPink
}

/// Health metric types
public enum HealthMetricType {
    case heartRate
    case bloodPressure
    case temperature
    case respiratoryRate
    case oxygenSaturation
    case steps
    case calories
    case sleep
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