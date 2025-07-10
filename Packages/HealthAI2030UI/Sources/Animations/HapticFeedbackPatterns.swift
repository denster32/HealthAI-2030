import SwiftUI

// MARK: - Haptic Feedback Patterns
/// Comprehensive haptic feedback patterns for enhanced user experience
/// Provides tactile feedback for various interactions and states
public struct HapticFeedbackPatterns {
    
    // MARK: - Haptic Feedback Manager
    
    /// Centralized haptic feedback manager
    public class HapticManager: ObservableObject {
        public static let shared = HapticManager()
        
        private let lightImpact = UIImpactFeedbackGenerator(style: .light)
        private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
        private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
        private let softImpact = UIImpactFeedbackGenerator(style: .soft)
        private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
        private let notificationFeedback = UINotificationFeedbackGenerator()
        private let selectionFeedback = UISelectionFeedbackGenerator()
        
        private init() {
            // Prepare generators for immediate use
            lightImpact.prepare()
            mediumImpact.prepare()
            heavyImpact.prepare()
            softImpact.prepare()
            rigidImpact.prepare()
            notificationFeedback.prepare()
            selectionFeedback.prepare()
        }
        
        // MARK: - Impact Feedback
        
        public func lightImpact() {
            lightImpact.impactOccurred()
        }
        
        public func mediumImpact() {
            mediumImpact.impactOccurred()
        }
        
        public func heavyImpact() {
            heavyImpact.impactOccurred()
        }
        
        public func softImpact() {
            softImpact.impactOccurred()
        }
        
        public func rigidImpact() {
            rigidImpact.impactOccurred()
        }
        
        // MARK: - Notification Feedback
        
        public func successNotification() {
            notificationFeedback.notificationOccurred(.success)
        }
        
        public func warningNotification() {
            notificationFeedback.notificationOccurred(.warning)
        }
        
        public func errorNotification() {
            notificationFeedback.notificationOccurred(.error)
        }
        
        // MARK: - Selection Feedback
        
        public func selectionChanged() {
            selectionFeedback.selectionChanged()
        }
        
        // MARK: - Custom Patterns
        
        public func buttonPress() {
            lightImpact()
        }
        
        public func buttonRelease() {
            softImpact()
        }
        
        public func toggleSwitch() {
            mediumImpact()
        }
        
        public func sliderChange() {
            lightImpact()
        }
        
        public func cardFlip() {
            mediumImpact()
        }
        
        public func listScroll() {
            softImpact()
        }
        
        public func refreshComplete() {
            successNotification()
        }
        
        public func errorOccurred() {
            errorNotification()
        }
        
        public func achievementUnlocked() {
            heavyImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.successNotification()
            }
        }
        
        public func healthGoalReached() {
            mediumImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.successNotification()
            }
        }
        
        public func emergencyAlert() {
            heavyImpact()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.errorNotification()
            }
        }
    }
    
    // MARK: - Haptic Button Animation
    
    /// Button with haptic feedback animation
    public struct HapticButton: View {
        let title: String
        let icon: String
        let style: ButtonStyle
        let onPress: () -> Void
        @State private var isPressed: Bool = false
        @State private var scale: CGFloat = 1.0
        
        public init(
            title: String,
            icon: String = "",
            style: ButtonStyle = .primary,
            onPress: @escaping () -> Void
        ) {
            self.title = title
            self.icon = icon
            self.style = style
            self.onPress = onPress
        }
        
        public var body: some View {
            Button(action: {
                HapticManager.shared.buttonPress()
                onPress()
            }) {
                HStack(spacing: 8) {
                    if !icon.isEmpty {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(style.textColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(style.backgroundColor)
                .cornerRadius(12)
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 0.1), value: scale)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    scale = pressing ? 0.95 : 1.0
                }
                
                if !pressing {
                    HapticManager.shared.buttonRelease()
                }
            }, perform: {})
        }
    }
    
    // MARK: - Haptic Toggle Animation
    
    /// Toggle with haptic feedback animation
    public struct HapticToggle: View {
        let title: String
        let isOn: Bool
        let onToggle: (Bool) -> Void
        @State private var isAnimating: Bool = false
        
        public init(
            title: String,
            isOn: Bool,
            onToggle: @escaping (Bool) -> Void
        ) {
            self.title = title
            self.isOn = isOn
            self.onToggle = onToggle
        }
        
        public var body: some View {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.toggleSwitch()
                    onToggle(!isOn)
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isAnimating = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isAnimating = false
                    }
                }) {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isOn ? Color.blue : Color(.systemGray4))
                        .frame(width: 50, height: 30)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 26, height: 26)
                                .offset(x: isOn ? 10 : -10)
                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Haptic Slider Animation
    
    /// Slider with haptic feedback animation
    public struct HapticSlider: View {
        let title: String
        let value: Binding<Double>
        let range: ClosedRange<Double>
        let step: Double
        @State private var isDragging: Bool = false
        
        public init(
            title: String,
            value: Binding<Double>,
            range: ClosedRange<Double> = 0...1,
            step: Double = 0.01
        ) {
            self.title = title
            self.value = value
            self.range = range
            self.step = step
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(value.wrappedValue * 100))%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                Slider(value: value, in: range, step: step)
                    .accentColor(.blue)
                    .onChanged { _ in
                        if !isDragging {
                            isDragging = true
                            HapticManager.shared.sliderChange()
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Haptic Card Animation
    
    /// Card with haptic feedback animation
    public struct HapticCard: View {
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
        let onTap: () -> Void
        @State private var isPressed: Bool = false
        @State private var scale: CGFloat = 1.0
        @State private var rotation: Double = 0
        
        public init(
            title: String,
            subtitle: String,
            icon: String,
            color: Color = .blue,
            onTap: @escaping () -> Void
        ) {
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.color = color
            self.onTap = onTap
        }
        
        public var body: some View {
            Button(action: {
                HapticManager.shared.cardFlip()
                onTap()
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    rotation += 180
                }
            }) {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(color)
                        .frame(width: 60, height: 60)
                        .background(color.opacity(0.1))
                        .clipShape(Circle())
                        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 0.1), value: scale)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    scale = pressing ? 0.95 : 1.0
                }
            }, perform: {})
        }
    }
    
    // MARK: - Haptic List Animation
    
    /// List with haptic feedback animation
    public struct HapticList: View {
        let items: [HapticListItem]
        let onItemTap: (HapticListItem) -> Void
        @State private var selectedItem: HapticListItem?
        
        public init(
            items: [HapticListItem],
            onItemTap: @escaping (HapticListItem) -> Void
        ) {
            self.items = items
            self.onItemTap = onItemTap
        }
        
        public var body: some View {
            LazyVStack(spacing: 8) {
                ForEach(items) { item in
                    HapticListItemView(
                        item: item,
                        isSelected: selectedItem?.id == item.id
                    )
                    .onTapGesture {
                        HapticManager.shared.selectionChanged()
                        selectedItem = item
                        onItemTap(item)
                    }
                }
            }
        }
    }
    
    // MARK: - Haptic Success Animation
    
    /// Success animation with haptic feedback
    public struct HapticSuccessAnimation: View {
        let title: String
        let message: String
        let onComplete: () -> Void
        @State private var isAnimating: Bool = false
        @State private var showContent: Bool = false
        
        public init(
            title: String,
            message: String,
            onComplete: @escaping () -> Void
        ) {
            self.title = title
            self.message = message
            self.onComplete = onComplete
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true), value: isAnimating)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.green)
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)
                }
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3).delay(0.2), value: showContent)
                    
                    Text(message)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3).delay(0.4), value: showContent)
                }
            }
            .padding(32)
            .onAppear {
                HapticManager.shared.successNotification()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    showContent = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isAnimating = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    onComplete()
                }
            }
        }
    }
    
    // MARK: - Haptic Error Animation
    
    /// Error animation with haptic feedback
    public struct HapticErrorAnimation: View {
        let title: String
        let message: String
        let onDismiss: () -> Void
        @State private var isShaking: Bool = false
        @State private var showContent: Bool = false
        
        public init(
            title: String,
            message: String,
            onDismiss: @escaping () -> Void
        ) {
            self.title = title
            self.message = message
            self.onDismiss = onDismiss
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.red)
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .offset(x: isShaking ? 10 : 0)
                    .animation(.easeInOut(duration: 0.1).repeatCount(isShaking ? 6 : 0, autoreverses: true), value: isShaking)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3).delay(0.2), value: showContent)
                    
                    Text(message)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3).delay(0.4), value: showContent)
                }
                
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3).delay(0.6), value: showContent)
            }
            .padding(32)
            .onAppear {
                HapticManager.shared.errorNotification()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    showContent = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isShaking = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isShaking = false
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum ButtonStyle {
    case primary
    case secondary
    case destructive
    case success
    
    var backgroundColor: Color {
        switch self {
        case .primary: return .blue
        case .secondary: return Color(.systemGray5)
        case .destructive: return .red
        case .success: return .green
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary, .destructive, .success: return .white
        case .secondary: return .primary
        }
    }
}

struct HapticListItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    init(id: String, title: String, subtitle: String, icon: String, color: Color = .blue) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
}

struct HapticListItemView: View {
    let item: HapticListItem
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(item.color)
                .frame(width: 40, height: 40)
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
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Slider Extension

extension Slider {
    func onChanged(_ action: @escaping (Double) -> Void) -> some View {
        self.onReceive(Just(value)) { value in
            action(value)
        }
    }
    
    func onEnded(_ action: @escaping (Double) -> Void) -> some View {
        self.onReceive(Just(value)) { value in
            action(value)
        }
    }
}

// MARK: - Preview

struct HapticFeedbackPatterns_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            HapticButton(title: "Press Me", icon: "hand.tap") {
                print("Button pressed")
            }
            
            HapticToggle(title: "Enable Notifications", isOn: true) { _ in
                print("Toggle changed")
            }
            
            HapticSlider(title: "Volume", value: .constant(0.7)) {
                print("Slider changed")
            }
            
            HapticCard(
                title: "Health Card",
                subtitle: "Your health summary",
                icon: "heart.fill",
                color: .red
            ) {
                print("Card tapped")
            }
            
            HapticSuccessAnimation(
                title: "Success!",
                message: "Your action was completed successfully"
            ) {
                print("Success animation completed")
            }
            
            HapticErrorAnimation(
                title: "Error",
                message: "Something went wrong. Please try again."
            ) {
                print("Error dismissed")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 