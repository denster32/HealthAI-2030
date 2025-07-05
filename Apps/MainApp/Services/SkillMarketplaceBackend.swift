import Foundation
import Combine

@MainActor
class SkillMarketplaceBackend: ObservableObject {
    static let shared = SkillMarketplaceBackend()
    @Published var availableSkills: [MarketplaceSkill] = []
    @Published var userSkills: [MarketplaceSkill] = []
    
    private init() {}
    
    func fetchAvailableSkills() {
        // TODO: Fetch skills from backend API
        availableSkills = [
            MarketplaceSkill(id: UUID(), name: "Sleep Optimizer", description: "Improve your sleep with AI routines."),
            MarketplaceSkill(id: UUID(), name: "Cardiac Coach", description: "Personalized cardiac health insights.")
        ]
    }
    
    func submitSkill(_ skill: MarketplaceSkill) {
        // TODO: Submit skill to backend for review
        userSkills.append(skill)
    }
}

struct MarketplaceSkill: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let code: String // Store the plugin's Swift code
    var isApproved: Bool = false // For future approval process
    var version: String = "1.0.0" // For future versioning
    let submissionDate: Date = Date()
}
