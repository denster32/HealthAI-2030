import XCTest
@testable import HealthAI2030Core

final class DataIntegrityManagerTests: XCTestCase {
    struct DummyModel: Codable, Identifiable, Equatable {
        let id: UUID
        var value: Int
        var name: String
    }

    func testChecksumValidationDetectsAlteration() {
        let manager = DataIntegrityManager.shared
        var model = DummyModel(id: UUID(), value: 42, name: "Original")
        let checksum = manager.computeChecksum(model)
        
        // Should validate with original data
        XCTAssertTrue(manager.validateDataIntegrity(model, storedChecksum: checksum), "Checksum should validate for original data")
        
        // Alter the model
        model.value = 99
        
        // Should fail validation after alteration
        XCTAssertFalse(manager.validateDataIntegrity(model, storedChecksum: checksum), "Checksum validation should fail after data alteration")
    }
} 