
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
}

/// Represents a full user-defined script.
struct UserScript {
    let condition: DSLCondition
    let actions: [DSLAction]
}

// 2. Create a parser for the DSL

class DSLParser {
    /// Parses a string containing a user script into a `UserScript` object.
    /// Note: This is a simplified, non-robust parser for demonstration purposes.
    func parse(_ scriptText: String) -> UserScript? {
        // Example script: "WHEN my_sleep_score < 70 DO set_home_lights(to: \"calm\", at: \"9:00 PM") AND play_meditation_audio(\"deep_sleep\")"
        // This is a very basic parser and would need to be made more robust for a real application.

        let whenRange = scriptText.range(of: "WHEN ")!
        let doRange = scriptText.range(of: " DO ")!

        let conditionString = String(scriptText[whenRange.upperBound..<doRange.lowerBound])
        let actionString = String(scriptText[doRange.upperBound...])

        // Parse condition
        let conditionParts = conditionString.split(separator: " ").map(String.init)
        guard conditionParts.count == 3,
              let value = Double(conditionParts[2]) else { return nil }
        let condition = DSLCondition(metric: conditionParts[0], comparison: conditionParts[1], value: value)

        // Parse actions (simplified)
        var actions: [DSLAction] = []
        if actionString.contains("set_home_lights") {
            actions.append(.setHomeLights(color: "calm", time: "9:00 PM"))
        }
        if actionString.contains("play_meditation_audio") {
            actions.append(.playMeditationAudio(track: "deep_sleep"))
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
            }
        }
    }
}
