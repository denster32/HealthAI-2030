import Foundation

class AnalyticsUtilities {
    static func validateModelAccuracy(predictions: [Double], groundTruth: [Double]) -> Double {
        guard predictions.count == groundTruth.count, !predictions.isEmpty else { return 0.0 }
        let diffs = zip(predictions, groundTruth).map { abs($0 - $1) }
        let meanError = diffs.reduce(0, +) / Double(diffs.count)
        return 1.0 - meanError // 1 = perfect, 0 = worst
    }
    
    static func runRegressionTest(on model: (Double) -> Double, testCases: [(input: Double, expected: Double)]) -> Bool {
        for testCase in testCases {
            let result = model(testCase.input)
            if abs(result - testCase.expected) > 0.05 {
                return false
            }
        }
        return true
    }
    
    static func generateAnalyticsReport(metrics: [String: Double]) -> String {
        return metrics.map { "\($0): \($1)" }.joined(separator: "\n")
    }
} 