import Foundation

class AlertPrioritizer {
    static let shared = AlertPrioritizer()
    
    struct PrioritizedAlert {
        let alert: AlertRuleEngine.TriggeredAlert
        let triageRank: TriageRank
        let priorityScore: Double
    }
    
    enum TriageRank: String, Codable {
        case critical, urgent, advisory, informational
    }
    
    // MARK: - Prioritization Logic
    func prioritize(alerts: [AlertRuleEngine.TriggeredAlert], context: AlertContext) -> [PrioritizedAlert] {
        return alerts.map { alert in
            let score = calculatePriorityScore(alert: alert, context: context)
            let rank = triageRank(for: alert, score: score)
            return PrioritizedAlert(alert: alert, triageRank: rank, priorityScore: score)
        }.sorted { $0.priorityScore > $1.priorityScore }
    }
    
    private func calculatePriorityScore(alert: AlertRuleEngine.TriggeredAlert, context: AlertContext) -> Double {
        // Base score from severity
        var score: Double = 0.0
        switch alert.rule.severity {
        case .critical: score += 1.0
        case .urgent: score += 0.8
        case .advisory: score += 0.5
        case .informational: score += 0.2
        }
        // Confidence adjustment (if available)
        if let confidence = context.confidenceByMetric[alert.rule.metricKey] {
            score *= confidence
        }
        // User history adjustment (e.g., recent similar alerts)
        if let recentCount = context.recentAlertCounts[alert.rule.id], recentCount > 2 {
            score *= 0.8 // Deprioritize repeated alerts
        }
        // Contextual adjustment (e.g., time of day, activity)
        if context.isNightTime && alert.rule.metricKey == "sleep_quality" {
            score += 0.1
        }
        return min(score, 1.0)
    }
    
    private func triageRank(for alert: AlertRuleEngine.TriggeredAlert, score: Double) -> TriageRank {
        switch score {
        case 0.9...1.0: return .critical
        case 0.7..<0.9: return .urgent
        case 0.4..<0.7: return .advisory
        default: return .informational
        }
    }
}

struct AlertContext {
    let confidenceByMetric: [String: Double]
    let recentAlertCounts: [String: Int]
    let isNightTime: Bool
}

struct TriageRank {
    enum Rank: String {
        case critical = "Critical"
        case urgent = "Urgent"
        case advisory = "Advisory"
        case informational = "Informational"
    }
    let rank: Rank
    let score: Int // Numerical score for finer-grained prioritization
}