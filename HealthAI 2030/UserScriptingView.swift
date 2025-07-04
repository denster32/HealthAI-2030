import SwiftUI

struct UserScriptingView: View {
    @State private var scripts: [UserScript] = []
    @State private var isEditing = false
    @State private var scriptToEdit: UserScript? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(scripts) { script in
                    VStack(alignment: .leading) {
                        Text("WHEN \(script.condition.metric) \(script.condition.comparison) \(script.condition.value)")
                            .font(.headline)
                        ForEach(script.actions, id: \.self) { action in
                            Text("DO \(action.description)")
                                .font(.subheadline)
                        }
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
                ScriptEditorView(script: $scriptToEdit, scripts: $scripts)
            }
        }
    }

    private func deleteScript(at offsets: IndexSet) {
        scripts.remove(atOffsets: offsets)
    }
}

struct ScriptEditorView: View {
    @Binding var script: UserScript?
    @Binding var scripts: [UserScript]
    @Environment(\.presentationMode) var presentationMode

    @State private var metric = ""
    @State private var comparison = ">"
    @State private var value = ""
    @State private var actions: [DSLAction] = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Condition")) {
                    TextField("Metric (e.g., heart_rate)", text: $metric)
                    Picker("Comparison", selection: $comparison) {
                        Text(">").tag(">")
                        Text("<").tag("<" )
                        Text("==").tag("==")
                    }
                    TextField("Value", text: $value)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Actions")) {
                    // Action editor will go here
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
            metric = script.condition.metric
            comparison = script.condition.comparison
            value = String(script.condition.value)
            actions = script.actions
        }
    }

    private func saveScript() {
        guard let doubleValue = Double(value) else { return } // Basic validation
        let condition = DSLCondition(metric: metric, comparison: comparison, value: doubleValue)
        
        if let index = scripts.firstIndex(where: { $0.id == script?.id }) {
            scripts[index].condition = condition
            scripts[index].actions = actions
        } else {
            let newScript = UserScript(id: UUID(), condition: condition, actions: actions)
            scripts.append(newScript)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

extension DSLAction: Hashable {
    var description: String {
        switch self {
        case .setHomeLights(let color, let time):
            return "Set home lights to \(color) at \(time)"
        case .playMeditationAudio(let track):
            return "Play meditation audio: \(track)"
        case .sendNotification(let message):
            return "Send notification: \(message)"
        }
    }
}

