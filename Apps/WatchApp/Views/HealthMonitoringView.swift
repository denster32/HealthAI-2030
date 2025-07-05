import SwiftUI
import HealthKit
import WatchKit

struct HealthMonitoringView: View {
    @StateObject private var healthManager = WatchHealthManager()
    @State private var selectedMetric: HealthMetric = .heartRate
    @State private var showingQuickAction = false
    
    enum HealthMetric: String, CaseIterable {
        case heartRate = "Heart Rate"
        case steps = "Steps"
        case calories = "Calories"
        case sleep = "Sleep"
        case activity = "Activity"
        case respiratory = "Respiratory"
        
        var icon: String {
            switch self {
            case .heartRate: return "heart.fill"
            case .steps: return "figure.walk"
            case .calories: return "flame.fill"
            case .sleep: return "bed.double.fill"
            case .activity: return "figure.run"
            case .respiratory: return "lungs.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .heartRate: return .red
            case .steps: return .green
            case .calories: return .orange
            case .sleep: return .blue
            case .activity: return .purple
            case .respiratory: return .cyan
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Current Metric Display
                CurrentMetricCard(metric: selectedMetric, value: healthManager.currentValue)
                
                // Quick Actions
                QuickActionsView(healthManager: healthManager)
                
                // Metric Selector
                MetricSelectorView(selectedMetric: $selectedMetric)
                
                // Health Insights
                if let insight = healthManager.currentInsight {
                    HealthInsightCard(insight: insight)
                }
                
                // Emergency Contact
                EmergencyContactButton()
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Health Monitor")
        .onAppear {
            healthManager.startMonitoring()
        }
        .onDisappear {
            healthManager.stopMonitoring()
        }
    }
}

struct CurrentMetricCard: View {
    let metric: HealthMonitoringView.HealthMetric
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundColor(metric.color)
                    .font(.title2)
                
                Spacer()
                
                Text(metric.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // Trend indicator
            HStack {
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
                    .font(.caption)
                Text("+5%")
                    .font(.caption2)
                    .foregroundColor(.green)
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickActionsView: View {
    @ObservedObject var healthManager: WatchHealthManager
    @State private var showingWorkout = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                QuickActionButton(
                    title: "Start Workout",
                    icon: "figure.run",
                    color: .green
                ) {
                    showingWorkout = true
                }
                
                QuickActionButton(
                    title: "Log Water",
                    icon: "drop.fill",
                    color: .blue
                ) {
                    healthManager.logWaterIntake()
                }
                
                QuickActionButton(
                    title: "Meditation",
                    icon: "brain.head.profile",
                    color: .purple
                ) {
                    healthManager.startMeditation()
                }
                
                QuickActionButton(
                    title: "Emergency",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                ) {
                    healthManager.triggerEmergency()
                }
            }
        }
        .sheet(isPresented: $showingWorkout) {
            WorkoutSelectionView()
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MetricSelectorView: View {
    @Binding var selectedMetric: HealthMonitoringView.HealthMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Metrics")
                .font(.headline)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(HealthMonitoringView.HealthMetric.allCases, id: \.self) { metric in
                        MetricButton(
                            metric: metric,
                            isSelected: selectedMetric == metric
                        ) {
                            selectedMetric = metric
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct MetricButton: View {
    let metric: HealthMonitoringView.HealthMetric
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: metric.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : metric.color)
                
                Text(metric.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 60, height: 50)
            .background(isSelected ? metric.color : Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HealthInsightCard: View {
    let insight: HealthInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Health Insight")
                    .font(.headline)
                Spacer()
            }
            
            Text(insight.message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let recommendation = insight.recommendation {
                Text("💡 \(recommendation)")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmergencyContactButton: View {
    var body: some View {
        Button(action: {
            // Emergency contact action
        }) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.white)
                Text("Emergency Contact")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.red)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    let workoutTypes = [
        ("Running", "figure.run", Color.green),
        ("Walking", "figure.walk", Color.blue),
        ("Cycling", "bicycle", Color.orange),
        ("Swimming", "figure.pool.swim", Color.cyan),
        ("Yoga", "figure.mind.and.body", Color.purple),
        ("Strength", "dumbbell.fill", Color.red)
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(workoutTypes, id: \.0) { workout in
                    Button(action: {
                        // Start workout
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: workout.1)
                                .foregroundColor(workout.2)
                                .font(.title2)
                            
                            Text(workout.0)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Models and Managers

struct HealthInsight {
    let message: String
    let recommendation: String?
    let severity: InsightSeverity
    
    enum InsightSeverity {
        case info, warning, alert
    }
}

class WatchHealthManager: ObservableObject {
    @Published var currentValue: String = "0"
    @Published var currentInsight: HealthInsight?
    
    private var healthStore: HKHealthStore?
    private var updateTimer: Timer?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func startMonitoring() {
        requestHealthKitPermissions()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.updateHealthData()
        }
        updateHealthData()
    }
    
    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func requestHealthKitPermissions() {
        guard let healthStore = healthStore else { return }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.updateHealthData()
                }
            }
        }
    }
    
    private func updateHealthData() {
        // Simulate health data updates
        DispatchQueue.main.async {
            self.currentValue = "\(Int.random(in: 60...100))"
            self.generateInsight()
        }
    }
    
    private func generateInsight() {
        let insights = [
            HealthInsight(
                message: "Your heart rate is within normal range",
                recommendation: "Consider a 5-minute walk to maintain activity",
                severity: .info
            ),
            HealthInsight(
                message: "You've been sedentary for 2 hours",
                recommendation: "Time for a quick stretch break!",
                severity: .warning
            ),
            HealthInsight(
                message: "Great job hitting your step goal!",
                recommendation: "Keep up the momentum",
                severity: .info
            )
        ]
        
        currentInsight = insights.randomElement()
    }
    
    func logWaterIntake() {
        // Log water intake
        WKInterfaceDevice.current().play(.success)
    }
    
    func startMeditation() {
        // Start meditation session
        WKInterfaceDevice.current().play(.start)
    }
    
    func triggerEmergency() {
        // Trigger emergency protocols
        WKInterfaceDevice.current().play(.notification)
    }
}

#Preview {
    HealthMonitoringView()
} 