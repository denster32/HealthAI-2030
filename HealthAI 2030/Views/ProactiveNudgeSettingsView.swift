import SwiftUI

/// UI for managing proactive nudge settings, feedback, and notification scheduling.
struct ProactiveNudgeSettingsView: View {
    @ObservedObject var nudgeSkill: ProactiveNudgeSkill
    @State private var selectedTypes: Set<String> = []
    @State private var feedbackText: String = ""
    @State private var showTimePicker = false
    @State private var showAR = false
    let allTypes = ["hydration", "movement", "mindfulness", "nutrition", "sleep"]
    
    var body: some View {
        Form {
            Section(header: Text("Nudge Frequency")) {
                Picker("Frequency", selection: $nudgeSkill.frequency) {
                    ForEach(NudgeFrequency.allCases) { freq in
                        Text(freq.rawValue.capitalized).tag(freq)
                    }
                }.pickerStyle(SegmentedPickerStyle())
            }
            Section(header: Text("Nudge Types")) {
                ForEach(allTypes, id: \ .self) { type in
                    Toggle(type.capitalized, isOn: Binding(
                        get: { nudgeSkill.nudgeTypes.contains(type) },
                        set: { isOn in
                            if isOn { nudgeSkill.nudgeTypes.append(type) }
                            else { nudgeSkill.nudgeTypes.removeAll { $0 == type } }
                        }
                    ))
                }
            }
            Section(header: Text("Notification Schedule")) {
                Toggle("Enable Scheduled Nudge", isOn: $nudgeSkill.schedule.enabled)
                if nudgeSkill.schedule.enabled {
                    DatePicker("Time", selection: $nudgeSkill.schedule.time, displayedComponents: .hourAndMinute)
                }
            }
            Section(header: Text("Feedback")) {
                TextField("Your feedback...", text: $feedbackText)
                Button("Submit Feedback") {
                    nudgeSkill.submitFeedback(feedbackText)
                    feedbackText = ""
                }.disabled(feedbackText.isEmpty)
                if !nudgeSkill.feedbackHistory.isEmpty {
                    ForEach(nudgeSkill.feedbackHistory.reversed(), id: \ .self) { feedback in
                        Text(feedback).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Nudge Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showAR = true }) {
                    Label("AR View", systemImage: "arkit")
                }
            }
        }
        .sheet(isPresented: $showAR) {
            ARHealthVisualizerView()
        }
    }
}

#if DEBUG
struct ProactiveNudgeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ProactiveNudgeSettingsView(nudgeSkill: .preview)
    }
}
#endif
