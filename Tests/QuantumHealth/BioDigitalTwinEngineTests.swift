import XCTest
import SwiftData
import HealthKit
@testable import QuantumHealth

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
final class BioDigitalTwinEngineTests: XCTestCase {
    
    private var engine: BioDigitalTwinEngine!
    private var modelContext: ModelContext!
    private var modelContainer: ModelContainer!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory SwiftData container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: BioDigitalTwin.self, SimulationResult.self, DiseaseProgressionPrediction.self, configurations: config)
        modelContext = ModelContext(modelContainer)
        
        // Initialize the engine
        engine = try BioDigitalTwinEngine(modelContext: modelContext)
    }
    
    override func tearDownWithError() throws {
        engine = nil
        modelContext = nil
        modelContainer = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testEngineInitialization() throws {
        XCTAssertNotNil(engine)
        XCTAssertEqual(engine.currentStatus, .idle)
        XCTAssertEqual(engine.simulationCount, 0)
        XCTAssertEqual(engine.averageSimulationTime, 0.0)
        XCTAssertEqual(engine.peakMemoryUsage, 0)
    }
    
    func testEngineInitializationWithInvalidContext() throws {
        // Test initialization with invalid context
        XCTAssertThrowsError(try BioDigitalTwinEngine(modelContext: ModelContext(try ModelContainer(for: BioDigitalTwin.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))) { error in
            XCTAssertTrue(error is BioDigitalTwinEngine.BioDigitalTwinError)
        }
    }
    
    // MARK: - Digital Twin Creation Tests
    
    func testCreateDigitalTwinSuccess() async throws {
        // Given
        let healthData = createMockHealthProfile()
        
        // When
        let digitalTwin = try await engine.createDigitalTwin(from: healthData)
        
        // Then
        XCTAssertNotNil(digitalTwin)
        XCTAssertEqual(digitalTwin.patientId, healthData.patientId)
        XCTAssertNotNil(digitalTwin.cardiovascularModel)
        XCTAssertNotNil(digitalTwin.neurologicalModel)
        XCTAssertNotNil(digitalTwin.endocrineModel)
        XCTAssertNotNil(digitalTwin.immuneModel)
        XCTAssertNotNil(digitalTwin.metabolicModel)
        XCTAssertEqual(engine.currentStatus, .idle)
    }
    
    func testCreateDigitalTwinWithInvalidHealthData() async throws {
        // Given
        let invalidHealthData = createInvalidHealthProfile()
        
        // When & Then
        do {
            _ = try await engine.createDigitalTwin(from: invalidHealthData)
            XCTFail("Expected error for invalid health data")
        } catch let error as BioDigitalTwinEngine.BioDigitalTwinError {
            XCTAssertEqual(error, .invalidHealthData("Patient ID cannot be empty"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testCreateDigitalTwinCaching() async throws {
        // Given
        let healthData = createMockHealthProfile()
        
        // When - Create twin twice
        let twin1 = try await engine.createDigitalTwin(from: healthData)
        let twin2 = try await engine.createDigitalTwin(from: healthData)
        
        // Then - Both should be the same (cached)
        XCTAssertEqual(twin1.id, twin2.id)
        XCTAssertEqual(twin1.patientId, twin2.patientId)
    }
    
    // MARK: - Health Scenario Simulation Tests
    
    func testSimulateHealthScenarioSuccess() async throws {
        // Given
        let healthData = createMockHealthProfile()
        let digitalTwin = try await engine.createDigitalTwin(from: healthData)
        let scenario = createMockHealthScenario()
        let duration: TimeInterval = 3600 // 1 hour
        
        // When
        let result = try await engine.simulateHealthScenario(digitalTwin: digitalTwin, scenario: scenario, duration: duration)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result.scenario.name, scenario.name)
        XCTAssertFalse(result.states.isEmpty)
        XCTAssertEqual(engine.currentStatus, .idle)
        XCTAssertEqual(engine.simulationCount, 1)
        XCTAssertGreaterThan(engine.averageSimulationTime, 0.0)
    }
    
    func testSimulateHealthScenarioWithInvalidInputs() async throws {
        // Given
        let healthData = createMockHealthProfile()
        let digitalTwin = try await engine.createDigitalTwin(from: healthData)
        let scenario = createMockHealthScenario()
        let invalidDuration: TimeInterval = -1 // Invalid negative duration
        
        // When & Then
        do {
            _ = try await engine.simulateHealthScenario(digitalTwin: digitalTwin, scenario: scenario, duration: invalidDuration)
            XCTFail("Expected error for invalid duration")
        } catch let error as BioDigitalTwinEngine.BioDigitalTwinError {
            XCTAssertEqual(error, .validationError("Simulation duration must be positive"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testSimulateHealthScenarioCaching() async throws {
        // Given
        let healthData = createMockHealthProfile()
        let digitalTwin = try await engine.createDigitalTwin(from: healthData)
        let scenario = createMockHealthScenario()
        let duration: TimeInterval = 3600
        
        // When - Simulate same scenario twice
        let result1 = try await engine.simulateHealthScenario(digitalTwin: digitalTwin, scenario: scenario, duration: duration)
        let result2 = try await engine.simulateHealthScenario(digitalTwin: digitalTwin, scenario: scenario, duration: duration)
        
        // Then - Results should be the same (cached)
        XCTAssertEqual(result1.scenario.name, result2.scenario.name)
        XCTAssertEqual(result1.states.count, result2.states.count)
    }
    
    // MARK: - Disease Progression Prediction Tests
    
    func testPredictDiseaseProgressionSuccess() async throws {
        // Given
        let healthData = createMockHealthProfile()
        let digitalTwin = try await engine.createDigitalTwin(from: healthData)
        let disease = createMockDiseaseModel()
        let timeframe: TimeInterval = 86400 * 30 // 30 days
        
        // When
        let prediction = try await engine.predictDiseaseProgression(digitalTwin: digitalTwin, disease: disease, timeframe: timeframe)
        
        // Then
        XCTAssertNotNil(prediction)
        XCTAssertEqual(prediction.disease.name, disease.name)
        XCTAssertFalse(prediction.progressionStates.isEmpty)
        XCTAssertEqual(engine.currentStatus, .idle)
    }
    
    func testPredictDiseaseProgressionWithInvalidTimeframe() async throws {
        // Given
        let healthData = createMockHealthProfile()
        let digitalTwin = try await engine.createDigitalTwin(from: healthData)
        let disease = createMockDiseaseModel()
        let invalidTimeframe: TimeInterval = 0 // Invalid zero timeframe
        
        // When & Then
        do {
            _ = try await engine.predictDiseaseProgression(digitalTwin: digitalTwin, disease: disease, timeframe: invalidTimeframe)
            XCTFail("Expected error for invalid timeframe")
        } catch let error as BioDigitalTwinEngine.BioDigitalTwinError {
            XCTAssertEqual(error, .validationError("Prediction timeframe must be positive"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Treatment Optimization Tests
    
    func testOptimizeTreatmentSuccess() async throws {
        // Given
        let healthData = createMockHealthProfile()
        let digitalTwin = try await engine.createDigitalTwin(from: healthData)
        let condition = createMockMedicalCondition()
        let treatments = createMockTreatments()
        
        // When
        let result = try await engine.optimizeTreatment(digitalTwin: digitalTwin, condition: condition, availableTreatments: treatments)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertFalse(result.treatmentEvaluations.isEmpty)
        XCTAssertEqual(engine.currentStatus, .idle)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeSimulation() async throws {
        // Given
        let healthData = createMockHealthProfile()
        let digitalTwin = try await engine.createDigitalTwin(from: healthData)
        let scenario = createMockHealthScenario()
        let duration: TimeInterval = 86400 * 7 // 1 week simulation
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await engine.simulateHealthScenario(digitalTwin: digitalTwin, scenario: scenario, duration: duration)
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result.states.count, 1000) // Should have many states
        XCTAssertLessThan(executionTime, 30.0) // Should complete within 30 seconds
    }
    
    func testMemoryUsageUnderLoad() async throws {
        // Given
        let healthData = createMockHealthProfile()
        let digitalTwin = try await engine.createDigitalTwin(from: healthData)
        let scenario = createMockHealthScenario()
        
        // When - Run multiple simulations
        let initialMemory = engine.peakMemoryUsage
        
        for _ in 0..<5 {
            _ = try await engine.simulateHealthScenario(digitalTwin: digitalTwin, scenario: scenario, duration: 3600)
        }
        
        let finalMemory = engine.peakMemoryUsage
        
        // Then - Memory usage should be reasonable
        XCTAssertGreaterThan(finalMemory, initialMemory)
        XCTAssertLessThan(finalMemory, 500 * 1024 * 1024) // Less than 500MB
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingForSystemFailures() async throws {
        // Given - Create engine with invalid system components
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: BioDigitalTwin.self, configurations: config)
        let context = ModelContext(container)
        
        // When & Then - Should handle system initialization errors gracefully
        XCTAssertThrowsError(try BioDigitalTwinEngine(modelContext: context)) { error in
            XCTAssertTrue(error is BioDigitalTwinEngine.BioDigitalTwinError)
        }
    }
    
    func testErrorRecoveryAfterFailure() async throws {
        // Given
        let healthData = createMockHealthProfile()
        
        // When - First call succeeds
        let twin1 = try await engine.createDigitalTwin(from: healthData)
        
        // Then - Engine should recover and be ready for next operation
        XCTAssertEqual(engine.currentStatus, .idle)
        
        // When - Second call also succeeds
        let twin2 = try await engine.createDigitalTwin(from: healthData)
        
        // Then - Both operations should work
        XCTAssertEqual(twin1.patientId, twin2.patientId)
        XCTAssertEqual(engine.currentStatus, .idle)
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentDigitalTwinCreation() async throws {
        // Given
        let healthData1 = createMockHealthProfile()
        let healthData2 = createMockHealthProfile()
        
        // When - Create twins concurrently
        async let twin1 = engine.createDigitalTwin(from: healthData1)
        async let twin2 = engine.createDigitalTwin(from: healthData2)
        
        let (result1, result2) = try await (twin1, twin2)
        
        // Then - Both should succeed
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertNotEqual(result1.id, result2.id)
        XCTAssertEqual(engine.currentStatus, .idle)
    }
    
    func testConcurrentSimulations() async throws {
        // Given
        let healthData = createMockHealthProfile()
        let digitalTwin = try await engine.createDigitalTwin(from: healthData)
        let scenario1 = createMockHealthScenario()
        let scenario2 = createMockHealthScenario()
        
        // When - Run simulations concurrently
        async let sim1 = engine.simulateHealthScenario(digitalTwin: digitalTwin, scenario: scenario1, duration: 1800)
        async let sim2 = engine.simulateHealthScenario(digitalTwin: digitalTwin, scenario: scenario2, duration: 1800)
        
        let (result1, result2) = try await (sim1, sim2)
        
        // Then - Both should succeed
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(engine.simulationCount, 2)
    }
    
    // MARK: - SwiftData Integration Tests
    
    func testSwiftDataPersistence() async throws {
        // Given
        let healthData = createMockHealthProfile()
        
        // When
        let digitalTwin = try await engine.createDigitalTwin(from: healthData)
        
        // Then - Should be saved to SwiftData
        let fetchDescriptor = FetchDescriptor<BioDigitalTwin>()
        let savedTwins = try modelContext.fetch(fetchDescriptor)
        XCTAssertTrue(savedTwins.contains { $0.id == digitalTwin.id })
    }
    
    // MARK: - Helper Methods
    
    private func createMockHealthProfile() -> HealthProfile {
        return HealthProfile(
            patientId: "test-patient-\(UUID().uuidString)",
            cardiovascularData: CardiovascularData(),
            neurologicalData: NeurologicalData(),
            endocrineData: EndocrineData(),
            immuneData: ImmuneData(),
            metabolicData: MetabolicData(),
            lastUpdated: Date()
        )
    }
    
    private func createInvalidHealthProfile() -> HealthProfile {
        return HealthProfile(
            patientId: "", // Invalid empty ID
            cardiovascularData: CardiovascularData(),
            neurologicalData: NeurologicalData(),
            endocrineData: EndocrineData(),
            immuneData: ImmuneData(),
            metabolicData: MetabolicData(),
            lastUpdated: Date()
        )
    }
    
    private func createMockHealthScenario() -> HealthScenario {
        return HealthScenario(
            name: "Test Scenario",
            description: "A test health scenario",
            duration: 3600,
            complexity: 0.5
        )
    }
    
    private func createMockDiseaseModel() -> DiseaseModel {
        return DiseaseModel(
            name: "Test Disease",
            description: "A test disease model",
            currentSymptoms: [],
            progressionRate: 0.1,
            severity: 0.5
        )
    }
    
    private func createMockMedicalCondition() -> MedicalCondition {
        return MedicalCondition(
            name: "Test Condition",
            description: "A test medical condition",
            severity: 0.5,
            affectedSystems: [.cardiovascular, .neurological]
        )
    }
    
    private func createMockTreatments() -> [Treatment] {
        return [
            Treatment(name: "Treatment A", description: "First treatment option", cost: 1000),
            Treatment(name: "Treatment B", description: "Second treatment option", cost: 2000),
            Treatment(name: "Treatment C", description: "Third treatment option", cost: 1500)
        ]
    }
}

// MARK: - Mock Data Structures

struct CardiovascularData {
    let heartRate: Double = 72.0
    let bloodPressure: (systolic: Double, diastolic: Double) = (120.0, 80.0)
    let cardiacOutput: Double = 5.0
}

struct NeurologicalData {
    let brainActivity: Double = 0.8
    let cognitiveFunction: Double = 0.9
    let stressLevel: Double = 0.3
}

struct EndocrineData {
    let insulinLevel: Double = 5.0
    let cortisolLevel: Double = 15.0
    let thyroidLevel: Double = 2.5
}

struct ImmuneData {
    let whiteBloodCellCount: Double = 7000.0
    let antibodyLevel: Double = 0.7
    let inflammationLevel: Double = 0.2
}

struct MetabolicData {
    let glucoseLevel: Double = 100.0
    let cholesterolLevel: Double = 180.0
    let metabolicRate: Double = 1500.0
}

struct HealthProfile {
    let patientId: String
    let cardiovascularData: CardiovascularData
    let neurologicalData: NeurologicalData
    let endocrineData: EndocrineData
    let immuneData: ImmuneData
    let metabolicData: MetabolicData
    let lastUpdated: Date
}

struct HealthScenario {
    let name: String
    let description: String
    let duration: TimeInterval
    let complexity: Double
}

struct DiseaseModel {
    let name: String
    let description: String
    let currentSymptoms: [Symptom]
    let progressionRate: Double
    let severity: Double
}

struct MedicalCondition {
    let name: String
    let description: String
    let severity: Double
    let affectedSystems: [BodySystem]
}

struct Treatment {
    let name: String
    let description: String
    let cost: Double
}

struct Symptom {
    let name: String
    let severity: Double
}

enum BodySystem: String, CaseIterable {
    case cardiovascular = "cardiovascular"
    case neurological = "neurological"
    case endocrine = "endocrine"
    case immune = "immune"
    case metabolic = "metabolic"
} 