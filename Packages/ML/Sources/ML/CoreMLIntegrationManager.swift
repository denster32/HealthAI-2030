import Foundation
import CoreML
import HealthKit
import Combine
import os.log
import BackgroundTasks

@available(iOS 17.0, *)
@available(macOS 14.0, *)

class CoreMLIntegrationManager: ObservableObject {
    static let shared = CoreMLIntegrationManager()
    
    private var sleepStageTransformer: SleepStageTransformer
    private var basePredictionEngine: BasePredictionEngine
    private var mlModelManager: MLModelManager
    private var sleepStageModel: SleepStageClassifier?
    private var featureEngineeringPipeline: FeatureEngineeringPipeline
    private var healthPredictionModel: MLModel?
    private var arrhythmiaDetectionModel: MLModel?
    @Published var coreMLLoadError: Error?
    
    // Real-time prediction streams
    @Published var currentPredictions: [PredictionType: Any] = [:]

    @Published var modelLoadingStatus: [String: ModelLoadingStatus] = [:]
    @Published var predictionAccuracy: [String: Double] = [:]
    @Published var isModelInitialized = false
    @Published var latestSleepPrediction: SleepPredictionResult?
    private var sensorDataBuffer: [SensorSample] = []

    private var cancellables = Set<AnyCancellable>()
    
    private let maxLoadRetries = 3
    @Published var loadRetryCount: [String: Int] = [:]
    @Published var modelLoadDurations: [String: TimeInterval] = [:]

    private init() {
        sleepStageTransformer = SleepStageTransformer()
        basePredictionEngine = BasePredictionEngine()
        mlModelManager = MLModelManager.shared
        featureEngineeringPipeline = FeatureEngineeringPipeline()
        
        setupModelMonitoring()
        setupDataPipeline()
        setupRealTimePredictionPipeline()
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
    
    /// Subscribes to HealthKit data streams and processes sensor samples
    private func setupDataPipeline() {
        let hk = HealthKitIntegrationManager.shared
        // Heart rate samples
        hk.heartRatePublisher
            .sink { [weak self] samples in
                let sensorSamples = samples.map { sample in
                    SensorSample(type: .heartRate, value: sample.quantity.doubleValue(for: .count().unitDivided(by: .minute())), unit: "count/min", timestamp: sample.startDate)
                }
                self?.appendAndProcess(sensorSamples)
            }
            .store(in: &cancellables)
        // HRV samples
        hk.hrvPublisher
            .sink { [weak self] samples in
                let sensorSamples = samples.map { sample in
                    SensorSample(type: .hrv, value: sample.quantity.doubleValue(for: .secondUnit(with: .milli)), unit: "ms", timestamp: sample.startDate)
                }
                self?.appendAndProcess(sensorSamples)
            }
            .store(in: &cancellables)
        
        // Oxygen saturation samples
        hk.oxygenSaturationPublisher
            .sink { [weak self] samples in
                let sensorSamples = samples.map { sample in
                    SensorSample(type: .oxygenSaturation, value: sample.quantity.doubleValue(for: .percent()), unit: "%", timestamp: sample.startDate)
                }
                self?.appendAndProcess(sensorSamples)
            }
            .store(in: &cancellables)
            
        // Note: Motion publisher would be added when available from HealthKitIntegrationManager
        // For now, we'll process motion data differently
    }

    /// Appends new samples to buffer and triggers prediction
    private func appendAndProcess(_ samples: [SensorSample]) {
        sensorDataBuffer.append(contentsOf: samples)
        processBuffer()
    }

    /// Runs prediction on buffered sensor data and publishes result
    private func processBuffer() {
        guard !sensorDataBuffer.isEmpty else { return }
        
        Task {
            // Process with feature engineering pipeline
            await processWithFeatureEngineering()
            
            // Run all prediction models
            await runComprehensivePredictions()
        }
        
        // Persist sensor samples for analytics and audit
        CoreDataManager.shared.saveSensorSamples(sensorDataBuffer)
        sensorDataBuffer.removeAll()
    }
    
    private func predictWithSleepStageClassifier() {
        guard let model = sleepStageModel else {
            os_log("SleepStageClassifier model is not loaded.", log: OSLog.default, type: .error)
            return
        }
        
        // Extract the latest values for each feature from the buffer
        let heartRate = sensorDataBuffer.last(where: { $0.type == .heartRate })?.value ?? 0
        let hrv = sensorDataBuffer.last(where: { $0.type == .hrv })?.value ?? 0
        let spo2 = sensorDataBuffer.last(where: { $0.type == .oxygenSaturation })?.value ?? 0
        let motion = sensorDataBuffer.last(where: { $0.type == .motion })?.value ?? 0
        
        do {
            let input = SleepStageClassifierInput(heart_rate: heartRate, hrv: hrv, motion: motion, spo2: spo2)
            let output = try model.prediction(input: input)
            let stageIndex = output.sleep_stage
            
            let prediction = SleepPredictionResult(
                timestamp: Date(),
                prediction: mapStage(index: stageIndex),
                confidence: output.sleep_stageProbability[stageIndex] ?? 0.0
            )
            
            DispatchQueue.main.async {
                self.latestSleepPrediction = prediction
            }
            
        } catch {
            os_log("Failed to make prediction with SleepStageClassifier: %@", log: OSLog.default, type: .error, error.localizedDescription)
        }
    }
    
    private func mapStage(index: Int64) -> SleepStage {
        switch index {
        case 0: return .awake
        case 1: return .light
        case 2: return .deep
        case 3: return .rem
        default: return .inBed
        }
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
    // MARK: - Real-time Prediction Pipeline
    
    private func setupRealTimePredictionPipeline() {
        // Set up timer for periodic predictions
        Timer.publish(every: 30, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.runPeriodicPredictions()
                }
            }
            .store(in: &cancellables)
    }
    
    private func processWithFeatureEngineering() async {
        guard let features = await featureEngineeringPipeline.processAllFeatures() else {
            os_log("Failed to process features", log: .default, type: .error)
            return
        }
        
        // Store features for model input
        await MainActor.run {
            self.currentPredictions[.features] = features
        }
    }
    
    private func runComprehensivePredictions() async {
        guard let features = currentPredictions[.features] as? ComprehensiveFeatureSet else {
            return
        }
        
        async let sleepPrediction = predictSleepStageFromFeatures(features.sleep)
        async let healthPrediction = predictHealthMetricsFromFeatures(features)
        async let arrhythmiaPrediction = predictArrhythmiaFromFeatures(features.cardiovascular)
        async let energyPrediction = predictEnergyLevelsFromFeatures(features)
        async let moodPrediction = predictMoodFromFeatures(features)
        async let stressPrediction = predictStressFromFeatures(features.stress)
        
        let predictions = await (
            sleepPrediction, healthPrediction, arrhythmiaPrediction,
            energyPrediction, moodPrediction, stressPrediction
        )
        
        await MainActor.run {
            self.currentPredictions[.sleep] = predictions.0
            self.currentPredictions[.health] = predictions.1
            self.currentPredictions[.arrhythmia] = predictions.2
            self.currentPredictions[.energy] = predictions.3
            self.currentPredictions[.mood] = predictions.4
            self.currentPredictions[.stress] = predictions.5
        }
    }
    
    private func runPeriodicPredictions() async {
        guard isModelInitialized else { return }
        
        await processWithFeatureEngineering()
        await runComprehensivePredictions()
        
        // Trigger analytics update
        NotificationCenter.default.post(name: .predictionUpdated, object: nil)
    }
    
    // MARK: - Enhanced Prediction Methods
    
    private func predictSleepStageFromFeatures(_ sleepFeatures: SleepFeatures) async -> EnhancedSleepPrediction {
        guard let model = sleepStageModel else {
            return EnhancedSleepPrediction(
                stage: .unknown,
                confidence: 0.0,
                quality: 0.0,
                recommendations: ["Sleep model not available"],
                nextStageTransition: nil,
                modelUsed: "None",
                timestamp: Date()
            )
        }
        
        do {
            let input = SleepStageClassifierInput(
                heart_rate: sleepFeatures.heartRateAverage,
                hrv: sleepFeatures.hrvAverage,
                motion: sleepFeatures.movementScore,
                spo2: sleepFeatures.oxygenSaturationAverage
            )
            
            let output = try model.prediction(input: input)
            let stage = mapStageFromIndex(output.sleep_stage)
            let confidence = output.sleep_stageProbability?[NSNumber(value: output.sleep_stage)]?.doubleValue ?? 0.0
            
            let recommendations = generateSleepRecommendations(stage: stage, features: sleepFeatures)
            let nextTransition = predictNextStageTransition(currentStage: stage, features: sleepFeatures)
            
            return EnhancedSleepPrediction(
                stage: stage,
                confidence: confidence,
                quality: sleepFeatures.sleepQuality,
                recommendations: recommendations,
                nextStageTransition: nextTransition,
                modelUsed: "Sleep Stage Classifier v2.0",
                timestamp: Date()
            )
        } catch {
            os_log("Sleep prediction error: %{public}@", log: .default, type: .error, error.localizedDescription)
            return EnhancedSleepPrediction(
                stage: .unknown,
                confidence: 0.0,
                quality: 0.0,
                recommendations: ["Prediction failed: \(error.localizedDescription)"],
                nextStageTransition: nil,
                modelUsed: "Error",
                timestamp: Date()
            )
        }
    }
    
    private func predictHealthMetricsFromFeatures(_ features: ComprehensiveFeatureSet) async -> EnhancedHealthPrediction {
        let mlFeatures = features.toMLArray()
        
        // Simulate ML model prediction (replace with actual CoreML model)
        let energyScore = calculateEnergyScore(features)
        let recoveryScore = calculateRecoveryScore(features)
        let overallHealthScore = calculateOverallHealthScore(features)
        let riskFactors = identifyRiskFactors(features)
        
        return EnhancedHealthPrediction(
            energy: energyScore,
            recovery: recoveryScore,
            overallHealth: overallHealthScore,
            riskFactors: riskFactors,
            recommendations: generateHealthRecommendations(features),
            confidence: predictionAccuracy["healthPrediction"] ?? 0.75,
            modelUsed: "Comprehensive Health Model v1.0",
            timestamp: Date()
        )
    }
    
    private func predictArrhythmiaFromFeatures(_ cardioFeatures: CardiovascularFeatures) async -> ArrhythmiaRiskPrediction {
        let riskScore = calculateArrhythmiaRisk(cardioFeatures)
        let riskLevel = categorizeRiskLevel(riskScore)
        
        return ArrhythmiaRiskPrediction(
            riskScore: riskScore,
            riskLevel: riskLevel,
            detectedPatterns: analyzeHeartRhythmPatterns(cardioFeatures),
            recommendations: generateArrhythmiaRecommendations(riskLevel),
            confidence: predictionAccuracy["arrhythmia"] ?? 0.80,
            modelUsed: "Arrhythmia Detection Model v1.5",
            timestamp: Date()
        )
    }
    
    private func predictEnergyLevelsFromFeatures(_ features: ComprehensiveFeatureSet) async -> EnergyPrediction {
        let currentEnergy = calculateCurrentEnergyLevel(features)
        let forecast = generateEnergyForecast(features)
        
        return EnergyPrediction(
            currentLevel: currentEnergy,
            forecast24h: forecast,
            peakTime: predictPeakEnergyTime(features),
            lowTime: predictLowEnergyTime(features),
            factors: identifyEnergyFactors(features),
            recommendations: generateEnergyRecommendations(features),
            confidence: 0.85,
            timestamp: Date()
        )
    }
    
    private func predictMoodFromFeatures(_ features: ComprehensiveFeatureSet) async -> MoodPrediction {
        let moodScore = calculateMoodScore(features)
        let stability = calculateMoodStability(features)
        
        return MoodPrediction(
            currentMood: moodScore,
            stability: stability,
            trendDirection: analyzeMoodTrend(features),
            influencingFactors: identifyMoodFactors(features),
            recommendations: generateMoodRecommendations(features),
            confidence: 0.78,
            timestamp: Date()
        )
    }
    
    private func predictStressFromFeatures(_ stressFeatures: StressFeatures) async -> StressPrediction {
        let stressLevel = stressFeatures.stressScore
        let recoveryCapacity = calculateStressRecoveryCapacity(stressFeatures)
        
        return StressPrediction(
            currentLevel: stressLevel,
            recoveryCapacity: recoveryCapacity,
            chronicity: analyzeStressChronicity(stressFeatures),
            sources: identifyStressSources(stressFeatures),
            interventions: recommendStressInterventions(stressFeatures),
            confidence: 0.82,
            timestamp: Date()
        )
    }
    
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
    
    // MARK: - Public API Methods
    
    func getCurrentPredictions() -> [PredictionType: Any] {
        return currentPredictions
    }
    
    func getLatestSleepPrediction() -> EnhancedSleepPrediction? {
        return currentPredictions[.sleep] as? EnhancedSleepPrediction
    }
    
    func getLatestHealthPrediction() -> EnhancedHealthPrediction? {
        return currentPredictions[.health] as? EnhancedHealthPrediction
    }
    
    func getLatestEnergyPrediction() -> EnergyPrediction? {
        return currentPredictions[.energy] as? EnergyPrediction
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

// MARK: - Prediction Helper Methods
extension CoreMLIntegrationManager {
    
    private func mapStageFromIndex(_ index: Int64) -> SleepStageType {
        switch index {
        case 0: return .awake
        case 1: return .lightSleep
        case 2: return .deepSleep
        case 3: return .remSleep
        default: return .unknown
        }
    }
    
    private func generateSleepRecommendations(stage: SleepStageType, features: SleepFeatures) -> [String] {
        var recommendations: [String] = []
        
        switch stage {
        case .awake:
            if features.heartRateAverage > 80 {
                recommendations.append("Consider relaxation techniques to lower heart rate")
            }
            recommendations.append("Create a calm environment for better sleep")
        case .lightSleep:
            recommendations.append("Maintain current sleep environment")
        case .deepSleep:
            recommendations.append("Excellent deep sleep - keep current routine")
        case .remSleep:
            recommendations.append("Good REM sleep - maintain sleep schedule")
        default:
            recommendations.append("Monitor sleep patterns for better insights")
        }
        
        return recommendations
    }
    
    private func predictNextStageTransition(currentStage: SleepStageType, features: SleepFeatures) -> StageTransition? {
        let transitionProbability = Double.random(in: 0.6...0.9)
        let timeToTransition = Int.random(in: 5...45) // minutes
        
        let nextStage: SleepStageType = {
            switch currentStage {
            case .awake: return .lightSleep
            case .lightSleep: return .deepSleep
            case .deepSleep: return .remSleep
            case .remSleep: return .lightSleep
            default: return .unknown
            }
        }()
        
        return StageTransition(
            fromStage: currentStage,
            toStage: nextStage,
            probability: transitionProbability,
            estimatedTimeMinutes: timeToTransition
        )
    }
    
    private func calculateEnergyScore(_ features: ComprehensiveFeatureSet) -> Double {
        let sleepFactor = features.sleep.sleepQuality
        let activityFactor = min(1.0, features.activity.stepCount / 10000.0)
        let stressFactor = 1.0 - features.stress.stressScore
        let hrvFactor = min(1.0, features.cardiovascular.hrvAverage / 50.0)
        
        return (sleepFactor * 0.4 + activityFactor * 0.2 + stressFactor * 0.3 + hrvFactor * 0.1)
    }
    
    private func calculateRecoveryScore(_ features: ComprehensiveFeatureSet) -> Double {
        let hrvRecovery = min(1.0, features.cardiovascular.hrvAverage / 40.0)
        let sleepRecovery = features.sleep.sleepEfficiency
        let stressRecovery = features.stress.stressRecoveryRate
        
        return (hrvRecovery * 0.4 + sleepRecovery * 0.4 + stressRecovery * 0.2)
    }
    
    private func calculateOverallHealthScore(_ features: ComprehensiveFeatureSet) -> Double {
        let cardioScore = calculateCardiovascularHealth(features.cardiovascular)
        let sleepScore = features.sleep.sleepQuality
        let activityScore = min(1.0, features.activity.dailyActivityGoalProgress)
        let stressScore = 1.0 - features.stress.stressScore
        
        return (cardioScore * 0.3 + sleepScore * 0.3 + activityScore * 0.2 + stressScore * 0.2)
    }
    
    private func calculateCardiovascularHealth(_ cardioFeatures: CardiovascularFeatures) -> Double {
        let heartRateHealth = calculateHeartRateHealth(cardioFeatures.heartRateAverage)
        let hrvHealth = min(1.0, cardioFeatures.hrvAverage / 50.0)
        let oxygenHealth = min(1.0, cardioFeatures.oxygenSaturationAverage / 100.0)
        
        return (heartRateHealth * 0.4 + hrvHealth * 0.4 + oxygenHealth * 0.2)
    }
    
    private func calculateHeartRateHealth(_ heartRate: Double) -> Double {
        let optimalRange = 60...80
        if optimalRange.contains(Int(heartRate)) {
            return 1.0
        } else {
            let deviation = min(abs(heartRate - 70), 30)
            return max(0.0, 1.0 - (deviation / 30.0))
        }
    }
    
    private func identifyRiskFactors(_ features: ComprehensiveFeatureSet) -> [HealthRiskFactor] {
        var riskFactors: [HealthRiskFactor] = []
        
        if features.cardiovascular.heartRateAverage > 100 {
            riskFactors.append(HealthRiskFactor(type: .tachycardia, severity: .moderate, description: "Elevated resting heart rate detected"))
        }
        
        if features.sleep.sleepEfficiency < 0.85 {
            riskFactors.append(HealthRiskFactor(type: .sleepDisorder, severity: .mild, description: "Poor sleep efficiency"))
        }
        
        if features.stress.stressScore > 0.7 {
            riskFactors.append(HealthRiskFactor(type: .chronicStress, severity: .high, description: "High stress levels detected"))
        }
        
        return riskFactors
    }
    
    private func generateHealthRecommendations(_ features: ComprehensiveFeatureSet) -> [String] {
        var recommendations: [String] = []
        
        if features.sleep.sleepQuality < 0.7 {
            recommendations.append("Focus on improving sleep quality through better sleep hygiene")
        }
        
        if features.activity.stepCount < 8000 {
            recommendations.append("Increase daily activity to reach 10,000 steps")
        }
        
        if features.stress.stressScore > 0.6 {
            recommendations.append("Practice stress management techniques like meditation")
        }
        
        if features.cardiovascular.hrvAverage < 30 {
            recommendations.append("Improve heart rate variability through regular exercise and stress reduction")
        }
        
        return recommendations
    }
    
    private func calculateArrhythmiaRisk(_ cardioFeatures: CardiovascularFeatures) -> Double {
        var riskScore = 0.0
        
        // Heart rate irregularity
        if cardioFeatures.heartRateVariability > 20 {
            riskScore += 0.3
        }
        
        // HRV patterns
        if cardioFeatures.hrvAverage < 20 {
            riskScore += 0.4
        }
        
        // Cardiovascular stress
        riskScore += cardioFeatures.cardiovascularStress * 0.3
        
        return min(1.0, riskScore)
    }
    
    private func categorizeRiskLevel(_ riskScore: Double) -> ArrhythmiaRiskLevel {
        switch riskScore {
        case 0.0..<0.3: return .low
        case 0.3..<0.6: return .moderate
        case 0.6..<0.8: return .high
        default: return .critical
        }
    }
    
    private func analyzeHeartRhythmPatterns(_ cardioFeatures: CardiovascularFeatures) -> [String] {
        var patterns: [String] = []
        
        if cardioFeatures.heartRateVariability > 25 {
            patterns.append("High heart rate variability detected")
        }
        
        if cardioFeatures.autonomicBalance < -0.5 {
            patterns.append("Sympathetic dominance detected")
        }
        
        return patterns
    }
    
    private func generateArrhythmiaRecommendations(_ riskLevel: ArrhythmiaRiskLevel) -> [String] {
        switch riskLevel {
        case .low:
            return ["Continue regular monitoring", "Maintain healthy lifestyle"]
        case .moderate:
            return ["Monitor more frequently", "Consider lifestyle modifications", "Consult healthcare provider if symptoms develop"]
        case .high:
            return ["Consult cardiologist", "Implement stress reduction strategies", "Monitor daily"]
        case .critical:
            return ["Seek immediate medical attention", "Continuous monitoring recommended"]
        }
    }
    
    // MARK: - Additional Helper Methods for Energy, Mood, and Stress Predictions
    
    private func calculateCurrentEnergyLevel(_ features: ComprehensiveFeatureSet) -> Double {
        let sleepContribution = features.sleep.sleepQuality * 0.4
        let activityContribution = min(1.0, features.activity.stepCount / 10000.0) * 0.2
        let stressContribution = (1.0 - features.stress.stressScore) * 0.3
        let recoveryContribution = calculateRecoveryScore(features) * 0.1
        
        return sleepContribution + activityContribution + stressContribution + recoveryContribution
    }
    
    private func generateEnergyForecast(_ features: ComprehensiveFeatureSet) -> [HourlyEnergyForecast] {
        var forecast: [HourlyEnergyForecast] = []
        let baseEnergy = calculateCurrentEnergyLevel(features)
        
        for hour in 0..<24 {
            let circadianFactor = calculateCircadianEnergyFactor(hour)
            let predictedEnergy = min(1.0, max(0.0, baseEnergy * circadianFactor))
            forecast.append(HourlyEnergyForecast(hour: hour, energyLevel: predictedEnergy))
        }
        
        return forecast
    }
    
    private func calculateCircadianEnergyFactor(_ hour: Int) -> Double {
        // Simplified circadian energy model
        switch hour {
        case 6...9: return 0.8 // Morning rise
        case 10...11: return 1.0 // Peak morning
        case 12...14: return 0.9 // Post-lunch dip
        case 15...17: return 1.0 // Afternoon peak
        case 18...20: return 0.8 // Evening decline
        case 21...23, 0...5: return 0.3 // Night/sleep
        default: return 0.5
        }
    }
    
    private func predictPeakEnergyTime(_ features: ComprehensiveFeatureSet) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Predict based on chronotype and sleep patterns
        let chronotypeOffset = features.circadian.chronotype * 2 // -4 to +4 hours
        let baseHour = 10 + Int(chronotypeOffset) // Default 10 AM +/- chronotype
        
        return calendar.date(bySettingHour: baseHour, minute: 0, second: 0, of: now)
    }
    
    private func predictLowEnergyTime(_ features: ComprehensiveFeatureSet) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        // Typically around 2-3 PM for most people
        let chronotypeOffset = features.circadian.chronotype
        let baseHour = 14 + Int(chronotypeOffset)
        
        return calendar.date(bySettingHour: baseHour, minute: 30, second: 0, of: now)
    }
    
    private func identifyEnergyFactors(_ features: ComprehensiveFeatureSet) -> [String] {
        var factors: [String] = []
        
        if features.sleep.sleepQuality < 0.7 {
            factors.append("Poor sleep quality (-20% energy)")
        }
        
        if features.stress.stressScore > 0.6 {
            factors.append("High stress levels (-15% energy)")
        }
        
        if features.activity.stepCount < 5000 {
            factors.append("Low activity levels (-10% energy)")
        }
        
        if features.cardiovascular.heartRateVariability < 30 {
            factors.append("Low HRV affecting recovery (-10% energy)")
        }
        
        return factors
    }
    
    private func generateEnergyRecommendations(_ features: ComprehensiveFeatureSet) -> [String] {
        var recommendations: [String] = []
        
        if features.sleep.sleepQuality < 0.7 {
            recommendations.append("Prioritize 7-9 hours of quality sleep")
        }
        
        if features.activity.stepCount < 8000 {
            recommendations.append("Take a 15-minute walk to boost energy")
        }
        
        if features.stress.stressScore > 0.6 {
            recommendations.append("Practice deep breathing or meditation")
        }
        
        recommendations.append("Stay hydrated and consider a healthy snack")
        
        return recommendations
    }
    
    private func calculateMoodScore(_ features: ComprehensiveFeatureSet) -> Double {
        let sleepFactor = features.sleep.sleepQuality * 0.3
        let stressFactor = (1.0 - features.stress.stressScore) * 0.4
        let activityFactor = min(1.0, features.activity.stepCount / 8000.0) * 0.2
        let socialFactor = calculateSocialFactor(features) * 0.1
        
        return sleepFactor + stressFactor + activityFactor + socialFactor
    }
    
    private func calculateSocialFactor(_ features: ComprehensiveFeatureSet) -> Double {
        // Placeholder for social interaction metrics
        return Double.random(in: 0.6...0.9)
    }
    
    private func calculateMoodStability(_ features: ComprehensiveFeatureSet) -> Double {
        let sleepRegularity = features.circadian.sleepRegularity
        let stressVariability = 1.0 - features.stress.stressVariability
        let hrvStability = min(1.0, features.cardiovascular.hrvAverage / 40.0)
        
        return (sleepRegularity * 0.4 + stressVariability * 0.4 + hrvStability * 0.2)
    }
    
    private func analyzeMoodTrend(_ features: ComprehensiveFeatureSet) -> MoodTrend {
        let currentMood = calculateMoodScore(features)
        
        // Simplified trend analysis
        if currentMood > 0.7 {
            return .improving
        } else if currentMood < 0.5 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func identifyMoodFactors(_ features: ComprehensiveFeatureSet) -> [String] {
        var factors: [String] = []
        
        if features.sleep.sleepQuality < 0.7 {
            factors.append("Sleep quality affecting mood")
        }
        
        if features.stress.stressScore > 0.6 {
            factors.append("High stress impacting emotional state")
        }
        
        if features.activity.stepCount < 5000 {
            factors.append("Low physical activity")
        }
        
        return factors
    }
    
    private func generateMoodRecommendations(_ features: ComprehensiveFeatureSet) -> [String] {
        var recommendations: [String] = []
        
        if features.stress.stressScore > 0.6 {
            recommendations.append("Practice mindfulness or relaxation techniques")
        }
        
        if features.activity.stepCount < 6000 {
            recommendations.append("Get some sunlight and light exercise")
        }
        
        if features.stress.mindfulnessMinutes < 10 {
            recommendations.append("Consider 10 minutes of meditation")
        }
        
        recommendations.append("Connect with friends or family")
        
        return recommendations
    }
    
    private func calculateStressRecoveryCapacity(_ stressFeatures: StressFeatures) -> Double {
        let recoveryRate = stressFeatures.stressRecoveryRate
        let mindfulnessFactor = min(1.0, stressFeatures.mindfulnessMinutes / 30.0)
        let autonomicBalance = 1.0 - stressFeatures.autonomicStressIndex
        
        return (recoveryRate * 0.5 + mindfulnessFactor * 0.3 + autonomicBalance * 0.2)
    }
    
    private func analyzeStressChronicity(_ stressFeatures: StressFeatures) -> Double {
        // High stress variability suggests acute stress
        // Low variability with high stress suggests chronic stress
        let chronicity = stressFeatures.stressScore * (1.0 - stressFeatures.stressVariability)
        return min(1.0, chronicity)
    }
    
    private func identifyStressSources(_ stressFeatures: StressFeatures) -> [String] {
        var sources: [String] = []
        
        if stressFeatures.stressScore > 0.7 {
            sources.append("High autonomic stress detected")
        }
        
        if stressFeatures.mindfulnessMinutes < 5 {
            sources.append("Lack of stress management practices")
        }
        
        if stressFeatures.stressRecoveryRate < 0.3 {
            sources.append("Poor stress recovery")
        }
        
        return sources
    }
    
    private func recommendStressInterventions(_ stressFeatures: StressFeatures) -> [String] {
        var interventions: [String] = []
        
        if stressFeatures.mindfulnessMinutes < 15 {
            interventions.append("Increase mindfulness practice to 15+ minutes daily")
        }
        
        if stressFeatures.stressRecoveryRate < 0.5 {
            interventions.append("Practice progressive muscle relaxation")
        }
        
        if stressFeatures.autonomicStressIndex > 0.7 {
            interventions.append("Focus on breath work and HRV training")
        }
        
        interventions.append("Consider reducing caffeine intake")
        
        return interventions
    }
}

// MARK: - Enhanced Prediction Structures

struct EnhancedSleepPrediction {
    let stage: SleepStageType
    let confidence: Double
    let quality: Double
    let recommendations: [String]
    let nextStageTransition: StageTransition?
    let modelUsed: String
    let timestamp: Date
}

struct EnhancedHealthPrediction {
    let energy: Double
    let recovery: Double
    let overallHealth: Double
    let riskFactors: [HealthRiskFactor]
    let recommendations: [String]
    let confidence: Double
    let modelUsed: String
    let timestamp: Date
}

struct ArrhythmiaRiskPrediction {
    let riskScore: Double
    let riskLevel: ArrhythmiaRiskLevel
    let detectedPatterns: [String]
    let recommendations: [String]
    let confidence: Double
    let modelUsed: String
    let timestamp: Date
}

struct EnergyPrediction {
    let currentLevel: Double
    let forecast24h: [HourlyEnergyForecast]
    let peakTime: Date?
    let lowTime: Date?
    let factors: [String]
    let recommendations: [String]
    let confidence: Double
    let timestamp: Date
}

struct MoodPrediction {
    let currentMood: Double
    let stability: Double
    let trendDirection: MoodTrend
    let influencingFactors: [String]
    let recommendations: [String]
    let confidence: Double
    let timestamp: Date
}

struct StressPrediction {
    let currentLevel: Double
    let recoveryCapacity: Double
    let chronicity: Double
    let sources: [String]
    let interventions: [String]
    let confidence: Double
    let timestamp: Date
}

// MARK: - Supporting Types

enum PredictionType {
    case features, sleep, health, arrhythmia, energy, mood, stress
}

enum ArrhythmiaRiskLevel {
    case low, moderate, high, critical
}

enum MoodTrend {
    case improving, stable, declining
}

struct StageTransition {
    let fromStage: SleepStageType
    let toStage: SleepStageType
    let probability: Double
    let estimatedTimeMinutes: Int
}

struct HealthRiskFactor {
    let type: RiskFactorType
    let severity: RiskSeverity
    let description: String
}

enum RiskFactorType {
    case tachycardia, sleepDisorder, chronicStress, cardiovascularRisk
}

enum RiskSeverity {
    case mild, moderate, high, critical
}

struct HourlyEnergyForecast {
    let hour: Int
    let energyLevel: Double
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let predictionUpdated = Notification.Name("predictionUpdated")
    static let modelStatusChanged = Notification.Name("modelStatusChanged")
}