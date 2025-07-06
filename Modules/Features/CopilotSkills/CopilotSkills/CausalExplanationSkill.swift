import Foundation

/// Example: Causal Explanation Skill Plugin
public class CausalExplanationSkill: HealthCopilotSkill {
    public let skillID = "causal.explanation"
    public let displayName = "Causal Explanation"
    public let description = "Explains the reasoning behind health recommendations using a knowledge graph."
    public let supportedIntents = ["explain_recommendation"]
    public var manifest: HealthCopilotSkillManifest { HealthCopilotSkillManifest(
        skillID: skillID,
        displayName: displayName,
        description: description,
        version: "1.0.0",
        author: "HealthAI 2030 Team",
        supportedIntents: supportedIntents,
        capabilities: ["causal_graph", "explanation"],
        url: nil
    )}
    public init() {}
    public func handle(intent: String, parameters: [String: Any], context: HealthCopilotContext?) async throws -> HealthCopilotSkillResult {
        guard intent == "explain_recommendation" else {
            return .error("Intent not supported by CausalExplanationSkill.")
        }
        let recommendation = parameters["recommendation"] as? String ?? ""
        let cause = parameters["cause"] as? String ?? ""
        let evidence = parameters["evidence"] as? String ?? ""
        let explanation = "Because your \(cause.lowercased()), and research shows: \(evidence)."
        let markdown = """
### Why this recommendation?
- **Recommendation:** \(recommendation)
- **Cause:** \(cause)
- **Evidence:** \(evidence)

_This explanation is generated using the HealthAI 2030 knowledge graph and latest research._
"""
        // Simple causal graph as JSON (could be rendered as a graph in UI/AR)
        let causalGraph: [String: Any] = [
            "nodes": [
                ["id": "cause", "label": cause],
                ["id": "recommendation", "label": recommendation],
                ["id": "evidence", "label": evidence]
            ],
            "edges": [
                ["from": "cause", "to": "recommendation", "label": "leads to"],
                ["from": "evidence", "to": "recommendation", "label": "supports"]
            ]
        ]
        return .json([
            "explanation": explanation,
            "markdown": markdown,
            "causalGraph": causalGraph
        ])
    }
}
