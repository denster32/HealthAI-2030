import SwiftUI
import Charts

// MARK: - Chart Data Models
public struct Point: Identifiable {
    public let id = UUID()
    public let date: Date
    public let value: Double
    
    public init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

public struct CategoryValue: Identifiable {
    public let id = UUID()
    public let category: String
    public let value: Double
    public let color: Color?
    
    public init(category: String, value: Double, color: Color? = nil) {
        self.category = category
        self.value = value
        self.color = color
    }
}

// MARK: - HealthLineChart
public struct HealthLineChart: View {
    let data: [Point]
    let title: String?
    let showGrid: Bool
    let showPoints: Bool
    let lineColor: Color
    let fillColor: Color?
    let yAxisTitle: String?
    let xAxisTitle: String?
    
    public init(
        data: [Point],
        title: String? = nil,
        showGrid: Bool = true,
        showPoints: Bool = true,
        lineColor: Color = .blue,
        fillColor: Color? = nil,
        yAxisTitle: String? = nil,
        xAxisTitle: String? = nil
    ) {
        self.data = data
        self.title = title
        self.showGrid = showGrid
        self.showPoints = showPoints
        self.lineColor = lineColor
        self.fillColor = fillColor
        self.yAxisTitle = yAxisTitle
        self.xAxisTitle = xAxisTitle
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
            if let title = title {
                Text(title)
                    .font(HealthAIDesignSystem.Typography.headline)
                    .fontWeight(.medium)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
            }
            
            Chart(data) { point in
                if let fillColor = fillColor {
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(fillColor.opacity(0.3))
                }
                
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2))
                
                if showPoints {
                    PointMark(
                        x: .value("Time", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(lineColor)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: showGrid ? 0.5 : 0))
                        .foregroundStyle(HealthAIDesignSystem.Color.border)
                    AxisValueLabel()
                        .foregroundStyle(HealthAIDesignSystem.Color.textSecondary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: showGrid ? 0.5 : 0))
                        .foregroundStyle(HealthAIDesignSystem.Color.border)
                    AxisValueLabel()
                        .foregroundStyle(HealthAIDesignSystem.Color.textSecondary)
                }
            }
            .frame(height: 200)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(accessibilityLabel))
            .accessibilityValue(Text(accessibilityValue))
        }
    }
    
    private var accessibilityLabel: String {
        let titleText = title ?? "Chart"
        return "\(titleText) showing \(data.count) data points"
    }
    
    private var accessibilityValue: String {
        guard !data.isEmpty else { return "No data available" }
        
        let minValue = data.map { $0.value }.min() ?? 0
        let maxValue = data.map { $0.value }.max() ?? 0
        let avgValue = data.map { $0.value }.reduce(0, +) / Double(data.count)
        
        return "Range from \(String(format: "%.1f", minValue)) to \(String(format: "%.1f", maxValue)), average \(String(format: "%.1f", avgValue))"
    }
}

// MARK: - HealthBarChart
public struct HealthBarChart: View {
    let data: [CategoryValue]
    let title: String?
    let showValues: Bool
    let barColor: Color?
    let horizontal: Bool
    
    public init(
        data: [CategoryValue],
        title: String? = nil,
        showValues: Bool = true,
        barColor: Color? = nil,
        horizontal: Bool = false
    ) {
        self.data = data
        self.title = title
        self.showValues = showValues
        self.barColor = barColor
        self.horizontal = horizontal
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
            if let title = title {
                Text(title)
                    .font(HealthAIDesignSystem.Typography.headline)
                    .fontWeight(.medium)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
            }
            
            if horizontal {
                Chart(data) { item in
                    BarMark(
                        x: .value("Value", item.value),
                        y: .value("Category", item.category)
                    )
                    .foregroundStyle(item.color ?? barColor ?? HealthAIDesignSystem.Color.healthPrimary)
                    .annotation(position: .trailing) {
                        if showValues {
                            Text(String(format: "%.1f", item.value))
                                .font(HealthAIDesignSystem.Typography.caption)
                                .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(HealthAIDesignSystem.Color.border)
                        AxisValueLabel()
                            .foregroundStyle(HealthAIDesignSystem.Color.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(HealthAIDesignSystem.Color.textSecondary)
                    }
                }
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Category", item.category),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(item.color ?? barColor ?? HealthAIDesignSystem.Color.healthPrimary)
                    .annotation(position: .top) {
                        if showValues {
                            Text(String(format: "%.1f", item.value))
                                .font(HealthAIDesignSystem.Typography.caption)
                                .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .foregroundStyle(HealthAIDesignSystem.Color.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(HealthAIDesignSystem.Color.border)
                        AxisValueLabel()
                            .foregroundStyle(HealthAIDesignSystem.Color.textSecondary)
                    }
                }
            }
            .frame(height: 200)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(accessibilityLabel))
            .accessibilityValue(Text(accessibilityValue))
        }
    }
    
    private var accessibilityLabel: String {
        let titleText = title ?? "Bar Chart"
        return "\(titleText) showing \(data.count) categories"
    }
    
    private var accessibilityValue: String {
        guard !data.isEmpty else { return "No data available" }
        
        let maxValue = data.map { $0.value }.max() ?? 0
        let maxCategory = data.first { $0.value == maxValue }?.category ?? ""
        
        return "Highest value is \(String(format: "%.1f", maxValue)) for \(maxCategory)"
    }
}

// MARK: - HealthPieChart
public struct HealthPieChart: View {
    let data: [CategoryValue]
    let title: String?
    let showValues: Bool
    let showLegend: Bool
    
    public init(
        data: [CategoryValue],
        title: String? = nil,
        showValues: Bool = true,
        showLegend: Bool = true
    ) {
        self.data = data
        self.title = title
        self.showValues = showValues
        self.showLegend = showLegend
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.medium) {
            if let title = title {
                Text(title)
                    .font(HealthAIDesignSystem.Typography.headline)
                    .fontWeight(.medium)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
            }
            
            HStack(spacing: HealthAIDesignSystem.Spacing.large) {
                Chart(data) { item in
                    SectorMark(
                        angle: .value("Value", item.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color ?? defaultColor(for: item.category))
                    .annotation(position: .overlay) {
                        if showValues {
                            Text(String(format: "%.0f%%", (item.value / totalValue) * 100))
                                .font(HealthAIDesignSystem.Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 150, height: 150)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(accessibilityLabel))
                .accessibilityValue(Text(accessibilityValue))
                
                if showLegend {
                    VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
                        ForEach(data) { item in
                            HStack(spacing: HealthAIDesignSystem.Spacing.small) {
                                Circle()
                                    .fill(item.color ?? defaultColor(for: item.category))
                                    .frame(width: 12, height: 12)
                                
                                Text(item.category)
                                    .font(HealthAIDesignSystem.Typography.caption)
                                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
                                
                                Spacer()
                                
                                Text(String(format: "%.1f", item.value))
                                    .font(HealthAIDesignSystem.Typography.caption)
                                    .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var totalValue: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    private func defaultColor(for category: String) -> Color {
        let colors: [Color] = [
            .blue, .green, .orange, .red, .purple, .pink, .yellow, .cyan
        ]
        let index = abs(category.hashValue) % colors.count
        return colors[index]
    }
    
    private var accessibilityLabel: String {
        let titleText = title ?? "Pie Chart"
        return "\(titleText) showing \(data.count) categories"
    }
    
    private var accessibilityValue: String {
        guard !data.isEmpty else { return "No data available" }
        
        let largestCategory = data.max { $0.value < $1.value }
        let percentage = largestCategory.map { ($0.value / totalValue) * 100 } ?? 0
        
        return "Largest segment is \(largestCategory?.category ?? "") with \(String(format: "%.1f", percentage)) percent"
    }
}

// MARK: - HealthScatterPlot
public struct HealthScatterPlot: View {
    let data: [Point]
    let title: String?
    let showTrendLine: Bool
    let pointColor: Color
    let pointSize: CGFloat
    
    public init(
        data: [Point],
        title: String? = nil,
        showTrendLine: Bool = false,
        pointColor: Color = .blue,
        pointSize: CGFloat = 6
    ) {
        self.data = data
        self.title = title
        self.showTrendLine = showTrendLine
        self.pointColor = pointColor
        self.pointSize = pointSize
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
            if let title = title {
                Text(title)
                    .font(HealthAIDesignSystem.Typography.headline)
                    .fontWeight(.medium)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
            }
            
            Chart(data) { point in
                PointMark(
                    x: .value("Time", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(pointColor)
                .symbolSize(pointSize)
                
                if showTrendLine {
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Trend", calculateTrendValue(for: point.date))
                    )
                    .foregroundStyle(pointColor.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(HealthAIDesignSystem.Color.border)
                    AxisValueLabel()
                        .foregroundStyle(HealthAIDesignSystem.Color.textSecondary)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(HealthAIDesignSystem.Color.border)
                    AxisValueLabel()
                        .foregroundStyle(HealthAIDesignSystem.Color.textSecondary)
                }
            }
            .frame(height: 200)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(accessibilityLabel))
            .accessibilityValue(Text(accessibilityValue))
        }
    }
    
    private func calculateTrendValue(for date: Date) -> Double {
        // Simple linear trend calculation
        guard data.count > 1 else { return 0 }
        
        let sortedData = data.sorted { $0.date < $1.date }
        let firstValue = sortedData.first?.value ?? 0
        let lastValue = sortedData.last?.value ?? 0
        let totalTime = sortedData.last?.date.timeIntervalSince(sortedData.first?.date ?? Date()) ?? 1
        let timeSinceStart = date.timeIntervalSince(sortedData.first?.date ?? Date())
        
        return firstValue + (lastValue - firstValue) * (timeSinceStart / totalTime)
    }
    
    private var accessibilityLabel: String {
        let titleText = title ?? "Scatter Plot"
        return "\(titleText) showing \(data.count) data points"
    }
    
    private var accessibilityValue: String {
        guard !data.isEmpty else { return "No data available" }
        
        let minValue = data.map { $0.value }.min() ?? 0
        let maxValue = data.map { $0.value }.max() ?? 0
        
        return "Values range from \(String(format: "%.1f", minValue)) to \(String(format: "%.1f", maxValue))"
    }
}

// MARK: - HealthHeatmap
public struct HealthHeatmap: View {
    let data: [[Double]]
    let rowLabels: [String]
    let columnLabels: [String]
    let title: String?
    let colorScale: ColorScale
    
    public enum ColorScale {
        case red, blue, green, purple
        
        func color(for value: Double, min: Double, max: Double) -> Color {
            let normalized = (value - min) / (max - min)
            switch self {
            case .red:
                return Color(red: normalized, green: 0, blue: 0)
            case .blue:
                return Color(red: 0, green: 0, blue: normalized)
            case .green:
                return Color(red: 0, green: normalized, blue: 0)
            case .purple:
                return Color(red: normalized, green: 0, blue: normalized)
            }
        }
    }
    
    public init(
        data: [[Double]],
        rowLabels: [String],
        columnLabels: [String],
        title: String? = nil,
        colorScale: ColorScale = .red
    ) {
        self.data = data
        self.rowLabels = rowLabels
        self.columnLabels = columnLabels
        self.title = title
        self.colorScale = colorScale
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
            if let title = title {
                Text(title)
                    .font(HealthAIDesignSystem.Typography.headline)
                    .fontWeight(.medium)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
            }
            
            VStack(spacing: HealthAIDesignSystem.Spacing.extraSmall) {
                // Column headers
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 80)
                    
                    ForEach(columnLabels, id: \.self) { label in
                        Text(label)
                            .font(HealthAIDesignSystem.Typography.caption)
                            .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                            .frame(maxWidth: .infinity)
                            .rotationEffect(.degrees(-45))
                    }
                }
                
                // Data rows
                ForEach(Array(data.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: 0) {
                        Text(rowLabels[rowIndex])
                            .font(HealthAIDesignSystem.Typography.caption)
                            .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
                            .frame(width: 80, alignment: .leading)
                        
                        ForEach(Array(row.enumerated()), id: \.offset) { colIndex, value in
                            Rectangle()
                                .fill(cellColor(for: value))
                                .frame(height: 30)
                                .overlay(
                                    Text(String(format: "%.1f", value))
                                        .font(HealthAIDesignSystem.Typography.caption2)
                                        .foregroundColor(.white)
                                )
                                .accessibilityLabel(Text("\(rowLabels[rowIndex]) \(columnLabels[colIndex]): \(String(format: "%.1f", value))"))
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(accessibilityLabel))
        }
    }
    
    private var minValue: Double {
        data.flatMap { $0 }.min() ?? 0
    }
    
    private var maxValue: Double {
        data.flatMap { $0 }.max() ?? 1
    }
    
    private func cellColor(for value: Double) -> Color {
        colorScale.color(for: value, min: minValue, max: maxValue)
    }
    
    private var accessibilityLabel: String {
        let titleText = title ?? "Heatmap"
        return "\(titleText) with \(rowLabels.count) rows and \(columnLabels.count) columns"
    }
}
