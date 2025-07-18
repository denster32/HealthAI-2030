import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct FocusModeHealthWidget: Widget {
    let kind: String = "FocusModeHealthWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusModeProvider()) { entry in
            FocusModeHealthWidgetView(entry: entry)
        }
        .configurationDisplayName("Health Focus Mode")
        .description("Monitor and control your health-aware focus modes")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@available(iOS 18.0, *)
struct FocusModeProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusModeEntry {
        FocusModeEntry(
            date: Date(),
            activeFocusMode: .workoutMode,
            healthContext: HealthFocusContext(
                heartRate: 75.0,
                currentActivity: "Walking",
                stressLevel: 0.3,
                timeOfDay: 14,
                date: Date()
            ),
            activeRules: [.enhancedHeartRateMonitoring, .allowFitnessApps],
            effectiveness: 0.85
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FocusModeEntry) -> ()) {
        let entry = FocusModeEntry(
            date: Date(),
            activeFocusMode: .meditationMode,
            healthContext: HealthFocusContext(
                heartRate: 68.0,
                currentActivity: "Resting",
                stressLevel: 0.2,
                timeOfDay: 10,
                date: Date()
            ),
            activeRules: [.stressMonitoring, .blockNonEssentialNotifications],
            effectiveness: 0.92
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusModeEntry>) -> ()) {
        Task {
            let currentEntry = await getCurrentFocusModeEntry()
            let timeline = Timeline(entries: [currentEntry], policy: .after(Date().addingTimeInterval(300))) // Update every 5 minutes
            completion(timeline)
        }
    }
    
    private func getCurrentFocusModeEntry() async -> FocusModeEntry {
        let focusModeManager = FocusModeHealthManager.shared
        let activeFocusMode = focusModeManager.activeFocusMode
        
        let healthManager = HealthDataManager.shared
        let heartRate = await healthManager.getLatestHeartRate()
        let currentActivity = await healthManager.getCurrentActivity()
        let stressLevel = await healthManager.getCurrentStressLevel()
        
        let healthContext = HealthFocusContext(
            heartRate: heartRate,
            currentActivity: currentActivity,
            stressLevel: stressLevel,
            timeOfDay: Calendar.current.component(.hour, from: Date()),
            date: Date()
        )
        
        return FocusModeEntry(
            date: Date(),
            activeFocusMode: activeFocusMode,
            healthContext: healthContext,
            activeRules: focusModeManager.healthRules,
            effectiveness: focusModeManager.focusAnalytics.effectivenessRating
        )
    }
}

@available(iOS 18.0, *)
struct FocusModeEntry: TimelineEntry {
    let date: Date
    let activeFocusMode: HealthFocusMode?
    let healthContext: HealthFocusContext
    let activeRules: [HealthFocusRule]
    let effectiveness: Double
}

@available(iOS 18.0, *)
struct FocusModeHealthWidgetView: View {
    var entry: FocusModeProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallFocusModeView(entry: entry)
        case .systemMedium:
            MediumFocusModeView(entry: entry)
        case .systemLarge:
            LargeFocusModeView(entry: entry)
        default:
            SmallFocusModeView(entry: entry)
        }
    }
}

@available(iOS 18.0, *)
struct SmallFocusModeView: View {
    let entry: FocusModeEntry
    
    var body: some View {
        VStack(spacing: 8) {
            if let focusMode = entry.activeFocusMode {
                // Active focus mode display
                VStack(spacing: 4) {
                    Image(systemName: focusMode.iconName)
                        .font(.title2)
                        .foregroundColor(focusMode.color)
                    
                    Text(focusMode.shortName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                // No active focus mode
                VStack(spacing: 4) {
                    Image(systemName: "moon.zzz")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No Focus")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("Tap to activate")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Health indicator
            if let heartRate = entry.healthContext.heartRate {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("\(Int(heartRate))")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

@available(iOS 18.0, *)
struct MediumFocusModeView: View {
    let entry: FocusModeEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Focus mode status
            VStack(alignment: .leading, spacing: 8) {
                if let focusMode = entry.activeFocusMode {
                    HStack(spacing: 8) {
                        Image(systemName: focusMode.iconName)
                            .font(.title2)
                            .foregroundColor(focusMode.color)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(focusMode.shortName)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Effectiveness indicator
                    HStack(spacing: 4) {
                        Text("Effectiveness")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(entry.effectiveness * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(effectivenessColor(entry.effectiveness))
                    }
                    
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "moon.zzz")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text("No Focus Mode")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("Tap to activate health-aware focus")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Right side - Health metrics
            VStack(alignment: .trailing, spacing: 8) {
                if let heartRate = entry.healthContext.heartRate {
                    HealthMetricView(
                        icon: "heart.fill",
                        value: "\(Int(heartRate))",
                        unit: "BPM",
                        color: .red
                    )
                }
                
                if let stressLevel = entry.healthContext.stressLevel {
                    HealthMetricView(
                        icon: "brain.head.profile",
                        value: stressLevelText(stressLevel),
                        unit: "",
                        color: stressColor(stressLevel)
                    )
                }
                
                if let activity = entry.healthContext.currentActivity {
                    HealthMetricView(
                        icon: "figure.walk",
                        value: activity,
                        unit: "",
                        color: .blue
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func effectivenessColor(_ effectiveness: Double) -> Color {
        if effectiveness > 0.8 { return .green }
        if effectiveness > 0.6 { return .orange }
        return .red
    }
    
    private func stressLevelText(_ stress: Double) -> String {
        if stress > 0.7 { return "High" }
        if stress > 0.4 { return "Medium" }
        return "Low"
    }
    
    private func stressColor(_ stress: Double) -> Color {
        if stress > 0.7 { return .red }
        if stress > 0.4 { return .orange }
        return .green
    }
}

@available(iOS 18.0, *)
struct LargeFocusModeView: View {
    let entry: FocusModeEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Focus Mode")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(entry.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let focusMode = entry.activeFocusMode {
                    Image(systemName: focusMode.iconName)
                        .font(.title)
                        .foregroundColor(focusMode.color)
                }
            }
            
            if let focusMode = entry.activeFocusMode {
                // Active focus mode details
                VStack(spacing: 12) {
                    HStack {
                        Text(focusMode.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("Active")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(focusMode.color.opacity(0.2))
                            .foregroundColor(focusMode.color)
                            .clipShape(Capsule())
                    }
                    
                    // Health metrics grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        if let heartRate = entry.healthContext.heartRate {
                            HealthMetricCard(
                                icon: "heart.fill",
                                title: "Heart Rate",
                                value: "\(Int(heartRate))",
                                unit: "BPM",
                                color: .red
                            )
                        }
                        
                        if let stressLevel = entry.healthContext.stressLevel {
                            HealthMetricCard(
                                icon: "brain.head.profile",
                                title: "Stress",
                                value: stressLevelText(stressLevel),
                                unit: "",
                                color: stressColor(stressLevel)
                            )
                        }
                        
                        if let activity = entry.healthContext.currentActivity {
                            HealthMetricCard(
                                icon: "figure.walk",
                                title: "Activity",
                                value: activity,
                                unit: "",
                                color: .blue
                            )
                        }
                        
                        HealthMetricCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Effectiveness",
                            value: "\(Int(entry.effectiveness * 100))",
                            unit: "%",
                            color: effectivenessColor(entry.effectiveness)
                        )
                    }
                    
                    // Active rules summary
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Rules (\(entry.activeRules.count))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(entry.activeRules.prefix(3).enumerated()), id: \.offset) { _, rule in
                                    Text(rule.displayName)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray5))
                                        .clipShape(Capsule())
                                }
                                
                                if entry.activeRules.count > 3 {
                                    Text("+\(entry.activeRules.count - 3)")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(.systemGray4))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                
            } else {
                // No active focus mode
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No Focus Mode Active")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Activate a health-aware focus mode to optimize your experience based on current health metrics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // Quick action buttons
                    HStack(spacing: 12) {
                        FocusModeQuickButton(mode: .workoutMode)
                        FocusModeQuickButton(mode: .sleepMode)
                        FocusModeQuickButton(mode: .meditationMode)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func effectivenessColor(_ effectiveness: Double) -> Color {
        if effectiveness > 0.8 { return .green }
        if effectiveness > 0.6 { return .orange }
        return .red
    }
    
    private func stressLevelText(_ stress: Double) -> String {
        if stress > 0.7 { return "High" }
        if stress > 0.4 { return "Medium" }
        return "Low"
    }
    
    private func stressColor(_ stress: Double) -> Color {
        if stress > 0.7 { return .red }
        if stress > 0.4 { return .orange }
        return .green
    }
}

@available(iOS 18.0, *)
struct HealthMetricView: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

@available(iOS 18.0, *)
struct HealthMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

@available(iOS 18.0, *)
struct FocusModeQuickButton: View {
    let mode: HealthFocusMode
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: mode.iconName)
                .font(.caption)
                .foregroundColor(mode.color)
            Text(mode.shortName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(8)
        .background(mode.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Extensions

@available(iOS 18.0, *)
extension HealthFocusMode {
    var iconName: String {
        switch self {
        case .workoutMode: return "figure.run"
        case .sleepMode: return "moon.zzz"
        case .meditationMode: return "brain.head.profile"
        case .recoveryMode: return "heart.circle"
        case .healthMonitoring: return "cross.circle"
        }
    }
    
    var shortName: String {
        switch self {
        case .workoutMode: return "Workout"
        case .sleepMode: return "Sleep"
        case .meditationMode: return "Meditation"
        case .recoveryMode: return "Recovery"
        case .healthMonitoring: return "Monitoring"
        }
    }
    
    var color: Color {
        switch self {
        case .workoutMode: return .orange
        case .sleepMode: return .indigo
        case .meditationMode: return .green
        case .recoveryMode: return .blue
        case .healthMonitoring: return .red
        }
    }
}

@available(iOS 18.0, *)
extension HealthFocusRule {
    var displayName: String {
        switch self {
        case .allowCriticalHealthAlerts: return "Critical Alerts"
        case .blockNonEssentialNotifications: return "Block Non-Essential"
        case .limitSocialNotifications: return "Limit Social"
        case .prioritizeHealthApps: return "Health Apps Priority"
        case .limitSocialMediaAccess: return "Limit Social Media"
        case .allowFitnessApps: return "Fitness Apps"
        case .enhancedHeartRateMonitoring: return "Enhanced HR"
        case .reducedDataCollection: return "Reduced Data"
        case .stressMonitoring: return "Stress Monitor"
        case .dimDisplayBrightness: return "Dim Display"
        case .reduceAnimations: return "Reduce Motion"
        case .simplifyInterface: return "Simple UI"
        case .intelligentNotificationTiming: return "Smart Timing"
        }
    }
}

// MARK: - Widget Preview

@available(iOS 18.0, *)
struct FocusModeHealthWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Small widget preview
            FocusModeHealthWidgetView(entry: FocusModeEntry(
                date: Date(),
                activeFocusMode: .workoutMode,
                healthContext: HealthFocusContext(
                    heartRate: 85.0,
                    currentActivity: "Running",
                    stressLevel: 0.4,
                    timeOfDay: 15,
                    date: Date()
                ),
                activeRules: [.enhancedHeartRateMonitoring, .allowFitnessApps],
                effectiveness: 0.88
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small - Active")
            
            // Medium widget preview
            FocusModeHealthWidgetView(entry: FocusModeEntry(
                date: Date(),
                activeFocusMode: .meditationMode,
                healthContext: HealthFocusContext(
                    heartRate: 65.0,
                    currentActivity: "Resting",
                    stressLevel: 0.2,
                    timeOfDay: 10,
                    date: Date()
                ),
                activeRules: [.stressMonitoring, .blockNonEssentialNotifications, .simplifyInterface],
                effectiveness: 0.95
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium - Meditation")
            
            // Large widget preview
            FocusModeHealthWidgetView(entry: FocusModeEntry(
                date: Date(),
                activeFocusMode: nil,
                healthContext: HealthFocusContext(
                    heartRate: 72.0,
                    currentActivity: "Walking",
                    stressLevel: 0.3,
                    timeOfDay: 14,
                    date: Date()
                ),
                activeRules: [],
                effectiveness: 0.0
            ))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
            .previewDisplayName("Large - Inactive")
        }
    }
}