import Foundation
import SwiftData

/// Represents the unified, high-dimensional digital twin model of a user's health.
/// This model integrates various data types and is used for simulations and predictions.
@Model
public class DigitalTwinModel {
    @Attribute(.unique) public var id: UUID
    public var userId: String // Unique identifier for the user
    public var lastUpdated: Date
    public var fusedBiometricData: Data? // JSON or binary representation of processed biometric data
    public var fusedGenomicData: Data? // JSON or binary representation of processed genomic data
    public var fusedClinicalData: Data? // JSON or binary representation of processed clinical data
    public var fusedLifestyleData: Data? // JSON or binary representation of processed lifestyle data
    public var fusedEnvironmentalData: Data? // JSON or binary representation of processed environmental data
    public var predictiveMarkers: Data? // JSON representation of key predictive markers/features
    public var healthScore: Double // A composite health score
    public var riskAssessments: Data? // JSON representation of various health risk assessments

    public init(id: UUID = UUID(), userId: String, lastUpdated: Date, fusedBiometricData: Data? = nil, fusedGenomicData: Data? = nil, fusedClinicalData: Data? = nil, fusedLifestyleData: Data? = nil, fusedEnvironmentalData: Data? = nil, predictiveMarkers: Data? = nil, healthScore: Double = 0.0, riskAssessments: Data? = nil) {
        self.id = id
        self.userId = userId
        self.lastUpdated = lastUpdated
        self.fusedBiometricData = fusedBiometricData
        self.fusedGenomicData = fusedGenomicData
        self.fusedClinicalData = fusedClinicalData
        self.fusedLifestyleData = fusedLifestyleData
        self.fusedEnvironmentalData = fusedEnvironmentalData
        self.predictiveMarkers = predictiveMarkers
        self.healthScore = healthScore
        self.riskAssessments = riskAssessments
    }
}