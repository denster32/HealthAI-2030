import SwiftUI
import SwiftData
import Charts

/// Comprehensive analytics view displaying health insights and trends
struct AnalyticsView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var errorHandler = ErrorHandlingService.shared
    @Query(sort: [SortDescriptor(\HealthData.timestamp, order: .reverse)]) private var healthData: [HealthData]
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetric: HealthMetric = .heartRate
    @State private var showingInsights = false
    
    enum HealthMetric: String, CaseIterable {
        case heartRate = "Heart Rate"
        case steps = "Steps"
        case sleep = "Sleep"
        case stress = "Stress"
        case hrv = "HRV"
        case oxygenSaturation = "Oxygen Saturation"
        
        var icon: String {
            switch self {
            case .heartRate: return "heart.fill"
            case .steps: return "figure.walk"
            case .sleep: return "bed.double.fill"
            case .stress: return "brain.head.profile"
            case .hrv: return "waveform.path.ecg"
            case .oxygenSaturation: return "lungs.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .heartRate: return .red
            case .steps: return .green
            case .sleep: return .blue
            case .stress: return .orange
            case .hrv: return .purple
            case .oxygenSaturation: return .cyan
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Metric selector
                    metricSelector
                    
                    // Main chart
                    mainChart
                    
                    // Statistics
                    statisticsSection
                    
                    // Insights
                    insightsSection
                    
                    // Trends
                    trendsSection
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshAnalytics()
            }
            .alert("Error", isPresented: $errorHandler.showingError) {
                Button("OK") { errorHandler.dismissError() }
            } message: {
                Text(errorHandler.currentErrorMessage)
            }
            .sheet(isPresented: $showingInsights) {
                InsightsDetailView(metric: selectedMetric)
            }
        }
    }
    
    private var metricSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Metric")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(HealthMetric.allCases, id: \.self) { metric in
                    MetricSelectorButton(
                        metric: metric,
                        isSelected: selectedMetric == metric
                    ) {
                        selectedMetric = metric
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var mainChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(selectedMetric.rawValue) Trends")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            if #available(iOS 17.0, *) {
                Chart(filteredHealthData) { data in
                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value(selectedMetric.rawValue, metricValue(for: data))
                    )
                    .foregroundStyle(selectedMetric.color)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", data.timestamp),
                        y: .value(selectedMetric.rawValue, metricValue(for: data))
                    )
                    .foregroundStyle(selectedMetric.color.opacity(0.1))
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: timeStride)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: timeFormat)
                    }
                }
            } else {
                // Fallback for iOS 16
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 250)
                    .overlay(
                        Text("Charts available in iOS 17+")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticCard(
                    title: "Average",
                    value: String(format: "%.1f", averageValue),
                    unit: selectedMetric.unit,
                    color: selectedMetric.color
                )
                
                StatisticCard(
                    title: "Maximum",
                    value: String(format: "%.1f", maximumValue),
                    unit: selectedMetric.unit,
                    color: selectedMetric.color
                )
                
                StatisticCard(
                    title: "Minimum",
                    value: String(format: "%.1f", minimumValue),
                    unit: selectedMetric.unit,
                    color: selectedMetric.color
                )
                
                StatisticCard(
                    title: "Trend",
                    value: trendDescription,
                    unit: "",
                    color: trendColor
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingInsights = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            VStack(spacing: 12) {
                InsightCard(
                    title: "Health Trend",
                    description: "Your \(selectedMetric.rawValue.lowercased()) has been \(trendDirection) over the past \(selectedTimeRange.displayName.lowercased()).",
                    icon: "chart.line.uptrend.xyaxis",
                    color: trendColor
                )
                
                InsightCard(
                    title: "Recommendation",
                    description: generateRecommendation(),
                    icon: "lightbulb.fill",
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TrendRow(
                    title: "Daily Pattern",
                    description: "Peak activity around 2 PM",
                    trend: .increasing,
                    color: .green
                )
                
                TrendRow(
                    title: "Weekly Pattern",
                    description: "Lower activity on weekends",
                    trend: .decreasing,
                    color: .orange
                )
                
                TrendRow(
                    title: "Monthly Pattern",
                    description: "Consistent improvement",
                    trend: .increasing,
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Computed Properties
    
    private var filteredHealthData: [HealthData] {
        let cutoff = Date().addingTimeInterval(-selectedTimeRange.interval)
        return healthData.filter { $0.timestamp >= cutoff }
    }
    
    private var timeStride: Calendar.Component {
        switch selectedTimeRange {
        case .day: return .hour
        case .week: return .day
        case .month: return .weekOfMonth
        }
    }
    
    private var timeFormat: Date.FormatStyle {
        switch selectedTimeRange {
        case .day: return .dateTime.hour()
        case .week: return .dateTime.weekday()
        case .month: return .dateTime.month()
        }
    }
    
    private func metricValue(for data: HealthData) -> Double {
        switch selectedMetric {
        case .heartRate: return data.heartRate
        case .steps: return Double(data.steps)
        case .sleep: return data.sleepHours
        case .stress: return data.stressLevel
        case .hrv: return data.heartRateVariability
        case .oxygenSaturation: return data.oxygenSaturation
        }
    }
    
    private var averageValue: Double {
        let values = filteredHealthData.map { metricValue(for: $0) }.filter { $0 > 0 }
        return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }
    
    private var maximumValue: Double {
        let values = filteredHealthData.map { metricValue(for: $0) }.filter { $0 > 0 }
        return values.max() ?? 0
    }
    
    private var minimumValue: Double {
        let values = filteredHealthData.map { metricValue(for: $0) }.filter { $0 > 0 }
        return values.min() ?? 0
    }
    
    private var trendDescription: String {
        let trend = calculateTrend()
        switch trend {
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        case .stable: return "Stable"
        }
    }
    
    private var trendColor: Color {
        let trend = calculateTrend()
        switch trend {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .gray
        }
    }
    
    private var trendDirection: String {
        let trend = calculateTrend()
        switch trend {
        case .increasing: return "improving"
        case .decreasing: return "declining"
        case .stable: return "stable"
        }
    }
    
    private func calculateTrend() -> Trend {
        guard filteredHealthData.count >= 2 else { return .stable }
        
        let values = filteredHealthData.map { metricValue(for: $0) }.filter { $0 > 0 }
        guard values.count >= 2 else { return .stable }
        
        let recent = Array(values.prefix(values.count / 2))
        let older = Array(values.suffix(values.count / 2))
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)
        
        let change = recentAvg - olderAvg
        let percentChange = (change / olderAvg) * 100
        
        if percentChange > 5 {
            return .increasing
        } else if percentChange < -5 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private func generateRecommendation() -> String {
        let trend = calculateTrend()
        switch (selectedMetric, trend) {
        case (.heartRate, .increasing):
            return "Consider stress management techniques to help lower your heart rate."
        case (.steps, .decreasing):
            return "Try to increase your daily step count by taking short walks."
        case (.sleep, .decreasing):
            return "Focus on maintaining a consistent sleep schedule."
        case (.stress, .increasing):
            return "Practice mindfulness or meditation to reduce stress levels."
        default:
            return "Continue monitoring your \(selectedMetric.rawValue.lowercased()) for optimal health."
        }
    }
    
    // MARK: - Actions
    
    private func refreshAnalytics() async {
        // Implement analytics refresh logic
    }
}

// MARK: - Supporting Views

struct MetricSelectorButton: View {
    let metric: AnalyticsView.HealthMetric
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: metric.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : metric.color)
                
                Text(metric.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? metric.color : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Select \(metric.rawValue) metric")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct InsightCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TrendRow: View {
    let title: String
    let description: String
    let trend: Trend
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: trend.iconName)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Types

extension AnalyticsView.HealthMetric {
    var unit: String {
        switch self {
        case .heartRate: return "BPM"
        case .steps: return "steps"
        case .sleep: return "hours"
        case .stress: return "%"
        case .hrv: return "ms"
        case .oxygenSaturation: return "%"
        }
    }
}

// Placeholder views
struct InsightsDetailView: View {
    let metric: AnalyticsView.HealthMetric
    
    var body: some View {
        NavigationStack {
            Text("Detailed insights for \(metric.rawValue)")
                .navigationTitle("\(metric.rawValue) Insights")
        }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [UserProfile.self, HealthData.self, DigitalTwin.self], isCloudKitEnabled: true)
}