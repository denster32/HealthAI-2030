import Foundation
import Accelerate

class AFFeatureExtractor {
    
    // MARK: - Constants
    private let pacDetectionThreshold = 0.8 // Threshold for PAC detection
    private let pWaveWindowSize = 50 // samples for P-wave analysis
    private let hrvWindowSize = 300 // samples for HRV calculation
    private let laSizeEstimationWindow = 24 // hours for LA size proxy
    
    // MARK: - Private Properties
    private var pacHistory: [PACEvent] = []
    private var pWaveHistory: [PWaveMeasurement] = []
    private var hrvHistory: [HRVMeasurement] = []
    
    // MARK: - Public Interface
    
    /// Extract AF-specific features from ECG data
    func extractAFFeatures(ecgData: ProcessedECGData, completion: @escaping (Result<AFFeatures, Error>) -> Void) {
        print("AF Feature Extractor: Starting feature extraction...")
        
        // Extract QRS complexes and intervals
        let qrsComplexes = extractQRSComplexes(from: ecgData)
        let rrIntervals = extractRRIntervals(from: qrsComplexes)
        
        // Extract PAC density
        let pacDensity = extractPACDensity(ecgData: ecgData, qrsComplexes: qrsComplexes)
        
        // Extract P-wave dispersion
        let pWaveDispersion = extractPWaveDispersion(ecgData: ecgData, qrsComplexes: qrsComplexes)
        
        // Extract sleep HRV
        let sleepHRV = extractSleepHRV(rrIntervals: rrIntervals)
        
        // Estimate LA size proxy
        let laSizeProxy = estimateLASizeProxy(ecgData: ecgData, rrIntervals: rrIntervals)
        
        // Get demographic and clinical data
        let demographics = getDemographicData()
        let clinicalData = getClinicalData()
        
        // Create AF features
        let features = AFFeatures(
            pacDensity: pacDensity,
            pWaveDispersion: pWaveDispersion,
            sleepHRV: sleepHRV,
            laSizeProxy: laSizeProxy,
            age: demographics.age,
            bmi: demographics.bmi,
            gender: demographics.gender,
            hasHypertension: clinicalData.hasHypertension,
            hasDiabetes: clinicalData.hasDiabetes,
            hasHeartFailure: clinicalData.hasHeartFailure,
            hasStroke: clinicalData.hasStroke
        )
        
        // Store extracted features for historical analysis
        storeExtractedFeatures(features)
        
        completion(.success(features))
    }
    
    /// Get historical feature trends
    func getFeatureTrends() -> AFFeatureTrends {
        return AFFeatureTrends(
            pacDensityTrend: calculateTrend(values: pacHistory.map { $0.density }),
            pWaveDispersionTrend: calculateTrend(values: pWaveHistory.map { $0.duration }),
            hrvTrend: calculateTrend(values: hrvHistory.map { $0.hrv }),
            laSizeTrend: calculateTrend(values: hrvHistory.map { $0.laSizeProxy })
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
    
    private func extractPACDensity(ecgData: ProcessedECGData, qrsComplexes: [QRSComplex]) -> Double {
        var pacCount = 0
        let samples = ecgData.samples
        let samplingRate = 512.0
        
        // Detect PACs based on premature beats and morphology changes
        for i in 1..<qrsComplexes.count {
            let currentQRS = qrsComplexes[i]
            let previousQRS = qrsComplexes[i-1]
            
            // Calculate RR interval
            let rrInterval = currentQRS.rPeakTime - previousQRS.rPeakTime
            
            // Check for premature beat (RR < 80% of average)
            let averageRR = calculateAverageRR(qrsComplexes: qrsComplexes, excludeIndex: i)
            let isPremature = rrInterval < averageRR * 0.8
            
            // Check for morphology change
            let hasMorphologyChange = detectMorphologyChange(currentQRS: currentQRS, previousQRS: previousQRS)
            
            // Check for compensatory pause
            let hasCompensatoryPause = i < qrsComplexes.count - 1 ? 
                (qrsComplexes[i+1].rPeakTime - currentQRS.rPeakTime) > averageRR * 1.2 : false
            
            if isPremature && hasMorphologyChange && hasCompensatoryPause {
                pacCount += 1
            }
        }
        
        // Calculate PAC density (PACs per hour)
        let recordingDuration = ecgData.duration / 3600.0 // Convert to hours
        let pacDensity = recordingDuration > 0 ? Double(pacCount) / recordingDuration : 0.0
        
        print("AF Feature Extractor: Detected \(pacCount) PACs, density: \(pacDensity) PACs/hour")
        return pacDensity
    }
    
    private func calculateAverageRR(qrsComplexes: [QRSComplex], excludeIndex: Int) -> TimeInterval {
        var totalRR = 0.0
        var count = 0
        
        for i in 1..<qrsComplexes.count {
            if i != excludeIndex && i-1 != excludeIndex {
                let rrInterval = qrsComplexes[i].rPeakTime - qrsComplexes[i-1].rPeakTime
                totalRR += rrInterval
                count += 1
            }
        }
        
        return count > 0 ? totalRR / Double(count) : 0.8 // Default 800ms
    }
    
    private func detectMorphologyChange(currentQRS: QRSComplex, previousQRS: QRSComplex) -> Bool {
        // Calculate morphology difference
        let amplitudeDiff = abs(currentQRS.rPoint - previousQRS.rPoint)
        let widthDiff = abs(currentQRS.width - previousQRS.width)
        
        // Normalize differences
        let normalizedAmplitudeDiff = amplitudeDiff / (abs(previousQRS.rPoint) + 1e-10)
        let normalizedWidthDiff = widthDiff / (previousQRS.width + 1e-10)
        
        // Consider morphology change if differences exceed threshold
        return normalizedAmplitudeDiff > 0.3 || normalizedWidthDiff > 0.3
    }
    
    private func extractPWaveDispersion(ecgData: ProcessedECGData, qrsComplexes: [QRSComplex]) -> Double {
        var pWaveDurations: [Double] = []
        let samples = ecgData.samples
        let samplingRate = 512.0
        
        for qrsComplex in qrsComplexes {
            if let pWaveDuration = measurePWaveDuration(ecgData: ecgData, qrsComplex: qrsComplex) {
                pWaveDurations.append(pWaveDuration)
            }
        }
        
        // Calculate P-wave dispersion (max - min duration)
        guard !pWaveDurations.isEmpty else { return 0.0 }
        
        let maxDuration = pWaveDurations.max() ?? 0.0
        let minDuration = pWaveDurations.min() ?? 0.0
        let dispersion = maxDuration - minDuration
        
        print("AF Feature Extractor: P-wave dispersion: \(dispersion) ms")
        return dispersion
    }
    
    private func measurePWaveDuration(ecgData: ProcessedECGData, qrsComplex: QRSComplex) -> Double? {
        let samples = ecgData.samples
        let samplingRate = 512.0
        
        // Calculate P-wave search window (200ms before QRS)
        let pWaveSearchStart = Int((qrsComplex.qPeakTime - 0.2) * samplingRate)
        let pWaveSearchEnd = Int(qrsComplex.qPeakTime * samplingRate)
        
        guard pWaveSearchStart >= 0 && pWaveSearchEnd < samples.count else { return nil }
        
        // Find P-wave onset and offset
        let pWaveSamples = Array(samples[pWaveSearchStart..<pWaveSearchEnd])
        
        if let pWaveOnset = findPWaveOnset(samples: pWaveSamples),
           let pWaveOffset = findPWaveOffset(samples: pWaveSamples) {
            
            let duration = (pWaveOffset - pWaveOnset) / samplingRate * 1000.0 // Convert to ms
            return duration
        }
        
        return nil
    }
    
    private func findPWaveOnset(samples: [Double]) -> Int? {
        // Find P-wave onset using threshold crossing
        let threshold = 0.1
        let baseline = samples.prefix(10).reduce(0, +) / Double(min(10, samples.count))
        
        for i in 10..<samples.count {
            if abs(samples[i] - baseline) > threshold {
                return i
            }
        }
        
        return nil
    }
    
    private func findPWaveOffset(samples: [Double]) -> Int? {
        // Find P-wave offset using threshold crossing
        let threshold = 0.1
        let baseline = samples.suffix(10).reduce(0, +) / Double(min(10, samples.count))
        
        for i in (0..<samples.count-10).reversed() {
            if abs(samples[i] - baseline) > threshold {
                return i
            }
        }
        
        return nil
    }
    
    private func extractSleepHRV(rrIntervals: [RRInterval]) -> Double {
        guard rrIntervals.count >= hrvWindowSize else { return 0.0 }
        
        // Calculate HRV using RMSSD (Root Mean Square of Successive Differences)
        var rmssdSum = 0.0
        var count = 0
        
        for i in 1..<rrIntervals.count {
            let difference = rrIntervals[i].interval - rrIntervals[i-1].interval
            rmssdSum += difference * difference
            count += 1
        }
        
        let rmssd = count > 0 ? sqrt(rmssdSum / Double(count)) : 0.0
        
        // Convert to milliseconds
        let hrvMs = rmssd * 1000.0
        
        print("AF Feature Extractor: Sleep HRV (RMSSD): \(hrvMs) ms")
        return hrvMs
    }
    
    private func estimateLASizeProxy(ecgData: ProcessedECGData, rrIntervals: [RRInterval]) -> Double {
        // Estimate LA size using P-wave duration and amplitude
        // This is a simplified proxy - in production, this would use more sophisticated methods
        
        var pWaveDurations: [Double] = []
        var pWaveAmplitudes: [Double] = []
        
        // Extract P-wave measurements from recent data
        let recentQRSComplexes = extractQRSComplexes(from: ecgData)
        
        for qrsComplex in recentQRSComplexes {
            if let pWaveMeasurement = measurePWave(ecgData: ecgData, qrsComplex: qrsComplex) {
                pWaveDurations.append(pWaveMeasurement.duration)
                pWaveAmplitudes.append(pWaveMeasurement.amplitude)
            }
        }
        
        guard !pWaveDurations.isEmpty else { return 40.0 } // Default LA size
        
        // Calculate LA size proxy based on P-wave characteristics
        let avgDuration = pWaveDurations.reduce(0, +) / Double(pWaveDurations.count)
        let avgAmplitude = pWaveAmplitudes.reduce(0, +) / Double(pWaveAmplitudes.count)
        
        // LA size proxy formula (simplified)
        // Longer P-wave duration and larger amplitude suggest larger LA
        let laSizeProxy = 30.0 + (avgDuration - 100.0) * 0.2 + avgAmplitude * 10.0
        
        print("AF Feature Extractor: LA size proxy: \(laSizeProxy) mm")
        return max(20.0, min(80.0, laSizeProxy)) // Clamp to reasonable range
    }
    
    private func measurePWave(ecgData: ProcessedECGData, qrsComplex: QRSComplex) -> PWaveMeasurement? {
        let samples = ecgData.samples
        let samplingRate = 512.0
        
        // Calculate P-wave search window
        let pWaveSearchStart = Int((qrsComplex.qPeakTime - 0.2) * samplingRate)
        let pWaveSearchEnd = Int(qrsComplex.qPeakTime * samplingRate)
        
        guard pWaveSearchStart >= 0 && pWaveSearchEnd < samples.count else { return nil }
        
        let pWaveSamples = Array(samples[pWaveSearchStart..<pWaveSearchEnd])
        
        if let pWaveOnset = findPWaveOnset(samples: pWaveSamples),
           let pWaveOffset = findPWaveOffset(samples: pWaveSamples) {
            
            let duration = (pWaveOffset - pWaveOnset) / samplingRate * 1000.0 // ms
            let amplitude = pWaveSamples[pWaveOnset..<pWaveOffset].map { abs($0) }.max() ?? 0.0
            
            return PWaveMeasurement(
                duration: duration,
                amplitude: amplitude,
                timestamp: qrsComplex.rPeakTime
            )
        }
        
        return nil
    }
    
    private func getDemographicData() -> DemographicData {
        // For M2, return simulated demographic data
        // In production, this would come from user profile or HealthKit
        
        return DemographicData(
            age: 55, // Simulated age
            bmi: 28.5, // Simulated BMI
            gender: .male // Simulated gender
        )
    }
    
    private func getClinicalData() -> ClinicalData {
        // For M2, return simulated clinical data
        // In production, this would come from medical records or user input
        
        return ClinicalData(
            hasHypertension: false,
            hasDiabetes: false,
            hasHeartFailure: false,
            hasStroke: false
        )
    }
    
    private func storeExtractedFeatures(_ features: AFFeatures) {
        // Store features for trend analysis
        let pacEvent = PACEvent(
            density: features.pacDensity,
            timestamp: Date()
        )
        pacHistory.append(pacEvent)
        
        let pWaveMeasurement = PWaveMeasurement(
            duration: features.pWaveDispersion,
            amplitude: 0.0, // Not used for dispersion
            timestamp: Date().timeIntervalSince1970
        )
        pWaveHistory.append(pWaveMeasurement)
        
        let hrvMeasurement = HRVMeasurement(
            hrv: features.sleepHRV,
            laSizeProxy: features.laSizeProxy,
            timestamp: Date()
        )
        hrvHistory.append(hrvMeasurement)
        
        // Keep history manageable
        if pacHistory.count > 1000 {
            pacHistory.removeFirst(pacHistory.count - 1000)
        }
        if pWaveHistory.count > 1000 {
            pWaveHistory.removeFirst(pWaveHistory.count - 1000)
        }
        if hrvHistory.count > 1000 {
            hrvHistory.removeFirst(hrvHistory.count - 1000)
        }
    }
    
    private func calculateTrend(values: [Double]) -> TrendDirection {
        guard values.count >= 3 else { return .stable }
        
        // Simple trend calculation using linear regression
        let xValues = Array(0..<values.count).map { Double($0) }
        let slope = calculateLinearRegressionSlope(xValues: xValues, yValues: values)
        
        if slope > 0.01 {
            return .increasing
        } else if slope < -0.01 {
            return .decreasing
        } else {
            return .stable
        }
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
}

// MARK: - Supporting Types

struct PACEvent {
    let density: Double
    let timestamp: Date
}

struct PWaveMeasurement {
    let duration: Double // ms
    let amplitude: Double
    let timestamp: TimeInterval
}

struct HRVMeasurement {
    let hrv: Double // ms
    let laSizeProxy: Double // mm
    let timestamp: Date
}

struct DemographicData {
    let age: Int
    let bmi: Double
    let gender: Gender
}

struct ClinicalData {
    let hasHypertension: Bool
    let hasDiabetes: Bool
    let hasHeartFailure: Bool
    let hasStroke: Bool
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

struct AFFeatureTrends {
    let pacDensityTrend: TrendDirection
    let pWaveDispersionTrend: TrendDirection
    let hrvTrend: TrendDirection
    let laSizeTrend: TrendDirection
}

enum AFFeatureExtractionError: Error {
    case insufficientData
    case extractionError
    case invalidData
} 