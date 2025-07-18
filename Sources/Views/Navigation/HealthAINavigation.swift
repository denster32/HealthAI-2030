
import SwiftUI
import HealthAI2030UI

struct HealthAINavigation<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(HealthAIDesignSystem.Color.surface)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(HealthAIDesignSystem.Color.textPrimary)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(HealthAIDesignSystem.Color.textPrimary)]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // For iPad/macOS sidebar styling
        UISplitViewController.appearance().primaryBackgroundStyle = .sidebar
    }

    var body: some View {
        NavigationView {
            content
        }
        .navigationViewStyle(.stack)
    }
}
