import SwiftUI
import Charts

/// Respiratory Health Dashboard View for iOS 18+ respiratory health features
/// Displays respiratory rate, oxygen saturation, sleep apnea detection, and breathing patterns
struct RespiratoryHealthDashboardView: View {
    @StateObject private var respiratoryManager = RespiratoryHealthManager.shared
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingBreathingExercise = false
    @State private var selectedInsight: RespiratoryInsight?
    
    enum TimeRange: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Respiratory Health Score Card
                    RespiratoryHealthScoreCard()
                    
                    // Respiratory Rate Card
                    RespiratoryRateCard()
                    
                    // Oxygen Saturation Card
                    OxygenSaturationCard()
                    
                    // Sleep Apnea Card
                    SleepApneaCard()
                    
                    // Breathing Pattern Card
                    BreathingPatternCard()
                    
                    // Respiratory Insights Card
                    RespiratoryInsightsCard()
                }
                .padding()
            }
            .navigationTitle("Respiratory Health")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Breathing Exercise") {
                        showingBreathingExercise = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
            }
        }
        .sheet(isPresented: $showingBreathingExercise) {
            BreathingExerciseView()
        }
        .sheet(item: $selectedInsight) { insight in
            RespiratoryInsightDetailView(insight: insight)
        }
    }
}

// MARK: - Respiratory Health Score Card

struct RespiratoryHealthScoreCard: View {
    @StateObject private var respiratoryManager = RespiratoryHealthManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lungs.fill")
                    .foregroundColor(.blue)
                Text("Respiratory Health Score")
                    .font(.headline)
                Spacer()
                Text("\(Int(respiratoryManager.respiratoryHealthScore * 100))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: respiratoryManager.respiratoryHealthScore)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: respiratoryManager.respiratoryHealthScore)
                
                VStack {
                    Text("\(Int(respiratoryManager.respiratoryHealthScore * 100))")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Quick Stats
            HStack(spacing: 20) {
                StatItem(
                    title: "Respiratory Rate",
                    value: "\(String(format: "%.1f", respiratoryManager.respiratoryRate))",
                    color: .blue
                )
                
                StatItem(
                    title: "O2 Saturation",
                    value: "\(String(format: "%.1f", respiratoryManager.oxygenSaturation))%",
                    color: oxygenColor
                )
                
                StatItem(
                    title: "Efficiency",
                    value: "\(Int(respiratoryManager.respiratoryEfficiency * 100))%",
                    color: efficiencyColor
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var oxygenColor: Color {
        let saturation = respiratoryManager.oxygenSaturation
        switch saturation {
        case 95...100: return .green
        case 90..<95: return .yellow
        default: return .red
        }
    }
    
    private var efficiencyColor: Color {
        let efficiency = respiratoryManager.respiratoryEfficiency
        switch efficiency {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        default: return .red
        }
    }
}

// MARK: - Respiratory Rate Card

struct RespiratoryRateCard: View {
    @StateObject private var respiratoryManager = RespiratoryHealthManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lungs")
                    .foregroundColor(.blue)
                Text("Respiratory Rate")
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.1f", respiratoryManager.respiratoryRate))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    + Text(" breaths/min")
                        .font(.caption)
                        .foregroundColor(.secondary)
            }
            
            if respiratoryManager.respiratoryRateData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lungs")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.6))
                    Text("No respiratory rate data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Respiratory Rate Chart
                Chart {
                    ForEach(respiratoryManager.respiratoryRateData.prefix(100), id: \.timestamp) { sample in
                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("Rate", sample.value)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 120)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue))")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Respiratory Rate Statistics
                HStack(spacing: 20) {
                    StatItem(
                        title: "Average Rate",
                        value: "\(String(format: "%.1f", averageRespiratoryRate()))",
                        color: .blue
                    )
                    
                    StatItem(
                        title: "Min Rate",
                        value: "\(String(format: "%.1f", minRespiratoryRate()))",
                        color: .blue
                    )
                    
                    StatItem(
                        title: "Max Rate",
                        value: "\(String(format: "%.1f", maxRespiratoryRate()))",
                        color: .blue
                    )
                }
                
                // Breathing Pattern Status
                HStack {
                    Text("Current Pattern:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(respiratoryManager.breathingPattern.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(breathingPatternColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(breathingPatternColor.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func averageRespiratoryRate() -> Double {
        guard !respiratoryManager.respiratoryRateData.isEmpty else { return 0 }
        return respiratoryManager.respiratoryRateData.reduce(0) { $0 + $1.value } / Double(respiratoryManager.respiratoryRateData.count)
    }
    
    private func minRespiratoryRate() -> Double {
        respiratoryManager.respiratoryRateData.map { $0.value }.min() ?? 0
    }
    
    private func maxRespiratoryRate() -> Double {
        respiratoryManager.respiratoryRateData.map { $0.value }.max() ?? 0
    }
    
    private var breathingPatternColor: Color {
        switch respiratoryManager.breathingPattern {
        case .slow: return .blue
        case .normal: return .green
        case .slightlyElevated: return .yellow
        case .elevated: return .orange
        case .rapid: return .red
        }
    }
}

// MARK: - Oxygen Saturation Card

struct OxygenSaturationCard: View {
    @StateObject private var respiratoryManager = RespiratoryHealthManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.cyan)
                Text("Oxygen Saturation")
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.1f", respiratoryManager.oxygenSaturation))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(oxygenColor)
            }
            
            if respiratoryManager.oxygenSaturationData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "drop")
                        .font(.system(size: 40))
                        .foregroundColor(.cyan.opacity(0.6))
                    Text("No oxygen saturation data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Oxygen Saturation Chart
                Chart {
                    ForEach(respiratoryManager.oxygenSaturationData.prefix(50), id: \.timestamp) { sample in
                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("O2 Sat", sample.value)
                        )
                        .foregroundStyle(.cyan)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 120)
                .chartYScale(domain: 90...100)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue))%")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Oxygen Saturation Statistics
                HStack(spacing: 20) {
                    StatItem(
                        title: "Average O2",
                        value: "\(String(format: "%.1f", averageOxygenSaturation()))%",
                        color: .cyan
                    )
                    
                    StatItem(
                        title: "Min O2",
                        value: "\(String(format: "%.1f", minOxygenSaturation()))%",
                        color: .cyan
                    )
                    
                    StatItem(
                        title: "Status",
                        value: oxygenStatusText(),
                        color: oxygenColor
                    )
                }
                
                // Oxygen Level Indicator
                VStack(spacing: 8) {
                    HStack {
                        Text("Oxygen Level:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack(spacing: 4) {
                        ForEach(0..<10, id: \.self) { index in
                            Rectangle()
                                .fill(oxygenLevelColor(for: index))
                                .frame(height: 20)
                                .cornerRadius(2)
                        }
                    }
                    
                    HStack {
                        Text("Low")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Normal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("High")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func averageOxygenSaturation() -> Double {
        guard !respiratoryManager.oxygenSaturationData.isEmpty else { return 0 }
        return respiratoryManager.oxygenSaturationData.reduce(0) { $0 + $1.value } / Double(respiratoryManager.oxygenSaturationData.count)
    }
    
    private func minOxygenSaturation() -> Double {
        respiratoryManager.oxygenSaturationData.map { $0.value }.min() ?? 0
    }
    
    private func oxygenStatusText() -> String {
        let saturation = respiratoryManager.oxygenSaturation
        switch saturation {
        case 95...100: return "Normal"
        case 90..<95: return "Low"
        default: return "Very Low"
        }
    }
    
    private var oxygenColor: Color {
        let saturation = respiratoryManager.oxygenSaturation
        switch saturation {
        case 95...100: return .green
        case 90..<95: return .yellow
        default: return .red
        }
    }
    
    private func oxygenLevelColor(for index: Int) -> Color {
        let saturation = respiratoryManager.oxygenSaturation
        let level = (saturation - 90) / 10 * 10 // Normalize to 0-10 scale
        
        if Double(index) <= level {
            return oxygenColor
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// MARK: - Sleep Apnea Card

struct SleepApneaCard: View {
    @StateObject private var respiratoryManager = RespiratoryHealthManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.purple)
                Text("Sleep Apnea")
                    .font(.headline)
                Spacer()
                Text(respiratoryManager.sleepApneaRisk.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(sleepApneaColor)
            }
            
            if respiratoryManager.sleepApneaEvents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bed.double")
                        .font(.system(size: 40))
                        .foregroundColor(.purple.opacity(0.6))
                    Text("No sleep apnea events detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Continue monitoring during sleep")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Sleep Apnea Events Chart
                Chart {
                    ForEach(respiratoryManager.sleepApneaEvents.prefix(20), id: \.startDate) { event in
                        BarMark(
                            x: .value("Date", event.startDate),
                            y: .value("Duration", event.duration / 60) // Convert to minutes
                        )
                        .foregroundStyle(.purple.gradient)
                    }
                }
                .frame(height: 120)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue))m")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Sleep Apnea Statistics
                HStack(spacing: 20) {
                    StatItem(
                        title: "Events",
                        value: "\(respiratoryManager.sleepApneaEvents.count)",
                        color: .purple
                    )
                    
                    StatItem(
                        title: "Avg Duration",
                        value: formatAverageDuration(),
                        color: .purple
                    )
                    
                    StatItem(
                        title: "Risk Level",
                        value: respiratoryManager.sleepApneaRisk.displayName,
                        color: sleepApneaColor
                    )
                }
                
                // Sleep Apnea Alerts
                if !respiratoryManager.sleepApneaAlerts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Alerts")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(respiratoryManager.sleepApneaAlerts.prefix(2), id: \.timestamp) { alert in
                            SleepApneaAlertRow(alert: alert)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func formatAverageDuration() -> String {
        guard !respiratoryManager.sleepApneaEvents.isEmpty else { return "0m" }
        let averageDuration = respiratoryManager.sleepApneaEvents.reduce(0) { $0 + $1.duration } / Double(respiratoryManager.sleepApneaEvents.count)
        let minutes = Int(averageDuration) / 60
        return "\(minutes)m"
    }
    
    private var sleepApneaColor: Color {
        switch respiratoryManager.sleepApneaRisk {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}

struct SleepApneaAlertRow: View {
    let alert: SleepApneaAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(alertColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Sleep Apnea Alert")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Risk: \(alert.risk.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(alert.severity.displayName)
                .font(.caption)
                .foregroundColor(alertColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(alertColor.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var alertColor: Color {
        switch alert.severity {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Breathing Pattern Card

struct BreathingPatternCard: View {
    @StateObject private var respiratoryManager = RespiratoryHealthManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.green)
                Text("Breathing Pattern")
                    .font(.headline)
                Spacer()
                Text("\(Int(respiratoryManager.respiratoryEfficiency * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    + Text(" Efficiency")
                        .font(.caption)
                        .foregroundColor(.secondary)
            }
            
            if respiratoryManager.breathingPatternData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 40))
                        .foregroundColor(.green.opacity(0.6))
                    Text("No breathing pattern data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Breathing Pattern Chart
                Chart {
                    ForEach(respiratoryManager.breathingPatternData.prefix(50), id: \.timestamp) { sample in
                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("Variability", sample.variability)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 120)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(String(format: "%.1f", doubleValue))")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Breathing Pattern Analysis
                VStack(spacing: 12) {
                    HStack {
                        Text("Current Pattern:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(respiratoryManager.breathingPattern.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(breathingPatternColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(breathingPatternColor.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        Text("Efficiency:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(respiratoryManager.respiratoryEfficiency * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(efficiencyColor)
                    }
                }
                
                // Breathing Recommendations
                if !respiratoryManager.breathingRecommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Breathing Recommendations")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(respiratoryManager.breathingRecommendations.prefix(2), id: \.title) { recommendation in
                            BreathingRecommendationRow(recommendation: recommendation)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var breathingPatternColor: Color {
        switch respiratoryManager.breathingPattern {
        case .slow: return .blue
        case .normal: return .green
        case .slightlyElevated: return .yellow
        case .elevated: return .orange
        case .rapid: return .red
        }
    }
    
    private var efficiencyColor: Color {
        let efficiency = respiratoryManager.respiratoryEfficiency
        switch efficiency {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        default: return .red
        }
    }
}

struct BreathingRecommendationRow: View {
    let recommendation: BreathingRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendationIcon)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(recommendation.duration))
                    .font(.caption)
                    .fontWeight(.medium)
                Text(recommendation.technique.displayName)
                    .font(.caption2)
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var recommendationIcon: String {
        switch recommendation.type {
        case .deepBreathing: return "lungs.fill"
        case .pacedBreathing: return "timer"
        case .diaphragmaticBreathing: return "figure.core.training"
        case .relaxationBreathing: return "leaf.fill"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

// MARK: - Respiratory Insights Card

struct RespiratoryInsightsCard: View {
    @StateObject private var respiratoryManager = RespiratoryHealthManager.shared
    @State private var selectedInsight: RespiratoryInsight?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Respiratory Insights")
                    .font(.headline)
                Spacer()
            }
            
            if respiratoryManager.respiratoryInsights.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow.opacity(0.6))
                    Text("No respiratory insights yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Continue monitoring to receive personalized insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(respiratoryManager.respiratoryInsights.prefix(3), id: \.timestamp) { insight in
                    RespiratoryInsightRow(insight: insight)
                        .onTapGesture {
                            selectedInsight = insight
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .sheet(item: $selectedInsight) { insight in
            RespiratoryInsightDetailView(insight: insight)
        }
    }
}

struct RespiratoryInsightRow: View {
    let insight: RespiratoryInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insightIcon)
                .foregroundColor(insightColor)
                .frame(width: 24)
            
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
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var insightIcon: String {
        switch insight.type {
        case .respiratoryRate: return "lungs"
        case .oxygenSaturation: return "drop.fill"
        case .breathingPattern: return "waveform.path.ecg"
        case .efficiency: return "chart.line.uptrend.xyaxis"
        case .sleepApnea: return "bed.double.fill"
        case .general: return "lungs.fill"
        }
    }
    
    private var insightColor: Color {
        switch insight.severity {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RespiratoryInsightDetailView: View {
    let insight: RespiratoryInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Insight Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: insightIcon)
                                .foregroundColor(insightColor)
                                .font(.title2)
                            Text(insight.title)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text(insight.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Insight Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(.headline)
                        
                        DetailRow(title: "Type", value: insight.type.displayName)
                        DetailRow(title: "Severity", value: insight.severity.displayName)
                        DetailRow(title: "Time", value: insight.timestamp, style: .date)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                }
                .padding()
            }
            .navigationTitle("Respiratory Insight")
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
    
    private var insightIcon: String {
        switch insight.type {
        case .respiratoryRate: return "lungs"
        case .oxygenSaturation: return "drop.fill"
        case .breathingPattern: return "waveform.path.ecg"
        case .efficiency: return "chart.line.uptrend.xyaxis"
        case .sleepApnea: return "bed.double.fill"
        case .general: return "lungs.fill"
        }
    }
    
    private var insightColor: Color {
        switch insight.severity {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let style: DateFormatter.Style?
    
    init(title: String, value: String, style: DateFormatter.Style? = nil) {
        self.title = title
        self.value = value
        self.style = style
    }
    
    init(title: String, value: Date, style: DateFormatter.Style) {
        self.title = title
        self.value = value.formatted(date: style, time: .shortened)
        self.style = style
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Placeholder Views

struct BreathingExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Breathing Exercise")
                    .font(.title)
                Text("This view would guide users through breathing exercises")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Breathing Exercise")
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

// MARK: - Extensions

extension SleepApneaRisk {
    var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .moderate: return "Moderate Risk"
        case .high: return "High Risk"
        case .severe: return "Severe Risk"
        }
    }
}

extension BreathingPattern {
    var displayName: String {
        switch self {
        case .slow: return "Slow"
        case .normal: return "Normal"
        case .slightlyElevated: return "Slightly Elevated"
        case .elevated: return "Elevated"
        case .rapid: return "Rapid"
        }
    }
}

extension SleepApneaAlert.AlertSeverity {
    var displayName: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

extension BreathingRecommendation.BreathingTechnique {
    var displayName: String {
        switch self {
        case .boxBreathing: return "Box"
        case .fourSevenEight: return "4-7-8"
        case .pursedLip: return "Pursed Lip"
        case .bellyBreathing: return "Belly"
        }
    }
}

extension RespiratoryInsight.InsightType {
    var displayName: String {
        switch self {
        case .respiratoryRate: return "Respiratory Rate"
        case .oxygenSaturation: return "Oxygen Saturation"
        case .breathingPattern: return "Breathing Pattern"
        case .efficiency: return "Efficiency"
        case .sleepApnea: return "Sleep Apnea"
        case .general: return "General"
        }
    }
}

extension RespiratoryInsight.InsightSeverity {
    var displayName: String {
        switch self {
        case .info: return "Information"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

extension RespiratoryInsight: Identifiable {
    var id: Date { timestamp }
}

#Preview {
    RespiratoryHealthDashboardView()
} 