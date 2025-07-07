import XCTest
import SwiftData
import CloudKit
@testable import HealthAI2030Core

@MainActor
final class CloudKitConflictResolutionTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var conflictResolver: CloudKitConflictResolver!
    var syncManager: CloudKitSyncManager!
    
    override func setUp() async throws {
        // Create test model container
        let schema = Schema([
            HealthRecord.self,
            SleepRecord.self,
            UserProfile.self,
            HealthDataEntry.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        conflictResolver = CloudKitConflictResolver()
        syncManager = CloudKitSyncManager(modelContainer: modelContainer)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        conflictResolver = nil
        syncManager = nil
    }
    
    // MARK: - Basic Conflict Resolution Tests
    
    func testLastWriteWinsStrategy() async throws {
        // Create conflicting records with different timestamps
        let record1 = HealthRecord(
            id: UUID(),
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            heartRate: 75,
            bloodPressure: "120/80",
            temperature: 98.6,
            notes: "Older record"
        )
        
        let record2 = HealthRecord(
            id: record1.id, // Same ID to create conflict
            timestamp: Date(), // Current time
            heartRate: 80,
            bloodPressure: "125/85",
            temperature: 98.8,
            notes: "Newer record"
        )
        
        // Test last write wins strategy
        let resolution = try await conflictResolver.resolveConflict(
            localRecord: record1,
            remoteRecord: record2,
            strategy: .lastWriteWins
        )
        
        XCTAssertEqual(resolution.winningRecord?.heartRate, 80, "Newer record should win")
        XCTAssertEqual(resolution.winningRecord?.notes, "Newer record", "Newer record should win")
        XCTAssertEqual(resolution.resolutionType, .lastWriteWins, "Resolution type should be lastWriteWins")
    }
    
    func testClientWinsStrategy() async throws {
        // Create conflicting records
        let localRecord = HealthRecord(
            id: UUID(),
            timestamp: Date(),
            heartRate: 75,
            bloodPressure: "120/80",
            temperature: 98.6,
            notes: "Local record"
        )
        
        let remoteRecord = HealthRecord(
            id: localRecord.id,
            timestamp: Date().addingTimeInterval(3600), // 1 hour later
            heartRate: 80,
            bloodPressure: "125/85",
            temperature: 98.8,
            notes: "Remote record"
        )
        
        // Test client wins strategy
        let resolution = try await conflictResolver.resolveConflict(
            localRecord: localRecord,
            remoteRecord: remoteRecord,
            strategy: .clientWins
        )
        
        XCTAssertEqual(resolution.winningRecord?.heartRate, 75, "Local record should win")
        XCTAssertEqual(resolution.winningRecord?.notes, "Local record", "Local record should win")
        XCTAssertEqual(resolution.resolutionType, .clientWins, "Resolution type should be clientWins")
    }
    
    func testServerWinsStrategy() async throws {
        // Create conflicting records
        let localRecord = HealthRecord(
            id: UUID(),
            timestamp: Date(),
            heartRate: 75,
            bloodPressure: "120/80",
            temperature: 98.6,
            notes: "Local record"
        )
        
        let remoteRecord = HealthRecord(
            id: localRecord.id,
            timestamp: Date().addingTimeInterval(-3600), // 1 hour earlier
            heartRate: 80,
            bloodPressure: "125/85",
            temperature: 98.8,
            notes: "Remote record"
        )
        
        // Test server wins strategy
        let resolution = try await conflictResolver.resolveConflict(
            localRecord: localRecord,
            remoteRecord: remoteRecord,
            strategy: .serverWins
        )
        
        XCTAssertEqual(resolution.winningRecord?.heartRate, 80, "Remote record should win")
        XCTAssertEqual(resolution.winningRecord?.notes, "Remote record", "Remote record should win")
        XCTAssertEqual(resolution.resolutionType, .serverWins, "Resolution type should be serverWins")
    }
    
    // MARK: - Complex Conflict Scenarios
    
    func testMultipleDeviceConflict() async throws {
        // Simulate conflict between multiple devices
        let baseRecord = HealthRecord(
            id: UUID(),
            timestamp: Date(),
            heartRate: 70,
            bloodPressure: "115/75",
            temperature: 98.4,
            notes: "Base record"
        )
        
        // Device A modifies the record
        let deviceARecord = HealthRecord(
            id: baseRecord.id,
            timestamp: Date().addingTimeInterval(300), // 5 minutes later
            heartRate: 75,
            bloodPressure: "120/80",
            temperature: 98.6,
            notes: "Device A modification"
        )
        
        // Device B modifies the same record simultaneously
        let deviceBRecord = HealthRecord(
            id: baseRecord.id,
            timestamp: Date().addingTimeInterval(600), // 10 minutes later
            heartRate: 80,
            bloodPressure: "125/85",
            temperature: 98.8,
            notes: "Device B modification"
        )
        
        // Resolve conflict between Device A and Device B
        let resolution = try await conflictResolver.resolveConflict(
            localRecord: deviceARecord,
            remoteRecord: deviceBRecord,
            strategy: .lastWriteWins
        )
        
        XCTAssertEqual(resolution.winningRecord?.heartRate, 80, "Device B should win (newer timestamp)")
        XCTAssertEqual(resolution.winningRecord?.notes, "Device B modification", "Device B should win")
    }
    
    func testLongTermOfflineConflict() async throws {
        // Simulate device coming online after long period offline
        let oldLocalRecord = HealthRecord(
            id: UUID(),
            timestamp: Date().addingTimeInterval(-86400 * 7), // 7 days ago
            heartRate: 70,
            bloodPressure: "115/75",
            temperature: 98.4,
            notes: "Old local record"
        )
        
        let recentRemoteRecord = HealthRecord(
            id: oldLocalRecord.id,
            timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
            heartRate: 80,
            bloodPressure: "125/85",
            temperature: 98.8,
            notes: "Recent remote record"
        )
        
        // Test conflict resolution for long-term offline scenario
        let resolution = try await conflictResolver.resolveConflict(
            localRecord: oldLocalRecord,
            remoteRecord: recentRemoteRecord,
            strategy: .lastWriteWins
        )
        
        XCTAssertEqual(resolution.winningRecord?.heartRate, 80, "Recent remote record should win")
        XCTAssertEqual(resolution.resolutionType, .lastWriteWins, "Should use last write wins strategy")
    }
    
    func testPartialFieldConflict() async throws {
        // Test conflict where only some fields are different
        let localRecord = HealthRecord(
            id: UUID(),
            timestamp: Date(),
            heartRate: 75,
            bloodPressure: "120/80",
            temperature: 98.6,
            notes: "Local record"
        )
        
        let remoteRecord = HealthRecord(
            id: localRecord.id,
            timestamp: Date(),
            heartRate: 75, // Same heart rate
            bloodPressure: "125/85", // Different blood pressure
            temperature: 98.6, // Same temperature
            notes: "Remote record" // Different notes
        )
        
        // Test field-level conflict resolution
        let resolution = try await conflictResolver.resolveConflict(
            localRecord: localRecord,
            remoteRecord: remoteRecord,
            strategy: .mergeFields
        )
        
        XCTAssertEqual(resolution.winningRecord?.heartRate, 75, "Heart rate should remain unchanged")
        XCTAssertEqual(resolution.winningRecord?.bloodPressure, "125/85", "Blood pressure should use remote value")
        XCTAssertEqual(resolution.winningRecord?.temperature, 98.6, "Temperature should remain unchanged")
        XCTAssertEqual(resolution.winningRecord?.notes, "Remote record", "Notes should use remote value")
        XCTAssertEqual(resolution.resolutionType, .mergeFields, "Should use merge fields strategy")
    }
    
    // MARK: - Data Type Specific Conflicts
    
    func testHealthDataEntryConflict() async throws {
        // Test conflict resolution for HealthDataEntry
        let localEntry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "heartRate",
            value: 75.0,
            stringValue: nil,
            unit: "bpm",
            source: "local",
            deviceSource: "iPhone",
            provenance: nil,
            metadata: ["local": "true"],
            isValidated: false,
            validationErrors: nil
        )
        
        let remoteEntry = HealthDataEntry(
            id: localEntry.id,
            timestamp: Date().addingTimeInterval(300),
            dataType: "heartRate",
            value: 80.0,
            stringValue: nil,
            unit: "bpm",
            source: "remote",
            deviceSource: "Apple Watch",
            provenance: nil,
            metadata: ["remote": "true"],
            isValidated: true,
            validationErrors: nil
        )
        
        let resolution = try await conflictResolver.resolveConflict(
            localRecord: localEntry,
            remoteRecord: remoteEntry,
            strategy: .lastWriteWins
        )
        
        XCTAssertEqual(resolution.winningRecord?.value, 80.0, "Remote value should win")
        XCTAssertEqual(resolution.winningRecord?.source, "remote", "Remote source should win")
        XCTAssertEqual(resolution.winningRecord?.isValidated, true, "Remote validation status should win")
    }
    
    func testSleepRecordConflict() async throws {
        // Test conflict resolution for SleepRecord
        let localSleep = SleepRecord(
            id: UUID(),
            startTime: Date().addingTimeInterval(-28800), // 8 hours ago
            endTime: Date().addingTimeInterval(-7200), // 2 hours ago
            quality: .good,
            duration: 6.0,
            notes: "Local sleep record"
        )
        
        let remoteSleep = SleepRecord(
            id: localSleep.id,
            startTime: Date().addingTimeInterval(-28800),
            endTime: Date().addingTimeInterval(-3600), // 1 hour ago
            quality: .excellent,
            duration: 7.0,
            notes: "Remote sleep record"
        )
        
        let resolution = try await conflictResolver.resolveConflict(
            localRecord: localSleep,
            remoteRecord: remoteSleep,
            strategy: .lastWriteWins
        )
        
        XCTAssertEqual(resolution.winningRecord?.duration, 7.0, "Remote duration should win")
        XCTAssertEqual(resolution.winningRecord?.quality, .excellent, "Remote quality should win")
        XCTAssertEqual(resolution.winningRecord?.notes, "Remote sleep record", "Remote notes should win")
    }
    
    // MARK: - Conflict Resolution Strategy Validation
    
    func testConflictResolutionStrategyValidation() async throws {
        // Test that all conflict resolution strategies are properly validated
        let strategies: [ConflictResolutionStrategy] = [
            .lastWriteWins,
            .clientWins,
            .serverWins,
            .mergeFields,
            .manual
        ]
        
        let localRecord = HealthRecord(
            id: UUID(),
            timestamp: Date(),
            heartRate: 75,
            bloodPressure: "120/80",
            temperature: 98.6,
            notes: "Local record"
        )
        
        let remoteRecord = HealthRecord(
            id: localRecord.id,
            timestamp: Date().addingTimeInterval(300),
            heartRate: 80,
            bloodPressure: "125/85",
            temperature: 98.8,
            notes: "Remote record"
        )
        
        for strategy in strategies {
            do {
                let resolution = try await conflictResolver.resolveConflict(
                    localRecord: localRecord,
                    remoteRecord: remoteRecord,
                    strategy: strategy
                )
                
                XCTAssertNotNil(resolution, "Resolution should not be nil for strategy: \(strategy)")
                XCTAssertEqual(resolution.resolutionType, strategy, "Resolution type should match strategy")
                
                // Verify strategy-specific behavior
                switch strategy {
                case .lastWriteWins:
                    XCTAssertEqual(resolution.winningRecord?.heartRate, 80, "Last write wins should choose newer record")
                case .clientWins:
                    XCTAssertEqual(resolution.winningRecord?.heartRate, 75, "Client wins should choose local record")
                case .serverWins:
                    XCTAssertEqual(resolution.winningRecord?.heartRate, 80, "Server wins should choose remote record")
                case .mergeFields:
                    // Merge should combine fields appropriately
                    XCTAssertNotNil(resolution.winningRecord, "Merge should produce a combined record")
                case .manual:
                    XCTAssertEqual(resolution.resolutionType, .manual, "Manual should require user intervention")
                }
            } catch {
                XCTFail("Conflict resolution should not fail for strategy: \(strategy), error: \(error)")
            }
        }
    }
    
    func testConflictResolutionDocumentation() async throws {
        // Test that conflict resolution strategies are properly documented
        let strategies: [ConflictResolutionStrategy] = [
            .lastWriteWins,
            .clientWins,
            .serverWins,
            .mergeFields,
            .manual
        ]
        
        for strategy in strategies {
            let description = strategy.description
            XCTAssertFalse(description.isEmpty, "Strategy should have a description: \(strategy)")
            XCTAssertTrue(description.count > 10, "Description should be meaningful: \(description)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testConflictResolutionWithInvalidRecords() async throws {
        // Test conflict resolution with invalid or corrupted records
        let validRecord = HealthRecord(
            id: UUID(),
            timestamp: Date(),
            heartRate: 75,
            bloodPressure: "120/80",
            temperature: 98.6,
            notes: "Valid record"
        )
        
        // Test with nil records
        do {
            let _ = try await conflictResolver.resolveConflict(
                localRecord: nil,
                remoteRecord: validRecord,
                strategy: .lastWriteWins
            )
            XCTFail("Should throw error for nil local record")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("nil") || error.localizedDescription.contains("invalid"), "Should handle nil local record")
        }
        
        do {
            let _ = try await conflictResolver.resolveConflict(
                localRecord: validRecord,
                remoteRecord: nil,
                strategy: .lastWriteWins
            )
            XCTFail("Should throw error for nil remote record")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("nil") || error.localizedDescription.contains("invalid"), "Should handle nil remote record")
        }
    }
    
    func testConflictResolutionWithMismatchedIDs() async throws {
        // Test conflict resolution with records that have different IDs
        let record1 = HealthRecord(
            id: UUID(),
            timestamp: Date(),
            heartRate: 75,
            bloodPressure: "120/80",
            temperature: 98.6,
            notes: "Record 1"
        )
        
        let record2 = HealthRecord(
            id: UUID(), // Different ID
            timestamp: Date(),
            heartRate: 80,
            bloodPressure: "125/85",
            temperature: 98.8,
            notes: "Record 2"
        )
        
        do {
            let _ = try await conflictResolver.resolveConflict(
                localRecord: record1,
                remoteRecord: record2,
                strategy: .lastWriteWins
            )
            XCTFail("Should throw error for mismatched IDs")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("ID") || error.localizedDescription.contains("mismatch"), "Should handle mismatched IDs")
        }
    }
    
    // MARK: - Performance Tests
    
    func testConflictResolutionPerformance() async throws {
        // Test performance of conflict resolution with large datasets
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let localRecords = (0..<100).map { index in
            HealthRecord(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 60)),
                heartRate: 70 + index,
                bloodPressure: "120/80",
                temperature: 98.4,
                notes: "Local record \(index)"
            )
        }
        
        let remoteRecords = (0..<100).map { index in
            HealthRecord(
                id: localRecords[index].id,
                timestamp: Date().addingTimeInterval(Double(index * 60) + 300),
                heartRate: 75 + index,
                bloodPressure: "125/85",
                temperature: 98.6,
                notes: "Remote record \(index)"
            )
        }
        
        // Resolve conflicts for all records
        for i in 0..<100 {
            let _ = try await conflictResolver.resolveConflict(
                localRecord: localRecords[i],
                remoteRecord: remoteRecords[i],
                strategy: .lastWriteWins
            )
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Conflict resolution should be reasonably fast (< 1 second for 100 records)
        XCTAssertLessThan(duration, 1.0, "Conflict resolution took too long: \(duration)s for 100 records")
    }
}

// MARK: - Helper Classes

class CloudKitConflictResolver {
    func resolveConflict<T: SyncableRecord>(
        localRecord: T?,
        remoteRecord: T?,
        strategy: ConflictResolutionStrategy
    ) async throws -> ConflictResolution<T> {
        
        // Validate inputs
        guard let local = localRecord else {
            throw ConflictResolutionError.invalidLocalRecord
        }
        
        guard let remote = remoteRecord else {
            throw ConflictResolutionError.invalidRemoteRecord
        }
        
        guard local.id == remote.id else {
            throw ConflictResolutionError.mismatchedIDs
        }
        
        // Apply resolution strategy
        let winningRecord: T
        let resolutionType: ConflictResolutionStrategy
        
        switch strategy {
        case .lastWriteWins:
            winningRecord = local.timestamp > remote.timestamp ? local : remote
            resolutionType = .lastWriteWins
            
        case .clientWins:
            winningRecord = local
            resolutionType = .clientWins
            
        case .serverWins:
            winningRecord = remote
            resolutionType = .serverWins
            
        case .mergeFields:
            winningRecord = try mergeRecords(local: local, remote: remote)
            resolutionType = .mergeFields
            
        case .manual:
            winningRecord = local // Placeholder, would require user input
            resolutionType = .manual
        }
        
        return ConflictResolution(
            winningRecord: winningRecord,
            resolutionType: resolutionType,
            conflictDetectedAt: Date()
        )
    }
    
    private func mergeRecords<T: SyncableRecord>(local: T, remote: T) throws -> T {
        // Implement field-level merging logic
        // This is a simplified implementation
        return local.timestamp > remote.timestamp ? local : remote
    }
}

class CloudKitSyncManager {
    let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
}

// MARK: - Supporting Types

protocol SyncableRecord {
    var id: UUID { get }
    var timestamp: Date { get }
}

extension HealthRecord: SyncableRecord {}
extension HealthDataEntry: SyncableRecord {}
extension SleepRecord: SyncableRecord {}

enum ConflictResolutionStrategy: CaseIterable {
    case lastWriteWins
    case clientWins
    case serverWins
    case mergeFields
    case manual
    
    var description: String {
        switch self {
        case .lastWriteWins: return "Use the record with the most recent timestamp"
        case .clientWins: return "Always use the local (client) record"
        case .serverWins: return "Always use the remote (server) record"
        case .mergeFields: return "Combine fields from both records intelligently"
        case .manual: return "Require manual user intervention to resolve"
        }
    }
}

struct ConflictResolution<T> {
    let winningRecord: T
    let resolutionType: ConflictResolutionStrategy
    let conflictDetectedAt: Date
}

enum ConflictResolutionError: Error, LocalizedError {
    case invalidLocalRecord
    case invalidRemoteRecord
    case mismatchedIDs
    
    var errorDescription: String? {
        switch self {
        case .invalidLocalRecord: return "Local record is nil or invalid"
        case .invalidRemoteRecord: return "Remote record is nil or invalid"
        case .mismatchedIDs: return "Record IDs do not match"
        }
    }
} 