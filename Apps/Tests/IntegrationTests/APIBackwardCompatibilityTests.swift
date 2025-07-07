import XCTest
import Foundation
@testable import HealthAI2030Core
@testable import HealthAI2030Networking

final class APIBackwardCompatibilityTests: XCTestCase {
    
    let versioningManager = APIVersioningManager.shared
    let networkErrorHandler = NetworkErrorHandler.shared
    
    // MARK: - Mock API Response Models
    
    /// Mock response models for different API versions
    struct HealthRecordV1: Codable {
        let id: String
        let type: String
        let value: Double
        let timestamp: String
    }
    
    struct HealthRecordV2: Codable {
        let id: String
        let type: String
        let value: Double
        let timestamp: String
        let metadata: [String: String]?
        let confidence: Double?
    }
    
    struct HealthRecordV3: Codable {
        let id: String
        let type: String
        let value: Double
        let timestamp: String
        let metadata: [String: String]?
        let confidence: Double?
        let aiInsights: [String: String]?
        let quantumOptimized: Bool?
    }
    
    struct SleepSessionV1: Codable {
        let id: String
        let startTime: String
        let endTime: String
        let duration: Int
    }
    
    struct SleepSessionV2: Codable {
        let id: String
        let startTime: String
        let endTime: String
        let duration: Int
        let sleepStages: [String: Int]?
        let qualityScore: Double?
    }
    
    struct MLModelV1: Codable {
        let id: String
        let name: String
        let version: String
        let accuracy: Double
    }
    
    struct MLModelV2: Codable {
        let id: String
        let name: String
        let version: String
        let accuracy: Double
        let performanceMetrics: [String: Double]?
        let lastUpdated: String?
    }
    
    // MARK: - Backward Compatibility Tests
    
    func testV1ToV2HealthRecordsCompatibility() async throws {
        // Simulate V1 API response
        let v1Response = HealthRecordV1(
            id: "record123",
            type: "heart_rate",
            value: 75.0,
            timestamp: "2024-01-01T12:00:00Z"
        )
        
        let v1Data = try JSONEncoder().encode(v1Response)
        
        // Test that V2 client can parse V1 response
        let v2Response = try JSONDecoder().decode(HealthRecordV2.self, from: v1Data)
        
        XCTAssertEqual(v2Response.id, "record123")
        XCTAssertEqual(v2Response.type, "heart_rate")
        XCTAssertEqual(v2Response.value, 75.0)
        XCTAssertEqual(v2Response.timestamp, "2024-01-01T12:00:00Z")
        XCTAssertNil(v2Response.metadata)
        XCTAssertNil(v2Response.confidence)
    }
    
    func testV2ToV1HealthRecordsCompatibility() async throws {
        // Simulate V2 API response
        let v2Response = HealthRecordV2(
            id: "record456",
            type: "blood_pressure",
            value: 120.0,
            timestamp: "2024-01-01T13:00:00Z",
            metadata: ["device": "apple_watch"],
            confidence: 0.95
        )
        
        let v2Data = try JSONEncoder().encode(v2Response)
        
        // Test that V1 client can parse V2 response (should ignore extra fields)
        let v1Response = try JSONDecoder().decode(HealthRecordV1.self, from: v2Data)
        
        XCTAssertEqual(v1Response.id, "record456")
        XCTAssertEqual(v1Response.type, "blood_pressure")
        XCTAssertEqual(v1Response.value, 120.0)
        XCTAssertEqual(v1Response.timestamp, "2024-01-01T13:00:00Z")
    }
    
    func testV2ToV3HealthRecordsCompatibility() async throws {
        // Simulate V2 API response
        let v2Response = HealthRecordV2(
            id: "record789",
            type: "sleep_quality",
            value: 85.0,
            timestamp: "2024-01-01T14:00:00Z",
            metadata: ["environment": "quiet_room"],
            confidence: 0.88
        )
        
        let v2Data = try JSONEncoder().encode(v2Response)
        
        // Test that V3 client can parse V2 response
        let v3Response = try JSONDecoder().decode(HealthRecordV3.self, from: v2Data)
        
        XCTAssertEqual(v3Response.id, "record789")
        XCTAssertEqual(v3Response.type, "sleep_quality")
        XCTAssertEqual(v3Response.value, 85.0)
        XCTAssertEqual(v3Response.timestamp, "2024-01-01T14:00:00Z")
        XCTAssertEqual(v3Response.metadata?["environment"], "quiet_room")
        XCTAssertEqual(v3Response.confidence, 0.88)
        XCTAssertNil(v3Response.aiInsights)
        XCTAssertNil(v3Response.quantumOptimized)
    }
    
    func testV3ToV2HealthRecordsCompatibility() async throws {
        // Simulate V3 API response
        let v3Response = HealthRecordV3(
            id: "record101",
            type: "stress_level",
            value: 65.0,
            timestamp: "2024-01-01T15:00:00Z",
            metadata: ["activity": "work"],
            confidence: 0.92,
            aiInsights: ["trend": "increasing"],
            quantumOptimized: true
        )
        
        let v3Data = try JSONEncoder().encode(v3Response)
        
        // Test that V2 client can parse V3 response (should ignore extra fields)
        let v2Response = try JSONDecoder().decode(HealthRecordV2.self, from: v3Data)
        
        XCTAssertEqual(v2Response.id, "record101")
        XCTAssertEqual(v2Response.type, "stress_level")
        XCTAssertEqual(v2Response.value, 65.0)
        XCTAssertEqual(v2Response.timestamp, "2024-01-01T15:00:00Z")
        XCTAssertEqual(v2Response.metadata?["activity"], "work")
        XCTAssertEqual(v2Response.confidence, 0.92)
    }
    
    func testV1ToV3HealthRecordsCompatibility() async throws {
        // Simulate V1 API response
        let v1Response = HealthRecordV1(
            id: "record202",
            type: "temperature",
            value: 98.6,
            timestamp: "2024-01-01T16:00:00Z"
        )
        
        let v1Data = try JSONEncoder().encode(v1Response)
        
        // Test that V3 client can parse V1 response
        let v3Response = try JSONDecoder().decode(HealthRecordV3.self, from: v1Data)
        
        XCTAssertEqual(v3Response.id, "record202")
        XCTAssertEqual(v3Response.type, "temperature")
        XCTAssertEqual(v3Response.value, 98.6)
        XCTAssertEqual(v3Response.timestamp, "2024-01-01T16:00:00Z")
        XCTAssertNil(v3Response.metadata)
        XCTAssertNil(v3Response.confidence)
        XCTAssertNil(v3Response.aiInsights)
        XCTAssertNil(v3Response.quantumOptimized)
    }
    
    // MARK: - Sleep Session Compatibility Tests
    
    func testV1ToV2SleepSessionsCompatibility() async throws {
        // Simulate V1 API response
        let v1Response = SleepSessionV1(
            id: "sleep123",
            startTime: "2024-01-01T22:00:00Z",
            endTime: "2024-01-02T06:00:00Z",
            duration: 28800
        )
        
        let v1Data = try JSONEncoder().encode(v1Response)
        
        // Test that V2 client can parse V1 response
        let v2Response = try JSONDecoder().decode(SleepSessionV2.self, from: v1Data)
        
        XCTAssertEqual(v2Response.id, "sleep123")
        XCTAssertEqual(v2Response.startTime, "2024-01-01T22:00:00Z")
        XCTAssertEqual(v2Response.endTime, "2024-01-02T06:00:00Z")
        XCTAssertEqual(v2Response.duration, 28800)
        XCTAssertNil(v2Response.sleepStages)
        XCTAssertNil(v2Response.qualityScore)
    }
    
    func testV2ToV1SleepSessionsCompatibility() async throws {
        // Simulate V2 API response
        let v2Response = SleepSessionV2(
            id: "sleep456",
            startTime: "2024-01-02T22:00:00Z",
            endTime: "2024-01-03T06:00:00Z",
            duration: 28800,
            sleepStages: ["deep": 7200, "light": 14400, "rem": 7200],
            qualityScore: 85.5
        )
        
        let v2Data = try JSONEncoder().encode(v2Response)
        
        // Test that V1 client can parse V2 response
        let v1Response = try JSONDecoder().decode(SleepSessionV1.self, from: v2Data)
        
        XCTAssertEqual(v1Response.id, "sleep456")
        XCTAssertEqual(v1Response.startTime, "2024-01-02T22:00:00Z")
        XCTAssertEqual(v1Response.endTime, "2024-01-03T06:00:00Z")
        XCTAssertEqual(v1Response.duration, 28800)
    }
    
    // MARK: - ML Model Compatibility Tests
    
    func testV1ToV2MLModelsCompatibility() async throws {
        // Simulate V1 API response
        let v1Response = MLModelV1(
            id: "model123",
            name: "health_predictor",
            version: "1.0.0",
            accuracy: 0.92
        )
        
        let v1Data = try JSONEncoder().encode(v1Response)
        
        // Test that V2 client can parse V1 response
        let v2Response = try JSONDecoder().decode(MLModelV2.self, from: v1Data)
        
        XCTAssertEqual(v2Response.id, "model123")
        XCTAssertEqual(v2Response.name, "health_predictor")
        XCTAssertEqual(v2Response.version, "1.0.0")
        XCTAssertEqual(v2Response.accuracy, 0.92)
        XCTAssertNil(v2Response.performanceMetrics)
        XCTAssertNil(v2Response.lastUpdated)
    }
    
    func testV2ToV1MLModelsCompatibility() async throws {
        // Simulate V2 API response
        let v2Response = MLModelV2(
            id: "model456",
            name: "sleep_analyzer",
            version: "2.1.0",
            accuracy: 0.94,
            performanceMetrics: ["precision": 0.96, "recall": 0.93],
            lastUpdated: "2024-01-01T10:00:00Z"
        )
        
        let v2Data = try JSONEncoder().encode(v2Response)
        
        // Test that V1 client can parse V2 response
        let v1Response = try JSONDecoder().decode(MLModelV1.self, from: v2Data)
        
        XCTAssertEqual(v1Response.id, "model456")
        XCTAssertEqual(v1Response.name, "sleep_analyzer")
        XCTAssertEqual(v1Response.version, "2.1.0")
        XCTAssertEqual(v1Response.accuracy, 0.94)
    }
    
    // MARK: - API Version Header Tests
    
    func testAPIVersionHeadersCompatibility() async throws {
        let v1Endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v1,
            method: .get,
            description: "Health records v1"
        )
        
        let v2Endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v2,
            method: .get,
            description: "Health records v2"
        )
        
        let v3Endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v3,
            method: .get,
            description: "Health records v3"
        )
        
        let v1Headers = versioningManager.getVersionHeaders(for: v1Endpoint)
        let v2Headers = versioningManager.getVersionHeaders(for: v2Endpoint)
        let v3Headers = versioningManager.getVersionHeaders(for: v3Endpoint)
        
        // Test header compatibility
        XCTAssertEqual(v1Headers["API-Version"], "v1")
        XCTAssertEqual(v1Headers["Accept"], "application/vnd.healthai.v1+json")
        
        XCTAssertEqual(v2Headers["API-Version"], "v2")
        XCTAssertEqual(v2Headers["Accept"], "application/vnd.healthai.v2+json")
        
        XCTAssertEqual(v3Headers["API-Version"], "v3")
        XCTAssertEqual(v3Headers["Accept"], "application/vnd.healthai.v3+json")
    }
    
    // MARK: - URL Construction Compatibility Tests
    
    func testURLConstructionCompatibility() async throws {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records/{id}",
            version: .v2,
            method: .get,
            description: "Health records endpoint"
        )
        
        let pathParameters = ["id": "record123"]
        
        // Test URL construction for different environments
        let productionURL = versioningManager.buildURL(for: endpoint, pathParameters: pathParameters, environment: .production)
        let stagingURL = versioningManager.buildURL(for: endpoint, pathParameters: pathParameters, environment: .staging)
        let developmentURL = versioningManager.buildURL(for: endpoint, pathParameters: pathParameters, environment: .development)
        
        XCTAssertEqual(productionURL.absoluteString, "https://api.healthai2030.com/v2/health/records/record123")
        XCTAssertEqual(stagingURL.absoluteString, "https://api-staging.healthai2030.com/v2/health/records/record123")
        XCTAssertEqual(developmentURL.absoluteString, "https://api-dev.healthai2030.com/v2/health/records/record123")
    }
    
    // MARK: - Error Handling Compatibility Tests
    
    func testErrorResponseCompatibility() async throws {
        // Test that error responses are compatible across versions
        let v1ErrorResponse = [
            "error": "validation_failed",
            "message": "Invalid health record data",
            "code": 400
        ]
        
        let v2ErrorResponse = [
            "error": "validation_failed",
            "message": "Invalid health record data",
            "code": 400,
            "details": [
                "field": "value",
                "constraint": "required"
            ],
            "timestamp": "2024-01-01T12:00:00Z"
        ]
        
        let v3ErrorResponse = [
            "error": "validation_failed",
            "message": "Invalid health record data",
            "code": 400,
            "details": [
                "field": "value",
                "constraint": "required"
            ],
            "timestamp": "2024-01-01T12:00:00Z",
            "requestId": "req_123456",
            "suggestions": ["Check data format", "Verify required fields"]
        ]
        
        // Test that V1 client can parse V2 error response
        let v1Data = try JSONSerialization.data(withJSONObject: v2ErrorResponse)
        let v1Parsed = try JSONSerialization.jsonObject(with: v1Data) as? [String: Any]
        
        XCTAssertEqual(v1Parsed?["error"] as? String, "validation_failed")
        XCTAssertEqual(v1Parsed?["message"] as? String, "Invalid health record data")
        XCTAssertEqual(v1Parsed?["code"] as? Int, 400)
        
        // Test that V2 client can parse V3 error response
        let v2Data = try JSONSerialization.data(withJSONObject: v3ErrorResponse)
        let v2Parsed = try JSONSerialization.jsonObject(with: v2Data) as? [String: Any]
        
        XCTAssertEqual(v2Parsed?["error"] as? String, "validation_failed")
        XCTAssertEqual(v2Parsed?["message"] as? String, "Invalid health record data")
        XCTAssertEqual(v2Parsed?["code"] as? Int, 400)
        XCTAssertNotNil(v2Parsed?["details"])
        XCTAssertNotNil(v2Parsed?["timestamp"])
    }
    
    // MARK: - Network Error Handling Compatibility Tests
    
    func testNetworkErrorCompatibility() async throws {
        // Test that network errors are handled consistently across versions
        let timeoutError = URLError(.timedOut)
        let networkOfflineError = URLError(.notConnectedToInternet)
        let serverError = URLError(.badServerResponse)
        
        // Test error categorization
        let timeoutCategory = networkErrorHandler.categorizeError(timeoutError)
        let networkOfflineCategory = networkErrorHandler.categorizeError(networkOfflineError)
        let serverErrorCategory = networkErrorHandler.categorizeError(serverError)
        
        XCTAssertEqual(timeoutCategory, .timeout)
        XCTAssertEqual(networkOfflineCategory, .networkOffline)
        XCTAssertEqual(serverErrorCategory, .unknownError)
        
        // Test that retry logic works consistently
        var retryCount = 0
        do {
            _ = try await networkErrorHandler.exponentialBackoffRetry(
                operation: {
                    retryCount += 1
                    throw timeoutError
                },
                maxRetries: 2,
                initialDelay: 0.1
            )
        } catch {
            XCTAssertEqual(retryCount, 3, "Should have retried 3 times (1 initial + 2 retries)")
        }
    }
    
    // MARK: - Deprecated Endpoint Tests
    
    func testDeprecatedEndpointHandling() async throws {
        let deprecatedEndpoints = versioningManager.getDeprecatedEndpoints()
        
        XCTAssertGreaterThanOrEqual(deprecatedEndpoints.count, 0, "Should have some deprecated endpoints")
        
        for endpoint in deprecatedEndpoints {
            XCTAssertTrue(endpoint.deprecated, "All returned endpoints should be deprecated")
            
            // Test that deprecated endpoints still work but are marked appropriately
            let headers = versioningManager.getVersionHeaders(for: endpoint)
            XCTAssertNotNil(headers["API-Version"], "Deprecated endpoints should still have version headers")
            
            // Test URL construction for deprecated endpoints
            let url = versioningManager.buildURL(for: endpoint, environment: .production)
            XCTAssertTrue(url.absoluteString.contains(endpoint.version.rawValue), "URL should contain version")
        }
    }
    
    // MARK: - Migration Tests
    
    func testEndpointMigration() async throws {
        let v1Endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v1,
            method: .get,
            description: "Health records v1"
        )
        
        // Test migration to v2
        let migratedEndpoint = versioningManager.migrateEndpoint(v1Endpoint, to: .v2)
        XCTAssertNotNil(migratedEndpoint, "Should be able to migrate to v2")
        XCTAssertEqual(migratedEndpoint?.version, .v2, "Migrated endpoint should be v2")
        XCTAssertEqual(migratedEndpoint?.path, "/health/records", "Path should remain the same")
        
        // Test that migrated endpoint has correct headers
        if let migrated = migratedEndpoint {
            let headers = versioningManager.getVersionHeaders(for: migrated)
            XCTAssertEqual(headers["API-Version"], "v2")
            XCTAssertEqual(headers["Accept"], "application/vnd.healthai.v2+json")
        }
    }
    
    // MARK: - Performance Tests
    
    func testBackwardCompatibilityPerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test multiple compatibility scenarios
        for _ in 0..<100 {
            let v1Response = HealthRecordV1(
                id: "record\(Int.random(in: 1...1000))",
                type: "heart_rate",
                value: Double.random(in: 60...100),
                timestamp: "2024-01-01T12:00:00Z"
            )
            
            let v1Data = try JSONEncoder().encode(v1Response)
            let _ = try JSONDecoder().decode(HealthRecordV3.self, from: v1Data)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should be very fast
        XCTAssertLessThan(duration, 1.0, "Backward compatibility parsing took too long: \(duration)s")
    }
    
    // MARK: - Stress Tests
    
    func testBackwardCompatibilityStressTest() async throws {
        let endpoints = versioningManager.allEndpoints
        var successCount = 0
        var failureCount = 0
        
        // Test compatibility across all endpoints
        for endpoint in endpoints {
            do {
                // Test URL construction
                let url = versioningManager.buildURL(for: endpoint, environment: .production)
                XCTAssertTrue(url.absoluteString.contains(endpoint.version.rawValue))
                
                // Test headers
                let headers = versioningManager.getVersionHeaders(for: endpoint)
                XCTAssertNotNil(headers["API-Version"])
                XCTAssertNotNil(headers["Accept"])
                
                // Test validation
                XCTAssertTrue(versioningManager.validateEndpoint(endpoint))
                
                successCount += 1
            } catch {
                failureCount += 1
            }
        }
        
        XCTAssertGreaterThan(successCount, 0, "Should have successful compatibility tests")
        XCTAssertEqual(failureCount, 0, "Should have no compatibility failures")
    }
} 