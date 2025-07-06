import Foundation
import HealthKit
import CoreML
import NaturalLanguage
import Speech
import Combine

// MARK: - Enhanced AI Health Coach Manager

class EnhancedAIHealthCoachManager: ObservableObject {
    // MARK: - Published Properties
    @Published var conversationHistory: [ChatMessage] = []
    @Published var currentWorkoutRecommendation: WorkoutRecommendation?
    @Published var nutritionPlan: NutritionPlan?
    @Published var mentalHealthStatus: MentalHealthStatus = .good
    @Published var progressGoals: [HealthGoal] = []
    @Published var motivationalMessages: [MotivationalMessage] = []
    @Published var isListening = false
    @Published var isProcessing = false
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - User Profile
    private var userProfile: UserHealthProfile {
        didSet {
            updatePersonalization()
        }
    }
    
    // MARK: - AI Models
    private var nlpModel: NLModel?
    private var sentimentAnalyzer: NLModel?
    private var workoutRecommendationModel: MLModel?
    private var nutritionModel: MLModel?
    
    // MARK: - Initialization
    init() {
        self.userProfile = UserHealthProfile()
        setupAI()
        loadUserProfile()
        startHealthMonitoring()
    }
    
    // MARK: - Setup Methods
    
    private func setupAI() {
        loadNLPModels()
        setupSpeechRecognition()
        initializeConversationContext()
    }
    
    private func loadNLPModels() {
        // Load natural language processing models
        do {
            // Load conversation model
            if let modelURL = Bundle.main.url(forResource: "HealthCoachNLP", withExtension: "mlmodelc") {
                nlpModel = try NLModel(contentsOf: modelURL)
            }
            
            // Load sentiment analysis model
            if let sentimentURL = Bundle.main.url(forResource: "SentimentAnalysis", withExtension: "mlmodelc") {
                sentimentAnalyzer = try NLModel(contentsOf: sentimentURL)
            }
            
            // Load workout recommendation model
            if let workoutURL = Bundle.main.url(forResource: "WorkoutRecommendation", withExtension: "mlmodelc") {
                workoutRecommendationModel = try MLModel(contentsOf: workoutURL)
            }
            
            // Load nutrition model
            if let nutritionURL = Bundle.main.url(forResource: "NutritionGuidance", withExtension: "mlmodelc") {
                nutritionModel = try MLModel(contentsOf: nutritionURL)
            }
        } catch {
            print("Error loading AI models: \(error)")
        }
    }
    
    private func setupSpeechRecognition() {
        speechRecognizer?.delegate = self
        speechRecognizer?.supportsOnDeviceRecognition = true
    }
    
    private func initializeConversationContext() {
        // Initialize conversation with greeting
        let greeting = ChatMessage(
            id: UUID(),
            content: "Hello! I'm your AI health coach. I'm here to help you achieve your health goals. How can I assist you today?",
            sender: .ai,
            timestamp: Date(),
            messageType: .greeting
        )
        conversationHistory.append(greeting)
    }
    
    // MARK: - Conversational AI Interface
    
    func sendMessage(_ message: String) {
        let userMessage = ChatMessage(
            id: UUID(),
            content: message,
            sender: .user,
            timestamp: Date(),
            messageType: .text
        )
        conversationHistory.append(userMessage)
        
        // Process message and generate response
        processUserMessage(message)
    }
    
    private func processUserMessage(_ message: String) {
        isProcessing = true
        
        // Analyze sentiment
        let sentiment = analyzeSentiment(message)
        
        // Determine intent
        let intent = determineIntent(message)
        
        // Generate response based on intent and sentiment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let response = self.generateResponse(for: intent, sentiment: sentiment, context: message)
            let aiMessage = ChatMessage(
                id: UUID(),
                content: response,
                sender: .ai,
                timestamp: Date(),
                messageType: .text
            )
            self.conversationHistory.append(aiMessage)
            self.isProcessing = false
        }
    }
    
    private func analyzeSentiment(_ text: String) -> Sentiment {
        guard let model = sentimentAnalyzer else { return .neutral }
        
        do {
            let prediction = try model.predictedLabel(for: text)
            switch prediction {
            case "positive":
                return .positive
            case "negative":
                return .negative
            default:
                return .neutral
            }
        } catch {
            return .neutral
        }
    }
    
    private func determineIntent(_ message: String) -> ConversationIntent {
        let lowercased = message.lowercased()
        
        if lowercased.contains("workout") || lowercased.contains("exercise") || lowercased.contains("fitness") {
            return .workoutRecommendation
        } else if lowercased.contains("nutrition") || lowercased.contains("diet") || lowercased.contains("food") {
            return .nutritionGuidance
        } else if lowercased.contains("mental") || lowercased.contains("stress") || lowercased.contains("anxiety") {
            return .mentalHealthSupport
        } else if lowercased.contains("progress") || lowercased.contains("goal") || lowercased.contains("achievement") {
            return .progressTracking
        } else if lowercased.contains("motivation") || lowercased.contains("encourage") {
            return .motivation
        } else {
            return .generalHealth
        }
    }
    
    private func generateResponse(for intent: ConversationIntent, sentiment: Sentiment, context: String) -> String {
        switch intent {
        case .workoutRecommendation:
            return generateWorkoutResponse(sentiment: sentiment)
        case .nutritionGuidance:
            return generateNutritionResponse(sentiment: sentiment)
        case .mentalHealthSupport:
            return generateMentalHealthResponse(sentiment: sentiment)
        case .progressTracking:
            return generateProgressResponse(sentiment: sentiment)
        case .motivation:
            return generateMotivationalResponse(sentiment: sentiment)
        case .generalHealth:
            return generateGeneralHealthResponse(sentiment: sentiment)
        }
    }
    
    // MARK: - Voice Interaction
    
    func startVoiceRecognition() {
        guard !isListening else { return }
        
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.beginVoiceRecognition()
                }
            }
        }
    }
    
    func stopVoiceRecognition() {
        isListening = false
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    private func beginVoiceRecognition() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .dontDeactivateOnSilence)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            let inputNode = audioEngine.inputNode
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                if let result = result {
                    let transcribedText = result.bestTranscription.formattedString
                    if result.isFinal {
                        self?.sendMessage(transcribedText)
                        self?.stopVoiceRecognition()
                    }
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            
        } catch {
            print("Error starting voice recognition: \(error)")
        }
    }
    
    // MARK: - Workout Recommendations
    
    private func generateWorkoutResponse(sentiment: Sentiment) -> String {
        let recommendation = generatePersonalizedWorkout()
        currentWorkoutRecommendation = recommendation
        
        var response = "Based on your fitness level and goals, here's a personalized workout for you:\n\n"
        response += "🏃‍♂️ **\(recommendation.type.rawValue)**\n"
        response += "⏱️ Duration: \(recommendation.duration) minutes\n"
        response += "🔥 Intensity: \(recommendation.intensity.rawValue)\n\n"
        response += "**Exercises:**\n"
        
        for (index, exercise) in recommendation.exercises.enumerated() {
            response += "\(index + 1). \(exercise.name) - \(exercise.duration) min\n"
        }
        
        response += "\n💡 **Tips:** \(recommendation.tips)"
        
        if sentiment == .negative {
            response += "\n\nI understand you might not be feeling up to it today. Remember, even a short walk can make a big difference! 🌟"
        }
        
        return response
    }
    
    private func generatePersonalizedWorkout() -> WorkoutRecommendation {
        let fitnessLevel = assessFitnessLevel()
        let goals = userProfile.fitnessGoals
        let availableTime = userProfile.availableTime
        
        // Generate workout based on user profile
        let workoutType: WorkoutType
        let intensity: WorkoutIntensity
        let duration: Int
        
        switch goals {
        case .weightLoss:
            workoutType = .cardio
            intensity = .moderate
            duration = min(availableTime, 45)
        case .strength:
            workoutType = .strength
            intensity = .high
            duration = min(availableTime, 60)
        case .endurance:
            workoutType = .cardio
            intensity = .high
            duration = min(availableTime, 60)
        case .flexibility:
            workoutType = .flexibility
            intensity = .low
            duration = min(availableTime, 30)
        }
        
        let exercises = generateExercises(for: workoutType, duration: duration, fitnessLevel: fitnessLevel)
        let tips = generateWorkoutTips(for: workoutType, fitnessLevel: fitnessLevel)
        
        return WorkoutRecommendation(
            type: workoutType,
            intensity: intensity,
            duration: duration,
            exercises: exercises,
            tips: tips,
            caloriesBurned: estimateCaloriesBurned(type: workoutType, duration: duration, intensity: intensity)
        )
    }
    
    private func assessFitnessLevel() -> FitnessLevel {
        // Analyze health data to determine fitness level
        let heartRate = userProfile.averageHeartRate
        let activityLevel = userProfile.activityLevel
        let age = userProfile.age
        
        if activityLevel > 10000 && heartRate < 70 {
            return .advanced
        } else if activityLevel > 7000 && heartRate < 80 {
            return .intermediate
        } else {
            return .beginner
        }
    }
    
    private func generateExercises(for type: WorkoutType, duration: Int, fitnessLevel: FitnessLevel) -> [Exercise] {
        switch type {
        case .cardio:
            return [
                Exercise(name: "Jogging", duration: duration / 2, type: .cardio),
                Exercise(name: "Jumping Jacks", duration: 5, type: .cardio),
                Exercise(name: "High Knees", duration: 5, type: .cardio),
                Exercise(name: "Burpees", duration: 5, type: .cardio)
            ]
        case .strength:
            return [
                Exercise(name: "Push-ups", duration: 10, type: .strength),
                Exercise(name: "Squats", duration: 10, type: .strength),
                Exercise(name: "Plank", duration: 5, type: .strength),
                Exercise(name: "Lunges", duration: 10, type: .strength)
            ]
        case .flexibility:
            return [
                Exercise(name: "Stretching", duration: 10, type: .flexibility),
                Exercise(name: "Yoga Poses", duration: 10, type: .flexibility),
                Exercise(name: "Deep Breathing", duration: 5, type: .flexibility),
                Exercise(name: "Meditation", duration: 5, type: .flexibility)
            ]
        }
    }
    
    private func generateWorkoutTips(for type: WorkoutType, fitnessLevel: FitnessLevel) -> String {
        switch type {
        case .cardio:
            return "Start slow and gradually increase intensity. Stay hydrated and listen to your body."
        case .strength:
            return "Focus on proper form over weight. Take rest days between strength sessions."
        case .flexibility:
            return "Breathe deeply and hold each stretch for 30 seconds. Don't force any movements."
        }
    }
    
    private func estimateCaloriesBurned(type: WorkoutType, duration: Int, intensity: WorkoutIntensity) -> Int {
        let baseCalories: Int
        switch type {
        case .cardio:
            baseCalories = 8
        case .strength:
            baseCalories = 6
        case .flexibility:
            baseCalories = 3
        }
        
        let intensityMultiplier: Double
        switch intensity {
        case .low:
            intensityMultiplier = 0.7
        case .moderate:
            intensityMultiplier = 1.0
        case .high:
            intensityMultiplier = 1.3
        }
        
        return Int(Double(baseCalories * duration) * intensityMultiplier)
    }
    
    // MARK: - Nutrition Guidance
    
    private func generateNutritionResponse(sentiment: Sentiment) -> String {
        let plan = generateNutritionPlan()
        nutritionPlan = plan
        
        var response = "Here's your personalized nutrition plan:\n\n"
        response += "🍎 **Daily Calorie Target:** \(plan.dailyCalories) calories\n"
        response += "🥩 **Protein:** \(plan.proteinGrams)g\n"
        response += "🍞 **Carbs:** \(plan.carbGrams)g\n"
        response += "🥑 **Fat:** \(plan.fatGrams)g\n\n"
        
        response += "**Meal Suggestions:**\n"
        for meal in plan.meals {
            response += "🍽️ \(meal.name): \(meal.calories) calories\n"
        }
        
        response += "\n💧 **Hydration:** Aim for \(plan.hydrationTarget) glasses of water daily"
        
        if sentiment == .negative {
            response += "\n\nRemember, healthy eating is a journey, not a destination. Every healthy choice counts! 🌱"
        }
        
        return response
    }
    
    private func generateNutritionPlan() -> NutritionPlan {
        let bmr = calculateBMR()
        let tdee = calculateTDEE(bmr: bmr)
        let goal = userProfile.nutritionGoal
        
        let dailyCalories: Int
        switch goal {
        case .weightLoss:
            dailyCalories = Int(Double(tdee) * 0.85) // 15% deficit
        case .maintenance:
            dailyCalories = tdee
        case .muscleGain:
            dailyCalories = Int(Double(tdee) * 1.1) // 10% surplus
        }
        
        let proteinGrams = Int(Double(userProfile.weight) * 1.6) // 1.6g per kg
        let fatGrams = Int(Double(dailyCalories) * 0.25 / 9) // 25% of calories
        let carbGrams = (dailyCalories - (proteinGrams * 4) - (fatGrams * 9)) / 4
        
        let meals = generateMealPlan(calories: dailyCalories, protein: proteinGrams, carbs: carbGrams, fat: fatGrams)
        
        return NutritionPlan(
            dailyCalories: dailyCalories,
            proteinGrams: proteinGrams,
            carbGrams: carbGrams,
            fatGrams: fatGrams,
            meals: meals,
            hydrationTarget: 8,
            supplements: generateSupplementRecommendations()
        )
    }
    
    private func calculateBMR() -> Int {
        // Mifflin-St Jeor Equation
        let weight = userProfile.weight
        let height = userProfile.height
        let age = userProfile.age
        let isMale = userProfile.gender == .male
        
        if isMale {
            return Int(10 * weight + 6.25 * height - 5 * age + 5)
        } else {
            return Int(10 * weight + 6.25 * height - 5 * age - 161)
        }
    }
    
    private func calculateTDEE(bmr: Int) -> Int {
        let activityMultiplier: Double
        switch userProfile.activityLevel {
        case 0..<5000:
            activityMultiplier = 1.2 // Sedentary
        case 5000..<7500:
            activityMultiplier = 1.375 // Lightly active
        case 7500..<10000:
            activityMultiplier = 1.55 // Moderately active
        default:
            activityMultiplier = 1.725 // Very active
        }
        
        return Int(Double(bmr) * activityMultiplier)
    }
    
    private func generateMealPlan(calories: Int, protein: Int, carbs: Int, fat: Int) -> [Meal] {
        let breakfastCalories = Int(Double(calories) * 0.25)
        let lunchCalories = Int(Double(calories) * 0.35)
        let dinnerCalories = Int(Double(calories) * 0.30)
        let snackCalories = Int(Double(calories) * 0.10)
        
        return [
            Meal(name: "Breakfast", calories: breakfastCalories, type: .breakfast),
            Meal(name: "Lunch", calories: lunchCalories, type: .lunch),
            Meal(name: "Dinner", calories: dinnerCalories, type: .dinner),
            Meal(name: "Snack", calories: snackCalories, type: .snack)
        ]
    }
    
    private func generateSupplementRecommendations() -> [Supplement] {
        var supplements: [Supplement] = []
        
        // Vitamin D if low sun exposure
        if userProfile.sunExposure < 15 {
            supplements.append(Supplement(name: "Vitamin D", dosage: "1000 IU", frequency: "Daily"))
        }
        
        // Omega-3 for heart health
        supplements.append(Supplement(name: "Omega-3", dosage: "1000mg", frequency: "Daily"))
        
        // Protein powder if struggling to meet protein goals
        if userProfile.proteinIntake < userProfile.weight * 1.6 {
            supplements.append(Supplement(name: "Protein Powder", dosage: "25g", frequency: "Post-workout"))
        }
        
        return supplements
    }
    
    // MARK: - Mental Health Support
    
    private func generateMentalHealthResponse(sentiment: Sentiment) -> String {
        let status = assessMentalHealthStatus()
        mentalHealthStatus = status
        
        var response = "I'm here to support your mental health journey. "
        
        switch status {
        case .excellent:
            response += "Your mental health appears to be in great shape! Keep up the positive habits."
        case .good:
            response += "You're doing well! Here are some ways to maintain your mental wellness:"
        case .moderate:
            response += "I notice you might be experiencing some stress. Let's work on some coping strategies:"
        case .poor:
            response += "I'm concerned about your mental health. Please consider reaching out to a mental health professional."
        }
        
        response += "\n\n🧘‍♀️ **Mindfulness Exercise:** Take 5 deep breaths, focusing on each inhale and exhale."
        response += "\n😴 **Sleep Hygiene:** Aim for 7-9 hours of quality sleep tonight."
        response += "\n🌞 **Sunlight:** Try to get 15-30 minutes of natural sunlight today."
        response += "\n📞 **Support:** Don't hesitate to reach out to friends, family, or professionals."
        
        if sentiment == .negative {
            response += "\n\nRemember, it's okay to not be okay. You're not alone, and seeking help is a sign of strength. 💙"
        }
        
        return response
    }
    
    private func assessMentalHealthStatus() -> MentalHealthStatus {
        // Analyze sleep quality, stress levels, and mood indicators
        let sleepQuality = userProfile.averageSleepQuality
        let stressLevel = userProfile.stressLevel
        let moodScore = userProfile.moodScore
        
        if sleepQuality > 8 && stressLevel < 3 && moodScore > 7 {
            return .excellent
        } else if sleepQuality > 6 && stressLevel < 5 && moodScore > 5 {
            return .good
        } else if sleepQuality > 4 && stressLevel < 7 && moodScore > 3 {
            return .moderate
        } else {
            return .poor
        }
    }
    
    // MARK: - Progress Tracking
    
    private func generateProgressResponse(sentiment: Sentiment) -> String {
        let progress = calculateProgress()
        updateProgressGoals(progress: progress)
        
        var response = "Here's your progress update:\n\n"
        
        for goal in progressGoals {
            let percentage = Int(goal.progress * 100)
            response += "🎯 **\(goal.name):** \(percentage)% complete\n"
            
            if goal.progress >= 1.0 {
                response += "🎉 Congratulations! You've achieved this goal!\n"
            } else {
                let remaining = goal.target - goal.current
                response += "📈 \(remaining) more to go\n"
            }
            response += "\n"
        }
        
        response += "**Overall Progress:** \(Int(progress.overallProgress * 100))%\n"
        response += "**Streak:** \(progress.currentStreak) days\n"
        response += "**Next Milestone:** \(progress.nextMilestone)"
        
        if sentiment == .positive {
            response += "\n\nYou're doing amazing! Keep up the fantastic work! 🌟"
        } else {
            response += "\n\nEvery step forward is progress. You're building healthy habits that will last a lifetime! 💪"
        }
        
        return response
    }
    
    private func calculateProgress() -> ProgressSummary {
        let goals = progressGoals
        let overallProgress = goals.isEmpty ? 0 : goals.map { $0.progress }.reduce(0, +) / Double(goals.count)
        
        let currentStreak = calculateCurrentStreak()
        let nextMilestone = determineNextMilestone(progress: overallProgress)
        
        return ProgressSummary(
            overallProgress: overallProgress,
            currentStreak: currentStreak,
            nextMilestone: nextMilestone,
            goalsCompleted: goals.filter { $0.progress >= 1.0 }.count,
            totalGoals: goals.count
        )
    }
    
    private func calculateCurrentStreak() -> Int {
        // Calculate consecutive days of activity
        // Implementation would track daily activity and count consecutive days
        return 7 // Placeholder
    }
    
    private func determineNextMilestone(progress: Double) -> String {
        if progress < 0.25 {
            return "Complete 25% of your goals"
        } else if progress < 0.5 {
            return "Reach 50% completion"
        } else if progress < 0.75 {
            return "Achieve 75% of your goals"
        } else {
            return "Complete all your goals!"
        }
    }
    
    // MARK: - Motivation System
    
    private func generateMotivationalResponse(sentiment: Sentiment) -> String {
        let message = generatePersonalizedMotivationalMessage(sentiment: sentiment)
        motivationalMessages.append(message)
        
        return message.content
    }
    
    private func generatePersonalizedMotivationalMessage(sentiment: Sentiment) -> MotivationalMessage {
        let messages: [String]
        
        switch sentiment {
        case .positive:
            messages = [
                "You're absolutely crushing it! Your positive energy is inspiring! 🌟",
                "Look at you go! Your dedication is paying off in amazing ways! 💪",
                "You're not just making progress, you're creating a healthier, happier life! 🎉",
                "Your commitment to your health is truly admirable. Keep shining! ✨"
            ]
        case .negative:
            messages = [
                "Remember, every expert was once a beginner. You're learning and growing every day! 🌱",
                "It's okay to have tough days. What matters is that you keep moving forward! 💙",
                "You're stronger than you think. Every challenge is making you more resilient! 🔥",
                "Progress isn't always linear, but you're still moving in the right direction! 📈"
            ]
        case .neutral:
            messages = [
                "You're building healthy habits that will serve you for a lifetime! 🏆",
                "Consistency beats perfection every time. You're doing great! 🎯",
                "Your future self will thank you for the choices you're making today! 🙏",
                "Every healthy choice is a step toward your best self! 🌟"
            ]
        }
        
        let randomMessage = messages.randomElement() ?? messages[0]
        
        return MotivationalMessage(
            id: UUID(),
            content: randomMessage,
            timestamp: Date(),
            category: sentiment == .negative ? .encouragement : .celebration
        )
    }
    
    // MARK: - General Health Response
    
    private func generateGeneralHealthResponse(sentiment: Sentiment) -> String {
        let healthScore = calculateHealthScore()
        
        var response = "Your overall health score is \(healthScore)/100. "
        
        if healthScore >= 90 {
            response += "Excellent! You're in fantastic health! 🌟"
        } else if healthScore >= 75 {
            response += "Great job! You're maintaining good health habits! 👍"
        } else if healthScore >= 60 {
            response += "You're on the right track! Here are some areas to focus on:"
        } else {
            response += "Let's work together to improve your health. Here's what we can focus on:"
        }
        
        response += "\n\n**Health Areas:**\n"
        response += "❤️ Heart Health: \(userProfile.heartHealthScore)/100\n"
        response += "💪 Fitness: \(userProfile.fitnessScore)/100\n"
        response += "🧠 Mental Health: \(userProfile.mentalHealthScore)/100\n"
        response += "🍎 Nutrition: \(userProfile.nutritionScore)/100\n"
        response += "😴 Sleep: \(userProfile.sleepScore)/100"
        
        return response
    }
    
    private func calculateHealthScore() -> Int {
        let scores = [
            userProfile.heartHealthScore,
            userProfile.fitnessScore,
            userProfile.mentalHealthScore,
            userProfile.nutritionScore,
            userProfile.sleepScore
        ]
        
        return Int(scores.reduce(0, +) / Double(scores.count))
    }
    
    // MARK: - Health Monitoring
    
    private func startHealthMonitoring() {
        // Monitor health data changes and update recommendations
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateHealthData()
            }
            .store(in: &cancellables)
    }
    
    private func updateHealthData() {
        // Fetch latest health data and update user profile
        // Implementation would integrate with HealthKit
    }
    
    private func loadUserProfile() {
        // Load user profile from persistent storage
        // Implementation would load from UserDefaults or Core Data
    }
    
    private func updatePersonalization() {
        // Update AI recommendations based on new user profile data
        // Implementation would retrain or adjust AI models
    }
}

// MARK: - Supporting Types

enum ConversationIntent {
    case workoutRecommendation
    case nutritionGuidance
    case mentalHealthSupport
    case progressTracking
    case motivation
    case generalHealth
}

enum Sentiment {
    case positive
    case negative
    case neutral
}

enum MessageSender {
    case user
    case ai
}

enum MessageType {
    case text
    case greeting
    case workout
    case nutrition
    case mentalHealth
}

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let sender: MessageSender
    let timestamp: Date
    let messageType: MessageType
}

enum WorkoutType: String, CaseIterable {
    case cardio = "Cardio"
    case strength = "Strength Training"
    case flexibility = "Flexibility & Mobility"
}

enum WorkoutIntensity: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
}

enum FitnessLevel: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

enum FitnessGoal: String, CaseIterable {
    case weightLoss = "Weight Loss"
    case strength = "Strength Building"
    case endurance = "Endurance"
    case flexibility = "Flexibility"
}

enum NutritionGoal: String, CaseIterable {
    case weightLoss = "Weight Loss"
    case maintenance = "Maintenance"
    case muscleGain = "Muscle Gain"
}

enum MealType: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}

enum MentalHealthStatus: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case moderate = "Moderate"
    case poor = "Poor"
}

enum MotivationalCategory: String, CaseIterable {
    case celebration = "Celebration"
    case encouragement = "Encouragement"
    case reminder = "Reminder"
}

struct WorkoutRecommendation {
    let type: WorkoutType
    let intensity: WorkoutIntensity
    let duration: Int
    let exercises: [Exercise]
    let tips: String
    let caloriesBurned: Int
}

struct Exercise {
    let name: String
    let duration: Int
    let type: WorkoutType
}

struct NutritionPlan {
    let dailyCalories: Int
    let proteinGrams: Int
    let carbGrams: Int
    let fatGrams: Int
    let meals: [Meal]
    let hydrationTarget: Int
    let supplements: [Supplement]
}

struct Meal {
    let name: String
    let calories: Int
    let type: MealType
}

struct Supplement {
    let name: String
    let dosage: String
    let frequency: String
}

struct HealthGoal: Identifiable {
    let id: UUID
    let name: String
    let target: Double
    let current: Double
    let unit: String
    let deadline: Date
    
    var progress: Double {
        return current / target
    }
}

struct MotivationalMessage: Identifiable {
    let id: UUID
    let content: String
    let timestamp: Date
    let category: MotivationalCategory
}

struct ProgressSummary {
    let overallProgress: Double
    let currentStreak: Int
    let nextMilestone: String
    let goalsCompleted: Int
    let totalGoals: Int
}

struct UserHealthProfile {
    var age: Int = 30
    var weight: Double = 70.0 // kg
    var height: Double = 170.0 // cm
    var gender: Gender = .other
    var fitnessGoals: FitnessGoal = .weightLoss
    var nutritionGoal: NutritionGoal = .maintenance
    var availableTime: Int = 60 // minutes
    var activityLevel: Int = 8000 // steps
    var averageHeartRate: Int = 75
    var averageSleepQuality: Double = 7.5
    var stressLevel: Int = 4 // 1-10 scale
    var moodScore: Double = 7.0 // 1-10 scale
    var sunExposure: Int = 20 // minutes
    var proteinIntake: Double = 80.0 // grams
    
    // Health scores (0-100)
    var heartHealthScore: Int = 85
    var fitnessScore: Int = 75
    var mentalHealthScore: Int = 80
    var nutritionScore: Int = 70
    var sleepScore: Int = 75
}

enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

// MARK: - Speech Recognition Delegate

extension EnhancedAIHealthCoachManager: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Handle availability changes
    }
} 