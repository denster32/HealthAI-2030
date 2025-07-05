import SwiftUI

struct AdaptiveRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Environment objects for the app
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
        Group {
            if horizontalSizeClass == .compact {
                // iPhone UI - Existing TabView
                iPhoneContentView()
            } else {
                // iPad UI - New NavigationSplitView
                iPadRootView()
            }
        }
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

// iPhone Content View - Existing TabView
struct iPhoneContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)

            ExplainabilityView()
                .tabItem {
                    Label("Explainability", systemImage: "eye.fill")
                }
                .tag(1)

            UserScriptingView()
                .tabItem {
                    Label("User Scripting", systemImage: "scroll.fill")
                }
                .tag(2)

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(3)

            AutomationSettingsView()
                .tabItem {
                    Label("Automations", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .onAppear {
            UITabBar.appearance().backgroundColor = UIColor.systemBackground
        }
    }
}

#Preview {
    AdaptiveRootView()
        .environmentObject(HealthDataManager.shared)
        .environmentObject(PredictiveAnalyticsManager.shared)
        .environmentObject(SleepOptimizationManager.shared)
} 