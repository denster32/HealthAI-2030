import Foundation

/// Represents a structured explanation for a health recommendation.
public struct Explanation: Identifiable, Codable {
    public let id = UUID()
    public let recommendation: String
    public let summary: String
    public let featureImportances: [FeatureImportance]
    public let decisionPath: [String]
    public let confidenceScore: Double // 0.0 to 1.0

    public init(recommendation: String, summary: String, featureImportances: [FeatureImportance], decisionPath: [String], confidenceScore: Double) {
        self.recommendation = recommendation
        self.summary = summary
        self.featureImportances = featureImportances
        self.decisionPath = decisionPath
        self.confidenceScore = confidenceScore
    }
}

/// Represents the importance of a specific feature in a recommendation.
public struct FeatureImportance: Identifiable, Codable {
    public let id = UUID()
    public let feature: String
    public let importance: Double // e.g., 0.0 to 1.0, or a raw score
    public let unit: String?

    public init(feature: String, importance: Double, unit: String? = nil) {
        self.feature = feature
        self.importance = importance
        self.unit = unit
    }
}

/// Explainable AI logic for HealthAI 2030.
public class ExplainableAI {
    public init() {}

    /// Generates a comprehensive explanation for a recommendation.
    /// - Parameters:
    ///   - recommendation: The health recommendation provided.
    ///   - healthData: A dictionary of relevant health data features and their values.
    ///   - modelOutput: Optional, raw output from an ML model if applicable.
    /// - Returns: A structured `Explanation` object.
    public func generateExplanation(for recommendation: String, healthData: [String: Any], modelOutput: [String: Any]? = nil) -> Explanation {
        var summary = "This recommendation is based on your recent health data and trends."
        var featureImportances: [FeatureImportance] = []
        var decisionPath: [String] = []
        var confidenceScore: Double = 0.7 // Default confidence

        // 1. Feature Importance (Example Logic)
        if let sleepDuration = healthData["sleepDuration"] as? Double {
            featureImportances.append(FeatureImportance(feature: "Sleep Duration", importance: sleepDuration / 8.0, unit: "hours"))
        }
        if let heartRateVariability = healthData["heartRateVariability"] as? Double {
            featureImportances.append(FeatureImportance(feature: "Heart Rate Variability", importance: heartRateVariability / 100.0, unit: "ms"))
        }
        if let activityLevel = healthData["activityLevel"] as? Double {
            featureImportances.append(FeatureImportance(feature: "Activity Level", importance: activityLevel / 10000.0, unit: "steps"))
        }

        // 2. Rule Extraction/Decision Path (Example Logic)
        if recommendation.contains("earlier bedtime") {
            if let avgSleep = healthData["averageSleep"] as? Double {
                if avgSleep < 7.0 {
                    summary = "We recommended an earlier bedtime because your average sleep duration was below 7 hours for the past week."
                    decisionPath.append("Rule: Average sleep < 7 hours -> Recommend earlier bedtime")
                    confidenceScore = 0.9
                } else {
                    summary = "We recommended an earlier bedtime to help you feel more rested, based on your recent sleep patterns."
                    decisionPath.append("Rule: Recent sleep patterns indicate need for more rest")
                    confidenceScore = 0.75
                }
            }
        } else if recommendation.contains("increase daily steps") {
            if let dailySteps = healthData["dailySteps"] as? Int, dailySteps < 5000 {
                summary = "We recommended increasing your daily steps because your average daily activity level is below 5000 steps."
                decisionPath.append("Rule: Daily steps < 5000 -> Recommend increasing steps")
                confidenceScore = 0.88
            }
        }
        // Add more specific rules/decision paths based on recommendation type

        // 3. Confidence Scores (Example Logic - could be derived from ML model output)
        if let mlConfidence = modelOutput?["confidence"] as? Double {
            confidenceScore = mlConfidence
        }

        return Explanation(
            recommendation: recommendation,
            summary: summary,
            featureImportances: featureImportances.sorted(by: { $0.importance > $1.importance }),
            decisionPath: decisionPath,
            confidenceScore: min(1.0, max(0.0, confidenceScore)) // Ensure score is between 0 and 1
        )
    }

    /// Provides a sample explanation for demonstration purposes.
    public func sampleExplanation() -> Explanation {
        let sampleHealthData: [String: Any] = [
            "averageSleep": 6.5,
            "sleepDuration": 6.2,
            "heartRateVariability": 45.0,
            "activityLevel": 4000.0,
            "dailySteps": 3500
        ]
        return generateExplanation(for: "earlier bedtime", healthData: sampleHealthData)
    }
}
