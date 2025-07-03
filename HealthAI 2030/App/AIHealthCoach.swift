import Foundation
import Combine

/// AIHealthCoach: Personalized, conversational health assistant
class AIHealthCoach: ObservableObject {
    static let shared = AIHealthCoach()
    @Published var conversation: [AIMessage] = []
    @Published var currentPlan: HealthPlan?
    
    private let nlpEngine = HealthAINLPEngine()
    private let healthDataManager = HealthDataManager.shared
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
        let response = nlpEngine.generateResponse(for: text, context: conversation)
        conversation.append(AIMessage(role: .coach, content: response))
    }
    
    private func proactiveNudge(for data: HealthData?) {
        guard let data = data else { return }
        // Example: If stress is high, suggest a break
        if data.stressLevel > 0.7 {
            let msg = "I'm noticing your stress is elevated. Would you like a quick breathing exercise or a walk?"
            conversation.append(AIMessage(role: .coach, content: msg))
        }
    }
}

struct AIMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    enum Role { case user, coach }
}

struct HealthPlan {
    let title: String
    let steps: [String]
    let startDate: Date
    let endDate: Date
}

class HealthAINLPEngine {
    func generateResponse(for input: String, context: [AIMessage]) -> String {
        // Placeholder: Integrate with on-device Core ML or cloud NLP
        if input.lowercased().contains("sleep") {
            return "Improving your sleep is a great goal! Try winding down 30 minutes before bed."
        }
        return "Let's work on your health goals together!"
    }
}
