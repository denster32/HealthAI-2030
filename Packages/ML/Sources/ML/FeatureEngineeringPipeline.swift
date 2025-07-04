import Foundation
import HealthKit
import Combine
import os.log

@available(iOS 17.0, *)
public class FeatureEngineeringPipeline: ObservableObject {
    private let logger = Logger(subsystem: "com.healthai.2030", category: "FeatureEngineering")
    
    // MARK: - Public Properties
    @Published public var isProcessing = false
    @Published public var lastProcessedDate: Date?
    @Published public var processingErrors: [FeatureProcessingError] = []
    
    // MARK: - Private Properties
    private let healthKitManager: HealthKitIntegrationManager
    private let sleepFeatureExtractor: SleepFeatureExtractor
    private var cancellables = Set<AnyCancellable>()
    
    // Feature processors
    private let cardiovascularProcessor = CardiovascularFeatureProcessor()
    private let sleepProcessor = SleepFeatureProcessor()
    private let activityProcessor = ActivityFeatureProcessor()
    private let environmentalProcessor = EnvironmentalFeatureProcessor()
    private let circadianProcessor = CircadianFeatureProcessor()
    private let nutritionProcessor = NutritionFeatureProcessor()
    private let stressProcessor = StressFeatureProcessor()
    
    // Feature cache
    private var featureCache: [String: FeatureSet] = [:]
    private let cacheExpiryTime: TimeInterval = 3600 // 1 hour
    
    // MARK: - Initialization
    public init(healthKitManager: HealthKitIntegrationManager = .shared) {
        self.healthKitManager = healthKitManager
        self.sleepFeatureExtractor = SleepFeatureExtractor()
        setupDataStreamSubscriptions()
    }
    
    // MARK: - Public Interface
    
    /// Process all available health data into ML-ready features
    public func processAllFeatures() async -> ComprehensiveFeatureSet? {
        logger.info("Starting comprehensive feature processing")
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Process features in parallel for efficiency
            async let cardiovascularFeatures = processCardiovascularFeatures()
            async let sleepFeatures = processSleepFeatures()
            async let activityFeatures = processActivityFeatures()
            async let environmentalFeatures = processEnvironmentalFeatures()
            async let circadianFeatures = processCircadianFeatures()
            async let nutritionFeatures = processNutritionFeatures()
            async let stressFeatures = processStressFeatures()
            
            let (cardio, sleep, activity, environmental, circadian, nutrition, stress) = await (
                cardiovascularFeatures, sleepFeatures, activityFeatures,
                environmentalFeatures, circadianFeatures, nutritionFeatures, stressFeatures
            )
            
            let comprehensiveFeatures = ComprehensiveFeatureSet(
                cardiovascular: cardio,
                sleep: sleep,
                activity: activity,
                environmental: environmental,
                circadian: circadian,
                nutrition: nutrition,
                stress: stress,
                timestamp: Date()
            )
            
            lastProcessedDate = Date()
            logger.info("Feature processing completed successfully")
            return comprehensiveFeatures
            
        } catch {
            logger.error("Feature processing failed: \\(error.localizedDescription)")
            processingErrors.append(FeatureProcessingError(error: error, timestamp: Date()))
            return nil
        }
    }
    
    /// Get cached features or process new ones
    public func getFeatures(for timeWindow: TimeInterval = 3600) async -> ComprehensiveFeatureSet? {
        let cacheKey = "features_\\(Int(timeWindow))"
        
        if let cachedFeatures = featureCache[cacheKey],
           Date().timeIntervalSince(cachedFeatures.timestamp) < cacheExpiryTime {
            logger.debug("Returning cached features")
            return cachedFeatures as? ComprehensiveFeatureSet
        }
        
        guard let newFeatures = await processAllFeatures() else {
            return nil
        }
        
        featureCache[cacheKey] = newFeatures
        return newFeatures
    }
    
    // MARK: - Private Feature Processing Methods
    
    private func processCardiovascularFeatures() async -> CardiovascularFeatures {
        logger.debug("Processing cardiovascular features")
        
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-3600) // Last hour
        
        // Fetch heart rate data
        let heartRateData = await fetchHealthKitData(
            type: HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            startDate: startDate,
            endDate: endDate
        )
        
        // Fetch HRV data
        let hrvData = await fetchHealthKitData(
            type: HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            startDate: startDate,
            endDate: endDate
        )
        
        // Fetch respiratory rate data
        let respiratoryData = await fetchHealthKitData(
            type: HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
            startDate: startDate,
            endDate: endDate
        )
        
        // Fetch oxygen saturation data
        let oxygenData = await fetchHealthKitData(
            type: HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!,
            startDate: startDate,
            endDate: endDate
        )
        
        return cardiovascularProcessor.process(
            heartRateData: heartRateData,
            hrvData: hrvData,
            respiratoryData: respiratoryData,
            oxygenData: oxygenData
        )
    }
    
    private func processSleepFeatures() async -> SleepFeatures {
        logger.debug("Processing sleep features")
        
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-12 * 3600) // Last 12 hours
        
        let sleepData = await fetchSleepData(startDate: startDate, endDate: endDate)
        
        return sleepProcessor.process(sleepData: sleepData)
    }
    
    private func processActivityFeatures() async -> ActivityFeatures {
        logger.debug("Processing activity features")
        
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-24 * 3600) // Last 24 hours
        
        let stepData = await fetchHealthKitData(
            type: HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            startDate: startDate,
            endDate: endDate
        )
        
        let activeEnergyData = await fetchHealthKitData(
            type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            startDate: startDate,
            endDate: endDate
        )
        
        let workoutData = await fetchWorkoutData(startDate: startDate, endDate: endDate)
        
        return activityProcessor.process(
            stepData: stepData,
            activeEnergyData: activeEnergyData,
            workoutData: workoutData
        )
    }
    
    private func processEnvironmentalFeatures() async -> EnvironmentalFeatures {
        logger.debug("Processing environmental features")
        
        let audioExposureData = await fetchHealthKitData(
            type: HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure)!,
            startDate: Date().addingTimeInterval(-24 * 3600),
            endDate: Date()
        )
        
        return environmentalProcessor.process(audioExposureData: audioExposureData)
    }
    
    private func processCircadianFeatures() async -> CircadianFeatures {
        logger.debug("Processing circadian features")
        
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-7 * 24 * 3600) // Last week
        
        let sleepData = await fetchSleepData(startDate: startDate, endDate: endDate)
        let activityData = await fetchHealthKitData(
            type: HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            startDate: startDate,
            endDate: endDate
        )
        
        return circadianProcessor.process(sleepData: sleepData, activityData: activityData)
    }
    
    private func processNutritionFeatures() async -> NutritionFeatures {
        logger.debug("Processing nutrition features")
        
        return nutritionProcessor.process()
    }
    
    private func processStressFeatures() async -> StressFeatures {
        logger.debug("Processing stress features")
        
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-24 * 3600) // Last 24 hours
        
        let hrvData = await fetchHealthKitData(
            type: HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            startDate: startDate,
            endDate: endDate
        )
        
        let heartRateData = await fetchHealthKitData(
            type: HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            startDate: startDate,
            endDate: endDate
        )
        
        let mindfulnessData = await fetchCategoryData(
            type: HKCategoryType.categoryType(forIdentifier: .mindfulSession)!,
            startDate: startDate,
            endDate: endDate
        )
        
        return stressProcessor.process(
            hrvData: hrvData,
            heartRateData: heartRateData,
            mindfulnessData: mindfulnessData
        )
    }
    
    // MARK: - Data Fetching Helpers
    
    private func fetchHealthKitData(type: HKQuantityType, startDate: Date, endDate: Date) async -> [HKQuantitySample] {
        await withCheckedContinuation { continuation in
            healthKitManager.fetchSamples(for: type, from: startDate, to: endDate) { (samples: [HKQuantitySample]?, error) in
                if let error = error {
                    logger.error("Error fetching HealthKit data: \\(error.localizedDescription)")
                    continuation.resume(returning: [])
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
        }
    }
    
    private func fetchCategoryData(type: HKCategoryType, startDate: Date, endDate: Date) async -> [HKCategorySample] {
        await withCheckedContinuation { continuation in
            healthKitManager.fetchSamples(for: type, from: startDate, to: endDate) { (samples: [HKCategorySample]?, error) in
                if let error = error {
                    logger.error("Error fetching category data: \\(error.localizedDescription)")
                    continuation.resume(returning: [])
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
        }
    }
    
    private func fetchSleepData(startDate: Date, endDate: Date) async -> [HKCategorySample] {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }
        
        return await fetchCategoryData(type: sleepType, startDate: startDate, endDate: endDate)
    }
    
    private func fetchWorkoutData(startDate: Date, endDate: Date) async -> [HKWorkout] {
        await withCheckedContinuation { continuation in
            healthKitManager.fetchSamples(for: HKWorkoutType.workoutType(), from: startDate, to: endDate) { (samples: [HKWorkout]?, error) in
                if let error = error {
                    logger.error("Error fetching workout data: \\(error.localizedDescription)")
                    continuation.resume(returning: [])
                } else {
                    continuation.resume(returning: samples ?? [])
                }
            }
        }
    }
    
    // MARK: - Data Stream Subscriptions
    
    private func setupDataStreamSubscriptions() {
        healthKitManager.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.invalidateFeatureCache()
            }
            .store(in: &cancellables)
        
        healthKitManager.sleepAnalysisPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.invalidateFeatureCache()
            }
            .store(in: &cancellables)
        
        healthKitManager.hrvPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.invalidateFeatureCache()
            }
            .store(in: &cancellables)
    }
    
    private func invalidateFeatureCache() {
        featureCache.removeAll()
        logger.debug("Feature cache invalidated due to new data")
    }
}

// MARK: - Feature Set Structures

public struct ComprehensiveFeatureSet: FeatureSet {
    let cardiovascular: CardiovascularFeatures
    let sleep: SleepFeatures
    let activity: ActivityFeatures
    let environmental: EnvironmentalFeatures
    let circadian: CircadianFeatures
    let nutrition: NutritionFeatures
    let stress: StressFeatures
    let timestamp: Date
    
    public func toMLArray() -> [Double] {
        var features: [Double] = []
        features.append(contentsOf: cardiovascular.toMLArray())
        features.append(contentsOf: sleep.toMLArray())
        features.append(contentsOf: activity.toMLArray())
        features.append(contentsOf: environmental.toMLArray())
        features.append(contentsOf: circadian.toMLArray())
        features.append(contentsOf: nutrition.toMLArray())
        features.append(contentsOf: stress.toMLArray())
        return features
    }
}

public struct CardiovascularFeatures: FeatureSet {
    let heartRateAverage: Double
    let heartRateVariability: Double
    let heartRateMin: Double
    let heartRateMax: Double
    let heartRateRange: Double
    let restingHeartRate: Double
    
    let hrvAverage: Double
    let hrvVariability: Double
    let rmssd: Double
    let sdnn: Double
    let pnn50: Double
    
    let respiratoryRateAverage: Double
    let respiratoryRateVariability: Double
    
    let oxygenSaturationAverage: Double
    let oxygenSaturationVariability: Double
    let oxygenSaturationMin: Double
    
    let cardiovascularStress: Double
    let autonomicBalance: Double
    let timestamp: Date
    
    public func toMLArray() -> [Double] {
        return [
            heartRateAverage, heartRateVariability, heartRateMin, heartRateMax, heartRateRange, restingHeartRate,
            hrvAverage, hrvVariability, rmssd, sdnn, pnn50,
            respiratoryRateAverage, respiratoryRateVariability,
            oxygenSaturationAverage, oxygenSaturationVariability, oxygenSaturationMin,
            cardiovascularStress, autonomicBalance
        ]
    }
}

public struct ActivityFeatures: FeatureSet {
    let stepCount: Double
    let stepCountVariability: Double
    let activeMinutes: Double
    let sedentaryMinutes: Double
    let activeEnergyBurned: Double
    let workoutDuration: Double
    let workoutIntensity: Double
    let activityConsistency: Double
    let dailyActivityGoalProgress: Double
    let timestamp: Date
    
    public func toMLArray() -> [Double] {
        return [
            stepCount, stepCountVariability, activeMinutes, sedentaryMinutes,
            activeEnergyBurned, workoutDuration, workoutIntensity,
            activityConsistency, dailyActivityGoalProgress
        ]
    }
}

public struct EnvironmentalFeatures: FeatureSet {
    let audioExposureLevel: Double
    let audioExposureVariability: Double
    let noisePollutionScore: Double
    let timestamp: Date
    
    public func toMLArray() -> [Double] {
        return [audioExposureLevel, audioExposureVariability, noisePollutionScore]
    }
}

public struct CircadianFeatures: FeatureSet {
    let sleepRegularity: Double
    let sleepMidpoint: Double
    let sleepMidpointVariability: Double
    let socialJetlag: Double
    let chronotype: Double
    let lightExposureScore: Double
    let activityRhythmStrength: Double
    let timestamp: Date
    
    public func toMLArray() -> [Double] {
        return [
            sleepRegularity, sleepMidpoint, sleepMidpointVariability,
            socialJetlag, chronotype, lightExposureScore, activityRhythmStrength
        ]
    }
}

public struct NutritionFeatures: FeatureSet {
    let nutritionScore: Double
    let hydrationLevel: Double
    let caffeineIntake: Double
    let lastMealTiming: Double
    let timestamp: Date
    
    public func toMLArray() -> [Double] {
        return [nutritionScore, hydrationLevel, caffeineIntake, lastMealTiming]
    }
}

public struct StressFeatures: FeatureSet {
    let stressScore: Double
    let stressVariability: Double
    let mindfulnessMinutes: Double
    let stressRecoveryRate: Double
    let autonomicStressIndex: Double
    let timestamp: Date
    
    public func toMLArray() -> [Double] {
        return [stressScore, stressVariability, mindfulnessMinutes, stressRecoveryRate, autonomicStressIndex]
    }
}

// MARK: - Feature Processing Error
public struct FeatureProcessingError {
    let error: Error
    let timestamp: Date
    
    var localizedDescription: String {
        return "Feature processing error at \\(timestamp): \\(error.localizedDescription)"
    }
}

// MARK: - Feature Set Protocol
public protocol FeatureSet {
    var timestamp: Date { get }
    func toMLArray() -> [Double]
}