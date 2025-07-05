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
enum DSLAction: Codable, CaseIterable, Hashable {
    case setHomeLights(color: String, time: String)
    case playMeditationAudio(track: String)
    case sendNotification(message: String)
    case logHealthMetric(metric: String, value: Double)
    case adjustSleepGoal(hours: Double)
    case triggerSmartHomeScene(sceneName: String)
    case startBreathingExercise(duration: Double)
    case recordMood(mood: String)
    case recommendContent(category: String)
    case updatePrivacySetting(setting: String, enabled: Bool)

    // For CaseIterable conformance
    static var allCases: [DSLAction] {
        return [
            .setHomeLights(color: "default", time: "default"),
            .playMeditationAudio(track: "default"),
            .sendNotification(message: "default"),
            .logHealthMetric(metric: "default", value: 0.0),
            .adjustSleepGoal(hours: 0.0),
            .triggerSmartHomeScene(sceneName: "default"),
            .startBreathingExercise(duration: 0.0),
            .recordMood(mood: "default"),
            .recommendContent(category: "default"),
            .updatePrivacySetting(setting: "default", enabled: false)
        ]
    }

    // For Codable conformance (manual implementation for associated values)
    enum CodingKeys: String, CodingKey {
        case type
        case color, time, track, message, metric, value, hours, sceneName, duration, mood, category, setting, enabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "setHomeLights":
            let color = try container.decode(String.self, forKey: .color)
            let time = try container.decode(String.self, forKey: .time)
            self = .setHomeLights(color: color, time: time)
        case "playMeditationAudio":
            let track = try container.decode(String.self, forKey: .track)
            self = .playMeditationAudio(track: track)
        case "sendNotification":
            let message = try container.decode(String.self, forKey: .message)
            self = .sendNotification(message: message)
        case "logHealthMetric":
            let metric = try container.decode(String.self, forKey: .metric)
            let value = try container.decode(Double.self, forKey: .value)
            self = .logHealthMetric(metric: metric, value: value)
        case "adjustSleepGoal":
            let hours = try container.decode(Double.self, forKey: .hours)
            self = .adjustSleepGoal(hours: hours)
        case "triggerSmartHomeScene":
            let sceneName = try container.decode(String.self, forKey: .sceneName)
            self = .triggerSmartHomeScene(sceneName: sceneName)
        case "startBreathingExercise":
            let duration = try container.decode(Double.self, forKey: .duration)
            self = .startBreathingExercise(duration: duration)
        case "recordMood":
            let mood = try container.decode(String.self, forKey: .mood)
            self = .recordMood(mood: mood)
        case "recommendContent":
            let category = try container.decode(String.self, forKey: .category)
            self = .recommendContent(category: category)
        case "updatePrivacySetting":
            let setting = try container.decode(String.self, forKey: .setting)
            let enabled = try container.decode(Bool.self, forKey: .enabled)
            self = .updatePrivacySetting(setting: setting, enabled: enabled)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown DSLAction type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .setHomeLights(let color, let time):
            try container.encode("setHomeLights", forKey: .type)
            try container.encode(color, forKey: .color)
            try container.encode(time, forKey: .time)
        case .playMeditationAudio(let track):
            try container.encode("playMeditationAudio", forKey: .type)
            try container.encode(track, forKey: .track)
        case .sendNotification(let message):
            try container.encode("sendNotification", forKey: .type)
            try container.encode(message, forKey: .message)
        case .logHealthMetric(let metric, let value):
            try container.encode("logHealthMetric", forKey: .type)
            try container.encode(metric, forKey: .metric)
            try container.encode(value, forKey: .value)
        case .adjustSleepGoal(let hours):
            try container.encode("adjustSleepGoal", forKey: .type)
            try container.encode(hours, forKey: .hours)
        case .triggerSmartHomeScene(let sceneName):
            try container.encode("triggerSmartHomeScene", forKey: .type)
            try container.encode(sceneName, forKey: .sceneName)
        case .startBreathingExercise(let duration):
            try container.encode("startBreathingExercise", forKey: .type)
            try container.encode(duration, forKey: .duration)
        case .recordMood(let mood):
            try container.encode("recordMood", forKey: .type)
            try container.encode(mood, forKey: .mood)
        case .recommendContent(let category):
            try container.encode("recommendContent", forKey: .type)
            try container.encode(category, forKey: .category)
        case .updatePrivacySetting(let setting, let enabled):
            try container.encode("updatePrivacySetting", forKey: .type)
            try container.encode(setting, forKey: .setting)
            try container.encode(enabled, forKey: .enabled)
        }
    }
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
        if lowerAction.contains("trigger_smart_home_scene") {
            let sceneName = lowerAction.contains("good_night") ? "Good Night" : "Default"
            actions.append(.triggerSmartHomeScene(sceneName: sceneName))
        }
        if lowerAction.contains("start_breathing_exercise") {
            actions.append(.startBreathingExercise(duration: 5.0)) // Default to 5 minutes
        }
        if lowerAction.contains("record_mood") {
            let mood = lowerAction.contains("happy") ? "Happy" : "Neutral"
            actions.append(.recordMood(mood: mood))
        }
        if lowerAction.contains("recommend_content") {
            let category = lowerAction.contains("sleep") ? "Sleep" : "General"
            actions.append(.recommendContent(category: category))
        }
        if lowerAction.contains("update_privacy_setting") {
            let setting = lowerAction.contains("data_sharing") ? "data_sharing" : "notifications"
            let enabled = !lowerAction.contains("disable")
            actions.append(.updatePrivacySetting(setting: setting, enabled: enabled))
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
            case .triggerSmartHomeScene(let sceneName):
                print("  - Triggering smart home scene: \(sceneName)")
                // SmartHomeManager.shared.triggerScene(sceneName)
            case .startBreathingExercise(let duration):
                print("  - Starting breathing exercise for \(duration) minutes")
                // BreathingManager.shared.startExercise(duration: duration)
            case .recordMood(let mood):
                print("  - Recording mood: \(mood)")
                // MentalHealthManager.shared.recordMood(mood)
            case .recommendContent(let category):
                print("  - Recommending content in category: \(category)")
                // ContentRecommendationManager.shared.recommend(category: category)
            case .updatePrivacySetting(let setting, let enabled):
                print("  - Updating privacy setting '\(setting)' to \(enabled)")
                // PrivacySecurityManager.shared.updateSetting(setting, enabled: enabled)
            }
        }
    }
}
