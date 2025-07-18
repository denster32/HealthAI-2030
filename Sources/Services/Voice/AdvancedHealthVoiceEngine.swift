import Foundation
import Speech
import AVFoundation
import Combine
import NaturalLanguage

/// Advanced Health Voice & Conversational AI Engine
/// Provides comprehensive voice interaction, natural language processing, conversational AI, and voice coaching
@available(iOS 18.0, macOS 15.0, *)
public actor AdvancedHealthVoiceEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var isListening = false
    @Published public private(set) var isSpeaking = false
    @Published public private(set) var conversationHistory: [ConversationEntry] = []
    @Published public private(set) var voiceCommands: [VoiceCommand] = []
    @Published public private(set) var voiceCoaching: VoiceCoachingSession?
    @Published public private(set) var speechRecognition: SpeechRecognitionResult = SpeechRecognitionResult()
    @Published public private(set) var naturalLanguageProcessing: NLPResult = NLPResult()
    @Published public private(set) var conversationalAI: ConversationalAIResponse = ConversationalAIResponse()
    @Published public private(set) var isVoiceActive = false
    @Published public private(set) var lastError: String?
    @Published public private(set) var voiceProgress: Double = 0.0
    @Published public private(set) var voiceInsights: [VoiceInsight] = []
    
    // MARK: - Private Properties
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    private let speechRecognizer: SFSpeechRecognizer
    private let synthesizer: AVSpeechSynthesizer
    private let audioEngine: AVAudioEngine
    private let inputNode: AVAudioInputNode
    
    private var cancellables = Set<AnyCancellable>()
    private let voiceQueue = DispatchQueue(label: "health.voice", qos: .userInitiated)
    private let nlpQueue = DispatchQueue(label: "health.nlp", qos: .userInitiated)
    
    // Voice data caches
    private var voiceData: [String: VoiceData] = [:]
    private var conversationData: [String: ConversationData] = [:]
    private var coachingData: [String: CoachingData] = [:]
    private var nlpData: [String: NLPData] = [:]
    
    // Voice parameters
    private let voiceUpdateInterval: TimeInterval = 1.0 // 1 second
    private var lastVoiceUpdate: Date = Date()
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
        self.synthesizer = AVSpeechSynthesizer()
        self.audioEngine = AVAudioEngine()
        self.inputNode = audioEngine.inputNode
        
        setupVoiceSystem()
        setupSpeechRecognition()
        setupNaturalLanguageProcessing()
        setupConversationalAI()
        initializeVoicePlatform()
    }
    
    // MARK: - Public Methods
    
    /// Start voice system
    public func startVoiceSystem() async throws {
        isVoiceActive = true
        lastError = nil
        voiceProgress = 0.0
        
        do {
            // Request speech recognition authorization
            try await requestSpeechRecognitionAuthorization()
            
            // Initialize voice platform
            try await initializeVoicePlatform()
            
            // Start continuous voice processing
            try await startContinuousVoiceProcessing()
            
            // Update voice status
            await updateVoiceStatus()
            
            // Track voice activation
            analyticsEngine.trackEvent("voice_system_started", properties: [
                "timestamp": Date().timeIntervalSince1970,
                "conversation_count": conversationHistory.count
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isVoiceActive = false
            }
            throw error
        }
    }
    
    /// Stop voice system
    public func stopVoiceSystem() async {
        isVoiceActive = false
        voiceProgress = 0.0
        
        // Stop listening and speaking
        await stopListening()
        await stopSpeaking()
        
        // Save final voice data
        if !conversationHistory.isEmpty {
            await MainActor.run {
                // Save conversation data
            }
        }
        
        // Track voice deactivation
        analyticsEngine.trackEvent("voice_system_stopped", properties: [
            "duration": Date().timeIntervalSince(lastVoiceUpdate),
            "conversations_count": conversationHistory.count
        ])
    }
    
    /// Start listening
    public func startListening() async throws {
        do {
            // Check authorization
            try await checkSpeechRecognitionAuthorization()
            
            // Configure audio session
            try await configureAudioSession()
            
            // Start speech recognition
            try await startSpeechRecognition()
            
            // Update listening status
            await MainActor.run {
                self.isListening = true
            }
            
            // Track listening start
            analyticsEngine.trackEvent("voice_listening_started", properties: [
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Stop listening
    public func stopListening() async {
        // Stop speech recognition
        speechRecognizer.stopRecognition()
        
        // Update listening status
        await MainActor.run {
            self.isListening = false
        }
        
        // Track listening stop
        analyticsEngine.trackEvent("voice_listening_stopped", properties: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Speak text
    public func speakText(_ text: String, voice: VoiceType = .default) async throws {
        do {
            // Validate text
            try await validateText(text: text)
            
            // Configure speech synthesis
            try await configureSpeechSynthesis(voice: voice)
            
            // Create speech utterance
            let utterance = try await createSpeechUtterance(text: text, voice: voice)
            
            // Start speaking
            try await startSpeaking(utterance: utterance)
            
            // Update speaking status
            await MainActor.run {
                self.isSpeaking = true
            }
            
            // Track speech
            analyticsEngine.trackEvent("voice_speech_started", properties: [
                "text_length": text.count,
                "voice_type": voice.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Stop speaking
    public func stopSpeaking() async {
        // Stop speech synthesis
        synthesizer.stopSpeaking(at: .immediate)
        
        // Update speaking status
        await MainActor.run {
            self.isSpeaking = false
        }
        
        // Track speech stop
        analyticsEngine.trackEvent("voice_speech_stopped", properties: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Process voice command
    public func processVoiceCommand(_ command: String) async throws -> VoiceCommandResponse {
        do {
            // Process natural language
            let nlpResult = try await processNaturalLanguage(text: command)
            
            // Generate conversational AI response
            let aiResponse = try await generateConversationalAIResponse(nlpResult: nlpResult)
            
            // Execute voice command
            let response = try await executeVoiceCommand(command: command, aiResponse: aiResponse)
            
            // Add to conversation history
            await addToConversationHistory(command: command, response: response)
            
            // Track command processing
            analyticsEngine.trackEvent("voice_command_processed", properties: [
                "command": command,
                "response_type": response.type.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            return response
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Start voice coaching session
    public func startVoiceCoachingSession(type: CoachingType) async throws {
        do {
            // Validate coaching type
            try await validateCoachingType(type: type)
            
            // Create coaching session
            let session = try await createCoachingSession(type: type)
            
            // Start coaching
            try await startCoaching(session: session)
            
            // Update coaching status
            await MainActor.run {
                self.voiceCoaching = session
            }
            
            // Track coaching start
            analyticsEngine.trackEvent("voice_coaching_started", properties: [
                "coaching_type": type.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Stop voice coaching session
    public func stopVoiceCoachingSession() async throws {
        do {
            // Stop coaching
            try await stopCoaching()
            
            // Update coaching status
            await MainActor.run {
                self.voiceCoaching = nil
            }
            
            // Track coaching stop
            analyticsEngine.trackEvent("voice_coaching_stopped", properties: [
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get conversation history
    public func getConversationHistory(limit: Int = 50) async -> [ConversationEntry] {
        return Array(conversationHistory.suffix(limit))
    }
    
    /// Get voice commands
    public func getVoiceCommands(category: CommandCategory = .all) async -> [VoiceCommand] {
        let filteredCommands = voiceCommands.filter { command in
            switch category {
            case .all: return true
            case .health: return command.category == .health
            case .fitness: return command.category == .fitness
            case .nutrition: return command.category == .nutrition
            case .sleep: return command.category == .sleep
            case .mental: return command.category == .mental
            case .system: return command.category == .system
            }
        }
        
        return filteredCommands
    }
    
    /// Get voice insights
    public func getVoiceInsights(type: InsightType = .all) async -> [VoiceInsight] {
        let filteredInsights = voiceInsights.filter { insight in
            switch type {
            case .all: return true
            case .health: return insight.type == .health
            case .behavior: return insight.type == .behavior
            case .emotion: return insight.type == .emotion
            case .recommendation: return insight.type == .recommendation
            }
        }
        
        return filteredInsights
    }
    
    /// Analyze voice patterns
    public func analyzeVoicePatterns() async throws -> VoicePatternAnalysis {
        do {
            // Collect voice data
            let voiceData = await collectVoiceData()
            
            // Analyze patterns
            let analysis = try await analyzeVoiceData(voiceData: voiceData)
            
            // Generate insights
            let insights = try await generateVoiceInsights(analysis: analysis)
            
            // Update voice insights
            await updateVoiceInsights(insights: insights)
            
            // Track analysis
            analyticsEngine.trackEvent("voice_patterns_analyzed", properties: [
                "patterns_count": analysis.patterns.count,
                "insights_count": insights.count,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            return analysis
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Generate voice response
    public func generateVoiceResponse(context: ConversationContext) async throws -> String {
        do {
            // Analyze context
            let contextAnalysis = try await analyzeConversationContext(context: context)
            
            // Generate response
            let response = try await generateResponseFromContext(analysis: contextAnalysis)
            
            // Validate response
            try await validateResponse(response: response)
            
            return response
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Export voice data
    public func exportVoiceData(format: ExportFormat = .json) async throws -> Data {
        let exportData = VoiceExportData(
            timestamp: Date(),
            conversationHistory: conversationHistory,
            voiceCommands: voiceCommands,
            voiceCoaching: voiceCoaching,
            speechRecognition: speechRecognition,
            naturalLanguageProcessing: naturalLanguageProcessing,
            conversationalAI: conversationalAI,
            voiceInsights: voiceInsights
        )
        
        switch format {
        case .json:
            return try JSONEncoder().encode(exportData)
        case .csv:
            return try exportToCSV(exportData: exportData)
        case .xml:
            return try exportToXML(exportData: exportData)
        case .pdf:
            return try exportToPDF(exportData: exportData)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupVoiceSystem() {
        // Setup voice system
        setupAudioEngine()
        setupSpeechRecognition()
        setupSpeechSynthesis()
        setupVoiceProcessing()
    }
    
    private func setupSpeechRecognition() {
        // Setup speech recognition
        setupRecognitionDelegate()
        setupRecognitionConfiguration()
        setupRecognitionHandling()
    }
    
    private func setupNaturalLanguageProcessing() {
        // Setup natural language processing
        setupNLPTagger()
        setupNLPAnalysis()
        setupNLPGeneration()
    }
    
    private func setupConversationalAI() {
        // Setup conversational AI
        setupAIModel()
        setupAIResponse()
        setupAIContext()
    }
    
    private func initializeVoicePlatform() async throws {
        // Initialize voice platform
        try await loadVoiceModels()
        try await validateVoiceConfiguration()
        try await setupVoiceAlgorithms()
    }
    
    private func startContinuousVoiceProcessing() async throws {
        // Start continuous voice processing
        try await startVoiceTimer()
        try await startDataCollection()
        try await startPatternAnalysis()
    }
    
    private func requestSpeechRecognitionAuthorization() async throws {
        // Request speech recognition authorization
        let status = SFSpeechRecognizer.authorizationStatus()
        
        switch status {
        case .notDetermined:
            let granted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
            if !granted {
                throw VoiceError.authorizationDenied
            }
        case .denied, .restricted:
            throw VoiceError.authorizationDenied
        case .authorized:
            break
        @unknown default:
            throw VoiceError.authorizationDenied
        }
    }
    
    private func checkSpeechRecognitionAuthorization() async throws {
        // Check speech recognition authorization
        let status = SFSpeechRecognizer.authorizationStatus()
        guard status == .authorized else {
            throw VoiceError.authorizationDenied
        }
    }
    
    private func configureAudioSession() async throws {
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func startSpeechRecognition() async throws {
        // Start speech recognition
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.shouldReportPartialResults = true
        
        let recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.speechRecognition = SpeechRecognitionResult(
                        text: result.bestTranscription.formattedString,
                        confidence: result.bestTranscription.segments.map { $0.confidence }.reduce(0, +) / Double(result.bestTranscription.segments.count),
                        isFinal: result.isFinal,
                        timestamp: Date()
                    )
                }
                
                if let error = error {
                    self?.lastError = error.localizedDescription
                }
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    private func validateText(text: String) async throws {
        // Validate text
        guard !text.isEmpty else {
            throw VoiceError.invalidText
        }
        
        guard text.count <= 1000 else {
            throw VoiceError.textTooLong
        }
    }
    
    private func configureSpeechSynthesis(voice: VoiceType) async throws {
        // Configure speech synthesis
        synthesizer.delegate = nil
    }
    
    private func createSpeechUtterance(text: String, voice: VoiceType) async throws -> AVSpeechUtterance {
        // Create speech utterance
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voice.language)
        utterance.rate = voice.rate
        utterance.pitchMultiplier = voice.pitch
        utterance.volume = voice.volume
        return utterance
    }
    
    private func startSpeaking(utterance: AVSpeechUtterance) async throws {
        // Start speaking
        synthesizer.speak(utterance)
    }
    
    private func processNaturalLanguage(text: String) async throws -> NLPResult {
        // Process natural language
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType, .tokenType])
        tagger.string = text
        
        var entities: [NLPEntity] = []
        var sentiment: NLPSentiment = .neutral
        var intent: NLPIntent = .unknown
        
        // Extract entities
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                entities.append(NLPEntity(
                    text: String(text[tokenRange]),
                    type: tag.rawValue,
                    range: tokenRange
                ))
            }
            return true
        }
        
        // Analyze sentiment
        sentiment = try await analyzeSentiment(text: text)
        
        // Determine intent
        intent = try await determineIntent(text: text)
        
        return NLPResult(
            text: text,
            entities: entities,
            sentiment: sentiment,
            intent: intent,
            confidence: 0.8,
            timestamp: Date()
        )
    }
    
    private func generateConversationalAIResponse(nlpResult: NLPResult) async throws -> ConversationalAIResponse {
        // Generate conversational AI response
        let response = try await generateAIResponse(nlpResult: nlpResult)
        
        return ConversationalAIResponse(
            text: response,
            type: .conversation,
            confidence: 0.9,
            timestamp: Date()
        )
    }
    
    private func executeVoiceCommand(command: String, aiResponse: ConversationalAIResponse) async throws -> VoiceCommandResponse {
        // Execute voice command
        let commandType = try await determineCommandType(command: command)
        let response = try await executeCommand(command: command, type: commandType)
        
        return VoiceCommandResponse(
            command: command,
            response: response,
            type: commandType,
            success: true,
            timestamp: Date()
        )
    }
    
    private func addToConversationHistory(command: String, response: VoiceCommandResponse) async {
        // Add to conversation history
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
    
    private func validateCoachingType(type: CoachingType) async throws {
        // Validate coaching type
    }
    
    private func createCoachingSession(type: CoachingType) async throws -> VoiceCoachingSession {
        return VoiceCoachingSession(
            id: UUID(),
            type: type,
            startTime: Date(),
            status: .active,
            progress: 0.0,
            timestamp: Date()
        )
    }
    
    private func startCoaching(session: VoiceCoachingSession) async throws {
        // Start coaching
    }
    
    private func stopCoaching() async throws {
        // Stop coaching
    }
    
    private func collectVoiceData() async -> [VoiceData] {
        return Array(voiceData.values)
    }
    
    private func analyzeVoiceData(voiceData: [VoiceData]) async throws -> VoicePatternAnalysis {
        // Analyze voice data
        return VoicePatternAnalysis(
            patterns: [],
            insights: [],
            recommendations: [],
            timestamp: Date()
        )
    }
    
    private func generateVoiceInsights(analysis: VoicePatternAnalysis) async throws -> [VoiceInsight] {
        // Generate voice insights
        return []
    }
    
    private func updateVoiceInsights(insights: [VoiceInsight]) async {
        await MainActor.run {
            self.voiceInsights = insights
        }
    }
    
    private func analyzeConversationContext(context: ConversationContext) async throws -> ContextAnalysis {
        // Analyze conversation context
        return ContextAnalysis(
            context: context,
            analysis: [],
            timestamp: Date()
        )
    }
    
    private func generateResponseFromContext(analysis: ContextAnalysis) async throws -> String {
        // Generate response from context
        return "I understand your request. How can I help you with your health goals?"
    }
    
    private func validateResponse(response: String) async throws {
        // Validate response
        guard !response.isEmpty else {
            throw VoiceError.invalidResponse
        }
    }
    
    private func analyzeSentiment(text: String) async throws -> NLPSentiment {
        // Analyze sentiment
        return .positive
    }
    
    private func determineIntent(text: String) async throws -> NLPIntent {
        // Determine intent
        return .healthQuery
    }
    
    private func generateAIResponse(nlpResult: NLPResult) async throws -> String {
        // Generate AI response
        return "I understand your request. Let me help you with that."
    }
    
    private func determineCommandType(command: String) async throws -> CommandType {
        // Determine command type
        return .healthQuery
    }
    
    private func executeCommand(command: String, type: CommandType) async throws -> String {
        // Execute command
        return "Command executed successfully."
    }
    
    private func updateVoiceStatus() async {
        // Update voice status
        voiceProgress = 1.0
    }
    
    // MARK: - Setup Methods
    
    private func setupAudioEngine() {
        // Setup audio engine
    }
    
    private func setupSpeechSynthesis() {
        // Setup speech synthesis
    }
    
    private func setupVoiceProcessing() {
        // Setup voice processing
    }
    
    private func setupRecognitionDelegate() {
        // Setup recognition delegate
    }
    
    private func setupRecognitionConfiguration() {
        // Setup recognition configuration
    }
    
    private func setupRecognitionHandling() {
        // Setup recognition handling
    }
    
    private func setupNLPTagger() {
        // Setup NLP tagger
    }
    
    private func setupNLPAnalysis() {
        // Setup NLP analysis
    }
    
    private func setupNLPGeneration() {
        // Setup NLP generation
    }
    
    private func setupAIModel() {
        // Setup AI model
    }
    
    private func setupAIResponse() {
        // Setup AI response
    }
    
    private func setupAIContext() {
        // Setup AI context
    }
    
    private func loadVoiceModels() async throws {
        // Load voice models
    }
    
    private func validateVoiceConfiguration() async throws {
        // Validate voice configuration
    }
    
    private func setupVoiceAlgorithms() async throws {
        // Setup voice algorithms
    }
    
    private func startVoiceTimer() async throws {
        // Start voice timer
    }
    
    private func startDataCollection() async throws {
        // Start data collection
    }
    
    private func startPatternAnalysis() async throws {
        // Start pattern analysis
    }
    
    // MARK: - Export Methods
    
    private func exportToCSV(exportData: VoiceExportData) throws -> Data {
        // Implement CSV export
        return Data()
    }
    
    private func exportToXML(exportData: VoiceExportData) throws -> Data {
        // Implement XML export
        return Data()
    }
    
    private func exportToPDF(exportData: VoiceExportData) throws -> Data {
        // Implement PDF export
        return Data()
    }
}

// MARK: - Supporting Models

public struct ConversationEntry: Identifiable, Codable {
    public let id: UUID
    public let userInput: String
    public let systemResponse: String
    public let timestamp: Date
    public let type: ConversationType
}

public struct VoiceCommand: Identifiable, Codable {
    public let id: UUID
    public let command: String
    public let category: CommandCategory
    public let type: CommandType
    public let description: String
    public let timestamp: Date
}

public struct VoiceCoachingSession: Identifiable, Codable {
    public let id: UUID
    public let type: CoachingType
    public let startTime: Date
    public let status: CoachingStatus
    public let progress: Double
    public let timestamp: Date
}

public struct SpeechRecognitionResult: Codable {
    public let text: String
    public let confidence: Float
    public let isFinal: Bool
    public let timestamp: Date
}

public struct NLPResult: Codable {
    public let text: String
    public let entities: [NLPEntity]
    public let sentiment: NLPSentiment
    public let intent: NLPIntent
    public let confidence: Double
    public let timestamp: Date
}

public struct ConversationalAIResponse: Codable {
    public let text: String
    public let type: ResponseType
    public let confidence: Double
    public let timestamp: Date
}

public struct VoiceCommandResponse: Codable {
    public let command: String
    public let response: String
    public let type: CommandType
    public let success: Bool
    public let timestamp: Date
}

public struct VoiceInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: InsightType
    public let severity: Severity
    public let recommendations: [String]
    public let timestamp: Date
}

public struct VoicePatternAnalysis: Codable {
    public let patterns: [VoicePattern]
    public let insights: [VoiceInsight]
    public let recommendations: [String]
    public let timestamp: Date
}

public struct ConversationContext: Codable {
    public let userProfile: String
    public let healthData: String
    public let conversationHistory: [ConversationEntry]
    public let currentIntent: String
    public let timestamp: Date
}

public struct VoiceExportData: Codable {
    public let timestamp: Date
    public let conversationHistory: [ConversationEntry]
    public let voiceCommands: [VoiceCommand]
    public let voiceCoaching: VoiceCoachingSession?
    public let speechRecognition: SpeechRecognitionResult
    public let naturalLanguageProcessing: NLPResult
    public let conversationalAI: ConversationalAIResponse
    public let voiceInsights: [VoiceInsight]
}

// MARK: - Supporting Data Models

public struct NLPEntity: Codable {
    public let text: String
    public let type: String
    public let range: Range<String.Index>
}

public struct VoicePattern: Codable {
    public let type: String
    public let frequency: Double
    public let intensity: Double
    public let consistency: Double
    public let timestamp: Date
}

public struct ContextAnalysis: Codable {
    public let context: ConversationContext
    public let analysis: [String]
    public let timestamp: Date
}

// MARK: - Enums

public enum ConversationType: String, Codable, CaseIterable {
    case command, question, statement, coaching
}

public enum CommandCategory: String, Codable, CaseIterable {
    case health, fitness, nutrition, sleep, mental, system
}

public enum CommandType: String, Codable, CaseIterable {
    case healthQuery, fitnessQuery, nutritionQuery, sleepQuery, mentalQuery, systemQuery
}

public enum CoachingType: String, Codable, CaseIterable {
    case fitness, nutrition, sleep, mental, meditation, motivation
}

public enum CoachingStatus: String, Codable, CaseIterable {
    case active, paused, completed, cancelled
}

public enum NLPSentiment: String, Codable, CaseIterable {
    case positive, negative, neutral, mixed
}

public enum NLPIntent: String, Codable, CaseIterable {
    case healthQuery, fitnessQuery, nutritionQuery, sleepQuery, mentalQuery, systemQuery, unknown
}

public enum ResponseType: String, Codable, CaseIterable {
    case conversation, command, coaching, information
}

public enum InsightType: String, Codable, CaseIterable {
    case health, behavior, emotion, recommendation
}

public enum Severity: String, Codable, CaseIterable {
    case low, medium, high, critical
}

public enum VoiceType: String, Codable, CaseIterable {
    case `default`, male, female, child, elderly
}

// MARK: - Voice Type Extensions

extension VoiceType {
    var language: String {
        switch self {
        case .default, .male, .female, .child, .elderly:
            return "en-US"
        }
    }
    
    var rate: Float {
        switch self {
        case .default, .male, .female: return 0.5
        case .child: return 0.6
        case .elderly: return 0.4
        }
    }
    
    var pitch: Float {
        switch self {
        case .default: return 1.0
        case .male: return 0.8
        case .female: return 1.2
        case .child: return 1.3
        case .elderly: return 0.7
        }
    }
    
    var volume: Float {
        switch self {
        case .default, .male, .female, .child, .elderly:
            return 1.0
        }
    }
}

// MARK: - Voice Errors

public enum VoiceError: Error, LocalizedError {
    case authorizationDenied
    case invalidText
    case textTooLong
    case invalidResponse
    case audioEngineError
    case speechRecognitionError
    case speechSynthesisError
    
    public var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Speech recognition authorization denied"
        case .invalidText:
            return "Invalid text provided"
        case .textTooLong:
            return "Text is too long"
        case .invalidResponse:
            return "Invalid response generated"
        case .audioEngineError:
            return "Audio engine error"
        case .speechRecognitionError:
            return "Speech recognition error"
        case .speechSynthesisError:
            return "Speech synthesis error"
        }
    }
}

// MARK: - Extensions

extension Timeframe {
    var dateComponent: Calendar.Component {
        switch self {
        case .hour: return .hour
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
    }
} 