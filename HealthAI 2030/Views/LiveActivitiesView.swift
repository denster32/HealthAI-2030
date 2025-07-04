import SwiftUI
import ActivityKit
import HealthKit

// MARK: - Live Activity Models

struct HealthMonitoringAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var heartRate: Double
        var oxygenSaturation: Double
        var stressLevel: String
        var sleepQuality: Double
        var steps: Int
        var caloriesBurned: Int
        var lastUpdated: Date
    }
    
    var activityType: String
    var userID: String
}

// MARK: - Live Activity Manager

@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published var currentActivity: Activity<HealthMonitoringAttributes>?
    @Published var isActivityActive = false
    
    private let healthStore = HKHealthStore()
    private var updateTimer: Timer?
    
    private init() {
        setupHealthMonitoring()
    }
    
    // MARK: - Activity Management
    
    func startHealthMonitoring() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        let attributes = HealthMonitoringAttributes(
            activityType: "health_monitoring",
            userID: "user_123"
        )
        
        let contentState = HealthMonitoringAttributes.ContentState(
            heartRate: 0.0,
            oxygenSaturation: 0.0,
            stressLevel: "Unknown",
            sleepQuality: 0.0,
            steps: 0,
            caloriesBurned: 0,
            lastUpdated: Date()
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
            
            currentActivity = activity
            isActivityActive = true
            
            // Start real-time updates
            startRealTimeUpdates()
            
            print("Health monitoring Live Activity started")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func stopHealthMonitoring() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
            isActivityActive = false
            
            // Stop real-time updates
            stopRealTimeUpdates()
            
            print("Health monitoring Live Activity stopped")
        }
    }
    
    func updateHealthData() async {
        guard let activity = currentActivity else { return }
        
        let healthData = await fetchCurrentHealthData()
        
        let contentState = HealthMonitoringAttributes.ContentState(
            heartRate: healthData.heartRate,
            oxygenSaturation: healthData.oxygenSaturation,
            stressLevel: healthData.stressLevel,
            sleepQuality: healthData.sleepQuality,
            steps: healthData.steps,
            caloriesBurned: healthData.caloriesBurned,
            lastUpdated: Date()
        )
        
        await activity.update(using: contentState)
    }
    
    // MARK: - Health Data Fetching
    
    private func fetchCurrentHealthData() async -> (heartRate: Double, oxygenSaturation: Double, stressLevel: String, sleepQuality: Double, steps: Int, caloriesBurned: Int) {
        let heartRate = AdvancedCardiacManager.shared.heartRateData.first?.value ?? 0.0
        let oxygenSaturation = RespiratoryHealthManager.shared.oxygenSaturation
        let stressLevel = MentalHealthManager.shared.stressLevel.displayName
        let sleepQuality = SleepOptimizationManager.shared.sleepQuality
        // Simulate fetching steps and calories burned
        let steps = Int.random(in: 1000...10000)
        let caloriesBurned = Int.random(in: 200...2000)
        
        return (heartRate, oxygenSaturation, stressLevel, sleepQuality, steps, caloriesBurned)
    }
    
    // MARK: - Real-time Updates
    
    private func startRealTimeUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.updateHealthData()
            }
        }
    }
    
    private func stopRealTimeUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - Health Monitoring Setup
    
    private func setupHealthMonitoring() {
        // Request HealthKit permissions for Live Activity data
        var healthTypes: Set<HKObjectType> = []
        
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            healthTypes.insert(heartRateType)
        }
        if let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
            healthTypes.insert(oxygenType)
        }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            healthTypes.insert(sleepType)
        }
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            healthTypes.insert(stepType)
        }
        if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            healthTypes.insert(energyType)
        }
        
        healthStore.requestAuthorization(toShare: nil, read: healthTypes) { success, error in
            if success {
                print("HealthKit permissions granted for Live Activities")
            } else {
                print("HealthKit permissions denied for Live Activities: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

// MARK: - Live Activity Views

struct HealthMonitoringLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HealthMonitoringAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIslandLiveActivityView(context: context)
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<HealthMonitoringAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Health Monitoring")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(timeAgoString(from: context.state.lastUpdated))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                HealthMetricView(
                    title: "Heart Rate",
                    value: "\(Int(context.state.heartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                HealthMetricView(
                    title: "Oxygen",
                    value: "\(String(format: "%.1f", context.state.oxygenSaturation))",
                    unit: "%",
                    icon: "lungs.fill",
                    color: .blue
                )
                
                HealthMetricView(
                    title: "Steps",
                    value: "\(context.state.steps)",
                    unit: "",
                    icon: "figure.walk",
                    color: .green
                )
            }
            
            HStack(spacing: 20) {
                HealthMetricView(
                    title: "Stress",
                    value: context.state.stressLevel,
                    unit: "",
                    icon: "brain.head.profile",
                    color: stressColor
                )
                
                HealthMetricView(
                    title: "Calories",
                    value: "\(context.state.caloriesBurned)",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange
                )
                
                HealthMetricView(
                    title: "Sleep Quality",
                    value: "\(Int(context.state.sleepQuality * 100))%",
                    unit: "",
                    icon: "moon.fill",
                    color: .indigo
                )
            }
            
            HStack {
                Spacer()
                Button("Stop Monitoring") {
                    LiveActivityManager.shared.stopHealthMonitoring()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var stressColor: Color {
        switch context.state.stressLevel {
        case "Low": return .green
        case "Moderate": return .yellow
        case "High": return .orange
        case "Severe": return .red
        default: return .gray
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}

struct DynamicIslandLiveActivityView: View {
    let context: ActivityViewContext<HealthMonitoringAttributes>
    
    var body: some View {
        DynamicIsland {
            // Expanded UI
            DynamicIslandExpandedRegion(.leading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heart Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(context.state.heartRate))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("BPM")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            DynamicIslandExpandedRegion(.trailing) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Oxygen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", context.state.oxygenSaturation))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            DynamicIslandExpandedRegion(.bottom) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stress Level")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(context.state.stressLevel)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(stressColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Steps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(context.state.steps)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(context.state.caloriesBurned)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
        } compactLeading: {
            // Compact leading
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
        } compactTrailing: {
            // Compact trailing
            Text("\(Int(context.state.heartRate))")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.red)
        } minimal: {
            // Minimal
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
        }
    }
    
    private var stressColor: Color {
        switch context.state.stressLevel {
        case "Low": return .green
        case "Moderate": return .yellow
        case "High": return .orange
        case "Severe": return .red
        default: return .gray
        }
    }
}

// MARK: - Supporting Views

struct HealthMetricView: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Live Activity Control View

struct LiveActivityControlView: View {
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Live Activity Control")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Health Monitoring")
                    Spacer()
                    Text(liveActivityManager.isActivityActive ? "Active" : "Inactive")
                        .font(.caption)
                        .foregroundColor(liveActivityManager.isActivityActive ? .green : .secondary)
                }
                
                Text("Real-time health monitoring with Live Activities and Dynamic Island integration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if liveActivityManager.isActivityActive {
                VStack(spacing: 12) {
                    Button("Update Health Data") {
                        Task {
                            await liveActivityManager.updateHealthData()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Stop Monitoring") {
                        liveActivityManager.stopHealthMonitoring()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            } else {
                Button("Start Monitoring") {
                    liveActivityManager.startHealthMonitoring()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Live Activities")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Extensions

extension StressLevel {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .severe: return "Severe"
        }
    }
}

// MARK: - Widget Bundle

@main
struct HealthAI2030LiveActivityBundle: WidgetBundle {
    var body: some Widget {
        HealthMonitoringLiveActivity()
    }
} 