import Foundation

/// Dynamic loader for Health Copilot Skills (Swift bundles or packages)
public class HealthCopilotSkillLoader {
    public static let shared = HealthCopilotSkillLoader()
    private init() {}

    /// Load a skill from a dynamic bundle at runtime
    /// - Parameter bundleURL: URL to the .bundle or .framework
    /// - Returns: Loaded skill instance, or nil if failed
    public func loadSkill(from bundleURL: URL) -> HealthCopilotSkill? {
        guard let bundle = Bundle(url: bundleURL) else { return nil }
        guard let principalClass = bundle.principalClass as? HealthCopilotSkill.Type else { return nil }
        let skill = principalClass.init()
        HealthCopilotSkillRegistry.shared.register(skill: skill)
        return skill
    }
}
