import SwiftUI

struct OnboardingQuestionnaireView: View {
    @ObservedObject var onboarding = OnboardingManager.shared
    @State private var page: Int = 0
    @State private var showSummary = false
    
    var body: some View {
        NavigationView {
            VStack {
                if showSummary {
                    OnboardingSummaryView()
                } else {
                    TabView(selection: $page) {
                        DemographicsPage().tag(0)
                        LifestylePage().tag(1)
                        HealthHistoryPage().tag(2)
                        MentalHealthPage().tag(3)
                        SocialPage().tag(4)
                        PrivacyPage().tag(5)
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle())
                    HStack {
                        if page > 0 { Button("Back") { page -= 1 } }
                        Spacer()
                        if page < 5 {
                            Button("Next") { page += 1 }
                        } else {
                            Button("Finish") {
                                onboarding.completeOnboarding()
                                showSummary = true
                            }
                        }
                    }.padding()
                }
            }
            .navigationTitle("Welcome to HealthAI 2030")
        }
    }
}

// MARK: - Pages
struct DemographicsPage: View {
    @ObservedObject var onboarding = OnboardingManager.shared
    var body: some View {
        Form {
            Section(header: Text("Demographics")) {
                TextField("Age", text: $onboarding.age)
                TextField("Gender", text: $onboarding.gender)
                TextField("Height (cm)", text: $onboarding.height)
                TextField("Weight (kg)", text: $onboarding.weight)
            }
        }
    }
}

struct LifestylePage: View {
    @ObservedObject var onboarding = OnboardingManager.shared
    var body: some View {
        Form {
            Section(header: Text("Lifestyle")) {
                TextField("Diet (e.g. vegetarian, keto)", text: $onboarding.diet)
                Picker("Smoking", selection: $onboarding.smoking) {
                    ForEach(["Never", "Former", "Current"], id: \ .self) { Text($0) }
                }
                Picker("Alcohol Use", selection: $onboarding.alcohol) {
                    ForEach(["None", "Occasional", "Regular"], id: \ .self) { Text($0) }
                }
                Picker("Drug Use", selection: $onboarding.drugs) {
                    ForEach(["None", "Occasional", "Regular"], id: \ .self) { Text($0) }
                }
                TextField("Physical Activity (hours/week)", text: $onboarding.activity)
            }
        }
    }
}

struct HealthHistoryPage: View {
    @ObservedObject var onboarding = OnboardingManager.shared
    var body: some View {
        Form {
            Section(header: Text("Health History")) {
                TextField("Chronic Conditions", text: $onboarding.conditions)
                TextField("Medications", text: $onboarding.medications)
                TextField("Family History (e.g. heart disease)", text: $onboarding.familyHistory)
            }
        }
    }
}

struct MentalHealthPage: View {
    @ObservedObject var onboarding = OnboardingManager.shared
    var body: some View {
        Form {
            Section(header: Text("Mental Health")) {
                Picker("Mood", selection: $onboarding.mood) {
                    ForEach(["😊", "😐", "😢", "😠"], id: \ .self) { Text($0) }
                }
                TextField("Anxiety/Depression (Y/N)", text: $onboarding.mentalHealth)
                TextField("Stress Level (1-10)", text: $onboarding.stress)
            }
        }
    }
}

struct SocialPage: View {
    @ObservedObject var onboarding = OnboardingManager.shared
    var body: some View {
        Form {
            Section(header: Text("Social & Environment")) {
                TextField("Living Situation", text: $onboarding.livingSituation)
                TextField("Occupation", text: $onboarding.occupation)
                TextField("Support Network", text: $onboarding.supportNetwork)
                TextField("Wearables/Devices", text: $onboarding.devices)
            }
        }
    }
}

struct PrivacyPage: View {
    @ObservedObject var onboarding = OnboardingManager.shared
    var body: some View {
        Form {
            Section(header: Text("Privacy & Consent")) {
                Toggle("Share anonymized data for research", isOn: $onboarding.shareForResearch)
                Toggle("Enable personalized recommendations", isOn: $onboarding.enablePersonalization)
            }
        }
    }
}

struct OnboardingSummaryView: View {
    @ObservedObject var onboarding = OnboardingManager.shared
    var body: some View {
        VStack {
            Text("Thank you!").font(.largeTitle).bold().padding()
            Text("Your information will help us personalize your experience and digital twin.")
            List {
                Text("Age: \(onboarding.age)")
                Text("Gender: \(onboarding.gender)")
                Text("Height: \(onboarding.height) cm")
                Text("Weight: \(onboarding.weight) kg")
                Text("Diet: \(onboarding.diet)")
                Text("Smoking: \(onboarding.smoking)")
                Text("Alcohol: \(onboarding.alcohol)")
                Text("Drugs: \(onboarding.drugs)")
                Text("Activity: \(onboarding.activity) h/wk")
                Text("Chronic Conditions: \(onboarding.conditions)")
                Text("Medications: \(onboarding.medications)")
                Text("Family History: \(onboarding.familyHistory)")
                Text("Mood: \(onboarding.mood)")
                Text("Mental Health: \(onboarding.mentalHealth)")
                Text("Stress: \(onboarding.stress)")
                Text("Living: \(onboarding.livingSituation)")
                Text("Occupation: \(onboarding.occupation)")
                Text("Support: \(onboarding.supportNetwork)")
                Text("Devices: \(onboarding.devices)")
                Text("Share for Research: \(onboarding.shareForResearch ? "Yes" : "No")")
                Text("Personalization: \(onboarding.enablePersonalization ? "Yes" : "No")")
            }
        }
    }
}

// MARK: - OnboardingManager
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    // Demographics
    @Published var age: String = ""
    @Published var gender: String = ""
    @Published var height: String = ""
    @Published var weight: String = ""
    // Lifestyle
    @Published var diet: String = ""
    @Published var smoking: String = "Never"
    @Published var alcohol: String = "None"
    @Published var drugs: String = "None"
    @Published var activity: String = ""
    // Health History
    @Published var conditions: String = ""
    @Published var medications: String = ""
    @Published var familyHistory: String = ""
    // Mental Health
    @Published var mood: String = "😊"
    @Published var mentalHealth: String = ""
    @Published var stress: String = ""
    // Social
    @Published var livingSituation: String = ""
    @Published var occupation: String = ""
    @Published var supportNetwork: String = ""
    @Published var devices: String = ""
    // Privacy
    @Published var shareForResearch: Bool = false
    @Published var enablePersonalization: Bool = true
    // Completion
    func completeOnboarding() {
        // Save to user profile, digital twin, and analytics modules
        DigitalTwinManager.shared.updateWithOnboarding(self)
        AIHealthCoach.shared.updateWithOnboarding(self)
        DeepHealthAnalytics.shared.updateWithOnboarding(self)
    }
}
