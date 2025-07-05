import Foundation
import SwiftData
import UserNotifications

/// Engine to route chat/LLM queries to Copilot Skills and aggregate responses
public class CopilotSkillChatEngine: ObservableObject {
    public static let shared = CopilotSkillChatEngine()
    @Published public var chatHistory: [ChatMessage] = []
    private let registry = HealthCopilotSkillRegistry.shared
    private var chatModelContext: ModelContext? = try? ModelContext(for: CopilotChatMessage.self)
    private let analytics = DeepHealthAnalytics.shared
    private let arVisualizer = ARHealthVisualizer()

    private init() {
        loadChatHistory()
    }

    public func sendUserMessage(_ text: String, context: HealthCopilotContext) async {
        let userMsg = ChatMessage(role: .user, content: text)
        await MainActor.run { self.chatHistory.append(userMsg) }
        saveChatMessage(role: "user", content: text)
        let (intent, params) = CopilotSkillChatEngine.extractIntent(from: text)
        let results = await registry.handleAll(intent: intent, parameters: params, context: context)
        for result in results {
            let reply = CopilotSkillChatEngine.formatResult(result)
            await MainActor.run { self.chatHistory.append(ChatMessage(role: .copilot, content: reply)) }
            saveChatMessage(role: "copilot", content: reply)
            routeResultToAnalyticsAndNotifications(result)
        }
    }

    private func routeResultToAnalyticsAndNotifications(_ result: HealthCopilotSkillResult) {
        switch result {
        case .json(let obj):
            // Example: If result contains a trend or prediction, update analytics
            if let trend = obj["trend"] as? [String: Any],
               let metric = trend["metric"] as? String,
               let direction = trend["direction"] as? String,
               let confidence = trend["confidence"] as? Double {
                let t = HealthTrend(metric: metric, direction: direction, confidence: confidence)
                analytics.trends.append(t)
            }
            if let prediction = obj["prediction"] as? [String: Any],
               let event = prediction["event"] as? String,
               let probability = prediction["probability"] as? Double,
               let timeframe = prediction["timeframe"] as? String {
                let p = HealthPrediction(event: event, probability: probability, timeframe: timeframe)
                analytics.predictions.append(p)
            }
            // Example: If result is urgent, trigger notification
            if let urgent = obj["urgent"] as? Bool, urgent {
                triggerNotification(title: "Health Alert", body: obj["message"] as? String ?? "Important health update.")
            }
        case .text(let str):
            // Simple keyword-based notification (example)
            if str.lowercased().contains("urgent") || str.lowercased().contains("alert") {
                triggerNotification(title: "Health Alert", body: str)
            }
        default: break
        }
        arVisualizer.updateWithSkillResult(result)
    }

    private func triggerNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func saveChatMessage(role: String, content: String) {
        guard let context = chatModelContext else { return }
        let msg = CopilotChatMessage(role: role, content: content)
        context.insert(msg)
        try? context.save()
    }

    public func loadChatHistory() {
        guard let context = chatModelContext else { return }
        let messages = (try? context.fetch(CopilotChatMessage.self)) ?? []
        self.chatHistory = messages.map { ChatMessage(role: $0.role == "user" ? .user : .copilot, content: $0.content) }
    }

    public static func extractIntent(from text: String) -> (String, [String: Any]) {
        // Simple keyword-based intent extraction (replace with LLM/NLU)
        let lower = text.lowercased()
        if lower.contains("sleep") { return ("analyze_sleep", [:]) }
        if lower.contains("steps") { return ("get_steps", [:]) }
        if lower.contains("medication") && lower.contains("interaction") { return ("check_interactions", ["medications": ["warfarin", "aspirin"]]) }
        if lower.contains("why") { return ("explain_recommendation", ["recommendation": "Increase sleep", "cause": "Low REM", "evidence": "Stanford study 2024"]) }
        return ("analyze_sleep", [:])
    }

    public static func formatResult(_ result: HealthCopilotSkillResult) -> String {
        switch result {
        case .text(let str): return str
        case .markdown(let md): return md
        case .json(let obj): return String(describing: obj)
        case .error(let err): return "Error: \(err)"
        }
    }
}

public struct ChatMessage: Identifiable {
    public enum Role { case user, copilot }
    public let id = UUID()
    public let role: Role
    public let content: String
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}
