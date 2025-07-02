import Foundation
import HealthKit
import Combine

/// Advanced sleep analytics engine
/// Provides deep analysis of sleep patterns, quality trends, and optimization opportunities
class SleepAnalyticsEngine: AnalyticsEngine {
    // MARK: - Published Properties
    @Published var sleepQualityScore: Double = 0.0
    @Published var sleepEfficiency: Double = 0.0
    @Published var sleepLatency: Double = 0.0
    @Published var remSleepPercentage: Double = 0.0
    @Published var deepSleepPercentage: Double = 0.0
    @Published var sleepTrends: [SleepTrend] = []
    @Published var sleepInsights: [SleepInsight] = []
    @Published var sleepRecommendations: [SleepRecommendation] = []
    
    // MARK: - Private Properties
    private var healthStore: HKHealthStore?
    private var sleepData: [SleepSession] = []
    private var sleepPredictor = SleepQualityPredictor()
    private var sleepOptimizer = SleepOptimizationRecommender()
    
    // Sleep analysis parameters
    private let analysisWindow: TimeInterval = 30 * 24 * 3600 // 30 days
    private let trendWindow: TimeInterval = 7 * 24 * 3600 // 7 days
    
    weak var delegate: AnalyticsEngineDelegate?
    
    init() {
        super.init()
        setupSleepAnalysis()
    }
    
    // MARK: - Public Methods
    
    /// Get comprehensive sleep analytics
    func getAnalytics() -> DimensionAnalytics {
        return DimensionAnalytics(
            dimension: .sleep,
            metrics: getSleepMetrics(),
            trends: sleepTrends,
            risks: getSleepRisks(),
            insights: sleepInsights,
            recommendations: sleepRecommendations
        )
    }
    
    /// Analyze sleep patterns and generate insights
    func analyzeSleepPatterns() {
        guard !sleepData.isEmpty else { return }
        
        // Calculate sleep metrics
        calculateSleepMetrics()
        
        // Detect sleep trends
        detectSleepTrends()
        
        // Generate sleep insights
        generateSleepInsights()
        
        // Generate sleep recommendations
        generateSleepRecommendations()
        
        // Predict sleep quality
        predictSleepQuality()
        
        // Notify delegate
        delegate?.analyticsEngine(self, didUpdateAnalytics: getAnalytics())
    }
    
    /// Get sleep quality prediction for tonight
    func predictTonightSleepQuality() -> SleepQualityPrediction {
        return sleepPredictor.predictSleepQuality(for: Date())
    }
    
    /// Get personalized sleep optimization recommendations
    func getSleepOptimizationRecommendations() -> [SleepRecommendation] {
        return sleepOptimizer.generateRecommendations(basedOn: sleepData)
    }
    
    // MARK: - Private Methods
    
    private func setupSleepAnalysis() {
        // Initialize sleep analysis components
        sleepPredictor.delegate = self
        sleepOptimizer.delegate = self
    }
    
    private func calculateSleepMetrics() {
        guard let recentSessions = getRecentSleepSessions() else { return }
        
        // Calculate sleep quality score
        sleepQualityScore = calculateOverallSleepQuality(from: recentSessions)
        
        // Calculate sleep efficiency
        sleepEfficiency = calculateSleepEfficiency(from: recentSessions)
        
        // Calculate sleep latency
        sleepLatency = calculateAverageSleepLatency(from: recentSessions)
        
        // Calculate sleep stage percentages
        let stagePercentages = calculateSleepStagePercentages(from: recentSessions)
        remSleepPercentage = stagePercentages.rem
        deepSleepPercentage = stagePercentages.deep
    }
    
    private func detectSleepTrends() {
        let trends = analyzeSleepTrends()
        DispatchQueue.main.async { [weak self] in
            self?.sleepTrends = trends
        }
    }
    
    private func generateSleepInsights() {
        let insights = generateSleepInsightsFromData()
        DispatchQueue.main.async { [weak self] in
            self?.sleepInsights = insights
        }
    }
    
    private func generateSleepRecommendations() {
        let recommendations = sleepOptimizer.generateRecommendations(basedOn: sleepData)
        DispatchQueue.main.async { [weak self] in
            self?.sleepRecommendations = recommendations
        }
    }
    
    private func predictSleepQuality() {
        let prediction = sleepPredictor.predictSleepQuality(for: Date())
        // Process prediction results
    }
    
    private func getRecentSleepSessions() -> [SleepSession]? {
        let cutoffDate = Date().addingTimeInterval(-analysisWindow)
        return sleepData.filter { $0.startDate >= cutoffDate }
    }
    
    private func calculateOverallSleepQuality(from sessions: [SleepSession]) -> Double {
        guard !sessions.isEmpty else { return 0.0 }
        
        let qualityScores = sessions.map { session in
            calculateSessionQuality(session)
        }
        
        return qualityScores.reduce(0, +) / Double(qualityScores.count)
    }
    
    private func calculateSessionQuality(_ session: SleepSession) -> Double {
        var score = 0.0
        
        // Duration factor (optimal: 7-9 hours)
        let durationHours = session.duration / 3600
        if durationHours >= 7.0 && durationHours <= 9.0 {
            score += 0.3
        } else if durationHours >= 6.0 && durationHours <= 10.0 {
            score += 0.2
        } else {
            score += 0.1
        }
        
        // Efficiency factor
        score += session.efficiency * 0.3
        
        // REM sleep factor (optimal: 20-25%)
        let remPercentage = session.remDuration / session.duration
        if remPercentage >= 0.20 && remPercentage <= 0.25 {
            score += 0.2
        } else if remPercentage >= 0.15 && remPercentage <= 0.30 {
            score += 0.15
        } else {
            score += 0.1
        }
        
        // Deep sleep factor (optimal: 15-20%)
        let deepPercentage = session.deepDuration / session.duration
        if deepPercentage >= 0.15 && deepPercentage <= 0.20 {
            score += 0.2
        } else if deepPercentage >= 0.10 && deepPercentage <= 0.25 {
            score += 0.15
        } else {
            score += 0.1
        }
        
        return min(1.0, score)
    }
    
    private func calculateSleepEfficiency(from sessions: [SleepSession]) -> Double {
        guard !sessions.isEmpty else { return 0.0 }
        
        let efficiencies = sessions.map { $0.efficiency }
        return efficiencies.reduce(0, +) / Double(efficiencies.count)
    }
    
    private func calculateAverageSleepLatency(from sessions: [SleepSession]) -> Double {
        guard !sessions.isEmpty else { return 0.0 }
        
        let latencies = sessions.compactMap { $0.sleepLatency }
        guard !latencies.isEmpty else { return 0.0 }
        
        return latencies.reduce(0, +) / Double(latencies.count)
    }
    
    private func calculateSleepStagePercentages(from sessions: [SleepSession]) -> (rem: Double, deep: Double) {
        guard !sessions.isEmpty else { return (0.0, 0.0) }
        
        var totalRemDuration: TimeInterval = 0
        var totalDeepDuration: TimeInterval = 0
        var totalDuration: TimeInterval = 0
        
        for session in sessions {
            totalRemDuration += session.remDuration
            totalDeepDuration += session.deepDuration
            totalDuration += session.duration
        }
        
        let remPercentage = totalDuration > 0 ? totalRemDuration / totalDuration : 0.0
        let deepPercentage = totalDuration > 0 ? totalDeepDuration / totalDuration : 0.0
        
        return (rem: remPercentage, deep: deepPercentage)
    }
    
    private func analyzeSleepTrends() -> [SleepTrend] {
        var trends: [SleepTrend] = []
        
        // Analyze sleep duration trend
        if let durationTrend = analyzeTrend(for: \.duration, in: sleepData) {
            trends.append(durationTrend)
        }
        
        // Analyze sleep quality trend
        if let qualityTrend = analyzeQualityTrend() {
            trends.append(qualityTrend)
        }
        
        // Analyze sleep efficiency trend
        if let efficiencyTrend = analyzeTrend(for: \.efficiency, in: sleepData) {
            trends.append(efficiencyTrend)
        }
        
        return trends
    }
    
    private func analyzeTrend<T: Comparable>(for keyPath: KeyPath<SleepSession, T>, in sessions: [SleepSession]) -> SleepTrend? {
        guard sessions.count >= 7 else { return nil }
        
        let recentSessions = Array(sessions.suffix(7))
        let values = recentSessions.map { $0[keyPath: keyPath] }
        
        // Simple trend analysis
        let firstHalf = Array(values.prefix(3))
        let secondHalf = Array(values.suffix(3))
        
        let firstAverage = firstHalf.reduce(0) { $0 + Double(truncating: $1 as! NSNumber) } / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0) { $0 + Double(truncating: $1 as! NSNumber) } / Double(secondHalf.count)
        
        let change = secondAverage - firstAverage
        let percentageChange = firstAverage > 0 ? (change / firstAverage) * 100 : 0
        
        let direction: TrendDirection = change > 0 ? .improving : (change < 0 ? .declining : .stable)
        
        return SleepTrend(
            metric: String(describing: keyPath),
            direction: direction,
            magnitude: abs(percentageChange),
            timeframe: trendWindow,
            confidence: calculateTrendConfidence(values)
        )
    }
    
    private func analyzeQualityTrend() -> SleepTrend? {
        guard sleepData.count >= 7 else { return nil }
        
        let recentSessions = Array(sleepData.suffix(7))
        let qualityScores = recentSessions.map { calculateSessionQuality($0) }
        
        let firstHalf = Array(qualityScores.prefix(3))
        let secondHalf = Array(qualityScores.suffix(3))
        
        let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let change = secondAverage - firstAverage
        let percentageChange = firstAverage > 0 ? (change / firstAverage) * 100 : 0
        
        let direction: TrendDirection = change > 0 ? .improving : (change < 0 ? .declining : .stable)
        
        return SleepTrend(
            metric: "Sleep Quality",
            direction: direction,
            magnitude: abs(percentageChange),
            timeframe: trendWindow,
            confidence: calculateTrendConfidence(qualityScores)
        )
    }
    
    private func calculateTrendConfidence(_ values: [Double]) -> Double {
        // Simple confidence calculation based on variance
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // Lower standard deviation = higher confidence
        let coefficientOfVariation = standardDeviation / mean
        return max(0.0, min(1.0, 1.0 - coefficientOfVariation))
    }
    
    private func generateSleepInsightsFromData() -> [SleepInsight] {
        var insights: [SleepInsight] = []
        
        // Analyze sleep consistency
        if let consistencyInsight = analyzeSleepConsistency() {
            insights.append(consistencyInsight)
        }
        
        // Analyze sleep timing
        if let timingInsight = analyzeSleepTiming() {
            insights.append(timingInsight)
        }
        
        // Analyze sleep stages
        if let stageInsight = analyzeSleepStages() {
            insights.append(stageInsight)
        }
        
        return insights
    }
    
    private func analyzeSleepConsistency() -> SleepInsight? {
        guard sleepData.count >= 7 else { return nil }
        
        let recentSessions = Array(sleepData.suffix(7))
        let durations = recentSessions.map { $0.duration }
        
        let meanDuration = durations.reduce(0, +) / Double(durations.count)
        let variance = durations.map { pow($0 - meanDuration, 2) }.reduce(0, +) / Double(durations.count)
        let standardDeviation = sqrt(variance)
        let coefficientOfVariation = standardDeviation / meanDuration
        
        if coefficientOfVariation > 0.2 {
            return SleepInsight(
                title: "Sleep Schedule Inconsistency",
                description: "Your sleep duration varies significantly from night to night, which can impact sleep quality.",
                category: .pattern,
                confidence: 0.8,
                actionable: true,
                priority: .medium
            )
        }
        
        return nil
    }
    
    private func analyzeSleepTiming() -> SleepInsight? {
        guard sleepData.count >= 7 else { return nil }
        
        let recentSessions = Array(sleepData.suffix(7))
        let bedtimes = recentSessions.map { $0.startDate }
        
        // Calculate average bedtime
        let averageBedtime = bedtimes.reduce(0) { $0 + $1.timeIntervalSince1970 } / Double(bedtimes.count)
        let averageBedtimeDate = Date(timeIntervalSince1970: averageBedtime)
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: averageBedtimeDate)
        
        if hour >= 23 || hour <= 5 {
            return SleepInsight(
                title: "Late Bedtime Pattern",
                description: "You consistently go to bed late, which may affect your circadian rhythm and sleep quality.",
                category: .pattern,
                confidence: 0.7,
                actionable: true,
                priority: .medium
            )
        }
        
        return nil
    }
    
    private func analyzeSleepStages() -> SleepInsight? {
        let (remPercentage, deepPercentage) = calculateSleepStagePercentages(from: sleepData)
        
        if remPercentage < 0.15 {
            return SleepInsight(
                title: "Low REM Sleep",
                description: "Your REM sleep percentage is below the recommended range, which may affect memory consolidation and emotional regulation.",
                category: .optimization,
                confidence: 0.8,
                actionable: true,
                priority: .high
            )
        }
        
        if deepPercentage < 0.10 {
            return SleepInsight(
                title: "Low Deep Sleep",
                description: "Your deep sleep percentage is below the recommended range, which may affect physical recovery and immune function.",
                category: .optimization,
                confidence: 0.8,
                actionable: true,
                priority: .high
            )
        }
        
        return nil
    }
    
    private func getSleepMetrics() -> [String: Double] {
        return [
            "Sleep Quality Score": sleepQualityScore,
            "Sleep Efficiency": sleepEfficiency,
            "Sleep Latency": sleepLatency,
            "REM Sleep Percentage": remSleepPercentage,
            "Deep Sleep Percentage": deepSleepPercentage
        ]
    }
    
    private func getSleepRisks() -> [RiskAssessment] {
        var risks: [RiskAssessment] = []
        
        // Sleep deprivation risk
        if sleepQualityScore < 0.6 {
            risks.append(RiskAssessment(
                category: .sleep,
                level: .moderate,
                score: 1.0 - sleepQualityScore,
                factors: ["Low sleep quality score", "Poor sleep efficiency"],
                recommendations: ["Improve sleep hygiene", "Maintain consistent sleep schedule"]
            ))
        }
        
        // Sleep disorder risk
        if sleepLatency > 30 * 60 { // 30 minutes
            risks.append(RiskAssessment(
                category: .sleep,
                level: .moderate,
                score: 0.7,
                factors: ["High sleep latency", "Difficulty falling asleep"],
                recommendations: ["Practice relaxation techniques", "Avoid screens before bed"]
            ))
        }
        
        return risks
    }
}

// MARK: - Sleep Prediction Delegate

extension SleepAnalyticsEngine: SleepQualityPredictorDelegate {
    func sleepQualityPredictor(_ predictor: SleepQualityPredictor, didUpdatePrediction prediction: SleepQualityPrediction) {
        // Handle sleep quality prediction updates
    }
}

// MARK: - Sleep Optimization Delegate

extension SleepAnalyticsEngine: SleepOptimizationRecommenderDelegate {
    func sleepOptimizationRecommender(_ recommender: SleepOptimizationRecommender, didUpdateRecommendations recommendations: [SleepRecommendation]) {
        // Handle sleep optimization recommendation updates
    }
}

// MARK: - Supporting Types

struct SleepSession {
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let efficiency: Double
    let sleepLatency: TimeInterval?
    let remDuration: TimeInterval
    let deepDuration: TimeInterval
    let lightDuration: TimeInterval
    let awakeDuration: TimeInterval
}

struct SleepTrend {
    let metric: String
    let direction: TrendDirection
    let magnitude: Double
    let timeframe: TimeInterval
    let confidence: Double
}

struct SleepInsight {
    let title: String
    let description: String
    let category: InsightCategory
    let confidence: Double
    let actionable: Bool
    let priority: InsightPriority
}

struct SleepRecommendation {
    let title: String
    let description: String
    let category: RecommendationCategory
    let priority: RecommendationPriority
    let actionable: Bool
    let estimatedImpact: Double
}

struct SleepQualityPrediction {
    let predictedScore: Double
    let confidence: Double
    let factors: [String]
    let recommendations: [String]
}

// MARK: - Base Classes

class AnalyticsEngine: ObservableObject {
    weak var delegate: AnalyticsEngineDelegate?
    
    init() {}
}

protocol AnalyticsEngineDelegate: AnyObject {
    func analyticsEngine(_ engine: AnalyticsEngine, didUpdateAnalytics analytics: DimensionAnalytics)
}

class SleepQualityPredictor {
    weak var delegate: SleepQualityPredictorDelegate?
    
    func predictSleepQuality(for date: Date) -> SleepQualityPrediction {
        // Implementation for sleep quality prediction
        return SleepQualityPrediction(
            predictedScore: 0.8,
            confidence: 0.7,
            factors: ["Recent sleep patterns", "Daily activity"],
            recommendations: ["Maintain consistent bedtime", "Avoid caffeine after 2 PM"]
        )
    }
}

protocol SleepQualityPredictorDelegate: AnyObject {
    func sleepQualityPredictor(_ predictor: SleepQualityPredictor, didUpdatePrediction prediction: SleepQualityPrediction)
}

class SleepOptimizationRecommender {
    weak var delegate: SleepOptimizationRecommenderDelegate?
    
    func generateRecommendations(basedOn sessions: [SleepSession]) -> [SleepRecommendation] {
        // Implementation for sleep optimization recommendations
        return [
            SleepRecommendation(
                title: "Improve Sleep Hygiene",
                description: "Create a relaxing bedtime routine",
                category: .sleep,
                priority: .medium,
                actionable: true,
                estimatedImpact: 0.2
            )
        ]
    }
}

protocol SleepOptimizationRecommenderDelegate: AnyObject {
    func sleepOptimizationRecommender(_ recommender: SleepOptimizationRecommender, didUpdateRecommendations recommendations: [SleepRecommendation])
} 