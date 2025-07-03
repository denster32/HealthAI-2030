import SwiftUI

struct WatchContentView: View {
    var body: some View {
        VStack {
            Text("HealthAI 2030 on Apple Watch")
                .font(.headline)
                .padding(.top, 8)
            Text("Live health monitoring, haptics, and quick insights.")
                .font(.caption)
                .padding(.bottom, 8)
            Spacer()
            // Add live metrics, haptic feedback, and quick actions for watchOS
            Text("Premium Watch Experience: Real-time health, haptics, and notifications.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
