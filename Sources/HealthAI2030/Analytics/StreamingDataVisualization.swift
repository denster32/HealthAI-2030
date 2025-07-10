//
//  StreamingDataVisualization.swift
//  HealthAI 2030
//
//  Created by Agent 6 (Analytics) on 2025-01-14
//  Real-time data visualization system
//

import Foundation
import SwiftUI
import Combine
import Charts

/// Real-time streaming data visualization system
public class StreamingDataVisualization: ObservableObject {
    
    // MARK: - Properties
    
    @Published public var activeCharts: [StreamingChart] = []
    @Published public var dataBuffer: [ChartDataPoint] = []
    @Published public var updateFrequency: TimeInterval = 1.0
    @Published public var isStreaming: Bool = false
    
    private var streamingTimer: Timer?
    private let maxDataPoints: Int = 1000
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init() {
        setupStreamingVisualization()
    }
    
    // MARK: - Streaming Visualization Methods
    
    /// Start streaming data visualization
    public func startStreaming(frequency: TimeInterval = 1.0) {
        updateFrequency = frequency
        isStreaming = true
        
        streamingTimer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { [weak self] _ in
            self?.updateVisualizations()
        }
    }
    
    /// Stop streaming data visualization
    public func stopStreaming() {
        isStreaming = false
        streamingTimer?.invalidate()
        streamingTimer = nil
    }
    
    /// Add new chart to streaming system
    public func addChart(_ chart: StreamingChart) {
        activeCharts.append(chart)
    }
    
    /// Remove chart from streaming system
    public func removeChart(id: UUID) {
        activeCharts.removeAll { $0.id == id }
    }
    
    /// Update all active visualizations
    private func updateVisualizations() {
        for chart in activeCharts {
            updateChart(chart)
        }
        
        // Cleanup old data points
        cleanupDataBuffer()
    }
    
    /// Update specific chart with new data
    private func updateChart(_ chart: StreamingChart) {
        let newDataPoint = generateDataPoint(for: chart)
        
        DispatchQueue.main.async { [weak self] in
            self?.dataBuffer.append(newDataPoint)
            chart.addDataPoint(newDataPoint)
        }
    }
    
    /// Generate new data point for chart
    private func generateDataPoint(for chart: StreamingChart) -> ChartDataPoint {
        let value = generateValue(for: chart.type)
        
        return ChartDataPoint(
            id: UUID(),
            timestamp: Date(),
            value: value,
            chartType: chart.type,
            label: chart.title
        )
    }
    
    /// Generate value based on chart type
    private func generateValue(for chartType: ChartType) -> Double {
        switch chartType {
        case .heartRate:
            return Double.random(in: 60...100) + sin(Date().timeIntervalSince1970 / 10) * 10
        case .bloodPressure:
            return Double.random(in: 110...140) + cos(Date().timeIntervalSince1970 / 15) * 5
        case .glucose:
            return Double.random(in: 80...120) + sin(Date().timeIntervalSince1970 / 20) * 8
        case .activity:
            return Double.random(in: 0...1000) + abs(sin(Date().timeIntervalSince1970 / 5)) * 500
        case .temperature:
            return 98.6 + Double.random(in: -1...1)
        case .oxygenSaturation:
            return Double.random(in: 95...100)
        }
    }
    
    /// Cleanup old data points
    private func cleanupDataBuffer() {
        if dataBuffer.count > maxDataPoints {
            let removeCount = dataBuffer.count - maxDataPoints
            dataBuffer.removeFirst(removeCount)
        }
    }
    
    // MARK: - Chart Creation Methods
    
    /// Create heart rate streaming chart
    public func createHeartRateChart() -> StreamingChart {
        return StreamingChart(
            title: "Heart Rate",
            type: .heartRate,
            color: .red,
            yAxisRange: 50...150
        )
    }
    
    /// Create blood pressure streaming chart
    public func createBloodPressureChart() -> StreamingChart {
        return StreamingChart(
            title: "Blood Pressure",
            type: .bloodPressure,
            color: .blue,
            yAxisRange: 80...180
        )
    }
    
    /// Create glucose streaming chart
    public func createGlucoseChart() -> StreamingChart {
        return StreamingChart(
            title: "Glucose Level",
            type: .glucose,
            color: .green,
            yAxisRange: 60...200
        )
    }
    
    /// Create activity streaming chart
    public func createActivityChart() -> StreamingChart {
        return StreamingChart(
            title: "Activity Level",
            type: .activity,
            color: .orange,
            yAxisRange: 0...2000
        )
    }
    
    // MARK: - Data Export Methods
    
    /// Export streaming data to CSV
    public func exportToCSV() -> String {
        var csv = "Timestamp,Chart Type,Value,Label\n"
        
        for dataPoint in dataBuffer {
            csv += "\(dataPoint.timestamp),\(dataPoint.chartType),\(dataPoint.value),\(dataPoint.label)\n"
        }
        
        return csv
    }
    
    /// Export streaming data to JSON
    public func exportToJSON() -> Data? {
        return try? JSONEncoder().encode(dataBuffer)
    }
    
    private func setupStreamingVisualization() {
        // Initialize default charts
        let heartRateChart = createHeartRateChart()
        let bloodPressureChart = createBloodPressureChart()
        let glucoseChart = createGlucoseChart()
        
        addChart(heartRateChart)
        addChart(bloodPressureChart)
        addChart(glucoseChart)
    }
}

// MARK: - Supporting Types

public class StreamingChart: ObservableObject, Identifiable {
    public let id = UUID()
    public let title: String
    public let type: ChartType
    public let color: Color
    public let yAxisRange: ClosedRange<Double>
    
    @Published public var dataPoints: [ChartDataPoint] = []
    @Published public var isVisible: Bool = true
    
    private let maxPoints: Int = 50
    
    public init(title: String, type: ChartType, color: Color, yAxisRange: ClosedRange<Double>) {
        self.title = title
        self.type = type
        self.color = color
        self.yAxisRange = yAxisRange
    }
    
    public func addDataPoint(_ point: ChartDataPoint) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.dataPoints.append(point)
            
            // Keep only recent data points
            if self.dataPoints.count > self.maxPoints {
                self.dataPoints.removeFirst(self.dataPoints.count - self.maxPoints)
            }
        }
    }
    
    public func clearData() {
        dataPoints.removeAll()
    }
}

public struct ChartDataPoint: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let value: Double
    public let chartType: ChartType
    public let label: String
    
    public init(id: UUID, timestamp: Date, value: Double, chartType: ChartType, label: String) {
        self.id = id
        self.timestamp = timestamp
        self.value = value
        self.chartType = chartType
        self.label = label
    }
}

public enum ChartType: String, CaseIterable, Codable {
    case heartRate = "heart_rate"
    case bloodPressure = "blood_pressure"
    case glucose = "glucose"
    case activity = "activity"
    case temperature = "temperature"
    case oxygenSaturation = "oxygen_saturation"
    
    public var displayName: String {
        switch self {
        case .heartRate:
            return "Heart Rate"
        case .bloodPressure:
            return "Blood Pressure"
        case .glucose:
            return "Glucose"
        case .activity:
            return "Activity"
        case .temperature:
            return "Temperature"
        case .oxygenSaturation:
            return "Oxygen Saturation"
        }
    }
    
    public var unit: String {
        switch self {
        case .heartRate:
            return "BPM"
        case .bloodPressure:
            return "mmHg"
        case .glucose:
            return "mg/dL"
        case .activity:
            return "Steps"
        case .temperature:
            return "°F"
        case .oxygenSaturation:
            return "%"
        }
    }
}

// MARK: - SwiftUI Chart View

public struct StreamingChartView: View {
    @ObservedObject private var chart: StreamingChart
    
    public init(chart: StreamingChart) {
        self.chart = chart
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chart.title)
                .font(.headline)
                .foregroundColor(chart.color)
            
            Chart(chart.dataPoints) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(chart.color)
                .interpolationMethod(.cardinal)
            }
            .chartYScale(domain: chart.yAxisRange)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour().minute())
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
