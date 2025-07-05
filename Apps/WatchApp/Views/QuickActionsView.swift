import SwiftUI
import WatchKit
import AVFoundation
import Speech

struct QuickActionsView: View {
    @StateObject private var voiceManager = VoiceCommandManager()
    @State private var showingVoiceInput = false
    @State private var selectedAction: QuickAction?
    
    enum QuickAction: String, CaseIterable {
        case startWorkout = "Start Workout"
        case logWater = "Log Water"
        case startMeditation = "Start Meditation"
        case checkHeartRate = "Check Heart Rate"
        case emergencyCall = "Emergency Call"
        case logMood = "Log Mood"
        case takeMedication = "Take Medication"
        case checkWeather = "Check Weather"
        
        var icon: String {
            switch self {
            case .startWorkout: return "figure.run"
            case .logWater: return "drop.fill"
            case .startMeditation: return "brain.head.profile"
            case .checkHeartRate: return "heart.fill"
            case .emergencyCall: return "phone.fill"
            case .logMood: return "face.smiling"
            case .takeMedication: return "pill.fill"
            case .checkWeather: return "cloud.sun.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .startWorkout: return .green
            case .logWater: return .blue
            case .startMeditation: return .purple
            case .checkHeartRate: return .red
            case .emergencyCall: return .red
            case .logMood: return .yellow
            case .takeMedication: return .orange
            case .checkWeather: return .cyan
            }
        }
        
        var hapticType: WKHapticType {
            switch self {
            case .emergencyCall: return .notification
            case .startWorkout, .startMeditation: return .start
            default: return .click
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Voice Command Button
                VoiceCommandButton(
                    isListening: $showingVoiceInput,
                    onCommand: handleVoiceCommand
                )
                
                // Quick Actions Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(QuickAction.allCases, id: \.self) { action in
                        QuickActionCard(
                            action: action,
                            isSelected: selectedAction == action
                        ) {
                            executeAction(action)
                        }
                    }
                }
                
                // Recent Actions
                if !voiceManager.recentCommands.isEmpty {
                    RecentCommandsView(commands: voiceManager.recentCommands)
                }
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Quick Actions")
        .sheet(isPresented: $showingVoiceInput) {
            VoiceInputView(voiceManager: voiceManager)
        }
    }
    
    private func executeAction(_ action: QuickAction) {
        // Provide haptic feedback
        WKInterfaceDevice.current().play(action.hapticType)
        
        // Execute the action
        switch action {
        case .startWorkout:
            startWorkout()
        case .logWater:
            logWaterIntake()
        case .startMeditation:
            startMeditation()
        case .checkHeartRate:
            checkHeartRate()
        case .emergencyCall:
            emergencyCall()
        case .logMood:
            logMood()
        case .takeMedication:
            takeMedication()
        case .checkWeather:
            checkWeather()
        }
        
        selectedAction = action
        
        // Reset selection after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            selectedAction = nil
        }
    }
    
    private func handleVoiceCommand(_ command: String) {
        // Parse voice command and execute corresponding action
        let lowercasedCommand = command.lowercased()
        
        if lowercasedCommand.contains("workout") || lowercasedCommand.contains("run") {
            executeAction(.startWorkout)
        } else if lowercasedCommand.contains("water") || lowercasedCommand.contains("drink") {
            executeAction(.logWater)
        } else if lowercasedCommand.contains("meditation") || lowercasedCommand.contains("breathe") {
            executeAction(.startMeditation)
        } else if lowercasedCommand.contains("heart") || lowercasedCommand.contains("pulse") {
            executeAction(.checkHeartRate)
        } else if lowercasedCommand.contains("emergency") || lowercasedCommand.contains("help") {
            executeAction(.emergencyCall)
        } else if lowercasedCommand.contains("mood") || lowercasedCommand.contains("feel") {
            executeAction(.logMood)
        } else if lowercasedCommand.contains("medication") || lowercasedCommand.contains("pill") {
            executeAction(.takeMedication)
        } else if lowercasedCommand.contains("weather") {
            executeAction(.checkWeather)
        }
    }
    
    // MARK: - Action Implementations
    
    private func startWorkout() {
        // Navigate to workout selection
        print("Starting workout...")
    }
    
    private func logWaterIntake() {
        // Log water intake with haptic feedback
        WKInterfaceDevice.current().play(.success)
        print("Water intake logged")
    }
    
    private func startMeditation() {
        // Start meditation session
        print("Starting meditation...")
    }
    
    private func checkHeartRate() {
        // Check current heart rate
        print("Checking heart rate...")
    }
    
    private func emergencyCall() {
        // Trigger emergency call
        print("Emergency call triggered")
    }
    
    private func logMood() {
        // Log current mood
        print("Logging mood...")
    }
    
    private func takeMedication() {
        // Log medication intake
        print("Medication logged")
    }
    
    private func checkWeather() {
        // Check current weather
        print("Checking weather...")
    }
}

struct QuickActionCard: View {
    let action: QuickActionsView.QuickAction
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : action.color)
                
                Text(action.rawValue)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(isSelected ? action.color : Color(.systemGray6))
            .cornerRadius(12)
            .scaleEffect(isSelected ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VoiceCommandButton: View {
    @Binding var isListening: Bool
    let onCommand: (String) -> Void
    
    var body: some View {
        Button(action: {
            isListening.toggle()
        }) {
            HStack {
                Image(systemName: isListening ? "mic.fill" : "mic")
                    .font(.title2)
                    .foregroundColor(isListening ? .red : .blue)
                
                Text(isListening ? "Listening..." : "Voice Command")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isListening ? Color.red.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentCommandsView: View {
    let commands: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Commands")
                .font(.headline)
                .padding(.horizontal, 4)
            
            ForEach(commands.prefix(3), id: \.self) { command in
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text(command)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
        }
    }
}

struct VoiceInputView: View {
    @ObservedObject var voiceManager: VoiceCommandManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Voice Commands")
                .font(.headline)
            
            Text("Say one of these commands:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach([
                    "Start workout",
                    "Log water",
                    "Check heart rate",
                    "Start meditation",
                    "Emergency call"
                ], id: \.self) { command in
                    HStack {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text(command)
                            .font(.caption)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

class VoiceCommandManager: ObservableObject {
    @Published var recentCommands: [String] = []
    @Published var isListening = false
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    func startListening() {
        guard !isListening else { return }
        
        isListening = true
        
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self?.beginRecognition()
                } else {
                    self?.isListening = false
                }
            }
        }
    }
    
    func stopListening() {
        isListening = false
        audioEngine.stop()
        recognitionRequest?.endAudio()
    }
    
    private func beginRecognition() {
        // Implementation for speech recognition
        // This is a simplified version - in a real app, you'd implement full speech recognition
        print("Speech recognition started")
    }
    
    func addCommand(_ command: String) {
        recentCommands.insert(command, at: 0)
        if recentCommands.count > 5 {
            recentCommands.removeLast()
        }
    }
}

#Preview {
    QuickActionsView()
} 