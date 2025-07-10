// PatientOutcomesDashboard.swift
// HealthAI 2030 - Agent 6 Analytics
// Dashboard for visualizing and tracking patient outcomes

import Foundation

public struct PatientOutcome {
    public let patientId: String
    public let outcomeType: String
    public let value: Double
    public let timestamp: Date
}

public class PatientOutcomesDashboard {
    private(set) public var outcomes: [PatientOutcome] = []
    
    public init() {}
    
    public func addOutcome(_ outcome: PatientOutcome) {
        outcomes.append(outcome)
    }
    
    public func outcomes(for patientId: String) -> [PatientOutcome] {
        return outcomes.filter { $0.patientId == patientId }
    }
    
    public func latestOutcome(for patientId: String, type: String) -> PatientOutcome? {
        return outcomes.filter { $0.patientId == patientId && $0.outcomeType == type }.sorted { $0.timestamp > $1.timestamp }.first
    }
    
    public func outcomesSummary() -> [String: [String: Double]] {
        var summary: [String: [String: Double]] = [:]
        let grouped = Dictionary(grouping: outcomes, by: { $0.patientId })
        for (patientId, group) in grouped {
            for outcome in group {
                summary[patientId, default: [:]][outcome.outcomeType] = outcome.value
            }
        }
        return summary
    }
}
