import Foundation

/// Manager responsible for generating feature importance explanations for model predictions.
public class ExplanationViewManager {
    public init() {}

    /// Computes feature importance scores for given input features and prediction output.
    /// - Parameters:
    ///   - features: Dictionary of feature names to values.
    ///   - prediction: Model prediction output.
    /// - Returns: Dictionary mapping feature names to importance scores.
    public func computeFeatureImportances(features: [String: Double], prediction: Double) -> [String: Double] {
        // Implementation for feature importance computation
        var importances: [String: Double] = [:]
        
        // Calculate feature importance using multiple methods
        let correlationImportances = calculateCorrelationImportances(features: features, prediction: prediction)
        let varianceImportances = calculateVarianceImportances(features: features)
        let domainImportances = calculateDomainImportances(features: features)
        
        // Combine different importance measures
        for (featureName, _) in features {
            let correlationScore = correlationImportances[featureName] ?? 0.0
            let varianceScore = varianceImportances[featureName] ?? 0.0
            let domainScore = domainImportances[featureName] ?? 0.0
            
            // Weighted combination of different importance measures
            let combinedImportance = (correlationScore * 0.4) + (varianceScore * 0.3) + (domainScore * 0.3)
            importances[featureName] = combinedImportance
        }
        
        // Normalize importance scores to sum to 1.0
        let totalImportance = importances.values.reduce(0.0, +)
        if totalImportance > 0 {
            for (feature, _) in importances {
                importances[feature] = importances[feature]! / totalImportance
            }
        }
        
        return importances
    }
    
    /// Calculate importance based on correlation with prediction
    private func calculateCorrelationImportances(features: [String: Double], prediction: Double) -> [String: Double] {
        var importances: [String: Double] = [:]
        
        for (featureName, featureValue) in features {
            // Calculate correlation-like score based on feature value and prediction
            let normalizedValue = normalizeFeatureValue(featureName: featureName, value: featureValue)
            let correlationScore = abs(normalizedValue - prediction)
            importances[featureName] = correlationScore
        }
        
        return importances
    }
    
    /// Calculate importance based on feature variance
    private func calculateVarianceImportances(features: [String: Double]) -> [String: Double] {
        var importances: [String: Double] = [:]
        
        for (featureName, featureValue) in features {
            // Calculate variance-based importance
            let normalizedValue = normalizeFeatureValue(featureName: featureName, value: featureValue)
            let varianceScore = abs(normalizedValue - 0.5) * 2 // Scale to [0, 1]
            importances[featureName] = varianceScore
        }
        
        return importances
    }
    
    /// Calculate importance based on domain knowledge
    private func calculateDomainImportances(features: [String: Double]) -> [String: Double] {
        let domainImportanceMap: [String: Double] = [
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
            "oxygen_saturation": 0.9,
            "glucose_level": 0.9,
            "cholesterol_total": 0.7,
            "cholesterol_hdl": 0.7,
            "cholesterol_ldl": 0.7,
            "triglycerides": 0.6
        ]
        
        var importances: [String: Double] = [:]
        for (featureName, _) in features {
            importances[featureName] = domainImportanceMap[featureName.lowercased()] ?? 0.5
        }
        
        return importances
    }
    
    /// Normalize feature value based on feature type
    private func normalizeFeatureValue(featureName: String, value: Double) -> Double {
        let normalizationRanges: [String: (min: Double, max: Double)] = [
            "heart_rate": (40.0, 200.0),
            "blood_pressure_systolic": (70.0, 200.0),
            "blood_pressure_diastolic": (40.0, 120.0),
            "sleep_duration": (0.0, 12.0),
            "sleep_efficiency": (0.0, 1.0),
            "activity_level": (0.0, 10.0),
            "steps_count": (0.0, 50000.0),
            "stress_level": (0.0, 10.0),
            "mood_score": (0.0, 10.0),
            "weight": (30.0, 300.0),
            "bmi": (15.0, 50.0),
            "age": (0.0, 120.0),
            "temperature": (35.0, 42.0),
            "respiratory_rate": (8.0, 30.0),
            "oxygen_saturation": (70.0, 100.0),
            "glucose_level": (50.0, 400.0),
            "cholesterol_total": (100.0, 400.0),
            "cholesterol_hdl": (20.0, 100.0),
            "cholesterol_ldl": (50.0, 200.0),
            "triglycerides": (50.0, 500.0)
        ]
        
        if let range = normalizationRanges[featureName.lowercased()] {
            let normalized = (value - range.min) / (range.max - range.min)
            return max(0.0, min(1.0, normalized))
        }
        
        // Default normalization for unknown features
        return max(0.0, min(1.0, value / 100.0))
    }
} 