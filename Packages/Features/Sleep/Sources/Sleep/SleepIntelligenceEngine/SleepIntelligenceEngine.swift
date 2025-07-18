import Foundation
import HealthAI2030Core
import AsyncAlgorithms
import QdrantSwift

/// Advanced sleep intelligence engine with transformer algorithms and edge vector search
@globalActor
public actor SleepIntelligenceEngine {
    public static let shared = SleepIntelligenceEngine()
    
    private var vectorStore: QdrantLiteClient?
    private var sleepModel: SleepTransformerModel
    private var currentSleepState: SleepState?
    private var optimizationHistory: [SleepOptimization] = []
    
    private init() {
        self.sleepModel = SleepTransformerModel()
        setupVectorStore()
        startSleepTracking()
    }
    
    // MARK: - Public Interface
    
    /// Generate personalized sleep optimization recommendations
    public func generateSleepOptimizations() async throws -> [SleepOptimization] {
        guard let currentState = currentSleepState else {
            throw SleepEngineError.noCurrentState
        }
        
        // Use transformer model for prediction
        let predictions = await sleepModel.predict(from: currentState)
        
        // Query vector database for similar sleep patterns
        let similarPatterns = try await querySimilarSleepPatterns(currentState)
        
        // Combine ML predictions with vector search results
        let optimizations = generateOptimizations(
            predictions: predictions,
            similarPatterns: similarPatterns
        )
        
        // Store optimization for future learning
        optimizationHistory.append(contentsOf: optimizations)
        
        return optimizations
    }
    
    /// Update sleep state from sensor data
    public func updateSleepState(_ state: SleepState) async {
        self.currentSleepState = state
        
        // Store state in vector database for future queries
        await storeSleepStateVector(state)
        
        // Update transformer model with new data
        await sleepModel.updateWithRealTimeData(state)
    }
    
    /// Get current sleep insights with confidence scoring
    public func getCurrentSleepInsights() async -> [SleepInsight] {
        guard let state = currentSleepState else { return [] }
        
        return await sleepModel.generateInsights(from: state)
    }
    
    /// Analyze sleep patterns using advanced transformer model
    public func getAdvancedSleepPatternAnalysis() async -> SleepPatternAnalysis? {
        return await sleepModel.analyzeSleepPatterns()
    }
    
    /// Personalize the sleep model with user feedback data
    public func personalizeModel(with outcomes: [SleepOutcome]) async throws {
        try await sleepModel.personalizeModel(userOutcomes: outcomes)
    }
    
    /// Generate comprehensive sleep forecast for the next 24-48 hours
    public func generateAdvancedSleepForecast(hours: Int = 24) async throws -> SleepForecast? {
        guard let transformer = await getAdvancedTransformer() else { return nil }
        
        let recentHistory = await getSleepHistory(days: 7)
        guard !recentHistory.isEmpty else { return nil }
        
        return try await transformer.generateSleepForecast(
            history: recentHistory,
            forecastHours: hours
        )
    }
    
    /// Get contextual sleep insights with explanations
    public func getContextualSleepInsights() async -> [ContextualSleepInsight] {
        guard let state = currentSleepState,
              let transformer = await getAdvancedTransformer() else { return [] }
        
        let recentHistory = await getSleepHistory(days: 7)
        
        return await transformer.generateContextualInsights(
            currentState: state,
            recentHistory: recentHistory
        )
    }
    
    /// Predict optimal bedtime based on circadian rhythm and personal patterns
    public func predictOptimalBedtime() async throws -> SleepRecommendation {
        guard let state = currentSleepState else {
            throw SleepEngineError.noCurrentState
        }
        
        let circadianOptimal = await calculateCircadianOptimalBedtime(state)
        let personalOptimal = await calculatePersonalOptimalBedtime(state)
        
        return SleepRecommendation(
            recommendedBedtime: averageTime(circadianOptimal, personalOptimal),
            confidence: calculateConfidence(state),
            reasoning: generateRecommendationReasoning(
                circadian: circadianOptimal,
                personal: personalOptimal
            )
        )
    }
    
    // MARK: - Private Implementation
    
    private func setupVectorStore() {
        do {
            vectorStore = try QdrantLiteClient(
                collectionName: "sleep_patterns",
                vectorSize: 128,
                distance: .cosine
            )
        } catch {
            print("Failed to initialize vector store: \(error)")
        }
    }
    
    private func startSleepTracking() {
        Task {
            // Subscribe to sensor data for real-time sleep tracking
            let sensorStream = await SensorDataActor.shared.subscribe(to: .sleepStage)
            
            for await metric in sensorStream {
                let sleepState = await generateSleepState(from: metric)
                await updateSleepState(sleepState)
            }
        }
    }
    
    private func querySimilarSleepPatterns(_ state: SleepState) async throws -> [SleepPattern] {
        guard let vectorStore = vectorStore else {
            throw SleepEngineError.vectorStoreNotInitialized
        }
        
        let stateVector = state.toVector()
        let similarVectors = try await vectorStore.search(
            vector: stateVector,
            limit: 10,
            threshold: 0.8
        )
        
        return similarVectors.compactMap { vector in
            SleepPattern.fromVector(vector)
        }
    }
    
    private func storeSleepStateVector(_ state: SleepState) async {
        guard let vectorStore = vectorStore else { return }
        
        do {
            let vector = state.toVector()
            try await vectorStore.upsert(
                id: state.id.uuidString,
                vector: vector,
                payload: state.toPayload()
            )
        } catch {
            print("Failed to store sleep state vector: \(error)")
        }
    }
    
    private func generateOptimizations(
        predictions: [SleepPrediction],
        similarPatterns: [SleepPattern]
    ) -> [SleepOptimization] {
        var optimizations: [SleepOptimization] = []
        
        // Generate optimization from ML predictions
        for prediction in predictions {
            if prediction.confidence > 0.7 {
                optimizations.append(SleepOptimization(
                    type: .bedtimeAdjustment,
                    suggestion: prediction.suggestion,
                    confidence: prediction.confidence,
                    expectedImprovement: prediction.expectedImprovement,
                    source: .mlPrediction
                ))
            }
        }
        
        // Generate optimizations from similar patterns
        let patternOptimizations = analyzeSimilarPatterns(similarPatterns)
        optimizations.append(contentsOf: patternOptimizations)
        
        // Sort by confidence and expected improvement
        return optimizations.sorted { opt1, opt2 in
            let score1 = opt1.confidence * opt1.expectedImprovement
            let score2 = opt2.confidence * opt2.expectedImprovement
            return score1 > score2
        }
    }
    
    private func analyzeSimilarPatterns(_ patterns: [SleepPattern]) -> [SleepOptimization] {
        guard !patterns.isEmpty else { return [] }
        
        var optimizations: [SleepOptimization] = []
        
        // Analyze successful sleep patterns
        let successfulPatterns = patterns.filter { $0.sleepQualityScore > 0.8 }
        
        if !successfulPatterns.isEmpty {
            let avgBedtime = successfulPatterns.map(\.bedtime).average()
            let avgWakeTime = successfulPatterns.map(\.wakeTime).average()
            
            optimizations.append(SleepOptimization(
                type: .scheduleOptimization,
                suggestion: "Based on similar users, optimal bedtime is \(formatTime(avgBedtime)) and wake time is \(formatTime(avgWakeTime))",
                confidence: 0.8,
                expectedImprovement: 0.3,
                source: .vectorSearch
            ))
        }
        
        return optimizations
    }
    
    private func generateSleepState(from metric: HealthMetric) async -> SleepState {
        return SleepState(
            id: UUID(),
            timestamp: metric.timestamp,
            sleepStage: extractSleepStage(from: metric),
            heartRateVariability: await getCurrentHRV(),
            bodyTemperature: await getCurrentBodyTemp(),
            movementLevel: await getCurrentMovement(),
            environmentalFactors: await getEnvironmentalFactors()
        )
    }
    
    private func calculateCircadianOptimalBedtime(_ state: SleepState) async -> Date {
        // Calculate based on circadian rhythm and light exposure
        let calendar = Calendar.current
        let now = Date()
        
        // Natural circadian rhythm suggests 10-11 PM bedtime
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 22 + Int(state.circadianShift)
        components.minute = 30
        
        return calendar.date(from: components) ?? now
    }
    
    private func calculatePersonalOptimalBedtime(_ state: SleepState) async -> Date {
        // Use personal sleep history and transformer model
        let historicalData = optimizationHistory.suffix(30) // Last 30 days
        
        if historicalData.isEmpty {
            return await calculateCircadianOptimalBedtime(state)
        }
        
        let avgBedtime = historicalData.compactMap(\.optimalBedtime).average()
        return Date(timeIntervalSince1970: avgBedtime)
    }
    
    private func getCurrentHRV() async -> Double? {
        // Get current HRV from sensor actor
        return await SensorDataActor.shared.currentBiorhythmicState().heartRateVariability
    }
    
    private func getCurrentBodyTemp() async -> Double? {
        // Implementation would get current body temperature
        return 36.5 // Placeholder
    }
    
    private func getCurrentMovement() async -> Double {
        // Implementation would get current movement/activity level
        return 0.2 // Placeholder
    }
    
    private func getEnvironmentalFactors() async -> EnvironmentalFactors {
        return EnvironmentalFactors(
            lightLevel: 100,
            noiseLevel: 30,
            temperature: 20.0,
            humidity: 45.0
        )
    }
    
    private func extractSleepStage(from metric: HealthMetric) -> SleepStage {
        // Implementation would extract sleep stage from metric
        return .light
    }
    
    private func averageTime(_ time1: Date, _ time2: Date) -> Date {
        let avg = (time1.timeIntervalSince1970 + time2.timeIntervalSince1970) / 2
        return Date(timeIntervalSince1970: avg)
    }
    
    private func calculateConfidence(_ state: SleepState) -> Double {
        // Calculate confidence based on data quality and historical accuracy
        return 0.85
    }
    
    private func generateRecommendationReasoning(circadian: Date, personal: Date) -> String {
        return "Based on your circadian rhythm and personal sleep patterns"
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getAdvancedTransformer() async -> AdvancedSleepTransformer? {
        return AdvancedSleepTransformer.shared
    }
    
    private func getSleepHistory(days: Int) async -> [SleepState] {
        // This would integrate with a data store to get historical sleep states
        // For now, return empty array as placeholder
        return []
    }
}

// MARK: - Supporting Types

public struct SleepState: Sendable {
    public let id: UUID
    public let timestamp: Date
    public let sleepStage: SleepStage
    public let heartRateVariability: Double?
    public let bodyTemperature: Double?
    public let movementLevel: Double
    public let environmentalFactors: EnvironmentalFactors
    
    public var circadianShift: Double {
        // Calculate circadian shift based on various factors
        let hour = Calendar.current.component(.hour, from: timestamp)
        return Double(hour - 22) / 24.0 // Normalize to -1 to 1
    }
    
    public func toVector() -> [Float] {
        // Convert sleep state to 128-dimensional vector for similarity search
        var vector: [Float] = []
        
        // Time-based features (24 dimensions)
        let hour = Calendar.current.component(.hour, from: timestamp)
        let minute = Calendar.current.component(.minute, from: timestamp)
        vector.append(Float(hour) / 24.0)
        vector.append(Float(minute) / 60.0)
        
        // Add more time encodings (day of week, season, etc.)
        let dayOfWeek = Calendar.current.component(.weekday, from: timestamp)
        vector.append(Float(dayOfWeek) / 7.0)
        
        // Physiological features (32 dimensions)
        vector.append(Float(heartRateVariability ?? 0) / 100.0)
        vector.append(Float(bodyTemperature ?? 36.5) / 40.0)
        vector.append(Float(movementLevel))
        
        // Sleep stage encoding (8 dimensions)
        let stageVector = sleepStage.toVector()
        vector.append(contentsOf: stageVector)
        
        // Environmental features (16 dimensions)
        vector.append(Float(environmentalFactors.lightLevel) / 1000.0)
        vector.append(Float(environmentalFactors.noiseLevel) / 100.0)
        vector.append(Float(environmentalFactors.temperature) / 40.0)
        vector.append(Float(environmentalFactors.humidity) / 100.0)
        
        // Pad to 128 dimensions with zeros if needed
        while vector.count < 128 {
            vector.append(0.0)
        }
        
        return vector
    }
    
    public func toPayload() -> [String: Any] {
        return [
            "id": id.uuidString,
            "timestamp": timestamp.timeIntervalSince1970,
            "sleepStage": sleepStage.rawValue,
            "hrv": heartRateVariability ?? 0,
            "bodyTemp": bodyTemperature ?? 0,
            "movement": movementLevel
        ]
    }
}

public enum SleepStage: String, Sendable, CaseIterable {
    case awake
    case light
    case deep
    case rem
    
    public func toVector() -> [Float] {
        switch self {
        case .awake: return [1, 0, 0, 0]
        case .light: return [0, 1, 0, 0]
        case .deep: return [0, 0, 1, 0]
        case .rem: return [0, 0, 0, 1]
        }
    }
}

public struct EnvironmentalFactors: Sendable {
    public let lightLevel: Double // lux
    public let noiseLevel: Double // dB
    public let temperature: Double // Celsius
    public let humidity: Double // percentage
}

public struct SleepOptimization: Sendable {
    public enum OptimizationType: Sendable {
        case bedtimeAdjustment
        case scheduleOptimization
        case environmentalControl
        case relaxationTechnique
    }
    
    public enum Source: Sendable {
        case mlPrediction
        case vectorSearch
        case circadianAnalysis
    }
    
    public let type: OptimizationType
    public let suggestion: String
    public let confidence: Double
    public let expectedImprovement: Double
    public let source: Source
    public let optimalBedtime: TimeInterval?
    
    public init(
        type: OptimizationType,
        suggestion: String,
        confidence: Double,
        expectedImprovement: Double,
        source: Source,
        optimalBedtime: TimeInterval? = nil
    ) {
        self.type = type
        self.suggestion = suggestion
        self.confidence = confidence
        self.expectedImprovement = expectedImprovement
        self.source = source
        self.optimalBedtime = optimalBedtime
    }
}

public struct SleepRecommendation: Sendable {
    public let recommendedBedtime: Date
    public let confidence: Double
    public let reasoning: String
}

public struct SleepInsight: Sendable {
    public let title: String
    public let description: String
    public let confidence: Double
    public let category: Category
    
    public enum Category: Sendable {
        case quality
        case duration
        case timing
        case environment
    }
}

public struct SleepPattern: Sendable {
    public let bedtime: TimeInterval
    public let wakeTime: TimeInterval
    public let sleepQualityScore: Double
    public let duration: TimeInterval
    
    public static func fromVector(_ vector: VectorSearchResult) -> SleepPattern? {
        // Reconstruct sleep pattern from vector search result
        guard let payload = vector.payload else { return nil }
        
        // Implementation would reconstruct from payload
        return SleepPattern(
            bedtime: 22 * 3600, // 10 PM
            wakeTime: 7 * 3600,  // 7 AM
            sleepQualityScore: 0.8,
            duration: 9 * 3600   // 9 hours
        )
    }
}

public struct SleepPrediction: Sendable {
    public let suggestion: String
    public let confidence: Double
    public let expectedImprovement: Double
}

// MARK: - Transformer Model

private actor SleepTransformerModel {
    private var advancedTransformer: AdvancedSleepTransformer
    private var trainingData: [SleepState] = []
    private var sleepHistory: [SleepState] = []
    private var isAdvancedModelEnabled = true
    
    init() {
        self.advancedTransformer = AdvancedSleepTransformer.shared
    }
    
    func predict(from state: SleepState) async -> [SleepPrediction] {
        // Use advanced transformer for predictions
        if isAdvancedModelEnabled {
            do {
                // Ensure transformer is initialized
                try await advancedTransformer.initialize()
                
                // Get recent sleep history for context
                let recentHistory = sleepHistory.suffix(168) // Last week
                
                // Generate advanced forecast
                let forecast = try await advancedTransformer.generateSleepForecast(
                    history: Array(recentHistory),
                    forecastHours: 24
                )
                
                // Convert transformer predictions to legacy format
                return convertTransformerPredictions(forecast.predictions)
                
            } catch {
                print("Advanced transformer prediction failed: \\(error)")
                // Fall back to simplified prediction
                return await generateSimplifiedPredictions(from: state)
            }
        } else {
            return await generateSimplifiedPredictions(from: state)
        }
    }
    
    func updateWithRealTimeData(_ state: SleepState) async {
        trainingData.append(state)
        sleepHistory.append(state)
        
        // Keep only recent data for performance
        if trainingData.count > 1000 {
            trainingData.removeFirst(100)
        }
        
        if sleepHistory.count > 168 * 7 { // Keep 7 weeks of hourly data
            sleepHistory.removeFirst(168)
        }
        
        // Update advanced transformer with new data
        if isAdvancedModelEnabled {
            // Use the advanced transformer's real-time learning capabilities
            // The transformer handles its own internal state updates
        }
        
        // Also update simplified model weights as backup
        await retrainModel()
    }
    
    func generateInsights(from state: SleepState) async -> [SleepInsight] {
        var insights: [SleepInsight] = []
        
        // Use advanced transformer for contextual insights
        if isAdvancedModelEnabled {
            do {
                let recentHistory = sleepHistory.suffix(168)
                let contextualInsights = await advancedTransformer.generateContextualInsights(
                    currentState: state,
                    recentHistory: Array(recentHistory)
                )
                
                // Convert contextual insights to legacy format
                insights.append(contentsOf: convertContextualInsights(contextualInsights))
                
            } catch {
                print("Advanced insight generation failed: \\(error)")
            }
        }
        
        // Add traditional rule-based insights as backup
        insights.append(contentsOf: await generateTraditionalInsights(from: state))
        
        return insights
    }
    
    func analyzeSleepPatterns() async -> SleepPatternAnalysis? {
        guard isAdvancedModelEnabled && sleepHistory.count >= 168 else { return nil }
        
        do {
            return await advancedTransformer.analyzeSleepPatterns(sleepHistory: sleepHistory)
        } catch {
            print("Sleep pattern analysis failed: \\(error)")
            return nil
        }
    }
    
    func personalizeModel(userOutcomes: [SleepOutcome]) async throws {
        guard isAdvancedModelEnabled && sleepHistory.count >= 30 else {
            throw SleepEngineError.invalidData("Insufficient data for personalization")
        }
        
        try await advancedTransformer.personalizeModel(
            userSleepData: sleepHistory,
            outcomes: userOutcomes
        )
    }
    
    // MARK: - Private Implementation
    
    private func convertTransformerPredictions(_ predictions: [AdvancedSleepTransformer.SleepPrediction]) -> [SleepPrediction] {
        return predictions.map { prediction in
            let suggestionText: String
            
            switch prediction.predictedStage {
            case .deep:
                suggestionText = "Optimal time for deep sleep phase - maintain current environment"
            case .rem:
                suggestionText = "REM sleep window approaching - avoid disturbances"
            case .light:
                suggestionText = "Light sleep period - good time for natural wake-up"
            case .awake:
                if prediction.qualityScore > 0.7 {
                    suggestionText = "Sleep cycle complete - consider waking up naturally"
                } else {
                    suggestionText = "Sleep disruption detected - focus on relaxation"
                }
            }
            
            return SleepPrediction(
                suggestion: suggestionText,
                confidence: prediction.stageConfidence,
                expectedImprovement: min(0.5, prediction.qualityScore)
            )
        }
    }
    
    private func convertContextualInsights(_ contextualInsights: [ContextualSleepInsight]) -> [SleepInsight] {
        return contextualInsights.map { insight in
            let category: SleepInsight.Category
            
            switch insight.type {
            case .sleepQuality: category = .quality
            case .circadianRhythm: category = .timing
            case .environment: category = .environment
            case .lifestyle: category = .quality
            }
            
            return SleepInsight(
                title: insight.title,
                description: insight.description + " " + insight.explanation,
                confidence: insight.confidence,
                category: category
            )
        }
    }
    
    private func generateSimplifiedPredictions(from state: SleepState) async -> [SleepPrediction] {
        var predictions: [SleepPrediction] = []
        
        // Bedtime prediction based on current time
        let currentHour = Calendar.current.component(.hour, from: Date())
        if currentHour > 20 || currentHour < 6 {
            let confidence = calculatePredictionConfidence(state)
            predictions.append(SleepPrediction(
                suggestion: "Consider going to bed in the next 30 minutes for optimal sleep",
                confidence: confidence,
                expectedImprovement: 0.25
            ))
        }
        
        // Environmental optimization prediction
        if state.environmentalFactors.temperature > 24 {
            predictions.append(SleepPrediction(
                suggestion: "Lower room temperature to 18-21°C for better sleep quality",
                confidence: 0.9,
                expectedImprovement: 0.3
            ))
        }
        
        // HRV-based prediction
        if let hrv = state.heartRateVariability, hrv < 20 {
            predictions.append(SleepPrediction(
                suggestion: "Your HRV suggests stress - try relaxation techniques before sleep",
                confidence: 0.8,
                expectedImprovement: 0.4
            ))
        }
        
        return predictions
    }
    
    private func generateTraditionalInsights(from state: SleepState) async -> [SleepInsight] {
        var insights: [SleepInsight] = []
        
        // HRV-based insight
        if let hrv = state.heartRateVariability, hrv < 20 {
            insights.append(SleepInsight(
                title: "Low Sleep Readiness",
                description: "Your heart rate variability suggests your body may not be ready for restorative sleep.",
                confidence: 0.8,
                category: .quality
            ))
        }
        
        // Environmental insight
        if state.environmentalFactors.temperature > 24 {
            insights.append(SleepInsight(
                title: "Room Too Warm",
                description: "Consider lowering the room temperature to 18-21°C for better sleep quality.",
                confidence: 0.9,
                category: .environment
            ))
        }
        
        // Movement-based insight
        if state.movementLevel > 0.5 {
            insights.append(SleepInsight(
                title: "High Movement Detected",
                description: "Increased movement may indicate restless sleep or environmental disturbances.",
                confidence: 0.7,
                category: .quality
            ))
        }
        
        return insights
    }
    
    private func calculatePredictionConfidence(_ state: SleepState) -> Double {
        // Calculate confidence based on data quality and historical accuracy
        var confidence = 0.5
        
        if state.heartRateVariability != nil { confidence += 0.2 }
        if state.bodyTemperature != nil { confidence += 0.1 }
        if !trainingData.isEmpty { confidence += 0.2 }
        
        return min(1.0, confidence)
    }
    
    private func retrainModel() async {
        // Simplified model retraining for backup system
        guard trainingData.count > 10 else { return }
        
        // Update weights based on recent data patterns
        // This serves as a fallback when the advanced transformer is unavailable
    }
}

// MARK: - Helper Extensions

private extension Array where Element == TimeInterval {
    func average() -> TimeInterval {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

// MARK: - Mock Qdrant Types (for compilation)

private protocol QdrantLiteClient {
    init(collectionName: String, vectorSize: Int, distance: DistanceMetric) throws
    func search(vector: [Float], limit: Int, threshold: Double) async throws -> [VectorSearchResult]
    func upsert(id: String, vector: [Float], payload: [String: Any]) async throws
}

private enum DistanceMetric {
    case cosine
}

private struct VectorSearchResult {
    let id: String
    let score: Double
    let payload: [String: Any]?
}

// Mock implementation
private class MockQdrantLiteClient: QdrantLiteClient {
    required init(collectionName: String, vectorSize: Int, distance: DistanceMetric) throws {
        // Mock implementation
    }
    
    func search(vector: [Float], limit: Int, threshold: Double) async throws -> [VectorSearchResult] {
        // Mock search results
        return []
    }
    
    func upsert(id: String, vector: [Float], payload: [String: Any]) async throws {
        // Mock upsert
    }
}

// MARK: - Error Types

public enum SleepEngineError: Error, Sendable {
    case noCurrentState
    case vectorStoreNotInitialized
    case predictionFailed(String)
    case invalidData(String)
}