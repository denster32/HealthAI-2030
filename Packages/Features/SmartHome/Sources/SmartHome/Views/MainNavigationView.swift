import SwiftUI
import SwiftData

/// Main navigation view that handles authentication state and app navigation
struct MainNavigationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var errorHandler = ErrorHandlingService.shared
    @State private var selectedTab: MainTab = .dashboard
    @State private var showingOnboarding = false
    @State private var showExportProgress = false // State to control export progress sheet
    enum MainTab: String, CaseIterable, Identifiable {
        case dashboard, health, analytics, settings, export // Added export tab
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .health: return "Health"
            case .analytics: return "Analytics"
            case .settings: return "Settings"
            case .export: return "Export" // Added export case
            }
        
        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .health: return "heart.fill"
            case .analytics: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            case .export: return "square.and.arrow.up.fill" // Added export case
            }
    }
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                if let user = authManager.currentUser, user.isOnboardingCompleted {
                    mainTabView
                } else {
                    OnboardingView()
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            setupApp()
        }
        .alert("Error", isPresented: $errorHandler.showingError) {
            Button("OK") { errorHandler.dismissError() }
        } message: {
            Text(errorHandler.currentErrorMessage)
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(MainTab.dashboard.title, systemImage: MainTab.dashboard.icon)
                }
                .tag(MainTab.dashboard)
            
            HealthDashboardView()
                .tabItem {
                    Label(MainTab.health.title, systemImage: MainTab.health.icon)
                }
                .tag(MainTab.health)
            
            AnalyticsView()
                .tabItem {
                    Label(MainTab.analytics.title, systemImage: MainTab.analytics.icon)
                }
                .tag(MainTab.analytics)
            
            SettingsView()
                .tabItem {
                    Label(MainTab.settings.title, systemImage: MainTab.settings.icon)
                }
                .tag(MainTab.settings)
        }
            ExportConfigurationView() // Added Export View
                .tabItem {
                    Label(MainTab.export.title, systemImage: MainTab.export.icon)
                }
                .tag(MainTab.export)

            NavigationLink(destination: ExportProgressView(), isActive: $showExportProgress) { // Added navigation to export progress
                EmptyView()
            }
            .hidden() // Keep the link hidden, we'll activate it programmatically
            .onAppear {
                showExportProgress = exportManager.isExporting // Show progress if export is already running
            }
            .onChange(of: exportManager.isExporting) { isExporting in
                showExportProgress = isExporting // Update visibility when export state changes
            }
        .tint(.blue)
        .navigationTitle(selectedTab.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    Task {
                        await refreshData()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .symbolEffect(.pulse, isActive: false)
                }
                .accessibilityLabel("Refresh data")
            }
        }
    }
    
    private func setupApp() {
        // Configure authentication manager with SwiftData context
        if let modelContext = try? ModelContext(for: UserProfile.self) {
            authManager.configure(with: modelContext)
        }
        
        // Check if user needs onboarding
        if let user = authManager.currentUser, !user.isOnboardingCompleted {
            showingOnboarding = true
        }
    }
    
    private func refreshData() async {
        // Implement data refresh logic
        // This would typically refresh health data, analytics, etc.
    }
}

#Preview {
    MainNavigationView()
        .modelContainer(for: [UserProfile.self, HealthData.self, DigitalTwin.self], isCloudKitEnabled: true)
} 