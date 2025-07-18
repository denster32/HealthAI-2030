import Foundation
import SwiftUI
import HealthAI2030Core
import ConversationalAI
import HealthReasoningEngine
import HealthMetrics

/// Advanced AI Health Coach with conversational interface and personalized guidance
@MainActor
public class AIHealthCoach: ObservableObject {
    public static let shared = AIHealthCoach()
    
    @Published public private(set) var isAvailable = false
    @Published public private(set) var currentConversation: HealthConversation?
    @Published public private(set) var coachPersonality: CoachPersonality = .supportive
    @Published public private(set) var userProfile: UserHealthProfile?
    @Published public private(set) var activeGoals: [HealthGoal] = []
    
    private var conversationalEngine: ConversationalAIEngine
    private var reasoningEngine: HealthReasoningEngine
    private var personalityAdjuster: PersonalityAdjustmentEngine
    private var goalTracker: HealthGoalTracker
    private var contextManager: ConversationContextManager
    
    public enum CoachPersonality: String, CaseIterable, Sendable {
        case supportive = "supportive"
        case motivational = "motivational"
        case analytical = "analytical"
        case gentle = "gentle"
        case scientific = "scientific"
        case friend = "friend"
        
        public var displayName: String {
            switch self {
            case .supportive: return "Supportive"
            case .motivational: return "Motivational"
            case .analytical: return "Analytical"
            case .gentle: return "Gentle"
            case .scientific: return "Scientific"
            case .friend: return "Friendly"
            }
        }
        
        public var description: String {
            switch self {
            case .supportive: return "Encouraging and understanding, focuses on positive reinforcement"
            case .motivational: return "Energetic and challenging, pushes you to achieve your best"
            case .analytical: return "Data-driven and precise, provides detailed insights and reasoning"
            case .gentle: return "Calm and patient, takes a soft approach to guidance"
            case .scientific: return "Evidence-based and educational, explains the science behind recommendations"
            case .friend: return "Casual and relatable, like talking to a knowledgeable friend"
            }
        }
    }
    
    private init() {
        self.conversationalEngine = ConversationalAIEngine()
        self.reasoningEngine = HealthReasoningEngine()
        self.personalityAdjuster = PersonalityAdjustmentEngine()
        self.goalTracker = HealthGoalTracker()
        self.contextManager = ConversationContextManager()
        
        initializeAICoach()
    }
    
    // MARK: - Public Interface
    
    /// Start a new health conversation
    public func startConversation(topic: ConversationTopic? = nil) async throws {
        guard isAvailable else {
            throw AICoachError.serviceUnavailable
        }
        
        // Create new conversation context
        let conversation = HealthConversation(
            id: UUID(),
            topic: topic,
            startTime: Date(),
            personality: coachPersonality,
            userProfile: userProfile
        )
        
        currentConversation = conversation
        
        // Initialize conversation with contextual greeting
        let greeting = await generateContextualGreeting(topic: topic)
        await addMessage(greeting, from: .coach)
    }
    
    /// Send a message to the AI coach
    public func sendMessage(_ content: String) async throws -> AICoachResponse {
        guard let conversation = currentConversation else {
            throw AICoachError.noActiveConversation
        }
        
        // Add user message to conversation
        let userMessage = ConversationMessage(
            content: content,
            sender: .user,
            timestamp: Date()
        )
        
        await addMessage(userMessage, from: .user)
        
        // Process message through reasoning engine
        let context = await contextManager.buildContext(
            conversation: conversation,
            userProfile: userProfile,
            recentHealthData: await getRecentHealthData()
        )
        
        let reasoning = await reasoningEngine.analyzeMessage(
            content,
            context: context
        )
        
        // Generate response through conversational engine
        let response = await conversationalEngine.generateResponse(
            to: content,
            reasoning: reasoning,
            personality: coachPersonality,
            context: context
        )
        
        // Add coach response to conversation
        let coachMessage = ConversationMessage(
            content: response.content,
            sender: .coach,
            timestamp: Date(),
            reasoning: reasoning,
            suggestions: response.suggestions,
            actionItems: response.actionItems
        )
        
        await addMessage(coachMessage, from: .coach)
        
        // Update goals if relevant
        if let goalUpdates = response.goalUpdates {
            await updateGoals(goalUpdates)
        }
        
        return AICoachResponse(
            message: coachMessage,
            confidence: response.confidence,
            followUpQuestions: response.followUpQuestions,
            healthInsights: response.healthInsights
        )
    }
    
    /// Ask the coach for proactive insights
    public func getProactiveInsights() async -> [ProactiveInsight] {
        guard let userProfile = userProfile else { return [] }
        
        let recentData = await getRecentHealthData()
        let context = ConversationContext(
            userProfile: userProfile,
            recentHealthData: recentData,
            activeGoals: activeGoals,
            timeOfDay: Date(),
            conversationHistory: currentConversation?.messages ?? []
        )
        
        return await reasoningEngine.generateProactiveInsights(context: context)
    }
    
    /// Set coach personality
    public func setPersonality(_ personality: CoachPersonality) async {
        coachPersonality = personality
        
        // Adjust ongoing conversation if active
        if let conversation = currentConversation {
            await personalityAdjuster.adjustConversation(
                conversation,
                to: personality
            )
        }
    }
    
    /// Update user health profile
    public func updateUserProfile(_ profile: UserHealthProfile) async {
        userProfile = profile
        
        // Update conversational context
        await contextManager.updateUserProfile(profile)
        
        // Regenerate active goals based on new profile
        await refreshHealthGoals()
    }
    
    /// End current conversation
    public func endConversation() async {
        guard let conversation = currentConversation else { return }
        
        // Generate conversation summary
        let summary = await generateConversationSummary(conversation)
        
        // Store conversation for future context
        await contextManager.storeConversation(conversation, summary: summary)
        
        currentConversation = nil
    }
    
    // MARK: - Goal Management
    
    /// Create a new health goal
    public func createHealthGoal(_ goal: HealthGoal) async {
        activeGoals.append(goal)
        await goalTracker.addGoal(goal)
        
        // Provide coaching on the new goal
        if let conversation = currentConversation {
            let goalGuidance = await generateGoalGuidance(goal)
            await addMessage(goalGuidance, from: .coach)
        }
    }
    
    /// Update goal progress
    public func updateGoalProgress(_ goalId: UUID, progress: Double) async {
        guard let goalIndex = activeGoals.firstIndex(where: { $0.id == goalId }) else { return }
        
        activeGoals[goalIndex].currentProgress = progress
        await goalTracker.updateProgress(goalId, progress: progress)
        
        // Provide motivational feedback
        let feedback = await generateProgressFeedback(activeGoals[goalIndex])
        if let conversation = currentConversation {
            await addMessage(feedback, from: .coach)
        }
    }
    
    // MARK: - Private Implementation
    
    private func initializeAICoach() {
        Task {
            do {
                await conversationalEngine.initialize()
                await reasoningEngine.loadHealthKnowledge()
                isAvailable = true
            } catch {
                print("Failed to initialize AI Coach: \(error)")
                isAvailable = false
            }
        }
    }
    
    private func generateContextualGreeting(topic: ConversationTopic?) async -> ConversationMessage {
        let timeOfDay = getTimeOfDay()
        let recentData = await getRecentHealthData()
        
        var greeting = ""
        
        // Time-based greeting
        switch timeOfDay {
        case .morning:
            greeting = "Good morning! "
        case .afternoon:
            greeting = "Good afternoon! "
        case .evening:
            greeting = "Good evening! "
        case .night:
            greeting = "Hello! "
        }
        
        // Personality-based greeting continuation
        switch coachPersonality {
        case .supportive:
            greeting += "I'm here to support you on your health journey. "
        case .motivational:
            greeting += "Ready to crush some health goals today? "
        case .analytical:
            greeting += "Let's analyze your health data and optimize your wellbeing. "
        case .gentle:
            greeting += "How are you feeling today? I'm here to help. "
        case .scientific:
            greeting += "Let's explore the science behind optimal health. "
        case .friend:
            greeting += "Hey there! What's going on with your health today? "
        }
        
        // Topic-specific greeting
        if let topic = topic {
            switch topic {
            case .sleep:
                greeting += "I see you want to talk about sleep. How has your sleep been lately?"
            case .exercise:
                greeting += "Let's discuss your fitness journey. What's your current activity level?"
            case .nutrition:
                greeting += "Nutrition is so important! What are your eating patterns like?"
            case .stress:
                greeting += "Stress management is crucial for wellbeing. How are you handling stress?"
            case .general:
                greeting += "What aspect of your health would you like to focus on today?"
            }
        } else {
            // Add insight based on recent health data
            if let insight = await generateQuickInsight(recentData) {
                greeting += insight
            } else {
                greeting += "What would you like to discuss about your health today?"
            }
        }
        
        return ConversationMessage(
            content: greeting,
            sender: .coach,
            timestamp: Date()
        )
    }
    
    private func addMessage(_ message: ConversationMessage, from sender: MessageSender) async {
        guard var conversation = currentConversation else { return }
        
        conversation.messages.append(message)
        currentConversation = conversation
        
        // Update conversation context
        await contextManager.updateContext(with: message)
    }
    
    private func getRecentHealthData() async -> [HealthMetric] {
        // Get recent health metrics from the last 24 hours
        let dayAgo = Date().addingTimeInterval(-24 * 3600)
        
        // This would integrate with MetricsAnalyticsEngine
        // For now, return empty array
        return []
    }
    
    private func getTimeOfDay() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
    
    private func generateQuickInsight(_ healthData: [HealthMetric]) async -> String? {
        guard !healthData.isEmpty else { return nil }
        
        // Generate a quick insight based on recent data
        if let heartRate = healthData.first(where: { $0.type == .heartRate }) {
            if heartRate.value > 100 {
                return "I noticed your heart rate has been elevated recently. "
            } else if heartRate.value < 60 {
                return "Your resting heart rate looks really good! "
            }
        }
        
        return nil
    }
    
    private func generateConversationSummary(_ conversation: HealthConversation) async -> ConversationSummary {
        let keyPoints = await conversationalEngine.extractKeyPoints(conversation.messages)
        let insights = await reasoningEngine.generateConversationInsights(conversation)
        let actionItems = conversation.messages.flatMap { $0.actionItems ?? [] }
        
        return ConversationSummary(
            conversationId: conversation.id,
            startTime: conversation.startTime,
            endTime: Date(),
            topic: conversation.topic,
            keyPoints: keyPoints,
            insights: insights,
            actionItems: actionItems,
            userSatisfaction: nil // Would be collected from user feedback
        )
    }
    
    private func generateGoalGuidance(_ goal: HealthGoal) async -> ConversationMessage {
        let guidance = await reasoningEngine.generateGoalGuidance(goal, personality: coachPersonality)
        
        return ConversationMessage(
            content: guidance.content,
            sender: .coach,
            timestamp: Date(),
            suggestions: guidance.suggestions,
            actionItems: guidance.actionItems
        )
    }
    
    private func generateProgressFeedback(_ goal: HealthGoal) async -> ConversationMessage {
        let feedback = await reasoningEngine.generateProgressFeedback(goal, personality: coachPersonality)
        
        return ConversationMessage(
            content: feedback.content,
            sender: .coach,
            timestamp: Date(),
            suggestions: feedback.suggestions
        )
    }
    
    private func updateGoals(_ updates: [GoalUpdate]) async {
        for update in updates {
            if let goalIndex = activeGoals.firstIndex(where: { $0.id == update.goalId }) {
                activeGoals[goalIndex].applyUpdate(update)
                await goalTracker.updateGoal(activeGoals[goalIndex])
            }
        }
    }
    
    private func refreshHealthGoals() async {
        guard let profile = userProfile else { return }
        
        // Generate personalized health goals based on profile
        let suggestedGoals = await reasoningEngine.generatePersonalizedGoals(profile)
        
        // Add new goals that aren't already active
        for goal in suggestedGoals {
            if !activeGoals.contains(where: { $0.type == goal.type }) {
                activeGoals.append(goal)
                await goalTracker.addGoal(goal)
            }
        }
    }
}

// MARK: - Supporting Types

public struct HealthConversation: Identifiable, Sendable {
    public let id: UUID
    public let topic: ConversationTopic?
    public let startTime: Date
    public let personality: AIHealthCoach.CoachPersonality
    public let userProfile: UserHealthProfile?
    public var messages: [ConversationMessage] = []
    
    public var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    public var messageCount: Int {
        messages.count
    }
}

public struct ConversationMessage: Identifiable, Sendable {
    public let id = UUID()
    public let content: String
    public let sender: MessageSender
    public let timestamp: Date
    public let reasoning: HealthReasoning?
    public let suggestions: [HealthSuggestion]?
    public let actionItems: [ActionItem]?
    
    public init(
        content: String,
        sender: MessageSender,
        timestamp: Date,
        reasoning: HealthReasoning? = nil,
        suggestions: [HealthSuggestion]? = nil,
        actionItems: [ActionItem]? = nil
    ) {
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
        self.reasoning = reasoning
        self.suggestions = suggestions
        self.actionItems = actionItems
    }
}

public enum MessageSender: String, Sendable {
    case user = "user"
    case coach = "coach"
    case system = "system"
}

public enum ConversationTopic: String, CaseIterable, Sendable {
    case sleep = "sleep"
    case exercise = "exercise"
    case nutrition = "nutrition"
    case stress = "stress"
    case general = "general"
    
    public var displayName: String {
        switch self {
        case .sleep: return "Sleep"
        case .exercise: return "Exercise"
        case .nutrition: return "Nutrition"
        case .stress: return "Stress"
        case .general: return "General Health"
        }
    }
}

public enum TimeOfDay: Sendable {
    case morning
    case afternoon
    case evening
    case night
}

public struct AICoachResponse: Sendable {
    public let message: ConversationMessage
    public let confidence: Double
    public let followUpQuestions: [String]
    public let healthInsights: [HealthInsight]
}

public struct ProactiveInsight: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let content: String
    public let priority: Priority
    public let category: Category
    public let actionItems: [ActionItem]
    public let timestamp: Date
    
    public enum Priority: Int, Sendable {
        case low = 1
        case medium = 2
        case high = 3
        case urgent = 4
    }
    
    public enum Category: String, Sendable {
        case trending = "trending"
        case anomaly = "anomaly"
        case opportunity = "opportunity"
        case reminder = "reminder"
        case celebration = "celebration"
    }
}

public struct UserHealthProfile: Sendable {
    public let age: Int
    public let gender: Gender
    public let healthGoals: [String]
    public let medicalConditions: [String]
    public let medications: [String]
    public let preferences: HealthPreferences
    public let activityLevel: ActivityLevel
    
    public enum Gender: String, Sendable {
        case male = "male"
        case female = "female"
        case other = "other"
        case preferNotToSay = "prefer_not_to_say"
    }
    
    public enum ActivityLevel: String, Sendable {
        case sedentary = "sedentary"
        case lightlyActive = "lightly_active"
        case moderatelyActive = "moderately_active"
        case veryActive = "very_active"
        case extremelyActive = "extremely_active"
    }
}

public struct HealthPreferences: Sendable {
    public let preferredCoachingStyle: AIHealthCoach.CoachPersonality
    public let communicationFrequency: CommunicationFrequency
    public let focusAreas: [ConversationTopic]
    public let notificationPreferences: NotificationPreferences
    
    public enum CommunicationFrequency: String, Sendable {
        case minimal = "minimal"
        case weekly = "weekly"
        case daily = "daily"
        case realTime = "real_time"
    }
}

public struct NotificationPreferences: Sendable {
    public let enableProactiveInsights: Bool
    public let enableGoalReminders: Bool
    public let enableHealthAlerts: Bool
    public let quietHours: ClosedRange<Int>? // Hour range (e.g., 22...7)
}

public struct HealthGoal: Identifiable, Sendable {
    public let id = UUID()
    public let type: GoalType
    public let title: String
    public let description: String
    public let targetValue: Double
    public let currentProgress: Double
    public let unit: String
    public let deadline: Date?
    public let createdAt: Date
    
    public enum GoalType: String, CaseIterable, Sendable {
        case weightLoss = "weight_loss"
        case fitnessImprovement = "fitness_improvement"
        case sleepQuality = "sleep_quality"
        case stressReduction = "stress_reduction"
        case nutrition = "nutrition"
        case heartHealth = "heart_health"
        case mindfulness = "mindfulness"
        case customGoal = "custom"
    }
    
    public var progressPercentage: Double {
        min(100, max(0, (currentProgress / targetValue) * 100))
    }
    
    public mutating func applyUpdate(_ update: GoalUpdate) {
        // Apply goal update logic
    }
}

public struct GoalUpdate: Sendable {
    public let goalId: UUID
    public let progressDelta: Double?
    public let newTargetValue: Double?
    public let newDeadline: Date?
    public let notes: String?
}

public struct ConversationSummary: Sendable {
    public let conversationId: UUID
    public let startTime: Date
    public let endTime: Date
    public let topic: ConversationTopic?
    public let keyPoints: [String]
    public let insights: [HealthInsight]
    public let actionItems: [ActionItem]
    public let userSatisfaction: Double?
}

public struct HealthSuggestion: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let category: Category
    public let evidenceLevel: EvidenceLevel
    
    public enum Category: String, Sendable {
        case lifestyle = "lifestyle"
        case exercise = "exercise"
        case nutrition = "nutrition"
        case sleep = "sleep"
        case medical = "medical"
        case mental = "mental"
    }
    
    public enum EvidenceLevel: String, Sendable {
        case high = "high"
        case medium = "medium"
        case low = "low"
        case anecdotal = "anecdotal"
    }
}

public struct ActionItem: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let priority: Priority
    public let estimatedTimeMinutes: Int?
    public let dueDate: Date?
    
    public enum Priority: Int, Sendable {
        case low = 1
        case medium = 2
        case high = 3
        case urgent = 4
    }
}

public struct HealthInsight: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let content: String
    public let confidence: Double
    public let category: Category
    public let supportingData: [String]
    
    public enum Category: String, Sendable {
        case pattern = "pattern"
        case correlation = "correlation"
        case prediction = "prediction"
        case recommendation = "recommendation"
    }
}

// MARK: - Error Types

public enum AICoachError: Error, LocalizedError, Sendable {
    case serviceUnavailable
    case noActiveConversation
    case invalidInput(String)
    case reasoningFailed(String)
    case profileNotSet
    
    public var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "AI Health Coach is currently unavailable"
        case .noActiveConversation:
            return "No active conversation to send message to"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .reasoningFailed(let message):
            return "Health reasoning failed: \(message)"
        case .profileNotSet:
            return "User health profile must be set before coaching"
        }
    }
}

// MARK: - AI Coach View

public struct AIHealthCoachView: View {
    @StateObject private var coach = AIHealthCoach.shared
    @State private var messageText = ""
    @State private var isTyping = false
    @State private var showingPersonalitySelector = false
    @State private var showingTopicSelector = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack {
                if let conversation = coach.currentConversation {
                    // Conversation View
                    ConversationView(
                        conversation: conversation,
                        isTyping: isTyping
                    )
                    
                    // Message Input
                    MessageInputView(
                        text: $messageText,
                        isEnabled: coach.isAvailable && !isTyping,
                        onSend: sendMessage
                    )
                    
                } else {
                    // Welcome View
                    WelcomeView(
                        personality: coach.coachPersonality,
                        onStartConversation: startConversation,
                        onShowPersonalitySelector: { showingPersonalitySelector = true },
                        onShowTopicSelector: { showingTopicSelector = true }
                    )
                }
            }
            .navigationTitle("AI Health Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if coach.currentConversation != nil {
                        Button("End") {
                            endConversation()
                        }
                    }
                    
                    Button("Settings") {
                        showingPersonalitySelector = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingPersonalitySelector) {
            PersonalitySelectorView(
                selectedPersonality: coach.coachPersonality,
                onSelect: { personality in
                    Task {
                        await coach.setPersonality(personality)
                    }
                }
            )
        }
        .sheet(isPresented: $showingTopicSelector) {
            TopicSelectorView(
                onSelect: { topic in
                    Task {
                        try? await coach.startConversation(topic: topic)
                    }
                }
            )
        }
    }
    
    private func startConversation() {
        Task {
            try? await coach.startConversation()
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = messageText
        messageText = ""
        isTyping = true
        
        Task {
            do {
                let _ = try await coach.sendMessage(message)
            } catch {
                print("Error sending message: \(error)")
            }
            isTyping = false
        }
    }
    
    private func endConversation() {
        Task {
            await coach.endConversation()
        }
    }
}

// MARK: - Supporting Views

struct ConversationView: View {
    let conversation: HealthConversation
    let isTyping: Bool
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(conversation.messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                    
                    if isTyping {
                        TypingIndicatorView()
                    }
                }
                .padding()
            }
            .onChange(of: conversation.messages.count) { _, _ in
                if let lastMessage = conversation.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct MessageBubbleView: View {
    let message: ConversationMessage
    
    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer()
            }
            
            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(bubbleColor)
                    .foregroundStyle(textColor)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                
                if let suggestions = message.suggestions, !suggestions.isEmpty {
                    SuggestionsView(suggestions: suggestions)
                }
                
                if let actionItems = message.actionItems, !actionItems.isEmpty {
                    ActionItemsView(actionItems: actionItems)
                }
                
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 280, alignment: message.sender == .user ? .trailing : .leading)
            
            if message.sender == .coach {
                Spacer()
            }
        }
    }
    
    private var bubbleColor: Color {
        message.sender == .user ? .blue : .gray.opacity(0.2)
    }
    
    private var textColor: Color {
        message.sender == .user ? .white : .primary
    }
}

struct SuggestionsView: View {
    let suggestions: [HealthSuggestion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(suggestions.prefix(3)) { suggestion in
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    
                    Text(suggestion.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
    }
}

struct ActionItemsView: View {
    let actionItems: [ActionItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(actionItems.prefix(3)) { item in
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.green)
                        .font(.caption)
                    
                    Text(item.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(.gray)
                        .frame(width: 6, height: 6)
                        .scaleEffect(animationPhase == index ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Spacer()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

struct MessageInputView: View {
    @Binding var text: String
    let isEnabled: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .disabled(!isEnabled)
                .onSubmit {
                    if isEnabled {
                        onSend()
                    }
                }
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSend ? .blue : .gray)
            }
            .disabled(!canSend)
        }
        .padding()
    }
    
    private var canSend: Bool {
        isEnabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct WelcomeView: View {
    let personality: AIHealthCoach.CoachPersonality
    let onStartConversation: () -> Void
    let onShowPersonalitySelector: () -> Void
    let onShowTopicSelector: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("AI Health Coach")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your personalized health companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                Text("Current Personality: \(personality.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button("Change Personality") {
                    onShowPersonalitySelector()
                }
                .buttonStyle(.bordered)
            }
            
            VStack(spacing: 16) {
                Button("Start General Chat") {
                    onStartConversation()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("Choose Topic") {
                    onShowTopicSelector()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

struct PersonalitySelectorView: View {
    let selectedPersonality: AIHealthCoach.CoachPersonality
    let onSelect: (AIHealthCoach.CoachPersonality) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(AIHealthCoach.CoachPersonality.allCases, id: \.self) { personality in
                PersonalityRow(
                    personality: personality,
                    isSelected: personality == selectedPersonality
                ) {
                    onSelect(personality)
                    dismiss()
                }
            }
            .navigationTitle("Coach Personality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PersonalityRow: View {
    let personality: AIHealthCoach.CoachPersonality
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(personality.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                
                Text(personality.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct TopicSelectorView: View {
    let onSelect: (ConversationTopic) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(ConversationTopic.allCases, id: \.self) { topic in
                Button(topic.displayName) {
                    onSelect(topic)
                    dismiss()
                }
            }
            .navigationTitle("Choose Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}