import XCTest
@testable import QuantumHealth

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
final class BioDigitalTwinEngineTests: XCTestCase {
    
    var engine: BioDigitalTwinEngine!
    var testHealthData: HealthProfile!
    
    override func setUp() {
        super.setUp()
        engine = BioDigitalTwinEngine()
        testHealthData = createTestHealthData()
    }
    
    override func tearDown() {
        engine = nil
        testHealthData = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testEngineInitialization() {
        XCTAssertNotNil(engine)
        
        // Test initial performance metrics
        let metrics = engine.getPerformanceMetrics()
        XCTAssertEqual(metrics.simulationCount, 0)
        XCTAssertEqual(metrics.averageSimulationTime, 0.0)
        XCTAssertEqual(metrics.peakMemoryUsage, 0)
    }
    
    func testDigitalTwinCreation() {
        let digitalTwin = engine.createDigitalTwin(from: testHealthData)
        
        XCTAssertNotNil(digitalTwin)
        XCTAssertEqual(digitalTwin.patientId, testHealthData.patientId)
        XCTAssertNotNil(digitalTwin.cardiovascularModel)
        XCTAssertNotNil(digitalTwin.neurologicalModel)
        XCTAssertNotNil(digitalTwin.endocrineModel)
        XCTAssertNotNil(digitalTwin.immuneModel)
        XCTAssertNotNil(digitalTwin.metabolicModel)
    }
    
    func testDigitalTwinCaching() {
        // Create first twin
        let twin1 = engine.createDigitalTwin(from: testHealthData)
        
        // Create second twin with same data (should use cache)
        let twin2 = engine.createDigitalTwin(from: testHealthData)
        
        XCTAssertEqual(twin1.id, twin2.id)
        
        // Check cache hit metrics
        let metrics = engine.getPerformanceMetrics()
        XCTAssertGreaterThan(metrics.cacheHitRate, 0.0)
    }
    
    // MARK: - Performance Optimization Tests
    
    func testSimulationPerformance() {
        let digitalTwin = engine.createDigitalTwin(from: testHealthData)
        let scenario = HealthScenario(
            name: "Test Exercise",
            timeStepSize: 1.0,
            affectedSystems: ["cardiovascular"]
        )
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = engine.simulateHealthScenario(
            digitalTwin: digitalTwin,
            scenario: scenario,
            duration: 60.0
        )
        let endTime = CFAbsoluteTimeGetCurrent()
        
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result.states.count, 0)
        
        let executionTime = endTime - startTime
        XCTAssertLessThan(executionTime, 5.0) // Should complete within 5 seconds
        
        // Check performance metrics
        let metrics = engine.getPerformanceMetrics()
        XCTAssertGreaterThan(metrics.simulationCount, 0)
        XCTAssertGreaterThan(metrics.averageSimulationTime, 0.0)
    }
    
    func testConcurrentSimulation() {
        let digitalTwin = engine.createDigitalTwin(from: testHealthData)
        let scenario = HealthScenario(
            name: "Complex Scenario",
            timeStepSize: 0.5,
            affectedSystems: ["cardiovascular", "neurological", "endocrine"]
        )
        
        // Test large simulation that should trigger concurrent processing
        let result = engine.simulateHealthScenario(
            digitalTwin: digitalTwin,
            scenario: scenario,
            duration: 3600.0 // 1 hour simulation
        )
        
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result.states.count, 1000)
    }
    
    func testMemoryOptimization() {
        // Create multiple digital twins to test memory management
        var twins: [BioDigitalTwin] = []
        
        for i in 0..<10 {
            let healthData = createTestHealthData(patientId: "patient_\(i)")
            let twin = engine.createDigitalTwin(from: healthData)
            twins.append(twin)
        }
        
        // Trigger memory optimization
        engine.optimizeMemoryUsage()
        
        // Check that memory usage is reasonable
        let metrics = engine.getPerformanceMetrics()
        XCTAssertLessThan(metrics.peakMemoryUsage, 500 * 1024 * 1024) // Less than 500MB
    }
    
    func testCacheOptimization() {
        // Test cache optimization by creating many twins
        for i in 0..<50 {
            let healthData = createTestHealthData(patientId: "cache_test_\(i)")
            _ = engine.createDigitalTwin(from: healthData)
        }
        
        // Trigger cache optimization
        engine.optimizeMemoryUsage()
        
        // Verify cache is still functional
        let healthData = createTestHealthData(patientId: "cache_test_0")
        let twin = engine.createDigitalTwin(from: healthData)
        XCTAssertNotNil(twin)
    }
    
    // MARK: - Advanced Optimization Tests
    
    func testPredictiveCaching() {
        // Test predictive caching by performing common operations
        let digitalTwin = engine.createDigitalTwin(from: testHealthData)
        
        // Perform common sequence of operations
        let scenario = HealthScenario(
            name: "Common Scenario",
            timeStepSize: 1.0,
            affectedSystems: ["cardiovascular"]
        )
        
        _ = engine.simulateHealthScenario(
            digitalTwin: digitalTwin,
            scenario: scenario,
            duration: 300.0
        )
        
        // Trigger background optimization
        engine.performAdvancedOptimization()
        
        // Wait a bit for background optimization to complete
        let expectation = XCTestExpectation(description: "Background optimization")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Check that predictive caching was performed
        let metrics = engine.getPerformanceMetrics()
        XCTAssertGreaterThan(metrics.cacheHitRate, 0.0)
    }
    
    func testAdaptiveTimeStepOptimization() {
        let digitalTwin = engine.createDigitalTwin(from: testHealthData)
        
        // Test simple scenario (should use larger time steps)
        let simpleScenario = HealthScenario(
            name: "Simple",
            timeStepSize: 1.0,
            affectedSystems: []
        )
        
        let simpleResult = engine.simulateHealthScenario(
            digitalTwin: digitalTwin,
            scenario: simpleScenario,
            duration: 60.0
        )
        
        // Test complex scenario (should use smaller time steps)
        let complexScenario = HealthScenario(
            name: "Complex",
            timeStepSize: 1.0,
            affectedSystems: ["cardiovascular", "neurological", "endocrine", "immune", "metabolic"]
        )
        
        let complexResult = engine.simulateHealthScenario(
            digitalTwin: digitalTwin,
            scenario: complexScenario,
            duration: 60.0
        )
        
        // Both should complete successfully with different optimization strategies
        XCTAssertNotNil(simpleResult)
        XCTAssertNotNil(complexResult)
    }
    
    func testPerformanceMonitoring() {
        // Perform operations to generate performance data
        let digitalTwin = engine.createDigitalTwin(from: testHealthData)
        let scenario = HealthScenario(
            name: "Performance Test",
            timeStepSize: 1.0,
            affectedSystems: ["cardiovascular"]
        )
        
        _ = engine.simulateHealthScenario(
            digitalTwin: digitalTwin,
            scenario: scenario,
            duration: 120.0
        )
        
        // Get performance metrics
        let metrics = engine.getPerformanceMetrics()
        
        XCTAssertGreaterThan(metrics.simulationCount, 0)
        XCTAssertGreaterThan(metrics.averageSimulationTime, 0.0)
        XCTAssertGreaterThanOrEqual(metrics.peakMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(metrics.cacheHitRate, 0.0)
        XCTAssertLessThanOrEqual(metrics.cacheHitRate, 1.0)
        
        // Check operation metrics
        let operationMetrics = metrics.operationMetrics
        XCTAssertGreaterThan(operationMetrics.count, 0)
    }
    
    func testCacheClearAndReset() {
        // Create some cached data
        let twin1 = engine.createDigitalTwin(from: testHealthData)
        XCTAssertNotNil(twin1)
        
        // Clear cache
        engine.clearCache()
        
        // Create twin again (should not use cache)
        let twin2 = engine.createDigitalTwin(from: testHealthData)
        XCTAssertNotNil(twin2)
        
        // Twins should have different IDs after cache clear
        XCTAssertNotEqual(twin1.id, twin2.id)
    }
    
    // MARK: - SwiftData Integration Tests
    
    func testPersistentCacheIntegration() {
        // Setup persistent cache
        engine.setupPersistentCache()
        
        // Test saving to persistent cache
        let testObject = "test_data" as AnyObject
        engine.saveToPersistentCache(key: "test_key", object: testObject)
        
        // Test loading from persistent cache
        let loadedObject = engine.loadFromPersistentCache(key: "test_key")
        XCTAssertNotNil(loadedObject)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        // Test with invalid health data
        let invalidHealthData = HealthProfile(
            patientId: "invalid",
            cardiovascularData: CardiovascularData(),
            neurologicalData: NeurologicalData(),
            endocrineData: EndocrineData(),
            immuneData: ImmuneData(),
            metabolicData: MetabolicData(),
            lastUpdated: Date()
        )
        
        // Should handle gracefully
        let digitalTwin = engine.createDigitalTwin(from: invalidHealthData)
        XCTAssertNotNil(digitalTwin)
    }
    
    func testMemoryPressureHandling() {
        // Simulate memory pressure by creating many objects
        var twins: [BioDigitalTwin] = []
        
        for i in 0..<100 {
            let healthData = createTestHealthData(patientId: "pressure_test_\(i)")
            let twin = engine.createDigitalTwin(from: healthData)
            twins.append(twin)
        }
        
        // Trigger aggressive memory cleanup
        engine.optimizeMemoryUsage()
        
        // Should still be functional
        let healthData = createTestHealthData(patientId: "pressure_test_0")
        let twin = engine.createDigitalTwin(from: healthData)
        XCTAssertNotNil(twin)
    }
    
    // MARK: - Helper Methods
    
    private func createTestHealthData(patientId: String = "test_patient") -> HealthProfile {
        return HealthProfile(
            patientId: patientId,
            cardiovascularData: CardiovascularData(
                restingHeartRate: 72.0,
                restingBloodPressure: BloodPressure(systolic: 120, diastolic: 80),
                maxHeartRate: 190.0,
                strokeVolume: 70.0,
                cardiacOutput: 5.0
            ),
            neurologicalData: NeurologicalData(
                brainActivity: 0.8,
                cognitiveFunction: 0.9,
                stressLevel: 0.3,
                sleepQuality: 0.8
            ),
            endocrineData: EndocrineData(
                insulinLevel: 10.0,
                cortisolLevel: 15.0,
                thyroidLevel: 2.5,
                growthHormone: 1.0
            ),
            immuneData: ImmuneData(
                whiteBloodCellCount: 7000.0,
                infectionLevel: 0.1,
                inflammationLevel: 0.2,
                antibodyLevel: 0.8
            ),
            metabolicData: MetabolicData(
                glucoseLevel: 100.0,
                metabolicRate: 1.0,
                energyLevel: 0.8,
                hydrationLevel: 0.9
            ),
            lastUpdated: Date()
        )
    }
    
    static var allTests = [
        ("testEngineInitialization", testEngineInitialization),
        ("testDigitalTwinCreation", testDigitalTwinCreation),
        ("testDigitalTwinCaching", testDigitalTwinCaching),
        ("testSimulationPerformance", testSimulationPerformance),
        ("testConcurrentSimulation", testConcurrentSimulation),
        ("testMemoryOptimization", testMemoryOptimization),
        ("testCacheOptimization", testCacheOptimization),
        ("testPredictiveCaching", testPredictiveCaching),
        ("testAdaptiveTimeStepOptimization", testAdaptiveTimeStepOptimization),
        ("testPerformanceMonitoring", testPerformanceMonitoring),
        ("testCacheClearAndReset", testCacheClearAndReset),
        ("testPersistentCacheIntegration", testPersistentCacheIntegration),
        ("testErrorHandling", testErrorHandling),
        ("testMemoryPressureHandling", testMemoryPressureHandling)
    ]
} 