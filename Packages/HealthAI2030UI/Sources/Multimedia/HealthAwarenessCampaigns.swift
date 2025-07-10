import SwiftUI

// MARK: - Health Awareness Campaigns
/// Comprehensive health awareness campaign system for enhanced education
/// Provides interactive campaigns and awareness content for various health topics
public struct HealthAwarenessCampaigns {
    
    // MARK: - Campaign Dashboard Component
    
    /// Main dashboard for health awareness campaigns
    public struct CampaignDashboard: View {
        let campaigns: [HealthCampaign]
        @State private var selectedCampaign: HealthCampaign?
        @State private var userProgress: [String: CampaignProgress] = [:]
        @State private var showActiveCampaigns: Bool = true
        
        public init(campaigns: [HealthCampaign]) {
            self.campaigns = campaigns
        }
        
        public var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Health Awareness")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Stay informed and take action for better health")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Campaign filter
                    HStack {
                        Button(action: {
                            showActiveCampaigns = true
                        }) {
                            Text("Active Campaigns")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(showActiveCampaigns ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(showActiveCampaigns ? Color.blue : Color(.systemGray5))
                                .cornerRadius(20)
                        }
                        
                        Button(action: {
                            showActiveCampaigns = false
                        }) {
                            Text("All Campaigns")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(!showActiveCampaigns ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(!showActiveCampaigns ? Color.blue : Color(.systemGray5))
                                .cornerRadius(20)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Campaigns list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredCampaigns) { campaign in
                                CampaignCard(
                                    campaign: campaign,
                                    progress: userProgress[campaign.id],
                                    onTap: {
                                        selectedCampaign = campaign
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                .navigationBarHidden(true)
                .sheet(item: $selectedCampaign) { campaign in
                    CampaignDetailView(
                        campaign: campaign,
                        progress: userProgress[campaign.id] ?? CampaignProgress(),
                        onProgressUpdate: { progress in
                            userProgress[campaign.id] = progress
                        }
                    )
                }
            }
        }
        
        private var filteredCampaigns: [HealthCampaign] {
            if showActiveCampaigns {
                return campaigns.filter { $0.isActive }
            } else {
                return campaigns
            }
        }
    }
    
    // MARK: - Campaign Card Component
    
    /// Card for campaign display
    public struct CampaignCard: View {
        let campaign: HealthCampaign
        let progress: CampaignProgress?
        let onTap: () -> Void
        
        public var body: some View {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {
                    // Campaign header
                    HStack {
                        Image(systemName: campaign.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(campaign.category.color)
                            .frame(width: 50, height: 50)
                            .background(campaign.category.color.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(campaign.title)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text(campaign.category.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(campaign.category.color)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        if campaign.isActive {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    // Campaign description
                    Text(campaign.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Progress indicator
                    if let progress = progress {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Progress")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(progress.completionPercentage))%")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(campaign.category.color)
                            }
                            
                            ProgressView(value: progress.completionPercentage, total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: campaign.category.color))
                        }
                    }
                    
                    // Campaign metadata
                    HStack {
                        Label("\(campaign.duration) days", systemImage: "clock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Label("\(campaign.participants) participants", systemImage: "person.2")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Campaign Detail View
    
    /// Detailed view for individual campaigns
    public struct CampaignDetailView: View {
        let campaign: HealthCampaign
        let progress: CampaignProgress
        let onProgressUpdate: (CampaignProgress) -> Void
        @State private var currentStep: Int = 0
        @State private var showQuiz: Bool = false
        @Environment(\.presentationMode) var presentationMode
        
        public var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        // Campaign header
                        VStack(spacing: 16) {
                            Image(systemName: campaign.icon)
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(campaign.category.color)
                                .frame(width: 80, height: 80)
                                .background(campaign.category.color.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(spacing: 8) {
                                Text(campaign.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                
                                Text(campaign.description)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        
                        // Progress overview
                        VStack(spacing: 12) {
                            HStack {
                                Text("Your Progress")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(Int(progress.completionPercentage))% Complete")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(campaign.category.color)
                            }
                            
                            ProgressView(value: progress.completionPercentage, total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: campaign.category.color))
                                .frame(height: 8)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Campaign steps
                        VStack(spacing: 16) {
                            Text("Campaign Steps")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(Array(campaign.steps.enumerated()), id: \.element.id) { index, step in
                                CampaignStepView(
                                    step: step,
                                    isCompleted: progress.completedSteps.contains(step.id),
                                    isCurrent: index == currentStep,
                                    onComplete: {
                                        completeStep(step.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            if progress.completionPercentage >= 100 {
                                Button(action: {
                                    showQuiz = true
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Take Final Quiz")
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(campaign.category.color)
                                    .cornerRadius(12)
                                }
                            } else {
                                Button(action: {
                                    if currentStep < campaign.steps.count - 1 {
                                        currentStep += 1
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.right")
                                        Text("Continue Campaign")
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(campaign.category.color)
                                    .cornerRadius(12)
                                }
                            }
                            
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Back to Campaigns")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showQuiz) {
                    CampaignQuizView(
                        quiz: campaign.quiz,
                        onComplete: { score in
                            showQuiz = false
                            // Handle quiz completion
                        }
                    )
                }
            }
        }
        
        private func completeStep(_ stepId: String) {
            var updatedProgress = progress
            if !updatedProgress.completedSteps.contains(stepId) {
                updatedProgress.completedSteps.append(stepId)
                updatedProgress.completionPercentage = Double(updatedProgress.completedSteps.count) / Double(campaign.steps.count) * 100
                onProgressUpdate(updatedProgress)
            }
        }
    }
    
    // MARK: - Campaign Step View
    
    /// Individual campaign step component
    public struct CampaignStepView: View {
        let step: CampaignStep
        let isCompleted: Bool
        let isCurrent: Bool
        let onComplete: () -> Void
        @State private var showStepDetail: Bool = false
        
        public var body: some View {
            VStack(spacing: 12) {
                // Step header
                HStack {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color.green : (isCurrent ? step.category.color : Color(.systemGray4)))
                            .frame(width: 40, height: 40)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step.number)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(step.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    if isCurrent && !isCompleted {
                        Button(action: {
                            showStepDetail = true
                        }) {
                            Text("Start")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(step.category.color)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Step content
                if showStepDetail {
                    VStack(spacing: 16) {
                        // Step content based on type
                        switch step.type {
                        case .video:
                            VideoStepContent(step: step)
                        case .article:
                            ArticleStepContent(step: step)
                        case .interactive:
                            InteractiveStepContent(step: step, onComplete: onComplete)
                        case .quiz:
                            QuizStepContent(step: step, onComplete: onComplete)
                        }
                        
                        // Complete button
                        Button(action: {
                            onComplete()
                            showStepDetail = false
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark as Complete")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(step.category.color)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrent ? step.category.color : Color.clear, lineWidth: 2)
            )
            .animation(.easeInOut(duration: 0.3), value: showStepDetail)
        }
    }
    
    // MARK: - Step Content Components
    
    /// Video step content
    public struct VideoStepContent: View {
        let step: CampaignStep
        
        public var body: some View {
            VStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(step.category.color)
                
                Text("Watch Video")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(step.content)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
    
    /// Article step content
    public struct ArticleStepContent: View {
        let step: CampaignStep
        
        public var body: some View {
            VStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(step.category.color)
                
                Text("Read Article")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(step.content)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(6)
            }
            .padding()
        }
    }
    
    /// Interactive step content
    public struct InteractiveStepContent: View {
        let step: CampaignStep
        let onComplete: () -> Void
        @State private var interactionCompleted: Bool = false
        
        public var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(step.category.color)
                
                Text("Interactive Activity")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(step.content)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    interactionCompleted = true
                    onComplete()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Activity")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(interactionCompleted ? Color.green : step.category.color)
                    .cornerRadius(12)
                }
                .disabled(interactionCompleted)
            }
            .padding()
        }
    }
    
    /// Quiz step content
    public struct QuizStepContent: View {
        let step: CampaignStep
        let onComplete: () -> Void
        @State private var selectedAnswer: Int?
        @State private var showResult: Bool = false
        
        public var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(step.category.color)
                
                Text("Quick Quiz")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(step.content)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Quiz options (simplified)
                VStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Button(action: {
                            selectedAnswer = index
                            showResult = true
                        }) {
                            HStack {
                                Text("Option \(index + 1)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedAnswer == index {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(step.category.color)
                                }
                            }
                            .padding(12)
                            .background(selectedAnswer == index ? step.category.color.opacity(0.1) : Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(showResult)
                    }
                }
                
                if showResult {
                    Button(action: onComplete) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Campaign Quiz View
    
    /// Final campaign quiz
    public struct CampaignQuizView: View {
        let quiz: CampaignQuiz
        let onComplete: (Int) -> Void
        @State private var currentQuestion: Int = 0
        @State private var selectedAnswers: [Int: Int] = [:]
        @State private var showResults: Bool = false
        @Environment(\.presentationMode) var presentationMode
        
        public var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    if !showResults {
                        // Quiz questions
                        VStack(spacing: 16) {
                            Text("Campaign Quiz")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Question \(currentQuestion + 1) of \(quiz.questions.count)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(quiz.questions[currentQuestion].question)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            VStack(spacing: 8) {
                                ForEach(Array(quiz.questions[currentQuestion].options.enumerated()), id: \.offset) { index, option in
                                    Button(action: {
                                        selectedAnswers[currentQuestion] = index
                                    }) {
                                        HStack {
                                            Text(option)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                            
                                            Spacer()
                                            
                                            if selectedAnswers[currentQuestion] == index {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(16)
                                        .background(selectedAnswers[currentQuestion] == index ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            HStack {
                                if currentQuestion > 0 {
                                    Button("Previous") {
                                        currentQuestion -= 1
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                                Spacer()
                                
                                if currentQuestion < quiz.questions.count - 1 {
                                    Button("Next") {
                                        currentQuestion += 1
                                    }
                                    .buttonStyle(.bordered)
                                } else {
                                    Button("Submit Quiz") {
                                        showResults = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                        .padding()
                    } else {
                        // Quiz results
                        VStack(spacing: 20) {
                            Text("Quiz Results")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            let score = calculateScore()
                            let percentage = Double(score) / Double(quiz.questions.count) * 100
                            
                            VStack(spacing: 8) {
                                Text("\(score)/\(quiz.questions.count) Correct")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("\(Int(percentage))%")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(percentage >= 80 ? .green : .orange)
                            }
                            
                            Text(percentage >= 80 ? "Congratulations! You've successfully completed the campaign." : "Good effort! Keep learning and improving.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Complete Campaign") {
                                onComplete(score)
                                presentationMode.wrappedValue.dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
                .navigationBarHidden(true)
            }
        }
        
        private func calculateScore() -> Int {
            var score = 0
            for (questionIndex, selectedAnswer) in selectedAnswers {
                if selectedAnswer == quiz.questions[questionIndex].correctAnswer {
                    score += 1
                }
            }
            return score
        }
    }
}

// MARK: - Supporting Types

struct HealthCampaign: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: CampaignCategory
    let duration: Int
    let participants: Int
    let isActive: Bool
    let steps: [CampaignStep]
    let quiz: CampaignQuiz
    
    init(id: String, title: String, description: String, icon: String, category: CampaignCategory, duration: Int, participants: Int, isActive: Bool, steps: [CampaignStep], quiz: CampaignQuiz) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.duration = duration
        self.participants = participants
        self.isActive = isActive
        self.steps = steps
        self.quiz = quiz
    }
}

struct CampaignStep: Identifiable {
    let id: String
    let number: Int
    let title: String
    let description: String
    let type: StepType
    let content: String
    let category: CampaignCategory
    
    init(id: String, number: Int, title: String, description: String, type: StepType, content: String, category: CampaignCategory) {
        self.id = id
        self.number = number
        self.title = title
        self.description = description
        self.type = type
        self.content = content
        self.category = category
    }
}

enum StepType {
    case video
    case article
    case interactive
    case quiz
}

struct CampaignQuiz {
    let title: String
    let questions: [CampaignQuestion]
    
    init(title: String, questions: [CampaignQuestion]) {
        self.title = title
        self.questions = questions
    }
}

struct CampaignQuestion {
    let question: String
    let options: [String]
    let correctAnswer: Int
    
    init(question: String, options: [String], correctAnswer: Int) {
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
    }
}

enum CampaignCategory: String, CaseIterable {
    case nutrition = "Nutrition"
    case exercise = "Exercise"
    case mentalHealth = "Mental Health"
    case preventiveCare = "Preventive Care"
    case chronicDisease = "Chronic Disease"
    case emergency = "Emergency"
    
    var color: Color {
        switch self {
        case .nutrition: return .green
        case .exercise: return .orange
        case .mentalHealth: return .purple
        case .preventiveCare: return .blue
        case .chronicDisease: return .red
        case .emergency: return .red
        }
    }
}

struct CampaignProgress {
    var completedSteps: [String] = []
    var completionPercentage: Double = 0.0
    
    init(completedSteps: [String] = [], completionPercentage: Double = 0.0) {
        self.completedSteps = completedSteps
        self.completionPercentage = completionPercentage
    }
}

// MARK: - Preview

struct HealthAwarenessCampaigns_Previews: PreviewProvider {
    static var previews: some View {
        CampaignDashboard(campaigns: [
            HealthCampaign(
                id: "1",
                title: "Heart Health Awareness",
                description: "Learn about heart health and prevention strategies",
                icon: "heart.fill",
                category: .preventiveCare,
                duration: 30,
                participants: 1500,
                isActive: true,
                steps: [
                    CampaignStep(
                        id: "1",
                        number: 1,
                        title: "Understanding Heart Health",
                        description: "Learn the basics of cardiovascular health",
                        type: .video,
                        content: "Watch this informative video about heart health",
                        category: .preventiveCare
                    )
                ],
                quiz: CampaignQuiz(
                    title: "Heart Health Quiz",
                    questions: [
                        CampaignQuestion(
                            question: "What is a normal resting heart rate?",
                            options: ["60-100 BPM", "40-60 BPM", "100-120 BPM"],
                            correctAnswer: 0
                        )
                    ]
                )
            )
        ])
        .previewLayout(.sizeThatFits)
    }
} 