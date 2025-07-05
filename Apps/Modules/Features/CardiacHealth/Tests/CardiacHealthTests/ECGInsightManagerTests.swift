import XCTest
@testable import CardiacHealth

final class ECGInsightManagerTests: XCTestCase {
    var insightManager: ECGInsightManager!
    var mockHealthDataManager: MockHealthDataManager!
    
    override func setUp() {
        super.setUp()
        mockHealthDataManager = MockHealthDataManager()
        insightManager = ECGInsightManager()
        // Inject mock dependencies
        insightManager.healthDataManager = mockHealthDataManager
    }
    
    override func tearDown() {
        insightManager = nil
        mockHealthDataManager = nil
        super.tearDown()
    }
    
    func testStartAnalysis_WithoutPermissions_ReturnsPermissionDenied() async {
        // Arrange
        mockHealthDataManager.shouldGrantPermission = false
        
        // Act
        await insightManager.startAnalysis()
        
        // Assert
        XCTAssertEqual(insightManager.status, .permissionDenied)
        XCTAssertTrue(insightManager.insights.isEmpty)
    }
    
    func testStartAnalysis_WithPermissions_GeneratesInsights() async {
        // Arrange
        mockHealthDataManager.shouldGrantPermission = true
        mockHealthDataManager.currentECGData = ECGData()
        
        // Act
        await insightManager.startAnalysis()
        
        // Assert
        XCTAssertEqual(insightManager.status, .completed)
        XCTAssertFalse(insightManager.insights.isEmpty)
        
        // Verify we got insights for each type of analysis
        let insightTypes = insightManager.insights.map { $0.type }
        XCTAssertTrue(insightTypes.contains(.beatMorphology))
        XCTAssertTrue(insightTypes.contains(.hrtTurbulence))
        XCTAssertTrue(insightTypes.contains(.qtDynamics))
        XCTAssertTrue(insightTypes.contains(.stSegment))
        XCTAssertTrue(insightTypes.contains(.afForecast))
    }
    
    func testInsightSeverityProcessing() async {
        // Arrange
        mockHealthDataManager.shouldGrantPermission = true
        mockHealthDataManager.currentECGData = ECGData()
        
        // Act
        await insightManager.startAnalysis()
        
        // Assert
        XCTAssertFalse(insightManager.criticalInsights.isEmpty)
        XCTAssertTrue(insightManager.criticalInsights.allSatisfy { $0.severity == .critical })
        XCTAssertTrue(insightManager.warningInsights.allSatisfy { $0.severity == .warning })
        XCTAssertTrue(insightManager.infoInsights.allSatisfy { $0.severity == .info })
    }
}

// MARK: - Mock Objects
class MockHealthDataManager: HealthDataManager {
    var shouldGrantPermission = true
    override func requestECGPermissions(_ completion: @escaping (Bool) -> Void) {
        completion(shouldGrantPermission)
    }
}
