import Foundation

/// Explainable AI logic for HealthAI 2030.
public class ExplainableAI {
    public init() {}
    /// Generates a user-friendly explanation for a recommendation, using context and data.
    public func explanation(for recommendation: String, context: [String: Any]) -> String {
        // Example: Use context to generate a tailored explanation
        if recommendation.contains("earlier bedtime"),
           let avgSleep = context["averageSleep"] as? Double {
            if avgSleep < 7.0 {
                return "We recommended an earlier bedtime because your average sleep duration was below 7 hours for the past week."
            } else {
                return "We recommended an earlier bedtime to help you feel more rested, based on your recent sleep patterns."
            }
        }
        // Add more rules for other recommendations
        return "This recommendation is based on your recent health data and trends."
    }
    public func sampleExplanation() -> String {
        return explanation(for: "earlier bedtime", context: ["averageSleep": 6.5])
    }
}
