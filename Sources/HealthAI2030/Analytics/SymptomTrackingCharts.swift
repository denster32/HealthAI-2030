// SymptomTrackingCharts.swift
// HealthAI 2030 - Agent 6 Analytics
// Visualization for symptom tracking and trends

import Foundation

public struct SymptomTrackingDataPoint {
    public let timestamp: Date
    public let symptom: String
    public let severity: Double
}

public class SymptomTrackingCharts {
    private(set) public var data: [SymptomTrackingDataPoint] = []
    
    public init() {}
    
    public func addDataPoint(_ dataPoint: SymptomTrackingDataPoint) {
        data.append(dataPoint)
    }
    
    public func dataPoints(for symptom: String) -> [SymptomTrackingDataPoint] {
        return data.filter { $0.symptom == symptom }
    }
    
    public func latestDataPoint(for symptom: String) -> SymptomTrackingDataPoint? {
        return data.filter { $0.symptom == symptom }.sorted { $0.timestamp > $1.timestamp }.first
    }
}
