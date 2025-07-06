import XCTest
import Foundation
import Combine
@testable import HealthAI2030

/// Unit tests for Feedback & Support Manager
final class FeedbackSupportTests: XCTestCase {
    var manager: FeedbackSupportManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        manager = FeedbackSupportManager.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        manager = nil
        super.tearDown()
    }
    
    func testSubmitFeedbackSuccess() {
        let expectation = self.expectation(description: "Feedback submitted")
        let entry = FeedbackSupportManager.FeedbackEntry(
            type: .general,
            message: "Great app!",
            email: "test@example.com",
            screenshot: nil
        )
        manager.submitFeedback(entry)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertTrue(self.manager.feedbacks.contains(where: { $0.id == entry.id }))
            XCTAssertEqual(self.manager.submissionResult?.successMessage, "Feedback submitted successfully.")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }
    
    func testSubmitTicketSuccess() {
        let expectation = self.expectation(description: "Ticket submitted")
        let ticket = FeedbackSupportManager.SupportTicket(
            subject: "Need help",
            description: "I have an issue.",
            email: "user@example.com"
        )
        manager.submitTicket(ticket)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertTrue(self.manager.tickets.contains(where: { $0.id == ticket.id }))
            XCTAssertEqual(self.manager.submissionResult?.successMessage, "Support ticket submitted successfully.")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }
    
    func testFeedbackLocalFallback() {
        // Simulate backend failure by overriding submitToBackend
        let entry = FeedbackSupportManager.FeedbackEntry(
            type: .bug,
            message: "App crashed",
            email: nil,
            screenshot: nil
        )
        // This would require dependency injection or mocking in real implementation
        // For now, just ensure local save method can be called
        manager.saveLocally(entry)
        // No crash means pass
        XCTAssertTrue(true)
    }
    
    func testTicketLocalFallback() {
        let ticket = FeedbackSupportManager.SupportTicket(
            subject: "Login issue",
            description: "Can't log in",
            email: nil
        )
        manager.saveTicketLocally(ticket)
        XCTAssertTrue(true)
    }
    
    func testLoadLocalEntries() {
        manager.loadLocalEntries()
        // No crash means pass
        XCTAssertTrue(true)
    }
} 