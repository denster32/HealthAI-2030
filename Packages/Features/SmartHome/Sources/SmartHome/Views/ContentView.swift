import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab: String, CaseIterable, Identifiable {
        case dashboard, health, analytics, settings
        var id: String { rawValue }
    }
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                mainTabView
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Configure authentication manager with SwiftData context
            if let modelContext = try? ModelContext(for: UserProfile.self) {
                authManager.configure(with: modelContext)
            }
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(Tab.dashboard)
                .animation(.easeInOut, value: selectedTab)
            
            HealthDashboardView()
                .tabItem {
                    Label("Health", systemImage: "heart.fill")
                }
                .tag(Tab.health)
                .animation(.easeInOut, value: selectedTab)
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(Tab.analytics)
                .animation(.easeInOut, value: selectedTab)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
                .animation(.easeInOut, value: selectedTab)
        }
        .tint(.blue) // Modern tint color for tab items
        .navigationTitle(tabTitle(for: selectedTab))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    viewModel.refreshData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .symbolEffect(.pulse, isActive: viewModel.isRefreshing)
                }
            }
        }
    }
    
    private func tabTitle(for tab: Tab) -> String {
        switch tab {
        case .dashboard: return "Dashboard"
        case .health: return "Health"
        case .analytics: return "Analytics"
        case .settings: return "Settings"
        }
    }
}

class ContentViewModel: ObservableObject {
    @Published var isRefreshing: Bool = false
    
    func refreshData() {
        isRefreshing = true
        // Simulate data refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isRefreshing = false
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.light)
}

// ... existing code ... (rest of the file can remain unchanged or be adapted based on specific needs)