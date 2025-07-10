import SwiftUI
import Charts

// MARK: - Comparison Charts
/// Comprehensive comparison and benchmark chart components for HealthAI 2030
/// Provides before/after comparisons, benchmark comparisons, and trend comparisons
public struct ComparisonCharts {
    
    // MARK: - Before/After Comparison Charts
    
    /// Before/After comparison bar chart
    public struct BeforeAfterComparisonChart: View {
        let beforeData: [ComparisonDataPoint]
        let afterData: [ComparisonDataPoint]
        let title: String
        
        public init(beforeData: [ComparisonDataPoint], afterData: [ComparisonDataPoint], title: String) {
            self.beforeData = beforeData
            self.afterData = afterData
            self.title = title
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Chart {
                    ForEach(beforeData) { point in
                        BarMark(
                            x: .value("Category", point.category),
                            y: .value("Before", point.value)
                        )
                        .foregroundStyle(.red.opacity(0.7))
                        .position(by: .value("Period", "Before"))
                    }
                    
                    ForEach(afterData) { point in
                        BarMark(
                            x: .value("Category", point.category),
                            y: .value("After", point.value)
                        )
                        .foregroundStyle(.green.opacity(0.7))
                        .position(by: .value("Period", "After"))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let category = value.as(String.self) {
                                Text(category)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text("\(val, specifier: "%.1f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartLegend(position: .top, alignment: .center)
            }
        }
    }
    
    /// Before/After comparison line chart
    public struct BeforeAfterLineChart: View {
        let beforeData: [TimeSeriesDataPoint]
        let afterData: [TimeSeriesDataPoint]
        let title: String
        
        public init(beforeData: [TimeSeriesDataPoint], afterData: [TimeSeriesDataPoint], title: String) {
            self.beforeData = beforeData
            self.afterData = afterData
            self.title = title
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Chart {
                    ForEach(beforeData) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Before", point.value)
                        )
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 3, dash: [5, 5]))
                        .symbol(by: .value("Period", "Before"))
                    }
                    
                    ForEach(afterData) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("After", point.value)
                        )
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .symbol(by: .value("Period", "After"))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let timestamp = value.as(Date.self) {
                                Text(timestamp, format: .dateTime.day())
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text("\(val, specifier: "%.1f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartLegend(position: .top, alignment: .center)
            }
        }
    }
    
    // MARK: - Benchmark Comparison Charts
    
    /// Benchmark comparison radar chart
    public struct BenchmarkRadarChart: View {
        let userMetrics: [RadarMetric]
        let benchmarkMetrics: [RadarMetric]
        let title: String
        
        public init(userMetrics: [RadarMetric], benchmarkMetrics: [RadarMetric], title: String) {
            self.userMetrics = userMetrics
            self.benchmarkMetrics = benchmarkMetrics
            self.title = title
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                // Simplified radar chart using bar chart
                Chart {
                    ForEach(userMetrics) { metric in
                        BarMark(
                            x: .value("Metric", metric.name),
                            y: .value("User", metric.value)
                        )
                        .foregroundStyle(.blue.opacity(0.7))
                        .position(by: .value("Type", "User"))
                    }
                    
                    ForEach(benchmarkMetrics) { metric in
                        BarMark(
                            x: .value("Metric", metric.name),
                            y: .value("Benchmark", metric.value)
                        )
                        .foregroundStyle(.orange.opacity(0.7))
                        .position(by: .value("Type", "Benchmark"))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let metric = value.as(String.self) {
                                Text(metric)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text("\(val, specifier: "%.1f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartLegend(position: .top, alignment: .center)
            }
        }
    }
    
    /// Age group comparison chart
    public struct AgeGroupComparisonChart: View {
        let ageGroups: [AgeGroupData]
        let userAgeGroup: String
        
        public init(ageGroups: [AgeGroupData], userAgeGroup: String) {
            self.ageGroups = ageGroups
            self.userAgeGroup = userAgeGroup
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Age Group Comparison")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Chart {
                    ForEach(ageGroups) { group in
                        BarMark(
                            x: .value("Age Group", group.ageGroup),
                            y: .value("Average", group.averageValue)
                        )
                        .foregroundStyle(group.ageGroup == userAgeGroup ? .blue : .gray.opacity(0.6))
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let ageGroup = value.as(String.self) {
                                Text(ageGroup)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text("\(val, specifier: "%.1f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Population percentile chart
    public struct PercentileChart: View {
        let userValue: Double
        let percentileData: [PercentileDataPoint]
        let metricName: String
        
        public init(userValue: Double, percentileData: [PercentileDataPoint], metricName: String) {
            self.userValue = userValue
            self.percentileData = percentileData
            self.metricName = metricName
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(metricName) Percentile")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Chart {
                    ForEach(percentileData) { point in
                        LineMark(
                            x: .value("Percentile", point.percentile),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }
                    
                    RuleMark(x: .value("User", calculateUserPercentile()))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .annotation(position: .top) {
                            Text("You")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let percentile = value.as(Double.self) {
                                Text("\(Int(percentile))%")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text("\(val, specifier: "%.1f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        
        private func calculateUserPercentile() -> Double {
            // Simple percentile calculation
            let sortedValues = percentileData.map { $0.value }.sorted()
            guard let userIndex = sortedValues.firstIndex(where: { $0 >= userValue }) else {
                return 100.0
            }
            return Double(userIndex) / Double(sortedValues.count - 1) * 100
        }
    }
    
    // MARK: - Trend Comparison Charts
    
    /// Multi-period trend comparison
    public struct MultiPeriodTrendChart: View {
        let periods: [PeriodData]
        let title: String
        
        public init(periods: [PeriodData], title: String) {
            self.periods = periods
            self.title = title
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Chart {
                    ForEach(periods) { period in
                        ForEach(period.dataPoints) { point in
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(period.color)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            .symbol(by: .value("Period", period.name))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let timestamp = value.as(Date.self) {
                                Text(timestamp, format: .dateTime.day())
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text("\(val, specifier: "%.1f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartLegend(position: .top, alignment: .center)
            }
        }
    }
    
    /// Year-over-year comparison
    public struct YearOverYearChart: View {
        let currentYear: [MonthlyDataPoint]
        let previousYear: [MonthlyDataPoint]
        let metricName: String
        
        public init(currentYear: [MonthlyDataPoint], previousYear: [MonthlyDataPoint], metricName: String) {
            self.currentYear = currentYear
            self.previousYear = previousYear
            self.metricName = metricName
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(metricName) - Year over Year")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Chart {
                    ForEach(currentYear) { point in
                        LineMark(
                            x: .value("Month", point.month),
                            y: .value("Current Year", point.value)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .symbol(by: .value("Year", "Current"))
                    }
                    
                    ForEach(previousYear) { point in
                        LineMark(
                            x: .value("Month", point.month),
                            y: .value("Previous Year", point.value)
                        )
                        .foregroundStyle(.gray)
                        .lineStyle(StrokeStyle(lineWidth: 3, dash: [5, 5]))
                        .symbol(by: .value("Year", "Previous"))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let month = value.as(String.self) {
                                Text(month)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text("\(val, specifier: "%.1f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartLegend(position: .top, alignment: .center)
            }
        }
    }
}

// MARK: - Data Models

public struct ComparisonDataPoint: Identifiable {
    public let id = UUID()
    public let category: String
    public let value: Double
    
    public init(category: String, value: Double) {
        self.category = category
        self.value = value
    }
}

public struct TimeSeriesDataPoint: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let value: Double
    
    public init(timestamp: Date, value: Double) {
        self.timestamp = timestamp
        self.value = value
    }
}

public struct RadarMetric: Identifiable {
    public let id = UUID()
    public let name: String
    public let value: Double
    
    public init(name: String, value: Double) {
        self.name = name
        self.value = value
    }
}

public struct AgeGroupData: Identifiable {
    public let id = UUID()
    public let ageGroup: String
    public let averageValue: Double
    
    public init(ageGroup: String, averageValue: Double) {
        self.ageGroup = ageGroup
        self.averageValue = averageValue
    }
}

public struct PercentileDataPoint: Identifiable {
    public let id = UUID()
    public let percentile: Double
    public let value: Double
    
    public init(percentile: Double, value: Double) {
        self.percentile = percentile
        self.value = value
    }
}

public struct PeriodData: Identifiable {
    public let id = UUID()
    public let name: String
    public let dataPoints: [TimeSeriesDataPoint]
    public let color: Color
    
    public init(name: String, dataPoints: [TimeSeriesDataPoint], color: Color) {
        self.name = name
        self.dataPoints = dataPoints
        self.color = color
    }
}

public struct MonthlyDataPoint: Identifiable {
    public let id = UUID()
    public let month: String
    public let value: Double
    
    public init(month: String, value: Double) {
        self.month = month
        self.value = value
    }
} 