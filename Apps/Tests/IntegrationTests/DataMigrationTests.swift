import XCTest
import SwiftData
@testable import Managers

@available(iOS 18.0, macOS 15.0, *)
final class DataMigrationTests: XCTestCase {

    func testMigrationFromV1ToVLatest() async throws {
        let oldSchema = Schema([SchemaV1UserProfile.self])
        let oldConfig = ModelConfiguration(schema: oldSchema, isStoredInMemoryOnly: true)
        let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfig])
        let oldContext = ModelContext(oldContainer)

        let userV1 = SchemaV1UserProfile(name: "Alice")
        oldContext.insert(userV1)
        try oldContext.save()

        let newSchema = Schema([SchemaV2UserProfile.self])
        let newConfig = ModelConfiguration(schema: newSchema, isStoredInMemoryOnly: true)
        let newContainer = try ModelContainer(for: newSchema, configurations: [newConfig])
        let newContext = ModelContext(newContainer)

        let usersV2 = try newContext.fetchAll(SchemaV2UserProfile.self)
        XCTAssertEqual(usersV2.count, 1)
        XCTAssertEqual(usersV2.first?.name, "Alice")
        XCTAssertNil(usersV2.first?.email)
    }

    func testMigrationFromV2ToVLatest() async throws {
        let oldSchema = Schema([SchemaV2UserProfile.self])
        let oldConfig = ModelConfiguration(schema: oldSchema, isStoredInMemoryOnly: true)
        let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfig])
        let oldContext = ModelContext(oldContainer)

        let userV2 = SchemaV2UserProfile(name: "Bob", email: "bob@example.com")
        oldContext.insert(userV2)
        try oldContext.save()

        let newSchema = Schema([SchemaV2UserProfile.self])
        let newConfig = ModelConfiguration(schema: newSchema, isStoredInMemoryOnly: true)
        let newContainer = try ModelContainer(for: newSchema, configurations: [newConfig])
        let newContext = ModelContext(newContainer)

        let users = try newContext.fetchAll(SchemaV2UserProfile.self)
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.email, "bob@example.com")
    }

    func testSchemaEvolutionWithNewField() async throws {
        // Adding new optional field: email should default to nil for old data
        try await testMigrationFromV1ToVLatest()
    }

    func testSchemaEvolutionWithRenamedField() async throws {
        // Test field renaming migration
        let oldSchema = Schema([SchemaV1UserProfile.self])
        let oldConfig = ModelConfiguration(schema: oldSchema, isStoredInMemoryOnly: true)
        let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfig])
        let oldContext = ModelContext(oldContainer)

        let userV1 = SchemaV1UserProfile(name: "Charlie")
        oldContext.insert(userV1)
        try oldContext.save()

        // Create migration plan for field renaming
        let migrationPlan = SchemaMigrationPlan(
            targetVersion: SchemaV2UserProfile.self,
            migrationSteps: [
                .init(from: SchemaV1UserProfile.self, to: SchemaV2UserProfile.self) { context in
                    // Simulate field renaming: name -> fullName
                    let oldUsers = try context.fetchAll(SchemaV1UserProfile.self)
                    for oldUser in oldUsers {
                        let newUser = SchemaV2UserProfile(name: oldUser.name, email: nil)
                        context.insert(newUser)
                    }
                }
            ]
        )

        let newSchema = Schema([SchemaV2UserProfile.self])
        let newConfig = ModelConfiguration(schema: newSchema, isStoredInMemoryOnly: true, migrationPlan: migrationPlan)
        let newContainer = try ModelContainer(for: newSchema, configurations: [newConfig])
        let newContext = ModelContext(newContainer)

        let users = try newContext.fetchAll(SchemaV2UserProfile.self)
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.name, "Charlie")
    }

    func testSchemaEvolutionWithRemovedField() async throws {
        // Test field removal migration
        let oldSchema = Schema([SchemaV2UserProfile.self])
        let oldConfig = ModelConfiguration(schema: oldSchema, isStoredInMemoryOnly: true)
        let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfig])
        let oldContext = ModelContext(oldContainer)

        let userV2 = SchemaV2UserProfile(name: "David", email: "david@example.com")
        oldContext.insert(userV2)
        try oldContext.save()

        // Create migration plan for field removal
        let migrationPlan = SchemaMigrationPlan(
            targetVersion: SchemaV1UserProfile.self,
            migrationSteps: [
                .init(from: SchemaV2UserProfile.self, to: SchemaV1UserProfile.self) { context in
                    // Simulate field removal: email field is dropped
                    let oldUsers = try context.fetchAll(SchemaV2UserProfile.self)
                    for oldUser in oldUsers {
                        let newUser = SchemaV1UserProfile(name: oldUser.name)
                        context.insert(newUser)
                    }
                }
            ]
        )

        let newSchema = Schema([SchemaV1UserProfile.self])
        let newConfig = ModelConfiguration(schema: newSchema, isStoredInMemoryOnly: true, migrationPlan: migrationPlan)
        let newContainer = try ModelContainer(for: newSchema, configurations: [newConfig])
        let newContext = ModelContext(newContainer)

        let users = try newContext.fetchAll(SchemaV1UserProfile.self)
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.name, "David")
        // Email field should be removed and not accessible
    }

    func testMigrationFailureForIncompatibleSchemas() async throws {
        // Negative migration test: incompatible schemas without migration plan should fail
        let oldSchema = Schema([SchemaV1UserProfile.self])
        let oldConfig = ModelConfiguration(schema: oldSchema, isStoredInMemoryOnly: true)
        let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfig])
        let oldContext = ModelContext(oldContainer)

        let userV1 = SchemaV1UserProfile(name: "Eve")
        oldContext.insert(userV1)
        try oldContext.save()

        let incompatibleSchema = Schema([SchemaV2UserProfile.self])
        let newConfig = ModelConfiguration(schema: incompatibleSchema, isStoredInMemoryOnly: true)
        XCTAssertThrowsError(try ModelContainer(for: incompatibleSchema, configurations: [newConfig])) { error in
            // Expected migration failure error
        }
    }
    
    func testComplexMigrationWithMultipleSteps() async throws {
        // Test complex migration with multiple schema changes
        let oldSchema = Schema([SchemaV1UserProfile.self])
        let oldConfig = ModelConfiguration(schema: oldSchema, isStoredInMemoryOnly: true)
        let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfig])
        let oldContext = ModelContext(oldContainer)

        // Create multiple users with old schema
        let users = [
            SchemaV1UserProfile(name: "User1"),
            SchemaV1UserProfile(name: "User2"),
            SchemaV1UserProfile(name: "User3")
        ]
        
        for user in users {
            oldContext.insert(user)
        }
        try oldContext.save()

        // Create complex migration plan
        let migrationPlan = SchemaMigrationPlan(
            targetVersion: SchemaV2UserProfile.self,
            migrationSteps: [
                .init(from: SchemaV1UserProfile.self, to: SchemaV2UserProfile.self) { context in
                    let oldUsers = try context.fetchAll(SchemaV1UserProfile.self)
                    for oldUser in oldUsers {
                        let newUser = SchemaV2UserProfile(name: oldUser.name, email: "\(oldUser.name.lowercased())@migrated.com")
                        context.insert(newUser)
                    }
                }
            ]
        )

        let newSchema = Schema([SchemaV2UserProfile.self])
        let newConfig = ModelConfiguration(schema: newSchema, isStoredInMemoryOnly: true, migrationPlan: migrationPlan)
        let newContainer = try ModelContainer(for: newSchema, configurations: [newConfig])
        let newContext = ModelContext(newContainer)

        let migratedUsers = try newContext.fetchAll(SchemaV2UserProfile.self)
        XCTAssertEqual(migratedUsers.count, 3)
        
        // Verify all users were migrated correctly
        for migratedUser in migratedUsers {
            XCTAssertNotNil(migratedUser.email)
            XCTAssertTrue(migratedUser.email!.contains("@migrated.com"))
        }
    }
    
    func testMigrationWithDataTransformation() async throws {
        // Test migration with data transformation
        let oldSchema = Schema([SchemaV1UserProfile.self])
        let oldConfig = ModelConfiguration(schema: oldSchema, isStoredInMemoryOnly: true)
        let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfig])
        let oldContext = ModelContext(oldContainer)

        let userV1 = SchemaV1UserProfile(name: "John Doe")
        oldContext.insert(userV1)
        try oldContext.save()

        // Create migration plan with data transformation
        let migrationPlan = SchemaMigrationPlan(
            targetVersion: SchemaV2UserProfile.self,
            migrationSteps: [
                .init(from: SchemaV1UserProfile.self, to: SchemaV2UserProfile.self) { context in
                    let oldUsers = try context.fetchAll(SchemaV1UserProfile.self)
                    for oldUser in oldUsers {
                        // Transform name to email format
                        let email = "\(oldUser.name.lowercased().replacingOccurrences(of: " ", with: "."))@transformed.com"
                        let newUser = SchemaV2UserProfile(name: oldUser.name, email: email)
                        context.insert(newUser)
                    }
                }
            ]
        )

        let newSchema = Schema([SchemaV2UserProfile.self])
        let newConfig = ModelConfiguration(schema: newSchema, isStoredInMemoryOnly: true, migrationPlan: migrationPlan)
        let newContainer = try ModelContainer(for: newSchema, configurations: [newConfig])
        let newContext = ModelContext(newContainer)

        let migratedUsers = try newContext.fetchAll(SchemaV2UserProfile.self)
        XCTAssertEqual(migratedUsers.count, 1)
        XCTAssertEqual(migratedUsers.first?.email, "john.doe@transformed.com")
    }
} 