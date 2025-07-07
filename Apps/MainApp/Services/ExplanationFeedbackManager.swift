import Foundation

/// Manager for collecting and processing user feedback on AI explanations.
public class ExplanationFeedbackManager {
    public init() {}
    private var feedbackStore: [String: String] = [:]

    /// Records user feedback for a given explanation key.
    public func recordFeedback(explanationID: String, feedback: String) {
        feedbackStore[explanationID] = feedback
    }

    /// Retrieves feedback for a given explanation.
    public func getFeedback(explanationID: String) -> String? {
        return feedbackStore[explanationID]
    }
} 