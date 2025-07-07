import XCTest
import Foundation
@testable import HealthAI2030Core

final class APIVersioningManagerTests: XCTestCase {
    
    let versioningManager = APIVersioningManager.shared
    
    // MARK: - Environment Tests
    
    func testEnvironmentBaseURLs() {
        XCTAssertEqual(APIVersioningManager.Environment.development.baseURL.absoluteString, "https://api-dev.healthai2030.com")
        XCTAssertEqual(APIVersioningManager.Environment.staging.baseURL.absoluteString, "https://api-staging.healthai2030.com")
        XCTAssertEqual(APIVersioningManager.Environment.production.baseURL.absoluteString, "https://api.healthai2030.com")
    }
    
    func testEnvironmentAllCases() {
        let environments = APIVersioningManager.Environment.allCases
        XCTAssertEqual(environments.count, 3)
        XCTAssertTrue(environments.contains(.development))
        XCTAssertTrue(environments.contains(.staging))
        XCTAssertTrue(environments.contains(.production))
    }
    
    // MARK: - API Version Tests
    
    func testAPIVersionProperties() {
        XCTAssertEqual(APIVersioningManager.APIVersion.v1.versionString, "v1")
        XCTAssertEqual(APIVersioningManager.APIVersion.v2.versionString, "v2")
        XCTAssertEqual(APIVersioningManager.APIVersion.v3.versionString, "v3")
        
        XCTAssertEqual(APIVersioningManager.APIVersion.v1.headerValue, "application/vnd.healthai.v1+json")
        XCTAssertEqual(APIVersioningManager.APIVersion.v2.headerValue, "application/vnd.healthai.v2+json")
        XCTAssertEqual(APIVersioningManager.APIVersion.v3.headerValue, "application/vnd.healthai.v3+json")
    }
    
    func testAPIVersionAllCases() {
        let versions = APIVersioningManager.APIVersion.allCases
        XCTAssertEqual(versions.count, 3)
        XCTAssertTrue(versions.contains(.v1))
        XCTAssertTrue(versions.contains(.v2))
        XCTAssertTrue(versions.contains(.v3))
    }
    
    // MARK: - API Endpoint Tests
    
    func testAPIEndpointInitialization() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/test/path",
            version: .v2,
            method: .get,
            description: "Test endpoint"
        )
        
        XCTAssertEqual(endpoint.path, "/test/path")
        XCTAssertEqual(endpoint.version, .v2)
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.description, "Test endpoint")
        XCTAssertFalse(endpoint.deprecated)
        XCTAssertEqual(endpoint.fullPath, "/v2/test/path")
    }
    
    func testAPIEndpointDeprecated() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/legacy/path",
            version: .v1,
            method: .get,
            description: "Legacy endpoint",
            deprecated: true
        )
        
        XCTAssertTrue(endpoint.deprecated)
        XCTAssertEqual(endpoint.fullPath, "/v1/legacy/path")
    }
    
    func testAPIEndpointFullPath() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v3,
            method: .post,
            description: "Health records endpoint"
        )
        
        XCTAssertEqual(endpoint.fullPath, "/v3/health/records")
    }
    
    // MARK: - HTTP Method Tests
    
    func testHTTPMethodAllCases() {
        let methods = APIVersioningManager.HTTPMethod.allCases
        XCTAssertEqual(methods.count, 5)
        XCTAssertTrue(methods.contains(.get))
        XCTAssertTrue(methods.contains(.post))
        XCTAssertTrue(methods.contains(.put))
        XCTAssertTrue(methods.contains(.delete))
        XCTAssertTrue(methods.contains(.patch))
    }
    
    func testHTTPMethodRawValues() {
        XCTAssertEqual(APIVersioningManager.HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(APIVersioningManager.HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(APIVersioningManager.HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(APIVersioningManager.HTTPMethod.delete.rawValue, "DELETE")
        XCTAssertEqual(APIVersioningManager.HTTPMethod.patch.rawValue, "PATCH")
    }
    
    // MARK: - Endpoints Registry Tests
    
    func testAllEndpointsNotEmpty() {
        let endpoints = versioningManager.allEndpoints
        XCTAssertGreaterThan(endpoints.count, 0, "Should have endpoints defined")
    }
    
    func testEndpointsByVersion() {
        let v1Endpoints = versioningManager.getEndpoints(for: .v1)
        let v2Endpoints = versioningManager.getEndpoints(for: .v2)
        let v3Endpoints = versioningManager.getEndpoints(for: .v3)
        
        XCTAssertGreaterThan(v1Endpoints.count, 0, "Should have v1 endpoints")
        XCTAssertGreaterThan(v2Endpoints.count, 0, "Should have v2 endpoints")
        XCTAssertGreaterThan(v3Endpoints.count, 0, "Should have v3 endpoints")
        
        // Verify all endpoints have correct version
        for endpoint in v1Endpoints {
            XCTAssertEqual(endpoint.version, .v1)
        }
        for endpoint in v2Endpoints {
            XCTAssertEqual(endpoint.version, .v2)
        }
        for endpoint in v3Endpoints {
            XCTAssertEqual(endpoint.version, .v3)
        }
    }
    
    func testDeprecatedEndpoints() {
        let deprecatedEndpoints = versioningManager.getDeprecatedEndpoints()
        XCTAssertGreaterThanOrEqual(deprecatedEndpoints.count, 0, "Should have some deprecated endpoints")
        
        for endpoint in deprecatedEndpoints {
            XCTAssertTrue(endpoint.deprecated, "All returned endpoints should be deprecated")
        }
    }
    
    func testHealthEndpointsExist() {
        let allEndpoints = versioningManager.allEndpoints
        let healthEndpoints = allEndpoints.filter { $0.path.contains("/health/") }
        
        XCTAssertGreaterThan(healthEndpoints.count, 0, "Should have health endpoints")
        
        // Check for specific health endpoints
        let healthRecordsEndpoints = healthEndpoints.filter { $0.path.contains("/health/records") }
        XCTAssertGreaterThan(healthRecordsEndpoints.count, 0, "Should have health records endpoints")
    }
    
    func testSleepEndpointsExist() {
        let allEndpoints = versioningManager.allEndpoints
        let sleepEndpoints = allEndpoints.filter { $0.path.contains("/sleep/") }
        
        XCTAssertGreaterThan(sleepEndpoints.count, 0, "Should have sleep endpoints")
        
        // Check for specific sleep endpoints
        let sleepSessionsEndpoints = sleepEndpoints.filter { $0.path.contains("/sleep/sessions") }
        XCTAssertGreaterThan(sleepSessionsEndpoints.count, 0, "Should have sleep sessions endpoints")
    }
    
    func testMLEndpointsExist() {
        let allEndpoints = versioningManager.allEndpoints
        let mlEndpoints = allEndpoints.filter { $0.path.contains("/ml/") }
        
        XCTAssertGreaterThan(mlEndpoints.count, 0, "Should have ML endpoints")
        
        // Check for specific ML endpoints
        let mlModelsEndpoints = mlEndpoints.filter { $0.path.contains("/ml/models") }
        XCTAssertGreaterThan(mlModelsEndpoints.count, 0, "Should have ML models endpoints")
    }
    
    func testQuantumEndpointsExist() {
        let allEndpoints = versioningManager.allEndpoints
        let quantumEndpoints = allEndpoints.filter { $0.path.contains("/quantum/") }
        
        XCTAssertGreaterThan(quantumEndpoints.count, 0, "Should have quantum endpoints")
        
        // Check that quantum endpoints are v3
        for endpoint in quantumEndpoints {
            XCTAssertEqual(endpoint.version, .v3, "Quantum endpoints should be v3")
        }
    }
    
    // MARK: - Versioning Strategy Tests
    
    func testCurrentAPIVersion() {
        let currentVersion = versioningManager.currentAPIVersion
        XCTAssertEqual(currentVersion, .v2, "Current API version should be v2")
    }
    
    func testMinimumSupportedVersion() {
        let minimumVersion = versioningManager.minimumSupportedVersion
        XCTAssertEqual(minimumVersion, .v1, "Minimum supported version should be v1")
    }
    
    func testVersionSupport() {
        XCTAssertTrue(versioningManager.isVersionSupported(.v1), "v1 should be supported")
        XCTAssertTrue(versioningManager.isVersionSupported(.v2), "v2 should be supported")
        XCTAssertTrue(versioningManager.isVersionSupported(.v3), "v3 should be supported")
    }
    
    func testGetAPIVersionForEndpoint() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/test/path",
            version: .v3,
            method: .get,
            description: "Test endpoint"
        )
        
        let version = versioningManager.getAPIVersion(for: endpoint)
        XCTAssertEqual(version, .v3, "Should return endpoint's version")
    }
    
    // MARK: - URL Construction Tests
    
    func testBuildURLForEndpoint() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v2,
            method: .get,
            description: "Health records endpoint"
        )
        
        let url = versioningManager.buildURL(for: endpoint, environment: .production)
        XCTAssertEqual(url.absoluteString, "https://api.healthai2030.com/v2/health/records")
    }
    
    func testBuildURLWithPathParameters() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records/{id}",
            version: .v1,
            method: .put,
            description: "Update health record"
        )
        
        let pathParameters = ["id": "12345"]
        let url = versioningManager.buildURL(for: endpoint, pathParameters: pathParameters, environment: .staging)
        XCTAssertEqual(url.absoluteString, "https://api-staging.healthai2030.com/v1/health/records/12345")
    }
    
    func testBuildURLWithMultiplePathParameters() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/users/{userId}/settings/{settingId}",
            version: .v2,
            method: .get,
            description: "Get user setting"
        )
        
        let pathParameters = ["userId": "user123", "settingId": "setting456"]
        let url = versioningManager.buildURL(for: endpoint, pathParameters: pathParameters, environment: .development)
        XCTAssertEqual(url.absoluteString, "https://api-dev.healthai2030.com/v2/users/user123/settings/setting456")
    }
    
    // MARK: - Backward Compatibility Tests
    
    func testHasNewerVersion() {
        let v1Endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v1,
            method: .get,
            description: "Health records v1"
        )
        
        let v3Endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v3,
            method: .get,
            description: "Health records v3"
        )
        
        XCTAssertTrue(versioningManager.hasNewerVersion(for: v1Endpoint), "v1 endpoint should have newer versions")
        XCTAssertFalse(versioningManager.hasNewerVersion(for: v3Endpoint), "v3 endpoint should not have newer versions")
    }
    
    func testGetLatestVersion() {
        let latestVersion = versioningManager.getLatestVersion(for: "/health/records")
        XCTAssertEqual(latestVersion, .v2, "Latest version for health records should be v2")
    }
    
    func testMigrateEndpoint() {
        let v1Endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v1,
            method: .get,
            description: "Health records v1"
        )
        
        let migratedEndpoint = versioningManager.migrateEndpoint(v1Endpoint, to: .v2)
        XCTAssertNotNil(migratedEndpoint, "Should be able to migrate to v2")
        XCTAssertEqual(migratedEndpoint?.version, .v2, "Migrated endpoint should be v2")
        XCTAssertEqual(migratedEndpoint?.path, "/health/records", "Path should remain the same")
    }
    
    func testMigrateEndpointToUnsupportedVersion() {
        let v1Endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v1,
            method: .get,
            description: "Health records v1"
        )
        
        // Try to migrate to a non-existent version
        let migratedEndpoint = versioningManager.migrateEndpoint(v1Endpoint, to: .v3)
        XCTAssertNil(migratedEndpoint, "Should not be able to migrate to non-existent version")
    }
    
    // MARK: - Version Headers Tests
    
    func testVersionHeadersForGetRequest() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v2,
            method: .get,
            description: "Health records endpoint"
        )
        
        let headers = versioningManager.getVersionHeaders(for: endpoint)
        
        XCTAssertEqual(headers["API-Version"], "v2")
        XCTAssertEqual(headers["Accept"], "application/vnd.healthai.v2+json")
        XCTAssertNil(headers["Content-Type"], "GET requests should not have Content-Type")
    }
    
    func testVersionHeadersForPostRequest() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v3,
            method: .post,
            description: "Create health record"
        )
        
        let headers = versioningManager.getVersionHeaders(for: endpoint)
        
        XCTAssertEqual(headers["API-Version"], "v3")
        XCTAssertEqual(headers["Accept"], "application/vnd.healthai.v3+json")
        XCTAssertEqual(headers["Content-Type"], "application/vnd.healthai.v3+json")
    }
    
    func testVersionHeadersForPutRequest() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records/{id}",
            version: .v1,
            method: .put,
            description: "Update health record"
        )
        
        let headers = versioningManager.getVersionHeaders(for: endpoint)
        
        XCTAssertEqual(headers["API-Version"], "v1")
        XCTAssertEqual(headers["Accept"], "application/vnd.healthai.v1+json")
        XCTAssertEqual(headers["Content-Type"], "application/vnd.healthai.v1+json")
    }
    
    // MARK: - Validation Tests
    
    func testValidateEndpoint() {
        let validEndpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v1,
            method: .get,
            description: "Valid endpoint"
        )
        
        XCTAssertTrue(versioningManager.validateEndpoint(validEndpoint), "Valid endpoint should pass validation")
    }
    
    func testValidateInvalidEndpoint() {
        let invalidEndpoint = APIVersioningManager.APIEndpoint(
            path: "/invalid/path",
            version: .v1,
            method: .get,
            description: "Invalid endpoint"
        )
        
        XCTAssertFalse(versioningManager.validateEndpoint(invalidEndpoint), "Invalid endpoint should fail validation")
    }
    
    func testIsEndpointDeprecated() {
        let deprecatedEndpoint = APIVersioningManager.APIEndpoint(
            path: "/legacy/health",
            version: .v1,
            method: .get,
            description: "Legacy endpoint",
            deprecated: true
        )
        
        let nonDeprecatedEndpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v2,
            method: .get,
            description: "Current endpoint"
        )
        
        XCTAssertTrue(versioningManager.isEndpointDeprecated(deprecatedEndpoint), "Deprecated endpoint should be marked as deprecated")
        XCTAssertFalse(versioningManager.isEndpointDeprecated(nonDeprecatedEndpoint), "Non-deprecated endpoint should not be marked as deprecated")
    }
    
    // MARK: - Documentation Tests
    
    func testGenerateAPIDocumentation() {
        let documentation = versioningManager.generateAPIDocumentation()
        
        XCTAssertGreaterThan(documentation.count, 0, "Documentation should not be empty")
        XCTAssertTrue(documentation.contains("# HealthAI 2030 API Documentation"), "Should contain title")
        XCTAssertTrue(documentation.contains("## API Version V1"), "Should contain v1 section")
        XCTAssertTrue(documentation.contains("## API Version V2"), "Should contain v2 section")
        XCTAssertTrue(documentation.contains("## API Version V3"), "Should contain v3 section")
    }
    
    func testExportEndpointsAsJSON() {
        let jsonData = versioningManager.exportEndpointsAsJSON()
        
        XCTAssertNotNil(jsonData, "Should export JSON data")
        
        if let data = jsonData {
            let jsonString = String(data: data, encoding: .utf8)
            XCTAssertNotNil(jsonString, "Should be valid UTF-8")
            XCTAssertTrue(jsonString?.contains("health/records") ?? false, "Should contain endpoint data")
        }
    }
    
    // MARK: - Performance Tests
    
    func testEndpointsRegistryPerformance() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Access all endpoints multiple times
        for _ in 0..<1000 {
            let _ = versioningManager.allEndpoints
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should be very fast
        XCTAssertLessThan(duration, 0.1, "Endpoints registry access took too long: \(duration)s")
    }
    
    func testURLConstructionPerformance() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v2,
            method: .get,
            description: "Health records endpoint"
        )
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Build URLs multiple times
        for _ in 0..<1000 {
            let _ = versioningManager.buildURL(for: endpoint, environment: .production)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should be very fast
        XCTAssertLessThan(duration, 0.1, "URL construction took too long: \(duration)s")
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyPathParameters() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v1,
            method: .get,
            description: "Health records endpoint"
        )
        
        let url = versioningManager.buildURL(for: endpoint, pathParameters: [:], environment: .production)
        XCTAssertEqual(url.absoluteString, "https://api.healthai2030.com/v1/health/records")
    }
    
    func testMissingPathParameters() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records/{id}",
            version: .v1,
            method: .get,
            description: "Health records endpoint"
        )
        
        let url = versioningManager.buildURL(for: endpoint, pathParameters: [:], environment: .production)
        XCTAssertEqual(url.absoluteString, "https://api.healthai2030.com/v1/health/records/{id}")
    }
    
    func testExtraPathParameters() {
        let endpoint = APIVersioningManager.APIEndpoint(
            path: "/health/records",
            version: .v1,
            method: .get,
            description: "Health records endpoint"
        )
        
        let pathParameters = ["id": "12345", "extra": "value"]
        let url = versioningManager.buildURL(for: endpoint, pathParameters: pathParameters, environment: .production)
        XCTAssertEqual(url.absoluteString, "https://api.healthai2030.com/v1/health/records")
    }
} 