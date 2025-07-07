import XCTest
@testable import HealthAI2030Core

final class ThirdPartyIntegrationTests: XCTestCase {
    let integration = ThirdPartyIntegrationManager.shared
    
    func testConnectWithProtocol() {
        let success = integration.connect(protocol: .bluetooth, deviceId: "device1")
        XCTAssertTrue(success)
    }
    
    func testAllIntegrationProtocols() {
        let protocols: [ThirdPartyIntegrationManager.IntegrationProtocol] = [
            .bluetooth,
            .wifi,
            .usb,
            .nfc,
            .cloudAPI
        ]
        
        for protocol in protocols {
            let success = integration.connect(protocol: protocol, deviceId: "test_device")
            XCTAssertTrue(success)
        }
    }
    
    func testDisconnect() {
        integration.disconnect(deviceId: "device1")
        // No assertion, just ensure no crash
    }
    
    func testDiscoverDevices() {
        let devices = integration.discoverDevices()
        XCTAssertEqual(devices.count, 3)
        XCTAssertTrue(devices.contains("fitness_tracker_1"))
        XCTAssertTrue(devices.contains("smart_scale_1"))
        XCTAssertTrue(devices.contains("blood_pressure_monitor_1"))
    }
    
    func testDiscoverServices() {
        let services = integration.discoverServices()
        XCTAssertEqual(services.count, 4)
        XCTAssertTrue(services.contains("google_fit"))
        XCTAssertTrue(services.contains("apple_health"))
        XCTAssertTrue(services.contains("fitbit"))
        XCTAssertTrue(services.contains("myfitnesspal"))
    }
    
    func testScanForNewDevices() {
        let newDevices = integration.scanForNewDevices()
        XCTAssertEqual(newDevices.count, 2)
        XCTAssertTrue(newDevices.contains("new_device_1"))
        XCTAssertTrue(newDevices.contains("new_device_2"))
    }
    
    func testSyncData() {
        let data = integration.syncData(from: "device1")
        XCTAssertNotNil(data)
    }
    
    func testMapData() {
        let originalData = Data([1,2,3])
        let mapped = integration.mapData(originalData, to: "JSON")
        XCTAssertNotNil(mapped)
    }
    
    func testValidateDataMapping() {
        XCTAssertTrue(integration.validateDataMapping(Data([1,2,3])))
        XCTAssertFalse(integration.validateDataMapping(Data()))
    }
    
    func testMonitorIntegrationHealth() {
        let health = integration.monitorIntegrationHealth(deviceId: "device1")
        XCTAssertEqual(health["status"] as? String, "healthy")
        XCTAssertEqual(health["lastSync"] as? String, "2024-01-15T10:30:00Z")
        XCTAssertEqual(health["syncSuccess"] as? Double, 0.95)
        XCTAssertEqual(health["connectionQuality"] as? String, "excellent")
    }
    
    func testCheckIntegrationStatus() {
        let status = integration.checkIntegrationStatus(deviceId: "device1")
        XCTAssertTrue(status)
    }
    
    func testTestIntegration() {
        let success = integration.testIntegration(deviceId: "device1")
        XCTAssertTrue(success)
    }
    
    func testValidateIntegration() {
        let validation = integration.validateIntegration(deviceId: "device1")
        XCTAssertEqual(validation["valid"] as? Bool, true)
        XCTAssertEqual(validation["testsPassed"] as? Int, 10)
        XCTAssertEqual(validation["testsFailed"] as? Int, 0)
        XCTAssertEqual(validation["performance"] as? String, "excellent")
    }
    
    func testAddToCatalog() {
        integration.addToCatalog(deviceId: "catalog1", name: "Test Device", protocol: .bluetooth, supported: true)
        let catalog = integration.getCatalog()
        XCTAssertGreaterThan(catalog.count, 0)
        let device = catalog.first { $0.deviceId == "catalog1" }
        XCTAssertNotNil(device)
        XCTAssertEqual(device?.name, "Test Device")
        XCTAssertEqual(device?.protocol, .bluetooth)
        XCTAssertTrue(device?.supported ?? false)
    }
    
    func testSearchCatalog() {
        integration.addToCatalog(deviceId: "search1", name: "Apple Watch", protocol: .bluetooth, supported: true)
        integration.addToCatalog(deviceId: "search2", name: "Fitbit", protocol: .bluetooth, supported: true)
        
        let appleResults = integration.searchCatalog(query: "Apple")
        XCTAssertEqual(appleResults.count, 1)
        XCTAssertEqual(appleResults.first?.name, "Apple Watch")
        
        let fitbitResults = integration.searchCatalog(query: "Fitbit")
        XCTAssertEqual(fitbitResults.count, 1)
        XCTAssertEqual(fitbitResults.first?.name, "Fitbit")
    }
} 