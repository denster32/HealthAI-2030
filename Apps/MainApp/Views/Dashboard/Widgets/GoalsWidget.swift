
import SwiftUI
import HealthAI2030UI

struct GoalsWidget: View {
    var body: some View {
        HealthMetricCard(title: "Goals", value: "3 of 5 Complete", trend: "Keep it up!")
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Goals Widget")
    }
}
