import Foundation

/// Example plugin: Personalized Sleep Coach
public class PersonalizedSleepCoachPlugin: HealthAIPlugin {
    public let pluginName = "Personalized Sleep Coach"
    public let pluginDescription = "Provides tailored sleep tips and reminders based on your data."
    
    private let explainableAI = ExplainableAI() // Initialize ExplainableAI

    public func activate() {
        // TODO: Integrate with sleep analytics and notification APIs
        print("Personalized Sleep Coach activated!")
    }
    
    /// Provides a personalized sleep recommendation with an explanation.
    /// - Parameter sleepData: A dictionary of relevant sleep data (e.g., "averageSleep", "sleepQuality").
    /// - Returns: A tuple containing the recommendation string and its explanation.
    public func getSleepRecommendation(sleepData: [String: Any]) -> (recommendation: String, explanation: Explanation) {
        var recommendation = "Based on your sleep patterns, aim for consistent sleep times."
        
        // Example recommendation logic
        if let averageSleep = sleepData["averageSleep"] as? Double, averageSleep < 7.0 {
            recommendation = "Your average sleep duration is low. Try going to bed 30 minutes earlier."
        } else if let sleepQuality = sleepData["sleepQuality"] as? Double, sleepQuality < 0.7 {
            recommendation = "Your sleep quality could be improved. Ensure your bedroom is dark and cool."
        }
        
        let explanation = explainableAI.generateExplanation(for: recommendation, healthData: sleepData)
        
        return (recommendation, explanation)
    }
}

// Register plugin
PluginManager.shared.register(plugin: PersonalizedSleepCoachPlugin())
