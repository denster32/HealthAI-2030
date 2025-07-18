import Foundation
import SwiftData

/// Model representing a health data entry
@Model
final class HealthDataEntry: CKSyncable {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var dataType: CKSyncableDataType
    var timestamp: Date
    var value: Double?
    var stringValue: String?
    var metadata: [String: String]?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        dataType: CKSyncableDataType,
        timestamp: Date = Date(),
        value: Double? = nil,
        stringValue: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.dataType = dataType
        self.timestamp = timestamp
        self.value = value
        self.stringValue = stringValue
        self.metadata = metadata
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}