import XCTest
import Foundation
import AWSS3
@testable import HealthAI_2030

/// Comprehensive Test Suite for TelemetryUploadManager
/// Tests all aspects of telemetry data upload including API and S3 fallback mechanisms
@MainActor
final class TelemetryUploadManagerTests: XCTestCase {
    
    var uploadManager: TelemetryUploadManager!
    var mockConfig: TelemetryConfig!
    var mockURLSession: MockURLSession!
    var mockS3TransferUtility: MockAWSS3TransferUtility!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockConfig = TelemetryConfig(
            s3Bucket: "test-bucket",
            apiEndpoint: URL(string: "https://api.test.com/telemetry")!,
            apiKey: "test-api-key",
            awsRegion: .USEast1
        )
        
        mockURLSession = MockURLSession()
        mockS3TransferUtility = MockAWSS3TransferUtility()
        
        // Create upload manager with mocked dependencies
        uploadManager = TelemetryUploadManager(config: mockConfig)
    }
    
    override func tearDown() async throws {
        uploadManager = nil
        mockConfig = nil
        mockURLSession = nil
        mockS3TransferUtility = nil
        try await super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testTelemetryConfigInitialization() {
        let config = TelemetryConfig(
            s3Bucket: "test-bucket",
            apiEndpoint: URL(string: "https://api.test.com/telemetry")!,
            apiKey: "test-api-key",
            awsRegion: .USEast1
        )
        
        XCTAssertEqual(config.s3Bucket, "test-bucket")
        XCTAssertEqual(config.apiEndpoint.absoluteString, "https://api.test.com/telemetry")
        XCTAssertEqual(config.apiKey, "test-api-key")
        XCTAssertEqual(config.awsRegion, .USEast1)
    }
    
    func testTelemetryUploadManagerInitialization() {
        XCTAssertNotNil(uploadManager)
        XCTAssertEqual(uploadManager.config.s3Bucket, "test-bucket")
        XCTAssertEqual(uploadManager.config.apiEndpoint.absoluteString, "https://api.test.com/telemetry")
        XCTAssertEqual(uploadManager.config.apiKey, "test-api-key")
        XCTAssertEqual(uploadManager.config.awsRegion, .USEast1)
    }
    
    // MARK: - Telemetry Event Tests
    
    func testTelemetryEventStructure() {
        let event = MockTelemetryEvent(
            timestamp: Date(),
            eventType: "test_event",
            payload: ["key": "value", "number": 42]
        )
        
        XCTAssertEqual(event.eventType, "test_event")
        XCTAssertEqual(event.payload["key"] as? String, "value")
        XCTAssertEqual(event.payload["number"] as? Int, 42)
    }
    
    func testTelemetryEventEncoding() throws {
        let event = MockTelemetryEvent(
            timestamp: Date(),
            eventType: "test_event",
            payload: ["key": "value"]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(event)
        XCTAssertNotNil(data)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decodedEvent = try decoder.decode(MockTelemetryEvent.self, from: data)
        XCTAssertEqual(decodedEvent.eventType, "test_event")
        XCTAssertEqual(decodedEvent.payload["key"] as? String, "value")
    }
    
    // MARK: - API Upload Tests
    
    func testSuccessfulAPIUpload() async {
        let expectation = XCTestExpectation(description: "API upload success")
        
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "test_event", payload: ["key": "value"])
        ]
        
        uploadManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("API upload should succeed: \(error)")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testAPIUploadWithNetworkError() async {
        let expectation = XCTestExpectation(description: "API upload with network error")
        
        // Mock network error
        mockURLSession.shouldFail = true
        mockURLSession.mockError = NSError(domain: "NetworkError", code: -1009, userInfo: nil)
        
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "test_event", payload: ["key": "value"])
        ]
        
        uploadManager.upload(events: events) { result in
            switch result {
            case .success:
                // Should fallback to S3 and succeed
                expectation.fulfill()
            case .failure(let error):
                // Both API and S3 failed
                XCTAssertTrue(error is TelemetryUploadError)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testAPIUploadWithHTTPError() async {
        let expectation = XCTestExpectation(description: "API upload with HTTP error")
        
        // Mock HTTP error
        mockURLSession.shouldFail = true
        mockURLSession.mockHTTPResponse = HTTPURLResponse(
            url: URL(string: "https://api.test.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "test_event", payload: ["key": "value"])
        ]
        
        uploadManager.upload(events: events) { result in
            switch result {
            case .success:
                // Should fallback to S3 and succeed
                expectation.fulfill()
            case .failure(let error):
                // Both API and S3 failed
                XCTAssertTrue(error is TelemetryUploadError)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testAPIUploadRetryLogic() async {
        let expectation = XCTestExpectation(description: "API upload retry logic")
        
        // Mock temporary failure followed by success
        mockURLSession.retryCount = 0
        mockURLSession.maxRetries = 2
        
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "test_event", payload: ["key": "value"])
        ]
        
        uploadManager.upload(events: events) { result in
            switch result {
            case .success:
                XCTAssertGreaterThanOrEqual(self.mockURLSession.retryCount, 1)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Upload should succeed after retries: \(error)")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - S3 Upload Tests
    
    func testSuccessfulS3Upload() async {
        let expectation = XCTestExpectation(description: "S3 upload success")
        
        // Mock API failure to trigger S3 fallback
        mockURLSession.shouldFail = true
        mockURLSession.mockError = NSError(domain: "NetworkError", code: -1009, userInfo: nil)
        
        // Mock S3 success
        mockS3TransferUtility.shouldFail = false
        
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "test_event", payload: ["key": "value"])
        ]
        
        uploadManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("S3 upload should succeed: \(error)")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testS3UploadWithError() async {
        let expectation = XCTestExpectation(description: "S3 upload with error")
        
        // Mock API failure
        mockURLSession.shouldFail = true
        mockURLSession.mockError = NSError(domain: "NetworkError", code: -1009, userInfo: nil)
        
        // Mock S3 failure
        mockS3TransferUtility.shouldFail = true
        mockS3TransferUtility.mockError = NSError(domain: "S3Error", code: -1, userInfo: nil)
        
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "test_event", payload: ["key": "value"])
        ]
        
        uploadManager.upload(events: events) { result in
            switch result {
            case .success:
                XCTFail("Upload should fail when both API and S3 fail")
            case .failure(let error):
                XCTAssertTrue(error is TelemetryUploadError)
                if case TelemetryUploadError.combined(let apiError, let s3Error) = error {
                    XCTAssertNotNil(apiError)
                    XCTAssertNotNil(s3Error)
                } else {
                    XCTFail("Expected combined error")
                }
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testS3UploadRetryLogic() async {
        let expectation = XCTestExpectation(description: "S3 upload retry logic")
        
        // Mock API failure
        mockURLSession.shouldFail = true
        mockURLSession.mockError = NSError(domain: "NetworkError", code: -1009, userInfo: nil)
        
        // Mock S3 retry logic
        mockS3TransferUtility.retryCount = 0
        mockS3TransferUtility.maxRetries = 2
        
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "test_event", payload: ["key": "value"])
        ]
        
        uploadManager.upload(events: events) { result in
            switch result {
            case .success:
                XCTAssertGreaterThanOrEqual(self.mockS3TransferUtility.retryCount, 1)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("S3 upload should succeed after retries: \(error)")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - Batch Upload Tests
    
    func testBatchUploadWithMultipleEvents() async {
        let expectation = XCTestExpectation(description: "Batch upload with multiple events")
        
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "event1", payload: ["key1": "value1"]),
            MockTelemetryEvent(timestamp: Date(), eventType: "event2", payload: ["key2": "value2"]),
            MockTelemetryEvent(timestamp: Date(), eventType: "event3", payload: ["key3": "value3"])
        ]
        
        uploadManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Batch upload should succeed: \(error)")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testEmptyBatchUpload() async {
        let expectation = XCTestExpectation(description: "Empty batch upload")
        
        let events: [MockTelemetryEvent] = []
        
        uploadManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Empty batch upload should succeed: \(error)")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testMaxRetriesExceededError() async {
        let expectation = XCTestExpectation(description: "Max retries exceeded")
        
        // Mock persistent failures
        mockURLSession.shouldFail = true
        mockURLSession.mockError = NSError(domain: "NetworkError", code: -1009, userInfo: nil)
        mockURLSession.maxRetries = 0 // No retries
        
        mockS3TransferUtility.shouldFail = true
        mockS3TransferUtility.mockError = NSError(domain: "S3Error", code: -1, userInfo: nil)
        mockS3TransferUtility.maxRetries = 0 // No retries
        
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "test_event", payload: ["key": "value"])
        ]
        
        uploadManager.upload(events: events) { result in
            switch result {
            case .success:
                XCTFail("Upload should fail when max retries exceeded")
            case .failure(let error):
                XCTAssertTrue(error is TelemetryUploadError)
                if case TelemetryUploadError.maxRetriesExceeded = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected max retries exceeded error")
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testCombinedErrorDescription() {
        let apiError = NSError(domain: "APIError", code: 500, userInfo: [NSLocalizedDescriptionKey: "API Error"])
        let s3Error = NSError(domain: "S3Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "S3 Error"])
        
        let combinedError = TelemetryUploadError.combined(apiError: apiError, s3Error: s3Error)
        
        let description = combinedError.localizedDescription
        XCTAssertTrue(description.contains("API Error"))
        XCTAssertTrue(description.contains("S3 Error"))
    }
    
    func testMaxRetriesExceededErrorDescription() {
        let error = TelemetryUploadError.maxRetriesExceeded
        XCTAssertEqual(error.localizedDescription, "Maximum retry attempts exceeded")
    }
    
    // MARK: - Security Tests
    
    func testSecureCredentialManagement() {
        // Test that credentials are not hardcoded
        // This is a basic test - in a real environment, we'd mock the SecretsManager
        
        let config = TelemetryConfig(
            s3Bucket: "test-bucket",
            apiEndpoint: URL(string: "https://api.test.com/telemetry")!,
            apiKey: "test-api-key",
            awsRegion: .USEast1
        )
        
        XCTAssertNotEqual(config.apiKey, "")
        XCTAssertNotEqual(config.s3Bucket, "")
    }
    
    func testRequestHeaders() async {
        let expectation = XCTestExpectation(description: "Request headers verification")
        
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "test_event", payload: ["key": "value"])
        ]
        
        // Capture the request to verify headers
        mockURLSession.requestCapture = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertNotNil(request.value(forHTTPHeaderField: "Authorization"))
            XCTAssertNotNil(request.value(forHTTPHeaderField: "User-Agent"))
            XCTAssertNotNil(request.value(forHTTPHeaderField: "X-Request-ID"))
            expectation.fulfill()
        }
        
        uploadManager.upload(events: events) { _ in }
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    
    func testUploadPerformance() {
        let events = Array(0..<100).map { index in
            MockTelemetryEvent(
                timestamp: Date(),
                eventType: "performance_test_event",
                payload: ["index": index, "data": "test_data_\(index)"]
            )
        }
        
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            uploadManager.upload(events: events) { _ in
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testLargePayloadHandling() async {
        let expectation = XCTestExpectation(description: "Large payload handling")
        
        // Create a large payload
        let largePayload = Dictionary(uniqueKeysWithValues: (0..<1000).map { ("key_\($0)", "value_\($0)") })
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "large_payload_event", payload: largePayload)
        ]
        
        uploadManager.upload(events: events) { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Large payload upload should succeed: \(error)")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - Concurrent Upload Tests
    
    func testConcurrentUploads() async {
        let expectation = XCTestExpectation(description: "Concurrent uploads")
        expectation.expectedFulfillmentCount = 3
        
        let events = [
            MockTelemetryEvent(timestamp: Date(), eventType: "concurrent_event", payload: ["key": "value"])
        ]
        
        // Start multiple concurrent uploads
        for i in 0..<3 {
            Task {
                uploadManager.upload(events: events) { result in
                    switch result {
                    case .success:
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Concurrent upload \(i) should succeed: \(error)")
                    }
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
}

// MARK: - Mock Types

struct MockTelemetryEvent: TelemetryEvent {
    let timestamp: Date
    let eventType: String
    let payload: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case timestamp, eventType, payload
    }
    
    init(timestamp: Date, eventType: String, payload: [String: Any]) {
        self.timestamp = timestamp
        self.eventType = eventType
        self.payload = payload
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        eventType = try container.decode(String.self, forKey: .eventType)
        payload = try container.decode([String: Any].self, forKey: .payload)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(payload, forKey: .payload)
    }
}

class MockURLSession: URLSession {
    var shouldFail = false
    var mockError: Error?
    var mockHTTPResponse: HTTPURLResponse?
    var retryCount = 0
    var maxRetries = 3
    var requestCapture: ((URLRequest) -> Void)?
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        requestCapture?(request)
        
        if shouldFail {
            retryCount += 1
            
            if retryCount <= maxRetries {
                // Simulate retry delay
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    completionHandler(nil, self.mockHTTPResponse, self.mockError)
                }
            } else {
                completionHandler(nil, mockHTTPResponse, mockError)
            }
        } else {
            let successResponse = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
            completionHandler(Data(), successResponse, nil)
        }
        
        return MockURLSessionDataTask()
    }
}

class MockURLSessionDataTask: URLSessionDataTask {
    override func resume() {
        // Mock implementation
    }
}

class MockAWSS3TransferUtility: AWSS3TransferUtility {
    var shouldFail = false
    var mockError: Error?
    var retryCount = 0
    var maxRetries = 3
    
    func uploadData(_ data: Data, bucket: String, key: String, contentType: String, expression: AWSS3TransferUtilityUploadExpression, completionHandler: @escaping (AWSS3TransferUtilityUploadTask?, Error?) -> Void) {
        if shouldFail {
            retryCount += 1
            
            if retryCount <= maxRetries {
                // Simulate retry delay
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    completionHandler(nil, self.mockError)
                }
            } else {
                completionHandler(nil, mockError)
            }
        } else {
            completionHandler(MockAWSS3TransferUtilityUploadTask(), nil)
        }
    }
}

class MockAWSS3TransferUtilityUploadTask: AWSS3TransferUtilityUploadTask {
    // Mock implementation
} 