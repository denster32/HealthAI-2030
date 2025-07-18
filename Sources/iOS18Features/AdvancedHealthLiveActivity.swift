import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Enhanced Health Activity Attributes

@available(iOS 18.0, *)
struct AdvancedHealthActivityAttributes: ActivityAttributes {
    public typealias ContentState = AdvancedHealthActivityContentState
    
    public struct ContentState: Codable, Hashable {
        // Real-time health metrics
        var heartRate: Int?
        var steps: Int
        var caloriesBurned: Int
        var waterIntake: Int // in ounces
        var activeWorkout: WorkoutInfo?
        var healthScore: Int
        var lastUpdated: Date
        
        // Activity status
        var isWorkoutActive: Bool
        var isMeditationActive: Bool
        var currentFocusMode: String?
        
        // Goals and progress
        var stepGoal: Int
        var waterGoal: Int
        var stepProgress: Double // 0.0 to 1.0
        var waterProgress: Double // 0.0 to 1.0
        
        // Health alerts
        var hasActiveAlert: Bool
        var alertMessage: String?
        var alertPriority: AlertPriority
    }
    
    // Static data for the activity
    var activityType: HealthActivityType
    var userName: String
    var startTime: Date
}

@available(iOS 18.0, *)
struct WorkoutInfo: Codable, Hashable {
    let type: String
    let duration: TimeInterval
    let intensity: String
    let estimatedCalories: Int?
}

@available(iOS 18.0, *)
enum HealthActivityType: String, Codable {
    case dailyTracking = "Daily Health Tracking"
    case workoutSession = "Workout Session"
    case meditationSession = "Meditation Session"
    case healthMonitoring = "Health Monitoring"
    case recoveryMode = "Recovery Mode"
}

@available(iOS 18.0, *)
enum AlertPriority: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - Advanced Health Live Activity Widget

@available(iOS 18.0, *)
struct AdvancedHealthLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AdvancedHealthActivityAttributes.self) { context in
            // MARK: - Lock Screen Live Activity View
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(backgroundTint(for: context.attributes.activityType))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Dynamic Island Expanded View
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                // MARK: - Compact Leading View
                CompactLeadingView(context: context)
            } compactTrailing: {
                // MARK: - Compact Trailing View
                CompactTrailingView(context: context)
            } minimal: {
                // MARK: - Minimal View
                MinimalView(context: context)
            }
            .widgetURL(URL(string: "healthai2030://liveactivity/\(context.attributes.activityType.rawValue)"))
            .keylineTint(keylineTint(for: context.attributes.activityType))
        }
    }
    
    private func backgroundTint(for activityType: HealthActivityType) -> Color {
        switch activityType {
        case .dailyTracking: return .blue
        case .workoutSession: return .orange
        case .meditationSession: return .green
        case .healthMonitoring: return .red
        case .recoveryMode: return .purple
        }
    }
    
    private func keylineTint(for activityType: HealthActivityType) -> Color {
        switch activityType {
        case .dailyTracking: return .blue
        case .workoutSession: return .orange
        case .meditationSession: return .green
        case .healthMonitoring: return .red
        case .recoveryMode: return .purple
        }
    }
}

// MARK: - Lock Screen Live Activity View

@available(iOS 18.0, *)
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<AdvancedHealthActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with activity type and time
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.activityType.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Started \(timeAgo(from: context.attributes.startTime))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Activity icon
                Image(systemName: iconName(for: context.attributes.activityType))
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Main content based on activity type
            switch context.attributes.activityType {
            case .dailyTracking:
                DailyTrackingContent(state: context.state)
            case .workoutSession:
                WorkoutSessionContent(state: context.state)
            case .meditationSession:
                MeditationSessionContent(state: context.state)
            case .healthMonitoring:
                HealthMonitoringContent(state: context.state)
            case .recoveryMode:
                RecoveryModeContent(state: context.state)
            }
            
            // Alert banner if present
            if context.state.hasActiveAlert, let alertMessage = context.state.alertMessage {
                AlertBanner(message: alertMessage, priority: context.state.alertPriority)
            }
            
            // Last updated timestamp
            HStack {
                Spacer()
                Text("Updated \(context.state.lastUpdated, style: .time)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
    }
    
    private func iconName(for activityType: HealthActivityType) -> String {
        switch activityType {
        case .dailyTracking: return "heart.text.square.fill"
        case .workoutSession: return "figure.run"
        case .meditationSession: return "brain.head.profile"
        case .healthMonitoring: return "cross.circle.fill"
        case .recoveryMode: return "bed.double.circle.fill"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m ago"
        } else {
            return "\(minutes)m ago"
        }
    }
}

// MARK: - Content Views for Different Activity Types

@available(iOS 18.0, *)
struct DailyTrackingContent: View {
    let state: AdvancedHealthActivityAttributes.ContentState
    
    var body: some View {
        HStack(spacing: 16) {
            // Steps progress
            VStack(spacing: 4) {
                CircularProgressView(
                    progress: state.stepProgress,
                    color: .blue,
                    lineWidth: 6
                ) {
                    VStack(spacing: 2) {
                        Text("\(state.steps)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("steps")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(width: 80, height: 80)
                
                Text("\(Int(state.stepProgress * 100))% of goal")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Health metrics
            VStack(spacing: 8) {
                if let heartRate = state.heartRate {
                    HealthMetricRow(
                        icon: "heart.fill",
                        value: "\(heartRate)",
                        unit: "BPM",
                        color: .red
                    )
                }
                
                HealthMetricRow(
                    icon: "flame.fill",
                    value: "\(state.caloriesBurned)",
                    unit: "cal",
                    color: .orange
                )
                
                HealthMetricRow(
                    icon: "drop.fill",
                    value: "\(state.waterIntake)",
                    unit: "oz",
                    color: .blue
                )
                
                HealthMetricRow(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(state.healthScore)",
                    unit: "/100",
                    color: .green
                )
            }
        }
    }
}

@available(iOS 18.0, *)
struct WorkoutSessionContent: View {
    let state: AdvancedHealthActivityAttributes.ContentState
    
    var body: some View {
        VStack(spacing: 12) {
            if let workout = state.activeWorkout {
                // Workout header
                HStack {
                    Image(systemName: workoutIcon(for: workout.type))
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.type.capitalized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(formatDuration(workout.duration))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                // Workout metrics
                HStack(spacing: 20) {
                    if let heartRate = state.heartRate {
                        WorkoutMetric(
                            icon: "heart.fill",
                            value: "\(heartRate)",
                            unit: "BPM",
                            color: .red
                        )
                    }
                    
                    WorkoutMetric(
                        icon: "flame.fill",
                        value: "\(state.caloriesBurned)",
                        unit: "cal",
                        color: .orange
                    )
                    
                    if let estimatedCal = workout.estimatedCalories {
                        WorkoutMetric(
                            icon: "target",
                            value: "\(estimatedCal)",
                            unit: "target",
                            color: .green
                        )
                    }
                }
            }
        }
    }
    
    private func workoutIcon(for type: String) -> String {
        switch type.lowercased() {
        case "running": return "figure.run"
        case "walking": return "figure.walk"
        case "cycling": return "bicycle"
        case "swimming": return "figure.pool.swim"
        case "yoga": return "figure.yoga"
        default: return "figure.strengthtraining.traditional"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

@available(iOS 18.0, *)
struct MeditationSessionContent: View {
    let state: AdvancedHealthActivityAttributes.ContentState
    
    var body: some View {
        VStack(spacing: 12) {
            // Meditation progress (assuming we have session duration in workout info)
            if let session = state.activeWorkout {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Meditation Session")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(formatDuration(session.duration))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                // Breathing indicator or heart rate
                if let heartRate = state.heartRate {
                    HStack {
                        Text("Heart Rate")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("\(heartRate) BPM")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

@available(iOS 18.0, *)
struct HealthMonitoringContent: View {
    let state: AdvancedHealthActivityAttributes.ContentState
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Health Monitoring Active")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                if let heartRate = state.heartRate {
                    MonitoringMetric(
                        icon: "heart.fill",
                        value: "\(heartRate)",
                        label: "Heart Rate",
                        color: .red
                    )
                }
                
                MonitoringMetric(
                    icon: "chart.line.uptrend.xyaxis",
                    value: "\(state.healthScore)",
                    label: "Health Score",
                    color: .green
                )
                
                if let focusMode = state.currentFocusMode {
                    MonitoringMetric(
                        icon: "moon.circle.fill",
                        value: focusMode,
                        label: "Focus Mode",
                        color: .purple
                    )
                }
            }
        }
    }
}

@available(iOS 18.0, *)
struct RecoveryModeContent: View {
    let state: AdvancedHealthActivityAttributes.ContentState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "bed.double.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("Recovery Mode")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text("Optimizing for rest and recovery")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            if let heartRate = state.heartRate {
                HStack {
                    Text("Resting Heart Rate")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("\(heartRate) BPM")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// MARK: - Dynamic Island Views

@available(iOS 18.0, *)
struct ExpandedLeadingView: View {
    let context: ActivityViewContext<AdvancedHealthActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: iconName(for: context.attributes.activityType))
                .font(.title2)
                .foregroundColor(color(for: context.attributes.activityType))
            
            Text(context.attributes.activityType.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
        }
    }
    
    private func iconName(for activityType: HealthActivityType) -> String {
        switch activityType {
        case .dailyTracking: return "heart.text.square.fill"
        case .workoutSession: return "figure.run"
        case .meditationSession: return "brain.head.profile"
        case .healthMonitoring: return "cross.circle.fill"
        case .recoveryMode: return "bed.double.circle.fill"
        }
    }
    
    private func color(for activityType: HealthActivityType) -> Color {
        switch activityType {
        case .dailyTracking: return .blue
        case .workoutSession: return .orange
        case .meditationSession: return .green
        case .healthMonitoring: return .red
        case .recoveryMode: return .purple
        }
    }
}

@available(iOS 18.0, *)
struct ExpandedTrailingView: View {
    let context: ActivityViewContext<AdvancedHealthActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if let heartRate = context.state.heartRate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(heartRate)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("BPM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(context.state.steps)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                Text("steps")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

@available(iOS 18.0, *)
struct ExpandedCenterView: View {
    let context: ActivityViewContext<AdvancedHealthActivityAttributes>
    
    var body: some View {
        if context.state.hasActiveAlert, let alertMessage = context.state.alertMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(context.state.alertPriority.color)
                
                Text(alertMessage)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
        } else {
            HStack(spacing: 12) {
                ProgressIndicator(
                    progress: context.state.stepProgress,
                    color: .blue,
                    size: 30
                )
                
                ProgressIndicator(
                    progress: context.state.waterProgress,
                    color: .cyan,
                    size: 30
                )
                
                VStack(spacing: 2) {
                    Text("\(context.state.healthScore)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

@available(iOS 18.0, *)
struct ExpandedBottomView: View {
    let context: ActivityViewContext<AdvancedHealthActivityAttributes>
    
    var body: some View {
        HStack {
            // Quick action buttons based on activity type
            switch context.attributes.activityType {
            case .workoutSession:
                QuickActionButton(title: "Pause", icon: "pause.fill", color: .orange)
                Spacer()
                QuickActionButton(title: "Stop", icon: "stop.fill", color: .red)
                
            case .meditationSession:
                QuickActionButton(title: "Pause", icon: "pause.fill", color: .green)
                Spacer()
                QuickActionButton(title: "End", icon: "checkmark.circle.fill", color: .blue)
                
            default:
                Text("Updated \(context.state.lastUpdated, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                QuickActionButton(title: "View", icon: "arrow.up.right", color: .blue)
            }
        }
    }
}

@available(iOS 18.0, *)
struct CompactLeadingView: View {
    let context: ActivityViewContext<AdvancedHealthActivityAttributes>
    
    var body: some View {
        Image(systemName: iconName(for: context.attributes.activityType))
            .font(.body)
            .foregroundColor(color(for: context.attributes.activityType))
    }
    
    private func iconName(for activityType: HealthActivityType) -> String {
        switch activityType {
        case .dailyTracking: return "heart.fill"
        case .workoutSession: return "figure.run"
        case .meditationSession: return "brain.head.profile"
        case .healthMonitoring: return "cross.circle.fill"
        case .recoveryMode: return "bed.double.circle.fill"
        }
    }
    
    private func color(for activityType: HealthActivityType) -> Color {
        switch activityType {
        case .dailyTracking: return .blue
        case .workoutSession: return .orange
        case .meditationSession: return .green
        case .healthMonitoring: return .red
        case .recoveryMode: return .purple
        }
    }
}

@available(iOS 18.0, *)
struct CompactTrailingView: View {
    let context: ActivityViewContext<AdvancedHealthActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            if let heartRate = context.state.heartRate {
                Text("\(heartRate)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            } else {
                Text("\(context.state.steps)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
    }
}

@available(iOS 18.0, *)
struct MinimalView: View {
    let context: ActivityViewContext<AdvancedHealthActivityAttributes>
    
    var body: some View {
        if context.state.hasActiveAlert {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(context.state.alertPriority.color)
        } else {
            Image(systemName: iconName(for: context.attributes.activityType))
                .font(.caption)
                .foregroundColor(color(for: context.attributes.activityType))
        }
    }
    
    private func iconName(for activityType: HealthActivityType) -> String {
        switch activityType {
        case .dailyTracking: return "heart.fill"
        case .workoutSession: return "figure.run"
        case .meditationSession: return "brain.head.profile"
        case .healthMonitoring: return "cross.circle.fill"
        case .recoveryMode: return "bed.double.circle.fill"
        }
    }
    
    private func color(for activityType: HealthActivityType) -> Color {
        switch activityType {
        case .dailyTracking: return .blue
        case .workoutSession: return .orange
        case .meditationSession: return .green
        case .healthMonitoring: return .red
        case .recoveryMode: return .purple
        }
    }
}

// MARK: - Supporting Views

@available(iOS 18.0, *)
struct HealthMetricRow: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
    }
}

@available(iOS 18.0, *)
struct WorkoutMetric: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(spacing: 1) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

@available(iOS 18.0, *)
struct MonitoringMetric: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
            
            VStack(spacing: 1) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

@available(iOS 18.0, *)
struct AlertBanner: View {
    let message: String
    let priority: AlertPriority
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(priority.color)
            
            Text(message)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(priority.color.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(priority.color.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

@available(iOS 18.0, *)
struct CircularProgressView<Content: View>: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let content: () -> Content
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            content()
        }
    }
}

@available(iOS 18.0, *)
struct ProgressIndicator: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 3)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
        }
    }
}

@available(iOS 18.0, *)
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Action would be handled by the main app
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
        }
    }
}

// MARK: - Widget Preview

@available(iOS 18.0, *)
struct AdvancedHealthLiveActivity_Previews: PreviewProvider {
    static let attributes = AdvancedHealthActivityAttributes(
        activityType: .workoutSession,
        userName: "John Doe",
        startTime: Date().addingTimeInterval(-1800) // 30 minutes ago
    )
    
    static let contentState = AdvancedHealthActivityAttributes.ContentState(
        heartRate: 145,
        steps: 8750,
        caloriesBurned: 420,
        waterIntake: 32,
        activeWorkout: WorkoutInfo(
            type: "Running",
            duration: 1800, // 30 minutes
            intensity: "Vigorous",
            estimatedCalories: 450
        ),
        healthScore: 85,
        lastUpdated: Date(),
        isWorkoutActive: true,
        isMeditationActive: false,
        currentFocusMode: "Workout Mode",
        stepGoal: 10000,
        waterGoal: 64,
        stepProgress: 0.875,
        waterProgress: 0.5,
        hasActiveAlert: false,
        alertMessage: nil,
        alertPriority: .low
    )
    
    static var previews: some View {
        Group {
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.compact))
                .previewDisplayName("Dynamic Island Compact")
            
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
                .previewDisplayName("Dynamic Island Expanded")
            
            attributes
                .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
                .previewDisplayName("Dynamic Island Minimal")
            
            attributes
                .previewContext(contentState, viewKind: .content)
                .previewDisplayName("Lock Screen")
        }
    }
}