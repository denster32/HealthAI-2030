import Foundation
import HealthKit
import Combine
import CoreML
import AVFoundation
import UIKit

class SleepOptimizationManager: ObservableObject {
    static let shared = SleepOptimizationManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Published properties
    @Published var currentSleepStage: SleepStageType = .unknown
    @Published var sleepQuality: Double = 0.0
    @Published var deepSleepPercentage: Double = 0.0
    @Published var isOptimizationActive: Bool = false
    @Published var sleepMetrics: SleepMetrics = SleepMetrics()
    
    // Sleep stage transformer model
    private var sleepStageModel: MLModel?
    
    private init() {
        loadSleepStageModel()
        startSleepMonitoring()
    }
    
    // MARK: - Sleep Stage Detection
    
    func startSleepMonitoring() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.analyzeSleepStage()
            }
            .store(in: &cancellables)
    }
    
    private func analyzeSleepStage() {
        guard let model = sleepStageModel else { return }
        
        let heartRate = HealthDataManager.shared.currentHeartRate
        let hrv = HealthDataManager.shared.currentHRV
        let oxygenSaturation = HealthDataManager.shared.currentOxygenSaturation
        let bodyTemperature = HealthDataManager.shared.currentBodyTemperature
        
        let input = createSleepStageInput(
            heartRate: heartRate,
            hrv: hrv,
            oxygenSaturation: oxygenSaturation,
            bodyTemperature: bodyTemperature
        )
        
        predictSleepStage(with: input)
    }
    
    private func createSleepStageInput(heartRate: Double, hrv: Double, oxygenSaturation: Double, bodyTemperature: Double) -> [Double] {
        return [
            heartRate,
            hrv,
            oxygenSaturation,
            bodyTemperature,
            Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 86400)
        ]
    }
    
    private func predictSleepStage(with input: [Double]) {
        let prediction = performSleepStagePrediction(input: input)
        
        DispatchQueue.main.async {
            self.currentSleepStage = prediction
            self.sleepMetrics.addTime(30, to: prediction) // Assuming 30-second intervals
            self.updateSleepMetrics()
            self.triggerInterventionsIfNeeded()
        }
    }
    
    private func performSleepStagePrediction(input: [Double]) -> SleepStageType {
        let heartRate = input[0]
        let hrv = input[1]
        
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
        let currentEnvironment = EnvironmentManager.shared.getCurrentEnvironment()
        
        let sleepState = SleepState(
            stage: convertToRLAgentSleepStage(currentSleepStage),
            hrv: HealthDataManager.shared.currentHRV,
            heartRate: HealthDataManager.shared.currentHeartRate,
            timeInStage: sleepMetrics.totalSleepTime
        )
        
        let environmentData = EnvironmentData(
            temperature: currentEnvironment.temperature,
            humidity: currentEnvironment.humidity,
            noiseLevel: currentEnvironment.noiseLevel / 100.0,
            lightLevel: currentEnvironment.lightLevel / 100.0,
            bedIncline: BedMotorManager.shared.currentHeadElevation
        )
        
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
                AdaptiveAudioManager.shared.applyHapticNudge(intensity: 0.3)
            case .strongPulse:
                AdaptiveAudioManager.shared.applyHapticNudge(intensity: 0.8)
            }
            
        case .environment(let envType):
            performEnvironmentNudge(envType)
            
        case .bedMotor(let bedType):
            performBedMotorNudge(bedType)
        }
        
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
    
    // MARK: - ML Model Management
    private func loadSleepStageModel() {
        print("Loading sleep stage model...")
    }

    // MARK: - Metrics and Analytics
    private func updateSleepMetrics() {
        let quality = calculateSleepQuality()
        let deepSleepPercentage = sleepMetrics.deepSleepPercentage
        let remSleepPercentage = sleepMetrics.remSleepPercentage

        DispatchQueue.main.async {
            self.sleepQuality = quality
            self.deepSleepPercentage = deepSleepPercentage
            self.sleepMetrics.remSleepPercentage = remSleepPercentage // Ensure this is updated
        }
    }

    private func calculateSleepQuality() -> Double {
        let hrv = HealthDataManager.shared.currentHRV
        let heartRate = HealthDataManager.shared.currentHeartRate

        let hrvScore = min(hrv / 100.0, 1.0)
        let heartRateScore = max(0, 1.0 - (heartRate - 60) / 40)

        return (hrvScore + heartRateScore) / 2.0
    }

    // MARK: - Public Interface
    func startOptimization() {
        isOptimizationActive = true
        print("Sleep optimization started")
    }

    func stopOptimization() {
        isOptimizationActive = false
        AdaptiveAudioManager.shared.stopAudio()
        BedMotorManager.shared.stopMassage()
        EnvironmentManager.shared.stopOptimization()
        print("Sleep optimization stopped")
    }

    func getSleepReport() -> SleepReport {
        return SleepReport(
            date: Date(),
            totalSleepTime: sleepMetrics.totalSleepTime,
            deepSleepPercentage: sleepMetrics.deepSleepPercentage,
            remSleepPercentage: sleepMetrics.remSleepPercentage,
            sleepQuality: sleepQuality,
            interventions: sleepMetrics.interventions
        )
    }
}

// MARK: - Supporting Classes and Models

enum SleepStageType: String, Codable {
    case awake
    case lightSleep
    case deepSleep
    case remSleep
    case unknown
}

struct SleepMetrics {
    var totalSleepTime: TimeInterval = 0
    var deepSleepTime: TimeInterval = 0
    var remSleepTime: TimeInterval = 0
    var lightSleepTime: TimeInterval = 0
    var awakeTime: TimeInterval = 0
    var interventions: [NudgeAction] = []
    
    var deepSleepPercentage: Double {
        guard totalSleepTime > 0 else { return 0 }
        return deepSleepTime / totalSleepTime
    }
    
    var remSleepPercentage: Double {
        guard totalSleepTime > 0 else { return 0 }
        return remSleepTime / totalSleepTime
    }
    
    var lightSleepPercentage: Double {
        guard totalSleepTime > 0 else { return 0 }
        return lightSleepTime / totalSleepTime
    }
    
    var awakePercentage: Double {
        guard totalSleepTime > 0 else { return 0 }
        return awakeTime / totalSleepTime
    }
    
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
            awakeTime += time
        }
        totalSleepTime += time
    }
}

struct SleepReport {
    let date: Date
    let totalSleepTime: TimeInterval
    let deepSleepPercentage: Double
    let remSleepPercentage: Double
    let sleepQuality: Double
    let interventions: [NudgeAction]
}