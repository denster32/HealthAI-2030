
import SwiftUI
import HealthAI2030UI

struct ActivityWidget: View {
    var body: some View {
        HealthAICard {
            VStack {
                Text("Activity")
                    .font(HealthAIDesignSystem.Typography.headline)
                ActivityRing(progress: 0.75, color: .pink)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Activity Widget")
        }
    }
}
