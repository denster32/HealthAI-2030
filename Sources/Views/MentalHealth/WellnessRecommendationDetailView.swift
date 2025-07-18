import SwiftUI

/// Wellness Recommendation Detail View
/// Provides detailed information and step-by-step guidance for wellness recommendations
@available(iOS 18.0, macOS 15.0, *)
public struct WellnessRecommendationDetailView: View {
    
    // MARK: - Properties
    let recommendation: WellnessRecommendation
    let mentalHealthEngine: AdvancedMentalHealthEngine
    
    // MARK: - State
    @State private var isCompleted = false
    @State private var showingSteps = false
    @State private var currentStep = 0
    @State private var progress: Double = 0.0
    @State private var notes = ""
    @State private var showingNotes = false
    @State private var showingImplementation = false
    @State private var startTime: Date?
    @State private var isActive = false
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Progress Section
                    progressSection
                    
                    // Implementation Steps
                    implementationSection
                    
                    // Benefits Section
                    benefitsSection
                    
                    // Tips Section
                    tipsSection
                    
                    // Timer Section (if applicable)
                    if recommendation.duration > 0 {
                        timerSection
                    }
                    
                    // Action Section
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Wellness Recommendation")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Notes") {
                        showingNotes = true
                    }
                    .foregroundColor(.purple)
                }
            }
        }
        .sheet(isPresented: $showingNotes) {
            WellnessNotesView(notes: $notes, recommendation: recommendation)
        }
        .sheet(isPresented: $showingImplementation) {
            WellnessImplementationGuideView(recommendation: recommendation)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon and Title
            HStack {
                Image(systemName: recommendationIcon)
                    .font(.system(size: 50))
                    .foregroundColor(priorityColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        PriorityBadge(priority: recommendation.priority)
                        
                        Spacer()
                        
                        Label("\(Int(recommendation.estimatedImpact * 100))% Impact", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Description
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            // Category and Duration
            HStack {
                Label(recommendation.category.rawValue.capitalized, systemImage: categoryIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if recommendation.duration > 0 {
                    Label(formatDuration(recommendation.duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Implementation Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                .scaleEffect(y: 2)
            
            HStack {
                Text("Not Started")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Implementation Section
    private var implementationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Implementation Steps")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(showingSteps ? "Hide" : "Show") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSteps.toggle()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.purple)
            }
            
            if showingSteps {
                VStack(spacing: 12) {
                    ForEach(Array(implementationSteps.enumerated()), id: \.offset) { index, step in
                        ImplementationStepCard(
                            step: step,
                            stepNumber: index + 1,
                            isCompleted: index < currentStep,
                            isCurrent: index == currentStep
                        ) {
                            if index <= currentStep {
                                currentStep = min(index + 1, implementationSteps.count - 1)
                                updateProgress()
                            }
                        }
                    }
                }
            }
            
            Button("View Implementation Guide") {
                showingImplementation = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Expected Benefits")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(expectedBenefits, id: \.self) { benefit in
                    BenefitCard(benefit: benefit)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pro Tips")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(proTips, id: \.self) { tip in
                    TipCard(tip: tip)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Timer Section
    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Timer")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                if isActive {
                    // Active timer
                    VStack(spacing: 12) {
                        Text(timeRemaining)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                        
                        ProgressView(value: timerProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                        
                        Button("Stop Activity") {
                            stopActivity()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                } else {
                    // Start timer
                    VStack(spacing: 12) {
                        Text("Duration: \(formatDuration(recommendation.duration))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Start Activity") {
                            startActivity()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
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
            if !isCompleted {
                Button("Mark as Completed") {
                    markAsCompleted()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(progress < 1.0)
                
                Button("Start Implementation") {
                    startImplementation()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        Text("Completed!")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Text("Great job! You've successfully implemented this wellness recommendation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Methods
    private var recommendationIcon: String {
        switch recommendation.type {
        case .stressManagement: return "brain.head.profile"
        case .moodImprovement: return "face.smiling"
        case .energyBoost: return "bolt.fill"
        case .focusImprovement: return "target"
        case .socialConnection: return "person.2.fill"
        case .sleepImprovement: return "bed.double.fill"
        }
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private var categoryIcon: String {
        switch recommendation.category {
        case .stress: return "brain.head.profile"
        case .mood: return "face.smiling"
        case .energy: return "bolt.fill"
        case .focus: return "target"
        case .social: return "person.2.fill"
        case .sleep: return "bed.double.fill"
        }
    }
    
    private var implementationSteps: [String] {
        switch recommendation.type {
        case .stressManagement:
            return [
                "Find a quiet, comfortable space",
                "Sit or lie down in a relaxed position",
                "Close your eyes and take deep breaths",
                "Focus on your breath for 5 minutes",
                "Gradually return to normal breathing"
            ]
        case .moodImprovement:
            return [
                "Identify your current mood",
                "Choose an uplifting activity",
                "Engage in the activity for 10 minutes",
                "Notice any mood changes",
                "Reflect on what helped"
            ]
        case .energyBoost:
            return [
                "Drink a glass of water",
                "Do some light stretching",
                "Take a short walk",
                "Practice deep breathing",
                "Eat a healthy snack"
            ]
        case .focusImprovement:
            return [
                "Eliminate distractions",
                "Set a clear goal for the session",
                "Use the Pomodoro technique",
                "Take short breaks",
                "Review your progress"
            ]
        case .socialConnection:
            return [
                "Choose someone to reach out to",
                "Send a thoughtful message",
                "Plan a brief conversation",
                "Share something positive",
                "Listen actively and respond"
            ]
        case .sleepImprovement:
            return [
                "Create a relaxing bedtime routine",
                "Avoid screens 1 hour before bed",
                "Ensure your bedroom is comfortable",
                "Practice relaxation techniques",
                "Maintain a consistent sleep schedule"
            ]
        }
    }
    
    private var expectedBenefits: [String] {
        switch recommendation.type {
        case .stressManagement:
            return [
                "Reduced stress and anxiety levels",
                "Improved emotional regulation",
                "Better sleep quality",
                "Enhanced overall well-being"
            ]
        case .moodImprovement:
            return [
                "Elevated mood and positive outlook",
                "Increased motivation and energy",
                "Better stress resilience",
                "Improved social interactions"
            ]
        case .energyBoost:
            return [
                "Increased physical and mental energy",
                "Improved focus and concentration",
                "Better productivity and performance",
                "Enhanced mood and motivation"
            ]
        case .focusImprovement:
            return [
                "Enhanced concentration and attention",
                "Improved productivity and efficiency",
                "Better task completion",
                "Reduced mental fatigue"
            ]
        case .socialConnection:
            return [
                "Strengthened relationships",
                "Improved emotional support",
                "Enhanced sense of belonging",
                "Better mental health outcomes"
            ]
        case .sleepImprovement:
            return [
                "Better sleep quality and duration",
                "Improved daytime energy levels",
                "Enhanced cognitive function",
                "Better overall health"
            ]
        }
    }
    
    private var proTips: [String] {
        switch recommendation.type {
        case .stressManagement:
            return [
                "Practice regularly, even when not stressed",
                "Try different techniques to find what works",
                "Be patient with yourself during practice",
                "Combine with physical activity for best results"
            ]
        case .moodImprovement:
            return [
                "Start with small, achievable activities",
                "Track your mood before and after",
                "Build a toolkit of mood-boosting activities",
                "Don't force positivity - acknowledge all emotions"
            ]
        case .energyBoost:
            return [
                "Stay hydrated throughout the day",
                "Take regular movement breaks",
                "Eat balanced meals and snacks",
                "Get adequate sleep for sustained energy"
            ]
        case .focusImprovement:
            return [
                "Start with shorter focus sessions",
                "Gradually increase duration over time",
                "Use environmental cues to signal focus time",
                "Reward yourself for successful focus periods"
            ]
        case .socialConnection:
            return [
                "Start with small, meaningful interactions",
                "Be genuine and authentic in your communication",
                "Listen actively and show interest",
                "Don't pressure yourself to be social constantly"
            ]
        case .sleepImprovement:
            return [
                "Be consistent with your sleep schedule",
                "Create a relaxing pre-sleep routine",
                "Optimize your sleep environment",
                "Be patient - sleep improvements take time"
            ]
        }
    }
    
    private func updateProgress() {
        progress = Double(currentStep + 1) / Double(implementationSteps.count)
    }
    
    private func startImplementation() {
        currentStep = 0
        updateProgress()
    }
    
    private func markAsCompleted() {
        isCompleted = true
        progress = 1.0
        
        // Track completion
        // This would integrate with the mental health engine to track recommendation completion
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        }
    }
    
    private func startActivity() {
        startTime = Date()
        isActive = true
    }
    
    private func stopActivity() {
        isActive = false
        startTime = nil
    }
    
    private var timeRemaining: String {
        guard let startTime = startTime else { return "00:00" }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = max(0, recommendation.duration - elapsed)
        
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var timerProgress: Double {
        guard let startTime = startTime else { return 0.0 }
        
        let elapsed = Date().timeIntervalSince(startTime)
        return min(1.0, elapsed / recommendation.duration)
    }
}

// MARK: - Supporting Views

struct ImplementationStepCard: View {
    let step: String
    let stepNumber: Int
    let isCompleted: Bool
    let isCurrent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Step Number
                ZStack {
                    Circle()
                        .fill(stepColor)
                        .frame(width: 32, height: 32)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Text("\(stepNumber)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                
                // Step Description
                Text(step)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Current indicator
                if isCurrent {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var stepColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .purple
        } else {
            return .gray
        }
    }
    
    private var backgroundColor: Color {
        if isCurrent {
            return Color.purple.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
}

struct BenefitCard: View {
    let benefit: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
            
            Text(benefit)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TipCard: View {
    let tip: String
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundColor(.yellow)
            
            Text(tip)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PriorityBadge: View {
    let priority: WellnessRecommendation.Priority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor)
            .cornerRadius(8)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct WellnessNotesView: View {
    @Binding var notes: String
    let recommendation: WellnessRecommendation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Add your notes about this recommendation...", text: $notes, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(5...10)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct WellnessImplementationGuideView: View {
    let recommendation: WellnessRecommendation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Implementation Guide")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("This guide will help you successfully implement the \(recommendation.title.lowercased()) recommendation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Implementation guide content would go here
                    Text("Detailed implementation guide content...")
                        .font(.body)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Guide")
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
}

// MARK: - Preview
#Preview {
    WellnessRecommendationDetailView(
        recommendation: WellnessRecommendation(
            type: .stressManagement,
            title: "Practice Deep Breathing",
            description: "Your stress level is elevated. Try 5 minutes of deep breathing exercises.",
            priority: .high,
            estimatedImpact: 0.8,
            category: .stress,
            duration: 300 // 5 minutes
        ),
        mentalHealthEngine: AdvancedMentalHealthEngine(
            healthDataManager: HealthDataManager(),
            predictionEngine: AdvancedHealthPredictionEngine(),
            analyticsEngine: AnalyticsEngine()
        )
    )
} 