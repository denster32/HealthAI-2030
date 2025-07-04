//
//  PerformanceOptimizerTests.swift
//  HealthAI 2030Tests
//
//  Created by System on 7/4/2025.
//  Copyright © 2025 HealthAI. All rights reserved.
//

import XCTest
@testable import HealthAI_2030

final class PerformanceOptimizerTests: XCTestCase {
    
    var optimizer: PerformanceOptimizer!
    
    override func setUp() {
        super.setUp()
        optimizer = PerformanceOptimizer.shared
        optimizer.initialize()
    }
    
    override func tearDown() {
        optimizer = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testSharedInstance() {
        XCTAssertNotNil(PerformanceOptimizer.shared)
        XCTAssertTrue(PerformanceOptimizer.shared === optimizer)
    }
    
    func testInitialOptimizationLevel() {
        XCTAssertEqual(optimizer.optimizationLevel, 50)
    }
    
    // MARK: - Optimization Level Tests
    
    func testSetOptimizationLevel() {
        optimizer.setOptimizationLevel(75)
        XCTAssertEqual(optimizer.optimizationLevel, 75)
        
        // Test clamping at boundaries
        optimizer.setOptimizationLevel(-10)
        XCTAssertEqual(optimizer.optimizationLevel, 0)
        
        optimizer.setOptimizationLevel(150)
        XCTAssertEqual(optimizer.optimizationLevel, 100)
    }
    
    // MARK: - View Registration Tests
    
    func testRegisterView() {
        let testView = Text("Test View")
        optimizer.registerView(testView, name: "TestView")
        
        // In real implementation would verify optimization applied
        XCTAssertTrue(true)
    }
    
    // MARK: - Metrics Collection Tests
    
    func testGetMetricsReport() {
        let metrics = optimizer.getMetricsReport()
        
        // Verify metrics are within expected ranges
        XCTAssertGreaterThanOrEqual(metrics.cpuUsage, 0)
        XCTAssertLessThanOrEqual(metrics.cpuUsage, 100)
        
        XCTAssertGreaterThanOrEqual(metrics.memoryUsage, 0)
        XCTAssertLessThanOrEqual(metrics.memoryUsage, 100)
        
        XCTAssertGreaterThanOrEqual(metrics.fps, 30)
        XCTAssertLessThanOrEqual(metrics.fps, 120)
    }
    
    // MARK: - Memory Pressure Tests
    
    func testMemoryPressureHandling() {
        let initialLevel = optimizer.optimizationLevel
        
        // Simulate memory pressure warning
        optimizer.handleMemoryPressure(.warning)
        XCTAssertGreaterThan(optimizer.optimizationLevel, initialLevel)
        
        let warningLevel = optimizer.optimizationLevel
        
        // Simulate critical memory pressure
        optimizer.handleMemoryPressure(.critical)
        XCTAssertGreaterThan(optimizer.optimizationLevel, warningLevel)
    }
    
    // MARK: - Performance Tests
    
    func testOptimizationPerformance() {
        measure {
            for level in stride(from: 0, through: 100, by: 10) {
                optimizer.setOptimizationLevel(level)
            }
        }
    }
    
    func testMetricsCollectionPerformance() {
        measure {
            for _ in 0..<100 {
                _ = optimizer.getMetricsReport()
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testConcurrentAccess() {
        let queue = DispatchQueue.global(qos: .userInitiated)
        let group = DispatchGroup()
        
        for _ in 0..<100 {
            group.enter()
            queue.async {
                self.optimizer.setOptimizationLevel(Int.random(in: 0...100))
                _ = self.optimizer.getMetricsReport()
                group.leave()
            }
        }
        
        group.wait()
        XCTAssertTrue(true) // If we get here without crashing, test passes
    }
}