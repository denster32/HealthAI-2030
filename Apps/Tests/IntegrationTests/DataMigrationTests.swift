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
        // TODO: Implement rename migration test
        XCTFail("Rename migration test not implemented")
    }

    func testSchemaEvolutionWithRemovedField() async throws {
        // TODO: Implement remove field migration test
        XCTFail("Remove field migration test not implemented")
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
} 