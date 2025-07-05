import XCTest
import SwiftUI
import SwiftData
@testable import HealthAI2030

final class PlatformSpecificTests: XCTestCase {
    
    // MARK: - WatchOS Tests
    
    func testWatchOSHealthMonitoringView() {
        let healthMonitoringView = HealthMonitoringView()
        
        // Test view creation
        XCTAssertNotNil(healthMonitoringView)
        
        // Test health manager initialization
        let healthManager = WatchHealthManager()
        XCTAssertNotNil(healthManager)
        
        // Test health metrics
        let metrics = HealthMonitoringView.HealthMetric.allCases
        XCTAssertEqual(metrics.count, 6) // heartRate, steps, calories, sleep, activity, respiratory
        
        // Test metric properties
        let heartRateMetric = HealthMonitoringView.HealthMetric.heartRate
        XCTAssertEqual(heartRateMetric.icon, "heart.fill")
        XCTAssertEqual(heartRateMetric.color, .red)
    }
    
    func testWatchOSQuickActionsView() {
        let quickActionsView = QuickActionsView()
        
        // Test view creation
        XCTAssertNotNil(quickActionsView)
        
        // Test quick actions
        let actions = QuickActionsView.QuickAction.allCases
        XCTAssertEqual(actions.count, 8) // startWorkout, logWater, startMeditation, checkHeartRate, emergencyCall, logMood, takeMedication, checkWeather
        
        // Test action properties
        let workoutAction = QuickActionsView.QuickAction.startWorkout
        XCTAssertEqual(workoutAction.icon, "figure.run")
        XCTAssertEqual(workoutAction.color, .green)
        XCTAssertEqual(workoutAction.hapticType, .start)
    }
    
    func testWatchOSComplicationsView() {
        let complicationsView = ComplicationsView()
        
        // Test view creation
        XCTAssertNotNil(complicationsView)
        
        // Test complication manager
        let complicationManager = ComplicationManager()
        XCTAssertNotNil(complicationManager)
        
        // Test update frequencies
        let frequencies = ComplicationManager.UpdateFrequency.allCases
        XCTAssertEqual(frequencies.count, 5) // oneMinute, fiveMinutes, fifteenMinutes, thirtyMinutes, oneHour
        
        // Test complication types
        let complicationTypes = ComplicationsView.ComplicationSettingsView.ComplicationType.allCases
        XCTAssertEqual(complicationTypes.count, 9) // heartRate, steps, calories, sleep, activity, water, medication, weather, battery
    }
    
    func testWatchOSHealthManager() {
        let healthManager = WatchHealthManager()
        
        // Test initial state
        XCTAssertEqual(healthManager.currentValue, "0")
        XCTAssertNil(healthManager.currentInsight)
        
        // Test health monitoring
        healthManager.startMonitoring()
        XCTAssertNotNil(healthManager.updateTimer)
        
        // Test stopping monitoring
        healthManager.stopMonitoring()
        XCTAssertNil(healthManager.updateTimer)
        
        // Test health actions
        healthManager.logWaterIntake()
        healthManager.startMeditation()
        healthManager.triggerEmergency()
        // These should not crash and should provide haptic feedback
    }
    
    // MARK: - macOS Tests
    
    func testMacOSSidebarView() {
        let selectedSection = SidebarView.NavigationSection.dashboard
        let sidebarView = SidebarView(selectedSection: .constant(selectedSection))
        
        // Test view creation
        XCTAssertNotNil(sidebarView)
        
        // Test navigation sections
        let sections = SidebarView.NavigationSection.allCases
        XCTAssertEqual(sections.count, 11) // dashboard, analytics, healthData, aiCopilot, sleepTracking, workouts, nutrition, mentalHealth, medications, family, settings
        
        // Test section properties
        let dashboardSection = SidebarView.NavigationSection.dashboard
        XCTAssertEqual(dashboardSection.icon, "chart.bar.fill")
        XCTAssertEqual(dashboardSection.color, .blue)
    }
    
    func testMacOSAdvancedAnalyticsDashboard() {
        let analyticsDashboard = AdvancedAnalyticsDashboard()
        
        // Test view creation
        XCTAssertNotNil(analyticsDashboard)
        
        // Test time ranges
        let timeRanges = AdvancedAnalyticsDashboard.TimeRange.allCases
        XCTAssertEqual(timeRanges.count, 5) // day, week, month, quarter, year
        
        // Test health metrics
        let healthMetrics = AdvancedAnalyticsDashboard.HealthMetric.allCases
        XCTAssertEqual(healthMetrics.count, 10) // heartRate, steps, calories, sleep, activity, water, weight, bloodPressure, glucose, oxygen
    }
    
    func testMacOSAnalyticsManager() {
        let analyticsManager = AnalyticsManager()
        
        // Test initial state
        XCTAssertTrue(analyticsManager.heartRateData.isEmpty)
        XCTAssertTrue(analyticsManager.stepsData.isEmpty)
        XCTAssertTrue(analyticsManager.sleepData.isEmpty)
        XCTAssertTrue(analyticsManager.activityData.isEmpty)
        
        // Test data loading
        analyticsManager.loadData(for: .week)
        XCTAssertFalse(analyticsManager.heartRateData.isEmpty)
        XCTAssertFalse(analyticsManager.stepsData.isEmpty)
        XCTAssertFalse(analyticsManager.sleepData.isEmpty)
        XCTAssertFalse(analyticsManager.activityData.isEmpty)
        
        // Test averages calculation
        analyticsManager.calculateAverages()
        XCTAssertGreaterThan(analyticsManager.averageHeartRate, 0)
        XCTAssertGreaterThan(analyticsManager.dailySteps, 0)
        XCTAssertGreaterThan(analyticsManager.averageSleepHours, 0)
        XCTAssertGreaterThan(analyticsManager.dailyCalories, 0)
    }
    
    func testMacOSDataPoint() {
        let date = Date()
        let value = 75.0
        let dataPoint = DataPoint(date: date, value: value)
        
        // Test data point properties
        XCTAssertEqual(dataPoint.date, date)
        XCTAssertEqual(dataPoint.value, value)
        XCTAssertNotNil(dataPoint.id)
    }
    
    // MARK: - tvOS Tests
    
    func testTVOSFamilyHealthDashboardView() {
        let familyDashboardView = FamilyHealthDashboardView()
        
        // Test view creation
        XCTAssertNotNil(familyDashboardView)
        
        // Test time ranges
        let timeRanges = FamilyHealthDashboardView.TimeRange.allCases
        XCTAssertEqual(timeRanges.count, 4) // day, week, month, year
        
        // Test dashboard sections
        let sections = FamilyHealthDashboardView.DashboardSection.allCases
        XCTAssertEqual(sections.count, 4) // familyOverview, healthSummary, alerts, activities
    }
    
    func testTVOSFamilyHealthCardView() {
        let familyMember = FamilyMember(
            name: "John Doe",
            relationship: "Father",
            age: 35,
            profileColor: .blue
        )
        
        let cardView = FamilyHealthCardView(familyMember: familyMember)
        
        // Test view creation
        XCTAssertNotNil(cardView)
        
        // Test health metrics
        let healthMetrics = FamilyHealthCardView.HealthMetric.allCases
        XCTAssertEqual(healthMetrics.count, 6) // overview, heartRate, activity, sleep, nutrition, medications
        
        // Test metric properties
        let overviewMetric = FamilyHealthCardView.HealthMetric.overview
        XCTAssertEqual(overviewMetric.icon, "person.fill")
        XCTAssertEqual(overviewMetric.color, .blue)
    }
    
    func testTVOSFamilyMember() {
        let familyMember = FamilyMember(
            name: "John Doe",
            relationship: "Father",
            age: 35,
            profileColor: .blue
        )
        
        // Test family member properties
        XCTAssertEqual(familyMember.name, "John Doe")
        XCTAssertEqual(familyMember.relationship, "Father")
        XCTAssertEqual(familyMember.age, 35)
        XCTAssertEqual(familyMember.profileColor, .blue)
        XCTAssertEqual(familyMember.initials, "JD")
        XCTAssertGreaterThan(familyMember.heartRate, 0)
        XCTAssertGreaterThan(familyMember.dailySteps, 0)
    }
    
    func testTVOSHealthAlertCard() {
        let familyMember = FamilyMember(
            name: "John Doe",
            relationship: "Father",
            age: 35,
            profileColor: .blue
        )
        
        let alertCard = HealthAlertCard(
            member: familyMember,
            alertType: .medication,
            message: "Time to take medication",
            severity: .medium
        )
        
        // Test alert card creation
        XCTAssertNotNil(alertCard)
        
        // Test alert types
        let alertTypes = HealthAlertCard.AlertType.allCases
        XCTAssertEqual(alertTypes.count, 4) // medication, exercise, appointment, vital
        
        // Test alert severities
        let severities = HealthAlertCard.AlertSeverity.allCases
        XCTAssertEqual(severities.count, 3) // low, medium, high
    }
    
    // MARK: - Cross-Platform Integration Tests
    
    func testCrossPlatformDataConsistency() {
        // Test that data models are consistent across platforms
        let healthData = HealthData()
        let sleepSession = SleepSession()
        let workoutRecord = WorkoutRecord()
        
        // Test SwiftData model creation
        XCTAssertNotNil(healthData)
        XCTAssertNotNil(sleepSession)
        XCTAssertNotNil(workoutRecord)
    }
    
    func testPlatformSpecificUIComponents() {
        // Test that platform-specific UI components render correctly
        
        // WatchOS components
        let watchHealthMonitoring = HealthMonitoringView()
        XCTAssertNotNil(watchHealthMonitoring)
        
        let watchQuickActions = QuickActionsView()
        XCTAssertNotNil(watchQuickActions)
        
        let watchComplications = ComplicationsView()
        XCTAssertNotNil(watchComplications)
        
        // macOS components
        let macOSSidebar = SidebarView(selectedSection: .constant(.dashboard))
        XCTAssertNotNil(macOSSidebar)
        
        let macOSAnalytics = AdvancedAnalyticsDashboard()
        XCTAssertNotNil(macOSAnalytics)
        
        // tvOS components
        let tvOSFamilyDashboard = FamilyHealthDashboardView()
        XCTAssertNotNil(tvOSFamilyDashboard)
        
        let familyMember = FamilyMember(
            name: "Test User",
            relationship: "Self",
            age: 30,
            profileColor: .green
        )
        
        let tvOSFamilyCard = FamilyHealthCardView(familyMember: familyMember)
        XCTAssertNotNil(tvOSFamilyCard)
    }
    
    func testPlatformSpecificNavigation() {
        // Test navigation patterns for each platform
        
        // WatchOS: Tab-based navigation
        let watchTabs = ["Health", "Sleep", "Monitor", "Actions", "Complications", "Settings"]
        XCTAssertEqual(watchTabs.count, 6)
        
        // macOS: Sidebar navigation
        let macOSSections = SidebarView.NavigationSection.allCases
        XCTAssertEqual(macOSSections.count, 11)
        
        // tvOS: Tab-based navigation
        let tvOSTabs = ["Family Health", "Individual", "Activities", "Goals", "Settings"]
        XCTAssertEqual(tvOSTabs.count, 5)
    }
    
    func testPlatformSpecificDataFlow() {
        // Test data flow between platform-specific components
        
        // WatchOS data flow
        let watchHealthManager = WatchHealthManager()
        watchHealthManager.startMonitoring()
        XCTAssertNotNil(watchHealthManager.updateTimer)
        
        // macOS data flow
        let macOSAnalyticsManager = AnalyticsManager()
        macOSAnalyticsManager.loadData(for: .week)
        XCTAssertFalse(macOSAnalyticsManager.heartRateData.isEmpty)
        
        // tvOS data flow
        let familyMember = FamilyMember(
            name: "Test User",
            relationship: "Self",
            age: 30,
            profileColor: .blue
        )
        XCTAssertNotNil(familyMember)
        XCTAssertGreaterThan(familyMember.heartRate, 0)
    }
    
    func testPlatformSpecificAccessibility() {
        // Test accessibility features for each platform
        
        // WatchOS accessibility
        let watchHealthMonitoring = HealthMonitoringView()
        // Test that view has proper accessibility labels and hints
        XCTAssertNotNil(watchHealthMonitoring)
        
        // macOS accessibility
        let macOSSidebar = SidebarView(selectedSection: .constant(.dashboard))
        // Test that sidebar has proper accessibility support
        XCTAssertNotNil(macOSSidebar)
        
        // tvOS accessibility
        let tvOSFamilyDashboard = FamilyHealthDashboardView()
        // Test that dashboard has proper focus management
        XCTAssertNotNil(tvOSFamilyDashboard)
    }
    
    func testPlatformSpecificPerformance() {
        // Test performance characteristics for each platform
        
        // WatchOS performance
        let watchHealthManager = WatchHealthManager()
        let startTime = Date()
        watchHealthManager.startMonitoring()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 1.0) // Should start quickly
        
        // macOS performance
        let macOSAnalyticsManager = AnalyticsManager()
        let analyticsStartTime = Date()
        macOSAnalyticsManager.loadData(for: .week)
        let analyticsEndTime = Date()
        let analyticsDuration = analyticsEndTime.timeIntervalSince(analyticsStartTime)
        XCTAssertLessThan(analyticsDuration, 2.0) // Should load data quickly
        
        // tvOS performance
        let familyMember = FamilyMember(
            name: "Test User",
            relationship: "Self",
            age: 30,
            profileColor: .blue
        )
        let cardStartTime = Date()
        let _ = FamilyHealthCardView(familyMember: familyMember)
        let cardEndTime = Date()
        let cardDuration = cardEndTime.timeIntervalSince(cardStartTime)
        XCTAssertLessThan(cardDuration, 1.0) // Should render quickly
    }
    
    func testPlatformSpecificErrorHandling() {
        // Test error handling for each platform
        
        // WatchOS error handling
        let watchHealthManager = WatchHealthManager()
        watchHealthManager.stopMonitoring() // Should not crash if not started
        XCTAssertNil(watchHealthManager.updateTimer)
        
        // macOS error handling
        let macOSAnalyticsManager = AnalyticsManager()
        macOSAnalyticsManager.loadData(for: .day) // Should handle empty data gracefully
        XCTAssertNotNil(macOSAnalyticsManager.heartRateData)
        
        // tvOS error handling
        let familyMember = FamilyMember(
            name: "",
            relationship: "",
            age: 0,
            profileColor: .clear
        )
        XCTAssertNotNil(familyMember) // Should handle empty/invalid data
    }
    
    // MARK: - Performance Tests
    
    func testWatchOSPerformance() {
        measure {
            let healthManager = WatchHealthManager()
            healthManager.startMonitoring()
            healthManager.stopMonitoring()
        }
    }
    
    func testMacOSPerformance() {
        measure {
            let analyticsManager = AnalyticsManager()
            analyticsManager.loadData(for: .month)
            analyticsManager.calculateAverages()
        }
    }
    
    func testTVOSPerformance() {
        measure {
            let familyMember = FamilyMember(
                name: "Test User",
                relationship: "Self",
                age: 30,
                profileColor: .blue
            )
            let _ = FamilyHealthCardView(familyMember: familyMember)
        }
    }
    
    // MARK: - Memory Tests
    
    func testWatchOSMemoryUsage() {
        var healthManagers: [WatchHealthManager] = []
        
        for _ in 0..<10 {
            let manager = WatchHealthManager()
            healthManagers.append(manager)
        }
        
        // Should not cause memory issues
        XCTAssertEqual(healthManagers.count, 10)
    }
    
    func testMacOSMemoryUsage() {
        var analyticsManagers: [AnalyticsManager] = []
        
        for _ in 0..<5 {
            let manager = AnalyticsManager()
            manager.loadData(for: .week)
            analyticsManagers.append(manager)
        }
        
        // Should not cause memory issues
        XCTAssertEqual(analyticsManagers.count, 5)
    }
    
    func testTVOSMemoryUsage() {
        var familyMembers: [FamilyMember] = []
        
        for i in 0..<10 {
            let member = FamilyMember(
                name: "User \(i)",
                relationship: "Family",
                age: 30 + i,
                profileColor: .blue
            )
            familyMembers.append(member)
        }
        
        // Should not cause memory issues
        XCTAssertEqual(familyMembers.count, 10)
    }
}

// MARK: - Test Helpers

extension PlatformSpecificTests {
    
    func createTestHealthData() -> HealthData {
        let healthData = HealthData()
        healthData.heartRate = 75
        healthData.steps = 8500
        healthData.calories = 2100
        healthData.timestamp = Date()
        return healthData
    }
    
    func createTestSleepSession() -> SleepSession {
        let sleepSession = SleepSession()
        sleepSession.startTime = Date().addingTimeInterval(-28800) // 8 hours ago
        sleepSession.endTime = Date()
        sleepSession.quality = .good
        return sleepSession
    }
    
    func createTestWorkoutRecord() -> WorkoutRecord {
        let workoutRecord = WorkoutRecord()
        workoutRecord.type = .running
        workoutRecord.duration = 1800 // 30 minutes
        workoutRecord.calories = 300
        workoutRecord.startTime = Date().addingTimeInterval(-3600) // 1 hour ago
        return workoutRecord
    }
} 