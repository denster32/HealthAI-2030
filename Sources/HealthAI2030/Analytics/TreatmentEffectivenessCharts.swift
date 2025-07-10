// TreatmentEffectivenessCharts.swift
// HealthAI 2030 - Agent 6 Analytics
// Visualization for treatment effectiveness over time

import Foundation

public struct TreatmentEffectivenessDataPoint {
    public let timestamp: Date
    public let treatmentId: String
    public let effectiveness: Double
}

public class TreatmentEffectivenessCharts {
    private(set) public var data: [TreatmentEffectivenessDataPoint] = []
    
    public init() {}
    
    public func addDataPoint(_ dataPoint: TreatmentEffectivenessDataPoint) {
        data.append(dataPoint)
    }
    
    public func dataPoints(for treatmentId: String) -> [TreatmentEffectivenessDataPoint] {
        return data.filter { $0.treatmentId == treatmentId }
    }
    
    public func latestDataPoint(for treatmentId: String) -> TreatmentEffectivenessDataPoint? {
        return data.filter { $0.treatmentId == treatmentId }.sorted { $0.timestamp > $1.timestamp }.first
    }
}
