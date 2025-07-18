import Foundation
import CoreML
import SwiftUI
import Combine

/// User Preference Learning System
/// Provides machine learning-based user preference detection, content filtering, and behavior pattern recognition
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class UserPreferenceLearning: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var userPreferences: UserPreferences = UserPreferences()
    @Published public private(set) var behaviorPatterns: [BehaviorPattern] = []
    @Published public private(set) var featureRecommendations: [FeatureRecommendation] = []
    @Published public private(set) var preferenceInsights: [PreferenceInsight] = []
    @Published public private(set) var learningProgress: Double = 0.0
    @Published public private(set) var isLearningActive = false
    @Published public private(set) var lastError: String?
    @Published public private(set) var modelAccuracy: Double = 0.0
    
    // MARK: - Private Properties
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    private var cancellables = Set<AnyCancellable>()
    private let learningQueue = DispatchQueue(label: "health.preference.learning", qos: .userInitiated)
    
    // ML Models
    private var preferenceModel: MLModel?
    private var behaviorModel: MLModel?
    private var recommendationModel: MLModel?
    
    // Learning data caches
    private var preferenceData: [String: PreferenceData] = [:]
    private var behaviorData: [String: BehaviorData] = [:]
    private var recommendationData: [String: RecommendationData] = [:]
    
    // Learning parameters
    private let learningUpdateInterval: TimeInterval = 600.0 // 10 minutes
    private var lastLearningUpdate: Date = Date()
    private let minDataPoints = 50
    private let confidenceThreshold = 0.7
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        
        setupLearningSystem()
        setupMLModels()
        setupDataCollection()
        initializeLearningPlatform()
    }
    
    // MARK: - Public Methods
    
    /// Start preference learning system
    public func startLearning() async throws {
        isLearningActive = true
        lastError = nil
        learningProgress = 0.0
        
        do {
            // Initialize learning platform
            try await initializeLearningPlatform()
            
            // Start continuous learning
            try await startContinuousLearning()
            
            // Update learning status
            await updateLearningStatus()
            
            // Track learning start
            analyticsEngine.trackEvent("preference_learning_started", properties: [
                "timestamp": Date().timeIntervalSince1970,
                "model_accuracy": modelAccuracy
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isLearningActive = false
            }
            throw error
        }
    }
    
    /// Stop preference learning system
    public func stopLearning() async {
        await MainActor.run {
            self.isLearningActive = false
        }
        
        // Track learning stop
        analyticsEngine.trackEvent("preference_learning_stopped", properties: [
            "timestamp": Date().timeIntervalSince1970,
            "session_duration": Date().timeIntervalSince(lastLearningUpdate)
        ])
    }
    
    /// Learn from user interaction
    public func learnFromInteraction(_ interaction: UserInteraction) async throws {
        do {
            // Validate interaction
            try await validateInteraction(interaction)
            
            // Process interaction for learning
            try await processInteractionForLearning(interaction)
            
            // Update preference models
            try await updatePreferenceModels(interaction: interaction)
            
            // Update behavior patterns
            await updateBehaviorPatterns(interaction: interaction)
            
            // Generate new insights
            await generatePreferenceInsights()
            
            // Update learning progress
            await updateLearningProgress()
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get user preferences
    public func getUserPreferences() async -> UserPreferences {
        do {
            // Analyze current preferences
            let analysis = try await analyzeCurrentPreferences()
            
            // Update user preferences
            let preferences = UserPreferences(
                healthCategories: analysis.healthCategories,
                interactionPatterns: analysis.interactionPatterns,
                featurePreferences: analysis.featurePreferences,
                contentPreferences: analysis.contentPreferences,
                timingPreferences: analysis.timingPreferences,
                confidence: analysis.confidence,
                lastUpdated: Date()
            )
            
            await MainActor.run {
                self.userPreferences = preferences
            }
            
            return preferences
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return UserPreferences()
        }
    }
    
    /// Get behavior patterns
    public func getBehaviorPatterns() async -> [BehaviorPattern] {
        do {
            // Analyze behavior patterns
            let patterns = try await analyzeBehaviorPatterns()
            
            await MainActor.run {
                self.behaviorPatterns = patterns
            }
            
            return patterns
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Get feature recommendations
    public func getFeatureRecommendations(context: RecommendationContext? = nil) async -> [FeatureRecommendation] {
        do {
            // Analyze user preferences
            let preferenceAnalysis = try await analyzeCurrentPreferences()
            
            // Generate recommendations based on preferences
            let recommendations = try await generateRecommendationsFromPreferences(analysis: preferenceAnalysis, context: context)
            
            // Apply contextual filtering
            let contextualRecommendations = try await applyContextualFiltering(recommendations: recommendations, context: context)
            
            await MainActor.run {
                self.featureRecommendations = contextualRecommendations
            }
            
            return contextualRecommendations
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Filter content based on preferences
    public func filterContent(_ content: [ContentItem], context: FilterContext? = nil) async -> [ContentItem] {
        do {
            // Get user preferences
            let preferences = await getUserPreferences()
            
            // Apply preference-based filtering
            let filteredContent = try await applyPreferenceFiltering(content: content, preferences: preferences, context: context)
            
            // Apply behavioral filtering
            let behavioralContent = try await applyBehavioralFiltering(content: filteredContent, context: context)
            
            return behavioralContent
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return content
        }
    }
    
    /// Get preference insights
    public func getPreferenceInsights() async -> [PreferenceInsight] {
        do {
            // Analyze preference patterns
            let patterns = try await analyzePreferencePatterns()
            
            // Generate insights
            let insights = try await generateInsightsFromPatterns(patterns: patterns)
            
            await MainActor.run {
                self.preferenceInsights = insights
            }
            
            return insights
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Get model accuracy
    public func getModelAccuracy() async -> Double {
        do {
            // Calculate model accuracy
            let accuracy = try await calculateModelAccuracy()
            
            await MainActor.run {
                self.modelAccuracy = accuracy
            }
            
            return accuracy
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return 0.0
        }
    }
    
    /// Retrain models
    public func retrainModels() async throws {
        do {
            // Collect training data
            let trainingData = try await collectTrainingData()
            
            // Validate training data
            try await validateTrainingData(trainingData)
            
            // Retrain preference model
            try await retrainPreferenceModel(data: trainingData)
            
            // Retrain behavior model
            try await retrainBehaviorModel(data: trainingData)
            
            // Retrain recommendation model
            try await retrainRecommendationModel(data: trainingData)
            
            // Update model accuracy
            await getModelAccuracy()
            
            // Track model retraining
            analyticsEngine.trackEvent("models_retrained", properties: [
                "timestamp": Date().timeIntervalSince1970,
                "accuracy": modelAccuracy,
                "training_data_size": trainingData.count
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Export learning data
    public func exportLearningData(format: ExportFormat = .json) async throws -> Data {
        do {
            let exportData = LearningExportData(
                userPreferences: userPreferences,
                behaviorPatterns: behaviorPatterns,
                featureRecommendations: featureRecommendations,
                preferenceInsights: preferenceInsights,
                modelAccuracy: modelAccuracy,
                timestamp: Date()
            )
            
            switch format {
            case .json:
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                return try encoder.encode(exportData)
                
            case .csv:
                return try await exportToCSV(data: exportData)
                
            case .xml:
                return try await exportToXML(data: exportData)
            }
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupLearningSystem() {
        // Setup learning system
        setupDataCollection()
        setupModelManagement()
        setupAccuracyTracking()
        setupPrivacyControls()
    }
    
    private func setupMLModels() {
        // Setup ML models
        setupPreferenceModel()
        setupBehaviorModel()
        setupRecommendationModel()
        setupModelValidation()
    }
    
    private func setupDataCollection() {
        // Setup data collection
        setupInteractionCollection()
        setupPreferenceCollection()
        setupBehaviorCollection()
        setupRecommendationCollection()
    }
    
    private func initializeLearningPlatform() async throws {
        // Initialize learning platform
        try await loadLearningData()
        try await setupMLModels()
        try await initializeDataCollection()
    }
    
    private func startContinuousLearning() async throws {
        // Start continuous learning
        try await startDataCollection()
        try await startModelUpdates()
        try await startAccuracyTracking()
    }
    
    private func validateInteraction(_ interaction: UserInteraction) async throws {
        // Validate user interaction
        guard interaction.isValid else {
            throw LearningError.invalidInteraction(interaction.id.uuidString)
        }
        
        // Check interaction permissions
        if interaction.requiresPermissions {
            let hasPermissions = await checkInteractionPermissions(interaction)
            guard hasPermissions else {
                throw LearningError.insufficientPermissions(interaction.id.uuidString)
            }
        }
    }
    
    private func processInteractionForLearning(_ interaction: UserInteraction) async throws {
        // Process interaction for learning
        let features = extractFeatures(from: interaction)
        let label = extractLabel(from: interaction)
        
        // Add to training data
        try await addToTrainingData(features: features, label: label)
        
        // Update learning progress
        await updateLearningProgress()
    }
    
    private func updatePreferenceModels(interaction: UserInteraction) async throws {
        // Update preference models
        try await updatePreferenceModel(interaction: interaction)
        try await updateBehaviorModel(interaction: interaction)
        try await updateRecommendationModel(interaction: interaction)
    }
    
    private func updateBehaviorPatterns(interaction: UserInteraction) async {
        // Update behavior patterns
        await updateInteractionPatterns(interaction: interaction)
        await updateTimingPatterns(interaction: interaction)
        await updateContextPatterns(interaction: interaction)
    }
    
    private func generatePreferenceInsights() async {
        // Generate preference insights
        let patterns = await analyzePreferencePatterns()
        let insights = await generateInsightsFromPatterns(patterns: patterns)
        
        await MainActor.run {
            self.preferenceInsights = insights
        }
    }
    
    private func updateLearningProgress() async {
        // Update learning progress
        let progress = await calculateLearningProgress()
        await MainActor.run {
            self.learningProgress = progress
        }
    }
    
    private func analyzeCurrentPreferences() async throws -> PreferenceAnalysis {
        // Analyze current preferences
        let patterns = await analyzePreferencePatterns()
        let metrics = await calculatePreferenceMetrics()
        
        return PreferenceAnalysis(
            healthCategories: patterns.healthCategories,
            interactionPatterns: patterns.interactionPatterns,
            featurePreferences: patterns.featurePreferences,
            contentPreferences: patterns.contentPreferences,
            timingPreferences: patterns.timingPreferences,
            confidence: metrics.confidence,
            timestamp: Date()
        )
    }
    
    private func analyzeBehaviorPatterns() async throws -> [BehaviorPattern] {
        // Analyze behavior patterns
        let patterns = await analyzeInteractionPatterns()
        let timingPatterns = await analyzeTimingPatterns()
        let contextPatterns = await analyzeContextPatterns()
        
        return patterns + timingPatterns + contextPatterns
    }
    
    private func generateRecommendationsFromPreferences(analysis: PreferenceAnalysis, context: RecommendationContext?) async throws -> [FeatureRecommendation] {
        // Generate recommendations based on preference analysis
        var recommendations: [FeatureRecommendation] = []
        
        // Add preferred features
        for feature in analysis.featurePreferences.prefix(5) {
            recommendations.append(FeatureRecommendation(
                id: UUID(),
                feature: feature.feature,
                priority: .high,
                reason: "Based on your preferences",
                confidence: feature.confidence,
                context: context,
                timestamp: Date()
            ))
        }
        
        // Add contextual recommendations
        if let context = context {
            let contextualRecommendations = try await generateContextualRecommendations(context: context)
            recommendations.append(contentsOf: contextualRecommendations)
        }
        
        return recommendations
    }
    
    private func applyContextualFiltering(recommendations: [FeatureRecommendation], context: RecommendationContext?) async throws -> [FeatureRecommendation] {
        // Apply contextual filtering
        var filteredRecommendations = recommendations
        
        // Filter by time of day
        if let context = context {
            filteredRecommendations = filteredRecommendations.filter { recommendation in
                recommendation.feature.isAppropriateForTime(context.timeOfDay)
            }
        }
        
        // Filter by health status
        if let context = context {
            filteredRecommendations = filteredRecommendations.filter { recommendation in
                recommendation.feature.isAppropriateForHealthStatus(context.healthStatus)
            }
        }
        
        return filteredRecommendations
    }
    
    private func applyPreferenceFiltering(content: [ContentItem], preferences: UserPreferences, context: FilterContext?) async throws -> [ContentItem] {
        // Apply preference-based filtering
        var filteredContent = content
        
        // Filter by health categories
        filteredContent = filteredContent.filter { item in
            preferences.healthCategories.contains { category in
                item.category == category.category
            }
        }
        
        // Filter by content preferences
        filteredContent = filteredContent.filter { item in
            preferences.contentPreferences.contains { preference in
                item.type == preference.contentType
            }
        }
        
        return filteredContent
    }
    
    private func applyBehavioralFiltering(content: [ContentItem], context: FilterContext?) async throws -> [ContentItem] {
        // Apply behavioral filtering
        var filteredContent = content
        
        // Apply behavioral patterns
        let patterns = await getBehaviorPatterns()
        for pattern in patterns {
            filteredContent = try await applyBehavioralPattern(content: filteredContent, pattern: pattern)
        }
        
        return filteredContent
    }
    
    private func analyzePreferencePatterns() async throws -> PreferencePatterns {
        // Analyze preference patterns
        let healthCategories = calculateHealthCategoryPreferences()
        let interactionPatterns = calculateInteractionPatterns()
        let featurePreferences = calculateFeaturePreferences()
        let contentPreferences = calculateContentPreferences()
        let timingPreferences = calculateTimingPreferences()
        
        return PreferencePatterns(
            healthCategories: healthCategories,
            interactionPatterns: interactionPatterns,
            featurePreferences: featurePreferences,
            contentPreferences: contentPreferences,
            timingPreferences: timingPreferences,
            timestamp: Date()
        )
    }
    
    private func generateInsightsFromPatterns(patterns: PreferencePatterns) async throws -> [PreferenceInsight] {
        // Generate insights from patterns
        var insights: [PreferenceInsight] = []
        
        // Health category insight
        if let topCategory = patterns.healthCategories.first {
            insights.append(PreferenceInsight(
                id: UUID(),
                title: "Health Focus",
                description: "You show strong interest in \(topCategory.category.displayName)",
                type: .health,
                priority: .medium,
                confidence: topCategory.confidence,
                timestamp: Date()
            ))
        }
        
        // Feature preference insight
        if let topFeature = patterns.featurePreferences.first {
            insights.append(PreferenceInsight(
                id: UUID(),
                title: "Feature Preference",
                description: "You prefer \(topFeature.feature.displayName) features",
                type: .feature,
                priority: .medium,
                confidence: topFeature.confidence,
                timestamp: Date()
            ))
        }
        
        return insights
    }
    
    private func calculateModelAccuracy() async throws -> Double {
        // Calculate model accuracy
        let testData = try await collectTestData()
        let accuracy = try await evaluateModelAccuracy(testData: testData)
        return accuracy
    }
    
    private func collectTrainingData() async throws -> [TrainingData] {
        // Collect training data
        return []
    }
    
    private func validateTrainingData(_ data: [TrainingData]) async throws {
        // Validate training data
        guard data.count >= minDataPoints else {
            throw LearningError.insufficientTrainingData(data.count)
        }
    }
    
    private func retrainPreferenceModel(data: [TrainingData]) async throws {
        // Retrain preference model
    }
    
    private func retrainBehaviorModel(data: [TrainingData]) async throws {
        // Retrain behavior model
    }
    
    private func retrainRecommendationModel(data: [TrainingData]) async throws {
        // Retrain recommendation model
    }
    
    private func updateLearningStatus() async {
        // Update learning status
        lastLearningUpdate = Date()
    }
    
    private func loadLearningData() async throws {
        // Load learning data
        try await loadPreferenceData()
        try await loadBehaviorData()
        try await loadRecommendationData()
    }
    
    private func setupMLModels() async throws {
        // Setup ML models
        try await setupPreferenceModel()
        try await setupBehaviorModel()
        try await setupRecommendationModel()
    }
    
    private func initializeDataCollection() async throws {
        // Initialize data collection
        try await setupInteractionCollection()
        try await setupPreferenceCollection()
        try await setupBehaviorCollection()
    }
    
    private func startDataCollection() async throws {
        // Start data collection
        try await startInteractionCollection()
        try await startPreferenceCollection()
        try await startBehaviorCollection()
    }
    
    private func startModelUpdates() async throws {
        // Start model updates
        try await startPreferenceModelUpdates()
        try await startBehaviorModelUpdates()
        try await startRecommendationModelUpdates()
    }
    
    private func startAccuracyTracking() async throws {
        // Start accuracy tracking
        try await startModelAccuracyTracking()
        try await startPredictionAccuracyTracking()
    }
    
    private func checkInteractionPermissions(_ interaction: UserInteraction) async -> Bool {
        // Check interaction permissions
        return true // Placeholder
    }
    
    private func extractFeatures(from interaction: UserInteraction) -> [String: Any] {
        // Extract features from interaction
        return [:]
    }
    
    private func extractLabel(from interaction: UserInteraction) -> String {
        // Extract label from interaction
        return interaction.type.rawValue
    }
    
    private func addToTrainingData(features: [String: Any], label: String) async throws {
        // Add to training data
    }
    
    private func updatePreferenceModel(interaction: UserInteraction) async throws {
        // Update preference model
    }
    
    private func updateBehaviorModel(interaction: UserInteraction) async throws {
        // Update behavior model
    }
    
    private func updateRecommendationModel(interaction: UserInteraction) async throws {
        // Update recommendation model
    }
    
    private func updateInteractionPatterns(interaction: UserInteraction) async {
        // Update interaction patterns
    }
    
    private func updateTimingPatterns(interaction: UserInteraction) async {
        // Update timing patterns
    }
    
    private func updateContextPatterns(interaction: UserInteraction) async {
        // Update context patterns
    }
    
    private func calculateLearningProgress() async -> Double {
        // Calculate learning progress
        return 0.75 // 75% progress placeholder
    }
    
    private func calculatePreferenceMetrics() async throws -> PreferenceMetrics {
        // Calculate preference metrics
        return PreferenceMetrics(
            confidence: 0.85,
            timestamp: Date()
        )
    }
    
    private func analyzeInteractionPatterns() async throws -> [BehaviorPattern] {
        // Analyze interaction patterns
        return []
    }
    
    private func analyzeTimingPatterns() async throws -> [BehaviorPattern] {
        // Analyze timing patterns
        return []
    }
    
    private func analyzeContextPatterns() async throws -> [BehaviorPattern] {
        // Analyze context patterns
        return []
    }
    
    private func generateContextualRecommendations(context: RecommendationContext) async throws -> [FeatureRecommendation] {
        // Generate contextual recommendations
        return []
    }
    
    private func applyBehavioralPattern(content: [ContentItem], pattern: BehaviorPattern) async throws -> [ContentItem] {
        // Apply behavioral pattern
        return content
    }
    
    private func calculateHealthCategoryPreferences() -> [HealthCategoryPreference] {
        // Calculate health category preferences
        return []
    }
    
    private func calculateInteractionPatterns() -> [InteractionPattern] {
        // Calculate interaction patterns
        return []
    }
    
    private func calculateFeaturePreferences() -> [FeaturePreference] {
        // Calculate feature preferences
        return []
    }
    
    private func calculateContentPreferences() -> [ContentPreference] {
        // Calculate content preferences
        return []
    }
    
    private func calculateTimingPreferences() -> [TimingPreference] {
        // Calculate timing preferences
        return []
    }
    
    private func collectTestData() async throws -> [TestData] {
        // Collect test data
        return []
    }
    
    private func evaluateModelAccuracy(testData: [TestData]) async throws -> Double {
        // Evaluate model accuracy
        return 0.85 // 85% accuracy placeholder
    }
    
    private func loadPreferenceData() async throws {
        // Load preference data
    }
    
    private func loadBehaviorData() async throws {
        // Load behavior data
    }
    
    private func loadRecommendationData() async throws {
        // Load recommendation data
    }
    
    private func setupPreferenceModel() async throws {
        // Setup preference model
    }
    
    private func setupBehaviorModel() async throws {
        // Setup behavior model
    }
    
    private func setupRecommendationModel() async throws {
        // Setup recommendation model
    }
    
    private func setupInteractionCollection() async throws {
        // Setup interaction collection
    }
    
    private func setupPreferenceCollection() async throws {
        // Setup preference collection
    }
    
    private func setupBehaviorCollection() async throws {
        // Setup behavior collection
    }
    
    private func startInteractionCollection() async throws {
        // Start interaction collection
    }
    
    private func startPreferenceCollection() async throws {
        // Start preference collection
    }
    
    private func startBehaviorCollection() async throws {
        // Start behavior collection
    }
    
    private func startPreferenceModelUpdates() async throws {
        // Start preference model updates
    }
    
    private func startBehaviorModelUpdates() async throws {
        // Start behavior model updates
    }
    
    private func startRecommendationModelUpdates() async throws {
        // Start recommendation model updates
    }
    
    private func startModelAccuracyTracking() async throws {
        // Start model accuracy tracking
    }
    
    private func startPredictionAccuracyTracking() async throws {
        // Start prediction accuracy tracking
    }
    
    private func exportToCSV(data: LearningExportData) async throws -> Data {
        // Export to CSV
        return Data()
    }
    
    private func exportToXML(data: LearningExportData) async throws -> Data {
        // Export to XML
        return Data()
    }
}

// MARK: - Data Models

public struct UserPreferences: Codable {
    public let healthCategories: [HealthCategoryPreference]
    public let interactionPatterns: [InteractionPattern]
    public let featurePreferences: [FeaturePreference]
    public let contentPreferences: [ContentPreference]
    public let timingPreferences: [TimingPreference]
    public let confidence: Double
    public let lastUpdated: Date
    
    public init() {
        self.healthCategories = []
        self.interactionPatterns = []
        self.featurePreferences = []
        self.contentPreferences = []
        self.timingPreferences = []
        self.confidence = 0.0
        self.lastUpdated = Date()
    }
}

public struct UserInteraction: Identifiable, Codable {
    public let id: UUID
    public let type: InteractionType
    public let target: String
    public let duration: TimeInterval
    public let context: InteractionContext?
    public let timestamp: Date
    public let requiresPermissions: Bool
    
    var isValid: Bool {
        return !target.isEmpty && duration > 0
    }
}

public struct BehaviorPattern: Identifiable, Codable {
    public let id: UUID
    public let pattern: String
    public let frequency: Double
    public let confidence: Double
    public let category: PatternCategory
    public let timestamp: Date
}

public struct FeatureRecommendation: Identifiable, Codable {
    public let id: UUID
    public let feature: AppFeature
    public let priority: RecommendationPriority
    public let reason: String
    public let confidence: Double
    public let context: RecommendationContext?
    public let timestamp: Date
}

public struct PreferenceInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: InsightType
    public let priority: InsightPriority
    public let confidence: Double
    public let timestamp: Date
}

public struct LearningExportData: Codable {
    public let userPreferences: UserPreferences
    public let behaviorPatterns: [BehaviorPattern]
    public let featureRecommendations: [FeatureRecommendation]
    public let preferenceInsights: [PreferenceInsight]
    public let modelAccuracy: Double
    public let timestamp: Date
}

public enum InteractionType: String, Codable {
    case tap = "tap"
    case swipe = "swipe"
    case scroll = "scroll"
    case longPress = "long_press"
    case voice = "voice"
    case gesture = "gesture"
}

public struct InteractionContext: Codable {
    public let screen: String
    public let timeOfDay: TimeOfDay
    public let healthStatus: HealthStatus
    public let userActivity: [String]
}

public enum PatternCategory: String, Codable {
    case interaction = "interaction"
    case timing = "timing"
    case context = "context"
    case preference = "preference"
}

public struct AppFeature: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let category: FeatureCategory
    public let description: String
    
    var displayName: String {
        return name
    }
    
    func isAppropriateForTime(_ timeOfDay: TimeOfDay) -> Bool {
        // Check if feature is appropriate for time of day
        return true // Placeholder
    }
    
    func isAppropriateForHealthStatus(_ status: HealthStatus) -> Bool {
        // Check if feature is appropriate for health status
        return true // Placeholder
    }
}

public enum FeatureCategory: String, Codable {
    case health = "health"
    case fitness = "fitness"
    case nutrition = "nutrition"
    case sleep = "sleep"
    case mentalHealth = "mental_health"
    case social = "social"
    case analytics = "analytics"
    case coaching = "coaching"
}

public enum RecommendationPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

public struct RecommendationContext: Codable {
    public let timeOfDay: TimeOfDay
    public let healthStatus: HealthStatus
    public let userActivity: [String]
    public let deviceType: DeviceType
}

public struct FilterContext: Codable {
    public let timeOfDay: TimeOfDay
    public let healthStatus: HealthStatus
    public let userActivity: [String]
}

public struct ContentItem: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let category: HealthCategory
    public let type: ContentType
    public let priority: ContentPriority
    public let timestamp: Date
}

public enum HealthCategory: String, Codable {
    case cardiovascular = "cardiovascular"
    case respiratory = "respiratory"
    case sleep = "sleep"
    case fitness = "fitness"
    case nutrition = "nutrition"
    case mentalHealth = "mental_health"
    case social = "social"
    
    var displayName: String {
        switch self {
        case .cardiovascular: return "Cardiovascular"
        case .respiratory: return "Respiratory"
        case .sleep: return "Sleep"
        case .fitness: return "Fitness"
        case .nutrition: return "Nutrition"
        case .mentalHealth: return "Mental Health"
        case .social: return "Social"
        }
    }
}

public enum ContentType: String, Codable {
    case article = "article"
    case video = "video"
    case infographic = "infographic"
    case tip = "tip"
    case reminder = "reminder"
}

public enum ContentPriority: String, Codable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
}

public struct HealthCategoryPreference: Codable {
    public let category: HealthCategory
    public let preference: Double
    public let confidence: Double
    public let lastInteraction: Date
}

public struct InteractionPattern: Codable {
    public let pattern: String
    public let frequency: Double
    public let confidence: Double
    public let timestamp: Date
}

public struct FeaturePreference: Codable {
    public let feature: AppFeature
    public let preference: Double
    public let confidence: Double
    public let lastUsed: Date
}

public struct ContentPreference: Codable {
    public let contentType: ContentType
    public let preference: Double
    public let confidence: Double
    public let lastViewed: Date
}

public struct TimingPreference: Codable {
    public let timeOfDay: TimeOfDay
    public let preference: Double
    public let confidence: Double
    public let lastActivity: Date
}

public struct PreferenceAnalysis: Codable {
    public let healthCategories: [HealthCategoryPreference]
    public let interactionPatterns: [InteractionPattern]
    public let featurePreferences: [FeaturePreference]
    public let contentPreferences: [ContentPreference]
    public let timingPreferences: [TimingPreference]
    public let confidence: Double
    public let timestamp: Date
}

public struct PreferencePatterns: Codable {
    public let healthCategories: [HealthCategoryPreference]
    public let interactionPatterns: [InteractionPattern]
    public let featurePreferences: [FeaturePreference]
    public let contentPreferences: [ContentPreference]
    public let timingPreferences: [TimingPreference]
    public let timestamp: Date
}

public struct PreferenceMetrics: Codable {
    public let confidence: Double
    public let timestamp: Date
}

public enum InsightType: String, Codable {
    case health = "health"
    case feature = "feature"
    case behavior = "behavior"
    case timing = "timing"
}

public enum InsightPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

public enum TimeOfDay: String, Codable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
}

public enum HealthStatus: String, Codable {
    case critical = "critical"
    case poor = "poor"
    case normal = "normal"
    case good = "good"
    case excellent = "excellent"
}

public enum DeviceType: String, Codable {
    case iPhone = "iphone"
    case iPad = "ipad"
    case mac = "mac"
    case watch = "watch"
    case tv = "tv"
}

public enum ExportFormat: String, Codable {
    case json = "json"
    case csv = "csv"
    case xml = "xml"
}

public enum LearningError: Error, LocalizedError {
    case invalidInteraction(String)
    case insufficientPermissions(String)
    case insufficientTrainingData(Int)
    case modelTrainingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidInteraction(let interaction):
            return "Invalid interaction: \(interaction)"
        case .insufficientPermissions(let interaction):
            return "Insufficient permissions for interaction: \(interaction)"
        case .insufficientTrainingData(let count):
            return "Insufficient training data: \(count) points (minimum: \(50))"
        case .modelTrainingFailed(let reason):
            return "Model training failed: \(reason)"
        }
    }
}

// MARK: - Supporting Structures

public struct TrainingData: Codable {
    public let features: [String: Any]
    public let label: String
    public let timestamp: Date
}

public struct TestData: Codable {
    public let features: [String: Any]
    public let label: String
    public let timestamp: Date
}

public struct PreferenceData: Codable {
    public let preferences: [String: Any]
    public let patterns: [PreferencePattern]
    public let analytics: PreferenceAnalytics
}

public struct BehaviorData: Codable {
    public let patterns: [BehaviorPattern]
    public let interactions: [UserInteraction]
    public let analytics: BehaviorAnalytics
}

public struct RecommendationData: Codable {
    public let recommendations: [FeatureRecommendation]
    public let accuracy: Double
    public let analytics: RecommendationAnalytics
}

public struct PreferencePattern: Codable {
    public let pattern: String
    public let frequency: Double
    public let confidence: Double
    public let timestamp: Date
}

public struct PreferenceAnalytics: Codable {
    public let totalPreferences: Int
    public let averageConfidence: Double
    public let mostCommonPatterns: [String]
}

public struct BehaviorAnalytics: Codable {
    public let totalInteractions: Int
    public let averageFrequency: Double
    public let mostCommonPatterns: [String]
}

public struct RecommendationAnalytics: Codable {
    public let totalRecommendations: Int
    public let averageAccuracy: Double
    public let mostRecommendedFeatures: [String]
} 