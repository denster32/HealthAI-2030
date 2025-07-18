import Foundation
import Numerics

/// Advanced trend analysis engine for health metrics
public actor TrendAnalyzer {
    private let metricType: MetricType
    private var dataPoints: [HealthMetric] = []
    private var currentTrends: [Trend] = []
    private let maxDataPoints = 1000
    private let minPointsForTrend = 5
    
    public init(metricType: MetricType) {
        self.metricType = metricType
    }
    
    // MARK: - Public Interface
    
    /// Add new data point for trend analysis
    public func addDataPoint(_ metric: HealthMetric) {
        guard metric.type == metricType else { return }
        
        dataPoints.append(metric)
        dataPoints.sort { $0.timestamp < $1.timestamp }
        
        // Maintain maximum data points
        if dataPoints.count > maxDataPoints {
            dataPoints.removeFirst(dataPoints.count - maxDataPoints)
        }
        
        // Update trends
        updateTrends()
    }
    
    /// Get current trends
    public func getCurrentTrends() -> [Trend] {
        return currentTrends
    }
    
    /// Analyze trends for a specific time period
    public func analyzeTrends(for period: TimeInterval) -> [Trend] {
        let cutoffDate = Date().addingTimeInterval(-period)
        let filteredData = dataPoints.filter { $0.timestamp >= cutoffDate }
        
        guard filteredData.count >= minPointsForTrend else { return [] }
        
        return detectTrends(in: filteredData)
    }
    
    /// Get trend strength for recent data
    public func getTrendStrength(for period: TimeInterval = 7 * 24 * 3600) -> Double {
        let recentTrends = analyzeTrends(for: period)
        return recentTrends.isEmpty ? 0.0 : recentTrends.map(\.strength).max() ?? 0.0
    }
    
    /// Predict future trend direction
    public func predictTrendDirection(lookahead: TimeInterval = 24 * 3600) -> TrendDirection {
        guard dataPoints.count >= minPointsForTrend else { return .stable }
        
        let recentData = dataPoints.suffix(20)
        let slope = calculateLinearSlope(Array(recentData))
        
        let threshold = calculateSlopeThreshold()
        
        if abs(slope) < threshold {
            return .stable
        } else if slope > 0 {
            return .increasing
        } else {
            return .decreasing
        }
    }
    
    // MARK: - Private Implementation
    
    private func updateTrends() {
        guard dataPoints.count >= minPointsForTrend else { return }
        
        // Analyze different time periods
        let periods: [TimeInterval] = [
            24 * 3600,      // 1 day
            7 * 24 * 3600,  // 1 week
            30 * 24 * 3600, // 1 month
            90 * 24 * 3600  // 3 months
        ]
        
        currentTrends = []
        
        for period in periods {
            let trends = analyzeTrends(for: period)
            currentTrends.append(contentsOf: trends)
        }
        
        // Remove duplicate trends and keep the strongest
        currentTrends = removeDuplicateTrends(currentTrends)
    }
    
    private func detectTrends(in data: [HealthMetric]) -> [Trend] {
        guard data.count >= minPointsForTrend else { return [] }
        
        var trends: [Trend] = []
        
        // Linear trend analysis
        if let linearTrend = detectLinearTrend(in: data) {
            trends.append(linearTrend)
        }
        
        // Volatility analysis
        if let volatilityTrend = detectVolatilityTrend(in: data) {
            trends.append(volatilityTrend)
        }
        
        // Seasonal trend analysis
        if let seasonalTrend = detectSeasonalTrend(in: data) {
            trends.append(seasonalTrend)
        }
        
        return trends
    }
    
    private func detectLinearTrend(in data: [HealthMetric]) -> Trend? {
        let slope = calculateLinearSlope(data)
        let correlation = calculateCorrelation(data)
        let threshold = calculateSlopeThreshold()
        
        guard abs(slope) > threshold && abs(correlation) > 0.3 else { return nil }
        
        let direction: TrendDirection = abs(slope) < threshold ? .stable :
                                      slope > 0 ? .increasing : .decreasing
        
        let strength = min(abs(correlation), 1.0)
        let confidence = calculateConfidence(slope: slope, correlation: correlation, dataCount: data.count)
        
        return Trend(
            direction: direction,
            strength: strength,
            duration: data.last!.timestamp.timeIntervalSince(data.first!.timestamp),
            confidence: confidence,
            startDate: data.first!.timestamp,
            endDate: data.last!.timestamp,
            description: generateTrendDescription(direction: direction, strength: strength, metricType: metricType)
        )
    }
    
    private func detectVolatilityTrend(in data: [HealthMetric]) -> Trend? {
        let volatility = calculateVolatility(data)
        let meanValue = data.map(\.value).reduce(0, +) / Double(data.count)
        let coefficientOfVariation = volatility / meanValue
        
        guard coefficientOfVariation > 0.2 else { return nil }
        
        return Trend(
            direction: .volatile,
            strength: min(coefficientOfVariation, 1.0),
            duration: data.last!.timestamp.timeIntervalSince(data.first!.timestamp),
            confidence: min(0.8, coefficientOfVariation),
            startDate: data.first!.timestamp,
            endDate: data.last!.timestamp,
            description: "High volatility detected in \(metricType.displayName.lowercased())"
        )
    }
    
    private func detectSeasonalTrend(in data: [HealthMetric]) -> Trend? {
        // Simple seasonal detection based on time of day patterns
        guard data.count >= 14 else { return nil } // Need at least 2 weeks of data
        
        let hourlyAverages = calculateHourlyAverages(data)
        let seasonality = calculateSeasonalityStrength(hourlyAverages)
        
        guard seasonality > 0.3 else { return nil }
        
        return Trend(
            direction: .stable,
            strength: seasonality,
            duration: data.last!.timestamp.timeIntervalSince(data.first!.timestamp),
            confidence: min(0.7, seasonality),
            startDate: data.first!.timestamp,
            endDate: data.last!.timestamp,
            description: "Seasonal pattern detected in \(metricType.displayName.lowercased())"
        )
    }
    
    private func calculateLinearSlope(_ data: [HealthMetric]) -> Double {
        let n = Double(data.count)
        guard n > 1 else { return 0.0 }
        
        let timeValues = data.enumerated().map { Double($0.offset) }
        let metricValues = data.map(\.value)
        
        let sumX = timeValues.reduce(0, +)
        let sumY = metricValues.reduce(0, +)
        let sumXY = zip(timeValues, metricValues).map(*).reduce(0, +)
        let sumXX = timeValues.map { $0 * $0 }.reduce(0, +)
        
        let denominator = n * sumXX - sumX * sumX
        guard denominator != 0 else { return 0.0 }
        
        return (n * sumXY - sumX * sumY) / denominator
    }
    
    private func calculateCorrelation(_ data: [HealthMetric]) -> Double {
        let n = Double(data.count)
        guard n > 1 else { return 0.0 }
        
        let timeValues = data.enumerated().map { Double($0.offset) }
        let metricValues = data.map(\.value)
        
        let meanX = timeValues.reduce(0, +) / n
        let meanY = metricValues.reduce(0, +) / n
        
        let numerator = zip(timeValues, metricValues)
            .map { (x, y) in (x - meanX) * (y - meanY) }
            .reduce(0, +)
        
        let sumXDiffSquared = timeValues.map { ($0 - meanX) * ($0 - meanX) }.reduce(0, +)
        let sumYDiffSquared = metricValues.map { ($0 - meanY) * ($0 - meanY) }.reduce(0, +)
        
        let denominator = sqrt(sumXDiffSquared * sumYDiffSquared)
        guard denominator != 0 else { return 0.0 }
        
        return numerator / denominator
    }
    
    private func calculateVolatility(_ data: [HealthMetric]) -> Double {
        let values = data.map(\.value)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    private func calculateSlopeThreshold() -> Double {
        // Threshold based on metric type's normal range
        let range = metricType.normalRange
        let rangeSize = range.upperBound - range.lowerBound
        return rangeSize * 0.01 // 1% of range
    }
    
    private func calculateConfidence(slope: Double, correlation: Double, dataCount: Int) -> Double {
        let slopeConfidence = min(abs(slope) * 10, 1.0)
        let correlationConfidence = abs(correlation)
        let dataConfidence = min(Double(dataCount) / 30.0, 1.0)
        
        return (slopeConfidence + correlationConfidence + dataConfidence) / 3.0
    }
    
    private func calculateHourlyAverages(_ data: [HealthMetric]) -> [Double] {
        var hourlyData: [Int: [Double]] = [:]
        
        for metric in data {
            let hour = Calendar.current.component(.hour, from: metric.timestamp)
            if hourlyData[hour] == nil {
                hourlyData[hour] = []
            }
            hourlyData[hour]?.append(metric.value)
        }
        
        var averages: [Double] = Array(repeating: 0.0, count: 24)
        for hour in 0..<24 {
            if let values = hourlyData[hour], !values.isEmpty {
                averages[hour] = values.reduce(0, +) / Double(values.count)
            }
        }
        
        return averages
    }
    
    private func calculateSeasonalityStrength(_ hourlyAverages: [Double]) -> Double {
        let mean = hourlyAverages.reduce(0, +) / Double(hourlyAverages.count)
        let variance = hourlyAverages.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(hourlyAverages.count)
        let standardDeviation = sqrt(variance)
        
        return min(standardDeviation / mean, 1.0)
    }
    
    private func removeDuplicateTrends(_ trends: [Trend]) -> [Trend] {
        var uniqueTrends: [Trend] = []
        
        for trend in trends {
            let isDuplicate = uniqueTrends.contains { existingTrend in
                existingTrend.direction == trend.direction &&
                abs(existingTrend.startDate.timeIntervalSince(trend.startDate)) < 3600 // Within 1 hour
            }
            
            if !isDuplicate {
                uniqueTrends.append(trend)
            } else if let index = uniqueTrends.firstIndex(where: { $0.direction == trend.direction }) {
                // Keep the stronger trend
                if trend.strength > uniqueTrends[index].strength {
                    uniqueTrends[index] = trend
                }
            }
        }
        
        return uniqueTrends.sorted { $0.strength > $1.strength }
    }
    
    private func generateTrendDescription(direction: TrendDirection, strength: Double, metricType: MetricType) -> String {
        let strengthDescription = strength > 0.7 ? "strong" : strength > 0.4 ? "moderate" : "weak"
        let metricName = metricType.displayName.lowercased()
        
        switch direction {
        case .increasing:
            return "Your \(metricName) shows a \(strengthDescription) increasing trend"
        case .decreasing:
            return "Your \(metricName) shows a \(strengthDescription) decreasing trend"
        case .stable:
            return "Your \(metricName) is remaining \(strengthDescription)ly stable"
        case .volatile:
            return "Your \(metricName) shows \(strengthDescription) volatility"
        }
    }
}