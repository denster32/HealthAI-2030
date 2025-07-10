// VitalSignsCharts.swift
// HealthAI 2030 - Agent 6 Analytics
// Visualization of vital signs over time

import Foundation

public struct VitalSignDataPoint {
    public let timestamp: Date
    public let type: String
    public let value: Double
}

public class VitalSignsCharts {
    private(set) public var data: [VitalSignDataPoint] = []
    
    public init() {}
    
    public func addDataPoint(_ dataPoint: VitalSignDataPoint) {
        data.append(dataPoint)
    }
    
    public func dataPoints(for type: String) -> [VitalSignDataPoint] {
        return data.filter { $0.type == type }
    }
    
    public func latestDataPoint(for type: String) -> VitalSignDataPoint? {
        return data.filter { $0.type == type }.sorted { $0.timestamp > $1.timestamp }.first
    }
}
