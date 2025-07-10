import SwiftUI
import CoreHaptics

/// Comprehensive Animation System for HealthAI 2030
/// Provides micro-interactions, haptic feedback, and smooth transitions
public struct HealthAIAnimations {
    
    // MARK: - Animation Configuration
    public struct Configuration {
        public static let defaultDuration: Double = 0.3
        public static let fastDuration: Double = 0.15
        public static let slowDuration: Double = 0.6
        public static let springResponse: Double = 0.3
        public static let springDamping: Double = 0.8
        public static let springBlendDuration: Double = 0.2
    }
    
    // MARK: - Animation Presets
    public struct Presets {
        // Standard animations
        public static let standard = Animation.easeInOut(duration: Configuration.defaultDuration)
        public static let fast = Animation.easeInOut(duration: Configuration.fastDuration)
        public static let slow = Animation.easeInOut(duration: Configuration.slowDuration)
        
        // Spring animations
        public static let spring = Animation.spring(
            response: Configuration.springResponse,
            dampingFraction: Configuration.springDamping,
            blendDuration: Configuration.springBlendDuration
        )
        
        public static let springBouncy = Animation.spring(
            response: 0.4,
            dampingFraction: 0.6,
            blendDuration: Configuration.springBlendDuration
        )
        
        public static let springStiff = Animation.spring(
            response: 0.2,
            dampingFraction: 0.9,
            blendDuration: Configuration.springBlendDuration
        )
        
        // Health-specific animations
        public static let heartbeat = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        public static let breathing = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        public static let pulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        public static let loading = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)
        
        // Micro-interactions
        public static let buttonPress = Animation.easeInOut(duration: 0.1)
        public static let cardHover = Animation.easeInOut(duration: 0.25)
        public static let listItemAppear = Animation.easeOut(duration: 0.3)
        public static let modalPresent = Animation.spring(response: 0.4, dampingFraction: 0.8)
        public static let modalDismiss = Animation.easeInOut(duration: 0.2)
    }
    
    // MARK: - Haptic Feedback
    public class HapticManager: ObservableObject {
        public static let shared = HapticManager()
        
        #if os(iOS)
        private var engine: CHHapticEngine?
        #endif
        
        private init() {
            setupHapticEngine()
        }
        
        private func setupHapticEngine() {
            #if os(iOS)
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
            
            do {
                engine = try CHHapticEngine()
                try engine?.start()
            } catch {
                print("Failed to start haptic engine: \(error)")
            }
            #endif
        }
        
        // MARK: - Haptic Patterns
        public func success() {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
        }
        
        public func error() {
            #if os(iOS)
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            #endif
        }
        
        public func warning() {
            #if os(iOS)
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
            #endif
        }
        
        public func selection() {
            #if os(iOS)
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
            #endif
        }
        
        public func lightImpact() {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif
        }
        
        public func mediumImpact() {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            #endif
        }
        
        public func heavyImpact() {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            #endif
        }
        
        // MARK: - Custom Haptic Patterns
        public func heartbeatPattern() {
            #if os(iOS)
            guard let engine = engine else { return }
            
            let pattern = CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ], relativeTime: 0.1)
            ], parameters: [])
            
            do {
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                print("Failed to play heartbeat pattern: \(error)")
            }
            #endif
        }
        
        public func breathingPattern() {
            #if os(iOS)
            guard let engine = engine else { return }
            
            let pattern = CHHapticPattern(events: [
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ], relativeTime: 0, duration: 1.0),
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.1),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ], relativeTime: 1.0, duration: 1.0)
            ], parameters: [])
            
            do {
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } catch {
                print("Failed to play breathing pattern: \(error)")
            }
            #endif
        }
    }
    
    // MARK: - Animation Modifiers
    public struct AnimatedScale: ViewModifier {
        let scale: CGFloat
        let animation: Animation
        
        public init(scale: CGFloat = 1.0, animation: Animation = Presets.spring) {
            self.scale = scale
            self.animation = animation
        }
        
        public func body(content: Content) -> some View {
            content
                .scaleEffect(scale)
                .animation(animation, value: scale)
        }
    }
    
    public struct AnimatedOpacity: ViewModifier {
        let opacity: Double
        let animation: Animation
        
        public init(opacity: Double = 1.0, animation: Animation = Presets.standard) {
            self.opacity = opacity
            self.animation = animation
        }
        
        public func body(content: Content) -> some View {
            content
                .opacity(opacity)
                .animation(animation, value: opacity)
        }
    }
    
    public struct AnimatedOffset: ViewModifier {
        let offset: CGSize
        let animation: Animation
        
        public init(offset: CGSize = .zero, animation: Animation = Presets.spring) {
            self.offset = offset
            self.animation = animation
        }
        
        public func body(content: Content) -> some View {
            content
                .offset(offset)
                .animation(animation, value: offset)
        }
    }
    
    public struct AnimatedRotation: ViewModifier {
        let angle: Angle
        let animation: Animation
        
        public init(angle: Angle = .zero, animation: Animation = Presets.spring) {
            self.angle = angle
            self.animation = animation
        }
        
        public func body(content: Content) -> some View {
            content
                .rotationEffect(angle)
                .animation(animation, value: angle)
        }
    }
    
    // MARK: - Micro-interaction Modifiers
    public struct ButtonPressAnimation: ViewModifier {
        @State private var isPressed = false
        let onPress: () -> Void
        
        public init(onPress: @escaping () -> Void) {
            self.onPress = onPress
        }
        
        public func body(content: Content) -> some View {
            content
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(Presets.buttonPress, value: isPressed)
                .onTapGesture {
                    isPressed = true
                    HapticManager.shared.lightImpact()
                    onPress()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }
        }
    }
    
    public struct CardHoverAnimation: ViewModifier {
        @State private var isHovered = false
        
        public func body(content: Content) -> some View {
            content
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .shadow(radius: isHovered ? 8 : 4)
                .animation(Presets.cardHover, value: isHovered)
                #if os(macOS)
                .onHover { hovering in
                    isHovered = hovering
                }
                #endif
        }
    }
    
    public struct ListItemAnimation: ViewModifier {
        let index: Int
        @State private var hasAppeared = false
        
        public init(index: Int) {
            self.index = index
        }
        
        public func body(content: Content) -> some View {
            content
                .offset(y: hasAppeared ? 0 : 50)
                .opacity(hasAppeared ? 1.0 : 0.0)
                .animation(
                    Presets.listItemAppear.delay(Double(index) * 0.1),
                    value: hasAppeared
                )
                .onAppear {
                    hasAppeared = true
                }
        }
    }
    
    // MARK: - Health-specific Animations
    public struct HeartbeatAnimation: ViewModifier {
        @State private var isBeating = false
        
        public func body(content: Content) -> some View {
            content
                .scaleEffect(isBeating ? 1.1 : 1.0)
                .animation(Presets.heartbeat, value: isBeating)
                .onAppear {
                    isBeating = true
                }
        }
    }
    
    public struct BreathingAnimation: ViewModifier {
        @State private var isBreathing = false
        
        public func body(content: Content) -> some View {
            content
                .scaleEffect(isBreathing ? 1.05 : 1.0)
                .opacity(isBreathing ? 0.8 : 1.0)
                .animation(Presets.breathing, value: isBreathing)
                .onAppear {
                    isBreathing = true
                }
        }
    }
    
    public struct PulseAnimation: ViewModifier {
        @State private var isPulsing = false
        
        public func body(content: Content) -> some View {
            content
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.6 : 1.0)
                .animation(Presets.pulse, value: isPulsing)
                .onAppear {
                    isPulsing = true
                }
        }
    }
    
    public struct LoadingAnimation: ViewModifier {
        @State private var isRotating = false
        
        public func body(content: Content) -> some View {
            content
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(Presets.loading, value: isRotating)
                .onAppear {
                    isRotating = true
                }
        }
    }
    
    // MARK: - Transition Animations
    public struct SlideTransition: ViewModifier {
        let edge: Edge
        let isPresented: Bool
        
        public init(edge: Edge = .trailing, isPresented: Bool) {
            self.edge = edge
            self.isPresented = isPresented
        }
        
        public func body(content: Content) -> some View {
            content
                .transition(.asymmetric(
                    insertion: .move(edge: edge).combined(with: .opacity),
                    removal: .move(edge: edge).combined(with: .opacity)
                ))
                .animation(Presets.modalPresent, value: isPresented)
        }
    }
    
    public struct FadeTransition: ViewModifier {
        let isPresented: Bool
        
        public init(isPresented: Bool) {
            self.isPresented = isPresented
        }
        
        public func body(content: Content) -> some View {
            content
                .transition(.opacity.combined(with: .scale))
                .animation(Presets.modalPresent, value: isPresented)
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Applies animated scale
    public func healthAIAnimatedScale(
        scale: CGFloat = 1.0,
        animation: Animation = HealthAIAnimations.Presets.spring
    ) -> some View {
        self.modifier(HealthAIAnimations.AnimatedScale(scale: scale, animation: animation))
    }
    
    /// Applies animated opacity
    public func healthAIAnimatedOpacity(
        opacity: Double = 1.0,
        animation: Animation = HealthAIAnimations.Presets.standard
    ) -> some View {
        self.modifier(HealthAIAnimations.AnimatedOpacity(opacity: opacity, animation: animation))
    }
    
    /// Applies animated offset
    public func healthAIAnimatedOffset(
        offset: CGSize = .zero,
        animation: Animation = HealthAIAnimations.Presets.spring
    ) -> some View {
        self.modifier(HealthAIAnimations.AnimatedOffset(offset: offset, animation: animation))
    }
    
    /// Applies animated rotation
    public func healthAIAnimatedRotation(
        angle: Angle = .zero,
        animation: Animation = HealthAIAnimations.Presets.spring
    ) -> some View {
        self.modifier(HealthAIAnimations.AnimatedRotation(angle: angle, animation: animation))
    }
    
    /// Applies button press animation with haptic feedback
    public func healthAIButtonPress(onPress: @escaping () -> Void) -> some View {
        self.modifier(HealthAIAnimations.ButtonPressAnimation(onPress: onPress))
    }
    
    /// Applies card hover animation
    public func healthAICardHover() -> some View {
        self.modifier(HealthAIAnimations.CardHoverAnimation())
    }
    
    /// Applies list item animation
    public func healthAIListItemAnimation(index: Int) -> some View {
        self.modifier(HealthAIAnimations.ListItemAnimation(index: index))
    }
    
    /// Applies heartbeat animation
    public func healthAIHeartbeat() -> some View {
        self.modifier(HealthAIAnimations.HeartbeatAnimation())
    }
    
    /// Applies breathing animation
    public func healthAIBreathing() -> some View {
        self.modifier(HealthAIAnimations.BreathingAnimation())
    }
    
    /// Applies pulse animation
    public func healthAIPulse() -> some View {
        self.modifier(HealthAIAnimations.PulseAnimation())
    }
    
    /// Applies loading animation
    public func healthAILoading() -> some View {
        self.modifier(HealthAIAnimations.LoadingAnimation())
    }
    
    /// Applies slide transition
    public func healthAISlideTransition(edge: Edge = .trailing, isPresented: Bool) -> some View {
        self.modifier(HealthAIAnimations.SlideTransition(edge: edge, isPresented: isPresented))
    }
    
    /// Applies fade transition
    public func healthAIFadeTransition(isPresented: Bool) -> some View {
        self.modifier(HealthAIAnimations.FadeTransition(isPresented: isPresented))
    }
}

// MARK: - Animation Testing
public struct AnimationTesting {
    /// Tests animation performance
    public static func testAnimationPerformance<T: View>(_ view: T, animation: Animation) -> AnimationMetrics {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate animation
        let _ = view.animation(animation, value: true)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        return AnimationMetrics(
            duration: duration,
            isOptimal: duration < 0.016 // 60 FPS threshold
        )
    }
}

public struct AnimationMetrics {
    public let duration: CFTimeInterval
    public let isOptimal: Bool
} 