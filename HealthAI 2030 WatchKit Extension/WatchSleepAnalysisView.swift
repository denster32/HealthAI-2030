import SwiftUI
import HealthKit

struct WatchSleepAnalysisView: View {
    @ObservedObject private var sessionManager = WatchSessionManager.shared
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @State private var selectedTimeRange: TimeRange = .today
    @State private var showingSleepTips = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Sleep Stage Chart
                    SleepStageChartView()
                    
                    // Current Sleep Metrics
                    CurrentSleepMetricsView()
                    
                    // Sleep Quality Score
                    SleepQualityView()
                    
                    // Sleep Insights
                    SleepInsightsView()
                    
                    // Quick Actions
                    SleepActionsView()
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tips") {
                        showingSleepTips = true
                    }
                    .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showingSleepTips) {
            SleepTipsView()
        }
    }
}

struct SleepStageChartView: View {
    @ObservedObject private var sessionManager = WatchSessionManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Sleep Stages")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                Spacer()
                Text("Last 8h")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Simplified sleep stage visualization
            HStack(spacing: 2) {
                ForEach(0..<24, id: \.self) { hour in
                    Rectangle()
                        .fill(colorForSleepStage(at: hour))
                        .frame(height: 20)
                }
            }
            .cornerRadius(4)
            
            // Legend
            HStack(spacing: 12) {
                LegendItem(color: .red, text: "Awake")
                LegendItem(color: .yellow, text: "Light")
                LegendItem(color: .blue, text: "Deep")
                LegendItem(color: .purple, text: "REM")
            }
            .font(.caption2)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func colorForSleepStage(at hour: Int) -> Color {
        // Simulate sleep stage data based on hour
        let sleepHours = Array(22...24) + Array(0...6)
        
        if sleepHours.contains(hour) {
            switch hour % 4 {
            case 0: return .blue // Deep sleep
            case 1: return .yellow // Light sleep
            case 2: return .purple // REM sleep
            default: return .yellow // Light sleep
            }
        } else {
            return .red // Awake
        }
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
        }
    }
}

struct CurrentSleepMetricsView: View {
    @ObservedObject private var sessionManager = WatchSessionManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Current Status")
                .font(.caption)
                .foregroundColor(.accentColor)
            
            HStack(spacing: 16) {
                SleepMetricItem(
                    title: "Stage",
                    value: sessionManager.currentSleepStage.displayName,
                    color: colorForSleepStage(sessionManager.currentSleepStage)
                )
                
                SleepMetricItem(
                    title: "Duration",
                    value: formatDuration(sessionManager.sessionDuration),
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                SleepMetricItem(
                    title: "Heart Rate",
                    value: "\(Int(sessionManager.currentHeartRate))",
                    color: .red
                )
                
                SleepMetricItem(
                    title: "HRV",
                    value: "\(Int(sessionManager.currentHRV))",
                    color: .blue
                )
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func colorForSleepStage(_ stage: SleepStage) -> Color {
        switch stage {
        case .awake: return .red
        case .lightSleep: return .yellow
        case .deepSleep: return .blue
        case .remSleep: return .purple
        case .unknown: return .gray
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct SleepMetricItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SleepQualityView: View {
    @State private var sleepQuality: Double = 0.75
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Sleep Quality")
                .font(.caption)
                .foregroundColor(.accentColor)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: sleepQuality)
                    .stroke(qualityColor, lineWidth: 6)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(sleepQuality * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(qualityColor)
            }
            
            Text(qualityDescription)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var qualityColor: Color {
        if sleepQuality > 0.8 { return .green }
        if sleepQuality > 0.6 { return .yellow }
        return .red
    }
    
    private var qualityDescription: String {
        if sleepQuality > 0.8 { return "Excellent" }
        if sleepQuality > 0.6 { return "Good" }
        if sleepQuality > 0.4 { return "Fair" }
        return "Poor"
    }
}

struct SleepInsightsView: View {
    @State private var insights: [String] = [
        "Your deep sleep increased by 15% this week",
        "Consider reducing screen time before bed",
        "Your sleep consistency has improved"
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Insights")
                .font(.caption)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(insights.prefix(2), id: \.self) { insight in
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        
                        Text(insight)
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SleepActionsView: View {
    @ObservedObject private var sessionManager = WatchSessionManager.shared
    @ObservedObject private var hapticManager = WatchHapticManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Actions")
                .font(.caption)
                .foregroundColor(.accentColor)
            
            HStack(spacing: 8) {
                ActionButton(
                    icon: "moon.fill",
                    title: "Sleep Mode",
                    color: .indigo
                ) {
                    toggleSleepMode()
                }
                
                ActionButton(
                    icon: "heart.text.square",
                    title: "Check HR",
                    color: .red
                ) {
                    performHeartRateCheck()
                }
                
                ActionButton(
                    icon: "bell.slash",
                    title: "Do Not Disturb",
                    color: .purple
                ) {
                    enableDoNotDisturb()
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func toggleSleepMode() {
        if sessionManager.isSleepSessionActive {
            sessionManager.stopSleepSession()
        } else {
            sessionManager.startSleepSession()
        }
        hapticManager.triggerHaptic(type: .sessionStart)
    }
    
    private func performHeartRateCheck() {
        sessionManager.performBackgroundHealthCheck {
            // Completion handled by session manager
        }
        hapticManager.triggerHaptic(type: .reminder)
    }
    
    private func enableDoNotDisturb() {
        // This would integrate with system DND if available
        hapticManager.triggerHaptic(type: .reminder)
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SleepTipsView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let tips = [
        "Keep a consistent sleep schedule",
        "Create a relaxing bedtime routine",
        "Avoid caffeine 6 hours before bed",
        "Keep your bedroom cool and dark",
        "Limit screen time before sleep",
        "Exercise regularly, but not close to bedtime"
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tips, id: \.self) { tip in
                    HStack {
                        Image(systemName: "moon.stars")
                            .foregroundColor(.blue)
                        
                        Text(tip)
                            .font(.caption)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Sleep Tips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

enum TimeRange: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
}

#Preview {
    WatchSleepAnalysisView()
}