import SwiftUI
import Charts
import SwiftData

@available(tvOS 18.0, *)
struct TVHealthCategoryDetailView: View {
    let category: HealthCategory
    @Environment(\.modelContext) private var modelContext
    @Query private var healthRecords: [HealthData]
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
        case year = "1 Year"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: category.icon)
                            .font(.system(size: 60))
                            .foregroundColor(category.color)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.rawValue)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Detailed metrics and trends")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Time Range Picker
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 400)
                    }
                }
                
                // Key Metrics Section
                KeyMetricsSection(category: category, timeRange: selectedTimeRange)
                
                // Chart Section
                ChartSection(category: category, timeRange: selectedTimeRange)
                
                // Insights Section
                InsightsSection(category: category)
                
                // Recommendations Section
                RecommendationsSection(category: category)
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Key Metrics Section
@available(tvOS 18.0, *)
struct KeyMetricsSection: View {
    let category: HealthCategory
    let timeRange: TVHealthCategoryDetailView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Key Metrics")
                .font(.title)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 4), spacing: 30) {
                TVMetricCard(
                    title: "Current",
                    value: getCurrentValue(),
                    unit: getUnit(),
                    trend: "+2.3%",
                    trendDirection: .up
                )
                
                TVMetricCard(
                    title: "Average",
                    value: getAverageValue(),
                    unit: getUnit(),
                    trend: "+1.8%",
                    trendDirection: .up
                )
                
                TVMetricCard(
                    title: "High",
                    value: getHighValue(),
                    unit: getUnit(),
                    trend: "Today",
                    trendDirection: .neutral
                )
                
                TVMetricCard(
                    title: "Low",
                    value: getLowValue(),
                    unit: getUnit(),
                    trend: "Yesterday",
                    trendDirection: .neutral
                )
            }
        }
    }
    
    private func getCurrentValue() -> String {
        switch category {
        case .heartRate: return "72"
        case .steps: return "8,234"
        case .sleep: return "7.5"
        case .calories: return "2,145"
        case .activity: return "85"
        case .weight: return "165.2"
        case .bloodPressure: return "120/80"
        case .glucose: return "95"
        case .oxygen: return "98"
        case .respiratory: return "16"
        }
    }
    
    private func getAverageValue() -> String {
        switch category {
        case .heartRate: return "68"
        case .steps: return "7,890"
        case .sleep: return "7.8"
        case .calories: return "1,980"
        case .activity: return "82"
        case .weight: return "165.5"
        case .bloodPressure: return "118/78"
        case .glucose: return "92"
        case .oxygen: return "97"
        case .respiratory: return "15"
        }
    }
    
    private func getHighValue() -> String {
        switch category {
        case .heartRate: return "85"
        case .steps: return "12,450"
        case .sleep: return "8.5"
        case .calories: return "2,890"
        case .activity: return "95"
        case .weight: return "166.1"
        case .bloodPressure: return "125/85"
        case .glucose: return "105"
        case .oxygen: return "99"
        case .respiratory: return "18"
        }
    }
    
    private func getLowValue() -> String {
        switch category {
        case .heartRate: return "58"
        case .steps: return "3,210"
        case .sleep: return "6.2"
        case .calories: return "1,450"
        case .activity: return "65"
        case .weight: return "164.8"
        case .bloodPressure: return "110/70"
        case .glucose: return "85"
        case .oxygen: return "95"
        case .respiratory: return "12"
        }
    }
    
    private func getUnit() -> String {
        switch category {
        case .heartRate: return "BPM"
        case .steps: return "steps"
        case .sleep: return "hours"
        case .calories: return "kcal"
        case .activity: return "%"
        case .weight: return "lbs"
        case .bloodPressure: return "mmHg"
        case .glucose: return "mg/dL"
        case .oxygen: return "%"
        case .respiratory: return "breaths/min"
        }
    }
}

// MARK: - Chart Section
@available(tvOS 18.0, *)
struct ChartSection: View {
    let category: HealthCategory
    let timeRange: TVHealthCategoryDetailView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Trends")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                // Main Chart
                Chart {
                    ForEach(getChartData(), id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.value)
                        )
                        .foregroundStyle(category.color)
                        .lineStyle(StrokeStyle(lineWidth: 4))
                        
                        AreaMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Value", dataPoint.value)
                        )
                        .foregroundStyle(category.color.opacity(0.1))
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
                
                // Chart Legend
                HStack {
                    Circle()
                        .fill(category.color)
                        .frame(width: 16, height: 16)
                    
                    Text("\(category.rawValue) over time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    private func getChartData() -> [ChartDataPoint] {
        // Generate sample data based on category and time range
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [ChartDataPoint] = []
        
        let numberOfPoints: Int
        switch timeRange {
        case .day: numberOfPoints = 24
        case .week: numberOfPoints = 7
        case .month: numberOfPoints = 30
        case .year: numberOfPoints = 12
        }
        
        for i in 0..<numberOfPoints {
            let date: Date
            switch timeRange {
            case .day:
                date = calendar.date(byAdding: .hour, value: -i, to: now) ?? now
            case .week:
                date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            case .month:
                date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            case .year:
                date = calendar.date(byAdding: .month, value: -i, to: now) ?? now
            }
            
            let baseValue = getBaseValue()
            let randomVariation = Double.random(in: -0.1...0.1)
            let value = baseValue * (1 + randomVariation)
            
            dataPoints.append(ChartDataPoint(date: date, value: value))
        }
        
        return dataPoints.reversed()
    }
    
    private func getBaseValue() -> Double {
        switch category {
        case .heartRate: return 70.0
        case .steps: return 8000.0
        case .sleep: return 7.5
        case .calories: return 2000.0
        case .activity: return 80.0
        case .weight: return 165.0
        case .bloodPressure: return 120.0
        case .glucose: return 95.0
        case .oxygen: return 98.0
        case .respiratory: return 16.0
        }
    }
}

// MARK: - Insights Section
@available(tvOS 18.0, *)
struct InsightsSection: View {
    let category: HealthCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Insights")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                TVInsightRow(
                    icon: "lightbulb.fill",
                    title: "Positive Trend",
                    description: "Your \(category.rawValue.lowercased()) has improved by 5% this week compared to last week.",
                    color: .green
                )
                
                TVInsightRow(
                    icon: "clock.fill",
                    title: "Best Time",
                    description: "Your \(category.rawValue.lowercased()) is typically at its best between 6-8 AM.",
                    color: .blue
                )
                
                TVInsightRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Attention Needed",
                    description: "Consider increasing your daily \(category.rawValue.lowercased()) activity by 10% for optimal health.",
                    color: .orange
                )
            }
        }
    }
}

// MARK: - Recommendations Section
@available(tvOS 18.0, *)
struct RecommendationsSection: View {
    let category: HealthCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recommendations")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                TVRecommendationRow(
                    title: "Increase Activity",
                    description: "Try adding 10 more minutes of \(category.rawValue.lowercased()) activity daily.",
                    action: "View Plan"
                )
                
                TVRecommendationRow(
                    title: "Set Goal",
                    description: "Set a weekly goal to improve your \(category.rawValue.lowercased()) consistency.",
                    action: "Set Goal"
                )
                
                TVRecommendationRow(
                    title: "Share Progress",
                    description: "Share your \(category.rawValue.lowercased()) progress with family members.",
                    action: "Share"
                )
            }
        }
    }
}

// MARK: - Supporting Views

@available(tvOS 18.0, *)
struct TVMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: String
    let trendDirection: TVHealthCategoryDetailView.KeyMetricsSection.TrendDirection
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: trendDirection == .up ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                    .foregroundColor(trendDirection == .up ? .green : .red)
                
                Text(trend)
                    .font(.caption)
                    .foregroundColor(trendDirection == .up ? .green : .red)
            }
        }
        .frame(width: 200, height: 120)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

@available(tvOS 18.0, *)
struct TVInsightRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

@available(tvOS 18.0, *)
struct TVRecommendationRow: View {
    let title: String
    let description: String
    let action: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text(action)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(CardButtonStyle())
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Data Models
struct ChartDataPoint {
    let date: Date
    let value: Double
}

// MARK: - Preview
#Preview {
    TVHealthCategoryDetailView(category: .heartRate)
        .modelContainer(for: HealthData.self, inMemory: true)
} 