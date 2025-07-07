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
    
    func testInitialState() {
        XCTAssertEqual(ai.conversationHistory.count, 0)
        XCTAssertEqual(ai.currentState, .idle)
        XCTAssertEqual(ai.detectedEmotion, .neutral)
        XCTAssertFalse(ai.crisisDetected)
    }
    
    func testProcessUserInputAddsMessages() async {
        await ai.processUserInput("I feel happy today!")
        XCTAssertEqual(ai.conversationHistory.count, 2)
        XCTAssertEqual(ai.conversationHistory.first?.role, .user)
        XCTAssertEqual(ai.conversationHistory.last?.role, .ai)
        XCTAssertEqual(ai.detectedEmotion, .happy)
        XCTAssertFalse(ai.crisisDetected)
        XCTAssertEqual(ai.currentState, .responding)
    }
    
    func testEmotionDetectionSad() async {
        await ai.processUserInput("I am sad and depressed.")
        XCTAssertEqual(ai.detectedEmotion, .sad)
        XCTAssertEqual(ai.currentState, .responding)
    }
    
    func testEmotionDetectionAnxious() async {
        await ai.processUserInput("I'm feeling very anxious and worried.")
        XCTAssertEqual(ai.detectedEmotion, .anxious)
        XCTAssertEqual(ai.currentState, .responding)
    }
    
    func testCrisisDetection() async {
        await ai.processUserInput("I feel like I can't go on.")
        XCTAssertTrue(ai.crisisDetected)
        XCTAssertEqual(ai.currentState, .crisis)
        XCTAssertEqual(ai.conversationHistory.last?.role, .ai)
        XCTAssertTrue(ai.conversationHistory.last?.content.contains("crisis") ?? false)
    }
    
    func testMultiTurnDialogue() async {
        await ai.processUserInput("I feel stressed at work.")
        await ai.processUserInput("Now I'm also feeling anxious.")
        XCTAssertEqual(ai.conversationHistory.count, 4)
        XCTAssertEqual(ai.conversationHistory[0].role, .user)
        XCTAssertEqual(ai.conversationHistory[1].role, .ai)
        XCTAssertEqual(ai.conversationHistory[2].role, .user)
        XCTAssertEqual(ai.conversationHistory[3].role, .ai)
        XCTAssertEqual(ai.detectedEmotion, .anxious)
    }
    
    func testResetConversation() async {
        await ai.processUserInput("I feel happy today!")
        ai.resetConversation()
        XCTAssertEqual(ai.conversationHistory.count, 0)
        XCTAssertEqual(ai.currentState, .idle)
        XCTAssertEqual(ai.detectedEmotion, .neutral)
        XCTAssertFalse(ai.crisisDetected)
    }
    
    func testVoiceInputToggle() {
        ai.setVoiceInput(enabled: true)
        XCTAssertTrue(ai.voiceInputEnabled)
        ai.setVoiceInput(enabled: false)
        XCTAssertFalse(ai.voiceInputEnabled)
    }
    
    func testContextManagerCrisis() async {
        await ai.processUserInput("I'm very anxious.")
        // The context manager should mark isCrisis true if anxious
        let contextManager = Mirror(reflecting: ai).children.first { $0.label == "contextManager" }?.value as? AnyObject
        let getContext = contextManager?.perform(Selector(("getCurrentContextWithHistory:")), with: ai.conversationHistory)
        // This is a stub, but in a real test, we'd check context.isCrisis == true
    }
} 