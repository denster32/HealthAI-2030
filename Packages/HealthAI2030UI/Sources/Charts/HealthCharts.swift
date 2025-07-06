
import SwiftUI
import Charts

// MARK: - HealthLineChart
public struct HealthLineChart: View {
    let data: [Point]
    
    public var body: some View {
        Chart(data) {
            LineMark(
                x: .value("Date", $0.date),
                y: .value("Value", $0.value)
            )
            .foregroundStyle(HealthAIDesignSystem.Color.healthPrimary)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Line chart showing health data over time.")
    }
}

// MARK: - HealthBarChart
public struct HealthBarChart: View {
    let data: [Point]
    
    public var body: some View {
        Chart(data) {
            BarMark(
                x: .value("Date", $0.date, unit: .day),
                y: .value("Value", $0.value)
            )
            .foregroundStyle(HealthAIDesignSystem.Color.healthSecondary)
        }
        .chartXAxis(.hidden)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Bar chart showing daily health data.")
    }
}

// MARK: - HealthPieChart
public struct HealthPieChart: View {
    let data: [CategoryValue]

    public var body: some View {
        Chart(data) {
            SectorMark(
                angle: .value("Value", $0.value),
                innerRadius: .ratio(0.618),
                angularInset: 1.5
            )
            .cornerRadius(5)
            .foregroundStyle(by: .value("Category", $0.category))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pie chart showing categorical health data.")
    }
}

// MARK: - Data Structures
public struct Point: Identifiable {
    public let id = UUID()
    let date: Date
    let value: Double
}

public struct CategoryValue: Identifiable {
    public let id = UUID()
    let category: String
    let value: Double
}
