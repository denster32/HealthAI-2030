import Foundation
import Combine
import HealthKit // Assuming HealthData uses HealthKit types or similar

/// AIHealthCoach: Personalized, conversational health assistant
class AIHealthCoach: ObservableObject {
    static let shared = AIHealthCoach()
    @Published var conversation: [AIMessage] = []
    @Published var currentPlan: HealthPlan?
    
    private let nlpEngine = HealthAINLPEngine()
    private let healthDataManager = HealthDataManager.shared
    private let explainableAI = ExplainableAI() // Initialize ExplainableAI
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Listen for health data changes and proactively suggest actions
        healthDataManager.$latestHealthData
            .sink { [weak self] data in
                self?.proactiveNudge(for: data)
            }
            .store(in: &cancellables)
    }
    
    func sendUserMessage(_ text: String) {
        let userMsg = AIMessage(role: .user, content: text)
        conversation.append(userMsg)
        
        // For simplicity, let's assume the NLP engine can also provide a recommendation string
        // and some context for explanation. In a real app, this would be more sophisticated.
        let (responseContent, recommendation, healthDataForExplanation) = nlpEngine.generateResponseWithExplanationContext(for: text, context: conversation)
        
        var explanation: Explanation? = nil
        if let rec = recommendation, let hd = healthDataForExplanation {
            explanation = explainableAI.generateExplanation(for: rec, healthData: hd)
        }
        
        conversation.append(AIMessage(role: .coach, content: responseContent, explanation: explanation))
    }
    
    private func proactiveNudge(for data: HealthData?) {
        guard let data = data else { return }
        
        // Convert HealthData to a dictionary for ExplainableAI
        let healthDataDict: [String: Any] = [
            "stressLevel": data.stressLevel,
            "averageSleep": data.sleepDuration, // Assuming sleepDuration is average sleep
            "sleepDuration": data.sleepDuration,
            "heartRateVariability": data.heartRateVariability,
            "activityLevel": data.activityLevel,
            "dailySteps": data.dailySteps
        ]
        
        // Example: If stress is high, suggest a break
        if data.stressLevel > 0.7 {
            let recommendation = "take a break and relax"
            let explanation = explainableAI.generateExplanation(for: recommendation, healthData: healthDataDict)
            let msg = "I'm noticing your stress is elevated. Would you like a quick breathing exercise or a walk?"
            conversation.append(AIMessage(role: .coach, content: msg, explanation: explanation))
        }
        
        // Example: If sleep is low, suggest earlier bedtime
        if data.sleepDuration < 7.0 {
            let recommendation = "earlier bedtime"
            let explanation = explainableAI.generateExplanation(for: recommendation, healthData: healthDataDict)
            let msg = "Your sleep duration has been low recently. We recommend an earlier bedtime."
            conversation.append(AIMessage(role: .coach, content: msg, explanation: explanation))
        }
    }
}

struct AIMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let explanation: Explanation? // Optional explanation for the message

    enum Role { case user, coach }
    
    init(role: Role, content: String, explanation: Explanation? = nil) {
        self.role = role
        self.content = content
        self.explanation = explanation
    }
}

struct HealthPlan {
    let title: String
    let steps: [String]
    let startDate: Date
    let endDate: Date
}

class HealthAINLPEngine {
    // This function now returns the response content, the recommendation string,
    // and a dictionary of health data relevant to that recommendation for explanation.
    func generateResponseWithExplanationContext(for input: String, context: [AIMessage]) -> (String, String?, [String: Any]?) {
        // Placeholder: Integrate with on-device Core ML or cloud NLP
        // For demonstration, we'll simulate some logic.
        if input.lowercased().contains("sleep") {
            let recommendation = "Improving your sleep is a great goal! Try winding down 30 minutes before bed."
            let healthData: [String: Any] = ["averageSleep": 6.5] // Simulate relevant data
            return (recommendation, "earlier bedtime", healthData)
        } else if input.lowercased().contains("activity") {
            let recommendation = "Let's work on increasing your activity! Aim for 7500 steps today."
            let healthData: [String: Any] = ["dailySteps": 4000]
            return (recommendation, "increase daily steps", healthData)
        }
        return ("Let's work on your health goals together!", nil, nil)
    }
}
