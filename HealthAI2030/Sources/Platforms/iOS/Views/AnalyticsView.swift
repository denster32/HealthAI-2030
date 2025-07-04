import SwiftUI
import Charts // Assuming we will use Charts framework for visualizations
import Analytics

struct AnalyticsView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var predictiveAnalytics: PredictiveAnalyticsManager
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Health Analytics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    // Premium analytics hero image
                    PremiumAssets.dashboardHero
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(14)
                        .shadow(radius: 6)
                        .padding(.bottom, 8)
                    // Analytics tutorial video
                    VideoPlayerView(videoName: InAppTutorials.dashboardWalkthrough)
                        .frame(height: 90)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .padding(.bottom, 8)

                    ActivityOverviewSection()

                    SleepAnalysisSection()

                    InsightsAndPredictionsSection()

                    Spacer()
                }
            }
            .navigationTitle("Analytics Dashboard")
        }
    }
}

struct SleepAnalysisSection: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.blue)
                Text("Sleep Analysis")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            Text("Average Sleep Quality: \(String(format: "%.1f", sleepOptimizationManager.averageSleepQuality))")
                .font(.subheadline)
                .padding(.horizontal)

            Text("Sleep Consistency: \(String(format: "%.1f", sleepOptimizationManager.sleepConsistency))")
                .font(.subheadline)
                .padding(.horizontal)

            SleepQualityChartView(sleepData: sleepOptimizationManager.weeklySleepData)
                .frame(height: 200)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct ActivityOverviewSection: View {
    @EnvironmentObject var healthDataManager: HealthDataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.run.circle.fill")
                    .foregroundColor(.orange)
                Text("Activity Overview")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            DailyActivityBarChart(
                data: healthDataManager.weeklyTrends.stepTrend.map { Double($0) },
                labels: (0..<healthDataManager.weeklyTrends.stepTrend.count).map { "Day \($0 + 1)" },
                title: "Daily Steps",
                unit: "steps",
                color: .orange
            )
            .frame(height: 200)
            .padding(.horizontal)

            DailyActivityBarChart(
                data: healthDataManager.weeklyTrends.energyTrend,
                labels: (0..<healthDataManager.weeklyTrends.energyTrend.count).map { "Day \($0 + 1)" },
                title: "Daily Active Energy",
                unit: "kcal",
                color: .red
            )
            .frame(height: 200)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct InsightsAndPredictionsSection: View {
    @EnvironmentObject var predictiveAnalytics: PredictiveAnalyticsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Insights & Predictions")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            if predictiveAnalytics.dailyInsights.isEmpty && predictiveAnalytics.healthAlerts.isEmpty {
                Text("No insights or alerts available at this time.")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.horizontal)
            } else {
                ForEach(predictiveAnalytics.dailyInsights.prefix(3), id: \.timestamp) { insight in
                    InsightRow(insight: insight)
                        .padding(.horizontal)
                }
                ForEach(predictiveAnalytics.healthAlerts.prefix(3), id: \.timestamp) { alert in
                    AlertRow(alert: alert)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct InsightRow: View {
    let insight: DailyInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(insight.title)
                .font(.headline)
            Text(insight.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct AlertRow: View {
    let alert: PriorityAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(alert.title)
                .font(.headline)
            Text(alert.description)
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .padding(.vertical, 8)
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environmentObject(HealthDataManager.shared)
            .environmentObject(PredictiveAnalyticsManager.shared)
            .environmentObject(SleepOptimizationManager.shared)
    }
}