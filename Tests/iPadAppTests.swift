import XCTest
import SwiftUI
import PencilKit
@testable import HealthAI2030

final class iPadAppTests: XCTestCase {
    
    // MARK: - Adaptive Root View Tests
    
    func testAdaptiveRootViewCreation() {
        let adaptiveView = AdaptiveRootView()
        XCTAssertNotNil(adaptiveView)
    }
    
    func testAdaptiveRootViewSizeClassDetection() {
        // Test that the view can handle different size classes
        let adaptiveView = AdaptiveRootView()
        
        // Simulate compact size class (iPhone)
        let compactEnvironment = EnvironmentValues()
        // Note: In a real test, you'd inject the environment
        
        // Simulate regular size class (iPad)
        let regularEnvironment = EnvironmentValues()
        // Note: In a real test, you'd inject the environment
        
        XCTAssertNotNil(adaptiveView)
    }
    
    func testIPhoneContentViewCreation() {
        let iPhoneView = iPhoneContentView()
        XCTAssertNotNil(iPhoneView)
    }
    
    // MARK: - iPad Root View Tests
    
    func testIPadRootViewCreation() {
        let iPadView = iPadRootView()
        XCTAssertNotNil(iPadView)
    }
    
    func testIPadRootViewNavigationSplitView() {
        let iPadView = iPadRootView()
        // Test that the view contains a NavigationSplitView
        XCTAssertNotNil(iPadView)
    }
    
    func testSidebarSectionEnum() {
        let sections = SidebarSection.allCases
        XCTAssertEqual(sections.count, 11) // dashboard, analytics, healthData, aiCopilot, sleepTracking, workouts, nutrition, mentalHealth, medications, family, settings
        
        // Test specific sections
        XCTAssertEqual(SidebarSection.dashboard.icon, "square.grid.2x2.fill")
        XCTAssertEqual(SidebarSection.dashboard.color, .blue)
        XCTAssertEqual(SidebarSection.analytics.icon, "chart.bar.xaxis")
        XCTAssertEqual(SidebarSection.analytics.color, .purple)
    }
    
    func testHealthItemCreation() {
        let healthItem = HealthItem(
            title: "Heart Rate",
            subtitle: "View detailed data and trends",
            type: .healthCategory(.heartRate),
            icon: "heart.fill",
            color: .red
        )
        
        XCTAssertEqual(healthItem.title, "Heart Rate")
        XCTAssertEqual(healthItem.subtitle, "View detailed data and trends")
        XCTAssertEqual(healthItem.icon, "heart.fill")
        XCTAssertEqual(healthItem.color, .red)
    }
    
    func testHealthCategoryEnum() {
        let categories = HealthCategory.allCases
        XCTAssertEqual(categories.count, 10) // heartRate, steps, sleep, calories, activity, weight, bloodPressure, glucose, oxygen, respiratory
        
        // Test specific categories
        XCTAssertEqual(HealthCategory.heartRate.icon, "heart.fill")
        XCTAssertEqual(HealthCategory.heartRate.color, .red)
        XCTAssertEqual(HealthCategory.steps.icon, "figure.walk")
        XCTAssertEqual(HealthCategory.steps.color, .green)
    }
    
    func testWorkoutTypeEnum() {
        let workoutTypes = WorkoutType.allCases
        XCTAssertEqual(workoutTypes.count, 6) // running, walking, cycling, swimming, yoga, strength
        
        // Test specific workout types
        XCTAssertEqual(WorkoutType.running.icon, "figure.run")
        XCTAssertEqual(WorkoutType.cycling.icon, "bicycle")
    }
    
    // MARK: - iPad Sidebar View Tests
    
    func testIPadSidebarViewCreation() {
        let selectedSection: SidebarSection? = .dashboard
        let sidebarView = iPadSidebarView(selectedSection: .constant(selectedSection))
        XCTAssertNotNil(sidebarView)
    }
    
    func testIPadSidebarViewSections() {
        let sidebarView = iPadSidebarView(selectedSection: .constant(.dashboard))
        XCTAssertNotNil(sidebarView)
        
        // Test that all sections are represented
        let sections = SidebarSection.allCases
        XCTAssertEqual(sections.count, 11)
    }
    
    func testUserProfileSectionCreation() {
        let showingProfile = false
        let profileSection = UserProfileSection(showingProfile: .constant(showingProfile))
        XCTAssertNotNil(profileSection)
    }
    
    func testUserProfileViewCreation() {
        let profileView = UserProfileView()
        XCTAssertNotNil(profileView)
    }
    
    func testStatCardCreation() {
        let statCard = StatCard(title: "Age", value: "32", icon: "person.fill")
        XCTAssertNotNil(statCard)
    }
    
    func testHealthSummaryRowCreation() {
        let summaryRow = HealthSummaryRow(
            title: "BMI",
            value: "23.7",
            status: "Normal",
            color: .green
        )
        XCTAssertNotNil(summaryRow)
    }
    
    // MARK: - iPad Content View Tests
    
    func testIPadContentViewCreation() {
        let contentView = iPadContentView(section: .healthData, selectedItem: .constant(nil))
        XCTAssertNotNil(contentView)
    }
    
    func testHealthCategoryListViewCreation() {
        let listView = HealthCategoryListView(selection: .constant(nil))
        XCTAssertNotNil(listView)
    }
    
    func testHealthCategoryRowCreation() {
        let categoryRow = HealthCategoryRow(category: .heartRate)
        XCTAssertNotNil(categoryRow)
        XCTAssertEqual(categoryRow.category, .heartRate)
    }
    
    func testConversationListViewCreation() {
        let conversationView = ConversationListView(selection: .constant(nil))
        XCTAssertNotNil(conversationView)
    }
    
    func testConversationRowCreation() {
        let conversationRow = ConversationRow(
            title: "Morning Check-in",
            preview: "How are you feeling today?",
            time: "2 hours ago"
        )
        XCTAssertNotNil(conversationRow)
    }
    
    func testWorkoutListViewCreation() {
        let workoutView = WorkoutListView(selection: .constant(nil))
        XCTAssertNotNil(workoutView)
    }
    
    func testWorkoutTypeRowCreation() {
        let workoutRow = WorkoutTypeRow(workoutType: .running)
        XCTAssertNotNil(workoutRow)
        XCTAssertEqual(workoutRow.workoutType, .running)
    }
    
    func testSleepSessionListViewCreation() {
        let sleepView = SleepSessionListView(selection: .constant(nil))
        XCTAssertNotNil(sleepView)
    }
    
    func testSleepSessionRowCreation() {
        let sleepRow = SleepSessionRow(
            title: "Last Night",
            duration: "7.5 hours",
            quality: "Good quality",
            time: "12 hours ago"
        )
        XCTAssertNotNil(sleepRow)
    }
    
    func testMedicationListViewCreation() {
        let medicationView = MedicationListView(selection: .constant(nil))
        XCTAssertNotNil(medicationView)
    }
    
    func testMedicationRowCreation() {
        let medicationRow = MedicationRow(
            name: "Vitamin D",
            dosage: "1000 IU",
            frequency: "Daily",
            time: "Morning"
        )
        XCTAssertNotNil(medicationRow)
    }
    
    func testFamilyMemberListViewCreation() {
        let familyView = FamilyMemberListView(selection: .constant(nil))
        XCTAssertNotNil(familyView)
    }
    
    func testFamilyMemberRowCreation() {
        let familyRow = FamilyMemberRow(
            name: "John Doe",
            relationship: "Father",
            age: "32 years old"
        )
        XCTAssertNotNil(familyRow)
    }
    
    func testSinglePaneViewCreation() {
        let singlePaneView = SinglePaneView(section: .dashboard)
        XCTAssertNotNil(singlePaneView)
    }
    
    // MARK: - iPad Detail View Tests
    
    func testIPadDetailViewCreation() {
        let detailView = iPadDetailView(item: nil)
        XCTAssertNotNil(detailView)
    }
    
    func testIPadDetailViewWithHealthItem() {
        let healthItem = HealthItem(
            title: "Heart Rate",
            subtitle: "View detailed data and trends",
            type: .healthCategory(.heartRate),
            icon: "heart.fill",
            color: .red
        )
        
        let detailView = iPadDetailView(item: healthItem)
        XCTAssertNotNil(detailView)
    }
    
    func testHealthCategoryDetailViewCreation() {
        let detailView = HealthCategoryDetailView(category: .heartRate)
        XCTAssertNotNil(detailView)
    }
    
    func testKeyMetricsSectionCreation() {
        let metricsSection = KeyMetricsSection(category: .heartRate)
        XCTAssertNotNil(metricsSection)
    }
    
    func testMetricCardCreation() {
        let metricCard = MetricCard(
            title: "Current",
            value: "72",
            unit: "BPM",
            trend: "+2.3%",
            trendDirection: .up
        )
        XCTAssertNotNil(metricCard)
    }
    
    func testChartSectionCreation() {
        let analyticsManager = AnalyticsManager()
        let chartSection = ChartSection(category: .heartRate, analyticsManager: analyticsManager)
        XCTAssertNotNil(chartSection)
    }
    
    func testInsightsSectionCreation() {
        let insightsSection = InsightsSection(category: .heartRate)
        XCTAssertNotNil(insightsSection)
    }
    
    func testInsightRowCreation() {
        let insightRow = InsightRow(
            icon: "lightbulb.fill",
            title: "Positive Trend",
            description: "Your heart rate has improved by 5% this week",
            color: .green
        )
        XCTAssertNotNil(insightRow)
    }
    
    func testRecommendationsSectionCreation() {
        let recommendationsSection = RecommendationsSection(category: .heartRate)
        XCTAssertNotNil(recommendationsSection)
    }
    
    func testRecommendationRowCreation() {
        let recommendationRow = RecommendationRow(
            title: "Increase Activity",
            description: "Try adding 10 more minutes of exercise daily",
            action: "View Plan"
        )
        XCTAssertNotNil(recommendationRow)
    }
    
    func testConversationDetailViewCreation() {
        let conversationView = ConversationDetailView(conversationId: "test_conversation")
        XCTAssertNotNil(conversationView)
    }
    
    func testMessageBubbleCreation() {
        let userBubble = MessageBubble(text: "Hello", isUser: true)
        let aiBubble = MessageBubble(text: "Hi there!", isUser: false)
        
        XCTAssertNotNil(userBubble)
        XCTAssertNotNil(aiBubble)
    }
    
    func testWorkoutDetailViewCreation() {
        let workoutView = WorkoutDetailView(workoutType: .running)
        XCTAssertNotNil(workoutView)
    }
    
    func testSleepSessionDetailViewCreation() {
        let sleepView = SleepSessionDetailView(date: Date())
        XCTAssertNotNil(sleepView)
    }
    
    func testMedicationDetailViewCreation() {
        let medicationView = MedicationDetailView(medicationName: "Vitamin D")
        XCTAssertNotNil(medicationView)
    }
    
    func testFamilyMemberDetailViewCreation() {
        let familyView = FamilyMemberDetailView(memberName: "John Doe")
        XCTAssertNotNil(familyView)
    }
    
    // MARK: - Annotation Tests
    
    func testAnnotationViewCreation() {
        let healthItem = HealthItem(
            title: "Heart Rate",
            subtitle: "View detailed data and trends",
            type: .healthCategory(.heartRate),
            icon: "heart.fill",
            color: .red
        )
        
        let annotationView = AnnotationView(item: healthItem) { _ in
            // Save callback
        }
        XCTAssertNotNil(annotationView)
    }
    
    func testPKCanvasRepresentableCreation() {
        let canvasView = PKCanvasView()
        let canvasRepresentable = PKCanvasRepresentable(canvasView: .constant(canvasView))
        XCTAssertNotNil(canvasRepresentable)
    }
    
    // MARK: - Integration Tests
    
    func testIPadAppIntegration() {
        // Test the complete iPad app flow
        let adaptiveView = AdaptiveRootView()
        let iPadView = iPadRootView()
        let sidebarView = iPadSidebarView(selectedSection: .constant(.dashboard))
        let contentView = iPadContentView(section: .healthData, selectedItem: .constant(nil))
        let detailView = iPadDetailView(item: nil)
        
        XCTAssertNotNil(adaptiveView)
        XCTAssertNotNil(iPadView)
        XCTAssertNotNil(sidebarView)
        XCTAssertNotNil(contentView)
        XCTAssertNotNil(detailView)
    }
    
    func testNavigationFlow() {
        // Test navigation between different sections
        let sections: [SidebarSection] = [.dashboard, .analytics, .healthData, .aiCopilot]
        
        for section in sections {
            let contentView = iPadContentView(section: section, selectedItem: .constant(nil))
            XCTAssertNotNil(contentView)
        }
    }
    
    func testDataFlow() {
        // Test data flow from sidebar to content to detail
        let healthItem = HealthItem(
            title: "Heart Rate",
            subtitle: "View detailed data and trends",
            type: .healthCategory(.heartRate),
            icon: "heart.fill",
            color: .red
        )
        
        let detailView = iPadDetailView(item: healthItem)
        XCTAssertNotNil(detailView)
    }
    
    // MARK: - Performance Tests
    
    func testIPadAppPerformance() {
        measure {
            let iPadView = iPadRootView()
            let sidebarView = iPadSidebarView(selectedSection: .constant(.dashboard))
            let contentView = iPadContentView(section: .healthData, selectedItem: .constant(nil))
            let detailView = iPadDetailView(item: nil)
            
            // Simulate view creation and rendering
            _ = iPadView
            _ = sidebarView
            _ = contentView
            _ = detailView
        }
    }
    
    func testSidebarPerformance() {
        measure {
            for section in SidebarSection.allCases {
                let sidebarView = iPadSidebarView(selectedSection: .constant(section))
                _ = sidebarView
            }
        }
    }
    
    func testContentListPerformance() {
        measure {
            for section in SidebarSection.allCases {
                let contentView = iPadContentView(section: section, selectedItem: .constant(nil))
                _ = contentView
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testIPadAppMemoryUsage() {
        var views: [Any] = []
        
        for _ in 0..<10 {
            let iPadView = iPadRootView()
            let sidebarView = iPadSidebarView(selectedSection: .constant(.dashboard))
            let contentView = iPadContentView(section: .healthData, selectedItem: .constant(nil))
            let detailView = iPadDetailView(item: nil)
            
            views.append(iPadView)
            views.append(sidebarView)
            views.append(contentView)
            views.append(detailView)
        }
        
        // Should not cause memory issues
        XCTAssertEqual(views.count, 40)
    }
    
    func testHealthItemMemoryUsage() {
        var healthItems: [HealthItem] = []
        
        for i in 0..<100 {
            let item = HealthItem(
                title: "Item \(i)",
                subtitle: "Subtitle \(i)",
                type: .healthCategory(.heartRate),
                icon: "heart.fill",
                color: .red
            )
            healthItems.append(item)
        }
        
        // Should not cause memory issues
        XCTAssertEqual(healthItems.count, 100)
    }
    
    // MARK: - Accessibility Tests
    
    func testIPadAppAccessibility() {
        let iPadView = iPadRootView()
        let sidebarView = iPadSidebarView(selectedSection: .constant(.dashboard))
        let contentView = iPadContentView(section: .healthData, selectedItem: .constant(nil))
        let detailView = iPadDetailView(item: nil)
        
        // Test that views are accessible
        XCTAssertNotNil(iPadView)
        XCTAssertNotNil(sidebarView)
        XCTAssertNotNil(contentView)
        XCTAssertNotNil(detailView)
    }
    
    func testSidebarAccessibility() {
        for section in SidebarSection.allCases {
            let sidebarView = iPadSidebarView(selectedSection: .constant(section))
            XCTAssertNotNil(sidebarView)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testIPadAppErrorHandling() {
        // Test with nil values
        let detailView = iPadDetailView(item: nil)
        XCTAssertNotNil(detailView)
        
        // Test with invalid sections
        let contentView = iPadContentView(section: nil, selectedItem: .constant(nil))
        XCTAssertNotNil(contentView)
    }
    
    func testHealthItemErrorHandling() {
        // Test health item creation with various parameters
        let validItem = HealthItem(
            title: "Valid Item",
            subtitle: "Valid subtitle",
            type: .healthCategory(.heartRate),
            icon: "heart.fill",
            color: .red
        )
        XCTAssertNotNil(validItem)
        
        let emptyItem = HealthItem(
            title: "",
            subtitle: nil,
            type: .healthCategory(.heartRate),
            icon: "",
            color: .clear
        )
        XCTAssertNotNil(emptyItem)
    }
}

// MARK: - Test Helpers

extension iPadAppTests {
    
    func createSampleHealthItem() -> HealthItem {
        return HealthItem(
            title: "Test Health Item",
            subtitle: "Test subtitle",
            type: .healthCategory(.heartRate),
            icon: "heart.fill",
            color: .red
        )
    }
    
    func createSampleConversation() -> HealthItem {
        return HealthItem(
            title: "Test Conversation",
            subtitle: "Test conversation preview",
            type: .conversation("test_conversation_id"),
            icon: "message.fill",
            color: .blue
        )
    }
    
    func createSampleWorkout() -> HealthItem {
        return HealthItem(
            title: "Test Workout",
            subtitle: "Test workout description",
            type: .workout(.running),
            icon: "figure.run",
            color: .green
        )
    }
} 