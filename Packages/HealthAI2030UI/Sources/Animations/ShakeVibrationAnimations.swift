import SwiftUI

// MARK: - Shake Vibration Animations
/// Comprehensive shake and vibration animations for enhanced user experience
/// Provides haptic feedback and visual shake effects for various interactions
public struct ShakeVibrationAnimations {
    
    // MARK: - Shake to Undo Animation
    
    /// Shake to undo animation with haptic feedback
    public struct ShakeToUndoAnimation: View {
        let onUndo: () -> Void
        @State private var shakeOffset: CGFloat = 0
        @State private var isShaking: Bool = false
        @State private var shakeCount: Int = 0
        @State private var showUndoPrompt: Bool = false
        
        public init(onUndo: @escaping () -> Void) {
            self.onUndo = onUndo
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Main content
                VStack(spacing: 16) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.blue)
                        .scaleEffect(isShaking ? 1.2 : 1.0)
                        .offset(x: shakeOffset)
                        .animation(.easeInOut(duration: 0.1).repeatCount(isShaking ? 10 : 0, autoreverses: true), value: isShaking)
                    
                    Text("Shake to Undo")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Shake your device to undo the last action")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .onShake {
                    startShakeAnimation()
                }
                
                // Undo prompt
                if showUndoPrompt {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.green)
                        
                        Text("Undo Action")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Last action has been undone")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
        }
        
        private func startShakeAnimation() {
            shakeCount += 1
            
            // Trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true)) {
                isShaking = true
                shakeOffset = 10
            }
            
            // Stop shaking after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShaking = false
                    shakeOffset = 0
                }
            }
            
            // Trigger undo after 3 shakes
            if shakeCount >= 3 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showUndoPrompt = true
                }
                
                onUndo()
                
                // Reset after showing prompt
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showUndoPrompt = false
                    }
                    shakeCount = 0
                }
            }
        }
    }
    
    // MARK: - Shake to Refresh Animation
    
    /// Shake to refresh animation with loading states
    public struct ShakeToRefreshAnimation: View {
        let onRefresh: () -> Void
        @State private var shakeOffset: CGFloat = 0
        @State private var isShaking: Bool = false
        @State private var isRefreshing: Bool = false
        @State private var refreshProgress: Double = 0
        
        public init(onRefresh: @escaping () -> Void) {
            self.onRefresh = onRefresh
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Main content
                VStack(spacing: 16) {
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: refreshProgress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        // Icon
                        Image(systemName: isRefreshing ? "arrow.clockwise" : "arrow.clockwise.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .none, value: isRefreshing)
                    }
                    .offset(x: shakeOffset)
                    .animation(.easeInOut(duration: 0.1).repeatCount(isShaking ? 8 : 0, autoreverses: true), value: isShaking)
                    
                    Text(isRefreshing ? "Refreshing..." : "Shake to Refresh")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(isRefreshing ? "Updating your data" : "Shake your device to refresh")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .onShake {
                    if !isRefreshing {
                        startRefreshAnimation()
                    }
                }
            }
            .padding()
        }
        
        private func startRefreshAnimation() {
            // Trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1).repeatCount(8, autoreverses: true)) {
                isShaking = true
                shakeOffset = 15
            }
            
            // Start refresh after shake
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShaking = false
                    shakeOffset = 0
                    isRefreshing = true
                }
                
                // Simulate refresh progress
                withAnimation(.linear(duration: 2.0)) {
                    refreshProgress = 1.0
                }
                
                onRefresh()
                
                // Complete refresh
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isRefreshing = false
                        refreshProgress = 0
                    }
                }
            }
        }
    }
    
    // MARK: - Shake to Report Animation
    
    /// Shake to report issue or feedback animation
    public struct ShakeToReportAnimation: View {
        let onReport: () -> Void
        @State private var shakeOffset: CGFloat = 0
        @State private var isShaking: Bool = false
        @State private var showReportDialog: Bool = false
        @State private var reportType: ReportType = .bug
        
        public init(onReport: @escaping () -> Void) {
            self.onReport = onReport
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Main content
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.orange)
                        .scaleEffect(isShaking ? 1.1 : 1.0)
                        .offset(x: shakeOffset)
                        .animation(.easeInOut(duration: 0.1).repeatCount(isShaking ? 6 : 0, autoreverses: true), value: isShaking)
                    
                    Text("Shake to Report")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Shake your device to report an issue")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .onShake {
                    startReportAnimation()
                }
                
                // Report dialog
                if showReportDialog {
                    VStack(spacing: 16) {
                        Text("Report Issue")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            ForEach(ReportType.allCases, id: \.self) { type in
                                Button(action: {
                                    reportType = type
                                }) {
                                    HStack {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(type.color)
                                        
                                        Text(type.title)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if reportType == type {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(12)
                                    .background(reportType == type ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showReportDialog = false
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Report") {
                                onReport()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showReportDialog = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
        }
        
        private func startReportAnimation() {
            // Trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)) {
                isShaking = true
                shakeOffset = 12
            }
            
            // Show report dialog after shake
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShaking = false
                    shakeOffset = 0
                    showReportDialog = true
                }
            }
        }
    }
    
    // MARK: - Shake to Clear Animation
    
    /// Shake to clear data or reset animation
    public struct ShakeToClearAnimation: View {
        let onClear: () -> Void
        @State private var shakeOffset: CGFloat = 0
        @State private var isShaking: Bool = false
        @State private var showClearConfirmation: Bool = false
        @State private var clearProgress: Double = 0
        
        public init(onClear: @escaping () -> Void) {
            self.onClear = onClear
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Main content
                VStack(spacing: 16) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.red)
                        .scaleEffect(isShaking ? 1.1 : 1.0)
                        .offset(x: shakeOffset)
                        .animation(.easeInOut(duration: 0.1).repeatCount(isShaking ? 10 : 0, autoreverses: true), value: isShaking)
                    
                    Text("Shake to Clear")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Shake your device to clear all data")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .onShake {
                    startClearAnimation()
                }
                
                // Clear confirmation
                if showClearConfirmation {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.orange)
                        
                        Text("Clear All Data?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("This action cannot be undone. All your data will be permanently deleted.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showClearConfirmation = false
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Clear All") {
                                startClearProcess()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Clear progress
                if clearProgress > 0 && clearProgress < 1.0 {
                    VStack(spacing: 12) {
                        ProgressView(value: clearProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .red))
                            .frame(width: 200)
                        
                        Text("Clearing data... \(Int(clearProgress * 100))%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding()
        }
        
        private func startClearAnimation() {
            // Trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1).repeatCount(10, autoreverses: true)) {
                isShaking = true
                shakeOffset = 15
            }
            
            // Show confirmation after shake
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShaking = false
                    shakeOffset = 0
                    showClearConfirmation = true
                }
            }
        }
        
        private func startClearProcess() {
            withAnimation(.easeInOut(duration: 0.3)) {
                showClearConfirmation = false
            }
            
            // Simulate clear process
            withAnimation(.linear(duration: 3.0)) {
                clearProgress = 1.0
            }
            
            onClear()
            
            // Reset after completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    clearProgress = 0
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum ReportType: String, CaseIterable {
    case bug = "Bug"
    case feature = "Feature Request"
    case feedback = "Feedback"
    case crash = "Crash"
    
    var title: String {
        return rawValue
    }
    
    var icon: String {
        switch self {
        case .bug: return "ant.fill"
        case .feature: return "lightbulb.fill"
        case .feedback: return "message.fill"
        case .crash: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .bug: return .red
        case .feature: return .blue
        case .feedback: return .green
        case .crash: return .orange
        }
    }
}

// MARK: - Shake Detection Extension

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetectionModifier(action: action))
    }
}

struct ShakeDetectionModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

// MARK: - Preview

struct ShakeVibrationAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ShakeToUndoAnimation {
                print("Undo action triggered")
            }
            
            ShakeToRefreshAnimation {
                print("Refresh triggered")
            }
            
            ShakeToReportAnimation {
                print("Report triggered")
            }
            
            ShakeToClearAnimation {
                print("Clear triggered")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 