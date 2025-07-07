import XCTest
@testable import HealthAI2030Core

final class EdgeComputingTests: XCTestCase {
    let edge = EdgeComputingManager.shared
    
    func testRegisterEdgeDevice() {
        let capabilities = ["cpu": "arm64", "memory": "4GB", "sensors": ["heart_rate", "gps"]]
        let registered = edge.registerEdgeDevice(id: "device1", type: .wearable, capabilities: capabilities)
        XCTAssertTrue(registered)
        
        let devices = edge.getEdgeDevices()
        XCTAssertGreaterThan(devices.count, 0)
        let device = devices.first { $0.id == "device1" }
        XCTAssertNotNil(device)
        XCTAssertEqual(device?.type, .wearable)
        XCTAssertEqual(device?.status, "online")
    }
    
    func testAllEdgeDeviceTypes() {
        let types: [EdgeComputingManager.EdgeDeviceType] = [
            .wearable,
            .sensor,
            .gateway,
            .mobile,
            .iot
        ]
        
        for (index, type) in types.enumerated() {
            let capabilities = ["type": "test"]
            let registered = edge.registerEdgeDevice(id: "device\(index)", type: type, capabilities: capabilities)
            XCTAssertTrue(registered)
        }
        
        let devices = edge.getEdgeDevices()
        XCTAssertGreaterThanOrEqual(devices.count, types.count)
    }
    
    func testUpdateDeviceStatus() {
        let updated = edge.updateDeviceStatus(deviceId: "device1", status: "offline")
        XCTAssertTrue(updated)
        
        let devices = edge.getEdgeDevices()
        let device = devices.first { $0.id == "device1" }
        XCTAssertEqual(device?.status, "offline")
    }
    
    func testMonitorDeviceHealth() {
        let health = edge.monitorDeviceHealth(deviceId: "device1")
        XCTAssertEqual(health["cpuUsage"] as? Double, 0.25)
        XCTAssertEqual(health["memoryUsage"] as? Double, 0.4)
        XCTAssertEqual(health["batteryLevel"] as? Double, 0.85)
        XCTAssertEqual(health["networkStatus"] as? String, "connected")
        XCTAssertEqual(health["lastHeartbeat"] as? String, "2024-01-15T10:30:00Z")
    }
    
    func testProcessHealthDataAtEdge() {
        let data = Data("health data".utf8)
        let processed = edge.processHealthDataAtEdge(deviceId: "device1", data: data)
        XCTAssertNotNil(processed)
    }
    
    func testRunEdgeMLModel() {
        let input = Data("ml input".utf8)
        let result = edge.runEdgeMLModel(deviceId: "device1", modelId: "health_model", input: input)
        XCTAssertNotNil(result)
    }
    
    func testOptimizeEdgeProcessing() {
        let optimization = edge.optimizeEdgeProcessing(deviceId: "device1")
        XCTAssertEqual(optimization["processingSpeed"] as? Double, 0.8)
        XCTAssertEqual(optimization["latency"] as? Double, 0.1)
        XCTAssertEqual(optimization["throughput"] as? Int, 1000)
        XCTAssertEqual(optimization["optimizationGain"] as? Double, 0.3)
    }
    
    func testMonitorEdgePerformance() {
        let performance = edge.monitorEdgePerformance(deviceId: "device1")
        XCTAssertEqual(performance["processingTime"] as? Double, 0.05)
        XCTAssertEqual(performance["queueLength"] as? Int, 5)
        XCTAssertEqual(performance["errorRate"] as? Double, 0.01)
        XCTAssertEqual(performance["resourceUtilization"] as? Double, 0.6)
    }
    
    func testSyncDataToCloud() {
        let data = Data("sync data".utf8)
        let synced = edge.syncDataToCloud(deviceId: "device1", data: data)
        XCTAssertTrue(synced)
    }
    
    func testSyncDataFromCloud() {
        let data = edge.syncDataFromCloud(deviceId: "device1")
        XCTAssertNotNil(data)
    }
    
    func testManageSyncSchedule() {
        let schedule = ["frequency": "hourly", "batchSize": 1000]
        let managed = edge.manageSyncSchedule(deviceId: "device1", schedule: schedule)
        XCTAssertTrue(managed)
    }
    
    func testMonitorSyncStatus() {
        let status = edge.monitorSyncStatus(deviceId: "device1")
        XCTAssertEqual(status["lastSync"] as? String, "2024-01-15T10:30:00Z")
        XCTAssertEqual(status["syncStatus"] as? String, "successful")
        XCTAssertEqual(status["dataTransferred"] as? Int, 1024)
        XCTAssertEqual(status["syncDuration"] as? Double, 2.5)
    }
    
    func testResolveSyncConflicts() {
        let conflicts = ["conflict1": "data_mismatch", "conflict2": "timestamp_conflict"]
        let resolution = edge.resolveSyncConflicts(deviceId: "device1", conflicts: conflicts)
        XCTAssertEqual(resolution["resolved"] as? Bool, true)
        XCTAssertEqual(resolution["conflictsResolved"] as? Int, 3)
        XCTAssertEqual(resolution["resolutionStrategy"] as? String, "timestamp_based")
    }
    
    func testImplementEdgeSecurity() {
        let policies = ["encryption": "AES-256", "authentication": "required"]
        let implemented = edge.implementEdgeSecurity(deviceId: "device1", policies: policies)
        XCTAssertTrue(implemented)
    }
    
    func testEncryptAndDecryptEdgeData() {
        let originalData = Data("sensitive data".utf8)
        let key = Data("encryption_key".utf8)
        
        let encrypted = edge.encryptEdgeData(data: originalData, key: key)
        XCTAssertNotNil(encrypted)
        
        let decrypted = edge.decryptEdgeData(encryptedData: encrypted, key: key)
        XCTAssertNotNil(decrypted)
    }
    
    func testValidateEdgeSecurity() {
        let security = edge.validateEdgeSecurity(deviceId: "device1")
        XCTAssertEqual(security["encryptionEnabled"] as? Bool, true)
        XCTAssertEqual(security["authenticationValid"] as? Bool, true)
        XCTAssertEqual(security["accessControlActive"] as? Bool, true)
        XCTAssertEqual(security["securityScore"] as? Int, 95)
        XCTAssertEqual(security["vulnerabilities"] as? [String], [])
    }
    
    func testImplementPrivacyControls() {
        let controls = ["dataRetention": "30_days", "anonymization": "enabled"]
        let implemented = edge.implementPrivacyControls(deviceId: "device1", controls: controls)
        XCTAssertTrue(implemented)
    }
    
    func testOptimizeEdgeResources() {
        let optimization = edge.optimizeEdgeResources(deviceId: "device1")
        XCTAssertEqual(optimization["cpuOptimization"] as? Double, 0.2)
        XCTAssertEqual(optimization["memoryOptimization"] as? Double, 0.15)
        XCTAssertEqual(optimization["batteryOptimization"] as? Double, 0.3)
        XCTAssertEqual(optimization["networkOptimization"] as? Double, 0.25)
    }
    
    func testLoadBalanceEdgeWorkload() {
        let deviceIds = ["device1", "device2", "device3"]
        let balance = edge.loadBalanceEdgeWorkload(deviceIds: deviceIds)
        XCTAssertEqual(balance["balanced"] as? Bool, true)
        XCTAssertNotNil(balance["workloadDistribution"])
        XCTAssertEqual(balance["optimizationGain"] as? Double, 0.25)
    }
    
    func testCacheEdgeData() {
        let data = Data("cache data".utf8)
        let cached = edge.cacheEdgeData(deviceId: "device1", data: data, ttl: 3600)
        XCTAssertTrue(cached)
    }
    
    func testOptimizeEdgeAlgorithms() {
        let optimization = edge.optimizeEdgeAlgorithms(deviceId: "device1")
        XCTAssertEqual(optimization["algorithmOptimization"] as? Double, 0.3)
        XCTAssertEqual(optimization["executionTimeReduction"] as? Double, 0.4)
        XCTAssertEqual(optimization["accuracyMaintained"] as? Double, 0.95)
        XCTAssertEqual(optimization["resourceUsageReduction"] as? Double, 0.25)
    }
    
    func testCollectEdgeAnalytics() {
        let analytics = edge.collectEdgeAnalytics(deviceId: "device1")
        XCTAssertEqual(analytics["dataProcessed"] as? Int, 10000)
        XCTAssertEqual(analytics["processingTime"] as? Double, 5.2)
        XCTAssertEqual(analytics["errorRate"] as? Double, 0.02)
        XCTAssertEqual(analytics["userInteractions"] as? Int, 150)
        XCTAssertNotNil(analytics["featureUsage"])
    }
    
    func testGenerateEdgeInsights() {
        let insights = edge.generateEdgeInsights(deviceId: "device1")
        XCTAssertNotNil(insights["performanceTrends"])
        XCTAssertNotNil(insights["usagePatterns"])
        XCTAssertNotNil(insights["optimizationOpportunities"])
        XCTAssertNotNil(insights["predictiveInsights"])
    }
    
    func testCreateEdgeDashboard() {
        let deviceIds = ["device1", "device2", "device3"]
        let dashboard = edge.createEdgeDashboard(deviceIds: deviceIds)
        XCTAssertNotNil(dashboard)
    }
    
    func testExportEdgeAnalytics() {
        let export = edge.exportEdgeAnalytics(deviceId: "device1", format: "json")
        XCTAssertNotNil(export)
    }
} 