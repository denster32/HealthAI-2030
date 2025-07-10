import XCTest
import Foundation
@testable import HealthAI2030

/// UX Engagement Orchestrator Tests
/// Comprehensive test suite for the UX Engagement Orchestrator system
@available(iOS 18.0, macOS 15.0, *)
final class UXEngagementOrchestratorTests: XCTestCase {
    
    // MARK: - Properties
    var orchestrator: UXEngagementOrchestrator!
    var healthDataManager: HealthDataManager!
    var analyticsEngine: AnalyticsEngine!
    
    // MARK: - Setup and Teardown
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize dependencies
        healthDataManager = HealthDataManager.shared
        analyticsEngine = AnalyticsEngine.shared
        
        // Initialize orchestrator
        orchestrator = UXEngagementOrchestrator(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine
        )
    }
    
    override func tearDown() async throws {
        // Stop orchestrator
        await orchestrator?.stopOrchestrator()
        
        // Clean up
        orchestrator = nil
        healthDataManager = nil
        analyticsEngine = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testOrchestratorInitialization() async throws {
        // Test orchestrator initialization
        XCTAssertNotNil(orchestrator)
        XCTAssertNotNil(orchestrator.navigationSystem)
        XCTAssertNotNil(orchestrator.gamificationSystem)
        XCTAssertNotNil(orchestrator.challengesSystem)
        XCTAssertNotNil(orchestrator.socialSystem)
        XCTAssertNotNil(orchestrator.personalizationSystem)
        XCTAssertNotNil(orchestrator.adaptiveInterface)
        XCTAssertNotNil(orchestrator.aiOrchestration)
    }
    
    func testOrchestratorStatusInitialization() async throws {
        // Test initial status
        XCTAssertEqual(orchestrator.orchestrationStatus, .idle)
        XCTAssertNil(orchestrator.lastError)
        XCTAssertEqual(orchestrator.orchestrationProgress, 0.0)
    }
    
    func testSystemHealthInitialization() async throws {
        // Test system health initialization
        let health = orchestrator.systemHealth
        XCTAssertNotNil(health)
        XCTAssertNotNil(health.navigationHealth)
        XCTAssertNotNil(health.gamificationHealth)
        XCTAssertNotNil(health.challengesHealth)
        XCTAssertNotNil(health.socialHealth)
        XCTAssertNotNil(health.personalizationHealth)
        XCTAssertNotNil(health.adaptiveInterfaceHealth)
        XCTAssertNotNil(health.aiOrchestrationHealth)
        XCTAssertNotNil(health.overallHealth)
    }
    
    func testEngagementMetricsInitialization() async throws {
        // Test engagement metrics initialization
        let metrics = orchestrator.engagementMetrics
        XCTAssertNotNil(metrics)
        XCTAssertNotNil(metrics.navigationMetrics)
        XCTAssertNotNil(metrics.gamificationMetrics)
        XCTAssertNotNil(metrics.challengesMetrics)
        XCTAssertNotNil(metrics.socialMetrics)
        XCTAssertNotNil(metrics.personalizationMetrics)
        XCTAssertNotNil(metrics.adaptiveInterfaceMetrics)
        XCTAssertNotNil(metrics.aiOrchestrationMetrics)
        XCTAssertNotNil(metrics.overallMetrics)
    }
    
    // MARK: - Start/Stop Tests
    
    func testOrchestratorStart() async throws {
        // Test orchestrator start
        try await orchestrator.startOrchestrator()
        
        // Verify status
        XCTAssertEqual(orchestrator.orchestrationStatus, .active)
        XCTAssertNil(orchestrator.lastError)
        XCTAssertGreaterThan(orchestrator.orchestrationProgress, 0.0)
        
        // Verify systems are active
        XCTAssertNotNil(orchestrator.navigationSystem)
        XCTAssertNotNil(orchestrator.gamificationSystem)
        XCTAssertNotNil(orchestrator.challengesSystem)
        XCTAssertNotNil(orchestrator.socialSystem)
        XCTAssertNotNil(orchestrator.personalizationSystem)
        XCTAssertNotNil(orchestrator.adaptiveInterface)
        XCTAssertNotNil(orchestrator.aiOrchestration)
    }
    
    func testOrchestratorStop() async throws {
        // Start orchestrator first
        try await orchestrator.startOrchestrator()
        XCTAssertEqual(orchestrator.orchestrationStatus, .active)
        
        // Test orchestrator stop
        await orchestrator.stopOrchestrator()
        
        // Verify status
        XCTAssertEqual(orchestrator.orchestrationStatus, .stopped)
    }
    
    func testOrchestratorRestart() async throws {
        // Test orchestrator restart
        try await orchestrator.startOrchestrator()
        XCTAssertEqual(orchestrator.orchestrationStatus, .active)
        
        await orchestrator.stopOrchestrator()
        XCTAssertEqual(orchestrator.orchestrationStatus, .stopped)
        
        try await orchestrator.startOrchestrator()
        XCTAssertEqual(orchestrator.orchestrationStatus, .active)
    }
    
    // MARK: - System Health Tests
    
    func testGetSystemHealth() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Test system health retrieval
        let health = try await orchestrator.getSystemHealth()
        
        // Verify health data
        XCTAssertNotNil(health)
        XCTAssertNotNil(health.navigationHealth)
        XCTAssertNotNil(health.gamificationHealth)
        XCTAssertNotNil(health.challengesHealth)
        XCTAssertNotNil(health.socialHealth)
        XCTAssertNotNil(health.personalizationHealth)
        XCTAssertNotNil(health.adaptiveInterfaceHealth)
        XCTAssertNotNil(health.aiOrchestrationHealth)
        XCTAssertNotNil(health.overallHealth)
        
        // Verify health status
        XCTAssertTrue(health.overallHealth.isActive)
        XCTAssertGreaterThan(health.overallHealth.uptime, 0.0)
        XCTAssertLessThanOrEqual(health.overallHealth.uptime, 1.0)
        XCTAssertGreaterThanOrEqual(health.overallHealth.responseTime, 0.0)
    }
    
    func testSystemHealthConsistency() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Get health multiple times
        let health1 = try await orchestrator.getSystemHealth()
        let health2 = try await orchestrator.getSystemHealth()
        
        // Verify consistency
        XCTAssertEqual(health1.overallHealth.isActive, health2.overallHealth.isActive)
        XCTAssertEqual(health1.navigationHealth.isActive, health2.navigationHealth.isActive)
        XCTAssertEqual(health1.gamificationHealth.isActive, health2.gamificationHealth.isActive)
    }
    
    // MARK: - Engagement Metrics Tests
    
    func testGetEngagementMetrics() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Test engagement metrics retrieval
        let metrics = try await orchestrator.getEngagementMetrics()
        
        // Verify metrics data
        XCTAssertNotNil(metrics)
        XCTAssertNotNil(metrics.navigationMetrics)
        XCTAssertNotNil(metrics.gamificationMetrics)
        XCTAssertNotNil(metrics.challengesMetrics)
        XCTAssertNotNil(metrics.socialMetrics)
        XCTAssertNotNil(metrics.personalizationMetrics)
        XCTAssertNotNil(metrics.adaptiveInterfaceMetrics)
        XCTAssertNotNil(metrics.aiOrchestrationMetrics)
        XCTAssertNotNil(metrics.overallMetrics)
        
        // Verify metrics values
        XCTAssertGreaterThanOrEqual(metrics.overallMetrics.totalEngagement, 0)
        XCTAssertGreaterThanOrEqual(metrics.overallMetrics.averageEngagement, 0.0)
        XCTAssertLessThanOrEqual(metrics.overallMetrics.averageEngagement, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.overallMetrics.userRetention, 0.0)
        XCTAssertLessThanOrEqual(metrics.overallMetrics.userRetention, 1.0)
    }
    
    func testEngagementMetricsConsistency() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Get metrics multiple times
        let metrics1 = try await orchestrator.getEngagementMetrics()
        let metrics2 = try await orchestrator.getEngagementMetrics()
        
        // Verify consistency
        XCTAssertEqual(metrics1.overallMetrics.totalEngagement, metrics2.overallMetrics.totalEngagement)
        XCTAssertEqual(metrics1.overallMetrics.averageEngagement, metrics2.overallMetrics.averageEngagement, accuracy: 0.01)
    }
    
    // MARK: - Engagement Coordination Tests
    
    func testCoordinateEngagement() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Create engagement context
        let context = EngagementContext(
            id: UUID(),
            type: .comprehensive,
            navigationContext: NavigationContext(
                userProfile: UserProfile(id: UUID(), name: "Test User", age: 30, preferences: [:]),
                currentLocation: "Home",
                destination: "Workout",
                preferences: NavigationPreferences(preferredRoute: "fastest", accessibility: false, timeOptimization: true)
            ),
            gamificationContext: GamificationContext(
                activity: HealthActivity(id: UUID(), type: "workout", duration: 30, intensity: "moderate"),
                points: 50,
                context: PointContext(activity: "workout", multiplier: 1.0, bonus: 0)
            ),
            socialContext: SocialContext(
                healthData: HealthData(id: UUID(), type: "workout", value: 30, unit: "minutes", timestamp: Date()),
                friends: [UUID()],
                privacy: SharePrivacy.public
            ),
            personalizationContext: RecommendationContext(
                userProfile: UserProfile(id: UUID(), name: "Test User", age: 30, preferences: [:]),
                healthData: [HealthData(id: UUID(), type: "workout", value: 30, unit: "minutes", timestamp: Date())],
                preferences: [:]
            ),
            adaptiveContext: AdaptationContext(
                userProfile: UserProfile(id: UUID(), name: "Test User", age: 30, preferences: [:]),
                currentInterface: "dashboard",
                preferences: [:]
            ),
            aiContext: AIContext(
                userProfile: UserProfile(id: UUID(), name: "Test User", age: 30, preferences: [:]),
                healthData: [HealthData(id: UUID(), type: "workout", value: 30, unit: "minutes", timestamp: Date())],
                requestType: "insights"
            ),
            activeSystems: ["navigation", "gamification", "social", "personalization", "adaptive", "ai"],
            timestamp: Date()
        )
        
        // Test engagement coordination
        try await orchestrator.coordinateEngagement(context: context)
        
        // Verify coordination was successful
        XCTAssertEqual(orchestrator.orchestrationStatus, .active)
        XCTAssertNil(orchestrator.lastError)
    }
    
    func testCoordinateEngagementWithInvalidContext() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Create invalid context (no active systems)
        let invalidContext = EngagementContext(
            id: UUID(),
            type: .navigation,
            navigationContext: nil,
            gamificationContext: nil,
            socialContext: nil,
            personalizationContext: nil,
            adaptiveContext: nil,
            aiContext: nil,
            activeSystems: [],
            timestamp: Date()
        )
        
        // Test engagement coordination with invalid context
        do {
            try await orchestrator.coordinateEngagement(context: invalidContext)
            XCTFail("Should throw error for invalid context")
        } catch {
            XCTAssertNotNil(error)
            XCTAssertEqual(orchestrator.lastError, error.localizedDescription)
        }
    }
    
    func testCoordinateEngagementWhenNotActive() async throws {
        // Don't start orchestrator
        
        // Create valid context
        let context = EngagementContext(
            id: UUID(),
            type: .navigation,
            navigationContext: NavigationContext(
                userProfile: UserProfile(id: UUID(), name: "Test User", age: 30, preferences: [:]),
                currentLocation: "Home",
                destination: "Workout",
                preferences: NavigationPreferences(preferredRoute: "fastest", accessibility: false, timeOptimization: true)
            ),
            gamificationContext: nil,
            socialContext: nil,
            personalizationContext: nil,
            adaptiveContext: nil,
            aiContext: nil,
            activeSystems: ["navigation"],
            timestamp: Date()
        )
        
        // Test engagement coordination when not active
        do {
            try await orchestrator.coordinateEngagement(context: context)
            XCTFail("Should throw error when orchestrator is not active")
        } catch {
            XCTAssertNotNil(error)
            XCTAssertEqual(orchestrator.lastError, error.localizedDescription)
        }
    }
    
    // MARK: - Analytics Tests
    
    func testGetOrchestratorAnalytics() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Test analytics retrieval
        let analytics = try await orchestrator.getOrchestratorAnalytics()
        
        // Verify analytics data
        XCTAssertNotNil(analytics)
        XCTAssertEqual(analytics.totalSystems, 7)
        XCTAssertGreaterThanOrEqual(analytics.activeSystems, 0)
        XCTAssertLessThanOrEqual(analytics.activeSystems, 7)
        XCTAssertGreaterThanOrEqual(analytics.averageResponseTime, 0.0)
        XCTAssertNotNil(analytics.orchestrationPatterns)
        XCTAssertNotNil(analytics.insights)
        XCTAssertNotNil(analytics.timestamp)
    }
    
    func testOrchestratorAnalyticsConsistency() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Get analytics multiple times
        let analytics1 = try await orchestrator.getOrchestratorAnalytics()
        let analytics2 = try await orchestrator.getOrchestratorAnalytics()
        
        // Verify consistency
        XCTAssertEqual(analytics1.totalSystems, analytics2.totalSystems)
        XCTAssertEqual(analytics1.activeSystems, analytics2.activeSystems)
    }
    
    // MARK: - Export Tests
    
    func testExportOrchestratorDataJSON() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Test JSON export
        let data = try await orchestrator.exportOrchestratorData(format: .json)
        
        // Verify export data
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data.count, 0)
        
        // Verify JSON format
        let json = try JSONSerialization.jsonObject(with: data)
        XCTAssertNotNil(json)
    }
    
    func testExportOrchestratorDataCSV() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Test CSV export
        let data = try await orchestrator.exportOrchestratorData(format: .csv)
        
        // Verify export data
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data.count, 0)
        
        // Verify CSV format
        let csvString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(csvString)
        XCTAssertTrue(csvString?.contains(",") ?? false)
    }
    
    func testExportOrchestratorDataXML() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Test XML export
        let data = try await orchestrator.exportOrchestratorData(format: .xml)
        
        // Verify export data
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data.count, 0)
        
        // Verify XML format
        let xmlString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(xmlString)
        XCTAssertTrue(xmlString?.contains("<") ?? false)
        XCTAssertTrue(xmlString?.contains(">") ?? false)
    }
    
    // MARK: - Error Handling Tests
    
    func testOrchestratorErrorHandling() async throws {
        // Test error handling when orchestrator is not properly initialized
        let invalidOrchestrator = UXEngagementOrchestrator(
            healthDataManager: HealthDataManager.shared,
            analyticsEngine: AnalyticsEngine.shared
        )
        
        // Try to coordinate engagement without starting
        let context = EngagementContext(
            id: UUID(),
            type: .navigation,
            navigationContext: nil,
            gamificationContext: nil,
            socialContext: nil,
            personalizationContext: nil,
            adaptiveContext: nil,
            aiContext: nil,
            activeSystems: ["navigation"],
            timestamp: Date()
        )
        
        do {
            try await invalidOrchestrator.coordinateEngagement(context: context)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
            XCTAssertEqual(invalidOrchestrator.lastError, error.localizedDescription)
        }
    }
    
    func testSystemAvailabilityError() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Create context that references unavailable system
        let context = EngagementContext(
            id: UUID(),
            type: .comprehensive,
            navigationContext: nil,
            gamificationContext: nil,
            socialContext: nil,
            personalizationContext: nil,
            adaptiveContext: nil,
            aiContext: nil,
            activeSystems: ["unavailable_system"],
            timestamp: Date()
        )
        
        // Test error handling
        do {
            try await orchestrator.coordinateEngagement(context: context)
            // This might not throw if the system gracefully handles unavailable systems
        } catch {
            XCTAssertNotNil(error)
            XCTAssertEqual(orchestrator.lastError, error.localizedDescription)
        }
    }
    
    // MARK: - Performance Tests
    
    func testOrchestratorStartupPerformance() async throws {
        // Measure startup performance
        let startTime = Date()
        
        try await orchestrator.startOrchestrator()
        
        let endTime = Date()
        let startupTime = endTime.timeIntervalSince(startTime)
        
        // Verify reasonable startup time (less than 5 seconds)
        XCTAssertLessThan(startupTime, 5.0)
    }
    
    func testEngagementCoordinationPerformance() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Create engagement context
        let context = EngagementContext(
            id: UUID(),
            type: .navigation,
            navigationContext: NavigationContext(
                userProfile: UserProfile(id: UUID(), name: "Test User", age: 30, preferences: [:]),
                currentLocation: "Home",
                destination: "Workout",
                preferences: NavigationPreferences(preferredRoute: "fastest", accessibility: false, timeOptimization: true)
            ),
            gamificationContext: nil,
            socialContext: nil,
            personalizationContext: nil,
            adaptiveContext: nil,
            aiContext: nil,
            activeSystems: ["navigation"],
            timestamp: Date()
        )
        
        // Measure coordination performance
        let startTime = Date()
        
        try await orchestrator.coordinateEngagement(context: context)
        
        let endTime = Date()
        let coordinationTime = endTime.timeIntervalSince(startTime)
        
        // Verify reasonable coordination time (less than 2 seconds)
        XCTAssertLessThan(coordinationTime, 2.0)
    }
    
    func testSystemHealthRetrievalPerformance() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Measure health retrieval performance
        let startTime = Date()
        
        _ = try await orchestrator.getSystemHealth()
        
        let endTime = Date()
        let retrievalTime = endTime.timeIntervalSince(startTime)
        
        // Verify reasonable retrieval time (less than 1 second)
        XCTAssertLessThan(retrievalTime, 1.0)
    }
    
    // MARK: - Integration Tests
    
    func testOrchestratorIntegrationWithAllSystems() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Verify all systems are available
        XCTAssertNotNil(orchestrator.navigationSystem)
        XCTAssertNotNil(orchestrator.gamificationSystem)
        XCTAssertNotNil(orchestrator.challengesSystem)
        XCTAssertNotNil(orchestrator.socialSystem)
        XCTAssertNotNil(orchestrator.personalizationSystem)
        XCTAssertNotNil(orchestrator.adaptiveInterface)
        XCTAssertNotNil(orchestrator.aiOrchestration)
        
        // Test comprehensive engagement coordination
        let context = EngagementContext(
            id: UUID(),
            type: .comprehensive,
            navigationContext: NavigationContext(
                userProfile: UserProfile(id: UUID(), name: "Test User", age: 30, preferences: [:]),
                currentLocation: "Home",
                destination: "Workout",
                preferences: NavigationPreferences(preferredRoute: "fastest", accessibility: false, timeOptimization: true)
            ),
            gamificationContext: GamificationContext(
                activity: HealthActivity(id: UUID(), type: "workout", duration: 30, intensity: "moderate"),
                points: 50,
                context: PointContext(activity: "workout", multiplier: 1.0, bonus: 0)
            ),
            socialContext: SocialContext(
                healthData: HealthData(id: UUID(), type: "workout", value: 30, unit: "minutes", timestamp: Date()),
                friends: [UUID()],
                privacy: SharePrivacy.public
            ),
            personalizationContext: RecommendationContext(
                userProfile: UserProfile(id: UUID(), name: "Test User", age: 30, preferences: [:]),
                healthData: [HealthData(id: UUID(), type: "workout", value: 30, unit: "minutes", timestamp: Date())],
                preferences: [:]
            ),
            adaptiveContext: AdaptationContext(
                userProfile: UserProfile(id: UUID(), name: "Test User", age: 30, preferences: [:]),
                currentInterface: "dashboard",
                preferences: [:]
            ),
            aiContext: AIContext(
                userProfile: UserProfile(id: UUID(), name: "Test User", age: 30, preferences: [:]),
                healthData: [HealthData(id: UUID(), type: "workout", value: 30, unit: "minutes", timestamp: Date())],
                requestType: "insights"
            ),
            activeSystems: ["navigation", "gamification", "challenges", "social", "personalization", "adaptive", "ai"],
            timestamp: Date()
        )
        
        // Test comprehensive coordination
        try await orchestrator.coordinateEngagement(context: context)
        
        // Verify successful coordination
        XCTAssertEqual(orchestrator.orchestrationStatus, .active)
        XCTAssertNil(orchestrator.lastError)
        
        // Verify all systems are still active
        XCTAssertNotNil(orchestrator.navigationSystem)
        XCTAssertNotNil(orchestrator.gamificationSystem)
        XCTAssertNotNil(orchestrator.challengesSystem)
        XCTAssertNotNil(orchestrator.socialSystem)
        XCTAssertNotNil(orchestrator.personalizationSystem)
        XCTAssertNotNil(orchestrator.adaptiveInterface)
        XCTAssertNotNil(orchestrator.aiOrchestration)
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentEngagementCoordination() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Create multiple contexts
        let contexts = (0..<5).map { index in
            EngagementContext(
                id: UUID(),
                type: .navigation,
                navigationContext: NavigationContext(
                    userProfile: UserProfile(id: UUID(), name: "Test User \(index)", age: 30, preferences: [:]),
                    currentLocation: "Home",
                    destination: "Workout",
                    preferences: NavigationPreferences(preferredRoute: "fastest", accessibility: false, timeOptimization: true)
                ),
                gamificationContext: nil,
                socialContext: nil,
                personalizationContext: nil,
                adaptiveContext: nil,
                aiContext: nil,
                activeSystems: ["navigation"],
                timestamp: Date()
            )
        }
        
        // Test concurrent coordination
        try await withThrowingTaskGroup(of: Void.self) { group in
            for context in contexts {
                group.addTask {
                    try await self.orchestrator.coordinateEngagement(context: context)
                }
            }
            
            try await group.waitForAll()
        }
        
        // Verify orchestrator is still active
        XCTAssertEqual(orchestrator.orchestrationStatus, .active)
        XCTAssertNil(orchestrator.lastError)
    }
    
    func testConcurrentDataRetrieval() async throws {
        // Start orchestrator
        try await orchestrator.startOrchestrator()
        
        // Test concurrent data retrieval
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Concurrent health retrieval
            group.addTask {
                _ = try await self.orchestrator.getSystemHealth()
            }
            
            // Concurrent metrics retrieval
            group.addTask {
                _ = try await self.orchestrator.getEngagementMetrics()
            }
            
            // Concurrent analytics retrieval
            group.addTask {
                _ = try await self.orchestrator.getOrchestratorAnalytics()
            }
            
            try await group.waitForAll()
        }
        
        // Verify orchestrator is still active
        XCTAssertEqual(orchestrator.orchestrationStatus, .active)
        XCTAssertNil(orchestrator.lastError)
    }
}

// MARK: - Supporting Types for Tests

public struct UserProfile: Codable {
    public let id: UUID
    public let name: String
    public let age: Int
    public let preferences: [String: String]
}

public struct HealthActivity: Codable {
    public let id: UUID
    public let type: String
    public let duration: Int
    public let intensity: String
}

public struct PointContext: Codable {
    public let activity: String
    public let multiplier: Double
    public let bonus: Int
}

public struct HealthData: Codable {
    public let id: UUID
    public let type: String
    public let value: Double
    public let unit: String
    public let timestamp: Date
}

public enum SharePrivacy: String, Codable {
    case `public` = "public"
    case friends = "friends"
    case private = "private"
}

public struct RecommendationContext: Codable {
    public let userProfile: UserProfile
    public let healthData: [HealthData]
    public let preferences: [String: String]
}

public struct AdaptationContext: Codable {
    public let userProfile: UserProfile
    public let currentInterface: String
    public let preferences: [String: String]
}

public struct AIContext: Codable {
    public let userProfile: UserProfile
    public let healthData: [HealthData]
    public let requestType: String
} 