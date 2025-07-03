import Foundation
import HealthKit
import Combine

/// Comprehensive cardiac health analyzer
/// Provides cardiac health assessment, trend analysis, and risk calculation
class CardiacHealthAnalyzer: AnalyticsEngine {
    // MARK: - Published Properties
    @Published var cardiacHealthScore: Double = 0.0
    @Published var heartRateVariability: Double = 0.0
    @Published var restingHeartRate: Double = 0.0
    @Published var cardiacTrends: [CardiacTrend] = []
    @Published var cardiacInsights: [CardiacInsight] = []
    @Published var cardiacRecommendations: [CardiacRecommendation] = []
    @Published var cardiacRisks: [CardiacRisk] = []
    
    // MARK: - Private Properties
    private var healthStore: HKHealthStore?
    private var cardiacData: [CardiacMeasurement] = []
    private var ecgInsights: [ECGInsight] = []
    
    // Cardiac analysis parameters
    private let analysisWindow: TimeInterval = 30 * 24 * 3600 // 30 days
    private let trendWindow: TimeInterval = 7 * 24 * 3600 // 7 days
    
    // ECG insight integration
    private let ecgInsightManager = ECGInsightManager.shared
    private let cardiacRiskCalculator = CardiacRiskCalculator()
    private let cardiacTrendPredictor = CardiacTrendPredictor()
    
    weak var delegate: AnalyticsEngineDelegate?
    
    init() {
        super.init()
        setupCardiacAnalysis()
    }
    
    // MARK: - Public Methods
    
    /// Get comprehensive cardiac analytics
    func getAnalytics() -> DimensionAnalytics {
        return DimensionAnalytics(
            dimension: .cardiac,
            metrics: getCardiacMetrics(),
            trends: cardiacTrends,
            risks: getCardiacRisks(),
            insights: cardiacInsights,
            recommendations: cardiacRecommendations
        )
    }
    
    /// Analyze cardiac health patterns and generate insights
    func analyzeCardiacHealth() {
        guard !cardiacData.isEmpty else { return }
        
        // Calculate cardiac metrics
        calculateCardiacMetrics()
        
        // Detect cardiac trends
        detectCardiacTrends()
        
        // Generate cardiac insights
        generateCardiacInsights()
        
        // Generate cardiac recommendations
        generateCardiacRecommendations()
        
        // Calculate cardiac risks
        calculateCardiacRisks()
        
        // Predict cardiac trends
        predictCardiacTrends()
        
        // Notify delegate
        delegate?.analyticsEngine(self, didUpdateAnalytics: getAnalytics())
    }
    
    /// Get cardiac risk assessment
    func getCardiacRiskAssessment() -> CardiacRiskAssessment {
        return cardiacRiskCalculator.calculateRisk(basedOn: cardiacData, ecgInsights: ecgInsights)
    }
    
    /// Get cardiac trend predictions
    func getCardiacTrendPredictions() -> [CardiacTrendPrediction] {
        return cardiacTrendPredictor.predictTrends(basedOn: cardiacData)
    }
    
    // MARK: - Private Methods
    
    private func setupCardiacAnalysis() {
        // Setup ECG insight integration
        setupECGInsightIntegration()
        
        // Setup cardiac analysis components
        cardiacRiskCalculator.delegate = self
        cardiacTrendPredictor.delegate = self
    }
    
    private func setupECGInsightIntegration() {
        // Subscribe to ECG insights from M2 Beta modules
        ecgInsightManager.insightsPublisher
            .sink { [weak self] insights in
                self?.processECGInsights(insights)
            }
            .store(in: &cancellables)
    }
    
    private func processECGInsights(_ insights: [ECGInsight]) {
        ecgInsights = insights
        
        // Trigger cardiac analysis when new ECG insights are available
        analyzeCardiacHealth()
    }
    
    private func calculateCardiacMetrics() {
        guard let recentData = getRecentCardiacData() else { return }
        
        // Calculate cardiac health score
        cardiacHealthScore = calculateOverallCardiacHealth(from: recentData)
        
        // Calculate heart rate variability
        heartRateVariability = calculateAverageHRV(from: recentData)
        
        // Calculate resting heart rate
        restingHeartRate = calculateAverageRestingHeartRate(from: recentData)
    }
    
    private func detectCardiacTrends() {
        let trends = analyzeCardiacTrends()
        DispatchQueue.main.async { [weak self] in
            self?.cardiacTrends = trends
        }
    }
    
    private func generateCardiacInsights() {
        let insights = generateCardiacInsightsFromData()
        DispatchQueue.main.async { [weak self] in
            self?.cardiacInsights = insights
        }
    }
    
    private func generateCardiacRecommendations() {
        let recommendations = generateCardiacRecommendationsFromData()
        DispatchQueue.main.async { [weak self] in
            self?.cardiacRecommendations = recommendations
        }
    }
    
    private func calculateCardiacRisks() {
        let risks = cardiacRiskCalculator.calculateRisks(basedOn: cardiacData, ecgInsights: ecgInsights)
        DispatchQueue.main.async { [weak self] in
            self?.cardiacRisks = risks
        }
    }
    
    private func predictCardiacTrends() {
        let predictions = cardiacTrendPredictor.predictTrends(basedOn: cardiacData)
        // Process trend predictions
    }
    
    private func getRecentCardiacData() -> [CardiacMeasurement]? {
        let cutoffDate = Date().addingTimeInterval(-analysisWindow)
        return cardiacData.filter { $0.timestamp >= cutoffDate }
    }
    
    private func calculateOverallCardiacHealth(from measurements: [CardiacMeasurement]) -> Double {
        guard !measurements.isEmpty else { return 0.0 }
        
        let healthScores = measurements.map { measurement in
            calculateMeasurementHealth(measurement)
        }
        
        return healthScores.reduce(0, +) / Double(healthScores.count)
    }
    
    private func calculateMeasurementHealth(_ measurement: CardiacMeasurement) -> Double {
        var score = 0.0
        
        // Heart rate factor (optimal: 60-100 BPM)
        let heartRate = measurement.heartRate
        if heartRate >= 60 && heartRate <= 100 {
            score += 0.3
        } else if heartRate >= 50 && heartRate <= 110 {
            score += 0.2
        } else {
            score += 0.1
        }
        
        // HRV factor (higher is better, but within normal range)
        let hrv = measurement.heartRateVariability
        if hrv >= 20 && hrv <= 100 {
            score += 0.3
        } else if hrv >= 15 && hrv <= 120 {
            score += 0.2
        } else {
            score += 0.1
        }
        
        // Blood pressure factor (if available)
        if let systolic = measurement.systolicBloodPressure,
           let diastolic = measurement.diastolicBloodPressure {
            if systolic < 120 && diastolic < 80 {
                score += 0.2
            } else if systolic < 130 && diastolic < 85 {
                score += 0.15
            } else {
                score += 0.1
            }
        } else {
            score += 0.1 // Default score if BP not available
        }
        
        // ECG insight factor
        if let ecgInsight = measurement.ecgInsight {
            score += ecgInsight.healthScore * 0.2
        } else {
            score += 0.1 // Default score if ECG insight not available
        }
        
        return min(1.0, score)
    }
    
    private func calculateAverageHRV(from measurements: [CardiacMeasurement]) -> Double {
        guard !measurements.isEmpty else { return 0.0 }
        
        let hrvValues = measurements.compactMap { $0.heartRateVariability }
        guard !hrvValues.isEmpty else { return 0.0 }
        
        return hrvValues.reduce(0, +) / Double(hrvValues.count)
    }
    
    private func calculateAverageRestingHeartRate(from measurements: [CardiacMeasurement]) -> Double {
        guard !measurements.isEmpty else { return 0.0 }
        
        let restingHRValues = measurements.compactMap { $0.restingHeartRate }
        guard !restingHRValues.isEmpty else { return 0.0 }
        
        return restingHRValues.reduce(0, +) / Double(restingHRValues.count)
    }
    
    private func analyzeCardiacTrends() -> [CardiacTrend] {
        var trends: [CardiacTrend] = []
        
        // Analyze heart rate trend
        if let hrTrend = analyzeTrend(for: \.heartRate, in: cardiacData) {
            trends.append(hrTrend)
        }
        
        // Analyze HRV trend
        if let hrvTrend = analyzeHRVTrend() {
            trends.append(hrvTrend)
        }
        
        // Analyze cardiac health score trend
        if let healthTrend = analyzeHealthTrend() {
            trends.append(healthTrend)
        }
        
        return trends
    }
    
    private func analyzeTrend<T: Comparable>(for keyPath: KeyPath<CardiacMeasurement, T>, in measurements: [CardiacMeasurement]) -> CardiacTrend? {
        guard measurements.count >= 7 else { return nil }
        
        let recentMeasurements = Array(measurements.suffix(7))
        let values = recentMeasurements.map { $0[keyPath: keyPath] }
        
        // Simple trend analysis
        let firstHalf = Array(values.prefix(3))
        let secondHalf = Array(values.suffix(3))
        
        let firstAverage = firstHalf.reduce(0) { $0 + Double(truncating: $1 as! NSNumber) } / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0) { $0 + Double(truncating: $1 as! NSNumber) } / Double(secondHalf.count)
        
        let change = secondAverage - firstAverage
        let percentageChange = firstAverage > 0 ? (change / firstAverage) * 100 : 0
        
        let direction: TrendDirection = change > 0 ? .improving : (change < 0 ? .declining : .stable)
        
        return CardiacTrend(
            metric: String(describing: keyPath),
            direction: direction,
            magnitude: abs(percentageChange),
            timeframe: trendWindow,
            confidence: calculateTrendConfidence(values)
        )
    }
    
    private func analyzeHRVTrend() -> CardiacTrend? {
        guard cardiacData.count >= 7 else { return nil }
        
        let recentMeasurements = Array(cardiacData.suffix(7))
        let hrvValues = recentMeasurements.compactMap { $0.heartRateVariability }
        
        guard hrvValues.count >= 6 else { return nil }
        
        let firstHalf = Array(hrvValues.prefix(3))
        let secondHalf = Array(hrvValues.suffix(3))
        
        let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let change = secondAverage - firstAverage
        let percentageChange = firstAverage > 0 ? (change / firstAverage) * 100 : 0
        
        let direction: TrendDirection = change > 0 ? .improving : (change < 0 ? .declining : .stable)
        
        return CardiacTrend(
            metric: "Heart Rate Variability",
            direction: direction,
            magnitude: abs(percentageChange),
            timeframe: trendWindow,
            confidence: calculateTrendConfidence(hrvValues)
        )
    }
    
    private func analyzeHealthTrend() -> CardiacTrend? {
        guard cardiacData.count >= 7 else { return nil }
        
        let recentMeasurements = Array(cardiacData.suffix(7))
        let healthScores = recentMeasurements.map { calculateMeasurementHealth($0) }
        
        let firstHalf = Array(healthScores.prefix(3))
        let secondHalf = Array(healthScores.suffix(3))
        
        let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        let change = secondAverage - firstAverage
        let percentageChange = firstAverage > 0 ? (change / firstAverage) * 100 : 0
        
        let direction: TrendDirection = change > 0 ? .improving : (change < 0 ? .declining : .stable)
        
        return CardiacTrend(
            metric: "Cardiac Health Score",
            direction: direction,
            magnitude: abs(percentageChange),
            timeframe: trendWindow,
            confidence: calculateTrendConfidence(healthScores)
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
    
    private func generateCardiacInsightsFromData() -> [CardiacInsight] {
        var insights: [CardiacInsight] = []
        
        // Analyze heart rate patterns
        if let hrInsight = analyzeHeartRatePatterns() {
            insights.append(hrInsight)
        }
        
        // Analyze HRV patterns
        if let hrvInsight = analyzeHRVPatterns() {
            insights.append(hrvInsight)
        }
        
        // Analyze ECG insights
        if let ecgInsight = analyzeECGInsights() {
            insights.append(ecgInsight)
        }
        
        return insights
    }
    
    private func analyzeHeartRatePatterns() -> CardiacInsight? {
        guard cardiacData.count >= 7 else { return nil }
        
        let recentMeasurements = Array(cardiacData.suffix(7))
        let heartRates = recentMeasurements.map { $0.heartRate }
        
        let averageHR = heartRates.reduce(0, +) / Double(heartRates.count)
        
        if averageHR > 100 {
            return CardiacInsight(
                title: "Elevated Heart Rate",
                description: "Your average heart rate is elevated, which may indicate stress, dehydration, or other health factors.",
                category: .pattern,
                confidence: 0.8,
                actionable: true,
                priority: .medium
            )
        } else if averageHR < 50 {
            return CardiacInsight(
                title: "Low Heart Rate",
                description: "Your average heart rate is lower than normal, which may indicate excellent fitness or require medical attention.",
                category: .pattern,
                confidence: 0.7,
                actionable: true,
                priority: .medium
            )
        }
        
        return nil
    }
    
    private func analyzeHRVPatterns() -> CardiacInsight? {
        guard cardiacData.count >= 7 else { return nil }
        
        let recentMeasurements = Array(cardiacData.suffix(7))
        let hrvValues = recentMeasurements.compactMap { $0.heartRateVariability }
        
        guard !hrvValues.isEmpty else { return nil }
        
        let averageHRV = hrvValues.reduce(0, +) / Double(hrvValues.count)
        
        if averageHRV < 20 {
            return CardiacInsight(
                title: "Low Heart Rate Variability",
                description: "Your heart rate variability is low, which may indicate stress, poor sleep, or reduced autonomic function.",
                category: .optimization,
                confidence: 0.8,
                actionable: true,
                priority: .high
            )
        }
        
        return nil
    }
    
    private func analyzeECGInsights() -> CardiacInsight? {
        guard !ecgInsights.isEmpty else { return nil }
        
        // Check for concerning ECG insights
        let concerningInsights = ecgInsights.filter { $0.severity == .moderate || $0.severity == .high }
        
        if !concerningInsights.isEmpty {
            let mostConcerning = concerningInsights.max { $0.severity.rawValue < $1.severity.rawValue }
            
            return CardiacInsight(
                title: "ECG Anomaly Detected",
                description: "Recent ECG analysis detected \(mostConcerning?.type.rawValue ?? "anomalies") that may require attention.",
                category: .anomaly,
                confidence: mostConcerning?.confidence ?? 0.7,
                actionable: true,
                priority: .high
            )
        }
        
        return nil
    }
    
    private func generateCardiacRecommendationsFromData() -> [CardiacRecommendation] {
        var recommendations: [CardiacRecommendation] = []
        
        // Generate recommendations based on insights
        for insight in cardiacInsights {
            if insight.actionable {
                recommendations.append(generateRecommendationForInsight(insight))
            }
        }
        
        // Add general cardiac health recommendations
        recommendations.append(CardiacRecommendation(
            title: "Regular Exercise",
            description: "Engage in regular cardiovascular exercise to improve heart health",
            category: .exercise,
            priority: .medium,
            actionable: true,
            estimatedImpact: 0.3
        ))
        
        return recommendations
    }
    
    private func generateRecommendationForInsight(_ insight: CardiacInsight) -> CardiacRecommendation {
        switch insight.title {
        case "Elevated Heart Rate":
            return CardiacRecommendation(
                title: "Stress Management",
                description: "Practice stress reduction techniques like meditation or deep breathing",
                category: .stress,
                priority: .medium,
                actionable: true,
                estimatedImpact: 0.2
            )
        case "Low Heart Rate Variability":
            return CardiacRecommendation(
                title: "Improve Sleep Quality",
                description: "Focus on getting better quality sleep to improve autonomic function",
                category: .sleep,
                priority: .high,
                actionable: true,
                estimatedImpact: 0.4
            )
        case "ECG Anomaly Detected":
            return CardiacRecommendation(
                title: "Consult Healthcare Provider",
                description: "Schedule a consultation with your healthcare provider to review ECG findings",
                category: .medical,
                priority: .urgent,
                actionable: true,
                estimatedImpact: 0.8
            )
        default:
            return CardiacRecommendation(
                title: "Monitor Cardiac Health",
                description: "Continue monitoring your cardiac health metrics",
                category: .lifestyle,
                priority: .low,
                actionable: true,
                estimatedImpact: 0.1
            )
        }
    }
    
    private func getCardiacMetrics() -> [String: Double] {
        return [
            "Cardiac Health Score": cardiacHealthScore,
            "Heart Rate Variability": heartRateVariability,
            "Resting Heart Rate": restingHeartRate
        ]
    }
    
    private func getCardiacRisks() -> [RiskAssessment] {
        return cardiacRisks.map { cardiacRisk in
            RiskAssessment(
                category: .cardiac,
                level: cardiacRisk.level,
                score: cardiacRisk.score,
                factors: cardiacRisk.factors,
                recommendations: cardiacRisk.recommendations
            )
        }
    }
}

// MARK: - Cardiac Risk Calculator Delegate

extension CardiacHealthAnalyzer: CardiacRiskCalculatorDelegate {
    func cardiacRiskCalculator(_ calculator: CardiacRiskCalculator, didUpdateRisk risk: CardiacRisk) {
        // Handle cardiac risk updates
    }
}

// MARK: - Cardiac Trend Predictor Delegate

extension CardiacHealthAnalyzer: CardiacTrendPredictorDelegate {
    func cardiacTrendPredictor(_ predictor: CardiacTrendPredictor, didUpdatePredictions predictions: [CardiacTrendPrediction]) {
        // Handle cardiac trend prediction updates
    }
}

// MARK: - Supporting Types

struct CardiacMeasurement {
    let timestamp: Date
    let heartRate: Double
    let heartRateVariability: Double?
    let restingHeartRate: Double?
    let systolicBloodPressure: Double?
    let diastolicBloodPressure: Double?
    let ecgInsight: ECGInsight?
}

struct CardiacTrend {
    let metric: String
    let direction: TrendDirection
    let magnitude: Double
    let timeframe: TimeInterval
    let confidence: Double
}

struct CardiacInsight {
    let title: String
    let description: String
    let category: InsightCategory
    let confidence: Double
    let actionable: Bool
    let priority: InsightPriority
}

struct CardiacRecommendation {
    let title: String
    let description: String
    let category: RecommendationCategory
    let priority: RecommendationPriority
    let actionable: Bool
    let estimatedImpact: Double
}

struct CardiacRisk {
    let type: CardiacRiskType
    let level: RiskLevel
    let score: Double
    let factors: [String]
    let recommendations: [String]
}

enum CardiacRiskType: String, CaseIterable {
    case arrhythmia = "Arrhythmia"
    case hypertension = "Hypertension"
    case coronaryDisease = "Coronary Disease"
    case heartFailure = "Heart Failure"
}

struct CardiacRiskAssessment {
    let overallRisk: RiskLevel
    let riskScore: Double
    let specificRisks: [CardiacRisk]
    let recommendations: [String]
}

struct CardiacTrendPrediction {
    let metric: String
    let predictedValue: Double
    let confidence: Double
    let timeframe: TimeInterval
    let factors: [String]
}

// MARK: - ECG Insight Types (from M2 Beta)

struct ECGInsight {
    let type: ECGInsightType
    let severity: ECGInsightSeverity
    let confidence: Double
    let healthScore: Double
    let description: String
}

enum ECGInsightType: String, CaseIterable {
    case beatMorphology = "Beat Morphology"
    case hrTurbulence = "HR Turbulence"
    case qtDynamic = "QT Dynamic"
    case afForecast = "AF Forecast"
    case stShift = "ST Shift"
}

enum ECGInsightSeverity: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
}

// MARK: - Base Classes

class CardiacRiskCalculator {
    weak var delegate: CardiacRiskCalculatorDelegate?
    
    func calculateRisk(basedOn measurements: [CardiacMeasurement], ecgInsights: [ECGInsight]) -> CardiacRiskAssessment {
        // Implementation for cardiac risk calculation
        return CardiacRiskAssessment(
            overallRisk: .low,
            riskScore: 0.2,
            specificRisks: [],
            recommendations: ["Continue monitoring", "Maintain healthy lifestyle"]
        )
    }
    
    func calculateRisks(basedOn measurements: [CardiacMeasurement], ecgInsights: [ECGInsight]) -> [CardiacRisk] {
        // Implementation for specific cardiac risk calculation
        return []
    }
}

protocol CardiacRiskCalculatorDelegate: AnyObject {
    func cardiacRiskCalculator(_ calculator: CardiacRiskCalculator, didUpdateRisk risk: CardiacRisk)
}

class CardiacTrendPredictor {
    weak var delegate: CardiacTrendPredictorDelegate?
    
    func predictTrends(basedOn measurements: [CardiacMeasurement]) -> [CardiacTrendPrediction] {
        // Implementation for cardiac trend prediction
        return []
    }
}

protocol CardiacTrendPredictorDelegate: AnyObject {
    func cardiacTrendPredictor(_ predictor: CardiacTrendPredictor, didUpdatePredictions predictions: [CardiacTrendPrediction])
} 