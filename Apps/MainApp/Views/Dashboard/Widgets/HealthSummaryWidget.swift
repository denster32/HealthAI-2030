
import SwiftUI
import HealthAI2030UI

struct HealthSummaryWidget: View {
    var body: some View {
        HealthMetricCard(title: "Daily Summary", value: "Good", trend: "Improving")
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Health Summary Widget")
    }
}
