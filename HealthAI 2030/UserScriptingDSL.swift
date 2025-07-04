import Foundation

/// A simple DSL for user-defined health automations.

// 1. Define the structure of the DSL

/// Represents a condition in a WHEN clause.
struct DSLCondition {
    let metric: String
    let comparison: String // e.g., "<", ">", "=="
    let value: Double
}

/// Represents an action in a DO clause.
enum DSLAction {
    case setHomeLights(color: String, time: String)
    case playMeditationAudio(track: String)
    case sendNotification(message: String)
    case logHealthMetric(metric: String, value: Double)
    case adjustSleepGoal(hours: Double)
}

/// Represents a full user-defined script.
struct UserScript {
    let condition: DSLCondition
    let actions: [DSLAction]
}

// 2. Create a parser for the DSL

class DSLParser {
    /// Parses a string containing a user script into a `UserScript` object.
    /// Now supports more robust parsing and more actions.
    func parse(_ scriptText: String) -> UserScript? {
        guard let whenRange = scriptText.range(of: "WHEN "),
              let doRange = scriptText.range(of: " DO ") else { return nil }
        let conditionString = String(scriptText[whenRange.upperBound..<doRange.lowerBound])
        let actionString = String(scriptText[doRange.upperBound...])
        let conditionParts = conditionString.split(separator: " ").map(String.init)
        guard conditionParts.count == 3,
              let value = Double(conditionParts[2]) else { return nil }
        let condition = DSLCondition(metric: conditionParts[0], comparison: conditionParts[1], value: value)
        var actions: [DSLAction] = []
        let lowerAction = actionString.lowercased()
        if lowerAction.contains("set_home_lights") {
            let color = lowerAction.contains("calm") ? "calm" : "default"
            let time = lowerAction.contains("9:00 pm") ? "9:00 PM" : "evening"
            actions.append(.setHomeLights(color: color, time: time))
        }
        if lowerAction.contains("play_meditation_audio") {
            let track = lowerAction.contains("deep_sleep") ? "deep_sleep" : "default"
            actions.append(.playMeditationAudio(track: track))
        }
        if lowerAction.contains("send_notification") {
            actions.append(.sendNotification(message: "Custom notification"))
        }
        if lowerAction.contains("log_health_metric") {
            actions.append(.logHealthMetric(metric: "sleep_score", value: value))
        }
        if lowerAction.contains("adjust_sleep_goal") {
            actions.append(.adjustSleepGoal(hours: 8.0))
        }
        return UserScript(condition: condition, actions: actions)
    }
}

// 3. Create an engine to execute the scripts

class ScriptingEngine {
    /// Executes the actions defined in a user script.
    func execute(_ script: UserScript) {
        // Here, you would integrate with your home automation and notification systems.
        print("Executing script for condition: \(script.condition.metric) \(script.condition.comparison) \(script.condition.value)")
        for action in script.actions {
            switch action {
            case .setHomeLights(let color, let time):
                print("  - Setting home lights to \(color) at \(time)")
                // HomeKitManager.shared.setLights(color: color, time: time)
            case .playMeditationAudio(let track):
                print("  - Playing meditation audio: \(track)")
                // AudioManager.shared.play(track: track)
            case .sendNotification(let message):
                print("  - Sending notification: \(message)")
                // NotificationManager.shared.send(message: message)
            case .logHealthMetric(let metric, let value):
                print("  - Logging health metric: \(metric) with value: \(value)")
                // HealthDataManager.shared.logMetric(metric, value: value)
            case .adjustSleepGoal(let hours):
                print("  - Adjusting sleep goal to \(hours) hours")
                // SleepManager.shared.adjustSleepGoal(hours: hours)
            }
        }
    }
}
