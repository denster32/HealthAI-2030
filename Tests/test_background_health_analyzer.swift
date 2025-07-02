#!/usr/bin/env swift
import Foundation

enum AnomalySeverity { case low, medium, high, critical }
struct HealthAnomaly { let severity: AnomalySeverity }
struct HealthAnalysis { let anomalies: [HealthAnomaly] }
struct HealthTrend { let confidence: Double; let magnitude: Double }
struct HealthPattern { let confidence: Double }

func countSignificantFindings(_ analyses: [String: HealthAnalysis], _ trends: [String: HealthTrend], _ patterns: [String: HealthPattern]) -> Int {
    var count = 0
    for analysis in analyses.values {
        count += analysis.anomalies.filter { $0.severity == .high || $0.severity == .critical }.count
    }
    for trend in trends.values where trend.confidence > 0.8 && abs(trend.magnitude) > 0.1 {
        count += 1
    }
    for pattern in patterns.values where pattern.confidence > 0.8 {
        count += 1
    }
    return count
}

struct MockModel { let metadataAccuracy: Double; let featureCount: Int }

func calculateModelAccuracy(models: [MockModel]) -> Double {
    guard !models.isEmpty else { return 0.0 }
    let total = models.map { model -> Double in
        if model.metadataAccuracy > 0 {
            return model.metadataAccuracy
        } else {
            return 0.5 + 0.02 * Double(model.featureCount)
        }
    }.reduce(0, +)
    return total / Double(models.count)
}

// Test cases
let analyses = [
    "hr": HealthAnalysis(anomalies: [HealthAnomaly(severity: .high), HealthAnomaly(severity: .low)]),
    "rr": HealthAnalysis(anomalies: [HealthAnomaly(severity: .critical)])
]
let trends = [
    "hr": HealthTrend(confidence: 0.9, magnitude: 0.2),
    "rr": HealthTrend(confidence: 0.5, magnitude: 0.3)
]
let patterns = [
    "sleep": HealthPattern(confidence: 0.85)
]
assert(countSignificantFindings(analyses, trends, patterns) == 4)

let models = [
    MockModel(metadataAccuracy: 0.9, featureCount: 5),
    MockModel(metadataAccuracy: 0.0, featureCount: 4)
]
let expected = (0.9 + (0.5 + 0.02*4)) / 2
let accuracy = calculateModelAccuracy(models: models)
assert(abs(accuracy - expected) < 0.0001)
print("All tests passed")
