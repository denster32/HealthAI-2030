import Foundation
import AVFoundation
import NaturalLanguage

@available(iOS 18.0, *)
class SiriResponseManager: ObservableObject {
    static let shared = SiriResponseManager()
    
    private let nlProcessor = NLLanguageRecognizer()
    private let healthFormatter = SiriHealthFormatter()
    private let errorHandler = SiriErrorHandler()
    
    @Published var isProcessing = false
    @Published var lastResponse: SiriHealthResponse?
    
    private init() {}
    
    // MARK: - Main Response Generation
    
    func generateResponse(for query: String, with data: [String: Any]) async -> SiriHealthResponse {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let processedQuery = await processQuery(query)
            let contextualResponse = await generateContextualResponse(processedQuery, data: data)
            let formattedResponse = await formatResponse(contextualResponse)
            
            let response = SiriHealthResponse(
                spokenText: formattedResponse.spokenText,
                displayText: formattedResponse.displayText,
                confidence: formattedResponse.confidence,
                insights: formattedResponse.insights,
                followUpSuggestions: formattedResponse.followUpSuggestions,
                timestamp: Date()
            )
            
            DispatchQueue.main.async {
                self.lastResponse = response
            }
            
            return response
            
        } catch {
            return await errorHandler.generateErrorResponse(for: error, query: query)
        }
    }
    
    // MARK: - Query Processing
    
    private func processQuery(_ query: String) async -> ProcessedHealthQuery {
        let intent = extractIntent(from: query)
        let entities = extractEntities(from: query)
        let context = determineContext(from: query)
        let urgency = assessUrgency(from: query)
        
        return ProcessedHealthQuery(
            originalQuery: query,
            intent: intent,
            entities: entities,
            context: context,
            urgency: urgency,
            confidence: calculateConfidence(intent: intent, entities: entities)
        )
    }
    
    private func extractIntent(from query: String) -> HealthIntent {
        let lowercaseQuery = query.lowercased()
        
        // Data retrieval intents
        if lowercaseQuery.contains("what") || lowercaseQuery.contains("how") || lowercaseQuery.contains("show") {
            if lowercaseQuery.contains("heart rate") { return .getHeartRate }
            if lowercaseQuery.contains("sleep") { return .getSleep }
            if lowercaseQuery.contains("steps") { return .getSteps }
            if lowercaseQuery.contains("water") { return .getWaterIntake }
            if lowercaseQuery.contains("health score") { return .getHealthScore }
            if lowercaseQuery.contains("workout") { return .getWorkouts }
            return .getGeneralHealth
        }
        
        // Action intents
        if lowercaseQuery.contains("log") || lowercaseQuery.contains("record") {
            if lowercaseQuery.contains("workout") { return .logWorkout }
            if lowercaseQuery.contains("water") { return .recordWater }
            if lowercaseQuery.contains("medication") { return .logMedication }
            return .logGeneralData
        }
        
        if lowercaseQuery.contains("start") {
            if lowercaseQuery.contains("meditation") { return .startMeditation }
            if lowercaseQuery.contains("workout") { return .startWorkout }
            return .startActivity
        }
        
        if lowercaseQuery.contains("set") && lowercaseQuery.contains("goal") {
            return .setGoal
        }
        
        // Analysis intents
        if lowercaseQuery.contains("analyze") || lowercaseQuery.contains("trend") {
            return .analyzeData
        }
        
        // Comparison intents
        if lowercaseQuery.contains("compare") || lowercaseQuery.contains("vs") {
            return .compareData
        }
        
        return .unknown
    }
    
    private func extractEntities(from query: String) -> [HealthEntity] {
        var entities: [HealthEntity] = []
        let lowercaseQuery = query.lowercased()
        
        // Time entities
        if lowercaseQuery.contains("today") { entities.append(.timeFrame("today")) }
        if lowercaseQuery.contains("yesterday") { entities.append(.timeFrame("yesterday")) }
        if lowercaseQuery.contains("this week") { entities.append(.timeFrame("this week")) }
        if lowercaseQuery.contains("last week") { entities.append(.timeFrame("last week")) }
        if lowercaseQuery.contains("this month") { entities.append(.timeFrame("this month")) }
        
        // Health data entities
        if lowercaseQuery.contains("heart rate") { entities.append(.dataType("heart_rate")) }
        if lowercaseQuery.contains("blood pressure") { entities.append(.dataType("blood_pressure")) }
        if lowercaseQuery.contains("steps") { entities.append(.dataType("steps")) }
        if lowercaseQuery.contains("sleep") { entities.append(.dataType("sleep")) }
        if lowercaseQuery.contains("water") { entities.append(.dataType("water")) }
        if lowercaseQuery.contains("weight") { entities.append(.dataType("weight")) }
        
        // Numeric entities
        let numberRegex = try? NSRegularExpression(pattern: "\\b\\d+\\b", options: [])
        if let regex = numberRegex {
            let range = NSRange(location: 0, length: query.utf16.count)
            let matches = regex.matches(in: query, options: [], range: range)
            for match in matches {
                if let range = Range(match.range, in: query) {
                    let number = String(query[range])
                    entities.append(.number(number))
                }
            }
        }
        
        return entities
    }
    
    private func determineContext(from query: String) -> HealthContext {
        let timeOfDay = Calendar.current.component(.hour, from: Date())
        let urgencyLevel = assessUrgency(from: query)
        
        return HealthContext(
            timeOfDay: timeOfDay,
            urgencyLevel: urgencyLevel,
            conversationHistory: getRecentConversationHistory(),
            userPreferences: getUserPreferences()
        )
    }
    
    private func assessUrgency(from query: String) -> UrgencyLevel {
        let lowercaseQuery = query.lowercased()
        
        if lowercaseQuery.contains("emergency") || lowercaseQuery.contains("urgent") || lowercaseQuery.contains("help") {
            return .high
        }
        
        if lowercaseQuery.contains("pain") || lowercaseQuery.contains("symptom") || lowercaseQuery.contains("concerned") {
            return .medium
        }
        
        return .low
    }
    
    private func calculateConfidence(intent: HealthIntent, entities: [HealthEntity]) -> Double {
        var confidence = 0.5
        
        // Boost confidence for clear intents
        if intent != .unknown {
            confidence += 0.3
        }
        
        // Boost confidence for relevant entities
        if !entities.isEmpty {
            confidence += 0.2
        }
        
        return min(confidence, 1.0)
    }
    
    // MARK: - Contextual Response Generation
    
    private func generateContextualResponse(_ query: ProcessedHealthQuery, data: [String: Any]) async -> ContextualHealthResponse {
        let baseResponse = await generateBaseResponse(for: query, with: data)
        let insights = await generateInsights(for: query, with: data)
        let personalizedElements = await addPersonalization(to: baseResponse, query: query)
        
        return ContextualHealthResponse(
            baseResponse: personalizedElements,
            insights: insights,
            contextualElements: generateContextualElements(query: query),
            confidence: query.confidence
        )
    }
    
    private func generateBaseResponse(for query: ProcessedHealthQuery, with data: [String: Any]) async -> String {
        switch query.intent {
        case .getHeartRate:
            return await generateHeartRateResponse(data: data, query: query)
        case .getSleep:
            return await generateSleepResponse(data: data, query: query)
        case .getSteps:
            return await generateStepsResponse(data: data, query: query)
        case .getWaterIntake:
            return await generateWaterResponse(data: data, query: query)
        case .getHealthScore:
            return await generateHealthScoreResponse(data: data, query: query)
        case .getWorkouts:
            return await generateWorkoutResponse(data: data, query: query)
        case .logWorkout:
            return "I'll help you log your workout. What type of exercise did you do?"
        case .recordWater:
            return "Great! I'll record your water intake. How much water did you drink?"
        case .startMeditation:
            return "Perfect! I'll start a meditation session for you. Find a comfortable position and let's begin."
        case .setGoal:
            return "I'll help you set a health goal. What would you like to focus on improving?"
        case .analyzeData:
            return await generateAnalysisResponse(data: data, query: query)
        case .compareData:
            return await generateComparisonResponse(data: data, query: query)
        default:
            return "I'm here to help with your health questions. What would you like to know?"
        }
    }
    
    private func generateHeartRateResponse(data: [String: Any], query: ProcessedHealthQuery) async -> String {
        guard let heartRate = data["heartRate"] as? Double else {
            return "I couldn't find recent heart rate data. Make sure your Apple Watch is connected and you have the necessary permissions enabled."
        }
        
        let hrInt = Int(heartRate)
        var response = "Your current heart rate is \(hrInt) beats per minute."
        
        // Add context based on heart rate value
        if heartRate < 60 {
            response += " That's on the lower side, which could be normal if you're very fit."
        } else if heartRate > 100 {
            response += " That's a bit elevated. Are you currently active or feeling stressed?"
        } else {
            response += " That's in a healthy range."
        }
        
        return response
    }
    
    private func generateSleepResponse(data: [String: Any], query: ProcessedHealthQuery) async -> String {
        guard let duration = data["duration"] as? TimeInterval,
              let efficiency = data["efficiency"] as? Double else {
            return "I couldn't find sleep data for the requested time period. Make sure sleep tracking is enabled on your device."
        }
        
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        let efficiencyPercent = Int(efficiency * 100)
        
        var response = "You slept for \(hours) hours and \(minutes) minutes with \(efficiencyPercent)% sleep efficiency."
        
        // Add insights based on sleep quality
        if efficiency > 0.85 {
            response += " That's excellent sleep quality!"
        } else if efficiency > 0.75 {
            response += " Your sleep quality is pretty good."
        } else {
            response += " Your sleep efficiency could be improved. Consider reviewing your bedtime routine."
        }
        
        return response
    }
    
    private func generateStepsResponse(data: [String: Any], query: ProcessedHealthQuery) async -> String {
        guard let steps = data["steps"] as? Double else {
            return "I couldn't find step data for the requested time period. Make sure your phone or watch is tracking your activity."
        }
        
        let stepsInt = Int(steps)
        var response = "You've taken \(stepsInt) steps"
        
        // Add time context
        if let timeFrame = query.entities.first(where: { entity in
            if case .timeFrame = entity { return true }
            return false
        }) {
            response += " \(timeFrame.value)."
        } else {
            response += " today."
        }
        
        // Add achievement context
        if steps >= 10000 {
            response += " Fantastic! You've reached the recommended daily goal."
        } else if steps >= 7500 {
            response += " Great job! You're getting close to the daily goal of 10,000 steps."
        } else {
            let remaining = 10000 - stepsInt
            response += " You need \(remaining) more steps to reach the daily goal."
        }
        
        return response
    }
    
    private func generateWaterResponse(data: [String: Any], query: ProcessedHealthQuery) async -> String {
        guard let waterIntake = data["waterIntake"] as? Double else {
            return "I couldn't find water intake data. Make sure you're logging your water consumption."
        }
        
        let goal = data["goal"] as? Double ?? 64.0
        let remaining = max(0, goal - waterIntake)
        
        let intakeInt = Int(waterIntake)
        let goalInt = Int(goal)
        
        var response = "You've had \(intakeInt) ounces of water today out of your \(goalInt) ounce goal."
        
        if remaining > 0 {
            response += " You need \(Int(remaining)) more ounces to reach your goal."
        } else {
            response += " Excellent! You've met your daily hydration goal."
        }
        
        return response
    }
    
    private func generateHealthScoreResponse(data: [String: Any], query: ProcessedHealthQuery) async -> String {
        guard let score = data["healthScore"] as? Double else {
            return "I couldn't calculate your health score right now. Make sure you have recent health data available."
        }
        
        let scoreInt = Int(score)
        var response = "Your current health score is \(scoreInt) out of 100."
        
        // Add interpretation
        if score >= 80 {
            response += " That's excellent! You're maintaining great health habits."
        } else if score >= 60 {
            response += " That's a good score with room for improvement."
        } else {
            response += " There's significant room for improvement. Consider focusing on your health goals."
        }
        
        return response
    }
    
    private func generateWorkoutResponse(data: [String: Any], query: ProcessedHealthQuery) async -> String {
        guard let workouts = data["workouts"] as? [WorkoutData], !workouts.isEmpty else {
            return "You haven't logged any workouts recently. Would you like to start a new workout or log a past exercise session?"
        }
        
        let lastWorkout = workouts.first!
        return "Your last workout was \(lastWorkout.type) for \(lastWorkout.duration) minutes. Keep up the great work!"
    }
    
    private func generateAnalysisResponse(data: [String: Any], query: ProcessedHealthQuery) async -> String {
        // Generate trend analysis response
        return "Based on your recent health data, I can see positive trends in your activity levels. Your sleep has been consistent, and your heart rate indicates good cardiovascular health."
    }
    
    private func generateComparisonResponse(data: [String: Any], query: ProcessedHealthQuery) async -> String {
        // Generate comparison response
        return "Comparing this week to last week, your activity has increased by 15%, and your sleep efficiency has improved by 8%. You're making great progress!"
    }
    
    private func generateInsights(for query: ProcessedHealthQuery, with data: [String: Any]) async -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Generate context-specific insights
        switch query.intent {
        case .getHeartRate:
            insights.append(HealthInsight(
                type: .cardiovascular,
                message: "Your heart rate variability suggests good cardiovascular fitness.",
                confidence: 0.8,
                actionable: true
            ))
        case .getSleep:
            insights.append(HealthInsight(
                type: .sleep,
                message: "Consider maintaining a consistent bedtime to improve sleep quality.",
                confidence: 0.9,
                actionable: true
            ))
        case .getSteps:
            insights.append(HealthInsight(
                type: .activity,
                message: "Try taking short walks throughout the day to boost your step count.",
                confidence: 0.85,
                actionable: true
            ))
        default:
            break
        }
        
        return insights
    }
    
    private func addPersonalization(to response: String, query: ProcessedHealthQuery) async -> String {
        let preferences = getUserPreferences()
        let timeOfDay = Calendar.current.component(.hour, from: Date())
        
        var personalizedResponse = response
        
        // Add time-based personalization
        if timeOfDay < 12 {
            personalizedResponse = "Good morning! " + personalizedResponse
        } else if timeOfDay < 17 {
            personalizedResponse = "Good afternoon! " + personalizedResponse
        } else {
            personalizedResponse = "Good evening! " + personalizedResponse
        }
        
        // Add encouragement based on preferences
        if preferences.motivationLevel == .high {
            personalizedResponse += " Keep up the fantastic work!"
        }
        
        return personalizedResponse
    }
    
    private func generateContextualElements(query: ProcessedHealthQuery) -> [ContextualElement] {
        var elements: [ContextualElement] = []
        
        // Add time context
        elements.append(ContextualElement(
            type: .timeContext,
            content: "Current time: \(Date().formatted(date: .omitted, time: .shortened))"
        ))
        
        // Add urgency context
        if query.urgency == .high {
            elements.append(ContextualElement(
                type: .urgencyIndicator,
                content: "This seems urgent. Consider consulting a healthcare provider if needed."
            ))
        }
        
        return elements
    }
    
    // MARK: - Response Formatting
    
    private func formatResponse(_ contextualResponse: ContextualHealthResponse) async -> FormattedHealthResponse {
        let spokenText = await healthFormatter.formatForSpeech(contextualResponse.baseResponse)
        let displayText = await healthFormatter.formatForDisplay(contextualResponse.baseResponse)
        let followUpSuggestions = await healthFormatter.generateFollowUpSuggestions(for: contextualResponse)
        
        return FormattedHealthResponse(
            spokenText: spokenText,
            displayText: displayText,
            confidence: contextualResponse.confidence,
            insights: contextualResponse.insights,
            followUpSuggestions: followUpSuggestions
        )
    }
    
    // MARK: - Helper Methods
    
    private func getRecentConversationHistory() -> [String] {
        // Mock implementation - would retrieve actual conversation history
        return []
    }
    
    private func getUserPreferences() -> UserHealthPreferences {
        // Mock implementation - would retrieve actual user preferences
        return UserHealthPreferences(
            motivationLevel: .medium,
            responseStyle: .conversational,
            privacyLevel: .high
        )
    }
}

// MARK: - Supporting Data Structures

struct ProcessedHealthQuery {
    let originalQuery: String
    let intent: HealthIntent
    let entities: [HealthEntity]
    let context: HealthContext
    let urgency: UrgencyLevel
    let confidence: Double
}

enum HealthIntent {
    case getHeartRate
    case getSleep
    case getSteps
    case getWaterIntake
    case getHealthScore
    case getWorkouts
    case getGeneralHealth
    case logWorkout
    case recordWater
    case logMedication
    case logGeneralData
    case startMeditation
    case startWorkout
    case startActivity
    case setGoal
    case analyzeData
    case compareData
    case unknown
}

enum HealthEntity {
    case timeFrame(String)
    case dataType(String)
    case number(String)
    case duration(String)
    
    var value: String {
        switch self {
        case .timeFrame(let value),
             .dataType(let value),
             .number(let value),
             .duration(let value):
            return value
        }
    }
}

struct HealthContext {
    let timeOfDay: Int
    let urgencyLevel: UrgencyLevel
    let conversationHistory: [String]
    let userPreferences: UserHealthPreferences
}

enum UrgencyLevel {
    case low
    case medium
    case high
}

struct UserHealthPreferences {
    let motivationLevel: MotivationLevel
    let responseStyle: ResponseStyle
    let privacyLevel: PrivacyLevel
}

enum MotivationLevel {
    case low
    case medium
    case high
}

enum ResponseStyle {
    case formal
    case conversational
    case brief
}

enum PrivacyLevel {
    case low
    case medium
    case high
}

struct ContextualHealthResponse {
    let baseResponse: String
    let insights: [HealthInsight]
    let contextualElements: [ContextualElement]
    let confidence: Double
}

struct HealthInsight {
    let type: InsightType
    let message: String
    let confidence: Double
    let actionable: Bool
}

enum InsightType {
    case cardiovascular
    case sleep
    case activity
    case nutrition
    case mental
    case general
}

struct ContextualElement {
    let type: ElementType
    let content: String
}

enum ElementType {
    case timeContext
    case urgencyIndicator
    case motivationalElement
    case educational
}

struct FormattedHealthResponse {
    let spokenText: String
    let displayText: String
    let confidence: Double
    let insights: [HealthInsight]
    let followUpSuggestions: [String]
}

struct SiriHealthResponse {
    let spokenText: String
    let displayText: String
    let confidence: Double
    let insights: [HealthInsight]
    let followUpSuggestions: [String]
    let timestamp: Date
}