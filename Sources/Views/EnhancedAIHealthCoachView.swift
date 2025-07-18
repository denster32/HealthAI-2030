import SwiftUI
import Speech
import AVFoundation

struct EnhancedAIHealthCoachView: View {
    @StateObject private var coachManager = EnhancedAIHealthCoachManager()
    @State private var messageText = ""
    @State private var showingWorkoutDetails = false
    @State private var showingNutritionDetails = false
    @State private var showingMentalHealthDetails = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    Text("Chat").tag(0)
                    Text("Workouts").tag(1)
                    Text("Nutrition").tag(2)
                    Text("Mental Health").tag(3)
                    Text("Progress").tag(4)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    chatView.tag(0)
                    workoutView.tag(1)
                    nutritionView.tag(2)
                    mentalHealthView.tag(3)
                    progressView.tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("AI Health Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        // Settings action
                    }
                }
            }
        }
    }
    
    // MARK: - Chat View
    private var chatView: some View {
        VStack {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(coachManager.conversationHistory) { message in
                            ChatBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        if coachManager.isProcessing {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("AI is thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: coachManager.conversationHistory.count) { _ in
                    if let lastMessage = coachManager.conversationHistory.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message input
            HStack {
                TextField("Type your message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(coachManager.isProcessing)
                
                Button(action: {
                    if coachManager.isListening {
                        coachManager.stopVoiceRecognition()
                    } else {
                        coachManager.startVoiceRecognition()
                    }
                }) {
                    Image(systemName: coachManager.isListening ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                        .foregroundColor(coachManager.isListening ? .red : .blue)
                }
                
                Button("Send") {
                    sendMessage()
                }
                .disabled(messageText.isEmpty || coachManager.isProcessing)
            }
            .padding()
        }
    }
    
    // MARK: - Workout View
    private var workoutView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let recommendation = coachManager.currentWorkoutRecommendation {
                    WorkoutRecommendationCard(recommendation: recommendation) {
                        showingWorkoutDetails = true
                    }
                } else {
                    EmptyStateView(
                        icon: "figure.run",
                        title: "No Workout Recommendation",
                        message: "Ask your AI coach for a personalized workout!"
                    )
                }
                
                // Quick workout options
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    QuickWorkoutCard(title: "Quick Cardio", duration: "15 min", icon: "heart.fill", color: .red)
                    QuickWorkoutCard(title: "Strength", duration: "20 min", icon: "dumbbell.fill", color: .blue)
                    QuickWorkoutCard(title: "Yoga", duration: "10 min", icon: "figure.mind.and.body", color: .green)
                    QuickWorkoutCard(title: "Stretching", duration: "5 min", icon: "figure.flexibility", color: .orange)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingWorkoutDetails) {
            if let recommendation = coachManager.currentWorkoutRecommendation {
                WorkoutDetailView(recommendation: recommendation)
            }
        }
    }
    
    // MARK: - Nutrition View
    private var nutritionView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let plan = coachManager.nutritionPlan {
                    NutritionPlanCard(plan: plan) {
                        showingNutritionDetails = true
                    }
                } else {
                    EmptyStateView(
                        icon: "leaf.fill",
                        title: "No Nutrition Plan",
                        message: "Ask your AI coach for personalized nutrition guidance!"
                    )
                }
                
                // Nutrition tracking
                NutritionTrackingSection()
            }
            .padding()
        }
        .sheet(isPresented: $showingNutritionDetails) {
            if let plan = coachManager.nutritionPlan {
                NutritionDetailView(plan: plan)
            }
        }
    }
    
    // MARK: - Mental Health View
    private var mentalHealthView: some View {
        ScrollView {
            VStack(spacing: 20) {
                MentalHealthStatusCard(status: coachManager.mentalHealthStatus)
                
                // Mental health tools
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    MentalHealthToolCard(title: "Meditation", icon: "brain.head.profile", color: .purple)
                    MentalHealthToolCard(title: "Breathing", icon: "lungs.fill", color: .blue)
                    MentalHealthToolCard(title: "Journaling", icon: "book.fill", color: .green)
                    MentalHealthToolCard(title: "Mood Check", icon: "face.smiling", color: .yellow)
                }
                
                // Stress management tips
                StressManagementSection()
            }
            .padding()
        }
        .sheet(isPresented: $showingMentalHealthDetails) {
            MentalHealthDetailView(status: coachManager.mentalHealthStatus)
        }
    }
    
    // MARK: - Progress View
    private var progressView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Progress overview
                ProgressOverviewCard(goals: coachManager.progressGoals)
                
                // Goals list
                ForEach(coachManager.progressGoals) { goal in
                    GoalProgressCard(goal: goal)
                }
                
                // Motivational messages
                if !coachManager.motivationalMessages.isEmpty {
                    MotivationalMessagesSection(messages: coachManager.motivationalMessages)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        coachManager.sendMessage(messageText)
        messageText = ""
    }
}

// MARK: - Supporting Views

struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding()
                    .background(message.sender == .user ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.sender == .user ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.sender == .ai {
                Spacer()
            }
        }
    }
}

struct WorkoutRecommendationCard: View {
    let recommendation: WorkoutRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "figure.run")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(recommendation.type.rawValue)
                            .font(.headline)
                        Text("\(recommendation.duration) min • \(recommendation.intensity.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(recommendation.caloriesBurned) cal")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Text(recommendation.tips)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickWorkoutCard: View {
    let title: String
    let duration: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(duration)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NutritionPlanCard: View {
    let plan: NutritionPlan
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading) {
                        Text("Daily Nutrition Plan")
                            .font(.headline)
                        Text("\(plan.dailyCalories) calories")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    MacroNutrientView(label: "Protein", value: "\(plan.proteinGrams)g", color: .red)
                    MacroNutrientView(label: "Carbs", value: "\(plan.carbGrams)g", color: .orange)
                    MacroNutrientView(label: "Fat", value: "\(plan.fatGrams)g", color: .yellow)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MacroNutrientView: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NutritionTrackingSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Tracking")
                .font(.headline)
            
            HStack {
                TrackingItemView(label: "Calories", value: "1,200", target: "2,000", color: .blue)
                TrackingItemView(label: "Water", value: "6", target: "8", color: .cyan)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TrackingItemView: View {
    let label: String
    let value: String
    let target: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("of \(target)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MentalHealthStatusCard: View {
    let status: MentalHealthStatus
    
    var statusColor: Color {
        switch status {
        case .excellent: return .green
        case .good: return .blue
        case .moderate: return .orange
        case .poor: return .red
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(statusColor)
                
                VStack(alignment: .leading) {
                    Text("Mental Health Status")
                        .font(.headline)
                    Text(status.rawValue)
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                }
                
                Spacer()
            }
            
            Text("Your mental health appears to be in \(status.rawValue.lowercased()) condition. Continue with your positive habits!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MentalHealthToolCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StressManagementSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stress Management Tips")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                TipRowView(icon: "lungs.fill", tip: "Practice deep breathing exercises")
                TipRowView(icon: "figure.mind.and.body", tip: "Try 5 minutes of meditation")
                TipRowView(icon: "leaf.fill", tip: "Take a walk in nature")
                TipRowView(icon: "music.note", tip: "Listen to calming music")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TipRowView: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(tip)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct ProgressOverviewCard: View {
    let goals: [HealthGoal]
    
    var overallProgress: Double {
        guard !goals.isEmpty else { return 0 }
        return goals.map { $0.progress }.reduce(0, +) / Double(goals.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text("Overall Progress")
                        .font(.headline)
                    Text("\(Int(overallProgress * 100))% Complete")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            ProgressView(value: overallProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GoalProgressCard: View {
    let goal: HealthGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(goal.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: goal.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            Text("\(goal.current, specifier: "%.1f") / \(goal.target, specifier: "%.1f") \(goal.unit)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MotivationalMessagesSection: View {
    let messages: [MotivationalMessage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Motivational Messages")
                .font(.headline)
            
            ForEach(messages.suffix(3)) { message in
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundColor(.blue)
                    
                    Text(message.content)
                        .font(.subheadline)
                        .italic()
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Detail Views (Placeholders)

struct WorkoutDetailView: View {
    let recommendation: WorkoutRecommendation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Workout Details")
                        .font(.title)
                        .padding()
                    
                    // Implementation would show detailed workout information
                    Text("Detailed workout view implementation")
                        .padding()
                }
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct NutritionDetailView: View {
    let plan: NutritionPlan
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Nutrition Details")
                        .font(.title)
                        .padding()
                    
                    // Implementation would show detailed nutrition information
                    Text("Detailed nutrition view implementation")
                        .padding()
                }
            }
            .navigationTitle("Nutrition Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct MentalHealthDetailView: View {
    let status: MentalHealthStatus
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Mental Health Details")
                        .font(.title)
                        .padding()
                    
                    // Implementation would show detailed mental health information
                    Text("Detailed mental health view implementation")
                        .padding()
                }
            }
            .navigationTitle("Mental Health Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EnhancedAIHealthCoachView()
} 