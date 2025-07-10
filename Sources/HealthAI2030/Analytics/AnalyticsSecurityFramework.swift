// AnalyticsSecurityFramework.swift
// HealthAI 2030 - Agent 6 Analytics
// Security framework for analytics modules and data

import Foundation

public struct AnalyticsSecurityEvent {
    public let timestamp: Date
    public let eventType: String
    public let description: String
}

public class AnalyticsSecurityFramework {
    private(set) public var events: [AnalyticsSecurityEvent] = []
    
    public init() {}
    
    public func logEvent(_ event: AnalyticsSecurityEvent) {
        events.append(event)
    }
    
    public func events(ofType type: String) -> [AnalyticsSecurityEvent] {
        return events.filter { $0.eventType == type }
    }
    
    public func latestEvent() -> AnalyticsSecurityEvent? {
        return events.sorted { $0.timestamp > $1.timestamp }.first
    }
}
