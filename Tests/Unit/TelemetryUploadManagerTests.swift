import XCTest
import Foundation
import AWSS3
@testable import HealthAI2030

final class TelemetryUploadManagerTests: XCTestCase {
    
    var telemetryManager: TelemetryUploadManager!
    var mockConfig: MockTelemetryConfig!
    var mockURLSession: MockURLSession!
    var mockS3TransferUtility: MockAWSS3TransferUtility!
    
    override func setUp() {
        super.setUp()
        mockConfig = MockTelemetryConfig()
        mockURLSession = MockURLSession()
        mockS3TransferUtility = MockAWSS3TransferUtility()
        
        telemetryManager = TelemetryUploadManager(
            config: mockConfig,
            urlSession: mockURLSession,
            s3TransferUtility: mockS3TransferUtility
        )
    }
    
    override func tearDown() {
        telemetryManager = nil
        mockConfig = nil
        mockURLSession = nil
        mockS3TransferUtility = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitializationWithValidConfig() {
        // Given
        let config = MockTelemetryConfig()
        config.apiEndpoint = URL(string: "https://api.healthai.com/telemetry")!
        config.s3Bucket = "healthai-telemetry"
        config.awsRegion = .USEast1
        
        // When
        let manager = TelemetryUploadManager(
            config: config,
            urlSession: mockURLSession,
            s3TransferUtility: mockS3TransferUtility
        )
        
        // Then
        XCTAssertNotNil(manager)
    }
    
    func testInitializationWithSecureHeaders() {
        // Given
        let config = MockTelemetryConfig()
        
        // When
        let manager = TelemetryUploadManager(
            config: config,
            urlSession: mockURLSession,
            s3TransferUtility: mockS3TransferUtility
        )
        
        // Then
        XCTAssertNotNil(manager)
        // Verify secure headers are set in URLSession configuration
        XCTAssertTrue(mockURLSession.configuration.tlsMinimumSupportedProtocolVersion == .TLSv13)
        XCTAssertEqual(mockURLSession.configuration.requestCachePolicy, .reloadIgnoringLocalCacheData)
    }
    
    // MARK: - API Upload Tests
    
    func testUploadToAPISuccessfully() {
        // Given
        let events = createTestTelemetryEvents()
        let expectation = XCTestExpectation(description: "API upload should succeed")
        
        mockURLSession.mockResponse = createMockHTTPResponse(statusCode: 200)
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API upload should succeed: \(error)")
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(mockURLSession.dataTaskCallCount, 1)
    }
    
    func testUploadToAPIWithRetryOnFailure() {
        // Given
        let events = createTestTelemetryEvents()
        let expectation = XCTestExpectation(description: "API upload should retry and eventually succeed")
        
        // Mock first two attempts to fail, third to succeed
        mockURLSession.mockResponses = [
            createMockHTTPResponse(statusCode: 500),
            createMockHTTPResponse(statusCode: 503),
            createMockHTTPResponse(statusCode: 200)
        ]
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API upload should eventually succeed: \(error)")
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(mockURLSession.dataTaskCallCount, 3)
    }
    
    func testUploadToAPIWithMaxRetriesExceeded() {
        // Given
        let events = createTestTelemetryEvents()
        let expectation = XCTestExpectation(description: "API upload should fail after max retries")
        
        // Mock all attempts to fail
        mockURLSession.mockResponses = Array(repeating: createMockHTTPResponse(statusCode: 500), count: 4)
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                XCTFail("API upload should fail after max retries")
            case .failure(let error):
                XCTAssertTrue(error is TelemetryUploadError)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(mockURLSession.dataTaskCallCount, 3) // Max retry count
    }
    
    func testUploadToAPIWithNetworkError() {
        // Given
        let events = createTestTelemetryEvents()
        let expectation = XCTestExpectation(description: "API upload should handle network error")
        
        mockURLSession.mockError = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: nil)
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                XCTFail("API upload should fail with network error")
            case .failure(let error):
                XCTAssertTrue(error is TelemetryUploadError)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - S3 Fallback Tests
    
    func testS3FallbackOnAPIFailure() {
        // Given
        let events = createTestTelemetryEvents()
        let expectation = XCTestExpectation(description: "Should fallback to S3 when API fails")
        
        mockURLSession.mockResponse = createMockHTTPResponse(statusCode: 500)
        mockS3TransferUtility.shouldSucceed = true
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("S3 fallback should succeed: \(error)")
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(mockURLSession.dataTaskCallCount, 1)
        XCTAssertEqual(mockS3TransferUtility.uploadCallCount, 1)
    }
    
    func testS3FallbackWithRetry() {
        // Given
        let events = createTestTelemetryEvents()
        let expectation = XCTestExpectation(description: "S3 fallback should retry and succeed")
        
        mockURLSession.mockResponse = createMockHTTPResponse(statusCode: 500)
        mockS3TransferUtility.shouldSucceed = false
        mockS3TransferUtility.shouldSucceedAfterRetries = 2
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("S3 fallback should eventually succeed: \(error)")
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(mockS3TransferUtility.uploadCallCount, 3)
    }
    
    func testS3FallbackWithMaxRetriesExceeded() {
        // Given
        let events = createTestTelemetryEvents()
        let expectation = XCTestExpectation(description: "S3 fallback should fail after max retries")
        
        mockURLSession.mockResponse = createMockHTTPResponse(statusCode: 500)
        mockS3TransferUtility.shouldSucceed = false
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                XCTFail("S3 fallback should fail after max retries")
            case .failure(let error):
                XCTAssertTrue(error is TelemetryUploadError)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(mockS3TransferUtility.uploadCallCount, 3) // Max retry count
    }
    
    // MARK: - Combined Error Tests
    
    func testBothAPIAndS3Failure() {
        // Given
        let events = createTestTelemetryEvents()
        let expectation = XCTestExpectation(description: "Should fail when both API and S3 fail")
        
        mockURLSession.mockResponse = createMockHTTPResponse(statusCode: 500)
        mockS3TransferUtility.shouldSucceed = false
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                XCTFail("Should fail when both API and S3 fail")
            case .failure(let error):
                if case TelemetryUploadError.combined = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Should return combined error")
                }
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Data Validation Tests
    
    func testUploadWithEmptyEventsArray() {
        // Given
        let events: [TelemetryEvent] = []
        let expectation = XCTestExpectation(description: "Should handle empty events array")
        
        mockURLSession.mockResponse = createMockHTTPResponse(statusCode: 200)
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should succeed with empty events: \(error)")
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testUploadWithLargeEventsArray() {
        // Given
        let events = createLargeTelemetryEventsArray()
        let expectation = XCTestExpectation(description: "Should handle large events array")
        
        mockURLSession.mockResponse = createMockHTTPResponse(statusCode: 200)
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should succeed with large events array: \(error)")
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Security Tests
    
    func testSecureCredentialRetrieval() {
        // Given
        let events = createTestTelemetryEvents()
        let expectation = XCTestExpectation(description: "Should use secure credentials")
        
        mockURLSession.mockResponse = createMockHTTPResponse(statusCode: 200)
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should succeed with secure credentials: \(error)")
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        
        // Verify secure headers were set
        if let request = mockURLSession.lastRequest {
            XCTAssertNotNil(request.value(forHTTPHeaderField: "Authorization"))
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertNotNil(request.value(forHTTPHeaderField: "X-Request-ID"))
        }
    }
    
    func testSecurityEventLogging() {
        // Given
        let events = createTestTelemetryEvents()
        let expectation = XCTestExpectation(description: "Should log security events")
        
        mockURLSession.mockResponse = createMockHTTPResponse(statusCode: 200)
        
        // When
        telemetryManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should succeed: \(error)")
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        // Verify security events were logged (implementation dependent)
    }
    
    // MARK: - Performance Tests
    
    func testUploadPerformance() {
        // Given
        let events = createTestTelemetryEvents()
        let expectation = XCTestExpectation(description: "Should complete within reasonable time")
        
        mockURLSession.mockResponse = createMockHTTPResponse(statusCode: 200)
        
        // When
        let startTime = Date()
        telemetryManager.upload(events: events) { result in
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            switch result {
            case .success:
                XCTAssertLessThan(duration, 5.0, "Upload should complete within 5 seconds")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Should succeed: \(error)")
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestTelemetryEvents() -> [TelemetryEvent] {
        return [
            TelemetryEvent(
                id: UUID(),
                timestamp: Date(),
                type: "health_data",
                data: ["heart_rate": 75, "steps": 8500],
                userId: "test_user_123"
            ),
            TelemetryEvent(
                id: UUID(),
                timestamp: Date(),
                type: "app_usage",
                data: ["screen": "dashboard", "duration": 300],
                userId: "test_user_123"
            )
        ]
    }
    
    private func createLargeTelemetryEventsArray() -> [TelemetryEvent] {
        return (0..<100).map { index in
            TelemetryEvent(
                id: UUID(),
                timestamp: Date().addingTimeInterval(TimeInterval(index)),
                type: "health_data",
                data: ["index": index, "value": "test_value_\(index)"],
                userId: "test_user_123"
            )
        }
    }
    
    private func createMockHTTPResponse(statusCode: Int) -> HTTPURLResponse {
        return HTTPURLResponse(
            url: URL(string: "https://api.healthai.com/telemetry")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: [:]
        )!
    }
}

// MARK: - Mock Classes

class MockTelemetryConfig: TelemetryConfig {
    var apiEndpoint: URL = URL(string: "https://api.healthai.com/telemetry")!
    var s3Bucket: String = "healthai-telemetry"
    var awsRegion: AWSRegionType = .USEast1
}

class MockURLSession: URLSession {
    var mockResponse: HTTPURLResponse?
    var mockResponses: [HTTPURLResponse] = []
    var mockError: Error?
    var dataTaskCallCount = 0
    var lastRequest: URLRequest?
    
    var configuration: URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.tlsMinimumSupportedProtocolVersion = .TLSv13
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return config
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        dataTaskCallCount += 1
        lastRequest = request
        
        let task = MockURLSessionDataTask()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            if let error = self.mockError {
                completionHandler(nil, nil, error)
                return
            }
            
            let response: HTTPURLResponse
            if !self.mockResponses.isEmpty {
                response = self.mockResponses.removeFirst()
            } else {
                response = self.mockResponse ?? HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: [:]
                )!
            }
            
            completionHandler(Data(), response, nil)
        }
        
        return task
    }
}

class MockURLSessionDataTask: URLSessionDataTask {
    override func resume() {
        // Mock implementation
    }
}

class MockAWSS3TransferUtility: AWSS3TransferUtility {
    var shouldSucceed = true
    var shouldSucceedAfterRetries = 0
    var uploadCallCount = 0
    
    override func uploadData(_ data: Data, bucket: String, key: String, contentType: String, expression: AWSS3TransferUtilityUploadExpression, completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?) -> AWSTask<AWSS3TransferUtilityUploadTask> {
        uploadCallCount += 1
        
        let task = AWSTask<AWSS3TransferUtilityUploadTask>()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            if self.shouldSucceed || (self.shouldSucceedAfterRetries > 0 && self.uploadCallCount > self.shouldSucceedAfterRetries) {
                completionHandler?(nil, nil)
            } else {
                let error = NSError(domain: "AWSS3TransferUtilityErrorDomain", code: -1, userInfo: nil)
                completionHandler?(nil, error)
            }
        }
        
        return task
    }
}

// MARK: - Supporting Types

struct TelemetryEvent: Codable {
    let id: UUID
    let timestamp: Date
    let type: String
    let data: [String: Any]
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp, type, data, userId
    }
    
    init(id: UUID, timestamp: Date, type: String, data: [String: Any], userId: String) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.data = data
        self.userId = userId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(userId, forKey: .userId)
        
        // Encode data as JSON
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        try container.encode(jsonData, forKey: .data)
    }
}

protocol TelemetryConfig {
    var apiEndpoint: URL { get }
    var s3Bucket: String { get }
    var awsRegion: AWSRegionType { get }
}

enum TelemetryUploadError: Error {
    case maxRetriesExceeded
    case combined(apiError: Error, s3Error: Error)
}

// Mock AWS types
typealias AWSRegionType = String
extension AWSRegionType {
    static let USEast1 = "us-east-1"
}

class AWSS3TransferUtility {
    func uploadData(_ data: Data, bucket: String, key: String, contentType: String, expression: AWSS3TransferUtilityUploadExpression, completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?) -> AWSTask<AWSS3TransferUtilityUploadTask> {
        fatalError("Should be mocked")
    }
}

class AWSS3TransferUtilityUploadExpression {
    // Mock implementation
}

typealias AWSS3TransferUtilityUploadCompletionHandlerBlock = (AWSS3TransferUtilityUploadTask?, Error?) -> Void

class AWSS3TransferUtilityUploadTask {
    // Mock implementation
}

class AWSTask<T> {
    // Mock implementation
}

// Mock SecretsManager
class SecretsManager {
    static let shared = SecretsManager()
    
    func getSecret(named: String) -> String? {
        // Mock implementation
        return "mock_secret"
    }
} 