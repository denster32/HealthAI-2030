import Foundation
import SwiftData

/// Represents a unified health data entry for the Digital Health Twin.
/// This model is designed to be flexible and store various types of health data.
@Model
public class HealthDataEntry: Equatable {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var dataType: String // Corresponds to PrivacySettings.DataType.rawValue
    public var value: Double? // For numerical data like heart rate, steps
    public var stringValue: String? // For string-based data like notes, specific genomic markers
    public var jsonValue: Data? // For complex, structured data (e.g., detailed clinical records, environmental data)
    public var source: String // e.g., "HealthKit", "User Input", "23andMe", "Environmental API"
    public var privacyConsentGiven: Bool // Reflects the granular consent at the time of data ingestion

    public init(id: UUID = UUID(), timestamp: Date, dataType: PrivacySettings.DataType, value: Double? = nil, stringValue: String? = nil, jsonValue: Data? = nil, source: String, privacyConsentGiven: Bool) {
        self.id = id
        self.timestamp = timestamp
        self.dataType = dataType.rawValue
        self.value = value
        self.stringValue = stringValue
        self.jsonValue = jsonValue
        self.source = source
        self.privacyConsentGiven = privacyConsentGiven
    }

    /// Possible errors when decoding `jsonValue`.
    public enum HealthDataEntryError: Error {
        case jsonValueMissing
        case jsonDecodingFailed(Error)
    }

    /// Indicates whether a numeric value is present.
    public var hasNumericValue: Bool {
        return value != nil
    }

    /// Indicates whether a string value is present.
    public var hasStringValue: Bool {
        return stringValue != nil
    }

    /// Decode `jsonValue` into a specified Decodable type.
    public func decodedJSON<T: Decodable>(as type: T.Type) throws -> T {
        guard let data = jsonValue else {
            throw HealthDataEntryError.jsonValueMissing
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw HealthDataEntryError.jsonDecodingFailed(error)
        }
    }

    /// Equatable conformance for comparing entries.
    public static func == (lhs: HealthDataEntry, rhs: HealthDataEntry) -> Bool {
        return lhs.id == rhs.id &&
               lhs.timestamp == rhs.timestamp &&
               lhs.dataType == rhs.dataType &&
               lhs.value == rhs.value &&
               lhs.stringValue == rhs.stringValue &&
               lhs.jsonValue == rhs.jsonValue &&
               lhs.source == rhs.source &&
               lhs.privacyConsentGiven == rhs.privacyConsentGiven
    }
}