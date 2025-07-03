import Foundation
import SwiftData

/// Singleton registry for Health Copilot Skills (plugins)
public class HealthCopilotSkillRegistry {
    public static let shared = HealthCopilotSkillRegistry()
    private var skills: [String: HealthCopilotSkill] = [:]
    private let queue = DispatchQueue(label: "com.healthai2030.copilot.skillregistry", attributes: .concurrent)
    
    private var enabledSkills: Set<String> = []
    private var skillStateModelContext: ModelContext? = try? ModelContext(for: SkillState.self)
    
    private init() {
        loadSkillStates()
    }
    
    /// Register a skill (plugin) with the registry
    public func register(skill: HealthCopilotSkill) {
        queue.async(flags: .barrier) {
            self.skills[skill.skillID] = skill
        }
    }
    
    /// Unregister a skill by ID
    public func unregister(skillID: String) {
        queue.async(flags: .barrier) {
            self.skills.removeValue(forKey: skillID)
        }
    }
    
    /// Get a skill by ID
    public func skill(for skillID: String) -> HealthCopilotSkill? {
        var result: HealthCopilotSkill?
        queue.sync {
            result = skills[skillID]
        }
        return result
    }
    
    /// List all registered skills
    public func allSkills() -> [HealthCopilotSkill] {
        var result: [HealthCopilotSkill] = []
        queue.sync {
            result = Array(skills.values)
        }
        return result
    }
    
    /// List all skill manifests (for LLM/plugin discovery)
    public func allSkillManifests() -> [HealthCopilotSkillManifest] {
        var result: [HealthCopilotSkillManifest] = []
        queue.sync {
            result = skills.values.map { $0.manifest }
        }
        return result
    }

    /// Enable/disable skills (for user or admin control)
    public func enableSkill(skillID: String) {
        queue.async(flags: .barrier) {
            self.enabledSkills.insert(skillID)
            self.saveSkillState(skillID: skillID, isEnabled: true)
        }
    }
    public func disableSkill(skillID: String) {
        queue.async(flags: .barrier) {
            self.enabledSkills.remove(skillID)
            self.saveSkillState(skillID: skillID, isEnabled: false)
        }
    }
    public func isSkillEnabled(skillID: String) -> Bool {
        var result = true
        queue.sync {
            result = enabledSkills.isEmpty || enabledSkills.contains(skillID)
        }
        return result
    }
    private func saveSkillState(skillID: String, isEnabled: Bool) {
        guard let context = skillStateModelContext else { return }
        let state = (try? context.fetchOne(SkillState.self, where: #Predicate { $0.id == skillID })) ?? SkillState(id: skillID)
        state.isEnabled = isEnabled
        state.lastUpdated = Date()
        try? context.save()
    }
    private func loadSkillStates() {
        guard let context = skillStateModelContext else { return }
        let allStates = (try? context.fetch(SkillState.self)) ?? []
        self.enabledSkills = Set(allStates.filter { $0.isEnabled }.map { $0.id })
    }

    /// Route an intent to the appropriate skill
    public func handle(intent: String, parameters: [String: Any], context: HealthCopilotContext?) async throws -> String? {
        let skills = allSkills().filter { $0.supportedIntents.contains(intent) }
        guard let skill = skills.first else { return nil }
        return try await skill.handle(intent: intent, parameters: parameters, context: context)
    }

    /// Route an intent to all matching skills and aggregate results
    public func handleAll(intent: String, parameters: [String: Any], context: HealthCopilotContext?) async -> [HealthCopilotSkillResult] {
        let skills = allSkills().filter { $0.supportedIntents.contains(intent) && isSkillEnabled(skillID: $0.skillID) }
        var results: [HealthCopilotSkillResult] = []
        for skill in skills {
            do {
                let result = try await skill.handle(intent: intent, parameters: parameters, context: context)
                results.append(result)
            } catch {
                results.append(.error("Error in skill \(skill.skillID): \(error.localizedDescription)"))
            }
        }
        return results
    }
    
    /// List all skill statuses (for diagnostics, UI, or LLM)
    public func allSkillStatuses() -> [String: HealthCopilotSkillStatus] {
        var result: [String: HealthCopilotSkillStatus] = [:]
        queue.sync {
            for (id, skill) in skills {
                result[id] = skill.status
            }
        }
        return result
    }
}
