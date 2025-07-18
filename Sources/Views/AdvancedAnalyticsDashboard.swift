import SwiftUI
import Charts
import Combine
import HealthKit

/// Advanced Health Analytics Dashboard for HealthAI 2030
/// Provides comprehensive health analytics with real-time data visualization
@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedAnalyticsDashboard: View {
    
    // MARK: - State Management
    @StateObject private var viewModel = AdvancedAnalyticsViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetrics: Set<HealthMetric> = [.heartRate, .steps, .sleep]
    @State private var showingCustomization = false
    @State private var showingExport = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with controls
                    headerSection
                    
                    // Key metrics overview
                    keyMetricsSection
                    
                    // Charts and visualizations
                    chartsSection
                    
                    // Health insights
                    insightsSection
                    
                    // Predictive analytics
                    predictiveSection
                    
                    // Custom analytics
                    customAnalyticsSection
                }
                .padding()
            }
            .navigationTitle("Health Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Customize") {
                        showingCustomization = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        showingExport = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingCustomization) {
            AnalyticsCustomizationView(
                selectedMetrics: $selectedMetrics,
                selectedTimeRange: $selectedTimeRange
            )
        }
        .sheet(isPresented: $showingExport) {
            AnalyticsExportView(data: viewModel.exportData())
        }
        .onAppear {
            viewModel.loadAnalyticsData(timeRange: selectedTimeRange, metrics: selectedMetrics)
        }
        .onChange(of: selectedTimeRange) { _ in
            viewModel.loadAnalyticsData(timeRange: selectedTimeRange, metrics: selectedMetrics)
        }
        .onChange(of: selectedMetrics) { _ in
            viewModel.loadAnalyticsData(timeRange: selectedTimeRange, metrics: selectedMetrics)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Analytics Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Real-time insights powered by AI")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Last updated
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Last updated: \(viewModel.lastUpdated, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Refresh") {
                    viewModel.refreshData()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Key Metrics Section
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Health Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricCard(
                    title: "Heart Rate",
                    value: "\(Int(viewModel.averageHeartRate))",
                    unit: "BPM",
                    trend: viewModel.heartRateTrend,
                    color: .red
                )
                
                MetricCard(
                    title: "Steps",
                    value: "\(viewModel.totalSteps)",
                    unit: "steps",
                    trend: viewModel.stepsTrend,
                    color: .green
                )
                
                MetricCard(
                    title: "Sleep",
                    value: String(format: "%.1f", viewModel.averageSleepHours),
                    unit: "hours",
                    trend: viewModel.sleepTrend,
                    color: .blue
                )
                
                MetricCard(
                    title: "Health Score",
                    value: "\(viewModel.healthScore)",
                    unit: "/100",
                    trend: viewModel.healthScoreTrend,
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Charts Section
    
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Heart rate chart
            if selectedMetrics.contains(.heartRate) {
                ChartCard(title: "Heart Rate Over Time") {
                    HeartRateChart(data: viewModel.heartRateData)
                }
            }
            
            // Steps chart
            if selectedMetrics.contains(.steps) {
                ChartCard(title: "Daily Steps") {
                    StepsChart(data: viewModel.stepsData)
                }
            }
            
            // Sleep chart
            if selectedMetrics.contains(.sleep) {
                ChartCard(title: "Sleep Patterns") {
                    SleepChart(data: viewModel.sleepData)
                }
            }
            
            // Activity chart
            if selectedMetrics.contains(.activity) {
                ChartCard(title: "Activity Levels") {
                    ActivityChart(data: viewModel.activityData)
                }
            }
        }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Health Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(viewModel.healthInsights, id: \.id) { insight in
                InsightCard(insight: insight)
            }
        }
    }
    
    // MARK: - Predictive Section
    
    private var predictiveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Predictive Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Health predictions
            VStack(spacing: 12) {
                PredictionCard(
                    title: "Health Risk Assessment",
                    prediction: viewModel.healthRiskPrediction,
                    confidence: viewModel.healthRiskConfidence
                )
                
                PredictionCard(
                    title: "Optimal Exercise Time",
                    prediction: viewModel.optimalExerciseTime,
                    confidence: viewModel.exerciseTimeConfidence
                )
                
                PredictionCard(
                    title: "Sleep Quality Forecast",
                    prediction: viewModel.sleepQualityForecast,
                    confidence: viewModel.sleepQualityConfidence
                )
            }
        }
    }
    
    // MARK: - Custom Analytics Section
    
    private var customAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Correlation analysis
            if viewModel.showCorrelationAnalysis {
                CorrelationAnalysisView(correlations: viewModel.correlations)
            }
            
            // Anomaly detection
            if viewModel.showAnomalyDetection {
                AnomalyDetectionView(anomalies: viewModel.anomalies)
            }
            
            // Trend analysis
            if viewModel.showTrendAnalysis {
                TrendAnalysisView(trends: viewModel.trends)
            }
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: TrendDirection
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: trend.iconName)
                    .foregroundColor(trend.color)
                    .font(.caption)
            }
            
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct InsightCard: View {
    let insight: HealthInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insight.iconName)
                    .foregroundColor(insight.color)
                
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(insight.severity.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(insight.severity.color.opacity(0.2))
                    .foregroundColor(insight.severity.color)
                    .cornerRadius(8)
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let recommendation = insight.recommendation {
                Text("Recommendation: \(recommendation)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PredictionCard: View {
    let title: String
    let prediction: String
    let confidence: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(prediction)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Confidence:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: confidence)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 100)
                
                Text("\(Int(confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Chart Views

struct HeartRateChart: View {
    let data: [HeartRateDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Heart Rate", point.heartRate)
            )
            .foregroundStyle(.red)
            
            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value("Heart Rate", point.heartRate)
            )
            .foregroundStyle(.red.opacity(0.1))
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct StepsChart: View {
    let data: [StepsDataPoint]
    
    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Date", point.date),
                y: .value("Steps", point.steps)
            )
            .foregroundStyle(.green)
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct SleepChart: View {
    let data: [SleepDataPoint]
    
    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Date", point.date),
                y: .value("Hours", point.hours)
            )
            .foregroundStyle(.blue)
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct ActivityChart: View {
    let data: [ActivityDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Activity", point.activityLevel)
            )
            .foregroundStyle(.orange)
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

// MARK: - Supporting Types

enum TimeRange: CaseIterable {
    case day, week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .day: return "24 Hours"
        case .week: return "7 Days"
        case .month: return "30 Days"
        case .quarter: return "3 Months"
        case .year: return "1 Year"
        }
    }
}

enum HealthMetric: CaseIterable {
    case heartRate, steps, sleep, activity, calories, weight, bloodPressure
    
    var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .steps: return "Steps"
        case .sleep: return "Sleep"
        case .activity: return "Activity"
        case .calories: return "Calories"
        case .weight: return "Weight"
        case .bloodPressure: return "Blood Pressure"
        }
    }
}

enum TrendDirection {
    case up, down, stable
    
    var iconName: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

enum InsightSeverity {
    case low, medium, high, critical
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct HealthInsight {
    let id = UUID()
    let title: String
    let description: String
    let recommendation: String?
    let severity: InsightSeverity
    let iconName: String
    let color: Color
}

struct HeartRateDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let heartRate: Double
}

struct StepsDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
}

struct SleepDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
}

struct ActivityDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let activityLevel: Double
}

// MARK: - View Model

@available(iOS 18.0, macOS 15.0, *)
class AdvancedAnalyticsViewModel: ObservableObject {
    @Published var lastUpdated = Date()
    @Published var averageHeartRate: Double = 0
    @Published var totalSteps: Int = 0
    @Published var averageSleepHours: Double = 0
    @Published var healthScore: Int = 0
    
    @Published var heartRateTrend: TrendDirection = .stable
    @Published var stepsTrend: TrendDirection = .stable
    @Published var sleepTrend: TrendDirection = .stable
    @Published var healthScoreTrend: TrendDirection = .stable
    
    @Published var heartRateData: [HeartRateDataPoint] = []
    @Published var stepsData: [StepsDataPoint] = []
    @Published var sleepData: [SleepDataPoint] = []
    @Published var activityData: [ActivityDataPoint] = []
    
    @Published var healthInsights: [HealthInsight] = []
    @Published var healthRiskPrediction = ""
    @Published var healthRiskConfidence: Double = 0
    @Published var optimalExerciseTime = ""
    @Published var exerciseTimeConfidence: Double = 0
    @Published var sleepQualityForecast = ""
    @Published var sleepQualityConfidence: Double = 0
    
    @Published var showCorrelationAnalysis = true
    @Published var showAnomalyDetection = true
    @Published var showTrendAnalysis = true
    
    @Published var correlations: [String] = []
    @Published var anomalies: [String] = []
    @Published var trends: [String] = []
    
    func loadAnalyticsData(timeRange: TimeRange, metrics: Set<HealthMetric>) {
        // Load analytics data based on selected time range and metrics
        generateMockData(timeRange: timeRange, metrics: metrics)
        generateInsights()
        generatePredictions()
        lastUpdated = Date()
    }
    
    func refreshData() {
        // Refresh all analytics data
        loadAnalyticsData(timeRange: .week, metrics: [.heartRate, .steps, .sleep])
    }
    
    func exportData() -> [String: Any] {
        // Export analytics data
        return [
            "heartRate": averageHeartRate,
            "steps": totalSteps,
            "sleep": averageSleepHours,
            "healthScore": healthScore,
            "insights": healthInsights.map { $0.title }
        ]
    }
    
    private func generateMockData(timeRange: TimeRange, metrics: Set<HealthMetric>) {
        // Generate mock data for demonstration
        averageHeartRate = Double.random(in: 60...100)
        totalSteps = Int.random(in: 5000...15000)
        averageSleepHours = Double.random(in: 6...9)
        healthScore = Int.random(in: 70...95)
        
        // Generate trend data
        heartRateTrend = [.up, .down, .stable].randomElement()!
        stepsTrend = [.up, .down, .stable].randomElement()!
        sleepTrend = [.up, .down, .stable].randomElement()!
        healthScoreTrend = [.up, .down, .stable].randomElement()!
        
        // Generate chart data
        generateChartData(timeRange: timeRange)
    }
    
    private func generateChartData(timeRange: TimeRange) {
        let calendar = Calendar.current
        let now = Date()
        
        // Generate heart rate data
        heartRateData = (0..<24).map { hour in
            let timestamp = calendar.date(byAdding: .hour, value: -hour, to: now)!
            return HeartRateDataPoint(
                timestamp: timestamp,
                heartRate: Double.random(in: 60...100)
            )
        }.reversed()
        
        // Generate steps data
        stepsData = (0..<7).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            return StepsDataPoint(
                date: date,
                steps: Int.random(in: 5000...15000)
            )
        }.reversed()
        
        // Generate sleep data
        sleepData = (0..<7).map { day in
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            return SleepDataPoint(
                date: date,
                hours: Double.random(in: 6...9)
            )
        }.reversed()
        
        // Generate activity data
        activityData = (0..<24).map { hour in
            let timestamp = calendar.date(byAdding: .hour, value: -hour, to: now)!
            return ActivityDataPoint(
                timestamp: timestamp,
                activityLevel: Double.random(in: 0...1)
            )
        }.reversed()
    }
    
    private func generateInsights() {
        healthInsights = [
            HealthInsight(
                title: "Heart Rate Variability Improving",
                description: "Your HRV has increased by 15% over the past week, indicating better cardiovascular health.",
                recommendation: "Continue your current exercise routine",
                severity: .low,
                iconName: "heart.fill",
                color: .green
            ),
            HealthInsight(
                title: "Sleep Quality Declining",
                description: "Sleep efficiency has decreased by 8% this week. Consider adjusting your bedtime routine.",
                recommendation: "Try going to bed 30 minutes earlier",
                severity: .medium,
                iconName: "bed.double.fill",
                color: .orange
            ),
            HealthInsight(
                title: "Activity Level Optimal",
                description: "You're meeting your daily activity goals consistently. Great job!",
                recommendation: nil,
                severity: .low,
                iconName: "figure.walk",
                color: .blue
            )
        ]
    }
    
    private func generatePredictions() {
        healthRiskPrediction = "Low risk of cardiovascular issues in the next 30 days"
        healthRiskConfidence = 0.85
        
        optimalExerciseTime = "Between 6:00 AM and 8:00 AM"
        exerciseTimeConfidence = 0.78
        
        sleepQualityForecast = "Expected to improve by 12% with current routine"
        sleepQualityConfidence = 0.72
    }
}

// MARK: - Customization and Export Views

struct AnalyticsCustomizationView: View {
    @Binding var selectedMetrics: Set<HealthMetric>
    @Binding var selectedTimeRange: TimeRange
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time Range") {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Metrics to Display") {
                    ForEach(HealthMetric.allCases, id: \.self) { metric in
                        Toggle(metric.displayName, isOn: Binding(
                            get: { selectedMetrics.contains(metric) },
                            set: { isSelected in
                                if isSelected {
                                    selectedMetrics.insert(metric)
                                } else {
                                    selectedMetrics.remove(metric)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Customize Analytics")
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

struct AnalyticsExportView: View {
    let data: [String: Any]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Analytics Data Export")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(data.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(data[key] ?? "N/A")")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Button("Export as JSON") {
                    // Export functionality
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationTitle("Export Data")
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

// MARK: - Additional Analysis Views

struct CorrelationAnalysisView: View {
    let correlations: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Correlation Analysis")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(correlations, id: \.self) { correlation in
                Text("• \(correlation)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct AnomalyDetectionView: View {
    let anomalies: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Anomaly Detection")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(anomalies, id: \.self) { anomaly in
                Text("⚠️ \(anomaly)")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct TrendAnalysisView: View {
    let trends: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trend Analysis")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(trends, id: \.self) { trend in
                Text("📈 \(trend)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Preview

@available(iOS 18.0, macOS 15.0, *)
struct AdvancedAnalyticsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedAnalyticsDashboard()
    }
} 