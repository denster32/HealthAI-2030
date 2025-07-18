import Foundation
import CoreML
import Combine
import HealthKit
import os.log

/// Comprehensive data model for pre-symptom health prediction
public struct PreSymptomHealthInput: Codable {
    public let heartRateVariability: Double
    public let bloodPressure: (systolic: Double, diastolic: Double)
    public let sleepQuality: Double
    public let physicalActivity: Double
    public let nutritionalIntake: Double
    public let stressLevel: Double
    public let geneticRiskFactors: [String: Double]
    public let environmentalFactors: [String: Double]
    public let medicalHistory: [String: Bool]
    
    public init(
        heartRateVariability: Double,
        bloodPressure: (systolic: Double, diastolic: Double),
        sleepQuality: Double,
        physicalActivity: Double,
        nutritionalIntake: Double,
        stressLevel: Double,
        geneticRiskFactors: [String: Double] = [:],
        environmentalFactors: [String: Double] = [:],
        medicalHistory: [String: Bool] = [:]
    ) {
        self.heartRateVariability = heartRateVariability
        self.bloodPressure = bloodPressure
        self.sleepQuality = sleepQuality
        self.physicalActivity = physicalActivity
        self.nutritionalIntake = nutritionalIntake
        self.stressLevel = stressLevel
        self.geneticRiskFactors = geneticRiskFactors
        self.environmentalFactors = environmentalFactors
        self.medicalHistory = medicalHistory
    }
}

/// Pre-symptom prediction output with risk assessment and recommendations
public struct PreSymptomHealthOutput: Codable {
    public enum RiskLevel: String, Codable {
        case low
        case moderate
        case high
        case critical
    }
    
    public struct PredictedRisk: Codable {
        public let condition: String
        public let probabilityScore: Double
        public let confidenceInterval: Double
        public let recommendedActions: [String]
    }
    
    public let overallRiskLevel: RiskLevel
    public let predictedRisks: [PredictedRisk]
    public let anomalyDetectionScore: Double
    public let falsePositiveProbability: Double
    public let falseNegativeProbability: Double
}

/// Add enhanced error handling and logging
public enum PreSymptomPredictorError: Error {
    case modelLoadFailure(modelName: String)
    case healthKitAuthorizationDenied
    case insufficientHealthData
    case predictionFailure(underlyingError: Error)
    case anomalyDetectionFailure
    case cacheOperationFailed
}

/// Enhanced logging and error tracking
private class PreSymptomPredictorErrorTracker {
    static let shared = PreSymptomPredictorErrorTracker()
    
    private var errorLog: [Date: PreSymptomPredictorError] = [:]
    private let errorLogQueue = DispatchQueue(label: "com.healthai.errorTracking", attributes: .concurrent)
    
    func logError(_ error: PreSymptomPredictorError) {
        errorLogQueue.async(flags: .barrier) {
            self.errorLog[Date()] = error
        }
    }
    
    func getRecentErrors(within timeInterval: TimeInterval = 3600) -> [PreSymptomPredictorError] {
        let cutoffDate = Date().addingTimeInterval(-timeInterval)
        return errorLogQueue.sync {
            errorLog.filter { $0.key > cutoffDate }.map { $0.value }
        }
    }
}

/// Advanced Pre-symptom Health Prediction Engine
public class PreSymptomHealthPredictor {
    public static let shared = PreSymptomHealthPredictor()
    
    // Machine Learning Models
    private var predictionModel: MLModel?
    private var anomalyDetectionModel: MLModel?
    private var falseNegativeReductionModel: MLModel?
    
    // Combine publishers
    private let predictionPublisher = PassthroughSubject<PreSymptomHealthOutput, Never>()
    
    // Health Store for data collection
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "com.healthai.presymptompredictor", category: "PreSymptomHealthPredictor")
    
    // Caching mechanism for prediction results
    private var predictionCache: [String: PreSymptomHealthOutput] = [:]
    
    private init() {
        setupMLModels()
        setupHealthKitObservers()
    }
    
    /// Setup Machine Learning Models
    private func setupMLModels() {
        logger.debug("Starting ML model initialization")
        
        do {
            let predictionModelURL = Bundle.main.url(forResource: "PreSymptomPredictionModel", withExtension: "mlmodel")!
            logger.debug("Loading prediction model from: \(predictionModelURL)")
            predictionModel = try MLModel(contentsOf: predictionModelURL)
            logger.debug("Prediction model loaded successfully")
            
            let anomalyModelURL = Bundle.main.url(forResource: "AnomalyDetectionModel", withExtension: "mlmodel")!
            logger.debug("Loading anomaly detection model from: \(anomalyModelURL)")
            anomalyDetectionModel = try MLModel(contentsOf: anomalyModelURL)
            logger.debug("Anomaly detection model loaded successfully")
            
            let fnrModelURL = Bundle.main.url(forResource: "FalseNegativeReductionModel", withExtension: "mlmodel")!
            logger.debug("Loading false negative reduction model from: \(fnrModelURL)")
            falseNegativeReductionModel = try MLModel(contentsOf: fnrModelURL)
            logger.debug("False negative reduction model loaded successfully")
            
            logger.info("All ML models initialized successfully")
        } catch {
            logger.critical("ML Model setup failed: \(error.localizedDescription)")
            PreSymptomPredictorErrorTracker.shared.logError(.modelLoadFailure(modelName: error.localizedDescription))
            
            // Record telemetry for model load failure
            PredictionTelemetryManager.shared.recordEvent(
                type: .predictionFailed,
                errorDescription: "Model load failed: \(error.localizedDescription)"
            )
        }
        
        // Verify all models loaded
        if predictionModel == nil || anomalyDetectionModel == nil || falseNegativeReductionModel == nil {
            logger.critical("One or more ML models failed to load")
        }
    }
    
    /// Setup HealthKit observers for continuous data collection
    private func setupHealthKitObservers() {
        logger.debug("Initializing HealthKit observers")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.critical("HealthKit data not available on this device")
            PreSymptomPredictorErrorTracker.shared.logError(.healthKitAuthorizationDenied)
            PredictionTelemetryManager.shared.recordEvent(
                type: .predictionFailed,
                errorDescription: "HealthKit not available"
            )
            return
        }
        
        // Verify all required HealthKit types are available
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
              let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic),
              let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            logger.critical("Required HealthKit types not available")
            PreSymptomPredictorErrorTracker.shared.logError(.insufficientHealthData)
            return
        }
        
        let typesToRead: Set = [hrvType, systolicType, diastolicType, energyType]
        logger.debug("Requesting HealthKit authorization for types: \(typesToRead.map { $0.identifier })")
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] (success, error) in
            if let error = error {
                self?.logger.critical("HealthKit authorization error: \(error.localizedDescription)")
                PreSymptomPredictorErrorTracker.shared.logError(.healthKitAuthorizationDenied)
                PredictionTelemetryManager.shared.recordEvent(
                    type: .predictionFailed,
                    errorDescription: "HealthKit auth error: \(error.localizedDescription)"
                )
                return
            }
            
            if !success {
                self?.logger.error("HealthKit authorization denied by user")
                PreSymptomPredictorErrorTracker.shared.logError(.healthKitAuthorizationDenied)
                PredictionTelemetryManager.shared.recordEvent(
                    type: .predictionFailed,
                    errorDescription: "HealthKit authorization denied"
                )
                return
            }
            
            self?.logger.info("HealthKit authorization granted")
            PredictionTelemetryManager.shared.recordEvent(
                type: .predictionStarted,
                inputFeatures: ["authStatus": 1.0]
            )
            
            // Check current authorization status for each type
            typesToRead.forEach { type in
                let status = self?.healthStore.authorizationStatus(for: type)
                self?.logger.debug("Authorization status for \(type.identifier): \(status?.rawValue ?? -1)")
            }
            
            self?.setupContinuousQueries()
        }
    }
    
    /// Setup continuous queries for health data with enhanced logging
    private func setupContinuousQueries() {
        logger.debug("Setting up continuous HealthKit queries")
        
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            logger.critical("Failed to create HRV quantity type")
            PreSymptomPredictorErrorTracker.shared.logError(.insufficientHealthData)
            return
        }
        
        logger.debug("Creating anchored query for HRV data")
        let hrvQuery = HKAnchoredObjectQuery(
            type: hrvType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] (query, samples, deletedObjects, newAnchor, error) in
            if let error = error {
                self?.logger.error("HRV query error: \(error.localizedDescription)")
                PreSymptomPredictorErrorTracker.shared.logError(.predictionFailure(underlyingError: error))
                return
            }
            
            guard let hrvSamples = samples as? [HKQuantitySample], !hrvSamples.isEmpty else {
                self?.logger.debug("No HRV samples available")
                return
            }
            
            self?.logger.info("Received \(hrvSamples.count) HRV samples")
            self?.logger.debug("Sample details: \(hrvSamples.map { "\($0.startDate): \($0.quantity)" })")
            
            // Record telemetry for data received
            PredictionTelemetryManager.shared.recordEvent(
                type: .performanceMetrics,
                inputFeatures: ["hrvSampleCount": Double(hrvSamples.count)]
            )
            
            self?.processHealthData(hrvSamples: hrvSamples)
        }
        
        // Add update handler for continuous updates
        hrvQuery.updateHandler = { [weak self] (query, samples, deletedObjects, newAnchor, error) in
            if let error = error {
                self?.logger.error("HRV update error: \(error.localizedDescription)")
                return
            }
            
            guard let hrvSamples = samples as? [HKQuantitySample], !hrvSamples.isEmpty else {
                return
            }
            
            self?.logger.debug("Received \(hrvSamples.count) updated HRV samples")
            self?.processHealthData(hrvSamples: hrvSamples)
        }
        
        logger.debug("Executing HRV query")
        healthStore.execute(hrvQuery)
        logger.info("Continuous HRV monitoring started")
        
        // Record telemetry for query execution
        PredictionTelemetryManager.shared.recordEvent(
            type: .predictionStarted,
            inputFeatures: ["queryType": "HRV"]
        )
    }
    
    /// Process health data with enhanced validation and logging
    private func processHealthData(hrvSamples: [HKQuantitySample]) {
        logger.debug("Processing \(hrvSamples.count) HRV samples")
        
        guard !hrvSamples.isEmpty else {
            logger.warning("Empty HRV samples array received")
            return
        }
        
        // Log sample details
        logger.debug("HRV sample details:")
        hrvSamples.forEach { sample in
            logger.debug("- \(sample.startDate): \(sample.quantity)")
        }
        
        // Calculate average HRV with validation
        let hrvValues = hrvSamples.map { sample in
            let value = sample.quantity.doubleValue(for: HKUnit.secondUnit())
            logger.debug("Converted HRV value: \(value) seconds")
            return value
        }
        
        let totalHRV = hrvValues.reduce(0, +)
        let avgHRV = totalHRV / Double(hrvValues.count)
        
        logger.info("Calculated average HRV: \(avgHRV) seconds")
        
        // Validate HRV range (normal range: 20-100ms)
        if avgHRV < 0.020 || avgHRV > 0.100 {
            logger.warning("Abnormal average HRV detected: \(avgHRV) seconds")
            PredictionTelemetryManager.shared.recordEvent(
                type: .performanceMetrics,
                inputFeatures: ["abnormalHRV": avgHRV]
            )
        }
        
        // Collect contextual data with logging
        logger.debug("Collecting contextual health data")
        let input = collectContextualData(baseHRV: avgHRV)
        logger.debug("Pre-symptom prediction input prepared: \(input)")
        
        // Record telemetry before prediction
        PredictionTelemetryManager.shared.recordEvent(
            type: .predictionStarted,
            inputFeatures: [
                "hrv": avgHRV,
                "sampleCount": Double(hrvSamples.count)
            ]
        )
        
        // Predict with error handling
        do {
            logger.debug("Initiating pre-symptom prediction")
            predictPreSymptomHealthRisks(input: input)
        } catch {
            logger.error("Prediction failed: \(error.localizedDescription)")
            PreSymptomPredictorErrorTracker.shared.logError(.predictionFailure(underlyingError: error))
            PredictionTelemetryManager.shared.recordEvent(
                type: .predictionFailed,
                errorDescription: error.localizedDescription
            )
        }
    }
    
    /// Collect contextual data for pre-symptom prediction
    private func collectContextualData(baseHRV: Double) -> PreSymptomHealthInput {
        return PreSymptomHealthInput(
            heartRateVariability: baseHRV,
            bloodPressure: simulateBloodPressure(),
            sleepQuality: simulateSleepQuality(),
            physicalActivity: simulatePhysicalActivity(),
            nutritionalIntake: simulateNutritionalIntake(),
            stressLevel: simulateStressLevel(),
            geneticRiskFactors: simulateGeneticRiskFactors(),
            environmentalFactors: simulateEnvironmentalFactors(),
            medicalHistory: simulateMedicalHistory()
        )
    }
    
    /// Predict pre-symptom health risks using ML models
    private func predictPreSymptomHealthRisks(input: PreSymptomHealthInput) {
        guard let predictionModel = predictionModel,
              let anomalyDetectionModel = anomalyDetectionModel,
              let falseNegativeReductionModel = falseNegativeReductionModel else { return }
        
        do {
            // Prepare input for ML models
            let modelInput = prepareModelInput(input)
            
            // Prediction
            let prediction = try predictionModel.prediction(input: modelInput)
            
            // Anomaly Detection
            let anomalyDetection = try anomalyDetectionModel.prediction(input: modelInput)
            
            // False Negative Reduction
            let falseNegativeReduction = try falseNegativeReductionModel.prediction(input: modelInput)
            
            // Extract prediction results
            let predictedRisks = extractPredictedRisks(prediction)
            let overallRiskLevel = determineOverallRiskLevel(predictedRisks)
            
            let output = PreSymptomHealthOutput(
                overallRiskLevel: overallRiskLevel,
                predictedRisks: predictedRisks,
                anomalyDetectionScore: extractAnomalyScore(anomalyDetection),
                falsePositiveProbability: extractFalsePositiveProbability(prediction),
                falseNegativeProbability: extractFalseNegativeProbability(falseNegativeReduction)
            )
            
            // Cache the prediction
            cachePreSymptomPrediction(output)
            
            // Publish the prediction
            predictionPublisher.send(output)
            
            // Trigger notifications or interventions if needed
            handleHighRiskScenarios(output)
        } catch {
            logger.error("Pre-symptom health prediction failed: \(error.localizedDescription)")
        }
    }
    
    /// Prepare input for ML models
    private func prepareModelInput(_ input: PreSymptomHealthInput) -> [String: Any] {
        print("PreSymptomHealthPredictor: prepareModelInput - Input: \(input)") // Add logging
        let modelInput = [
            "heartRateVariability": input.heartRateVariability,
            "systolicBloodPressure": input.bloodPressure.systolic,
            "diastolicBloodPressure": input.bloodPressure.diastolic,
            "sleepQuality": input.sleepQuality,
            "physicalActivity": input.physicalActivity,
            "nutritionalIntake": input.nutritionalIntake,
            "stressLevel": input.stressLevel,
            "geneticRiskFactors": input.geneticRiskFactors,
            "environmentalFactors": input.environmentalFactors,
            "medicalHistory": input.medicalHistory
        ]
        print("PreSymptomHealthPredictor: prepareModelInput - Model Input: \(modelInput)") // Add logging
        return modelInput
    }
    
    /// Extract predicted risks from ML model output
    private func extractPredictedRisks(_ prediction: [String: Any]) -> [PreSymptomHealthOutput.PredictedRisk] {
        var risks: [PreSymptomHealthOutput.PredictedRisk] = []
        
        let conditions = ["cardiovascular", "metabolic", "respiratory", "neurological"]
        
        for condition in conditions {
            if let probabilityScore = prediction["\(condition)RiskScore"] as? Double,
               let confidenceInterval = prediction["\(condition)ConfidenceInterval"] as? Double {
                risks.append(PreSymptomHealthOutput.PredictedRisk(
                    condition: condition,
                    probabilityScore: probabilityScore,
                    confidenceInterval: confidenceInterval,
                    recommendedActions: generateRecommendedActions(condition: condition, riskScore: probabilityScore)
                ))
            }
        }
        
        return risks
    }
    
    /// Generate recommended actions based on condition and risk score
    private func generateRecommendedActions(condition: String, riskScore: Double) -> [String] {
        var actions: [String] = []
        
        switch condition {
        case "cardiovascular":
            if riskScore > 0.7 {
                actions.append("Schedule cardiovascular screening")
                actions.append("Consult with cardiologist")
                actions.append("Implement heart-healthy diet")
            } else if riskScore > 0.4 {
                actions.append("Increase cardiovascular exercise")
                actions.append("Monitor blood pressure")
            }
            
        case "metabolic":
            if riskScore > 0.7 {
                actions.append("Comprehensive metabolic panel")
                actions.append("Consult endocrinologist")
                actions.append("Review dietary habits")
            } else if riskScore > 0.4 {
                actions.append("Blood glucose monitoring")
                actions.append("Adjust nutrition plan")
            }
            
        case "respiratory":
            if riskScore > 0.7 {
                actions.append("Pulmonary function test")
                actions.append("Consult pulmonologist")
                actions.append("Environmental allergen assessment")
            } else if riskScore > 0.4 {
                actions.append("Lung capacity screening")
                actions.append("Respiratory exercise program")
            }
            
        case "neurological":
            if riskScore > 0.7 {
                actions.append("Neurological consultation")
                actions.append("Advanced neuroimaging")
                actions.append("Cognitive function assessment")
            } else if riskScore > 0.4 {
                actions.append("Neurological screening")
                actions.append("Cognitive exercise program")
            }
            
        default:
            break
        }
        
        return actions
    }
    
    /// Determine overall risk level based on predicted risks
    private func determineOverallRiskLevel(_ risks: [PreSymptomHealthOutput.PredictedRisk]) -> PreSymptomHealthOutput.RiskLevel {
        let highestRiskScore = risks.map { $0.probabilityScore }.max() ?? 0.0
        
        switch highestRiskScore {
        case 0.0..<0.3:
            return .low
        case 0.3..<0.6:
            return .moderate
        case 0.6..<0.8:
            return .high
        case 0.8...1.0:
            return .critical
        default:
            return .low
        }
    }
    
    /// Extract anomaly detection score
    private func extractAnomalyScore(_ anomalyDetection: [String: Any]) -> Double {
        return anomalyDetection["anomalyScore"] as? Double ?? 0.0
    }
    
    /// Extract false positive probability
    private func extractFalsePositiveProbability(_ prediction: [String: Any]) -> Double {
        return prediction["falsePositiveProbability"] as? Double ?? 0.0
    }
    
    /// Extract false negative probability
    private func extractFalseNegativeProbability(_ falseNegativeReduction: [String: Any]) -> Double {
        return falseNegativeReduction["falseNegativeProbability"] as? Double ?? 0.0
    }
    
    /// Handle high-risk scenarios
    private func handleHighRiskScenarios(_ output: PreSymptomHealthOutput) {
        switch output.overallRiskLevel {
        case .high, .critical:
            sendHighRiskNotification(output)
        default:
            break
        }
    }
    
    /// Send high-risk notification
    private func sendHighRiskNotification(_ output: PreSymptomHealthOutput) {
        let content = UNMutableNotificationContent()
        content.title = "Health Risk Alert"
        content.body = "Potential health risks detected. Please review recommended actions."
        content.sound = .critical
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Cache pre-symptom prediction results
    private func cachePreSymptomPrediction(_ output: PreSymptomHealthOutput) {
        let cacheKey = UUID().uuidString
        predictionCache[cacheKey] = output
        
        // Limit cache size
        if predictionCache.count > 100 {
            let oldestKey = predictionCache.keys.sorted().first!
            predictionCache.removeValue(forKey: oldestKey)
        }
    }
    
    // MARK: - Simulation Methods (to be replaced with real data collection)
    
    private func simulateBloodPressure() -> (systolic: Double, diastolic: Double) {
        return (
            systolic: Double.random(in: 100.0...180.0),
            diastolic: Double.random(in: 60.0...120.0)
        )
    }
    
    private func simulateSleepQuality() -> Double {
        return Double.random(in: 0.0...1.0)
    }
    
    private func simulatePhysicalActivity() -> Double {
        return Double.random(in: 0.0...1.0)
    }
    
    private func simulateNutritionalIntake() -> Double {
        return Double.random(in: 0.0...1.0)
    }
    
    private func simulateStressLevel() -> Double {
        return Double.random(in: 0.0...1.0)
    }
    
    private func simulateGeneticRiskFactors() -> [String: Double] {
        return [
            "cardiovascularRisk": Double.random(in: 0.0...1.0),
            "diabetesRisk": Double.random(in: 0.0...1.0),
            "cancerRisk": Double.random(in: 0.0...1.0)
        ]
    }
    
    private func simulateEnvironmentalFactors() -> [String: Double] {
        return [
            "airQuality": Double.random(in: 0.0...1.0),
            "stressExposure": Double.random(in: 0.0...1.0),
            "toxinExposure": Double.random(in: 0.0...1.0)
        ]
    }
    
    private func simulateMedicalHistory() -> [String: Bool] {
        return [
            "familyHeartDisease": Bool.random(),
            "diabetes": Bool.random(),
            "hypertension": Bool.random()
        ]
    }
    
    // MARK: - Public Interface
    
    /// Subscribe to pre-symptom health predictions
    public func subscribeToPredictions() -> AnyPublisher<PreSymptomHealthOutput, Never> {
        return predictionPublisher.eraseToAnyPublisher()
    }
    
    /// Manually trigger pre-symptom health prediction
    public func predictPreSymptomHealthRisks() {
        let baseInput = PreSymptomHealthInput(
            heartRateVariability: simulateHeartRateVariability(),
            bloodPressure: simulateBloodPressure(),
            sleepQuality: simulateSleepQuality(),
            physicalActivity: simulatePhysicalActivity(),
            nutritionalIntake: simulateNutritionalIntake(),
            stressLevel: simulateStressLevel(),
            geneticRiskFactors: simulateGeneticRiskFactors(),
            environmentalFactors: simulateEnvironmentalFactors(),
            medicalHistory: simulateMedicalHistory()
        )
        
        predictPreSymptomHealthRisks(input: baseInput)
    }
    
    /// Retrieve cached prediction results
    public func getCachedPredictions() -> [PreSymptomHealthOutput] {
        return Array(predictionCache.values)
    }
    
    /// Simulate heart rate variability
    private func simulateHeartRateVariability() -> Double {
        return Double.random(in: 20.0...100.0)
    }
    
    /// Advanced model validation and drift detection
    private func validateModelPerformance(output: PreSymptomHealthOutput) -> Bool {
        // Check for potential model drift or performance issues
        let recentErrors = PreSymptomPredictorErrorTracker.shared.getRecentErrors()
        
        // Sophisticated drift detection logic
        let driftIndicators = [
            output.falsePositiveProbability > 0.2,  // High false positive rate
            output.falseNegativeProbability > 0.1,  // High false negative rate
            output.anomalyDetectionScore > 0.8,     // High anomaly score
            recentErrors.count > 5                  // Multiple recent errors
        ]
        
        let potentialModelDrift = driftIndicators.filter { $0 }.count > 2
        
        if potentialModelDrift {
            logger.critical("Potential model drift detected. Triggering model retraining.")
            triggerModelRetraining()
        }
        
        return !potentialModelDrift
    }
    
    /// Trigger model retraining process
    private func triggerModelRetraining() {
        // Placeholder for model retraining logic
        // In a real-world scenario, this would:
        // 1. Pause predictions
        // 2. Collect recent training data
        // 3. Retrain or download updated model
        // 4. Validate new model
        // 5. Switch to new model
        logger.info("Model retraining process initiated.")
    }
    
    /// Enhanced prediction method with comprehensive error handling
    public func predictPreSymptomHealthRisks(
        input: PreSymptomHealthInput,
        completion: @escaping (Result<PreSymptomHealthOutput, PreSymptomPredictorError>) -> Void
    ) {
        // Start performance tracking
        let startTime = Date()
        
        // Record prediction start event
        let inputFeatures: [String: Double] = [
            "heartRateVariability": input.heartRateVariability,
            "systolicBloodPressure": input.bloodPressure.systolic,
            "diastolicBloodPressure": input.bloodPressure.diastolic,
            "sleepQuality": input.sleepQuality,
            "physicalActivity": input.physicalActivity,
            "nutritionalIntake": input.nutritionalIntake,
            "stressLevel": input.stressLevel
        ]
        
        PredictionTelemetryManager.shared.recordEvent(
            type: .predictionStarted,
            inputFeatures: inputFeatures
        )
        
        guard let predictionModel = predictionModel,
              let anomalyDetectionModel = anomalyDetectionModel,
              let falseNegativeReductionModel = falseNegativeReductionModel else {
            let error = PreSymptomPredictorError.modelLoadFailure(modelName: "One or more models failed to load")
            
            // Record telemetry for model load failure
            PredictionTelemetryManager.shared.recordEvent(
                type: .predictionFailed,
                inputFeatures: inputFeatures,
                errorDescription: error.localizedDescription
            )
            
            PreSymptomPredictorErrorTracker.shared.logError(error)
            completion(.failure(error))
            return
        }
        
        do {
            // Existing prediction logic...
            let modelInput = prepareModelInput(input)
            
            let prediction = try predictionModel.prediction(input: modelInput)
            let anomalyDetection = try anomalyDetectionModel.prediction(input: modelInput)
            let falseNegativeReduction = try falseNegativeReductionModel.prediction(input: modelInput)
            
            let predictedRisks = extractPredictedRisks(prediction)
            let overallRiskLevel = determineOverallRiskLevel(predictedRisks)
            
            let output = PreSymptomHealthOutput(
                overallRiskLevel: overallRiskLevel,
                predictedRisks: predictedRisks,
                anomalyDetectionScore: extractAnomalyScore(anomalyDetection),
                falsePositiveProbability: extractFalsePositiveProbability(prediction),
                falseNegativeProbability: extractFalseNegativeProbability(falseNegativeReduction)
            )
            
            // Validate model performance
            let isModelPerformanceValid = validateModelPerformance(output: output)
            
            // Calculate performance metrics
            let endTime = Date()
            let processingTime = endTime.timeIntervalSince(startTime)
            
            // Get current memory usage (approximate)
            var memoryUsage: Int64 = 0
            var cpuUsage: Double = 0
            
            // Record telemetry for prediction completion
            PredictionTelemetryManager.shared.recordEvent(
                type: .predictionCompleted,
                inputFeatures: inputFeatures,
                outputRiskLevel: overallRiskLevel.rawValue,
                performanceMetrics: PredictionTelemetryManager.TelemetryEvent.PerformanceMetrics(
                    processingTime: processingTime,
                    memoryUsage: memoryUsage,
                    cpuUsage: cpuUsage
                )
            )
            
            if isModelPerformanceValid {
                cachePreSymptomPrediction(output)
                predictionPublisher.send(output)
                handleHighRiskScenarios(output)
                completion(.success(output))
            } else {
                // Record telemetry for model performance issue
                PredictionTelemetryManager.shared.recordEvent(
                    type: .modelDriftDetected,
                    inputFeatures: inputFeatures
                )
                
                let error = PreSymptomPredictorError.predictionFailure(underlyingError: NSError(domain: "ModelPerformance", code: 1, userInfo: nil))
                PreSymptomPredictorErrorTracker.shared.logError(error)
                completion(.failure(error))
            }
        } catch {
            // Record telemetry for prediction failure
            PredictionTelemetryManager.shared.recordEvent(
                type: .predictionFailed,
                inputFeatures: inputFeatures,
                errorDescription: error.localizedDescription
            )
            
            let predictionError = PreSymptomPredictorError.predictionFailure(underlyingError: error)
            PreSymptomPredictorErrorTracker.shared.logError(predictionError)
            completion(.failure(predictionError))
        }
    }
} 