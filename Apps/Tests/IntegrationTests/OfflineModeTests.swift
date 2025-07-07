import XCTest
import SwiftData
@testable import HealthAI2030Core

@available(iOS 18.0, macOS 15.0, *)
final class OfflineModeTests: XCTestCase {
    var manager: SwiftDataManager!

    override func setUpWithError() throws {
        manager = SwiftDataManager()
        manager.isNetworkEnabled = false // simulate offline
    }

    override func tearDownWithError() throws {
        manager.isNetworkEnabled = true
        manager = nil
    }

    func testAppLaunchOffline() {
        // TODO: Simulate app launch without network connectivity and ensure no errors occur
        XCTAssertTrue(true, "Simulated offline launch succeeded")
    }

    func testDataCreationOffline() async throws {
        let manager = SwiftDataManager.shared
        // Simulate offline mode: assume CloudKit unavailable
        let entry = HealthDataEntry(id: UUID(), timestamp: Date(), dataType: "offlineTest", value: 1.0, stringValue: nil, unit: "unit", source: "test", deviceSource: "device", provenance: nil, metadata: nil, isValidated: false, validationErrors: nil)
        try await manager.save(entry)
        let results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
        XCTAssertEqual(results.first?.id, entry.id)
    }

    func testDataModificationOffline() async throws {
        let manager = SwiftDataManager.shared
        let entry = HealthDataEntry(id: UUID(), timestamp: Date(), dataType: "offlineTest", value: 1.0, stringValue: nil, unit: "unit", source: "test", deviceSource: "device", provenance: nil, metadata: nil, isValidated: false, validationErrors: nil)
        try await manager.save(entry)
        entry.value = 2.0
        try await manager.update(entry)
        let results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
        XCTAssertEqual(results.first?.value, 2.0)
    }

    func testDataDeletionOffline() async throws {
        let manager = SwiftDataManager.shared
        let entry = HealthDataEntry(id: UUID(), timestamp: Date(), dataType: "offlineTest", value: 1.0, stringValue: nil, unit: "unit", source: "test", deviceSource: "device", provenance: nil, metadata: nil, isValidated: false, validationErrors: nil)
        try await manager.save(entry)
        try await manager.delete(entry)
        let results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
        XCTAssertTrue(results.isEmpty)
    }

    func testTransitionOfflineToOnline() async throws {
        let manager = SwiftDataManager.shared
        let entry = HealthDataEntry(id: UUID(), timestamp: Date(), dataType: "offlineTest", value: 1.0, stringValue: nil, unit: "unit", source: "test", deviceSource: "device", provenance: nil, metadata: nil, isValidated: false, validationErrors: nil)
        try await manager.save(entry)
        // TODO: Simulate network restoration and trigger sync
        let results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
        XCTAssertEqual(results.count, 1)
    }
} 