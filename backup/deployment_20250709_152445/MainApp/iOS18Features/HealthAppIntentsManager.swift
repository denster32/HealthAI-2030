import Foundation
import AppIntents
import HealthKit
import Intents

@available(iOS 18.0, *)
class HealthAppIntentsManager: ObservableObject {
    static let shared = HealthAppIntentsManager()
    
    @Published var availableIntents: [HealthAppIntentMetadata] = []
    @Published var recentIntentUsage: [IntentUsageRecord] = []
    @Published var shortcutSuggestions: [HealthShortcutSuggestion] = []
    
    private let shortcutsManager = HealthShortcutsManager()
    private let analyticsManager = HealthShortcutsAnalytics()
    private let optimizerManager = HealthShortcutsOptimizer()
    
    private init() {
        registerHealthIntents()
        loadIntentHistory()
        generateShortcutSuggestions()
    }
    
    // MARK: - Intent Registration
    
    private func registerHealthIntents() {
        let intents: [HealthAppIntentMetadata] = [
            // Vital Signs Intents
            HealthAppIntentMetadata(
                id: "get_heart_rate",
                title: "Get Heart Rate",
                description: "Retrieve current or recent heart rate data",
                category: .vitals,
                systemImageName: "heart.fill",
                intent: GetHeartRateIntent.self,
                parameters: [],
                estimatedExecutionTime: 1.0,
                requiresHealthPermission: true
            ),
            
            HealthAppIntentMetadata(
                id: "get_blood_pressure",
                title: "Get Blood Pressure",
                description: "Retrieve latest blood pressure reading",
                category: .vitals,
                systemImageName: "heart.text.square",
                intent: GetBloodPressureIntent.self,
                parameters: [],
                estimatedExecutionTime: 1.0,
                requiresHealthPermission: true
            ),
            
            // Activity Intents
            HealthAppIntentMetadata(
                id: "get_step_count",
                title: "Get Step Count",
                description: "Check daily step count and progress",
                category: .activity,
                systemImageName: "figure.walk",
                intent: GetStepCountIntent.self,
                parameters: [
                    IntentParameter(name: "timeframe", type: .enumeration, required: false)
                ],
                estimatedExecutionTime: 1.0,
                requiresHealthPermission: true
            ),
            
            HealthAppIntentMetadata(
                id: "log_workout",
                title: "Log Workout",
                description: "Record a completed workout session",
                category: .activity,
                systemImageName: "dumbbell.fill",
                intent: LogWorkoutIntent.self,
                parameters: [
                    IntentParameter(name: "workoutType", type: .enumeration, required: true),
                    IntentParameter(name: "duration", type: .number, required: true),
                    IntentParameter(name: "intensity", type: .enumeration, required: false)
                ],
                estimatedExecutionTime: 2.0,
                requiresHealthPermission: true
            ),
            
            HealthAppIntentMetadata(
                id: "start_workout",
                title: "Start Workout",
                description: "Begin a new workout session",
                category: .activity,
                systemImageName: "play.circle.fill",
                intent: StartWorkoutIntent.self,
                parameters: [
                    IntentParameter(name: "workoutType", type: .enumeration, required: true)
                ],
                estimatedExecutionTime: 1.5,
                requiresHealthPermission: true
            ),
            
            // Nutrition Intents
            HealthAppIntentMetadata(
                id: "log_water_intake",
                title: "Log Water Intake",
                description: "Record water consumption",
                category: .nutrition,
                systemImageName: "drop.fill",
                intent: LogWaterIntakeIntent.self,
                parameters: [
                    IntentParameter(name: "amount", type: .number, required: true),
                    IntentParameter(name: "unit", type: .enumeration, required: false)
                ],
                estimatedExecutionTime: 1.0,
                requiresHealthPermission: true
            ),
            
            HealthAppIntentMetadata(
                id: "log_meal",
                title: "Log Meal",
                description: "Record a meal and nutritional information",
                category: .nutrition,
                systemImageName: "fork.knife",
                intent: LogMealIntent.self,
                parameters: [
                    IntentParameter(name: "mealType", type: .enumeration, required: true),
                    IntentParameter(name: "calories", type: .number, required: false),
                    IntentParameter(name: "description", type: .text, required: false)
                ],
                estimatedExecutionTime: 2.0,
                requiresHealthPermission: true
            ),
            
            // Sleep Intents
            HealthAppIntentMetadata(
                id: "get_sleep_data",
                title: "Get Sleep Data",
                description: "Retrieve sleep analysis and trends",
                category: .sleep,
                systemImageName: "moon.zzz",
                intent: GetSleepDataIntent.self,
                parameters: [
                    IntentParameter(name: "timeframe", type: .enumeration, required: false)
                ],
                estimatedExecutionTime: 1.5,
                requiresHealthPermission: true
            ),
            
            HealthAppIntentMetadata(
                id: "set_sleep_goal",
                title: "Set Sleep Goal",
                description: "Configure sleep duration and bedtime goals",
                category: .sleep,
                systemImageName: "bed.double",
                intent: SetSleepGoalIntent.self,
                parameters: [
                    IntentParameter(name: "bedtime", type: .time, required: true),
                    IntentParameter(name: "wakeTime", type: .time, required: true)
                ],
                estimatedExecutionTime: 1.0,
                requiresHealthPermission: false
            ),
            
            // Mental Health Intents
            HealthAppIntentMetadata(
                id: "start_meditation",
                title: "Start Meditation",
                description: "Begin a guided meditation session",
                category: .mentalHealth,
                systemImageName: "brain.head.profile",
                intent: StartMeditationIntent.self,
                parameters: [
                    IntentParameter(name: "duration", type: .number, required: false),
                    IntentParameter(name: "type", type: .enumeration, required: false)
                ],
                estimatedExecutionTime: 1.0,
                requiresHealthPermission: false
            ),
            
            HealthAppIntentMetadata(
                id: "log_mood",
                title: "Log Mood",
                description: "Record current mood and mental state",
                category: .mentalHealth,
                systemImageName: "face.smiling",
                intent: LogMoodIntent.self,
                parameters: [
                    IntentParameter(name: "mood", type: .enumeration, required: true),
                    IntentParameter(name: "notes", type: .text, required: false)
                ],
                estimatedExecutionTime: 1.5,
                requiresHealthPermission: true
            ),
            
            // Health Goals Intents
            HealthAppIntentMetadata(
                id: "set_health_goal",
                title: "Set Health Goal",
                description: "Create or update health and fitness goals",
                category: .goals,
                systemImageName: "target",
                intent: SetHealthGoalIntent.self,
                parameters: [
                    IntentParameter(name: "goalType", type: .enumeration, required: true),
                    IntentParameter(name: "target", type: .number, required: true),
                    IntentParameter(name: "timeframe", type: .enumeration, required: false)
                ],
                estimatedExecutionTime: 1.0,
                requiresHealthPermission: false
            ),
            
            HealthAppIntentMetadata(
                id: "check_goal_progress",
                title: "Check Goal Progress",
                description: "Review progress towards health goals",
                category: .goals,
                systemImageName: "chart.line.uptrend.xyaxis",
                intent: CheckGoalProgressIntent.self,
                parameters: [
                    IntentParameter(name: "goalType", type: .enumeration, required: false)
                ],
                estimatedExecutionTime: 1.0,
                requiresHealthPermission: true
            ),
            
            // Analysis Intents
            HealthAppIntentMetadata(
                id: "health_summary",
                title: "Health Summary",
                description: "Get comprehensive health overview",
                category: .analysis,
                systemImageName: "doc.text.magnifyingglass",
                intent: HealthSummaryIntent.self,
                parameters: [
                    IntentParameter(name: "timeframe", type: .enumeration, required: false)
                ],
                estimatedExecutionTime: 2.0,
                requiresHealthPermission: true
            ),
            
            HealthAppIntentMetadata(
                id: "health_trends",
                title: "Health Trends",
                description: "Analyze health data trends and patterns",
                category: .analysis,
                systemImageName: "waveform.path.ecg",
                intent: HealthTrendsIntent.self,
                parameters: [
                    IntentParameter(name: "dataType", type: .enumeration, required: true),
                    IntentParameter(name: "timeframe", type: .enumeration, required: false)
                ],
                estimatedExecutionTime: 3.0,
                requiresHealthPermission: true
            )
        ]
        
        DispatchQueue.main.async {
            self.availableIntents = intents
        }
    }
    
    // MARK: - Intent Execution
    
    func executeIntent<T: AppIntent>(_ intentType: T.Type, with parameters: [String: Any]) async throws -> IntentResult {
        let startTime = Date()
        
        do {
            // Create intent instance
            let intent = intentType.init()
            
            // Configure intent parameters
            try configureIntentParameters(intent, with: parameters)
            
            // Execute intent
            let result = try await intent.perform()
            
            // Track usage
            let executionTime = Date().timeIntervalSince(startTime)
            await trackIntentUsage(
                intentType: String(describing: intentType),
                parameters: parameters,
                executionTime: executionTime,
                success: true
            )
            
            return result
            
        } catch {
            let executionTime = Date().timeIntervalSince(startTime)
            await trackIntentUsage(
                intentType: String(describing: intentType),
                parameters: parameters,
                executionTime: executionTime,
                success: false
            )
            throw error
        }
    }
    
    private func configureIntentParameters<T: AppIntent>(_ intent: T, with parameters: [String: Any]) throws {
        // Use reflection to set intent parameters
        let mirror = Mirror(reflecting: intent)
        
        for child in mirror.children {
            guard let propertyName = child.label else { continue }
            
            if let value = parameters[propertyName] {
                // This would require proper parameter setting implementation
                // For now, this is a placeholder for the parameter configuration logic
                print("Setting parameter \(propertyName) to \(value)")
            }
        }
    }
    
    // MARK: - Shortcut Management
    
    func generateShortcutSuggestions() {
        Task {
            let suggestions = await shortcutsManager.generateSuggestions(
                basedOnUsage: recentIntentUsage,
                availableIntents: availableIntents
            )
            
            DispatchQueue.main.async {
                self.shortcutSuggestions = suggestions
            }
        }
    }
    
    func createShortcut(from suggestion: HealthShortcutSuggestion) async -> Bool {
        return await shortcutsManager.createShortcut(
            title: suggestion.title,
            phrase: suggestion.suggestedPhrase,
            intent: suggestion.intent,
            parameters: suggestion.defaultParameters
        )
    }
    
    func getPopularShortcuts() -> [HealthShortcutSuggestion] {
        return shortcutsManager.getPopularShortcuts()
    }
    
    // MARK: - Intent Discovery
    
    func searchIntents(query: String) -> [HealthAppIntentMetadata] {
        let lowercaseQuery = query.lowercased()
        
        return availableIntents.filter { intent in
            intent.title.lowercased().contains(lowercaseQuery) ||
            intent.description.lowercased().contains(lowercaseQuery) ||
            intent.category.rawValue.lowercased().contains(lowercaseQuery)
        }
    }
    
    func getIntentsByCategory(_ category: HealthIntentCategory) -> [HealthAppIntentMetadata] {
        return availableIntents.filter { $0.category == category }
    }
    
    func getRecentlyUsedIntents(limit: Int = 10) -> [HealthAppIntentMetadata] {
        let recentIntentIds = recentIntentUsage
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0.intentId }
        
        return availableIntents.filter { intent in
            recentIntentIds.contains(intent.id)
        }
    }
    
    // MARK: - Usage Analytics
    
    private func trackIntentUsage(
        intentType: String,
        parameters: [String: Any],
        executionTime: TimeInterval,
        success: Bool
    ) async {
        let usage = IntentUsageRecord(
            intentId: intentType,
            parameters: parameters,
            timestamp: Date(),
            executionTime: executionTime,
            success: success
        )
        
        DispatchQueue.main.async {
            self.recentIntentUsage.append(usage)
            
            // Keep only last 100 usage records
            if self.recentIntentUsage.count > 100 {
                self.recentIntentUsage.removeFirst(self.recentIntentUsage.count - 100)
            }
        }
        
        // Track analytics
        await analyticsManager.trackIntentUsage(usage)
        
        // Update optimization
        await optimizerManager.updateOptimization(based: usage)
    }
    
    private func loadIntentHistory() {
        // Mock implementation - would load from persistent storage
        recentIntentUsage = []
    }
    
    // MARK: - Voice Phrase Management
    
    func suggestVoicePhrases(for intent: HealthAppIntentMetadata) -> [String] {
        switch intent.id {
        case "get_heart_rate":
            return [
                "What's my heart rate?",
                "Check my heart rate",
                "Show me my heart rate",
                "How's my heart rate today?"
            ]
        case "get_step_count":
            return [
                "How many steps today?",
                "Check my step count",
                "Show my steps",
                "What's my step progress?"
            ]
        case "log_water_intake":
            return [
                "Log water intake",
                "Record water",
                "I drank water",
                "Add water to my log"
            ]
        case "start_workout":
            return [
                "Start a workout",
                "Begin exercise",
                "Start my workout",
                "Time to exercise"
            ]
        case "start_meditation":
            return [
                "Start meditation",
                "Begin meditation",
                "Time to meditate",
                "Start mindfulness session"
            ]
        default:
            return [
                intent.title,
                "Run \(intent.title.lowercased())",
                "Execute \(intent.title.lowercased())"
            ]
        }
    }
    
    // MARK: - Permission Management
    
    func checkRequiredPermissions(for intent: HealthAppIntentMetadata) async -> [PermissionStatus] {
        var permissions: [PermissionStatus] = []
        
        if intent.requiresHealthPermission {
            let healthStatus = await checkHealthKitPermission()
            permissions.append(PermissionStatus(
                type: .healthKit,
                status: healthStatus,
                required: true
            ))
        }
        
        // Check for other specific permissions based on intent
        switch intent.category {
        case .vitals, .activity, .nutrition, .sleep:
            let motionStatus = await checkMotionPermission()
            permissions.append(PermissionStatus(
                type: .motion,
                status: motionStatus,
                required: false
            ))
        default:
            break
        }
        
        return permissions
    }
    
    private func checkHealthKitPermission() async -> AuthorizationStatus {
        // Mock implementation
        return .authorized
    }
    
    private func checkMotionPermission() async -> AuthorizationStatus {
        // Mock implementation
        return .authorized
    }
}

// MARK: - Data Structures

struct HealthAppIntentMetadata: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: HealthIntentCategory
    let systemImageName: String
    let intent: any AppIntent.Type
    let parameters: [IntentParameter]
    let estimatedExecutionTime: TimeInterval
    let requiresHealthPermission: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, systemImageName
        case parameters, estimatedExecutionTime, requiresHealthPermission
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(systemImageName, forKey: .systemImageName)
        try container.encode(parameters, forKey: .parameters)
        try container.encode(estimatedExecutionTime, forKey: .estimatedExecutionTime)
        try container.encode(requiresHealthPermission, forKey: .requiresHealthPermission)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(HealthIntentCategory.self, forKey: .category)
        systemImageName = try container.decode(String.self, forKey: .systemImageName)
        parameters = try container.decode([IntentParameter].self, forKey: .parameters)
        estimatedExecutionTime = try container.decode(TimeInterval.self, forKey: .estimatedExecutionTime)
        requiresHealthPermission = try container.decode(Bool.self, forKey: .requiresHealthPermission)
        
        // Set intent to a placeholder - this would need proper handling in production
        intent = GetHeartRateIntent.self
    }
    
    init(id: String, title: String, description: String, category: HealthIntentCategory, systemImageName: String, intent: any AppIntent.Type, parameters: [IntentParameter], estimatedExecutionTime: TimeInterval, requiresHealthPermission: Bool) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.systemImageName = systemImageName
        self.intent = intent
        self.parameters = parameters
        self.estimatedExecutionTime = estimatedExecutionTime
        self.requiresHealthPermission = requiresHealthPermission
    }
}

enum HealthIntentCategory: String, Codable, CaseIterable {
    case vitals = "Vitals"
    case activity = "Activity"
    case nutrition = "Nutrition"
    case sleep = "Sleep"
    case mentalHealth = "Mental Health"
    case goals = "Goals"
    case analysis = "Analysis"
    case medication = "Medication"
}

struct IntentParameter: Codable {
    let name: String
    let type: ParameterType
    let required: Bool
}

enum ParameterType: String, Codable {
    case text
    case number
    case enumeration
    case time
    case date
    case boolean
}

struct IntentUsageRecord: Codable {
    let intentId: String
    let parameters: [String: Any]
    let timestamp: Date
    let executionTime: TimeInterval
    let success: Bool
    
    enum CodingKeys: String, CodingKey {
        case intentId, timestamp, executionTime, success
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(intentId, forKey: .intentId)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(executionTime, forKey: .executionTime)
        try container.encode(success, forKey: .success)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intentId = try container.decode(String.self, forKey: .intentId)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        executionTime = try container.decode(TimeInterval.self, forKey: .executionTime)
        success = try container.decode(Bool.self, forKey: .success)
        parameters = [:] // Would need special handling for Any type
    }
    
    init(intentId: String, parameters: [String: Any], timestamp: Date, executionTime: TimeInterval, success: Bool) {
        self.intentId = intentId
        self.parameters = parameters
        self.timestamp = timestamp
        self.executionTime = executionTime
        self.success = success
    }
}

struct HealthShortcutSuggestion: Identifiable {
    let id: String
    let title: String
    let description: String
    let suggestedPhrase: String
    let intent: String
    let defaultParameters: [String: Any]
    let category: HealthIntentCategory
    let popularity: Double
    let estimatedUsefulness: Double
}

struct PermissionStatus {
    let type: PermissionType
    let status: AuthorizationStatus
    let required: Bool
}

enum PermissionType {
    case healthKit
    case motion
    case location
    case notifications
}

enum AuthorizationStatus {
    case notDetermined
    case denied
    case authorized
    case restricted
}

// MARK: - Supporting Managers

class HealthShortcutsManager {
    func generateSuggestions(
        basedOnUsage usage: [IntentUsageRecord],
        availableIntents: [HealthAppIntentMetadata]
    ) async -> [HealthShortcutSuggestion] {
        
        var suggestions: [HealthShortcutSuggestion] = []
        
        // Generate suggestions based on usage patterns
        let usageFrequency = Dictionary(grouping: usage, by: { $0.intentId })
            .mapValues { $0.count }
        
        for intent in availableIntents {
            let frequency = usageFrequency[intent.id] ?? 0
            let popularity = Double(frequency) / Double(max(usage.count, 1))
            
            if popularity > 0.1 || intent.category == .vitals { // Suggest popular or vital intents
                suggestions.append(HealthShortcutSuggestion(
                    id: UUID().uuidString,
                    title: "Quick \(intent.title)",
                    description: "Fast access to \(intent.description.lowercased())",
                    suggestedPhrase: generateSuggestedPhrase(for: intent),
                    intent: intent.id,
                    defaultParameters: generateDefaultParameters(for: intent),
                    category: intent.category,
                    popularity: popularity,
                    estimatedUsefulness: calculateUsefulness(for: intent, usage: usage)
                ))
            }
        }
        
        // Add time-based suggestions
        suggestions.append(contentsOf: generateTimeBasedSuggestions())
        
        // Sort by usefulness and limit
        return suggestions
            .sorted { $0.estimatedUsefulness > $1.estimatedUsefulness }
            .prefix(10)
            .map { $0 }
    }
    
    private func generateSuggestedPhrase(for intent: HealthAppIntentMetadata) -> String {
        switch intent.id {
        case "get_heart_rate": return "Check my heart rate"
        case "get_step_count": return "How many steps today?"
        case "log_water_intake": return "Log my water"
        case "start_workout": return "Start my workout"
        case "start_meditation": return "Time to meditate"
        default: return "Run \(intent.title.lowercased())"
        }
    }
    
    private func generateDefaultParameters(for intent: HealthAppIntentMetadata) -> [String: Any] {
        switch intent.id {
        case "log_water_intake":
            return ["amount": 8, "unit": "oz"]
        case "start_workout":
            return ["workoutType": "walking"]
        case "start_meditation":
            return ["duration": 10, "type": "breathing"]
        default:
            return [:]
        }
    }
    
    private func calculateUsefulness(for intent: HealthAppIntentMetadata, usage: [IntentUsageRecord]) -> Double {
        let frequency = usage.filter { $0.intentId == intent.id }.count
        let recency = usage.filter { $0.intentId == intent.id }
            .max { $0.timestamp < $1.timestamp }?.timestamp ?? Date.distantPast
        
        let frequencyScore = Double(frequency) / Double(max(usage.count, 1))
        let recencyScore = max(0, 1.0 - Date().timeIntervalSince(recency) / (7 * 24 * 3600)) // Last 7 days
        
        return (frequencyScore * 0.7) + (recencyScore * 0.3)
    }
    
    private func generateTimeBasedSuggestions() -> [HealthShortcutSuggestion] {
        let hour = Calendar.current.component(.hour, from: Date())
        var suggestions: [HealthShortcutSuggestion] = []
        
        // Morning suggestions
        if hour >= 6 && hour < 12 {
            suggestions.append(HealthShortcutSuggestion(
                id: "morning_routine",
                title: "Morning Health Check",
                description: "Quick morning health overview",
                suggestedPhrase: "Good morning health check",
                intent: "health_summary",
                defaultParameters: ["timeframe": "today"],
                category: .analysis,
                popularity: 0.8,
                estimatedUsefulness: 0.9
            ))
        }
        
        // Evening suggestions
        if hour >= 18 && hour < 23 {
            suggestions.append(HealthShortcutSuggestion(
                id: "evening_reflection",
                title: "Evening Health Review",
                description: "Review today's health progress",
                suggestedPhrase: "How was my health today?",
                intent: "health_summary",
                defaultParameters: ["timeframe": "today"],
                category: .analysis,
                popularity: 0.7,
                estimatedUsefulness: 0.8
            ))
        }
        
        return suggestions
    }
    
    func createShortcut(
        title: String,
        phrase: String,
        intent: String,
        parameters: [String: Any]
    ) async -> Bool {
        // Mock implementation - would create actual Shortcuts app shortcut
        print("Creating shortcut: \(title) with phrase '\(phrase)'")
        return true
    }
    
    func getPopularShortcuts() -> [HealthShortcutSuggestion] {
        // Mock implementation - would return actual popular shortcuts
        return []
    }
}

class HealthShortcutsAnalytics {
    func trackIntentUsage(_ usage: IntentUsageRecord) async {
        print("📊 Intent used: \(usage.intentId) - Success: \(usage.success) - Time: \(usage.executionTime)s")
    }
}

class HealthShortcutsOptimizer {
    func updateOptimization(based usage: IntentUsageRecord) async {
        // Optimize intent performance based on usage patterns
        if usage.executionTime > 3.0 {
            print("🔧 Slow intent detected: \(usage.intentId) - Optimizing...")
        }
    }
}