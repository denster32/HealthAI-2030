import SwiftUI

struct CopilotSkill: Identifiable, Decodable {
    let id: String
    let name: String
    let description: String
}

struct SkillAction: Identifiable {
    let id = UUID()
    let title: String
    let action: () -> Void
}

struct SkillMarketplaceView: View {
    @State private var skills: [CopilotSkill] = []
    @State private var installedSkills: Set<String> = []
    
    var body: some View {
        NavigationView {
            List(skills) { skill in
                VStack(alignment: .leading) {
                    Text(skill.name).font(.headline)
                    Text(skill.description).font(.subheadline)
                    HStack {
                        if installedSkills.contains(skill.id) {
                            Button("Disable") {
                                disableSkill(skill.id)
                            }
                            .buttonStyle(.borderedProminent)
                            Button("Uninstall") {
                                uninstallSkill(skill.id)
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Install") {
                                installSkill(skill.id)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
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

    private func installSkill(_ id: String) {
        installedSkills.insert(id)
        print("Installed skill with id: \(id)")
    }

    private func disableSkill(_ id: String) {
        print("Disabled skill with id: \(id)")
    }

    private func uninstallSkill(_ id: String) {
        installedSkills.remove(id)
        print("Uninstalled skill with id: \(id)")
    }
}

#Preview {
    SkillMarketplaceView()
}
