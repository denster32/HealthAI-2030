import SwiftUI
import HealthAI2030UI
import HealthAI2030Core

@main
struct HealthAI2030iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(HealthAICoordinator())
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            HealthDashboardView()
        }
    }
} 