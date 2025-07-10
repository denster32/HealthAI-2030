import SwiftUI
import AVKit

// MARK: - Interactive Video Tutorials
/// Comprehensive interactive video tutorial system for enhanced learning
/// Provides step-by-step interactive tutorials with user engagement features
public struct InteractiveVideoTutorials {
    
    // MARK: - Interactive Tutorial Player
    
    /// Interactive tutorial player with step-by-step guidance
    public struct InteractiveTutorialPlayer: View {
        let tutorial: TutorialData
        @State private var currentStep: Int = 0
        @State private var player: AVPlayer?
        @State private var isPlaying: Bool = false
        @State private var showStepOverlay: Bool = true
        @State private var userProgress: [Int: Bool] = [:]
        @State private var showQuiz: Bool = false
        
        public init(tutorial: TutorialData) {
            self.tutorial = tutorial
        }
        
        public var body: some View {
            VStack(spacing: 0) {
                // Video player with overlay
                ZStack {
                    if let player = player {
                        VideoPlayer(player: player)
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(12)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            )
                    }
                    
                    // Step overlay
                    if showStepOverlay && currentStep < tutorial.steps.count {
                        StepOverlay(
                            step: tutorial.steps[currentStep],
                            onComplete: {
                                completeCurrentStep()
                            }
                        )
                    }
                    
                    // Quiz overlay
                    if showQuiz {
                        QuizOverlay(
                            quiz: tutorial.quiz,
                            onComplete: { score in
                                showQuiz = false
                                // Handle quiz completion
                            }
                        )
                    }
                }
                
                // Tutorial controls
                VStack(spacing: 16) {
                    // Progress indicator
                    VStack(spacing: 8) {
                        HStack {
                            Text("Step \(currentStep + 1) of \(tutorial.steps.count)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(Int(progressPercentage))% Complete")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        ProgressView(value: progressPercentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                    
                    // Step navigation
                    HStack(spacing: 12) {
                        Button(action: {
                            if currentStep > 0 {
                                currentStep -= 1
                                updatePlayerForCurrentStep()
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        }
                        .disabled(currentStep == 0)
                        
                        Spacer()
                        
                        Button(action: {
                            if isPlaying {
                                player?.pause()
                            } else {
                                player?.play()
                            }
                            isPlaying.toggle()
                        }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentStep < tutorial.steps.count - 1 {
                                currentStep += 1
                                updatePlayerForCurrentStep()
                            } else {
                                showQuiz = true
                            }
                        }) {
                            HStack {
                                Text(currentStep == tutorial.steps.count - 1 ? "Quiz" : "Next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                        }
                        .disabled(currentStep == tutorial.steps.count - 1 && !canProceedToQuiz)
                    }
                }
                .padding()
            }
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
        }
        
        private var progressPercentage: Double {
            let completedSteps = userProgress.values.filter { $0 }.count
            return Double(completedSteps) / Double(tutorial.steps.count) * 100
        }
        
        private var canProceedToQuiz: Bool {
            return userProgress.values.allSatisfy { $0 }
        }
        
        private func setupPlayer() {
            if let videoURL = tutorial.steps[currentStep].videoURL {
                player = AVPlayer(url: videoURL)
            }
        }
        
        private func updatePlayerForCurrentStep() {
            if let videoURL = tutorial.steps[currentStep].videoURL {
                player?.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
                player?.seek(to: .zero)
                isPlaying = false
            }
        }
        
        private func completeCurrentStep() {
            userProgress[currentStep] = true
            
            // Auto-advance to next step after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if currentStep < tutorial.steps.count - 1 {
                    currentStep += 1
                    updatePlayerForCurrentStep()
                }
            }
        }
    }
    
    // MARK: - Step Overlay Component
    
    /// Overlay for interactive step guidance
    public struct StepOverlay: View {
        let step: TutorialStep
        let onComplete: () -> Void
        @State private var showInstructions: Bool = true
        @State private var interactionCompleted: Bool = false
        
        public var body: some View {
            VStack {
                // Instructions panel
                if showInstructions {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: step.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text(step.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showInstructions = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text(step.instructions)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        // Interactive elements
                        ForEach(step.interactions) { interaction in
                            InteractionElement(
                                interaction: interaction,
                                onComplete: {
                                    interactionCompleted = true
                                }
                            )
                        }
                        
                        if interactionCompleted {
                            Button(action: onComplete) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Complete Step")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .padding()
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Interaction Element Component
    
    /// Interactive element for step completion
    public struct InteractionElement: View {
        let interaction: TutorialInteraction
        let onComplete: () -> Void
        @State private var isCompleted: Bool = false
        
        public var body: some View {
            switch interaction.type {
            case .tap:
                Button(action: {
                    isCompleted = true
                    onComplete()
                }) {
                    Text(interaction.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isCompleted ? Color.green : Color.blue)
                        .cornerRadius(6)
                }
                .disabled(isCompleted)
                
            case .swipe:
                HStack {
                    Text(interaction.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        isCompleted = true
                        onComplete()
                    }) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(isCompleted ? Color.green : Color.orange)
                            .clipShape(Circle())
                    }
                    .disabled(isCompleted)
                }
                
            case .drag:
                VStack(spacing: 8) {
                    Text(interaction.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        isCompleted = true
                        onComplete()
                    }) {
                        HStack {
                            Image(systemName: "hand.draw")
                            Text("Drag Here")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isCompleted ? Color.green : Color.purple)
                        .cornerRadius(6)
                    }
                    .disabled(isCompleted)
                }
            }
        }
    }
    
    // MARK: - Quiz Overlay Component
    
    /// Quiz overlay for tutorial completion
    public struct QuizOverlay: View {
        let quiz: TutorialQuiz
        let onComplete: (Int) -> Void
        @State private var currentQuestion: Int = 0
        @State private var selectedAnswers: [Int: Int] = [:]
        @State private var showResults: Bool = false
        
        public var body: some View {
            VStack(spacing: 20) {
                if !showResults {
                    // Quiz questions
                    VStack(spacing: 16) {
                        Text("Quiz: \(quiz.title)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Question \(currentQuestion + 1) of \(quiz.questions.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(quiz.questions[currentQuestion].question)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(quiz.questions[currentQuestion].options.enumerated()), id: \.offset) { index, option in
                                Button(action: {
                                    selectedAnswers[currentQuestion] = index
                                }) {
                                    HStack {
                                        Text(option)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        if selectedAnswers[currentQuestion] == index {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(12)
                                    .background(selectedAnswers[currentQuestion] == index ? Color.blue.opacity(0.6) : Color.white.opacity(0.2))
                                    .cornerRadius(8)
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
                                .tint(.white)
                            }
                            
                            Spacer()
                            
                            if currentQuestion < quiz.questions.count - 1 {
                                Button("Next") {
                                    currentQuestion += 1
                                }
                                .buttonStyle(.bordered)
                                .tint(.white)
                            } else {
                                Button("Submit Quiz") {
                                    showResults = true
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            }
                        }
                    }
                } else {
                    // Quiz results
                    VStack(spacing: 16) {
                        Text("Quiz Results")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        let score = calculateScore()
                        let percentage = Double(score) / Double(quiz.questions.count) * 100
                        
                        Text("\(score)/\(quiz.questions.count) Correct")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(Int(percentage))%")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(percentage >= 80 ? .green : .orange)
                        
                        Text(percentage >= 80 ? "Great job! You've mastered this tutorial." : "Keep practicing to improve your understanding.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Button("Continue") {
                            onComplete(score)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                }
            }
            .padding(24)
            .background(Color.black.opacity(0.9))
            .cornerRadius(16)
            .padding()
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
    
    // MARK: - Tutorial Library Component
    
    /// Library of available tutorials
    public struct TutorialLibrary: View {
        let tutorials: [TutorialData]
        @State private var selectedCategory: TutorialCategory?
        @State private var searchText: String = ""
        @State private var selectedTutorial: TutorialData?
        
        public init(tutorials: [TutorialData]) {
            self.tutorials = tutorials
        }
        
        public var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search tutorials...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding()
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TutorialCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }) {
                                    Text(category.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedCategory == category ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? category.color : Color(.systemGray5))
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Tutorial grid
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(filteredTutorials) { tutorial in
                                TutorialCard(tutorial: tutorial) {
                                    selectedTutorial = tutorial
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Tutorials")
                .sheet(item: $selectedTutorial) { tutorial in
                    InteractiveTutorialPlayer(tutorial: tutorial)
                }
            }
        }
        
        private var filteredTutorials: [TutorialData] {
            var filtered = tutorials
            
            if let category = selectedCategory {
                filtered = filtered.filter { $0.category == category }
            }
            
            if !searchText.isEmpty {
                filtered = filtered.filter { tutorial in
                    tutorial.title.localizedCaseInsensitiveContains(searchText) ||
                    tutorial.description.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            return filtered
        }
    }
    
    // MARK: - Tutorial Card Component
    
    /// Card for tutorial display
    public struct TutorialCard: View {
        let tutorial: TutorialData
        let onTap: () -> Void
        
        public var body: some View {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {
                    // Thumbnail
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(tutorial.category.color.opacity(0.2))
                            .aspectRatio(16/9, contentMode: .fit)
                        
                        Image(systemName: tutorial.icon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(tutorial.category.color)
                    }
                    
                    // Tutorial info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tutorial.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(tutorial.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            Text(tutorial.category.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(tutorial.category.color)
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            Text("\(tutorial.steps.count) steps")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Supporting Types

struct TutorialData: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: TutorialCategory
    let steps: [TutorialStep]
    let quiz: TutorialQuiz
    
    init(id: String, title: String, description: String, icon: String, category: TutorialCategory, steps: [TutorialStep], quiz: TutorialQuiz) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.steps = steps
        self.quiz = quiz
    }
}

struct TutorialStep: Identifiable {
    let id: String
    let title: String
    let instructions: String
    let icon: String
    let videoURL: URL?
    let interactions: [TutorialInteraction]
    
    init(id: String, title: String, instructions: String, icon: String, videoURL: URL? = nil, interactions: [TutorialInteraction] = []) {
        self.id = id
        self.title = title
        self.instructions = instructions
        self.icon = icon
        self.videoURL = videoURL
        self.interactions = interactions
    }
}

struct TutorialInteraction: Identifiable {
    let id: String
    let type: InteractionType
    let title: String
    
    init(id: String, type: InteractionType, title: String) {
        self.id = id
        self.type = type
        self.title = title
    }
}

enum InteractionType {
    case tap
    case swipe
    case drag
}

struct TutorialQuiz {
    let title: String
    let questions: [QuizQuestion]
    
    init(title: String, questions: [QuizQuestion]) {
        self.title = title
        self.questions = questions
    }
}

struct QuizQuestion {
    let question: String
    let options: [String]
    let correctAnswer: Int
    
    init(question: String, options: [String], correctAnswer: Int) {
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
    }
}

enum TutorialCategory: String, CaseIterable {
    case basics = "Basics"
    case nutrition = "Nutrition"
    case exercise = "Exercise"
    case mentalHealth = "Mental Health"
    case medication = "Medication"
    case emergency = "Emergency"
    
    var color: Color {
        switch self {
        case .basics: return .blue
        case .nutrition: return .green
        case .exercise: return .orange
        case .mentalHealth: return .purple
        case .medication: return .yellow
        case .emergency: return .red
        }
    }
}

// MARK: - Preview

struct InteractiveVideoTutorials_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            InteractiveTutorialPlayer(
                tutorial: TutorialData(
                    id: "1",
                    title: "Basic Health Monitoring",
                    description: "Learn how to monitor your basic health metrics",
                    icon: "heart.fill",
                    category: .basics,
                    steps: [
                        TutorialStep(
                            id: "1",
                            title: "Check Heart Rate",
                            instructions: "Place your finger on the sensor to measure your heart rate",
                            icon: "heart.fill",
                            interactions: [
                                TutorialInteraction(id: "1", type: .tap, title: "Tap to start measurement")
                            ]
                        )
                    ],
                    quiz: TutorialQuiz(
                        title: "Health Monitoring Quiz",
                        questions: [
                            QuizQuestion(
                                question: "What is a normal resting heart rate?",
                                options: ["60-100 BPM", "40-60 BPM", "100-120 BPM", "120-140 BPM"],
                                correctAnswer: 0
                            )
                        ]
                    )
                )
            )
            
            TutorialLibrary(tutorials: [
                TutorialData(
                    id: "1",
                    title: "Basic Health Monitoring",
                    description: "Learn how to monitor your basic health metrics",
                    icon: "heart.fill",
                    category: .basics,
                    steps: [],
                    quiz: TutorialQuiz(title: "", questions: [])
                )
            ])
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 