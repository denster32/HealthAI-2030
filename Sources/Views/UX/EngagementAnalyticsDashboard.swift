import SwiftUI
import Charts

// MARK: - Engagement Analytics Data Models
struct EngagementMetric: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let trend: TrendDirection
    let change: Double // % change
}

struct EngagementTrend: Identifiable {
    let id = UUID()
    let metric: String
    let dataPoints: [TrendDataPoint]
}

struct TrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

enum TrendDirection: String, CaseIterable {
    case increasing, decreasing, stable, fluctuating
}

struct EngagementCohort: Identifiable {
    let id = UUID()
    let name: String
    let metrics: [EngagementMetric]
}

// MARK: - Engagement Analytics Dashboard View
struct EngagementAnalyticsDashboard: View {
    @State private var metrics: [EngagementMetric] = [
        EngagementMetric(name: "Daily Active Users", value: 1240, trend: .increasing, change: 3.2),
        EngagementMetric(name: "Retention Rate", value: 0.82, trend: .stable, change: 0.0),
        EngagementMetric(name: "Avg. Session Length (min)", value: 7.4, trend: .increasing, change: 1.1),
        EngagementMetric(name: "Feature Usage", value: 0.67, trend: .fluctuating, change: -0.5)
    ]
    @State private var trends: [EngagementTrend] = [
        EngagementTrend(metric: "Daily Active Users", dataPoints: Self.generateTrendData(base: 1200, fluctuation: 80)),
        EngagementTrend(metric: "Retention Rate", dataPoints: Self.generateTrendData(base: 0.8, fluctuation: 0.05)),
        EngagementTrend(metric: "Avg. Session Length (min)", dataPoints: Self.generateTrendData(base: 7.0, fluctuation: 1.0)),
        EngagementTrend(metric: "Feature Usage", dataPoints: Self.generateTrendData(base: 0.65, fluctuation: 0.1))
    ]
    @State private var cohorts: [EngagementCohort] = [
        EngagementCohort(name: "Patients", metrics: [
            EngagementMetric(name: "DAU", value: 900, trend: .increasing, change: 2.5),
            EngagementMetric(name: "Retention", value: 0.85, trend: .stable, change: 0.0)
        ]),
        EngagementCohort(name: "Providers", metrics: [
            EngagementMetric(name: "DAU", value: 220, trend: .decreasing, change: -1.2),
            EngagementMetric(name: "Retention", value: 0.78, trend: .decreasing, change: -0.5)
        ]),
        EngagementCohort(name: "Researchers", metrics: [
            EngagementMetric(name: "DAU", value: 120, trend: .stable, change: 0.0),
            EngagementMetric(name: "Retention", value: 0.81, trend: .increasing, change: 0.3)
        ])
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Engagement Analytics Dashboard")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                // Metrics Summary
                MetricsSummaryView(metrics: metrics)
                // Trends
                ForEach(trends) { trend in
                    TrendChartView(trend: trend)
                }
                // Cohort Segmentation
                Text("Cohort Segmentation")
                    .font(.title2.bold())
                    .padding(.top, 16)
                ForEach(cohorts) { cohort in
                    CohortMetricsView(cohort: cohort)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Analytics")
        .accessibilityElement(children: .contain)
    }
    
    // Helper to generate trend data
    static func generateTrendData(base: Double, fluctuation: Double) -> [TrendDataPoint] {
        let days = (0..<14).map { Calendar.current.date(byAdding: .day, value: -$0, to: Date())! }.reversed()
        return days.enumerated().map { (i, date) in
            let value = base + Double.random(in: -fluctuation...fluctuation)
            return TrendDataPoint(date: date, value: value)
        }
    }
}

// MARK: - Metrics Summary View
struct MetricsSummaryView: View {
    let metrics: [EngagementMetric]
    var body: some View {
        HStack(spacing: 16) {
            ForEach(metrics) { metric in
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.name)
                        .font(.headline)
                    Text(metric.value >= 1 ? String(format: "%.0f", metric.value) : String(format: "%.2f", metric.value))
                        .font(.title.bold())
                        .foregroundColor(.accentColor)
                    HStack(spacing: 4) {
                        Image(systemName: metric.trend == .increasing ? "arrow.up" : metric.trend == .decreasing ? "arrow.down" : "arrow.left.and.right")
                            .foregroundColor(metric.trend == .increasing ? .green : metric.trend == .decreasing ? .red : .gray)
                        Text(String(format: "%+.1f%%", metric.change))
                            .font(.caption)
                            .foregroundColor(metric.change >= 0 ? .green : .red)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(metric.name), \(metric.value), \(metric.trend.rawValue), change \(metric.change) percent")
            }
        }
    }
}

// MARK: - Trend Chart View
struct TrendChartView: View {
    let trend: EngagementTrend
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trend.metric)
                .font(.headline)
            Chart(trend.dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.accent)
            }
            .frame(height: 120)
            .accessibilityLabel("Trend chart for \(trend.metric)")
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Cohort Metrics View
struct CohortMetricsView: View {
    let cohort: EngagementCohort
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(cohort.name)
                .font(.headline)
            HStack(spacing: 16) {
                ForEach(cohort.metrics) { metric in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.name)
                            .font(.caption)
                        Text(metric.value >= 1 ? String(format: "%.0f", metric.value) : String(format: "%.2f", metric.value))
                            .font(.body.bold())
                            .foregroundColor(.accentColor)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(metric.name), \(metric.value)")
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct EngagementAnalyticsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EngagementAnalyticsDashboard()
        }
        .previewDevice("iPhone 15 Pro")
    }
} 