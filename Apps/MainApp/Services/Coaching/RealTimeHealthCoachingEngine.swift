import Foundation
import CoreML
import HealthKit
import Combine
import AVFoundation

/// Real-Time Health Coaching Engine
/// Provides personalized AI coaching and adaptive health recommendations
@available(iOS 18.0, macOS 15.0, *)
public actor RealTimeHealthCoachingEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var currentCoachingSession: CoachingSession?
    @Published public private(set) var activeRecommendations: [HealthRecommendation] = []
    @Published public private(set) var coachingHistory: [CoachingSession] = []
    @Published public private(set) var isCoachingActive = false
    @Published public private(set) var currentGoal: HealthGoal?
    @Published public private(set) var progressMetrics: ProgressMetrics = ProgressMetrics()
    @Published public private(set) var lastError: String?
    
    // MARK: - Private Properties
    private let healthDataManager: HealthDataManager
    private let predictionEngine: AdvancedHealthPredictionEngine
    private let analyticsEngine: AnalyticsEngine
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let coachingModel: MLModel?
    
    private var cancellables = Set<AnyCancellable>()
    private let coachingQueue = DispatchQueue(label: "health.coaching", qos: .userInitiated)
    private let healthStore = HKHealthStore()
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, 
                predictionEngine: AdvancedHealthPredictionEngine,
                analyticsEngine: AnalyticsEngine) {
        self.healthDataManager = healthDataManager
        self.predictionEngine = predictionEngine
        self.analyticsEngine = analyticsEngine
        self.coachingModel = nil // Load coaching model
        
        setupHealthKitObservers()
        setupCoachingSession()
    }
    
    // MARK: - Public Methods
    
    /// Start a new coaching session
    public func startCoachingSession(goal: HealthGoal? = nil) async throws -> CoachingSession {
        isCoachingActive = true
        lastError = nil
        
        do {
            // Create new coaching session
            let session = CoachingSession(
                id: UUID(),
                startTime: Date(),
                goal: goal ?? currentGoal,
                status: .active,
                recommendations: [],
                interactions: []
            )
            
            // Generate initial recommendations
            let recommendations = try await generateRecommendations(for: session)
            session.recommendations = recommendations
            
            // Update current session
            await MainActor.run {
                self.currentCoachingSession = session
                self.activeRecommendations = recommendations
                self.coachingHistory.append(session)
            }
            
            // Track analytics
            analyticsEngine.trackEvent("coaching_session_started", properties: [
                "goal_type": goal?.type.rawValue ?? "general",
                "session_id": session.id.uuidString
            ])
            
            return session
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isCoachingActive = false
            }
            throw error
        }
    }
    
    /// End current coaching session
    public func endCoachingSession() async {
        guard let session = currentCoachingSession else { return }
        
        session.endTime = Date()
        session.status = .completed
        
        // Calculate session metrics
        let metrics = calculateSessionMetrics(session)
        session.metrics = metrics
        
        // Update progress
        await updateProgressMetrics(session: session)
        
        await MainActor.run {
            self.currentCoachingSession = nil
            self.isCoachingActive = false
        }
        
        // Track analytics
        analyticsEngine.trackEvent("coaching_session_completed", properties: [
            "session_duration": session.duration,
            "recommendations_followed": metrics.recommendationsFollowed,
            "goal_progress": metrics.goalProgress
        ])
    }
    
    /// Generate personalized health recommendations
    public func generateRecommendations(for session: CoachingSession? = nil) async throws -> [HealthRecommendation] {
        let currentSession = session ?? currentCoachingSession
        
        do {
            // Get current health data
            let healthData = try await collectCurrentHealthData()
            
            // Get predictions for context
            let predictions = try await predictionEngine.generatePredictions()
            
            // Generate recommendations based on health data and predictions
            let recommendations = try await createPersonalizedRecommendations(
                healthData: healthData,
                predictions: predictions,
                session: currentSession
            )
            
            // Update active recommendations
            await MainActor.run {
                self.activeRecommendations = recommendations
            }
            
            return recommendations
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Process user interaction and provide coaching response
    public func processUserInteraction(_ interaction: UserInteraction) async throws -> CoachingResponse {
        guard let session = currentCoachingSession else {
            throw CoachingError.noActiveSession
        }
        
        // Add interaction to session
        session.interactions.append(interaction)
        
        // Generate coaching response
        let response = try await generateCoachingResponse(for: interaction, session: session)
        
        // Update session
        session.interactions.append(interaction)
        
        // Track analytics
        analyticsEngine.trackEvent("user_interaction_processed", properties: [
            "interaction_type": interaction.type.rawValue,
            "session_id": session.id.uuidString
        ])
        
        return response
    }
    
    /// Set or update health goal
    public func setHealthGoal(_ goal: HealthGoal) async {
        await MainActor.run {
            self.currentGoal = goal
        }
        
        // Generate goal-specific recommendations
        if let session = currentCoachingSession {
            let recommendations = try? await generateRecommendations(for: session)
            await MainActor.run {
                self.activeRecommendations = recommendations ?? []
            }
        }
        
        // Track analytics
        analyticsEngine.trackEvent("health_goal_set", properties: [
            "goal_type": goal.type.rawValue,
            "target_value": goal.targetValue,
            "timeframe": goal.timeframe.rawValue
        ])
    }
    
    /// Provide voice coaching
    public func provideVoiceCoaching(_ message: String) async {
        let utterance = AVSpeechUtterance(string: message)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        
        speechSynthesizer.speak(utterance)
    }
    
    /// Get coaching insights and progress
    public func getCoachingInsights() async -> CoachingInsights {
        let insights = CoachingInsights(
            totalSessions: coachingHistory.count,
            averageSessionDuration: calculateAverageSessionDuration(),
            mostCommonGoals: getMostCommonGoals(),
            successRate: calculateSuccessRate(),
            improvementAreas: identifyImprovementAreas(),
            recommendations: generateInsightRecommendations()
        )
        
        return insights
    }
    
    // MARK: - Private Methods
    
    private func setupHealthKitObservers() {
        // Observe health data changes for real-time coaching
        healthStore.healthDataPublisher
            .sink { [weak self] healthData in
                Task {
                    await self?.processHealthDataUpdate(healthData)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupCoachingSession() {
        // Initialize coaching session with default goal
        Task {
            let defaultGoal = HealthGoal(
                type: .generalWellness,
                targetValue: 0.8,
                timeframe: .month,
                description: "Improve overall health and wellness"
            )
            await setHealthGoal(defaultGoal)
        }
    }
    
    private func collectCurrentHealthData() async throws -> HealthData {
        let data = HealthData()
        
        // Collect current health metrics
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let heartRateData = try await healthStore.samples(
                of: heartRateType,
                predicate: nil,
                limit: 10,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            )
            data.heartRateSamples = heartRateData
        }
        
        // Collect activity data
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let stepData = try await healthStore.samples(
                of: stepType,
                predicate: nil,
                limit: 10,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            )
            data.stepSamples = stepData
        }
        
        // Collect sleep data
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            let sleepData = try await healthStore.samples(
                of: sleepType,
                predicate: nil,
                limit: 5,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            )
            data.sleepSamples = sleepData
        }
        
        return data
    }
    
    private func createPersonalizedRecommendations(
        healthData: HealthData,
        predictions: ComprehensiveHealthPrediction,
        session: CoachingSession?
    ) async throws -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // Cardiovascular health recommendations
        if predictions.cardiovascular.riskScore > 0.3 {
            recommendations.append(HealthRecommendation(
                type: .cardiovascular,
                title: "Improve Heart Health",
                description: "Your cardiovascular risk is elevated. Consider increasing physical activity and monitoring blood pressure.",
                priority: .high,
                estimatedTime: 30,
                difficulty: .moderate,
                category: .exercise
            ))
        }
        
        // Sleep quality recommendations
        if predictions.sleep.qualityScore < 0.7 {
            recommendations.append(HealthRecommendation(
                type: .sleep,
                title: "Optimize Sleep Quality",
                description: "Your sleep quality could be improved. Try establishing a consistent bedtime routine.",
                priority: .medium,
                estimatedTime: 15,
                difficulty: .easy,
                category: .lifestyle
            ))
        }
        
        // Stress management recommendations
        if predictions.stress.stressLevel > 0.6 {
            recommendations.append(HealthRecommendation(
                type: .stress,
                title: "Manage Stress Levels",
                description: "Your stress levels are high. Consider meditation or deep breathing exercises.",
                priority: .high,
                estimatedTime: 10,
                difficulty: .easy,
                category: .mentalHealth
            ))
        }
        
        // Goal-specific recommendations
        if let goal = session?.goal {
            recommendations.append(contentsOf: generateGoalSpecificRecommendations(goal: goal))
        }
        
        // Sort by priority and estimated time
        recommendations.sort { $0.priority.rawValue > $1.priority.rawValue }
        
        return recommendations
    }
    
    private func generateGoalSpecificRecommendations(goal: HealthGoal) -> [HealthRecommendation] {
        switch goal.type {
        case .weightLoss:
            return [
                HealthRecommendation(
                    type: .nutrition,
                    title: "Track Caloric Intake",
                    description: "Monitor your daily caloric intake to achieve your weight loss goal.",
                    priority: .high,
                    estimatedTime: 5,
                    difficulty: .easy,
                    category: .nutrition
                ),
                HealthRecommendation(
                    type: .exercise,
                    title: "Increase Physical Activity",
                    description: "Aim for 150 minutes of moderate exercise per week.",
                    priority: .high,
                    estimatedTime: 30,
                    difficulty: .moderate,
                    category: .exercise
                )
            ]
        case .cardiovascularHealth:
            return [
                HealthRecommendation(
                    type: .exercise,
                    title: "Cardio Training",
                    description: "Engage in cardiovascular exercises to improve heart health.",
                    priority: .high,
                    estimatedTime: 45,
                    difficulty: .moderate,
                    category: .exercise
                )
            ]
        case .sleepOptimization:
            return [
                HealthRecommendation(
                    type: .sleep,
                    title: "Sleep Hygiene",
                    description: "Improve your sleep environment and bedtime routine.",
                    priority: .medium,
                    estimatedTime: 20,
                    difficulty: .easy,
                    category: .lifestyle
                )
            ]
        case .stressReduction:
            return [
                HealthRecommendation(
                    type: .mentalHealth,
                    title: "Mindfulness Practice",
                    description: "Practice mindfulness meditation for stress reduction.",
                    priority: .medium,
                    estimatedTime: 15,
                    difficulty: .easy,
                    category: .mentalHealth
                )
            ]
        case .generalWellness:
            return [
                HealthRecommendation(
                    type: .lifestyle,
                    title: "Daily Wellness Check",
                    description: "Complete your daily wellness activities and health tracking.",
                    priority: .medium,
                    estimatedTime: 10,
                    difficulty: .easy,
                    category: .lifestyle
                )
            ]
        }
    }
    
    private func generateCoachingResponse(for interaction: UserInteraction, session: CoachingSession) async throws -> CoachingResponse {
        // Generate contextual coaching response based on interaction
        let response = CoachingResponse(
            id: UUID(),
            message: generateResponseMessage(for: interaction),
            recommendations: try await generateRecommendations(for: session),
            encouragement: generateEncouragement(for: interaction),
            nextSteps: generateNextSteps(for: interaction),
            timestamp: Date()
        )
        
        return response
    }
    
    private func generateResponseMessage(for interaction: UserInteraction) -> String {
        switch interaction.type {
        case .goalCompleted:
            return "Excellent work! You've completed your goal. Let's set a new challenge to keep the momentum going."
        case .recommendationFollowed:
            return "Great job following the recommendation! How did it feel? Would you like to try another one?"
        case .healthDataUpdated:
            return "I see your health data has improved. Keep up the great work! Here are some suggestions to continue your progress."
        case .struggling:
            return "I understand this can be challenging. Let's break it down into smaller, more manageable steps. What's the biggest obstacle you're facing?"
        case .question:
            return "That's a great question! Let me provide you with some personalized guidance based on your current health status."
        }
    }
    
    private func generateEncouragement(for interaction: UserInteraction) -> String {
        let encouragements = [
            "You're making great progress!",
            "Every small step counts toward your health goals.",
            "You have the power to improve your health.",
            "Consistency is key - you're building healthy habits.",
            "Your dedication to health is inspiring!"
        ]
        
        return encouragements.randomElement() ?? "Keep up the great work!"
    }
    
    private func generateNextSteps(for interaction: UserInteraction) -> [String] {
        switch interaction.type {
        case .goalCompleted:
            return ["Set a new goal", "Review your progress", "Celebrate your achievement"]
        case .recommendationFollowed:
            return ["Try another recommendation", "Track your progress", "Share your success"]
        case .healthDataUpdated:
            return ["Continue current routine", "Set new targets", "Monitor trends"]
        case .struggling:
            return ["Break down the goal", "Seek support", "Adjust expectations"]
        case .question:
            return ["Review recommendations", "Check progress", "Ask more questions"]
        }
    }
    
    private func processHealthDataUpdate(_ healthData: [HKQuantitySample]) {
        // Process real-time health data for coaching
        Task {
            if let session = currentCoachingSession {
                let recommendations = try? await generateRecommendations(for: session)
                await MainActor.run {
                    self.activeRecommendations = recommendations ?? []
                }
            }
        }
    }
    
    private func calculateSessionMetrics(_ session: CoachingSession) -> SessionMetrics {
        let duration = session.duration
        let recommendationsFollowed = session.interactions.filter { $0.type == .recommendationFollowed }.count
        let goalProgress = calculateGoalProgress(session: session)
        
        return SessionMetrics(
            duration: duration,
            recommendationsFollowed: recommendationsFollowed,
            goalProgress: goalProgress,
            engagementScore: calculateEngagementScore(session: session)
        )
    }
    
    private func calculateGoalProgress(session: CoachingSession) -> Double {
        // Calculate progress toward current goal
        guard let goal = session.goal else { return 0.0 }
        
        // This would be calculated based on actual health data progress
        return 0.75 // Placeholder
    }
    
    private func calculateEngagementScore(session: CoachingSession) -> Double {
        let interactionCount = session.interactions.count
        let duration = session.duration
        
        // Calculate engagement based on interactions per minute
        return min(1.0, Double(interactionCount) / (duration / 60.0))
    }
    
    private func updateProgressMetrics(session: CoachingSession) async {
        let metrics = session.metrics ?? SessionMetrics(duration: 0, recommendationsFollowed: 0, goalProgress: 0, engagementScore: 0)
        
        await MainActor.run {
            self.progressMetrics.totalSessions += 1
            self.progressMetrics.totalDuration += metrics.duration
            self.progressMetrics.totalRecommendationsFollowed += metrics.recommendationsFollowed
            self.progressMetrics.averageGoalProgress = (self.progressMetrics.averageGoalProgress + metrics.goalProgress) / 2.0
        }
    }
    
    private func calculateAverageSessionDuration() -> TimeInterval {
        guard !coachingHistory.isEmpty else { return 0 }
        let totalDuration = coachingHistory.compactMap { $0.metrics?.duration }.reduce(0, +)
        return totalDuration / Double(coachingHistory.count)
    }
    
    private func getMostCommonGoals() -> [HealthGoalType] {
        let goalTypes = coachingHistory.compactMap { $0.goal?.type }
        let counts = Dictionary(grouping: goalTypes, by: { $0 }).mapValues { $0.count }
        return counts.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    private func calculateSuccessRate() -> Double {
        let completedSessions = coachingHistory.filter { $0.status == .completed }
        guard !completedSessions.isEmpty else { return 0.0 }
        
        let successfulSessions = completedSessions.filter { session in
            guard let metrics = session.metrics else { return false }
            return metrics.goalProgress >= 0.7 && metrics.engagementScore >= 0.6
        }
        
        return Double(successfulSessions.count) / Double(completedSessions.count)
    }
    
    private func identifyImprovementAreas() -> [String] {
        var areas: [String] = []
        
        if progressMetrics.averageGoalProgress < 0.6 {
            areas.append("Goal Achievement")
        }
        
        if progressMetrics.totalRecommendationsFollowed < progressMetrics.totalSessions {
            areas.append("Recommendation Adherence")
        }
        
        return areas
    }
    
    private func generateInsightRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if progressMetrics.averageGoalProgress < 0.6 {
            recommendations.append("Consider setting smaller, more achievable goals")
        }
        
        if progressMetrics.totalRecommendationsFollowed < progressMetrics.totalSessions {
            recommendations.append("Try focusing on one recommendation at a time")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Models

public class CoachingSession: ObservableObject {
    public let id: UUID
    public let startTime: Date
    public var endTime: Date?
    public let goal: HealthGoal?
    public var status: SessionStatus
    public var recommendations: [HealthRecommendation]
    public var interactions: [UserInteraction]
    public var metrics: SessionMetrics?
    
    public var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    public init(id: UUID, startTime: Date, goal: HealthGoal?, status: SessionStatus, recommendations: [HealthRecommendation], interactions: [UserInteraction]) {
        self.id = id
        self.startTime = startTime
        self.goal = goal
        self.status = status
        self.recommendations = recommendations
        self.interactions = interactions
    }
}

public struct HealthRecommendation: Identifiable, Codable {
    public let id = UUID()
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let priority: Priority
    public let estimatedTime: Int // minutes
    public let difficulty: Difficulty
    public let category: Category
    
    public enum RecommendationType: String, Codable, CaseIterable {
        case cardiovascular, sleep, stress, nutrition, exercise, mentalHealth, lifestyle
    }
    
    public enum Priority: Int, Codable, CaseIterable {
        case low = 1, medium = 2, high = 3
    }
    
    public enum Difficulty: String, Codable, CaseIterable {
        case easy, moderate, challenging
    }
    
    public enum Category: String, Codable, CaseIterable {
        case exercise, nutrition, lifestyle, mentalHealth, sleep
    }
}

public struct UserInteraction: Identifiable, Codable {
    public let id = UUID()
    public let type: InteractionType
    public let message: String?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public enum InteractionType: String, Codable, CaseIterable {
        case goalCompleted, recommendationFollowed, healthDataUpdated, struggling, question
    }
}

public struct CoachingResponse: Identifiable, Codable {
    public let id: UUID
    public let message: String
    public let recommendations: [HealthRecommendation]
    public let encouragement: String
    public let nextSteps: [String]
    public let timestamp: Date
}

public struct HealthGoal: Identifiable, Codable {
    public let id = UUID()
    public let type: HealthGoalType
    public let targetValue: Double
    public let timeframe: Timeframe
    public let description: String
    
    public enum HealthGoalType: String, Codable, CaseIterable {
        case weightLoss, cardiovascularHealth, sleepOptimization, stressReduction, generalWellness
    }
    
    public enum Timeframe: String, Codable, CaseIterable {
        case week, month, quarter, year
    }
}

public struct SessionMetrics: Codable {
    public let duration: TimeInterval
    public let recommendationsFollowed: Int
    public let goalProgress: Double
    public let engagementScore: Double
}

public struct ProgressMetrics: Codable {
    public var totalSessions: Int = 0
    public var totalDuration: TimeInterval = 0
    public var totalRecommendationsFollowed: Int = 0
    public var averageGoalProgress: Double = 0.0
}

public struct CoachingInsights: Codable {
    public let totalSessions: Int
    public let averageSessionDuration: TimeInterval
    public let mostCommonGoals: [HealthGoal.HealthGoalType]
    public let successRate: Double
    public let improvementAreas: [String]
    public let recommendations: [String]
}

public enum SessionStatus: String, Codable, CaseIterable {
    case active, paused, completed, abandoned
}

public enum CoachingError: Error {
    case noActiveSession
    case invalidGoal
    case recommendationGenerationFailed
    case sessionCreationFailed
}

// MARK: - Extensions

extension HKHealthStore {
    var healthDataPublisher: AnyPublisher<[HKQuantitySample], Never> {
        // Create a publisher for health data updates
        return Just([]).eraseToAnyPublisher()
    }
} 