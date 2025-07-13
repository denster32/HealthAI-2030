import SwiftUI
import Charts

// MARK: - HealthAI Data Visualization System
/// Comprehensive data visualization system for HealthAI 2030
/// Provides interactive charts, graphs, and health data visualizations

// MARK: - Health Data Models
public struct HealthDataPoint: Identifiable, Codable {
    public let id = UUID()
    public let timestamp: Date
    public let value: Double
    public let unit: String
    public let category: HealthCategory
    public let metadata: [String: String]?
    
    public init(
        timestamp: Date,
        value: Double,
        unit: String,
        category: HealthCategory,
        metadata: [String: String]? = nil
    ) {
        self.timestamp = timestamp
        self.value = value
        self.unit = unit
        self.category = category
        self.metadata = metadata
    }
}

public enum HealthCategory: String, CaseIterable, Codable {
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case sleep = "Sleep"
    case activity = "Activity"
    case temperature = "Temperature"
    case stress = "Stress"
    case nutrition = "Nutrition"
    case hydration = "Hydration"
    case weight = "Weight"
    case steps = "Steps"
    case calories = "Calories"
    case oxygen = "Blood Oxygen"
    
    var color: Color {
        switch self {
        case .heartRate: return .red
        case .bloodPressure: return .blue
        case .sleep: return .purple
        case .activity: return .green
        case .temperature: return .orange
        case .stress: return .yellow
        case .nutrition: return .brown
        case .hydration: return .cyan
        case .weight: return .gray
        case .steps: return .mint
        case .calories: return .pink
        case .oxygen: return .indigo
        }
    }
    
    var icon: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .bloodPressure: return "heart.circle.fill"
        case .sleep: return "bed.double.fill"
        case .activity: return "figure.walk"
        case .temperature: return "thermometer"
        case .stress: return "brain.head.profile"
        case .nutrition: return "fork.knife"
        case .hydration: return "drop.fill"
        case .weight: return "scalemass"
        case .steps: return "figure.walk"
        case .calories: return "flame.fill"
        case .oxygen: return "lungs.fill"
        }
    }
}

// MARK: - Chart Types
public enum ChartType: String, CaseIterable {
    case line = "Line Chart"
    case area = "Area Chart"
    case bar = "Bar Chart"
    case scatter = "Scatter Plot"
    case pie = "Pie Chart"
    case donut = "Donut Chart"
    case radar = "Radar Chart"
    case heatmap = "Heatmap"
}

// MARK: - Time Range
public enum TimeRange: String, CaseIterable {
    case hour = "1 Hour"
    case day = "24 Hours"
    case week = "7 Days"
    case month = "30 Days"
    case quarter = "3 Months"
    case year = "1 Year"
    
    var dateInterval: DateInterval {
        let now = Date()
        switch self {
        case .hour:
            return DateInterval(start: now.addingTimeInterval(-3600), duration: 3600)
        case .day:
            return DateInterval(start: now.addingTimeInterval(-86400), duration: 86400)
        case .week:
            return DateInterval(start: now.addingTimeInterval(-604800), duration: 604800)
        case .month:
            return DateInterval(start: now.addingTimeInterval(-2592000), duration: 2592000)
        case .quarter:
            return DateInterval(start: now.addingTimeInterval(-7776000), duration: 7776000)
        case .year:
            return DateInterval(start: now.addingTimeInterval(-31536000), duration: 31536000)
        }
    }
}

// MARK: - Health Data Chart
public struct HealthDataChart: View {
    let data: [HealthDataPoint]
    let chartType: ChartType
    let timeRange: TimeRange
    let showLegend: Bool
    let showGrid: Bool
    let animated: Bool
    
    @State private var animationProgress: Double = 0
    
    public init(
        data: [HealthDataPoint],
        chartType: ChartType = .line,
        timeRange: TimeRange = .day,
        showLegend: Bool = true,
        showGrid: Bool = true,
        animated: Bool = true
    ) {
        self.data = data
        self.chartType = chartType
        self.timeRange = timeRange
        self.showLegend = showLegend
        self.showGrid = showGrid
        self.animated = animated
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Chart Header
            HStack {
                Text(chartType.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(timeRange.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Chart Content
            Group {
                switch chartType {
                case .line:
                    LineChartView(data: data, animated: animated, progress: animationProgress)
                case .area:
                    AreaChartView(data: data, animated: animated, progress: animationProgress)
                case .bar:
                    BarChartView(data: data, animated: animated, progress: animationProgress)
                case .scatter:
                    ScatterChartView(data: data, animated: animated, progress: animationProgress)
                case .pie:
                    PieChartView(data: data, animated: animated, progress: animationProgress)
                case .donut:
                    DonutChartView(data: data, animated: animated, progress: animationProgress)
                case .radar:
                    RadarChartView(data: data, animated: animated, progress: animationProgress)
                case .heatmap:
                    HeatmapView(data: data, animated: animated, progress: animationProgress)
                }
            }
            .frame(height: 300)
            
            // Legend
            if showLegend {
                ChartLegend(data: data)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 1.0)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - Line Chart View
struct LineChartView: View {
    let data: [HealthDataPoint]
    let animated: Bool
    let progress: Double
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value * progress)
                )
                .foregroundStyle(point.category.color)
                .lineStyle(StrokeStyle(lineWidth: 3))
                
                PointMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value * progress)
                )
                .foregroundStyle(point.category.color)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

// MARK: - Area Chart View
struct AreaChartView: View {
    let data: [HealthDataPoint]
    let animated: Bool
    let progress: Double
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                AreaMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value * progress)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            point.category.color.opacity(0.8),
                            point.category.color.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

// MARK: - Bar Chart View
struct BarChartView: View {
    let data: [HealthDataPoint]
    let animated: Bool
    let progress: Double
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value * progress)
                )
                .foregroundStyle(point.category.color)
                .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

// MARK: - Scatter Chart View
struct ScatterChartView: View {
    let data: [HealthDataPoint]
    let animated: Bool
    let progress: Double
    
    var body: some View {
        Chart {
            ForEach(data) { point in
                PointMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value * progress)
                )
                .foregroundStyle(point.category.color)
                .symbolSize(100)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

// MARK: - Pie Chart View
struct PieChartView: View {
    let data: [HealthDataPoint]
    let animated: Bool
    let progress: Double
    
    private var groupedData: [HealthCategory: Double] {
        Dictionary(grouping: data, by: { $0.category })
            .mapValues { points in
                points.reduce(0) { $0 + $1.value } * progress
            }
    }
    
    var body: some View {
        ZStack {
            ForEach(Array(groupedData.enumerated()), id: \.key) { index, element in
                let category = element.key
                let value = element.value
                let total = groupedData.values.reduce(0, +)
                let percentage = total > 0 ? value / total : 0
                let startAngle = calculateStartAngle(for: index, in: groupedData)
                let endAngle = startAngle + (360 * percentage)
                
                PieSlice(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    color: category.color
                )
            }
        }
        .frame(width: 200, height: 200)
    }
    
    private func calculateStartAngle(for index: Int, in data: [HealthCategory: Double]) -> Double {
        let total = data.values.reduce(0, +)
        let previousValues = Array(data.values.prefix(index))
        let previousSum = previousValues.reduce(0, +)
        return (previousSum / total) * 360
    }
}

// MARK: - Pie Slice
struct PieSlice: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 100, y: 100)
            let radius: CGFloat = 80
            
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: Angle(degrees: startAngle),
                endAngle: Angle(degrees: endAngle),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(color)
    }
}

// MARK: - Donut Chart View
struct DonutChartView: View {
    let data: [HealthDataPoint]
    let animated: Bool
    let progress: Double
    
    private var groupedData: [HealthCategory: Double] {
        Dictionary(grouping: data, by: { $0.category })
            .mapValues { points in
                points.reduce(0) { $0 + $1.value } * progress
            }
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                .frame(width: 200, height: 200)
            
            // Data slices
            ForEach(Array(groupedData.enumerated()), id: \.key) { index, element in
                let category = element.key
                let value = element.value
                let total = groupedData.values.reduce(0, +)
                let percentage = total > 0 ? value / total : 0
                let startAngle = calculateStartAngle(for: index, in: groupedData)
                let endAngle = startAngle + (360 * percentage)
                
                DonutSlice(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    color: category.color,
                    lineWidth: 20
                )
            }
            
            // Center content
            VStack {
                Text("Total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.0f", groupedData.values.reduce(0, +)))
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .frame(width: 200, height: 200)
    }
    
    private func calculateStartAngle(for index: Int, in data: [HealthCategory: Double]) -> Double {
        let total = data.values.reduce(0, +)
        let previousValues = Array(data.values.prefix(index))
        let previousSum = previousValues.reduce(0, +)
        return (previousSum / total) * 360
    }
}

// MARK: - Donut Slice
struct DonutSlice: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 100, y: 100)
            let radius: CGFloat = 80
            
            path.addArc(
                center: center,
                radius: radius,
                startAngle: Angle(degrees: startAngle),
                endAngle: Angle(degrees: endAngle),
                clockwise: false
            )
        }
        .stroke(color, lineWidth: lineWidth)
        .frame(width: 200, height: 200)
    }
}

// MARK: - Radar Chart View
struct RadarChartView: View {
    let data: [HealthDataPoint]
    let animated: Bool
    let progress: Double
    
    private var groupedData: [HealthCategory: Double] {
        Dictionary(grouping: data, by: { $0.category })
            .mapValues { points in
                points.reduce(0) { $0 + $1.value } * progress
            }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
            
            ZStack {
                // Background grid
                RadarGrid(center: center, radius: radius, levels: 5)
                
                // Data polygon
                RadarPolygon(
                    data: groupedData,
                    center: center,
                    radius: radius,
                    progress: progress
                )
            }
        }
        .frame(width: 300, height: 300)
    }
}

// MARK: - Radar Grid
struct RadarGrid: View {
    let center: CGPoint
    let radius: CGFloat
    let levels: Int
    
    var body: some View {
        ZStack {
            // Circular levels
            ForEach(1...levels, id: \.self) { level in
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: radius * 2 * CGFloat(level) / CGFloat(levels))
            }
            
            // Axes
            ForEach(0..<HealthCategory.allCases.count, id: \.self) { index in
                let angle = (2 * Double.pi * Double(index)) / Double(HealthCategory.allCases.count)
                let endPoint = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                
                Path { path in
                    path.move(to: center)
                    path.addLine(to: endPoint)
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            }
        }
    }
}

// MARK: - Radar Polygon
struct RadarPolygon: View {
    let data: [HealthCategory: Double]
    let center: CGPoint
    let radius: CGFloat
    let progress: Double
    
    var body: some View {
        Path { path in
            let categories = Array(data.keys)
            let maxValue = data.values.max() ?? 1
            
            for (index, category) in categories.enumerated() {
                let angle = (2 * Double.pi * Double(index)) / Double(categories.count)
                let value = data[category] ?? 0
                let normalizedValue = value / maxValue
                let pointRadius = radius * normalizedValue
                
                let point = CGPoint(
                    x: center.x + pointRadius * cos(angle),
                    y: center.y + pointRadius * sin(angle)
                )
                
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
        .fill(Color.blue.opacity(0.3))
        .stroke(Color.blue, lineWidth: 2)
    }
}

// MARK: - Heatmap View
struct HeatmapView: View {
    let data: [HealthDataPoint]
    let animated: Bool
    let progress: Double
    
    private var heatmapData: [[Double]] {
        // Group data by hour and day
        let calendar = Calendar.current
        var heatmap = Array(repeating: Array(repeating: 0.0, count: 24), count: 7)
        
        for point in data {
            let weekday = calendar.component(.weekday, from: point.timestamp) - 1
            let hour = calendar.component(.hour, from: point.timestamp)
            heatmap[weekday][hour] += point.value * progress
        }
        
        return heatmap
    }
    
    private var maxValue: Double {
        heatmapData.flatMap { $0 }.max() ?? 1
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { day in
                HStack(spacing: 4) {
                    ForEach(0..<24, id: \.self) { hour in
                        let value = heatmapData[day][hour]
                        let intensity = value / maxValue
                        
                        Rectangle()
                            .fill(Color.blue.opacity(intensity))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Chart Legend
struct ChartLegend: View {
    let data: [HealthDataPoint]
    
    private var uniqueCategories: [HealthCategory] {
        Array(Set(data.map { $0.category })).sorted { $0.rawValue < $1.rawValue }
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 120), spacing: 8)
        ], spacing: 8) {
            ForEach(uniqueCategories, id: \.self) { category in
                HStack(spacing: 8) {
                    Circle()
                        .fill(category.color)
                        .frame(width: 12, height: 12)
                    
                    Text(category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Interactive Chart Container
public struct InteractiveChartContainer: View {
    @State private var selectedChartType: ChartType = .line
    @State private var selectedTimeRange: TimeRange = .day
    @State private var showingLegend = true
    @State private var showingGrid = true
    
    let data: [HealthDataPoint]
    
    public init(data: [HealthDataPoint]) {
        self.data = data
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Controls
            HStack {
                Picker("Chart Type", selection: $selectedChartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                Toggle("Legend", isOn: $showingLegend)
                    .toggleStyle(SwitchToggleStyle())
                
                Toggle("Grid", isOn: $showingGrid)
                    .toggleStyle(SwitchToggleStyle())
            }
            .padding(.horizontal)
            
            // Chart
            HealthDataChart(
                data: data,
                chartType: selectedChartType,
                timeRange: selectedTimeRange,
                showLegend: showingLegend,
                showGrid: showingGrid
            )
        }
    }
}

// MARK: - Sample Data Generator
public struct SampleDataGenerator {
    public static func generateHeartRateData(hours: Int = 24) -> [HealthDataPoint] {
        var data: [HealthDataPoint] = []
        let now = Date()
        
        for hour in 0..<hours {
            let timestamp = now.addingTimeInterval(-Double(hour * 3600))
            let baseHeartRate = 70.0
            let variation = Double.random(in: -10...15)
            let heartRate = baseHeartRate + variation
            
            data.append(HealthDataPoint(
                timestamp: timestamp,
                value: heartRate,
                unit: "BPM",
                category: .heartRate
            ))
        }
        
        return data.reversed()
    }
    
    public static func generateSleepData(days: Int = 7) -> [HealthDataPoint] {
        var data: [HealthDataPoint] = []
        let now = Date()
        
        for day in 0..<days {
            let timestamp = now.addingTimeInterval(-Double(day * 86400))
            let sleepHours = Double.random(in: 6.5...8.5)
            
            data.append(HealthDataPoint(
                timestamp: timestamp,
                value: sleepHours,
                unit: "hours",
                category: .sleep
            ))
        }
        
        return data.reversed()
    }
    
    public static func generateActivityData(days: Int = 7) -> [HealthDataPoint] {
        var data: [HealthDataPoint] = []
        let now = Date()
        
        for day in 0..<days {
            let timestamp = now.addingTimeInterval(-Double(day * 86400))
            let steps = Double.random(in: 5000...12000)
            
            data.append(HealthDataPoint(
                timestamp: timestamp,
                value: steps,
                unit: "steps",
                category: .activity
            ))
        }
        
        return data.reversed()
    }
}

// MARK: - Preview
struct HealthAIDataCharts_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                HealthDataChart(
                    data: SampleDataGenerator.generateHeartRateData(),
                    chartType: .line
                )
                
                HealthDataChart(
                    data: SampleDataGenerator.generateSleepData(),
                    chartType: .bar
                )
                
                InteractiveChartContainer(
                    data: SampleDataGenerator.generateActivityData()
                )
            }
            .padding()
        }
    }
} 