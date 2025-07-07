import XCTest
@testable import HealthAI2030App

final class ErrorTaxonomyTests: XCTestCase {
    func testTelemetryErrorGenerateCode() {
        let code = TelemetryError.data.generateErrorCode(subCategory: "MISSING_DATA", specific: "UserID")
        XCTAssertEqual(code, "DATA-MISSING_DATA-UserID")
    }

    func testPredictionErrorGenerateCode() {
        let code = PredictionError.scoreCalculation.generateErrorCode(specific: "ValueOutOfRange")
        XCTAssertEqual(code, "PREDICTION-SCORE_CALCULATION-ValueOutOfRange")
    }

    func testErrorContextDefaults() {
        let context = ErrorContext(code: "SYS-CPU_ERROR-001", message: "CPU Overload")
        XCTAssertEqual(context.code, "SYS-CPU_ERROR-001")
        XCTAssertEqual(context.message, "CPU Overload")
        XCTAssertEqual(context.severity.rawValue, ErrorContext.SeverityLevel.medium.rawValue)
        XCTAssertNotNil(context.timestamp)
        XCTAssertNil(context.stackTrace)
    }

    func testErrorContextMetadataAndStackTrace() {
        let metadata: [String: Any] = ["key": "value"]
        let context = ErrorContext(
            code: "SYS-NETWORK_ERROR-002",
            message: "Network down",
            severity: .critical,
            metadata: metadata,
            stackTrace: "frame1\nframe2"
        )
        XCTAssertEqual(context.severity, .critical)
        XCTAssertEqual(context.metadata["key"] as? String, "value")
        XCTAssertEqual(context.stackTrace, "frame1\nframe2")
    }
} 