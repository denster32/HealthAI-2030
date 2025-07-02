import SwiftUI
import MentalHealthDashboardView
import AdvancedCardiacDashboardView
import RespiratoryHealthDashboardView

struct MainTabView: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var sleepOptimizationManager = SleepOptimizationManager.shared
    @StateObject private var environmentManager = EnvironmentManager.shared
    @StateObject private var mentalHealthManager = MentalHealthManager.shared
    @StateObject private var advancedCardiacManager = AdvancedCardiacManager.shared
    @StateObject private var respiratoryHealthManager = RespiratoryHealthManager.shared
    @StateObject private var systemIntelligenceManager = SystemIntelligenceManager.shared
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            AdvancedAnalyticsDashboardView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Analytics")
                }
            
            MentalHealthDashboardView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("Mental Health")
                }
            
            AdvancedCardiacDashboardView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Cardiac")
                }
            
            RespiratoryHealthDashboardView()
                .tabItem {
                    Image(systemName: "lungs.fill")
                    Text("Respiratory")
                }
            
            SystemIntelligenceView()
                .tabItem {
                    Image(systemName: "brain")
                    Text("Intelligence")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .environmentObject(healthDataManager)
        .environmentObject(sleepOptimizationManager)
        .environmentObject(environmentManager)
        .environmentObject(mentalHealthManager)
        .environmentObject(advancedCardiacManager)
        .environmentObject(respiratoryHealthManager)
        .environmentObject(systemIntelligenceManager)
    }
}

struct DashboardView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var predictiveAnalytics: PredictiveAnalyticsManager
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager
    @EnvironmentObject var environmentManager: EnvironmentManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Health Status
                    CurrentHealthStatusCard()
                    
                    // PhysioForecast
                    PhysioForecastCard()
                    
                    // Health Alerts
                    HealthAlertsCard()
                    
                    // Daily Insights
                    DailyInsightsCard()
                    
                    // Sleep Architecture
                    SleepArchitectureCard()

                    // Recovery Rating
                    RecoveryRatingCard()

                    // Quick Actions
                    QuickActionsCard()
                }
                .padding()
            }
            .navigationTitle("HealthAI 2030")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CurrentHealthStatusCard: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Current Health Status")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                HealthMetricView(
                    title: "Heart Rate",
                    value: "\(Int(healthDataManager.currentHeartRate))",
                    unit: "BPM",
                    color: .red
                )
                
                HealthMetricView(
                    title: "HRV",
                    value: String(format: "%.1f", healthDataManager.currentHRV),
                    unit: "ms",
                    color: .green
                )
                
                HealthMetricView(
                    title: "Oxygen",
                    value: String(format: "%.1f", healthDataManager.currentOxygenSaturation * 100),
                    unit: "%",
                    color: .blue
                )
                
                HealthMetricView(
                    title: "Steps",
                    value: "\(healthDataManager.stepCount)",
                    unit: "",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PhysioForecastCard: View {
    @EnvironmentObject var predictiveAnalytics: PredictiveAnalyticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "crystal.ball")
                    .foregroundColor(.purple)
                Text("Tomorrow's Forecast")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForecastMetricRow(
                    title: "Energy",
                    value: predictiveAnalytics.physioForecast.energy,
                    color: .yellow
                )
                
                ForecastMetricRow(
                    title: "Mood Stability",
                    value: predictiveAnalytics.physioForecast.moodStability,
                    color: .green
                )
                
                ForecastMetricRow(
                    title: "Cognitive Acuity",
                    value: predictiveAnalytics.physioForecast.cognitiveAcuity,
                    color: .blue
                )
                
                ForecastMetricRow(
                    title: "Resilience",
                    value: predictiveAnalytics.physioForecast.musculoskeletalResilience,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct HealthAlertsCard: View {
    @EnvironmentObject var predictiveAnalytics: PredictiveAnalyticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Health Alerts")
                    .font(.headline)
                Spacer()
            }
            
            if predictiveAnalytics.healthAlerts.isEmpty {
                Text("No active alerts")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(predictiveAnalytics.healthAlerts.prefix(3), id: \.timestamp) { alert in
                    AlertRow(alert: alert)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct DailyInsightsCard: View {
    @EnvironmentObject var predictiveAnalytics: PredictiveAnalyticsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Daily Insights")
                    .font(.headline)
                Spacer()
            }
            
            if predictiveAnalytics.dailyInsights.isEmpty {
                Text("No insights available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(predictiveAnalytics.dailyInsights.prefix(2), id: \.timestamp) { insight in
                    InsightRow(insight: insight)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct QuickActionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.blue)
                Text("Quick Actions")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                QuickActionButton(
                    title: "Start Sleep",
                    icon: "bed.double.fill",
                    color: .purple
                ) {
                    sleepOptimizationManager.startOptimization()
                }
                
                QuickActionButton(
                    title: "Environment",
                    icon: "house.fill",
                    color: .green
                ) {
                    environmentManager.optimizeForSleep()
                }
                
                QuickActionButton(
                    title: "Meditation",
                    icon: "brain.head.profile",
                    color: .blue
                ) {
                    // Start meditation
                }
                
                QuickActionButton(
                    title: "Exercise",
                    icon: "figure.run",
                    color: .orange
                ) {
                    // Start exercise tracking
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Supporting Views

struct HealthMetricView: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ForecastMetricRow: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(width: 100)
            
            Text("\(Int(value * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AlertRow: View {
    let alert: HealthAlert
    
    var body: some View {
        HStack {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.message)
                    .font(.subheadline)
                    .lineLimit(2)
                
                Text(alert.recommendedAction)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var severityColor: Color {
        switch alert.severity {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }
}

struct InsightRow: View {
    let insight: HealthInsight
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if insight.actionable {
                Button("Action") {
                    // Handle action
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views

struct SleepView: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var bedMotorManager: BedMotorManager
    @EnvironmentObject var rlAgent: RLAgent
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Sleep Optimization Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Sleep Architecture and Recovery Cards
                    SleepArchitectureCard()
                    RecoveryRatingCard()
                    
                    // Current Sleep Status
                    CurrentSleepStatusCard()
                    
                    // RLAgent Statistics
                    RLAgentStatsCard()
                    
                    // Bed Motor Status
                    BedMotorStatusCard()
                    
                    // Sleep Optimization Controls
                    SleepOptimizationControlsCard()
                    
                    // Recent Interventions
                    RecentInterventionsCard()
                    
                    // Sleep History (simplified for M1)
                    SleepHistoryCard()
                }
                .padding()
            }
            .navigationTitle("Sleep")
        }
    }
}

// MARK: - Supporting View Components

struct CurrentSleepStatusCard: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.purple)
                Text("Current Sleep Status")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                StatusRow(title: "Sleep Stage", value: sleepOptimizationManager.currentSleepStage.rawValue.capitalized, color: .purple)
                StatusRow(title: "Sleep Quality", value: "\(Int(sleepOptimizationManager.sleepQuality * 100))%", color: sleepQualityColor(sleepOptimizationManager.sleepQuality))
                StatusRow(title: "Heart Rate", value: "\(Int(healthDataManager.currentHeartRate)) BPM", color: .red)
                StatusRow(title: "HRV", value: "\(Int(healthDataManager.currentHRV)) ms", color: .green)
                StatusRow(title: "Deep Sleep", value: "\(Int(sleepOptimizationManager.deepSleepPercentage * 100))%", color: .blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func sleepQualityColor(_ quality: Double) -> Color {
        if quality >= 0.8 { return .green }
        else if quality >= 0.6 { return .orange }
        else { return .red }
    }
}

struct RLAgentStatsCard: View {
    @EnvironmentObject var rlAgent: RLAgent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("RL Agent Statistics")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                StatusRow(title: "Total Nudges", value: "\(rlAgent.nudgeCount)", color: .blue)
                
                if let lastNudge = rlAgent.lastNudgeAction {
                    StatusRow(title: "Last Nudge", value: lastNudge.reason, color: .orange)
                } else {
                    StatusRow(title: "Last Nudge", value: "None", color: .gray)
                }
                
                StatusRow(title: "Agent Status", value: "Active", color: .green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct BedMotorStatusCard: View {
    @EnvironmentObject var bedMotorManager: BedMotorManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double")
                    .foregroundColor(.indigo)
                Text("Bed Motor Status")
                    .font(.headline)
                Spacer()
                
                // Connection status indicator
                Circle()
                    .fill(bedMotorManager.connectionStatus == .connected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                StatusRow(title: "Head Elevation", value: "\(Int(bedMotorManager.headElevation * 100))%", color: .indigo)
                StatusRow(title: "Foot Elevation", value: "\(Int(bedMotorManager.footElevation * 100))%", color: .indigo)
                StatusRow(title: "Massage", value: bedMotorManager.isMassaging ? "Active" : "Inactive", color: bedMotorManager.isMassaging ? .green : .gray)
                StatusRow(title: "Moving", value: bedMotorManager.isMoving ? "Yes" : "No", color: bedMotorManager.isMoving ? .orange : .gray)
                
                if let error = bedMotorManager.lastError {
                    StatusRow(title: "Last Error", value: error.description, color: .red)
                }
            }
            
            // Quick bed position controls
            HStack(spacing: 12) {
                Button("Flat") {
                    bedMotorManager.setFlatPosition()
                }
                .buttonStyle(.bordered)
                
                Button("Deep Sleep") {
                    bedMotorManager.setDeepSleepPosition()
                }
                .buttonStyle(.bordered)
                
                Button("Wake Up") {
                    bedMotorManager.setWakeUpPosition()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SleepOptimizationControlsCard: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                Text("Sleep Optimization Controls")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $sleepOptimizationManager.isOptimizationActive) {
                    Text("Enable Sleep Optimization")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal)
                
                HStack(spacing: 12) {
                    Button(action: {
                        sleepOptimizationManager.startOptimization()
                    }) {
                        Label("Start", systemImage: "play.circle.fill")
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        sleepOptimizationManager.stopOptimization()
                    }) {
                        Label("Stop", systemImage: "stop.circle.fill")
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecentInterventionsCard: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.orange)
                Text("Recent Interventions")
                    .font(.headline)
                Spacer()
            }
            
            if sleepOptimizationManager.sleepMetrics.interventions.isEmpty {
                Text("No recent interventions.")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(Array(sleepOptimizationManager.sleepMetrics.interventions.suffix(5).enumerated()), id: \.offset) { index, intervention in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(intervention.reason)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Type: \(interventionTypeString(intervention.type))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    if index < sleepOptimizationManager.sleepMetrics.interventions.suffix(5).count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func interventionTypeString(_ type: NudgeActionType) -> String {
        switch type {
        case .audio(let audioType):
            return "Audio: \(audioTypeString(audioType))"
        case .haptic(let hapticType):
            return "Haptic: \(hapticTypeString(hapticType))"
        case .environment(let envType):
            return "Environment: \(environmentTypeString(envType))"
        case .bedMotor(let bedType):
            return "Bed Motor: \(bedMotorTypeString(bedType))"
        }
    }
    
    private func audioTypeString(_ type: AudioNudgeType) -> String {
        switch type {
        case .pinkNoise: return "Pink Noise"
        case .isochronicTones: return "Isochronic Tones"
        case .binauralBeats: return "Binaural Beats"
        case .natureSounds: return "Nature Sounds"
        }
    }
    
    private func hapticTypeString(_ type: HapticNudgeType) -> String {
        switch type {
        case .gentlePulse: return "Gentle Pulse"
        case .strongPulse: return "Strong Pulse"
        }
    }
    
    private func environmentTypeString(_ type: EnvironmentNudgeType) -> String {
        switch type {
        case .lowerTemperature: return "Lower Temperature"
        case .raiseHumidity: return "Raise Humidity"
        case .dimLights: return "Dim Lights"
        case .closeBlinds: return "Close Blinds"
        case .startHEPAFilter: return "Start HEPA Filter"
        case .stopHEPAFilter: return "Stop HEPA Filter"
        }
    }
    
    private func bedMotorTypeString(_ type: BedMotorNudgeType) -> String {
        switch type {
        case .adjustHead: return "Adjust Head"
        case .adjustFoot: return "Adjust Foot"
        case .startMassage: return "Start Massage"
        case .stopMassage: return "Stop Massage"
        }
    }
}

struct SleepHistoryCard: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Sleep History")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                StatusRow(title: "Total Sleep Time", value: formatTimeInterval(sleepOptimizationManager.sleepMetrics.totalSleepTime), color: .green)
                StatusRow(title: "Deep Sleep Time", value: formatTimeInterval(sleepOptimizationManager.sleepMetrics.deepSleepTime), color: .blue)
                StatusRow(title: "REM Sleep Time", value: formatTimeInterval(sleepOptimizationManager.sleepMetrics.remSleepTime), color: .purple)
                StatusRow(title: "Light Sleep Time", value: formatTimeInterval(sleepOptimizationManager.sleepMetrics.lightSleepTime), color: .orange)
                StatusRow(title: "Awake Time", value: formatTimeInterval(sleepOptimizationManager.sleepMetrics.awakeTime), color: .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct EnvironmentView: View {
    @EnvironmentObject var environmentManager: EnvironmentManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Environment Control Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Current Environment Data
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current Environment")
                            .font(.headline)
                        
                        EnvironmentMetricRow(title: "Temperature", value: "\(String(format: "%.1f", environmentManager.currentTemperature))°C", icon: "thermometer")
                        EnvironmentMetricRow(title: "Humidity", value: "\(Int(environmentManager.currentHumidity))%", icon: "humidity.fill")
                        EnvironmentMetricRow(title: "Light Level", value: "\(Int(environmentManager.currentLightLevel * 100))%", icon: "lightbulb.fill")
                        EnvironmentMetricRow(title: "Noise Level", value: "\(Int(environmentManager.noiseLevel)) dB", icon: "speaker.wave.2.fill")
                        EnvironmentMetricRow(title: "Air Quality", value: "\(Int(environmentManager.airQuality * 100))%", icon: "wind")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Environment Optimization Controls
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Optimization Modes")
                            .font(.headline)
                        
                        Picker("Optimization Mode", selection: $environmentManager.currentOptimizationMode) {
                            Text("Auto").tag(OptimizationMode.auto)
                            Text("Sleep").tag(OptimizationMode.sleep)
                            Text("Work").tag(OptimizationMode.work)
                            Text("Exercise").tag(OptimizationMode.exercise)
                            Text("Custom").tag(OptimizationMode.custom)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        Button(action: {
                            switch environmentManager.currentOptimizationMode {
                            case .auto:
                                // Implement auto logic or do nothing for now
                                break
                            case .sleep:
                                environmentManager.optimizeForSleep()
                            case .work:
                                environmentManager.optimizeForWork()
                            case .exercise:
                                environmentManager.optimizeForExercise()
                            case .custom:
                                // Implement custom logic
                                break
                            }
                        }) {
                            Label("Apply Optimization", systemImage: "wand.and.stars")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            environmentManager.stopOptimization()
                        }) {
                            Label("Stop Optimization", systemImage: "stop.circle.fill")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Environment Recommendations
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Environment Recommendations")
                            .font(.headline)
                        
                        if environmentManager.getEnvironmentRecommendations().isEmpty {
                            Text("No recommendations at this time.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(environmentManager.getEnvironmentRecommendations(), id: \.message) { recommendation in
                                Text("• \(recommendation.message)")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                }
                .padding()
            }
            .navigationTitle("Environment")
        }
    }
}

struct EnvironmentMetricRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("App configuration and preferences coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(HealthDataManager.shared)
        .environmentObject(PredictiveAnalyticsManager.shared)
        .environmentObject(SleepOptimizationManager.shared)
        .environmentObject(EnvironmentManager.shared)
}