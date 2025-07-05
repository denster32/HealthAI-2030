import Foundation

/// Marketplace manifest for user discovery and management of skills
public struct SkillMarketplaceManifest: Codable {
    public let skills: [HealthCopilotSkillManifest]
    public let lastUpdated: Date
    public let source: String
    public init(skills: [HealthCopilotSkillManifest], lastUpdated: Date = Date(), source: String = "local") {
        self.skills = skills
        self.lastUpdated = lastUpdated
        self.source = source
    }
}
