import Foundation

/// Stores user privacy preferences for data sharing.
///
/// - Controls sharing of health and usage data.
/// - Persists settings in UserDefaults.
/// - Adds support for granular permissions and audit logging.
public struct PrivacySettings: Codable {
    /// Whether to share health data with cloud or third parties.
    public var shareHealthData: Bool
    /// Whether to share anonymized usage data for analytics.
    public var shareUsageData: Bool
    /// Granular permissions for specific data types.
    public var granularPermissions: [HealthDataType: Bool]
    /// Audit log of privacy setting changes.
    public var auditLog: [PrivacySettingAuditEntry]

    public init(shareHealthData: Bool = true, shareUsageData: Bool = false, granularPermissions: [HealthDataType: Bool] = [:], auditLog: [PrivacySettingAuditEntry] = []) {
        self.shareHealthData = shareHealthData
        self.shareUsageData = shareUsageData
        self.granularPermissions = granularPermissions
        self.auditLog = auditLog
    }

    /// Saves the privacy settings to UserDefaults.
    public func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "PrivacySettings")
        }
    }

    /// Loads the privacy settings from UserDefaults, or returns defaults if not set.
    public static func load() -> PrivacySettings {
        if let data = UserDefaults.standard.data(forKey: "PrivacySettings"),
           let settings = try? JSONDecoder().decode(PrivacySettings.self, from: data) {
            // Add migration logic here for older versions of PrivacySettings
            var migratedSettings = settings
            // Example migration: if granularPermissions is empty, initialize with default values
            if migratedSettings.granularPermissions.isEmpty {
                HealthDataType.allCases.forEach { type in
                    migratedSettings.granularPermissions[type] = true // Default to true for existing users
                }
            }
            return migratedSettings
        }
        return PrivacySettings()
    }

    /// Records a change to privacy settings in the audit log.
    public mutating func recordAuditEntry(action: String, details: String) {
        let entry = PrivacySettingAuditEntry(timestamp: Date(), action: action, details: details)
        auditLog.append(entry)
    }
}

/// Represents an entry in the privacy setting audit log.
public struct PrivacySettingAuditEntry: Codable, Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let action: String
    public let details: String
}

// Placeholder for HealthDataType - replace with actual HealthAI 2030 HealthDataType enum
public enum HealthDataType: String, Codable, CaseIterable, Hashable {
    case heartRate = "Heart Rate"
    case sleep = "Sleep Data"
    case activity = "Activity Data"
    case nutrition = "Nutrition Data"
    case mentalHealth = "Mental Health Data"
    case genomic = "Genomic Data"
    case clinical = "Clinical Records"
    case environmental = "Environmental Data"
    case location = "Location Data"
    case biometric = "Biometric Data"
    case custom = "Custom Data"
}
