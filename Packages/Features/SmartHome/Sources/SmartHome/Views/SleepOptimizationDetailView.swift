import SwiftUI

/// Sleep Optimization Detail View
/// Provides detailed information and step-by-step guidance for sleep optimizations
@available(iOS 18.0, macOS 15.0, *)
public struct SleepOptimizationDetailView: View {
    
    // MARK: - Properties
    let optimization: SleepOptimization
    let sleepEngine: AdvancedSleepIntelligenceEngine
    
    // MARK: - State
    @State private var isCompleted = false
    @State private var showingSteps = false
    @State private var currentStep = 0
    @State private var progress: Double = 0.0
    @State private var notes = ""
    @State private var showingNotes = false
    @State private var showingImplementation = false
    
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
                    
                    // Action Section
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Sleep Optimization")
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
                    .foregroundColor(.indigo)
                }
            }
        }
        .sheet(isPresented: $showingNotes) {
            SleepNotesView(notes: $notes, optimization: optimization)
        }
        .sheet(isPresented: $showingImplementation) {
            ImplementationGuideView(optimization: optimization)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon and Title
            HStack {
                Image(systemName: optimizationIcon)
                    .font(.system(size: 50))
                    .foregroundColor(priorityColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(optimization.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        PriorityBadge(priority: optimization.priority)
                        
                        Spacer()
                        
                        Label("\(Int(optimization.estimatedImpact * 100))% Impact", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Description
            Text(optimization.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            // Category and Difficulty
            HStack {
                Label(optimization.category.rawValue.capitalized, systemImage: categoryIcon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("High Impact", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
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
                    .foregroundColor(.indigo)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .indigo))
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
                .foregroundColor(.indigo)
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
                    
                    Text("Great job! You've successfully implemented this sleep optimization.")
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
    private var optimizationIcon: String {
        switch optimization.type {
        case .duration: return "clock"
        case .efficiency: return "chart.line.uptrend.xyaxis"
        case .deepSleep: return "brain.head.profile"
        case .environment: return "house.fill"
        case .schedule: return "calendar"
        case .lifestyle: return "leaf.fill"
        }
    }
    
    private var priorityColor: Color {
        switch optimization.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private var categoryIcon: String {
        switch optimization.category {
        case .schedule: return "calendar"
        case .environment: return "house.fill"
        case .lifestyle: return "leaf.fill"
        case .nutrition: return "fork.knife"
        case .exercise: return "figure.walk"
        }
    }
    
    private var implementationSteps: [String] {
        switch optimization.type {
        case .duration:
            return [
                "Set a consistent bedtime",
                "Create a relaxing bedtime routine",
                "Avoid screens 1 hour before bed",
                "Ensure your bedroom is comfortable",
                "Track your sleep duration"
            ]
        case .efficiency:
            return [
                "Optimize your sleep environment",
                "Reduce noise and light exposure",
                "Maintain comfortable temperature",
                "Use comfortable bedding",
                "Monitor sleep efficiency"
            ]
        case .deepSleep:
            return [
                "Reduce evening screen time",
                "Avoid caffeine after 2 PM",
                "Exercise regularly but not close to bedtime",
                "Create a dark, quiet sleep environment",
                "Practice relaxation techniques"
            ]
        case .environment:
            return [
                "Measure current room temperature",
                "Adjust thermostat to 65-72°F",
                "Install blackout curtains if needed",
                "Use white noise machine if necessary",
                "Ensure good air circulation"
            ]
        case .schedule:
            return [
                "Calculate your optimal bedtime",
                "Set consistent wake-up time",
                "Gradually adjust your schedule",
                "Maintain schedule on weekends",
                "Track your sleep patterns"
            ]
        case .lifestyle:
            return [
                "Establish a daily routine",
                "Exercise regularly",
                "Manage stress through meditation",
                "Limit alcohol and nicotine",
                "Maintain healthy diet"
            ]
        }
    }
    
    private var expectedBenefits: [String] {
        switch optimization.type {
        case .duration:
            return [
                "Improved cognitive function and memory",
                "Better mood and emotional regulation",
                "Enhanced immune system function",
                "Reduced risk of chronic health conditions"
            ]
        case .efficiency:
            return [
                "More restorative sleep quality",
                "Reduced time spent awake in bed",
                "Better daytime energy levels",
                "Improved overall sleep satisfaction"
            ]
        case .deepSleep:
            return [
                "Enhanced physical recovery and repair",
                "Improved memory consolidation",
                "Better hormone regulation",
                "Reduced inflammation and stress"
            ]
        case .environment:
            return [
                "Faster sleep onset",
                "Reduced sleep disturbances",
                "Better sleep quality",
                "More comfortable sleep experience"
            ]
        case .schedule:
            return [
                "Improved circadian rhythm alignment",
                "More consistent sleep patterns",
                "Better daytime alertness",
                "Enhanced overall sleep quality"
            ]
        case .lifestyle:
            return [
                "Better overall health and wellness",
                "Improved stress management",
                "Enhanced sleep quality",
                "More sustainable sleep habits"
            ]
        }
    }
    
    private var proTips: [String] {
        switch optimization.type {
        case .duration:
            return [
                "Start with small adjustments (15-30 minutes)",
                "Be consistent with your schedule",
                "Use a sleep diary to track progress",
                "Don't try to make up for lost sleep on weekends"
            ]
        case .efficiency:
            return [
                "Invest in quality bedding and pillows",
                "Consider using a sleep tracker",
                "Create a pre-sleep ritual",
                "Keep your bedroom dedicated to sleep only"
            ]
        case .deepSleep:
            return [
                "Try progressive muscle relaxation",
                "Use blue light filters on devices",
                "Consider magnesium supplements",
                "Practice mindfulness meditation"
            ]
        case .environment:
            return [
                "Use a hygrometer to monitor humidity",
                "Consider a smart thermostat",
                "Test different white noise options",
                "Keep your bedroom clean and organized"
            ]
        case .schedule:
            return [
                "Use gradual adjustments (15 minutes per week)",
                "Expose yourself to natural light in the morning",
                "Avoid long naps during the day",
                "Be patient with schedule changes"
            ]
        case .lifestyle:
            return [
                "Start with one change at a time",
                "Track your progress consistently",
                "Be patient with lifestyle changes",
                "Seek support from friends and family"
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
        // This would integrate with the sleep engine to track optimization completion
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
                        .foregroundColor(.indigo)
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
            return .indigo
        } else {
            return .gray
        }
    }
    
    private var backgroundColor: Color {
        if isCurrent {
            return Color.indigo.opacity(0.1)
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
    let priority: SleepOptimization.Priority
    
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

struct SleepNotesView: View {
    @Binding var notes: String
    let optimization: SleepOptimization
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Add your notes about this optimization...", text: $notes, axis: .vertical)
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

struct ImplementationGuideView: View {
    let optimization: SleepOptimization
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Implementation Guide")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("This guide will help you successfully implement the \(optimization.title.lowercased()) optimization.")
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
    SleepOptimizationDetailView(
        optimization: SleepOptimization(
            type: .deepSleep,
            title: "Enhance Deep Sleep",
            description: "Your deep sleep percentage is low. Try reducing evening screen time and caffeine.",
            priority: .high,
            estimatedImpact: 0.7,
            category: .lifestyle
        ),
        sleepEngine: AdvancedSleepIntelligenceEngine(
            healthDataManager: HealthDataManager(),
            predictionEngine: AdvancedHealthPredictionEngine(),
            analyticsEngine: AnalyticsEngine()
        )
    )
} 