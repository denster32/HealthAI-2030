import Foundation
import Accelerate

/// Analyzes model drift using statistical methods
public final class ModelDriftAnalyzer {
    private let windowSize: Int
    private var referenceDistribution: [Double]
    private var movingWindow: [Double]
    private var currentIndex = 0
    private var alertThreshold: Double
    
    /// Initialize analyzer with reference distribution
    /// - Parameters:
    ///   - referenceDistribution: Baseline distribution to compare against
    ///   - windowSize: Size of moving window for tracking
    ///   - alertThreshold: KS test threshold for alerts (default: 0.05)
    public init(
        referenceDistribution: [Double],
        windowSize: Int = 100,
        alertThreshold: Double = 0.05
    ) {
        self.referenceDistribution = referenceDistribution.sorted()
        self.windowSize = windowSize
        self.movingWindow = Array(repeating: 0.0, count: windowSize)
        self.alertThreshold = alertThreshold
    }
    
    /// Update analyzer with new prediction score
    /// - Returns: Tuple containing (driftDetected: Bool, ksStatistic: Double, confidenceInterval: (lower: Double, upper: Double))
    public func update(with value: Double) -> (driftDetected: Bool, ksStatistic: Double, confidenceInterval: (lower: Double, upper: Double)) {
        // Update moving window
        movingWindow[currentIndex] = value
        currentIndex = (currentIndex + 1) % windowSize
        
        // Calculate KS statistic
        let ksStatistic = calculateKSStatistic()
        
        // Calculate moving average and confidence interval
        let (mean, stdDev) = calculateStats()
        let confidenceInterval = (mean - 1.96 * stdDev, mean + 1.96 * stdDev)
        
        // Check against threshold
        let driftDetected = ksStatistic > alertThreshold
        
        return (driftDetected, ksStatistic, confidenceInterval)
    }
    
    private func calculateKSStatistic() -> Double {
        let currentSample = movingWindow.filter { $0 != 0 }.sorted()
        guard !currentSample.isEmpty else { return 0.0 }
        
        let n = currentSample.count
        let m = referenceDistribution.count
        var i = 0
        var j = 0
        var d = 0.0
        var fn1 = 0.0
        var fn2 = 0.0
        
        while i < n && j < m {
            let x1 = currentSample[i]
            let x2 = referenceDistribution[j]
            
            if x1 <= x2 {
                fn1 = Double(i + 1) / Double(n)
                i += 1
            }
            if x2 <= x1 {
                fn2 = Double(j + 1) / Double(m)
                j += 1
            }
            
            d = max(d, abs(fn1 - fn2))
        }
        
        return d
    }
    
    private func calculateStats() -> (mean: Double, stdDev: Double) {
        var mean = 0.0
        var stdDev = 0.0
        
        vDSP_meanvD(movingWindow, 1, &mean, vDSP_Length(windowSize))
        vDSP_normalizeD(movingWindow, 1, nil, 1, &stdDev, vDSP_Length(windowSize))
        
        return (mean, stdDev)
    }
    
    /// Update reference distribution
    public func updateReferenceDistribution(_ newDistribution: [Double]) {
        self.referenceDistribution = newDistribution.sorted()
    }
}