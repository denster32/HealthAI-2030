import Foundation
import Combine

/// Feedback & Support Manager for HealthAI 2030
/// Handles user feedback, bug reports, and support ticketing with backend integration and local fallback
public class FeedbackSupportManager: ObservableObject {
    public static let shared = FeedbackSupportManager()
    
    @Published public var feedbacks: [FeedbackEntry] = []
    @Published public var tickets: [SupportTicket] = []
    @Published public var isSubmitting: Bool = false
    @Published public var submissionResult: SubmissionResult?
    
    private let backendURL = URL(string: "https://api.healthai2030.com/support")!
    private let localStorageKey = "local_feedback_support_entries"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Feedback Entry
    public struct FeedbackEntry: Identifiable, Codable {
        public let id: String
        public let type: FeedbackType
        public let message: String
        public let email: String?
        public let screenshot: Data?
        public let createdAt: Date
        public let status: FeedbackStatus
        
        public init(id: String = UUID().uuidString, type: FeedbackType, message: String, email: String?, screenshot: Data?, createdAt: Date = Date(), status: FeedbackStatus = .pending) {
            self.id = id
            self.type = type
            self.message = message
            self.email = email
            self.screenshot = screenshot
            self.createdAt = createdAt
            self.status = status
        }
    }
    
    public enum FeedbackType: String, CaseIterable, Codable {
        case general = "General"
        case bug = "Bug Report"
        case suggestion = "Suggestion"
        case support = "Support Request"
    }
    
    public enum FeedbackStatus: String, CaseIterable, Codable {
        case pending = "Pending"
        case submitted = "Submitted"
        case resolved = "Resolved"
        case failed = "Failed"
    }
    
    // MARK: - Support Ticket
    public struct SupportTicket: Identifiable, Codable {
        public let id: String
        public let subject: String
        public let description: String
        public let email: String?
        public let createdAt: Date
        public let status: TicketStatus
        
        public init(id: String = UUID().uuidString, subject: String, description: String, email: String?, createdAt: Date = Date(), status: TicketStatus = .open) {
            self.id = id
            self.subject = subject
            self.description = description
            self.email = email
            self.createdAt = createdAt
            self.status = status
        }
    }
    
    public enum TicketStatus: String, CaseIterable, Codable {
        case open = "Open"
        case inProgress = "In Progress"
        case resolved = "Resolved"
        case closed = "Closed"
    }
    
    public enum SubmissionResult {
        case success(String)
        case failure(String)
    }
    
    // MARK: - Public Methods
    public func submitFeedback(_ entry: FeedbackEntry) {
        isSubmitting = true
        // Try backend submission first
        submitToBackend(entry) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSubmitting = false
                switch result {
                case .success:
                    self?.feedbacks.append(entry)
                    self?.submissionResult = .success("Feedback submitted successfully.")
                case .failure(let error):
                    self?.saveLocally(entry)
                    self?.submissionResult = .failure("Submission failed: \(error). Saved locally.")
                }
            }
        }
    }
    
    public func submitTicket(_ ticket: SupportTicket) {
        isSubmitting = true
        // Try backend submission first
        submitTicketToBackend(ticket) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSubmitting = false
                switch result {
                case .success:
                    self?.tickets.append(ticket)
                    self?.submissionResult = .success("Support ticket submitted successfully.")
                case .failure(let error):
                    self?.saveTicketLocally(ticket)
                    self?.submissionResult = .failure("Submission failed: \(error). Saved locally.")
                }
            }
        }
    }
    
    public func loadLocalEntries() {
        // Load locally saved feedback and tickets
        // Implementation would decode from UserDefaults or file
    }
    
    // MARK: - Private Methods
    private func submitToBackend(_ entry: FeedbackEntry, completion: @escaping (Result<Void, String>) -> Void) {
        // Simulate backend submission (replace with real networking)
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // Simulate success
            completion(.success(()))
        }
    }
    
    private func submitTicketToBackend(_ ticket: SupportTicket, completion: @escaping (Result<Void, String>) -> Void) {
        // Simulate backend submission (replace with real networking)
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            // Simulate success
            completion(.success(()))
        }
    }
    
    private func saveLocally(_ entry: FeedbackEntry) {
        // Save feedback locally for later submission
    }
    
    private func saveTicketLocally(_ ticket: SupportTicket) {
        // Save ticket locally for later submission
    }
} 