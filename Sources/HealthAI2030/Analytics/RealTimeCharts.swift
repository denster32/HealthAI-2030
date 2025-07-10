// RealTimeCharts.swift
// HealthAI 2030 - Agent 6 Analytics
// Real-time charting engine for live analytics

import Foundation

public struct RealTimeChartData {
    public let timestamp: Date
    public let value: Double
    public let label: String
}

public class RealTimeCharts {
    private(set) public var data: [RealTimeChartData] = []
    
    public init() {}
    
    public func addDataPoint(_ dataPoint: RealTimeChartData) {
        data.append(dataPoint)
    }
    
    public func latestDataPoints(count: Int) -> [RealTimeChartData] {
        return Array(data.suffix(count))
    }
    
    public func clear() {
        data.removeAll()
    }
}
