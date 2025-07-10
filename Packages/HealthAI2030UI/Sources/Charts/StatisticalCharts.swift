import SwiftUI
import Charts

// MARK: - Statistical Charts
/// Comprehensive statistical and distribution chart components for HealthAI 2030
/// Provides histograms, box plots, scatter plots, and correlation charts
public struct StatisticalCharts {
    
    // MARK: - Distribution Charts
    
    /// Histogram for data distribution
    public struct HistogramChart: View {
        let data: [HistogramBin]
        let title: String
        let xAxisLabel: String
        let yAxisLabel: String
        
        public init(data: [HistogramBin], title: String, xAxisLabel: String = "Value", yAxisLabel: String = "Frequency") {
            self.data = data
            self.title = title
            self.xAxisLabel = xAxisLabel
            self.yAxisLabel = yAxisLabel
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Chart {
                    ForEach(data) { bin in
                        BarMark(
                            x: .value("Range", "\(bin.minValue, specifier: "%.1f")-\(bin.maxValue, specifier: "%.1f")"),
                            y: .value("Frequency", bin.frequency)
                        )
                        .foregroundStyle(.blue.gradient)
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let range = value.as(String.self) {
                                Text(range)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let frequency = value.as(Double.self) {
                                Text("\(Int(frequency))")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                HStack {
                    Text(xAxisLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(yAxisLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    /// Box plot for statistical summary
    public struct BoxPlotChart: View {
        let data: [BoxPlotData]
        let title: String
        
        public init(data: [BoxPlotData], title: String) {
            self.data = data
            self.title = title
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Chart {
                    ForEach(data) { item in
                        RectangleMark(
                            x: .value("Category", item.category),
                            yStart: .value("Q1", item.q1),
                            yEnd: .value("Q3", item.q3),
                            width: 40
                        )
                        .foregroundStyle(.blue.opacity(0.6))
                        
                        RectangleMark(
                            x: .value("Category", item.category),
                            yStart: .value("Min", item.min),
                            yEnd: .value("Max", item.max),
                            width: 2
                        )
                        .foregroundStyle(.blue)
                        
                        PointMark(
                            x: .value("Category", item.category),
                            y: .value("Median", item.median)
                        )
                        .foregroundStyle(.white)
                        .symbolSize(20)
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
            }
        }
    }
    
    /// Normal distribution curve
    public struct NormalDistributionChart: View {
        let data: [DistributionPoint]
        let mean: Double
        let standardDeviation: Double
        let title: String
        
        public init(data: [DistributionPoint], mean: Double, standardDeviation: Double, title: String) {
            self.data = data
            self.mean = mean
            self.standardDeviation = standardDeviation
            self.title = title
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Chart {
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Value", point.value),
                            y: .value("Density", point.density)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.catmullRom)
                    }
                    
                    RuleMark(x: .value("Mean", mean))
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .annotation(position: .top) {
                            Text("Mean")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                Text("\(val, specifier: "%.1f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let density = value.as(Double.self) {
                                Text("\(density, specifier: "%.3f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                HStack {
                    Text("Mean: \(mean, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("SD: \(standardDeviation, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Correlation Charts
    
    /// Scatter plot for correlation analysis
    public struct ScatterPlotChart: View {
        let data: [ScatterDataPoint]
        let title: String
        let xAxisLabel: String
        let yAxisLabel: String
        let showTrendLine: Bool
        
        public init(data: [ScatterDataPoint], title: String, xAxisLabel: String, yAxisLabel: String, showTrendLine: Bool = true) {
            self.data = data
            self.title = title
            self.xAxisLabel = xAxisLabel
            self.yAxisLabel = yAxisLabel
            self.showTrendLine = showTrendLine
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Chart {
                    ForEach(data) { point in
                        PointMark(
                            x: .value(xAxisLabel, point.x),
                            y: .value(yAxisLabel, point.y)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(50)
                    }
                    
                    if showTrendLine {
                        let trendData = calculateTrendLine()
                        ForEach(trendData, id: \.x) { point in
                            LineMark(
                                x: .value(xAxisLabel, point.x),
                                y: .value(yAxisLabel, point.y)
                            )
                            .foregroundStyle(.red)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let x = value.as(Double.self) {
                                Text("\(x, specifier: "%.1f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let y = value.as(Double.self) {
                                Text("\(y, specifier: "%.1f")")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                HStack {
                    Text(xAxisLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(yAxisLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        
        private func calculateTrendLine() -> [ScatterDataPoint] {
            guard data.count > 1 else { return [] }
            
            let n = Double(data.count)
            let sumX = data.reduce(0) { $0 + $1.x }
            let sumY = data.reduce(0) { $0 + $1.y }
            let sumXY = data.reduce(0) { $0 + $1.x * $1.y }
            let sumX2 = data.reduce(0) { $0 + $1.x * $1.x }
            
            let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
            let intercept = (sumY - slope * sumX) / n
            
            let minX = data.map { $0.x }.min() ?? 0
            let maxX = data.map { $0.x }.max() ?? 1
            
            return [
                ScatterDataPoint(x: minX, y: slope * minX + intercept),
                ScatterDataPoint(x: maxX, y: slope * maxX + intercept)
            ]
        }
    }
    
    /// Correlation matrix heatmap
    public struct CorrelationHeatmap: View {
        let correlations: [CorrelationData]
        let title: String
        
        public init(correlations: [CorrelationData], title: String) {
            self.correlations = correlations
            self.title = title
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(correlations) { correlation in
                        VStack(spacing: 4) {
                            Text(correlation.variable1)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text("\(correlation.correlation, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(correlationColor(correlation.correlation))
                            
                            Text(correlation.variable2)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(8)
                        .background(correlationColor(correlation.correlation).opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        
        private func correlationColor(_ correlation: Double) -> Color {
            let absCorrelation = abs(correlation)
            if absCorrelation > 0.7 {
                return correlation > 0 ? .green : .red
            } else if absCorrelation > 0.3 {
                return correlation > 0 ? .blue : .orange
            } else {
                return .gray
            }
        }
    }
    
    // MARK: - Statistical Summary Charts
    
    /// Statistical summary card
    public struct StatisticalSummaryCard: View {
        let data: [Double]
        let title: String
        
        public init(data: [Double], title: String) {
            self.data = data
            self.title = title
        }
        
        private var statistics: Statistics {
            calculateStatistics(data)
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 8) {
                    StatRow(label: "Count", value: "\(data.count)")
                    StatRow(label: "Mean", value: String(format: "%.2f", statistics.mean))
                    StatRow(label: "Median", value: String(format: "%.2f", statistics.median))
                    StatRow(label: "Std Dev", value: String(format: "%.2f", statistics.standardDeviation))
                    StatRow(label: "Min", value: String(format: "%.2f", statistics.min))
                    StatRow(label: "Max", value: String(format: "%.2f", statistics.max))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        
        private func calculateStatistics(_ data: [Double]) -> Statistics {
            let sorted = data.sorted()
            let count = Double(data.count)
            let sum = data.reduce(0, +)
            let mean = sum / count
            
            let variance = data.reduce(0) { $0 + pow($1 - mean, 2) } / count
            let standardDeviation = sqrt(variance)
            
            let median: Double
            if count.truncatingRemainder(dividingBy: 2) == 0 {
                let mid = Int(count / 2)
                median = (sorted[mid - 1] + sorted[mid]) / 2
            } else {
                median = sorted[Int(count / 2)]
            }
            
            return Statistics(
                count: data.count,
                mean: mean,
                median: median,
                standardDeviation: standardDeviation,
                min: sorted.first ?? 0,
                max: sorted.last ?? 0
            )
        }
    }
}

// MARK: - Data Models

public struct HistogramBin: Identifiable {
    public let id = UUID()
    public let minValue: Double
    public let maxValue: Double
    public let frequency: Double
    
    public init(minValue: Double, maxValue: Double, frequency: Double) {
        self.minValue = minValue
        self.maxValue = maxValue
        self.frequency = frequency
    }
}

public struct BoxPlotData: Identifiable {
    public let id = UUID()
    public let category: String
    public let min: Double
    public let q1: Double
    public let median: Double
    public let q3: Double
    public let max: Double
    
    public init(category: String, min: Double, q1: Double, median: Double, q3: Double, max: Double) {
        self.category = category
        self.min = min
        self.q1 = q1
        self.median = median
        self.q3 = q3
        self.max = max
    }
}

public struct DistributionPoint: Identifiable {
    public let id = UUID()
    public let value: Double
    public let density: Double
    
    public init(value: Double, density: Double) {
        self.value = value
        self.density = density
    }
}

public struct ScatterDataPoint: Identifiable {
    public let id = UUID()
    public let x: Double
    public let y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct CorrelationData: Identifiable {
    public let id = UUID()
    public let variable1: String
    public let variable2: String
    public let correlation: Double
    
    public init(variable1: String, variable2: String, correlation: Double) {
        self.variable1 = variable1
        self.variable2 = variable2
        self.correlation = correlation
    }
}

public struct Statistics {
    public let count: Int
    public let mean: Double
    public let median: Double
    public let standardDeviation: Double
    public let min: Double
    public let max: Double
    
    public init(count: Int, mean: Double, median: Double, standardDeviation: Double, min: Double, max: Double) {
        self.count = count
        self.mean = mean
        self.median = median
        self.standardDeviation = standardDeviation
        self.min = min
        self.max = max
    }
}

// MARK: - Supporting Views

private struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
} 