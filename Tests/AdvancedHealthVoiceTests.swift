import XCTest
import Foundation
import Combine
@testable import HealthAI2030

@available(iOS 18.0, macOS 15.0, *)
final class AdvancedHealthVoiceTests: XCTestCase {
    
    var voiceEngine: AdvancedHealthVoiceEngine!
    var healthDataManager: HealthDataManager!
    var analyticsEngine: AnalyticsEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        healthDataManager = HealthDataManager.shared
        analyticsEngine = AnalyticsEngine.shared
        voiceEngine = AdvancedHealthVoiceEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        voiceEngine = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testVoiceEngineInitialization() {
        XCTAssertNotNil(voiceEngine)
        XCTAssertNotNil(voiceEngine.healthDataManager)
        XCTAssertNotNil(voiceEngine.analyticsEngine)
    }
    
    func testVoiceEngineConfiguration() {
        XCTAssertEqual(voiceEngine.configuration.speechRecognitionLanguage, "en-US")
        XCTAssertEqual(voiceEngine.configuration.textToSpeechVoice, "en-US-Neural2-F")
        XCTAssertEqual(voiceEngine.configuration.conversationHistoryLimit, 100)
        XCTAssertEqual(voiceEngine.configuration.voiceCommandTimeout, 30.0)
        XCTAssertTrue(voiceEngine.configuration.enableVoiceAnalytics)
        XCTAssertTrue(voiceEngine.configuration.enableConversationalAI)
    }
    
    // MARK: - Voice System Tests
    
    func testStartVoiceSystem() async throws {
        try await voiceEngine.startVoiceSystem()
        XCTAssertTrue(voiceEngine.isVoiceActive)
    }
    
    func testStopVoiceSystem() async throws {
        try await voiceEngine.startVoiceSystem()
        await voiceEngine.stopVoiceSystem()
        XCTAssertFalse(voiceEngine.isVoiceActive)
    }
    
    func testVoiceSystemStatus() async throws {
        XCTAssertFalse(voiceEngine.isVoiceActive)
        try await voiceEngine.startVoiceSystem()
        XCTAssertTrue(voiceEngine.isVoiceActive)
    }
    
    // MARK: - Speech Recognition Tests
    
    func testStartListening() async throws {
        try await voiceEngine.startListening()
        XCTAssertTrue(voiceEngine.isListening)
    }
    
    func testStopListening() async throws {
        try await voiceEngine.startListening()
        await voiceEngine.stopListening()
        XCTAssertFalse(voiceEngine.isListening)
    }
    
    func testSpeechRecognitionResult() async throws {
        let result = try await voiceEngine.processSpeechRecognition("What's my heart rate?")
        XCTAssertNotNil(result)
        XCTAssertEqual(result.transcript, "What's my heart rate?")
        XCTAssertGreaterThan(result.confidence, 0.0)
    }
    
    func testSpeechRecognitionError() async {
        do {
            _ = try await voiceEngine.processSpeechRecognition("")
            XCTFail("Should throw error for empty input")
        } catch {
            XCTAssertTrue(error is VoiceEngineError)
        }
    }
    
    // MARK: - Text-to-Speech Tests
    
    func testSpeakText() async throws {
        try await voiceEngine.speakText("Hello, how can I help you today?")
        XCTAssertTrue(voiceEngine.isSpeaking)
    }
    
    func testStopSpeaking() async throws {
        try await voiceEngine.speakText("Test message")
        await voiceEngine.stopSpeaking()
        XCTAssertFalse(voiceEngine.isSpeaking)
    }
    
    func testSpeakTextWithVoice() async throws {
        try await voiceEngine.speakText("Test message", voice: .male)
        XCTAssertTrue(voiceEngine.isSpeaking)
    }
    
    func testSpeakTextError() async {
        do {
            try await voiceEngine.speakText("")
            XCTFail("Should throw error for empty text")
        } catch {
            XCTAssertTrue(error is VoiceEngineError)
        }
    }
    
    // MARK: - Voice Command Tests
    
    func testProcessVoiceCommand() async throws {
        let response = try await voiceEngine.processVoiceCommand("What's my heart rate?")
        XCTAssertNotNil(response)
        XCTAssertEqual(response.command, "What's my heart rate?")
        XCTAssertNotNil(response.response)
        XCTAssertEqual(response.category, .health)
    }
    
    func testProcessVoiceCommandWithContext() async throws {
        let context = ConversationContext(
            userProfile: UserProfile(id: "test", name: "Test User"),
            healthData: HealthData(),
            conversationHistory: [],
            currentTime: Date()
        )
        
        let response = try await voiceEngine.processVoiceCommand("How am I doing today?", context: context)
        XCTAssertNotNil(response)
        XCTAssertEqual(response.command, "How am I doing today?")
    }
    
    func testGetVoiceCommands() async {
        let commands = await voiceEngine.getVoiceCommands()
        XCTAssertFalse(commands.isEmpty)
        
        let healthCommands = await voiceEngine.getVoiceCommands(category: .health)
        XCTAssertFalse(healthCommands.isEmpty)
        XCTAssertTrue(healthCommands.allSatisfy { $0.category == .health })
    }
    
    func testVoiceCommandCategories() async {
        let categories: [CommandCategory] = [.health, .fitness, .nutrition, .sleep, .meditation]
        
        for category in categories {
            let commands = await voiceEngine.getVoiceCommands(category: category)
            XCTAssertTrue(commands.allSatisfy { $0.category == category })
        }
    }
    
    // MARK: - Conversation Management Tests
    
    func testAddConversationEntry() async {
        let entry = ConversationEntry(
            id: UUID(),
            userInput: "Test input",
            systemResponse: "Test response",
            timestamp: Date(),
            type: .question
        )
        
        await voiceEngine.addConversationEntry(entry)
        let history = await voiceEngine.getConversationHistory()
        XCTAssertTrue(history.contains { $0.id == entry.id })
    }
    
    func testGetConversationHistory() async {
        let history = await voiceEngine.getConversationHistory()
        XCTAssertNotNil(history)
        XCTAssertTrue(history is [ConversationEntry])
    }
    
    func testGetConversationHistoryWithLimit() async {
        let history = await voiceEngine.getConversationHistory(limit: 5)
        XCTAssertLessThanOrEqual(history.count, 5)
    }
    
    func testClearConversationHistory() async {
        await voiceEngine.clearConversationHistory()
        let history = await voiceEngine.getConversationHistory()
        XCTAssertTrue(history.isEmpty)
    }
    
    // MARK: - Voice Coaching Tests
    
    func testStartVoiceCoachingSession() async throws {
        try await voiceEngine.startVoiceCoachingSession(type: .fitness)
        XCTAssertNotNil(voiceEngine.currentCoachingSession)
        XCTAssertEqual(voiceEngine.currentCoachingSession?.type, .fitness)
        XCTAssertEqual(voiceEngine.currentCoachingSession?.status, .active)
    }
    
    func testStopVoiceCoachingSession() async throws {
        try await voiceEngine.startVoiceCoachingSession(type: .fitness)
        try await voiceEngine.stopVoiceCoachingSession()
        XCTAssertEqual(voiceEngine.currentCoachingSession?.status, .completed)
    }
    
    func testGetCoachingSessions() async {
        let sessions = await voiceEngine.getCoachingSessions()
        XCTAssertNotNil(sessions)
        XCTAssertTrue(sessions is [VoiceCoachingSession])
    }
    
    func testGetCoachingSessionsByType() async {
        let fitnessSessions = await voiceEngine.getCoachingSessions(type: .fitness)
        XCTAssertTrue(fitnessSessions.allSatisfy { $0.type == .fitness })
    }
    
    // MARK: - Natural Language Processing Tests
    
    func testProcessNaturalLanguage() async throws {
        let result = try await voiceEngine.processNaturalLanguage("What's my heart rate today?")
        XCTAssertNotNil(result)
        XCTAssertEqual(result.intent, .healthQuery)
        XCTAssertEqual(result.entities.count, 1)
        XCTAssertEqual(result.entities.first?.type, .healthMetric)
        XCTAssertEqual(result.entities.first?.value, "heart rate")
    }
    
    func testProcessNaturalLanguageWithContext() async throws {
        let context = ConversationContext(
            userProfile: UserProfile(id: "test", name: "Test User"),
            healthData: HealthData(),
            conversationHistory: [],
            currentTime: Date()
        )
        
        let result = try await voiceEngine.processNaturalLanguage("How am I doing?", context: context)
        XCTAssertNotNil(result)
        XCTAssertEqual(result.intent, .generalQuery)
    }
    
    // MARK: - Conversational AI Tests
    
    func testGenerateConversationalResponse() async throws {
        let context = ConversationContext(
            userProfile: UserProfile(id: "test", name: "Test User"),
            healthData: HealthData(),
            conversationHistory: [],
            currentTime: Date()
        )
        
        let response = try await voiceEngine.generateConversationalResponse(context: context)
        XCTAssertNotNil(response)
        XCTAssertNotNil(response.response)
        XCTAssertNotNil(response.confidence)
        XCTAssertGreaterThan(response.confidence, 0.0)
    }
    
    func testGenerateConversationalResponseWithHistory() async throws {
        let history = [
            ConversationEntry(
                id: UUID(),
                userInput: "What's my heart rate?",
                systemResponse: "Your heart rate is 72 BPM.",
                timestamp: Date().addingTimeInterval(-3600),
                type: .question
            )
        ]
        
        let context = ConversationContext(
            userProfile: UserProfile(id: "test", name: "Test User"),
            healthData: HealthData(),
            conversationHistory: history,
            currentTime: Date()
        )
        
        let response = try await voiceEngine.generateConversationalResponse(context: context)
        XCTAssertNotNil(response)
    }
    
    // MARK: - Voice Analytics Tests
    
    func testAnalyzeVoicePatterns() async throws {
        let analysis = try await voiceEngine.analyzeVoicePatterns()
        XCTAssertNotNil(analysis)
        XCTAssertNotNil(analysis.usagePatterns)
        XCTAssertNotNil(analysis.insights)
        XCTAssertNotNil(analysis.recommendations)
    }
    
    func testGetVoiceInsights() async {
        let insights = await voiceEngine.getVoiceInsights()
        XCTAssertNotNil(insights)
        XCTAssertTrue(insights is [VoiceInsight])
    }
    
    func testGetVoiceInsightsByType() async {
        let behaviorInsights = await voiceEngine.getVoiceInsights(type: .behavior)
        XCTAssertTrue(behaviorInsights.allSatisfy { $0.type == .behavior })
        
        let healthInsights = await voiceEngine.getVoiceInsights(type: .health)
        XCTAssertTrue(healthInsights.allSatisfy { $0.type == .health })
    }
    
    func testTrackVoiceInteraction() async {
        let interaction = VoiceInteraction(
            id: UUID(),
            command: "What's my heart rate?",
            response: "Your heart rate is 72 BPM.",
            timestamp: Date(),
            duration: 2.5,
            success: true
        )
        
        await voiceEngine.trackVoiceInteraction(interaction)
        let analytics = await voiceEngine.getVoiceAnalytics()
        XCTAssertNotNil(analytics)
    }
    
    // MARK: - Voice Response Generation Tests
    
    func testGenerateVoiceResponse() async throws {
        let context = ConversationContext(
            userProfile: UserProfile(id: "test", name: "Test User"),
            healthData: HealthData(),
            conversationHistory: [],
            currentTime: Date()
        )
        
        let response = try await voiceEngine.generateVoiceResponse(context: context)
        XCTAssertNotNil(response)
        XCTAssertFalse(response.isEmpty)
    }
    
    func testGenerateVoiceResponseForHealthQuery() async throws {
        let context = ConversationContext(
            userProfile: UserProfile(id: "test", name: "Test User"),
            healthData: HealthData(),
            conversationHistory: [],
            currentTime: Date()
        )
        
        let response = try await voiceEngine.generateVoiceResponse(context: context)
        XCTAssertNotNil(response)
    }
    
    // MARK: - Data Export Tests
    
    func testExportVoiceData() async throws {
        let data = try await voiceEngine.exportVoiceData()
        XCTAssertNotNil(data)
        XCTAssertFalse(data.isEmpty)
    }
    
    func testExportVoiceDataAsJSON() async throws {
        let data = try await voiceEngine.exportVoiceData(format: .json)
        XCTAssertNotNil(data)
        
        let jsonString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString?.contains("conversations") ?? false)
    }
    
    func testExportVoiceDataAsCSV() async throws {
        let data = try await voiceEngine.exportVoiceData(format: .csv)
        XCTAssertNotNil(data)
        
        let csvString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(csvString)
        XCTAssertTrue(csvString?.contains(",") ?? false)
    }
    
    // MARK: - Error Handling Tests
    
    func testVoiceEngineErrorHandling() {
        let error = VoiceEngineError.speechRecognitionFailed("Test error")
        XCTAssertEqual(error.localizedDescription, "Speech recognition failed: Test error")
    }
    
    func testInvalidVoiceCommand() async {
        do {
            _ = try await voiceEngine.processVoiceCommand("")
            XCTFail("Should throw error for empty command")
        } catch {
            XCTAssertTrue(error is VoiceEngineError)
        }
    }
    
    func testInvalidSpeechInput() async {
        do {
            _ = try await voiceEngine.processSpeechRecognition("")
            XCTFail("Should throw error for empty speech input")
        } catch {
            XCTAssertTrue(error is VoiceEngineError)
        }
    }
    
    // MARK: - Integration Tests
    
    func testVoiceEngineWithHealthData() async throws {
        // Test integration with health data manager
        let healthData = HealthData()
        let context = ConversationContext(
            userProfile: UserProfile(id: "test", name: "Test User"),
            healthData: healthData,
            conversationHistory: [],
            currentTime: Date()
        )
        
        let response = try await voiceEngine.generateVoiceResponse(context: context)
        XCTAssertNotNil(response)
    }
    
    func testVoiceEngineWithAnalytics() async throws {
        // Test integration with analytics engine
        let interaction = VoiceInteraction(
            id: UUID(),
            command: "Test command",
            response: "Test response",
            timestamp: Date(),
            duration: 1.0,
            success: true
        )
        
        await voiceEngine.trackVoiceInteraction(interaction)
        let analytics = await voiceEngine.getVoiceAnalytics()
        XCTAssertNotNil(analytics)
    }
    
    // MARK: - Performance Tests
    
    func testVoiceCommandProcessingPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Voice command processing")
            
            Task {
                do {
                    _ = try await voiceEngine.processVoiceCommand("What's my heart rate?")
                    expectation.fulfill()
                } catch {
                    XCTFail("Voice command processing failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testConversationResponseGenerationPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Response generation")
            
            Task {
                do {
                    let context = ConversationContext(
                        userProfile: UserProfile(id: "test", name: "Test User"),
                        healthData: HealthData(),
                        conversationHistory: [],
                        currentTime: Date()
                    )
                    
                    _ = try await voiceEngine.generateVoiceResponse(context: context)
                    expectation.fulfill()
                } catch {
                    XCTFail("Response generation failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentVoiceCommands() async throws {
        let commands = [
            "What's my heart rate?",
            "How many steps today?",
            "What should I eat?",
            "How did I sleep?",
            "Start fitness coaching"
        ]
        
        let responses = try await withThrowingTaskGroup(of: VoiceCommandResponse.self) { group in
            for command in commands {
                group.addTask {
                    try await self.voiceEngine.processVoiceCommand(command)
                }
            }
            
            var results: [VoiceCommandResponse] = []
            for try await response in group {
                results.append(response)
            }
            return results
        }
        
        XCTAssertEqual(responses.count, commands.count)
    }
    
    func testConcurrentConversationGeneration() async throws {
        let contexts = (0..<5).map { _ in
            ConversationContext(
                userProfile: UserProfile(id: "test", name: "Test User"),
                healthData: HealthData(),
                conversationHistory: [],
                currentTime: Date()
            )
        }
        
        let responses = try await withThrowingTaskGroup(of: String.self) { group in
            for context in contexts {
                group.addTask {
                    try await self.voiceEngine.generateVoiceResponse(context: context)
                }
            }
            
            var results: [String] = []
            for try await response in group {
                results.append(response)
            }
            return results
        }
        
        XCTAssertEqual(responses.count, contexts.count)
    }
}

// MARK: - Test Helpers

extension AdvancedHealthVoiceTests {
    
    func createMockHealthData() -> HealthData {
        return HealthData(
            heartRate: 72,
            steps: 8500,
            sleepHours: 7.5,
            caloriesBurned: 450,
            waterIntake: 2000,
            stressLevel: 3,
            mood: .good,
            timestamp: Date()
        )
    }
    
    func createMockUserProfile() -> UserProfile {
        return UserProfile(
            id: "test-user",
            name: "Test User",
            age: 30,
            gender: .notSpecified,
            height: 175,
            weight: 70,
            activityLevel: .moderate,
            healthGoals: [.fitness, .nutrition],
            preferences: UserPreferences()
        )
    }
    
    func createMockConversationContext() -> ConversationContext {
        return ConversationContext(
            userProfile: createMockUserProfile(),
            healthData: createMockHealthData(),
            conversationHistory: [],
            currentTime: Date()
        )
    }
} 