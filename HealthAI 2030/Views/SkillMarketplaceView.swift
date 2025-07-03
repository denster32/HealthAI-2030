import SwiftUI

struct CopilotSkill: Identifiable, Decodable {
    let id: String
    let name: String
    let description: String
}

struct SkillMarketplaceView: View {
    @State private var skills: [CopilotSkill] = []
    var body: some View {
        NavigationView {
            List(skills) { skill in
                VStack(alignment: .leading) {
                    Text(skill.name).font(.headline)
                    Text(skill.description).font(.subheadline)
                }
            }
            .navigationTitle("Skill Marketplace")
            .onAppear(perform: loadSkills)
        }
    }
    private func loadSkills() {
        if let url = Bundle.main.url(forResource: "SkillManifest", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let manifest = try? JSONDecoder().decode([String: [CopilotSkill]].self, from: data) {
            skills = manifest["skills"] ?? []
        }
    }
}

#Preview {
    SkillMarketplaceView()
}
