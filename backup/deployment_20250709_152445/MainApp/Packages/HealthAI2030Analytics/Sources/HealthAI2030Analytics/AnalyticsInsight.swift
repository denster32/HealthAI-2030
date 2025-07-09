import Foundation
import SwiftData
import CloudKit

@available(iOS 18.0, macOS 15.0, *)
@Model
public final class AnalyticsInsight /*: CKSyncable*/ { // Comment out CKSyncable if missing
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var details: String // Renamed from description
    public var category: String
    public var confidence: Double
    public var timestamp: Date
    public var source: String // "iPhone", "Mac", "Watch"
    public var actionable: Bool
    public var data: Data? // Serialized insight data
    public var priority: Int = 0 // 0=low, 1=medium, 2=high, 3=critical
    
    // Sync metadata
    public var lastSyncDate: Date?
    public var needsSync: Bool = false
    public var syncVersion: Int = 1
    
    public init(id: UUID = UUID(), title: String, details: String, category: String, confidence: Double, timestamp: Date = Date(), source: String, actionable: Bool = false, data: Data? = nil, priority: Int = 0) {
        self.id = id
        self.title = title
        self.details = details
        self.category = category
        self.confidence = confidence
        self.timestamp = timestamp
        self.source = source
        self.actionable = actionable
        self.data = data
        self.priority = priority
        self.lastSyncDate = nil
        self.needsSync = true
        self.syncVersion = 1
    }
}

@available(iOS 18.0, macOS 15.0, *)
extension AnalyticsInsight {
    var ckRecord: CKRecord {
        let record = CKRecord(recordType: "AnalyticsInsight", recordID: CKRecord.ID(recordName: id.uuidString))
        record["title"] = title
        record["details"] = details // Renamed from description
        record["category"] = category
        record["confidence"] = confidence
        record["timestamp"] = timestamp
        record["source"] = source
        record["actionable"] = actionable
        record["priority"] = priority
        record["syncVersion"] = syncVersion
        if let data = data {
            record["data"] = data
        }
        return record
    }
    
    convenience init?(from record: CKRecord) {
        guard let title = record["title"] as? String,
              let details = record["details"] as? String, // Renamed from description
              let category = record["category"] as? String,
              let confidence = record["confidence"] as? Double,
              let timestamp = record["timestamp"] as? Date,
              let source = record["source"] as? String else {
            return nil
        }
        self.init(title: title, details: details, category: category, confidence: confidence, timestamp: timestamp, source: source)
    }
}