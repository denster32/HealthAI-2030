import Foundation
import Accelerate
import CoreML

class ECGDataProcessor {
    
    // MARK: - Constants
    private let samplingRate: Double = 512.0 // Hz (typical for Apple Watch ECG)
    private let filterOrder = 4
    private let lowPassCutoff: Double = 40.0 // Hz
    private let highPassCutoff: Double = 0.5 // Hz
    private let notchFrequency: Double = 50.0 // Hz (for power line interference)
    
    // MARK: - Public Interface
    
    /// Process raw ECG data through the complete pipeline
    func processECGData(_ ecgData: ECGData) -> ProcessedECGData {
        print("ECG Data Processor: Processing \(ecgData.samples.count) samples")
        
        // Step 1: Pre-filtering
        let filteredData = applyBandpassFilter(ecgData.samples)
        
        // Step 2: Remove baseline wander
        let baselineCorrected = removeBaselineWander(filteredData)
        
        // Step 3: Remove power line interference
        let denoisedData = removePowerLineInterference(baselineCorrected)
        
        // Step 4: Normalize signal
        let normalizedData = normalizeSignal(denoisedData)
        
        // Step 5: Assess signal quality
        let quality = assessSignalQuality(normalizedData)
        
        return ProcessedECGData(
            samples: normalizedData,
            duration: ecgData.duration,
            timestamp: ecgData.timestamp,
            quality: quality
        )
    }
    
    /// Extract QRS complexes from processed ECG data
    func extractQRSComplexes(_ processedData: ProcessedECGData) -> [QRSComplex] {
        let samples = processedData.samples
        var qrsComplexes: [QRSComplex] = []
        
        // Use Pan-Tompkins algorithm for QRS detection
        let rPeaks = detectRPeaks(samples)
        
        for (index, rPeakIndex) in rPeaks.enumerated() {
            let qrsComplex = extractQRSComplex(samples: samples, rPeakIndex: rPeakIndex, index: index)
            qrsComplexes.append(qrsComplex)
        }
        
        print("ECG Data Processor: Extracted \(qrsComplexes.count) QRS complexes")
        return qrsComplexes
    }
    
    /// Extract RR intervals from QRS complexes
    func extractRRIntervals(_ qrsComplexes: [QRSComplex]) -> [RRInterval] {
        var rrIntervals: [RRInterval] = []
        
        for i in 1..<qrsComplexes.count {
            let currentRPeak = qrsComplexes[i].rPeakTime
            let previousRPeak = qrsComplexes[i-1].rPeakTime
            let rrInterval = currentRPeak - previousRPeak
            
            let rrIntervalData = RRInterval(
                interval: rrInterval,
                timestamp: currentRPeak,
                index: i
            )
            rrIntervals.append(rrIntervalData)
        }
        
        print("ECG Data Processor: Extracted \(rrIntervals.count) RR intervals")
        return rrIntervals
    }
    
    /// Extract QT intervals from QRS complexes
    func extractQTIntervals(_ qrsComplexes: [QRSComplex]) -> [QTInterval] {
        var qtIntervals: [QTInterval] = []
        
        for qrsComplex in qrsComplexes {
            if let qtInterval = calculateQTInterval(qrsComplex) {
                qtIntervals.append(qtInterval)
            }
        }
        
        print("ECG Data Processor: Extracted \(qtIntervals.count) QT intervals")
        return qtIntervals
    }
    
    /// Segment ECG data into analysis windows
    func segmentECGData(_ processedData: ProcessedECGData, windowSize: TimeInterval = 30.0) -> [ECGSegment] {
        let samplesPerWindow = Int(windowSize * samplingRate)
        let samples = processedData.samples
        var segments: [ECGSegment] = []
        
        for i in stride(from: 0, to: samples.count, by: samplesPerWindow) {
            let endIndex = min(i + samplesPerWindow, samples.count)
            let segmentSamples = Array(samples[i..<endIndex])
            
            let segment = ECGSegment(
                samples: segmentSamples,
                startTime: processedData.timestamp.addingTimeInterval(Double(i) / samplingRate),
                duration: Double(segmentSamples.count) / samplingRate,
                quality: assessSegmentQuality(segmentSamples)
            )
            segments.append(segment)
        }
        
        print("ECG Data Processor: Created \(segments.count) segments")
        return segments
    }
    
    // MARK: - Private Filtering Methods
    
    private func applyBandpassFilter(_ samples: [Double]) -> [Double] {
        // Apply high-pass filter first
        let highPassFiltered = applyHighPassFilter(samples)
        
        // Then apply low-pass filter
        let bandpassFiltered = applyLowPassFilter(highPassFiltered)
        
        return bandpassFiltered
    }
    
    private func applyHighPassFilter(_ samples: [Double]) -> [Double] {
        // Simple high-pass filter implementation
        // In production, this would use more sophisticated filtering
        let alpha = 1.0 / (1.0 + highPassCutoff / samplingRate)
        var filtered = [Double](repeating: 0.0, count: samples.count)
        
        if samples.count > 0 {
            filtered[0] = samples[0]
        }
        
        for i in 1..<samples.count {
            filtered[i] = alpha * (filtered[i-1] + samples[i] - samples[i-1])
        }
        
        return filtered
    }
    
    private func applyLowPassFilter(_ samples: [Double]) -> [Double] {
        // Simple low-pass filter implementation
        let alpha = lowPassCutoff / samplingRate
        var filtered = [Double](repeating: 0.0, count: samples.count)
        
        if samples.count > 0 {
            filtered[0] = samples[0]
        }
        
        for i in 1..<samples.count {
            filtered[i] = alpha * samples[i] + (1.0 - alpha) * filtered[i-1]
        }
        
        return filtered
    }
    
    private func removeBaselineWander(_ samples: [Double]) -> [Double] {
        // Remove baseline wander using moving average
        let windowSize = Int(samplingRate * 0.2) // 200ms window
        var baselineCorrected = [Double](repeating: 0.0, count: samples.count)
        
        for i in 0..<samples.count {
            let startIndex = max(0, i - windowSize / 2)
            let endIndex = min(samples.count, i + windowSize / 2)
            let window = Array(samples[startIndex..<endIndex])
            
            let baseline = window.reduce(0.0, +) / Double(window.count)
            baselineCorrected[i] = samples[i] - baseline
        }
        
        return baselineCorrected
    }
    
    private func removePowerLineInterference(_ samples: [Double]) -> [Double] {
        // Simple notch filter for power line interference
        // In production, this would use more sophisticated methods
        let notchWidth = 2.0 // Hz
        let samplesPerCycle = samplingRate / notchFrequency
        
        var denoised = samples
        
        for i in Int(samplesPerCycle)..<samples.count {
            let previousSample = denoised[i - Int(samplesPerCycle)]
            denoised[i] = (samples[i] + previousSample) / 2.0
        }
        
        return denoised
    }
    
    private func normalizeSignal(_ samples: [Double]) -> [Double] {
        guard !samples.isEmpty else { return samples }
        
        let maxAmplitude = samples.map { abs($0) }.max() ?? 1.0
        guard maxAmplitude > 0 else { return samples }
        
        return samples.map { $0 / maxAmplitude }
    }
    
    // MARK: - QRS Detection Methods
    
    private func detectRPeaks(_ samples: [Double]) -> [Int] {
        // Simplified R-peak detection using threshold crossing
        // In production, this would use the Pan-Tompkins algorithm
        var rPeaks: [Int] = []
        let threshold = 0.6 // Adaptive threshold would be better
        
        for i in 1..<samples.count-1 {
            if samples[i] > threshold && 
               samples[i] > samples[i-1] && 
               samples[i] > samples[i+1] {
                rPeaks.append(i)
            }
        }
        
        // Remove peaks that are too close together (minimum RR interval)
        let minRRInterval = Int(samplingRate * 0.3) // 300ms minimum
        var filteredPeaks: [Int] = []
        
        for peak in rPeaks {
            if filteredPeaks.isEmpty || peak - filteredPeaks.last! >= minRRInterval {
                filteredPeaks.append(peak)
            }
        }
        
        return filteredPeaks
    }
    
    private func extractQRSComplex(samples: [Double], rPeakIndex: Int, index: Int) -> QRSComplex {
        let rPeakTime = Double(rPeakIndex) / samplingRate
        let qrsWidth = Int(samplingRate * 0.12) // 120ms typical QRS width
        
        // Extract Q and S points
        let qIndex = max(0, rPeakIndex - qrsWidth / 2)
        let sIndex = min(samples.count - 1, rPeakIndex + qrsWidth / 2)
        
        let qPoint = samples[qIndex]
        let rPoint = samples[rPeakIndex]
        let sPoint = samples[sIndex]
        
        return QRSComplex(
            qPoint: qPoint,
            rPoint: rPoint,
            sPoint: sPoint,
            qPeakTime: Double(qIndex) / samplingRate,
            rPeakTime: rPeakTime,
            sPeakTime: Double(sIndex) / samplingRate,
            width: Double(qrsWidth) / samplingRate,
            index: index
        )
    }
    
    private func calculateQTInterval(_ qrsComplex: QRSComplex) -> QTInterval? {
        // Simplified QT interval calculation
        // In production, this would use more sophisticated T-wave detection
        let qtDuration = 0.4 // Simplified: 400ms typical QT interval
        
        return QTInterval(
            duration: qtDuration,
            startTime: qrsComplex.qPeakTime,
            endTime: qrsComplex.qPeakTime + qtDuration,
            index: qrsComplex.index
        )
    }
    
    // MARK: - Quality Assessment Methods
    
    private func assessSignalQuality(_ samples: [Double]) -> DataQuality {
        guard !samples.isEmpty else { return .poor }
        
        // Calculate signal-to-noise ratio (simplified)
        let signalPower = samples.map { $0 * $0 }.reduce(0.0, +) / Double(samples.count)
        let noisePower = calculateNoisePower(samples)
        
        let snr = signalPower / (noisePower + 1e-10)
        
        switch snr {
        case 0..<1.0:
            return .poor
        case 1.0..<3.0:
            return .fair
        case 3.0..<10.0:
            return .good
        default:
            return .excellent
        }
    }
    
    private func calculateNoisePower(_ samples: [Double]) -> Double {
        // Simplified noise power calculation
        // In production, this would use more sophisticated methods
        let mean = samples.reduce(0.0, +) / Double(samples.count)
        let variance = samples.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(samples.count)
        return variance
    }
    
    private func assessSegmentQuality(_ samples: [Double]) -> DataQuality {
        return assessSignalQuality(samples)
    }
}

// MARK: - Supporting Types

struct QRSComplex {
    let qPoint: Double
    let rPoint: Double
    let sPoint: Double
    let qPeakTime: TimeInterval
    let rPeakTime: TimeInterval
    let sPeakTime: TimeInterval
    let width: TimeInterval
    let index: Int
}

struct RRInterval {
    let interval: TimeInterval
    let timestamp: TimeInterval
    let index: Int
}

struct QTInterval {
    let duration: TimeInterval
    let startTime: TimeInterval
    let endTime: TimeInterval
    let index: Int
}

struct ECGSegment {
    let samples: [Double]
    let startTime: Date
    let duration: TimeInterval
    let quality: DataQuality
}