import Foundation

/// Stores user privacy preferences for data sharing.
///
/// - Controls sharing of health and usage data.
/// - Persists settings in UserDefaults.
/// - TODO: Add support for granular permissions and audit logging.
public struct PrivacySettings: Codable {
    /// Whether to share health data with cloud or third parties.
    public var shareHealthData: Bool
    /// Whether to share anonymized usage data for analytics.
    public var shareUsageData: Bool
    public init(shareHealthData: Bool = true, shareUsageData: Bool = false) {
        self.shareHealthData = shareHealthData
        self.shareUsageData = shareUsageData
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
            return settings
        }
        return PrivacySettings()
    }
    // TODO: Add migration support for future settings changes.
}
// TODO: Add unit tests for PrivacySettings persistence and logic.
