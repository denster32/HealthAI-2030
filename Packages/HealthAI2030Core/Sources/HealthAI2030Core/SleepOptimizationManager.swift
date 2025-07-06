import Foundation
import HealthKit
import Combine
import CoreML
import AVFoundation
import SwiftData // Import SwiftData
import CloudKit // Import CloudKit
import OSLog // Import OSLog for logging
#if canImport(UIKit)
import UIKit
#endif

class SleepOptimizationManager: ObservableObject {
    static let shared = SleepOptimizationManager()
    
    private var cancellables = Set<AnyCancellable>()
    private let swiftDataManager = SwiftDataManager.shared // SwiftData Manager instance
    
    // Published properties
    @Published var currentSleepStage: SleepStageType = .unknown
    @Published var sleepQuality: Double = 0.0
    @Published var deepSleepPercentage: Double = 0.0
    @AppStorage("isSleepOptimizationActive") @Published var isOptimizationActive: Bool = false
    @Published var sleepMetrics: SleepMetrics = SleepMetrics()
    @Published var sleepQuickActions: [SyncableSleepQuickAction] = [] // New: For quick action data persistence
    
    // Sleep stage transformer model
    private var sleepStageModel: MLModel?
    
    private init() {
        // Initialization is deferred to the initialize() method
    }
    
    /// Initializes the SleepOptimizationManager and sets up sleep monitoring.
    func initialize() async {
        Logger.sleepOptimization.info("Initializing SleepOptimizationManager...")
        
        // Load the sleep stage ML model
        await loadSleepStageModel()
        
        // Start monitoring sleep patterns
        startSleepMonitoring()
        
        // Load sleep quick actions from SwiftData
        await loadSleepQuickActions()
        
        Logger.sleepOptimization.info("SleepOptimizationManager initialized successfully")
    }
    
    // MARK: - Sleep Stage Detection
    
    /// Starts monitoring sleep patterns and updates published properties.
    private func startSleepMonitoring() {
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
    
    private func predictSleepStage(with input: MLMultiArray) {
        do {
            let model = try SleepStageClassifier(configuration: MLModelConfiguration())
            let prediction = try model.prediction(input: SleepStageClassifierInput(heart_rate: input[0].doubleValue, hrv: input[1].doubleValue, motion: input[2].doubleValue, spo2: input[3].doubleValue))
            
            let sleepStage: SleepStageType
            switch prediction.sleep_stage {
            case 0: sleepStage = .awake
            case 1: sleepStage = .lightSleep
            case 2: sleepStage = .deepSleep
            case 3: sleepStage = .remSleep
            default: sleepStage = .unknown
            }
            
            DispatchQueue.main.async {
                self.currentSleepStage = sleepStage
                self.sleepMetrics.addTime(30, to: sleepStage) // Assuming 30-second intervals
                self.updateSleepMetrics()
                self.triggerInterventionsIfNeeded()
            }
        } catch {
            Logger.sleepOptimization.error("Error making prediction: \(error.localizedDescription)")
        }
    }
    
    private func performSleepStagePrediction(input: [Double]) -> SleepStageType {
        // This method is now replaced by the CoreML model integration.
        // The logic has been moved to predictSleepStage(with: MLMultiArray).
        return .unknown
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
        Logger.sleepOptimization.info("RLAgent triggered nudge: \(action.reason)")
        
        // Save quick action to SwiftData
        do {
            let encoder = JSONEncoder()
            let actionDetailsData = try encoder.encode(action.type)
            let actionDetailsString = String(data: actionDetailsData, encoding: .utf8)
            
            let quickAction = SyncableSleepQuickAction(
                timestamp: Date(),
                actionType: String(describing: action.type),
                actionDetails: actionDetailsString,
                reason: action.reason
            )
            try await swiftDataManager.save(quickAction)
            Logger.sleepOptimization.info("Sleep quick action saved to SwiftData: \(action.actionType)")
            DispatchQueue.main.async {
                self.sleepQuickActions.append(quickAction)
            }
        } catch {
            Logger.sleepOptimization.error("Failed to save sleep quick action to SwiftData: \(error.localizedDescription)")
        }
        
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
    
    /// Loads the Core ML model for sleep stage detection.
    private func loadSleepStageModel() async {
        Logger.sleepOptimization.info("Loading sleep stage model...")
        
        guard let modelURL = Bundle.main.url(forResource: "SleepStageClassifier", withExtension: "mlmodelc") else {
            Logger.sleepOptimization.error("Error: SleepStageClassifier.mlmodelc not found.")
            return
        }
        
        do {
            sleepStageModel = try MLModel(contentsOf: modelURL)
            Logger.sleepOptimization.info("Sleep stage model loaded successfully")
        } catch {
            Logger.sleepOptimization.error("Error loading sleep stage model: \(error.localizedDescription)")
        }
    }
    
    private func loadSleepQuickActions() async {
        do {
            let fetchedActions: [SyncableSleepQuickAction] = try await swiftDataManager.fetchAll()
            DispatchQueue.main.async {
                self.sleepQuickActions = fetchedActions
                Logger.sleepOptimization.info("Loaded \(self.sleepQuickActions.count) sleep quick actions from SwiftData.")
            }
        } catch {
            Logger.sleepOptimization.error("Failed to load sleep quick actions from SwiftData: \(error.localizedDescription)")
        }
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
        Logger.sleepOptimization.info("Sleep optimization started")
    }
 
    /// Stops any ongoing sleep optimization.
    func stopOptimization() {
        isOptimizationActive = false
        AdaptiveAudioManager.shared.stopAudio()
        BedMotorManager.shared.stopMassage()
        EnvironmentManager.shared.stopOptimization()
        Logger.sleepOptimization.info("Sleep optimization stopped")
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

// MARK: - Logging Extension for SleepOptimizationManager
extension OSLog {
    private static let subsystem = "com.healthai2030.SleepTracking"
    static let sleepOptimization = Logger(subsystem: subsystem, category: "SleepOptimizationManager")
}
