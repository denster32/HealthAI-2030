
import SwiftUI
import HealthAI2030UI

struct SleepCycleVisualization: View {
    let data = [
        CategoryValue(category: "Awake", value: 10),
        CategoryValue(category: "REM", value: 90),
        CategoryValue(category: "Light", value: 180),
        CategoryValue(category: "Deep", value: 120),
    ]

    var body: some View {
        VStack {
            Text("Sleep Cycles")
                .font(HealthAIDesignSystem.Typography.headline)
            HealthPieChart(data: data)
                .frame(height: 200)
        }
        .padding()
        .background(HealthAIDesignSystem.Color.surface)
        .cornerRadius(HealthAIDesignSystem.Layout.cardCornerRadius)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sleep cycle visualization showing time in each stage.")
    }
}

struct HeartRateVariabilityChart: View {
    let data = [
        Point(date: .now.addingTimeInterval(-3600), value: 55),
        Point(date: .now.addingTimeInterval(-1800), value: 60),
        Point(date: .now, value: 58),
    ]

    var body: some View {
        VStack {
            Text("Heart Rate Variability (HRV)")
                .font(HealthAIDesignSystem.Typography.headline)
            HealthLineChart(data: data)
                .frame(height: 150)
        }
        .padding()
        .background(HealthAIDesignSystem.Color.surface)
        .cornerRadius(HealthAIDesignSystem.Layout.cardCornerRadius)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Heart rate variability chart.")
    }
}
