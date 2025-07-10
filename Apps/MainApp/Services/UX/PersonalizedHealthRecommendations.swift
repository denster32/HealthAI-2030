import Foundation
import SwiftUI
import Combine

/// Personalized Health Recommendations System
/// Provides AI-driven health recommendations with adaptive learning and contextual insights
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class PersonalizedHealthRecommendations: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var currentRecommendations: [HealthRecommendation] = []
    @Published public private(set) var recommendationHistory: [HealthRecommendation] = []
    @Published public private(set) var userPreferences: UserPreferences = UserPreferences()
    @Published public private(set) var recommendationInsights: [RecommendationInsight] = []
    @Published public private(set) var isRecommendationsActive = false
    @Published public private(set) var lastError: String?
    @Published public private(set) var recommendationProgress: Double = 0.0
    
    // MARK: - Private Properties
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    private var cancellables = Set<AnyCancellable>()
    private let recommendationsQueue = DispatchQueue(label: "health.recommendations", qos: .userInitiated)
    
    // Recommendation data caches
    private var recommendationData: [String: RecommendationData] = [:]
    private var userProfileData: [String: UserProfileData] = [:]
    private var contextData: [String: ContextData] = [:]
    
    // Recommendation parameters
    private let recommendationUpdateInterval: TimeInterval = 1800.0 // 30 minutes
    private var lastRecommendationUpdate: Date = Date()
    
    // AI model parameters
    private var recommendationModel: RecommendationModel?
    private var userBehaviorModel: UserBehaviorModel?
    private var contextModel: ContextModel?
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        
        setupRecommendationsSystem()
        setupAIModels()
        setupPersonalizationEngine()
        initializeRecommendationsPlatform()
    }
    
    // MARK: - Public Methods
    
    /// Start recommendations system
    public func startRecommendationsSystem() async throws {
        isRecommendationsActive = true
        lastError = nil
        recommendationProgress = 0.0
        
        do {
            // Initialize recommendations platform
            try await initializeRecommendationsPlatform()
            
            // Start continuous recommendation tracking
            try await startContinuousRecommendationTracking()
            
            // Update recommendation status
            await updateRecommendationStatus()
            
            // Track recommendations start
            analyticsEngine.trackEvent("recommendations_system_started", properties: [
                "timestamp": Date().timeIntervalSince1970,
                "current_recommendations": currentRecommendations.count
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isRecommendationsActive = false
            }
            throw error
        }
    }
    
    /// Stop recommendations system
    public func stopRecommendationsSystem() async {
        await MainActor.run {
            self.isRecommendationsActive = false
        }
        
        // Track recommendations stop
        analyticsEngine.trackEvent("recommendations_system_stopped", properties: [
            "timestamp": Date().timeIntervalSince1970,
            "session_duration": Date().timeIntervalSince(lastRecommendationUpdate)
        ])
    }
    
    /// Generate personalized recommendations
    public func generateRecommendations(context: RecommendationContext? = nil) async throws {
        do {
            // Validate recommendation generation
            try await validateRecommendationGeneration(context: context)
            
            // Get user profile
            let userProfile = try await getUserProfile()
            
            // Get current context
            let currentContext = context ?? try await getCurrentContext()
            
            // Generate recommendations using AI
            let recommendations = try await generateAIRecommendations(
                userProfile: userProfile,
                context: currentContext
            )
            
            // Filter and rank recommendations
            let filteredRecommendations = try await filterAndRankRecommendations(
                recommendations: recommendations,
                userProfile: userProfile,
                context: currentContext
            )
            
            // Update current recommendations
            await MainActor.run {
                self.currentRecommendations = filteredRecommendations
            }
            
            // Track recommendation generation
            await trackRecommendationGeneration(recommendations: filteredRecommendations)
            
            // Generate insights
            await generateRecommendationInsights()
            
            // Update recommendation progress
            await updateRecommendationProgress()
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Update user preferences
    public func updateUserPreferences(_ preferences: UserPreferences) async throws {
        do {
            // Validate user preferences
            try await validateUserPreferences(preferences)
            
            // Update preferences
            await MainActor.run {
                self.userPreferences = preferences
            }
            
            // Update user profile
            try await updateUserProfile(preferences: preferences)
            
            // Regenerate recommendations
            try await generateRecommendations()
            
            // Track preference update
            await trackPreferenceUpdate(preferences: preferences)
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Provide feedback on recommendation
    public func provideFeedback(recommendationId: UUID, feedback: RecommendationFeedback) async throws {
        do {
            // Find recommendation
            guard let recommendation = currentRecommendations.first(where: { $0.id == recommendationId }) else {
                throw RecommendationError.recommendationNotFound(recommendationId.uuidString)
            }
            
            // Update recommendation with feedback
            try await updateRecommendationFeedback(recommendation: recommendation, feedback: feedback)
            
            // Update recommendation history
            await MainActor.run {
                if let index = self.currentRecommendations.firstIndex(where: { $0.id == recommendationId }) {
                    self.currentRecommendations[index].feedback = feedback
                    self.currentRecommendations[index].feedbackProvidedAt = Date()
                }
            }
            
            // Update AI models with feedback
            try await updateAIModelsWithFeedback(recommendation: recommendation, feedback: feedback)
            
            // Track feedback
            await trackRecommendationFeedback(recommendation: recommendation, feedback: feedback)
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get recommendation history
    public func getRecommendationHistory(limit: Int = 50) async -> [HealthRecommendation] {
        let history = recommendationHistory.suffix(limit)
        return Array(history)
    }
    
    /// Get recommendation analytics
    public func getRecommendationAnalytics() async -> RecommendationAnalytics {
        do {
            // Calculate recommendation metrics
            let metrics = try await calculateRecommendationMetrics()
            
            // Analyze recommendation patterns
            let patterns = try await analyzeRecommendationPatterns()
            
            // Generate insights
            let insights = try await generateRecommendationInsights(metrics: metrics, patterns: patterns)
            
            let analytics = RecommendationAnalytics(
                totalRecommendations: metrics.totalRecommendations,
                acceptedRecommendations: metrics.acceptedRecommendations,
                averageAcceptanceRate: metrics.averageAcceptanceRate,
                recommendationPatterns: patterns,
                insights: insights,
                timestamp: Date()
            )
            
            return analytics
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return RecommendationAnalytics()
        }
    }
    
    /// Get recommendation insights
    public func getRecommendationInsights() async -> [RecommendationInsight] {
        do {
            // Analyze recommendation patterns
            let patterns = try await analyzeRecommendationPatterns()
            
            // Generate insights
            let insights = try await generateInsightsFromPatterns(patterns: patterns)
            
            await MainActor.run {
                self.recommendationInsights = insights
            }
            
            return insights
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Export recommendations data
    public func exportRecommendationsData(format: ExportFormat = .json) async throws -> Data {
        do {
            let exportData = RecommendationsExportData(
                currentRecommendations: currentRecommendations,
                recommendationHistory: recommendationHistory,
                userPreferences: userPreferences,
                recommendationInsights: recommendationInsights,
                timestamp: Date()
            )
            
            switch format {
            case .json:
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                return try encoder.encode(exportData)
                
            case .csv:
                return try await exportToCSV(data: exportData)
                
            case .xml:
                return try await exportToXML(data: exportData)
            }
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupRecommendationsSystem() {
        // Setup recommendations system
        setupRecommendationGeneration()
        setupRecommendationTracking()
        setupRecommendationAnalytics()
        setupRecommendationOptimization()
    }
    
    private func setupAIModels() {
        // Setup AI models
        setupRecommendationModel()
        setupUserBehaviorModel()
        setupContextModel()
        setupModelTraining()
    }
    
    private func setupPersonalizationEngine() {
        // Setup personalization engine
        setupUserProfiling()
        setupContextAnalysis()
        setupPreferenceLearning()
        setupAdaptiveAlgorithms()
    }
    
    private func initializeRecommendationsPlatform() async throws {
        // Initialize recommendations platform
        try await loadRecommendationsData()
        try await setupRecommendationGeneration()
        try await initializeAIModels()
    }
    
    private func startContinuousRecommendationTracking() async throws {
        // Start continuous recommendation tracking
        try await startRecommendationUpdates()
        try await startAIModelUpdates()
        try await startPersonalizationUpdates()
    }
    
    private func validateRecommendationGeneration(context: RecommendationContext?) async throws {
        // Validate recommendation generation
        guard isRecommendationsActive else {
            throw RecommendationError.systemNotActive
        }
        
        // Check AI model availability
        guard recommendationModel != nil else {
            throw RecommendationError.modelNotAvailable
        }
    }
    
    private func validateUserPreferences(_ preferences: UserPreferences) async throws {
        // Validate user preferences
        guard preferences.isValid else {
            throw RecommendationError.invalidPreferences
        }
        
        // Check preference constraints
        let hasValidConstraints = await checkPreferenceConstraints(preferences)
        guard hasValidConstraints else {
            throw RecommendationError.invalidPreferenceConstraints
        }
    }
    
    private func trackRecommendationGeneration(recommendations: [HealthRecommendation]) async {
        // Track recommendation generation
        analyticsEngine.trackEvent("recommendations_generated", properties: [
            "recommendations_count": recommendations.count,
            "recommendation_types": recommendations.map { $0.type.rawValue },
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    private func trackPreferenceUpdate(preferences: UserPreferences) async {
        // Track preference update
        analyticsEngine.trackEvent("user_preferences_updated", properties: [
            "preferences_updated": true,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    private func trackRecommendationFeedback(recommendation: HealthRecommendation, feedback: RecommendationFeedback) async {
        // Track recommendation feedback
        analyticsEngine.trackEvent("recommendation_feedback_provided", properties: [
            "recommendation_id": recommendation.id.uuidString,
            "feedback_type": feedback.type.rawValue,
            "feedback_rating": feedback.rating,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    private func getUserProfile() async throws -> UserProfile {
        // Get user profile
        let profile = UserProfile(
            id: UUID(),
            userId: getCurrentUserId(),
            healthGoals: userPreferences.healthGoals,
            preferences: userPreferences,
            behaviorPatterns: await analyzeUserBehavior(),
            healthMetrics: await getHealthMetrics(),
            timestamp: Date()
        )
        
        return profile
    }
    
    private func getCurrentContext() async throws -> RecommendationContext {
        // Get current context
        let context = RecommendationContext(
            timeOfDay: getCurrentTimeOfDay(),
            location: await getCurrentLocation(),
            activity: await getCurrentActivity(),
            healthStatus: await getCurrentHealthStatus(),
            weather: await getCurrentWeather(),
            deviceType: getCurrentDeviceType(),
            timestamp: Date()
        )
        
        return context
    }
    
    private func generateAIRecommendations(userProfile: UserProfile, context: RecommendationContext) async throws -> [HealthRecommendation] {
        // Generate AI recommendations
        guard let model = recommendationModel else {
            throw RecommendationError.modelNotAvailable
        }
        
        let recommendations = try await model.generateRecommendations(
            userProfile: userProfile,
            context: context
        )
        
        return recommendations
    }
    
    private func filterAndRankRecommendations(recommendations: [HealthRecommendation], userProfile: UserProfile, context: RecommendationContext) async throws -> [HealthRecommendation] {
        // Filter and rank recommendations
        var filteredRecommendations = recommendations
        
        // Apply user preferences filter
        filteredRecommendations = filteredRecommendations.filter { recommendation in
            return recommendation.matchesUserPreferences(userPreferences)
        }
        
        // Apply context filter
        filteredRecommendations = filteredRecommendations.filter { recommendation in
            return recommendation.isRelevantForContext(context)
        }
        
        // Rank recommendations
        filteredRecommendations = try await rankRecommendations(
            recommendations: filteredRecommendations,
            userProfile: userProfile,
            context: context
        )
        
        // Limit to top recommendations
        let maxRecommendations = 10
        filteredRecommendations = Array(filteredRecommendations.prefix(maxRecommendations))
        
        return filteredRecommendations
    }
    
    private func generateRecommendationInsights() async {
        // Generate recommendation insights
        let analytics = await getRecommendationAnalytics()
        let insights = analytics.insights
        
        // Track insights
        for insight in insights {
            analyticsEngine.trackEvent("recommendation_insight_generated", properties: [
                "insight_id": insight.id.uuidString,
                "insight_type": insight.type.rawValue,
                "insight_priority": insight.priority.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
        }
    }
    
    private func updateRecommendationProgress() async {
        // Update recommendation progress
        let progress = await calculateRecommendationProgress()
        await MainActor.run {
            self.recommendationProgress = progress
        }
    }
    
    private func updateUserProfile(preferences: UserPreferences) async throws {
        // Update user profile
        let userProfile = try await getUserProfile()
        
        // Update profile data
        await updateProfileData(profile: userProfile)
    }
    
    private func updateRecommendationFeedback(recommendation: HealthRecommendation, feedback: RecommendationFeedback) async throws {
        // Update recommendation feedback
        var updatedRecommendation = recommendation
        updatedRecommendation.feedback = feedback
        updatedRecommendation.feedbackProvidedAt = Date()
        
        // Update in history
        await MainActor.run {
            self.recommendationHistory.append(updatedRecommendation)
        }
    }
    
    private func updateAIModelsWithFeedback(recommendation: HealthRecommendation, feedback: RecommendationFeedback) async throws {
        // Update AI models with feedback
        guard let model = recommendationModel else {
            throw RecommendationError.modelNotAvailable
        }
        
        try await model.updateWithFeedback(
            recommendation: recommendation,
            feedback: feedback
        )
    }
    
    private func calculateRecommendationMetrics() async throws -> RecommendationMetrics {
        // Calculate recommendation metrics
        let totalRecommendations = recommendationHistory.count
        let acceptedRecommendations = recommendationHistory.filter { $0.feedback?.type == .accepted }.count
        let averageAcceptanceRate = totalRecommendations > 0 ? Double(acceptedRecommendations) / Double(totalRecommendations) : 0.0
        
        return RecommendationMetrics(
            totalRecommendations: totalRecommendations,
            acceptedRecommendations: acceptedRecommendations,
            averageAcceptanceRate: averageAcceptanceRate,
            timestamp: Date()
        )
    }
    
    private func analyzeRecommendationPatterns() async throws -> RecommendationPatterns {
        // Analyze recommendation patterns
        let patterns = await analyzeAcceptancePatterns()
        let trends = await analyzeTrendPatterns()
        
        return RecommendationPatterns(
            patterns: patterns,
            trends: trends,
            timestamp: Date()
        )
    }
    
    private func generateRecommendationInsights(metrics: RecommendationMetrics, patterns: RecommendationPatterns) async throws -> [RecommendationInsight] {
        // Generate recommendation insights
        var insights: [RecommendationInsight] = []
        
        // High acceptance rate insight
        if metrics.averageAcceptanceRate > 0.8 {
            insights.append(RecommendationInsight(
                id: UUID(),
                title: "Great Match",
                description: "You accept \(Int(metrics.averageAcceptanceRate * 100))% of recommendations!",
                type: .acceptance,
                priority: .high,
                timestamp: Date()
            ))
        }
        
        // Pattern insight
        if let pattern = patterns.patterns.first {
            insights.append(RecommendationInsight(
                id: UUID(),
                title: "Recommendation Pattern",
                description: "You tend to \(pattern.pattern) recommendations",
                type: .pattern,
                priority: .medium,
                timestamp: Date()
            ))
        }
        
        return insights
    }
    
    private func generateInsightsFromPatterns(patterns: RecommendationPatterns) async throws -> [RecommendationInsight] {
        // Generate insights from patterns
        var insights: [RecommendationInsight] = []
        
        // Trend insight
        if let trend = patterns.trends.currentTrend {
            insights.append(RecommendationInsight(
                id: UUID(),
                title: "Recommendation Trend",
                description: "Your acceptance rate is \(trend)",
                type: .trend,
                priority: .medium,
                timestamp: Date()
            ))
        }
        
        return insights
    }
    
    private func updateRecommendationStatus() async {
        // Update recommendation status
        lastRecommendationUpdate = Date()
    }
    
    private func loadRecommendationsData() async throws {
        // Load recommendations data
        try await loadRecommendationData()
        try await loadUserProfileData()
        try await loadContextData()
    }
    
    private func setupRecommendationGeneration() async throws {
        // Setup recommendation generation
        try await setupRecommendationAlgorithms()
        try await setupRecommendationValidation()
        try await setupRecommendationAnalytics()
    }
    
    private func initializeAIModels() async throws {
        // Initialize AI models
        try await setupRecommendationModel()
        try await setupUserBehaviorModel()
        try await setupContextModel()
    }
    
    private func startRecommendationUpdates() async throws {
        // Start recommendation updates
        try await startRecommendationTracking()
        try await startRecommendationAnalytics()
        try await startRecommendationOptimization()
    }
    
    private func startAIModelUpdates() async throws {
        // Start AI model updates
        try await startModelTraining()
        try await startModelValidation()
        try await startModelOptimization()
    }
    
    private func startPersonalizationUpdates() async throws {
        // Start personalization updates
        try await startUserProfiling()
        try await startContextAnalysis()
        try await startPreferenceLearning()
    }
    
    private func checkPreferenceConstraints(_ preferences: UserPreferences) async -> Bool {
        // Check preference constraints
        return true // Placeholder
    }
    
    private func analyzeUserBehavior() async -> [BehaviorPattern] {
        // Analyze user behavior
        return []
    }
    
    private func getHealthMetrics() async -> [HealthMetric] {
        // Get health metrics
        return []
    }
    
    private func getCurrentTimeOfDay() -> TimeOfDay {
        // Get current time of day
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
    
    private func getCurrentLocation() async -> Location? {
        // Get current location
        return nil // Placeholder
    }
    
    private func getCurrentActivity() async -> Activity? {
        // Get current activity
        return nil // Placeholder
    }
    
    private func getCurrentHealthStatus() async -> HealthStatus {
        // Get current health status
        return .normal // Placeholder
    }
    
    private func getCurrentWeather() async -> Weather? {
        // Get current weather
        return nil // Placeholder
    }
    
    private func getCurrentDeviceType() -> DeviceType {
        // Get current device type
        return .iPhone // Placeholder
    }
    
    private func getCurrentUserId() -> UUID {
        // Get current user ID
        return UUID() // Placeholder
    }
    
    private func rankRecommendations(recommendations: [HealthRecommendation], userProfile: UserProfile, context: RecommendationContext) async throws -> [HealthRecommendation] {
        // Rank recommendations
        return recommendations.sorted { $0.priority > $1.priority }
    }
    
    private func calculateRecommendationProgress() async -> Double {
        // Calculate recommendation progress
        let totalRecommendations = currentRecommendations.count
        let acceptedRecommendations = currentRecommendations.filter { $0.feedback?.type == .accepted }.count
        
        return totalRecommendations > 0 ? Double(acceptedRecommendations) / Double(totalRecommendations) : 0.0
    }
    
    private func updateProfileData(profile: UserProfile) async {
        // Update profile data
    }
    
    private func analyzeAcceptancePatterns() async throws -> [AcceptancePattern] {
        // Analyze acceptance patterns
        return []
    }
    
    private func analyzeTrendPatterns() async throws -> RecommendationTrends {
        // Analyze trend patterns
        return RecommendationTrends(
            currentTrend: "stable",
            acceptanceRate: 0.0,
            timestamp: Date()
        )
    }
    
    private func loadRecommendationData() async throws {
        // Load recommendation data
    }
    
    private func loadUserProfileData() async throws {
        // Load user profile data
    }
    
    private func loadContextData() async throws {
        // Load context data
    }
    
    private func setupRecommendationAlgorithms() async throws {
        // Setup recommendation algorithms
    }
    
    private func setupRecommendationValidation() async throws {
        // Setup recommendation validation
    }
    
    private func setupRecommendationAnalytics() async throws {
        // Setup recommendation analytics
    }
    
    private func setupRecommendationModel() async throws {
        // Setup recommendation model
    }
    
    private func setupUserBehaviorModel() async throws {
        // Setup user behavior model
    }
    
    private func setupContextModel() async throws {
        // Setup context model
    }
    
    private func startRecommendationTracking() async throws {
        // Start recommendation tracking
    }
    
    private func startRecommendationAnalytics() async throws {
        // Start recommendation analytics
    }
    
    private func startRecommendationOptimization() async throws {
        // Start recommendation optimization
    }
    
    private func startModelTraining() async throws {
        // Start model training
    }
    
    private func startModelValidation() async throws {
        // Start model validation
    }
    
    private func startModelOptimization() async throws {
        // Start model optimization
    }
    
    private func startUserProfiling() async throws {
        // Start user profiling
    }
    
    private func startContextAnalysis() async throws {
        // Start context analysis
    }
    
    private func startPreferenceLearning() async throws {
        // Start preference learning
    }
    
    private func exportToCSV(data: RecommendationsExportData) async throws -> Data {
        // Export to CSV
        return Data()
    }
    
    private func exportToXML(data: RecommendationsExportData) async throws -> Data {
        // Export to XML
        return Data()
    }
}

// MARK: - Data Models

public struct HealthRecommendation: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: RecommendationType
    public let category: RecommendationCategory
    public let priority: Double
    public let confidence: Double
    public let actionItems: [ActionItem]
    public let expectedOutcome: String
    public let timeToImplement: TimeInterval
    public let difficulty: RecommendationDifficulty
    public let tags: [String]
    public let createdAt: Date
    public var feedback: RecommendationFeedback?
    public var feedbackProvidedAt: Date?
    
    func matchesUserPreferences(_ preferences: UserPreferences) -> Bool {
        // Check if recommendation matches user preferences
        return preferences.healthGoals.contains { goal in
            return tags.contains(goal.rawValue)
        }
    }
    
    func isRelevantForContext(_ context: RecommendationContext) -> Bool {
        // Check if recommendation is relevant for current context
        return true // Placeholder
    }
}

public struct UserPreferences: Codable {
    public var healthGoals: [HealthGoal]
    public var preferredActivities: [ActivityType]
    public var timePreferences: [TimeOfDay]
    public var difficultyPreferences: [RecommendationDifficulty]
    public var notificationPreferences: NotificationPreferences
    public var privacySettings: PrivacySettings
    
    var isValid: Bool {
        return !healthGoals.isEmpty
    }
}

public struct RecommendationContext: Codable {
    public let timeOfDay: TimeOfDay
    public let location: Location?
    public let activity: Activity?
    public let healthStatus: HealthStatus
    public let weather: Weather?
    public let deviceType: DeviceType
    public let timestamp: Date
}

public struct RecommendationFeedback: Codable {
    public let type: FeedbackType
    public let rating: Int
    public let comment: String?
    public let timestamp: Date
}

public struct RecommendationInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: InsightType
    public let priority: InsightPriority
    public let timestamp: Date
}

public struct RecommendationsExportData: Codable {
    public let currentRecommendations: [HealthRecommendation]
    public let recommendationHistory: [HealthRecommendation]
    public let userPreferences: UserPreferences
    public let recommendationInsights: [RecommendationInsight]
    public let timestamp: Date
}

public struct UserProfile: Codable {
    public let id: UUID
    public let userId: UUID
    public let healthGoals: [HealthGoal]
    public let preferences: UserPreferences
    public let behaviorPatterns: [BehaviorPattern]
    public let healthMetrics: [HealthMetric]
    public let timestamp: Date
}

public struct ActionItem: Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let estimatedTime: TimeInterval
    public let difficulty: RecommendationDifficulty
    public let resources: [String]
}

public struct BehaviorPattern: Codable {
    public let pattern: String
    public let frequency: Double
    public let confidence: Double
    public let timestamp: Date
}

public struct HealthMetric: Codable {
    public let type: MetricType
    public let value: Double
    public let unit: String
    public let timestamp: Date
}

public struct Location: Codable {
    public let latitude: Double
    public let longitude: Double
    public let name: String?
}

public struct Activity: Codable {
    public let type: ActivityType
    public let intensity: ActivityIntensity
    public let duration: TimeInterval
}

public struct Weather: Codable {
    public let temperature: Double
    public let condition: WeatherCondition
    public let humidity: Double
}

public struct NotificationPreferences: Codable {
    public let enabled: Bool
    public let frequency: NotificationFrequency
    public let quietHours: QuietHours
}

public struct PrivacySettings: Codable {
    public let dataSharing: DataSharingLevel
    public let analytics: Bool
    public let personalization: Bool
}

public struct RecommendationAnalytics: Codable {
    public let totalRecommendations: Int
    public let acceptedRecommendations: Int
    public let averageAcceptanceRate: Double
    public let recommendationPatterns: RecommendationPatterns
    public let insights: [RecommendationInsight]
    public let timestamp: Date
    
    public init() {
        self.totalRecommendations = 0
        self.acceptedRecommendations = 0
        self.averageAcceptanceRate = 0.0
        self.recommendationPatterns = RecommendationPatterns()
        self.insights = []
        self.timestamp = Date()
    }
}

public struct RecommendationMetrics: Codable {
    public let totalRecommendations: Int
    public let acceptedRecommendations: Int
    public let averageAcceptanceRate: Double
    public let timestamp: Date
}

public struct RecommendationPatterns: Codable {
    public let patterns: [AcceptancePattern]
    public let trends: RecommendationTrends
    public let timestamp: Date
    
    public init() {
        self.patterns = []
        self.trends = RecommendationTrends()
        self.timestamp = Date()
    }
}

public struct AcceptancePattern: Codable {
    public let pattern: String
    public let frequency: Double
    public let confidence: Double
    public let timestamp: Date
}

public struct RecommendationTrends: Codable {
    public let currentTrend: String
    public let acceptanceRate: Double
    public let timestamp: Date
    
    public init() {
        self.currentTrend = "stable"
        self.acceptanceRate = 0.0
        self.timestamp = Date()
    }
}

public enum RecommendationType: String, Codable {
    case fitness = "fitness"
    case nutrition = "nutrition"
    case sleep = "sleep"
    case mindfulness = "mindfulness"
    case health = "health"
    case lifestyle = "lifestyle"
}

public enum RecommendationCategory: String, Codable {
    case exercise = "exercise"
    case diet = "diet"
    case sleep = "sleep"
    case stress = "stress"
    case prevention = "prevention"
    case treatment = "treatment"
}

public enum RecommendationDifficulty: String, Codable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
}

public enum HealthGoal: String, Codable {
    case weightLoss = "weight_loss"
    case muscleGain = "muscle_gain"
    case betterSleep = "better_sleep"
    case stressReduction = "stress_reduction"
    case heartHealth = "heart_health"
    case mentalHealth = "mental_health"
}

public enum ActivityType: String, Codable {
    case running = "running"
    case walking = "walking"
    case cycling = "cycling"
    case swimming = "swimming"
    case yoga = "yoga"
    case meditation = "meditation"
}

public enum ActivityIntensity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case extreme = "extreme"
}

public enum TimeOfDay: String, Codable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
}

public enum HealthStatus: String, Codable {
    case critical = "critical"
    case poor = "poor"
    case normal = "normal"
    case good = "good"
    case excellent = "excellent"
}

public enum DeviceType: String, Codable {
    case iPhone = "iphone"
    case iPad = "ipad"
    case mac = "mac"
    case watch = "watch"
    case tv = "tv"
}

public enum WeatherCondition: String, Codable {
    case sunny = "sunny"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case snowy = "snowy"
    case windy = "windy"
}

public enum NotificationFrequency: String, Codable {
    case immediate = "immediate"
    case hourly = "hourly"
    case daily = "daily"
    case weekly = "weekly"
}

public enum DataSharingLevel: String, Codable {
    case none = "none"
    case minimal = "minimal"
    case standard = "standard"
    case comprehensive = "comprehensive"
}

public enum FeedbackType: String, Codable {
    case accepted = "accepted"
    case declined = "declined"
    case implemented = "implemented"
    case notRelevant = "not_relevant"
}

public enum InsightType: String, Codable {
    case acceptance = "acceptance"
    case pattern = "pattern"
    case trend = "trend"
    case improvement = "improvement"
}

public enum InsightPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

public enum MetricType: String, Codable {
    case steps = "steps"
    case heartRate = "heart_rate"
    case sleep = "sleep"
    case weight = "weight"
    case calories = "calories"
}

public enum ExportFormat: String, Codable {
    case json = "json"
    case csv = "csv"
    case xml = "xml"
}

public enum RecommendationError: Error, LocalizedError {
    case systemNotActive
    case modelNotAvailable
    case recommendationNotFound(String)
    case invalidPreferences
    case invalidPreferenceConstraints
    
    public var errorDescription: String? {
        switch self {
        case .systemNotActive:
            return "Recommendations system is not active"
        case .modelNotAvailable:
            return "AI recommendation model is not available"
        case .recommendationNotFound(let id):
            return "Recommendation not found: \(id)"
        case .invalidPreferences:
            return "Invalid user preferences"
        case .invalidPreferenceConstraints:
            return "Invalid preference constraints"
        }
    }
}

// MARK: - Supporting Structures

public struct RecommendationData: Codable {
    public let recommendations: [HealthRecommendation]
    public let analytics: RecommendationAnalytics
}

public struct UserProfileData: Codable {
    public let profiles: [UserProfile]
    public let analytics: UserProfileAnalytics
}

public struct ContextData: Codable {
    public let contexts: [RecommendationContext]
    public let analytics: ContextAnalytics
}

public struct UserProfileAnalytics: Codable {
    public let totalProfiles: Int
    public let averagePreferences: Double
    public let mostCommonGoals: [HealthGoal]
}

public struct ContextAnalytics: Codable {
    public let totalContexts: Int
    public let averageRelevance: Double
    public let mostRelevantContexts: [String]
}

public struct QuietHours: Codable {
    public let startTime: Date
    public let endTime: Date
    public let enabled: Bool
}

// MARK: - AI Model Protocols

public protocol RecommendationModel {
    func generateRecommendations(userProfile: UserProfile, context: RecommendationContext) async throws -> [HealthRecommendation]
    func updateWithFeedback(recommendation: HealthRecommendation, feedback: RecommendationFeedback) async throws
}

public protocol UserBehaviorModel {
    func analyzeBehavior(patterns: [BehaviorPattern]) async throws -> [BehaviorInsight]
    func predictBehavior(context: RecommendationContext) async throws -> BehaviorPrediction
}

public protocol ContextModel {
    func analyzeContext(context: RecommendationContext) async throws -> ContextAnalysis
    func predictOptimalContext() async throws -> RecommendationContext
}

public struct BehaviorInsight: Codable {
    public let insight: String
    public let confidence: Double
    public let timestamp: Date
}

public struct BehaviorPrediction: Codable {
    public let prediction: String
    public let probability: Double
    public let timestamp: Date
}

public struct ContextAnalysis: Codable {
    public let analysis: String
    public let relevance: Double
    public let timestamp: Date
} 