
import SwiftUI
import HealthAI2030UI

struct MoodWidget: View {
    @State private var mood = "🙂"
    var body: some View {
        HealthAICard {
            VStack {
                Text("Mood")
                    .font(HealthAIDesignSystem.Typography.headline)
                MoodSelector(selectedMood: $mood)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Mood Widget")
        }
    }
}
