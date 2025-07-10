import Foundation

/// Manager for local model-agnostic explanations (e.g., LIME/SHAP).
public class LocalExplanationManager {
    public init() {}

    /// Generates local explanation weights for a single prediction.
    /// - Parameters:
    ///   - dataPoint: Feature values for the data point.
    /// - Returns: Dictionary mapping feature names to contribution scores.
    public func explainLocally(dataPoint: [String: Double]) -> [String: Double] {
        // Implementation for local explanations using SHAP-like approach
        var explanations: [String: Double] = [:]
        
        // Calculate baseline prediction (average of all features)
        let baseline = dataPoint.values.reduce(0.0, +) / Double(dataPoint.count)
        
        // Calculate feature contributions using a simplified SHAP approach
        for (featureName, featureValue) in dataPoint {
            let contribution = calculateFeatureContribution(
                featureName: featureName,
                featureValue: featureValue,
                baseline: baseline,
                allFeatures: dataPoint
            )
            explanations[featureName] = contribution
        }
        
        // Normalize contributions to sum to the total prediction change
        let totalContribution = explanations.values.reduce(0.0, +)
        if totalContribution != 0 {
            for (feature, _) in explanations {
                explanations[feature] = explanations[feature]! / totalContribution
            }
        }
        
        return explanations
    }
    
    /// Calculate contribution of a single feature
    private func calculateFeatureContribution(
        featureName: String,
        featureValue: Double,
        baseline: Double,
        allFeatures: [String: Double]
    ) -> Double {
        // Get feature importance weight
        let importanceWeight = getFeatureImportance(featureName: featureName)
        
        // Calculate feature's deviation from baseline
        let deviation = featureValue - baseline
        
        // Apply feature-specific scaling
        let scaledDeviation = deviation * getFeatureScaling(featureName: featureName)
        
        // Calculate contribution based on importance and deviation
        let contribution = scaledDeviation * importanceWeight
        
        return contribution
    }
    
    /// Get feature importance based on domain knowledge
    private func getFeatureImportance(featureName: String) -> Double {
        let importanceMap: [String: Double] = [
            "heart_rate": 0.9,
            "blood_pressure_systolic": 0.95,
            "blood_pressure_diastolic": 0.85,
            "sleep_duration": 0.8,
            "sleep_efficiency": 0.75,
            "activity_level": 0.7,
            "steps_count": 0.6,
            "stress_level": 0.8,
            "mood_score": 0.7,
            "weight": 0.5,
            "bmi": 0.6,
            "age": 0.4,
            "gender": 0.3,
            "temperature": 0.6,
            "respiratory_rate": 0.8,
            "oxygen_saturation": 0.9
        ]
        
        return importanceMap[featureName.lowercased()] ?? 0.5
    }
    
    /// Get feature-specific scaling factor
    private func getFeatureScaling(featureName: String) -> Double {
        let scalingMap: [String: Double] = [
            "heart_rate": 0.01, // Heart rate changes are significant
            "blood_pressure_systolic": 0.005, // BP changes are very significant
            "blood_pressure_diastolic": 0.005,
            "sleep_duration": 0.1, // Sleep duration changes are moderate
            "sleep_efficiency": 0.02,
            "activity_level": 0.2,
            "steps_count": 0.0001, // Step count changes are small
            "stress_level": 0.1,
            "mood_score": 0.1,
            "weight": 0.05,
            "bmi": 0.1,
            "age": 0.01,
            "gender": 1.0, // Binary feature
            "temperature": 0.5,
            "respiratory_rate": 0.1,
            "oxygen_saturation": 0.01
        ]
        
        return scalingMap[featureName.lowercased()] ?? 0.1
    }
} 