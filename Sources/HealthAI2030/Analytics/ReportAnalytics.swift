// ReportAnalytics.swift
// HealthAI 2030 - Agent 6 Analytics
// Analytics for generated and scheduled reports

import Foundation

public struct ReportAnalyticsSummary {
    public let reportId: UUID
    public let views: Int
    public let downloads: Int
    public let shares: Int
    public let lastAccessed: Date?
}

public class ReportAnalytics {
    private(set) public var summaries: [ReportAnalyticsSummary] = []
    
    public init() {}
    
    public func addSummary(_ summary: ReportAnalyticsSummary) {
        summaries.append(summary)
    }
    
    public func summary(for reportId: UUID) -> ReportAnalyticsSummary? {
        return summaries.first { $0.reportId == reportId }
    }
    
    public func mostViewedReports(top n: Int) -> [ReportAnalyticsSummary] {
        return summaries.sorted { $0.views > $1.views }.prefix(n).map { $0 }
    }
}
