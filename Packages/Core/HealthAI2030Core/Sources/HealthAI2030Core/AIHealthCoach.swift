import Foundation
import Combine
import HealthKit // Assuming HealthData uses HealthKit types or similar

/// AIHealthCoach: Personalized, conversational health assistant
@MainActor
class AIHealthCoach: ObservableObject {
    static let shared = AIHealthCoach()
    @Published var conversation: [AIMessage] = []
    @Published var currentPlan: HealthPlan?
    
    private let nlpEngine = HealthAINLPEngine()
    private let healthDataManager = HealthDataManager.shared
    // Note: ExplainableAI functionality integrated into coach logic
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

struct Explanation {
    let reasoning: String
    let confidence: Double
    let sources: [String]
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

