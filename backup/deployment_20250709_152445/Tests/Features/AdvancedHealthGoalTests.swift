import XCTest
import Combine
@testable import HealthAI2030

/// Comprehensive unit tests for Advanced Health Goal Engine
final class AdvancedHealthGoalTests: XCTestCase {
    
    // MARK: - Properties
    
    var goalEngine: AdvancedHealthGoalEngine!
    var mockHealthDataManager: MockHealthDataManager!
    var mockMLModelManager: MockMLModelManager!
    var mockAnalyticsEngine: MockAnalyticsEngine!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockHealthDataManager = MockHealthDataManager()
        mockMLModelManager = MockMLModelManager()
        mockAnalyticsEngine = MockAnalyticsEngine()
        cancellables = Set<AnyCancellable>()
        
        goalEngine = AdvancedHealthGoalEngine(
            healthDataManager: mockHealthDataManager,
            mlModelManager: mockMLModelManager,
            analyticsEngine: mockAnalyticsEngine
        )
    }
    
    override func tearDown() {
        goalEngine = nil
        mockHealthDataManager = nil
        mockMLModelManager = nil
        mockAnalyticsEngine = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Goal Management Tests
    
    func testCreateGoal_Success() async throws {
        // Given
        let goal = createSampleGoal()
        mockHealthDataManager.mockHealthData = createSampleHealthData()
        
        // When
        try await goalEngine.createGoal(goal)
        
        // Then
        XCTAssertEqual(goalEngine.userGoals.count, 1)
        XCTAssertEqual(goalEngine.userGoals.first?.id, goal.id)
        XCTAssertEqual(goalEngine.userGoals.first?.title, goal.title)
        XCTAssertFalse(goalEngine.isLoading)
        XCTAssertNil(goalEngine.errorMessage)
    }
    
    func testCreateGoal_InvalidTitle_ThrowsError() async {
        // Given
        var goal = createSampleGoal()
        goal.title = ""
        
        // When & Then
        do {
            try await goalEngine.createGoal(goal)
            XCTFail("Expected error for invalid title")
        } catch GoalError.invalidTitle {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testCreateGoal_InvalidTargetValue_ThrowsError() async {
        // Given
        var goal = createSampleGoal()
        goal.targetValue = 0
        
        // When & Then
        do {
            try await goalEngine.createGoal(goal)
            XCTFail("Expected error for invalid target value")
        } catch GoalError.invalidTargetValue {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testCreateGoal_InvalidDeadline_ThrowsError() async {
        // Given
        var goal = createSampleGoal()
        goal.deadline = Date().addingTimeInterval(-86400) // Yesterday
        
        // When & Then
        do {
            try await goalEngine.createGoal(goal)
            XCTFail("Expected error for invalid deadline")
        } catch GoalError.invalidDeadline {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUpdateGoal_Success() async throws {
        // Given
        let originalGoal = createSampleGoal()
        try await goalEngine.createGoal(originalGoal)
        
        var updatedGoal = originalGoal
        updatedGoal.title = "Updated Goal Title"
        updatedGoal.targetValue = 15000
        
        // When
        try await goalEngine.updateGoal(updatedGoal)
        
        // Then
        XCTAssertEqual(goalEngine.userGoals.count, 1)
        XCTAssertEqual(goalEngine.userGoals.first?.title, "Updated Goal Title")
        XCTAssertEqual(goalEngine.userGoals.first?.targetValue, 15000)
        XCTAssertFalse(goalEngine.isLoading)
        XCTAssertNil(goalEngine.errorMessage)
    }
    
    func testDeleteGoal_Success() async throws {
        // Given
        let goal = createSampleGoal()
        try await goalEngine.createGoal(goal)
        XCTAssertEqual(goalEngine.userGoals.count, 1)
        
        // When
        try await goalEngine.deleteGoal(id: goal.id)
        
        // Then
        XCTAssertEqual(goalEngine.userGoals.count, 0)
        XCTAssertNil(goalEngine.goalProgress[goal.id])
        XCTAssertFalse(goalEngine.isLoading)
        XCTAssertNil(goalEngine.errorMessage)
    }
    
    func testDeleteGoal_GoalNotFound_ThrowsError() async {
        // When & Then
        do {
            try await goalEngine.deleteGoal(id: "nonexistent-id")
            XCTFail("Expected error for non-existent goal")
        } catch {
            // Expected error
        }
    }
    
    // MARK: - AI Recommendations Tests
    
    func testGenerateGoalRecommendations_Success() async {
        // Given
        mockHealthDataManager.mockHealthData = createSampleHealthData()
        let mockRecommendations = createSampleRecommendations()
        mockMLModelManager.mockRecommendations = mockRecommendations
        
        // When
        await goalEngine.generateGoalRecommendations()
        
        // Then
        XCTAssertEqual(goalEngine.aiRecommendations.count, mockRecommendations.count)
        XCTAssertEqual(goalEngine.aiRecommendations.first?.title, mockRecommendations.first?.title)
        XCTAssertNil(goalEngine.errorMessage)
    }
    
    func testGenerateGoalRecommendations_MLModelError_SetsErrorMessage() async {
        // Given
        mockHealthDataManager.mockHealthData = createSampleHealthData()
        mockMLModelManager.shouldThrowError = true
        
        // When
        await goalEngine.generateGoalRecommendations()
        
        // Then
        XCTAssertTrue(goalEngine.aiRecommendations.isEmpty)
        XCTAssertNotNil(goalEngine.errorMessage)
        XCTAssertTrue(goalEngine.errorMessage?.contains("Failed to generate goal recommendations") == true)
    }
    
    func testApplyRecommendation_Success() async throws {
        // Given
        let recommendation = createSampleRecommendation()
        mockHealthDataManager.mockHealthData = createSampleHealthData()
        
        // When
        try await goalEngine.applyRecommendation(recommendation)
        
        // Then
        XCTAssertEqual(goalEngine.userGoals.count, 1)
        XCTAssertEqual(goalEngine.userGoals.first?.title, recommendation.title)
        XCTAssertEqual(goalEngine.userGoals.first?.category, recommendation.category)
        XCTAssertEqual(goalEngine.userGoals.first?.targetValue, recommendation.targetValue)
        XCTAssertFalse(goalEngine.isLoading)
        XCTAssertNil(goalEngine.errorMessage)
    }
    
    func testAdjustGoalDifficulty_ProgressLow_DecreasesDifficulty() async throws {
        // Given
        let goal = createSampleGoal(difficulty: .advanced)
        try await goalEngine.createGoal(goal)
        
        // Mock low progress
        let progress = GoalProgress(
            goalId: goal.id,
            currentValue: goal.targetValue * 0.3, // 30% progress
            targetValue: goal.targetValue,
            completionPercentage: 30.0,
            milestones: [],
            lastUpdated: Date()
        )
        goalEngine.goalProgress[goal.id] = progress
        
        // When
        await goalEngine.adjustGoalDifficulty(for: goal.id)
        
        // Then
        let updatedGoal = goalEngine.userGoals.first { $0.id == goal.id }
        XCTAssertEqual(updatedGoal?.difficulty, .intermediate) // Should decrease from advanced to intermediate
    }
    
    func testAdjustGoalDifficulty_ProgressHigh_IncreasesDifficulty() async throws {
        // Given
        let goal = createSampleGoal(difficulty: .intermediate)
        try await goalEngine.createGoal(goal)
        
        // Mock high progress with plenty of time
        let progress = GoalProgress(
            goalId: goal.id,
            currentValue: goal.targetValue * 0.9, // 90% progress
            targetValue: goal.targetValue,
            completionPercentage: 90.0,
            milestones: [],
            lastUpdated: Date()
        )
        goalEngine.goalProgress[goal.id] = progress
        
        // When
        await goalEngine.adjustGoalDifficulty(for: goal.id)
        
        // Then
        let updatedGoal = goalEngine.userGoals.first { $0.id == goal.id }
        XCTAssertEqual(updatedGoal?.difficulty, .advanced) // Should increase from intermediate to advanced
    }
    
    // MARK: - Goal Progress Tracking Tests
    
    func testUpdateGoalProgress_UpdatesProgressCorrectly() async {
        // Given
        let goal = createSampleGoal()
        try await goalEngine.createGoal(goal)
        
        // Mock health data
        mockHealthDataManager.mockActivityData = ActivityData(
            averageSteps: 8000,
            exerciseMinutes: 45,
            activeCalories: 300,
            totalCalories: 2000
        )
        
        // When
        await goalEngine.updateGoalProgress()
        
        // Then
        let progress = goalEngine.goalProgress[goal.id]
        XCTAssertNotNil(progress)
        XCTAssertEqual(progress?.currentValue, 8000)
        XCTAssertEqual(progress?.completionPercentage, 80.0) // 8000/10000 * 100
    }
    
    func testMilestoneAchievement_TriggersNotification() async throws {
        // Given
        let goal = createSampleGoal()
        try await goalEngine.createGoal(goal)
        
        let progress = GoalProgress(
            goalId: goal.id,
            currentValue: goal.targetValue * 0.5, // 50% progress
            targetValue: goal.targetValue,
            completionPercentage: 50.0,
            milestones: [
                GoalMilestone(id: "milestone1", name: "50% Complete", targetPercentage: 50.0, targetValue: goal.targetValue * 0.5)
            ],
            lastUpdated: Date()
        )
        goalEngine.goalProgress[goal.id] = progress
        
        // When
        await goalEngine.updateGoalProgress()
        
        // Then
        let updatedProgress = goalEngine.goalProgress[goal.id]
        XCTAssertEqual(updatedProgress?.achievedMilestones.count, 1)
        XCTAssertEqual(updatedProgress?.achievedMilestones.first?.name, "50% Complete")
    }
    
    // MARK: - Social Goal Features Tests
    
    func testCreateSocialChallenge_Success() async throws {
        // Given
        let challenge = createSampleSocialChallenge()
        
        // When
        try await goalEngine.createSocialChallenge(challenge)
        
        // Then
        XCTAssertEqual(goalEngine.socialChallenges.count, 1)
        XCTAssertEqual(goalEngine.socialChallenges.first?.id, challenge.id)
        XCTAssertEqual(goalEngine.socialChallenges.first?.title, challenge.title)
        XCTAssertFalse(goalEngine.isLoading)
        XCTAssertNil(goalEngine.errorMessage)
    }
    
    func testCreateSocialChallenge_InvalidTitle_ThrowsError() async {
        // Given
        var challenge = createSampleSocialChallenge()
        challenge.title = ""
        
        // When & Then
        do {
            try await goalEngine.createSocialChallenge(challenge)
            XCTFail("Expected error for invalid title")
        } catch GoalError.invalidTitle {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testCreateSocialChallenge_TooManyParticipants_ThrowsError() async {
        // Given
        var challenge = createSampleSocialChallenge()
        challenge.maxParticipants = 5
        challenge.participants = Array(repeating: "user", count: 6) // More than max
        
        // When & Then
        do {
            try await goalEngine.createSocialChallenge(challenge)
            XCTFail("Expected error for too many participants")
        } catch GoalError.tooManyParticipants {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testJoinSocialChallenge_Success() async throws {
        // Given
        let challenge = createSampleSocialChallenge()
        try await goalEngine.createSocialChallenge(challenge)
        let originalParticipantCount = challenge.participants.count
        
        // When
        try await goalEngine.joinSocialChallenge(challenge.id)
        
        // Then
        let updatedChallenge = goalEngine.socialChallenges.first { $0.id == challenge.id }
        XCTAssertEqual(updatedChallenge?.participants.count, originalParticipantCount + 1)
        XCTAssertTrue(updatedChallenge?.participants.contains("current_user") == true)
    }
    
    func testJoinSocialChallenge_ChallengeNotFound_ThrowsError() async {
        // When & Then
        do {
            try await goalEngine.joinSocialChallenge("nonexistent-id")
            XCTFail("Expected error for non-existent challenge")
        } catch GoalError.challengeNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testShareGoal_Success() async throws {
        // Given
        let goal = createSampleGoal()
        try await goalEngine.createGoal(goal)
        let userIds = ["user1", "user2", "user3"]
        
        // When
        try await goalEngine.shareGoal(goal.id, with: userIds)
        
        // Then
        // Verify shared goal was created (implementation would check persistent storage)
        XCTAssertFalse(goalEngine.isLoading)
        XCTAssertNil(goalEngine.errorMessage)
    }
    
    // MARK: - Goal Analytics Tests
    
    func testUpdateGoalAnalytics_CalculatesCorrectMetrics() async {
        // Given
        let goals = [
            createSampleGoal(category: .steps, difficulty: .beginner),
            createSampleGoal(category: .sleep, difficulty: .intermediate),
            createSampleGoal(category: .exercise, difficulty: .advanced)
        ]
        
        for goal in goals {
            try await goalEngine.createGoal(goal)
        }
        
        // Mock progress data
        goalEngine.goalProgress[goals[0].id] = GoalProgress(
            goalId: goals[0].id,
            currentValue: goals[0].targetValue,
            targetValue: goals[0].targetValue,
            completionPercentage: 100.0,
            milestones: [],
            lastUpdated: Date()
        )
        
        goalEngine.goalProgress[goals[1].id] = GoalProgress(
            goalId: goals[1].id,
            currentValue: goals[1].targetValue * 0.5,
            targetValue: goals[1].targetValue,
            completionPercentage: 50.0,
            milestones: [],
            lastUpdated: Date()
        )
        
        goalEngine.goalProgress[goals[2].id] = GoalProgress(
            goalId: goals[2].id,
            currentValue: goals[2].targetValue * 0.25,
            targetValue: goals[2].targetValue,
            completionPercentage: 25.0,
            milestones: [],
            lastUpdated: Date()
        )
        
        // When
        await goalEngine.updateGoalAnalytics()
        
        // Then
        XCTAssertEqual(goalEngine.goalAnalytics.totalGoals, 3)
        XCTAssertEqual(goalEngine.goalAnalytics.activeGoals, 3)
        XCTAssertEqual(goalEngine.goalAnalytics.completedGoals, 1)
        XCTAssertEqual(goalEngine.goalAnalytics.averageCompletionRate, 58.33, accuracy: 0.01)
        XCTAssertEqual(goalEngine.goalAnalytics.goalDifficultyDistribution[.beginner], 1)
        XCTAssertEqual(goalEngine.goalAnalytics.goalDifficultyDistribution[.intermediate], 1)
        XCTAssertEqual(goalEngine.goalAnalytics.goalDifficultyDistribution[.advanced], 1)
    }
    
    func testCalculateSuccessRateByCategory_ReturnsCorrectRates() async {
        // Given
        let stepsGoal = createSampleGoal(category: .steps)
        let sleepGoal = createSampleGoal(category: .sleep)
        
        try await goalEngine.createGoal(stepsGoal)
        try await goalEngine.createGoal(sleepGoal)
        
        // Mock progress - steps goal completed, sleep goal not completed
        goalEngine.goalProgress[stepsGoal.id] = GoalProgress(
            goalId: stepsGoal.id,
            currentValue: stepsGoal.targetValue,
            targetValue: stepsGoal.targetValue,
            completionPercentage: 100.0,
            milestones: [],
            lastUpdated: Date()
        )
        
        goalEngine.goalProgress[sleepGoal.id] = GoalProgress(
            goalId: sleepGoal.id,
            currentValue: sleepGoal.targetValue * 0.3,
            targetValue: sleepGoal.targetValue,
            completionPercentage: 30.0,
            milestones: [],
            lastUpdated: Date()
        )
        
        // When
        await goalEngine.updateGoalAnalytics()
        
        // Then
        let successRates = goalEngine.goalAnalytics.successRateByCategory
        XCTAssertEqual(successRates[.steps], 100.0)
        XCTAssertEqual(successRates[.sleep], 0.0)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleGoal(
        id: String = UUID().uuidString,
        category: GoalCategory = .steps,
        difficulty: GoalDifficulty = .intermediate
    ) -> HealthGoal {
        return HealthGoal(
            id: id,
            title: "Sample Goal",
            description: "A sample health goal for testing",
            category: category,
            targetValue: 10000,
            currentValue: 0,
            unit: "steps",
            deadline: Date().addingTimeInterval(30 * 24 * 3600), // 30 days from now
            difficulty: difficulty,
            priority: .medium,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createSampleRecommendation() -> GoalRecommendation {
        return GoalRecommendation(
            id: UUID().uuidString,
            title: "Increase Daily Steps",
            description: "Based on your activity patterns, try increasing your daily step count",
            category: .steps,
            targetValue: 12000,
            currentValue: 8000,
            unit: "steps",
            deadline: Date().addingTimeInterval(30 * 24 * 3600),
            difficulty: .intermediate,
            priority: .medium,
            confidence: 0.85,
            reasoning: "Your current average is 8000 steps, increasing to 12000 would improve cardiovascular health"
        )
    }
    
    private func createSampleRecommendations() -> [GoalRecommendation] {
        return [
            createSampleRecommendation(),
            GoalRecommendation(
                id: UUID().uuidString,
                title: "Improve Sleep Quality",
                description: "Focus on getting 8 hours of quality sleep",
                category: .sleep,
                targetValue: 8.0,
                currentValue: 6.5,
                unit: "hours",
                deadline: Date().addingTimeInterval(30 * 24 * 3600),
                difficulty: .beginner,
                priority: .high,
                confidence: 0.92,
                reasoning: "Your sleep duration is below recommended levels"
            )
        ]
    }
    
    private func createSampleSocialChallenge() -> SocialChallenge {
        return SocialChallenge(
            id: UUID().uuidString,
            title: "30-Day Step Challenge",
            description: "Let's walk 10,000 steps every day for 30 days!",
            category: .steps,
            targetValue: 10000,
            deadline: Date().addingTimeInterval(30 * 24 * 3600),
            maxParticipants: 10,
            participants: [],
            createdBy: "user1",
            createdAt: Date()
        )
    }
    
    private func createSampleHealthData() -> HealthData {
        return HealthData(
            steps: 8000,
            sleepHours: 7.5,
            heartRate: 72,
            weight: 70.0,
            exerciseMinutes: 45,
            timestamp: Date()
        )
    }
}

// MARK: - Mock Classes

class MockHealthDataManager: HealthDataManager {
    var mockHealthData: HealthData?
    var mockActivityData: ActivityData?
    
    override func getHealthData(for period: HealthDataPeriod) async -> HealthData {
        return mockHealthData ?? HealthData(
            steps: 0,
            sleepHours: 0,
            heartRate: 0,
            weight: 0,
            exerciseMinutes: 0,
            timestamp: Date()
        )
    }
    
    override func getActivityData(for period: HealthDataPeriod) async -> ActivityData {
        return mockActivityData ?? ActivityData(
            averageSteps: 0,
            exerciseMinutes: 0,
            activeCalories: 0,
            totalCalories: 0
        )
    }
    
    var healthDataPublisher: AnyPublisher<HealthData, Never> {
        Just(mockHealthData ?? HealthData(
            steps: 0,
            sleepHours: 0,
            heartRate: 0,
            weight: 0,
            exerciseMinutes: 0,
            timestamp: Date()
        )).eraseToAnyPublisher()
    }
}

class MockMLModelManager: MLModelManager {
    var mockRecommendations: [GoalRecommendation] = []
    var shouldThrowError = false
    
    override func generateGoalRecommendations(from healthData: HealthData) async throws -> [GoalRecommendation] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "ML model error"])
        }
        return mockRecommendations
    }
}

class MockAnalyticsEngine: AnalyticsEngine {
    var analyticsUpdatePublisher: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}

// MARK: - Supporting Types

struct HealthData {
    let steps: Int
    let sleepHours: Double
    let heartRate: Int
    let weight: Double
    let exerciseMinutes: Int
    let timestamp: Date
}

struct ActivityData {
    let averageSteps: Double
    let exerciseMinutes: Double
    let activeCalories: Double
    let totalCalories: Double
}

enum HealthDataPeriod {
    case day, week, month, year
}

class HealthDataManager {
    func getHealthData(for period: HealthDataPeriod) async -> HealthData {
        return HealthData(steps: 0, sleepHours: 0, heartRate: 0, weight: 0, exerciseMinutes: 0, timestamp: Date())
    }
    
    func getActivityData(for period: HealthDataPeriod) async -> ActivityData {
        return ActivityData(averageSteps: 0, exerciseMinutes: 0, activeCalories: 0, totalCalories: 0)
    }
    
    var healthDataPublisher: AnyPublisher<HealthData, Never> {
        Just(HealthData(steps: 0, sleepHours: 0, heartRate: 0, weight: 0, exerciseMinutes: 0, timestamp: Date())).eraseToAnyPublisher()
    }
}

class MLModelManager {
    func generateGoalRecommendations(from healthData: HealthData) async throws -> [GoalRecommendation] {
        return []
    }
}

class AnalyticsEngine {
    var analyticsUpdatePublisher: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}

class GoalPersistenceManager {
    static let shared = GoalPersistenceManager()
    
    func loadGoals() async throws -> [HealthGoal] {
        return []
    }
    
    func saveGoal(_ goal: HealthGoal) async throws {
        // Mock implementation
    }
    
    func updateGoal(_ goal: HealthGoal) async throws {
        // Mock implementation
    }
    
    func deleteGoal(id: String) async throws {
        // Mock implementation
    }
    
    func saveSocialChallenge(_ challenge: SocialChallenge) async throws {
        // Mock implementation
    }
    
    func updateSocialChallenge(_ challenge: SocialChallenge) async throws {
        // Mock implementation
    }
    
    func saveSharedGoal(_ sharedGoal: SharedGoal) async throws {
        // Mock implementation
    }
}

class NotificationManager {
    static let shared = NotificationManager()
    
    func scheduleNotification(_ notification: LocalNotification) async {
        // Mock implementation
    }
}

struct LocalNotification {
    let title: String
    let body: String
    let category: NotificationCategory
    let userInfo: [String: Any]
}

enum NotificationCategory {
    case goalMilestone
}

struct UserProfile {
    let id: String
    let name: String
    
    static let current = UserProfile(id: "current_user", name: "Current User")
} 