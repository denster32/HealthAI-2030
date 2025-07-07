import Foundation
import SwiftData

@Model
final class SchemaV1UserProfile {
    @Attribute var id: UUID
    @Attribute var name: String

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
} 