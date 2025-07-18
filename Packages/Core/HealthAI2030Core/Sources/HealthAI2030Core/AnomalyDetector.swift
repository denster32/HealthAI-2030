import Foundation
import Numerics

/// Advanced anomaly detection engine for health metrics
public actor AnomalyDetector {
    private let metricType: MetricType
    private var dataPoints: [HealthMetric] = []
    private var detectedAnomalies: [Anomaly] = []
    private let maxDataPoints = 1000
    private let minPointsForDetection = 10
    
    // Detection parameters
    private let zScoreThreshold: Double = 2.5
    private let iqrMultiplier: Double = 1.5
    private let madThreshold: Double = 3.0
    
    public init(metricType: MetricType) {
        self.metricType = metricType
    }
    
    // MARK: - Public Interface
    
    /// Add new data point for anomaly detection
    public func addDataPoint(_ metric: HealthMetric) {
        guard metric.type == metricType else { return }
        
        dataPoints.append(metric)
        dataPoints.sort { $0.timestamp < $1.timestamp }
        
        // Maintain maximum data points
        if dataPoints.count > maxDataPoints {
            dataPoints.removeFirst(dataPoints.count - maxDataPoints)
        }
        
        // Check for anomalies in real-time
        if dataPoints.count >= minPointsForDetection {
            checkForAnomalies(newPoint: metric)
        }
    }
    
    /// Get recent anomalies
    public func getRecentAnomalies(within timeInterval: TimeInterval = 7 * 24 * 3600) -> [Anomaly] {
        let cutoffDate = Date().addingTimeInterval(-timeInterval)
        return detectedAnomalies.filter { $0.timestamp >= cutoffDate }
    }
    
    /// Get all detected anomalies
    public func getAllAnomalies() -> [Anomaly] {
        return detectedAnomalies
    }
    
    /// Analyze data points for anomalies using multiple methods
    public func analyzeAnomalies() -> [Anomaly] {
        guard dataPoints.count >= minPointsForDetection else { return [] }
        
        var anomalies: [Anomaly] = []
        
        // Z-Score based detection
        anomalies.append(contentsOf: detectZScoreAnomalies())
        
        // IQR based detection
        anomalies.append(contentsOf: detectIQRAnomalies())
        
        // MAD (Median Absolute Deviation) based detection
        anomalies.append(contentsOf: detectMADAnomalies())
        
        // Isolation Forest-like detection
        anomalies.append(contentsOf: detectIsolationAnomalies())
        
        // Context-aware detection
        anomalies.append(contentsOf: detectContextualAnomalies())
        
        // Remove duplicates and merge similar anomalies
        return mergeSimilarAnomalies(anomalies)
    }
    
    /// Get anomaly score for a specific value
    public func getAnomalyScore(for value: Double) -> Double {
        guard dataPoints.count >= minPointsForDetection else { return 0.0 }
        
        let scores = [
            calculateZScore(value),
            calculateIQRScore(value),
            calculateMADScore(value),
            calculateIsolationScore(value)
        ]
        
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    // MARK: - Private Implementation
    
    private func checkForAnomalies(newPoint: HealthMetric) {
        let anomalies = analyzeAnomalies()
        
        // Check if the new point is anomalous
        for anomaly in anomalies {
            if abs(anomaly.timestamp.timeIntervalSince(newPoint.timestamp)) < 60 { // Within 1 minute
                if !detectedAnomalies.contains(where: { existing in
                    abs(existing.timestamp.timeIntervalSince(anomaly.timestamp)) < 300 // Within 5 minutes
                }) {
                    detectedAnomalies.append(anomaly)
                }
            }
        }
        
        // Clean up old anomalies (keep last 30 days)
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
        detectedAnomalies.removeAll { $0.timestamp < thirtyDaysAgo }
    }
    
    // MARK: - Z-Score Detection
    
    private func detectZScoreAnomalies() -> [Anomaly] {
        let values = dataPoints.map(\.value)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        guard standardDeviation > 0 else { return [] }
        
        var anomalies: [Anomaly] = []
        
        for point in dataPoints {
            let zScore = abs(point.value - mean) / standardDeviation
            if zScore > zScoreThreshold {
                let anomaly = createAnomaly(
                    point: point,
                    score: min(zScore / 5.0, 1.0),
                    method: "Z-Score",
                    threshold: zScoreThreshold
                )
                anomalies.append(anomaly)
            }
        }
        
        return anomalies
    }
    
    // MARK: - IQR Detection
    
    private func detectIQRAnomalies() -> [Anomaly] {
        let values = dataPoints.map(\.value).sorted()
        guard values.count >= 4 else { return [] }
        
        let q1Index = values.count / 4
        let q3Index = 3 * values.count / 4
        let q1 = values[q1Index]
        let q3 = values[q3Index]
        let iqr = q3 - q1
        
        let lowerBound = q1 - iqrMultiplier * iqr
        let upperBound = q3 + iqrMultiplier * iqr
        
        var anomalies: [Anomaly] = []
        
        for point in dataPoints {
            if point.value < lowerBound || point.value > upperBound {
                let distanceFromBound = min(abs(point.value - lowerBound), abs(point.value - upperBound))
                let score = min(distanceFromBound / iqr, 1.0)
                
                let anomaly = createAnomaly(
                    point: point,
                    score: score,
                    method: "IQR",
                    threshold: iqrMultiplier
                )
                anomalies.append(anomaly)
            }
        }
        
        return anomalies
    }
    
    // MARK: - MAD Detection
    
    private func detectMADAnomalies() -> [Anomaly] {
        let values = dataPoints.map(\.value).sorted()
        guard values.count >= minPointsForDetection else { return [] }
        
        let median = calculateMedian(values)
        let absoluteDeviations = values.map { abs($0 - median) }.sorted()
        let mad = calculateMedian(absoluteDeviations)
        
        guard mad > 0 else { return [] }
        
        var anomalies: [Anomaly] = []
        
        for point in dataPoints {
            let modifiedZScore = 0.6745 * abs(point.value - median) / mad
            if modifiedZScore > madThreshold {
                let anomaly = createAnomaly(
                    point: point,
                    score: min(modifiedZScore / 5.0, 1.0),
                    method: "MAD",
                    threshold: madThreshold
                )
                anomalies.append(anomaly)
            }
        }
        
        return anomalies
    }
    
    // MARK: - Isolation-based Detection
    
    private func detectIsolationAnomalies() -> [Anomaly] {
        // Simplified isolation forest approach
        var anomalies: [Anomaly] = []
        
        for (index, point) in dataPoints.enumerated() {
            let isolationScore = calculateIsolationScore(point, atIndex: index)
            if isolationScore > 0.7 {
                let anomaly = createAnomaly(
                    point: point,
                    score: isolationScore,
                    method: "Isolation",
                    threshold: 0.7
                )
                anomalies.append(anomaly)
            }
        }
        
        return anomalies
    }
    
    // MARK: - Contextual Anomaly Detection
    
    private func detectContextualAnomalies() -> [Anomaly] {
        var anomalies: [Anomaly] = []
        
        // Time-based contextual anomalies
        let timeBasedAnomalies = detectTimeBasedAnomalies()
        anomalies.append(contentsOf: timeBasedAnomalies)
        
        // Trend-based contextual anomalies
        let trendBasedAnomalies = detectTrendBasedAnomalies()
        anomalies.append(contentsOf: trendBasedAnomalies)
        
        return anomalies
    }
    
    private func detectTimeBasedAnomalies() -> [Anomaly] {
        // Detect anomalies based on time patterns (e.g., unusual values at specific times)
        var anomalies: [Anomaly] = []
        
        // Group by hour of day
        var hourlyData: [Int: [HealthMetric]] = [:]
        for point in dataPoints {
            let hour = Calendar.current.component(.hour, from: point.timestamp)
            if hourlyData[hour] == nil {
                hourlyData[hour] = []
            }
            hourlyData[hour]?.append(point)
        }
        
        // Check for anomalies within each hour group
        for (hour, points) in hourlyData {
            guard points.count >= 3 else { continue }
            
            let values = points.map(\.value)
            let mean = values.reduce(0, +) / Double(values.count)
            let std = sqrt(values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count))
            
            for point in points {
                if std > 0 && abs(point.value - mean) / std > 2.0 {
                    let anomaly = Anomaly(
                        metricType: metricType,
                        value: point.value,
                        timestamp: point.timestamp,
                        anomalyScore: min(abs(point.value - mean) / std / 3.0, 1.0),
                        description: "Unusual \(metricType.displayName.lowercased()) value for hour \(hour)",
                        severity: determineSeverity(point.value),
                        possibleCauses: generateTimeBasedCauses(hour: hour)
                    )
                    anomalies.append(anomaly)
                }
            }
        }
        
        return anomalies
    }
    
    private func detectTrendBasedAnomalies() -> [Anomaly] {
        // Detect sudden spikes or drops that break established trends
        var anomalies: [Anomaly] = []
        
        guard dataPoints.count >= 5 else { return anomalies }
        
        for i in 2..<dataPoints.count-1 {
            let current = dataPoints[i]
            let previous = dataPoints[i-1]
            let next = dataPoints[i+1]
            
            let prevChange = current.value - previous.value
            let nextChange = next.value - current.value
            
            // Detect spikes (sudden increase followed by decrease)
            if prevChange > 0 && nextChange < 0 {
                let spikeIntensity = min(prevChange, abs(nextChange))
                let normalRange = metricType.normalRange
                let rangeSize = normalRange.upperBound - normalRange.lowerBound
                
                if spikeIntensity > rangeSize * 0.1 { // 10% of normal range
                    let anomaly = Anomaly(
                        metricType: metricType,
                        value: current.value,
                        timestamp: current.timestamp,
                        anomalyScore: min(spikeIntensity / rangeSize, 1.0),
                        description: "Sudden spike detected in \(metricType.displayName.lowercased())",
                        severity: determineSeverity(current.value),
                        possibleCauses: generateSpikeCauses()
                    )
                    anomalies.append(anomaly)
                }
            }
        }
        
        return anomalies
    }
    
    // MARK: - Utility Methods
    
    private func calculateZScore(_ value: Double) -> Double {
        let values = dataPoints.map(\.value)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        guard standardDeviation > 0 else { return 0.0 }
        return abs(value - mean) / standardDeviation / zScoreThreshold
    }
    
    private func calculateIQRScore(_ value: Double) -> Double {
        let values = dataPoints.map(\.value).sorted()
        guard values.count >= 4 else { return 0.0 }
        
        let q1 = values[values.count / 4]
        let q3 = values[3 * values.count / 4]
        let iqr = q3 - q1
        
        let lowerBound = q1 - iqrMultiplier * iqr
        let upperBound = q3 + iqrMultiplier * iqr
        
        if value >= lowerBound && value <= upperBound {
            return 0.0
        }
        
        let distance = min(abs(value - lowerBound), abs(value - upperBound))
        return min(distance / iqr, 1.0)
    }
    
    private func calculateMADScore(_ value: Double) -> Double {
        let values = dataPoints.map(\.value).sorted()
        let median = calculateMedian(values)
        let absoluteDeviations = values.map { abs($0 - median) }.sorted()
        let mad = calculateMedian(absoluteDeviations)
        
        guard mad > 0 else { return 0.0 }
        
        let modifiedZScore = 0.6745 * abs(value - median) / mad
        return min(modifiedZScore / madThreshold, 1.0)
    }
    
    private func calculateIsolationScore(_ value: Double) -> Double {
        // Simplified isolation score based on distance to nearest neighbors
        let values = dataPoints.map(\.value)
        let distances = values.map { abs($0 - value) }.sorted()
        
        guard distances.count > 1 else { return 0.0 }
        
        let nearestDistance = distances[1] // Skip self (distance 0)
        let medianDistance = calculateMedian(distances)
        
        return min(nearestDistance / medianDistance, 1.0)
    }
    
    private func calculateIsolationScore(_ point: HealthMetric, atIndex index: Int) -> Double {
        let windowSize = min(10, dataPoints.count / 2)
        let start = max(0, index - windowSize)
        let end = min(dataPoints.count, index + windowSize + 1)
        
        let neighbors = Array(dataPoints[start..<end])
        let values = neighbors.map(\.value)
        
        let distances = values.map { abs($0 - point.value) }.sorted()
        guard distances.count > 1 else { return 0.0 }
        
        let averageDistance = distances.prefix(min(5, distances.count)).reduce(0, +) / Double(min(5, distances.count))
        let maxDistance = distances.max() ?? 1.0
        
        return min(averageDistance / maxDistance, 1.0)
    }
    
    private func calculateMedian(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let count = sorted.count
        
        if count % 2 == 0 {
            return (sorted[count/2 - 1] + sorted[count/2]) / 2.0
        } else {
            return sorted[count/2]
        }
    }
    
    private func createAnomaly(point: HealthMetric, score: Double, method: String, threshold: Double) -> Anomaly {
        return Anomaly(
            metricType: metricType,
            value: point.value,
            timestamp: point.timestamp,
            anomalyScore: score,
            description: "Anomaly detected using \(method) method",
            severity: determineSeverity(point.value),
            possibleCauses: generatePossibleCauses(method: method, value: point.value)
        )
    }
    
    private func determineSeverity(_ value: Double) -> SeverityLevel {
        let normalRange = metricType.normalRange
        
        if normalRange.contains(value) {
            return .normal
        }
        
        let deviation = value < normalRange.lowerBound ?
            (normalRange.lowerBound - value) / normalRange.lowerBound :
            (value - normalRange.upperBound) / normalRange.upperBound
        
        return deviation > 0.3 ? .critical : .warning
    }
    
    private func generatePossibleCauses(method: String, value: Double) -> [String] {
        var causes: [String] = []
        
        // Generic causes based on metric type
        switch metricType {
        case .heartRate:
            causes = ["Physical activity", "Stress", "Caffeine", "Medication", "Sleep quality"]
        case .bloodPressure:
            causes = ["Salt intake", "Stress", "Physical activity", "Medication", "Dehydration"]
        case .bloodOxygen:
            causes = ["Respiratory issues", "High altitude", "Exercise", "Sleep apnea"]
        case .sleepDuration:
            causes = ["Schedule changes", "Stress", "Caffeine", "Environment", "Health issues"]
        case .stressLevel:
            causes = ["Work pressure", "Personal issues", "Health concerns", "Environmental factors"]
        default:
            causes = ["Lifestyle changes", "Health conditions", "External factors", "Measurement error"]
        }
        
        // Add method-specific context
        if method == "Z-Score" {
            causes.append("Statistical outlier")
        } else if method == "IQR" {
            causes.append("Value outside typical range")
        }
        
        return causes
    }
    
    private func generateTimeBasedCauses(hour: Int) -> [String] {
        if hour >= 22 || hour <= 6 {
            return ["Sleep-related factors", "Night shift work", "Late activity"]
        } else if hour >= 7 && hour <= 9 {
            return ["Morning routine changes", "Breakfast impact", "Commute stress"]
        } else if hour >= 12 && hour <= 14 {
            return ["Lunch impact", "Midday activity", "Work stress"]
        } else {
            return ["Daily activity", "Work factors", "Environmental changes"]
        }
    }
    
    private func generateSpikeCauses() -> [String] {
        switch metricType {
        case .heartRate:
            return ["Sudden physical activity", "Startle response", "Caffeine effect"]
        case .bloodPressure:
            return ["Sudden stress", "Physical exertion", "Medication effect"]
        case .stressLevel:
            return ["Acute stressor", "Unexpected event", "Anxiety episode"]
        default:
            return ["Sudden change", "Acute event", "External trigger"]
        }
    }
    
    private func mergeSimilarAnomalies(_ anomalies: [Anomaly]) -> [Anomaly] {
        var merged: [Anomaly] = []
        
        for anomaly in anomalies.sorted(by: { $0.timestamp < $1.timestamp }) {
            let isDuplicate = merged.contains { existing in
                abs(existing.timestamp.timeIntervalSince(anomaly.timestamp)) < 300 && // Within 5 minutes
                abs(existing.value - anomaly.value) < metricType.normalRange.upperBound * 0.05 // Within 5% of range
            }
            
            if !isDuplicate {
                merged.append(anomaly)
            }
        }
        
        return merged
    }
}