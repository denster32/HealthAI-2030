import SwiftUI
import SwiftData
import AVFoundation

/// Main chat interface for the Copilot system
public struct CopilotChatView: View {
    @StateObject private var viewModel = CopilotChatViewModel()
    @State private var messageText = ""
    @State private var isRecording = false
    @State private var showingSkillPicker = false
    @FocusState private var isTextFieldFocused: Bool
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Messages
            messagesView
            
            // Input area
            inputArea
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.loadChatHistory()
        }
        .sheet(isPresented: $showingSkillPicker) {
            SkillPickerView { skill in
                viewModel.executeSkill(skill)
                showingSkillPicker = false
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Health AI Copilot")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Your personal health assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                showingSkillPicker = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .bottom
        )
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if viewModel.isTyping {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(viewModel.messages.last?.id ?? "typing", anchor: .bottom)
                }
            }
        }
    }
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            // Suggested actions
            if !viewModel.suggestedActions.isEmpty {
                suggestedActionsView
            }
            
            // Input field
            HStack(spacing: 12) {
                // Voice button
                Button(action: {
                    if isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                    isRecording.toggle()
                }) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title2)
                        .foregroundColor(isRecording ? .red : .blue)
                }
                .disabled(viewModel.isTyping)
                
                // Text input
                HStack {
                    TextField("Ask me about your health...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                        .disabled(viewModel.isTyping)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isTyping)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
    
    private var suggestedActionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.suggestedActions, id: \.id) { action in
                    Button(action: {
                        viewModel.executeAction(action)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: action.icon)
                                .font(.caption)
                            Text(action.title)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        viewModel.sendMessage(trimmedText)
        messageText = ""
        isTextFieldFocused = false
    }
}

/// Individual message bubble
struct MessageBubble: View {
    let message: CopilotMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
                userMessage
            } else {
                copilotMessage
                Spacer()
            }
        }
    }
    
    private var userMessage: some View {
        Text(message.content)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(18)
            .cornerRadius(4, corners: [.topLeft, .topRight, .bottomLeft])
    }
    
    private var copilotMessage: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(18)
                .cornerRadius(4, corners: [.topLeft, .topRight, .bottomRight])
            
            // Show actions if available
            if !message.actions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(message.actions, id: \.id) { action in
                        Button(action.title) {
                            // Handle action
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

/// Typing indicator
struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0 + animationOffset)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(18)
            .cornerRadius(4, corners: [.topLeft, .topRight, .bottomRight])
            
            Spacer()
        }
        .onAppear {
            animationOffset = 0.3
        }
    }
}

/// Skill picker view
struct SkillPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSkillSelected: (CopilotSkill) -> Void
    
    @StateObject private var registry = CopilotSkillRegistry.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(registry.getSkillsByCategory().sorted(by: { $0.key < $1.key }), id: \.key) { category, skills in
                    Section(header: Text(category)) {
                        ForEach(skills, id: \.skillID) { skill in
                            Button(action: {
                                onSkillSelected(skill)
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(skill.skillName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(skill.skillDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Skill")
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

/// View model for the chat interface
@MainActor
class CopilotChatViewModel: ObservableObject {
    @Published var messages: [CopilotMessage] = []
    @Published var isTyping = false
    @Published var suggestedActions: [CopilotAction] = []
    
    private let registry = CopilotSkillRegistry.shared
    private let speechRecognizer = SpeechRecognizer()
    private var audioRecorder: AVAudioRecorder?
    
    init() {
        setupSpeechRecognition()
    }
    
    func loadChatHistory() {
        // Load chat history from SwiftData
        // This would integrate with the existing chat history system
    }
    
    func sendMessage(_ text: String) {
        let userMessage = CopilotMessage(
            id: UUID().uuidString,
            content: text,
            role: .user,
            timestamp: Date(),
            actions: []
        )
        
        messages.append(userMessage)
        
        // Process message with Copilot
        Task {
            await processMessage(text)
        }
    }
    
    func executeSkill(_ skill: CopilotSkill) {
        let message = CopilotMessage(
            id: UUID().uuidString,
            content: "Executing \(skill.skillName)...",
            role: .copilot,
            timestamp: Date(),
            actions: []
        )
        
        messages.append(message)
        
        // Execute skill with default context
        Task {
            await executeSkillWithContext(skill)
        }
    }
    
    func executeAction(_ action: CopilotAction) {
        let message = CopilotMessage(
            id: UUID().uuidString,
            content: "Executing \(action.title)...",
            role: .copilot,
            timestamp: Date(),
            actions: []
        )
        
        messages.append(message)
        
        // Handle action execution
        Task {
            await handleAction(action)
        }
    }
    
    func startRecording() {
        speechRecognizer.startRecording { [weak self] text in
            Task { @MainActor in
                if let text = text, !text.isEmpty {
                    self?.sendMessage(text)
                }
            }
        }
    }
    
    func stopRecording() {
        speechRecognizer.stopRecording()
    }
    
    // MARK: - Private Methods
    
    private func processMessage(_ text: String) async {
        isTyping = true
        
        // Create context for skill execution
        let context = createContext()
        
        // Extract intent and parameters
        let (intent, parameters) = extractIntentAndParameters(from: text)
        
        // Execute skill
        let result = await registry.handleIntent(intent, parameters: parameters, context: context)
        
        // Create response message
        let responseMessage = CopilotMessage(
            id: UUID().uuidString,
            content: result.displayText,
            role: .copilot,
            timestamp: Date(),
            actions: extractActions(from: result)
        )
        
        await MainActor.run {
            messages.append(responseMessage)
            isTyping = false
            updateSuggestedActions(context: context)
        }
    }
    
    private func executeSkillWithContext(_ skill: CopilotSkill) async {
        isTyping = true
        
        let context = createContext()
        let result = await skill.execute(
            intent: skill.handledIntents.first ?? "default",
            parameters: [:],
            context: context
        )
        
        let responseMessage = CopilotMessage(
            id: UUID().uuidString,
            content: result.displayText,
            role: .copilot,
            timestamp: Date(),
            actions: extractActions(from: result)
        )
        
        await MainActor.run {
            messages.append(responseMessage)
            isTyping = false
            updateSuggestedActions(context: context)
        }
    }
    
    private func handleAction(_ action: CopilotAction) async {
        isTyping = true
        
        // Handle different action types
        switch action.actionType {
        case .startWorkout:
            await handleStartWorkout()
        case .startSleepSession:
            await handleStartSleepSession()
        case .startMeditation:
            await handleStartMeditation()
        case .logWater:
            await handleLogWater()
        case .logMood:
            await handleLogMood()
        case .setReminder:
            await handleSetReminder(action.parameters)
        case .viewDetails:
            await handleViewDetails(action.parameters)
        case .shareData:
            await handleShareData()
        case .custom(let customType):
            await handleCustomAction(customType, parameters: action.parameters)
        }
        
        await MainActor.run {
            isTyping = false
        }
    }
    
    private func createContext() -> CopilotContext {
        // Create context with current data
        // This would integrate with SwiftData and other managers
        return CopilotContext(
            userID: nil,
            modelContext: try! ModelContext(for: HealthData.self),
            healthData: [],
            sleepSessions: [],
            workoutRecords: [],
            userProfile: nil,
            conversationHistory: messages.map { ChatMessage(role: $0.role == .user ? .user : .copilot, content: $0.content) },
            currentTime: Date(),
            deviceType: .iPhone
        )
    }
    
    private func extractIntentAndParameters(from text: String) -> (String, [String: Any]) {
        // Simple intent extraction - in a real app, this would use NLP
        let lowercased = text.lowercased()
        
        if lowercased.contains("sleep") {
            return ("explain_sleep_quality", [:])
        } else if lowercased.contains("heart") || lowercased.contains("hr") {
            return ("explain_heart_rate", [:])
        } else if lowercased.contains("stress") {
            return ("explain_stress_level", [:])
        } else if lowercased.contains("activity") || lowercased.contains("workout") {
            return ("explain_activity_pattern", [:])
        } else if lowercased.contains("streak") {
            return ("get_activity_streak", [:])
        } else if lowercased.contains("goal") {
            return ("list_goals", [:])
        } else {
            return ("analyze_correlation", ["metric1": "steps", "metric2": "sleep"])
        }
    }
    
    private func extractActions(from result: CopilotSkillResult) -> [CopilotAction] {
        // Extract actions from skill result
        // This would parse the result and extract actionable items
        return []
    }
    
    private func updateSuggestedActions(context: CopilotContext) {
        suggestedActions = registry.getAllSuggestedActions(context: context)
    }
    
    private func setupSpeechRecognition() {
        // Setup speech recognition
    }
    
    // MARK: - Action Handlers
    
    private func handleStartWorkout() async {
        // Handle workout start
    }
    
    private func handleStartSleepSession() async {
        // Handle sleep session start
    }
    
    private func handleStartMeditation() async {
        // Handle meditation start
    }
    
    private func handleLogWater() async {
        // Handle water logging
    }
    
    private func handleLogMood() async {
        // Handle mood logging
    }
    
    private func handleSetReminder(_ parameters: [String: Any]) async {
        // Handle reminder setting
    }
    
    private func handleViewDetails(_ parameters: [String: Any]) async {
        // Handle viewing details
    }
    
    private func handleShareData() async {
        // Handle data sharing
    }
    
    private func handleCustomAction(_ type: String, parameters: [String: Any]) async {
        // Handle custom actions
    }
}

/// Message model for the chat interface
struct CopilotMessage: Identifiable {
    let id: String
    let content: String
    let role: MessageRole
    let timestamp: Date
    let actions: [CopilotAction]
    
    enum MessageRole {
        case user
        case copilot
    }
}

/// Speech recognition helper
class SpeechRecognizer: NSObject, ObservableObject {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    private var onResult: ((String?) -> Void)?
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    func startRecording(onResult: @escaping (String?) -> Void) {
        self.onResult = onResult
        
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.startRecording()
                } else {
                    onResult(nil)
                }
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    private func startRecording() {
        // Implementation for starting speech recognition
        // This would set up the audio engine and start recognition
    }
}

// MARK: - Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
} 