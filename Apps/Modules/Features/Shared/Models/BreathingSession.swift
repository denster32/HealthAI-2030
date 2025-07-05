import Foundation

public struct BreathingSession: Identifiable, Codable {
    public let id: UUID
    public let startTime: Date
    public let endTime: Date?
    public let pattern: String
    public let duration: TimeInterval
    public let notes: String?
    
    public init(id: UUID = UUID(), startTime: Date = Date(), endTime: Date? = nil, pattern: String, duration: TimeInterval, notes: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.pattern = pattern
        self.duration = duration
        self.notes = notes
    }
}
