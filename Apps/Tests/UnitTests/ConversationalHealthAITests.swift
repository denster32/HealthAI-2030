import XCTest
@testable import HealthAI2030

@available(iOS 17.0, *)
final class ConversationalHealthAITests: XCTestCase {
    var ai: ConversationalHealthAI!
    
    override func setUpWithError() throws {
        ai = ConversationalHealthAI()
    }
    
    override func tearDownWithError() throws {
        ai = nil
    }
    
    func testProcessUserMessageAddsToHistory() async {
        await ai.processUserMessage("I want to improve my sleep.")
        XCTAssertEqual(ai.conversationHistory.count, 2) // user + AI
        XCTAssertEqual(ai.conversationHistory.first?.role, .user)
        XCTAssertEqual(ai.conversationHistory.last?.role, .ai)
    }
    
    func testEmotionAnalysisHappy() async {
        await ai.processUserMessage("I feel great today!")
        XCTAssertEqual(ai.currentEmotion, .happy)
    }
    
    func testEmotionAnalysisSad() async {
        await ai.processUserMessage("I feel sad and tired.")
        XCTAssertEqual(ai.currentEmotion, .sad)
    }
    
    func testCrisisDetection() async {
        await ai.processUserMessage("I feel like I can't go on.")
        XCTAssertTrue(ai.isCrisisDetected)
        XCTAssertTrue(ai.conversationHistory.last?.content.contains("mental health professional") ?? false)
    }
    
    func testContextMaintainsHistory() async {
        await ai.processUserMessage("How can I eat healthier?")
        await ai.processUserMessage("And what about exercise?")
        XCTAssertEqual(ai.conversationHistory.count, 4)
        // Context should have all messages
        let context = ai.value(forKey: "context") as? ConversationContext
        XCTAssertEqual(context?.messages.count, 4)
    }
    
    func testResetConversation() async {
        await ai.processUserMessage("Hello")
        ai.resetConversation()
        XCTAssertTrue(ai.conversationHistory.isEmpty)
        XCTAssertEqual(ai.currentEmotion, .neutral)
        XCTAssertFalse(ai.isCrisisDetected)
    }
} 