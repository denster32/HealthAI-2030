import Foundation
import HealthAI2030Core
import AsyncAlgorithms

/// Advanced conversational AI engine for natural health coaching interactions
@globalActor
public actor ConversationalAIEngine {
    public static let shared = ConversationalAIEngine()
    
    private var languageModel: HealthLanguageModel
    private var responseGenerator: ResponseGenerator
    private var contextProcessor: ContextProcessor
    private var personalityEngine: PersonalityEngine
    private var isInitialized = false
    
    private init() {
        self.languageModel = HealthLanguageModel()
        self.responseGenerator = ResponseGenerator()
        self.contextProcessor = ContextProcessor()
        self.personalityEngine = PersonalityEngine()
    }
    
    // MARK: - Public Interface
    
    /// Initialize the conversational AI engine
    public func initialize() async throws {
        guard !isInitialized else { return }
        
        try await languageModel.loadModel()
        await responseGenerator.initialize()
        await contextProcessor.initialize()
        await personalityEngine.loadPersonalities()
        
        isInitialized = true
    }
    
    /// Generate a response to user input
    public func generateResponse(
        to userInput: String,
        reasoning: HealthReasoning,
        personality: CoachPersonality,
        context: ConversationContext
    ) async -> ConversationalResponse {
        guard isInitialized else {
            return ConversationalResponse.error("AI engine not initialized")
        }
        
        // Process user input through language model
        let userIntent = await languageModel.analyzeIntent(userInput, context: context)
        
        // Generate base response using reasoning
        let baseResponse = await responseGenerator.generateBaseResponse(
            intent: userIntent,
            reasoning: reasoning,
            context: context
        )
        
        // Apply personality adjustments
        let personalizedResponse = await personalityEngine.applyPersonality(
            baseResponse,
            personality: personality,
            context: context
        )
        
        // Generate suggestions and action items
        let suggestions = await generateSuggestions(reasoning, personality: personality)
        let actionItems = await generateActionItems(reasoning, personality: personality)
        let followUpQuestions = await generateFollowUpQuestions(userIntent, context: context)
        let healthInsights = await extractHealthInsights(reasoning)
        
        return ConversationalResponse(
            content: personalizedResponse.content,
            confidence: personalizedResponse.confidence,
            suggestions: suggestions,
            actionItems: actionItems,
            followUpQuestions: followUpQuestions,
            healthInsights: healthInsights,
            goalUpdates: reasoning.goalUpdates
        )
    }
    
    /// Extract key points from conversation messages
    public func extractKeyPoints(_ messages: [ConversationMessage]) async -> [String] {
        let conversationText = messages.map { $0.content }.joined(separator: " ")
        return await languageModel.extractKeyPoints(from: conversationText)
    }
    
    // MARK: - Private Implementation
    
    private func generateSuggestions(
        _ reasoning: HealthReasoning,
        personality: CoachPersonality
    ) async -> [HealthSuggestion] {
        var suggestions: [HealthSuggestion] = []
        
        // Generate suggestions based on reasoning insights
        for insight in reasoning.insights {
            if let suggestion = await convertInsightToSuggestion(insight, personality: personality) {
                suggestions.append(suggestion)
            }
        }
        
        // Add personality-specific suggestions
        let personalitySuggestions = await personalityEngine.generateSuggestions(
            reasoning: reasoning,
            personality: personality
        )
        
        suggestions.append(contentsOf: personalitySuggestions)
        
        return Array(suggestions.prefix(3)) // Limit to 3 suggestions
    }
    
    private func generateActionItems(
        _ reasoning: HealthReasoning,
        personality: CoachPersonality
    ) async -> [ActionItem] {
        var actionItems: [ActionItem] = []
        
        // Convert recommendations to actionable items
        for recommendation in reasoning.recommendations {
            let actionItem = ActionItem(
                title: recommendation.title,
                description: recommendation.description,
                priority: mapPriorityFromRecommendation(recommendation),
                estimatedTimeMinutes: recommendation.estimatedTimeMinutes,
                dueDate: recommendation.suggestedDeadline
            )
            actionItems.append(actionItem)
        }
        
        // Add personality-specific action items
        let personalityActions = await personalityEngine.generateActionItems(
            reasoning: reasoning,
            personality: personality
        )
        
        actionItems.append(contentsOf: personalityActions)
        
        return Array(actionItems.prefix(3)) // Limit to 3 action items
    }
    
    private func generateFollowUpQuestions(
        _ userIntent: UserIntent,
        context: ConversationContext
    ) async -> [String] {
        return await responseGenerator.generateFollowUpQuestions(
            intent: userIntent,
            context: context
        )
    }
    
    private func extractHealthInsights(_ reasoning: HealthReasoning) async -> [HealthInsight] {
        return reasoning.insights.map { insight in
            HealthInsight(
                title: insight.title,
                content: insight.description,
                confidence: insight.confidence,
                category: mapInsightCategory(insight.category),
                supportingData: insight.supportingData
            )
        }
    }
    
    private func convertInsightToSuggestion(
        _ insight: ReasoningInsight,
        personality: CoachPersonality
    ) async -> HealthSuggestion? {
        // Convert reasoning insight to health suggestion
        guard insight.confidence > 0.6 else { return nil }
        
        let suggestion = HealthSuggestion(
            title: insight.title,
            description: await personalityEngine.adjustSuggestionForPersonality(
                insight.description,
                personality: personality
            ),
            category: mapSuggestionCategory(insight.category),
            evidenceLevel: mapEvidenceLevel(insight.confidence)
        )
        
        return suggestion
    }
    
    private func mapPriorityFromRecommendation(_ recommendation: HealthRecommendation) -> ActionItem.Priority {
        switch recommendation.priority {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .urgent: return .urgent
        }
    }
    
    private func mapInsightCategory(_ category: ReasoningInsight.Category) -> HealthInsight.Category {
        switch category {
        case .pattern: return .pattern
        case .correlation: return .correlation
        case .prediction: return .prediction
        case .recommendation: return .recommendation
        }
    }
    
    private func mapSuggestionCategory(_ category: ReasoningInsight.Category) -> HealthSuggestion.Category {
        switch category {
        case .pattern: return .lifestyle
        case .correlation: return .lifestyle
        case .prediction: return .medical
        case .recommendation: return .lifestyle
        }
    }
    
    private func mapEvidenceLevel(_ confidence: Double) -> HealthSuggestion.EvidenceLevel {
        switch confidence {
        case 0.9...1.0: return .high
        case 0.7..<0.9: return .medium
        case 0.5..<0.7: return .low
        default: return .anecdotal
        }
    }
}

// MARK: - Language Model

public actor HealthLanguageModel {
    private var modelTokenizer: Tokenizer?
    private var intentClassifier: IntentClassifier
    private var keyPointExtractor: KeyPointExtractor
    
    public init() {
        self.intentClassifier = IntentClassifier()
        self.keyPointExtractor = KeyPointExtractor()
    }
    
    public func loadModel() async throws {
        // In a real implementation, this would load a trained health language model
        // For now, we'll use rule-based and pattern matching approaches
        
        modelTokenizer = Tokenizer()
        await intentClassifier.initialize()
        await keyPointExtractor.initialize()
    }
    
    public func analyzeIntent(_ input: String, context: ConversationContext) async -> UserIntent {
        // Tokenize input
        let tokens = await modelTokenizer?.tokenize(input) ?? []
        
        // Classify intent
        return await intentClassifier.classify(tokens: tokens, context: context)
    }
    
    public func extractKeyPoints(from text: String) async -> [String] {
        return await keyPointExtractor.extract(from: text)
    }
}

// MARK: - Response Generator

public actor ResponseGenerator {
    private var responseTemplates: [String: [ResponseTemplate]] = [:]
    private var healthFacts: [HealthFact] = []
    
    public func initialize() async {
        await loadResponseTemplates()
        await loadHealthFacts()
    }
    
    public func generateBaseResponse(
        intent: UserIntent,
        reasoning: HealthReasoning,
        context: ConversationContext
    ) async -> BaseResponse {
        // Select appropriate response template
        let template = selectTemplate(for: intent, reasoning: reasoning)
        
        // Fill template with context-specific information
        let filledTemplate = await fillTemplate(
            template,
            intent: intent,
            reasoning: reasoning,
            context: context
        )
        
        // Calculate confidence based on reasoning and context
        let confidence = calculateResponseConfidence(intent, reasoning: reasoning, context: context)
        
        return BaseResponse(
            content: filledTemplate,
            confidence: confidence,
            template: template
        )
    }
    
    public func generateFollowUpQuestions(
        intent: UserIntent,
        context: ConversationContext
    ) async -> [String] {
        var questions: [String] = []
        
        // Generate intent-specific follow-up questions
        switch intent.category {
        case .sleep:
            questions.append(contentsOf: [
                "How many hours of sleep did you get last night?",
                "Do you have a consistent bedtime routine?",
                "What time do you usually go to bed?"
            ])
            
        case .exercise:
            questions.append(contentsOf: [
                "What type of exercise do you enjoy most?",
                "How often do you currently exercise?",
                "Do you have any physical limitations I should know about?"
            ])
            
        case .nutrition:
            questions.append(contentsOf: [
                "What does a typical meal look like for you?",
                "Do you have any dietary restrictions?",
                "How much water do you drink daily?"
            ])
            
        case .stress:
            questions.append(contentsOf: [
                "What are your main sources of stress?",
                "Do you practice any stress management techniques?",
                "How does stress typically affect you physically?"
            ])
            
        case .general:
            questions.append(contentsOf: [
                "What health goal is most important to you right now?",
                "How are you feeling today compared to yesterday?",
                "Is there anything specific you'd like to improve?"
            ])
        }
        
        // Filter based on conversation history to avoid repetition
        return await filterRepeatedQuestions(questions, context: context)
    }
    
    private func loadResponseTemplates() async {
        // Load response templates for different intent categories
        responseTemplates = [
            "sleep": [
                ResponseTemplate(
                    id: "sleep_general",
                    pattern: "Sleep is crucial for {health_aspect}. Based on your {data_point}, I recommend {recommendation}.",
                    variables: ["health_aspect", "data_point", "recommendation"]
                ),
                ResponseTemplate(
                    id: "sleep_improvement",
                    pattern: "I notice you want to improve your sleep. {insight} Here's what you can try: {suggestion}",
                    variables: ["insight", "suggestion"]
                )
            ],
            "exercise": [
                ResponseTemplate(
                    id: "exercise_encouragement",
                    pattern: "That's great that you're thinking about exercise! {motivation} Based on your current level, {recommendation}.",
                    variables: ["motivation", "recommendation"]
                )
            ],
            "nutrition": [
                ResponseTemplate(
                    id: "nutrition_guidance",
                    pattern: "Nutrition plays a key role in {health_goal}. {insight} Consider {suggestion}.",
                    variables: ["health_goal", "insight", "suggestion"]
                )
            ]
        ]
    }
    
    private func loadHealthFacts() async {
        // Load evidence-based health facts for educational responses
        healthFacts = [
            HealthFact(
                topic: "sleep",
                fact: "Adults need 7-9 hours of sleep per night for optimal health",
                evidence: "Recommended by the National Sleep Foundation"
            ),
            HealthFact(
                topic: "exercise",
                fact: "150 minutes of moderate exercise per week reduces disease risk",
                evidence: "World Health Organization guidelines"
            ),
            HealthFact(
                topic: "hydration",
                fact: "Proper hydration improves cognitive function and physical performance",
                evidence: "Multiple clinical studies"
            )
        ]
    }
    
    private func selectTemplate(for intent: UserIntent, reasoning: HealthReasoning) -> ResponseTemplate {
        let categoryTemplates = responseTemplates[intent.category.rawValue] ?? []
        
        // Select template based on intent specificity and reasoning insights
        return categoryTemplates.first ?? ResponseTemplate.defaultTemplate
    }
    
    private func fillTemplate(
        _ template: ResponseTemplate,
        intent: UserIntent,
        reasoning: HealthReasoning,
        context: ConversationContext
    ) async -> String {
        var filledContent = template.pattern
        
        // Replace template variables with actual content
        for variable in template.variables {
            let replacement = await generateVariableContent(
                variable: variable,
                intent: intent,
                reasoning: reasoning,
                context: context
            )
            filledContent = filledContent.replacingOccurrences(of: "{\(variable)}", with: replacement)
        }
        
        return filledContent
    }
    
    private func generateVariableContent(
        variable: String,
        intent: UserIntent,
        reasoning: HealthReasoning,
        context: ConversationContext
    ) async -> String {
        switch variable {
        case "health_aspect":
            return intent.healthAspect ?? "overall wellness"
        case "data_point":
            return reasoning.primaryDataPoint ?? "your health metrics"
        case "recommendation":
            return reasoning.recommendations.first?.description ?? "consulting with a healthcare provider"
        case "insight":
            return reasoning.insights.first?.description ?? "every small step matters"
        case "suggestion":
            return reasoning.recommendations.first?.actionItems.first ?? "starting with small, manageable changes"
        case "motivation":
            return generateMotivationalPhrase(for: intent.category)
        case "health_goal":
            return context.userProfile?.healthGoals.first ?? "your health journey"
        default:
            return "your wellness"
        }
    }
    
    private func generateMotivationalPhrase(for category: ConversationTopic) -> String {
        switch category {
        case .exercise:
            return "Your body is designed to move, and every step counts!"
        case .sleep:
            return "Quality sleep is one of the best investments in your health."
        case .nutrition:
            return "Food is medicine, and you have the power to nourish your body well."
        case .stress:
            return "Managing stress is a skill that improves with practice."
        case .general:
            return "Your health journey is unique and valuable."
        }
    }
    
    private func calculateResponseConfidence(
        _ intent: UserIntent,
        reasoning: HealthReasoning,
        context: ConversationContext
    ) -> Double {
        var confidence = 0.7 // Base confidence
        
        // Increase confidence based on reasoning quality
        if reasoning.confidence > 0.8 {
            confidence += 0.1
        }
        
        // Increase confidence if we have user profile data
        if context.userProfile != nil {
            confidence += 0.1
        }
        
        // Increase confidence if we have recent health data
        if !context.recentHealthData.isEmpty {
            confidence += 0.1
        }
        
        return min(1.0, confidence)
    }
    
    private func filterRepeatedQuestions(_ questions: [String], context: ConversationContext) async -> [String] {
        let previousQuestions = context.conversationHistory
            .filter { $0.sender == .coach }
            .map { $0.content.lowercased() }
        
        return questions.filter { question in
            !previousQuestions.contains { previousQuestion in
                previousQuestion.contains(question.lowercased())
            }
        }
    }
}

// MARK: - Personality Engine

public actor PersonalityEngine {
    private var personalityProfiles: [CoachPersonality: PersonalityProfile] = [:]
    
    public func loadPersonalities() async {
        personalityProfiles = [
            .supportive: PersonalityProfile(
                responseModifiers: ["encouraging", "understanding", "positive"],
                communicationStyle: .warm,
                vocabularyPreference: .simple,
                motivationApproach: .gentle
            ),
            .motivational: PersonalityProfile(
                responseModifiers: ["energetic", "challenging", "goal-oriented"],
                communicationStyle: .dynamic,
                vocabularyPreference: .action,
                motivationApproach: .intense
            ),
            .analytical: PersonalityProfile(
                responseModifiers: ["data-driven", "precise", "logical"],
                communicationStyle: .professional,
                vocabularyPreference: .technical,
                motivationApproach: .factual
            ),
            .gentle: PersonalityProfile(
                responseModifiers: ["calm", "patient", "soft"],
                communicationStyle: .nurturing,
                vocabularyPreference: .simple,
                motivationApproach: .gradual
            ),
            .scientific: PersonalityProfile(
                responseModifiers: ["evidence-based", "educational", "thorough"],
                communicationStyle: .informative,
                vocabularyPreference: .scientific,
                motivationApproach: .educational
            ),
            .friend: PersonalityProfile(
                responseModifiers: ["casual", "relatable", "conversational"],
                communicationStyle: .friendly,
                vocabularyPreference: .casual,
                motivationApproach: .peer
            )
        ]
    }
    
    public func applyPersonality(
        _ baseResponse: BaseResponse,
        personality: CoachPersonality,
        context: ConversationContext
    ) async -> PersonalizedResponse {
        guard let profile = personalityProfiles[personality] else {
            return PersonalizedResponse(
                content: baseResponse.content,
                confidence: baseResponse.confidence
            )
        }
        
        // Apply personality-specific modifications
        let personalizedContent = await adjustContentForPersonality(
            baseResponse.content,
            profile: profile,
            context: context
        )
        
        return PersonalizedResponse(
            content: personalizedContent,
            confidence: baseResponse.confidence
        )
    }
    
    public func generateSuggestions(
        reasoning: HealthReasoning,
        personality: CoachPersonality
    ) async -> [HealthSuggestion] {
        guard let profile = personalityProfiles[personality] else { return [] }
        
        var suggestions: [HealthSuggestion] = []
        
        // Generate personality-specific suggestions
        switch personality {
        case .motivational:
            suggestions.append(HealthSuggestion(
                title: "Challenge Yourself",
                description: "Push your limits and see what you're capable of!",
                category: .lifestyle,
                evidenceLevel: .medium
            ))
            
        case .analytical:
            suggestions.append(HealthSuggestion(
                title: "Track Your Data",
                description: "Monitor your metrics to identify patterns and optimize performance.",
                category: .lifestyle,
                evidenceLevel: .high
            ))
            
        case .gentle:
            suggestions.append(HealthSuggestion(
                title: "Take It Slow",
                description: "Small, consistent steps lead to lasting changes.",
                category: .lifestyle,
                evidenceLevel: .medium
            ))
            
        default:
            break
        }
        
        return suggestions
    }
    
    public func generateActionItems(
        reasoning: HealthReasoning,
        personality: CoachPersonality
    ) async -> [ActionItem] {
        guard let profile = personalityProfiles[personality] else { return [] }
        
        var actionItems: [ActionItem] = []
        
        // Generate personality-specific action items
        switch personality {
        case .motivational:
            actionItems.append(ActionItem(
                title: "Set a Challenge Goal",
                description: "Choose one ambitious but achievable goal for this week",
                priority: .medium,
                estimatedTimeMinutes: 15,
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())
            ))
            
        case .analytical:
            actionItems.append(ActionItem(
                title: "Analyze Your Trends",
                description: "Review your health data from the past week for patterns",
                priority: .medium,
                estimatedTimeMinutes: 20,
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
            ))
            
        default:
            break
        }
        
        return actionItems
    }
    
    public func adjustSuggestionForPersonality(
        _ suggestion: String,
        personality: CoachPersonality
    ) async -> String {
        switch personality {
        case .motivational:
            return addMotivationalLanguage(suggestion)
        case .gentle:
            return addGentleLanguage(suggestion)
        case .scientific:
            return addScientificLanguage(suggestion)
        case .analytical:
            return addAnalyticalLanguage(suggestion)
        case .friend:
            return addFriendlyLanguage(suggestion)
        case .supportive:
            return addSupportiveLanguage(suggestion)
        }
    }
    
    private func adjustContentForPersonality(
        _ content: String,
        profile: PersonalityProfile,
        context: ConversationContext
    ) async -> String {
        var adjustedContent = content
        
        // Apply communication style adjustments
        switch profile.communicationStyle {
        case .warm:
            adjustedContent = addWarmth(adjustedContent)
        case .dynamic:
            adjustedContent = addEnergy(adjustedContent)
        case .professional:
            adjustedContent = addProfessionalism(adjustedContent)
        case .nurturing:
            adjustedContent = addNurturing(adjustedContent)
        case .informative:
            adjustedContent = addInformation(adjustedContent)
        case .friendly:
            adjustedContent = addFriendliness(adjustedContent)
        }
        
        return adjustedContent
    }
    
    // MARK: - Personality Adjustment Methods
    
    private func addMotivationalLanguage(_ text: String) -> String {
        let motivationalPhrases = ["You've got this!", "Amazing progress!", "Push forward!", "You're stronger than you think!"]
        return text + " " + motivationalPhrases.randomElement()!
    }
    
    private func addGentleLanguage(_ text: String) -> String {
        return text.replacingOccurrences(of: "should", with: "might consider")
            .replacingOccurrences(of: "must", with: "could")
    }
    
    private func addScientificLanguage(_ text: String) -> String {
        return "Research shows that " + text + " This is supported by multiple clinical studies."
    }
    
    private func addAnalyticalLanguage(_ text: String) -> String {
        return "Based on the data analysis, " + text + " The evidence suggests this approach is optimal."
    }
    
    private func addFriendlyLanguage(_ text: String) -> String {
        let friendlyPhrases = ["Hey,", "So,", "You know what?", "Here's the thing -"]
        return friendlyPhrases.randomElement()! + " " + text.lowercased()
    }
    
    private func addSupportiveLanguage(_ text: String) -> String {
        return "I believe in you! " + text + " Remember, I'm here to support you every step of the way."
    }
    
    private func addWarmth(_ text: String) -> String {
        return text + " I'm here for you. 😊"
    }
    
    private func addEnergy(_ text: String) -> String {
        return text + " Let's make it happen! 💪"
    }
    
    private func addProfessionalism(_ text: String) -> String {
        return "Based on current health guidelines, " + text
    }
    
    private func addNurturing(_ text: String) -> String {
        return "Take your time with this: " + text + " There's no rush."
    }
    
    private func addInformation(_ text: String) -> String {
        return text + " Would you like me to explain the science behind this recommendation?"
    }
    
    private func addFriendliness(_ text: String) -> String {
        return text + " What do you think?"
    }
}

// MARK: - Supporting Types

public typealias CoachPersonality = AIHealthCoach.CoachPersonality
public typealias ConversationTopic = AIHealthCoach.ConversationTopic

public struct ConversationalResponse: Sendable {
    public let content: String
    public let confidence: Double
    public let suggestions: [HealthSuggestion]
    public let actionItems: [ActionItem]
    public let followUpQuestions: [String]
    public let healthInsights: [HealthInsight]
    public let goalUpdates: [GoalUpdate]?
    
    public static func error(_ message: String) -> ConversationalResponse {
        return ConversationalResponse(
            content: "I apologize, but I'm having trouble processing that right now. \(message)",
            confidence: 0.0,
            suggestions: [],
            actionItems: [],
            followUpQuestions: [],
            healthInsights: [],
            goalUpdates: nil
        )
    }
}

public struct UserIntent: Sendable {
    public let category: ConversationTopic
    public let specificity: Double // 0-1, how specific the intent is
    public let entities: [String] // Extracted entities (symptoms, activities, etc.)
    public let sentiment: Sentiment
    public let healthAspect: String? // Specific health aspect mentioned
    
    public enum Sentiment: String, Sendable {
        case positive = "positive"
        case neutral = "neutral"
        case negative = "negative"
        case concerned = "concerned"
    }
}

public struct ConversationContext: Sendable {
    public let userProfile: UserHealthProfile?
    public let recentHealthData: [HealthMetric]
    public let activeGoals: [HealthGoal]
    public let timeOfDay: Date
    public let conversationHistory: [ConversationMessage]
    
    public init(
        userProfile: UserHealthProfile?,
        recentHealthData: [HealthMetric],
        activeGoals: [HealthGoal],
        timeOfDay: Date,
        conversationHistory: [ConversationMessage]
    ) {
        self.userProfile = userProfile
        self.recentHealthData = recentHealthData
        self.activeGoals = activeGoals
        self.timeOfDay = timeOfDay
        self.conversationHistory = conversationHistory
    }
}

public struct BaseResponse: Sendable {
    public let content: String
    public let confidence: Double
    public let template: ResponseTemplate
}

public struct PersonalizedResponse: Sendable {
    public let content: String
    public let confidence: Double
}

public struct ResponseTemplate: Sendable {
    public let id: String
    public let pattern: String
    public let variables: [String]
    
    public static let defaultTemplate = ResponseTemplate(
        id: "default",
        pattern: "I understand you're asking about {topic}. {general_guidance}",
        variables: ["topic", "general_guidance"]
    )
}

public struct PersonalityProfile: Sendable {
    public let responseModifiers: [String]
    public let communicationStyle: CommunicationStyle
    public let vocabularyPreference: VocabularyPreference
    public let motivationApproach: MotivationApproach
    
    public enum CommunicationStyle: String, Sendable {
        case warm = "warm"
        case dynamic = "dynamic"
        case professional = "professional"
        case nurturing = "nurturing"
        case informative = "informative"
        case friendly = "friendly"
    }
    
    public enum VocabularyPreference: String, Sendable {
        case simple = "simple"
        case technical = "technical"
        case action = "action"
        case scientific = "scientific"
        case casual = "casual"
    }
    
    public enum MotivationApproach: String, Sendable {
        case gentle = "gentle"
        case intense = "intense"
        case factual = "factual"
        case gradual = "gradual"
        case educational = "educational"
        case peer = "peer"
    }
}

public struct HealthFact: Sendable {
    public let topic: String
    public let fact: String
    public let evidence: String
}

// MARK: - Helper Classes

public actor Tokenizer {
    public func tokenize(_ text: String) async -> [String] {
        // Simple tokenization - in production this would use a proper NLP tokenizer
        return text.lowercased()
            .components(separatedBy: .whitespacesAndPunctuation)
            .filter { !$0.isEmpty }
    }
}

public actor IntentClassifier {
    private var keywords: [ConversationTopic: [String]] = [:]
    
    public func initialize() async {
        keywords = [
            .sleep: ["sleep", "bed", "tired", "insomnia", "rest", "dream", "wake", "nap"],
            .exercise: ["exercise", "workout", "run", "gym", "fitness", "strength", "cardio", "activity"],
            .nutrition: ["eat", "food", "diet", "nutrition", "meal", "calories", "weight", "hungry"],
            .stress: ["stress", "anxiety", "worried", "pressure", "overwhelmed", "calm", "relax"],
            .general: ["health", "wellness", "feeling", "body", "overall", "general"]
        ]
    }
    
    public func classify(tokens: [String], context: ConversationContext) async -> UserIntent {
        var categoryScores: [ConversationTopic: Double] = [:]
        
        // Calculate scores for each category based on keyword matches
        for (category, categoryKeywords) in keywords {
            let matches = tokens.filter { token in
                categoryKeywords.contains { keyword in
                    token.contains(keyword) || keyword.contains(token)
                }
            }
            categoryScores[category] = Double(matches.count) / Double(categoryKeywords.count)
        }
        
        // Find the highest scoring category
        let topCategory = categoryScores.max(by: { $0.value < $1.value })?.key ?? .general
        let specificity = categoryScores[topCategory] ?? 0.0
        
        // Extract entities (simplified)
        let entities = extractEntities(from: tokens)
        
        // Determine sentiment (simplified)
        let sentiment = determineSentiment(from: tokens)
        
        // Extract health aspect
        let healthAspect = extractHealthAspect(from: tokens, category: topCategory)
        
        return UserIntent(
            category: topCategory,
            specificity: specificity,
            entities: entities,
            sentiment: sentiment,
            healthAspect: healthAspect
        )
    }
    
    private func extractEntities(from tokens: [String]) -> [String] {
        // Simple entity extraction - in production this would use NER
        let healthEntities = ["headache", "fatigue", "pain", "nausea", "dizzy", "fever"]
        return tokens.filter { healthEntities.contains($0) }
    }
    
    private func determineSentiment(from tokens: [String]) -> UserIntent.Sentiment {
        let positiveWords = ["good", "great", "better", "happy", "excellent", "amazing"]
        let negativeWords = ["bad", "worse", "terrible", "awful", "horrible", "pain"]
        let concernedWords = ["worried", "concerned", "scared", "anxious", "confused"]
        
        let positiveCount = tokens.filter { positiveWords.contains($0) }.count
        let negativeCount = tokens.filter { negativeWords.contains($0) }.count
        let concernedCount = tokens.filter { concernedWords.contains($0) }.count
        
        if concernedCount > 0 {
            return .concerned
        } else if positiveCount > negativeCount {
            return .positive
        } else if negativeCount > positiveCount {
            return .negative
        } else {
            return .neutral
        }
    }
    
    private func extractHealthAspect(from tokens: [String], category: ConversationTopic) -> String? {
        switch category {
        case .sleep:
            if tokens.contains("quality") { return "sleep quality" }
            if tokens.contains("duration") { return "sleep duration" }
            if tokens.contains("insomnia") { return "insomnia" }
        case .exercise:
            if tokens.contains("strength") { return "strength training" }
            if tokens.contains("cardio") { return "cardiovascular fitness" }
            if tokens.contains("endurance") { return "endurance" }
        case .nutrition:
            if tokens.contains("weight") { return "weight management" }
            if tokens.contains("energy") { return "energy levels" }
        default:
            break
        }
        return nil
    }
}

public actor KeyPointExtractor {
    private var importantPhrases: [String] = []
    
    public func initialize() async {
        importantPhrases = [
            "sleep quality", "energy level", "stress management", "exercise routine",
            "nutrition plan", "weight loss", "muscle gain", "mental health",
            "heart rate", "blood pressure", "meditation", "hydration"
        ]
    }
    
    public func extract(from text: String) async -> [String] {
        let lowercasedText = text.lowercased()
        var keyPoints: [String] = []
        
        // Extract important phrases
        for phrase in importantPhrases {
            if lowercasedText.contains(phrase) {
                keyPoints.append(phrase)
            }
        }
        
        // Extract sentences with health-related keywords
        let sentences = text.components(separatedBy: ". ")
        for sentence in sentences {
            if containsHealthKeywords(sentence) && sentence.count > 20 {
                keyPoints.append(sentence)
            }
        }
        
        return Array(Set(keyPoints)) // Remove duplicates
    }
    
    private func containsHealthKeywords(_ text: String) -> Bool {
        let healthKeywords = ["health", "feel", "sleep", "exercise", "eat", "stress", "energy", "pain"]
        let lowercasedText = text.lowercased()
        
        return healthKeywords.contains { keyword in
            lowercasedText.contains(keyword)
        }
    }
}

// MARK: - Context and State Management

public actor ContextProcessor {
    public func initialize() async {
        // Initialize context processing capabilities
    }
}

public actor ConversationContextManager {
    private var currentContext: ConversationContext?
    private var conversationHistories: [UUID: [ConversationMessage]] = [:]
    
    public func buildContext(
        conversation: HealthConversation,
        userProfile: UserHealthProfile?,
        recentHealthData: [HealthMetric]
    ) async -> ConversationContext {
        let context = ConversationContext(
            userProfile: userProfile,
            recentHealthData: recentHealthData,
            activeGoals: [], // Would get from goal tracker
            timeOfDay: Date(),
            conversationHistory: conversation.messages
        )
        
        currentContext = context
        return context
    }
    
    public func updateContext(with message: ConversationMessage) async {
        // Update context with new message
    }
    
    public func updateUserProfile(_ profile: UserHealthProfile) async {
        // Update user profile in context
    }
    
    public func storeConversation(_ conversation: HealthConversation, summary: ConversationSummary) async {
        conversationHistories[conversation.id] = conversation.messages
    }
}

public actor PersonalityAdjustmentEngine {
    public func adjustConversation(_ conversation: HealthConversation, to personality: CoachPersonality) async {
        // Adjust ongoing conversation for new personality
    }
}

public actor HealthGoalTracker {
    private var goals: [UUID: HealthGoal] = [:]
    
    public func addGoal(_ goal: HealthGoal) async {
        goals[goal.id] = goal
    }
    
    public func updateProgress(_ goalId: UUID, progress: Double) async {
        goals[goalId]?.currentProgress = progress
    }
    
    public func updateGoal(_ goal: HealthGoal) async {
        goals[goal.id] = goal
    }
}