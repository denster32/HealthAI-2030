import Foundation
import SwiftData

@Model
final class SchemaV2UserProfile {
    @Attribute var id: UUID
    @Attribute var name: String
    @Attribute var email: String? // new optional field

    init(name: String, email: String? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
    }
} 