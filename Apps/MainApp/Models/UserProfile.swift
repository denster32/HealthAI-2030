import Foundation
import SwiftData

/// Represents a user's profile information in the HealthAI 2030 app
@Model
public class UserProfile {
    @Attribute(.unique) public var id: UUID
    public var email: String
    public var displayName: String
    public var dateOfBirth: Date?
    public var height: Double?
    public var weight: Double?
    public var gender: String?
    public var createdAt: Date
    public var lastUpdated: Date
    public var isOnboardingCompleted: Bool
    public var preferences: UserPreferences
    
    @Relationship(deleteRule: .cascade) public var healthData: [HealthData]?
    @Relationship(deleteRule: .cascade) public var digitalTwin: DigitalTwin?
    
    public init(
        id: UUID = UUID(),
        email: String,
        displayName: String,
        dateOfBirth: Date? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        gender: String? = nil,
        createdAt: Date = Date(),
        lastUpdated: Date = Date(),
        isOnboardingCompleted: Bool = false,
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.dateOfBirth = dateOfBirth
        self.height = height
        self.weight = weight
        self.gender = gender
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.isOnboardingCompleted = isOnboardingCompleted
        self.preferences = preferences
    }
    
    public func updateProfile(
        displayName: String? = nil,
        dateOfBirth: Date? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        gender: String? = nil
    ) {
        if let displayName = displayName {
            self.displayName = displayName
        }
        if let dateOfBirth = dateOfBirth {
            self.dateOfBirth = dateOfBirth
        }
        if let height = height {
            self.height = height
        }
        if let weight = weight {
            self.weight = weight
        }
        if let gender = gender {
            self.gender = gender
        }
        self.lastUpdated = Date()
    }
    
    public func completeOnboarding() {
        self.isOnboardingCompleted = true
        self.lastUpdated = Date()
    }
}

/// User preferences for the app
public struct UserPreferences: Codable {
    public var notificationsEnabled: Bool
    public var healthKitSyncEnabled: Bool
    public var cloudKitSyncEnabled: Bool
    public var darkModeEnabled: Bool
    public var language: String
    public var units: MeasurementUnits
    
    public init(
        notificationsEnabled: Bool = true,
        healthKitSyncEnabled: Bool = true,
        cloudKitSyncEnabled: Bool = true,
        darkModeEnabled: Bool = false,
        language: String = "en",
        units: MeasurementUnits = .metric
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.healthKitSyncEnabled = healthKitSyncEnabled
        self.cloudKitSyncEnabled = cloudKitSyncEnabled
        self.darkModeEnabled = darkModeEnabled
        self.language = language
        self.units = units
    }
}

public enum MeasurementUnits: String, CaseIterable, Codable {
    case metric = "metric"
    case imperial = "imperial"
    
    public var displayName: String {
        switch self {
        case .metric: return "Metric"
        case .imperial: return "Imperial"
        }
    }
} 