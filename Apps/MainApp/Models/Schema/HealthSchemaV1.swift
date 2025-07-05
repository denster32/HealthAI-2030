import Foundation
import SwiftData

/// Schema version 1.0 for HealthAI 2030 data models
/// This defines the initial schema structure for all SwiftData models
public enum HealthSchemaV1 {
    
    /// The schema containing all data models for version 1.0
    public static let schema = Schema([
        UserProfile.self,
        HealthData.self,
        DigitalTwin.self
    ])
    
    /// Schema version identifier
    public static let version = Schema.Version(1, 0, 0)
    
    /// Migration plan for future schema updates
    public static let migrationPlan = SchemaMigrationPlan(
        targetVersion: version,
        migrationSteps: [
            // Future migration steps will be added here
            // Example: SchemaMigrationStep(from: Schema.Version(1, 0, 0), to: Schema.Version(1, 1, 0)) { context in
            //     // Migration logic
            // }
        ]
    )
}

/// Schema configuration for the app
public struct HealthSchemaConfiguration {
    
    /// Creates a model container with the current schema
    public static func createModelContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: HealthSchemaV1.schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        
        return try ModelContainer(
            for: HealthSchemaV1.schema,
            migrationPlan: HealthSchemaV1.migrationPlan,
            configurations: config
        )
    }
    
    /// Creates a model container for testing (in-memory only)
    public static func createTestModelContainer() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: HealthSchemaV1.schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(
            for: HealthSchemaV1.schema,
            configurations: config
        )
    }
} 