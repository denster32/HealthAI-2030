import SwiftUI

// MARK: - Notification Animations
/// Comprehensive notification animations for enhanced user experience
/// Provides smooth, accessible, and engaging notification animations for various message types
public struct NotificationAnimations {
    
    // MARK: - Toast Notification Animation
    
    /// Toast notification with slide-in and fade animations
    public struct ToastNotificationAnimation: View {
        let title: String
        let message: String?
        let type: NotificationType
        let duration: TimeInterval
        let onDismiss: () -> Void
        @State private var isVisible: Bool = false
        @State private var offset: CGFloat = -200
        @State private var opacity: Double = 0
        @State private var scale: CGFloat = 0.8
        
        public init(
            title: String,
            message: String? = nil,
            type: NotificationType = .info,
            duration: TimeInterval = 3.0,
            onDismiss: @escaping () -> Void
        ) {
            self.title = title
            self.message = message
            self.type = type
            self.duration = duration
            self.onDismiss = onDismiss
        }
        
        public var body: some View {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(type.color)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let message = message {
                        Text(message)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Dismiss button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: type.color.opacity(0.2),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(type.color.opacity(0.3), lineWidth: 1)
            )
            .offset(y: offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                show()
            }
        }
        
        private func show() {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
                offset = 0
                opacity = 1
                scale = 1.0
            }
            
            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                dismiss()
            }
        }
        
        private func dismiss() {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = false
                offset = -200
                opacity = 0
                scale = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onDismiss()
            }
        }
    }
    
    // MARK: - Banner Notification Animation
    
    /// Banner notification with slide-down animation
    public struct BannerNotificationAnimation: View {
        let title: String
        let subtitle: String?
        let type: NotificationType
        let actionTitle: String?
        let action: (() -> Void)?
        let onDismiss: () -> Void
        @State private var isVisible: Bool = false
        @State private var offset: CGFloat = -100
        @State private var opacity: Double = 0
        @State private var progress: Double = 0
        
        public init(
            title: String,
            subtitle: String? = nil,
            type: NotificationType = .info,
            actionTitle: String? = nil,
            action: (() -> Void)? = nil,
            onDismiss: @escaping () -> Void
        ) {
            self.title = title
            self.subtitle = subtitle
            self.type = type
            self.actionTitle = actionTitle
            self.action = action
            self.onDismiss = onDismiss
        }
        
        public var body: some View {
            VStack(spacing: 0) {
                // Main banner
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: type.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(type.color)
                        .frame(width: 32, height: 32)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Action button
                    if let actionTitle = actionTitle, let action = action {
                        Button(action: {
                            action()
                            dismiss()
                        }) {
                            Text(actionTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(type.color)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Dismiss button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: type.color.opacity(0.2),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                )
                
                // Progress bar
                Rectangle()
                    .fill(type.color)
                    .frame(height: 2)
                    .scaleEffect(x: progress, anchor: .leading)
            }
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                show()
            }
        }
        
        private func show() {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
                offset = 0
                opacity = 1
            }
            
            // Progress animation
            withAnimation(.linear(duration: 5.0)) {
                progress = 1.0
            }
            
            // Auto-dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                dismiss()
            }
        }
        
        private func dismiss() {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = false
                offset = -100
                opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onDismiss()
            }
        }
    }
    
    // MARK: - Modal Notification Animation
    
    /// Modal notification with scale and fade animations
    public struct ModalNotificationAnimation: View {
        let title: String
        let message: String
        let type: NotificationType
        let primaryAction: NotificationAction?
        let secondaryAction: NotificationAction?
        let onDismiss: () -> Void
        @State private var isVisible: Bool = false
        @State private var scale: CGFloat = 0.8
        @State private var opacity: Double = 0
        @State private var blurRadius: CGFloat = 20
        
        public init(
            title: String,
            message: String,
            type: NotificationType = .info,
            primaryAction: NotificationAction? = nil,
            secondaryAction: NotificationAction? = nil,
            onDismiss: @escaping () -> Void
        ) {
            self.title = title
            self.message = message
            self.type = type
            self.primaryAction = primaryAction
            self.secondaryAction = secondaryAction
            self.onDismiss = onDismiss
        }
        
        public var body: some View {
            ZStack {
                // Background blur
                Color.black.opacity(0.3)
                    .blur(radius: blurRadius)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                
                // Modal content
                VStack(spacing: 20) {
                    // Icon
                    Image(systemName: type.icon)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(type.color)
                        .padding(.top, 20)
                    
                    // Title
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    // Message
                    Text(message)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        if let secondaryAction = secondaryAction {
                            Button(action: {
                                secondaryAction.action()
                                dismiss()
                            }) {
                                Text(secondaryAction.title)
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
                        }
                        
                        if let primaryAction = primaryAction {
                            Button(action: {
                                primaryAction.action()
                                dismiss()
                            }) {
                                Text(primaryAction.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(type.color)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: .black.opacity(0.2),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                )
                .scaleEffect(scale)
                .opacity(opacity)
                .padding(.horizontal, 40)
            }
            .onAppear {
                show()
            }
        }
        
        private func show() {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
                scale = 1.0
                opacity = 1
                blurRadius = 0
            }
        }
        
        private func dismiss() {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = false
                scale = 0.8
                opacity = 0
                blurRadius = 20
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onDismiss()
            }
        }
    }
    
    // MARK: - Inline Notification Animation
    
    /// Inline notification with expand/collapse animations
    public struct InlineNotificationAnimation: View {
        let title: String
        let message: String
        let type: NotificationType
        let isExpanded: Bool
        let onToggle: () -> Void
        let onDismiss: () -> Void
        @State private var height: CGFloat = 0
        @State private var opacity: Double = 0
        @State private var rotation: Double = 0
        
        public init(
            title: String,
            message: String,
            type: NotificationType = .info,
            isExpanded: Bool = false,
            onToggle: @escaping () -> Void,
            onDismiss: @escaping () -> Void
        ) {
            self.title = title
            self.message = message
            self.type = type
            self.isExpanded = isExpanded
            self.onToggle = onToggle
            self.onDismiss = onDismiss
        }
        
        public var body: some View {
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: type.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(type.color)
                    
                    // Title
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Expand/collapse button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            rotation += 180
                        }
                        onToggle()
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(rotation))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Dismiss button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(type.color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(type.color.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Expandable content
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(message)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }
            }
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    opacity = 1
                }
            }
        }
        
        private func dismiss() {
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss()
            }
        }
    }
    
    // MARK: - Badge Notification Animation
    
    /// Badge notification with pulse and bounce animations
    public struct BadgeNotificationAnimation: View {
        let count: Int
        let color: Color
        let size: CGFloat
        @State private var scale: CGFloat = 1.0
        @State private var pulseScale: CGFloat = 1.0
        @State private var rotation: Double = 0
        
        public init(
            count: Int,
            color: Color = .red,
            size: CGFloat = 20
        ) {
            self.count = count
            self.color = color
            self.size = size
        }
        
        public var body: some View {
            ZStack {
                // Background
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .scaleEffect(scale * pulseScale)
                    .rotationEffect(.degrees(rotation))
                
                // Count text
                Text("\(count > 99 ? "99+" : "\(count)")")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
            }
            .onAppear {
                startAnimation()
            }
            .onChange(of: count) { _ in
                startAnimation()
            }
        }
        
        private func startAnimation() {
            // Bounce animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
            
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
            
            // Rotation animation
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Supporting Types

enum NotificationType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

struct NotificationAction {
    let title: String
    let action: () -> Void
    
    init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
}

// MARK: - Preview

struct NotificationAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ToastNotificationAnimation(
                title: "Success!",
                message: "Your changes have been saved.",
                type: .success
            ) {
                print("Toast dismissed")
            }
            
            BannerNotificationAnimation(
                title: "New Message",
                subtitle: "You have a new message from John",
                type: .info,
                actionTitle: "View"
            ) {
                print("Banner action")
            } onDismiss: {
                print("Banner dismissed")
            }
            
            BadgeNotificationAnimation(count: 5)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 