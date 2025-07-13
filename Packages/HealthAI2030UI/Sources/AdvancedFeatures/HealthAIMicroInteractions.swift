import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - HealthAI Advanced Micro-Interactions
/// Advanced micro-interactions and haptic feedback system for HealthAI 2030
/// Provides sophisticated animations, tactile feedback, and enhanced user experience

// MARK: - Haptic Feedback Manager
public class HealthAIHapticManager: ObservableObject {
    public static let shared = HealthAIHapticManager()
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    private init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        impactFeedback.prepare()
        notificationFeedback.prepare()
        selectionFeedback.prepare()
    }
    
    // MARK: - Health-Specific Haptics
    public func heartRateAlert() {
        notificationFeedback.notificationOccurred(.warning)
    }
    
    public func healthGoalAchieved() {
        notificationFeedback.notificationOccurred(.success)
    }
    
    public func healthWarning() {
        notificationFeedback.notificationOccurred(.error)
    }
    
    public func dataRecorded() {
        impactFeedback.impactOccurred(intensity: 0.7)
    }
    
    public func metricChanged() {
        selectionFeedback.selectionChanged()
    }
    
    public func buttonPress() {
        impactFeedback.impactOccurred(intensity: 0.5)
    }
    
    public func cardTap() {
        impactFeedback.impactOccurred(intensity: 0.3)
    }
}

// MARK: - Advanced Animation Presets
public struct HealthAIAdvancedAnimations {
    
    // MARK: - Health Metric Animations
    public static let healthMetricUpdate = Animation.spring(
        response: 0.6,
        dampingFraction: 0.8,
        blendDuration: 0.3
    )
    
    public static let heartRatePulse = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    
    public static let activityRingFill = Animation.spring(
        response: 1.0,
        dampingFraction: 0.6,
        blendDuration: 0.5
    )
    
    public static let sleepWave = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    
    // MARK: - UI State Animations
    public static let cardHover = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7,
        blendDuration: 0.1
    )
    
    public static let modalPresentation = Animation.spring(
        response: 0.5,
        dampingFraction: 0.8,
        blendDuration: 0.2
    )
    
    public static let listItemAppear = Animation.spring(
        response: 0.4,
        dampingFraction: 0.8,
        blendDuration: 0.1
    )
    
    // MARK: - Data Visualization Animations
    public static let chartDataLoad = Animation.easeOut(duration: 1.2)
    
    public static let progressBarFill = Animation.spring(
        response: 0.8,
        dampingFraction: 0.7,
        blendDuration: 0.3
    )
    
    public static let counterIncrement = Animation.spring(
        response: 0.4,
        dampingFraction: 0.6,
        blendDuration: 0.1
    )
}

// MARK: - Micro-Interaction Components

// MARK: - Pulsing Heart Rate Indicator
public struct PulsingHeartRateIndicator: View {
    @State private var isPulsing = false
    let heartRate: Double
    let color: Color
    
    public init(heartRate: Double, color: Color = .red) {
        self.heartRate = heartRate
        self.color = color
    }
    
    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                HealthAIAdvancedAnimations.heartRatePulse,
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Breathing Animation
public struct BreathingAnimation: View {
    @State private var isBreathing = false
    let color: Color
    let size: CGFloat
    
    public init(color: Color = .blue, size: CGFloat = 100) {
        self.color = color
        self.size = size
    }
    
    public var body: some View {
        Circle()
            .fill(color.opacity(0.3))
            .frame(width: size, height: size)
            .scaleEffect(isBreathing ? 1.2 : 0.8)
            .animation(
                HealthAIAdvancedAnimations.sleepWave,
                value: isBreathing
            )
            .onAppear {
                isBreathing = true
            }
    }
}

// MARK: - Animated Health Metric
public struct AnimatedHealthMetric: View {
    @State private var displayedValue: Double = 0
    let targetValue: Double
    let unit: String
    let color: Color
    let format: String
    
    public init(
        value: Double,
        unit: String,
        color: Color = .primary,
        format: String = "%.1f"
    ) {
        self.targetValue = value
        self.unit = unit
        self.color = color
        self.format = format
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            Text(String(format: format, displayedValue))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .contentTransition(.numericText())
            
            Text(unit)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(color.opacity(0.7))
        }
        .onAppear {
            animateToTarget()
        }
        .onChange(of: targetValue) { _ in
            animateToTarget()
        }
    }
    
    private func animateToTarget() {
        withAnimation(HealthAIAdvancedAnimations.counterIncrement) {
            displayedValue = targetValue
        }
    }
}

// MARK: - Interactive Health Card
public struct InteractiveHealthCard<Content: View>: View {
    @State private var isPressed = false
    @State private var isHovered = false
    let title: String
    let content: Content
    let onTap: () -> Void
    
    public init(
        title: String,
        @ViewBuilder content: () -> Content,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.content = content()
        self.onTap = onTap
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(0.1),
                    radius: isHovered ? 8 : 4,
                    x: 0,
                    y: isHovered ? 4 : 2
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(HealthAIAdvancedAnimations.cardHover, value: isHovered)
        .animation(HealthAIAdvancedAnimations.cardHover, value: isPressed)
        .onTapGesture {
            withAnimation(HealthAIAdvancedAnimations.cardHover) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(HealthAIAdvancedAnimations.cardHover) {
                    isPressed = false
                }
                HealthAIHapticManager.shared.cardTap()
                onTap()
            }
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Animated Progress Ring
public struct AnimatedProgressRing: View {
    @State private var progress: Double = 0
    let targetProgress: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    
    public init(
        progress: Double,
        color: Color = .blue,
        size: CGFloat = 100,
        lineWidth: CGFloat = 8
    ) {
        self.targetProgress = progress
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    HealthAIAdvancedAnimations.activityRingFill,
                    value: progress
                )
        }
        .frame(width: size, height: size)
        .onAppear {
            animateProgress()
        }
        .onChange(of: targetProgress) { _ in
            animateProgress()
        }
    }
    
    private func animateProgress() {
        withAnimation(HealthAIAdvancedAnimations.activityRingFill) {
            progress = targetProgress
        }
    }
}

// MARK: - Floating Action Button
public struct FloatingActionButton: View {
    @State private var isPressed = false
    let icon: String
    let color: Color
    let action: () -> Void
    
    public init(
        icon: String,
        color: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            withAnimation(HealthAIAdvancedAnimations.cardHover) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(HealthAIAdvancedAnimations.cardHover) {
                    isPressed = false
                }
                HealthAIHapticManager.shared.buttonPress()
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(
                            color: color.opacity(0.3),
                            radius: isPressed ? 4 : 8,
                            x: 0,
                            y: isPressed ? 2 : 4
                        )
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(HealthAIAdvancedAnimations.cardHover, value: isPressed)
    }
}

// MARK: - Animated Chart Data
public struct AnimatedChartData: View {
    @State private var animationProgress: Double = 0
    let data: [Double]
    let color: Color
    let height: CGFloat
    
    public init(
        data: [Double],
        color: Color = .blue,
        height: CGFloat = 100
    ) {
        self.data = data
        self.color = color
        self.height = height
    }
    
    public var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let stepX = width / CGFloat(data.count - 1)
                let maxValue = data.max() ?? 1
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = height - (value / maxValue) * height * animationProgress
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: 3)
            .animation(
                HealthAIAdvancedAnimations.chartDataLoad,
                value: animationProgress
            )
        }
        .frame(height: height)
        .onAppear {
            withAnimation(HealthAIAdvancedAnimations.chartDataLoad) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - Shimmer Loading Effect
public struct ShimmerLoadingEffect: View {
    @State private var isAnimating = false
    let color: Color
    
    public init(color: Color = .gray.opacity(0.3)) {
        self.color = color
    }
    
    public var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                color.opacity(0.3),
                color.opacity(0.7),
                color.opacity(0.3)
            ]),
            startPoint: isAnimating ? .leading : .trailing,
            endPoint: isAnimating ? .trailing : .leading
        )
        .mask(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
        )
        .animation(
            Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Confetti Animation
public struct ConfettiAnimation: View {
    @State private var isAnimating = false
    let color: Color
    
    public init(color: Color = .yellow) {
        self.color = color
    }
    
    public var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .offset(
                        x: isAnimating ? CGFloat.random(in: -100...100) : 0,
                        y: isAnimating ? CGFloat.random(in: -200...200) : 0
                    )
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 2.0)
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Success Checkmark Animation
public struct SuccessCheckmarkAnimation: View {
    @State private var isAnimating = false
    let color: Color
    
    public init(color: Color = .green) {
        self.color = color
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 60, height: 60)
                .scaleEffect(isAnimating ? 1.0 : 0.0)
                .animation(
                    HealthAIAdvancedAnimations.modalPresentation,
                    value: isAnimating
                )
            
            Image(systemName: "checkmark")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .scaleEffect(isAnimating ? 1.0 : 0.0)
                .animation(
                    HealthAIAdvancedAnimations.modalPresentation.delay(0.2),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
            HealthAIHapticManager.shared.healthGoalAchieved()
        }
    }
}

// MARK: - Micro-Interaction Modifiers
public struct MicroInteractionModifiers {
    
    public static func pulseOnTap() -> some ViewModifier {
        PulseOnTapModifier()
    }
    
    public static func shakeOnError() -> some ViewModifier {
        ShakeOnErrorModifier()
    }
    
    public static func bounceOnSuccess() -> some ViewModifier {
        BounceOnSuccessModifier()
    }
}

// MARK: - Pulse On Tap Modifier
struct PulseOnTapModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .animation(
                HealthAIAdvancedAnimations.healthMetricUpdate,
                value: isPulsing
            )
            .onTapGesture {
                withAnimation(HealthAIAdvancedAnimations.healthMetricUpdate) {
                    isPulsing = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(HealthAIAdvancedAnimations.healthMetricUpdate) {
                        isPulsing = false
                    }
                }
                
                HealthAIHapticManager.shared.buttonPress()
            }
    }
}

// MARK: - Shake On Error Modifier
struct ShakeOnErrorModifier: ViewModifier {
    @State private var isShaking = false
    
    func body(content: Content) -> some View {
        content
            .offset(x: isShaking ? 10 : 0)
            .animation(
                Animation.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true),
                value: isShaking
            )
            .onReceive(NotificationCenter.default.publisher(for: .healthError)) { _ in
                withAnimation {
                    isShaking = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        isShaking = false
                    }
                }
                
                HealthAIHapticManager.shared.healthWarning()
            }
    }
}

// MARK: - Bounce On Success Modifier
struct BounceOnSuccessModifier: ViewModifier {
    @State private var isBouncing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? 1.2 : 1.0)
            .animation(
                HealthAIAdvancedAnimations.healthMetricUpdate,
                value: isBouncing
            )
            .onReceive(NotificationCenter.default.publisher(for: .healthSuccess)) { _ in
                withAnimation(HealthAIAdvancedAnimations.healthMetricUpdate) {
                    isBouncing = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(HealthAIAdvancedAnimations.healthMetricUpdate) {
                        isBouncing = false
                    }
                }
                
                HealthAIHapticManager.shared.healthGoalAchieved()
            }
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let healthError = Notification.Name("healthError")
    static let healthSuccess = Notification.Name("healthSuccess")
    static let healthWarning = Notification.Name("healthWarning")
}

// MARK: - Preview
struct HealthAIMicroInteractions_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            PulsingHeartRateIndicator(heartRate: 72)
            
            AnimatedHealthMetric(value: 72, unit: "BPM", color: .red)
            
            AnimatedProgressRing(progress: 0.75, color: .blue)
            
            FloatingActionButton(icon: "plus") {
                print("FAB tapped")
            }
            
            SuccessCheckmarkAnimation()
        }
        .padding()
    }
} 