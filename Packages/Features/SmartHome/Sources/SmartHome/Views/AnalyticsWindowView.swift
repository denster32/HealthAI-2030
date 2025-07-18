import SwiftUI
import Charts

struct AnalyticsWindowView: View {
    @EnvironmentObject var macAnalyticsEngine: MacAnalyticsEngine
    @EnvironmentObject var dataExportManager: DataExportManager
    @State private var dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .month, value: -6, to: end) ?? end
        return start...end
    }()
    @State private var selectedMetrics: Set<String> = ["sleepStage"]
    @State private var trendMetric: String = "sleepStage"
    @State private var showExportSheet = false
    @State private var reportURL: URL?

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Filters")) {
                    DatePicker("Start Date", selection: Binding(
                        get: { dateRange.lowerBound },
                        set: { dateRange = $0...dateRange.upperBound }
                    ), displayedComponents: .date)
                    DatePicker("End Date", selection: Binding(
                        get: { dateRange.upperBound },
                        set: { dateRange = dateRange.lowerBound...$0 }
                    ), displayedComponents: .date)
                    // Metric toggles
                    Toggle("Sleep Stage", isOn: Binding(
                        get: { selectedMetrics.contains("sleepStage") },
                        set: { if $0 { selectedMetrics.insert("sleepStage") } else { selectedMetrics.remove("sleepStage") } }
                    ))
                    Toggle("Health Prediction", isOn: Binding(
                        get: { selectedMetrics.contains("healthPrediction") },
                        set: { if $0 { selectedMetrics.insert("healthPrediction") } else { selectedMetrics.remove("healthPrediction") } }
                    ))
                    Toggle("Arrhythmia", isOn: Binding(
                        get: { selectedMetrics.contains("arrhythmia") },
                        set: { if $0 { selectedMetrics.insert("arrhythmia") } else { selectedMetrics.remove("arrhythmia") } }
                    ))
                }

                Section(header: Text("Historical Chart")) {
                    HistoricalChartView(dateRange: dateRange, metrics: selectedMetrics)
                        .frame(height: 200)
                    if macAnalyticsEngine.isLoadingTrend {
                        ProgressView("Updating chart...")
                    }
                    if let error = macAnalyticsEngine.trendError {
                        Text("Chart error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    }
                }

                Section(header: Text("Trendlines")) {
                    Picker("Trend Metric", selection: $trendMetric) {
                        ForEach(Array(selectedMetrics), id: \ .self) { m in
                            Text(m).tag(m)
                        }
                    }
                    .pickerStyle(.menu)
                    TrendlineView(dateRange: dateRange, metric: trendMetric)
                        .frame(height: 200)
                    if macAnalyticsEngine.isLoadingTrend {
                        ProgressView("Loading trend...")
                    }
                    if let error = macAnalyticsEngine.trendError {
                        Text("Trend error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    }
                }

                Section(header: Text("Anomalies")) {
                    AnomalyListView(dateRange: dateRange)
                    if macAnalyticsEngine.isLoadingAnomalies {
                        ProgressView("Loading anomalies...")
                    }
                    if let error = macAnalyticsEngine.anomaliesError {
                        Text("Anomaly error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        dataExportManager.isExporting = true
                        Task {
                            do {
                                let url = try await macAnalyticsEngine.generateReports(format: .csv, for: DateInterval(start: dateRange.lowerBound, end: dateRange.upperBound))
                                self.reportURL = url
                                self.showExportSheet = true
                            } catch {
                                // error handled by engine
                            }
                        }
                    }) {
                        if dataExportManager.isExporting {
                            ProgressView()
                        } else {
                            Text("Export Data")
                        }
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = reportURL {
                    ShareLink(item: url)
                }
            }
        }
        .environmentObject(DataExportManager.shared)
    }
}

struct AnalyticsWindowView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsWindowView()
            .environmentObject(MacAnalyticsEngine.shared)
    }
}
