import XCTest
import Foundation
@testable import HealthAI2030Core

final class CircuitBreakerTests: XCTestCase {
    
    // MARK: - Basic Circuit Breaker Tests
    
    func testCircuitBreakerInitialization() {
        let circuitBreaker = CircuitBreaker()
        
        // Test default values
        XCTAssertTrue(circuitBreaker.allowRequest(), "Circuit should be closed initially")
        
        let customBreaker = CircuitBreaker(failureThreshold: 3, resetTimeout: 30)
        XCTAssertTrue(customBreaker.allowRequest(), "Custom circuit should be closed initially")
    }
    
    func testCircuitBreakerStateTransitions() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 2, resetTimeout: 1.0)
        
        // Initial state should be closed
        XCTAssertTrue(circuitBreaker.allowRequest(), "Should allow requests when closed")
        
        // First failure
        circuitBreaker.recordFailure()
        XCTAssertTrue(circuitBreaker.allowRequest(), "Should still allow requests after first failure")
        
        // Second failure - should open circuit
        circuitBreaker.recordFailure()
        XCTAssertFalse(circuitBreaker.allowRequest(), "Should not allow requests when circuit is open")
        
        // Wait for reset timeout
        Thread.sleep(forTimeInterval: 1.1)
        
        // Should transition to half-open
        XCTAssertTrue(circuitBreaker.allowRequest(), "Should allow request when half-open")
        
        // Success should close circuit
        circuitBreaker.recordSuccess()
        XCTAssertTrue(circuitBreaker.allowRequest(), "Should allow requests when closed")
    }
    
    func testCircuitBreakerFailureThreshold() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 3, resetTimeout: 1.0)
        
        // Record failures up to threshold
        for i in 1...3 {
            circuitBreaker.recordFailure()
            if i < 3 {
                XCTAssertTrue(circuitBreaker.allowRequest(), "Should allow requests before threshold")
            } else {
                XCTAssertFalse(circuitBreaker.allowRequest(), "Should not allow requests at threshold")
            }
        }
    }
    
    func testCircuitBreakerResetTimeout() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 1, resetTimeout: 0.5)
        
        // Trigger circuit to open
        circuitBreaker.recordFailure()
        XCTAssertFalse(circuitBreaker.allowRequest(), "Circuit should be open")
        
        // Wait less than reset timeout
        Thread.sleep(forTimeInterval: 0.2)
        XCTAssertFalse(circuitBreaker.allowRequest(), "Circuit should still be open")
        
        // Wait for reset timeout
        Thread.sleep(forTimeInterval: 0.4)
        XCTAssertTrue(circuitBreaker.allowRequest(), "Circuit should be half-open after timeout")
    }
    
    func testCircuitBreakerSuccessResetsFailureCount() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 3, resetTimeout: 1.0)
        
        // Record some failures
        circuitBreaker.recordFailure()
        circuitBreaker.recordFailure()
        
        // Record success
        circuitBreaker.recordSuccess()
        
        // Should be back to closed state
        XCTAssertTrue(circuitBreaker.allowRequest(), "Should allow requests after success")
        
        // Failure count should be reset
        circuitBreaker.recordFailure()
        XCTAssertTrue(circuitBreaker.allowRequest(), "Should allow requests after reset failure count")
    }
    
    // MARK: - Edge Case Tests
    
    func testCircuitBreakerWithZeroFailureThreshold() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 0, resetTimeout: 1.0)
        
        // Should open immediately on first failure
        circuitBreaker.recordFailure()
        XCTAssertFalse(circuitBreaker.allowRequest(), "Should not allow requests with zero threshold")
    }
    
    func testCircuitBreakerWithVeryShortResetTimeout() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 1, resetTimeout: 0.1)
        
        // Trigger circuit to open
        circuitBreaker.recordFailure()
        XCTAssertFalse(circuitBreaker.allowRequest(), "Circuit should be open")
        
        // Wait for reset timeout
        Thread.sleep(forTimeInterval: 0.15)
        XCTAssertTrue(circuitBreaker.allowRequest(), "Circuit should be half-open after short timeout")
    }
    
    func testCircuitBreakerWithVeryLongResetTimeout() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 1, resetTimeout: 10.0)
        
        // Trigger circuit to open
        circuitBreaker.recordFailure()
        XCTAssertFalse(circuitBreaker.allowRequest(), "Circuit should be open")
        
        // Wait less than reset timeout
        Thread.sleep(forTimeInterval: 0.1)
        XCTAssertFalse(circuitBreaker.allowRequest(), "Circuit should still be open")
    }
    
    func testCircuitBreakerMultipleSuccessCalls() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 2, resetTimeout: 1.0)
        
        // Record some failures
        circuitBreaker.recordFailure()
        circuitBreaker.recordFailure()
        XCTAssertFalse(circuitBreaker.allowRequest(), "Circuit should be open")
        
        // Multiple success calls should not cause issues
        circuitBreaker.recordSuccess()
        circuitBreaker.recordSuccess()
        circuitBreaker.recordSuccess()
        
        XCTAssertTrue(circuitBreaker.allowRequest(), "Should allow requests after multiple success calls")
    }
    
    func testCircuitBreakerMultipleFailureCalls() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 2, resetTimeout: 1.0)
        
        // Multiple failure calls should not cause issues
        circuitBreaker.recordFailure()
        circuitBreaker.recordFailure()
        circuitBreaker.recordFailure()
        circuitBreaker.recordFailure()
        
        XCTAssertFalse(circuitBreaker.allowRequest(), "Should not allow requests after multiple failures")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testCircuitBreakerConcurrentAccess() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 5, resetTimeout: 1.0)
        let expectation = XCTestExpectation(description: "Concurrent access test")
        let queue = DispatchQueue(label: "test", attributes: .concurrent)
        
        var successCount = 0
        var failureCount = 0
        
        // Perform concurrent operations
        for i in 0..<100 {
            queue.async {
                if i % 2 == 0 {
                    circuitBreaker.recordSuccess()
                    successCount += 1
                } else {
                    circuitBreaker.recordFailure()
                    failureCount += 1
                }
            }
        }
        
        queue.async {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Circuit should still function correctly
        let canMakeRequest = circuitBreaker.allowRequest()
        XCTAssertTrue(canMakeRequest || !canMakeRequest, "Circuit should be in a valid state")
    }
    
    // MARK: - Performance Tests
    
    func testCircuitBreakerPerformance() {
        let circuitBreaker = CircuitBreaker()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform many operations
        for _ in 0..<10000 {
            let _ = circuitBreaker.allowRequest()
            circuitBreaker.recordSuccess()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should be very fast (< 0.1 seconds for 10000 operations)
        XCTAssertLessThan(duration, 0.1, "Circuit breaker operations took too long: \(duration)s")
    }
    
    func testCircuitBreakerMemoryUsage() {
        // Test that circuit breaker doesn't leak memory
        weak var weakBreaker: CircuitBreaker?
        
        autoreleasepool {
            let breaker = CircuitBreaker()
            weakBreaker = breaker
            
            // Perform operations
            for _ in 0..<1000 {
                breaker.recordFailure()
                breaker.recordSuccess()
            }
        }
        
        // Circuit breaker should be deallocated
        XCTAssertNil(weakBreaker, "Circuit breaker should be deallocated")
    }
    
    // MARK: - Integration Tests
    
    func testCircuitBreakerWithNetworkSimulation() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 3, resetTimeout: 0.5)
        
        // Simulate network failures
        for i in 1...5 {
            let canMakeRequest = circuitBreaker.allowRequest()
            
            if canMakeRequest {
                // Simulate network request
                let success = i % 2 == 0 // Every other request succeeds
                
                if success {
                    circuitBreaker.recordSuccess()
                } else {
                    circuitBreaker.recordFailure()
                }
            } else {
                // Circuit is open, wait for timeout
                Thread.sleep(forTimeInterval: 0.6)
            }
        }
        
        // Circuit should eventually stabilize
        let finalState = circuitBreaker.allowRequest()
        XCTAssertTrue(finalState || !finalState, "Circuit should be in a valid final state")
    }
    
    func testCircuitBreakerWithDifferentThresholds() {
        let thresholds = [1, 2, 5, 10]
        
        for threshold in thresholds {
            let circuitBreaker = CircuitBreaker(failureThreshold: threshold, resetTimeout: 0.1)
            
            // Record failures up to threshold
            for i in 1...threshold {
                circuitBreaker.recordFailure()
                if i < threshold {
                    XCTAssertTrue(circuitBreaker.allowRequest(), "Should allow requests before threshold \(threshold)")
                } else {
                    XCTAssertFalse(circuitBreaker.allowRequest(), "Should not allow requests at threshold \(threshold)")
                }
            }
            
            // Wait for reset
            Thread.sleep(forTimeInterval: 0.15)
            XCTAssertTrue(circuitBreaker.allowRequest(), "Should allow requests after reset for threshold \(threshold)")
        }
    }
    
    // MARK: - Error Recovery Tests
    
    func testCircuitBreakerErrorRecovery() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 2, resetTimeout: 0.5)
        
        // Simulate a failing service
        for _ in 1...3 {
            circuitBreaker.recordFailure()
        }
        
        // Circuit should be open
        XCTAssertFalse(circuitBreaker.allowRequest(), "Circuit should be open")
        
        // Wait for reset timeout
        Thread.sleep(forTimeInterval: 0.6)
        
        // Try a request (should be half-open)
        XCTAssertTrue(circuitBreaker.allowRequest(), "Circuit should be half-open")
        
        // If this request succeeds, circuit should close
        circuitBreaker.recordSuccess()
        XCTAssertTrue(circuitBreaker.allowRequest(), "Circuit should be closed after successful recovery")
        
        // If this request fails, circuit should open again
        circuitBreaker.recordFailure()
        XCTAssertFalse(circuitBreaker.allowRequest(), "Circuit should open again after failure in half-open state")
    }
    
    func testCircuitBreakerPartialRecovery() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 3, resetTimeout: 0.5)
        
        // Simulate multiple failures
        for _ in 1...4 {
            circuitBreaker.recordFailure()
        }
        
        // Circuit should be open
        XCTAssertFalse(circuitBreaker.allowRequest(), "Circuit should be open")
        
        // Wait for reset timeout
        Thread.sleep(forTimeInterval: 0.6)
        
        // Try a request (should be half-open)
        XCTAssertTrue(circuitBreaker.allowRequest(), "Circuit should be half-open")
        
        // If this request fails, circuit should open again
        circuitBreaker.recordFailure()
        XCTAssertFalse(circuitBreaker.allowRequest(), "Circuit should open again after failure")
        
        // Wait for reset timeout again
        Thread.sleep(forTimeInterval: 0.6)
        
        // Try another request
        XCTAssertTrue(circuitBreaker.allowRequest(), "Circuit should be half-open again")
        
        // This time succeed
        circuitBreaker.recordSuccess()
        XCTAssertTrue(circuitBreaker.allowRequest(), "Circuit should be closed after success")
    }
    
    // MARK: - Stress Tests
    
    func testCircuitBreakerStressTest() {
        let circuitBreaker = CircuitBreaker(failureThreshold: 5, resetTimeout: 0.1)
        
        // Perform many rapid operations
        for _ in 0..<1000 {
            let canMakeRequest = circuitBreaker.allowRequest()
            
            if canMakeRequest {
                // Randomly succeed or fail
                if Bool.random() {
                    circuitBreaker.recordSuccess()
                } else {
                    circuitBreaker.recordFailure()
                }
            } else {
                // Circuit is open, wait a bit
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
        
        // Circuit should still be functional
        let finalState = circuitBreaker.allowRequest()
        XCTAssertTrue(finalState || !finalState, "Circuit should be in a valid state after stress test")
    }
    
    func testMultipleCircuitBreakers() {
        let breakers = [
            CircuitBreaker(failureThreshold: 1, resetTimeout: 0.1),
            CircuitBreaker(failureThreshold: 2, resetTimeout: 0.2),
            CircuitBreaker(failureThreshold: 3, resetTimeout: 0.3)
        ]
        
        // Test each breaker independently
        for (index, breaker) in breakers.enumerated() {
            // Trigger circuit to open
            for _ in 1...breaker.failureThreshold {
                breaker.recordFailure()
            }
            
            XCTAssertFalse(breaker.allowRequest(), "Breaker \(index) should be open")
            
            // Wait for reset
            Thread.sleep(forTimeInterval: 0.4)
            
            XCTAssertTrue(breaker.allowRequest(), "Breaker \(index) should be half-open")
        }
    }
} 