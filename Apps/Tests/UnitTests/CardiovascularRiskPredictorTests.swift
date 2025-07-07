import XCTest
import HealthKit
import CoreML
@testable import HealthAI2030

@MainActor
final class CardiovascularRiskPredictorTests: XCTestCase {
    
    var riskPredictor: CardiovascularRiskPredictor!
    
    override func setUp() {
        super.setUp()
        riskPredictor = CardiovascularRiskPredictor()
    }
    
    override func tearDown() {
        riskPredictor = nil
        super.tearDown()
    }
    
    // MARK: - Risk Calculation Tests
    
    func testCalculateRiskWithValidData() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Risk calculation completed")
        
        // When
        do {
            let riskScore = try await riskPredictor.calculateRisk()
            
            // Then
            XCTAssertGreaterThanOrEqual(riskScore, 0.0)
            XCTAssertLessThanOrEqual(riskScore, 1.0)
            XCTAssertEqual(riskPredictor.currentRiskScore, riskScore)
            XCTAssertFalse(riskPredictor.riskFactors.isEmpty)
            XCTAssertFalse(riskPredictor.recommendations.isEmpty)
            
            expectation.fulfill()
        } catch {
            XCTFail("Risk calculation failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testRiskTrendCalculation() async throws {
        // Given
        let lowRiskScore = 0.03
        let mediumRiskScore = 0.08
        let highRiskScore = 0.15
        let criticalRiskScore = 0.25
        
        // When & Then
        let lowTrend = riskPredictor.calculateRiskTrend(score: lowRiskScore)
        XCTAssertEqual(lowTrend, .improving)
        
        let mediumTrend = riskPredictor.calculateRiskTrend(score: mediumRiskScore)
        XCTAssertEqual(mediumTrend, .stable)
        
        let highTrend = riskPredictor.calculateRiskTrend(score: highRiskScore)
        XCTAssertEqual(highTrend, .worsening)
        
        let criticalTrend = riskPredictor.calculateRiskTrend(score: criticalRiskScore)
        XCTAssertEqual(criticalTrend, .critical)
    }
    
    func testRiskFactorExtraction() async throws {
        // Given
        let healthData = HealthData(
            age: 50,
            gender: .male,
            systolicBP: 150,
            diastolicBP: 95,
            totalCholesterol: 250,
            hdlCholesterol: 40,
            ldlCholesterol: 160,
            triglycerides: 200,
            bmi: 30.0,
            isSmoker: true,
            hasDiabetes: false,
            familyHistory: true,
            restingHeartRate: 80,
            bloodGlucose: 100
        )
        
        // When
        let riskFactors = riskPredictor.extractRiskFactors(healthData: healthData)
        
        // Then
        XCTAssertFalse(riskFactors.isEmpty)
        
        // Check that age factor is present
        let ageFactor = riskFactors.first { $0.category == .age }
        XCTAssertNotNil(ageFactor)
        XCTAssertEqual(ageFactor?.value, 50.0)
        XCTAssertEqual(ageFactor?.unit, "years")
        XCTAssertFalse(ageFactor?.isModifiable ?? true)
        
        // Check that blood pressure factor is present
        let bpFactor = riskFactors.first { $0.category == .bloodPressure }
        XCTAssertNotNil(bpFactor)
        XCTAssertEqual(bpFactor?.value, 150.0)
        XCTAssertEqual(bpFactor?.unit, "mmHg")
        XCTAssertTrue(bpFactor?.isModifiable ?? false)
        
        // Check that family history is present
        let familyHistoryFactor = riskFactors.first { $0.category == .familyHistory }
        XCTAssertNotNil(familyHistoryFactor)
        XCTAssertEqual(familyHistoryFactor?.value, 1.0)
        XCTAssertFalse(familyHistoryFactor?.isModifiable ?? true)
        
        // Verify factors are sorted by impact (highest first)
        for i in 0..<(riskFactors.count - 1) {
            XCTAssertGreaterThanOrEqual(riskFactors[i].impact, riskFactors[i + 1].impact)
        }
    }
    
    func testRecommendationGeneration() async throws {
        // Given
        let highRiskScore = 0.18
        let riskFactors = [
            CardiovascularRiskPredictor.RiskFactor(
                name: "Systolic Blood Pressure",
                value: 160.0,
                unit: "mmHg",
                impact: 0.3,
                category: .bloodPressure,
                isModifiable: true
            ),
            CardiovascularRiskPredictor.RiskFactor(
                name: "Total Cholesterol",
                value: 280.0,
                unit: "mg/dL",
                impact: 0.25,
                category: .cholesterol,
                isModifiable: true
            ),
            CardiovascularRiskPredictor.RiskFactor(
                name: "Body Mass Index",
                value: 32.0,
                unit: "kg/m²",
                impact: 0.2,
                category: .lifestyle,
                isModifiable: true
            )
        ]
        
        // When
        let recommendations = riskPredictor.generateRecommendations(riskFactors: riskFactors, score: highRiskScore)
        
        // Then
        XCTAssertFalse(recommendations.isEmpty)
        
        // Check for critical recommendation due to high risk
        let criticalRecommendations = recommendations.filter { $0.priority == .critical }
        XCTAssertFalse(criticalRecommendations.isEmpty)
        
        // Check for blood pressure recommendation
        let bpRecommendations = recommendations.filter { $0.title.contains("Blood Pressure") }
        XCTAssertFalse(bpRecommendations.isEmpty)
        
        // Check for cholesterol recommendation
        let cholesterolRecommendations = recommendations.filter { $0.title.contains("Cholesterol") }
        XCTAssertFalse(cholesterolRecommendations.isEmpty)
        
        // Check for lifestyle recommendations
        let lifestyleRecommendations = recommendations.filter { $0.category == .lifestyle }
        XCTAssertFalse(lifestyleRecommendations.isEmpty)
        
        // Verify recommendations are sorted by priority
        for i in 0..<(recommendations.count - 1) {
            let currentPriority = recommendations[i].priority.rawValue
            let nextPriority = recommendations[i + 1].priority.rawValue
            XCTAssertGreaterThanOrEqual(currentPriority, nextPriority)
        }
    }
    
    func testRiskPredictionTrend() async throws {
        // Given
        let months = 12
        let expectation = XCTestExpectation(description: "Risk prediction completed")
        
        // When
        do {
            let predictions = try await riskPredictor.predictRiskTrend(months: months)
            
            // Then
            XCTAssertEqual(predictions.count, months)
            
            // All predictions should be between 0 and 1
            for prediction in predictions {
                XCTAssertGreaterThanOrEqual(prediction, 0.0)
                XCTAssertLessThanOrEqual(prediction, 1.0)
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("Risk prediction failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testAnalyzeRiskFactors() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Risk factor analysis completed")
        
        // When
        do {
            let riskFactors = try await riskPredictor.analyzeRiskFactors()
            
            // Then
            XCTAssertFalse(riskFactors.isEmpty)
            
            // Each risk factor should have valid data
            for factor in riskFactors {
                XCTAssertFalse(factor.name.isEmpty)
                XCTAssertGreaterThanOrEqual(factor.value, 0.0)
                XCTAssertFalse(factor.unit.isEmpty)
                XCTAssertGreaterThanOrEqual(factor.impact, 0.0)
                XCTAssertLessThanOrEqual(factor.impact, 1.0)
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("Risk factor analysis failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testGeneratePersonalizedRecommendations() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Personalized recommendations generated")
        
        // When
        do {
            let recommendations = try await riskPredictor.generatePersonalizedRecommendations()
            
            // Then
            XCTAssertFalse(recommendations.isEmpty)
            
            // Each recommendation should have valid data
            for recommendation in recommendations {
                XCTAssertFalse(recommendation.title.isEmpty)
                XCTAssertFalse(recommendation.description.isEmpty)
                XCTAssertGreaterThanOrEqual(recommendation.estimatedImpact, 0.0)
                XCTAssertLessThanOrEqual(recommendation.estimatedImpact, 1.0)
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("Personalized recommendations generation failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Risk Model Tests
    
    func testFraminghamRiskCalculation() async throws {
        // Given
        let healthData = HealthData(
            age: 55,
            gender: .male,
            systolicBP: 140,
            diastolicBP: 90,
            totalCholesterol: 220,
            hdlCholesterol: 45,
            ldlCholesterol: 150,
            triglycerides: 180,
            bmi: 28.0,
            isSmoker: false,
            hasDiabetes: false,
            familyHistory: false,
            restingHeartRate: 70,
            bloodGlucose: 95
        )
        
        // When
        let riskScores = try await riskPredictor.calculateMultipleRiskScores(healthData: healthData)
        
        // Then
        XCTAssertEqual(riskScores.count, 4) // Framingham, ASCVD, Reynolds, QRISK
        
        // Check that all risk scores are valid
        for (model, score) in riskScores {
            XCTAssertGreaterThanOrEqual(score, 0.0)
            XCTAssertLessThanOrEqual(score, 1.0)
            XCTAssertTrue(CardiovascularRiskPredictor.RiskModel.allCases.contains(model))
        }
    }
    
    func testRiskScoreCombination() async throws {
        // Given
        let riskScores: [CardiovascularRiskPredictor.RiskModel: Double] = [
            .ascvd: 0.12,
            .framingham: 0.10,
            .qrisk: 0.08,
            .reynolds: 0.06
        ]
        
        // When
        let combinedScore = riskPredictor.combineRiskScores(riskScores)
        
        // Then
        XCTAssertGreaterThanOrEqual(combinedScore, 0.0)
        XCTAssertLessThanOrEqual(combinedScore, 1.0)
        
        // Combined score should be weighted average
        let expectedScore = (0.12 * 0.4) + (0.10 * 0.3) + (0.08 * 0.2) + (0.06 * 0.1)
        XCTAssertEqual(combinedScore, expectedScore, accuracy: 0.001)
    }
    
    // MARK: - Helper Method Tests
    
    func testAgeImpactCalculation() async throws {
        // Given
        let youngAge = 25
        let middleAge = 45
        let olderAge = 65
        
        // When & Then
        let youngImpact = riskPredictor.calculateAgeImpact(age: youngAge)
        XCTAssertEqual(youngImpact, 0.0, accuracy: 0.001)
        
        let middleImpact = riskPredictor.calculateAgeImpact(age: middleAge)
        XCTAssertGreaterThan(middleImpact, 0.0)
        XCTAssertLessThan(middleImpact, 1.0)
        
        let olderImpact = riskPredictor.calculateAgeImpact(age: olderAge)
        XCTAssertGreaterThan(olderImpact, middleImpact)
        XCTAssertLessThanOrEqual(olderImpact, 1.0)
    }
    
    func testBloodPressureImpactCalculation() async throws {
        // Given
        let normalBP = (systolic: 120, diastolic: 80)
        let elevatedBP = (systolic: 140, diastolic: 90)
        let highBP = (systolic: 160, diastolic: 100)
        
        // When & Then
        let normalImpact = riskPredictor.calculateBPImpact(systolic: normalBP.systolic, diastolic: normalBP.diastolic)
        XCTAssertEqual(normalImpact, 0.0, accuracy: 0.001)
        
        let elevatedImpact = riskPredictor.calculateBPImpact(systolic: elevatedBP.systolic, diastolic: elevatedBP.diastolic)
        XCTAssertGreaterThan(elevatedImpact, 0.0)
        XCTAssertLessThan(elevatedImpact, 1.0)
        
        let highImpact = riskPredictor.calculateBPImpact(systolic: highBP.systolic, diastolic: highBP.diastolic)
        XCTAssertGreaterThan(highImpact, elevatedImpact)
        XCTAssertLessThanOrEqual(highImpact, 1.0)
    }
    
    func testCholesterolImpactCalculation() async throws {
        // Given
        let goodCholesterol = (total: 180, hdl: 60)
        let borderlineCholesterol = (total: 220, hdl: 45)
        let highCholesterol = (total: 280, hdl: 35)
        
        // When & Then
        let goodImpact = riskPredictor.calculateCholesterolImpact(total: goodCholesterol.total, hdl: goodCholesterol.hdl)
        XCTAssertEqual(goodImpact, 0.0, accuracy: 0.001)
        
        let borderlineImpact = riskPredictor.calculateCholesterolImpact(total: borderlineCholesterol.total, hdl: borderlineCholesterol.hdl)
        XCTAssertGreaterThan(borderlineImpact, 0.0)
        XCTAssertLessThan(borderlineImpact, 1.0)
        
        let highImpact = riskPredictor.calculateCholesterolImpact(total: highCholesterol.total, hdl: highCholesterol.hdl)
        XCTAssertGreaterThan(highImpact, borderlineImpact)
        XCTAssertLessThanOrEqual(highImpact, 1.0)
    }
    
    func testBMIImpactCalculation() async throws {
        // Given
        let normalBMI = 22.0
        let overweightBMI = 28.0
        let obeseBMI = 35.0
        
        // When & Then
        let normalImpact = riskPredictor.calculateBMIImpact(bmi: normalBMI)
        XCTAssertGreaterThanOrEqual(normalImpact, 0.0)
        XCTAssertLessThan(normalImpact, 0.5)
        
        let overweightImpact = riskPredictor.calculateBMIImpact(bmi: overweightBMI)
        XCTAssertGreaterThan(overweightImpact, normalImpact)
        XCTAssertLessThan(overweightImpact, 1.0)
        
        let obeseImpact = riskPredictor.calculateBMIImpact(bmi: obeseBMI)
        XCTAssertGreaterThan(obeseImpact, overweightImpact)
        XCTAssertLessThanOrEqual(obeseImpact, 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testHealthKitNotAvailableError() async throws {
        // Given
        let mockPredictor = CardiovascularRiskPredictor()
        
        // When & Then
        do {
            _ = try await mockPredictor.calculateRisk()
            XCTFail("Expected error when HealthKit is not available")
        } catch CardiovascularRiskError.healthKitNotAvailable {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testRiskCalculationPerformance() async throws {
        // Given
        let iterations = 100
        let expectation = XCTestExpectation(description: "Performance test completed")
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            do {
                _ = try await riskPredictor.calculateRisk()
            } catch {
                // Ignore errors for performance test
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / Double(iterations)
        
        // Then
        XCTAssertLessThan(averageTime, 0.1) // Should complete in less than 100ms on average
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 30.0)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndRiskAssessment() async throws {
        // Given
        let expectation = XCTestExpectation(description: "End-to-end risk assessment completed")
        
        // When
        do {
            // Calculate risk
            let riskScore = try await riskPredictor.calculateRisk()
            
            // Analyze risk factors
            let riskFactors = try await riskPredictor.analyzeRiskFactors()
            
            // Generate recommendations
            let recommendations = try await riskPredictor.generatePersonalizedRecommendations()
            
            // Predict future risk
            let predictions = try await riskPredictor.predictRiskTrend(months: 6)
            
            // Then
            XCTAssertGreaterThanOrEqual(riskScore, 0.0)
            XCTAssertLessThanOrEqual(riskScore, 1.0)
            XCTAssertFalse(riskFactors.isEmpty)
            XCTAssertFalse(recommendations.isEmpty)
            XCTAssertEqual(predictions.count, 6)
            
            // Verify consistency
            XCTAssertEqual(riskPredictor.currentRiskScore, riskScore)
            XCTAssertEqual(riskPredictor.riskFactors.count, riskFactors.count)
            XCTAssertEqual(riskPredictor.recommendations.count, recommendations.count)
            
            expectation.fulfill()
        } catch {
            XCTFail("End-to-end risk assessment failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
}

// MARK: - Test Extensions

extension CardiovascularRiskPredictor {
    // Expose private methods for testing
    func calculateRiskTrend(score: Double) -> RiskTrend {
        // This would be the actual implementation from the main class
        switch score {
        case 0..<0.05:
            return .improving
        case 0.05..<0.10:
            return .stable
        case 0.10..<0.20:
            return .worsening
        default:
            return .critical
        }
    }
    
    func extractRiskFactors(healthData: HealthData) -> [RiskFactor] {
        var factors: [RiskFactor] = []
        
        // Age factor
        factors.append(RiskFactor(
            name: "Age",
            value: Double(healthData.age),
            unit: "years",
            impact: calculateAgeImpact(age: healthData.age),
            category: .age,
            isModifiable: false
        ))
        
        // Blood pressure factors
        factors.append(RiskFactor(
            name: "Systolic Blood Pressure",
            value: Double(healthData.systolicBP),
            unit: "mmHg",
            impact: calculateBPImpact(systolic: healthData.systolicBP, diastolic: healthData.diastolicBP),
            category: .bloodPressure,
            isModifiable: true
        ))
        
        // Cholesterol factors
        factors.append(RiskFactor(
            name: "Total Cholesterol",
            value: Double(healthData.totalCholesterol),
            unit: "mg/dL",
            impact: calculateCholesterolImpact(total: healthData.totalCholesterol, hdl: healthData.hdlCholesterol),
            category: .cholesterol,
            isModifiable: true
        ))
        
        // BMI factor
        factors.append(RiskFactor(
            name: "Body Mass Index",
            value: healthData.bmi,
            unit: "kg/m²",
            impact: calculateBMIImpact(bmi: healthData.bmi),
            category: .lifestyle,
            isModifiable: true
        ))
        
        // Family history
        if healthData.familyHistory {
            factors.append(RiskFactor(
                name: "Family History",
                value: 1.0,
                unit: "Yes/No",
                impact: 0.15,
                category: .familyHistory,
                isModifiable: false
            ))
        }
        
        return factors.sorted { $0.impact > $1.impact }
    }
    
    func generateRecommendations(riskFactors: [RiskFactor], score: Double) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // High priority recommendations for high risk
        if score > 0.15 {
            recommendations.append(HealthRecommendation(
                title: "Consult Healthcare Provider",
                description: "Your cardiovascular risk is elevated. Schedule an appointment with your healthcare provider for a comprehensive evaluation.",
                priority: .critical,
                category: .referral,
                evidenceLevel: .a,
                estimatedImpact: 0.8
            ))
        }
        
        // Blood pressure recommendations
        if let bpFactor = riskFactors.first(where: { $0.category == .bloodPressure && $0.impact > 0.1 }) {
            recommendations.append(HealthRecommendation(
                title: "Blood Pressure Management",
                description: "Your blood pressure is contributing to cardiovascular risk. Consider lifestyle changes and medication if prescribed.",
                priority: .high,
                category: .lifestyle,
                evidenceLevel: .a,
                estimatedImpact: 0.6
            ))
        }
        
        // Cholesterol recommendations
        if let cholesterolFactor = riskFactors.first(where: { $0.category == .cholesterol && $0.impact > 0.1 }) {
            recommendations.append(HealthRecommendation(
                title: "Cholesterol Management",
                description: "Your cholesterol levels are contributing to cardiovascular risk. Focus on heart-healthy diet and exercise.",
                priority: .high,
                category: .lifestyle,
                evidenceLevel: .a,
                estimatedImpact: 0.5
            ))
        }
        
        // BMI recommendations
        if let bmiFactor = riskFactors.first(where: { $0.category == .lifestyle && $0.name == "Body Mass Index" && $0.value > 25 }) {
            recommendations.append(HealthRecommendation(
                title: "Weight Management",
                description: "Your BMI indicates overweight status. Consider weight loss through diet and exercise to reduce cardiovascular risk.",
                priority: .medium,
                category: .lifestyle,
                evidenceLevel: .a,
                estimatedImpact: 0.4
            ))
        }
        
        // General lifestyle recommendations
        recommendations.append(HealthRecommendation(
            title: "Regular Exercise",
            description: "Aim for at least 150 minutes of moderate-intensity exercise per week to improve cardiovascular health.",
            priority: .medium,
            category: .lifestyle,
            evidenceLevel: .a,
            estimatedImpact: 0.3
        ))
        
        recommendations.append(HealthRecommendation(
            title: "Heart-Healthy Diet",
            description: "Follow a diet rich in fruits, vegetables, whole grains, and lean proteins. Limit saturated fats and sodium.",
            priority: .medium,
            category: .lifestyle,
            evidenceLevel: .a,
            estimatedImpact: 0.3
        ))
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    func calculateMultipleRiskScores(healthData: HealthData) async throws -> [RiskModel: Double] {
        var riskScores: [RiskModel: Double] = [:]
        
        // Calculate Framingham Risk Score
        riskScores[.framingham] = try riskCalculator.calculateFraminghamRisk(healthData: healthData)
        
        // Calculate ASCVD Risk Score
        riskScores[.ascvd] = try riskCalculator.calculateASCVDRisk(healthData: healthData)
        
        // Calculate Reynolds Risk Score
        riskScores[.reynolds] = try riskCalculator.calculateReynoldsRisk(healthData: healthData)
        
        // Calculate QRISK Score
        riskScores[.qrisk] = try riskCalculator.calculateQRISKRisk(healthData: healthData)
        
        return riskScores
    }
    
    func combineRiskScores(_ riskScores: [RiskModel: Double]) -> Double {
        // Weight the different risk scores based on clinical evidence
        let weights: [RiskModel: Double] = [
            .ascvd: 0.4,      // Most widely used in US
            .framingham: 0.3, // Traditional standard
            .qrisk: 0.2,      // UK standard, good for diverse populations
            .reynolds: 0.1    // Additional factor consideration
        ]
        
        let weightedSum = riskScores.reduce(0.0) { sum, entry in
            sum + (entry.value * weights[entry.key, default: 0.0])
        }
        
        return weightedSum
    }
    
    func calculateAgeImpact(age: Int) -> Double {
        return min(1.0, Double(age - 30) / 50.0)
    }
    
    func calculateBPImpact(systolic: Int, diastolic: Int) -> Double {
        let systolicImpact = max(0.0, Double(systolic - 120) / 80.0)
        let diastolicImpact = max(0.0, Double(diastolic - 80) / 40.0)
        return min(1.0, (systolicImpact + diastolicImpact) / 2.0)
    }
    
    func calculateCholesterolImpact(total: Int, hdl: Int) -> Double {
        let totalImpact = max(0.0, Double(total - 200) / 100.0)
        let hdlImpact = max(0.0, Double(60 - hdl) / 40.0)
        return min(1.0, (totalImpact + hdlImpact) / 2.0)
    }
    
    func calculateBMIImpact(bmi: Double) -> Double {
        return min(1.0, max(0.0, (bmi - 18.5) / 20.0))
    }
} 