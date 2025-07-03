import Foundation

struct CopilotSkill: Decodable {
    let id: String
    let name: String
    let description: String
}

class SkillLoader {
    func loadSkills() -> [CopilotSkill] {
        guard let url = Bundle.main.url(forResource: "SkillManifest", withExtension: "json") else { return [] }
        do {
            let data = try Data(contentsOf: url)
            let manifest = try JSONDecoder().decode([String: [CopilotSkill]].self, from: data)
            return manifest["skills"] ?? []
        } catch {
            return []
        }
    }
}
