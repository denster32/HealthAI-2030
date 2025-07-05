import Foundation
import MLX
import SwiftData

/// Cardiovascular risk prediction model using MLX
public class CardiovascularRiskPredictor: ObservableObject {
    public static let shared = CardiovascularRiskPredictor()
    
    @Published public var isModelLoaded = false
    @Published public var predictionInProgress = false
    
    private var model: MLXModel?
    private let modelURL = Bundle.main.url(forResource: "cardiovascular_risk_model", withExtension: "mlx")
    private let analytics = DeepHealthAnalytics.shared
    
    private init() {
        loadModel()
    }
    
    /// Load the MLX model
    private func loadModel() {
        guard let modelURL = modelURL else {
            print("Cardiovascular risk model not found")
            return
        }
        
        Task {
            do {
                model = try MLXModel.load(from: modelURL)
                await MainActor.run {
                    isModelLoaded = true
                }
                analytics.logEvent("cv_risk_model_loaded", parameters: ["success": true])
            } catch {
                print("Failed to load cardiovascular risk model: \(error)")
                analytics.logEvent("cv_risk_model_load_failed", parameters: ["error": error.localizedDescription])
            }
        }
    }
    
    /// Predict cardiovascular risk based on health data
    public func predictRisk(healthData: [HealthData], userProfile: UserProfile?) async -> CardiovascularRiskPrediction {
        guard isModelLoaded, let model = model else {
            return CardiovascularRiskPrediction(
                riskScore: 0,
                riskLevel: .unknown,
                confidence: 0,
                factors: [],
                recommendations: [],
                error: "Model not loaded"
            )
        }
        
        await MainActor.run {
            predictionInProgress = true
        }
        
        defer {
            Task { @MainActor in
                predictionInProgress = false
            }
        }
        
        do {
            // Prepare input features
            let features = prepareFeatures(healthData: healthData, userProfile: userProfile)
            
            // Run prediction
            let prediction = try await runPrediction(model: model, features: features)
            
            // Analyze results
            let riskAnalysis = analyzeRiskFactors(features: features, prediction: prediction)
            
            let result = CardiovascularRiskPrediction(
                riskScore: prediction.riskScore,
                riskLevel: prediction.riskLevel,
                confidence: prediction.confidence,
                factors: riskAnalysis.factors,
                recommendations: riskAnalysis.recommendations,
                error: nil
            )
            
            analytics.logEvent("cv_risk_prediction_completed", parameters: [
                "risk_score": prediction.riskScore,
                "risk_level": prediction.riskLevel.rawValue,
                "confidence": prediction.confidence
            ])
            
            return result
            
        } catch {
            analytics.logEvent("cv_risk_prediction_failed", parameters: [
                "error": error.localizedDescription
            ])
            
            return CardiovascularRiskPrediction(
                riskScore: 0,
                riskLevel: .unknown,
                confidence: 0,
                factors: [],
                recommendations: [],
                error: error.localizedDescription
            )
        }
    }
    
    /// Prepare input features for the model
    private func prepareFeatures(healthData: [HealthData], userProfile: UserProfile?) -> [String: MLXArray] {
        let recentData = healthData.suffix(30) // Last 30 days
        
        // Calculate average metrics
        let avgHeartRate = recentData.compactMap { $0.heartRate }.reduce(0, +) / max(recentData.count, 1)
        let avgHRV = recentData.compactMap { $0.hrv }.reduce(0, +) / max(recentData.count, 1)
        let avgSystolicBP = recentData.compactMap { $0.systolicBloodPressure }.reduce(0, +) / max(recentData.count, 1)
        let avgDiastolicBP = recentData.compactMap { $0.diastolicBloodPressure }.reduce(0, +) / max(recentData.count, 1)
        let avgActivityLevel = recentData.compactMap { $0.activityLevel }.reduce(0, +) / max(recentData.count, 1)
        let avgSleepDuration = recentData.compactMap { $0.sleepDuration }.reduce(0, +) / max(recentData.count, 1)
        let avgStressLevel = recentData.compactMap { $0.stressLevel }.reduce(0, +) / max(recentData.count, 1)
        
        // Calculate variability metrics
        let heartRateVariability = calculateVariability(recentData.compactMap { $0.heartRate })
        let bloodPressureVariability = calculateVariability(recentData.compactMap { $0.systolicBloodPressure })
        
        // User profile features
        let age = userProfile?.age ?? 30
        let gender = userProfile?.gender == "male" ? 1.0 : 0.0
        let bmi = userProfile?.bmi ?? 25.0
        let hasDiabetes = userProfile?.hasDiabetes ?? false ? 1.0 : 0.0
        let hasHypertension = userProfile?.hasHypertension ?? false ? 1.0 : 0.0
        let smokingStatus = userProfile?.smokingStatus == "current" ? 1.0 : 0.0
        
        // Create feature array
        let features: [Float] = [
            Float(age),
            Float(gender),
            Float(bmi),
            Float(avgHeartRate),
            Float(avgHRV),
            Float(avgSystolicBP),
            Float(avgDiastolicBP),
            Float(avgActivityLevel),
            Float(avgSleepDuration),
            Float(avgStressLevel),
            Float(heartRateVariability),
            Float(bloodPressureVariability),
            Float(hasDiabetes),
            Float(hasHypertension),
            Float(smokingStatus)
        ]
        
        return [
            "features": MLXArray(features).reshaped([1, features.count])
        ]
    }
    
    /// Run prediction using MLX model
    private func runPrediction(model: MLXModel, features: [String: MLXArray]) async throws -> (riskScore: Double, riskLevel: RiskLevel, confidence: Double) {
        let outputs = try model.predict(features)
        
        guard let riskScoreArray = outputs["risk_score"] as? MLXArray,
              let confidenceArray = outputs["confidence"] as? MLXArray else {
            throw PredictionError.invalidOutput
        }
        
        let riskScore = Double(riskScoreArray.item() as! Float)
        let confidence = Double(confidenceArray.item() as! Float)
        
        let riskLevel = determineRiskLevel(score: riskScore)
        
        return (riskScore, riskLevel, confidence)
    }
    
    /// Determine risk level based on score
    private func determineRiskLevel(score: Double) -> RiskLevel {
        switch score {
        case 0..<0.2:
            return .low
        case 0.2..<0.4:
            return .moderate
        case 0.4..<0.6:
            return .high
        default:
            return .veryHigh
        }
    }
    
    /// Calculate variability of a metric
    private func calculateVariability(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    /// Analyze risk factors and generate recommendations
    private func analyzeRiskFactors(features: [String: MLXArray], prediction: (riskScore: Double, riskLevel: RiskLevel, confidence: Double)) -> (factors: [RiskFactor], recommendations: [String]) {
        var factors: [RiskFactor] = []
        var recommendations: [String] = []
        
        let featureArray = features["features"] as! MLXArray
        let values = Array(featureArray.flattened()) as! [Float]
        
        // Analyze individual risk factors
        if values.count >= 15 {
            let age = Double(values[0])
            let bmi = Double(values[2])
            let heartRate = Double(values[3])
            let hrv = Double(values[4])
            let systolicBP = Double(values[5])
            let diastolicBP = Double(values[6])
            let activityLevel = Double(values[7])
            let sleepDuration = Double(values[8])
            let stressLevel = Double(values[9])
            let hasDiabetes = values[12] > 0.5
            let hasHypertension = values[13] > 0.5
            let smokingStatus = values[14] > 0.5
            
            // Age factor
            if age > 65 {
                factors.append(RiskFactor(
                    name: "Age",
                    value: "\(Int(age)) years",
                    impact: .moderate,
                    description: "Age is a significant risk factor for cardiovascular disease"
                ))
            }
            
            // BMI factor
            if bmi > 30 {
                factors.append(RiskFactor(
                    name: "BMI",
                    value: String(format: "%.1f", bmi),
                    impact: .high,
                    description: "High BMI increases cardiovascular risk"
                ))
                recommendations.append("Work with a healthcare provider to develop a weight management plan")
            }
            
            // Blood pressure factors
            if systolicBP > 140 || diastolicBP > 90 {
                factors.append(RiskFactor(
                    name: "Blood Pressure",
                    value: "\(Int(systolicBP))/\(Int(diastolicBP)) mmHg",
                    impact: .high,
                    description: "Elevated blood pressure is a major cardiovascular risk factor"
                ))
                recommendations.append("Monitor blood pressure regularly and follow medical advice")
            }
            
            // Heart rate variability
            if hrv < 30 {
                factors.append(RiskFactor(
                    name: "Heart Rate Variability",
                    value: String(format: "%.1f ms", hrv),
                    impact: .moderate,
                    description: "Low HRV indicates poor autonomic nervous system function"
                ))
                recommendations.append("Practice stress management techniques and regular exercise")
            }
            
            // Activity level
            if activityLevel < 0.3 {
                factors.append(RiskFactor(
                    name: "Physical Activity",
                    value: "Low",
                    impact: .moderate,
                    description: "Low physical activity increases cardiovascular risk"
                ))
                recommendations.append("Aim for at least 150 minutes of moderate exercise per week")
            }
            
            // Sleep duration
            if sleepDuration < 7 {
                factors.append(RiskFactor(
                    name: "Sleep Duration",
                    value: String(format: "%.1f hours", sleepDuration),
                    impact: .moderate,
                    description: "Insufficient sleep is associated with increased cardiovascular risk"
                ))
                recommendations.append("Prioritize 7-9 hours of quality sleep per night")
            }
            
            // Stress level
            if stressLevel > 0.7 {
                factors.append(RiskFactor(
                    name: "Stress Level",
                    value: "High",
                    impact: .moderate,
                    description: "High stress levels can negatively impact cardiovascular health"
                ))
                recommendations.append("Practice stress management techniques like meditation or deep breathing")
            }
            
            // Medical conditions
            if hasDiabetes {
                factors.append(RiskFactor(
                    name: "Diabetes",
                    value: "Present",
                    impact: .high,
                    description: "Diabetes significantly increases cardiovascular risk"
                ))
                recommendations.append("Work closely with your healthcare team to manage diabetes")
            }
            
            if hasHypertension {
                factors.append(RiskFactor(
                    name: "Hypertension",
                    value: "Present",
                    impact: .high,
                    description: "Hypertension is a major cardiovascular risk factor"
                ))
                recommendations.append("Follow prescribed treatment plan and monitor blood pressure")
            }
            
            if smokingStatus {
                factors.append(RiskFactor(
                    name: "Smoking",
                    value: "Current",
                    impact: .veryHigh,
                    description: "Smoking is one of the most significant cardiovascular risk factors"
                ))
                recommendations.append("Consider smoking cessation programs and support")
            }
        }
        
        // Add general recommendations based on risk level
        switch prediction.riskLevel {
        case .low:
            recommendations.append("Continue maintaining healthy lifestyle habits")
        case .moderate:
            recommendations.append("Consider regular cardiovascular health checkups")
        case .high:
            recommendations.append("Schedule a consultation with a cardiologist")
        case .veryHigh:
            recommendations.append("Seek immediate medical evaluation for cardiovascular health")
        case .unknown:
            recommendations.append("Insufficient data for accurate risk assessment")
        }
        
        return (factors, recommendations)
    }
}

// MARK: - Data Models

public struct CardiovascularRiskPrediction {
    public let riskScore: Double
    public let riskLevel: RiskLevel
    public let confidence: Double
    public let factors: [RiskFactor]
    public let recommendations: [String]
    public let error: String?
    
    public init(riskScore: Double, riskLevel: RiskLevel, confidence: Double, factors: [RiskFactor], recommendations: [String], error: String?) {
        self.riskScore = riskScore
        self.riskLevel = riskLevel
        self.confidence = confidence
        self.factors = factors
        self.recommendations = recommendations
        self.error = error
    }
}

public enum RiskLevel: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    case unknown = "Unknown"
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "yellow"
        case .high: return "orange"
        case .veryHigh: return "red"
        case .unknown: return "gray"
        }
    }
}

public struct RiskFactor {
    public let name: String
    public let value: String
    public let impact: RiskImpact
    public let description: String
    
    public init(name: String, value: String, impact: RiskImpact, description: String) {
        self.name = name
        self.value = value
        self.impact = impact
        self.description = description
    }
}

public enum RiskImpact: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
}

public enum PredictionError: Error {
    case modelNotLoaded
    case invalidInput
    case invalidOutput
    case predictionFailed
} 