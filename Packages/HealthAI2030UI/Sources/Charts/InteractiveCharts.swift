import SwiftUI
import Charts

// MARK: - Interactive Charts
/// Interactive chart components for HealthAI 2030
/// Provides touch-enabled, animated, and responsive chart components
public struct InteractiveCharts {
    
    // MARK: - Interactive Line Chart
    
    /// Interactive heart rate chart with touch selection
    public struct InteractiveHeartRateChart: View {
        let data: [HeartRateDataPoint]
        let timeRange: TimeRange
        @State private var selectedPoint: HeartRateDataPoint?
        @State private var isAnimating: Bool = false
        
        public init(data: [HeartRateDataPoint], timeRange: TimeRange = .week) {
            self.data = data
            self.timeRange = timeRange
        }
        
        public var body: some View {
            VStack(spacing: 16) {
                Chart {
                    ForEach(data) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Heart Rate", point.heartRate)
                        )
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.catmullRom)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(Double(data.firstIndex(of: point) ?? 0) * 0.1), value: isAnimating)
                        
                        AreaMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Heart Rate", point.heartRate)
                        )
                        .foregroundStyle(.red.opacity(0.1))
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 1.0).delay(Double(data.firstIndex(of: point) ?? 0) * 0.1), value: isAnimating)
                        
                        if selectedPoint?.id == point.id {
                            PointMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Heart Rate", point.heartRate)
                            )
                            .foregroundStyle(.red)
                            .symbolSize(100)
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
                .chartOverlay { proxy in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let x = value.location.x
                                    if let date = proxy.value(atX: x) as Date? {
                                        let closestPoint = data.min { point1, point2 in
                                            abs(point1.timestamp.timeIntervalSince(date)) < abs(point2.timestamp.timeIntervalSince(date))
                                        }
                                        selectedPoint = closestPoint
                                    }
                                }
                                .onEnded { _ in
                                    // Keep selection for a moment then clear
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        selectedPoint = nil
                                    }
                                }
                        )
                }
                .onAppear {
                    isAnimating = true
                }
                
                if let selected = selectedPoint {
                    VStack(spacing: 8) {
                        Text("Selected Reading")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("Heart Rate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(Int(selected.heartRate)) BPM")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(selected.timestamp, style: .time)
                                    .font(.title2)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Interactive Bar Chart
    
    /// Interactive activity bar chart with drill-down capability
    public struct InteractiveActivityChart: View {
        let data: [ActivityDataPoint]
        let timeRange: TimeRange
        @State private var selectedBar: ActivityDataPoint?
        @State private var showingDetail: Bool = false
        
        public init(data: [ActivityDataPoint], timeRange: TimeRange = .week) {
            self.data = data
            self.timeRange = timeRange
        }
        
        public var body: some View {
            VStack(spacing: 16) {
                Chart {
                    ForEach(data) { point in
                        BarMark(
                            x: .value("Date", point.date),
                            y: .value("Steps", point.steps)
                        )
                        .foregroundStyle(selectedBar?.id == point.id ? .green : .green.opacity(0.7))
                        .cornerRadius(4)
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
                .chartOverlay { proxy in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            TapGesture()
                                .onEnded { _ in
                                    if let selected = selectedBar {
                                        showingDetail = true
                                    }
                                }
                        )
                        .onTapGesture { location in
                            if let date = proxy.value(atX: location.x) as Date? {
                                let closestPoint = data.min { point1, point2 in
                                    abs(point1.date.timeIntervalSince(date)) < abs(point2.date.timeIntervalSince(date))
                                }
                                selectedBar = closestPoint
                            }
                        }
                }
                
                if let selected = selectedBar {
                    VStack(spacing: 8) {
                        Text("Activity Details")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("Steps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(selected.steps)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(selected.date, style: .date)
                                    .font(.title2)
                                    .fontWeight(.medium)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Goal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(selected.goal)")
                                    .font(.title2)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let selected = selectedBar {
                    ActivityDetailView(activity: selected)
                }
            }
        }
    }
    
    // MARK: - Interactive Scatter Plot
    
    /// Interactive scatter plot for correlation analysis
    public struct InteractiveScatterPlot: View {
        let data: [CorrelationDataPoint]
        let xLabel: String
        let yLabel: String
        @State private var selectedPoint: CorrelationDataPoint?
        @State private var showingTrendLine: Bool = false
        
        public init(data: [CorrelationDataPoint], xLabel: String, yLabel: String) {
            self.data = data
            self.xLabel = xLabel
            self.yLabel = yLabel
        }
        
        public var body: some View {
            VStack(spacing: 16) {
                Chart {
                    ForEach(data) { point in
                        PointMark(
                            x: .value(xLabel, point.xValue),
                            y: .value(yLabel, point.yValue)
                        )
                        .foregroundStyle(selectedPoint?.id == point.id ? .blue : .blue.opacity(0.6))
                        .symbolSize(selectedPoint?.id == point.id ? 150 : 100)
                    }
                    
                    if showingTrendLine {
                        LineMark(
                            x: .value("Trend", data.map { $0.xValue }),
                            y: .value("Trend", data.map { $0.yValue })
                        )
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.1f")")
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.1f")")
                    }
                }
                .chartOverlay { proxy in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let x = value.location.x
                                    let y = value.location.y
                                    if let xValue = proxy.value(atX: x) as Double?,
                                       let yValue = proxy.value(atY: y) as Double? {
                                        let closestPoint = data.min { point1, point2 in
                                            let distance1 = sqrt(pow(point1.xValue - xValue, 2) + pow(point1.yValue - yValue, 2))
                                            let distance2 = sqrt(pow(point2.xValue - xValue, 2) + pow(point2.yValue - yValue, 2))
                                            return distance1 < distance2
                                        }
                                        selectedPoint = closestPoint
                                    }
                                }
                        )
                }
                
                HStack {
                    Button("Show Trend Line") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showingTrendLine.toggle()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    if let selected = selectedPoint {
                        VStack(alignment: .trailing) {
                            Text("Selected Point")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("(\(String(format: "%.1f", selected.xValue)), \(String(format: "%.1f", selected.yValue)))")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Interactive Pie Chart
    
    /// Interactive pie chart for health data distribution
    public struct InteractivePieChart: View {
        let data: [PieChartDataPoint]
        @State private var selectedSegment: PieChartDataPoint?
        @State private var isAnimating: Bool = false
        
        public init(data: [PieChartDataPoint]) {
            self.data = data
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                ZStack {
                    ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                        PieSlice(
                            data: point,
                            startAngle: startAngle(for: index),
                            endAngle: endAngle(for: index),
                            isSelected: selectedSegment?.id == point.id,
                            isAnimating: isAnimating
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedSegment = selectedSegment?.id == point.id ? nil : point
                            }
                        }
                    }
                }
                .frame(width: 200, height: 200)
                
                if let selected = selectedSegment {
                    VStack(spacing: 8) {
                        Text(selected.label)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(Int(selected.value))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(selected.color)
                        
                        Text("\(String(format: "%.1f", selected.percentage))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                isAnimating = true
            }
        }
        
        private func startAngle(for index: Int) -> Double {
            let total = data.reduce(0) { $0 + $1.value }
            let previousValues = data.prefix(index).reduce(0) { $0 + $1.value }
            return (previousValues / total) * 360
        }
        
        private func endAngle(for index: Int) -> Double {
            let total = data.reduce(0) { $0 + $1.value }
            let currentAndPreviousValues = data.prefix(index + 1).reduce(0) { $0 + $1.value }
            return (currentAndPreviousValues / total) * 360
        }
    }
}

// MARK: - Supporting Views

/// Custom pie slice view
private struct PieSlice: View {
    let data: PieChartDataPoint
    let startAngle: Double
    let endAngle: Double
    let isSelected: Bool
    let isAnimating: Bool
    
    var body: some View {
        Path { path in
            let center = CGPoint(x: 100, y: 100)
            let radius: CGFloat = isSelected ? 90 : 80
            path.move(to: center)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle),
                clockwise: false
            )
            path.closeSubpath()
        }
        .fill(data.color)
        .scaleEffect(isAnimating ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.8).delay(Double(startAngle) / 360 * 0.5), value: isAnimating)
        .shadow(color: isSelected ? .black.opacity(0.3) : .clear, radius: 5, x: 0, y: 2)
    }
}

/// Activity detail view for drill-down
private struct ActivityDetailView: View {
    let activity: ActivityDataPoint
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Activity Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    DetailRow(title: "Steps", value: "\(activity.steps)", color: .green)
                    DetailRow(title: "Goal", value: "\(activity.goal)", color: .blue)
                    DetailRow(title: "Date", value: activity.date.formatted(date: .long, time: .omitted), color: .orange)
                    DetailRow(title: "Progress", value: "\(Int((Double(activity.steps) / Double(activity.goal)) * 100))%", color: .purple)
                }
                
                Spacer()
            }
            .padding()
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

/// Detail row component
private struct DetailRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Data Models

/// Data point for correlation analysis
public struct CorrelationDataPoint: Identifiable {
    public let id = UUID()
    public let xValue: Double
    public let yValue: Double
    public let label: String
    
    public init(xValue: Double, yValue: Double, label: String) {
        self.xValue = xValue
        self.yValue = yValue
        self.label = label
    }
}

/// Data point for pie charts
public struct PieChartDataPoint: Identifiable {
    public let id = UUID()
    public let label: String
    public let value: Double
    public let color: Color
    public let percentage: Double
    
    public init(label: String, value: Double, color: Color) {
        self.label = label
        self.value = value
        self.color = color
        self.percentage = 0 // Will be calculated based on total
    }
}

// MARK: - Extensions

public extension InteractiveCharts {
    /// Create correlation data from heart rate and activity data
    static func createCorrelationData(heartRateData: [HeartRateDataPoint], activityData: [ActivityDataPoint]) -> [CorrelationDataPoint] {
        // Implementation for creating correlation data
        return []
    }
    
    /// Create pie chart data from health metrics
    static func createHealthDistributionData(metrics: [String: Double]) -> [PieChartDataPoint] {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink]
        let total = metrics.values.reduce(0, +)
        
        return Array(metrics.enumerated()).map { index, element in
            let percentage = (element.value / total) * 100
            return PieChartDataPoint(
                label: element.key,
                value: element.value,
                color: colors[index % colors.count]
            )
        }
    }
} 