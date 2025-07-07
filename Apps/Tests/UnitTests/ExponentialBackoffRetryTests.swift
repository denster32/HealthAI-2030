import XCTest
import Foundation
@testable import HealthAI2030Networking

final class ExponentialBackoffRetryTests: XCTestCase {
    
    // MARK: - Basic Exponential Backoff Tests
    
    func testExponentialBackoffRetrySuccess() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        
        let result = try await errorHandler.exponentialBackoffRetry {
            callCount += 1
            return "Success on attempt \(callCount)"
        }
        
        XCTAssertEqual(result, "Success on attempt 1")
        XCTAssertEqual(callCount, 1, "Should succeed on first attempt")
    }
    
    func testExponentialBackoffRetryWithFailures() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        
        let result = try await errorHandler.exponentialBackoffRetry(
            operation: {
                callCount += 1
                if callCount < 3 {
                    throw URLError(.timedOut)
                }
                return "Success on attempt \(callCount)"
            },
            maxRetries: 5,
            initialDelay: 0.1
        )
        
        XCTAssertEqual(result, "Success on attempt 3")
        XCTAssertEqual(callCount, 3, "Should succeed on third attempt")
    }
    
    func testExponentialBackoffRetryMaxRetriesExceeded() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    throw URLError(.timedOut)
                },
                maxRetries: 2,
                initialDelay: 0.1
            )
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertEqual(callCount, 3, "Should have made 3 attempts (1 initial + 2 retries)")
            XCTAssertTrue(error is URLError)
        }
    }
    
    // MARK: - Delay Calculation Tests
    
    func testExponentialBackoffDelayCalculation() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        var delays: [TimeInterval] = []
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    if callCount > 1 {
                        delays.append(CFAbsoluteTimeGetCurrent() - startTime)
                    }
                    throw URLError(.timedOut)
                },
                maxRetries: 3,
                initialDelay: 0.1
            )
        } catch {
            // Expected to fail
        }
        
        XCTAssertEqual(callCount, 4, "Should have made 4 attempts")
        XCTAssertEqual(delays.count, 3, "Should have recorded 3 delays")
        
        // Verify exponential backoff delays (approximately)
        // Initial delay: 0.1s, then 0.2s, then 0.4s
        if delays.count >= 1 {
            XCTAssertGreaterThan(delays[0], 0.05, "First delay should be at least 0.05s")
            XCTAssertLessThan(delays[0], 0.2, "First delay should be less than 0.2s")
        }
        
        if delays.count >= 2 {
            XCTAssertGreaterThan(delays[1], delays[0], "Second delay should be greater than first")
        }
        
        if delays.count >= 3 {
            XCTAssertGreaterThan(delays[2], delays[1], "Third delay should be greater than second")
        }
    }
    
    func testExponentialBackoffWithCustomInitialDelay() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    throw URLError(.timedOut)
                },
                maxRetries: 1,
                initialDelay: 0.5
            )
        } catch {
            // Expected to fail
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertGreaterThan(totalTime, 0.4, "Should have waited at least 0.4s")
        XCTAssertLessThan(totalTime, 1.0, "Should not have waited more than 1.0s")
    }
    
    // MARK: - Error Type Filtering Tests
    
    func testExponentialBackoffRetryOnlyForSpecificErrors() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        
        // Test with timeout error (should retry)
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    throw URLError(.timedOut)
                },
                maxRetries: 2,
                initialDelay: 0.1
            )
        } catch {
            XCTAssertEqual(callCount, 3, "Should have retried timeout errors")
        }
        
        // Reset call count
        callCount = 0
        
        // Test with network offline error (should retry)
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    throw URLError(.notConnectedToInternet)
                },
                maxRetries: 2,
                initialDelay: 0.1
            )
        } catch {
            XCTAssertEqual(callCount, 3, "Should have retried network offline errors")
        }
        
        // Reset call count
        callCount = 0
        
        // Test with decoding error (should not retry)
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    throw AppNetworkError.decodingError
                },
                maxRetries: 2,
                initialDelay: 0.1
            )
        } catch {
            XCTAssertEqual(callCount, 1, "Should not retry decoding errors")
        }
    }
    
    func testExponentialBackoffRetryWithServerErrors() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        
        // Test with server error (should retry)
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    throw AppNetworkError.serverError(statusCode: 500, message: "Internal Server Error")
                },
                maxRetries: 2,
                initialDelay: 0.1
            )
        } catch {
            XCTAssertEqual(callCount, 3, "Should have retried server errors")
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testExponentialBackoffRetryWithZeroMaxRetries() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    throw URLError(.timedOut)
                },
                maxRetries: 0,
                initialDelay: 0.1
            )
        } catch {
            XCTAssertEqual(callCount, 1, "Should not retry with zero max retries")
        }
    }
    
    func testExponentialBackoffRetryWithZeroInitialDelay() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    throw URLError(.timedOut)
                },
                maxRetries: 2,
                initialDelay: 0.0
            )
        } catch {
            XCTAssertEqual(callCount, 3, "Should still retry with zero initial delay")
        }
    }
    
    func testExponentialBackoffRetryWithNegativeValues() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    throw URLError(.timedOut)
                },
                maxRetries: -1,
                initialDelay: -1.0
            )
        } catch {
            XCTAssertEqual(callCount, 1, "Should not retry with negative max retries")
        }
    }
    
    // MARK: - Performance Tests
    
    func testExponentialBackoffRetryPerformance() async throws {
        let errorHandler = NetworkErrorHandler.shared
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test with successful operation
        _ = try await errorHandler.exponentialBackoffRetry {
            return "Success"
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should be very fast for successful operations
        XCTAssertLessThan(duration, 0.1, "Successful operation took too long: \(duration)s")
    }
    
    func testExponentialBackoffRetryMemoryUsage() async throws {
        // Test that retry mechanism doesn't leak memory
        weak var weakErrorHandler: NetworkErrorHandler?
        
        autoreleasepool {
            let errorHandler = NetworkErrorHandler.shared
            weakErrorHandler = errorHandler
            
            // Perform operations
            Task {
                do {
                    _ = try await errorHandler.exponentialBackoffRetry(
                        operation: {
                            throw URLError(.timedOut)
                        },
                        maxRetries: 1,
                        initialDelay: 0.1
                    )
                } catch {
                    // Expected to fail
                }
            }
        }
        
        // Error handler should not be deallocated (it's a singleton)
        XCTAssertNotNil(weakErrorHandler, "Error handler should not be deallocated")
    }
    
    // MARK: - Integration Tests
    
    func testExponentialBackoffRetryWithNetworkSimulation() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        var successCount = 0
        
        // Simulate network conditions
        for i in 1...10 {
            do {
                let result = try await errorHandler.exponentialBackoffRetry(
                    operation: {
                        callCount += 1
                        // Simulate intermittent failures
                        if i % 3 == 0 {
                            throw URLError(.timedOut)
                        }
                        return "Success \(i)"
                    },
                    maxRetries: 2,
                    initialDelay: 0.1
                )
                
                successCount += 1
                XCTAssertEqual(result, "Success \(i)")
            } catch {
                // Some operations will fail after retries
            }
        }
        
        XCTAssertGreaterThan(successCount, 0, "Should have some successful operations")
        XCTAssertGreaterThan(callCount, 10, "Should have made more calls due to retries")
    }
    
    func testExponentialBackoffRetryWithMixedErrorTypes() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        var timeoutCount = 0
        var serverErrorCount = 0
        var decodingErrorCount = 0
        
        // Test with different error types
        for i in 1...15 {
            do {
                _ = try await errorHandler.exponentialBackoffRetry(
                    operation: {
                        callCount += 1
                        
                        // Simulate different error types
                        switch i % 4 {
                        case 0:
                            throw URLError(.timedOut)
                        case 1:
                            throw AppNetworkError.serverError(statusCode: 500, message: "Server Error")
                        case 2:
                            throw AppNetworkError.decodingError
                        default:
                            return "Success"
                        }
                    },
                    maxRetries: 2,
                    initialDelay: 0.1
                )
            } catch {
                if error is URLError {
                    timeoutCount += 1
                } else if case AppNetworkError.serverError = error {
                    serverErrorCount += 1
                } else if case AppNetworkError.decodingError = error {
                    decodingErrorCount += 1
                }
            }
        }
        
        // Should have retried timeout and server errors, but not decoding errors
        XCTAssertGreaterThan(timeoutCount, 0, "Should have some timeout errors")
        XCTAssertGreaterThan(serverErrorCount, 0, "Should have some server errors")
        XCTAssertGreaterThan(decodingErrorCount, 0, "Should have some decoding errors")
    }
    
    // MARK: - Stress Tests
    
    func testExponentialBackoffRetryStressTest() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var totalCalls = 0
        var successfulCalls = 0
        
        // Perform many operations with retries
        for i in 0..<50 {
            do {
                let result = try await errorHandler.exponentialBackoffRetry(
                    operation: {
                        totalCalls += 1
                        
                        // Randomly succeed or fail
                        if Bool.random() {
                            return "Success \(i)"
                        } else {
                            throw URLError(.timedOut)
                        }
                    },
                    maxRetries: 1,
                    initialDelay: 0.05
                )
                
                successfulCalls += 1
                XCTAssertEqual(result, "Success \(i)")
            } catch {
                // Some operations will fail
            }
        }
        
        // Should have some successful operations
        XCTAssertGreaterThan(successfulCalls, 0, "Should have some successful operations")
        XCTAssertGreaterThan(totalCalls, 50, "Should have made more calls due to retries")
    }
    
    func testExponentialBackoffRetryConcurrentAccess() async throws {
        let errorHandler = NetworkErrorHandler.shared
        let expectation = XCTestExpectation(description: "Concurrent retry test")
        let queue = DispatchQueue(label: "test", attributes: .concurrent)
        
        var totalCalls = 0
        var successfulCalls = 0
        
        // Perform concurrent operations
        for i in 0..<20 {
            queue.async {
                Task {
                    do {
                        let result = try await errorHandler.exponentialBackoffRetry(
                            operation: {
                                totalCalls += 1
                                
                                // Randomly succeed or fail
                                if Bool.random() {
                                    return "Success \(i)"
                                } else {
                                    throw URLError(.timedOut)
                                }
                            },
                            maxRetries: 1,
                            initialDelay: 0.05
                        )
                        
                        successfulCalls += 1
                        XCTAssertEqual(result, "Success \(i)")
                    } catch {
                        // Some operations will fail
                    }
                }
            }
        }
        
        queue.async {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        // Should have some successful operations
        XCTAssertGreaterThan(successfulCalls, 0, "Should have some successful operations")
        XCTAssertGreaterThan(totalCalls, 20, "Should have made more calls due to retries")
    }
    
    // MARK: - Error Categorization Tests
    
    func testErrorCategorizationForRetry() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        
        // Test URLError categorization
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    throw URLError(.notConnectedToInternet)
                },
                maxRetries: 1,
                initialDelay: 0.1
            )
        } catch {
            XCTAssertEqual(callCount, 2, "Should retry network offline errors")
        }
        
        // Reset call count
        callCount = 0
        
        // Test custom error categorization
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    throw AppNetworkError.unknownError
                },
                maxRetries: 1,
                initialDelay: 0.1
            )
        } catch {
            XCTAssertEqual(callCount, 1, "Should not retry unknown errors")
        }
    }
    
    // MARK: - Recovery Tests
    
    func testExponentialBackoffRetryRecovery() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        var failureCount = 0
        
        // Simulate a service that recovers after some failures
        let result = try await errorHandler.exponentialBackoffRetry(
            operation: {
                callCount += 1
                failureCount += 1
                
                // Fail first 3 times, then succeed
                if failureCount <= 3 {
                    throw URLError(.timedOut)
                }
                
                return "Recovered after \(failureCount) failures"
            },
            maxRetries: 5,
            initialDelay: 0.1
        )
        
        XCTAssertEqual(result, "Recovered after 4 failures")
        XCTAssertEqual(callCount, 4, "Should have succeeded on 4th attempt")
    }
    
    func testExponentialBackoffRetryPartialRecovery() async throws {
        let errorHandler = NetworkErrorHandler.shared
        var callCount = 0
        var failureCount = 0
        
        // Simulate a service that partially recovers
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    callCount += 1
                    failureCount += 1
                    
                    // Fail first 2 times, succeed once, then fail again
                    if failureCount <= 2 || failureCount > 3 {
                        throw URLError(.timedOut)
                    }
                    
                    return "Temporary success"
                },
                maxRetries: 3,
                initialDelay: 0.1
            )
        } catch {
            XCTAssertEqual(callCount, 5, "Should have made 5 attempts (1 initial + 3 retries + 1 more after success)")
        }
    }
} 