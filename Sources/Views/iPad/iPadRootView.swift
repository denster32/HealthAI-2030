import SwiftUI

struct iPadRootView: View {
    @State private var selectedSection: SidebarSection? = .dashboard
    @State private var selectedItem: HealthItem?
    
    // Environment objects
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var predictiveAnalytics: PredictiveAnalyticsManager
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var emergencyAlertManager: EmergencyAlertManager
    @EnvironmentObject var smartHomeManager: SmartHomeManager
    @EnvironmentObject var thirdPartyAPIManager: ThirdPartyAPIManager
    @EnvironmentObject var swiftDataManager: SwiftDataManager
    @EnvironmentObject var accessibilityResources: AccessibilityResources
    @EnvironmentObject var iOS18FeaturesManager: IOS18FeaturesManager
    @EnvironmentObject var skillLoader: SkillLoader
    @EnvironmentObject var appIntentManager: AppIntentManager
    @EnvironmentObject var userScriptingManager: UserScriptingManager
    @EnvironmentObject var enhancedAudioExperienceManager: EnhancedAudioExperienceManager
    @EnvironmentObject var familyGroupManager: FamilyGroupManager
    @EnvironmentObject var performanceOptimizer: PerformanceOptimizer
    @EnvironmentObject var controlCenterManager: ControlCenterManager
    @EnvironmentObject var spotlightManager: SpotlightManager
    @EnvironmentObject var interactiveWidgetManager: InteractiveWidgetManager
    @EnvironmentObject var shortcutsManager: ShortcutsManager
    @EnvironmentObject var enhancedSleepViewManager: EnhancedSleepViewManager
    @EnvironmentObject var dataPrivacyDashboardManager: DataPrivacyDashboardManager
    @EnvironmentObject var diagnosticsDashboardManager: DiagnosticsDashboardManager
    @EnvironmentObject var performanceOptimizationDashboardManager: PerformanceOptimizationDashboardManager
    @EnvironmentObject var federatedLearningManager: FederatedLearningManager
    @EnvironmentObject var enhancedAudioViewManager: EnhancedAudioViewManager
    @EnvironmentObject var explainabilityViewManager: ExplainabilityViewManager
    @EnvironmentObject var userScriptingViewManager: UserScriptingViewManager
    @EnvironmentObject var biofeedbackMeditationViewManager: BiofeedbackMeditationViewManager
    @EnvironmentObject var automationSettingsViewManager: AutomationSettingsViewManager
    @EnvironmentObject var localizationSettingsViewManager: LocalizationSettingsViewManager
    @EnvironmentObject var enhancedSleepView: EnhancedSleepViewManager
    @EnvironmentObject var environmentalHealthViewManager: EnvironmentalHealthViewManager
    @EnvironmentObject var iPadSpecificFeaturesManager: IPadSpecificFeaturesManager
    @EnvironmentObject var liveActivitiesViewManager: LiveActivitiesViewManager
    @EnvironmentObject var performanceOptimizedViewsManager: PerformanceOptimizedViewsManager
    @EnvironmentObject var sleepCoachingViewManager: SleepCoachingViewManager
    @EnvironmentObject var accessibilityResourcesViewManager: AccessibilityResourcesViewManager
    @EnvironmentObject var analyticsViewManager: AnalyticsViewManager
    @EnvironmentObject var appleTVViewManager: AppleTVViewManager
    @EnvironmentObject var watchKitExtensionViewManager: WatchKitExtensionViewManager
    @EnvironmentObject var macOSViewManager: MacOSViewManager
    @EnvironmentObject var tvOSViewManager: TVOSViewManager
    @EnvironmentObject var watchKitAppViewManager: WatchKitAppViewManager
    @EnvironmentObject var iOS18FeaturesViewManager: IOS18FeaturesViewManager
    @EnvironmentObject var healthAI2030AppViewManager: HealthAI2030AppViewManager
    @EnvironmentObject var healthAI2030MacAppViewManager: HealthAI2030MacAppViewManager
    @EnvironmentObject var healthAI2030TVAppViewManager: HealthAI2030TVAppViewManager
    @EnvironmentObject var healthAI2030WatchAppViewManager: HealthAI2030WatchAppViewManager
    @EnvironmentObject var healthAI2030WidgetsViewManager: HealthAI2030WidgetsViewManager
    @EnvironmentObject var healthAI2030TestsViewManager: HealthAI2030TestsViewManager
    @EnvironmentObject var healthAI2030UITestsViewManager: HealthAI2030UITestsViewManager
    @EnvironmentObject var healthAI2030DocCViewManager: HealthAI2030DocCViewManager
    @EnvironmentObject var mlViewManager: MLViewManager
    @EnvironmentObject var modulesViewManager: ModulesViewManager
    @EnvironmentObject var packagesViewManager: PackagesViewManager
    @EnvironmentObject var scriptsViewManager: ScriptsViewManager
    @EnvironmentObject var sourcesViewManager: SourcesViewManager
    @EnvironmentObject var testsViewManager: TestsViewManager

    var body: some View {
        NavigationSplitView {
            // Column 1: Sidebar
            iPadSidebarView(selectedSection: $selectedSection)
        } content: {
            // Column 2: Content List
            iPadContentView(section: selectedSection, selectedItem: $selectedItem)
        } detail: {
            // Column 3: Detail View
            iPadDetailView(item: selectedItem)
        }
        .navigationSplitViewStyle(.balanced)
        .environmentObject(healthDataManager)
        .environmentObject(predictiveAnalytics)
        .environmentObject(sleepOptimizationManager)
        .environmentObject(locationManager)
        .environmentObject(emergencyAlertManager)
        .environmentObject(smartHomeManager)
        .environmentObject(thirdPartyAPIManager)
        .environmentObject(swiftDataManager)
        .environmentObject(accessibilityResources)
        .environmentObject(iOS18FeaturesManager)
        .environmentObject(skillLoader)
        .environmentObject(appIntentManager)
        .environmentObject(userScriptingManager)
        .environmentObject(enhancedAudioExperienceManager)
        .environmentObject(familyGroupManager)
        .environmentObject(performanceOptimizer)
        .environmentObject(controlCenterManager)
        .environmentObject(spotlightManager)
        .environmentObject(interactiveWidgetManager)
        .environmentObject(shortcutsManager)
        .environmentObject(enhancedSleepViewManager)
        .environmentObject(dataPrivacyDashboardManager)
        .environmentObject(diagnosticsDashboardManager)
        .environmentObject(performanceOptimizationDashboardManager)
        .environmentObject(federatedLearningManager)
        .environmentObject(enhancedAudioViewManager)
        .environmentObject(explainabilityViewManager)
        .environmentObject(userScriptingViewManager)
        .environmentObject(biofeedbackMeditationViewManager)
        .environmentObject(automationSettingsViewManager)
        .environmentObject(localizationSettingsViewManager)
        .environmentObject(enhancedSleepView)
        .environmentObject(environmentalHealthViewManager)
        .environmentObject(iPadSpecificFeaturesManager)
        .environmentObject(liveActivitiesViewManager)
        .environmentObject(performanceOptimizedViewsManager)
        .environmentObject(sleepCoachingViewManager)
        .environmentObject(accessibilityResourcesViewManager)
        .environmentObject(analyticsViewManager)
        .environmentObject(appleTVViewManager)
        .environmentObject(watchKitExtensionViewManager)
        .environmentObject(macOSViewManager)
        .environmentObject(tvOSViewManager)
        .environmentObject(watchKitAppViewManager)
        .environmentObject(iOS18FeaturesViewManager)
        .environmentObject(healthAI2030AppViewManager)
        .environmentObject(healthAI2030MacAppViewManager)
        .environmentObject(healthAI2030TVAppViewManager)
        .environmentObject(healthAI2030WatchAppViewManager)
        .environmentObject(healthAI2030WidgetsViewManager)
        .environmentObject(healthAI2030TestsViewManager)
        .environmentObject(healthAI2030UITestsViewManager)
        .environmentObject(healthAI2030DocCViewManager)
        .environmentObject(mlViewManager)
        .environmentObject(modulesViewManager)
        .environmentObject(packagesViewManager)
        .environmentObject(scriptsViewManager)
        .environmentObject(sourcesViewManager)
        .environmentObject(testsViewManager)
    }
}

// MARK: - Supporting Types

enum SidebarSection: String, CaseIterable {
    case dashboard = "Dashboard"
    case analytics = "Analytics"
    case healthData = "Health Data"
    case aiCopilot = "AI Copilot"
    case sleepTracking = "Sleep Tracking"
    case workouts = "Workouts"
    case nutrition = "Nutrition"
    case mentalHealth = "Mental Health"
    case medications = "Medications"
    case family = "Family Health"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .analytics: return "chart.bar.xaxis"
        case .healthData: return "heart.text.square.fill"
        case .aiCopilot: return "brain.head.profile"
        case .sleepTracking: return "bed.double.fill"
        case .workouts: return "figure.run"
        case .nutrition: return "fork.knife"
        case .mentalHealth: return "brain"
        case .medications: return "pill.fill"
        case .family: return "person.3.fill"
        case .settings: return "gear"
        }
    }
    
    var color: Color {
        switch self {
        case .dashboard: return .blue
        case .analytics: return .purple
        case .healthData: return .red
        case .aiCopilot: return .orange
        case .sleepTracking: return .indigo
        case .workouts: return .green
        case .nutrition: return .yellow
        case .mentalHealth: return .pink
        case .medications: return .mint
        case .family: return .cyan
        case .settings: return .gray
        }
    }
}

enum HealthItemType {
    case healthCategory(HealthCategory)
    case conversation(String) // conversation ID
    case workout(WorkoutType)
    case sleepSession(Date)
    case medication(String)
    case familyMember(String)
}

struct HealthItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let type: HealthItemType
    let icon: String
    let color: Color
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: HealthItem, rhs: HealthItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum HealthCategory: String, CaseIterable {
    case heartRate = "Heart Rate"
    case steps = "Steps"
    case sleep = "Sleep"
    case calories = "Calories"
    case activity = "Activity"
    case weight = "Weight"
    case bloodPressure = "Blood Pressure"
    case glucose = "Glucose"
    case oxygen = "Oxygen"
    case respiratory = "Respiratory"
    
    var icon: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .steps: return "figure.walk"
        case .sleep: return "bed.double.fill"
        case .calories: return "flame.fill"
        case .activity: return "figure.run"
        case .weight: return "scalemass.fill"
        case .bloodPressure: return "heart.circle.fill"
        case .glucose: return "drop.degreesign.fill"
        case .oxygen: return "lungs.fill"
        case .respiratory: return "lungs"
        }
    }
    
    var color: Color {
        switch self {
        case .heartRate: return .red
        case .steps: return .green
        case .sleep: return .blue
        case .calories: return .orange
        case .activity: return .purple
        case .weight: return .brown
        case .bloodPressure: return .pink
        case .glucose: return .yellow
        case .oxygen: return .mint
        case .respiratory: return .cyan
        }
    }
}

enum WorkoutType: String, CaseIterable {
    case running = "Running"
    case walking = "Walking"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case yoga = "Yoga"
    case strength = "Strength Training"
    
    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .yoga: return "figure.mind.and.body"
        case .strength: return "dumbbell.fill"
        }
    }
}

#Preview {
    iPadRootView()
        .environmentObject(HealthDataManager.shared)
        .environmentObject(PredictiveAnalyticsManager.shared)
        .environmentObject(SleepOptimizationManager.shared)
} 