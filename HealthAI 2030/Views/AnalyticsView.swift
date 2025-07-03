import SwiftUI
import Charts // Assuming we will use Charts framework for visualizations

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

                    // Daily Summary Section
                    DailySummarySection()

                    // Weekly Trends Section
                    WeeklyTrendsSection()

                    // Sleep Analysis Section
                    SleepAnalysisSection()

                    // Activity Overview Section
                    ActivityOverviewSection()

                    // Insights & Predictions Section (Placeholder for now)
                    InsightsAndPredictionsSection()
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Sections

struct DailySummarySection: View {
    @EnvironmentObject var healthDataManager: HealthDataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.day.timeline.leading")
                    .foregroundColor(.blue)
                Text("Daily Summary")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                HealthSummaryCard(
                    title: "Avg Heart Rate",
                    value: "\(Int(healthDataManager.dailyMetrics.averageHeartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                HealthSummaryCard(
                    title: "Total Steps",
                    value: "\(healthDataManager.dailyMetrics.totalSteps)",
                    unit: "steps",
                    icon: "figure.walk",
                    color: .orange
                )
                HealthSummaryCard(
                    title: "Sleep Duration",
                    value: formatTimeInterval(healthDataManager.dailyMetrics.sleepDuration),
                    unit: "",
                    icon: "bed.double.fill",
                    color: .purple
                )
                HealthSummaryCard(
                    title: "Sleep Quality",
                    value: "\(Int(healthDataManager.dailyMetrics.sleepQuality * 100))",
                    unit: "%",
                    icon: "moon.stars.fill",
                    color: .green
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct WeeklyTrendsSection: View {
    @EnvironmentObject var healthDataManager: HealthDataManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("Weekly Trends")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            HealthTrendLineChart(
                data: healthDataManager.weeklyTrends.heartRateTrend,
                labels: (0..<healthDataManager.weeklyTrends.heartRateTrend.count).map { "Day \($0 + 1)" },
                title: "Heart Rate Trend",
                unit: "BPM",
                color: .red
            )
            .frame(height: 200)
            .padding(.horizontal)

            HealthTrendLineChart(
                data: healthDataManager.weeklyTrends.hrvTrend,
                labels: (0..<healthDataManager.weeklyTrends.hrvTrend.count).map { "Day \($0 + 1)" },
                title: "HRV Trend",
                unit: "ms",
                color: .green
            )
            .frame(height: 200)
            .padding(.horizontal)

            HealthTrendLineChart(
                data: healthDataManager.weeklyTrends.sleepTrend.map { $0 / 3600.0 }, // Convert to hours
                labels: (0..<healthDataManager.weeklyTrends.sleepTrend.count).map { "Day \($0 + 1)" },
                title: "Sleep Duration Trend",
                unit: "hours",
                color: .purple
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

struct SleepAnalysisSection: View {
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .foregroundColor(.purple)
                Text("Sleep Architecture")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            SleepStageDonutChart(sleepMetrics: sleepOptimizationManager.sleepMetrics)
                .frame(height: 200)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sleep Quality:")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(sleepOptimizationManager.sleepQuality * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(sleepQualityColor(sleepOptimizationManager.sleepQuality))
                }
                Text("Deep Sleep: \(Int(sleepOptimizationManager.deepSleepPercentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("REM Sleep: \(Int(sleepOptimizationManager.sleepMetrics.remSleepPercentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }

    private func sleepQualityColor(_ quality: Double) -> Color {
        if quality >= 0.8 {
            return .green
        } else if quality >= 0.6 {
            return .orange
        } else {
            return .red
        }
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

// MARK: - Reusable Visualization Components

struct HealthSummaryCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct HealthTrendLineChart: View {
    let data: [Double]
    let labels: [String]
    let title: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.leading)

            Chart {
                ForEach(data.indices, id: \.self) { index in
                    LineMark(
                        x: .value("Day", labels[index]),
                        y: .value(unit, data[index])
                    )
                    .foregroundStyle(color)
                    PointMark(
                        x: .value("Day", labels[index]),
                        y: .value(unit, data[index])
                    )
                    .foregroundStyle(color)
                }
            }
            .chartYAxisLabel(unit)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct SleepStageDonutChart: View {
    var sleepMetrics: SleepMetrics

    var body: some View {
        VStack(alignment: .leading) {
            Text("Sleep Stage Breakdown")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.leading)

            Chart {
                SectorMark(
                    angle: .value("Awake", sleepMetrics.awakePercentage),
                    innerRadius: .ratio(0.618),
                    outerRadius: .inset(10)
                )
                .foregroundStyle(by: .value("Stage", "Awake"))
                .annotation(position: .overlay) {
                    if sleepMetrics.awakePercentage > 0.05 {
                        Text("\(Int(sleepMetrics.awakePercentage * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                }

                SectorMark(
                    angle: .value("Light Sleep", sleepMetrics.lightSleepPercentage),
                    innerRadius: .ratio(0.618),
                    outerRadius: .inset(10)
                )
                .foregroundStyle(by: .value("Stage", "Light Sleep"))
                .annotation(position: .overlay) {
                    if sleepMetrics.lightSleepPercentage > 0.05 {
                        Text("\(Int(sleepMetrics.lightSleepPercentage * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                }

                SectorMark(
                    angle: .value("Deep Sleep", sleepMetrics.deepSleepPercentage),
                    innerRadius: .ratio(0.618),
                    outerRadius: .inset(10)
                )
                .foregroundStyle(by: .value("Stage", "Deep Sleep"))
                .annotation(position: .overlay) {
                    if sleepMetrics.deepSleepPercentage > 0.05 {
                        Text("\(Int(sleepMetrics.deepSleepPercentage * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                }

                SectorMark(
                    angle: .value("REM Sleep", sleepMetrics.remSleepPercentage),
                    innerRadius: .ratio(0.618),
                    outerRadius: .inset(10)
                )
                .foregroundStyle(by: .value("Stage", "REM Sleep"))
                .annotation(position: .overlay) {
                    if sleepMetrics.remSleepPercentage > 0.05 {
                        Text("\(Int(sleepMetrics.remSleepPercentage * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .chartForegroundStyleScale([
                "Awake": Color.red,
                "Light Sleep": Color.orange,
                "Deep Sleep": Color.purple,
                "REM Sleep": Color.blue
            ])
            .chartLegend(position: .bottom, alignment: .center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct DailyActivityBarChart: View {
    let data: [Double]
    let labels: [String]
    let title: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.leading)

            Chart {
                ForEach(data.indices, id: \.self) { index in
                    BarMark(
                        x: .value("Day", labels[index]),
                        y: .value(unit, data[index])
                    )
                    .foregroundStyle(color)
                }
            }
            .chartYAxisLabel(unit)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Previews

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
            .environmentObject(HealthDataManager.shared)
            .environmentObject(PredictiveAnalyticsManager.shared)
            .environmentObject(SleepOptimizationManager.shared)
    }
}