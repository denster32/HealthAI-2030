
import SwiftUI
import HealthAI2030UI

struct SleepWidget: View {
    var body: some View {
        HealthMetricCard(title: "Sleep", value: "8h 15m", trend: "+15m from avg")
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Sleep Widget")
    }
}
