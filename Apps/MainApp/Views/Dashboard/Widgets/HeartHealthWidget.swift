
import SwiftUI
import HealthAI2030UI

struct HeartHealthWidget: View {
    var body: some View {
        HealthAICard {
            VStack {
                Text("Heart Health")
                    .font(HealthAIDesignSystem.Typography.headline)
                HeartRateDisplay(heartRate: 75)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Heart Health Widget")
        }
    }
}
