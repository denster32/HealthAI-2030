import SwiftUI
import UniformTypeIdentifiers

struct PluginSubmissionView: View {
    @State private var pluginName: String = ""
    @State private var pluginDescription: String = ""
    @State private var pluginFileURL: URL? = nil
    @State private var submissionStatus: String? = nil
    @State private var isSubmitting = false
    @State private var showingFilePicker = false
    @State private var pluginCode: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section(header: Text("Plugin Details")) {
                TextField("Plugin Name", text: $pluginName)
                TextField("Description", text: $pluginDescription)
            }

            Section(header: Text("Upload Plugin")) {
                Button("Select Plugin File") {
                    showingFilePicker = true
                }
                .fileImporter(
                    isPresented: $showingFilePicker,
                    allowedContentTypes: [.swift, .text, .data],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            pluginFileURL = url
                        }
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
                
                if let url = pluginFileURL {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Size: \(formatFileSize(url))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Remove") {
                            pluginFileURL = nil
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                }
            }

            Section(header: Text("Code (Optional)")) {
                TextEditor(text: $pluginCode)
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if pluginCode.isEmpty {
                                Text("// Paste your plugin Swift code here")
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }

            Section {
                Button("Submit Plugin") {
                    submitPlugin()
                }
                .disabled(pluginName.isEmpty || pluginDescription.isEmpty || (pluginFileURL == nil && pluginCode.isEmpty) || isSubmitting)
                
                if isSubmitting {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Submitting plugin...")
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let status = submissionStatus {
                Section(header: Text("Submission Status")) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    Text(status)
                        .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationTitle("Submit Plugin")
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
            }
        }
        .navigationTitle("Submit Plugin")
    }

    private func submitPlugin() {
        isSubmitting = true
        submissionStatus = nil
        
        Task {
            do {
                // Validate plugin submission
                try validatePluginSubmission()
                
                // Create plugin submission
                let submission = PluginSubmission(
                    name: pluginName,
                    description: pluginDescription,
                    code: pluginCode,
                    fileURL: pluginFileURL,
                    submittedAt: Date()
                )
                
                // Save to SwiftData
                let context = ModelContainer.shared.mainContext
                context.insert(submission)
                try context.save()
                
                // Submit to plugin registry
                try await submitToPluginRegistry(submission)
                
                await MainActor.run {
                    submissionStatus = "Plugin submitted successfully! It will be reviewed within 24-48 hours."
                    isSubmitting = false
                    
                    // Reset form
                    pluginName = ""
                    pluginDescription = ""
                    pluginCode = ""
                    pluginFileURL = nil
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isSubmitting = false
                }
            }
        }
    }
    
    private func validatePluginSubmission() throws {
        guard !pluginName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PluginSubmissionError.invalidName
        }
        
        guard !pluginDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PluginSubmissionError.invalidDescription
        }
        
        guard pluginFileURL != nil || !pluginCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PluginSubmissionError.noContent
        }
        
        // Validate plugin code if provided
        if !pluginCode.isEmpty {
            try validatePluginCode(pluginCode)
        }
    }
    
    private func validatePluginCode(_ code: String) throws {
        // Basic Swift syntax validation
        let requiredKeywords = ["import", "struct", "class", "func"]
        let hasRequiredKeywords = requiredKeywords.contains { code.contains($0) }
        
        guard hasRequiredKeywords else {
            throw PluginSubmissionError.invalidCode
        }
        
        // Check for potentially dangerous code
        let dangerousPatterns = ["import Foundation", "import System", "import Darwin"]
        let hasDangerousImports = dangerousPatterns.contains { code.contains($0) }
        
        if hasDangerousImports {
            throw PluginSubmissionError.dangerousCode
        }
    }
    
    private func submitToPluginRegistry(_ submission: PluginSubmission) async throws {
        // Simulate network request to plugin registry
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // In a real implementation, this would send the submission to a server
        // For now, we'll just simulate success
    }
    
    private func formatFileSize(_ url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useKB, .useMB, .useGB]
                formatter.countStyle = .file
                return formatter.string(fromByteCount: fileSize)
            }
        } catch {
            // Ignore errors
        }
        return "Unknown size"
    }
}

// MARK: - Supporting Types

struct PluginSubmission: Codable {
    let id = UUID()
    let name: String
    let description: String
    let code: String
    let fileURL: URL?
    let submittedAt: Date
}

enum PluginSubmissionError: LocalizedError {
    case invalidName
    case invalidDescription
    case noContent
    case invalidCode
    case dangerousCode
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Plugin name is required"
        case .invalidDescription:
            return "Plugin description is required"
        case .noContent:
            return "Please provide either a plugin file or code"
        case .invalidCode:
            return "Invalid plugin code format"
        case .dangerousCode:
            return "Plugin code contains potentially dangerous imports"
        }
    }
    }
}

#Preview {
    PluginSubmissionView()
}
