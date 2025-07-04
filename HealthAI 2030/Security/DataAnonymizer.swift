import Foundation

/// Utility for anonymizing health data for analytics/ML.
public struct DataAnonymizer {
    public static func anonymize(_ record: [String: Any]) -> [String: Any] {
        var copy = record
        copy.removeValue(forKey: "userID")
        copy.removeValue(forKey: "email")
        // Add more fields as needed
        return copy
    }
}
