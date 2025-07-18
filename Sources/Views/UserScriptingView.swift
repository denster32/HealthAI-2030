import SwiftUI

struct UserScriptingView: View {
    @ObservedObject var userScriptingManager = UserScriptingManager.shared
    @State private var isEditing = false
    @State private var scriptToEdit: UserScript? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(userScriptingManager.scripts) { script in
                    VStack(alignment: .leading) {
                        Text(script.name)
                            .font(.headline)
                        Text(script.code)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .onTapGesture {
                        scriptToEdit = script
                        isEditing = true
                    }
                }
                .onDelete(perform: deleteScript)
            }
            .navigationTitle("Automations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        scriptToEdit = nil
                        isEditing = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                ScriptEditorView(script: $scriptToEdit)
            }
        }
        .onAppear {
            // Load scripts when the view appears
            // UserScriptingManager.shared.loadScripts() // This is now handled internally by the manager's init
        }
    }

    private func deleteScript(at offsets: IndexSet) {
        offsets.forEach { index in
            let script = userScriptingManager.scripts[index]
            userScriptingManager.deleteScript(id: script.id)
        }
    }
}

struct ScriptEditorView: View {
    @Binding var script: UserScript?
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userScriptingManager = UserScriptingManager.shared

    @State private var scriptName: String = ""
    @State private var scriptCode: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Script Details")) {
                    TextField("Script Name", text: $scriptName)
                    TextEditor(text: $scriptCode)
                        .frame(height: 150)
                        .border(Color.gray.opacity(0.2), width: 1)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Text("Example: WHEN heart_rate > 100 DO send_notification")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(script == nil ? "New Automation" : "Edit Automation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveScript() }
                }
            }
        }
        .onAppear(perform: loadScript)
    }

    private func loadScript() {
        if let script = script {
            scriptName = script.name
            scriptCode = script.code
        }
    }

    private func saveScript() {
        if let existingScript = script {
            // Update existing script
            var updatedScript = existingScript
            updatedScript.name = scriptName
            updatedScript.code = scriptCode
            updatedScript.modified = Date()
            if let index = userScriptingManager.scripts.firstIndex(where: { $0.id == updatedScript.id }) {
                userScriptingManager.scripts[index] = updatedScript
            }
        } else {
            // Create new script
            let newScript = UserScript(id: UUID(), name: scriptName, code: scriptCode, created: Date(), modified: Date())
            userScriptingManager.addScript(newScript)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

extension DSLAction: CustomStringConvertible {
    var description: String {
        switch self {
        case .setHomeLights(let color, let time):
            return "Set home lights to \(color) at \(time)"
        case .playMeditationAudio(let track):
            return "Play meditation audio: \(track)"
        case .sendNotification(let message):
            return "Send notification: \(message)"
        case .logHealthMetric(let metric, let value):
            return "Log health metric \(metric) with value \(value)"
        case .adjustSleepGoal(let hours):
            return "Adjust sleep goal to \(hours) hours"
        case .triggerSmartHomeScene(let sceneName):
            return "Trigger smart home scene: \(sceneName)"
        case .startBreathingExercise(let duration):
            return "Start breathing exercise for \(duration) minutes"
        case .recordMood(let mood):
            return "Record mood: \(mood)"
        case .recommendContent(let category):
            return "Recommend content in category: \(category)"
        case .updatePrivacySetting(let setting, let enabled):
            return "Update privacy setting '\(setting)' to \(enabled)"
        }
    }
}

