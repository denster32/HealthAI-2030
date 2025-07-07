import XCTest
@testable import HealthAI2030

@available(iOS 17.0, *)
final class PersonalizedRecommendationEngineTests: XCTestCase {
    var engine: PersonalizedRecommendationEngine!
    
    override func setUpWithError() throws {
        engine = PersonalizedRecommendationEngine()
    }
    
    override func tearDownWithError() throws {
        engine = nil
    }
    
    func testGenerateRecommendationsIncludesConditionSpecific() async {
        let context = RecommendationContext(recentActivity: nil, recentSymptoms: nil, timeOfDay: nil)
        let recs = await engine.generateRecommendations(for: context)
        XCTAssertTrue(recs.contains { $0.type == .conditionSpecific })
    }
    
    func testGenerateRecommendationsIncludesLifestyle() async {
        let context = RecommendationContext(recentActivity: nil, recentSymptoms: nil, timeOfDay: nil)
        let recs = await engine.generateRecommendations(for: context)
        XCTAssertTrue(recs.contains { $0.type == .lifestyle })
    }
    
    func testABTestGroupAssignment() async {
        let context = RecommendationContext(recentActivity: nil, recentSymptoms: nil, timeOfDay: nil)
        _ = await engine.generateRecommendations(for: context)
        XCTAssertTrue([ABTestGroup.control, ABTestGroup.variant].contains(engine.abTestGroup))
    }
    
    func testAddAndCompleteGoal() {
        let goal = HealthGoal(id: UUID(), title: "Walk 10,000 steps", isCompleted: false)
        engine.addGoal(goal)
        XCTAssertTrue(engine.activeGoals.contains(goal))
        engine.completeGoal(goal)
        XCTAssertTrue(engine.activeGoals.first?.isCompleted ?? false)
    }
    
    func testNoDuplicateRecommendations() async {
        let context = RecommendationContext(recentActivity: nil, recentSymptoms: nil, timeOfDay: nil)
        let recs = await engine.generateRecommendations(for: context)
        let unique = Set(recs)
        XCTAssertEqual(recs.count, unique.count)
    }
} 