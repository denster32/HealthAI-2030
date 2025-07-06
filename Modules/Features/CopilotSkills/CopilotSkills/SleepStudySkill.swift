import Foundation

/// Example: Stanford Sleep Study Skill Plugin
public class SleepStudySkill: HealthCopilotSkill {
    public let skillID = "stanford.sleepstudy"
    public let displayName = "Stanford Sleep Study Analyzer"
    public let description = "Analyzes sleep data and provides evidence-based recommendations using Stanford protocols."
    public let supportedIntents = ["analyze_sleep", "sleep_recommendation"]
    
    public init() {}
    
    public func handle(intent: String, parameters: [String: Any], context: HealthCopilotContext?) async throws -> String {
        switch intent {
        case "analyze_sleep":
            guard let healthData = context?.healthData, let sleep = healthData["sleep"] as? [String: Any] else {
                return "No sleep data available."
            }
            // Example: Analyze total sleep, REM, deep, and provide feedback
            let total = sleep["totalHours"] as? Double ?? 0
            let rem = sleep["remHours"] as? Double ?? 0
            let deep = sleep["deepHours"] as? Double ?? 0
            var advice = "You slept \(String(format: "%.1f", total))h (REM: \(String(format: "%.1f", rem))h, Deep: \(String(format: "%.1f", deep))h). "
            if total < 7 {
                advice += "Stanford recommends at least 7h per night. Try to increase your sleep duration. "
            }
            if rem < 1.5 {
                advice += "REM sleep is a bit low; consider stress reduction before bed. "
            }
            if deep < 1.0 {
                advice += "Deep sleep is below optimal; try a cooler room or less screen time before bed. "
            }
            return advice
        case "sleep_recommendation":
            return "Stanford protocol: Maintain a consistent bedtime, avoid caffeine after 2pm, and keep your bedroom cool and dark."
        default:
            return "Intent not supported by SleepStudySkill."
        }
    }
}
