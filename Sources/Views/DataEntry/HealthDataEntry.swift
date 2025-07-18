import SwiftUI
import HealthAI2030UI

struct HealthDataEntry: View {
    @State private var symptom: String = ""
    @State private var medication: String = ""
    @State private var exercise: String = ""
    @State private var nutrition: String = ""
    @State private var mood: String = ""
    @State private var sleepQuality: String = ""
    
    var body: some View {
        Form {
            HealthFormSection(title: "Symptom Tracking") {
                HealthFormField(text: $symptom, label: "Symptom", placeholder: "Describe your symptom", isSecure: false, error: nil)
            }
            HealthFormSection(title: "Medication Logging") {
                HealthFormField(text: $medication, label: "Medication", placeholder: "Enter medication name", isSecure: false, error: nil)
            }
            HealthFormSection(title: "Exercise Recording") {
                HealthFormField(text: $exercise, label: "Exercise", placeholder: "Describe exercise", isSecure: false, error: nil)
            }
            HealthFormSection(title: "Nutrition Tracking") {
                HealthFormField(text: $nutrition, label: "Nutrition", placeholder: "Describe meal", isSecure: false, error: nil)
            }
            HealthFormSection(title: "Mood Logging") {
                HealthFormField(text: $mood, label: "Mood", placeholder: "How do you feel?", isSecure: false, error: nil)
            }
            HealthFormSection(title: "Sleep Quality Assessment") {
                HealthFormField(text: $sleepQuality, label: "Sleep Quality", placeholder: "Describe your sleep", isSecure: false, error: nil)
            }
        }
        .navigationTitle("Health Data Entry")
        .accessibilityElement(children: .contain)
    }
}
