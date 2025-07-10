// QualityMetricsDashboard.swift
// HealthAI 2030 - Agent 6 Analytics
// Dashboard for visualizing and tracking quality metrics across the platform

import Foundation

public struct QualityMetric {
    public let name: String
    public let value: Double
    public let target: Double?
    public let timestamp: Date
}

public class QualityMetricsDashboard {
    private(set) public var metrics: [QualityMetric] = []
    
    public init() {}
    
    public func addMetric(_ metric: QualityMetric) {
        metrics.append(metric)
    }
    
    public func metrics(for name: String) -> [QualityMetric] {
        return metrics.filter { $0.name == name }
    }
    
    public func latestMetric(for name: String) -> QualityMetric? {
        return metrics.filter { $0.name == name }.sorted { $0.timestamp > $1.timestamp }.first
    }
    
    public func metricsSummary() -> [String: (latest: Double, target: Double?)] {
        var summary: [String: (Double, Double?)] = [:]
        let grouped = Dictionary(grouping: metrics, by: { $0.name })
        for (name, group) in grouped {
            if let latest = group.sorted(by: { $0.timestamp > $1.timestamp }).first {
                summary[name] = (latest.value, latest.target)
            }
        }
        return summary
    }
}
