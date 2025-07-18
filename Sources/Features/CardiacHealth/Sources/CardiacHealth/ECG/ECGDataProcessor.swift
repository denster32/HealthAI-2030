import Foundation
import CoreML
import QuartzCore

/// ECGDataProcessor
///
/// Provides high-performance ECG signal processing and anomaly detection.
/// - Filters raw ECG data using a moving average filter.
/// - Detects anomalies using Core ML or CPU fallback.
/// - Tracks performance and memory usage.
/// - Checks for device memory constraints (e.g., Apple Watch).
@available(iOS 18.0, macOS 15.0, *)
public class ECGDataProcessor {
    
    // MARK: - Performance Metrics
    private var processingStartTime: CFTimeInterval = 0
    private var memoryBeforeProcessing: UInt64 = 0
    
    /// Initialize a new ECGDataProcessor.
    public init() {}
    
    /// Start performance tracking (internal use).
    private func startPerformanceTracking() {
        processingStartTime = CACurrentMediaTime()
        memoryBeforeProcessing = reportMemoryUsage()
    }
    
    /// End performance tracking and return metrics (internal use).
    private func endPerformanceTracking() -> (time: Double, memory: Int64) {
        let processingTime = (CACurrentMediaTime() - processingStartTime) * 1000
        let memoryUsed = Int64(reportMemoryUsage() - memoryBeforeProcessing)
        return (processingTime, memoryUsed)
    }
    
    /// Report current memory usage (internal use).
    private func reportMemoryUsage() -> UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return kerr == KERN_SUCCESS ? taskInfo.resident_size : 0
    }
    
    // MARK: - Signal Processing
    /// Process raw ECG data with a moving average filter.
    /// - Parameter samples: Raw ECG samples.
    /// - Returns: Filtered ECG samples.
    public func processECGData(_ samples: [Float]) -> [Float] {
        startPerformanceTracking()
        defer {
            let metrics = endPerformanceTracking()
            print("Processing time: \(metrics.time)ms, Memory used: \(metrics.memory) bytes")
        }
        
        // Use CPU processing for now (can be enhanced with Metal later)
        return processWithCPU(samples)
    }
    
    /// CPU implementation of moving average filter.
    private func processWithCPU(_ samples: [Float]) -> [Float] {
        // CPU implementation with moving average filter
        var processed = [Float](repeating: 0, count: samples.count)
        
        // Simple moving average filter
        let windowSize = 5
        for i in 0..<samples.count {
            var sum: Float = 0
            var count = 0
            for j in -windowSize/2...windowSize/2 {
                let index = i + j
                if index >= 0 && index < samples.count {
                    sum += samples[index]
                    count += 1
                }
            }
            processed[i] = sum / Float(count)
        }
        
        return processed
    }
    
    // MARK: - Core ML Integration
    private let mlModel: CardioAnomalyDetector? = {
        guard let model = try? CardioAnomalyDetector(configuration: .init()) else {
            print("Failed to load Core ML model")
            return nil
        }
        return model
    }()
    
    /// Detect anomalies in ECG data using Core ML or CPU fallback.
    /// - Parameter samples: Filtered ECG samples.
    /// - Returns: Dictionary of anomaly probabilities.
    public func detectAnomalies(_ samples: [Float]) -> [String: Double] {
        // Watch Series 3 has limited memory (max 15MB)
        if ProcessInfo.processInfo.deviceModel == "Watch3,1" {
            return detectAnomaliesWithCPU(samples)
        }
        
        guard let model = mlModel else {
            return detectAnomaliesWithCPU(samples)
        }
        
        do {
            let input = CardioAnomalyDetectorInput(ecgSignal: samples)
            let output = try model.prediction(input: input)
            return output.classProbability
        } catch {
            print("Core ML error: \(error)")
            return detectAnomaliesWithCPU(samples)
        }
    }
    
    /// CPU fallback for anomaly detection (simple variance-based logic).
    private func detectAnomaliesWithCPU(_ samples: [Float]) -> [String: Double] {
        // Simplified CPU-based anomaly detection
        // This is a placeholder - real implementation would be more complex
        let mean = samples.reduce(0, +) / Float(samples.count)
        let variance = samples.map { pow($0 - mean, 2) }.reduce(0, +) / Float(samples.count)
        
        return [
            "normal": Double(max(0, 1 - (variance * 0.1))),
            "afib": Double(min(1, variance * 0.05)),
            "tachycardia": Double(min(1, variance * 0.03))
        ]
    }
    
    // MARK: - Memory Constraints
    /// Check if device is within memory constraints for ECG processing.
    /// - Returns: True if memory usage is acceptable.
    public func checkMemoryConstraints() -> Bool {
        let memoryUsage = reportMemoryUsage()
        if ProcessInfo.processInfo.isiPodAppOnMac {
            return memoryUsage < 15 * 1024 * 1024 // 15MB limit for Watch
        }
        return true // No strict limits for other devices
    }
}

// Device model extension
extension ProcessInfo {
    var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(cString: ptr)
            }
        }
        return modelCode
    }
    
    var isiPodAppOnMac: Bool {
        #if os(watchOS)
        return true
        #else
        return false
        #endif
    }
}

// Placeholder Core ML model classes (these would be generated from actual .mlmodel files)
@available(iOS 18.0, macOS 15.0, *)
public class CardioAnomalyDetector {
    public init(configuration: MLModelConfiguration) throws {
        // Placeholder implementation
    }
    
    public func prediction(input: CardioAnomalyDetectorInput) throws -> CardioAnomalyDetectorOutput {
        // Placeholder implementation
        return CardioAnomalyDetectorOutput(classProbability: ["normal": 0.8, "afib": 0.1, "tachycardia": 0.1])
    }
}

@available(iOS 18.0, macOS 15.0, *)
public class CardioAnomalyDetectorInput {
    public let ecgSignal: [Float]
    
    public init(ecgSignal: [Float]) {
        self.ecgSignal = ecgSignal
    }
}

@available(iOS 18.0, macOS 15.0, *)
public class CardioAnomalyDetectorOutput {
    public let classProbability: [String: Double]
    
    public init(classProbability: [String: Double]) {
        self.classProbability = classProbability
    }
}