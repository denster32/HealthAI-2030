import Foundation

/// Example: Personalized Medication Advisor Skill
public class PersonalizedMedicationAdvisorSkill: HealthCopilotSkill {
    public let skillID = "medication.advisor"
    public let displayName = "Personalized Medication Advisor"
    public let description = "Checks for drug interactions, schedules, and provides explainable recommendations."
    public let supportedIntents = ["check_interactions", "medication_schedule", "explain_medication"]
    public var manifest: HealthCopilotSkillManifest { HealthCopilotSkillManifest(
        skillID: skillID,
        displayName: displayName,
        description: description,
        version: "1.0.0",
        author: "HealthAI 2030 Team",
        supportedIntents: supportedIntents,
        capabilities: ["drug_interaction", "schedule", "explanation"],
        url: nil
    )}
    public var status: HealthCopilotSkillStatus = .healthy
    public init() {}
    public func handle(intent: String, parameters: [String: Any], context: HealthCopilotContext?) async throws -> HealthCopilotSkillResult {
        switch intent {
        case "check_interactions":
            guard let meds = parameters["medications"] as? [String] else {
                return .error("No medications provided.")
            }
            // Example: Simulate a drug interaction check
            if meds.contains("warfarin") && meds.contains("aspirin") {
                return .markdown("**Warning:** Warfarin and aspirin together increase bleeding risk. Consult your doctor.")
            }
            return .text("No major interactions found.")
        case "medication_schedule":
            guard let meds = parameters["medications"] as? [String] else {
                return .error("No medications provided.")
            }
            let schedule = meds.map { "- \($0): 8am, 8pm" }.joined(separator: "\n")
            return .markdown("### Medication Schedule\n\(schedule)")
        case "explain_medication":
            let med = parameters["medication"] as? String ?? "Unknown"
            let explanation = "\(med): Used to treat your condition. Take as prescribed."
            return .markdown("### Why this medication?\n- **Medication:** \(med)\n- **Reason:** \(explanation)")
        default:
            return .error("Intent not supported by PersonalizedMedicationAdvisorSkill.")
        }
    }
}
