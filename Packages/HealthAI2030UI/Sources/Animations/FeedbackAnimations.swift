import SwiftUI

// MARK: - Feedback Animations
/// Comprehensive feedback animations for enhanced user experience
/// Provides smooth, accessible, and engaging feedback animations for various user interactions
public struct FeedbackAnimations {
    
    // MARK: - Success Feedback Animation
    
    /// Success feedback with checkmark animation
    public struct SuccessFeedbackAnimation: View {
        let message: String
        let onComplete: () -> Void
        @State private var checkmarkScale: CGFloat = 0
        @State private var circleScale: CGFloat = 0
        @State private var messageOpacity: Double = 0
        @State private var rotation: Double = 0
        
        public init(
            message: String,
            onComplete: @escaping () -> Void
        ) {
            self.message = message
            self.onComplete = onComplete
        }
        
        public var body: some View {
            VStack(spacing: 16) {
                // Success icon
                ZStack {
                    // Background circle
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(circleScale)
                    
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.green)
                        .scaleEffect(checkmarkScale)
                        .rotationEffect(.degrees(rotation))
                }
                
                // Message
                Text(message)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(messageOpacity)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .onAppear {
                startAnimation()
            }
        }
        
        private func startAnimation() {
            // Circle animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                circleScale = 1.0
            }
            
            // Checkmark animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    checkmarkScale = 1.0
                    rotation = 360
                }
            }
            
            // Message animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    messageOpacity = 1.0
                }
            }
            
            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onComplete()
            }
        }
    }
    
    // MARK: - Error Feedback Animation
    
    /// Error feedback with X mark animation
    public struct ErrorFeedbackAnimation: View {
        let message: String
        let onComplete: () -> Void
        @State private var xMarkScale: CGFloat = 0
        @State private var circleScale: CGFloat = 0
        @State private var messageOpacity: Double = 0
        @State private var shakeOffset: CGFloat = 0
        
        public init(
            message: String,
            onComplete: @escaping () -> Void
        ) {
            self.message = message
            self.onComplete = onComplete
        }
        
        public var body: some View {
            VStack(spacing: 16) {
                // Error icon
                ZStack {
                    // Background circle
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(circleScale)
                    
                    // X mark
                    Image(systemName: "xmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.red)
                        .scaleEffect(xMarkScale)
                        .offset(x: shakeOffset)
                }
                
                // Message
                Text(message)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(messageOpacity)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .onAppear {
                startAnimation()
            }
        }
        
        private func startAnimation() {
            // Circle animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                circleScale = 1.0
            }
            
            // X mark animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    xMarkScale = 1.0
                }
            }
            
            // Shake animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.3).repeatCount(3, autoreverses: true)) {
                    shakeOffset = 10
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        shakeOffset = 0
                    }
                }
            }
            
            // Message animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    messageOpacity = 1.0
                }
            }
            
            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onComplete()
            }
        }
    }
    
    // MARK: - Loading Feedback Animation
    
    /// Loading feedback with spinning animation
    public struct LoadingFeedbackAnimation: View {
        let message: String
        let onComplete: () -> Void
        @State private var rotation: Double = 0
        @State private var scale: CGFloat = 1.0
        @State private var messageOpacity: Double = 0
        
        public init(
            message: String,
            onComplete: @escaping () -> Void
        ) {
            self.message = message
            self.onComplete = onComplete
        }
        
        public var body: some View {
            VStack(spacing: 16) {
                // Loading spinner
                ZStack {
                    // Background circle
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    // Spinning circle
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.3)]),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)
                }
                
                // Message
                Text(message)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(messageOpacity)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .onAppear {
                startAnimation()
            }
        }
        
        private func startAnimation() {
            // Spinning animation
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.1
            }
            
            // Message animation
            withAnimation(.easeInOut(duration: 0.5)) {
                messageOpacity = 1.0
            }
        }
    }
    
    // MARK: - Confirmation Feedback Animation
    
    /// Confirmation feedback with question mark animation
    public struct ConfirmationFeedbackAnimation: View {
        let title: String
        let message: String
        let confirmAction: () -> Void
        let cancelAction: () -> Void
        @State private var questionScale: CGFloat = 0
        @State private var circleScale: CGFloat = 0
        @State private var contentOpacity: Double = 0
        @State private var bounceOffset: CGFloat = 0
        
        public init(
            title: String,
            message: String,
            confirmAction: @escaping () -> Void,
            cancelAction: @escaping () -> Void
        ) {
            self.title = title
            self.message = message
            self.confirmAction = confirmAction
            self.cancelAction = cancelAction
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Question icon
                ZStack {
                    // Background circle
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(circleScale)
                    
                    // Question mark
                    Image(systemName: "questionmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.orange)
                        .scaleEffect(questionScale)
                        .offset(y: bounceOffset)
                }
                
                // Content
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(contentOpacity)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        cancelAction()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        confirmAction()
                    }) {
                        Text("Confirm")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .opacity(contentOpacity)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .onAppear {
                startAnimation()
            }
        }
        
        private func startAnimation() {
            // Circle animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                circleScale = 1.0
            }
            
            // Question mark animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    questionScale = 1.0
                }
            }
            
            // Bounce animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.5).repeatCount(2, autoreverses: true)) {
                    bounceOffset = -5
                }
            }
            
            // Content animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    contentOpacity = 1.0
                }
            }
        }
    }
    
    // MARK: - Haptic Feedback Animation
    
    /// Haptic feedback with visual pulse animation
    public struct HapticFeedbackAnimation: View {
        let intensity: HapticIntensity
        let onComplete: () -> Void
        @State private var pulseScale: CGFloat = 1.0
        @State private var opacity: Double = 1.0
        @State private var rotation: Double = 0
        
        public init(
            intensity: HapticIntensity = .medium,
            onComplete: @escaping () -> Void
        ) {
            self.intensity = intensity
            self.onComplete = onComplete
        }
        
        public var body: some View {
            ZStack {
                // Pulse circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(intensity.color.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulseScale)
                        .opacity(opacity)
                        .animation(
                            .easeInOut(duration: intensity.duration)
                            .repeatCount(1, autoreverses: true)
                            .delay(Double(index) * 0.1),
                            value: pulseScale
                        )
                }
                
                // Center indicator
                Circle()
                    .fill(intensity.color)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(rotation))
            }
            .onAppear {
                startAnimation()
            }
        }
        
        private func startAnimation() {
            // Trigger haptic feedback
            HapticManager.shared.impact(intensity.hapticStyle)
            
            // Pulse animation
            withAnimation(.easeInOut(duration: intensity.duration)) {
                pulseScale = intensity.scale
                opacity = 0.0
            }
            
            // Rotation animation
            withAnimation(.linear(duration: intensity.duration)) {
                rotation = 360
            }
            
            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + intensity.duration) {
                onComplete()
            }
        }
    }
    
    // MARK: - Celebration Feedback Animation
    
    /// Celebration feedback with confetti animation
    public struct CelebrationFeedbackAnimation: View {
        let message: String
        let onComplete: () -> Void
        @State private var confettiPieces: [ConfettiPiece] = []
        @State private var messageScale: CGFloat = 0
        @State private var messageOpacity: Double = 0
        
        public init(
            message: String,
            onComplete: @escaping () -> Void
        ) {
            self.message = message
            self.onComplete = onComplete
        }
        
        public var body: some View {
            ZStack {
                // Confetti pieces
                ForEach(confettiPieces, id: \.id) { piece in
                    ConfettiPieceView(piece: piece)
                }
                
                // Celebration message
                VStack(spacing: 16) {
                    Image(systemName: "party.popper.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.orange)
                    
                    Text(message)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .scaleEffect(messageScale)
                .opacity(messageOpacity)
            }
            .onAppear {
                startAnimation()
            }
        }
        
        private func startAnimation() {
            // Generate confetti
            confettiPieces = (0..<20).map { _ in
                ConfettiPiece(
                    id: UUID(),
                    color: [.red, .blue, .green, .yellow, .purple, .orange].randomElement()!,
                    position: CGPoint(
                        x: CGFloat.random(in: -100...100),
                        y: CGFloat.random(in: -100...100)
                    ),
                    rotation: Double.random(in: 0...360),
                    scale: CGFloat.random(in: 0.5...1.5)
                )
            }
            
            // Message animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                messageScale = 1.0
                messageOpacity = 1.0
            }
            
            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onComplete()
            }
        }
    }
}

// MARK: - Supporting Types

enum HapticIntensity {
    case light
    case medium
    case heavy
    
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: return .light
        case .medium: return .medium
        case .heavy: return .heavy
        }
    }
    
    var color: Color {
        switch self {
        case .light: return .blue
        case .medium: return .orange
        case .heavy: return .red
        }
    }
    
    var duration: Double {
        switch self {
        case .light: return 0.3
        case .medium: return 0.5
        case .heavy: return 0.7
        }
    }
    
    var scale: CGFloat {
        switch self {
        case .light: return 1.2
        case .medium: return 1.5
        case .heavy: return 2.0
        }
    }
}

struct ConfettiPiece {
    let id: UUID
    let color: Color
    let position: CGPoint
    let rotation: Double
    let scale: CGFloat
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(piece.rotation))
            .scaleEffect(piece.scale)
            .offset(x: piece.position.x + offset.width, y: piece.position.y + offset.height)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) {
                    offset = CGSize(
                        width: CGFloat.random(in: -50...50),
                        height: -200
                    )
                    opacity = 0.0
                }
            }
    }
}

// MARK: - Preview

struct FeedbackAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SuccessFeedbackAnimation(message: "Operation completed successfully!") {
                print("Success feedback dismissed")
            }
            
            ErrorFeedbackAnimation(message: "Something went wrong. Please try again.") {
                print("Error feedback dismissed")
            }
            
            LoadingFeedbackAnimation(message: "Processing...") {
                print("Loading feedback dismissed")
            }
            
            HapticFeedbackAnimation(intensity: .medium) {
                print("Haptic feedback completed")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 