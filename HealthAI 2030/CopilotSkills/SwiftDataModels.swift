import Foundation
import SwiftData

@Model
final class SkillState: Identifiable {
    @Attribute(.unique) var id: String
    var isEnabled: Bool
    var lastStatus: String
    var lastUpdated: Date
    
    init(id: String, isEnabled: Bool = true, lastStatus: String = "healthy", lastUpdated: Date = Date()) {
        self.id = id
        self.isEnabled = isEnabled
        self.lastStatus = lastStatus
        self.lastUpdated = lastUpdated
    }
}

@Model
final class CopilotChatMessage: Identifiable {
    @Attribute(.unique) var id: UUID
    var role: String
    var content: String
    var timestamp: Date
    
    init(role: String, content: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
