import SwiftUI

// MARK: - Swipe Gesture Animations
/// Comprehensive swipe gesture animations for enhanced user experience
/// Provides smooth, engaging, and intuitive swipe interactions across the app
public struct SwipeGestureAnimations {
    
    // MARK: - Swipe to Delete Animation
    
    /// Swipe to delete animation with smooth transitions
    public struct SwipeToDeleteAnimation: View {
        let item: SwipeableItem
        let onDelete: () -> Void
        @State private var offset: CGFloat = 0
        @State private var isDeleting: Bool = false
        @State private var deleteButtonOpacity: Double = 0
        
        public init(
            item: SwipeableItem,
            onDelete: @escaping () -> Void
        ) {
            self.item = item
            self.onDelete = onDelete
        }
        
        public var body: some View {
            ZStack {
                // Delete button background
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            isDeleting = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDelete()
                        }
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    .opacity(deleteButtonOpacity)
                    .scaleEffect(isDeleting ? 0.8 : 1.0)
                    .padding(.trailing, 20)
                }
                
                // Main content
                HStack {
                    // Item icon
                    Image(systemName: item.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(item.color)
                        .frame(width: 50, height: 50)
                        .background(item.color.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(item.subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    Circle()
                        .fill(item.statusColor)
                        .frame(width: 12, height: 12)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .offset(x: offset)
                .scaleEffect(isDeleting ? 0.9 : 1.0)
                .opacity(isDeleting ? 0 : 1)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.x
                            offset = translation
                            
                            // Show delete button when swiping left
                            if translation < -50 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    deleteButtonOpacity = 1.0
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    deleteButtonOpacity = 0.0
                                }
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.x
                            let velocity = value.velocity.x
                            
                            // Snap back or trigger delete
                            if translation < -100 || velocity < -500 {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                    offset = -UIScreen.main.bounds.width
                                    isDeleting = true
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onDelete()
                                }
                            } else {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                    offset = 0
                                    deleteButtonOpacity = 0.0
                                }
                            }
                        }
                )
            }
        }
    }
    
    // MARK: - Swipe to Reveal Animation
    
    /// Swipe to reveal hidden actions animation
    public struct SwipeToRevealAnimation: View {
        let item: SwipeableItem
        let actions: [SwipeAction]
        let onAction: (SwipeAction) -> Void
        @State private var offset: CGFloat = 0
        @State private var revealedActions: [Bool] = []
        
        public init(
            item: SwipeableItem,
            actions: [SwipeAction],
            onAction: @escaping (SwipeAction) -> Void
        ) {
            self.item = item
            self.actions = actions
            self.onAction = onAction
            self._revealedActions = State(initialValue: Array(repeating: false, count: actions.count))
        }
        
        public var body: some View {
            ZStack {
                // Action buttons
                HStack {
                    Spacer()
                    
                    ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                onAction(action)
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(action.title)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 60, height: 60)
                            .background(action.color)
                            .clipShape(Circle())
                        }
                        .scaleEffect(revealedActions[index] ? 1.0 : 0.8)
                        .opacity(revealedActions[index] ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1), value: revealedActions[index])
                        .padding(.trailing, index == 0 ? 20 : 10)
                    }
                }
                
                // Main content
                HStack {
                    Image(systemName: item.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(item.color)
                        .frame(width: 50, height: 50)
                        .background(item.color.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(item.subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(offset > 50 ? 90 : 0))
                        .animation(.easeInOut(duration: 0.3), value: offset)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.x
                            offset = translation
                            
                            // Reveal actions progressively
                            for (index, _) in actions.enumerated() {
                                let threshold = CGFloat(index + 1) * 80
                                if translation > threshold {
                                    revealedActions[index] = true
                                } else {
                                    revealedActions[index] = false
                                }
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.x
                            let velocity = value.velocity.x
                            
                            // Snap back or keep revealed
                            if translation < 100 && velocity < 500 {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                    offset = 0
                                    revealedActions = Array(repeating: false, count: actions.count)
                                }
                            } else {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                    offset = CGFloat(actions.count) * 80
                                }
                            }
                        }
                )
            }
        }
    }
    
    // MARK: - Swipe to Dismiss Animation
    
    /// Swipe to dismiss notification or card animation
    public struct SwipeToDismissAnimation: View {
        let content: String
        let type: DismissType
        let onDismiss: () -> Void
        @State private var offset: CGFloat = 0
        @State private var opacity: Double = 1.0
        @State private var scale: CGFloat = 1.0
        
        public init(
            content: String,
            type: DismissType = .notification,
            onDismiss: @escaping () -> Void
        ) {
            self.content = content
            self.type = type
            self.onDismiss = onDismiss
        }
        
        public var body: some View {
            HStack {
                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(type.color)
                    .frame(width: 40, height: 40)
                    .background(type.color.opacity(0.1))
                    .clipShape(Circle())
                
                // Content
                Text(content)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Dismiss button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            .offset(x: offset, y: offset * 0.3)
            .opacity(opacity)
            .scaleEffect(scale)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.x
                        offset = translation
                        
                        // Calculate opacity and scale based on swipe distance
                        let progress = abs(translation) / 200
                        opacity = 1.0 - progress
                        scale = 1.0 - progress * 0.1
                    }
                    .onEnded { value in
                        let translation = value.translation.x
                        let velocity = value.velocity.x
                        
                        // Dismiss if swiped far enough or with enough velocity
                        if abs(translation) > 150 || abs(velocity) > 500 {
                            dismiss()
                        } else {
                            // Snap back
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                offset = 0
                                opacity = 1.0
                                scale = 1.0
                            }
                        }
                    }
            )
        }
        
        private func dismiss() {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                offset = offset > 0 ? 500 : -500
                opacity = 0
                scale = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss()
            }
        }
    }
    
    // MARK: - Swipe to Navigate Animation
    
    /// Swipe to navigate between views animation
    public struct SwipeToNavigateAnimation: View {
        let currentView: String
        let onSwipeLeft: () -> Void
        let onSwipeRight: () -> Void
        @State private var offset: CGFloat = 0
        @State private var nextViewOffset: CGFloat = 0
        @State private var isTransitioning: Bool = false
        
        public init(
            currentView: String,
            onSwipeLeft: @escaping () -> Void,
            onSwipeRight: @escaping () -> Void
        ) {
            self.currentView = currentView
            self.onSwipeLeft = onSwipeLeft
            self.onSwipeRight = onSwipeRight
        }
        
        public var body: some View {
            ZStack {
                // Next view (left)
                if offset > 0 {
                    VStack {
                        Text("Previous View")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Text("Swipe right to go back")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
                    .offset(x: -UIScreen.main.bounds.width + offset)
                }
                
                // Current view
                VStack {
                    Text(currentView)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Swipe left or right to navigate")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .offset(x: offset)
                .scaleEffect(isTransitioning ? 0.95 : 1.0)
                
                // Next view (right)
                if offset < 0 {
                    VStack {
                        Text("Next View")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Text("Swipe left to continue")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
                    .offset(x: UIScreen.main.bounds.width + offset)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.x
                        offset = translation
                    }
                    .onEnded { value in
                        let translation = value.translation.x
                        let velocity = value.velocity.x
                        
                        if translation > 100 || velocity > 500 {
                            // Swipe right - go to previous
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                offset = UIScreen.main.bounds.width
                                isTransitioning = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSwipeRight()
                                offset = 0
                                isTransitioning = false
                            }
                        } else if translation < -100 || velocity < -500 {
                            // Swipe left - go to next
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                offset = -UIScreen.main.bounds.width
                                isTransitioning = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSwipeLeft()
                                offset = 0
                                isTransitioning = false
                            }
                        } else {
                            // Snap back
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                offset = 0
                            }
                        }
                    }
            )
        }
    }
}

// MARK: - Supporting Types

struct SwipeableItem {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let statusColor: Color
    
    init(title: String, subtitle: String, icon: String, color: Color = .blue, statusColor: Color = .green) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.statusColor = statusColor
    }
}

struct SwipeAction {
    let title: String
    let icon: String
    let color: Color
    
    init(title: String, icon: String, color: Color) {
        self.title = title
        self.icon = icon
        self.color = color
    }
}

enum DismissType {
    case notification
    case warning
    case success
    case error
    
    var icon: String {
        switch self {
        case .notification: return "bell.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .notification: return .blue
        case .warning: return .orange
        case .success: return .green
        case .error: return .red
        }
    }
}

// MARK: - Preview

struct SwipeGestureAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SwipeToDeleteAnimation(
                item: SwipeableItem(
                    title: "Health Record",
                    subtitle: "Updated 2 hours ago",
                    icon: "heart.fill",
                    color: .red
                )
            ) {
                print("Item deleted")
            }
            
            SwipeToRevealAnimation(
                item: SwipeableItem(
                    title: "Appointment",
                    subtitle: "Tomorrow at 2:00 PM",
                    icon: "calendar",
                    color: .blue
                ),
                actions: [
                    SwipeAction(title: "Edit", icon: "pencil", color: .blue),
                    SwipeAction(title: "Share", icon: "square.and.arrow.up", color: .green),
                    SwipeAction(title: "Delete", icon: "trash", color: .red)
                ]
            ) { action in
                print("Action: \(action.title)")
            }
            
            SwipeToDismissAnimation(
                content: "Your health data has been updated successfully",
                type: .success
            ) {
                print("Notification dismissed")
            }
            
            SwipeToNavigateAnimation(
                currentView: "Current View"
            ) {
                print("Swiped left")
            } onSwipeRight: {
                print("Swiped right")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 