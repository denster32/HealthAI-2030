import XCTest
import AppIntents
@testable import HealthAI2030

@available(iOS 18.0, *)
class SiriTestSuite: XCTestCase {
    
    var healthAIIntent: HealthAIAppIntent!
    var responseManager: SiriResponseManager!
    var healthFormatter: SiriHealthFormatter!
    var errorHandler: SiriErrorHandler!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        healthAIIntent = HealthAIAppIntent()
        responseManager = SiriResponseManager.shared
        healthFormatter = SiriHealthFormatter()
        errorHandler = SiriErrorHandler()
    }
    
    override func tearDownWithError() throws {
        healthAIIntent = nil
        responseManager = nil
        healthFormatter = nil
        errorHandler = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Health Data Query Tests
    
    func testHeartRateQuery() async throws {
        // Test heart rate query intent
        healthAIIntent.healthCommand = "What's my heart rate?"
        
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Verify the response contains heart rate information
        // Note: This would be enhanced with actual HealthKit integration
    }
    
    func testSleepDataQuery() async throws {
        healthAIIntent.healthCommand = "How did I sleep last night?"
        
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Verify sleep data response format
    }
    
    func testStepsQuery() async throws {
        healthAIIntent.healthCommand = "How many steps have I taken today?"
        
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Verify steps data response
    }
    
    func testHealthScoreQuery() async throws {
        healthAIIntent.healthCommand = "What's my health score?"
        
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Verify health score calculation
    }
    
    func testWaterIntakeQuery() async throws {
        healthAIIntent.healthCommand = "How much water have I had today?"
        
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Verify water intake tracking
    }
    
    // MARK: - Health Action Tests
    
    func testLogWorkoutIntent() async throws {
        healthAIIntent.healthCommand = "Log my workout"
        
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Verify workout logging flow initiation
    }
    
    func testRecordWaterIntent() async throws {
        healthAIIntent.healthCommand = "Record my water intake"
        
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Verify water logging flow initiation
    }
    
    func testStartMeditationIntent() async throws {
        healthAIIntent.healthCommand = "Start meditation session"
        
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Verify meditation session initiation
    }
    
    func testSetHealthGoalIntent() async throws {
        healthAIIntent.healthCommand = "Set health goal"
        
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Verify goal setting flow initiation
    }
    
    // MARK: - Natural Language Processing Tests
    
    func testNaturalLanguageVariations() async throws {
        let variations = [
            "What's my heart rate?",
            "Show me my heart rate",
            "How's my heart rate",
            "Heart rate check",
            "Check my pulse"
        ]
        
        for variation in variations {
            healthAIIntent.healthCommand = variation
            let result = try await healthAIIntent.perform()
            XCTAssertNotNil(result, "Failed for variation: \(variation)")
        }
    }
    
    func testComplexQueries() async throws {
        let complexQueries = [
            "How did I sleep last night and what's my heart rate?",
            "Show me my steps and water intake for today",
            "Compare my sleep this week to last week",
            "What's my overall health status?"
        ]
        
        for query in complexQueries {
            healthAIIntent.healthCommand = query
            let result = try await healthAIIntent.perform()
            XCTAssertNotNil(result, "Failed for complex query: \(query)")
        }
    }
    
    func testInvalidQueries() async throws {
        let invalidQueries = [
            "Play music",
            "What's the weather?",
            "Call mom",
            "Random nonsense query"
        ]
        
        for query in invalidQueries {
            healthAIIntent.healthCommand = query
            let result = try await healthAIIntent.perform()
            XCTAssertNotNil(result, "Should handle invalid query gracefully: \(query)")
            // Verify that appropriate fallback response is provided
        }
    }
    
    // MARK: - Response Manager Tests
    
    func testResponseManagerInitialization() {
        XCTAssertNotNil(responseManager)
        XCTAssertFalse(responseManager.isProcessing)
        XCTAssertNil(responseManager.lastResponse)
    }
    
    func testResponseGeneration() async throws {
        let testData: [String: Any] = [
            "heartRate": 75.0,
            "steps": 8500.0,
            "waterIntake": 32.0
        ]
        
        let response = await responseManager.generateResponse(for: "What's my heart rate?", with: testData)
        
        XCTAssertNotNil(response)
        XCTAssertFalse(response.spokenText.isEmpty)
        XCTAssertFalse(response.displayText.isEmpty)
        XCTAssertGreaterThan(response.confidence, 0.0)
    }
    
    func testContextualResponseGeneration() async throws {
        // Test morning greeting
        let morningResponse = await responseManager.generateResponse(
            for: "What's my heart rate?",
            with: ["heartRate": 65.0]
        )
        
        // Test evening response
        let eveningResponse = await responseManager.generateResponse(
            for: "What's my heart rate?",
            with: ["heartRate": 70.0]
        )
        
        XCTAssertNotNil(morningResponse)
        XCTAssertNotNil(eveningResponse)
        // Responses should be contextually different based on time
    }
    
    // MARK: - Health Formatter Tests
    
    func testSpeechFormatting() async throws {
        let testText = "Your heart rate is 75 BPM and you've taken 10,000 steps."
        let formattedText = await healthFormatter.formatForSpeech(testText)
        
        XCTAssertNotNil(formattedText)
        XCTAssertTrue(formattedText.contains("beats per minute"))
        XCTAssertTrue(formattedText.contains("10 thousand"))
    }
    
    func testDisplayFormatting() async throws {
        let testText = "Your heart rate is 75 BPM and you've taken 10,000 steps."
        let formattedText = await healthFormatter.formatForDisplay(testText)
        
        XCTAssertNotNil(formattedText)
        // Should contain emoji indicators
        XCTAssertTrue(formattedText.contains("❤️") || formattedText.contains("👣"))
    }
    
    func testAccessibilityFormatting() async throws {
        let testText = "75 BPM, 85%, 10,000 steps"
        let accessibleText = await healthFormatter.formatForAccessibility(testText)
        
        XCTAssertNotNil(accessibleText)
        XCTAssertTrue(accessibleText.contains("seventy-five"))
        XCTAssertTrue(accessibleText.contains("percent"))
        XCTAssertTrue(accessibleText.contains("ten thousand"))
    }
    
    func testFollowUpSuggestions() async throws {
        let mockResponse = ContextualHealthResponse(
            baseResponse: "Your heart rate is 75 BPM.",
            insights: [],
            contextualElements: [],
            confidence: 0.9
        )
        
        let suggestions = await healthFormatter.generateFollowUpSuggestions(for: mockResponse)
        
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertLessThanOrEqual(suggestions.count, 5)
        XCTAssertTrue(suggestions.contains { $0.contains("heart rate") })
    }
    
    // MARK: - Error Handling Tests
    
    func testHealthKitPermissionError() async throws {
        let permissionError = PermissionError.healthKitNotAuthorized
        let errorResponse = await errorHandler.generateErrorResponse(for: permissionError, query: "What's my heart rate?")
        
        XCTAssertNotNil(errorResponse)
        XCTAssertTrue(errorResponse.spokenText.contains("permission"))
        XCTAssertFalse(errorResponse.followUpSuggestions.isEmpty)
    }
    
    func testNoDataAvailableError() async throws {
        let dataError = HealthDataError.noDataAvailable
        let errorResponse = await errorHandler.generateErrorResponse(for: dataError, query: "Show my sleep data")
        
        XCTAssertNotNil(errorResponse)
        XCTAssertTrue(errorResponse.spokenText.contains("data"))
        XCTAssertFalse(errorResponse.followUpSuggestions.isEmpty)
    }
    
    func testNetworkError() async throws {
        let networkError = NetworkError.noConnection
        let errorResponse = await errorHandler.generateErrorResponse(for: networkError, query: "Analyze my health trends")
        
        XCTAssertNotNil(errorResponse)
        XCTAssertTrue(errorResponse.spokenText.contains("connection") || errorResponse.spokenText.contains("internet"))
        XCTAssertFalse(errorResponse.followUpSuggestions.isEmpty)
    }
    
    func testDeviceError() async throws {
        let deviceError = DeviceError.watchNotConnected
        let errorResponse = await errorHandler.generateErrorResponse(for: deviceError, query: "What's my heart rate?")
        
        XCTAssertNotNil(errorResponse)
        XCTAssertTrue(errorResponse.spokenText.contains("Watch") || errorResponse.spokenText.contains("connected"))
        XCTAssertFalse(errorResponse.followUpSuggestions.isEmpty)
    }
    
    // MARK: - Data Query Intent Tests
    
    func testHealthDataQueryIntent() async throws {
        let queryIntent = HealthDataQueryIntent()
        queryIntent.dataType = .heartRate
        queryIntent.timePeriod = .today
        
        let result = try await queryIntent.perform()
        
        XCTAssertNotNil(result)
        // Verify the query intent processes correctly
    }
    
    func testHealthDataQueryWithDifferentTimePeriods() async throws {
        let timePeriods: [TimePeriod] = [.today, .yesterday, .thisWeek, .lastWeek, .thisMonth, .lastMonth]
        
        for period in timePeriods {
            let queryIntent = HealthDataQueryIntent()
            queryIntent.dataType = .steps
            queryIntent.timePeriod = period
            
            let result = try await queryIntent.perform()
            XCTAssertNotNil(result, "Failed for time period: \(period)")
        }
    }
    
    // MARK: - Health Action Intent Tests
    
    func testHealthActionIntent() async throws {
        let actionIntent = HealthActionIntent()
        actionIntent.actionType = .logWorkout
        actionIntent.value = "30 minutes running"
        
        let result = try await actionIntent.perform()
        
        XCTAssertNotNil(result)
    }
    
    func testHealthActionIntentWithoutValue() async throws {
        let actionIntent = HealthActionIntent()
        actionIntent.actionType = .startMeditation
        actionIntent.value = nil
        
        let result = try await actionIntent.perform()
        
        XCTAssertNotNil(result)
        // Should handle missing value gracefully
    }
    
    // MARK: - Health Goal Intent Tests
    
    func testCreateHealthGoal() async throws {
        let goalIntent = HealthGoalIntent()
        goalIntent.goalAction = .create
        goalIntent.goalType = .steps
        goalIntent.targetValue = "10000"
        
        let result = try await goalIntent.perform()
        
        XCTAssertNotNil(result)
    }
    
    func testCheckHealthGoals() async throws {
        let goalIntent = HealthGoalIntent()
        goalIntent.goalAction = .check
        
        let result = try await goalIntent.perform()
        
        XCTAssertNotNil(result)
    }
    
    func testUpdateHealthGoal() async throws {
        let goalIntent = HealthGoalIntent()
        goalIntent.goalAction = .update
        goalIntent.goalType = .water
        goalIntent.targetValue = "80"
        
        let result = try await goalIntent.perform()
        
        XCTAssertNotNil(result)
    }
    
    func testDeleteHealthGoal() async throws {
        let goalIntent = HealthGoalIntent()
        goalIntent.goalAction = .delete
        goalIntent.goalType = .exercise
        
        let result = try await goalIntent.perform()
        
        XCTAssertNotNil(result)
    }
    
    // MARK: - Performance Tests
    
    func testSiriResponseTime() async throws {
        let startTime = Date()
        
        healthAIIntent.healthCommand = "What's my heart rate?"
        let result = try await healthAIIntent.perform()
        
        let endTime = Date()
        let responseTime = endTime.timeIntervalSince(startTime)
        
        XCTAssertNotNil(result)
        XCTAssertLessThan(responseTime, 2.0, "Siri response should be under 2 seconds")
    }
    
    func testMultipleConcurrentRequests() async throws {
        let commands = [
            "What's my heart rate?",
            "How did I sleep?",
            "Show my steps",
            "Check my water intake",
            "What's my health score?"
        ]
        
        await withTaskGroup(of: Void.self) { group in
            for command in commands {
                group.addTask {
                    let intent = HealthAIAppIntent()
                    intent.healthCommand = command
                    
                    do {
                        let result = try await intent.perform()
                        XCTAssertNotNil(result)
                    } catch {
                        XCTFail("Concurrent request failed for command: \(command)")
                    }
                }
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testSiriShortcutsSuggestions() async throws {
        let suggestions = responseManager.suggestHealthShortcuts()
        
        XCTAssertFalse(suggestions.isEmpty)
        XCTAssertLessThanOrEqual(suggestions.count, 10) // Reasonable limit
    }
    
    func testHealthDataManagerIntegration() async throws {
        let healthManager = HealthDataManager.shared
        
        // Test basic data retrieval methods
        let heartRate = await healthManager.getLatestHeartRate()
        let sleep = await healthManager.getLastNightSleep()
        let steps = await healthManager.getTodaySteps()
        
        // These are mock implementations, so we just verify they don't crash
        XCTAssertNotNil(heartRate)
        XCTAssertNotNil(sleep)
        XCTAssertNotNil(steps)
    }
    
    // MARK: - Accessibility Tests
    
    func testVoiceOverCompatibility() async throws {
        healthAIIntent.healthCommand = "What's my heart rate?"
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Verify that the response is VoiceOver friendly
        // This would be enhanced with actual VoiceOver testing in a UI test
    }
    
    func testDynamicTypeSupport() async throws {
        // Test that responses work with different text sizes
        let testText = "Your heart rate is 75 BPM"
        let formattedText = await healthFormatter.formatForDisplay(testText)
        
        XCTAssertNotNil(formattedText)
        // Verify that text doesn't break with dynamic type scaling
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyHealthCommand() async throws {
        healthAIIntent.healthCommand = ""
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Should handle empty input gracefully
    }
    
    func testVeryLongHealthCommand() async throws {
        let longCommand = String(repeating: "What's my heart rate? ", count: 100)
        healthAIIntent.healthCommand = longCommand
        
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Should handle very long input without crashing
    }
    
    func testSpecialCharactersInCommand() async throws {
        healthAIIntent.healthCommand = "What's my 💓 rate? Show me 📊 data!"
        let result = try await healthAIIntent.perform()
        
        XCTAssertNotNil(result)
        // Should handle emoji and special characters
    }
    
    func testNonEnglishCommands() async throws {
        let nonEnglishCommands = [
            "¿Cuál es mi frecuencia cardíaca?", // Spanish
            "Quelle est ma fréquence cardiaque?", // French
            "Was ist meine Herzfrequenz?", // German
            "私の心拍数は何ですか？" // Japanese
        ]
        
        for command in nonEnglishCommands {
            healthAIIntent.healthCommand = command
            let result = try await healthAIIntent.perform()
            XCTAssertNotNil(result, "Failed for non-English command: \(command)")
        }
    }
    
    // MARK: - Memory and Resource Tests
    
    func testMemoryUsage() async throws {
        // Test that repeated Siri interactions don't cause memory leaks
        for _ in 1...100 {
            healthAIIntent.healthCommand = "What's my heart rate?"
            let result = try await healthAIIntent.perform()
            XCTAssertNotNil(result)
        }
        
        // Memory usage should be stable
        // This would be enhanced with actual memory profiling
    }
    
    func testResourceCleanup() {
        // Test that resources are properly cleaned up
        let initialResponseManager = SiriResponseManager.shared
        
        // Perform operations
        Task {
            _ = await initialResponseManager.generateResponse(for: "test", with: [:])
        }
        
        // Verify cleanup
        XCTAssertFalse(initialResponseManager.isProcessing)
    }
}