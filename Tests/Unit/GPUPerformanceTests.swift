import XCTest
@testable import Core

final class GPUPerformanceTests: XCTestCase {
    func testGPUAcceleratedMLSetup() {
        let optimizer = MetalOptimizer.shared
        let accelerator = optimizer.setupGPUAcceleratedML()
        XCTAssertNotNil(accelerator)
    }
    
    func testGPUDataPipelineCreation() {
        let optimizer = MetalOptimizer.shared
        let pipeline = optimizer.createGPUDataPipeline()
        XCTAssertNotNil(pipeline)
    }
    
    func testGPUImageProcessingSetup() {
        let optimizer = MetalOptimizer.shared
        let processor = optimizer.setupGPUImageProcessing()
        XCTAssertNotNil(processor)
    }
    
    func testGPUPerformanceBenchmark() {
        let optimizer = MetalOptimizer.shared
        let results = optimizer.benchmarkGPUPerformance()
        XCTAssertTrue(results.summary.contains("benchmarks passed"))
    }
    
    func testGPUHealthAnalysisSetup() {
        let optimizer = MetalOptimizer.shared
        let analyzer = optimizer.setupGPUHealthAnalysis()
        XCTAssertNotNil(analyzer)
    }
} 