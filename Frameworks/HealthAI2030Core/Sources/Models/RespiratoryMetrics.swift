import Foundation

public struct RespiratoryMetrics: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let oxygenSaturation: Double? // Percentage
    public let respiratoryRate: Double? // Breaths per minute
    public let inhaledAirQuality: Double? // Placeholder for air quality index
    
    public init(id: UUID = UUID(), date: Date = Date(), oxygenSaturation: Double? = nil, respiratoryRate: Double? = nil, inhaledAirQuality: Double? = nil) {
        self.id = id
        self.date = date
        self.oxygenSaturation = oxygenSaturation
        self.respiratoryRate = respiratoryRate
        self.inhaledAirQuality = inhaledAirQuality
    }
}
