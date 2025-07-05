import Foundation

public struct HealthAutomationRule: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let condition: String // e.g., predicate or DSL
    public let action: String // e.g., action identifier or script
    public let isEnabled: Bool
    public let created: Date
    public let modified: Date
    
    public init(id: UUID = UUID(), name: String, condition: String, action: String, isEnabled: Bool = true, created: Date = Date(), modified: Date = Date()) {
        self.id = id
        self.name = name
        self.condition = condition
        self.action = action
        self.isEnabled = isEnabled
        self.created = created
        self.modified = modified
    }
}
