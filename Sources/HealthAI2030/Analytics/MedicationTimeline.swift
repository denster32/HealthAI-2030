// MedicationTimeline.swift
// HealthAI 2030 - Agent 6 Analytics
// Timeline visualization for medication adherence and events

import Foundation

public struct MedicationTimelineEvent {
    public let timestamp: Date
    public let medicationId: String
    public let eventType: String
}

public class MedicationTimeline {
    private(set) public var events: [MedicationTimelineEvent] = []
    
    public init() {}
    
    public func addEvent(_ event: MedicationTimelineEvent) {
        events.append(event)
    }
    
    public func events(for medicationId: String) -> [MedicationTimelineEvent] {
        return events.filter { $0.medicationId == medicationId }
    }
    
    public func latestEvent(for medicationId: String) -> MedicationTimelineEvent? {
        return events.filter { $0.medicationId == medicationId }.sorted { $0.timestamp > $1.timestamp }.first
    }
}
