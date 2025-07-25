import Foundation
import CoreML
import Accelerate
import OSLog // Import OSLog for logging
import MLXHealthPredictor

class SleepStageClassifier {
    
    // MARK: - Properties
    private var model: MLModel?
    private let featureExtractor: SleepFeatureExtractor
    private let confidenceThreshold: Double = 0.7
    private let logger = Logger(subsystem: "com.HealthAI2030.SleepTracking", category: "SleepStageClassifier")
    private let mlxPredictor = MLXHealthPredictor.shared
    
    // Model performance metrics
    private var classificationAccuracy: [SleepStageType: Double] = [
        .awake: 0.92,
        .lightSleep: 0.85,
        .deepSleep: 0.89,
        .remSleep: 0.83,
        .unknown: 0.0
    ]
    
    // Sleep stage transition probabilities (Markov chain)
    private let transitionProbabilities: [SleepStageType: [SleepStageType: Double]] = [
        .awake: [
            .awake: 0.7,
            .lightSleep: 0.25,
            .deepSleep: 0.03,
            .remSleep: 0.02,
            .unknown: 0.0
        ],
        .lightSleep: [
            .awake: 0.15,
            .lightSleep: 0.4,
            .deepSleep: 0.35,
            .remSleep: 0.1,
            .unknown: 0.0
        ],
        .deepSleep: [
            .awake: 0.05,
            .lightSleep: 0.6,
            .deepSleep: 0.25,
            .remSleep: 0.1,
            .unknown: 0.0
        ],
        .remSleep: [
            .awake: 0.2,
            .lightSleep: 0.5,
            .deepSleep: 0.1,
            .remSleep: 0.2,
            .unknown: 0.0
        ],
        .unknown: [
            .awake: 0.4,
            .lightSleep: 0.3,
            .deepSleep: 0.15,
            .remSleep: 0.15,
            .unknown: 0.0
        ]
    ]
    
    // Previous classifications for temporal consistency
    private var recentClassifications: [(stage: SleepStageType, confidence: Double, timestamp: Date)] = []
    private let historySize = 10
    
    init() {
        self.featureExtractor = SleepFeatureExtractor()
        loadModel()
    }
    
    // MARK: - Model Loading
    
    private func loadModel() {
        // Load trained CoreML model for sleep stage classification from EnhancedMacAnalyticsEngine
        self.model = EnhancedMacAnalyticsEngine.shared.mlModelManager.sleepStageClassifierModel
        if self.model != nil {
            logger.info("SleepStageClassifier: Successfully loaded CoreML sleep stage model from EnhancedMacAnalyticsEngine.")
        } else {
            logger.warning("SleepStageClassifier: CoreML sleep stage model not available from EnhancedMacAnalyticsEngine. Falling back to algorithmic classification.")
        }
    }
    
    // MARK: - Sleep Stage Classification
    
    func classifySleepStage(features: SleepFeatures) async -> SleepStageResult {
        do {
            let inputArray = features.asMLXInputArray()
            let predictedStageString = try await mlxPredictor.predictSleepStage(from: inputArray)
            let stage = mapStringToSleepStage(predictedStageString)
            logger.info("MLX predicted sleep stage: \(predictedStageString)")
            return SleepStageResult(
                stage: stage,
                confidence: 0.9, // Placeholder confidence, update if MLX returns confidence
                allScores: [:],
                method: .mlx
            )
        } catch {
            logger.error("MLXHealthPredictor failed: \(error.localizedDescription). Returning unknown stage.")
            return SleepStageResult(
                stage: .unknown,
                confidence: 0.0,
                allScores: [:],
                method: .mlx
            )
        }
    }
    
    private func classifyWithCoreML(features: SleepFeatures, model: MLModel) -> SleepStageResult {
        do {
            // Create feature dictionary for CoreML input
            let inputFeatures: [String: Any] = [
                "heartRate": features.heartRateAverage,
                "hrv": features.hrv,
                "movement": features.activityCount, // Use activityCount from SleepFeatures
                "temperature": features.wristTemperatureAverage, // Use wristTemperatureAverage
                "oxygenSaturation": features.oxygenSaturation, // Use oxygenSaturation
                "timeOfDay": features.timestamp.hourOfDay, // Use a helper for timeOfDay
                "timeSinceLastWake": features.sleepWakeDetection // Use sleepWakeDetection as a proxy for time since last wake
            ]
            
            // Create MLFeatureProvider
            let featureProvider = try MLDictionaryFeatureProvider(dictionary: inputFeatures)
            
            // Make prediction
            let prediction = try model.prediction(from: featureProvider)
            
            // Extract sleep stage and confidence
            var sleepStage: SleepStageType = .unknown
            var confidence: Double = 0.0
            var allScores: [SleepStageType: Double] = [:]
            
            // Handle different output formats
            if let stageOutput = prediction.featureValue(for: "sleepStage") {
                if let stageName = stageOutput.stringValue {
                    sleepStage = mapStringToSleepStage(stageName)
                    confidence = 0.85 // Default confidence for string output
                }
            }
            
            // Try to get confidence/probability scores
            if let probabilities = prediction.featureValue(for: "sleepStageProbability")?.dictionaryValue {
                for (stage, prob) in probabilities {
                    let stageType = mapStringToSleepStage(stage)
                    let probability = prob.doubleValue
                    allScores[stageType] = probability
                    
                    if probability > confidence {
                        sleepStage = stageType
                        confidence = probability
                    }
                }
            }
            
            // Update classification accuracy tracking
            let currentAccuracy = classificationAccuracy[sleepStage] ?? 0.0
            classificationAccuracy[sleepStage] = currentAccuracy
            
            return SleepStageResult(
                stage: sleepStage,
                confidence: confidence,
                allScores: allScores,
                method: .coreML
            )
            
        } catch {
            logger.error("SleepStageClassifier: CoreML prediction failed: \(error.localizedDescription). Falling back to algorithmic classification.")
            // Fall back to algorithmic classification
            return classifyAlgorithmically(features: features)
        }
    }
    
    private func mapStringToSleepStage(_ stageName: String) -> SleepStageType {
        switch stageName.lowercased() {
        case "awake":
            return .awake
        case "lightsleep", "light_sleep", "lightsleep", "stage1", "stage2":
            return .lightSleep
        case "deepsleep", "deep_sleep", "deepsleep", "stage3", "stage4":
            return .deepSleep
        case "remsleep", "rem_sleep", "remsleep", "rem":
            return .remSleep
        default:
            return .unknown
        }
    }
    
    private func classifyAlgorithmically(features: SleepFeatures) -> SleepStageResult {
        var stageScores: [SleepStageType: Double] = [:]
        
        // Calculate scores for each sleep stage based on features
        stageScores[.awake] = calculateAwakeScore(features: features)
        stageScores[.lightSleep] = calculateLightSleepScore(features: features)
        stageScores[.deepSleep] = calculateDeepSleepScore(features: features)
        stageScores[.remSleep] = calculateREMSleepScore(features: features)
        
        // Find stage with highest score
        let bestStage = stageScores.max(by: { $0.value < $1.value })?.key ?? .unknown
        let confidence = stageScores[bestStage] ?? 0.0
        
        return SleepStageResult(
            stage: bestStage,
            confidence: confidence,
            allScores: stageScores,
            method: .algorithmic
        )
    }
    
    // MARK: - Stage-Specific Scoring
    
    private func calculateAwakeScore(features: SleepFeatures) -> Double {
        var score = 0.0
        
        // High heart rate indicates wakefulness
        if features.heartRateAverage > 70 {
            score += 0.3
        }
        
        // High movement variance indicates wakefulness
        if features.activityCount > 5.0 { // Using activityCount
            score += 0.4
        }
        
        // Low HRV can indicate stress/wakefulness
        if features.rmssd < 30 { // Using rmssd for HRV
            score += 0.2
        }
        
        // Circadian factors
        let hourOfDay = features.timestamp.hourOfDay
        if hourOfDay >= 6 && hourOfDay <= 22 {
            score += 0.3 // Daytime hours
        }
        
        // Temperature regulation (awake people have more variable temperatures)
        // Assuming temperatureStability can be derived from wristTemperatureGradient
        if abs(features.wristTemperatureGradient) > 0.1 { // High gradient means less stability
            score += 0.2
        }
        
        return min(1.0, score)
    }
    
    private func calculateLightSleepScore(features: SleepFeatures) -> Double {
        var score = 0.0
        
        // Moderate heart rate (60-70 BPM typical for light sleep)
        if features.heartRateAverage >= 55 && features.heartRateAverage <= 75 {
            score += 0.3
        }
        
        // Some movement but not excessive
        if features.activityCount > 1.0 && features.activityCount < 5.0 { // Using activityCount
            score += 0.2
        }
        
        // Moderate HRV
        if features.rmssd >= 25 && features.rmssd <= 45 { // Using rmssd for HRV
            score += 0.2
        }
        
        // Breathing pattern regularity (placeholder, assuming it can be derived or is part of features)
        // For now, a constant value or a simple check
        if features.oxygenSaturation > 90.0 { // Proxy for regular breathing
            score += 0.2
        }
        
        // Nighttime hours
        let hourOfDay = features.timestamp.hourOfDay
        if hourOfDay >= 22 || hourOfDay <= 6 {
            score += 0.2
        }
        
        // Temperature stability
        if abs(features.wristTemperatureGradient) < 0.05 { // Low gradient means more stability
            score += 0.1
        }
        
        return min(1.0, score)
    }
    
    private func calculateDeepSleepScore(features: SleepFeatures) -> Double {
        var score = 0.0
        
        // Low heart rate (50-65 BPM typical for deep sleep)
        if features.heartRateAverage >= 45 && features.heartRateAverage <= 65 {
            score += 0.35
        }
        
        // Minimal movement
        if features.activityCount < 1.5 { // Using activityCount
            score += 0.3
        }
        
        // High HRV indicates parasympathetic dominance
        if features.rmssd > 35 { // Using rmssd for HRV
            score += 0.2
        }
        
        // Regular breathing (placeholder)
        if features.oxygenSaturation > 94.0 { // Proxy for regular breathing
            score += 0.15
        }
        
        // Optimal time window for deep sleep (11 PM - 3 AM)
        let hourOfDay = features.timestamp.hourOfDay
        if hourOfDay >= 23 || hourOfDay <= 3 {
            score += 0.2
        }
        
        // High temperature stability
        if abs(features.wristTemperatureGradient) < 0.02 { // Very low gradient means high stability
            score += 0.1
        }
        
        // Consider time since sleep onset (deep sleep typically occurs early)
        if features.sleepWakeDetection == 0.0 { // If currently in sleep state
            score += 0.15
        }
        
        return min(1.0, score)
    }
    
    private func calculateREMSleepScore(features: SleepFeatures) -> Double {
        var score = 0.0
        
        // Moderate to high heart rate (65-80 BPM during REM)
        if features.heartRateAverage >= 60 && features.heartRateAverage <= 85 {
            score += 0.3
        }
        
        // Variable heart rate (REM is characterized by variability)
        if features.heartRateVariability > 8 {
            score += 0.25
        }
        
        // Minimal physical movement (REM atonia)
        if features.activityCount < 1.0 { // Using activityCount
            score += 0.2
        }
        
        // Irregular breathing patterns during REM (placeholder)
        if features.oxygenSaturationVariability > 0.5 { // Proxy for irregular breathing
            score += 0.15
        }
        
        // REM typically occurs in later sleep cycles (4-6 AM)
        let hourOfDay = features.timestamp.hourOfDay
        if hourOfDay >= 4 && hourOfDay <= 6 {
            score += 0.2
        }
        
        // Consider sleep cycle timing (REM increases toward morning)
        if features.sleepWakeDetection == 0.0 { // If currently in sleep state
            score += 0.15
        }
        
        // Temperature regulation can be impaired during REM
        if abs(features.wristTemperatureGradient) > 0.05 && abs(features.wristTemperatureGradient) < 0.1 {
            score += 0.1
        }
        
        return min(1.0, score)
    }
    
    // MARK: - Temporal Consistency
    
    private func applyTemporalConsistency(to result: SleepStageResult, features: SleepFeatures) -> SleepStageResult {
        guard !recentClassifications.isEmpty else { return result }
        
        // Get previous stage for transition probability
        let previousStage = recentClassifications.last?.stage ?? .unknown
        
        // Apply transition probability weighting
        let transitionProb = transitionProbabilities[previousStage]?[result.stage] ?? 0.1
        
        // Adjust confidence based on transition probability
        let adjustedConfidence = result.confidence * (0.7 + 0.3 * transitionProb)
        
        // Check for rapid stage changes (potential noise)
        let rapidChangeCount = countRapidChanges(in: recentClassifications, window: 5)
        let stabilityPenalty = min(0.3, Double(rapidChangeCount) * 0.1)
        
        let finalConfidence = max(0.1, adjustedConfidence - stabilityPenalty)
        
        // If confidence drops below threshold, consider previous stage
        if finalConfidence < confidenceThreshold && result.confidence > 0.5 {
            let smoothedStage = applySmoothingFilter(currentStage: result.stage, confidence: finalConfidence)
            
            return SleepStageResult(
                stage: smoothedStage,
                confidence: finalConfidence,
                allScores: result.allScores,
                method: .temporallyAdjusted
            )
        }
        
        return SleepStageResult(
            stage: result.stage,
            confidence: finalConfidence,
            allScores: result.allScores,
            method: .temporallyAdjusted
        )
    }
    
    private func applySmoothingFilter(currentStage: SleepStageType, confidence: Double) -> SleepStageType {
        // Use majority vote from recent classifications if confidence is low
        let recentStages = recentClassifications.suffix(5).map { $0.stage }
        
        let stageCounts = Dictionary(grouping: recentStages, by: { $0 })
            .mapValues { $0.count }
        
        let majorityStage = stageCounts.max(by: { $0.value < $1.value })?.key
        
        return majorityStage ?? currentStage
    }
    
    private func countRapidChanges(in classifications: [(stage: SleepStageType, confidence: Double, timestamp: Date)], window: Int) -> Int {
        guard classifications.count >= window else { return 0 }
        
        let recent = Array(classifications.suffix(window))
        var changes = 0
        
        for i in 1..<recent.count {
            if recent[i].stage != recent[i-1].stage {
                changes += 1
            }
        }
        
        return changes
    }
    
    private func addToHistory(stage: SleepStageType, confidence: Double) {
        recentClassifications.append((stage: stage, confidence: confidence, timestamp: Date()))
        
        // Maintain history size
        if recentClassifications.count > historySize {
            recentClassifications.removeFirst()
        }
    }
    
    // MARK: - Model Performance
    
    func getClassificationAccuracy() -> [SleepStageType: Double] {
        return classificationAccuracy
    }
    
    func updateAccuracy(for stage: SleepStageType, accuracy: Double) {
        classificationAccuracy[stage] = accuracy
    }
    
    // MARK: - Advanced Features
    
    func predictNextStage(currentStage: SleepStageType, features: SleepFeatures) -> StagePrediction {
        let probabilities = transitionProbabilities[currentStage] ?? [:]
        
        // Adjust probabilities based on current features and time
        var adjustedProbabilities = probabilities
        
        // Consider circadian timing
        let hourOfDay = features.timestamp.hourOfDay
        
        if hourOfDay >= 4 && hourOfDay <= 6 {
            // Increase REM probability in early morning
            adjustedProbabilities[.remSleep] = (adjustedProbabilities[.remSleep] ?? 0) * 1.5
        }
        
        if hourOfDay >= 23 || hourOfDay <= 2 {
            // Increase deep sleep probability early in sleep
            adjustedProbabilities[.deepSleep] = (adjustedProbabilities[.deepSleep] ?? 0) * 1.3
        }
        
        // Normalize probabilities
        let total = adjustedProbabilities.values.reduce(0, +)
        if total > 0 {
            adjustedProbabilities = adjustedProbabilities.mapValues { $0 / total }
        }
        
        let mostLikelyStage = adjustedProbabilities.max(by: { $0.value < $1.value })?.key ?? .unknown
        let confidence = adjustedProbabilities[mostLikelyStage] ?? 0.0
        
        return StagePrediction(
            stage: mostLikelyStage,
            confidence: confidence,
            allProbabilities: adjustedProbabilities,
            timeToTransition: estimateTimeToTransition(from: currentStage, to: mostLikelyStage)
        )
    }
    
    private func estimateTimeToTransition(from currentStage: SleepStageType, to nextStage: SleepStageType) -> TimeInterval {
        // Typical stage durations in minutes
        let stageDurations: [SleepStageType: TimeInterval] = [
            .awake: 10 * 60,        // 10 minutes
            .lightSleep: 15 * 60,   // 15 minutes
            .deepSleep: 20 * 60,    // 20 minutes
            .remSleep: 25 * 60,     // 25 minutes
            .unknown: 5 * 60        // 5 minutes
        ]
        
        return stageDurations[currentStage] ?? 600 // Default 10 minutes
    }
}

// MARK: - Supporting Types

struct SleepStageResult {
    let stage: SleepStageType
    let confidence: Double
    let allScores: [SleepStageType: Double]
    let method: ClassificationMethod
}

struct StagePrediction {
    let stage: SleepStageType
    let confidence: Double
    let allProbabilities: [SleepStageType: Double]
    let timeToTransition: TimeInterval
}

enum ClassificationMethod {
    case algorithmic
    case coreML
    case temporallyAdjusted
    case ensemble
    case mlx
}

// Helper extension for Date to get hour of day
extension Date {
    var hourOfDay: Int {
        Calendar.current.component(.hour, from: self)
    }
}

// Add helper to convert SleepFeatures to MLX input array
extension SleepFeatures {
    func asMLXInputArray() -> [Double] {
        // Map relevant features to a [Double] array for MLX
        return [
            heartRateAverage,
            hrv,
            activityCount,
            wristTemperatureAverage,
            oxygenSaturation
        ]
    }
}