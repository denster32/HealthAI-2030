import Foundation

/// Engine for generating counterfactual "what-if" scenarios for model predictions.
public class CounterfactualExplanationEngine {
    public init() {}

    /// Generates a counterfactual prediction given modifications to input features.
    /// - Parameters:
    ///   - originalFeatures: Original feature set.
    ///   - modifiedFeatures: Modified feature set for what-if scenario.
    /// - Returns: New prediction based on modified features.
    public func explainWhatIf(originalFeatures: [String: Double], modifiedFeatures: [String: Double]) -> Double {
        // Implementation for counterfactual analysis
        // Calculate the difference between original and modified features
        var featureChanges: [String: Double] = [:]
        var totalChange = 0.0
        
        for (key, originalValue) in originalFeatures {
            if let modifiedValue = modifiedFeatures[key] {
                let change = modifiedValue - originalValue
                featureChanges[key] = change
                totalChange += abs(change)
            }
        }
        
        // Calculate impact weights based on feature importance
        let impactWeights = calculateFeatureImpactWeights(featureChanges: featureChanges)
        
        // Simulate prediction change based on feature modifications
        let predictionChange = calculatePredictionChange(
            featureChanges: featureChanges,
            impactWeights: impactWeights
        )
        
        // Return the simulated new prediction
        // In a real implementation, this would re-run the actual model
        let basePrediction = 0.5 // Simulated base prediction
        let newPrediction = basePrediction + predictionChange
        
        // Ensure prediction stays within valid range [0, 1]
        return max(0.0, min(1.0, newPrediction))
    }
    
    /// Calculate impact weights for different features
    private func calculateFeatureImpactWeights(featureChanges: [String: Double]) -> [String: Double] {
        var weights: [String: Double] = [:]
        let totalChange = featureChanges.values.map { abs($0) }.reduce(0, +)
        
        for (feature, change) in featureChanges {
            if totalChange > 0 {
                // Weight based on relative change magnitude
                weights[feature] = abs(change) / totalChange
            } else {
                weights[feature] = 1.0 / Double(featureChanges.count)
            }
        }
        
        return weights
    }
    
    /// Calculate prediction change based on feature modifications and their impacts
    private func calculatePredictionChange(featureChanges: [String: Double], impactWeights: [String: Double]) -> Double {
        var totalImpact = 0.0
        
        for (feature, change) in featureChanges {
            let weight = impactWeights[feature] ?? 0.0
            let impact = change * weight * getFeatureSensitivity(feature: feature)
            totalImpact += impact
        }
        
        // Normalize the impact to a reasonable prediction change
        return totalImpact * 0.1 // Scale factor to keep changes reasonable
    }
    
    /// Get feature sensitivity based on feature type
    private func getFeatureSensitivity(feature: String) -> Double {
        // Define sensitivity levels for different feature types
        let sensitivityMap: [String: Double] = [
            "heart_rate": 0.8,
            "blood_pressure": 0.9,
            "sleep_duration": 0.7,
            "activity_level": 0.6,
            "stress_level": 0.8,
            "age": 0.5,
            "weight": 0.4,
            "bmi": 0.6
        ]
        
        return sensitivityMap[feature.lowercased()] ?? 0.5
    }
} 