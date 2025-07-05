import XCTest
import SwiftData
@testable import CopilotSkills
@testable import HealthPrediction
@testable import AR
@testable import SmartHome

/// Comprehensive tests for all core features
final class ComprehensiveFeatureTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: HealthData.self, configurations: config)
        modelContext = ModelContext(container)
    }
    
    override func tearDownWithError() throws {
        modelContext = nil
    }
    
    // MARK: - Copilot Skills Tests
    
    func testCopilotSkillRegistry() async throws {
        let registry = CopilotSkillRegistry.shared
        
        // Test skill registration
        XCTAssertTrue(registry.registeredSkills.count >= 3) // Should have default skills
        
        // Test skill lookup
        let causalSkill = registry.getSkill(id: "causal_explanation")
        XCTAssertNotNil(causalSkill)
        XCTAssertEqual(causalSkill?.skillName, "Causal Explanation")
        
        // Test intent handling
        let skillsForIntent = registry.getSkillsForIntent("explain_sleep_quality")
        XCTAssertFalse(skillsForIntent.isEmpty)
        
        // Test context building
        let context = CopilotContextBuilder(modelContext: modelContext)
            .withHealthData([])
            .withSleepSessions([])
            .withWorkoutRecords([])
            .build()
        
        XCTAssertNotNil(context)
    }
    
    func testCausalExplanationSkill() async throws {
        let skill = CausalExplanationSkill()
        
        // Test skill properties
        XCTAssertEqual(skill.skillID, "causal_explanation")
        XCTAssertEqual(skill.skillName, "Causal Explanation")
        XCTAssertTrue(skill.canHandle(intent: "explain_sleep_quality"))
        
        // Test execution with empty context
        let context = CopilotContextBuilder(modelContext: modelContext).build()
        let result = await skill.execute(intent: "explain_sleep_quality", parameters: [:], context: context)
        
        switch result {
        case .text(let message):
            XCTAssertTrue(message.contains("don't have enough sleep data"))
        default:
            XCTFail("Expected text result")
        }
    }
    
    func testActivityStreakTracker() async throws {
        let skill = ActivityStreakTrackerPlugin()
        
        // Test skill properties
        XCTAssertEqual(skill.skillID, "activity_streak_tracker")
        XCTAssertTrue(skill.canHandle(intent: "get_activity_streak"))
        
        // Test execution
        let context = CopilotContextBuilder(modelContext: modelContext).build()
        let result = await skill.execute(intent: "get_activity_streak", parameters: [:], context: context)
        
        switch result {
        case .composite(let results):
            XCTAssertFalse(results.isEmpty)
        default:
            XCTFail("Expected composite result")
        }
    }
    
    func testGoalSettingSkill() async throws {
        let skill = GoalSettingSkill()
        
        // Test skill properties
        XCTAssertEqual(skill.skillID, "goal_setting")
        XCTAssertTrue(skill.canHandle(intent: "set_goal"))
        
        // Test goal creation
        let parameters = [
            "goal_type": "steps",
            "target_value": 10000.0,
            "goal_name": "Daily Steps Goal"
        ]
        
        let context = CopilotContextBuilder(modelContext: modelContext).build()
        let result = await skill.execute(intent: "set_goal", parameters: parameters, context: context)
        
        switch result {
        case .composite(let results):
            XCTAssertFalse(results.isEmpty)
        default:
            XCTFail("Expected composite result")
        }
    }
    
    // MARK: - Health Prediction Tests
    
    func testCardiovascularRiskPredictor() async throws {
        let predictor = CardiovascularRiskPredictor.shared
        
        // Test model loading (may not be available in test environment)
        // XCTAssertTrue(predictor.isModelLoaded || predictor.isModelLoaded == false)
        
        // Test prediction with sample data
        let sampleHealthData = createSampleHealthData()
        let userProfile = createSampleUserProfile()
        
        let prediction = await predictor.predictRisk(healthData: sampleHealthData, userProfile: userProfile)
        
        // Test prediction structure
        XCTAssertNotNil(prediction)
        XCTAssertNotNil(prediction.riskLevel)
        XCTAssertNotNil(prediction.factors)
        XCTAssertNotNil(prediction.recommendations)
    }
    
    func testGlucosePredictionModel() async throws {
        let model = GlucosePredictionModel.shared
        
        // Test prediction with sample data
        let sampleHealthData = createSampleHealthData()
        let userProfile = createSampleUserProfile()
        
        let prediction = await model.predictGlucose(
            healthData: sampleHealthData,
            userProfile: userProfile,
            timeHorizon: .twoHours
        )
        
        // Test prediction structure
        XCTAssertNotNil(prediction)
        XCTAssertNotNil(prediction.predictions)
        XCTAssertNotNil(prediction.trends)
        XCTAssertNotNil(prediction.alerts)
    }
    
    func testFederatedLearningManager() async throws {
        let manager = FederatedLearningManager.shared
        
        // Test session initialization
        let participants = ["device1", "device2", "device3"]
        let config = FederatedConfig(maxRounds: 10, localEpochs: 2)
        
        let session = await manager.initializeFederatedLearning(
            modelType: .cardiovascularRisk,
            participants: participants,
            configuration: config
        )
        
        XCTAssertEqual(session.participants.count, 3)
        XCTAssertEqual(session.configuration.maxRounds, 10)
        XCTAssertEqual(session.status, .initializing)
        
        // Test skill statistics
        let stats = manager.getSkillStatistics()
        XCTAssertNotNil(stats["total_skills"])
        XCTAssertNotNil(stats["active_skills"])
    }
    
    // MARK: - AR Tests
    
    func testARHealthVisualizer() async throws {
        let visualizer = ARHealthVisualizer.shared
        
        // Test AR session initialization
        let isInitialized = await visualizer.initializeARSession()
        
        // Note: AR may not be available in test environment
        // XCTAssertTrue(isInitialized || !isInitialized)
        
        // Test visualization types
        let visualizationTypes = ARVisualizationType.allCases
        XCTAssertEqual(visualizationTypes.count, 5)
        XCTAssertTrue(visualizationTypes.contains(.heartRate))
        XCTAssertTrue(visualizationTypes.contains(.sleepQuality))
    }
    
    // MARK: - Smart Home Tests
    
    func testSmartHomeManager() async throws {
        let manager = SmartHomeManager.shared
        
        // Test HomeKit availability check
        // Note: HomeKit may not be available in test environment
        // XCTAssertTrue(manager.isHomeKitAvailable || !manager.isHomeKitAvailable)
        
        // Test health rule creation
        let trigger = HealthTrigger(
            metric: "heart_rate",
            condition: .greaterThan,
            threshold: 100.0
        )
        
        let action = AutomationAction.adjustLighting(brightness: 0.5, color: nil)
        
        let rule = try await manager.createHealthRule(
            trigger: trigger,
            action: action,
            name: "Test Rule"
        )
        
        XCTAssertEqual(rule.name, "Test Rule")
        XCTAssertEqual(rule.trigger.metric, "heart_rate")
        XCTAssertTrue(rule.isEnabled)
        
        // Test rule evaluation
        let healthData = HealthData()
        healthData.heartRate = 120.0
        
        XCTAssertTrue(rule.shouldTrigger(for: healthData))
        
        // Test rule update
        var updatedRule = rule
        updatedRule.isEnabled = false
        
        try await manager.updateHealthRule(updatedRule)
        XCTAssertFalse(updatedRule.isEnabled)
        
        // Test rule deletion
        try await manager.deleteHealthRule(rule)
        XCTAssertFalse(manager.healthRules.contains { $0.id == rule.id })
    }
    
    // MARK: - Integration Tests
    
    func testCopilotSkillIntegration() async throws {
        let registry = CopilotSkillRegistry.shared
        let context = CopilotContextBuilder(modelContext: modelContext)
            .withHealthData(createSampleHealthData())
            .withSleepSessions(createSampleSleepSessions())
            .withWorkoutRecords(createSampleWorkoutRecords())
            .build()
        
        // Test multiple skill execution
        let intents = ["explain_sleep_quality", "get_activity_streak", "list_goals"]
        let results = await registry.handleMultipleIntents(intents, parameters: [:], context: context)
        
        XCTAssertEqual(results.count, 3)
        
        // Test suggested actions
        let actions = registry.getAllSuggestedActions(context: context)
        XCTAssertFalse(actions.isEmpty)
    }
    
    func testHealthPredictionIntegration() async throws {
        let cvPredictor = CardiovascularRiskPredictor.shared
        let glucoseModel = GlucosePredictionModel.shared
        
        let healthData = createSampleHealthData()
        let userProfile = createSampleUserProfile()
        
        // Test concurrent predictions
        async let cvPrediction = cvPredictor.predictRisk(healthData: healthData, userProfile: userProfile)
        async let glucosePrediction = glucoseModel.predictGlucose(
            healthData: healthData,
            userProfile: userProfile,
            timeHorizon: .twoHours
        )
        
        let (cv, glucose) = await (cvPrediction, glucosePrediction)
        
        XCTAssertNotNil(cv)
        XCTAssertNotNil(glucose)
    }
    
    func testSmartHomeHealthIntegration() async throws {
        let smartHomeManager = SmartHomeManager.shared
        
        // Create health-based automation rule
        let trigger = HealthTrigger(
            metric: "stress_level",
            condition: .greaterThan,
            threshold: 0.7
        )
        
        let action = AutomationAction.adjustLighting(brightness: 0.3, color: UIColor.blue)
        
        let rule = try await smartHomeManager.createHealthRule(
            trigger: trigger,
            action: action,
            name: "Stress Relief Lighting"
        )
        
        // Test rule with high stress data
        let highStressData = HealthData()
        highStressData.stressLevel = 0.8
        
        XCTAssertTrue(rule.shouldTrigger(for: highStressData))
        
        // Test rule with low stress data
        let lowStressData = HealthData()
        lowStressData.stressLevel = 0.3
        
        XCTAssertFalse(rule.shouldTrigger(for: lowStressData))
    }
    
    // MARK: - Performance Tests
    
    func testCopilotSkillPerformance() async throws {
        let registry = CopilotSkillRegistry.shared
        let context = CopilotContextBuilder(modelContext: modelContext)
            .withHealthData(createLargeHealthDataset())
            .build()
        
        let startTime = Date()
        
        // Execute multiple skills
        for _ in 0..<10 {
            _ = await registry.handleIntent("explain_sleep_quality", parameters: [:], context: context)
        }
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        // Should complete within reasonable time
        XCTAssertLessThan(executionTime, 5.0)
    }
    
    func testHealthPredictionPerformance() async throws {
        let predictor = CardiovascularRiskPredictor.shared
        let healthData = createLargeHealthDataset()
        let userProfile = createSampleUserProfile()
        
        let startTime = Date()
        
        let prediction = await predictor.predictRisk(healthData: healthData, userProfile: userProfile)
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        XCTAssertNotNil(prediction)
        XCTAssertLessThan(executionTime, 3.0)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleHealthData() -> [HealthData] {
        var data: [HealthData] = []
        
        for i in 0..<10 {
            let healthData = HealthData()
            healthData.heartRate = 70.0 + Double(i)
            healthData.stressLevel = 0.3 + (Double(i) * 0.1)
            healthData.activityLevel = 0.5 + (Double(i) * 0.05)
            healthData.sleepDuration = 7.0 + (Double(i) * 0.2)
            healthData.sleepScore = 80.0 + (Double(i) * 2.0)
            healthData.timestamp = Date().addingTimeInterval(-Double(i * 3600))
            
            data.append(healthData)
        }
        
        return data
    }
    
    private func createSampleUserProfile() -> UserProfile {
        let profile = UserProfile()
        profile.age = 30
        profile.gender = "male"
        profile.bmi = 25.0
        profile.hasDiabetes = false
        profile.hasHypertension = false
        profile.smokingStatus = "never"
        return profile
    }
    
    private func createSampleSleepSessions() -> [SleepSession] {
        var sessions: [SleepSession] = []
        
        for i in 0..<7 {
            let session = SleepSession()
            session.startTime = Date().addingTimeInterval(-Double(i * 24 * 3600))
            session.duration = 7.5 * 3600 // 7.5 hours
            session.sleepScore = 85.0 + (Double(i) * 2.0)
            sessions.append(session)
        }
        
        return sessions
    }
    
    private func createSampleWorkoutRecords() -> [WorkoutRecord] {
        var records: [WorkoutRecord] = []
        
        for i in 0..<5 {
            let record = WorkoutRecord()
            record.startTime = Date().addingTimeInterval(-Double(i * 24 * 3600))
            record.duration = 45 * 60 // 45 minutes
            record.workoutType = "cardio"
            record.caloriesBurned = 300.0 + (Double(i) * 50.0)
            records.append(record)
        }
        
        return records
    }
    
    private func createLargeHealthDataset() -> [HealthData] {
        var data: [HealthData] = []
        
        for i in 0..<100 {
            let healthData = HealthData()
            healthData.heartRate = 60.0 + Double.random(in: 0...40)
            healthData.stressLevel = Double.random(in: 0...1)
            healthData.activityLevel = Double.random(in: 0...1)
            healthData.sleepDuration = Double.random(in: 6...9)
            healthData.sleepScore = Double.random(in: 60...100)
            healthData.timestamp = Date().addingTimeInterval(-Double(i * 3600))
            
            data.append(healthData)
        }
        
        return data
    }
} 