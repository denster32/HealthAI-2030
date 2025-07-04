import Foundation
import SwiftUI

/// Proactive Health Nudge Skill Plugin
public class ProactiveNudgeSkill: HealthCopilotSkill, ObservableObject {
    public let skillID = "proactive.nudge"
    public let displayName = "Proactive Health Nudges"
    public let description = "Delivers real-time, personalized health nudges based on analytics."
    public let supportedIntents = ["get_nudge", "configure_nudge_settings", "report_nudge_feedback"]
    public var manifest: HealthCopilotSkillManifest { HealthCopilotSkillManifest(
        skillID: skillID,
        displayName: displayName,
        description: description,
        version: "1.0.0",
        author: "HealthAI 2030 Team",
        supportedIntents: supportedIntents,
        capabilities: ["nudges", "proactive_interventions"],
        url: nil
    )}
    public var status: HealthCopilotSkillStatus { .healthy }
    public static var nudgeSettings: [String: Any] = ["frequency": "hourly", "types": ["hydration", "movement", "mindfulness"]]
    
    @Published public var frequency: NudgeFrequency = .hourly
    @Published public var nudgeTypes: [String] = ["hydration", "movement", "mindfulness"]
    @Published public var feedbackHistory: [String] = []
    @Published public var schedule: NudgeSchedule = NudgeSchedule()

    public init() {}
    
    public func handle(intent: String, parameters: [String: Any], context: HealthCopilotContext?) async throws -> HealthCopilotSkillResult {
        switch intent {
        case "get_nudge":
            // Simulate a nudge based on random or analytics-driven logic
            let nudges = [
                "Time to hydrate! Drink a glass of water.",
                "Stand up and stretch for 2 minutes.",
                "Take a mindful breath break.",
                "Quick walk? Boost your energy!"
            ]
            let nudge = nudges.randomElement() ?? "Stay healthy!"
            return .text(nudge)
        case "configure_nudge_settings":
            if let freq = parameters["frequency"] as? String { ProactiveNudgeSkill.nudgeSettings["frequency"] = freq }
            if let types = parameters["types"] as? [String] { ProactiveNudgeSkill.nudgeSettings["types"] = types }
            return .text("Nudge settings updated.")
        case "report_nudge_feedback":
            let feedback = parameters["feedback"] as? String ?? ""
            return .text("Thank you for your feedback: \(feedback)")
        default:
            return .error("Intent not supported by ProactiveNudgeSkill.")
        }
    }
    
    public func updateSettings(frequency: NudgeFrequency, types: [String]) {
        self.frequency = frequency
        self.nudgeTypes = types
        // TODO: Persist settings and sync with notification system
    }

    public func submitFeedback(_ feedback: String) {
        feedbackHistory.append(feedback)
        // TODO: Send feedback to analytics/notification system
    }

    public func updateSchedule(_ schedule: NudgeSchedule) {
        self.schedule = schedule
        // TODO: Integrate with notification scheduling
    }
}

public enum NudgeFrequency: String, CaseIterable, Codable, Identifiable {
    case off, hourly, daily, custom
    public var id: String { rawValue }
}

public struct NudgeSchedule: Codable, Hashable {
    public var enabled: Bool
    public var time: Date
    public init(enabled: Bool = true, time: Date = Date()) {
        self.enabled = enabled
        self.time = time
    }
}

#if DEBUG
extension ProactiveNudgeSkill {
    public static var preview: ProactiveNudgeSkill {
        let skill = ProactiveNudgeSkill()
        skill.frequency = .hourly
        skill.nudgeTypes = ["hydration", "movement"]
        skill.feedbackHistory = ["Great nudge!", "Too frequent"]
        skill.schedule = NudgeSchedule(enabled: true, time: Date())
        return skill
    }
}
#endif
