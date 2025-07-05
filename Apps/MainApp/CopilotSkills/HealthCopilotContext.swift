import Foundation

/// Context passed to Copilot Skills for chat/LLM queries. Extend as needed.
public struct HealthCopilotContext {
    public static let `default` = HealthCopilotContext()
    // Add user, device, session, or environment info here as needed
    public init() {}
}
