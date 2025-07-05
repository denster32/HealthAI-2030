import Foundation

public struct MentalHealthScore: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let score: Double
    public let context: String?
    public let notes: String?
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), score: Double, context: String? = nil, notes: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.score = score
        self.context = context
        self.notes = notes
    }
}
