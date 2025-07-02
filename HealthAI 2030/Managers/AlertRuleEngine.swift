import Foundation

class AlertRuleEngine {
    static let shared = AlertRuleEngine()
    
    // MARK: - Alert Rule Definition
    struct AlertRule {
        let id: String
        let name: String
        let description: String
        let metricKey: String
        let threshold: Double
        let comparison: ComparisonType
        let severity: AlertSeverity
        let enabled: Bool
    }
    
    enum ComparisonType {
        case greaterThan
        case lessThan
        case equalTo
    }
    
    enum AlertSeverity: String, Codable {
        case critical, urgent, advisory, informational
    }
    
    // MARK: - Rule Set
    private(set) var rules: [AlertRule] = [
        AlertRule(
            id: "ecg_ischemia_critical",
            name: "Critical Ischemia Detected",
            description: "ST segment changes indicating acute ischemia.",
            metricKey: "ecg_ischemia_risk",
            threshold: 0.8,
            comparison: .greaterThan,
            severity: .critical,
            enabled: true
        ),
        AlertRule(
            id: "af_forecast_high",
            name: "High AF Conversion Risk",
            description: "AF forecast risk exceeds high threshold.",
            metricKey: "af_overall_risk",
            threshold: 0.7,
            comparison: .greaterThan,
            severity: .urgent,
            enabled: true
        ),
        AlertRule(
            id: "qt_dynamic_abnormal",
            name: "QT Dynamics Abnormal",
            description: "QT-RR slope or variability abnormal.",
            metricKey: "qt_dynamic_risk",
            threshold: 0.5,
            comparison: .greaterThan,
            severity: .advisory,
            enabled: true
        ),
        AlertRule(
            id: "sleep_quality_low",
            name: "Low Sleep Quality",
            description: "Sleep quality score below threshold.",
            metricKey: "sleep_quality",
            threshold: 60.0,
            comparison: .lessThan,
            severity: .advisory,
            enabled: true
        )
    ]
    
    // MARK: - Rule Evaluation
    func evaluate(metrics: [String: Double]) -> [TriggeredAlert] {
        var triggered: [TriggeredAlert] = []
        for rule in rules where rule.enabled {
            if let value = metrics[rule.metricKey], compare(value: value, rule: rule) {
                triggered.append(TriggeredAlert(
                    rule: rule,
                    value: value,
                    timestamp: Date()
                ))
            }
        }
        return triggered
    }
    
    private func compare(value: Double, rule: AlertRule) -> Bool {
        switch rule.comparison {
        case .greaterThan:
            return value > rule.threshold
        case .lessThan:
            return value < rule.threshold
        case .equalTo:
            return value == rule.threshold
        }
    }
    
    // MARK: - Alert Struct
    struct TriggeredAlert {
        let rule: AlertRule
        let value: Double
        let timestamp: Date
    }
}

struct STShiftInsight {
    let zScore: Double
    let consecutiveExcursions: Int
    let isCritical: Bool
}