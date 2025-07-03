import CoreML
import Foundation
import os.log

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
    
    func predictSleepStage(from features: SleepFeatures) -> SleepStageType {
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
        
        let sleepFeatures = SleepFeatures(
            rmssd: features[0],
            sdnn: features[1],
            heartRateAverage: features[2],
            heartRateVariability: features[3],
            spo2Average: features[4],
            spo2Variability: features[5],
            activityCount: features[6],
            sleepWakeDetection: features[7],
            wristTemperatureAverage: features[8],
            wristTemperatureGradient: features[9],
            timestamp: Date()
        )
        
        let stageType = predictSleepStage(from: sleepFeatures)
        return stageType.rawValue
    }
    
    func predictSleepStageWithConfidence(from features: SleepFeatures) -> (stage: SleepStageType, confidence: Double) {
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
    
    private func predictWithCoreML(features: SleepFeatures, model: MLModel) -> SleepStageType {
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
        let normalizedHeartRate = max(40.0, min(features.heartRateAverage, 180.0))
        let normalizedHRV = max(0.0, min(features.rmssd, 100.0))
        let normalizedMovement = max(0.0, min(features.activityCount / 100.0, 1.0))
        let normalizedOxygen = max(80.0, min(features.spo2Average, 100.0))
        let normalizedTemp = max(35.0, min(features.wristTemperatureAverage, 40.0))
        
        let inputDictionary: [String: MLFeatureValue] = [
            "heartRate": MLFeatureValue(double: normalizedHeartRate),
            "hrv": MLFeatureValue(double: normalizedHRV),
            "movement": MLFeatureValue(double: normalizedMovement),
            "bloodOxygen": MLFeatureValue(double: normalizedOxygen),
            "temperature": MLFeatureValue(double: normalizedTemp),
            "breathingRate": MLFeatureValue(double: 14.0),
            "timeOfNight": MLFeatureValue(double: getTimeOfNight()),
            "previousStage": MLFeatureValue(double: 1.0)
        ]
        
        do {
            return try MLDictionaryFeatureProvider(dictionary: inputDictionary)
        } catch {
            print("Error creating ML input: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func extractSleepStage(from prediction: MLFeatureProvider) -> SleepStageType {
        let awakeProb = prediction.featureValue(for: "awakeProbability")?.doubleValue ?? 0.0
        let lightProb = prediction.featureValue(for: "lightProbability")?.doubleValue ?? 0.0
        let deepProb = prediction.featureValue(for: "deepProbability")?.doubleValue ?? 0.0
        let remProb = prediction.featureValue(for: "remProbability")?.doubleValue ?? 0.0
        
        let probabilities = [awakeProb, lightProb, deepProb, remProb]
        let maxIndex = probabilities.enumerated().max(by: { $0.element < $1.element })?.offset ?? 1
        
        switch maxIndex {
        case 0: return .awake
        case 1: return .lightSleep
        case 2: return .deepSleep
        case 3: return .remSleep
        default: return .lightSleep
        }
    }
    
    private func extractConfidence(from prediction: MLFeatureProvider) -> Double {
        let awakeProb = prediction.featureValue(for: "awakeProbability")?.doubleValue ?? 0.0
        let lightProb = prediction.featureValue(for: "lightProbability")?.doubleValue ?? 0.0
        let deepProb = prediction.featureValue(for: "deepProbability")?.doubleValue ?? 0.0
        let remProb = prediction.featureValue(for: "remProbability")?.doubleValue ?? 0.0
        
        return max(awakeProb, lightProb, deepProb, remProb)
    }
    
    private func predictWithFallback(features: SleepFeatures) -> SleepStageType {
        // Calculate scores for each sleep stage based on physiological markers
        var scores: [SleepStageType: Double] = [
            .awake: 0.0,
            .lightSleep: 0.0,
            .deepSleep: 0.0,
            .remSleep: 0.0
        ]
        
        // Activity score - high activity suggests awake state
        let activityScore = min(1.0, features.activityCount / 100.0)
        scores[.awake]! += activityScore * 2.0
        scores[.lightSleep]! += (1.0 - activityScore) * 0.5
        scores[.deepSleep]! += (1.0 - activityScore) * 1.5
        scores[.remSleep]! += (1.0 - activityScore) * 1.0
        
        // Heart rate score
        let normalizedHR = (features.heartRateAverage - 40.0) / 40.0 // Normalize between 40-80 bpm
        scores[.awake]! += normalizedHR * 1.5
        scores[.lightSleep]! += (1.0 - abs(normalizedHR - 0.5)) * 1.0
        scores[.deepSleep]! += (1.0 - normalizedHR) * 2.0
        scores[.remSleep]! += (normalizedHR > 0.4 && normalizedHR < 0.7) ? 1.5 : 0.0
        
        // HRV score - high HRV often indicates REM sleep
        let normalizedHRV = min(1.0, features.rmssd / 80.0)
        scores[.awake]! += normalizedHRV * 0.5
        scores[.lightSleep]! += normalizedHRV * 0.7
        scores[.deepSleep]! += (1.0 - normalizedHRV) * 1.0
        scores[.remSleep]! += normalizedHRV * 2.0
        
        // Temperature gradient - stable temperature often indicates deep sleep
        let tempStability = 1.0 - min(1.0, abs(features.wristTemperatureGradient) * 10.0)
        scores[.deepSleep]! += tempStability * 1.0
        
        // Time of night factor - deep sleep more common in first half, REM in second half
        let timeOfNight = getTimeOfNight() / 8.0 // Normalize to 0-1 over 8 hour night
        if timeOfNight < 0.3 {
            scores[.deepSleep]! += 1.0
        } else if timeOfNight > 0.6 {
            scores[.remSleep]! += 1.0
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

struct ModelInfo {
    let name: String
    let version: String
    let description: String
}

class BasePredictionEngine {
    private let sleepStageTransformer = SleepStageTransformer()
    private var lastPredictionTime = Date()
    private let minPredictionInterval: TimeInterval = 30.0
    
    func predictSleepStage(from features: SleepFeatures) -> (stage: SleepStageType, confidence: Double, quality: Double) {
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
        let heartRateScore = normalizeScore(features.heartRateAverage, optimal: 60, range: 30)
        let movementScore = max(0, 1 - features.activityCount / 100.0)
        let hrvScore = min(1, features.rmssd / 50.0)
        let oxygenScore = max(0, (features.spo2Average - 90) / 10)
        
        return (heartRateScore * 0.3 + movementScore * 0.3 + hrvScore * 0.2 + oxygenScore * 0.2)
    }
    
    private func normalizeScore(_ value: Double, optimal: Double, range: Double) -> Double {
        return max(0, 1 - abs(value - optimal) / range)
    }
}