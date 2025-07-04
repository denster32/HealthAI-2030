import SwiftUI

// MARK: - Log Mood Modal

struct LogMoodModal: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mentalHealthManager = MentalHealthManager.shared
    @State private var selectedMood: Mood = .neutral
    @State private var intensity: Double = 0.5
    @State private var trigger: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Mood Selection
                VStack(spacing: 16) {
                    Text("How are you feeling?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            MoodButton(
                                mood: mood,
                                isSelected: selectedMood == mood,
                                action: { selectedMood = mood }
                            )
                        }
                    }
                }
                
                // Intensity Slider
                VStack(spacing: 12) {
                    Text("Intensity: \(Int(intensity * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Slider(value: $intensity, in: 0...1, step: 0.1)
                        .accentColor(moodColor)
                }
                
                // Trigger Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("What triggered this mood? (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("e.g., work stress, good news, exercise...", text: $trigger)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Log Mood") {
                        Task {
                            await mentalHealthManager.recordMoodChange(
                                selectedMood,
                                intensity: intensity,
                                trigger: trigger.isEmpty ? nil : trigger
                            )
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("Log Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var moodColor: Color {
        switch selectedMood {
        case .verySad: return .red
        case .sad: return .orange
        case .neutral: return .yellow
        case .happy: return .green
        case .veryHappy: return .blue
        }
    }
}

struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: moodIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : moodColor)
                
                Text(mood.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? moodColor : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var moodIcon: String {
        switch mood {
        case .verySad: return "face.dashed"
        case .sad: return "face.dashed.fill"
        case .neutral: return "face.neutral"
        case .happy: return "face.smiling"
        case .veryHappy: return "face.smiling.inverse"
        }
    }
    
    private var moodColor: Color {
        switch mood {
        case .verySad: return .red
        case .sad: return .orange
        case .neutral: return .yellow
        case .happy: return .green
        case .veryHappy: return .blue
        }
    }
}

// MARK: - Breathing Exercise Modal

struct BreathingExerciseModal: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var respiratoryManager = RespiratoryHealthManager.shared
    @State private var selectedTechnique: BreathingRecommendation.BreathingTechnique = .boxBreathing
    @State private var duration: TimeInterval = 300 // 5 minutes
    @State private var isExerciseActive = false
    @State private var remainingTime: TimeInterval = 300
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isExerciseActive {
                    // Active Exercise View
                    VStack(spacing: 20) {
                        Text("Breathing Exercise")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Breathing Animation
                        ZStack {
                            Circle()
                                .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                                .frame(width: 200, height: 200)
                            
                            Circle()
                                .scale(isExerciseActive ? 1.2 : 0.8)
                                .foregroundColor(.blue.opacity(0.6))
                                .frame(width: 200, height: 200)
                                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isExerciseActive)
                        }
                        
                        Text(breathingInstruction)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text(timeString(from: remainingTime))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Button("Stop Exercise") {
                            stopExercise()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                } else {
                    // Setup View
                    VStack(spacing: 20) {
                        Text("Breathing Exercise")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        // Technique Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Technique")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(BreathingRecommendation.BreathingTechnique.allCases, id: \.self) { technique in
                                TechniqueButton(
                                    technique: technique,
                                    isSelected: selectedTechnique == technique,
                                    action: { selectedTechnique = technique }
                                )
                            }
                        }
                        
                        // Duration Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration: \(Int(duration / 60)) minutes")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Slider(value: $duration, in: 60...900, step: 60) // 1-15 minutes
                                .accentColor(.blue)
                        }
                        
                        Button("Start Exercise") {
                            startExercise()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                
                Spacer()
                
                if !isExerciseActive {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("Breathing Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onReceive(timer) { _ in
                if isExerciseActive && remainingTime > 0 {
                    remainingTime -= 1
                    if remainingTime <= 0 {
                        stopExercise()
                    }
                }
            }
        }
    }
    
    private var breathingInstruction: String {
        switch selectedTechnique {
        case .boxBreathing:
            return "Breathe in for 4\nHold for 4\nBreathe out for 4\nHold for 4"
        case .fourSevenEight:
            return "Breathe in for 4\nHold for 7\nBreathe out for 8"
        case .pursedLip:
            return "Breathe in through nose\nBreathe out through pursed lips"
        case .bellyBreathing:
            return "Breathe deeply into your belly\nFeel your stomach expand"
        }
    }
    
    private func startExercise() {
        isExerciseActive = true
        remainingTime = duration
    }
    
    private func stopExercise() {
        isExerciseActive = false
        remainingTime = duration
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct TechniqueButton: View {
    let technique: BreathingRecommendation.BreathingTechnique
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: techniqueIcon)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(technique.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(techniqueDescription)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var techniqueIcon: String {
        switch technique {
        case .boxBreathing: return "square.fill"
        case .fourSevenEight: return "timer"
        case .pursedLip: return "mouth"
        case .bellyBreathing: return "figure.core.training"
        }
    }
    
    private var techniqueDescription: String {
        switch technique {
        case .boxBreathing: return "Equal breathing pattern"
        case .fourSevenEight: return "Relaxation technique"
        case .pursedLip: return "Slow, controlled breathing"
        case .bellyBreathing: return "Deep diaphragmatic breathing"
        }
    }
}

// MARK: - Mental State Modal

struct MentalStateModal: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mentalHealthManager = MentalHealthManager.shared
    @State private var selectedState: MentalState = .neutral
    @State private var intensity: Double = 0.5
    @State private var context: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Mental State Selection
                VStack(spacing: 16) {
                    Text("What's your mental state?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(MentalState.allCases, id: \.self) { state in
                            MentalStateButton(
                                state: state,
                                isSelected: selectedState == state,
                                action: { selectedState = state }
                            )
                        }
                    }
                }
                
                // Intensity Slider
                VStack(spacing: 12) {
                    Text("Intensity: \(Int(intensity * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Slider(value: $intensity, in: 0...1, step: 0.1)
                        .accentColor(stateColor)
                }
                
                // Context Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Context (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("e.g., work meeting, exercise, social event...", text: $context)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Record State") {
                        Task {
                            await mentalHealthManager.recordMentalState(
                                selectedState,
                                intensity: intensity
                            )
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle("Mental State")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var stateColor: Color {
        switch selectedState {
        case .veryNegative: return .red
        case .negative: return .orange
        case .neutral: return .yellow
        case .positive: return .green
        case .veryPositive: return .blue
        }
    }
}

struct MentalStateButton: View {
    let state: MentalState
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: stateIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : stateColor)
                
                Text(state.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? stateColor : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var stateIcon: String {
        switch state {
        case .veryNegative: return "exclamationmark.triangle.fill"
        case .negative: return "minus.circle"
        case .neutral: return "circle"
        case .positive: return "plus.circle"
        case .veryPositive: return "star.fill"
        }
    }
    
    private var stateColor: Color {
        switch state {
        case .veryNegative: return .red
        case .negative: return .orange
        case .neutral: return .yellow
        case .positive: return .green
        case .veryPositive: return .blue
        }
    }
}


// MARK: - Health Check Modal

struct HealthCheckModal: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var mentalHealthManager = MentalHealthManager.shared
    @StateObject private var advancedCardiacManager = AdvancedCardiacManager.shared
    @StateObject private var respiratoryHealthManager = RespiratoryHealthManager.shared
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading health data...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Health Overview
                        VStack(spacing: 16) {
                            Text("Health Overview")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                HealthMetricCard(
                                    title: "Mental Health",
                                    value: "\(Int(mentalHealthManager.mentalHealthScore * 100))%",
                                    icon: "brain.head.profile",
                                    color: .purple,
                                    status: mentalHealthStatus
                                )
                                
                                HealthMetricCard(
                                    title: "Cardiac Health",
                                    value: "\(Int(advancedCardiacManager.heartRateData.first?.value ?? 0)) BPM",
                                    icon: "heart.fill",
                                    color: .red,
                                    status: cardiacStatus
                                )
                                
                                HealthMetricCard(
                                    title: "Respiratory",
                                    value: "\(String(format: "%.1f", respiratoryHealthManager.oxygenSaturation))%",
                                    icon: "lungs.fill",
                                    color: .blue,
                                    status: respiratoryStatus
                                )
                                
                                HealthMetricCard(
                                    title: "Sleep Quality",
                                    value: "\(Int(SleepOptimizationManager.shared.sleepQuality * 100))%",
                                    icon: "bed.double.fill",
                                    color: .indigo,
                                    status: sleepStatus
                                )
                            }
                        }
                        
                        // Recommendations
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommendations")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(healthRecommendations, id: \.self) { recommendation in
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text(recommendation)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Health Check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadHealthData()
            }
        }
    }
    
    private func loadHealthData() {
        Task {
            await healthDataManager.refreshHealthData()
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private var mentalHealthStatus: HealthStatus {
        let score = mentalHealthManager.mentalHealthScore
        if score >= 0.8 { return .excellent }
        if score >= 0.6 { return .good }
        if score >= 0.4 { return .fair }
        return .poor
    }
    
    private var cardiacStatus: HealthStatus {
        let heartRate = advancedCardiacManager.heartRateData.first?.value ?? 0
        if heartRate >= 60 && heartRate <= 100 { return .excellent }
        if heartRate >= 50 && heartRate <= 110 { return .good }
        if heartRate >= 40 && heartRate <= 120 { return .fair }
        return .poor
    }
    
    private var respiratoryStatus: HealthStatus {
        let oxygen = respiratoryHealthManager.oxygenSaturation
        if oxygen >= 98 { return .excellent }
        if oxygen >= 95 { return .good }
        if oxygen >= 90 { return .fair }
        return .poor
    }
    
    private var sleepStatus: HealthStatus {
        let quality = SleepOptimizationManager.shared.sleepQuality
        if quality >= 0.8 { return .excellent }
        if quality >= 0.6 { return .good }
        if quality >= 0.4 { return .fair }
        return .poor
    }
    
    private var healthRecommendations: [String] {
        var recommendations: [String] = []
        
        if mentalHealthManager.stressLevel == .high {
            recommendations.append("Consider a mindfulness session to reduce stress")
        }
        
        if respiratoryHealthManager.respiratoryRate > 20 {
            recommendations.append("Try a breathing exercise to calm your breathing")
        }
        
        if SleepOptimizationManager.shared.sleepQuality < 0.6 {
            recommendations.append("Review your sleep optimization settings")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Your health metrics look good! Keep up the great work.")
        }
        
        return recommendations
    }
}

struct HealthMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let status: HealthStatus
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(status.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(status.color.opacity(0.2))
                .foregroundColor(status.color)
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types


enum HealthStatus {
    case excellent
    case good
    case fair
    case poor
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .red
        }
    }
}

// MARK: - Extensions

extension BreathingRecommendation.BreathingTechnique: CaseIterable {
    public static var allCases: [BreathingRecommendation.BreathingTechnique] {
        return [.boxBreathing, .fourSevenEight, .pursedLip, .bellyBreathing]
    }
} 