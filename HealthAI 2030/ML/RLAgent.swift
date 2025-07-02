import Foundation
import Combine
import CoreML
import GameplayKit // For potential future use with more complex RL algorithms

// MARK: - Nudge Actions
enum HEPAFilterMode: Codable, Hashable {
    case auto
    case manual
    case off
}

enum AudioNudgeType: Codable, Hashable {
    case pinkNoise
    case isochronicTones
    case binauralBeats
    case natureSounds
}

enum HapticNudgeType: Codable, Hashable {
    case gentlePulse
    case strongPulse
}

enum EnvironmentNudgeType: Codable, Hashable {
    case lowerTemperature(Double)
    case raiseHumidity(Double)
    case dimLights(Double)
    case closeBlinds(Double)
    case startHEPAFilter
    case stopHEPAFilter
}

enum BedMotorNudgeType: Codable, Hashable {
    case adjustHead(Double)
    case adjustFoot(Double)
    case startMassage(Double)
    case stopMassage
}

enum NudgeActionType: Codable, Hashable {
    case audio(AudioNudgeType)
    case haptic(HapticNudgeType)
    case environment(EnvironmentNudgeType)
    case bedMotor(BedMotorNudgeType)
}

struct NudgeAction: Codable, Hashable {
    let type: NudgeActionType
    let reason: String
}

// MARK: - Sleep and Environment Data Structures

enum SleepStage {
    case awake, light, deep, rem
}

struct SleepState {
    let stage: SleepStage
    let hrv: Double
    let heartRate: Double
    let timeInStage: TimeInterval
}

struct EnvironmentData {
    let temperature: Double
    let humidity: Double
    let noiseLevel: Double // 0.0 - 1.0
    let lightLevel: Double // 0.0 - 1.0
    let bedIncline: Double // degrees
}

// MARK: - RLAgent (Rule-Based for M1)

class RLAgent: ObservableObject {
    static let shared = RLAgent()
    
    @Published var lastNudgeAction: NudgeAction?
    @Published var nudgeCount: Int = 0
    
    private init() {}
    
    /// Decide on a nudge action based on current sleep state and environment data
    func decideNudge(sleepState: SleepState, environment: EnvironmentData) -> NudgeAction? {
        print("RLAgent: Analyzing sleep state - Stage: \(sleepState.stage), HRV: \(sleepState.hrv), HR: \(sleepState.heartRate)")
        print("RLAgent: Environment - Temp: \(environment.temperature)°C, Humidity: \(environment.humidity)%, Noise: \(environment.noiseLevel), Light: \(environment.lightLevel)")
        
        // Rule-based logic for M1
        switch sleepState.stage {
        case .deep:
            if environment.noiseLevel > 0.3 {
                let action = NudgeAction(type: .audio(.pinkNoise), reason: "Deep sleep with noise detected; play pink noise to mask disturbances.")
                recordNudge(action)
                return action
            }
            if environment.temperature > 21.0 {
                let action = NudgeAction(type: .environment(.lowerTemperature(19.0)), reason: "Deep sleep and room too warm; lower temperature for optimal deep sleep.")
                recordNudge(action)
                return action
            }
            if environment.lightLevel > 0.1 {
                let action = NudgeAction(type: .environment(.dimLights(0.05)), reason: "Deep sleep and room too bright; dim lights completely.")
                recordNudge(action)
                return action
            }
            
        case .light:
            if environment.lightLevel > 0.2 {
                let action = NudgeAction(type: .environment(.dimLights(0.1)), reason: "Light sleep and room too bright; dim lights to promote deeper sleep.")
                recordNudge(action)
                return action
            }
            if environment.humidity < 35.0 {
                let action = NudgeAction(type: .environment(.raiseHumidity(45.0)), reason: "Light sleep and air too dry; raise humidity for comfort.")
                recordNudge(action)
                return action
            }
            if environment.temperature > 22.0 {
                let action = NudgeAction(type: .environment(.lowerTemperature(20.0)), reason: "Light sleep and room too warm; lower temperature to promote deep sleep.")
                recordNudge(action)
                return action
            }
            if sleepState.hrv < 25.0 {
                let action = NudgeAction(type: .audio(.isochronicTones), reason: "Light sleep with low HRV; play isochronic tones to promote relaxation.")
                recordNudge(action)
                return action
            }
            
        case .rem:
            if environment.noiseLevel > 0.2 {
                let action = NudgeAction(type: .audio(.natureSounds), reason: "REM sleep with noise detected; play nature sounds to mask disturbances.")
                recordNudge(action)
                return action
            }
            if environment.lightLevel > 0.15 {
                let action = NudgeAction(type: .environment(.dimLights(0.08)), reason: "REM sleep and room too bright; dim lights to protect REM cycles.")
                recordNudge(action)
                return action
            }
            if sleepState.heartRate > 75 {
                let action = NudgeAction(type: .haptic(.gentlePulse), reason: "REM sleep with elevated heart rate; gentle haptic to stabilize.")
                recordNudge(action)
                return action
            }
            
        case .awake:
            if environment.bedIncline < 5.0 {
                let action = NudgeAction(type: .bedMotor(.adjustHead(10.0)), reason: "Awake and bed incline low; raise head to help wake up naturally.")
                recordNudge(action)
                return action
            }
            if environment.lightLevel < 0.3 {
                let action = NudgeAction(type: .environment(.dimLights(0.4)), reason: "Awake and room too dark; increase light to help wake up.")
                recordNudge(action)
                return action
            }
            if sleepState.timeInStage > 300 { // Awake for more than 5 minutes
                let action = NudgeAction(type: .bedMotor(.startMassage(0.3)), reason: "Awake for extended period; gentle massage to promote relaxation.")
                recordNudge(action)
                return action
            }
        }
        
        // Cross-stage rules
        if sleepState.hrv < 20.0 {
            let action = NudgeAction(type: .haptic(.gentlePulse), reason: "Very low HRV detected; gentle haptic pulse to stimulate parasympathetic response.")
            recordNudge(action)
            return action
        }
        
        if sleepState.heartRate > 85 {
            let action = NudgeAction(type: .audio(.binauralBeats), reason: "Elevated heart rate; binaural beats to promote calm.")
            recordNudge(action)
            return action
        }
        
        if environment.humidity > 70.0 {
            let action = NudgeAction(type: .environment(.startHEPAFilter), reason: "High humidity detected; activate HEPA filter to prevent mold.")
            recordNudge(action)
            return action
        }
        
        // No nudge needed
        return nil
    }
    
    private func recordNudge(_ action: NudgeAction) {
        DispatchQueue.main.async {
            self.lastNudgeAction = action
            self.nudgeCount += 1
        }
        print("RLAgent: Triggering nudge - \(action.reason)")
    }
    
    // MARK: - Learning Interface (for future RL implementation)
    
    /// Record the outcome of a nudge action for future learning
    func recordOutcome(action: NudgeAction, sleepImprovement: Double, timeToNextStage: TimeInterval) {
        // For M1, this is just logging. In future versions, this would update a Q-table or neural network
        print("RLAgent: Outcome recorded - Action: \(action.reason), Sleep Improvement: \(sleepImprovement), Time to Next Stage: \(timeToNextStage)s")
    }
    
    /// Get statistics about the agent's performance
    func getPerformanceStats() -> RLAgentStats {
        return RLAgentStats(
            totalNudges: nudgeCount,
            lastNudgeTime: lastNudgeAction != nil ? Date() : nil,
            averageSleepImprovement: 0.0 // Placeholder for future implementation
        )
    }
}

// MARK: - Supporting Structures

struct RLAgentStats {
    let totalNudges: Int
    let lastNudgeTime: Date?
    let averageSleepImprovement: Double
}