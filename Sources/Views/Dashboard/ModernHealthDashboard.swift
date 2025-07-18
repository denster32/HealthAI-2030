
import SwiftUI
import HealthAI2030UI

struct ModernHealthDashboard: View {
    var body: some View {
        TabView {
            dashboardContent
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
                .accessibilityLabel("Dashboard Tab")

            Text("Trends View Placeholder")
                .tabItem {
                    Label("Trends", systemImage: "chart.bar.xaxis")
                }
                .accessibilityLabel("Trends Tab")
            
            Text("Profile View Placeholder")
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .accessibilityLabel("Profile Tab")
        }
        .accentColor(HealthAIDesignSystem.Color.healthPrimary)
    }

    private var dashboardContent: some View {
        HealthAINavigation {
            ScrollView {
                VStack(spacing: HealthAIDesignSystem.Spacing.large) {
                    HealthSummaryWidget()
                    ActivityWidget()
                    SleepWidget()
                    HeartHealthWidget()
                    MoodWidget()
                    GoalsWidget()
                }
                .padding()
            }
            .navigationTitle("Your Health")
            .background(HealthAIDesignSystem.Color.background)
        }
    }
}
