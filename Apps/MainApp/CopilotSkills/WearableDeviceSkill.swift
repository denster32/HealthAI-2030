import Foundation

/// Example: Wearable Device Skill Plugin
public class WearableDeviceSkill: HealthCopilotSkill {
    public let skillID = "wearable.device"
    public let displayName = "Wearable Device Data"
    public let description = "Integrates and analyzes data from a connected wearable device."
    public let supportedIntents = ["get_steps", "get_hrv", "get_heart_rate"]
    
    public init() {}
    
    public func handle(intent: String, parameters: [String: Any], context: HealthCopilotContext?) async throws -> String {
        guard let healthData = context?.healthData else {
            return "No health data available."
        }
        switch intent {
        case "get_steps":
            let steps = healthData["steps"] as? Int ?? 0
            return "You have taken \(steps) steps today."
        case "get_hrv":
            let hrv = healthData["hrv"] as? Double ?? 0
            return String(format: "Your HRV is %.1f ms.", hrv)
        case "get_heart_rate":
            let hr = healthData["heartRate"] as? Int ?? 0
            return "Your current heart rate is \(hr) bpm."
        default:
            return "Intent not supported by WearableDeviceSkill."
        }
    }
}
