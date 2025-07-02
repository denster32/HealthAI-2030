import Foundation
import HealthKit
import Combine
import CoreML
import AVFoundation
import UIKit

class SleepOptimizationManager: ObservableObject {
    static let shared = SleepOptimizationManager()
    
    private var cancellables = Set<AnyCancellable>()
    private var audioEngine: AVAudioEngine?
    private var audioPlayer: AVAudioPlayerNode?
    
    // Published properties
    @Published var currentSleepStage: SleepStageType = .unknown
    @Published var sleepQuality: Double = 0.0
    @Published var deepSleepPercentage: Double = 0.0
    @Published var isOptimizationActive: Bool = false
    @Published var sleepMetrics: SleepMetrics = SleepMetrics()
    
    // Sleep stage transformer model
    private var sleepStageModel: MLModel?
    
    private init() {
        // Audio engine setup is now handled by AdaptiveAudioManager
        loadSleepStageModel()
        startSleepMonitoring()
    }
    
    // MARK: - Sleep Stage Detection
    
    func startSleepMonitoring() {
        // Start monitoring sleep patterns
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.analyzeSleepStage()
            }
            .store(in: &cancellables)
    }
    
    private func analyzeSleepStage() {
        // Analyze current sleep stage using ML model
        guard let model = sleepStageModel else { return }
        
        // Get current sensor data
        let heartRate = HealthDataManager.shared.currentHeartRate
        let hrv = HealthDataManager.shared.currentHRV
        let oxygenSaturation = HealthDataManager.shared.currentOxygenSaturation
        let bodyTemperature = HealthDataManager.shared.currentBodyTemperature
        
        // Create input for ML model
        let input = createSleepStageInput(
            heartRate: heartRate,
            hrv: hrv,
            oxygenSaturation: oxygenSaturation,
            bodyTemperature: bodyTemperature
        )
        
        // Predict sleep stage
        predictSleepStage(with: input)
    }
    
    private func createSleepStageInput(heartRate: Double, hrv: Double, oxygenSaturation: Double, bodyTemperature: Double) -> [Double] {
        // Create feature vector for sleep stage prediction
        return [
            heartRate,
            hrv,
            oxygenSaturation,
            bodyTemperature,
            Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 86400) // Time of day
        ]
    }
    
    private func predictSleepStage(with input: [Double]) {
        // Use ML model to predict sleep stage
        // This is a simplified implementation
        let prediction = performSleepStagePrediction(input: input)
        
        DispatchQueue.main.async {
            self.currentSleepStage = prediction
            self.updateSleepMetrics()
            self.triggerInterventionsIfNeeded()
        }
    }
    
    private func performSleepStagePrediction(input: [Double]) -> SleepStageType {
        // Simplified sleep stage prediction logic
        // In a real implementation, this would use the ML model
        
        let heartRate = input[0]
        let hrv = input[1]
        
        // Simple rule-based classification for demo
        if heartRate < 60 && hrv > 50 {
            return .deepSleep
        } else if heartRate < 70 && hrv > 30 {
            return .lightSleep
        } else if heartRate > 80 {
            return .remSleep
        } else {
            return .awake
        }
    }
    
    // MARK: - Sleep Interventions
    
    private func triggerInterventionsIfNeeded() {
        // Get current environment data
        let currentEnvironment = EnvironmentManager.shared.getCurrentEnvironment()
        
        // Create SleepState from current data
        let sleepState = SleepState(
            stage: convertToRLAgentSleepStage(currentSleepStage),
            hrv: HealthDataManager.shared.currentHRV,
            heartRate: HealthDataManager.shared.currentHeartRate,
            timeInStage: sleepMetrics.totalSleepTime
        )
        
        // Create EnvironmentData from current environment
        let environmentData = EnvironmentData(
            temperature: currentEnvironment.temperature,
            humidity: currentEnvironment.humidity,
            noiseLevel: currentEnvironment.noiseLevel / 100.0, // Convert to 0-1 scale
            lightLevel: currentEnvironment.lightLevel / 100.0, // Convert to 0-1 scale
            bedIncline: BedMotorManager.shared.currentHeadElevation
        )
        
        // Get nudge decision from RLAgent
        if let nudgeAction = RLAgent.shared.decideNudge(sleepState: sleepState, environment: environmentData) {
            triggerNudge(action: nudgeAction)
        }
    }
    
    private func convertToRLAgentSleepStage(_ stage: SleepStageType) -> SleepStage {
        switch stage {
        case .awake:
            return .awake
        case .lightSleep:
            return .light
        case .deepSleep:
            return .deep
        case .remSleep:
            return .rem
        case .unknown:
            return .awake
        }
    }

    private func triggerNudge(action: NudgeAction) {
        print("RLAgent triggered nudge: \(action.reason)")
        
        switch action.type {
        case .audio(let audioType):
            switch audioType {
            case .pinkNoise:
                AdaptiveAudioManager.shared.playPinkNoise()
            case .isochronicTones:
                AdaptiveAudioManager.shared.playIsochronicTones()
            case .binauralBeats:
                AdaptiveAudioManager.shared.playBinauralBeats()
            case .natureSounds:
                AdaptiveAudioManager.shared.playNatureSounds()
            }
            
        case .haptic(let hapticType):
            switch hapticType {
            case .gentlePulse:
                triggerHapticPulse(intensity: 0.3)
            case .strongPulse:
                triggerHapticPulse(intensity: 0.8)
            }
            
        case .environment(let envType):
            performEnvironmentNudge(envType)
            
        case .bedMotor(let bedType):
            performBedMotorNudge(bedType)
        }
        
        // Record the intervention
        DispatchQueue.main.async {
            self.sleepMetrics.interventions.append(action)
        }
    }
    
    private func performEnvironmentNudge(_ envType: EnvironmentNudgeType) {
        switch envType {
        case .lowerTemperature(let target):
            EnvironmentManager.shared.adjustTemperature(target: target)
        case .raiseHumidity(let target):
            EnvironmentManager.shared.adjustHumidity(target: target)
        case .dimLights(let level):
            EnvironmentManager.shared.adjustLighting(intensity: level)
        case .closeBlinds(let position):
            EnvironmentManager.shared.adjustBlinds(position: position)
        case .startHEPAFilter:
            EnvironmentManager.shared.setHEPAFilterState(on: true, mode: .auto)
        case .stopHEPAFilter:
            EnvironmentManager.shared.setHEPAFilterState(on: false, mode: .off)
        }
    }
    
    private func performBedMotorNudge(_ bedType: BedMotorNudgeType) {
        switch bedType {
        case .adjustHead(let elevation):
            BedMotorManager.shared.adjustHeadElevation(to: elevation)
        case .adjustFoot(let elevation):
            BedMotorManager.shared.adjustFootElevation(to: elevation)
        case .startMassage(let intensity):
            BedMotorManager.shared.startMassage(intensity: intensity)
        case .stopMassage:
            BedMotorManager.shared.stopMassage()
        }
    }
    
    private func triggerHapticPulse(intensity: Double) {
        // Trigger haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred(intensity: Float(intensity))
        
        print("Haptic pulse triggered with intensity: \(intensity)")
    }

    private func performEnvironmentAction(_ action: EnvironmentOptimizationType) {
        switch action {
        case .optimizeForDeepSleep:
            EnvironmentManager.shared.optimizeForSleep()
        case .optimizeForREM:
            EnvironmentManager.shared.optimizeForSleep() // Assuming sleep optimization covers REM for now
        case .adjustLighting(let intensity):
            EnvironmentManager.shared.adjustLighting(intensity: intensity)
        case .adjustTemperature(let target):
            EnvironmentManager.shared.adjustTemperature(target: target)
        case .adjustHumidity(let target):
            EnvironmentManager.shared.adjustHumidity(target: target)
        case .adjustBlinds(let position):
            EnvironmentManager.shared.adjustBlinds(position: position)
        case .setHEPAFilterState(let on, let mode):
            EnvironmentManager.shared.setHEPAFilterState(on: on, mode: mode)
        case .setSmartMattressHeaterCooler(let on, let temperature):
            EnvironmentManager.shared.setSmartMattressHeaterCooler(on: on, temperature: temperature)
        }
    }

    private func performBedMotorAction(_ action: BedMotorAction) {
        switch action {
        case .adjustHeadElevation(let elevation):
            BedMotorManager.shared.adjustHeadElevation(to: elevation)
        case .adjustFootElevation(let elevation):
            BedMotorManager.shared.adjustFootElevation(to: elevation)
        case .startMassage(let intensity):
            BedMotorManager.shared.startMassage(intensity: intensity)
        case .stopMassage:
            BedMotorManager.shared.stopMassage()
        }
    }

    // MARK: - Audio Engine Setup (Moved to AdaptiveAudioManager)
    private func setupAudioEngine() {
        // Audio engine setup is now handled by AdaptiveAudioManager
    }

    // MARK: - ML Model Management
    private func loadSleepStageModel() {
        // Load the sleep stage prediction model
        // In a real implementation, this would load a Core ML model
        print("Loading sleep stage model...")
    }

    // MARK: - Metrics and Analytics
    private func updateSleepMetrics() {
        // Update sleep quality metrics
        let quality = calculateSleepQuality()
        let deepSleepPercentage = calculateDeepSleepPercentage()

        DispatchQueue.main.async {
            self.sleepQuality = quality
            self.deepSleepPercentage = deepSleepPercentage
        }
    }

    private func calculateSleepQuality() -> Double {
        // Calculate sleep quality based on various factors
        // This is a simplified calculation
        let hrv = HealthDataManager.shared.currentHRV
        let heartRate = HealthDataManager.shared.currentHeartRate

        let hrvScore = min(hrv / 100.0, 1.0)
        let heartRateScore = max(0, 1.0 - (heartRate - 60) / 40)

        return (hrvScore + heartRateScore) / 2.0
    }

    private func calculateDeepSleepPercentage() -> Double {
        // Calculate percentage of time spent in deep sleep
        // This would be based on historical data
        return 0.25 // Simplified for demo
    }

    // MARK: - Public Interface
    func startOptimization() {
        isOptimizationActive = true
        print("Sleep optimization started")
    }

    func stopOptimization() {
        isOptimizationActive = false
        // Stop any active nudges
        AdaptiveAudioManager.shared.stopAudio()
        BedMotorManager.shared.stopMassage()
        EnvironmentManager.shared.stopOptimization()
        print("Sleep optimization stopped")
    }

    func getSleepReport() -> SleepReport {
        return SleepReport(
            date: Date(),
            totalSleepTime: sleepMetrics.totalSleepTime,
            deepSleepPercentage: deepSleepPercentage,
            remSleepPercentage: sleepMetrics.remSleepPercentage,
            sleepQuality: sleepQuality,
            interventions: sleepMetrics.interventions
        )
    }
}

// MARK: - Supporting Classes and Models

struct SleepMetrics {
    var totalSleepTime: TimeInterval = 0
    var deepSleepTime: TimeInterval = 0
    var remSleepTime: TimeInterval = 0
    var lightSleepTime: TimeInterval = 0
    var awakeTime: TimeInterval = 0
    var remSleepPercentage: Double = 0
    var interventions: [NudgeAction] = [] // Changed to NudgeAction
    
    // Computed properties for percentages
    var deepSleepPercentage: Double {
        guard totalSleepTime > 0 else { return 0 }
        return deepSleepTime / totalSleepTime
    }
    
    var lightSleepPercentage: Double {
        guard totalSleepTime > 0 else { return 0 }
        return lightSleepTime / totalSleepTime
    }
    
    var awakePercentage: Double {
        guard totalSleepTime > 0 else { return 0 }
        return awakeTime / totalSleepTime
    }
    
    // Update percentages when times change
    mutating func updatePercentages() {
        if totalSleepTime > 0 {
            remSleepPercentage = remSleepTime / totalSleepTime
        }
    }
    
    // Add time to a specific stage
    mutating func addTime(_ time: TimeInterval, to stage: SleepStageType) {
        switch stage {
        case .deepSleep:
            deepSleepTime += time
        case .remSleep:
            remSleepTime += time
        case .lightSleep:
            lightSleepTime += time
        case .awake:
            awakeTime += time
        case .unknown:
            awakeTime += time // Default to awake for unknown
        }
        totalSleepTime += time
        updatePercentages()
    }
}

struct SleepReport {
    let date: Date
    let totalSleepTime: TimeInterval
    let deepSleepPercentage: Double
    let remSleepPercentage: Double
    let sleepQuality: Double
    let interventions: [NudgeAction] // Changed to NudgeAction
}