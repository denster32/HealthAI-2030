import Foundation
import HealthKit
import CoreMotion
import Combine
import CoreML
import os.log
@_exported import class HealthAI_2030.HealthData

@available(iOS 17.0, *)
@available(macOS 14.0, *)

class HealthDataManager: ObservableObject {
    static let shared = HealthDataManager()
    
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager() // Initialize CoreMotion Manager
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties for SwiftUI
    @Published var currentHeartRate: Double = 0
    @Published var currentHRV: Double = 0
    @Published var currentOxygenSaturation: Double = 0
    @Published var currentBodyTemperature: Double = 0
    @Published var sleepData: [HKCategorySample] = []
    @Published var stepCount: Int = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var rawSensorData: [SensorSample] = [] // Property for raw sensor data
    @Published var latestAccelerometerData: CMAccelerometerData? // New property for accelerometer data
    
    // Health metrics
    @Published var dailyMetrics: DailyHealthMetrics = DailyHealthMetrics()
    @Published var weeklyTrends: WeeklyHealthTrends = WeeklyHealthTrends()
    @Published var currentSleepFeatures: SleepFeatures? // New property for extracted features
    @Published var predictedSleepStage: String? // New property for sleep stage prediction
    
    private let sleepFeatureExtractor = SleepFeatureExtractor()
    private let coreMLIntegrationManager = CoreMLIntegrationManager.shared
    private let federatedLearningManager = FederatedLearningManager.shared

    private init() {
        requestHealthKitAuthorization { [weak self] success in
            if success {
                self?.setupHealthKitObservers()
                self?.startDataCollection()
            } else {
                print("HealthKit authorization failed. Cannot collect health data.")
            }
        }
    }
    
    func refreshData() {
        fetchCurrentHealthData()
        fetchDailyMetrics()
        fetchWeeklyTrends()
    }
    
    // MARK: - HealthKit Authorization
    func requestHealthKitAuthorization(completion: @escaping (Bool) -> Void) {
        let healthKitTypesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .walkingSpeed)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)! // Add dietary water for logging
        ]
        
        let healthKitTypesToWrite: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)! // Allow writing dietary water
        ]
        
        healthStore.requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) { success, error in
            if let error = error {
                print("HealthKit Authorization Error: \(error.localizedDescription)")
            }
            completion(success)
        }
    }
    
    private func setupHealthKitObservers() {
        // Setup real-time observers for health data
        setupHeartRateObserver()
        setupHRVObserver()
        setupOxygenSaturationObserver()
        setupBodyTemperatureObserver()
        setupSleepObserver()
        setupStepCountObserver()
        setupActiveEnergyObserver()
        setupMovementObserver()
    }
    
    private func setupHeartRateObserver() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateSamples(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func setupHRVObserver() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let query = HKAnchoredObjectQuery(type: hrvType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHRVSamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHRVSamples(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func setupOxygenSaturationObserver() {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let query = HKAnchoredObjectQuery(type: oxygenType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processOxygenSamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processOxygenSamples(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func setupBodyTemperatureObserver() {
        guard let temperatureType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) else { return }
        
        let query = HKAnchoredObjectQuery(type: temperatureType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processTemperatureSamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processTemperatureSamples(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func setupSleepObserver() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let query = HKAnchoredObjectQuery(type: sleepType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processSleepSamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processSleepSamples(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func setupStepCountObserver() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let query = HKAnchoredObjectQuery(type: stepType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processStepSamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processStepSamples(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func setupActiveEnergyObserver() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let query = HKAnchoredObjectQuery(type: energyType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processEnergySamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processEnergySamples(samples)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Data Processing Methods
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            let newSensorSamples = samples.map { sample in
                SensorSample(type: .heartRate, value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")), unit: "count/min", timestamp: sample.endDate)
            }
            self.rawSensorData.append(contentsOf: newSensorSamples)
            if let latestSample = samples.last {
                self.currentHeartRate = latestSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
        }
    }
    
    private func processHRVSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            let newSensorSamples = samples.map { sample in
                SensorSample(type: .heartRateVariabilitySDNN, value: sample.quantity.doubleValue(for: HKUnit(from: "ms")), unit: "ms", timestamp: sample.endDate)
            }
            self.rawSensorData.append(contentsOf: newSensorSamples)
            if let latestSample = samples.last {
                self.currentHRV = latestSample.quantity.doubleValue(for: HKUnit(from: "ms"))
            }
        }
    }
    
    private func processOxygenSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            let newSensorSamples = samples.map { sample in
                SensorSample(type: .oxygenSaturation, value: sample.quantity.doubleValue(for: HKUnit.percent()), unit: "%", timestamp: sample.endDate)
            }
            self.rawSensorData.append(contentsOf: newSensorSamples)
            if let latestSample = samples.last {
                self.currentOxygenSaturation = latestSample.quantity.doubleValue(for: HKUnit.percent())
            }
        }
    }
    
    private func processTemperatureSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            let newSensorSamples = samples.map { sample in
                SensorSample(type: .bodyTemperature, value: sample.quantity.doubleValue(for: HKUnit.degreeCelsius()), unit: "degC", timestamp: sample.endDate)
            }
            self.rawSensorData.append(contentsOf: newSensorSamples)
            if let latestSample = samples.last {
                self.currentBodyTemperature = latestSample.quantity.doubleValue(for: HKUnit.degreeCelsius())
            }
        }
    }
    
    private func processSleepSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKCategorySample] else { return }
        
        DispatchQueue.main.async {
            self.sleepData = samples
            
            // Enhanced real-time processing with predictive analytics
            self.performAdvancedSleepProcessing()
        }
    }
    
    private func performAdvancedSleepProcessing() {
        // Extract enhanced sleep features
        self.currentSleepFeatures = self.sleepFeatureExtractor.extractFeatures(from: self.rawSensorData)
        
        guard let features = self.currentSleepFeatures else { return }
        
        // Perform real-time ML prediction with production models
        let sleepPrediction = self.coreMLIntegrationManager.predictSleepStage(from: self.rawSensorData)
        self.predictedSleepStage = sleepPrediction.stage.rawValue
        
        // Enhanced: Perform real-time health risk assessment
        self.performRealtimeHealthRiskAssessment(features: features, prediction: sleepPrediction)
        
        // Enhanced: Trigger predictive interventions if needed
        self.triggerPredictiveInterventions(features: features, prediction: sleepPrediction)
        
        // Enhanced: Update federated learning with high-quality features
        if self.federatedLearningManager.isEnabled() && sleepPrediction.confidence > 0.7 {
            self.federatedLearningManager.generateLocalModelUpdate(with: features.toArray().map { String($0) })
        }
        
        // Enhanced: Real-time data streaming for continuous monitoring
        self.updateContinuousMonitoring(features: features, prediction: sleepPrediction)
        
        // Clear processed data
        self.rawSensorData.removeAll()
        
        // Save enhanced data to Core Data
        self.saveEnhancedHealthData(features: features, prediction: sleepPrediction)
    }
    
    private func performRealtimeHealthRiskAssessment(features: SleepFeatures, prediction: SleepPredictionResult) {
        var riskLevel: HealthRiskLevel = .low
        var riskFactors: [String] = []
        
        // Real-time cardiovascular risk assessment
        if features.heartRateAverage > 85 {
            riskLevel = .elevated
            riskFactors.append("Elevated heart rate during sleep: \(Int(features.heartRateAverage)) BPM")
        }
        
        // Real-time respiratory risk assessment
        if features.oxygenSaturationAverage < 95 {
            riskLevel = max(riskLevel, .high)
            riskFactors.append("Low oxygen saturation: \(Int(features.oxygenSaturationAverage))%")
        }
        
        if features.oxygenSaturationAverage < 90 {
            riskLevel = .critical
            riskFactors.append("Critical oxygen saturation: \(Int(features.oxygenSaturationAverage))%")
        }
        
        // Real-time autonomic nervous system assessment
        if features.heartRateVariability < 20 {
            riskLevel = max(riskLevel, .elevated)
            riskFactors.append("Low HRV indicating stress/fatigue: \(Int(features.heartRateVariability))ms")
        }
        
        // Real-time temperature regulation assessment
        if features.wristTemperatureAverage < 35.5 || features.wristTemperatureAverage > 38.5 {
            riskLevel = max(riskLevel, .elevated)
            riskFactors.append("Temperature dysregulation: \(String(format: "%.1f", features.wristTemperatureAverage))°C")
        }
        
        // Real-time sleep architecture assessment
        if prediction.confidence < 0.5 {
            riskLevel = max(riskLevel, .elevated)
            riskFactors.append("Poor sleep stage classification confidence")
        }
        
        // Store risk assessment
        let riskAssessment = RealtimeHealthRiskAssessment(
            level: riskLevel,
            factors: riskFactors,
            timestamp: Date(),
            confidence: prediction.confidence
        )
        
        // Trigger immediate alerts for high/critical risks
        if riskLevel >= .high {
            self.triggerImmediateHealthAlert(assessment: riskAssessment)
        }
        
        // Post notification for background processing
        NotificationCenter.default.post(
            name: .realtimeHealthRiskAssessed,
            object: riskAssessment
        )
    }
    
    private func triggerPredictiveInterventions(features: SleepFeatures, prediction: SleepPredictionResult) {
        var interventions: [PredictiveIntervention] = []
        
        // Smart environment interventions
        if features.heartRateAverage > 80 && prediction.stage.rawValue != "awake" {
            interventions.append(PredictiveIntervention(
                type: .environmentalAdjustment,
                description: "Reduce room temperature to lower heart rate",
                urgency: .withinMinutes,
                expectedBenefit: 0.3
            ))
        }
        
        // Audio therapy interventions
        if features.heartRateVariability < 25 && prediction.stage.rawValue == "lightSleep" {
            interventions.append(PredictiveIntervention(
                type: .audioTherapy,
                description: "Initiate HRV coherence audio guidance",
                urgency: .immediate,
                expectedBenefit: 0.4
            ))
        }
        
        // Movement-based interventions
        if features.activityCount > 30 && prediction.stage.rawValue != "awake" {
            interventions.append(PredictiveIntervention(
                type: .environmentalAdjustment,
                description: "Activate white noise to reduce disturbances",
                urgency: .immediate,
                expectedBenefit: 0.25
            ))
        }
        
        // Smart alarm interventions
        let timeUntilMorning = calculateTimeUntilMorning()
        if timeUntilMorning < 7200 && prediction.stage.rawValue == "lightSleep" { // 2 hours until morning
            interventions.append(PredictiveIntervention(
                type: .smartAlarmOptimization,
                description: "Optimize wake window for natural awakening",
                urgency: .scheduled,
                expectedBenefit: 0.5
            ))
        }
        
        // Execute interventions
        for intervention in interventions {
            self.executeRealtimeIntervention(intervention)
        }
        
        if !interventions.isEmpty {
            print("HealthDataManager: Executed \(interventions.count) predictive interventions")
        }
    }
    
    private func updateContinuousMonitoring(features: SleepFeatures, prediction: SleepPredictionResult) {
        // Update continuous monitoring stream for Apple Watch and other devices
        let monitoringData = ContinuousMonitoringData(
            heartRate: features.heartRateAverage,
            hrv: features.heartRateVariability,
            oxygenSaturation: features.spo2Average,
            sleepStage: prediction.stage.rawValue,
            confidence: prediction.confidence,
            timestamp: Date()
        )
        
        // Send to Apple Watch via Watch Connectivity
        if let watchManager = AppleWatchManager.shared {
            watchManager.sendContinuousMonitoringData(monitoringData)
        }
        
        // Update live activities on iPhone
        if let liveActivityManager = HealthLiveActivity.shared {
            liveActivityManager.updateSleepMonitoring(data: monitoringData)
        }
        
        // Stream to health dashboard
        NotificationCenter.default.post(
            name: .continuousMonitoringDataUpdated,
            object: monitoringData
        )
    }
    
    private func executeRealtimeIntervention(_ intervention: PredictiveIntervention) {
        switch intervention.type {
        case .environmentalAdjustment:
            // Trigger smart home adjustments
            if let smartHomeManager = SmartHomeManager.shared {
                Task {
                    await smartHomeManager.executeRealtimeAdjustment(intervention)
                }
            }
            
        case .audioTherapy:
            // Start immediate audio therapy
            if let audioEngine = EnhancedAudioEngine.shared {
                Task {
                    await audioEngine.startRealtimeAudioTherapy(intervention)
                }
            }
            
        case .smartAlarmOptimization:
            // Optimize alarm timing
            if let alarmSystem = SmartAlarmSystem.shared {
                Task {
                    await alarmSystem.optimizeAlarmTiming(based: intervention)
                }
            }
            
        case .biofeedbackGuidance:
            // Provide real-time biofeedback
            if let biofeedbackEngine = AdvancedBiofeedback.shared {
                Task {
                    await biofeedbackEngine.provideRealtimeBiofeedback(intervention)
                }
            }
        }
        
        print("HealthDataManager: Executed intervention: \(intervention.description)")
    }
    
    private func triggerImmediateHealthAlert(assessment: RealtimeHealthRiskAssessment) {
        let alertTitle: String
        let alertBody: String
        let sound: UNNotificationSound
        
        switch assessment.level {
        case .critical:
            alertTitle = "🚨 Critical Health Alert"
            alertBody = "Critical health issue detected during sleep. Consider waking up and seeking medical attention."
            sound = .critical
        case .high:
            alertTitle = "⚠️ High Health Risk Alert"
            alertBody = "High health risk detected during sleep. Monitoring closely."
            sound = .default
        default:
            return // Don't send notifications for elevated/low risks during sleep
        }
        
        let content = UNMutableNotificationContent()
        content.title = alertTitle
        content.body = alertBody
        content.sound = sound
        content.categoryIdentifier = "HEALTH_RISK_ALERT"
        
        let request = UNNotificationRequest(
            identifier: "health_risk_\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("HealthDataManager: Failed to send health alert: \(error)")
            } else {
                print("HealthDataManager: Health alert sent for \(assessment.level) risk")
            }
        }
    }
    
    private func saveEnhancedHealthData(features: SleepFeatures, prediction: SleepPredictionResult) {
        let enhancedData = EnhancedHealthSnapshot(
            // Basic vitals
            heartRate: features.heartRateAverage,
            hrv: features.heartRateVariability,
            oxygenSaturation: features.spo2Average,
            bodyTemperature: features.wristTemperatureAverage,
            
            // Sleep-specific features
            sleepStage: prediction.stage.rawValue,
            sleepStageConfidence: prediction.confidence,
            sleepQuality: prediction.quality,
            
            // Advanced features
            activityCount: features.activityCount,
            temperatureStability: features.wristTemperatureGradient,
            breathingRegularity: features.sdnn, // Proxy for breathing
            
            // Metadata
            timestamp: Date(),
            modelVersion: prediction.modelUsed
        )
        
        // Save to Core Data
        CoreDataManager.shared.saveEnhancedHealthData(enhancedData)
    }
    
    private func calculateTimeUntilMorning() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        
        // Assume 7 AM as target wake time
        var wakeTime = calendar.startOfDay(for: now)
        wakeTime = calendar.date(byAdding: .hour, value: 7, to: wakeTime) ?? wakeTime
        
        // If it's already past 7 AM, target tomorrow's 7 AM
        if now > wakeTime {
            wakeTime = calendar.date(byAdding: .day, value: 1, to: wakeTime) ?? wakeTime
        }
        
        return wakeTime.timeIntervalSince(now)
    }
    
    private func processStepSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            let totalSteps = samples.reduce(0) { total, sample in
                total + Int(sample.quantity.doubleValue(for: HKUnit.count()))
            }
            self.stepCount = totalSteps
        }
    }
    
    private func processEnergySamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            let totalEnergy = samples.reduce(0.0) { total, sample in
                total + sample.quantity.doubleValue(for: HKUnit.kilocalorie())
            }
            self.activeEnergyBurned = totalEnergy
        }
    }
    
    // MARK: - Data Fetching Methods
    
    private func fetchCurrentHealthData() {
        // Fetch current health data from HealthKit
        fetchHeartRate()
        fetchHRV()
        fetchOxygenSaturation()
        fetchBodyTemperature()
        fetchSleepData()
        fetchStepCount()
        fetchActiveEnergy()
        fetchMovementData()
        // No direct fetch for CoreMotion data as it's stream-based
    }
    
    private func fetchHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { [weak self] query, statistics, error in
            if let average = statistics?.averageQuantity() {
                DispatchQueue.main.async {
                    self?.currentHeartRate = average.doubleValue(for: HKUnit(from: "count/min"))
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHRV() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: predicate, options: .discreteAverage) { [weak self] query, statistics, error in
            if let average = statistics?.averageQuantity() {
                DispatchQueue.main.async {
                    self?.currentHRV = average.doubleValue(for: HKUnit(from: "ms"))
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchOxygenSaturation() {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: oxygenType, quantitySamplePredicate: predicate, options: .discreteAverage) { [weak self] query, statistics, error in
            if let average = statistics?.averageQuantity() {
                DispatchQueue.main.async {
                    self?.currentOxygenSaturation = average.doubleValue(for: HKUnit.percent())
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBodyTemperature() {
        guard let temperatureType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: temperatureType, quantitySamplePredicate: predicate, options: .discreteAverage) { [weak self] query, statistics, error in
            if let average = statistics?.averageQuantity() {
                DispatchQueue.main.async {
                    self?.currentBodyTemperature = average.doubleValue(for: HKUnit.degreeCelsius())
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchSleepData() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date(), options: .strictStartDate)
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] query, samples, error in
            if let samples = samples as? [HKCategorySample] {
                DispatchQueue.main.async {
                    self?.sleepData = samples
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchStepCount() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] query, statistics, error in
            if let sum = statistics?.sumQuantity() {
                DispatchQueue.main.async {
                    self?.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveEnergy() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: Date()), end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] query, statistics, error in
            if let sum = statistics?.sumQuantity() {
                DispatchQueue.main.async {
                    self?.activeEnergyBurned = sum.doubleValue(for: HKUnit.kilocalorie())
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchDailyMetrics() {
        // Fetch and process daily health metrics
        // This would include aggregated data for the current day
    }
    
    private func fetchWeeklyTrends() {
        // Fetch and process weekly health trends
        // This would include trend analysis over the past week
    }
    
    private func setupMovementObserver() {
        guard let movementType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed) else { return }
        
        let query = HKAnchoredObjectQuery(type: movementType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processMovementSamples(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processMovementSamples(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func processMovementSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        DispatchQueue.main.async {
            let newSensorSamples = samples.map { sample in
                SensorSample(type: .walkingSpeed, value: sample.quantity.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second())), unit: "m/s", timestamp: sample.endDate)
            }
            self.rawSensorData.append(contentsOf: newSensorSamples)
        }
    }
    
    private func fetchMovementData() {
        guard let movementType = HKQuantityType.quantityType(forIdentifier: .walkingSpeed) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: movementType, quantitySamplePredicate: predicate, options: .discreteAverage) { [weak self] query, statistics, error in
            if let average = statistics?.averageQuantity() {
                DispatchQueue.main.async {
                    // For POC, we'll just store the latest average movement data as a raw sensor sample
                    let newSample = SensorSample(type: .walkingSpeed, value: average.doubleValue(for: HKUnit.meter().unitDivided(by: HKUnit.second())), unit: "m/s", timestamp: Date())
                    self?.rawSensorData.append(newSample)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func startDataCollection() {
        // Start continuous data collection
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    
    var isAuthorized: Bool {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        return healthStore.authorizationStatus(for: heartRateType) == .sharingAuthorized
    }
    
    func requestHealthDataAccess(completion: @escaping (Bool) -> Void) {
        requestHealthKitAuthorization(completion: completion)
    }
    
    func refreshHealthData() {
        refreshData()
    }
    
    // MARK: - Background Data Collection
    
    func enableBackgroundDelivery() {
        guard isAuthorized else { return }
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for heart rate: \(error)")
            }
        }
        
        healthStore.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for HRV: \(error)")
            }
        }
        
        healthStore.enableBackgroundDelivery(for: sleepType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery for sleep: \(error)")
            }
        }
    }
    
    // MARK: - Data Export
    
    func exportHealthData(startDate: Date, endDate: Date) -> [String: Any] {
        // Export health data for the specified date range
        return [
            "heartRate": currentHeartRate,
            "hrv": currentHRV,
            "oxygenSaturation": currentOxygenSaturation,
            "bodyTemperature": currentBodyTemperature,
            "stepCount": stepCount,
            "activeEnergyBurned": activeEnergyBurned,
            "exportDate": Date(),
            "dateRange": ["start": startDate, "end": endDate]
        ]
    }
    
    // MARK: - App Intent Support
    
    func getCurrentHeartRate() async -> Double {
        // Fetch the latest heart rate sample directly for the intent
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return 0.0 }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date(), options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { query, samples, error in
                if let sample = samples?.first as? HKQuantitySample {
                    let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    continuation.resume(returning: heartRate)
                } else {
                    continuation.resume(returning: 0.0)
                }
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Data Logging
    
    func logWaterIntake(amount: Double) {
        guard isAuthorized else {
            print("HealthDataManager: HealthKit not authorized for writing.")
            return
        }
        
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            print("HealthDataManager: Dietary Water type not available.")
            return
        }
        
        let waterQuantity = HKQuantity(unit: HKUnit.literUnit(with: .milli), doubleValue: amount)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: Date(), end: Date())
        
        healthStore.save(waterSample) { success, error in
            if success {
                print("HealthDataManager: Successfully logged \(amount) ml of water intake.")
            } else if let error = error {
                print("HealthDataManager: Failed to log water intake: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Apple Watch Integration
    
    func updateWatchHealthData(_ watchData: WatchHealthData) {
        DispatchQueue.main.async {
            // Update current readings with Watch data
            self.currentHeartRate = watchData.heartRate
            self.currentHRV = watchData.hrv
            
            // Create sensor samples from Watch data
            let heartRateSample = SensorSample(
                type: .heartRate,
                value: watchData.heartRate,
                unit: "count/min",
                timestamp: watchData.timestamp
            )
            
            let hrvSample = SensorSample(
                type: .hrv,
                value: watchData.hrv,
                unit: "ms",
                timestamp: watchData.timestamp
            )
            
            self.rawSensorData.append(contentsOf: [heartRateSample, hrvSample])
            
            // Update predicted sleep stage if available
            if !watchData.sleepStage.isEmpty {
                self.predictedSleepStage = watchData.sleepStage
            }
            
            print("HealthDataManager: Updated with Watch data - HR: \(watchData.heartRate), HRV: \(watchData.hrv)")
        }
    }
    
    func saveWatchSleepSession(_ session: WatchSleepSession) {
        guard let endTime = session.endTime,
              let duration = session.duration else {
            print("HealthDataManager: Invalid sleep session data")
            return
        }
        
        let startTime = session.startTime
        
        // Save to HealthKit as a sleep analysis entry
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let sleepSample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleep.rawValue,
            start: startTime,
            end: endTime
        )
        
        healthStore.save(sleepSample) { [weak self] success, error in
            if success {
                print("HealthDataManager: Watch sleep session saved to HealthKit")
                
                // Also save session metrics
                if let avgHeartRate = session.averageHeartRate {
                    self?.saveAverageHeartRate(avgHeartRate, for: startTime, endTime: endTime)
                }
                
                if let avgHRV = session.averageHRV {
                    self?.saveAverageHRV(avgHRV, for: startTime, endTime: endTime)
                }
            } else if let error = error {
                print("HealthDataManager: Failed to save sleep session: \(error)")
            }
        }
    }
    
    func getCurrentHealthStatus() -> [String: Any] {
        return [
            "heartRate": currentHeartRate,
            "hrv": currentHRV,
            "oxygenSaturation": currentOxygenSaturation,
            "bodyTemperature": currentBodyTemperature,
            "stepCount": stepCount,
            "activeEnergyBurned": activeEnergyBurned,
            "predictedSleepStage": predictedSleepStage ?? "unknown",
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    func getCurrentSleepStage() -> [String: Any] {
        return [
            "sleepStage": predictedSleepStage ?? "unknown",
            "confidence": 0.8, // Default confidence
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    private func saveAverageHeartRate(_ heartRate: Double, for startTime: Date, endTime: Date) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let heartRateQuantity = HKQuantity(unit: HKUnit(from: "count/min"), doubleValue: heartRate)
        let heartRateSample = HKQuantitySample(
            type: heartRateType,
            quantity: heartRateQuantity,
            start: startTime,
            end: endTime
        )
        
        healthStore.save(heartRateSample) { success, error in
            if let error = error {
                print("Failed to save average heart rate: \(error)")
            }
        }
    }
    
    private func saveAverageHRV(_ hrv: Double, for startTime: Date, endTime: Date) {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let hrvQuantity = HKQuantity(unit: HKUnit(from: "ms"), doubleValue: hrv)
        let hrvSample = HKQuantitySample(
            type: hrvType,
            quantity: hrvQuantity,
            start: startTime,
            end: endTime
        )
        
        healthStore.save(hrvSample) { success, error in
            if let error = error {
                print("Failed to save average HRV: \(error)")
            }
        }
    }
    
    // MARK: - Health Insights
    
    func generateDailyHealthInsights() -> [String] {
        var insights: [String] = []
        
        // Heart rate insights
        if currentHeartRate > 100 {
            insights.append("Your heart rate is elevated (\(Int(currentHeartRate)) BPM). Consider taking a break.")
        } else if currentHeartRate < 60 {
            insights.append("Your resting heart rate is low (\(Int(currentHeartRate)) BPM). Great cardiovascular fitness!")
        }
        
        // HRV insights
        if currentHRV > 50 {
            insights.append("Excellent heart rate variability (\(Int(currentHRV))ms). Your body is well-recovered.")
        } else if currentHRV < 20 {
            insights.append("Low heart rate variability (\(Int(currentHRV))ms). Consider stress management techniques.")
        }
        
        // Activity insights
        if stepCount < 5000 {
            insights.append("You've taken \(stepCount) steps today. Try to reach 10,000 steps for optimal health.")
        } else if stepCount > 10000 {
            insights.append("Great activity level! You've taken \(stepCount) steps today.")
        }
        
        return insights
    }
    
    // MARK: - Federated Learning Support
    
    /// Retrieves health data for training machine learning models.
    /// - Returns: An array of HealthData objects suitable for training.
    /// - Throws: An error if data retrieval fails.
    func getTrainingData() async throws -> [HealthData] {
        // Fetch health data from the last 30 days
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else {
            throw HealthDataError.invalidDateRange
        }
        
        var healthDataPoints: [HealthData] = []
        
        // Fetch heart rate data
        if let heartRateData = try await fetchHealthData(type: .heartRate, startDate: startDate, endDate: endDate) {
            for sample in heartRateData {
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                let healthData = HealthData(
                    value: heartRate,
                    heartRate: heartRate,
                    timestamp: sample.endDate
                )
                healthDataPoints.append(healthData)
            }
        }
        
        // Fetch blood pressure data (if available)
        if let systolicData = try await fetchHealthData(type: .bloodPressureSystolic, startDate: startDate, endDate: endDate),
           let diastolicData = try await fetchHealthData(type: .bloodPressureDiastolic, startDate: startDate, endDate: endDate) {
            
            // Match systolic and diastolic readings by timestamp
            let systolicDict = Dictionary(grouping: systolicData) { sample in
                calendar.startOfDay(for: sample.endDate)
            }
            
            let diastolicDict = Dictionary(grouping: diastolicData) { sample in
                calendar.startOfDay(for: sample.endDate)
            }
            
            for (day, systolicSamples) in systolicDict {
                if let diastolicSamples = diastolicDict[day] {
                    // Use the average for the day
                    let avgSystolic = systolicSamples.map { $0.quantity.doubleValue(for: HKUnit.millimeterOfMercury()) }.reduce(0, +) / Double(systolicSamples.count)
                    let avgDiastolic = diastolicSamples.map { $0.quantity.doubleValue(for: HKUnit.millimeterOfMercury()) }.reduce(0, +) / Double(diastolicSamples.count)
                    
                    let healthData = HealthData(
                        value: avgSystolic, // Use systolic as the primary value
                        systolicBloodPressure: avgSystolic,
                        diastolicBloodPressure: avgDiastolic,
                        timestamp: day
                    )
                    healthDataPoints.append(healthData)
                }
            }
        }
        
        // Fetch oxygen saturation data
        if let oxygenData = try await fetchHealthData(type: .oxygenSaturation, startDate: startDate, endDate: endDate) {
            for sample in oxygenData {
                let oxygenSaturation = sample.quantity.doubleValue(for: HKUnit.percent())
                let healthData = HealthData(
                    value: oxygenSaturation,
                    oxygenSaturation: oxygenSaturation,
                    timestamp: sample.endDate
                )
                healthDataPoints.append(healthData)
            }
        }
        
        // Fetch body temperature data
        if let temperatureData = try await fetchHealthData(type: .bodyTemperature, startDate: startDate, endDate: endDate) {
            for sample in temperatureData {
                let temperature = sample.quantity.doubleValue(for: HKUnit.degreeCelsius())
                let healthData = HealthData(
                    value: temperature,
                    bodyTemperature: temperature,
                    timestamp: sample.endDate
                )
                healthDataPoints.append(healthData)
            }
        }
        
        return healthDataPoints
    }
    
    /// Fetches health data of a specific type for a given date range.
    /// - Parameters:
    ///   - type: The type of health data to fetch.
    ///   - startDate: The start date of the range.
    ///   - endDate: The end date of the range.
    /// - Returns: An array of HKQuantitySample objects, or nil if the data type is not available.
    /// - Throws: An error if data retrieval fails.
    private func fetchHealthData(type: HKQuantityTypeIdentifier, startDate: Date, endDate: Date) async throws -> [HKQuantitySample]? {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let quantitySamples = samples as? [HKQuantitySample] ?? []
                continuation.resume(returning: quantitySamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Errors that can occur during health data operations.
    enum HealthDataError: Error {
        case invalidDateRange
        case dataNotAvailable
        case authorizationRequired
        case processingFailed
    }
}

extension Date {
    func toHealthKitTimestamp() -> Date {
        // HealthKit timestamps are often in UTC, or at least consistent.
        // For CoreMotion, CMATimeStamp is seconds since boot, so we convert to Date.
        // This extension assumes the CMATimeStamp is relative to the device's uptime.
        // For simplicity, we'll just return self for now, assuming the conversion
        // from CMATimeStamp to Date is handled where the data is received.
        return self
    }
}

extension TimeInterval {
    func toDate() -> Date {
        return Date(timeIntervalSinceReferenceDate: self)
    }
}

// MARK: - Data Models

struct DailyHealthMetrics {
    var averageHeartRate: Double = 0
    var averageHRV: Double = 0
    var totalSteps: Int = 0
    var totalEnergyBurned: Double = 0
    var sleepDuration: TimeInterval = 0
    var sleepQuality: Double = 0
}

struct WeeklyHealthTrends {
    var heartRateTrend: [Double] = []
    var hrvTrend: [Double] = []
    var stepTrend: [Int] = []
    var energyTrend: [Double] = []
    var sleepTrend: [TimeInterval] = []
}

extension SleepFeatures {
    func toArray() -> [Double] {
        return [
            rmssd,
            sdnn,
            heartRateAverage,
            heartRateVariability,
            spo2Average,
            spo2Variability,
            activityCount,
            sleepWakeDetection,
            wristTemperatureAverage,
            wristTemperatureGradient
        ]
    }
}

// MARK: - Enhanced Real-Time Processing Types

enum HealthRiskLevel: Comparable {
    case low
    case elevated
    case high
    case critical
    
    static func < (lhs: HealthRiskLevel, rhs: HealthRiskLevel) -> Bool {
        let order: [HealthRiskLevel] = [.low, .elevated, .high, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

struct RealtimeHealthRiskAssessment {
    let level: HealthRiskLevel
    let factors: [String]
    let timestamp: Date
    let confidence: Double
}

struct PredictiveIntervention {
    let type: InterventionType
    let description: String
    let urgency: InterventionUrgency
    let expectedBenefit: Double
    
    enum InterventionType {
        case environmentalAdjustment
        case audioTherapy
        case smartAlarmOptimization
        case biofeedbackGuidance
    }
    
    enum InterventionUrgency {
        case immediate
        case withinMinutes
        case scheduled
    }
}

struct ContinuousMonitoringData {
    let heartRate: Double
    let hrv: Double
    let oxygenSaturation: Double
    let sleepStage: String
    let confidence: Double
    let timestamp: Date
}

struct EnhancedHealthSnapshot {
    let heartRate: Double
    let hrv: Double
    let oxygenSaturation: Double
    let bodyTemperature: Double
    let sleepStage: String
    let sleepStageConfidence: Double
    let sleepQuality: Double
    let activityCount: Double
    let temperatureStability: Double
    let breathingRegularity: Double
    let timestamp: Date
    let modelVersion: String
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let realtimeHealthRiskAssessed = Notification.Name("realtimeHealthRiskAssessed")
    static let continuousMonitoringDataUpdated = Notification.Name("continuousMonitoringDataUpdated")
}