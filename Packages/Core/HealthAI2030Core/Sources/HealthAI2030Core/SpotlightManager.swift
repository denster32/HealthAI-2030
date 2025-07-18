import Foundation
import CoreSpotlight
#if canImport(MobileCoreServices)
import MobileCoreServices
#elseif canImport(CoreServices)
import CoreServices
#endif
import SwiftUI
import Combine
import OSLog

// MARK: - Spotlight Manager for iOS 18 Search Integration

@available(iOS 18.0, *)
class SpotlightManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var indexedItems: [SpotlightItem] = []
    @Published var searchQueries: [SearchQuery] = []
    @Published var indexingProgress: Double = 0.0
    @Published var isIndexing = false
    
    // MARK: - Private Properties
    private let searchableIndex = CSSearchableIndex.default()
    private let logger = Logger(subsystem: "com.healthai2030.spotlight", category: "manager")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Domain Identifiers
    private struct DomainIdentifiers {
        static let healthData = "com.healthai2030.healthdata"
        static let sleepData = "com.healthai2030.sleepdata"
        static let aiInsights = "com.healthai2030.aiinsights"
        static let coachingRecommendations = "com.healthai2030.coaching"
        static let environmentSettings = "com.healthai2030.environment"
        static let emergencyContacts = "com.healthai2030.emergency"
    }
    
    init() {
        setupSpotlightConfiguration()
        setupSearchHandlers()
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        logger.info("Initializing Spotlight Manager")
        
        // Clear existing index
        await clearIndex()
        
        // Index current health data
        await indexHealthData()
        
        // Setup continuous indexing
        setupContinuousIndexing()
        
        // Configure search suggestions
        await configureSearchSuggestions()
    }
    
    // MARK: - Health Data Indexing
    
    func indexHealthData() async {
        logger.info("Indexing health data for Spotlight search")
        
        await MainActor.run {
            self.isIndexing = true
            self.indexingProgress = 0.0
        }
        
        var items: [CSSearchableItem] = []
        
        // Index health metrics
        items.append(contentsOf: await indexHealthMetrics())
        await updateProgress(0.2)
        
        // Index sleep data
        items.append(contentsOf: await indexSleepData())
        await updateProgress(0.4)
        
        // Index AI insights
        items.append(contentsOf: await indexAIInsights())
        await updateProgress(0.6)
        
        // Index coaching recommendations
        items.append(contentsOf: await indexCoachingRecommendations())
        await updateProgress(0.8)
        
        // Index environment settings
        items.append(contentsOf: await indexEnvironmentSettings())
        await updateProgress(0.9)
        
        // Index emergency information
        items.append(contentsOf: await indexEmergencyInformation())
        await updateProgress(1.0)
        
        // Add items to search index
        await addItemsToIndex(items)
        
        await MainActor.run {
            self.isIndexing = false
            self.indexingProgress = 0.0
        }
        
        logger.info("Completed indexing \(items.count) items")
    }
    
    // MARK: - Individual Indexing Methods
    
    private func indexHealthMetrics() async -> [CSSearchableItem] {
        var items: [CSSearchableItem] = []
        
        // Current health metrics
        let healthMetrics = await getCurrentHealthMetrics()
        
        let healthItem = CSSearchableItem(
            uniqueIdentifier: "current_health_metrics",
            domainIdentifier: DomainIdentifiers.healthData,
            attributeSet: createHealthMetricsAttributeSet(healthMetrics)
        )
        
        items.append(healthItem)
        
        // Recent health trends
        let trends = await getHealthTrends()
        for (index, trend) in trends.enumerated() {
            let trendItem = CSSearchableItem(
                uniqueIdentifier: "health_trend_\(index)",
                domainIdentifier: DomainIdentifiers.healthData,
                attributeSet: createHealthTrendAttributeSet(trend)
            )
            items.append(trendItem)
        }
        
        return items
    }
    
    private func indexSleepData() async -> [CSSearchableItem] {
        var items: [CSSearchableItem] = []
        
        // Recent sleep sessions
        let sleepSessions = await getRecentSleepSessions()
        for session in sleepSessions {
            let sleepItem = CSSearchableItem(
                uniqueIdentifier: "sleep_session_\(session.id)",
                domainIdentifier: DomainIdentifiers.sleepData,
                attributeSet: createSleepSessionAttributeSet(session)
            )
            items.append(sleepItem)
        }
        
        // Sleep analytics
        let analytics = await getSleepAnalytics()
        let analyticsItem = CSSearchableItem(
            uniqueIdentifier: "sleep_analytics",
            domainIdentifier: DomainIdentifiers.sleepData,
            attributeSet: createSleepAnalyticsAttributeSet(analytics)
        )
        items.append(analyticsItem)
        
        return items
    }
    
    private func indexAIInsights() async -> [CSSearchableItem] {
        var items: [CSSearchableItem] = []
        
        // AI-generated insights
        let insights = await getAIInsights()
        for insight in insights {
            let insightItem = CSSearchableItem(
                uniqueIdentifier: "ai_insight_\(insight.id)",
                domainIdentifier: DomainIdentifiers.aiInsights,
                attributeSet: createAIInsightAttributeSet(insight)
            )
            items.append(insightItem)
        }
        
        // Predictive analytics
        let predictions = await getPredictiveAnalytics()
        for prediction in predictions {
            let predictionItem = CSSearchableItem(
                uniqueIdentifier: "prediction_\(prediction.id)",
                domainIdentifier: DomainIdentifiers.aiInsights,
                attributeSet: createPredictionAttributeSet(prediction)
            )
            items.append(predictionItem)
        }
        
        return items
    }
    
    private func indexCoachingRecommendations() async -> [CSSearchableItem] {
        var items: [CSSearchableItem] = []
        
        // Current coaching recommendations
        let recommendations = await getCoachingRecommendations()
        for recommendation in recommendations {
            let coachingItem = CSSearchableItem(
                uniqueIdentifier: "coaching_\(recommendation.id)",
                domainIdentifier: DomainIdentifiers.coachingRecommendations,
                attributeSet: createCoachingAttributeSet(recommendation)
            )
            items.append(coachingItem)
        }
        
        // Coaching programs
        let programs = await getCoachingPrograms()
        for program in programs {
            let programItem = CSSearchableItem(
                uniqueIdentifier: "program_\(program.id)",
                domainIdentifier: DomainIdentifiers.coachingRecommendations,
                attributeSet: createProgramAttributeSet(program)
            )
            items.append(programItem)
        }
        
        return items
    }
    
    private func indexEnvironmentSettings() async -> [CSSearchableItem] {
        var items: [CSSearchableItem] = []
        
        // Environment presets
        let presets = await getEnvironmentPresets()
        for preset in presets {
            let presetItem = CSSearchableItem(
                uniqueIdentifier: "environment_preset_\(preset.id)",
                domainIdentifier: DomainIdentifiers.environmentSettings,
                attributeSet: createEnvironmentPresetAttributeSet(preset)
            )
            items.append(presetItem)
        }
        
        // Current environment status
        let currentEnvironment = await getCurrentEnvironmentStatus()
        let environmentItem = CSSearchableItem(
            uniqueIdentifier: "current_environment",
            domainIdentifier: DomainIdentifiers.environmentSettings,
            attributeSet: createEnvironmentStatusAttributeSet(currentEnvironment)
        )
        items.append(environmentItem)
        
        return items
    }
    
    private func indexEmergencyInformation() async -> [CSSearchableItem] {
        var items: [CSSearchableItem] = []
        
        // Emergency contacts
        let contacts = await getEmergencyContacts()
        for contact in contacts {
            let contactItem = CSSearchableItem(
                uniqueIdentifier: "emergency_contact_\(contact.id)",
                domainIdentifier: DomainIdentifiers.emergencyContacts,
                attributeSet: createEmergencyContactAttributeSet(contact)
            )
            items.append(contactItem)
        }
        
        // Medical information
        let medicalInfo = await getMedicalInformation()
        let medicalItem = CSSearchableItem(
            uniqueIdentifier: "medical_information",
            domainIdentifier: DomainIdentifiers.emergencyContacts,
            attributeSet: createMedicalInfoAttributeSet(medicalInfo)
        )
        items.append(medicalItem)
        
        return items
    }
    
    // MARK: - Attribute Set Creation
    
    private func createHealthMetricsAttributeSet(_ metrics: HealthMetricsData) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        
        attributeSet.title = "Current Health Metrics"
        attributeSet.contentDescription = "Heart Rate: \(Int(metrics.heartRate)) BPM, Steps: \(metrics.steps), Sleep Quality: \(Int(metrics.sleepQuality * 100))%"
        attributeSet.keywords = ["health", "metrics", "heart rate", "steps", "sleep", "current"]
        attributeSet.thumbnailData = createHealthMetricsThumbnail()
        attributeSet.contentCreationDate = Date()
        attributeSet.contentModificationDate = Date()
        
        return attributeSet
    }
    
    private func createHealthTrendAttributeSet(_ trend: HealthTrend) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        
        attributeSet.title = "\(trend.metric) Trend"
        attributeSet.contentDescription = "Your \(trend.metric.lowercased()) has \(trend.direction.rawValue) by \(Int(trend.change))% over the past week"
        attributeSet.keywords = ["health", "trend", trend.metric.lowercased(), trend.direction.rawValue]
        attributeSet.thumbnailData = createTrendThumbnail(trend)
        attributeSet.contentCreationDate = trend.date
        
        return attributeSet
    }
    
    private func createSleepSessionAttributeSet(_ session: SleepSessionData) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        attributeSet.title = "Sleep Session - \(formatter.string(from: session.date))"
        attributeSet.contentDescription = "Duration: \(formatDuration(session.duration)), Quality: \(Int(session.quality * 100))%, Deep Sleep: \(Int(session.deepSleepPercentage * 100))%"
        attributeSet.keywords = ["sleep", "session", "duration", "quality", "deep sleep", "analysis"]
        attributeSet.thumbnailData = createSleepSessionThumbnail(session)
        attributeSet.contentCreationDate = session.date
        
        return attributeSet
    }
    
    private func createSleepAnalyticsAttributeSet(_ analytics: SleepAnalyticsData) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        
        attributeSet.title = "Sleep Analytics"
        attributeSet.contentDescription = "Average sleep quality: \(Int(analytics.averageQuality * 100))%, Sleep efficiency: \(Int(analytics.efficiency * 100))%"
        attributeSet.keywords = ["sleep", "analytics", "analysis", "efficiency", "quality", "patterns"]
        attributeSet.thumbnailData = createSleepAnalyticsThumbnail()
        attributeSet.contentCreationDate = Date()
        
        return attributeSet
    }
    
    private func createAIInsightAttributeSet(_ insight: AIInsightData) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        
        attributeSet.title = insight.title
        attributeSet.contentDescription = insight.description
        attributeSet.keywords = ["ai", "insight", "recommendation", "health", insight.category.lowercased()]
        attributeSet.thumbnailData = createAIInsightThumbnail(insight)
        attributeSet.contentCreationDate = insight.date
        
        return attributeSet
    }
    
    private func createPredictionAttributeSet(_ prediction: PredictionData) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        
        attributeSet.title = "Health Prediction: \(prediction.metric)"
        attributeSet.contentDescription = "AI predicts \(prediction.description) with \(Int(prediction.confidence * 100))% confidence"
        attributeSet.keywords = ["ai", "prediction", "forecast", "health", prediction.metric.lowercased()]
        attributeSet.thumbnailData = createPredictionThumbnail(prediction)
        attributeSet.contentCreationDate = prediction.date
        
        return attributeSet
    }
    
    private func createCoachingAttributeSet(_ recommendation: CoachingRecommendationData) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        
        attributeSet.title = recommendation.title
        attributeSet.contentDescription = recommendation.description
        attributeSet.keywords = ["coaching", "recommendation", "health", "ai", recommendation.category.lowercased()]
        attributeSet.thumbnailData = createCoachingThumbnail(recommendation)
        attributeSet.contentCreationDate = recommendation.date
        
        return attributeSet
    }
    
    private func createProgramAttributeSet(_ program: CoachingProgramData) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        
        attributeSet.title = program.name
        attributeSet.contentDescription = "\(program.description) - \(program.duration) day program"
        attributeSet.keywords = ["coaching", "program", "health", program.category.lowercased()]
        attributeSet.thumbnailData = createProgramThumbnail(program)
        attributeSet.contentCreationDate = program.startDate
        
        return attributeSet
    }
    
    private func createEnvironmentPresetAttributeSet(_ preset: EnvironmentPresetData) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        
        attributeSet.title = preset.name
        attributeSet.contentDescription = "Temperature: \(Int(preset.temperature))°F, Lighting: \(preset.lighting), Audio: \(preset.audio)"
        attributeSet.keywords = ["environment", "preset", "temperature", "lighting", "audio", preset.name.lowercased()]
        attributeSet.thumbnailData = createEnvironmentPresetThumbnail(preset)
        attributeSet.contentCreationDate = preset.createdDate
        
        return attributeSet
    }
    
    private func createEnvironmentStatusAttributeSet(_ status: EnvironmentStatusData) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        
        attributeSet.title = "Current Environment"
        attributeSet.contentDescription = "Temperature: \(Int(status.temperature))°F, Humidity: \(Int(status.humidity))%, Air Quality: \(status.airQuality)"
        attributeSet.keywords = ["environment", "current", "temperature", "humidity", "air quality"]
        attributeSet.thumbnailData = createEnvironmentStatusThumbnail()
        attributeSet.contentCreationDate = Date()
        
        return attributeSet
    }
    
    private func createEmergencyContactAttributeSet(_ contact: EmergencyContactData) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .contact)
        
        attributeSet.title = contact.name
        attributeSet.contentDescription = "\(contact.relationship) - \(contact.phone)"
        attributeSet.keywords = ["emergency", "contact", contact.name.lowercased(), contact.relationship.lowercased()]
        attributeSet.phoneNumbers = [contact.phone]
        attributeSet.contentCreationDate = contact.addedDate
        
        return attributeSet
    }
    
    private func createMedicalInfoAttributeSet(_ info: MedicalInformationData) -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .data)
        
        attributeSet.title = "Medical Information"
        attributeSet.contentDescription = "Blood Type: \(info.bloodType), Allergies: \(info.allergies.joined(separator: ", "))"
        attributeSet.keywords = ["medical", "information", "blood type", "allergies", "conditions"]
        attributeSet.contentCreationDate = info.lastUpdated
        
        return attributeSet
    }
    
    // MARK: - Index Management
    
    private func addItemsToIndex(_ items: [CSSearchableItem]) async {
        return await withCheckedContinuation { continuation in
            searchableIndex.indexSearchableItems(items) { error in
                if let error = error {
                    self.logger.error("Failed to index items: \(error)")
                } else {
                    self.logger.debug("Successfully indexed \(items.count) items")
                }
                continuation.resume()
            }
        }
    }
    
    func updateIndex() async {
        logger.info("Updating Spotlight index")
        await indexHealthData()
    }
    
    func clearIndex() async {
        logger.info("Clearing Spotlight index")
        
        return await withCheckedContinuation { continuation in
            searchableIndex.deleteAllSearchableItems { error in
                if let error = error {
                    self.logger.error("Failed to clear index: \(error)")
                } else {
                    self.logger.debug("Successfully cleared Spotlight index")
                }
                continuation.resume()
            }
        }
    }
    
    func deleteItems(withIdentifiers identifiers: [String]) async {
        return await withCheckedContinuation { continuation in
            searchableIndex.deleteSearchableItems(withIdentifiers: identifiers) { error in
                if let error = error {
                    self.logger.error("Failed to delete items: \(error)")
                } else {
                    self.logger.debug("Successfully deleted \(identifiers.count) items")
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Search Suggestions
    
    private func configureSearchSuggestions() async {
        logger.info("Configuring search suggestions")
        
        let suggestions = [
            "heart rate",
            "sleep quality",
            "steps today",
            "stress level",
            "AI recommendations",
            "coaching insights",
            "environment settings",
            "sleep analysis",
            "health trends",
            "emergency contacts"
        ]
        
        // This would configure search suggestions in the system
        // Implementation depends on available iOS 18 APIs
    }
    
    // MARK: - Search Handling
    
    private func setupSearchHandlers() {
        // Handle search queries and user interactions
        NotificationCenter.default.publisher(for: .spotlightSearchPerformed)
            .compactMap { $0.object as? String }
            .sink { [weak self] query in
                self?.recordSearchQuery(query)
            }
            .store(in: &cancellables)
    }
    
    private func recordSearchQuery(_ query: String) {
        let searchQuery = SearchQuery(
            query: query,
            timestamp: Date(),
            resultCount: 0 // Would be populated with actual results
        )
        
        searchQueries.append(searchQuery)
        logger.debug("Recorded search query: \(query)")
    }
    
    // MARK: - Continuous Indexing
    
    private func setupContinuousIndexing() {
        // Index new data as it becomes available
        Timer.publish(every: 3600, on: .main, in: .common) // Every hour
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.updateIndex()
                }
            }
            .store(in: &cancellables)
        
        // Listen for data updates
        NotificationCenter.default.publisher(for: .healthDataUpdated)
            .sink { [weak self] _ in
                Task {
                    await self?.indexLatestHealthData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func indexLatestHealthData() async {
        // Index only the latest health data without full reindex
        let latestMetrics = await getCurrentHealthMetrics()
        let attributeSet = createHealthMetricsAttributeSet(latestMetrics)
        
        let item = CSSearchableItem(
            uniqueIdentifier: "current_health_metrics",
            domainIdentifier: DomainIdentifiers.healthData,
            attributeSet: attributeSet
        )
        
        await addItemsToIndex([item])
    }
    
    // MARK: - Configuration
    
    private func setupSpotlightConfiguration() {
        // Configure Spotlight settings
        searchableIndex.indexDelegate = self
    }
    
    // MARK: - Helper Methods
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.indexingProgress = progress
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    // MARK: - Thumbnail Creation (Placeholder implementations)
    
    private func createHealthMetricsThumbnail() -> Data? {
        // Create thumbnail image for health metrics
        return nil
    }
    
    private func createTrendThumbnail(_ trend: HealthTrend) -> Data? {
        // Create thumbnail for health trend
        return nil
    }
    
    private func createSleepSessionThumbnail(_ session: SleepSessionData) -> Data? {
        // Create thumbnail for sleep session
        return nil
    }
    
    private func createSleepAnalyticsThumbnail() -> Data? {
        // Create thumbnail for sleep analytics
        return nil
    }
    
    private func createAIInsightThumbnail(_ insight: AIInsightData) -> Data? {
        // Create thumbnail for AI insight
        return nil
    }
    
    private func createPredictionThumbnail(_ prediction: PredictionData) -> Data? {
        // Create thumbnail for prediction
        return nil
    }
    
    private func createCoachingThumbnail(_ recommendation: CoachingRecommendationData) -> Data? {
        // Create thumbnail for coaching recommendation
        return nil
    }
    
    private func createProgramThumbnail(_ program: CoachingProgramData) -> Data? {
        // Create thumbnail for coaching program
        return nil
    }
    
    private func createEnvironmentPresetThumbnail(_ preset: EnvironmentPresetData) -> Data? {
        // Create thumbnail for environment preset
        return nil
    }
    
    private func createEnvironmentStatusThumbnail() -> Data? {
        // Create thumbnail for environment status
        return nil
    }
    
    // MARK: - Data Fetching (Placeholder implementations)
    
    private func getCurrentHealthMetrics() async -> HealthMetricsData {
        return HealthMetricsData(
            heartRate: 72.0,
            steps: 8456,
            sleepQuality: 0.85
        )
    }
    
    private func getHealthTrends() async -> [HealthTrend] {
        return [
            HealthTrend(metric: "Heart Rate", change: 5.0, direction: .up, date: Date()),
            HealthTrend(metric: "Sleep Quality", change: 10.0, direction: .up, date: Date()),
            HealthTrend(metric: "Stress Level", change: -15.0, direction: .down, date: Date())
        ]
    }
    
    private func getRecentSleepSessions() async -> [SleepSessionData] {
        return []
    }
    
    private func getSleepAnalytics() async -> SleepAnalyticsData {
        return SleepAnalyticsData(
            averageQuality: 0.82,
            efficiency: 0.88
        )
    }
    
    private func getAIInsights() async -> [AIInsightData] {
        return []
    }
    
    private func getPredictiveAnalytics() async -> [PredictionData] {
        return []
    }
    
    private func getCoachingRecommendations() async -> [CoachingRecommendationData] {
        return []
    }
    
    private func getCoachingPrograms() async -> [CoachingProgramData] {
        return []
    }
    
    private func getEnvironmentPresets() async -> [EnvironmentPresetData] {
        return []
    }
    
    private func getCurrentEnvironmentStatus() async -> EnvironmentStatusData {
        return EnvironmentStatusData(
            temperature: 72.0,
            humidity: 45.0,
            airQuality: "Good"
        )
    }
    
    private func getEmergencyContacts() async -> [EmergencyContactData] {
        return []
    }
    
    private func getMedicalInformation() async -> MedicalInformationData {
        return MedicalInformationData(
            bloodType: "O+",
            allergies: ["None"],
            lastUpdated: Date()
        )
    }
}

// MARK: - CSSearchableIndexDelegate

extension SpotlightManager: CSSearchableIndexDelegate {
    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
        Task {
            await indexHealthData()
            acknowledgementHandler()
        }
    }
    
    func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
        Task {
            // Reindex specific items
            await updateIndex()
            acknowledgementHandler()
        }
    }
}

// MARK: - Supporting Data Types

struct SpotlightItem {
    let identifier: String
    let title: String
    let description: String
    let category: String
    let indexDate: Date
}

struct SearchQuery {
    let query: String
    let timestamp: Date
    let resultCount: Int
}

struct HealthMetricsData {
    let heartRate: Double
    let steps: Int
    let sleepQuality: Double
}

struct HealthTrend {
    let metric: String
    let change: Double
    let direction: TrendDirection
    let date: Date
}

// TrendDirection is now defined in MetricTypes.swift

struct SleepSessionData {
    let id: String = UUID().uuidString
    let date: Date
    let duration: TimeInterval
    let quality: Double
    let deepSleepPercentage: Double
}

struct SleepAnalyticsData {
    let averageQuality: Double
    let efficiency: Double
}

struct AIInsightData {
    let id: String = UUID().uuidString
    let title: String
    let description: String
    let category: String
    let date: Date
}

struct PredictionData {
    let id: String = UUID().uuidString
    let metric: String
    let description: String
    let confidence: Double
    let date: Date
}

struct CoachingRecommendationData {
    let id: String = UUID().uuidString
    let title: String
    let description: String
    let category: String
    let date: Date
}

struct CoachingProgramData {
    let id: String = UUID().uuidString
    let name: String
    let description: String
    let category: String
    let duration: Int
    let startDate: Date
}

struct EnvironmentPresetData {
    let id: String = UUID().uuidString
    let name: String
    let temperature: Double
    let lighting: String
    let audio: String
    let createdDate: Date
}

struct EnvironmentStatusData {
    let temperature: Double
    let humidity: Double
    let airQuality: String
}

struct EmergencyContactData {
    let id: String = UUID().uuidString
    let name: String
    let relationship: String
    let phone: String
    let addedDate: Date
}

struct MedicalInformationData {
    let bloodType: String
    let allergies: [String]
    let lastUpdated: Date
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let spotlightSearchPerformed = Notification.Name("spotlightSearchPerformed")
}