import Foundation

/// Protocol for a Health Copilot Skill (LLM Plugin)
public protocol HealthCopilotSkill: AnyObject {
    /// Unique identifier for the skill
    var skillID: String { get }
    /// Human-readable name
    var displayName: String { get }
    /// Short description of what the skill does
    var description: String { get }
    /// List of supported intent names (for LLM routing)
    var supportedIntents: [String] { get }
    /// Called by the Copilot to handle a user intent/query
    /// - Parameters:
    ///   - intent: The intent name (e.g., "analyze_sleep")
    ///   - parameters: Dictionary of parameters (from LLM/user)
    ///   - context: Optional context (user profile, health data, etc.)
    /// - Returns: Result as a string (can be JSON, markdown, etc.)
    func handle(intent: String, parameters: [String: Any], context: HealthCopilotContext?) async throws -> HealthCopilotSkillResult
    /// Return manifest for LLM/plugin discovery
    var manifest: HealthCopilotSkillManifest { get }
    /// Report current health/status of the skill (for diagnostics, LLM, or UI)
    var status: HealthCopilotSkillStatus { get }
}

/// Context object passed to skills (user data, health metrics, etc.)
public struct HealthCopilotContext {
    public let userID: String
    public let userProfile: [String: Any]
    public let healthData: [String: Any]
    public let date: Date
    public init(userID: String, userProfile: [String: Any], healthData: [String: Any], date: Date = Date()) {
        self.userID = userID
        self.userProfile = userProfile
        self.healthData = healthData
        self.date = date
    }
}

/// Skill result type: supports plain text, markdown, or structured JSON
public enum HealthCopilotSkillResult {
    case text(String)
    case markdown(String)
    case json([String: Any])
    case error(String)
}

/// Skill metadata for discovery, versioning, and capability introspection
public struct HealthCopilotSkillManifest: Codable {
    public let skillID: String
    public let displayName: String
    public let description: String
    public let version: String
    public let author: String
    public let supportedIntents: [String]
    public let capabilities: [String]
    public let url: URL?
}

/// Skill health/status reporting
public enum HealthCopilotSkillStatus: String, Codable {
    case healthy
    case degraded
    case error
    case updating
    case disabled
}

public extension HealthCopilotSkill {
    /// Manifest for LLM/plugin discovery
    var manifest: HealthCopilotSkillManifest {
        HealthCopilotSkillManifest(
            skillID: skillID,
            displayName: displayName,
            description: description,
            version: "1.0.0",
            author: "HealthAI 2030 Team",
            supportedIntents: supportedIntents,
            capabilities: supportedIntents,
            url: nil
        )
    }
    var isEnabled: Bool {
        HealthCopilotSkillRegistry.shared.isSkillEnabled(skillID: skillID)
    }
}
