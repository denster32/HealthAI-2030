import CoreML
import Foundation
import os.log
import Models // Import the Models package

class SleepStageTransformer {
    private var coreMLModel: MLModel?
    private var isModelLoaded = false
    private let fallbackAccuracy: Double = 0.65
    
    init() {
        loadCoreMLModel()
    }
    
    private func loadCoreMLModel() {
        // Try to load the CoreML model from the bundle
        do {
            // Check if model file exists in the bundle
            if let modelURL = Bundle.module.url(forResource: "SleepStagePredictor", withExtension: "mlmodelc") {
                coreMLModel = try MLModel(contentsOf: modelURL)
                isModelLoaded = true
                print("SleepStageTransformer: Successfully loaded CoreML model")
            } else {
                // Try to compile the model if it exists as .mlmodel
                if let modelURL = Bundle.module.url(forResource: "SleepStagePredictor", withExtension: "mlmodel") {
                    let compiledURL = try MLModel.compileModel(at: modelURL)
                    coreMLModel = try MLModel(contentsOf: compiledURL)
                    isModelLoaded = true
                    print("SleepStageTransformer: Successfully compiled and loaded CoreML model")
                } else {
                    print("SleepStageTransformer: CoreML model not found, using enhanced rule-based prediction")
                    isModelLoaded = false
                }
            }
        } catch {
            print("SleepStageTransformer: Failed to load CoreML model: \(error.localizedDescription)")
            print("SleepStageTransformer: Using enhanced rule-based prediction as fallback")
            isModelLoaded = false
        }
    }
    
    func predictSleepStage(from features: SleepFeatures) -> SleepStage { // Changed SleepStageType to SleepStage
        if isModelLoaded, let model = coreMLModel {
            return predictWithCoreML(features: features, model: model)
        } else {
            return predictWithFallback(features: features)
        }
    }
    
    func predictSleepStage(features: [Double]) -> String {
        guard features.count >= 10 else {
            return "unknown"
        }
        
        // Map array elements to SleepFeatures properties based on DataModels.swift
        let sleepFeatures = SleepFeatures(
            heartRate: features[2], // heartRateAverage
            heartRateVariability: features[3], // heartRateVariability
            movement: features[6], // activityCount
            respiratoryRate: 0.0, // Not directly available in the array, assuming 0 or needs to be added
            oxygenSaturation: features[4], // spo2Average
            temperature: features[8], // wristTemperatureAverage
            timeOfDay: getTimeOfNight(), // Calculated separately
            previousStage: .unknown, // Needs to be determined or passed
            heartRateMin: 0.0, heartRateMax: 0.0, heartRateStdDev: 0.0, // Placeholder
            hrvMin: 0.0, hrvMax: 0.0, hrvStdDev: 0.0, // Placeholder
            bloodOxygenMin: 0.0, bloodOxygenMax: 0.0, bloodOxygenStdDev: 0.0, // Placeholder
            previousStageDuration: 0.0, // Placeholder
            heartRateChangeRate: 0.0, // Placeholder
            hrvChangeRate: 0.0, // Placeholder
            bloodOxygenChangeRate: 0.0 // Placeholder
        )
        
        let stageType = predictSleepStage(from: sleepFeatures)
        return stageType.rawValue
    }
    
    func predictSleepStageWithConfidence(from features: SleepFeatures) -> (stage: SleepStage, confidence: Double) { // Changed SleepStageType to SleepStage
        if isModelLoaded, let model = coreMLModel {
            do {
                let input = try createMLInput(from: features)
                let prediction = try model.prediction(from: input)
                let stage = extractSleepStage(from: prediction)
                let confidence = extractConfidence(from: prediction)
                return (stage, confidence)
            } catch {
                print("SleepStageTransformer: ML prediction failed: \(error.localizedDescription)")
                return (predictWithFallback(features: features), fallbackAccuracy)
            }
        } else {
            return (predictWithFallback(features: features), fallbackAccuracy)
        }
    }
    
    private func predictWithCoreML(features: SleepFeatures, model: MLModel) -> SleepStage { // Changed SleepStageType to SleepStage
        do {
            let input = try createMLInput(from: features)
            let prediction = try model.prediction(from: input)
            return extractSleepStage(from: prediction)
        } catch {
            print("SleepStageTransformer: ML prediction failed: \(error.localizedDescription), using fallback")
            return predictWithFallback(features: features)
        }
    }
    
    private func createMLInput(from features: SleepFeatures) throws -> MLFeatureProvider {
        // Normalize values to prevent extreme inputs
        let normalizedHeartRate = max(40.0, min(features.heartRate, 180.0)) // Changed to features.heartRate
        let normalizedHRV = max(0.0, min(features.heartRateVariability, 100.0)) // Changed to features.heartRateVariability
        let normalizedMovement = max(0.0, min(features.movement / 100.0, 1.0)) // Changed to features.movement
        let normalizedOxygen = max(80.0, min(features.oxygenSaturation, 100.0)) // Changed to features.oxygenSaturation
        let normalizedTemp = max(35.0, min(features.temperature, 40.0)) // Changed to features.temperature
        
        let inputDictionary: [String: MLFeatureValue] = [
            "heartRate": MLFeatureValue(double: normalizedHeartRate),
            "hrv": MLFeatureValue(double: normalizedHRV),
            "movement": MLFeatureValue(double: normalizedMovement),
            "bloodOxygen": MLFeatureValue(double: normalizedOxygen),
            "temperature": MLFeatureValue(double: normalizedTemp),
            "breathingRate": MLFeatureValue(double: features.respiratoryRate), // Added respiratoryRate
            "timeOfNight": MLFeatureValue(double: features.timeOfDay), // Changed to features.timeOfDay
            "previousStage": MLFeatureValue(double: Double(features.previousStage.rawValue)) // Changed to features.previousStage
        ]
        
        do {
            return try MLDictionaryFeatureProvider(dictionary: inputDictionary)
        } catch {
            print("Error creating ML input: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func extractSleepStage(from prediction: MLFeatureProvider) -> SleepStage { // Changed SleepStageType to SleepStage
        let awakeProb = prediction.featureValue(for: "awakeProbability")?.doubleValue ?? 0.0
        let lightProb = prediction.featureValue(for: "lightProbability")?.doubleValue ?? 0.0
        let deepProb = prediction.featureValue(for: "deepProbability")?.doubleValue ?? 0.0
        let remProb = prediction.featureValue(for: "remProbability")?.doubleValue ?? 0.0
        
        let probabilities = [awakeProb, lightProb, deepProb, remProb]
        let maxIndex = probabilities.enumerated().max(by: { $0.element < $1.element })?.offset ?? 1
        
        switch maxIndex {
        case 0: return .awake
        case 1: return .light
        case 2: return .deep
        case 3: return .rem
        default: return .light
        }
    }
    
    private func extractConfidence(from prediction: MLFeatureProvider) -> Double {
        let awakeProb = prediction.featureValue(for: "awakeProbability")?.doubleValue ?? 0.0
        let lightProb = prediction.featureValue(for: "lightProbability")?.doubleValue ?? 0.0
        let deepProb = prediction.featureValue(for: "deepProbability")?.doubleValue ?? 0.0
        let remProb = prediction.featureValue(for: "remProbability")?.doubleValue ?? 0.0
        
        return max(awakeProb, lightProb, deepProb, remProb)
    }
    
    private func predictWithFallback(features: SleepFeatures) -> SleepStage { // Changed SleepStageType to SleepStage
        // Calculate scores for each sleep stage based on physiological markers
        var scores: [SleepStage: Double] = [ // Changed SleepStageType to SleepStage
            .awake: 0.0,
            .light: 0.0, // Changed .lightSleep to .light
            .deep: 0.0, // Changed .deepSleep to .deep
            .rem: 0.0 // Changed .remSleep to .rem
        ]
        
        // Activity score - high activity suggests awake state
        let activityScore = min(1.0, features.movement / 100.0) // Changed features.activityCount to features.movement
        scores[.awake]! += activityScore * 2.0
        scores[.light]! += (1.0 - activityScore) * 0.5 // Changed .lightSleep to .light
        scores[.deep]! += (1.0 - activityScore) * 1.5 // Changed .deepSleep to .deep
        scores[.rem]! += (1.0 - activityScore) * 1.0 // Changed .remSleep to .rem
        
        // Heart rate score
        let normalizedHR = (features.heartRate - 40.0) / 40.0 // Changed features.heartRateAverage to features.heartRate
        scores[.awake]! += normalizedHR * 1.5
        scores[.light]! += (1.0 - abs(normalizedHR - 0.5)) * 1.0 // Changed .lightSleep to .light
        scores[.deep]! += (1.0 - normalizedHR) * 2.0 // Changed .deepSleep to .deep
        scores[.rem]! += (normalizedHR > 0.4 && normalizedHR < 0.7) ? 1.5 : 0.0 // Changed .remSleep to .rem
        
        // HRV score - high HRV often indicates REM sleep
        let normalizedHRV = min(1.0, features.heartRateVariability / 80.0) // Changed features.rmssd to features.heartRateVariability
        scores[.awake]! += normalizedHRV * 0.5
        scores[.light]! += normalizedHRV * 0.7 // Changed .lightSleep to .light
        scores[.deep]! += (1.0 - normalizedHRV) * 1.0 // Changed .deepSleep to .deep
        scores[.rem]! += normalizedHRV * 2.0 // Changed .remSleep to .rem
        
        // Temperature gradient - stable temperature often indicates deep sleep
        let tempStability = 1.0 - min(1.0, abs(features.temperature) * 10.0) // Changed features.wristTemperatureGradient to features.temperature (assuming gradient is derived from temp)
        scores[.deep]! += tempStability * 1.0 // Changed .deepSleep to .deep
        
        // Time of night factor - deep sleep more common in first half, REM in second half
        let timeOfNight = features.timeOfDay / 8.0 // Normalize to 0-1 over 8 hour night // Changed getTimeOfNight() to features.timeOfDay
        if timeOfNight < 0.3 {
            scores[.deep]! += 1.0 // Changed .deepSleep to .deep
        } else if timeOfNight > 0.6 {
            scores[.rem]! += 1.0 // Changed .remSleep to .rem
        }
        
        // Find the sleep stage with the highest score
        let sortedScores = scores.sorted { $0.value > $1.value }
        return sortedScores.first?.key ?? .unknown
    }
    
    private func getTimeOfNight() -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        if hour >= 22 || hour <= 6 {
            if hour >= 22 {
                return Double(hour - 22)
            } else {
                return Double(hour + 2)
            }
        }
        
        return 0.0
    }
    
    func getModelInfo() -> ModelInfo {
        if let model = coreMLModel {
            return ModelInfo(
                name: model.modelDescription.metadata[MLModelMetadataKey.creatorDefinedKey] as? String ?? "SleepStageTransformer",
                version: model.modelDescription.metadata[MLModelMetadataKey.versionStringKey] as? String ?? "1.0",
                description: model.modelDescription.metadata[MLModelMetadataKey.descriptionKey] as? String ?? "Sleep stage prediction model"
            )
        } else {
            return ModelInfo(
                name: "SleepStageTransformer (Fallback)",
                version: "1.0",
                description: "Rule-based fallback sleep stage prediction"
            )
        }
    }
}

// Removed duplicate ModelInfo struct definition
// struct ModelInfo {
//     let name: String
//     let version: String
//     let description: String
// }

class BasePredictionEngine {
    private let sleepStageTransformer = SleepStageTransformer()
    private var lastPredictionTime = Date()
    private let minPredictionInterval: TimeInterval = 30.0
    
    func predictSleepStage(from features: SleepFeatures) -> (stage: SleepStage, confidence: Double, quality: Double) { // Changed SleepStageType to SleepStage
        let now = Date()
        guard now.timeIntervalSince(lastPredictionTime) >= minPredictionInterval else {
            return (.unknown, 0.0, 0.0)
        }
        
        lastPredictionTime = now
        
        let prediction = sleepStageTransformer.predictSleepStageWithConfidence(from: features)
        let quality = calculateSleepQuality(from: features)
        
        return (prediction.stage, prediction.confidence, quality)
    }
    
    private func calculateSleepQuality(from features: SleepFeatures) -> Double {
        let heartRateScore = normalizeScore(features.heartRate, optimal: 60, range: 30) // Changed features.heartRateAverage to features.heartRate
        let movementScore = max(0, 1 - features.movement / 100.0) // Changed features.activityCount to features.movement
        let hrvScore = min(1, features.heartRateVariability / 50.0) // Changed features.rmssd to features.heartRateVariability
        let oxygenScore = max(0, (features.oxygenSaturation - 90) / 10) // Changed features.spo2Average to features.oxygenSaturation
        
        return (heartRateScore * 0.3 + movementScore * 0.3 + hrvScore * 0.2 + oxygenScore * 0.2)
    }
    
    private func normalizeScore(_ value: Double, optimal: Double, range: Double) -> Double {
        return max(0, 1 - abs(value - optimal) / range)
    }
}