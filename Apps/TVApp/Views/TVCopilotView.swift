import SwiftUI
import Speech
import AVFoundation

@available(tvOS 18.0, *)
struct TVCopilotView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var copilotManager = CopilotManager()
    @State private var inputText = ""
    @State private var isListening = false
    @State private var showingKeyboard = false
    @State private var selectedSkill: CopilotSkill?
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Panel - Conversation History
            ConversationHistoryPanel(
                messages: copilotManager.messages,
                selectedSkill: selectedSkill
            )
            .frame(width: 600)
            
            // Right Panel - Input and Skills
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AI Health Copilot")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Your personal health assistant")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Skills Grid
                SkillsGrid(selectedSkill: $selectedSkill)
                
                // Input Area
                InputArea(
                    inputText: $inputText,
                    isListening: $isListening,
                    showingKeyboard: $showingKeyboard,
                    onSend: sendMessage,
                    onVoiceInput: startVoiceInput
                )
                
                Spacer()
            }
            .padding(40)
            .background(Color(.secondarySystemBackground))
        }
        .background(Color(.systemBackground))
        .onAppear {
            setupSpeechRecognition()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func setupSpeechRecognition() {
        speechRecognizer.onTranscription = { text in
            inputText = text
        }
        
        speechRecognizer.onError = { error in
            print("Speech recognition error: \(error)")
        }
    }
    
    private func startVoiceInput() {
        isListening = true
        speechRecognizer.startRecording()
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = CopilotMessage(
            id: UUID(),
            text: inputText,
            isUser: true,
            timestamp: Date()
        )
        
        copilotManager.addMessage(message)
        
        // Clear input
        inputText = ""
        isListening = false
        speechRecognizer.stopRecording()
        
        // Process with AI
        Task {
            await copilotManager.processUserInput(message.text, selectedSkill: selectedSkill)
        }
    }
    
    private func cleanup() {
        speechRecognizer.stopRecording()
    }
}

// MARK: - Conversation History Panel
@available(tvOS 18.0, *)
struct ConversationHistoryPanel: View {
    let messages: [CopilotMessage]
    let selectedSkill: CopilotSkill?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 16) {
                Text("Conversation History")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let skill = selectedSkill {
                    HStack {
                        Image(systemName: skill.icon)
                            .foregroundColor(skill.color)
                        
                        Text("Using: \(skill.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(24)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Skills Grid
@available(tvOS 18.0, *)
struct SkillsGrid: View {
    @Binding var selectedSkill: CopilotSkill?
    
    let skills: [CopilotSkill] = [
        CopilotSkill(
            id: UUID(),
            name: "Health Analysis",
            description: "Analyze your health data and provide insights",
            icon: "chart.bar.xaxis",
            color: .blue
        ),
        CopilotSkill(
            id: UUID(),
            name: "Workout Planning",
            description: "Create personalized workout plans",
            icon: "figure.run",
            color: .green
        ),
        CopilotSkill(
            id: UUID(),
            name: "Nutrition Advice",
            description: "Get personalized nutrition recommendations",
            icon: "leaf.fill",
            color: .orange
        ),
        CopilotSkill(
            id: UUID(),
            name: "Sleep Coaching",
            description: "Improve your sleep quality",
            icon: "bed.double.fill",
            color: .purple
        ),
        CopilotSkill(
            id: UUID(),
            name: "Stress Management",
            description: "Learn stress reduction techniques",
            icon: "brain.head.profile",
            color: .pink
        ),
        CopilotSkill(
            id: UUID(),
            name: "General Health",
            description: "General health questions and advice",
            icon: "heart.fill",
            color: .red
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Skills")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                ForEach(skills, id: \.id) { skill in
                    SkillCard(
                        skill: skill,
                        isSelected: selectedSkill?.id == skill.id
                    ) {
                        selectedSkill = selectedSkill?.id == skill.id ? nil : skill
                    }
                }
            }
        }
    }
}

// MARK: - Input Area
@available(tvOS 18.0, *)
struct InputArea: View {
    @Binding var inputText: String
    @Binding var isListening: Bool
    @Binding var showingKeyboard: Bool
    let onSend: () -> Void
    let onVoiceInput: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Input Field
            HStack(spacing: 16) {
                TextField("Type your message or use voice...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)
                    .onSubmit {
                        onSend()
                    }
                
                // Voice Input Button
                Button(action: onVoiceInput) {
                    Image(systemName: isListening ? "waveform" : "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isListening ? .red : .blue)
                        .frame(width: 60, height: 60)
                        .background(isListening ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                        .cornerRadius(30)
                        .scaleEffect(isListening ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isListening)
                }
                .buttonStyle(CardButtonStyle())
                
                // Send Button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .cornerRadius(30)
                }
                .buttonStyle(CardButtonStyle())
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            // Voice Status
            if isListening {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.red)
                    
                    Text("Listening... Speak now")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            // Quick Actions
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 16) {
                    QuickActionButton(
                        title: "Health Summary",
                        icon: "heart.fill",
                        action: { inputText = "Give me a health summary" }
                    )
                    
                    QuickActionButton(
                        title: "Workout Plan",
                        icon: "figure.run",
                        action: { inputText = "Create a workout plan for me" }
                    )
                    
                    QuickActionButton(
                        title: "Sleep Tips",
                        icon: "bed.double.fill",
                        action: { inputText = "Give me sleep improvement tips" }
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views

@available(tvOS 18.0, *)
struct MessageBubble: View {
    let message: CopilotMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(message.text)
                        .font(.body)
                        .padding(16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                        
                        Text("AI Copilot")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(message.text)
                        .font(.body)
                        .padding(16)
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

@available(tvOS 18.0, *)
struct SkillCard: View {
    let skill: CopilotSkill
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: skill.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : skill.color)
                
                Text(skill.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                Text(skill.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 180, height: 120)
            .background(isSelected ? skill.color : Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? skill.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(CardButtonStyle())
    }
}

@available(tvOS 18.0, *)
struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(width: 100, height: 60)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Managers

@available(tvOS 18.0, *)
class CopilotManager: ObservableObject {
    @Published var messages: [CopilotMessage] = []
    
    func addMessage(_ message: CopilotMessage) {
        messages.append(message)
    }
    
    func processUserInput(_ input: String, selectedSkill: CopilotSkill?) async {
        // Simulate AI processing
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let response = generateResponse(for: input, skill: selectedSkill)
        
        await MainActor.run {
            let aiMessage = CopilotMessage(
                id: UUID(),
                text: response,
                isUser: false,
                timestamp: Date()
            )
            messages.append(aiMessage)
        }
    }
    
    private func generateResponse(for input: String, skill: CopilotSkill?) -> String {
        let skillName = skill?.name ?? "General Health"
        
        if input.lowercased().contains("health summary") {
            return "Based on your recent health data, you're doing well! Your heart rate is stable at 72 BPM, you've averaged 8,234 steps daily, and your sleep quality has improved by 15% this week. Keep up the great work!"
        } else if input.lowercased().contains("workout plan") {
            return "I'll create a personalized workout plan for you. Based on your fitness level and goals, I recommend: 3 days of cardio (30 min), 2 days of strength training, and 2 days of active recovery. Would you like me to schedule this for you?"
        } else if input.lowercased().contains("sleep") {
            return "Here are some tips to improve your sleep: 1) Maintain a consistent sleep schedule, 2) Create a relaxing bedtime routine, 3) Keep your bedroom cool and dark, 4) Avoid screens 1 hour before bed, 5) Consider meditation or deep breathing exercises."
        } else {
            return "I'm here to help with your health and wellness questions. I can analyze your health data, create workout plans, provide nutrition advice, and much more. What would you like to know about?"
        }
    }
}

@available(tvOS 18.0, *)
class SpeechRecognizer: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    var onTranscription: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    func startRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            onError?(NSError(domain: "SpeechRecognizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not available"]))
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.beginRecording()
                } else {
                    self?.onError?(NSError(domain: "SpeechRecognizer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized"]))
                }
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
    
    private func beginRecording() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            
            let inputNode = audioEngine.inputNode
            recognitionRequest?.shouldReportPartialResults = true
            
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
                if let result = result {
                    self?.onTranscription?(result.bestTranscription.formattedString)
                }
                
                if error != nil {
                    self?.stopRecording()
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
        } catch {
            onError?(error)
        }
    }
}

// MARK: - Data Models
struct CopilotMessage: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
}

struct CopilotSkill: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Preview
#Preview {
    TVCopilotView()
} 