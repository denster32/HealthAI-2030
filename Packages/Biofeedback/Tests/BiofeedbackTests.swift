import XCTest
@testable import Biofeedback

final class BiofeedbackTests: XCTestCase {
    
    func testBiofeedbackEngineInitialization() {
        // Test that BiofeedbackEngine can be initialized
        let engine = BiofeedbackEngine()
        XCTAssertNotNil(engine)
        XCTAssertEqual(engine.biofeedbackStatus, .idle)
    }
    
    func testBiofeedbackSessionCreation() {
        // Test BiofeedbackSession creation
        let session = BiofeedbackSession(
            name: "Test Session",
            duration: 300,
            sessionType: .meditation,
            protocol: .heartRateVariability
        )
        
        XCTAssertEqual(session.name, "Test Session")
        XCTAssertEqual(session.duration, 300)
        XCTAssertEqual(session.sessionType, .meditation)
        XCTAssertEqual(session.protocol, .heartRateVariability)
    }
    
    func testBiofeedbackProtocols() {
        // Test all biofeedback protocols are available
        let protocols = BiofeedbackProtocol.allCases
        XCTAssertEqual(protocols.count, 4)
        XCTAssertTrue(protocols.contains(.heartRateVariability))
        XCTAssertTrue(protocols.contains(.breathing))
        XCTAssertTrue(protocols.contains(.stressReduction))
        XCTAssertTrue(protocols.contains(.performance))
    }
    
    func testBiofeedbackAudioZoneCreation() {
        // Test BiofeedbackAudioZone creation
        let position = BiofeedbackSpatialPosition(x: 1.0, y: 2.0, z: 3.0)
        let audioSource = BiofeedbackAudioSource(
            fileName: "test_audio",
            fileExtension: "wav",
            category: .nature
        )
        
        let zone = BiofeedbackAudioZone(
            position: position,
            audioSource: audioSource,
            intensityRange: 0.0...1.0,
            biofeedbackType: .heartRate
        )
        
        XCTAssertEqual(zone.position.x, 1.0)
        XCTAssertEqual(zone.position.y, 2.0)
        XCTAssertEqual(zone.position.z, 3.0)
        XCTAssertEqual(zone.audioSource.fileName, "test_audio")
        XCTAssertEqual(zone.biofeedbackType, .heartRate)
    }
    
    func testBiofeedbackParameters() {
        // Test BiofeedbackParameters creation
        let parameters = BiofeedbackParameters(
            heartRate: 75.0,
            breathingRate: 16.0,
            stressLevel: 0.3,
            coherenceLevel: 0.8,
            hrv: 45.0
        )
        
        XCTAssertEqual(parameters.heartRate, 75.0)
        XCTAssertEqual(parameters.breathingRate, 16.0)
        XCTAssertEqual(parameters.stressLevel, 0.3)
        XCTAssertEqual(parameters.coherenceLevel, 0.8)
        XCTAssertEqual(parameters.hrv, 45.0)
    }
    
    static var allTests = [
        ("testBiofeedbackEngineInitialization", testBiofeedbackEngineInitialization),
        ("testBiofeedbackSessionCreation", testBiofeedbackSessionCreation),
        ("testBiofeedbackProtocols", testBiofeedbackProtocols),
        ("testBiofeedbackAudioZoneCreation", testBiofeedbackAudioZoneCreation),
        ("testBiofeedbackParameters", testBiofeedbackParameters)
    ]
} 