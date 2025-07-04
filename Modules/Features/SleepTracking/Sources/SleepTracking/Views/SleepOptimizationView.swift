import SwiftUI
import Charts

struct SleepOptimizationView: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager
    @EnvironmentObject var environmentManager: EnvironmentManager
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    @State private var showingSleepSession = false
    @State private var showingEnvironmentSetup = false
    @State private var selectedSleepStage: SleepStage = .awake
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                SleepHeaderView()
                
                // Sleep Session Status
                SleepSessionStatusCard()
                
                // Sleep Environment Controls
                SleepEnvironmentControls()
                
                // Sleep Analytics
                SleepAnalyticsSection()
                
                // Sleep Recommendations
                SleepRecommendationsSection()
                
                // Sleep Trends
                SleepTrendsChart()
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showingSleepSession) {
            SleepSessionView()
        }
        .sheet(isPresented: $showingEnvironmentSetup) {
            EnvironmentSetupView()
        }
    }
}

// MARK: - Header View

struct SleepHeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sleep Optimization")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Intelligent sleep engineering and environment optimization")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Current time
            VStack(alignment: .trailing, spacing: 5) {
                Text(currentTime)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(currentDate)
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var currentTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}

// MARK: - Sleep Session Status Card

struct SleepSessionStatusCard: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager
    
    var body: some View {
        VStack(spacing: 25) {
            // Session Status
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sleep Session")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(sessionStatus)
                        .font(.title3)
                        .foregroundColor(sessionStatusColor)
                }
                
                Spacer()
                
                // Session Duration
                if sleepOptimizationManager.isSleepSessionActive {
                    VStack(alignment: .trailing, spacing: 5) {
                        Text("Duration")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(sessionDuration)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                if sleepOptimizationManager.isSleepSessionActive {
                    Button(action: {
                        sleepOptimizationManager.stopSleepSession()
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop Session")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                } else {
                    Button(action: {
                        sleepOptimizationManager.startSleepSession()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Session")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                }
                
                Button(action: {
                    // Show sleep session details
                }) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Details")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
        }
        .padding(25)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var sessionStatus: String {
        sleepOptimizationManager.isSleepSessionActive ? "Active" : "Ready"
    }
    
    private var sessionStatusColor: Color {
        sleepOptimizationManager.isSleepSessionActive ? .green : .gray
    }
    
    private var sessionDuration: String {
        let duration = sleepOptimizationManager.sessionDuration
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

// MARK: - Sleep Environment Controls

struct SleepEnvironmentControls: View {
    @EnvironmentObject var environmentManager: EnvironmentManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Environment")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                // Temperature Control
                EnvironmentControlCard(
                    title: "Temperature",
                    value: String(format: "%.1f°C", environmentManager.currentTemperature),
                    icon: "thermometer",
                    color: .blue,
                    isActive: environmentManager.isTemperatureControlActive
                ) {
                    environmentManager.toggleTemperatureControl()
                }
                
                // Humidity Control
                EnvironmentControlCard(
                    title: "Humidity",
                    value: String(format: "%.0f%%", environmentManager.currentHumidity),
                    icon: "humidity",
                    color: .cyan,
                    isActive: environmentManager.isHumidityControlActive
                ) {
                    environmentManager.toggleHumidityControl()
                }
                
                // Light Control
                EnvironmentControlCard(
                    title: "Lighting",
                    value: environmentManager.currentLightLevel > 50 ? "On" : "Off",
                    icon: "lightbulb",
                    color: .yellow,
                    isActive: environmentManager.isLightControlActive
                ) {
                    environmentManager.toggleLightControl()
                }
                
                // Air Quality
                EnvironmentControlCard(
                    title: "Air Quality",
                    value: environmentManager.airQualityStatus,
                    icon: "wind",
                    color: environmentManager.airQualityColor,
                    isActive: environmentManager.isAirQualityControlActive
                ) {
                    environmentManager.toggleAirQualityControl()
                }
            }
            
            // Quick Environment Presets
            VStack(alignment: .leading, spacing: 15) {
                Text("Quick Presets")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 15) {
                    EnvironmentPresetButton(
                        title: "Sleep Mode",
                        icon: "bed.double.fill",
                        color: .purple
                    ) {
                        environmentManager.activateSleepMode()
                    }
                    
                    EnvironmentPresetButton(
                        title: "Relax Mode",
                        icon: "leaf.fill",
                        color: .green
                    ) {
                        environmentManager.activateRelaxMode()
                    }
                    
                    EnvironmentPresetButton(
                        title: "Reset",
                        icon: "arrow.clockwise",
                        color: .gray
                    ) {
                        environmentManager.resetEnvironment()
                    }
                }
            }
        }
        .padding(25)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

struct EnvironmentControlCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                    
                    // Active indicator
                    Circle()
                        .fill(isActive ? Color.green : Color.gray)
                        .frame(width: 12, height: 12)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnvironmentPresetButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sleep Analytics Section

struct SleepAnalyticsSection: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Analytics")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                // Sleep Duration
                AnalyticsCard(
                    title: "Sleep Duration",
                    value: "7h 32m",
                    subtitle: "Last Night",
                    color: .blue,
                    icon: "clock.fill"
                )
                
                // Sleep Efficiency
                AnalyticsCard(
                    title: "Sleep Efficiency",
                    value: "87%",
                    subtitle: "Excellent",
                    color: .green,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                // Deep Sleep
                AnalyticsCard(
                    title: "Deep Sleep",
                    value: "2h 15m",
                    subtitle: "Optimal",
                    color: .purple,
                    icon: "moon.fill"
                )
                
                // REM Sleep
                AnalyticsCard(
                    title: "REM Sleep",
                    value: "1h 45m",
                    subtitle: "Good",
                    color: .orange,
                    icon: "brain.head.profile"
                )
                
                // Sleep Score
                AnalyticsCard(
                    title: "Sleep Score",
                    value: "92",
                    subtitle: "Excellent",
                    color: .green,
                    icon: "star.fill"
                )
                
                // Wake Ups
                AnalyticsCard(
                    title: "Wake Ups",
                    value: "2",
                    subtitle: "Minimal",
                    color: .yellow,
                    icon: "eye.fill"
                )
            }
        }
        .padding(25)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Sleep Recommendations Section

struct SleepRecommendationsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Recommendations")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 15) {
                RecommendationCard(
                    title: "Optimize Bedtime",
                    description: "Based on your sleep patterns, try going to bed at 10:30 PM for optimal sleep quality.",
                    icon: "bed.double.fill",
                    color: .blue,
                    priority: .high
                )
                
                RecommendationCard(
                    title: "Reduce Screen Time",
                    description: "Limit screen exposure 1 hour before bedtime to improve melatonin production.",
                    icon: "iphone",
                    color: .orange,
                    priority: .medium
                )
                
                RecommendationCard(
                    title: "Adjust Temperature",
                    description: "Lower your bedroom temperature to 18-20°C for better sleep quality.",
                    icon: "thermometer",
                    color: .cyan,
                    priority: .medium
                )
            }
        }
        .padding(25)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

struct RecommendationCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let priority: RecommendationPriority
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Priority indicator
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)
                }
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var priorityColor: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - Sleep Trends Chart

struct SleepTrendsChart: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Trends")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Chart {
                ForEach(sleepData, id: \.date) { dataPoint in
                    BarMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Sleep Duration", dataPoint.duration)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 300)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }
        .padding(25)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var sleepData: [SleepDataPoint] {
        // Sample data - would come from actual sleep data
        return [
            SleepDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), duration: 7.5),
            SleepDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), duration: 8.0),
            SleepDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), duration: 6.5),
            SleepDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), duration: 7.8),
            SleepDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), duration: 8.2),
            SleepDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), duration: 7.3),
            SleepDataPoint(date: Date(), duration: 7.5)
        ]
    }
}

// MARK: - Supporting Types

enum RecommendationPriority {
    case high
    case medium
    case low
}

struct SleepDataPoint {
    let date: Date
    let duration: Double
}

// MARK: - Placeholder Views

struct SleepSessionView: View {
    var body: some View {
        VStack {
            Text("Sleep Session")
                .font(.title)
                .fontWeight(.bold)
            Text("Implementation coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct EnvironmentSetupView: View {
    var body: some View {
        VStack {
            Text("Environment Setup")
                .font(.title)
                .fontWeight(.bold)
            Text("Implementation coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}