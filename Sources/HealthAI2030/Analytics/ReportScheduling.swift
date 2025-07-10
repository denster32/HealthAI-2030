// ReportScheduling.swift
// HealthAI 2030 - Agent 6 Analytics
// Automated and custom report scheduling logic

import Foundation

public struct ScheduledReport {
    public let id: UUID
    public let reportType: String
    public let schedule: ReportSchedule
    public let recipients: [String]
    public let lastRun: Date?
    public let nextRun: Date?
}

public struct ReportSchedule {
    public let frequency: Frequency
    public let time: DateComponents
    public enum Frequency: String {
        case daily, weekly, monthly, quarterly, yearly
    }
}

public class ReportScheduler {
    private(set) public var scheduledReports: [ScheduledReport] = []
    
    public init() {}
    
    public func scheduleReport(_ report: ScheduledReport) {
        scheduledReports.append(report)
    }
    
    public func removeReport(id: UUID) {
        scheduledReports.removeAll { $0.id == id }
    }
    
    public func nextScheduledReports(after date: Date) -> [ScheduledReport] {
        return scheduledReports.filter { ($0.nextRun ?? Date.distantPast) > date }
    }
}
