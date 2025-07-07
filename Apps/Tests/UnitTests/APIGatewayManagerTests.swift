import XCTest
@testable import HealthAI2030Core

final class APIGatewayManagerTests: XCTestCase {
    let gateway = APIGatewayManager.shared
    
    func testAuthentication() {
        XCTAssertTrue(gateway.authenticate(token: "validToken"))
        XCTAssertFalse(gateway.authenticate(token: ""))
    }
    
    func testAuthorization() {
        XCTAssertTrue(gateway.authorize(userRole: "admin", endpoint: "/test"))
    }
    
    func testRateLimiting() {
        let userId = "user1"
        for _ in 0..<gateway.rateLimit {
            XCTAssertFalse(gateway.isRateLimited(userId: userId))
        }
        XCTAssertTrue(gateway.isRateLimited(userId: userId))
    }
    
    func testRequestCaching() {
        let key = "https://api.healthai2030.com/test"
        let data = Data([1,2,3])
        gateway.cacheResponse(for: key, data: data)
        let cached = gateway.getCachedResponse(for: key)
        XCTAssertEqual(cached, data)
    }
    
    func testMetricsRecording() {
        let endpoint = "/test"
        gateway.recordMetric(endpoint: endpoint, responseTime: 0.1, statusCode: 200)
        let metrics = gateway.getMetrics(for: endpoint)
        XCTAssertTrue(metrics.contains { $0.endpoint == endpoint && $0.statusCode == 200 })
    }
    
    func testRouteRequestSuccess() {
        let url = URL(string: "https://api.healthai2030.com/test")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("validToken", forHTTPHeaderField: "Authorization")
        let exp = expectation(description: "routeRequest")
        gateway.routeRequest(request, userId: "user2", userRole: "admin") { result in
            switch result {
            case .success(let (response, data)):
                XCTAssertNotNil(response)
                XCTAssertNotNil(data)
            case .failure:
                XCTFail("Should not fail")
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testRouteRequestUnauthorized() {
        let url = URL(string: "https://api.healthai2030.com/test")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("", forHTTPHeaderField: "Authorization")
        let exp = expectation(description: "routeRequestUnauthorized")
        gateway.routeRequest(request, userId: "user3", userRole: "admin") { result in
            switch result {
            case .success:
                XCTFail("Should not succeed")
            case .failure(let error):
                XCTAssertEqual((error as NSError).code, 401)
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testRouteRequestRateLimited() {
        let url = URL(string: "https://api.healthai2030.com/test")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("validToken", forHTTPHeaderField: "Authorization")
        let userId = "user4"
        // Exhaust rate limit
        for _ in 0..<gateway.rateLimit {
            _ = gateway.isRateLimited(userId: userId)
        }
        let exp = expectation(description: "routeRequestRateLimited")
        gateway.routeRequest(request, userId: userId, userRole: "admin") { result in
            switch result {
            case .success:
                XCTFail("Should not succeed")
            case .failure(let error):
                XCTAssertEqual((error as NSError).code, 429)
            }
            exp.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
} 