import Foundation
import Accelerate

class HRTurbulenceCalculator {
    
    // MARK: - Constants
    private let pvcDetectionThreshold = 0.8 // Threshold for PVC detection
    private let hrtWindowSize = 20 // Number of beats to analyze after PVC
    private let accelerationWindow = 5 // Beats for acceleration phase
    private let decelerationWindow = 15 // Beats for deceleration phase
    private let normalRRRange = 0.6...1.2 // Normal RR interval range in seconds
    
    // MARK: - Public Interface
    
    /// Calculate HR turbulence metrics from ECG data
    func calculateHRTurbulence(ecgData: ProcessedECGData, completion: @escaping (Result<ECGInsight, Error>) -> Void) {
        print("HR Turbulence Calculator: Starting analysis...")
        
        // Extract QRS complexes and RR intervals
        let qrsComplexes = extractQRSComplexes(from: ecgData)
        let rrIntervals = extractRRIntervals(from: qrsComplexes)
        
        // Detect PVCs
        let pvcs = detectPVCs(rrIntervals: rrIntervals, qrsComplexes: qrsComplexes)
        
        // Calculate HR turbulence for each PVC
        let hrtMetrics = calculateHRTMetrics(pvcs: pvcs, rrIntervals: rrIntervals)
        
        // Assess autonomic dysfunction
        let autonomicDysfunction = assessAutonomicDysfunction(hrtMetrics: hrtMetrics)
        
        // Create insight
        let insight = ECGInsight(
            type: .hrTurbulence,
            severity: severityForAutonomicDysfunction(autonomicDysfunction),
            confidence: calculateConfidence(hrtMetrics: hrtMetrics),
            description: generateDescription(hrtMetrics: hrtMetrics, autonomicDysfunction: autonomicDysfunction),
            timestamp: Date(),
            data: HRTurbulenceData(
                turbulenceOnset: hrtMetrics.averageTurbulenceOnset,
                turbulenceSlope: hrtMetrics.averageTurbulenceSlope,
                pvcCount: pvcs.count,
                autonomicDysfunctionScore: autonomicDysfunction,
                averageRRVariability: hrtMetrics.averageRRVariability
            )
        )
        
        completion(.success(insight))
    }
    
    /// Get current HR turbulence metrics
    func getCurrentHRTMetrics() -> HRTMetrics {
        // Return cached metrics if available
        return HRTMetrics(
            averageTurbulenceOnset: 0.0,
            averageTurbulenceSlope: 0.0,
            averageRRVariability: 0.0,
            pvcCount: 0
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
    
    private func detectPVCs(rrIntervals: [RRInterval], qrsComplexes: [QRSComplex]) -> [PVC] {
        var pvcs: [PVC] = []
        
        for i in 1..<rrIntervals.count {
            let currentRR = rrIntervals[i].interval
            let previousRR = rrIntervals[i-1].interval
            
            // PVC detection criteria:
            // 1. Compensatory pause (RR interval > 1.2 * normal)
            // 2. Premature beat (RR interval < 0.8 * normal)
            // 3. QRS morphology changes (simplified check)
            
            let isCompensatoryPause = currentRR > normalRRRange.upperBound * 1.2
            let isPrematureBeat = previousRR < normalRRRange.lowerBound * 0.8
            let hasMorphologyChange = detectMorphologyChange(qrsComplexes: qrsComplexes, index: i)
            
            if (isCompensatoryPause || isPrematureBeat) && hasMorphologyChange {
                let pvc = PVC(
                    index: i,
                    rrInterval: currentRR,
                    compensatoryPause: isCompensatoryPause,
                    prematureBeat: isPrematureBeat,
                    timestamp: rrIntervals[i].timestamp,
                    morphologyScore: calculateMorphologyScore(qrsComplexes: qrsComplexes, index: i)
                )
                pvcs.append(pvc)
            }
        }
        
        print("HR Turbulence Calculator: Detected \(pvcs.count) PVCs")
        return pvcs
    }
    
    private func detectMorphologyChange(qrsComplexes: [QRSComplex], index: Int) -> Bool {
        guard index < qrsComplexes.count && index > 0 else { return false }
        
        let currentQRS = qrsComplexes[index]
        let previousQRS = qrsComplexes[index - 1]
        
        // Calculate morphology difference
        let amplitudeDiff = abs(currentQRS.rPoint - previousQRS.rPoint)
        let widthDiff = abs(currentQRS.width - previousQRS.width)
        
        // Normalize differences
        let normalizedAmplitudeDiff = amplitudeDiff / (abs(previousQRS.rPoint) + 1e-10)
        let normalizedWidthDiff = widthDiff / (previousQRS.width + 1e-10)
        
        // Consider morphology change if differences exceed threshold
        return normalizedAmplitudeDiff > 0.3 || normalizedWidthDiff > 0.3
    }
    
    private func calculateMorphologyScore(qrsComplexes: [QRSComplex], index: Int) -> Double {
        guard index < qrsComplexes.count else { return 0.0 }
        
        let qrs = qrsComplexes[index]
        
        // Calculate morphology score based on QRS characteristics
        let amplitudeScore = normalizeScore(qrs.rPoint, min: 0.5, max: 2.0)
        let widthScore = normalizeScore(qrs.width, min: 0.06, max: 0.12)
        let symmetryScore = calculateQRSSymmetry(qrs)
        
        return (amplitudeScore + widthScore + symmetryScore) / 3.0
    }
    
    private func calculateQRSSymmetry(_ qrs: QRSComplex) -> Double {
        let leftHalf = abs(qrs.rPoint - qrs.qPoint)
        let rightHalf = abs(qrs.rPoint - qrs.sPoint)
        let total = leftHalf + rightHalf
        
        guard total > 0 else { return 0.0 }
        
        return 1.0 - abs(leftHalf - rightHalf) / total
    }
    
    private func normalizeScore(_ value: Double, min: Double, max: Double) -> Double {
        if value < min { return 0.0 }
        if value > max { return 0.0 }
        return 1.0 - abs(value - (min + max) / 2.0) / ((max - min) / 2.0)
    }
    
    private func calculateHRTMetrics(pvcs: [PVC], rrIntervals: [RRInterval]) -> HRTMetrics {
        guard !pvcs.isEmpty else {
            return HRTMetrics(
                averageTurbulenceOnset: 0.0,
                averageTurbulenceSlope: 0.0,
                averageRRVariability: 0.0,
                pvcCount: 0
            )
        }
        
        var turbulenceOnsets: [Double] = []
        var turbulenceSlopes: [Double] = []
        var rrVariabilities: [Double] = []
        
        for pvc in pvcs {
            // Calculate turbulence onset (TO)
            if let to = calculateTurbulenceOnset(pvc: pvc, rrIntervals: rrIntervals) {
                turbulenceOnsets.append(to)
            }
            
            // Calculate turbulence slope (TS)
            if let ts = calculateTurbulenceSlope(pvc: pvc, rrIntervals: rrIntervals) {
                turbulenceSlopes.append(ts)
            }
            
            // Calculate RR variability around PVC
            if let variability = calculateRRVariability(pvc: pvc, rrIntervals: rrIntervals) {
                rrVariabilities.append(variability)
            }
        }
        
        let averageTO = turbulenceOnsets.isEmpty ? 0.0 : turbulenceOnsets.reduce(0, +) / Double(turbulenceOnsets.count)
        let averageTS = turbulenceSlopes.isEmpty ? 0.0 : turbulenceSlopes.reduce(0, +) / Double(turbulenceSlopes.count)
        let averageVariability = rrVariabilities.isEmpty ? 0.0 : rrVariabilities.reduce(0, +) / Double(rrVariabilities.count)
        
        return HRTMetrics(
            averageTurbulenceOnset: averageTO,
            averageTurbulenceSlope: averageTS,
            averageRRVariability: averageVariability,
            pvcCount: pvcs.count
        )
    }
    
    private func calculateTurbulenceOnset(pvc: PVC, rrIntervals: [RRInterval]) -> Double? {
        let pvcIndex = pvc.index
        guard pvcIndex + accelerationWindow < rrIntervals.count else { return nil }
        
        // Calculate average RR interval before PVC
        let prePVCRR = calculateAverageRR(rrIntervals: rrIntervals, startIndex: max(0, pvcIndex - 5), endIndex: pvcIndex)
        
        // Calculate average RR interval during acceleration phase
        let accelerationRR = calculateAverageRR(rrIntervals: rrIntervals, startIndex: pvcIndex + 1, endIndex: pvcIndex + accelerationWindow)
        
        // Turbulence onset = (acceleration RR - pre PVC RR) / pre PVC RR
        guard prePVCRR > 0 else { return nil }
        
        return (accelerationRR - prePVCRR) / prePVCRR
    }
    
    private func calculateTurbulenceSlope(pvc: PVC, rrIntervals: [RRInterval]) -> Double? {
        let pvcIndex = pvc.index
        guard pvcIndex + decelerationWindow < rrIntervals.count else { return nil }
        
        // Get RR intervals during deceleration phase
        let decelerationRRs = Array(rrIntervals[pvcIndex + accelerationWindow..<pvcIndex + decelerationWindow])
        
        // Calculate linear regression slope
        return calculateLinearRegressionSlope(rrIntervals: decelerationRRs)
    }
    
    private func calculateAverageRR(rrIntervals: [RRInterval], startIndex: Int, endIndex: Int) -> Double {
        guard startIndex < endIndex && endIndex <= rrIntervals.count else { return 0.0 }
        
        let intervals = Array(rrIntervals[startIndex..<endIndex])
        let sum = intervals.reduce(0.0) { $0 + $1.interval }
        
        return sum / Double(intervals.count)
    }
    
    private func calculateLinearRegressionSlope(rrIntervals: [RRInterval]) -> Double? {
        guard rrIntervals.count > 1 else { return nil }
        
        let n = Double(rrIntervals.count)
        let xValues = Array(0..<rrIntervals.count).map { Double($0) }
        let yValues = rrIntervals.map { $0.interval }
        
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).map { $0 * $1 }.reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = n * sumX2 - sumX * sumX
        
        guard denominator != 0 else { return nil }
        
        return numerator / denominator
    }
    
    private func calculateRRVariability(pvc: PVC, rrIntervals: [RRInterval]) -> Double? {
        let pvcIndex = pvc.index
        guard pvcIndex + 10 < rrIntervals.count else { return nil }
        
        // Calculate RR variability in window around PVC
        let startIndex = max(0, pvcIndex - 5)
        let endIndex = min(rrIntervals.count, pvcIndex + 5)
        
        let intervals = Array(rrIntervals[startIndex..<endIndex])
        let mean = intervals.reduce(0.0) { $0 + $1.interval } / Double(intervals.count)
        
        let variance = intervals.map { pow($0.interval - mean, 2) }.reduce(0, +) / Double(intervals.count)
        
        return sqrt(variance)
    }
    
    private func assessAutonomicDysfunction(hrtMetrics: HRTMetrics) -> Double {
        // Assess autonomic dysfunction based on HR turbulence metrics
        
        // Normal ranges for HR turbulence:
        // Turbulence Onset (TO): -2.0% to 0.0%
        // Turbulence Slope (TS): 2.5 to 4.5 ms/RR interval
        
        let toScore = assessTurbulenceOnset(hrtMetrics.averageTurbulenceOnset)
        let tsScore = assessTurbulenceSlope(hrtMetrics.averageTurbulenceSlope)
        let variabilityScore = assessRRVariability(hrtMetrics.averageRRVariability)
        
        // Combine scores (higher score = more dysfunction)
        let dysfunctionScore = (toScore + tsScore + variabilityScore) / 3.0
        
        return min(dysfunctionScore, 1.0)
    }
    
    private func assessTurbulenceOnset(_ to: Double) -> Double {
        // Normal TO is slightly negative (-2.0% to 0.0%)
        // Positive TO indicates autonomic dysfunction
        if to < -0.02 {
            return 0.0 // Normal
        } else if to < 0.0 {
            return 0.3 // Mild dysfunction
        } else if to < 0.02 {
            return 0.6 // Moderate dysfunction
        } else {
            return 1.0 // Severe dysfunction
        }
    }
    
    private func assessTurbulenceSlope(_ ts: Double) -> Double {
        // Normal TS is 2.5 to 4.5 ms/RR interval
        // Lower TS indicates autonomic dysfunction
        if ts >= 2.5 && ts <= 4.5 {
            return 0.0 // Normal
        } else if ts >= 1.5 && ts < 2.5 {
            return 0.4 // Mild dysfunction
        } else if ts >= 0.5 && ts < 1.5 {
            return 0.7 // Moderate dysfunction
        } else {
            return 1.0 // Severe dysfunction
        }
    }
    
    private func assessRRVariability(_ variability: Double) -> Double {
        // Higher RR variability is generally better
        // Lower variability indicates autonomic dysfunction
        if variability > 0.1 {
            return 0.0 // Normal
        } else if variability > 0.05 {
            return 0.3 // Mild dysfunction
        } else if variability > 0.02 {
            return 0.6 // Moderate dysfunction
        } else {
            return 1.0 // Severe dysfunction
        }
    }
    
    private func severityForAutonomicDysfunction(_ dysfunction: Double) -> InsightSeverity {
        switch dysfunction {
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
    
    private func calculateConfidence(hrtMetrics: HRTMetrics) -> Double {
        // Calculate confidence based on data quality and PVC count
        let pvcCount = hrtMetrics.pvcCount
        
        if pvcCount == 0 {
            return 0.0 // No PVCs detected
        } else if pvcCount < 3 {
            return 0.3 // Low confidence with few PVCs
        } else if pvcCount < 10 {
            return 0.7 // Moderate confidence
        } else {
            return 1.0 // High confidence with many PVCs
        }
    }
    
    private func generateDescription(hrtMetrics: HRTMetrics, autonomicDysfunction: Double) -> String {
        let dysfunctionPercentage = Int(autonomicDysfunction * 100)
        let pvcCount = hrtMetrics.pvcCount
        
        if pvcCount == 0 {
            return "No PVCs detected. HR turbulence analysis requires PVCs for assessment."
        } else if autonomicDysfunction < 0.2 {
            return "Normal HR turbulence response. \(pvcCount) PVCs analyzed with normal autonomic function."
        } else if autonomicDysfunction < 0.4 {
            return "Mild autonomic dysfunction detected. \(dysfunctionPercentage)% dysfunction score with \(pvcCount) PVCs."
        } else if autonomicDysfunction < 0.6 {
            return "Moderate autonomic dysfunction. \(dysfunctionPercentage)% dysfunction score indicating reduced HR turbulence response."
        } else if autonomicDysfunction < 0.8 {
            return "Significant autonomic dysfunction. \(dysfunctionPercentage)% dysfunction score with impaired HR turbulence."
        } else {
            return "Severe autonomic dysfunction. \(dysfunctionPercentage)% dysfunction score requiring medical evaluation."
        }
    }
}

// MARK: - Supporting Types

struct PVC {
    let index: Int
    let rrInterval: TimeInterval
    let compensatoryPause: Bool
    let prematureBeat: Bool
    let timestamp: TimeInterval
    let morphologyScore: Double
}

struct HRTMetrics {
    let averageTurbulenceOnset: Double
    let averageTurbulenceSlope: Double
    let averageRRVariability: Double
    let pvcCount: Int
}

struct HRTurbulenceData: Codable {
    let turbulenceOnset: Double
    let turbulenceSlope: Double
    let pvcCount: Int
    let autonomicDysfunctionScore: Double
    let averageRRVariability: Double
}

enum HRTurbulenceError: Error {
    case insufficientData
    case noPVCsDetected
    case calculationError
}