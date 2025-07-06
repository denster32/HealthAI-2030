import Foundation
import Combine

/// Core protocols and data structures for Self-Evolving AI Health Agent
@available(iOS 18.0, macOS 15.0, *)

// MARK: - Core Protocols

/// Protocol for self-modifying AI agents
public protocol SelfModifyingAgent {
    func reflectAndModify() async -> ModificationResult
    func learn(from interaction: UserInteraction) async
    func consolidateMemory() async
    func updatePersonality(based traits: [PersonalityTrait]) async
    func simulateEmotion(for context: InteractionContext) async -> EmotionResponse
}

/// Protocol for memory consolidation systems
public protocol MemoryConsolidator {
    func consolidate(memories: [AgentMemory], personality: PersonalityProfile, emotionState: EmotionState) async -> [ConsolidatedMemory]
}

/// Protocol for personality adaptation engines
public protocol PersonalityEngine {
    func adapt(currentPersonality: PersonalityProfile, traits: [PersonalityTrait], learningHistory: [LearningEvent], adaptationHistory: [AdaptationEvent]) async -> PersonalityProfile
}

/// Protocol for emotion simulation systems
public protocol EmotionSimulator {
    func process(context: InteractionContext, currentEmotion: EmotionState, personality: PersonalityProfile, recentMemory: [AgentMemory], episodicMemory: [EpisodicMemory]) async -> EmotionResult
    func processUserFeedback(_ feedback: UserFeedback, currentEmotion: EmotionState) async -> EmotionState
    func updateSensitivity(_ sensitivity: Double)
}

/// Protocol for learning systems
public protocol LearningSystem {
    func process(signals: [LearningSignal]) async
    func generateResponse(for interaction: UserInteraction, style: ResponseStyle, memory: [AgentMemory], personality: PersonalityProfile, emotionState: EmotionState) async -> String
    func updateStrategy(_ strategy: ResponseStrategy) async
    func updateConfidenceCalibration(_ calibration: Double) async
    func updateStrategies(_ strategies: [LearningStrategy]) async
}

/// Protocol for evolution engines
public protocol EvolutionEngine {
    func generateModification(for area: ImprovementArea, agent: SelfEvolvingHealthAgent) async -> AgentModification?
    func testModification(_ modification: AgentModification, agent: SelfEvolvingHealthAgent) async -> ModificationTestResult
}

/// Protocol for meta-learning systems
public protocol MetaLearningEngine {
    func analyze(learningHistory: [LearningEvent], adaptationHistory: [AdaptationEvent], performanceMetrics: PerformanceMetrics) async -> MetaLearningResult
    func processFeedback(_ feedback: UserFeedback, agent: SelfEvolvingHealthAgent) async
}

// MARK: - Data Structures

/// Comprehensive personality profile using Big Five model
public struct PersonalityProfile: Codable, Equatable {
    public var openness: Double           // 0.0 - 1.0
    public var conscientiousness: Double  // 0.0 - 1.0
    public var extraversion: Double       // 0.0 - 1.0
    public var agreeableness: Double      // 0.0 - 1.0
    public var neuroticism: Double        // 0.0 - 1.0
    public var adaptationRate: Double     // Learning speed
    public var stability: Double          // Resistance to change
    
    public init(openness: Double, conscientiousness: Double, extraversion: Double, agreeableness: Double, neuroticism: Double, adaptationRate: Double = 0.05, stability: Double = 0.7) {
        self.openness = max(0.0, min(1.0, openness))
        self.conscientiousness = max(0.0, min(1.0, conscientiousness))
        self.extraversion = max(0.0, min(1.0, extraversion))
        self.agreeableness = max(0.0, min(1.0, agreeableness))
        self.neuroticism = max(0.0, min(1.0, neuroticism))
        self.adaptationRate = max(0.001, min(0.1, adaptationRate))
        self.stability = max(0.1, min(0.9, stability))
    }
    
    public static func defaultProfile() -> PersonalityProfile {
        return PersonalityProfile(
            openness: 0.6,
            conscientiousness: 0.7,
            extraversion: 0.5,
            agreeableness: 0.8,
            neuroticism: 0.3,
            adaptationRate: 0.05,
            stability: 0.7
        )
    }
    
    public static func therapeuticProfile() -> PersonalityProfile {
        return PersonalityProfile(
            openness: 0.8,
            conscientiousness: 0.9,
            extraversion: 0.4,
            agreeableness: 0.95,
            neuroticism: 0.1,
            adaptationRate: 0.03,
            stability: 0.8
        )
    }
}

/// Multi-dimensional emotion state
public struct EmotionState: Codable, Equatable {
    public var valence: Double      // Positive/Negative emotion (-1.0 to 1.0)
    public var arousal: Double      // Energy level (0.0 to 1.0)
    public var dominance: Double    // Control/submission (0.0 to 1.0)
    public var empathy: Double      // Empathetic response level (0.0 to 1.0)
    public var confidence: Double   // Certainty in responses (0.0 to 1.0)
    
    public init(valence: Double, arousal: Double, dominance: Double, empathy: Double, confidence: Double) {
        self.valence = max(-1.0, min(1.0, valence))
        self.arousal = max(0.0, min(1.0, arousal))
        self.dominance = max(0.0, min(1.0, dominance))
        self.empathy = max(0.0, min(1.0, empathy))
        self.confidence = max(0.0, min(1.0, confidence))
    }
    
    public static func neutral() -> EmotionState {
        return EmotionState(valence: 0.0, arousal: 0.3, dominance: 0.5, empathy: 0.7, confidence: 0.6)
    }
    
    public static func supportive() -> EmotionState {
        return EmotionState(valence: 0.4, arousal: 0.4, dominance: 0.3, empathy: 0.9, confidence: 0.8)
    }
    
    public static func alert() -> EmotionState {
        return EmotionState(valence: 0.0, arousal: 0.8, dominance: 0.7, empathy: 0.6, confidence: 0.9)
    }
}

/// Agent operational states
public enum AgentState: String, Codable, CaseIterable {
    case initializing = "initializing"
    case active = "active"
    case reflecting = "reflecting"
    case evolving = "evolving"
    case adapting = "adapting"
    case maintaining = "maintaining"
    case error = "error"
}

/// User interaction context
public struct InteractionContext: Codable {
    public let category: String
    public let isHealthRelated: Bool
    public let isEmergency: Bool
    public let isTherapeutic: Bool
    public let containsFeedback: Bool
    public let emotionalIntensity: Double     // 0.0 to 1.0
    public let emotionalValence: Double       // -1.0 to 1.0
    public let emotionalResonance: Double     // 0.0 to 1.0
    public let userSatisfaction: Double?      // 0.0 to 1.0
    public let wasSuccessful: Bool
    public let feedbackPolarity: Double       // -1.0 to 1.0
    public let keywords: [String]
    public let timestamp: Date
    
    public init(category: String, isHealthRelated: Bool = false, isEmergency: Bool = false, isTherapeutic: Bool = false, containsFeedback: Bool = false, emotionalIntensity: Double = 0.0, emotionalValence: Double = 0.0, emotionalResonance: Double = 0.0, userSatisfaction: Double? = nil, wasSuccessful: Bool = true, feedbackPolarity: Double = 0.0, keywords: [String] = [], timestamp: Date = Date()) {
        self.category = category
        self.isHealthRelated = isHealthRelated
        self.isEmergency = isEmergency
        self.isTherapeutic = isTherapeutic
        self.containsFeedback = containsFeedback
        self.emotionalIntensity = max(0.0, min(1.0, emotionalIntensity))
        self.emotionalValence = max(-1.0, min(1.0, emotionalValence))
        self.emotionalResonance = max(0.0, min(1.0, emotionalResonance))
        self.userSatisfaction = userSatisfaction
        self.wasSuccessful = wasSuccessful
        self.feedbackPolarity = max(-1.0, min(1.0, feedbackPolarity))
        self.keywords = keywords
        self.timestamp = timestamp
    }
}

/// User interaction data
public struct UserInteraction: Codable {
    public let id: UUID
    public let input: String
    public let context: InteractionContext
    public let timestamp: Date
    public let metadata: [String: String]
    
    public init(input: String, context: InteractionContext, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.input = input
        self.context = context
        self.timestamp = Date()
        self.metadata = metadata
    }
}

/// Agent memory structure
public struct AgentMemory: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let interactionContext: InteractionContext
    public let userInput: String
    public let agentResponse: String
    public var outcome: InteractionOutcome
    public let emotionalState: EmotionState
    public let importance: Double
    public let tags: [String]
    public let memoryType: MemoryType
    
    public init(id: UUID = UUID(), timestamp: Date, interactionContext: InteractionContext, userInput: String, agentResponse: String, outcome: InteractionOutcome, emotionalState: EmotionState, importance: Double, tags: [String], memoryType: MemoryType) {
        self.id = id
        self.timestamp = timestamp
        self.interactionContext = interactionContext
        self.userInput = userInput
        self.agentResponse = agentResponse
        self.outcome = outcome
        self.emotionalState = emotionalState
        self.importance = max(0.0, min(1.0, importance))
        self.tags = tags
        self.memoryType = memoryType
    }
}

/// Types of memory
public enum MemoryType: String, Codable, CaseIterable {
    case episodic = "episodic"
    case semantic = "semantic"
    case procedural = "procedural"
    case working = "working"
}

/// Interaction outcomes
public enum InteractionOutcome: String, Codable, CaseIterable {
    case pending = "pending"
    case successful = "successful"
    case failed = "failed"
    case partially_successful = "partially_successful"
}

/// Learning events
public struct LearningEvent: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let eventType: LearningEventType
    public let trigger: String
    public let modification: AgentModification
    public let success: Bool
    public let impact: Double
    public let confidence: Double
    
    public init(id: UUID = UUID(), timestamp: Date, eventType: LearningEventType, trigger: String, modification: AgentModification, success: Bool, impact: Double, confidence: Double) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.trigger = trigger
        self.modification = modification
        self.success = success
        self.impact = max(0.0, min(1.0, impact))
        self.confidence = max(0.0, min(1.0, confidence))
    }
}

/// Types of learning events
public enum LearningEventType: String, Codable, CaseIterable {
    case interactionLearning = "interaction_learning"
    case userFeedback = "user_feedback"
    case selfModification = "self_modification"
    case memoryConsolidation = "memory_consolidation"
    case personalityAdaptation = "personality_adaptation"
    case stateChange = "state_change"
    case errorCorrection = "error_correction"
}

/// Agent modifications
public enum AgentModification: Codable, Equatable {
    case personalityUpdate
    case learningRateAdjustment(Double)
    case memoryOptimization
    case responseStrategyUpdate(ResponseStrategy)
    case emotionSensitivityAdjustment(Double)
    case personalityStabilization(Double)
    case confidenceCalibration(Double)
    case feedbackIntegration
    case learningUpdate
    case stateUpdate
    
    public var impact: Double {
        switch self {
        case .personalityUpdate: return 0.3
        case .learningRateAdjustment: return 0.2
        case .memoryOptimization: return 0.4
        case .responseStrategyUpdate: return 0.3
        case .emotionSensitivityAdjustment: return 0.2
        case .personalityStabilization: return 0.1
        case .confidenceCalibration: return 0.2
        case .feedbackIntegration: return 0.4
        case .learningUpdate: return 0.2
        case .stateUpdate: return 0.1
        }
    }
}

/// Personality traits for adaptation
public struct PersonalityTrait: Codable {
    public let dimension: PersonalityDimension
    public let adjustment: Double      // -1.0 to 1.0
    public let confidence: Double      // 0.0 to 1.0
    public let source: TraitSource
    
    public init(dimension: PersonalityDimension, adjustment: Double, confidence: Double, source: TraitSource) {
        self.dimension = dimension
        self.adjustment = max(-1.0, min(1.0, adjustment))
        self.confidence = max(0.0, min(1.0, confidence))
        self.source = source
    }
}

/// Big Five personality dimensions
public enum PersonalityDimension: String, Codable, CaseIterable {
    case openness = "openness"
    case conscientiousness = "conscientiousness"
    case extraversion = "extraversion"
    case agreeableness = "agreeableness"
    case neuroticism = "neuroticism"
}

/// Sources of personality trait adjustments
public enum TraitSource: String, Codable, CaseIterable {
    case userFeedback = "user_feedback"
    case interactionPattern = "interaction_pattern"
    case performanceAnalysis = "performance_analysis"
    case emergencyResponse = "emergency_response"
    case therapeuticNeed = "therapeutic_need"
}

/// Emotion response data
public struct EmotionResponse: Codable {
    public let tone: EmotionTone
    public let confidence: Double
    public let empathy: Double
    public let arousal: Double
    public let appropriateness: Double
    
    public init(tone: EmotionTone, confidence: Double, empathy: Double, arousal: Double, appropriateness: Double) {
        self.tone = tone
        self.confidence = max(0.0, min(1.0, confidence))
        self.empathy = max(0.0, min(1.0, empathy))
        self.arousal = max(0.0, min(1.0, arousal))
        self.appropriateness = max(0.0, min(1.0, appropriateness))
    }
}

/// Emotion tones
public enum EmotionTone: String, Codable, CaseIterable {
    case supportive = "supportive"
    case empathetic = "empathetic"
    case professional = "professional"
    case urgent = "urgent"
    case calming = "calming"
    case encouraging = "encouraging"
    case neutral = "neutral"
    case concerned = "concerned"
}

/// Response styles
public struct ResponseStyle: Codable {
    public let formality: Double        // 0.0 to 1.0
    public let warmth: Double           // 0.0 to 1.0
    public let confidence: Double       // 0.0 to 1.0
    public let verbosity: Double        // 0.0 to 1.0
    public let supportiveness: Double   // 0.0 to 1.0
    public let adaptiveness: Double     // 0.0 to 1.0
    
    public init(formality: Double, warmth: Double, confidence: Double, verbosity: Double, supportiveness: Double, adaptiveness: Double) {
        self.formality = max(0.0, min(1.0, formality))
        self.warmth = max(0.0, min(1.0, warmth))
        self.confidence = max(0.0, min(1.0, confidence))
        self.verbosity = max(0.0, min(1.0, verbosity))
        self.supportiveness = max(0.0, min(1.0, supportiveness))
        self.adaptiveness = max(0.0, min(1.0, adaptiveness))
    }
}

/// Response strategies
public enum ResponseStrategy: String, Codable, CaseIterable {
    case informational = "informational"
    case therapeutic = "therapeutic"
    case emergency = "emergency"
    case empathetic = "empathetic"
    case adaptive = "adaptive"
    case educational = "educational"
    case motivational = "motivational"
}

/// Agent response data
public struct AgentResponse: Codable {
    public let content: String
    public let emotionalTone: EmotionTone
    public let confidence: Double
    public let personalityExpression: ResponseStyle
    public let responseStrategy: ResponseStrategy
    public let adaptationLevel: Double
    public let timestamp: Date
    public let processingTime: TimeInterval
    
    public init(content: String, emotionalTone: EmotionTone, confidence: Double, personalityExpression: ResponseStyle, responseStrategy: ResponseStrategy, adaptationLevel: Double, timestamp: Date, processingTime: TimeInterval = 0.0) {
        self.content = content
        self.emotionalTone = emotionalTone
        self.confidence = max(0.0, min(1.0, confidence))
        self.personalityExpression = personalityExpression
        self.responseStrategy = responseStrategy
        self.adaptationLevel = max(0.0, min(1.0, adaptationLevel))
        self.timestamp = timestamp
        self.processingTime = processingTime
    }
}

/// User feedback structure
public struct UserFeedback: Codable {
    public let id: UUID
    public let type: FeedbackType
    public let content: String
    public let importance: Double
    public let confidence: Double
    public let emotionalValence: Double
    public let personalityHints: [PersonalityTrait]
    public let context: InteractionContext
    public let timestamp: Date
    
    public init(type: FeedbackType, content: String, importance: Double, confidence: Double, emotionalValence: Double, personalityHints: [PersonalityTrait] = [], context: InteractionContext) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.importance = max(0.0, min(1.0, importance))
        self.confidence = max(0.0, min(1.0, confidence))
        self.emotionalValence = max(-1.0, min(1.0, emotionalValence))
        self.personalityHints = personalityHints
        self.context = context
        self.timestamp = Date()
    }
}

/// Feedback types
public enum FeedbackType: String, Codable, CaseIterable {
    case positive = "positive"
    case negative = "negative"
    case corrective = "corrective"
    case instructional = "instructional"
    case emotional = "emotional"
    case behavioral = "behavioral"
}

/// Learning signals
public enum LearningSignal: Codable {
    case userSatisfaction(Double)
    case interactionSuccess(Bool)
    case emotionalResonance(Double)
    case noveltyDetected(Double)
    case explicitFeedback(Double)
    case performanceMetric(String, Double)
    case errorDetected(String)
}

/// Improvement areas
public enum ImprovementArea: String, Codable, CaseIterable {
    case responseQuality = "response_quality"
    case memoryManagement = "memory_management"
    case processingSpeed = "processing_speed"
    case learningAgility = "learning_agility"
    case learningEfficiency = "learning_efficiency"
    case confidenceCalibration = "confidence_calibration"
    case emotionalIntelligence = "emotional_intelligence"
    case personalityAdaptation = "personality_adaptation"
}

/// Performance analysis
public struct PerformanceAnalysis: Codable {
    public let successRate: Double
    public let averageImpact: Double
    public let adaptationFrequency: Double
    public let learningEfficiency: Double
    public let memoryEfficiency: Double
    public let responseQuality: Double
    public let confidenceLevel: Double
    
    public init(successRate: Double, averageImpact: Double, adaptationFrequency: Double, learningEfficiency: Double, memoryEfficiency: Double, responseQuality: Double, confidenceLevel: Double) {
        self.successRate = max(0.0, min(1.0, successRate))
        self.averageImpact = max(0.0, min(1.0, averageImpact))
        self.adaptationFrequency = max(0.0, min(1.0, adaptationFrequency))
        self.learningEfficiency = max(0.0, min(1.0, learningEfficiency))
        self.memoryEfficiency = max(0.0, min(1.0, memoryEfficiency))
        self.responseQuality = max(0.0, min(1.0, responseQuality))
        self.confidenceLevel = max(0.0, min(1.0, confidenceLevel))
    }
}

/// Modification results
public struct ModificationResult: Codable {
    public let modifications: [AgentModification]
    public let rejectedModifications: [AgentModification]
    public let improvementAreas: [ImprovementArea]
    public let overallImprovement: Double
    public let performanceAnalysis: PerformanceAnalysis
    public let timestamp: Date
    
    public init(modifications: [AgentModification], rejectedModifications: [AgentModification], improvementAreas: [ImprovementArea], overallImprovement: Double, performanceAnalysis: PerformanceAnalysis, timestamp: Date) {
        self.modifications = modifications
        self.rejectedModifications = rejectedModifications
        self.improvementAreas = improvementAreas
        self.overallImprovement = max(0.0, min(1.0, overallImprovement))
        self.performanceAnalysis = performanceAnalysis
        self.timestamp = timestamp
    }
}

/// Modification test results
public struct ModificationTestResult: Codable {
    public let success: Bool
    public let improvementScore: Double
    public let confidence: Double
    public let risks: [String]
    public let metrics: [String: Double]
    
    public init(success: Bool, improvementScore: Double, confidence: Double, risks: [String] = [], metrics: [String: Double] = [:]) {
        self.success = success
        self.improvementScore = max(-1.0, min(1.0, improvementScore))
        self.confidence = max(0.0, min(1.0, confidence))
        self.risks = risks
        self.metrics = metrics
    }
}

/// Agent status information
public struct AgentStatus: Codable {
    public let state: AgentState
    public let personality: PersonalityProfile
    public let emotionState: EmotionState
    public let memoryCount: Int
    public let episodicMemoryCount: Int
    public let learningEventsCount: Int
    public let adaptationEventsCount: Int
    public let lastReflection: Date?
    public let lastConsolidation: Date?
    public let adaptationRate: Double
    public let stability: Double
    public let memoryUtilization: Double
    public let performanceMetrics: PerformanceMetrics
    public let successfulModifications: Int
    
    public init(state: AgentState, personality: PersonalityProfile, emotionState: EmotionState, memoryCount: Int, episodicMemoryCount: Int, learningEventsCount: Int, adaptationEventsCount: Int, lastReflection: Date?, lastConsolidation: Date?, adaptationRate: Double, stability: Double, memoryUtilization: Double, performanceMetrics: PerformanceMetrics, successfulModifications: Int) {
        self.state = state
        self.personality = personality
        self.emotionState = emotionState
        self.memoryCount = memoryCount
        self.episodicMemoryCount = episodicMemoryCount
        self.learningEventsCount = learningEventsCount
        self.adaptationEventsCount = adaptationEventsCount
        self.lastReflection = lastReflection
        self.lastConsolidation = lastConsolidation
        self.adaptationRate = adaptationRate
        self.stability = stability
        self.memoryUtilization = max(0.0, min(1.0, memoryUtilization))
        self.performanceMetrics = performanceMetrics
        self.successfulModifications = successfulModifications
    }
}

/// Performance metrics
public struct PerformanceMetrics: Codable {
    public var totalInteractions: Int = 0
    public var healthInteractions: Int = 0
    public var emergencyInteractions: Int = 0
    public var averageResponseTime: TimeInterval = 0.0
    public var averageConfidence: Double = 0.6
    public var successfulAdaptations: Int = 0
    public var failedAdaptations: Int = 0
    
    public init() {}
    
    public var adaptationSuccessRate: Double {
        let total = successfulAdaptations + failedAdaptations
        return total > 0 ? Double(successfulAdaptations) / Double(total) : 0.5
    }
    
    public var healthInteractionRatio: Double {
        return totalInteractions > 0 ? Double(healthInteractions) / Double(totalInteractions) : 0.0
    }
}

/// Episodic memory for significant events
public struct EpisodicMemory: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let event: EpisodicEvent
    public let context: InteractionContext
    public let emotionalValence: Double
    public let importance: Double
    public var associatedMemories: [UUID]
    
    public init(id: UUID = UUID(), timestamp: Date, event: EpisodicEvent, context: InteractionContext, emotionalValence: Double, importance: Double, associatedMemories: [UUID]) {
        self.id = id
        self.timestamp = timestamp
        self.event = event
        self.context = context
        self.emotionalValence = max(-1.0, min(1.0, emotionalValence))
        self.importance = max(0.0, min(1.0, importance))
        self.associatedMemories = associatedMemories
    }
}

/// Types of episodic events
public enum EpisodicEvent: String, Codable, CaseIterable {
    case userFeedback = "user_feedback"
    case emergencyInteraction = "emergency_interaction"
    case significantAdaptation = "significant_adaptation"
    case therapeuticBreakthrough = "therapeutic_breakthrough"
    case errorEvent = "error_event"
    case milestone = "milestone"
}

/// Consolidated memory structure
public struct ConsolidatedMemory: Codable {
    public let consolidatedMemory: AgentMemory
    public let originalMemories: [AgentMemory]
    public let consolidationStrategy: ConsolidationStrategy
    public let compressionRatio: Double
    
    public init(consolidatedMemory: AgentMemory, originalMemories: [AgentMemory], consolidationStrategy: ConsolidationStrategy, compressionRatio: Double) {
        self.consolidatedMemory = consolidatedMemory
        self.originalMemories = originalMemories
        self.consolidationStrategy = consolidationStrategy
        self.compressionRatio = max(0.0, min(1.0, compressionRatio))
    }
}

/// Memory consolidation strategies
public enum ConsolidationStrategy: String, Codable, CaseIterable {
    case semantic = "semantic"
    case temporal = "temporal"
    case importance = "importance"
    case emotional = "emotional"
    case similarity = "similarity"
}

/// Adaptation events
public struct AdaptationEvent: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let type: AdaptationType
    public let description: String
    public let success: Bool
    public let impact: Double
    
    public init(id: UUID = UUID(), timestamp: Date, type: AdaptationType, description: String, success: Bool, impact: Double) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.description = description
        self.success = success
        self.impact = max(0.0, min(1.0, impact))
    }
}

/// Types of adaptations
public enum AdaptationType: String, Codable, CaseIterable {
    case personalityAdaptation = "personality_adaptation"
    case learningRateAdjustment = "learning_rate_adjustment"
    case memoryOptimization = "memory_optimization"
    case emotionCalibration = "emotion_calibration"
    case responseStrategy = "response_strategy"
    case metaLearning = "meta_learning"
}

/// Learning strategies
public enum LearningStrategy: String, Codable, CaseIterable {
    case conservative = "conservative"
    case aggressive = "aggressive"
    case balanced = "balanced"
    case userDriven = "user_driven"
    case contextual = "contextual"
    case therapeutic = "therapeutic"
}

/// Meta-learning results
public struct MetaLearningResult: Codable {
    public let shouldAdapt: Bool
    public let recommendedAdaptationRate: Double
    public let recommendedStrategies: [LearningStrategy]
    public let expectedImpact: Double
    public let description: String
    public let confidence: Double
    
    public init(shouldAdapt: Bool, recommendedAdaptationRate: Double, recommendedStrategies: [LearningStrategy], expectedImpact: Double, description: String, confidence: Double) {
        self.shouldAdapt = shouldAdapt
        self.recommendedAdaptationRate = max(0.001, min(0.1, recommendedAdaptationRate))
        self.recommendedStrategies = recommendedStrategies
        self.expectedImpact = max(0.0, min(1.0, expectedImpact))
        self.description = description
        self.confidence = max(0.0, min(1.0, confidence))
    }
}

/// Emotion processing results
public struct EmotionResult: Codable {
    public let state: EmotionState
    public let response: EmotionResponse
    public let reasoning: String
    public let confidence: Double
    
    public init(state: EmotionState, response: EmotionResponse, reasoning: String, confidence: Double) {
        self.state = state
        self.response = response
        self.reasoning = reasoning
        self.confidence = max(0.0, min(1.0, confidence))
    }
}

/// Agent learning data for export
public struct AgentLearningData: Codable {
    public let personality: PersonalityProfile
    public let emotionState: EmotionState
    public let memoryCount: Int
    public let learningHistory: [LearningEvent]
    public let adaptationHistory: [AdaptationEvent]
    public let performanceMetrics: PerformanceMetrics
    public let exportTimestamp: Date
    
    public init(personality: PersonalityProfile, emotionState: EmotionState, memoryCount: Int, learningHistory: [LearningEvent], adaptationHistory: [AdaptationEvent], performanceMetrics: PerformanceMetrics, exportTimestamp: Date) {
        self.personality = personality
        self.emotionState = emotionState
        self.memoryCount = memoryCount
        self.learningHistory = learningHistory
        self.adaptationHistory = adaptationHistory
        self.performanceMetrics = performanceMetrics
        self.exportTimestamp = exportTimestamp
    }
}