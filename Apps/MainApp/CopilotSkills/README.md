# Health Copilot Skills (LLM Plugin System)

This directory contains the Health Copilot Skills API and example plugins for HealthAI 2030.

## Overview
- **HealthCopilotSkill**: Protocol for defining a plugin/skill that can be registered with the Copilot LLM.
- **HealthCopilotSkillRegistry**: Singleton registry for registering, discovering, and invoking skills.
- **Example Skills**: `SleepStudySkill`, `WearableDeviceSkill`.

## How It Works
1. **Define a Skill**: Conform to `HealthCopilotSkill` and implement the required methods.
2. **Register the Skill**: Register your skill with `HealthCopilotSkillRegistry.shared.register(skill:)` at app startup or plugin load.
3. **Invoke a Skill**: The Copilot/LLM can route user intents/queries to the appropriate skill via the registry.

## Example Usage
```swift
// Register skills at app launch
HealthCopilotSkillRegistry.shared.register(skill: SleepStudySkill())
HealthCopilotSkillRegistry.shared.register(skill: WearableDeviceSkill())

// Handle a user intent (e.g., from LLM or UI)
let context = HealthCopilotContext(userID: "user123", userProfile: [:], healthData: ["steps": 8000, "hrv": 52.3, "heartRate": 68, "sleep": ["totalHours": 6.5, "remHours": 1.2, "deepHours": 0.8]])
let result = try await HealthCopilotSkillRegistry.shared.handle(intent: "analyze_sleep", parameters: [:], context: context)
print(result ?? "No skill handled the intent.")
```

## Advanced Features

- Skills provide a manifest for LLM/plugin discovery, versioning, and capability introspection.
- The registry supports enabling/disabling skills, multi-skill routing, and error aggregation.
- Results can be plain text, markdown, or structured JSON for rich LLM and UI integration.
- Example advanced skill: `CausalExplanationSkill` for explainable AI.

## Example: Aggregate Results from Multiple Skills
```swift
let results = await HealthCopilotSkillRegistry.shared.handleAll(intent: "analyze_sleep", parameters: [:], context: context)
for result in results {
    switch result {
    case .text(let str): print(str)
    case .markdown(let md): print(md)
    case .json(let obj): print(obj)
    case .error(let err): print("Error: \(err)")
    }
}
```

## Extending
- Add new skills by conforming to `HealthCopilotSkill`.
- Skills can be distributed as Swift packages, frameworks, or loaded dynamically.
- The system is thread-safe and ready for production use.
