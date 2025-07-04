import SwiftUI
import Charts

@available(iOS 17.0, *)
@available(macOS 14.0, *)

// MARK: - iPad-Optimized Health Data Visualizations

struct iPadEnhancedChartsView: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var predictiveAnalytics = PredictiveAnalyticsManager.shared
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var deviceType: DeviceType {
        DeviceType.current
    }
    
    var body: some View {
        Group {
            if deviceType.isIPad {
                iPadChartsLayout
            } else {
                iPhoneChartsLayout
            }
        }
    }
    
    private var iPadChartsLayout: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            // Heart Rate Trend Chart
            iPadChartCard(title: "Heart Rate Trend") {
                HeartRateChart()
                    .frame(height: 200)
            }
            
            // HRV Analysis
            iPadChartCard(title: "HRV Analysis") {
                HRVChart()
                    .frame(height: 200)
            }
            
            // Sleep Architecture (Full Width)
            iPadChartCard(title: "Sleep Architecture") {
                SleepArchitectureChart()
                    .frame(height: 150)
            }
            .gridCellColumns(2)
            
            // Daily Activity Overview
            iPadChartCard(title: "Daily Activity") {
                ActivityChart()
                    .frame(height: 200)
            }
            
            // Recovery Metrics
            iPadChartCard(title: "Recovery Metrics") {
                RecoveryChart()
                    .frame(height: 200)
            }
        }
    }
    
    private var iPhoneChartsLayout: some View {
        VStack(spacing: 20) {
            // Compact versions for iPhone
            CompactChartCard(title: "Heart Rate") {
                HeartRateChart()
                    .frame(height: 120)
            }
            
            CompactChartCard(title: "Sleep Quality") {
                SleepArchitectureChart()
                    .frame(height: 100)
            }
        }
    }
}

struct iPadChartCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    // Expand chart action
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct CompactChartCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            content()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Enhanced Chart Components

struct HeartRateChart: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    
    // Mock data for demonstration
    private var heartRateData: [HeartRatePoint] {
        let now = Date()
        return (0..<24).map { hour in
            HeartRatePoint(
                time: Calendar.current.date(byAdding: .hour, value: -hour, to: now) ?? now,
                heartRate: Double.random(in: 60...100),
                zone: heartRateZone(for: Double.random(in: 60...100))
            )
        }.reversed()
    }
    
    var body: some View {
        Chart(heartRateData, id: \.time) { point in
            LineMark(
                x: .value("Time", point.time),
                y: .value("Heart Rate", point.heartRate)
            )
            .foregroundStyle(colorForZone(point.zone))
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            AreaMark(
                x: .value("Time", point.time),
                y: .value("Heart Rate", point.heartRate)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [colorForZone(point.zone).opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 4)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: 50...120)
    }
    
    private func heartRateZone(for hr: Double) -> HeartRateZone {
        switch hr {
        case 0..<60: return .resting
        case 60..<100: return .normal
        case 100..<150: return .elevated
        default: return .maximum
        }
    }
    
    private func colorForZone(_ zone: HeartRateZone) -> Color {
        switch zone {
        case .resting: return .blue
        case .normal: return .green
        case .elevated: return .orange
        case .maximum: return .red
        }
    }
}

struct HRVChart: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    
    // Mock HRV data
    private var hrvData: [HRVPoint] {
        let now = Date()
        return (0..<7).map { day in
            HRVPoint(
                date: Calendar.current.date(byAdding: .day, value: -day, to: now) ?? now,
                hrv: Double.random(in: 20...60),
                quality: Double.random(in: 0.5...1.0)
            )
        }.reversed()
    }
    
    var body: some View {
        Chart(hrvData, id: \.date) { point in
            BarMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("HRV", point.hrv)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [colorForQuality(point.quality), colorForQuality(point.quality).opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
    }
    
    private func colorForQuality(_ quality: Double) -> Color {
        switch quality {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

struct SleepArchitectureChart: View {
    // Mock sleep stage data
    private var sleepStages: [SleepStagePoint] {
        let startTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        var stages: [SleepStagePoint] = []
        
        // Generate 8 hours of sleep data in 30-minute intervals
        for interval in 0..<16 {
            let time = Calendar.current.date(byAdding: .minute, value: interval * 30, to: startTime) ?? startTime
            let stage = sleepStageForInterval(interval)
            stages.append(SleepStagePoint(time: time, stage: stage, depth: depthForStage(stage)))
        }
        
        return stages
    }
    
    var body: some View {
        Chart(sleepStages, id: \.time) { point in
            BarMark(
                x: .value("Time", point.time),
                y: .value("Sleep Depth", point.depth)
            )
            .foregroundStyle(colorForStage(point.stage))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { _ in
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4]) { value in
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text(labelForDepth(intValue))
                    }
                }
            }
        }
        .chartYScale(domain: 0...4)
    }
    
    private func sleepStageForInterval(_ interval: Int) -> SleepStage {
        // Simplified sleep cycle simulation
        switch interval {
        case 0...2: return .light
        case 3...5: return .deep
        case 6...7: return .rem
        case 8...10: return .light
        case 11...12: return .deep
        case 13...14: return .rem
        default: return .light
        }
    }
    
    private func depthForStage(_ stage: SleepStage) -> Double {
        switch stage {
        case .awake: return 4
        case .light: return 3
        case .deep: return 1
        case .rem: return 2
        }
    }
    
    private func colorForStage(_ stage: SleepStage) -> Color {
        switch stage {
        case .awake: return .red
        case .light: return .blue
        case .deep: return .purple
        case .rem: return .orange
        }
    }
    
    private func labelForDepth(_ depth: Int) -> String {
        switch depth {
        case 1: return "Deep"
        case 2: return "REM"
        case 3: return "Light"
        case 4: return "Awake"
        default: return ""
        }
    }
}

struct ActivityChart: View {
    // Mock activity data
    private var activityData: [ActivityPoint] {
        let now = Date()
        return (0..<7).map { day in
            ActivityPoint(
                date: Calendar.current.date(byAdding: .day, value: -day, to: now) ?? now,
                steps: Int.random(in: 5000...15000),
                activeMinutes: Int.random(in: 30...120),
                calories: Int.random(in: 200...800)
            )
        }.reversed()
    }
    
    var body: some View {
        Chart {
            ForEach(activityData, id: \.date) { point in
                // Steps as bars
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Steps", point.steps)
                )
                .foregroundStyle(.blue)
                .opacity(0.7)
                
                // Active minutes as line
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Active Minutes", point.activeMinutes * 100) // Scale for visibility
                )
                .foregroundStyle(.orange)
                .lineStyle(StrokeStyle(lineWidth: 3))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
            }
        }
    }
}

struct RecoveryChart: View {
    // Mock recovery data
    private var recoveryData: [RecoveryPoint] {
        let now = Date()
        return (0..<14).map { day in
            RecoveryPoint(
                date: Calendar.current.date(byAdding: .day, value: -day, to: now) ?? now,
                recovery: Double.random(in: 0.3...1.0),
                stress: Double.random(in: 0.1...0.8),
                sleep: Double.random(in: 0.5...1.0)
            )
        }.reversed()
    }
    
    var body: some View {
        Chart {
            ForEach(recoveryData, id: \.date) { point in
                // Recovery line
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Recovery", point.recovery)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                // Stress line
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Stress", point.stress)
                )
                .foregroundStyle(.red)
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYScale(domain: 0...1)
    }
}

// MARK: - Data Models for Charts

struct HeartRatePoint {
    let time: Date
    let heartRate: Double
    let zone: HeartRateZone
}

enum HeartRateZone {
    case resting, normal, elevated, maximum
}

struct HRVPoint {
    let date: Date
    let hrv: Double
    let quality: Double
}

struct SleepStagePoint {
    let time: Date
    let stage: SleepStage
    let depth: Double
}

enum SleepStage {
    case awake, light, deep, rem
}

struct ActivityPoint {
    let date: Date
    let steps: Int
    let activeMinutes: Int
    let calories: Int
}

struct RecoveryPoint {
    let date: Date
    let recovery: Double
    let stress: Double
    let sleep: Double
}

// MARK: - iPad-Specific Analytics Dashboard

struct iPadAnalyticsDashboard: View {
    import Analytics
    @StateObject private var analyticsEngine = AnalyticsEngine.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Summary cards row
                    iPadSummaryCardsRow()
                    
                    // Main charts section
                    iPadEnhancedChartsView()
                    
                    // Detailed insights
                    iPadInsightsSection()
                    
                    // Correlation analysis
                    iPadCorrelationSection()
                }
                .padding()
            }
            .navigationTitle("Health Analytics")
            .iPadOptimized()
        }
    }
}

struct iPadSummaryCardsRow: View {
    var body: some View {
        HStack(spacing: 20) {
            iPadSummaryCard(
                title: "Sleep Score",
                value: "87",
                subtitle: "+5 from yesterday",
                color: .purple,
                icon: "bed.double.fill"
            )
            
            iPadSummaryCard(
                title: "Recovery",
                value: "92%",
                subtitle: "Excellent",
                color: .green,
                icon: "heart.circle.fill"
            )
            
            iPadSummaryCard(
                title: "HRV",
                value: "45ms",
                subtitle: "Above average",
                color: .blue,
                icon: "waveform.path.ecg"
            )
            
            iPadSummaryCard(
                title: "Stress",
                value: "Low",
                subtitle: "28% today",
                color: .orange,
                icon: "brain.head.profile"
            )
        }
    }
}

struct iPadSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct iPadInsightsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Insights")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                iPadInsightCard(
                    title: "Sleep Optimization",
                    insight: "Your deep sleep increased by 15% this week. Consider maintaining your current bedtime routine.",
                    priority: .high,
                    icon: "lightbulb.fill"
                )
                
                iPadInsightCard(
                    title: "Recovery Pattern",
                    insight: "Your HRV shows optimal recovery on weekends. Try to replicate weekend sleep patterns on weekdays.",
                    priority: .medium,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                iPadInsightCard(
                    title: "Activity Correlation",
                    insight: "Higher step counts correlate with better sleep quality. Aim for 10,000+ steps daily.",
                    priority: .low,
                    icon: "figure.walk"
                )
                
                iPadInsightCard(
                    title: "Stress Management",
                    insight: "Meditation sessions reduced your stress levels by 30%. Continue with 10-minute sessions.",
                    priority: .high,
                    icon: "brain.head.profile"
                )
            }
        }
    }
}

struct iPadInsightCard: View {
    let title: String
    let insight: String
    let priority: InsightPriority
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(colorForPriority(priority))
                    .font(.title3)
                
                Spacer()
                
                priorityBadge
            }
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(insight)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorForPriority(priority).opacity(0.3), lineWidth: 1)
        )
    }
    
    private var priorityBadge: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForPriority(priority).opacity(0.2))
            .foregroundColor(colorForPriority(priority))
            .cornerRadius(6)
    }
    
    private func colorForPriority(_ priority: InsightPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

enum InsightPriority: String {
    case high, medium, low
}

struct iPadCorrelationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Correlations")
                .font(.title2)
                .fontWeight(.bold)
            
            // Correlation matrix or detailed correlation cards
            iPadCorrelationMatrix()
        }
    }
}

struct iPadCorrelationMatrix: View {
    var body: some View {
        // Simplified correlation display
        VStack(spacing: 12) {
            iPadCorrelationRow(
                metric1: "Sleep Quality",
                metric2: "HRV",
                correlation: 0.78,
                significance: "Strong positive correlation"
            )
            
            iPadCorrelationRow(
                metric1: "Step Count",
                metric2: "Sleep Duration",
                correlation: 0.65,
                significance: "Moderate positive correlation"
            )
            
            iPadCorrelationRow(
                metric1: "Stress Level",
                metric2: "Heart Rate",
                correlation: 0.82,
                significance: "Strong positive correlation"
            )
        }
    }
}

struct iPadCorrelationRow: View {
    let metric1: String
    let metric2: String
    let correlation: Double
    let significance: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(metric1)
                        .fontWeight(.medium)
                    Text("↔")
                        .foregroundColor(.secondary)
                    Text(metric2)
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                
                Text(significance)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", correlation))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorForCorrelation(correlation))
                
                correlationBar
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var correlationBar: some View {
        ProgressView(value: abs(correlation))
            .progressViewStyle(LinearProgressViewStyle(tint: colorForCorrelation(correlation)))
            .frame(width: 60, height: 4)
    }
    
    private func colorForCorrelation(_ value: Double) -> Color {
        let absValue = abs(value)
        if absValue >= 0.7 { return .green }
        else if absValue >= 0.5 { return .orange }
        else { return .gray }
    }
}