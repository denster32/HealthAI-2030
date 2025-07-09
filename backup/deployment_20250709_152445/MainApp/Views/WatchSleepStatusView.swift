import SwiftUI

/// Simple watchOS view for quick glance sleep status.
struct WatchSleepStatusView: View {
    var sleepScore: Int = 82
    var body: some View {
        VStack(spacing: 4) {
            Text("Sleep Score")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(sleepScore)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            HStack(spacing: 2) {
                Image(systemName: "moon.stars.fill")
                Text("Good Night!")
            }
            .font(.caption2)
        }
        .padding()
    }
}

#Preview {
    WatchSleepStatusView()
}
