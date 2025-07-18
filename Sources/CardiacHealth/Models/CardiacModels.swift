import Foundation
import HealthKit
import SwiftData
import CloudKit

enum CardiacHealthError: Error {
    case dataUnavailable
    case analysisError(String)
    case dataFetchFailed
    case permissionDenied
    case invalidData
}

/// Represents a heart rate measurement at a point in time
public struct HeartRateMeasurement {
    public let value: Int
    public let timestamp: Date
    
    public init(value: Int, timestamp: Date) {
        self.value = value
        self.timestamp = timestamp
    }
}

/// Summary of cardiac health metrics
public struct CardiacSummary {
    public let averageHeartRate: Int
    public let restingHeartRate: Int
    public let hrvScore: Double
    public let timestamp: Date
    
    public init(averageHeartRate: Int, restingHeartRate: Int, hrvScore: Double, timestamp: Date) {
        self.averageHeartRate = averageHeartRate
        self.restingHeartRate = restingHeartRate
        self.hrvScore = hrvScore
        self.timestamp = timestamp
    }
}

/// Risk level assessment for cardiac health
public enum RiskLevel: String {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case critical = "Critical"
}

/// Represents a single day's cardiac trend data
public struct CardiacTrendData: Identifiable {
    public let id: UUID
    public let date: Date
    public let restingHeartRate: Double
    public let hrv: Double
    
    public init(date: Date, restingHeartRate: Double, hrv: Double) {
        self.id = UUID()
        self.date = date
        self.restingHeartRate = restingHeartRate
        self.hrv = hrv
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct CardiacHealthAnalyzer {
    func analyze() throws {
        // Simulate data fetching
        let hasData = Bool.random()
        if !hasData {
            throw CardiacHealthError.dataUnavailable
        }

        // Simulate analysis
        let success = Bool.random()
        if !success {
            throw CardiacHealthError.analysisError("Irregular heartbeat detected")
        }
    }
}

// MARK: - SwiftData Model for Persistence

@available(iOS 18.0, macOS 15.0, *)
@Model
public final class SyncableCardiacEvent: CKSyncable {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var eventType: String // e.g., "Irregular Heartbeat", "Blood Pressure Logged"
    public var value: Double? // e.g., blood pressure reading, heart rate
    public var unit: String? // e.g., "mmHg", "bpm"
    public var notes: String?
    
    // CKSyncable properties
    public var lastSyncDate: Date?
    public var needsSync: Bool = false
    public var syncVersion: Int = 1
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), eventType: String, value: Double? = nil, unit: String? = nil, notes: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.value = value
        self.unit = unit
        self.notes = notes
        self.lastSyncDate = nil
        self.needsSync = true
        self.syncVersion = 1
    }
    
    // MARK: - CloudKit Record Conversion
    
    public var ckRecord: CKRecord {
        let record = CKRecord(recordType: "CardiacEvent", recordID: CKRecord.ID(recordName: id.uuidString))
        record["timestamp"] = timestamp
        record["eventType"] = eventType
        record["value"] = value
        record["unit"] = unit
        record["notes"] = notes
        record["lastSyncDate"] = lastSyncDate
        record["needsSync"] = needsSync
        record["syncVersion"] = syncVersion
        return record
    }
    
    public convenience init?(from record: CKRecord) {
        guard let timestamp = record["timestamp"] as? Date,
              let eventType = record["eventType"] as? String,
              let id = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        
        let value = record["value"] as? Double
        let unit = record["unit"] as? String
        let notes = record["notes"] as? String
        
        self.init(
            id: id,
            timestamp: timestamp,
            eventType: eventType,
            value: value,
            unit: unit,
            notes: notes
        )
        self.lastSyncDate = record["lastSyncDate"] as? Date
        self.needsSync = record["needsSync"] as? Bool ?? false
        self.syncVersion = record["syncVersion"] as? Int ?? 1
    }
    
    public func merge(with remoteRecord: CKRecord) {
        if let remoteTimestamp = remoteRecord["timestamp"] as? Date, remoteTimestamp > self.timestamp {
            self.timestamp = remoteTimestamp
            self.eventType = remoteRecord["eventType"] as? String ?? self.eventType
            self.value = remoteRecord["value"] as? Double ?? self.value
            self.unit = remoteRecord["unit"] as? String ?? self.unit
            self.notes = remoteRecord["notes"] as? String ?? self.notes
        }
        super.merge(with: remoteRecord) // Call superclass merge for sync metadata
    }
}