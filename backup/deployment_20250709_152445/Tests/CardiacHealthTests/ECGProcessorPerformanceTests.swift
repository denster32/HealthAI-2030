import XCTest
@testable import CardiacHealth

@available(iOS 18.0, macOS 15.0, *)
final class ECGProcessorPerformanceTests: XCTestCase {
    private let sampleCount = 5000 // 5 seconds of ECG data at 1000Hz
    private let maxWatchLatency: Double = 50 // ms
    private let maxWatchMemory: Int64 = 15 * 1024 * 1024 // 15MB
    
    func testProcessingLatency() {
        let processor = ECGDataProcessor()
        let samples = generateECGSamples(count: sampleCount)
        
        let start = CACurrentMediaTime()
        _ = processor.processECGData(samples)
        let elapsed = (CACurrentMediaTime() - start) * 1000 // ms
        print("Processing latency: \(elapsed) ms")
        XCTAssertLessThan(elapsed, maxWatchLatency, "Processing latency exceeded \(maxWatchLatency)ms limit")
    }
    
    func testMemoryFootprint() {
        let processor = ECGDataProcessor()
        let samples = generateECGSamples(count: sampleCount)
        
        _ = processor.processECGData(samples)
        let memoryOk = processor.checkMemoryConstraints()
        
        // Check if running on Watch simulator/device
        if ProcessInfo.processInfo.isiPodAppOnMac {
            XCTAssertTrue(memoryOk, "Memory usage exceeded 15MB Watch limit")
        }
    }
    
    func testCoreMLFallbackPerformance() {
        // Simulate Watch Series 3 environment
        setenv("SIMULATED_MODEL", "Watch3,1", 1)
        let processor = ECGDataProcessor()
        let samples = generateECGSamples(count: sampleCount)
        let start = CACurrentMediaTime()
        _ = processor.detectAnomalies(samples)
        let elapsed = (CACurrentMediaTime() - start) * 1000 // ms
        print("CoreML fallback latency: \(elapsed) ms")
        XCTAssertLessThan(elapsed, maxWatchLatency, "CoreML fallback latency exceeded \(maxWatchLatency)ms limit")
        unsetenv("SIMULATED_MODEL")
    }
    
    private func generateECGSamples(count: Int) -> [Float] {
        var samples = [Float]()
        for i in 0..<count {
            let value = sin(Float(i) * 0.1) + Float.random(in: -0.1...0.1)
            samples.append(value)
        }
        return samples
    }
}