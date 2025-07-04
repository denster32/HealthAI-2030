import Foundation
import CoreML
import HealthKit
import Combine
import os.log

@available(iOS 17.0, *)
@available(macOS 14.0, *)

class CoreMLIntegrationManager: ObservableObject {
    static let shared = CoreMLIntegrationManager()
    
    private var sleepStageTransformer: SleepStageTransformer
    private var basePredictionEngine: BasePredictionEngine
    private var mlModelManager: MLModelManager
    private var sleepStageModel: SleepStageClassifier?
    @Published var coreMLLoadError: Error?

    @Published var modelLoadingStatus: [String: ModelLoadingStatus] = [:]
    @Published var predictionAccuracy: [String: Double] = [:]
    @Published var isModelInitialized = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private let maxLoadRetries = 3
    @Published var loadRetryCount: [String: Int] = [:]
    @Published var modelLoadDurations: [String: TimeInterval] = [:]

    private init() {
        sleepStageTransformer = SleepStageTransformer()
        basePredictionEngine = BasePredictionEngine()
        mlModelManager = MLModelManager.shared
        
        setupModelMonitoring()
        initializeModels()
    }
    
    private func setupModelMonitoring() {
        mlModelManager.$modelStatus
            .sink { [weak self] status in
                DispatchQueue.main.async {
                    self?.updateModelStatus(status)
                }
            }
            .store(in: &cancellables)
        
        mlModelManager.$modelAccuracy
            .sink { [weak self] accuracy in
                DispatchQueue.main.async {
                    self?.predictionAccuracy = accuracy
                }
            }
            .store(in: &cancellables)
    }
    
    private func initializeModels() {
        modelLoadingStatus["sleepStage"] = .loading
        modelLoadingStatus["healthPrediction"] = .loading
        modelLoadingStatus["arrhythmia"] = .loading
        
        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.loadAllModels()
        }
    }
    
    /// Loads CoreML models with retry logic, backoff, and performance metrics
    private func loadAllModels() async {
        let modelName = "sleepStage"
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        for attempt in 1...maxLoadRetries {
            // update loading status and retry count
            DispatchQueue.main.async {
                self.modelLoadingStatus[modelName] = .loading
                self.loadRetryCount[modelName] = attempt
            }
            let start = Date()
            do {
                try await loadModelWithiOS26Enhancements()
                let model = try SleepStageClassifier(configuration: config)
                let duration = Date().timeIntervalSince(start)
                DispatchQueue.main.async {
                    self.sleepStageModel = model
                    self.modelLoadDurations[modelName] = duration
                    self.modelLoadingStatus[modelName] = .loaded
                    self.predictionAccuracy[modelName] = MLModelManager.shared.modelAccuracy[modelName] ?? 0.0
                    self.isModelInitialized = true
                    
                    // Mark other models as loaded based on MLModelManager
                    self.modelLoadingStatus["healthPrediction"] = .loaded
                    self.predictionAccuracy["healthPrediction"] = self.mlModelManager.modelAccuracy["healthPrediction"] ?? 0.0
                    self.modelLoadingStatus["arrhythmia"] = .loaded
                    self.predictionAccuracy["arrhythmia"] = self.mlModelManager.modelAccuracy["arrhythmia"] ?? 0.0
                }
                return
            } catch {
                // on failure, retry or fail
                if attempt < maxLoadRetries {
                    // exponential backoff
                    try? await Task.sleep(nanoseconds: UInt64(Double(attempt) * 0.5 * 1_000_000_000))
                    continue
                } else {
                    DispatchQueue.main.async {
                        self.coreMLLoadError = error
                        self.modelLoadingStatus[modelName] = .error
                        self.isModelInitialized = false
                    }
                    os_log("Failed to load CoreML model %@ after %d attempts: %{public}@", log: .default, type: .error, modelName, attempt, String(describing: error))
                }
            }
        }
        
        // Load health prediction (mood) model
        for name in ["healthPrediction", "arrhythmia"] {
            DispatchQueue.main.async { self.modelLoadingStatus[name] = .loading }
            var loaded = false
            let maxRetries = maxLoadRetries
            for attempt in 1...maxRetries {
                do {
                    let model: MLModel?
                    if name == "healthPrediction" {
                        model = MLModelRegistry.moodPredictionModel
                    } else {
                        model = MLModelRegistry.arrhythmiaDetectionModel
                    }
                    guard let coreModel = model else { throw NSError(domain: "CoreMLIntegrationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not found in registry"] ) }
                    // Optionally wrap into specific type
                    let accuracy = MLModelManager.shared.modelAccuracy[name] ?? 0.0
                    DispatchQueue.main.async {
                        self.modelLoadingStatus[name] = .loaded
                        self.predictionAccuracy[name] = accuracy
                    }
                    loaded = true
                    break
                } catch {
                    if attempt < maxRetries {
                        try? await Task.sleep(nanoseconds: UInt64(Double(attempt) * 0.3 * 1_000_000_000))
                        continue
                    } else {
                        DispatchQueue.main.async {
                            self.modelLoadingStatus[name] = .error
                            self.predictionAccuracy[name] = 0.0
                            self.coreMLLoadError = NSError(domain: "CoreMLIntegrationManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed loading \(name) model: \(error.localizedDescription)"])
                        }
                    }
                }
            }
        }
    }
    
    private func loadModelWithiOS26Enhancements() async throws {
        // Use optimized model loading with background processing
        let config = MLModelConfiguration()
        config.allowLowPrecisionAccumulationOnGPU = true
        config.computeUnits = .cpuAndNeuralEngine
        
        // Note: Future optimizations will be added when available in newer iOS versions
        // For now, we use standard configuration options
    }
    
    private func updateModelStatus(_ status: [String: ModelStatus]) {
        for (modelName, modelStatus) in status {
            switch modelStatus {
            case .loading:
                modelLoadingStatus[modelName] = .loading
            case .loaded:
                modelLoadingStatus[modelName] = .loaded
            case .training:
                modelLoadingStatus[modelName] = .training
            case .error:
                modelLoadingStatus[modelName] = .error
            }
        }
    }
    
    /// Predicts sleep stage using the loaded CoreML model
    func predictSleepStage(from sensorData: [SensorSample]) -> SleepPredictionResult {
        guard isModelInitialized, let model = sleepStageModel else {
            return SleepPredictionResult(
                stage: .unknown,
                confidence: 0.0,
                quality: 0.0,
                modelUsed: modelLoadingStatus["sleepStage"] == .error ? "Error" : "Not Initialized",
                timestamp: Date()
            )
        }
        
        let sleepFeatureExtractor = SleepFeatureExtractor()
        let features = sleepFeatureExtractor.extractFeatures(from: sensorData)
        
        do {
            let input = SleepStageClassifierInput(
                heart_rate: features.heartRate,
                hrv: features.hrv,
                motion: features.movement,
                spo2: features.oxygenSaturation
            )
            let output = try model.prediction(input: input)
            
            let stage: SleepStageType = {
                switch output.sleep_stage {
                case 0: return .awake
                case 1: return .lightSleep
                case 2: return .deepSleep
                case 3: return .remSleep
                default: return .unknown
                }
            }()
            
            let confidence = output.sleep_stageProbability?[NSNumber(value: output.sleep_stage)]?.doubleValue ?? 0.0
            return SleepPredictionResult(
                stage: stage,
                confidence: confidence,
                quality: confidence,
                modelUsed: getModelName(for: "sleepStage"),
                timestamp: Date()
            )
        } catch {
            os_log("SleepStage prediction error: %{public}@", log: .default, type: .error, String(describing: error))
            return SleepPredictionResult(
                stage: .unknown,
                confidence: 0.0,
                quality: 0.0,
                modelUsed: "Error",
                timestamp: Date()
            )
        }
    }
    
    func predictHealthMetrics(currentMetrics: HealthMetrics, historicalData: [HealthMetrics]) -> HealthPredictionResult {
        guard isModelInitialized else {
            return HealthPredictionResult(
                energy: 0.5,
                mood: 0.5,
                cognitiveAcuity: 0.5,
                musculoskeletalResilience: 0.5,
                confidence: 0.0,
                modelUsed: "None - Not Initialized",
                timestamp: Date()
            )
        }
        
        let features = createHealthPredictionFeatures(from: currentMetrics, historical: historicalData)
        let prediction = mlModelManager.predictHealthMetrics(features: features)
        
        return HealthPredictionResult(
            energy: prediction.energy,
            mood: prediction.mood,
            cognitiveAcuity: prediction.cognitiveAcuity,
            musculoskeletalResilience: prediction.resilience,
            confidence: predictionAccuracy["healthPrediction"] ?? 0.0,
            modelUsed: getModelName(for: "healthPrediction"),
            timestamp: Date()
        )
    }
    
    func analyzeHeartRhythm(ecgData: [Double]) -> ArrhythmiaAnalysisResult {
        guard isModelInitialized else {
            return ArrhythmiaAnalysisResult(
                type: .normal,
                confidence: 0.0,
                severity: 0.0,
                recommendation: "Models not initialized",
                modelUsed: "None - Not Initialized",
                timestamp: Date()
            )
        }
        
        let detection = mlModelManager.detectArrhythmia(ecgData: ecgData)
        
        return ArrhythmiaAnalysisResult(
            type: detection.type,
            confidence: detection.confidence,
            severity: detection.severity,
            recommendation: generateArrhythmiaRecommendation(for: detection.type, severity: detection.severity),
            modelUsed: getModelName(for: "arrhythmia"),
            timestamp: Date()
        )
    }
    
    func simulateHealthScenario(_ scenario: HealthScenario) -> HealthSimulationResult {
        let simulation = mlModelManager.simulateHealthScenario(scenario: scenario)
        
        return HealthSimulationResult(
            metrics: simulation.metrics,
            confidence: simulation.confidence,
            recommendations: generateScenarioRecommendations(for: scenario, results: simulation.metrics),
            modelUsed: getModelName(for: "digitalTwin"),
            timestamp: Date()
        )
    }
    
    private func createHealthPredictionFeatures(from metrics: HealthMetrics, historical: [HealthMetrics]) -> HealthPredictionFeatures {
        let avgSleepQuality = historical.isEmpty ? 0.7 : 0.75
        let avgStressLevel = 0.4
        let avgNutritionScore = 0.8
        let avgActivityLevel = Double(metrics.stepCount) / 10000.0
        
        return HealthPredictionFeatures(
            sleepQuality: avgSleepQuality,
            hrv: metrics.hrv,
            heartRate: metrics.heartRate,
            activityLevel: avgActivityLevel,
            stressLevel: avgStressLevel,
            nutritionScore: avgNutritionScore
        )
    }
    
    private func generateArrhythmiaRecommendation(for type: ArrhythmiaType, severity: Double) -> String {
        switch type {
        case .normal:
            return "Heart rhythm appears normal. Continue regular monitoring."
        case .atrialFibrillation:
            if severity > 0.7 {
                return "Significant atrial fibrillation detected. Consult a cardiologist immediately."
            } else {
                return "Mild atrial fibrillation detected. Monitor closely and consult healthcare provider."
            }
        case .ventricularTachycardia:
            return "Ventricular tachycardia detected. Seek immediate medical attention."
        case .bradycardia:
            return "Slow heart rate detected. Consult healthcare provider if symptoms persist."
        case .prematureBeats:
            return "Premature beats detected. Usually benign but monitor for frequency."
        }
    }
    
    private func generateScenarioRecommendations(for scenario: HealthScenario, results: [String: Double]) -> [String] {
        var recommendations: [String] = []
        
        if let energy = results["energy"], energy < 0.6 {
            if scenario.sleepHours < 7 {
                recommendations.append("Increase sleep duration to 7-9 hours for better energy levels")
            }
            if scenario.exerciseMinutes < 30 {
                recommendations.append("Add 30+ minutes of daily exercise to boost energy")
            }
        }
        
        if let mood = results["mood"], mood < 0.6 {
            if scenario.stressLevel > 0.7 {
                recommendations.append("Practice stress reduction techniques like meditation")
            }
            if scenario.sleepHours < 7 {
                recommendations.append("Prioritize adequate sleep for mood stability")
            }
        }
        
        if let cognitive = results["cognitive"], cognitive < 0.6 {
            if scenario.caffeineIntake > 400 {
                recommendations.append("Reduce caffeine intake to improve cognitive function")
            }
            recommendations.append("Consider brain training exercises and adequate hydration")
        }
        
        return recommendations.isEmpty ? ["All metrics look good! Continue current lifestyle."] : recommendations
    }
    
    /// Returns retry count and load duration for a given model
    func getLoadMetrics(for model: String) -> (retries: Int, duration: TimeInterval?) {
        let retries = loadRetryCount[model] ?? 0
        let duration = modelLoadDurations[model]
        return (retries, duration)
    }

    /// Provides friendly model name and version if available
    private func getModelName(for type: String) -> String {
        var name = type.capitalized
        if let (retries, duration) = Optional(getLoadMetrics(for: type)), retries > 0 {
            name += " (loaded in \(String(format: "%.2fs", duration ?? 0)) after \(retries) attempts)"
        }
        return name
    }
    
    func getModelStatus() -> [String: ModelLoadingStatus] {
        return modelLoadingStatus
    }
    
    func reloadModels() {
        isModelInitialized = false
        initializeModels()
    }
    
    func enableFederatedLearning() {
        mlModelManager.syncWithFederatedServer()
    }
    
    func updateModelsWithLocalData(_ trainingData: [TrainingSample]) {
        mlModelManager.updateModelLocally(trainingData: trainingData)
    }
}

enum ModelLoadingStatus {
    case loading
    case loaded
    case fallback
    case training
    case error
}

struct SleepPredictionResult {
    let stage: SleepStageType
    let confidence: Double
    let quality: Double
    let modelUsed: String
    let timestamp: Date
}

struct HealthPredictionResult {
    let energy: Double
    let mood: Double
    let cognitiveAcuity: Double
    let musculoskeletalResilience: Double
    let confidence: Double
    let modelUsed: String
    let timestamp: Date
}

struct ArrhythmiaAnalysisResult {
    let type: ArrhythmiaType
    let confidence: Double
    let severity: Double
    let recommendation: String
    let modelUsed: String
    let timestamp: Date
}

struct HealthSimulationResult {
    let metrics: [String: Double]
    let confidence: Double
    let recommendations: [String]
    let modelUsed: String
    let timestamp: Date
}

extension CoreMLIntegrationManager {
    
    func generateTrainingData(from healthMetrics: [HealthMetrics], sleepData: [SleepMetrics]) -> [TrainingSample] {
        var trainingData: [TrainingSample] = []
        
        for metric in healthMetrics {
            let features = [
                metric.heartRate,
                metric.hrv,
                metric.oxygenSaturation,
                metric.bodyTemperature,
                Double(metric.stepCount) / 10000.0,
                metric.activeEnergyBurned / 2000.0
            ]
            
            let sleepQuality = calculateSleepQualityLabel(heartRate: metric.heartRate, hrv: metric.hrv)
            
            let sample = TrainingSample(
                features: features,
                label: sleepQuality,
                timestamp: metric.timestamp
            )
            
            trainingData.append(sample)
        }
        
        return trainingData
    }
    
    private func calculateSleepQualityLabel(heartRate: Double, hrv: Double) -> Double {
        if heartRate < 60 && hrv > 40 {
            return 1.0
        } else if heartRate < 70 && hrv > 30 {
            return 0.8
        } else if heartRate < 80 && hrv > 20 {
            return 0.6
        } else {
            return 0.4
        }
    }
}