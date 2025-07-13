import SwiftUI
import HealthAI2030UI
import HealthAI2030Core

@main
struct HealthAI2030MacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(HealthAICoordinator())
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

struct ContentView: View {
    var body: some View {
        MacHealthDashboardView()
    }
}