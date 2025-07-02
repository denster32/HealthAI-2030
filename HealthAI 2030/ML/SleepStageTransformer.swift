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
        // For MVP, we'll use fallback prediction until actual CoreML models are trained
        print("SleepStageTransformer: Using enhanced rule-based prediction (CoreML model will be added in future versions)")
        isModelLoaded = false
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
        let inputDictionary: [String: MLFeatureValue] = [
            "heartRate": MLFeatureValue(double: features.heartRateAverage),
            "hrv": MLFeatureValue(double: features.rmssd),
            "movement": MLFeatureValue(double: features.activityCount / 100.0),
            "bloodOxygen": MLFeatureValue(double: features.spo2Average),
            "temperature": MLFeatureValue(double: features.wristTemperatureAverage),
            "breathingRate": MLFeatureValue(double: 14.0),
            "timeOfNight": MLFeatureValue(double: getTimeOfNight()),
            "previousStage": MLFeatureValue(double: 1.0)
        ]
        
        return try MLDictionaryFeatureProvider(dictionary: inputDictionary)
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
        if features.activityCount > 50.0 {
            return .awake
        } else if features.heartRateAverage < 55.0 && features.activityCount < 10.0 && features.wristTemperatureGradient < 0.1 {
            return .deepSleep
        } else if features.heartRateAverage > 65.0 && features.activityCount > 10.0 && features.activityCount < 50.0 {
            return .lightSleep
        } else if features.rmssd > 40.0 && features.heartRateAverage > 55.0 && features.heartRateAverage < 65.0 {
            return .remSleep
        } else {
            return .unknown
        }
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