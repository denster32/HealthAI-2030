import Foundation

class XAIExplanationGenerator {
    static let shared = XAIExplanationGenerator()
    
    struct Explanation {
        let title: String
        let summary: String
        let contributingFactors: [String]
        let modelConfidence: Double?
        let reference: String?
    }
    
    // MARK: - Explanation Generation
    func generateExplanation(for alert: AlertRuleEngine.TriggeredAlert, context: AlertContext) -> Explanation {
        let rule = alert.rule
        var factors: [String] = []
        var confidence: Double? = context.confidenceByMetric[rule.metricKey]
        var reference: String? = nil
        
        // Example: Add contributing factors based on metricKey
        switch rule.metricKey {
        case "ecg_ischemia_risk":
            factors.append("ST segment changes detected above critical threshold.")
            reference = "ECGInsightManager, STSegmentAnalyzer"
        case "af_overall_risk":
            factors.append("AF forecast model predicts high conversion risk.")
            reference = "AFForecastModel, AFFeatureExtractor"
        case "qt_dynamic_risk":
            factors.append("QT-RR slope or variability abnormal.")
            reference = "QTDynamicAnalyzer"
        case "sleep_quality":
            factors.append("Sleep quality score below healthy range.")
            reference = "SleepOptimizationManager"
        default:
            factors.append("Metric \(rule.metricKey) triggered alert.")
        }
        
        let summary = "Alert triggered: \(rule.name). Reason: \(rule.description) Value: \(alert.value)."
        
        return Explanation(
            title: rule.name,
            summary: summary,
            contributingFactors: factors,
            modelConfidence: confidence,
            reference: reference
        )
    }
}