import Foundation
import CoreML
import HealthKit
import SwiftUI

/// Personalized Recommendation Engine for Health Coaching
@available(iOS 17.0, *)
public class PersonalizedRecommendationEngine: ObservableObject {
    // MARK: - Published Properties
    @Published public var recommendations: [HealthRecommendation] = []
    @Published public var activeGoals: [HealthGoal] = []
    @Published public var abTestGroup: ABTestGroup = .control
    
    // MARK: - Private Properties
    private let userProfileManager = UserProfileManager()
    private let evidenceDatabase = EvidenceBasedInterventionDatabase()
    private let abTestManager = ABTestManager()
    private let recommendationHistory: [HealthRecommendation] = []
    
    // MARK: - Public Methods
    /// Generate personalized recommendations for the user
    public func generateRecommendations(for context: RecommendationContext) async -> [HealthRecommendation] {
        let profile = userProfileManager.getCurrentUserProfile()
        let collaborative = collaborativeFilteringRecommendations(for: profile)
        let contentBased = contentBasedRecommendations(for: profile, context: context)
        let temporal = temporalPatternRecommendations(for: profile)
        let evidence = evidenceDatabase.getEvidenceBasedRecommendations(for: profile)
        let abGroup = abTestManager.getCurrentGroup()
        abTestGroup = abGroup
        
        // Combine and deduplicate recommendations
        var all = collaborative + contentBased + temporal + evidence
        all = Array(Set(all))
        // Optionally, filter or sort based on A/B group
        if abGroup == .variant {
            all.shuffle()
        }
        recommendations = all
        return all
    }
    
    /// Track a new health goal
    public func addGoal(_ goal: HealthGoal) {
        activeGoals.append(goal)
    }
    
    /// Mark a goal as completed
    public func completeGoal(_ goal: HealthGoal) {
        if let idx = activeGoals.firstIndex(of: goal) {
            activeGoals[idx].isCompleted = true
        }
    }
    
    // MARK: - Private Recommendation Methods
    private func collaborativeFilteringRecommendations(for profile: UserProfile) -> [HealthRecommendation] {
        // Placeholder: Recommend what similar users found helpful
        return [HealthRecommendation(id: UUID(), title: "Try a 10-minute walk after lunch", type: .lifestyle, evidenceLevel: .moderate)]
    }
    
    private func contentBasedRecommendations(for profile: UserProfile, context: RecommendationContext) -> [HealthRecommendation] {
        // Placeholder: Recommend based on user's health conditions and preferences
        if profile.conditions.contains(.hypertension) {
            return [HealthRecommendation(id: UUID(), title: "Reduce sodium intake to <2g/day", type: .conditionSpecific, evidenceLevel: .high)]
        }
        return []
    }
    
    private func temporalPatternRecommendations(for profile: UserProfile) -> [HealthRecommendation] {
        // Placeholder: Recommend based on time-of-day or weekly patterns
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 21 {
            return [HealthRecommendation(id: UUID(), title: "Wind down with a mindfulness exercise before bed", type: .lifestyle, evidenceLevel: .moderate)]
        }
        return []
    }
}

// MARK: - Supporting Types

@available(iOS 17.0, *)
public struct HealthRecommendation: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let type: RecommendationType
    public let evidenceLevel: EvidenceLevel
    
    public enum RecommendationType: String {
        case lifestyle, conditionSpecific, behavioral, goal, intervention
    }
    public enum EvidenceLevel: String {
        case high, moderate, low
    }
}

@available(iOS 17.0, *)
public struct HealthGoal: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public var isCompleted: Bool
}

@available(iOS 17.0, *)
public struct RecommendationContext {
    public let recentActivity: String?
    public let recentSymptoms: [String]?
    public let timeOfDay: String?
}

@available(iOS 17.0, *)
public struct UserProfile {
    public let id: UUID
    public let conditions: [HealthCondition]
    public let preferences: [String]
}

@available(iOS 17.0, *)
public enum HealthCondition: String, Hashable {
    case hypertension, diabetes, obesity, insomnia, depression, anxiety
}

@available(iOS 17.0, *)
public class UserProfileManager {
    public func getCurrentUserProfile() -> UserProfile {
        // Placeholder: Return a sample profile
        return UserProfile(id: UUID(), conditions: [.hypertension], preferences: ["low sodium", "walking"])
    }
}

@available(iOS 17.0, *)
public class EvidenceBasedInterventionDatabase {
    public func getEvidenceBasedRecommendations(for profile: UserProfile) -> [HealthRecommendation] {
        // Placeholder: Return evidence-based recommendations
        return [HealthRecommendation(id: UUID(), title: "Monitor blood pressure daily", type: .conditionSpecific, evidenceLevel: .high)]
    }
}

@available(iOS 17.0, *)
public enum ABTestGroup: String {
    case control, variant
}

@available(iOS 17.0, *)
public class ABTestManager {
    public func getCurrentGroup() -> ABTestGroup {
        // Placeholder: Randomly assign group
        return Bool.random() ? .control : .variant
    }
}

// MARK: - Core Recommendation Engine

/// Comprehensive personalized recommendation engine for health coaching
/// Implements collaborative filtering, content-based filtering, and hybrid approaches
@MainActor
class PersonalizedRecommendationEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentRecommendations: [HealthRecommendation] = []
    @Published var recommendationHistory: [HealthRecommendation] = []
    @Published var userPreferences: UserHealthPreferences = UserHealthPreferences()
    @Published var isGeneratingRecommendations: Bool = false
    
    // MARK: - Private Properties
    
    private let healthKitManager: HealthKitManager
    private let mlPredictor: HealthPredictor
    private let userProfileManager: UserProfileManager
    private let recommendationCache: NSCache<NSString, [HealthRecommendation]> = NSCache()
    private let abTestManager: ABTestManager
    private let evidenceDatabase: EvidenceBasedInterventionDatabase
    
    // MARK: - Initialization
    
    init(healthKitManager: HealthKitManager, 
         mlPredictor: HealthPredictor,
         userProfileManager: UserProfileManager) {
        self.healthKitManager = healthKitManager
        self.mlPredictor = mlPredictor
        self.userProfileManager = userProfileManager
        self.abTestManager = ABTestManager()
        self.evidenceDatabase = EvidenceBasedInterventionDatabase()
        
        setupRecommendationEngine()
    }
    
    // MARK: - Public Methods
    
    /// Generate personalized health recommendations based on current data
    func generateRecommendations() async throws {
        isGeneratingRecommendations = true
        defer { isGeneratingRecommendations = false }
        
        // Clear cache for fresh recommendations
        recommendationCache.removeAllObjects()
        
        // Gather current health data
        let healthData = try await gatherCurrentHealthData()
        
        // Generate recommendations using multiple approaches
        let collaborativeRecommendations = try await generateCollaborativeRecommendations(healthData: healthData)
        let contentBasedRecommendations = try await generateContentBasedRecommendations(healthData: healthData)
        let temporalRecommendations = try await generateTemporalRecommendations(healthData: healthData)
        let evidenceBasedRecommendations = try await generateEvidenceBasedRecommendations(healthData: healthData)
        
        // Combine and rank recommendations
        let allRecommendations = collaborativeRecommendations + 
                                contentBasedRecommendations + 
                                temporalRecommendations + 
                                evidenceBasedRecommendations
        
        let rankedRecommendations = rankRecommendations(allRecommendations, healthData: healthData)
        
        // Apply A/B testing
        let testedRecommendations = abTestManager.applyABTesting(to: rankedRecommendations)
        
        // Update current recommendations
        currentRecommendations = testedRecommendations
        recommendationHistory.append(contentsOf: testedRecommendations)
        
        // Cache recommendations
        cacheRecommendations(testedRecommendations, for: healthData.userId)
    }
    
    /// Get recommendations for specific health condition
    func getRecommendationsForCondition(_ condition: HealthCondition) async throws -> [HealthRecommendation] {
        let conditionKey = "condition_\(condition.rawValue)" as NSString
        
        if let cached = recommendationCache.object(forKey: conditionKey) {
            return cached
        }
        
        let recommendations = try await evidenceDatabase.getInterventionsForCondition(condition)
        let personalizedRecommendations = personalizeRecommendations(recommendations, for: condition)
        
        recommendationCache.setObject(personalizedRecommendations, forKey: conditionKey)
        return personalizedRecommendations
    }
    
    /// Update user preferences and regenerate recommendations
    func updateUserPreferences(_ preferences: UserHealthPreferences) async throws {
        userPreferences = preferences
        try await generateRecommendations()
    }
    
    /// Track recommendation engagement
    func trackRecommendationEngagement(_ recommendation: HealthRecommendation, action: RecommendationAction) {
        recommendation.engagementMetrics.recordAction(action)
        abTestManager.trackEngagement(for: recommendation, action: action)
    }
    
    // MARK: - Private Methods
    
    private func setupRecommendationEngine() {
        // Configure cache
        recommendationCache.countLimit = 100
        recommendationCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Load user preferences
        Task {
            userPreferences = await userProfileManager.loadUserPreferences()
        }
    }
    
    private func gatherCurrentHealthData() async throws -> HealthDataSnapshot {
        let userId = userProfileManager.currentUser?.id ?? UUID().uuidString
        
        // Gather comprehensive health data
        let sleepData = try await healthKitManager.getSleepData(for: Date().addingTimeInterval(-7*24*3600), to: Date())
        let activityData = try await healthKitManager.getActivityData(for: Date().addingTimeInterval(-7*24*3600), to: Date())
        let heartRateData = try await healthKitManager.getHeartRateData(for: Date().addingTimeInterval(-24*3600), to: Date())
        let nutritionData = try await healthKitManager.getNutritionData(for: Date().addingTimeInterval(-7*24*3600), to: Date())
        let mindfulnessData = try await healthKitManager.getMindfulnessData(for: Date().addingTimeInterval(-7*24*3600), to: Date())
        
        return HealthDataSnapshot(
            userId: userId,
            sleepData: sleepData,
            activityData: activityData,
            heartRateData: heartRateData,
            nutritionData: nutritionData,
            mindfulnessData: mindfulnessData,
            timestamp: Date()
        )
    }
    
    private func generateCollaborativeRecommendations(healthData: HealthDataSnapshot) async throws -> [HealthRecommendation] {
        // Simulate collaborative filtering based on similar user profiles
        let similarUsers = try await findSimilarUsers(healthData: healthData)
        let collaborativeRecommendations = similarUsers.flatMap { user in
            user.successfulRecommendations
        }
        
        return collaborativeRecommendations
    }
    
    private func generateContentBasedRecommendations(healthData: HealthDataSnapshot) async throws -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // Analyze sleep patterns
        if let sleepRecommendation = analyzeSleepPatterns(healthData.sleepData) {
            recommendations.append(sleepRecommendation)
        }
        
        // Analyze activity patterns
        if let activityRecommendation = analyzeActivityPatterns(healthData.activityData) {
            recommendations.append(activityRecommendation)
        }
        
        // Analyze heart rate patterns
        if let heartRateRecommendation = analyzeHeartRatePatterns(healthData.heartRateData) {
            recommendations.append(heartRateRecommendation)
        }
        
        // Analyze nutrition patterns
        if let nutritionRecommendation = analyzeNutritionPatterns(healthData.nutritionData) {
            recommendations.append(nutritionRecommendation)
        }
        
        return recommendations
    }
    
    private func generateTemporalRecommendations(healthData: HealthDataSnapshot) async throws -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // Time-based recommendations
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Morning recommendations (6-10 AM)
        if currentHour >= 6 && currentHour <= 10 {
            recommendations.append(HealthRecommendation(
                id: UUID(),
                title: "Morning Energy Boost",
                description: "Start your day with a 10-minute morning walk to boost energy and metabolism",
                category: .activity,
                priority: .high,
                timeOfDay: .morning,
                evidenceLevel: .strong,
                personalizationFactors: ["morning_routine", "energy_levels"],
                estimatedImpact: .moderate,
                timeToImplement: 10,
                frequency: .daily
            ))
        }
        
        // Afternoon recommendations (2-4 PM)
        if currentHour >= 14 && currentHour <= 16 {
            recommendations.append(HealthRecommendation(
                id: UUID(),
                title: "Afternoon Mindfulness Break",
                description: "Take a 5-minute mindfulness break to reduce stress and improve focus",
                category: .mindfulness,
                priority: .medium,
                timeOfDay: .afternoon,
                evidenceLevel: .moderate,
                personalizationFactors: ["stress_levels", "productivity"],
                estimatedImpact: .moderate,
                timeToImplement: 5,
                frequency: .daily
            ))
        }
        
        // Evening recommendations (8-10 PM)
        if currentHour >= 20 && currentHour <= 22 {
            recommendations.append(HealthRecommendation(
                id: UUID(),
                title: "Evening Wind-Down Routine",
                description: "Prepare for better sleep with a 15-minute wind-down routine",
                category: .sleep,
                priority: .high,
                timeOfDay: .evening,
                evidenceLevel: .strong,
                personalizationFactors: ["sleep_quality", "evening_habits"],
                estimatedImpact: .high,
                timeToImplement: 15,
                frequency: .daily
            ))
        }
        
        return recommendations
    }
    
    private func generateEvidenceBasedRecommendations(healthData: HealthDataSnapshot) async throws -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // Get evidence-based interventions for current health state
        let interventions = try await evidenceDatabase.getInterventionsForHealthData(healthData)
        
        for intervention in interventions {
            let recommendation = HealthRecommendation(
                id: UUID(),
                title: intervention.title,
                description: intervention.description,
                category: intervention.category,
                priority: intervention.priority,
                timeOfDay: intervention.timeOfDay,
                evidenceLevel: intervention.evidenceLevel,
                personalizationFactors: intervention.personalizationFactors,
                estimatedImpact: intervention.estimatedImpact,
                timeToImplement: intervention.timeToImplement,
                frequency: intervention.frequency
            )
            recommendations.append(recommendation)
        }
        
        return recommendations
    }
    
    private func rankRecommendations(_ recommendations: [HealthRecommendation], healthData: HealthDataSnapshot) -> [HealthRecommendation] {
        return recommendations.sorted { rec1, rec2 in
            let score1 = calculateRecommendationScore(rec1, healthData: healthData)
            let score2 = calculateRecommendationScore(rec2, healthData: healthData)
            return score1 > score2
        }
    }
    
    private func calculateRecommendationScore(_ recommendation: HealthRecommendation, healthData: HealthDataSnapshot) -> Double {
        var score: Double = 0.0
        
        // Base score from evidence level
        switch recommendation.evidenceLevel {
        case .strong: score += 10.0
        case .moderate: score += 7.0
        case .weak: score += 4.0
        case .anecdotal: score += 2.0
        }
        
        // Priority multiplier
        switch recommendation.priority {
        case .critical: score *= 2.0
        case .high: score *= 1.5
        case .medium: score *= 1.0
        case .low: score *= 0.7
        }
        
        // Personalization bonus
        let personalizationMatch = calculatePersonalizationMatch(recommendation, healthData: healthData)
        score += personalizationMatch * 5.0
        
        // Time relevance bonus
        let timeRelevance = calculateTimeRelevance(recommendation)
        score += timeRelevance * 3.0
        
        // User preference alignment
        let preferenceAlignment = calculatePreferenceAlignment(recommendation)
        score += preferenceAlignment * 4.0
        
        return score
    }
    
    private func calculatePersonalizationMatch(_ recommendation: HealthRecommendation, healthData: HealthDataSnapshot) -> Double {
        var matchScore: Double = 0.0
        
        for factor in recommendation.personalizationFactors {
            switch factor {
            case "sleep_quality":
                if let avgSleepQuality = healthData.sleepData.averageQuality {
                    matchScore += avgSleepQuality < 7.0 ? 1.0 : 0.0
                }
            case "stress_levels":
                if let avgHeartRate = healthData.heartRateData.averageHeartRate {
                    matchScore += avgHeartRate > 80 ? 1.0 : 0.0
                }
            case "activity_levels":
                if let avgSteps = healthData.activityData.averageSteps {
                    matchScore += avgSteps < 8000 ? 1.0 : 0.0
                }
            default:
                matchScore += 0.5 // Default partial match
            }
        }
        
        return min(matchScore / Double(recommendation.personalizationFactors.count), 1.0)
    }
    
    private func calculateTimeRelevance(_ recommendation: HealthRecommendation) -> Double {
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        switch recommendation.timeOfDay {
        case .morning:
            return currentHour >= 6 && currentHour <= 10 ? 1.0 : 0.0
        case .afternoon:
            return currentHour >= 12 && currentHour <= 16 ? 1.0 : 0.0
        case .evening:
            return currentHour >= 18 && currentHour <= 22 ? 1.0 : 0.0
        case .anytime:
            return 0.5
        }
    }
    
    private func calculatePreferenceAlignment(_ recommendation: HealthRecommendation) -> Double {
        var alignment: Double = 0.0
        
        // Check if user prefers this category
        if userPreferences.preferredCategories.contains(recommendation.category) {
            alignment += 1.0
        }
        
        // Check time preference
        if userPreferences.preferredTimeOfDay == recommendation.timeOfDay {
            alignment += 1.0
        }
        
        // Check duration preference
        if recommendation.timeToImplement <= userPreferences.maxTimePerRecommendation {
            alignment += 1.0
        }
        
        return alignment / 3.0
    }
    
    private func findSimilarUsers(healthData: HealthDataSnapshot) async throws -> [SimilarUser] {
        // Simulate finding similar users based on health profiles
        // In a real implementation, this would query a user similarity database
        
        return [
            SimilarUser(
                id: "user1",
                similarityScore: 0.85,
                successfulRecommendations: [
                    HealthRecommendation(
                        id: UUID(),
                        title: "Evening Stretching Routine",
                        description: "15-minute stretching routine before bed",
                        category: .activity,
                        priority: .medium,
                        timeOfDay: .evening,
                        evidenceLevel: .moderate,
                        personalizationFactors: ["sleep_quality"],
                        estimatedImpact: .moderate,
                        timeToImplement: 15,
                        frequency: .daily
                    )
                ]
            )
        ]
    }
    
    private func analyzeSleepPatterns(_ sleepData: [SleepRecord]) -> HealthRecommendation? {
        guard !sleepData.isEmpty else { return nil }
        
        let avgSleepQuality = sleepData.map { $0.quality }.reduce(0, +) / Double(sleepData.count)
        let avgSleepDuration = sleepData.map { $0.duration }.reduce(0, +) / Double(sleepData.count)
        
        if avgSleepQuality < 7.0 {
            return HealthRecommendation(
                id: UUID(),
                title: "Improve Sleep Quality",
                description: "Your sleep quality is below optimal. Try establishing a consistent bedtime routine.",
                category: .sleep,
                priority: .high,
                timeOfDay: .evening,
                evidenceLevel: .strong,
                personalizationFactors: ["sleep_quality"],
                estimatedImpact: .high,
                timeToImplement: 20,
                frequency: .daily
            )
        }
        
        if avgSleepDuration < 7.0 {
            return HealthRecommendation(
                id: UUID(),
                title: "Increase Sleep Duration",
                description: "Aim for 7-9 hours of sleep per night for optimal health.",
                category: .sleep,
                priority: .high,
                timeOfDay: .evening,
                evidenceLevel: .strong,
                personalizationFactors: ["sleep_duration"],
                estimatedImpact: .high,
                timeToImplement: 0, // Time management
                frequency: .daily
            )
        }
        
        return nil
    }
    
    private func analyzeActivityPatterns(_ activityData: [ActivityRecord]) -> HealthRecommendation? {
        guard !activityData.isEmpty else { return nil }
        
        let avgSteps = activityData.map { $0.stepCount }.reduce(0, +) / Double(activityData.count)
        
        if avgSteps < 8000 {
            return HealthRecommendation(
                id: UUID(),
                title: "Increase Daily Steps",
                description: "Aim for 10,000 steps per day to improve cardiovascular health.",
                category: .activity,
                priority: .medium,
                timeOfDay: .anytime,
                evidenceLevel: .strong,
                personalizationFactors: ["activity_levels"],
                estimatedImpact: .moderate,
                timeToImplement: 30,
                frequency: .daily
            )
        }
        
        return nil
    }
    
    private func analyzeHeartRatePatterns(_ heartRateData: [HeartRateRecord]) -> HealthRecommendation? {
        guard !heartRateData.isEmpty else { return nil }
        
        let avgHeartRate = heartRateData.map { $0.heartRate }.reduce(0, +) / Double(heartRateData.count)
        
        if avgHeartRate > 80 {
            return HealthRecommendation(
                id: UUID(),
                title: "Stress Management",
                description: "Your heart rate suggests elevated stress levels. Try deep breathing exercises.",
                category: .mindfulness,
                priority: .medium,
                timeOfDay: .anytime,
                evidenceLevel: .moderate,
                personalizationFactors: ["stress_levels"],
                estimatedImpact: .moderate,
                timeToImplement: 10,
                frequency: .daily
            )
        }
        
        return nil
    }
    
    private func analyzeNutritionPatterns(_ nutritionData: [NutritionRecord]) -> HealthRecommendation? {
        guard !nutritionData.isEmpty else { return nil }
        
        let avgWaterIntake = nutritionData.map { $0.waterIntake }.reduce(0, +) / Double(nutritionData.count)
        
        if avgWaterIntake < 2000 {
            return HealthRecommendation(
                id: UUID(),
                title: "Increase Water Intake",
                description: "Aim for 8-10 glasses of water per day for optimal hydration.",
                category: .nutrition,
                priority: .medium,
                timeOfDay: .anytime,
                evidenceLevel: .strong,
                personalizationFactors: ["hydration"],
                estimatedImpact: .moderate,
                timeToImplement: 1,
                frequency: .daily
            )
        }
        
        return nil
    }
    
    private func personalizeRecommendations(_ recommendations: [HealthRecommendation], for condition: HealthCondition) -> [HealthRecommendation] {
        return recommendations.map { recommendation in
            var personalized = recommendation
            personalized.description = "\(recommendation.description) (Personalized for \(condition.displayName))"
            return personalized
        }
    }
    
    private func cacheRecommendations(_ recommendations: [HealthRecommendation], for userId: String) {
        let key = "recommendations_\(userId)" as NSString
        recommendationCache.setObject(recommendations, forKey: key)
    }
}

// MARK: - Supporting Types

struct HealthRecommendation: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let category: HealthCategory
    let priority: RecommendationPriority
    let timeOfDay: TimeOfDay
    let evidenceLevel: EvidenceLevel
    let personalizationFactors: [String]
    let estimatedImpact: ImpactLevel
    let timeToImplement: Int // minutes
    let frequency: RecommendationFrequency
    var engagementMetrics: EngagementMetrics = EngagementMetrics()
    
    enum HealthCategory: String, CaseIterable, Codable {
        case sleep, activity, nutrition, mindfulness, medication, social, environmental
    }
    
    enum RecommendationPriority: String, CaseIterable, Codable {
        case critical, high, medium, low
    }
    
    enum TimeOfDay: String, CaseIterable, Codable {
        case morning, afternoon, evening, anytime
    }
    
    enum EvidenceLevel: String, CaseIterable, Codable {
        case strong, moderate, weak, anecdotal
    }
    
    enum ImpactLevel: String, CaseIterable, Codable {
        case high, moderate, low
    }
    
    enum RecommendationFrequency: String, CaseIterable, Codable {
        case daily, weekly, monthly, once
    }
}

struct UserHealthPreferences: Codable {
    var preferredCategories: [HealthRecommendation.HealthCategory] = []
    var preferredTimeOfDay: HealthRecommendation.TimeOfDay = .anytime
    var maxTimePerRecommendation: Int = 30 // minutes
    var notificationPreferences: NotificationPreferences = NotificationPreferences()
    var healthGoals: [HealthGoal] = []
    
    struct NotificationPreferences: Codable {
        var enablePushNotifications: Bool = true
        var quietHours: ClosedRange<Int> = 22...7
        var frequency: NotificationFrequency = .daily
    }
    
    enum NotificationFrequency: String, CaseIterable, Codable {
        case hourly, daily, weekly
    }
}

struct HealthGoal: Codable, Identifiable {
    let id: UUID
    let title: String
    let targetValue: Double
    let currentValue: Double
    let unit: String
    let deadline: Date?
    let category: HealthRecommendation.HealthCategory
}

struct HealthDataSnapshot: Codable {
    let userId: String
    let sleepData: [SleepRecord]
    let activityData: [ActivityRecord]
    let heartRateData: [HeartRateRecord]
    let nutritionData: [NutritionRecord]
    let mindfulnessData: [MindfulnessRecord]
    let timestamp: Date
}

struct SimilarUser: Codable {
    let id: String
    let similarityScore: Double
    let successfulRecommendations: [HealthRecommendation]
}

struct EngagementMetrics: Codable {
    var views: Int = 0
    var clicks: Int = 0
    var dismissals: Int = 0
    var completions: Int = 0
    var lastViewed: Date?
    
    mutating func recordAction(_ action: RecommendationAction) {
        switch action {
        case .view:
            views += 1
            lastViewed = Date()
        case .click:
            clicks += 1
        case .dismiss:
            dismissals += 1
        case .complete:
            completions += 1
        }
    }
}

enum RecommendationAction: String, CaseIterable {
    case view, click, dismiss, complete
}

enum HealthCondition: String, CaseIterable, Codable {
    case diabetes, hypertension, obesity, depression, anxiety, insomnia, cardiovascular
    
    var displayName: String {
        switch self {
        case .diabetes: return "Diabetes"
        case .hypertension: return "Hypertension"
        case .obesity: return "Obesity"
        case .depression: return "Depression"
        case .anxiety: return "Anxiety"
        case .insomnia: return "Insomnia"
        case .cardiovascular: return "Cardiovascular Disease"
        }
    }
}

// MARK: - A/B Testing Manager

class ABTestManager: ObservableObject {
    private var activeTests: [String: ABTest] = [:]
    private var userAssignments: [String: String] = [:]
    
    func applyABTesting(to recommendations: [HealthRecommendation]) -> [HealthRecommendation] {
        var testedRecommendations = recommendations
        
        for test in activeTests.values {
            if let variant = getVariantForUser(test.id) {
                testedRecommendations = test.applyVariant(variant, to: testedRecommendations)
            }
        }
        
        return testedRecommendations
    }
    
    func trackEngagement(for recommendation: HealthRecommendation, action: RecommendationAction) {
        // Track engagement for A/B test analysis
        for test in activeTests.values {
            test.recordEngagement(for: recommendation, action: action)
        }
    }
    
    private func getVariantForUser(_ testId: String) -> String? {
        return userAssignments[testId]
    }
}

struct ABTest: Codable {
    let id: String
    let name: String
    let variants: [String]
    let startDate: Date
    let endDate: Date
    
    func applyVariant(_ variant: String, to recommendations: [HealthRecommendation]) -> [HealthRecommendation] {
        // Apply variant-specific modifications to recommendations
        return recommendations
    }
    
    func recordEngagement(for recommendation: HealthRecommendation, action: RecommendationAction) {
        // Record engagement for analysis
    }
}

// MARK: - Evidence-Based Intervention Database

class EvidenceBasedInterventionDatabase: ObservableObject {
    
    func getInterventionsForCondition(_ condition: HealthCondition) async throws -> [EvidenceBasedIntervention] {
        // Simulate database query for evidence-based interventions
        switch condition {
        case .diabetes:
            return [
                EvidenceBasedIntervention(
                    title: "Blood Sugar Monitoring",
                    description: "Monitor blood glucose levels regularly",
                    category: .medication,
                    priority: .high,
                    timeOfDay: .anytime,
                    evidenceLevel: .strong,
                    personalizationFactors: ["blood_sugar_levels"],
                    estimatedImpact: .high,
                    timeToImplement: 5,
                    frequency: .daily
                )
            ]
        case .hypertension:
            return [
                EvidenceBasedIntervention(
                    title: "Sodium Reduction",
                    description: "Reduce sodium intake to less than 2,300mg per day",
                    category: .nutrition,
                    priority: .high,
                    timeOfDay: .anytime,
                    evidenceLevel: .strong,
                    personalizationFactors: ["blood_pressure"],
                    estimatedImpact: .high,
                    timeToImplement: 0,
                    frequency: .daily
                )
            ]
        default:
            return []
        }
    }
    
    func getInterventionsForHealthData(_ healthData: HealthDataSnapshot) async throws -> [EvidenceBasedIntervention] {
        // Analyze health data and return relevant interventions
        var interventions: [EvidenceBasedIntervention] = []
        
        // Add general wellness interventions
        interventions.append(EvidenceBasedIntervention(
            title: "Regular Exercise",
            description: "Engage in 150 minutes of moderate exercise per week",
            category: .activity,
            priority: .high,
            timeOfDay: .anytime,
            evidenceLevel: .strong,
            personalizationFactors: ["activity_levels"],
            estimatedImpact: .high,
            timeToImplement: 30,
            frequency: .daily
        ))
        
        return interventions
    }
}

struct EvidenceBasedIntervention: Codable {
    let title: String
    let description: String
    let category: HealthRecommendation.HealthCategory
    let priority: HealthRecommendation.RecommendationPriority
    let timeOfDay: HealthRecommendation.TimeOfDay
    let evidenceLevel: HealthRecommendation.EvidenceLevel
    let personalizationFactors: [String]
    let estimatedImpact: HealthRecommendation.ImpactLevel
    let timeToImplement: Int
    let frequency: HealthRecommendation.RecommendationFrequency
}

// MARK: - Mock Data Extensions

extension Array where Element == SleepRecord {
    var averageQuality: Double? {
        guard !isEmpty else { return nil }
        return map { $0.quality }.reduce(0, +) / Double(count)
    }
    
    var averageDuration: Double? {
        guard !isEmpty else { return nil }
        return map { $0.duration }.reduce(0, +) / Double(count)
    }
}

extension Array where Element == ActivityRecord {
    var averageSteps: Double? {
        guard !isEmpty else { return nil }
        return map { $0.stepCount }.reduce(0, +) / Double(count)
    }
}

extension Array where Element == HeartRateRecord {
    var averageHeartRate: Double? {
        guard !isEmpty else { return nil }
        return map { $0.heartRate }.reduce(0, +) / Double(count)
    }
}

extension Array where Element == NutritionRecord {
    var averageWaterIntake: Double? {
        guard !isEmpty else { return nil }
        return map { $0.waterIntake }.reduce(0, +) / Double(count)
    }
} 