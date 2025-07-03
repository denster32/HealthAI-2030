import Foundation
import Accelerate

class STSegmentAnalyzer {
    
    // MARK: - Constants
    private let stWindowSize = 20 // samples for ST measurement
    private let zScoreWindow = 100 // samples for rolling z-score calculation
    private let stElevationThreshold = 0.1 // mV threshold for ST elevation
    private let zScoreThreshold = 2.0 // Standard deviations for significant change
    private let consecutiveExcursionsThreshold = 3 // Number of consecutive excursions for alert
    private let exertionDetectionWindow = 30 // seconds for exertion detection
    
    // MARK: - Private Properties
    private var stHistory: [STMeasurement] = []
    private var exertionPeriods: [ExertionPeriod] = []
    
    // MARK: - Public Interface
    
    /// Analyze ST segments and detect ischemia
    func analyzeSTSegments(ecgData: ProcessedECGData, completion: @escaping (Result<ECGInsight, Error>) -> Void) {
        print("ST Segment Analyzer: Starting analysis...")
        
        // Extract QRS complexes for ST measurement reference
        let qrsComplexes = extractQRSComplexes(from: ecgData)
        
        // Measure ST segments
        let stMeasurements = measureSTSegments(ecgData: ecgData, qrsComplexes: qrsComplexes)
        
        // Calculate rolling z-scores
        let zScores = calculateRollingZScores(stMeasurements: stMeasurements)
        
        // Detect exertion periods
        let exertionPeriods = detectExertionPeriods(ecgData: ecgData)
        
        // Analyze ST changes during exertion
        let exertionAnalysis = analyzeSTDuringExertion(stMeasurements: stMeasurements, exertionPeriods: exertionPeriods)
        
        // Detect significant ST changes
        let stChanges = detectSignificantSTChanges(zScores: zScores, exertionAnalysis: exertionAnalysis)
        
        // Assess ischemia risk
        let ischemiaRisk = assessIschemiaRisk(stChanges: stChanges, exertionAnalysis: exertionAnalysis)
        
        // Create insight
        let insight = ECGInsight(
            type: .stSegmentShift,
            severity: severityForIschemiaRisk(ischemiaRisk),
            confidence: calculateConfidence(stMeasurements: stMeasurements),
            description: generateDescription(ischemiaRisk: ischemiaRisk, stChanges: stChanges),
            timestamp: Date(),
            data: STSegmentData(
                averageSTElevation: calculateAverageSTElevation(stMeasurements: stMeasurements),
                maxZScore: zScores.map { $0.zScore }.max() ?? 0.0,
                consecutiveExcursions: stChanges.consecutiveExcursions,
                exertionPeriods: exertionPeriods.count,
                ischemiaRisk: ischemiaRisk,
                stVariability: calculateSTVariability(stMeasurements: stMeasurements)
            )
        )
        
        completion(.success(insight))
    }
    
    /// Get current ST segment metrics
    func getCurrentSTMetrics() -> STMetrics {
        return STMetrics(
            averageElevation: 0.0,
            maxElevation: 0.0,
            variability: 0.0,
            measurementCount: 0
        )
    }
    
    // MARK: - Private Methods
    
    private func extractQRSComplexes(from ecgData: ProcessedECGData) -> [QRSComplex] {
        let processor = ECGDataProcessor()
        return processor.extractQRSComplexes(ecgData)
    }
    
    private func measureSTSegments(ecgData: ProcessedECGData, qrsComplexes: [QRSComplex]) -> [STMeasurement] {
        var stMeasurements: [STMeasurement] = []
        
        for qrsComplex in qrsComplexes {
            if let stMeasurement = measureSTSegment(ecgData: ecgData, qrsComplex: qrsComplex) {
                stMeasurements.append(stMeasurement)
            }
        }
        
        print("ST Segment Analyzer: Measured \(stMeasurements.count) ST segments")
        return stMeasurements
    }
    
    private func measureSTSegment(ecgData: ProcessedECGData, qrsComplex: QRSComplex) -> STMeasurement? {
        let samples = ecgData.samples
        let samplingRate = 512.0 // Hz
        
        // Calculate ST measurement point (80ms after R peak)
        let stOffset = Int(0.08 * samplingRate) // 80ms
        let rPeakIndex = Int(qrsComplex.rPeakTime * samplingRate)
        let stIndex = rPeakIndex + stOffset
        
        guard stIndex < samples.count else { return nil }
        
        // Measure ST segment height relative to baseline
        let baseline = calculateBaseline(samples: samples, qrsIndex: rPeakIndex)
        let stHeight = samples[stIndex] - baseline
        
        // Calculate ST slope
        let stSlope = calculateSTSlope(samples: samples, stIndex: stIndex)
        
        // Determine ST morphology
        let morphology = determineSTMorphology(stHeight: stHeight, stSlope: stSlope)
        
        return STMeasurement(
            height: stHeight,
            slope: stSlope,
            morphology: morphology,
            timestamp: qrsComplex.rPeakTime + 0.08, // 80ms after R peak
            index: qrsComplex.index,
            quality: assessSTQuality(stHeight: stHeight, stSlope: stSlope)
        )
    }
    
    private func calculateBaseline(samples: [Double], qrsIndex: Int) -> Double {
        // Calculate baseline as average of samples before QRS
        let baselineStart = max(0, qrsIndex - 50)
        let baselineEnd = max(0, qrsIndex - 10)
        
        guard baselineEnd > baselineStart else { return 0.0 }
        
        let baselineSamples = Array(samples[baselineStart..<baselineEnd])
        return baselineSamples.reduce(0, +) / Double(baselineSamples.count)
    }
    
    private func calculateSTSlope(samples: [Double], stIndex: Int) -> Double {
        // Calculate ST slope over 40ms window
        let slopeWindow = Int(0.04 * 512.0) // 40ms at 512Hz
        let endIndex = min(samples.count - 1, stIndex + slopeWindow)
        
        guard endIndex > stIndex else { return 0.0 }
        
        let xValues = Array(stIndex...endIndex).map { Double($0) }
        let yValues = Array(samples[stIndex...endIndex])
        
        return calculateLinearRegressionSlope(xValues: xValues, yValues: yValues)
    }
    
    private func calculateLinearRegressionSlope(xValues: [Double], yValues: [Double]) -> Double {
        guard xValues.count == yValues.count && xValues.count > 1 else { return 0.0 }
        
        let n = Double(xValues.count)
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map { $0 * $1 }.reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = n * sumX2 - sumX * sumX
        
        guard denominator != 0 else { return 0.0 }
        
        return numerator / denominator
    }
    
    private func determineSTMorphology(stHeight: Double, stSlope: Double) -> STMorphology {
        if stHeight > stElevationThreshold {
            return stSlope > 0 ? .elevatedUpsloping : .elevatedDownsloping
        } else if stHeight < -stElevationThreshold {
            return stSlope < 0 ? .depressedDownsloping : .depressedUpsloping
        } else {
            return stSlope > 0.1 ? .normalUpsloping : .normalHorizontal
        }
    }
    
    private func assessSTQuality(stHeight: Double, stSlope: Double) -> DataQuality {
        // Assess ST measurement quality based on signal characteristics
        let heightVariability = abs(stHeight)
        let slopeVariability = abs(stSlope)
        
        if heightVariability < 0.05 && slopeVariability < 0.1 {
            return .excellent
        } else if heightVariability < 0.1 && slopeVariability < 0.2 {
            return .good
        } else if heightVariability < 0.2 && slopeVariability < 0.5 {
            return .fair
        } else {
            return .poor
        }
    }
    
    private func calculateRollingZScores(stMeasurements: [STMeasurement]) -> [STZScore] {
        var zScores: [STZScore] = []
        
        for i in 0..<stMeasurements.count {
            let windowStart = max(0, i - zScoreWindow / 2)
            let windowEnd = min(stMeasurements.count, i + zScoreWindow / 2)
            let window = Array(stMeasurements[windowStart..<windowEnd])
            
            let zScore = calculateZScore(measurement: stMeasurements[i], window: window)
            zScores.append(zScore)
        }
        
        return zScores
    }
    
    private func calculateZScore(measurement: STMeasurement, window: [STMeasurement]) -> STZScore {
        guard window.count > 1 else {
            return STZScore(
                zScore: 0.0,
                timestamp: measurement.timestamp,
                index: measurement.index
            )
        }
        
        let heights = window.map { $0.height }
        let mean = heights.reduce(0, +) / Double(heights.count)
        let variance = heights.map { pow($0 - mean, 2) }.reduce(0, +) / Double(heights.count)
        let stdDev = sqrt(variance)
        
        let zScore = stdDev > 0 ? (measurement.height - mean) / stdDev : 0.0
        
        return STZScore(
            zScore: zScore,
            timestamp: measurement.timestamp,
            index: measurement.index
        )
    }
    
    private func detectExertionPeriods(ecgData: ProcessedECGData) -> [ExertionPeriod] {
        // For M2, this is a simplified exertion detection
        // In production, this would use accelerometer data and heart rate changes
        
        var exertionPeriods: [ExertionPeriod] = []
        let samples = ecgData.samples
        let samplingRate = 512.0
        
        // Detect periods of increased heart rate (simplified)
        let heartRateChanges = detectHeartRateChanges(samples: samples)
        
        for change in heartRateChanges {
            if change.heartRateIncrease > 20 { // 20 BPM increase
                let exertionPeriod = ExertionPeriod(
                    startTime: change.timestamp,
                    endTime: change.timestamp + exertionDetectionWindow,
                    intensity: change.heartRateIncrease / 50.0, // Normalize to 0-1
                    duration: exertionDetectionWindow
                )
                exertionPeriods.append(exertionPeriod)
            }
        }
        
        return exertionPeriods
    }
    
    private func detectHeartRateChanges(samples: [Double]) -> [HeartRateChange] {
        // Simplified heart rate change detection
        // In production, this would use actual heart rate data
        var changes: [HeartRateChange] = []
        
        // Simulate heart rate changes for demonstration
        let simulatedChanges = [
            HeartRateChange(timestamp: 60, heartRateIncrease: 25),
            HeartRateChange(timestamp: 180, heartRateIncrease: 30),
            HeartRateChange(timestamp: 300, heartRateIncrease: 15)
        ]
        
        return simulatedChanges
    }
    
    private func analyzeSTDuringExertion(stMeasurements: [STMeasurement], exertionPeriods: [ExertionPeriod]) -> ExertionAnalysis {
        var exertionSTChanges: [STChange] = []
        
        for exertionPeriod in exertionPeriods {
            let stMeasurementsInPeriod = stMeasurements.filter { measurement in
                measurement.timestamp >= exertionPeriod.startTime && 
                measurement.timestamp <= exertionPeriod.endTime
            }
            
            if let stChange = calculateSTChangeDuringExertion(measurements: stMeasurementsInPeriod) {
                exertionSTChanges.append(stChange)
            }
        }
        
        return ExertionAnalysis(
            exertionPeriods: exertionPeriods,
            stChanges: exertionSTChanges,
            averageSTChange: calculateAverageSTChange(changes: exertionSTChanges)
        )
    }
    
    private func calculateSTChangeDuringExertion(measurements: [STMeasurement]) -> STChange? {
        guard measurements.count > 1 else { return nil }
        
        guard let baselineMeasurement = measurements.first,
              let peakMeasurement = measurements.max(by: { $0.height < $1.height }) else {
            return nil
        }
        
        let stChange = peakMeasurement.height - baselineMeasurement.height
        let timeToPeak = peakMeasurement.timestamp - baselineMeasurement.timestamp
        
        return STChange(
            baselineHeight: baselineMeasurement.height,
            peakHeight: peakMeasurement.height,
            change: stChange,
            timeToPeak: timeToPeak,
            isSignificant: abs(stChange) > stElevationThreshold
        )
    }
    
    private func calculateAverageSTChange(changes: [STChange]) -> Double {
        guard !changes.isEmpty else { return 0.0 }
        
        let totalChange = changes.reduce(0.0) { $0 + $1.change }
        return totalChange / Double(changes.count)
    }
    
    private func detectSignificantSTChanges(zScores: [STZScore], exertionAnalysis: ExertionAnalysis) -> STChanges {
        var significantChanges: [STZScore] = []
        var consecutiveExcursions = 0
        var maxConsecutive = 0
        
        for zScore in zScores {
            if abs(zScore.zScore) > zScoreThreshold {
                significantChanges.append(zScore)
                consecutiveExcursions += 1
                maxConsecutive = max(maxConsecutive, consecutiveExcursions)
            } else {
                consecutiveExcursions = 0
            }
        }
        
        return STChanges(
            significantChanges: significantChanges,
            consecutiveExcursions: maxConsecutive,
            totalExcursions: significantChanges.count,
            hasCriticalPattern: maxConsecutive >= consecutiveExcursionsThreshold
        )
    }
    
    private func assessIschemiaRisk(stChanges: STChanges, exertionAnalysis: ExertionAnalysis) -> Double {
        var riskScore = 0.0
        
        // Risk from consecutive excursions
        if stChanges.consecutiveExcursions >= consecutiveExcursionsThreshold {
            riskScore += 0.6
        } else if stChanges.consecutiveExcursions > 0 {
            riskScore += Double(stChanges.consecutiveExcursions) / Double(consecutiveExcursionsThreshold) * 0.4
        }
        
        // Risk from exertion-related ST changes
        let exertionRisk = exertionAnalysis.stChanges.filter { $0.isSignificant }.count > 0 ? 0.3 : 0.0
        riskScore += exertionRisk
        
        // Risk from total excursions
        let excursionRisk = min(Double(stChanges.totalExcursions) / 10.0, 0.2)
        riskScore += excursionRisk
        
        return min(riskScore, 1.0)
    }
    
    private func severityForIschemiaRisk(_ risk: Double) -> InsightSeverity {
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
    
    private func calculateConfidence(stMeasurements: [STMeasurement]) -> Double {
        guard !stMeasurements.isEmpty else { return 0.0 }
        
        // Calculate confidence based on measurement quality and quantity
        let qualityScores = stMeasurements.map { measurement in
            switch measurement.quality {
            case .excellent: return 1.0
            case .good: return 0.8
            case .fair: return 0.6
            case .poor: return 0.3
            }
        }
        
        let averageQuality = qualityScores.reduce(0, +) / Double(qualityScores.count)
        let quantityScore = min(Double(stMeasurements.count) / 100.0, 1.0)
        
        return (averageQuality + quantityScore) / 2.0
    }
    
    private func calculateAverageSTElevation(stMeasurements: [STMeasurement]) -> Double {
        guard !stMeasurements.isEmpty else { return 0.0 }
        
        let elevations = stMeasurements.map { $0.height }
        return elevations.reduce(0, +) / Double(elevations.count)
    }
    
    private func calculateSTVariability(stMeasurements: [STMeasurement]) -> Double {
        guard stMeasurements.count > 1 else { return 0.0 }
        
        let heights = stMeasurements.map { $0.height }
        let mean = heights.reduce(0, +) / Double(heights.count)
        let variance = heights.map { pow($0 - mean, 2) }.reduce(0, +) / Double(heights.count)
        
        return sqrt(variance)
    }
    
    private func generateDescription(ischemiaRisk: Double, stChanges: STChanges) -> String {
        let riskPercentage = Int(ischemiaRisk * 100)
        let excursionCount = stChanges.totalExcursions
        let consecutiveCount = stChanges.consecutiveExcursions
        
        if ischemiaRisk < 0.2 {
            return "Normal ST segment morphology with no significant changes detected."
        } else if ischemiaRisk < 0.4 {
            return "Mild ST segment changes. \(excursionCount) excursions detected with \(riskPercentage)% ischemia risk."
        } else if ischemiaRisk < 0.6 {
            return "Moderate ST segment abnormalities. \(consecutiveCount) consecutive excursions indicating potential ischemia."
        } else if ischemiaRisk < 0.8 {
            return "Significant ST segment changes. \(consecutiveCount) consecutive excursions suggesting myocardial ischemia."
        } else {
            return "Critical ST segment changes. \(consecutiveCount) consecutive excursions indicating acute ischemia requiring immediate medical attention."
        }
    }
}

// MARK: - Supporting Types

struct STMeasurement {
    let height: Double // mV
    let slope: Double // mV/s
    let morphology: STMorphology
    let timestamp: TimeInterval
    let index: Int
    let quality: DataQuality
}

enum STMorphology {
    case elevatedUpsloping
    case elevatedDownsloping
    case depressedUpsloping
    case depressedDownsloping
    case normalUpsloping
    case normalHorizontal
}

struct STZScore {
    let zScore: Double
    let timestamp: TimeInterval
    let index: Int
}

struct ExertionPeriod {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let intensity: Double // 0-1
    let duration: TimeInterval
}

struct HeartRateChange {
    let timestamp: TimeInterval
    let heartRateIncrease: Int // BPM
}

struct STChange {
    let baselineHeight: Double
    let peakHeight: Double
    let change: Double
    let timeToPeak: TimeInterval
    let isSignificant: Bool
}

struct ExertionAnalysis {
    let exertionPeriods: [ExertionPeriod]
    let stChanges: [STChange]
    let averageSTChange: Double
}

struct STChanges {
    let significantChanges: [STZScore]
    let consecutiveExcursions: Int
    let totalExcursions: Int
    let hasCriticalPattern: Bool
}

struct STMetrics {
    let averageElevation: Double
    let maxElevation: Double
    let variability: Double
    let measurementCount: Int
}

struct STSegmentData: Codable {
    let averageSTElevation: Double
    let maxZScore: Double
    let consecutiveExcursions: Int
    let exertionPeriods: Int
    let ischemiaRisk: Double
    let stVariability: Double
}

enum STSegmentError: Error {
    case insufficientData
    case measurementError
    case calculationError
}