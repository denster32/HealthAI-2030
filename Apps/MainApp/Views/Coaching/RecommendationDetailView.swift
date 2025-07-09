import SwiftUI

/// Recommendation Detail View
/// Provides detailed information and step-by-step guidance for health recommendations
@available(iOS 18.0, macOS 15.0, *)
public struct RecommendationDetailView: View {
    
    // MARK: - Properties
    let recommendation: HealthRecommendation
    let coachingEngine: RealTimeHealthCoachingEngine
    
    // MARK: - State
    @State private var isCompleted = false
    @State private var showingSteps = false
    @State private var currentStep = 0
    @State private var progress: Double = 0.0
    @State private var notes = ""
    @State private var showingNotes = false
    
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
                    
                    // Steps Section
                    stepsSection
                    
                    // Benefits Section
                    benefitsSection
                    
                    // Tips Section
                    tipsSection
                    
                    // Action Section
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Recommendation")
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
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingNotes) {
            NotesView(notes: $notes, recommendation: recommendation)
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
                        
                        Label("\(recommendation.estimatedTime)m", systemImage: "clock")
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
            
            // Difficulty and Category
            HStack {
                Label(recommendation.difficulty.rawValue.capitalized, systemImage: "speedometer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label(recommendation.category.rawValue.capitalized, systemImage: categoryIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                Text("Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
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
    
    // MARK: - Steps Section
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Step-by-Step Guide")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(showingSteps ? "Hide" : "Show") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSteps.toggle()
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if showingSteps {
                VStack(spacing: 12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        StepCard(
                            step: step,
                            stepNumber: index + 1,
                            isCompleted: index < currentStep,
                            isCurrent: index == currentStep
                        ) {
                            if index <= currentStep {
                                currentStep = min(index + 1, steps.count - 1)
                                updateProgress()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Benefits")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(benefits, id: \.self) { benefit in
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
                ForEach(tips, id: \.self) { tip in
                    TipCard(tip: tip)
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
                
                Button("Start Recommendation") {
                    startRecommendation()
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
                    
                    Text("Great job! You've successfully completed this recommendation.")
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
        case .cardiovascular: return "heart.fill"
        case .sleep: return "bed.double.fill"
        case .stress: return "brain.head.profile"
        case .nutrition: return "leaf.fill"
        case .exercise: return "figure.walk"
        case .mentalHealth: return "brain"
        case .lifestyle: return "house.fill"
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
        case .exercise: return "figure.walk"
        case .nutrition: return "leaf.fill"
        case .lifestyle: return "house.fill"
        case .mentalHealth: return "brain"
        case .sleep: return "bed.double.fill"
        }
    }
    
    private var steps: [String] {
        switch recommendation.type {
        case .cardiovascular:
            return [
                "Check your current heart rate",
                "Start with 5 minutes of light cardio",
                "Gradually increase intensity",
                "Monitor your heart rate during exercise",
                "Cool down for 5 minutes"
            ]
        case .sleep:
            return [
                "Set a consistent bedtime",
                "Create a relaxing bedtime routine",
                "Avoid screens 1 hour before bed",
                "Keep your bedroom cool and dark",
                "Track your sleep quality"
            ]
        case .stress:
            return [
                "Find a quiet, comfortable space",
                "Sit or lie down comfortably",
                "Close your eyes and breathe deeply",
                "Focus on your breath for 5 minutes",
                "Gradually return to normal awareness"
            ]
        case .nutrition:
            return [
                "Plan your meals for the week",
                "Include a variety of colorful vegetables",
                "Choose lean protein sources",
                "Limit processed foods and sugars",
                "Stay hydrated throughout the day"
            ]
        case .exercise:
            return [
                "Start with a 5-minute warm-up",
                "Choose an activity you enjoy",
                "Aim for 30 minutes of moderate activity",
                "Include strength training 2-3 times per week",
                "Cool down and stretch"
            ]
        case .mentalHealth:
            return [
                "Practice daily gratitude",
                "Connect with friends and family",
                "Engage in activities you enjoy",
                "Practice mindfulness or meditation",
                "Seek professional help if needed"
            ]
        case .lifestyle:
            return [
                "Establish a daily routine",
                "Get adequate sleep",
                "Stay physically active",
                "Maintain social connections",
                "Practice stress management"
            ]
        }
    }
    
    private var benefits: [String] {
        switch recommendation.type {
        case .cardiovascular:
            return [
                "Improved heart health and circulation",
                "Increased energy levels",
                "Better cardiovascular fitness",
                "Reduced risk of heart disease"
            ]
        case .sleep:
            return [
                "Better cognitive function",
                "Improved mood and emotional regulation",
                "Enhanced immune system",
                "Better physical recovery"
            ]
        case .stress:
            return [
                "Reduced anxiety and tension",
                "Improved mental clarity",
                "Better emotional balance",
                "Enhanced overall well-being"
            ]
        case .nutrition:
            return [
                "Improved energy levels",
                "Better digestive health",
                "Enhanced immune function",
                "Maintained healthy weight"
            ]
        case .exercise:
            return [
                "Increased strength and endurance",
                "Better cardiovascular health",
                "Improved mood and mental health",
                "Enhanced quality of life"
            ]
        case .mentalHealth:
            return [
                "Better emotional well-being",
                "Improved stress management",
                "Enhanced relationships",
                "Greater life satisfaction"
            ]
        case .lifestyle:
            return [
                "Better overall health",
                "Improved quality of life",
                "Enhanced well-being",
                "Greater life satisfaction"
            ]
        }
    }
    
    private var tips: [String] {
        switch recommendation.type {
        case .cardiovascular:
            return [
                "Start slowly and gradually increase intensity",
                "Listen to your body and don't overexert",
                "Stay hydrated during exercise",
                "Consider working with a fitness professional"
            ]
        case .sleep:
            return [
                "Keep a consistent sleep schedule",
                "Create a relaxing bedtime routine",
                "Make your bedroom a sleep sanctuary",
                "Avoid caffeine in the afternoon"
            ]
        case .stress:
            return [
                "Practice regularly, even for just a few minutes",
                "Find a technique that works for you",
                "Be patient with yourself",
                "Consider guided meditation apps"
            ]
        case .nutrition:
            return [
                "Plan and prepare meals ahead of time",
                "Read food labels and ingredients",
                "Eat mindfully and savor your food",
                "Don't skip meals"
            ]
        case .exercise:
            return [
                "Find activities you genuinely enjoy",
                "Start with small, achievable goals",
                "Mix different types of exercise",
                "Listen to your body and rest when needed"
            ]
        case .mentalHealth:
            return [
                "Practice self-compassion",
                "Set healthy boundaries",
                "Engage in activities that bring joy",
                "Don't hesitate to seek professional help"
            ]
        case .lifestyle:
            return [
                "Make small, sustainable changes",
                "Focus on consistency over perfection",
                "Celebrate your progress",
                "Be patient with yourself"
            ]
        }
    }
    
    private func updateProgress() {
        progress = Double(currentStep + 1) / Double(steps.count)
    }
    
    private func startRecommendation() {
        currentStep = 0
        updateProgress()
    }
    
    private func markAsCompleted() {
        isCompleted = true
        progress = 1.0
        
        // Track completion
        let interaction = UserInteraction(
            type: .recommendationFollowed,
            message: "Completed recommendation: \(recommendation.title)",
            timestamp: Date(),
            metadata: [
                "recommendation_id": recommendation.id.uuidString,
                "recommendation_type": recommendation.type.rawValue
            ]
        )
        
        Task {
            do {
                _ = try await coachingEngine.processUserInteraction(interaction)
            } catch {
                print("Failed to track recommendation completion: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct StepCard: View {
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
                        .foregroundColor(.blue)
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
            return .blue
        } else {
            return .gray
        }
    }
    
    private var backgroundColor: Color {
        if isCurrent {
            return Color.blue.opacity(0.1)
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

struct NotesView: View {
    @Binding var notes: String
    let recommendation: HealthRecommendation
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

// MARK: - Preview
#Preview {
    RecommendationDetailView(
        recommendation: HealthRecommendation(
            type: .cardiovascular,
            title: "Improve Heart Health",
            description: "Your cardiovascular risk is elevated. Consider increasing physical activity and monitoring blood pressure.",
            priority: .high,
            estimatedTime: 30,
            difficulty: .moderate,
            category: .exercise
        ),
        coachingEngine: RealTimeHealthCoachingEngine(
            healthDataManager: HealthDataManager(),
            predictionEngine: AdvancedHealthPredictionEngine(),
            analyticsEngine: AnalyticsEngine()
        )
    )
} 