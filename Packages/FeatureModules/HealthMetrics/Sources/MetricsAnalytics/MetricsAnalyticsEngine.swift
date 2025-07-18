import Foundation
import HealthAI2030Core
import AsyncAlgorithms
import Numerics

/// Advanced metrics analytics engine with statistical analysis and trend detection
@globalActor
public actor MetricsAnalyticsEngine {
    public static let shared = MetricsAnalyticsEngine()
    
    private var metricsHistory: [MetricType: [HealthMetric]] = [:]
    private var trendAnalyzers: [MetricType: TrendAnalyzer] = [:]
    private var anomalyDetectors: [MetricType: AnomalyDetector] = [:]
    private var correlationMatrix: CorrelationMatrix = CorrelationMatrix()
    
    private init() {
        setupAnalyzers()
        startMetricsProcessing()
    }
    
    // MARK: - Public Interface
    
    /// Add new metric data for analysis
    public func addMetric(_ metric: HealthMetric) async {
        // Store metric in history
        if metricsHistory[metric.type] == nil {
            metricsHistory[metric.type] = []
        }
        metricsHistory[metric.type]?.append(metric)
        
        // Maintain rolling window (keep last 90 days)
        let ninetyDaysAgo = Date().addingTimeInterval(-90 * 24 * 3600)
        metricsHistory[metric.type]?.removeAll { $0.timestamp < ninetyDaysAgo }
        
        // Update analyzers
        await updateAnalyzers(metric)
        
        // Update correlation matrix
        await updateCorrelations(metric)
    }
    
    /// Get comprehensive analytics for a specific metric type
    public func getAnalytics(for metricType: MetricType) async -> MetricAnalytics? {
        guard let history = metricsHistory[metricType], !history.isEmpty else {
            return nil
        }
        
        let statistics = calculateStatistics(for: history)
        let trends = await trendAnalyzers[metricType]?.getCurrentTrends() ?? []
        let anomalies = await anomalyDetectors[metricType]?.getRecentAnomalies() ?? []
        let forecasts = await generateForecasts(for: metricType, history: history)
        
        return MetricAnalytics(
            metricType: metricType,
            statistics: statistics,
            trends: trends,
            anomalies: anomalies,
            forecasts: forecasts,
            lastUpdated: Date()
        )
    }
    
    /// Get cross-metric correlations and insights
    public func getCorrelationInsights() async -> [CorrelationInsight] {
        return await correlationMatrix.generateInsights()
    }
    
    /// Get personalized health score based on all metrics
    public func calculateHealthScore() async -> HealthScore {
        var metricScores: [MetricType: Double] = [:]
        var confidence = 1.0
        
        for metricType in MetricType.allCases {
            if let analytics = await getAnalytics(for: metricType) {
                let score = calculateMetricScore(analytics)
                metricScores[metricType] = score
                
                // Reduce confidence if data is sparse
                if analytics.statistics.sampleSize < 7 {
                    confidence *= 0.8
                }
            }
        }
        
        let overallScore = calculateOverallScore(metricScores)
        let riskFactors = identifyRiskFactors(metricScores)
        let recommendations = generateRecommendations(metricScores)
        
        return HealthScore(
            overall: overallScore,
            confidence: confidence,
            metricScores: metricScores,
            riskFactors: riskFactors,
            recommendations: recommendations,
            timestamp: Date()
        )
    }
    
    /// Get trend predictions for the next period
    public func getTrendPredictions(daysAhead: Int = 7) async -> [TrendPrediction] {
        var predictions: [TrendPrediction] = []
        
        for metricType in MetricType.allCases {
            guard let analyzer = trendAnalyzers[metricType],
                  let history = metricsHistory[metricType],
                  history.count >= 3 else { continue }
            
            let prediction = await analyzer.predictTrend(daysAhead: daysAhead)
            predictions.append(prediction)
        }
        
        return predictions.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Private Implementation
    
    private func setupAnalyzers() {
        for metricType in MetricType.allCases {
            trendAnalyzers[metricType] = TrendAnalyzer(metricType: metricType)
            anomalyDetectors[metricType] = AnomalyDetector(metricType: metricType)
        }
    }
    
    private func startMetricsProcessing() {
        Task {
            // Subscribe to real-time metrics
            for metricType in MetricType.allCases {
                Task {
                    let stream = await SensorDataActor.shared.subscribe(to: metricType)
                    
                    for await metric in stream {
                        await addMetric(metric)
                    }
                }
            }
        }
    }
    
    private func updateAnalyzers(_ metric: HealthMetric) async {
        await trendAnalyzers[metric.type]?.addDataPoint(metric)
        await anomalyDetectors[metric.type]?.analyzeMetric(metric)
    }
    
    private func updateCorrelations(_ metric: HealthMetric) async {
        // Find metrics from the same time window for correlation analysis
        let timeWindow: TimeInterval = 30 * 60 // 30 minutes
        let contemporaneousMetrics = findContemporaneousMetrics(
            for: metric.timestamp,
            window: timeWindow
        )
        
        await correlationMatrix.updateCorrelations(metric, with: contemporaneousMetrics)
    }
    
    private func findContemporaneousMetrics(for timestamp: Date, window: TimeInterval) -> [HealthMetric] {
        var contemporaneous: [HealthMetric] = []
        
        for (_, history) in metricsHistory {
            let nearby = history.filter { metric in
                abs(metric.timestamp.timeIntervalSince(timestamp)) <= window
            }
            contemporaneous.append(contentsOf: nearby)
        }
        
        return contemporaneous
    }
    
    private func calculateStatistics(for history: [HealthMetric]) -> MetricStatistics {
        let values = history.map(\.value)
        
        return MetricStatistics(
            sampleSize: values.count,
            mean: values.mean(),
            median: values.median(),
            standardDeviation: values.standardDeviation(),
            minimum: values.min() ?? 0,
            maximum: values.max() ?? 0,
            percentile25: values.percentile(0.25),
            percentile75: values.percentile(0.75),
            trend: calculateBasicTrend(values),
            variance: values.variance()
        )
    }
    
    private func calculateBasicTrend(_ values: [Double]) -> TrendDirection {
        guard values.count >= 2 else { return .stable }
        
        let recent = Array(values.suffix(min(7, values.count))) // Last week
        let earlier = Array(values.prefix(min(7, values.count)))  // First week
        
        let recentMean = recent.mean()
        let earlierMean = earlier.mean()
        
        let changePercent = (recentMean - earlierMean) / earlierMean * 100
        
        if abs(changePercent) < 5 {
            return .stable
        } else if changePercent > 0 {
            return .increasing
        } else {
            return .decreasing
        }
    }
    
    private func generateForecasts(for metricType: MetricType, history: [HealthMetric]) async -> [MetricForecast] {
        guard history.count >= 7 else { return [] } // Need at least a week of data
        
        let values = history.map(\.value)
        let timestamps = history.map(\.timestamp)
        
        // Simple linear regression for forecasting
        let forecasts = generateLinearForecasts(values: values, timestamps: timestamps, days: 7)
        
        return forecasts.enumerated().map { index, value in
            let forecastDate = Date().addingTimeInterval(TimeInterval((index + 1) * 24 * 3600))
            return MetricForecast(
                date: forecastDate,
                predictedValue: value,
                confidence: calculateForecastConfidence(history: history, daysAhead: index + 1),
                bounds: calculateConfidenceBounds(value: value, confidence: 0.8)
            )
        }
    }
    
    private func generateLinearForecasts(values: [Double], timestamps: [Date], days: Int) -> [Double] {
        // Convert timestamps to relative time points
        guard let firstTimestamp = timestamps.first else { return [] }
        
        let timePoints = timestamps.map { $0.timeIntervalSince(firstTimestamp) / (24 * 3600) } // Days since start
        
        // Calculate linear regression
        let (slope, intercept) = linearRegression(x: timePoints, y: values)
        
        // Generate forecasts
        let lastTimePoint = timePoints.last ?? 0
        return (1...days).map { day in
            let futureTimePoint = lastTimePoint + Double(day)
            return slope * futureTimePoint + intercept
        }
    }
    
    private func linearRegression(x: [Double], y: [Double]) -> (slope: Double, intercept: Double) {
        guard x.count == y.count, !x.isEmpty else { return (0, 0) }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        return (slope, intercept)
    }
    
    private func calculateForecastConfidence(history: [HealthMetric], daysAhead: Int) -> Double {
        // Confidence decreases with forecast distance and data variance
        let baseConfidence = 0.9
        let distancePenalty = Double(daysAhead) * 0.05
        let variancePenalty = calculateVariancePenalty(history)
        
        return max(0.1, baseConfidence - distancePenalty - variancePenalty)
    }
    
    private func calculateVariancePenalty(_ history: [HealthMetric]) -> Double {
        let values = history.map(\.value)
        let variance = values.variance()
        let mean = values.mean()
        
        // Coefficient of variation as penalty
        let cv = sqrt(variance) / mean
        return min(0.3, cv * 0.5)
    }
    
    private func calculateConfidenceBounds(value: Double, confidence: Double) -> (lower: Double, upper: Double) {
        let margin = value * (1.0 - confidence) * 0.5
        return (value - margin, value + margin)
    }
    
    private func calculateMetricScore(_ analytics: MetricAnalytics) -> Double {
        // Score based on how the metric compares to healthy ranges
        let mean = analytics.statistics.mean
        let metricType = analytics.metricType
        
        switch metricType {
        case .heartRate:
            return scoreHeartRate(mean)
        case .heartRateVariability:
            return scoreHRV(mean)
        case .oxygenSaturation:
            return scoreSpO2(mean)
        case .bloodPressureSystolic:
            return scoreBPSystolic(mean)
        case .bloodPressureDiastolic:
            return scoreBPDiastolic(mean)
        case .bodyTemperature:
            return scoreBodyTemperature(mean)
        case .respiratoryRate:
            return scoreRespiratoryRate(mean)
        case .stressLevel:
            return scoreStressLevel(mean)
        case .sleepQuality:
            return scoreSleepQuality(mean)
        case .activityLevel:
            return scoreActivityLevel(mean)
        default:
            return 0.5 // Neutral score for unknown metrics
        }
    }
    
    private func scoreHeartRate(_ value: Double) -> Double {
        // Optimal: 60-80 bpm
        if value >= 60 && value <= 80 {
            return 1.0
        } else if value >= 50 && value <= 100 {
            return 0.8
        } else if value >= 40 && value <= 120 {
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func scoreHRV(_ value: Double) -> Double {
        // Higher HRV is generally better (values in ms)
        if value >= 50 {
            return 1.0
        } else if value >= 30 {
            return 0.8
        } else if value >= 20 {
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func scoreSpO2(_ value: Double) -> Double {
        // Optimal: 95-100%
        if value >= 97 {
            return 1.0
        } else if value >= 95 {
            return 0.8
        } else if value >= 90 {
            return 0.5
        } else {
            return 0.2
        }
    }
    
    private func scoreBPSystolic(_ value: Double) -> Double {
        // Optimal: 90-120 mmHg
        if value >= 90 && value <= 120 {
            return 1.0
        } else if value >= 80 && value <= 140 {
            return 0.7
        } else if value >= 70 && value <= 160 {
            return 0.4
        } else {
            return 0.2
        }
    }
    
    private func scoreBPDiastolic(_ value: Double) -> Double {
        // Optimal: 60-80 mmHg
        if value >= 60 && value <= 80 {
            return 1.0
        } else if value >= 50 && value <= 90 {
            return 0.7
        } else if value >= 40 && value <= 100 {
            return 0.4
        } else {
            return 0.2
        }
    }
    
    private func scoreBodyTemperature(_ value: Double) -> Double {
        // Optimal: 36.1-37.2°C
        if value >= 36.1 && value <= 37.2 {
            return 1.0
        } else if value >= 35.5 && value <= 37.8 {
            return 0.8
        } else if value >= 35.0 && value <= 38.5 {
            return 0.5
        } else {
            return 0.2
        }
    }
    
    private func scoreRespiratoryRate(_ value: Double) -> Double {
        // Optimal: 12-20 breaths/min
        if value >= 12 && value <= 20 {
            return 1.0
        } else if value >= 10 && value <= 25 {
            return 0.8
        } else if value >= 8 && value <= 30 {
            return 0.5
        } else {
            return 0.2
        }
    }
    
    private func scoreStressLevel(_ value: Double) -> Double {
        // Lower stress is better (0-10 scale)
        if value <= 2 {
            return 1.0
        } else if value <= 4 {
            return 0.8
        } else if value <= 6 {
            return 0.6
        } else if value <= 8 {
            return 0.4
        } else {
            return 0.2
        }
    }
    
    private func scoreSleepQuality(_ value: Double) -> Double {
        // Higher sleep quality is better (0-10 scale)
        if value >= 8 {
            return 1.0
        } else if value >= 6 {
            return 0.8
        } else if value >= 4 {
            return 0.6
        } else if value >= 2 {
            return 0.4
        } else {
            return 0.2
        }
    }
    
    private func scoreActivityLevel(_ value: Double) -> Double {
        // Moderate activity is optimal (0-10 scale)
        if value >= 4 && value <= 7 {
            return 1.0
        } else if value >= 2 && value <= 9 {
            return 0.8
        } else if value >= 1 && value <= 10 {
            return 0.6
        } else {
            return 0.3
        }
    }
    
    private func calculateOverallScore(_ metricScores: [MetricType: Double]) -> Double {
        guard !metricScores.isEmpty else { return 0.5 }
        
        // Weight different metrics by importance
        let weights: [MetricType: Double] = [
            .heartRate: 1.0,
            .heartRateVariability: 1.2,
            .bloodPressureSystolic: 1.1,
            .bloodPressureDiastolic: 1.1,
            .oxygenSaturation: 1.0,
            .stressLevel: 1.2,
            .sleepQuality: 1.3,
            .activityLevel: 0.8,
            .bodyTemperature: 0.6,
            .respiratoryRate: 0.7
        ]
        
        var weightedSum = 0.0
        var totalWeight = 0.0
        
        for (metricType, score) in metricScores {
            let weight = weights[metricType] ?? 0.5
            weightedSum += score * weight
            totalWeight += weight
        }
        
        return totalWeight > 0 ? weightedSum / totalWeight : 0.5
    }
    
    private func identifyRiskFactors(_ metricScores: [MetricType: Double]) -> [RiskFactor] {
        var riskFactors: [RiskFactor] = []
        
        for (metricType, score) in metricScores {
            if score < 0.5 {
                let severity: RiskSeverity = score < 0.3 ? .high : .medium
                
                riskFactors.append(RiskFactor(
                    metricType: metricType,
                    severity: severity,
                    score: score,
                    description: generateRiskDescription(metricType, score)
                ))
            }
        }
        
        return riskFactors.sorted { $0.score < $1.score }
    }
    
    private func generateRiskDescription(_ metricType: MetricType, _ score: Double) -> String {
        switch metricType {
        case .heartRate:
            return score < 0.3 ? "Heart rate significantly outside normal range" : "Heart rate moderately elevated or low"
        case .heartRateVariability:
            return score < 0.3 ? "Very low heart rate variability indicating high stress" : "Low heart rate variability"
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return score < 0.3 ? "Blood pressure significantly elevated or low" : "Blood pressure outside optimal range"
        case .oxygenSaturation:
            return score < 0.3 ? "Low blood oxygen levels" : "Oxygen saturation below optimal"
        case .stressLevel:
            return score < 0.3 ? "Very high stress levels detected" : "Elevated stress levels"
        case .sleepQuality:
            return score < 0.3 ? "Poor sleep quality affecting health" : "Sleep quality below optimal"
        default:
            return "Metric outside healthy range"
        }
    }
    
    private func generateRecommendations(_ metricScores: [MetricType: Double]) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        for (metricType, score) in metricScores {
            if score < 0.7 {
                recommendations.append(contentsOf: generateMetricRecommendations(metricType, score))
            }
        }
        
        // Add general recommendations
        if metricScores.values.contains(where: { $0 < 0.6 }) {
            recommendations.append(HealthRecommendation(
                category: .lifestyle,
                priority: .medium,
                title: "Comprehensive Health Assessment",
                description: "Consider consulting with a healthcare provider for a comprehensive evaluation.",
                actionItems: [
                    "Schedule appointment with primary care physician",
                    "Prepare list of symptoms and concerns",
                    "Bring health data and trends"
                ]
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func generateMetricRecommendations(_ metricType: MetricType, _ score: Double) -> [HealthRecommendation] {
        switch metricType {
        case .heartRate:
            return [HealthRecommendation(
                category: .cardiovascular,
                priority: score < 0.4 ? .high : .medium,
                title: "Heart Rate Optimization",
                description: "Your heart rate patterns suggest room for improvement.",
                actionItems: [
                    "Engage in regular cardio exercise",
                    "Practice breathing exercises",
                    "Monitor caffeine intake"
                ]
            )]
            
        case .heartRateVariability:
            return [HealthRecommendation(
                category: .stress,
                priority: score < 0.4 ? .high : .medium,
                title: "Stress Management",
                description: "Low heart rate variability indicates increased stress.",
                actionItems: [
                    "Practice meditation or mindfulness",
                    "Ensure adequate sleep",
                    "Consider stress reduction techniques"
                ]
            )]
            
        case .sleepQuality:
            return [HealthRecommendation(
                category: .sleep,
                priority: .high,
                title: "Sleep Quality Improvement",
                description: "Your sleep quality could benefit from optimization.",
                actionItems: [
                    "Establish consistent sleep schedule",
                    "Optimize sleep environment",
                    "Limit screen time before bed"
                ]
            )]
            
        case .stressLevel:
            return [HealthRecommendation(
                category: .stress,
                priority: score < 0.4 ? .high : .medium,
                title: "Stress Reduction",
                description: "Elevated stress levels detected.",
                actionItems: [
                    "Practice regular relaxation techniques",
                    "Consider yoga or tai chi",
                    "Evaluate and reduce stressors"
                ]
            )]
            
        default:
            return []
        }
    }
}

// MARK: - Supporting Types

public struct MetricAnalytics: Sendable {
    public let metricType: MetricType
    public let statistics: MetricStatistics
    public let trends: [Trend]
    public let anomalies: [Anomaly]
    public let forecasts: [MetricForecast]
    public let lastUpdated: Date
}

public struct MetricStatistics: Sendable {
    public let sampleSize: Int
    public let mean: Double
    public let median: Double
    public let standardDeviation: Double
    public let minimum: Double
    public let maximum: Double
    public let percentile25: Double
    public let percentile75: Double
    public let trend: TrendDirection
    public let variance: Double
}

public enum TrendDirection: Sendable {
    case increasing
    case decreasing
    case stable
}

public struct MetricForecast: Sendable {
    public let date: Date
    public let predictedValue: Double
    public let confidence: Double
    public let bounds: (lower: Double, upper: Double)
}

public struct HealthScore: Sendable {
    public let overall: Double // 0-1
    public let confidence: Double // 0-1
    public let metricScores: [MetricType: Double]
    public let riskFactors: [RiskFactor]
    public let recommendations: [HealthRecommendation]
    public let timestamp: Date
}

public struct RiskFactor: Sendable {
    public let metricType: MetricType
    public let severity: RiskSeverity
    public let score: Double
    public let description: String
}

public enum RiskSeverity: Int, Sendable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public struct HealthRecommendation: Sendable {
    public enum Category: Sendable {
        case cardiovascular
        case stress
        case sleep
        case activity
        case nutrition
        case lifestyle
    }
    
    public enum Priority: Int, Sendable {
        case low = 1
        case medium = 2
        case high = 3
        case urgent = 4
    }
    
    public let category: Category
    public let priority: Priority
    public let title: String
    public let description: String
    public let actionItems: [String]
}

// MARK: - Helper Extensions

private extension Array where Element == Double {
    func mean() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
    
    func median() -> Double {
        guard !isEmpty else { return 0 }
        let sorted = self.sorted()
        let count = sorted.count
        
        if count.isMultiple(of: 2) {
            return (sorted[count / 2 - 1] + sorted[count / 2]) / 2
        } else {
            return sorted[count / 2]
        }
    }
    
    func standardDeviation() -> Double {
        let mean = self.mean()
        let variance = self.variance()
        return sqrt(variance)
    }
    
    func variance() -> Double {
        let mean = self.mean()
        let squaredDifferences = map { pow($0 - mean, 2) }
        return squaredDifferences.mean()
    }
    
    func percentile(_ p: Double) -> Double {
        guard !isEmpty, p >= 0, p <= 1 else { return 0 }
        let sorted = self.sorted()
        let index = p * Double(sorted.count - 1)
        let lowerIndex = Int(floor(index))
        let upperIndex = Int(ceil(index))
        
        if lowerIndex == upperIndex {
            return sorted[lowerIndex]
        } else {
            let weight = index - Double(lowerIndex)
            return sorted[lowerIndex] * (1 - weight) + sorted[upperIndex] * weight
        }
    }
}

// Additional supporting types would be defined here for TrendAnalyzer, AnomalyDetector, CorrelationMatrix, etc.