import Foundation
import SwiftUI
import HealthKit
import UserNotifications
import CoreHaptics
import AVFoundation
import CoreLocation
import HomeKit
import os.log

/// SleepFeedbackEngine - Closed-loop feedback system for real-time sleep optimization
@MainActor
class SleepFeedbackEngine: ObservableObject {
    static let shared = SleepFeedbackEngine()
    
    // MARK: - Published Properties
    @Published var isActive = false
    @Published var currentInterventions: [SleepIntervention] = []
    @Published var feedbackHistory: [FeedbackEvent] = []
    @Published var adaptationLevel: Double = 0.0
    @Published var interventionEffectiveness: [InterventionType: Double] = [:]
    
    // MARK: - Private Properties
    private var sleepManager = SleepManager.shared
    private var healthKitManager = HealthKitManager.shared
    private var aiSleepEngine = AISleepAnalysisEngine.shared
    private var analytics = SleepAnalyticsEngine.shared
    
    // Intervention systems
    private var notificationManager = SleepNotificationManager()
    private var hapticEngine: CHHapticEngine?
    private var audioTherapy = AudioTherapyEngine()
    private var environmentController = SmartEnvironmentController()
    private var alarmSystem = SmartAlarmSystem()
    
    // Feedback loop components
    private var interventionQueue: [SleepIntervention] = []
    private var activeInterventions: Set<UUID> = []
    private var interventionTimer: Timer?
    private var effectivenessTracker = InterventionEffectivenessTracker()
    
    // Configuration
    private let maxConcurrentInterventions = 3
    private let feedbackLoopInterval: TimeInterval = 30.0 // 30 seconds
    private let adaptationThreshold: Double = 0.7
    private let maxInterventionHistory = 1000
    
    private init() {
        setupFeedbackEngine()
    }
    
    // MARK: - Setup
    private func setupFeedbackEngine() {
        setupHapticEngine()
        setupNotificationManager()
        loadInterventionEffectiveness()
        Logger.success("Sleep feedback engine initialized", log: Logger.sleepManager)
    }
    
    private func setupHapticEngine() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            Logger.info("Haptic engine initialized", log: Logger.sleepManager)
        } catch {
            Logger.error("Failed to initialize haptic engine: \(error.localizedDescription)", log: Logger.sleepManager)
        }
    }
    
    private func setupNotificationManager() {
        notificationManager.requestAuthorization()
    }
    
    // MARK: - Feedback Loop Control
    func startFeedbackLoop() async {
        guard !isActive else { return }
        
        isActive = true
        Logger.info("Starting sleep feedback loop", log: Logger.sleepManager)
        
        // Start the main feedback timer
        interventionTimer = Timer.scheduledTimer(withTimeInterval: feedbackLoopInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.runFeedbackCycle()
            }
        }
        
        // Initial assessment
        await runFeedbackCycle()
    }
    
    func stopFeedbackLoop() async {
        guard isActive else { return }
        
        isActive = false
        interventionTimer?.invalidate()
        interventionTimer = nil
        
        // Stop all active interventions
        await stopAllInterventions()
        
        // Save effectiveness data
        saveInterventionEffectiveness()
        
        Logger.info("Sleep feedback loop stopped", log: Logger.sleepManager)
    }
    
    // MARK: - Main Feedback Cycle
    private func runFeedbackCycle() async {
        // Step 1: Collect current sleep data
        let currentData = await collectCurrentSleepData()
        
        // Step 2: Analyze sleep state using AI
        let sleepAnalysis = await analyzeSleepState(currentData)
        
        // Step 3: Assess intervention effectiveness
        await assessInterventionEffectiveness(currentData, sleepAnalysis)
        
        // Step 4: Determine needed interventions
        let neededInterventions = await determineNeededInterventions(sleepAnalysis)
        
        // Step 5: Execute interventions
        await executeInterventions(neededInterventions)
        
        // Step 6: Update adaptation level
        updateAdaptationLevel(sleepAnalysis)
        
        // Step 7: Log feedback event
        logFeedbackEvent(currentData, sleepAnalysis, neededInterventions)
    }
    
    // MARK: - Data Collection
    private func collectCurrentSleepData() async -> SleepDataSnapshot {
        let biometricData = healthKitManager.biometricData ?? BiometricData()
        let sleepStage = sleepManager.currentSleepStage
        let environmentData = await environmentController.getCurrentEnvironmentData()
        
        return SleepDataSnapshot(
            timestamp: Date(),
            biometricData: biometricData,
            sleepStage: sleepStage,
            environmentData: environmentData,
            isMonitoring: sleepManager.isMonitoring
        )
    }
    
    // MARK: - Sleep State Analysis
    private func analyzeSleepState(_ data: SleepDataSnapshot) async -> SleepStateAnalysis {
        // Use AI engine for comprehensive analysis
        let features = SleepFeatures(
            heartRate: data.biometricData.heartRate,
            hrv: data.biometricData.hrv,
            movement: data.biometricData.movement,
            bloodOxygen: data.biometricData.oxygenSaturation,
            temperature: data.environmentData.temperature,
            breathingRate: data.biometricData.respiratoryRate,
            timeOfNight: calculateTimeOfNight(),
            previousStage: data.sleepStage
        )
        
        let aiPrediction = await aiSleepEngine.predictSleepStage(features)
        
        // Analyze sleep quality trends
        let qualityTrend = await analytics.analyzeSleepPatterns()
        
        // Detect anomalies
        let anomalies = detectSleepAnomalies(data, aiPrediction)
        
        // Calculate intervention urgency
        let urgency = calculateInterventionUrgency(data, aiPrediction, anomalies)
        
        return SleepStateAnalysis(
            currentStage: aiPrediction.sleepStage,
            predictedStage: aiPrediction.sleepStage,
            confidence: aiPrediction.confidence,
            sleepQuality: aiPrediction.sleepQuality,
            qualityTrend: qualityTrend.sleepQualityTrend,
            anomalies: anomalies,
            urgency: urgency,
            recommendations: aiPrediction.recommendations
        )
    }
    
    // MARK: - Intervention Determination
    private func determineNeededInterventions(_ analysis: SleepStateAnalysis) async -> [SleepIntervention] {
        var interventions: [SleepIntervention] = []
        
        // High urgency interventions
        if analysis.urgency >= 0.8 {
            interventions.append(contentsOf: await getHighUrgencyInterventions(analysis))
        }
        
        // Medium urgency interventions
        if analysis.urgency >= 0.5 {
            interventions.append(contentsOf: await getMediumUrgencyInterventions(analysis))
        }
        
        // Low urgency interventions (optimization)
        if analysis.urgency >= 0.2 {
            interventions.append(contentsOf: await getLowUrgencyInterventions(analysis))
        }
        
        // Preventive interventions
        interventions.append(contentsOf: await getPreventiveInterventions(analysis))
        
        // Filter based on effectiveness and user preferences
        let filteredInterventions = await filterInterventions(interventions, analysis: analysis)
        
        // Limit concurrent interventions
        return Array(filteredInterventions.prefix(maxConcurrentInterventions))
    }
    
    private func getHighUrgencyInterventions(_ analysis: SleepStateAnalysis) async -> [SleepIntervention] {
        var interventions: [SleepIntervention] = []
        
        // Sleep disruption alerts
        if analysis.anomalies.contains(.severeDisruption) {
            interventions.append(SleepIntervention(
                id: UUID(),
                type: .immediateAlert,
                priority: .critical,
                trigger: .sleepDisruption,
                action: .hapticAlert,
                parameters: ["intensity": 0.8, "duration": 2.0],
                expectedEffect: .wakeUpGently
            ))
        }
        
        // Emergency health alerts
        if analysis.anomalies.contains(.healthConcern) {
            interventions.append(SleepIntervention(
                id: UUID(),
                type: .healthAlert,
                priority: .critical,
                trigger: .healthAnomaly,
                action: .notification,
                parameters: ["message": "Sleep health concern detected", "urgent": true],
                expectedEffect: .healthAwareness
            ))
        }
        
        return interventions
    }
    
    private func getMediumUrgencyInterventions(_ analysis: SleepStateAnalysis) async -> [SleepIntervention] {
        var interventions: [SleepIntervention] = []
        
        // Sleep stage optimization
        if analysis.currentStage != analysis.predictedStage {
            interventions.append(SleepIntervention(
                id: UUID(),
                type: .stageOptimization,
                priority: .medium,
                trigger: .stageTransition,
                action: .audioTherapy,
                parameters: ["frequency": getOptimalFrequency(for: analysis.predictedStage)],
                expectedEffect: .stageTransition
            ))
        }
        
        // Environment adjustments
        if analysis.anomalies.contains(.environmentIssue) {
            interventions.append(SleepIntervention(
                id: UUID(),
                type: .environmentAdjustment,
                priority: .medium,
                trigger: .environmentAnomaly,
                action: .adjustEnvironment,
                parameters: await getEnvironmentAdjustments(analysis),
                expectedEffect: .environmentOptimization
            ))
        }
        
        return interventions
    }
    
    private func getLowUrgencyInterventions(_ analysis: SleepStateAnalysis) async -> [SleepIntervention] {
        var interventions: [SleepIntervention] = []
        
        // Sleep quality enhancement
        if analysis.sleepQuality < 0.7 {
            interventions.append(SleepIntervention(
                id: UUID(),
                type: .qualityEnhancement,
                priority: .low,
                trigger: .qualityImprovement,
                action: .breathingGuidance,
                parameters: ["pattern": "4-7-8", "duration": 300],
                expectedEffect: .relaxation
            ))
        }
        
        return interventions
    }
    
    private func getPreventiveInterventions(_ analysis: SleepStateAnalysis) async -> [SleepIntervention] {
        var interventions: [SleepIntervention] = []
        
        // Smart wake preparation (if approaching wake time)
        if isApproachingWakeTime() {
            interventions.append(SleepIntervention(
                id: UUID(),
                type: .smartWake,
                priority: .low,
                trigger: .timeBasedOptimization,
                action: .gradualWake,
                parameters: ["lightIntensity": 0.1, "duration": 1800], // 30 minutes
                expectedEffect: .gentleWake
            ))
        }
        
        return interventions
    }
    
    // MARK: - Intervention Execution
    private func executeInterventions(_ interventions: [SleepIntervention]) async {
        for intervention in interventions {
            // Check if intervention is already active
            guard !activeInterventions.contains(intervention.id) else { continue }
            
            // Execute intervention
            await executeIntervention(intervention)
            
            // Track active intervention
            activeInterventions.insert(intervention.id)
            currentInterventions.append(intervention)
            
            // Schedule intervention completion
            scheduleInterventionCompletion(intervention)
        }
    }
    
    private func executeIntervention(_ intervention: SleepIntervention) async {
        Logger.info("Executing intervention: \(intervention.type)", log: Logger.sleepManager)
        
        switch intervention.action {
        case .hapticAlert:
            await executeHapticIntervention(intervention)
        case .audioTherapy:
            await executeAudioIntervention(intervention)
        case .notification:
            await executeNotificationIntervention(intervention)
        case .adjustEnvironment:
            await executeEnvironmentIntervention(intervention)
        case .breathingGuidance:
            await executeBreathingIntervention(intervention)
        case .gradualWake:
            await executeGradualWakeIntervention(intervention)
        }
    }
    
    private func executeHapticIntervention(_ intervention: SleepIntervention) async {
        guard let hapticEngine = hapticEngine else { return }
        
        let intensity = intervention.parameters["intensity"] as? Double ?? 0.5
        let duration = intervention.parameters["duration"] as? Double ?? 1.0
        
        do {
            let events = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0
                )
            ]
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            
            // Schedule stop
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                try? player.stop(atTime: 0)
            }
            
        } catch {
            Logger.error("Haptic intervention failed: \(error.localizedDescription)", log: Logger.sleepManager)
        }
    }
    
    private func executeAudioIntervention(_ intervention: SleepIntervention) async {
        let frequency = intervention.parameters["frequency"] as? Double ?? 432.0
        await audioTherapy.playTherapeuticAudio(frequency: frequency, duration: 300)
    }
    
    private func executeNotificationIntervention(_ intervention: SleepIntervention) async {
        let message = intervention.parameters["message"] as? String ?? "Sleep intervention"
        let urgent = intervention.parameters["urgent"] as? Bool ?? false
        
        await notificationManager.sendSleepNotification(
            title: "Sleep Optimization",
            body: message,
            urgent: urgent
        )
    }
    
    private func executeEnvironmentIntervention(_ intervention: SleepIntervention) async {
        await environmentController.applyOptimalSettings(intervention.parameters)
    }
    
    private func executeBreathingIntervention(_ intervention: SleepIntervention) async {
        let pattern = intervention.parameters["pattern"] as? String ?? "4-7-8"
        let duration = intervention.parameters["duration"] as? Double ?? 300
        
        await audioTherapy.playBreathingGuidance(pattern: pattern, duration: duration)
    }
    
    private func executeGradualWakeIntervention(_ intervention: SleepIntervention) async {
        let lightIntensity = intervention.parameters["lightIntensity"] as? Double ?? 0.1
        let duration = intervention.parameters["duration"] as? Double ?? 1800
        
        await environmentController.startGradualWake(
            lightIntensity: lightIntensity,
            duration: duration
        )
    }
    
    // MARK: - Intervention Management
    private func scheduleInterventionCompletion(_ intervention: SleepIntervention) {
        let completionTime = intervention.parameters["duration"] as? Double ?? 60.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + completionTime) { [weak self] in
            Task { @MainActor in
                await self?.completeIntervention(intervention.id)
            }
        }
    }
    
    private func completeIntervention(_ interventionId: UUID) async {
        activeInterventions.remove(interventionId)
        currentInterventions.removeAll { $0.id == interventionId }
        
        Logger.info("Intervention completed: \(interventionId)", log: Logger.sleepManager)
    }
    
    private func stopAllInterventions() async {
        for intervention in currentInterventions {
            await completeIntervention(intervention.id)
        }
        
        await audioTherapy.stopAllAudio()
        await environmentController.resetToDefault()
    }
    
    // MARK: - Effectiveness Assessment
    private func assessInterventionEffectiveness(_ currentData: SleepDataSnapshot, _ analysis: SleepStateAnalysis) async {
        for intervention in currentInterventions {
            let effectiveness = await calculateInterventionEffectiveness(intervention, currentData, analysis)
            effectivenessTracker.recordEffectiveness(intervention.type, effectiveness: effectiveness)
            
            // Update global effectiveness map
            let currentEffectiveness = interventionEffectiveness[intervention.type] ?? 0.5
            interventionEffectiveness[intervention.type] = (currentEffectiveness * 0.8) + (effectiveness * 0.2)
        }
    }
    
    private func calculateInterventionEffectiveness(_ intervention: SleepIntervention, _ data: SleepDataSnapshot, _ analysis: SleepStateAnalysis) async -> Double {
        // Calculate effectiveness based on intervention type and expected outcome
        switch intervention.expectedEffect {
        case .stageTransition:
            return analysis.currentStage == analysis.predictedStage ? 1.0 : 0.3
        case .relaxation:
            return data.biometricData.heartRate < 65 ? 0.8 : 0.4
        case .environmentOptimization:
            return analysis.anomalies.contains(.environmentIssue) ? 0.2 : 0.9
        case .gentleWake:
            return analysis.sleepQuality > 0.7 ? 0.9 : 0.5
        case .healthAwareness:
            return 0.8 // Hard to measure but assume effective
        case .wakeUpGently:
            return sleepManager.currentSleepStage == .awake ? 0.9 : 0.1
        }
    }
    
    // MARK: - Utility Methods
    private func calculateTimeOfNight() -> Double {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        if hour >= 22 {
            return Double(hour - 22)
        } else if hour < 8 {
            return Double(hour + 2)
        } else {
            return 0.0
        }
    }
    
    private func detectSleepAnomalies(_ data: SleepDataSnapshot, _ prediction: SleepStagePrediction) -> Set<SleepAnomaly> {
        var anomalies: Set<SleepAnomaly> = []
        
        // Health-based anomalies
        if data.biometricData.heartRate > 100 || data.biometricData.heartRate < 40 {
            anomalies.insert(.healthConcern)
        }
        
        if data.biometricData.oxygenSaturation < 90 {
            anomalies.insert(.healthConcern)
        }
        
        // Sleep disruption anomalies
        if data.biometricData.movement > 0.8 && data.sleepStage != .awake {
            anomalies.insert(.severeDisruption)
        }
        
        // Environment anomalies
        if data.environmentData.temperature > 75 || data.environmentData.temperature < 65 {
            anomalies.insert(.environmentIssue)
        }
        
        if data.environmentData.noiseLevel > 50 {
            anomalies.insert(.environmentIssue)
        }
        
        return anomalies
    }
    
    private func calculateInterventionUrgency(_ data: SleepDataSnapshot, _ prediction: SleepStagePrediction, _ anomalies: Set<SleepAnomaly>) -> Double {
        var urgency = 0.0
        
        // Health concerns have highest urgency
        if anomalies.contains(.healthConcern) {
            urgency += 0.8
        }
        
        // Severe disruptions have high urgency
        if anomalies.contains(.severeDisruption) {
            urgency += 0.6
        }
        
        // Environment issues have medium urgency
        if anomalies.contains(.environmentIssue) {
            urgency += 0.4
        }
        
        // Low sleep quality increases urgency
        if prediction.sleepQuality < 0.4 {
            urgency += 0.3
        }
        
        // Low confidence in predictions increases urgency
        if prediction.confidence < 0.5 {
            urgency += 0.2
        }
        
        return min(1.0, urgency)
    }
    
    private func getOptimalFrequency(for stage: SleepStage) -> Double {
        switch stage {
        case .deep: return 0.5 // Delta waves
        case .light: return 8.0 // Alpha waves
        case .rem: return 40.0 // Gamma waves
        case .awake: return 15.0 // Beta waves
        }
    }
    
    private func getEnvironmentAdjustments(_ analysis: SleepStateAnalysis) async -> [String: Any] {
        var adjustments: [String: Any] = [:]
        
        // Temperature adjustments
        if analysis.anomalies.contains(.environmentIssue) {
            adjustments["targetTemperature"] = 68.0
        }
        
        // Lighting adjustments
        adjustments["lightLevel"] = 0.0
        
        // Sound adjustments
        adjustments["maxNoiseLevel"] = 35.0
        
        return adjustments
    }
    
    private func isApproachingWakeTime() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Assume wake time is around 7 AM
        return hour >= 6 && hour < 8
    }
    
    private func filterInterventions(_ interventions: [SleepIntervention], analysis: SleepStateAnalysis) async -> [SleepIntervention] {
        return interventions.filter { intervention in
            // Filter based on effectiveness
            let effectiveness = interventionEffectiveness[intervention.type] ?? 0.5
            
            // Only use interventions that have proven effective
            return effectiveness > 0.3
        }.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func updateAdaptationLevel(_ analysis: SleepStateAnalysis) {
        // Increase adaptation level based on successful interventions
        let successRate = effectivenessTracker.getAverageEffectiveness()
        adaptationLevel = min(1.0, adaptationLevel + (successRate - 0.5) * 0.1)
    }
    
    private func logFeedbackEvent(_ data: SleepDataSnapshot, _ analysis: SleepStateAnalysis, _ interventions: [SleepIntervention]) {
        let event = FeedbackEvent(
            timestamp: Date(),
            sleepStage: analysis.currentStage,
            sleepQuality: analysis.sleepQuality,
            urgency: analysis.urgency,
            interventionsExecuted: interventions.count,
            anomalies: analysis.anomalies
        )
        
        feedbackHistory.append(event)
        
        // Maintain history size
        if feedbackHistory.count > maxInterventionHistory {
            feedbackHistory.removeFirst()
        }
    }
    
    // MARK: - Persistence
    private func loadInterventionEffectiveness() {
        if let data = UserDefaults.standard.data(forKey: "interventionEffectiveness"),
           let effectiveness = try? JSONDecoder().decode([InterventionType: Double].self, from: data) {
            interventionEffectiveness = effectiveness
        }
    }
    
    private func saveInterventionEffectiveness() {
        if let data = try? JSONEncoder().encode(interventionEffectiveness) {
            UserDefaults.standard.set(data, forKey: "interventionEffectiveness")
        }
    }
    
    // MARK: - Public Interface
    func getStatusReport() -> FeedbackEngineStatus {
        return FeedbackEngineStatus(
            isActive: isActive,
            activeInterventions: currentInterventions.count,
            adaptationLevel: adaptationLevel,
            averageEffectiveness: effectivenessTracker.getAverageEffectiveness(),
            recentEvents: Array(feedbackHistory.suffix(10))
        )
    }
    
    func forceIntervention(_ type: InterventionType) async {
        let intervention = SleepIntervention(
            id: UUID(),
            type: type,
            priority: .medium,
            trigger: .manual,
            action: getActionForType(type),
            parameters: [:],
            expectedEffect: .relaxation
        )
        
        await executeIntervention(intervention)
    }
    
    private func getActionForType(_ type: InterventionType) -> InterventionAction {
        switch type {
        case .audioTherapy: return .audioTherapy
        case .environmentAdjustment: return .adjustEnvironment
        case .hapticFeedback: return .hapticAlert
        case .breathingExercise: return .breathingGuidance
        default: return .notification
        }
    }
}

// MARK: - Supporting Classes

class SleepNotificationManager {
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                Logger.info("Notification authorization granted", log: Logger.sleepManager)
            } else {
                Logger.warning("Notification authorization denied", log: Logger.sleepManager)
            }
        }
    }
    
    func sendSleepNotification(title: String, body: String, urgent: Bool = false) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = urgent ? .default : nil
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            Logger.error("Failed to send notification: \(error.localizedDescription)", log: Logger.sleepManager)
        }
    }
}

class AudioTherapyEngine {
    private var audioEngine = AVAudioEngine()
    private var isPlaying = false
    
    func playTherapeuticAudio(frequency: Double, duration: TimeInterval) async {
        // Implementation for playing therapeutic audio
        Logger.info("Playing therapeutic audio at \(frequency)Hz for \(duration)s", log: Logger.sleepManager)
    }
    
    func playBreathingGuidance(pattern: String, duration: TimeInterval) async {
        // Implementation for breathing guidance audio
        Logger.info("Playing breathing guidance: \(pattern) for \(duration)s", log: Logger.sleepManager)
    }
    
    func stopAllAudio() async {
        if isPlaying {
            audioEngine.stop()
            isPlaying = false
        }
    }
}

class SmartEnvironmentController {
    func getCurrentEnvironmentData() async -> EnvironmentData {
        return EnvironmentData(
            temperature: 70.0,
            humidity: 45.0,
            lightLevel: 0.1,
            noiseLevel: 25.0,
            airQuality: 95.0
        )
    }
    
    func applyOptimalSettings(_ parameters: [String: Any]) async {
        Logger.info("Applying environment adjustments", log: Logger.sleepManager)
    }
    
    func startGradualWake(lightIntensity: Double, duration: TimeInterval) async {
        Logger.info("Starting gradual wake with light intensity \(lightIntensity)", log: Logger.sleepManager)
    }
    
    func resetToDefault() async {
        Logger.info("Resetting environment to default settings", log: Logger.sleepManager)
    }
}

class InterventionEffectivenessTracker {
    private var effectivenessHistory: [InterventionType: [Double]] = [:]
    
    func recordEffectiveness(_ type: InterventionType, effectiveness: Double) {
        if effectivenessHistory[type] == nil {
            effectivenessHistory[type] = []
        }
        effectivenessHistory[type]?.append(effectiveness)
        
        // Keep only recent history
        if effectivenessHistory[type]!.count > 100 {
            effectivenessHistory[type]?.removeFirst()
        }
    }
    
    func getAverageEffectiveness() -> Double {
        let allEffectiveness = effectivenessHistory.values.flatMap { $0 }
        return allEffectiveness.isEmpty ? 0.5 : allEffectiveness.reduce(0, +) / Double(allEffectiveness.count)
    }
    
    func getEffectiveness(for type: InterventionType) -> Double {
        guard let history = effectivenessHistory[type], !history.isEmpty else { return 0.5 }
        return history.reduce(0, +) / Double(history.count)
    }
}

// MARK: - Data Models

struct SleepDataSnapshot {
    let timestamp: Date
    let biometricData: BiometricData
    let sleepStage: SleepStage
    let environmentData: EnvironmentData
    let isMonitoring: Bool
}

struct EnvironmentData {
    let temperature: Double
    let humidity: Double
    let lightLevel: Double
    let noiseLevel: Double
    let airQuality: Double
}

struct SleepStateAnalysis {
    let currentStage: SleepStage
    let predictedStage: SleepStage
    let confidence: Double
    let sleepQuality: Double
    let qualityTrend: TrendDirection
    let anomalies: Set<SleepAnomaly>
    let urgency: Double
    let recommendations: [SleepRecommendation]
}

enum SleepAnomaly: Hashable {
    case healthConcern
    case severeDisruption
    case environmentIssue
    case stageAbnormality
}

struct SleepIntervention: Identifiable {
    let id: UUID
    let type: InterventionType
    let priority: InterventionPriority
    let trigger: InterventionTrigger
    let action: InterventionAction
    let parameters: [String: Any]
    let expectedEffect: InterventionEffect
    
    // Make Hashable by using id
    static func == (lhs: SleepIntervention, rhs: SleepIntervention) -> Bool {
        lhs.id == rhs.id
    }
}

enum InterventionType: String, CaseIterable, Codable {
    case audioTherapy = "audioTherapy"
    case environmentAdjustment = "environmentAdjustment"
    case hapticFeedback = "hapticFeedback"
    case breathingExercise = "breathingExercise"
    case smartWake = "smartWake"
    case stageOptimization = "stageOptimization"
    case qualityEnhancement = "qualityEnhancement"
    case healthAlert = "healthAlert"
    case immediateAlert = "immediateAlert"
}

enum InterventionPriority: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

enum InterventionTrigger: String, CaseIterable {
    case healthAnomaly = "healthAnomaly"
    case sleepDisruption = "sleepDisruption"
    case environmentAnomaly = "environmentAnomaly"
    case stageTransition = "stageTransition"
    case qualityImprovement = "qualityImprovement"
    case timeBasedOptimization = "timeBasedOptimization"
    case manual = "manual"
}

enum InterventionAction: String, CaseIterable {
    case hapticAlert = "hapticAlert"
    case audioTherapy = "audioTherapy"
    case notification = "notification"
    case adjustEnvironment = "adjustEnvironment"
    case breathingGuidance = "breathingGuidance"
    case gradualWake = "gradualWake"
}

enum InterventionEffect: String, CaseIterable {
    case stageTransition = "stageTransition"
    case relaxation = "relaxation"
    case environmentOptimization = "environmentOptimization"
    case gentleWake = "gentleWake"
    case healthAwareness = "healthAwareness"
    case wakeUpGently = "wakeUpGently"
}

struct FeedbackEvent {
    let timestamp: Date
    let sleepStage: SleepStage
    let sleepQuality: Double
    let urgency: Double
    let interventionsExecuted: Int
    let anomalies: Set<SleepAnomaly>
}

struct FeedbackEngineStatus {
    let isActive: Bool
    let activeInterventions: Int
    let adaptationLevel: Double
    let averageEffectiveness: Double
    let recentEvents: [FeedbackEvent]
}