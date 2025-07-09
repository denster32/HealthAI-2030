import SwiftUI

/// Goal Setting View for Health Coaching
/// Allows users to set and configure health goals
@available(iOS 18.0, macOS 15.0, *)
public struct GoalSettingView: View {
    
    // MARK: - State
    @ObservedObject var coachingEngine: RealTimeHealthCoachingEngine
    @State private var selectedGoalType: HealthGoal.HealthGoalType = .generalWellness
    @State private var targetValue: Double = 0.8
    @State private var timeframe: HealthGoal.Timeframe = .month
    @State private var description: String = ""
    @State private var showingPreview = false
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Goal Type Selection
                    goalTypeSection
                    
                    // Target Configuration
                    targetSection
                    
                    // Timeframe Selection
                    timeframeSection
                    
                    // Description
                    descriptionSection
                    
                    // Preview
                    if showingPreview {
                        previewSection
                    }
                    
                    // Action Buttons
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Set Health Goal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Preview") {
                        withAnimation {
                            showingPreview.toggle()
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            setupInitialGoal()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Set Your Health Goal")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Choose a specific health goal and we'll create a personalized coaching plan to help you achieve it.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Goal Type Section
    private var goalTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(HealthGoal.HealthGoalType.allCases, id: \.self) { goalType in
                    GoalTypeCard(
                        goalType: goalType,
                        isSelected: selectedGoalType == goalType
                    ) {
                        selectedGoalType = goalType
                        updateDescription()
                    }
                }
            }
        }
    }
    
    // MARK: - Target Section
    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Target")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text(targetLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(targetValueText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Slider(value: $targetValue, in: targetRange) { _ in
                    updateDescription()
                }
                .accentColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Timeframe Section
    private var timeframeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeframe")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(HealthGoal.Timeframe.allCases, id: \.self) { timeFrame in
                    TimeframeCard(
                        timeframe: timeFrame,
                        isSelected: timeframe == timeFrame
                    ) {
                        timeframe = timeFrame
                        updateDescription()
                    }
                }
            }
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Description")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("Describe your goal...", text: $description, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            let previewGoal = HealthGoal(
                type: selectedGoalType,
                targetValue: targetValue,
                timeframe: timeframe,
                description: description.isEmpty ? defaultDescription : description
            )
            
            GoalPreviewCard(goal: previewGoal)
        }
    }
    
    // MARK: - Action Section
    private var actionSection: some View {
        VStack(spacing: 16) {
            Button("Set Goal") {
                setGoal()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(description.isEmpty)
            
            Button("Start Coaching Session") {
                setGoalAndStartSession()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
    
    // MARK: - Helper Methods
    private func setupInitialGoal() {
        if let currentGoal = coachingEngine.currentGoal {
            selectedGoalType = currentGoal.type
            targetValue = currentGoal.targetValue
            timeframe = currentGoal.timeframe
            description = currentGoal.description
        } else {
            updateDescription()
        }
    }
    
    private func updateDescription() {
        if description.isEmpty || description == defaultDescription {
            description = defaultDescription
        }
    }
    
    private var targetLabel: String {
        switch selectedGoalType {
        case .weightLoss: return "Target Weight Loss"
        case .cardiovascularHealth: return "Target Heart Health Score"
        case .sleepOptimization: return "Target Sleep Quality"
        case .stressReduction: return "Target Stress Level"
        case .generalWellness: return "Target Wellness Score"
        }
    }
    
    private var targetValueText: String {
        switch selectedGoalType {
        case .weightLoss: return "\(Int(targetValue)) kg"
        case .cardiovascularHealth: return "\(Int(targetValue * 100))%"
        case .sleepOptimization: return "\(Int(targetValue * 100))%"
        case .stressReduction: return "\(Int(targetValue * 100))%"
        case .generalWellness: return "\(Int(targetValue * 100))%"
        }
    }
    
    private var targetRange: ClosedRange<Double> {
        switch selectedGoalType {
        case .weightLoss: return 1...20
        case .cardiovascularHealth: return 0.5...1.0
        case .sleepOptimization: return 0.6...1.0
        case .stressReduction: return 0.1...0.5
        case .generalWellness: return 0.5...1.0
        }
    }
    
    private var defaultDescription: String {
        switch selectedGoalType {
        case .weightLoss:
            return "Lose \(Int(targetValue)) kg over \(timeframe.displayName.lowercased()) through healthy diet and exercise"
        case .cardiovascularHealth:
            return "Improve cardiovascular health to \(Int(targetValue * 100))% score over \(timeframe.displayName.lowercased())"
        case .sleepOptimization:
            return "Achieve \(Int(targetValue * 100))% sleep quality over \(timeframe.displayName.lowercased())"
        case .stressReduction:
            return "Reduce stress levels to \(Int(targetValue * 100))% over \(timeframe.displayName.lowercased())"
        case .generalWellness:
            return "Improve overall wellness to \(Int(targetValue * 100))% score over \(timeframe.displayName.lowercased())"
        }
    }
    
    private func setGoal() {
        let goal = HealthGoal(
            type: selectedGoalType,
            targetValue: targetValue,
            timeframe: timeframe,
            description: description
        )
        
        Task {
            await coachingEngine.setHealthGoal(goal)
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    private func setGoalAndStartSession() {
        let goal = HealthGoal(
            type: selectedGoalType,
            targetValue: targetValue,
            timeframe: timeframe,
            description: description
        )
        
        Task {
            await coachingEngine.setHealthGoal(goal)
            
            do {
                _ = try await coachingEngine.startCoachingSession(goal: goal)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to start coaching session: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views

struct GoalTypeCard: View {
    let goalType: HealthGoal.HealthGoalType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: goalIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(goalType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var goalIcon: String {
        switch goalType {
        case .weightLoss: return "scalemass"
        case .cardiovascularHealth: return "heart.fill"
        case .sleepOptimization: return "bed.double.fill"
        case .stressReduction: return "brain.head.profile"
        case .generalWellness: return "leaf.fill"
        }
    }
}

struct TimeframeCard: View {
    let timeframe: HealthGoal.Timeframe
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(timeframe.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(timeframeDescription)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var timeframeDescription: String {
        switch timeframe {
        case .week: return "Short-term focus"
        case .month: return "Medium-term goal"
        case .quarter: return "Long-term planning"
        case .year: return "Annual objective"
        }
    }
}

struct GoalPreviewCard: View {
    let goal: HealthGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: goalIcon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.type.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(goal.timeframe.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(targetValueText)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Text(goal.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Progress indicator
            ProgressView(value: 0.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var goalIcon: String {
        switch goal.type {
        case .weightLoss: return "scalemass"
        case .cardiovascularHealth: return "heart.fill"
        case .sleepOptimization: return "bed.double.fill"
        case .stressReduction: return "brain.head.profile"
        case .generalWellness: return "leaf.fill"
        }
    }
    
    private var targetValueText: String {
        switch goal.type {
        case .weightLoss: return "\(Int(goal.targetValue)) kg"
        case .cardiovascularHealth: return "\(Int(goal.targetValue * 100))%"
        case .sleepOptimization: return "\(Int(goal.targetValue * 100))%"
        case .stressReduction: return "\(Int(goal.targetValue * 100))%"
        case .generalWellness: return "\(Int(goal.targetValue * 100))%"
        }
    }
}

// MARK: - Preview
#Preview {
    GoalSettingView(coachingEngine: RealTimeHealthCoachingEngine(
        healthDataManager: HealthDataManager(),
        predictionEngine: AdvancedHealthPredictionEngine(),
        analyticsEngine: AnalyticsEngine()
    ))
} 