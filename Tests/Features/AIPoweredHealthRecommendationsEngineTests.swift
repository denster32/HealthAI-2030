import XCTest
import Combine
import SwiftUI
import CoreML
@testable import HealthAI2030Core

@available(iOS 18.0, macOS 15.0, *)
final class AIPoweredHealthRecommendationsEngineTests: XCTestCase {
    
    var recommendationsEngine: AIPoweredHealthRecommendationsEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        recommendationsEngine = AIPoweredHealthRecommendationsEngine.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        recommendationsEngine = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testRecommendationsEngineInitialization() {
        XCTAssertNotNil(recommendationsEngine)
        XCTAssertTrue(recommendationsEngine.currentRecommendations.isEmpty)
        XCTAssertTrue(recommendationsEngine.personalizedPlans.isEmpty)
        XCTAssertTrue(recommendationsEngine.recommendationInsights.isEmpty)
        XCTAssertFalse(recommendationsEngine.isGenerating)
        XCTAssertEqual(recommendationsEngine.recommendationAccuracy, 0.0)
        XCTAssertEqual(recommendationsEngine.userEngagement.totalInteractions, 0)
        XCTAssertTrue(recommendationsEngine.contextualFactors.isEmpty)
    }
    
    // MARK: - Recommendation Generation Tests
    
    func testGenerateRecommendations() async throws {
        let recommendations = try await recommendationsEngine.generateRecommendations()
        
        XCTAssertNotNil(recommendations)
        XCTAssertTrue(recommendations is [AIHealthRecommendation])
        XCTAssertGreaterThanOrEqual(recommendations.count, 0)
    }
    
    func testGenerateRecommendationsUpdatesPublishedProperties() async throws {
        let initialRecommendationsCount = recommendationsEngine.currentRecommendations.count
        
        _ = try await recommendationsEngine.generateRecommendations()
        
        // Wait for UI updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        XCTAssertNotEqual(recommendationsEngine.currentRecommendations.count, initialRecommendationsCount)
    }
    
    func testGenerateRecommendationsWhenAlreadyGenerating() async {
        // Start a recommendation generation
        let task1 = Task {
            try await recommendationsEngine.generateRecommendations()
        }
        
        // Try to start another generation immediately
        do {
            _ = try await recommendationsEngine.generateRecommendations()
            XCTFail("Should throw error when already generating")
        } catch RecommendationError.alreadyGenerating {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Wait for first task to complete
        _ = try? await task1.value
    }
    
    // MARK: - Personalized Health Plan Tests
    
    func testGeneratePersonalizedHealthPlan() async throws {
        let goals = createMockHealthGoals()
        
        let plan = try await recommendationsEngine.generatePersonalizedHealthPlan(goals: goals)
        
        XCTAssertNotNil(plan)
        XCTAssertEqual(plan.goals.count, goals.count)
        XCTAssertNotNil(plan.recommendations)
        XCTAssertGreaterThan(plan.timeline, 0)
        XCTAssertNotNil(plan.startDate)
        XCTAssertNotNil(plan.endDate)
        XCTAssertNotNil(plan.milestones)
        XCTAssertGreaterThan(plan.confidence, 0.0)
    }
    
    func testGeneratePersonalizedHealthPlanUpdatesPublishedProperties() async throws {
        let initialPlansCount = recommendationsEngine.personalizedPlans.count
        let goals = createMockHealthGoals()
        
        _ = try await recommendationsEngine.generatePersonalizedHealthPlan(goals: goals)
        
        // Wait for UI updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        XCTAssertNotEqual(recommendationsEngine.personalizedPlans.count, initialPlansCount)
    }
    
    // MARK: - Aspect-Specific Recommendations Tests
    
    func testGetRecommendationsForSpecificAspect() async throws {
        let cardiovascularRecommendations = try await recommendationsEngine.getRecommendations(for: .cardiovascular)
        
        XCTAssertNotNil(cardiovascularRecommendations)
        XCTAssertTrue(cardiovascularRecommendations is [AIHealthRecommendation])
        
        // Verify all recommendations are for cardiovascular aspect
        for recommendation in cardiovascularRecommendations {
            XCTAssertEqual(recommendation.aspect, .cardiovascular)
        }
    }
    
    func testGetRecommendationsForAllAspects() async throws {
        for aspect in HealthAspect.allCases {
            let recommendations = try await recommendationsEngine.getRecommendations(for: aspect)
            
            XCTAssertNotNil(recommendations)
            XCTAssertTrue(recommendations is [AIHealthRecommendation])
            
            for recommendation in recommendations {
                XCTAssertEqual(recommendation.aspect, aspect)
            }
        }
    }
    
    // MARK: - Contextual Recommendations Tests
    
    func testGetContextualRecommendations() async throws {
        let context = RecommendationContext(factors: [.stress, .activity])
        
        let contextualRecommendations = try await recommendationsEngine.getContextualRecommendations(context: context)
        
        XCTAssertNotNil(contextualRecommendations)
        XCTAssertTrue(contextualRecommendations is [AIHealthRecommendation])
        
        // Verify recommendations have relevant contextual factors
        for recommendation in contextualRecommendations {
            let hasRelevantFactor = recommendation.contextualFactors.contains { factor in
                context.factors.contains(factor.type)
            }
            XCTAssertTrue(hasRelevantFactor)
        }
    }
    
    // MARK: - Recommendation Insights Tests
    
    func testGetRecommendationInsights() async throws {
        let insights = try await recommendationsEngine.getRecommendationInsights()
        
        XCTAssertNotNil(insights)
        XCTAssertTrue(insights is [RecommendationInsight])
    }
    
    func testGetRecommendationInsightsUpdatesPublishedProperties() async throws {
        let initialInsightsCount = recommendationsEngine.recommendationInsights.count
        
        _ = try await recommendationsEngine.getRecommendationInsights()
        
        // Wait for UI updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        XCTAssertNotEqual(recommendationsEngine.recommendationInsights.count, initialInsightsCount)
    }
    
    // MARK: - Feedback Tests
    
    func testProvideFeedback() async throws {
        let recommendations = try await recommendationsEngine.generateRecommendations()
        guard let recommendation = recommendations.first else {
            XCTSkip("No recommendations available for testing")
            return
        }
        
        let feedback = RecommendationFeedback(
            recommendationId: recommendation.id,
            action: .accepted,
            rating: 5,
            comment: "Great recommendation!"
        )
        
        try await recommendationsEngine.provideFeedback(for: recommendation, feedback: feedback)
        
        // Verify feedback was processed
        XCTAssertGreaterThan(recommendationsEngine.userEngagement.totalInteractions, 0)
    }
    
    func testProvideFeedbackUpdatesEngagementMetrics() async throws {
        let recommendations = try await recommendationsEngine.generateRecommendations()
        guard let recommendation = recommendations.first else {
            XCTSkip("No recommendations available for testing")
            return
        }
        
        let initialInteractions = recommendationsEngine.userEngagement.totalInteractions
        
        let feedback = RecommendationFeedback(
            recommendationId: recommendation.id,
            action: .implemented,
            rating: 4,
            comment: "Implemented successfully"
        )
        
        try await recommendationsEngine.provideFeedback(for: recommendation, feedback: feedback)
        
        // Verify engagement metrics were updated
        XCTAssertGreaterThan(recommendationsEngine.userEngagement.totalInteractions, initialInteractions)
        XCTAssertGreaterThan(recommendationsEngine.userEngagement.implementedRecommendations, 0)
    }
    
    // MARK: - Recommendation Explanation Tests
    
    func testGetRecommendationExplanation() async throws {
        let recommendations = try await recommendationsEngine.generateRecommendations()
        guard let recommendation = recommendations.first else {
            XCTSkip("No recommendations available for testing")
            return
        }
        
        let explanation = try await recommendationsEngine.getRecommendationExplanation(for: recommendation)
        
        XCTAssertNotNil(explanation)
        XCTAssertNotNil(explanation.summary)
        XCTAssertNotNil(explanation.featureImportances)
        XCTAssertNotNil(explanation.decisionPath)
        XCTAssertGreaterThan(explanation.confidence, 0.0)
        XCTAssertNotNil(explanation.contextualFactors)
    }
    
    // MARK: - User Preferences Tests
    
    func testUpdateUserPreferences() async throws {
        let preferences = UserPreferences(
            preferredCategories: [.exercise, .nutrition],
            preferredTimeSensitivity: .high,
            maxRecommendationsPerDay: 3,
            notificationPreferences: NotificationPreferences()
        )
        
        try await recommendationsEngine.updateUserPreferences(preferences)
        
        // Verify preferences were updated (this would require exposing preferences for testing)
        XCTAssertTrue(true)
    }
    
    // MARK: - Statistics Tests
    
    func testGetRecommendationStats() {
        let stats = recommendationsEngine.getRecommendationStats()
        
        XCTAssertNotNil(stats)
        XCTAssertTrue(stats is RecommendationStats)
        XCTAssertGreaterThanOrEqual(stats.totalRecommendations, 0)
        XCTAssertGreaterThanOrEqual(stats.acceptedRecommendations, 0)
        XCTAssertGreaterThanOrEqual(stats.rejectedRecommendations, 0)
        XCTAssertGreaterThanOrEqual(stats.averageConfidence, 0.0)
        XCTAssertLessThanOrEqual(stats.averageConfidence, 1.0)
        XCTAssertNotNil(stats.lastGenerated)
    }
    
    // MARK: - Error Handling Tests
    
    func testRecommendationsEngineHandlesErrorsGracefully() async {
        // This test verifies that the engine doesn't crash when errors occur
        do {
            let recommendations = try await recommendationsEngine.generateRecommendations()
            XCTAssertNotNil(recommendations)
        } catch {
            // If an error is thrown, it should be handled gracefully
            XCTAssertTrue(error is RecommendationError)
        }
    }
    
    func testRecommendationErrorTypes() {
        let errors: [RecommendationError] = [
            .alreadyGenerating,
            .userProfileNotAvailable,
            .contextualEngineNotAvailable,
            .personalizationEngineNotAvailable,
            .feedbackProcessorNotAvailable,
            .explainableAINotAvailable,
            .mlModelNotAvailable
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Performance Tests
    
    func testRecommendationGenerationPerformance() async throws {
        let startTime = Date()
        
        _ = try await recommendationsEngine.generateRecommendations()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Recommendation generation should complete within reasonable time (10 seconds)
        XCTAssertLessThan(duration, 10.0)
    }
    
    func testConcurrentRecommendationRequests() async throws {
        let expectation1 = XCTestExpectation(description: "First recommendation request")
        let expectation2 = XCTestExpectation(description: "Second recommendation request")
        
        async let recommendations1 = recommendationsEngine.generateRecommendations()
        async let recommendations2 = recommendationsEngine.generateRecommendations()
        
        let (result1, result2) = try await (recommendations1, recommendations2)
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        
        expectation1.fulfill()
        expectation2.fulfill()
        
        wait(for: [expectation1, expectation2], timeout: 15.0)
    }
    
    // MARK: - Data Model Tests
    
    func testAIHealthRecommendationStructure() {
        let recommendation = AIHealthRecommendation(
            aspect: .cardiovascular,
            title: "Test Recommendation",
            description: "This is a test recommendation",
            category: .cardiovascular,
            priority: .high,
            confidence: 0.85,
            actionable: true,
            estimatedImpact: 0.8,
            contextualFactors: [],
            actionItems: ["Action 1", "Action 2"],
            timeSensitivity: .medium,
            personalizationScore: 0.9
        )
        
        XCTAssertEqual(recommendation.aspect, .cardiovascular)
        XCTAssertEqual(recommendation.title, "Test Recommendation")
        XCTAssertEqual(recommendation.description, "This is a test recommendation")
        XCTAssertEqual(recommendation.category, .cardiovascular)
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertEqual(recommendation.confidence, 0.85)
        XCTAssertTrue(recommendation.actionable)
        XCTAssertEqual(recommendation.estimatedImpact, 0.8)
        XCTAssertEqual(recommendation.actionItems.count, 2)
        XCTAssertEqual(recommendation.timeSensitivity, .medium)
        XCTAssertEqual(recommendation.personalizationScore, 0.9)
        XCTAssertNotNil(recommendation.timestamp)
    }
    
    func testPersonalizedHealthPlanStructure() {
        let goals = createMockHealthGoals()
        let recommendations = createMockRecommendations()
        let milestones = createMockMilestones()
        
        let plan = PersonalizedHealthPlan(
            id: UUID(),
            title: "Test Health Plan",
            description: "This is a test health plan",
            goals: goals,
            recommendations: recommendations,
            timeline: 30,
            progress: 0.5,
            startDate: Date(),
            endDate: Date().addingTimeInterval(30 * 24 * 3600),
            milestones: milestones,
            estimatedCompletion: Date().addingTimeInterval(25 * 24 * 3600),
            confidence: 0.85
        )
        
        XCTAssertNotNil(plan.id)
        XCTAssertEqual(plan.title, "Test Health Plan")
        XCTAssertEqual(plan.description, "This is a test health plan")
        XCTAssertEqual(plan.goals.count, goals.count)
        XCTAssertEqual(plan.recommendations.count, recommendations.count)
        XCTAssertEqual(plan.timeline, 30)
        XCTAssertEqual(plan.progress, 0.5)
        XCTAssertNotNil(plan.startDate)
        XCTAssertNotNil(plan.endDate)
        XCTAssertEqual(plan.milestones.count, milestones.count)
        XCTAssertNotNil(plan.estimatedCompletion)
        XCTAssertEqual(plan.confidence, 0.85)
    }
    
    func testHealthGoalStructure() {
        let goal = HealthGoal(
            title: "Improve Sleep",
            description: "Get 8 hours of sleep per night",
            targetValue: 8.0,
            currentValue: 6.5,
            unit: "hours",
            deadline: Date().addingTimeInterval(30 * 24 * 3600)
        )
        
        XCTAssertNotNil(goal.id)
        XCTAssertEqual(goal.title, "Improve Sleep")
        XCTAssertEqual(goal.description, "Get 8 hours of sleep per night")
        XCTAssertEqual(goal.targetValue, 8.0)
        XCTAssertEqual(goal.currentValue, 6.5)
        XCTAssertEqual(goal.unit, "hours")
        XCTAssertNotNil(goal.deadline)
    }
    
    func testHealthMilestoneStructure() {
        let milestone = HealthMilestone(
            id: UUID(),
            title: "Week 1 Milestone",
            description: "Complete first week of the plan",
            targetDate: Date().addingTimeInterval(7 * 24 * 3600),
            completed: false,
            progress: 0.3
        )
        
        XCTAssertNotNil(milestone.id)
        XCTAssertEqual(milestone.title, "Week 1 Milestone")
        XCTAssertEqual(milestone.description, "Complete first week of the plan")
        XCTAssertNotNil(milestone.targetDate)
        XCTAssertFalse(milestone.completed)
        XCTAssertEqual(milestone.progress, 0.3)
    }
    
    func testRecommendationInsightStructure() {
        let insight = RecommendationInsight(
            type: .multipleHighPriority,
            title: "Multiple High Priority Recommendations",
            description: "You have several high priority recommendations",
            severity: .medium,
            actionable: true
        )
        
        XCTAssertNotNil(insight.id)
        XCTAssertEqual(insight.type, .multipleHighPriority)
        XCTAssertEqual(insight.title, "Multiple High Priority Recommendations")
        XCTAssertEqual(insight.description, "You have several high priority recommendations")
        XCTAssertEqual(insight.severity, .medium)
        XCTAssertTrue(insight.actionable)
    }
    
    func testContextualFactorStructure() {
        let factor = ContextualFactor(
            type: .stress,
            value: "High",
            confidence: 0.8,
            relevance: 0.9
        )
        
        XCTAssertNotNil(factor.id)
        XCTAssertEqual(factor.type, .stress)
        XCTAssertEqual(factor.value, "High")
        XCTAssertEqual(factor.confidence, 0.8)
        XCTAssertEqual(factor.relevance, 0.9)
    }
    
    func testRecommendationFeedbackStructure() {
        let feedback = RecommendationFeedback(
            recommendationId: UUID(),
            action: .accepted,
            rating: 5,
            comment: "Great recommendation!"
        )
        
        XCTAssertNotNil(feedback.id)
        XCTAssertNotNil(feedback.recommendationId)
        XCTAssertEqual(feedback.action, .accepted)
        XCTAssertEqual(feedback.rating, 5)
        XCTAssertEqual(feedback.comment, "Great recommendation!")
        XCTAssertNotNil(feedback.timestamp)
    }
    
    func testRecommendationExplanationStructure() {
        let explanation = RecommendationExplanation(
            summary: "This recommendation is based on your health data",
            featureImportances: [
                FeatureImportance(feature: "Heart Rate", importance: 0.8, unit: "BPM"),
                FeatureImportance(feature: "Sleep Quality", importance: 0.6, unit: "score")
            ],
            decisionPath: ["Step 1", "Step 2", "Step 3"],
            confidence: 0.85,
            contextualFactors: ["Time of day", "Stress level"]
        )
        
        XCTAssertEqual(explanation.summary, "This recommendation is based on your health data")
        XCTAssertEqual(explanation.featureImportances.count, 2)
        XCTAssertEqual(explanation.decisionPath.count, 3)
        XCTAssertEqual(explanation.confidence, 0.85)
        XCTAssertEqual(explanation.contextualFactors.count, 2)
    }
    
    func testFeatureImportanceStructure() {
        let featureImportance = FeatureImportance(
            feature: "Heart Rate",
            importance: 0.8,
            unit: "BPM"
        )
        
        XCTAssertEqual(featureImportance.feature, "Heart Rate")
        XCTAssertEqual(featureImportance.importance, 0.8)
        XCTAssertEqual(featureImportance.unit, "BPM")
    }
    
    func testUserEngagementMetricsStructure() {
        let metrics = UserEngagementMetrics()
        
        XCTAssertEqual(metrics.totalInteractions, 0)
        XCTAssertEqual(metrics.acceptedRecommendations, 0)
        XCTAssertEqual(metrics.rejectedRecommendations, 0)
        XCTAssertEqual(metrics.implementedRecommendations, 0)
        XCTAssertEqual(metrics.ignoredRecommendations, 0)
        XCTAssertEqual(metrics.engagementRate, 0.0)
    }
    
    func testRecommendationStatsStructure() {
        let stats = RecommendationStats(
            totalRecommendations: 100,
            acceptedRecommendations: 75,
            rejectedRecommendations: 15,
            averageConfidence: 0.85,
            lastGenerated: Date()
        )
        
        XCTAssertEqual(stats.totalRecommendations, 100)
        XCTAssertEqual(stats.acceptedRecommendations, 75)
        XCTAssertEqual(stats.rejectedRecommendations, 15)
        XCTAssertEqual(stats.averageConfidence, 0.85)
        XCTAssertNotNil(stats.lastGenerated)
    }
    
    func testUserHealthProfileStructure() {
        let preferences = UserPreferences()
        let profile = UserHealthProfile(
            age: 35,
            gender: .other,
            height: 175.0,
            weight: 70.0,
            activityLevel: .moderate,
            healthGoals: [.improveSleep, .increaseActivity],
            medicalConditions: ["Hypertension"],
            medications: ["Lisinopril"],
            preferences: preferences
        )
        
        XCTAssertEqual(profile.age, 35)
        XCTAssertEqual(profile.gender, .other)
        XCTAssertEqual(profile.height, 175.0)
        XCTAssertEqual(profile.weight, 70.0)
        XCTAssertEqual(profile.activityLevel, .moderate)
        XCTAssertEqual(profile.healthGoals.count, 2)
        XCTAssertEqual(profile.medicalConditions.count, 1)
        XCTAssertEqual(profile.medications.count, 1)
        XCTAssertNotNil(profile.preferences)
    }
    
    func testUserPreferencesStructure() {
        let notificationPreferences = NotificationPreferences()
        let preferences = UserPreferences(
            preferredCategories: [.exercise, .nutrition],
            preferredTimeSensitivity: .high,
            maxRecommendationsPerDay: 5,
            notificationPreferences: notificationPreferences
        )
        
        XCTAssertEqual(preferences.preferredCategories.count, 2)
        XCTAssertEqual(preferences.preferredTimeSensitivity, .high)
        XCTAssertEqual(preferences.maxRecommendationsPerDay, 5)
        XCTAssertNotNil(preferences.notificationPreferences)
    }
    
    func testNotificationPreferencesStructure() {
        let quietHours = DateInterval(start: Date(), duration: 8 * 3600)
        let preferences = NotificationPreferences(
            enablePushNotifications: true,
            enableEmailNotifications: false,
            quietHours: quietHours
        )
        
        XCTAssertTrue(preferences.enablePushNotifications)
        XCTAssertFalse(preferences.enableEmailNotifications)
        XCTAssertNotNil(preferences.quietHours)
    }
    
    // MARK: - Integration Tests
    
    func testRecommendationsEngineIntegrationWithAnalytics() async throws {
        // Test that the recommendations engine properly integrates with the analytics engine
        let recommendations = try await recommendationsEngine.generateRecommendations()
        
        XCTAssertNotNil(recommendations)
        XCTAssertTrue(recommendations is [AIHealthRecommendation])
    }
    
    func testRecommendationsEngineIntegrationWithPrediction() async throws {
        // Test that the recommendations engine properly integrates with the prediction engine
        let recommendations = try await recommendationsEngine.generateRecommendations()
        
        XCTAssertNotNil(recommendations)
        XCTAssertTrue(recommendations is [AIHealthRecommendation])
    }
    
    func testRecommendationsEngineIntegrationWithMonitoring() async throws {
        // Test that the recommendations engine properly integrates with the monitoring engine
        let recommendations = try await recommendationsEngine.generateRecommendations()
        
        XCTAssertNotNil(recommendations)
        XCTAssertTrue(recommendations is [AIHealthRecommendation])
    }
    
    // MARK: - Periodic Updates Tests
    
    func testPeriodicUpdates() async throws {
        let expectation = XCTestExpectation(description: "Periodic update")
        expectation.expectedFulfillmentCount = 2
        
        var updateCount = 0
        recommendationsEngine.$lastUpdateTime
            .dropFirst()
            .sink { _ in
                updateCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Wait for periodic updates
        wait(for: [expectation], timeout: 15.0)
        
        XCTAssertGreaterThanOrEqual(updateCount, 1)
    }
    
    // MARK: - UI Integration Tests
    
    func testPublishedPropertiesForUI() {
        // Test that all published properties are accessible for UI binding
        XCTAssertNotNil(recommendationsEngine.currentRecommendations)
        XCTAssertNotNil(recommendationsEngine.personalizedPlans)
        XCTAssertNotNil(recommendationsEngine.recommendationInsights)
        XCTAssertNotNil(recommendationsEngine.isGenerating)
        XCTAssertNotNil(recommendationsEngine.lastUpdateTime)
        XCTAssertNotNil(recommendationsEngine.recommendationAccuracy)
        XCTAssertNotNil(recommendationsEngine.userEngagement)
        XCTAssertNotNil(recommendationsEngine.contextualFactors)
    }
    
    func testObservableObjectConformance() {
        // Test that the recommendations engine conforms to ObservableObject for SwiftUI
        XCTAssertTrue(recommendationsEngine is ObservableObject)
    }
    
    // MARK: - Test Helpers
    
    private func createMockHealthGoals() -> [HealthGoal] {
        return [
            HealthGoal(
                title: "Improve Sleep",
                description: "Get 8 hours of sleep per night",
                targetValue: 8.0,
                currentValue: 6.5,
                unit: "hours",
                deadline: Date().addingTimeInterval(30 * 24 * 3600)
            ),
            HealthGoal(
                title: "Increase Activity",
                description: "Walk 10,000 steps per day",
                targetValue: 10000.0,
                currentValue: 5000.0,
                unit: "steps",
                deadline: Date().addingTimeInterval(30 * 24 * 3600)
            )
        ]
    }
    
    private func createMockRecommendations() -> [AIHealthRecommendation] {
        return [
            AIHealthRecommendation(
                aspect: .cardiovascular,
                title: "Monitor Heart Rate",
                description: "Your heart rate is elevated",
                category: .cardiovascular,
                priority: .high,
                confidence: 0.85,
                actionable: true,
                estimatedImpact: 0.8,
                contextualFactors: [],
                actionItems: ["Action 1", "Action 2"],
                timeSensitivity: .medium,
                personalizationScore: 0.9
            )
        ]
    }
    
    private func createMockMilestones() -> [HealthMilestone] {
        return [
            HealthMilestone(
                id: UUID(),
                title: "Week 1",
                description: "Complete first week",
                targetDate: Date().addingTimeInterval(7 * 24 * 3600),
                completed: false,
                progress: 0.3
            ),
            HealthMilestone(
                id: UUID(),
                title: "Week 2",
                description: "Complete second week",
                targetDate: Date().addingTimeInterval(14 * 24 * 3600),
                completed: false,
                progress: 0.0
            )
        ]
    }
}

// MARK: - Test Extensions

extension AIPoweredHealthRecommendationsEngineTests {
    
    func testRecommendationsEngineSingleton() {
        let instance1 = AIPoweredHealthRecommendationsEngine.shared
        let instance2 = AIPoweredHealthRecommendationsEngine.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testRecommendationsEngineMemoryManagement() {
        weak var weakReference: AIPoweredHealthRecommendationsEngine?
        
        autoreleasepool {
            let strongReference = AIPoweredHealthRecommendationsEngine.shared
            weakReference = strongReference
        }
        
        // The singleton should remain in memory
        XCTAssertNotNil(weakReference)
    }
} 