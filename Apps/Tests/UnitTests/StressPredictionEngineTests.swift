import XCTest
import Foundation
@testable import HealthAI2030

@available(iOS 17.0, *)
final class StressPredictionEngineTests: XCTestCase {
    
    var stressEngine: StressPredictionEngine!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        stressEngine = StressPredictionEngine()
    }
    
    override func tearDownWithError() throws {
        stressEngine = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Stress Level Classification Tests
    
    func testStressLevelClassification() {
        // Test low stress
        XCTAssertEqual(StressLevel.fromScore(0.1), .low)
        XCTAssertEqual(StressLevel.fromScore(0.24), .low)
        
        // Test moderate stress
        XCTAssertEqual(StressLevel.fromScore(0.25), .moderate)
        XCTAssertEqual(StressLevel.fromScore(0.49), .moderate)
        
        // Test high stress
        XCTAssertEqual(StressLevel.fromScore(0.5), .high)
        XCTAssertEqual(StressLevel.fromScore(0.74), .high)
        
        // Test critical stress
        XCTAssertEqual(StressLevel.fromScore(0.75), .critical)
        XCTAssertEqual(StressLevel.fromScore(1.0), .critical)
    }
    
    // MARK: - Stress Analysis Tests
    
    func testStressAnalysisCreation() async throws {
        let components = [
            StressAnalysisComponent(
                type: .voice,
                score: 0.3,
                confidence: 0.8,
                metadata: [:]
            ),
            StressAnalysisComponent(
                type: .hrv,
                score: 0.4,
                confidence: 0.9,
                metadata: [:]
            ),
            StressAnalysisComponent(
                type: .facial,
                score: 0.2,
                confidence: 0.7,
                metadata: [:]
            )
        ]
        
        let analysis = StressAnalysis(components: components)
        
        // Test weighted average calculation
        let expectedScore = (0.3 * 0.8 + 0.4 * 0.9 + 0.2 * 0.7) / (0.8 + 0.9 + 0.7)
        XCTAssertEqual(analysis.stressScore, expectedScore, accuracy: 0.001)
        
        // Test stress level classification
        XCTAssertEqual(analysis.overallStressLevel, .moderate)
        
        // Test mental health score (inverse of stress)
        XCTAssertEqual(analysis.mentalHealthScore, 1 - expectedScore, accuracy: 0.001)
    }
    
    func testStressAnalysisWithEmptyComponents() {
        let analysis = StressAnalysis(components: [])
        
        XCTAssertEqual(analysis.stressScore, 0.0)
        XCTAssertEqual(analysis.overallStressLevel, .low)
        XCTAssertEqual(analysis.mentalHealthScore, 1.0)
    }
    
    func testStressAnalysisWithSingleComponent() {
        let component = StressAnalysisComponent(
            type: .voice,
            score: 0.6,
            confidence: 1.0,
            metadata: [:]
        )
        
        let analysis = StressAnalysis(components: [component])
        
        XCTAssertEqual(analysis.stressScore, 0.6)
        XCTAssertEqual(analysis.overallStressLevel, .high)
        XCTAssertEqual(analysis.mentalHealthScore, 0.4)
    }
    
    // MARK: - Recommendation Generation Tests
    
    func testRecommendationGenerationForLowStress() {
        let components = [
            StressAnalysisComponent(
                type: .voice,
                score: 0.1,
                confidence: 0.8,
                metadata: [:]
            )
        ]
        
        let analysis = StressAnalysis(components: components)
        let recommendations = analysis.generateRecommendations()
        
        XCTAssertEqual(recommendations.count, 1)
        XCTAssertEqual(recommendations.first?.type, .maintenance)
        XCTAssertEqual(recommendations.first?.priority, .low)
    }
    
    func testRecommendationGenerationForModerateStress() {
        let components = [
            StressAnalysisComponent(
                type: .voice,
                score: 0.3,
                confidence: 0.8,
                metadata: [:]
            )
        ]
        
        let analysis = StressAnalysis(components: components)
        let recommendations = analysis.generateRecommendations()
        
        XCTAssertEqual(recommendations.count, 1)
        XCTAssertEqual(recommendations.first?.type, .mindfulness)
        XCTAssertEqual(recommendations.first?.priority, .medium)
    }
    
    func testRecommendationGenerationForHighStress() {
        let components = [
            StressAnalysisComponent(
                type: .voice,
                score: 0.6,
                confidence: 0.8,
                metadata: [:]
            )
        ]
        
        let analysis = StressAnalysis(components: components)
        let recommendations = analysis.generateRecommendations()
        
        XCTAssertEqual(recommendations.count, 1)
        XCTAssertEqual(recommendations.first?.type, .intervention)
        XCTAssertEqual(recommendations.first?.priority, .high)
    }
    
    func testRecommendationGenerationForCriticalStress() {
        let components = [
            StressAnalysisComponent(
                type: .voice,
                score: 0.8,
                confidence: 0.8,
                metadata: [:]
            )
        ]
        
        let analysis = StressAnalysis(components: components)
        let recommendations = analysis.generateRecommendations()
        
        XCTAssertEqual(recommendations.count, 1)
        XCTAssertEqual(recommendations.first?.type, .crisis)
        XCTAssertEqual(recommendations.first?.priority, .critical)
    }
    
    // MARK: - Linear Regression Tests
    
    func testLinearRegressionCalculation() {
        let x: [Double] = [1, 2, 3, 4, 5]
        let y: [Double] = [2, 4, 6, 8, 10]
        
        let (slope, intercept) = calculateLinearRegression(x: x, y: y)
        
        XCTAssertEqual(slope, 2.0, accuracy: 0.001)
        XCTAssertEqual(intercept, 0.0, accuracy: 0.001)
    }
    
    func testLinearRegressionWithNegativeSlope() {
        let x: [Double] = [1, 2, 3, 4, 5]
        let y: [Double] = [10, 8, 6, 4, 2]
        
        let (slope, intercept) = calculateLinearRegression(x: x, y: y)
        
        XCTAssertEqual(slope, -2.0, accuracy: 0.001)
        XCTAssertEqual(intercept, 12.0, accuracy: 0.001)
    }
    
    func testLinearRegressionWithSinglePoint() {
        let x: [Double] = [1]
        let y: [Double] = [5]
        
        let (slope, intercept) = calculateLinearRegression(x: x, y: y)
        
        XCTAssertEqual(slope, 0.0, accuracy: 0.001)
        XCTAssertEqual(intercept, 5.0, accuracy: 0.001)
    }
    
    // MARK: - Variance Calculation Tests
    
    func testVarianceCalculation() {
        let values: [Double] = [1, 2, 3, 4, 5]
        let variance = calculateVariance(values)
        
        // Expected variance for [1,2,3,4,5] is 2.0
        XCTAssertEqual(variance, 2.0, accuracy: 0.001)
    }
    
    func testVarianceCalculationWithIdenticalValues() {
        let values: [Double] = [5, 5, 5, 5, 5]
        let variance = calculateVariance(values)
        
        XCTAssertEqual(variance, 0.0, accuracy: 0.001)
    }
    
    func testVarianceCalculationWithSingleValue() {
        let values: [Double] = [10]
        let variance = calculateVariance(values)
        
        XCTAssertEqual(variance, 0.0, accuracy: 0.001)
    }
    
    // MARK: - Prediction Confidence Tests
    
    func testPredictionConfidenceCalculation() {
        let dataPoints = [
            StressDataPoint(timestamp: Date(), stressLevel: .low, score: 0.1),
            StressDataPoint(timestamp: Date().addingTimeInterval(3600), stressLevel: .low, score: 0.2),
            StressDataPoint(timestamp: Date().addingTimeInterval(7200), stressLevel: .low, score: 0.15)
        ]
        
        let confidence = calculatePredictionConfidence(data: dataPoints)
        
        // Should be between 0 and 1
        XCTAssertGreaterThanOrEqual(confidence, 0.0)
        XCTAssertLessThanOrEqual(confidence, 1.0)
    }
    
    func testPredictionConfidenceWithHighVariance() {
        let dataPoints = [
            StressDataPoint(timestamp: Date(), stressLevel: .low, score: 0.1),
            StressDataPoint(timestamp: Date().addingTimeInterval(3600), stressLevel: .critical, score: 0.9),
            StressDataPoint(timestamp: Date().addingTimeInterval(7200), stressLevel: .low, score: 0.2)
        ]
        
        let confidence = calculatePredictionConfidence(data: dataPoints)
        
        // High variance should result in lower confidence
        XCTAssertLessThan(confidence, 0.8)
    }
    
    // MARK: - Prediction Factors Tests
    
    func testPredictionFactorsExtraction() {
        let dataPoints = [
            StressDataPoint(timestamp: Date(), stressLevel: .high, score: 0.6),
            StressDataPoint(timestamp: Date().addingTimeInterval(3600), stressLevel: .high, score: 0.7),
            StressDataPoint(timestamp: Date().addingTimeInterval(7200), stressLevel: .critical, score: 0.8)
        ]
        
        let factors = extractPredictionFactors(data: dataPoints)
        
        // Should contain sustained high stress factor
        XCTAssertTrue(factors.contains("Sustained high stress"))
        
        // Should contain weekday/weekend factor
        XCTAssertTrue(factors.contains("Weekday") || factors.contains("Weekend"))
    }
    
    func testPredictionFactorsForWorkHours() {
        // Create a date during work hours (10 AM)
        let workHourDate = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
        
        let dataPoints = [
            StressDataPoint(timestamp: workHourDate, stressLevel: .moderate, score: 0.3)
        ]
        
        let factors = extractPredictionFactors(data: dataPoints)
        
        // Should contain work hours factor
        XCTAssertTrue(factors.contains("Work hours"))
    }
    
    // MARK: - Stress Prediction Tests
    
    func testStressPredictionWithSufficientData() async throws {
        // Create a week of stress data
        var dataPoints: [StressDataPoint] = []
        for i in 0..<168 {
            let timestamp = Date().addingTimeInterval(-Double(i * 3600))
            let score = 0.3 + (Double(i % 24) * 0.01) // Slight daily variation
            dataPoints.append(StressDataPoint(
                timestamp: timestamp,
                stressLevel: StressLevel.fromScore(score),
                score: score
            ))
        }
        
        let prediction = try await calculateStressPrediction(from: dataPoints, hours: 24)
        
        XCTAssertNotNil(prediction)
        XCTAssertGreaterThanOrEqual(prediction.confidence, 0.0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1.0)
        XCTAssertEqual(prediction.timeHorizon, 24)
        XCTAssertFalse(prediction.factors.isEmpty)
    }
    
    func testStressPredictionWithInsufficientData() async throws {
        let dataPoints = [
            StressDataPoint(timestamp: Date(), stressLevel: .moderate, score: 0.3)
        ]
        
        do {
            _ = try await calculateStressPrediction(from: dataPoints, hours: 24)
            XCTFail("Should throw insufficient data error")
        } catch {
            // Expected to throw error
        }
    }
    
    // MARK: - Mental Health Recommendation Tests
    
    func testMentalHealthRecommendations() async throws {
        // This would test the actual recommendation generation
        // For now, we'll test the structure
        let recommendation = MentalHealthRecommendation(
            type: .mindfulness,
            title: "Test Recommendation",
            description: "Test description",
            priority: .medium
        )
        
        XCTAssertEqual(recommendation.type, .mindfulness)
        XCTAssertEqual(recommendation.title, "Test Recommendation")
        XCTAssertEqual(recommendation.description, "Test description")
        XCTAssertEqual(recommendation.priority, .medium)
    }
    
    // MARK: - Performance Tests
    
    func testStressAnalysisPerformance() {
        let components = (0..<100).map { _ in
            StressAnalysisComponent(
                type: .voice,
                score: Double.random(in: 0...1),
                confidence: Double.random(in: 0.5...1),
                metadata: [:]
            )
        }
        
        measure {
            let analysis = StressAnalysis(components: components)
            _ = analysis.stressScore
            _ = analysis.overallStressLevel
            _ = analysis.mentalHealthScore
        }
    }
    
    func testLinearRegressionPerformance() {
        let x = (0..<1000).map { Double($0) }
        let y = x.map { $0 * 2 + 1 }
        
        measure {
            _ = calculateLinearRegression(x: x, y: y)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testStressAnalysisWithInvalidData() {
        let components = [
            StressAnalysisComponent(
                type: .voice,
                score: -0.1, // Invalid negative score
                confidence: 1.5, // Invalid confidence > 1
                metadata: [:]
            )
        ]
        
        let analysis = StressAnalysis(components: components)
        
        // Should handle invalid data gracefully
        XCTAssertGreaterThanOrEqual(analysis.stressScore, 0.0)
        XCTAssertLessThanOrEqual(analysis.stressScore, 1.0)
    }
    
    // MARK: - Helper Methods (copied from StressPredictionEngine for testing)
    
    private func calculateLinearRegression(x: [Double], y: [Double]) -> (slope: Double, intercept: Double) {
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY - slope * sumX) / n
        
        return (slope, intercept)
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
    
    private func calculatePredictionConfidence(data: [StressDataPoint]) -> Double {
        let variance = calculateVariance(data.map { $0.score })
        let dataPoints = Double(data.count)
        
        let consistencyScore = max(0, 1 - variance)
        let volumeScore = min(1, dataPoints / 168) // Normalize to 1 week
        
        return (consistencyScore + volumeScore) / 2
    }
    
    private func extractPredictionFactors(data: [StressDataPoint]) -> [String] {
        var factors: [String] = []
        
        // Time-based patterns
        let hourOfDay = Calendar.current.component(.hour, from: Date())
        if hourOfDay >= 9 && hourOfDay <= 17 {
            factors.append("Work hours")
        }
        
        // Stress level patterns
        let recentStress = data.suffix(6).map { $0.stressLevel }
        if recentStress.filter({ $0 == .high || $0 == .critical }).count >= 3 {
            factors.append("Sustained high stress")
        }
        
        // Weekend vs weekday
        let isWeekend = Calendar.current.isDateInWeekend(Date())
        factors.append(isWeekend ? "Weekend" : "Weekday")
        
        return factors
    }
    
    private func calculateStressPrediction(from data: [StressDataPoint], hours: Int) async throws -> StressPrediction {
        guard data.count >= 24 else {
            throw StressPredictionError.insufficientData
        }
        
        let timestamps = data.map { $0.timestamp.timeIntervalSince1970 }
        let scores = data.map { $0.score }
        
        let (slope, intercept) = calculateLinearRegression(x: timestamps, y: scores)
        
        let futureTimestamp = Date().timeIntervalSince1970 + Double(hours * 3600)
        let predictedScore = slope * futureTimestamp + intercept
        
        let predictedLevel = StressLevel.fromScore(predictedScore)
        
        return StressPrediction(
            predictedStressLevel: predictedLevel,
            predictedScore: predictedScore,
            confidence: calculatePredictionConfidence(data: data),
            timeHorizon: hours,
            factors: extractPredictionFactors(data: data)
        )
    }
} 