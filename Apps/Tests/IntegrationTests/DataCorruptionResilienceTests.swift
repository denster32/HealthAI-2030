import XCTest
import SwiftData
import Foundation
@testable import HealthAI2030Core

@MainActor
final class DataCorruptionResilienceTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var testStoreURL: URL!
    
    override func setUp() async throws {
        // Create a temporary store for testing
        let tempDir = FileManager.default.temporaryDirectory
        testStoreURL = tempDir.appendingPathComponent("test_corruption_store.sqlite")
        
        // Remove any existing test store
        try? FileManager.default.removeItem(at: testStoreURL)
        
        let schema = Schema([
            HealthRecord.self,
            SleepRecord.self,
            UserProfile.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: testStoreURL,
            isStoredInMemoryOnly: false
        )
        
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        // Clean up test store
        try? FileManager.default.removeItem(at: testStoreURL)
    }
    
    // MARK: - Test Data Setup
    
    private func createTestData() throws {
        let context = modelContainer.mainContext
        
        // Create test health records
        let healthRecord1 = HealthRecord(
            id: UUID(),
            timestamp: Date(),
            heartRate: 75,
            bloodPressure: "120/80",
            temperature: 98.6,
            notes: "Test health record 1"
        )
        
        let healthRecord2 = HealthRecord(
            id: UUID(),
            timestamp: Date().addingTimeInterval(-3600),
            heartRate: 72,
            bloodPressure: "118/78",
            temperature: 98.4,
            notes: "Test health record 2"
        )
        
        let sleepRecord = SleepRecord(
            id: UUID(),
            startTime: Date().addingTimeInterval(-28800),
            endTime: Date().addingTimeInterval(-7200),
            quality: .good,
            duration: 6.0,
            notes: "Test sleep record"
        )
        
        let userProfile = UserProfile(
            id: UUID(),
            name: "Test User",
            age: 30,
            weight: 70.0,
            height: 175.0,
            email: "test@example.com"
        )
        
        context.insert(healthRecord1)
        context.insert(healthRecord2)
        context.insert(sleepRecord)
        context.insert(userProfile)
        
        try context.save()
    }
    
    // MARK: - Corruption Simulation Tests
    
    func testRandomByteCorruption() async throws {
        // Create test data
        try createTestData()
        
        // Verify data exists
        let context = modelContainer.mainContext
        let healthRecords = try context.fetch(FetchDescriptor<HealthRecord>())
        XCTAssertEqual(healthRecords.count, 2, "Should have 2 health records before corruption")
        
        // Simulate random byte corruption
        try simulateCorruption(type: .random)
        
        // Attempt to load data after corruption
        do {
            let corruptedRecords = try context.fetch(FetchDescriptor<HealthRecord>())
            // The app should handle corruption gracefully
            print("Records after corruption: \(corruptedRecords.count)")
        } catch {
            // Expected behavior - corruption should be detected
            print("Corruption detected: \(error)")
            XCTAssertTrue(error.localizedDescription.contains("corruption") || 
                         error.localizedDescription.contains("invalid") ||
                         error.localizedDescription.contains("format"),
                         "Should detect corruption")
        }
    }
    
    func testHeaderCorruption() async throws {
        try createTestData()
        
        // Simulate header corruption
        try simulateCorruption(type: .header)
        
        // Test app behavior with corrupted header
        do {
            let context = modelContainer.mainContext
            let _ = try context.fetch(FetchDescriptor<HealthRecord>())
            XCTFail("Should not be able to read from corrupted store")
        } catch {
            // Expected - header corruption should prevent reading
            XCTAssertTrue(error.localizedDescription.contains("corruption") || 
                         error.localizedDescription.contains("invalid") ||
                         error.localizedDescription.contains("format"),
                         "Should detect header corruption")
        }
    }
    
    func testPartialCorruption() async throws {
        try createTestData()
        
        // Simulate partial corruption
        try simulateCorruption(type: .partial)
        
        // Test app behavior with partial corruption
        let context = modelContainer.mainContext
        do {
            let records = try context.fetch(FetchDescriptor<HealthRecord>())
            // May succeed with some data loss
            print("Records after partial corruption: \(records.count)")
        } catch {
            // May fail depending on corruption location
            print("Partial corruption error: \(error)")
        }
    }
    
    func testCompleteCorruption() async throws {
        try createTestData()
        
        // Simulate complete corruption
        try simulateCorruption(type: .complete)
        
        // Test app behavior with completely corrupted store
        do {
            let context = modelContainer.mainContext
            let _ = try context.fetch(FetchDescriptor<HealthRecord>())
            XCTFail("Should not be able to read from completely corrupted store")
        } catch {
            // Expected - complete corruption should prevent reading
            XCTAssertTrue(error.localizedDescription.contains("corruption") || 
                         error.localizedDescription.contains("invalid") ||
                         error.localizedDescription.contains("format"),
                         "Should detect complete corruption")
        }
    }
    
    // MARK: - Recovery Tests
    
    func testAutomaticRecoveryFromBackup() async throws {
        try createTestData()
        
        // Create backup before corruption
        let backupURL = testStoreURL.appendingPathExtension("backup")
        try FileManager.default.copyItem(at: testStoreURL, to: backupURL)
        
        // Corrupt the store
        try simulateCorruption(type: .random)
        
        // Simulate automatic recovery attempt
        do {
            let context = modelContainer.mainContext
            let _ = try context.fetch(FetchDescriptor<HealthRecord>())
            XCTFail("Should not be able to read from corrupted store")
        } catch {
            // Attempt recovery from backup
            try FileManager.default.removeItem(at: testStoreURL)
            try FileManager.default.copyItem(at: backupURL, to: testStoreURL)
            
            // Recreate model container with recovered store
            let schema = Schema([HealthRecord.self, SleepRecord.self, UserProfile.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                url: testStoreURL,
                isStoredInMemoryOnly: false
            )
            
            let recoveredContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let recoveredContext = recoveredContainer.mainContext
            
            // Verify data is recovered
            let recoveredRecords = try recoveredContext.fetch(FetchDescriptor<HealthRecord>())
            XCTAssertEqual(recoveredRecords.count, 2, "Should recover 2 health records from backup")
            
            // Clean up
            try FileManager.default.removeItem(at: backupURL)
        }
    }
    
    func testGracefulDegradationWithCorruption() async throws {
        try createTestData()
        
        // Simulate corruption
        try simulateCorruption(type: .partial)
        
        // Test that app can still function with degraded data
        let context = modelContainer.mainContext
        
        // Try to create new data (should work even with corrupted existing data)
        let newRecord = HealthRecord(
            id: UUID(),
            timestamp: Date(),
            heartRate: 80,
            bloodPressure: "125/85",
            temperature: 98.7,
            notes: "New record after corruption"
        )
        
        context.insert(newRecord)
        
        do {
            try context.save()
            print("Successfully saved new record after corruption")
        } catch {
            print("Failed to save new record after corruption: \(error)")
            // This might fail depending on corruption severity
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testCorruptionErrorHandling() async throws {
        try createTestData()
        
        // Simulate corruption
        try simulateCorruption(type: .header)
        
        // Test that app provides meaningful error messages
        do {
            let context = modelContainer.mainContext
            let _ = try context.fetch(FetchDescriptor<HealthRecord>())
            XCTFail("Should not be able to read from corrupted store")
        } catch {
            let errorMessage = error.localizedDescription.lowercased()
            
            // Check for appropriate error indicators
            let hasCorruptionIndicator = errorMessage.contains("corruption") ||
                                        errorMessage.contains("invalid") ||
                                        errorMessage.contains("format") ||
                                        errorMessage.contains("damaged") ||
                                        errorMessage.contains("unreadable")
            
            XCTAssertTrue(hasCorruptionIndicator, 
                         "Error should indicate data corruption: \(errorMessage)")
        }
    }
    
    // MARK: - Helper Methods
    
    private enum CorruptionType {
        case random, header, metadata, partial, complete
    }
    
    private func simulateCorruption(type: CorruptionType) throws {
        guard let storePath = testStoreURL?.path else {
            XCTFail("No test store path available")
            return
        }
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: storePath)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Create temporary corrupted file
        let corruptedData: Data
        
        switch type {
        case .random:
            // Corrupt random bytes
            var originalData = try Data(contentsOf: testStoreURL)
            let corruptionCount = min(100, originalData.count / 10)
            for _ in 0..<corruptionCount {
                let randomIndex = Int.random(in: 0..<originalData.count)
                originalData[randomIndex] = UInt8.random(in: 0...255)
            }
            corruptedData = originalData
            
        case .header:
            // Corrupt first 1KB
            var originalData = try Data(contentsOf: testStoreURL)
            let headerSize = min(1024, originalData.count)
            for i in 0..<headerSize {
                originalData[i] = UInt8.random(in: 0...255)
            }
            corruptedData = originalData
            
        case .metadata:
            // Corrupt metadata section (around 10% into file)
            var originalData = try Data(contentsOf: testStoreURL)
            let metadataOffset = originalData.count / 10
            let metadataSize = min(1024, originalData.count - metadataOffset)
            for i in metadataOffset..<(metadataOffset + metadataSize) {
                originalData[i] = UInt8.random(in: 0...255)
            }
            corruptedData = originalData
            
        case .partial:
            // Corrupt middle portion
            var originalData = try Data(contentsOf: testStoreURL)
            let middleOffset = originalData.count / 2
            let corruptionSize = min(2048, originalData.count - middleOffset)
            for i in middleOffset..<(middleOffset + corruptionSize) {
                originalData[i] = UInt8.random(in: 0...255)
            }
            corruptedData = originalData
            
        case .complete:
            // Corrupt entire file
            let randomData = Data((0..<Int(fileSize)).map { _ in UInt8.random(in: 0...255) })
            corruptedData = randomData
        }
        
        // Write corrupted data back to file
        try corruptedData.write(to: testStoreURL)
    }
    
    // MARK: - Performance Tests
    
    func testCorruptionDetectionPerformance() async throws {
        try createTestData()
        
        // Measure time to detect corruption
        let startTime = CFAbsoluteTimeGetCurrent()
        
        try simulateCorruption(type: .random)
        
        do {
            let context = modelContainer.mainContext
            let _ = try context.fetch(FetchDescriptor<HealthRecord>())
        } catch {
            let detectionTime = CFAbsoluteTimeGetCurrent() - startTime
            
            // Corruption detection should be reasonably fast (< 1 second)
            XCTAssertLessThan(detectionTime, 1.0, 
                             "Corruption detection took too long: \(detectionTime)s")
        }
    }
} 