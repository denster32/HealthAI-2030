import Foundation
import Numerics

/// Advanced correlation analysis engine for health metrics relationships
public actor CorrelationMatrix {
    private var metricData: [MetricType: [HealthMetric]] = [:]
    private var correlationCache: [String: MetricCorrelation] = [:]
    private var lastUpdateTime: Date = Date()
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    private let minDataPointsForCorrelation = 10
    
    public init() {}
    
    // MARK: - Public Interface
    
    /// Add metric data for correlation analysis
    public func addMetricData(_ metric: HealthMetric) {
        if metricData[metric.type] == nil {
            metricData[metric.type] = []
        }
        metricData[metric.type]?.append(metric)
        
        // Maintain rolling window (keep last 90 days)
        let ninetyDaysAgo = Date().addingTimeInterval(-90 * 24 * 3600)
        metricData[metric.type]?.removeAll { $0.timestamp < ninetyDaysAgo }
        
        // Invalidate cache if significant time has passed
        if Date().timeIntervalSince(lastUpdateTime) > cacheExpirationInterval {
            correlationCache.removeAll()
            lastUpdateTime = Date()
        }
    }
    
    /// Calculate correlation between two metric types
    public func calculateCorrelation(between primary: MetricType, and secondary: MetricType) -> MetricCorrelation? {
        let cacheKey = correlationCacheKey(primary, secondary)
        
        // Check cache first
        if let cached = correlationCache[cacheKey] {
            return cached
        }
        
        guard let primaryData = metricData[primary],
              let secondaryData = metricData[secondary],
              primaryData.count >= minDataPointsForCorrelation,
              secondaryData.count >= minDataPointsForCorrelation else {
            return nil
        }
        
        // Find overlapping time periods
        let (primaryValues, secondaryValues) = findOverlappingData(primaryData, secondaryData)
        
        guard primaryValues.count >= minDataPointsForCorrelation else { return nil }
        
        let correlation = pearsonCorrelation(primaryValues, secondaryValues)
        let pValue = calculatePValue(correlation: correlation, sampleSize: primaryValues.count)
        let description = generateCorrelationDescription(primary, secondary, correlation)
        
        let result = MetricCorrelation(
            primaryMetric: primary,
            secondaryMetric: secondary,
            correlation: correlation,
            pValue: pValue,
            description: description
        )
        
        // Cache the result
        correlationCache[cacheKey] = result
        
        return result
    }
    
    /// Get all significant correlations for a specific metric
    public func getCorrelations(for metricType: MetricType, threshold: Double = 0.3) -> [MetricCorrelation] {
        var correlations: [MetricCorrelation] = []
        
        for otherMetricType in MetricType.allCases {
            guard otherMetricType != metricType else { continue }
            
            if let correlation = calculateCorrelation(between: metricType, and: otherMetricType),
               abs(correlation.correlation) >= threshold && correlation.pValue < 0.05 {
                correlations.append(correlation)
            }
        }
        
        return correlations.sorted { abs($0.correlation) > abs($1.correlation) }
    }
    
    /// Get the full correlation matrix for all available metrics
    public func getFullCorrelationMatrix() -> [[Double?]] {
        let allMetrics = Array(metricData.keys).sorted { $0.rawValue < $1.rawValue }
        var matrix: [[Double?]] = Array(repeating: Array(repeating: nil, count: allMetrics.count), count: allMetrics.count)
        
        for (i, primary) in allMetrics.enumerated() {
            for (j, secondary) in allMetrics.enumerated() {
                if i == j {
                    matrix[i][j] = 1.0 // Perfect correlation with self
                } else if let correlation = calculateCorrelation(between: primary, and: secondary) {
                    matrix[i][j] = correlation.correlation
                }
            }
        }
        
        return matrix
    }
    
    /// Find the strongest correlations across all metrics
    public func getStrongestCorrelations(limit: Int = 10, threshold: Double = 0.3) -> [MetricCorrelation] {
        var allCorrelations: [MetricCorrelation] = []
        let allMetrics = Array(metricData.keys)
        
        for i in 0..<allMetrics.count {
            for j in (i+1)..<allMetrics.count {
                if let correlation = calculateCorrelation(between: allMetrics[i], and: allMetrics[j]),
                   abs(correlation.correlation) >= threshold && correlation.pValue < 0.05 {
                    allCorrelations.append(correlation)
                }
            }
        }
        
        return Array(allCorrelations
            .sorted { abs($0.correlation) > abs($1.correlation) }
            .prefix(limit))
    }
    
    /// Detect potential causation relationships (not just correlation)
    public func detectPotentialCausation(primary: MetricType, secondary: MetricType, lagDays: Int = 1) -> CausationAnalysis? {
        guard let primaryData = metricData[primary],
              let secondaryData = metricData[secondary] else { return nil }
        
        // Calculate correlation with time lag
        let laggedCorrelation = calculateLaggedCorrelation(
            primary: primaryData,
            secondary: secondaryData,
            lagDays: lagDays
        )
        
        // Calculate reverse correlation
        let reverseCorrelation = calculateLaggedCorrelation(
            primary: secondaryData,
            secondary: primaryData,
            lagDays: lagDays
        )
        
        // Determine likely direction of causation
        let causationDirection = determineCausationDirection(
            forwardCorr: laggedCorrelation,
            reverseCorr: reverseCorrelation,
            primary: primary,
            secondary: secondary
        )
        
        return CausationAnalysis(
            primaryMetric: primary,
            secondaryMetric: secondary,
            forwardCorrelation: laggedCorrelation,
            reverseCorrelation: reverseCorrelation,
            suggestedDirection: causationDirection,
            confidence: calculateCausationConfidence(laggedCorrelation, reverseCorrelation),
            lagDays: lagDays
        )
    }
    
    /// Generate insights based on correlation patterns
    public func generateCorrelationInsights() -> [CorrelationInsight] {
        var insights: [CorrelationInsight] = []
        
        let strongCorrelations = getStrongestCorrelations(limit: 20, threshold: 0.5)
        
        for correlation in strongCorrelations {
            let insight = generateInsight(from: correlation)
            insights.append(insight)
        }
        
        // Add pattern-based insights
        insights.append(contentsOf: detectCorrelationPatterns())
        
        return insights.sorted { $0.importance > $1.importance }
    }
    
    // MARK: - Private Implementation
    
    private func findOverlappingData(_ primary: [HealthMetric], _ secondary: [HealthMetric]) -> ([Double], [Double]) {
        // Create time windows and find overlapping measurements
        let timeWindow: TimeInterval = 3600 // 1 hour window
        
        var primaryValues: [Double] = []
        var secondaryValues: [Double] = []
        
        for primaryMetric in primary {
            // Find secondary metrics within time window
            let matchingSecondary = secondary.filter { secondaryMetric in
                abs(secondaryMetric.timestamp.timeIntervalSince(primaryMetric.timestamp)) <= timeWindow
            }
            
            if let closestSecondary = matchingSecondary.min(by: { 
                abs($0.timestamp.timeIntervalSince(primaryMetric.timestamp)) < 
                abs($1.timestamp.timeIntervalSince(primaryMetric.timestamp))
            }) {
                primaryValues.append(primaryMetric.value)
                secondaryValues.append(closestSecondary.value)
            }
        }
        
        return (primaryValues, secondaryValues)
    }
    
    private func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0.0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumXX = x.map { $0 * $0 }.reduce(0, +)
        let sumYY = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumXX - sumX * sumX) * (n * sumYY - sumY * sumY))
        
        guard denominator != 0 else { return 0.0 }
        
        return numerator / denominator
    }
    
    private func calculatePValue(correlation: Double, sampleSize: Int) -> Double {
        // Simplified p-value calculation using t-distribution approximation
        guard sampleSize > 2 else { return 1.0 }
        
        let df = Double(sampleSize - 2)
        let tStatistic = correlation * sqrt(df / (1 - correlation * correlation))
        
        // Approximate p-value using t-distribution
        // This is a simplified calculation; in practice, you'd use a proper statistical library
        let pValue = 2 * (1 - approximateTCDF(abs(tStatistic), df: df))
        
        return max(0.0, min(1.0, pValue))
    }
    
    private func approximateTCDF(_ t: Double, df: Double) -> Double {
        // Simplified approximation of t-distribution CDF
        // For more accuracy, use a proper statistical library
        if df >= 30 {
            // Use normal approximation for large df
            return approximateNormalCDF(t)
        }
        
        // Very rough approximation for small df
        let x = t / sqrt(df + t * t)
        return 0.5 + 0.5 * x / (1 + abs(x))
    }
    
    private func approximateNormalCDF(_ x: Double) -> Double {
        // Simplified normal CDF approximation
        return 0.5 * (1 + erf(x / sqrt(2)))
    }
    
    private func erf(_ x: Double) -> Double {
        // Error function approximation
        let a1 = 0.254829592
        let a2 = -0.284496736
        let a3 = 1.421413741
        let a4 = -1.453152027
        let a5 = 1.061405429
        let p = 0.3275911
        
        let sign = x >= 0 ? 1.0 : -1.0
        let absX = abs(x)
        
        let t = 1.0 / (1.0 + p * absX)
        let y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-absX * absX)
        
        return sign * y
    }
    
    private func calculateLaggedCorrelation(primary: [HealthMetric], secondary: [HealthMetric], lagDays: Int) -> Double {
        let lagInterval = TimeInterval(lagDays * 24 * 3600)
        
        var laggedPairs: [(Double, Double)] = []
        
        for primaryMetric in primary {
            let targetTime = primaryMetric.timestamp.addingTimeInterval(lagInterval)
            
            if let matchingSecondary = secondary.min(by: { 
                abs($0.timestamp.timeIntervalSince(targetTime)) < 
                abs($1.timestamp.timeIntervalSince(targetTime))
            }), abs(matchingSecondary.timestamp.timeIntervalSince(targetTime)) < lagInterval / 2 {
                laggedPairs.append((primaryMetric.value, matchingSecondary.value))
            }
        }
        
        guard laggedPairs.count >= minDataPointsForCorrelation else { return 0.0 }
        
        let primaryValues = laggedPairs.map(\.0)
        let secondaryValues = laggedPairs.map(\.1)
        
        return pearsonCorrelation(primaryValues, secondaryValues)
    }
    
    private func determineCausationDirection(
        forwardCorr: Double,
        reverseCorr: Double,
        primary: MetricType,
        secondary: MetricType
    ) -> CausationDirection {
        let forwardStrength = abs(forwardCorr)
        let reverseStrength = abs(reverseCorr)
        
        // If correlations are similar, consider biological plausibility
        if abs(forwardStrength - reverseStrength) < 0.1 {
            return determineBiologicalPlausibility(primary: primary, secondary: secondary)
        }
        
        if forwardStrength > reverseStrength {
            return .primaryToSecondary
        } else if reverseStrength > forwardStrength {
            return .secondaryToPrimary
        } else {
            return .bidirectional
        }
    }
    
    private func determineBiologicalPlausibility(primary: MetricType, secondary: MetricType) -> CausationDirection {
        // Define known biological relationships
        let knownCausalRelationships: [(MetricType, MetricType)] = [
            (.stressLevel, .heartRate),
            (.exerciseMinutes, .heartRate),
            (.exerciseMinutes, .caloriesBurned),
            (.sleepDuration, .stressLevel),
            (.sleepQuality, .moodScore),
            (.waterIntake, .bodyTemperature),
            (.stressLevel, .bloodPressure)
        ]
        
        if knownCausalRelationships.contains(where: { $0.0 == primary && $0.1 == secondary }) {
            return .primaryToSecondary
        } else if knownCausalRelationships.contains(where: { $0.0 == secondary && $0.1 == primary }) {
            return .secondaryToPrimary
        } else {
            return .uncertain
        }
    }
    
    private func calculateCausationConfidence(_ forwardCorr: Double, _ reverseCorr: Double) -> Double {
        let maxCorr = max(abs(forwardCorr), abs(reverseCorr))
        let difference = abs(abs(forwardCorr) - abs(reverseCorr))
        
        // Higher confidence when there's a clear difference in correlation strength
        return min(maxCorr + difference, 1.0)
    }
    
    private func generateCorrelationDescription(_ primary: MetricType, _ secondary: MetricType, _ correlation: Double) -> String {
        let strength = CorrelationStrength.from(correlation: abs(correlation))
        let direction = correlation > 0 ? "positive" : "negative"
        
        return "There is a \(strength.displayName.lowercased()) \(direction) correlation between \(primary.displayName.lowercased()) and \(secondary.displayName.lowercased())"
    }
    
    private func generateInsight(from correlation: MetricCorrelation) -> CorrelationInsight {
        let strength = correlation.strength
        let isPositive = correlation.correlation > 0
        
        var insightText = ""
        var actionableAdvice = ""
        var importance = abs(correlation.correlation)
        
        // Generate context-specific insights
        switch (correlation.primaryMetric, correlation.secondaryMetric) {
        case (.stressLevel, .heartRate), (.heartRate, .stressLevel):
            insightText = "Your stress levels and heart rate show a \(strength.displayName.lowercased()) correlation"
            actionableAdvice = "Consider stress management techniques like meditation or deep breathing exercises"
            importance += 0.2
            
        case (.sleepDuration, .moodScore), (.moodScore, .sleepDuration):
            insightText = "Your sleep duration significantly impacts your mood"
            actionableAdvice = "Aim for consistent 7-9 hours of sleep to improve mood stability"
            importance += 0.3
            
        case (.exerciseMinutes, .sleepQuality), (.sleepQuality, .exerciseMinutes):
            insightText = "Regular exercise is correlated with better sleep quality"
            actionableAdvice = "Try to exercise earlier in the day for optimal sleep benefits"
            importance += 0.25
            
        default:
            insightText = correlation.description
            actionableAdvice = "Monitor these metrics together for better health insights"
        }
        
        return CorrelationInsight(
            primaryMetric: correlation.primaryMetric,
            secondaryMetric: correlation.secondaryMetric,
            correlation: correlation.correlation,
            insight: insightText,
            actionableAdvice: actionableAdvice,
            importance: importance,
            confidence: 1.0 - correlation.pValue
        )
    }
    
    private func detectCorrelationPatterns() -> [CorrelationInsight] {
        var patternInsights: [CorrelationInsight] = []
        
        // Detect metric clusters (groups of highly correlated metrics)
        let clusters = detectMetricClusters()
        for cluster in clusters {
            if cluster.count >= 3 {
                let insight = CorrelationInsight(
                    primaryMetric: cluster[0],
                    secondaryMetric: cluster[1],
                    correlation: 0.8, // Estimated cluster correlation
                    insight: "Multiple health metrics are showing coordinated patterns",
                    actionableAdvice: "Focus on improving one key metric to positively impact the entire cluster",
                    importance: 0.9,
                    confidence: 0.8
                )
                patternInsights.append(insight)
            }
        }
        
        return patternInsights
    }
    
    private func detectMetricClusters() -> [[MetricType]] {
        // Simple clustering based on correlation strength
        var clusters: [[MetricType]] = []
        var processed: Set<MetricType> = []
        
        for metric in metricData.keys {
            guard !processed.contains(metric) else { continue }
            
            var cluster = [metric]
            processed.insert(metric)
            
            for otherMetric in metricData.keys {
                guard !processed.contains(otherMetric) else { continue }
                
                if let correlation = calculateCorrelation(between: metric, and: otherMetric),
                   abs(correlation.correlation) > 0.6 {
                    cluster.append(otherMetric)
                    processed.insert(otherMetric)
                }
            }
            
            if cluster.count > 1 {
                clusters.append(cluster)
            }
        }
        
        return clusters
    }
    
    private func correlationCacheKey(_ primary: MetricType, _ secondary: MetricType) -> String {
        let sorted = [primary.rawValue, secondary.rawValue].sorted()
        return "\(sorted[0])_\(sorted[1])"
    }
}

// MARK: - Supporting Types

/// Analysis of potential causation between metrics
public struct CausationAnalysis: Codable {
    public let primaryMetric: MetricType
    public let secondaryMetric: MetricType
    public let forwardCorrelation: Double
    public let reverseCorrelation: Double
    public let suggestedDirection: CausationDirection
    public let confidence: Double
    public let lagDays: Int
    
    public init(
        primaryMetric: MetricType,
        secondaryMetric: MetricType,
        forwardCorrelation: Double,
        reverseCorrelation: Double,
        suggestedDirection: CausationDirection,
        confidence: Double,
        lagDays: Int
    ) {
        self.primaryMetric = primaryMetric
        self.secondaryMetric = secondaryMetric
        self.forwardCorrelation = forwardCorrelation
        self.reverseCorrelation = reverseCorrelation
        self.suggestedDirection = suggestedDirection
        self.confidence = confidence
        self.lagDays = lagDays
    }
}

/// Direction of potential causation
public enum CausationDirection: String, Codable, CaseIterable {
    case primaryToSecondary = "primary_to_secondary"
    case secondaryToPrimary = "secondary_to_primary"
    case bidirectional = "bidirectional"
    case uncertain = "uncertain"
    
    public var displayName: String {
        switch self {
        case .primaryToSecondary: return "Primary → Secondary"
        case .secondaryToPrimary: return "Secondary → Primary"
        case .bidirectional: return "Bidirectional"
        case .uncertain: return "Uncertain"
        }
    }
}

/// Actionable insight based on correlation analysis
public struct CorrelationInsight: Codable, Identifiable {
    public let id = UUID()
    public let primaryMetric: MetricType
    public let secondaryMetric: MetricType
    public let correlation: Double
    public let insight: String
    public let actionableAdvice: String
    public let importance: Double  // 0.0 to 1.0
    public let confidence: Double  // 0.0 to 1.0
    
    public init(
        primaryMetric: MetricType,
        secondaryMetric: MetricType,
        correlation: Double,
        insight: String,
        actionableAdvice: String,
        importance: Double,
        confidence: Double
    ) {
        self.primaryMetric = primaryMetric
        self.secondaryMetric = secondaryMetric
        self.correlation = correlation
        self.insight = insight
        self.actionableAdvice = actionableAdvice
        self.importance = importance
        self.confidence = confidence
    }
}