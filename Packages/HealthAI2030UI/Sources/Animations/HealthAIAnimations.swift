import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Comprehensive Animation System for HealthAI 2030
/// Provides micro-interactions, haptic feedback, and smooth transitions
public struct HealthAIAnimations {
    
    // MARK: - Animation Presets
    public struct Presets {
        public static let smooth = Animation.easeInOut(duration: 0.3)
        public static let spring = Animation.spring(response: 0.3, dampingFraction: 0.8)
        public static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
        public static let quick = Animation.easeInOut(duration: 0.15)
        public static let slow = Animation.easeInOut(duration: 0.6)
        public static let elastic = Animation.spring(response: 0.5, dampingFraction: 0.3)
    }
    
    // MARK: - Micro-interactions
    public struct MicroInteractions {
        
        /// Button press animation with haptic feedback
        public static func buttonPress() -> some ViewModifier {
            return ViewModifier { content in
                content
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.1), value: true)
                    .onTapGesture {
                        HealthAIHaptics.trigger(.light)
                    }
            }
        }
        
        /// Card hover effect with elevation
        public static func cardHover() -> some ViewModifier {
            return ViewModifier { content in
                content
                    .scaleEffect(1.02)
                    .shadow(radius: 12, x: 0, y: 4)
                    .animation(.easeInOut(duration: 0.2), value: true)
            }
        }
        
        /// Health metric pulse animation
        public static func healthPulse() -> some ViewModifier {
            return ViewModifier { content in
                content
                    .scaleEffect(1.1)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: true)
            }
        }
        
        /// Breathing animation for meditation features
        public static func breathing() -> some ViewModifier {
            return ViewModifier { content in
                content
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: true)
            }
        }
        
        /// Heartbeat animation for cardiac health
        public static func heartbeat() -> some ViewModifier {
            return ViewModifier { content in
                content
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: true)
            }
        }
    }
    
    // MARK: - View Transitions
    public struct Transitions {
        public static let slideUp = AnyTransition.move(edge: .bottom).combined(with: .opacity)
        public static let slideDown = AnyTransition.move(edge: .top).combined(with: .opacity)
        public static let slideLeft = AnyTransition.move(edge: .trailing).combined(with: .opacity)
        public static let slideRight = AnyTransition.move(edge: .leading).combined(with: .opacity)
        public static let scale = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let fade = AnyTransition.opacity
        public static let flip = AnyTransition.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.2).combined(with: .opacity)
        )
    }
    
    // MARK: - Animation Modifiers
    public struct Modifiers {
        
        /// Scale animation modifier
        public static func scale(_ scale: CGFloat, animation: Animation = Presets.spring) -> some ViewModifier {
            return ViewModifier { content in
                content.scaleEffect(scale).animation(animation, value: scale)
            }
        }
        
        /// Opacity animation modifier
        public static func opacity(_ opacity: Double, animation: Animation = Presets.smooth) -> some ViewModifier {
            return ViewModifier { content in
                content.opacity(opacity).animation(animation, value: opacity)
            }
        }
        
        /// Offset animation modifier
        public static func offset(_ offset: CGSize, animation: Animation = Presets.spring) -> some ViewModifier {
            return ViewModifier { content in
                content.offset(offset).animation(animation, value: offset)
            }
        }
        
        /// Rotation animation modifier
        public static func rotation(_ angle: Angle, animation: Animation = Presets.smooth) -> some ViewModifier {
            return ViewModifier { content in
                content.rotationEffect(angle).animation(animation, value: angle)
            }
        }
        
        /// List item appearance animation
        public static func listItemAppearance(delay: Double = 0.0) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .opacity(0)
                    .offset(y: 20)
                    .animation(.easeOut(duration: 0.5).delay(delay), value: true)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                            // Trigger animation
                        }
                    }
            }
        }
    }
}

// MARK: - Haptic Feedback System
public struct HealthAIHaptics {
    
    public enum HapticType {
        case light, medium, heavy, success, warning, error, selection, heartbeat, breathing
    }
    
    public static func trigger(_ type: HapticType) {
        #if os(iOS)
        switch type {
        case .light:
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        case .medium:
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        case .heavy:
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        case .success:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        case .selection:
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
        case .heartbeat:
            // Custom heartbeat pattern
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                impactFeedback.impactOccurred()
            }
        case .breathing:
            // Gentle breathing pattern
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        #endif
    }
    
    /// Custom heartbeat haptic pattern
    public static func heartbeatPattern() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        
        // First beat
        impactFeedback.impactOccurred()
        
        // Second beat after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impactFeedback.impactOccurred()
        }
        
        // Third beat after longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            impactFeedback.impactOccurred()
        }
        #endif
    }
    
    /// Breathing pattern haptic feedback
    public static func breathingPattern() {
        #if os(iOS)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        
        // Inhale
        impactFeedback.impactOccurred()
        
        // Hold
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            impactFeedback.impactOccurred()
        }
        
        // Exhale
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            impactFeedback.impactOccurred()
        }
        #endif
    }
}

// MARK: - Animated Health Components

/// Animated health metric card with micro-interactions
public struct AnimatedHealthCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    let trend: String?
    let status: HealthStatus
    
    @State private var isPressed = false
    @State private var isHovered = false
    @State private var isVisible = false
    
    public init(title: String, value: String, unit: String, color: Color, icon: String, trend: String? = nil, status: HealthStatus = .unknown) {
        self.title = title
        self.value = value
        self.unit = unit
        self.color = color
        self.icon = icon
        self.trend = trend
        self.status = status
    }
    
    public var body: some View {
        HealthMetricCard(
            title: title,
            value: value,
            unit: unit,
            color: color,
            icon: icon,
            trend: trend,
            status: status
        )
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
        .shadow(radius: isHovered ? 12 : HealthAIDesignSystem.Layout.shadowRadius, x: 0, y: isHovered ? 4 : 2)
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : 20)
        .animation(HealthAIAnimations.Presets.spring, value: isPressed)
        .animation(HealthAIAnimations.Presets.smooth, value: isHovered)
        .animation(HealthAIAnimations.Presets.smooth, value: isVisible)
        .onTapGesture {
            withAnimation(HealthAIAnimations.Presets.quick) {
                isPressed = true
            }
            HealthAIHaptics.trigger(.medium)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(HealthAIAnimations.Presets.quick) {
                    isPressed = false
                }
            }
        }
        .onAppear {
            withAnimation(HealthAIAnimations.Presets.smooth.delay(0.1)) {
                isVisible = true
            }
        }
        #if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
    }
}

/// Animated button with haptic feedback
public struct AnimatedButton: View {
    let title: String
    let style: HealthAIButton.Style
    let icon: String?
    let hapticType: HealthAIHaptics.HapticType
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    public init(title: String, style: HealthAIButton.Style = .primary, icon: String? = nil, hapticType: HealthAIHaptics.HapticType = .medium, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.icon = icon
        self.hapticType = hapticType
        self.action = action
    }
    
    public var body: some View {
        HealthAIButton(title: title, style: style, icon: icon) {
            HealthAIHaptics.trigger(hapticType)
            action()
        }
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
        .animation(HealthAIAnimations.Presets.spring, value: isPressed)
        .animation(HealthAIAnimations.Presets.smooth, value: isHovered)
        .onTapGesture {
            withAnimation(HealthAIAnimations.Presets.quick) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(HealthAIAnimations.Presets.quick) {
                    isPressed = false
                }
            }
        }
        #if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
    }
}

/// Animated loading view with health-themed animations
public struct AnimatedLoadingView: View {
    let message: String
    let animationType: LoadingAnimationType
    
    @State private var isAnimating = false
    
    public enum LoadingAnimationType {
        case pulse, rotate, breathe, heartbeat
    }
    
    public init(message: String = "Loading...", animationType: LoadingAnimationType = .pulse) {
        self.message = message
        self.animationType = animationType
    }
    
    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.lg) {
            // Animated icon
            Group {
                switch animationType {
                case .pulse:
                    Image(systemName: "heart.fill")
                        .foregroundColor(HealthAIDesignSystem.Colors.primary)
                        .font(.system(size: 48))
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0.6 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                case .rotate:
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(HealthAIDesignSystem.Colors.primary)
                        .font(.system(size: 48))
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnimating)
                case .breathe:
                    Image(systemName: "lungs.fill")
                        .foregroundColor(HealthAIDesignSystem.Colors.primary)
                        .font(.system(size: 48))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                case .heartbeat:
                    Image(systemName: "heart.fill")
                        .foregroundColor(HealthAIDesignSystem.Colors.primary)
                        .font(.system(size: 48))
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                }
            }
            
            // Loading message
            Text(message)
                .font(HealthAIDesignSystem.Typography.body)
                .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(HealthAIDesignSystem.Spacing.xl)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Animation Extensions
extension View {
    /// Apply micro-interaction animations
    public func microInteraction(_ type: HealthAIAnimations.MicroInteractions.Type) -> some View {
        switch type {
        case is HealthAIAnimations.MicroInteractions.Type:
            return self.modifier(HealthAIAnimations.MicroInteractions.buttonPress())
        default:
            return self
        }
    }
    
    /// Apply haptic feedback on tap
    public func hapticFeedback(_ type: HealthAIHaptics.HapticType) -> some View {
        self.onTapGesture {
            HealthAIHaptics.trigger(type)
        }
    }
    
    /// Apply smooth transition
    public func smoothTransition(_ transition: AnyTransition) -> some View {
        self.transition(transition)
    }
} 