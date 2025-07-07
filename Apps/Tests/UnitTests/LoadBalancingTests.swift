import XCTest
@testable import HealthAI2030Core

final class LoadBalancingTests: XCTestCase {
    let loadBalancer = LoadBalancingManager.shared
    
    func testServerSelection() {
        let servers = ["server1", "server2", "server3"]
        let selected = loadBalancer.selectServer(algorithm: .roundRobin, servers: servers)
        XCTAssertNotNil(selected)
        XCTAssertTrue(servers.contains(selected!))
    }
    
    func testAllLoadBalancingAlgorithms() {
        let servers = ["server1", "server2"]
        let algorithms: [LoadBalancingManager.LoadBalancingAlgorithm] = [
            .roundRobin,
            .leastConnections,
            .weightedRoundRobin,
            .ipHash,
            .leastResponseTime
        ]
        
        for algorithm in algorithms {
            let selected = loadBalancer.selectServer(algorithm: algorithm, servers: servers)
            XCTAssertNotNil(selected)
        }
    }
    
    func testScaleUp() {
        loadBalancer.scaleUp(service: "api-service", instances: 2)
        // No assertion, just ensure no crash
    }
    
    func testScaleDown() {
        loadBalancer.scaleDown(service: "api-service", instances: 1)
        // No assertion, just ensure no crash
    }
    
    func testAutoScale() {
        loadBalancer.autoScale(service: "api-service", currentLoad: 0.8, threshold: 0.7)
        loadBalancer.autoScale(service: "api-service", currentLoad: 0.3, threshold: 0.7)
        // No assertion, just ensure no crash
    }
    
    func testHealthCheck() {
        let healthy = loadBalancer.checkHealth(server: "server1")
        XCTAssertTrue(healthy)
    }
    
    func testFailover() {
        loadBalancer.failover(from: "server1", to: "backup-server")
        // No assertion, just ensure no crash
    }
    
    func testTrafficRouting() {
        let servers = ["server1", "server2", "server3"]
        let routed = loadBalancer.routeTraffic(request: "api-request", servers: servers)
        XCTAssertNotNil(routed)
        XCTAssertTrue(servers.contains(routed) || routed == "default")
    }
    
    func testTrafficOptimization() {
        loadBalancer.optimizeTraffic(optimization: "latency_optimization")
        // No assertion, just ensure no crash
    }
    
    func testLoadBalancingMetrics() {
        let metrics = loadBalancer.getLoadBalancingMetrics()
        XCTAssertEqual(metrics["activeConnections"] as? Int, 150)
        XCTAssertEqual(metrics["requestsPerSecond"] as? Int, 1000)
        XCTAssertEqual(metrics["averageResponseTime"] as? Double, 0.15)
        XCTAssertEqual(metrics["serverHealth"] as? Double, 0.98)
    }
    
    func testLoadBalancerMonitoring() {
        let monitoring = loadBalancer.monitorLoadBalancer()
        XCTAssertEqual(monitoring["status"] as? String, "healthy")
        XCTAssertEqual(monitoring["uptime"] as? Double, 99.9)
        XCTAssertEqual(monitoring["errors"] as? Int, 0)
    }
    
    func testGeographicRouting() {
        let servers = ["us-east", "us-west", "eu-west"]
        let routed = loadBalancer.routeByGeography(userLocation: "New York", servers: servers)
        XCTAssertNotNil(routed)
        XCTAssertTrue(servers.contains(routed) || routed == "default")
    }
    
    func testNearestServer() {
        let servers = ["us-east": "server1", "us-west": "server2", "eu-west": "server3"]
        let nearest = loadBalancer.getNearestServer(userLocation: "New York", servers: servers)
        XCTAssertNotNil(nearest)
        XCTAssertTrue(servers.values.contains(nearest) || nearest == "default")
    }
} 