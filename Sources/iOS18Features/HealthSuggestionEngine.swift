import Foundation
import CoreML
import HealthKit
import CoreLocation
import UserNotifications

@available(iOS 18.0, *)
class HealthSuggestionEngine: ObservableObject {
    static let shared = HealthSuggestionEngine()
    
    @Published var activeSuggestions: [HealthSuggestion] = []
    @Published var suggestionHistory: [HealthSuggestion] = []
    @Published var isProcessing = false
    
    private let suggestionManager = HealthSuggestionManager()
    private let analyticsManager = HealthSuggestionAnalytics()
    private let personalizationEngine = HealthSuggestionPersonalization()
    private let contextEngine = HealthContextEngine()
    
    private var mlModel: HealthSuggestionMLModel?
    private var timer: Timer?
    
    private init() {
        loadMLModel()
        startPeriodicSuggestionGeneration()
    }
    
    // MARK: - Core Suggestion Generation
    
    func generateSuggestions() async {
        guard !isProcessing else { return }
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
        
        do {
            // Gather current context
            let context = await gatherHealthContext()
            
            // Generate AI-powered suggestions
            let aiSuggestions = await generateAISuggestions(context: context)
            
            // Generate contextual suggestions
            let contextualSuggestions = await generateContextualSuggestions(context: context)
            
            // Generate time-based suggestions
            let timeSuggestions = await generateTimeBasedSuggestions(context: context)
            
            // Generate weather-based suggestions
            let weatherSuggestions = await generateWeatherBasedSuggestions(context: context)
            
            // Combine and personalize
            var allSuggestions = aiSuggestions + contextualSuggestions + timeSuggestions + weatherSuggestions
            allSuggestions = await personalizationEngine.personalizeSuggestions(allSuggestions, for: context)
            
            // Filter and rank
            let finalSuggestions = await filterAndRankSuggestions(allSuggestions, context: context)
            
            // Update suggestions
            DispatchQueue.main.async {
                self.activeSuggestions = finalSuggestions
                self.suggestionHistory.append(contentsOf: finalSuggestions)
            }
            
            // Schedule notifications for high-priority suggestions
            await scheduleNotifications(for: finalSuggestions)
            
            // Track analytics
            await analyticsManager.trackSuggestionGeneration(
                suggestions: finalSuggestions,
                context: context
            )
            
        } catch {
            print("❌ Error generating suggestions: \(error)")
        }
    }
    
    // MARK: - AI-Powered Suggestions
    
    private func generateAISuggestions(context: HealthSuggestionContext) async -> [HealthSuggestion] {
        guard let mlModel = mlModel else { return [] }
        
        var suggestions: [HealthSuggestion] = []
        
        // Generate medication reminders
        if await shouldSuggestMedication(context: context) {
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .medicationReminder,
                title: "Time for your medication",
                message: "Don't forget to take your \(context.nextMedication?.name ?? "medication") at \(context.nextMedication?.time ?? "the scheduled time")",
                priority: .high,
                category: .medication,
                actionType: .reminder,
                estimatedImpact: 0.9,
                confidence: 0.95,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(3600) // Expires in 1 hour
            ))
        }
        
        // Generate step goal suggestions
        if let stepProgress = context.healthData.stepProgress, stepProgress > 0.7 && stepProgress < 1.0 {
            let remainingSteps = Int((1.0 - stepProgress) * 10000) // Assuming 10K goal
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .activityReminder,
                title: "You're close to your step goal!",
                message: "Only \(remainingSteps) more steps to reach your daily goal. A 10-minute walk should do it!",
                priority: .medium,
                category: .fitness,
                actionType: .action,
                estimatedImpact: 0.7,
                confidence: 0.85,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(7200) // Expires in 2 hours
            ))
        }
        
        // Generate screen time break suggestions
        if context.deviceUsage.continuousScreenTime > 120 { // 2 hours
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .wellnessReminder,
                title: "Consider a break from screen time",
                message: "You've been using your device for \(Int(context.deviceUsage.continuousScreenTime / 60)) hours. Take a 5-minute break to rest your eyes.",
                priority: .medium,
                category: .wellness,
                actionType: .reminder,
                estimatedImpact: 0.6,
                confidence: 0.8,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(1800) // Expires in 30 minutes
            ))
        }
        
        // Generate weather-based exercise suggestions
        if context.weather.isGoodForExercise && context.healthData.todayActivity < 30 {
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .activitySuggestion,
                title: "Perfect weather for outdoor exercise!",
                message: "It's \(Int(context.weather.temperature))°F with \(context.weather.description). Great time for a walk or run outside.",
                priority: .medium,
                category: .fitness,
                actionType: .suggestion,
                estimatedImpact: 0.8,
                confidence: 0.75,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(10800) // Expires in 3 hours
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Contextual Suggestions
    
    private func generateContextualSuggestions(context: HealthSuggestionContext) async -> [HealthSuggestion] {
        var suggestions: [HealthSuggestion] = []
        
        // Heart rate-based suggestions
        if let heartRate = context.healthData.currentHeartRate {
            if heartRate > 100 && context.currentActivity != .exercise {
                suggestions.append(HealthSuggestion(
                    id: UUID().uuidString,
                    type: .healthAlert,
                    title: "Elevated heart rate detected",
                    message: "Your heart rate is \(Int(heartRate)) BPM. Consider taking deep breaths or sitting down if you feel unwell.",
                    priority: .high,
                    category: .health,
                    actionType: .alert,
                    estimatedImpact: 0.9,
                    confidence: 0.9,
                    timestamp: Date(),
                    expiresAt: Date().addingTimeInterval(900) // Expires in 15 minutes
                ))
            }
        }
        
        // Sleep-based suggestions
        if let sleepQuality = context.healthData.lastNightSleepQuality, sleepQuality < 0.7 {
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .sleepSuggestion,
                title: "Improve your sleep tonight",
                message: "Last night's sleep quality was \(Int(sleepQuality * 100))%. Try avoiding caffeine after 2 PM and setting a consistent bedtime.",
                priority: .medium,
                category: .sleep,
                actionType: .suggestion,
                estimatedImpact: 0.8,
                confidence: 0.85,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(43200) // Expires in 12 hours
            ))
        }
        
        // Hydration suggestions
        if context.healthData.waterIntake < 32 && context.timeOfDay > 12 { // Less than 32oz after noon
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .hydrationReminder,
                title: "Stay hydrated",
                message: "You've only had \(Int(context.healthData.waterIntake)) oz of water today. Aim for at least 64 oz daily.",
                priority: .medium,
                category: .nutrition,
                actionType: .reminder,
                estimatedImpact: 0.6,
                confidence: 0.8,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(3600) // Expires in 1 hour
            ))
        }
        
        // Stress management suggestions
        if let stressLevel = context.healthData.currentStressLevel, stressLevel > 0.7 {
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .stressManagement,
                title: "High stress detected",
                message: "Your stress level seems elevated. Try a 5-minute breathing exercise or brief meditation.",
                priority: .high,
                category: .mentalHealth,
                actionType: .action,
                estimatedImpact: 0.8,
                confidence: 0.85,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(1800) // Expires in 30 minutes
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Time-Based Suggestions
    
    private func generateTimeBasedSuggestions(context: HealthSuggestionContext) async -> [HealthSuggestion] {
        var suggestions: [HealthSuggestion] = []
        let hour = context.timeOfDay
        
        // Morning suggestions (6-10 AM)
        if hour >= 6 && hour < 10 {
            if context.healthData.hadBreakfast == false {
                suggestions.append(HealthSuggestion(
                    id: UUID().uuidString,
                    type: .nutritionSuggestion,
                    title: "Don't skip breakfast!",
                    message: "Start your day with a healthy breakfast to boost your energy and metabolism.",
                    priority: .medium,
                    category: .nutrition,
                    actionType: .suggestion,
                    estimatedImpact: 0.7,
                    confidence: 0.8,
                    timestamp: Date(),
                    expiresAt: Date().addingTimeInterval(7200) // Expires in 2 hours
                ))
            }
            
            if context.healthData.morningStretch == false {
                suggestions.append(HealthSuggestion(
                    id: UUID().uuidString,
                    type: .activitySuggestion,
                    title: "Morning stretch routine",
                    message: "Start your day with a 5-minute stretch to improve flexibility and reduce tension.",
                    priority: .low,
                    category: .fitness,
                    actionType: .suggestion,
                    estimatedImpact: 0.5,
                    confidence: 0.7,
                    timestamp: Date(),
                    expiresAt: Date().addingTimeInterval(10800) // Expires in 3 hours
                ))
            }
        }
        
        // Afternoon suggestions (12-6 PM)
        if hour >= 12 && hour < 18 {
            if context.healthData.todayActivity < 30 { // Less than 30 minutes of activity
                suggestions.append(HealthSuggestion(
                    id: UUID().uuidString,
                    type: .activitySuggestion,
                    title: "Afternoon energy boost",
                    message: "Take a 10-minute walk or do some light exercise to beat the afternoon slump.",
                    priority: .medium,
                    category: .fitness,
                    actionType: .suggestion,
                    estimatedImpact: 0.6,
                    confidence: 0.75,
                    timestamp: Date(),
                    expiresAt: Date().addingTimeInterval(3600) // Expires in 1 hour
                ))
            }
        }
        
        // Evening suggestions (6-10 PM)
        if hour >= 18 && hour < 22 {
            if context.healthData.eveningMeal == false {
                suggestions.append(HealthSuggestion(
                    id: UUID().uuidString,
                    type: .nutritionSuggestion,
                    title: "Healthy dinner time",
                    message: "Plan a balanced dinner with lean protein, vegetables, and whole grains.",
                    priority: .medium,
                    category: .nutrition,
                    actionType: .suggestion,
                    estimatedImpact: 0.7,
                    confidence: 0.8,
                    timestamp: Date(),
                    expiresAt: Date().addingTimeInterval(5400) // Expires in 1.5 hours
                ))
            }
            
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .sleepPreparation,
                title: "Prepare for better sleep",
                message: "Start winding down by dimming lights and avoiding screens 1 hour before bed.",
                priority: .medium,
                category: .sleep,
                actionType: .suggestion,
                estimatedImpact: 0.8,
                confidence: 0.85,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(7200) // Expires in 2 hours
            ))
        }
        
        // Night suggestions (10 PM - 12 AM)
        if hour >= 22 || hour < 1 {
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .sleepReminder,
                title: "Consider going to bed",
                message: "It's getting late. Aim for 7-9 hours of sleep for optimal health and recovery.",
                priority: .high,
                category: .sleep,
                actionType: .reminder,
                estimatedImpact: 0.9,
                confidence: 0.9,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(3600) // Expires in 1 hour
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Weather-Based Suggestions
    
    private func generateWeatherBasedSuggestions(context: HealthSuggestionContext) async -> [HealthSuggestion] {
        var suggestions: [HealthSuggestion] = []
        
        let weather = context.weather
        
        // Hot weather suggestions
        if weather.temperature > 80 {
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .weatherAlert,
                title: "Stay cool and hydrated",
                message: "It's \(Int(weather.temperature))°F outside. Drink extra water and avoid prolonged sun exposure.",
                priority: .medium,
                category: .safety,
                actionType: .alert,
                estimatedImpact: 0.7,
                confidence: 0.9,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(14400) // Expires in 4 hours
            ))
        }
        
        // Cold weather suggestions
        if weather.temperature < 40 {
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .weatherAlert,
                title: "Bundle up for cold weather",
                message: "It's \(Int(weather.temperature))°F outside. Dress warmly and protect exposed skin.",
                priority: .medium,
                category: .safety,
                actionType: .alert,
                estimatedImpact: 0.6,
                confidence: 0.85,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(21600) // Expires in 6 hours
            ))
        }
        
        // Good weather for exercise
        if weather.isGoodForExercise {
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .activitySuggestion,
                title: "Perfect weather for outdoor activity",
                message: "Beautiful \(weather.description) today! Consider taking your workout outside.",
                priority: .low,
                category: .fitness,
                actionType: .suggestion,
                estimatedImpact: 0.6,
                confidence: 0.8,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(10800) // Expires in 3 hours
            ))
        }
        
        // UV protection suggestions
        if weather.uvIndex > 6 {
            suggestions.append(HealthSuggestion(
                id: UUID().uuidString,
                type: .healthReminder,
                title: "High UV index",
                message: "UV index is \(weather.uvIndex). Use sunscreen and wear protective clothing if going outside.",
                priority: .medium,
                category: .safety,
                actionType: .reminder,
                estimatedImpact: 0.8,
                confidence: 0.9,
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(18000) // Expires in 5 hours
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Suggestion Filtering and Ranking
    
    private func filterAndRankSuggestions(_ suggestions: [HealthSuggestion], context: HealthSuggestionContext) async -> [HealthSuggestion] {
        var filteredSuggestions = suggestions
        
        // Remove duplicates
        filteredSuggestions = removeDuplicateSuggestions(filteredSuggestions)
        
        // Filter by user preferences
        filteredSuggestions = await filterByUserPreferences(filteredSuggestions)
        
        // Filter by timing constraints
        filteredSuggestions = filterByTimingConstraints(filteredSuggestions)
        
        // Rank by priority and relevance
        filteredSuggestions = rankSuggestionsByRelevance(filteredSuggestions, context: context)
        
        // Limit to reasonable number
        return Array(filteredSuggestions.prefix(8))
    }
    
    private func removeDuplicateSuggestions(_ suggestions: [HealthSuggestion]) -> [HealthSuggestion] {
        var seen = Set<String>()
        return suggestions.filter { suggestion in
            let key = "\(suggestion.type.rawValue)-\(suggestion.category.rawValue)"
            return seen.insert(key).inserted
        }
    }
    
    private func filterByUserPreferences(_ suggestions: [HealthSuggestion]) async -> [HealthSuggestion] {
        let preferences = await getUserSuggestionPreferences()
        
        return suggestions.filter { suggestion in
            switch suggestion.category {
            case .fitness:
                return preferences.fitnessReminders
            case .nutrition:
                return preferences.nutritionSuggestions
            case .sleep:
                return preferences.sleepReminders
            case .medication:
                return preferences.medicationReminders
            case .mentalHealth:
                return preferences.mentalHealthSupport
            case .safety:
                return preferences.safetyAlerts
            case .wellness:
                return preferences.wellnessReminders
            case .health:
                return preferences.healthAlerts
            }
        }
    }
    
    private func filterByTimingConstraints(_ suggestions: [HealthSuggestion]) -> [HealthSuggestion] {
        let now = Date()
        return suggestions.filter { suggestion in
            suggestion.expiresAt > now
        }
    }
    
    private func rankSuggestionsByRelevance(_ suggestions: [HealthSuggestion], context: HealthSuggestionContext) -> [HealthSuggestion] {
        return suggestions.sorted { lhs, rhs in
            // First sort by priority
            if lhs.priority != rhs.priority {
                return lhs.priority.sortOrder < rhs.priority.sortOrder
            }
            
            // Then by estimated impact
            if lhs.estimatedImpact != rhs.estimatedImpact {
                return lhs.estimatedImpact > rhs.estimatedImpact
            }
            
            // Finally by confidence
            return lhs.confidence > rhs.confidence
        }
    }
    
    // MARK: - Context Gathering
    
    private func gatherHealthContext() async -> HealthSuggestionContext {
        let healthManager = HealthDataManager.shared
        let locationManager = LocationManager.shared
        let weatherManager = WeatherManager.shared
        
        // Gather health data
        let healthData = HealthContextData(
            currentHeartRate: await healthManager.getLatestHeartRate(),
            stepProgress: await calculateStepProgress(),
            waterIntake: await healthManager.getTodayWaterIntake(),
            lastNightSleepQuality: await calculateSleepQuality(),
            currentStressLevel: await healthManager.getCurrentStressLevel(),
            todayActivity: await getTodayActivityMinutes(),
            hadBreakfast: await checkIfHadBreakfast(),
            morningStretch: await checkMorningStretch(),
            eveningMeal: await checkEveningMeal()
        )
        
        // Gather device usage data
        let deviceUsage = DeviceUsageData(
            continuousScreenTime: await getScreenTime(),
            notificationCount: await getTodayNotificationCount(),
            appUsagePatterns: await getAppUsagePatterns()
        )
        
        // Gather environmental data
        let location = await locationManager.getCurrentLocation()
        let weather = await weatherManager.getCurrentWeather(for: location)
        
        // Gather medication data
        let nextMedication = await getNextMedicationReminder()
        
        return HealthSuggestionContext(
            healthData: healthData,
            deviceUsage: deviceUsage,
            weather: weather,
            location: location,
            timeOfDay: Calendar.current.component(.hour, from: Date()),
            currentActivity: await getCurrentActivityType(),
            nextMedication: nextMedication
        )
    }
    
    // MARK: - Helper Methods
    
    private func loadMLModel() {
        // Load Core ML model for health suggestions
        // This would be a real Core ML model in production
        mlModel = HealthSuggestionMLModel()
    }
    
    private func startPeriodicSuggestionGeneration() {
        timer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in // Every 15 minutes
            Task {
                await self?.generateSuggestions()
            }
        }
    }
    
    private func scheduleNotifications(for suggestions: [HealthSuggestion]) async {
        let center = UNUserNotificationCenter.current()
        
        for suggestion in suggestions {
            if suggestion.priority == .high {
                let content = UNMutableNotificationContent()
                content.title = suggestion.title
                content.body = suggestion.message
                content.sound = .default
                content.categoryIdentifier = "HEALTH_SUGGESTION"
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(
                    identifier: suggestion.id,
                    content: content,
                    trigger: trigger
                )
                
                do {
                    try await center.add(request)
                } catch {
                    print("❌ Failed to schedule notification: \(error)")
                }
            }
        }
    }
    
    private func shouldSuggestMedication(context: HealthSuggestionContext) async -> Bool {
        guard let nextMed = context.nextMedication else { return false }
        
        let now = Date()
        let timeUntilMedication = nextMed.scheduledTime.timeIntervalSince(now)
        
        // Suggest if medication is due within 15 minutes
        return timeUntilMedication <= 900 && timeUntilMedication > 0
    }
    
    // MARK: - Mock Data Methods
    
    private func calculateStepProgress() async -> Double {
        let steps = await HealthDataManager.shared.getTodaySteps() ?? 0
        return min(steps / 10000.0, 1.0) // Assuming 10K step goal
    }
    
    private func calculateSleepQuality() async -> Double {
        let sleep = await HealthDataManager.shared.getLastNightSleep()
        return sleep?.efficiency ?? 0.8
    }
    
    private func getTodayActivityMinutes() async -> Int {
        // Mock implementation
        return Int.random(in: 0...120)
    }
    
    private func checkIfHadBreakfast() async -> Bool {
        // Mock implementation
        return Bool.random()
    }
    
    private func checkMorningStretch() async -> Bool {
        // Mock implementation
        return Bool.random()
    }
    
    private func checkEveningMeal() async -> Bool {
        // Mock implementation
        return Bool.random()
    }
    
    private func getScreenTime() async -> TimeInterval {
        // Mock implementation
        return TimeInterval.random(in: 0...480) // 0-8 hours in minutes
    }
    
    private func getTodayNotificationCount() async -> Int {
        // Mock implementation
        return Int.random(in: 10...100)
    }
    
    private func getAppUsagePatterns() async -> [String: TimeInterval] {
        // Mock implementation
        return [
            "Social": TimeInterval.random(in: 0...120),
            "Health": TimeInterval.random(in: 0...60),
            "Productivity": TimeInterval.random(in: 0...180)
        ]
    }
    
    private func getCurrentActivityType() async -> ActivityType {
        let activities: [ActivityType] = [.resting, .walking, .exercise, .working]
        return activities.randomElement() ?? .resting
    }
    
    private func getNextMedicationReminder() async -> MedicationReminder? {
        // Mock implementation
        if Bool.random() {
            return MedicationReminder(
                name: "Vitamin D",
                scheduledTime: Date().addingTimeInterval(TimeInterval.random(in: 0...3600)),
                time: "2:00 PM"
            )
        }
        return nil
    }
    
    private func getUserSuggestionPreferences() async -> SuggestionPreferences {
        // Mock implementation - would load from user preferences
        return SuggestionPreferences(
            fitnessReminders: true,
            nutritionSuggestions: true,
            sleepReminders: true,
            medicationReminders: true,
            mentalHealthSupport: true,
            safetyAlerts: true,
            wellnessReminders: true,
            healthAlerts: true
        )
    }
}

// MARK: - Data Structures

struct HealthSuggestion: Identifiable, Codable {
    let id: String
    let type: SuggestionType
    let title: String
    let message: String
    let priority: SuggestionPriority
    let category: SuggestionCategory
    let actionType: ActionType
    let estimatedImpact: Double // 0.0 - 1.0
    let confidence: Double // 0.0 - 1.0
    let timestamp: Date
    let expiresAt: Date
}

enum SuggestionType: String, Codable {
    case medicationReminder
    case activityReminder
    case activitySuggestion
    case nutritionSuggestion
    case sleepSuggestion
    case sleepReminder
    case sleepPreparation
    case hydrationReminder
    case wellnessReminder
    case stressManagement
    case healthAlert
    case healthReminder
    case weatherAlert
}

enum SuggestionPriority: String, Codable {
    case low
    case medium
    case high
    
    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

enum SuggestionCategory: String, Codable {
    case fitness
    case nutrition
    case sleep
    case medication
    case mentalHealth
    case safety
    case wellness
    case health
}

enum ActionType: String, Codable {
    case reminder
    case suggestion
    case action
    case alert
}

enum ActivityType {
    case resting
    case walking
    case exercise
    case working
}

struct HealthSuggestionContext {
    let healthData: HealthContextData
    let deviceUsage: DeviceUsageData
    let weather: WeatherData
    let location: CLLocation?
    let timeOfDay: Int
    let currentActivity: ActivityType
    let nextMedication: MedicationReminder?
}

struct HealthContextData {
    let currentHeartRate: Double?
    let stepProgress: Double
    let waterIntake: Double
    let lastNightSleepQuality: Double
    let currentStressLevel: Double?
    let todayActivity: Int // minutes
    let hadBreakfast: Bool
    let morningStretch: Bool
    let eveningMeal: Bool
}

struct DeviceUsageData {
    let continuousScreenTime: TimeInterval // minutes
    let notificationCount: Int
    let appUsagePatterns: [String: TimeInterval]
}

struct WeatherData {
    let temperature: Double
    let description: String
    let uvIndex: Int
    let isGoodForExercise: Bool
}

struct MedicationReminder {
    let name: String
    let scheduledTime: Date
    let time: String
}

struct SuggestionPreferences {
    let fitnessReminders: Bool
    let nutritionSuggestions: Bool
    let sleepReminders: Bool
    let medicationReminders: Bool
    let mentalHealthSupport: Bool
    let safetyAlerts: Bool
    let wellnessReminders: Bool
    let healthAlerts: Bool
}

// MARK: - Mock Supporting Classes

class HealthSuggestionMLModel {
    // Mock Core ML model for health suggestions
}

class HealthSuggestionManager {
    // Manages suggestion lifecycle
}

class HealthSuggestionAnalytics {
    func trackSuggestionGeneration(suggestions: [HealthSuggestion], context: HealthSuggestionContext) async {
        print("📊 Generated \(suggestions.count) health suggestions")
    }
}

class HealthSuggestionPersonalization {
    func personalizeSuggestions(_ suggestions: [HealthSuggestion], for context: HealthSuggestionContext) async -> [HealthSuggestion] {
        // Apply personalization based on user history and preferences
        return suggestions
    }
}

class HealthContextEngine {
    // Gathers and processes health context
}

class LocationManager {
    static let shared = LocationManager()
    
    func getCurrentLocation() async -> CLLocation? {
        // Mock implementation
        return CLLocation(latitude: 37.7749, longitude: -122.4194) // San Francisco
    }
}

class WeatherManager {
    static let shared = WeatherManager()
    
    func getCurrentWeather(for location: CLLocation?) async -> WeatherData {
        // Mock implementation
        return WeatherData(
            temperature: Double.random(in: 60...80),
            description: ["sunny", "cloudy", "partly cloudy"].randomElement() ?? "sunny",
            uvIndex: Int.random(in: 1...10),
            isGoodForExercise: Bool.random()
        )
    }
}