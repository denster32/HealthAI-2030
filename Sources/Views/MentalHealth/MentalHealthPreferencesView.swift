import SwiftUI

/// Mental Health Preferences View
/// Allows users to configure wellness goals, stress management preferences, and monitoring settings
@available(iOS 18.0, macOS 15.0, *)
public struct MentalHealthPreferencesView: View {
    
    // MARK: - State
    @ObservedObject var mentalHealthEngine: AdvancedMentalHealthEngine
    @State private var stressManagement: WellnessPreferences.StressManagementType = .breathing
    @State private var moodTracking: WellnessPreferences.MoodTrackingType = .daily
    @State private var meditation: WellnessPreferences.MeditationType = .guided
    @State private var exercise: WellnessPreferences.ExerciseType = .walking
    @State private var socialConnection: WellnessPreferences.SocialConnectionType = .family
    @State private var showingStressPrediction = false
    @State private var stressPrediction: StressPrediction?
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Stress Management Preferences
                    stressManagementSection
                    
                    // Mood Tracking Preferences
                    moodTrackingSection
                    
                    // Meditation Preferences
                    meditationSection
                    
                    // Exercise Preferences
                    exerciseSection
                    
                    // Social Connection Preferences
                    socialConnectionSection
                    
                    // Stress Prediction
                    stressPredictionSection
                    
                    // Action Buttons
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Mental Health Preferences")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreferences()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentPreferences()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("Mental Health Preferences")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Configure your mental health goals and preferences for personalized wellness recommendations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Stress Management Section
    private var stressManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stress Management")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(WellnessPreferences.StressManagementType.allCases, id: \.self) { type in
                    PreferenceOptionCard(
                        title: type.displayName,
                        description: type.description,
                        icon: type.icon,
                        isSelected: stressManagement == type
                    ) {
                        stressManagement = type
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Mood Tracking Section
    private var moodTrackingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Tracking")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(WellnessPreferences.MoodTrackingType.allCases, id: \.self) { type in
                    PreferenceOptionCard(
                        title: type.displayName,
                        description: type.description,
                        icon: type.icon,
                        isSelected: moodTracking == type
                    ) {
                        moodTracking = type
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Meditation Section
    private var meditationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meditation Preferences")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(WellnessPreferences.MeditationType.allCases, id: \.self) { type in
                    PreferenceOptionCard(
                        title: type.displayName,
                        description: type.description,
                        icon: type.icon,
                        isSelected: meditation == type
                    ) {
                        meditation = type
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Exercise Section
    private var exerciseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercise Preferences")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(WellnessPreferences.ExerciseType.allCases, id: \.self) { type in
                    PreferenceOptionCard(
                        title: type.displayName,
                        description: type.description,
                        icon: type.icon,
                        isSelected: exercise == type
                    ) {
                        exercise = type
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Social Connection Section
    private var socialConnectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Connection")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(WellnessPreferences.SocialConnectionType.allCases, id: \.self) { type in
                    PreferenceOptionCard(
                        title: type.displayName,
                        description: type.description,
                        icon: type.icon,
                        isSelected: socialConnection == type
                    ) {
                        socialConnection = type
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Stress Prediction Section
    private var stressPredictionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stress Prediction")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Get Prediction") {
                    getStressPrediction()
                }
                .font(.subheadline)
                .foregroundColor(.purple)
            }
            
            if let prediction = stressPrediction {
                StressPredictionCard(prediction: prediction)
            } else {
                Text("Get AI-powered stress predictions based on your current patterns and preferences.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Action Section
    private var actionSection: some View {
        VStack(spacing: 16) {
            Button("Save Preferences") {
                savePreferences()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("Reset to Defaults") {
                resetToDefaults()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
    
    // MARK: - Helper Methods
    private func loadCurrentPreferences() {
        let preferences = mentalHealthEngine.getUserWellnessPreferences()
        stressManagement = preferences.stressManagement
        moodTracking = preferences.moodTracking
        meditation = preferences.meditation
        exercise = preferences.exercise
        socialConnection = preferences.socialConnection
    }
    
    private func savePreferences() {
        let preferences = WellnessPreferences(
            stressManagement: stressManagement,
            moodTracking: moodTracking,
            meditation: meditation,
            exercise: exercise,
            socialConnection: socialConnection
        )
        
        Task {
            await mentalHealthEngine.setWellnessPreferences(preferences)
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    private func resetToDefaults() {
        stressManagement = .breathing
        moodTracking = .daily
        meditation = .guided
        exercise = .walking
        socialConnection = .family
    }
    
    private func getStressPrediction() {
        Task {
            do {
                let prediction = try await mentalHealthEngine.getStressPrediction()
                await MainActor.run {
                    self.stressPrediction = prediction
                }
            } catch {
                print("Failed to get stress prediction: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct PreferenceOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .purple)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.purple : Color.purple.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.purple : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StressPredictionCard: View {
    let prediction: StressPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Stress Prediction")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Confidence: \(Int(prediction.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Predicted Level:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(prediction.predictedStressLevel.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(prediction.predictedStressLevel.color)
                }
                
                HStack {
                    Text("Timeframe:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTimeframe(prediction.timeframe))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            if !prediction.factors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contributing Factors:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(prediction.factors, id: \.self) { factor in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                            
                            Text(factor)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            if !prediction.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(prediction.recommendations, id: \.self) { recommendation in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatTimeframe(_ timeframe: TimeInterval) -> String {
        let hours = Int(timeframe / 3600)
        if hours < 24 {
            return "\(hours) hours"
        } else {
            let days = hours / 24
            return "\(days) days"
        }
    }
}

// MARK: - Extensions

extension WellnessPreferences.StressManagementType {
    var displayName: String {
        switch self {
        case .breathing: return "Breathing Exercises"
        case .meditation: return "Meditation"
        case .exercise: return "Physical Exercise"
        case .social: return "Social Connection"
        case .professional: return "Professional Support"
        }
    }
    
    var description: String {
        switch self {
        case .breathing: return "Deep breathing and relaxation techniques"
        case .meditation: return "Mindfulness and meditation practices"
        case .exercise: return "Physical activity and movement"
        case .social: return "Connecting with friends and family"
        case .professional: return "Seeking professional mental health support"
        }
    }
    
    var icon: String {
        switch self {
        case .breathing: return "lungs.fill"
        case .meditation: return "brain.head.profile"
        case .exercise: return "figure.walk"
        case .social: return "person.2.fill"
        case .professional: return "stethoscope"
        }
    }
}

extension WellnessPreferences.MoodTrackingType {
    var displayName: String {
        switch self {
        case .daily: return "Daily Tracking"
        case .weekly: return "Weekly Tracking"
        case .event: return "Event-Based"
        case .continuous: return "Continuous Monitoring"
        }
    }
    
    var description: String {
        switch self {
        case .daily: return "Track mood once per day"
        case .weekly: return "Weekly mood assessments"
        case .event: return "Track mood during specific events"
        case .continuous: return "Real-time mood monitoring"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "calendar"
        case .weekly: return "calendar.badge.clock"
        case .event: return "flag.fill"
        case .continuous: return "waveform.path.ecg"
        }
    }
}

extension WellnessPreferences.MeditationType {
    var displayName: String {
        switch self {
        case .guided: return "Guided Meditation"
        case .mindfulness: return "Mindfulness"
        case .breathing: return "Breathing Focus"
        case .bodyScan: return "Body Scan"
        case .lovingKindness: return "Loving Kindness"
        }
    }
    
    var description: String {
        switch self {
        case .guided: return "Audio-guided meditation sessions"
        case .mindfulness: return "Present moment awareness"
        case .breathing: return "Breath-focused meditation"
        case .bodyScan: return "Progressive body relaxation"
        case .lovingKindness: return "Compassion and kindness practice"
        }
    }
    
    var icon: String {
        switch self {
        case .guided: return "speaker.wave.2"
        case .mindfulness: return "eye.fill"
        case .breathing: return "lungs.fill"
        case .bodyScan: return "figure.walk"
        case .lovingKindness: return "heart.fill"
        }
    }
}

extension WellnessPreferences.ExerciseType {
    var displayName: String {
        switch self {
        case .walking: return "Walking"
        case .running: return "Running"
        case .yoga: return "Yoga"
        case .strength: return "Strength Training"
        case .cardio: return "Cardio"
        }
    }
    
    var description: String {
        switch self {
        case .walking: return "Gentle walking and movement"
        case .running: return "Running and jogging"
        case .yoga: return "Yoga and stretching"
        case .strength: return "Strength and resistance training"
        case .cardio: return "Cardiovascular exercise"
        }
    }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .yoga: return "figure.mind.and.body"
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.circle.fill"
        }
    }
}

extension WellnessPreferences.SocialConnectionType {
    var displayName: String {
        switch self {
        case .family: return "Family"
        case .friends: return "Friends"
        case .colleagues: return "Colleagues"
        case .community: return "Community"
        case .professional: return "Professional"
        }
    }
    
    var description: String {
        switch self {
        case .family: return "Connect with family members"
        case .friends: return "Spend time with friends"
        case .colleagues: return "Build workplace relationships"
        case .community: return "Engage with community groups"
        case .professional: return "Professional networking"
        }
    }
    
    var icon: String {
        switch self {
        case .family: return "house.fill"
        case .friends: return "person.2.fill"
        case .colleagues: return "building.2.fill"
        case .community: return "person.3.fill"
        case .professional: return "briefcase.fill"
        }
    }
}

// MARK: - Preview
#Preview {
    MentalHealthPreferencesView(mentalHealthEngine: AdvancedMentalHealthEngine(
        healthDataManager: HealthDataManager(),
        predictionEngine: AdvancedHealthPredictionEngine(),
        analyticsEngine: AnalyticsEngine()
    ))
} 