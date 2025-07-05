import XCTest
@testable import ML

@available(macOS 14.0, *)
@available(iOS 17.0, *)
final class CoreMLIntegrationManagerTests: XCTestCase {
    func testModelInitialization() async {
        let manager = CoreMLIntegrationManager.shared
        // Wait briefly for async init
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertTrue(manager.isModelInitialized || manager.coreMLLoadError != nil, "Model should attempt to initialize")
    }

    func testPredictSleepStageWithoutData() {
        let manager = CoreMLIntegrationManager.shared
        let result = manager.predictSleepStage(from: [])
        XCTAssertEqual(result.stage, .unknown)
        XCTAssertEqual(result.confidence, 0.0)
    }
}
