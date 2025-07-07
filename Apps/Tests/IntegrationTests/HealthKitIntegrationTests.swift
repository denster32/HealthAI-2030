import XCTest
import HealthKit
@testable import HealthAI2030Core

final class HealthKitIntegrationTests: XCTestCase {
    
    var healthStore: HKHealthStore!
    var mockHealthKitManager: MockHealthKitManager!
    
    override func setUp() async throws {
        try await super.setUp()
        healthStore = HKHealthStore()
        mockHealthKitManager = MockHealthKitManager()
    }
    
    override func tearDown() async throws {
        healthStore = nil
        mockHealthKitManager = nil
        try await super.tearDown()
    }

    func testReadWriteHealthKitDataTypes() async throws {
        // Test reading and writing various HealthKit data types
        let testDataTypes: [HKQuantityType] = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        ]
        
        for dataType in testDataTypes {
            // Test reading data
            let readResult = try await mockHealthKitManager.readHealthData(
                type: dataType,
                startDate: Date().addingTimeInterval(-86400), // Last 24 hours
                endDate: Date()
            )
            XCTAssertNotNil(readResult, "Should be able to read \(dataType.identifier) data")
            
            // Test writing sample data
            let sample = createMockHealthKitSample(for: dataType)
            let writeResult = try await mockHealthKitManager.writeHealthData(sample)
            XCTAssertTrue(writeResult, "Should be able to write \(dataType.identifier) data")
        }
    }

    func testPermissionPromptHandling() async throws {
        // Test HealthKit authorization flow
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        ]
        
        // Test permission request
        let authorizationResult = try await mockHealthKitManager.requestAuthorization(
            typesToRead: typesToRead,
            typesToWrite: typesToWrite
        )
        XCTAssertTrue(authorizationResult, "Should successfully request HealthKit authorization")
        
        // Test permission status checking
        let readStatus = mockHealthKitManager.authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!)
        XCTAssertEqual(readStatus, .sharingAuthorized, "Heart rate read permission should be authorized")
        
        let writeStatus = mockHealthKitManager.authorizationStatus(for: HKQuantityType.quantityType(forIdentifier: .bodyMass)!)
        XCTAssertEqual(writeStatus, .sharingAuthorized, "Body mass write permission should be authorized")
    }

    func testConcurrentHealthKitOperations() async throws {
        // Test concurrent HealthKit read/write operations
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        // Create multiple concurrent read operations
        await withTaskGroup(of: [HKQuantitySample]?.self) { group in
            for i in 0..<5 {
                group.addTask {
                    return try? await self.mockHealthKitManager.readHealthData(
                        type: heartRateType,
                        startDate: Date().addingTimeInterval(-3600 * Double(i)),
                        endDate: Date()
                    )
                }
            }
            
            // Create multiple concurrent write operations
            for i in 0..<3 {
                group.addTask {
                    let sample = self.createMockHealthKitSample(for: stepCountType, value: Double(i * 100))
                    return try? await self.mockHealthKitManager.writeHealthData(sample)
                }
            }
            
            // Verify all operations complete successfully
            var completedOperations = 0
            for await result in group {
                XCTAssertNotNil(result, "Concurrent operation should complete successfully")
                completedOperations += 1
            }
            XCTAssertEqual(completedOperations, 8, "All 8 concurrent operations should complete")
        }
    }
    
    func testHealthKitDataConsistency() async throws {
        // Test data consistency across multiple operations
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        // Write initial data
        let initialSample = createMockHealthKitSample(for: heartRateType, value: 75.0)
        let writeResult = try await mockHealthKitManager.writeHealthData(initialSample)
        XCTAssertTrue(writeResult, "Should write initial heart rate data")
        
        // Read back the data
        let readResult = try await mockHealthKitManager.readHealthData(
            type: heartRateType,
            startDate: Date().addingTimeInterval(-300), // Last 5 minutes
            endDate: Date()
        )
        
        XCTAssertNotNil(readResult, "Should read back heart rate data")
        XCTAssertGreaterThan(readResult!.count, 0, "Should have at least one heart rate sample")
        
        // Verify data consistency
        let lastSample = readResult!.last!
        XCTAssertEqual(lastSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())), 75.0, accuracy: 0.1, "Heart rate value should be consistent")
    }
    
    func testHealthKitErrorHandling() async throws {
        // Test error handling for invalid operations
        let invalidType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        // Test reading with invalid date range
        do {
            let _ = try await mockHealthKitManager.readHealthData(
                type: invalidType,
                startDate: Date(),
                endDate: Date().addingTimeInterval(-3600) // End before start
            )
            XCTFail("Should throw error for invalid date range")
        } catch {
            XCTAssertTrue(error is HealthKitError, "Should throw HealthKitError for invalid date range")
        }
        
        // Test writing invalid sample
        do {
            let invalidSample = createMockHealthKitSample(for: invalidType, value: -50.0) // Negative heart rate
            let _ = try await mockHealthKitManager.writeHealthData(invalidSample)
            XCTFail("Should throw error for invalid sample data")
        } catch {
            XCTAssertTrue(error is HealthKitError, "Should throw HealthKitError for invalid sample")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockHealthKitSample(for type: HKQuantityType, value: Double = 75.0) -> HKQuantitySample {
        let quantity = HKQuantity(unit: getUnit(for: type), doubleValue: value)
        return HKQuantitySample(
            type: type,
            quantity: quantity,
            start: Date(),
            end: Date().addingTimeInterval(60),
            device: HKDevice(name: "Mock Device", manufacturer: "HealthAI", model: "Test", hardwareVersion: "1.0", firmwareVersion: "1.0", softwareVersion: "1.0", localIdentifier: "test-device", udiDeviceIdentifier: nil)
        )
    }
    
    private func getUnit(for type: HKQuantityType) -> HKUnit {
        switch type.identifier {
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return HKUnit.count().unitDivided(by: .minute())
        case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue:
            return .secondUnit(with: .milli)
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return .count()
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return .kilocalorie()
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            return .gramUnit(with: .kilo)
        default:
            return .count()
        }
    }
}

// MARK: - Mock HealthKit Manager

class MockHealthKitManager {
    
    enum HealthKitError: Error {
        case invalidDateRange
        case invalidSampleData
        case authorizationDenied
    }
    
    func readHealthData(type: HKQuantityType, startDate: Date, endDate: Date) async throws -> [HKQuantitySample] {
        // Validate date range
        guard startDate < endDate else {
            throw HealthKitError.invalidDateRange
        }
        
        // Simulate reading health data
        let mockSamples = [
            createMockSample(type: type, value: 75.0, date: startDate.addingTimeInterval(300)),
            createMockSample(type: type, value: 78.0, date: startDate.addingTimeInterval(600)),
            createMockSample(type: type, value: 72.0, date: startDate.addingTimeInterval(900))
        ]
        
        return mockSamples.filter { $0.startDate >= startDate && $0.endDate <= endDate }
    }
    
    func writeHealthData(_ sample: HKQuantitySample) async throws -> Bool {
        // Validate sample data
        guard sample.quantity.doubleValue(for: getUnit(for: sample.quantityType)) > 0 else {
            throw HealthKitError.invalidSampleData
        }
        
        // Simulate writing health data
        return true
    }
    
    func requestAuthorization(typesToRead: Set<HKObjectType>, typesToWrite: Set<HKSampleType>) async throws -> Bool {
        // Simulate authorization request
        return true
    }
    
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        // Simulate authorized status
        return .sharingAuthorized
    }
    
    private func createMockSample(type: HKQuantityType, value: Double, date: Date) -> HKQuantitySample {
        let quantity = HKQuantity(unit: getUnit(for: type), doubleValue: value)
        return HKQuantitySample(
            type: type,
            quantity: quantity,
            start: date,
            end: date.addingTimeInterval(60),
            device: HKDevice(name: "Mock Device", manufacturer: "HealthAI", model: "Test", hardwareVersion: "1.0", firmwareVersion: "1.0", softwareVersion: "1.0", localIdentifier: "test-device", udiDeviceIdentifier: nil)
        )
    }
    
    private func getUnit(for type: HKQuantityType) -> HKUnit {
        switch type.identifier {
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return HKUnit.count().unitDivided(by: .minute())
        case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue:
            return .secondUnit(with: .milli)
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            return .count()
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return .kilocalorie()
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            return .gramUnit(with: .kilo)
        default:
            return .count()
        }
    }
} 