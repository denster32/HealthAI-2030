import XCTest
import Foundation
import Combine
@testable import HealthAI2030

/// Unit tests for Health Goal Engine Manager
final class HealthGoalEngineTests: XCTestCase {
    var manager: HealthGoalEngineManager!
    var cancellables: Set<AnyCancellable>!
    let userId = "user123"
    
    override func setUp() {
        super.setUp()
        manager = HealthGoalEngineManager.shared
        cancellables = Set<AnyCancellable>()
        manager.goals.removeAll()
        manager.progress.removeAll()
        manager.analytics.removeAll()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        manager = nil
        super.tearDown()
    }
    
    func testCreateGoal() {
        let goal = HealthGoalEngineManager.HealthGoal(
            title: "10k Steps",
            description: "Walk 10,000 steps daily",
            type: .steps,
            targetValue: 10000,
            unit: "steps",
            userId: userId
        )
        manager.createGoal(goal)
        XCTAssertTrue(manager.goals.contains(where: { $0.id == goal.id }))
        XCTAssertNotNil(manager.progress[goal.id])
    }
    
    func testUpdateGoal() {
        let goal = HealthGoalEngineManager.HealthGoal(
            title: "Sleep 8h",
            description: "Sleep at least 8 hours",
            type: .sleep,
            targetValue: 8,
            unit: "hours",
            userId: userId
        )
        manager.createGoal(goal)
        var updatedGoal = goal
        updatedGoal.targetValue = 9
        manager.updateGoal(updatedGoal)
        XCTAssertEqual(manager.goals.first?.targetValue, 9)
    }
    
    func testRemoveGoal() {
        let goal = HealthGoalEngineManager.HealthGoal(
            title: "Drink Water",
            description: "Drink 2L water",
            type: .water,
            targetValue: 2,
            unit: "L",
            userId: userId
        )
        manager.createGoal(goal)
        manager.removeGoal(goal.id)
        XCTAssertFalse(manager.goals.contains(where: { $0.id == goal.id }))
        XCTAssertNil(manager.progress[goal.id])
        XCTAssertNil(manager.analytics[goal.id])
    }
    
    func testUpdateProgressAndAnalytics() {
        let goal = HealthGoalEngineManager.HealthGoal(
            title: "Mindfulness",
            description: "10 min meditation",
            type: .mindfulness,
            targetValue: 10,
            unit: "min",
            userId: userId
        )
        manager.createGoal(goal)
        manager.updateProgress(goalId: goal.id, value: 5)
        let progress = manager.getProgress(goalId: goal.id)
        XCTAssertEqual(progress?.currentValue, 5)
        XCTAssertFalse(progress?.isCompleted ?? true)
        manager.updateProgress(goalId: goal.id, value: 10)
        let updatedProgress = manager.getProgress(goalId: goal.id)
        XCTAssertTrue(updatedProgress?.isCompleted ?? false)
        let analytics = manager.getAnalytics(goalId: goal.id)
        XCTAssertEqual(analytics?.completionRate, 1.0)
    }
    
    func testGoalsForUser() {
        let goal1 = HealthGoalEngineManager.HealthGoal(
            title: "Goal 1",
            description: "desc",
            type: .custom,
            targetValue: 1,
            unit: "unit",
            userId: userId
        )
        let goal2 = HealthGoalEngineManager.HealthGoal(
            title: "Goal 2",
            description: "desc",
            type: .custom,
            targetValue: 2,
            unit: "unit",
            userId: "other"
        )
        manager.createGoal(goal1)
        manager.createGoal(goal2)
        let userGoals = manager.goalsForUser(userId: userId)
        XCTAssertTrue(userGoals.contains(where: { $0.id == goal1.id }))
        XCTAssertFalse(userGoals.contains(where: { $0.id == goal2.id }))
    }
} 