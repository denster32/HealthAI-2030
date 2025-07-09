import Foundation
import Combine
import CoreML

@MainActor
public class ExplainableAIManager: ObservableObject {
    public static let shared = ExplainableAIManager()
    @Published public var explanations: [AIExplanation] = []
    @Published public var featureImportance: [String: Double] = [:]
    
    private let healthDataManager: HealthDataManager
    private let mlModelManager: MLModelManager
    
    private init() {
        self.healthDataManager = HealthDataManager.shared
        self.mlModelManager = MLModelManager.shared
    }
    
    public func generateExplanation(for recommendation: String, context: [String: Any]) async {
        let explanation = await performExplainableAnalysis(
            recommendation: recommendation,
            context: context
        )
        explanations.append(explanation)
    }
    
    private func performExplainableAnalysis(recommendation: String, context: [String: Any]) async -> AIExplanation {
        // Analyze feature importance
        let importance = await calculateFeatureImportance(context: context)
        featureImportance = importance
        
        // Generate reasoning based on feature importance
        let reason = generateReasoning(importance: importance, recommendation: recommendation)
        
        // Calculate confidence based on data quality and model performance
        let confidence = await calculateConfidence(context: context)
        
        // Generate decision path
        let decisionPath = generateDecisionPath(context: context, importance: importance)
        
        return AIExplanation(
            id: UUID(),
            recommendation: recommendation,
            reason: reason,
            confidence: confidence,
            featureImportance: importance,
            decisionPath: decisionPath,
            dataQuality: await assessDataQuality(context: context)
        )
    }
    
    private func calculateFeatureImportance(context: [String: Any]) async -> [String: Double] {
        var importance: [String: Double] = [:]
        
        // Analyze health metrics importance
        if let heartRate = context["heartRate"] as? Double {
            importance["heartRate"] = heartRate > 100 ? 0.9 : heartRate > 80 ? 0.7 : 0.5
        }
        
        if let sleepQuality = context["sleepQuality"] as? Double {
            importance["sleepQuality"] = sleepQuality < 0.6 ? 0.9 : sleepQuality < 0.8 ? 0.7 : 0.5
        }
        
        if let stressLevel = context["stressLevel"] as? Double {
            importance["stressLevel"] = stressLevel > 0.7 ? 0.8 : stressLevel > 0.5 ? 0.6 : 0.4
        }
        
        if let activityLevel = context["activityLevel"] as? Double {
            importance["activityLevel"] = activityLevel < 0.3 ? 0.8 : activityLevel < 0.6 ? 0.6 : 0.4
        }
        
        if let nutritionScore = context["nutritionScore"] as? Double {
            importance["nutritionScore"] = nutritionScore < 0.6 ? 0.7 : nutritionScore < 0.8 ? 0.5 : 0.3
        }
        
        // Normalize importance scores
        let maxImportance = importance.values.max() ?? 1.0
        for key in importance.keys {
            importance[key] = importance[key]! / maxImportance
        }
        
        return importance
    }
    
    private func generateReasoning(importance: [String: Double], recommendation: String) -> String {
        let topFeatures = importance.sorted { $0.value > $1.value }.prefix(3)
        var reasons: [String] = []
        
        for (feature, score) in topFeatures {
            if score > 0.7 {
                reasons.append("Your \(feature) is significantly affecting your health")
            } else if score > 0.5 {
                reasons.append("Your \(feature) shows room for improvement")
            }
        }
        
        if reasons.isEmpty {
            return "Based on your overall health patterns and trends."
        } else {
            return reasons.joined(separator: ". ") + "."
        }
    }
    
    private func calculateConfidence(context: [String: Any]) async -> Double {
        var confidence = 0.8 // Base confidence
        
        // Adjust based on data completeness
        let dataPoints = context.count
        if dataPoints < 3 {
            confidence -= 0.2
        } else if dataPoints > 8 {
            confidence += 0.1
        }
        
        // Adjust based on data recency
        if let lastUpdate = context["lastUpdate"] as? Date {
            let daysSinceUpdate = Date().timeIntervalSince(lastUpdate) / (24 * 60 * 60)
            if daysSinceUpdate > 7 {
                confidence -= 0.3
            } else if daysSinceUpdate < 1 {
                confidence += 0.1
            }
        }
        
        // Adjust based on model performance
        if let modelAccuracy = context["modelAccuracy"] as? Double {
            confidence = confidence * modelAccuracy
        }
        
        return max(0.1, min(1.0, confidence))
    }
    
    private func generateDecisionPath(context: [String: Any], importance: [String: Double]) -> [DecisionStep] {
        var path: [DecisionStep] = []
        
        // Generate decision tree path
        for (feature, score) in importance.sorted(by: { $0.value > $1.value }) {
            if let value = context[feature] as? Double {
                let threshold = getThreshold(for: feature)
                let decision = value > threshold ? "high" : "low"
                
                path.append(DecisionStep(
                    feature: feature,
                    value: value,
                    threshold: threshold,
                    decision: decision,
                    importance: score
                ))
            }
        }
        
        return path
    }
    
    private func getThreshold(for feature: String) -> Double {
        switch feature {
        case "heartRate": return 80.0
        case "sleepQuality": return 0.7
        case "stressLevel": return 0.6
        case "activityLevel": return 0.5
        case "nutritionScore": return 0.7
        default: return 0.5
        }
    }
    
    private func assessDataQuality(context: [String: Any]) async -> DataQuality {
        var quality = DataQuality()
        
        // Check data completeness
        let requiredFields = ["heartRate", "sleepQuality", "stressLevel", "activityLevel"]
        let presentFields = requiredFields.filter { context[$0] != nil }
        quality.completeness = Double(presentFields.count) / Double(requiredFields.count)
        
        // Check data recency
        if let lastUpdate = context["lastUpdate"] as? Date {
            let daysSinceUpdate = Date().timeIntervalSince(lastUpdate) / (24 * 60 * 60)
            quality.recency = daysSinceUpdate < 1 ? 1.0 : daysSinceUpdate < 7 ? 0.7 : 0.3
        }
        
        // Check data consistency
        quality.consistency = await checkDataConsistency(context: context)
        
        return quality
    }
    
    private func checkDataConsistency(context: [String: Any]) async -> Double {
        // Simple consistency check - in a real implementation, this would be more sophisticated
        var consistency = 1.0
        
        if let heartRate = context["heartRate"] as? Double, heartRate > 200 {
            consistency -= 0.3 // Unrealistic heart rate
        }
        
        if let sleepQuality = context["sleepQuality"] as? Double, sleepQuality > 1.0 {
            consistency -= 0.3 // Invalid sleep quality score
        }
        
        return max(0.0, consistency)
    }
}

public struct AIExplanation: Identifiable, Codable {
    public let id: UUID
    public let recommendation: String
    public let reason: String
    public let confidence: Double
    public let featureImportance: [String: Double]
    public let decisionPath: [DecisionStep]
    public let dataQuality: DataQuality
}

public struct DecisionStep: Codable {
    public let feature: String
    public let value: Double
    public let threshold: Double
    public let decision: String
    public let importance: Double
}

public struct DataQuality: Codable {
    public var completeness: Double = 0.0
    public var recency: Double = 0.0
    public var consistency: Double = 0.0
    
    public var overall: Double {
        return (completeness + recency + consistency) / 3.0
    }
}
