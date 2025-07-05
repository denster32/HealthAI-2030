import Foundation

public enum MoodType: String, Codable, CaseIterable {
    case happy, sad, anxious, calm, angry, excited, tired, neutral
}

public struct MoodEntry: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let mood: MoodType
    public let notes: String?
}

public enum MoodType: String, CaseIterable, Codable {
    case happy = "Happy"
    case sad = "Sad"
    case anxious = "Anxious"
    case calm = "Calm"
    case energetic = "Energetic"
    case tired = "Tired"
}
