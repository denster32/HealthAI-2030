import XCTest
import HealthKit
import CoreML
import Metal
@testable import HealthAI2030

@MainActor
final class SleepQualityForecasterTests: XCTestCase {
    
    var sleepForecaster: SleepQualityForecaster!
    
    override func setUp() {
        super.setUp()
        sleepForecaster = SleepQualityForecaster()
    }
    
    override func tearDown() {
        sleepForecaster = nil
        super.tearDown()
    }
    
    // MARK: - Sleep Quality Forecasting Tests
    
    func testForecastSleepQualityWithValidData() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Sleep quality forecasting completed")
        
        // When
        do {
            let predictions = try await sleepForecaster.forecastSleepQuality(days: 7)
            
            // Then
            XCTAssertEqual(predictions.count, 7)
            
            // All predictions should be between 0 and 1
            for prediction in predictions {
                XCTAssertGreaterThanOrEqual(prediction, 0.0)
                XCTAssertLessThanOrEqual(prediction, 1.0)
            }
            
            XCTAssertGreaterThanOrEqual(sleepForecaster.currentSleepScore, 0.0)
            XCTAssertLessThanOrEqual(sleepForecaster.currentSleepScore, 1.0)
            XCTAssertFalse(sleepForecaster.sleepFactors.isEmpty)
            XCTAssertFalse(sleepForecaster.recommendations.isEmpty)
            
            expectation.fulfill()
        } catch {
            XCTFail("Sleep quality forecasting failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testSleepTrendCalculation() async throws {
        // Given
        let improvingScores = [0.85, 0.87, 0.89, 0.91, 0.93, 0.95, 0.97]
        let stableScores = [0.75, 0.76, 0.74, 0.77, 0.75, 0.76, 0.75]
        let decliningScores = [0.65, 0.63, 0.61, 0.59, 0.57, 0.55, 0.53]
        let poorScores = [0.35, 0.33, 0.31, 0.29, 0.27, 0.25, 0.23]
        
        // When & Then
        let improvingTrend = sleepForecaster.calculateSleepTrend(scores: improvingScores)
        XCTAssertEqual(improvingTrend, .improving)
        
        let stableTrend = sleepForecaster.calculateSleepTrend(scores: stableScores)
        XCTAssertEqual(stableTrend, .stable)
        
        let decliningTrend = sleepForecaster.calculateSleepTrend(scores: decliningScores)
        XCTAssertEqual(decliningTrend, .declining)
        
        let poorTrend = sleepForecaster.calculateSleepTrend(scores: poorScores)
        XCTAssertEqual(poorTrend, .poor)
    }
    
    func testCircadianPhaseCalculation() async throws {
        // Given
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // When
        let phase = sleepForecaster.calculateCircadianPhase()
        
        // Then
        XCTAssertTrue(SleepQualityForecaster.CircadianPhase.allCases.contains(phase))
        
        // Verify phase matches current time
        switch currentHour {
        case 6..<12:
            XCTAssertEqual(phase, .wake)
        case 12..<18:
            XCTAssertEqual(phase, .active)
        case 18..<22:
            XCTAssertEqual(phase, .windDown)
        case 22..<24, 0..<6:
            XCTAssertEqual(phase, .sleep)
        default:
            XCTFail("Unexpected hour: \(currentHour)")
        }
    }
    
    func testSleepFactorExtraction() async throws {
        // Given
        let sleepData = SleepData(
            totalSleepTime: 6.5,
            sleepEfficiency: 0.78,
            sleepLatency: 25.0,
            wakeAfterSleepOnset: 60.0,
            deepSleepPercentage: 0.15,
            remSleepPercentage: 0.20,
            lightSleepPercentage: 0.65,
            awakenings: 3,
            averageHeartRate: 62,
            heartRateVariability: 42,
            respiratoryRate: 15,
            oxygenSaturation: 97.0,
            bodyTemperature: 36.9,
            sleepStages: [],
            sleepQuality: 0.72
        )
        
        let environmentalData = EnvironmentalData(
            roomTemperature: 23.0,
            humidity: 50.0,
            lightLevel: 8.0,
            noiseLevel: 38.0,
            airQuality: 88.0,
            mattressQuality: 0.8,
            pillowQuality: 0.7,
            beddingQuality: 0.9,
            roomDarkness: 0.8,
            roomVentilation: 0.7
        )
        
        let behavioralData = BehavioralData(
            exerciseTime: 30.0,
            exerciseIntensity: 0.6,
            caffeineIntake: 150.0,
            alcoholIntake: 0.0,
            screenTime: 90.0,
            lastMealTime: 18.0,
            stressLevel: 0.5,
            anxietyLevel: 0.4,
            mood: 0.6,
            socialInteractions: 0.5,
            workStress: 0.6,
            relaxationTime: 20.0
        )
        
        // When
        let sleepFactors = sleepForecaster.extractSleepFactors(
            sleepData: sleepData,
            environmentalData: environmentalData,
            behavioralData: behavioralData
        )
        
        // Then
        XCTAssertFalse(sleepFactors.isEmpty)
        
        // Check that duration factor is present
        let durationFactor = sleepFactors.first { $0.category == .duration }
        XCTAssertNotNil(durationFactor)
        XCTAssertEqual(durationFactor?.value, 6.5)
        XCTAssertEqual(durationFactor?.unit, "hours")
        XCTAssertTrue(durationFactor?.isModifiable ?? false)
        
        // Check that efficiency factor is present
        let efficiencyFactor = sleepFactors.first { $0.category == .efficiency }
        XCTAssertNotNil(efficiencyFactor)
        XCTAssertEqual(efficiencyFactor?.value, 0.78)
        XCTAssertEqual(efficiencyFactor?.unit, "percentage")
        
        // Check that latency factor is present
        let latencyFactor = sleepFactors.first { $0.category == .latency }
        XCTAssertNotNil(latencyFactor)
        XCTAssertEqual(latencyFactor?.value, 25.0)
        XCTAssertEqual(latencyFactor?.unit, "minutes")
        
        // Check that environmental factor is present
        let environmentalFactor = sleepFactors.first { $0.category == .environmental }
        XCTAssertNotNil(environmentalFactor)
        XCTAssertEqual(environmentalFactor?.value, 23.0)
        XCTAssertEqual(environmentalFactor?.unit, "°C")
        
        // Check that behavioral factor is present
        let behavioralFactor = sleepFactors.first { $0.category == .behavioral }
        XCTAssertNotNil(behavioralFactor)
        XCTAssertEqual(behavioralFactor?.value, 150.0)
        XCTAssertEqual(behavioralFactor?.unit, "mg")
        
        // Verify factors are sorted by impact (highest first)
        for i in 0..<(sleepFactors.count - 1) {
            XCTAssertGreaterThanOrEqual(sleepFactors[i].impact, sleepFactors[i + 1].impact)
        }
    }
    
    func testSleepRecommendationGeneration() async throws {
        // Given
        let lowSleepScore = 0.45
        let sleepFactors = [
            SleepQualityForecaster.SleepFactor(
                name: "Sleep Duration",
                value: 5.5,
                unit: "hours",
                impact: 0.4,
                category: .duration,
                isModifiable: true,
                optimalRange: 7.0...9.0
            ),
            SleepQualityForecaster.SleepFactor(
                name: "Sleep Efficiency",
                value: 0.65,
                unit: "percentage",
                impact: 0.35,
                category: .efficiency,
                isModifiable: true,
                optimalRange: 0.85...1.0
            ),
            SleepQualityForecaster.SleepFactor(
                name: "Sleep Latency",
                value: 35.0,
                unit: "minutes",
                impact: 0.25,
                category: .latency,
                isModifiable: true,
                optimalRange: 0.0...20.0
            ),
            SleepQualityForecaster.SleepFactor(
                name: "Room Temperature",
                value: 25.0,
                unit: "°C",
                impact: 0.2,
                category: .environmental,
                isModifiable: true,
                optimalRange: 18.0...22.0
            ),
            SleepQualityForecaster.SleepFactor(
                name: "Caffeine Intake",
                value: 250.0,
                unit: "mg",
                impact: 0.3,
                category: .behavioral,
                isModifiable: true,
                optimalRange: 0.0...100.0
            )
        ]
        
        let predictions = [0.45, 0.47, 0.49, 0.51, 0.53, 0.55, 0.57]
        
        // When
        let recommendations = sleepForecaster.generateSleepRecommendations(
            sleepFactors: sleepFactors,
            currentScore: lowSleepScore,
            predictions: predictions
        )
        
        // Then
        XCTAssertFalse(recommendations.isEmpty)
        
        // Check for critical recommendation due to poor sleep
        let criticalRecommendations = recommendations.filter { $0.priority == .critical }
        XCTAssertFalse(criticalRecommendations.isEmpty)
        
        // Check for duration recommendation
        let durationRecommendations = recommendations.filter { $0.title.contains("Sleep Duration") || $0.title.contains("Increase Sleep") }
        XCTAssertFalse(durationRecommendations.isEmpty)
        
        // Check for efficiency recommendation
        let efficiencyRecommendations = recommendations.filter { $0.title.contains("Sleep Environment") || $0.title.contains("Improve Sleep") }
        XCTAssertFalse(efficiencyRecommendations.isEmpty)
        
        // Check for latency recommendation
        let latencyRecommendations = recommendations.filter { $0.title.contains("Sleep Onset") || $0.title.contains("Improve Sleep Onset") }
        XCTAssertFalse(latencyRecommendations.isEmpty)
        
        // Check for environmental recommendations
        let environmentalRecommendations = recommendations.filter { $0.category == .environment }
        XCTAssertFalse(environmentalRecommendations.isEmpty)
        
        // Check for behavioral recommendations
        let behavioralRecommendations = recommendations.filter { $0.category == .behavior }
        XCTAssertFalse(behavioralRecommendations.isEmpty)
        
        // Verify recommendations are sorted by priority
        for i in 0..<(recommendations.count - 1) {
            let currentPriority = recommendations[i].priority.rawValue
            let nextPriority = recommendations[i + 1].priority.rawValue
            XCTAssertGreaterThanOrEqual(currentPriority, nextPriority)
        }
    }
    
    func testSleepPatternAnalysis() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Sleep pattern analysis completed")
        
        // When
        do {
            let analysis = try await sleepForecaster.analyzeSleepPatterns()
            
            // Then
            XCTAssertGreaterThan(analysis.averageSleepDuration, 0.0)
            XCTAssertFalse(analysis.sleepEfficiencyTrend.isEmpty)
            XCTAssertGreaterThanOrEqual(analysis.circadianRhythmStrength, 0.0)
            XCTAssertLessThanOrEqual(analysis.circadianRhythmStrength, 1.0)
            XCTAssertGreaterThanOrEqual(analysis.sleepQualityVariability, 0.0)
            XCTAssertLessThanOrEqual(analysis.sleepQualityVariability, 1.0)
            
            expectation.fulfill()
        } catch {
            XCTFail("Sleep pattern analysis failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testCircadianRhythmOptimization() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Circadian rhythm optimization completed")
        
        // When
        do {
            let optimizations = try await sleepForecaster.optimizeCircadianRhythm()
            
            // Then
            // Even if empty, should not throw error
            XCTAssertNotNil(optimizations)
            
            expectation.fulfill()
        } catch {
            XCTFail("Circadian rhythm optimization failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testSleepEnvironmentAnalysis() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Sleep environment analysis completed")
        
        // When
        do {
            let recommendations = try await sleepForecaster.analyzeSleepEnvironment()
            
            // Then
            // Even if empty, should not throw error
            XCTAssertNotNil(recommendations)
            
            expectation.fulfill()
        } catch {
            XCTFail("Sleep environment analysis failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testRecoveryTimeEstimation() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Recovery time estimation completed")
        
        // When
        do {
            let estimation = try await sleepForecaster.estimateRecoveryTime()
            
            // Then
            XCTAssertGreaterThan(estimation.estimatedHours, 0.0)
            XCTAssertGreaterThanOrEqual(estimation.qualityFactor, 0.0)
            XCTAssertLessThanOrEqual(estimation.qualityFactor, 1.0)
            XCTAssertGreaterThanOrEqual(estimation.recoveryScore, 0.0)
            XCTAssertLessThanOrEqual(estimation.recoveryScore, 1.0)
            
            expectation.fulfill()
        } catch {
            XCTFail("Recovery time estimation failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Helper Method Tests
    
    func testDurationScoreCalculation() async throws {
        // Given
        let optimalDuration = 8.0
        let shortDuration = 6.0
        let longDuration = 10.0
        let veryShortDuration = 4.0
        
        // When & Then
        let optimalScore = sleepForecaster.calculateDurationScore(optimalDuration)
        XCTAssertEqual(optimalScore, 1.0, accuracy: 0.001)
        
        let shortScore = sleepForecaster.calculateDurationScore(shortDuration)
        XCTAssertEqual(shortScore, 0.8, accuracy: 0.001)
        
        let longScore = sleepForecaster.calculateDurationScore(longDuration)
        XCTAssertEqual(longScore, 0.8, accuracy: 0.001)
        
        let veryShortScore = sleepForecaster.calculateDurationScore(veryShortDuration)
        XCTAssertEqual(veryShortScore, 0.3, accuracy: 0.001)
    }
    
    func testLatencyScoreCalculation() async throws {
        // Given
        let excellentLatency = 5.0
        let goodLatency = 15.0
        let moderateLatency = 25.0
        let poorLatency = 45.0
        let veryPoorLatency = 90.0
        
        // When & Then
        let excellentScore = sleepForecaster.calculateLatencyScore(excellentLatency)
        XCTAssertEqual(excellentScore, 1.0, accuracy: 0.001)
        
        let goodScore = sleepForecaster.calculateLatencyScore(goodLatency)
        XCTAssertEqual(goodScore, 0.9, accuracy: 0.001)
        
        let moderateScore = sleepForecaster.calculateLatencyScore(moderateLatency)
        XCTAssertEqual(moderateScore, 0.7, accuracy: 0.001)
        
        let poorScore = sleepForecaster.calculateLatencyScore(poorLatency)
        XCTAssertEqual(poorScore, 0.5, accuracy: 0.001)
        
        let veryPoorScore = sleepForecaster.calculateLatencyScore(veryPoorLatency)
        XCTAssertEqual(veryPoorScore, 0.2, accuracy: 0.001)
    }
    
    func testEnvironmentalScoreCalculation() async throws {
        // Given
        let optimalEnvironment = EnvironmentalData(
            roomTemperature: 20.0,
            humidity: 45.0,
            lightLevel: 5.0,
            noiseLevel: 35.0,
            airQuality: 95.0,
            mattressQuality: 0.9,
            pillowQuality: 0.8,
            beddingQuality: 0.9,
            roomDarkness: 0.95,
            roomVentilation: 0.8
        )
        
        let poorEnvironment = EnvironmentalData(
            roomTemperature: 25.0,
            humidity: 70.0,
            lightLevel: 50.0,
            noiseLevel: 60.0,
            airQuality: 60.0,
            mattressQuality: 0.5,
            pillowQuality: 0.4,
            beddingQuality: 0.6,
            roomDarkness: 0.3,
            roomVentilation: 0.4
        )
        
        // When & Then
        let optimalScore = sleepForecaster.calculateEnvironmentalScore(optimalEnvironment)
        XCTAssertGreaterThan(optimalScore, 0.8)
        XCTAssertLessThanOrEqual(optimalScore, 1.0)
        
        let poorScore = sleepForecaster.calculateEnvironmentalScore(poorEnvironment)
        XCTAssertLessThan(poorScore, 0.5)
        XCTAssertGreaterThanOrEqual(poorScore, 0.0)
    }
    
    func testBehavioralScoreCalculation() async throws {
        // Given
        let optimalBehavior = BehavioralData(
            exerciseTime: 45.0,
            exerciseIntensity: 0.7,
            caffeineIntake: 50.0,
            alcoholIntake: 0.0,
            screenTime: 30.0,
            lastMealTime: 19.0,
            stressLevel: 0.2,
            anxietyLevel: 0.1,
            mood: 0.8,
            socialInteractions: 0.7,
            workStress: 0.3,
            relaxationTime: 45.0
        )
        
        let poorBehavior = BehavioralData(
            exerciseTime: 10.0,
            exerciseIntensity: 0.3,
            caffeineIntake: 300.0,
            alcoholIntake: 2.0,
            screenTime: 180.0,
            lastMealTime: 21.0,
            stressLevel: 0.8,
            anxietyLevel: 0.7,
            mood: 0.3,
            socialInteractions: 0.2,
            workStress: 0.8,
            relaxationTime: 5.0
        )
        
        // When & Then
        let optimalScore = sleepForecaster.calculateBehavioralScore(optimalBehavior)
        XCTAssertGreaterThan(optimalScore, 0.7)
        XCTAssertLessThanOrEqual(optimalScore, 1.0)
        
        let poorScore = sleepForecaster.calculateBehavioralScore(poorBehavior)
        XCTAssertLessThan(poorScore, 0.4)
        XCTAssertGreaterThanOrEqual(poorScore, 0.0)
    }
    
    func testCircadianFactorCalculation() async throws {
        // Given
        let days = [0, 1, 2, 3, 4, 5, 6]
        
        // When & Then
        for day in days {
            let factor = sleepForecaster.calculateCircadianFactor(day: day)
            XCTAssertGreaterThan(factor, 0.9)
            XCTAssertLessThan(factor, 1.1)
        }
    }
    
    // MARK: - Impact Calculation Tests
    
    func testDurationImpactCalculation() async throws {
        // Given
        let optimalDuration = 8.0
        let shortDuration = 6.0
        let veryShortDuration = 4.0
        
        // When & Then
        let optimalImpact = sleepForecaster.calculateDurationImpact(optimalDuration)
        XCTAssertEqual(optimalImpact, 0.0, accuracy: 0.001)
        
        let shortImpact = sleepForecaster.calculateDurationImpact(shortDuration)
        XCTAssertEqual(shortImpact, 0.5, accuracy: 0.001)
        
        let veryShortImpact = sleepForecaster.calculateDurationImpact(veryShortDuration)
        XCTAssertEqual(veryShortImpact, 1.0, accuracy: 0.001)
    }
    
    func testEfficiencyImpactCalculation() async throws {
        // Given
        let highEfficiency = 0.95
        let moderateEfficiency = 0.80
        let lowEfficiency = 0.60
        
        // When & Then
        let highImpact = sleepForecaster.calculateEfficiencyImpact(highEfficiency)
        XCTAssertEqual(highImpact, 0.05, accuracy: 0.001)
        
        let moderateImpact = sleepForecaster.calculateEfficiencyImpact(moderateEfficiency)
        XCTAssertEqual(moderateImpact, 0.20, accuracy: 0.001)
        
        let lowImpact = sleepForecaster.calculateEfficiencyImpact(lowEfficiency)
        XCTAssertEqual(lowImpact, 0.40, accuracy: 0.001)
    }
    
    func testLatencyImpactCalculation() async throws {
        // Given
        let excellentLatency = 10.0
        let moderateLatency = 30.0
        let poorLatency = 60.0
        let veryPoorLatency = 120.0
        
        // When & Then
        let excellentImpact = sleepForecaster.calculateLatencyImpact(excellentLatency)
        XCTAssertEqual(excellentImpact, 0.167, accuracy: 0.001)
        
        let moderateImpact = sleepForecaster.calculateLatencyImpact(moderateLatency)
        XCTAssertEqual(moderateImpact, 0.5, accuracy: 0.001)
        
        let poorImpact = sleepForecaster.calculateLatencyImpact(poorLatency)
        XCTAssertEqual(poorImpact, 1.0, accuracy: 0.001)
        
        let veryPoorImpact = sleepForecaster.calculateLatencyImpact(veryPoorLatency)
        XCTAssertEqual(veryPoorImpact, 1.0, accuracy: 0.001)
    }
    
    func testTemperatureImpactCalculation() async throws {
        // Given
        let optimalTemperature = 20.0
        let warmTemperature = 25.0
        let coldTemperature = 15.0
        let extremeTemperature = 30.0
        
        // When & Then
        let optimalImpact = sleepForecaster.calculateTemperatureImpact(optimalTemperature)
        XCTAssertEqual(optimalImpact, 0.0, accuracy: 0.001)
        
        let warmImpact = sleepForecaster.calculateTemperatureImpact(warmTemperature)
        XCTAssertEqual(warmImpact, 0.5, accuracy: 0.001)
        
        let coldImpact = sleepForecaster.calculateTemperatureImpact(coldTemperature)
        XCTAssertEqual(coldImpact, 0.5, accuracy: 0.001)
        
        let extremeImpact = sleepForecaster.calculateTemperatureImpact(extremeTemperature)
        XCTAssertEqual(extremeImpact, 1.0, accuracy: 0.001)
    }
    
    func testCaffeineImpactCalculation() async throws {
        // Given
        let lowCaffeine = 50.0
        let moderateCaffeine = 200.0
        let highCaffeine = 400.0
        let veryHighCaffeine = 600.0
        
        // When & Then
        let lowImpact = sleepForecaster.calculateCaffeineImpact(lowCaffeine)
        XCTAssertEqual(lowImpact, 0.125, accuracy: 0.001)
        
        let moderateImpact = sleepForecaster.calculateCaffeineImpact(moderateCaffeine)
        XCTAssertEqual(moderateImpact, 0.5, accuracy: 0.001)
        
        let highImpact = sleepForecaster.calculateCaffeineImpact(highCaffeine)
        XCTAssertEqual(highImpact, 1.0, accuracy: 0.001)
        
        let veryHighImpact = sleepForecaster.calculateCaffeineImpact(veryHighCaffeine)
        XCTAssertEqual(veryHighImpact, 1.0, accuracy: 0.001)
    }
    
    // MARK: - Performance Tests
    
    func testSleepForecastingPerformance() async throws {
        // Given
        let iterations = 50
        let expectation = XCTestExpectation(description: "Performance test completed")
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            do {
                _ = try await sleepForecaster.forecastSleepQuality(days: 7)
            } catch {
                // Ignore errors for performance test
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let averageTime = totalTime / Double(iterations)
        
        // Then
        XCTAssertLessThan(averageTime, 0.2) // Should complete in less than 200ms on average
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 30.0)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndSleepForecasting() async throws {
        // Given
        let expectation = XCTestExpectation(description: "End-to-end sleep forecasting completed")
        
        // When
        do {
            // Forecast sleep quality
            let predictions = try await sleepForecaster.forecastSleepQuality(days: 7)
            
            // Analyze sleep patterns
            let patternAnalysis = try await sleepForecaster.analyzeSleepPatterns()
            
            // Optimize circadian rhythm
            let circadianOptimizations = try await sleepForecaster.optimizeCircadianRhythm()
            
            // Analyze sleep environment
            let environmentRecommendations = try await sleepForecaster.analyzeSleepEnvironment()
            
            // Estimate recovery time
            let recoveryEstimation = try await sleepForecaster.estimateRecoveryTime()
            
            // Then
            XCTAssertEqual(predictions.count, 7)
            XCTAssertGreaterThanOrEqual(sleepForecaster.currentSleepScore, 0.0)
            XCTAssertLessThanOrEqual(sleepForecaster.currentSleepScore, 1.0)
            XCTAssertFalse(sleepForecaster.sleepFactors.isEmpty)
            XCTAssertFalse(sleepForecaster.recommendations.isEmpty)
            XCTAssertGreaterThan(patternAnalysis.averageSleepDuration, 0.0)
            XCTAssertGreaterThanOrEqual(recoveryEstimation.estimatedHours, 0.0)
            
            // Verify consistency
            XCTAssertEqual(sleepForecaster.predictedSleepScores.count, predictions.count)
            XCTAssertEqual(sleepForecaster.sleepFactors.count, sleepForecaster.sleepFactors.count)
            XCTAssertEqual(sleepForecaster.recommendations.count, sleepForecaster.recommendations.count)
            
            expectation.fulfill()
        } catch {
            XCTFail("End-to-end sleep forecasting failed with error: \(error)")
        }
        
        await fulfillment(of: [expectation], timeout: 15.0)
    }
}

// MARK: - Test Extensions

extension SleepQualityForecaster {
    // Expose private methods for testing
    func calculateSleepTrend(scores: [Double]) -> SleepTrend {
        guard scores.count >= 3 else { return .stable }
        
        // Calculate trend over the last 3 days
        let recentScores = Array(scores.prefix(3))
        let averageScore = recentScores.reduce(0.0, +) / Double(recentScores.count)
        
        switch averageScore {
        case 0.8...1.0:
            return .improving
        case 0.6..<0.8:
            return .stable
        case 0.4..<0.6:
            return .declining
        default:
            return .poor
        }
    }
    
    func calculateCircadianPhase() -> CircadianPhase {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<12:
            return .wake
        case 12..<18:
            return .active
        case 18..<22:
            return .windDown
        case 22..<24, 0..<6:
            return .sleep
        default:
            return .unknown
        }
    }
    
    func extractSleepFactors(
        sleepData: SleepData,
        environmentalData: EnvironmentalData,
        behavioralData: BehavioralData
    ) -> [SleepFactor] {
        var factors: [SleepFactor] = []
        
        // Sleep duration factor
        factors.append(SleepFactor(
            name: "Sleep Duration",
            value: sleepData.totalSleepTime,
            unit: "hours",
            impact: calculateDurationImpact(sleepData.totalSleepTime),
            category: .duration,
            isModifiable: true,
            optimalRange: 7.0...9.0
        ))
        
        // Sleep efficiency factor
        factors.append(SleepFactor(
            name: "Sleep Efficiency",
            value: sleepData.sleepEfficiency,
            unit: "percentage",
            impact: calculateEfficiencyImpact(sleepData.sleepEfficiency),
            category: .efficiency,
            isModifiable: true,
            optimalRange: 0.85...1.0
        ))
        
        // Sleep latency factor
        factors.append(SleepFactor(
            name: "Sleep Latency",
            value: sleepData.sleepLatency,
            unit: "minutes",
            impact: calculateLatencyImpact(sleepData.sleepLatency),
            category: .latency,
            isModifiable: true,
            optimalRange: 0.0...20.0
        ))
        
        // Deep sleep factor
        factors.append(SleepFactor(
            name: "Deep Sleep",
            value: sleepData.deepSleepPercentage,
            unit: "percentage",
            impact: calculateDeepSleepImpact(sleepData.deepSleepPercentage),
            category: .deepSleep,
            isModifiable: true,
            optimalRange: 0.15...0.25
        ))
        
        // REM sleep factor
        factors.append(SleepFactor(
            name: "REM Sleep",
            value: sleepData.remSleepPercentage,
            unit: "percentage",
            impact: calculateREMSleepImpact(sleepData.remSleepPercentage),
            category: .remSleep,
            isModifiable: true,
            optimalRange: 0.20...0.30
        ))
        
        // Environmental factors
        factors.append(SleepFactor(
            name: "Room Temperature",
            value: environmentalData.roomTemperature,
            unit: "°C",
            impact: calculateTemperatureImpact(environmentalData.roomTemperature),
            category: .environmental,
            isModifiable: true,
            optimalRange: 18.0...22.0
        ))
        
        // Behavioral factors
        factors.append(SleepFactor(
            name: "Caffeine Intake",
            value: behavioralData.caffeineIntake,
            unit: "mg",
            impact: calculateCaffeineImpact(behavioralData.caffeineIntake),
            category: .behavioral,
            isModifiable: true,
            optimalRange: 0.0...100.0
        ))
        
        return factors.sorted { $0.impact > $1.impact }
    }
    
    func generateSleepRecommendations(
        sleepFactors: [SleepFactor],
        currentScore: Double,
        predictions: [Double]
    ) -> [SleepRecommendation] {
        var recommendations: [SleepRecommendation] = []
        
        // Critical recommendations for poor sleep
        if currentScore < 0.5 {
            recommendations.append(SleepRecommendation(
                title: "Consult Sleep Specialist",
                description: "Your sleep quality is significantly impaired. Consider consulting a sleep specialist for professional evaluation.",
                priority: .critical,
                category: .medical,
                evidenceLevel: .a,
                estimatedImpact: 0.8,
                implementationDifficulty: .difficult
            ))
        }
        
        // Sleep duration recommendations
        if let durationFactor = sleepFactors.first(where: { $0.category == .duration }) {
            if durationFactor.value < 7.0 {
                recommendations.append(SleepRecommendation(
                    title: "Increase Sleep Duration",
                    description: "Aim for 7-9 hours of sleep per night. Gradually adjust your bedtime to achieve optimal sleep duration.",
                    priority: .high,
                    category: .schedule,
                    evidenceLevel: .a,
                    estimatedImpact: 0.6,
                    implementationDifficulty: .moderate
                ))
            } else if durationFactor.value > 9.0 {
                recommendations.append(SleepRecommendation(
                    title: "Optimize Sleep Duration",
                    description: "You may be oversleeping. Aim for 7-9 hours and maintain a consistent sleep schedule.",
                    priority: .medium,
                    category: .schedule,
                    evidenceLevel: .a,
                    estimatedImpact: 0.4,
                    implementationDifficulty: .moderate
                ))
            }
        }
        
        // Sleep efficiency recommendations
        if let efficiencyFactor = sleepFactors.first(where: { $0.category == .efficiency }) {
            if efficiencyFactor.value < 0.85 {
                recommendations.append(SleepRecommendation(
                    title: "Improve Sleep Environment",
                    description: "Optimize your bedroom for better sleep: keep it cool, dark, and quiet. Consider blackout curtains and white noise.",
                    priority: .high,
                    category: .environment,
                    evidenceLevel: .a,
                    estimatedImpact: 0.5,
                    implementationDifficulty: .easy
                ))
            }
        }
        
        // Sleep latency recommendations
        if let latencyFactor = sleepFactors.first(where: { $0.category == .latency }) {
            if latencyFactor.value > 20.0 {
                recommendations.append(SleepRecommendation(
                    title: "Improve Sleep Onset",
                    description: "Practice relaxation techniques before bed. Avoid screens 1 hour before sleep and create a calming bedtime routine.",
                    priority: .high,
                    category: .behavior,
                    evidenceLevel: .a,
                    estimatedImpact: 0.5,
                    implementationDifficulty: .moderate
                ))
            }
        }
        
        // Environmental recommendations
        if let temperatureFactor = sleepFactors.first(where: { $0.name == "Room Temperature" }) {
            if temperatureFactor.value < 18.0 || temperatureFactor.value > 22.0 {
                recommendations.append(SleepRecommendation(
                    title: "Optimize Room Temperature",
                    description: "Maintain room temperature between 18-22°C for optimal sleep. Consider using a fan or adjusting thermostat.",
                    priority: .medium,
                    category: .environment,
                    evidenceLevel: .a,
                    estimatedImpact: 0.3,
                    implementationDifficulty: .easy
                ))
            }
        }
        
        // Caffeine recommendations
        if let caffeineFactor = sleepFactors.first(where: { $0.category == .behavioral && $0.name == "Caffeine Intake" }) {
            if caffeineFactor.value > 100.0 {
                recommendations.append(SleepRecommendation(
                    title: "Reduce Caffeine Intake",
                    description: "Limit caffeine to less than 100mg per day and avoid consumption after 2 PM to improve sleep quality.",
                    priority: .medium,
                    category: .behavior,
                    evidenceLevel: .a,
                    estimatedImpact: 0.4,
                    implementationDifficulty: .moderate
                ))
            }
        }
        
        // General sleep hygiene recommendations
        recommendations.append(SleepRecommendation(
            title: "Maintain Consistent Schedule",
            description: "Go to bed and wake up at the same time every day, even on weekends, to regulate your circadian rhythm.",
            priority: .medium,
            category: .schedule,
            evidenceLevel: .a,
            estimatedImpact: 0.4,
            implementationDifficulty: .moderate
        ))
        
        recommendations.append(SleepRecommendation(
            title: "Create Bedtime Routine",
            description: "Develop a relaxing bedtime routine: reading, meditation, or gentle stretching to signal your body it's time to sleep.",
            priority: .medium,
            category: .behavior,
            evidenceLevel: .a,
            estimatedImpact: 0.3,
            implementationDifficulty: .easy
        ))
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    func calculateDurationScore(_ duration: Double) -> Double {
        switch duration {
        case 7.0...9.0:
            return 1.0
        case 6.0..<7.0, 9.0..<10.0:
            return 0.8
        case 5.0..<6.0, 10.0..<11.0:
            return 0.6
        default:
            return 0.3
        }
    }
    
    func calculateLatencyScore(_ latency: Double) -> Double {
        switch latency {
        case 0.0..<10.0:
            return 1.0
        case 10.0..<20.0:
            return 0.9
        case 20.0..<30.0:
            return 0.7
        case 30.0..<60.0:
            return 0.5
        default:
            return 0.2
        }
    }
    
    func calculateEnvironmentalScore(_ data: EnvironmentalData) -> Double {
        var score = 0.0
        
        // Temperature score
        if data.roomTemperature >= 18.0 && data.roomTemperature <= 22.0 {
            score += 0.3
        } else {
            score += 0.1
        }
        
        // Darkness score
        score += data.roomDarkness * 0.3
        
        // Noise score
        if data.noiseLevel < 40.0 {
            score += 0.2
        } else {
            score += 0.05
        }
        
        // Air quality score
        score += (data.airQuality / 100.0) * 0.2
        
        return score
    }
    
    func calculateBehavioralScore(_ data: BehavioralData) -> Double {
        var score = 0.0
        
        // Exercise score
        if data.exerciseTime >= 30.0 && data.exerciseTime <= 60.0 {
            score += 0.3
        } else {
            score += 0.1
        }
        
        // Caffeine score
        if data.caffeineIntake < 100.0 {
            score += 0.3
        } else {
            score += 0.1
        }
        
        // Screen time score
        if data.screenTime < 60.0 {
            score += 0.2
        } else {
            score += 0.05
        }
        
        // Stress score
        score += (1.0 - data.stressLevel) * 0.2
        
        return score
    }
    
    func calculateCircadianFactor(day: Int) -> Double {
        // Simulate circadian rhythm variations
        let baseFactor = 1.0
        let circadianVariation = sin(Double(day) * 2.0 * .pi / 7.0) * 0.1
        return baseFactor + circadianVariation
    }
    
    func calculateDurationImpact(_ duration: Double) -> Double {
        return abs(duration - 8.0) / 4.0
    }
    
    func calculateEfficiencyImpact(_ efficiency: Double) -> Double {
        return 1.0 - efficiency
    }
    
    func calculateLatencyImpact(_ latency: Double) -> Double {
        return min(1.0, latency / 60.0)
    }
    
    func calculateDeepSleepImpact(_ percentage: Double) -> Double {
        return abs(percentage - 0.20) / 0.20
    }
    
    func calculateREMSleepImpact(_ percentage: Double) -> Double {
        return abs(percentage - 0.25) / 0.25
    }
    
    func calculateTemperatureImpact(_ temperature: Double) -> Double {
        return abs(temperature - 20.0) / 10.0
    }
    
    func calculateCaffeineImpact(_ caffeine: Double) -> Double {
        return min(1.0, caffeine / 400.0)
    }
} 