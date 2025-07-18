import XCTest
import CoreML
@testable import HealthAI2030

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
final class OptimizedMLModelManagerTests: XCTestCase {
    
    var mlManager: OptimizedMLModelManager!
    
    override func setUp() async throws {
        try await super.setUp()
        mlManager = OptimizedMLModelManager.shared
        await mlManager.clearCache() // Start with clean cache
    }
    
    override func tearDown() async throws {
        await mlManager.clearCache()
        mlManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Model Configuration Tests
    
    func testModelConfigurationDefaults() {
        let config = OptimizedMLModelManager.ModelConfiguration(modelName: "TestModel")
        
        XCTAssertEqual(config.modelName, "TestModel")
        XCTAssertEqual(config.quantizationType, .dynamic)
        XCTAssertEqual(config.computeUnits, .all)
        XCTAssertTrue(config.enableCaching)
        XCTAssertEqual(config.maxBatchSize, 1)
        XCTAssertEqual(config.optimizationLevel, .balanced)
    }
    
    func testModelConfigurationCustomization() {
        let config = OptimizedMLModelManager.ModelConfiguration(
            modelName: "CustomModel",
            quantizationType: .int8,
            computeUnits: .cpuOnly,
            enableCaching: false,
            maxBatchSize: 32,
            optimizationLevel: .aggressive
        )
        
        XCTAssertEqual(config.modelName, "CustomModel")
        XCTAssertEqual(config.quantizationType, .int8)
        XCTAssertEqual(config.computeUnits, .cpuOnly)
        XCTAssertFalse(config.enableCaching)
        XCTAssertEqual(config.maxBatchSize, 32)
        XCTAssertEqual(config.optimizationLevel, .aggressive)
    }
    
    // MARK: - Performance Metrics Tests
    
    func testPerformanceMetricsInitialization() {
        var metrics = OptimizedMLModelManager.ModelPerformanceMetrics()
        
        XCTAssertEqual(metrics.loadTime, 0)
        XCTAssertEqual(metrics.inferenceTime, 0)
        XCTAssertEqual(metrics.memoryUsage, 0)
        XCTAssertEqual(metrics.energyImpact, 0)
        XCTAssertEqual(metrics.accuracy, 0)
        XCTAssertEqual(metrics.throughput, 0)
        XCTAssertEqual(metrics.cacheHitRate, 0)
    }
    
    func testPerformanceMetricsUpdateInferenceTime() {
        var metrics = OptimizedMLModelManager.ModelPerformanceMetrics()
        
        metrics.updateInferenceTime(0.1)
        XCTAssertEqual(metrics.inferenceTime, 0.05, accuracy: 0.001) // Moving average: (0 + 0.1) / 2
        
        metrics.updateInferenceTime(0.2)
        XCTAssertEqual(metrics.inferenceTime, 0.125, accuracy: 0.001) // Moving average: (0.05 + 0.2) / 2
    }
    
    func testPerformanceMetricsUpdateThroughput() {
        var metrics = OptimizedMLModelManager.ModelPerformanceMetrics()
        
        metrics.updateThroughput(10.0)
        XCTAssertEqual(metrics.throughput, 5.0, accuracy: 0.001) // Moving average: (0 + 10) / 2
        
        metrics.updateThroughput(20.0)
        XCTAssertEqual(metrics.throughput, 12.5, accuracy: 0.001) // Moving average: (5 + 20) / 2
    }
    
    // MARK: - Cache Statistics Tests
    
    func testInitialCacheStatistics() async {
        let stats = await mlManager.getCacheStatistics()
        
        XCTAssertEqual(stats.totalModels, 0)
        XCTAssertEqual(stats.totalMemoryUsage, 0)
        XCTAssertEqual(stats.averageCacheHitRate, 0)
        XCTAssertNil(stats.oldestCacheEntry)
        XCTAssertNil(stats.newestCacheEntry)
    }
    
    func testCacheClearFunctionality() async {
        // Cache should start empty after setUp
        let initialStats = await mlManager.getCacheStatistics()
        XCTAssertEqual(initialStats.totalModels, 0)
        
        // Clear cache again - should remain empty
        await mlManager.clearCache()
        let finalStats = await mlManager.getCacheStatistics()
        XCTAssertEqual(finalStats.totalModels, 0)
    }
    
    // MARK: - Model Loading Tests (Mock-based)
    
    func testModelNotFoundError() async {
        let config = OptimizedMLModelManager.ModelConfiguration(
            modelName: "NonExistentModel"
        )
        
        do {
            _ = try await mlManager.loadOptimizedModel(config)
            XCTFail("Expected model not found error")
        } catch let error as MLModelError {
            switch error {
            case .modelNotFound(let name):
                XCTAssertEqual(name, "NonExistentModel")
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testModelNotLoadedInferenceError() async {
        do {
            _ = try await mlManager.performOptimizedInference(
                modelName: "UnloadedModel",
                input: MockMLFeatureProvider()
            )
            XCTFail("Expected model not loaded error")
        } catch let error as MLModelError {
            switch error {
            case .modelNotLoaded(let name):
                XCTAssertEqual(name, "UnloadedModel")
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Batch Processing Tests
    
    func testBatchChunking() {
        let array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let chunked = array.chunked(into: 3)
        
        XCTAssertEqual(chunked.count, 4)
        XCTAssertEqual(chunked[0], [1, 2, 3])
        XCTAssertEqual(chunked[1], [4, 5, 6])
        XCTAssertEqual(chunked[2], [7, 8, 9])
        XCTAssertEqual(chunked[3], [10])
    }
    
    func testEmptyBatchChunking() {
        let array: [Int] = []
        let chunked = array.chunked(into: 3)
        
        XCTAssertEqual(chunked.count, 0)
    }
    
    func testSingleElementBatchChunking() {
        let array = [42]
        let chunked = array.chunked(into: 3)
        
        XCTAssertEqual(chunked.count, 1)
        XCTAssertEqual(chunked[0], [42])
    }
    
    // MARK: - Average Calculation Tests
    
    func testDoubleArrayAverage() {
        let values = [1.0, 2.0, 3.0, 4.0, 5.0]
        XCTAssertEqual(values.average(), 3.0, accuracy: 0.001)
    }
    
    func testEmptyDoubleArrayAverage() {
        let values: [Double] = []
        XCTAssertEqual(values.average(), 0.0)
    }
    
    func testSingleElementDoubleArrayAverage() {
        let values = [42.0]
        XCTAssertEqual(values.average(), 42.0)
    }
    
    // MARK: - Configuration Optimization Tests
    
    func testQuantizationTypeSelection() {
        let configs = [
            OptimizedMLModelManager.ModelConfiguration.QuantizationType.none,
            .int8,
            .int16,
            .float16,
            .dynamic
        ]
        
        // Test that all quantization types are distinct
        XCTAssertEqual(Set(configs.map { "\($0)" }).count, configs.count)
    }
    
    func testOptimizationLevelSelection() {
        let levels = [
            OptimizedMLModelManager.ModelConfiguration.OptimizationLevel.none,
            .memory,
            .speed,
            .balanced,
            .aggressive
        ]
        
        // Test that all optimization levels are distinct
        XCTAssertEqual(Set(levels.map { "\($0)" }).count, levels.count)
    }
    
    // MARK: - Error Handling Tests
    
    func testMLModelErrorDescriptions() {
        let errors: [MLModelError] = [
            .modelNotFound("TestModel"),
            .modelNotLoaded("TestModel"),
            .optimizationFailed("Test reason"),
            .quantizationFailed("Test reason")
        ]
        
        for error in errors {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
            XCTAssertTrue(error.errorDescription?.contains("TestModel") ?? error.errorDescription?.contains("Test reason") ?? false)
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testCacheEvictionBehavior() async {
        // This test would require mock models to actually test cache behavior
        // For now, we test that the cache starts empty and can be cleared
        
        let initialStats = await mlManager.getCacheStatistics()
        XCTAssertEqual(initialStats.totalModels, 0)
        
        await mlManager.clearCache()
        
        let finalStats = await mlManager.getCacheStatistics()
        XCTAssertEqual(finalStats.totalModels, 0)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentCacheAccess() async {
        // Test that concurrent operations don't crash
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask { [weak self] in
                    let stats = await self?.mlManager.getCacheStatistics()
                    XCTAssertNotNil(stats)
                }
            }
        }
    }
    
    func testConcurrentClearCache() async {
        // Test that concurrent cache clears don't crash
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask { [weak self] in
                    await self?.mlManager.clearCache()
                }
            }
        }
        
        let finalStats = await mlManager.getCacheStatistics()
        XCTAssertEqual(finalStats.totalModels, 0)
    }
    
    // MARK: - Performance Tests
    
    func testCacheStatisticsPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Cache stats performance")
            
            Task {
                for _ in 0..<100 {
                    _ = await mlManager.getCacheStatistics()
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    func testMultipleClearCachePerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Clear cache performance")
            
            Task {
                for _ in 0..<10 {
                    await mlManager.clearCache()
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Integration Tests with Real CoreML (if available)
    
    func testMLComputeUnitsAvailability() {
        // Test that we can query ML compute units without crashing
        let allUnits: [MLComputeUnits] = [.all, .cpuOnly, .cpuAndGPU, .cpuAndNeuralEngine]
        
        for units in allUnits {
            let config = OptimizedMLModelManager.ModelConfiguration(
                modelName: "TestModel",
                computeUnits: units
            )
            XCTAssertEqual(config.computeUnits, units)
        }
    }
    
    func testMLModelConfigurationCreation() {
        // Test that we can create MLModelConfiguration without crashing
        let mlConfig = MLModelConfiguration()
        mlConfig.computeUnits = .cpuOnly
        mlConfig.allowLowPrecisionAccumulationOnGPU = false
        
        XCTAssertEqual(mlConfig.computeUnits, .cpuOnly)
        XCTAssertFalse(mlConfig.allowLowPrecisionAccumulationOnGPU)
    }
    
    func testMLPredictionOptionsCreation() {
        // Test that we can create MLPredictionOptions without crashing
        let options = MLPredictionOptions()
        options.usesCPUOnly = false
        
        XCTAssertFalse(options.usesCPUOnly)
    }
    
    // MARK: - Stress Tests
    
    func testStressCacheOperations() async {
        // Stress test with rapid cache operations
        await withTaskGroup(of: Void.self) { group in
            // Multiple concurrent readers
            for _ in 0..<20 {
                group.addTask { [weak self] in
                    for _ in 0..<50 {
                        _ = await self?.mlManager.getCacheStatistics()
                    }
                }
            }
            
            // Concurrent cache clears
            for _ in 0..<5 {
                group.addTask { [weak self] in
                    await self?.mlManager.clearCache()
                }
            }
        }
        
        // Should still be functional after stress test
        let finalStats = await mlManager.getCacheStatistics()
        XCTAssertNotNil(finalStats)
    }
}

// MARK: - Mock Classes for Testing

class MockMLFeatureProvider: MLFeatureProvider {
    var featureNames: Set<String> = ["mockFeature"]
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "mockFeature" {
            return MLFeatureValue(double: 1.0)
        }
        return nil
    }
}

class MockMLModel: MLModel {
    override var modelDescription: MLModelDescription {
        let inputDescription = MLFeatureDescription()
        let outputDescription = MLFeatureDescription()
        
        return MLModelDescription(
            inputDescriptionsByName: ["input": inputDescription],
            outputDescriptionsByName: ["output": outputDescription],
            predictedFeatureName: nil,
            predictedProbabilitiesName: nil,
            metadata: [:]
        )
    }
    
    override func prediction(from input: MLFeatureProvider) throws -> MLFeatureProvider {
        return MockMLFeatureProvider()
    }
}

// MARK: - Helper Extensions for Testing

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

private extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}