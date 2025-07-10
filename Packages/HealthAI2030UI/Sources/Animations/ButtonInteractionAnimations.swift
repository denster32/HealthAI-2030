import SwiftUI

// MARK: - Button Interaction Animations
/// Comprehensive button interaction animations for enhanced user experience
/// Provides smooth, accessible, and engaging button animations for all interaction states
public struct ButtonInteractionAnimations {
    
    // MARK: - Primary Button Animations
    
    /// Primary button with comprehensive interaction animations
    public struct PrimaryButtonAnimation: View {
        let title: String
        let icon: String?
        let action: () -> Void
        @State private var isPressed: Bool = false
        @State private var isHovered: Bool = false
        @State private var scale: CGFloat = 1.0
        @State private var rotation: Double = 0
        
        public init(
            title: String,
            icon: String? = nil,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.icon = icon
            self.action = action
        }
        
        public var body: some View {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                    scale = 0.95
                }
                
                // Trigger action with haptic feedback
                HapticManager.shared.impact(.medium)
                action()
                
                // Reset animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                        scale = 1.0
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .rotationEffect(.degrees(rotation))
                    }
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(buttonGradient)
                        .shadow(
                            color: isPressed ? .clear : .blue.opacity(0.3),
                            radius: isPressed ? 0 : 8,
                            x: 0,
                            y: isPressed ? 0 : 4
                        )
                )
                .scaleEffect(scale)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                    scale = hovering ? 1.05 : 1.0
                }
            }
            .onAppear {
                // Start subtle rotation animation for icon
                if icon != nil {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
        }
        
        private var buttonGradient: LinearGradient {
            LinearGradient(
                colors: isPressed ? 
                    [Color.blue.opacity(0.8), Color.blue.opacity(0.6)] :
                    [Color.blue, Color.blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Secondary Button Animations
    
    /// Secondary button with subtle interaction animations
    public struct SecondaryButtonAnimation: View {
        let title: String
        let icon: String?
        let action: () -> Void
        @State private var isPressed: Bool = false
        @State private var isHovered: Bool = false
        @State private var scale: CGFloat = 1.0
        @State private var borderWidth: CGFloat = 1
        
        public init(
            title: String,
            icon: String? = nil,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.icon = icon
            self.action = action
        }
        
        public var body: some View {
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = true
                    scale = 0.98
                    borderWidth = 2
                }
                
                HapticManager.shared.impact(.light)
                action()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        isPressed = false
                        scale = 1.0
                        borderWidth = 1
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: borderWidth)
                        )
                )
                .scaleEffect(scale)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(isHovered ? 0.1 : 0))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                    scale = hovering ? 1.02 : 1.0
                }
            }
        }
    }
    
    // MARK: - Icon Button Animations
    
    /// Icon button with rotation and scale animations
    public struct IconButtonAnimation: View {
        let icon: String
        let size: CGFloat
        let color: Color
        let action: () -> Void
        @State private var isPressed: Bool = false
        @State private var isHovered: Bool = false
        @State private var scale: CGFloat = 1.0
        @State private var rotation: Double = 0
        @State private var pulseScale: CGFloat = 1.0
        
        public init(
            icon: String,
            size: CGFloat = 24,
            color: Color = .blue,
            action: @escaping () -> Void
        ) {
            self.icon = icon
            self.size = size
            self.color = color
            self.action = action
        }
        
        public var body: some View {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                    scale = 0.8
                    rotation += 180
                }
                
                HapticManager.shared.impact(.light)
                action()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                        scale = 1.0
                    }
                }
            }) {
                Image(systemName: icon)
                    .font(.system(size: size, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: size + 16, height: size + 16)
                    .background(
                        Circle()
                            .fill(color.opacity(isHovered ? 0.1 : 0))
                    )
                    .scaleEffect(scale * pulseScale)
                    .rotationEffect(.degrees(rotation))
            }
            .buttonStyle(PlainButtonStyle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                    scale = hovering ? 1.1 : 1.0
                }
            }
            .onAppear {
                // Start subtle pulse animation
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulseScale = 1.05
                }
            }
        }
    }
    
    // MARK: - Toggle Button Animations
    
    /// Toggle button with smooth state transition animations
    public struct ToggleButtonAnimation: View {
        let title: String
        let isOn: Bool
        let action: () -> Void
        @State private var isPressed: Bool = false
        @State private var scale: CGFloat = 1.0
        @State private var slideOffset: CGFloat = 0
        
        public init(
            title: String,
            isOn: Bool,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.isOn = isOn
            self.action = action
        }
        
        public var body: some View {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                    scale = 0.95
                }
                
                HapticManager.shared.impact(.light)
                action()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                        scale = 1.0
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isOn ? .white : .primary)
                    
                    Spacer()
                    
                    // Toggle switch
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isOn ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 44, height: 24)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .offset(x: slideOffset)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isOn ? Color.green.opacity(0.1) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isOn ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
                .scaleEffect(scale)
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                updateTogglePosition()
            }
            .onChange(of: isOn) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    updateTogglePosition()
                }
            }
        }
        
        private func updateTogglePosition() {
            slideOffset = isOn ? 10 : -10
        }
    }
    
    // MARK: - Loading Button Animations
    
    /// Button with loading state animations
    public struct LoadingButtonAnimation: View {
        let title: String
        let isLoading: Bool
        let action: () -> Void
        @State private var isPressed: Bool = false
        @State private var scale: CGFloat = 1.0
        @State private var rotation: Double = 0
        
        public init(
            title: String,
            isLoading: Bool = false,
            action: @escaping () -> Void
        ) {
            self.title = title
            self.isLoading = isLoading
            self.action = action
        }
        
        public var body: some View {
            Button(action: {
                if !isLoading {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                        scale = 0.95
                    }
                    
                    HapticManager.shared.impact(.medium)
                    action()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = false
                            scale = 1.0
                        }
                    }
                }
            }) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .rotationEffect(.degrees(rotation))
                    } else {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(minWidth: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isLoading ? Color.gray : Color.blue)
                        .shadow(
                            color: isPressed ? .clear : .blue.opacity(0.3),
                            radius: isPressed ? 0 : 8,
                            x: 0,
                            y: isPressed ? 0 : 4
                        )
                )
                .scaleEffect(scale)
                .disabled(isLoading)
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                if isLoading {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
        }
    }
    
    // MARK: - Floating Action Button Animations
    
    /// Floating action button with bounce and shadow animations
    public struct FloatingActionButtonAnimation: View {
        let icon: String
        let action: () -> Void
        @State private var isPressed: Bool = false
        @State private var scale: CGFloat = 1.0
        @State private var shadowRadius: CGFloat = 8
        @State private var bounceOffset: CGFloat = 0
        
        public init(
            icon: String,
            action: @escaping () -> Void
        ) {
            self.icon = icon
            self.action = action
        }
        
        public var body: some View {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                    scale = 0.9
                    shadowRadius = 4
                }
                
                HapticManager.shared.impact(.medium)
                action()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                        scale = 1.0
                        shadowRadius = 8
                    }
                }
            }) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: .blue.opacity(0.3),
                                radius: shadowRadius,
                                x: 0,
                                y: shadowRadius / 2
                            )
                    )
                    .scaleEffect(scale)
                    .offset(y: bounceOffset)
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                // Start subtle bounce animation
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    bounceOffset = -2
                }
            }
        }
    }
}

// MARK: - Haptic Manager

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
    
    func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}

// MARK: - Preview

struct ButtonInteractionAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PrimaryButtonAnimation(title: "Primary Action", icon: "star.fill") {
                print("Primary button tapped")
            }
            
            SecondaryButtonAnimation(title: "Secondary Action", icon: "arrow.right") {
                print("Secondary button tapped")
            }
            
            IconButtonAnimation(icon: "heart.fill", color: .red) {
                print("Icon button tapped")
            }
            
            ToggleButtonAnimation(title: "Toggle Feature", isOn: true) {
                print("Toggle changed")
            }
            
            LoadingButtonAnimation(title: "Loading Action", isLoading: false) {
                print("Loading button tapped")
            }
            
            FloatingActionButtonAnimation(icon: "plus") {
                print("FAB tapped")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 