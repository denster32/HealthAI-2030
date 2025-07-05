import Foundation
import SwiftUI
import Combine

// MARK: - HealthAI Core Service

/// Main HealthAI service that orchestrates all health-related functionality
public class HealthAICoreService: BaseHealthAIService {
    
    // MARK: - Dependencies
    private let dataProcessor: HealthDataProcessorProtocol
    private let predictionService: HealthPredictionServiceProtocol
    private let analyticsService: HealthAnalyticsServiceProtocol
    private let storageService: HealthStorageServiceProtocol
    
    // MARK: - Published Properties
    @Published public var currentHealthStatus: HealthStatus = .unknown
    @Published public var recentInsights: [HealthInsight] = []
    @Published public var healthMetrics: HealthMetrics = HealthMetrics()
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let healthUpdateTimer: Timer?
    
    // MARK: - Initialization
    
    public init(
        dataProcessor: HealthDataProcessorProtocol,
        predictionService: HealthPredictionServiceProtocol,
        analyticsService: HealthAnalyticsServiceProtocol,
        storageService: HealthStorageServiceProtocol
    ) {
        self.dataProcessor = dataProcessor
        self.predictionService = predictionService
        self.analyticsService = analyticsService
        self.storageService = storageService
        
        super.init(serviceIdentifier: "HealthAICore")
        
        setupBindings()
        startHealthMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Processes new health data and updates insights
    public func processHealthData(_ data: HealthData) async throws {
        let processedData = try await dataProcessor.process(data)
        try await storageService.store(processedData)
        
        let insights = try await generateInsights(from: processedData)
        await updateInsights(insights)
        
        let predictions = try await predictionService.predict(processedData)
        await updatePredictions(predictions)
    }
    
    /// Generates health insights from current data
    public func generateInsights(from data: ProcessedHealthData) async throws -> [HealthInsight] {
        let insights = try await analyticsService.generateInsights(from: data)
        return insights.map { HealthInsight(from: $0) }
    }
    
    /// Gets health recommendations based on current status
    public func getRecommendations() async throws -> [HealthRecommendation] {
        let recommendations = try await predictionService.getRecommendations()
        return recommendations.map { HealthRecommendation(from: $0) }
    }
    
    /// Updates health status based on latest data
    public func updateHealthStatus() async throws {
        let latestData = try await storageService.getLatestData()
        let status = try await calculateHealthStatus(from: latestData)
        await updateStatus(status)
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Setup reactive bindings between services
        dataProcessor.dataProcessedPublisher
            .sink { [weak self] data in
                Task {
                    try await self?.handleProcessedData(data)
                }
            }
            .store(in: &cancellables)
        
        predictionService.predictionUpdatedPublisher
            .sink { [weak self] prediction in
                Task {
                    await self?.handlePredictionUpdate(prediction)
                }
            }
            .store(in: &cancellables)
    }
    
    private func startHealthMonitoring() {
        // Start periodic health monitoring
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                try await self?.updateHealthStatus()
            }
        }
    }
    
    private func handleProcessedData(_ data: ProcessedHealthData) async throws {
        try await storageService.store(data)
        let insights = try await generateInsights(from: data)
        await updateInsights(insights)
    }
    
    private func handlePredictionUpdate(_ prediction: HealthPrediction) async {
        await updatePredictions([prediction])
    }
    
    @MainActor
    private func updateInsights(_ insights: [HealthInsight]) {
        recentInsights = insights
    }
    
    @MainActor
    private func updatePredictions(_ predictions: [HealthPrediction]) {
        // Update predictions in UI
    }
    
    @MainActor
    private func updateStatus(_ status: HealthStatus) {
        currentHealthStatus = status
    }
    
    private func calculateHealthStatus(from data: ProcessedHealthData) async throws -> HealthStatus {
        // Calculate overall health status based on various metrics
        let metrics = data.metrics
        let score = calculateHealthScore(metrics)
        
        switch score {
        case 0.8...1.0:
            return .excellent
        case 0.6..<0.8:
            return .good
        case 0.4..<0.6:
            return .fair
        case 0.2..<0.4:
            return .poor
        default:
            return .critical
        }
    }
    
    private func calculateHealthScore(_ metrics: HealthMetrics) -> Double {
        // Calculate weighted health score based on various metrics
        var score = 0.0
        var totalWeight = 0.0
        
        // Heart rate score
        if let heartRate = metrics.heartRate {
            let heartRateScore = calculateHeartRateScore(heartRate)
            score += heartRateScore * 0.3
            totalWeight += 0.3
        }
        
        // Sleep score
        if let sleepHours = metrics.sleepHours {
            let sleepScore = calculateSleepScore(sleepHours)
            score += sleepScore * 0.25
            totalWeight += 0.25
        }
        
        // Activity score
        if let steps = metrics.dailySteps {
            let activityScore = calculateActivityScore(steps)
            score += activityScore * 0.25
            totalWeight += 0.25
        }
        
        // Nutrition score
        if let waterIntake = metrics.waterIntake {
            let nutritionScore = calculateNutritionScore(waterIntake)
            score += nutritionScore * 0.2
            totalWeight += 0.2
        }
        
        return totalWeight > 0 ? score / totalWeight : 0.0
    }
    
    private func calculateHeartRateScore(_ heartRate: Int) -> Double {
        // Normal resting heart rate is 60-100 BPM
        if heartRate >= 60 && heartRate <= 100 {
            return 1.0
        } else if heartRate >= 50 && heartRate <= 110 {
            return 0.8
        } else if heartRate >= 40 && heartRate <= 120 {
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func calculateSleepScore(_ hours: Double) -> Double {
        // Optimal sleep is 7-9 hours
        if hours >= 7.0 && hours <= 9.0 {
            return 1.0
        } else if hours >= 6.0 && hours <= 10.0 {
            return 0.8
        } else if hours >= 5.0 && hours <= 11.0 {
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func calculateActivityScore(_ steps: Int) -> Double {
        // Target is 10,000 steps per day
        if steps >= 10000 {
            return 1.0
        } else if steps >= 8000 {
            return 0.9
        } else if steps >= 6000 {
            return 0.7
        } else if steps >= 4000 {
            return 0.5
        } else {
            return 0.3
        }
    }
    
    private func calculateNutritionScore(_ waterIntake: Double) -> Double {
        // Target is 2-3 liters per day
        if waterIntake >= 2.0 && waterIntake <= 3.0 {
            return 1.0
        } else if waterIntake >= 1.5 && waterIntake <= 3.5 {
            return 0.8
        } else if waterIntake >= 1.0 && waterIntake <= 4.0 {
            return 0.6
        } else {
            return 0.3
        }
    }
}

// MARK: - Supporting Protocols

public protocol HealthDataProcessorProtocol: DataProcessorProtocol where InputType == HealthData, OutputType == ProcessedHealthData {
    var dataProcessedPublisher: AnyPublisher<ProcessedHealthData, Never> { get }
}

public protocol HealthPredictionServiceProtocol: PredictionServiceProtocol where PredictionInput == ProcessedHealthData, PredictionOutput == HealthPrediction {
    var predictionUpdatedPublisher: AnyPublisher<HealthPrediction, Never> { get }
    func getRecommendations() async throws -> [PredictionRecommendation]
}

public protocol HealthAnalyticsServiceProtocol: AnalyticsServiceProtocol {
    func generateInsights(from data: ProcessedHealthData) async throws -> [AnalyticsInsight]
}

public protocol HealthStorageServiceProtocol: DataStorageProtocol where DataType == ProcessedHealthData {
    func getLatestData() async throws -> ProcessedHealthData
}

// MARK: - Data Models

public enum HealthStatus: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case critical = "Critical"
    case unknown = "Unknown"
    
    public var color: Color {
        switch self {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .yellow
        case .poor:
            return .orange
        case .critical:
            return .red
        case .unknown:
            return .gray
        }
    }
}

public struct HealthData: Codable {
    public let timestamp: Date
    public let heartRate: Int?
    public let bloodPressure: BloodPressure?
    public let temperature: Double?
    public let steps: Int?
    public let sleepHours: Double?
    public let waterIntake: Double?
    public let calories: Int?
    public let mood: Mood?
    
    public init(
        timestamp: Date = Date(),
        heartRate: Int? = nil,
        bloodPressure: BloodPressure? = nil,
        temperature: Double? = nil,
        steps: Int? = nil,
        sleepHours: Double? = nil,
        waterIntake: Double? = nil,
        calories: Int? = nil,
        mood: Mood? = nil
    ) {
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.bloodPressure = bloodPressure
        self.temperature = temperature
        self.steps = steps
        self.sleepHours = sleepHours
        self.waterIntake = waterIntake
        self.calories = calories
        self.mood = mood
    }
}

public struct ProcessedHealthData: Codable {
    public let originalData: HealthData
    public let metrics: HealthMetrics
    public let processedAt: Date
    public let quality: DataQuality
    
    public init(originalData: HealthData, metrics: HealthMetrics, processedAt: Date = Date(), quality: DataQuality) {
        self.originalData = originalData
        self.metrics = metrics
        self.processedAt = processedAt
        self.quality = quality
    }
}

public struct HealthMetrics: Codable {
    public var heartRate: Int?
    public var bloodPressure: BloodPressure?
    public var temperature: Double?
    public var dailySteps: Int?
    public var sleepHours: Double?
    public var waterIntake: Double?
    public var calories: Int?
    public var mood: Mood?
    public var healthScore: Double?
    
    public init() {}
}

public struct BloodPressure: Codable {
    public let systolic: Int
    public let diastolic: Int
    
    public init(systolic: Int, diastolic: Int) {
        self.systolic = systolic
        self.diastolic = diastolic
    }
}

public enum Mood: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case okay = "Okay"
    case poor = "Poor"
    case terrible = "Terrible"
}

public enum DataQuality: String, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

public struct HealthInsight: Identifiable, Codable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let category: InsightCategory
    public let severity: InsightSeverity
    public let actionable: Bool
    public let timestamp: Date
    
    public init(title: String, description: String, category: InsightCategory, severity: InsightSeverity, actionable: Bool, timestamp: Date = Date()) {
        self.title = title
        self.description = description
        self.category = category
        self.severity = severity
        self.actionable = actionable
        self.timestamp = timestamp
    }
    
    public init(from analyticsInsight: AnalyticsInsight) {
        self.title = analyticsInsight.title
        self.description = analyticsInsight.description
        self.category = .general
        self.severity = analyticsInsight.confidence > 0.8 ? .high : analyticsInsight.confidence > 0.5 ? .medium : .low
        self.actionable = analyticsInsight.actionable
        self.timestamp = Date()
    }
}

public enum InsightCategory: String, CaseIterable, Codable {
    case general = "General"
    case cardiovascular = "Cardiovascular"
    case sleep = "Sleep"
    case activity = "Activity"
    case nutrition = "Nutrition"
    case mental = "Mental"
}

public enum InsightSeverity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

public struct HealthPrediction: Identifiable, Codable {
    public let id = UUID()
    public let type: PredictionType
    public let value: Double
    public let confidence: Double
    public let timeframe: TimeInterval
    public let timestamp: Date
    
    public init(type: PredictionType, value: Double, confidence: Double, timeframe: TimeInterval, timestamp: Date = Date()) {
        self.type = type
        self.value = value
        self.confidence = confidence
        self.timeframe = timeframe
        self.timestamp = timestamp
    }
}

public enum PredictionType: String, CaseIterable, Codable {
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case sleepQuality = "Sleep Quality"
    case activityLevel = "Activity Level"
    case stressLevel = "Stress Level"
    case healthRisk = "Health Risk"
}

public struct HealthRecommendation: Identifiable, Codable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let category: RecommendationCategory
    public let priority: RecommendationPriority
    public let actionable: Bool
    public let estimatedImpact: Double
    
    public init(title: String, description: String, category: RecommendationCategory, priority: RecommendationPriority, actionable: Bool, estimatedImpact: Double) {
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.actionable = actionable
        self.estimatedImpact = estimatedImpact
    }
    
    public init(from predictionRecommendation: PredictionRecommendation) {
        self.title = predictionRecommendation.title
        self.description = predictionRecommendation.description
        self.category = .general
        self.priority = predictionRecommendation.priority > 0.8 ? .high : predictionRecommendation.priority > 0.5 ? .medium : .low
        self.actionable = true
        self.estimatedImpact = predictionRecommendation.priority
    }
}

public enum RecommendationCategory: String, CaseIterable, Codable {
    case general = "General"
    case exercise = "Exercise"
    case nutrition = "Nutrition"
    case sleep = "Sleep"
    case stress = "Stress"
    case medical = "Medical"
}

public enum RecommendationPriority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
}

// MARK: - Supporting Types

public struct PredictionRecommendation {
    public let title: String
    public let description: String
    public let priority: Double
} 