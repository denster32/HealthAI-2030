import SwiftUI
import Charts

// MARK: - Health Trend Charts
/// Comprehensive trend visualization components for HealthAI 2030
/// Provides line charts, area charts, and bar charts for health data trends
public struct HealthTrendCharts {
    
    // MARK: - Line Chart Components
    
    /// Heart rate trend line chart
    public struct HeartRateTrendChart: View {
        let data: [HeartRateDataPoint]
        let timeRange: TimeRange
        let showTarget: Bool
        let targetValue: Double?
        
        public init(data: [HeartRateDataPoint], timeRange: TimeRange = .week, showTarget: Bool = false, targetValue: Double? = nil) {
            self.data = data
            self.timeRange = timeRange
            self.showTarget = showTarget
            self.targetValue = targetValue
        }
        
        public var body: some View {
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Heart Rate", point.heartRate)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Heart Rate", point.heartRate)
                    )
                    .foregroundStyle(.red.opacity(0.1))
                }
                
                if showTarget, let target = targetValue {
                    RuleMark(y: .value("Target", target))
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .annotation(position: .leading) {
                            Text("Target")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange.strideBy)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: timeRange.dateFormat)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.0f")")
                }
            }
        }
    }
    
    /// HRV trend line chart
    public struct HRVTrendChart: View {
        let data: [HRVDataPoint]
        let timeRange: TimeRange
        
        public init(data: [HRVDataPoint], timeRange: TimeRange = .week) {
            self.data = data
            self.timeRange = timeRange
        }
        
        public var body: some View {
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("HRV", point.hrv)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("HRV", point.hrv)
                    )
                    .foregroundStyle(.green.opacity(0.1))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange.strideBy)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: timeRange.dateFormat)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.1f")")
                }
            }
        }
    }
    
    /// Sleep trend area chart
    public struct SleepTrendChart: View {
        let data: [SleepDataPoint]
        let timeRange: TimeRange
        
        public init(data: [SleepDataPoint], timeRange: TimeRange = .week) {
            self.data = data
            self.timeRange = timeRange
        }
        
        public var body: some View {
            Chart {
                ForEach(data) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Hours", point.hours)
                    )
                    .foregroundStyle(.blue.opacity(0.3))
                    
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Hours", point.hours)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange.strideBy)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: timeRange.dateFormat)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.1f")h")
                }
            }
        }
    }
    
    /// Activity trend bar chart
    public struct ActivityTrendChart: View {
        let data: [ActivityDataPoint]
        let timeRange: TimeRange
        
        public init(data: [ActivityDataPoint], timeRange: TimeRange = .week) {
            self.data = data
            self.timeRange = timeRange
        }
        
        public var body: some View {
            Chart {
                ForEach(data) { point in
                    BarMark(
                        x: .value("Date", point.date),
                        y: .value("Steps", point.steps)
                    )
                    .foregroundStyle(.green.gradient)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange.strideBy)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: timeRange.dateFormat)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel("\(value.as(Int.self) ?? 0)")
                }
            }
        }
    }
    
    /// Blood pressure trend chart
    public struct BloodPressureTrendChart: View {
        let data: [BloodPressureDataPoint]
        let timeRange: TimeRange
        
        public init(data: [BloodPressureDataPoint], timeRange: TimeRange = .week) {
            self.data = data
            self.timeRange = timeRange
        }
        
        public var body: some View {
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Systolic", point.systolic)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol(by: .value("Type", "Systolic"))
                    
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Diastolic", point.diastolic)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol(by: .value("Type", "Diastolic"))
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange.strideBy)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: timeRange.dateFormat)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.0f")")
                }
            }
            .chartLegend(position: .top, alignment: .center)
        }
    }
    
    /// Weight trend chart
    public struct WeightTrendChart: View {
        let data: [WeightDataPoint]
        let timeRange: TimeRange
        let showGoal: Bool
        let goalWeight: Double?
        
        public init(data: [WeightDataPoint], timeRange: TimeRange = .month, showGoal: Bool = false, goalWeight: Double? = nil) {
            self.data = data
            self.timeRange = timeRange
            self.showGoal = showGoal
            self.goalWeight = goalWeight
        }
        
        public var body: some View {
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.purple)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(.purple)
                }
                
                if showGoal, let goal = goalWeight {
                    RuleMark(y: .value("Goal", goal))
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        .annotation(position: .leading) {
                            Text("Goal")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange.strideBy)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: timeRange.dateFormat)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.1f")kg")
                }
            }
        }
    }
    
    /// Temperature trend chart
    public struct TemperatureTrendChart: View {
        let data: [TemperatureDataPoint]
        let timeRange: TimeRange
        
        public init(data: [TemperatureDataPoint], timeRange: TimeRange = .day) {
            self.data = data
            self.timeRange = timeRange
        }
        
        public var body: some View {
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Temperature", point.temperature)
                    )
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Temperature", point.temperature)
                    )
                    .foregroundStyle(.orange.opacity(0.1))
                }
                
                // Normal temperature range
                RuleMark(y: .value("Normal High", 37.2))
                    .foregroundStyle(.red.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                
                RuleMark(y: .value("Normal Low", 36.1))
                    .foregroundStyle(.red.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: timeRange.strideBy)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: timeRange.dateFormat)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.1f")°C")
                }
            }
        }
    }
}

// MARK: - Data Models

public struct HeartRateDataPoint: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let heartRate: Double
    
    public init(timestamp: Date, heartRate: Double) {
        self.timestamp = timestamp
        self.heartRate = heartRate
    }
}

public struct HRVDataPoint: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let hrv: Double
    
    public init(timestamp: Date, hrv: Double) {
        self.timestamp = timestamp
        self.hrv = hrv
    }
}

public struct SleepDataPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let hours: Double
    
    public init(date: Date, hours: Double) {
        self.date = date
        self.hours = hours
    }
}

public struct ActivityDataPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let steps: Int
    
    public init(date: Date, steps: Int) {
        self.date = date
        self.steps = steps
    }
}

public struct BloodPressureDataPoint: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let systolic: Double
    public let diastolic: Double
    
    public init(timestamp: Date, systolic: Double, diastolic: Double) {
        self.timestamp = timestamp
        self.systolic = systolic
        self.diastolic = diastolic
    }
}

public struct WeightDataPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let weight: Double
    
    public init(date: Date, weight: Double) {
        self.date = date
        self.weight = weight
    }
}

public struct TemperatureDataPoint: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let temperature: Double
    
    public init(timestamp: Date, temperature: Double) {
        self.timestamp = timestamp
        self.temperature = temperature
    }
}

// MARK: - Supporting Types

public enum TimeRange: CaseIterable {
    case hour, day, week, month, quarter, year
    
    public var strideBy: Calendar.Component {
        switch self {
        case .hour: return .hour
        case .day: return .hour
        case .week: return .day
        case .month: return .day
        case .quarter: return .weekOfYear
        case .year: return .month
        }
    }
    
    public var dateFormat: Date.FormatStyle {
        switch self {
        case .hour: return .dateTime.hour()
        case .day: return .dateTime.hour()
        case .week: return .dateTime.weekday(.abbreviated)
        case .month: return .dateTime.day()
        case .quarter: return .dateTime.month(.abbreviated)
        case .year: return .dateTime.month(.abbreviated)
        }
    }
} 