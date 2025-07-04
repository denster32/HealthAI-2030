import SwiftUI

struct PluginSubmissionView: View {
    @State private var pluginName: String = ""
    @State private var pluginDescription: String = ""
    @State private var pluginFileURL: URL? = nil
    @State private var submissionStatus: String? = nil

    var body: some View {
        Form {
            Section(header: Text("Plugin Details")) {
                TextField("Plugin Name", text: $pluginName)
                TextField("Description", text: $pluginDescription)
            }

            Section(header: Text("Upload Plugin")) {
                Button("Select Plugin File") {
                    // Placeholder for file picker
                }
                if let url = pluginFileURL {
                    Text("Selected: \(url.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Code (Optional)")) {
                TextEditor(text: .constant("// Paste your plugin Swift code here"))
                    .frame(height: 200)
            }

            Section {
                Button("Submit Plugin") {
                    submitPlugin()
                }
                .disabled(pluginName.isEmpty || pluginDescription.isEmpty || pluginFileURL == nil)
            }

            if let status = submissionStatus {
                Section(header: Text("Submission Status")) {
                    Text(status)
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Submit Plugin")
    }

    private func submitPlugin() {
        // Placeholder for plugin submission logic
        submissionStatus = "Plugin submitted successfully!"
    }
}

#Preview {
    PluginSubmissionView()
}
