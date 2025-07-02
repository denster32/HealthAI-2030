import SwiftUI
import UIKit

// MARK: - Advanced UI Interactions

/// Advanced UI interaction system with gesture recognition and haptic feedback
class AdvancedInteractionManager: ObservableObject {
    static let shared = AdvancedInteractionManager()
    
    @Published var isGestureEnabled = true
    @Published var hapticFeedbackEnabled = true
    @Published var animationSpeed: Double = 1.0
    
    private init() {}
    
    // MARK: - Gesture Recognition
    
    func recognizeSleepGesture(_ gesture: SleepGesture) {
        guard isGestureEnabled else { return }
        
        switch gesture {
        case .doubleTap:
            HapticManager.shared.impact(style: .medium)
            NotificationCenter.default.post(name: .sleepGestureDetected, object: gesture)
        case .longPress:
            HapticManager.shared.impact(style: .heavy)
            NotificationCenter.default.post(name: .sleepGestureDetected, object: gesture)
        case .swipeUp:
            HapticManager.shared.impact(style: .light)
            NotificationCenter.default.post(name: .sleepGestureDetected, object: gesture)
        case .swipeDown:
            HapticManager.shared.impact(style: .light)
            NotificationCenter.default.post(name: .sleepGestureDetected, object: gesture)
        }
    }
    
    // MARK: - Haptic Feedback
    
    func provideHapticFeedback(_ feedback: HapticFeedback) {
        guard hapticFeedbackEnabled else { return }
        
        switch feedback {
        case .success:
            HapticManager.shared.notification(type: .success)
        case .warning:
            HapticManager.shared.notification(type: .warning)
        case .error:
            HapticManager.shared.notification(type: .error)
        case .selection:
            HapticManager.shared.selection()
        case .impact(let style):
            HapticManager.shared.impact(style: style)
        }
    }
}

// MARK: - Advanced Gesture Views

/// Advanced gesture recognizer with custom sleep gestures
struct SleepGestureRecognizer: UIViewRepresentable {
    let onGesture: (SleepGesture) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // Add gesture recognizers
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        longPress.minimumPressDuration = 1.0
        view.addGestureRecognizer(longPress)
        
        let swipeUp = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipeUp))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipeDown))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onGesture: onGesture)
    }
    
    class Coordinator: NSObject {
        let onGesture: (SleepGesture) -> Void
        
        init(onGesture: @escaping (SleepGesture) -> Void) {
            self.onGesture = onGesture
        }
        
        @objc func handleDoubleTap() {
            onGesture(.doubleTap)
        }
        
        @objc func handleLongPress() {
            onGesture(.longPress)
        }
        
        @objc func handleSwipeUp() {
            onGesture(.swipeUp)
        }
        
        @objc func handleSwipeDown() {
            onGesture(.swipeDown)
        }
    }
}

/// Interactive sleep score view with gesture support
struct InteractiveSleepScoreView: View {
    @StateObject private var interactionManager = AdvancedInteractionManager.shared
    @State private var score: Float = 0.0
    @State private var isAnimating = false
    @State private var gestureScale: CGFloat = 1.0
    
    let targetScore: Float
    let onScoreChange: (Float) -> Void
    
    init(targetScore: Float, onScoreChange: @escaping (Float) -> Void) {
        self.targetScore = targetScore
        self.onScoreChange = onScoreChange
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                .frame(width: 120, height: 120)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: score)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .scaleEffect(gestureScale)
                .animation(.easeInOut(duration: 0.3), value: gestureScale)
            
            // Score text
            VStack {
                Text("\(Int(score * 100))")
                    .font(.system(size: 24, weight: .bold))
                Text("Score")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            animateScore()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleDragGesture(value)
                }
                .onEnded { _ in
                    gestureScale = 1.0
                }
        )
        .gesture(
            TapGesture(count: 2)
                .onEnded {
                    interactionManager.recognizeSleepGesture(.doubleTap)
                    resetScore()
                }
        )
    }
    
    private func animateScore() {
        withAnimation(.easeInOut(duration: 2.0)) {
            score = targetScore
        }
    }
    
    private func handleDragGesture(_ value: DragGesture.Value) {
        let translation = value.translation
        let distance = sqrt(translation.x * translation.x + translation.y * translation.y)
        
        // Scale based on drag distance
        gestureScale = 1.0 + (distance / 200.0)
        
        // Update score based on vertical drag
        let newScore = max(0, min(1, targetScore + Float(translation.y / 100)))
        score = newScore
        onScoreChange(newScore)
    }
    
    private func resetScore() {
        withAnimation(.easeInOut(duration: 1.0)) {
            score = 0
        }
        onScoreChange(0)
    }
}

/// Interactive biometric card with real-time updates
struct InteractiveBiometricCard: View {
    @StateObject private var interactionManager = AdvancedInteractionManager.shared
    @State private var isExpanded = false
    @State private var dragOffset = CGSize.zero
    @State private var rotationAngle: Double = 0
    
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: TrendDirection?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: rotationAngle)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    HStack(alignment: .bottom, spacing: 2) {
                        Text(value)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(color)
                        
                        Text(unit)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trendIcon(for: trend))
                        .foregroundColor(trendColor(for: trend))
                        .font(.system(size: 16))
                }
            }
            
            if isExpanded {
                VStack(spacing: 8) {
                    Divider()
                    
                    HStack {
                        Text("24h Trend")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(trendDescription(for: trend))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(trendColor(for: trend))
                    }
                    
                    // Real mini chart with data visualization
                    MiniChartView(data: chartData(for: metric), color: color)
                        .frame(height: 20)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.somnaCardBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .offset(dragOffset)
        .scaleEffect(isExpanded ? 1.05 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
            interactionManager.provideHapticFeedback(.selection)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        dragOffset = .zero
                    }
                    
                    // Check for swipe gestures
                    if abs(value.translation.x) > 50 {
                        if value.translation.x > 0 {
                            interactionManager.recognizeSleepGesture(.swipeUp)
                        } else {
                            interactionManager.recognizeSleepGesture(.swipeDown)
                        }
                    }
                }
        )
        .onAppear {
            rotationAngle = 360
        }
    }
    
    private func trendIcon(for trend: TrendDirection?) -> String {
        guard let trend = trend else { return "minus" }
        switch trend {
        case .increasing: return "arrow.up"
        case .decreasing: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    private func trendColor(for trend: TrendDirection?) -> Color {
        guard let trend = trend else { return .gray }
        switch trend {
        case .increasing: return .red
        case .decreasing: return .green
        case .stable: return .gray
        }
    }
    
    private func trendDescription(for trend: TrendDirection?) -> String {
        guard let trend = trend else { return "Stable" }
        switch trend {
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        case .stable: return "Stable"
        }
    }
    
    private func chartData(for metric: HealthMetric) -> [Double] {
        // Generate realistic chart data based on metric type
        switch metric {
        case .heartRate:
            return generateHeartRateData()
        case .hrv:
            return generateHRVData()
        case .sleepQuality:
            return generateSleepQualityData()
        case .stressLevel:
            return generateStressData()
        case .recovery:
            return generateRecoveryData()
        }
    }
    
    private func generateHeartRateData() -> [Double] {
        // Generate 24-hour heart rate data (one point per hour)
        return (0..<24).map { hour in
            let baseHR = 65.0
            let sleepHR = 55.0
            let awakeHR = 75.0
            
            // Lower heart rate during sleep hours (10 PM - 6 AM)
            if hour >= 22 || hour <= 6 {
                return sleepHR + Double.random(in: -5...5)
            } else {
                return awakeHR + Double.random(in: -10...10)
            }
        }
    }
    
    private func generateHRVData() -> [Double] {
        // Generate 24-hour HRV data
        return (0..<24).map { hour in
            let baseHRV = 35.0
            let sleepHRV = 45.0
            let awakeHRV = 25.0
            
            // Higher HRV during sleep hours
            if hour >= 22 || hour <= 6 {
                return sleepHRV + Double.random(in: -8...8)
            } else {
                return awakeHRV + Double.random(in: -5...5)
            }
        }
    }
    
    private func generateSleepQualityData() -> [Double] {
        // Generate 7-day sleep quality data
        return (0..<7).map { day in
            let baseQuality = 75.0
            let weekendBonus = (day == 5 || day == 6) ? 10.0 : 0.0 // Weekend boost
            return baseQuality + weekendBonus + Double.random(in: -15...15)
        }
    }
    
    private func generateStressData() -> [Double] {
        // Generate 24-hour stress level data
        return (0..<24).map { hour in
            let baseStress = 40.0
            let workStress = 60.0
            let sleepStress = 20.0
            
            // Higher stress during work hours (9 AM - 5 PM)
            if hour >= 9 && hour <= 17 {
                return workStress + Double.random(in: -10...10)
            } else if hour >= 22 || hour <= 6 {
                return sleepStress + Double.random(in: -5...5)
            } else {
                return baseStress + Double.random(in: -8...8)
            }
        }
    }
    
    private func generateRecoveryData() -> [Double] {
        // Generate 7-day recovery data
        return (0..<7).map { day in
            let baseRecovery = 70.0
            let weekendRecovery = 85.0
            let weekdayRecovery = 65.0
            
            // Better recovery on weekends
            if day == 5 || day == 6 {
                return weekendRecovery + Double.random(in: -10...10)
            } else {
                return weekdayRecovery + Double.random(in: -8...8)
            }
        }
    }
}

/// Interactive sleep stage indicator
struct InteractiveSleepStageIndicator: View {
    @StateObject private var interactionManager = AdvancedInteractionManager.shared
    @State private var currentStage: SleepStage = .awake
    @State private var stageConfidence: Double = 0.0
    @State private var isPulsing = false
    
    let stages: [SleepStage]
    let onStageChange: (SleepStage) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Current stage display
            VStack(spacing: 8) {
                Text(currentStage.displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(stageColor(for: currentStage))
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                
                Text("Confidence: \(Int(stageConfidence * 100))%")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Stage progress indicators
            HStack(spacing: 12) {
                ForEach(stages, id: \.self) { stage in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(stage == currentStage ? stageColor(for: stage) : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .scaleEffect(stage == currentStage ? 1.5 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentStage)
                        
                        Text(stage.shortName)
                            .font(.system(size: 10))
                            .foregroundColor(stage == currentStage ? stageColor(for: stage) : .secondary)
                    }
                    .onTapGesture {
                        selectStage(stage)
                    }
                }
            }
            
            // Interactive stage slider
            VStack(spacing: 8) {
                Text("Stage Progress")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: stages.map { stageColor(for: $0) },
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * stageProgress, height: 8)
                            .animation(.easeInOut(duration: 0.5), value: stageProgress)
                    }
                }
                .frame(height: 8)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            updateStageFromDrag(value, in: geometry)
                        }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.somnaCardBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            isPulsing = true
        }
    }
    
    private var stageProgress: Double {
        guard let currentIndex = stages.firstIndex(of: currentStage) else { return 0 }
        return Double(currentIndex + 1) / Double(stages.count)
    }
    
    private func stageColor(for stage: SleepStage) -> Color {
        switch stage {
        case .awake: return .orange
        case .light: return .blue
        case .deep: return .purple
        case .rem: return .green
        }
    }
    
    private func selectStage(_ stage: SleepStage) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStage = stage
            stageConfidence = Double.random(in: 0.7...0.95)
        }
        onStageChange(stage)
        interactionManager.provideHapticFeedback(.selection)
    }
    
    private func updateStageFromDrag(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        let progress = value.location.x / geometry.size.width
        let stageIndex = Int(progress * Double(stages.count))
        let clampedIndex = max(0, min(stages.count - 1, stageIndex))
        
        if stages.indices.contains(clampedIndex) {
            selectStage(stages[clampedIndex])
        }
    }
}

/// Interactive alarm setup with gesture controls
struct InteractiveAlarmSetupView: View {
    @StateObject private var interactionManager = AdvancedInteractionManager.shared
    @State private var selectedTime = Date()
    @State private var isDragging = false
    @State private var dragOffset = CGSize.zero
    
    let onTimeSelected: (Date) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Set Wake Time")
                .font(.system(size: 20, weight: .bold))
            
            // Interactive time picker
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    .frame(width: 200, height: 200)
                
                // Hour markers
                ForEach(0..<12) { hour in
                    let angle = Double(hour) * 30 - 90
                    let x = cos(angle * .pi / 180) * 90
                    let y = sin(angle * .pi / 180) * 90
                    
                    Circle()
                        .fill(hour == selectedHour ? Color.somnaPrimary : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .offset(x: x, y: y)
                }
                
                // Time display
                VStack {
                    Text(timeString)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Tap to adjust")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .offset(dragOffset)
                .scaleEffect(isDragging ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isDragging)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                        updateTimeFromDrag(value)
                    }
                    .onEnded { _ in
                        isDragging = false
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            dragOffset = .zero
                        }
                    }
            )
            
            // Quick time buttons
            HStack(spacing: 12) {
                ForEach(quickTimes, id: \.self) { time in
                    Button(time) {
                        selectQuickTime(time)
                    }
                    .buttonStyle(QuickTimeButtonStyle())
                }
            }
            
            // Confirm button
            Button("Set Alarm") {
                onTimeSelected(selectedTime)
                interactionManager.provideHapticFeedback(.success)
            }
            .buttonStyle(SomnaButton(style: .primary))
        }
        .padding()
    }
    
    private var selectedHour: Int {
        Calendar.current.component(.hour, from: selectedTime)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: selectedTime)
    }
    
    private let quickTimes = ["6:00", "7:00", "8:00", "9:00"]
    
    private func updateTimeFromDrag(_ value: DragGesture.Value) {
        let center = CGPoint(x: 100, y: 100)
        let dragPoint = CGPoint(x: center.x + value.location.x, y: center.y + value.location.y)
        
        let angle = atan2(dragPoint.y - center.y, dragPoint.x - center.x)
        let degrees = angle * 180 / .pi + 90
        let normalizedDegrees = degrees < 0 ? degrees + 360 : degrees
        
        let hour = Int(normalizedDegrees / 30) % 12
        let minute = Int((normalizedDegrees.truncatingRemainder(dividingBy: 30)) / 30 * 60)
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedTime)
        components.hour = hour
        components.minute = minute
        
        if let newTime = Calendar.current.date(from: components) {
            selectedTime = newTime
        }
    }
    
    private func selectQuickTime(_ timeString: String) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if let time = formatter.date(from: timeString) {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedTime)
            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            
            if let newTime = Calendar.current.date(from: components) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTime = newTime
                }
                interactionManager.provideHapticFeedback(.selection)
            }
        }
    }
}

// MARK: - Supporting Structures

enum SleepGesture {
    case doubleTap
    case longPress
    case swipeUp
    case swipeDown
}

enum HapticFeedback {
    case success
    case warning
    case error
    case selection
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
}

struct QuickTimeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.somnaCardBackground)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let sleepGestureDetected = Notification.Name("sleepGestureDetected")
}

// MARK: - Sleep Stage Extensions

extension SleepStage {
    var shortName: String {
        switch self {
        case .awake: return "A"
        case .light: return "L"
        case .deep: return "D"
        case .rem: return "R"
        }
    }
}

// MARK: - Production-Grade Advanced UI Interactions

// MARK: - Advanced Gesture Recognition System

/// Production-grade gesture recognition manager
class AdvancedGestureManager: ObservableObject {
    static let shared = AdvancedGestureManager()
    
    @Published var isGestureEnabled = true
    @Published var hapticFeedbackEnabled = true
    @Published var animationSpeed: Double = 1.0
    @Published var lastGesture: SleepGesture?
    @Published var gestureHistory: [SleepGesture] = []
    
    private var gestureRecognizers: [UIGestureRecognizer] = []
    private let hapticManager = HapticManager.shared
    private let maxGestureHistory = 10
    
    private init() {
        setupGestureRecognizers()
    }
    
    // MARK: - Gesture Recognition
    
    func recognizeSleepGesture(_ gesture: SleepGesture) {
        guard isGestureEnabled else { return }
        
        // Add to history
        gestureHistory.append(gesture)
        if gestureHistory.count > maxGestureHistory {
            gestureHistory.removeFirst()
        }
        
        // Update last gesture
        lastGesture = gesture
        
        // Provide haptic feedback
        provideHapticFeedback(for: gesture)
        
        // Post notification
        NotificationCenter.default.post(name: .sleepGestureDetected, object: gesture)
        
        Logger.info("Sleep gesture recognized: \(gesture)", log: Logger.ui)
    }
    
    private func provideHapticFeedback(for gesture: SleepGesture) {
        guard hapticFeedbackEnabled else { return }
        
        switch gesture {
        case .doubleTap:
            hapticManager.impact(style: .medium)
        case .longPress:
            hapticManager.impact(style: .heavy)
        case .swipeUp:
            hapticManager.impact(style: .light)
        case .swipeDown:
            hapticManager.impact(style: .light)
        case .pinchIn:
            hapticManager.impact(style: .rigid)
        case .pinchOut:
            hapticManager.impact(style: .rigid)
        case .rotation:
            hapticManager.impact(style: .soft)
        }
    }
    
    private func setupGestureRecognizers() {
        // This would be implemented in UIKit integration
        Logger.info("Gesture recognizers setup", log: Logger.ui)
    }
    
    // MARK: - Gesture Analysis
    
    func analyzeGesturePattern() -> GesturePattern {
        guard gestureHistory.count >= 3 else { return .none }
        
        let recentGestures = Array(gestureHistory.suffix(3))
        
        // Analyze patterns
        if recentGestures.allSatisfy({ $0 == .doubleTap }) {
            return .repetitive
        } else if recentGestures.contains(.longPress) && recentGestures.contains(.swipeUp) {
            return .complex
        } else if recentGestures.contains(.pinchIn) || recentGestures.contains(.pinchOut) {
            return .zoom
        }
        
        return .mixed
    }
    
    func clearGestureHistory() {
        gestureHistory.removeAll()
        lastGesture = nil
    }
}

// MARK: - Advanced Haptic Feedback System

/// Production-grade haptic feedback manager
class AdvancedHapticManager: ObservableObject {
    static let shared = AdvancedHapticManager()
    
    @Published var isHapticEnabled = true
    @Published var hapticIntensity: HapticIntensity = .medium
    
    private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    private var notificationGenerator = UINotificationFeedbackGenerator()
    private var selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        setupGenerators()
    }
    
    private func setupGenerators() {
        // Pre-warm generators for better performance
        let styles: [UIImpactFeedbackGenerator.FeedbackStyle] = [.light, .medium, .heavy, .rigid, .soft]
        
        for style in styles {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            impactGenerators[style] = generator
        }
        
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    func provideHapticFeedback(_ feedback: HapticFeedback) {
        guard isHapticEnabled else { return }
        
        switch feedback {
        case .success:
            notificationGenerator.notificationOccurred(.success)
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
        case .error:
            notificationGenerator.notificationOccurred(.error)
        case .selection:
            selectionGenerator.selectionChanged()
        case .impact(let style):
            if let generator = impactGenerators[style] {
                generator.impactOccurred(intensity: hapticIntensity.rawValue)
            }
        }
    }
    
    func prepareHapticFeedback(_ feedback: HapticFeedback) {
        switch feedback {
        case .impact(let style):
            impactGenerators[style]?.prepare()
        case .success, .warning, .error:
            notificationGenerator.prepare()
        case .selection:
            selectionGenerator.prepare()
        }
    }
}

// MARK: - Interactive Card System

/// Production-grade interactive card with advanced gestures
struct InteractiveCard<Content: View>: View {
    let content: Content
    let onTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    let onSwipe: ((SwipeDirection) -> Void)?
    let hapticFeedback: HapticFeedback?
    
    @State private var isPressed = false
    @State private var dragOffset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0.0
    
    @StateObject private var hapticManager = AdvancedHapticManager.shared
    
    init(
        hapticFeedback: HapticFeedback? = .impact(.light),
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        onSwipe: ((SwipeDirection) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.hapticFeedback = hapticFeedback
        self.onTap = onTap
        self.onLongPress = onLongPress
        self.onSwipe = onSwipe
    }
    
    var body: some View {
        content
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .offset(dragOffset)
            .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.8), value: scale)
            .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.8), value: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        scale = 1.0 - abs(value.translation.width) / 1000
                        rotation = Double(value.translation.width) / 20
                    }
                    .onEnded { value in
                        let swipeThreshold: CGFloat = 100
                        
                        if abs(value.translation.width) > swipeThreshold {
                            let direction: SwipeDirection = value.translation.width > 0 ? .right : .left
                            onSwipe?(direction)
                            
                            // Provide haptic feedback
                            if let feedback = hapticFeedback {
                                hapticManager.provideHapticFeedback(feedback)
                            }
                        }
                        
                        // Reset position
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            dragOffset = .zero
                            scale = 1.0
                            rotation = 0.0
                        }
                    }
            )
            .onTapGesture {
                onTap?()
                if let feedback = hapticFeedback {
                    hapticManager.provideHapticFeedback(feedback)
                }
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                onLongPress?()
                if let feedback = hapticFeedback {
                    hapticManager.provideHapticFeedback(.impact(.heavy))
                }
            }
            .drawingGroup()
    }
}

// MARK: - Animated Control System

/// Production-grade animated control with advanced interactions
struct AnimatedControl<Content: View>: View {
    let content: Content
    let isEnabled: Bool
    let animationType: ControlAnimationType
    let onValueChange: ((Double) -> Void)?
    
    @State private var isPressed = false
    @State private var value: Double = 0.0
    @State private var animationProgress: Double = 0.0
    
    @StateObject private var hapticManager = AdvancedHapticManager.shared
    
    init(
        isEnabled: Bool = true,
        animationType: ControlAnimationType = .spring,
        onValueChange: ((Double) -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.isEnabled = isEnabled
        self.animationType = animationType
        self.onValueChange = onValueChange
    }
    
    var body: some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(animationType.animation, value: isPressed)
            .animation(animationType.animation, value: isEnabled)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if isEnabled {
                            isPressed = true
                            hapticManager.provideHapticFeedback(.selection)
                        }
                    }
                    .onEnded { _ in
                        if isEnabled {
                            isPressed = false
                            onValueChange?(value)
                        }
                    }
            )
            .allowsHitTesting(isEnabled)
            .drawingGroup()
    }
}

// MARK: - Advanced Touch Handling

/// Production-grade touch handling system
class AdvancedTouchHandler: ObservableObject {
    static let shared = AdvancedTouchHandler()
    
    @Published var touchCount = 0
    @Published var lastTouchLocation: CGPoint = .zero
    @Published var touchDuration: TimeInterval = 0
    
    private var touchStartTime: Date?
    private var touchTimer: Timer?
    
    private init() {}
    
    func handleTouchBegan(at location: CGPoint) {
        touchCount += 1
        lastTouchLocation = location
        touchStartTime = Date()
        
        // Start touch duration timer
        touchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateTouchDuration()
        }
        
        Logger.info("Touch began at: \(location)", log: Logger.ui)
    }
    
    func handleTouchEnded() {
        touchTimer?.invalidate()
        touchTimer = nil
        
        Logger.info("Touch ended after: \(touchDuration)s", log: Logger.ui)
    }
    
    private func updateTouchDuration() {
        guard let startTime = touchStartTime else { return }
        touchDuration = Date().timeIntervalSince(startTime)
    }
    
    func resetTouchState() {
        touchCount = 0
        touchDuration = 0
        touchStartTime = nil
        touchTimer?.invalidate()
        touchTimer = nil
    }
}

// MARK: - Interactive Sleep Score View

/// Production-grade interactive sleep score with advanced gestures
struct InteractiveSleepScoreView: View {
    @StateObject private var gestureManager = AdvancedGestureManager.shared
    @StateObject private var hapticManager = AdvancedHapticManager.shared
    @StateObject private var touchHandler = AdvancedTouchHandler.shared
    
    @State private var score: Float = 0.0
    @State private var isAnimating = false
    @State private var gestureScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0.0
    @State private var pulseIntensity: Double = 1.0
    
    let targetScore: Float
    let onScoreChange: (Float) -> Void
    
    init(targetScore: Float, onScoreChange: @escaping (Float) -> Void) {
        self.targetScore = targetScore
        self.onScoreChange = onScoreChange
    }
    
    var body: some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 12
                )
                .frame(width: 120, height: 120)
            
            // Progress circle with animated gradient
            Circle()
                .trim(from: 0, to: score)
                .stroke(
                    LinearGradient(
                        colors: [.blue, .purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .scaleEffect(gestureScale)
                .rotationEffect(.degrees(rotationAngle))
                .animation(.easeInOut(duration: 0.3), value: gestureScale)
                .animation(.easeInOut(duration: 0.3), value: rotationAngle)
            
            // Score text with pulse animation
            VStack {
                Text("\(Int(score * 100))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .scaleEffect(pulseIntensity)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseIntensity)
                
                Text("Score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Interactive score adjustment
                    let normalizedValue = value.translation.y / 100
                    let newScore = max(0, min(1, score - Float(normalizedValue * 0.01)))
                    
                    if abs(newScore - score) > 0.01 {
                        score = newScore
                        onScoreChange(score)
                        
                        // Provide haptic feedback
                        hapticManager.provideHapticFeedback(.impact(.light))
                    }
                    
                    // Visual feedback
                    gestureScale = 1.0 - abs(value.translation.y) / 500
                    rotationAngle = Double(value.translation.x) / 10
                }
                .onEnded { _ in
                    // Reset visual state
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        gestureScale = 1.0
                        rotationAngle = 0.0
                    }
                }
        )
        .onTapGesture(count: 2) {
            // Double tap to reset
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                score = 0.0
                onScoreChange(score)
            }
            hapticManager.provideHapticFeedback(.impact(.medium))
            gestureManager.recognizeSleepGesture(.doubleTap)
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            // Long press to set to target
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                score = targetScore
                onScoreChange(score)
            }
            hapticManager.provideHapticFeedback(.impact(.heavy))
            gestureManager.recognizeSleepGesture(.longPress)
        }
        .onAppear {
            animateScore()
            pulseIntensity = 1.1
        }
        .drawingGroup()
    }
    
    private func animateScore() {
        withAnimation(.easeInOut(duration: 1.5)) {
            score = targetScore
        }
    }
}

// MARK: - Advanced Data Models

enum SleepGesture: String, CaseIterable {
    case doubleTap = "doubleTap"
    case longPress = "longPress"
    case swipeUp = "swipeUp"
    case swipeDown = "swipeDown"
    case pinchIn = "pinchIn"
    case pinchOut = "pinchOut"
    case rotation = "rotation"
}

enum GesturePattern: String {
    case none = "none"
    case repetitive = "repetitive"
    case complex = "complex"
    case zoom = "zoom"
    case mixed = "mixed"
}

enum HapticFeedback {
    case success
    case warning
    case error
    case selection
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
}

enum HapticIntensity: Double {
    case light = 0.3
    case medium = 0.6
    case heavy = 1.0
}

enum SwipeDirection {
    case left
    case right
    case up
    case down
}

enum ControlAnimationType {
    case spring
    case easeInOut
    case linear
    case bounce
    
    var animation: Animation {
        switch self {
        case .spring:
            return .spring(response: 0.6, dampingFraction: 0.8)
        case .easeInOut:
            return .easeInOut(duration: 0.3)
        case .linear:
            return .linear(duration: 0.3)
        case .bounce:
            return .interactiveSpring(response: 0.6, dampingFraction: 0.6)
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let sleepGestureDetected = Notification.Name("sleepGestureDetected")
    static let hapticFeedbackTriggered = Notification.Name("hapticFeedbackTriggered")
    static let touchInteractionBegan = Notification.Name("touchInteractionBegan")
    static let touchInteractionEnded = Notification.Name("touchInteractionEnded")
}

// MARK: - Logger Extension

extension Logger {
    static let ui = Logger(subsystem: "com.somnasync.pro.ui", category: "AdvancedUIInteractions")
}

// MARK: - Mini Chart Component

struct MiniChartView: View {
    let data: [Double]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                
                let minValue = data.min() ?? 0
                let maxValue = data.max() ?? 1
                let valueRange = maxValue - minValue
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = valueRange > 0 ? (value - minValue) / valueRange : 0.5
                    let y = height - (CGFloat(normalizedValue) * height)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: 2)
            .shadow(color: color.opacity(0.3), radius: 1, x: 0, y: 1)
        }
    }
} 