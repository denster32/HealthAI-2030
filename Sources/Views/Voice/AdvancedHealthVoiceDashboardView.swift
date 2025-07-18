import SwiftUI
import Charts

/// Advanced Health Voice & Conversational AI Dashboard
/// Provides comprehensive voice interaction, conversation history, voice commands, and coaching sessions
@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedHealthVoiceDashboardView: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    @StateObject private var viewModel = AdvancedHealthVoiceViewModel()
    @State private var selectedTab = 0
    @State private var showingVoiceCommand = false
    @State private var showingCoaching = false
    @State private var showingConversation = false
    @State private var selectedCommand: VoiceCommand?
    @State private var selectedCoaching: VoiceCoachingSession?
    @State private var isListening = false
    @State private var isSpeaking = false
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Voice Tab
                    voiceTabView
                        .tag(0)
                    
                    // Conversations Tab
                    conversationsTabView
                        .tag(1)
                    
                    // Commands Tab
                    commandsTabView
                        .tag(2)
                    
                    // Coaching Tab
                    coachingTabView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(backgroundColor)
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $showingVoiceCommand) {
            VoiceCommandView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCoaching) {
            CoachingView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingConversation) {
            ConversationView(viewModel: viewModel)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Voice AI")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { viewModel.refreshData() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            // Tab Indicators
            HStack(spacing: 0) {
                ForEach(0..<4) { index in
                    Button(action: { selectedTab = index }) {
                        VStack(spacing: 4) {
                            Text(tabTitle(for: index))
                                .font(.caption)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == index ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(headerBackgroundColor)
    }
    
    // MARK: - Voice Tab View
    private var voiceTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Voice Status Card
                voiceStatusCard
                
                // Voice Controls
                voiceControlsCard
                
                // Voice Insights
                voiceInsightsCard
                
                // Voice Analytics
                voiceAnalyticsCard
            }
            .padding()
        }
    }
    
    // MARK: - Conversations Tab View
    private var conversationsTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Conversation History
                conversationHistoryCard
                
                // Recent Conversations
                recentConversationsCard
                
                // Conversation Analytics
                conversationAnalyticsCard
            }
            .padding()
        }
    }
    
    // MARK: - Commands Tab View
    private var commandsTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Voice Commands
                voiceCommandsCard
                
                // Command Categories
                commandCategoriesCard
                
                // Command Analytics
                commandAnalyticsCard
            }
            .padding()
        }
    }
    
    // MARK: - Coaching Tab View
    private var coachingTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Active Coaching
                activeCoachingCard
                
                // Coaching Sessions
                coachingSessionsCard
                
                // Coaching Analytics
                coachingAnalyticsCard
            }
            .padding()
        }
    }
    
    // MARK: - Voice Status Card
    private var voiceStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Voice Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    if viewModel.isVoiceActive {
                        Task { await viewModel.stopVoiceSystem() }
                    } else {
                        Task { await viewModel.startVoiceSystem() }
                    }
                }) {
                    Text(viewModel.isVoiceActive ? "Stop" : "Start")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.isVoiceActive ? Color.red : Color.green)
                        .cornerRadius(8)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Conversations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.conversationHistory.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Commands")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.voiceCommands.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            if viewModel.isVoiceActive {
                ProgressView(value: viewModel.voiceProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(.green)
            }
            
            if let error = viewModel.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Voice Controls Card
    private var voiceControlsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice Controls")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                // Listen Button
                Button(action: {
                    if isListening {
                        Task { await viewModel.stopListening() }
                        isListening = false
                    } else {
                        Task { await viewModel.startListening() }
                        isListening = true
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: isListening ? "mic.fill" : "mic")
                            .font(.title)
                            .foregroundColor(isListening ? .red : .accentColor)
                        
                        Text(isListening ? "Stop" : "Listen")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isListening ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Speak Button
                Button(action: {
                    if isSpeaking {
                        Task { await viewModel.stopSpeaking() }
                        isSpeaking = false
                    } else {
                        Task { await viewModel.speakText("Hello! How can I help you with your health today?") }
                        isSpeaking = true
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.3")
                            .font(.title)
                            .foregroundColor(isSpeaking ? .green : .accentColor)
                        
                        Text(isSpeaking ? "Stop" : "Speak")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isSpeaking ? Color.green.opacity(0.1) : Color.accentColor.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // Voice Recognition Status
            if viewModel.speechRecognition.text.isNotEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recognized:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.speechRecognition.text)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Voice Insights Card
    private var voiceInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.voiceInsights.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "lightbulb")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No voice insights available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.voiceInsights.prefix(3)) { insight in
                        VoiceInsightRowView(insight: insight)
                    }
                    
                    if viewModel.voiceInsights.count > 3 {
                        Button("View All \(viewModel.voiceInsights.count) Insights") {
                            selectedTab = 0
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Voice Analytics Card
    private var voiceAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Voice Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Conversation Count
                HStack {
                    Text("Total Conversations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(viewModel.conversationHistory.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
                
                // Command Success Rate
                HStack {
                    Text("Command Success Rate")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("95%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                // Average Response Time
                HStack {
                    Text("Avg Response Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("1.2s")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Conversation History Card
    private var conversationHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Conversation History")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingConversation = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            if viewModel.conversationHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "message")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No conversations yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Start Conversation") {
                        showingConversation = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.conversationHistory.prefix(3)) { entry in
                        ConversationRowView(entry: entry)
                    }
                    
                    if viewModel.conversationHistory.count > 3 {
                        Button("View All \(viewModel.conversationHistory.count) Conversations") {
                            selectedTab = 1
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Recent Conversations Card
    private var recentConversationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Conversations")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.conversationHistory.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No recent conversations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.conversationHistory.prefix(3)) { entry in
                        RecentConversationRowView(entry: entry)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Conversation Analytics Card
    private var conversationAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conversation Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Conversation Types
                HStack {
                    Text("Conversation Types")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Commands: \(viewModel.conversationHistory.filter { $0.type == .command }.count)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("Questions: \(viewModel.conversationHistory.filter { $0.type == .question }.count)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                // Average Conversation Length
                HStack {
                    Text("Avg Conversation Length")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("3.2 exchanges")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Voice Commands Card
    private var voiceCommandsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Voice Commands")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingVoiceCommand = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            if viewModel.voiceCommands.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "command")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No voice commands available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Add Command") {
                        showingVoiceCommand = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.voiceCommands.prefix(3)) { command in
                        VoiceCommandRowView(command: command) {
                            selectedCommand = command
                        }
                    }
                    
                    if viewModel.voiceCommands.count > 3 {
                        Button("View All \(viewModel.voiceCommands.count) Commands") {
                            selectedTab = 2
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Command Categories Card
    private var commandCategoriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Command Categories")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(CommandCategory.allCases, id: \.self) { category in
                    CommandCategoryCard(category: category) {
                        // Handle category selection
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Command Analytics Card
    private var commandAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Command Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Most Used Commands
                HStack {
                    Text("Most Used Commands")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Health: 45%")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("Fitness: 30%")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                // Command Success Rate
                HStack {
                    Text("Success Rate")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("95%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Active Coaching Card
    private var activeCoachingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Coaching")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingCoaching = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            if viewModel.voiceCoaching == nil {
                VStack(spacing: 8) {
                    Image(systemName: "person.wave.2")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No active coaching session")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Start Coaching") {
                        showingCoaching = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.voiceCoaching?.type.rawValue.capitalized ?? "")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(viewModel.voiceCoaching?.status.rawValue.capitalized ?? "")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    ProgressView(value: viewModel.voiceCoaching?.progress ?? 0.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .accentColor(.accentColor)
                    
                    Text("Progress: \(Int((viewModel.voiceCoaching?.progress ?? 0.0) * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Coaching Sessions Card
    private var coachingSessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coaching Sessions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(CoachingType.allCases.prefix(4), id: \.self) { type in
                    CoachingTypeRowView(type: type) {
                        Task { await viewModel.startVoiceCoachingSession(type: type) }
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Coaching Analytics Card
    private var coachingAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coaching Analytics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Session Duration
                HStack {
                    Text("Avg Session Duration")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("15 min")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                // Completion Rate
                HStack {
                    Text("Completion Rate")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("85%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Voice"
        case 1: return "Conversations"
        case 2: return "Commands"
        case 3: return "Coaching"
        default: return ""
        }
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemGroupedBackground)
    }
    
    private var headerBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }
}

// MARK: - Supporting Views

@available(iOS 18.0, macOS 15.0, *)
struct VoiceInsightRowView: View {
    let insight: VoiceInsight
    
    var body: some View {
        HStack {
            Image(systemName: insightIcon(for: insight.type))
                .font(.title3)
                .foregroundColor(severityColor(insight.severity))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(insight.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func insightIcon(for type: InsightType) -> String {
        switch type {
        case .health: return "heart"
        case .behavior: return "brain.head.profile"
        case .emotion: return "face.smiling"
        case .recommendation: return "lightbulb"
        }
    }
    
    private func severityColor(_ severity: Severity) -> Color {
        switch severity {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct ConversationRowView: View {
    let entry: ConversationEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.userInput)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(entry.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.systemResponse)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct RecentConversationRowView: View {
    let entry: ConversationEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.type.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                
                Text(entry.userInput)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(entry.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct VoiceCommandRowView: View {
    let command: VoiceCommand
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(command.command)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(command.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(command.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    
                    Text(command.type.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct CommandCategoryCard: View {
    let category: CommandCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: categoryIcon(for: category))
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text(category.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryIcon(for category: CommandCategory) -> String {
        switch category {
        case .health: return "heart"
        case .fitness: return "figure.run"
        case .nutrition: return "leaf"
        case .sleep: return "bed.double"
        case .mental: return "brain.head.profile"
        case .system: return "gear"
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct CoachingTypeRowView: View {
    let type: CoachingType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: coachingIcon(for: type))
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Start coaching session")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func coachingIcon(for type: CoachingType) -> String {
        switch type {
        case .fitness: return "figure.run"
        case .nutrition: return "leaf"
        case .sleep: return "bed.double"
        case .mental: return "brain.head.profile"
        case .meditation: return "sparkles"
        case .motivation: return "flame"
        }
    }
}

// MARK: - Placeholder Views

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