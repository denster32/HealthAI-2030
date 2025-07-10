import Foundation
import Combine
import SwiftUI

/// Advanced Health Voice ViewModel
/// Manages voice interaction, conversation history, voice commands, and coaching sessions
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class AdvancedHealthVoiceViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var isVoiceActive = false
    @Published public var isListening = false
    @Published public var isSpeaking = false
    @Published public var conversationHistory: [ConversationEntry] = []
    @Published public var voiceCommands: [VoiceCommand] = []
    @Published public var voiceCoaching: VoiceCoachingSession?
    @Published public var speechRecognition: SpeechRecognitionResult = SpeechRecognitionResult()
    @Published public var naturalLanguageProcessing: NLPResult = NLPResult()
    @Published public var conversationalAI: ConversationalAIResponse = ConversationalAIResponse()
    @Published public var voiceInsights: [VoiceInsight] = []
    @Published public var lastError: String?
    @Published public var voiceProgress: Double = 0.0
    @Published public var isLoading = false
    @Published public var selectedTimeframe: Timeframe = .day
    
    // MARK: - Private Properties
    private var voiceEngine: AdvancedHealthVoiceEngine?
    private var cancellables = Set<AnyCancellable>()
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager = HealthDataManager.shared,
                analyticsEngine: AnalyticsEngine = AnalyticsEngine.shared) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        
        setupVoiceEngine()
        setupBindings()
        loadMockData()
    }
    
    // MARK: - Public Methods
    
    /// Load data for the dashboard
    public func loadData() {
        Task {
            await loadVoiceData()
            await loadConversationData()
            await loadCommandData()
            await loadCoachingData()
        }
    }
    
    /// Refresh data
    public func refreshData() {
        Task {
            isLoading = true
            await loadData()
            isLoading = false
        }
    }
    
    /// Start voice system
    public func startVoiceSystem() async {
        do {
            try await voiceEngine?.startVoiceSystem()
            await updateVoiceStatus()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Stop voice system
    public func stopVoiceSystem() async {
        await voiceEngine?.stopVoiceSystem()
        await updateVoiceStatus()
    }
    
    /// Start listening
    public func startListening() async {
        do {
            try await voiceEngine?.startListening()
            await updateListeningStatus()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Stop listening
    public func stopListening() async {
        await voiceEngine?.stopListening()
        await updateListeningStatus()
    }
    
    /// Speak text
    public func speakText(_ text: String, voice: VoiceType = .default) async {
        do {
            try await voiceEngine?.speakText(text, voice: voice)
            await updateSpeakingStatus()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Stop speaking
    public func stopSpeaking() async {
        await voiceEngine?.stopSpeaking()
        await updateSpeakingStatus()
    }
    
    /// Process voice command
    public func processVoiceCommand(_ command: String) async {
        do {
            let response = try await voiceEngine?.processVoiceCommand(command)
            if let response = response {
                await updateConversationHistory(command: command, response: response)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Start voice coaching session
    public func startVoiceCoachingSession(type: CoachingType) async {
        do {
            try await voiceEngine?.startVoiceCoachingSession(type: type)
            await loadCoachingData()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Stop voice coaching session
    public func stopVoiceCoachingSession() async {
        do {
            try await voiceEngine?.stopVoiceCoachingSession()
            await loadCoachingData()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Get conversation history
    public func getConversationHistory(limit: Int = 50) async -> [ConversationEntry] {
        return await voiceEngine?.getConversationHistory(limit: limit) ?? []
    }
    
    /// Get voice commands
    public func getVoiceCommands(category: CommandCategory = .all) async -> [VoiceCommand] {
        return await voiceEngine?.getVoiceCommands(category: category) ?? []
    }
    
    /// Get voice insights
    public func getVoiceInsights(type: InsightType = .all) async -> [VoiceInsight] {
        return await voiceEngine?.getVoiceInsights(type: type) ?? []
    }
    
    /// Analyze voice patterns
    public func analyzeVoicePatterns() async {
        do {
            let analysis = try await voiceEngine?.analyzeVoicePatterns()
            if let analysis = analysis {
                await updateVoiceInsights(analysis: analysis)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Generate voice response
    public func generateVoiceResponse(context: ConversationContext) async -> String {
        do {
            return try await voiceEngine?.generateVoiceResponse(context: context) ?? "I'm sorry, I couldn't generate a response."
        } catch {
            lastError = error.localizedDescription
            return "I'm sorry, there was an error generating the response."
        }
    }
    
    /// Export voice data
    public func exportVoiceData(format: ExportFormat = .json) async throws -> Data {
        return try await voiceEngine?.exportVoiceData(format: format) ?? Data()
    }
    
    /// Clear error
    public func clearError() {
        lastError = nil
    }
    
    // MARK: - Private Methods
    
    private func setupVoiceEngine() {
        voiceEngine = AdvancedHealthVoiceEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine
        )
    }
    
    private func setupBindings() {
        // Setup bindings for real-time updates
        setupVoiceBindings()
        setupConversationBindings()
        setupCommandBindings()
        setupCoachingBindings()
    }
    
    private func setupVoiceBindings() {
        // Voice bindings would be set up here
    }
    
    private func setupConversationBindings() {
        // Conversation bindings would be set up here
    }
    
    private func setupCommandBindings() {
        // Command bindings would be set up here
    }
    
    private func setupCoachingBindings() {
        // Coaching bindings would be set up here
    }
    
    private func loadMockData() {
        // Load mock data for preview and testing
        loadMockConversations()
        loadMockVoiceCommands()
        loadMockVoiceInsights()
        loadMockCoaching()
    }
    
    private func loadMockConversations() {
        conversationHistory = [
            ConversationEntry(
                id: UUID(),
                userInput: "What's my heart rate today?",
                systemResponse: "Your current heart rate is 72 BPM, which is within the normal range for your age and activity level.",
                timestamp: Date().addingTimeInterval(-3600),
                type: .question
            ),
            ConversationEntry(
                id: UUID(),
                userInput: "Start a fitness coaching session",
                systemResponse: "I'll start a fitness coaching session for you. Let's begin with a quick warm-up routine.",
                timestamp: Date().addingTimeInterval(-7200),
                type: .command
            ),
            ConversationEntry(
                id: UUID(),
                userInput: "How many steps did I take today?",
                systemResponse: "You've taken 8,500 steps today. You're 1,500 steps away from your daily goal of 10,000 steps.",
                timestamp: Date().addingTimeInterval(-10800),
                type: .question
            )
        ]
    }
    
    private func loadMockVoiceCommands() {
        voiceCommands = [
            VoiceCommand(
                id: UUID(),
                command: "What's my heart rate?",
                category: .health,
                type: .healthQuery,
                description: "Get current heart rate information",
                timestamp: Date()
            ),
            VoiceCommand(
                id: UUID(),
                command: "Start fitness coaching",
                category: .fitness,
                type: .fitnessQuery,
                description: "Begin a fitness coaching session",
                timestamp: Date()
            ),
            VoiceCommand(
                id: UUID(),
                command: "How many steps today?",
                category: .fitness,
                type: .fitnessQuery,
                description: "Get today's step count",
                timestamp: Date()
            ),
            VoiceCommand(
                id: UUID(),
                command: "What should I eat?",
                category: .nutrition,
                type: .nutritionQuery,
                description: "Get nutrition recommendations",
                timestamp: Date()
            ),
            VoiceCommand(
                id: UUID(),
                command: "How did I sleep?",
                category: .sleep,
                type: .sleepQuery,
                description: "Get sleep quality information",
                timestamp: Date()
            )
        ]
    }
    
    private func loadMockVoiceInsights() {
        voiceInsights = [
            VoiceInsight(
                id: UUID(),
                title: "Voice Pattern Detected",
                description: "You tend to ask about heart rate in the morning. Consider setting up automatic heart rate monitoring.",
                type: .behavior,
                severity: .low,
                recommendations: ["Enable automatic heart rate monitoring", "Set up morning health check reminders"],
                timestamp: Date()
            ),
            VoiceInsight(
                id: UUID(),
                title: "Coaching Engagement High",
                description: "You're highly engaged during fitness coaching sessions. This is great for your health goals!",
                type: .health,
                severity: .low,
                recommendations: ["Continue with regular coaching sessions", "Try nutrition coaching next"],
                timestamp: Date()
            ),
            VoiceInsight(
                id: UUID(),
                title: "Voice Recognition Improved",
                description: "Your voice recognition accuracy has improved by 15% over the last week.",
                type: .recommendation,
                severity: .low,
                recommendations: ["Keep using voice commands regularly", "Try more complex voice queries"],
                timestamp: Date()
            )
        ]
    }
    
    private func loadMockCoaching() {
        voiceCoaching = VoiceCoachingSession(
            id: UUID(),
            type: .fitness,
            startTime: Date().addingTimeInterval(-1800),
            status: .active,
            progress: 0.6,
            timestamp: Date()
        )
    }
    
    private func loadVoiceData() async {
        // Load voice data from the engine
        if let engine = voiceEngine {
            let insights = await engine.getVoiceInsights()
            await MainActor.run {
                self.voiceInsights = insights
            }
        }
    }
    
    private func loadConversationData() async {
        // Load conversation data from the engine
        if let engine = voiceEngine {
            let conversations = await engine.getConversationHistory()
            await MainActor.run {
                self.conversationHistory = conversations
            }
        }
    }
    
    private func loadCommandData() async {
        // Load command data from the engine
        if let engine = voiceEngine {
            let commands = await engine.getVoiceCommands()
            await MainActor.run {
                self.voiceCommands = commands
            }
        }
    }
    
    private func loadCoachingData() async {
        // Load coaching data from the engine
        // For now, we'll keep the mock data
    }
    
    private func updateVoiceStatus() async {
        // Update voice status from the engine
        if let engine = voiceEngine {
            // This would be updated through the engine's published properties
            // For now, we'll simulate the update
            await MainActor.run {
                self.isVoiceActive = true
                self.voiceProgress = 0.85
            }
        }
    }
    
    private func updateListeningStatus() async {
        // Update listening status from the engine
        if let engine = voiceEngine {
            // This would be updated through the engine's published properties
            await MainActor.run {
                self.isListening = true
            }
        }
    }
    
    private func updateSpeakingStatus() async {
        // Update speaking status from the engine
        if let engine = voiceEngine {
            // This would be updated through the engine's published properties
            await MainActor.run {
                self.isSpeaking = true
            }
        }
    }
    
    private func updateConversationHistory(command: String, response: VoiceCommandResponse) async {
        let entry = ConversationEntry(
            id: UUID(),
            userInput: command,
            systemResponse: response.response,
            timestamp: Date(),
            type: .command
        )
        
        await MainActor.run {
            self.conversationHistory.append(entry)
        }
    }
    
    private func updateVoiceInsights(analysis: VoicePatternAnalysis) async {
        await MainActor.run {
            self.voiceInsights = analysis.insights
        }
    }
}

// MARK: - Supporting Views

@available(iOS 18.0, macOS 15.0, *)
struct VoiceCommandView: View {
    @ObservedObject var viewModel: AdvancedHealthVoiceViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Voice Command Management")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("Voice command management interface")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct CoachingView: View {
    @ObservedObject var viewModel: AdvancedHealthVoiceViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Voice Coaching Management")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("Voice coaching management interface")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct ConversationView: View {
    @ObservedObject var viewModel: AdvancedHealthVoiceViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Conversation Management")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("Conversation management interface")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Preview
@available(iOS 18.0, macOS 15.0, *)
#Preview {
    AdvancedHealthVoiceDashboardView()
} 