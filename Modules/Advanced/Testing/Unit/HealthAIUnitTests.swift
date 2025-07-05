import XCTest
import Foundation
import Combine
@testable import HealthAI2030

// MARK: - HealthAI Unit Tests

final class HealthAIUnitTests: XCTestCase {
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private var mockDataProcessor: MockHealthDataProcessor!
    private var mockPredictionService: MockHealthPredictionService!
    private var mockAnalyticsService: MockHealthAnalyticsService!
    private var mockStorageService: MockHealthStorageService!
    private var healthAICore: HealthAICoreService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        setupMockServices()
        setupHealthAICore()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        healthAICore = nil
        mockDataProcessor = nil
        mockPredictionService = nil
        mockAnalyticsService = nil
        mockStorageService = nil
        super.tearDown()
    }
    
    // MARK: - Setup Methods
    
    private func setupMockServices() {
        mockDataProcessor = MockHealthDataProcessor()
        mockPredictionService = MockHealthPredictionService()
        mockAnalyticsService = MockHealthAnalyticsService()
        mockStorageService = MockHealthStorageService()
    }
    
    private func setupHealthAICore() {
        healthAICore = HealthAICoreService(
            dataProcessor: mockDataProcessor,
            predictionService: mockPredictionService,
            analyticsService: mockAnalyticsService,
            storageService: mockStorageService
        )
    }
    
    // MARK: - Health Data Processing Tests
    
    func testHealthDataProcessing() async throws {
        // Given
        let healthData = createSampleHealthData()
        mockDataProcessor.processResult = createSampleProcessedData()
        
        // When
        try await healthAICore.processHealthData(healthData)
        
        // Then
        XCTAssertTrue(mockDataProcessor.processCalled)
        XCTAssertEqual(mockDataProcessor.processedData, healthData)
        XCTAssertTrue(mockStorageService.storeCalled)
    }
    
    func testHealthDataValidation() async throws {
        // Given
        let invalidHealthData = createInvalidHealthData()
        mockDataProcessor.processError = HealthDataError.invalidData
        
        // When & Then
        do {
            try await healthAICore.processHealthData(invalidHealthData)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is HealthDataError)
        }
    }
    
    // MARK: - Health Status Calculation Tests
    
    func testHealthStatusCalculationExcellent() async throws {
        // Given
        let excellentMetrics = createExcellentHealthMetrics()
        mockStorageService.latestDataResult = ProcessedHealthData(
            originalData: HealthData(),
            metrics: excellentMetrics,
            quality: .high
        )
        
        // When
        try await healthAICore.updateHealthStatus()
        
        // Then
        XCTAssertEqual(healthAICore.currentHealthStatus, .excellent)
    }
    
    func testHealthStatusCalculationPoor() async throws {
        // Given
        let poorMetrics = createPoorHealthMetrics()
        mockStorageService.latestDataResult = ProcessedHealthData(
            originalData: HealthData(),
            metrics: poorMetrics,
            quality: .high
        )
        
        // When
        try await healthAICore.updateHealthStatus()
        
        // Then
        XCTAssertEqual(healthAICore.currentHealthStatus, .poor)
    }
    
    // MARK: - Insights Generation Tests
    
    func testInsightsGeneration() async throws {
        // Given
        let processedData = createSampleProcessedData()
        let expectedInsights = createSampleInsights()
        mockAnalyticsService.insightsResult = expectedInsights
        
        // When
        let insights = try await healthAICore.generateInsights(from: processedData)
        
        // Then
        XCTAssertEqual(insights.count, expectedInsights.count)
        XCTAssertEqual(insights.first?.title, expectedInsights.first?.title)
    }
    
    // MARK: - Recommendations Tests
    
    func testRecommendationsGeneration() async throws {
        // Given
        let expectedRecommendations = createSampleRecommendations()
        mockPredictionService.recommendationsResult = expectedRecommendations
        
        // When
        let recommendations = try await healthAICore.getRecommendations()
        
        // Then
        XCTAssertEqual(recommendations.count, expectedRecommendations.count)
        XCTAssertEqual(recommendations.first?.title, expectedRecommendations.first?.title)
    }
    
    // MARK: - Service Health Tests
    
    func testServiceHealthCheck() async {
        // When
        let healthStatus = await healthAICore.healthCheck()
        
        // Then
        XCTAssertTrue(healthStatus.isHealthy)
        XCTAssertGreaterThan(healthStatus.responseTime, 0)
        XCTAssertEqual(healthStatus.errorCount, 0)
    }
    
    func testServiceInitialization() async throws {
        // When
        try await healthAICore.initialize()
        
        // Then
        XCTAssertTrue(healthAICore.isActive)
        XCTAssertTrue(mockDataProcessor.initializeCalled)
        XCTAssertTrue(mockPredictionService.initializeCalled)
        XCTAssertTrue(mockAnalyticsService.initializeCalled)
        XCTAssertTrue(mockStorageService.initializeCalled)
    }
    
    func testServiceShutdown() async throws {
        // Given
        try await healthAICore.initialize()
        
        // When
        try await healthAICore.shutdown()
        
        // Then
        XCTAssertFalse(healthAICore.isActive)
        XCTAssertTrue(mockDataProcessor.shutdownCalled)
        XCTAssertTrue(mockPredictionService.shutdownCalled)
        XCTAssertTrue(mockAnalyticsService.shutdownCalled)
        XCTAssertTrue(mockStorageService.shutdownCalled)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingDuringProcessing() async {
        // Given
        let healthData = createSampleHealthData()
        mockDataProcessor.processError = HealthDataError.processingFailed
        
        // When & Then
        do {
            try await healthAICore.processHealthData(healthData)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is HealthDataError)
        }
    }
    
    func testErrorHandlingDuringInsightsGeneration() async {
        // Given
        let processedData = createSampleProcessedData()
        mockAnalyticsService.insightsError = AnalyticsError.generationFailed
        
        // When & Then
        do {
            _ = try await healthAICore.generateInsights(from: processedData)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AnalyticsError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testDataProcessingPerformance() {
        // Given
        let healthData = createSampleHealthData()
        mockDataProcessor.processResult = createSampleProcessedData()
        
        // When & Then
        measure {
            let expectation = XCTestExpectation(description: "Data processing")
            
            Task {
                try await healthAICore.processHealthData(healthData)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testInsightsGenerationPerformance() {
        // Given
        let processedData = createSampleProcessedData()
        mockAnalyticsService.insightsResult = createSampleInsights()
        
        // When & Then
        measure {
            let expectation = XCTestExpectation(description: "Insights generation")
            
            Task {
                _ = try await healthAICore.generateInsights(from: processedData)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSampleHealthData() -> HealthData {
        return HealthData(
            timestamp: Date(),
            heartRate: 75,
            bloodPressure: BloodPressure(systolic: 120, diastolic: 80),
            temperature: 36.8,
            steps: 8500,
            sleepHours: 7.5,
            waterIntake: 2.0,
            calories: 2000,
            mood: .good
        )
    }
    
    private func createInvalidHealthData() -> HealthData {
        return HealthData(
            timestamp: Date(),
            heartRate: -50, // Invalid heart rate
            bloodPressure: nil,
            temperature: nil,
            steps: nil,
            sleepHours: nil,
            waterIntake: nil,
            calories: nil,
            mood: nil
        )
    }
    
    private func createSampleProcessedData() -> ProcessedHealthData {
        return ProcessedHealthData(
            originalData: createSampleHealthData(),
            metrics: createExcellentHealthMetrics(),
            quality: .high
        )
    }
    
    private func createExcellentHealthMetrics() -> HealthMetrics {
        var metrics = HealthMetrics()
        metrics.heartRate = 65
        metrics.dailySteps = 12000
        metrics.sleepHours = 8.0
        metrics.waterIntake = 2.5
        metrics.healthScore = 0.95
        return metrics
    }
    
    private func createPoorHealthMetrics() -> HealthMetrics {
        var metrics = HealthMetrics()
        metrics.heartRate = 95
        metrics.dailySteps = 2000
        metrics.sleepHours = 4.0
        metrics.waterIntake = 0.5
        metrics.healthScore = 0.25
        return metrics
    }
    
    private func createSampleInsights() -> [AnalyticsInsight] {
        return [
            AnalyticsInsight(
                title: "Improved Sleep Pattern",
                description: "Your sleep quality has improved by 15% over the last week",
                confidence: 0.92,
                actionable: true
            ),
            AnalyticsInsight(
                title: "Increased Activity",
                description: "Your daily step count has increased by 20%",
                confidence: 0.88,
                actionable: true
            )
        ]
    }
    
    private func createSampleRecommendations() -> [PredictionRecommendation] {
        return [
            PredictionRecommendation(
                title: "Increase Daily Steps",
                description: "Aim for 10,000 steps daily to improve cardiovascular health",
                priority: 0.85
            ),
            PredictionRecommendation(
                title: "Improve Sleep Quality",
                description: "Maintain a consistent sleep schedule for better health",
                priority: 0.75
            )
        ]
    }
}

// MARK: - Mock Services

class MockHealthDataProcessor: HealthDataProcessorProtocol {
    var processCalled = false
    var processedData: HealthData?
    var processResult: ProcessedHealthData?
    var processError: Error?
    
    var dataProcessedPublisher: AnyPublisher<ProcessedHealthData, Never> {
        return PassthroughSubject<ProcessedHealthData, Never>().eraseToAnyPublisher()
    }
    
    func process(_ input: HealthData) async throws -> ProcessedHealthData {
        processCalled = true
        processedData = input
        
        if let error = processError {
            throw error
        }
        
        return processResult ?? ProcessedHealthData(
            originalData: input,
            metrics: HealthMetrics(),
            quality: .high
        )
    }
    
    func validate(_ input: HealthData) async throws -> Bool {
        return processError == nil
    }
    
    func initialize() async throws {
        initializeCalled = true
    }
    
    func shutdown() async throws {
        shutdownCalled = true
    }
    
    func healthCheck() async -> ServiceHealthStatus {
        return ServiceHealthStatus(
            isHealthy: true,
            lastCheck: Date(),
            responseTime: 0.1,
            errorCount: 0
        )
    }
    
    var initializeCalled = false
    var shutdownCalled = false
}

class MockHealthPredictionService: HealthPredictionServiceProtocol {
    var predictCalled = false
    var trainCalled = false
    var recommendationsResult: [PredictionRecommendation] = []
    
    var predictionUpdatedPublisher: AnyPublisher<HealthPrediction, Never> {
        return PassthroughSubject<HealthPrediction, Never>().eraseToAnyPublisher()
    }
    
    func predict(_ input: ProcessedHealthData) async throws -> HealthPrediction {
        predictCalled = true
        return HealthPrediction(
            type: .heartRate,
            value: 75.0,
            confidence: 0.85,
            timeframe: 24 * 3600,
            timestamp: Date()
        )
    }
    
    func train(with data: [ProcessedHealthData]) async throws {
        trainCalled = true
    }
    
    func evaluate(accuracy: [ProcessedHealthData]) async throws -> PredictionAccuracy {
        return PredictionAccuracy(
            accuracy: 0.85,
            precision: 0.82,
            recall: 0.88,
            f1Score: 0.85
        )
    }
    
    func getRecommendations() async throws -> [PredictionRecommendation] {
        return recommendationsResult
    }
    
    func initialize() async throws {
        initializeCalled = true
    }
    
    func shutdown() async throws {
        shutdownCalled = true
    }
    
    func healthCheck() async -> ServiceHealthStatus {
        return ServiceHealthStatus(
            isHealthy: true,
            lastCheck: Date(),
            responseTime: 0.1,
            errorCount: 0
        )
    }
    
    var initializeCalled = false
    var shutdownCalled = false
}

class MockHealthAnalyticsService: HealthAnalyticsServiceProtocol {
    var insightsResult: [AnalyticsInsight] = []
    var insightsError: Error?
    
    func generateInsights(from data: ProcessedHealthData) async throws -> [AnalyticsInsight] {
        if let error = insightsError {
            throw error
        }
        return insightsResult
    }
    
    func trackEvent(_ event: AnalyticsEvent) async throws {
        // Mock implementation
    }
    
    func generateReport(for period: DateInterval) async throws -> AnalyticsReport {
        return AnalyticsReport(
            period: period,
            metrics: [:],
            insights: []
        )
    }
    
    func getInsights() async throws -> [AnalyticsInsight] {
        return insightsResult
    }
    
    func initialize() async throws {
        initializeCalled = true
    }
    
    func shutdown() async throws {
        shutdownCalled = true
    }
    
    func healthCheck() async -> ServiceHealthStatus {
        return ServiceHealthStatus(
            isHealthy: true,
            lastCheck: Date(),
            responseTime: 0.1,
            errorCount: 0
        )
    }
    
    var initializeCalled = false
    var shutdownCalled = false
}

class MockHealthStorageService: HealthStorageServiceProtocol {
    var storeCalled = false
    var retrieveCalled = false
    var latestDataResult: ProcessedHealthData?
    
    func store(_ data: ProcessedHealthData) async throws {
        storeCalled = true
    }
    
    func retrieve(id: String) async throws -> ProcessedHealthData? {
        retrieveCalled = true
        return latestDataResult
    }
    
    func delete(id: String) async throws {
        // Mock implementation
    }
    
    func query(filter: DataFilter) async throws -> [ProcessedHealthData] {
        return []
    }
    
    func getLatestData() async throws -> ProcessedHealthData {
        return latestDataResult ?? ProcessedHealthData(
            originalData: HealthData(),
            metrics: HealthMetrics(),
            quality: .high
        )
    }
    
    func initialize() async throws {
        initializeCalled = true
    }
    
    func shutdown() async throws {
        shutdownCalled = true
    }
    
    func healthCheck() async -> ServiceHealthStatus {
        return ServiceHealthStatus(
            isHealthy: true,
            lastCheck: Date(),
            responseTime: 0.1,
            errorCount: 0
        )
    }
    
    var initializeCalled = false
    var shutdownCalled = false
}

// MARK: - Error Types

enum HealthDataError: Error {
    case invalidData
    case processingFailed
    case validationFailed
}

enum AnalyticsError: Error {
    case generationFailed
    case invalidData
    case processingError
} 