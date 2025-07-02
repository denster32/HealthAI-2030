import Foundation
import Accelerate

class QTDynamicAnalyzer {
    
    // MARK: - Constants
    private let qtWindowSize = 30 // Number of beats for QT analysis
    private let minRRInterval = 0.3 // Minimum RR interval in seconds
    private let maxRRInterval = 1.5 // Maximum RR interval in seconds
    private let normalQTSlope = 0.15...0.25 // Normal QT-RR slope range
    private let circadianPeriods = 4 // Number of circadian periods to analyze
    
    // MARK: - Public Interface
    
    /// Analyze QT dynamics and detect drug/electrolyte imbalances
    func analyzeQTDynamics(ecgData: ProcessedECGData, completion: @escaping (Result<ECGInsight, Error>) -> Void) {
        print("QT Dynamic Analyzer: Starting analysis...")
        
        // Extract QRS complexes and intervals
        let qrsComplexes = extractQRSComplexes(from: ecgData)
        let rrIntervals = extractRRIntervals(from: qrsComplexes)
        let qtIntervals = extractQTIntervals(from: qrsComplexes)
        
        // Validate data quality
        guard validateDataQuality(rrIntervals: rrIntervals, qtIntervals: qtIntervals) else {
            completion(.failure(QTDynamicError.insufficientData))
            return
        }
        
        // Calculate QT-RR relationships
        let qtRrData = calculateQTRRData(rrIntervals: rrIntervals, qtIntervals: qtIntervals)
        
        // Analyze circadian patterns
        let circadianAnalysis = analyzeCircadianPatterns(qtRrData: qtRrData)
        
        // Detect abnormalities
        let abnormalities = detectAbnormalities(qtRrData: qtRrData, circadianAnalysis: circadianAnalysis)
        
        // Assess overall risk
        let riskAssessment = assessRisk(abnormalities: abnormalities, qtRrData: qtRrData)
        
        // Create insight
        let insight = ECGInsight(
            type: .qtDynamics,
            severity: severityForRisk(riskAssessment),
            confidence: calculateConfidence(qtRrData: qtRrData),
            description: generateDescription(riskAssessment: riskAssessment, abnormalities: abnormalities),
            timestamp: Date(),
            data: QTDynamicData(
                averageSlope: qtRrData.averageSlope,
                slopeVariability: qtRrData.slopeVariability,
                circadianVariation: circadianAnalysis.variation,
                abnormalityCount: abnormalities.count,
                riskScore: riskAssessment,
                qtDispersion: calculateQTDispersion(qtIntervals: qtIntervals)
            )
        )
        
        completion(.success(insight))
    }
    
    /// Get current QT dynamic metrics
    func getCurrentQTDynamics() -> QTRRData {
        // Return cached metrics if available
        return QTRRData(
            averageSlope: 0.0,
            slopeVariability: 0.0,
            correlation: 0.0,
            dataPoints: []
        )
    }
    
    // MARK: - Private Methods
    
    private func extractQRSComplexes(from ecgData: ProcessedECGData) -> [QRSComplex] {
        let processor = ECGDataProcessor()
        return processor.extractQRSComplexes(ecgData)
    }
    
    private func extractRRIntervals(from qrsComplexes: [QRSComplex]) -> [RRInterval] {
        let processor = ECGDataProcessor()
        return processor.extractRRIntervals(qrsComplexes)
    }
    
    private func extractQTIntervals(from qrsComplexes: [QRSComplex]) -> [QTInterval] {
        let processor = ECGDataProcessor()
        return processor.extractQTIntervals(qrsComplexes)
    }
    
    private func validateDataQuality(rrIntervals: [RRInterval], qtIntervals: [QTInterval]) -> Bool {
        // Check if we have sufficient data
        guard rrIntervals.count >= qtWindowSize && qtIntervals.count >= qtWindowSize else {
            print("QT Dynamic Analyzer: Insufficient data for analysis")
            return false
        }
        
        // Check for valid RR intervals
        let validRRCount = rrIntervals.filter { interval in
            interval.interval >= minRRInterval && interval.interval <= maxRRInterval
        }.count
        
        let rrQuality = Double(validRRCount) / Double(rrIntervals.count)
        
        // Check for valid QT intervals
        let validQTCount = qtIntervals.filter { interval in
            interval.duration >= 0.2 && interval.duration <= 0.6 // Normal QT range
        }.count
        
        let qtQuality = Double(validQTCount) / Double(qtIntervals.count)
        
        // Require at least 70% quality for both
        return rrQuality >= 0.7 && qtQuality >= 0.7
    }
    
    private func calculateQTRRData(rrIntervals: [RRInterval], qtIntervals: [QTInterval]) -> QTRRData {
        var dataPoints: [QTRRPoint] = []
        
        // Match RR and QT intervals by timestamp
        for rrInterval in rrIntervals {
            if let matchingQT = findMatchingQTInterval(rrInterval: rrInterval, qtIntervals: qtIntervals) {
                let dataPoint = QTRRPoint(
                    rrInterval: rrInterval.interval,
                    qtInterval: matchingQT.duration,
                    timestamp: rrInterval.timestamp,
                    index: rrInterval.index
                )
                dataPoints.append(dataPoint)
            }
        }
        
        // Calculate overall slope and correlation
        let slope = calculateLinearRegressionSlope(dataPoints: dataPoints)
        let correlation = calculateCorrelation(dataPoints: dataPoints)
        let variability = calculateSlopeVariability(dataPoints: dataPoints)
        
        return QTRRData(
            averageSlope: slope,
            slopeVariability: variability,
            correlation: correlation,
            dataPoints: dataPoints
        )
    }
    
    private func findMatchingQTInterval(rrInterval: RRInterval, qtIntervals: [QTInterval]) -> QTInterval? {
        // Find QT interval that matches the RR interval timestamp
        return qtIntervals.first { qtInterval in
            abs(qtInterval.startTime - rrInterval.timestamp) < 0.1 // Within 100ms
        }
    }
    
    private func calculateLinearRegressionSlope(dataPoints: [QTRRPoint]) -> Double {
        guard dataPoints.count > 1 else { return 0.0 }
        
        let xValues = dataPoints.map { $0.rrInterval }
        let yValues = dataPoints.map { $0.qtInterval }
        
        let n = Double(dataPoints.count)
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map { $0 * $1 }.reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = n * sumX2 - sumX * sumX
        
        guard denominator != 0 else { return 0.0 }
        
        return numerator / denominator
    }
    
    private func calculateCorrelation(dataPoints: [QTRRPoint]) -> Double {
        guard dataPoints.count > 1 else { return 0.0 }
        
        let xValues = dataPoints.map { $0.rrInterval }
        let yValues = dataPoints.map { $0.qtInterval }
        
        let n = Double(dataPoints.count)
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map { $0 * $1 }.reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)
        let sumY2 = yValues.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        guard denominator != 0 else { return 0.0 }
        
        return numerator / denominator
    }
    
    private func calculateSlopeVariability(dataPoints: [QTRRPoint]) -> Double {
        guard dataPoints.count >= qtWindowSize else { return 0.0 }
        
        var slopes: [Double] = []
        
        // Calculate slopes for sliding windows
        for i in 0...(dataPoints.count - qtWindowSize) {
            let window = Array(dataPoints[i..<i + qtWindowSize])
            let slope = calculateLinearRegressionSlope(dataPoints: window)
            slopes.append(slope)
        }
        
        // Calculate coefficient of variation
        let meanSlope = slopes.reduce(0, +) / Double(slopes.count)
        let variance = slopes.map { pow($0 - meanSlope, 2) }.reduce(0, +) / Double(slopes.count)
        let stdDev = sqrt(variance)
        
        return stdDev / (meanSlope + 1e-10)
    }
    
    private func analyzeCircadianPatterns(qtRrData: QTRRData) -> CircadianAnalysis {
        let dataPoints = qtRrData.dataPoints
        
        // Group data points by time of day (simplified to 6-hour periods)
        var periodData: [Int: [QTRRPoint]] = [:]
        
        for point in dataPoints {
            let hour = Calendar.current.component(.hour, from: Date(timeIntervalSince1970: point.timestamp))
            let period = hour / 6 // 0-5, 6-11, 12-17, 18-23
            periodData[period, default: []].append(point)
        }
        
        // Calculate slopes for each period
        var periodSlopes: [Double] = []
        for period in 0..<circadianPeriods {
            if let periodPoints = periodData[period], periodPoints.count >= 5 {
                let slope = calculateLinearRegressionSlope(dataPoints: periodPoints)
                periodSlopes.append(slope)
            }
        }
        
        // Calculate circadian variation
        let variation = calculateCircadianVariation(slopes: periodSlopes)
        
        return CircadianAnalysis(
            periodSlopes: periodSlopes,
            variation: variation,
            hasCircadianPattern: variation > 0.1
        )
    }
    
    private func calculateCircadianVariation(slopes: [Double]) -> Double {
        guard slopes.count > 1 else { return 0.0 }
        
        let mean = slopes.reduce(0, +) / Double(slopes.count)
        let variance = slopes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(slopes.count)
        
        return sqrt(variance)
    }
    
    private func detectAbnormalities(qtRrData: QTRRData, circadianAnalysis: CircadianAnalysis) -> [QTAbnormality] {
        var abnormalities: [QTAbnormality] = []
        
        // Check for flattened slope (drug effect)
        if qtRrData.averageSlope < normalQTSlope.lowerBound {
            abnormalities.append(QTAbnormality(
                type: .flattenedSlope,
                severity: severityForSlopeDeviation(qtRrData.averageSlope),
                description: "QT-RR slope flattened (\(String(format: "%.3f", qtRrData.averageSlope)))",
                confidence: qtRrData.correlation
            ))
        }
        
        // Check for steep slope (electrolyte imbalance)
        if qtRrData.averageSlope > normalQTSlope.upperBound {
            abnormalities.append(QTAbnormality(
                type: .steepSlope,
                severity: severityForSlopeDeviation(qtRrData.averageSlope),
                description: "QT-RR slope steepened (\(String(format: "%.3f", qtRrData.averageSlope)))",
                confidence: qtRrData.correlation
            ))
        }
        
        // Check for high slope variability
        if qtRrData.slopeVariability > 0.5 {
            abnormalities.append(QTAbnormality(
                type: .highVariability,
                severity: .moderate,
                description: "High QT-RR slope variability (\(String(format: "%.3f", qtRrData.slopeVariability)))",
                confidence: 0.7
            ))
        }
        
        // Check for loss of circadian pattern
        if !circadianAnalysis.hasCircadianPattern {
            abnormalities.append(QTAbnormality(
                type: .lossOfCircadianPattern,
                severity: .mild,
                description: "Loss of normal circadian QT-RR variation",
                confidence: 0.6
            ))
        }
        
        // Check for poor correlation
        if qtRrData.correlation < 0.3 {
            abnormalities.append(QTAbnormality(
                type: .poorCorrelation,
                severity: .moderate,
                description: "Poor QT-RR correlation (\(String(format: "%.3f", qtRrData.correlation)))",
                confidence: 0.8
            ))
        }
        
        return abnormalities
    }
    
    private func severityForSlopeDeviation(_ slope: Double) -> InsightSeverity {
        let deviation = abs(slope - (normalQTSlope.lowerBound + normalQTSlope.upperBound) / 2.0)
        let maxDeviation = (normalQTSlope.upperBound - normalQTSlope.lowerBound) / 2.0
        let normalizedDeviation = deviation / maxDeviation
        
        switch normalizedDeviation {
        case 0.0..<0.5:
            return .mild
        case 0.5..<1.0:
            return .moderate
        case 1.0..<1.5:
            return .severe
        default:
            return .critical
        }
    }
    
    private func assessRisk(abnormalities: [QTAbnormality], qtRrData: QTRRData) -> Double {
        guard !abnormalities.isEmpty else { return 0.0 }
        
        // Calculate risk based on abnormality severity and count
        let severityScores = abnormalities.map { abnormality in
            Double(abnormality.severity.rawValue) / Double(InsightSeverity.critical.rawValue)
        }
        
        let averageSeverity = severityScores.reduce(0, +) / Double(severityScores.count)
        let abnormalityCount = Double(abnormalities.count)
        
        // Combine factors: severity, count, and data quality
        let riskScore = (averageSeverity * 0.5 + min(abnormalityCount / 5.0, 1.0) * 0.3 + qtRrData.correlation * 0.2)
        
        return min(riskScore, 1.0)
    }
    
    private func calculateQTDispersion(qtIntervals: [QTInterval]) -> Double {
        guard qtIntervals.count > 1 else { return 0.0 }
        
        let qtDurations = qtIntervals.map { $0.duration }
        let maxQT = qtDurations.max() ?? 0.0
        let minQT = qtDurations.min() ?? 0.0
        
        return maxQT - minQT
    }
    
    private func severityForRisk(_ risk: Double) -> InsightSeverity {
        switch risk {
        case 0.0..<0.2:
            return .normal
        case 0.2..<0.4:
            return .mild
        case 0.4..<0.6:
            return .moderate
        case 0.6..<0.8:
            return .severe
        default:
            return .critical
        }
    }
    
    private func calculateConfidence(qtRrData: QTRRData) -> Double {
        // Calculate confidence based on data quality and correlation
        let dataQuality = min(Double(qtRrData.dataPoints.count) / 100.0, 1.0)
        let correlationQuality = qtRrData.correlation
        
        return (dataQuality + correlationQuality) / 2.0
    }
    
    private func generateDescription(riskAssessment: Double, abnormalities: [QTAbnormality]) -> String {
        let riskPercentage = Int(riskAssessment * 100)
        let abnormalityCount = abnormalities.count
        
        if abnormalityCount == 0 {
            return "Normal QT-RR dynamics with appropriate slope and circadian variation."
        } else if riskAssessment < 0.3 {
            return "Mild QT-RR abnormalities detected. \(abnormalityCount) issues found with \(riskPercentage)% risk score."
        } else if riskAssessment < 0.6 {
            return "Moderate QT-RR abnormalities. \(abnormalityCount) issues indicating potential drug effects or electrolyte imbalance."
        } else if riskAssessment < 0.8 {
            return "Significant QT-RR abnormalities. \(abnormalityCount) issues suggesting drug toxicity or severe electrolyte imbalance."
        } else {
            return "Critical QT-RR abnormalities. \(abnormalityCount) issues requiring immediate medical attention for drug/electrolyte assessment."
        }
    }
}

// MARK: - Supporting Types

struct QTRRPoint {
    let rrInterval: TimeInterval
    let qtInterval: TimeInterval
    let timestamp: TimeInterval
    let index: Int
}

struct QTRRData {
    let averageSlope: Double
    let slopeVariability: Double
    let correlation: Double
    let dataPoints: [QTRRPoint]
}

struct CircadianAnalysis {
    let periodSlopes: [Double]
    let variation: Double
    let hasCircadianPattern: Bool
}

struct QTAbnormality {
    let type: QTAbnormalityType
    let severity: InsightSeverity
    let description: String
    let confidence: Double
}

enum QTAbnormalityType {
    case flattenedSlope
    case steepSlope
    case highVariability
    case lossOfCircadianPattern
    case poorCorrelation
}

struct QTDynamicData: Codable {
    let averageSlope: Double
    let slopeVariability: Double
    let circadianVariation: Double
    let abnormalityCount: Int
    let riskScore: Double
    let qtDispersion: Double
}

enum QTDynamicError: Error {
    case insufficientData
    case invalidIntervals
    case calculationError
}