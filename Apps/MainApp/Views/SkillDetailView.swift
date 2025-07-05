import SwiftUI

struct SkillDetailView: View {
    let skill: HealthCopilotSkill
    var onUninstall: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(skill.manifest.displayName)
                .font(.largeTitle).bold()
            Text(skill.manifest.description)
                .font(.title3)
                .foregroundColor(.secondary)
            Divider()
            Group {
                HStack {
                    Text("Status:").bold()
                    Text(skill.status.rawValue.capitalized)
                }
                HStack {
                    Text("Version:").bold()
                    Text(skill.manifest.version)
                }
                HStack {
                    Text("Author:").bold()
                    Text(skill.manifest.author)
                }
                if let url = skill.manifest.url {
                    HStack {
                        Text("URL:").bold()
                        Link(url.absoluteString, destination: url)
                    }
                }
            }
            Divider()
            Text("Capabilities:").bold()
            ForEach(skill.manifest.capabilities, id: \.self) { cap in
                Text("• \(cap)")
            }
            Divider()
            Text("Diagnostics").font(.headline)
            VStack(alignment: .leading, spacing: 4) {
                Text("Health: \(skill.status.rawValue.capitalized)")
                // Add more diagnostics as needed (last error, last check, etc)
            }
            if let onUninstall = onUninstall {
                Button(role: .destructive) {
                    onUninstall()
                } label: {
                    Label("Uninstall Skill", systemImage: "trash")
                }
                .padding(.top, 16)
            }
            Spacer()
        }
        .padding()
        .navigationTitle(skill.manifest.displayName)
    }
}
