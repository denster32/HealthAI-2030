import Foundation
import Combine
import HealthKit
import UserNotifications
import CoreML

/// Comprehensive data model for stress detection and interruption
public struct StressDetectionInput: Codable {
    public let heartRateVariability: Double
    public let respiratoryRate: Double
    public let cortisolLevel: Double
    public let sleepQuality: Double
    public let physicalActivity: Double
    public let screenTime: Double
    public let socialInteractions: Double
    public let workloadIntensity: Double
    
    public init(
        heartRateVariability: Double,
        respiratoryRate: Double,
        cortisolLevel: Double,
        sleepQuality: Double,
        physicalActivity: Double,
        screenTime: Double,
        socialInteractions: Double,
        workloadIntensity: Double
    ) {
        self.heartRateVariability = heartRateVariability
        self.respiratoryRate = respiratoryRate
        self.cortisolLevel = cortisolLevel
        self.sleepQuality = sleepQuality
        self.physicalActivity = physicalActivity
        self.screenTime = screenTime
        self.socialInteractions = socialInteractions
        self.workloadIntensity = workloadIntensity
    }
}

/// Stress interruption output with recommendations and intervention strategies
public struct StressInterruptionOutput: Codable {
    public enum StressLevel: String, Codable {
        case low, moderate, high, critical
    }
    
    public let stressLevel: StressLevel
    public let stressScore: Double
    public let triggerReasons: [String]
    public let recommendedInterventions: [StressIntervention]
    public let immediateActionRequired: Bool
}

/// Stress intervention strategies
public struct StressIntervention: Codable {
    public enum InterventionType: String, Codable {
        case breathing
        case meditation
        case physicalActivity
        case socialConnection
        case workPause
        case sleepRecommendation
    }
    
    public let type: InterventionType
    public let duration: TimeInterval
    public let intensity: Double
    public let description: String
}

/// Advanced Stress Interruption System
public class StressInterruptionSystem {
    public static let shared = StressInterruptionSystem()
    
    // Machine Learning Models
    private var stressDetectionModel: MLModel?
    private var interventionRecommendationModel: MLModel?
    
    // Combine publishers
    private let stressDetectionPublisher = PassthroughSubject<StressInterruptionOutput, Never>()
    
    // Health Store for data collection
    private let healthStore = HKHealthStore()
    private let logger = Logger(subsystem: "com.healthai.stressdetection", category: "StressInterruptionSystem")
    
    // User preferences for stress management
    private var userPreferences: [String: Any] = [:]
    
    private init() {
        setupMLModels()
        setupHealthKitObservers()
        setupNotificationAuthorization()
    }
    
    /// Setup Machine Learning Models
    private func setupMLModels() {
        do {
            stressDetectionModel = try MLModel(contentsOf: Bundle.main.url(forResource: "StressDetectionModel", withExtension: "mlmodel")!)
            interventionRecommendationModel = try MLModel(contentsOf: Bundle.main.url(forResource: "StressInterventionRecommender", withExtension: "mlmodel")!)
        } catch {
            logger.error("ML Model setup failed: \(error.localizedDescription)")
        }
    }
    
    /// Setup HealthKit observers for continuous data collection
    private func setupHealthKitObservers() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] (success, error) in
            guard success else {
                self?.logger.error("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self?.setupContinuousQueries()
        }
    }
    
    /// Setup continuous queries for health data
    private func setupContinuousQueries() {
        // Heart Rate Variability Query
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let hrvQuery = HKAnchoredObjectQuery(type: hrvType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] (query, samples, deletedObjects, newAnchor, error) in
            guard let hrvSamples = samples as? [HKQuantitySample] else { return }
            self?.processHealthData(hrvSamples: hrvSamples)
        }
        
        healthStore.execute(hrvQuery)
    }
    
    /// Process health data and trigger stress detection
    private func processHealthData(hrvSamples: [HKQuantitySample]) {
        guard !hrvSamples.isEmpty else { return }
        
        let hrvValues = hrvSamples.map { $0.quantity.doubleValue(for: HKUnit.secondUnit()) }
        let avgHRV = hrvValues.reduce(0, +) / Double(hrvValues.count)
        
        // Collect additional contextual data
        let input = collectContextualData(baseHRV: avgHRV)
        
        // Detect and interrupt stress
        detectAndInterruptStress(input: input)
    }
    
    /// Collect contextual data for stress detection
    private func collectContextualData(baseHRV: Double) -> StressDetectionInput {
        // In a real implementation, these would be collected from various sources
        return StressDetectionInput(
            heartRateVariability: baseHRV,
            respiratoryRate: simulateRespiratoryRate(),
            cortisolLevel: simulateCortisolLevel(),
            sleepQuality: simulateSleepQuality(),
            physicalActivity: simulatePhysicalActivity(),
            screenTime: simulateScreenTime(),
            socialInteractions: simulateSocialInteractions(),
            workloadIntensity: simulateWorkloadIntensity()
        )
    }
    
    /// Detect and interrupt stress using ML models
    private func detectAndInterruptStress(input: StressDetectionInput) {
        guard let stressDetectionModel = stressDetectionModel,
              let interventionRecommendationModel = interventionRecommendationModel else { return }
        
        do {
            // Stress Detection
            let stressDetection = try stressDetectionModel.prediction(input: [
                "heartRateVariability": input.heartRateVariability,
                "respiratoryRate": input.respiratoryRate,
                "cortisolLevel": input.cortisolLevel,
                "sleepQuality": input.sleepQuality,
                "physicalActivity": input.physicalActivity,
                "screenTime": input.screenTime,
                "socialInteractions": input.socialInteractions,
                "workloadIntensity": input.workloadIntensity
            ])
            
            // Extract stress detection results
            let stressScore = stressDetection["stressScore"] as? Double ?? 0.5
            let stressLevel = determineStressLevel(score: stressScore)
            let triggerReasons = extractTriggerReasons(stressDetection)
            
            // Intervention Recommendation
            let interventionRecommendation = try interventionRecommendationModel.prediction(input: [
                "stressScore": stressScore,
                "stressLevel": stressLevel.rawValue
            ])
            
            let recommendedInterventions = extractInterventions(interventionRecommendation)
            
            let output = StressInterruptionOutput(
                stressLevel: stressLevel,
                stressScore: stressScore,
                triggerReasons: triggerReasons,
                recommendedInterventions: recommendedInterventions,
                immediateActionRequired: stressLevel == .high || stressLevel == .critical
            )
            
            stressDetectionPublisher.send(output)
            
            // Trigger notifications or interventions if needed
            handleStressInterruption(output)
        } catch {
            logger.error("Stress detection failed: \(error.localizedDescription)")
        }
    }
    
    /// Determine stress level based on stress score
    private func determineStressLevel(score: Double) -> StressInterruptionOutput.StressLevel {
        switch score {
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
    
    /// Extract trigger reasons from ML model output
    private func extractTriggerReasons(_ prediction: [String: Any]) -> [String] {
        // Simulated method - replace with actual ML model output
        var reasons: [String] = []
        
        if let workloadFactor = prediction["workloadFactor"] as? Double, workloadFactor > 0.7 {
            reasons.append("High workload intensity")
        }
        
        if let screenTimeFactor = prediction["screenTimeFactor"] as? Double, screenTimeFactor > 0.8 {
            reasons.append("Excessive screen time")
        }
        
        return reasons
    }
    
    /// Extract recommended interventions from ML model output
    private func extractInterventions(_ prediction: [String: Any]) -> [StressIntervention] {
        var interventions: [StressIntervention] = []
        
        // Breathing exercise intervention
        if let breathingRecommended = prediction["recommendBreathing"] as? Bool, breathingRecommended {
            interventions.append(StressIntervention(
                type: .breathing,
                duration: 300, // 5 minutes
                intensity: 0.6,
                description: "Guided deep breathing exercise to reduce stress"
            ))
        }
        
        // Meditation intervention
        if let meditationRecommended = prediction["recommendMeditation"] as? Bool, meditationRecommended {
            interventions.append(StressIntervention(
                type: .meditation,
                duration: 600, // 10 minutes
                intensity: 0.7,
                description: "Mindfulness meditation to calm the mind"
            ))
        }
        
        // Physical activity intervention
        if let exerciseRecommended = prediction["recommendExercise"] as? Bool, exerciseRecommended {
            interventions.append(StressIntervention(
                type: .physicalActivity,
                duration: 1200, // 20 minutes
                intensity: 0.5,
                description: "Light to moderate physical activity to reduce stress"
            ))
        }
        
        return interventions
    }
    
    /// Handle stress interruption based on detected stress level
    private func handleStressInterruption(_ output: StressInterruptionOutput) {
        switch output.stressLevel {
        case .low, .moderate:
            // Soft interventions, optional notifications
            sendSoftInterventionNotification(output)
        case .high, .critical:
            // Urgent interventions, immediate notifications
            sendUrgentInterventionNotification(output)
            triggerImmediateIntervention(output)
        }
    }
    
    /// Send soft intervention notification
    private func sendSoftInterventionNotification(_ output: StressInterruptionOutput) {
        let content = UNMutableNotificationContent()
        content.title = "Stress Management Suggestion"
        content.body = "Consider taking a short break or trying a relaxation technique."
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Send urgent intervention notification
    private func sendUrgentInterventionNotification(_ output: StressInterruptionOutput) {
        let content = UNMutableNotificationContent()
        content.title = "High Stress Alert"
        content.body = "Your stress levels are elevated. Immediate intervention recommended."
        content.sound = .critical
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Trigger immediate intervention for high stress
    private func triggerImmediateIntervention(_ output: StressInterruptionOutput) {
        // In a real implementation, this could pause work apps, 
        // launch a guided meditation, or trigger other stress-reduction mechanisms
        logger.info("Triggering immediate stress intervention")
    }
    
    /// Setup notification authorization
    private func setupNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification authorization granted")
            } else {
                print("Notification authorization denied")
            }
        }
    }
    
    // MARK: - Simulation Methods (to be replaced with real data collection)
    
    private func simulateRespiratoryRate() -> Double {
        return Double.random(in: 12.0...20.0)
    }
    
    private func simulateCortisolLevel() -> Double {
        return Double.random(in: 0.0...1.0)
    }
    
    private func simulateSleepQuality() -> Double {
        return Double.random(in: 0.0...1.0)
    }
    
    private func simulatePhysicalActivity() -> Double {
        return Double.random(in: 0.0...1.0)
    }
    
    private func simulateScreenTime() -> Double {
        return Double.random(in: 0.0...1.0)
    }
    
    private func simulateSocialInteractions() -> Double {
        return Double.random(in: 0.0...1.0)
    }
    
    private func simulateWorkloadIntensity() -> Double {
        return Double.random(in: 0.0...1.0)
    }
    
    // MARK: - Public Interface
    
    /// Subscribe to stress detection updates
    public func subscribeToStressDetection() -> AnyPublisher<StressInterruptionOutput, Never> {
        return stressDetectionPublisher.eraseToAnyPublisher()
    }
    
    /// Manually trigger stress detection
    public func detectStress() {
        let baseInput = StressDetectionInput(
            heartRateVariability: simulateHeartRateVariability(),
            respiratoryRate: simulateRespiratoryRate(),
            cortisolLevel: simulateCortisolLevel(),
            sleepQuality: simulateSleepQuality(),
            physicalActivity: simulatePhysicalActivity(),
            screenTime: simulateScreenTime(),
            socialInteractions: simulateSocialInteractions(),
            workloadIntensity: simulateWorkloadIntensity()
        )
        
        detectAndInterruptStress(input: baseInput)
    }
    
    /// Simulate heart rate variability
    private func simulateHeartRateVariability() -> Double {
        return Double.random(in: 20.0...100.0)
    }
    
    /// Update user preferences for stress management
    public func updateUserPreferences(_ preferences: [String: Any]) {
        userPreferences.merge(preferences) { (_, new) in new }
    }
} 