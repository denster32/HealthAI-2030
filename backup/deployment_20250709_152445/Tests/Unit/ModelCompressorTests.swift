import XCTest
import CoreML
@testable import Core

final class ModelCompressorTests: XCTestCase {
    func testPruneModel() {
        let dummyModel = MLModel() // Replace with a mock or test model
        let pruned = ModelCompressor.shared.pruneModel(dummyModel, sparsity: 0.5)
        XCTAssertEqual(pruned.sparsity, 0.5)
    }
    
    func testQuantizeModel() {
        let dummyModel = MLModel() // Replace with a mock or test model
        let quantized = ModelCompressor.shared.quantizeModel(dummyModel, precision: .int8)
        XCTAssertEqual(quantized.precision, .int8)
    }
    
    func testDistillModel() {
        let teacher = MLModel() // Replace with a mock or test model
        let student = MLModel() // Replace with a mock or test model
        let distilled = ModelCompressor.shared.distillModel(teacher: teacher, student: student)
        XCTAssertNotNil(distilled)
    }
    
    func testValidateCompressedModel() {
        let dummyModel = MLModel() // Replace with a mock or test model
        let compressed = CompressedModel(model: dummyModel, compressionMethod: "pruning")
        let result = ModelCompressor.shared.validateCompressedModel(compressed)
        XCTAssertTrue(result.isValid)
    }
} 