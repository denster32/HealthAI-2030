import Foundation

/// Simple test suite for Health Copilot Skills
public class HealthCopilotSkillTests {
    public static func runAll() async {
        let registry = HealthCopilotSkillRegistry.shared
        registry.register(skill: SleepStudySkill())
        registry.register(skill: WearableDeviceSkill())
        registry.register(skill: CausalExplanationSkill())
        registry.register(skill: PersonalizedMedicationAdvisorSkill())
        let context = HealthCopilotContext(userID: "testuser", userProfile: [:], healthData: ["steps": 10000, "hrv": 60.0, "heartRate": 70, "sleep": ["totalHours": 6.0, "remHours": 1.0, "deepHours": 0.7], "medications": ["warfarin", "aspirin"]])
        print("--- Testing SleepStudySkill ---")
        let sleepResult = try? await registry.handle(intent: "analyze_sleep", parameters: [:], context: context)
        print(sleepResult ?? "No result")
        print("--- Testing WearableDeviceSkill ---")
        let stepsResult = try? await registry.handle(intent: "get_steps", parameters: [:], context: context)
        print(stepsResult ?? "No result")
        print("--- Testing CausalExplanationSkill ---")
        let explainResult = try? await registry.handle(intent: "explain_recommendation", parameters: ["recommendation": "Increase sleep", "cause": "Low REM", "evidence": "Stanford study 2024"], context: context)
        print(explainResult ?? "No result")
        print("--- Testing PersonalizedMedicationAdvisorSkill ---")
        let medResult = try? await registry.handle(intent: "check_interactions", parameters: ["medications": ["warfarin", "aspirin"]], context: context)
        print(medResult ?? "No result")
        print("--- All skill statuses ---")
        print(registry.allSkillStatuses())
    }
}
