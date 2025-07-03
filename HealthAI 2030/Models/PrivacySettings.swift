import Foundation

public struct PrivacySettings: Codable {
    public var shareHealthData: Bool
    public var shareUsageData: Bool
    public init(shareHealthData: Bool = true, shareUsageData: Bool = false) {
        self.shareHealthData = shareHealthData
        self.shareUsageData = shareUsageData
    }
    public func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "PrivacySettings")
        }
    }
    public static func load() -> PrivacySettings {
        if let data = UserDefaults.standard.data(forKey: "PrivacySettings"),
           let settings = try? JSONDecoder().decode(PrivacySettings.self, from: data) {
            return settings
        }
        return PrivacySettings()
    }
}
